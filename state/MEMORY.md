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

- **v1.2.3（2026-08-29）**："模组找不到"根因已定位——SOL 计数器跨会话累积造成假绿（tabBuild 陈旧值），实机结构靠探针实证（页面视觉 visPipInv@165,72 ×9 ✓；汉化把主栏按钮类改名 ButPage_1536，类名/坐标不可硬编码）。v1.2.3 全部改结构特征定位 + null 安全 + 分阶段诊断（pipTab.stage0-5/tabStage/tabSnap/tabProbe）+ 文字面板兜底；全新 SOL 冒烟 *PAGE 探测全中。**待玩家实机复现**（开游戏 → 哔哔小马 → 主菜单页，看按钮/面板；诊断可全链路定位残留问题）。
- v1.0（910cdce）：全部功能实机验证通过（用户 2026-08-18 确认）；dist zip（D-045）为 v1.0，功能验收后需重打包。
- 回滚：`git checkout 910cdce -- release/MoreSkillsWeaponsMod.swf`。

## 4. 正在进行与卡点

- **模组面板实机验收**：主菜单页点"模组"按钮 → 原版控件行显示/可调/点其他子按钮退出（诊断 tabBuild/tabOn/tabOff/tabStage；若按钮仍缺，读 tabProbe 看页面视觉匹配）。
- **D-044 魔法冲刺腾空补重力**：机制数据已佐证（dashPoseGrav=6），只差玩家对落感的**主观**确认。
- 举枪/疾跑切枪：迁移换机后尚无触发记录——待玩家实机各用一次即闭环。

## 5. 已知问题

- **趴姿（lurked）分支尽力而为**：lurked/lurkX/lurkBox 均 internal 不可写——冲刺后位移>10px 会站起回归；蹲姿分支完整支持（已知限制，见 D-039）。
- 发枪可能重复 +12 发 gren40（读档时序，可接受）。
- DLC/pfe.swf、pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010 流程）。

## 6. 下一步（优先级排序）

1. 玩家重启游戏 → 主菜单页看"模组"按钮/面板（v1.2.3 验收）；若仍异常，读 SOL 的 tabProbe/tabStage/lastErr 即可定位；
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
