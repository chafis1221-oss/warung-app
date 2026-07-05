import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'product.dart';
import 'product_provider.dart';

class AdminForm extends StatelessWidget {
  final TextEditingController namaController;
  final TextEditingController hargaController;
  final TextEditingController newCategoryController;
  final String selectedCategory;
  final bool isEditing;
  final int? editId;
  final String? imagePath;
  final bool hasExistingImage;
  final Function(String?) onCategoryChanged;
  final Function(String) onImagePicked;
  final VoidCallback onSave;
  final VoidCallback? onBack;

  const AdminForm({
    super.key,
    required this.namaController,
    required this.hargaController,
    required this.newCategoryController,
    required this.selectedCategory,
    required this.isEditing,
    required this.editId,
    required this.imagePath,
    this.hasExistingImage = false,
    required this.onCategoryChanged,
    required this.onImagePicked,
    required this.onSave,
    this.onBack,
  });

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) onImagePicked(picked.path);
  }

  Future<void> _submit(BuildContext context) async {
    final nama = namaController.text.trim();
    final hargaText = hargaController.text.replaceAll('.', '').trim();
    if (nama.isEmpty) { _snack(context, 'Nama wajib diisi', true); return; }
    final harga = int.tryParse(hargaText);
    if (harga == null || harga <= 0) { _snack(context, 'Harga > 0', true); return; }

    final provider = context.read<ProductProvider>();
    final p = Product(id: editId ?? 0, nama: nama, harga: harga, kategori: selectedCategory);
    try {
      if (isEditing) {
        await provider.updateProduct(editId!, p);
        if (imagePath != null) await provider.uploadImage(editId!, imagePath!);
        _snack(context, 'Diupdate', false);
      } else {
        final c = await provider.createProduct(p);
        if (imagePath != null) { await provider.uploadImage(c.id, imagePath!); await provider.loadProducts(); }
        _snack(context, 'Ditambahkan', false);
      }
      onSave();
      onBack?.call();
    } catch (e) { _snack(context, e.toString(), true); }
  }

  void _snack(BuildContext c, String m, bool e) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), backgroundColor: e ? AppConfig.errorRed : AppConfig.successGreen, duration: const Duration(seconds: 2)));
  }

  void _categoryDialog(BuildContext context) {
    final provider = context.read<ProductProvider>();
    newCategoryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Kelola Kategori'),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: TextField(controller: newCategoryController, decoration: const InputDecoration(hintText: 'Kategori baru', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () { final c = newCategoryController.text.trim(); if (c.isNotEmpty) { provider.addCategory(c); newCategoryController.clear(); setState(() {}); } }, style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryGreen, foregroundColor: Colors.white), child: const Text('Tambah')),
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
    final imageLabel = hasExistingImage ? '✓ Ada, pilih ganti' : 'Pilih Gambar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(isEditing ? 'Edit Produk' : 'Tambah Produk', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.textDark))),
          IconButton(icon: const Icon(Icons.category, color: AppConfig.primaryGreen), onPressed: () => _categoryDialog(context), tooltip: 'Kelola Kategori'),
        ]),
        const SizedBox(height: 12),
        TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
        const SizedBox(height: 8),
        TextField(controller: hargaController, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()], decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: selectedCategory.isEmpty ? null : selectedCategory, decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), items: provider.allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: onCategoryChanged),
        const SizedBox(height: 8),
        Row(children: [
          ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image, size: 18), label: Text(imageLabel), style: ElevatedButton.styleFrom(backgroundColor: AppConfig.lightGreen, foregroundColor: AppConfig.textDark)),
          if (imagePath != null) ...[const SizedBox(width: 8), Text('✓ Dipilih', style: TextStyle(fontSize: 12, color: AppConfig.successGreen, fontWeight: FontWeight.w600))],
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () => _submit(context), style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: Text(isEditing ? 'Update' : 'Simpan'))),
          if (isEditing) ...[const SizedBox(width: 8), OutlinedButton(onPressed: onBack, style: OutlinedButton.styleFrom(foregroundColor: AppConfig.textLight, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Batal'))],
        ]),
      ]),
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
