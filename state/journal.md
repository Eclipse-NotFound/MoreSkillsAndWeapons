# MoreSkills&Weapons —— 开发日志

> 协议见 GOVERNANCE.md §8：只追加不改写，**新条目插在最上面**。

## 2026-09-19 接手核对：同步 v1.3.4 现状与验证边界

- 按用户要求接手 MoreSkills&Weapons，阅读职责、治理、记忆、近期日志、入口与设置相关源码、构建配置和设计/决策记录；接手时 master 工作树干净，HEAD 为 `7950f6c`。
- 旧 MEMORY 停在 v1.3.3；源码诊断为 `1.3.4-hub`，release 26383 字节且与 HEAD 一致。2026-09-05 `f17880c` 已记录页签字号调整、恢复默认持久化、Sandevistan 自动接入实测，`7950f6c` 同步设计；将已完成事项移出待开发列表。
- 按 `MSWU.inGameplay()` 纠正旧快照：排除条件为 onPause 与 godMode 同时成立，单纯时停仍允许介入。跨模组设置以 `MSWModAPICarrier` 载体为准；旧设计与注释中的直接 World 属性/兄弟域查类路径不可照用。
- 构建依赖文件在 D 盘 Animate 路径存在，但本轮 PATH 查不到 Java；build.bat 直接写 release，未执行。本轮仅更新交接文件，没有编译、启动游戏、修改源码或部署产物。
- 下一步按用户具体开发需求推进；面板手感、D-044 落感及换机后举枪/切枪仍是历史记录未闭环项，未新增用户待办。dist 保持旧 v1.0，发布时再走门禁。

## 2026-08-29（九续） v1.3.3：跨模组通道定稿（modAPI 载体）——回应 Sandevistan 接入受阻

- Sandevistan 按契约实现后撞 #1065：兄弟模组域互不可见。证据成立，且推翻 shared-knowledge 旧结论（LoaderContext(false) 非同域，实为各模组独立子域；mod-loader-patch-structure.md 已二次修正）。这解释了既有观测：子域可见父域类（fe.inter/fl.controls 探针可用），兄弟互不可见。
- 方案取舍：改 loader 合并游戏域（动共享 pfe.swf + 全模组回归）不取；采用父域对象会合点——World 实例密封挂不了属性（#1056 第一次尝试静默失败，诊断空白暴露），改 **MSWModAPICarrier 动态载体挂 World.w.main**（幂等发布，getChildByName 可达）。modAPI=published 实测（SOL）。
- 待办：Sandevistan 侧重试循环改走 getChildByName("MSWModAPICarrier").modAPI（其常驻重试 10 帧一发，通道就绪后自动出现）；二期验收。D-044 落感与举枪/切枪仍待玩家。


## 2026-08-29（七续） v1.3.0：聚合页一期交付（宿主 API + 自注册 + 模组子页签）

- 按 design/mod-settings-hub.md 一期实施：新增 MSWSettingsHub（登记簿 + MSW 12 项 buildMswItems 自注册构造器 + makeGetter/makeSetter 闭包）；MoreSkillsWeaponsMod 增静态契约入口 settingsRegister（其他模组经 getDefinitionByName 调用）与 settings 实例；MSWPipTab 重构为登记簿驱动（renderRows 按当前页重建行、通用 min/max/step 滑块换算、≥2 注册方时顶部模组子页签行、单方自动平铺、close 统一调 onPageClose）；MSWAutoTest 注册 mock 页 + 自动切页验证。行容器沿用 MovieClip；rowOf 密封类防护保留。
- 关键发现：mock 注册在 ctor 早于 instanceInit 的 MSW 自注册 → 页序 = 注册序（宿主不排序，注册方自行约定；mock 仅测试实例存在）。
- 验证：自动驱动全绿——pages=2、tabOn=1、page 切换、rowOf=true、无 lastErr；截图人审：双页签渲染、MSW 12 行完整、帮助栏显示 mock/MSW 描述。
- 遗留：玩家实机验收 v1.3.0（用户实例仅 MSW 一页=平铺，与现状视觉等价）；二期 Sandevistan 接入（其仓库侧）；D-044 落感与举枪/切枪仍待玩家。


## 2026-08-29（六续） 模组设置聚合页规划成文

- 用户提出未来要把更多模组的设置整合进"模组"页。规划落盘 design/mod-settings-hub.md：注册式聚合契约（各模组 get/set 回调自持配置，宿主不越权写他人存储）、模组子页签 UI（≥2 注册方时出现，单方自动退化为平铺）、loader 链时序约定（MSW 之前加载的模组 ENTER_FRAME 重试注册）、控件扩展路线（choice/action/info）、分期（一期宿主 API+MSW 自注册 → 二期 Sandevistan 接入 → 三期其余模组）。未实现，待玩家确认后启动一期。


