import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'product_provider.dart';
import 'product.dart';
import 'widgets.dart';

class DetailScreen extends StatelessWidget {
  final int productId;
  final String imageBaseUrl;

  const DetailScreen({
    super.key,
    required this.productId,
    required this.imageBaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getById(productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produk')),
        body: const EmptyState(message: 'Produk tidak ditemukan'),
      );
    }

    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: AppConfig.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar besar
            Container(
              width: double.infinity,
              height: 250,
              color: AppConfig.lightGreen.withOpacity(0.1),
              child: product.gambar.isNotEmpty
                  ? ProductImage(
                      imageUrl: '$imageBaseUrl${product.imageUrl}',
                      version: product.versiGambar,
                      size: 250,
                    )
                  : Icon(
                      Icons.shopping_bag,
                      size: 80,
                      color: AppConfig.primaryGreen.withOpacity(0.3),
                    ),
            ),

            // Info produk
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppConfig.lightGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.kategori,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConfig.darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product.hargaFormatted,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppConfig.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Info tambahan
                  _infoRow(Icons.inventory, 'ID Produk', '#${product.id}'),
                  const SizedBox(height: 8),
                  if (product.updatedAt != null)
                    _infoRow(
                      Icons.update,
                      'Terakhir diupdate',
                      '${product.updatedAt!.day}/${product.updatedAt!.month}/${product.updatedAt!.year} '
                          '${product.updatedAt!.hour}:${product.updatedAt!.minute.toString().padLeft(2, '0')}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConfig.textLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppConfig.textLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConfig.textDark,
          ),
        ),
      ],
    );
  }
}
