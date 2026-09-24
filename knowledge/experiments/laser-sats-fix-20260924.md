---
domain: ui-systems
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产字节经原生SATS候选、鼠标事件、点击入队与实际射击，覆盖文本、多目标、取消、行动点、切枪及真实保存/comLoad。"
date-updated: 2026-09-24
---

# 原版 SATS 选敌修复：v1.14.1-sats-selection

用户在[原因评估](laser-sats-selection-20260924.md)后明确“实装”，并补充“如隔离测试已验证则不用再做原版验证”。本轮按此执行：准确候选通过隔离测试后安装，安装后只核对正式文件与候选一致，不再启动正式游戏或追加重复实战。

当前状态：**v1.14.1-sats-selection已安装**。SATS 53 PASS、原枪199 PASS/203行、接触93 PASS及隔离启动900帧全部通过；安装后正式文件与准确候选SHA一致。按用户要求不再追加原版/正式游戏实战。

## 实现范围

- `MSWLaser.injectXml`删除`sats.@noperc`，逐帧配置明确`noPerc=false`，恢复原版鼠标悬停选敌。零直接伤害与无普通命中抽签仍由零弹体及独立几何射线保证。
- `MSWLaserSats.refreshLabels`只处理当前非致命枪对应的活动SATS候选，保留原生轮廓事件和队列身份；将不适用的概率改成“瞄眼”，普通武器仍显示其原始百分比。文本沿用原生TextField的CR换行，避免每帧重复赋值。
- 瞄眼、基础17AP、2电池、6秒致盲、手动空地射击与现有方向/阻挡设置保留。激光笔仍不进入SATS。
- 基于已合入的眼圈响应、设置分组，以及`9d3a551`的激光笔非正面/两枪天角兽护盾规则组合构建。不能用早期v1.13.3单功能候选覆盖同期新功能。

## 准确产物与验证

候选及冻结源码、清单位于`build/out/laser-sats-final/`。生产55427字节，SHA256 **`17BDF40AD86C66A7F6C95C27ABB86D397A17E450D11B22D32CEBA7FA7EB857C5`**；40个生产定义，无宿主原类和外置探针。主版本`1.14.1-sats-selection`，激光版本`9-sats-selection`。

测试均复制准确候选并前后核对SHA，使用独立AIR ID和存储。没有修改真实存档、关闭用户游戏、修改根SWF或其他模组。根1.02宿主SHA为`B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`。

| 检查 | 证据与边界 |
|---|---|
| 原生SATS选敌 | `selection/results.txt`：53 PASS/63行，原枪/非致命枪悬停、入队身份及提示；两个不同敌人的顺序、34AP预留、逐项取消及返还；取消最后一枪自动退出；重开、空地条目、16AP不足、激光笔禁止进入；保存/comLoad后的当前/库存/待装备引用，读档后重新选敌开火，切回原枪显示百分比；全程无laserError。 |
| 实际射击 | 新开档与读档后均为队列清空、AP80→63、弹数12→10、失明6秒、生命50→50。直接使用原生点击建立的队列，未手工构造或push队列，未使用`-ProbeNoPerc`诊断开关。 |
| 原枪回归 | `laser/results.txt`：199 PASS/203行，真实存读档、15项设置、身体/各方向辅助、原版激光光束与逐帧淡出、实际盲敌状态；自然舞台光束11显示帧/476像素。旧手建SATS队列断言只作补充，不替代本次选敌入口。 |
| 同期接触规则 | `contact/results.txt`：93 PASS，两枪对普通/首领天角兽前后、有盾/无盾、生命与盾值不变，墙箱及其他盾继续阻挡，共用方向开关/帧间扫眼保持。 |
| 隔离启动 | `startup/install-smoke.json`：准确1.14.1版本、900帧、ModSettings-connected、tabOn=1及各模块无错误。此轮发生于安装前的隔离副本。 |

复现：从游戏根运行`build/test-laser-sats-select.ps1 -ProductionSwf <准确候选> -Nodebug -OutputDirectory out/laser-sats-final/selection`。原枪使用`test-laser-reload.ps1`；接触专项使用`test-pointer.ps1 -ProbeClass PointerContactSmoke`；启动使用`test-installed.ps1`并指定准确候选、已准备的独立运行目录及ExpectedVersion。

事件由程序触发，但走原版候选/悬停/攻击输入与队列执行。未声称真人鼠标在全部窗口比例下验收，也未覆盖所有敌人、剧情、联机、DLC或完整时停组合。没有把“瞄眼”写成无视遮挡的命中保证。

## 失败过程与纠正

1. 首份76A1B9F0…/55337字节的选敌已通过，提示断言失败。定点日志和图片确认实际为`名字\r瞄眼`，测试预期为`名字\n瞄眼`，没有模块错误；统一测试换行，生产比较采用CR。诊断日志已从测试源码移除。
2. 新增取消用例误以为取消最后一枪后仍留在SATS，随后空地点击没有入队。原版`Sats.unsetCel`明确退出；先断言退出再重开，未改变生产取消逻辑。
3. 读档后的武器身份检查通过，随后重复`changeWeapon(同ID,true)`把已持有的枪收起。按原版`UnitPlayer.changeWeapon`语义只在不同武器时切换，直接验证真实读档恢复的枪，不靠强制重装掩盖问题。
4. 验证过程中同期源码继续合入v1.14规则，重新冻结完整源并测试新组合字节。早期CAE1DA82…/55336字节的900帧和原枪203行记录保留，但不冒充最终v1.14.1证据。
5. 接触专项首次在复制声音资源时遇磁盘空间不足，尚未启动该场景。只删除本任务此前已退出、可重建的10个隔离runtime目录，保留结果、图片、冻结源码和候选，释放约1GB后重跑。未清理其他任务或正式游戏文件。

## 发布与回滚

2026-09-24 08:52已安装，仅替换`release/MoreSkillsWeaponsMod.swf`。发布前对照当时正式v1.14.0/7AE25C6B…；冻结源码相对该已提交基线只有MSWLaser、MSWLaserSats与入口版本三个文件不同，完整保留同期正式功能。新增近距智能的三个未提交源码不在本候选中，未修改或夹带。

- 正式文件55427字节/17BDF40A…，与已验候选完全相同；完整回执在`build/out/laser-sats-final/installation.json`，manifest状态为installed-hash-verified。
- 回滚：`release/MoreSkillsWeaponsMod.before-v1.14.1-sats-20260924.swf`，55258字节，SHA256 `7AE25C6BABEF61DBB3A158AD9E20FD8DBB3B473E4E66E34D2226CF2DA4F73ACF`。恢复该文件到正式SWF并重启即回v1.14.0，保留眼圈/分组/激光笔方向及天角兽规则，但撤销SATS选敌修复。
- 根SWF与清单指纹不变；配置/存档及其他模组未写入。用户保存并重启游戏后加载新代码。
- 安装后遵从用户明确要求只核对文件一致性，没有再次启动任何实战或启动测试。此前隔离验证通过不能表述成真人实战验收。
