package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   /** Exact-byte contact regression: real native weapons and enemy actors. */
   public class PointerContactSmoke extends Sprite
   {
      private static var instance:PointerContactSmoke;
      private var host:*,loader:Loader=new Loader(),domain:ApplicationDomain,timer:Timer=new Timer(50);
      private var w:*,m:*,wp:*,target:*,G:Class,started:Boolean=false,ticks:int=0,failures:int=0,log:String="";
      public static function init(main:*):void {instance=new PointerContactSmoke();instance.start(main);}
      public function PointerContactSmoke() {}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            domain=loader.contentLoaderInfo.applicationDomain;domain.getDefinition("MoreSkillsWeaponsMod")["init"](host);
            timer.addEventListener("timer",tick);timer.start();
         });
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
      }
      private function check(v:Boolean,msg:String):void {log+=(v?"PASS ":"FAIL ")+msg+"\n";if(!v)failures++;}
      private function tick(e:Event):void
      {
         try {
            ticks++;w=domain.getDefinition("fe.World")["w"];m=domain.getDefinition("MoreSkillsWeaponsMod")["testInstance"]();
            if(ticks>900)throw new Error("timeout");
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(ticks<90 || w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons.mswlaserpointer==null)return;
            w.gg.controlOn();if(w.gg.atkPoss==0)return;
            if(w.pip.active)w.pip.onoff();w.gui.dialText();w.onPause=true;w.godMode=false;w.catPause=false;
            w.gg.work="";w.gg.t_work=0;w.gg.dx=w.gg.dy=0;w.loc.base=false;
            G=domain.getDefinition("MSWLaserGeometry") as Class;
            m.cfg.laserAssist=false;m.cfg.laserNonFront=false;m.cfg.pointerEnabled=m.cfg.laserEnabled=true;
            w.invent.items.batt.kol=1000;
            for(var x:int=100;x<1400;x+=20)for(var y:int=60;y<480;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;}
            w.loc.objs=[];
            contacts();sweeps();settings();finish();
         }catch(err:*){finish(String(err)+"\n"+err.getStackTrace());}
      }
      private function actor(id:String,shield:Number,back:Boolean=false):void
      {
         m.pointer.stop();m.laser.blind.clear();if(target!=null)target.exterminate();
         target=w.loc.createUnit(id,650,360,true);w.loc.units=[w.gg,target];w.loc.objs=[];
         target.fraction=2;target.hp=target.maxhp;target.sost=1;target.disabled=target.trigDis=target.npc=target.noAgro=false;
         target.storona=back?1:-1;target.shithp=shield;target.t_emerg=target.stun=0;target.isVis=true;
         target.setPos(650,360);target.actions();target.animate();target.setVisPos();
         var eye:Object=G["eye"](target);w.gg.setPos(eye.x-250,eye.y+55);w.gg.storona=1;w.gg.setVisPos();
      }
      private function equip(id:String):void
      {
         if(w.gg.currentWeapon==null || w.gg.currentWeapon.id!=id)w.gg.changeWeapon(id,true);wp=w.gg.currentWeapon;if(wp==null || wp.id!=id)throw new Error("equip failed "+id);
         wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
      }
      private function aim(x:Number,y:Number):void
      {
         w.cam.celX=x*w.cam.scaleV+w.cam.vx;w.cam.celY=y*w.cam.scaleV+w.cam.vy;w.celX=w.gg.celX=x;w.celY=w.gg.celY=y;
         for(var i:int=0;i<12;i++){w.gg.setWeaponPos();wp.step();}wp.getBulXY();
      }
      private function fire(expect:Boolean,label:String,body:Boolean=false,blocked:Boolean=false):void
      {
         var eye:Object=G["eye"](target),hp:Number=target.hp,shield:Number=target.shithp;
         aim(body?target.X:eye.x,body?target.Y-12:eye.y);
         if(blocked)w.loc.objs=[{X1:wp.bulX+40,X2:wp.bulX+50,Y1:60,Y2:470,dead:false,phis:1}];
         var shots:Number=Number(m.cfg.diag.laserShots||0);
         if(wp.id=="mswlaserpointer")
         {m.pointer.prepare(w);wp.step();w.ctr.keyAttack=true;wp.attack();m.pointer.frame(w);check(m.pointer.lit,"pointer actually lit "+label);}
         else
         {wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;wp.attack();wp.step();check(Number(m.cfg.diag.laserShots||0)==shots+1,"native gun actually fired "+label);}
         var blind:Number=m.laser.blind.remaining(target),reason:*=wp.id=="mswlaserpointer"?m.cfg.diag.pointerLastHit:m.cfg.diag.laserLastHit;
         check(expect?blind==6:blind==0,label+" remain="+blind+" reason="+reason);
         check(target.hp==hp && target.shithp==shield,"no health or shield loss "+label);
         m.pointer.stop();m.laser.blind.clear();w.loc.objs=[];
      }
      private function contacts():void
      {
         for each(var weapon:String in ["mswlaserpointer","mswdazzler"])
         {
            for each(var id:String in ["alicorn","bossalicorn"])
            {
               actor(id,0);equip(weapon);fire(true,weapon+" front unshielded "+id);
               actor(id,80);equip(weapon);fire(true,weapon+" front shielded "+id);
               actor(id,80,true);equip(weapon);m.cfg.laserNonFront=false;fire(false,weapon+" rear disabled "+id);
               m.cfg.laserNonFront=true;fire(true,weapon+" rear enabled "+id);
               fire(false,weapon+" body shielded "+id,true);
               fire(false,weapon+" wall shielded "+id,false,true);
               m.cfg.laserNonFront=false;
               if(weapon=="mswdazzler")
               {actor(id,80);equip(weapon);m.cfg.laserAssist=true;fire(true,weapon+" assisted shielded "+id,true);m.cfg.laserAssist=false;}
            }
            actor("raider",80);equip(weapon);fire(false,weapon+" other shield still blocks");
         }
         actor("alicorn",80,true);equip("mswlaserpointer");m.cfg.laserNonFront=true;
         var eye:Object=G["eye"](target);aim(eye.x,eye.y);m.pointer.prepare(w);wp.step();w.ctr.keyAttack=true;wp.attack();m.pointer.frame(w);
         var was:Number=m.laser.blind.remaining(target);m.cfg.laserNonFront=false;m.pointer.prepare(w);wp.step();m.pointer.frame(w);
         check(was==6 && m.laser.blind.remaining(target)==was,"direction off keeps existing blindness");
         var state:*=m.laser.blind.states[target];if(state!=null){state.sources.pointer=0;state.node.step();}
         m.pointer.prepare(w);wp.step();m.pointer.frame(w);check(m.laser.blind.remaining(target)==0,"direction off stops refreshing continuous rear contact");m.pointer.stop();
      }
      private function sweeps():void
      {
         actor("alicorn",80,true);var eye:Object=G["eye"](target);
         var S:Class=domain.getDefinition("MSWPointerSweep") as Class,s:*=new S(),hits:int=0;
         var contact:Function=function(h:Object):void{if(h.unit===target && h.eye)hits++;};
         // New optional argument must apply to both current and interpolated rays.
         s.scan(w,eye.x-200,eye.y,-.25,6,contact,true);s.scan(w,eye.x-200,eye.y,.25,6,contact,true);
         check(hits>0,"rear sweep catches shielded eye between missing endpoints");
         s.reset();hits=0;s.scan(w,eye.x-200,eye.y,-.25,6,contact,false);s.scan(w,eye.x-200,eye.y,.25,6,contact,false);
         check(hits==0,"rear sweep obeys disabled direction");
         w.loc.objs=[{X1:eye.x-100,X2:eye.x-90,Y1:60,Y2:470,dead:false,phis:1}];s.reset();hits=0;
         s.scan(w,eye.x-200,eye.y,-.25,6,contact,true);s.scan(w,eye.x-200,eye.y,.25,6,contact,true);
         check(hits==0,"rear sweep cannot pass actual wall");w.loc.objs=[];
      }
      private function settings():void
      {
         var item:Object;
         for each(var p:Object in m.settings.api.getPages())if(p.modId=="msw-laser")for each(var i:Object in p.items)if(i.key=="laserNonFront")item=i;
         check(item!=null && item.def===false,"existing shared direction switch stays default off");
         item.set(true);var C:Class=domain.getDefinition("MSWConfig") as Class,c:*=new C();c.load();check(c.laserNonFront,"shared switch persists");
         check(m.cfg.diag.pointerError==null && m.cfg.diag.laserError==null,"callbacks have no module errors");
      }
      private function finish(error:String=""):void
      {
         timer.stop();if(error){log+="FAIL "+error+"\n";failures++;}
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath("pointer-results.txt"),"write");fs.writeUTFBytes(log+(failures?"FAIL production pointer":"PASS production pointer")+"\n");fs.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(failures?1:0);
      }
   }
}
