# 项目交接文档（HANDOFF）

> 生成日期：2026-08-17
> 用途：转移项目到新对话时，先读本文件恢复上下文。
> 完整细则见 `design/`、`decisions/`、`state/current-status.md`、
> `shared-knowledge/`（公共知识）。本文件是索引 + 状态快照。

---

## 0. 一句话

《辐射小马国》同人游戏 **Remains** 的模组 **MoreSkills&Weapons**：
跳弹技能 + 可编程榴弹炮（下坠/撞墙次数/初速度/反弹力度可调）+ 蹲姿/梯子举枪技能。

## 1. 权限与协作（重要）

- 工作区：`mods/MoreSkills&Weapons/`（READ-WRITE）；`shared-knowledge/`（只读+谨慎贡献）；
  `game-reference/` 与游戏原始文件（READ-ONLY）；其他模组（默认不访问、绝不修改）。
- **多开发者共享环境**：`mods/` 下有 RConnect、RealisticVision、Sandevistan 三个其他模组；
  游戏根目录是共享工作区（见 `MODS_MIRROR_NOTICE.txt`）。
- **改动游戏本体文件（pfe.swf 等）前必须先检查其他开发者是否已改动（时间戳/loader 字符串），
  有改动则先合并。** 本模组只动过 `pfe.swf`（追加 loader），DLC 两个文件从未动。
- 不读取其他模组源码（隔离原则）；F10 曾与其他模组热键冲突 → 本模组热键只用 F6。

## 2. 当前功能状态（截至 2026-08-17）

| 功能 | 状态 | 说明 |
| --- | --- | --- |
| 可编程榴弹炮 `mswglau` | ✅ 已实现 | 运行时注入 AllData.d 克隆自 glau；进游戏自动发放+12 发 gren40；存档/HUD/修理兼容 |
| 榴弹参数（哔哔小马设置页） | ✅ 已实现 | 下坠速率/撞墙次数/初速度/反弹力度；SharedObject 持久化（MSWConfig） |
| SATS 弹道覆盖层 | ✅ 已实现 | 按参数实时绘制，终点爆炸范围圈用原版 satsRadius 素材（绿色，已对齐） |
| 跳弹技能 | ✅ 已实现 | 独立开关；镜面反射；破墙那发不弹跳；已修复大量反弹问题（见 D-013~D-025） |
| 蹲姿/梯子举枪 | 🟡 待复测 | 面板第 6 行开关（Shift+W）；**诊断注意：aimSkill 当前 false（需开启开关）**；D-031 改键 + D-032 失效修复已就位 |
| 手雷击落 + 疾跑切枪 | 🟡 待复测 | 自 Sandevistan 迁移（面板第 7-10 行）；**D-033（2026-08-17）：斯安维斯坦时停期已放行**（inGameplay 改 onPause&&godMode 判据；projhits 加 origDam 恢复 + 时停视觉爆炸）；回放期仍禁 |
| 魔法冲刺保持趴姿 | 🟡 待实机 | **D-037（2026-08-18）**：趴着（lurked）施放 sp_kdash 后保持趴姿（含冲刺中趴姿动画滑行、冲刺后继续趴姿移动——只能趴姿进入的通道全程趴姿）；面板第 11 行开关，默认开 |
| 设置面板 | ✅ 主入口=哔哔小马设置页；辅入口=F6 浮层 | F8 在该键盘无键事件；F10 已让出 |

## 3. 文件结构

