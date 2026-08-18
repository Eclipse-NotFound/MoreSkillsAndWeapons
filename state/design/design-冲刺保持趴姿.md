# 设计：魔法冲刺保持姿态（dashKeepPose）

> 状态：**已批准并实现**（2026-08-18；用户确认：默认开、姿态动画滑行；
> 验收场景：只能蹲/趴进入的通道内滑行，玩家全程保持姿态）
> 实现：`src/MSWDashPose.as`（组件，D-037 趴姿 + D-038 蹲姿双分支）+
> `MSWConfig.dashKeepPose`（默认开）+ 设置面板第 11 行；构建产物 15329 字节。
> 需求：原版魔法冲刺（sp_kdash）在蹲下（isSit）或趴着（lurked）时施放，
> 冲刺结束时自动站起；希望冲刺期间与结束后**保持姿态**。

---

## 1. 原版机制（已逆向确认，1.02）

### 1.1 魔法冲刺技能（sp_kdash）

- 定义：`AllData.as:4012` `<item id='sp_kdash' tip='spell' ... tele='1' snd='dash'>`、
  `4021` `<weapon id='sp_kdash' tip='5' skill='7' perslvl='15' spell='1'/>`。
- 施放：玩家按法术键（keyDef / keySpell1-4）→ `UnitPlayer.control()`（2238 行）
  → `Spell.cast(cx,cy)` → `cast_kdash()`（Spell.as:335-369）。
- 前提：`loc.levitOn == true`（Location.levitOn 默认 true，仅房间 `@levitoff` 关闭，
  Location.as:484）；`control()` 门控：`work == "lurk"/"unlurk"/"res"` 时整体早退
  （UnitPlayer.as:2087-2090）→ **施放必须发生在 work=="" 的稳定趴姿期**。
- 效果（Spell.as:335-369）：
  1. 方向 = 鼠标目标 − 玩家位置；`norma(vec, speed)` 把向量钳到
     `speed = dam*(1+(power-1)*0.5)`（Obj.as:norma，只截断不放大）；
  2. `isLaz=0; levit=0;`（清梯子/悬浮状态）；
  3. `dx += dir.x; dy += dir.y;`（一次性冲量）；
  4. `kdash_t` = 帧数：`ceil(距离/速度)+1`，默认 15、最小 7（约 0.12-0.25s）；
  5. `t_levitfilter = 20`（视觉特效计时）。

### 1.2 每帧姿态状态机（UnitPlayer）

帧序（Unit.step()：forces → control → run → **actions** → animate）：

- **actions()**（UnitPlayer.as:1045-1069）：
  - 趴姿清理（1045-1058）：`if(!stay) lurked=false;`；
    `if(lurkBox && lurkBox.wall==0 && !lurkBox.stay) lurked=false;`；
    `if(work != "lurk" && |X-lurkX| > 10) lurked=false;`
    → `if(!lurked && work!="unlurk" && sloy∈{0,1}) chSloy(2);`（图层还原）
  - 冲刺计时（1065-1069）：`if(kdash_t > 0) { --kdash_t; stay = false; }`
    —— **冲刺每帧强制 stay=false**。
- **control()**（2884-2889）：`if(isSit && !stay && rat==0) unsit();` ——
  蹲姿在 stay=false 后立即站起；趴姿的解除走 actions() 清理。
- **animate()**（4195-4270 姿态分支，按优先级）：
  `t_work&&work=="lurk"` → 播放 `"lurk"+lurkTip` 趴姿动画（**注意此分支在 lurked 判断之前**，
  即 t_work>0 期间即使 lurked=false 也继续显示趴姿动画）→
  `t_work&&work=="unlurk"` → 站起动画 → `t_work&&work=="res"` → ...
  → `if(lurked)` → 仅眼睛状态（身体冻结在最后趴姿帧）→ 否则正常站/走/跳动画。
- **stay 的恢复**：`Unit.run()` 落地/贴台阶时 `stay=true`（Unit.as:2382/2429）；
  `stay=false` 时 t_stay 每帧-1（约 5 帧过渡）。

### 1.3 站起链路（bug 根因）

