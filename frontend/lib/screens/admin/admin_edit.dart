import 'dart:io';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'models/product.dart';
import 'providers/product_provider.dart';

class AdminEdit extends StatefulWidget {
  final Product product;
  final bool fromHome;
  const AdminEdit({super.key, required this.product, this.fromHome = false});

  @override
  State<AdminEdit> createState() => _AdminEditState();
}

class _AdminEditState extends State<AdminEdit> {
  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  final _newCategoryController = TextEditingController();
  late String _selectedCategory;
  String? _imagePath;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _namaController = TextEditingController(text: p.nama);
    _hargaController = TextEditingController(text: _formatHarga(p.harga));
    _selectedCategory = p.kategori;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  String _formatHarga(int harga) {
    final text = harga.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
        _imageChanged = true;
      });
    }
  }

  Future<void> _update() async {
    final nama = _namaController.text.trim();
    final hargaText = _hargaController.text.replaceAll('.', '').trim();
    if (nama.isEmpty) { _snack('Nama wajib diisi', true); return; }
    final harga = int.tryParse(hargaText);
    if (harga == null || harga <= 0) { _snack('Harga > 0', true); return; }

    final provider = context.read<ProductProvider>();
    final p = Product(id: widget.product.id, nama: nama, harga: harga, kategori: _selectedCategory);
    try {
      await provider.updateProduct(widget.product.id, p);
      if (_imageChanged && _imagePath != null) {
        await provider.uploadImage(widget.product.id, _imagePath!);
        await provider.loadProducts();
      }
      _snack('Produk diupdate', false);
      if (mounted) Navigator.pop(context);
    } catch (e) { _snack(e.toString(), true); }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin hapus "${widget.product.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppConfig.errorRed), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await context.read<ProductProvider>().deleteProduct(widget.product.id);
        if (mounted) {
          _snack('Produk dihapus', false);
          Navigator.pop(context);
        }
      } catch (e) { _snack(e.toString(), true); }
    }
  }

  void _snack(String m, bool e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: e ? AppConfig.errorRed : AppConfig.successGreen, duration: const Duration(seconds: 2)));
  }

  void _categoryDialog() {
    final provider = context.read<ProductProvider>();
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Kelola Kategori'),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: TextField(controller: _newCategoryController, decoration: const InputDecoration(hintText: 'Kategori baru', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () { final c = _newCategoryController.text.trim(); if (c.isNotEmpty) { provider.addCategory(c); _newCategoryController.clear(); setState(() {}); } }, style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryGreen, foregroundColor: Colors.white), child: const Text('Tambah')),
            ]),
            const SizedBox(height: 12),
            Consumer<ProductProvider>(builder: (_, p, __) {
              if (p.customCategories.isEmpty) return const Text('Belum ada', style: TextStyle(color: AppConfig.textLight));
              return Flexible(child: ListView.builder(shrinkWrap: true, itemCount: p.customCategories.length, itemBuilder: (_, i) => ListTile(dense: true, title: Text(p.customCategories[i]), trailing: IconButton(icon: const Icon(Icons.delete, size: 18, color: AppConfig.errorRed), onPressed: () { provider.removeCategory(p.customCategories[i]); setState(() {}); }))));
            }),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = widget.product;

    // Preview: gambar baru > gambar lama
    final previewUrl = _imagePath != null
        ? null // pakai file lokal
        : (product.gambar.isNotEmpty
            ? (product.isFullUrl ? product.imageUrl : '${provider.api.baseUrl}${product.imageUrl}')
            : null);

    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: AppConfig.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _delete, tooltip: 'Hapus Produk'),
          IconButton(icon: const Icon(Icons.category, color: Colors.white), onPressed: _categoryDialog, tooltip: 'Kelola Kategori'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Preview gambar
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_imagePath!), width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
          ] else if (previewUrl != null && previewUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(previewUrl, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 200, color: AppConfig.lightGreen.withOpacity(0.1), child: const Center(child: Icon(Icons.broken_image, color: AppConfig.textLight)))),
            ),
            const SizedBox(height: 12),
          ],

          TextField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
          const SizedBox(height: 8),
          TextField(controller: _hargaController, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()], decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: provider.allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.darkGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Galeri'),
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.lightGreen, foregroundColor: AppConfig.textDark, padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ]),
          if (product.gambar.isNotEmpty && !_imageChanged)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('✓ Sudah ada gambar', style: TextStyle(fontSize: 11, color: AppConfig.successGreen))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _update,
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) return newValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.length));
  }
}
