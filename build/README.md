# 构建工具链说明（可复现）

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

智能武器：`test-smart-unit.ps1` 验证锁定状态机、参数保存和寻路/转弯数学；`test-smart.ps1` 验证原版首步、绕实体箱体命中、跳弹继承、霰弹特殊弹药、64 发局部寻路、实际帧锁定/遮挡/恢复/暂停，以及 12 项设置与 F6。`test-smart-sandy.ps1` 只读复制已安装 Sandevistan 到隔离副本，用独立配置验证真实时停/回放和重建弹丸匹配，绝不修改其正式配置。

非致命激光枪：`test-laser.ps1` 验证眼部几何、原生半自动/装填/SATS、赠枪与存档接续、36 类敌人接管/恢复及实际攻击、恐慌子弹/爆炸/近战误伤、11 项配置与 HUD。`-Sandevistan` 只读复制已安装时停模组，追加冻结/慢步/开火/回放检查。输出在 `out/laser`；`LaserSmokeMod`、测试专用的 `smoke/SandevistanMod.as` 错误捕获器和任何测试副本都不能安装。

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
