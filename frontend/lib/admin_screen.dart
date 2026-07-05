import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'product.dart';
import 'product_provider.dart';
import 'widgets.dart';

class AdminScreen extends StatefulWidget {
  final Product? editProduct;
  const AdminScreen({super.key, this.editProduct});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  String _selectedCategory = '';
  bool _isEditing = false;
  int? _editId;
  String? _imagePath;
  late TabController _tabController;

  final List<String> _defaultCategories = [
    'Sembako',
    'Minuman',
    'Makanan Instan',
    'Camilan',
    'Kebersihan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Jika ada produk yang mau diedit, langsung isi form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editProduct != null) {
        _editProduct(widget.editProduct!);
        _tabController.animateTo(0); // Pindah ke tab Form
      }
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _resetForm() {
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
      _resetForm();
    } catch (e) {
      _showSnack(e.toString(), true);
    }
  }

  Future<void> _deleteProduct(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin hapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppConfig.errorRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ProductProvider>().deleteProduct(id);
        _showSnack('Produk dihapus', false);
      } catch (e) {
        _showSnack(e.toString(), true);
      }
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _isEditing = true;
      _editId = product.id;
      _namaController.text = product.nama;
      _hargaController.text = product.harga.toString();
      _selectedCategory = product.kategori;
      _imagePath = null;
    });
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final allCategories = [..._defaultCategories, ...provider.categories]
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      appBar: AppBar(
        title: Text(widget.editProduct != null ? 'Edit Produk' : 'Admin'),
        backgroundColor: AppConfig.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Form'),
            Tab(text: 'Daftar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Produk' : 'Tambah Produk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConfig.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: allCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedCategory = val ?? ''),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image, size: 18),
                      label: Text(
                          _imagePath != null ? 'Ganti Gambar' : 'Pilih Gambar'),
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
                        onPressed: _resetForm,
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

          // Tab 2: Daftar
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Text(
                      'Daftar Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.totalProducts} item',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConfig.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.products.isEmpty
                    ? const EmptyState(message: 'Belum ada produk')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: provider.products.length,
                        itemBuilder: (_, i) {
                          final product = provider.products[i];
                          return Card(
                            color: AppConfig.cardWhite,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              leading: ProductImage(
                                imageUrl: product.gambar.isNotEmpty
                                    ? (product.isFullUrl
                                        ? product.imageUrl
                                        : '${provider.api.baseUrl}${product.imageUrl}')
                                    : '',
                                version: product.versiGambar,
                                size: 40,
                              ),
                              title: Text(
                                product.nama,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                product.hargaFormatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConfig.darkGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: AppConfig.primaryGreen,
                                    onPressed: () => _editProduct(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: AppConfig.errorRed,
                                    onPressed: () => _deleteProduct(
                                        product.id, product.nama),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
