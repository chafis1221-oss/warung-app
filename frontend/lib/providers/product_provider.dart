import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/search_service.dart';

enum ConnectionStatus { online, offline, serverError }
enum SortMode { defaultSort, nameAsc, nameDesc, priceLow, priceHigh }

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
  SortMode _sortMode = SortMode.defaultSort;

  static const List<String> defaultCategories = ['Sembako', 'Minuman', 'Makanan Instan', 'Camilan', 'Kebersihan'];
  List<String> _customCategories = [];

  ProductProvider({required this.api}) { _customCategories = CacheService.loadCategories(); }

  List<Product> get products => _filteredProducts;
  SortMode get sortMode => _sortMode;
  List<String> get customCategories => List.unmodifiable(_customCategories);

  List<String> get allCategories {
    final set = <String>{};
    set.addAll(defaultCategories);
    set.addAll(_customCategories);
    for (final p in _products) { if (p.kategori.isNotEmpty) set.add(p.kategori); }
    return set.toList()..sort();
  }

  ConnectionStatus get status => _status;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isLoading => _isLoading;
  bool get isLocal => api.isLocal;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  int get totalProducts => _products.length;

  void _applyFilters() {
    _filteredProducts = SearchService.fuzzySearch(_searchQuery, _products)
        .where((p) {
          if (_selectedCategory.isNotEmpty && p.kategori != _selectedCategory) return false;
          if (p.harga < _minPrice || p.harga > _maxPrice) return false;
          return true;
        }).toList();
    _sortProducts();
    notifyListeners();
  }

  void setSearch(String q) { _searchQuery = q; _applyFilters(); }
  void setCategory(String c) { _selectedCategory = c; _applyFilters(); }
  void setSortMode(SortMode m) { _sortMode = m; _applyFilters(); }
  void resetFilters() { _searchQuery = ''; _selectedCategory = ''; _applyFilters(); }

  void _sortProducts() {
    switch (_sortMode) {
      case SortMode.nameAsc: _filteredProducts.sort((a, b) => a.nama.compareTo(b.nama)); break;
      case SortMode.nameDesc: _filteredProducts.sort((a, b) => b.nama.compareTo(a.nama)); break;
      case SortMode.priceLow: _filteredProducts.sort((a, b) => a.harga.compareTo(b.harga)); break;
      case SortMode.priceHigh: _filteredProducts.sort((a, b) => b.harga.compareTo(a.harga)); break;
      default: _filteredProducts.sort((a, b) => a.nama.compareTo(b.nama));
    }
  }

  Product? getById(int id) { try { return _products.firstWhere((p) => p.id == id); } catch (_) { return null; } }

  // Kategori
  void addCategory(String c) { c = c.trim(); if (c.isEmpty || _customCategories.contains(c) || defaultCategories.contains(c)) return; _customCategories.add(c); _customCategories.sort(); CacheService.saveCategories(_customCategories); notifyListeners(); }
  void removeCategory(String c) { _customCategories.remove(c); CacheService.saveCategories(_customCategories); notifyListeners(); }

  // Load
  Future<bool> loadProducts() async {
    _isLoading = true; notifyListeners();
    try {
      final connected = await api.initConnection();
      if (connected) {
        final version = await api.getVersion();
        if (version != null && !api.isVersionChanged(version)) {
          _products = await CacheService.loadProducts();
          _lastUpdated = await CacheService.loadLastUpdated();
        } else {
          _products = await api.fetchProducts();
          _lastUpdated = DateTime.now();
          await CacheService.saveProducts(_products, _lastUpdated);
        }
        _status = ConnectionStatus.online;
      } else {
        _products = await CacheService.loadProducts();
        _lastUpdated = await CacheService.loadLastUpdated();
        _status = _products.isNotEmpty ? ConnectionStatus.serverError : ConnectionStatus.offline;
      }
    } catch (_) {
      _products = await CacheService.loadProducts();
      _lastUpdated = await CacheService.loadLastUpdated();
      _status = _products.isNotEmpty ? ConnectionStatus.serverError : ConnectionStatus.offline;
    }
    _applyFilters(); _isLoading = false; notifyListeners();
    return true;
  }

  // CRUD
  Future<Product> createProduct(Product p) async {
    final c = await api.createProduct(p); _products.add(c); _applyFilters();
    await CacheService.saveProducts(_products, _lastUpdated); return c;
  }
  Future<void> updateProduct(int id, Product p) async {
    await api.updateProduct(id, p);
    final i = _products.indexWhere((x) => x.id == id);
    if (i != -1) _products[i] = Product(id: id, nama: p.nama, harga: p.harga, kategori: p.kategori, gambar: _products[i].gambar, versiGambar: _products[i].versiGambar);
    _applyFilters(); await CacheService.saveProducts(_products, _lastUpdated);
  }
  Future<void> deleteProduct(int id) async {
    await api.deleteProduct(id); _products.removeWhere((x) => x.id == id);
    _applyFilters(); await CacheService.saveProducts(_products, _lastUpdated);
  }
  Future<void> uploadImage(int id, String path) async {
    final r = await api.uploadImage(id, path);
    final i = _products.indexWhere((x) => x.id == id);
    if (i != -1) _products[i] = Product(id: id, nama: _products[i].nama, harga: _products[i].harga, kategori: _products[i].kategori, gambar: r['gambar'] ?? '', versiGambar: r['versi_gambar'] ?? '');
    _applyFilters(); await CacheService.saveProducts(_products, _lastUpdated);
  }
}