```
mods/MoreSkills&Weapons/
├─ AGENT_SCOPE.md           权限规则（受保护，勿改）
├─ src/                     AS3 源码（完全动态访问架构，零游戏类类型引用）
│  ├─ MoreSkillsWeaponsMod.as  入口：static init(main)（loader 契约）→ 帧/键事件
│  ├─ MSWU.as               防御性动态访问工具（bracket + in 探测）
│  ├─ MSWConfig.as          设置 + SharedObject 持久化 + 诊断计数器（diag）
│  ├─ MSWWeapon.as          mswglau 注入/发放/每帧应用参数（grav/speed/explRadius/destroy/tipDecal）
│  ├─ MSWBullets.as         核心：子弹跟踪/跳弹/榴弹反弹与引爆（帧后重生方案）
│  ├─ MSWTrajectory.as      SATS 自绘弹道（satsRadius 素材）
│  ├─ MSWPanel.as           设置面板（PipPageOpt 叠加 + F6 浮层）
│  ├─ MSWAim.as             蹲姿/梯子举枪
│  ├─ MSWProjHits.as        手雷击落（2026-08-17 迁自 Sandevistan）
│  ├─ MSWSwaprun.as         疾跑切枪（2026-08-17 迁自 Sandevistan）
│  └─ MSWDashPose.as        魔法冲刺保持趴姿（2026-08-18 D-037）
├─ design/                  features.md（功能设计）、mechanics-notes.md（机制清单）、
│                           skill-aim-sit-ladder.md（举枪技能设计）
├─ decisions/decisions.md   D-001 ~ D-030 技术决策（含每轮实测 bug 的根因与教训）
├─ state/current-status.md  当前状态/已知问题/下一步
├─ knowledge/               experiments/build-toolchain（构建探索记录）
├─ build/                   构建：build.bat + flex-config.xml + README.md；
│                           pfe-patch/（pfe.swf 导出脚本 8.9MB + 合并中间产物，可留可清）
└─ release/MoreSkillsWeaponsMod.swf   构建产物（部署到游戏即替换此文件）
```

## 4. 进行中的问题（接续点）

**新迁入技能（2026-08-17，Sandevistan 开发者交付）**：`手雷击落`+`疾跑切枪`
已迁入（MSWProjHits/MSWSwaprun，面板第 7-10 行）。与斯安维斯坦共存约定：
`MSWU.inGameplay()` 含 onPause 判定——斯安维斯坦时停/回放期间本模组不介入。
**迁移报告**：`state/迁移报告-2026-08-17-Sandevistan技能迁入.md`（总览/清单/
验证/回滚）；技术细节：`state/MIGRATION-Sandevistan-swaprun-projhits.md`。
**待实机复测**。

**举枪改键（D-031，2026-08-17）**：用户确认"趴下按 W 举枪"违背使用习惯，
已改为 **Shift+W 举枪**、W 恢复原版（坐姿起身/梯子爬升）。**D-032 已修复
举枪失效根因**（用户实测"完全失效"）：
- 根因① heldShift 事件顺序：Shift+W 同时按下时 W 的 KEY_DOWN 可能先到 →
  当帧 on=false → prevSit 污染 → 恢复兜底永不触发。修复：KEY_DOWN(87)
  用 `e.shiftKey` 同步 heldShift；
- 根因② 吞键失效（D-030 已知 stopImmediatePropagation 不阻止 Ctr）：
  现 KEY_DOWN(87) 坐姿分支直接改写 Ctr 状态——`ctr.keyBeUp=false` +
  `ctr.keyDowns[87]=true`（后续重复 KEY_DOWN 被 Ctr 守卫跳过，keyBeUp
  不再置位 → 游戏 2884 永不触发）；帧内三保险保留为双保险；
- 根因③ 配置：sol 中 aimSkill 曾为 02=false（用户面板误触/保存），
  需打开面板第 6 行开关（AMF0 布尔 03=true、02=false）。
**待实机复测**：
- Shift+W 坐姿举枪（D-032 修复后应不再站起）；
- 单独 W 起身/爬升无任何拦截（原版路径）；
- 松 Shift 或 W 即退出瞄准（release：keySit=false、noStairs=false）；
- 诊断读取法不变：`%APPDATA%\pfe\Local Store\#SharedObjects\
  mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol`
  （注意路径含 mods 子目录，非 pfe.swf 下）；关注 keyBeUpLeak /
  sitRestored（>0 = 恢复兜底闭环）/ aimSkill 布尔值。
