# 摸鱼签 - 开发日志

## 日期：2026年5月8日

---

## 一、Gradle 构建失败（初始问题）

### 问题描述
```
Error resolving plugin [id: 'dev.flutter.flutter-plugin-loader', version: '1.0.0']
> Could not read workspace metadata from ~/.gradle/caches/8.7/kotlin-dsl/accessors/.../metadata.bin
```

### 根本原因
1. **系统代理导致网络不通** - 系统启用了 HTTP/HTTPS/SOCKS 代理，但代理服务未运行
2. **Gradle Kotlin DSL 缓存损坏** - `~/.gradle/caches/8.7/kotlin-dsl/` 下的 metadata.bin 文件损坏
3. **JDK 21 与 AGP 8.0.2 不兼容** - Android Studio 自带 JDK 21，但 AGP 8.0.2 的 JdkImageTransform 调用 jlink 失败

### 解决方案

| 步骤 | 操作 | 作用 |
|------|------|------|
| 1 | `gradle.properties` 中禁用所有代理 | 解决 SOCKS/HTTP 代理连接问题 |
| 2 | `settings.gradle` 添加阿里云镜像源 | 解决 Maven Central TLS 握手失败 |
| 3 | 手动下载 Gradle 8.7 到 `~/.gradle/wrapper/dists/` | 解决 Gradle Wrapper 下载超时 |
| 4 | `brew install openjdk@17` + 配置 `org.gradle.java.home` | 解决 JDK 21 与 AGP 8.2 不兼容 |
| 5 | `sdkmanager "build-tools;34.0.0"` | 安装缺失的 Build Tools |

### 关键配置文件修改

**gradle.properties**：
```properties
org.gradle.java.home=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
systemProp.http.proxyHost=
systemProp.http.proxyPort=
systemProp.https.proxyHost=
systemProp.https.proxyPort=
systemProp.socksProxyHost=
systemProp.socksProxyPort=
```

**settings.gradle**：
```groovy
repositories {
    maven { url 'https://maven.aliyun.com/repository/google' }
    maven { url 'https://maven.aliyun.com/repository/public' }
    maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
    maven { url 'https://maven.aliyun.com/repository/central' }
    google()
    mavenCentral()
    gradlePluginPortal()
}
```

---

## 二、计数器点击不累加

### 问题描述
点击木鱼后，计数器数字不更新。

### 根本原因
`_onTap()` 方法中，只有触发奖励时才调用 `setState()` 更新 UI，但 99% 的点击不会触发奖励，导致 UI 不刷新。

### 解决方案
将 `setState()` 移到条件判断外面，确保每次点击都更新 UI。

```dart
// 修复前
if (triggered) {
    setState(() { ... });  // 只有触发奖励时才更新 UI
}

// 修复后
setState(() {  // 每次点击都更新 UI
    if (triggered) { ... }
});
```

---

## 三、桌面小组件（App Widget）

### 实现方案
使用 `home_widget` 插件 + 自定义 Android Widget Provider。

### 创建的文件

| 文件 | 作用 |
|------|------|
| `res/layout/widget_small.xml` | 小组件布局 (2×1) |
| `res/layout/widget_medium.xml` | 中组件布局 (2×2) |
| `res/layout/widget_large.xml` | 大组件布局 (4×2) |
| `res/xml/widget_small_info.xml` | 小组件配置 |
| `res/xml/widget_medium_info.xml` | 中组件配置 |
| `res/xml/widget_large_info.xml` | 大组件配置 |
| `BaseWidgetProvider.kt` | Widget 基类（共享逻辑） |
| `MoyuSmallWidgetProvider.kt` | 小组件 Provider |
| `MoyuMediumWidgetProvider.kt` | 中组件 Provider |
| `MoyuLargeWidgetProvider.kt` | 大组件 Provider |

### 遇到的问题

#### 3.1 ClassCastException: Long cannot be cast to Integer
**原因**：Widget 端用 `putLong` 写入，Flutter 端用 `getInt` 读取，类型不匹配。

**解决**：Widget 端改用 `putInt`/`getInt`，并添加兼容旧数据的 try-catch。

