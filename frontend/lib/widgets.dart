import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'config.dart';
import 'product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String imageBaseUrl;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageBaseUrl,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConfig.cardWhite,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductImage(
                imageUrl: product.imageUrl.isEmpty
                    ? ''
                    : '$imageBaseUrl${product.imageUrl}',
                version: product.versiGambar,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.kategori,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConfig.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.hargaFormatted,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppConfig.primaryGreen,
                  onPressed: onEdit,
                ),
              const Icon(Icons.chevron_right, color: AppConfig.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final String version;
  final double size;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.version = '',
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppConfig.lightGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.shopping_bag,
          color: AppConfig.primaryGreen,
          size: size * 0.5,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: '$imageUrl?v=$version',
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: AppConfig.lightGreen.withOpacity(0.1),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConfig.primaryGreen,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppConfig.lightGreen.withOpacity(0.2),
          child:
              Icon(Icons.broken_image, color: AppConfig.textLight, size: size * 0.4),
        ),
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  final bool isOnline;
  final bool isLocal;
  final DateTime? lastUpdated;

  const StatusBar({
    super.key,
    required this.isOnline,
    required this.isLocal,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color color;

    if (isOnline) {
      icon = isLocal ? Icons.wifi : Icons.cloud;
      label = isLocal ? 'Lokal' : 'Online';
      color = AppConfig.successGreen;
    } else {
      icon = Icons.cloud_off;
      label = lastUpdated != null ? 'Offline' : 'No data';
      color = AppConfig.errorRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    this.message = 'Tidak ada produk',
    this.icon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppConfig.textLight),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppConfig.textLight),
          ),
        ],
      ),
    );
  }
}
