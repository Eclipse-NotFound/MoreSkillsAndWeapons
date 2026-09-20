# MoreSkills&Weapons —— 开发记忆入口

## 2026-09-20 当前发布覆盖：v1.5.1 独立设置客户端
本轮用户授权安装 ModSettings 并切换入口。当前 release 为 26957 字节，SHA256 4783CC1943CB8CC58DB4610144FB959E37E3A41C652E82BFE714C74E3A30A8A1，诊断版本 1.5.1-modsettings；下文 v1.5.0 宿主与 SHA 为上次发布记录。
共享渲染器已移至 ModSettings；本模组仅经 ModSettingsCarrier.modAPI 注册 18+10 项，F6 浮层/配置/玩法保留，Pip 内 F6 路由到独立面板。settingsRegister 同域 facade 保留，旧 MSWModAPICarrier 不再发布。依赖 ModSettings 提供 Pip 聚合界面，其他客户端运行不再依赖 MSW。
完整组合/无 MSW 独立组合/重启持久化通过；MSW 原控件和真实跳弹回归通过；正式字节启动 frames=900、modAPI=ModSettings-connected、tabOn=1。原跳弹和智能玩法未改。新的弹道平滑 WIP 属于其他正在进行的任务，未纳入本次发布与提交。
备份和成套回滚在 ../ModSettings/build/backups/before-migration-20260920-142036；只回滚本 SWF 会造成新旧宿主混装，应同步恢复 loader/客户端。当前状态详情见 ../ModSettings/knowledge/experiments/2026-09-20-migration.md。旧 dist 未更新。

> 新会话从这里开始。协议见工作区 GOVERNANCE.md §8；本模组参数见 ../AGENT_SCOPE.md。

## 1. 这个模组是什么

武器与技能扩展模组：智能武器（准星锁定、飞行转弯、局部绕障）+ 跳弹 + 可编程榴弹炮 mswglau + 蹲/梯举枪 + 冲刺保持姿态 + 手雷击落/疾跑切枪 + 散布恒定。Pip「模组」原版风格设置页与 F6 浮层共用配置。
入口类 MoreSkillsWeaponsMod。主体动态访问；v1.5.0 增加仅 fe.Pt 的外部编译存根，用于原生链表步进钩子，**不得将存根嵌入正式 SWF**。不需要改游戏 loader。

## 2. 用户偏好与协作约定

- 热键只用 F6；智能页在 F6 内用 Tab/PageUp/PageDown 切换，不新增全局热键。
- 用户已明确「按这套参数实装并在设置面板中保留调节入口」：完整智能武器方案及初值、边界均已确认，不再重问 Q1–Q21。
- 普通迁移技能仍遵守 D-033 / MSWU.inGameplay：可操作时停可介入，回放不介入。智能武器另有专用回放适配，仅重建弹丸走制导。
- 游戏本体改动前必须检查其他开发者改动；只写当前模组，其他模组必要最小范围只读。
- 跳弹/举枪接入游戏技能系统仍按用户要求延缓。

## 3. 当前状态

- **源码 / 已安装 v1.5.0**，诊断版本 `1.5.0-smart-weapons`，2026-09-20 完成。智能默认关闭，入口 Pip「模组 → 智能武器」或 F6 → Tab。十项配置（主开关 + 九个数值）保存/恢复默认可用，既有跳弹设置保留。
- 新功能：玩家实弹枪与霰弹枪（含特殊弹药）、单目标、目视获取、遮挡后保持/线性衰减、重见恢复、出膛快照、有限转弯/局部绕障、跳弹共享剩余预算、普通命中抽签豁免及持续 HUD。细则和全部默认见 design/smart-weapons.md。
- 正式 SWF **34457 字节**，SHA256 `B3D076B51D36E164740F373B6745980D3A2C9FCB8949208FAE94536891BAB6DB`。v1.4.1 备份：release/MoreSkillsWeaponsMod.before-v1.5.0-20260920.swf，27521 字节，SHA256 `F9DCD668B57B3EE9B44A52649D55432276AFADE9DEF0EF9E46BA5AB9B9ADCDB3`。
- 智能验证：42 项规则；真实游戏首步接管、绕实体箱体命中、低转速撞墙后跳弹继承、原版霰弹特殊弹药、64 发寻路约 16–17 ms、分步搜索防饥饿、锁定/遮挡/恢复/暂停/彻底脱锁及真实设置控件通过。
- Sandevistan 联合副本：实际热键/实际枪械开火、冻结与慢步计时、回放重建匹配、旧弹预算保持、回放实际扣血及恢复正常状态通过。补充扣血检查曾失败并先回滚，定位为测试准星被 Camera 覆盖；修正测试输入后通过，制导源码无需修改。完整证据和边界见 knowledge/experiments/smart-weapons-20260920.md。
- 旧功能回归：315 项跳弹断言、原设置页和基础/额外反弹、连续十次真实扣血与护甲/穿甲/距离对照通过。未改原有跳弹次数/概率/衰减规则。
- 生产 SWF 同字节隔离启动检查通过：版本正确、frames=900、modAPI=published、tabOn=1，无 lastErr/smartError，见 build/out/install-smoke.json。正式用户进程保留，需保存后重启加载。
- 跨模组通道仍为 World.w.main 下 MSWModAPICarrier.modAPI.registerPage；不要改用密封 World 动态属性或兄弟域 getDefinitionByName。dist 仍为旧 v1.0，未制作分发包。
- 原 v1.4.1「跳弹重置命中距离」默认开启且仍有效；关闭可恢复整条弹链累计距离。

