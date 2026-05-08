import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moyu_sign/core/constants.dart';
import 'package:moyu_sign/core/theme.dart';
import 'package:moyu_sign/features/card/domain/card_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 摸鱼签主页
/// 逻辑：点击木鱼 → 功德+1 → 1% 概率木鱼翻转显示 "giao!" + 祝福语

class CardScreen extends ConsumerStatefulWidget {
  final CardService cardService;

  const CardScreen({super.key, required this.cardService});

  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isTriggered = false; // 是否触发奖励
  String? _currentMessage; // 当前祝福语
  bool _isAnimating = false;
  bool _isCooldown = false;
  Timer? _cooldownTimer;
  Timer? _refreshTimer; // 定期刷新计数的 Timer
  int _count = 0; // 本地缓存计数

  // 木鱼点击动画（缩放）
  late AnimationController _fishTapController;
  late Animation<double> _fishScaleAnimation;

  // 木鱼翻转动画（触发奖励时）
  late AnimationController _fishFlipController;
  late Animation<double> _fishFlipAnimation;

  // 功德+1 弹出动画
  late AnimationController _meritController;
  late Animation<double> _meritOpacityAnimation;
  late Animation<Offset> _meritSlideAnimation;

  // "giao!" 弹出动画
  late AnimationController _giaoController;
  late Animation<double> _giaoScaleAnimation;
  late Animation<double> _giaoOpacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _count = widget.cardService.getTodayCount();

    // 每秒检查一次计数变化（用于组件点击后同步）
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshCount();
    });

    // 木鱼点击动画（缩放）
    _fishTapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fishScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _fishTapController, curve: Curves.easeInOut),
    );

    // 木鱼翻转动画（触发奖励时）
    _fishFlipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fishFlipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fishFlipController, curve: Curves.easeOutBack),
    );

    // 功德+1 弹出动画
    _meritController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _meritOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _meritController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _meritSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _meritController, curve: Curves.easeOut),
    );

    // "giao!" 弹出动画
    _giaoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _giaoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _giaoController, curve: Curves.elasticOut),
    );
    _giaoOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _giaoController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _cooldownTimer?.cancel();
    _fishTapController.dispose();
    _fishFlipController.dispose();
    _meritController.dispose();
    _giaoController.dispose();
    super.dispose();
  }

  /// 定期刷新计数（用于组件点击后同步）
  void _refreshCount() {
    SharedPreferences.getInstance().then((prefs) {
      // Flutter 的 shared_preferences 插件会自动添加 "flutter." 前缀
      // 所以这里直接用 keyTodayCount 即可
      final newCount = prefs.getInt(keyTodayCount) ?? 0;
      if (newCount != _count) {
        setState(() {
          _count = newCount;
        });
      }
    });
  }

  void _onTap() {
    if (_isAnimating || _isCooldown || _isTriggered) return;

    // 木鱼点击动画
    _fishTapController.forward().then((_) {
      _fishTapController.reverse();
    });

    // 显示功德+1
    _meritController.reset();
    _meritController.forward();

    final triggered = widget.cardService.onTap();

    // 无论是否触发奖励，都更新 UI 显示新计数
    setState(() {
      _count = widget.cardService.getTodayCount();
      if (triggered) {
        String? message = widget.cardService.getRandomMessage();
        // 如果所有文案都已触发，重置后重新获取
        if (message == null) {
          widget.cardService.resetTriggeredIndices();
          message = widget.cardService.getRandomMessage();
        }
        if (message != null) {
          _currentMessage = message;
          _isTriggered = true;
          _isAnimating = true;
        }
      }
    });

    // 触发奖励的额外处理
    if (triggered && _isTriggered) {
      // 木鱼翻转动画
      _fishFlipController.forward().then((_) {
        setState(() => _isAnimating = false);
      });

      // 显示 "giao!"
      _giaoController.reset();
      _giaoController.forward();

      // 启动冷却
      _startCooldown();
    }
  }

  void _startCooldown() {
    setState(() => _isCooldown = true);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        // 自动恢复
        _fishFlipController.reverse().then((_) {
          setState(() {
            _isTriggered = false;
            _isCooldown = false;
            _currentMessage = null;
          });
        });
      }
    });
  }

  void _onCardTap() {
    if (_isTriggered && !_isCooldown) {
      // 手动恢复
      _fishFlipController.reverse().then((_) {
        setState(() {
          _isTriggered = false;
          _currentMessage = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _isTriggered ? _onCardTap : _onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F0E8),
                Color(0xFFEDE7D9),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 顶部标题
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Text(
                        '摸鱼签',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.woodBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '敲木鱼，积功德，摸鱼也要有仪式感',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.woodBrown.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 木鱼区域（带动画）
                AnimatedBuilder(
                  animation: _fishFlipAnimation,
                  builder: (context, child) {
                    final angle = _fishFlipAnimation.value * pi;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);

                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 木鱼图片
                      AnimatedBuilder(
                        animation: _fishScaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _fishScaleAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _isTriggered
                                    ? AppTheme.meritGold.withOpacity(0.5)
                                    : AppTheme.moyuOrange.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/wooden_fish_001.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // 功德+1 弹出动画
                      AnimatedBuilder(
                        animation: _meritController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _meritSlideAnimation,
                            child: FadeTransition(
                              opacity: _meritOpacityAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.meritGold,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.meritGold.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            '功德+1',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // "giao!" 弹出动画
                AnimatedBuilder(
                  animation: _giaoController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _giaoScaleAnimation,
                      child: FadeTransition(
                        opacity: _giaoOpacityAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'giao!',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.meritGold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 祝福语区域
                if (_isTriggered && _currentMessage != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.meritGold.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '✨ 功德无量 ✨',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.meritGold,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppTheme.woodBrown,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      // 功德计数
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '今日功德',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.woodBrown,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_count',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.moyuOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 点击提示
                      if (_isCooldown)
                        Text(
                          '休息一下，5秒后可继续敲木鱼',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.moyuOrange,
                                  ),
                        )
                      else
                        Text(
                          '点击木鱼敲一下',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.woodBrown.withOpacity(0.6),
                                  ),
                        ),
                    ],
                  ),

                const Spacer(),

                // 底部装饰
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/lazy_cat_001.jpg',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '躺平也是一种修行',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.woodBrown.withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
