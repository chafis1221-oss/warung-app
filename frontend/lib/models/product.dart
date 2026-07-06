class Product {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final String gambar;
  final String versiGambar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    this.gambar = '',
    this.versiGambar = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: json['harga'] ?? 0,
      kategori: json['kategori'] ?? '',
      gambar: json['gambar'] ?? '',
      versiGambar: json['versi_gambar'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'harga': harga,
      'kategori': kategori,
    };
  }

  String get hargaFormatted => 'Rp ${harga.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]}.',
      )}';

  // Cek apakah gambar adalah URL lengkap atau hanya nama file
  bool get isFullUrl => gambar.startsWith('http://') || gambar.startsWith('https://');

  String get imageUrl {
    if (gambar.isEmpty) return '';
    if (isFullUrl) return gambar;
    return '/images/$gambar';
  }
}
