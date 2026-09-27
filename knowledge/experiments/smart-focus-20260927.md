---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "正式候选原样加载；真实Bullet、霰弹、Pip/F6输入及斯安维斯坦热键录制/回放。"
  - kind: decompiled-game-code
    game-version: "1.02"
    symbol: "fe.inter::Camera.calc; fe.inter::Ctr.onMouseMove1"
date-updated: 2026-09-27
---

# v1.15.0 多重锁定聚焦模式

用户Q1–Q10及完整方案均已确认，并明确要求实现后直接安装。正式文件57398字节，SHA256 `49944BA875ECFE2AAC847CD30C5B23A41D8367DAC0A8708D74CFDC02DE2682E0`，入口版本 `1.15.0-smart-focus`，HUD仍 `3-multi-lock`。安装回执：`build/out/smart-focus/installation.json`。

## 实现与边界

- `MSWSmartFocus`只选择已完成且强度大于零的锁定，不推进获取、不补满强度、不消耗轮换游标。身体框距离优先，重叠时中心距离优先，完全相等保留当前。
- `MSWSmartWeapons.scan`只在新弹首次登记时使用聚焦目标，普通轮换为后备；旧弹、跳弹和时停历史沿用出生快照。制导、速度、伤害、碰撞、破窗与自适应预测实现均未修改。
- 聚焦对象死亡设等待标志；仅活跃游玩期间发生位置变化的鼠标移动事件清除。输入处理先观察死亡再解除，兼容死亡与鼠标移动都发生在两显示帧之间的情况。镜头/敌人移动、菜单内输入不解除等待。
- 准星位置由屏幕鼠标及当前相机平移/缩放换算；输入回调直接用事件坐标，避免Camera.calc尚未更新w.celX/Y。新弹登记时使用当前cam.celX/Y换算，避免只依赖上一显示帧的选择。
- `smartFocus=false`、`smartFocusRadius=48`，范围0–200/步长4。Pip/F6共用定义，支持保存和默认恢复，旧配置只补缺项；0要求指中身体。智能设置由16项增至18项，HUD无聚焦色或外框。

## 验证（均为隔离存储与隐藏实例）

| 证据 | 结果 | 验证内容 |
|---|---|---|
| `rules/results.txt` | 159断言 | 独立获取、即时切换、边界/重叠、死亡等待、旧配置迁移/保存/默认、原多锁/玻璃/自适应规则 |
| `production/results.txt` | 87检查 | 正式字节真实Pip复选框/滑块/F6/保存；6发集火、真实特殊霰弹、旧弹和跳弹目标保留、死亡后轮流、菜单/镜头/敌人移动不解除等待、真实墙遮挡/弱锁保持/完全脱锁；随后原9发均分、实际伤害、霰弹分散、模式切换回归 |
| `sandy/results.txt` | 34条PASS加汇总，含逐帧预算重复检查 | 真实斯安维斯坦热键、前两发A/第三发B；回放前关闭聚焦/多锁并改参数，回放仍为A/A/B及30/40/50%普通、10/20/30%最低半径；真实伤害与世界恢复 |
| `laser/results.txt` | 199条PASS含汇总 | 正式字节实际保存/comLoad/延迟装备/开火、两方向眼区、辅助、护盾边界、失明与最终舞台光束 |
| `startup/install-smoke.json` | 900帧通过 | 正常manifest入口，版本1.15.0、HUD版本一致，ModSettings-connected、tabOn=1，无模块错误 |

以上路径均相对于 `build/out/smart-focus`。正式字节专项三个驱动加载同一49944BA8…候选；41个生产定义，主游戏存根外部链接，生产文件不含Smoke/Probe。`production/focus-settings.png`已检查新开关/范围文字与布局。驱动源冻结在test-source，完整候选源及清单在candidate与manifest.json。

未将测试断言数当成全部玩法认证：没有完整联机/DLC/全部敌人验证，没有重新测试历史“时停预演+跳弹+智能绕障”三者组合。输入实测使用真实Stage事件派发，不代表OS鼠标至显示器延迟测试；聚焦不保证所有障碍路径必中。

## 测试与安装过程中的纠正

1. 原SmartTests的“stable recovery grows gradually”在未改聚焦的已提交旧源也失败（baseline-rules/result/results.txt）。v1.14.2统一精细积分后，600px远目标在0.6倍率的中间半径耗尽256样本，不能作为“已确认可安全恢复”夹具。恢复场景改为120px，并先断言中间半径预测命中，再保留两次确认/渐进恢复断言；游戏预测代码未改。远目标预算未知的原断言仍保留。
2. 新时停外部驱动首次编译的全限定ApplicationDomain参数不被旧编译器解析，改显式import/短名；未改候选。
3. 首次安装的`File.Replace(temp,target,$null)`被PowerShell转换成空字符串路径并报错。正式文件仍为旧版，先在journal记录；复核旧版/备份/暂存文件后，以`[NullString]::Value`原子替换成功，再验正式哈希。

## 基线、安装与回滚

- 安装前正式v1.14.3：55731字节/`3ECFA98B9E8A58E14314F1295B994F54BF5605BCCEC2F82D796CA2FAF03745F9`。源基线提交3ee1260，包含已验证v1.14.4眼位修复，本轮冻结后叠加聚焦改动。
- 另一眼位任务当时的未提交MSWLaserEyes/MSWBlindAccess/MSWEyeFrames与测试夹具留在工作树，未覆盖、未纳入本次发布/提交。不能把当前整个脏树当成本候选的冻结源。
- 根application.xml仍指pfe.swf，根宿主SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`；未修改宿主、loader清单、其他模组正式文件或真实存档。
- 备份 `release/MoreSkillsWeaponsMod.before-v1.15.0-smart-focus-20260927-210640.swf`。回滚时退出游戏，将此备份复制为 `release/MoreSkillsWeaponsMod.swf`，再启动，回到v1.14.3。
- 2026-09-27 21:07安装并核对哈希。依据用户既有约定，隔离候选已验证，安装后只核对文件；未启动/关闭真实游戏。用户自行保存并重启生效。
