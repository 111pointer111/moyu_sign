/// 摸鱼签核心常量

/// 触发翻转的概率（1%）
const double triggerProbability = 0.01;

/// 翻转动画时长（毫秒）
const int flipDurationMs = 600;

/// 计数器显示的最小字体大小
const double counterMinFontSize = 64.0;

/// 计数器显示的最大字体大小
const double counterMaxFontSize = 96.0;

/// 存储 key：今日点击次数
const String keyTodayCount = 'today_count';

/// 存储 key：今日已触发的文案索引列表
const String keyTriggeredIndices = 'triggered_indices';

/// 存储 key：声音开关状态
const String keySoundEnabled = 'sound_enabled';

/// 音效文件路径（AssetSource 会自动添加 assets/ 前缀）
const String soundWoodenFishTap = 'sounds/wooden_fish_tap.mp3';