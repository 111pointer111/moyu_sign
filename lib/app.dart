import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moyu_sign/core/theme.dart';
import 'package:moyu_sign/features/card/domain/card_service.dart';
import 'package:moyu_sign/features/card/presentation/card_screen.dart';
import 'package:moyu_sign/shared/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App 根组件

class MoyuSignApp extends ConsumerWidget {
  const MoyuSignApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '摸鱼签',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final storage = StorageService(snapshot.data!);
          final cardService = CardService(storage);

          return CardScreen(cardService: cardService);
        },
      ),
    );
  }
}