## 2026-08-29（五续） v1.2.11：数字字形/颜色对齐 + 修调参静默失效

- 用户特写对比指出：数字字形/颜色不一致、拖滑块数字不动。根因：①原版 nazv/numb 实为 `_sans/16/#00FF99`（探针实证），我此前近白色 + 自选字号；②rowOf 修密封类时"抛异常即 return null"——滑块/复选框事件永远找不到所属行，**调参全部静默失效**。修正：rowOf 抛异常改继续向父级；字体/颜色/样式表全套照抄（makeLabel 按 label/value/button 三源，PipPage.setStyle 挂原版样式表）；行上挂 mswSc/mswCb 供 snap 自检（rowOf=true）。
- 验证：全自动回归全绿（tabFont 探针 num=_sans/16/c65433、tabOn=1、rowOf=true、无 lastErr）。
- 遗留：玩家实机验收；D-044 落感与举枪/切枪仍待玩家。


## 2026-08-29（四续） v1.2.9：字体与背景对齐原版

- 用户指出背景/字体仍差很多。根因：①suppress 把页面视觉自带的背景/边框美术（大尺寸子件）也藏了——模组页只剩外层粗纹理；②标签用 SimHei，原版行标签实为 `_sans/16`（按钮 `_sans/20`，均非内嵌——探针 tabFont 实证）。修正：suppress 保留大尺寸子件（背景美术）；makeLabel 从游戏现成行 nazv/but5.text 抄字体名/字号/内嵌标志（tabFont 诊断落 SOL）；顺修 rowOf 在密封类（fl.controls.*）上访问动态属性的 #1069。
- 验证：全自动链路全绿（tabOn=1、tabFont=_sans/16、截图人审：字体与页面边框/纹理与原版一致）。
- 遗留：玩家实机验收；D-044 落感与举枪/切枪仍待玩家。


## 2026-08-29（三续） v1.2.7：行框比例对齐原版

- 用户再发对比图指出观感差距。量比例发现核心差：原版行框宽 ≈ 内容区 73%（页局部 ~550px，右侧留帮助/立绘区），我的 700 全宽。修正：行框 550x24、标签 14px、复选框 x=360、滑块 x=256 宽 240 高 14、数值 x=505、帮助栏移 x=600 宽 230。自动回归通过（tabBuild/tabOn/截图人审）。
- 遗留：玩家实机验收 v1.2.7；D-044 落感与举枪/切枪仍待玩家。


## 2026-08-29（再续） v1.2.6：面板版式对齐原版选项页

- 用户发来两图（模组页 vs 原版选项页）指出未对齐。修正：行框改不透明黑底+1px 暗绿边框（原 45% 透明在暗底上不可见）；列位置对齐（标签 x=12、复选框 x=440 居中、滑块 x=300 宽 315、数值 x=625 只显示数值）；右侧新增悬停帮助栏（标题+HELP_DEFAULT，行 MOUSE_OVER 显示说明）——对齐原版"悬停行右侧出说明"的 UX；suppress 反转：面板打开时页面只留子按钮+模组内容，pers/存档信息/记录文本全部让位（修复重叠）。自动驱动回归通过（tabBuild/tabOn、截图人审）。
- 遗留：玩家实机验收 v1.2.6；D-044 落感与举枪/切枪仍待玩家。


## 2026-08-29（续） v1.2.5：克隆空壳实锤，自绘+原版组件定稿（D-046 v2.5）

- 做了什么：玩家复现"仍无显示"→ snap 诊断显示按钮已构建（700,26）但玩家看不到 → 判别实验（debugPlace/wh 记录）实锤**克隆游戏符号类 = 零尺寸空壳**（汉化符号类美术靠运行时初始化）。v1.2.5 全部弃克隆：按钮自绘（绿框深底两态），行 = MovieClip + fl.controls.CheckBox/ScrollBar（原版选项组件，自带程序化皮肤），手绘开关/步进兜底；新增 MSWAutoTest 测试基建（appid≠pfe 激活：自动开档→pip.onoff(5) 开主菜单页→debugClick 派发真实点击）。
- 关键决定/发现：克隆游戏 UI 类不可行（wh=0x0）；Sprite 密封类挂动态属性 #1056（行容器必须 MovieClip）；fl.controls 组件同域可实例化且观感与原版一致；自动化闭环（MSWAutoTest + read_sol.py + 截图）可在不碰用户桌面的情况下完整回归 UI。知识沉淀：pip-ui-localized-structure.md 补克隆空壳教训。
- 验证：全自动链路全绿——tabBuild=1/tabOn=1/无 lastErr，截图人审：模组按钮入列、12 行控件全部渲染、复选框与滑块状态与配置一致。
- 遗留/下一步：玩家实机手感验收；D-044 落感 + 举枪/切枪触发；全闭环后重打 dist。

