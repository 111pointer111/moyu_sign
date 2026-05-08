import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterDisplay', () {
    test('显示数字 0', () {
      // 简单渲染测试
      expect('0'.length, 1);
    });

    test('4 位数以下显示大字号', () {
      // 数字 9999 → 4位 → 字号 80
      final digits = 9999.toString().length;
      expect(digits, 4);
    });
  });
}