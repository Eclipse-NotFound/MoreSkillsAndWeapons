package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   /** TEST ONLY: native candidate creation, hover handler and attack input.
    * Never hand-constructs or pushes a SatsCel. */
   public class LaserSatsSelectSmoke extends Sprite
   {
      private static var inst:LaserSatsSelectSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100),domain:ApplicationDomain;
      private var w:*,m:*,enemy:*,ticks:int=0,started:Boolean=false,log:String="";
      private var reloading:Boolean=false,oldPlayer:*,reloadTick:int=0;
      public function LaserSatsSelectSmoke() {}
      public static function init(main:*):void {inst=new LaserSatsSelectSmoke();inst.start(main);}
      private function cls(name:String):Class {return domain.getDefinition(name) as Class;}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](host);
            timer.addEventListener("timer",tick);timer.start();
         });
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
      }
      private function ok(value:Boolean,text:String):void {if(!value)throw new Error(text);log+="PASS "+text+"\n";}
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks>600)throw new Error("scene readiness timeout");
            w=cls("fe.World")["w"];m=cls("MoreSkillsWeaponsMod")["testInstance"]();
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(ticks<90 || w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswdazzler"]==null)return;
            if(reloading && (w.gg===oldPlayer || ticks-reloadTick<30))return;
            w.gg.controlOn();if(w.gg.atkPoss==0)return;
            timer.stop();if(w.pip.active)w.pip.onoff();w.gui.dialText();w.onPause=false;w.catPause=false;w.loc.base=false;w.weaponsLevelsOff=false;
            if(reloading)
            {
               ok(w.gg.currentWeapon===w.invent.weapons["mswdazzler"] && w.gg.newWeapon===w.gg.currentWeapon,"native reload restores current, inventory and pending dazzler identity");
               setup();testSelection("mswdazzler","reloaded");testSelection("lasp","switched-back");
               ok(m.cfg.diag.laserError==null,"no laser runtime errors through selection, cancellation, switching and loading");
               finish(true,"");return;
            }
            setup();testSelection("lasp");testSelection("mswdazzler");testQueueControls();
            w.gg.changeWeapon("mswdazzler",true);w.saveGame(1);oldPlayer=w.gg;w.comLoad=1;reloadTick=ticks;reloading=true;timer.start();
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function setup():void
      {
         m.laser.blind.clear();
         for(var x:int=120;x<1000;x+=20)for(var y:int=80;y<500;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;tile.visi=1;}
         w.gg.setPos(240,320);w.gg.storona=1;w.gg.dx=w.gg.dy=0;w.gg.actions();w.gg.setVisPos();w.gg.work="";w.gg.t_work=0;
         enemy=w.loc.createUnit("raider",430,320,true);enemy.fraction=2;enemy.sost=1;enemy.hp=enemy.maxhp;
         enemy.disabled=enemy.trigDis=enemy.npc=enemy.noAgro=false;enemy.storona=-1;enemy.shithp=enemy.t_emerg=0;enemy.isVis=true;
         enemy.setPos(430,320);enemy.actions();enemy.animate();enemy.setVisPos();w.loc.units=[w.gg,enemy];w.loc.objs=[];
         w.celX=w.gg.celX=enemy.X;w.celY=w.gg.celY=enemy.Y-enemy.scY/2;
         w.invent.items.batt.kol=100;if(w.invent.weapons["lasp"]==null)w.invent.addWeapon("lasp");
      }
      private function recordFor(u:*):Object
      {for each(var row:Object in w.sats.units)if(row.u===u)return row;return null;}
      private function clickTarget(u:*):void
      {
         var row:Object=recordFor(u);ok(row!=null,"native candidate exists for queued target");
         row.du.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER,true));w.ctr.keyAttack=true;w.sats.step();
         row.du.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT,true));
      }
      private function testSelection(id:String,phase:String="fresh"):void
      {
         log+="PHASE "+phase+"\n";m.laser.blind.clear();
         var wp:*=w.invent.weapons[id];
         // Selecting the already held weapon holsters it in the native game.
         // In particular, exercise the genuinely loaded gun without re-equipping.
         if(w.gg.currentWeapon!==wp)w.gg.changeWeapon(id,true);
         ok(w.gg.currentWeapon===wp,"native equip "+id);
         wp.hold=wp.holder;wp.t_attack=wp.t_auto=wp.t_reload=0;wp.ready=true;wp.hp=wp.maxhp;
         for(var i:int=0;i<15;i++){w.gg.setWeaponPos();wp.step();}m.laser.prepare(w);
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class;
         if(id=="mswdazzler" && F["applicationDirectory"].resolvePath("sats-select-disable-noperc.txt").exists)
         {wp.noPerc=false;log+="DIAGNOSTIC ONLY: mswdazzler.noPerc=false; production bytes unchanged\n";}
         ok(w.gg.isMeet(enemy) && enemy.isSats && enemy.sost<3 && !enemy.invis && w.gg.look(enemy)>0 && enemy.getTileVisi(),"fixture satisfies native visibility and candidate rules "+id);
         w.sats.od=80;w.sats.onoff(1);ok(w.sats.active,"native SATS opens "+id);
         var record:Object=recordFor(enemy);
         ok(record!=null,"native candidate contains visible enemy "+id);
         record.du.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER,true));
         var hovered:Boolean=record.du.filters.length>0;
         w.ctr.keyAttack=true;w.sats.step();
         ok(w.sats.que.length==1,"native attack input creates exactly one queue entry "+id);
         var selected:*=cls("fe.inter.MSWLaserSats")["target"](w.sats.que[0]);
         log+="OBS "+id+" noPerc="+wp.noPerc+" damage="+wp.damage+" candidates="+w.sats.units.length+" highlight="+hovered+" selected="+(selected===enemy?"enemy":"point")+" reservedAP="+(w.sats.od-w.sats.odv)+"\n";
         screenshot(id+"-selection.png");
         ok(hovered && selected===enemy,"hover and native click select the enemy identity "+id);
         m.laser.frame(w);
         var label:String=record.v.getChildByName("su").txt.text;
         screenshot(id+"-"+phase+"-label.png");
         ok(id=="mswdazzler"?label.replace(/\r/g,"\n")==enemy.nazv+"\n瞄眼":label.indexOf("%")>=0 && label.indexOf("瞄眼")<0,"weapon-specific SATS label "+id);
         record.du.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT,true));
         ok(record.du.filters.length==0,"native hover clears on mouse out "+id);
         w.sats.onoff(-1);
         if(id=="mswdazzler")
         {
            var hp:Number=enemy.hp,ammo:int=wp.hold;
            for(i=0;i<100 && w.sats.que.length>0;i++){w.gg.step();m.laser.frame(w);}
            log+="OBS execution queue="+w.sats.que.length+" AP="+w.sats.od+" ammo="+ammo+"->"+wp.hold+" blind="+m.laser.blind.remaining(enemy)+" hp="+hp+"->"+enemy.hp+"\n";
            ok(w.sats.que.length==0 && w.sats.od>=63 && w.sats.od<64,"native selected queue executes and charges seventeen AP");
            ok(m.laser.blind.remaining(enemy)>0 && wp.hold==ammo-2 && enemy.hp==hp,"native selected shot blinds without damage and spends two batteries");
         }
         w.sats.clearAll();
      }
      private function testQueueControls():void
      {
         m.laser.blind.clear();w.gg.setPos(240,320);w.gg.dx=w.gg.dy=0;w.gg.actions();w.gg.setVisPos();
         var other:*=w.loc.createUnit("raider",600,220,true);
         other.fraction=2;other.sost=1;other.disabled=other.trigDis=other.npc=other.noAgro=false;other.storona=-1;
         other.setPos(600,220);other.actions();other.animate();other.setVisPos();w.loc.units=[w.gg,enemy,other];
         var wp:*=w.gg.currentWeapon,ammo:int=wp.hold;w.sats.od=80;w.sats.onoff(1);m.laser.frame(w);
         clickTarget(other);clickTarget(enemy);
         var bridge:Class=cls("fe.inter.MSWLaserSats");
         ok(w.sats.que.length==2 && bridge["target"](w.sats.que[0])===other && bridge["target"](w.sats.que[1])===enemy,"multiple targets retain native click order and exact identities");
         ok(w.sats.odv==46 && w.sats.od==80,"two queued shots reserve thirty-four AP without spending it");
         w.ctr.keyTele=true;w.sats.step();
         ok(w.sats.que.length==1 && bridge["target"](w.sats.que[0])===other && w.sats.odv==63,"native cancel removes last target and restores reserved AP");
         w.ctr.keyTele=true;w.sats.step();
         ok(w.sats.que.length==0 && w.sats.odv==80 && !w.sats.active,"native cancel clears final target, restores full AP and exits SATS");
         w.sats.onoff(1);m.laser.frame(w);
         w.celX=800;w.celY=100;w.ctr.keyAttack=true;w.sats.step();
         ok(w.sats.que.length==1 && bridge["target"](w.sats.que[0])==null,"empty-space click remains a manual coordinate shot");
         w.ctr.keyTele=true;w.sats.step();w.sats.onoff(-1);w.sats.clearAll();
         ok(wp.hold==ammo && m.laser.blind.remaining(enemy)==0 && m.laser.blind.remaining(other)==0,"cancelling and exiting do not fire or blind");
         w.sats.od=16;w.sats.onoff(1);m.laser.frame(w);clickTarget(enemy);
         ok(w.sats.que.length==0 && w.sats.odv==16,"insufficient AP cannot queue an eye shot");w.sats.onoff(-1);w.sats.clearAll();
         w.sats.od=80;w.sats.onoff(1);m.laser.frame(w);clickTarget(enemy);
         ok(w.sats.que.length==1 && bridge["target"](w.sats.que[0])===enemy,"reopening SATS restores a working native selection");
         w.ctr.keyTele=true;w.sats.step();w.sats.onoff(-1);w.sats.clearAll();
         w.gg.changeWeapon("mswlaserpointer",true);ok(w.gg.currentWeapon.id=="mswlaserpointer","native equip pointer for exclusion check");
         w.sats.onoff(1);ok(!w.sats.active && w.sats.que.length==0,"laser pointer still cannot enter SATS");
      }
      private function screenshot(name:String):void
      {
         var st:*=host.stage,b:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0);b.draw(st);
         var Opt:Class=cls("flash.display.PNGEncoderOptions");write(name,Object(b)["encode"](b.rect,new Opt()),true);b.dispose();
      }
      private function write(name:String,value:*,binary:Boolean=false):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,s:*=new S();
         s.open(F["applicationStorageDirectory"].resolvePath(name),"write");if(binary)s.writeBytes(value);else s.writeUTFBytes(String(value));s.close();
      }
      private function finish(pass:Boolean,error:String):void
      {timer.stop();write("sats-select-results.txt",log+(error?"FAIL "+error+"\n":"")+(pass?"PASS native SATS selection":"FAIL native SATS selection")+"\n");getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);}
   }
}
