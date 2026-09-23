package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;

   /** TEST ONLY: independent probe, production classes are loaded unmodified. */
   public class SmoothModeProductionSmoke extends Sprite
   {
      private static var probe:SmoothModeProductionSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(50),domain:ApplicationDomain;
      private var ticks:int=0,log:String="",checks:int=0;
      private var m:*,w:*,weapon:*,target:*,wall:Array=[];
      public function SmoothModeProductionSmoke() {}
      public static function init(main:*):void {probe=new SmoothModeProductionSmoke();probe.start(main);}
      private function cls(name:String):Class {return domain.getDefinition(name) as Class;}
      private function start(main:*):void
      {
         host=main;
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            try {domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](host);timer.addEventListener("timer",tick);timer.start();}
            catch(err:*) {finish(false,String(err)+"\n"+err.getStackTrace());}
         });
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void {finish(false,e.text);});
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function ok(value:Boolean,message:String):void
      {if(!value)throw new Error(message);checks++;log+="PASS "+message+"\n";}
      private function position(x:Number,y:Number):void
      {target.X=x;target.Y=y+20;target.X1=x-12;target.X2=x+12;target.Y1=y-20;target.Y2=y+20;}
      private function spawn(x:Number=220,y:Number=400,dx:Number=20,dy:Number=0):*
      {
         var B:Class=cls("fe.weapon.Bullet"),b:*=new B(w.gg,x,y,cls("visualBullet"),true);
         b.weap=weapon;b.damage=100;b.tipDamage=0;b.precision=10;b.miss=1;
         b.dx=dx;b.dy=dy;b.vel=Math.sqrt(dx*dx+dy*dy);return b;
      }
      private function physics():void
      {
         var b:*=w.loc.firstObj,n:int=0;
         while(b!=null && n++<12000){var next:*=b.nobj;b.step();b=next;}
         if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
      }
      private function clean():void
      {
         var b:*=w.loc.firstObj;
         while(b!=null){var next:*=b.nobj;if(getQualifiedClassName(b)=="fe.weapon::Bullet")w.loc.remObj(b);b=next;}
         m.smart.frame(w);
      }
      private function chase(enabled:Boolean,amount:Number):Object
      {
         clean();m.cfg.smartSmooth=enabled;m.cfg.smartSmoothing=amount;
         position(860,260);m.smart.lock.target=target;m.smart.lock.strength=1;
         var b:*=spawn(),hp:Number=target.hp,result:Object={points:[],peak:0,urgent:0,hit:false};
         var oldAngle:Number=0,oldTurn:Number=0,hasAngle:Boolean=false;
         for(var i:int=0;i<65 && !b.babah;i++)
         {
            if(i==6)position(860,560);
            if(i==12)position(860,260);
            physics();var s:*=m.smart.snapshot(b),points:Array=s.motionPath;
            for(var j:int=1;j<points.length;j++)
            {
               var p:Object=points[j-1],q:Object=points[j];
               var a:Number=Math.atan2(q.y-p.y,q.x-p.x),turn:Number=cls("MSWSmartRoute")["angle"](a-oldAngle);
               if(i<13 && hasAngle)result.peak=Math.max(result.peak,Math.abs(turn-oldTurn));
               hasAngle=true;oldAngle=a;oldTurn=turn;result.points.push({x:q.x,y:q.y});
            }
            result.urgent=s.smoothUrgent==null?0:s.smoothUrgent;
         }
         result.hit=target.hp<hp;result.end={x:b.X,y:b.Y};clean();return result;
      }
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks%100==0)write("heartbeat.txt","ticks="+ticks+"\n"+log);
            if(ticks>1000)throw new Error("timeout");
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active || m.cfg.diag.frames<600)return;
            timer.stop();if(w.verror.visible)throw new Error(w.verror.txt.text);
            ok(m.cfg.diag.ver=="1.9.1-exemption-menu","exact production smooth version loaded");
            ok(!m.cfg.smartSmooth && m.cfg.smartSmoothing==50,"new smooth mode defaults off at 50 percent");
            if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
            for(var x:int=100;x<1400;x+=20)for(var y:int=40;y<760;y+=20){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null){tile.phis=0;tile.water=0;}}
            w.gg.setPos(220,320);w.gg.dx=w.gg.dy=0;
            weapon=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");w.gg.currentWeapon=weapon;
            target=new (cls("fe.unit.Unit"))();target.loc=w.loc;target.fraction=2;target.hp=target.maxhp=1000000;
            target.sost=1;target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;
            w.loc.units=[target];m.cfg.smartEnabled=true;m.cfg.smartTurnRadius=50;m.cfg.smartTurn=1080;
            m.cfg.smartLife=2;m.cfg.ricochet=false;m.cfg.smartMultiLock=false;m.smart.frame(w);
            var traces:Object={};
            traces.off=chase(false,50);traces.zero=chase(true,0);
            ok(JSON.stringify(traces.off.points)==JSON.stringify(traces.zero.points),"zero amount reproduces disabled native trajectory exactly");
            traces.medium=chase(true,50);traces.high=chase(true,100);
            write("smooth-traces.json",JSON.stringify(traces));
            log+="CURVATURE off="+traces.off.peak+" medium="+traces.medium.peak+" high="+traces.high.peak+"\n";
            ok(traces.medium.peak<traces.off.peak*0.8 && traces.high.peak<traces.medium.peak,"native moving-target turn-rate jumps decrease with smoothing");
            ok(traces.off.hit && traces.medium.hit && traces.high.hit,"moving target is actually damaged at all compared settings");
            // Native solid-box detour. Record the complete path, including urgent recovery.
            position(520,240);
            for(x=320;x<400;x+=40)for(y=200;y<280;y+=40){tile=w.loc.getAbsTile(x+1,y+1);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=y;tile.phY2=y+40;wall.push(tile);}
            for each(var amount:Number in [0,50,100])
            {
               m.cfg.smartSmooth=amount>0;m.cfg.smartSmoothing=amount;m.smart.lock.target=target;m.smart.lock.strength=1;
               var b:*=spawn(220,240),hp:Number=target.hp,path:Array=[];
               for(var i:int=0;i<80 && !b.babah;i++){physics();path=path.concat(m.smart.snapshot(b).motionPath || []);}
               var s:*=m.smart.snapshot(b);
               write("smooth-box-"+amount+".json",JSON.stringify(path));
               log+="BOX amount="+amount+" hit="+(target.hp<hp)+" end="+b.X+","+b.Y+" urgent="+s.smoothUrgent+"\n";
               ok(target.hp<hp,"native curved box detour damages target at "+amount);clean();
            }
            m.cfg.smartSmooth=true;m.cfg.smartSmoothing=75;m.cfg.smartTurn=90;m.cfg.ricochet=true;m.cfg.ricochetCount=2;
            b=spawn(310,240,25);m.bullets.process(w);physics();s=m.smart.snapshot(b);var budget:Number=s.remaining;
            ok(b.babah,"smooth mode retains unavoidable real wall collision");
            m.bullets.process(w);var bounce:*=w.loc.firstObj;
            while(bounce!=null && (bounce===b || m.smart.snapshot(bounce)!==s))bounce=bounce.nobj;
            ok(bounce!=null && bounce.dx<0 && s.smooth && s.smoothing==75 && s.smoothRate==0 && s.remaining==budget,"ricochet reflects first, retains settings and budget, resets turn history");
            m.cfg.smartSmooth=false;m.cfg.smartSmoothing=0;physics();
            ok(s.smooth && s.smoothing==75 && s.remaining<budget,"bounced in-flight shot keeps smooth snapshot after settings change");
            clean();for each(tile in wall)tile.phis=0;m.cfg.ricochet=false;m.cfg.smartTurn=1080;
            // A constrained corridor must retain its physical walls; smoothing
            // must not be achieved by trimming collision checks around a curve.
            var corridor:Array=[];
            for(x=320;x<720;x+=40)for(y=160;y<=280;y+=120)
            {tile=w.loc.getAbsTile(x+1,y+1);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=y;tile.phY2=y+40;corridor.push(tile);}
            for each(amount in [50,100])
            {
               position(860,240);m.cfg.smartSmooth=true;m.cfg.smartSmoothing=amount;
               b=spawn(220,240,20,-3);hp=target.hp;
               for(i=0;i<60 && !b.babah;i++)physics();
               ok(target.hp<hp,"smooth native shot stays inside narrow corridor and hits at "+amount);clean();
            }
            for each(tile in corridor)tile.phis=0;
            m.cfg.smartSmooth=true;m.cfg.smartSmoothing=50;m.cfg.smartLife=0.1;position(1200,220);
            b=spawn();for(i=0;i<3;i++)physics();s=m.smart.snapshot(b);
            ok(s.remaining==0 && b.liv==97,"smooth subdivisions keep original age and three-step budget");
            var dx:Number=b.dx,dy:Number=b.dy;physics();
            ok(b.dx==dx && b.dy==dy,"expired smooth shot continues with native momentum");clean();m.cfg.smartLife=2;
            // Same production build, alternating identical workloads, no screenshot in timings.
            var timings:Array=[];
            for(i=0;i<6;i++)
            {
               m.cfg.smartSmooth=i%2==1;position(1200,180);var batch:Array=[];
               for(var j:int=0;j<64;j++)batch.push(spawn(220,400+j%8,160));
               var started:int=getTimer();physics();var elapsed:int=getTimer()-started;timings.push(elapsed);
               for each(b in batch)if(b.babah || b.liv!=99 || Math.abs(b.dist-160)>0.001)throw new Error("batch speed/age changed");
               ok(elapsed<2000,"64 fast bullets advance exactly once; smooth="+m.cfg.smartSmooth+" cost="+elapsed+"ms");clean();
            }
            write("smooth-timings.json",JSON.stringify(timings));
            ok(m.cfg.diag.smartError==null && m.cfg.diag.laserError==null,"production has no smart or laser errors");finish(true,"");
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function write(name:String,value:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,stream:*=new S();
         stream.open(F["applicationStorageDirectory"].resolvePath(name),"write");stream.writeUTFBytes(value);stream.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();write("production-smooth.txt",log+(error?"FAIL "+error+"\n":"")+"checks="+checks+"\n"+(pass?"PASS production smooth mode":"FAIL production smooth mode")+"\n");
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
