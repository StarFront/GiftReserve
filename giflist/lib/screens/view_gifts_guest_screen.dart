import 'package:flutter/material.dart';
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/services/gift_service.dart';
import 'package:giflist/services/gift_remote_service.dart';
import 'package:giflist/services/auth_api.dart';
import 'package:giflist/screens/gift_detail_screen.dart';

class ViewGiftsGuestScreen extends StatefulWidget {
  const ViewGiftsGuestScreen({super.key});

  @override
  State<ViewGiftsGuestScreen> createState() => _ViewGiftsGuestScreenState();
}

class _ViewGiftsGuestScreenState extends State<ViewGiftsGuestScreen> {
  final GiftService _giftService = giftService; // fallback temporal
  final GiftRemoteService _remote = GiftRemoteService();
  final AuthApi _authApi = AuthApi();
  List<Gift> _gifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    try {
      final list = await _remote.list();
      if (!mounted) return;
      setState(() => _gifts = list);
    } catch (e) {
      // fallback local si remoto falla
      setState(() => _gifts = _giftService.getAll());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aviso: lista local por error remoto: $e')),
      );
    }
  }

  void _toggleReservation(Gift g) {
    final user = _authApi.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para reservar')));
      return;
    }
    // Evitar doble taps
    if (g.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regalo sin id remoto')));
      return;
    }
    () async {
      try {
        Gift updated;
        if (!g.isReserved) {
          updated = await _remote.reserve(g.id!, userId: user.id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservado')));
        } else {
          // Solo permitir cancelar si reservado por mismo usuario (MVP: verificación local)
          if (g.reservedBy != null && g.reservedBy == user.id) {
            updated = await _remote.cancel(g.id!, userId: user.id);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes cancelar esta reserva')));
            return;
          }
        }
        setState(() {
          final idx = _gifts.indexWhere((x) => x.id == g.id);
          if (idx != -1) {
            _gifts[idx] = updated;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error remoto reserva: $e')));
      }
    }();
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
