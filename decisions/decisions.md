# 技术决策记录

> 记录"为什么"，不重复代码细节。格式：日期 / 决策 / 备选 / 理由。

---

## D-001 模组代码采用"完全动态访问"架构（2026-08-15）

- **决策**：模组源码不引用任何游戏类类型；全部用 `getDefinitionByName` +
  动态 bracket 访问 public 成员 + `getQualifiedClassName` 分流。
- **备选**：mxmlc 以 `-external-library-path` 引用 pfe.swf 做 externs 编译。
  实测 Animate 自带 mxmlc 4.6 只接受 SWC（"pfe.swf 不是 SWC 文件"），
  手工构造 SWC 目录复杂且脆弱。
- **理由**：
  1. shared-knowledge 已确认沙箱内"只能调 public 成员（动态 bracket 访问）+ 反射"，
     typed 引用并不能获得更多能力；
  2. 密封类（Bullet/Weapon/Box…）对不存在成员的 bracket 访问会抛 #1069 且吞掉
     外层 try —— 因此无论架构如何都必须先探测再访问，动态架构下用
     `has(obj,"x")` 探测更直接；
  3. 零游戏类依赖 → 编译只需 playerglobal，工具链最简、可复现。
- **代价**：无编译期类型检查。缓解：`design/mechanics-notes.md` 记录每个
  被访问成员的出处（类/字段/语义），写访问封装函数集中维护。

## D-002 跳弹用"帧后重生 Bullet"而非修改引擎（2026-08-15）

- **决策**：检测玩家子弹撞墙死亡 → 在墙外按镜面反射新建等参 Bullet 继续飞行。
- **备选**：
  1. hook `Bullet.run`/`popadalo` —— 子 ApplicationDomain 不可 hook 游戏原型，不可行；
  2. 用 `PhisBullet`（引擎自带 skok 弹跳）替代 —— `Weapon.shoot` 写死
     `new Bullet(...)`，不可替换；
  3. 帧前拦截（抢在游戏 step 前改写位置避免触墙）—— 模组 ENTER_FRAME 恒晚于
     游戏 step（shared-knowledge），不可行。
- **理由**：重生方案完全在"帧后"窗口内实现，不依赖任何引擎 hook；
  游戏本身在 `Bullet` 死亡（babah/liv）后即 `remObj` 出链，重生不产生双重结算；
  视觉/音效/破坏等由原版路径各自负责，重生子弹只补"继续飞行"这一段。

## D-003 可编程榴弹炮的"撞墙次数"用 explRadius 预置 0 + 手动 iExpl（2026-08-15）

- **决策**：`wallHits>0` 时每帧把武器实例 `explRadius` 置 0（`shoot()` 读武器字段
  写子弹），飞行子弹不携带爆炸半径；死亡时按分类决定"镜面反弹"或"撞击点 iExpl 爆炸"。
- **备选**：保持 explRadius 原值、试图在子弹撞墙前把 `isExpl=true` 以压制爆炸 ——
  压制后子弹同样 babah 死亡且无爆炸，与置 0 等价，但存在"枪口贴墙首帧竞态"
  （子弹创建与首次 step 同帧完成，模组帧已来不及改子弹）；武器字段是开火时读取，
  无竞态。
- **理由**：把"可变行为"提前到武器字段（开火前），规避子弹级竞态；
  `iExpl` 是 public 且走原版 `explosion()` 全流程（破瓦片/范围伤害/击退/视觉/
  友伤减免），爆炸保真度最高。

## D-004 下坠速率直接复用 `weapon.grav`（2026-08-15）

- **决策**：不发明新物理，每帧写 `weapon.grav = cfg.dropRate`。
- **理由**：`shoot()` 原公式 `b.ddy += World.ddy * this.grav`（World.ddy=1），
  语义即"每步平方的下坠加速度"，与"下坠速率"需求完全吻合；对 AI 持枪（若有）
  同样生效；零侵入。

## D-005 SATS 弹道：noTrass + 自绘覆盖层（2026-08-15）

- **决策**：`mswglau` 实例置 `noTrass=true`；自绘弧线于 `w.vsats` 内。
- **备选**：
  1. 修正内建 `setTrass` 结果 —— `setTrass` 只加固定 `World.ddy` 不乘 grav 值，
     且无公开入口传入系数；trass 由 MOUSE_MOVE 异步触发，帧后修正会闪变；
  2. 临时缩放 `World.ddy` —— 是 const，且影响全场所有榴弹，污染原版行为；
  3. 复用 `Trasser` 对象 —— `is_skok/skok` 是 internal，外部读不到改不了。
- **理由**：自绘层可完整复刻原版弧线语义（同 maxdelta 子步、同 tile 矩形判定），
  并按需加入"弹跳 N 次后终止+爆炸半径圈"预览；每帧重绘天然支持"设置实时生效"。

## D-006 新武器 = 运行时注入 AllData.d XML 节点（2026-08-15）

- **决策**：模组启动时向 `AllData.d` appendChild 克隆自 `glau` 的
  `<weapon id='mswglau'>` 节点，再用游戏原厂 `Weapon.create/Invent.addWeapon` 生成。
- **备选**：
  1. 手写 Weapon 子类实例并逐字段拷贝 —— 大量 internal/派生字段（vis 类解析、
     variant 语义、弹药绑定）难以完整复刻；
  2. 修改游戏数据文件 —— 游戏原始文件只读，禁止。
- **理由**：走原厂工厂后，HUD/快捷栏/存档读档/修理/弹药全部自动兼容；
  XML 注入是运行时内存操作，不触碰任何游戏文件。

## D-007 构建工具链 = Animate 2024 自带 mxmlc + FP11.1 playerglobal（2026-08-15）

- **决策**：`java -jar "<Animate 2024>\...\ActionScript 3.0\bin\mxmlc.jar"
  -target-player=11.1`，flex-config.xml 里 `library-path` 追加
  `<Animate>\...\FP11.1\playerglobal.swc`；cwd 需 stub `themes/Spark/spark.css`
  与 `localFonts.ser`（Animate 版 mxmlc 的 defaults 会读取）。
- **备选**：下载 Flex/AIR SDK（网络可行但 ~100MB+、注册门槛）；Animate flairc
  （需 FLA 工程，过重）。
- **理由**：本机现成、零下载；产物 swf v14 ≤ 运行时 41，可被游戏 Loader 加载。
- 详情固化在 `build/README.md`（可复现步骤）。

## D-008 配置持久化用 SharedObject（2026-08-15）

- **决策**：`SharedObject("MSWConfig")` 存设置，不写文件。
- **理由**：`flash.filesystem` 属 AIR 专有 API，需要 airglobal.swc 编译
  （Animate 未附带）；SharedObject 在 playerglobal 内，编译零依赖，AIR 下按应用
  隔离持久化。若以后需要外部可编辑的 config.txt，需先解决 airglobal 编译依赖。

## D-009 热键选 F8（2026-08-15）

- **决策**：F8 开关设置面板。
- **理由**：Sandevistan 占 F9（MODS_MIRROR_NOTICE 记录其 F9 面板写 config.txt），
  错开避免冲突；F8 不在 `AllData` 默认键位引用中。

## D-010 pfe.swf loader 合并方式（2026-08-15）

- **决策**：FFDec 26.2.1 先 `-export script` 导出 1016 个脚本，仅修改
  `MainFE.as`，再以**只含 MainFE.as 的最小目录**执行 `-importScript` 定向替换，
  输出新 SWF 后覆盖部署；合并前保留整文件备份。
- **备选**：全量脚本目录导入（全部重编译，风险大）；二进制手改 ABC（不可行）。
- **理由**：定向导入只重编译被改的脚本，其余 1015 个脚本与资源 tag 保持
  逐字节原样，风险最小；产物经 dumpSWF 结构解析 + 反编译回读双重验证。
