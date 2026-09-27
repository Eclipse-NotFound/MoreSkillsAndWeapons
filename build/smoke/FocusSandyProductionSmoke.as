package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   /** No MSW implementation is linked into this external production-byte driver. */
   public class FocusSandyProductionSmoke extends Sprite
   {
      private static var loader:Loader;
      private static var probe:FocusSandyProbe;
      public function FocusSandyProductionSmoke() {}
      public static function init(main:*):void
      {
         loader=new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            var domain:ApplicationDomain=loader.contentLoaderInfo.applicationDomain;
            domain.getDefinition("MoreSkillsWeaponsMod")["init"](main);
            probe=new FocusSandyProbe(domain);
         });
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
   }
}
