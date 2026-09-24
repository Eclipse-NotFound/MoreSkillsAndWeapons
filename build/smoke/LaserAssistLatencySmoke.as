package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.utils.setTimeout;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
   /** TEST ONLY: reticle entry to eye-ring latency on unchanged production bytes. */
   public class LaserAssistLatencySmoke extends Sprite
   {
      private static var probe:LaserAssistLatencySmoke;
      private var host:*,loader:Loader=new Loader(),domain:ApplicationDomain;
      private var m:*,w:*,wp:*,target:*,geom:Class,hud:*;
      private var baselineLoader:Loader=new Loader(),baseline:Class;
      private var immediate:Boolean=false,inputAt:int=0,inputCost:int=0;
      private var seed:uint=1729;
      private function random():Number {seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed/4294967296;}
      private var frames:int=0,phase:int=0,at:int=0,trial:int=0,startTime:int=0;
      private var started:Boolean=false,done:Boolean=false,log:String="",samples:Array=[];
      public function LaserAssistLatencySmoke() {}
      public static function init(main:*):void {probe=new LaserAssistLatencySmoke();probe.start(main);}
      private function cls(n:String):Class {return domain.getDefinition(n) as Class;}
      private function start(main:*):void
      {
         host=main;
         baselineLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            baseline=baselineLoader.contentLoaderInfo.applicationDomain.getDefinition("MSWLaserGeometry") as Class;
            loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
         });
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](host);
            host.stage.addEventListener(Event.ENTER_FRAME,before,false,2000);
            host.stage.addEventListener(Event.EXIT_FRAME,after);
         });
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void {finish(false,e.text);});
         baselineLoader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/Baseline.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
      }
      private function ok(v:Boolean,text:String):void {if(!v)throw new Error(text);log+="PASS "+text+"\n";}
      private function aim(x:Number,y:Number):void {w.cam.celX=x*w.cam.scaleV+w.cam.vx;w.cam.celY=y*w.cam.scaleV+w.cam.vy;}
      private function before(e:Event):void
      {
         try {
            if(done)return;frames++;if(frames>900)throw new Error("timeout phase="+phase);
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswdazzler"]==null)return;
            if(phase==0) {
               w.gg.controlOn();if(w.gg.atkPoss==0)return;
               if(w.pip.active)w.pip.onoff();w.gui.dialText();w.onPause=false;w.godMode=false;w.catPause=false;
               w.gg.changeWeapon("mswdazzler",true);wp=w.gg.currentWeapon;
               if(wp!==w.invent.weapons["mswdazzler"])return;
               log+="CONFIG enabled="+m.cfg.laserEnabled+" assist="+m.cfg.laserAssist+" nonFront="+m.cfg.laserNonFront+" nonFrontRatio="+m.cfg.laserNonFrontRatio+" radius="+m.cfg.laserBodyRadius+" floor="+m.cfg.laserAssistFloor+" speed="+m.cfg.laserAssistSpeed+"\n";m.cfg.laserEnabled=m.cfg.laserAssist=true;m.cfg.laserNonFront=true;m.cfg.laserDebug=false;m.cfg.smartEnabled=false;
               geom=cls("MSWLaserGeometry");
               for(var x:int=60;x<1400;x+=20)for(var y:int=40;y<600;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;}
               target=w.loc.createUnit("raider",600,340,true);target.fraction=2;target.hp=target.maxhp;target.sost=1;
               target.disabled=target.trigDis=target.npc=target.noAgro=false;target.storona=-1;target.shithp=target.t_emerg=0;
               target.stun=10000;target.fixed=true;target.setPos(600,340);target.actions();target.animate();target.setVisPos();
               w.gg.fixed=true;w.gg.setPos(260,340);w.gg.dx=w.gg.dy=0;w.gg.setVisPos();w.loc.units=[w.gg,target];w.loc.objs=[];w.loc.base=false;target.setCel(w.gg);
               log+="HOST fps="+host.stage.frameRate+" version="+m.cfg.diag.ver+" radius="+m.cfg.laserBodyRadius+" speed="+m.cfg.laserAssistSpeed+"\n";
               phase=1;at=frames;
            }
            if(phase==1) {
               aim(trial%2==0?100:1100,100);
               if(frames-at>=12){phase=2;at=frames;startTime=getTimer();}
            }
            if(phase==2)aim(target.X,target.Y-target.scY/2);
         }catch(err:*){finish(false,err+"\n"+err.getStackTrace());}
      }
      private function after(e:Event):void
      {
         try {
            if(done)return;
            if(phase==3 && inputAt>0) {
               log+="LOW-FPS frameRate="+host.stage.frameRate+" input-to-next-frame-ms="+(getTimer()-inputAt)+" handler-ms="+inputCost+" immediate-ring="+immediate+"\n";
               ok(immediate,"mouse movement updates eye ring before the next slow game frame");
               inputChecks();finish(true,"");return;
            }
            if(phase!=2)return;
            hud=host.getChildByName("MSWLaserHUD");wp.getBulXY();
            var selected:*=geom["assist"](w,wp,m.cfg);
            var ring:Boolean=hud!=null && hud.visible && hud.getBounds(hud).width>0;
            var age:int=frames-at;
            if(ring || age>=30) {
               var eye:Object=geom["eye"](target),hit:Object=geom["castRay"](w,wp.bulX,wp.bulY,Math.atan2(eye.y-wp.bulY,eye.x-wp.bulX),m.cfg.laserEye,2000,w.gg,m.cfg.laserNonFront);
               log+="DIAG hostile="+geom["hostile"](target,w)+" sost="+target.sost+" facing="+target.storona+" fraction="+target.fraction+" playerFraction="+w.gg.fraction+" eye="+eye.x+","+eye.y+" hit="+hit.reason+" unit="+(hit.unit===target)+" actualHit="+hit.eye+" eyeRadius="+m.cfg.laserEye+" equipped="+(w.gg.currentWeapon===wp)+" err="+m.cfg.diag.laserError+"\n";
               samples.push(age);log+="SAMPLE trial="+trial+" frames="+age+" ms="+(getTimer()-startTime)+" selected="+(selected===target)+" ring="+ring+" visible="+target.isVis+" invisible="+target.invis+" display="+target.vis.visible+" aim="+w.celX+","+w.celY+" body="+target.X1+","+target.Y1+","+target.X2+","+target.Y2+" muzzle="+wp.bulX+","+wp.bulY+"\n";
               ok(ring && age<=1,"eye ring appears within the first updated display frame trial="+trial+" delay="+age);
               trial++;if(trial>=6){ok(m.cfg.diag.laserError==null,"no laser callback errors");benchmark();phase=3;host.stage.frameRate=8;
                  aim(100,100);w.celX=100;w.celY=100;m.laser.frame(w);
                  ok(hud.getBounds(hud).width==0,"ring absent before between-frame input");
                  setTimeout(function():void {
                     inputAt=getTimer();
                     host.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE,true,false,
                        target.X*w.cam.scaleV+w.cam.vx,(target.Y-target.scY/2)*w.cam.scaleV+w.cam.vy));
                     immediate=hud.getBounds(hud).width>0;inputCost=getTimer()-inputAt;
                  },30);return;}
               phase=1;at=frames;
            }
         }catch(err:*){finish(false,err+"\n"+err.getStackTrace());}
      }
      private function benchmark():void
      {
         w.celX=target.X;w.celY=target.Y-target.scY/2;
         var all:Array=[w.gg],units:Array=[];
         for(var n:int=0;n<32;n++) {
            var u:*=w.loc.createUnit("raider",650,395,true);u.fraction=2;u.sost=1;u.hp=u.maxhp;
            u.disabled=u.trigDis=u.npc=u.noAgro=false;u.isVis=true;u.invis=false;u.storona=-1;
            u.setPos(650,395);u.actions();u.animate();u.setVisPos();u.storona=-1;u.vis.visible=true;units.push(u);all.push(u);
         }
         all.push(target);w.loc.units=all;
         var selected:*,start:int,oldTimes:Array=[],newTimes:Array=[];
         for(n=0;n<50;n++){geom["assist"](w,wp,m.cfg);baseline["assist"](w,wp,m.cfg);}
         for(var round:int=0;round<10;round++)for(var order:int=0;order<2;order++) {
            var old:Boolean=(round+order)%2==0,c:Class=old?baseline:geom;
            start=getTimer();for(n=0;n<200;n++)selected=c["assist"](w,wp,m.cfg);
            (old?oldTimes:newTimes).push((getTimer()-start)/200);
            if(selected!==target)throw new Error("pointed crowd selection changed");
         }
         stats("baseline crowded selection ms/call",oldTimes);stats("candidate crowded selection ms/call",newTimes);
         ok(selected===target,"crowd preserves directly pointed target");
         var savedCfg:Object={front:m.cfg.laserNonFront,ratio:m.cfg.laserNonFrontRatio,dx:w.gg.dx,dy:w.gg.dy};
         for(var sample:int=0;sample<600;sample++) {
            m.cfg.laserNonFront=sample%2==0;m.cfg.laserNonFrontRatio=(sample%5)*25;
            w.gg.dx=(sample%3)*7;w.gg.dy=(sample%4)*3;
            w.celX=400+random()*450;w.celY=220+random()*160;
            for(n=0;n<units.length;n++) {
               u=units[n];u.setPos(400+random()*450,260+random()*180);u.setVisPos();
               u.storona=random()<.5?-1:1;u.shithp=random()<.1?100:0;
               u.isVis=random()>.1;u.invis=random()<.1;u.vis.visible=random()>.1;
            }
            w.loc.units=sample%2?all.concat().reverse():all;
            if(geom["assist"](w,wp,m.cfg)!==baseline["assist"](w,wp,m.cfg))throw new Error("selection parity sample="+sample);
         }
         ok(true,"600 seeded native crowd scenes preserve original selection with motion, facing, shields, visibility and array order");
         m.cfg.laserNonFront=savedCfg.front;m.cfg.laserNonFrontRatio=savedCfg.ratio;w.gg.dx=savedCfg.dx;w.gg.dy=savedCfg.dy;
         for each(u in units) {
            u.setPos(650,395);u.setVisPos();u.shithp=0;u.invis=false;u.isVis=true;u.vis.visible=true;
            u.fixed=true;u.stun=10000;
         }
         w.loc.units=all;log+="LOW-FPS scene native-enemies="+(all.length-1)+"\n";
      }
      private function stats(name:String,values:Array):void
      {
         var sum:Number=0;for each(var v:Number in values)sum+=v;values.sort(Array.NUMERIC);
         log+="BENCH "+name+" mean="+(sum/values.length).toFixed(3)+" p95-batch="+values[Math.ceil(values.length*.95)-1]+" max-batch="+values[values.length-1]+"\n";
      }
      private function move(x:Number,y:Number):void
      {host.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE,true,false,x*w.cam.scaleV+w.cam.vx,y*w.cam.scaleV+w.cam.vy));}
      private function inputChecks():void
      {
         var x:Number=target.X,y:Number=target.Y-target.scY/2,wx:Number=w.celX,wy:Number=w.celY;
         move(100,100);ok(hud.getBounds(hud).width==0,"move away clears eye ring within input event");
         target.shithp=100;move(x,y);ok(hud.getBounds(hud).width==0,"input preview respects eye shield");target.shithp=0;
         target.vis.visible=false;move(x,y);ok(hud.getBounds(hud).width==0,"input preview respects hidden actor");target.vis.visible=true;
         target.storona=1;m.cfg.laserNonFront=false;move(x,y);ok(hud.getBounds(hud).width==0,"input preview respects front-only rule");m.cfg.laserNonFront=true;
         m.cfg.laserAssist=false;move(x,y);ok(hud.getBounds(hud).width==0,"input preview respects disabled assistance");m.cfg.laserAssist=true;
         move(x,y);ok(hud.getBounds(hud).width>0,"valid target immediately reacquires after restrictions clear");
         ok(w.celX==wx && w.celY==wy,"input preview does not mutate game world cursor");
         ok(m.cfg.diag.laserError==null,"no errors after input preview restrictions");
      }
      private function finish(pass:Boolean,error:String):void
      {
         if(done)return;done=true;host.stage.removeEventListener(Event.ENTER_FRAME,before);host.stage.removeEventListener(Event.EXIT_FRAME,after);
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath("latency-results.txt"),"write");fs.writeUTFBytes(log+(error?"FAIL "+error+"\n":"")+(pass?"PASS laser assist latency":"FAIL laser assist latency")+"\n");fs.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
