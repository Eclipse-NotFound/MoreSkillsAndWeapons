# MoreSkills&Weapons —— 开发记忆入口

> 新会话从这里开始。协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。

## 1. 这个模组是什么

武器与技能扩展模组：**跳弹**（镜面反射）+ **可编程榴弹炮 mswglau**（下坠/撞墙/初速度/反弹可调，SATS 实时弹道）+ **蹲/梯举枪**（Shift+W）+ **魔法冲刺保持蹲/趴姿** + **手雷击落 / 疾跑切枪**（迁自 Sandevistan）+ 散布恒定 + **哔哔小马"模组"子页**（主菜单页内，原版复选框/滑块控件，v1.2）+ F6 浮层。完全动态访问架构（零游戏类类型引用）。入口类 `MoreSkillsWeaponsMod`。

## 2. 用户偏好与协作约定

- **热键只用 F6**（F8 在该键盘无键事件；F10 曾与其他模组冲突已让出）。
- **与 Sandevistan 共存**：以 D-033 / `MSWU.inGameplay()` 为准：`onPause && godMode` 时不介入；仅时停（onPause=true、godMode=false）仍可介入。旧记忆将时停与回放一并排除，已于 2026-09-19 按源码纠正。
- **改游戏本体文件前必须先检查其他开发者改动**（时间戳/loader 字符串），有改动先合并。
- 跳弹/举枪接入游戏技能系统：用户要求延缓，未做。

## 3. 当前状态

- **源码 / 隔离构建 v1.4.0**：诊断版本 `1.4.0-ricochet`，增加基础跳弹次数、额外概率和概率/伤害/速度衰减；五项设置在模组页与 F6 共用定义。默认仍为一次跳弹，额外概率 0%。完整已确认规则见 design/ricochet-settings.md。
- **正式运行时仍为 v1.3.4**：release/MoreSkillsWeaponsMod.swf 保持 **26383 字节**，未被本轮覆盖。候选产物在 build/out/MoreSkillsWeaponsMod.swf；dist 仍为 v1.0。本轮用户授权实现，正式替换待最终部署确认，不要混淆源码与安装版本。
- **跨模组通道**：宿主在 `World.w.main` 下发布动态载体 `MSWModAPICarrier`，其他模组经 `getChildByName("MSWModAPICarrier").modAPI.registerPage(...)` 接入。不要沿用旧设计中的兄弟域 `getDefinitionByName` 或直接写 `World.w.modAPI` 路径。
- **最近历史验证依据**：2026-09-05 提交 `f17880c` 记录 Sandevistan 自动接入（测试 pages=3）及真实点击恢复默认验证；`7950f6c` 同步设计状态。设计正文部分仍标 2026-08-29，日期以各自证据为准。
- **2026-09-19 实现验证**：隔离 AIR 266 项断言通过；游戏副本真实设置页 17 行、五个滑块、恢复默认点击通过，真实 Bullet 对象 3 次基础 + 1 次额外反弹、减伤/减速和概率归零终止通过；截图已核对。游戏冒烟暂停世界并设置碰撞状态，不是自然开火/高弹量性能/多模组共存复验。正式游戏与真实存档未改。
- **测试基建**：MSWAutoTest 按 applicationID≠pfe 激活，自动开档/开菜单/派发点击；这是源码门控，不能替代正式实例回归。诊断配合 read_sol.py 读取。
- v1.0（910cdce）历史记录为 2026-08-18 全部功能实机通过；dist zip 仍为 v1.0，尚未随当前 release 更新。回滚或发布须另走对应技能与部署授权流程。

## 4. 正在进行与卡点

- 本次跳弹功能已实现并验证，等待是否替换正式 release 的最终确认；不需要修改游戏本体 loader。基础次数 0–20、百分比 0–100，整条链保护上限 100 次；低速/零伤害终止；快照随续弹继承，允许再次命中同一目标。
- 历史记录仍留有面板手感、D-044 冲刺落感、换机后举枪/疾跑切枪确认项；已读记录中未见后续闭环，本轮未重跑，不能据此判定功能失效。
- **构建环境已打通**：使用 `D:\Program Files\Adobe Animate 2024\jre\bin\java.exe`（17.0.10），配原 mxmlc.jar / playerglobal.swc 成功构建；不依赖 PATH。PowerShell 将包含 `+=` 的编译选项整体加引号。当前仅有既存 MSWSettingsHub 无显式构造器警告，无编译错误。

## 5. 已知问题

- **趴姿（lurked）分支尽力而为**：lurked/lurkX/lurkBox 均 internal 不可写——冲刺后位移>10px 会站起回归；蹲姿分支完整支持（已知限制，见 D-039）。
- 发枪可能重复 +12 发 gren40（读档时序，可接受）。
- DLC/pfe.swf、pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010 流程）。

## 6. 下一步（优先级排序）

1. 获得正式部署确认后，按 remains-release-gate 备份并替换本模组 release；当前测试专用 out/smoke/SmokeMod.swf **不可部署**，生产产物是 out/MoreSkillsWeaponsMod.swf。
2. 可重跑 build/test-ricochet.ps1 与 build/test-game-smoke.ps1；测试使用唯一应用 ID，清理只针对各自测试进程与描述符，正式 pfe 实例不碰。
3. 若进入发布，核对上述历史未闭环项，走发布门禁并更新 dist；不要把旧 v1.2.11 验收要求误当当前版本。
4. choice/action/info 控件、长页滚动等仅为设计候选；跳弹/举枪接入游戏技能系统仍按用户延缓决定处理。

## 7. 深入了解

- **开发历程**：state/journal.md（含 Sandevistan 技能迁入与 D-037~D-044 全链路摘要；迁移报告原文在 git 历史）
- **决策**：decisions/decisions.md（至 D-046；关键索引：D-001 动态架构 / D-002 帧后重生 / D-007 构建链 / D-010 pfe 合并 / D-016 F6-only / D-026~D-033 举枪与时停共存 / D-037~D-044 冲刺姿态 / D-045 分发 / D-046 面板）
- **设计**：design/ricochet-settings.md（v1.4.0 规则、公式、实现与验证边界）；旧 design/features.md、mechanics-notes.md、skill-aim-sit-ladder.md、design-冲刺保持趴姿.md。
- **源码结构**：src 下 15 个 AS 文件，v1.4.0 新增 MSWRicochet（每条跳弹链的快照/次数/概率）；其余入口/配置/武器/追踪/UI 等结构不变。配置存 SharedObject `MSWConfig`。
- **诊断读取法**：`python build/tools/read_sol.py "%APPDATA%\pfe\Local Store\#SharedObjects\mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol"`——完整解析 AMF3 键值（格式规律沉淀在 shared-knowledge `knowledge-validation/methods/sol-diag-reading.md`）；diag 计数器跨会话累积、换机/换用户重置
- **构建/部署**：build/README.md 已更新当前 Java/编译器路径、隔离构建与测试命令。旧 build.bat 使用裸 java，直接覆盖运行时 release，因此不是只读编译检查；实际部署走 remains-release-gate，修改 loader 走 remains-swf-patching。
- **共享知识贡献清单**：原 HANDOFF §6（bullet-wall-impact / explosion-blast-bullets / phisbullet-grenade-physics / runtime-weapon-creation / sats-trajectory-arc / pippageopt-overlay / mod-loader-patch-structure 等）
