# FlowClock v1.1.0 — 迭代日志 (CHANGELOG)

## Bug Fixes

### 1. 安全中断拦截 — PopScope
- **Root Cause**: `Navigator.push` 全屏后系统回退手势直接 pop，绕过放弃逻辑。
- **Solution**: `TimerPage` 包裹 `PopScope(canPop: false)`，拦截物理返回键和手势，仅保留显式"放弃"按钮。

### 2. 自动无感启动
- **Root Cause**: 进入计时页后需手动点 ▶，交互多一步。
- **Solution**: `initState` → `addPostFrameCallback` 内调用 `ref.read(timerProvider.notifier).start()`。

### 3. 新增结束/放弃按钮
- **Root Cause**: 计时页无显式退出入口，返回键被拦截后无法退出。
- **Solution**: 底部新增"🚪 放弃当前番茄"按钮，点击 → 确认对话框 → `SessionRecorder.recordAbandoned()` 写入 DB → `Navigator.pop()`。

### 4. 精简休息状态 — TimerMode {work, rest}
- **Root Cause**: `TimerMode` 枚举有 `shortBreak`、`longBreak` 三种，增加不必要复杂度。
- **Solution**: 合并为 `{work, rest}`。完成番茄后切换到 `rest`，休息结束后切回 `work`。`breakDuration` 统一为一种。

### 5. UI 文本溢出修复 (>100分钟)
- **Root Cause**: 时长输入框固定 72px 宽度，三位数 `120分钟` 溢出。
- **Solution**: TextField 容器宽度从 72px → 90px；计时显示 `>=100分钟` 时格式设为 `120m00s`，避免 `120:00` 溢出。

### 6. 时间数据绑定失效
- **Root Cause**: 任务未存储单次专注时长，`resetToWork()` 读全局 `workDuration`(25分钟)。
- **Solution**: `tasks` 表新增 `target_minutes` 字段；创建/编辑任务时存储 Slider 值；启动计时调用 `resetToWorkWithDuration(seconds)` 从任务读取。

### 7. 设置项解耦清理
- **Root Cause**: 设置页有"专注时长"滑块，与任务级时长冲突。
- **Solution**: 删除设置页"专注时长"和"长短休息"滑块，仅保留统一"休息时长"。

### 8. 消除黄色双条线
- **Root Cause**: 计时页直接用 `Container` 无 `Scaffold`，Material widget (Slider/TextField) 缺少 `Material` ancestor。
- **Solution**: `TimerPage.build` 返回 `Scaffold(body: Container(...))`，提供完整 Material 上下文。同时为 `TimerPage` 内部控件提供 Material 环境。

## Optimizations
- 导航栏从 4 标签精简为 3 标签（任务/统计/设置）
- 任务卡片支持 `targetMinutes` 字段，按任务独立配置单次专注时长
- 计时页时间显示自适应 ≥100 分钟格式
- `SettingsProvider` 简化为 `workDuration` + `breakDuration` 双字段

## Technical Debt / Notes
- `BiometricNotifier` 的 `startSession`、`stopSession` 等方法在 `TimerNotifier` 中被条件调用，实际目前未激活
- `fatigue_alert_dialog.dart` 和 `flow_extension_dialog.dart` 的方法为占位 stub，后续需完整恢复生物传感器功能
- `TimerNotifier._tickCount` 字段未使用，保留以备后续埋点/统计
- `health` 插件为 Android APK 独占依赖，Web 编译需条件排除
