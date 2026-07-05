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
  final GlobalKey<AdminFormState> _formKey = GlobalKey<AdminFormState>();

  @override
  void initState() {
    super.initState();
    _currentEditProduct = widget.editProduct;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onEditFromList(Product product) {
    setState(() => _currentEditProduct = product);
    _formKey.currentState?.loadProduct(product);
    _tabController.animateTo(0);
  }

  void _onSave() {
    setState(() => _currentEditProduct = null);
    _formKey.currentState?.reset();
    _tabController.animateTo(1);
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
            key: _formKey,
            editProduct: _currentEditProduct,
            onSave: _onSave,
          ),
          AdminList(onEdit: _onEditFromList),
        ],
      ),
    );
  }
}
