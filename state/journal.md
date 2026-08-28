# MoreSkills&Weapons —— 开发日志

> 协议见 GOVERNANCE.md §8：只追加不改写，**新条目插在最上面**。

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
