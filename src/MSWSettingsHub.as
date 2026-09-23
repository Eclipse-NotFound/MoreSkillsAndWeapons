package
{
   /**
    * MSW setting definitions and outbound registration adapter for ModSettings.
    *
    * Main settings host is World.w.main.getChildByName("ModSettingsCarrier").modAPI.
    * This adapter queues MSW's pages until that host arrives; it publishes no carrier.
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
      public var api:* = null;
      private var revision:int = 0;
      private var sentRevision:int = -1;

      public function MSWSettingsHub() {}

      public function connect(w:*):void
      {
         try
         {
            var carrier:* = w.main.getChildByName("ModSettingsCarrier");
            var next:* = carrier == null ? null : carrier["modAPI"];
            if(next !== api) { api = next; sentRevision = -1; }
            if(api == null || sentRevision == revision) return;
            for each(var page:Object in pages)
               api.registerPage(page.modId, page.displayName, page.items, page.onPageClose, page.desc);
            sentRevision = revision;
         }
         catch(e:*) { api = null; sentRevision = -1; }
      }

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
               revision++;
               return; // 重复注册 = 更新
            }
         }
         var p:Object = {
            "modId": modId, "displayName": displayName, "items": items,
            "onPageClose": onPageClose, "desc": desc
         };
         pages[pages.length] = p;
         revision++;
      }

      public function getPages():Array
      {
         return pages;
      }

      /** MSW 自注册的设置项（第一个注册方，走同一契约）。 */
      public static function buildMswItems(mod:*):Array
      {
         // def = 出厂默认（= MSWConfig 字段初始值），供面板"恢复默认"使用
      var defs:Array = [
            ["ricochet", "跳弹技能", "check", 0, 0, 1, "", false],
            ["ricochetCount", "基础跳弹次数", "slider", 0, 20, 1, "次数内必弹；0=首次撞墙即抽概率。整条弹道最多100次。", 1],
            ["ricochetChance", "额外跳弹概率", "slider", 0, 100, 1, "首次额外跳弹概率；0%=不额外跳弹。设置只影响新发射的子弹。", 0],
            ["ricochetChanceDecay", "额外概率衰减", "slider", 0, 100, 1, "每次成功额外跳弹后降低下次概率；50%：80%→40%→20%。", 0],
            ["ricochetDamageDecay", "额外伤害衰减", "slider", 0, 100, 1, "仅额外跳弹后减伤；20%：100→80→64。伤害归零终止。", 0],
            ["ricochetSpeedDecay", "额外速度衰减", "slider", 0, 100, 1, "仅额外跳弹后减速；低于1像素/游戏步终止。", 0],
            ["ricochetResetDistance", "跳弹重置命中距离", "check", 0, 0, 1, "开：每次反弹重新计距；关：累计距离。仍受武器精度、敌人闪避影响；仅影响新发射子弹。", true],
            ["dropRate", "下坠速率", "slider", 0, 3, 0.1, "0.1步进 0-3", 1],
            ["wallHits", "撞墙次数", "slider", 0, 5, 1, "0=撞墙即爆", 0],
            ["muzzleVel", "初速度", "slider", 10, 100, 1, "10-100", 35],
            ["bounce", "反弹力度", "slider", 0, 1, 0.1, "0.1步进 0-1", 0.4],
            ["aimSkill", "蹲/梯举枪", "check", 0, 0, 1, "Shift+W", false],
            ["projHits", "手雷击落", "check", 0, 0, 1, "", true],
            ["projHp", "投掷物血量", "slider", 1, 1000, 5, "步进5", 30],
            ["projArmor", "投掷物护甲", "slider", 0, 500, 5, "步进5", 0],
            ["swapRun", "疾跑切枪", "check", 0, 0, 1, "Shift+数字键", true],
            ["spreadFix", "散布恒定", "check", 0, 0, 1, "仅榴弹炮", true],
            ["dashKeepPose", "冲刺保持蹲/趴", "check", 0, 0, 1, "魔法冲刺", true]
         ];
         var items:Array = [];
         for(var i:int = 0; i < defs.length; i++)
         {
            var d:Array = defs[i];
            items[items.length] = {
               "key": d[0], "label": d[1], "kind": d[2],
               "min": d[3], "max": d[4], "step": d[5], "hint": d[6],
               "def": d[7], "suffix": d[2] == "slider" && String(d[0]).indexOf("ricochet") == 0 && d[0] != "ricochetCount" ? "%" : "",
               "get": makeGetter(mod, d[0]),
               "set": makeSetter(mod, d[0], d[2])
            };
         }
         return items;
      }

      private static function makeGetter(mod:*, k:String):Function
      {
         return function():* { return mod.cfg[k]; };
      }

      public static function buildSmartItems(mod:*):Array
      {
         var defs:Array = [
            ["smartEnabled","智能武器","check",0,0,1,"仅玩家实弹枪/霰弹；默认关闭。关闭立即停止制导。",false,""],
            ["smartMultiLock","多重锁定","check",0,0,1,"视野内敌人同时锁定；子弹轮流分配，霰弹可分散。切换后重新锁定。",false,""],
            ["smartRadius","准星锁定容差","slider",0,200,4,"仅单目标模式：准星到敌人身体边缘的场景距离；无需双方发现。",48,"px"],
            ["smartAcquire","锁定时间","slider",0.1,3,0.1,"暂停菜单时不计时；可操作时停期间继续计时。",0.6,"秒"],
            ["smartGrace","中断容错时间","slider",0,0.5,0.05,"暂停菜单时不计时；可操作时停期间继续计时。",0.15,"秒"],
            ["smartRetreat","锁定进度回退时间","slider",0.1,3,0.1,"暂停菜单时不计时；可操作时停期间继续计时。",0.6,"秒"],
            ["smartHold","失去目视保持时间","slider",0,3,0.1,"暂停菜单时不计时；可操作时停期间继续计时。",0.6,"秒"],
            ["smartKeepOutOfSight","视野外保持锁定","check",0,0,1,"已锁定目标离开画面或被遮挡时保持当前强度；新目标仍须目视获取。关闭后按原有保持和衰减时间脱锁。",false,""],
            ["smartDecay","脱锁衰减时间","slider",0.1,5,0.1,"暂停菜单时不计时；可操作时停期间继续计时。",1.5,"秒"],
            ["smartRecover","重新目视恢复时间","slider",0.1,3,0.1,"暂停菜单时不计时；可操作时停期间继续计时。",0.4,"秒"],
            ["smartTurn","基础转向速度（°/游戏秒）","slider",90,2880,90,"允许掉头；与半径倍率共同决定转弯能力，弱锁定时降低。",1080,""],
            ["smartTurnRadius","转弯半径倍率","slider",10,200,10,"越小弯越急；100%为原手感。开火时固定，跳弹/回放沿用。",50,"%"],
            ["smartSmooth","平滑弹道","check",0,0,1,"优先较短路线，提前圆滑过弯；紧急时急转补救。开火时固定，跳弹/回放沿用。",false,""],
            ["smartSmoothing","平滑程度","slider",0,100,5,"越高，转弯力度变化越缓；0保留原手感。紧急补救仍受现有转弯能力限制。",50,"%"],
            ["smartLife","制导时限（游戏秒）","slider",0.1,5,0.1,"跳弹不刷新时限；子弹实际推进才计时，到期继续普通飞行。",2,""],
            ["smartHudSize","锁定菱形大小","slider",12,80,2,"菱形的屏幕宽高；越小越紧凑，原大小40。关闭设置后立即生效。",24,"px"]
         ];
         var result:Array=[];
         for each(var d:Array in defs) result.push({key:d[0],label:d[1],kind:d[2],min:d[3],max:d[4],step:d[5],hint:d[6],def:d[7],suffix:d[8],get:makeGetter(mod,d[0]),set:makeSetter(mod,d[0],d[2])});
         return result;
      }

      public static function buildLaserItems(mod:*):Array
      {
         var defs:Array=[
            ["laserEnabled","非致命激光枪","check",0,0,1,"每存档仅赠送一次；关闭会解除当前失明控制。",true,""],
            ["laserDuration","失明时长","slider",0.5,30,0.5,"跟随敌人行动时间，命中刷新而不叠加；首领同规则。",6,"秒"],
            ["laserEye","眼区基础半径","slider",3,10,0.5,"按体型缩放，最终限制在3–10像素；必须从正面射入。",6,"px"],
            ["laserAssist","身体选敌辅助","check",0,0,1,"开火时瞄眼；所指敌人背对或眼部被挡时不转选。关闭后手动瞄准，SATS不受影响。",true,""],
            ["laserBodyRadius","身体外围辅助范围","slider",0,160,4,"站定时准星到身体判定框的最大距离；直接瞄身体仍须通过正面与遮挡检查。",60,"px"],
            ["laserAssistFloor","高速最低范围","slider",10,100,5,"移动只缩小外围范围，直接瞄身体不受影响；默认60像素的50%为30像素。",50,"%"],
            ["laserAssistSpeed","降至最低范围的速度","slider",1,40,0.5,"水平与垂直速度合算；范围随速度线性缩小，达到此速度后保持最低比例。",10,"px/步"],
            ["laserInterval","射击最短间隔","slider",0.1,3,0.1,"半自动：松开后才能再次点射。",0.8,"秒"],
            ["laserMagazine","每匣可射次数","slider",1,30,1,"容量按次数×每发耗弹计算，不赠送弹药。",6,"次"],
            ["laserReload","装填时间","slider",0.5,6,0.1,"本枪的装填时间。",2,"秒"],
            ["laserAmmo","每发电池消耗","slider",1,10,1,"使用原版电池类弹药；固定消耗，不受电池回收专长减免。",2,"份"],
            ["laserAP","SATS基础行动点","slider",1,100,1,"SATS选中敌人自动瞄眼；正面与遮挡条件仍适用。",17,"AP"],
            ["laserDebug","失明命中调试标志","check",0,0,1,"装备本枪时显示开火状态及命中原因，标出命中点与眼区，持续3秒。",false,""]
         ];
         var result:Array=[];
         for each(var d:Array in defs)result.push({key:d[0],label:d[1],kind:d[2],min:d[3],max:d[4],step:d[5],hint:d[6],def:d[7],suffix:d[8],get:makeGetter(mod,d[0]),set:makeSetter(mod,d[0],d[2])});
         return result;
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