## 4. 正在进行与卡点

- **智能武器 HUD 菱形改版（讨论中）**：用户要求开始锁定时在敌人身上出现跟随移动的空心红色正菱形，蓝色沿边缘随进度覆盖，满锁全蓝，脱锁反向；明确调用 grilling。本轮先确认边缘起点/方向、尺寸、旧文字条是否替换、旧锁与新候选并存、归零消失及未锁满遮挡时的显示。上述选项尚未拍板，未改 HUD 实现或部署。同仓库同时有设置中枢迁移及弹道平滑相关未提交改动，勿覆盖或混入本轮提交。
- 智能武器本轮实装已完成，交付包含下节明确边界；没有待用户重新确认的参数。
- **设置中枢独立模组探查（未批准实施）**：保留 design/settings-hub-extraction-investigation.md。建议独立 Pip 聚合页/接口，MSW 改为客户端，保留旧载体名兼容；F6 是否通用化待定。不能只增加新宿主而让旧 MSW 同时渲染。该工作与本轮智能武器实装分开，未修改其他模组。
- 历史面板手感、D-044 冲刺落感、换机后举枪/疾跑切枪的旧记录没有后续闭环；本轮未重跑，不据此判定失效。

## 5. 已知问题

- 局部绕障有有限转速、240 px 搜索范围及原版碰撞约束，不保证封闭空间/多拐角/贴墙高速弹命中。
- Sandevistan 已测普通智能射击及回放；原有跳弹要求 damage>0，而时停慢步会暂时归零。**时停预演 + 跳弹 + 智能绕障三者组合未解决/未通过**，不得私自补回临时伤害。普通时间智能跳弹已测。
- 玩家原已开 godMode 时，onPause/godMode 不能可靠辨别时停与回放；保留既有边缘限制。移动敌人和所有模组组合的逐像素回放一致性、长时间自然战斗和联机未声称覆盖。
- 趴姿 lurked 分支受 internal 字段限制，冲刺位移较大仍可站起；蹲姿支持完整，见 D-039。发枪可能重复 +12 gren40。
- DLC 1.03/1.04 未合并本模组 loader，不在当前支持/测试范围。

## 6. 下一步

1. 用户保存后重启，通过智能页打开主开关；默认数值可按体验调节，不另建待办或提醒。
2. 若处理上述时停三者组合，先界定伤害暂存/回放归属与跨模组权限；当前测试和源码不得当作完全兼容保证。
3. 回滚至 v1.4.1：把 before-v1.5.0 备份复制覆盖 release/MoreSkillsWeaponsMod.swf 后重启。更早备份也保留；只关智能无需回滚。
4. 若继续设置中枢独立，先确定拆分范围尤其 F6；验收卸掉 MSW 后其他设置仍可用、单页默认/容量/晚到注册。choice/action/info 等控件仍是候选。
5. 外部分发需另走发布门禁更新 dist；不要把历史版本的待办当当前门禁结果。

## 7. 深入了解

- design/smart-weapons.md：全部已确认规则、参数表、实现结构及历史源码调查。
- knowledge/experiments/smart-weapons-20260920.md：测试条件、证据、失败定位、边界和产物回滚；state/journal.md：历程。
- design/ricochet-settings.md、knowledge/experiments/ricochet-damage-20260920.md：原跳弹规则和伤害证据。
- src 共 20 个 AS 类；新增 MSWSmartLock / Route / Weapons / Step 及 fe.weapon.MSWSmartReplayStep。回放节点是唯一新类，不覆盖原版类；仅回放期存在。
- build/build.ps1 与 build/build.bat 均只构建至 out；先生成外部 SmartHost.swc。Java/Animate/compc 路径和全部测试命令见 build/README.md。生产产物与 Smoke/Probe 不得混用。
- 配置为 SharedObject MSWConfig；read_sol.py 可只读解析真实 pfe 的 Local Store。diag 跨会话累积，排错须看版本/时间与新计数，不能把旧错误当新故障。
- decisions/decisions.md：D-001～D-046 历史；原共享机制（碰撞、爆炸、武器创建、Pip 页、loader）继续查 shared-knowledge。
