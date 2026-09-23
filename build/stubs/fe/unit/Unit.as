package fe.unit
{
   import flash.display.Bitmap;
   import flash.geom.Rectangle;
   // External declarations only; the host supplies the actual 1.02 class.
   public class Unit
   {
      public function Unit() {}
      internal var aiState:int;
      internal var aiSpok:int;
      internal var aiTCh:int;
      internal var aiNapr:int;
      internal var aiVNapr:int;
      internal var visDamDY:int;
      internal var anims:Array;
      internal var visBmp:Bitmap;
      internal var blitRect:Rectangle;
      public var celUnit:Unit;
      public var priorUnit:Unit;
   }
}
