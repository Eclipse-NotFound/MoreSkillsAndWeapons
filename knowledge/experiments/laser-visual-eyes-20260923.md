---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: user-observation
    summary: "开火效果不佳；实战射中画面眼睛仍不能致盲。"
  - kind: runtime-experiment
    summary: "相同原生 Raider、正常装备及 Weapon.attack/step：旧生产字节扣弹2、blind=0；修复后 blind=6、HP不变，移动转身12次及后续 Location.step 均通过。"
  - kind: decompiled-game-code
    symbol: "fe.unit::Unit.actions, UnitRaider.animate, fe.weapon::Bullet.step"
date-updated: 2026-09-23
---

# 眼部命中与原版激光表现修复

本次处理的是 castRay 编译热修复之后的实战漏判。真实存储诊断为激光 `2-cast-ray`，laserShots=30、laserBlinds=2、laserError=null；这些是累计计数，不能据此推断某一发射击。未将其他功能的累计错误当作激光原因。

## 可复现的失败和原因

`build/test-laser-combat.ps1 -Nodebug` 加载原样生产 SWF，独立 AIR ID，正常换枪与 `Weapon.attack/step`。不手写 eyeX/Y、枪口或碰撞边界；用原生动作、动画和 setPos 更新，准星瞄向截图测量的眼睛。

- 已安装 39991 字节 `909CEF05...`：Raider 在 (500,320)，原生感知点 (486.25,267.5)，实际显示眼睛约 (474,252)。前者位于颈部。手动瞄实际眼睛，扣弹2、shot+1、blind=0；失败保存在 `build/out/laser-visual/installed-before-results.txt`。只调整眼位即恢复6秒零伤害失明。
- 原射线先要求穿过身体矩形才检查眼睛。Protect 的可见传感器约 Y=240，身体顶部 Y=250；校准眼位后仍漏判。`body-gate-red.log` 保留失败，加入独立眼区的最近接触检测后通过。
- 第三个假设是失明被战斗更新清除。修复命中后实际 Location.step 保持 vision=0、celUnit=null，计时正常减少；没有发现这一假设成立。

旧244条机制测试与上次生产开火测试手工设置了眼位，证明的是按给定坐标的机制，不能证明眼位与美术一致。原测试保留用于规则回归，新增独立的可见眼睛命中回归补足此边界。

## 最终实现

- `MSWLaserEyes` 集中提供世界眼位。Raider 等位图角色使用已渲染帧的头部位置表；BlitAnim.f 是下一帧，须从 blitRect 读取当前显示帧。其他已核对角色使用传感器锚点；向量首领读取动画 eye 符号，炮塔读取传感器灯部件。没有改游戏 eyeX/Y 或 AI 感知原点。
- 瞄准辅助、SATS、HUD 与射线共用同一个位置。眼区与身体一起参与最近接触选择，不再要求先进入身体矩形；正面、护盾、墙体与前方单位的规则保留。
- `MSWLaserBeam` 只承载视觉，复用原生激光手枪 `visbullaser2`，放在原版弹道层、按游戏步进4帧淡出。没有原生伤害弹丸，不参与跳弹或智能制导；切图/关闭时清理。移除原来HUD上的青白硬线。
- 核心版本保留 `1.6.2-smart-keep-lock`；激光组件版本改为 `3-visual-eyes`。新增最后一次结果 `laserLastHit`，不保存逐发长日志。既有枪与赠枪标记保持兼容。

## 验证与产物范围

- 原版36类敌人视觉锚点图人工核对；新生产测试24条PASS，覆盖独立测量眼位、正常换枪/开火、传感器框外命中、12组移动转身后的辅助开火、自然战斗状态持续、原版光束资产/弹道图层/4步淡出。`combat-results.txt`、`eye-atlas.png`、`native-eye.png`、`native-laser-beam.png` 在 `build/out/laser-visual/`。
- 激光机制244条PASS；实际 Sandevistan 加回放合计251条PASS，零伤害、护盾/墙体/第一目标、装填、SATS、恐慌攻击与生命周期均通过。准确生产字节的 -nodebug 开火与光束像素检查通过。
- 安装前后同字节启动均900帧，ModSettings-connected、tabOn=1、laserRuntimeVersion=3-visual-eyes，无 lastErr/smartError/laserError。记录 `build/out/laser-visual-production/install-smoke.json` 与 `build/out/laser-visual-installed/install-smoke.json`。
- 期间另一任务在开发多目标智能锁定；用2121565的冻结源码加本次激光文件构建，未收进该未发布功能。逐类反编译：原30类只有 MSWLaser、MSWLaserGeometry、MSWLaserHUD、MSWBlindAccess 改变，另26类一致；新增 Eyes、Beam，共32个生产定义，无测试探针和宿主原类。
- 游戏本体同期被其他工作更新；最终测试副本均核对为当前根 pfe.swf `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`，application.xml 仍加载根 pfe.swf，通用清单仍加载MSW。本任务未修改本体或清单。

## 安装与回滚

正式 SWF 为41512字节，SHA256 `D16523C35BE414FB200D5FFDD31B1453B85F1AF3802A91180805D8FDD0F21BBD`。安装前确认原正式指纹未变，备份到 `release/MoreSkillsWeaponsMod.before-laser-eyes-20260923.swf`（39991字节、SHA256 `909CEF05D810A8F0C0093B34DD0999DC0CE6847E24E0402C1818BFCF435C3744`），再校验并替换。

若回滚，将该备份复制回正式文件并重启；会恢复本次眼位/身体门槛问题。没有关闭用户实例或写入真实存档；用户需重启游戏才能使用修复，已有枪继续可用。

## 验证边界

测试是原生游戏中的隔离场景与随后实际世界步进，不是用户整局战斗录像。36类抽样图不代表所有外观变体、所有动画帧均逐像素标注；部分非头部表角色仍采用经图像核对的局部锚点。未覆盖所有剧情、联机、DLC与全模组组合。
