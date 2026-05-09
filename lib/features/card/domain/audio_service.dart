import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:moyu_sign/core/constants.dart';
import 'package:moyu_sign/shared/storage.dart';

/// 音频服务类
/// 管理音效播放和声音开关状态

class AudioService {
  final StorageService _storageService;
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioService(this._storageService);

  /// 获取声音开关状态
  bool get isSoundEnabled => _storageService.isSoundEnabled();

  /// 切换声音开关状态
  Future<void> toggleSound() async {
    final newState = !_storageService.isSoundEnabled();
    await _storageService.setSoundEnabled(newState);
  }

  /// 播放木鱼敲击音效
  Future<void> playWoodenFishTap() async {
    if (!isSoundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource(soundWoodenFishTap));
    } catch (e) {
      // 音效播放失败不影响主应用
      debugPrint('Failed to play sound: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}
