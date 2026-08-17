# 功能设计：跳弹 + 可编程榴弹炮

> 本文档描述模组功能设计。实现依赖的机制级清单见 `design/mechanics-notes.md`；
> 面向跨模组的公共知识按 `shared-knowledge/README.md` 另行贡献。

---

## 1. 总体

模组包含两项功能、一个设置面板、一个自定义 SATS 弹道覆盖层：

| 组件 | 说明 |
| --- | --- |
| 跳弹技能（独立开关） | 玩家枪械子弹首次撞墙按镜面反射反弹一次 |
| 可编程榴弹炮 | 新武器 `mswglau`（数值/贴图照搬 `glau`），下坠速率与爆炸前撞墙次数可调 |
| SATS 弹道覆盖层 | 可编程榴弹炮的 SATS 弹道按当前设置实时绘制（含弹跳预览） |
| 设置面板 | 热键（默认 F8）开关；方向键调参；SharedObject 持久化 |

---

## 2. 跳弹技能

### 2.1 适用范围

- 仅玩家（`owner.player`）发射的 `Bullet`，且：
  - `explRadius == 0`（非爆炸弹；爆炸弹撞墙即爆，无弹跳语义）
  - `brakeR == 0`（排除火焰/照明弹类，其有自带下坠与减速）
  - `tipDamage == 0`（D_BUL 枪弹；激光/等离子/火焰等能量类不参与）
- 每个原始子弹**只在第一次撞墙时反弹**；反弹后的子弹再撞墙按原版死亡。

### 2.2 实现路径（respawn 方案）

引擎对 `Bullet` 无弹跳路径（`Bullet.run()` 撞墙固定 `popadalo()` → `babah=true`，
`liv=4`，死亡）。无法 hook 密封类原型，因此采用**帧后重生**：

1. 模组每帧（晚于游戏 step）扫描 `loc.firstObj` 链，登记玩家飞行子弹
   （`!babah && !in_chain 检查 + 死亡判定`），记录上一帧位置与朝向。
   注：子弹在出生帧内就会完成首次 step 并可撞墙死亡（高速弹一步可达 vel 像素）。
   对这类"无历史位置"的死亡：**不猜测反弹面**——跳弹按原版消亡、榴弹直接
   引爆（D-019：猜测必然偶发错误反弹，宁可放弃贴墙 ~vel 像素内的反弹覆盖）。
2. 检测到"撞墙死亡"（`babah==true` 且死亡点 tile `phis==1` 且落在
   `phX1..phX2/phY1..phY2` 内）后：
   - **墙壁被破坏则不反弹**（用户指定特殊情况）：
     死亡后 `loc.getAbsTile(X,Y).phis == 0`（`hitTile` 已把墙打穿）→ 不重生，子弹按原版消亡。
     门（`Tile.door` Box）同理由 `hitTile → door.die()` 走同一 tile 路径，phis 归零即覆盖。
   - 墙壁完好：按进入面做**镜面反射**，重生等参数的新 `Bullet`：
     - 方向：`dx/dy` 对应分量取反（矩形边界反射，过冲量镜像回弹）；
     - 出生点：反射后方向偏移出矩形外（避免重生子弹自身再次触墙）；
     - 视觉：复用原子弹 `vis.constructor` 类（同贴图/混合模式）；
     - 战斗字段：`damage/pier/tipDamage/tipDecal/armorMult/crit*/destroy/
       precision/antiprec/probiv/spring/flare/weap/weapId/miss/desintegr` 等全部拷贝；
     - `liv=100`（与原版枪弹一致，不因反弹扣减射程）、`tilehit=false`（可再次触墙）、
       `dist` 保持原值累积。
   - 反弹后的子弹标记为"已弹跳"，不再参与跳弹。
3. 死亡原因分类（用于可编程榴弹炮，见 §3）：墙 / 单位 / 超时（liv 归零）。

### 2.3 独立开关

- 配置项 `ricochet`（默认 `false`）。后续再适配游戏技能系统（`Pers`/perk），
  届时开关语义不变、由 perk 状态联动。

---

## 3. 可编程榴弹炮（`mswglau`）

### 3.1 武器定义

