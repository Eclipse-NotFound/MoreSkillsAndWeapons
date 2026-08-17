package
{
   import flash.display.MovieClip;

   /**
    * 可编程榴弹炮的 SATS 弹道覆盖层。
    *
    * 原版 Weapon.setTrass 只判 grav 非零就加固定 World.ddy（不乘 grav 值），
    * 无法表达自定义下坠；本类在 vsats（与 SATS 视觉同相机变换）内自绘弧线，
    * 复刻 Trasser 的 maxdelta 子步与 tile 撞墙判定，并按 wallHits 加入弹跳预览。
    */
   public class MSWTrajectory
   {
      private var mod:*;
      private var overlay:MovieClip = null;
      private var overlayParent:* = null;

      private static const MAXDELTA:Number = 9;   // World.maxdelta
      private static const TILE:Number = 40;      // World.tileX/tileY
      private static const MAXSTEPS:int = 100;    // Trasser.liv

      public function MSWTrajectory(m:*)
      {
         mod = m;
      }

      /** 每帧调用。 */
      public function update(w:*):void
      {
         try
         {
            if(w == null) return;
            var sats:* = w["sats"];
            var gg:* = w["gg"];
            var wp:* = (gg != null) ? gg["currentWeapon"] : null;
            var ours:Boolean = sats != null && sats["active"] == true &&
               wp != null && MSWU.str(wp, "id") == MSWWeapon.WEAPON_ID;
            if(!ours)
            {
               hide();
               return;
            }
            var vsats:* = w["vsats"];
            if(vsats == null)
            {
               hide();
               return;
            }
            if(overlay == null || overlayParent != vsats)
            {
               overlay = new MovieClip();
               overlayParent = vsats;
               vsats.addChild(overlay);
            }
            // 隐藏原版弹道/半径圈（noTrass 已让游戏不画，双保险防残留）
            try
            {
               sats["trasser"]["visible"] = false;
               sats["radius"]["visible"] = false;
            }
            catch(e:*)
            {
            }
            draw(w, wp);
         }
         catch(e:*)
         {
         }
      }

      private function hide():void
      {
         if(overlay != null && overlay["parent"] != null)
         {
            try
            {
               overlay["parent"].removeChild(overlay);
            }
            catch(e:*)
            {
            }
         }
         overlay = null;
         overlayParent = null;
      }

      private function draw(w:*, wp:*):void
      {
         var g:* = overlay["graphics"];
         g.clear();
         var loc:* = w["loc"];
         if(loc == null) return;
         var X:Number = MSWU.num(wp, "X");
         var Y:Number = MSWU.num(wp, "Y");
         var celX:Number = MSWU.num(w, "celX");
         var celY:Number = MSWU.num(w, "celY");
         var speed:Number = MSWU.num(wp, "speed") * MSWU.num(wp, "speedMult", 1);
         var ang:Number = Math.atan2(celY - Y, celX - X);
         var dx:Number = Math.cos(ang) * speed;
         var dy:Number = Math.sin(ang) * speed;
         var ddy:Number = mod.cfg.dropRate; // World.ddy == 1
         var eb:Number = mod.cfg.bounce;    // 反弹弹性（与实战一致）
         var hitsLeft:int = mod.cfg.wallHits;
         var spaceX:Number = MSWU.num(loc, "spaceX") * TILE;
         var spaceY:Number = MSWU.num(loc, "spaceY") * TILE;

         g.lineStyle(5, 65433, 0.5);
         g.moveTo(X, Y);
         var cx:Number = X;
         var cy:Number = Y;
         var cdx:Number = dx;
         var cdy:Number = dy;
         var ended:Boolean = false;

         for(var i:int = 0; i < MAXSTEPS && !ended; i++)
         {
            cdy += ddy;
            var n:int = 1;
            var m:Number = Math.abs(cdx) > Math.abs(cdy) ? Math.abs(cdx) : Math.abs(cdy);
            if(m > MAXDELTA) n = Math.floor(m / MAXDELTA) + 1;
            for(var s:int = 0; s < n && !ended; s++)
            {
               // X 轴
               cx += cdx / n;
               if(cx < 0 || cx >= spaceX)
               {
                  ended = true;
                  break;
               }
               var t:* = loc["getAbsTile"](cx, cy);
               if(t != null && MSWU.num(t, "phis") == 1 &&
                  cx >= MSWU.num(t, "phX1") && cx <= MSWU.num(t, "phX2") &&
                  cy >= MSWU.num(t, "phY1") && cy <= MSWU.num(t, "phY2"))
               {
                  if(hitsLeft <= 0)
                  {
                     ended = true;
                     break;
                  }
                  // 手雷物理：弹性 = 设置值（与 MSWBullets.bounce 一致）
                  if(cdx < 0) cx = MSWU.num(t, "phX2") + 1;
                  else cx = MSWU.num(t, "phX1") - 1;
                  cdx = (cdx < 0 ? 1 : -1) * Math.abs(cdx * eb);
                  hitsLeft--;
               }
               // Y 轴
               if(cdy != 0)
               {
                  cy += cdy / n;
                  if(cy < 0 || cy >= spaceY)
                  {
                     ended = true;
                     break;
                  }
                  t = loc["getAbsTile"](cx, cy);
                  if(t != null && MSWU.num(t, "phis") == 1 &&
                     cy >= MSWU.num(t, "phY1") && cy <= MSWU.num(t, "phY2") &&
                     cx >= MSWU.num(t, "phX1") && cx <= MSWU.num(t, "phX2"))
                  {
                     if(hitsLeft <= 0)
                     {
                        ended = true;
                        break;
                     }
                     if(cdy > 0)
                     {
                        // 砸向地面：小速度落地静止，否则弹性 0.4 + 摩擦 0.7
                        if(Math.abs(cdy) <= 2)
                        {
                           cy = MSWU.num(t, "phY1") - 1;
                           ended = true;
                           break;
                        }
                        cy = MSWU.num(t, "phY1") - 1;
                        cdy = -Math.abs(cdy * eb);
                        cdx *= 0.7;
                     }
                     else
                     {
                        cy = MSWU.num(t, "phY2") + 1;
                        cdy = Math.abs(cdy * eb);
                     }
                     hitsLeft--;
                  }
               }
            }
            if(!ended) g.lineTo(cx, cy);
         }

         // 终点爆炸范围圈：用原版 SATS 同款素材 satsRadius（绿色圆），
         // 缩放公式与原版一致（scale = explRadius/100，素材半径 100px）——
         // 对齐原版榴弹武器的爆炸范围显示（玩家反馈：自绘红色圈不一致）。
         var rad:Number = mod.weapon.origExplRadius(wp);
         var rc:* = overlay["radiusMc"];
         if(rad > 0)
         {
            if(rc == null)
            {
               try
               {
                  var rcCls:Class = MSWU.cls("satsRadius");
                  if(rcCls != null)
                  {
                     rc = new rcCls();
                     rc["cacheAsBitmap"] = true;
                     overlay.addChild(rc);
                     overlay["radiusMc"] = rc;
                  }
               }
               catch(e:*)
               {
               }
            }
            if(rc != null)
            {
               rc["x"] = cx;
               rc["y"] = cy;
               rc["scaleX"] = rad / 100;
               rc["scaleY"] = rad / 100;
               rc["visible"] = true;
            }
         }
         else if(rc != null)
         {
            rc["visible"] = false;
         }
      }
   }
}