趴着（`lurked=true, stay=true, work=""`, 冻结趴姿帧）→ 施放冲刺：

1. 施放帧（cast_kdash）：`kdash_t = N`，冲量起飞；
2. actions()：`--kdash_t; stay = false;`（**第一帧起每帧**）；
3. 次帧 actions()：`!stay` → `lurked=false` → `chSloy(2)`；蹲姿则
   control() `isSit && !stay → unsit()`；
4. animate()：`t_work>0 && work=="lurk"` 分支仍显示趴姿动画直到 t_work 归零；
   之后 `lurked=false` → 正常站姿分支 → **站起**；
5. 冲刺结束（kdash_t==0，forces() 末帧刹车 dx/dy*=0.3）：stay 保持 false，
   落地后 `stay=true`，但 lurked 已死 → **保持站立**。

用户观察到的"结束时站起"= 趴姿动画被 t_work 延续到冲刺尾段，随后被 lurked=false 终止。

> 结论：**破坏姿势的唯一原因是 actions() 在冲刺期间每帧强制 `stay=false`**，
> 触发 lurked/isSit 清理；stay 本身在落地后会自动恢复。

---

## 2. 目标行为

- 蹲下（isSit，按 S）或趴着（lurked）时施放魔法冲刺：
  - 冲刺飞行期间保持姿态（蹲姿=polz/roll 爬行动画、趴姿=lurk 动画随冲刺滑行）；
  - 冲刺结束后**继续保持姿态**（stay 恢复、isSit/lurked 存活），可继续姿态移动
    （**验收场景：只能蹲/趴进入的通道内全程保持姿态**），W/空格 正常解除；
  - 未蹲/趴时施放：行为与现版本一致（不受影响）。
- 注：玩家实测按 S 进入的是**蹲姿 isSit**（原版蹲姿粘性：松 S 不解除，起身只走
  W/SPACE/水/梯子/rat）；lurked 趴姿需坐姿下按 W + lurk box/tile（D-038）。

---

## 3. 实现方案（模组侧，不改游戏文件）

利用既有 frame-late 挂载点（ENTER_FRAME 晚于游戏 World 帧——与跳弹同模式），
新增组件 `src/MSWDashPose.as`，开关 `dashKeepPose`（默认开）+ 面板行
（MSWPanel ROWS 11→12）。

### 3.1 触发检测（每帧）

- `gg.kdash_t` 由 0 变 >0（冲刺开始）且当时 `gg.lurked == true` 且 `work==""`
  → 进入 **dashPose 接管**，保存快照：lurkTip、sloy。
- 接管期退出条件：`kdash_t` 归 0 后（或接管期间）玩家按了解除键
  （`ctr.keyBeUp || ctr.keySit || ctr.keyJump`）→ 停止接管，交还原版。

### 3.2 接管期每帧（frame-late，游戏帧之后）

| 字段 | 强制值 | 原因 |
|---|---|---|
| `gg.stay` | `true` | 抵掉 actions() 的 `stay=false`，保 lurked 清理不触发 |
| `gg.lurked` | `true` | 直接保趴姿（防 lurkBox/stay 清理） |
| `gg.lurkX` | `= X` | 防 `work!="lurk" && \|X-lurkX\|>10` 清理（冲刺位移大） |
| `gg.lurkBox` | `null` | 冲出趴伏物后 `lurkBox.wall==0` 清理防护 |
| `gg.t_work` / `gg.work` | 冲刺期间 `t_work=20, work="lurk"` | animate() 播放完整趴姿动画（滑行）；control() 门控无妨（冲刺期本来就不可操作） |
| `gg.animState` | `"lurk"`（配合 vis.osn 复位） | 首次接管时 `vis.osn.gotoAndStop("lurk"+lurkTip)`、`vis.osn.body.gotoAndPlay(1)`，让姿态从冻结帧回到动画 |

- 冲刺结束后（kdash_t==0）：停止刷新 work/t_work（让 t_work 自然衰减回
  work="" → 身体冻结趴姿帧）；继续保 stay/lurked/lurkX 若干帧或直到玩家解除键
  —— 防"落地前 stay=false 窗口"（冲量含 dy，冲刺末可能仍在空中）。
