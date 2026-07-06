import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/product.dart';

class ApiService {
  String _baseUrl = AppConfig.localBaseUrl;
  bool _isLocal = true;
  String _lastVersion = '';

  String get baseUrl => _baseUrl;
  bool get isLocal => _isLocal;

  Future<bool> _tryConnect(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/health'))
          .timeout(AppConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> initConnection() async {
    final localOk = await _tryConnect(AppConfig.localBaseUrl);
    if (localOk) {
      _baseUrl = AppConfig.localBaseUrl;
      _isLocal = true;
      return true;
    }

    final tunnelOk = await _tryConnect(AppConfig.tunnelBaseUrl);
    if (tunnelOk) {
      _baseUrl = AppConfig.tunnelBaseUrl;
      _isLocal = false;
      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>?> getVersion() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/products/version'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  bool isVersionChanged(Map<String, dynamic> versionData) {
    final hash = versionData['hash'] ?? '';
    if (hash != _lastVersion) {
      _lastVersion = hash;
      return true;
    }
    return false;
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/products'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Failed to load products');
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    if (response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Gagal menyimpan');
  }

  Future<void> updateProduct(int id, Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Gagal mengupdate');
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/products/$id'),
    );
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus');
    }
  }

  Future<Map<String, String>> uploadImage(int id, String filePath) async {
    final uri = Uri.parse('$_baseUrl/api/products/$id/image');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('gambar', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return Map<String, String>.from(json.decode(body));
    }
    final error = json.decode(body);
    throw Exception(error['message'] ?? 'Gagal upload');
  }

  String imageUrl(String gambar) {
    if (gambar.isEmpty) return '';
    return '$_baseUrl/images/$gambar';
  }
}
