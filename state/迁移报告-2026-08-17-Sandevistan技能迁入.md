# 迁移报告：Sandevistan → MoreSkills&Weapons

## 疾跑中切枪（swaprun）+ 手雷击落（projhits）

> 交付方：Sandevistan 模组开发者
> 接收方：MoreSkills&Weapons 开发者
> 日期：2026-08-17
> 状态：**已完成迁移并构建部署，待实机复测**
>
> 技术细节文档：`state/MIGRATION-Sandevistan-swaprun-projhits.md`
> 源实现备份：`mods/Sandevistan/state/migration-backup-v1.126/`
> （`SandevistanMod.as.bak.v1.126` = 迁移前完整源码，git v1.126 = `bc4a9b9`）

---

## 1. 背景与目标

用户要求将 Sandevistan 模组的两个技能**迁入本模组（MoreSkills&Weapons）**，
并明确约束（2026-08-17 对话确认）：

1. **不改变技能的实现逻辑**（碰撞/血量/护甲/引爆、事件层拦截等行为一致）；
2. **Sandevistan 侧停用**，源码保留作备份——**游戏实际加载 = 本模组的实现**；
3. 尽量使斯安维斯坦模组**适配**迁移后的手雷击落（共存不冲突）。

结论：两个技能的实际运行实现已迁入本模组（新建组件 + SharedObject 配置 +
设置面板），Sandevistan 已发布 v1.127 停用对应逻辑（其回放系统经适配后无回归）。

---

## 2. 迁移内容总览

| 技能 | 源实现（Sandevistan） | 迁入组件（本模组） | 默认值 |
|---|---|---|---|
| 手雷击落（投掷物可击落） | `stepProjHits()`，v1.83 起（v1.92 扫掠碰撞 / v1.114 按武器覆盖） | `src/MSWProjHits.as` | 开；projHp=30、projArmor=0 |
| 疾跑中切枪 | `onKey()` 内 swaprun 拦截，v1.100 起（v1.104 改事件层） | `src/MSWSwaprun.as` | 开（疾跑按住 Shift 时数字键切第一组快捷槽） |

**未迁移**：手雷击落在 Sandevistan 中的"时停/回放"分支（`projBoom` 重演、
`origDam` 恢复、`seenAtk` 追踪器）——它们依赖斯安维斯坦的时停回放系统，
本模组无此系统，无法承载；该部分逻辑继续由 Sandevistan 自身维护（已适配为
独立于击落开关的 `replayProjBoom()`）。

---

## 3. 变更文件清单

### 3.1 本模组（MoreSkills&Weapons）——6 个源文件 + 1 个构建产物

| 文件 | 变更 | 说明 |
|---|---|---|
| `src/MSWU.as` | 修改（+约 25 行） | 新增静态助手 `inGameplay(w)`：可操作状态判定（`allStat`/gg/loc/onConsol/pip/sats/stand/guiPause + **`onPause`**），供两个新组件复用 |
| `src/MSWConfig.as` | 修改 | 新增 `projHits`/`projHp`/`projArmor`/`projHpOver`/`projArmorOver`/`swapRun` 六个字段；load/save/clamp 同步（SharedObject 持久化） |
| `src/MSWPanel.as` | 修改 | 设置行 6→10（`ROWS=10`）：新增 `手雷击落`(开关)、`投掷物血量`(±5)、`投掷物护甲`(±5)、`疾跑切枪`(开关)；哔哔小马设置页与 F6 浮层同步生效 |
| `src/MSWProjHits.as` | **新建** | 手雷击落核心（§4.1） |
| `src/MSWSwaprun.as` | **新建** | 疾跑切枪核心（§4.2） |
| `src/MoreSkillsWeaponsMod.as` | 修改 | 新增 `projhits`/`swaprun` 组件成员并接线：`onFrame` 增加 `projhits.process(w)`；`onKeyDown` 在面板/浮层处理之后、F6 热键之前调用 `swaprun.intercept(e, world)` |
| `release/MoreSkillsWeaponsMod.swf` | **重建产物** | 11864 → 14348 字节（swf v14，仅字符串引用游戏类，无嵌入） |

### 3.2 Sandevistan 侧（供知悉，非本模组文件）