---

## 2026-08-29 v1.2.3：排查"主菜单找不到模组设置"（D-046 v2.3）

- 做了什么：实机诊断（用户 SOL：lastErr=pipTab:#1010）+ 自建测试实例 + 模组内探针（vpip 子级全量 dump 进 SOL）定位根因；v1.2.2→v1.2.3 加固（结构特征定位页面视觉、行类克隆现成行、null 安全、分阶段诊断、文字面板兜底）。
- 关键决定/发现：①**SOL 计数器跨会话累积**——tabBuild 陈旧值造出"假绿"，冒烟断言前必须清测试 SOL；②汉化补丁重命名 UI 类（主栏按钮=ButPage_1536，竖排左列），反编译的类名/坐标不可硬编码，但页面视觉 visPipInv@165,72 ×9 与子页按钮 but1..5 结构在实机成立（探针 *PAGE 全中）；③测试实例会被 TDFC AutoTest 钩子自动开进游戏（appid≠pfe 即激活），会污染"标题态冒烟"预期。结构结论沉淀 shared-knowledge ui-systems/discoveries/pip-ui-localized-structure.md。
- 遗留/下一步：玩家实机复现（重启→主菜单页）；诊断可全链路定位残留问题；D-044 落感与举枪/切枪确认仍待玩家。

---

## 2026-08-28（深夜） v1.2：模组面板迁入主菜单页 + 原版控件（D-046 v2）

- 做了什么：按用户反馈重做——移除主页签栏按钮，"模组"按钮改为克隆 Opt 页（主菜单页）子按钮类挂 but5 旁（与载入/保存/选项/控制/记录并列）；设置行改为实例化 visPipOptItem（自带 fl.controls.CheckBox 复选框与 ScrollBar 滑块，与原版选项页同款控件），数值滑块拖动实时生效、关面板统一 save（防高频 flush，D-035 教训）；F6 在哔哔小马任意子页直接跳 Opt 页并展开面板（pip.onoff(5) public）。MSWPanel 移除文字宿主，模组面板纯鼠标交互。
- 关键决定/发现：Opt 页复用 visPipInv 布局（class 名与物品页相同，按 (165,72)+可见 判定页视觉）；原版选项控件 = visPipOptItem 行自带 CheckBox/ScrollBar，同域下 new 即白嫖全套原生控件；游戏 setStatItems 会复显行 → 面板打开期间每帧压制。详见 decisions D-046 v2 修订。
- 遗留/下一步：玩家实机点击验收（tabOn/tabOff）；D-044 落感 + 举枪/切枪触发确认；验收后重打 dist zip（当前 dist 是 v1.0）。

---

## 2026-08-28（晚） v1.1：哔哔小马"模组"页签（D-046）

- 做了什么：按用户需求把模组设置整合进哔哔小马主页签栏——新建 MSWPipTab（克隆 but5 页签类挂栏尾，点击后接管页面显示 pip 绿设置内容），MSWPanel 移除 PipPageOpt 叠加宿主改页签宿主，主类按键门控改页签 + F6 语义更新（pip 开着时 F6=开关页签）。build.bat/flex-config.xml 修复本机工具链路径（C 盘旧路径→D 盘 Animate 2024）。发布门禁走完（构建/版本标记 diagSet ver=1.1-piptab/部署/冒烟/D-046/记忆/提交）。
- 关键决定/发现：PipBuck.pages 等均 internal，"真页面"不可行 → 克隆页签按钮 + 自行接管（隐藏 vpip 非 chrome 子级，切页失活时靠 PipPage.setStatus 自恢复）。冒烟（pfe-msw-test 隔离实例）：loader 无错、tabBuild=1（页签构建成功）、心跳正常、无 lastErr。
- 遗留/下一步：玩家实机点击页签验收（读 tabOn/tabOff）；D-044 落感 + 举枪/切枪触发确认；验收后重打 dist zip（当前 dist 是 v1.0）。

---

## 2026-08-28 诊断复核 + SOL 解析工具 + 知识提升

