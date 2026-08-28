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

- **v1.2（2026-08-28 晚）**："模组"按钮迁入 Opt 页（主菜单页）子按钮栏（载入/保存/选项/控制/记录 旁），设置行改原版控件（visPipOptItem 自带 CheckBox/ScrollBar 滑块）；已部署（release SWF 19365 字节），冒烟通过（ver=1.2-optpanel / tabBuild=1 / 心跳正常 / 无 lastErr）；**待玩家实机点击验收**。
- v1.0（910cdce）：全部功能实机验证通过（用户 2026-08-18 确认）；dist zip（D-045）就绪——注意 dist 内是 v1.0 SWF，v1.2 验收后需重打包。
- **2026-08-28 实机诊断复核**（玩家迁移新机后持续游玩中，kdashSeen=399）：D-044 补重力实机触发 6 次、手雷击落 projHit/projBoom=2/2、ricochet 反弹 159 次——主力功能实战活跃无回归（详见 journal 当日条目）。
- 回滚：`git checkout 910cdce -- release/MoreSkillsWeaponsMod.swf`。

## 4. 正在进行与卡点

- **模组面板实机验收**：哔哔小马 → 主菜单页 → 点"模组"按钮 → 原版控件行显示/复选框与滑块可调/点其他子按钮正常退出（诊断读 tabOn/tabOff）。
- **D-044 魔法冲刺腾空补重力**：机制数据已佐证（dashPoseGrav=6），只差玩家对落感的**主观**确认。
- 举枪/疾跑切枪：迁移换机后 SOL 重置，尚无触发记录——待玩家实机各用一次即闭环。

## 5. 已知问题

- **趴姿（lurked）分支尽力而为**：lurked/lurkX/lurkBox 均 internal 不可写——冲刺后位移>10px 会站起回归；蹲姿分支完整支持（已知限制，见 D-039）。
- 发枪可能重复 +12 发 gren40（读档时序，可接受）。
- DLC/pfe.swf、pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010 流程）。

## 6. 下一步（优先级排序）

1. 玩家实机点一次"模组"按钮（主菜单页内），v1.2 验收（控件观感/滑块手感）；
2. 玩家确认 D-044 落感（机制数据已佐证）+ 举枪/疾跑切枪各用一次 → 全闭环后重打 dist zip（含 v1.2）；
3. 视反馈微调（按钮位置/控件布局）；如玩家满意可启动"接入游戏技能系统"设计（跳弹/举枪）。

## 7. 深入了解

- **开发历程**：state/journal.md（含 Sandevistan 技能迁入与 D-037~D-044 全链路摘要；迁移报告原文在 git 历史）
- **决策**：decisions/decisions.md（D-001~D-045；关键索引：D-001 动态架构 / D-002 帧后重生 / D-007 构建链 / D-010 pfe 合并 / D-016 F6-only / D-026~D-032 举枪演进 / D-037~D-044 冲刺姿态 / D-045 分发）
- **设计**：design/features.md、mechanics-notes.md、skill-aim-sit-ladder.md、design-冲刺保持趴姿.md
- **源码结构**：12 个 MSW*.as（入口/防御访问工具/配置/武器注入/子弹核心/SATS 弹道/面板/哔哔小马模组页签/举枪/击落/切枪/冲刺姿态）
- **诊断读取法**：`python build/tools/read_sol.py "%APPDATA%\pfe\Local Store\#SharedObjects\mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol"`——完整解析 AMF3 键值（格式规律沉淀在 shared-knowledge `knowledge-validation/methods/sol-diag-reading.md`）；diag 计数器跨会话累积、换机/换用户重置
- **构建/部署**：`cd build && build.bat`（Animate mxmlc）；部署只需替换 release SWF；改 loader 走 FFDec 定向替换（备份 pfe_1.02_before_msw_merge_20260815.swf）
- **共享知识贡献清单**：原 HANDOFF §6（bullet-wall-impact / explosion-blast-bullets / phisbullet-grenade-physics / runtime-weapon-creation / sats-trajectory-arc / pippageopt-overlay / mod-loader-patch-structure 等）