- 模式遵循其他三个模组的既有 loader（LoaderContext(false) + getDefinition +
  `init(this)`，`this`=MainFE），见 shared-knowledge
  `knowledge-validation/discoveries/mod-loader-patch-structure.md`。
- 范围决策：仅合并 root pfe.swf（1.02，当前游玩版本）；DLC/pfe.swf 与
  DLC/pfeUI.swf（1.03/1.04）暂不合并（与 RealisticVision 的覆盖范围一致），
  如需支持另行合并。

## D-011 设置面板集成进 PipBuck 设置页，F8 降级为辅助（2026-08-15）

- **决策**：主入口 = 游戏自带设置页（`pip.active && currentPage 是 PipPageOpt`，
  面板挂 `World.w.vpip` 内 (185,80)，方向键/回车调参）；F8 浮层保留为辅入口。
- **背景**：用户实测 F8 面板打不开。存档证据（`PFEgame0.sol` 含 mswglau +
  gren40）证明模组已加载、发枪正常——问题只在"F8→浮层"路径；根因未实锤
  （最可能是其他模组在 stage 键盘监听链上先行吞键，因模组隔离无法读取其源码）。
- **理由**：
  1. 设置页路径不依赖 F 键与监听顺序，确定性可用；且与用户偏好一致
     （集成进游戏自带设置）；
  2. 哔哔小马页面 UI 纯鼠标驱动（PipPage/PipBuck 无键盘监听），方向键/回车
     可安全消费；仅"按键绑定"对话框（visSetKey）显示期间需放行（显示树扫描检测）；
  3. `page2`（子页号）为 internal 不可读，故不区分子页、面板常驻该页顶部
     横幅区（statHead 恒隐藏，区域空闲）；
  4. 增设 SharedObject 诊断计数器（booted/keys/f8/pip/…），下次实测即可定位
     F8 根因（若 keys>0 而 f8=0 → 被上游吞键；若 f8>0 而面板不显示 → 渲染问题）。

## D-012 模组加载验证方法：检查存档 SharedObject（2026-08-15）

- **决策**：以 `%APPDATA%\pfe\Local Store\#SharedObjects\pfe.swf\PFEgame*.sol`
  中的武器 id（mswglau/gren40）与 `MSWConfig.sol` 诊断计数器作为模组是否
  加载/工作的地面真相。
- **理由**：AIR 下 `trace` 输出不可得（无 flashlog 配置），而 SharedObject 是
  AMF 明文（字符串可直接 grep）；PFEgame 存档按 id 存武器清单，是最直接的
  发枪证据。已验证有效（18:09 存档证明模组运行）。
  补充验证（08-16）：`hk117=9/hk118=1` 证明 F6/F7 已到达模组处理器，
  F8/F10 从未到达 → 多热键方案生效，用户键盘 F8 无键事件（媒体映射/被拦截）。

## D-017 榴弹反弹细节修正（2026-08-16，玩家实测反馈）

- **落地即爆**：原"落地静止等待引信"被判定为"爆炸不及时"（wallHits≥2 时
  静止在地上等引信超时才爆）。改为 `|dy|<=2` 落地接触时立即引爆
  （爆炸点 = 地面以上贴图半高处），移除静止弹机制。
- **角点只弹 X 轴**：进入子步同时穿越两面时，原版 PhisBullet 按 X 先判定
  只弹 X（位置已移出矩形，Y 判定不再触发）；跟随原版，消除角点双轴反转
  造成的"原路反弹"观感。
- **贴图半尺寸定位**：反弹/落点位置由"矩形外 2px"改为"矩形外贴图半宽/半高"
  （贴图中心为注册点），消除"贴图陷进地里"。
- **边界墙兜底**：重生点经世界边界钳制后若仍在矩形内（贴地图边缘的墙），
  不再反弹循环——榴弹直接引爆、跳弹按原版消亡。
- **重生加 try/catch + diag**（errBounce/lastErr/bounce/explode 计数），
  用于定位"墙边开炮炮弹消失"（若为异常抛出则下一轮数据可见）。

## D-018 炮口初速度设置替代射速（2026-08-16）

- **决策**：面板第 4 行由"射速"改为"初速度"（`weapon.speed`，10-100，原版 35）。
- **理由**：用户指出当前模板为一发一换弹，射速设置无意义；初速度
  （`shoot()` 中 `b.vel = speed*speedMult`）直接影响弹道射程，
  SATS 弧线自动跟随（读同一字段）。

## D-019 无历史撞墙不反弹、角点统一 X 轴、热键仅 F6（2026-08-16）

- **无历史位置（出生帧内撞墙）不再反弹**：枪口贴墙（出生帧即死亡）的子弹
  没有历史轨迹，任何进入面估计都可能错（此前 min-t 估计仍偶发"原路回弹"）。
  改为：跳弹按原版消亡（火花），榴弹直接引爆。牺牲了"贴墙 ~vel 像素内"
  的反弹覆盖，换取零错误反弹。
- **角点统一只弹 X 轴**：跳弹与榴弹的进入子步同时穿越两面时都只弹 X 轴
  （跟随原版 PhisBullet 判定顺序）；榴弹同时把 Y 贴出碰撞体外侧
  （否则重生点仍在地面矩形内 → 偶发"陷地"）。
- **热键收敛为仅 F6**：F10 与其他模组热键冲突（用户反馈），F8 无键事件；
  诊断（hk117=9）证明 F6 稳定到达。其余 F 键仅记录诊断，不触发、不拦截。

## D-020 死亡弹贴图立即摘除（2026-08-16）

- **现象**：榴弹反弹时偶发"穿模"陷进地里，站在地上朝正下方发射最明显。
- **根因**：子弹撞墙死亡（babah）后仍在对象链上停留 4 帧，且
  `Bullet.step` 的 vis 同步块（babah 之外、每步必执行）会每步
  `vis.visible=true` 并同步位置——死亡点位于地板/墙矩形内时，整颗榴弹
  贴图被渲染在碰撞体内部（改 visible 无效，游戏每步都会重置）。
- **修复**：反弹/引爆时立即 `vis.parent.removeChild(vis)` 摘除旧弹贴图
  （旧弹已被重生弹/爆炸取代）；贴图尺寸读取异常时回退 16px 常规尺寸。
- **通用结论**：帧后重生类方案必须自行摘除旧弹 vis——游戏只在出链
  （remObj→remVisual）时摘除，babah 滞留期间可见性无法靠 visible 控制。

## D-021 反弹零墙损 + 对角线净空（2026-08-16）

- **反弹零墙损**：wallHits>0 期间把武器 `destroy=0`、`tipDecal=0`
  （与 explRadius 同机制）。飞行弹撞墙时游戏仍会调 `hitTile(0,..,0)`，
  但 `Tile.udar(0)` 不掉血、`Grafon.dyrka` 对 `tipDecal==0` 直接返回
  （裂痕 expl_tre 的随机概率还由伤害比例 gate）——反弹对墙壁零伤害零视觉
  （玩家实测：未爆炸时墙壁不应有破坏动画）。手动引爆时用注册表原值
  （origDestroy/origTipDec）完整结算破坏与裂痕视觉。
- **对角线净空**：反弹/落点净空由"贴图半宽/半高"改为"对角线半径
  （√(w²+h²)/2，限幅 8..20）"。贴图随翻滚旋转（vis.rotation 每帧累加），
  旋转后包围盒的下探量可超过半高——半高净空在旋转姿态下仍会"陷地"
  （玩家实测：正下方发射最明显）。
- **教训**：对"贴图中心为注册点且会被旋转"的对象做几何摆放时，
  净空必须按旋转包围盒（对角线半径）计算，而不是半高。

## D-026 蹲姿/梯子举枪技能（2026-08-16 规划，2026-08-17 实施）

