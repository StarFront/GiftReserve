import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:giflist/models/gift_model.dart';
import 'package:giflist/services/auth_service.dart';
import 'package:giflist/services/gift_service.dart';

class AddGiftScreen extends StatefulWidget {
  final Gift? giftToEdit;
  const AddGiftScreen({super.key, this.giftToEdit});

  @override
  State<AddGiftScreen> createState() => _AddGiftScreenState();
}

class _AddGiftScreenState extends State<AddGiftScreen> {
  final AuthService _authService = AuthService();
  final GiftService _giftService = giftService;

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _priceController = TextEditingController();

  // State
  bool _isLoading = false;
  String? _error;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    final g = widget.giftToEdit;
    if (g != null) {
      _nameController.text = g.name;
      _descriptionController.text = g.description;
      _linkController.text = g.productLink ?? '';
      _priceController.text = g.price.toString();
      _selectedImageName = g.imageUrl;
      _selectedImageBytes = g.imageData;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool _isValidPrice(String price) {
    try {
      double.parse(price);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!mounted) return;
        setState(() {
          _selectedImageBytes = file.bytes;
          _selectedImageName = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al seleccionar imagen: $e')));
    }
  }

  Future<void> _handleAddGift() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      if (_nameController.text.isEmpty) throw Exception('El nombre del regalo es requerido');
      if (_descriptionController.text.isEmpty) throw Exception('La descripción es requerida');
      if (_priceController.text.isEmpty) throw Exception('El precio es requerido');
      if (!_isValidPrice(_priceController.text)) throw Exception('El precio debe ser un número válido');

      final parsedPrice = double.parse(_priceController.text);
      if (parsedPrice <= 0) throw Exception('El precio debe ser un número positivo');

      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final gift = Gift(
        id: widget.giftToEdit?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        productLink: _linkController.text.isNotEmpty ? _linkController.text : null,
        price: parsedPrice,
        quantity: widget.giftToEdit?.quantity ?? 1,
        hostId: user.id,
        imageUrl: _selectedImageName,
        imageData: _selectedImageBytes,
        isReserved: widget.giftToEdit?.isReserved ?? false,
        reservedBy: widget.giftToEdit?.reservedBy,
      );

      if (widget.giftToEdit != null && widget.giftToEdit!.id != null) {
        _giftService.update(widget.giftToEdit!.id!, gift);
      } else {
        _giftService.add(gift);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Regalo agregado exitosamente!'), backgroundColor: Color(0xFFE91E8C)));

        _nameController.clear();
        _descriptionController.clear();
        _linkController.clear();
        _priceController.clear();
        _selectedImageBytes = null;
        _selectedImageName = null;

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Agregar Regalo'),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red[300]!), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
              ),

            Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
              child: _selectedImageBytes != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover)) : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickImage,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]), const SizedBox(height: 8), Text('Agregar imagen', style: TextStyle(color: Colors.grey[600], fontSize: 13))]),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Nombre del regalo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(controller: _nameController, decoration: InputDecoration(hintText: 'Nombre del regalo', prefixIcon: const Icon(Icons.card_giftcard), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)))),
            const SizedBox(height: 16),

            TextField(controller: _descriptionController, maxLines: 3, decoration: InputDecoration(hintText: 'Describe el regalo en detalle...', prefixIcon: const Icon(Icons.description), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)))),
            const SizedBox(height: 16),

            Text('Enlace del regalo (opcional)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(controller: _linkController, decoration: InputDecoration(hintText: 'https://ejemplo.com/producto', prefixIcon: const Icon(Icons.link), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!))), keyboardType: TextInputType.url),
            const SizedBox(height: 16),

            Text('Precio', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(controller: _priceController, decoration: InputDecoration(hintText: 'Ej: 99.99', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!))), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),

            ElevatedButton.icon(onPressed: _isLoading ? null : _handleAddGift, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFFE91E8C), disabledBackgroundColor: Colors.grey[300], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.add), label: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Agregar regalo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
