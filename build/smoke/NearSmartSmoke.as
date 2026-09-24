package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   /** Independent production probe: records full near-target winding in real slow time. */
   public class NearSmartSmoke extends Sprite
   {
      private static var probe:NearSmartSmoke;
      private var host:*,loader:Loader=new Loader(),domain:ApplicationDomain,timer:Timer=new Timer(50);
      private var w:*,m:*,weapon:*,target:*,options:Object;
      private var ticks:int=0,phase:int=0,since:int=0,fired:int=0,started:Boolean=false,shots:Array=[],log:String="";
      public function NearSmartSmoke(){}
      public static function init(main:*):void{probe=new NearSmartSmoke();probe.start(main);}
      private function cls(name:String):Class{return domain.getDefinition(name) as Class;}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void{
            domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](host);
            options=JSON.parse(read("app:/near-options.json"));timer.addEventListener("timer",tick);timer.start();
            host.addEventListener(Event.ENTER_FRAME,observe,false,-10000);
         });
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
      }
      private function key():void
      {host.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,220));host.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,220));}
      private function ok(v:Boolean,msg:String):void{if(!v)throw new Error(msg);log+="PASS "+msg+"\n";}
      private function aim():void
      {
         var ay:Number=280+Number(options.aimOffset);
         w.cam.celX=target.X*w.cam.scaleV+w.cam.vx;w.cam.celY=ay*w.cam.scaleV+w.cam.vy;
         w.celX=w.gg.celX=target.X;w.celY=w.gg.celY=ay;
      }
      private function track(b:*,name:String):void
      {
         shots.push({b:b,name:name,lastLiv:-1,lastAngle:Math.atan2(b.begy-280,b.begx-target.X),winding:0,peak:0,points:[],done:false});
         var s:*=m.smart.snapshot(b);
         if(s!=null)for each(var scale:Number in [0.5,0.475,0.45,0.4,0.3,0.2,0.1])
            log+="FORECAST "+name+" scale="+scale+" "+JSON.stringify(cls("MSWAdaptiveRadius")["evaluate"](b,s,[{x:target.X,y:280}],1080/30*Math.PI/180,scale))+"\n";
         log+="OBSERVED "+name+" birth="+b.begx+","+b.begy+" x="+b.X+" y="+b.Y+" dx="+b.dx+" dy="+b.dy+" target="+target.X+",280\n";
      }
      private function spawn(name:String,x:Number,y:Number,dx:Number,dy:Number):void
      {
         if(options.only!="all" && options.only!=name)return;
         var b:*=new (cls("fe.weapon.Bullet"))(w.gg,x,y,cls("visualBullet"),true);
         b.weap=weapon;b.damage=20;b.tipDamage=0;b.destroy=10;b.dx=dx;b.dy=dy;b.vel=Math.sqrt(dx*dx+dy*dy);b.precision=0;b.miss=0;
         m.smart.frame(w);track(b,name);
      }
      private function tick(e:Event):void
      {
         try{
            ticks++;if(ticks>1800)throw new Error("timeout phase="+phase);
            w=cls("fe.World")["w"];m=cls("MoreSkillsWeaponsMod")["testInstance"]();
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(w.gg==null || w.loc==null || !w.loc.active)return;
            if(ticks%100==0)write("heartbeat.txt","phase="+phase+" ticks="+ticks+"\n"+log);
            if(phase==0)
            {
               if(ticks<120 || m.settings.api==null)return;
               var registered:Boolean=false;for each(var page:Object in m.settings.api.getPages())if(page.modId=="sandevistan")registered=true;
               if(!registered)return;
               ok(true,"actual installed Sandevistan and MSW loaded");
               if(w.pip.active)w.pip.onoff();w.onPause=false;w.godMode=false;w.catPause=false;w.gg.controlOn();
               for(var x:int=80;x<1400;x+=40)for(var y:int=40;y<760;y+=40){var tile:*=w.loc.getAbsTile(x+1,y+1);if(tile!=null){tile.phis=0;tile.door=null;tile.water=0;}}
               for(x=80;x<280;x+=40){tile=w.loc.getAbsTile(x+1,361);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=360;tile.phY2=400;}
               w.gg.setPos(220,360);w.gg.dx=w.gg.dy=0;w.gg.setVisPos();
               weapon=cls("fe.weapon.Weapon")["create"](w.gg,options.weapon);weapon.hold=99;weapon.hp=weapon.maxhp;weapon.lvl=weapon.perslvl=0;
               w.gg.currentWeapon=weapon;w.gg.childObjs[0]=weapon;weapon.setPers(w.gg,w.gg.pers);weapon.addVisual();w.gg.setWeaponPos();
               target=new (cls("fe.unit.Unit"))();target.loc=w.loc;target.fraction=2;target.sost=1;target.hp=target.maxhp=1000000;
               target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;target.X=400;target.Y=300;
               target.X1=385;target.X2=415;target.Y1=260;target.Y2=300;target.dx=target.dy=0;w.loc.units=[w.gg,target];w.loc.objs=[];
               target.X=220+Number(options.distance);target.X1=target.X-15;target.X2=target.X+15;
               m.cfg.smartEnabled=true;m.cfg.smartMultiLock=false;m.cfg.smartTurnRadius=options.radius;m.cfg.smartMinTurnRadius=10;
               m.cfg.smartAdaptiveRadius=options.adaptive;m.cfg.smartLife=2;m.cfg.smartTurn=1080;m.cfg.ricochet=false;
               m.cfg.smartKeepOutOfSight=true;aim();m.smart.frame(w);m.smart.lock.target=target;m.smart.lock.strength=1;
               if(options.mode!="normal"){key();ok(w.onPause && !w.godMode,"real hotkey enters slow phase");}
               phase=1;since=getTimer();return;
            }
            aim();
            if(phase==1 && getTimer()-since>400)
            {
               m.smart.lock.target=target;m.smart.lock.strength=1;
               spawn("near-fast-direct",340,280,227,0);
               spawn("near-fast-oblique",340,250,227,20);
               spawn("near-slow-oblique",340,250,20,20);
               spawn("near-very-fast",350,250,320,0);
               spawn("near-log-speed",350,250,227,0);
               spawn("lmg-off-axis",target.X+6.75,341.15,180,0);
               spawn("starts-inside-target",400,280,20,0);
               spawn("muzzle-past-target",430,280,227,0);
               weapon.t_auto=weapon.t_attack=weapon.t_reload=0;
               var existing:Array=[];var b:*=w.loc.firstObj;while(b!=null){existing.push(b);b=b.nobj;}
               if(options.only=="all" || options.only=="actual"){ok(weapon.attack(),"real "+options.weapon+" attack accepted");fired++;}
               b=w.loc.firstObj;while(b!=null){if(getQualifiedClassName(b)=="fe.weapon::Bullet" && existing.indexOf(b)<0)track(b,"actual-"+options.weapon);b=b.nobj;}
               phase=2;since=getTimer();return;
            }
            if(phase==2)
            {
               if(options.only=="actual" && fired<int(options.shots) && weapon.t_attack<=0 && weapon.t_reload<=0)
               {weapon.t_auto=0;if(weapon.attack())fired++;}
               var done:Boolean=true;for each(var r:Object in shots)if(!r.done)done=false;
               if(done && (options.only!="actual" || fired>=int(options.shots)) && getTimer()-since>2000 || getTimer()-since>14000)
               {
                  observe();var loops:int=0,report:Array=[];
                  for each(r in shots){if(r.peak>Math.PI*1.5)loops++;log+="SHOT "+r.name+" winding="+r.peak+" distance="+r.b.dist+" samples="+r.points.length+" end="+r.b.X+","+r.b.Y+" babah="+r.b.babah+" liv="+r.b.liv+"\n";report.push({name:r.name,peak:r.peak,distance:r.b.dist,points:r.points});}
                  write("trajectories.json",JSON.stringify({options:options,hp:target.hp,shots:report}));
                  ok(shots.length>=(options.only=="all"?8:options.only=="actual"?int(options.shots):1),"requested native near shots observed");
                  var hitAll:Boolean=true;
                  for each(r in shots)if(!r.b.babah || r.b.parr==null || r.b.parr.indexOf(target)<0 || r.b.X<target.X1 || r.b.X>target.X2 || r.b.Y<target.Y1 || r.b.Y>target.Y2)hitAll=false;
                  ok(hitAll,"all near shots contact the native target and stop inside its bounds");
                  if(options.mode=="normal")ok(target.hp<1000000,"normal-time hits cause native damage");
                  ok(loops==0,"no near shot orbits the target; looping shots="+loops);finish(true,"");
               }
            }
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function observe(e:Event=null):void
      {
         if(m==null || target==null)return;
         if(phase==2)
         {
            var node:*=w.loc.firstObj;
            while(node!=null)
            {
               if(getQualifiedClassName(node)=="fe.weapon::Bullet" && node.owner===w.gg)
               {var known:Boolean=false;for each(var item:Object in shots)if(item.b===node)known=true;if(!known)track(node,"actual-"+options.weapon);}
               node=node.nobj;
            }
         }
         for each(var r:Object in shots)
         {
            if(r.done)continue;var b:*=r.b,s:*=m.smart.snapshot(b);
            if(b.liv==r.lastLiv)continue;r.lastLiv=b.liv;
            var points:Array=s!=null && s.motionPath!=null?s.motionPath:[{x:b.X,y:b.Y}];
            for each(var p:Object in points)
            {
               var a:Number=Math.atan2(p.y-280,p.x-target.X),d:Number=a-r.lastAngle;
               while(d>Math.PI)d-=Math.PI*2;while(d< -Math.PI)d+=Math.PI*2;
               r.winding+=d;r.lastAngle=a;r.peak=Math.max(r.peak,Math.abs(r.winding));
               r.points.push({x:p.x,y:p.y,dx:b.dx,dy:b.dy,age:b.liv,babah:b.babah,remaining:s==null?-1:s.remaining,radius:s==null?null:s.radiusNow,cause:s==null?null:s.radiusCause});
            }
            if(b.babah || !b.in_chain || b.liv<=0)r.done=true;
         }
      }
      private function read(path:String):String
      {var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();fs.open(new F(path),"read");var text:String=fs.readUTFBytes(fs.bytesAvailable);fs.close();return text;}
      private function write(name:String,text:String):void
      {var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeUTFBytes(text);fs.close();}
      private function finish(pass:Boolean,error:String):void
      {timer.stop();write("near-results.txt",log+(error?"FAIL "+error+"\n":"")+(pass?"PASS near smart":"FAIL near smart")+"\n");getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);}
   }
}
