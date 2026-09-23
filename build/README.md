# 构建工具链说明（可复现）

## 当前版本：自适应转弯半径

旧「平滑弹道/平滑程度」已替换为「自适应转弯半径/最小半径倍率」。旧开关状态迁移，普通倍率原样保留；最小倍率10–200%/步长10/默认10%，有效下限不高于普通倍率。以下历史小节的smooth-mode入口已由自适应入口替代，不部署旧产物。

- `test-smart-unit.ps1`：131条规则，含旧配置迁移、新字段优先、最大可行倍率、最低值、稳定后恢复、预测预算耗尽及透窗路线兼容。
- `test-smart.ps1`：16项真实设置、Pip/F6保存与默认值、原单目标回归；新增项所在settings.png已检查。
- `test-adaptive-radius-production.ps1 -ProductionSwf <准确生产SWF> -Nodebug`：24项真实物理检查；固定200%与自适应的实际命中对照、倍率轨迹、恢复、绕箱、通道、反弹、原寿命/预算和64弹压力。输出out/adaptive-radius-production。
- `test-smart-sandy.ps1 -AdaptiveRadius`：真实时停逐发保留目标、30/40/50%普通倍率与10/20/30%最小倍率，回放前关闭模式并改为200%仍沿用原值。输出out/sandy-adaptive；旧-SmoothMode保留为参数别名。
- `test-multi-lock-production.ps1`、`test-exclusion-production.ps1`：自适应开启后的52项多锁及312项单菜单豁免/实际单位/在途弹检查。
- `test-glass-production.ps1`：39项原生透窗/破窗/装甲窗绕行；关闭及开启自适应时均保留撞窗停弹，后续子弹通过真实破口。
- `tools/plot-adaptive-radius.py <结果目录>`：Pillow读取真实位置与倍率记录绘图，不重新模拟。

上述启动/规则/智能/时停脚本支持-GameDirectory指定实际游戏根，允许从嵌套独立检出测试。生产文件须单独通过激光真实读档/光束检查及安装前后900帧检查；相同RuntimeDirectory不能同时跑两种场景。当前实验与候选指纹见knowledge/experiments/smart-adaptive-radius-20260923.md。

弹道平滑回归：`test-smooth.ps1` 测原生轨迹拐角、距离、曳光、绕墙扣血、跳弹入墙面、时限/寿命、清理及 64 发批量，结果和截图在 `out/smooth/`。`test-smart-sandy.ps1` 同时测真实慢步/回放的曲线。两者支持 `-SourcePath` 指定固定源码快照（相对 build 目录），生产候选分别写入各自结果目录的 `Production.swf`；Smoke/Probe 仍禁止部署。详见 `knowledge/experiments/smart-smoothing-20260920.md`。

v1.5.1 起真实游戏 UI 测试需要正式安装 ModSettings 及其 loader。`test-game-smoke.ps1`、`test-damage.ps1`、`test-smart.ps1` 可用 `-HostSwf` / `-SettingsSwf` 指定预部署候选；测试只复制到私有目录。`test-installed.ps1` 使用正式宿主与正式依赖字节。

## 依赖
- Java：当前使用 `D:\Program Files\Adobe Animate 2024\jre\bin\java.exe`（17.0.10，2026-09-19 实际构建与测试通过；无需 PATH 配置）
- Adobe Animate 2024 自带 mxmlc：
  `D:\Program Files\Adobe Animate 2024\Common\Configuration\ActionScript 3.0\bin\mxmlc.jar`
  （版本输出：Version 4.6.0 build 23188）
- playerglobal.swc：
  `D:\Program Files\Adobe Animate 2024\Common\Configuration\ActionScript 3.0\FP11.1\playerglobal.swc`
  （flex-config.xml 中已写死绝对路径）

## 为什么这样配（坑位记录，见 decisions D-007）
1. Animate 版 mxmlc 运行时要求 cwd 存在 `flex-config.xml`（defaults），
   且其 defaults 会读取 `./themes/Spark/spark.css` 与 `./localFonts.ser`——
   本目录提供 stub（spark.css 一行规则、localFonts.ser 空文件）。
