---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产字节、实际 Sandevistan 热键慢速阶段、原生轻机枪开火及固定初态 Bullet 的红绿对照。"
  - kind: decompiled-game-code
    game-version: "1.02"
    symbol: "fe.weapon::Bullet.run / udar; fe.weapon::Weapon.shoot"
date-updated: 2026-09-24
---

# 近距智能子弹绕圈：v1.14.2-smart-near

用户报告时停攻击近敌转圈，澄清为**时停中的慢速阶段、轻机枪、一至三个身位**。只读核对其智能配置为自适应开、普通50%、最低10%。开发轮完成修复与隔离验证；随后用户明确“直接安装，不要再做测试”，已安装准确候选，未新增测试、启动游戏或操作真实存档。

## 根因与修复

1. 预测曾使用较粗、最多32段的积分，真实飞行最多256段。固定初态 `(350,250), v=(320,0)`、目标框 `[385,415]×[260,300]` 时，预测47.5%半径在0.21875逻辑步命中，实际擦过后绕约280°、行进1297.78px。统一到 `MSWSmartRoute.motionSamples` 后，预测正确否决47.5%，实际在65.19px命中。
2. 预测的线段扫掠命中比原生 `Bullet.run` 的采样点落框更宽松。仅统一积分后仍有边角擦过误报；固定轻机枪初态 `(406.75,341.15), v=(180,0)` 选择15%时仍绕圈。预测改成相同采样点判定后，选中可行的12.5%，103.125px命中。
3. 循环轨迹耗尽256次预测预算后返回unknown，旧选择器因“未知不能证明不可达”而不试更小半径。最终直达段已绕目标超过270°时，现在明确返回orbit并沿原有抽样/细化流程找更小半径；多拐角路线期间不累计绕目标角度，真正的预算不足仍是unknown。

实际移动仍调用同一颗原生Bullet.run，未改速度、伤害、寿命、转向上限、弹药碰撞或制导预算。固定半径/上下限相等分支不变。收紧和渐进恢复仍受用户原有上下限约束，无新设置。

预测判定只估算到达目标框，无法替代原生护盾、特殊形状、闪避或动态障碍；不承诺必中。最低半径过大或关闭自适应时仍可能绕远。这里未修改Sandevistan，也未声称修复历史“时停预演+跳弹+绕障”三者组合。

## 红绿证据与单变量排查

所有输出在 `build/out/near-smart/`；`results.txt`与`trajectories.json`保留逐发轨迹。隔离运行副本可清理，冻结源码、SWF、结果不删除。

| 对照 | 结果 |
|---|---|
| 旧版高速单发 `slow-minimal` / `normal-minimal` | 两种时间状态均同样绕约280°，排除仅由时停重复转向引起 |
| 旧版预测细节 `forecast-refine` | 47.5%预测命中，实际擦过；不是单纯“绕远后命中也合格” |
| 只改积分 `precision-fast` | 高速反例转绿，47.5%正确预测为失败 |
| 只改积分 `precision-lmg` | 原生轻机枪仍绕圈，预测unknown；证明尚有第二类问题 |
| 再加orbit `green-slow` | 普通高速弹通过，但固定轻机枪边角仍失败；揭示线段扫掠误判 |
| 对齐采样点 `final-lmg-deterministic` | 固定轻机枪103.125px、约117°命中 |
| 冻结旧版 `baseline-lmg-deterministic` | 同初态行进6874px、约7.7圈后接触目标，新增回归稳定检出旧问题 |
| 原生轻机枪 `lmg-winding-red` | 准星偏离、近距目标，约8.5圈才命中 |
| 修复后 `final-lmg-burst` | 原生随机速度/散布连续12发全部接触目标，无完整绕圈 |

基线：v1.13.1 `E1EA2AC2…`、v1.13.2 `620A5BB9…`；修复开发候选 `53E7283D…`。上述不是最终合并版的指纹。普通轻机枪速度由原生200及0.8–1.2随机倍率产生，320高速合成弹是精度回归，不冒充轻机枪常规弹速。

## 最终完整候选

基于已正式安装的v1.14.1冻结源，仅叠加三个智能实现文件和主版本号，保留眼圈响应、激光笔非正面、天角兽护盾和SATS选敌修复。

- `build/out/near-smart/final/MoreSkillsWeaponsMod.swf`：**55504字节**，SHA256 **`C01F426A358BB995829A200854039A2E836B285B59183364B43256F104F48F81`**。
- 40个生产定义，无宿主原类或外置探针；冻结源码和链接表在同目录。
- 最终准确字节：`verified-slow`与`verified-normal`各8组固定初态+1次原生轻机枪，`verified-lmg`连续12发原生轻机枪全部通过原生接触/停点/无绕圈断言；正常时间还通过伤害断言。
- 24项自适应、39项透窗、52项多锁、199项激光真实读档/开火通过。包括移动目标、普通半径保持、渐进恢复、上下限、实体绕障、窄通道、跳弹快照、寿命/速度以及64弹压力场景。结果与指纹清单在同目录manifest及`verified-*`。
- 64弹自适应一次物理推进86–132ms，固定15–17ms；为压力场景成本，不等同日常FPS，也不宣称预测无额外开销。

测试入口：`build/test-near-smart.ps1`，支持`-ProductionSwf`、`-Mode normal`、`-Only lmg-off-axis`、`-Only actual -Distance 70 -AimOffset 60 -Shots 12`。原生碰撞记录、停止位置和绕角共同验收；正常时间额外检查真实伤害。慢速预演伤害被Sandevistan清零，不能要求此阶段立即扣血。

## 安装回执（2026-09-24 13:59）

- 用户明确要求直接安装、不再测试。正式文件仍为候选基线v1.14.1/17BDF40A…，备份后替换为上述55504字节/C01F426A…，文件一致性核对通过。
- 备份：`release/MoreSkillsWeaponsMod.before-v1.14.2-smart-near-20260924-135857.swf`，55427字节/17BDF40A…。退出游戏后以此恢复正式文件，再重启可回滚。
- 回执：`build/out/near-smart/final/installation.json`。复用上一轮验证，本次未运行测试、未重启游戏、未触碰真实存档、游戏本体或其他模组；用户保存并重启生效。
- 第一次替换调用因PowerShell空备份参数报错，正式字节未变；改用同目录覆盖重命名后完成，既有备份保留。

## 测试夹具修正与边界

- 最初整片地面把大圈截断；改成仅玩家脚下支撑，才看到完整轨迹。实际开火在后续玩家步生成，须持续观察而非只检查attack返回后的同一瞬间。
- 原生弹在首次观察时可能已飞过一段，因此绕角起点须取`begx/begy`，不能以首次观察的末点代替枪口。轨迹记录取motionPath，不凭最终命中判定无绕圈。
- 新增伤害断言曾错误用于慢速预演，`verified-slow/results-invalid-damage-assert.txt`保留失败；原生接触及停点均正确。随后按Sandevistan既有伤害延迟语义改用parr接触记录，正常时间单独验伤害，没有为测试修改生产伤害。
- 旧测试脚本写死ModSettings宿主/历史主版本；改用现有设置宿主复制助手，准确文件由运行器SHA校验，业务控制器仍须实际存在。
- 磁盘满只清理本任务已退出的runtime副本后继续；未删除结果、唯一资料或其他任务文件。
- 通用离散点碰撞知识已有 `shared-knowledge/physics-collision/discoveries/collision-motion-source-audit-2026-09-09.md`，不重复建卡。本文件记录MSW专属预测偏差与修复。