- 运行时向 `AllData.d`（public static 可变 XML）追加 `<weapon id='mswglau'>` 节点，
  内容从 `glau` 节点克隆并替换 id：
  - `<char maxhp='100' damexpl='120' damage='0' rapid='25' prec='6' crit='0'
     tipdam='4' knock='50' destroy='600' expl='150'/>`
  - `<phis speed='35' grav='1' grav2='0' drot='8' deviation='8' recoil='5'
     massa='10' m='2'/>`
  - `<vis vweap='visglau' tipdec='9' vbul='gren40' spring='0'/>`
    （`vweap` 强制手持贴图 = 榴弹发射器；如需“末日”外观可换 `visglau_1`）
  - `<snd shoot='glau_s' reload='flamer_r' noise='800'/>`
  - `<sats noperc='1' cons='32'/>`（与原版一致，SATS 消耗/隐藏百分比）
  - `<ammo holder='6' reload='60'/>` + `<a>gren40</a>`（与原版共用 40mm 榴弹）
- 创建走游戏原厂路径：`Invent.addWeapon('mswglau')` → `Weapon.create`，
  存档/读档、HUD、快捷栏、修理等全部兼容（存档只存 id，读档时节点已由模组注入）。
- 显示名：原版 `nazv` 从翻译表 `Res.txt("w", id)` 取，新 id 无译文 → 模组在创建后
  直接写 `weapon.nazv = "可编程榴弹炮"`（每次会话对实例重写，防御读档重建）。

### 3.2 下坠速率

- 游戏公式：`shoot()` 中 `b.ddy += World.ddy(=1) * weapon.grav`。
- 模组每帧对 `invent.weapons['mswglau']` 实例写 `weapon.grav = cfg.dropRate`
  （public 字段，开火时读取）→ **实时生效**，无需改子弹。
- 范围 `0.0 .. 3.0`，步长 0.1，默认 1.0（= 原版）。

### 3.3 爆炸前撞墙次数（`wallHits`）与反弹物理

- 语义：`wallHits = N` 表示榴弹在墙上弹跳 N 次、第 N+1 次触墙（或命中单位/引信
  超时）爆炸。`N=0` = 原版行为（首次触墙即爆）。
- 实现：
  - `wallHits > 0` 时，每帧把武器实例的 `explRadius` 置 0（public 字段，
    `shoot()→setBullet()` 会读它写入子弹）→ 子弹飞行中**不带爆炸半径**：
    撞墙不再自爆（`popadalo` 走无声死亡路径），撞击墙壁的 `hitTile(destroy)`
    破坏效果由原版路径保留。
  - 模组侧给该武器注册 `origExplRadius`（首次见到时从实例读取保存，之后实例被置 0）。
  - 飞行子弹死亡时（帧后检测）分类处理：
    - **撞墙且墙未被破坏**：剩余弹跳 `>0` → 按手雷物理反弹（见下）；
      剩余弹跳 `==0` → 在撞击点爆炸。
    - **撞墙且墙被破坏**：不弹跳，立即在撞击点爆炸（与"破坏墙的那发不该弹跳"一致，
      同时保持原版"撞墙即爆"语义）。
    - **命中单位 / liv 引信超时**：在死亡点爆炸（原版语义）。
  - 爆炸方式：在撞击点创建不可见 `Bullet`（`param4=null`）并调用其 public
    `explosion()`（复刻 iExpl 但保留原 otbros）→ 走原版 `explRun()` 全流程；
    随后 `liv=1` 让其下一步自行出链。
  - `wallHits == 0`：不置 0 `explRadius`，不追踪爆炸（完全原版路径）。

### 3.3.1 反弹物理（对齐原版手雷 PhisBullet，玩家要求）

- 弹性 `skok=0.4`（X 面与天花板）；砸地 `tormoz=0.7` 水平减速；
  `|dy|<=2` 时**落地即爆**（爆炸点 = 地面上方贴图半高处；原"静止等引信"
  被玩家判定为"爆炸不及时"，已取消静止状态）。
- 角点同时穿越两面：跟随原版 PhisBullet 的判定顺序（X 先判、位置移出后
  Y 不再触发）**只弹 X 轴**，避免"原路反弹"观感。
- 反弹/落点定位按**贴图半宽/半高**放在碰撞体外侧（贴图中心为注册点，
  避免"陷进地里"）；贴地图边界墙时重生点钳制后仍在矩形内 → 直接引爆/消亡
  （防循环）。
