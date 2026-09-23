package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
   import flash.text.TextField;
   public class ExclusionProductionSmoke extends Sprite
   {
      private static var probe:ExclusionProductionSmoke;
      private var host:*,loader:Loader=new Loader(),domain:ApplicationDomain,timer:Timer=new Timer(50);
      private var m:*,w:*,gun:*,rat:*,mole:*,raider:*,flying:*,hud:*;
      private var ticks:int=0,phase:int=0,since:int=0,count:int=0,page:int=0;
      private var log:String="",rows:Array=[],allRows:Array=[],sizes:Array=[18,13];
      public function ExclusionProductionSmoke() {}
      public static function init(main:*):void {probe=new ExclusionProductionSmoke();probe.start(main);}
      private function cls(n:String):Class {return domain.getDefinition(n) as Class;}
      private function ok(v:Boolean,s:String):void {if(!v)throw new Error(s);count++;log+="PASS "+s+"\n";}
      private function start(main:*):void
      {
         host=main;
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            try{domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](host);timer.addEventListener("timer",tick);timer.start();}
            catch(err:*){finish(false,err+"\n"+err.getStackTrace());}
         });
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void{finish(false,e.text);});
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function next(p:int):void {phase=p;since=getTimer();}
      private function collect(o:*):void
      {if(o==null || !o.visible)return;if("settingsItem" in o && o.settingsItem!=null)rows.push(o);if("numChildren" in o)for(var i:int=0;i<o.numChildren;i++)collect(o.getChildAt(i));}
      private function named(o:*,name:String):*
      {if(o==null || !o.visible)return null;if(o.name==name)return o;if("numChildren" in o)for(var i:int=0;i<o.numChildren;i++){var result:*=named(o.getChildAt(i),name);if(result!=null)return result;}return null;}
      private function position(u:*,x:Number,y:Number):void
      {u.setPos(x,y);u.X1=x-u.scX/2;u.X2=x+u.scX/2;u.Y1=y-u.scY;u.Y2=y;if(u.vis!=null)u.setVisPos();}
      private function nativeUnit(factory:String,cid:String=null):*
      {
         var u:*=cls("fe.unit.Unit")["create"](factory,10,null,null,cid);
         ok(u!=null,"native factory "+factory+"/"+cid);u.loc=w.loc;u.hp=u.maxhp=100000;u.sost=1;u.fraction=2;
         u.disabled=u.trigDis=u.npc=u.noAgro=false;u.isVis=true;return u;
      }
      private function matrix():void
      {
         var cases:Array=[["bloodwing","bloodwing","2"],["fish","fish",null],["tarakan","tarakan",null],["rat","rat",null],["molerat","molerat",null],
            ["scorp","scorp3",null],["ant","ant","3"],["slime","slime",null],["bloat","bloat","10"],
            ["necros","necros",null],["ebloat","ebloat",null],["eant","eant",null],
            ["spritebot","spritebot",null],["vortex","vortex",null],["roller","roller","2"],["msp","msp",null],["dron","dron","3"],
            ["hmine","mine","hmine"],["mine","mine","mine"],["plamine","mine","plamine"],["impmine","mine","impmine"],["zebmine","mine","zebmine"],["balemine","mine","balemine"],
            ["trigcans","trcans",null],["trigridge","trridge",null],["trigplate","trplate",null],["triglaser","trlaser",null],
            ["damshot","damshot",null],["damgren","damgren",null],["damexpl1","expl1",null],["transmitter","transm",null]];
         for each(var row:Array in cases) {
            var u:*=nativeUnit(row[1],row[2]);m.cfg.smartExclusions={};ok(m.smart.targetAllowed(u,w),"native target initially allowed "+u.id);
            m.cfg.smartExclusions[row[0]]=true;ok(!m.smart.targetAllowed(u,w),"native entity excluded by correct option "+row[0]+":"+u.id);
            delete m.cfg.smartExclusions[row[0]];ok(m.smart.targetAllowed(u,w),"native entity permitted again "+u.id);
         }
         m.cfg.smartExclusions={};
      }
      private function bullet():*
      {
         var b:*=new (cls("fe.weapon.Bullet"))(w.gg,300,280,null,true);
         b.weap=gun;b.damage=1;b.tipDamage=0;b.precision=10;b.miss=1;b.dx=10;b.dy=0;b.vel=10;return b;
      }
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks%100==0)write("heartbeat.txt","phase="+phase+" ticks="+ticks+"\n"+log);
            if(ticks>1800)throw new Error("timeout phase="+phase);
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            var elapsed:int=getTimer()-since,i:int,r:*,item:*,b:*,u:*,tile:*,snapshot:*;
            if(phase==0) {
               // The fixture's final automatic page switch occurs about 800 frames
               // after the world starts. Begin only after it relinquishes the UI.
               if(m.cfg.diag.frames<1100)return;
               ok(m.cfg.diag.ver=="1.12.0-nonfront-laser","exact production version loaded");
               ok(m.cfg.diag.smartMotionVersion=="1.4-adaptive-radius" && m.cfg.diag.laserRuntimeVersion=="7-nonfront-assist","adaptive motion and current laser components preserved");
               var exemptionPages:int=0;
               for each(var registered:Object in m.settings.getPages())if(String(registered.modId).indexOf("msw-exempt")==0){exemptionPages++;ok(registered.modId=="msw-exempt" && registered.items.length==31,"one registered menu contains all 31 options");}
               ok(exemptionPages==1,"only one exemption entry alongside other mods");
               // Same stored keys as v1.9.0, spanning both internal pages.
               m.cfg.smartExclusions={rat:true,mine:true,transmitter:true};m.cfg.save();
               if(!w.pip.active)w.pip.onoff(5);if(!m.panel.tabActive())m.panel.tabToggle(w);
               if(!m.settings.api.selectPage("msw-exempt"))return;next(1);return;
            }
            if(phase==1 && elapsed>200) {
               rows=[];collect(host);ok(rows.length==sizes[page],"internal page "+page+" count="+rows.length);
               for each(r in rows) {
                  item=r.settingsItem;var previous:Boolean=item.key=="smartExclude_rat" || item.key=="smartExclude_mine" || item.key=="smartExclude_transmitter";
                  ok(item.get()==previous && r.settingsSc.selected==previous,"existing choice preserved "+item.key);
                  r.settingsSc.selected=true;r.settingsSc.dispatchEvent(new Event(Event.CHANGE));ok(item.get(),"actual checkbox "+item.key);
                  var saved:*=new (cls("MSWConfig"))();saved.load();ok(saved.smartExclusions[item.key.substr(13)]===true,"persistent UI choice "+item.key);
               }
               allRows=allRows.concat(rows);screenshot("settings-page"+(page+1)+".png");
               if(page==0){r=named(host,"SettingsNextItems");ok(r!=null && r.mouseEnabled,"internal next page enabled");r.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));page=1;next(1);return;}
               ok(allRows.length==31,"all options reached through internal paging");
               r=named(host,"SettingsPreviousItems");ok(r!=null && r.mouseEnabled,"internal previous page enabled");r.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
               rows=[];collect(host);ok(rows.length==18 && rows[0].settingsItem.key=="smartExclude_bloodwing" && rows[0].settingsSc.selected,"return to first internal page keeps choices");
               r=named(host,"SettingsReset");ok(r!=null,"page reset exists");r.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
               for each(r in allRows)ok(!r.settingsItem.get(),"all-group default restored "+r.settingsItem.key);
               w.pip.onoff();m.panel.toggleOverlay();
               for(i=0;i<3;i++)m.panel.handleKey(9);
               for(i=0;i<31;i++){
                  m.panel.handleKey(39);ok(allRows[i].settingsItem.get(),"F6 reaches option "+i);
                  if(i==30){m.panel.update(w);var overlay:*=host.getChildByName("MSWF6Panel");ok(overlay!=null && overlay.text.indexOf("发报机")>=0 && overlay.text.indexOf("血翼")<0 && overlay.y+overlay.height<=host.stage.stageHeight && overlay.x+overlay.width<=host.stage.stageWidth,"F6 scrolls final option within screen");screenshot("settings-f6.png");}
                  m.panel.handleKey(40);
               }
               m.panel.handleKey(9);m.panel.update(w);ok(host.getChildByName("MSWF6Panel").text.indexOf("MoreSkills&Weapons")==0,"F6 cycles four menus back to main");
               m.panel.handleKey(33);m.panel.handleKey(39);ok(!m.cfg.smartExclusions.bloodwing,"F6 wraps backwards to single exemption menu");m.panel.toggleOverlay();
               m.cfg.smartExclusions={};matrix();
               w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
               for(var x:int=100;x<1200;x+=20)for(var y:int=40;y<650;y+=20){tile=w.loc.getAbsTile(x,y);tile.phis=0;tile.water=0;}
               position(w.gg,240,320);w.gg.dx=w.gg.dy=0;w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.cam.celX=440;w.cam.celY=280;
               gun=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");w.gg.currentWeapon=gun;
               rat=w.loc.createUnit("rat",440,300,true);mole=w.loc.createUnit("molerat",620,300,true);raider=w.loc.createUnit("raider",760,300,true);
               for each(u in [rat,mole,raider]){u.hp=u.maxhp=100000;u.disabled=u.trigDis=u.npc=u.noAgro=false;u.fraction=2;u.sost=1;u.isVis=true;}
               w.loc.units=[w.gg,rat,mole,raider];w.celX=440;w.celY=rat.Y-4;
               m.cfg.smartEnabled=true;m.cfg.smartMultiLock=false;m.cfg.smartAcquire=0.6;m.cfg.smartExclusions={};m.cfg.smartKeepOutOfSight=true;
               m.cfg.smartAdaptiveRadius=true;m.cfg.smartMinTurnRadius=10;
               m.smart.frame(w);next(2);return;
            }
            if(phase==2 && elapsed>200) {
               ok(m.smart.lock.candidate===rat && m.smart.lock.progress>0,"single target acquisition begins");
               m.cfg.smartExclusions.rat=true;m.smart.frame(w);ok(m.smart.lock.candidate==null && m.smart.lock.target==null,"exemption cancels unfinished acquisition immediately");
               m.cfg.smartMultiLock=true;w.celX=w.celY=-1000;m.smart.frame(w);next(3);return;
            }
            if(phase==3 && elapsed>850) {
               ok(m.smart.multiLock.stateFor(rat)==null && m.smart.multiLock.locks.length==2,"multi mode acquires only non-exempt enemies");
               for(i=0;i<4;i++){b=bullet();m.smart.frame(w);snapshot=m.smart.snapshot(b);ok(snapshot!=null && snapshot.target!==rat,"new shot never selects excluded rat");}
               m.cfg.smartExclusions={};m.smart.frame(w);ok(m.smart.multiLock.stateFor(rat).target==null,"removing exemption starts acquisition anew");next(4);return;
            }
            if(phase==4 && elapsed>850) {
               ok(m.smart.multiLock.locks.length==3 && m.smart.multiLock.stateFor(rat).target===rat,"rat reacquires normally");
               // Exercise the time-stop handshake with native bullets; this is
               // a focused replay-order test, not a full Sandevistan run.
               w.onPause=false;m.smart.prepare(w);w.onPause=true;w.godMode=false;m.smart.prepare(w);
               var recorded:Array=[];
               for(i=0;i<3;i++){b=bullet();m.smart.frame(w);recorded.push(m.smart.snapshot(b).target);if(m.smart.snapshot(b).target===rat)flying=b;}
               ok(flying!=null,"one in-flight bullet tracks rat");m.cfg.smartExclusions.rat=true;m.smart.frame(w);
               ok(m.smart.multiLock.stateFor(rat)==null && m.smart.multiLock.locks.length==2,"held lock removed without disturbing others");
               m.smart.beforeProjectiles();m.smart.afterProjectiles();ok(m.smart.snapshot(flying).remaining==0,"existing bullet stops guidance without retargeting");
               w.godMode=true;m.smart.prepare(w);
               for(i=0;i<3;i++) {
                  b=bullet();m.smart.beforeProjectiles();m.smart.afterProjectiles();snapshot=m.smart.snapshot(b);
                  ok(recorded[i]===rat?snapshot==null:snapshot!=null && snapshot.target===recorded[i],"replay retains shot order while skipping exempt target "+i);
               }
               w.onPause=false;w.godMode=false;m.smart.prepare(w);w.onPause=true;m.smart.prepare(w);
               m.cfg.smartMultiLock=false;m.cfg.smartExclusions={};w.celX=440;w.celY=rat.Y-4;m.smart.frame(w);next(5);return;
            }
            if(phase==5 && elapsed>850) {
               ok(m.smart.lock.target===rat,"single target full lock restored");
               m.cfg.smartExclusions.rat=true;m.smart.frame(w);ok(m.smart.lock.target==null,"single completed lock is also removed");
               hud=host.getChildByName("MSWSmartHUD");ok(hud!=null && !hud.visible,"excluded single marker removed");
               ok(m.cfg.diag.smartError==null && m.cfg.diag.laserError==null,"no module errors");finish(true,"");
            }
         }catch(err:*){finish(false,err+"\n"+err.getStackTrace());}
      }
      private function screenshot(name:String):void
      {
         var bmp:BitmapData=new BitmapData(host.stage.stageWidth,host.stage.stageHeight,false,0);bmp.draw(host.stage);
         var opts:Class=cls("flash.display.PNGEncoderOptions"),bytes:*=Object(bmp)["encode"](bmp.rect,new opts()),S:Class=cls("flash.filesystem.FileStream"),stream:*=new S();
         stream.open(cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");stream.writeBytes(bytes);stream.close();bmp.dispose();
      }
      private function write(name:String,value:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,s:*=new S();
         s.open(F["applicationStorageDirectory"].resolvePath(name),"write");s.writeUTFBytes(value);s.close();
      }
      private function finish(pass:Boolean,error:String):void
      {timer.stop();write("production-exclusion.txt",log+(error?"FAIL "+error+"\n":"")+"checks="+count+"\n"+(pass?"PASS production exclusion":"FAIL production exclusion")+"\n");getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);}
   }
}
