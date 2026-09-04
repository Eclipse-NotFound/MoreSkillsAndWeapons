package
{
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFieldAutoSize;
   import flash.utils.getQualifiedClassName;

   /**
    * 设置面板：两个宿主，同一份配置。
    *
    * 1) 哔哔小马"模组"子页（主，2026-08-28 v2）：Opt 页子按钮栏的"模组"按钮
    *    （见 MSWPipTab），点击后以原版控件（CheckBox/滑块）显示设置行。
    *    取代 v1 的主页签栏按钮与文字面板。纯鼠标交互。
    *
    * 2) F6 浮层宿主（辅）：挂在 World.w.main 左上角，纯游戏中快速调参（键盘）。
    *    pip 打开期间 F6 = 开/关"模组"面板，浮层不叠加。
    */
   public class MSWPanel
   {
      private var mod:*;

      public var overlayOpen:Boolean = false;

      private var sel:int = 0;
      private var tab:MSWPipTab;
      private var ovTf:TextField = null; // F6 浮层内容（黑底白字框）

      private static const ROWS:int = 12;

      public function MSWPanel(m:*)
      {
         mod = m;
         tab = new MSWPipTab(m);
      }

      // ---------------- 状态查询 ----------------

      /** 原版选项页是否打开（诊断计数用）。 */
      public function pipPageActive(w:*):Boolean
      {
         if(w == null) return false;
         var pip:* = w["pip"];
         if(pip == null || pip["active"] != true) return false;
         var page:* = pip["currentPage"];
         if(page == null) return false;
         try
         {
            return getQualifiedClassName(page) == "fe.inter::PipPageOpt";
         }
         catch(e:*)
         {
            return false;
         }
         return false;
      }

      /** 模组面板是否展开。 */
      public function tabActive():Boolean
      {
         return tab.isActive();
      }

      /** pip 开着时 F6 开/关模组面板。 */
      public function tabToggle(w:*):void
      {
         tab.toggle(w);
      }

      /** 自动测试用：对模组按钮派发真实点击。 */
      public function debugClick():void
      {
         tab.debugClick();
      }

      /** 自动测试用：切换模组子页。 */
      public function debugSwitchPage(i:int):void
      {
         tab.debugSwitchPage(i);
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

      // ---------------- 按键（F6 浮层用） ----------------

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
            else if(sel == 9) mod.cfg.swapRun = !mod.cfg.swapRun;
            else if(sel == 10) mod.cfg.spreadFix = !mod.cfg.spreadFix;
            else mod.cfg.dashKeepPose = !mod.cfg.dashKeepPose;
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
            var pipOn:Boolean = false;
            try
            {
               pipOn = w["pip"] != null && w["pip"]["active"] == true;
            }
            catch(e0:*)
            {
            }
            // pip 打开时不保留 F6 浮层（避免与哔哔小马 UI 叠加；F6 改开模组面板）
            if(pipOn && overlayOpen) overlayOpen = false;
            tab.update(w);
            if(overlayOpen)
            {
               var main:* = w["main"];
               if(main != null)
               {
                  if(ovTf == null) ovTf = makeOverlayTf();
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

      /** F6 浮层：黑底白字框（游戏中一眼可辨是模组 UI）。 */
      private function makeOverlayTf():TextField
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
         if(ovTf == null) return;
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
         s += (sel == 10 ? "> " : "  ") + "散布恒定 : " + (c.spreadFix ? "开" : "关") + "  (仅榴弹炮)\n";
         s += (sel == 11 ? "> " : "  ") + "冲刺保持蹲/趴 : " + (c.dashKeepPose ? "开" : "关") + "  (魔法冲刺)\n";
         s += "←→/Enter 调整   ↑↓ 选择";
         ovTf["text"] = s;
      }
   }
}
