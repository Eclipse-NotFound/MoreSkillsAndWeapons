---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "优化生产SWF经真实保存/读档、原生开火、近中远距离与二维速度、重叠选敌、实际Pip/F6、同URL旧版配置升级回退验证；新配置124行PASS，旧配置129行PASS。"
date-updated: 2026-09-23
---

# 激光身体选敌与移动保底辅助

用户确认 design/laser-body-assist.md 的完整方案后实现。已安装 **v1.10.0-body-assist**，激光组件 **5-body-assist**。本记录只验证辅助增强，不将其他任务正在开发的透窗路线或自适应半径列为本版能力。

## 实现与参数

- 普通射击先选准星内的原生身体矩形；重叠按眼睛到准星距离确定唯一所指目标，再检查射线。背面、护盾或遮挡使所指目标无效时，返回无辅助，原手动射线照常射出，不转选邻居。
- 没有直接指到身体时，在可实际致盲的外围候选中按身体距离、眼距排序。取消原最大修正角度门槛；HUD眼圈与开火使用同一选择器。
- 外围范围随 `sqrt(dx²+dy²)` 线性缩小：默认速度0/5/10对应60/45/30场景px，超过10仍30；直接指身体不受该收缩影响。
- 新配置键：laserAssist=true、laserBodyRadius=60（0–160/4）、laserAssistFloor=50（10–100/5）、laserAssistSpeed=10（1–40/0.5）。激光页从12项变13项，Pip/F6共用，旧角度项退出界面。
- 首次升级只继承旧laserSpeed，其余新参数独立初始化；保存与恢复新版默认都保留旧laserRadius/laserAngle/laserSpeed。新版设置一经保存，之后不再用旧值覆盖。普通辅助关闭时手动命中和SATS选眼仍有效。
- 原零生命伤害、正面判定、首个身体/箱体/地形遮挡、原版光束与延迟装备newWeapon修复保留。

## 自动化与图像证据

全部实例使用唯一AIR ID、隐藏窗口与独立存储。真实游戏和真实存档未被操作。

| 验证 | 结果 | 本机证据（相对模组根） |
| --- | --- | --- |
| 正式优化编译/链接 | 35定义，宿主原类及Smoke/Probe未嵌入 | build/out/laser-body-assist/link-report.xml |
| 全新配置、真实装备→保存→comLoad→延迟装备→开火 | 124行PASS，含最终成功行 | build/out/laser-body-assist/fresh/results.txt |
| 定制旧配置升级/回退/重新升级及同一实战套件 | 129行PASS，含最终成功行 | build/out/laser-body-assist/reload/results.txt |
| 激光机制与实际Sandevistan时停/回放 | 251行PASS，含最终成功行；使用冻结源码编译的调试测试版 | build/out/laser-body-assist/laser/results.txt |
| 准确生产字节多锁实战 | 52项 + 最终成功行 | build/out/laser-body-assist/multi-lock-production/results.txt |
| 准确生产字节豁免设置/31类过滤/实战 | 312项 + 最终成功行 | build/out/laser-body-assist/exclusion-production/results.txt |
| 安装前后启动 | 各900帧、ModSettings-connected、tabOn=1，无lastErr/smartError/laserError | build/out/laser-body-assist/{preinstall,installed}/install-smoke.json |

身体射击使用原生Weapon.attack/step：目标X=380/650/1050，准星放下半身，玩家速度分别(0,0)/(10,0)/(0,-10)/(6,8)。每枪扣2电池、只发射一次、目标生命不变并失明6秒。近身用例修正角度实际超过旧5°门槛。

外围测试检查60/45/30精确边界及边界外0.01px；另测速度(30,40)、半径0仍可指身体边缘、最低比例100%、手动开关、SATS独立分支。多目标检查直接身体优先、身体距离优先、同距按眼距、重叠与遍历顺序无关、无效所指目标不改投、无直接身体时跳过无效外围候选。敌对/隐形/不可见/死亡/剧情禁用筛选均保持。

HUD用实际渲染像素验证有眼圈、无效时清空；Pip实际CheckBox/ScrollBar和恢复默认按钮、F6四项修改、保存重载通过。已人工查看body-assist-settings.png及F6 laser-settings.png，13项均在屏内；截图与结果同目录。Pip刚重建的组件皮肤尚未推进显示帧，截图用于核对标签布局，控件行为以真实事件断言为依据。

未暂停World/Location开火时，临时隐藏单个激光对象并比较完整舞台像素：全新配置8个显示帧/峰值475像素，升级配置11帧/峰值476像素。live-laser-stage.png可见原版红色激光与“已失明”提示；显示帧数依刷新/世界步速率变化，不作为固定寿命。敌人失明期间未重新发现玩家，计时随实际行动推进。

## 有价值的失败与边界

1. 初版升级测试将旧SWF改名成LegacyConfig.swf直接加载。SharedObject默认路径包含调用SWF文件名，两版落入不同配置目录，导致迁移断言失败，不能据此判定产品迁移错误。
2. 尝试在AIR内替换app:/下的隔离资源，被fileWriteResource拒绝；已有公共知识mod-log-channel.md明确该限制。最终由外部测试脚本响应独立存储中的握手标记换版，两版从同一URL、兄弟ApplicationDomain加载；旧版只使用Config，不初始化整个旧模组。前后均校验候选SHA256。
3. 最初重叠夹具把期待选中的眼睛放在另一个身体后面，真实第一接触目标规则使其不可达。保留这一应返回null的用例，新增前方眼睛可达的站位，并证明备用眼睛可达时仍不会在所指眼睛被盾挡住后改投。生产代码未因这些夹具问题改变。

以上真实测试覆盖原版1.02指定场景，不代表全部敌人变体逐帧、长期战斗、联机、DLC或全部模组组合。身体框不是逐像素剪影；枪口越过目标、竖直射入以及其他身体遮挡仍可能导致手动原方向发射。这些保留的几何限制已测，不将瞄中身体直接当作眼部命中。

## 发布与回滚

- 正式SWF及冻结候选：47483字节，SHA256 `132BC390598296BD6237B3991D762F587CF66466EBB907334EA7CF972277F3CE`。冻结源码/产物：build/out/laser-body-assist/src、MoreSkillsWeaponsMod.swf。
- 保留HUD 3-multi-lock、智能运动1.3-smooth-mode与31项单菜单豁免。安装时主src另有同期透窗路线修改，未编入本冻结候选；不得误称所有主src都与本版一致。
- 回滚：release/MoreSkillsWeaponsMod.before-v1.10.0-body-assist-20260923.swf，47213字节，SHA256 `A56E3B46D22CBC5CECCC086AA86C5E58917EC0FA5FFF4D3178DAABF02A49F659`；换回正式文件名并重启恢复v1.9.1角度辅助，保留其旧参数。备份创建前检查不存在，安装前检查正式基线未变。
- 根pfe.swf SHA256仍 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`，未修改游戏本体、清单、ModSettings或其他模组正式文件。
