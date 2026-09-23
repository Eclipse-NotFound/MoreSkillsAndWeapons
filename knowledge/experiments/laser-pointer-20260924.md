---
domain: weapons-projectiles
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产SWF的真实存读档、40类原生敌人扫眼、快速扫掠、耗电、真实Sandevistan及原枪/炮塔/多锁回归；隔离启动900帧。"
date-updated: 2026-09-24
---

# 激光笔常亮变体：实现与验收

用户Q1–Q12均A，完整方案获“按此实现”确认。源码已合入主目录，**v1.13.0-laser-pointer已按后续“请安装”部署**，安装后准确字节900帧检查通过。设计见../../design/laser-pointer.md。

## 产物及复现入口

- 候选、冻结src、链接表与manifest：`build/out/laser-pointer/`。
- 候选54248字节，SHA256 `476430BC9B1A475267D76A4C31FFC0A7A7718582498F149DD51B1C93B4C9BF9F`。40个生产定义；宿主Weapon/Bullet/Unit/Pt声明外部链接，没有测试探针嵌入。源码提交`5c75d72`；后续仅改测试预期和文档。
- 原始测试位于`build/out/laser-pointer-work/build/out/`，简明证据复制到候选下`verification/`。manifest记录逐源码SHA；测试前后核对准确候选字节一致。
- 使用当前根1.02游戏与ModLoader设置宿主。实际Sandevistan v1.143只复制到测试副本；独立AIR应用ID、独立存档，未停止用户游戏，未改本体、根清单、其他模组或真实存档。
- 构建：`build/build.ps1 -OutputDirectory out/laser-pointer`。生产测试：`build/test-pointer.ps1 -ProductionSwf <候选绝对路径> -OutputDirectory out/pointer-test -Nodebug -Sandevistan`；嵌套工作树需加`-GameDirectory <实际游戏根>`。AIR测试需允许独立应用存储，普通沙箱曾报3003而无结果。

## 关键实现

- `MSWPointerWeapon`消费原生攻击按键：一次点击触发一次，长按不重复；不调用原生shoot，无弹匣/装填、无原生弹体或SATS排队。
- `MSWPointer`拥有独立武器ID `mswlaserpointer`。`game.triggers`保存一次赠送标志及未用完的电池比例；只扣随身`batt`，同步重量，不调用会扣仓库的minusItem。
- wall-clock时间只在可操作亮灯时扣除；普通暂停不扣电，时停的玩家武器步作为可操作心跳。换枪/收枪/Pip/SATS/控制接管熄灭，开灯状态不保存；回放不产生新光束或额外扣电。
- `MSWPointerBeam`在世界层保留一个细束/落点图形，更新时不重播单发动画。状态栏显示亮灭、库存和预付余量；共用失明倒数HUD但不传辅助目标。
- `MSWPointerSweep`保存眼位与身体框的独立快照，7个均匀中间样本加眼位角度交叉求根，补检玩家/敌人移动。每条样本仍查首个实体、真实墙/箱/护盾与朝向；显示光束不偏向敌人。
- 共用`MSWBlindController`为每个目标只保留一个AI控制节点，内部按laser/pointer分别计时，显示/接管取较长剩余值；刷新不相加，禁用只移除对应来源。眼位/恐慌/友伤继承现有实现。
- 五项独立设置，Pip与F6第五页共用保存/默认值。原枪非正面开关不传给激光笔射线，开启该开关后笔的背面射入仍无效。

## 证据

| 检查 | 本轮结果 |
| --- | --- |
| 准确候选激光笔 | `pointer-verified/results.txt`155行PASS（包含重复回放帧和结束行，不代表155种独立机制）。真实equip→saveGame→comLoad→延迟换枪，库存80、已付余量0.37保持，读档关闭且无重复赠送。 |
| 原生目标覆盖 | 40种实际原生目标，逐一手动眼位开关照射后6秒失明、生命值不减，移除pointer来源恢复感知；含生物、移动机械、8类炮塔、首领。ThunderHead平移原生角色让远端传感器落在场景内，未改传感器锚点。 |
| 耗电与控制来源 | 30秒计费核心精确60电池；短点余量/改速/耗尽/补电不自启；普通实时时间4.67秒耗9.284份，误差在显示帧范围内。混合两枪取较长值、同一节点、各自禁用互不误清通过。 |
| 快扫与限制 | 两端都没碰眼的快速扫掠、中间移动眼穿束能命中；中间墙箱阻挡不能致盲；身体不吸眼、背面/护盾无效。 |
| 持续画面 | 完整舞台EXIT_FRAME差分，204显示帧持续有光束，峰值225像素；人工查看pointer-live.png、pointer-settings.png，细束/落点、6秒倒数、亮灭/库存/余量与五设置可读。 |
| 实际时停 | 实际热键进入时停，立即扫眼刷新6秒；2.13秒用4.204份电池。关灯后计时15帧冻结、10次跟随慢世界推进；实际回放全程关闭，回放前后电量未额外减少。 |
| 原枪准确字节 | `pointer-gun-reload/results.txt`199行PASS：真实读档、15项设置、身体辅助、非正面与SATS，未暂停舞台光束13帧/476像素。 |
| 原枪炮塔准确字节 | `pointer-turrets/results.txt`391行PASS：8种炮塔×4方向、前后辅助/手动、收起/停机/护盾、原地恐慌与恢复。 |
| 智能多锁准确字节 | `pointer-multi/results.txt`52项检查：三目标实际伤害、九发轮分、原生霰弹、跳弹继承目标/预算、失锁与模式切换。 |
| 锁定豁免与五菜单 | `pointer-exclusions/results.txt`314项检查，当前ModLoader每页16+15；31项保存/默认、所有选项F6可达、五菜单正反切换及智能过滤/在途弹通过。 |
| 同源开发驱动 | `laser/results.txt`251行PASS；原枪36类AI、恐慌攻击友伤/真实伤害、到期恢复、SATS及实际Sandevistan录制回放。该驱动另编译，不称为准确候选文件的字节实测。 |
| 跳弹规则 | `tests/results.txt`315断言，含次数/概率/衰减/距离与F6；另编译的规则测试，不冒称全部真实战斗。 |
| 当前宿主启动 | `pointer-startup/install-smoke.json`准确候选900帧，ModSettings-connected/tabOn=1，pointer/laser/smart无错误；未将它当作安装后检查。 |

