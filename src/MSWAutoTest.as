package
{
   import flash.utils.getDefinitionByName;

   /**
    * 测试实例自动驱动（仅 appid ≠ "pfe" 时激活，TDFC AutoTest 同款模式）。
    *
    * 目的：自动化复现"哔哔小马主菜单页"场景——自动开新档 → 打开哔哔小马
    * 并跳到 Opt 页（主菜单页）→ 停手，让 MSWPipTab 构建按钮/面板，供
    * 截图与 SOL 诊断离线检查。用户实例（appid=pfe）零影响。
    *
    * 序列遵循 remains-auto-testing 四步：
    * 等 landData → 放行主循环（mm.active=false）→ newGame(-1,...)
    * （nload<0 才是真新档；异步链由 World.step 自走，30s 超时重试）→
    * gg 出现后 pip.onoff(5)（public，开哔哔小马并跳 Opt 页）。
    */
   public class MSWAutoTest
   {
      private var mod:*;
      private var enabled:Boolean = false;
      private var stage:String = "idle";
      private var t:int = 0;
      private var triedNewGame:Boolean = false;
      private var openedPip:Boolean = false;

      // mock 页内部状态（自动测试分页渲染验证用）
      private var mockA:Boolean = true;
      private var mockB:Number = 50;

      public function MSWAutoTest(m:*)
      {
         mod = m;
         try
         {
            var na:* = getDefinitionByName("flash.desktop.NativeApplication");
            var id:String = na["nativeApplication"]["applicationID"];
            enabled = id != "pfe";
            mod.cfg.diagSet("auto", enabled ? "on:" + id : "off");
            if(enabled) registerMockPage(); // 多模组分页渲染回归：注册 mock 页
         }
         catch(e:*)
         {
            enabled = false;
         }
      }

      private function registerMockPage():void
      {
         var items:Array = [
            {"key": "mockA", "label": "模拟开关", "kind": "check", "min": 0, "max": 0, "step": 1,
             "hint": "自动测试用模拟项",
             "get": function():* { return mockA; },
             "set": function(v:*):void { mockA = v == true; }},
            {"key": "mockB", "label": "模拟数值", "kind": "slider", "min": 0, "max": 100, "step": 5,
             "hint": "步进5",
             "get": function():* { return mockB; },
             "set": function(v:*):void { mockB = Number(v); }}
         ];
         mod.settings.registerPage("mocktest", "Mock 测试", items, null, "自动测试注册的模拟页");
      }

      public function update(w:*):void
      {
         if(!enabled) return;
         try
         {
            if(w == null) return;
            t++;
            if(stage == "idle")
            {
               // 第 -1 步：boot stage-2 没跑完（landData 空）就动菜单会 #1009
               if(w["landData"] == null) return;
               var mm:* = w["mm"];
               if(mm == null) return;
               if(mm["active"] == true)
               {
                  mm["active"] = false; // 第 0 步：放行主循环
                  stage = "game";
                  t = 0;
                  mod.cfg.diagSet("auto", "menu-off");
               }
               return;
            }
            if(stage == "game")
            {
               if(w["gg"] != null)
               {
                  stage = "inGame";
                  t = 0;
                  mod.cfg.diagSet("auto", "inGame");
                  return;
               }
               // 第 1 步：真·新档（nload<0）；异步链由 step 自走
               if(!triedNewGame || t > 1800) // ~30s 超时重试
               {
                  w["newGame"](-1, "LP", null);
                  triedNewGame = true;
                  t = 0;
                  mod.cfg.diagSet("auto", "newGame-tried");
               }
               return;
            }
            if(stage == "inGame")
            {
               if(t < 300) return; // 等 5s 世界稳定
               var pip:* = w["pip"];
               if(pip == null) return;
               if(!openedPip)
               {
                  pip["onoff"](5); // 开哔哔小马并跳 Opt 页（public）
                  openedPip = true;
                  t = 0;
                  mod.cfg.diagSet("auto", "pip-opt-open");
                  return;
               }
               if(t == 310) mod.panel.debugClick(); // 自动点开模组面板
               if(t == 500) mod.panel.debugSwitchPage(1); // 切到 mock 页（分页渲染回归）
               // 测试模式：保持 Opt 页打开，供截图/诊断检查
            }
         }
         catch(e:*)
         {
            mod.cfg.diagSet("auto", "err:" + e);
         }
      }
   }
}
