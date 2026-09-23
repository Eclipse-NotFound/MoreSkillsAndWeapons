---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "1123条规则、289项准确生产豁免、52项平滑多锁、22项平滑物理、39行激光读档回归；安装前后启动检查"
date-updated: 2026-09-23
---

# 智能武器锁定豁免

## 规则与实现

第一批五组31项，普通地雷6项和机关装置8项按用户追加回答分别勾选。全部默认不豁免，单/多锁共用；肉食灵包括王，巢穴独立。完整范围与行为见 `../../design/smart-lock-exemptions.md`，实体ID证据见 `../discoveries/smart-lock-exemption-catalog-20260923.md`。

`MSWSmartExclusions` 以精确实体ID查表，避免UnitMonstrik共用类把鼠、蟑螂、蝎子混成一个开关。配置只存已知且为布尔true的键，旧配置与未知/错误类型值回落为空。五个Pip页与F6使用相同控件定义；F6明确选择本模组的八个页面，不受测试模拟页或其他注册页影响。

`targetAllowed` 增加表过滤，单锁未完成候选同步清空，多锁由原独立状态机移除目标。在途弹在物理推进检查资格、终止剩余制导，不改投；回放先消费原顺序记录再检查豁免，不让下一颗子弹占用前一颗的目标。没有修改伤害、原生碰撞或其他模组。

## 验证与测试边界

- `build/out/lock-exemption-work/build/out/exclusion-tests/results.txt`：1123条PASS，31项精确变种与类别间互不误伤、默认/保存/清洗、各页独立、清除候选不影响原有效锁定。
- `ExclusionProductionSmoke` 单独编译探针，仅加载准确生产SWF，不把源码与探针链接在一起。真实Pip31个复选框逐项派发CHANGE、重新读配置、点击各页恢复默认；F6前后循环；五页截图均已检查，最多9项，无截断。
- 对31个原生工厂生成的单位确认实际ID，并分别验证允许→豁免→允许。为隔离物种匹配，夹具统一存活状态、阵营与房间；这不代表自然场景中每个机关都始终满足原锁定资格。
- 在真实房间布置鼠、鼹鼠、掠夺者，验证未完成单锁取消、多锁跳过鼠、解除豁免重新计时、已锁状态独立移除、在途弹停止且不改投、单锁标记清除。测试为程序化布置，无真实存档。
- 回放补测使用原生子弹和时停握手（暂停录制→godMode回放→物理前后回调），检查豁免目标跳过且后续两发原目标不移位。这不是实际Sandevistan全程测试；该模组真实回放的历史验证见多锁、平滑弹道记录。

## 过程中的纠正

- 原测试夹具会在游戏启动后自动切Pip页。等600帧仍会与31项UI验收重叠，导致“普通地雷控件数”失败；改为等1100帧后完整UI验收通过，未改玩法来迁就测试。
- 测试自动注册Mock页，不能假定全局第4页就是本模组第一豁免页；按注册ID找页，F6也固定本模组顺序。
- 回放时显示帧不扫描子弹，扫描由物理回调执行；最初探针只调用frame导致未产生快照，补为真实物理前后入口验证。
- 本轮在独立git工作树冻结源码，先合入激光提交ea922ac，再合入平滑提交3fb7622。版本标记冲突统一为1.9.0，保留全部平滑字段与最新多锁探针。主目录与冻结源逐文件归一换行比较一致；合并后重编译并重跑最终字节，早期候选未部署。

## 安装状态

正式候选 `build/out/lock-exemption-work/build/out/MoreSkillsWeaponsMod.swf`，47050字节，SHA256 `15D7E3A56393D252656ADD2B1631F780CDA4EE6EB752A9AD3D12F286F5B48707`。核心1.9.0-lock-exemption、运动1.3-smooth-mode、HUD3-multi-lock、激光4-reload-debug；链接35个生产定义，宿主原类外置，无Smoke/Probe。实现提交0fc83b3；正式文件由该源码构建，构建后没有再改生产源码。

以下路径均位于上述工作树的 `build/out/`，场景回归全部针对该同一候选：

| 验证 | 结果文件 |
|---|---|
| 分类与配置 | exclusion-tests/results.txt：1123条PASS，在最终合并配置上重跑 |
| 豁免与设置 | exclusion-production/results.txt：289项PASS，包含最新组件标记和开启平滑时的豁免；五页settings-*.png已检查 |
| 多目标实战 | multi-lock-production/results.txt：52项PASS，平滑开启，三目标真实伤害、均分和霰弹、独立脱锁/保持/死亡与模式切换 |
| 平滑物理 | smooth-mode-production/results.txt：22项PASS，关闭/0%一致、追踪/绕障命中、碰撞/跳弹继承、预算与批量计龄；并发验收的耗时不作为性能比较结论 |
| 激光读档 | laser-reload/results.txt：39行PASS，真实comLoad后开火、调试、失明与未暂停完整舞台光束（7帧、峰值174像素） |
| 安装前启动 | startup/install-smoke.json：相同SHA256、900帧、ModSettings-connected、tabOn=1，版本/组件正确，无lastErr/smartError/laserError |

已安装。`installed/install-smoke.json`：从正式release复制同字节再次启动，900帧、ModSettings-connected、tabOn=1，核心与组件标记正确，无lastErr/smartError/laserError。替换前核对原正式F18097A6...，备份为 `release/MoreSkillsWeaponsMod.before-v1.9.0-lock-exemption-20260923.swf`（45014字节，完整SHA256 `F18097A6681993E1B894B2B25B31781DBD2B9407FED8F6F6F45CFDB9A7AB7C05`）。回滚时仅将此备份复制回正式文件并重启，可保留平滑、多锁与激光4，仅撤回豁免。

本轮未改根pfe.swf（B7824465...）、loader-manifest（4953B682...）、ModSettings（5BD830A6...）或其他模组/真实存档；不关闭用户游戏。用户须自行重启加载新版本。

原有时停预演+跳弹+智能绕障复杂组合的未通过边界保留；本轮回放豁免是物理握手模拟，不声称新跑完整Sandevistan联测，也未覆盖全部长期战斗、DLC、联机或剧情阵营变化。
