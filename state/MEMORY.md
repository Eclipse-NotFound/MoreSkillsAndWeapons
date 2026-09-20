# MoreSkills&Weapons —— 开发记忆入口

> 协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。最近实现：2026-09-20；正式安装未随本轮更换。

## 1. 这个模组是什么

技能与武器扩展：智能武器、可调跳弹、非致命激光枪、可编程榴弹炮、举枪/冲刺姿态、手雷击落、疾跑切枪及恒定散布。入口 MoreSkillsWeaponsMod；独立 ModSettings 聚合 Pip 设置，MSW 保留 F6 浮层。主体动态访问；少量唯一同包类通过外部宿主声明接入 Unit/SATS/Weapon/Bullet。宿主存根绝不能嵌入正式 SWF。

## 2. 用户偏好与协作约定

- 激光枪 Q1–Q25 与整体补充边界均已确认，用户明确“按此实现”，不再重问。完整约定见 design/nonlethal-laser.md。
- 激光零直接生命伤害；正面眼部/传感器命中，普通敌人和首领统一失明 6 秒，可刷新；恐慌攻击可误伤同伴/中立并造成死亡，射手阵营不变。
- 默认半自动 0.8 秒、6 次一匣、2 秒装填、每次 2 份原版电池；40 px/5° 瞬时辅助随二维速度减弱，手动精瞄始终有效；SATS 瞄眼基础 17 AP；每存档只赠枪一次，不赠弹。只有直线，没有跳弹/智能制导。
- 智能武器默认关闭，规则与菱形 HUD 已确认。热键只用 F6，Tab/PageUp/PageDown 切换三页，不新增热键。
- 当前模组可写；其他模组最小必要只读。游戏本体/正式 release 部署核对并发版本与授权；本轮仅实现验证，没有新安装请求。

## 3. 当前状态

- **候选 v1.6.0-dazzler 已实现、验证、未安装**。生产产物 build/out/MoreSkillsWeaponsMod.swf，39403 字节，SHA256 EF5FBA0F8407E25432F38CF9A9342D8D802B1F80243011C43A8693CEF92A713E。
- 普通激光回归 244 条 PASS；36 类原生敌人接管/恢复，24 个有武器的测试单位另验证真实攻击；覆盖身体/眼部/背面/遮挡/护盾、隐形不辅助、六次点射与装填、SATS 17 AP、存档 AMF 与读档武器接续、爆炸/刀棍/中立友伤、生命周期。Sandevistan 实际慢步及一次录制一次回放也通过。
- 同字节生产检查：900 帧、laserGifts=1、ModSettings-connected、tabOn=1；无 lastErr/smartError/laserError。链接表 30 个模组定义，没有宿主原类或 Smoke/Probe。详见 knowledge/experiments/nonlethal-laser-20260920.md 和 build/out/laser-production/install-smoke.json。
- 原功能回归：智能规则 42 条、跳弹规则 315 条、智能原生游戏场景（绕障/64 弹/锁定/设置）通过。激光有 11 个设置，Pip 独立页 msw-laser，F6 三页；眼圈/倒计时截图已检查。
- **正式仍安装 v1.5.3-smart-diamond**：release/MoreSkillsWeaponsMod.swf 28580 字节，SHA256 671FD977ECA722B9272FF916426E64E5DF8C8C4DEFDA1ECADACDF1778C5EB72A。
- 根 pfe.swf 七 loader 未改，SHA256 9A81430D775209E37E8E7FD54414057995E0680671445F38797623865B5A699A。ModSettings 与其他模组正式文件未改。dist 仍旧 v1.0，未打分发包。

## 4. 正在进行与卡点

- 本轮实现与隔离验证完成，候选等待用户提出安装/部署。不是只做普通枪手原型；36 类与真实伤害路径已有证据，但不等于全关卡全变体认证。
- 激光开火最终采用 MSWDazzlerWeapon 的原生 shoot 回调，已移除轮询射击计数/激光头节点方案。固定扣弹，电池回收专长不会改变“每匣次数”。原生保存 id，恢复后重新接成子类。
- 同包 internal 访问已实测；旧“只能 public”的公共记录新增了范围补充。四个适配类必须显式 includes 并在场景就绪后解析，避免早期 loader 死等。

## 5. 已知问题与验证边界

- 激光首版借用原激光手枪外形；眼位使用公开 eyeX/eyeY 加体型容差，尚未逐套美术逐帧标注。射线最长 2000 场景像素。未覆盖全敌人变体、全剧情状态、长期自然战斗、联机和 DLC 1.03/1.04。
- Sandevistan v1.140 进入后第一显示帧尚无开火录制基线，首帧立刻开火可能不重播；本轮联测在进入后等待 6×50ms 再射击，不声称修复了该模组既有首帧边界。
- 原有“时停预演 + 跳弹 + 智能绕障”三者组合仍未解决/未通过；本次激光不参与两种弹道机制，不能据此宣称旧问题已修复。
- 局部智能绕障不保证封闭/多拐角或极高速命中；智能 HUD 位置为体型近似。原 godMode 已开启时的回放识别、所有模组组合没有完整认证。
- 原举枪趴姿与冲刺落感历史事项未重跑；本轮没有扩改这些功能。旧榴弹炮发枪可能重复 +12 gren40，激光没有赠弹。

## 6. 下一步

- 用户要求安装时使用 remains-release-gate；先确认候选指纹/源版本，备份正式 v1.5.3，只替换本模组 release SWF 并重启，根游戏 loader 不需修改。安装后再跑同字节生产验证。
- 不要部署 build/out/laser/LaserSmokeMod.swf、smoke/SandevistanMod.as 的错误捕获器或任何测试副本。
- 若另开新任务，优先读本文件及激光实验记录；Q1–Q25 不再询问。普通功能已完成，不自行建立提醒/待办。
- v1.5.3 原回滚备份仍在 release/MoreSkillsWeaponsMod.before-v1.5.3-final-20260920.swf（v1.5.2）；回到设置拆分前须成套恢复 ModSettings loader/客户端，不能只换本 SWF。

## 7. 深入了解

- design/nonlethal-laser.md：用户 25 项选择、边界及当前状态；knowledge/experiments/nonlethal-laser-20260920.md：实现、验证、失败修复和证据路径。
- build/README.md：编译、外部宿主声明、test-laser.ps1 及 -Sandevistan、生产候选同字节检查命令。build.ps1 只写 out 并检查链接表；不自动部署。
- shared-knowledge/knowledge-validation/discoveries/host-internal-package-bridge.md：同包桥接及加载时序；newgame-room-readiness.md：自动开档还须等待 allLandsLoaded。
- design/smart-weapons.md、smart-weapon-hud.md、ricochet-settings.md；knowledge/experiments/smart-hud-20260920.md、smart-smoothing-20260920.md、ricochet-damage-20260920.md：既有功能证据。
- state/journal.md 为历程；decisions/decisions.md 保留 D-001～D-046。diag 跨会话累积，判断时看版本与本轮计数；测试始终使用唯一 AIR 应用 ID。
