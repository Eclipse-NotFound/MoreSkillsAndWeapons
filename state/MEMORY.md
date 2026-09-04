# MoreSkills&Weapons —— 开发记忆入口

> 新会话从这里开始。协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。

## 1. 这个模组是什么

武器与技能扩展模组：**跳弹**（镜面反射）+ **可编程榴弹炮 mswglau**（下坠/撞墙/初速度/反弹可调，SATS 实时弹道）+ **蹲/梯举枪**（Shift+W）+ **魔法冲刺保持蹲/趴姿** + **手雷击落 / 疾跑切枪**（迁自 Sandevistan）+ 散布恒定 + **哔哔小马"模组"子页**（主菜单页内，原版复选框/滑块控件，v1.2）+ F6 浮层。完全动态访问架构（零游戏类类型引用）。入口类 `MoreSkillsWeaponsMod`。

## 2. 用户偏好与协作约定

- **热键只用 F6**（F8 在该键盘无键事件；F10 曾与其他模组冲突已让出）。
- **与 Sandevistan 共存**：时停/回放期间本模组不介入（`MSWU.inGameplay()` 含 onPause 判定）。
- **改游戏本体文件前必须先检查其他开发者改动**（时间戳/loader 字符串），有改动先合并。
- 跳弹/举枪接入游戏技能系统：用户要求延缓，未做。

## 3. 当前状态

- **v1.2.9（2026-08-29）**：字体/背景对齐原版——suppress 保留页面自带背景美术（大尺寸子件不再隐藏）；标签字体从游戏现成行 nazv 探测（实测 `_sans/16`、按钮 `_sans/20`、非内嵌），不再写死 SimHei；修 rowOf 密封类 #1069。自动驱动验证通过（tabOn=1/tabFont 探针/截图人审字体背景一致）。release SWF 23108 字节。
- **测试基建**：MSWAutoTest 常驻模组内（appid≠pfe 才激活，用户实例零影响）——自动开档/开主菜单页/派发点击，配 read_sol.py 与截图可全自动回归 UI。
- v1.0（910cdce）：全部功能实机验证通过（2026-08-18）；dist zip 为 v1.0，本轮验收后重打包。
- 回滚：`git checkout 910cdce -- release/MoreSkillsWeaponsMod.swf`。

## 4. 正在进行与卡点

- **模组面板实机验收**：玩家重启后主菜单页点"模组"→ 滑块拖动/复选框点按/切子页退出（自动化已验，待真人手感确认）。
- **D-044 魔法冲刺腾空补重力**：机制数据已佐证（dashPoseGrav=6），只差玩家对落感的**主观**确认。
- 举枪/疾跑切枪：迁移换机后尚无触发记录——待玩家实机各用一次即闭环。

## 5. 已知问题

- **趴姿（lurked）分支尽力而为**：lurked/lurkX/lurkBox 均 internal 不可写——冲刺后位移>10px 会站起回归；蹲姿分支完整支持（已知限制，见 D-039）。
- 发枪可能重复 +12 发 gren40（读档时序，可接受）。
- DLC/pfe.swf、pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010 流程）。

## 6. 下一步（优先级排序）

1. 玩家实机验收 v1.2.5（主菜单页 → 模组：滑块手感/复选框/切页退出）；
2. 玩家确认 D-044 落感 + 举枪/疾跑切枪各用一次 → 全闭环后重打 dist zip（含新版）；
3. 如玩家满意可启动"接入游戏技能系统"设计（跳弹/举枪）。

## 7. 深入了解

- **开发历程**：state/journal.md（含 Sandevistan 技能迁入与 D-037~D-044 全链路摘要；迁移报告原文在 git 历史）
- **决策**：decisions/decisions.md（D-001~D-045；关键索引：D-001 动态架构 / D-002 帧后重生 / D-007 构建链 / D-010 pfe 合并 / D-016 F6-only / D-026~D-032 举枪演进 / D-037~D-044 冲刺姿态 / D-045 分发）
- **设计**：design/features.md、mechanics-notes.md、skill-aim-sit-ladder.md、design-冲刺保持趴姿.md
- **源码结构**：12 个 MSW*.as（入口/防御访问工具/配置/武器注入/子弹核心/SATS 弹道/面板/哔哔小马模组页签/举枪/击落/切枪/冲刺姿态）
- **诊断读取法**：`python build/tools/read_sol.py "%APPDATA%\pfe\Local Store\#SharedObjects\mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol"`——完整解析 AMF3 键值（格式规律沉淀在 shared-knowledge `knowledge-validation/methods/sol-diag-reading.md`）；diag 计数器跨会话累积、换机/换用户重置
- **构建/部署**：`cd build && build.bat`（Animate mxmlc）；部署只需替换 release SWF；改 loader 走 FFDec 定向替换（备份 pfe_1.02_before_msw_merge_20260815.swf）
- **共享知识贡献清单**：原 HANDOFF §6（bullet-wall-impact / explosion-blast-bullets / phisbullet-grenade-physics / runtime-weapon-creation / sats-trajectory-arc / pippageopt-overlay / mod-loader-patch-structure 等）
