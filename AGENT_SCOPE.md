# MoreSkills&Weapons —— Agent 工作范围

> 完整治理规则见工作区根目录 `GOVERNANCE.md`（权限模型、知识库、参考区、游戏文件修改、外置记忆协议、同步与镜像）。
> 本文件只记录本模组的参数与特例。开始开发：读本文件 → 读 `state\MEMORY.md`（记忆入口）。

## 项目参数

| 项 | 值 |
|---|---|
| project | MoreSkills&Weapons |
| workspace | mods/MoreSkills&Weapons/ |
| repository | 本目录为独立 git 仓库 |
| 运行时入口 | release/MoreSkillsWeaponsMod.swf（入口类 `MoreSkillsWeaponsMod`，`public static init(main)`） |
| 记忆入口 | state/MEMORY.md |

## 本模组特例（相对 GOVERNANCE 的偏离/补充）

- `dist\` 是对外分发包（zip + 分发用说明），与 `release\`（游戏运行时加载点）语义不同，两者并存。
- 构建走 Animate 自带 mxmlc.jar 路线（完全动态访问架构），细节见 `remains-mod-build` 技能。
