import 'dart:io';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'product.dart';
import 'product_provider.dart';

class AdminForm extends StatefulWidget {
  final bool fromHome;
  const AdminForm({super.key, this.fromHome = false});

  @override
  State<AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<AdminForm> {
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _newCategoryController = TextEditingController();
  String _selectedCategory = '';
  String? _imagePath;

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  Future<void> _submit() async {
    final nama = _namaController.text.trim();
    final hargaText = _hargaController.text.replaceAll('.', '').trim();
    if (nama.isEmpty) { _snack('Nama wajib diisi', true); return; }
    final harga = int.tryParse(hargaText);
    if (harga == null || harga <= 0) { _snack('Harga > 0', true); return; }

    final provider = context.read<ProductProvider>();
    final p = Product(id: 0, nama: nama, harga: harga, kategori: _selectedCategory);
    try {
      final created = await provider.createProduct(p);
      if (_imagePath != null) {
        await provider.uploadImage(created.id, _imagePath!);
        await provider.loadProducts();
      }
      _snack('Produk ditambahkan', false);
      if (mounted) Navigator.pop(context);
    } catch (e) { _snack(e.toString(), true); }
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

    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        backgroundColor: AppConfig.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
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
              child: Image.file(
                java.io.File(_imagePath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
