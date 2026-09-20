---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "独立 AIR 应用 ID、原生 1.02 游戏副本；244 项普通回归、36 种原生敌人、Sandevistan 慢步及逐发回放；正式 release 未变。"
date-updated: 2026-09-20
---

# 非致命激光枪实现与隔离验证

用户在 Q1–Q25 和整体补充边界之后明确“按此实现”。实现依据见 `design/nonlethal-laser.md`。本轮生成候选 v1.6.0-dazzler，没有安装；正式仍 v1.5.3。

## 实现

- `MSWLaser` 注入 mswdazzler，按 Game.triggers 的 per-save 标记赠枪，不赠弹。原生存档仍保存武器 id、hold、ammo 等；读取原版武器后升级为唯一子类 `MSWDazzlerWeapon`，同时接续装备、childObjs 和 SATS 引用。
- 新子类仅覆写本枪 shoot，在原生开火成功当下触发光束。保留原生半自动、装填、声音、SATS bookkeeping；kol=0，不创建有伤害的激光 Bullet。固定按设置扣弹，回收专长不改变每匣可射次数。不用帧后计数变化猜开火，避免短间隔/回放观察窗口问题。
- 几何模块逐格遍历地形，对实际墙块/实体箱体矩形取首交点，再找首个单位；在眼位附近小圆内且从朝向一侧射入才致盲。活护盾阻挡。辅助不选择隐形或不可见单位；手动命中仍按几何规则。
- `MSWBlindController` 在原单位前插入原生 Pt 派生节点，只替代其 control 流程，继续原生受力、碰撞、actions、动画和武器子对象步进。清掉 Unit/Raider 的内部目标缓存，计时跟随敌人实际行动步。死亡、场景切换、脚本禁用和关闭功能解除接管；关闭/休眠炮塔不会被唤醒。
- 恐慌只改变射击方向与移动输入，不修改阵营。原生弹丸用临时 targetObj 通过原生伤害路径；爆炸只在该弹的执行期间放开同伴 blast 免疫，随后恢复。WClub 复用的非链表攻击体用 `MSWPanicBlade` 保留原生扫掠几何：恐慌开始的挥击延续到恢复后，之后普通挥击恢复阵营过滤。新生成的原生 SmartBullet 清空目标，避免失明导弹仍追踪玩家。
- 新增 11 项设置，进入独立 ModSettings 的 msw-laser 页，同时沿用 MSW F6 浮层，Tab/PageUp/PageDown 三页切换。HUD 为短光束、眼圈、失明倒计时，状态标记仅装备本枪时显示。
- 原生 `Unit`、`UnitRaider`、`SatsCel`、`Weapon`、`Bullet`、`Pt` 都是外部声明；正式模组仅包含唯一新增类，不替换本体类。内部访问 helper 延迟解析，全部显式 includes，生产 build 自动检查链接定义表。

## 运行验证

命令都在 build 目录；唯一应用 ID 与隔离副本不会读写真实 pfe 存档。

