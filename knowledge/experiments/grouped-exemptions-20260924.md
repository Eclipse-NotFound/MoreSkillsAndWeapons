---
domain: ui-systems
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确生产SWF：分组真实控件、旧宿主兼容、跨重启记忆、31类豁免/在途弹320项、多锁52项、激光存读档/真实开火；正式安装后65项。"
date-updated: 2026-09-24
---

# 锁定豁免分组接入与安装

2026-09-24用户确认Q1–Q6均A及整体实现、验证、安装。基于fa8c1ee（已安装v1.13.0激光笔）合入分组，保留其完整源代码，仅改MSWSettingsHub、MSWSmartExclusions和主入口版本标记三个生产文件。

## 行为

Pip「模组→MSW→锁定豁免」按原5类逐行显示，标题批量全选/清空该类原有键；部分选中时点击补全，显示未/部分/全部豁免及数量。右侧展开按钮只改变显示状态，子项可单独调整。一次展开一类或全部收起，首次全收起；位置由ModLoader保存到原菜单存储，跨功能/关闭/重启保留。

原5组31项范围、默认值与玩法过滤不变；恢复默认清全部31项，包括收起项。每次批量操作只cfg.save一次。F6仍用带类别名称的31项平面列表，五功能页及激光笔入口保留。MSWSettingsHub仅在宿主groupVersion>=1时传navigation.groups，旧宿主仍显示平面项，无新增配置键/总开关。

## 构建与验证

正式v1.13.1-settings-groups，54503字节，SHA256 `E1EA2AC2ACAA1F9F7D91DC9EFE72F07E782609EB1C8B4E5ED42072FB1C53FE28`。候选build/out/groups/MoreSkillsWeaponsMod.swf，40生产定义，无宿主原类或测试探针。冻结源在../ModLoader/work/groups-source/src，编译后已逐文件核对当前src一致。

| 本项目记录 | 结果 |
|---|---|
| build/out/exclusion-tests/results.txt | 1197项；原精确分类、配置清洗、5组全开/全关、仅本组变更、一次保存、短标签与平面标签并存 |
| build/out/groups-exclusion-verified/results.txt | 准确E1EA生产字节320项；实际Pip五组全部31项/保存/重置、F6五页与31项、原生实体分类、单多锁、在途弹与回放握手 |
| build/out/groups-multi/results.txt | 准确E1EA生产字节52项；多目标发弹/实际伤害、霰弹分配、目标失效和跳弹继承 |
| build/out/groups-laser/results.txt | 准确E1EA生产字节PASS production laser shot；真实comLoad、武器引用、非正面参数、开火与舞台光束（末尾14帧/476像素），约199行输出并非199项断言 |

复现入口：test-exclusion-unit.ps1；test-exclusion-production.ps1 -ProductionSwf <候选> -SettingsSwf <宿主候选> -Nodebug；test-multi-lock-production.ps1、test-laser-reload.ps1均传ProductionSwf与-Nodebug。使用独立AIR ID、自有存储和进程。

ModLoader侧额外通过：三次启动62+6+4项（含明确全收起后的再次重启）；新MSW配旧宿主8项；旧MSW/新MSW组合各50项；最终精确375951宿主中文样式24项、安装前后各65项与frames=600。前几组UI和320项生产豁免使用补绘箭头前的2B6C210D宿主；最终375951重新验证全部分组行为与中文样式。旧宿主验证用安装前C970字节。准确映射与所有输入hash见ModLoader实验grouped-settings-2026-09-24.md及各run.json。

首次生产豁免探针硬编码1.13.0而拒绝本轮版本，行为断言尚未开始；改为1.13.1后320项通过。另两次宿主探针错误为跨SWF默认SharedObject路径假设、旧宿主版本期望，均仅修测试后复验。未修改生产逻辑迎合探针。

未重跑全部激光笔扫眼/计费/时停、炮塔、所有历史跳弹路线；玩法源与fa8c1ee相同，但旧版证据不冒称本轮准确字节全认证。原时停预演+跳弹+智能绕障等既有边界仍保留。

## 安装与回滚

备份../ModLoader/work/backups/before-groups-20260924-075628/，旧MSW54248字节，SHA256 `476430BC9B1A475267D76A4C31FFC0A7A7718582498F149DD51B1C93B4C9BF9F`（包含激光笔）；宿主旧C9701A91…。本轮成对安装两个准确候选，正式字节复验65项通过，部署回执../ModLoader/build/out/groups-installation/deployment.json为installed-and-verified。三份游戏文件、名单、其他模组和文本配置指纹未变，真实配置/存档未操作。

回滚时先退出游戏，从上述目录把两个旧SWF分别恢复到本模组与ModLoader正式release路径并重启。保留配置和当前清单；旧宿主忽略新增展开记忆，不丢失豁免值。不要拿更旧B8EB/C233覆盖激光笔。现有release/MoreSkillsWeaponsMod.before-v1.13.0-laser-pointer-20260924.swf是历史回到v1.12的备份，不是本轮回滚点。

Git定向提交本轮文件，已有journal历史重排、他人新建的LaserSatsSelectSmoke.as与test-laser-sats-select.ps1留在工作树，未混入提交。
