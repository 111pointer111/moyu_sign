import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moyu_sign/core/constants.dart';

/// 翻转卡片动画组件
/// 正面：显示数字
/// 背面：显示文案
/// 优化：带回弹效果的 3D 翻转 + 轻微缩放

class FlipCard extends StatefulWidget {
  /// 是否正在显示背面（文案）
  final bool isFlipped;

  /// 正面内容（数字）
  final Widget front;

  /// 背面内容（文案）
  final Widget back;

  /// 动画完成回调
  final VoidCallback? onFlipComplete;

  const FlipCard({
    super.key,
    required this.isFlipped,
    required this.front,
    required this.back,
    this.onFlipComplete,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: flipDurationMs),
      vsync: this,
    );

    // 翻转动画：使用 easeOutBack 曲线带回弹效果
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // 缩放动画：翻转时轻微缩小，完成后恢复
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipComplete?.call();
      }
    });

    _animation.addListener(() {
      // 当动画过半时切换正面/背面
      if (_animation.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_animation.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped && !oldWidget.isFlipped) {
      // 开始翻转
      _showFront = true;
      _controller.forward(from: 0);
    } else if (!widget.isFlipped && oldWidget.isFlipped) {
      // 复原
      _showFront = true;
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final scale = _scaleAnimation.value;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateY(angle)
          ..scale(scale, scale);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: _showFront
              ? widget.front
              : Transform(
                  transform: Matrix4.identity()
                    ..rotateY(pi)
                    ..scale(scale, scale),
                  alignment: Alignment.center,
                  child: widget.back,
                ),
        );
      },
    );
  }
}
