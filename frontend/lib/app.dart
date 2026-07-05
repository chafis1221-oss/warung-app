import 'package:flutter/material.dart';
import 'config.dart';
import 'home_screen.dart';

class WarungMamaFahriApp extends StatelessWidget {
  const WarungMamaFahriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConfig.primaryGreen,
        scaffoldBackgroundColor: AppConfig.backgroundWhite,
        colorScheme: const ColorScheme.light(
          primary: AppConfig.primaryGreen,
          secondary: AppConfig.lightGreen,
          surface: AppConfig.cardWhite,
          error: AppConfig.errorRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConfig.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          color: AppConfig.cardWhite,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppConfig.darkGreen,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
