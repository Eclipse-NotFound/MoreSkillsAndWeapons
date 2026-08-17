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
       * 斯安维斯坦相关（2026-08-17 D-033 调整）：
       * - 时停期（onPause=true 且 godMode=false）：**放行**——迁移技能
       *   （手雷击落/疾跑切枪）在时停期间也要生效（对齐 Sandevistan 原版
       *   行为：原版时停期间两者都工作，仅回放期禁止）；
       * - 回放期（onPause=true 且 godMode=true，Sandevistan 回放开始置
       *   world.godMode=true）：**禁止**——回放期爆炸由斯安维斯坦重演、
       *   武器被其钉住，介入会造成双重结算。
       * 注：godMode 判定在"玩家平时开着 godMode + 用时停"的边缘场景会误判
       * 为回放期（技能禁），可接受。
       */
      public static function inGameplay(w:*):Boolean
      {
         if(w == null) return false;
         if(w["onPause"] == true && w["godMode"] == true) return false;
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
