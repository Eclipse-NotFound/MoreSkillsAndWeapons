# MoreSkillsAndWeapons — 更多技能与武器

[English](README.md) · **简体中文**

给战斗增加智能追踪子弹、跳弹、非致命激光枪和可调榴弹炮，还能在疾跑时切枪。适合想尝试更多武器玩法的玩家。

**[下载 v1.15.3 — MoreSkillsAndWeapons_v1.15.3.zip](https://github.com/Eclipse-NotFound/MoreSkillsAndWeapons/releases/download/v1.15.3/MoreSkillsAndWeapons_v1.15.3.zip)** · [发布说明 / 其他版本](https://github.com/Eclipse-NotFound/MoreSkillsAndWeapons/releases)

点击上方链接下载成品。也可以打开发布页，展开 **Assets（下载文件）**，选择同名文件；**Source code** 和绿色 **Code → Download ZIP** 是源码，不能直接安装。

## 会带来什么变化

- **智能武器**：锁定可见目标，引导子弹转弯；可选多目标锁定与聚焦集火。智能功能默认关闭，在设置中开启。
- **跳弹与榴弹炮**：调整反弹和榴弹飞行、引爆方式。
- **非致命激光枪与激光笔**：照射眼睛或传感器使敌人短暂失明；箱柜阻挡等行为可调。
- **动作与防御**：疾跑切枪、蹲姿/梯子举枪、冲刺保持姿态，以及击落手雷、导弹和榴弹。

## 安装

适用于 **Windows / Remains 1.02**。

1. 保存并退出游戏。Steam 库中右键 Remains → **管理 → 浏览本地文件**，打开含 `pfe.swf` 和 `application.xml` 的游戏文件夹。
2. 第一次装本系列模组，先完成 [ModLoader 首次安装](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.zh-CN.md#first-install)；它包含一次性游戏补丁和模组扫描器。已装好的玩家可跳过。
3. 解压下载的 ZIP，把里面的 **`mods` 文件夹合并到游戏文件夹**，不要套成 `mods/mods`。
4. 双击游戏目录下的 **`mods/ModLoader/RemainsModScanner.exe`**，等待完成后关闭提示，再按平常方式启动游戏。

放对后应能找到：`mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf`。游戏内按 F6，应能打开 MSW 设置。保留目录名中的 `&`。

[图示文件结构、更新与恢复方法](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.zh-CN.md)

## 第一次怎么玩

先按 **F6** 打开设置，选择一项想尝试的功能；也可从 **哔哔小马 → 设置 → 模组 → MSW** 进入。设置会保存。

| 操作 | 效果 |
|---|---|
| F6 | 打开/关闭 MSW 设置 |
| 按住 Shift + 数字键 1–0 | 疾跑时切换第一组快捷槽武器 |
| 蹲下或爬梯时按住 Shift + W | 抬高枪口 |

第一次尝试智能子弹，先在“智能武器”中打开总开关，再对可见敌人获取锁定；仅安装模组不会自动打开它。

## 更新、停用与适用范围

更新前保存退出，备份 `mods/MoreSkills&Weapons`，再合并新版文件、运行扫描器并重启；保留自己的配置。临时停用时，可把该模组文件夹移到 `mods` 之外备份，再扫描并重启。

本指引对应 v1.15.3，仅按 Remains 1.02 使用。激光本身不直接扣生命，但失明敌人的攻击仍可能误伤其他角色。新增武器与全部联机组合未全面验证。

## 遇到问题

先检查：文件夹是否放对、是否运行过扫描器、是否完全退出并重启。通用问题见[安装与排错指南](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.zh-CN.md#troubleshooting)。

仍有问题，请到[问题反馈](https://github.com/Eclipse-NotFound/MoreSkillsAndWeapons/issues)说明：游戏版本、本模组版本、其他已装模组、操作步骤、预期结果与实际结果；能附截图或报错原文更好。不要上传个人存档，除非排查时确有需要。

<details>
<summary>开发资料（普通安装无需阅读）</summary>

本页按可下载的发布包编写，仓库源码可能更靠前。实现见 [src](src/)；历史设计、验证和版本记录保留在项目目录中。

</details>

[查看全部模组及玩法介绍](https://github.com/Eclipse-NotFound/ModLoader/blob/master/README.zh-CN.md#choose-mods) · [首次安装指南](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.zh-CN.md)

这是玩家制作的非官方模组项目，需要自行拥有游戏。
