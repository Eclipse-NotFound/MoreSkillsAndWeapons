---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产两枪对普通及首领天角兽的开盾/背后眼区命中：93条通过，生命与护盾不变；原枪真实存读档199条、多目标52项通过。"
date-updated: 2026-09-24
---

# 激光笔共用非正面开关与天角兽护盾例外

用户要求激光笔接入已有背后致盲，并反馈开盾天角兽无法致盲；针对原先护盾阻挡约定，用户明确选B：**两把非致命激光武器均可穿天角兽护盾致盲，不伤血、不削盾**。本次延续已安装功能修订，版本`1.14.0-laser-contact`。

## 原因与实现

旧准确安装字节E1EA2AC2…在真实普通/首领天角兽上复现：无盾正面眼区命中为blind6，盾80时两枪均为shield/0；激光笔即使打开laserNonFront也仍back/0。这来自旧显式规则，不是伤害链偶发故障。原版UnitAlicorn/UnitBossAlicorn的shithp与护盾显示已在实际对象上设置并animate。

- `MSWLaserGeometry.shieldBlocks`仅豁免`fe.unit::UnitAlicorn`及`UnitBossAlicorn`；两枪共用几何射线，完全不调用普通伤害或削盾链。其他盾牌仍阻挡。
- `MSWPointer`把现有laserNonFront传给`MSWPointerSweep`的当前及帧间射线。切换规则时丢弃跨规则插值历史，关闭不消除既有失明，但不再刷新背面接触。
- 沿用同一个默认false的设置和保存键；激光枪页说明同时控制两枪，激光笔眼区提示指向该开关。不新增页/配置键、不引入辅助瞄准；原枪非正面外围比例不作用于激光笔。
- 必须实际经过有效眼区；墙箱、第一个敌人身体、其他单位护盾继续阻挡。激光笔持续电池计费、来源计时、时停/存读档规则未改。

## 准确字节与验证

最终源码已选择性合入主项目提交`9d3a551`，保留已提交眼圈优化、分组设置和全部原功能；同期未提交SATS修复保持其工作区状态，未偷带进本产物。候选55258字节，SHA256 `7AE25C6BABEF61DBB3A158AD9E20FD8DBB3B473E4E66E34D2226CF2DA4F73ACF`，40生产定义，无宿主原类或探针。准确产物与冻结源码在`build/out/laser-contact/`。

| 证据 | 结果及边界 |
| --- | --- |
| verification/contacts/results.txt | 93 PASS：两枪×两类天角兽；无盾/有盾正面、背面开关、身体命中、墙箱、原枪身体辅助、其他盾阻挡、生命/护盾不变；连续照射关闭开关、帧间扫眼与持久化。 |
| verification/laser/results.txt | 199 PASS：真实装备、保存、comLoad、延迟装备、原枪开火/6秒/零伤害、15项设置、各方向辅助及实际舞台原版光束（12帧/476像素）。不等于修复原生SATS选敌。 |
| verification/multi/results.txt | 52项检查/53 PASS，真实多目标伤害、逐弹分配、霰弹、跳弹继承、脱锁及设置状态回归。 |
| verification/pre-merge | 原候选ABC1CCFC…/55227字节的专项93、原枪199、多锁52项及完整激光笔157 PASS。完整笔覆盖40类、真实存读档、正常耗电、连续光束、实际Sandevistan与不回放；合并后未冒称重跑此完整套件。 |

实际时停（合并前候选）：2.40秒耗4.722电池；普通4.57秒耗9.064；光束194显示帧/225像素。合并仅新增MSWLaser眼圈重绘去重，笔/扫掠/计费源码未再改。

基线测试还包含一次旧6参接口调用新版第7参的#1063，这只能证明旧接口不兼容，不能作为护盾根因。早期夹具重复changeWeapon同一武器会原生收枪，已修夹具后重跑；基线本身的盾/背面断言已有独立观察。合入主分支曾因同期推进而不能快进，后按文件选择性集成，保留他人SATS/近距智能及journal历史重排。

## 发布与回滚

已安装最终7AE25C6B…准确字节。安装前、安装后各900帧：版本1.14.0、ModSettings-connected/tabOn=1、无模块错误。安装时先核对正式已推进到v1.13.2/620A5BB9…（不是最初E1基线），保留眼圈优化后备份替换；回执`build/out/laser-contact/installation.json`。

当前回滚只需退出游戏后，将`release/MoreSkillsWeaponsMod.before-v1.14.0-laser-contact-20260924.swf`复制为同目录`MoreSkillsWeaponsMod.swf`，再重启；回到v1.13.2/620A5BB9…/55175字节。保持现有ModLoader2.3、根SWF和清单不变，不需要旧分组阶段的双模组回滚。真实游戏未重启，由用户保存并重启后生效。

本次不修改根pfe.swf、loader-manifest、其他模组或真实配置/存档；测试均为独立AIR ID。未覆盖联机、DLC及所有长期战斗。墙箱仍阻挡；不把天角兽例外推广给所有盾。
