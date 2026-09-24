package
{
   import flash.display.Sprite;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   /** Exact production bytes, native Box objects and native weapon callbacks. */
   public class LaserPropSmoke extends Sprite
   {
      private static var instance:LaserPropSmoke;
      private var host:*,loader:Loader=new Loader(),domain:ApplicationDomain,timer:Timer=new Timer(50);
      private var w:*,m:*,wp:*,target:*,prop:*,G:Class,started:Boolean=false,ticks:int=0,failures:int=0,log:String="";
      public static function init(main:*):void {instance=new LaserPropSmoke();instance.start(main);}
      public function LaserPropSmoke() {}
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
            if(ticks>900)throw new Error("timeout");if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(ticks<90 || w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons.mswlaserpointer==null)return;
            w.gg.controlOn();if(w.gg.atkPoss==0)return;
            if(w.pip.active)w.pip.onoff();w.gui.dialText();w.onPause=true;w.godMode=false;w.catPause=false;
            w.gg.work="";w.gg.t_work=0;w.gg.dx=w.gg.dy=0;w.loc.base=false;
            G=domain.getDefinition("MSWLaserGeometry") as Class;
            m.cfg.laserAssist=false;m.cfg.laserNonFront=false;m.cfg.pointerEnabled=m.cfg.laserEnabled=true;
            w.invent.items.batt.kol=1000;
            for(var x:int=80;x<1400;x+=20)for(var y:int=40;y<760;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;}
            target=w.loc.createUnit("raider",750,400,true);w.loc.units=[w.gg,target];w.loc.objs=[];
            target.fraction=2;target.hp=target.maxhp;target.sost=1;target.storona=-1;target.shithp=target.t_emerg=target.stun=0;target.isVis=true;
            target.setPos(750,400);target.actions();target.animate();target.setVisPos();
            var eye:Object=G["eye"](target);w.gg.setPos(eye.x-450,eye.y+55);w.gg.storona=1;w.gg.setVisPos();
            props();
            if("pointerBlockObjects" in m.cfg){obstacles();sweeps();settings();}
            else check(false,"pointer obstruction setting exists");
            check(!m.cfg.diag.laserError && !m.cfg.diag.pointerError,"production callbacks remain error free");finish();
         }catch(err:*){finish(String(err)+"\n"+err.getStackTrace());}
      }
      private function equip(id:String):void
      {
         m.pointer.stop();m.laser.blind.clear();
         if(w.gg.currentWeapon==null || w.gg.currentWeapon.id!=id)w.gg.changeWeapon(id,true);wp=w.gg.currentWeapon;
         if(wp==null || wp.id!=id)throw new Error("equip failed "+id);
         wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
      }
      private function aim(body:Boolean=false):void
      {
         var e:Object=G["eye"](target),x:Number=body?target.X:e.x,y:Number=body?target.Y-12:e.y;
         w.cam.celX=x*w.cam.scaleV+w.cam.vx;w.cam.celY=y*w.cam.scaleV+w.cam.vy;w.celX=w.gg.celX=x;w.celY=w.gg.celY=y;
         for(var i:int=0;i<16;i++){w.gg.setWeaponPos();wp.step();}wp.getBulXY();
      }
      private function makeProp(id:String):void
      {
         var B:Class=domain.getDefinition("fe.loc.Box") as Class,e:Object=G["eye"](target);
         prop=new B(w.loc,id,520,int(e.y+20));
         if(prop.door==0)
         {
            var delta:Number=e.y-(prop.Y1+prop.Y2)/2;
            prop.Y+=delta;prop.Y1+=delta;prop.Y2+=delta;prop.runVis();
         }
         w.loc.objs=[prop];
      }
      private function fire(expect:Boolean,label:String,body:Boolean=false):void
      {
         m.pointer.stop();m.laser.blind.clear();aim(body);
         var hp:Number=target.hp,boxHP:Number=prop==null?0:prop.hp,shots:Number=Number(m.cfg.diag.laserShots||0);
         if(wp.id=="mswlaserpointer")
         {m.pointer.prepare(w);wp.step();w.ctr.keyAttack=true;wp.attack();m.pointer.frame(w);check(m.pointer.lit,"pointer lights "+label);}
         else
         {wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;wp.attack();wp.step();check(Number(m.cfg.diag.laserShots||0)==shots+1 && wp.hold==10,"gun fires and consumes two batteries "+label);}
         var blind:Number=m.laser.blind.remaining(target),reason:*=wp.id=="mswlaserpointer"?m.cfg.diag.pointerLastHit:m.cfg.diag.laserLastHit;
         check(expect?blind==6:blind==0,label+" remain="+blind+" reason="+reason);
         check(target.hp==hp && (prop==null || prop.hp==boxHP),"no health or prop damage "+label);
         if(wp.id=="mswlaserpointer")
         {
            var beam:*=w.grafon.visObjs[2].getChildByName("MSWPointerBeam"),edge:Number=beam.getBounds(beam.parent).right;
            check(expect?edge>target.X1:edge<target.X1,"visible pointer endpoint follows collision result "+label);
         }
         m.pointer.stop();m.laser.blind.clear();
      }
      private function props():void
      {
         for each(var id:String in ["bigbox","bigbox2","box","woodbox","mcrate1","medbox","filecab","chest"])
         {
            makeProp(id);check(prop.phis>0 && prop.door==0 && !prop.dead,"native solid prop fixture "+id);
            equip("mswdazzler");fire(true,"gun passes "+id);
            m.cfg.laserAssist=true;fire(true,"body assistance passes "+id,true);m.cfg.laserAssist=false;
            equip("mswlaserpointer");fire(true,"pointer default passes "+id);
            if("pointerBlockObjects" in m.cfg)
            {
               m.cfg.pointerBlockObjects=true;fire(false,"pointer optional block "+id);
               equip("mswdazzler");fire(true,"pointer option does not affect gun "+id);m.cfg.pointerBlockObjects=false;
            }
            w.loc.objs=[];
         }
      }
      private function obstacles():void
      {
         for each(var id:String in ["door2","window1","window2"])
         {
            makeProp(id);check(prop.door>0 && prop.tiles.length>0,"native door/window installs collision tiles "+id);
            var glass:Boolean=id=="window1" || id=="window2";
            equip("mswdazzler");fire(glass,"closed door blocks / glass transmits gun "+id);
            for each(var block:Boolean in [false,true])
            {
               m.cfg.pointerBlockObjects=block;equip("mswlaserpointer");fire(glass,"closed door blocks / glass transmits pointer "+id+" option="+block);
            }
            if(glass)
            {
               var rearWall:Array=LaserTestWall.put(w.loc,620,640,40,700);
               equip("mswdazzler");fire(false,"wall behind glass blocks gun "+id);equip("mswlaserpointer");fire(false,"wall behind glass blocks pointer "+id);LaserTestWall.restore(rearWall);
               var blocker:*=w.loc.createUnit("raider",650,400,true);blocker.setPos(650,400);blocker.t_emerg=0;w.loc.units=[w.gg,blocker,target];
               equip("mswdazzler");fire(false,"first body behind glass blocks gun "+id);equip("mswlaserpointer");fire(false,"first body behind glass blocks pointer "+id);
               blocker.exterminate();w.loc.units=[w.gg,target];
            }
            prop.setDoor(true);
            equip("mswdazzler");fire(true,"open map object passes gun "+id);
            equip("mswlaserpointer");fire(true,"open map object passes even with pointer prop blocking "+id);
            for each(var t:* in prop.tiles){t.phis=0;t.door=null;}w.loc.objs=[];
         }
         prop=null;m.cfg.pointerBlockObjects=false;
         var solid:Array=LaserTestWall.put(w.loc,500,540,40,700);
         equip("mswdazzler");fire(false,"solid terrain blocks gun");equip("mswlaserpointer");fire(false,"solid terrain blocks pointer");LaserTestWall.restore(solid);
         makeProp("bigbox");equip("mswdazzler");aim();
         var Sats:Class=domain.getDefinition("fe.inter.SatsCel") as Class,q:*=new Sats({u:target,n:0},0,0,17);
         w.gg.sats.que.push(q);fire(true,"SATS selected eye ray passes prop");w.gg.sats.que.pop();q.remove();w.loc.objs=[];
      }
      private function sweeps():void
      {
         var S:Class=domain.getDefinition("MSWPointerSweep") as Class,s:*=new S(),e:Object=G["eye"](target),hits:int=0;
         var contact:Function=function(h:Object):void{if(h.unit===target && h.eye)hits++;};makeProp("bigbox");
         for each(var block:Boolean in [false,true])
         {
            s.reset();hits=0;s.scan(w,e.x-400,e.y,-.18,6,contact,false,block);s.scan(w,e.x-400,e.y,.18,6,contact,false,block);
            check(block?hits==0:hits>0,"interpolated sweep obeys prop setting "+block);
         }
         s.reset();hits=0;s.scan(w,e.x-400,e.y,-.18,6,contact,false,true);s.scan(w,e.x-400,e.y,.18,6,contact,false,false);
         check(hits==0,"setting changes do not replay a sweep across old-policy interval");
         equip("mswlaserpointer");aim();m.cfg.pointerBlockObjects=false;m.pointer.prepare(w);wp.step();w.ctr.keyAttack=true;wp.attack();m.pointer.frame(w);
         check(m.pointer.lit && m.laser.blind.remaining(target)==6,"continuous beam initially passes prop");
         m.cfg.pointerBlockObjects=true;m.laser.blind.clear();m.pointer.prepare(w);wp.step();m.pointer.frame(w);
         check(m.pointer.lit && m.laser.blind.remaining(target)==0,"blocking option immediately affects a lit beam");
         m.cfg.pointerBlockObjects=false;m.pointer.prepare(w);wp.step();m.pointer.frame(w);
         check(m.pointer.lit && m.laser.blind.remaining(target)==6,"unblocking immediately resumes eye contact");m.pointer.stop();m.laser.blind.clear();w.loc.objs=[];
      }
      private function find(c:DisplayObjectContainer,name:String):*
      {for(var i:int=0;i<c.numChildren;i++){var child:*=c.getChildAt(i);if(child.name==name)return child;try{if(child.settingsItem!=null && child.settingsItem.key==name)return child;}catch(ignore:*){}if(child is DisplayObjectContainer){var found:*=find(child,name);if(found!=null)return found;}}return null;}
      private function settings():void
      {
         var page:Object,item:Object;for each(var p:Object in m.settings.api.getPages())if(p.modId=="msw-pointer")page=p;
         for each(var i:Object in page.items)if(i.key=="pointerBlockObjects")item=i;
         check(page.items.length==6 && item!=null && item.def===false,"six pointer settings include default-off prop blocking");
         w.pip.onoff(5);m.settings.api.selectPage("msw-pointer");var row:*=find(w.main,"pointerBlockObjects");
         check(row!=null && !row.settingsSc.selected,"real Pip renders default-off checkbox");
         row.settingsSc.selected=true;row.settingsSc.dispatchEvent(new Event(Event.CHANGE,true));
         var C:Class=domain.getDefinition("MSWConfig") as Class,c:*=new C();c.load();
         check(c.pointerBlockObjects && m.cfg.pointerBlockObjects,"Pip checkbox persists to a fresh config instance");
         item.set(false);c=new C();c.load();check(!c.pointerBlockObjects,"off choice persists");w.pip.onoff();
         m.panel.toggleOverlay();for(var n:int=0;n<4;n++)m.panel.handleKey(9);m.panel.update(w);
         check(find(w.main,"MSWF6Panel").text.indexOf("箱柜阻挡光束")>=0,"F6 exposes pointer obstruction option");m.panel.toggleOverlay();
         item.set(true);for each(i in page.items)i.set(i.def);c=new C();c.load();check(!c.pointerBlockObjects,"restore defaults returns to unblocked props");
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
