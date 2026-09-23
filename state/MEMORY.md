# MoreSkills&Weapons —— 开发记忆入口

> 协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。最近正式安装：2026-09-23，v1.8.0-smooth-mode + 激光组件 4-reload-debug。

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
- 平滑弹道Q1=B命中优先、Q2=B短路线圆滑过弯、Q3=A全部智能转向、Q4=A开关加程度；用户「开始实现」确认整套规则。默认关闭，0–100%/步长5/默认50%，出膛/跳弹/回放继承，紧急补救仍受原转向上限约束；不重问。
- 当前模组可写；其他模组最小必要只读。已按功能需求实施与安装；根游戏 loader 无须修改。不得关闭用户真实游戏或用测试实例操作真实存档。

## 3. 当前状态

- **正式已安装 v1.8.0-smooth-mode + 激光4-reload-debug**，45014字节，SHA256 `F18097A6681993E1B894B2B25B31781DBD2B9407FED8F6F6F45CFDB9A7AB7C05`。HUD `3-multi-lock`、智能运动 `1.3-smooth-mode`。安装前发现同期激光任务已更新正式版，指纹保护阻止覆盖；最终从其已安装基线合入平滑实现，保留读档修复/调试功能。
- 平滑采用既有短路线有限前瞻和逐物理步转向速率渐变；预测撞墙或近目标/时限不足时可急转。速度、伤害、寿命、制导预算不变，0%与关闭轨迹完全相同；跳弹先真实反射，再重建转向历史。Pip/F6智能页16项，默认程度50%为实测起点，高值可能走更宽弧线。
- 本轮95条规则、16项真实设置与原单目标流程、实际Sandevistan逐发25/50/75%平滑及30/40/50%半径/不同目标回放继承通过。最终生产字节22项平滑物理、52项平滑多锁、39行激光真实读档/视觉回归通过；安装前后同字节900帧、设置入口正常，无三类模块错误。34个生产定义，无宿主原类/测试探针。详情见smart-smooth-mode-20260923.md。
- 读档无光束/失明已真实复现并修复：UnitPlayer.attach 的延迟换枪缓存 newWeapon，原先只替换背包/手持，导致稍后又装备原 Weapon。现在同步待装备引用。激光页新增默认关的「失明命中调试标志」，Pip/F6共用保存，显示命中点/眼区和身体、背面、护盾、不适用、成功失明等原因，标志3秒。共12项设置。
- 激光4上一轮独立完成39行PASS读档/开火/调试/UI、251行机制/实际时停、51项多目标验证及安装前后900帧，结果见build/out/laser-debug/installed与laser-reload-debug-20260923.md；本轮最终字节重跑39行读档回归，未暂停完整舞台光束差分7帧可见、峰值174像素。
- 多重锁定有独立获取、保持、衰减和菱形；稳定轮流分弹，不设固定目标上限。半径仍为10–200%/步长10/默认50%；菱形12–80屏幕px/步长2/默认24。原单目标规则、特殊弹药、跳弹和视野外保持开关保留。上一轮79/30/14/51证据见smart-multi-lock-20260923.md，当前智能验证由前述平滑实验扩充。
- 实际 Sandevistan 回放按同武器录制顺序匹配，既有97px位置容差只作门槛；每帧观察出生顺序。旧弹预算和真实伤害通过；平滑开关/程度与目标、半径共同记录到逐发快照。
- 激光之前独立完成24条视觉生产场景、244条机制及251条实际时停/回放；36类原生敌人抽样、存档/装填/SATS等证据见 laser-visual-eyes-20260923.md 与 nonlethal-laser-20260920.md。本轮保留该代码并补准确生产字节开火检查，没有宣称重跑全部历史测试。
- 发布编译自定义 trace 被删除造成的激光校验栈下溢已用 castRay 修复；仅 debug 测试或启动成功不能证明激光可开火。激光12项设置，Pip独立页msw-laser，F6三页。
- 根 pfe.swf 使用通用 loader，本轮期间被其他工作更新；当前 SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`，加载矩阵以 mods/loader-manifest.txt 为准。本轮最终生产/启动场景复制当前宿主；未改本体、清单、ModSettings、其他模组正式文件或真实存档。dist仍旧v1.0。

## 4. 正在进行与卡点

- 新增锁定豁免需求，本轮先完成敌人类别调查：现用SWF的148个unit定义与1.02参考一致，图鉴3大类/14分组/104条不等于敌人数。已按豁免用途列32个物种/型号候选及首领、机关边界；尚未决定最终粒度/豁免项，也未实现。见knowledge/discoveries/smart-lock-exemption-catalog-20260923.md。
- 平滑弹道开发、实测与安装已完成；无需等待新的实施确认。设计与实测见design/smart-smooth-mode.md、knowledge/experiments/smart-smooth-mode-20260923.md。
- 激光开火采用 MSWDazzlerWeapon 原生 shoot 回调。原生保存id，恢复子类时同步invent/currentWeapon/childObjs/newWeapon/SATS引用；必须用真实comLoad回归，强制即时装备会漏测。固定扣弹，无轮询计数补偿。
- 同包 internal 访问已实测；旧“只能 public”的公共记录新增了范围补充。四个适配类必须显式 includes 并在场景就绪后解析，避免早期 loader 死等。

## 5. 已知问题与验证边界

- 激光借用原激光手枪外形与光束。眼位已改为显示部位解析，36类抽样图已核对；位图头部表随已显示帧更新，部分类型仍为局部传感器锚点。尚未逐套变体逐帧标注，射线最长2000场景像素；未覆盖全部剧情、长期战斗、联机和DLC。原 eyeX/Y 是近似感知原点，不能当精准眼区。
- Sandevistan v1.140 进入后第一显示帧尚无开火录制基线，首帧立刻开火可能不重播；本轮联测在进入后等待 6×50ms 再射击，不声称修复了该模组既有首帧边界。
- 原有“时停预演 + 跳弹 + 智能绕障”三者组合仍未解决/未通过；本轮分别验证实际回放与跳弹继承，不等于三者组合已通过。
- 局部智能绕障不保证封闭/多拐角或极高速命中；智能 HUD 位置为体型近似。原 godMode 已开启时的回放识别、所有模组组合没有完整认证。
- 原举枪趴姿与冲刺落感历史事项未重跑；本轮没有扩改这些功能。旧榴弹炮发枪可能重复 +12 gren40，激光没有赠弹。

## 6. 下一步

- 用户重启后在 Pip「模组 → 智能武器」或 F6 智能页开启「平滑弹道」（默认关闭），程度默认50%、可调0–100%。智能总开关也须开启；单/多锁均可用，改设置影响新弹。可按实际手感反馈再调，当前无待确认的实施步骤。
- 当前回滚用 release/MoreSkillsWeaponsMod.before-v1.8.0-smooth-mode-20260923.swf（43654字节，SHA256 `04A7E69F62044840F9BCA112E235632546096FB9C360C6F5869446DAF4E1E0B9`），换回正式文件并重启：只撤销平滑弹道，保留多锁与激光4读档修复。旧before-laser-reload-debug及before-v1.7.0-multi-lock会撤销更多功能，不要混用。
- 当前生产候选与冻结源在 build/out/smooth-mode-final/，SWF与正式同字节，源码统一换行后与src一致。历史out/smooth-mode及out/multi-lock缺少激光4；out/laser-debug缺少平滑功能，不能覆盖当前release。激光调试入口仍为Pip「模组→非致命激光枪」或F6激光页的「失明命中调试标志」。
- 后续发布必须验证准确生产字节的多目标实战与激光真实开火；保留 MSWLaserEyes/Beam、MSWBlindAccess.pose、castRay 和外部宿主声明。增加test-laser-reload.ps1覆盖装备→保存→comLoad→延迟装备→开火及完整舞台光束；旧combat即时装备测试不能替代。眼位测试仍须独立测量可见部位。
- 测试使用独立 AIR ID；本环境隔离游戏启动需沙箱提权，否则可能无存储/无输出超时。不要部署任何 Smoke/Probe 或测试用 SandevistanMod.as；不要关闭用户游戏。
- 若另开新任务，优先读本文件及平滑/多锁/激光实验记录；已确认规则不重问。锁定豁免仍停在类别调查，不当成本轮已实现功能。普通功能已完成，不自行建立提醒/待办。回到历史设置拆分前须成套恢复 ModSettings loader/客户端，不能只换本 SWF。

## 7. 深入了解

- knowledge/experiments/laser-reload-debug-20260923.md：读档延迟装备引用红绿复现、调试标志、39/251/51验证、生产类差分与指纹。公共武器切换知识weapon-switch-flow.md已补读档替换窗口。

- knowledge/discoveries/smart-lock-exemption-catalog-20260923.md：锁定豁免的类别/中文名/变种/实体ID清单，当前SWF核对、伙伴/机关/首领及共用行为类边界；本轮只读调查。
- design/smart-smooth-mode.md、knowledge/experiments/smart-smooth-mode-20260923.md：已确认Q1–Q4、平滑/紧急补救实现、95/16/22/52/39及实际回放证据、最终组合字节与安装回滚。
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
