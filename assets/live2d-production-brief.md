# 甜喵 Live2D 模型制作与导出规范

## 角色基准

只使用当前指定灰白虎斑猫形象：大圆眼、灰白虎斑、粉色耳内与嘴部、轻手绘线条。不得换脸型、换画风或换成临时替代猫。所有动作必须能识别为同一只猫。

## Cubism 分层命名

PSD/Cubism 图层必须使用稳定英文名，方便 app、Web 和验收脚本对齐：

| 分组 | 必需图层 |
| --- | --- |
| Head | `HeadBase`, `FaceWhite`, `ForeheadStripes`, `CheekStripesL`, `CheekStripesR`, `Nose`, `MouthUpper`, `MouthInner`, `MouthTongue`, `WhiskersL`, `WhiskersR` |
| Ears | `EarL`, `EarR`, `EarInnerL`, `EarInnerR` |
| Eyes | `EyeWhiteL`, `EyeWhiteR`, `PupilL`, `PupilR`, `EyeHighlightL`, `EyeHighlightR`, `EyelidUpperL`, `EyelidUpperR`, `EyelidLowerL`, `EyelidLowerR` |
| Body | `BodyBase`, `ChestWhite`, `BackStripes`, `HipBase` |
| Legs | `FrontLegNear`, `FrontLegFar`, `FrontPawNear`, `FrontPawFar`, `HindLegNear`, `HindLegFar`, `HindPawNear`, `HindPawFar` |
| Tail | `TailRoot`, `TailMid`, `TailTip`, `TailStripes` |
| Effects | `GroundShadow` |

关节处必须预留遮挡重叠：颈部、肩部、髋部、尾根至少保留 12-18 px 等效高分辨率重叠区，避免运动时露底或出现白边。

## Cubism 参数命名

首批模型必须包含这些参数，范围按 Cubism 常规设定：

| 参数 | 范围 | 用途 |
| --- | --- | --- |
| `ParamAngleX` | -30..30 | 轻微左右看 |
| `ParamAngleY` | -30..30 | 轻微上下看 |
| `ParamAngleZ` | -30..30 | 头部小幅倾斜，只用于瞬时反馈 |
| `ParamBodyAngleX` | -10..10 | 行走重心 |
| `ParamBodyAngleZ` | -10..10 | 梳毛/挠抓身体平衡 |
| `ParamEyeLOpen`, `ParamEyeROpen` | 0..1 | 眨眼 |
| `ParamEyeBallX`, `ParamEyeBallY` | -1..1 | 视线 |
| `ParamMouthOpenY` | 0..1 | 点击反馈/开心口型 |
| `ParamTailAngle` | -30..30 | 尾巴摆动 |
| `ParamPawNear`, `ParamPawFar` | -1..1 | 前爪动作 |
| `ParamLegNear`, `ParamLegFar` | -1..1 | 行走对角腿 |

中性姿态必须头部端正，不能长期歪头。

## 动作文件

只导出首批 6 个真实动作，文件名固定：

| 文件 | 建议时长 | 要求 |
| --- | --- | --- |
| `motions/idle.motion3.json` | 2.6-3.2s loop | 轻呼吸、尾巴小幅摆动、眼睛微动 |
| `motions/blink.motion3.json` | 0.4-0.7s | 自然闭眼再睁眼 |
| `motions/tap.motion3.json` | 0.45-0.8s | 点击短反馈，不切换长期姿态 |
| `motions/walk.motion3.json` | 0.7-1.0s loop | 四腿对角交替承重，脚底接触线稳定 |
| `motions/groom.motion3.json` | 1.2-1.8s | 抬前爪梳毛，爪子与头部有遮挡关系 |
| `motions/scratch.motion3.json` | 0.8-1.4s | 短促挠抓，身体不过度晃动 |

睡眠、翻滚、跳跃暂不制作入口。除非 Cubism 导出对应 `.motion3.json` 并通过验收，否则不得加入 app 菜单或在线预览。

## 导出目录

Cubism 导出后必须放入：

```text
Resources/Live2D/Tianmiao/
  tianmiao.model3.json
  tianmiao.moc3
  textures/
    texture_00.png
  motions/
    idle.motion3.json
    blink.motion3.json
    tap.motion3.json
    walk.motion3.json
    groom.motion3.json
    scratch.motion3.json
  expressions/            optional
  physics.json            optional
  pose3.json              optional
```

Web 预览不得单独维护另一套模型，必须通过 `python3 scripts/sync_live2d_assets.py` 从 app 资源同步到 `web-preview/public/live2d/Tianmiao/`。

## 验收清单

- `REQUIRE_LIVE2D_ASSETS=1 python3 scripts/verify_live2d_assets.py` 通过。
- `python3 scripts/sync_live2d_assets.py --check` 通过。
- app 和 Web 引用同一个 `assetVersion`。
- 缩放到 `360x392` 桌宠画布仍清晰。
- 头、身体、爪子、尾巴连接处没有断裂、白边或纸片旋转感。
- 正面、侧向、行走中都能识别为同一只灰白虎斑甜喵。
- 连续点击 10 次只触发 `tap`，不跳姿态、不闪烁。