| 检查 | 证据/结果 |
|---|---|
| `test-laser.ps1` | `out/laser/results.txt`：244 条 PASS，包含最终结束标记；无 laserError。 |
| 普通原生敌人 | 36 类：raider/slaver/zebra/ranger/merc/encl/alicorn；protect/gutsy/robot/eqd/sentinel/roller/spritebot/vortex/dron/msp/thunderhead；turret/landturret/wturret/bossturret；zombie/hellhound/rat/ant/bloat/bloodwing/fish/necros；bossraider/bossnecr/bossalicorn/megadron/bossencl/ultra。各类接管与恢复通过，有武器者另断言其原生武器实际产生攻击。 |
| 命中及辅助 | 正面眼中、身体无效、背面无效、墙挡、护盾挡、首个单位截断、高装甲/高闪避不否定几何命中、水平/垂直高速辅助归零、手动精瞄仍成功、隐形不辅助。 |
| 射击与补给 | 按住仅一枪；6 次点射恰好耗尽 12 份电池（recyc=1 也如此）；原生装填 60 步；缩容退回电池；开关/改射速不会凭空再发；存档标志经 AMF 往返、原版武器恢复后状态接续、丢弃/出售不补发。 |
| SATS | 原队项身份读取、地点队项保持地点、选中眼部可超出普通辅助角；实际 UnitPlayer.step 执行队列并扣 17 AP、2 弹药。 |
| 恐慌伤害 | 原生持枪实际生成弹丸；入盲前弹不变；已发弹在恢复后仍可同阵营误伤；中立受伤；原本 friendlyExpl=0 的同伴能被恐慌爆炸伤害且字段随后恢复；近身生物与刀棍误伤、之后正常挥击恢复豁免。 |
| 生命周期 | 30 行动步消耗 1 秒、重击刷新不叠加、只渲染不扣时间；外部禁用保留、濒死回原流程、切场景清状态、关闭功能恢复视觉、关机炮塔拒绝接管。 |
| `test-laser.ps1 -Sandevistan` | `out/laser/sandevistan-results.txt`：真实已安装 v1.140 的只读副本，实际热键、显示冻结帧和慢步、时停中开火、一次记录一次回放均通过。使用独立 config。 |
| 原功能回归 | `test-smart-unit.ps1` 42 条；`test-ricochet.ps1` 315 条；`test-smart.ps1` 实机场景含绕障、64 弹批次、锁定/遮挡/暂停和设置通过。 |
| HUD/F6 | `out/laser/laser-hud.png` 与 `laser-settings.png` 已目视检查；11 项齐全，可键盘调整并持久化；独立 ModSettings 注册通过。 |

生产产物为 `out/MoreSkillsWeaponsMod.swf`；同字节持续启动检查由 `test-installed.ps1 -ProductionSwf <候选路径>` 执行，结果独立保存在 `out/laser-production/install-smoke.json`。脚本名中的 installed 不表示本轮已部署。

最终候选：39403 字节，SHA256 `EF5FBA0F8407E25432F38CF9A9342D8D802B1F80243011C43A8693CEF92A713E`；生产检查 frames=900、laserGifts=1、ModSettings-connected、tabOn=1，无 lastErr/smartError/laserError。链接报告含 30 个模组定义，不含六个原生类声明或 Smoke/Probe。编译器输出的链接报告未转义仓库路径中的 `&`，检查器仅在解析副本时补 XML 转义。

## 有价值的失败与修复

- 强类型 helper 过早进入文档类依赖使 loader 无 COMPLETE：改为 includes + 场景就绪后解析。同包访问实证已归入 shared-knowledge。
- 只等待 landData 自动开档发生 Land.prepareRooms 空引用：需 allLandsLoaded。不是 Rooms 损坏或宿主版本换掉。
- 首轮只测控制状态漏掉 tip=0 敌人枪和刀棍非链表攻击体；新增逐类真实攻击断言后分别修复，不能以“失明状态存在”替代“武器真的乱攻”。
- 不能给所有单位硬设 animState="attack"；Necros 不含这个动画。沿用原生可用武器/身体接触攻击。
- Bullet.vse 为 internal，默认包直接读会 #1069；用在链状态判断清理。
- 长批次测试的旧弹丸仍在场景链中，会杀掉后续计时靶，制造 SATS 队列自动取消；后续场景先清测试攻击体，计时必须同时断言靶存活及剩余时间大于零。
- Sandevistan 进入后的第一显示帧尚无 recPrevWid/hold 基线，同帧开火可能不记入回放；当前联测延后 6 个 50ms tick 再发射。这是该版本已有录制边界，本轮没有写其源码或配置。不能宣称已覆盖同帧热键+开火。

## 验证边界

没有验证所有敌人变体/剧情组合、长时间自然战斗、联机或 DLC 1.03/1.04；36 类覆盖不等于所有关卡所有状态。眼部使用游戏公开眼位并按体型缩放，未为每套美术逐帧标注骨骼。时停联测覆盖本枪普通单次开火/回放与行动计时，不宣称所有原有时停+跳弹+智能三者问题已解决。正式游戏 SWF、release 和其他模组未修改。
