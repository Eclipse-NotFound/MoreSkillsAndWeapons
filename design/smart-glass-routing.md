# 智能武器透窗锁定与玻璃路线

2026-09-23。用户反馈智能弹不把可打碎窗户作为可选路线，玩家也不能锁定窗后的敌人，并点名 grilling。本轮只读核对当前 v1.9.1 与 1.02 原版源码，未修改功能、未运行新场景、未部署。方案尚待逐题选择与整体确认。

## 用户目标与待决前沿

目标：玻璃窗后的合格敌人可以进入智能锁定，弹道规划能够考虑破窗路线。单/多锁、既有豁免、视野外保持和真实物理边界须衔接；与另一个任务的自适应半径方案并存，不在本轮擅自改其参数。

- Q1 待答：A 保留原版，撞窗那发停止并结算破坏，打碎后后续子弹可穿过（推荐）；B 智能弹打碎玻璃后同发继续飞。B 是新增穿透能力，选择后还需确认穿窗伤害/速度等后果。
- Q2 待答：A 普通窗、装甲窗都可透窗锁定；路线只把当前弹丸在当前地图规则下能够造成破坏的窗列为候选（推荐）；B 本轮仅处理普通窗，装甲窗继续沿用原判定。
- 待 Q1/Q2 后再讨论：无障碍绕路与需要破窗的较短路线如何取舍；新行为是否需要调节入口，以及所选穿透分支带来的剩余问题。未把这些建议当作用户决定。

## 静态事实

以下是源码证据，不是实际游戏场景验证。

- `src/MSWSmartWeapons.as:289` 的 visible 调用 Location.isLine，单锁与多锁都复用；`src/MSWSmartRoute.as:18` 对所有 phis==1 矩形阻挡。寻路、路径压缩、近步转向和旧平滑预测都复用 clear，因此只修改寻路入口仍可能在近窗时被避障转向排斥。
- 原版 `fe/loc/Location.as:2366–2385` 的 isLine 只判断 phis==1 物理矩形，不读透明度或材质；第五参是要忽略的 door 对象，并非通用透玻璃选项。
- 原版 `fe/AllData.as:4862–4863`：window1 普通窗为 hp10/mat5/opac0.2，window2 装甲窗为 hp1000/thre100/mat5/opac0.2。`fe/loc/Box.as:653–672` 的 initDoor 将覆盖格 phis、opac、door、mat、hp、thre 设为门窗属性；Box 默认 phis=1。应通过 tile.door 的精确 window1/window2 身份识别，不能把所有可破坏实体或某个普通地形字符直接当成窗。
- 原版 `fe/weapon/Bullet.as:476–491` 先 popadalo，再 hitTile；popadalo 最终将普通枪弹 babah=true、liv限制到4，即使同次破坏窗，后续仍停止移动。材质只改变视觉/声音等表现，没有玻璃同发击穿例外。
- Bullet.destroy 与对敌生命伤害分开，`fe/weapon/Weapon.as:156,1673` 默认地形破坏值10并赋给新弹；其他效果可修改它。不能以武器面板伤害替代破窗能力。
- `fe/loc/Tile.as:340–347` 在 indestruct 或 thre>destroy 时拒绝破坏，否则 hp-=destroy；`Location.as:2511–2517` 在 !destroyOn 且 hp>500 时拒绝地形破坏。装甲窗可能被地图规则禁止破坏。`Box.as:285–288` 的实例 indestruct 可把 hp/thre 改成10000，而不直接设置 Tile.indestruct，所以不能只查单一标志。
- 公共 `shared-knowledge/world-objects/discoveries/tile-code-table.md` 旧文将 F（40）称为玻璃，此标签不正确：AllData.as:6443 是 Рухлядь（杂木/破烂）、mat3；窗为上述 mat5 的 Box。实现不得沿用该误标。

源码路径均相对 `game-reference/decompiled/1.02/src102/scripts`。实际安装宿主包含后续 loader 更新；实施时仍需以隔离的当前宿主验证普通窗、装甲窗、不可破坏实例、实墙与真实原生子弹，并保留其他同期功能。
