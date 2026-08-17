package
{
   import flash.utils.getDefinitionByName;

   /**
    * 共享工具：对游戏对象的防御性动态访问。
    * 游戏类多为密封类：对不存在成员的 bracket 访问会抛 #1069 并吞掉外层 try，
    * 因此一律先用 `in` 探测（`in` 不抛异常）再读取。
    */
   public class MSWU
   {
      public static function has(o:*, p:String):Boolean
      {
         if(o == null)
         {
            return false;
         }
         var r:Boolean = false;
         try
         {
            r = (p in o) && (o[p] !== undefined);
         }
         catch(e:*)
         {
            r = false;
         }
         return r;
      }

      public static function num(o:*, p:String, def:Number = 0):Number
      {
         if(!has(o, p))
         {
            return def;
         }
         var v:Number = o[p];
         if(isNaN(v))
         {
            return def;
         }
         return v;
      }

      public static function str(o:*, p:String, def:String = null):String
      {
         if(!has(o, p))
         {
            return def;
         }
         var v:* = o[p];
         if(v == null)
         {
            return def;
         }
         return String(v);
      }

      public static function cls(name:String):Class
      {
         try
         {
            return getDefinitionByName(name) as Class;
         }
         catch(e:*)
         {
            return null;
         }
         return null;
      }

      /** 取 fe.World.w（全局入口） */
      public static function world():*
      {
         var c:Class = cls("fe.World");
         if(c == null)
         {
            return null;
         }
         try
         {
            return c["w"];
         }
         catch(e:*)
         {
            return null;
         }
         return null;
      }

      /**
       * 可操作状态判定（镜像 Sandevistan inGameplay，2026-08-17 迁移核对）：
       * 世界已运行、无控制台/哔哔小马/SATS/仓库界面、无游戏菜单暂停。
       * 另加 onPause 判定——斯安维斯坦时停/回放期间世界冻结（onPause=true），
       * 迁移自 Sandevistan 的"手雷击落/疾跑切枪"不得在世界冻结时生效
       * （冻结期攻击体伤害被清零、回放期由斯安维斯坦自己重演）。
       */
      public static function inGameplay(w:*):Boolean
      {
         if(w == null) return false;
         if(w["onPause"] == true) return false;
         if(num(w, "allStat") < 1) return false;
         if(w["gg"] == null || w["loc"] == null) return false;
         if(w["onConsol"] == true) return false;
         var pip:* = w["pip"];
         if(pip != null && pip["active"] == true) return false;
         var sats:* = w["sats"];
         if(sats != null && sats["active"] == true) return false;
         var stand:* = w["stand"];
         if(stand != null && stand["active"] == true) return false;
         var gui:* = w["gui"];
         if(gui != null && gui["guiPause"] == true) return false;
         return true;
      }
   }
}
