package
{
   import flash.net.SharedObject;

   /**
    * 模组设置：SharedObject 持久化（无需 AIR File API，见 decisions D-008）。
    */
   public class MSWConfig
   {
      /** 跳弹技能独立开关（尚未接入游戏技能系统） */
      public var ricochet:Boolean = false;

      /** 跳弹链首次登记时快照；百分比均为 0..100 的整数。 */
      public var ricochetCount:int = 1;
      public var ricochetChance:Number = 0;
      public var ricochetChanceDecay:Number = 0;
      public var ricochetDamageDecay:Number = 0;
      public var ricochetSpeedDecay:Number = 0;
      public var ricochetResetDistance:Boolean = true;

      public var smartEnabled:Boolean = false;
      public var smartMultiLock:Boolean = false;
      public var smartKeepOutOfSight:Boolean = false;
      public var smartRadius:Number = 48;
      public var smartAcquire:Number = 0.6;
      public var smartGrace:Number = 0.15;
      public var smartRetreat:Number = 0.6;
      public var smartHold:Number = 0.6;
      public var smartDecay:Number = 1.5;
      public var smartRecover:Number = 0.4;
      public var smartTurn:Number = 1080;
      public var smartTurnRadius:Number = 50;
      public var smartSmooth:Boolean = false;
      public var smartSmoothing:Number = 50;
      public var smartLife:Number = 2;
      public var smartHudSize:Number = 24;

      public var laserEnabled:Boolean = true;
      public var laserDebug:Boolean = false;
      public var laserDuration:Number = 6;
      public var laserEye:Number = 6;
      public var laserRadius:Number = 40;
      public var laserAngle:Number = 5;
      public var laserSpeed:Number = 10;
      public var laserInterval:Number = 0.8;
      public var laserMagazine:Number = 6;
      public var laserReload:Number = 2;
      public var laserAmmo:Number = 2;
      public var laserAP:Number = 17;
      private static const LASER_KEYS:Array=["laserEnabled","laserDebug","laserDuration","laserEye","laserRadius","laserAngle","laserSpeed","laserInterval","laserMagazine","laserReload","laserAmmo","laserAP"];

      /** 可编程榴弹炮下坠速率 = weapon.grav（1.0 = 原版，0 = 无下坠） */
      public var dropRate:Number = 1.0;

      /** 爆炸前撞墙次数（0 = 撞墙即爆，与原版一致） */
      public var wallHits:int = 0;

      /** 炮口初速度 = weapon.speed（px/世界步；glau 原版 35） */
      public var muzzleVel:int = 35;

      /** 反弹力度（弹性系数 0..1；0.4 = 原版手雷 skok，0 = 贴墙滑落） */
      public var bounce:Number = 0.4;

      /** 蹲姿/梯子举枪技能（独立开关，尚未接入游戏技能系统） */
      public var aimSkill:Boolean = false;

      // ---- 2026-08-17 自 Sandevistan 迁移（MSWProjHits / MSWSwaprun）----
      // 原配置键：projhits/projhp/projarmor/projhp_<id>/projarmor_<id>/swaprun
      // （Sandevistan config.txt）。MSW 无 config.txt，改 SharedObject 持久化；
      // 按武器覆盖项（projhp_<id>）无 UI 入口，保留字段供存档/调试注入。
      /** 手雷击落：投掷物（手雷/导弹/榴弹）受击至血量归零直接爆炸 */
      public var projHits:Boolean = true;

      /** 投掷物血量（原 projhp，默认 30） */
      public var projHp:Number = 30;

      /** 投掷物护甲（原 projarmor，默认 0=预留接口：伤害先减护甲） */
      public var projArmor:Number = 0;

      /** 按武器 id 的血量覆盖（原 projhp_<id>；无 UI，存档/调试注入用） */
      public var projHpOver:Object = null;

      /** 按武器 id 的护甲覆盖（原 projarmor_<id>；无 UI，存档/调试注入用） */
      public var projArmorOver:Object = null;

      /** 疾跑（按住 Shift）中数字键切第一组快捷槽（原 swaprun） */
      public var swapRun:Boolean = true;

      /** 散布恒定（mswglau）：每帧 hp=maxhp → breaking=0 → 散布不随磨损增大（D-034） */
      public var spreadFix:Boolean = true;

      /** 魔法冲刺保持趴姿：趴着（lurked）施放 sp_kdash 后保持趴姿（D-037） */
      public var dashKeepPose:Boolean = true;

      private var so:SharedObject = null;

      public function MSWConfig()
      {
         super();
      }

      public function load():void
      {
         try
         {
            so = SharedObject.getLocal("MSWConfig");
            for each(var laserKey:String in LASER_KEYS)if(so.data[laserKey]!==undefined)this[laserKey]=so.data[laserKey];
            if(so.data.ricochet != undefined) ricochet = so.data.ricochet;
            if(so.data.smartEnabled != undefined) smartEnabled = so.data.smartEnabled;
            if(so.data.smartMultiLock != undefined) smartMultiLock = so.data.smartMultiLock == true;
            if(so.data.smartKeepOutOfSight != undefined) smartKeepOutOfSight = so.data.smartKeepOutOfSight == true;
            if(so.data.smartRadius != undefined) smartRadius = so.data.smartRadius;
            if(so.data.smartAcquire != undefined) smartAcquire = so.data.smartAcquire;
            if(so.data.smartGrace != undefined) smartGrace = so.data.smartGrace;
            if(so.data.smartRetreat != undefined) smartRetreat = so.data.smartRetreat;
            if(so.data.smartHold != undefined) smartHold = so.data.smartHold;
            if(so.data.smartDecay != undefined) smartDecay = so.data.smartDecay;
            if(so.data.smartRecover != undefined) smartRecover = so.data.smartRecover;
            if(so.data.smartTurn != undefined) smartTurn = so.data.smartTurn;
            if(so.data.smartTurnRadius != undefined) smartTurnRadius = so.data.smartTurnRadius;
            if(so.data.smartSmooth != undefined) smartSmooth = so.data.smartSmooth == true;
            if(so.data.smartSmoothing != undefined) smartSmoothing = so.data.smartSmoothing;
            if(so.data.smartLife != undefined) smartLife = so.data.smartLife;
            if(so.data.smartHudSize != undefined) smartHudSize = so.data.smartHudSize;
            if(so.data.ricochetCount != undefined) ricochetCount = so.data.ricochetCount;
            if(so.data.ricochetChance != undefined) ricochetChance = so.data.ricochetChance;
            if(so.data.ricochetChanceDecay != undefined) ricochetChanceDecay = so.data.ricochetChanceDecay;
            if(so.data.ricochetDamageDecay != undefined) ricochetDamageDecay = so.data.ricochetDamageDecay;
            if(so.data.ricochetSpeedDecay != undefined) ricochetSpeedDecay = so.data.ricochetSpeedDecay;
            if(so.data.ricochetResetDistance != undefined) ricochetResetDistance = so.data.ricochetResetDistance;
            if(so.data.dropRate != undefined) dropRate = so.data.dropRate;
            if(so.data.wallHits != undefined) wallHits = so.data.wallHits;
            if(so.data.muzzleVel != undefined) muzzleVel = so.data.muzzleVel;
            if(so.data.bounce != undefined) bounce = so.data.bounce;
            if(so.data.aimSkill != undefined) aimSkill = so.data.aimSkill;
            // 迁移自 Sandevistan（2026-08-17）
            if(so.data.projHits != undefined) projHits = so.data.projHits;
            if(so.data.projHp != undefined) projHp = so.data.projHp;
            if(so.data.projArmor != undefined) projArmor = so.data.projArmor;
            if(so.data.projHpOver != undefined) projHpOver = so.data.projHpOver;
            if(so.data.projArmorOver != undefined) projArmorOver = so.data.projArmorOver;
            if(so.data.swapRun != undefined) swapRun = so.data.swapRun;
            if(so.data.spreadFix != undefined) spreadFix = so.data.spreadFix;
            if(so.data.dashKeepPose != undefined) dashKeepPose = so.data.dashKeepPose;
         }
         catch(e:*)
         {
            so = null;
         }
         clamp();
         diagInit();
      }

      // ---------------- 诊断（写入 SharedObject，便于排查） ----------------

      public var diag:Object = null;

      public function diagInit():void
      {
         try
         {
            if(so == null) so = SharedObject.getLocal("MSWConfig");
            diag = so.data.diag;
            if(diag == null) diag = new Object();
         }
         catch(e:*)
         {
            diag = null;
         }
      }

      public function diagAdd(k:String):void
      {
         if(diag == null) return;
         if(diag[k] == null || isNaN(Number(diag[k]))) diag[k] = 0;
         diag[k] = Number(diag[k]) + 1;
      }

      public function diagSet(k:String, v:*):void
      {
         if(diag != null) diag[k] = v;
      }

      public function diagFlush():void
      {
         try
         {
            if(so == null || diag == null) return;
            so.data.diag = diag;
            so.flush();
         }
         catch(e:*)
         {
         }
      }

      public function save():void
      {
         try
         {
            if(so == null) so = SharedObject.getLocal("MSWConfig");
            for each(var laserKey:String in LASER_KEYS)so.data[laserKey]=this[laserKey];
            so.data.ricochet = ricochet;
            so.data.smartEnabled = smartEnabled;
            so.data.smartMultiLock = smartMultiLock;
            so.data.smartKeepOutOfSight = smartKeepOutOfSight;
            so.data.smartRadius = smartRadius;
            so.data.smartAcquire = smartAcquire;
            so.data.smartGrace = smartGrace;
            so.data.smartRetreat = smartRetreat;
            so.data.smartHold = smartHold;
            so.data.smartDecay = smartDecay;
            so.data.smartRecover = smartRecover;
            so.data.smartTurn = smartTurn;
            so.data.smartTurnRadius = smartTurnRadius;
            so.data.smartSmooth = smartSmooth;
            so.data.smartSmoothing = smartSmoothing;
            so.data.smartLife = smartLife;
            so.data.smartHudSize = smartHudSize;
            so.data.ricochetCount = ricochetCount;
            so.data.ricochetChance = ricochetChance;
            so.data.ricochetChanceDecay = ricochetChanceDecay;
            so.data.ricochetDamageDecay = ricochetDamageDecay;
            so.data.ricochetSpeedDecay = ricochetSpeedDecay;
            so.data.ricochetResetDistance = ricochetResetDistance;
            so.data.dropRate = dropRate;
            so.data.wallHits = wallHits;
            so.data.muzzleVel = muzzleVel;
            so.data.bounce = bounce;
            so.data.aimSkill = aimSkill;
            // 迁移自 Sandevistan（2026-08-17）
            so.data.projHits = projHits;
            so.data.projHp = projHp;
            so.data.projArmor = projArmor;
            so.data.projHpOver = projHpOver;
            so.data.projArmorOver = projArmorOver;
            so.data.swapRun = swapRun;
            so.data.spreadFix = spreadFix;
            so.data.dashKeepPose = dashKeepPose;
            so.flush();
         }
         catch(e:*)
         {
         }
      }

      public function clamp():void
      {
         laserDuration=smartClamp(laserDuration,6,0.5,30,0.5);
         laserEye=smartClamp(laserEye,6,3,10,0.5);
         laserRadius=smartClamp(laserRadius,40,0,160,4);
         laserAngle=smartClamp(laserAngle,5,0,20,0.5);
         laserSpeed=smartClamp(laserSpeed,10,1,40,0.5);
         laserInterval=smartClamp(laserInterval,0.8,0.1,3,0.1);
         laserMagazine=smartClamp(laserMagazine,6,1,30,1);
         laserReload=smartClamp(laserReload,2,0.5,6,0.1);
         laserAmmo=smartClamp(laserAmmo,2,1,10,1);
         laserAP=smartClamp(laserAP,17,1,100,1);
         smartRadius = smartClamp(smartRadius,48,0,200,4);
         smartAcquire = smartClamp(smartAcquire,0.6,0.1,3,0.1);
         smartGrace = smartClamp(smartGrace,0.15,0,0.5,0.05);
         smartRetreat = smartClamp(smartRetreat,0.6,0.1,3,0.1);
         smartHold = smartClamp(smartHold,0.6,0,3,0.1);
         smartDecay = smartClamp(smartDecay,1.5,0.1,5,0.1);
         smartRecover = smartClamp(smartRecover,0.4,0.1,3,0.1);
         smartTurn = smartClamp(smartTurn,1080,90,2880,90);
         smartTurnRadius = smartClamp(smartTurnRadius,50,10,200,10);
         smartSmoothing = smartClamp(smartSmoothing,50,0,100,5);
         smartLife = smartClamp(smartLife,2,0.1,5,0.1);
         smartHudSize = smartClamp(smartHudSize,24,12,80,2);
         ricochetCount = Math.max(0, Math.min(20, ricochetCount));
         ricochetChance = percent(ricochetChance);
         ricochetChanceDecay = percent(ricochetChanceDecay);
         ricochetDamageDecay = percent(ricochetDamageDecay);
         ricochetSpeedDecay = percent(ricochetSpeedDecay);
         dropRate = Math.round(dropRate * 10) / 10;
         if(dropRate < 0) dropRate = 0;
         if(dropRate > 3) dropRate = 3;
         wallHits = Math.round(wallHits);
         if(wallHits < 0) wallHits = 0;
         if(wallHits > 5) wallHits = 5;
         muzzleVel = Math.round(muzzleVel);
         if(muzzleVel < 10) muzzleVel = 10;
         if(muzzleVel > 100) muzzleVel = 100;
         bounce = Math.round(bounce * 10) / 10;
         if(bounce < 0) bounce = 0;
         if(bounce > 1) bounce = 1;
         // 迁移自 Sandevistan：投掷物血量/护甲钳制（原 config 解析中的钳制）
         projHp = Math.round(projHp);
         if(projHp < 1) projHp = 1;
         if(projHp > 1000) projHp = 1000;
         projArmor = Math.round(projArmor);
         if(projArmor < 0) projArmor = 0;
         if(projArmor > 500) projArmor = 500;
      }

      private function percent(v:Number):Number
      {
         return isFinite(v) ? Math.max(0, Math.min(100, Math.round(v))) : 0;
      }

      private function smartClamp(v:Number, def:Number, lo:Number, hi:Number, step:Number):Number
      { return !isFinite(v) ? def : Math.round(Math.max(lo,Math.min(hi,Math.round(v/step)*step))*1000)/1000; }
   }
}
