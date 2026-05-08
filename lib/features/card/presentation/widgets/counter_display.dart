import 'package:flutter/material.dart';

/// 计数器展示组件
/// 显示当前点击次数，大字居中

class CounterDisplay extends StatelessWidget {
  final int count;

  const CounterDisplay({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text(
      count.toString(),
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: _responsiveSize(count),
          ),
    );
  }

  double _responsiveSize(int count) {
    // 数字越大，字体略微缩小，避免溢出
    final digits = count.toString().length;
    if (digits <= 4) return 80;
    if (digits <= 5) return 64;
    return 48;
  }
}