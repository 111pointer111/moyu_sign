import 'dart:math';
import 'package:moyu_sign/core/constants.dart';
import 'package:moyu_sign/features/card/domain/messages.dart';
import 'package:moyu_sign/shared/storage.dart';

/// 摸鱼签核心服务
/// 职责：点击处理、概率判定、文案抽取、计数持久化

class CardService {
  final StorageService _storage;
  final Random _random;

  CardService(this._storage, {Random? random}) : _random = random ?? Random();

  /// 获取今日点击次数
  int getTodayCount() => _storage.getTodayCount();

  /// 处理一次点击
  /// 返回 true 表示触发了翻转（显示文案）
  /// 返回 false 表示普通计数
  bool onTap() {
    final count = _storage.getTodayCount() + 1;
    _storage.setTodayCount(count);

    // 概率判定
    if (_random.nextDouble() < triggerProbability) {
      return true; // 触发翻转
    }
    return false;
  }

  /// 获取一条随机文案（不重复）
  /// 若所有文案都已触发，返回 null
  String? getRandomMessage() {
    final triggered = _storage.getTriggeredIndices();
    final available = List.generate(
      Messages.all.length,
      (i) => i,
    ).where((i) => !triggered.contains(i)).toList();

    if (available.isEmpty) return null;

    final chosen = available[_random.nextInt(available.length)];
    _storage.addTriggeredIndex(chosen);
    return Messages.all[chosen];
  }

  /// 重置已触发的文案索引（当所有文案都显示过后调用）
  void resetTriggeredIndices() {
    _storage.resetTriggeredIndices();
  }
}