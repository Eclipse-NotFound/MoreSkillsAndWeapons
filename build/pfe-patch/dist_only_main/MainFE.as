package
{
   import fe.*;
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.display.MovieClip;
   import flash.display.StageAlign;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   import flash.system.LoaderContext;
   import flash.ui.ContextMenu;
   import flash.ui.ContextMenuItem;
   import flash.utils.getQualifiedClassName;
   
   /**
    * 分发版 MainFE：只含 MoreSkills&Weapons 的 loader。
    * 由 pfe-patch 流程生成（importScript 定向替换），1.02 基础 pfe 其余类不变。
    */
   public class MainFE extends MovieClip
   {
      
      public var zastavka:MovieClip;
      
      internal var mainMenu:MainMenu;
      
      internal var mswLoader:Loader;
      
      public function MainFE()
      {
         super();
         stage.scaleMode = "noScale";
         stage.align = StageAlign.TOP_LEFT;
         stage.color = 0;
         var _loc1_:ContextMenu = new ContextMenu();
         _loc1_.hideBuiltInItems();
         _loc1_.builtInItems.quality = true;
         contextMenu = _loc1_;
         _loc1_.customItems.push(new ContextMenuItem("Привет!",false,true,false));
         stop();
         addEventListener(Event.ENTER_FRAME,this.onEnterFrameLoader);
      }
      
      internal function onEnterFrameLoader(param1:Event) : *
      {
         var _loc2_:uint = loaderInfo.bytesLoaded;
         var _loc3_:uint = loaderInfo.bytesTotal;
         if(this.zastavka.alpha < 1)
         {
            this.zastavka.alpha += 0.05;
         }
         this.zastavka.progres.text = "Loading " + Math.round(_loc2_ / _loc3_ * 100) + "%";
         if(_loc2_ >= _loc3_)
         {
            this.zastavka.visible = false;
            removeEventListener(Event.ENTER_FRAME,this.onEnterFrameLoader);
            nextFrame();
            this.mainMenu = new MainMenu(this);
            this.loadMSWMod();
         }
      }
      
      internal function loadMSWMod() : *
      {
         var _loc1_:LoaderContext;
         trace("MSWMod: load start");
         try
         {
            this.mswLoader = new Loader();
            _loc1_ = new LoaderContext(false);
            this.mswLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onMSWModLoaded);
            this.mswLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.onMSWModError);
            this.mswLoader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),_loc1_);
            trace("MSWMod: load issued");
         }
         catch(err:*)
         {
            trace("MSWMod: load threw " + err);
         }
      }
      
      internal function onMSWModError(param1:IOErrorEvent) : *
      {
         trace("MSWMod: IOError " + param1.text);
      }
      
      internal function onMSWModLoaded(param1:Event) : *
      {
         var _loc2_:*;
         trace("MSWMod: complete fired");
         try
         {
            _loc2_ = LoaderInfo(param1.currentTarget).applicationDomain.getDefinition("MoreSkillsWeaponsMod");
            trace("MSWMod: class=" + _loc2_);
            _loc2_.init(this);
            trace("MSWMod: init returned");
         }
         catch(err:*)
         {
            trace("MSWMod load/init error: " + err);
         }
      }
   }
}
