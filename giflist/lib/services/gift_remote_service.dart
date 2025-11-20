import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/services/auth_api.dart';

class GiftRemoteService {
  GiftRemoteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final AuthApi _auth = AuthApi();

  static const String _base = 'https://ryk54ty6o6.execute-api.us-east-2.amazonaws.com/prod';

  Map<String, String> _headers() {
    final token = _auth.getCurrentUser()?.token;
    if (token == null || token.isEmpty) throw Exception('No autenticado');
    // Cognito Authorizer usualmente requiere formato Bearer
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  dynamic _unwrap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded.containsKey('body')) {
        final inner = decoded['body'];
        return inner is String ? jsonDecode(inner) : inner;
      }
      return decoded;
    } catch (_) {
      return body;
    }
  }

  Future<List<Gift>> list() async {
    final uri = Uri.parse('$_base/gifts');
    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Error al listar regalos: ${res.body}');
    }
    final data = _unwrap(res.body);
    if (data is List) {
      return data.map<Gift>((e) => _fromBackendJson(e as Map<String, dynamic>)).toList();
    }
    // tolerar formato { items: [...] }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map<Gift>((e) => _fromBackendJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Formato inesperado en listado: ${res.body}');
  }

  Future<Gift> create(Gift g) async {
    final uri = Uri.parse('$_base/gifts');
    final payload = {
      'name': g.name,
      'description': g.description,
      'price': g.price,
      'productLink': g.productLink,
      'quantity': g.quantity,
      // Indicamos al backend que queremos URL para subir imagen si hay bytes
      'imageUpload': g.imageData != null,
      'originalFileName': g.imageUrl, // usamos imageUrl como nombre original temporal
    };
    final res = await _client.post(uri, headers: _headers(), body: jsonEncode(payload));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al crear regalo: ${res.body}');
    }
    final data = _unwrap(res.body);
    if (data is Map<String, dynamic>) {
      final inner = (data['item'] is Map) ? data['item'] as Map<String, dynamic> : data;
      // Si hay uploadUrl y tenemos bytes, subir la imagen ahora
      final uploadUrl = data['uploadUrl'] as String?;
      if (uploadUrl != null && g.imageData != null) {
        try {
          await _uploadPresigned(uploadUrl, g.imageData!, g.imageUrl);
        } catch (e) {
          // No abortar la creación del regalo por fallo de imagen (MVP)
          // Se puede reintentar luego con un botón de "Reintentar subida".
        }
      }
      return _fromBackendJson(inner);
    }
    throw Exception('Formato inesperado al crear regalo: ${res.body}');
  }

  Future<Gift> reserve(String giftId, {required String userId}) async {
    final uri = Uri.parse('$_base/gifts/reserve');
    final payload = {'giftId': giftId, 'userId': userId};
    final res = await _client.post(uri, headers: _headers(), body: jsonEncode(payload));
    if (res.statusCode != 200) {
      throw Exception('Error al reservar: ${res.body}');
    }
    final data = _unwrap(res.body);
    if (data is Map<String, dynamic>) {
      final inner = (data['item'] is Map) ? data['item'] as Map<String, dynamic> : data;
      return _fromBackendJson(inner);
    }
    throw Exception('Formato inesperado en reserva: ${res.body}');
  }

  Future<Gift> cancel(String giftId, {required String userId}) async {
    final uri = Uri.parse('$_base/gifts/cancel');
    final payload = {'giftId': giftId, 'userId': userId};
    final res = await _client.post(uri, headers: _headers(), body: jsonEncode(payload));
    if (res.statusCode != 200) {
      throw Exception('Error al cancelar reserva: ${res.body}');
    }
    final data = _unwrap(res.body);
    if (data is Map<String, dynamic>) {
      final inner = (data['item'] is Map) ? data['item'] as Map<String, dynamic> : data;
      return _fromBackendJson(inner);
    }
    throw Exception('Formato inesperado al cancelar: ${res.body}');
  }

  Gift _fromBackendJson(Map<String, dynamic> json) {
    // Ser tolerantes con nombres de claves: giftId/id, createdAt, etc.
    final idVal = json['giftId'] ?? json['id'] ?? json['ItemId'];
    final id = idVal == null ? null : idVal.toString();
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final createdAtStr = createdAtRaw == null ? null : createdAtRaw.toString();
    final reservedFlag = json['isReserved'] ?? json['reserved'] ?? json['Reserved'];
    final isReserved = reservedFlag is bool
        ? reservedFlag
        : (reservedFlag is String ? reservedFlag.toLowerCase() == 'true' : false);
    final reservedByRaw = json['reservedBy'] ?? json['ReservedBy'];
    final reservedBy = reservedByRaw == null ? null : reservedByRaw.toString();

    // Campos obligatorios: name, description. Si vienen nulos, intentar claves alternativas.
    final nameRaw = json['name'] ?? json['Name'];
    final descRaw = json['description'] ?? json['Description'];
    if (nameRaw == null) {
      throw FormatException('Respuesta backend sin campo name: $json');
    }
    final name = nameRaw.toString();
    final description = descRaw == null ? '' : descRaw.toString();

    final priceRaw = json['price'] ?? json['Price'] ?? 0;
    final quantityRaw = json['quantity'] ?? json['Quantity'] ?? 1;
    final price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;
    final quantity = quantityRaw is int ? quantityRaw : int.tryParse(quantityRaw.toString()) ?? 1;

    final imageUrlRaw = json['imageUrl'] ?? json['ImageUrl'];
    final productLinkRaw = json['productLink'] ?? json['ProductLink'];

    return Gift(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrlRaw?.toString(),
      imageData: null,
      productLink: productLinkRaw?.toString(),
      price: price,
      quantity: quantity,
      isReserved: isReserved,
      reservedBy: reservedBy,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) ?? DateTime.now() : DateTime.now(),
    );
  }

  Future<void> _uploadPresigned(String url, List<int> bytes, String? fileName) async {
    final mime = _detectMimeType(fileName);
    final res = await http.put(Uri.parse(url), headers: {
      'Content-Type': mime,
    }, body: bytes);
    if (res.statusCode != 200) {
      throw Exception('Fallo subida imagen (${res.statusCode}): ${res.body}');
    }
  }

  String _detectMimeType(String? fileName) {
    if (fileName == null) return 'image/jpeg';
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
