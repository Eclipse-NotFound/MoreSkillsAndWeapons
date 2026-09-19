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

- **当前 v1.3.4**：入口诊断版本 `1.3.4-hub`，release SWF **26383 字节**，与接手时 HEAD 一致。聚合页、MSW 自注册、子页签、当前模组页恢复默认（`def` 契约 + 即时持久化）均已实现。
- **跨模组通道**：宿主在 `World.w.main` 下发布动态载体 `MSWModAPICarrier`，其他模组经 `getChildByName("MSWModAPICarrier").modAPI.registerPage(...)` 接入。不要沿用旧设计中的兄弟域 `getDefinitionByName` 或直接写 `World.w.modAPI` 路径。
- **最近历史验证依据**：2026-09-05 提交 `f17880c` 记录 Sandevistan 自动接入（测试 pages=3）及真实点击恢复默认验证；`7950f6c` 同步设计状态。设计正文部分仍标 2026-08-29，日期以各自证据为准。
- **2026-09-19 接手核查**：master 工作树起初干净；完成源码、构建配置和历史核对，本轮未编译、未启动游戏、未部署，不将历史实测视为本轮复验。
- **测试基建**：MSWAutoTest 按 applicationID≠pfe 激活，自动开档/开菜单/派发点击；这是源码门控，不能替代正式实例回归。诊断配合 read_sol.py 读取。
- v1.0（910cdce）历史记录为 2026-08-18 全部功能实机通过；dist zip 仍为 v1.0，尚未随当前 release 更新。回滚或发布须另走对应技能与部署授权流程。

## 4. 正在进行与卡点

- 本次任务是接手开发，尚未指定新的功能或修复目标；聚合页一期与 Sandevistan 接入已经完成，不再作为待启动任务。
- 历史记录仍留有面板手感、D-044 冲刺落感、换机后举枪/疾跑切枪确认项；已读记录中未见后续闭环，本轮未重跑，不能据此判定功能失效。
- **构建环境**：Animate 的 mxmlc.jar 与 FP11.1 playerglobal.swc 在当前 D 盘路径存在，但本轮 `Get-Command java` 未找到 PATH 中的 Java。后续编译先定位可用 Java；不等于机器未安装 Java。

## 5. 已知问题

- **趴姿（lurked）分支尽力而为**：lurked/lurkX/lurkBox 均 internal 不可写——冲刺后位移>10px 会站起回归；蹲姿分支完整支持（已知限制，见 D-039）。
- 发枪可能重复 +12 发 gren40（读档时序，可接受）。
- DLC/pfe.swf、pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010 流程）。

## 6. 下一步（优先级排序）

1. 按用户下一项明确需求继续；接手本身不触发新增功能、部署或重打包。
2. 若进入构建/验证，先解决 Java 命令入口，使用隔离构建输出和测试实例；根据改动范围回归现有功能。
3. 若进入发布，核对上述历史未闭环项，走发布门禁并更新 dist；不要把旧 v1.2.11 验收要求误当当前版本。
4. choice/action/info 控件、长页滚动等仅为设计候选；跳弹/举枪接入游戏技能系统仍按用户延缓决定处理。

## 7. 深入了解

- **开发历程**：state/journal.md（含 Sandevistan 技能迁入与 D-037~D-044 全链路摘要；迁移报告原文在 git 历史）
- **决策**：decisions/decisions.md（至 D-046；关键索引：D-001 动态架构 / D-002 帧后重生 / D-007 构建链 / D-010 pfe 合并 / D-016 F6-only / D-026~D-033 举枪与时停共存 / D-037~D-044 冲刺姿态 / D-045 分发 / D-046 面板）
- **设计**：design/features.md、mechanics-notes.md、skill-aim-sit-ladder.md、design-冲刺保持趴姿.md
- **源码结构**：src 下 14 个 AS 文件（入口/防御访问工具/配置/武器注入/子弹核心/SATS 弹道/面板/哔哔小马模组页签/举枪/击落/切枪/冲刺姿态/设置登记簿/自动测试）。配置存 SharedObject `MSWConfig`。
- **诊断读取法**：`python build/tools/read_sol.py "%APPDATA%\pfe\Local Store\#SharedObjects\mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol"`——完整解析 AMF3 键值（格式规律沉淀在 shared-knowledge `knowledge-validation/methods/sol-diag-reading.md`）；diag 计数器跨会话累积、换机/换用户重置
- **构建/部署**：build/build.bat 使用 Animate mxmlc，直接覆盖运行时 release SWF，因此不是只读编译检查。单纯验证应改用隔离输出；实际部署走 remains-release-gate，修改 loader 走 remains-swf-patching。build/README.md 部分旧机器路径已过时，以当前配置和探测结果为准。
- **共享知识贡献清单**：原 HANDOFF §6（bullet-wall-impact / explosion-blast-bullets / phisbullet-grenade-physics / runtime-weapon-creation / sats-trajectory-arc / pippageopt-overlay / mod-loader-patch-structure 等）
