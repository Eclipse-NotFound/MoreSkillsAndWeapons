# 设置中枢独立模组：探查与建议

2026-09-20。用户正在考虑把模组界面及接口从 MoreSkills&Weapons（MSW）拆出，本轮仅要求探查。以下建议尚未批准实施；未新建模组、改源码或部署。已安装 MSW 为 v1.4.1；调查时仓库 HEAD 为 a017198（含同期智能武器讨论）。

## 结论

适合拆分。现有界面已经通过 get/set 回调操作各模组的设置，不依赖跳弹、武器或技能算法；真正混合的是“公共界面宿主”和“MSW 自己的设置描述、日志、快捷键”。可以将公共部分抽成独立运行的设置中枢，让 MSW 与其他模组一样注册自己的页面。

目标应是：没有安装 MSW 时，Sandevistan 和 RealisticVision 仍能通过独立中枢显示设置，TDFC 仍能读取已注册的视野设置。各模组的玩法与配置文件继续由自身管理。中枢缺席时，玩法继续运行，只失去它提供的聚合入口。

这消除的是对 MSW 玩法模组的依赖；使用统一界面仍然需要设置中枢本身。复制同一份界面代码到每个玩法模组不能达到单一界面、统一维护的目的。

## 当前依赖：已核对源码与正式 SWF 字符串

| 模组 | 使用方式 | 本轮确认 |
|---|---|---|
| MSW | 提供登记簿、发布载体、渲染聚合页；自己注册 18 项 | 宿主与客户端职责混在同一 SWF |
| Sandevistan | 经载体 registerPage 注册 16 项；保留按类名查 MSW 的备用路径；测试使用 getPages | 注册失败仍有 F9 自有面板，非玩法硬依赖 |
| RealisticVision | 经载体 registerPage 注册 7 项 | 每 30 帧尝试，成功后停止；F11/F12 等原有入口不因此消失 |
| TDFC | GrabDiagnostics.visibility 经 getPages 读取 realisticvision 页的 enabled/mode | 不注册页面；缺失时 known=false，只降低抓取诊断的解释信息 |
| RConnect、RandomRooms | 在当前 src 搜索中未发现上述接口调用 | 正式 SWF 也未发现载体/registerPage/getPages/MSW 类名字符串；不据此宣称不存在任何其他机制关联 |

正式 SWF 字符串分布与这些源码调用一致，但字符串存在不等同于本轮运行成功。本轮没有重跑跨模组游戏实例。

Sandevistan 的游戏目录源码与 `D:/RemainsMod/mods/Sandevistan/src/SandevistanMod.as` 真源 SHA256 相同（85B71F3B…E4FF87）。未来修改其接入时必须改真源并同步；不能只改游戏目录镜像。

## 当前真实接口

会合点是：

```as3
var carrier:* = world.main.getChildByName("MSWModAPICarrier");
var hub:* = carrier != null ? carrier["modAPI"] : null;
hub.registerPage(modId, displayName, items, onPageClose, desc);
```

现有登记簿只有 registerPage 与 getPages 两个公共实例方法。相同 modId 重复注册会替换描述/items/回调，而非增加一页；getPages 返回内部数组本身。

items 的实际约定为 key、label、kind（check/slider）、min/max/step、hint、get/set，以及可选 def、suffix。def 决定该项是否参与恢复默认。

- check 调 set，注册方通常即时保存。
- slider 拖动时调 set；聚合面板整体关闭时，宿主逐一调用所有页面的 onPageClose。
- 切换模组子页目前不触发 onPageClose。迁移初版应保留含义，避免突然增加保存频率或遗漏原有延迟保存。
- 恢复默认会调有 def 的项的 set，随后调当前页 onPageClose。Sandevistan 当前注册项没有 def；直接搬过去不会自动获得默认值重置。
- 旧设计文档及部分源码注释仍提到 World.w.modAPI、跨模组 getDefinitionByName、300 帧上限。它们不是当前可靠契约：真实通道是显示树载体；Sandevistan 上限 36000 帧、每 10 帧一次，RV 每 30 帧无限重试。

