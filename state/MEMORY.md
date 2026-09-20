# MoreSkills&Weapons —— 开发记忆入口

> 协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。最近部署：2026-09-20。

## 1. 这个模组是什么

技能与武器扩展：智能武器（锁定、连续转弯、局部绕障、曲线曳光与菱形 HUD）、可调跳弹、可编程榴弹炮、举枪/冲刺姿态、手雷击落/疾跑切枪及恒定散布。入口 MoreSkillsWeaponsMod；Pip 设置由独立 ModSettings 聚合，MSW 保留 F6 浮层和配置。主体动态访问；仅 fe.Pt 为外部编译存根，绝不能嵌入正式 SWF。

## 2. 用户偏好与协作约定

- 智能武器全部规则与默认值已确认，不再重问；十项配置（开关 + 九个数值）保留设置入口，智能默认关闭。热键只用 F6，浮层内 Tab/PageUp/PageDown 切页。
- HUD 已确认：40 px 正菱形、2 px 描边，身体中心略偏前胸且随朝向翻转；红底蓝边从顶部逆时针覆盖，脱锁原路退回；旧锁与新候选可并存；遮挡时仍显示，归零立即移除；替换旧方框/文字条。
- 普通迁移技能遵守 D-033 / MSWU.inGameplay：可操作时停可介入，回放不介入。智能武器专门适配回放，仅重建弹丸走制导。
- 游戏文件改动前核对并发版本；只写当前模组，其他模组最小必要只读。跳弹/举枪接入游戏技能系统仍按用户要求延缓。

## 3. 当前状态

- **已安装 v1.5.3**：`ver=1.5.3-smart-diamond`，`smartHudVersion=1-top-ccw`，保留 v1.5.2 平滑弹道与 v1.5.1 独立设置客户端。
- release/MoreSkillsWeaponsMod.swf：**28580 字节**，SHA256 `671FD977ECA722B9272FF916426E64E5DF8C8C4DEFDA1ECADACDF1778C5EB72A`。
- HUD 18 项实际光栅检查、10 项真实 1.02 游戏副本检查通过；已查看原生 Raider 身上的双目标与半脱锁截图。正式同字节启动 frames=900、ModSettings-connected、tabOn=1，无 lastErr/smartError，HUD 标记正确。证据在 build/out/smart-hud-production/install-smoke.json。
- 本轮第一次生产检查发现构造期写入的 HUD 诊断被 cfg.load 覆盖，已先回滚再修正为加载后写入，最终重启检查通过；渲染和锁定逻辑未改。
- v1.5.2：每步细分转向、真实路径曳光、智能跳弹入墙面；同一高速复现由 29.25°/160 px 直段改善为 0.58°/5.93 px。该轮绕箱扣血、跳弹/时限/寿命/清理、64 发、42 智能与 315 跳弹规则、完整控件/锁定及实际 Sandevistan 慢步/回放扣血通过。
- v1.5.1：ModSettingsCarrier.modAPI 为跨模组入口，MSW 注册 18+10 项；不再发布旧 MSWModAPICarrier。不向密封 World 增加动态属性；同域 settingsRegister facade 保留。独立中枢及无 MSW 组合由其任务完成验收。
- 根游戏 pfe.swf 保留七个 loader，SHA256 `9A81430D775209E37E8E7FD54414057995E0680671445F38797623865B5A699A`；本轮未改本体或 ModSettings。dist 仍旧 v1.0，未打分发包。

## 4. 正在进行与卡点

- **非致命激光枪（设计讨论，未实现）**：用户要求 game-brainstorming + grilling，Q1–Q25 已全部回答，详见 design/nonlethal-laser.md。核心为半自动、零直接生命伤害、正面眼部/传感器几何命中；生物/机器/炮塔及首领统一失明 6 秒，可刷新，恐慌随机攻击能误伤同阵营/中立。已确认恢复后警戒并重新感知、按敌人行动时间计时；0.8 秒/6 次一匣/2 秒装填/每发 2 份 batt；普通辅助 40 px/5° 随二维速度衰减、不穿透；装备时眼圈和倒计时；每档仅赠一把，未选择赠弹；SATS 自动瞄眼、基础 17 AP；无额外装甲外观免疫，仅直线且不参与跳弹/制导。完整确认稿及补充边界已保存，待整体确认；机器/炮塔/近战 AI 接管及 SATS 队项映射仍需原型。
- 菱形 HUD、弹道平滑、独立设置入口三项均已完成并安装；没有待重新确认的参数。
- 历史面板手感、D-044 冲刺落感、换机后举枪/疾跑切枪旧记录没有后续闭环；本轮未重跑，不据此判定失效。

