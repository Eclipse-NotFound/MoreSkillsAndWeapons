# 新技能：蹲姿/梯子举枪（已实施）

> 状态：**已实施**（2026-08-17，`src/MSWAim.as` + 入口接线 + 面板第 6 行开关）。
> 机制探索与方案见下文；实施决策见 `decisions/decisions.md` D-026。
> **2026-08-17 改键**：举枪 = **Shift+W**（D-031），W 恢复原版语义
> （坐姿起身 / 梯子爬升），不再拦截单独的 W。

---

## 1. 需求

- 现有行为（原版）：
  - 站立：按住 W（`keyBeUp`）约 10 帧以上 → `weapUp`（举枪，武器位置抬高 40px）；
  - 坐下/蹲姿（`isSit`）：按 W → `unsit()`（起身）；
  - 梯子（`isLaz != 0`）：按 W → 向上爬（`checkStairs()` → `dy = -lazSpeed`）。
- 目标：**在坐下/梯子两种状态下也能"举枪"**（瞄准姿态 + 抬高的枪口），
  触发键 = **Shift+W**；起身/爬梯保持原版 W 路径（用户使用习惯）。

## 2. 已确认的机制事实（来源：反编译源码）

### 2.1 按键
- `Ctr` 键表：`keyBeUp = Keyboard.W`、`keySit = Keyboard.S`、
  `keyJump = Keyboard.SPACE`、`keyRun = Keyboard.SHIFT`（Ctr.as:16-25）。
- `keyBeUp/keySit/keyJump/keyRun` 均为 **public** 布尔（Ctr.as:93-101）。

### 2.2 举枪（weapUp）
- `UnitPlayer.weapUp`：**internal**（UnitPlayer.as:97）——模组**不能**直接写。
- 判定（UnitPlayer.control，~2893-2905）：
  ```
  weapUp = false;
  if(stay && ctr.keyBeUp && rat == 0) {
     if(isSit) t_up = 10;
     ++t_up;
     if(t_up > 10) weapUp = true;
  }
  else { if(t_up>0 && t_up<=7) lurk();  /* 掩体短按 */  ... }
  ```
- 效果（UnitPlayer.setWeaponPos ~3544-3549）：`if(stay && weapUp)`
  且上方 40px 处 tile 非实心 → `weaponY -= 40`——**举枪的全部效果 = 武器
  基准点上移 40px**，武器视觉随之、枪口（`getBulXY` 读 `vis.emit` 的世界
  坐标，Weapon.as）随之抬高 → 可越过低矮掩体射击。

### 2.3 坐下（isSit，public，Unit.as:282）
- `sit(b)`（public）：纯状态切换（isSit + scX/scY + 碰撞边界），无计时器；
- `unsit()`（public）：`sit(false)`，若 `collisionAll()` 则 `sit(true)` 回退；
- W 起身路径（UnitPlayer.as:2884）：`if(isSit && keyBeUp && !keySit && rat==0) unsit();`
- **空格起身路径（原生）**：`jumpp > 0 → if(isSit) unsit()`（~2702-2706）
  ——起身不需要 W，SPACE 原生即可。

### 2.4 梯子（isLaz，public，Unit.as:290）
- 上梯（Unit.checkStairs）：`isLaz = storona = tile.stair; stay = false; sit(false);`
  ——**梯子上 stay 恒为 false** → 原版 weapUp 块（要求 stay）在梯子上不可能成立；
- 爬升（UnitPlayer.as:2931）：`!isSit && !isFly && keyBeUp && ... && !noStairs
  → checkStairs() → dy = -lazSpeed`；
- 爬降：keySit 块（~2838）`isLaz && !noStairs → checkStairs(2) → dy = +lazSpeed*1.5`；
- 脱离：`runForever>0 || (keyJump && !keyBeUp) || loc.quake>5 → isLaz = 0`
  ——注意：按住 W 时 SPACE 不能脱离（keyBeUp 为真），松开 W 再跳即可；
- **`noStairs`：public**（UnitPlayer.as:47）——置 true 同时禁掉爬升与爬降判定。

### 2.5 枪口
- `Weapon.getBulXY()`：优先取 `vis.emit`（武器贴图内的枪口 MovieClip）的
  世界坐标——**抬武器贴图 = 抬枪口**，子弹出生点随之抬高（射击判定的
  基准在视觉位置）。模组帧后改写 `weapon.vis.y` 可直接抬高贴图与枪口
  （同 SATS 弹道/榴弹翻滚的帧后覆写模式）。

## 3. 方案（推荐）

统一采用"**模组帧后驱动 + 最小拦截**"，不修改游戏文件，不动 stay/isSit：

