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
   public class AdaptiveRadiusProductionSmoke extends Sprite
   {
      private static var probe:AdaptiveRadiusProductionSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(50),domain:ApplicationDomain;
      private var ticks:int=0,log:String="",checks:int=0;
      private var m:*,w:*,weapon:*,target:*,wall:Array=[];
      public function AdaptiveRadiusProductionSmoke() {}
      public static function init(main:*):void {probe=new AdaptiveRadiusProductionSmoke();probe.start(main);}
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
      private function shot(enabled:Boolean,normal:Number,minimum:Number,turn:Number,life:Number,
                            tx:Number,ty:Number,x:Number=220,y:Number=240,dx:Number=20,dy:Number=0,moving:Boolean=false):Object
      {
         clean();position(tx,ty);target.dx=target.dy=0;
         m.cfg.smartAdaptiveRadius=enabled;m.cfg.smartTurnRadius=normal;m.cfg.smartMinTurnRadius=minimum;
         m.cfg.smartTurn=turn;m.cfg.smartLife=life;m.smart.lock.target=target;m.smart.lock.strength=1;
         var b:*=spawn(x,y,dx,dy),hp:Number=target.hp,result:Object={points:[],radii:[],hit:false,minimum:normal,maximum:0};
         for(var i:int=0;i<80 && !b.babah;i++)
         {
            if(moving){target.dy=i<8?2:-2;position(tx,ty+(i<8?i*2:32-i*2));}
            physics();var s:*=m.smart.snapshot(b);
            result.points=result.points.concat(s.motionPath || []);
            var radius:Number=s.radiusNow==null?normal:s.radiusNow;
            result.radii.push(radius);result.minimum=Math.min(result.minimum,radius);result.maximum=Math.max(result.maximum,radius);
            if(radius<Math.min(normal,minimum)-0.0001 || radius>normal+0.0001)throw new Error("radius escaped configured interval");
         }
         result.hit=target.hp<hp;result.end={x:b.X,y:b.Y};result.state=m.smart.snapshot(b);
         log+="SHOT adaptive="+enabled+" normal="+normal+" minimum="+minimum+" turn="+turn+" hit="+result.hit+" used="+result.minimum+".."+result.maximum+" cause="+result.state.radiusCause+"\n";
         clean();return result;
      }
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks%100==0)write("heartbeat.txt","ticks="+ticks+"\n"+log);
            if(ticks>1000)throw new Error("timeout");
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active || m.cfg.diag.frames<600)return;
            timer.stop();if(w.verror.visible)throw new Error(w.verror.txt.text);
            ok(m.cfg.diag.ver=="1.12.0-nonfront-laser","exact production adaptive version loaded");
            ok(!m.cfg.smartAdaptiveRadius && m.cfg.smartMinTurnRadius==10,"adaptive mode defaults off with ten percent minimum");
            if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
            for(var x:int=100;x<1600;x+=20)for(var y:int=40;y<780;y+=20){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null){tile.phis=0;tile.water=0;}}
            w.gg.setPos(220,320);w.gg.dx=w.gg.dy=0;
            weapon=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");w.gg.currentWeapon=weapon;
            target=new (cls("fe.unit.Unit"))();target.loc=w.loc;target.fraction=2;target.hp=target.maxhp=1000000;
            target.sost=1;target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;
            target.skin=target.armor=target.armor_qual=target.shithp=0;target.dexter=100;
            w.loc.units=[target];m.cfg.smartEnabled=true;m.cfg.ricochet=false;m.cfg.smartMultiLock=false;m.smart.frame(w);
            var traces:Object={};
            traces.fixed=shot(false,200,10,1080,2,860,270);
            traces.equal=shot(true,200,200,1080,2,860,270);
            ok(JSON.stringify(traces.fixed.points)==JSON.stringify(traces.equal.points),"equal bounds preserve fixed-radius native trajectory point for point");
            traces.open=shot(true,200,10,1080,2,860,270);
            ok(traces.open.hit && traces.open.minimum==200,"reachable open target stays at large radius and takes real damage");
            traces.miss=shot(false,200,10,90,0.6,420,340);
            traces.rescue=shot(true,200,10,90,0.6,420,340);
            ok(!traces.miss.hit && traces.rescue.hit,"early adaptive rescue hits where fixed large radius misses");
            ok(traces.rescue.minimum>10 && traces.rescue.minimum<200,"rescue uses an intermediate radius instead of always choosing minimum");
            traces.floor=shot(true,200,180,90,0.6,420,340);
            ok(traces.floor.minimum>=180,"unreachable rescue respects configured minimum");
            traces.moving=shot(true,200,10,1080,2,860,280,220,400,20,0,true);
            ok(traces.moving.hit,"moving target with reversed velocity takes real damage");target.dx=target.dy=0;
            write("adaptive-traces.json",JSON.stringify(traces,function(k:String,v:*):*{return k=="state"?undefined:v;}));
            // Force a previously necessary tightening, then place the target on
            // a safely reachable distant bearing and measure recovery in flight.
            clean();position(420,340);m.cfg.smartAdaptiveRadius=true;m.cfg.smartTurnRadius=200;m.cfg.smartMinTurnRadius=10;
            m.cfg.smartTurn=90;m.cfg.smartLife=2;m.smart.lock.target=target;m.smart.lock.strength=1;
            var b:*=spawn(),s:*,initial:Number;
            physics();s=m.smart.snapshot(b);initial=s.radiusNow;
            position(b.X+b.dx/20*360,b.Y+b.dy/20*360);
            var recovery:Array=[initial];
            for(var i:int=0;i<12 && !b.babah;i++){physics();recovery.push(s.radiusNow);}
            log+="RECOVERY "+JSON.stringify(recovery)+"\n";write("adaptive-recovery.json",JSON.stringify(recovery));
            ok(initial<200 && recovery[1]==initial,"radius does not jump back on first safe forecast");
            var intermediate:Boolean=false,maxRise:Number=0;
            for(i=1;i<recovery.length;i++){maxRise=Math.max(maxRise,recovery[i]-recovery[i-1]);if(recovery[i]>initial && recovery[i]<200)intermediate=true;}
            ok(s.radiusNow>initial && intermediate && maxRise<=10.0001,"safe recovery is gradual in native flight");clean();
            // Physical solid-box detour with the ordinary route finder.
            for(x=320;x<400;x+=40)for(y=200;y<280;y+=40){tile=w.loc.getAbsTile(x+1,y+1);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=y;tile.phY2=y+40;wall.push(tile);}
            traces.box=shot(true,200,10,1080,2,520,240);
            write("adaptive-box.json",JSON.stringify(traces.box.points));
            ok(traces.box.hit,"adaptive radius detours around a real solid box and damages target");
            position(520,240);m.cfg.smartAdaptiveRadius=true;m.cfg.smartTurnRadius=200;m.cfg.smartMinTurnRadius=30;
            m.cfg.smartTurn=90;m.cfg.ricochet=true;m.cfg.ricochetCount=2;m.smart.lock.target=target;m.smart.lock.strength=1;
            b=spawn(310,240,25);m.bullets.process(w);physics();s=m.smart.snapshot(b);var budget:Number=s.remaining;
            ok(b.babah,"unavoidable native wall collision is retained");
            m.bullets.process(w);var bounce:*=w.loc.firstObj;
            while(bounce!=null && (bounce===b || m.smart.snapshot(bounce)!==s))bounce=bounce.nobj;
            ok(bounce!=null && bounce.dx<0 && s.adaptive && s.minTurnRadius==30 && s.radiusNow==200 && s.radiusStable==0 && s.remaining==budget,"ricochet reflects, inherits bounds and budget, then resets prediction");
            m.cfg.smartAdaptiveRadius=false;m.cfg.smartMinTurnRadius=150;physics();
            ok(s.adaptive && s.minTurnRadius==30 && s.remaining<budget,"in-flight ricochet keeps original adaptive settings");
            clean();for each(tile in wall)tile.phis=0;m.cfg.ricochet=false;
            var corridor:Array=[];
            for(x=320;x<720;x+=40)for(y=160;y<=280;y+=120)
            {tile=w.loc.getAbsTile(x+1,y+1);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=y;tile.phY2=y+40;corridor.push(tile);}
            var narrow:Object=shot(true,200,10,1080,2,860,240,220,240,20,-3);
            ok(narrow.hit,"adaptive projectile stays inside narrow physical corridor and hits");
            for each(tile in corridor)tile.phis=0;
            m.cfg.smartAdaptiveRadius=true;m.cfg.smartMinTurnRadius=10;m.cfg.smartLife=0.1;position(1200,220);
            b=spawn();for(i=0;i<3;i++)physics();s=m.smart.snapshot(b);
            ok(s.remaining==0 && b.liv==97,"subdivision retains native age and three-step guidance budget");
            var dx:Number=b.dx,dy:Number=b.dy;physics();
            ok(b.dx==dx && b.dy==dy,"expired adaptive shot continues with native momentum");clean();m.cfg.smartLife=2;
            var timings:Array=[];
            for(i=0;i<6;i++)
            {
               m.cfg.smartAdaptiveRadius=i%2==1;position(1200,180);var batch:Array=[];
               for(var j:int=0;j<64;j++)batch.push(spawn(220,400+j%8,160));
               var started:int=getTimer();physics();var elapsed:int=getTimer()-started;timings.push(elapsed);
               for each(b in batch)if(b.babah || b.liv!=99 || Math.abs(b.dist-160)>0.001)throw new Error("batch speed/age changed");
               ok(elapsed<2000,"64 fast bullets advance once; adaptive="+m.cfg.smartAdaptiveRadius+" cost="+elapsed+"ms");clean();
            }
            write("adaptive-timings.json",JSON.stringify(timings));
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
         timer.stop();write("production-adaptive.txt",log+(error?"FAIL "+error+"\n":"")+"checks="+checks+"\n"+(pass?"PASS production adaptive radius":"FAIL production adaptive radius")+"\n");
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
