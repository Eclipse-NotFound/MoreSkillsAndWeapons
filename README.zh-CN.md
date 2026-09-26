# MoreSkillsAndWeapons

《Fallout Equestria: REMAINS》的更多技能与武器模组——本模组合集的战斗扩展模组。

[English](README.md) · 简体中文

## 功能（v1.14.x）

- **跳弹**：子弹第一次撞墙按镜面反射反弹（设置中可关）。
- **可编程榴弹炮（mswglau）**：进游戏自动获得；可调下坠速率、爆炸前撞墙次数、炮口初速度与反弹力度——SATS 弹道实时反映上述设置。
- **激光技能系列**：激光眼与激光笔，可配置穿透箱柜/玻璃，激光笔带箱柜阻挡开关；自适应半径与近距响应调校。
- **手雷击落**：可用子弹打落空中的手雷、导弹与榴弹（自本合集迁移）。
- **疾跑切枪**：按住 Shift 用数字键 1–0 切换第一组快捷槽。
- **蹲姿/梯子举枪**：按住 Shift+W 在蹲姿或爬梯时抬起枪口，可越障射击。
- **魔法冲刺保持姿态**：蹲下/趴着施放魔法冲刺，冲刺全程与结束后保持姿态。
- **散布恒定**：模组榴弹炮的散布不随武器磨损增大。
- 对原版 SATS 选敌与瞄准行为的系列修复。

## 前置

- Fallout Equestria: REMAINS（推荐 1.02）。
- 一次性 **ModLoader** 游戏补丁——见
  [ModLoader Releases](https://github.com/Eclipse-NotFound/ModLoader/releases) → `Remains-GamePatch`。

## 安装

1. 从 [Releases](../../releases) 下载 `MoreSkillsAndWeapons_v1.14.3.zip`。
2. 把压缩包里的 `mods` 文件夹整个复制进游戏根目录（与 `pfe.swf` 同级）。
3. 重启游戏。

## 使用

游戏内按 **F6**（或哔哔小马设置页）打开设置：上述每项功能都有开关或参数，设置跨重启保存。

## 禁用 / 卸载

在 `mods/loader-manifest.txt` 把本模组的启用位改成 `0`，或删除 `mods/MoreSkills&Weapons`。目录名里的 `&` 是有意保留的，请勿改名。

## 从源码构建

AS3 源码在 `src/`；构建脚本与说明在 `build/`（开发记录为中文）。发布产物为 `release/MoreSkillsWeaponsMod.swf`（入口类 `MoreSkillsWeaponsMod`，静态 `init(main)`）。

## 相关模组

[ModLoader](https://github.com/Eclipse-NotFound/ModLoader) ·
[Sandevistan](https://github.com/Eclipse-NotFound/Sandevistan) ·
[TDFC](https://github.com/Eclipse-NotFound/TDFC) ·
[RealisticVision](https://github.com/Eclipse-NotFound/RealisticVision) ·
[RandomRooms](https://github.com/Eclipse-NotFound/RandomRooms) ·
[RConnect](https://github.com/Eclipse-NotFound/RConnect)

> 粉丝模组项目，与游戏原作者无关。
