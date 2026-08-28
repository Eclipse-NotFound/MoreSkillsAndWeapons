package
{
   import flash.events.MouseEvent;
   import flash.text.TextFormat;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;

   /**
    * 哔哔小马"模组"子页按钮 + 原版控件设置面板（v2.1，加固版）。
    *
    * 机制与 v2 相同（见 decisions D-046 v2），v2.1 加固（2026-08-28 实机
    * `pipTab:TypeError #1010` 排查）：
    * - 行类不再 getDefinitionByName 硬查符号名，而是**克隆 Opt 页现成的游戏行**
    *   （页面内容行的类就是 visPipOptItem，克隆其 constructor 类必然可得）；
    * - 所有子件访问 null 安全（缺子件跳过该子件而不是 #1010）；
    * - 行构建失败时回退 v1 式 pip 绿文字面板（保证"至少能看到设置"）；
    * - update 各阶段独立 try/catch，lastErr 带阶段前缀 + getStackTrace 落 SOL，
    *   关键状态快照存 diag（tabStage/tabSnap），实机问题可离线诊断。
    */
   public class MSWPipTab
   {
      private var mod:*;

      private var built:Boolean = false;
      private var myBut:* = null;          // "模组"子按钮（克隆 Opt 子按钮类）
      private var head:* = null;           // 标题行
      private var rows:Array = null;       // 设置行（visPipOptItem 克隆）
      private var rowsOk:Boolean = false;  // 行构建是否成功（失败则用文字兜底）
      private var fbTf:TextField = null;   // 文字兜底面板
      private var panelOpen:Boolean = false;
      private var hiddenVis:Array = null;
      private var cfgDirty:Boolean = false;
      private var cachedVpip:* = null;

      private static const SPEC:Array = [
         ["ricochet",     "跳弹技能",      "check",  0,   0,   ""],
         ["dropRate",     "下坠速率",      "slider", 0,  30,   "0.1步进 0-3"],
         ["wallHits",     "撞墙次数",      "slider", 0,   5,   "0=撞墙即爆"],
         ["muzzleVel",    "初速度",        "slider", 0,  90,   "10-100"],
         ["bounce",       "反弹力度",      "slider", 0,  10,   "0.1步进 0-1"],
         ["aimSkill",     "蹲/梯举枪",     "check",  0,   0,   "Shift+W"],
         ["projHits",     "手雷击落",      "check",  0,   0,   ""],
         ["projHp",       "投掷物血量",    "slider", 0, 199,   "步进5"],
         ["projArmor",    "投掷物护甲",    "slider", 0, 100,   "步进5"],
         ["swapRun",      "疾跑切枪",      "check",  0,   0,   "Shift+数字键"],
         ["spreadFix",    "散布恒定",      "check",  0,   0,   "仅榴弹炮"],
         ["dashKeepPose", "冲刺保持蹲/趴", "check",  0,   0,   "魔法冲刺"]
      ];

      public function MSWPipTab(m:*)
      {
         mod = m;
      }

      public function isActive():Boolean
      {
         return panelOpen;
      }

      // ---------------- 诊断 ----------------

      private function err(prefix:String, e:*):void
      {
         mod.cfg.diagSet("lastErr", prefix + ":" + e);
         try
         {
            var st:String = e["getStackTrace"]();
            if(st != null) mod.cfg.diagSet("tabTrace", st.substr(0, 400));
         }
         catch(e2:*)
         {
         }
      }

      private function snap():void
      {
         try
         {
            mod.cfg.diagSet("tabSnap", "but=" + (myBut == null ? "null" : myBut["x"] + "," + myBut["y"] + ",v" + myBut["visible"] + ",p" + (myBut["parent"] != null)) +
               " rows=" + (rows == null ? "null" : rows.length) +
               " rowsOk=" + rowsOk + " open=" + panelOpen);
         }
         catch(e:*)
         {
         }
      }

      // ---------------- 每帧 ----------------

      public function update(w:*):void
      {
         var pip:* = null;
         try
         {
            if(w == null) return;
            pip = w["pip"];
            if(pip == null) return;
         }
         catch(e0:*)
         {
            err("pipTab.stage0", e0);
            return;
         }
         var onOpt:Boolean = false;
         try
         {
            onOpt = qname(pip["currentPage"]) == "fe.inter::PipPageOpt";
         }
         catch(e1:*)
         {
            err("pipTab.stage1", e1);
            return;
         }
         if(!onOpt)
         {
            if(panelOpen)
            {
               try
               {
                  close(pip);
               }
               catch(e2:*)
               {
                  err("pipTab.stage2", e2);
               }
            }
            return;
         }
         var ov:* = null;
         try
         {
            ov = findOptVis(w);
            if(ov == null && !built) probeVpip(w); // 实机诊断：为何找不到页面视觉
         }
         catch(e3:*)
         {
            err("pipTab.stage3", e3);
            return;
         }
         if(ov == null) return;
         try
         {
            ensureBuilt(ov);
         }
         catch(e4:*)
         {
            err("pipTab.stage4", e4);
            snap();
            return;
         }
         if(!panelOpen) return;
         try
         {
            if(pip["active"] != true)
            {
               close(pip);
               return;
            }
            enforce(ov);
         }
         catch(e5:*)
         {
            err("pipTab.stage5", e5);
            snap();
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
               pip["onoff"](5);
            }
            var ov:* = findOptVis(w);
            if(ov == null) return;
            ensureBuilt(ov);
            if(panelOpen) close(pip);
            else open(ov, pip);
         }
         catch(err2:*)
         {
            err("tabToggle", err2);
            snap();
         }
      }

      // ---------------- 定位 Opt 页视觉 ----------------

      private function findOptVis(w:*):*
      {
         var vpip:* = w["vpip"];
         if(vpip == null) return null;
         var n:int = vpip["numChildren"];
         for(var i:int = 0; i < n; i++)
         {
            var c:* = vpip["getChildAt"](i);
            if(c == myBut || c == head || c == fbTf || isMine(c)) continue;
            if(c["visible"] != true) continue;
            // 页面视觉的可靠特征：内部有子页按钮 but1..but5（具名子件），
            // 与类名/坐标无关（汉化补丁重命名了 UI 类：实测为 ButPage_1536 系）
            try
            {
               if(c["getChildByName"]("but1") == null) continue;
               if(c["getChildByName"]("but5") == null) continue;
            }
            catch(eb:*)
            {
               continue;
            }
            return c;
         }
         return null;
      }

      /** 诊断：在 Opt 页却找不到页面视觉时，把 vpip 子级清单写进 SOL（一次性覆盖写）。 */
      private function probeVpip(w:*):void
      {
         try
         {
            if(mod.cfg.diag["tabProbe"] != null) return; // 只记首次
         }
         catch(e0:*)
         {
         }
         try
         {
            var vpip:* = w["vpip"];
            if(vpip == null)
            {
               mod.cfg.diagSet("tabProbe", "vpip=null");
               return;
            }
            var s:String = "n=" + vpip["numChildren"] + " vpipVis=" + vpip["visible"];
            var n:int = vpip["numChildren"];
            for(var i:int = 0; i < n; i++)
            {
               var c:* = vpip["getChildAt"](i);
               var hasSub:String = "";
               try
               {
                  if(c["getChildByName"] != null && c["getChildByName"]("but5") != null) hasSub = "*PAGE";
               }
               catch(e2:*)
               {
               }
               s += " |" + i + qname(c).replace(/^[^:]*::/, "").substr(0, 16) + "@" + Math.round(Number(c["x"])) + "," + Math.round(Number(c["y"])) + "v" + (c["visible"] ? 1 : 0) + hasSub;
            }
            mod.cfg.diagSet("tabProbe", s.substr(0, 790));
         }
         catch(e:*)
         {
            mod.cfg.diagSet("tabProbe", "probeErr:" + e);
         }
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

      private function mainVpip():*
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

      // ---------------- 构建 ----------------

      private function ensureBuilt(ov:*):void
      {
         if(built) return;
         mod.cfg.diagSet("tabStage", "build");
         var b5:* = ov["getChildByName"]("but5");
         if(b5 != null)
         {
            var cls:Class = null;
            try
            {
               cls = getDefinitionByName(getQualifiedClassName(b5)) as Class;
            }
            catch(eb:*)
            {
            }
            if(cls != null)
            {
               var t:* = new cls();
               t["mouseChildren"] = false;
               if(t["id"] != null)
               {
                  t["id"]["visible"] = false;
                  t["id"]["text"] = "msw";
               }
               var lt:* = t["text"];
               if(lt != null)
               {
                  try
                  {
                     lt["defaultTextFormat"] = lt["getTextFormat"]();
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
               }
               t["x"] = b5["x"] + b5["width"] + 2;
               t["y"] = b5["y"];
               t.addEventListener(MouseEvent.CLICK, onButClick);
               ov["addChild"](t);
               myBut = t;
            }
         }
         var vpip:* = mainVpip();
         for(var j:int = 0; j <= 5; j++)
         {
            var mb:* = vpip == null ? null : vpip["getChildByName"]("but" + j);
            if(mb != null) mb.addEventListener(MouseEvent.CLICK, onLeaveClick);
         }
         for(var k:int = 1; k <= 5; k++)
         {
            var ob:* = ov["getChildByName"]("but" + k);
            if(ob != null) ob.addEventListener(MouseEvent.CLICK, onLeaveClick);
         }
         buildRows(ov);
         built = true;
         mod.cfg.diagAdd("tabBuild");
         snap();
      }

      /** 行类来源：优先克隆 Opt 页现成内容行（无名 instance* 子级中带 nazv 子件的）。
       *  汉化补丁可能重命名了符号类（实测按钮类为 ButPage_1536 系），
       *  硬查 visPipOptItem 不可靠。 */
      private function rowDonorClass(ov:*):Class
      {
         var n:int = ov["numChildren"];
         for(var i:int = 0; i < n; i++)
         {
            var c:* = ov["getChildAt"](i);
            if(c == myBut || c == head || c == fbTf) continue;
            if(isChrome(c)) continue;
            try
            {
               if(c["getChildByName"] == null) continue;
               if(c["getChildByName"]("nazv") != null) return c["constructor"] as Class;
            }
            catch(e:*)
            {
            }
         }
         return null;
      }

      private function buildRows(ov:*):void
      {
         var itemCls:Class = rowDonorClass(ov);
         if(itemCls == null)
         {
            try
            {
               itemCls = getDefinitionByName("visPipOptItem") as Class;
            }
            catch(e0:*)
            {
            }
         }
         rows = [];
         if(itemCls != null)
         {
            try
            {
               buildWidgetRows(ov, itemCls);
            }
            catch(er:*)
            {
               err("pipTab.buildRows", er);
               snap();
            }
         }
         if(rows.length < SPEC.length)
         {
            // 兜底：pip 绿文字面板（至少设置可见可用）
            rowsOk = false;
            mod.cfg.diagSet("tabStage", "fallback");
            try
            {
               fbTf = makeFallbackTf();
               ov["addChild"](fbTf);
               fbTf["visible"] = false;
               refreshFallback();
            }
            catch(ef:*)
            {
               err("pipTab.fallback", ef);
            }
         }
         else
         {
            rowsOk = true;
            setRowsVisible(false);
         }
      }

      private function buildWidgetRows(ov:*, itemCls:Class):void
      {
         head = new itemCls();
         initRow(head);
         show(head, "back", true);
         setText(head, "nazv", "模组设置  MoreSkills&Weapons");
         head["x"] = 30;
         head["y"] = 70;
         ov["addChild"](head);
         for(var i:int = 0; i < SPEC.length; i++)
         {
            var r:* = new itemCls();
            initRow(r);
            r["x"] = 30;
            r["y"] = 100 + i * 30;
            var key:String = SPEC[i][0];
            setText(r, "nazv", SPEC[i][1]);
            r["mswKey"] = key;
            r["mswHint"] = SPEC[i][5];
            var cb:* = r["check"];
            var sc:* = r["scr"];
            if(SPEC[i][2] == "check" && cb != null)
            {
               show(r, "check", true);
               cb["selected"] = mod.cfg[key] == true;
               cb["addEventListener"]("change", onCheck);
            }
            else if(SPEC[i][2] == "slider" && sc != null)
            {
               show(r, "scr", true);
               sc["minScrollPosition"] = SPEC[i][3];
               sc["maxScrollPosition"] = SPEC[i][4];
               sc["scrollPosition"] = posOf(key);
               sc["addEventListener"]("scroll", onScroll);
               setText(r, "numb", valText(key));
            }
            ov["addChild"](r);
            rows[rows.length] = r;
         }
      }

      private function initRow(r:*):void
      {
         try
         {
            var st:* = getDefinitionByName("fe.inter::PipPage") as Class;
            if(st != null && r["nazv"] != null) st["setStyle"](r["nazv"]);
         }
         catch(e:*)
         {
         }
         show(r, "id", false);
         show(r, "scr", false);
         show(r, "check", false);
         show(r, "key1", false);
         show(r, "key2", false);
         show(r, "ramka", false);
         setText(r, "land", "");
         setText(r, "ggName", "");
         setText(r, "numb", "");
      }

      private function show(obj:*, name:String, v:Boolean):void
      {
         try
         {
            if(obj[name] != null) obj[name]["visible"] = v;
         }
         catch(e:*)
         {
         }
      }

      private function setText(obj:*, name:String, s:String):void
      {
         try
         {
            if(obj[name] != null) obj[name]["text"] = s;
         }
         catch(e:*)
         {
         }
      }

      // ---------------- 值换算 ----------------

      private function posOf(key:String):Number
      {
         var v:* = mod.cfg[key];
         if(key == "dropRate") return Math.round(Number(v) * 10);
         if(key == "bounce") return Math.round(Number(v) * 10);
         if(key == "muzzleVel") return Number(v) - 10;
         if(key == "projHp") return (Number(v) - 1) / 5;
         if(key == "projArmor") return Number(v) / 5;
         return Number(v);
      }

      private function valOf(key:String, pos:Number):*
      {
         if(key == "dropRate") return Math.round(pos) / 10;
         if(key == "bounce") return Math.round(pos) / 10;
         if(key == "muzzleVel") return Math.round(pos) + 10;
         if(key == "projHp") return 1 + Math.round(pos) * 5;
         if(key == "projArmor") return Math.round(pos) * 5;
         return Math.round(pos);
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
            mod.cfg.save();
         }
         catch(err2:*)
         {
            err("tabCheck", err2);
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
            var hint:String = row["mswHint"] == null ? "" : row["mswHint"];
            setText(row, "numb", valText(key) + (hint != "" ? "  " + hint : ""));
            cfgDirty = true;
         }
         catch(err2:*)
         {
            err("tabScroll", err2);
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
         catch(err2:*)
         {
            err("tabClick", err2);
            snap();
         }
      }

      private function onLeaveClick(e:*):void
      {
         try
         {
            if(!panelOpen) return;
            var w:* = MSWU.world();
            if(w == null) return;
            close(w["pip"]);
         }
         catch(err2:*)
         {
            err("tabLeave", err2);
         }
      }

      // ---------------- 打开 / 关闭 ----------------

      private function open(ov:*, pip:*):void
      {
         panelOpen = true;
         hiddenVis = [];
         suppressGameContent(ov, true);
         for(var i:int = 1; i <= 5; i++)
         {
            var b:* = ov["getChildByName"]("but" + i);
            if(b != null) b["gotoAndStop"](1);
         }
         if(myBut != null) myBut["gotoAndStop"](2);
         if(rowsOk) setRowsVisible(true);
         else if(fbTf != null)
         {
            refreshFallback();
            fbTf["visible"] = true;
         }
         try
         {
            pip["snd"](2);
         }
         catch(e:*)
         {
         }
         mod.cfg.diagAdd("tabOn");
         snap();
      }

      private function close(pip:*):void
      {
         panelOpen = false;
         if(myBut != null) myBut["gotoAndStop"](1);
         if(hiddenVis != null)
         {
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
         if(rowsOk) setRowsVisible(false);
         else if(fbTf != null) fbTf["visible"] = false;
         if(cfgDirty)
         {
            mod.cfg.clamp();
            mod.cfg.save();
            cfgDirty = false;
         }
         mod.cfg.diagAdd("tabOff");
      }

      private function suppressGameContent(ov:*, record:Boolean):void
      {
         var n:int = ov["numChildren"];
         for(var i:int = n - 1; i >= 0; i--)
         {
            var c:* = ov["getChildAt"](i);
            if(c == myBut || c == head || c == fbTf || isMine(c)) continue;
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

      private function enforce(ov:*):void
      {
         suppressGameContent(ov, false);
         if(rowsOk) setRowsVisible(true);
         else if(fbTf != null) fbTf["visible"] = true;
      }

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

      // ---------------- 文字兜底 ----------------

      private function makeFallbackTf():TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         fmt.font = "SimHei";
         fmt.size = 15;
         fmt.color = 0x00FF99;
         tf.defaultTextFormat = fmt;
         tf.multiline = true;
         tf.wordWrap = false;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.autoSize = TextFieldAutoSize.LEFT;
         return tf;
      }

      private function refreshFallback():void
      {
         if(fbTf == null) return;
         var c:* = mod.cfg;
         var s:String = "";
         s += MSWWeapon.WEAPON_NAME + " 模组设置\n";
         s += "--------------------------------\n";
         s += "跳弹技能 : " + (c.ricochet ? "开" : "关") + "\n";
         s += "下坠速率 : " + c.dropRate.toFixed(1) + "  (0-3)\n";
         s += "撞墙次数 : " + c.wallHits + "  (0=撞墙即爆)\n";
         s += "初速度   : " + c.muzzleVel + "  (10-100)\n";
         s += "反弹力度 : " + c.bounce.toFixed(1) + "  (0-1)\n";
         s += "蹲/梯举枪 : " + (c.aimSkill ? "开" : "关") + "\n";
         s += "手雷击落 : " + (c.projHits ? "开" : "关") + "\n";
         s += "投掷物血量 : " + c.projHp + "\n";
         s += "投掷物护甲 : " + c.projArmor + "\n";
         s += "疾跑切枪 : " + (c.swapRun ? "开" : "关") + "\n";
         s += "散布恒定 : " + (c.spreadFix ? "开" : "关") + "\n";
         s += "冲刺保持蹲/趴 : " + (c.dashKeepPose ? "开" : "关") + "\n";
         s += "(控件行初始化失败，此为文字兜底；数值用 F6 浮层调整)";
         fbTf["text"] = s;
      }
   }
}
