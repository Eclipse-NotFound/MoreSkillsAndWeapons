package
{
   import fe.Pt;
   /** A guard immediately before an original node. The original stays linked,
    * visible, damageable and present in loc.units; only its control step is replaced. */
   public class MSWLaserStep extends Pt
   {
      private var callback:Function;
      public function MSWLaserStep(fn:Function) {super();callback=fn;}
      override public function step():* {callback(this);}
   }
}
