---
domain: entities
type: experiments
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: runtime-experiment
    summary: "准确优化生产字节的8种原生炮塔，32次身体辅助射击、8次手动传感器射击、原生场景更新链、恢复和收起边界；189行PASS。"
date-updated: 2026-09-24
---

# 炮塔传感器致盲适配

用户要求加入炮塔失明，沿用既定Q12/Q15和固定设备原地乱转乱攻规则。已安装 **v1.11.1-turret-blind**，激光组件 **6-turret-sensors**；保留v1.11的自适应半径、玻璃路线、多重锁定、身体辅助与菜单接入。同期背向致盲提案未纳入本次安装。

## 根因与实现

- 旧版将所有单位的正面都按 `dx*storona` 判定。炮塔会二维旋转，storona只是缓存；即使从炮口朝向侧命中传感器，仍可能被错误归类为back/body。改用入射方向与炮口方向的点积，保持正面半平面规则。普通角色判定不变。
- `landturret`、`armturret` 虽然fixed=false，却不是步行单位。旧恐慌控制主动添加dx=5，造成横向滑行。新逻辑对全部UnitTurret取消主动走动和底座翻面，仍保留重力、击退与原物理更新。随机炮口角度规范化，按原生机械角度限制开火，之后同步炮口图像。
- 收起的隐藏炮塔仍保留旧light引用；新增可用性检查，仅完全展开、有可见传感器图形时允许命中。收起外壳仍作为普通身体挡光。停机、友方与剧情禁用规则继续沿用。
- 默认6秒，可刷新，跟随实际单位行动时间；暂停/时停停表。失明期间跳过原AI，不读取玩家实时目标；原地间歇乱射，炮塔阵营不变，沿用恐慌攻击友伤处理。结束恢复感知和武器寻敌参数，清旧目标。设置和现有失明/调试标志共用，无新增设置。

## 复现与单变量核对

1. 冻结基线v1.11.0：48980字节，SHA256 `F8DD73DD47E2E14A90097698317884E42EB3A0EBC163B91ADA12B6F8A1700F10`。
2. 外部测试驱动加载准确生产SWF，不链接生产源码。8种炮塔×4炮口方向的原生武器开火，15次错误拒绝；地面与装甲炮塔恐慌首步dx=5。结果 `build/out/laser-turret/baseline-control/results.txt`。
3. 只改二维正面判定：32次辅助射击全部通过，仅两个主动走动断言仍失败。候选SHA `2D018DBA7C8CEEF49E8A015C0CFB7D9C6480069681BEEAF69DB8497D27A4F549`，结果 `front-only-test/results.txt`。
4. 再修正炮塔控制后，各类乱射/恢复通过，仅隐藏炮塔收起判定失败；保存于 `control-check/results-before-exposure-fix.txt`。加入传感器展开检查后通过。

## 最终验证

- 准确候选：**49203字节**，SHA256 `C233D67EA0C5FC74BD0499ADFB1AD1C45823CAEEDA7145806D84BE101ABF0827`，冻结源码 `build/out/laser-turret/release/src`；36生产定义，无宿主原类/测试探针。
- `test-turret-laser.ps1 -Nodebug`：189行PASS、0FAIL，8种炮塔均以真实武器开火扣2电池、零直接伤害并致盲。32次身体辅助与8次手动射击；32次反向射线拒绝、8次护盾拒绝；隐藏2种收起/展开、8种停机保护通过。独立测量的可见传感器中心与解析位置一致，图 `control-check/turret-sensors.png`。
- 首步保留原生fixed状态以验证不增加横移；随后长期控制场景因测试场地无支撑地面，将炮塔固定。首步加29次真实Location.step精确消耗1秒，每步移动玩家且检测无重新锁定，包括absVis首领炮塔。原生恐慌武器发弹、6秒刷新、恢复感知及寻敌参数、底座朝向与炮口显示检查通过。四向矩阵包含直接设置炮口角度的几何测试，不声称各底座都自然允许360°旋转。
- 同候选生产字节：真实comLoad/延迟装备/光束/身体辅助124行PASS；未暂停舞台光束15显示帧、峰值476像素。多重锁定52项通过。副本 `release/reload-results.txt`、`release/multi-results.txt`。
- 同冻结源码另编译的机制驱动251行PASS：36类原生敌人、恐慌同阵营/中立伤害、生命周期、SATS与实际Sandevistan时停/回放。该套件是带驱动的开发字节，不能冒称准确安装SWF；记录 `release/mechanism-results.txt`。
- 所有游戏实例使用唯一AIR ID、隐藏窗口和独立存储。受限启动曾因独立存储写入报3003而超时，按原有隔离方式提权后完成。磁盘不足仅清理本轮重复runtime副本，红绿文本与图保留；真实存档、用户游戏未操作。

## 安装与边界

已核对旧正式文件仍为F8DD…，创建 `release/MoreSkillsWeaponsMod.before-v1.11.1-turret-blind-20260924.swf` 后替换正式文件为C233…。备份哈希与48980字节基线相同。安装前与安装后各900帧通过，ModSettings-connected、tabOn=1，无lastErr/smartError/laserError；证据 `build/out/laser-turret/preinstall/install-smoke.json`、`postinstall/install-smoke.json`。需重启用户游戏生效；回滚将备份复制回正式文件名再重启。

根 `pfe.swf` SHA256仍为 `B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`；未改本体、loader清单、ModSettings或其他模组部署文件。当前模组准确生产候选、冻结源、红绿结果与PNG保留；磁盘不足清理的仅本轮可重建runtime副本。

未覆盖DLC、第三方新炮塔、全部剧情关卡、长期战斗或联机。长期原生场景控制验证使用固定测试支撑；原物理代码保持，不以该测试声称验证全部坠落/击退情况。智能自适应/玻璃逻辑源码未改，本轮不重跑其全部历史路线矩阵。
