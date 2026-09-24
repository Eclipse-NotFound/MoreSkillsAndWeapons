---
domain: ui-systems
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: decompiled-game-code
    symbol: "fe.inter::Sats.getUnits / mOver / setCel; fe.weapon::Weapon constructor"
  - kind: runtime-experiment
    summary: "两份生产字节复现原生候选存在但点击只建立坐标队列；测试中仅改 noPerc 后恢复选敌，当前字节完成原生队列执行、17AP、2电池、6秒致盲及零伤害断言。"
date-updated: 2026-09-24
---

# 非致命激光枪无法在原版 SATS 选敌：评估与复现

后续进展：用户已要求“实装”，v1.14.1修复已安装，见[实现与验收](laser-sats-fix-20260924.md)。以下保留评估当时的证据；原始诊断命令对应a9926b4的测试，当前入口已加入正式修复回归。

**原因已确认；本轮未修复生产代码、未安装修复。** 用户最初要求评估加入 SATS，Q1 澄清为“在原版 SATS 中实际无法选中敌人”。不再把需求理解为持续锁定或新增一套玩法。

## 结论与因果

`MSWLaser.injectXml` 写入 `sats.@noperc=1`，`configure` 又每帧设 `wp.noPerc=true`。原版并不把这个标记仅用于隐藏命中率：

1. `Sats.getUnits` 正常建立可见敌人的候选。
2. `Sats.mOver` 只有在 `!weapon.noPerc` 时才给候选轮廓加悬停滤镜。
3. `Sats.setCel` 只通过 `du.filters.length>0` 判断哪个候选被选中；没有悬停滤镜就创建 `new SatsCel(null,celX,celY,...)`，即坐标射击。
4. `MSWLaser.fire` 遇到非空 SATS 队列后，读取其绑定敌人；坐标条目返回 null，也不会走普通战斗的身体辅助。因此玩家确实选不中敌人，开火也没有已选敌人的瞄眼帮助。

取消普通命中抽签由 `kol=0` 与模组独立几何射线实现，`noPerc` 不是这条实际命中机制的开关。恢复选敌不需要恢复随机命中率。

## 准确字节与结果

测试使用当前根 1.02 宿主（SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`）、当前设置宿主、独立 AIR ID 与测试存储；未操作真实存档或用户游戏。生产 SWF 在复制后及测试结束都校验 SHA256。

| 样本 | SHA256 | 基线 | 单变量诊断 |
|---|---|---|---|
| 已冻结 v1.13.0，54248字节 | `476430BC9B1A475267D76A4C31FFC0A7A7718582498F149DD51B1C93B4C9BF9F` | 原枪能选敌；非致命枪选成坐标 | 仅令 noPerc=false 后选敌通过 |
| 同期设置分组任务写入正式路径的观察样本，54503字节 | `E1EA2AC2ACAA1F9F7D91DC9EFE72F07E782609EB1C8B4E5ED42072FB1C53FE28` | 同样复现 | 恢复选敌；完整射击链通过 |

第二份仅复制到 `build/out/laser-sats-assessment/installed-observed.swf` 后测试；不是本评估部署的产物，也不代表已验收同期设置功能。

共同基线结果：

```text
lasp        noPerc=false damage=8 candidates=1 highlight=true  selected=enemy reservedAP=17
mswdazzler  noPerc=true  damage=0 candidates=1 highlight=false selected=point reservedAP=17
FAIL hover and native click select the enemy identity mswdazzler
```

单变量探针结果：

```text
DIAGNOSTIC ONLY: mswdazzler.noPerc=false; production bytes unchanged
mswdazzler  noPerc=false damage=0 candidates=1 highlight=true selected=enemy reservedAP=17
OBS execution queue=0 AP=63 ammo=12->10 blind=6 hp=50->50
PASS native selected shot blinds without damage and spends two batteries
```

探针只在当前武器对象上临时改变一个字段；没有手工构造、注入或 push `SatsCel`。执行链为原生 `onoff → 候选的 MOUSE_OVER 处理 → keyAttack/step → setCel → 关闭界面 → UnitPlayer.step`。它证明现有瞄眼/失明链可工作，**不表示修复已进入生产，也不证明完整正式修复已验收**。

## 可复现入口

从游戏根运行；测试要允许独立 AIR 存储。基线应因选不中敌人返回失败；附加 `-ProbeNoPerc` 仅作因果诊断：

```powershell
$candidate=Join-Path $PWD 'mods\MoreSkills&Weapons\build\out\laser-sats-assessment\installed-observed.swf'
& '.\mods\MoreSkills&Weapons\build\test-laser-sats-select.ps1' -ProductionSwf $candidate -GameDirectory $PWD -OutputDirectory 'out/laser-sats-assessment/red-current' -Nodebug
& '.\mods\MoreSkills&Weapons\build\test-laser-sats-select.ps1' -ProductionSwf $candidate -GameDirectory $PWD -OutputDirectory 'out/laser-sats-assessment/probe-current' -Nodebug -ProbeNoPerc
```

证据目录 `build/out/laser-sats-assessment/`：`red`/`probe` 对应 v1.13.0，`red-current`/`probe-current` 对应观察样本；各有 results.txt 及两武器的 selection.png。构建产物可再生，不入库。

第一轮夹具失败时连原版 lasp 也无候选，不能当成用户问题的复现。原因是玩家传送后的感知眼位没有更新；补正常 `gg.actions()` 后，可见性及原版对照通过，再得到上述真实故障。目标变体可随机，但原生候选条件都在每次测试中断言，两份字节结论一致。

## 旧测试为何漏过

`LaserProbe.satsCycle`、`LaserBodyAssistChecks`、`LaserNonFrontChecks` 都直接构造/推入带敌人身份的队列，证明的是“已有正确队列以后”的瞄眼与开火。它们没有验证玩家能否通过原版鼠标悬停与点击建立该队列；历史 SATS 通过记录不能用来反驳本次反馈。

新测试覆盖真实候选及处理函数，但鼠标事件与攻击输入由程序触发，未冒称真人鼠标或全部显示缩放已验证。场景是一个可见、无遮挡、正面掠夺者；多目标、取消/重排、读档恢复、多种敌人及其他模组组合仍属正式修复回归范围。

## 推荐的最小修复（尚未执行）

- 恢复此枪的原生敌人悬停/点击选中，保留已有队列瞄眼、基础17AP、零生命伤害、2电池及现有致盲规则。
- 删除 XML 的 `noperc` 属性，并在运行时配置设 `noPerc=false`。不能只写 `noperc=0`：原版构造器判断属性是否存在；也不能只改对象一次，因为 `configure` 会覆盖。
- 为此枪单独移除不适用的原生概率提示，建议显示“瞄眼”。诊断截图实际出现了95%，源于原版 `getPrec` 的上限，并非这把枪存在5%随机失手。不用“100%”假装保证穿墙、背面或无效传感器命中。
- 使用现有同包 SATS 桥或模组帧逻辑处理提示，不需要修改根游戏 SWF；不改变普通武器、激光笔不参与 SATS 的规则或独立设置接口。
- 正式实现后，以**未加 `-ProbeNoPerc` 的准确候选**重跑本测试，再补多目标、取消/退出/再进入、读档及切枪回归；诊断探针变绿不能替代发布门禁。

新增内容限于测试、评估记录和记忆。公共原生机制归档见 `shared-knowledge/ui-systems/facts/sats-no-perc-target-selection.md`。
