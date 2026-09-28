---
domain: rendering
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产候选五档普通弹/彩虹弹原生像素对照、历史曲线、真实时停/回放、跳弹/绕障和既有功能回归。"
date-updated: 2026-09-28
---

# v1.15.2：恢复原版曳光并沿智能弹道弯曲

用户在检查报告后明确要求「请按原版修复曳光并实装」。基线539207b包含完整v1.15.1眼位及聚焦功能；原故障与红色复现见smart-tracer-20260928.md。

## 实现与原因

- 新增MSWSmartTrail，仅负责视觉。按实际visualBullet/visualRainbow类缓存第一帧的原尺寸透明贴图，保留亮芯、颜色、宽度与透明渐变；不手工配色。
- 保存多步实际飞行位置及累计弧长，只留绘制需要的尾段；小于0.5px的相邻样本合并但保留累计长度。曳光按原版max(1,vel/100)长度，沿曲线贴图；第一步历史不足时沿初始切线向后补足，与原生出膛曳光长度一致。
- 绘制样本约每2px一段，上限512；由原生run碰撞样本提供轨迹。运动、目标选择、原生伤害、寿命和制导预算未改变。
- 原直线视觉scaleX暂置0，保留visible供时停记录读取；碰撞/移除/脱离制导时释放曲线并恢复原显示。原生撞击已经改过的缩放值不覆盖，原生第二帧撞击图保留。
- 模组入口版本1.15.2-native-tracer，无新增设置，已有参数保留。

## 像素校准过程

1. 初版原生贴图+曲线恢复了尾长，但2倍采样、UV 0..1仍使亮芯变软、积分光量约117.5%。未安装。
2. 原尺寸采样单独改变后约120%，未通过新增的原版光量/配色断言。
3. 修正UV跨度再附加半像素偏移能恢复总光量，但亮芯位置仍偏，配色断言仍失败。
4. 最终使用原尺寸纹理、横UV上限W/(W-1)、纵H/(H-1)，无半像素附加偏移；保持原像素间距。五档原版对照全过。该结果限本机AIR绘图路径，公共经验见shared-knowledge/rendering/discoveries/native-tracer-curved-texture.md。

## 准确候选与验证

固定候选`build/out/smart-tracer-fix/final/MoreSkillsWeaponsMod.swf`，源码冻结同目录src；63443字节，43生产定义，不含探针或原生宿主存根。SHA256：

`36B9C19193D231C99DB02BBF9CCF9F801ECA81C5347AD01E9FD961ED4E67B474`

当前根宿主SHA256 `C631CBF3511B6EE303F533D08D51511FE0EB702F43E5DB17F5241D8576C64867`；相对前次诊断宿主已由其他工作变化，本轮从实际根application.xml入口复制当前宿主，未替换本体或清单。像素及后续回归均使用此宿主。

| 场景 | 结果 |
|---|---|
| 原生像素/生命周期 | 49条PASS（含总结）；5/20/60/100/160速度可见长度差0–1px，积分亮度98.75–99.33%；峰值约251对原版253；彩虹弹积分98.82%、配色保留 |
| 连续低速与曲线 | 60物理步均保留88px，无finish/prune闪断；前25–75px历史曲线170/170采样点可见；制导停止恢复原图，撞击保留原图第二帧 |
| 自适应/跳弹/绕障 | 24项通过，实际扣血、狭窄通道、跳弹继承、到期恢复；64高速弹6组26/92/29/138/30/182ms（交替关闭/打开自适应，不等于日常帧率） |
| 实际Sandevistan | 真实热键、三次p9mm开火；慢速与回放曲线显示样本21/3；冻结预算、A/A/B目标与逐发半径、回放实际伤害、正常世界恢复通过 |
| 聚焦/多锁 | 87项，实际霰弹/跳弹/死亡等待/遮挡/设置/真实伤害均通过 |
| 激光回归 | 199条PASS，真实保存/comLoad后装备开火、辅助与完整舞台光束通过 |

入口分别为`test-smart-tracer.ps1`、`test-adaptive-radius-production.ps1`、`test-focus-sandy.ps1`、`test-focus-production.ps1`、`test-laser-reload.ps1`，均传入同一固定候选。证据在`build/out/smart-tracer-fix/`的native-pixels/adaptive/sandy/focus/laser子目录；原版和曲线两张PNG已查看。

启动检查首次100秒只到600帧，尚未满足900帧/设置入口门槛，当时未部署。脚本增加可选TimeoutSeconds并保留全部断言，单独补跑通过：版本1.15.2、900帧、ModSettings-connected、tabOn=1，无模块错误。证据startup-final/install-smoke.json。

## 发布与边界

2026-09-28 08:23已安装，正式release文件SHA256与上述准确候选一致；回执build/out/smart-tracer-fix/installation.json。只替换本模组SWF，未操作用户运行中的游戏、配置或真实存档，安装后按用户约定只核对字节。用户保存并重启游戏生效，无新增开关。

备份`release/MoreSkillsWeaponsMod.before-v1.15.2-native-tracer-20260928-082342.swf`为v1.15.1/88177481…；关闭游戏后将其复制为MoreSkillsWeaponsMod.swf并重启即可回滚。安装首次校验脚本碰到PowerShell只读Host变量，在任何替换前退出；已改为settingsHostPath并核验后完成安装，不涉及生产代码修订。

首段向后补足为原版曳光显示语义，不意味着子弹真实飞过补足段。逐帧历史保留可用于时停，但未认证所有弹型、窗口缩放、联机、DLC或“时停预演+跳弹+智能”三者组合。原native普通/彩虹弹已校准，曲线像素仍允许栅格化的微小差异。
