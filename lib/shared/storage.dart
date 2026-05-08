import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import '../core/constants.dart';

/// 本地存储封装（SharedPreferences）

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// 获取今日点击次数
  int getTodayCount() {
    return _prefs.getInt(keyTodayCount) ?? 0;
  }

  /// 保存今日点击次数
  Future<void> setTodayCount(int count) async {
    await _prefs.setInt(keyTodayCount, count);
    // 同步更新 Home Widget
    await _updateHomeWidget(count);
  }

  /// 更新 Home Widget 数据
  Future<void> _updateHomeWidget(int count) async {
    try {
      await HomeWidget.saveWidgetData<int>('today_count', count);
      // 更新所有类型的 Widget
      await HomeWidget.updateWidget(
        name: 'MoyuSmallWidgetProvider',
        iOSName: 'MoyuWidget',
      );
      await HomeWidget.updateWidget(
        name: 'MoyuMediumWidgetProvider',
        iOSName: 'MoyuWidget',
      );
      await HomeWidget.updateWidget(
        name: 'MoyuLargeWidgetProvider',
        iOSName: 'MoyuWidget',
      );
    } catch (e) {
      // Widget 更新失败不影响主应用
      debugPrint('Failed to update home widget: $e');
    }
  }

  /// 获取今日已触发的文案索引集合
  Set<int> getTriggeredIndices() {
    final list = _prefs.getStringList(keyTriggeredIndices) ?? [];
    return list.map((e) => int.parse(e)).toSet();
  }

  /// 添加已触发的文案索引
  Future<void> addTriggeredIndex(int index) async {
    final indices = getTriggeredIndices();
    indices.add(index);
    await _prefs.setStringList(
      keyTriggeredIndices,
      indices.map((e) => e.toString()).toList(),
    );
  }

  /// 重置已触发的文案索引（当所有文案都显示过后调用）
  Future<void> resetTriggeredIndices() async {
    await _prefs.setStringList(keyTriggeredIndices, []);
  }

  /// 重置今日数据（App 卸载后自动生效，因为数据跟着 SharedPreferences）
  /// 无需显式调用，SharedPreferences 本身就是持久化本地存储
}
