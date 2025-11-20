import 'package:flutter/material.dart';
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/services/gift_service.dart';
import 'package:giflist/services/auth_api.dart';
import 'package:giflist/screens/gift_detail_screen.dart';

class ViewGiftsGuestScreen extends StatefulWidget {
  const ViewGiftsGuestScreen({super.key});

  @override
  State<ViewGiftsGuestScreen> createState() => _ViewGiftsGuestScreenState();
}

class _ViewGiftsGuestScreenState extends State<ViewGiftsGuestScreen> {
  final GiftService _giftService = giftService;
  final AuthApi _authApi = AuthApi();
  List<Gift> _gifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  void _loadGifts() {
    setState(() {
      _gifts = _giftService.getAll();
    });
  }

  void _toggleReservation(Gift g) {
    final user = _authApi.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar')),
      );
      return;
    }

    if (!g.isReserved) {
      // Reservar: marcar y asignar reservedBy
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
        isReserved: true,
        reservedBy: user.id,
        createdAt: g.createdAt,
      );
      _giftService.update(g.id!, updated);
      _loadGifts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regalo reservado'), backgroundColor: Color(0xFFE91E8C)),
      );
      return;
    }

    // Cancelar: sólo si yo reservé
    if (g.reservedBy != null && g.reservedBy == user.id) {
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
      _loadGifts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada'), backgroundColor: Color(0xFFE91E8C)),
      );
      return;
    }

    // Si llegó aquí, otro usuario reservó
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No puedes cancelar: reserva hecha por otra persona')),
    );
  }

  Widget _buildTile(Gift g) {
    return InkWell(
      onTap: () async {
        // abrir detalle y refrescar después
        await Navigator.push(context, MaterialPageRoute(builder: (_) => GiftDetailScreen(gift: g)));
        _loadGifts();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area (larger)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(g.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            // Availability badge (top-right of details)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: g.isReserved ? Colors.orange[200] : Colors.green[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(g.isReserved ? 'Reservado' : 'Disponible', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(g.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('Precio: ${g.price}', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),

                    // Action button aligned bottom-right
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () => _toggleReservation(g),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: g.isReserved ? Colors.white : const Color(0xFFE91E8C),
                          side: g.isReserved ? const BorderSide(color: Color(0xFFE91E8C)) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          g.isReserved ? 'Cancelar' : 'Reservar',
                          style: TextStyle(color: g.isReserved ? const Color(0xFFE91E8C) : Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Regalos'),
        backgroundColor: const Color(0xFFE91E8C),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authApi.logout();
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _gifts.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No hay regalos aún', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => _loadGifts(),
                child: ListView.builder(
                  itemCount: _gifts.length,
                  itemBuilder: (_, i) => _buildTile(_gifts[i]),
                ),
              ),
      ),
    );
  }
}
