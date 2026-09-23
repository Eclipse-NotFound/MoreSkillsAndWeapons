---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "79条规则、30项HUD像素、14项设置、准确生产字节51条多目标场景、实际时停逐发快照回放及安装前后900帧检查"
date-updated: 2026-09-23
---

# 智能武器多重锁定实现与验证

## 用户决定与实现

用户两题均选A：视野内所有合格敌人同时累计原锁定进度，不要求准星靠近；每颗子弹轮流分配，霰弹同次射击的弹粒也能分散。详细规则见 `../../design/smart-multi-lock.md`。新增设置 `smartMultiLock` 默认关闭，旧配置补默认；Pip/F6智能页共14项，仍须开启智能武器总开关。

`MSWSmartMultiLock` 按每个单位保留独立 `MSWSmartLock`；数组保持获取顺序，Dictionary仅查身份。只有成功分配推进轮次，未完成或失效目标不占轮次，移除游标前的目标时修正游标。所有现存目标分别继承获取/容错/回退/保持/衰减/恢复，视野外保持只作用于已完成锁定；HUD逐一绘制红蓝菱形。切换模式重新获取，已发射子弹仍保留当时目标、强度和半径。

## 回放匹配与测试观察

原回放取同武器未用记录中出生位置最近的一条；实际时停回放因武器姿态使枪口位置变化，后发记录可能更近。改为按录制顺序取第一条符合原有 `<97 px` 容差的记录，位置作为门槛，不再排序。没有修改Sandevistan源码或正式文件。

实际三发录制目标依次为(750,220)、(680,140)、(800,320)，半径30%、40%、50%；第一发录制枪口(300.25,279.05)，回放三发均为(298.2,262.3)。回放前关闭多重模式、清空当前锁定并改半径为200%，三发仍逐一保留原目标及倍率，且造成真实伤害；原已存在子弹的剩余制导预算也保持。仅用50ms Timer采样会错过/重排观察到的出生，最终探针在每个ENTER_FRAME、智能模块之后采样，不能把旧低频观察顺序当发射顺序。

## 验证证据

| 范围 | 结果与本地证据 |
|---|---|
| 规则与配置 | `build/out/smart-tests/results.txt`：79条PASS。默认关闭/保存/恢复默认、独立时钟、轮换/删除/死亡、保持/候选退回、清空、256目标无固定上限。 |
| HUD像素 | `build/out/smart-hud/results.txt`：30项PASS，顶部逆时针红蓝覆盖、全蓝、退回、多档尺寸/缩放及清理。 |
| 设置与单目标回归 | `build/out/smart/results.txt`：14项真实控件的保存/默认、F6切换；原单目标、遮挡/离屏保持/恢复、暂停、跳弹/特殊弹药场景通过。`settings.png` 已检查14项能显示。 |
| 准确生产SWF多目标 | `build/out/multi-lock-production/results.txt`：51条PASS。三敌远离准星同时获取；离屏/隐形/友方/NPC/遮挡排除；提前发射不补制导；三蓝菱形；9弹各3发；跳弹继承目标/预算；每个目标实际伤害；原生oldshot的5颗特殊弹药弹粒均匀分配；模式切换、独立遮挡/弱化/保持/过期、死亡跳过和总开关清理。 |
| 实际时停逐发回放 | `build/out/sandy-multi/results.txt`：三次真实开火与三次回放逐发目标/30-40-50%半径一致，原弹预算保留、实际伤害、世界恢复、原生子步曲线通过，最大折角1.2285573374062482°。使用当时已冻结的相同智能源码；此轮激光为2-cast-ray，随后最终包仅合入独立激光3修复，并做下列生产激光回归。 |
| 最终生产激光回归 | `build/out/multi-lock-laser/results.txt`：正常开火扣弹12→10，光束回调1、原版世界图层光束及实际像素、失明6秒且HP不变，无验证错误。 |
| 正式编译 | `build/out/multi-lock/link-report.xml`：33个定义，不包含宿主原类、Smoke或Probe。冻结源为提交8678a9b加本轮6个智能源码文件。 |
| 安装前启动 | `build/out/multi-lock-startup/install-smoke.json`：准确候选900帧，版本1.7.0-multi-lock、HUD3-multi-lock、运动1.2-radius、激光3-visual-eyes、ModSettings-connected、tabOn=1，无lastErr/smartError/laserError。 |
| 安装后启动 | `build/out/multi-lock-installed/install-smoke.json`：从正式release复制同字节独立运行，再次达到900帧，版本/设置及无模块错误检查通过。 |

上述路径相对本模组根目录；out为可重建的本地证据。实际时停使用只读复制的Sandevistan正式SWF，50878字节，SHA256 `F556C0728DA406A4A6A05399DF93E9A0349C4225107547F1E12FE88A2AEE3E48`。测试均为独立AIR ID及隔离存储，不操作真实存档。所有生产多目标/激光及最终启动检查针对下节的同一最终候选字节。

## 过程中的更正与边界

- 本环境默认沙箱启动AIR会无测试存储/无输出并超时；隔离测试启动经提权后通过。启动需要等待原自动Pip流程完成，否则时停录制会被自动菜单打断；探针使用帧数门控后通过。
- 并发激光任务将探针期望升级为原版光束。旧激光2候选不能满足该新期望；最终改为以已提交8678a9b冻结完整激光3源码，再合入智能改动，正式字节的新探针回归通过。中间候选未安装。
- 多目标实战是程序化布置并清理物理障碍的场景，部分敌人位置在原房间美术之上；截图用来核对标记，不作为自然游玩展示。移动整个夹具以美化截图曾导致原生碰撞路径下个别指定目标未受伤，最终恢复原验收夹具。子弹始终真实碰撞，沿途对象可以挡枪，多重锁定不保证所有子弹命中其指定敌人。
- 保留原「时停预演 + 跳弹 + 智能绕障」三者组合未通过的边界。本轮证明逐发目标分配/普通回放和跳弹快照继承，不声称修复上述复杂组合，也未覆盖全部长期战斗、联机、DLC或全部模组组合。

## 安装与回滚

最终候选 `build/out/multi-lock/MoreSkillsWeaponsMod.swf` 已复制到 `release/MoreSkillsWeaponsMod.swf`：42525字节，SHA256 `F02FF3DBC917F557C59ADEF2EBC9605163E132FAC964952A1B437B8BF1BB5E97`。核心1.7.0-multi-lock、HUD3-multi-lock、运动1.2-radius、激光3-visual-eyes。保留最新视觉眼位、身体框外传感器、原版光束和castRay修复。未重新打dist分发包。

替换前备份 `release/MoreSkillsWeaponsMod.before-v1.7.0-multi-lock-20260923.swf`：41512字节，SHA256 `D16523C35BE414FB200D5FFDD31B1453B85F1AF3802A91180805D8FDD0F21BBD`。回滚时将该备份复制回正式SWF并重启，可撤销多重锁定并保留视野外保持及最新激光修复。更早备份或build/out内中间候选不等价，不应混用。

安装前后基线保持：根pfe.swf SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`，loader-manifest `4953B682AD9E18C212A0BCB30464AD905E1EB4D39610DC0366230E91F9EEB785`，ModSettings正式SWF `5BD830A63F42130EF56E9C24C0E95B77B9871640B53D5CB4AA5B51E363894B5C`。本轮未修改这些文件或其他模组。只启动/关闭自有测试进程，真实游戏保持运行；用户重启后在Pip或F6智能页开启「多重锁定」即可使用。