- **目标**：坐下/梯子状态下按住 W 也能"举枪"（原版：坐姿 W=起身、
  梯子 W=爬升、且梯子上 stay=false 导致原版 weapUp 永不成立）。
- **方案**（机制依据见 design/skill-aim-sit-ladder.md）：
  - 坐姿：KEY_DOWN 层吞 W（先于游戏 Ctr）→ 原版 unsit 不触发、保持坐姿；
    每帧把 `currentWeapon.vis.y` 抬高 40px（复刻 setWeaponPos 的
    weaponY-=40 与上方瓦片判定）；枪口 `getBulXY` 读 `vis.emit` →
    贴图抬高 = 枪口抬高 = 子弹出生点上移（可越障射击）。起身 = SPACE
    （原生 jumpp→unsit，S 不负责起身）。坐姿移动的上方向键被占用（可接受）。
  - 梯子：不吞 W；瞄准时置 `gg.noStairs=true`（public）禁爬升判定 +
    抬贴图；Shift+W 爬升、S 爬降（瞄准中禁用，用户确认接受）、松 W 后
    SPACE 脱离。
  - 抬枪为 **10 帧渐入**（对齐原版 t_up 阈值），松开立即恢复（原版同）；
    tip==5 法术武器不参与；rat 变身跳过；独立开关（面板第 6 行）。
- **关键发现**：`weapUp` 是 internal，但其效果可完全由模组复刻
  （贴图抬高 → vis.emit 枪口同步），无需触碰 stay/isSit 逻辑位置。

## D-027 举枪技能的时序与状态加固（2026-08-17 玩家实测）

- **梯子第一帧爬升**：noStairs 原在帧内设置（晚于该次游戏 step）→ 每次按 W
  会爬 ~5px。修复：KEY_DOWN 处理时（先于游戏 step）即置 noStairs。
- **坐姿仍起身（两种流程）**：
  1. "先坐下后按 W"——W 的 KEY_DOWN 被吞应已阻止（诊断埋点 wSwallow 待验证）；
  2. "按住 W 再坐下"——**没有新的 W 键事件可吞**，游戏控制循环用持续按住
     的 keyBeUp 直接 unsit；且松开 S 的一帧窗口（Ctr 清 keySit → 下一控制
     帧 `!keySit` 成立）也会起身。
- **修复（三保险）**：
  1. 瞄准期间每帧强制 `ctr.keySit = true`（public 字段）——unsit 条件含
     `!keySit`，强制后永不成立；坐姿下 sit(true) 幂等无副作用；
     同时 noStairs=true 防"强制 keySit"引发误爬梯；
  2. 瞄准中吞掉 S 的 KEY_UP（堵住松开 S 的窗口）；
  3. W 的 KEY_DOWN 吞键保留（流程 1）。
  释放瞄准时恢复 noStairs=false、keySit=false。
- **教训**：拦截"按住键的持续副作用"不能只依赖 KEY_DOWN——持续按住的状态
  在控制循环里每帧生效，必须在帧层反向抑制（强制对偶键位/标志）。

## D-028 坐姿起身的第三条路径：`isSit && !stay`（2026-08-17 玩家实测）

- **诊断**：`wSwallow=11 == wSitDown=11`——W 的 KEY_DOWN 每次都成功吞掉，
  但玩家仍起身 → 起身不在 2884（keyBeUp 路径）。
- **根因**：起身路径2 `if(isSit && !stay && rat==0) unsit()`（UnitPlayer.as:
  2889）——`stay` 在碰撞结算里会因**任何向下运动一帧**（dy>0 → stay=false，
  Unit.as:2248）被清零；坐姿微调/重力修正一帧即可触发 → 下一控制帧起身。
  stay 是 **Pt 基类的 public 字段**（Pt.as:17）。
- **修复（帧内三保险，坐姿瞄准中每帧执行）**：
  1. `ctr.keyBeUp = false`（堵 2884，无论吞键是否生效）；
  2. `ctr.keySit = true`（堵 2884 的 !keySit 条件）；
  3. `gg.stay = true`（堵 2889 的 !stay 条件）。
  顺序安全：control 先读（看到上一帧我强制后的值）→ 移动碰撞后改 stay →
  我帧后再强制（下帧 control 看到 true）。
- **观测诊断**：keyBeUpLeak（控制帧里 keyBeUp 仍为 true）/stayLost
  （强制后 stay 丢失）——复测若仍异常，数据直接指出是哪条路径。

## D-029 站起恢复兜底 + 观测时序修正（2026-08-17 玩家实测）

- **现象**：坐姿按 W 出现抬枪动画（瞄准分支在跑）但角色同时站起。
- **诊断修正**：上一轮 keyBeUpLeak 观测在"先强制再观测"之后，恒为 0
  ——不能证明吞键有效。观测移到 update 开头（游戏 step 之后、我强制
  之前）：若 Ctr 已置位 keyBeUp=true，说明吞键（stopImmediatePropagation）
  失效，当帧 control 的 2884 已触发 unsit（用户"点按 S 趴下"后松开 S，
  keySit=false → 2884 的 !keySit 成立）。
- **修复（站起恢复兜底）**：跟踪 prevSit；坐姿瞄准中若 isSit 被游戏任何
  路径取消 → 立即 `gg.sit(true)` 坐回（除非 SPACE 主动起身：keyJump/
  jumpp>0 时放行）。即便当帧被 unsit，帧后立即恢复，玩家视觉保持坐姿；
  下一帧 keyBeUp 已被强制 false，不再触发。
- **待验证**：下一轮测试的 keyBeUpLeak 计数将直接证实/排除吞键失效。

## D-030 实测证据：吞键失效 + 恢复兜底 prevSit 维护 bug（2026-08-17）

- **实测证据**（MSWConfig.sol）：`keyBeUpLeak = 7` —— 游戏 step 后
  `ctr.keyBeUp` 仍为 true 共 7 帧 → **Ctr 确实收到了被"吞"的 W**，
  stopImmediatePropagation 在该运行时**不阻止 Ctr 的置位**（与
  input-system.md 的经验相反；该经验来自 Sandevistan 的拦截场景，可能
  因注册对象/阶段差异失效）。按 W 帧 control 的 2884
  （isSit && keyBeUp && !keySit）触发 unsit。
- **恢复兜底未触发（上版 bug）**：`!on` 分支把 prevSit 清成 false →
  按 W 那一帧恢复判定 `prevSit && !isSitNow` 恒假。修复：prevSit 由
  所有分支统一维护（!on 分支也更新），恢复成功后续帧 sitAim 视为 true
  （抬枪连续）。
- **教训**：跨帧状态（prevSit）不能在提前 return 的分支里被错误清零；
  事件拦截（stopImmediatePropagation）的可靠性必须用帧内观测验证，
  不能假设生效。

## D-032 举枪失效根因：heldShift 事件顺序 + 吞键失效补强（2026-08-17 用户实测）

- **现象**：Shift+W 举枪完全失效（D-031 改键后），且 sol 诊断显示
  `keyBeUpLeak` 持续增长、`sitRestored` 从未出现、`aimSkill` 被关闭（02=false）。
- **根因 1（代码）**：Shift 与 W 几乎同时按下时，W 的 KEY_DOWN 可能先于
  Shift 到达（事件顺序无保证）→ 按 W 那一帧 `heldShift` 仍为 false →
  update 里 `on=false` → `!on` 分支把 `prevSit` 清成 false（此时游戏已
  unsit 站起）→ 之后 on=true 但 prevSit 已污染 → 恢复兜底永不触发 → 站起。
  修复：KEY_DOWN(87) 时用 `e.shiftKey` 同步 `heldShift`。
