---
domain: entities
type: discoveries
game-version: ["1.02"]
confidence: high
verified: true
discovered-by: MoreSkills&Weapons
evidence:
  - kind: decompiled-game-code
    symbol: "fe.AllData.d.unit/obj; fe.unit.Unit.create; fe.inter.PipPageInfo"
  - kind: static-comparison
    summary: "从当前pfe.swf重新导出AllData、fe.unit包及PipPageInfo，148个unit节点与1.02参考逐节点一致；中文名来自现用text_zh.xml。未进行新实机锁定测试。"
date-updated: 2026-09-23
---

# 锁定豁免所需的敌人分类调查

用户希望在设置中选择不锁定的敌人类别，本轮先调查、列出类别，尚未实现豁免。下文32组是为本模组设置整理的候选，不是用户已拍板的规则，也不是引擎内置的32种常量。

## 来源与核验范围

- 实际入口 `application.xml` 指向根 `pfe.swf`，现用1.02；重新只读导出64个脚本到 `build/out/enemy-catalog-20260923/current-game/scripts`。
- 当前SWF SHA256：`B78244657ED407D03808C90E97325509DB35F802122835F58933FFF8003305AC`；中文文件 `text_zh.xml` SHA256：`66DA212793683B19E65E3973B726A94A2885D5032395AF8A2E5A0FD20A17F895`。
- 当前 `AllData.d.unit` 有148个节点，与 `game-reference/decompiled/1.02/src102/scripts/fe/AllData.as` 逐节点比较无差异。节点包含模板、NPC、宠物、机关等，不能称为148种敌人。
- 图鉴按数据顺序及cat值分为3大类、14分组、104个具体条目；具体条目仍含凤凰/月刃/猫头鹰三个伙伴，不等于104种敌人。`PipPageInfo` 以最近的cat=2记录作为具体条目的分组，不是简单地读取parent属性。
- 本次为静态调查及当前文件交叉核验，未启动新游戏、未实测每一种单位的锁定；未覆盖DLC1.03/1.04或所有剧情运行时阵营改写。

## 原生图鉴14分组

| 大类 | 分组 |
|---|---|
| 小马—斑马—狮鹫 | 掠夺者、奴隶贩子、斑马军团、雇佣兵、铁骑卫、天马英克雷 |
| 怪物 | 天角兽、地狱犬、尸鬼、肉食灵、其他种类 |
| 机械类 | 大型机械类、小型机械类、炮塔 |

直接照搬会把老鼠、蟑螂、鱼、蚂蚁等都塞进“其他种类”，不方便单独豁免。建议按下表细分物种/型号，另处理首领和机关。

## 供设置选择的32组候选

名称沿用现用简体中文文本。ID表示实体运行时的 `u.id`，不是房间生成指令；短横范围是本文缩写，不是可直接执行的表达式。

| 序号 | 建议类别 | 游戏中的细分名称 | 对应ID |
|---|---|---|---|
| 1 | 掠夺者 | 虐待狂、流氓、铁盔、堕落、叛徒、刽子手、大师、纵火狂、炸弹狂掠夺者 | raider1–9 |
| 2 | 奴隶贩子 | 运输者、猎捕者、看守者、守卫、精英守卫、头领 | slaver1–6 |
| 3 | 斑马军团 | 斑马间谍、破坏者、刺客、战士、军团长官 | zebra1–5 |
| 4 | 雇佣兵 | 狮鹫侦察兵、突击兵、炮手、狙击手、鹰爪精英 | merc1–5 |
| 5 | 铁骑卫 | 骑士、十字军、圣骑士 | ranger1–3 |
| 6 | 天马英克雷 | 英克雷军官、侦察兵、突击兵、精英突击兵 | encl1–4 |
| 7 | 天角兽 | 蓝色、紫色、绿色天角兽 | alicorn1–3 |
| 8 | 地狱犬 | 图鉴类别“地狱犬”，实际条目“英克雷军犬” | hellhound1（hellhound为参数模板） |
| 9 | 尸鬼 | 狂尸鬼、迅捷、饥饿、狂暴、发光、士兵、凶残、中心城、肿胀狂尸鬼；中心城巫师 | zombie0–9 |
| 10 | 肉食灵 | 幼体、酸性、毒性、巨型、迅捷、粉色、梦魇肉食灵；肉食灵王（首领范围需另定） | bloat0–10 |
| 11 | 血翼 | 血翼、中心城血翼 | bloodwing、bloodwing2 |
| 12 | 鱼类 | 食马鱼、狼鱼、僵尸鱼 | fish1–3 |
| 13 | 辐射蟑螂 | 辐射蟑螂 | tarakan |
| 14 | 老鼠 | 老鼠 | rat |
| 15 | 鼹鼠 | 鼹鼠 | molerat |
| 16 | 辐射蝎 | 辐射蝎、嗜血辐射蝎、恐惧毒蝎 | scorp1–3 |
| 17 | 蚂蚁 | 工蚁、兵蚁、火蚁 | ant1–3 |
| 18 | 史莱姆 | 酸性、寒冰、粉色史莱姆 | slime、cryoslime、pinkslime |
| 19 | 死灵云团 | 死灵云团 | necros |
| 20 | 肉食灵巢穴 | 肉食灵巢穴 | ebloat |
| 21 | 蚁穴 | 蚁穴 | eant |
| 22 | 生化脑机器马 | 生化脑机器马 | robobrain |
| 23 | 机械护卫 | 机械护卫、AJ-17 | protect、protect1 |
| 24 | 狂风先生系列 | 狂风先生、飓风先生 | gutsy、gutsy1 |
| 25 | 机器小马 | 机器小马 | eqd |
| 26 | 铁卫马 | 铁卫马 | sentinel |
| 27 | 机械精灵 | 机械精灵 | spritebot |
| 28 | 旋翼机 | 旋翼机 | vortex |
| 29 | 电击球 | 电击球、英克雷电击球 | roller、roller2 |
| 30 | 蜘蛛地雷 | 蜘蛛地雷 | msp |
| 31 | 无马机 | 安保、战斗、英克雷无马机 | dron1–3 |
| 32 | 炮塔 | 天花板、陆地、墙壁、装甲、战斗、魔法炮塔 | turret0–5 |