- `mods/Sandevistan/src/SandevistanMod.as`（v1.127，git `ef43bae`）：
  - `cfgProjHits`/`cfgSwapRun` 默认改 `false`；
  - config.txt 解析分支（`projhits`/`projhp`/`projarmor`/`projhp_<id>`/`projarmor_<id>`/`swaprun`）、
    PipPageOpt 设置面板两行、saveConfigFile 回写**全部移除**（已有 config 无法再开启）；
  - **适配**：`stepProjHits` 的回放重演分支抽成 `replayProjBoom()`，脱离
    `cfgProjHits` 门控——斯安维斯坦回放系统对"时停中自然爆炸"的重演不受影响；
  - 完整源码备份：`mods/Sandevistan/state/migration-backup-v1.126/`。

---

## 4. 实现逻辑（与原版一致，未改动）

### 4.1 手雷击落（MSWProjHits）—— 原 `stepProjHits()` 常规模式

每帧（游戏 step 之后）：
1. 扫描 `loc.firstObj` 链分类：
   - **可击落投掷物** = `PhisBullet`/`SmartBullet`/`Bullet` 且 `explRadius>0` 且 `!isExpl`
     （普通枪弹/天角兽闪电 explRadius=0 不参与）；
   - **攻击体** = 其它 `fe.weapon::*` 且 `vel>=1`（近战 vel=0 不参与，v1.90）。
2. 双重判定 `p(投掷物)×b(攻击体)`：
   - `b==p` 跳过（v1.92 自测防护）；
   - 同源且投掷物距其 owner <200px 跳过（v1.91 出生护手，防贴脸自爆）；
   - **相对速度扫掠碰撞**（v1.92）：`R(t)=O+t·RV, t∈[0,1]` 钳制，最近点 ≤28px 命中；
   - 命中 → `loc.remObj(b)`（子弹弹出）；`dmg -= 护甲`（`projArmor` 或
     `projArmor_<武器id>` 覆盖，v1.114）；投掷物血量（`projHp` 或 `projhp_<id>`）扣减；
   - 血量 ≤0 → `p.explosion()` + `p.liv=0`（引爆即杀，防爆炸后继续沿轨迹飞行）。
3. 每帧清理已不在链上的投掷物血量记录。

### 4.2 疾跑切枪（MSWSwaprun）—— 原 `onKey()` 内 swaprun 拦截

- 键位映射从 `world.ctr.keyXML`（public）**懒构建**：`keyMap[keyCode] = keyId`
  （keyId 形如 `keyWeapon1`），换挡槽位号 = `keyId.substr(9)` 的数字（1-10）。
- **KEY_DOWN 事件层拦截**（本模组 KEY_DOWN 早于游戏 Ctr 注册）：
  疾跑中（`ctr.keyRun==true`）按到第一组快捷槽键 →
  `stopImmediatePropagation`（阻止游戏 Ctr 收到该键，防第二组槽重复处理）
  + `invent.useFav(n)` + 清 `visSel`/`currentSpell.active`/`keyDef`/`keyAttack`。

### 4.3 适配差异（仅两处，均不改变技能行为本体）

1. 防御性访问风格：原版直接 bracket 访问 + try/catch，本模组统一走 `MSWU`
   （`has`/`num`/`str` + `in` 探测）——游戏密封类访问更安全，逻辑不变；
2. `onPause` 门控：见 §6 共存约定（斯安维斯坦时停/回放期间两技能不介入）。

---

## 5. 配置与持久化

- **方式**：SharedObject（`MSWConfig`），无 config.txt——与既有设置
  （跳弹/榴弹参数/举枪）同一机制。
- **面板入口**：哔哔小马设置页 / F6 浮层，新增第 7-10 行：
  6=手雷击落(开关) 7=投掷物血量(±5, 1-1000) 8=投掷物护甲(±5, 0-500) 9=疾跑切枪(开关)。
- **注意**：Sandevistan 旧 `config.txt` 中的 `projhits/projhp/projarmor/projhp_<id>/
  projarmor_<id>/swaprun` 值**不会自动迁移**（两套配置机制不同），需在本模组
  面板重新设置；按武器覆盖项（`projhp_<id>`）暂**无 UI 入口**，字段已保留
  （存档/调试可注入 `projHpOver`/`projArmorOver` 对象），如需 UI 可后续加。
- **诊断**：`MSWConfig.sol` diag 计数器新增 `projHit`（命中）、`projBoom`（引爆）、
  `swapRun`（切枪消费）；读取法见 `state/HANDOFF.md` §4/§7。

---

## 6. 与斯安维斯坦的共存约定

