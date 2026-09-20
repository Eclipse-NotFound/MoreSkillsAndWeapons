package
{
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
   import flash.utils.getQualifiedClassName;
   public class SmartProbe
   {
      private var timer:Timer=new Timer(50), t:int=0, phase:int=0, since:int=0;
      private var w:*,m:*,target:*,weapon:*,bullet:*;
      private var rows:Array=[],log:String="";
      private var sightWall:Array=[],stateSince:int=0,held:Number=0;
      public function SmartProbe() { timer.addEventListener("timer",tick);timer.start(); }
      private function ok(v:Boolean,s:String):void { if(!v)throw new Error(s);log+="PASS "+s+"\n"; }
      private function find(o:*,text:String):* { if(o==null || !o.visible)return null;if(o is TextField && o.text==text)return o.parent;if("numChildren" in o)for(var i:int=0;i<o.numChildren;i++){var b:*=find(o.getChildAt(i),text);if(b!=null)return b;}return null; }
      private function collect(o:*):void {if(o==null || !o.visible)return;if("settingsItem" in o && o.settingsItem!=null)rows.push(o);if("numChildren" in o)for(var i:int=0;i<o.numChildren;i++)collect(o.getChildAt(i));}
      private function tick(e:Event):void
      {
         try
         {
            t++; if(t%100==0)write("heartbeat.txt","tick="+t+" phase="+phase+"\n"+log);
            if(t>1600)throw new Error("timeout phase "+phase);
            m=MoreSkillsWeaponsMod.testInstance();if(m==null)return;
            w=MSWU.world();if(w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(w.verror.visible)throw new Error("game dialog: "+w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            if(phase==0)
            {
               if(t<160)return;
               if(!w.pip.active)w.pip.onoff(5);
               if(!m.panel.tabActive())m.panel.tabToggle(w);
               if(MSWU.has(m.settings,"api") && m.settings.api!=null)
               {
                  if(!m.settings.api.selectPage("msw-smart"))return;
                  phase=1;since=t;return;
               }
               var tab:*=find(w.main,"智能武器");if(tab==null)return;
               tab.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));phase=1;since=t;return;
            }
            if(phase==1 && t-since>10)
            {
               rows=[];collect(w.main);ok(rows.length==10,"real smart settings page shows 10 controls");
               ok(rows[0].settingsItem.key=="smartEnabled" && !m.cfg.smartEnabled,"default off in real UI");
               var sliders:int=0;var stored:MSWConfig;
               for each(var r:* in rows)
               {
                  if(r.settingsItem.kind=="slider") { sliders++;r.settingsSc.scrollPosition=(r.settingsItem.def-r.settingsItem.min)/r.settingsItem.step;r.settingsSc.dispatchEvent(new Event("scroll")); }
                  if(r.settingsSc!=null && "drawNow" in r.settingsSc)r.settingsSc.drawNow();
               }
               ok(sliders==9 && m.cfg.smartGrace==0.15,"all nine sliders and 0.15 precision");
               rows[3].settingsSc.scrollPosition=5;rows[3].settingsSc.dispatchEvent(new Event("scroll"));
               m.panel.tabToggle(w);stored=new MSWConfig();stored.load();
               ok(stored.smartGrace==0.25,"changed decimal slider persists on page close");m.panel.tabToggle(w);
               rows=[];collect(w.main);
               rows[0].settingsSc.selected=true;rows[0].settingsSc.dispatchEvent(new Event(Event.CHANGE));
               ok(m.cfg.smartEnabled,"real checkbox enables smart guns");
               stored=new MSWConfig();stored.load();ok(stored.smartEnabled,"checkbox saves immediately");
               var reset:*=find(w.main,"恢复默认");ok(reset!=null,"smart reset button exists");reset.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
               ok(!m.cfg.smartEnabled && m.cfg.smartLife==2 && m.cfg.smartTurn==1080,"reset restores smart defaults");
               screenshot();w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
               m.panel.toggleOverlay();m.panel.handleKey(9);m.panel.handleKey(39);
               ok(m.cfg.smartEnabled,"F6 Tab smart page toggles master");
               m.panel.handleKey(40);m.panel.handleKey(39);ok(m.cfg.smartRadius==52,"F6 smart page adjusts numeric setting");
               m.panel.handleKey(9);m.panel.toggleOverlay();m.cfg.smartRadius=48;
               m.cfg.smartEnabled=true;m.cfg.ricochet=false;m.cfg.clamp();
               var W:Class=MSWU.cls("fe.weapon.Weapon");weapon=W["create"](w.gg,"p9mm");w.gg.currentWeapon=weapon;
               ok(MSWSmartWeapons.weaponAllowed(weapon),"actual pistol classified by gun kind");
               ok(!MSWSmartWeapons.weaponAllowed(W["create"](w.gg,"rail")),"rail gun excluded despite ballistic damage type");
               for(var x:int=160;x<=700;x+=10)for(var y:int=80;y<=420;y+=10){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null)tile.phis=0;}
               var U:Class=MSWU.cls("fe.unit.Unit");target=new U();target.loc=w.loc;target.fraction=2;target.sost=1;target.hp=target.maxhp=100000;
               target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;target.skin=target.armor=target.armor_qual=target.shithp=0;target.dexter=100;
               pos(360,240);w.loc.units.push(target);w.testDam=true;w.showHit=0;
               m.smart.frame(w);m.smart.lock.target=target;m.smart.lock.strength=1;
               ok(w.loc.firstObj is MSWSmartStep,"hook is an original Pt subclass");
               bullet=spawn(220,180,20,0);ok(bullet.liv==100 && bullet.precision==10,"newborn bullet before first motion");
               w.loc.firstObj.step();
               ok(m.smart.snapshot(bullet)!=null && bullet.precision==0 && bullet.miss==0,"hook configures newborn before Bullet.step");
               ok(bullet.dy>0 && bullet.liv==100,"first-step steering before lifetime decrement");
               bullet.step();ok(bullet.liv==99 && bullet.Y>180,"real Bullet follows steered trajectory");
               var remaining:Number=m.smart.snapshot(bullet).remaining;
               m.smart.frame(w);m.smart.frame(w);ok(m.smart.snapshot(bullet).remaining==remaining,"display-only frozen frames do not consume budget");
               m.smart.lock.clear();w.loc.firstObj.step();ok(m.smart.snapshot(bullet).remaining<remaining,"shot remains independent after weapon loses lock");
               bullet.damage=0;w.loc.firstObj.step();ok(m.smart.snapshot(bullet).remaining>0,"time-stop temporary zero damage does not cancel guidance");
               bullet.damage=100;var clone:*=spawn(220,180,-20,0);m.smart.inherit(bullet,clone);
               ok(Math.abs(m.smart.snapshot(clone).remaining-(m.cfg.smartLife-3/30))<0.00001,"bounce inherits remaining budget without refresh");
               target.fraction=100;w.loc.firstObj.step();ok(m.smart.snapshot(clone).remaining==0,"converted ally cancels existing guidance");target.fraction=2;
               m.smart.lock.target=target;m.smart.lock.strength=1;bullet=spawn(340,240,20,0);w.loc.firstObj.step();
               var hp:Number=target.hp;bullet.step();ok(target.hp<hp,"actual collision damages high-evasion target with smart accuracy");
               pos(520,240);var wall:Array=[];
               for(x=320;x<400;x+=40)for(y=200;y<280;y+=40){tile=w.loc.getAbsTile(x+1,y+1);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=y;tile.phY2=y+40;wall.push(tile);}
               ok(!MSWSmartRoute.clear(w.loc,220,240,520,240),"real terrain blocks direct shot");
               bullet=spawn(220,240,20,0);hp=target.hp;var curved:Boolean=false;var trajectory:String="";
               for(j=0;j<50 && !bullet.babah;j++){w.loc.firstObj.step();bullet.step();trajectory+=int(bullet.X)+","+int(bullet.Y)+" ";if(Math.abs(bullet.Y-240)>40)curved=true;}
               write("trajectory.txt",trajectory);ok(curved && target.hp<hp,"real Bullet curves around solid box and hits covered target");
               for each(tile in wall)tile.phis=0;
               // Force a close collision that a slow-turning round cannot avoid.
               for each(tile in wall)tile.phis=1;
               m.cfg.ricochet=true;m.cfg.ricochetCount=2;m.cfg.smartTurn=90;
               bullet=spawn(310,240,25,0);m.bullets.process(w);w.loc.firstObj.step();
               var shot:Object=m.smart.snapshot(bullet);bullet.step();ok(bullet.babah,"smart shot physically collides with close wall");
               remaining=shot.remaining;m.bullets.process(w);
               var bounced:*=w.loc.firstObj;
               while(bounced!=null && (bounced===bullet || m.smart.snapshot(bounced)!==shot))bounced=bounced.nobj;
               ok(bounced!=null && bounced.dx<0 && bounced.precision==0,"real ricochet reflects smart bullet and keeps accuracy");
               ok(shot.remaining==remaining,"real ricochet does not reset guidance budget");
               w.loc.firstObj.step();ok(shot.remaining<remaining,"reflected smart round resumes guidance");
               m.cfg.ricochet=false;m.cfg.smartTurn=1080;for each(tile in wall)tile.phis=0;
               pos(360,240);
               m.cfg.smartLife=0.1;m.smart.lock.target=target;m.smart.lock.strength=1;bullet=spawn(220,180,-15,0);
               for(var j:int=0;j<3;j++)w.loc.firstObj.step();
               ok(m.smart.snapshot(bullet).remaining<0.000001,"guidance expires at configured physics budget");
               var angle:Number=bullet.rot;w.loc.firstObj.step();ok(bullet.rot==angle && bullet.precision==0 && bullet.liv>0,"expiry keeps physical bullet and accuracy exemption");
               m.cfg.smartLife=2;
               var shotgun:*=W["create"](w.gg,"oldshot");shotgun.setPers(w.gg,w.gg.pers);shotgun.X=220;shotgun.Y=180;
               shotgun.hold=shotgun.holder;shotgun.ammoMod=3;shotgun.t_attack=shotgun.rapid;
               shotgun.step();w.loc.firstObj.step();
               var pellet:*=w.loc.firstObj;var pellets:int=0;
               while(pellet!=null){if(getQualifiedClassName(pellet)=="fe.weapon::Bullet" && pellet.weap===shotgun){pellets++;ok(pellet.tipDamage==3 && pellet.precision==0 && m.smart.snapshot(pellet)!=null,"actual shotgun special-ammo pellet guided");}pellet=pellet.nobj;}
               ok(pellets>1,"original shotgun creates multiple independently guided pellets");
               pos(520,240);for each(tile in wall)tile.phis=1;
               var many:Array=[];for(j=0;j<64;j++)many.push(spawn(220+j%8,240,20,0));
               var cost:int=getTimer();w.loc.firstObj.step();cost=getTimer()-cost;
               for each(pellet in many)if(m.smart.snapshot(pellet)==null || pellet.precision!=0)throw new Error("pellet batch lost guidance");
               ok(cost<2000,"64-round local-routing batch completes in "+cost+" ms");
               var spread:Array=[];for(x=180;x<=270;x+=30)for(y=210;y<=270;y+=30)spread.push(spawn(x,y,20,0));
               for(j=0;j<4;j++)w.loc.firstObj.step();
               for each(pellet in spread)if(m.smart.snapshot(pellet).route.length==0)throw new Error("deferred route starved");
               ok(true,"later rounds receive deferred route searches across steps");
               for each(tile in wall)tile.phis=0;
               m.cfg.smartEnabled=false;m.smart.frame(w);ok(!(w.loc.firstObj is MSWSmartStep),"disabled feature detaches head hook");
               m.cfg.smartLife=2;m.cfg.smartEnabled=true;
               w.visual.x=w.visual.y=0;w.visual.scaleX=w.visual.scaleY=1;
               w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.cam.celX=440;w.cam.celY=240;
               w.gg.setPos(220,260);pos(440,240);w.celX=440;w.celY=240;
               m.smart.frame(w);m.smart.lock.clear();
               ok(m.smart.visible(target,w),"real target visible through clear terrain");
               phase=2;stateSince=getTimer();return;
            }
            if(phase>=2)
            {
               w.celX=440;w.celY=240;m.smart.frame(w);
               var elapsed:int=getTimer()-stateSince;
               if(phase==2 && elapsed>900)
               {
                  ok(m.smart.lock.target===target && m.smart.lock.strength==1,"real frame clock acquires reticle target");
                  for(y=80;y<400;y+=40){tile=w.loc.getAbsTile(321,y+1);tile.phis=1;tile.phX1=320;tile.phX2=360;tile.phY1=y;tile.phY2=y+40;sightWall.push(tile);}
                  ok(!m.smart.visible(target,w),"wall removes player line of sight");
                  phase=3;stateSince=getTimer();
               }
               else if(phase==3 && elapsed>1100)
               {
                  ok(m.smart.lock.target===target && m.smart.lock.strength>0 && m.smart.lock.strength<0.9,"real occlusion holds then weakens lock");
                  var hud:*=w.main.getChildByName("MSWSmartHUD");ok(hud!=null && hud.visible,"locked target marker remains through terrain");
                  for each(tile in sightWall)tile.phis=0;
                  phase=4;stateSince=getTimer();
               }
               else if(phase==4 && elapsed>600)
               {
                  ok(m.smart.lock.strength==1,"real reappearance gradually restores signal");
                  for each(tile in sightWall)tile.phis=1;
                  held=m.smart.lock.strength;w.pip.onoff(5);phase=5;stateSince=getTimer();
               }
               else if(phase==5 && elapsed>800)
               {
                  ok(m.smart.lock.strength==held,"real menu pause freezes lock timer");w.pip.onoff();
                  phase=6;stateSince=getTimer();
               }
               else if(phase==6 && elapsed>2500)
               {
                  ok(m.smart.lock.target==null && m.smart.lock.candidate==null,"complete occluded loss cannot reacquire through wall");
                  finish("PASS smart game smoke",0);
               }
            }
         }
         catch(err:*) {finish("FAIL "+err+"\n"+err.getStackTrace(),1);}
      }
      private function pos(x:Number,y:Number):void {target.X=x;target.Y=y+20;target.X1=x-12;target.X2=x+12;target.Y1=y-20;target.Y2=y+20;}
      private function spawn(x:Number,y:Number,dx:Number,dy:Number):*
      {
         var B:Class=MSWU.cls("fe.weapon.Bullet");var b:*=new B(w.gg,x,y,null,true);
         b.weap=weapon;b.damage=100;b.tipDamage=0;b.precision=10;b.miss=1;b.dx=dx;b.dy=dy;b.vel=Math.sqrt(dx*dx+dy*dy);return b;
      }
      private function screenshot():void
      {
         rows=[];collect(w.main);for each(var r:* in rows)if(r.settingsSc!=null && "drawNow" in r.settingsSc)r.settingsSc.drawNow();
         var st:*=w.main.stage;var b:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0);b.draw(st);
         var enc:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class;var bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream");var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath("settings.png"),"write");f.writeBytes(bytes);f.close();b.dispose();
      }
      private function write(name:String,s:String):void {var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream");var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath(name),"write");f.writeUTFBytes(s);f.close();}
      private function finish(s:String,code:int):void {write("results.txt",log+s+"\n");timer.stop();MSWU.cls("flash.desktop.NativeApplication")["nativeApplication"].exit(code);}
   }
}
