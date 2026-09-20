package
{
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;

   /**
    * 子弹跟踪与干预（跳弹 + 可编程榴弹的弹跳/引爆）。
    *
    * 原理（见 design/features.md 与 decisions D-002/D-003）：
    * - 游戏 step 先于模组帧：本类在"帧后窗口"检测子弹死亡并重生/引爆。
    * - 撞墙判定复刻 Bullet.run 的条件：tile.phis==1 且子弹落在
    *   phX1..phX2/phY1..phY2 内。
    * - 墙被本发子弹打破后 tile.phis==0 → 不满足判定 → 不弹跳（用户特殊要求）。
    */
   public class MSWBullets
   {
      private var mod:*;
      private var track:Dictionary = new Dictionary(true);
      private var seen:Dictionary;
      private var lastLoc:* = null;
      private var BulletCls:Class = null;

      public function MSWBullets(m:*)
      {
         mod = m;
      }

      private function bulletClass():Class
      {
         if(BulletCls == null) BulletCls = MSWU.cls("fe.weapon.Bullet");
         return BulletCls;
      }

      /** 每帧调用。 */
      public function process(w:*):void
      {
         try
         {
            if(w == null) return;
            var loc:* = w["loc"];
            if(loc == null || !loc["active"])
            {
               if(loc != lastLoc)
               {
                  track = new Dictionary(true);
                  lastLoc = loc;
               }
               return;
            }
            if(loc != lastLoc)
            {
               track = new Dictionary(true);
               lastLoc = loc;
            }
            var gg:* = w["gg"];
            if(gg == null) return;

            // 1) 扫描对象链：登记新的玩家飞行子弹，更新存活子弹的上一帧位置。
            //    子弹在出生帧内即可完成首次 step 并撞墙死亡（高速弹一步最多
            //    vel 像素），因此"首次见到即已 babah/超时"的子弹也要在这里处理，
            //    否则枪口附近会形成弹跳死角。
            seen = new Dictionary(true);
            var o:* = loc["firstObj"];
            while(o != null)
            {
               if(getQualifiedClassName(o) == "fe.weapon::Bullet")
               {
                  var owner:* = o["owner"];
                  if(owner != null && owner["player"] == true)
                  {
                     seen[o] = true;
                     var info:* = track[o];
                     if(info == null)
                     {
                        var kind:String = classify(w, o);
                        if(o["babah"] == true || MSWU.num(o, "liv") <= 0)
                        {
                           // 首次见到即已死亡（出生帧内撞墙）。用出生点
                           // begx/begy（public，构造时记录）作为重放起点：
                           // 出生帧轨迹 = 出生点→死亡点的一段直线（子步内
                           // 直线），进入面判定完全精确——近距离地面射击
                           // 也能可靠反弹（玩家实测：近地面无法反弹）。
                           var sX:Number = MSWU.num(o, "begx", -1e9);
                           var sY:Number = MSWU.num(o, "begy", -1e9);
                           info = {
                              "kind": kind,
                              "prevX": sX,
                              "prevY": sY,
                              "ric": kind == "ric" ? new MSWRicochet(mod.cfg) : null,
                              "hits": mod.cfg.wallHits,
                              "dead": true
                           };
                           handleDeath(w, loc, o, info);
                           track[o] = info;
                        }
                        else
                        {
                           // 也登记关闭开关时的子弹，避免中途开启跳弹追溯生效。
                           track[o] = {
                              "kind": kind,
                              "prevX": MSWU.num(o, "X"),
                              "prevY": MSWU.num(o, "Y"),
                              "ric": kind == "ric" ? new MSWRicochet(mod.cfg) : null,
                              "hits": mod.cfg.wallHits,
                              "livLeft": MSWU.num(o, "liv"),
                              "grounded": false,
                              "spin": 0,
                              "dead": false
                           };
                        }
                     }
                     else
                     {
                        if(info["dead"] != true && o["babah"] != true)
                        {
                           info["prevX"] = MSWU.num(o, "X");
                           info["prevY"] = MSWU.num(o, "Y");
                           if(info["kind"] == "msw")
                           {
                              // 引信剩余时间（liv 随步递减，重生时延续，见 D-015）
                              info["livLeft"] = MSWU.num(o, "liv");
                              // 翻滚动画（参考 PhisBullet：vis.rotation += dr，dr=dx）
                              var dxc:Number = MSWU.num(o, "dx");
                              var sp:Number = MSWU.num(info, "spin") + dxc;
                              info["spin"] = sp;
                              var vs:* = o["vis"];
                              if(vs != null)
                              {
                                 try
                                 {
                                    vs["rotation"] = sp;
                                 }
                                 catch(e2:*)
                                 {
                                 }
                                 // 视觉防陷地钳制：下降末段/小回弹期间，贴图最低点
                                 // 不越过下方实体矩形的上沿（仅钳 vis.y，逻辑位置
                                 // 与碰撞判定不变——D-024）
                                 var cX:Number = MSWU.num(o, "X");
                                 var cY:Number = MSWU.num(o, "Y");
                                 var bt:* = loc["getAbsTile"](cX, cY + 12);
                                 if(bt != null && MSWU.num(bt, "phis") == 1 &&
                                    cX >= MSWU.num(bt, "phX1") && cX <= MSWU.num(bt, "phX2") &&
                                    cY >= MSWU.num(bt, "phY1") - 16 && cY < MSWU.num(bt, "phY1"))
                                 {
                                    var vw2:Number = MSWU.num(vs, "width");
                                    var vh2:Number = MSWU.num(vs, "height");
                                    if(!(vw2 > 4)) vw2 = 16;
                                    if(!(vh2 > 4)) vh2 = 16;
                                    var hd:Number = Math.sqrt(vw2 * vw2 + vh2 * vh2) / 2;
                                    if(hd < 8) hd = 8;
                                    if(hd > 20) hd = 20;
                                    var maxVisY:Number = MSWU.num(bt, "phY1") - hd;
                                    try
                                    {
                                       if(MSWU.num(vs, "y") > maxVisY) vs["y"] = maxVisY;
                                    }
                                    catch(e3:*)
                                    {
                                    }
                                 }
                              }
                           }
                        }
                     }
                  }
               }
               o = o["nobj"];
            }

            // 2) 处理本帧死亡或离开对象链的已跟踪子弹。
            //    必须先对键做快照再处理：bounce() 会在本轮新建重生弹条目，
            //    若被同一轮 for-in 扫到，它不在 seen（扫描后才创建）里，
            //    会被"已不在链上"分支误删 → 下一帧重新注册 → hits 被重置为
            //    wallHits → 无限小回弹直到引信耗尽（玩家实测 bug）。
            var keySnap:Array = new Array();
            for(var kk:Object in track)
            {
               keySnap.push(kk);
            }
            for each(var k:Object in keySnap)
            {
               var b:Object = k;
               if(b == null)
               {
                  delete track[k];
                  continue;
               }
               var inf:* = track[b];
               if(inf == null) continue;
               if(seen[b] == true)
               {
                  // 仍在链上但本帧撞击/超时（babah 后会在链上停留数帧）
                  if(inf["dead"] != true && (b["babah"] == true || MSWU.num(b, "liv") <= 0))
                  {
                     handleDeath(w, loc, b, inf);
                     inf["dead"] = true;
                  }
                  continue;
               }
               // 已不在链上
               if(inf["dead"] != true && b["babah"] != true && MSWU.num(b, "liv") > 0)
               {
                  // 无撞击且未超时地被移除（换场景/出错等）：不做任何事
                  delete track[b];
                  continue;
               }
               if(inf["dead"] != true)
               {
                  handleDeath(w, loc, b, inf);
               }
               delete track[b];
            }
         }
         catch(e:*)
         {
         }
      }

      /** 决定是否跟踪以及跟踪类型。 */
      private function classify(w:*, b:*):String
      {
         var isBabah:Boolean = b["babah"] == true;
         var bLiv:Number = MSWU.num(b, "liv");
         var weap:* = b["weap"];
         if(weap != null && MSWU.str(weap, "id") == MSWWeapon.WEAPON_ID)
         {
            // 只接管"未爆的榴弹"。必须排除爆炸产生的冲击弹：
            // explBlast→explBullet 生成的冲击弹同样 owner=玩家、weap=本武器、
            // explRadius=0，但字段特征相反：damage=damageExpl(>0)、
            // damageExpl=0、liv=3、precision=0（Bullet.explBullet）。
            // 注意：出生帧内撞墙死亡的榴弹 babah 后 liv 恒为 3（popadalo 置 4、
            // step 再减 1）——babah 状态必须豁免 liv>3 守卫，否则近距离地面
            // 射击"无法反弹"（玩家实测）；冲击弹仍被 damage>0&&damageExpl==0
            // 排除，豁免安全。
            if(MSWU.num(b, "explRadius") == 0 &&
               MSWU.num(b, "damageExpl") > 0 &&
               MSWU.num(b, "damage") <= 0 &&
               (isBabah || bLiv > 3))
            {
               return "msw";
            }
            return "none";
         }
         if(mod.cfg.ricochet)
         {
            // 跳弹：仅普通枪弹（非爆炸、非火焰减速弹）。
            // liv>3 排除爆炸冲击弹（liv=3 出生）；babah 豁免（同上）。
            if(MSWU.num(b, "explRadius") == 0 && MSWU.num(b, "brakeR") == 0 &&
               MSWU.num(b, "tipDamage") == 0 && MSWU.num(b, "vel") >= 1 &&
               (isBabah || bLiv > 3))
            {
               return "ric";
            }
         }
         return "none";
      }

      private function handleDeath(w:*, loc:*, b:*, inf:*):void
      {
         var X:Number = MSWU.num(b, "X");
         var Y:Number = MSWU.num(b, "Y");
         var wallIntact:Boolean = false;
         var tile:* = loc["getAbsTile"](X, Y);
         if(tile != null && MSWU.num(tile, "phis") == 1)
         {
            if(X >= MSWU.num(tile, "phX1") && X <= MSWU.num(tile, "phX2") &&
               Y >= MSWU.num(tile, "phY1") && Y <= MSWU.num(tile, "phY2"))
            {
               wallIntact = true;
            }
         }
         if(inf["kind"] == "msw")
         {
            // 无历史位置（出生帧内撞墙，枪口贴墙）：无法可靠判定进入面，
            // 不再猜测反弹——直接引爆（与"偶发原路回弹/消失"问题对应的修正）。
            if(wallIntact && MSWU.num(inf, "hits") > 0 && MSWU.num(inf, "prevX", -1e9) > -1e8)
            {
               bounce(loc, b, inf);
            }
            else
            {
               explode(b, X, Y);
            }
         }
         else if(inf["kind"] == "ric")
         {
            // 同上：无历史位置的墙撞按原版消亡，不做不可靠的反弹
            if(wallIntact && MSWU.num(inf, "prevX", -1e9) > -1e8)
            {
               var chain:MSWRicochet = inf["ric"] as MSWRicochet;
               var dx:Number = MSWU.num(b, "dx");
               var dy:Number = MSWU.num(b, "dy");
               var plan:Object = chain == null ? null : chain.plan(MSWU.num(b, "damage"), Math.sqrt(dx * dx + dy * dy));
               if(plan != null) bounce(loc, b, inf, plan);
               else mod.cfg.diagAdd("ricStop");
            }
         }
      }

      /**
       * 立即摘除死亡子弹的贴图。游戏在 babah 剩余 4 帧里每步都会
       * vis.visible=true 并同步位置——死亡点在地板/墙矩形内时整颗榴弹
       * 会"穿模"显示在碰撞体里（玩家实测：站在地上朝正下方发射最明显）。
       * 反弹/引爆时旧弹已被取代，贴图直接摘除。
       */
      private function killVis(b:*):void
      {
         try
         {
            var dv:* = b["vis"];
            if(dv != null && dv["parent"] != null)
            {
               dv["parent"].removeChild(dv);
            }
         }
         catch(e5:*)
         {
         }
      }

      /**
       * 反弹：先按子步重放判定进入面，再按弹种应用物理。
       * - ric（跳弹技能）：镜面反射，弹性 1.0（光线反射定律）。
       * - msw（可编程榴弹）：参考 PhisBullet 手雷——弹性 0.4、地面摩擦 0.7、
       *   落地静止、引信（liv）延续、翻滚动画、反弹音效。
       */
      private function bounce(loc:*, b:*, inf:*, ricPlan:Object = null):void
      {
         mod.cfg.diagAdd("bounce");
         killVis(b);
         var cls:Class = bulletClass();
         if(cls == null) return;
         var owner:* = b["owner"];
         if(owner == null) return;
         var X:Number = MSWU.num(b, "X");
         var Y:Number = MSWU.num(b, "Y");
         var dx:Number = MSWU.num(b, "dx");
         var dy:Number = MSWU.num(b, "dy");
         var tile:* = loc["getAbsTile"](X, Y);
         if(tile == null) return;
         var px1:Number = MSWU.num(tile, "phX1");
         var px2:Number = MSWU.num(tile, "phX2");
         var py1:Number = MSWU.num(tile, "phY1");
         var py2:Number = MSWU.num(tile, "phY2");
         var prevX:Number = MSWU.num(inf, "prevX", -1e9);
         var prevY:Number = MSWU.num(inf, "prevY", -1e9);

         var newX:Number = X;
         var newY:Number = Y;
         var ndx:Number = dx;
         var ndy:Number = dy;
         var crossX:Boolean = false;
         var crossY:Boolean = false;
         if(prevX > -1e8)
         {
            // 按游戏自己的子步粒度（World.maxdelta=9）重放本步轨迹，确定真实进入面。
            // 不能用"上一帧位置"直接对比矩形：高速弹一步可移动 vel 像素（远超
            // 40px 瓦片），斜向入射时上一帧位置常落在矩形上/下方，会误判为
            // 同时穿过两面 → 双轴反转 → 原路回弹（玩家实测 bug）。
            // 游戏 step() 内 dy+=ddy 每步只执行一次，子步间轨迹为直线，
            // 因此重放与真实路径完全一致。
            var stepN:int = 1;
            var maxD:Number = Math.abs(dx) > Math.abs(dy) ? Math.abs(dx) : Math.abs(dy);
            if(maxD > 9) stepN = Math.floor(maxD / 9) + 1;
            var cx:Number = prevX;
            var cy:Number = prevY;
            var s:int = 0;
            while(s < stepN)
            {
               var nx:Number = cx + dx / stepN;
               var ny:Number = cy + dy / stepN;
               if(nx >= px1 && nx <= px2 && ny >= py1 && ny <= py2)
               {
                  if(cx <= px1 && nx >= px1) crossX = true;
                  else if(cx >= px2 && nx <= px2) crossX = true;
                  if(cy <= py1 && ny >= py1) crossY = true;
                  else if(cy >= py2 && ny <= py2) crossY = true;
                  break;
               }
               cx = nx;
               cy = ny;
               s++;
            }
         }
         if(!crossX && !crossY)
         {
            // 无历史位置（出生帧内撞墙）：按"最近穿过的面"估计——穿透量/速度最小者。
            // 比"速度主轴"更接近真实进入面（D-014 补充）。
            var bestT:Number = 1e9;
            var t:Number;
            if(dx > 0)
            {
               t = (X - px1) / dx;
               if(t < bestT)
               {
                  bestT = t;
                  crossX = true;
                  crossY = false;
               }
            }
            else if(dx < 0)
            {
               t = (px2 - X) / -dx;
               if(t < bestT)
               {
                  bestT = t;
                  crossX = true;
                  crossY = false;
               }
            }
            if(dy > 0)
            {
               t = (Y - py1) / dy;
               if(t < bestT)
               {
                  bestT = t;
                  crossY = true;
                  crossX = false;
               }
            }
            else if(dy < 0)
            {
               t = (py2 - Y) / -dy;
               if(t < bestT)
               {
                  bestT = t;
                  crossY = true;
                  crossX = false;
               }
            }
            if(!crossX && !crossY)
            {
               if(Math.abs(dx) > Math.abs(dy)) crossX = true;
               else crossY = true;
            }
         }
         // 贴图半尺寸：反弹/落点定位时让整个贴图在碰撞体外侧（贴图中心为注册点，
         // 否则反弹瞬间会"陷进地里"，玩家实测问题）
         var oldVis:* = b["vis"];
         var visCls:Class = null;
         var halfD:Number = 8;
         if(oldVis != null)
         {
            try
            {
               visCls = oldVis["constructor"] as Class;
               var vw:Number = MSWU.num(oldVis, "width");
               var vh:Number = MSWU.num(oldVis, "height");
               // 尺寸异常（空帧/NaN）时回退到 16px 常规榴弹贴图尺寸
               if(!(vw > 4)) vw = 16;
               if(!(vh > 4)) vh = 16;
               // 用对角线半径做净空：贴图随翻滚旋转（vis.rotation 累加），
               // 旋转后的包围盒下探超过半高——半高净空仍会"陷地"（玩家实测）
               halfD = Math.sqrt(vw * vw + vh * vh) / 2;
               if(halfD < 8) halfD = 8;
               if(halfD > 20) halfD = 20;
            }
            catch(e2:*)
            {
            }
         }
         if(crossX && crossY)
         {
            // 角点同时穿越两面：按"更占优的分量"选择反弹轴——
            // 水平占优弹 X（原版 PhisBullet 的 X 先判行为），
            // 垂直占优弹 Y（接近垂直入射时弹地面/天花板才符合直觉，
            // 消除该场景的"原路回弹"观感，玩家实测）。
            // 未弹的轴同时把位置贴出碰撞体（避免重生点仍在矩形内 → 陷地）。
            if(Math.abs(dx) >= Math.abs(dy))
            {
               if(inf["kind"] == "msw" && dy != 0)
               {
                  if(dy > 0) newY = py1 - halfD;
                  else newY = py2 + halfD;
               }
               crossY = false;
            }
            else
            {
               if(dx != 0)
               {
                  if(dx > 0) newX = px1 - halfD;
                  else newX = px2 + halfD;
               }
               crossX = false;
            }
         }
         if(inf["kind"] == "msw")
         {
            // 参考 PhisBullet.run 的手雷物理：弹性 = 设置值（默认 0.4，可调
            // 0..1，0 = 贴墙滑落/滚地）、落地 tormoz=0.7、|dy|<=2 落地即爆。
            var e:Number = mod.cfg.bounce;
            if(crossX)
            {
               ndx = (dx > 0 ? -1 : 1) * Math.abs(dx * e);
               if(dx >= 0) newX = px1 - halfD;
               else newX = px2 + halfD;
            }
            if(crossY)
            {
               if(dy > 0)
               {
                  if(Math.abs(dy) <= 2)
                  {
                     explode(b, X, py1 - halfD);
                     return;
                  }
                  ndy = -Math.abs(dy * e);
                  newY = py1 - halfD;
                  ndx *= 0.7;
               }
               else
               {
                  ndy = Math.abs(dy * e);
                  newY = py2 + halfD;
               }
            }
         }
         else
         {
            // 跳弹技能：镜面反射。原版碰撞包含矩形边界，精确落在面上时
            // 镜像仍在面上，须留最小净空，否则后面的墙内保护会吞掉续弹。
            if(crossX)
            {
               ndx = -dx;
               if(dx >= 0) newX = px1 - Math.max(X - px1, 0.01);
               else newX = px2 + Math.max(px2 - X, 0.01);
            }
            if(crossY)
            {
               ndy = -dy;
               if(dy >= 0) newY = py1 - Math.max(Y - py1, 0.01);
               else newY = py2 + Math.max(py2 - Y, 0.01);
            }
         }
         // 世界边界保险
         var sx:Number = MSWU.num(loc, "spaceX") * 40;
         var sy:Number = MSWU.num(loc, "spaceY") * 40;
         if(sx > 0)
         {
            if(newX < 2) newX = 2;
            if(newX > sx - 2) newX = sx - 2;
         }
         if(sy > 0)
         {
            if(newY < 2) newY = 2;
            if(newY > sy - 2) newY = sy - 2;
         }
         // 贴地图边界的墙：钳制后重生点可能仍在矩形内（会反复触墙循环）。
         // 此时不再反弹：榴弹直接引爆（等效最后一次撞击），跳弹按原版消亡。
         if(newX >= px1 && newX <= px2 && newY >= py1 && newY <= py2)
         {
            if(inf["kind"] == "msw")
            {
               explode(b, X, Y);
            }
            return;
         }

         // 先用入射速度确定反射面/落点，衰减仅影响反射后的飞行段。
         if(ricPlan != null)
         {
            ndx *= ricPlan.speedScale;
            ndy *= ricPlan.speedScale;
         }
         var nb:* = null;
         try
         {
            nb = new cls(owner, newX, newY, visCls, true);
         }
         catch(e4:*)
         {
            mod.cfg.diagSet("lastErr", "bounceNew:" + e4);
            mod.cfg.diagAdd("errBounce");
            mod.cfg.diagFlush();
         }
         if(nb == null) return;
         copyBullet(b, nb, ndx, ndy);
         if(MSWU.has(mod,"smart") && mod.smart!=null) mod.smart.inherit(b,nb);
         if(inf["kind"] == "msw")
         {
            // 手雷风格：视觉由模组驱动翻滚（vRot=false），不再沿速度指向；
            // 引信 = 剩余 liv 延续（重生不刷新 100，见 D-015）
            nb["vRot"] = false;
            nb["rot"] = 0;
            nb["liv"] = MSWU.num(inf, "livLeft", 100);
            // 反弹音效（与手雷一致：fall_grenade，音量随撞击速度）
            try
            {
               var sndCls:Class = MSWU.cls("fe.Snd");
               if(sndCls != null)
               {
                  sndCls["ps"]("fall_grenade", X, Y, 0, Math.min(Math.abs(dx) / 10, 1));
               }
            }
            catch(e3:*)
            {
            }
         }
         else
         {
            nb["liv"] = 100;
            nb["damage"] = ricPlan.damage;
            // 新飞行段从反弹点计算命中距离；关闭时保留 copyBullet 的累计距离。
            if(ricPlan.resetDistance) nb["dist"] = 0;
            var chain:MSWRicochet = inf["ric"] as MSWRicochet;
            chain.recordBounce();
            mod.cfg.diagAdd("ricBounce");
            if(ricPlan.extra) mod.cfg.diagAdd("ricExtra");
            mod.cfg.diagSet("ricLastCount", chain.count);
         }
         track[nb] = {
            "kind": inf["kind"],
            "prevX": newX,
            "prevY": newY,
            "ric": inf["ric"],
            "hits": MSWU.num(inf, "hits") - 1,
            "livLeft": MSWU.num(inf, "livLeft", 100),
            "spin": 0,
            "dead": false
         };
         // 出生帧撞墙在扫描阶段就会生成续弹；它尚未被链扫描见到，
         // 但本帧确实存活，不能让后面的清理分支删除其计数/设置快照。
         seen[nb] = true;
      }

      private function copyBullet(b:*, nb:*, ndx:Number, ndy:Number):void
      {
         var vel:Number = Math.sqrt(ndx * ndx + ndy * ndy);
         if(vel <= 0) vel = MSWU.num(b, "vel", 1);
         nb["dx"] = ndx;
         nb["dy"] = ndy;
         nb["vel"] = vel;
         nb["knockx"] = ndx / vel;
         nb["knocky"] = ndy / vel;
         nb["rot"] = Math.atan2(ndy, ndx);
         nb["vRot"] = b["vRot"];
         nb["weap"] = b["weap"];
         nb["weapId"] = b["weapId"];
         nb["damage"] = MSWU.num(b, "damage");
         nb["damageExpl"] = MSWU.num(b, "damageExpl");
         nb["destroy"] = MSWU.num(b, "destroy");
         nb["tipDamage"] = MSWU.num(b, "tipDamage");
         nb["tipDecal"] = MSWU.num(b, "tipDecal");
         nb["otbros"] = MSWU.num(b, "otbros");
         nb["pier"] = MSWU.num(b, "pier");
         nb["armorMult"] = MSWU.num(b, "armorMult", 1);
         nb["precision"] = MSWU.num(b, "precision");
         nb["antiprec"] = MSWU.num(b, "antiprec");
         nb["miss"] = MSWU.num(b, "miss");
         nb["probiv"] = MSWU.num(b, "probiv");
         nb["spring"] = MSWU.num(b, "spring");
         nb["flare"] = b["flare"];
         nb["desintegr"] = MSWU.num(b, "desintegr");
         nb["critCh"] = MSWU.num(b, "critCh");
         nb["critDamMult"] = MSWU.num(b, "critDamMult", 1);
         nb["critInvis"] = MSWU.num(b, "critInvis");
         nb["critM"] = MSWU.num(b, "critM");
         nb["ddy"] = MSWU.num(b, "ddy");
         nb["ddx"] = MSWU.num(b, "ddx");
         nb["explTip"] = MSWU.num(b, "explTip", 1);
         nb["explKol"] = MSWU.num(b, "explKol");
         nb["dist"] = MSWU.num(b, "dist");
         nb["liv"] = 100;
         var v:* = nb["vis"];
         var ov:* = b["vis"];
         if(v != null && ov != null)
         {
            try
            {
               v["blendMode"] = ov["blendMode"];
            }
            catch(e:*)
            {
            }
         }
      }

      /**
       * 在 (X,Y) 引爆：复刻 iExpl（但保留原 otbros 击退/震动），
       * 走原版 explosion()→explRun 全流程。
       */
      private function explode(b:*, X:Number, Y:Number):void
      {
         mod.cfg.diagAdd("explode");
         killVis(b);
         var cls:Class = bulletClass();
         if(cls == null) return;
         var owner:* = b["owner"];
         if(owner == null) return;
         var weap:* = b["weap"];
         var dmg:Number = MSWU.num(b, "damageExpl");
         // 破坏力/贴花用武器原值（飞行期间 weapon.destroy/tipDecal 被置 0，
         // 爆炸时按原值完整结算，见 D-021）
         var dest:Number = mod.weapon.origDestroy(weap);
         var rad:Number = mod.weapon.origExplRadius(weap);
         var dummy:* = new cls(owner, X, Y, null, true);
         if(dummy == null) return;
         dummy["weap"] = weap;
         dummy["weapId"] = b["weapId"];
         dummy["tipDamage"] = 4; // D_EXPL
         dummy["otbros"] = MSWU.num(b, "otbros", 10);
         dummy["damageExpl"] = dmg;
         dummy["destroy"] = dest;
         dummy["tipDecal"] = mod.weapon.origTipDec(weap);
         dummy["explRadius"] = rad;
         try
         {
            dummy["explosion"]();
         }
         catch(e:*)
         {
         }
         dummy["liv"] = 1;
      }
   }
}
