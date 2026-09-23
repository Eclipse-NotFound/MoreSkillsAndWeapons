---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
date-updated: 2026-09-23
---

# 智能透窗锁定与普通窗破窗路线

用户已确认 design/smart-glass-routing.md 的完整规则。本轮只在当前模组实现、构建和隔离验证，没有安装本功能、修改游戏本体、其他模组或真实存档。

## 实现

- 新增 MSWSmartGlass：仅识别 tile.door.id 的 window1/window2。光学视线可穿过两种窗，仍遵守屏幕、隐形与目标资格；普通实墙和其他门不透明。
- 普通窗进入待破路线前检查当前弹丸的整数地形破坏值、Tile.indestruct/thre、地图 destroyOn/hp、特殊 tipDecal100 和 Box 死亡/奖品保护。装甲窗无论弹丸多强都不进入待破路线；phis=0 时按实际开口通行。
- clear/find 的可选 shot 参数传给寻路、路径压缩、近步转向和平滑预测；不传 shot 仍表示真实障碍查询。未修改 Bullet.run/popadalo/hitTile/die，破窗弹不会同发续飞。
- 同帧缓存与每发旧路线都区分 destroy/tipDecal/explRadius/destroyOn；变更能力后重新寻路，不补回制导时限。
- 爆炸弹由原生 explDestroy 对格子中心结算，因此只在爆炸半径覆盖40px格子内任何撞点到中心的距离（>sqrt(20²+20²)）时确定可破；更小半径保守绕行。该特殊半径边界由源码与规则测试确认，未声称覆盖所有爆炸弹实战。

## 冻结产物与证据

- 当前冻结源：build/out/glass-routing/src；候选 build/out/glass-routing/MoreSkillsWeaponsMod.swf，48115字节，SHA256 `AC52B1397093477FABDE8652503CF126ED4C37B47E0FC40BD3EE9D8184E3445A`。主标记沿用1.10.0-body-assist，新增 smartGlassVersion=1-windows；候选是开发产物，不能仅凭主版本号识别是否包含本功能。
- 宿主复制自实际根pfe.swf，SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`；36个生产定义，无宿主原类/Smoke/Probe混入。
- 与已安装激光5-body-assist冻结源逐文件比较，除本轮5个智能文件外其余源码相同。未吸收同期MSWPanel/MSWSettingsHub分层菜单改动；自适应半径将在另任务合并，当前验证仍是旧平滑0/50/100%。
- test-smart-unit.ps1：122条规则通过，其中新增27条玻璃规则。build/out/smart-tests/results.txt。
- 最终候选AC52B139...的准确字节已在-nodebug复验通过39项原生玻璃场景、52项多锁、124行PASS激光读档/身体辅助回归。玻璃结果build/out/glass-production-native/results.txt；多锁结果已归档build/out/glass-routing/multi-lock-results.txt；激光结果build/out/glass-routing/laser-regression/results.txt，真实未暂停光束4帧、峰值476像素。36个生产定义检查通过。
- 前一候选0536BE061E55A90F318CBE1E3443DA68F6D1A67A300C5831043541A5D950CF18也通过上述场景；最终候选仅纠正爆炸覆盖距离的保守上界并增加一条规则。源代码提交1cac284，不把前版结果冒充最终字节证据。

## 原生场景范围

独立AIR应用ID，加载优化生产SWF，-nodebug。真实Box构造与initDoor登记固定尺寸窗，原生Bullet逐步运行并调用Location.hitTile/Box.die；世界暂停以固定靶位，未替换真实碰撞，也不将这些确定性场景称作自然游玩录像。

39项覆盖：自然时钟单锁普通窗、多锁装甲窗、隐形保留；普通窗的原生停弹与后发实际扣血（平滑关闭/50/100%）；25hp窗三发破坏/第四发命中；两窗依次消耗两发；高破坏值弹仍绕未破装甲窗；已破装甲窗、零破坏弹、XML不可破坏实例和地图保护；后方实墙阻挡；同帧混合弹药缓存隔离、能力变化重算不重置预算；破窗不误生跳弹；64弹一物理步各寿命-1、路程20px。最终候选批量场景28ms仅作该测试参考，不代表日常FPS。

## 测试修正与边界

- 沙箱内AIR出现#3003、无法写出结果并超时；沙箱外相同隔离脚本正常。清理仅针对脚本创建的进程，不接触用户游戏。
- 首次锁定计时未通过：夹具设置world准星620但camera准星440，每帧相机又改回旧位置；另有自动Pip设置流程干扰。已对齐相机/世界准星并保持测试界面关闭，真实锁定计时通过。未为通过测试改变功能逻辑。
- 没有覆盖全部剧情窗变体、DLC、联机或完整时停+跳弹+绕障组合。局部寻路预算保持原有上限；没有路线仍沿用原生飞行，不保证绕过任何障碍。
- 后续自适应合入必须把shot传入其预测的clear调用；不能删除该上下文后沿用旧测试结果。SmartGlassChecks/GlassProductionSmoke里的旧平滑字段需随新模式调整并重新验证组合产物。
