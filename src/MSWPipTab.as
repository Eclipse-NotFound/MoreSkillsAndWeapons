package
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.geom.Point;
   import flash.utils.getDefinitionByName;

   /**
    * 哔哔小马"模组"子页按钮 + 设置面板（v1.2.5，全自绘控件）。
    *
    * 教训链（decisions D-046）：汉化补丁把游戏 UI 符号类改名（ButPage_1536），
    * 且 new 其类得到的是零尺寸空壳（美术靠运行时初始化）——**克隆游戏类不可行**。
    * v1.2.5 改为：
    * - 按钮自绘（绿框深底 + SimHei 文字，两态高亮），尺寸取自 but5 实测宽高；
    * - 控件行自绘容器 + fl.controls.CheckBox / fl.controls.ScrollBar（原版
    *   选项页的组件类，自带程序化皮肤，反编译确认在 SWF 内，同域可实例化）；
    * - 组件类不可用时退化为手绘开关/步进按钮；
    * - 页面视觉按结构特征定位（含具名 but1/but5 的可见子级，与类名坐标无关）；
    * - 全链路 null 安全 + 分阶段诊断（pipTab.stageN/tabStage/tabSnap/tabProbe）。
    */
   public class MSWPipTab
   {
      private var mod:*;

      private var built:Boolean = false;
      private var myBut:Sprite = null;     // "模组"按钮（自绘）
      private var myButHi:Sprite = null;   // 高亮层（显示 = 高亮态）
      private var head:* = null;           // 标题 TextField
      private var rows:Array = null;       // 设置行容器（Sprite）
      private var rowsOk:Boolean = false;
      private var panelOpen:Boolean = false;
      private var hiddenVis:Array = null;
      private var cfgDirty:Boolean = false;
      private var cachedVpip:* = null;
      private var helpTf:TextField = null;

      private static const HELP_DEFAULT:String = "鼠标悬停某行可查看说明。";

      // key / 标签 / "check"|"slider" / 滑块最小刻度 / 最大刻度 / 提示
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

      /** 自动测试用：对按钮派发真实 CLICK（走 onButClick 完整路径）。 */
      public function debugClick():void
      {
         if(myBut == null) return;
         myBut.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
      }

      /** 自动测试用：强制挪按钮位置做渲染判别实验。 */
      public function debugPlace(x:Number, y:Number):void
      {
         if(myBut == null) return;
         myBut["x"] = x;
         myBut["y"] = y;
         snap();
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
            var s:String = "but=" + (myBut == null ? "null" : myBut["x"] + "," + myBut["y"] + ",v" + myBut["visible"]) +
               " rows=" + (rows == null ? "null" : rows.length) +
               " rowsOk=" + rowsOk + " open=" + panelOpen;
            try
            {
               var pt:* = new flash.geom.Point(myBut["x"], myBut["y"]);
               pt = myBut["localToGlobal"](pt);
               s += " g=" + int(pt["x"]) + "," + int(pt["y"]);
            }
            catch(e1:*)
            {
            }
            try
            {
               s += " wh=" + int(myBut["width"]) + "x" + int(myBut["height"]);
            }
            catch(e1b:*)
            {
            }
            try
            {
               var ov:* = myBut == null ? null : myBut["parent"];
               if(ov != null) s += " sr=" + ov["scrollRect"] + " mask=" + (ov["mask"] != null);
            }
            catch(e2:*)
            {
            }
            mod.cfg.diagSet("tabSnap", s);
         }
         catch(e:*)
         {
         }
      }

      private function qname(o:*):String
      {
         try
         {
            return flash.utils.getQualifiedClassName(o);
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
            if(ov == null && !built) probeVpip(w);
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
            if(c == myBut || c == head || isMine(c)) continue;
            if(c["visible"] != true) continue;
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

      /** 诊断：在 Opt 页却找不到页面视觉时，把 vpip 子级清单写进 SOL。 */
      private function probeVpip(w:*):void
      {
         try
         {
            if(mod.cfg.diag["tabProbe"] != null) return;
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

      // ---------------- 自绘按钮 ----------------

      private static const COL_BORDER:int = 0x1E8C5A;
      private static const COL_BORDER_HI:int = 0x00FF99;
      private static const COL_FILL:int = 0x03170E;
      private static const COL_FILL_HI:int = 0x0A3A24;

      private function drawButtonFace(g:*, w:Number, h:Number, hi:Boolean):void
      {
         g.clear();
         g.beginFill(hi ? COL_FILL_HI : COL_FILL, 0.92);
         g.lineStyle(2, hi ? COL_BORDER_HI : COL_BORDER, 1);
         g.drawRect(0, 0, w, h);
         g.endFill();
      }

      private function makeLabel(text:String, size:int, color:int):TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         fmt.font = "SimHei";
         fmt.size = size;
         fmt.color = color;
         tf.defaultTextFormat = fmt;
         tf.text = text;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.autoSize = TextFieldAutoSize.LEFT;
         return tf;
      }

      // ---------------- 构建 ----------------

      private function ensureBuilt(ov:*):void
      {
         if(built) return;
         mod.cfg.diagSet("tabStage", "build");
         var b5:* = ov["getChildByName"]("but5");
         var bw:Number = 120;
         var bh:Number = 34;
         if(b5 != null)
         {
            try
            {
               if(Number(b5["width"]) > 40) bw = Number(b5["width"]);
               if(Number(b5["height"]) > 14) bh = Number(b5["height"]);
            }
            catch(e0:*)
            {
            }
         }
         myBut = new Sprite();
         myButHi = new Sprite();
         drawButtonFace(myButHi["graphics"], bw, bh, true);
         drawButtonFace(myBut["graphics"], bw, bh, false);
         myButHi["visible"] = false;
         var lt:TextField = makeLabel("模组", 15, 0xE8FFE8);
         lt["x"] = (bw - lt["width"]) / 2;
         lt["y"] = (bh - lt["height"]) / 2;
         myBut["addChild"](myButHi);
         myBut["addChild"](lt);
         myBut["mouseChildren"] = false;
         myBut["buttonMode"] = true;
         if(b5 != null)
         {
            myBut["x"] = Number(b5["x"]) + bw + 2;
            myBut["y"] = Number(b5["y"]);
         }
         else
         {
            myBut["x"] = 30;
            myBut["y"] = 40;
         }
         myBut.addEventListener(MouseEvent.CLICK, onButClick);
         ov["addChild"](myBut);
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

      private function buildRows(ov:*):void
      {
         // 右侧帮助栏（对齐原版：行悬停说明显示在此处）
         head = makeLabel(MSWWeapon.WEAPON_NAME + " 模组设置", 16, 0x00FF99);
         head["x"] = 600;
         head["y"] = 104;
         head["visible"] = false;
         ov["addChild"](head);
         helpTf = makeLabel(HELP_DEFAULT, 13, 0x9FE8C8);
         helpTf["x"] = 600;
         helpTf["y"] = 134;
         helpTf["width"] = 230;
         helpTf["wordWrap"] = true;
         helpTf["autoSize"] = TextFieldAutoSize.NONE;
         helpTf["height"] = 300;
         helpTf["visible"] = false;
         ov["addChild"](helpTf);
         rows = [];
         for(var i:int = 0; i < SPEC.length; i++)
         {
            var r:MovieClip = new MovieClip();
            r["x"] = 30;
            r["y"] = 100 + i * 30;
            var bg:Sprite = new Sprite();
            bg["graphics"].beginFill(0x000000, 1);
            bg["graphics"].lineStyle(1, 0x0F4A2E, 1);
            bg["graphics"].drawRect(0, 0, 550, 24);
            bg["graphics"].endFill();
            bg["mouseEnabled"] = false;
            r["addChild"](bg);
            var key:String = SPEC[i][0];
            var lt:TextField = makeLabel(SPEC[i][1], 14, 0xD8FFE8);
            lt["x"] = 10;
            lt["y"] = 3;
            r["addChild"](lt);
            r["mswKey"] = key;
            r["mswHint"] = SPEC[i][5];
            r.addEventListener(MouseEvent.MOUSE_OVER, onRowHover);
            r.addEventListener(MouseEvent.MOUSE_OUT, onRowOut);
            if(SPEC[i][2] == "check") buildCheck(r, key);
            else buildSlider(r, key, SPEC[i][3], SPEC[i][4]);
            r["visible"] = false;
            ov["addChild"](r);
            rows[rows.length] = r;
         }
         rowsOk = rows.length == SPEC.length;
         setRowsVisible(false);
      }

      private function buildCheck(r:Sprite, key:String):void
      {
         var cb:* = null;
         try
         {
            var cls:Class = getDefinitionByName("fl.controls::CheckBox") as Class;
            if(cls != null) cb = new cls();
         }
         catch(e0:*)
         {
         }
         if(cb != null)
         {
            cb["selected"] = mod.cfg[key] == true;
            cb["x"] = 360;
            cb["y"] = 2;
            cb["addEventListener"]("change", onCheck);
            r["addChild"](cb);
         }
         else
         {
            // 手绘开关（组件不可用时）
            var box:MovieClip = new MovieClip();
            drawToggle(box, mod.cfg[key] == true);
            box["x"] = 365;
            box["y"] = 2;
            box["buttonMode"] = true;
            box["mswKey"] = key;
            box.addEventListener(MouseEvent.CLICK, onHandToggle);
            r["addChild"](box);
         }
      }

      private function drawToggle(box:Sprite, on:Boolean):void
      {
         box["graphics"].clear();
         box["graphics"].lineStyle(2, on ? COL_BORDER_HI : COL_BORDER, 1);
         box["graphics"].beginFill(on ? COL_FILL_HI : COL_FILL, 1);
         box["graphics"].drawRect(0, 0, 20, 20);
         box["graphics"].endFill();
         if(on)
         {
            box["graphics"].lineStyle(3, 0x00FF99, 1);
            box["graphics"].moveTo(4, 10);
            box["graphics"].lineTo(9, 15);
            box["graphics"].lineTo(16, 5);
         }
      }

      private function buildSlider(r:Sprite, key:String, min:Number, max:Number):void
      {
         var sc:* = null;
         try
         {
            var cls:Class = getDefinitionByName("fl.controls::ScrollBar") as Class;
            if(cls != null) sc = new cls();
         }
         catch(e0:*)
         {
         }
         var numb:TextField = makeLabel(valText(key), 13, 0xE8FFE8);
         numb["x"] = 505;
         numb["y"] = 4;
         r["addChild"](numb);
         r["mswNumb"] = numb;
         if(sc != null)
         {
            sc["direction"] = "horizontal";
            sc["width"] = 240;
            sc["height"] = 14;
            sc["x"] = 256;
            sc["y"] = 5;
            sc["minScrollPosition"] = min;
            sc["maxScrollPosition"] = max;
            sc["scrollPosition"] = posOf(key);
            sc["addEventListener"]("scroll", onScroll);
            r["addChild"](sc);
         }
         else
         {
            // 手绘步进：◀ ▶
            var less:Sprite = miniBtn("◀", 256);
            var more:Sprite = miniBtn("▶", 445);
            less["mswKey"] = key;
            more["mswKey"] = key;
            less["mswDir"] = -1;
            more["mswDir"] = 1;
            less.addEventListener(MouseEvent.CLICK, onStep);
            more.addEventListener(MouseEvent.CLICK, onStep);
            r["addChild"](less);
            r["addChild"](more);
         }
      }

      private function miniBtn(txt:String, x:Number):MovieClip
      {
         var s:MovieClip = new MovieClip();
         drawButtonFace(s["graphics"], 40, 20, false);
         var lt:TextField = makeLabel(txt, 12, 0xE8FFE8);
         lt["x"] = (40 - lt["width"]) / 2;
         lt["y"] = 2;
         s["addChild"](lt);
         s["x"] = x;
         s["y"] = 4;
         s["buttonMode"] = true;
         return s;
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

      private function rowOf(o:*):*
      {
         while(o != null)
         {
            if(o["mswKey"] != null) return o;
            o = o["parent"];
         }
         return null;
      }

      private function onCheck(e:*):void
      {
         try
         {
            var cb:* = e["currentTarget"];
            var row:* = rowOf(cb);
            if(row == null) return;
            mod.cfg[row["mswKey"]] = cb["selected"] == true;
            mod.cfg.clamp();
            mod.cfg.save();
         }
         catch(err2:*)
         {
            err("tabCheck", err2);
         }
      }

      private function onHandToggle(e:*):void
      {
         try
         {
            var box:* = e["currentTarget"];
            var row:* = rowOf(box);
            if(row == null) return;
            var key:String = row["mswKey"];
            mod.cfg[key] = !(mod.cfg[key] == true);
            mod.cfg.clamp();
            mod.cfg.save();
            drawToggle(box, mod.cfg[key] == true);
         }
         catch(err2:*)
         {
            err("tabToggleBox", err2);
         }
      }

      private function onRowHover(e:*):void
      {
         try
         {
            var row:* = rowOf(e["currentTarget"]);
            if(row == null) return;
            var hint:String = row["mswHint"] == null ? "" : row["mswHint"];
            var lb:String = "";
            for(var i:int = 0; i < SPEC.length; i++)
            {
               if(SPEC[i][0] == row["mswKey"]) lb = SPEC[i][1];
            }
            if(helpTf != null) helpTf["text"] = lb + (hint != "" ? "：\n" + hint : "");
         }
         catch(e:*)
         {
         }
      }

      private function onRowOut(e:*):void
      {
         try
         {
            if(helpTf != null) helpTf["text"] = HELP_DEFAULT;
         }
         catch(e:*)
         {
         }
      }

      private function onScroll(e:*):void
      {
         try
         {
            var sc:* = e["currentTarget"];
            var row:* = rowOf(sc);
            if(row == null) return;
            var key:String = row["mswKey"];
            mod.cfg[key] = valOf(key, Number(sc["scrollPosition"]));
            mod.cfg.clamp();
            row["mswNumb"]["text"] = valText(key);
            cfgDirty = true; // 拖动期间不落盘（D-035），关面板统一 save
         }
         catch(err2:*)
         {
            err("tabScroll", err2);
         }
      }

      private function onStep(e:*):void
      {
         try
         {
            var btn:* = e["currentTarget"];
            var row:* = rowOf(btn);
            if(row == null) return;
            var key:String = row["mswKey"];
            var d:Number = Number(btn["mswDir"]);
            if(key == "dropRate" || key == "bounce") mod.cfg[key] = Number(mod.cfg[key]) + d * 0.1;
            else if(key == "muzzleVel") mod.cfg[key] = Number(mod.cfg[key]) + d * 5;
            else if(key == "projHp" || key == "projArmor") mod.cfg[key] = Number(mod.cfg[key]) + d * 5;
            else mod.cfg[key] = Number(mod.cfg[key]) + d;
            mod.cfg.clamp();
            mod.cfg.save();
            var hint:String = row["mswHint"] == null ? "" : row["mswHint"];
            row["mswNumb"]["text"] = valText(key) + (hint != "" ? "  " + hint : "");
         }
         catch(err2:*)
         {
            err("tabStep", err2);
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
         if(myBut != null) myButHi["visible"] = true;
         setRowsVisible(true);
         if(helpTf != null)
         {
            helpTf["text"] = HELP_DEFAULT;
            helpTf["visible"] = true;
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
         if(myBut != null) myButHi["visible"] = false;
         setRowsVisible(false);
         if(helpTf != null) helpTf["visible"] = false;
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
         setRowsVisible(false);
         if(cfgDirty)
         {
            mod.cfg.clamp();
            mod.cfg.save();
            cfgDirty = false;
         }
         mod.cfg.diagAdd("tabOff");
      }

      /** 面板打开时页面只保留子按钮（but1..5）+ 模组内容——对齐原版选项页
       *  （pers/存档信息/记录文本等一概让位）。 */
      private function suppressGameContent(ov:*, record:Boolean):void
      {
         var n:int = ov["numChildren"];
         for(var i:int = n - 1; i >= 0; i--)
         {
            var c:* = ov["getChildAt"](i);
            if(c == myBut || c == head || c == helpTf || isMine(c)) continue;
            var nm:String = "";
            try
            {
               nm = c["name"];
            }
            catch(en:*)
            {
            }
            if(nm != null && nm.length == 4 && nm.indexOf("but") == 0) continue; // 子按钮
            if(c["visible"] != true) continue;
            c["visible"] = false;
            if(record) hiddenVis[hiddenVis.length] = c;
         }
      }

      private function enforce(ov:*):void
      {
         suppressGameContent(ov, false);
         setRowsVisible(true);
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
   }
}