## 失败定位与测试修正

- 早期存档测试在剧情开场`atkPoss=0`时要求换枪，得到空手。修正为等待原生可装备状态并断言装备成功后保存；未绕过真实读档延迟。
- 仅设置世界准星坐标会被Camera从屏幕celX/celY覆盖，导致时停照射偏离目标。测试同时设置相机屏幕准星，保留原生玩家武器步和实际时停；生产光束没有增加吸眼。
- ThunderHead原生眼位离躯干很远，初始摆位让眼睛位于地图外；只平移测试角色，不改生产几何。
- 共享计时改为按来源管理后，旧测试直接改remaining不能使它到期。到期场景改对应source剩余，保留原有恢复断言。
- F6由四页变五页；旧循环/倒序导航与版本字符串断言更新。当前ModLoader每页16项、旧ModSettings18项，原豁免测试硬编码18导致失败；兼容两种已知容量，仍逐一核对31项、保存、恢复默认和F6可达。
- 新test-pointer移除复制模板中未实现的LegacySwf参数，避免暴露不会完成的升级握手。

## 边界与安装状态

- 连续命中是有限显示采样和插值，不能保证任意瞬移、复杂转身或高速动态遮挡都不漏；朝向/护盾使用当前帧，未声称完整连续碰撞证明。眼位沿用已有可见部位锚点，未逐套皮肤逐帧重新标注。
- 时停沿用MSW现有`onPause && godMode`回放识别；预先开原生godMode时的可操作时停未认证。未改Sandevistan接口，不通过可隐藏HUD文本推测内部状态。
- 验证覆盖1.02隔离场景；未认证所有剧情、联机、DLC、长期战斗和全部模组组合。30秒60电池为计费核心推进，实际连续照射另有4.67秒及真实时停采样，不把前者冒称30秒实战。
- 正式release现为v1.13.0，54248字节，SHA256 `476430BC9B1A475267D76A4C31FFC0A7A7718582498F149DD51B1C93B4C9BF9F`。根pfe.swf及加载清单与安装前指纹一致；本次不修改游戏本体和其他模组。

## 2026-09-24 安装记录

- 用户本轮明确“请安装”；复核候选/冻结源码/40生产定义及全部通过记录后，备份v1.12到`release/MoreSkillsWeaponsMod.before-v1.13.0-laser-pointer-20260924.swf`。备份49560字节、SHA256 `B8EB77D2005B427FA06F40D8FC2A9A5AA68C3E5A5E4DF282CC43FC2629B2684F`，拒绝覆盖既有同名备份。
- 部署准确候选后，`postinstall/install-smoke.json`记录正式文件SHA与900帧、v1.13.0-laser-pointer、ModSettings-connected、tabOn=1、pointer/laser/smart无错误。新独立AIR进程退出后正式hash再次一致，未关闭用户游戏或操作真实存档；用户重启生效。
- 安装检查初次采用通用XML解析器，遇mxmlc报告源码路径未转义&而失败；修正为与构建脚本一致的def扫描。首次File.Replace又因PowerShell空路径参数未执行替换；当时release仍为完整v1.12，随后的版本断言如实失败。记录后核对基线与备份完整，再复制候选并重跑，通过最终检查；没有忽略失败或运行半写文件。
- 回滚：将上述备份复制回同目录`MoreSkillsWeaponsMod.swf`并重启，恢复v1.12。安装记录与失败输出分别保留在preinstall-check.json、postinstall/、postinstall-before-replace/。
- 安装期间同期设置分组开发开始修改3个MSW源码文件并标记1.13.1，本次保留它们而只安装已冻结验证的v1.13；没有重新编译未完成修改。已有journal重排也保持未提交。
