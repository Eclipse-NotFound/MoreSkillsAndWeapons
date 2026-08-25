# 当前开发状态

> 频繁变化，不代表长期游戏事实。更新日期：2026-08-18

## 版本
- 模组版本：1.0（功能完整，全量实机验证通过——用户 2026-08-18 确认"所有项目都
  验证完成"）；release SWF 16246 字节（D-044，git `910cdce`）。
- 唯一未闭环节：**D-044 魔法冲刺腾空补重力**的最终落感确认（已修复，待玩家
  一次实机确认；诊断读 `dashPoseGrav`）。
- 分发包：`dist/MoreSkillsWeapons_mod_v1.zip`（D-045）已生成。

## 已完成
- [x] 全部功能实现并通过实机验证：
  跳弹（D-013~D-025）/ 可编程榴弹炮 mswglau（下坠/撞墙/初速度/反弹 + SATS 实时
  弹道）/ 蹲梯举枪（Shift+W，D-026~D-036）/ 迁移技能手雷击落+疾跑切枪
  （MSWProjHits/MSWSwaprun，D-033）/ 散布恒定（D-034）/ **魔法冲刺保持蹲趴姿**
  （MSWDashPose，D-037~D-044）/ 设置面板（哔哔小马设置页 + F6 浮层，ROWS=12）。
- [x] git 仓库：功能相关提交 D-037~D-045（`dd0b7e5`…`910cdce`），工作区干净。
- [x] shared-knowledge 沉淀（2026-08-18）：新增 `entities/facts/player-pose-states.md`、
  `weapons-projectiles/facts/magic-dash-kdash.md`；增强
  `rendering/facts/player-vis-anim-pipeline.md`（姿态分支门/空中无 isSit）、
  `knowledge-validation/facts/diag-sampling-rules.md`（flush 同步 I/O）、
  `knowledge-validation/facts/modding-interop.md`（D-039 实证）。
- [x] 分发包（D-045）：干净 1.02 pfe.swf（FFDec importScript 定向替换 MainFE，
  仅 `loadMSWMod()`，已反编译验证）+ 模组 SWF + README；`dist/` 已入 .gitignore。

## 待办
- [ ] D-044 重力补回最终实机确认（蹲姿冲刺腾空应抛物线下落，悬停感消除）。
- [ ] 分发包发送（用户分发；可选先在本机用干净 pfe.swf 单独回归一次）。
- [ ] 跳弹/举枪等接入游戏技能系统（用户此前要求延缓，未做）。

## 当前 bug / 已知限制
- **趴姿（lurked）分支尽力而为**（D-039 后 public-only 约束）：lurked/lurkX/
  lurkBox 均 internal 不可写——冲刺后位移>10px 会站起回归；box 趴伏可能被
  box 清理。蹲姿分支无此限制（完整支持）。
- 发枪可能重复 +12 发 gren40（读档时序，可接受）。
- DLC/pfe.swf、pfeUI.swf（1.03/1.04）未合并本模组 loader（如需支持按 D-010）。
- 诊断读取法：`%APPDATA%\pfe\Local Store\#SharedObjects\
  mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol`
  （紧凑 AMF 格式：键长度字节 L=2n+1 + n 字节 ASCII 键名；值 04=U29 整数 /
  05=double / 03=true / 02=false / 01=null；diag 是 AMF3 对象）。
  dashPose*：Cast/EntrySit/EntryLurk/F/Pin/Exit/Grav；kdashSeen；lurkProbe*。

## 下一步
1. 玩家确认 D-044 后，若满意即可分发（dist zip）。
2. 如需 DLC 支持、技能系统接入、或把发现提升为 facts，见 HANDOFF §4。
