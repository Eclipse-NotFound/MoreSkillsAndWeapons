# 实验记录：构建工具链探索（2026-08-15）

> 过程性记录，最终结论见 `build/README.md` 与 `decisions/decisions.md` D-007。

## 目标
找到本机可复现的 AS3 SWF 编译方案，产物需能被游戏 Loader（子 ApplicationDomain）
加载，且不把游戏类嵌入模组。

## 尝试与结果
1. **系统 PATH / Adobe 目录扫描**：无 mxmlc/asc、无独立 Flex/AIR SDK。
2. **Animate 2024 自带 mxmlc.jar**（`Common/Configuration/ActionScript 3.0/bin/`）：
   `java -jar mxmlc.jar -version` → Version 4.6.0 build 23188，可用。
3. **该 mxmlc 的 defaults 依赖 cwd 文件**：依次报缺
   `./flex-config.xml` → `./themes/Spark/spark.css` → `./localFonts.ser`；
   在 build 目录提供 flex-config.xml + 两个 stub 后通过。
4. **playerglobal 不自动挂载**：`-dump-config` 确认其 library-path 为空、
   不按 target-player 约定解析 playerglobal；在 flex-config.xml 的
   `compiler.library-path` 显式追加 Animate 的 `FP11.1/playerglobal.swc` 后
   Sprite 基类可解析。
5. **`-external-library-path` 拒绝 SWF**：报"pfe.swf 不是 SWC 文件"——
   以 pfe.swf 为 externs 做 typed 引用的路线不可行（Animate 版编译器只认 SWC）。
   → 由此确立完全动态访问架构（decisions D-001）。
6. **编译器怪癖**：函数仅在 try/catch 内有 return 会报"函数没有返回值"，
   try/catch 之后需补 return。
7. **cmd 批处理坑**：build.bat 必须 CRLF + 纯 ASCII（LF 或 UTF-8 中文在 cmd
   下解析错乱；python 内联写 `\b` 转义会吞反斜杠）。

## 最终方案
- 命令：`java -jar "<Animate>/.../bin/mxmlc.jar" -target-player=11.1
  -source-path+=..\src -output ..\release\MoreSkillsWeaponsMod.swf
  ..\src\MoreSkillsWeaponsMod.as`（cwd=build，见 build.bat）。
- 产物：swf v14、CWS 压缩、文档类 `MoreSkillsWeaponsMod`（SymbolClass
  symbol 0 已解析验证），游戏类仅以 getDefinitionByName 字符串引用，零嵌入。
