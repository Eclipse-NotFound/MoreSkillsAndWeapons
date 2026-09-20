package
{
   /** 一条跳弹链的设置快照与计数；只在确实生成续弹后推进。 */
   public class MSWRicochet
   {
      public static const LIMIT:int = 100;
      public var count:int = 0;
      private var base:int;
      private var chance:Number;
      private var chanceKeep:Number;
      private var damageKeep:Number;
      private var speedKeep:Number;
      private var resetDistance:Boolean;

      public function MSWRicochet(cfg:MSWConfig)
      {
         base = cfg.ricochetCount;
         chance = cfg.ricochetChance / 100;
         chanceKeep = 1 - cfg.ricochetChanceDecay / 100;
         damageKeep = 1 - cfg.ricochetDamageDecay / 100;
         speedKeep = 1 - cfg.ricochetSpeedDecay / 100;
         resetDistance = cfg.ricochetResetDistance;
      }

      /** null 表示终止；显式 roll 仅供确定性测试，正常调用用 Math.random。 */
      public function plan(damage:Number, speed:Number, roll:Number = NaN):Object
      {
         if(count >= LIMIT || !isFinite(damage) || damage <= 0 || !isFinite(speed) || speed < 1) return null;
         var extra:Boolean = count >= base;
         if(extra)
         {
            if(chance <= 0) return null;
            if(chance < 1 && (isNaN(roll) ? Math.random() : roll) >= chance) return null;
         }
         var scale:Number = extra ? speedKeep : 1;
         var nextDamage:Number = damage * (extra ? damageKeep : 1);
         if(nextDamage <= 0 || speed * scale < 1) return null;
         return {damage: nextDamage, speedScale: scale, extra: extra, resetDistance: resetDistance};
      }

      public function recordBounce():void
      {
         if(count >= base) chance *= chanceKeep;
         count++;
      }
   }
}
