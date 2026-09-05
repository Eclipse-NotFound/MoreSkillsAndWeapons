# 设计：哔哔小马"模组"设置聚合页（多模组设置整合规划）

> 2026-08-29 立项。目标：把其他模组的设置逐步整合进哔哔小马"模组"页，
> 形成统一的模组设置中心。本文档是规划基线，实现按"分期路线图"推进。
> 现有页面机制见 decisions D-046（v1.2.x 系列）。

## 1. 目标与原则

1. **统一入口**：玩家在哔哔小马"模组"页一处调整所有模组的设置；
2. **不越权**：MSW（宿主模组）只做 UI 与调度，**永不读写其他模组的配置**——
   每个模组的设置数据仍归各模组自己所有、自己持久化（GOVERNANCE 权限模型）；
3. **松耦合**：接入方与宿主只依赖一个很薄的注册契约；某模组未安装时自然
   不显示，互不影响；
4. **观感一致**：全部复用已验证的原版控件与样式（_sans/16/#00FF99、
   CheckBox/ScrollBar、行框规范，见 D-046 v2.11 与 shared-knowledge
   pip-ui-localized-structure）。

## 2. 现状基线（v1.2.x）

- "模组"按钮挂在 Opt 页（主菜单页）子按钮栏；面板打开时页面只保留
  子按钮 + 模组内容（其余让位）；
- 行 = 自绘 MovieClip + fl.controls.CheckBox（开关）/ ScrollBar（滑块）；
- 12 行写死在 MSWPipTab.SPEC，直接读写 MSW 自己的 MSWConfig；
- 自动驱动基建 MSWAutoTest（appid≠pfe 激活）可全自动回归 UI。

## 3. 架构：注册式聚合（回调契约）

核心决策：**设置项由各模组自己注册，宿主只渲染与转发**。

### 3.1 注册契约（宿主侧 API，MSW 仓库实现）

```
MoreSkillsWeaponsMod.settings.registerPage(
    modId: String,          // 唯一 id，如 "sandevistan"（registry 登记）
    displayName: String,    // 页内显示名，如 "斯安维斯坦"
    items: Array,           // 设置项描述（见 3.2）
    onPageClose: Function   // 可选：面板收起时回调（供延迟保存 flush）
)
```

- 注册方通过 `getDefinitionByName("MoreSkillsWeaponsMod")` 拿宿主类，
  调用其静态入口（宿主内部转发到单例）；
- **get/set 用回调**：每项提供 `get()` 与 `set(v)`，配置的读写、持久化
  时机完全由注册方决定——宿主不碰任何别人的存储；
- 未安装宿主时注册方静默跳过（try/catch + null 检查），各模组自己的
  原有设置 UI（如 Sandevistan F9 面板）继续保留，不受影响。

### 3.2 设置项描述（一期支持 check / slider）

```
{ key, label, kind: "check"|"slider",
  min, max, step,        // slider 用
  hint,                  // 悬停说明（右侧帮助栏显示）
  get: Function,         // 返回当前值（Boolean/Number）
  set: Function          // 写回值；连续项（滑块）由宿主在拖动中只调 set，
                         // 关面板时统一调 onPageClose 供注册方 flush
}
```

二期扩展（见 §6）：`choice`（枚举轮换）、`action`（按钮执行动作）、
`info`（只读信息行）。

### 3.3 注册时序（loader 链顺序问题）

MainFE 加载链固定：Sandy → RConnect → RVision → **MSW** → TDFC → RR。

- MSW 之后的模组（TDFC/RR）：init 里直接注册即可；
- MSW 之前的模组（Sandy/RConnect/RVision）：注册时宿主尚未加载 →
  **约定重试**：注册方在自己的 ENTER_FRAME 里重试
  `getDefinitionByName("MoreSkillsWeaponsMod")`，最多 ~300 帧，成功即注册；
- 宿主对"晚到/早到"都不感知——注册即追加，无顺序要求。

## 4. UI 结构：模组选择 + 分页渲染

### 方案对比

| 方案 | 描述 | 优点 | 缺点 |
|---|---|---|---|
| A. 模组子页签（推荐） | 面板顶部一排模组名小页签（自绘，仿原版 载入/保存/… 行），点击切换该模组的设置行 | 与原版交互一致；每模组行数不限；找设置快 | 多一排自绘控件 |
| B. 单列分组滚动 | 全部设置一列，按模组分节标题 + 原版式滚动 | 实现最简 | 设置多了翻找累；滚动条自绘成本不低 |
| C. 每模组独立主栏页签 | 左列每模组一个主页签 | —— | 改原版主栏布局（用户已否决过类似思路）；主栏空间/契约受限 |

