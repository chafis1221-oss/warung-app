import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuse/fuse.dart';
import 'product.dart';
import 'api_service.dart';

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

  static const List<String> defaultCategories = [
    'Sembako', 'Minuman', 'Makanan Instan', 'Camilan', 'Kebersihan',
  ];

  List<String> _customCategories = [];
  List<String> get customCategories => List.unmodifiable(_customCategories);

  ProductProvider({required this.api}) {
    _loadCategoriesFromCache();
  }

  List<Product> get products => _filteredProducts;
  SortMode get sortMode => _sortMode;

  List<String> get allCategories {
    final set = <String>{};
    set.addAll(defaultCategories);
    set.addAll(_customCategories);
    for (final p in _products) {
      if (p.kategori.isNotEmpty) set.add(p.kategori);
    }
    final list = set.toList()..sort();
    return list;
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

  // =============================================
  // SEARCH ENGINE MODERN
  // =============================================

  /// Normalisasi teks
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // hapus tanda baca
        .replaceAll(RegExp(r'\s+'), ' ')    // rapikan spasi
        .trim();
  }

  /// Jaro-Winkler similarity
  double _jaroWinkler(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final s1 = a.length <= b.length ? a : b;
    final s2 = a.length <= b.length ? b : a;

    final matchDistance = (s2.length ~/ 2) - 1;
    final s1Matches = List<bool>.filled(s1.length, false);
    final s2Matches = List<bool>.filled(s2.length, false);

    int matches = 0;
    for (int i = 0; i < s1.length; i++) {
      final start = i - matchDistance > 0 ? i - matchDistance : 0;
      final end = i + matchDistance + 1 < s2.length ? i + matchDistance + 1 : s2.length;
      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true;
          s2Matches[j] = true;
          matches++;
          break;
        }
      }
    }
    if (matches == 0) return 0.0;

    int transpositions = 0;
    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) {
        while (!s2Matches[k]) k++;
        if (s1[i] != s2[k]) transpositions++;
        k++;
      }
    }

    final jaro = (matches / s1.length +
        matches / s2.length +
        (matches - transpositions / 2) / matches) /
        3.0;

    int prefix = 0;
    for (int i = 0; i < min(4, s1.length); i++) {
      if (s1[i] == s2[i]) prefix++; else break;
    }

    return jaro + (prefix * 0.1 * (1 - jaro));
  }

  /// Levenshtein distance
  int _levenshtein(String a, String b) {
    final costs = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) costs[i][0] = i;
    for (int j = 0; j <= b.length; j++) costs[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        costs[i][j] = a[i - 1] == b[j - 1]
            ? costs[i - 1][j - 1]
            : 1 + min(costs[i - 1][j], min(costs[i][j - 1], costs[i - 1][j - 1]));
      }
    }
    return costs[a.length][b.length];
  }

  /// Fuzzy search gabungan Fuse + Jaro-Winkler + Levenshtein
  List<Product> _fuzzySearch(String query) {
    if (query.isEmpty) return List.from(_products);

    final normalizedQuery = _normalize(query);
    final queryWords = normalizedQuery.split(' ');

    // 1. Fuse (mesin utama)
    final fuse = Fuse(
      _products.map((p) => {
        'id': p.id,
        'nama': _normalize(p.nama),
      }).toList(),
      options: FuseOptions(
        keys: ['nama'],
        threshold: 0.5,
        distance: 100,
      ),
    );

    // Cari per kata, gabungkan hasil
    Set<int> allMatchedIds = {};
    for (final word in queryWords) {
      final results = fuse.search(word);
      for (final r in results) {
        allMatchedIds.add(r.item['id'] as int);
      }
    }

    // 2. Jaro-Winkler untuk typo kecil (jika Fuse kurang hasil)
    if (allMatchedIds.length < 3) {
      final jwThreshold = 0.80;
      for (final p in _products) {
        final normalizedNama = _normalize(p.nama);
        final namaWords = normalizedNama.split(' ');
        for (final qWord in queryWords) {
          for (final nWord in namaWords) {
            if (_jaroWinkler(qWord, nWord) >= jwThreshold) {
              allMatchedIds.add(p.id);
              break;
            }
          }
        }
      }
    }

    // 3. Levenshtein untuk perbandingan akhir
    final candidates = _products.where((p) => allMatchedIds.contains(p.id)).toList();
    if (candidates.isEmpty && queryWords.length == 1 && queryWords[0].length >= 3) {
      // Fallback: cari Levenshtein terdekat
      int bestDist = 999;
      Product? best;
      for (final p in _products) {
        final dist = _levenshtein(queryWords[0], _normalize(p.nama));
        if (dist < bestDist) {
          bestDist = dist;
          best = p;
        }
      }
      if (best != null && bestDist <= 3) {
        return [best];
      }
    }

    return candidates;
  }

  void _applyFilters() {
    _filteredProducts = _fuzzySearch(_searchQuery)
        .where((p) {
          if (_selectedCategory.isNotEmpty && p.kategori != _selectedCategory) return false;
          if (p.harga < _minPrice || p.harga > _maxPrice) return false;
          return true;
        })
        .toList();
    _sortProducts();
    notifyListeners();
  }

  // =============================================
  // SORT
  // =============================================

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    _applyFilters();
  }

  void _sortProducts() {
    switch (_sortMode) {
      case SortMode.defaultSort:
      case SortMode.nameAsc:
        _filteredProducts.sort((a, b) => a.nama.compareTo(b.nama));
        break;
      case SortMode.nameDesc:
        _filteredProducts.sort((a, b) => b.nama.compareTo(a.nama));
        break;
      case SortMode.priceLow:
        _filteredProducts.sort((a, b) => a.harga.compareTo(b.harga));
        break;
      case SortMode.priceHigh:
        _filteredProducts.sort((a, b) => b.harga.compareTo(a.harga));
        break;
    }
  }

  // =============================================
  // KATEGORI CUSTOM
  // =============================================

  void addCategory(String cat) {
    cat = cat.trim();
    if (cat.isEmpty || _customCategories.contains(cat)) return;
    if (defaultCategories.contains(cat)) return;
    _customCategories.add(cat);
    _customCategories.sort();
    _saveCategoriesToCache();
    notifyListeners();
  }

  void removeCategory(String cat) {
    _customCategories.remove(cat);
    _saveCategoriesToCache();
    notifyListeners();
  }

  Future<void> _saveCategoriesToCache() async {
    final box = Hive.box('products');
    await box.put('custom_categories', _customCategories);
  }

  void _loadCategoriesFromCache() {
    final box = Hive.box('products');
    final data = box.get('custom_categories');
    if (data != null && data is List) {
      _customCategories = data.cast<String>();
    }
  }

  // =============================================
  // FILTER UI
  // =============================================

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
    try { return _products.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }

  // =============================================
  // DATA LOADING & CACHE
  // =============================================

  Future<bool> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final connected = await api.initConnection();
      if (connected) {
        final version = await api.getVersion();
        bool needFetch = true;
        if (version != null && !api.isVersionChanged(version)) needFetch = false;
        if (needFetch) {
          _products = await api.fetchProducts();
          _lastUpdated = DateTime.now();
          await _saveToCache();
        } else {
          await _loadFromCache();
        }
        _status = ConnectionStatus.online;
      } else {
        final loaded = await _loadFromCache();
        _status = loaded ? ConnectionStatus.serverError : ConnectionStatus.offline;
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
    final data = _products.map((p) => jsonEncode({
      'id': p.id, 'nama': p.nama, 'harga': p.harga, 'kategori': p.kategori,
      'gambar': p.gambar, 'versi_gambar': p.versiGambar,
      'created_at': p.createdAt?.toIso8601String(), 'updated_at': p.updatedAt?.toIso8601String(),
    })).toList();
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
          id: map['id'] ?? 0, nama: map['nama'] ?? '', harga: map['harga'] ?? 0,
          kategori: map['kategori'] ?? '', gambar: map['gambar'] ?? '', versiGambar: map['versi_gambar'] ?? '',
          createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
          updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
        );
      }).toList();
      final updated = box.get('updated');
      if (updated != null) _lastUpdated = DateTime.tryParse(updated);
      return true;
    }
    return false;
  }

  // =============================================
  // CRUD
  // =============================================

  Future<Product> createProduct(Product product) async {
    final created = await api.createProduct(product);
    _products.add(created);
    _applyFilters();
    await _saveToCache();
    return created;
  }

  Future<void> updateProduct(int id, Product product) async {
    await api.updateProduct(id, product);
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = Product(
        id: id, nama: product.nama, harga: product.harga, kategori: product.kategori,
        gambar: _products[index].gambar, versiGambar: _products[index].versiGambar,
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
        id: id, nama: _products[index].nama, harga: _products[index].harga,
        kategori: _products[index].kategori,
        gambar: result['gambar'] ?? '', versiGambar: result['versi_gambar'] ?? '',
      );
    }
    _applyFilters();
    await _saveToCache();
  }
}
