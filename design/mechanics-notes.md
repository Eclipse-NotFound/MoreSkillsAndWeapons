# 机制笔记（模组内部，实现依赖清单）

> 本文件记录模组代码依赖的游戏机制与字段，含出处 symbol，便于维护与复查。
> 面向跨模组可复用的结论按 `shared-knowledge/README.md` 评估后另行贡献。
> 版本：game 1.02（`game-reference/decompiled/1.02/src102`）。

## 1. 子弹（fe.weapon::Bullet）

- `step()`（Bullet.as:170）：每世界步 `dy+=ddy; dx+=ddx`；位移超过
  `World.maxdelta(=9)` 时按子步多次调用 `run(k)`；`liv` 逐步递减；
  `liv<=0 && explRadius>0` → `explosion()`；`liv<=0||换loc` → `vse→remObj` 出链。
- `run()`（Bullet.as:411）：
  - 撞墙判定（Bullet.as:476）：`!tilehit && tile=loc.getAbsTile(X,Y)` 且
    `(phis==1 || phis==2 且仍在出生 tile)` 且 `X∈[phX1,phX2] && Y∈[phY1,phY2]` →
    `popadalo(mat)` + `weap.crash()` + `owner.crash(this)`；
    `explRadius==0` 时额外 `loc.hitTile(tile, destroy, X, Y, tipDecal)`（破墙）。
  - 单位命中：`udarBullet(b)` 返回 ≥0 → `popadalo(ret)` → babah 死亡。
  - Box 命中路径需要 `this.crack>0`（游戏未设置 crack，实际为死路径）。
- `popadalo(mat)`（Bullet.as:324）：`explRadius>0` → `explosion()`；
  否则按 `tipDecal` 出火花/无效果；最终 `babah=true; liv=4` → 下一步出链。
- `explosion()`（Bullet.as:666）：首行 `if(isExpl) return`；`isExpl=true`；
  `inWall` 按当前 tile 矩形重算；`explRun()`。
- `iExpl(damage, destroy, radius)`（Bullet.as:695）：public；置 D_EXPL/otbros=10/
  damageExpl/destroy/explRadius 并立即 `explosion()` —— 模组手动引爆入口。
- 关键 public 字段：X/Y/dx/dy/vel/rot/liv/babah/tilehit/inWall/in_chain(继承 Pt)/
  vis/weap/weapId/owner/tipDamage/tipDecal/damage/damageExpl/destroy/explRadius/
  explTip/explKol/explPeriod/expl_t(public 读)/pier/armorMult/precision/antiprec/
  critCh/critDamMult/critInvis/miss/probiv/spring/flare/desintegr/brakeR/ddy/ddx/
  dist/off/celX/celY/targetObj/damage…（构造 public：`Bullet(owner,x,y,visClass,addObj)`）。
- 常量：`Unit.D_BUL=0`，`D_EXPL=4`（Unit.as:28-70）。
- `liv` 由武器 shoot 时通常不设置（默认 100；火焰弹 brakeR/7 例外）。

## 2. 武器（fe.weapon::Weapon）

- `shoot()`（Weapon.as:~1450）：
  - 弹速 `b.vel = speed*speedMult`；方向 `b.rot`；`b.dx=cos(rot)*vel`；
  - `grav>0` → `b.ddy += World.ddy(=1) * this.grav; b.vRot=true`（下坠公式）。
  - `setBullet(b)`：tipDamage/tipDecal/otbros/pier/armorMult/destroy/precision/
    explTip/`explRadius = this.explRadius * this.explRadMult`/explKol/spring/flare/probiv…
- 关键 public 字段：`grav`（下坠系数，public，开火时读）、`explRadius`、
  `noTrass`、`noSats`、`noPerc`、`satsQue/satsCons`、`id`、`nazv`、`tip`、`cat`、
  `skill`、`speed`、`speedMult`、`vBullet`、`damageExpl`、`destroy`、`X/Y/rot`、
  `owner`、`hold/holder`、`ready`。
- `Weapon.create(owner,id,variant)`：public static 工厂；从
  `AllData.d.weapon.(@id==id)` 取节点，tip 决定子类（tip=3 → Weapon）。
