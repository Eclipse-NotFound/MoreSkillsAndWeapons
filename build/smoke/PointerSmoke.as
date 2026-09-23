package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   /** Independent driver, loads and exercises the exact production bytes. */
   public class PointerSmoke extends Sprite
   {
      private static var inst:PointerSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(50),domain:ApplicationDomain;
      private var ticks:int=0,phase:int=0,since:int=0,log:String="",w:*,m:*,wp:*,target:*,oldPlayer:*;
      private var geom:Class,PC:Class,started:Boolean=false,sandy:Boolean=false;
      private var startTime:int,energy:Number,remaining:Number,freeze:int=0,advance:int=0,beamFrames:int=0,pixels:int=0;
      public function PointerSmoke() {}
      public static function init(main:*):void {inst=new PointerSmoke();inst.start(main);}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaded);
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
      }
      private function loaded(e:Event):void
      {
         domain=loader.contentLoaderInfo.applicationDomain;var C:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;C["init"](host);
         timer.addEventListener("timer",tick);timer.start();
      }
      private function ok(v:Boolean,msg:String):void {if(!v)throw new Error(msg);log+="PASS "+msg+"\n";}
      private function total():Number {return w.invent.items.batt.kol+m.pointer.charge(w);}
      private function click():void {w.ctr.keyAttack=true;wp.attack();}
      private function draw():void {m.pointer.prepare(w);w.gg.setWeaponPos();wp.step();m.pointer.frame(w);}
      private function aim(x:Number,y:Number):void
      {w.celX=w.gg.celX=x;w.celY=w.gg.celY=y;for(var i:int=0;i<12;i++){w.gg.setWeaponPos();wp.step();}wp.getBulXY();}
      private function key():void
      {host.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,220));host.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,220));}
      private function tick(e:Event):void
      {
         try
         {
            ticks++;var C:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class,WC:Class=domain.getDefinition("fe.World") as Class;
            w=WC["w"];m=C["testInstance"]();
            if(ticks>1300)throw new Error("timeout phase="+phase);
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(m.cfg.diag.pointerError!=null)throw new Error(m.cfg.diag.pointerError);
            if(!started) {w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswlaserpointer"]==null)return;
            if(phase==0)
            {
               if(ticks<90)return;
               for each(var page:Object in m.settings.api.getPages())if(page.modId=="sandevistan")sandy=true;
               ok(w.invent.weapons["mswdazzler"]!=null,"pointer and original gun coexist");
               ok(m.cfg.diag.pointerGifts==1,"one pointer gifted without magazine");
               w.gg.controlOn();
               if(w.gg.atkPoss==0)return;
               log+="EQUIP atk="+w.gg.atkPoss+" respect="+w.invent.weapons["mswlaserpointer"].respect+" old="+getQualifiedClassName(w.gg.currentWeapon)+"\n";
               w.gg.changeWeapon("mswlaserpointer",true);
               ok(w.gg.currentWeapon===w.invent.weapons["mswlaserpointer"],"native equip completes before saving");w.game.triggers.msw_pointer_charge_v1=.37;w.invent.items.batt.kol=80;
               oldPlayer=w.gg;w.saveGame(1);w.comLoad=1;phase=1;since=ticks;return;
            }
            if(phase==1)
            {
               if(w.gg===oldPlayer || ticks-since<35)return;
               if(w.gg.t_work>0 && ticks-since<180)return;
               log+="LOADED current="+getQualifiedClassName(w.gg.currentWeapon)+" pending="+getQualifiedClassName(w.gg.newWeapon)+" work="+w.gg.work+" t="+w.gg.t_work+"\n";
               if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
               wp=w.gg.currentWeapon;geom=domain.getDefinition("MSWLaserGeometry") as Class;PC=domain.getDefinition("MSWPointer") as Class;
               ok(wp===w.invent.weapons["mswlaserpointer"] && w.gg.newWeapon===wp && getQualifiedClassName(wp)=="fe.weapon::MSWPointerWeapon","native save/load rebinds inventory current and pending weapon");
               ok(!m.pointer.lit && Math.abs(m.pointer.charge(w)-.37)<.00001 && w.invent.items.batt.kol==80,"load starts off and preserves paid fraction and inventory");
               ok(m.cfg.diag.pointerGifts==1,"reload does not repeat gift");
               setup();rules();
               m.pointer.stop();m.laser.blind.clear();target.stun=10000;target.fixed=true;target.storona=-1;
               var eye:Object=geom["eye"](target);aim(eye.x,eye.y);
               w.onPause=false;w.catPause=false;w.gg.controlOn();w.gg.fixed=true;w.loc.base=false;
               w.ctr.keyAttack=true;phase=2;since=ticks;startTime=getTimer();energy=total();
               host.stage.addEventListener(Event.EXIT_FRAME,capture);return;
            }
            if(phase==2)
            {
               // Keep a stable manually selected eye for this sustained-beam
               // fixture; no production assist is involved.
               eye=geom["eye"](target);aim(eye.x,eye.y);
               if(ticks-since<40)return;
               ok(m.pointer.lit,"one native attack press stays lit through real World steps");
               var elapsed:Number=(getTimer()-startTime)/1000,used:Number=energy-total();
               ok(Math.abs(used-elapsed*2)<.6,"real-time drain matches two batteries/sec elapsed="+elapsed.toFixed(2)+" used="+used.toFixed(3));
               ok(m.laser.blind.remaining(target)>5.8 && target.hp==target.maxhp,"continuous eye contact refreshes blindness with zero direct damage");
               ok(beamFrames>12 && pixels>20,"persistent beam changes final stage pixels frames="+beamFrames+" pixels="+pixels);
               w.ctr.keyAttack=true;phase=3;since=ticks;return;
            }
            if(phase==3)
            {
               if(ticks-since<3)return;
               ok(!m.pointer.lit,"second native press switches beam off");
               ok(m.laser.blind.remaining(target)>0,"switching off leaves applied blindness counting down");
               host.stage.removeEventListener(Event.EXIT_FRAME,capture);
               if(!sandy) {finish(true,"");return;}
               target.stun=10000;target.fixed=true;w.gg.fixed=true;w.onPause=false;w.godMode=false;w.gg.controlOn();key();
               ok(w.onPause && !w.godMode,"real Sandevistan hotkey starts controllable time stop");
               phase=4;since=ticks;return;
            }
            if(phase==4)
            {
               eye=geom["eye"](target);aim(eye.x,eye.y);
               if(ticks-since<8)return;
               w.ctr.keyAttack=true;energy=total();startTime=getTimer();phase=5;since=ticks;return;
            }
            if(phase==5)
            {
               eye=geom["eye"](target);aim(eye.x,eye.y);
               if(ticks-since<32)return;
               elapsed=(getTimer()-startTime)/1000;used=energy-total();
               ok(m.pointer.lit && m.laser.blind.remaining(target)>5.7,"real time stop supports immediate sustained eye contact lit="+m.pointer.lit+" remain="+m.laser.blind.remaining(target)+" hit="+m.cfg.diag.pointerLastHit+" used="+used+" work="+w.gg.work+" pause="+w.onPause+" god="+w.godMode+" control="+w.gg.ggControl+" error="+m.cfg.diag.pointerError+" player="+w.gg.X+","+w.gg.Y+" target="+target.X+","+target.Y+" muzzle="+wp.bulX+","+wp.bulY+" aim="+w.gg.celX+","+w.gg.celY);
               ok(Math.abs(used-elapsed*2)<.6,"time-stop drain remains ordinary speed elapsed="+elapsed.toFixed(2)+" used="+used.toFixed(3));
               click();remaining=m.laser.blind.remaining(target);phase=6;since=ticks;return;
            }
            if(phase==6)
            {
               var next:Number=m.laser.blind.remaining(target);if(next==remaining)freeze++;else if(next<remaining)advance++;remaining=next;
               if(ticks-since<25)return;
               ok(freeze>0 && advance>0 && remaining>4,"blind timer follows actual slow enemy steps freeze="+freeze+" advance="+advance);
               click();ok(m.pointer.lit,"pointer can be on when time stop ends");
               energy=total();key();ok(w.onPause && w.godMode,"actual replay starts");phase=7;since=ticks;return;
            }
            if(phase==7)
            {
               if(ticks-since>2)ok(!m.pointer.lit,"pointer stays off during replay tick="+(ticks-since));
               if(w.onPause)return;
               ok(Math.abs(total()-energy)<.02,"replay does not reapply pointer battery costs");
               ok(m.cfg.diag.pointerError==null && m.cfg.diag.laserError==null,"time stop and replay leave no pointer or blind errors");
               finish(true,"");
            }
         }
         catch(err:*) {finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function setup():void
      {
         w.gui.dialText();
         for(var x:int=100;x<1400;x+=20)for(var y:int=60;y<480;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;}
         target=w.loc.createUnit("raider",500,320,true);
         target.fraction=2;target.hp=target.maxhp;target.sost=1;target.disabled=target.trigDis=target.npc=target.noAgro=false;
         target.storona=-1;target.shithp=target.t_emerg=0;target.stun=10000;target.isVis=true;
         target.setPos(500,320);target.actions();target.animate();target.setVisPos();
         w.gg.setPos(240,320);w.gg.storona=1;w.gg.dx=w.gg.dy=0;w.gg.controlOn();w.gg.work="";w.gg.t_work=0;
         w.loc.units=[w.gg,target];w.loc.objs=[];w.loc.base=false;
         var eye:Object=geom["eye"](target);aim(eye.x,eye.y);m.pointer.prepare(w);wp.step();m.pointer.frame(w);
      }
      private function rules():void
      {
         ok(wp.ammo=="batt" && wp.holder==0 && wp.hold==0 && wp.noSats && wp.kol==0,"no magazine no native projectiles original battery and SATS disabled");
         click();ok(m.pointer.lit && m.laser.blind.remaining(target)==6,"native press immediately lights and blinds visible eye");
         for(var i:int=0;i<90;i++){wp.attack();wp.step();}
         ok(m.pointer.lit && !w.ctr.keyAttack && wp.kol_shoot==0,"holding native input cannot retrigger or record native shots");
         var before:Number=total();m.pointer.prepare(w);m.pointer.frame(w);
         ok(m.pointer.lit && Math.abs(total()-before)<.0001,"ordinary pause without player steps freezes charge and on state");
         click();ok(!m.pointer.lit && m.laser.blind.remaining(target)>0,"off does not cancel blindness");
         before=total();wp.attack(true);ok(!m.pointer.lit && total()==before,"SATS attack call cannot activate or consume");
         w.invent.items.batt.kol=100;w.game.triggers.msw_pointer_charge_v1=0;
         click();m.pointer.consume(w,30);m.pointer.stop();
         ok(w.invent.items.batt.kol==40 && m.pointer.charge(w)<.000001,"thirty seconds consumes exactly sixty batteries");
         click();m.pointer.consume(w,.125);m.pointer.stop();var paid:Number=m.pointer.charge(w),stock:Number=w.invent.items.batt.kol;
         click();m.pointer.stop();ok(w.invent.items.batt.kol==stock && Math.abs(m.pointer.charge(w)-paid)<.03,"short toggles preserve prepaid energy without startup fee");
         m.cfg.pointerRate=4;before=m.pointer.charge(w);m.pointer.consume(w,.05);
         ok(Math.abs(m.pointer.charge(w)-(before-.2))<.0001,"rate changes consume existing fraction without resetting it");m.cfg.pointerRate=2;
         w.invent.items.batt.kol=0;w.game.triggers.msw_pointer_charge_v1=.1;
         ok(!m.pointer.consume(w,.1) && w.invent.items.batt.kol==0 && m.pointer.charge(w)==0,"exhaustion consumes remainder and cannot use remote storage");
         click();ok(!m.pointer.lit,"empty inventory cannot turn on");w.invent.items.batt.kol=80;draw();ok(!m.pointer.lit,"refilling inventory does not auto-start");
         var b:*=m.laser.blind;b.clear();b.apply(target,w,8,"laser");b.apply(target,w,6,"pointer");
         ok(b.remaining(target)==8,"shorter pointer hit cannot shorten existing gun blindness");
         b.apply(target,w,10,"pointer");b.apply(target,w,6,"laser");ok(b.remaining(target)==10,"gun hit cannot shorten longer pointer blindness");
         var node:*=b.states[target].node;b.apply(target,w,10,"pointer");ok(node===b.states[target].node,"both weapons share one AI step guard");
         m.cfg.laserEnabled=false;m.laser.frame(w);ok(b.remaining(target)==10,"disabling gun preserves pointer contribution");
         m.cfg.laserEnabled=true;b.apply(target,w,7,"laser");m.cfg.pointerEnabled=false;m.pointer.frame(w);
         ok(b.remaining(target)==7,"disabling pointer preserves gun contribution");m.cfg.pointerEnabled=true;b.clear();
         eyeRules();settings();interruptions();
         ok(m.cfg.diag.pointerError==null && m.cfg.diag.laserError==null,"production callbacks and shared controller have no errors");
      }
      private function eyeRules():void
      {
         var b:*=m.laser.blind,eye:Object=geom["eye"](target);var hp:Number=target.hp;
         aim(target.X,target.Y-15);click();draw();ok(b.remaining(target)==0,"aiming at body has no hidden eye assist");m.pointer.stop();
         target.storona=1;target.animate();target.setVisPos();eye=geom["eye"](target);aim(eye.x,eye.y);click();draw();
         ok(b.remaining(target)==0,"backside eye remains invalid");m.pointer.stop();target.storona=-1;target.animate();target.setVisPos();
         eye=geom["eye"](target);target.shithp=50;aim(eye.x,eye.y);click();draw();ok(b.remaining(target)==0,"actual shield blocks pointer");m.pointer.stop();target.shithp=0;
         var S:Class=domain.getDefinition("MSWPointerSweep") as Class,sweep:*=new S(),hits:int=0;
         var accept:Function=function(hit:Object):void {if(hit.eye && hit.unit===target)hits++;};
         sweep.scan(w,300,eye.y,-.28,6,accept);sweep.scan(w,300,eye.y,.28,6,accept);
         ok(hits>0,"fast sweep crossing catches eye between two individually missing endpoints");
         var block:Object={X1:350,X2:360,Y1:80,Y2:420,dead:false,phis:1};w.loc.objs=[block];sweep.reset();hits=0;
         sweep.scan(w,300,eye.y,-.28,6,accept);sweep.scan(w,300,eye.y,.28,6,accept);
         ok(hits==0,"swept samples cannot blind through intervening wall box");w.loc.objs=[];
         sweep.reset();hits=0;target.setPos(500,280);target.actions();target.animate();target.setVisPos();
         sweep.scan(w,300,eye.y,0,6,accept);target.setPos(500,360);target.actions();target.animate();target.setVisPos();sweep.scan(w,300,eye.y,0,6,accept);
         ok(hits>0,"moving eye crossing a stationary beam is caught between samples");
         target.setPos(500,320);target.actions();target.animate();target.setVisPos();
         ok(target.hp==hp,"geometry-only sweep never deals direct damage");
      }
      private function settings():void
      {
         var items:Array=null;for each(var page:Object in m.settings.api.getPages())if(page.modId=="msw-pointer")items=page.items;
         ok(items!=null && items.length==5,"independent pointer page contains five settings");
         var gun:Number=m.cfg.laserDuration;items[1].set(9);items[2].set(8);items[3].set(3.4);items[4].set(true);m.cfg.save();
         var C:Class=domain.getDefinition("MSWConfig") as Class,c:*=new C();c.load();
         ok(c.pointerDuration==9 && c.pointerEye==8 && c.pointerRate==3.4 && c.pointerDebug && c.laserDuration==gun,"pointer settings persist independently from gun");
         for each(var item:Object in items)item.set(item.def);
         ok(m.cfg.pointerDuration==6 && m.cfg.pointerEye==6 && m.cfg.pointerRate==2 && !m.cfg.pointerDebug,"page defaults restore only pointer choices");
         m.panel.toggleOverlay();for(var i:int=0;i<4;i++)m.panel.handleKey(9);m.panel.update(w);
         saveStage("pointer-settings.png");m.panel.toggleOverlay();m.panel.update(w);
      }
      private function interruptions():void
      {
         var eye:Object=geom["eye"](target);aim(eye.x,eye.y);click();draw();
         ok(m.pointer.lit,"pointer relights after prior interruptions");
         w.pip.active=true;m.pointer.frame(w);w.pip.active=false;ok(!m.pointer.lit,"opening Pip stops beam");
         click();w.sats.active=true;m.pointer.frame(w);w.sats.active=false;ok(!m.pointer.lit,"entering SATS stops beam");
         click();var original:*=w.gg.currentWeapon;w.gg.currentWeapon=null;m.pointer.frame(w);w.gg.currentWeapon=original;ok(!m.pointer.lit,"holstering stops beam");
         click();w.gg.ggControl=false;m.pointer.frame(w);w.gg.ggControl=true;ok(!m.pointer.lit,"loss of player control stops beam");
      }
      private function capture(e:Event):void
      {
         try
         {
            var beam:*=w.grafon.visObjs[2].getChildByName("MSWPointerBeam");if(beam==null)return;beamFrames++;
            if(beamFrames%12!=0)return;
            var st:*=host.stage,a:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0),b:BitmapData=a.clone();
            a.draw(st);beam.visible=false;b.draw(st);beam.visible=true;var diff:*=a.compare(b),n:int=0;
            if(diff is BitmapData){for(var x:int=0;x<diff.width;x++)for(var y:int=0;y<diff.height;y++)if(diff.getPixel(x,y)!=0)n++;diff.dispose();}
            if(n>pixels){pixels=n;savePNG(a,"pointer-live.png");}a.dispose();b.dispose();
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function saveStage(name:String):void {var st:*=host.stage,b:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0);b.draw(st);savePNG(b,name);b.dispose();}
      private function savePNG(b:BitmapData,name:String):void
      {
         var E:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class,bytes:*=Object(b)["encode"](b.rect,new E());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();host.stage.removeEventListener(Event.EXIT_FRAME,capture);
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath("pointer-results.txt"),"write");fs.writeUTFBytes(log+(error?"FAIL "+error+"\n":"")+(pass?"PASS production pointer":"FAIL production pointer")+"\n");fs.close();
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(pass?0:1);
      }
   }
}
