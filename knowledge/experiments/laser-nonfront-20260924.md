---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确优化生产SWF：199行新配置、205行真实升级回退、391行八类炮塔与52项多锁通过；当前设置宿主安装前后900帧通过。"
date-updated: 2026-09-24
---

# 可选非正面致盲与较小外围辅助

用户Q1–Q7均A并整体“确认”。已实现并安装 **v1.12.0-nonfront-laser**，激光组件 **7-nonfront-assist**。基线是0f42e15的v1.11.1炮塔修复；自适应半径、透窗、多锁、豁免与菜单功能保留。设计见../../design/laser-rear-assist.md。

## 规则与实现

- `laserNonFront=false`、`laserNonFrontRatio=50`，缺项补默认，旧参数和未知键保留。Pip/F6共用，比例0–100/步长5，重置恢复默认；激光页共15项。
- castRay追加默认false的可选参数，旧调用仍限制正面。手动、SATS及辅助可达性明确传入当前开关，只放宽方向，不跳过身体/障碍首接触、有效眼区、护盾、传感器展开及敌人资格。
- 普通辅助在已衰减的身体外围范围上，对非正面目标乘比例；直接身体选择先于该过滤，保持无效所指目标不改投。使用枪口到眼部的归一化射线，普通角色按storona，炮塔按二维炮口点积。HUD复用同一选择器。
- 当前默认前方60/30、非正面30/15像素（站定/高速）；0只移除非正面外围，不影响直接身体/手动精瞄/SATS；100恢复与正面同范围。关闭方向开关只影响后续开火，已有失明按原计时结束。

## 生产字节与测试

冻结源码、候选和链接表：`build/out/laser-nonfront/release`。产物 **49560字节**，SHA256 **B8EB77D2005B427FA06F40D8FC2A9A5AA68C3E5A5E4DF282CC43FC2629B2684F**。36生产定义，无宿主原类或测试探针；所有测试后的正式候选字节未变化。

| 检查 | 证据与结果 |
| --- | --- |
| 新配置、真实读档、延迟装备、开火、辅助与UI | `reload-fresh/results.txt`，199行PASS（含结束行）；当前ModLoader设置宿主下最终复验，未暂停舞台光束9显示帧、峰值474像素。 |
| 同URL真实旧SWF升级/回退 | `reload-upgrade/legacy-settings-host-results.txt`，205行PASS。旧v1.11.1保存后新键保持，原速度/时长与回退参数不重置。此轮用旧ModSettings宿主，配置读写由MSW自持。 |
| 八类炮塔 | `turret/results.txt`，391行PASS，0FAIL；8种×4方向正面/非正面实际武器开火、32个垂直传感器射线、各方向30/60外围边界；护盾、收起、停机及原地恐慌/恢复。此轮用旧ModSettings宿主。 |
| 多锁生产字节 | `release/multi-results.txt`，52项，真实多目标分弹、遮挡/死亡/退出状态通过，旧ModSettings宿主。 |
| 同冻结源码的开发驱动 | `release/mechanism-results.txt`，251行PASS；36类敌人、恐慌友伤、生命周期、SATS、实际Sandevistan时停与回放。该套件另编译带驱动，不冒称安装文件的字节测试。 |
| 当前设置宿主启动 | `preinstall-current-host/install-smoke.json`、`postinstall-current-host/install-smoke.json`，各900帧，ModSettings-connected、tabOn=1，无lastErr/smartError/laserError。 |

上述目录均相对`build/out/laser-nonfront/`。具体新增边界包含：前/后/严格上下、近中远真实身体射击、二维速度及高速下限、半速22.5px、0/100比例、原正面范围不变、枪口越过目标、无辅助手动眼/身体、SATS不受外围、关闭不清既有状态、墙/箱/护盾/前方单位、HUD与所选目标一致。普通实际射击保持每发2电池、零生命伤害和6秒失明。

Pip实际checkbox/slider/reset事件与F6键路由、保存、范围边界均有断言；15行文字在面板内。PNG为同一驱动步直接绘制，原生控件皮肤尚未经过下一显示帧，不把即时PNG当完整皮肤截图。旧宿主图与当前宿主图均留存，最终`nonfront-pip.png`已去除测试未刷新造成的F6残影。

## 两次阻断与处理

1. 第一轮混合朝向候选断言失败。独立检查发现邻近目标的眼线被第一个身体阻挡，不能要求其被选中。将邻近目标下移并单独断言眼线可达后，同一生产字节通过；未修改生产逻辑迁就测试。失败文本`reload-upgrade/failed-mixed-fixture.txt`保留。
2. 首次安装后2400帧无tabOn，立即回滚。SOL显示waiting-ModSettings；ModLoader.sol显示此时清单已改为启用ModLoader、禁用旧ModSettings，而隔离副本没有复制新的ModLoaderMod.swf，报2035。安装前原清单曾直接加载ModSettings，故通过。根pfe与候选字节均未改变。
3. 更新本模组构建目录的`copy-settings-host.ps1`，按实际1.02清单复制唯一启用的设置宿主；读档/炮塔/机制/安装脚本接入它。当前ModLoader宿主下199行实战/UI与900帧安装前检查通过，才重新安装；安装后900帧再次通过。旧失败SOL/加载器对照留在`postinstall/`。未修改ModLoader、ModSettings或根清单。

## 安装和回滚

- 正式：`release/MoreSkillsWeaponsMod.swf`，B8EB…，49560字节。
- 最终回滚点：`release/MoreSkillsWeaponsMod.before-v1.12.0-nonfront-laser-final-20260924.swf`，49203字节，SHA256 **C233D67EA0C5FC74BD0499ADFB1AD1C45823CAEEDA7145806D84BE101ABF0827**。复制回正式文件名后重启，恢复v1.11.1。首次尝试的同基线备份也保留，未覆盖。
- 当前宿主：根pfe SHA256 B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC；同期ModLoader设置宿主C9701A91013899E2674F29990AC6E4977A6C4678D0AE47D8C14324F97084704C。清单及指纹快照见`release/installation-context.json`。
- 所有测试均唯一AIR应用ID、隐藏窗口和独立存档。未关闭用户游戏或改真实存档；用户重启后在Pip「模组→MSW→非致命激光枪」或F6激光页启用新开关。

没有修改自适应/玻璃/豁免逻辑，本轮未重跑它们全部历史矩阵。四向炮塔包含直接设定炮口角度的几何检查，不声称各底座自然支持360°；未覆盖全部剧情、第三方敌人、长时间战斗、联机或DLC。原时停预演＋跳弹＋智能绕障的组合问题未纳入本次修复。
