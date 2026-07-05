import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'product_provider.dart';
import 'widgets.dart';
import 'detail_screen.dart';
import 'admin_screen.dart';
import 'kalkulator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  DateTime? _lastBackPress;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.backgroundWhite,
        appBar: AppBar(
          title: const Text(AppConfig.appName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          backgroundColor: AppConfig.primaryGreen,
          elevation: 0,
          actions: [
            // Sort
            PopupMenuButton<SortMode>(
              icon: const Icon(Icons.sort, color: Colors.white),
              onSelected: (mode) => context.read<ProductProvider>().setSortMode(mode),
              itemBuilder: (_) => [
                const PopupMenuItem(value: SortMode.nameAsc, child: Text('🔤 A → Z')),
                const PopupMenuItem(value: SortMode.nameDesc, child: Text('🔤 Z → A')),
                const PopupMenuItem(value: SortMode.priceLow, child: Text('💰 Murah → Mahal')),
                const PopupMenuItem(value: SortMode.priceHigh, child: Text('💰💰 Mahal → Murah')),
              ],
            ),
            // Toggle
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            // Kalkulator
            IconButton(
              icon: const Icon(Icons.calculate, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KalkulatorScreen())),
            ),
            // Status — Selector biar gak rebuild semua
            Selector<ProductProvider, ConnectionStatus>(
              selector: (_, p) => p.status,
              builder: (_, status, __) {
                final p = context.read<ProductProvider>();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: StatusBar(
                    isOnline: status == ConnectionStatus.online,
                    isLocal: p.isLocal,
                    lastUpdated: p.lastUpdated,
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search
            Container(
              color: AppConfig.primaryGreen,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => context.read<ProductProvider>().setSearch(q),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '🔍  Cari produk...',
                  hintStyle: const TextStyle(color: AppConfig.textLight),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); context.read<ProductProvider>().setSearch(''); })
                      : null,
                ),
              ),
            ),
            // Kategori — Selector
            Selector<ProductProvider, List<String>>(
              selector: (_, p) => p.allCategories,
              builder: (_, categories, __) {
                final p = context.read<ProductProvider>();
                return Container(
                  color: AppConfig.primaryGreen,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip('Semua', '', p),
                        ...categories.map((cat) => _buildChip(cat, cat, p)),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Product list — Selector
            Expanded(
              child: Selector<ProductProvider, List<Product>>(
                selector: (_, p) => p.products,
                builder: (_, products, __) {
                  if (products.isEmpty) return const EmptyState();
                  return RefreshIndicator(
                    color: AppConfig.primaryGreen,
                    onRefresh: () => context.read<ProductProvider>().loadProducts(),
                    child: _isGridView ? _buildGrid(products) : _buildList(products),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppConfig.darkGreen,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
        ),
      ),
    );
  }

  // List
  Widget _buildList(List<Product> products) {
    final baseUrl = context.read<ProductProvider>().api.baseUrl;
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
              child: Row(
                children: [
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
                  IconButton(icon: const Icon(Icons.edit, size: 20), color: AppConfig.primaryGreen,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(editProduct: p)))),
                  const Icon(Icons.chevron_right, color: AppConfig.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Grid
  Widget _buildGrid(List<Product> products) {
    final baseUrl = context.read<ProductProvider>().api.baseUrl;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    Text(p.hargaFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.darkGreen)),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String value, ProductProvider provider) {
    final isSelected = provider.selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppConfig.textDark, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        selected: isSelected,
        onSelected: (_) => provider.setCategory(value),
        backgroundColor: Colors.white, selectedColor: AppConfig.darkGreen, checkmarkColor: Colors.white,
        side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