- 做了什么：逐字节破解本机 Flash 写出的 .sol（AMF3 方言：顶层名 2 字节变长 / 回引用表空串不入表 / 文件尾 0x00），落地解析器 `build/tools/read_sol.py`；实机诊断复核——D-044 补重力实机触发 6 次、击落 projHit/projBoom=2/2、kdashSeen=399、ricochet bounce=159（玩家迁移新机后持续游玩中）；shared-knowledge 七篇 discoveries 提升 facts（bullet-wall-impact / explosion-blast-bullets / phisbullet-grenade-physics / runtime-weapon-creation / sats-trajectory-arc / pippageopt-overlay / mod-loader-patch-structure），修正 2 处库内交叉引用 + swf-patching 技能路径。
- 关键决定/发现：SOL 格式规律与解析法沉淀至 shared-knowledge `knowledge-validation/methods/sol-diag-reading.md`；**diag 计数器跨会话累积、换机/换用户即重置**——迁移前旧诊断不可得，"举枪/切枪迁移后复测"需以新触发记录为准。
- 遗留/下一步：D-044 落感待玩家主观确认（数据已佐证）；举枪/疾跑切枪实机各用一次即闭环；玩家满意后可启动"接入游戏技能系统"设计。AGENTS.md:45 仍指向旧 discoveries 路径（受保护文件，已报告待用户改）。

---

## 2026-08-27 外置记忆迁移

- 由 state/current-status.md + state/HANDOFF.md 拆分迁移（原文在 git 历史）：现行状态 → state\MEMORY.md；state\design\design-冲刺保持趴姿.md 移至 design\；两份迁移报告浓缩为下方 journal 条目后删除。
- HANDOFF 中"已验证游戏机制清单"与"诊断计数器清单"暂以 git 历史为准，后续视需要沉淀入 shared-knowledge 或本文件。

---

## 开发历程（按 git 提交日期，新在上）

### 2026-08-26 交接刷新
- HANDOFF 补全（§0/§2/§4）+ current-status 更新为 v1.0（D-044 唯一待确认）。

### 2026-08-18 v1.0 收尾：冲刺姿态全链路 + 分发包（D-035~D-045）
- D-035/D-036：举枪排查——修复"先 Shift+W 再蹲下"流程失效 + 移除按键路径高频 SharedObject.flush（举枪卡顿）。
- D-037~D-044（八轮迭代，设计见 design/design-冲刺保持趴姿.md）：魔法冲刺保持趴姿/蹲姿。**D-039 关键根因**：internal 字段（lurked/lurkX/lurkTip/lurkBox）bracket 访问抛 #1069 被 catch 吞掉 → 组件每帧死亡，两轮"无效果"——游戏密封类 internal 一律不可访问（已回馈 shared-knowledge/modding-interop）；此后引用游戏字段必须先 grep "var <字段>" 确认 public。D-040~D-043 逐一修逐渐站起/抽搐/初始化帧 bug/滑行后期起身；D-044 补腾空重力（待玩家最终确认）。
- D-045：分发包 dist/MoreSkillsWeapons_mod_v1.zip（基于 pfe_1.02_before_msw_merge 备份用 FFDec importScript 生成干净 1.02 pfe.swf，仅本模组 loader，已反编译验证）。
- shared-knowledge 沉淀：新增 player-pose-states / magic-dash-kdash，增强 player-vis-anim-pipeline / diag-sampling-rules / modding-interop。

### 2026-08-17 建仓与首批功能（D-001~D-034）
- 初始提交：跳弹 / 可编程榴弹炮 / 蹲梯举枪 / 手雷击落 / 疾跑切枪。
- D-013~D-025：跳弹大量反弹问题修复链；D-026~D-032：举枪技能演进（D-031 改键 Shift+W；D-032 修复失效三根因：heldShift 事件顺序 / 吞键 stopImmediatePropagation 失效→改写 Ctr 状态 / sol 配置误存）。
- D-033：时停期放行迁移技能（与 Sandevistan 共存）；D-034：散布异常排查（无污染）+ mswglau 散布恒定。
- **Sandevistan 技能迁入**（手雷击落 MSWProjHits + 疾跑切枪 MSWSwaprun，面板第 7-10 行；迁移报告与审核结论原文在 git 历史：state/迁移报告-2026-08-17-Sandevistan技能迁入.md、state/MIGRATION-Sandevistan-swaprun-projhits.md）。共存约定：MSWU.inGameplay() 含 onPause——时停/回放期不介入；已知风险：时停期间切枪不生效（共存取舍）、旧 config.txt 值不迁移。待实机复测。
- pfe.swf 合并（追加本模组 loader，备份 pfe_1.02_before_msw_merge_20260815.swf）。