- **根因 2（吞键失效补强）**：D-030 已证 stopImmediatePropagation 在该运行时
  不能阻止 Ctr 置位 keyBeUp。现 KEY_DOWN(87) 坐姿分支直接改写 Ctr 状态：
  `ctr.keyBeUp=false` + `ctr.keyDowns[87]=true`（后者让按住 W 期间的重复
  KEY_DOWN 被 Ctr 的 keyDowns 守卫跳过 → keyBeUp 不再被置位 → 游戏 step 的
  2884 永不触发）。帧内三保险（keySit/stay 强制）保留作双保险。
- **根因 3（配置）**：sol 中 aimSkill 变为 false（02）——用户面板误触或
  保存时机，需用户重新打开第 6 行开关。诊断编码：AMF0 布尔 03=true、02=false。
- **教训**：组合键的状态必须由"事件时物理状态"（e.shiftKey）驱动，不能依赖
  两个键事件的到达顺序；拦截失效时可直接改写被拦截方的状态机字段。

## D-031 举枪改键：Shift+W 举枪、W 恢复原版语义（2026-08-17 用户需求）

- **决策**：蹲姿/梯子举枪从"按 W"改为"**按住 Shift+W**"；
  单独的 W 不再拦截——坐姿按 W = 原版起身（unsit）、梯子按 W = 原版爬升。
- **背景**：D-026~D-030 实现了"坐姿按 W 举枪"，但违背用户使用习惯
  （原版坐姿 W = 起身、梯子 W = 爬升），用户要求改回 Shift+W。
- **实现**：
  1. 入口 KEY_DOWN(87) 的吞 W / 置 noStairs 条件改为 `e.shiftKey`
     （用事件时的物理 Shift 状态判定，不依赖 heldShift 的事件到达顺序）；
  2. `MSWAim.update` 的 `on` 条件加 `heldShift`；梯子瞄准
     `lazAim` 由 `!heldShift`（W 举枪）反转为 `heldShift`；
  3. S 的 KEY_UP 吞键限定 `heldW && heldShift`（瞄准中）；
  4. 面板第 6 行文案标注 "(Shift+W)"。
- **行为**：Shift+W 举枪（三保险 + 恢复兜底原样保留）；松开 Shift 或 W
  即释放瞄准；坐姿按 W 起身、梯子按 W 爬升均为原版路径，不再有任何拦截。
- **边界**：松开 Shift 但 W 仍按住 → on=false → release（keySit 恢复 false、
  noStairs 恢复 false）→ 下一控制帧 keyBeUp 已由 Ctr 置位 → 原版起身/爬升
  恢复。待复测。

## D-022 出生帧死亡的子弹用出生点重放（2026-08-16）

- **现象**：站在地上打近距离地面时子弹无法反弹（出生帧内即撞地死亡，
  被 D-019 的"无历史不反弹"政策直接引爆）。
- **修复**："首次见到即已死亡"的子弹用其出生点 `begx/begy`（public，
  Bullet 构造时记录）作为子步重放的起点。出生帧的轨迹 = 出生点→死亡点
  的一段直线（ddy 每步只加一次、子步间直线），进入面判定与常规跟踪
  子弹同样精确——近距离地面射击恢复可靠反弹（反弹点在地面上方，
  顺带消除该场景的"爆炸点陷在地面内"观感）。
- D-019 的"无历史不反弹"退化为极少数兜底（begx 缺失时）。

## D-023 classify 的 liv>3 守卫误伤出生帧死亡弹（2026-08-16）

- **现象**：站在地上打近距离地面"无法反弹"、正对地面发射"陷入地面"
  （诊断佐证：bounce 计数大量来自跳弹，榴弹路径几乎不走）。
- **根因**：`classify()` 为排除爆炸冲击弹（liv=3 出生）加了 `liv > 3`
  守卫，但出生帧内撞墙死亡的榴弹 babah 后 liv 恒为 **3**（popadalo 置 4、
  step 再减 1）——被误判为 "none"：不反弹、不引爆、旧弹贴图无人摘除
  （滞留 4 帧渲染在死亡点 = 陷地视觉）。
- **修复**：babah 状态豁免 liv>3 守卫（`isBabah || liv > 3`）。冲击弹仍被
  `damage>0 && damageExpl==0` 排除（与 babah 无关），豁免安全。
- **教训**：按字段做身份判定时，死亡状态会改写字段（liv 被 popadalo 钳制），
  必须按"存活/死亡"分别处理阈值。

## D-024 无限小回弹根因：for-in 遍历中新建的条目被同轮误删（2026-08-16）

- **现象**：撞墙次数设 2，但榴弹弹完两次后仍会"多次小回弹"才爆炸，
  小回弹期间还陷进地里（玩家实测）。
- **根因**：step 2 用 `for(k in track)` 遍历处理死亡子弹；`bounce()` 在
  本轮新建的重生弹条目**会被同一轮遍历扫到**——它不在 `seen`（扫描后才
  创建）里，落入"已不在链上"分支被 `delete`；下一帧扫描时 `info==null`，
  用**全新的 wallHits** 重新注册 → 每次反弹后撞墙次数重置 → 无限小回弹，
  直到引信（livLeft ≈ 100 步）耗尽才爆炸。
- **修复**：step 2 先对 Dictionary 键做**快照**（Array）再处理，本轮新建
  条目不参与，下一帧正常进入 seen 流程。
- **伴随修复（视觉防陷地钳制）**：下降末段/小回弹期间，贴图最低点会被
  钳制在下方实体矩形上沿之上（仅钳 vis.y，逻辑位置与碰撞判定不变）——
  消除"贴图下探进地面"的最后残余。
- **教训**：Dictionary 的 for-in 遍历期间新建的键可能被同轮访问
  （实现相关）；凡"遍历 + 遍历中增删"的结构都应先快照。

## D-025 反弹力度设置 + 角点按占优分量选轴（2026-08-16）

- **反弹力度（弹性系数）设置**：新增面板第 5 行"反弹力度"（0.0..1.0，
  步长 0.1，默认 0.4 = 原版手雷 skok）。语义：1.0 完全弹性（镜面）、
  0.4 原版手雷、0 完全不弹（垂直分量清零 → 贴墙滑落/沿地滚行，
  平行分量与地面摩擦 0.7 保留）。SATS 弹道预览同步使用该值。
- **角点按占优分量选轴**：角点同时穿越两面时，改为按"更占优的分量"
  选择反弹轴——`|dx|>=|dy|` 弹 X（原版 PhisBullet 行为），否则弹 Y
  （接近垂直入射时弹地面/天花板才符合直觉，消除该场景残余的
  "原路回弹"观感，玩家实测）。未弹轴的位置同时贴出碰撞体。

## D-013 爆炸连锁卡死：必须排除爆炸冲击弹（2026-08-15）

- **现象**：可编程榴弹爆炸后反复播放爆炸动画/音效并卡死游戏。
- **根因**：`Bullet.explosion()→explBlast()→explBullet()` 生成的冲击弹
  （blast bullets）字段特征为 `owner=发射者（玩家）、weap=源武器、
  explRadius=0、damage=damageExpl(>0)、damageExpl=0、liv=3、precision=0`。
  本模组的子弹分类器只按"weap.id==mswglau && explRadius==0"识别飞行榴弹，
  冲击弹被误判为新榴弹；其 3 帧后死亡 → 再次手动引爆 → 生成新的冲击弹 →
  **指数级爆炸连锁**（每次爆炸对范围内每个单位生成一枚冲击弹）。
- **修复**：分类器要求同时满足 `damageExpl>0 && damage<=0 && liv>3`
  （真榴弹 damage=0/damageExpl=120/liv≈100；冲击弹完全相反且 liv=3 出生）。
  跳弹分支同样加 `liv>3` 守卫（防御 tipDamage=0 的爆炸型武器）。
