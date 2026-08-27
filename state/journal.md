# MoreSkills&Weapons —— 开发日志

> 协议见 GOVERNANCE.md §8：只追加不改写，**新条目插在最上面**。

## 2026-08-27 外置记忆迁移

- 由 state/current-status.md + state/HANDOFF.md 拆分迁移（原文在 git 历史）：现行状态 → state\MEMORY.md；state\design\design-冲刺保持趴姿.md 移至 design\；两份迁移报告浓缩为下方 journal 条目后删除。
- HANDOFF 中"已验证游戏机制清单"与"诊断计数器清单"暂以 git 历史为准，后续视需要沉淀入 shared-knowledge 或本文件。

---

## 开发历程（按 git 提交日期，新在上）

### 2026-08-26 交接刷新
- HANDOFF 补全（§0/§2/§4）+ current-status 更新为 v1.0（D-044 唯一待确认）。

### 2026-08-18 v1.0 收尾：冲刺姿态全链路 + 分发包（D-035~D-045）
- D-035/D-036：举枪排查——修复"先 Shift+W 再蹲下"流程失效 + 移除按键路径高频 SharedObject.flush（举枪卡顿）。
- D-037~D-044（八轮迭代，设计见 design/design-冲刺保持趴姿.md）：魔法冲刺保持趴姿/蹲姿。**D-039 关键根因**：internal 字段（lurked/lurkX/lurkTip/lurkBox）bracket 访问抛 #1069 被 catch 吞掉 → 组件每帧死亡，两轮"无效果"——游戏密封类 internal 一律不可访问（已回馈 shared-knowledge/modding-interop）；此后引用游戏字段必须先 grep "var <字段>" 确认 public。D-040~D-043 逐一修逐渐站起/抽搐/初始化帧 bug/滑行后期起身；D-044 补腾空重力（待玩家最终确认）。
- D-045：分发包 dist/MoreSkillsWeapons_mod_v1.zip（基于 pfe_1.02_before_msw_merge 备份用 FFDec importScript 生成干净 1.02 pfe.swf，仅本模组 loader，已反编译验证）。
- shared-knowledge 沉淀：新增 player-pose-states / magic-dash-kdash，增强 player-vis-anim-pipeline / diag-sampling-rules / modding-interop。

### 2026-08-17 建仓与首批功能（D-001~D-034）
- 初始提交：跳弹 / 可编程榴弹炮 / 蹲梯举枪 / 手雷击落 / 疾跑切枪。
- D-013~D-025：跳弹大量反弹问题修复链；D-026~D-032：举枪技能演进（D-031 改键 Shift+W；D-032 修复失效三根因：heldShift 事件顺序 / 吞键 stopImmediatePropagation 失效→改写 Ctr 状态 / sol 配置误存）。
- D-033：时停期放行迁移技能（与 Sandevistan 共存）；D-034：散布异常排查（无污染）+ mswglau 散布恒定。
- **Sandevistan 技能迁入**（手雷击落 MSWProjHits + 疾跑切枪 MSWSwaprun，面板第 7-10 行；迁移报告与审核结论原文在 git 历史：state/迁移报告-2026-08-17-Sandevistan技能迁入.md、state/MIGRATION-Sandevistan-swaprun-projhits.md）。共存约定：MSWU.inGameplay() 含 onPause——时停/回放期不介入；已知风险：时停期间切枪不生效（共存取舍）、旧 config.txt 值不迁移。待实机复测。
- pfe.swf 合并（追加本模组 loader，备份 pfe_1.02_before_msw_merge_20260815.swf）。
