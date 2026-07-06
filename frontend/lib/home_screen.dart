import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'product_provider.dart';
import 'widgets.dart';
import 'home_list.dart';
import 'detail_screen.dart';
import 'admin_form.dart';
import 'admin_edit.dart';
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

  void _onEdit(product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminEdit(product: product, fromHome: true)),
    );
    if (mounted) context.read<ProductProvider>().loadProducts();
  }

  void _onDelete(product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin hapus "${product.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppConfig.errorRed), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await context.read<ProductProvider>().deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${product.nama}" dihapus'), backgroundColor: AppConfig.successGreen));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppConfig.errorRed));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tekan sekali lagi untuk keluar'), duration: Duration(seconds: 2)));
          return;
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.backgroundWhite,
        appBar: AppBar(
          title: const Text(AppConfig.appName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          backgroundColor: AppConfig.primaryGreen,
          elevation: 0,
          actions: [
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
            IconButton(icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white), onPressed: () => setState(() => _isGridView = !_isGridView)),
            IconButton(icon: const Icon(Icons.calculate, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KalkulatorScreen()))),
            Selector<ProductProvider, ConnectionStatus>(
              selector: (_, p) => p.status,
              builder: (_, status, __) {
                final p = context.read<ProductProvider>();
                return Padding(padding: const EdgeInsets.only(right: 8), child: StatusBar(isOnline: status == ConnectionStatus.online, isLocal: p.isLocal, lastUpdated: p.lastUpdated));
              },
            ),
          ],
        ),
        body: Column(children: [
          Container(
            color: AppConfig.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => context.read<ProductProvider>().setSearch(q),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '🔍  Cari produk...', hintStyle: const TextStyle(color: AppConfig.textLight),
                filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); context.read<ProductProvider>().setSearch(''); })
                    : null,
              ),
            ),
          ),
          Consumer<ProductProvider>(
            builder: (_, provider, __) {
              final categories = provider.allCategories;
              return Container(
                color: AppConfig.primaryGreen,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _buildChip('Semua', '', provider),
                    ...categories.map((cat) => _buildChip(cat, cat, provider)),
                  ]),
                ),
              );
            },
          ),
          Expanded(
            child: HomeList(
              isGridView: _isGridView,
              onEdit: _onEdit,
              onDelete: _onDelete,
            ),
          ),
        ]),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppConfig.darkGreen,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminForm(fromHome: true)));
            if (mounted) context.read<ProductProvider>().loadProducts();
          },
        ),
      ),
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