- **教训**：接管"某武器发射的子弹"时，必须先把**爆炸产生的子弹**排除——
  它们同样挂在发射者名下。冲击弹字段特征已贡献 shared-knowledge
  （weapons-projectiles/discoveries/explosion-blast-bullets.md）。

## D-014 反弹进入面判定：按 maxdelta 子步重放轨迹（2026-08-15）

- **现象**：跳弹基本都"原路回弹"，少有镜面反射（玩家实测）。
- **根因**：进入面判定用"上一帧位置 vs 矩形边界"。高速弹一步移动 vel 像素
  （lmg 200px，远超 40px 瓦片），斜向入射时上一帧位置常落在矩形上/下边界外，
  被误判为"同时穿过两面"→ dx、dy 双反转 = 180° 原路回弹。
- **修复**：按游戏同款子步粒度（`World.maxdelta=9`，`stepN=floor(max|d|/9)+1`）
  从上一帧位置重放本步轨迹，取第一个落入矩形的子步，用其前后两点判定真实
  进入面（含角点同时穿两面的合法双反射）。重放与真实路径完全一致，因为
  `Bullet.step` 内 `dy+=ddy` 每步只执行一次、子步间为直线。
- **教训**：帧后窗口做几何判定时，凡涉及"步长 ≫ 碰撞体尺寸"的场景都必须
  按子步重放，不能用帧级端点。已同步至 shared-knowledge
  （physics-collision/discoveries/bullet-wall-impact.md 模组启示）。

## D-015 可编程榴弹的反弹物理对齐原版手雷（PhisBullet）（2026-08-15）

- **决策**：msw 榴弹反弹改用原版手雷物理模型：弹性 `skok=0.4`、砸地
  `tormoz=0.7` 水平减速、`|dy|<=2` 落地静止（stay）、视觉翻滚
  （`vis.rotation += dr`，dr=dx，模组帧后覆写）、反弹音效 `fall_grenade`、
  引信 = liv 延续（重生不刷新 100，总飞行时间与原版子弹一致）；SATS 弧线
  同步同一模型（含落地静止即终点）。
- **实现要点**：
  1. 落地静止的重生弹 = 静止弹（dx=dy=ddy=0、vRot=false），停在 `phY1-2`，
     引信 liv 继续倒数 → 超时爆炸（或单位走近触发 popadalo → 爆炸），
     避免了"每步撞地死亡-重生"的循环与视觉叠加；
  2. 引信用 tracker 的 `livLeft` 逐帧记录、重生时延续（首次见到即死亡的
     子弹默认 100——其出生帧即撞墙，引信基本未消耗）。
- **理由**：玩家反馈"回弹物理、动画不真实，参考游戏中自带的手雷"。
  跳弹技能（ric）保持镜面反射（光线反射定律），不受影响。

## D-016 浮层热键改为多键兼容（2026-08-15）

- **决策**：浮层开关接受 F6/F7/F8/F10 + 媒体播放键 179；诊断记录
  `hk<keyCode>` 计数。
- **依据**：MSWConfig.sol 诊断显示 `keys=10649`（普通键大量到达）而
  `f8` 计数缺失——F8 键从未到达模组处理器。两种可能：键盘 F8 被媒体功能
  映射（常见于多媒体键盘/笔记本 Fn 锁定），或被先注册的 stage 监听拦截
  （其他模组，隔离原则下不读取其源码）。多键兼容可同时规避两种情况；
  哔哔小马设置页仍是主入口。

## D-033 迁移技能在斯安维斯坦时停期生效（2026-08-17 用户实测反馈）

- **现象**：斯安维斯坦生效期间（时停/回放）手雷击落、疾跑切枪失效。
- **根因**：迁移版 `MSWU.inGameplay()` 含 `onPause==true → 禁`——时停/回放
  一律屏蔽。而 Sandevistan 原版行为（源码核对，本对话授权只读）：
  - 手雷击落：时停期**照常判定**（stepSandy → stepProjHits(loc, true)，
    isSandy 分支：damageExpl/destroy 清零做视觉爆炸 + liv=0 即杀 +
    projBoom 记录回放重演）；仅回放期由重演接管；
  - 疾跑切枪：时停期**允许**（onKey 拦截条件仅 `!replaying`）；仅回放期禁。
- **修复（本模组内，不修改 Sandevistan）**：
  1. `MSWU.inGameplay`：`onPause` 判定改为 `onPause && godMode`（回放期禁、
     时停期放行）。回放期信号 = Sandy 回放开始置 `world.godMode=true`
     （public，World.as:194），时停期 godMode=保存原值（玩家正常 false）。
  2. `MSWProjHits`：新增自维护 origDam 缓存（常规帧捕获攻击体 damage>0
     原值；时停期 Sandy 把玩家攻击体 damage/damageExpl 清零后用缓存恢复）；
     时停期引爆走**视觉爆炸**（damageExpl/destroy 清零再恢复 + explosion +
     liv=0，与 Sandy isSandy 分支一致）。
  3. `MSWSwaprun`：无代码改动（inGameplay 修改后自动生效）。
- **固有限制（需向用户说明）**：时停期击落的真实伤害不结算——Sandy 的
  回放重演（projBoom/replayProjBoom）是其私有系统，不记录/不重演本模组
  的引爆（迁移报告 §2 已明示未迁移该分支）。时停期击落 = 命中判定 +
  血量扣减 + 视觉爆炸；常规游戏期 = 完整真实爆炸。
- **边缘场景**：玩家平时开着 godMode + 用时停 → godMode=true 被误判回放期
  （技能禁），可接受。

## D-034 散布异常增大：根因排查与根除（2026-08-17 用户反馈）

- **排查（全部验证通过，无污染）**：
  1. 备份干净原版（C:\Users\micha\Desktop\Remains）vs 当前游戏：sprite/texture/
     text_*.xml 全部 SAME；pfe.swf 仅差模组 loader 补丁（当前 6 个 loader：
     Sandevistan/RConnect/RealisticVision/MSW/TDFC/RandomRooms）；
  2. 反编译当前 pfe.swf：Weapon/Bullet/PhisBullet/SmartBullet/WThrow 与
     原版 src102 **diff=0**（散布公式零污染）；
  3. 二进制字符串对比：备份 vs 当前 pfe.swf 的 deviation='N' 数据集合
     **完全一致**（AllData 武器数据零污染）。
- **根因 = 原版磨损机制（Weapon.as:1356-1361 + 1459）**：
  `if(hp < maxhp/2) breaking = (maxhp-hp)/maxhp*2 - 1; else breaking = 0;`
  散布公式 `deviation * (1 + breaking*2) / skillConf / ...` ——
  **武器耐久低于 50% 后散布线性增大至 3 倍**（每发射扣 1 hp，原版所有
  武器皆然）。另有技能等级（skillConf）、武器模块（devMult）、状态
  （mazil）因素，均为原版机制。
- **根除（模组内）**：mswglau 每帧 `hp = maxhp`（public 字段）→ breaking
  恒 0 → 散布恒为基础值，不随磨损增大；面板第 11 行"散布恒定"开关
  （默认开，仅对 mswglau 生效，不影响其他武器/游戏平衡）。
- **副作用**：mswglau 永不损坏（耐久无限）——对模组武器可接受。
- **提示用户**：若"散布异常"发生在其他武器，需确认技能等级/模块/磨损状态
  （均为原版机制，模组未干预）。

## D-035 举枪"无法实现"排查（2026-08-18 玩家实测）

- **诊断数据**（MSWConfig.sol 06:57）：aimSkill=true（开关已开）、
  wSitDown/wSwallow=16005（跨版本累积，D-031 前普通 W 也计数——不能区分
  当前版本行为）、keyBeUpLeak=15367（同样主要为旧累积）、**sitRestored=0
  （坐姿从未被 unsit——keySit 帧内强制保护有效，坐姿保持链路自洽）**。
