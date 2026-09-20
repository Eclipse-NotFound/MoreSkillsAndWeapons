---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "唯一 AIR 应用 ID、复制的真实游戏；设置控件、真实 Bullet/Unit/Weapon、时停回放副本及生产产物启动。"
  - kind: decompiled-game-code
    game-version: "1.02"
    symbol: "fe.loc.Location.step; fe.Pt; fe.weapon.Bullet.step/run; fe.inter.Camera.calc"
date-updated: 2026-09-20
---

# 智能武器 v1.5.0 实装验证

## 环境与复跑

`build/test-smart-unit.ps1`、`test-smart.ps1`、`test-smart-sandy.ps1`。运行真实根 `pfe.swf` 1.02 的资源副本，每轮唯一 app ID，隐藏窗口。真实 pfe 存档和已运行的用户进程不碰。Sandevistan 仅复制 release SWF 与使用测试专属配置：slowfactor=5、replayspeed=3。

游戏本体 SHA256：`5300EC4874E0404D298BB58C5D2A7469E82F93B455AD29AD64DD2E29D17241E7`。
Sandevistan 样本 SHA256：`4F44D602B8E02532F64F9640B9BB98F3B5FD918EC13319B4441E07B4B89A8625`。

## 已验证

- 42 项规则：获取/切换/容错/回退/保持/衰减/恢复；十项默认与保存；有限绕障、封闭失败、限速转弯/掉头/恒定弹速。
- 真实 Pip 10 项：九滑块、一开关、0.05 步长、关闭页后保存非默认小数、即时开关保存、恢复默认；F6 Tab 切页和数值修改。已人工核对截图 `build/out/smart/settings.png`。
- 外部 `fe.Pt` 子类可以加入原场景链。链首钩子在真实 Bullet 的 liv=100、首次移动前已写入制导与 precision/miss=0，之后由原 Bullet.step 运动并命中高闪避靶。
- 人工布置的真实地形箱体：直线被挡，原版 Bullet 实际弯曲绕箱并对后方 Unit 扣血；碰撞和实体墙仍有效。近墙低转速强制撞击后，原跳弹生成的新 Bullet 方向先反射，继承精度豁免、目标和剩余预算，再恢复制导。
- 原版 `oldshot` 创建多颗霰弹；弹药修改伤害类型为等离子后仍按来源枪种获得制导。普通手枪合格，轨道炮排除。
- 64 发局部绕障本机单次钩子约 16–17 ms；有分散出生点的弹丸分步轮到有限搜索，没有固定顺序饥饿。此数值为特定箱体/测试负载，非全地图帧率保证。
- 实际帧循环：按 Camera.celX/celY 驱动准星获取；新增墙体遮挡后保持/渐弱，框继续显示；移墙后恢复；打开真实 Pip 时锁定计时冻结；完全脱锁后不可隔墙获取。
- 已发射弹与武器锁定独立；目标转友方终止；显示帧无物理推进不扣预算；制导到期后保留物理弹/命中豁免；关闭主开关移除钩子。
- Sandevistan 联合运行：真实热键启动、实际枪械三次开火、冻结帧与慢速物理步计时相符；真实回放重建弹丸恢复原目标快照，无失配；重建弹丸获得制导并消耗自身预算，回放钉住的旧弹预算不变；回放实际对靶扣血，结束后恢复正常世界状态。
- 旧功能回归：315 项跳弹断言；真实设置/基础及额外反弹；连续十次实际扣血、护甲/穿甲、距离命中率对照均通过。结果在 `build/out/tests`、`out/smoke`、`out/damage`。

## 实现中修正的具体问题

- 0.1 秒经过三次 1/30 扣除后会剩浮点尾数，增加 1e-9 归零，防止多转一次。
- 寻路预算不足的弹丸原先与前排同步等待六步，可能总抢不到机会；改为下一步重试，已有路线照常继续。
- 回放不能仅扫描原对象引用：要匹配重建弹丸；也不能对被录像钉住、没真正运动的旧弹再次消耗预算。
- 原版子控件是 `fl.controls.ScrollBar.scrollPosition`；截图在恢复默认重建行后需要重新收集控件并 drawNow。
- 测试装枪必须同时设置玩家 `childObjs[0]`；仅 currentWeapon 赋值不会在玩家步进时产生真实射击。准星使用 Camera.celX/celY，直接写 World.celX 会被相机下一帧覆盖。
- 补充回放扣血断言曾因上述准星驱动错误失败：匹配/预算通过但子弹未命中。先恢复正式旧版后隔离排查，固定 Camera 输入后真实命中与扣血通过；未修改制导源码来迁就测试。随后重装此前同字节生产产物并再次检查加载。

## 保留边界

- 支持附近简单障碍；不保证封闭空间、多拐角或贴墙极高速子弹成功绕开。保留普通碰撞和有限转向，因此失败可以表现为撞墙/跳弹。
- 智能弹的强度和参数在发射时固定。时停回放按当前协议重放；不宣称随机散布、移动敌人、所有武器节奏和其他模组组合的逐像素一致。
- 玩家原先已开 godMode 时，公共 onPause/godMode 标记不能可靠区分时停与回放，沿既存兼容边界处理。
- 既有跳弹要求当前 damage>0；Sandevistan 慢步会把玩家弹丸伤害暂归零。本轮验证了普通时间智能跳弹，以及时停/回放智能射击，**没有解决或宣称通过“时停预演 + 跳弹 + 智能绕障”三者组合**。不得通过私自恢复临时零伤害来掩盖该限制。
- 特殊敌人的独立免疫/防御不改动；原版伤害流程和普通高闪避靶已测，不等于逐个特殊敌人实战全覆盖。长时间自然战斗、联机和 DLC 1.03/1.04 未测试。

## 产物与回滚

正式 `release/MoreSkillsWeaponsMod.swf`：34457 字节，SHA256 `B3D076B51D36E164740F373B6745980D3A2C9FCB8949208FAE94536891BAB6DB`。
反编译核对共 20 个模组类，包含唯一新回放节点，不包含原版 `fe.Pt` 定义。
备份 `release/MoreSkillsWeaponsMod.before-v1.5.0-20260920.swf`：27521 字节，SHA256 `F9DCD668B57B3EE9B44A52649D55432276AFADE9DEF0EF9E46BA5AB9B9ADCDB3`。
需回滚时将该备份复制覆盖正式 SWF 后重启。仅关闭智能武器可直接关闭主开关。
生产同字节副本重启验证：`ver=1.5.0-smart-weapons`、frames=900、modAPI=published、tabOn=1，无 lastErr/smartError，结果 `build/out/install-smoke.json`。
