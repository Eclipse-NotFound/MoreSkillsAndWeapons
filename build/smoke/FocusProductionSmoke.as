package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.KeyboardEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import flash.geom.Point;

   /** TEST ONLY: exercises the exact production SWF without linking its source. */
   public class FocusProductionSmoke extends Sprite
   {
      private static var probe:FocusProductionSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(50),domain:ApplicationDomain;
      private var ticks:int=0,phase:int=0,since:int=0,log:String="",checks:int=0;
      private var m:*,w:*,weapon:*,hud:*,early:*,flying:*,held:Number;
      private var targets:Array=[],excluded:Array=[],wall:Array=[];
      public function FocusProductionSmoke() {}
      public static function init(main:*):void {probe=new FocusProductionSmoke();probe.start(main);}
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
      private function next(value:int):void {phase=value;since=getTimer();}
      private function position(u:*,x:Number,y:Number):void
      {
         u.setPos(x,y);u.X1=x-u.scX/2;u.X2=x+u.scX/2;u.Y1=y-u.scY;u.Y2=y;
         if(u.vis!=null)u.setVisPos();
      }
      private function makeUnit(x:Number,y:Number,visual:Boolean=false):*
      {
         var u:*=visual?w.loc.createUnit("raider",x,y,true):new (cls("fe.unit.Unit"))();
         u.loc=w.loc;u.fraction=2;u.hp=u.maxhp=100000;u.sost=1;u.isVis=true;
         u.disabled=u.trigDis=u.npc=u.noAgro=false;u.blood=0;u.showNumbs=false;u.opt=null;
         u.storona=-1;u.shithp=u.skin=u.armor=u.armor_qual=0;u.dexter=100;
         if(!visual){u.scX=30;u.scY=60;}
         position(u,x,y);return u;
      }
      private function spawn(dx:Number=20,dy:Number=0):*
      {
         var B:Class=cls("fe.weapon.Bullet"),b:*=new B(w.gg,300,260,null,true);
         b.weap=weapon;b.damage=100;b.tipDamage=0;b.precision=10;b.miss=1;
         b.dx=dx;b.dy=dy;b.vel=Math.sqrt(dx*dx+dy*dy);return b;
      }
      private function state(u:*):* {return m.smart.multiLock.stateFor(u);}
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks%100==0)write("heartbeat.txt","ticks="+ticks+" phase="+phase+"\n"+log);
            if(ticks>1600)throw new Error("timeout phase "+phase);
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            var elapsed:int=getTimer()-since,i:int,u:*,b:*,s:*,tile:*;
            if(phase==0)
            {
               if(m.cfg.diag.frames<600)return;
               ok(domain.hasDefinition("MSWSmartMultiLock"),"production multi-lock controller loaded; runner verifies exact SWF hash");
               ok(!m.cfg.smartAdaptiveRadius,"adaptive radius defaults off before multi-lock test");
               m.cfg.smartAdaptiveRadius=true;m.cfg.smartMinTurnRadius=10;
               ok(!m.cfg.smartMultiLock,"new mode defaults off");
               if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
               for(var x:int=100;x<1300;x+=20)for(var y:int=40;y<760;y+=20){tile=w.loc.getAbsTile(x,y);tile.phis=0;tile.water=0;}
               position(w.gg,240,320);w.gg.dx=w.gg.dy=0;
               w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.cam.celX=440;w.cam.celY=280;
               weapon=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");w.gg.currentWeapon=weapon;
               targets=[makeUnit(440,200,true),makeUnit(500,380,true),makeUnit(660,280,true)];
               excluded=[makeUnit(3200,280),makeUnit(560,200),makeUnit(800,600),makeUnit(850,500),makeUnit(920,280)];
               excluded[1].invis=true;excluded[2].fraction=w.gg.fraction;excluded[3].npc=true;
               for(y=40;y<440;y+=40){tile=w.loc.getAbsTile(801,y+1);tile.phis=1;tile.phX1=800;tile.phX2=840;tile.phY1=y;tile.phY2=y+40;}
               w.loc.units=[w.gg].concat(targets,excluded);w.loc.objs=[];w.testDam=true;w.showHit=0;
               w.celX=w.gg.celX=-1000;w.celY=w.gg.celY=-1000;
               m.cfg.smartEnabled=true;m.cfg.smartMultiLock=true;m.cfg.smartAcquire=0.6;m.cfg.smartHold=0.3;m.cfg.smartDecay=0.6;
               m.cfg.smartKeepOutOfSight=false;m.cfg.smartLife=2;m.cfg.smartTurnRadius=50;m.cfg.ricochet=false;
               m.smart.frame(w);next(1);return;
            }
            if(phase==1 && elapsed>250)
            {
               for each(u in targets)ok(m.smart.visible(u,w) && state(u)!=null && state(u).candidate===u && state(u).progress>0 && state(u).progress<1,"native target acquires without reticle proximity at "+u.X);
               for each(u in excluded)ok(state(u)==null,"off-screen, invisible, friendly, NPC or occluded target excluded at "+u.X);
               early=spawn();m.smart.frame(w);ok(m.smart.snapshot(early)==null,"shot before acquisition remains ordinary");
               screenshot("multi-acquiring.png");next(2);return;
            }
            if(phase==2 && elapsed>800)
            {
               for each(u in targets)ok(state(u).target===u && state(u).strength==1,"native target completes its own lock at "+u.X);
               ok(m.smart.lock.target==null && m.smart.multiLock.locks.length==3,"multi mode does not use the single-target slot");
               ok(m.smart.snapshot(early)==null,"old bullet is not retroactively guided");w.loc.remObj(early);
               hud=host.getChildByName("MSWSmartHUD");ok(hud!=null && hud.visible,"production multi HUD active");
               for each(u in targets)ok(markerBlue(u),"blue diamond drawn at native target "+u.X);
               screenshot("multi-locked.png");
               focusChecks();
               var bullets:Array=[],counts:Array=[0,0,0],hp:Array=[];
               for each(u in targets)hp.push(u.hp);
               for(i=0;i<9;i++)bullets.push(spawn());m.smart.frame(w);
               for each(b in bullets){s=m.smart.snapshot(b);ok(s!=null && b.precision==0 && b.miss==0,"native bullet receives guidance");counts[targets.indexOf(s.target)]++;}
               ok(counts[0]==3 && counts[1]==3 && counts[2]==3,"nine consecutive bullets distribute three per target");
               var original:*=bullets[0],before:*=m.smart.snapshot(original);flying=spawn(1,0);
               m.smart.inherit(original,flying);w.loc.remObj(original);bullets.shift();
               ok(m.smart.snapshot(flying)===before && before.target===targets[0],"ricochet replacement inherits assigned target and budget");
               for(var step:int=0;step<65;step++)
               {
                  m.smart.beforeProjectiles();
                  for each(b in bullets)if(!b.babah && b.liv>0)b.step();
                  m.smart.afterProjectiles();
               }
               for(i=0;i<3;i++)ok(targets[i].hp<hp[i],"native guided bullets settle real damage on target "+i);
               for each(b in bullets)if(b.in_chain)w.loc.remObj(b);
               var shotgun:*=cls("fe.weapon.Weapon")["create"](w.gg,"oldshot");shotgun.setPers(w.gg,w.gg.pers);shotgun.X=300;shotgun.Y=260;
               shotgun.hold=shotgun.holder;shotgun.ammoMod=3;shotgun.t_attack=shotgun.rapid;shotgun.step();m.smart.frame(w);
               counts=[0,0,0];var pellets:int=0;var node:*=w.loc.firstObj;
               while(node!=null){if(getQualifiedClassName(node)=="fe.weapon::Bullet" && node.weap===shotgun){s=m.smart.snapshot(node);ok(s!=null && node.tipDamage==3,"native special-ammo pellet assigned");counts[targets.indexOf(s.target)]++;pellets++;}node=node.nobj;}
               ok(pellets>=3 && Math.min(counts[0],counts[1],counts[2])>0 && Math.max(counts[0],counts[1],counts[2])-Math.min(counts[0],counts[1],counts[2])<=1,"one real shotgun blast spreads pellets evenly over three enemies");
               m.cfg.smartMultiLock=false;m.smart.frame(w);
               ok(m.smart.multiLock.locks.length==0 && m.smart.lock.target==null,"mode switch clears acquisition and requires reacquisition");
               ok(m.smart.snapshot(flying).target===targets[0],"mode switch preserves in-flight target snapshot");
               m.cfg.smartMultiLock=true;m.smart.frame(w);next(3);return;
            }
            if(phase==3 && elapsed>900)
            {
               ok(m.smart.multiLock.locks.length==3 && state(targets[0]).strength==1,"all three reacquire after mode switch");
               for(var wy:int=40;wy<240;wy+=40){tile=w.loc.getAbsTile(401,wy+1);tile.phis=1;tile.phX1=400;tile.phX2=440;tile.phY1=wy;tile.phY2=wy+40;wall.push(tile);}
               ok(!m.smart.visible(targets[0],w) && m.smart.visible(targets[1],w) && m.smart.visible(targets[2],w),"real terrain occludes one target without occluding the others");
               next(4);return;
            }
            if(phase==4 && elapsed>550)
            {
               held=state(targets[0]).strength;
               ok(held>0 && held<1 && state(targets[1]).strength==1,"only the occluded target loses lock strength");
               m.cfg.smartKeepOutOfSight=true;next(5);return;
            }
            if(phase==5 && elapsed>1300)
            {
               ok(state(targets[0])!=null && Math.abs(state(targets[0]).strength-held)<0.00001,"out-of-sight switch retains the independently weakened lock");
               m.cfg.smartKeepOutOfSight=false;next(6);return;
            }
            if(phase==6 && elapsed>1300)
            {
               ok(state(targets[0])==null && state(targets[1]).strength==1 && state(targets[2]).strength==1,"occluded target expires independently after hold is disabled");
               targets[1].hp=0;
               b=spawn();m.smart.beforeProjectiles();m.smart.afterProjectiles();
               ok(m.smart.snapshot(b).target===targets[2],"enemy dying between display frames is skipped by new shots");
               m.smart.frame(w);ok(state(targets[1])==null && m.smart.multiLock.locks.length==1,"dead target and its marker are removed");
               m.cfg.smartEnabled=false;m.smart.frame(w);
               ok(m.smart.multiLock.locks.length==0 && !hud.visible && m.smart.snapshot(b).remaining==0,"master off clears all markers and stops existing guidance");
               ok(m.cfg.diag.smartError==null && m.cfg.diag.laserError==null,"production has no module errors");
               finish(true,"");
            }
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function aim(x:Number,y:Number,input:Boolean=true):void
      {
         w.cam.celX=x*w.cam.scaleV+w.cam.vx;w.cam.celY=y*w.cam.scaleV+w.cam.vy;
         w.celX=w.gg.celX=x;w.celY=w.gg.celY=y;
         if(input)host.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE,true,false,w.cam.celX,w.cam.celY));
      }
      private function focusShot():*
      {var b:*=spawn();m.smart.frame(w);return b;}
      private function collectRows(o:*,rows:Array):void
      {
         if(o==null || !o.visible)return;
         if("settingsItem" in o && o.settingsItem!=null)rows.push(o);
         if("numChildren" in o)for(var i:int=0;i<o.numChildren;i++)collectRows(o.getChildAt(i),rows);
      }
      private function focusChecks():void
      {
         ok(!m.cfg.smartFocus && m.cfg.smartFocusRadius==48,"production defaults focus off and radius 48");
         var focusItem:*,radiusItem:*,page:*,item:*;
         for each(page in m.settings.getPages())if(page.modId=="msw-smart")
            for each(item in page.items){if(item.key=="smartFocus")focusItem=item;if(item.key=="smartFocusRadius")radiusItem=item;}
         ok(focusItem!=null && radiusItem!=null && radiusItem.min==0 && radiusItem.max==200 && radiusItem.step==4,"Pip and F6 share focus setting definitions");
         w.pip.onoff(5);if(!m.panel.tabActive())m.panel.tabToggle(w);
         ok(m.settings.api.selectPage("msw-smart"),"real Pip selects smart page");
         var rows:Array=[];collectRows(host,rows);var found:int=0;
         for each(var row:* in rows)
         {
            if(row.settingsItem.key=="smartFocus")
            {row.settingsSc.selected=true;row.settingsSc.dispatchEvent(new Event(Event.CHANGE));found++;}
            if(row.settingsItem.key=="smartFocusRadius")
            {row.settingsSc.scrollPosition=18;row.settingsSc.dispatchEvent(new Event("scroll"));found++;}
         }
         ok(found==2 && m.cfg.smartFocus && m.cfg.smartFocusRadius==72,"real Pip checkbox and slider update focus settings");
         screenshot("focus-settings.png");m.panel.tabToggle(w);w.pip.onoff();
         var C:Class=cls("MSWConfig"),saved:*=new C();saved.load();
         ok(saved.smartFocus && saved.smartFocusRadius==72,"Pip close saves focus values in production config");
         m.panel.toggleOverlay();m.panel.handleKey(9);m.panel.handleKey(40);m.panel.handleKey(40);m.panel.handleKey(39);
         ok(!m.cfg.smartFocus,"F6 smart page toggles same focus option");
         m.panel.handleKey(40);m.panel.handleKey(39);ok(m.cfg.smartFocusRadius==76,"F6 adjusts independent focus range");m.panel.toggleOverlay();
         focusItem["set"](focusItem.def);radiusItem["set"](radiusItem.def);
         ok(!m.cfg.smartFocus && m.cfg.smartFocusRadius==48,"focus controls restore defaults");
         var a:*=targets[0],b:*=targets[1],c:*=targets[2],shots:Array=[],bullet:*,s:*,i:int;
         m.cfg.smartFocus=true;aim(a.X,(a.Y1+a.Y2)/2);m.smart.frame(w);
         var beforeHud:BitmapData=new BitmapData(host.stage.stageWidth,host.stage.stageHeight,true,0);beforeHud.draw(hud);
         for(i=0;i<6;i++)shots.push(spawn());m.smart.frame(w);
         for each(bullet in shots)ok(m.smart.snapshot(bullet).target===a,"all newly born rounds focus first enemy");
         aim(b.X,(b.Y1+b.Y2)/2);bullet=focusShot();shots.push(bullet);
         ok(m.smart.snapshot(bullet).target===b && m.smart.snapshot(shots[0]).target===a,"cursor switches new shots immediately while old target persists");
         var afterHud:BitmapData=new BitmapData(beforeHud.width,beforeHud.height,true,0);afterHud.draw(hud);
         var difference:*=beforeHud.compare(afterHud);ok(difference is Number && difference==0,"focus changes no HUD pixels");beforeHud.dispose();afterHud.dispose();
         var shotgun:*=cls("fe.weapon.Weapon")["create"](w.gg,"oldshot");shotgun.setPers(w.gg,w.gg.pers);shotgun.X=300;shotgun.Y=260;
         shotgun.hold=shotgun.holder;shotgun.ammoMod=3;shotgun.t_attack=shotgun.rapid;shotgun.step();m.smart.frame(w);
         var node:*=w.loc.firstObj,pellets:int=0;
         while(node!=null){if(getQualifiedClassName(node)=="fe.weapon::Bullet" && node.weap===shotgun){ok(m.smart.snapshot(node).target===b && node.tipDamage==3,"real special-ammo shotgun pellet focuses same enemy");pellets++;shots.push(node);}node=node.nobj;}
         ok(pellets>=3,"focus verified on native shotgun volley");
         var clone:*=spawn(1,0),source:*=shots[0];s=m.smart.snapshot(source);m.smart.inherit(source,clone);shots.push(clone);
         ok(m.smart.snapshot(clone)===s && s.target===a,"focused ricochet keeps original target and budget after cursor switch");
         aim(-1000,-1000);var counts:Array=[0,0,0];
         for(i=0;i<6;i++){bullet=focusShot();shots.push(bullet);counts[targets.indexOf(m.smart.snapshot(bullet).target)]++;}
         ok(counts[0]==2 && counts[1]==2 && counts[2]==2,"moving reticle away immediately restores even round robin");
         m.cfg.smartFocusRadius=0;aim(a.X2+1,(a.Y1+a.Y2)/2);
         counts=[0,0,0];for(i=0;i<3;i++){bullet=focusShot();shots.push(bullet);counts[targets.indexOf(m.smart.snapshot(bullet).target)]++;}
         ok(counts[0]==1 && counts[1]==1 && counts[2]==1,"zero focus range falls back outside body");
         aim(a.X,(a.Y1+a.Y2)/2);bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target===a,"zero range still focuses directly pointed body");
         m.cfg.smartFocusRadius=48;
         // Put another completed target underneath the reticle before the death.
         var bx:Number=b.X,by:Number=b.Y;position(b,a.X+10,a.Y);aim(a.X,(a.Y1+a.Y2)/2);m.smart.frame(w);
         a.hp=0;bullet=focusShot();shots.push(bullet);var first:*=m.smart.snapshot(bullet).target;
         bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target!==first,"focused death restores alternating survivors despite nearby candidate");
         m.smart.beforeProjectiles();m.smart.afterProjectiles();ok(s.remaining==0,"old focused round stops guidance instead of retargeting dead enemy");
         w.cam.vx+=4;position(b,b.X+2,b.Y);bullet=focusShot();shots.push(bullet);first=m.smart.snapshot(bullet).target;
         bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target!==first,"camera and enemy motion do not cancel death wait");
         w.pip.onoff(5);aim(b.X,(b.Y1+b.Y2)/2);w.pip.onoff();
         bullet=focusShot();shots.push(bullet);first=m.smart.snapshot(bullet).target;
         bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target!==first,"cursor movement in menu does not rearm focus");
         aim(b.X+1,(b.Y1+b.Y2)/2);bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target===b,"new gameplay mouse event rearms focus after death");
         // A native wall removes sight but not an already-completed lock.
         var tiles:Array=[];
         for(var y:int=40;y<240;y+=40){var t:*=w.loc.getAbsTile(401,y+1);t.phis=1;t.phX1=400;t.phX2=440;t.phY1=y;t.phY2=y+40;tiles.push(t);}
         ok(!m.smart.visible(b,w),"native wall hides focused enemy");
         m.smart.multiLock.stateFor(b).strength=0.4;m.cfg.smartKeepOutOfSight=true;
         bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target===b && Math.abs(m.smart.snapshot(bullet).strength-0.4)<0.00001,"covered held enemy remains focused at its current weak strength");
         m.cfg.smartKeepOutOfSight=false;m.smart.multiLock.advance([b,c],[c],m.cfg.smartHold+m.cfg.smartDecay+1,m.cfg);
         bullet=focusShot();shots.push(bullet);ok(m.smart.snapshot(bullet).target===c,"complete sight decay removes focus and uses remaining lock");
         for each(t in tiles)t.phis=0;
         for each(bullet in shots)if(bullet.in_chain)w.loc.remObj(bullet);
         a.hp=a.maxhp;position(b,bx,by);w.cam.vx=0;aim(-1000,-1000);
         m.cfg.smartFocus=false;m.cfg.smartKeepOutOfSight=false;m.smart.multiLock.clear();m.smart.multiLock.advance(targets,targets,m.cfg.smartAcquire,m.cfg);m.smart.frame(w);
         ok(m.smart.multiLock.locks.length==3,"focus preserves multi-lock acquisition pool and existing regression can continue");
      }
      private function markerBlue(u:*):Boolean
      {
         var p:Point=hud.globalToLocal(w.visual.localToGlobal(new Point((u.X1+u.X2)/2-(u.X2-u.X1)*0.15,u.Y1+(u.Y2-u.Y1)*0.4)));
         var bitmap:BitmapData=new BitmapData(host.stage.stageWidth,host.stage.stageHeight,true,0);bitmap.draw(hud);var pixels:int=0;
         for(var x:int=int(p.x)-16;x<=int(p.x)+16;x++)for(var y:int=int(p.y)-16;y<=int(p.y)+16;y++)if(x>=0 && y>=0 && x<bitmap.width && y<bitmap.height){var color:uint=bitmap.getPixel32(x,y);if((color>>>24)>0 && (color&255)>150 && ((color>>16)&255)<140)pixels++;}
         bitmap.dispose();return pixels>12;
      }
      private function screenshot(name:String):void
      {
         var bitmap:BitmapData=new BitmapData(host.stage.stageWidth,host.stage.stageHeight,false,0);bitmap.draw(host.stage);
         var options:Class=cls("flash.display.PNGEncoderOptions"),bytes:*=Object(bitmap)["encode"](bitmap.rect,new options());
         var S:Class=cls("flash.filesystem.FileStream"),stream:*=new S();stream.open(cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");stream.writeBytes(bytes);stream.close();bitmap.dispose();
      }
      private function write(name:String,value:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,stream:*=new S();
         stream.open(F["applicationStorageDirectory"].resolvePath(name),"write");stream.writeUTFBytes(value);stream.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();write("production-focus.txt",log+(error?"FAIL "+error+"\n":"")+"checks="+checks+"\n"+(pass?"PASS production focus":"FAIL production focus")+"\n");
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
