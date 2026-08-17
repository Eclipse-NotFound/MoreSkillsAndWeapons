# 构建工具链说明（可复现）

## 依赖
- Java 8+（本机 Oracle JDK 1.8.0_411）
- Adobe Animate 2024 自带 mxmlc：
  `C:\Program Files\Adobe\Adobe Animate 2024\Common\Configuration\ActionScript 3.0\bin\mxmlc.jar`
  （版本输出：Version 4.6.0 build 23188）
- playerglobal.swc：
  `C:\Program Files\Adobe\Adobe Animate 2024\Common\Configuration\ActionScript 3.0\FP11.1\playerglobal.swc`
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
