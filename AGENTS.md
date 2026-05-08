# moyu_sign

Flutter 单应用项目。「摸鱼签」— 社交冷场时的轻量卡片计数器，1% 概率触发翻转显示随机文案。

## Commands

```bash
flutter test                    # 全量测试
flutter test test/card_service_test.dart  # 单文件测试
flutter analyze                 # 静态分析（lint）
flutter run                     # 启动开发（需连接设备或模拟器）
flutter pub get                 # 安装依赖
```

## Architecture

```
lib/
  main.dart           — 入口，ProviderScope 包裹根组件
  app.dart            — MaterialApp + SharedPreferences 初始化
  core/
    constants.dart    — 概率、动画时长、存储 key 等常量
    theme.dart        — Material 3 主题配置（米白背景 + 橙黄种子色）
  features/card/
    domain/
      card_service.dart  — 核心逻辑：点击处理、概率判定、文案抽取
      messages.dart      — 10 条预设文案（6 职场 + 4 生活）
    presentation/
      card_screen.dart   — 主页面，状态管理用 ConsumerStatefulWidget
      widgets/
        flip_card.dart       — 3D 翻转动画组件
        counter_display.dart — 计数器数字展示（自适应字号）
        message_card.dart    — 翻转背面文案卡片
  shared/
    storage.dart      — SharedPreferences 封装（计数 + 已触发索引）
```

## Key Details

- **状态管理**: flutter_riverpod，但当前未使用 Provider 持久化状态，而是在 `app.dart` 中手动创建 `StorageService` 和 `CardService` 实例传入
- **存储**: shared_preferences，key 定义在 `core/constants.dart`（`today_count`、`triggered_indices`）
- **概率逻辑**: `CardService.onTap()` 返回 bool，`true` 表示触发翻转（1% 概率）；`getRandomMessage()` 保证同一天不重复抽取
- **文案约束**: `Messages.all` 和 `Messages.tags` 长度必须一致（当前均为 10），修改文案时同步更新两个列表
- **Linter 配置**: `analysis_options.yaml` 引用 `package:flutter_lints/flutter.yaml`，无自定义规则覆盖

## Testing

- `test/card_service_test.dart` 使用 **MockCardService**（手写模拟类）而非测试真实 `CardService`，修改核心逻辑时需同步更新 Mock
- `test/widget_test.dart` 是占位测试，不涉及真实 Widget 渲染
- `test/messages_test.dart` 验证文案数量和分类约束

## Gotchas

- `app.dart:20-31` 中 `SharedPreferences.getInstance()` 是异步操作，用 `FutureBuilder` 包裹，修改初始化流程时注意 loading 状态处理
- `StorageService.setTodayCount()` 是 async 但 `CardService.onTap()` 未 await，这是设计选择（fire-and-forget），改动前需评估一致性影响