## 建议怎么拆

独立中枢名暂称 ModSettings，仅为候选名称。

| 部分 | 建议归属 | 实际工作 |
|---|---|---|
| MSWPipTab：Pip 入口、子页、控件、提示、默认值与关闭保存调度 | 独立中枢 | 主要 UI 可复用；替换 mod.settings、mod.cfg 诊断与 MSWU.world 依赖 |
| MSWSettingsHub 的登记簿部分 | 独立中枢 | 保留小型注册契约，增加清晰的接口版本与异常隔离 |
| MSWSettingsHub.buildMswItems / getter / setter | MSW | 这些描述的是 MSW 的武器技能设置，应作为普通客户端注册 |
| MSWConfig、所有玩法类、MSW 诊断 | MSW | 不搬迁配置存储；不因设置界面独立而重置或迁移用户参数 |
| 载体发布、界面生命周期、公共界面诊断 | 独立中枢 | 从 MoreSkillsWeaponsMod.onFrame 中分离，拥有自己的初始化、更新和日志 |
| MSWPanel 的 F6 浮层 | 需单独明确产品范围 | 当前固定调用 buildMswItems，并直接保存 MSWConfig；不是可以原样搬出的通用面板 |
| MSWAutoTest / UI 冒烟 | 拆到各自测试侧 | 公共 UI 用 mock 页面测试，MSW 保留玩法与客户端注册测试；正式中枢不能依赖 MSW 来自动开档 |

建议首版先完成“Pip 聚合页 + 公共接口”的独立，F6 继续作为 MSW 私有快捷设置；Pip 打开时的 F6 快捷转交独立中枢，而非保留第二份聚合界面。这已能让其他模组脱离 MSW。若用户希望 F6 也成为所有模组的统一入口，则连浮层、模组选择和按键拦截一起通用化；需要同时移走 MSW 对这些按键的界面处理，不能两边各监听一套。

## 兼容迁移方案（推荐）

1. 独立中枢提供新的中性名称载体，并同时发布旧名称 MSWModAPICarrier 作为兼容入口。两个入口的 modAPI 指向同一个登记簿，不创建两套数据。
2. 保留 registerPage 五个位置参数及 getPages 的读取结构；保持既有 modId 与 item.key，特别是 TDFC 依赖的 realisticvision/enabled/mode。新接口增加版本标记，但不强迫旧客户端提供新参数。
3. 同一次发布中，把 MSW 改为普通注册客户端，取消其载体发布和 Pip 聚合 UI 创建。仅加兼容入口不能让未修改的 v1.4.1 自动交出宿主职责：它还会继续更新自己的 UI 和登记簿。
4. Sandevistan、RV、TDFC 可先通过旧入口继续工作，之后由各自项目迁移到新名称。兼容入口只是名字，独立中枢可在 MSW SWF 完全不存在时提供它。
5. 独立中枢需要自己的游戏 loader。必须直接由游戏加载，不能让 MSW 负责加载它，否则卸掉 MSW 后仍然失效。根 pfe.swf 的追加 loader 需按部署流程做；本轮未改。加载函数发起顺序不保证异步完成顺序，客户端必须允许中枢晚到。
6. 首版按游戏重启切换整体版本，不承诺运行中更换中枢。现有 Sandy/RV 注册成功后不再重试，新中枢若在运行中替换登记簿会丢页面；兼容期应维持同一登记簿对象的生命周期。

可选路线比较：

| 路线 | 收益 | 代价 / 建议 |
|---|---|---|
| 独立宿主 + 旧入口兼容 | 立即取消对 MSW 的依赖，已有两个注册方和一个读取方可以不同时升级 | 推荐；中枢与 MSW 仍须配套发布，旧入口维护成本很小 |
| 所有模组一次性改用全新接口 | 名称和契约一次统一 | 需同时改/验证多个独立项目，更易漏掉 TDFC 和各自测试；不推荐作为首步 |
| 中枢通过 MSW 加载，或复制界面到每个模组 | 看似改动少 | 前者仍依赖 MSW，后者可能出现重复界面；不能达成本次目标 |

