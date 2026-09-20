package
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;

   /**
    * 哔哔小马"模组"子页按钮 + 模组设置聚合面板（v1.3，多模组聚合）。
    *
    * 页面内容不再写死：由 MSWSettingsHub 登记簿驱动——每个注册模组一页
    * 设置行（check/slider 控件，get/set 回调由注册方自持数据）；MSW 自己
    * 的 12 项也走同一契约自注册（design/mod-settings-hub.md）。
    *
    * UI：子按钮栏"模组"按钮（自绘，克隆类在汉化客户端是空壳——D-046 v2.5）
    * 打开面板；注册方 ≥2 时顶部出现模组子页签行，单注册方自动退化为平铺。
    * 面板打开时页面只保留子按钮 + 模组内容（pers/存档信息等让位）；
    * 页面自带背景美术（大尺寸子件）保留以维持原版纹理。
    * 保存时机：check 即时持久化（注册方 set 内自理）；滑块拖动只 set，
    * 面板收起时宿主统一调各注册方 onPageClose（D-035 高频 flush 教训）。
    * 诊断：tabStage/tabSnap/tabProbe/tabFont/pages/page + 分阶段 lastErr。
    */
   public class MSWPipTab
   {
      private var mod:*;

      private var built:Boolean = false;
      private var myBut:Sprite = null;      // "模组"子按钮（自绘）
      private var myButHi:Sprite = null;    // 高亮层
      private var head:* = null;            // 右侧帮助栏标题
      private var helpTf:TextField = null;  // 右侧帮助文本
      private var tabRow:MovieClip = null;  // 模组子页签行
      private var chips:Array = null;       // 子页签按钮
      private var resetBtn:MovieClip = null; // "恢复默认"按钮（当前页）
      private var rows:Array = null;        // 当前方设置行
      private var selPage:int = 0;
      private var builtPages:int = -1;      // 构建页签行时的注册方数量
      private var panelOpen:Boolean = false;
      private var hiddenVis:Array = null;
      private var cachedVpip:* = null;

      // 原版字体探测结果（从游戏现成行 nazv/numb/按钮标签抄，见 probeFonts）
      private var rowFont:String = null;
      private var rowFontSize:* = null;
      private var rowEmbed:Boolean = false;
      private var rowColor:* = null;
      private var numFont:String = null;
      private var numFontSize:* = null;
      private var numEmbed:Boolean = false;
      private var numColor:* = null;
      private var butFont:String = null;
      private var butFontSize:* = null;
      private var butEmbed:Boolean = false;
      private var butColor:* = null;        // 按钮标签颜色
      private var butFilters:Array = null;  // 按钮标签滤镜（辉光等）
      private var btnBd1:* = null;          // 原版按钮常态美术（光栅采样）
      private var btnBd2:* = null;          // 原版按钮高亮美术

      private static const HELP_DEFAULT:String = "鼠标悬停某行可查看说明。";

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

      /** 自动测试用：切换当前模组子页。 */
      public function debugSwitchPage(i:int):void
      {
         var w:* = MSWU.world();
         if(w == null) return;
         switchPage(w, i);
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
               " page=" + selPage + "/" + pages().length +
               " open=" + panelOpen;
            try
            {
               var pt:* = new Point(myBut["x"], myBut["y"]);
               pt = myBut["localToGlobal"](pt);
               s += " g=" + int(pt["x"]) + "," + int(pt["y"]);
            }
            catch(e1:*)
            {
            }
            try
            {
               if(rows != null && rows.length > 1)
               {
                  var sc0:* = rows[1]["mswSc"];
                  s += " rowOf=" + (rowOf(sc0) != null);
               }
            }
            catch(e1c:*)
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

      private function pages():Array
      {
         return mod.settings.getPages();
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
            if(c == myBut || c == head || c == helpTf || c == tabRow || isMine(c)) continue;
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
         if(chips != null)
         {
            for(var j:int = 0; j < chips.length; j++)
            {
               if(chips[j] === c) return true;
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

      // ---------------- 自绘按钮与字体 ----------------

      private static const COL_BORDER:int = 0x1E8C5A;
      private static const COL_BORDER_HI:int = 0x00FF99;
      private static const COL_FILL:int = 0x03170E;
      private static const COL_FILL_HI:int = 0x0A3A24;
      private static const ROW_CAP:int = 18; // 内容区容量（100..610，stride 28）

      private function drawButtonFace(g:*, w:Number, h:Number, hi:Boolean):void
      {
         g.clear();
         g.beginFill(hi ? COL_FILL_HI : COL_FILL, 0.92);
         g.lineStyle(2, hi ? COL_BORDER_HI : COL_BORDER, 1);
         g.drawRect(0, 0, w, h);
         g.endFill();
      }

      /** 光栅采样原版按钮美术：临时清空其文字，帧1/帧2 各绘一张位图。
       *  全程同步执行，画面不会闪。采样失败时回退 drawButtonFace。 */
      private function sampleButtonArt(b5:*, bw:Number, bh:Number):void
      {
         try
         {
            var BD:Class = getDefinitionByName("flash.display.BitmapData") as Class;
            var fr:int = b5["currentFrame"];
            var orig:String = b5["text"]["text"];
            b5["text"]["text"] = "";
            b5["gotoAndStop"](1);
            btnBd1 = new BD(bw, bh, true, 0);
            btnBd1["draw"](b5);
            b5["gotoAndStop"](2);
            btnBd2 = new BD(bw, bh, true, 0);
            btnBd2["draw"](b5);
            b5["text"]["text"] = orig;
            b5["gotoAndStop"](fr);
         }
         catch(e:*)
         {
            btnBd1 = null;
            btnBd2 = null;
         }
      }

      private function probeFonts(ov:*):void
      {
         try
         {
            var n:int = ov["numChildren"];
            for(var i:int = 0; i < n; i++)
            {
               var c:* = ov["getChildAt"](i);
               if(c == myBut || c == head || c == helpTf) continue;
               try
               {
                  if(c["name"] != null && c["name"].indexOf("instance") != 0) continue;
               }
               catch(en:*)
               {
                  continue;
               }
               var nz:* = null;
               try
               {
                  nz = c["getChildByName"]("nazv");
               }
               catch(e2:*)
               {
               }
               if(nz == null) continue;
               var tf:* = nz["getTextFormat"]();
               rowFont = tf["font"];
               rowFontSize = tf["size"];
               rowEmbed = nz["embedFonts"] == true;
               try
               {
                  rowColor = tf["color"];
               }
               catch(e3:*)
               {
               }
               var nb:* = c["getChildByName"]("numb");
               if(nb != null)
               {
                  var nf:* = nb["getTextFormat"]();
                  numFont = nf["font"];
                  numFontSize = nf["size"];
                  numEmbed = nb["embedFonts"] == true;
                  try
                  {
                     numColor = nf["color"];
                  }
                  catch(e4:*)
                  {
                  }
               }
               break;
            }
         }
         catch(ea:*)
         {
         }
         try
         {
            var b5:* = ov["getChildByName"]("but5");
            if(b5 != null && b5["text"] != null)
            {
               var bf:* = b5["text"]["getTextFormat"]();
               butFont = bf["font"];
               butFontSize = bf["size"];
               butEmbed = b5["text"]["embedFonts"] == true;
               try
               {
                  butColor = bf["color"];
               }
               catch(ec1:*)
               {
               }
               try
               {
                  var fls:Array = b5["text"]["filters"];
                  if(fls != null && fls.length > 0) butFilters = fls;
               }
               catch(ec2:*)
               {
               }
            }
         }
         catch(eb:*)
         {
         }
         mod.cfg.diagSet("tabFont", (rowFont == null ? "?" : rowFont + "/" + rowFontSize + "/embed" + rowEmbed + "/c" + rowColor) +
            " num=" + (numFont == null ? "?" : numFont + "/" + numFontSize + "/c" + numColor) +
            " but=" + (butFont == null ? "?" : butFont + "/" + butFontSize + "/embed" + butEmbed));
      }

      /** kind: "label"=行标签 / "value"=数值 / "button"=按钮。
       *  字体规格分别抄自游戏行的 nazv / numb / 按钮标签；label/value 另挂
       *  原版样式表（PipPage.setStyle），渲染机制与原版一致。 */
      private function makeLabel(text:String, size:int, color:int, kind:String = "label"):TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         var fname:String = rowFont;
         var fsize:* = rowFontSize;
         var fcolor:* = rowColor != null ? rowColor : color;
         var fembed:Boolean = rowEmbed;
         if(kind == "value")
         {
            if(numFont != null) fname = numFont;
            if(numFontSize != null) fsize = numFontSize;
            if(numColor != null) fcolor = numColor;
            fembed = numEmbed;
         }
         else if(kind == "button")
         {
            if(butFont != null) fname = butFont;
            if(butFontSize != null) fsize = butFontSize;
            if(butColor != null) fcolor = butColor;
            fembed = butEmbed;
         }
         else if(kind == "chip")
         {
            // 页签：行字体 + 指定字号（页签是次级控件，不跟按钮的 20 号）
            if(butColor != null) fcolor = butColor;
            fembed = rowEmbed;
         }
         if(fname != null) fmt.font = fname; else fmt.font = "SimHei";
         if(fsize != null) fmt.size = fsize; else fmt.size = size;
         fmt.color = fcolor;
         tf.defaultTextFormat = fmt;
         try
         {
            tf.embedFonts = fembed;
            if(kind == "button" && butFilters != null) tf["filters"] = butFilters;
         }
         catch(ee:*)
         {
         }
         if(kind != "button")
         {
            try
            {
               var st:Class = getDefinitionByName("fe.inter::PipPage") as Class;
               if(st != null) st["setStyle"](tf);
            }
            catch(es:*)
            {
            }
         }
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
         probeFonts(ov);
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
         sampleButtonArt(b5, bw, bh);
         var useArt:Boolean = btnBd1 != null && btnBd2 != null;
         if(useArt)
         {
            // 原版按钮美术直接作底图（常态/高亮两态）
            var bmpC:Class = getDefinitionByName("flash.display::Bitmap") as Class;
            myBut["addChild"](new bmpC(btnBd1));
            myButHi["addChild"](new bmpC(btnBd2));
         }
         else
         {
            drawButtonFace(myButHi["graphics"], bw, bh, true);
            drawButtonFace(myBut["graphics"], bw, bh, false);
         }
         myButHi["visible"] = false;
         var lt:TextField = makeLabel("模组", 15, 0xE8FFE8, "button");
         try
         {
            // 字号校准：按原版按钮标签的实际字高缩放
            if(b5 != null && b5["text"] != null)
            {
               var wantH:Number = Number(b5["text"]["textHeight"]);
               if(wantH > 4 && lt["textHeight"] > 4)
               {
                  var calSize:int = Math.round(20 * wantH / lt["textHeight"]);
                  if(calSize >= 10 && calSize <= 40)
                  {
                     var f2:TextFormat = lt["defaultTextFormat"];
                     f2.size = calSize;
                     lt["defaultTextFormat"] = f2;
                     lt["setTextFormat"](f2);
                  }
               }
            }
         }
         catch(ecal:*)
         {
         }
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
         head = makeLabel("", 16, 0x00FF99);
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
         built = true;
         ensureTabRow(ov);
         mod.cfg.diagSet("pages", pages().length);
         mod.cfg.diagAdd("tabBuild");
         snap();
      }

      /** 模组子页签行：注册方 ≥2 时出现（单方平铺）。注册方数量变化时重建。 */
      private function ensureTabRow(ov:*):void
      {
         var n:int = pages().length;
         if(tabRow != null && n == builtPages) return;
         if(tabRow != null)
         {
            try
            {
               ov["removeChild"](tabRow);
            }
            catch(er:*)
            {
            }
            tabRow = null;
            chips = null;
         }
         if(n < 2) return;
         tabRow = new MovieClip();
         tabRow["x"] = 30;
         tabRow["y"] = 66;
         tabRow["visible"] = false;
         chips = [];
         var cx:Number = 0;
         for(var i:int = 0; i < n; i++)
         {
            var pg:* = pages()[i];
            var nm:String = pg["displayName"] == null ? pg["modId"] : pg["displayName"];
            var lt:TextField = makeLabel(nm, 14, 0xD8FFE8, "chip");
            var w:Number = lt["width"] + 22;
            var chip:MovieClip = new MovieClip();
            var bg:Sprite = new Sprite();
            drawButtonFace(bg["graphics"], w, 22, i == selPage);
            chip["addChild"](bg);
            chip["mswBg"] = bg;
            lt["x"] = 11;
            lt["y"] = 2;
            chip["addChild"](lt);
            chip["mswIdx"] = i;
            chip["buttonMode"] = true;
            chip["mouseChildren"] = false;
            chip.addEventListener(MouseEvent.CLICK, onPageChipClick);
            chip["x"] = cx;
            chip["y"] = 0;
            tabRow["addChild"](chip);
            chips[chips.length] = chip;
            cx += w + 8;
         }
         // "恢复默认"：重置当前模组页全部设置项（有 def 的）
         resetBtn = new MovieClip();
         var rbBg:Sprite = new Sprite();
         drawButtonFace(rbBg["graphics"], 92, 22, false);
         resetBtn["addChild"](rbBg);
         resetBtn["mswBg"] = rbBg;
         var rlt:TextField = makeLabel("恢复默认", 14, 0x9FE8C8, "chip");
         rlt["x"] = 11;
         rlt["y"] = 2;
         resetBtn["addChild"](rlt);
         resetBtn["x"] = cx + 16;
         resetBtn["y"] = 0;
         resetBtn["buttonMode"] = true;
         resetBtn["mouseChildren"] = false;
         resetBtn.addEventListener(MouseEvent.CLICK, onResetClick);
         tabRow["addChild"](resetBtn);
         ov["addChild"](tabRow);
         builtPages = n;
      }

      private function onResetClick(e:*):void
      {
         try
         {
            var w:* = MSWU.world();
            if(w == null) return;
            var pg:Array = pages();
            if(selPage >= pg.length) return;
            var page:* = pg[selPage];
            var items:Array = page["items"];
            var n:int = 0;
            for(var i:int = 0; i < items.length; i++)
            {
               var it:Object = items[i];
               if(it == null || it["def"] === undefined || it["def"] == null || it["set"] == null) continue;
               it["set"](it["def"]);
               n++;
            }
            try
            {
               if(page["onPageClose"] != null) page["onPageClose"](); // 重置即持久化
            }
            catch(e2:*)
            {
            }
            var ov:* = findOptVis(w);
            if(ov != null) renderRows(ov);
            setRowsVisible(true);
            if(helpTf != null) helpTf["text"] = "已恢复默认（" + n + " 项）。";
            mod.cfg.diagAdd("reset");
         }
         catch(err:*)
         {
            err("pageReset", err);
         }
      }

      private function onPageChipClick(e:*):void
      {
         try
         {
            var chip:* = e["currentTarget"];
            var w:* = MSWU.world();
            if(w == null) return;
            switchPage(w, int(chip["mswIdx"]));
         }
         catch(err:*)
         {
            err("pageChip", err);
         }
      }

      private function switchPage(w:*, i:int):void
      {
         var n:int = pages().length;
         if(i < 0 || i >= n) return;
         selPage = i;
         var ov:* = findOptVis(w);
         if(ov == null) return;
         ensureBuilt(ov);
         ensureTabRow(ov);
         if(chips != null)
         {
            for(var j:int = 0; j < chips.length; j++)
            {
               var chip:* = chips[j];
               var bg:* = chip["mswBg"];
               drawButtonFace(bg["graphics"], Number(chip["width"]), 22, j == selPage);
            }
         }
         renderRows(ov);
         mod.cfg.diagSet("page", selPage);
      }

      // ---------------- 行渲染（按当前注册页） ----------------

      private function renderRows(ov:*):void
      {
         if(rows != null)
         {
            for(var ri:int = 0; ri < rows.length; ri++)
            {
               try
               {
                  ov["removeChild"](rows[ri]);
               }
               catch(erm:*)
               {
               }
            }
         }
         rows = [];
         var pg:Array = pages();
         if(selPage >= pg.length) selPage = 0;
         var page:* = pg[selPage];
         if(page == null) return;
         var items:Array = page["items"];
         if(head != null) head["text"] = (page["displayName"] == null ? "" : page["displayName"]) + " 设置";
         if(helpTf != null) helpTf["text"] = (page["desc"] == null || page["desc"] == "") ? HELP_DEFAULT : page["desc"];
         if(items == null) return;
         var n:int = Math.min(items.length, ROW_CAP);
         for(var i:int = 0; i < n; i++)
         {
            var it:Object = items[i];
            if(it == null || it["key"] == null) continue;
            var r:MovieClip = new MovieClip();
            r["x"] = 30;
            r["y"] = 100 + i * 28;
            var bg:Sprite = new Sprite();
            bg["graphics"].beginFill(0x000000, 1);
            bg["graphics"].lineStyle(1, 0x0F4A2E, 1);
            bg["graphics"].drawRect(0, 0, 550, 24);
            bg["graphics"].endFill();
            bg["mouseEnabled"] = false;
            r["addChild"](bg);
            var lt:TextField = makeLabel(it["label"], 14, 0xD8FFE8, "label");
            lt["x"] = 10;
            lt["y"] = 3;
            r["addChild"](lt);
            r["mswItem"] = it;
            var kind:String = it["kind"] == null ? "check" : it["kind"];
            var cur:* = getItemVal(it);
            if(kind == "check")
            {
               var cb:* = makeCheck();
               cb["selected"] = cur == true;
               cb["x"] = 360;
               cb["y"] = 2;
               cb["addEventListener"]("change", onCheck);
               r["addChild"](cb);
               r["mswSc"] = cb;
            }
            else
            {
               var numb:TextField = makeLabel(fmtVal(it, cur), 13, 0xE8FFE8, "value");
               numb["x"] = 505;
               numb["y"] = 4;
               r["addChild"](numb);
               r["mswNumb"] = numb;
               var sc:* = makeSlider(it, cur);
               if(sc != null)
               {
                  sc["addEventListener"]("scroll", onScroll);
                  r["addChild"](sc);
                  r["mswSc"] = sc;
               }
               else
               {
                  var less:Sprite = miniBtn("◀", 256);
                  var more:Sprite = miniBtn("▶", 445);
                  less["mswDir"] = -1;
                  more["mswDir"] = 1;
                  less.addEventListener(MouseEvent.CLICK, onStep);
                  more.addEventListener(MouseEvent.CLICK, onStep);
                  r["addChild"](less);
                  r["addChild"](more);
               }
            }
            r.addEventListener(MouseEvent.MOUSE_OVER, onRowHover);
            r.addEventListener(MouseEvent.MOUSE_OUT, onRowOut);
            r["visible"] = false;
            ov["addChild"](r);
            rows[rows.length] = r;
         }
      }

      private function makeCheck():*
      {
         try
         {
            var cls:Class = getDefinitionByName("fl.controls::CheckBox") as Class;
            if(cls != null) return new cls();
         }
         catch(e0:*)
         {
         }
         var box:MovieClip = new MovieClip();
         drawToggle(box, false);
         box["buttonMode"] = true;
         box.addEventListener(MouseEvent.CLICK, onHandToggle);
         return box;
      }

      private function makeSlider(it:Object, cur:*):*
      {
         try
         {
            var cls:Class = getDefinitionByName("fl.controls::ScrollBar") as Class;
            if(cls != null)
            {
               var sc:* = new cls();
               sc["direction"] = "horizontal";
               sc["width"] = 240;
               sc["height"] = 14;
               sc["x"] = 256;
               sc["y"] = 5;
               sc["minScrollPosition"] = 0;
               sc["maxScrollPosition"] = Math.round((Number(it["max"]) - Number(it["min"])) / Number(it["step"]));
               sc["scrollPosition"] = posOf(it, cur);
               return sc;
            }
         }
         catch(e:*)
         {
         }
         return null;
      }

      private function drawToggle(box:*, on:Boolean):void
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

      private function miniBtn(txt:String, x:Number):Sprite
      {
         var s:Sprite = new Sprite();
         drawButtonFace(s["graphics"], 40, 20, false);
         var lt:TextField = makeLabel(txt, 12, 0xE8FFE8, "button");
         lt["x"] = (40 - lt["width"]) / 2;
         lt["y"] = 2;
         s["addChild"](lt);
         s["x"] = x;
         s["y"] = 4;
         s["buttonMode"] = true;
         return s;
      }

      // ---------------- 值换算（通用契约：min/max/step） ----------------

      private function getItemVal(it:Object):*
      {
         try
         {
            return it["get"]();
         }
         catch(e:*)
         {
            err("itemGet:" + it["key"], e);
         }
         return null;
      }

      private function posOf(it:Object, v:*):Number
      {
         var st:Number = Number(it["step"]);
         if(st <= 0) st = 1;
         return Math.round((Number(v) - Number(it["min"])) / st);
      }

      private function valOf(it:Object, pos:Number):*
      {
         var st:Number = Number(it["step"]);
         if(st <= 0) st = 1;
         return Number(it["min"]) + Math.round(pos) * st;
      }

      private function fmtVal(it:Object, v:*):String
      {
         var st:Number = Number(it["step"]);
         var suffix:String = it["suffix"] == null ? "" : String(it["suffix"]);
         if(st >= 1) return String(Math.round(Number(v))) + suffix;
         var d:int = 0;
         var t:Number = st;
         while(t > 0 && t < 1 && d < 4)
         {
            t *= 10;
            d += 1;
         }
         return Number(v).toFixed(d) + suffix;
      }

      // ---------------- 控件事件 ----------------

      private function rowOf(o:*):*
      {
         while(o != null)
         {
            var k:* = null;
            try
            {
               // 密封类（fl.controls.*）访问缺失属性抛 #1069：跳过并继续向父级找
               k = o["mswItem"];
            }
            catch(e:*)
            {
               k = null;
            }
            if(k != null) return o;
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
            var it:Object = row["mswItem"];
            it["set"](cb["selected"] == true);
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
            var it:Object = row["mswItem"];
            var cur:Boolean = getItemVal(it) == true;
            it["set"](!cur);
            drawToggle(box, getItemVal(it) == true);
         }
         catch(err2:*)
         {
            err("tabToggleBox", err2);
         }
      }

      private function onScroll(e:*):void
      {
         try
         {
            var sc:* = e["currentTarget"];
            var row:* = rowOf(sc);
            if(row == null) return;
            var it:Object = row["mswItem"];
            var v:* = valOf(it, Number(sc["scrollPosition"]));
            it["set"](v);
            if(row["mswNumb"] != null) row["mswNumb"]["text"] = fmtVal(it, v);
            // 拖动期间不落盘（D-035）：关面板时宿主统一调各注册方 onPageClose
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
            var it:Object = row["mswItem"];
            var v:Number = Number(getItemVal(it)) + Number(btn["mswDir"]) * Number(it["step"]);
            it["set"](v);
            if(row["mswNumb"] != null) row["mswNumb"]["text"] = fmtVal(it, getItemVal(it));
         }
         catch(err2:*)
         {
            err("tabStep", err2);
         }
      }

      private function onRowHover(e:*):void
      {
         try
         {
            var row:* = rowOf(e["currentTarget"]);
            if(row == null) return;
            var it:Object = row["mswItem"];
            var hint:String = it["hint"] == null ? "" : it["hint"];
            if(helpTf != null) helpTf["text"] = it["label"] + (hint != "" ? "：\n" + hint : "");
         }
         catch(e:*)
         {
         }
      }

      private function onRowOut(e:*):void
      {
         try
         {
            if(helpTf != null)
            {
               var pg:Array = pages();
               var d:String = selPage < pg.length ? pg[selPage]["desc"] : null;
               helpTf["text"] = (d == null || d == "") ? HELP_DEFAULT : d;
            }
         }
         catch(e:*)
         {
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
         ensureTabRow(ov);
         if(tabRow != null) tabRow["visible"] = true;
         renderRows(ov);
         setRowsVisible(true);
         if(helpTf != null)
         {
            var pg:Array = pages();
            var d:String = selPage < pg.length ? pg[selPage]["desc"] : null;
            helpTf["text"] = (d == null || d == "") ? HELP_DEFAULT : d;
            helpTf["visible"] = true;
         }
         if(head != null)
         {
            head["text"] = (selPage < pg.length && pg[selPage]["displayName"] != null ? pg[selPage]["displayName"] : "") + " 设置";
            head["visible"] = true;
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
         if(helpTf != null) helpTf["visible"] = false;
         if(head != null) head["visible"] = false;
         if(tabRow != null) tabRow["visible"] = false;
         // 各注册方的收尾回调（延迟保存 flush）
         var pg:Array = pages();
         for(var j:int = 0; j < pg.length; j++)
         {
            try
            {
               if(pg[j]["onPageClose"] != null) pg[j]["onPageClose"]();
            }
            catch(ec:*)
            {
               err("pageClose:" + pg[j]["modId"], ec);
            }
         }
         mod.cfg.diagAdd("tabOff");
      }

      private function suppressGameContent(ov:*, record:Boolean):void
      {
         var n:int = ov["numChildren"];
         for(var i:int = n - 1; i >= 0; i--)
         {
            var c:* = ov["getChildAt"](i);
            if(c == myBut || c == head || c == helpTf || c == tabRow || isMine(c)) continue;
            var nm:String = "";
            try
            {
               nm = c["name"];
            }
            catch(en:*)
            {
            }
            if(nm != null && nm.length == 4 && nm.indexOf("but") == 0) continue; // 子按钮
            try
            {
               // 页面自身的背景/边框美术（大尺寸子件）保留，维持原版纹理
               if(Number(c["width"]) > 800 && Number(c["height"]) > 400) continue;
            }
            catch(eg:*)
            {
            }
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

      private function setRowsVisible(v:Boolean):void
      {
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
