# 甜喵物语

甜喵物语是一个原生 macOS 桌宠。当前正在验收的 **v3.22（构建 54）** 最低支持
macOS 13.0；在录屏、状态和升级测试全部通过前不会作为正式版本发布。

## v3.22 设计

- 唯一正式渲染路线是 Cocoa/Core Animation 原生动画。
- 默认高度约 200 像素，提供小、中、大三档。
- 待机、走路、跳跃、睡眠、打滚、梳毛和抓挠使用真正不同的全身关键姿态。
- `PetState` 管理持续状态，`PetAction` 管理短动作，统一处理衔接、中断和恢复。
- 角落休息和低精力会持续睡眠；点击、拖拽、喂食、陪玩和切换模式均可唤醒。
- 专注计时保存结束时间，重启后恢复，并显示剩余时间和取消入口。
- 通知不可用时降级为桌面气泡；勿扰模式同时禁止通知和气泡。
- 登录时启动使用系统 `SMAppService` 的真实注册状态，默认关闭。
- 菜单和气泡优先使用“娃娃体简”，并移除了脚底人工椭圆底座。

旧 Live2D 制作说明保存在 `Experimental/Live2D/`，不进入运行包，也不在正式菜单里冒充
已接入。仓库目前没有 Cubism `.moc3`、模型配置、动作文件、Core 或 SDK。

## 自动更新边界

Sparkle 2.9.4 仍作为实验发布工具保留。v3.21 已降为预发布并撤出正式 appcast。由于当前
发布环境无法稳定访问更新私钥，v3.22 正式运行包不包含 Sparkle，也不会后台下载安装。
菜单“检查新版”会打开 GitHub Releases。

项目不使用 Developer ID，因此首次打开仍可能出现 Gatekeeper 提示。Sparkle 的 Ed25519
签名只验证更新包来自本项目且未被篡改，不等同于 Apple 身份签名或公证。

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

## 代码结构

- `Sources/TianMiao/PetModels.swift`：状态、动作、设置和专注数据。
- `Sources/TianMiao/PetRenderer.swift`：确定性关键帧时间轴与渲染。
- `Sources/TianMiao/PetWindows.swift`：透明桌宠窗口和气泡。
- `Sources/TianMiao/PetController.swift`：交互、菜单与行为调度。
- `Sources/TianMiao/main.swift`：应用入口。
- `Resources/Poses/`：构建时由已提交母图确定性生成的 25 张全身透明姿态。
- `Experimental/Live2D/`：不参与构建的实验资料。
- `scripts/`：构建、发布、素材生成和验收脚本。
