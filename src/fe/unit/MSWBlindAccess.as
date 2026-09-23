package fe.unit
{
   /** Keep the small amount of host-internal access isolated and version-tested. */
   public class MSWBlindAccess
   {
      public static function scriptStopped(target:*):Boolean
      {
         if(target is UnitRaider && !target.controlOn)return true;
         try {if(target.sleep===true)return true;}catch(e:*) {}
         return false;
      }
      public static function clearTarget(target:*,alert:Boolean=true):void
      {
         var u:Unit=target as Unit;
         u.celUnit=u.priorUnit=null;
         u.aiState=alert?2:0; u.aiTCh=0;
         if(alert) u.aiSpok=Math.max(u.aiSpok,Number(target.maxSpok));
         if(u is UnitRaider) { UnitRaider(u).celUnit2=null; UnitRaider(u).t_chCel=0; UnitRaider(u).tstor=target.storona; }
      }
      public static function state(target:*):int { return Unit(target).aiState; }
      public static function pose(target:*):Object
      {
         var u:Unit=target as Unit;
         if(u==null || u.visBmp==null || u.anims==null || u.anims[target.animState]==null)return null;
         // animate() blits first and advances anim.f afterwards. Read the
         // rectangle that was actually rendered, not the next animation frame.
         var r:*=u.blitRect;
         if(r==null || r.width<=0 || r.height<=0)return null;
         return {id:int(r.y/r.height),frame:int(r.x/r.width),x:u.visBmp.x,y:u.visBmp.y};
      }
      public static function facing(target:*,direction:int):void
      {
         target.storona=direction;
         var u:Unit=target as Unit;u.aiNapr=direction;u.aiVNapr=0;
         if(u is UnitRaider)UnitRaider(u).tstor=direction;
      }
      public static function finish(target:*):void
      {Unit(target).visDamDY=0;if(target.sndRunOn && target.sndRun && target.loc.active)target.sndRunPlay();}
   }
}
