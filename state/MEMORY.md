# MoreSkills&Weapons —— 开发记忆入口

> 协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。最近实现候选：2026-09-23，v1.6.2-smart-keep-lock；最近正式安装：v1.6.1-smart-tuning + 激光热修复（2-cast-ray）。

## 1. 这个模组是什么

技能与武器扩展：智能武器、可调跳弹、非致命激光枪、可编程榴弹炮、举枪/冲刺姿态、手雷击落、疾跑切枪及恒定散布。入口 MoreSkillsWeaponsMod；独立 ModSettings 聚合 Pip 设置，MSW 保留 F6 浮层。主体动态访问；少量唯一同包类通过外部宿主声明接入 Unit/SATS/Weapon/Bullet。宿主存根绝不能嵌入正式 SWF。

## 2. 用户偏好与协作约定

- 激光枪 Q1–Q25 与整体补充边界均已确认，用户明确“按此实现”，不再重问。完整约定见 design/nonlethal-laser.md。
- 激光零直接生命伤害；正面眼部/传感器命中，普通敌人和首领统一失明 6 秒，可刷新；恐慌攻击可误伤同伴/中立并造成死亡，射手阵营不变。
- 默认半自动 0.8 秒、6 次一匣、2 秒装填、每次 2 份原版电池；40 px/5° 瞬时辅助随二维速度减弱，手动精瞄始终有效；SATS 瞄眼基础 17 AP；每存档只赠枪一次，不赠弹。只有直线，没有跳弹/智能制导。
- 智能武器默认关闭，规则与菱形 HUD 已确认。热键只用 F6，Tab/PageUp/PageDown 切换三页，不新增热键。
- 用户要求转弯半径、菱形大小在设置中可调。新项默认由实现选定为 50% / 24 px；100% / 40 px 可恢复此前手感与大小。Pip/F6 均可调、保存和恢复默认，旧配置只补缺项。
- 用户新增视野外保持锁定开关：默认关闭，关闭沿用渐进脱锁；开启时已完成的锁定在离屏或遮挡后保持当前强度，新目标仍须目视获取。Pip/F6 共用设置，旧配置缺项默认关闭。
- 当前模组可写；其他模组最小必要只读。用户已明确“请实装”，授权将本次激光枪版本部署到正式 release；根游戏 loader 无须修改。

## 3. 当前状态

- **正式已安装 v1.6.1-smart-tuning + 激光热修复**。release/MoreSkillsWeaponsMod.swf 与 build/out/laser-fix/MoreSkillsWeaponsMod-final.swf 同字节，39842 字节，SHA256 `573709F879ED6A538D49110A73836053123DC859F47376D2C63D221090E5B089`。核心版本不变，新增激光标记 `laserRuntimeVersion=2-cast-ray`；HUD `2-adjustable-size`，运动 `1.2-radius`。
- **v1.6.2-smart-keep-lock 源码与生产候选已完成，尚未正式安装**。候选 build/out/keep-lock/MoreSkillsWeaponsMod.swf 为 39991 字节，SHA256 `909CEF05D810A8F0C0093B34DD0999DC0CE6847E24E0402C1818BFCF435C3744`。新增智能页第 13 项「视野外保持锁定」，默认关闭；开启后已有锁定离屏、被墙遮挡时不脱锁。
- 本候选 58 项智能规则、真实游戏离屏/墙遮挡/恢复及 13 项设置、30 定义生产链接、同字节 900 帧启动及生产激光真实开火回归通过。证据 knowledge/experiments/smart-keep-lock-20260923.md。正式 release 尚未替换，用户当前游戏仍运行上条的 v1.6.1 激光热修复。
- 智能页新增“转弯半径倍率”10–200%、步长 10、默认 50%；“锁定菱形大小”12–80 屏幕 px、步长 2、默认 24。共 12 项设置。半径同时影响追踪曲率和转角上限，开火时固定并在跳弹/回放中继承；HUD 即时读取大小。
- 本轮 53 条智能规则、30 项像素、14 项真实游戏 HUD、完整智能设置/锁定/绕障/跳弹、四档原生半径对照及实际时停回放通过。安装前后同字节启动均达 900 帧，ModSettings-connected、tabOn=1，无 lastErr/smartError/laserError；证据 build/out/smart-tuning-installed/install-smoke.json。
- 激光真实故障已修复：发布编译误删自定义 trace 调用，assist 校验栈下溢，同时中断光束/致盲；已改名 castRay，正常发布优化保留。原 debug 机制测试及生产启动检查漏掉真实开火，不能证明旧正式版可用；历史记录已补更正。
- 普通激光回归 244 条 PASS；36 类原生敌人接管/恢复，24 个有武器的测试单位另验证真实攻击；覆盖身体/眼部/背面/遮挡/护盾、隐形不辅助、六次点射与装填、SATS 17 AP、存档 AMF 与读档武器接续、爆炸/刀棍/中立友伤、生命周期。Sandevistan 实际慢步及一次录制一次回放也通过。
- 本次固定源回归 244 条 PASS；最终正式字节在 -nodebug 中真实开火通过：扣弹 2、光束回调 1、光束中点像素存在、失明 6 秒、生命不变。安装后同字节 900 帧、赠枪/设置正常、无模块错误；证据 build/out/laser-fix/production-final-results.txt 与 build/out/laser-fix-installed/install-smoke.json。独立 AIR 存储，不读写真实存档；30 个定义，无宿主原类或探针。
- 原功能回归：智能规则 42 条、跳弹规则 315 条、智能原生游戏场景（绕障/64 弹/锁定/设置）通过。激光有 11 个设置，Pip 独立页 msw-laser，F6 三页；眼圈/倒计时截图已检查。
- 旧 v1.5.3-smart-diamond 已备份为 release/MoreSkillsWeaponsMod.before-v1.6.0-20260920.swf，28580 字节，SHA256 671FD977ECA722B9272FF916426E64E5DF8C8C4DEFDA1ECADACDF1778C5EB72A。
- 根 pfe.swf 现为 2026-09-22 通用 loader，SHA256 `252E7B34FC8BF0DD8CF566F45876597FE999562BE0F2E6AB596215D1A514C6DB`，加载矩阵以 mods/loader-manifest.txt 为准。游戏测试副本必须带清单。本轮未改本体、清单、ModSettings 或其他模组正式文件。dist 仍旧 v1.0。

