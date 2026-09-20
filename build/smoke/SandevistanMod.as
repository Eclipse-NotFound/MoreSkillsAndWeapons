package
{
   import flash.display.Sprite;
   import flash.events.UncaughtErrorEvent;
   /** TEST ONLY: captures errors from sibling loaders in the isolated copy. */
   public class SandevistanMod extends Sprite
   {
      public static function init(main:*):void
      {
         trace("LASER diagnostic handler attached");
         main.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,onError);
      }
      private static function onError(e:UncaughtErrorEvent):void
      {trace("LASER HOST ERROR "+e.error);if(e.error is Error)trace(Error(e.error).getStackTrace());e.preventDefault();}
   }
}