- `getXmlParam()`（Weapon.as:401）：解析节点；`nazv = Res.txt("w", id)`（翻译表，
  新 id 无译文）；`svis="vis"+id`，`<vis @vweap>` 可强制视觉类名；
  `vBullet = getDefinitionByName("visbul"+visbul)`；`flare` 默认取 `visbul`。
- `setTrass()`（Weapon.as:1641）：SATS 弹道初值；`if(this.grav) trasser.ddy +=
  World.ddy` —— **只判非零，不乘 grav 值**（自定义下坠必须自绘）。

## 3. SATS（fe.inter::Sats / Trasser）

- `Sats.trass()`（Sats.as:547）：`if(weapon.noTrass) return;` →
  `weapon.setTrass(trasser.graphics)`；`weapon.explRadius>0` 时画半径圈
  `radius`（scale=explRadius/100，位置=trasser 终点）。
- `Sats` public 字段：`active/vis/trasser/radius/weapon/gg/que/units/od`。
- `Trasser.trass()`：100 步模拟；子步 maxdelta；撞墙（phis==1 矩形）终止；
  `is_skok`（internal）弹跳仅供 WThrow 使用。模组自绘弧线需复刻其判定。
- SATS 触发键：`ctr.keySats`（World.as:1380 `sats.onoff()`）；开火仍走武器
  `attack()→shoot()`（读当前 `grav`）。

## 4. 数据与工厂

- `AllData.d`：public static **可变 XML**（AllData.as:6）。运行时 appendChild
  新 `<weapon>` 节点即生效于后续 `Weapon.create`。
- `glau` 节点（AllData.as:3302-3314）：
  `<char maxhp='100' damexpl='120' damage='0' rapid='25' prec='6' crit='0'
   tipdam='4' knock='50' destroy='600' expl='150'/>`；
  `<phis speed='35' grav='1' .../>`；`<vis tipdec='9' vbul='gren40' spring='0'/>`；
  `<sats noperc='1' cons='32'/>`；`<ammo holder='6' reload='60'/>`；`<a>gren40</a>`。
  `glau^1`（“末日”）为独有变体，其视觉类名 `visglau_1`（sprite 资源存在）。
- `Invent.addWeapon(id,...)`（Invent.as:760）：已存在则 repair 返回；否则
  `Weapon.create` 入库。`Invent.plusItem(id,kol)` 给物品/弹药。
  `invent.weapons` 为 id 键字典；`items` 亦 id 键。
- 伤害类型常量见 Unit.as:28-70。

## 5. 世界与图层

- `World.w` public static；`w.loc`、`w.gg`（玩家）、`w.sats`、`w.grafon`、
  `w.celX/celY`（鼠标世界坐标）、`w.main`（顶层 Sprite）、`w.vsats`（SATS 视觉容器）、
  `w.gui`、`w.ctr`、`w.pers`。
- `Location`：`firstObj`（Pt 链，含武器/子弹/粒子）、`units`、`getAbsTile(x,y)`
  （public）、`spaceX/spaceY`、`destroyOn`（默认 true）、`active`、`hitTile`。
- `Tile`：`phis/phX1..phY2/hp/indestruct/thre/door/mat`；`Tile.udar(d)` 减 hp；
  hp≤0 → `die()`（phis 归零/门联动）——"墙被破坏"判定 = 撞击后 `phis==0`。
- 图层（shared-knowledge visobj-layer-system）：武器/单位 sloy=2、特效 3、UI 4/5。
  SATS 标记 SatsCel sloy=5。自绘弹道挂 `w.vsats` 内即可与 SATS 视觉同变换。
- 事件时序（shared-knowledge input-system）：游戏 ENTER_FRAME 先于模组；
  模组 KEY_DOWN 先于游戏 Ctr —— 面板键用 KEY_DOWN + stopImmediatePropagation。

## 6. 模组加载（已从 pfe.swf 二进制证实）

- 补丁后 MainFE 内 `MainFE.as$167` 区块：`Loader + 子 ApplicationDomain` 加载
  `app:/mods/Sandevistan/release/SandevistanMod.swf`，成功后调用文档类的
  `init(...)`（"SandyMod: init returned"）。加载路径**每模组硬编码**——
  本模组需要 pfe.swf 再追加一段 loader 才能进游戏（越权事项，待用户授权，
  见 state/current-status.md）。
- 模组文档类需提供 `public function init(main:*)`；`main.stage` 注册
  ENTER_FRAME/KEY_DOWN。