## 4. 正在进行与卡点

- 智能参数与激光修复均已安装，重启后生效；本轮视野外保持锁定已完成源码、测试和生产候选，发布门禁停在「本轮安装授权」之前。当前正式版仍只有 12 项智能设置，不要把候选误认为已安装。
- 激光开火最终采用 MSWDazzlerWeapon 的原生 shoot 回调，已移除轮询射击计数/激光头节点方案。固定扣弹，电池回收专长不会改变“每匣次数”。原生保存 id，恢复后重新接成子类。
- 同包 internal 访问已实测；旧“只能 public”的公共记录新增了范围补充。四个适配类必须显式 includes 并在场景就绪后解析，避免早期 loader 死等。

## 5. 已知问题与验证边界

- 激光首版借用原激光手枪外形；眼位使用公开 eyeX/eyeY 加体型容差，尚未逐套美术逐帧标注。射线最长 2000 场景像素。未覆盖全敌人变体、全剧情状态、长期自然战斗、联机和 DLC 1.03/1.04。
- Sandevistan v1.140 进入后第一显示帧尚无开火录制基线，首帧立刻开火可能不重播；本轮联测在进入后等待 6×50ms 再射击，不声称修复了该模组既有首帧边界。
- 原有“时停预演 + 跳弹 + 智能绕障”三者组合仍未解决/未通过；本次激光不参与两种弹道机制，不能据此宣称旧问题已修复。
- 局部智能绕障不保证封闭/多拐角或极高速命中；智能 HUD 位置为体型近似。原 godMode 已开启时的回放识别、所有模组组合没有完整认证。
- 原举枪趴姿与冲刺落感历史事项未重跑；本轮没有扩改这些功能。旧榴弹炮发枪可能重复 +12 gren40，激光没有赠弹。

## 6. 下一步

- 用户明确授权本次安装后，先核对正式版 SHA256 仍为 `573709F879ED6A538D49110A73836053123DC859F47376D2C63D221090E5B089`，备份到独立 `before-v1.6.2-keep-lock-20260923.swf`，再将已验候选替换正式版并用同字节独立启动检查。安装后用户须重启；当前未关闭用户游戏。仅回退此前激光修复可用 release/MoreSkillsWeaponsMod.before-v1.6.1-laser-fix-20260923.swf，但它会恢复旧激光故障。
- 后续发布保留 castRay 修复并用 test-laser-production.ps1 验证准确的生产 SWF；只通过 debug 测试或启动冒烟不够。build/out/smart-tuning 是未含激光修复的旧候选，不能覆盖当前 release。
- 不要部署 build/out/laser/LaserSmokeMod.swf、smoke/SandevistanMod.as 的错误捕获器或任何测试副本。
- 若另开新任务，优先读本文件及激光实验记录；Q1–Q25 不再询问。普通功能已完成，不自行建立提醒/待办。
- v1.5.3 原回滚备份仍在 release/MoreSkillsWeaponsMod.before-v1.5.3-final-20260920.swf（v1.5.2）；回到设置拆分前须成套恢复 ModSettings loader/客户端，不能只换本 SWF。

## 7. 深入了解

- knowledge/experiments/laser-release-fix-20260923.md：真实复现、编译单变量对照、两类差异校验及安装记录；shared-knowledge/knowledge-validation/discoveries/as3-custom-trace-release-stripping.md：编译陷阱。
- knowledge/experiments/smart-tuning-20260923.md：当前两项参数、原生半径对照、控件/回放/像素检查、通用清单适配、部署与回滚。
- knowledge/experiments/smart-keep-lock-20260923.md：本轮视野外保持锁定语义、真实游戏验证、未部署候选和生产激光回归。

- design/nonlethal-laser.md：用户 25 项选择、边界及当前状态；knowledge/experiments/nonlethal-laser-20260920.md：实现、验证、失败修复和证据路径。
- build/README.md：编译、外部宿主声明、test-laser.ps1 及 -Sandevistan、生产候选同字节检查命令。build.ps1 只写 out 并检查链接表；不自动部署。
- shared-knowledge/knowledge-validation/discoveries/host-internal-package-bridge.md：同包桥接及加载时序；newgame-room-readiness.md：自动开档还须等待 allLandsLoaded。
- design/smart-weapons.md、smart-weapon-hud.md、ricochet-settings.md；knowledge/experiments/smart-hud-20260920.md、smart-smoothing-20260920.md、ricochet-damage-20260920.md：既有功能证据。
- state/journal.md 为历程；decisions/decisions.md 保留 D-001～D-046。diag 跨会话累积，判断时看版本与本轮计数；测试始终使用唯一 AIR 应用 ID。
