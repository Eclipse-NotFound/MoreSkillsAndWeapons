package
{
   /** Lock acquisition and signal strength. dt is active player time, never bullet time. */
   public class MSWSmartLock
   {
      public var target:* = null;
      public var candidate:* = null;
      public var progress:Number = 0;
      public var strength:Number = 0;
      public var lost:Number = 0;
      private var interrupted:Number = 0;
      public function MSWSmartLock() {}
      public function clear():void
      { target=null; candidate=null; progress=0; strength=0; lost=0; interrupted=0; }
      public function advance(choice:*, visible:Boolean, dt:Number, c:*):void
      {
         if(target != null)
         {
            if(visible) { lost=0; strength=Math.min(1,strength+dt/c.smartRecover); }
            else if(c.smartKeepOutOfSight)
            {
               // Only an existing lock is retained. An unfinished candidate
               // still uses the normal interrupted-acquisition fade below.
               lost=0;
            }
            else
            {
               var old:Number=lost; lost+=dt;
               var decay:Number=Math.max(0,lost-c.smartHold)-Math.max(0,old-c.smartHold);
               strength=Math.max(0,strength-decay/c.smartDecay);
               if(strength<=0) { target=null; lost=0; }
            }
         }
         if(choice != null && choice !== target)
         {
            if(choice !== candidate) { candidate=choice; progress=0; }
            interrupted=0;
            progress=Math.min(1,progress+dt/c.smartAcquire);
            if(progress>=1-0.000001)
            { target=candidate; candidate=null; progress=0; strength=1; lost=0; }
         }
         else if(candidate != null)
         {
            old=interrupted; interrupted+=dt;
            var fade:Number=Math.max(0,interrupted-c.smartGrace)-Math.max(0,old-c.smartGrace);
            progress=Math.max(0,progress-fade/c.smartRetreat);
            if(progress<=0) { candidate=null; interrupted=0; }
         }
      }
   }
}