- 所有字段经 MSWU 动态访问（`in` 探测），与既有组件一致；`lurkBox` 置空仅当
  原 lurkBox 存在且玩家已移出其范围（`|X - lurkX| > 10` 或 box 判定已死）。

### 3.3 与既有组件交互

- **MSWAim（蹲/梯举枪）**：举枪要求 `rat==0 && heldW && heldShift`，与趴姿互斥
  （lurk 时 W 是解除键）——无冲突；但注意我们接管期间 W 仍应**保留解除功能**
  （见 3.1 退出条件），勿吞 W 事件。
- **MSWProjHits/MSWSwaprun**：互不相关。
- **Sandevistan 暂停/回放**：`kdash_t` 在 onPause 冻结期不变化；接管只在
  `inGameplay(w)` 为真时激活（复用既有门控，D-033 语义）。

### 3.4 配置与诊断

- `MSWConfig`：`dashKeepPose:Boolean = true`；load/save/clamp 同步。
- `MSWPanel`：第 11 行（ROWS 11→12）"冲刺保持趴姿" 开关（哔哔小马设置页 + F6 浮层）。
- 诊断计数器：`dashPoseCast`（接管次数）、`dashPoseF`（强制帧数）、
  `dashPoseExit`（解除次数）、`dashPoseEnd`（自然结束）。

---

## 4. 风险与取舍

| # | 风险 | 说明/对策 |
|---|---|---|
| 1 | work="lurk" 接管期 control() 早退 | 仅冲刺 7-15+ 帧内，原本冲刺期也几乎不可操作（玩家在空中）；可接受。若实测需要可改为仅 t_work=1 保动画分支 |
| 2 | 冲出趴伏物（床/桌下）后"悬空趴着" | lurkBox 置空后趴姿在开阔地也成立（lurkTip 沿用）；游戏本身允许开阔地趴姿（tile lurk）。视觉/碰撞用趴姿高度，与趴伏物无关 |
| 3 | 冲刺中被敌方打死/换区/传送 | 各解除路径（die/outLoc/换区）都会走 setNull/工作状态重置，接管应在 `gg` 失效或 `inGameplay` 假时自动复位（每帧检查） |
| 4 | 蹲姿（isSit）未覆盖 | 用户只要求趴着；蹲姿冲刺同样会站起（同根因），如需要可加同一开关的 isSit 分支（+强制 isSit=true，防 unsit）——待用户确认 |
| 5 | 与手雷击落同帧时序 | 无交互，各自独立 |
| 6 | animState 被其他系统改写 | animate() 每帧重算姿态，接管期每帧重设 work/t_work 即可覆盖 |

---

## 5. 验证清单（实机）

1. 趴着施放冲刺：全程趴姿滑行，结束后保持趴着；
2. 保持趴着时按 W（keyBeUp）/空格/蹲键 → 正常解除趴姿站起；
3. 蹲着施放冲刺：行为与现版一致（站起）——除非用户要求扩展到蹲姿；
4. 站立施放冲刺：行为与现版一致；
5. 冲刺后趴着移动（方向键）：按趴姿移动规则（lurkTip 1/3 仅转身）或解除；
6. 面板开关关掉后：恢复原版行为（站起）；
7. 读 `MSWConfig.sol` 诊断计数（dashPoseCast/F/Exit/End）。

---

## 6. 已确认决策（2026-08-18 用户）

1. 范围：**蹲姿 + 趴姿都做**（实测按 S 进入的是蹲姿 isSit——D-038）。
2. 默认开关：**开**（dashKeepPose=true）。
3. 冲刺中表现：**姿态动画滑行**（蹲姿=polz/roll 爬行动画、趴姿=lurk 动画）。
4. 验收场景：在**只能蹲/趴进入的通道**内滑行，玩家角色全程保持姿态
   （冲刺穿墙 `throu`（kdash_t>3，UnitPlayer.as:2640）为原版自带，配合本组件
   的姿态保持即可穿越；`stayPhis` 仅地面类型，不影响碰撞盒）。

