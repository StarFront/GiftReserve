import 'package:flutter/material.dart';
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/services/gift_service.dart';
import 'package:giflist/services/auth_api.dart';
import 'package:giflist/screens/gift_detail_screen.dart';

class ViewMyReservationsScreen extends StatefulWidget {
  const ViewMyReservationsScreen({super.key});

  @override
  State<ViewMyReservationsScreen> createState() => _ViewMyReservationsScreenState();
}

class _ViewMyReservationsScreenState extends State<ViewMyReservationsScreen> {
  final GiftService _giftService = giftService;
  final AuthApi _authApi = AuthApi();
  List<Gift> _my = [];

  @override
  void initState() {
    super.initState();
    _loadMy();
  }

  void _loadMy() {
    final user = _authApi.getCurrentUser();
    if (user == null) {
      setState(() => _my = []);
      return;
    }
    setState(() {
      _my = _giftService.getAll().where((g) => g.reservedBy == user.id).toList();
    });
  }

  void _cancelReservation(Gift g) {
    final user = _authApi.getCurrentUser();
    if (user == null) return;
    if (g.reservedBy != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes cancelar esta reserva')));
      return;
    }
    final updated = Gift(
      id: g.id,
      name: g.name,
      description: g.description,
      imageUrl: g.imageUrl,
      imageData: g.imageData,
      productLink: g.productLink,
      price: g.price,
      quantity: g.quantity,
      hostId: g.hostId,
      isReserved: false,
      reservedBy: null,
      createdAt: g.createdAt,
    );
    _giftService.update(g.id!, updated);
    _loadMy();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada'), backgroundColor: Color(0xFFE91E8C)));
  }

  Widget _tile(Gift g) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => GiftDetailScreen(gift: g)));
        _loadMy();
      },
      child: Card(
        color: Colors.pink[50],
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image area
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[200]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: g.imageData != null
                          ? Image.memory(g.imageData!, fit: BoxFit.cover)
                          : (g.imageUrl != null && g.imageUrl!.startsWith('http')
                              ? Image.network(g.imageUrl!, fit: BoxFit.cover)
                              : Center(child: Text(g.imageUrl != null ? g.imageUrl!.substring(0, 1) : '?'))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(g.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('Precio: ${g.price}', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Badge top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFD89E), borderRadius: BorderRadius.circular(12)),
                child: const Text('Reservado', style: TextStyle(fontSize: 12)),
              ),
            ),
            // Cancel button bottom-right corner
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton(
                onPressed: () => _cancelReservation(g),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE91E8C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE91E8C))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas'), backgroundColor: const Color(0xFFE91E8C)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _my.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.card_giftcard, size: 64, color: Colors.grey), SizedBox(height: 12), Text('No tienes reservas', style: TextStyle(color: Colors.grey))]))
            : RefreshIndicator(
                onRefresh: () async => _loadMy(),
                child: ListView.builder(itemCount: _my.length, itemBuilder: (_, i) => _tile(_my[i])),
              ),
      ),
    );
  }
}
