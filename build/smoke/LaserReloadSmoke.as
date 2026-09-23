package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFormat;
   /** TEST ONLY: actual save/load, pending equip, shot diagnostics and stage pixels. */
   public class LaserReloadSmoke extends Sprite
   {
      private static var probe:LaserReloadSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,log:String="",started:Boolean=false;
      private var liveTarget:*,liveFrame:int=0, reloadPlayer:*, reloadTick:int=0;
      private var naturalPixels:int=0,naturalFrames:int=0,naturalShots:Number=0;
      public function LaserReloadSmoke() {}
      public static function init(main:*):void {probe=new LaserReloadSmoke();probe.start(main);}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaded);
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function loaded(e:Event):void
      {
         domain=loader.contentLoaderInfo.applicationDomain;
         var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;entry["init"](host);
         timer.addEventListener("timer",tick);timer.start();
      }
      private function ok(value:Boolean,message:String):void {if(!value)throw new Error(message);log+="PASS "+message+"\n";}
      private function tick(e:Event):void
      {
         try {
            ticks++;
            var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class,WC:Class=domain.getDefinition("fe.World") as Class;
            var m:*=entry["testInstance"](),w:*=WC["w"];
            if(ticks>600)throw new Error("game did not become ready");
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswdazzler"]==null)return;
            if(reloadPlayer==null)
            {
               w.gg.changeWeapon("mswdazzler",true);
               w.invent.weapons["mswdazzler"].hold=12;
               w.saveGame(1);reloadPlayer=w.gg;w.comLoad=1;reloadTick=ticks;return;
            }
            if(w.gg===reloadPlayer || ticks-reloadTick<30)return;
            if(liveTarget!=null)
            {
               if(ticks-liveFrame<20)return;
               if(m.laser.blind.remaining(liveTarget)>=5.5 && ticks-liveFrame<150)return;
               ok(m.laser.blind.remaining(liveTarget)>0 && m.laser.blind.remaining(liveTarget)<5.5,"natural battle steps keep blindness and advance its timer");
               ok(liveTarget.vision==0 && liveTarget.celUnit==null,"blinded moving actor cannot reacquire player");
               ok(m.cfg.diag.laserError==null,"no laser errors through natural battle updates");
               ok(Number(m.cfg.diag.laserShots)==naturalShots+1,"unpaused world fires the loaded weapon exactly once");
               ok(naturalFrames>0 && naturalPixels>20,"native beam changes final stage pixels during unpaused gameplay (frames="+naturalFrames+", pixels="+naturalPixels+")");
               finish(true,"");return;
            }
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            for(var x:int=100;x<1300;x+=20)for(var y:int=80;y<420;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=0;tile.water=0;}

            var target:*=w.loc.createUnit("raider",500,320,true);
            target.fraction=2;target.hp=target.maxhp;target.sost=1;target.disabled=target.trigDis=target.npc=target.noAgro=false;
            target.storona=-1;target.shithp=0;target.stun=target.t_emerg=0;target.isVis=true;
            target.setPos(500,320);target.actions();target.setVisPos();target.animate();
            w.gg.setPos(240,320);w.gg.storona=1;w.gg.dx=w.gg.dy=0;w.loc.units=[w.gg,target];w.loc.objs=[];
            m.laser.frame(w);
            var wp:*=w.gg.currentWeapon;
            log+="RELOADED current="+getQualifiedClassName(wp)+" inventory="+getQualifiedClassName(w.invent.weapons["mswdazzler"])+" same="+(wp===w.invent.weapons["mswdazzler"])+" pending="+getQualifiedClassName(w.gg.newWeapon)+"\n";
            ok(wp===w.invent.weapons["mswdazzler"] && w.gg.newWeapon===wp,"loaded current, inventory and pending weapons remain identical");
            ok(!m.cfg.laserDebug,"shot diagnostics default off");
            m.panel.toggleOverlay();m.panel.handleKey(9);m.panel.handleKey(9);m.panel.handleKey(38);m.panel.handleKey(13);
            m.panel.update(w);
            ok(m.cfg.laserDebug,"F6 laser page enables diagnostics");
            m.panel.toggleOverlay();m.panel.update(w);
            var Config:Class=domain.getDefinition("MSWConfig") as Class,fresh:*=new Config();fresh.load();
            ok(fresh.laserDebug,"diagnostics toggle persists through SharedObject reload");
            var setting:Object=null;
            for each(var page:Object in m.settings.api.getPages())if(page.modId=="msw-laser")
               for each(var item:Object in page.items)if(item.key=="laserDebug")setting=item;
            ok(setting!=null && setting.def===false && setting.get()===true,"ModSettings shares the diagnostic switch and default");
            // This visual eye is measured from the native raider sprite, not
            // copied from the production target resolver under test.
            m.cfg.laserAngle=0;
            w.celX=w.gg.celX=target.X-26;w.celY=w.gg.celY=target.Y-68;
            for(var i:int=0;i<20;i++){w.gg.setWeaponPos();wp.step();}
            wp.getBulXY();
            target.setWeaponPos(2);
            log+="NATIVE eye="+target.eyeX+","+target.eyeY+" body="+target.X1+","+target.Y1+","+target.X2+","+target.Y2+" muzzle="+wp.bulX+","+wp.bulY+" facing="+target.storona+" mouth="+target.weaponX+","+target.weaponY+","+target.weaponR+" visual="+getQualifiedClassName(target.vis)+"\n";
            var image:BitmapData=new BitmapData(720,480,false,0x33404C),mat:Matrix=new Matrix(4*target.storona,0,0,4,360,400);
            target.vis.visible=true;image.draw(target.vis,mat);
            var marker:Sprite=new Sprite();marker.graphics.lineStyle(1,0x00FFFF);marker.graphics.drawCircle((target.eyeX-target.X)*4+360,(target.eyeY-target.Y)*4+400,6);
            image.draw(marker);savePNG(image,"native-eye.png");image.dispose();
            wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
            var shots:Number=Number(m.cfg.diag.laserShots||0),hp:Number=target.hp;
            wp.attack();wp.step();m.laser.frame(w);
            log+="SHOT ammo="+wp.hold+" shots="+m.cfg.diag.laserShots+" blind="+m.laser.blind.remaining(target)+" error="+m.cfg.diag.laserError+"\n";
            ok(wp.hold==10 && Number(m.cfg.diag.laserShots)==shots+1,"native equip/attack fires exactly once");
            ok(m.laser.blind.remaining(target)==6 && target.hp==hp,"manual shot at visible eye blinds without damage");
            var beam:*=w.loc.firstObj;while(beam!=null && getQualifiedClassName(beam)!="MSWLaserBeam")beam=beam.nobj;
            ok(beam!=null && beam.vis.parent===w.grafon.visObjs[2],"beam is rendered in the original projectile world layer");
            ok(getQualifiedClassName(beam.vis)==getQualifiedClassName(new wp.vBullet()),"beam uses the native laser-pistol asset");
            var hud:*=w.main.getChildByName("MSWLaserHUD"),status:*=hud.getChildByName("MSWLaserDebugStatus");
            ok(status.visible && status.text.indexOf("已失明 6.0s")>=0,"successful eye hit produces visible blindness debug text");
            var beamImage:BitmapData=new BitmapData(780,150,false,0x33404C);
            beamImage.draw(beam.vis,new Matrix(1,0,0,1,650,70));savePNG(beamImage,"native-laser-beam.png");beamImage.dispose();
            beam.step();ok(Math.abs(beam.vis.alpha-.75)<.001,"native laser fade starts at three-quarter opacity");
            beam.step();beam.step();beam.step();ok(!beam.in_chain && beam.vis.parent==null,"beam removes itself after four game steps");
            var geometry:Class=domain.getDefinition("MSWLaserGeometry") as Class;
            // Actual fire/cast/AI path for each rejection, not synthetic HUD messages.
            m.cfg.laserAngle=0;m.laser.blind.clear();
            target.storona=-1;target.shithp=0;target.setPos(500,320);target.animate();target.setVisPos();
            var eyeDebug:Object=geometry["eye"](target);
            wp.bulX=300;wp.bulY=300;w.gg.celX=500;w.gg.celY=300;m.laser.fire(w,wp);m.laser.frame(w);
            ok(m.cfg.diag.laserLastHit=="body" && status.text.indexOf("身体命中")>=0 && m.laser.blind.remaining(target)==0,"body hit reports no eye contact and does not blind");
            target.storona=1;target.animate();target.setVisPos();eyeDebug=geometry["eye"](target);
            wp.bulX=300;wp.bulY=eyeDebug.y;w.gg.celX=eyeDebug.x;w.gg.celY=eyeDebug.y;m.laser.fire(w,wp);m.laser.frame(w);
            ok(m.cfg.diag.laserLastHit=="back" && status.text.indexOf("非正面")>=0 && m.laser.blind.remaining(target)==0,"backside eye contact is explained without blindness");
            target.storona=-1;target.shithp=50;target.animate();target.setVisPos();eyeDebug=geometry["eye"](target);
            wp.bulX=300;wp.bulY=eyeDebug.y;w.gg.celX=eyeDebug.x;w.gg.celY=eyeDebug.y;m.laser.fire(w,wp);m.laser.frame(w);
            ok(m.cfg.diag.laserLastHit=="shield" && status.text.indexOf("护盾阻挡")>=0 && m.laser.blind.remaining(target)==0,"shield rejection is explained without blindness");
            target.shithp=0;target.noAgro=true;wp.bulX=300;wp.bulY=eyeDebug.y;m.laser.fire(w,wp);m.laser.frame(w);
            ok(m.cfg.diag.laserLastHit=="ineligible" && status.text.indexOf("不受失明影响")>=0,"ineligible unit contact is explained");
            target.noAgro=false;wp.bulX=300;wp.bulY=100;w.gg.celX=800;w.gg.celY=100;m.laser.fire(w,wp);m.laser.frame(w);
            ok(m.cfg.diag.laserLastHit=="miss" && status.text.indexOf("未命中单位")>=0,"empty shot has a diagnostic endpoint");
            m.laser.blind.apply(target,w);setting.set(false);m.laser.frame(w);
            ok(!status.visible,"turning diagnostics off immediately hides debug text");
            var normalLabel:Boolean=false;for(var ni:int=0;ni<hud.numChildren;ni++)
            {var label:*=hud.getChildAt(ni);if(label is TextField && label.visible && label.text.indexOf("失明 ")==0)normalLabel=true;}
            ok(normalLabel,"ordinary blindness countdown remains when diagnostics are off");
            setting.set(true);
            m.laser.blind.clear();target.stay=true;target.dx=target.dy=0;target.animate();
            var eye:Object=geometry["eye"](target);
            var hit:Object=geometry["castRay"](w,300,eye.y,0,6,2000,w.gg);
            log+="STANDING eye="+eye.x+","+eye.y+" bodyTop="+target.Y1+" hit="+hit.eye+"\n";
            ok(hit.eye && hit.unit===target,"standing visual eye works");
            target.exterminate();target=w.loc.createUnit("protect",500,320,true);target.storona=-1;target.shithp=0;target.setPos(500,320);target.actions();target.setVisPos();target.animate();w.loc.units=[w.gg,target];
            hit=geometry["castRay"](w,300,240,0,6,2000,w.gg);
            ok(hit.eye && hit.unit===target,"visible robot sensor above body collision box can be hit");
            target.exterminate();target=w.loc.createUnit("raider",500,320,true);target.storona=-1;target.shithp=0;target.t_emerg=0;target.setPos(500,320);target.actions();target.setVisPos();target.animate();w.loc.units=[w.gg,target];
            // Real gun/assist path after turning and animated movement. Eye
            // geometry was independently checked against sprite pixels above.
            m.cfg.laserAngle=5;
            for(i=0;i<12;i++)
            {
               m.laser.blind.clear();target.storona=i%2?-1:1;target.stay=true;target.dx=i%3?4:0;target.animate();target.setVisPos();
               w.gg.setPos(i%2?240:760,320);w.gg.storona=-target.storona;w.gg.setVisPos();w.gg.dx=w.gg.dy=0;
               eye=geometry["eye"](target);w.celX=w.gg.celX=eye.x;w.celY=w.gg.celY=eye.y+6;
               for(var settle:int=0;settle<15;settle++){w.gg.setWeaponPos();wp.step();}
               wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
               wp.attack();wp.step();m.laser.frame(w);
               ok(m.laser.blind.remaining(target)==6,"native aim assist hits displayed eye after move/turn "+i);
            }
            // Arm the gun, then let the real World/Location loop shoot and
            // inspect the complete stage at EXIT_FRAME, before it is displayed.
            m.laser.clear();target.storona=-1;target.dx=target.dy=0;target.setPos(500,320);target.actions();target.animate();target.setVisPos();
            w.gg.setPos(240,320);w.gg.dx=w.gg.dy=0;w.gg.storona=1;w.gg.setVisPos();
            eye=geometry["eye"](target);w.celX=w.gg.celX=eye.x;w.celY=w.gg.celY=eye.y;
            for(settle=0;settle<15;settle++){w.gg.setWeaponPos();wp.step();}
            wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
            naturalShots=Number(m.cfg.diag.laserShots);wp.attack();
            host.stage.addEventListener(Event.EXIT_FRAME,captureLive);
            w.onPause=false;w.catPause=false;w.gg.ggControl=false;
            liveTarget=target;liveFrame=ticks;timer.start();
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function captureLive(event:Event):void
      {
         try {
            var WC:Class=domain.getDefinition("fe.World") as Class,w:*=WC["w"],beam:*=w.loc.firstObj;
            while(beam!=null && getQualifiedClassName(beam)!="MSWLaserBeam")beam=beam.nobj;
            if(beam==null)return;
            naturalFrames++;
            var st:*=host.stage,a:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0),b:BitmapData=a.clone();
            a.draw(st);beam.vis.visible=false;b.draw(st);beam.vis.visible=true;
            var diff:*=a.compare(b),pixels:int=0;
            if(diff is BitmapData)
            {for(var x:int=0;x<diff.width;x++)for(var y:int=0;y<diff.height;y++)if(diff.getPixel(x,y)!=0)pixels++;diff.dispose();}
            if(pixels>naturalPixels){naturalPixels=pixels;savePNG(a,"live-laser-stage.png");}
            a.dispose();b.dispose();
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function savePNG(b:BitmapData,name:String):void
      {
         var enc:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class,bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         host.stage.removeEventListener(Event.EXIT_FRAME,captureLive);
         timer.stop();var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath("reload-shot.txt"),"write");fs.writeUTFBytes(log+(error?"FAIL "+error+"\n":"")+(pass?"PASS production laser shot":"FAIL production laser shot")+"\n");fs.close();
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(pass?0:1);
      }
   }
}