## 5. 已知问题

- 局部绕障受有限转速、240 px 搜索范围和原版碰撞约束，不保证封闭空间/多拐角/贴墙高速弹命中。
- **时停预演 + 跳弹 + 智能绕障三者组合未解决/未通过**；慢步暂时归零伤害，禁止擅自补回。普通时间智能跳弹、普通智能时停/回放已测。
- 原已开启 godMode 时，onPause/godMode 不能可靠辨别时停与回放；移动敌人/所有模组组合逐像素回放一致性、长时间自然战斗、联机未声称覆盖。
- HUD 前胸为原生包围盒近似位置，未逐种体型调骨骼锚点；40 px 指顶点路径，描边外缘约 42–43 px。DPI/所有屏幕配置未验。
- 趴姿 lurked 受 internal 限制，冲刺位移较大仍可站起；蹲姿见 D-039。发枪可能重复 +12 gren40。
- DLC 1.03/1.04 没有本模组 loader，不在支持/测试范围。

## 6. 下一步

- 非致命激光枪 Q1–Q25 不再重问。等待整份理解与补充边界确认（见 design/nonlethal-laser.md），之后从普通枪手最小原型开始，逐类完成机器/炮塔/近战与首领、SATS 等已选范围。当前无玩法代码或部署改动。
- 用户保存并重启后生效；智能默认关闭，使用原设置入口开启。不新建待办或提醒。
- 回滚本轮只需将 release/MoreSkillsWeaponsMod.before-v1.5.3-final-20260920.swf 覆盖正式 SWF，再重启；此备份为 v1.5.2，28285 字节，SHA256 `695109FDCD702CEFBCBB554748695F87740DA93F7654187807A1735D5D4961E9`。第一次尝试的 before-v1.5.3-20260920 备份也保留。
- 回到设置拆分之前的旧版须成套恢复 loader/客户端：备份在 ../ModSettings/build/backups/before-migration-20260920-142036，不能仅换本 SWF。只关智能无需回滚。
- 时停三者组合若继续处理，先界定伤害暂存/回放归属与跨模组权限。外部分发另走门禁更新 dist。

## 7. 深入了解

- design/smart-weapons.md：全部玩法规则与参数；design/smart-weapon-hud.md：显示约定；design/ricochet-settings.md：跳弹规则。
- knowledge/experiments/smart-hud-20260920.md：当前 HUD、截图、诊断失败及部署证据；smart-smoothing-20260920.md：平滑原理与回放测试；smart-weapons-20260920.md：最初智能实装与边界；ricochet-damage-20260920.md：原伤害证据。
- build/README.md：工具路径、编译和测试命令。build.ps1 / build.bat 仅生成 out，先构建外部 SmartHost.swc；正式 SWF 不得含 Smoke/Probe 或 fe.Pt 存根。当前 21 个 AS 类，fe.weapon.MSWSmartReplayStep 是新增唯一类，不覆盖游戏原版类。
- HUD 验证：test-smart-hud.ps1、test-smart-hud-game.ps1；生产检查 test-installed.ps1 支持 ExpectedHudVersion 与独立 RuntimeDirectory/OutputDirectory，避免覆盖其他任务日志。
- MSWConfig 使用 SharedObject；diag 会跨会话累积，应看版本/时间/新计数。read_sol.py 只读解析；自动测试始终用唯一应用 ID，不写用户 pfe 存储。
- state/journal.md：历程；decisions/decisions.md：D-001～D-046；游戏公共机制继续查 shared-knowledge。
