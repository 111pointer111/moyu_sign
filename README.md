# 摸鱼签

社交冷场时的轻量卡片计数器，1% 概率触发翻转显示随机文案。

敲木鱼，积功德，摸鱼也要有仪式感。

## 功能

- 点击木鱼累加功德计数
- 1% 概率触发奖励：木鱼翻转 + "giao!" + 随机祝福语
- 触发奖励后 5 秒冷却期，防止错过祝福语
- 桌面小组件（3 种尺寸：小/中/大），点击可直接累加
- App 与小组件数据实时同步
- 10 条搞笑文案，循环显示

## 截图

| 主界面 | 触发奖励 | 桌面小组件 |
|--------|---------|-----------|
| ![主界面](screenshots/main.png) | ![奖励](screenshots/reward.png) | ![小组件](screenshots/widget.png) |

## 技术栈

- **框架**：Flutter 3.24.5
- **状态管理**：flutter_riverpod
- **本地存储**：shared_preferences
- **桌面小组件**：home_widget
- **图标生成**：minimax CLI + flutter_launcher_icons

## 项目结构

```
lib/
├── main.dart                    # 入口
├── app.dart                     # MaterialApp + 初始化
├── core/
│   ├── constants.dart           # 常量（概率、动画时长、存储 key）
│   └── theme.dart               # 主题配置
├── features/card/
│   ├── domain/
│   │   ├── card_service.dart    # 核心逻辑（点击、概率、文案抽取）
│   │   └── messages.dart        # 10 条预设文案
│   └── presentation/
│       ├── card_screen.dart     # 主页面
│       └── widgets/
│           ├── flip_card.dart   # 3D 翻转动画组件
│           ├── counter_display.dart
│           └── message_card.dart
└── shared/
    └── storage.dart             # SharedPreferences 封装
```

## 运行

```bash
# 安装依赖
flutter pub get

# 运行（debug）
flutter run

# 打包
flutter build apk --release
```

输出路径：`build/app/outputs/flutter-apk/app-release.apk`

## 桌面小组件

长按桌面 → 小部件 → 摸鱼签 → 选择尺寸（小/中/大）

- **小组件** (2×1)：显示计数
- **中组件** (2×2)：计数 + 敲一下
- **大组件** (4×2)：计数 + 敲一下按钮

## 开发日志

详见 [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md)

## License

MIT