```kotlin
fun getCount(context: Context): Int {
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
    return try {
        flutterPrefs.getInt("flutter.$KEY_COUNT", 0)
    } catch (e: ClassCastException) {
        // 兼容旧数据：旧版用 Long 存储，迁移到 Int
        val longValue = flutterPrefs.getLong("flutter.$KEY_COUNT", 0L).toInt()
        flutterPrefs.edit()
            .remove("flutter.$KEY_COUNT")
            .putInt("flutter.$KEY_COUNT", longValue)
            .apply()
        longValue
    }
}
```

#### 3.2 Widget 和 App 数据不同步
**原因**：Widget 修改 SharedPreferences 后，App 的实例不会自动刷新。

**解决**：添加 Timer 每秒检查计数变化。

```dart
// 每秒检查一次计数变化
_refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    _refreshCount();
});

void _refreshCount() {
    SharedPreferences.getInstance().then((prefs) {
        final newCount = prefs.getInt(keyTodayCount) ?? 0;
        if (newCount != _count) {
            setState(() { _count = newCount; });
        }
    });
}
```

#### 3.3 SharedPreferences key 前缀问题
**关键知识点**：Flutter 的 `shared_preferences` 插件在 Android 端会自动添加 `flutter.` 前缀。

- Flutter 调用 `prefs.setInt('today_count', 5)` → 实际存储为 `flutter.today_count`
- Widget 调用 `prefs.putInt("flutter.today_count", 5)` → 存储为 `flutter.today_count`

---

## 四、翻牌卡住 Bug

### 问题描述
触发奖励后，卡片翻过去就一直卡住，无法恢复。

### 根本原因
`_onCardTap()` 方法中，翻回卡片后设置 `_isAnimating = true`，但没有回调来重置为 false。

### 解决方案
添加定时器，在动画完成后重置状态。

```dart
void _onCardTap() {
    if (_isFlipped && !_isCooldown) {
        setState(() {
            _isFlipped = false;
            _isAnimating = true;
        });
        // 动画完成后重置状态
        Future.delayed(Duration(milliseconds: flipDurationMs), () {
            if (mounted) {
                setState(() => _isAnimating = false);
            }
        });
    }
}
```

---

## 五、触发奖励无反应

### 问题描述
触发奖励时没有翻转动画和祝福语显示。

### 根本原因
当所有 10 条文案都已触发过时，`getRandomMessage()` 返回 `null`，导致 `_isTriggered` 不会被设置为 true。

### 解决方案
当所有文案都已触发时，自动重置文案索引。

```dart
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
```

---

## 六、UI/动画优化

### 6.1 木鱼翻转动画
触发奖励时，木鱼图标进行 3D Y 轴翻转，使用 `easeOutBack` 曲线带回弹效果。

### 6.2 "giao!" 弹出动画
翻转后显示 "giao!" 文字，使用弹性缩放动画 (`elasticOut`)。

### 6.3 祝福语卡片
显示金色卡片，包含 "功德无量" 标题和随机祝福语。

### 6.4 5 秒冷却期
触发奖励后 5 秒内禁止点击，防止用户错过祝福语。

---

## 七、App 图标和名称

### 使用 minimax 生成图标
```bash
mmx image generate --prompt "A cute cartoon wooden fish..." --aspect-ratio 1:1 --out-dir assets/icons --out-prefix app_icon
```

### 配置 flutter_launcher_icons
```yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/icons/app_icon_001.jpg"
  adaptive_icon_background: "#F5F0E8"
  adaptive_icon_foreground: "assets/icons/app_icon_001.jpg"
```

### 修改 App 名称
**AndroidManifest.xml**：`android:label="摸鱼签"`

---

## 八、项目依赖

```yaml
dependencies:
  flutter_riverpod: ^2.5.1      # 状态管理
  shared_preferences: ^2.2.3    # 本地存储
  home_widget: ^0.6.0           # 桌面小组件

dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # 图标生成
```

---

## 九、关键配置总结

| 配置项 | 值 | 说明 |
|--------|-----|------|
| AGP 版本 | 8.2.0 | 兼容 Flutter 3.24.5 |
| Kotlin 版本 | 1.8.22 | - |
| Gradle 版本 | 8.7 | 手动下载 |
| JDK 版本 | OpenJDK 17 | 通过 Homebrew 安装 |
| compileSdk | 35 | home_widget 要求 |
| buildToolsVersion | 33.0.1 | - |
| ndkVersion | 25.1.8937393 | shared_preferences_android 要求 |

---

## 十、打包

```bash
flutter build apk --release
```

**输出路径**：`build/app/outputs/flutter-apk/app-release.apk`（约 20.8MB）
