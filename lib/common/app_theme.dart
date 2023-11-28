import 'package:flutter/material.dart';

class AppThemes {
  // Material3主题配置
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    ),
  );

  // 暗黑模式下的主题配置
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 24, fontStyle: FontStyle.normal),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    ),
  );
}
