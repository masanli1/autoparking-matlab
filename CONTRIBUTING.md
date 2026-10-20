# Contributing

感谢你愿意改进 AutoParking MATLAB。

## 适合的贡献

- 算法：Hybrid A* / Reeds–Shepp、斜列车位、平行车位、动态障碍；
- 控制：执行器延迟、转向死区、MPC / LQR 对比；
- 测试：更多随机场景、失败案例、性能基准；
- 文档：教程、图解、英文化；
- GUI：更好的可视化与交互。

## 开发流程

1. Fork 仓库并新建分支：
   ```bash
   git checkout -b feat/your-feature
   ```
2. 保持 MATLAB 基础功能，尽量不引入工具箱依赖。
3. 跑测试：
   ```matlab
   addpath(genpath(pwd));
   parking_main('mode','test');
   test_gui;
   ```
4. 如果改了 1000 次测试相关逻辑，附上新的成功率/误差数据。
5. 提交 PR，说明动机、改动和验证方式。

## 代码风格

- 单位统一用米、秒、弧度；
- 函数名用小写 + 下划线；
- 关键几何/控制公式写注释；
- 新增模块放到对应目录，并在 `docs/ARCHITECTURE.md` 补一行。

## 许可证

贡献即表示同意以 **AGPL-3.0-or-later** 发布你的代码。