- 历史背景（改键前）：坐姿按 W 曾触发原版 unsit（2884 行
  isSit && keyBeUp && !keySit）；吞键（stopImmediatePropagation）在该运行时
  失效（keyBeUpLeak=7 实测证据，D-030）；恢复兜底 prevSit 维护 bug 已修
  （!on 分支不再清 prevSit）。
- 相关机制：起身路径共 3 条（2884 keyBeUp&&!keySit、2889 !stay、jumpp/SPACE）；
  `weapUp` internal 但效果可由"贴图抬高→vis.emit 枪口同步"复刻；
  `stay` 是 Pt 基类 public 字段；`isLaz/noStairs/sit()/unsit()` public。

**魔法冲刺保持趴姿（D-037，2026-08-18）**：新技能已实现，**待实机验证**：
- 设计：`state/design/design-冲刺保持趴姿.md`（含原版机制链与实现方案）；
- 用户确认：只做趴姿（lurked）、默认开、趴姿动画滑行；验收场景 = 只能趴姿
  进入的通道内全程保持趴姿；
- 实现：`src/MSWDashPose.as`——kdash_t 0→>0 且 lurked 时进入接管，每帧强制
  stay/lurked/lurkX/lurkBox=null，冲刺中 work="lurk"+t_work=20 播趴姿动画，
  冲刺后自然落定冻结趴姿；退出 = work=="unlurk"（W/空格/蹲原版解除）或死亡；
- 配置：`dashKeepPose` 默认开，面板第 11 行；
- 诊断：dashPoseCast（接管次数）/dashPoseF（接管帧数）/dashPoseExit（解除次数）；
- 验证清单：趴着施放冲刺→全程趴姿滑行→结束后仍趴着→W 正常解除；站着/蹲着
  施放→原版行为不变；通道场景→全程趴姿；面板开关关闭→原版行为；

**迁移技能审核（2026-08-17 已完成）**：手雷击落 + 疾跑切枪迁移报告已审核
通过（文件/产物真实性、游戏字段引用存在性、逻辑正确性均验证）；
待实机复测清单见迁移报告 §7。已知风险：Sandevistan 侧停用无法独立验证
（隔离原则）、时停期间切枪不生效（共存取舍）、旧 config.txt 值不迁移。

## 5. 构建与部署

- 构建：`cd build && build.bat`（Animate 2024 自带 mxmlc 4.6 + FP11.1 playerglobal；
  坑：cwd 需 flex-config.xml、themes/Spark/spark.css、localFonts.ser——均已就位）。
- 产物：`release/MoreSkillsWeaponsMod.swf`（swf v14；文档类 symbol 0；
  游戏类仅字符串引用，无嵌入）。
- 部署：**只需替换 release SWF**（loader 已打进 pfe.swf）；
  玩家存档证据（PFEgame0.sol 含 mswglau/gren40）确认加载链路正常。
- pfe.swf 合并流程（如需再次改 loader）：FFDec 26.2.1 位于
  `C:\Users\micha\Documents\_sandevistan_dev\ffdec\ffdec-cli.exe`；
  导出 MainFE → 只改 MainFE.as → 最小目录 importScript 定向替换 → 验证后部署；
  备份：`pfe_1.02_before_msw_merge_20260815.swf`（根目录）。
- 修改 pfe.swf 前**必须检查其他开发者改动**（当前 4 loader 完好，无改动）。

## 6. 已验证的游戏机制（可直接复用，勿重复逆向）

