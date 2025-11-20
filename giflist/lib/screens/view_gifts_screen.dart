import 'package:flutter/material.dart';
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/screens/add_gift_screen.dart';
import 'package:giflist/screens/gift_detail_screen.dart';
import 'package:giflist/services/gift_service.dart';
import 'package:giflist/services/gift_remote_service.dart';

class ViewGiftsScreen extends StatefulWidget {
  const ViewGiftsScreen({super.key});

  @override
  State<ViewGiftsScreen> createState() => _ViewGiftsScreenState();
}

class _ViewGiftsScreenState extends State<ViewGiftsScreen> {
  final GiftService _giftService = giftService; // fallback local
  final GiftRemoteService _remote = GiftRemoteService();
  List<Gift> _gifts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _remote.list();
      if (!mounted) return;
      setState(() => _gifts = list);
    } catch (e) {
      // fallback local
      setState(() {
        _gifts = _giftService.getAll();
        _error = 'Remoto falló: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDelete(String id) {
    // TODO: endpoint delete remoto (MVP: sólo local si existe)
    _giftService.delete(id);
    _loadGifts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Regalo eliminado (local)'), backgroundColor: Color(0xFFE91E8C)),
    );
  }

  Future<void> _onEdit(Gift gift) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddGiftScreen(giftToEdit: gift)),
    );
    _loadGifts();
  }

  Widget _buildTile(Gift g) {
    return InkWell(
      onTap: () async {
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
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(g.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        // Availability badge
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
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _onEdit(g),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar regalo'),
                        content: const Text('¿Estás seguro de eliminar este regalo?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _onDelete(g.id!);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        title: const Text('Regalos'),
        backgroundColor: const Color(0xFFE91E8C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_gifts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_error != null ? '$_error' : 'No hay regalos aún', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E8C)),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGiftScreen()));
                            _loadGifts();
                          },
                          child: const Text('Agregar regalo'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadGifts(),
                    child: ListView.builder(
                      itemCount: _gifts.length,
                      itemBuilder: (_, i) => _buildTile(_gifts[i]),
                    ),
                  )),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE91E8C),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGiftScreen()));
          _loadGifts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
