---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "95条规则、16项真实设置、最终字节22项平滑/52项多锁/39行激光读档、实际时停逐发继承、安装前后900帧"
date-updated: 2026-09-23
---

# 可调平滑弹道模式

## 决定与实现

用户Q1=B命中优先、Q2=B偏短路线圆滑过弯、Q3=A全部智能转向、Q4=A开关加程度滑块，并回复「开始实现」确认整套方案。默认关闭；程度0–100%、步长5、默认50%。两项在出膛取快照，跳弹与时停回放继承，0走原运动分支；半径、转向上限、速度、寿命、伤害及制导时限不改变。设计见../../design/smart-smooth-mode.md。

原模式已有小段曲线与真实碰撞，但没有限制转向速率的连续变化。新MSWSmartSmooth沿既有短路线做有限前瞻，再渐进更新转向速率；真实碰撞仍由原生Bullet.run处理。短弧预测发现危险、近目标来不及转回或制导即将结束时可临时放宽平滑，急转仍不越过原转向上限。跳弹先镜面反射，再清零转向历史重新开始平滑。

平滑速率的时间常数为0.9+3.9×程度比例个物理步，以小段实际推进比例计算，不用显示帧计时。预测每4小段一次、长度18–72px、最多8段；危险时最多6个转向候选。原有限局部寻路预算不增加。强度越高可能走更宽的弧线、需要更多紧急补救；50%为当前实测选择，不表示所有战斗中最优。

## 验证与本地证据

以下路径相对本模组目录。out文件可重建；所有游戏测试使用独立AIR ID、隐藏窗口及独立存储。

| 范围 | 证据 |
| --- | --- |
| 规则与配置 | build/out/smart-tests/results.txt：95条PASS。旧配置补默认、存储/恢复默认、上下限、转向量变化、不同程度响应、紧急墙体/近目标仍受原上限；原锁定、多锁、路线和半径规则通过。 |
| 设置与单目标 | build/out/smart/results.txt：真实16项控件完整显示，平滑开关即时保存、程度关闭面板保存、恢复默认、F6两项操作及原单目标/遮挡/保持/跳弹/霰弹回归通过。settings.png已检查。 |
| 准确生产平滑 | build/out/smooth-mode-production/results.txt：22条PASS。关闭与0%轨迹逐点完全相同；移动目标在关闭/50%/100%均实际受伤；0/50/100%绕80×80箱命中；50/100%狭窄通道命中；不可避免撞墙与镜面跳弹、重置转向历史/继承设置及预算、到期原动量、64弹同速度同计龄和模块错误检查。 |
| 平滑与多锁 | build/out/multi-lock-production/results.txt：最终F18097A6...生产文件52条PASS，平滑开启，9弹在三目标间各分3发、真实5弹粒特殊霰弹、真实伤害、独立脱锁/保持/死亡、切换与菱形。 |
| 实际时停回放 | build/out/sandy-smooth/results.txt：真实三次开火分别录制平滑25/50/75%、半径30/40/50%及不同目标；回放前关闭平滑、多锁并清空锁定，三发仍精确对应。旧弹预算、真实回放伤害及世界恢复通过。 |
| 最终激光读档 | build/out/smooth-mode-reload/results.txt：最终生产文件39行PASS；真实comLoad后背包/手持/延迟装备同为扩展武器，Pip/F6调试开关、眼位、6秒失明、零生命伤害、耗弹2和自然战斗通过。未暂停EXIT_FRAME完整舞台光束差分7帧可见、峰值174像素。 |
| 正式构建 | build/out/smooth-mode-final/link-report.xml：34个模组定义，宿主原类外置，无Smoke/Probe。 |
| 安装前后 | build/out/smooth-mode-final-startup/install-smoke.json、build/out/smooth-mode-installed/install-smoke.json：同一最终指纹均900帧，ModSettings-connected、tabOn=1、运动1.3、HUD3、激光4，无lastErr/smartError/laserError。 |

移动目标在第6、12物理步折返的对照中，前13步的相邻小段转向增量最大变化：关闭0.005424885567510557 rad，50%为0.00007534506324687051，100%为0.00003754012582656008。此值针对该夹具的普通追踪区间，不包含之后接近目标的紧急补救，不能外推全部战斗的改善比例。轨迹原始数据smooth-traces.json、smooth-box-0/50/100.json；build/tools/plot-smooth-mode.py将真实坐标绘为trajectory-comparison.png，未重算或伪造轨迹。

同一最终生产构建、同进程交替、无截图的64发×160px/步样本，关闭27/28/26ms、开启47/47/48ms；全弹仅推进/计龄一次。该压力样本显示额外预测有成本，不是日常FPS保证。方法参照已核对KB-000056的编译一致/交替输入/分离取图原则，不采用其他模组的具体性能数字。

## 过程中更正

- 首轮设置与F6检查已通过，但后续900ms锁定断言失败。旧探针只等待Timer次数，未等待测试驱动按帧自动打开Pip；补上diag.auto==pip-opt-open门控后同样玩法代码通过完整流程。没有通过改锁定机制迁就测试。
- 并发激光任务修改到一半时，编译因HUD新接口未就绪失败；改从46d0e64冻结基线加本轮7个源码文件，排除未完成激光改动。首个固定候选BEB759FB...已通过22项平滑、52项多锁、生产激光开火及900帧启动。
- 安装前发现正式文件已被该任务更新为激光4-reload-debug，原指纹断言主动停止，尚未备份或替换。最终以其已安装版本对应的build/out/laser-debug/src为基线合入完全相同的平滑实现，重新检查组合产物，避免覆盖读档修复和调试开关。
- 95条规则、真实16项设置、实际时停回放先在激光3冻结基线上完成；最终合并只改变激光组件及其设置，智能实现保持一致。最终字节另跑准确生产平滑、多锁、激光实际读档及安装前后启动；不把早期候选的指纹当最终安装证据。

## 最终候选与安装

已安装release/MoreSkillsWeaponsMod.swf，与build/out/smooth-mode-final/MoreSkillsWeaponsMod.swf同字节：45014字节，SHA256 `F18097A6681993E1B894B2B25B31781DBD2B9407FED8F6F6F45CFDB9A7AB7C05`。核心1.8.0-smooth-mode、运动1.3-smooth-mode、HUD3-multi-lock、激光4-reload-debug；保留多锁、视野外保持、激光眼位/原版光束/读档修复及新增激光诊断。最终冻结源码与当前src逐文件统一换行后相同。

安装前核对正式旧指纹，再备份为release/MoreSkillsWeaponsMod.before-v1.8.0-smooth-mode-20260923.swf：43654字节，SHA256 `04A7E69F62044840F9BCA112E235632546096FB9C360C6F5869446DAF4E1E0B9`。恢复此备份只撤销本轮平滑弹道，保留多重锁定和最新激光修复。替换后须重启真实游戏；本轮没有替用户关闭游戏。

根pfe.swf保持 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`；清单保持 `4953B682AD9E18C212A0BCB30464AD905E1EB4D39610DC0366230E91F9EEB785`；ModSettings保持 `5BD830A63F42130EF56E9C24C0E95B77B9871640B53D5CB4AA5B51E363894B5C`。测试使用当前宿主副本。

既有「时停预演 + 跳弹 + 智能绕障」组合未通过边界仍保留；本轮不保证封闭/复杂路线必中，也没有验证所有DLC、联机与长期战斗。只改本模组；真实存档和用户游戏进程不操作。
