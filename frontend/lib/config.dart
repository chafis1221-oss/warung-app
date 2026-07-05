import 'package:flutter/material.dart';

class AppConfig {
  // API
  static const String localBaseUrl = 'http://192.168.1.17:8088';
  static const String tunnelBaseUrl = 'https://backend.chafis.my.id';
  static const Duration connectTimeout = Duration(seconds: 2);
  static const int rateLimitPerMinute = 60;

  // App
  static const String appName = 'Warung Mama Fahri';
  static const String version = '1.0.0';

  // Theme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF757575);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF66BB6A);
}