## 必须留意的具体问题

- **单页恢复默认消失**：ensureTabRow 在页面数 <2 时提前返回，“恢复默认”按钮也在后面创建。独立中枢只装一个玩法模组时会触发，首版应修复并回归。
- **内容容量**：当前硬截断 18 行，尚无滚动；子页签也只水平累计宽度。独立后接入数量增加会暴露容量问题，至少要明确容量并给出可见提示；若同步承接更长设置页，应实现滚动/分页，不能继续静默隐藏项。
- **登记变化通知**：重复注册相同 modId 可以更新数据，但当前 UI 主要按页数判断重建；同一页内容更新和界面打开期间新模组加入需要重新渲染的信号。
- **输入职责**：F6 展开期间要阻止游戏移动/开火，按键绑定对话框期间要让行；宿主拆走后不能让 MSW 的疾跑切枪等按键处理抢先执行。
- **异常隔离**：单项 get/set 有防护，但恢复默认的 set 循环只有整体 try/catch，一项失败会中断其后的重置。中枢应逐项记录失败，避免一个注册方破坏其他页。
- **接口用途已超出绘制**：TDFC 通过 getPages 读其他模组配置摘要，因此不能只移 UI 后删除查询方法。首版保留兼容，不借机将所有跨模组玩法通信也集中进设置模组。
- **存储身份**：SharedObject 的路径与 SWF 身份相关。把 MSWConfig 搬进新 SWF 会有“旧设置丢了”的风险；按上述边界保留原配置代码与正式路径可避免这次迁移。
- **兼容与回滚**：至少把根游戏 loader、新中枢 SWF、MSW 客户端 SWF 视作配套发布集。回滚也要恢复同一组，避免旧 MSW 内置宿主与新中枢并存。

## 验收应证明什么

1. 不放 MSW SWF，只装独立中枢 + Sandevistan/RV，两个真实页面可用、保存后重启保持；TDFC 读取视野诊断仍有值。
2. 只有 MSW、没有中枢：玩法正常，保留约定的 F6/配置降级入口；只有中枢、零页面：正常显示空状态；只有一页：恢复默认可用。
3. 中枢先到/后到、重复注册、坏回调、晚到页面：不重复、不丢页、不阻断其他模组。
4. MSW 18 项、Sandy 16 项、RV 7 项的开关/滑块/保存行为兼容；MSW 跳弹原有回归继续通过。
5. Pip 开关、换页、读档、F6 与游戏按键互不冲突；新旧入口读到同一登记簿。
6. 正式安装与整组回滚均验证，保留所有原有 loader；初版限定实际游玩的根目录 1.02，DLC 1.03/1.04 单独评估。

## 证据索引（相对游戏根）

- mods/MoreSkills&Weapons/src/MSWSettingsHub.as:25（登记）、:47（查询）、:53（MSW 设置描述）。
- mods/MoreSkills&Weapons/src/MoreSkillsWeaponsMod.as:143（注册与输入）、:180（载体）、:220（玩法同帧更新 UI）、:360（Pip/F6 输入）。
- mods/MoreSkills&Weapons/src/MSWPipTab.as:175（登记簿依赖）、:680（子页/默认按钮）、:747（重置）、:799（切页）、:847（18 行截断）、:1244（关闭保存）。
- mods/MoreSkills&Weapons/src/MSWPanel.as:30（私有项构造）、:118（F6 设置与保存）。
- mods/Sandevistan/src/SandevistanMod.as:681（重试）、:3995（注册）、:4040（16 项）；真源位置见上。
- mods/RealisticVision/src/RealisticVisionMod.as:628（调用门控）、:3009（注册）、:3049（7 项）。
- mods/TDFC/src/GrabDiagnostics.as:50（通过中枢读取视野诊断）。
- shared-knowledge/knowledge-validation/discoveries/mod-loader-cross-domain-anomaly.md：兄弟域查类不可用，显示树会合点的实证。
- shared-knowledge/knowledge-validation/coordination/registry.md：当前 F6、Pip 聚合 UI 与载体仍登记在 MSW 名下；真正实施迁移时再更新归属。
