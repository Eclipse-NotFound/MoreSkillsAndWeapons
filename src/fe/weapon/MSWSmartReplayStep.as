package fe.weapon
{
   import fe.Pt;
   /** Exists ONLY during Sandevistan replay. Its existing player-projectile loop
    * calls this head node before stepping recreated bullets. No damage or visuals.
    * New unique class, not a replacement for any game definition. */
   public class MSWSmartReplayStep extends Pt
   {
      public var owner:*;
      public var explRadius:Number=0;
      private var callback:Function;
      public function MSWSmartReplayStep(player:*,fn:Function)
      { super(); owner=player; callback=fn; }
      override public function step():* { callback(); }
   }
}