2. 该 mxmlc 不会自动挂 playerglobal.swc，必须在 flex-config.xml 的
   `compiler.library-path` 里显式追加。
3. `-external-library-path` 不接受 SWF（只认 SWC）。主体保留动态访问；v1.5.0
   使用 `fe.Pt` 外部存根继承原游戏链表节点；v1.6.0 另有 Unit/UnitRaider、SatsCel、Weapon/Bullet 的最小外部声明，供同包访问与唯一子类编译。
   `build-smart-host.ps1` 先用 compc 生成 `out/SmartHost.swc`；必须作为 external 链接，
   不能把 `stubs` 加进模组 source-path，不能在产物中定义第二个 `fe.Pt`。
   compc 默认路径为 `D:/RemainsMod/mods/Sandevistan/build/tools/flexsdk/lib/compc.jar`，
   仅作为只读工具链使用，可传 FlexRoot 覆盖。源码主入口和 loader 契约不变。
   激光枪的四个宿主适配类由 `-includes` 保留、运行时延迟解析；build.ps1 自动检查链接报告，拒绝嵌入原生宿主类或 Smoke/Probe。

## 使用

隔离编译（PowerShell，在 build 目录执行）：

```powershell
./build.ps1
```

跳弹验证：`./test-ricochet.ps1` 运行 AIR 确定性断言；`./test-game-smoke.ps1` 在复制的游戏资源上执行真实控件/子弹冒烟。二者使用独立应用 ID，结果在 `out/`；不写真实 pfe 存档。第二个脚本中的测试专用文档类只用于测试，不可将 `out/smoke/SmokeMod.swf` 当发布产物。

伤害诊断：`./test-damage.ps1` 在隔离游戏副本中调用原版 Bullet.step/run 和 Unit.udarBullet，验证十次连续反弹的实际扣血、护甲/穿甲、精确墙面碰撞及轻机枪基础精度下的距离命中率。世界暂停后手动推进子弹，并非自然实战录像；命中率统计是随机样本。结果在 `out/damage/results.txt`，`out/damage/DamageSmokeMod.swf` 是测试探针，禁止部署到正式 release。

智能武器：`test-smart-unit.ps1` 验证锁定状态机、参数保存和寻路/转弯数学；`test-smart.ps1` 验证原版首步、绕实体箱体命中、跳弹继承、霰弹特殊弹药、64 发局部寻路、实际帧锁定/遮挡/恢复/暂停，以及 16 项设置与 F6（含多重锁定、视野外保持和平滑弹道）。`test-smart-sandy.ps1` 只读复制已安装 Sandevistan 到隔离副本，用独立配置验证真实时停/回放和重建弹丸匹配，绝不修改其正式配置。

非致命激光枪：`test-laser.ps1` 验证眼部几何、原生半自动/装填/SATS、赠枪与存档接续、36 类敌人接管/恢复及实际攻击、恐慌子弹/爆炸/近战误伤、11 项配置与 HUD。`-Sandevistan` 只读复制已安装时停模组，追加冻结/慢步/开火/回放检查。输出在 `out/laser`；`LaserSmokeMod`、测试专用的 `smoke/SandevistanMod.as` 错误捕获器和任何测试副本都不能安装。

激光发布行为检查：`test-laser-production.ps1 -ProductionSwf <生产SWF绝对路径> -Nodebug`（省略 ProductionSwf 则读正式 release）。独立驱动不链接 MSW 源码，原样加载产物，检查原生开火耗弹、光束中点实际像素、6 秒致盲与零生命伤害。输出 out/laser-shot；依赖当前通用 loader，仅修改测试副本清单。必须与前述 debug 机制测试区分：曾因自定义 trace 被发布编译删除，debug 测试与正式启动均过而正式开火失败。详见 knowledge/experiments/laser-release-fix-20260923.md。

