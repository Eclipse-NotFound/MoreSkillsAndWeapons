# 迁移说明：Sandevistan → MoreSkills&Weapons（疾跑中切枪 + 手雷击落）

> 撰写：Sandevistan 模组开发者（2026-08-17）
> 目的：告知 MoreSkills&Weapons 开发者，两个技能已迁入本模组，
> 以及具体改了哪些文件、逻辑是什么、与斯安维斯坦的共存约定。
> 源实现备份与源码摘录见 `mods/Sandevistan/state/migration-backup-v1.126/`。

## 0. 一句话

`疾跑中切枪`（swaprun）与`手雷击落`（projhits）两个技能从 Sandevistan
迁入本模组：**游戏实际运行实现 = 本模组**（Sandevistan 侧已停用）。
实现逻辑未改（碰撞/血量/护甲/引爆、事件层拦截），仅适配了本模组的
防御性动态访问风格（MSWU）与 SharedObject 配置。

## 1. 具体更改的文件

### 本模组（MoreSkills&Weapons）

| 文件 | 变更 |
|---|---|
| `src/MSWU.as` | **新增静态助手** `inGameplay(w)`：可操作状态判定（镜像 Sandevistan 的同名函数 + **onPause 判定**，见 §3 共存约定） |
| `src/MSWConfig.as` | 新增配置字段：`projHits`(默认开)、`projHp`(30)、`projArmor`(0)、`projHpOver`/`projArmorOver`(按武器覆盖，无 UI)、`swapRun`(默认开)；load/save/clamp 同步 |
| `src/MSWPanel.as` | 设置行 6→10：新增 `手雷击落`(开关)、`投掷物血量`(±5)、`投掷物护甲`(±5)、`疾跑切枪`(开关)；`ROWS=10` |
| `src/MSWProjHits.as` | **新文件**：手雷击落核心（§2） |
| `src/MSWSwaprun.as` | **新文件**：疾跑切枪核心（§2） |
| `src/MoreSkillsWeaponsMod.as` | 新增 `projhits`/`swaprun` 组件成员并接线；`onFrame` 增加 `projhits.process(w)`；`onKeyDown` 在面板/浮层处理之后、F6 热键之前调用 `swaprun.intercept(e, world)` |
| `release/MoreSkillsWeaponsMod.swf` | 重建产物（11864 → 14348 字节） |

### Sandevistan 侧（供知情，非本模组文件）

- `mods/Sandevistan/src/SandevistanMod.as`（v1.127）：两技能**停用**——
  `cfgProjHits`/`cfgSwapRun` 默认改 `false`；config.txt 解析分支、设置面板两行、
  saveConfigFile 回写全部移除（已有 config 无法再开启）；`stepProjHits` 的
  回放重演分支抽成 `replayProjBoom()` 脱离开关门控（斯安维斯坦回放系统对
  时停中自然爆炸的重演不受影响）。
- 完整源码备份：`mods/Sandevistan/state/migration-backup-v1.126/`。

## 2. 迁移的技能逻辑（实现未改）

### 手雷击落（MSWProjHits）—— 原 Sandevistan `stepProjHits()` 常规模式

- 每帧扫描 `loc.firstObj` 链：
  - **可击落投掷物** = `PhisBullet`/`SmartBullet`/`Bullet` 且 `explRadius>0` 且 `!isExpl`
  - **攻击体** = 其它 `fe.weapon::*` 且 `vel>=1`（近战 vel=0 不参与，v1.90）
- 双重判定 `p×b`：
  - `b==p` 跳过（v1.92 自测防护）
  - 同源且投掷物距 owner <200px 跳过（v1.91 出生护手，防贴脸自爆）
  - **相对速度扫掠碰撞**（v1.92）：`R(t)=O+t·RV, t∈[0,1] 钳制`，最近点 ≤28px 命中
  - 命中 → `loc.remObj(b)`（子弹弹出）；`dmg -= 护甲`（`projArmor` 或
    `projArmor_<武器id>` 覆盖，v1.114）；投掷物血量（`projHp` 或 `projhp_<id>`）扣减
  - 血量 ≤0 → `p.explosion()` + `p.liv=0`（引爆即杀防飞行鬼影）
- 默认值与原版一致：projHits=开、projHp=30、projArmor=0。
- **未迁移**：Sandevistan 的时停/回放分支（`projBoom` 重演、`origDam` 恢复、
  `seenAtk` 追踪器）——它们依赖斯安维斯坦的时停回放系统，本模组无此系统。

### 疾跑切枪（MSWSwaprun）—— 原 Sandevistan `onKey()` 内 swaprun 拦截

- 键位映射从 `world.ctr.keyXML`（public）懒构建：`keyMap[keyCode] = keyId`
  （keyId 形如 `keyWeapon1`），换挡槽位 = `keyId.substr(9)` 的数字（1-10）。
- KEY_DOWN 事件层拦截（本模组 KEY_DOWN 早于游戏 Ctr 注册）：
  疾跑中（`ctr.keyRun`）按到第一组快捷槽键 →
  `stopImmediatePropagation` + `invent.useFav(n)` + 清 visSel/currentSpell/keyDef/keyAttack。
- 默认开（`swapRun=true`）。

## 3. 与斯安维斯坦的共存约定（重要）

- **`MSWU.inGameplay()` 含 `world.onPause` 判定**：斯安维斯坦时停/回放期间
  世界冻结（`onPause=true`），本模组的两个迁移技能**不介入**：
  - 手雷击落：冻结期攻击体伤害被斯安维斯坦清零、回放期爆炸由斯安维斯坦
    的 `replayProjBoom()` 重演——本组件若介入会造成双重结算。
  - 疾跑切枪：回放期武器由斯安维斯坦重演并钉住 `replayWpn`——介入会破坏
    其状态机。
- **行为差异（与原版 Sandevistan 对比）**：Sandevistan 原版在"斯安维斯坦
  时停期间"仍允许疾跑切枪（仅回放期禁止）；迁移后改为冻结期一律不介入。
  影响：时停期间疾跑切数字键不再切枪（可接受，换取与回放系统的共存）。
- 其余共存：两模组各自独立加载（pfe.swf 里各自 loader），互不访问对方源码。

## 4. 配置与诊断

- 配置：SharedObject（哔哔小马设置页 / F6 浮层第 6-9 行），非 config.txt。
  Sandevistan 旧 `config.txt` 里的 `projhits/projhp/projarmor/projhp_*/projarmor_*/swaprun`
  值**不会自动迁移**（本模组无 config.txt）；按武器覆盖项（`projhp_<id>`）暂无
  面板入口，保留字段（存档/调试可注入 `projHpOver`/`projArmorOver`）。
- 诊断：`MSWConfig.sol` 的 diag 计数器新增 `projHit`（命中）、`projBoom`（引爆）、
  `swapRun`（拦截消费）。读取法见 `state/HANDOFF.md` §4/§7。

## 5. 建议验证

1. 正常战斗射击飞在空中的手雷/导弹/榴弹 → 血量见底即爆（无弹无爆音效检查）；
2. 按住 Shift（疾跑）按数字键 1-0 → 切第一组快捷槽（原版无此功能）；
3. 斯安维斯坦时停/回放期间 → 上述两技能不生效、回放爆炸重演正常；
4. 哔哔小马设置页/F6 浮层：6 手雷击落 7 投掷物血量 8 投掷物护甲 9 疾跑切枪。