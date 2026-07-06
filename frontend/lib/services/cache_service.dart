import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class CacheService {
  static const _boxName = 'products';

  static Future<void> saveProducts(List<Product> products, DateTime? lastUpdated) async {
    final box = Hive.box(_boxName);
    final data = products.map((p) => jsonEncode({
      'id': p.id, 'nama': p.nama, 'harga': p.harga, 'kategori': p.kategori,
      'gambar': p.gambar, 'versi_gambar': p.versiGambar,
      'created_at': p.createdAt?.toIso8601String(), 'updated_at': p.updatedAt?.toIso8601String(),
    })).toList();
    await box.put('data', data);
    await box.put('updated', lastUpdated?.toIso8601String());
  }

  static Future<List<Product>> loadProducts() async {
    final box = Hive.box(_boxName);
    final data = box.get('data');
    if (data == null || data is! List) return [];
    return data.map((e) {
      final map = jsonDecode(e);
      return Product(
        id: map['id'] ?? 0, nama: map['nama'] ?? '', harga: map['harga'] ?? 0,
        kategori: map['kategori'] ?? '', gambar: map['gambar'] ?? '', versiGambar: map['versi_gambar'] ?? '',
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
        updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      );
    }).toList();
  }

  static Future<DateTime?> loadLastUpdated() async {
    final box = Hive.box(_boxName);
    final updated = box.get('updated');
    return updated != null ? DateTime.tryParse(updated) : null;
  }

  static Future<void> saveCategories(List<String> categories) async {
    final box = Hive.box(_boxName);
    await box.put('custom_categories', categories);
  }

  static List<String> loadCategories() {
    final box = Hive.box(_boxName);
    final data = box.get('custom_categories');
    return data is List ? data.cast<String>() : [];
  }
}
