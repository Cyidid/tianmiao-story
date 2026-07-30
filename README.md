# 甜喵物语

甜喵物语是一款原生 macOS 桌宠，用自然的待机、行走和互动动作安静地陪伴在桌面上。

当前正式版本为 **v3.22（构建 54）**，支持 Apple 芯片 Mac，最低要求 macOS 13.0。

[下载甜喵物语 v3.22](https://github.com/Cyidid/tianmiao-story/releases/tag/v3.22) ·
[查看正式更新说明](RELEASE_NOTES.md)

## 产品功能

- 支持待机、行走、跳跃、睡眠、打滚、梳毛、抓挠和点击反馈。
- 喂小鱼干、陪它玩和摸摸头会同时改变状态并播放对应动作。
- 默认高度约 200 像素，可选择小、中、大三档。
- 角落休息和低精力会持续睡眠；点击、拖拽、喂食、陪玩和切换模式均可唤醒。
- 专注计时保存结束时间，重启后恢复，并显示剩余时间和取消入口。
- 通知不可用时降级为桌面气泡；勿扰模式同时禁止通知和气泡。
- 登录时启动使用系统 `SMAppService` 的真实注册状态，默认关闭。

## 安装

1. 从 [GitHub Releases](https://github.com/Cyidid/tianmiao-story/releases/tag/v3.22)
   下载 `tianmiao-story-macos-v3.22.zip`。
2. 解压后将“甜喵物语”拖入“应用程序”。
3. 首次打开若被 macOS 拦截，请前往“系统设置 → 隐私与安全性”，确认允许打开。

下载包 SHA-256：

```text
1f0d4a148f1a1f8d6fb73ba98629fb91065896c228fea9e8484668523fc5dda0
```

## 更新与签名说明

v3.22 不会在后台下载安装更新。菜单“检查新版”会打开 GitHub Releases，由用户手动下载
正式版本。

项目暂未使用 Developer ID 签名和 Apple 公证，因此首次打开可能出现 Gatekeeper 提示。
应用仅支持 arm64，不支持 Intel Mac。

## 构建

需要 macOS、Xcode Command Line Tools 和 Python 3/Pillow：

```bash
./scripts/build_app.sh
```

正式构建不下载或嵌入 Sparkle。版本号统一维护在 `Config/version.env`。

普通手动包：

```bash
./scripts/package_release.sh
```

实验 Sparkle 包工具仍保留，但不用于本次正式发布：

```bash
./scripts/package_signed_release.sh
```

`scripts/verify_pose_assets.py` 会检查全部 25 张透明关键帧的数量、画布、透明通道和
安全边距。录屏不再作为正式发布的强制条件。

旧 Live2D 制作资料保存在 `Experimental/Live2D/`，不参与正式构建，也不作为产品功能展示。

## 代码结构

- `Sources/TianMiao/PetModels.swift`：状态、动作、设置和专注数据。
- `Sources/TianMiao/PetRenderer.swift`：确定性关键帧时间轴与渲染。
- `Sources/TianMiao/PetWindows.swift`：透明桌宠窗口和气泡。
- `Sources/TianMiao/PetController.swift`：交互、菜单与行为调度。
- `Sources/TianMiao/main.swift`：应用入口。
- `Resources/Poses/`：构建时由已提交母图确定性生成的 25 张全身透明姿态。
- `Experimental/Live2D/`：不参与构建的实验资料。
- `scripts/`：构建、发布、素材生成和验收脚本。
