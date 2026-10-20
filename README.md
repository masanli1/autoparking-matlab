# AutoParking MATLAB

**1000 次倒车入库 · 100% 成功 · 0 碰撞**

一个零工具箱依赖的 MATLAB 自动泊车仿真项目：Hermite 前进接近 → 90° 圆弧倒车入库 → 路径跟踪 → 1000 次蒙特卡洛 → 交互演示台。

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020b%2B-ff6f00?style=flat-square)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-AGPL--3.0-2ea44f?style=flat-square)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-1000%2F1000-brightgreen?style=flat-square)](#-验证结果)

> 本仓库是**纯代码 / 仿真版**，不包含视频成片、封面、BGM 或视频渲染脚本。  
> 适合自动驾驶入门、路径规划/控制课程设计、MATLAB 仿真教学。

## ✨ 特性

- **1000 / 1000 成功**：随机起始位姿、初始航向 ±20°、初始前轮 ±20°，0 碰撞、0 规划失败。
- **真正的倒车入库**：前进到 staging 位 → 停车换挡 → 90° 圆弧 + 直线倒入车位，最终车头朝车道。
- **完整状态机**：`APPROACH → SHIFT → REVERSE → PARKED`，包含预打方向、碰撞/超时处理。
- **可解释的算法**：Hermite 路径、圆弧几何、前馈 + 横向/航向反馈，公式见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
- **交互演示台**：随机生成小车、点击车道放置、目标车位 1–8、速度调节、规划路径显示。
- **界面录制**：可把 GUI 演示录制为 MP4/AVI，保存到 `results/`。
- **零工具箱依赖**：仅使用 MATLAB 基础功能。

## 🚀 快速开始

### 环境要求

- MATLAB **R2020b+**（R2026b 已完整测试）
- 不需要任何工具箱

### 安装

```bash
git clone https://github.com/masanli1/autoparking-matlab.git
cd autoparking-matlab
```

在 MATLAB 中：

```matlab
cd autoparking-matlab
addpath(genpath(pwd));

parking_main                                  % 固定场景演示
parking_main('mode','demo','animate',true)    % 播放动画
parking_main('mode','single')                 % 随机起点跑一次
parking_main('mode','monte-carlo','cases',1000)
parking_gui                                   % 交互演示台
parking_main('mode','test')                   % 单元 + 集成测试
```

命令行（无界面）：

```bash
matlab -sd "$(pwd)" -batch "addpath(genpath(pwd)); parking_main('mode','monte-carlo','cases',1000)"
```

### 交互演示台

```matlab
parking_gui
```

| 控件 | 作用 |
| --- | --- |
| ① 随机生成小车 | 在车道内随机采样一个可行起始位姿 |
| ② 点击车道放置 | 在车道空白处单击生成小车，自动选择左/右接近方向 |
| ③ 开始泊车演示 | 播放前进接近 → 换挡 → 倒车入库 |
| ● 录制演示 / ■ 停止录制 | 录制 GUI 演示，保存 MP4/AVI 到 `results/` |
| 停止 / 重置 | 中止播放 / 清空场景 |
| 目标车位 | 1–8 切换 |
| 演示速度 | 调整动画帧间隔 |

## 🧠 3 分钟看懂

### 1. 环境

30 × 18 m 车库，8 个 2.8 × 5.2 m 垂直车位，7.5 m 宽车道；车辆 4.5 × 1.85 m，轴距 2.7 m，最大前轮转角 35°。

### 2. 前进接近

从任意车道起始位姿 `P0` 到 staging 位 `P1`，生成三次 Hermite 曲线：

```text
P(t) = h00(t)·P0 + h10(t)·m0 + h01(t)·P1 + h11(t)·m1
```

- staging 位：`[xs + R, ye - R, 0]` 或 `[xs - R, ye - R, π]`
- `R = 4.8 m`，对应前轮约 29.4°，留出约 5.6° 转向修正余量

### 3. 停车换挡 + 预打方向

到达 staging 后停车 0.9 s，先把方向盘打到倒车圆弧前馈角，再挂倒挡，避免因 40°/s 转向速率限制而在入弯时滞后。

### 4. 倒车入库

以左接近为例，圆弧圆心 `C = [xs + R, ye]`，从 staging 走 90° 顺时针圆弧到车位入口，再沿中心线直线倒车到：

```text
[xs, ye + depth - rear_overhang - clearance, -90°]
```

路径跟踪使用统一控制律：

```text
δ = g·atan(L·κ) − g·kθ·eθ − klat·elat
```

其中 `g = +1` 前进、`g = -1` 倒车；`κ` 为路径曲率，`eθ` 为航向误差，`elat` 为横向误差。

### 5. 1000 次蒙特卡洛

随机起点、随机航向/前轮，跑完整状态机并统计成功率、碰撞、最终误差、耗时：

```matlab
parking_main('mode','monte-carlo','cases',1000)
```

## 📊 验证结果

最终 1000 次测试（`rng(2026)`，目标车位 4）：

| 指标 | 结果 |
| --- | ---: |
| 成功 | **1000 / 1000（100%）** |
| 碰撞 | 0 |
| 规划失败 | 0 |
| 最终位置误差（均值 / 最大） | 0.0268 m / 0.0329 m |
| 最终航向误差（均值 / 最大） | 0.538° / 1.021° |
| P95 位置误差 | 0.0274 m |
| 平均仿真时长 | 46.7 s |
| 1000 次实际耗时 | 33.6 s |

复现：

```matlab
parking_main('mode','monte-carlo','cases',1000)
```

输出：

- `results/monte_carlo_1000.csv`
- `results/monte_carlo_1000.mat`
- `results/mc_1000_starts.png`
- `results/mc_1000_errors.png`
- `results/mc_1000_samples.png`

目标车位 1–8 各跑 10 次也全部成功。

## 🗂️ 项目结构

```text
autoparking-matlab/
├── parking_main.m              主入口：demo / single / monte-carlo / gui / test
├── parking_gui.m               交互演示台（随机/点击放置 + 录制）
├── config/default_config.m     全部参数
├── env/                        车库环境、占用栅格、绘图
├── vehicle/                    自行车模型、车身足迹、碰撞检测
├── planning/                   Hermite 前进路径、倒车圆弧、路径校验
├── control/track_path.m        前馈 + 横向/航向反馈跟踪
├── sim/                        状态机、随机场景、1000 次蒙特卡洛
├── gui/                        虚拟小车图形、点击位置 -> 起始位姿
├── tests/                      核心测试、GUI 测试、录制测试
├── docs/ARCHITECTURE.md        架构、几何、控制律、测试协议
├── LICENSE                     AGPL-3.0
└── README.md
```

## 🧪 测试

```matlab
addpath(genpath(pwd));

parking_main('mode','test')   % 环境/运动学/路径端点/单次泊车/20 次冒烟
test_gui                      % GUI 自检 + 5 个点击放置点
test_recording                % GUI 录制测试
```

命令行：

```bash
matlab -sd "$(pwd)" -batch "addpath(genpath(pwd)); parking_main('mode','test')"
matlab -sd "$(pwd)" -batch "addpath(genpath(pwd)); test_gui"
matlab -sd "$(pwd)" -batch "addpath(genpath(pwd)); test_recording"
```

## ⚖️ 许可证

本项目使用 **[GNU Affero General Public License v3.0](LICENSE)**（AGPL-3.0）。

- 可自由使用、修改、分发；
- 修改后若通过网络提供服务，需以 AGPL-3.0 公开修改后的源代码；
- 分发时保留版权声明和许可证文本。

如需闭源商用授权，请单独联系维护者。

## 📝 引用

```bibtex
@software{autoparking_matlab_2026,
  title  = {AutoParking MATLAB: 1000-case reverse parking simulation},
  author = {masanli1},
  year   = {2026},
  version= {1.0.0},
  license= {AGPL-3.0-or-later},
  url    = {https://github.com/masanli1/autoparking-matlab}
}
```

也可使用 [CITATION.cff](CITATION.cff)。

## English

**AutoParking MATLAB** is a from-scratch, toolbox-free automatic parking simulator:
Hermite forward approach, a 90° reverse arc into a perpendicular slot, path tracking,
collision checking, a 1000-case Monte Carlo study (100% success, 0 collisions),
and an interactive GUI with optional recording.
Licensed under **AGPL-3.0**.