本模组已贡献到 shared-knowledge（均含源码 symbol 与实测证据）：
- `physics-collision/discoveries/bullet-wall-impact.md`：Bullet 撞墙判定/下坠公式/破墙信号
- `physics-collision/discoveries/projectile-step-sweep.md`（既有）：maxdelta 子步
- `weapons-projectiles/discoveries/explosion-blast-bullets.md`：爆炸冲击弹字段特征（连锁爆炸陷阱）
- `weapons-projectiles/discoveries/phisbullet-grenade-physics.md`：原版手雷物理模型
- `weapons-projectiles/discoveries/runtime-weapon-creation.md`：AllData.d 注入 + Weapon.create
- `ui-systems/discoveries/sats-trajectory-arc.md`：SATS 弧线机制 + noTrass
- `ui-systems/discoveries/pippageopt-overlay.md`：哔哔小马设置页叠加 + SharedObject 验证法
- `knowledge-validation/discoveries/mod-loader-patch-structure.md`：MainFE loader 结构（含同域修正）
- 既有 facts（Sandevistan 贡献，本模组沿用）：密封类 bracket 陷阱、帧/键时序、
  firstObj 链、图层体系、爆炸流程等。

关键实现决策索引（decisions.md）：D-001 动态架构 / D-002 帧后重生 /
D-003 explRadius 置 0 + iExpl / D-007 构建链 / D-010 pfe 合并 / D-011 Pip 集成 /
D-013 冲击弹排除 / D-014 子步重放 / D-015 手雷物理 / D-016 多热键→D-019 F6-only /
D-021 反弹零墙损 / D-023 liv 守卫豁免 / D-024 键快照 / D-026~D-030 举枪技能演进 /
D-031 举枪改键 Shift+W / D-032 举枪失效根因（heldShift 同步 + keyDowns 阻断）。

## 7. 已知问题与风险（复测清单）

1. **举枪（D-031/D-032）待复测**——Shift+W 举枪、W 起身/爬升；D-032 已修复
   失效根因（heldShift 同步 + keyDowns 阻断），需实机确认不再站起；
2. **魔法冲刺保持趴姿（D-037）待实机**——趴着施放冲刺全程保持趴姿；验收
   场景：只能趴姿进入的通道内滑行；诊断读 dashPoseCast/dashPoseF/dashPoseExit；
2. 蹲姿举枪历史遗留：吞键失效（keyBeUpLeak）+ 恢复兜底（sitRestored）
   ——Shift+W 时三保险仍依赖兜底闭环，复测时读诊断确认；
3. 榴弹"偶发原路回弹/陷地"：经多轮修复（D-014/017/019/020/021/022/023/024/025）
   应基本消除，但需回归确认；
4. 诊断读取法：`%APPDATA%\pfe\Local Store\#SharedObjects\
   mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol`
   （AMF 明文可 grep；diag 计数：frames/keys/hk<code>/wDown/wSitDown/wSwallow/
   keyBeUpLeak/sitRestored/bounce/explode/errBounce/lastErr/projHit/projBoom/swapRun/
   dashPoseCast/dashPoseF/dashPoseExit）；
5. 跳弹/榴弹/举枪均未接入游戏技能系统（用户要求独立开关先行，后续适配）；
6. DLC/pfe.swf、DLC/pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010 流程）；
7. 发枪可能重复 +12 发 gren40（读档时序，可接受，后续优化）；
8. **迁移技能待复测**（手雷击落/疾跑切枪，见迁移报告 §7 验证清单）；
9. 迁移已知风险：Sandevistan 侧停用无法独立验证（隔离原则）、时停期间切枪
   不生效（共存取舍）、旧 config.txt 值不迁移（需面板重设）。

## 8. 下一步建议

1. 实机复测：举枪（Shift+W，读 sitRestored/keyBeUpLeak/aimSkill）、
   迁移技能（手雷击落/疾跑切枪，读 projHit/projBoom/swapRun）；
2. 回归测试榴弹全套参数与跳弹；
3. 视需要将已实测机制从 discoveries 提升为 facts；
4. 若玩家满意，可开始"接入游戏技能系统"设计（跳弹/举枪两技能）；
5. 定期检查 pfe.swf 是否被其他开发者改动（合并前备份）。
