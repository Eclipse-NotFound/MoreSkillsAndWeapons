---
type: experiment
game-version: ["1.02"]
verified: true
date-updated: 2026-09-23
---

# 智能弹道半径与菱形大小设置

## 需求与实现

用户反馈子弹转弯半径、锁定菱形过大，要求两项均可在设置中调节。本轮实现选定默认半径倍率 50%、菱形 24 px；旧手感/大小可调回 100% / 40 px。新配置仅在旧配置缺项时补默认，保留其他选项。

- `smartTurnRadius`：10–200%，步长 10，默认 50。同时反比缩放角速度上限和平滑追踪曲率；否则仅提高既有 smartTurn，仍可能受平滑公式限制而转出大弧线。较小倍率不越过目标方向，原速率/碰撞/伤害/寿命继续由原子弹处理。
- 倍率进入弹丸出膛快照、跳弹继承和时停录制/回放快照；途中改设置只影响新发射子弹。倍率不是固定世界半径，实际弧线也受速度、目标位置和地形影响。
- `smartHudSize`：12–80 屏幕 px，步长 2，默认 24。运行时 frame 传给生产渲染器，大小不受镜头缩放影响；配色、进度方向、前胸位置、2 px 描边和脱锁规则保留。
- Pip 智能页由 10 项变为 12 项；与 F6 共用定义。滑块保存、页面默认恢复、旧配置补项均覆盖。

## 验证证据

- `build/out/smart-tests/results.txt`：53 条断言通过，覆盖旧配置迁移、两项上下限/非法值/保存/默认、原锁定状态、寻路与曲率。局部未饱和条件下，50% 半径使单位距离转角为 100% 的两倍。
- `build/out/smart-hud/results.txt`：30 项光栅检查通过，含 12/24/40/80 px × 0.5/1/1.5/2 倍父层缩放，以及原方向、移动、朝向、双目标与清理。
- `build/out/smooth/results.txt`：真实同类子弹各前进 160 px 时，10/50/100/200% 分别转向 30.663/23.995/15.617/8.914 度；均只扣一次寿命。越小越急、在途快照不变、默认 50% 绕箱扣血/跳弹/预算/清理通过。64 发高速度样本 41 ms，仅为该压力样本，不代表日常帧率。
- `build/out/smart/results.txt`：真实 12 项控件、保存、恢复默认、F6 两项调整，以及原智能武器首步/绕障/跳弹/特殊弹药/锁定/遮挡流程通过。`settings.png` 已查看，新增两项完整显示。
- `build/out/sandy-smart/results.txt`：实际 Sandevistan 慢步/回放通过。录制使用 30%，回放前改为 200%，重建子弹仍保留录制的 30%；原预算/实际扣血/恢复通过，曲线相邻分段峰值转角 0.2295°。
- `build/out/smart-hud-game/results.txt`：14 项原游戏检查通过，新增四档生产 frame 尺寸检查。`game-two-targets.png` 已查看，默认 24 px 在真实 Raider 前胸正确显示。
- `build/out/smart-tuning/link-report.xml`：生产 30 个模组定义，宿主类均 external，没有 Smoke/Probe 或原版 Pt/Unit/Bullet/Weapon 嵌入。

全部测试使用全新独立 AIR ID、隐藏窗口及私有副本；未操作真实存档或关闭用户进程。测试明确用程序化场景，不等于长时间自然战斗或所有模组组合认证。

## 环境变化与并发

首次旧游戏探针因缺 `mods/loader-manifest.txt` 未加载模组，stdout 明确报告 manifest IOError，未形成业务失败证据。根 SWF 已在 2026-09-22 改为通用加载器；查证共享 loader 记录后，给本轮四个游戏测试脚本补齐清单复制，重跑均通过。本轮不改根 SWF 或清单。

候选在 10:04:50 固定，之后发现其他任务于 10:05:37/39 开始改 MSWLaserGeometry/MSWLaser，随后又有 smartKeepOutOfSight 视野外保持锁定及对应测试改动。它们不属于本轮、未进入候选，也不纳入本轮提交；非致命激光仍为既有 v1.6.0 实现，正式智能页仍为 12 项。保留这些并发工作区改动，并按改动片段提交本轮内容。

## 产物与回滚

- v1.6.1-smart-tuning，HUD `2-adjustable-size`、运动 `1.2-radius`，39761 字节，SHA256 `439A477F9487DEB2465DB180AA5360971BE5C59F1261B203A795901D6A4D3B62`。
- 发布前同字节候选检查通过：`build/out/smart-tuning-production/install-smoke.json`，900 帧、ModSettings-connected、tabOn=1，无 lastErr/smartError/laserError。
- 备份 `release/MoreSkillsWeaponsMod.before-v1.6.1-20260923.swf` 为 v1.6.0，39403 字节，SHA256 `EF5FBA0F8407E25432F38CF9A9342D8D802B1F80243011C43A8693CEF92A713E`。仅复制此备份覆盖正式模组并重启即可回滚。
- 根 SWF SHA256 `252E7B34FC8BF0DD8CF566F45876597FE999562BE0F2E6AB596215D1A514C6DB`；加载清单 `1FFBFC87AD79C4026277500BABD756744E4EEA440A02A60D8A1BD4C746CD2855`；ModSettings `5BD830A63F42130EF56E9C24C0E95B77B9871640B53D5CB4AA5B51E363894B5C`，保持不变。
- 安装后同字节重启也通过：`build/out/smart-tuning-installed/install-smoke.json`，900 帧、版本/HUD 标记正确、ModSettings-connected、tabOn=1，无 lastErr/smartError/laserError。用户进程保留，重启后生效。旧时停预演 + 跳弹 + 智能绕障三者组合边界仍保留。
