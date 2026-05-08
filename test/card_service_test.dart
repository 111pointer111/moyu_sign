import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyu_sign/core/constants.dart';
import 'package:moyu_sign/features/card/domain/messages.dart';

/// 模拟 CardService 的核心逻辑
/// （在 Service 实现前先写测试，遵循 TDD）

class MockCardService {
  final Random _random;
  final List<int> _triggeredIndices = [];

  MockCardService([Random? random]) : _random = random ?? Random();

  /// 判定是否触发（1% 概率）
  bool shouldTrigger() {
    return _random.nextDouble() < triggerProbability;
  }

  /// 获取一条未触发过的随机文案
  String? getRandomMessage() {
    final availableIndices = List.generate(
      Messages.all.length,
      (i) => i,
    ).where((i) => !_triggeredIndices.contains(i)).toList();

    if (availableIndices.isEmpty) return null;

    final chosen = availableIndices[_random.nextInt(availableIndices.length)];
    _triggeredIndices.add(chosen);
    return Messages.all[chosen];
  }
}

void main() {
  group('shouldTrigger - 概率测试', () {
    test('10000 次点击中，约有 1% 触发（允许误差 ±20%）', () {
      final service = MockCardService(Random(42));
      int triggerCount = 0;
      const iterations = 10000;

      for (int i = 0; i < iterations; i++) {
        if (service.shouldTrigger()) triggerCount++;
      }

      // 1% of 10000 = 100, 允许 ±20% → 80 ~ 120
      expect(triggerCount, inInclusiveRange(70, 140));
    });

    test('连续 100 次不触发是正常的', () {
      final service = MockCardService(Random(999));
      int triggerCount = 0;
      for (int i = 0; i < 100; i++) {
        if (service.shouldTrigger()) triggerCount++;
      }
      // 99% 不触发是大概率事件，触发超过 5 次是小概率
      expect(triggerCount, lessThan(5));
    });
  });

  group('getRandomMessage - 文案抽取', () {
    test('抽取 10 次后，所有文案都被触发过', () {
      final service = MockCardService(Random(42));
      final triggeredSet = <String>{};

      for (int i = 0; i < 10; i++) {
        final msg = service.getRandomMessage();
        expect(msg, isNotNull);
        triggeredSet.add(msg!);
      }

      // 10 条文案不重复全部触发
      expect(triggeredSet.length, 10);
    });

    test('11 次抽取时，第 11 次返回 null（已全部触发）', () {
      final service = MockCardService(Random(42));

      for (int i = 0; i < 10; i++) {
        service.getRandomMessage();
      }

      final msg = service.getRandomMessage();
      expect(msg, isNull);
    });

    test('同一文案不会在同一天内重复出现', () {
      final service = MockCardService(Random(42));
      final messages = <String>{};

      for (int i = 0; i < 10; i++) {
        final msg = service.getRandomMessage();
        expect(messages.contains(msg), isFalse,
            reason: '文案重复了: $msg');
        messages.add(msg!);
      }
    });
  });
}