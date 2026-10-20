# Changelog

## v1.0.0 — 2026-10-20

首个公开版本。

### 核心

- 8 车位车库环境、4.5 m 车辆、7.5 m 车道。
- 三次 Hermite 前进接近 + staging 位。
- 90° 圆弧 + 直线倒车入库，最终车头朝车道。
- 前馈 + 横向/航向反馈路径跟踪。
- `APPROACH → SHIFT → REVERSE → PARKED` 状态机。
- 1000 次蒙特卡洛：100% 成功、0 碰撞、0 规划失败。

### 工程

- 模块化目录：`env/ vehicle/ planning/ control/ sim/ gui/ tests/`。
- 零工具箱依赖。
- `parking_main` 主入口：demo / single / monte-carlo / gui / test。
- `parking_gui` 交互演示台：随机生成、点击放置、目标车位 1–8、速度调节。
- 虚拟小车：车身、车顶、车窗、车轮、灯光。
- 界面录制：MP4 优先、AVI 回退，自动保存到 `results/`。

### 许可证

- AGPL-3.0-or-later。