**采纳 A**，B 作为"仅 1-2 个模组注册"时的自动退化形态（只有一个注册方时
不渲染页签行，直接平铺——现状即此形态，平滑过渡）。

### 页面布局（页局部坐标，对齐原版规范）

```
y≈26    原版子按钮行（载入/保存/选项/控制/记录/模组）——不动
y≈70    模组子页签行（自绘小页签：模组名 ×N；当前项高亮）——仅 ≥2 个注册方时出现
y=100+  当前模组的设置行（行框 550x24、stride 30、规范同 v1.2.11）
右侧    帮助栏（悬停说明 / 模组描述）
```

- 行容量：内容区 100..610 ≈ 17 行；超出 → 该模组的行启用滚轮滚动
  （ MOUSE_WHEEL 已有原版先例），一期先按"单模组 ≤17 行"约定，
  滚动二期再做；
- 模组子页签的观感对齐原版子按钮（深底绿框、当前项高亮），
  复用 drawButtonFace；
- 悬停帮助栏扩展：模组页签悬停显示该模组的描述（注册方提供 `desc`）。

## 5. 数据流与保存时机

- 开关（check）：`set()` 即时调用，注册方自行即时持久化；
- 滑块（slider）：拖动中只调 `set()`（实时生效），宿主在**面板收起**时
  统一调各注册方的 `onPageClose` → 注册方自己 flush（沿用 D-035
  "高频 flush 卡顿"教训）；
- MSW 自己的 12 项也迁移为"自注册"（第一个注册方，吃自己的狗粮），
  MSWConfig 的 save/flush 逻辑不变。

## 6. 控件类型扩展路线

| 类型 | 用途 | 期 |
|---|---|---|
| check / slider | 开关、数值（已实现）；设置项契约含可选 `def`（默认值），页签行尾"恢复默认"一键重置当前模组页（v1.3.4） | 一期 |
| choice | 枚举轮换（如 RV 渲染模式：点击或 ◀▶ 循环） | 二期 |
| action | 执行动作的按钮（如"重载配置""立即应用"） | 二期 |
| info | 只读信息行（版本号、状态） | 三期 |

## 7. 治理与协作

- **不越权**：本设计不存在跨模组配置写——各模组数据自治；
  GOVERNANCE 无需修改；
- **登记**：聚合页作为 UI 占用更新
  `shared-knowledge/knowledge-validation/coordination/registry.md`
  （已有行补充"多模组聚合"性质）；注册契约的 `modId` 唯一性在该表登记；
- **契约文档**：本文件 §3 即契约；接入方实现时引用
  `mods/MoreSkills&Weapons/design/mod-settings-hub.md`；
- **接入实施归属**：各模组的接入改动在**各模组自己的仓库**由各自开发会话
  完成（并行协作；MSW 侧只维护宿主 API）；
- **回归**：MSWAutoTest 扩展"注册 mock 模组（appid≠pfe 时）"验证分页渲染，
  防止宿主迭代破坏契约。

## 8. 分期路线图

| 期 | 内容 | 交付物 |
|---|---|---|
| 一期 ✅（2026-08-29，v1.3.4-hub；通道定稿 modAPI 载体后 **Sandevistan 已实测自动接入**，pages=3；"恢复默认"已加） | 宿主 API（registerPage/契约类）+ MSW 12 项自注册迁移 + 模组子页签行（≥2 方时出现）+ onPageClose 保存时机。自动驱动验证：双页注册（MSW+mock）→ 子页签行渲染 → 自动切页 → 截图人审通过；rowOf=true、无 lastErr | 已交付 |
| 二期 | Sandevistan 接入（其仓库侧实现注册；设置项最多、收益最大）；choice 控件 | 聚合页双模组 |
| 三期 | RealisticVision（渲染模式 choice）/ TDFC / RandomRooms / RConnect 按需接入；action/info 控件；超 17 行滚轮滚动 | 全模组聚合 |
| 末段 | 各期验收后重打 dist 分发包 | —— |

## 9. 风险与对策

| 风险 | 对策 |
|---|---|
| 注册方设置项变化（版本迭代） | 回调式 get/set 天然跟随，宿主无快照 |
| 注册方崩溃拖累面板 | 宿主对 get/set 全部 try/catch，单项失败不影响其他项；诊断落 SOL |
| 未装 MSW 的分发环境 | 注册静默跳过，各模组原 UI 保留 |
| modId 冲突 | registry 登记唯一性 |
| 面板行数超容量 | 一期约定单模组 ≤17 行；二期滚轮滚动 |
