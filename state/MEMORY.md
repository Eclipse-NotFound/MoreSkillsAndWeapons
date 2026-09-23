# MoreSkills&Weapons —— 开发记忆入口

> 协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。最近正式安装：2026-09-23，v1.7.0-multi-lock + 激光组件 3-visual-eyes。

## 1. 这个模组是什么

技能与武器扩展：智能武器、可调跳弹、非致命激光枪、可编程榴弹炮、举枪/冲刺姿态、手雷击落、疾跑切枪及恒定散布。入口 MoreSkillsWeaponsMod；独立 ModSettings 聚合 Pip 设置，MSW 保留 F6 浮层。主体动态访问；少量唯一同包类通过外部宿主声明接入 Unit/SATS/Weapon/Bullet。宿主存根绝不能嵌入正式 SWF。

## 2. 用户偏好与协作约定

- 激光枪 Q1–Q25 与整体补充边界均已确认，用户明确“按此实现”，不再重问。完整约定见 design/nonlethal-laser.md。
- 激光零直接生命伤害；正面眼部/传感器命中，普通敌人和首领统一失明 6 秒，可刷新；恐慌攻击可误伤同伴/中立并造成死亡，射手阵营不变。
- 默认半自动 0.8 秒、6 次一匣、2 秒装填、每次 2 份原版电池；40 px/5° 瞬时辅助随二维速度减弱，手动精瞄始终有效；SATS 瞄眼基础 17 AP；每存档只赠枪一次，不赠弹。只有直线，没有跳弹/智能制导。
- 智能武器默认关闭，规则与菱形 HUD 已确认。热键只用 F6，Tab/PageUp/PageDown 切换三页，不新增热键。
- 用户要求转弯半径、菱形大小在设置中可调。新项默认由实现选定为 50% / 24 px；100% / 40 px 可恢复此前手感与大小。Pip/F6 均可调、保存和恢复默认，旧配置只补缺项。
- 用户新增视野外保持锁定开关：默认关闭，关闭沿用渐进脱锁；开启时已完成的锁定在离屏或遮挡后保持当前强度，新目标仍须目视获取。Pip/F6 共用设置，旧配置缺项默认关闭。
- 多重锁定两题均选 A：可见敌人无需准星靠近，同时按原锁定时间获取；每颗子弹轮流分配，霰弹弹粒也分散。开关默认关闭，原智能总开关仍须开启；独立脱锁，切换模式重新获取，已发射子弹保留快照。设计见 design/smart-multi-lock.md。
- 当前模组可写；其他模组最小必要只读。已按功能需求实施与安装；根游戏 loader 无须修改。不得关闭用户真实游戏或用测试实例操作真实存档。

## 3. 当前状态

