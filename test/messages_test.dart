import 'package:flutter_test/flutter_test.dart';
import 'package:moyu_sign/features/card/domain/messages.dart';

void main() {
  group('Messages', () {
    test('all 包含 10 条文案', () {
      expect(Messages.all.length, 10);
    });

    test('tags 和 all 数量一致', () {
      expect(Messages.tags.length, Messages.all.length);
    });

    test('文案内不含空字符串', () {
      for (final msg in Messages.all) {
        expect(msg.trim(), isNotEmpty);
      }
    });

    test('职场类文案 6 条', () {
      final workCount =
          Messages.tags.where((t) => t == '摸鱼提示').length;
      expect(workCount, 6);
    });

    test('生活类文案 4 条', () {
      final lifeCount =
          Messages.tags.where((t) => t == '生活感悟').length;
      expect(lifeCount, 4);
    });
  });
}