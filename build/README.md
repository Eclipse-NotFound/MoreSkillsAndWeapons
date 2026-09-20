# 构建工具链说明（可复现）

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
3. `-external-library-path` 不接受 SWF（只认 SWC），因此模组代码采用
   完全动态访问架构（getDefinitionByName + bracket 访问），编译期零游戏类依赖。

## 使用

隔离编译（PowerShell，在 build 目录执行）：

```powershell
New-Item -ItemType Directory -Force out | Out-Null
& 'D:\Program Files\Adobe Animate 2024\jre\bin\java.exe' '-Dfile.encoding=UTF-8' -jar 'D:\Program Files\Adobe Animate 2024\Common\Configuration\ActionScript 3.0\bin\mxmlc.jar' '-target-player=11.1' '-source-path+=../src' '-output=out/MoreSkillsWeaponsMod.swf' '../src/MoreSkillsWeaponsMod.as'
```

跳弹验证：`./test-ricochet.ps1` 运行 AIR 确定性断言；`./test-game-smoke.ps1` 在复制的游戏资源上执行真实控件/子弹冒烟。二者使用独立应用 ID，结果在 `out/`；不写真实 pfe 存档。第二个脚本中的测试专用文档类只用于测试，不可将 `out/smoke/SmokeMod.swf` 当发布产物。

伤害诊断：`./test-damage.ps1` 在隔离游戏副本中调用原版 Bullet.step/run 和 Unit.udarBullet，验证十次连续反弹的实际扣血、护甲/穿甲、精确墙面碰撞及轻机枪基础精度下的距离命中率。世界暂停后手动推进子弹，并非自然实战录像；命中率统计是随机样本。结果在 `out/damage/results.txt`，`out/damage/DamageSmokeMod.swf` 是测试探针，禁止部署到正式 release。

旧入口如下，**直接覆盖正式 release**，使用前走发布门禁；其裸 java 命令需要 PATH 可用：

```
cd build
build.bat
```
产物：`release\MoreSkillsWeaponsMod.swf`（swf 版本 14 ≤ 运行时 41）。

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
