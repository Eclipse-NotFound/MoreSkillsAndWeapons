---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: user-observation
    summary: "非致命激光枪有开火声音并消耗电池，没有光束、命中无效果。"
  - kind: runtime-experiment
    summary: "已安装生产字节实际开火重现：ammo=10、shots=undefined、blind=0、VerifyError 1024；仅保留 trace 编译对照和改名修复版均恢复光束与 6 秒零伤害致盲。"
date-updated: 2026-09-23
---

# 非致命激光枪发布产物无光束、无效果

## 根因和漏测边界

真实 pfe 诊断显示 v1.6.0-dazzler，laserError 为 frame:VerifyError #1024；用户补充有声音且扣电池。MSWLaserGeometry.assist 内的未限定 `trace(...)` 是自定义射线函数，却被 mxmlc 发布默认 omit-trace-statements 当作调试输出删除。字节码留下无返回值的 `coerce Object`，首次使用辅助瞄准即栈下溢；开火的 fire 和逐帧 render 都调用 assist，因而同时失去光束与致盲。

2026-09-20 的 244 条断言真实通过，但测试文档类是 debug 构建并重新链接了源码；正式 SWF 的 900 帧检查只测试启动和设置，没有开火。这是此前验收缺口，不能将那些结果解释成正式版激光可用。本次保留历史证据并新增真实产物行为回归。

## 可复现命令与对照

build 目录执行 `./test-laser-production.ps1`。驱动类不链接 MSW 源码，加载传入生产文件的同字节副本，创建正面原生 Raider，通过原版武器 step 开火，断言耗弹、laserShots、失明与零 HP 伤害、枪口到眼部中点的实际绘制像素。`-Nodebug` 使用正常游玩运行选项；默认输入当前 release，`-ProductionSwf` 可选候选文件。

| 输入 | 结果 |
|---|---|
| 原安装 EF5FBA0F8407E25432F38CF9A9342D8D802B1F80243011C43A8693CEF92A713E | 精确复现：耗弹 2，光束回调无增加，失明 0，assist 校验 #1024。out/laser-fix/before-results.txt 与 before-stderr.log。 |
| 同一 c082c74 源码，仅 `-omit-trace-statements=false` | 通过；字节码恢复 callproperty trace。out/laser-fix/keep-trace-results.txt、pcode-before、pcode-keep-trace。 |
| c082c74 加射线改名修复，恢复 `-omit-trace-statements=true` | -Nodebug 通过，6 秒致盲、HP 不变、光束像素存在。39481 字节，SHA256 090DAEAE49A0C406B97469419CD5E74F585DFDA531F978767E49734715E808E8；仅诊断候选，不能覆盖之后另行安装的智能更新。 |

修改：`trace` 改为 `castRay`（定义、类内调用、开火调用及原测试）；injectXml 写入 laserRuntimeVersion=2-cast-ray 并清本次启动的历史 laserError。没有改几何、辅助强度、伤害、持续时间或赠枪标记。

## 测试环境修正与并发保护

- 当前根 pfe.swf 已于其他任务换成通用清单 loader，SHA256 252E7B34FC8BF0DD8CF566F45876597FE999562BE0F2E6AB596215D1A514C6DB。旧测试缺少 mods/loader-manifest.txt，首先出现未加载模组的超时；test-laser 与 test-installed 已补只读复制。正式清单、根 SWF 均未改。
- 全回归一轮在实际 Location.step 计时断言失败，之前机制断言均通过。旧驱动仅等待固定 Timer ticks，可能撞上 MSWAutoTest 延迟打开 Pip 或低帧率。改为等待 auto=pip-opt-open 后开始场景，并在有界时间内等待实际敌人步进，失败打印 remaining/hp/pause/pip；不改变游戏计时算法。初次失败保存为 out/laser-fix/timing-first-results.txt。
- 本任务期间另一轮开发把 release 更新为 1.6.1-smart-tuning，439A477F9487DEB2465DB180AA5360971BE5C59F1261B203A795901D6A4D3B62。其源码和文档不属于本次改动；不得以旧 c082c74 构建覆盖该更新。最终需在新安装基线上合入两份激光源码改动并复核同字节行为。

修正测试门控后，固定源码的完整回归恢复 244 条 PASS；真实敌人计时 6 → 4.433 秒、hp=50、pip=false，并通过恢复/关闭清理。证据 out/laser-fix/full-regression-results.txt。

最终候选基于已安装智能更新重新固定源码，排除随后尚未发布的 smartKeepOutOfSight 改动（只处理 build/out 内副本，未动并发工作文件）。对新旧产物的 30 个类全部反编译逐文件比较，只有 MSWLaser 和 MSWLaserGeometry 两个文件不同，另 28 个类完全一致。证据 out/laser-fix/installed-source 与 final-source。最终文件 out/laser-fix/MoreSkillsWeaponsMod-final.swf，39842 字节，SHA256 573709F879ED6A538D49110A73836053123DC859F47376D2C63D221090E5B089，保留核心版本 1.6.1-smart-tuning，新增 laserRuntimeVersion=2-cast-ray。

## 验证边界

用户真实存储仅只读诊断；复现和回归全部用独立 AIR ID。未把其他累计 smartError/lastErr 当作本次激光根因，未改其他模组。首帧 Sandevistan 录制和全剧情/联机范围仍沿原有记录。

## 安装结果

- 最终冻结源再次与已发布智能提交 e4b5f9c 比较，恰好只有两个激光文件不同；正常保留 trace 删除的发布构建成功、定义表通过。准确产物的 -nodebug 实际开火全部通过，证据 production-final-results.txt。
- 核对正式旧指纹 439A477F... 和根游戏指纹未变后，创建并校验 release/MoreSkillsWeaponsMod.before-v1.6.1-laser-fix-20260923.swf，再替换正式 SWF 为 573709F...。回滚只需把这份备份覆盖正式文件并重启，但会恢复旧激光故障。
- 安装后 `test-installed.ps1 -ExpectedVersion 1.6.1-smart-tuning -ExpectedHudVersion 2-adjustable-size -RuntimeDirectory out\laser\runtime -OutputDirectory out\laser-fix-installed` 通过：900 帧、laserRuntimeVersion=2-cast-ray、laserGifts=1、ModSettings-connected、tabOn=1，无 lastErr/smartError/laserError。已验证复制字节与正式指纹一致。
- 没有关闭用户实例、改动真实存档、根游戏、清单或其他模组；用户重启加载现有枪的修复，不重置一次性赠枪标记。smartKeepOutOfSight 并发工作仍留在工作区，未纳入本次提交。
