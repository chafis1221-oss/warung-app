import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'product.dart';
import 'product_provider.dart';
import 'widgets.dart';

class AdminList extends StatelessWidget {
  final Function(Product) onEdit;

  const AdminList({super.key, required this.onEdit});

  Future<void> _deleteProduct(BuildContext context, int id, String nama) async {
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$nama" dihapus'),
              backgroundColor: AppConfig.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppConfig.errorRed,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      body: Column(
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
                                onPressed: () => onEdit(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                color: AppConfig.errorRed,
                                onPressed: () => _deleteProduct(
                                  context,
                                  product.id,
                                  product.nama,
                                ),
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
    );
  }
}
