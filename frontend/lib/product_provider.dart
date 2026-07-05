import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'product.dart';
import 'api_service.dart';

enum ConnectionStatus { online, offline, serverError }

class ProductProvider extends ChangeNotifier {
  final ApiService api;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  double _minPrice = 0;
  double _maxPrice = double.infinity;
  ConnectionStatus _status = ConnectionStatus.offline;
  DateTime? _lastUpdated;
  bool _isLoading = false;

  ProductProvider({required this.api});

  List<Product> get products => _filteredProducts;
  List<String> get categories {
    return _products
        .map((p) => p.kategori)
        .where((k) => k.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
  ConnectionStatus get status => _status;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isLoading => _isLoading;
  bool get isLocal => api.isLocal;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  int get totalProducts => _products.length;

  void _applyFilters() {
    _filteredProducts = _products.where((p) {
      if (_searchQuery.isNotEmpty &&
          !p.nama.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategory.isNotEmpty && p.kategori != _selectedCategory) {
        return false;
      }
      if (p.harga < _minPrice || p.harga > _maxPrice) {
        return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _minPrice = 0;
    _maxPrice = double.infinity;
    _applyFilters();
  }

  Product? getById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final connected = await api.initConnection();
      if (connected) {
        final version = await api.getVersion();
        bool needFetch = true;

        if (version != null && !api.isVersionChanged(version)) {
          needFetch = false;
        }

        if (needFetch) {
          final products = await api.fetchProducts();
          _products = products;
          _lastUpdated = DateTime.now();
          await _saveToCache();
        } else {
          await _loadFromCache();
        }

        _status = ConnectionStatus.online;
      } else {
        final loaded = await _loadFromCache();
        if (loaded) {
          _status = ConnectionStatus.serverError;
        } else {
          _status = ConnectionStatus.offline;
        }
      }
    } catch (_) {
      await _loadFromCache();
      _status = ConnectionStatus.serverError;
    }

    _applyFilters();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> _saveToCache() async {
    final box = Hive.box('products');
    final data = _products
        .map((p) => jsonEncode({
              'id': p.id,
              'nama': p.nama,
              'harga': p.harga,
              'kategori': p.kategori,
              'gambar': p.gambar,
              'versi_gambar': p.versiGambar,
              'created_at': p.createdAt?.toIso8601String(),
              'updated_at': p.updatedAt?.toIso8601String(),
            }))
        .toList();
    await box.put('data', data);
    await box.put('updated', _lastUpdated?.toIso8601String());
  }

  Future<bool> _loadFromCache() async {
    final box = Hive.box('products');
    final data = box.get('data');
    if (data != null && data is List) {
      _products = data.map((e) {
        final map = jsonDecode(e);
        return Product(
          id: map['id'] ?? 0,
          nama: map['nama'] ?? '',
          harga: map['harga'] ?? 0,
          kategori: map['kategori'] ?? '',
          gambar: map['gambar'] ?? '',
          versiGambar: map['versi_gambar'] ?? '',
          createdAt: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'])
              : null,
          updatedAt: map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'])
              : null,
        );
      }).toList();
      final updated = box.get('updated');
      if (updated != null) {
        _lastUpdated = DateTime.tryParse(updated);
      }
      return true;
    }
    return false;
  }

  Future<void> createProduct(Product product) async {
    final created = await api.createProduct(product);
    _products.add(created);
    _applyFilters();
    await _saveToCache();
  }

  Future<void> updateProduct(int id, Product product) async {
    await api.updateProduct(id, product);
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = Product(
        id: id,
        nama: product.nama,
        harga: product.harga,
        kategori: product.kategori,
        gambar: _products[index].gambar,
        versiGambar: _products[index].versiGambar,
      );
    }
    _applyFilters();
    await _saveToCache();
  }

  Future<void> deleteProduct(int id) async {
    await api.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    _applyFilters();
    await _saveToCache();
  }

  Future<void> uploadImage(int id, String filePath) async {
    final result = await api.uploadImage(id, filePath);
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = Product(
        id: id,
        nama: _products[index].nama,
        harga: _products[index].harga,
        kategori: _products[index].kategori,
        gambar: result['gambar'] ?? '',
        versiGambar: result['versi_gambar'] ?? '',
      );
    }
    _applyFilters();
    await _saveToCache();
  }
}
