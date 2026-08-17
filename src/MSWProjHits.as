package
{
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;

   /**
    * 手雷击落（投掷物可被击落）：2026-08-17 自 Sandevistan 迁移。
    *
    * 源实现：`mods/Sandevistan/src/SandevistanMod.as` 的 `stepProjHits()`
    * （v1.83 引入，v1.92 相对速度扫掠、v1.114 按武器覆盖）。
    * 迁移范围 = 常规游戏核心逻辑（碰撞扫掠 + 血量/护甲 + 引爆）。
    * Sandevistan 的"时停/回放"分支（projBoom 重演、origDam 恢复、seenAtk
    * 追踪器）依赖斯安维斯坦的时停回放系统，本模组无此系统，不迁移。
    *
    * 行为：手雷（PhisBullet）/导弹（SmartBullet）/榴弹（Bullet，带爆炸半径）
    * 受击至血量归零直接爆炸；普通子弹（含天角兽闪电，explRadius=0）不参与。
    * 护甲 = 伤害先减护甲。
    *
    * 斯安维斯坦共存（2026-08-17 D-033 调整）：
    * - 时停期（onPause=true 且 godMode=false）：**照常判定**——斯安维斯坦
    *   时停中把玩家攻击体 damage/damageExpl 清零（origDam 机制），本组件
    *   用自维护的 origDam 缓存恢复原始伤害；引爆走**视觉爆炸**（伤害/破坏
    *   清零再恢复，与 Sandevistan isSandy 分支一致）。真实伤害不结算：
    *   斯安维斯坦的回放重演（projBoom）是私有系统，不重演本组件的引爆。
    * - 回放期（onPause=true 且 godMode=true）：由 MSWU.inGameplay 屏蔽——
    *   回放期爆炸由斯安维斯坦重演，介入会造成双重结算。
    */
   public class MSWProjHits
   {
      private var mod:*;
      /** 投掷物 → 当前剩余血量 */
      private var projHp:Dictionary = new Dictionary(true);
      /** 攻击体 → 原始伤害（清零前捕获；斯安维斯坦时停期 damage 被清零时恢复） */
      private var origDam:Dictionary = new Dictionary(true);
      /** 近战攻击体（vel=0 静止在手上）不参与击落判定（v1.90） */
      private static const MELEE_VEL:Number = 1;

      public function MSWProjHits(m:*)
      {
         mod = m;
      }

      /** 每帧调用（游戏 step 之后）。 */
      public function process(w:*):void
      {
         try
         {
            if(w == null) return;
            if(!mod.cfg.projHits) return;
            if(!MSWU.inGameplay(w)) return;
            var loc:* = w["loc"];
            if(loc == null || !loc["active"]) return;

            // ---- 1. 收集投掷物（projs）与攻击体（objs）----
            // 源实现优先用 seenAtk（斯安维斯坦攻击体追踪器）；本模组无此
            // 系统，直接用 loc.firstObj 链扫描（源实现的兜底路径）。
            var projs:Array = new Array();
            var objs:Array = new Array();
            var o:* = loc["firstObj"];
            var g:int = 0;
            while(o != null)
            {
               var nx:* = o["nobj"];
               try
               {
                  var qn:String = getQualifiedClassName(o);
                  if(qn == "fe.weapon::PhisBullet" || qn == "fe.weapon::SmartBullet" || qn == "fe.weapon::Bullet")
                  {
                     // 可击落 = 带爆炸半径且未引爆（explRadius>0 && !isExpl）；
                     // 普通枪弹/闪电（explRadius=0）照常入 objs
                     if(isShootableProjectile(o))
                     {
                        if(projs.indexOf(o) < 0) projs.push(o);
                     }
                     else
                     {
                        // 近战攻击体不参与击落判定（v1.90：否则手雷飞过近战
                        // 范围会被"拳击"引爆并把攻击体 remObj 出链，破坏近战）
                        if(MSWU.num(o, "vel") < MELEE_VEL) { o = nx; if(++g > 20000) break; continue; }
                        objs.push(o);
                     }
                  }
                  else if(qn.indexOf("fe.weapon::") == 0)
                  {
                     if(MSWU.num(o, "vel") < MELEE_VEL) { o = nx; if(++g > 20000) break; continue; }
                     objs.push(o);
                  }
               }
               catch(e:*)
               {
               }
               o = nx;
               if(++g > 20000) break;
            }
            // ---- 2. 清理已消失投掷物的血量记录 + 攻击体原始伤害缓存 ----
            var keySnap:Array = new Array();
            for(var kH:Object in projHp)
            {
               keySnap.push(kH);
            }
            for each(var kD:Object in keySnap)
            {
               if(projs.indexOf(kD) < 0) delete projHp[kD];
            }
            var keySnap2:Array = new Array();
            for(var kO:Object in origDam)
            {
               keySnap2.push(kO);
            }
            for each(var kO2:Object in keySnap2)
            {
               if(objs.indexOf(kO2) < 0) delete origDam[kO2];
            }
            // 捕获攻击体原始伤害（清零前记录；斯安维斯坦时停期玩家攻击体
            // damage 被置 0，判定时用此缓存恢复，对齐 Sandevistan origDam）
            for each(var bCap:Object in objs)
            {
               try
               {
                  if(origDam[bCap] == null && MSWU.num(bCap, "damage") > 0)
                  {
                     origDam[bCap] = MSWU.num(bCap, "damage");
                  }
               }
               catch(e:*)
               {
               }
            }
            if(projs.length == 0 || objs.length == 0) return;

            // ---- 3. 双重判定：p(投掷物) × b(攻击体) ----
            for each(var p:Object in projs)
            {
               for each(var b:Object in objs)
               {
                  try
                  {
                     if(b == p) continue;   // v1.92 自测防护：爆炸弹同时进两表
                     // v1.91 出生护手：同源且投掷物距其 owner<200px（刚出手/
                     // 枪口附近）不判定，防投掷+连射在自己面前引爆；飞出后可
                     // 射击自己的手雷/导弹
                     if(b["owner"] == p["owner"])
                     {
                        try
                        {
                           var pown:* = p["owner"];
                           if(pown != null)
                           {
                              var odx:Number = MSWU.num(p, "X") - MSWU.num(pown, "X");
                              var ody:Number = MSWU.num(p, "Y") - MSWU.num(pown, "Y");
                              if(odx * odx + ody * ody < 200 * 200) continue;
                           }
                        }
                        catch(e:*)
                        {
                        }
                     }
                     // v1.92 相对速度扫掠碰撞：R(t)=O+t·RV, t∈[0,1] 钳制,
                     // |R(t*)|≤28 即命中（端点自然覆盖）
                     var sx:Number = MSWU.num(b, "X") - MSWU.num(b, "dx");
                     var sy:Number = MSWU.num(b, "Y") - MSWU.num(b, "dy");
                     var pdx:Number = MSWU.num(p, "dx");
                     var pdy:Number = MSWU.num(p, "dy");
                     var hitOK:Boolean = false;
                     var ddx0:Number = sx - (MSWU.num(p, "X") - pdx);
                     var ddy0:Number = sy - (MSWU.num(p, "Y") - pdy);
                     if(ddx0 * ddx0 + ddy0 * ddy0 <= 28 * 28) hitOK = true;
                     if(!hitOK)
                     {
                        var rvx:Number = MSWU.num(b, "dx") - pdx;
                        var rvy:Number = MSWU.num(b, "dy") - pdy;
                        var rv2:Number = rvx * rvx + rvy * rvy;
                        if(rv2 > 0.0001)
                        {
                           var tS:Number = -(ddx0 * rvx + ddy0 * rvy) / rv2;
                           if(tS < 0) tS = 0;
                           if(tS > 1) tS = 1;
                           var cxR:Number = ddx0 + rvx * tS;
                           var cyR:Number = ddy0 + rvy * tS;
                           if(cxR * cxR + cyR * cyR <= 28 * 28) hitOK = true;
                        }
                     }
                     if(!hitOK) continue;
                     mod.cfg.diagAdd("projHit");
                     var dmg:Number = MSWU.num(b, "damage");
                     // 斯安维斯坦时停期玩家攻击体 damage 被清零 → 用捕获的
                     // 原始伤害恢复（对齐 Sandevistan origDam）
                     if(dmg <= 0 && origDam[b] != null) dmg = Number(origDam[b]);
                     if(dmg <= 0) continue;
                     // v1.114 按发射武器 id 的护甲/血量覆盖（projarmor_<id>/
                     // projhp_<id>；无覆盖项用全局 projarmor/projhp）
                     var wIdP:String = "";
                     var weapP:* = p["weap"];
                     if(weapP != null && MSWU.has(weapP, "id")) wIdP = String(weapP["id"]);
                     var armP:Number = mod.cfg.projArmor;
                     if(wIdP != "" && mod.cfg.projArmorOver != null && mod.cfg.projArmorOver[wIdP] != null)
                     {
                        armP = Number(mod.cfg.projArmorOver[wIdP]);
                     }
                     dmg -= armP;   // 护甲（伤害先减护甲）
                     if(dmg <= 0) continue;
                     try { loc["remObj"](b); } catch(e:*) { }   // 命中子弹弹出
                     var baseHpP:Number = mod.cfg.projHp;
                     if(wIdP != "" && mod.cfg.projHpOver != null && mod.cfg.projHpOver[wIdP] != null)
                     {
                        baseHpP = Number(mod.cfg.projHpOver[wIdP]);
                     }
                     var hpP:Number = projHp[p] != null ? Number(projHp[p]) : baseHpP;
                     hpP -= dmg;
                     if(hpP <= 0)
                     {
                        delete projHp[p];
                        mod.cfg.diagAdd("projBoom");
                        // 斯安维斯坦时停期（onPause=true 且非回放）：引爆走
                        // 视觉爆炸（伤害/破坏清零再恢复——真实结算由斯安维
                        // 斯坦回放重演，但本组件的引爆不在其私有 projBoom
                        // 记录内，真实伤害不结算，固有限制）；常规期真实爆炸。
                        // 均引爆即杀（liv=0 → 下一世界步 vse→remObj），防
                        // 爆炸后鬼影继续沿轨迹飞行（v1.92）。
                        var frozenP:Boolean = w["onPause"] == true && w["godMode"] != true;
                        if(frozenP)
                        {
                           var svExpl:Number = MSWU.num(p, "damageExpl");
                           var svDest:Number = MSWU.num(p, "destroy");
                           try { p["damageExpl"] = 0; } catch(e:*) { }
                           try { p["destroy"] = 0; } catch(e:*) { }
                           try { p["explosion"](); } catch(e:*) { }
                           try { p["damageExpl"] = svExpl; } catch(e:*) { }
                           try { p["destroy"] = svDest; } catch(e:*) { }
                        }
                        else
                        {
                           try { p["explosion"](); } catch(e:*) { }
                        }
                        try { p["liv"] = 0; } catch(e:*) { }
                     }
                     else
                     {
                        projHp[p] = hpP;
                     }
                     break;   // 一颗子弹只判一个投掷物
                  }
                  catch(e:*)
                  {
                  }
               }
            }
         }
         catch(e:*)
         {
         }
      }

      /** 是否为可击落投掷物：PhisBullet/SmartBullet/Bullet 且 explRadius>0 且 !isExpl。 */
      private function isShootableProjectile(o:*):Boolean
      {
         if(MSWU.num(o, "explRadius") <= 0) return false;
         if(MSWU.has(o, "isExpl") && o["isExpl"] == true) return false;
         return true;
      }
   }
}