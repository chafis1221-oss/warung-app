import 'package:flutter/material.dart';
import 'config.dart';
import 'product.dart';
import 'admin_form.dart';
import 'admin_list.dart';

class AdminScreen extends StatefulWidget {
  final Product? editProduct;
  const AdminScreen({super.key, this.editProduct});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Product? _currentEditProduct;

  // Kontrol form
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
    _currentEditProduct = widget.editProduct;
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentEditProduct != null) {
        _loadProduct(_currentEditProduct!);
        _tabController.animateTo(0);
      }
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _newCategoryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadProduct(Product p) {
    setState(() {
      _isEditing = true;
      _editId = p.id;
      _namaController.text = p.nama;
      _hargaController.text = p.harga.toString();
      _selectedCategory = p.kategori;
      _imagePath = null;
      _currentEditProduct = p;
    });
  }

  void _resetForm() {
    _namaController.clear();
    _hargaController.clear();
    setState(() {
      _isEditing = false;
      _editId = null;
      _selectedCategory = '';
      _imagePath = null;
      _currentEditProduct = null;
    });
  }

  void _onEditFromList(Product product) {
    _loadProduct(product);
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      appBar: AppBar(
        title: Text(_currentEditProduct != null ? 'Edit Produk' : 'Admin'),
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
          AdminForm(
            namaController: _namaController,
            hargaController: _hargaController,
            newCategoryController: _newCategoryController,
            selectedCategory: _selectedCategory,
            isEditing: _isEditing,
            editId: _editId,
            imagePath: _imagePath,
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat ?? ''),
            onImagePicked: (path) => setState(() => _imagePath = path),
            onSave: () {
              _resetForm();
              _tabController.animateTo(1);
            },
            onBack: () {
              // Bug 1 fix: kalau dari home, pop langsung
              if (widget.editProduct != null) {
                Navigator.pop(context);
              } else {
                _resetForm();
                _tabController.animateTo(1);
              }
            },
          ),
          AdminList(onEdit: _onEditFromList),
        ],
      ),
    );
  }
}
