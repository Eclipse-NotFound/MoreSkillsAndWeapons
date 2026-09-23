# MoreSkills&Weapons —— 开发记忆入口

> 协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。最近正式安装：2026-09-23，v1.11.0-adaptive-radius；自适应半径、透窗路线、激光身体辅助及已提交菜单接口共同保留。

## 1. 这个模组是什么

技能与武器扩展：智能武器、可调跳弹、非致命激光枪、可编程榴弹炮、举枪/冲刺姿态、手雷击落、疾跑切枪及恒定散布。入口 MoreSkillsWeaponsMod；独立 ModSettings 聚合 Pip 设置，MSW 保留 F6 浮层。主体动态访问；少量唯一同包类通过外部宿主声明接入 Unit/SATS/Weapon/Bullet。宿主存根绝不能嵌入正式 SWF。

## 2. 用户偏好与协作约定

- 激光枪 Q1–Q25 与整体补充边界均已确认，用户明确“按此实现”，不再重问。完整约定见 design/nonlethal-laser.md。
- 激光零直接生命伤害；正面眼部/传感器命中，普通敌人和首领统一失明 6 秒，可刷新；恐慌攻击可误伤同伴/中立并造成死亡，射手阵营不变。
- 默认半自动0.8秒、6次一匣、2秒装填、每次2份原版电池；身体选敌辅助默认开，外围60px随二维速度线性缩至50%=30px，直接指身体不因速度失去辅助，取消旧5°限制。所指敌人无效不改投；手动开关、SATS独立瞄眼17AP保留。每存档只赠枪一次，不赠弹，只有直线，没有跳弹/智能制导。
- 智能武器默认关闭，规则与菱形 HUD 已确认。热键只用 F6，Tab/PageDown向后、PageUp向前切换四个菜单（原三页加一个豁免菜单）；↑↓选择时自动翻动长列表，不新增热键。
- 用户要求转弯半径、菱形大小在设置中可调。新项默认由实现选定为 50% / 24 px；100% / 40 px 可恢复此前手感与大小。Pip/F6 均可调、保存和恢复默认，旧配置只补缺项。
- 用户新增视野外保持锁定开关：默认关闭，关闭沿用渐进脱锁；开启时已完成的锁定在离屏或遮挡后保持当前强度，新目标仍须目视获取。Pip/F6 共用设置，旧配置缺项默认关闭。
- 多重锁定两题均选 A：可见敌人无需准星靠近，同时按原锁定时间获取；每颗子弹轮流分配，霰弹弹粒也分散。开关默认关闭，原智能总开关仍须开启；独立脱锁，切换模式重新获取，已发射子弹保留快照。设计见 design/smart-multi-lock.md。
- 用户用「可以」确认自适应整套方案：替换旧平滑；普通值复用转弯半径倍率，最低倍率10–200%/步长10/默认10%，有效下限不高于普通值；预测错过/撞墙/预算不足才收紧，稳定后渐增恢复。短路线与命中优先、单/多锁共用；旧平滑开关迁移，旧程度不转换。出膛/跳弹/回放保留逐发参数，不重问。
- 锁定豁免第一批：生物9（其他生物加肉食灵，含王）、云团与巢穴3、小型机械5、普通地雷6、机关与装置8，共31项。用户明确6种地雷和8种机关分别勾选；默认全不勾，勾选=不锁定。单/多锁共用，已锁/获取中的对应目标移除，在途弹停止追踪不改投，取消后重新获取；本批不扩入小马阵营、大型机械/炮塔及其他首领。
- 当前模组可写；其他模组最小必要只读。已按功能需求实施与安装；根游戏 loader 无须修改。不得关闭用户真实游戏或用测试实例操作真实存档。

## 3. 当前状态

