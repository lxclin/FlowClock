# FlowClock — HRV 自适应番茄计时器

基于心率变异性（HRV）实时感知专注状态的智能番茄工作法计时器。
在最佳时刻延长计时，在疲惫时提醒休息。

## 技术栈

| 层级 | 技术 |
|------|------|
| 语言 | Dart 3.x |
| 框架 | Flutter 3.41 |
| UI | Material 3 (Material You) |
| 状态管理 | Riverpod 2.5 |
| 持久化 | SharedPreferences |
| 音频 | audioplayers 6.x |
| 生物传感 | health 插件 → Apple HealthKit / Google Health Connect |
| 图形 | CustomPainter + SweepGradient |

## 功能

### 番茄计时
- 专注 25 分 / 短休息 5 分 / 长休息 15 分，一键切换，时长可自定义
- 环形渐变进度条，颜色随模式变化（专注=红、休息=绿）
- 播放/暂停/重置/跳过，计时结束自动切换 + 震动提醒

### HRV 自适应
- 连接 Apple Watch / Wear OS 读取实时心率 + HRV
- **心流检测**：专注时自动弹窗延长计时（+10 分钟，最多 2 次）
- **疲劳检测**：疲惫时推荐微休息（2 分钟）或呼吸引导（3 分钟）
- 2 分钟静息基线校准，无手表时自动降级为模拟数据

### 环境音
- 白噪音 / 雨声 / 咖啡馆 / 森林 四种场景音
- 15 秒无缝循环，音量可调
- Python 脚本程序化生成 WAV 音频文件

### 统计
- 今日完成番茄数 / 本周日历热力图 / 累计专注时长

### 设置
- 三种时长独立调节 / 提示音开关 / 震动开关 / 生物识别开关与重新校准

## 运行

```bash
flutter pub get
flutter run
```

## 构建

```bash
# Android APK
flutter build apk --release

# iOS (需 macOS + Xcode)
flutter build ios --release
```

## 目录结构

```
lib/
  core/          # 主题、工具
  timer/         # 计时器模块
  biometrics/    # 生物传感器模块
  calibration/   # 基线校准
  stats/         # 统计模块
  settings/      # 设置模块
```
