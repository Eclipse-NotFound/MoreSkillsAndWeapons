---
domain: rendering
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: decompiled-game-code
    game-version: "1.02"
    symbol: "fe.weapon::Bullet.step"
  - kind: runtime-experiment
    summary: "正式 v1.15.1 同字节副本与原生 Bullet 的五档速度像素对照，连续60物理步及长度/透明度单变量对照。"
date-updated: 2026-09-28
---

# 智能武器曳光偏弱：检查结果

后续：用户已要求按原版修复并实装，v1.15.2已完成。本文保留修复前的红色复现事实；修复与安装见smart-native-tracer-fix-20260928.md。

本轮用户要求检查。已复现并定位，未修改生产源码、正式 SWF、设置或真实存档；没有声称修复/安装。正式仍为 v1.15.1-eye-alignment，62289 字节，SHA256 `8817748176E17D3C32B286EB5780A818C580818393562973DA36EA3799F4425F`；源码基线 `1555ecb`。根宿主 SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`。

## 已确认原因

1. `MSWSmartMotion.advance` 每步重新创建 points，trails 条目也用本步 points 覆盖。因此绘制长度只等于当前物理步走过的路程，不累计历史曲线。原生 `Bullet.step` 对 spring=1 使用原图，vel>100 才按 vel/100 放大，否则保持 scaleX=1；不是按每步实际位移缩短到小于原图。
2. `MSWSmartMotion.finish` 把原图 scaleX 设为 0.04，以免原生直线遮住弯曲轨迹，再用固定 2px、0xFFDE91、alpha=0.7 的单色线替代。原图的亮芯、宽度轮廓和黄红透明渐变由此丢失。
3. 在本次隔离连续样本中，没有发现生命周期导致闪断：60 次真实 Bullet 物理步、300px 总位移，每步均有线；重复 finish/prune 不改像素，移除子弹正确清理。

这源于历史平滑绘制方案，而非此次聚焦逻辑或眼位修复。旧 `SmoothProbe` 只断言 scaleX=0.04 与曲线对象存在，未检查原版视觉保真，详见 smart-smoothing-20260920.md。

## 实测

真实根 pfe.swf + 正式模组的独立 AIR ID 副本；外部探针动态加载生产 SWF，未链接生产源码。相同原生 Bullet / visualBullet / p9mm / 初始方向，比较原生 step 与生产 advance → 原生 step → finish。只将可视对象放入独立显示容器以隔离背景，透明位图采样后同背景排版。

| 速度（px/物理步） | 原版可见长度 | 智能可见长度 | 智能/原版积分亮度 |
|---|---:|---:|---:|
| 5 | 88 | 7 | 9.0% |
| 20 | 88 | 22 | 25.9% |
| 60 | 88 | 62 | 71.2% |
| 100 | 88 | 103 | 115.8% |
| 160 | 141 | 162 | 115.2% |

“可见”以 alpha × 亮度 > 4 为阈值，故原图约100px几何长度测得88px；积分亮度是所有像素 alpha × Rec.709 亮度之和，不等于人的主观亮度。不能把低速结论泛化为所有速度总光量均更低：高速时线更长、总光量反而较多，但仍缺少渐变/亮芯。

两次运行五档结果一致。第二轮额外单变量对照（只改测试实例显示，不改生产源码）：

- 5px/步连续60步后仍为7px可见长度，积分2490.67；不是初次生成的短暂现象。
- 仅把同色、同宽、同透明度的测试曲线改画100px：长度102px，积分32089.35；恢复长度能消除“只剩小点”，但色彩仍均一。
- 仅把原5px线的不透明度0.7改1：长度仍7px，积分3083.93；无法补偿长度缺失。
- 测试中清掉替代线并恢复原版 scaleX=1：88px、积分27660.30，原生渐变像素完全恢复。此操作只用于证实原生资源没有丢失，不能直接当正式修复，因为会重新显示直线。

## 重现入口与证据

```powershell
& '.\build\test-smart-tracer.ps1' -Nodebug -OutputDirectory 'out\smart-tracer\controls'
```

当前 v1.15.1 输出 `FAIL smart tracer`，5/20/60 三档长度与积分低于原版75%，共6个症状断言失败；这是预期红色复现，不是启动或探针报错。75%是用于捕捉本故障的诊断阈值，不是已经与用户约定的修复视觉验收标准。

- 外部探针：`build/smoke/SmartTracerSmoke.as`。
- 基线：`build/out/smart-tracer/baseline/results.txt`、`tracers.png`。
- 连续步/单变量对照：`build/out/smart-tracer/controls/results.txt`、`tracers.png`。
- 每轮 `manifest.json` 保留生产、根宿主及探针指纹；运行完成的临时游戏副本已清理。

## 修复方向与边界

保留有限长度的历史真实曲线路径，并将原生曳光的亮芯/渐变沿曲线绘制；物理运动、目标快照、命中和伤害无需改动。不宜只增亮或恢复整条直线贴图。首帧历史不足、原生彩虹弹外观、碰撞/跳弹/脱离制导清理需在实际实现时一并处理。

本轮检查没有加载实际 Sandevistan；5px是受控低速样本，不称为时停联测。普通 visualBullet 五档对照支持显示层机制结论；未认证全部弹型、缩放、实际合成显示时序和联机。可选询问普通/时停场景尚未获答，检查未依赖该回答。