### 3.1 状态跟踪（模组内）
- KEY_DOWN/KEY_UP 跟踪 `heldW`（keyCode 87）与 `heldShift`（keyCode 16）；
- 每帧（游戏 step 之后）计算目标状态：
  `aimSit = heldW && heldShift && gg.isSit && gg.ggControl && gg.rat==0`；
  `aimLaz = heldW && heldShift && gg.isLaz!=0 && gg.ggControl && gg.rat==0`。
- **举枪统一 = Shift+W**；单独的 W 不进入本技能任何分支（原版起身/爬升）。

### 3.2 坐下 + 举枪（Shift+W）
- **拦截 W**：`aimSit` 时在 KEY_DOWN 层 `stopImmediatePropagation` 吞掉 W
  （判定用 `e.shiftKey`，见 D-031）→ `ctr.keyBeUp` 不置位 → 原版 `unsit()`
  不触发（玩家保持坐姿）；帧内三保险 + 恢复兜底（D-027~D-030）原样保留；
- **抬枪**：每帧把 `gg.currentWeapon.vis.y` 抬高 40px（复刻 setWeaponPos 的
  条件：武器上方 40px 处 tile 非实心才抬）。枪口（vis.emit）随之抬高，
  射击命中/子弹出生点自动上移——**完整"举枪"效果，纯模组侧实现**；
- **起身**：松开 Shift（或 W）即退出瞄准 → 按 W = 原版 unsit；SPACE 原生
  `jumpp → unsit` 也可起身；
- 松开 Shift/W → 恢复 vis.y，回到正常坐姿。
- 副作用检查：坐姿下 W 的原功能只有 unsit（坐姿不能移动），Shift+W 时
  吞掉无损失；`t_up`/lurk 短按逻辑与坐姿无关。

### 3.3 梯子 + 举枪（Shift+W）
- **不吞 W**（梯子姿态还依赖 keyBeUp 的其他语义，保持原生）；
- `aimLaz` 时置 `gg.noStairs = true` → 原版爬升判定被禁用（玩家停在梯子上）；
  同时帧后抬高 `currentWeapon.vis.y`（同上）→ 视觉 + 枪口双抬；
- **向上爬**：单独的 W（非 Shift，noStairs 不置 → 原生爬升）；
- **向下爬**：S（原生，仅未瞄准时——瞄准中 noStairs=true 会禁掉爬降，
  松开 W 即可爬降，可接受并在面板提示中说明）；
- **脱离梯子**：松开 W 后 SPACE（原生）。
- 副作用检查：noStairs 还出现在 keySit 的 stair 判定里（坐/降判定），
  瞄准期间玩家挂在梯子上不落地，无其他影响；`stay=false`（梯子）不影响
  模组方案（weapUp 不可用，但我们不依赖它）。

### 3.4 设置与技能化
- 设置面板新增第 6 行：**"蹲/梯举枪" 开关**（默认关，独立开关，
  与"跳弹技能"同模式；游戏技能系统适配后置）。
- 关闭时完全不拦截任何键。

## 4. 待验证问题（实施前逐一确认）
1. **坐姿能否开火**：攻击块（UnitPlayer.control ~2318）未见 isSit 条件，但
   `atkPoss` 是否在坐姿为 false 需确认——若坐姿禁止开火，需同步放开
   （或在文档中明确"举枪仅姿态"）。
2. `currentWeapon.vis` 在武器切换动画（work="change"）期间的抬升表现。
3. 梯子朝向（isLaz=±1）与举起武器的视觉朝向（storona）关系——贴图翻转。
4. lurk（掩体）姿态是否也要纳入"举枪"（用户表述"趴着"可能含 lurk；
   v1 先只做 isSit，lurk 作为扩展）。
5. `t_up` 与抬枪的视觉衔接：原版站立举枪有 10 帧阈值渐入，模组驱动为
   瞬时抬起——可接受（或加 3-5 帧渐变）。

## 5. 风险与边界
- vis.y 抬升是纯视觉+枪口基准：武器**逻辑**位置不变（碰撞、拾取等不受影响）；
- 魔法武器（tip==5）在 magicX/magicY 体系下——v1 只对枪械（tip!=5）生效；
- 变身（rat==1）跳过（原版同样跳过）；
- 与其他模组的键位冲突：只使用 W/Shift/S/SPACE 的既有语义，无新增热键。

## 6. 实施步骤（待用户批准后执行）
1. MSWConfig/MSWPanel 新增开关行（第 6 行）；
2. MSWMod：heldW/heldShift 跟踪 + KEY_DOWN 拦截（仅 aimSit）；
3. 新类 MSWAim：帧后状态机（aimSit/aimLaz）+ vis.y 抬升 + noStairs 管理；
4. 实测：坐姿举枪射击越障、梯子举枪/爬升/爬降/脱离、开关切换；
5. 按 shared-knowledge 规则把坐姿/梯子/举枪机制提炼为公共知识
   （weapUp internal + weaponY-40、getBulXY→vis.emit、noStairs 语义等）。
