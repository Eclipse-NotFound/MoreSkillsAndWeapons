package
{
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFieldAutoSize;
   import flash.utils.getQualifiedClassName;

   /**
    * 设置面板：两个宿主，同一份状态。
    *
    * 1) 哔哔小马（PipBuck）设置页宿主（主）：
    *    检测 `pip.active && currentPage 是 fe.inter::PipPageOpt`（public 可读；
    *    page2/internal 不可读，故不区分子页，页面顶部横幅对所有子页可见）。
    *    挂到 `World.w.vpip`（public）内 (185,80)（页面 vis 位于 vpip 内
    *    (165,72)，顶部 statHead 横幅在该页恒隐藏，此区域空闲）。
    *    页面 UI 纯鼠标驱动（PipPage/PipBuck 无键盘监听），方向键可安全消费；
    *    唯一例外是"按键绑定"对话框（visSetKey），显示期间不消费按键。
    *
    * 2) F8 浮层宿主（辅）：挂在 World.w.main 左上角。设置页打开时 F8 被忽略
    *    （避免两个面板叠加）。
    */
   public class MSWPanel
   {
      private var mod:*;

      public var overlayOpen:Boolean = false;

      private var sel:int = 0;
      private var pipTf:TextField = null;
      private var ovTf:TextField = null;

      private static const ROWS:int = 10;
      public static const KEY_F8:int = 119;
      public static const PAGE_QNAME:String = "fe.inter::PipPageOpt";

      public function MSWPanel(m:*)
      {
         mod = m;
      }

      // ---------------- 检测 ----------------

      public function pipPageActive(w:*):Boolean
      {
         if(w == null) return false;
         var pip:* = w["pip"];
         if(pip == null || pip["active"] != true) return false;
         var page:* = pip["currentPage"];
         if(page == null) return false;
         try
         {
            return getQualifiedClassName(page) == PAGE_QNAME;
         }
         catch(e:*)
         {
            return false;
         }
         return false;
      }

      /** 按键绑定对话框（visSetKey）是否可见：可见期间不消费键盘。 */
      public function setkeyDialogVisible(w:*):Boolean
      {
         if(w == null) return false;
         return findClass(w["vpip"], "visSetKey");
      }

      private function findClass(o:*, qname:String):Boolean
      {
         if(o == null) return false;
         try
         {
            var n:int = o["numChildren"];
            for(var i:int = 0; i < n; i++)
            {
               var c:* = o.getChildAt(i);
               if(c["visible"] != true) continue;
               var qn:String = getQualifiedClassName(c);
               if(qn != null && qn.indexOf(qname) >= 0) return true;
               if(findClass(c, qname)) return true;
            }
         }
         catch(e:*)
         {
         }
         return false;
      }

      // ---------------- 按键 ----------------

      /** 返回 true = 已消费。 */
      public function handleKey(code:int):Boolean
      {
         if(code == 38) // Up
         {
            sel = (sel + ROWS - 1) % ROWS;
            refresh();
            return true;
         }
         if(code == 40) // Down
         {
            sel = (sel + 1) % ROWS;
            refresh();
            return true;
         }
         var d:int = 0;
         if(code == 37) d = -1; // Left
         else if(code == 39 || code == 13) d = 1; // Right / Enter
         if(d != 0)
         {
            if(sel == 0) mod.cfg.ricochet = !mod.cfg.ricochet;
            else if(sel == 1) mod.cfg.dropRate += d * 0.1;
            else if(sel == 2) mod.cfg.wallHits += d;
            else if(sel == 3) mod.cfg.muzzleVel += d;
            else if(sel == 4) mod.cfg.bounce += d * 0.1;
            else if(sel == 5) mod.cfg.aimSkill = !mod.cfg.aimSkill;
            // 2026-08-17 自 Sandevistan 迁移（MSWProjHits / MSWSwaprun）
            else if(sel == 6) mod.cfg.projHits = !mod.cfg.projHits;
            else if(sel == 7) mod.cfg.projHp += d * 5;
            else if(sel == 8) mod.cfg.projArmor += d * 5;
            else mod.cfg.swapRun = !mod.cfg.swapRun;
            mod.cfg.clamp();
            mod.cfg.save();
            refresh();
            return true;
         }
         return false;
      }

      public function toggleOverlay():void
      {
         overlayOpen = !overlayOpen;
         refresh();
      }

      // ---------------- 帧更新 ----------------

      public function update(w:*):void
      {
         try
         {
            if(w == null) return;
            var pipOn:Boolean = pipPageActive(w);
            if(pipOn)
            {
               var vpip:* = w["vpip"];
               if(vpip != null)
               {
                  if(pipTf == null) pipTf = makeTf();
                  if(pipTf["parent"] != vpip)
                  {
                     try
                     {
                        vpip.addChild(pipTf);
                     }
                     catch(e:*)
                     {
                     }
                  }
                  pipTf["visible"] = true;
                  pipTf["x"] = 185;
                  pipTf["y"] = 80;
               }
            }
            else if(pipTf != null)
            {
               pipTf["visible"] = false;
            }
            if(overlayOpen)
            {
               var main:* = w["main"];
               if(main != null)
               {
                  if(ovTf == null) ovTf = makeTf();
                  if(ovTf["parent"] != main)
                  {
                     try
                     {
                        main.addChild(ovTf);
                     }
                     catch(e:*)
                     {
                     }
                  }
                  ovTf["visible"] = true;
                  ovTf["x"] = 24;
                  ovTf["y"] = 64;
               }
            }
            else if(ovTf != null)
            {
               ovTf["visible"] = false;
            }
            refresh();
         }
         catch(e:*)
         {
         }
      }

      // ---------------- 渲染 ----------------

      private function makeTf():TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         fmt.font = "SimHei";
         fmt.size = 15;
         fmt.color = 0xFFFFFF;
         tf.defaultTextFormat = fmt;
         tf.background = true;
         tf.backgroundColor = 0x000000;
         tf.alpha = 0.85;
         tf.border = true;
         tf.borderColor = 0x666666;
         tf.multiline = true;
         tf.wordWrap = false;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.autoSize = TextFieldAutoSize.LEFT;
         return tf;
      }

      private function refresh():void
      {
         var c:* = mod.cfg;
         var s:String = "";
         s += MSWWeapon.WEAPON_NAME + " 模组设置\n";
         s += "--------------------------------\n";
         s += (sel == 0 ? "> " : "  ") + "跳弹技能 : " + (c.ricochet ? "开" : "关") + "\n";
         s += (sel == 1 ? "> " : "  ") + "下坠速率 : " + c.dropRate.toFixed(1) + "  (0-3, 1=原版)\n";
         s += (sel == 2 ? "> " : "  ") + "撞墙次数 : " + c.wallHits + "  (0=撞墙即爆)\n";
         s += (sel == 3 ? "> " : "  ") + "初速度   : " + c.muzzleVel + "  (10-100, 原版 35)\n";
         s += (sel == 4 ? "> " : "  ") + "反弹力度 : " + c.bounce.toFixed(1) + "  (0-1, 原版 0.4)\n";
          s += (sel == 5 ? "> " : "  ") + "蹲/梯举枪 : " + (c.aimSkill ? "开" : "关") + "  (Shift+W)\n";
         // 2026-08-17 自 Sandevistan 迁移（MSWProjHits / MSWSwaprun）
         s += (sel == 6 ? "> " : "  ") + "手雷击落 : " + (c.projHits ? "开" : "关") + "\n";
         s += (sel == 7 ? "> " : "  ") + "投掷物血量 : " + c.projHp + "\n";
         s += (sel == 8 ? "> " : "  ") + "投掷物护甲 : " + c.projArmor + "\n";
         s += (sel == 9 ? "> " : "  ") + "疾跑切枪 : " + (c.swapRun ? "开" : "关") + "  (Shift+数字键)\n";
         s += "←→/Enter 调整   ↑↓ 选择";
         if(pipTf != null) pipTf["text"] = s;
         if(ovTf != null) ovTf["text"] = s;
      }
   }
}
