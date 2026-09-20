package
{
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFieldAutoSize;
   import flash.utils.getQualifiedClassName;

   /**
    * MSW-owned F6 overlay; when Pip is open the shortcut routes to ModSettings.
    * Both entries use the same MSW-owned setting definitions and configuration.
    */
   public class MSWPanel
   {
      private var mod:*;

      public var overlayOpen:Boolean = false;

      private var sel:int = 0;
      private var ovTf:TextField = null; // F6 浮层内容（黑底白字框）

      private var items:Array; // 与模组设置页共用同一份设置定义
      private var smartPage:Boolean = false;

      public function MSWPanel(m:*)
      {
         mod = m;
         items = MSWSettingsHub.buildMswItems(m);
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
         var api:* = mod.settings.api;
         return api != null && api.isOpen();
      }

      /** pip 开着时 F6 开/关模组面板。 */
      public function tabToggle(w:*):void
      {
         var api:* = mod.settings.api;
         if(api != null && api.togglePage(smartPage ? "msw-smart" : "msw")) mod.cfg.diagAdd("tabOn");
      }

      /** 自动测试用：对模组按钮派发真实点击。 */
      public function debugClick():void
      {
         tabToggle(MSWU.world());
      }

      /** 自动测试用：切换模组子页。 */
      public function debugSwitchPage(i:int):void
      {
         var api:* = mod.settings.api;
         var pages:Array = mod.settings.getPages();
         if(api != null && i >= 0 && i < pages.length) api.selectPage(pages[i].modId);
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
         if(code==9 || code==33 || code==34)
         {
            smartPage=!smartPage; sel=0;
            items=smartPage?MSWSettingsHub.buildSmartItems(mod):MSWSettingsHub.buildMswItems(mod);
            refresh(); return true;
         }
         if(code == 38) // Up
         {
            sel = (sel + items.length - 1) % items.length;
            refresh();
            return true;
         }
         if(code == 40) // Down
         {
            sel = (sel + 1) % items.length;
            refresh();
            return true;
         }
         var d:int = 0;
         if(code == 37) d = -1; // Left
         else if(code == 39 || code == 13) d = 1; // Right / Enter
         if(d != 0)
         {
            var it:Object = items[sel];
            var value:* = it["get"]();
            it["set"](it["kind"] == "check" ? !Boolean(value) : Number(value) + d * Number(it["step"]));
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
         s += (smartPage ? "智能武器" : MSWWeapon.WEAPON_NAME) + " 模组设置 [Tab 切页]\n";
         s += "--------------------------------\n";
         for(var i:int = 0; i < items.length; i++)
         {
            var it:Object = items[i];
            var value:* = it["get"]();
            var label:String = it["kind"] == "check" ? (value ? "开" : "关") :
               (Number(it["step"]) < 0.1 ? Number(value).toFixed(2) : Number(it["step"]) < 1 ? Number(value).toFixed(1) : String(value));
            s += (sel == i ? "> " : "  ") + it["label"] + " : " + label + it["suffix"] + "\n";
         }
         s += "←→/Enter 调整   ↑↓ 选择\n";
         s += items[sel]["hint"];
         ovTf["text"] = s;
      }
   }
}
