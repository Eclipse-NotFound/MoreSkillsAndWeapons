package
{
   import flash.events.KeyboardEvent;

   /**
    * 疾跑中切枪（swaprun）：2026-08-17 自 Sandevistan 迁移。
    *
    * 源实现：`mods/Sandevistan/src/SandevistanMod.as` 的 onKey() 内 swaprun
    * 拦截（v1.100 引入，v1.104 改 KEY_DOWN 事件层）。
    *
    * 机制：游戏本体按住 Shift 疾跑时数字键映射第二组快捷槽（通常为空，
    * 无法切枪）。本组件在 KEY_DOWN 事件层（早于游戏 Ctr 注册）直接消费
    * 数字键 + `invent.useFav(n)` 第一组槽位，并 stopImmediatePropagation
    * 阻止游戏 Ctr 收到该键（防第二组槽重复处理）。
    *
    * 键位映射：解析 `world.ctr.keyXML`（public）的 def/alt 键码 → 键位 id
    * （形如 keyWeapon1），换挡槽位号 = id.substr(9) 的数字部分（1-10）。
    *
    * 与斯安维斯坦的适配（2026-08-17 D-033 调整）：inGameplay() 判定改为
    * "时停期放行、回放期禁止"——斯安维斯坦时停期间（onPause=true 且
    * godMode=false）疾跑切枪照常生效（对齐 Sandevistan 原版行为：原版
    * 时停期间允许切枪、仅回放期禁止）；回放期（onPause=true 且
    * godMode=true）不拦截（武器由斯安维斯坦重演钉住，介入会破坏其状态机）。
    */
   public class MSWSwaprun
   {
      private var mod:*;
      /** 键码 → 键位 id（keyWeapon1..10 等）；从 world.ctr.keyXML 懒构建 */
      private var keyMap:Object = null;

      public function MSWSwaprun(m:*)
      {
         mod = m;
      }

      private function buildKeyMap(w:*):void
      {
         try
         {
            var ctr:* = w["ctr"];
            if(ctr == null) return;
            var kx:* = ctr["keyXML"];
            if(kx == null) return;
            var km:Object = {};
            for each(var k:XML in kx["key"])
            {
               var id:String = String(k.@id);
               var defs:Array = [String(k.@def), String(k.@alt)];
               for each(var dv:String in defs)
               {
                  var code:int = parseInt(dv, 10);
                  if(dv != "" && !isNaN(code) && code > 0 && code < 256)
                  {
                     km[code] = id;
                  }
               }
            }
            keyMap = km;
         }
         catch(e:*)
         {
         }
      }

      /**
       * KEY_DOWN 拦截；返回 true = 已消费（调用方应 stopImmediatePropagation）。
       * 仅在可操作且疾跑（keyRun）中、按到第一组快捷槽键时消费。
       */
      public function intercept(e:KeyboardEvent, w:*):Boolean
      {
         try
         {
            if(w == null) return false;
            if(!mod.cfg.swapRun) return false;
            if(!MSWU.inGameplay(w)) return false;
            var ctr:* = w["ctr"];
            if(ctr == null) return false;
            if(ctr["keyRun"] != true) return false;
            if(e.keyCode <= 0 || e.keyCode >= 256) return false;
            if(keyMap == null) buildKeyMap(w);
            if(keyMap == null) return false;
            var kbS:* = keyMap[e.keyCode];
            if(kbS == null) return false;
            var s:String = String(kbS);
            if(s.indexOf("keyWeapon") != 0) return false;
            var wnS:int = parseInt(s.substr(9));
            if(wnS < 1 || wnS > 10) return false;
            e.stopImmediatePropagation();
            e.preventDefault();
            try { w["invent"]["useFav"](wnS); } catch(e2:*) { }
            var gg:* = w["gg"];
            try { if(gg["visSel"]) { w["gui"]["unshowSelector"](0); } } catch(e2:*) { }
            try { if(gg["currentSpell"] != null) { gg["currentSpell"]["active"] = false; } } catch(e2:*) { }
            try { ctr["keyDef"] = false; ctr["keyAttack"] = false; } catch(e2:*) { }
            mod.cfg.diagAdd("swapRun");
            return true;
         }
         catch(e:*)
         {
            return false;
         }
         return false;
      }
   }
}