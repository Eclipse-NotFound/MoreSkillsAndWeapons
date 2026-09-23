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

   /** TEST ONLY: real Box.initDoor, Bullet.run, Location.hitTile and Box.die. */
   public class GlassProductionSmoke extends Sprite
   {
      private static var probe:GlassProductionSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(50),domain:ApplicationDomain;
      private var ticks:int=0,phase:int=0,since:int=0,log:String="",checks:int=0;
      private var m:*,w:*,weapon:*,target:*,pane:*,panes:Array=[];
      public function GlassProductionSmoke() {}
      public static function init(main:*):void {probe=new GlassProductionSmoke();probe.start(main);}
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
      private function position(x:Number=620,y:Number=280):void
      {target.X=x;target.Y=y+20;target.X1=x-12;target.X2=x+12;target.Y1=y-20;target.Y2=y+20;}
      private function cleanShots():void
      {
         m.smart.afterProjectiles();
         var b:*=w.loc.firstObj;
         while(b!=null){var next:*=b.nobj;if(getQualifiedClassName(b)=="fe.weapon::Bullet")w.loc.remObj(b);b=next;}
      }
      private function scene():void
      {
         cleanShots();panes=[];
         for(var x:int=80;x<1400;x+=40)for(var y:int=40;y<760;y+=40)
         {
            var t:*=w.loc.getAbsTile(x+1,y+1);
            if(t!=null){t.phis=0;t.water=0;t.door=null;t.indestruct=false;t.hp=1000;t.thre=0;t.opac=0;
               t.phX1=x;t.phX2=x+40;t.phY1=y;t.phY2=y+40;}
         }
         w.loc.destroyOn=true;position();m.cfg.smartMultiLock=false;m.cfg.smartAdaptiveRadius=false;m.cfg.smartMinTurnRadius=10;
         m.cfg.smartTurn=1080;m.cfg.smartTurnRadius=50;m.cfg.smartLife=2;m.cfg.ricochet=false;
         m.smart.frame(w);m.smart.lock.target=target;m.smart.lock.strength=1;
      }
      private function glass(id:String="window1",x:Number=380,hp:Number=-1,xml:XML=null):*
      {
         var p:*=new (cls("fe.loc.Box"))(w.loc,id,x,360,xml);
         // Deterministic fixture size; all tile identity/destruction comes from
         // native initDoor, with the constructor's real material and threshold.
         for each(var t:* in p.tiles){t.phis=0;t.door=null;}
         p.X1=x-20;p.X2=x+20;p.Y1=200;p.Y2=360;
         if(hp>=0)p.hp=hp;p.initDoor();panes.push(p);return p;
      }
      private function solid(x:Number,y1:Number=200,y2:Number=360):void
      {
         for(var y:Number=y1;y<y2;y+=40){var t:*=w.loc.getAbsTile(x+1,y+1);t.phis=1;t.door=null;t.indestruct=true;}
      }
      private function spawn(damage:Number=10,y:Number=280):*
      {
         var b:*=new (cls("fe.weapon.Bullet"))(w.gg,220,y,cls("visualBullet"),true);
         b.weap=weapon;b.damage=100;b.tipDamage=0;b.precision=0;b.miss=0;b.destroy=damage;
         b.dx=20;b.dy=0;b.vel=20;return b;
      }
      private function step():void
      {
         m.smart.beforeProjectiles();var b:*=w.loc.firstObj;
         while(b!=null){var next:*=b.nobj;if(getQualifiedClassName(b)=="fe.weapon::Bullet")b.step();b=next;}
         m.smart.afterProjectiles();
         if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
      }
      private function fly(b:*,limit:int=80):void {for(var i:int=0;i<limit && !b.babah && b.in_chain;i++)step();}
      private function physicsChecks():void
      {
         var b:*,after:*,hp:Number,t:*,s:*,i:int;
         for each(var amount:int in [0,50,200])
         {
            scene();pane=glass();m.cfg.smartAdaptiveRadius=amount>0;m.cfg.smartTurnRadius=amount>0?amount:50;
            hp=target.hp;b=spawn();fly(b);
            ok(pane.dead && b.babah && b.tilehit && b.X<400,"normal window is broken by the stopped original bullet; adaptive normal="+amount);
            ok(target.hp==hp,"breaking shot does not damage the distant target; adaptive normal="+amount);
            t=w.loc.getAbsTile(380,280);
            ok(t.phis==0 && t.door===pane,"native break opens tiles while retaining window identity");
            after=spawn();fly(after);
            ok(target.hp<hp,"next bullet passes the actual opening and damages target; adaptive normal="+amount);
         }
         scene();pane=glass("window1",380,25);hp=target.hp;
         for(i=0;i<3;i++)
         {
            b=spawn();fly(b);
            ok(b.babah && target.hp==hp && pane.dead==(i==2),"normal high-health window consumes native shot "+(i+1));
         }
         after=spawn();fly(after);ok(target.hp<hp,"fourth shot hits after three native damage events");
         scene();pane=glass();var second:*=glass("window1",500);hp=target.hp;
         b=spawn();fly(b);ok(pane.dead && !second.dead && target.hp==hp,"first of two windows consumes first shot");
         b=spawn();fly(b);ok(second.dead && target.hp==hp,"second window consumes second shot");
         b=spawn();fly(b);ok(target.hp<hp,"third shot traverses both opened windows");
         for each(amount in [0,100])
         {
            scene();pane=glass("window2");hp=target.hp;m.cfg.smartAdaptiveRadius=amount>0;m.cfg.smartTurnRadius=amount>0?amount:50;
            b=spawn(10000);fly(b);
            ok(!pane.dead && pane.tiles[0].hp==1000 && target.hp<hp,"powerful shot detours around intact armor; adaptive normal="+amount);
         }
         scene();pane=glass("window2");pane.die();hp=target.hp;b=spawn(0);fly(b);
         ok(target.hp<hp && w.loc.getAbsTile(380,280).door===pane,"zero-destruction shot traverses broken armored window");
         scene();pane=glass();hp=target.hp;b=spawn(0);fly(b);
         ok(!pane.dead && target.hp<hp,"zero-destruction ammo uses open detour around ordinary glass");
         scene();pane=glass("window1",380,-1,<obj indestruct="1"/>);hp=target.hp;b=spawn(10);fly(b);
         ok(!pane.dead && pane.thre==10000 && target.hp<hp,"native indestructible instance stays intact while shot detours");
         scene();pane=glass("window1",380,600);w.loc.destroyOn=false;hp=target.hp;b=spawn(1000);fly(b);
         ok(!pane.dead && target.hp<hp,"map-protected glass uses detour despite high destruction");
         scene();pane=glass();solid(480,40,760);
         ok(!m.smart.visible(target,w),"real wall behind normal glass blocks all three target sight samples");
         hp=target.hp;b=spawn();fly(b);ok(target.hp==hp,"glass-aware guidance cannot carry a bullet through the rear wall");
         // Force local search before glass; same start/goal cells, different
         // destruction ability, in one batch. The returned routes must differ.
         scene();pane=glass();solid(280,280,320);
         var capable:*=spawn(10),weak:*=spawn(0);step();
         var firstRoute:Array=m.smart.snapshot(capable).route,weakRoute:Array=m.smart.snapshot(weak).route;
         ok(firstRoute.length>0 && weakRoute.length>0 && JSON.stringify(firstRoute)!=JSON.stringify(weakRoute),"same-step cache separates strong and zero-destruction ammo routes");
         var used:Number=m.smart.snapshot(capable).remaining;
         capable.destroy=0;step();s=m.smart.snapshot(capable);
         ok(s.routePolicy.indexOf("0:")==0 && s.remaining<used,"changed projectile destruction invalidates its stored route without replenishing budget");
         scene();pane=glass();m.cfg.ricochet=true;m.cfg.ricochetCount=3;
         b=spawn();m.bullets.process(w);fly(b);m.bullets.process(w);
         ok(pane.dead && b.babah && m.smart.snapshot(b)!=null,"breaking a window keeps native stop with ricochet enabled");
         var total:int=0;var node:*=w.loc.firstObj;
         while(node!=null){if(getQualifiedClassName(node)=="fe.weapon::Bullet" && node!==b)total++;node=node.nobj;}
         ok(total==0,"destroyed glass does not spawn a reflected continuation");
         scene();pane=glass();var batch:Array=[];
         for(i=0;i<64;i++)batch.push(spawn(i%2?0:10,260+i%4));
         var started:int=getTimer();step();var elapsed:int=getTimer()-started;
         for each(b in batch)if(b.liv!=99 || Math.abs(b.dist-20)>0.0001)throw new Error("volley age or distance changed");
         ok(elapsed<2000,"64 mixed-capability bullets retain one physical step each; cost="+elapsed+"ms");
         ok(m.cfg.diag.smartError==null && m.cfg.diag.laserError==null,"no production smart or laser errors");
      }
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks%100==0)write("heartbeat.txt","ticks="+ticks+" phase="+phase+"\n"+log);
            if(ticks>1200)throw new Error("timeout phase "+phase);
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active || m.cfg.diag.frames<600)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(phase>0)
            {
               if(w.pip.active)w.pip.onoff();m.panel.overlayOpen=false;w.gg.ggControl=true;
               w.celX=w.gg.celX=620;w.celY=w.gg.celY=280;m.smart.frame(w);
            }
            if(phase==0)
            {
               ok(m.cfg.diag.smartGlassVersion=="1-windows","exact production glass implementation loaded");
               if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
               w.gg.setPos(220,320);w.gg.dx=w.gg.dy=0;
               w.visual.x=w.visual.y=0;w.visual.scaleX=w.visual.scaleY=1;
               w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.cam.celX=620;w.cam.celY=280;
               weapon=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");w.gg.currentWeapon=weapon;
               target=new (cls("fe.unit.Unit"))();target.loc=w.loc;target.fraction=2;target.hp=target.maxhp=1000000;
               target.sost=1;target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;
               target.disabled=target.trigDis=target.npc=target.noAgro=false;
               w.loc.units=[target];w.loc.objs=[];m.cfg.smartEnabled=true;m.cfg.smartAcquire=0.3;
               scene();pane=glass();m.smart.lock.clear();w.celX=620;w.celY=280;
               ok(!w.loc.isLine(220,278,620,280) && m.smart.visible(target,w),"native normal window blocks old sight but new production sight sees through");
               phase=1;since=getTimer();return;
            }
            if(phase==1 && getTimer()-since>900)
            {
               log+="LOCK progress="+m.smart.lock.progress+" strength="+m.smart.lock.strength+" visible="+m.smart.visible(target,w)+" allowed="+m.smart.targetAllowed(target,w)+" gameplay="+cls("MSWU")["inGameplay"](w)+" overlay="+m.panel.overlayOpen+" control="+w.gg.ggControl+" enabled="+m.cfg.smartEnabled+" catPause="+w.catPause+" weapon="+cls("MSWSmartWeapons")["weaponAllowed"](w.gg.currentWeapon)+" error="+m.cfg.diag.smartError+"\n";
               ok(m.smart.lock.target===target && m.smart.lock.strength==1,"single lock naturally completes through normal glass");
               scene();pane=glass("window2");m.cfg.smartMultiLock=true;m.smart.frame(w);
               ok(!w.loc.isLine(220,278,620,280) && m.smart.visible(target,w),"native armored window permits new sight despite physical blockage");
               phase=2;since=getTimer();return;
            }
            if(phase==2 && getTimer()-since>900)
            {
               var state:*=m.smart.multiLock.stateFor(target);
               ok(state!=null && state.target===target && state.strength==1,"multi lock naturally completes through armored glass");
               target.invis=true;ok(!m.smart.visible(target,w),"invisible enemy remains invisible through glass");target.invis=false;
               timer.stop();physicsChecks();finish(true,"");
            }
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function write(name:String,value:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,stream:*=new S();
         stream.open(F["applicationStorageDirectory"].resolvePath(name),"write");stream.writeUTFBytes(value);stream.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();write("production-glass.txt",log+(error?"FAIL "+error+"\n":"")+"checks="+checks+"\n"+(pass?"PASS production glass":"FAIL production glass")+"\n");
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