- **正式已安装 v1.7.0-multi-lock**，42525 字节，SHA256 `F02FF3DBC917F557C59ADEF2EBC9605163E132FAC964952A1B437B8BF1BB5E97`。HUD `3-multi-lock`、智能运动 `1.2-radius`、激光 `3-visual-eyes`。最终候选以提交 8678a9b 加本轮智能改动冻结，保留最新激光视觉眼位/原版光束修复。
- 多重锁定有独立获取、保持、衰减和菱形；稳定轮流分弹，不设固定目标上限。Pip/F6 智能页共 14 项。半径仍为10–200%/步长10/默认50%；菱形12–80屏幕px/步长2/默认24。原单目标规则、特殊弹药、跳弹和视野外保持开关保留。
- 本轮79条规则、30项HUD像素、14项真实设置的操作/保存/默认与单目标场景通过；最终生产字节51条实战断言通过，含三目标并行获取、9弹各3发、真实5弹粒霰弹、各目标实际伤害、独立遮挡/脱锁/保持/死亡和模式切换。
- 实际 Sandevistan 录制/回放通过：三发分别保留各自目标及30/40/50%半径，回放前改为200%并关闭多重模式仍逐发对应。回放按同武器录制顺序匹配，既有97px位置容差只作门槛；每帧观察出生顺序。原已存在子弹预算及真实回放伤害也通过。
- 最终生产 SWF 真实激光开火回归通过（扣弹2、光束回调1、原版光束像素、失明6秒、HP不变）。正式链接33个定义，无宿主原类或测试探针；安装前后相同字节均900帧，ModSettings-connected、tabOn=1，无 lastErr/smartError/laserError。详见 knowledge/experiments/smart-multi-lock-20260923.md。
- 激光之前独立完成24条视觉生产场景、244条机制及251条实际时停/回放；36类原生敌人抽样、存档/装填/SATS等证据见 laser-visual-eyes-20260923.md 与 nonlethal-laser-20260920.md。本轮保留该代码并补准确生产字节开火检查，没有宣称重跑全部历史测试。
- 发布编译自定义 trace 被删除造成的激光校验栈下溢已用 castRay 修复；仅 debug 测试或启动成功不能证明激光可开火。激光11项设置，Pip独立页msw-laser，F6三页。
- 根 pfe.swf 使用通用 loader，本轮期间被其他工作更新；当前 SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`，加载矩阵以 mods/loader-manifest.txt 为准。本轮最终生产/启动场景复制当前宿主；未改本体、清单、ModSettings、其他模组正式文件或真实存档。dist仍旧v1.0。

## 4. 正在进行与卡点

- 本轮多重锁定开发、实测与安装已完成，用户重启后生效，当前没有待拍板项。未关闭真实游戏进程。旧单目标、视野外保持、半径/菱形设置及最新激光修复均保留。
- 激光开火最终采用 MSWDazzlerWeapon 的原生 shoot 回调，已移除轮询射击计数/激光头节点方案。固定扣弹，电池回收专长不会改变“每匣次数”。原生保存 id，恢复后重新接成子类。
- 同包 internal 访问已实测；旧“只能 public”的公共记录新增了范围补充。四个适配类必须显式 includes 并在场景就绪后解析，避免早期 loader 死等。

## 5. 已知问题与验证边界

- 激光借用原激光手枪外形与光束。眼位已改为显示部位解析，36类抽样图已核对；位图头部表随已显示帧更新，部分类型仍为局部传感器锚点。尚未逐套变体逐帧标注，射线最长2000场景像素；未覆盖全部剧情、长期战斗、联机和DLC。原 eyeX/Y 是近似感知原点，不能当精准眼区。
- Sandevistan v1.140 进入后第一显示帧尚无开火录制基线，首帧立刻开火可能不重播；本轮联测在进入后等待 6×50ms 再射击，不声称修复了该模组既有首帧边界。
- 原有“时停预演 + 跳弹 + 智能绕障”三者组合仍未解决/未通过；本次激光不参与两种弹道机制，不能据此宣称旧问题已修复。
- 局部智能绕障不保证封闭/多拐角或极高速命中；智能 HUD 位置为体型近似。原 godMode 已开启时的回放识别、所有模组组合没有完整认证。
- 原举枪趴姿与冲刺落感历史事项未重跑；本轮没有扩改这些功能。旧榴弹炮发枪可能重复 +12 gren40，激光没有赠弹。

## 6. 下一步

- 用户重启后在 Pip「模组 → 智能武器」或 F6 智能页开启「多重锁定」（默认关闭）；智能武器总开关也须开启。
- 本轮回滚用 release/MoreSkillsWeaponsMod.before-v1.7.0-multi-lock-20260923.swf（41512字节，SHA256 `D16523C35BE414FB200D5FFDD31B1453B85F1AF3802A91180805D8FDD0F21BBD`），复制回正式SWF并重启：撤销多重锁定，保留视野外保持及最新激光眼位/光束修复。更早备份对应不同范围，不要混用。
- 本轮最终候选 build/out/multi-lock/MoreSkillsWeaponsMod.swf 与正式同字节；对应冻结源在 build/out/multi-lock/src。早期多重候选、build/out/smart-tuning 与旧 laser-fix 产物缺少后续修复，不能覆盖当前 release。
- 后续发布必须验证准确生产字节的多目标实战与激光真实开火；保留 MSWLaserEyes/Beam、MSWBlindAccess.pose、castRay 和外部宿主声明。视觉修复还须用 test-laser-combat.ps1 独立测量可见眼睛，不能只测函数自己返回的点。
- 测试使用独立 AIR ID；本环境隔离游戏启动需沙箱提权，否则可能无存储/无输出超时。不要部署任何 Smoke/Probe 或测试用 SandevistanMod.as；不要关闭用户游戏。
- 若另开新任务，优先读本文件及多重锁定/激光实验记录；已确认规则不重问。普通功能已完成，不自行建立提醒/待办。回到历史设置拆分前须成套恢复 ModSettings loader/客户端，不能只换本 SWF。

## 7. 深入了解

- design/smart-multi-lock.md、knowledge/experiments/smart-multi-lock-20260923.md：用户A/A、逐目标锁定/分弹、回放顺序、79/30/51及设置/联测证据、最终安装和回滚。
- knowledge/experiments/laser-visual-eyes-20260923.md：可见眼睛/框外传感器红绿对照、视觉样本、原版光束、生产场景与安装回滚；shared-knowledge/entities/discoveries/perception-eye-vs-rendered-eye.md：感知点与显示眼位区别。
- knowledge/experiments/laser-release-fix-20260923.md：真实复现、编译单变量对照、两类差异校验及安装记录；shared-knowledge/knowledge-validation/discoveries/as3-custom-trace-release-stripping.md：编译陷阱。
- knowledge/experiments/smart-tuning-20260923.md：当前两项参数、原生半径对照、控件/回放/像素检查、通用清单适配、部署与回滚。
- knowledge/experiments/smart-keep-lock-20260923.md：本轮视野外保持锁定语义、真实游戏验证、生产激光回归与部署回滚。

- design/nonlethal-laser.md：用户 25 项选择、边界及当前状态；knowledge/experiments/nonlethal-laser-20260920.md：实现、验证、失败修复和证据路径。
- build/README.md：编译、外部宿主声明、test-laser.ps1 及 -Sandevistan、生产候选同字节检查命令。build.ps1 只写 out 并检查链接表；不自动部署。
- shared-knowledge/knowledge-validation/discoveries/host-internal-package-bridge.md：同包桥接及加载时序；newgame-room-readiness.md：自动开档还须等待 allLandsLoaded。
- design/smart-weapons.md、smart-weapon-hud.md、ricochet-settings.md；knowledge/experiments/smart-hud-20260920.md、smart-smoothing-20260920.md、ricochet-damage-20260920.md：既有功能证据。
- state/journal.md 为历程；decisions/decisions.md 保留 D-001～D-046。diag 跨会话累积，判断时看版本与本轮计数；测试始终使用唯一 AIR 应用 ID。
