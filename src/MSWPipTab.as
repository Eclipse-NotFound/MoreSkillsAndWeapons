package
{
   import flash.events.MouseEvent;
   import flash.text.TextFormat;
   import flash.text.TextField;
   import flash.utils.Dictionary;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;

   /**
    * 哔哔小马"模组"子页按钮 + 原版控件设置面板（v2，2026-08-28 用户反馈后重做）。
    *
    * v1（主页签栏克隆按钮）废弃：用户要求按钮与"主菜单"页的
    * 载入/保存/选项/控制/记录 并列，且控件要像原版（按钮/滑块）。
    *
    * 机制（对照 1.02 反编译 PipBuck/PipPage/PipPageOpt）：
    * - Opt 页（fe.inter::PipPageOpt）复用 visPipInv 布局：子按钮 but1..but5
    *   （page2Click 是 public，读按钮 id.text 切子页），列表行 = visPipOptItem
    *   （自带 fl.controls.CheckBox「check」与 ScrollBar 滑块「scr」，原版
    *   选项页就是这么做的），行位置 x=30, y=100+i*30。
    * - "模组"按钮 = 克隆 Opt 页子按钮类，挂 but5 旁；点击后隐藏该页游戏内容
    *   （匿名 instance* 子级 + scBar），显示自建 visPipOptItem 行：
    *   开关行用 check（CHANGE 事件），数值行用 scr（"scroll" 事件，拖动实时生效，
    *   关面板时才 save()——避免拖动期间高频 SharedObject.flush（D-035 教训）。
    * - 失活：点任意子按钮/主页签（后挂监听，游戏先跑）/ pip 关闭 / 非 Opt 页
    *   （update 每帧判定 currentPage）。pip.onoff(5) 是 public——F6 可从任意
    *   子页直接跳到 Opt 页并展开本面板。
    * - 隐藏/恢复策略：open 时记录并隐藏；每帧 enforce 再压制（防游戏
    *   setStatItems 复显）；close 恢复。游戏切子页会自己重渲染，恢复无冲突。
    */
   public class MSWPipTab
   {
      private var mod:*;

      private var built:Boolean = false;
      private var myBut:* = null;          // "模组"子按钮（克隆 Opt 子按钮类）
      private var head:* = null;           // 标题行（visPipOptItem.back 样式）
      private var rows:Array = null;       // 12 个 visPipOptItem
      private var panelOpen:Boolean = false;
      private var hiddenVis:Array = null;  // open 时被隐藏的游戏子级
      private var cfgDirty:Boolean = false;

      // 行定义：key / 标签 / "check"|"slider" / 滑块最小值 / 滑块最大刻度 / 换算
      // 换算：val = f(pos)，pos ∈ [0,max]；posToVal 在 valOf 中实现
      private static const SPEC:Array = [
         ["ricochet",     "跳弹技能",     "check",  0,   0,   ""],
         ["dropRate",     "下坠速率",     "slider", 0,  30,   "0.1步进 0-3"],
         ["wallHits",     "撞墙次数",     "slider", 0,   5,   "0=撞墙即爆"],
         ["muzzleVel",    "初速度",       "slider", 0,  90,   "10-100"],
         ["bounce",       "反弹力度",     "slider", 0,  10,   "0.1步进 0-1"],
         ["aimSkill",     "蹲/梯举枪",    "check",  0,   0,   "Shift+W"],
         ["projHits",     "手雷击落",     "check",  0,   0,   ""],
         ["projHp",       "投掷物血量",   "slider", 0, 199,   "步进5"],
         ["projArmor",    "投掷物护甲",   "slider", 0, 100,   "步进5"],
         ["swapRun",      "疾跑切枪",     "check",  0,   0,   "Shift+数字键"],
         ["spreadFix",    "散布恒定",     "check",  0,   0,   "仅榴弹炮"],
         ["dashKeepPose", "冲刺保持蹲/趴", "check", 0,   0,   "魔法冲刺"]
      ];

      public function MSWPipTab(m:*)
      {
         mod = m;
      }

      public function isActive():Boolean
      {
         return panelOpen;
      }

      // ---------------- 每帧 ----------------

      public function update(w:*):void
      {
         try
         {
            if(w == null) return;
            var pip:* = w["pip"];
            if(pip == null) return;
            if(qname(pip["currentPage"]) != "fe.inter::PipPageOpt")
            {
               if(panelOpen) close(pip);
               return;
            }
            var ov:* = findOptVis(w);
            if(ov == null) return;
            ensureBuilt(ov);
            if(panelOpen)
            {
               if(pip["active"] != true)
               {
                  close(pip);
                  return;
               }
               enforce(ov);
            }
         }
         catch(e:*)
         {
            mod.cfg.diagSet("lastErr", "pipTab:" + e);
         }
      }

      /** F6 入口：任意子页直接跳 Opt 页并展开/收起本面板。 */
      public function toggle(w:*):void
      {
         try
         {
            var pip:* = w["pip"];
            if(pip == null || pip["active"] != true) return;
            if(!guardOk(w)) return;
            if(qname(pip["currentPage"]) != "fe.inter::PipPageOpt")
            {
               pip["onoff"](5); // public：切到 Opt 页（同步 setPage/setStatus）
            }
            var ov:* = findOptVis(w);
            if(ov == null) return;
            ensureBuilt(ov);
            if(panelOpen) close(pip);
            else open(ov, pip);
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabToggle:" + err);
         }
      }

      // ---------------- 定位 Opt 页视觉 ----------------

      /** 页面视觉固定在 vpip 内 (165,72) 且当前可见的那一个（setStatus 单页可见）。 */
      private function findOptVis(w:*):*
      {
         var vpip:* = w["vpip"];
         if(vpip == null) return null;
         var n:int = vpip["numChildren"];
         for(var i:int = 0; i < n; i++)
         {
            var c:* = vpip["getChildAt"](i);
            if(c == myBut || c == head || isMine(c)) continue;
            if(c["visible"] != true) continue;
            if(c["x"] != 165 || c["y"] != 72) continue;
            var q:String = getQualifiedClassName(c);
            if(q != null && q.indexOf("visPip") >= 0) return c;
         }
         return null;
      }

      private function isMine(c:*):Boolean
      {
         if(rows != null)
         {
            for(var i:int = 0; i < rows.length; i++)
            {
               if(rows[i] === c) return true;
            }
         }
         return false;
      }

      private function qname(o:*):String
      {
         try
         {
            return getQualifiedClassName(o);
         }
         catch(e:*)
         {
         }
         return "";
      }

      // ---------------- 构建 ----------------

      private function ensureBuilt(ov:*):void
      {
         if(built) return;
         var b5:* = ov["getChildByName"]("but5");
         if(b5 == null) return;
         var cls:Class = getDefinitionByName(getQualifiedClassName(b5)) as Class;
         if(cls != null)
         {
            var t:* = new cls();
            t["mouseChildren"] = false;
            t["id"]["visible"] = false;
            t["id"]["text"] = "msw";
            var lt:* = t["text"];
            try
            {
               var fmt:TextFormat = lt["getTextFormat"](); // 与原版子按钮同款字体
               lt["defaultTextFormat"] = fmt;
            }
            catch(e1:*)
            {
               try
               {
                  var f2:TextFormat = new TextFormat();
                  f2.font = "SimHei";
                  f2.size = 13;
                  lt["defaultTextFormat"] = f2;
               }
               catch(e2:*)
               {
               }
            }
            lt["text"] = "模组";
            t["x"] = b5["x"] + b5["width"] + 2;
            t["y"] = b5["y"];
            t.addEventListener(MouseEvent.CLICK, onButClick);
            ov["addChild"](t);
            myBut = t;
         }
         // 子按钮/主页签的点击 = 离开模组面板（游戏处理器先跑）
         for(var i:int = 1; i <= 5; i++)
         {
            var b:* = ov["getChildByName"]("but" + i);
            if(b != null) b.addEventListener(MouseEvent.CLICK, onLeaveClick);
         }
         var vpip:* = modMainVpip();
         for(var j:int = 0; j <= 5; j++)
         {
            var mb:* = vpip == null ? null : vpip["getChildByName"]("but" + j);
            if(mb != null) mb.addEventListener(MouseEvent.CLICK, onLeaveClick);
         }
         buildRows(ov);
         built = true;
         mod.cfg.diagAdd("tabBuild");
      }

      private var cachedVpip:* = null;

      private function modMainVpip():*
      {
         if(cachedVpip != null) return cachedVpip;
         try
         {
            var w:* = MSWU.world();
            if(w != null) cachedVpip = w["vpip"];
         }
         catch(e:*)
         {
         }
         return cachedVpip;
      }

      private function buildRows(ov:*):void
      {
         var itemCls:Class = getDefinitionByName("visPipOptItem") as Class;
         if(itemCls == null) return;
         // 标题行（仿 statHead：带 back 背景）
         head = new itemCls();
         initRow(head);
         try
         {
            head["back"]["visible"] = true;
         }
         catch(e0:*)
         {
         }
         head["x"] = 30;
         head["y"] = 70;
         head["nazv"]["text"] = "模组设置  MoreSkills&Weapons";
         ov["addChild"](head);
         rows = [];
         for(var i:int = 0; i < SPEC.length; i++)
         {
            var r:* = new itemCls();
            initRow(r);
            r["x"] = 30;
            r["y"] = 100 + i * 30;
            var key:String = SPEC[i][0];
            r["nazv"]["text"] = SPEC[i][1];
            r["mswKey"] = key;
            r["mswHint"] = SPEC[i][5];
            if(SPEC[i][2] == "check")
            {
               var cb:* = r["check"];
               cb["visible"] = true;
               cb["selected"] = mod.cfg[key] == true;
               cb["addEventListener"]("change", onCheck);
            }
            else
            {
               var sc:* = r["scr"];
               sc["visible"] = true;
               sc["minScrollPosition"] = SPEC[i][3];
               sc["maxScrollPosition"] = SPEC[i][4];
               sc["scrollPosition"] = posOf(key);
               sc["addEventListener"]("scroll", onScroll);
               r["numb"]["text"] = valText(key);
            }
            ov["addChild"](r);
            rows[rows.length] = r;
         }
         setRowsVisible(false);
      }

      /** 对齐 PipPageOpt.setStatItem 的行初始化：只留需要的子件。 */
      private function initRow(r:*):void
      {
         try
         {
            var st:* = getDefinitionByName("fe.inter::PipPage") as Class;
            st["setStyle"](r["nazv"]); // 原版 pip 文本样式
         }
         catch(e:*)
         {
         }
         r["id"]["visible"] = false;
         r["scr"]["visible"] = false;
         r["check"]["visible"] = false;
         r["key1"]["visible"] = false;
         r["key2"]["visible"] = false;
         r["ramka"]["visible"] = false;
         r["land"]["text"] = "";
         r["ggName"]["text"] = "";
         r["numb"]["text"] = "";
      }

      // ---------------- 值换算 ----------------

      /** 配置值 → 滑块刻度。 */
      private function posOf(key:String):Number
      {
         var v:* = mod.cfg[key];
         if(key == "dropRate") return Math.round(Number(v) * 10);
         if(key == "bounce") return Math.round(Number(v) * 10);
         if(key == "muzzleVel") return Number(v) - 10;
         if(key == "projHp") return (Number(v) - 1) / 5;
         if(key == "projArmor") return Number(v) / 5;
         return Number(v); // wallHits
      }

      /** 滑块刻度 → 配置值。 */
      private function valOf(key:String, pos:Number):*
      {
         if(key == "dropRate") return Math.round(pos) / 10;
         if(key == "bounce") return Math.round(pos) / 10;
         if(key == "muzzleVel") return Math.round(pos) + 10;
         if(key == "projHp") return 1 + Math.round(pos) * 5;
         if(key == "projArmor") return Math.round(pos) * 5;
         return Math.round(pos); // wallHits
      }

      private function valText(key:String):String
      {
         var v:* = mod.cfg[key];
         if(key == "dropRate" || key == "bounce") return Number(v).toFixed(1);
         return "" + v;
      }

      // ---------------- 控件事件 ----------------

      private function onCheck(e:*):void
      {
         try
         {
            var cb:* = e["currentTarget"];
            var row:* = cb["parent"];
            var key:String = row["mswKey"];
            mod.cfg[key] = cb["selected"] == true;
            mod.cfg.clamp();
            mod.cfg.save(); // 离散开关，即时落盘
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabCheck:" + err);
         }
      }

      private function onScroll(e:*):void
      {
         try
         {
            var sc:* = e["currentTarget"];
            var row:* = sc["parent"];
            var key:String = row["mswKey"];
            mod.cfg[key] = valOf(key, Number(sc["scrollPosition"]));
            mod.cfg.clamp();
            row["numb"]["text"] = valText(key) + (row["mswHint"] != "" ? "  " + row["mswHint"] : "");
            cfgDirty = true; // 拖动期间不落盘（D-035：高频 flush 卡顿），关面板时统一 save
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabScroll:" + err);
         }
      }

      private function guardOk(w:*):Boolean
      {
         try
         {
            var ctr:* = w["ctr"];
            if(ctr != null && ctr["setkeyOn"] == true) return false;
         }
         catch(e:*)
         {
         }
         return true;
      }

      private function onButClick(e:*):void
      {
         try
         {
            var w:* = MSWU.world();
            if(w == null) return;
            var pip:* = w["pip"];
            if(pip == null || pip["active"] != true) return;
            if(!guardOk(w)) return;
            if(panelOpen) close(pip);
            else
            {
               var ov:* = findOptVis(w);
               if(ov != null) open(ov, pip);
            }
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabClick:" + err);
         }
      }

      private function onLeaveClick(e:*):void
      {
         // 游戏 page2Click/pageClick 先执行；这里随后收面板
         try
         {
            if(!panelOpen) return;
            var w:* = MSWU.world();
            if(w == null) return;
            close(w["pip"]);
         }
         catch(err:*)
         {
            mod.cfg.diagSet("lastErr", "tabLeave:" + err);
         }
      }

      // ---------------- 打开 / 关闭 ----------------

      private function open(ov:*, pip:*):void
      {
         panelOpen = true;
         hiddenVis = [];
         suppressGameContent(ov, true);
         // 子按钮高亮全给"模组"（page2 高亮不可读恢复——internal，接受此外观取舍）
         for(var i:int = 1; i <= 5; i++)
         {
            var b:* = ov["getChildByName"]("but" + i);
            if(b != null) b["gotoAndStop"](1);
         }
         myBut["gotoAndStop"](2);
         setRowsVisible(true);
         try
         {
            pip["snd"](2);
         }
         catch(e:*)
         {
         }
         mod.cfg.diagAdd("tabOn");
      }

      private function close(pip:*):void
      {
         panelOpen = false;
         if(myBut != null) myBut["gotoAndStop"](1);
         restoreGameContent();
         setRowsVisible(false);
         if(cfgDirty)
         {
            mod.cfg.clamp();
            mod.cfg.save();
            cfgDirty = false;
         }
         mod.cfg.diagAdd("tabOff");
      }

      /** 隐藏 Opt 页游戏内容（匿名 instance* 子级 + scBar）。record=true 时记录以便恢复。 */
      private function suppressGameContent(ov:*, record:Boolean):void
      {
         var n:int = ov["numChildren"];
         for(var i:int = n - 1; i >= 0; i--)
         {
            var c:* = ov["getChildAt"](i);
            if(c == myBut || c == head || isMine(c)) continue;
            if(isChrome(c)) continue;
            if(c["visible"] != true) continue;
            c["visible"] = false;
            if(record) hiddenVis[hiddenVis.length] = c;
         }
         var sc:* = ov["getChildByName"]("scBar");
         if(sc != null && sc["visible"] == true)
         {
            sc["visible"] = false;
            if(record) hiddenVis[hiddenVis.length] = sc;
         }
      }

      /** 每帧压制：游戏 setStatItems 会把行复显，这里再压回去。 */
      private function enforce(ov:*):void
      {
         suppressGameContent(ov, false);
         setRowsVisible(true);
      }

      private function restoreGameContent():void
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

      /** 具名子件（butN/scBar/butOk/butDef/pers/skill/cats/info/bottext…）是 chrome。 */
      private function isChrome(c:*):Boolean
      {
         try
         {
            var nm:String = c["name"];
            if(nm != null && nm != "" && nm.indexOf("instance") != 0) return true;
         }
         catch(e:*)
         {
            return true;
         }
         return false;
      }

      private function setRowsVisible(v:Boolean):void
      {
         if(head != null) head["visible"] = v;
         if(rows != null)
         {
            for(var i:int = 0; i < rows.length; i++)
            {
               rows[i]["visible"] = v;
            }
         }
      }
   }
}
