package
{
   import flash.events.MouseEvent;
   import flash.text.TextFormat;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;

   /**
    * 哔哔小马"模组"页签：把模组设置整合进 PipBuck 主页签栏（用户需求 2026-08-28）。
    *
    * 机制（对照 1.02 反编译 PipBuck/PipPage，game-reference）：
    * - 页签栏 = pip.vis（= World.w.vpip，public）下的 but0..but5 MovieClip：
    *   but0=关闭，but1..but5 对应 pages[1..5]（stat/inv/info/vend/opt）。
    * - pages/page/kolPages/vis 均 internal（D-039：bracket 访问抛 #1069），
    *   无法注册"真"页面 → 克隆页签按钮类挂到栏尾，点击后自行接管：
    *   隐藏底层页面视觉（页面显隐由 PipPage.setStatus 驱动，游戏切页时自动恢复），
    *   显示模组设置内容，页签 gotoAndStop(2) 高亮，pip.snd(2) 与原版同音。
    * - 失活时机：点任意原版页签（后挂监听，游戏切页在前，已切页则不恢复旧页）/
    *   pip 关闭 / currentPage 引用变化（键盘切页）/ 再点本页签或 F6。
    * - 内容 TextField 由 MSWPanel 拥有并写入文本，这里只管挂载/定位/显隐。
    */
   public class MSWPipTab
   {
      private var mod:*;

      private var built:Boolean = false;
      private var tab:* = null;              // 克隆的页签按钮（but5 同类）
      private var active:Boolean = false;    // 本页签是否正接管显示
      private var activePageRef:* = null;    // 激活时的 currentPage（判"游戏已切页"）
      private var hiddenVis:Array = null;    // 激活时被隐藏的底层页面视觉（恢复用）
      private var contentTf:TextField = null;

      public function MSWPipTab(m:*)
      {
         mod = m;
      }

      public function isActive():Boolean
      {
         return active;
      }

      /** 由 MSWPanel 注入内容文本框（拥有者仍是 MSWPanel）。 */
      public function bindContent(tf:TextField):void
      {
         contentTf = tf;
      }

      // ---------------- 每帧 ----------------

      public function update(w:*):void
      {
         try
         {
            if(w == null) return;
            var pip:* = w["pip"];
            if(pip == null) return;
            ensureTab(w);
            if(tab == null) return;
            var b5:* = w["vpip"]["getChildByName"]("but5");
            if(b5 != null) tab["visible"] = b5["visible"];
            var pipOn:Boolean = pip["active"] == true;
            if(active && (!pipOn || !sameRef(pip["currentPage"], activePageRef)))
            {
               // pip 关闭 / 游戏已切页：静默失活，不恢复旧页面（游戏全权管理）
               deactivate(w, pip, false);
            }
            else if(active)
            {
               placeContent(w);
            }
         }
         catch(e:*)
         {
            mod.cfg.diagSet("lastErr", "pipTab:" + e);
         }
      }

      // ---------------- 页签构建 ----------------

      private function ensureTab(w:*):void
      {
         if(built) return;
         var vpip:* = w["vpip"];
         if(vpip == null) return;
         var b1:* = vpip["getChildByName"]("but1");
         var b5:* = vpip["getChildByName"]("but5");
         if(b1 == null || b5 == null) return;
         if(b1["visible"] != true) return; // toNormalMode 未跑（主菜单/light 模式）
         var cls:Class = getDefinitionByName(getQualifiedClassName(b5)) as Class;
         if(cls == null) return;
         var t:* = new cls();
         t["mouseChildren"] = false;                 // 对齐原版按钮（constructor 同款）
         t["id"]["visible"] = false;                 // id 是隐形数据格（同原版）
         t["id"]["text"] = "msw";
         var lt:* = t["text"];                       // 标签 TextField
         try
         {
            lt["embedFonts"] = false;                // 中文走设备字体（面板同款 SimHei）
            var fmt:TextFormat = new TextFormat();
            fmt.font = "SimHei";
            fmt.size = 13;
            fmt.color = 0x00FF99;                    // pip 绿（setStyle 主色）
            lt["defaultTextFormat"] = fmt;
         }
         catch(e1:*)
         {
         }
         lt["text"] = "模组";
         t["x"] = b5["x"] + b5["width"] + 2;
         t["y"] = b5["y"];
         t.addEventListener(MouseEvent.CLICK, onTabClick);
         for(var i:int = 0; i <= 5; i++)
         {
            var b:* = vpip["getChildByName"]("but" + i);
            if(b != null) b.addEventListener(MouseEvent.CLICK, onGameTabClick);
         }
         vpip["addChild"](t);
         tab = t;
         built = true;
         mod.cfg.diagAdd("tabBuild");
      }

      // ---------------- 点击 ----------------

      private function guardOk(w:*):Boolean
      {
         // 对齐 PipBuck.pageClick 的两个守卫：绑定键对话框 / gg.pipOff
         try
         {
            var ctr:* = w["ctr"];
            if(ctr != null && ctr["setkeyOn"] == true) return false;
            var gg:* = w["gg"];
            if(gg != null && gg["pipOff"] == true) return false;
         }
         catch(e:*)
         {
         }
         return true;
      }

      private function onTabClick(e:*):void
      {
         try
         {
            var w:* = MSWU.world();
            if(w == null) return;
            var pip:* = w["pip"];
            if(pip == null || pip["active"] != true) return;
            if(!guardOk(w)) return;
            if(active) deactivate(w, pip, true);
            else activate(w, pip);
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabClick:" + err);
         }
      }

      private function onGameTabClick(e:*):void
      {
         // 游戏页签被点：游戏 pageClick 先跑（先注册先执行），
         // 这里随后失活；已切页 → 不恢复旧页视觉
         try
         {
            if(!active) return;
            var w:* = MSWU.world();
            if(w == null) return;
            var pip:* = w["pip"];
            if(pip == null) return;
            deactivate(w, pip, false);
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "gameTab:" + err);
         }
      }

      /** F6 / 重复点击的切换入口（MSWPanel 代理）。 */
      public function toggle(w:*):void
      {
         try
         {
            var pip:* = w["pip"];
            if(pip == null || pip["active"] != true) return;
            if(!guardOk(w)) return;
            if(active) deactivate(w, pip, true);
            else activate(w, pip);
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabToggle:" + err);
         }
      }

      // ---------------- 接管 / 交还 ----------------

      private function activate(w:*, pip:*):void
      {
         activePageRef = pip["currentPage"];
         hidePageVis(w);
         sweepGameTabs(w);
         tab["gotoAndStop"](2);
         try
         {
            pip["snd"](2);
         }
         catch(e:*)
         {
         }
         active = true;
         mod.cfg.diagAdd("tabOn");
      }

      private function deactivate(w:*, pip:*, restore:Boolean):void
      {
         active = false;
         tab["gotoAndStop"](1);
         var switched:Boolean = !sameRef(pip["currentPage"], activePageRef);
         if(restore && !switched) restorePageVis();
         else hiddenVis = null; // 游戏已切页/pip 已关：显隐归游戏管
         activePageRef = null;
         mod.cfg.diagAdd("tabOff");
      }

      private function sweepGameTabs(w:*):void
      {
         var vpip:* = w["vpip"];
         if(vpip == null) return;
         for(var i:int = 0; i <= 5; i++)
         {
            var b:* = vpip["getChildByName"]("but" + i);
            if(b != null) b["gotoAndStop"](1);
         }
      }

      /** 隐藏 vpip 下非 chrome 的可见子级（即当前页面视觉），记录以便恢复。 */
      private function hidePageVis(w:*):void
      {
         hiddenVis = null;
         var vpip:* = w["vpip"];
         if(vpip == null) return;
         hiddenVis = [];
         var n:int = vpip["numChildren"];
         for(var i:int = n - 1; i >= 0; i--)
         {
            var c:* = vpip["getChildAt"](i);
            if(c == tab || c == contentTf) continue;
            if(!isChrome(c) && c["visible"] == true)
            {
               c["visible"] = false;
               hiddenVis[hiddenVis.length] = c;
            }
         }
      }

      private function restorePageVis():void
      {
         if(hiddenVis == null) return;
         for(var i:int = 0; i < hiddenVis.length; i++)
         {
            try
            {
               hiddenVis[i]["visible"] = true;
            }
            catch(e:*)
            {
            }
         }
         hiddenVis = null;
      }

      /** 具名 UI（butN/toptext/pr/pipError/skin/fon/butHelp/butMass）与
       *  帮助/绑定键对话框是 chrome；页面视觉是匿名 new 实例（name=instanceN）。 */
      private function isChrome(c:*):Boolean
      {
         try
         {
            var nm:String = c["name"];
            if(nm != null && nm != "" && nm.indexOf("instance") != 0) return true;
            var qn:String = getQualifiedClassName(c);
            if(qn != null && (qn.indexOf("visSetKey") >= 0 || qn.indexOf("visPipHelp") >= 0)) return true;
         }
         catch(e:*)
         {
            return true;
         }
         return false;
      }

      private function placeContent(w:*):void
      {
         if(contentTf == null) return;
         var vpip:* = w["vpip"];
         if(vpip == null) return;
         if(contentTf["parent"] != vpip)
         {
            try
            {
               vpip["addChild"](contentTf);
            }
            catch(e:*)
            {
               return;
            }
         }
         contentTf["x"] = 185;
         contentTf["y"] = 80;
         contentTf["visible"] = true;
      }

      private function sameRef(a:*, b:*):Boolean
      {
         return a === b;
      }
   }
}
