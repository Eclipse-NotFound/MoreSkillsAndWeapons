---
domain: entities
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产字节复现原生眼位可见却无法多锁、侦测显形天角兽仍被隐身标志排除；眼位单变量32项通过，最终44项可见性和87项聚焦通过。"
date-updated: 2026-09-28
---

# 智能武器目视锁定误判

用户报告：无遮挡、明显在屏幕内的敌人经常锁不上，已补充主要是多重锁定；具体敌人及枪名尚未提供。按现有开发/直接实装工作流处理，不重新讨论已确认的多锁、聚焦或脱锁规则。

## 已复现的问题与单变量证据

正式基线 v1.15.2：63443字节，SHA256 `36B9C19193D231C99DB02BBF9CCF9F801ECA81C5347AD01E9FD961ED4E67B474`。外部驱动 `build/test-smart-visibility.ps1` 只编译探针并加载准确生产SWF，不链接或替换生产函数；使用独立AIR ID、原生单位，不强制把所有敌人 `isVis` 改成true。

1. `baseline2/results.txt`：8类普通可见目标17项通过，隐身斑马自然未获锁定。未把这组绿色结果当成用户问题已解决。
2. `native-eye-baseline/results.txt`：普通敌人和12组镜头缩放/平移正常；平台场景两项失败，原生眼位视线可达，但智能可见性false且一秒后仍无多锁。玩家(220,360)、体型50×70、朝右，原生感知眼位(232.5,307.5)，旧估算起点(220,311)；支撑平台到x=280、顶面y=360，掠夺者(420,580)。从原生眼位到敌人头部的射线越过平台边缘，旧起点的三条中线射线被平台挡住。
3. 只改起点、保持采样点/相机/敌人状态不变，`eye-only-test/results.txt`：32项全部通过。中间候选63448字节，SHA `5B4A9ABD168481EA4E04373FC406F0F247D0C524FEE186731EE81345A54D18C4`。说明本例并非多锁时钟或整帧更新中断。
4. `infrared-baseline/results.txt`：在眼位候选中再加原生 alicorn1 自身control触发隐身；玩家infravis=1后原生animate令其完全显形，alpha=1，但isVis=false、invis=true。无遮挡、屏幕内仍拒绝可见与实际多锁，两项失败。关闭侦测后拒绝锁定本来正确。

以上是两个独立、已稳定执行的复现场景，不能据此宣称已经覆盖用户所有未描述的敌人/地形。实际MSW配置只读核对：多锁、聚焦和视野外保持均开，获取0.6秒；19项豁免是用户现有选择，未修改。历史diag存有无时点/调用栈的frame #1009；全新隔离实例无该错误且上述误判仍能复现，未把旧累计错误认定为本轮根因。

## 最终改动

- `MSWSmartWeapons.visible` 用原生 `Unit.actions` 相同公式计算当前玩家感知眼位，避免新位置尚未刷新eyeX/Y缓存。没有改变美术眼位/激光瞄眼数据。
- `infraredRevealed` 仅覆盖原生UnitAlicorn、UnitBossAlicorn、UnitBossNecr支持的侦测显形机制；要求玩家infravis>0、图像visible且alpha>0.5。随后仍检查屏幕和原有玻璃感知射线，不放行其他隐藏机制。
- 单/多锁共用，无新参数；锁定时间、聚焦、强度恢复/脱锁、视野外保持、子弹路径和曳光没有变化。未泛化移除isVis/invis检查。

冻结源与准确候选：`build/out/smart-visibility/final/`；v1.15.3-visible-lock，**63631字节**，SHA256 `81FAD2EBCA9F272117BBDEAA8DFF2D2A550213700A0A04D1C761148F407F628F`，43生产定义，无游戏宿主类或探针混入。

## 验证

- `candidate-test/results.txt`：44项通过；普通原生敌人、镜头缩放/平移、平台边缘、原生侦测显形的单/多锁；离屏、实体墙、隐藏/低透明图像、关闭侦测及其他类型的隐身状态仍拒绝。最后一项其他类型的隐身标记是显式边界夹具，不冒称完整钻地动画实测。
- `focus/results.txt`：87项通过；既有HUD、设置保存、多锁分弹、聚焦切换/死亡回退、跳弹继承、时钟/保持/独立脱锁及真实命中。
- `glass/results.txt`：39项通过；普通/装甲窗锁定、普通窗实际打碎、未破装甲窗绕行、破口通行、窗口后实体墙、混合弹药、64弹及跳弹边界。
- `laser/results.txt`：199行PASS（含最终标记）；准确候选实际保存/comLoad、延迟装备、激光开火和完整舞台光束。
- `startup/install-smoke.json`：正常loader入口900帧通过，版本1.15.3-visible-lock、ModSettings-connected、tabOn=1，无smartError/laserError。启动实例仅准备MSW及设置宿主，不据此声称其他全部模组已联测。测试过程中无真实存档写入或真实游戏操作。

## 安装与回滚

2026-09-28 21:24 已原子替换正式 `release/MoreSkillsWeaponsMod.swf`，安装后哈希与上述冻结候选一致；未启动或关闭真实游戏，用户保存并重启后生效。安装回执 `build/out/smart-visibility/installation.json`。

回滚备份 `release/MoreSkillsWeaponsMod.before-v1.15.3-visible-lock-20260928-212428.swf`，仍为v1.15.2的63443字节/36B9C191…；退出游戏后复制为正式文件名并重启即可。安装前核对基线未被其他任务改动；游戏根pfe.swf仍为C631CBF3…、ModLoader设置宿主仍为375951AE…，未修改游戏本体、清单、设置宿主或其他模组。安装后只核准确字节，复用安装前同字节隔离结果。

## 范围与调查过程

首个探针误用了不存在的spider单位ID，修正为原生bloodwing后继续；首次眼位候选调用用了相对路径，被脚本Push-Location影响而未启动，改为预先解析绝对路径。读MSW配置时既有Python SOL工具不支持AMF3 traits引用，先出现错位解码，改用本轮独立读取器核对后才引用豁免结果；未据错位结果改游戏配置。

普通天角兽的显形及锁定已运行验证；两个首领的同类显形条件只做源码核对。未认证DLC、所有模组组合或全部战斗地形；本轮不重复曳光像素/时停/眼位全量历史套件，相关源码及功能完整保留。原生机制记录见公共 `entities/discoveries/native-stealth-infrared-visibility.md`；感知眼位与美术眼睛的区别仍以 `perception-eye-vs-rendered-eye.md` 为准。
