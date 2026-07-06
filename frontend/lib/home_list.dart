import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'product.dart';
import 'product_provider.dart';
import 'widgets.dart';
import 'detail_screen.dart';

class HomeList extends StatelessWidget {
  final bool isGridView;
  final Function(Product) onEdit;
  final Function(Product) onDelete;

  const HomeList({
    super.key,
    required this.isGridView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<ProductProvider, List<Product>>(
      selector: (_, p) => p.products,
      builder: (_, products, __) {
        if (products.isEmpty) return const EmptyState();
        final baseUrl = context.read<ProductProvider>().api.baseUrl;
        return RefreshIndicator(
          color: AppConfig.primaryGreen,
          onRefresh: () => context.read<ProductProvider>().loadProducts(),
          child: isGridView ? _buildGrid(products, baseUrl, context) : _buildList(products, baseUrl, context),
        );
      },
    );
  }

  Widget _buildList(List<Product> products, String baseUrl, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final imageUrl = p.gambar.isNotEmpty ? (p.isFullUrl ? p.imageUrl : '$baseUrl${p.imageUrl}') : '';
        return Card(
          color: AppConfig.cardWhite, elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(productId: p.id, imageBaseUrl: baseUrl))),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ProductImage(imageUrl: imageUrl, version: p.versiGambar, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(p.kategori, style: const TextStyle(fontSize: 12, color: AppConfig.textLight)),
                    const SizedBox(height: 4),
                    Text(p.hargaFormatted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppConfig.darkGreen)),
                  ]),
                ),
                Column(children: [
                  IconButton(icon: const Icon(Icons.edit, size: 20), color: AppConfig.primaryGreen, onPressed: () => onEdit(p)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: AppConfig.errorRed, onPressed: () => onDelete(p)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<Product> products, String baseUrl, BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final imageUrl = p.gambar.isNotEmpty ? (p.isFullUrl ? p.imageUrl : '$baseUrl${p.imageUrl}') : '';
        return Card(
          color: AppConfig.cardWhite, elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(productId: p.id, imageBaseUrl: baseUrl))),
            borderRadius: BorderRadius.circular(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: ProductImage(imageUrl: imageUrl, version: p.versiGambar, size: double.infinity),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nama, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConfig.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: Text(p.hargaFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.darkGreen))),
                    IconButton(icon: const Icon(Icons.edit, size: 18), color: AppConfig.primaryGreen, onPressed: () => onEdit(p)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18), color: AppConfig.errorRed, onPressed: () => onDelete(p)),
                  ]),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}