- 视觉：翻滚动画 `vis.rotation += dr`（dr=dx，模组帧后覆写游戏同步）。
- 音效：每次反弹 `Snd.ps("fall_grenade", X, Y, 0, |dx|/10)`（与原版手雷一致）。
- 引信：重生弹 `liv` 延续（tracker 逐帧记录 `livLeft`），总飞行时间与原版
  子弹一致（≈100 世界步），不会无限弹跳。
- 跳弹技能（ric）保持镜面反射（光线反射定律），不受此影响。

### 3.4 SATS 弹道覆盖层

- 原版 `Weapon.setTrass()` 只判断 `grav>0` 就加固定 `World.ddy`（**不乘 grav 值**），
  无法表达自定义下坠；`Trasser` 只有投掷武器（WThrow）走 `is_skok` 弹跳。
- 方案：给 `mswglau` 实例置 `weapon.noTrass = true`（public），SATS 激活时游戏
  不再绘制内建弹道；模组在 `World.w.vsats` 容器内挂自己的 MovieClip，
  每帧（含设置实时变更）重绘：
  - 模拟起点 = 武器 `X/Y`；初速方向 = atan2(celY-Y, celX-X)；`vel = speed*speedMult`；
    `ddy = cfg.dropRate * World.ddy`；子步 `maxdelta=9`；
  - 撞墙判定同 `Trasser.run`（`phis==1` 矩形），弹跳按 §3.3.1 手雷物理
    （弹性 0.4/落地摩擦 0.7/落地静止即终点），弹跳 `wallHits` 次，
    终点击中墙（或到达 100 步引信/落地静止）后停止；
  - 终点画爆炸半径圈（`origExplRadius/100` 缩放，与原版手雷 SATS 的
    爆炸范围显示同款）。
  - 隐藏原版 `sats.trasser` 与 `sats.radius`（public 字段）避免残留。
- 非 `mswglau` 武器不受影响；武器切换后恢复原版绘制。

---

## 4. 设置面板（集成进游戏自带设置页）

- **主入口：哔哔小马（PipBuck）设置页**（用户 2026-08-15 指示）：
  - 检测：`pip.active && getQualifiedClassName(pip.currentPage) == "fe.inter::PipPageOpt"`
    （`currentPage` public；`page2` internal 不可读 → 不区分子页，面板显示在该页
    所有子页的顶部横幅区，该区域 `statHead` 恒隐藏、空闲）。
  - 宿主：`World.w.vpip`（public）内 (185,80)（页面 vis 位于 vpip 内 (165,72)）。
  - 按键：↑↓ 选行、←→/Enter 调整；设置页 UI 纯鼠标驱动，无键盘冲突；
    "按键绑定"对话框（visSetKey）显示期间不消费按键（显示树扫描检测）。
  - 设置页打开时 F8 被忽略（避免两层面板叠加）。
- **辅入口：F6 浮层**（挂在 `World.w.main`）——仅 F6（历史：F10 与其他模组
  热键冲突、F8 在该键盘上无键事件；诊断 hk117=9 证明 F6 稳定到达，D-019）；
  浮层打开时 Esc/F6 关闭，吞掉游戏操作键防误操作。
- 持久化：`SharedObject("MSWConfig")`，变更即存；另写诊断计数器
  （booted/frames/keys/hk<code>/pip/world/lastErr）便于排查。
- 内容：跳弹技能开关 / 下坠速率（0~3，步长 0.1）/ 撞墙次数（0~5）/
  初速度（10~100，=weapon.speed 炮口初速度，原版 35）。

## 4.1 F8 问题的排查结论（2026-08-15）
- 玩家存档 `PFEgame0.sol`（18:09）含 `mswglau`×1 + `gren40`×3 → 模组已加载、
  AllData 注入与发枪均正常；仅"F8→浮层"路径失效（根因未定：可能被其他模组的
  stage 键盘监听先行拦截；已加诊断计数器待实测确认）。哔哔小马设置页集成后
  该路径不再是唯一入口。

## 5. 武器发放

- 每个会话在进入场景后（`loc.active` 且 `gg.invent.weapons` 就绪）：
  `invent.weapons['mswglau']` 不存在 → `addWeapon('mswglau')` 并
  `plusItem('gren40', 12)`（仅首次；此后由存档持久化，不重复发弹药）。

## 6. 不做的事（当前版本）

- 不接入游戏技能/Perk 系统（用户明确：延缓适配，独立开关先行）。
- 不修改任何游戏原始文件、不读取其他模组。
- 不处理非玩家子弹（敌方榴弹等保持原版）。
