import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'api_service.dart';
import 'product_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('products');

  final apiService = ApiService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ProductProvider(api: apiService),
      child: const WarungMamaFahriApp(),
    ),
  );
}
