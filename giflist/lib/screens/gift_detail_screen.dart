import 'package:flutter/material.dart';
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/services/gift_service.dart';
import 'package:giflist/services/gift_remote_service.dart';
import 'package:giflist/services/auth_api.dart';
import 'package:giflist/screens/add_gift_screen.dart';

class GiftDetailScreen extends StatefulWidget {
  final Gift gift;
  const GiftDetailScreen({super.key, required this.gift});

  @override
  State<GiftDetailScreen> createState() => _GiftDetailScreenState();
}

class _GiftDetailScreenState extends State<GiftDetailScreen> {
  final GiftService _giftService = giftService;
  final AuthApi _authApi = AuthApi();
  final GiftRemoteService _remote = GiftRemoteService();
  late Gift _gift;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _gift = widget.gift;
  }

  Future<void> _refreshLocal() async {
    setState(() {
      _gift = _giftService.getAll().firstWhere((g) => g.id == _gift.id, orElse: () => _gift);
    });
  }

  Future<void> _onDelete() async {
    if (_gift.id == null) return;
    _giftService.delete(_gift.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regalo eliminado'), backgroundColor: Color(0xFFE91E8C)));
      Navigator.pop(context);
    }
  }

  Future<void> _onEdit() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddGiftScreen(giftToEdit: _gift)));
    await _refreshLocal();
    setState(() {});
  }

  Future<void> _onAction() async {
    final user = _authApi.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (_gift.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regalo sin id remoto')));
      } else if (!_gift.isReserved) {
        final updated = await _remote.reserve(_gift.id!, userId: user.id);
        _gift = updated;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regalo reservado'), backgroundColor: Color(0xFFE91E8C)));
      } else {
        if (_gift.reservedBy != null && _gift.reservedBy == user.id) {
          final updated = await _remote.cancel(_gift.id!, userId: user.id);
          _gift = updated;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada'), backgroundColor: Color(0xFFE91E8C)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes cancelar: reserva hecha por otra persona')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error remoto: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authApi.getCurrentUser();
    final canCancel = _gift.isReserved && _gift.reservedBy != null && user != null && _gift.reservedBy == user.id;
    final canReserve = !_gift.isReserved && user != null;
    // admin puede editar/eliminar
    final isAdmin = user != null && user.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Regalo'),
        backgroundColor: const Color(0xFFE91E8C),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge and image
            Row(
              children: [
                if (_gift.isReserved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange[200], borderRadius: BorderRadius.circular(12)),
                    child: const Text('Reservado', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_gift.imageData != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_gift.imageData!, height: 180, fit: BoxFit.cover))
            else if (_gift.imageUrl != null && _gift.imageUrl!.startsWith('http'))
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_gift.imageUrl!, height: 180, fit: BoxFit.cover))
            else
              Container(height: 180, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.card_giftcard, size: 48))),

            const SizedBox(height: 16),
            Text(_gift.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_gift.description),
            const SizedBox(height: 16),

            // Details card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detalles del Regalo', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Precio aproximado:'),
                      Text('\$${_gift.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cantidad:'),
                      Text('${_gift.quantity}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Link box
            if (_gift.productLink != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_gift.productLink!, style: const TextStyle(color: Colors.purple))),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Action area: hosts see edit/delete; guests see reserve/cancel
            if (isAdmin)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF42A5F5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Eliminar regalo'),
                                content: const Text('¿Estás seguro de eliminar este regalo?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _onDelete();
                                    },
                                    child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _loading || !(canReserve || canCancel) ? null : _onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canReserve ? const Color(0xFFE91E8C) : Colors.white,
                  side: canCancel ? const BorderSide(color: Color(0xFFE91E8C)) : null,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text(
                        _gift.isReserved ? (canCancel ? 'Cancelar Reserva' : 'Reservado') : 'Reservar Regalo',
                        style: TextStyle(color: canReserve ? Colors.white : const Color(0xFFE91E8C), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