- **发现 bug（已修）**：`!sitAim && !lazAim` 分支（站着按 Shift+W）执行
  `release + heldW=false`——**"按住 Shift+W 再按 S 蹲下"的流程在蹲下后
  heldW 已 false（无新按键事件）→ 举枪永远无法启动**。修复：该分支改为
  温和 return（不 release、不清 heldW），蹲下后下一帧立即进入 sitAim。
- **新增抬枪链路诊断**：sitAimF（坐姿瞄准帧数）/lazAimF（梯子瞄准帧数）/
  raiseF（抬枪执行次数）/raiseBlocked（武器上方 40px 被墙挡）——下次实测
  直接定位断点：sitAimF=0 → on 判定（heldShift/heldW）；raiseF=0 → 抬枪
  条件；raiseBlocked>0 → 上方有墙（正确行为）。
- **提示**：D-031 改键后举枪 = **按住 Shift 再按 W**；单独 W 保持原版
  （坐姿起身/梯子爬升）。

## D-036 举枪首帧卡顿：按键路径高频 SharedObject.flush（2026-08-18 玩家实测）

- **现象**：第一次蹲姿/梯子上举枪出现明显卡顿。
- **根因**：KEY_DOWN 路径上的 `SharedObject.flush()`（同步磁盘 I/O）——
  ① 坐姿 Shift+W 的 wSwallow 分支每次按键 flush；② 每 10 次按键
  （keyN%10）flush；③ 每次 F 键（hk 分支）flush。按键瞬间的同步写盘
  造成可感知卡顿。
- **修复**：删除全部按键路径 flush；诊断落盘只保留帧级低频
  （frameN%300 ≈ 5 秒，boot/首次 world/pip/异常 60 帧 各一次）。
- **教训**：SharedObject.flush 是同步 I/O，诊断计数器落盘必须走帧级节流，
  不能挂在按键/事件路径上。

## D-037 魔法冲刺保持趴姿（2026-08-18 新技能）

- **需求**：原版魔法冲刺（sp_kdash）在趴着（lurked）时施放，冲刺结束时自动
  站起；希望保持趴姿（用户确认：只做趴姿、默认开、趴姿动画滑行；验收场景：
  只能趴姿进入的通道内全程保持趴姿）。
- **原版机制（逆向确认）**：
  - `cast_kdash()`（Spell.as:335-369）：方向=目标-玩家，`norma()` 钳速到
    `dam*(1+(power-1)*0.5)`，冲量 dx/dy，`kdash_t`=帧数（默认 15、最小 7），
    清 isLaz/levit；需 `loc.levitOn`（仅 @levitoff 房间关闭）；
  - 施放门控：`control()` 在 work=="lurk"/"unlurk"/"res" 早退 → 只能从稳定趴姿
    （work==""）施放；
  - **根因**：`actions()`（1065-1069）冲刺期间每帧 `stay=false` → lurked 清理
    （`!stay→lurked=false`，1045-1048）→ animate() 脱离趴姿。趴姿动画被
    `t_work>0 && work=="lurk"` 分支延续到冲刺尾段（该分支在 lurked 判断之前），
    所以视觉上"结束时站起"。
- **实现（frame-late 姿态接管，不改游戏文件）**：`src/MSWDashPose.as`
  - 进入：kdash_t 0→>0 且 lurked && work==""（稳定趴姿施放）；
  - 冲刺中每帧强制 `stay=true / lurked=true / lurkX=X / lurkBox=null`
    （抵掉三个 lurked 清理路径），`work="lurk"+t_work=20` + `animState=""`
    迫使 animate() 重放趴姿动画（滑行）；
  - 冲刺结束：停止刷新 work/t_work → t_work 自然衰减 → 身体冻结趴姿帧，
    lurked 保持 → 可继续趴姿移动（lurkX 每帧跟随防位移清理）；
  - 退出：work=="unlurk"（原版 W/空格/蹲 解除流程）或 sost>=2（死亡）或
    玩家实例变化；回放期（onPause+godMode）经 MSWU.inGameplay 不介入（D-033）。
- **配置**：`dashKeepPose`（默认开），面板第 11 行（ROWS 11→12），
  哔哔小马设置页 + F6 浮层同步。
- **诊断**：dashPoseCast（接管次数）/dashPoseF（接管帧数）/dashPoseExit（解除次数）。
- **构建**：15226 字节（swf v14，仅字符串引用游戏类）。

## D-038 冲刺保持姿态扩展：蹲姿分支（2026-08-18 玩家实测"无效果"）

- **现象**：D-037 实现后玩家实测无效果。
- **根因**：玩家按 S"趴下"进入的是**蹲姿（isSit）**，不是 lurked 趴姿——
  本游戏 S 的语义 = 蹲下（Ctr keySit→sit(true)，UnitPlayer.as:2836）；lurked
  （趴伏/潜伏）需坐姿下按 W 且有 lurk box/tile 才进入（lurk()，2992 行），
  日常不常用。D-037 只接管 lurked → 蹲姿路径完全未覆盖。
- **原版蹲姿维护（逆向确认）**：
  - 蹲姿是**粘性**的：松 S 不解除（Ctr KEY_UP 只清 keySit，Ctr.as:806）；
  - 起身路径仅：W（2884 isSit&&keyBeUp&&!keySit→unsit）、SPACE（2706
    jumpp>0&&isSit→unsit）、`isSit && !stay`（2889——**冲刺期间 stay=false
    每帧触发**，即 bug 根源）、水/梯子/rat 边缘路径；
  - 蹲姿动画：animate() stay 分支 + walk 分支 `else if(isSit)` → "polz"/
    "roll" 爬行/翻滚姿势（4345-4430）——冲刺中保持 isSit 即显示蹲姿滑行。
- **修复**：MSWDashPose 双分支（poseMode：1=蹲姿 isSit，2=趴姿 lurked）：
  - 进入：kdash 0→>0 && work=="" && (isSit || lurked)；
  - 蹲姿强制：isSit=true + stay=true + scX/scY=sitX/sitY（sit(true) 幂等早退
    无法修碰撞盒，直接对齐；防 unsit 后盒尺寸残留 stayX/stayY）；
  - 冲刺中（kdash>0）即使按 W/SPACE 也保持姿态（"全程保持"语义）；
  - 退出：kdash==0 后游戏解除了姿态（isSit/lurked 变 false = 原版解除路径
    已执行）或 sost>=2 死亡 / rat 变形——交还原版。
- **配置**：沿用 dashKeepPose（默认开），面板第 11 行文案改"冲刺保持蹲/趴"。
- **构建**：15329 字节。

## D-039 冲刺保持姿态两轮"无效果"根因：internal 成员不可访问（2026-08-18 诊断）

- **现象**：D-037/D-038 两轮实现玩家实测均"无效果"。
- **诊断**：读 MSWConfig.sol（17:12 落盘，晚于 16:57 的 D-038 构建——用户确实
  用新构建玩过）——`dashPoseCast` **完全不存在** → 接管从未进入。且最后写入的
  诊断仍是举枪时代计数（lazAimF/raiseF/raiseBlocked——证明 MSWAim 组件正常）。
- **根因**：MSWDashPose.update() 顶部 `gg["lurked"] == true` —— `lurked` 是
  UnitPlayer **internal** 字段（UnitPlayer.as:165）。密封类 internal 成员从模组
  侧 bracket 访问抛 #1069 → 被外层 catch 吞掉 → **update() 每帧死掉**，任何
  分支（含纯 public 的蹲姿分支）都不执行 → dashPoseCast 永不计数。
- **佐证**：Sandevistan 源码 5921-5923 行明确记载"keyDowns 是 internal 无法
  访问"，并为卡键自愈改为"按 keyXML 强制 public 键布尔"（同一困境）。
