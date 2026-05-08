import 'package:flutter/material.dart';
import 'package:moyu_sign/core/theme.dart';

/// 文案展示卡片组件
/// 翻转后的背面，显示祝福/调侃文案

class MessageCard extends StatelessWidget {
  final String message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '👆 继续摸',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}