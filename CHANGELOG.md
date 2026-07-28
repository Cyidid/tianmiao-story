# 更新记录

## v3.21（未发布）

- 固定接入 Sparkle 2.9.4，提供应用内“检查更新”和默认每日后台检查。
- 使用固定 SHA-256 下载 Sparkle，并将 framework、Updater 和 XPC 服务嵌入应用。
- 创建项目独立的 Ed25519 更新签名密钥；仓库只保存公钥，私钥保留在发布者 Keychain。
- 正式发布脚本强制验证 Developer ID、hardened runtime、notarization、stapling 和 Sparkle appcast 签名。

### 发布阻塞

- 当前机器没有 Developer ID Application 证书和 notarization Keychain profile。
- 在这两项准备完成并通过真实升级测试前，v3.21 不得推送为正式版本或创建 Release。

## v3.20

- 新增原生跳跃、睡眠和打滚动作，并提供右键菜单及自动预览入口。
- 角落休息和低精力状态会进入持续睡眠；点击、拖拽、喂食、陪玩和模式切换会自然唤醒。
- 专注计时保存结束时间，支持重启恢复、剩余时间显示和取消。
- 通知仅在开启提醒时申请授权；通知不可用时降级为桌面气泡。
- 新增默认关闭的“登录时启动”，使用系统登录项真实状态。
- 明确最低支持 macOS 13.0，并修复构建产物最低系统版本错误。

### 已知限制

- 正式自动更新尚未启用；需要 Developer ID、notarization 和 Sparkle 更新签名链。
- Live2D 原生渲染器仍未接入，桌宠继续使用 Cocoa/Core Animation 分层动画。

## v3.19

- 恢复指定的灰白虎斑甜喵形象，并更新坐姿、行走部件和应用图标。
- 准备包含 42 个命名图层、动作参考和验收清单的 Live2D Cubism 制作源包。
- 在应用中加入 Live2D 资源状态门禁；真实模型缺失时继续使用现有原生分层动画，不显示未完成的 Live2D 动作。
- 修复同步目录可能附加 Finder/File Provider 元数据并导致严格签名失败的问题。
- 集中管理应用版本号和构建号，并新增可验证的正式发布打包流程。

### 已知限制

- 本版本不包含 Cubism Editor 导出的 `.moc3`、`.model3.json`、纹理和动作文件。
- Live2D 原生渲染器尚未接入；桌宠继续使用 Cocoa/Core Animation 分层动画。