- **修复（D-039）**：全部改用 **public 字段**——
  - 蹲姿分支（用户实测场景 S）：isSit/stay/scX/scY/sitX/sitY（均 public）；
  - 趴姿分支（尽力而为）：sloy∈{0,1}（public，Pt.as:23）代理 lurked 检测；
    lurked/lurkX/lurkBox internal 不可写 → 冲刺中 work="lurk"+t_work=20+stay
    强制（抵 !stay 与 |X-lurkX| 清理）；冲刺结束 t_work=1 快速收尾——位移
    >10px 的冲刺结束后趴姿无法保持（原版站起回归，lurkX 无法跟随）；
    box 趴伏（lurkBox!=null）冲刺中可能被 box 清理——已知限制；
  - 退出：kdash==0 后游戏解除了姿态（isSit=false / work=="unlurk" / sloy==2）
    或死亡/rat；
  - 诊断：kdashSeen（kdash 是否真的触发——区分"用户技能不是 sp_kdash"）、
    dashEntrySit/dashEntryLurk/dashEntryBlockWork/dashEntryBlockPose（进入链路）、
    lurkProbeOK/lurkProbeErr（internal 访问一次性探针，留档验证）；
- **教训**：游戏密封类成员必须先查可见性——internal 一律视为不可访问
  （bracket 会抛），public 才可读写。后续新增组件引用游戏字段前先 grep
  "var <字段>" 确认 public。
- **构建**：15631 字节。

## D-040 蹲姿冲刺"逐渐站起"：空中姿态分支无 isSit 处理 → 视觉钉扎（2026-08-18 玩家实测）

- **现象**：D-039 修复后（组件生效），蹲姿冲刺表现为"冲刺过程中逐渐站起，
  只在最后一刻（落地）恢复蹲姿"。
- **根因（逆向确认）**：animate() 的坐姿渲染只在 `stay || t_stay > 0` 分支内
  （4285 行）；冲刺中 actions() 每帧 `stay=false`（1068 行）且 `t_stay` 是
  private（79 行，模组无法续命）→ t_stay 5 帧耗尽后姿态落到外层分支 →
  空中分支（4533 行）渲染 "jump" 根帧**完全无 isSit 处理** → 飞行中必然显示
  站姿跳。冲刺结束落地（run() 置 stay=true）→ stay 分支重开 → 坐姿恢复
  ——"最后一刻恢复趴姿"。
- **修复（视觉钉扎）**：蹲姿模式冲刺中（kdash>0）每帧在钩子里
  `vis.osn.gotoAndStop("polz")` + `vis.osn.body.gotoAndPlay(1)`——polz 根帧 =
  原版蹲姿移动姿态；Flash 在所有 ENTER_FRAME 监听器之后才渲染 → 当帧生效，
  无闪烁。冲刺结束（落地后 stay=true）游戏自然渲染坐姿，无需钉扎。
- **细节**：不用 body.play()（会从游戏渲染残留的 jump 标签续播，混合姿态），
  用 gotoAndPlay(1) 从头重播身体循环（polz 根 + 腿部循环 = 爬行滑行姿态）；
  趴姿分支无此问题——lurk 动画分支在 animate() 顶部且带 return（4206 行），
  work="lurk" 刷新期间先于空中分支渲染。
- **诊断**：dashPosePin（钉扎帧数）。
- **构建**：15766 字节。

## D-041 蹲姿冲刺"瞬间站起动画抽搐"：polz+body.play 播进过渡帧段 → 冻结坐姿钉扎（2026-08-18 玩家实测）

- **现象**：D-040 的视觉钉扎（polz 根帧 + body.gotoAndPlay(1)）后，冲刺过程中
  出现瞬间的站起动画抽搐。
- **根因**：身体 MC 时间线前段含 down/up 过渡动画段（getStayFrame 坐姿帧=2，
  down/up 过渡在 3-26 帧区段，4328/4341 行）——`body.gotoAndPlay(1)` 每帧从头
  重播，身体会短暂播进站起过渡帧段 = 抽搐。
- **修复（D-041）**：钉扎改为**冻结坐姿**——根帧 "stay" + 身体
  `gotoAndStop(坐姿帧)`（零动画零抽搐）。坐姿帧取自冲刺前快照
  （每帧跟踪 body.currentFrame，进入时取上一帧值；开阔地=2、贴墙=49+，
  兼容各坐姿）；
  钉扎窗口扩展到**落地前**（Y 稳定 3 帧=落地；冲刺中/落地前 Y 变化不断钉），
  顺带修复"最后一刻才恢复蹲姿"（冲刺结束至落地间的站姿闪现）。
- **诊断**：dashPosePin 保持。
- **构建**：15999 字节。

## D-042 蹲姿冲刺仍有"站起动画抽搐"：坐姿帧快照时机 bug → 硬编码坐姿帧 2（2026-08-18 玩家实测）

- **现象**：D-041 冻结坐姿钉扎后仍有站起动画抽搐。
- **根因（代码复查）**：D-041 的坐姿帧"快照"逻辑有顺序 bug——身体帧跟踪
  （lastBodyFrame）在进入检测**之前**每帧更新；施放帧游戏 animate() 已把身体
  从坐姿帧 2 播进 polz/down/up 过渡段（3-26 帧），快照抓到的正是过渡帧
  （约 3-5），钉扎把身体冻在**半过渡姿态**——玩家看到的"站起动画"。
- **修复（D-042）**：不抓取——**硬编码坐姿帧 2**（getStayFrame 对 isSit 的
  默认返回值：开阔地坐姿；贴墙坐姿为 49+，冲刺时已离墙用开阔地坐姿正确）。
  删除身体帧跟踪；pinPose 失败计数 dashPosePinErr 留档。
- **构建**：15936 字节。

## D-043 蹲姿冲刺"滑行后期一次起身动画"：钉扎窗口改"落定坐姿"（2026-08-18 玩家实测）

- **现象**：D-042（硬编码坐姿帧 2）后冲刺全程冻结坐姿正常，但滑行后期会出现
  **一次**起身动画。
- **根因**：钉扎在"落地（Y 稳定 3 帧）"即停止——但落地后玩家仍在滑行
  （dx>4），游戏 animate() 的 polz 分支执行 `body.play()`，身体从冻结的坐姿帧 2
  播进 3-26 过渡段（起身动画帧段）；近静止分支的 `gotoAndStop(2)` 又被守卫
  （`currentFrame >= 3 && <= 26` 保护）挡住 → 起身动画完整播一遍后才 snap 回
  坐姿 = "一次起身动画"。
- **修复（D-043）**：钉扎窗口 = 冲刺中 || 未落地 || **未落定**——落定判定 =
  已落地（Y 稳定 3 帧）且 `animState=="down"/"downjump"`（游戏自己的坐姿闩锁，
  此时身体已在坐姿帧 2，起身动画无从开始）；按移动键（keyLeft/keyRight）视为
  主动移动，交还正常蹲姿爬行。
- **构建**：16066 字节。

## D-044 姿态滑行腾空下落过缓：kdash 飞行期零重力 → 接管期补回重力（2026-08-18 玩家实测）

- **现象**：全部功能验证完成后，玩家指出"趴姿滑行若腾空，其下落速度会过缓"。
- **根因（逆向确认）**：forces()（UnitPlayer.as:710-719）的 kdash 分支在
  kdash_t>0 期间**跳过整个重力分支**——魔法冲刺飞行期是零重力滑翔
  （原版即如此：dy 恒定不加速）。姿态接管保持的是飞行全程，故腾空时悬停
  感明显、下落过缓。
- **修复（D-044）**：接管期间（kdash>0）在帧钩子里补回重力——复刻 forces()
  公式：`dy += World.ddy(=1) * tile.grav`（采样点 Y - scY/4 同游戏），
  按 `loc.maxdy * grav` 钳制（与游戏重力门一致）；蹲姿/趴姿分支共用。
  冲刺结束后（kdash==0）游戏自然施加重力，无需干预。
