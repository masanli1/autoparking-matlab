# AutoParking MATLAB — CodeOnly 发布包

这是**纯代码/仿真版**，不包含 B 站成片、封面、BGM、视频渲染脚本或 `release/` 大文件。

## 内容

```text
AutoParking-MATLAB-v1.0.0-CodeOnly/
├── README.md                    GitHub 主页（纯代码版）
├── LICENSE                      AGPL-3.0 全文
├── docs/ARCHITECTURE.md         架构 / 几何 / 控制律 / 测试协议
├── parking_main.m               主入口
├── parking_gui.m                交互演示台（含 GUI 录制功能）
├── config/ env/ vehicle/ planning/ control/ sim/ gui/ util/ tests/
├── CITATION.cff
├── CONTRIBUTING.md
├── CHANGELOG.md
└── VERSION
```

## 先验证

```matlab
cd AutoParking-MATLAB-v1.0.0-CodeOnly
addpath(genpath(pwd));
parking_main('mode','test');
test_gui;
```

预期：`ALL TESTS PASSED`、`ALL GUI TESTS PASSED`，1000 次测试为 1000/1000。

## 发布到 GitHub

1. 仓库已使用 GitHub 用户名 `masanli1`；如账号不同，请全局替换 `masanli1`。
2. 登录 `gh`：
   ```bash
   gh auth login
   ```
3. 在本目录执行：
   ```bash
   ./publish_github.sh
   ```
   或手动：
   ```bash
   git init
   git add .
   git commit -m "feat: AutoParking MATLAB v1.0.0"
   gh repo create autoparking-matlab --public --source=. --remote=origin --push
   ```

## 许可证

AGPL-3.0-or-later。详见 `LICENSE`。