- `MSWU.inGameplay()` 含 **`world.onPause` 判定**：斯安维斯坦时停/回放期间
  世界冻结（`onPause=true`），本模组的两个迁移技能**不介入**——
  - 手雷击落：冻结期攻击体伤害被斯安维斯坦清零、回放期爆炸由斯安维斯坦
    的 `replayProjBoom()` 重演；本组件若介入会造成双重结算。
  - 疾跑切枪：回放期武器由斯安维斯坦重演并钉住 `replayWpn`；介入会破坏其状态机。
- **行为差异（与 Sandevistan 原版对比，需知悉）**：原版在"斯安维斯坦时停期间"
  仍允许疾跑切枪（仅回放期禁止）；迁移后**冻结期一律不介入**。影响：时停期间
  疾跑切数字键不再切枪。这是有意取舍（换取与回放系统共存），如用户需要可再议。
- 两模组各自独立加载（pfe.swf 内各自 loader），互不访问对方源码；
  KEY_DOWN 事件顺序（Sandy 先注册、本模组后注册）无冲突——Sandevistan 已不再
  消费这两个技能相关按键。

---

## 7. 验证状态与建议

**已完成**：两端源码编译通过（本模组 build.bat 成功，Sandevistan amxmlc 成功）；
两端 SWF 已就位（本模组 `release/MoreSkillsWeaponsMod.swf` 14348 字节，
Sandevistan 38926 字节）；无需重打 pfe.swf 补丁。

**未实机**。建议验证清单：
1. 正常战斗射击空中的手雷/导弹/榴弹 → 血量见底即爆（命中音效/无弹正确）；
2. 按住 Shift 疾跑按数字键 1-0 → 切第一组快捷槽（原版无此功能）；
3. 斯安维斯坦时停/回放期间 → 两技能不生效；回放爆炸重演正常（验证
   Sandevistan `replayProjBoom` 抽离门控无回归）；
4. 面板：哔哔小马设置页/F6 浮层第 7-10 行调参并重启验证 SharedObject 持久化；
5. 诊断：读 `MSWConfig.sol` 的 `projHit`/`projBoom`/`swapRun` 计数。

---

## 8. 已知差异与风险

| # | 项目 | 说明 |
|---|---|---|
| 1 | 时停期间疾跑切枪不生效 | §6 共存取舍（原版在时停期间可切） |
| 2 | 旧 config 值不自动迁移 | 两套配置机制不同，需面板重设（§5） |
| 3 | 按武器覆盖项无 UI | `projHpOver`/`projArmorOver` 字段已保留，无面板入口 |
| 4 | 旧 release SWF 被覆盖 | 构建直接写 `release/`，迁移前旧产物（11864B）未另行备份——建议本模组后续自行管理版本备份（如 Sandevistan 的 git 仓库模式） |
| 5 | 双模组同功能回归风险 | 若 Sandevistan 侧被他人从旧备份恢复，会出现双重执行——Sandevistan 已停用并记录在案，勿回退其 v1.126 |

---

## 9. 回滚方案

- **本模组**：将 `src/` 还原为迁移前版本并重新构建（`build/build.bat`）。
  迁移前源文件为 HANDOFF.md §3 所列 7 个文件；`MSWU.as`/`MSWConfig.as`/
  `MSWPanel.as`/`MoreSkillsWeaponsMod.as` 的增量见 §3.1 与 git/Sandevistan 备份
  中的对照（Sandevistan 备份 `state/migration-backup-v1.126/` 含源逻辑全文）。
- **Sandevistan**：git 还原 v1.126（`bc4a9b9`）或将
  `mods/Sandevistan/state/migration-backup-v1.126/SandevistanMod.as.bak.v1.126`
  覆盖回 `src/SandevistanMod.as` 并重新编译部署。
- **注**：回滚前务必与用户确认（用户已明确选择"停用 + 游戏加载本模组实现"）。

---

## 10. 附录：参考位置

| 内容 | 位置 |
|---|---|
| 本报告 | 本文件 |
| 技术细节（逐文件变更、逻辑、共存、验证） | `state/MIGRATION-Sandevistan-swaprun-projhits.md` |
| Sandevistan 源实现备份（迁移前完整源码） | `mods/Sandevistan/state/migration-backup-v1.126/SandevistanMod.as.bak.v1.126` |
| Sandevistan 源实现摘录（可读） | `mods/Sandevistan/state/migration-backup-v1.126/swaprun-projhits-source.md` |
| Sandevistan 侧变更记录 | `mods/Sandevistan/decisions/changelog.md`（v1.127） |
| 用户确认的迁移决策 | 2026-08-17 对话：①停用+备份 ②尽量使斯安维斯坦适配迁移后的手雷击落 |