- **诊断**：dashPoseGrav（补重力帧数）。
- **构建**：16246 字节。

## D-045 分发版 pfe.swf：只含本模组 loader 的干净构建（2026-08-18）

- **需求**：将模组分发给他人。对方需要 (1) 模组 SWF
  `mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf`，
  (2) 打过 loader 补丁的 `pfe.swf`（对方原版没有 loader，不会加载模组）。
- **约束**：当前共享 `pfe.swf` 是 6 模组合并文件（Sandy/RConnect/RVision/MSW/
  TDFC/RandomRooms）——直接分发会连带其他开发者 loader 代码（越界+授权问题），
  接收方没装那些模组也会有静默 IO 报错。
- **做法（干净+安全）**：从 1.02 基础副本
  `pfe_1.02_before_msw_merge_20260815.swf`（已复制到
  `build/pfe-patch/dist_build/base_102.swf`，不改共享 pfe.swf）用 FFDec
  `importScript` 把**只含 `loadMSWMod()` 的 MainFE** 定向合并进去：
  ```
  java -jar ffdec.jar -importScript <in.swf> <out.swf> <scriptsfolder>
  ```
  **注意参数顺序是 <in> <out> <folder>**（<folder> 放最后；放错顺序报
  "I/O error during reading"）。且用真正的 `ffdec.jar`（`ffdec-cli.jar` 只是
  1581B 启动桩），否则报 I/O error。
- **验证**：`-export script <outdir> <in.swf>` 导出 → `MainFE.as` 仅有
  `loadMSWMod()`（无 sandy/rconnect/rvision）；`-dumpSWF` 可正常解析。
- **产物**：`dist/` 分发包 → `dist/MoreSkillsWeapons_mod_v1.zip`
  （pfe.swf + mods/MoreSkills&Weapons/release/...SWF + README.txt 安装说明）；
  `dist/` 与 `build/pfe-patch/dist_build/` 已加入 .gitignore（15MB 二进制不入库）。
- **注意**：分发版 pfe 基于 1.02；接收方版本需匹配；Steam 校验文件会还原
  pfe.swf 需重覆盖；本包不含其他模组 loader，勿与其他 pfe 补丁混用。

## D-046 哔哔小马"模组"页签：克隆页签按钮 + 自行接管页面（2026-08-28）

- **需求**：用户要求把模组设置整合进哔哔小马既有界面——在主页签栏新开一个
  "模组"栏存放模组设置（取代原 PipPageOpt 叠加面板方案）。
- **约束**：`PipBuck.pages/page/kolPages/vis` 均 internal（D-039：#1069），
  无法把自定义 PipPage 注册进 pages 数组——"真页面"路线不可行。
- **做法（纯模组侧，零游戏文件改动）**：
  - 页签栏 = `pip.vis`（= `World.w.vpip`，public）下 `but0..but5`；loader 同域
    加载 → `getDefinitionByName(getQualifiedClassName(but5))` 克隆页签按钮类，
    `new` 实例改名"模组"，`x = but5.x + but5.width + 2`，挂进 vpip。
  - 点击后自行接管：隐藏 vpip 下非 chrome 可见子级（页面视觉是匿名
    instance* 子级；具名件与 visSetKey/visPipHelp 算 chrome）、本页签
    `gotoAndStop(2)` 高亮 + 其余 `gotoAndStop(1)`、`pip.snd(2)` 原版音效、
    显示 pip 绿内容（`PipPage.setStyle` 主色 #00FF99 + SimHei）。
  - 失活：点原版页签（后挂监听在游戏 pageClick 之后跑；已切页则不恢复旧页
    ——`PipPage.setStatus` 会自己重显页面）/ pip 关闭 / currentPage 引用变化
    / 再点本页签或 F6。恢复仅限"未切页的失活"（F6/重点击），防止复活旧页。
  - 键盘：模组页签激活时方向键/回车调参（原 Opt 页门控改页签门控）；
    pip 开着时 F6 = 开/关模组页签（原 F6 叠浮层方案废止）。
- **验证**：门禁 #3 冒烟（pfe-msw-test 隔离实例）：loader 无错、
  `ver=1.1-piptab`、frames 心跳、`tabBuild=1`（页签构建成功）、无 lastErr。
  点击接管（tabOn/内容显示）待玩家实机一次点击确认。
- **发布**：v1.1，release SWF 18036 字节；回滚 = `git checkout 910cdce --
  release/MoreSkillsWeaponsMod.swf`（v1.0 构建）。

### D-046 v2 修订（同日）：按钮迁入"主菜单"页 + 原版控件（2026-08-28 用户反馈）

- **反馈**：v1 的按钮与"主菜单"按钮并列不对，应与主菜单页的
  载入/保存/选项/控制/记录 并列；文字调整控件繁琐，要原版样式的按钮/滑块。
- **修正**（关键新知识）：
  - "主菜单"页 = PipPageOpt（pip 默认页 page=5），其子按钮是页 vis 内
    `but1..but5`（`PipPage.page2Click` public），按钮类可克隆；
  - 原版选项控件 = `visPipOptItem` 行自带 `fl.controls.CheckBox`（check）与
    `fl.controls.ScrollBar` 充当滑块（scr，min/maxScrollPosition + "scroll" 事件）
    ——同域加载下直接实例化 `visPipOptItem` 即可白嫖全套原生控件与样式；
  - Opt 页复用 visPipInv 布局（class 名与物品页相同），页视觉定位
    按"vpip 内 (165,72) 且当前可见"判定；
  - 滑块拖动期不落盘（"scroll" 连续触发，flush 卡顿见 D-035），关面板统一 save。
- **验证**：v1.2（19365 字节）冒烟通过：ver=1.2-optpanel、tabBuild=1
  （主菜单态 pip 默认即 Opt 页，按钮+12 行控件构建成功）、心跳正常、无 lastErr。

### D-046 v2.1/v2.3 加固（2026-08-29）：实机排查"主菜单找不到模组设置"

- **现象**：v1.2 在玩家实机的主菜单页里没有"模组"按钮；SOL 里
  `tabBuild=2`（陈旧值）曾误导冒烟结论，`lastErr=pipTab:#1010` 为更早会话遗留。
- **根因**（运行时探针实证，见 shared-knowledge
  ui-systems/discoveries/pip-ui-localized-structure.md）：
  v1.2 的 findOptVis 要求页面视觉类名含 "visPip" 且位于 (165,72)——
  实机页面视觉确实是 visPipInv@165,72（9 个），但 v1.2 冒烟的
  "tabBuild=1" 是 TDFC 自动驱动测试实例进游戏后的**陈旧 SOL 值**，
  实际在玩家会话中 findOptVis 从未成功（构建从未执行）。次级风险：
  汉化补丁把主栏按钮类改名为 ButPage_1536，硬编码类名/坐标不可靠。
- **修正**（v1.2.3）：
  - findOptVis 改为按**结构特征**定位：vpip 下"可见且含具名 but1/but5
    子件"的子级（探针 *PAGE 标记已验证 9 个页面全部命中）；
  - 行类优先从页面现成无名内容行（含 nazv 子件者）克隆，不再硬查符号名；
  - 全链路 null 安全 + 分阶段 lastErr（pipTab.stage0-5）+ tabStage/tabSnap/
    tabProbe 诊断落 SOL；行构建失败自动回退 pip 绿文字面板；
  - 坐标匹配放宽至 ±2px。
- **验证**：全新 SOL 冒烟——ver=1.2.3、tabProbe 的 *PAGE 标记全中、
  标题态不构建（页面视觉全隐藏，符合预期）；进游戏后的构建/显示
  待玩家一次实机复现（诊断已可全链路定位）。