激光可见眼位检查：`test-laser-combat.ps1 -ProductionSwf <生产SWF绝对路径> -Nodebug`，输出 out/laser-combat。独立驱动正常换枪/开火，不手写眼位、枪口或身体矩形，以截图测量坐标检查真正眼部命中；另测框外传感器、移动/转身、自然战斗失明持续、原版激光素材/图层/4步淡出。生成36类眼位对照图（青点=旧感知点、红点=现判定点）。使用 pfe-modsettings-combat 唯一ID避开旧自动打开Pip流程，不读写真实存档。此前按 eyeX/Y 构造的244条规则测试不能验证眼位与美术一致，发布时须同时运行此生产场景。

发布前也可运行同字节生产检查，无须先装到 release：`test-installed.ps1 -ProductionSwf <候选SWF绝对路径> -ExpectedVersion '1.6.0-dazzler' -ExpectedHudVersion '1-top-ccw' -RuntimeDirectory 'out\laser\runtime' -OutputDirectory 'out\laser-production'`。省略 ProductionSwf 才默认读取正式 release。

菱形 HUD：`./test-smart-hud.ps1` 做 30 项实际光栅检查并生成状态对照图；`./test-smart-hud-game.ps1` 做 14 项原游戏 HUD 检查并保存真实 Raider 上的标记截图，分别输出到 `out/smart-hud`、`out/smart-hud-game`。后者支持 SourcePath，用于固定源码快照。所有 Smoke/Probe 均不可部署。

安装后验证：先由 `test-game-smoke.ps1` 准备隔离资源，再运行 `./test-installed.ps1`。它复制正式 release 的同字节生产 SWF 到隔离实例，检查版本、持续帧计数及设置入口，默认输出 `out/install-smoke.json`。脚本不替换正式 release，失败时部署方须恢复已留存的备份；默认期望 v1.5.3，可用 ExpectedVersion 参数指定。真实 pfe 进程和存储不受影响。并行任务可用 RuntimeDirectory/OutputDirectory 选择独立资源和日志；本轮 HUD 安装检查使用：

```powershell
./test-installed.ps1 -ExpectedVersion '1.5.3-smart-diamond' -ExpectedHudVersion '1-top-ccw' -RuntimeDirectory 'out\smart-hud-game\runtime' -OutputDirectory 'out\smart-hud-production'
```

`build.bat` 现在也调用同一个隔离构建入口，不再直接覆盖正式 release：

```
cd build
build.bat
```
产物：`build/out/MoreSkillsWeaponsMod.swf`。安装时先备份旧 release，再按发布门禁复制生产产物；带 Smoke/Probe 的 SWF 不得安装。

## 部署（已完成，2026-08-15）
pfe.swf 的 MainFE 已追加本模组 loader 并部署到游戏目录：

- 路径：`app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf`
- 契约：加载后 `getDefinition("MoreSkillsWeaponsMod").init(main)`，`main` = MainFE 实例
- 合并流程（FFDec 26.2.1，`C:\Users\micha\Documents\_sandevistan_dev\ffdec\ffdec-cli.exe`）：
  1. `ffdec-cli -export script <dir> pfe.swf`（全量导出）
  2. 只修改 `scripts/MainFE.as`（复制到单独目录）
  3. `ffdec-cli -importScript pfe.swf <out.swf> <单独目录>`（定向替换，仅重编译 MainFE）
  4. 验证（字符串扫描 + `-dumpSWF` + 反编译回读）后覆盖部署
- 备份：游戏根目录 `pfe_1.02_before_msw_merge_20260815.swf`（本模组合并前状态）
- 详见 decisions D-010 与 shared-knowledge
  `knowledge-validation/discoveries/mod-loader-patch-structure.md`
- DLC/pfe.swf、DLC/pfeUI.swf（1.03/1.04）暂未合并（如需支持按同流程处理）

## 2026-09-23 智能参数更新

新增转弯半径倍率 10–200%（默认 50%，步长 10）及锁定菱形大小 12–80 px（默认 24，步长 2）；Pip/F6 共用。100% / 40 px 可恢复此前手感与大小。test-smart-unit 为 53 条，test-smooth 含四档原生半径对照/快照/跳弹，test-smart-sandy 验证录制后改倍率仍回放原值；参见 knowledge/experiments/smart-tuning-20260923.md。

