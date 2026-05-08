import 'package:flutter/material.dart';

/// 摸鱼签主题配置
/// 风格：佛系搞笑 + 木鱼功德 + 抽象幽默

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F0E8), // 米白色背景
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF9F43), // 明亮橙黄色
        brightness: Brightness.light,
        surface: const Color(0xFFF5F0E8),
      ),
      textTheme: const TextTheme(
        // 计数器大字
        displayLarge: TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D3436),
          letterSpacing: -2,
        ),
        // 文案展示
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3436),
          height: 1.5,
        ),
        // 副标题
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF636E72),
        ),
        // 标签
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB2BEC3),
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// 卡片背景色
  static const cardColor = Color(0xFFFFFFFF);

  /// 卡片阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// 功德金色
  static const meritGold = Color(0xFFFFD700);

  /// 木鱼棕色
  static const woodBrown = Color(0xFF8B6914);

  /// 禅意绿色
  static const zenGreen = Color(0xFF4CAF50);

  /// 摸鱼橙色
  static const moyuOrange = Color(0xFFFF6B35);
}
