---
type: experiment
game-version: ["1.02"]
verified: true
date-updated: 2026-09-23
---

# 视野外保持智能武器锁定

## 行为与边界

新增智能武器设置 `smartKeepOutOfSight`，默认关闭，旧存档配置缺项时也取关闭。关闭时，失去目视后仍按既有保持时间与衰减时间逐渐脱锁。开启时，仅已完成的锁定在失去目视后保持当前强度，不累积脱锁计时；切回关闭，从当时重新开始原有计时。锁定已经减弱时开启开关不会凭空回满，重新目视后仍按原恢复时间渐进回满。候选目标首次获取的可见性要求和进度回退不变。

本模组当前的目视判定包含画面范围、敌人的 `isVis` 与隐形状态、玩家到敌人的地形视线。因此该开关覆盖离屏和墙体遮挡；目标死亡、换房、阵营改变、玩家死亡、进入 SATS、换至不支持的武器或关闭智能总开关仍沿用原清除流程。子弹在发射时保存锁定强度，此开关只影响随后开火的快照，不追溯增强已发射子弹。

## 验证

- `build/test-smart-unit.ps1`：58 项断言通过。检查旧配置补默认、开关保存、已完成锁定在视野外 10 秒保持部分强度、候选目标仍回退、重新目视渐进恢复、关闭开关后按原时间脱锁。
- `build/test-smart.ps1`：隔离的真实游戏场景通过。Pip 智能页和 F6 均可调整并保存开关，恢复默认后关闭；已锁目标移至屏幕外 2.6 秒、再由实墙遮挡 2.6 秒仍保持满锁。关闭后，原保持、衰减、重新目视恢复和完全脱锁不能穿墙重新获取都通过。证据见 `build/out/smart/results.txt` 与设置截图 `build/out/smart/settings.png`。
- 生产编译及链接报告通过：30 个模组定义，宿主类仍为外部依赖，未嵌入测试探针。
- `build/out/keep-lock-production/install-smoke.json`：同字节候选在当前 1.02 游戏和 ModSettings 独立副本启动到 900 帧，版本 `1.6.2-smart-keep-lock`、设置连接正常，无 `lastErr`、`smartError`、`laserError`。初次使用较旧测试副本的游戏 SWF 被指纹检查拒绝；改用刚重建的 `test-smart-runtime` 后通过。
- `build/out/laser-shot/results.txt`：同一生产候选的原生激光命中仍只耗两份电池、使敌人失明且无直接伤害，射线实际绘制，无运行错误。

自动场景覆盖锁定流程，不代表长时间自然战斗或全部模组组合。测试副本使用独立 AIR 应用 ID，不读写真实存档。

## 部署状态

用户本轮明确选择安装后，候选 `build/out/keep-lock/MoreSkillsWeaponsMod.swf` 已同字节替换正式 `release/MoreSkillsWeaponsMod.swf`。新版本 39991 字节，SHA256 `909CEF05D810A8F0C0093B34DD0999DC0CE6847E24E0402C1818BFCF435C3744`。它基于已提交的 v1.6.1 智能参数更新与激光生产修复，不包含其他未提交功能。

替换前原正式版已备份到 `release/MoreSkillsWeaponsMod.before-v1.6.2-keep-lock-20260923.swf`，39842 字节，SHA256 `573709F879ED6A538D49110A73836053123DC859F47376D2C63D221090E5B089`。若需回滚，将该备份复制回正式 SWF 并重启游戏即可；这会撤销本次开关，但保留 v1.6.1 激光修复。安装后的相同字节再次独立启动到 900 帧，ModSettings-connected、tabOn=1、版本与 HUD/激光标记正确，无 `lastErr`、`smartError` 或 `laserError`；证据 `build/out/keep-lock-installed/install-smoke.json`。根游戏、清单、ModSettings 与真实存档未改；用户游戏进程未关闭，重启后生效。
