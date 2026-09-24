---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: decompiled-game-code
    symbol: "fe.weapon::Bullet.run; fe.loc::Box.initDoor/setDoor; fe::AllData.d.obj"
  - kind: runtime-experiment
    summary: "准确优化生产SWF：8类原生箱柜、普通/装甲窗、实心墙和关闭/打开的门，两武器原生回调、辅助、SATS目标、持续及插值光束、可见落点和Pip/F6配置。253行PASS。"
date-updated: 2026-09-24
---

# 两种激光的箱柜与玻璃穿透

用户要求非致命激光枪与激光笔默认不被集装箱、箱子、医疗箱、文件柜等物体阻挡，并给激光笔保留阻挡开关；随后明确普通与装甲玻璃都应透光。已安装 **v1.14.3-laser-props**，保留完整v1.14.2近距智能修复与此前SATS/眼圈/分组等能力。

## 实现

- 旧 `MSWLaserGeometry.wall` 将loc.objs中全部phis>0物体按整块矩形截断，混同了角色物理范围与子弹阻挡。原生Bullet.run通常按地图Tile和单位处理，另有指定撬锁目标、敌弹击中被玩家托举箱子的特殊路径；不能把Box.phis>0当成普通子弹必停的依据。本次激光不复制破锁/破坏副作用。
- 两枪共用射线默认不再截断普通箱柜；非致命枪的手动、辅助、HUD可达与SATS命中都用这一规则。激光笔新增 `pointerBlockObjects=false`，Pip/F6「箱柜阻挡光束」，独立页从5项变6项；开关即时保存、默认不阻挡，旧配置缺项自然用false，其他键不重置。
- 对普通/装甲窗只按精确window1/window2身份豁免，复用MSWSmartGlass.window的只读识别。不开智能武器也生效，不按材质或可破坏性泛化。普通墙/关闭门继续按Tile截断；门已打开时不会再被过时Box矩形二次截断。无削血、破窗、削盾或箱柜破坏调用。
- 激光笔当前射线与所有帧间插值样本都收到相同开关；切换开关时不重放跨旧规则区间。光束落点用同一次碰撞结果绘制。玻璃无论开关状态都透光。已有失明不因开关改变被强制移除；阻挡后停止刷新。
- 单位首个接触、眼区、方向、天角兽护盾例外、其他护盾和计费/时间规则保持。

## 红绿与回归

基线v1.14.2：55504字节，SHA256 `C01F426A358BB995829A200854039A2E836B285B59183364B43256F104F48F81`。准确基线在8类原生Box前复现：两武器直接射击和原枪身体辅助均被挡，光束落点提前停止；结果57 PASS/34 FAIL（含缺少新开关及汇总FAIL），`build/out/laser-props/baseline/results.txt`。没有将缺少新参数的接口错误当作玩法根因。

最终准确优化产物：**55731字节**，SHA256 `3ECFA98B9E8A58E14314F1295B994F54BF5605BCCEC2F82D796CA2FAF03745F9`。40生产定义，无宿主类/探针；激光10-prop-pass、笔3-prop-switch，其他组件版本保持。冻结源码/产物在 `build/out/laser-props/candidate`。

| 同字节证据 | 结果 |
| --- | --- |
| props/results.txt | 253 PASS、0 FAIL。原生bigbox/bigbox2/box/woodbox/mcrate1/medbox/filecab/chest；枪/辅助/笔默认穿透，笔开关挡箱而不影响枪。原生window1/window2在两种开关状态透光，窗后墙/首个单位仍阻挡，door2关闭阻挡/打开通光。两枪零血量/物体生命变化；笔可见终点、SATS目标射线、扫掠及亮灯中切换即时生效。真实Pip控件、F6、保存重载配置、恢复默认通过。 |
| pointer/results.txt | 156 PASS；完整激光笔存档/comLoad、余量与40类目标、原生输入、耗电、实际Sandevistan时停及不回放。普通4.35秒耗8.660电池；时停2.15秒耗4.220；持续束227显示帧/225峰值像素。PASS行数受回放显示步数量影响。 |
| reload/results.txt | 199 PASS；原枪真实保存/读档后原生开火、正/非正面辅助与HUD、自然战斗；舞台光束13帧/476峰值像素。 |
| contact/results.txt | 93 PASS；两枪共享方向开关、普通/首领天角兽护盾例外、其他护盾及实际墙阻挡。 |
| multi/results.txt | 52项检查/53 PASS，多锁实战与原有智能武器回归。 |
| startup/install-smoke.json | 900帧、版本1.14.3，ModSettings-connected/tabOn=1；无lastErr/smartError/laserError/pointerError。 |

原有若干“墙”夹具其实是临时loc.objs矩形，旧规则恰好把它们当墙。本次将墙阻挡断言改为真实Tile夹具LaserTestWall，保留原先不能穿墙、不能转选邻居的行为检查；新专项另外覆盖原生箱柜穿透，不能只删除失败断言。

F6图 `pointer/pointer-settings.png` 已检查，六项完整显示，“箱柜阻挡光束：关”。使用独立AIR ID、隐藏窗口与测试存档；没有操作用户真实存档/配置、关闭用户游戏。经验候选与本机制不相关，全局检索部分覆盖；采用本地公共对象/窗户机制与当前原始源码。

## 安装与回滚

安装前核对正式仍为C01F426A…，备份后替换为3ECFA98B…，正式字节核对一致。回执 `build/out/laser-props/installation.json`。遵循已记用户偏好，隔离验证完成后安装只核对文件，未再次启动游戏。

回滚：退出游戏，将 `release/MoreSkillsWeaponsMod.before-v1.14.3-laser-props-20260924.swf` 复制回 `MoreSkillsWeaponsMod.swf` 并重启，恢复v1.14.2/C01F426A…；既有其他模组/配置不需替换。新版本需用户保存并重启后生效。

根pfe.swf仍为B7824465…，清单仍为3FEC194F…，没有修改本体、ModLoader或其他模组正式文件。未认证DLC、第三方新窗口类型、全部剧情/长期战斗/联机；本轮未扩大原有时停+跳弹+智能绕障三者组合承诺。