- **正式已安装v1.11.0-adaptive-radius**，48980字节，SHA256 `F8DD73DD47E2E14A90097698317884E42EB3A0EBC163B91ADA12B6F8A1700F10`。运动 `1.4-adaptive-radius`、玻璃 `1-windows`、HUD `3-multi-lock`、激光 `5-body-assist`。智能16项、激光13项，31项豁免仍为单菜单内部18+13两页，F6共四菜单。
- 本轮131条组合规则通过；最终准确生产字节24项自适应、39项原生玻璃、52项多锁、312项豁免、124行激光读档/身体辅助通过，安装前后各900帧、ModSettings-connected、tabOn=1，无lastErr/smartError/laserError。36个生产定义，无宿主原类/探针。16项真实设置与实际Sandevistan回放另行编译通过；详细测试字节边界见knowledge/experiments/smart-adaptive-radius-20260923.md。
- v1.9.1的1123条豁免分类规则、旧平滑22项物理和激光开发轮251行机制等历史证据仍保留；本轮不冒充重跑全部历史套件，旧平滑证据不能代替新自适应。
- 自适应先预测普通倍率是否可达；必要时抽样收紧、细化最大可行区间，不一律使用最低值；连续两次确认可恢复后每次最多增加10个百分点。预测预算耗尽视为未知，不据此断言大半径必定失败。真实碰撞、速度、伤害、寿命和制导预算不变；关闭模式或上下限相同保留固定轨迹。
- 原生对照：固定200%会错过的场景，自适应81.25–111.25%命中；可达目标全程200%；恢复152.5→162.5→172.5→182.5→192.5→200。预测仅在私有对象中推进，不伤窗或挪动真实子弹。测试实际坐标与图在adaptive-radius-production。
- 读档无光束/失明修复保留：UnitPlayer.attach的延迟换枪缓存newWeapon必须同步替换。激光页的「失明命中调试标志」默认关，Pip/F6共用保存，显示命中点/眼区和身体、背面、护盾、不适用、成功失明等原因，标志3秒。当前激光13项设置。
- 激光4的历史验证见laser-reload-debug-20260923.md；本轮最终组合字节激光5读档、近中远身体辅助及原生光束通过，未暂停舞台光束7显示帧/476像素峰值。原始激光5配置升级/回退129行证据仍见laser-body-assist-20260923.md。
- 多重锁定有独立获取、保持、衰减和菱形；稳定轮流分弹，不设固定目标上限。半径仍为10–200%/步长10/默认50%；菱形12–80屏幕px/步长2/默认24。原单目标规则、特殊弹药、跳弹和视野外保持开关保留。上一轮79/30/14/51证据见smart-multi-lock-20260923.md，当前智能验证由自适应与透窗组合实验扩充。
- 实际Sandevistan按同武器录制顺序匹配，每帧观察出生顺序，97px仅作门槛。本轮真实回放保留逐发目标、30/40/50%普通倍率、10/20/30%最低倍率及自适应开关；录制后关闭模式/修改当前配置仍沿用快照，旧弹预算、真实伤害和世界恢复通过。该联测使用透窗合入前同快照实现，不称为最终安装字节的全组合回放。
- 激光之前独立完成24条视觉生产场景；眼位36类原生敌人抽样证据见laser-visual-eyes-20260923.md。本轮251行机制/实际时停再次通过，包括36类失明与原生恐慌动作；未重做全部眼位变体逐帧标注。
- 发布编译自定义trace被删除的激光校验栈下溢已用castRay修复；仅debug测试或启动成功不能证明可开火。激光13项设置，Pip独立页msw-laser，F6第三页。
- 根 pfe.swf 使用通用 loader，本轮期间被其他工作更新；当前 SHA256 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`，加载矩阵以 mods/loader-manifest.txt 为准。本轮最终生产/启动场景复制当前宿主；未改本体、清单、ModSettings、其他模组正式文件或真实存档。dist仍旧v1.0。

## 4. 正在进行与卡点

- 透窗已随v1.11组合安装：普通/装甲窗均可锁定，仅可损伤普通窗纳入短路线；撞窗仍原生停弹，后续弹通过实际破口，完整装甲窗绕行；不新增设置。来源1cac284/c9aca71，自适应预测已保留弹药能力，39项组合实战通过，无待合入或待安装步骤。
- 自适应已完成实现、组合验证及安装，用户Q1–Q4和默认最低10%均已确认，无待确认步骤。源码e46c905；菜单接入2013903也已纳入安装候选。详见design/smart-adaptive-radius.md及对应实验。
- 激光辅助增强已确认、实现并保留在本次组合版；规则、60/50%数值、旧参数迁移/回退与无效所指目标不转选见design/laser-body-assist.md。其旧单功能候选不可覆盖当前正式版。

- 锁定豁免第一批31项已实现、验证并安装，无待确认或待执行步骤。类别调查中的32组是完整候选目录，不等于本批选项；第一批范围见design/smart-lock-exemptions.md。调查原始证据保留在knowledge/discoveries/smart-lock-exemption-catalog-20260923.md。
- 旧平滑已被自适应替换；历史设计与实验保留用于追溯，不能恢复旧控制器或把旧参数入口重新加回。
- 激光开火采用 MSWDazzlerWeapon 原生 shoot 回调。原生保存id，恢复子类时同步invent/currentWeapon/childObjs/newWeapon/SATS引用；必须用真实comLoad回归，强制即时装备会漏测。固定扣弹，无轮询计数补偿。
- 同包 internal 访问已实测；旧“只能 public”的公共记录新增了范围补充。四个适配类必须显式 includes 并在场景就绪后解析，避免早期 loader 死等。

## 5. 已知问题与验证边界

- 预测基于当前目标框/线速度、局部路线与有限采样，不能预知急转、跳跃、特殊受击或所有动态遮挡。收紧受最低倍率和原预算约束，不保证必中；64弹压力有额外预测开销，实测数据不等于日常FPS。

- 激光借用原激光手枪外形与光束。眼位已改为显示部位解析，36类抽样图已核对；位图头部表随已显示帧更新，部分类型仍为局部传感器锚点。尚未逐套变体逐帧标注，射线最长2000场景像素；未覆盖全部剧情、长期战斗、联机和DLC。原 eyeX/Y 是近似感知原点，不能当精准眼区。
- Sandevistan v1.140 进入后第一显示帧尚无开火录制基线，首帧立刻开火可能不重播；本轮联测在进入后等待 6×50ms 再射击，不声称修复了该模组既有首帧边界。
- 原有“时停预演 + 跳弹 + 智能绕障”三者组合仍未解决/未通过；本轮分别验证实际回放与跳弹继承，不等于三者组合已通过。
- 局部智能绕障不保证封闭/多拐角或极高速命中；智能 HUD 位置为体型近似。原 godMode 已开启时的回放识别、所有模组组合没有完整认证。
- 原举枪趴姿与冲刺落感历史事项未重跑；本轮没有扩改这些功能。旧榴弹炮发枪可能重复 +12 gren40，激光没有赠弹。

## 6. 下一步

- 重启游戏启用新的身体瞄眼辅助；Pip「模组→非致命激光枪」或F6第三页调整开关、外围范围、最低比例和速度阈值。默认60/50%，旧速度首次继承，之后保留新选择；手动关闭普通辅助不影响SATS选眼。
- 用户重启后在Pip「模组 → 锁定豁免」用内部「上页/下页」查看31项，或F6切到豁免后↑↓选择。默认全不豁免，恢复默认清全部豁免；旧勾选直接保留。菜单已完成并安装，不再恢复五个并列入口，不重复询问地雷/机关粒度。
- 重启游戏后在Pip「模组→智能武器」或F6智能页使用「自适应转弯半径」和「最小半径倍率」。平时值仍由原「转弯半径倍率」控制；默认新开关关，已有旧平滑开关状态会迁移；最低默认10%。改配置作用于新弹，已发射/录制子弹保留快照。
- 当前回滚：release/MoreSkillsWeaponsMod.before-v1.11.0-adaptive-radius-20260923.swf，47483字节，SHA256 `132BC390598296BD6237B3991D762F587CF66466EBB907334EA7CF972277F3CE`。换回正式文件名并重启恢复v1.10激光身体辅助与旧平滑，撤销本次自适应和透窗；不要误用更旧备份。
- 当前正式同字节候选与冻结src：build/out/adaptive-work/build/out/adaptive-release。冻结源与主目录2013903一致，包含菜单接口；当前已安装ModSettings仍走兼容分支，后续聚合界面由其任务验证。本轮仅改本模组，不改根SWF、清单、其他模组或真实存档。
- 后续发布必须验证准确生产字节的多目标实战与激光真实开火；保留 MSWLaserEyes/Beam、MSWBlindAccess.pose、castRay 和外部宿主声明。增加test-laser-reload.ps1覆盖装备→保存→comLoad→延迟装备→开火及完整舞台光束；旧combat即时装备测试不能替代。眼位测试仍须独立测量可见部位。
- 测试使用独立 AIR ID；本环境隔离游戏启动需沙箱提权，否则可能无存储/无输出超时。不要部署任何 Smoke/Probe 或测试用 SandevistanMod.as；不要关闭用户游戏。
- 若另开新任务，优先读本文件及豁免/平滑/多锁/激光实验记录；已确认规则不重问。普通功能已完成，不自行建立提醒/待办。回到历史设置拆分前须成套恢复 ModSettings loader/客户端，不能只换本 SWF。

## 7. 深入了解

- design/smart-glass-routing.md、knowledge/experiments/smart-glass-routing-20260923.md：已确认透窗/破窗规则、原生边界、F材质纠正；本次组合安装和新自适应交叉实测见smart-adaptive-radius-20260923.md。
- design/laser-body-assist.md、knowledge/experiments/laser-body-assist-20260923.md：辅助增强已确认规则、13项设置、124/129行生产验证、配置同URL升级回退、251行机制与实际时停、发布和回滚。

- design/smart-adaptive-radius.md、knowledge/experiments/smart-adaptive-radius-20260923.md：已确认方案、131条规则/24原生弹道/39玻璃/52多锁/312豁免/124激光、实际回放与UI、最终指纹和回滚；自适应已安装。
- design/smart-lock-exemptions.md、knowledge/experiments/smart-lock-exemptions-20260923.md：第一批五组31项、精确变种、UI与过滤/在途弹/回放语义、1123/289/52/22/39验证、组合发布与回滚。
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