这只是一级多选建议。上述变种有各自ID，日后也可支持只豁免“中心城狂尸鬼”或“粉色史莱姆”，但本轮没有把这项复杂度当作用户要求。

## 另列的首领与特殊目标

| 名称/类别 | ID及注意点 |
|---|---|
| 掠夺者首领 | bossraider，独立UnitBossRaider |
| 亡灵巫师 | bossnecr，独立UnitBossNecr；不要与尸鬼中的“中心城巫师”或“死灵云团”混为一类 |
| 血月 | bossalicorn，独立UnitBossAlicorn |
| 超级铁卫马 | bossultra，独立UnitBossUltra |
| 炸弹杀手 | bossdron，独立UnitBossDron |
| 毁灭之翼 | bossencl，独立UnitBossEncl；该类没有直接设置boss=true，不能只靠boss字段搜集首领 |
| 肉食灵王 | UnitBloat的bloat7–10均改名为肉食灵王，7–9没有单独图鉴条目；没有独立首领类，也不能仅看boss字段 |
| 雷霆之首及战斗部件 | thunderhead主体、ttur舰炮、dront特殊无马机、destr1反应堆。属于特殊战斗对象；默认阵营/无敌阶段/部件位置各异，应单独设计，不能承诺全部都会成为现有锁定候选 |

陷阱/装置也属于Unit：瓶罐警铃(trigcans)、绊线(trigridge)、压力板(trigplate)、激光传感器(triglaser)、陷阱枪(damshot)、蹄雷串(damgren)、部署好的炸药(damexpl1)、发报机(transmitter)、训练假马(training)。其默认阵营分别落在1/2/4中，现有 `MSWSmartWeapons.targetAllowed` 没有按类排除它们，所以在运行状态/可见性等条件满足时可能被锁定；建议另设“陷阱与装置”和“训练假马”，不要混入生物种类。

普通地雷Mine也继承Unit，数据来自weapon而非unit节点：土制地雷(hmine)、破片地雷(mine)、等离子地雷(plamine)、脉冲地雷(impmine)、斑马破片地雷(zebmine)、野火地雷(balemine)。构造默认设阵营2，某些房间改为4，玩家布置的则另行设置阵营；敌方地雷也可能成为现有锁定候选。建议另设“普通地雷”，与会主动移动的“蜘蛛地雷”分别处理；只列AllData.unit会漏掉这六种。

死亡幻影(spectre)、魔法墙(mwall)、鬼刃(scythe)及反应堆(destr1)的默认数据阵营为0，现有过滤不接纳；剧情/召唤可改阵营，本轮不把静态默认值当作所有运行状态证明。

## 现有过滤与实现时必须注意的事实

- 当前MSW只接受同房、存活、有效、非NPC、非noAgro、阵营1–4且不同于玩家的单位，再做可见性和锁定计时。增加豁免应在此基础上收窄，不应扩大到友方或中立。
- 玩家伙伴凤凰/月刃/机械猫头鹰由UnitPet构造后强制设为玩家阵营100，虽然原始数据的fraction写1，仍被现有过滤排除。NPC、商马、俘虏也已经排除；不能只扫描XML的fraction列生成敌人名单。
- UnitMonstrik共用蟑螂、老鼠、鼹鼠和三种蝎子；UnitBloatEmitter共用肉食灵巢穴和蚁穴。需要按id细分，单按类名会误排除其他物种。
- Unit的fraction是当前阵营，不能当物种：旋翼机是机械单位却为2，地狱犬是生物却为4。首领召唤也可能重设被召唤者阵营。
- 地图生成ID与实体ID不同，例如robot→robobrain、ultra→bossultra、megadron→bossdron、fish→fish1–3、各炮塔生成别名→turret0–5。锁定豁免应检查实际实体身份。
- 建议默认不豁免任何类别，保持旧体验；单/多锁共用排除表、改变设置时已锁目标及在途弹如何处理、首领与所属种族是否独立，均是后续设计项，尚未获得用户选择。本轮不写配置、不改源码或release。

## 主要源码定位

相对参考根 `game-reference/decompiled/1.02/src102/scripts/`：

- `fe/AllData.as`：全部unit/obj定义；`fe/inter/PipPageInfo.as:245`：图鉴分组遍历。
- `fe/unit/Unit.as:678`：工厂生成与cid；`:454` 默认阵营0；`:1001` 数据阵营应用。
- `fe/unit/UnitMonstrik.as:22`、`UnitBloatEmitter.as:12`：共用类的id分流。
- `fe/unit/UnitBloat.as:32`及`:62`：bloat0–10与7以上统一显示王；`UnitPet.as:52`：伙伴强制玩家阵营。
- `fe/unit/UnitBossEncl.as:39`、`UnitThunderHead.as:110`、`UnitDestr.as:13`：特殊战斗类；`Mine.as:7`及`:108`、`:180`与`UnitMsp.as`：普通地雷/蜘蛛地雷及weapon数据来源。
- 本模组 `src/MSWSmartWeapons.as:36`：当前锁定资格。名称以根目录text_zh.xml的unit/n为准；雷霆之首名称同时由map/thunder与剧情文本核对。
