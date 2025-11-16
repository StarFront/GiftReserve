import 'dart:typed_data';
import 'dart:convert';

class Gift {
  final String? id;
  final String name;
  final String description;
  final String? imageUrl; // optional URL or filename
  final Uint8List? imageData; // optional raw bytes (in-memory)
  final String? productLink;
  final double price;
  final int quantity;
  final String hostId;
  final bool isReserved;
  final String? reservedBy;
  final DateTime createdAt;

  Gift({
    this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.imageData,
    this.productLink,
    required this.price,
    required this.quantity,
    required this.hostId,
    this.isReserved = false,
    this.reservedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Gift.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['imageData'] != null) {
      try {
        bytes = base64Decode(json['imageData'] as String);
      } catch (_) {
        bytes = null;
      }
    }

    return Gift(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      imageData: bytes,
      productLink: json['productLink'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      hostId: json['hostId'] as String,
      isReserved: json['isReserved'] as bool? ?? false,
      reservedBy: json['reservedBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'imageData': imageData != null ? base64Encode(imageData!) : null,
      'productLink': productLink,
      'price': price,
      'quantity': quantity,
      'hostId': hostId,
      'isReserved': isReserved,
      'reservedBy': reservedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
