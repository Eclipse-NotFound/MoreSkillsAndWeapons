package
{
   import fe.Pt;

   /** A head-of-chain callback: Location.step calls it after player.step and
    * before bullets, including bullets born during that same player step. */
   public class MSWSmartStep extends Pt
   {
      private var callback:Function;
      public function MSWSmartStep(fn:Function) { super(); callback = fn; }
      override public function step():* { callback(); }
   }
}
