# 智能弹道平滑：2026-09-20

## 复现与原因

用户反馈普通射击、时停/回放均能看到拐点与长直线。以 42a19bb 的源码快照、原版 1.02 Bullet 和 speed=160 的射击复现：单步先转 29.2488°，接下来 160 px 共线，原版碰撞细分并不重新转向。`test-smooth.ps1` 初次实际运行得到 FAIL。另一个放大因素是 Bullet.step 把 visualBullet 的直线曳光按 vel/100 拉长。

## 实现

- MSWSmartMotion 保留原 Bullet 身份，将一步分为不大于 6 px / 3° 的小段（最多 256 段），每段重新计算追踪方向并调用原 Bullet.run。追踪曲率随距离收敛，不在某步突然对齐射线。
- 原生碰撞、护甲、穿透、水体、伤害均继续由 run 执行。运动前只加一次 ddx/ddy；原 Bullet.step 仍执行一次寿命、爆炸与对象清理。
- 已运动但未碰撞的弹丸只在原生运动块期间暂置 babah。链尾一次性节点恢复活弹标记，随后自移除。保留 Bullet 身份是为了兼容 Sandevistan 的原对象伤害暂存表。禁止把时停暂存的零伤害擅自补回。
- 普通时间、慢步和回放使用相同积分。回放链尾沿用唯一的 fe.weapon.MSWSmartReplayStep；正常链尾不落入时停的弹丸记录过滤器。
- 曳光取真实经过的位置，保留原图的小弹头；命中、移除、关闭、换场景或预算到期清理曲线。不是画一条绕墙但碰撞仍穿墙的装饰曲线。
- 智能跳弹使用最后两个真实运动点判断撞入墙面；普通跳弹仍用原来的直线重放。
- 设置参数及默认值不变。诊断新增 `smartMotionVersion=1.1-smooth`。

## 隔离实测

全部为独立 AIR 应用 ID、隐藏窗口；不操作用户 pfe 实例或存储。早期从 42a19bb 抽取 src，隔离并发的设置中枢/HUD 工作；其后用当前组合复核。

- 同一 speed=160 场景：最大方向跳变 0.57898°，最大共线段 5.92593 px，总长仍 160 px。
- 原 Bullet.step 不重复移动；liv 100→99、dist=160、链尾恢复 babah=false。
- 曳光截图 `build/out/smooth/curve.png` 已检查，曲线使用原显示层坐标，无长直线贴图遮盖。
- 真实 80×80 地形箱绕行并扣血；转速不足真实撞墙；镜面反弹和剩余制导预算继承通过。
- 0.1 秒制导正好三个物理步，原生寿命扣三次；到期恢复原飞行和显示；关闭后无曲线残留。
- 64 发高速弹均只移动/计龄一次；批量耗时随进程负载记录在 results.txt，不能用此压力场景宣称稳定帧率。
- 42 项智能规则与 315 项跳弹规则通过。
- 实际 Sandevistan 副本：实际热键、三次枪械开火，冻结显示帧不扣预算，慢步按物理步扣预算；回放匹配、旧弹预算保持、实际扣血、退出状态通过；观测慢步/回放的曲线最大相邻方向差 0.12692°。

回归命令：`build/test-smooth.ps1`、`test-smart-unit.ps1`、`test-ricochet.ps1`、`test-smart.ps1`、`test-smart-sandy.ps1`。smooth / sandy 支持 SourcePath，便于从固定源码快照复现。所有 Smoke/Probe SWF 仅供测试，不部署。

## 边界和排障

- 第一版尝试访问 Bullet.vse，被原游戏 protected 边界拒绝；已改用公开 in_chain/babah/liv/isExpl，并添加运行时错误断言。修复前不曾部署。
- 并发设置中枢迁移后，旧探针从本地登记表查找 Sandevistan 会等待超时；改查公共 api.getPages。测试页面选择走公共 selectPage，保留实际控件验证。
- 仍受有限转弯半径、局部寻路和真实地形碰撞约束；不保证贴墙高速弹必中。时停预演 + 智能 + 跳弹三者的伤害暂存限制仍在，未声称解决。
- 本轮不修改根目录/DLC 游戏 SWF，不修改其他模组。并发任务可能更新宿主与设置/HUD，安装以当时已验证组合及备份为准。

## 部署记录

- 最终生产版本 `1.5.2-smart-smooth`，28285 字节，SHA256 `695109FDCD702CEFBCBB554748695F87740DA93F7654187807A1735D5D4961E9`。候选从已提交的 v1.5.1 src 快照加本轮平滑文件编译，排除并发任务尚未发布的菱形 HUD。反编译确认无测试探针/原版 Pt 存根/新 HUD 类，入口 public static init 正确。
- 固定候选 `test-smooth` 全过，64 发 160 px/步完整物理+曳光样本 29 ms。当前组合的完整 SmartProbe 控件/锁定/特殊霰弹/绕障回归通过；当前 ModSettings + Sandevistan 组合回放通过，峰值方向差 0.12946°。
- SmartProbe 先因新设置中枢重开时选回 msw 页而失败，修正探针重新 selectPage(msw-smart)，保留真实控件断言后通过。一次隔离开档出现原生 #1009，未进入业务；后续同场景启动及最终生产启动正常。
- 备份 `release/MoreSkillsWeaponsMod.before-v1.5.2-20260920.swf` 为 v1.5.1，26957 字节，SHA256 `4783CC1943CB8CC58DB4610144FB959E37E3A41C652E82BFE714C74E3A30A8A1`。回滚只复制该备份覆盖当前模组并重启；本轮未改变 loader/ModSettings。
- 安装前后宿主 SHA256 `9A81430D775209E37E8E7FD54414057995E0680671445F38797623865B5A699A`，ModSettings SHA256 `5BD830A63F42130EF56E9C24C0E95B77B9871640B53D5CB4AA5B51E363894B5C`，保留并发任务安装的版本。
- `test-installed.ps1 -ExpectedVersion 1.5.2-smart-smooth` 通过：正式 SWF 同字节副本，frames=900、modAPI=ModSettings-connected、tabOn=1，无 lastErr/smartError。用户实例与真实存储未操作，重启后生效。