根游戏已使用通用 loader，游戏副本必须复制 mods/loader-manifest.txt。本轮 test-smart、test-smooth、test-smart-sandy、test-smart-hud-game 已补齐；复制 SWF 本身不够。

生产候选固定到 out/smart-tuning；验证命令（build 目录）：

```powershell
./test-installed.ps1 -ProductionSwf (Join-Path $PWD 'out\smart-tuning\MoreSkillsWeaponsMod.swf') -ExpectedVersion '1.6.1-smart-tuning' -ExpectedHudVersion '2-adjustable-size' -RuntimeDirectory 'out\smart-hud-game\runtime' -OutputDirectory 'out\smart-tuning-production'
```

安装后省略 ProductionSwf，输出改为 out/smart-tuning-installed，核对实际 release 同字节。旧命令里的 ExpectedVersion 属历史版本，不用于当前产物。

## 2026-09-23 多重锁定

激光读档回归新增 `test-laser-reload.ps1 -ProductionSwf <准确生产SWF> -Nodebug`：装备保存后经原生 comLoad 读回，等待延迟换枪完成再射击；验证调试开关与命中分类，并在未暂停 EXIT_FRAME 对完整舞台做光束像素差分。独立输出 out/laser-reload；不可用直接强制装备的旧测试替代。详见 knowledge/experiments/laser-reload-debug-20260923.md。

智能规则增至 79 条，包含独立获取/脱锁、轮换与 256 目标无固定上限。`test-multi-lock-production.ps1 -ProductionSwf <生产SWF> -Nodebug` 原样加载生产文件，验证 51 项多目标行为：目视排除、三目标实际伤害、9 发均分、真实霰弹分散、独立遮挡/保持、死亡、模式切换及菱形。输出在 out/multi-lock-production。

`test-smart-sandy.ps1 -MultiLock` 使用单独 out/sandy-multi 副本，三次实际开火分别记录 30/40/50% 半径与不同目标。回放前改为 200% 并关闭多重模式，按每帧出生顺序核对原快照。开始前等待自动 Pip 初始化结束；超时也保留心跳，宿主异常会转为失败报告。原单目标测试入口保留。

该轮历史候选为 out/multi-lock/MoreSkillsWeaponsMod.swf，包含激光组件 3-visual-eyes，版本 1.7.0-multi-lock、HUD 3-multi-lock，不能覆盖后续正式版。安装前后用 test-installed.ps1 指定相应标记与独立 OutputDirectory。激光生产回归新增 OutputDirectory / ProbeSourcePath 参数，默认行为不变，供并发任务固定各自产物和探针；候选不能套用较新版本探针的视觉断言。

## 2026-09-23 可调平滑弹道

该轮生产版为 v1.8.0-smooth-mode，HUD 3-multi-lock、智能运动1.3-smooth-mode、激光4-reload-debug。冻结源码及同字节候选位于 out/smooth-mode-final，保留当时已安装的激光读档引用修复与命中调试设置；此产物现已被下节豁免版取代，不可覆盖当前正式版。

`build.ps1 -SourcePath <源码目录> -OutputDirectory <产物目录>` 可从固定源码构建，路径相对 build；链接报告与生产文件写入指定目录。默认仍读 ../src、输出 out。`test-smart.ps1 -SourcePath <源码目录>` 的 Production.swf 改写入 out/smart，不覆盖最终候选。

