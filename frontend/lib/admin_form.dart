import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'product.dart';
import 'product_provider.dart';

class AdminForm extends StatefulWidget {
  final Product? editProduct;
  final VoidCallback? onSave;

  const AdminForm({super.key, this.editProduct, this.onSave});

  @override
  State<AdminForm> createState() => AdminFormState();
}

class AdminFormState extends State<AdminForm> {
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _newCategoryController = TextEditingController();
  String _selectedCategory = '';
  bool _isEditing = false;
  int? _editId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.editProduct != null) {
      loadProduct(widget.editProduct!);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  // Dipanggil dari parent (admin_screen)
  void loadProduct(Product product) {
    setState(() {
      _isEditing = true;
      _editId = product.id;
      _namaController.text = product.nama;
      _hargaController.text = product.harga.toString();
      _selectedCategory = product.kategori;
      _imagePath = null;
    });
  }

  void reset() {
    _namaController.clear();
    _hargaController.clear();
    setState(() {
      _isEditing = false;
      _editId = null;
      _selectedCategory = '';
      _imagePath = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    final nama = _namaController.text.trim();
    final hargaText = _hargaController.text.trim();

    if (nama.isEmpty) {
      _showSnack('Nama produk wajib diisi', true);
      return;
    }
    final harga = int.tryParse(hargaText);
    if (harga == null || harga <= 0) {
      _showSnack('Harga harus angka > 0', true);
      return;
    }

    final provider = context.read<ProductProvider>();
    final product = Product(
      id: _editId ?? 0,
      nama: nama,
      harga: harga,
      kategori: _selectedCategory,
    );

    try {
      if (_isEditing) {
        await provider.updateProduct(_editId!, product);
        if (_imagePath != null) {
          await provider.uploadImage(_editId!, _imagePath!);
        }
        _showSnack('Produk diupdate', false);
      } else {
        final created = await provider.createProduct(product);
        if (_imagePath != null) {
          await provider.uploadImage(created.id, _imagePath!);
          await provider.loadProducts();
        }
        _showSnack('Produk ditambahkan', false);
      }
      reset();
      widget.onSave?.call();
    } catch (e) {
      _showSnack(e.toString(), true);
    }
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppConfig.errorRed : AppConfig.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCategoryDialog() {
    final provider = context.read<ProductProvider>();
    _newCategoryController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Kelola Kategori'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tambah kategori
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(
                          hintText: 'Nama kategori baru',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final cat = _newCategoryController.text.trim();
                        if (cat.isNotEmpty) {
                          provider.addCategory(cat);
                          _newCategoryController.clear();
                          setDialogState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Daftar kategori custom
                Consumer<ProductProvider>(
                  builder: (_, p, __) {
                    if (p.customCategories.isEmpty) {
                      return const Text('Belum ada kategori custom',
                          style: TextStyle(color: AppConfig.textLight));
                    }
                    return Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: p.customCategories.length,
                        itemBuilder: (_, i) {
                          final cat = p.customCategories[i];
                          return ListTile(
                            dense: true,
                            title: Text(cat),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppConfig.errorRed),
                              onPressed: () {
                                provider.removeCategory(cat);
                                setDialogState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ],
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
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
        backgroundColor: AppConfig.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: _showCategoryDialog,
            tooltip: 'Kelola Kategori',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Produk' : 'Tambah Produk',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: provider.allCategories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(_imagePath != null ? 'Ganti Gambar' : 'Pilih Gambar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.lightGreen,
                    foregroundColor: AppConfig.textDark,
                  ),
                ),
                if (_imagePath != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '✓ Gambar dipilih',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConfig.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_isEditing ? 'Update' : 'Simpan'),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
