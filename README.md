# FlowClock

一个基于 Flutter 构建的精美番茄钟应用，集成**生物识别驱动自适应专注**功能，支持 Android、iOS 和 Web 平台。

## ✨ 特性

### 🍅 经典番茄钟
- 三种模式循环：**专注**（默认 25 分钟）、**短休息**（5 分钟）、**长休息**（15 分钟）
- 每完成 4 个番茄自动切换长休息
- 自定义绘制圆形进度环，带渐变色和发光效果
- 播放/暂停、重置、跳过控制
- 计时结束振动反馈

### 🧠 生物识别自适应专注（核心亮点）
- 基于 **HRV（心率变异性）** 模拟检测三种心理状态：
  - **心流（Flow）**：心率适度升高 + HRV 稳定 → 提示延长工作时长
  - **疲劳（Fatigue）**：HRV 显著下降 + 心率异常 → 提示休息
  - **正常（Normal）**：正常工作状态
- **心流延长**：检测到心流状态时，弹窗提示延长 10 分钟专注（每轮最多 2 次）
- **疲劳恢复**：提供两种恢复方式
  - **微休息（Micro-break）**：暂停 2 分钟
  - **呼吸引导（Breathing Guide）**：3 分钟动画引导深呼吸
- **基线校准**：启动时进行 2 分钟基线测定，建立静息心率与 HRV 基准值
- 告警节流：心流提示间隔 ≥ 5 分钟，疲劳提示间隔 ≥ 8 分钟
- 传感器抽象层：当前使用模拟传感器（`MockSensorAdapter`），可扩展接入真实硬件

### 🎵 环境白噪音
- 4 种可循环播放的场景音效：
  - 白噪音
  - 雨声
  - 咖啡馆
  - 森林
- 音量调节滑块（5% ~ 100%）
- 底部弹出选单，当前播放音效一目了然

### 📊 数据统计
- 今日番茄数
- 累计专注时长（分钟/小时）
- 周历视图（周一 ~ 周日），每日番茄数一目了然

### ⚙️ 丰富设置
- 各项时长独立调节（专注/短休息/长休息：1 ~ 60 分钟）
- 生物识别开关 + 重新校准
- 声音/振动开关
- 关于信息

### 🧘 呼吸引导
- 3 分钟腹式深呼吸训练
- 4 秒吸气 + 4 秒呼气循环动画
- 可随时跳过返回工作

### 🎨 UI/UX
- Material 3 设计语言
- 模式专属配色：工作 = 红色渐变，休息 = 绿色渐变
- 底部导航栏（计时 / 统计 / 设置）
- 竖屏锁定
- 中文界面

## 📸 截图

> 请在此处添加应用截图
> 
> | 计时主界面 | 数据统计 | 设置页面 |
> |:---:|:---:|:---:|
> | ![timer](screenshots/timer.png) | ![stats](screenshots/stats.png) | ![settings](screenshots/settings.png) |

## 🚀 快速开始

### 环境要求

- **Flutter SDK** ≥ 3.4.0（Dart SDK ≥ 3.4.0）
- Android Studio / Xcode（用于移动端构建）或 Chrome（用于 Web 端）

### 安装与运行

```bash
# 克隆仓库
git clone https://github.com/your-username/FlowClock.git
cd FlowClock

# 安装依赖
flutter pub get

# 运行（已连接设备 / 模拟器）
flutter run

# 在 Chrome 中运行
flutter run -d chrome

# 运行测试
flutter test
```

### 构建

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

### 生成环境音效（可选）

环境音效文件已包含在 `assets/audio/` 中。如需重新生成：

```bash
python scripts/generate_audio.py
```

> 该脚本仅使用 Python 标准库（`wave`, `random`, `math`），无需额外安装依赖。

## 📁 项目结构

```
lib/
├── main.dart                          # 应用入口
├── app.dart                           # 应用壳（底部导航 + 校准检查）
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # 颜色常量 + Material 3 主题
│   └── utils/
│       └── vibration_util.dart        # 振动反馈工具
├── timer/
│   ├── models/
│   │   └── timer_state.dart           # 计时器状态模型
│   ├── providers/
│   │   ├── timer_provider.dart        # 计时逻辑核心（StateNotifier）
│   │   └── ambient_sound_provider.dart # 环境音效控制
│   ├── pages/
│   │   ├── timer_page.dart            # 计时主界面
│   │   ├── flow_extension_dialog.dart # 心流延长对话框
│   │   ├── fatigue_alert_dialog.dart  # 疲劳提醒对话框
│   │   └── breathing_guide_page.dart  # 呼吸引导页
│   └── widgets/
│       └── circular_progress.dart     # 圆形进度环（CustomPainter）
├── biometrics/
│   ├── models/
│   │   ├── mental_state.dart          # 心理状态枚举
│   │   ├── biometric_baseline.dart    # 基线数据模型
│   │   ├── biometric_snapshot.dart    # 单次读数模型
│   │   └── biometric_alert.dart       # 告警事件模型
│   ├── providers/
│   │   └── biometrics_provider.dart   # 生物识别状态机
│   └── services/
│       ├── biometrics_repository.dart # SharedPreferences 持久化
│       ├── detect_mental_state.dart   # HRV 分析算法
│       ├── sensor_adapter.dart        # 传感器抽象接口
│       └── sensor_adapter_mock.dart   # 模拟传感器实现
├── calibration/
│   └── pages/
│       └── calibration_page.dart      # 基线校准页面
├── stats/
│   ├── models/
│   │   └── pomodoro_record.dart       # 番茄记录模型
│   ├── providers/
│   │   └── stats_provider.dart        # 统计状态管理
│   └── pages/
│       └── stats_page.dart            # 统计页面
└── settings/
    ├── providers/
    │   └── settings_provider.dart     # 设置 + SharedPreferences 同步
    └── pages/
        └── settings_page.dart         # 设置页面
```

## 🛠 技术栈

| 类别 | 技术 |
|---|---|
| 框架 | Flutter / Dart |
| 状态管理 | [Riverpod](https://riverpod.dev)（StateNotifier 模式） |
| 本地持久化 | [SharedPreferences](https://pub.dev/packages/shared_preferences) |
| 音频播放 | [audioplayers](https://pub.dev/packages/audioplayers) |
| 日期格式化 | [intl](https://pub.dev/packages/intl) |
| UI | Material 3 / CustomPainter |

## 🧪 测试

```bash
flutter test
```

测试覆盖：
- `detect_mental_state_test.dart` — 5 个单元测试覆盖心理状态检测算法的正常、心流、疲劳、HRV 异常等场景
- `widget_test.dart` — 基础冒烟测试

## 📄 许可证

MIT License

---

**Made with Flutter & ❤️**
