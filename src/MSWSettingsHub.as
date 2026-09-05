package
{
   /**
    * 模组设置聚合页 —— 注册契约与登记簿（design/mod-settings-hub.md §3）。
    *
    * 接入方式（其他模组，在各自仓库实现）——主通道：
    *   var api:* = World.w["modAPI"];  // 宿主启动后自动发布。兄弟模组域互不可见，
    *                                   // getDefinitionByName 拿不到宿主类
    *                                   // （mod-loader-cross-domain-anomaly）
    *   if(api != null) api["registerPage"](modId, displayName, items, onPageClose, desc);
    * 未发布时在自己的 ENTER_FRAME 里重试（≤300 帧）。
    * 同域直调备用通道：getDefinitionByName("MoreSkillsWeaponsMod").settingsRegister(...)。
    *
    * items 元素：
    *   { key, label, kind:"check"|"slider", min, max, step, hint,
    *     get:Function, set:Function }
    * 配置数据完全由注册方自持（get/set 回调），宿主不读写注册方存储。
    * 保存时机：check 的 set 即时持久化；slider 拖动只 set（实时生效），
    * 面板收起时宿主统一调 onPageClose 供注册方 flush（D-035 教训）。
    */
   public class MSWSettingsHub
   {
      private var pages:Array = [];

      public function registerPage(modId:String, displayName:String, items:Array,
                                   onPageClose:Function = null, desc:String = ""):void
      {
         if(modId == null || items == null) return;
         for(var i:int = 0; i < pages.length; i++)
         {
            if(pages[i]["modId"] == modId)
            {
               pages[i]["displayName"] = displayName;
               pages[i]["items"] = items;
               pages[i]["onPageClose"] = onPageClose;
               pages[i]["desc"] = desc;
               return; // 重复注册 = 更新
            }
         }
         var p:Object = {
            "modId": modId, "displayName": displayName, "items": items,
            "onPageClose": onPageClose, "desc": desc
         };
         pages[pages.length] = p;
      }

      public function getPages():Array
      {
         return pages;
      }

      /** MSW 自注册的设置项（第一个注册方，走同一契约）。 */
      public static function buildMswItems(mod:*):Array
      {
         var defs:Array = [
            ["ricochet", "跳弹技能", "check", 0, 0, 1, ""],
            ["dropRate", "下坠速率", "slider", 0, 3, 0.1, "0.1步进 0-3"],
            ["wallHits", "撞墙次数", "slider", 0, 5, 1, "0=撞墙即爆"],
            ["muzzleVel", "初速度", "slider", 10, 100, 1, "10-100"],
            ["bounce", "反弹力度", "slider", 0, 1, 0.1, "0.1步进 0-1"],
            ["aimSkill", "蹲/梯举枪", "check", 0, 0, 1, "Shift+W"],
            ["projHits", "手雷击落", "check", 0, 0, 1, ""],
            ["projHp", "投掷物血量", "slider", 1, 1000, 5, "步进5"],
            ["projArmor", "投掷物护甲", "slider", 0, 500, 5, "步进5"],
            ["swapRun", "疾跑切枪", "check", 0, 0, 1, "Shift+数字键"],
            ["spreadFix", "散布恒定", "check", 0, 0, 1, "仅榴弹炮"],
            ["dashKeepPose", "冲刺保持蹲/趴", "check", 0, 0, 1, "魔法冲刺"]
         ];
         var items:Array = [];
         for(var i:int = 0; i < defs.length; i++)
         {
            var d:Array = defs[i];
            items[items.length] = {
               "key": d[0], "label": d[1], "kind": d[2],
               "min": d[3], "max": d[4], "step": d[5], "hint": d[6],
               "get": makeGetter(mod, d[0]),
               "set": makeSetter(mod, d[0], d[2])
            };
         }
         return items;
      }

      private static function makeGetter(mod:*, k:String):Function
      {
         return function():*
         {
            return mod.cfg[k];
         };
      }

      /** check 即时持久化；slider 只写内存（onPageClose 统一 save）。 */
      private static function makeSetter(mod:*, k:String, kind:String):Function
      {
         return function(v:*):void
         {
            if(kind == "check") mod.cfg[k] = v == true;
            else mod.cfg[k] = Number(v);
            mod.cfg.clamp();
            if(kind == "check") mod.cfg.save();
         };
      }
   }
}