- `test-smart-unit.ps1`：95条规则，增加旧配置默认/保存/数值边界、转向速率连续变化、程度响应和紧急转向上限；真实设置驱动等待自动Pip初始化完成后才进入后续锁定场景。
- `test-smooth-mode-production.ps1 -ProductionSwf <准确生产SWF> -Nodebug`：独立加载正式文件，22项原生物理断言，覆盖移动目标、绕箱、窄通道、真实碰撞/跳弹、预算与64弹批量；输出 out/smooth-mode-production。关闭和0%逐点一致，50/100%均验证实际伤害。
- `test-multi-lock-production.ps1 -ProductionSwf <准确生产SWF> -Nodebug`：当前探针先检查平滑默认关，再启用50%运行52项多目标回归。
- `test-smart-sandy.ps1 -SmoothMode -SourcePath <源码目录>`：使用独立 out/sandy-smooth，真实时停录制三发不同目标、30/40/50%半径及25/50/75%程度；回放前关闭两种模式并改变设置，检查逐发原快照及伤害。
- `tools/plot-smooth-mode.py <结果目录>`：需Pillow，从测试输出的真实坐标生成 trajectory-comparison.png；不重新模拟弹道。性能采样与取图分开，不能从该压力场景推算日常FPS。

最终候选准确字节另跑 `test-laser-reload.ps1 -ProductionSwf <准确生产SWF> -Nodebug` 保证保留最新读档、失明和完整舞台光束。安装前检查命令（build目录；须先由平滑生产测试准备对应隔离资源）：

```powershell
./test-installed.ps1 -ProductionSwf (Join-Path $PWD 'out\smooth-mode-final\MoreSkillsWeaponsMod.swf') -ExpectedVersion '1.8.0-smooth-mode' -ExpectedHudVersion '3-multi-lock' -RuntimeDirectory 'out\smooth-mode-production\runtime' -OutputDirectory 'out\smooth-mode-final-startup'
```

安装后省略 ProductionSwf，并改 OutputDirectory 为 out/smooth-mode-installed。不要与使用同一 RuntimeDirectory 的场景并行运行。指纹、备份和覆盖范围见 knowledge/experiments/smart-smooth-mode-20260923.md。

## 2026-09-23 锁定豁免

v1.9.0-lock-exemption 在平滑弹道和激光4基础上增加五组31项。Pip各组独立成页；F6共八页，Tab/PageDown向后、PageUp向前。具体范围见 design/smart-lock-exemptions.md。

- `test-exclusion-unit.ps1`：1123条精确ID/变种、互不误伤、配置清洗和分组默认检查。
- `test-exclusion-production.ps1 -ProductionSwf <生产SWF> -Nodebug`：31个真实复选框保存/恢复默认、F6循环、31类原生单位匹配、单/多锁及在途弹、时停回放入口的顺序豁免，共289项；生成五页设置截图。回放部分为握手模拟，不替代完整Sandevistan联测。
- 上述两个新脚本及生产多锁、平滑、激光读档脚本可加 `-GameDirectory <实际游戏根>`，供嵌套的独立工作树使用。输出都在各脚本所在build/out内，不共享实际存档。

本轮冻结源码、产物与结果位于 `out/lock-exemption-work/`（独立git工作树）。正式候选是其 `build/out/MoreSkillsWeaponsMod.swf`。旧平滑/激光候选不含豁免，不能覆盖新正式版。启动测试 `ExpectedVersion` 改为 `1.9.0-lock-exemption`，HUD仍为 `3-multi-lock`；完整同字节验收与回滚见 knowledge/experiments/smart-lock-exemptions-20260923.md。

## 2026-09-23 锁定豁免单菜单（v1.9.1）

用户追加要求后，当前入口合并为一个「锁定豁免」，31项在其内部两页显示（18+13）；分类名保留在选项标签。F6共四个菜单，↑↓自动翻动长列表；恢复默认清除全部豁免，原配置键不变。

候选及冻结源移至 `out/exemption-menu/`，版本标记 `1.9.1-exemption-menu`。更新后的 `test-exclusion-production.ps1` 验证312项，包括唯一入口、旧勾选跨页回显、内部分页和F6全部选项可达；截图为settings-page1.png、settings-page2.png、settings-f6.png。启动检查复用 `out/exclusion-production/runtime`，结果分别写入 `out/exemption-menu/startup` 和 `installed`；不要与使用同一运行目录的场景并发。上一节v1.9.0冻结产物为历史版本，不覆盖当前正式版。
