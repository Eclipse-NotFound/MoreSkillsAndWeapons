package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFormat;
   /** TEST ONLY: native turret sensors, actual gun fire and blindness. */
   public class TurretLaserSmoke extends Sprite
   {
      private static var probe:TurretLaserSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100),domain:ApplicationDomain;
      private var ticks:int=0,started:Boolean=false,log:String="",failures:int=0;
      private var w:*,m:*,wp:*,G:Class;
      public function TurretLaserSmoke() {}
      public static function init(main:*):void {probe=new TurretLaserSmoke();probe.start(main);}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaded);
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void{finish(e.text);});
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function loaded(e:Event):void
      {
         domain=loader.contentLoaderInfo.applicationDomain;
         var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;entry["init"](host);
         timer.addEventListener("timer",tick);timer.start();
      }
      private function check(pass:Boolean,message:String):void {log+=(pass?"PASS ":"FAIL ")+message+"\n";if(!pass)failures++;}
      private function tick(e:Event):void
      {
         try {
            ticks++;var E:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class,W:Class=domain.getDefinition("fe.World") as Class;
            m=E["testInstance"]();w=W["w"];
            if(ticks>700)throw new Error("world not ready");if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswdazzler"]==null)return;
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            for(var x:int=80;x<1400;x+=20)for(var y:int=40;y<760;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=0;tile.water=0;}
            w.gg.changeWeapon("mswdazzler",true);m.laser.frame(w);wp=w.gg.currentWeapon;w.gg.dx=w.gg.dy=0;w.loc.objs=[];
            G=domain.getDefinition("MSWLaserGeometry") as Class;
            matrix();finish();
         }catch(err:*){finish(String(err)+"\n"+err.getStackTrace());}
      }
      private function matrix():void
      {
         var ids:Array=["turret","landturret","wturret","armturret","cturret","bossturret","hturret","hturret2"];
         var collage:BitmapData=new BitmapData(1200,560,false,0x26303E);
         for(var i:int=0;i<ids.length;i++)
         {
            var id:String=ids[i],u:*=w.loc.createUnit(id,650,420,true);w.loc.units=[w.gg,u];
            u.t_emerg=u.stun=0;u.isVis=true;u.vis.visible=true;u.setPos(650,420);u.setVisPos();
            log+="ACTOR "+id+" class="+getQualifiedClassName(u)+" fraction="+u.fraction+" hp="+u.hp+" sost="+u.sost+" fixed="+u.fixed+" storona="+u.storona+" body="+u.X1+","+u.Y1+","+u.X2+","+u.Y2+"\n";
            // Expose hidden variants as they are after their emergence animation.
            if(id=="hturret" || id=="hturret2")
            {u.setCel(w.gg);u.alarma();u.vis.osn.gotoAndStop(1);}
            u.currentWeapon.findCel=false;u.currentWeapon.rot=u.currentWeapon.forceRot=Math.PI;u.animate();
            var ex:Object=G["eye"](u),light:*=u.vis.osn.light,lb:*=light.getBounds(light);
            var p:Point=u.vis.globalToLocal(light.localToGlobal(new Point(lb.x+lb.width/2,lb.y+lb.height/2)));
            p=u.vis.transform.matrix.transformPoint(p);
            log+="SENSOR "+id+" resolver="+ex.x+","+ex.y+" displayed="+p.x+","+p.y+" lightBounds="+lb+" frame="+u.vis.osn.currentFrame+" hostile="+G["hostile"](u,w)+"\n";
            var cx:Number=(i%4)*300+150,cy:Number=int(i/4)*280+150;
            collage.draw(u.vis,new Matrix(2,0,0,2,cx,cy));
            var mark:Sprite=new Sprite();mark.graphics.lineStyle(1,0xFFFF00);mark.graphics.drawCircle(cx+(p.x-u.X)*2,cy+(p.y-u.Y)*2,7);
            mark.graphics.lineStyle(1,0x00FFFF);mark.graphics.drawCircle(cx+(ex.x-u.X)*2,cy+(ex.y-u.Y)*2,4);collage.draw(mark);
            var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("Arial",15,0xFFFFFF);label.width=295;label.height=30;label.text=id;collage.draw(label,new Matrix(1,0,0,1,(i%4)*300+8,int(i/4)*280+8));
            for each(var a:Number in [Math.PI,0,Math.PI/2,-Math.PI/2])
            {
               m.laser.clear();u.currentWeapon.rot=u.currentWeapon.forceRot=a;u.currentWeapon.findCel=false;u.animate();
               ex=G["eye"](u);var sx:Number=ex.x+Math.cos(a)*250,sy:Number=ex.y+Math.sin(a)*250;
               w.gg.setPos(sx,sy+40);w.gg.storona=sx<u.X?1:-1;w.gg.dx=w.gg.dy=0;
               w.celX=w.gg.celX=u.X;w.celY=w.gg.celY=(u.Y1+u.Y2)/2;
               m.cfg.laserAssist=true;
               for(var settle:int=0;settle<20;settle++){w.gg.setWeaponPos();wp.step();}
               wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
               var hp:Number=u.hp,shots:Number=Number(m.cfg.diag.laserShots||0);
               wp.attack();wp.step();
               check(wp.hold==10 && Number(m.cfg.diag.laserShots)==shots+1,"native shot fired "+id+" angle="+a);
               check(m.laser.blind.remaining(u)==6 && u.hp==hp,"front sensor body-assisted shot blinds "+id+" angle="+a+" actual="+m.cfg.diag.laserLastHit+" error="+m.cfg.diag.laserError);
               m.laser.clear();
               var rear:Object=G["castRay"](w,ex.x-Math.cos(a)*150,ex.y-Math.sin(a)*150,a,m.cfg.laserEye,400,w.gg);
               check(rear.unit===u && !rear.eye,"rear sensor ray rejected "+id+" angle="+a);
               var allowed:Object=G["castRay"](w,ex.x-Math.cos(a)*150,ex.y-Math.sin(a)*150,a,m.cfg.laserEye,400,w.gg,true);
               check(allowed.unit===u && allowed.eye,"opt-in rear sensor ray accepted "+id+" angle="+a);
               var sideAngle:Number=a+Math.PI/2;
               allowed=G["castRay"](w,ex.x-Math.cos(sideAngle)*150,ex.y-Math.sin(sideAngle)*150,sideAngle,m.cfg.laserEye,400,w.gg,true);
               check(allowed.unit===u && allowed.eye,"opt-in perpendicular sensor ray accepted "+id+" angle="+a);
               m.cfg.laserNonFront=true;
               w.gg.setPos(ex.x-Math.cos(a)*250,ex.y-Math.sin(a)*250+40);w.gg.storona=w.gg.X<u.X?1:-1;
               w.celX=w.gg.celX=u.X;w.celY=w.gg.celY=(u.Y1+u.Y2)/2;
               for(settle=0;settle<20;settle++){w.gg.setWeaponPos();wp.step();}
               wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
               hp=u.hp;shots=Number(m.cfg.diag.laserShots||0);wp.attack();wp.step();
               check(wp.hold==10 && Number(m.cfg.diag.laserShots)==shots+1 && m.laser.blind.remaining(u)==6 && u.hp==hp,"opt-in native rear body shot blinds "+id+" angle="+a+" actual="+m.cfg.diag.laserLastHit);
               m.laser.clear();
               wp.bulX=ex.x-Math.cos(a)*150;wp.bulY=ex.y-Math.sin(a)*150;
               w.celX=w.gg.celX=u.X2+30;w.celY=w.gg.celY=(u.Y1+u.Y2)/2;
               check(G["assist"](w,wp,m.cfg)===u,"turret rear halo accepts 30px regardless of storona "+id+" angle="+a);
               w.celX=w.gg.celX=u.X2+30.01;
               check(G["assist"](w,wp,m.cfg)==null,"turret rear halo rejects beyond 30px "+id+" angle="+a);
               wp.bulX=ex.x+Math.cos(a)*150;wp.bulY=ex.y+Math.sin(a)*150;w.celX=w.gg.celX=u.X2+60;
               check(G["assist"](w,wp,m.cfg)===u,"turret front halo retains 60px at actual barrel heading "+id+" angle="+a);
               m.cfg.laserNonFront=false;
            }
            m.laser.clear();u.currentWeapon.rot=Math.PI;u.animate();ex=G["eye"](u);
            w.gg.setPos(ex.x-250,ex.y+40);w.gg.storona=1;
            w.celX=w.gg.celX=ex.x;w.celY=w.gg.celY=ex.y;m.cfg.laserAssist=false;
            for(settle=0;settle<20;settle++){w.gg.setWeaponPos();wp.step();}
            wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
            hp=u.hp;wp.attack();wp.step();
            check(m.laser.blind.remaining(u)==6 && u.hp==hp,"manual sensor shot blinds without direct damage "+id);
            m.laser.clear();u.shithp=50;
            var shield:Object=G["castRay"](w,ex.x-150,ex.y,0,m.cfg.laserEye,400,w.gg);
            check(shield.unit===u && !shield.eye && shield.reason=="shield","active shield still blocks turret sensor "+id);
            shield=G["castRay"](w,ex.x+150,ex.y,Math.PI,m.cfg.laserEye,400,w.gg,true);
            check(shield.unit===u && !shield.eye && shield.reason=="shield","opt-in rear cannot bypass turret shield "+id);u.shithp=0;
            u.currentWeapon.rot=0;u.currentWeapon.forceRot=0.25;u.currentWeapon.findCel=true;
            var oldVision:Number=u.vision,oldFacing:int=u.storona,panicBefore:Number=Number(m.cfg.diag.laserPanicShots||0);
            m.laser.blind.apply(u,w);
            var s:Object=m.laser.blind.states[u],oldX:Number=u.X;
            if(s!=null)
            {
               s.next=999;s.burst=99;s.angle=Math.PI;u.dx=u.dy=0;u.stay=true;s.node.step();
               check(u.X==oldX && u.dx==0,"blind turret never gains walking movement "+id+" dx="+u.dx+" delta="+(u.X-oldX));
               check(u.celUnit==null && u.vision==0 && m.laser.blind.remaining(u)>0,"blind control step keeps player target cleared "+id);
               check(u.storona==oldFacing,"panic preserves mounting orientation "+id);
               check(Math.abs(G["angle"](u.vis.osn.puha.rotation*Math.PI/180-u.currentWeapon.rot))<0.001,"displayed barrel matches native constrained firing angle "+id);
               // Long control checks pin the fixture, separately from the native
               // non-fixed first step above; the arena has no support tiles.
               u.fixed=true;u.currentWeapon.t_attack=u.currentWeapon.t_reload=u.currentWeapon.t_auto=0;u.currentWeapon.t_prep=20;
               var neverReacquired:Boolean=true;
               for(var frame:int=1;frame<30;frame++)
               {
                  w.gg.setPos(frame%2?180:1100,600);w.gg.dx=w.gg.dy=0;w.loc.step();
                  if(u.celUnit!=null || u.vision!=0)neverReacquired=false;
               }
               check(m.laser.blind.remaining(u)==5 && neverReacquired,"native Location chain consumes one second without reacquiring moved player "+id);
               check(Number(m.cfg.diag.laserPanicShots||0)>panicBefore,"native panic weapon actually fires "+id);
               m.laser.blind.apply(u,w);check(m.laser.blind.remaining(u)==6,"repeat sensor effect refreshes six seconds "+id);
               s.sources.laser=1;s.node.step();s.node.step();
               check(m.laser.blind.remaining(u)==0 && u.vision==oldVision && u.celUnit==null && u.currentWeapon.findCel && u.currentWeapon.forceRot==0.25,"expiry restores perception and weapon targeting without stale target "+id);
            }
            if(id=="hturret" || id=="hturret2")
            {
               u.setNull(true);u.currentWeapon.rot=Math.PI;ex=G["eye"](u);
               var closed:Object=G["castRay"](w,ex.x-150,ex.y,0,m.cfg.laserEye,400,w.gg);
               check(!closed.eye && !m.laser.blind.apply(u,w),"retracted sensor cannot be blinded "+id+" frame="+u.vis.osn.currentFrame);
               closed=G["castRay"](w,ex.x+150,ex.y,Math.PI,m.cfg.laserEye,400,w.gg,true);
               check(!closed.eye,"opt-in rear cannot bypass retracted sensor "+id);
               m.laser.clear();u.setCel(w.gg);u.alarma();u.vis.osn.gotoAndStop(1);u.animate();
               check(m.laser.blind.apply(u,w),"deployed sensor becomes vulnerable again "+id);m.laser.clear();
            }
            u.hack(0);check(!m.laser.blind.apply(u,w),"shutdown turret never awakened "+id);
            m.laser.clear();u.exterminate();
         }
         savePNG(collage,"turret-sensors.png");collage.dispose();
      }
      private function savePNG(b:BitmapData,name:String):void
      {
         var enc:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class,bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();
      }
      private function finish(error:String=""):void
      {
         timer.stop();if(error){log+="FAIL "+error+"\n";failures++;}
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath("turret-shot.txt"),"write");fs.writeUTFBytes(log+(failures==0?"PASS turret laser shot":"FAIL turret laser shot")+"\n");fs.close();
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(failures==0?0:1);
      }
   }
}
