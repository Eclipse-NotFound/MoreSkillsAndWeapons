---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "隔离 AIR 游戏副本，原版 Bullet.step/run、Unit.udarBullet，10 次反弹扣血与轻机枪精度距离对照。"
  - kind: decompiled-game-code
    game-version: "1.02"
    symbol: "fe.weapon::Bullet.accuracy/run; fe.unit::Unit.udarBullet"
date-updated: 2026-09-20
---

# 多次跳弹伤害诊断

## 用户场景与范围

用户报告普通时间下使用轻机枪，能看到子弹碰到敌人但不扣血、无伤害数字。实际配置读取：基础 10 次、额外概率 61%、三种衰减均 0%。未获取具体敌人、累计路径、人物技能与武器改装，因此下述命中率不是用户存档的精确预测。

## 伤害继承与命中是两个环节

`build/test-damage.ps1` 驱动游戏副本；独立应用 ID，不修改真实存档。暂停世界，手动调用原版 Bullet.step 撞墙，交由生产 MSWBullets 帧处理生成续弹，再调用原版 Unit.udarBullet 测扣血。固定伤害 100，关闭随机伤害与暴击，目标不闪避：直射及 10 次反弹均扣 100 HP；目标 skin=100、子弹 pier=20/armorMult=0.5 时均扣 70 HP。基础次数耗尽、额外概率 0 时第 11 次撞墙停止。未发现 0% 设置导致伤害额外衰减。

命中实验使用游戏 `Invent.addWeapon("lmg")` 实例读出的基础 precision=480、antiprec=0，目标 dexter=1、dexterPlus=0、子弹 miss=0。对第 10 次续弹调用真实 Bullet.run，固定其位置与目标外形相交，逐次清空命中名单；仅改变累计 dist。每组 2,000 次：

| dist（像素） | 扣血次数 | 0 扣血且继续飞行 | 每次有效扣血 |
|---|---:|---:|---:|
| 100 | 2000 | 0 | 100 |
| 1000 | 913 | 1087 | 100 |
| 5000 | 171 | 1829 | 100 |
| 10000 | 82 | 1918 | 100 |

结果与原版命中概率 `min(1, precision / dist / (dexter+dexterPlus+0.05))` 一致（上述条件下）。几何相交后仍可能判未命中，返回 -1，不扣血，Bullet.run 不调用 popadalo，子弹继续飞行。正式显示还受 showHit 设置影响；本测试关闭数字显示，仅以 HP/子弹状态验证，不声称拍摄到用户画面。

MSWBullets.copyBullet 继承 dist，v1.4.0 前代码也如此。多次跳弹放大原有累计距离效应，不是新增伤害衰减公式把伤害清零。游戏机制已有公共记录 `shared-knowledge/weapons-projectiles/discoveries/combat-pipeline-source-audit-2026-09-09.md` §5，此处保留本模组实验，不重复立公共机制文档。

## 独立发现：精确墙面碰撞会吞续弹

已确认的额外缺陷，但与用户补充的“子弹仍飞行”不同：墙外起点距离墙面 5 px，dx=10，原版拆为两个 5 px 子步，第一次恰好落在墙面。镜像反射位置仍等于墙面坐标，旧代码的闭区间墙内保护因此取消续弹。相同墙体改为距墙 6 px，则正常续弹。真实测试与独立四方向回归均在修复前失败。

修复仅对镜像位置增加最小 0.01 px 向外净空，不改变伤害、精度或距离继承。修复后四方向测试通过，总计 286 项断言；真实游戏精确边界/普通穿入交替 10 次、扣血及终止通过。

最初测试误选相邻实心墙，子弹出生在另一块墙内；该失败无效。修正为墙前 phis=0 并断言实际碰撞为选定墙体后才确认上述缺陷。早期直接拼接 XML 多个型号的 char.@prec 会读错数值；正式记录采用游戏创建的基础武器实例，不能沿用早期样本。

## 未做的玩法改动与交付状态

没有重置 dist、提高跳弹精度或绕过闪避。若希望反弹后仍可靠命中，需要另行决定命中规则：每次反弹重置命中距离会增强长链，同时保留敌人闪避和武器精度；直接必中则改动更大。不能以“修伤害”为由暗中改变这项平衡。

只提交源码边界修复与测试，正式 release 仍为 v1.4.0，SHA256 `D87B233391E87AE6BE4BB224055D5F2615B2DC3E1DFF0EF6929391508D3CF1EC`。测试不覆盖自然开火、高弹量性能或其他模组同时运行。
