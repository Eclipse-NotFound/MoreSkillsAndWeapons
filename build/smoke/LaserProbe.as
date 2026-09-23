package
{
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.display.BitmapData;
   import flash.utils.getQualifiedClassName;
   import flash.utils.ByteArray;
   import flash.utils.Timer;


   public class LaserProbe
   {
      private var timer:Timer=new Timer(50), ticks:int=0;
      private var log:String="",phase:int=0,since:int=0;
      private var m:*,w:*,wp:*,target:*,access:Class;
      private var slow:Boolean=false,previous:Number=0,frozen:int=0,advanced:int=0;
      private var slowShots:Number=0;
      public function LaserProbe() {timer.addEventListener("timer",tick);timer.start();}
      private function ok(v:Boolean,msg:String):void {if(!v)throw new Error(msg);log+="PASS "+msg+"\n";}
      private function tick(e:Event):void
      {
         try {
            ticks++;m=MoreSkillsWeaponsMod.testInstance();w=MSWU.world();
            if(ticks%100==0)write("heartbeat.txt","ticks="+ticks+" phase="+phase+" mod="+(m!=null)+" world="+(w!=null)+" gg="+(w!=null && w.gg!=null)+" error="+(m!=null?m.cfg.diag.lastErr:"")+"\n"+log);
            if(m!=null && m.cfg.diag.lastErr!=null)throw new Error(m.cfg.diag.lastErr);
            if(w!=null && w.verror!=null && w.verror.visible)throw new Error("startup dialog: "+w.verror.txt.text);
            if(ticks>1200)throw new Error("timeout");
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active || ticks<180 || m.cfg.diag.auto!="pip-opt-open")return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(phase==2)
            {
               if(ticks-since==6)
               {var SC:Class=MSWU.cls("fe.inter.SatsCel");w.gg.sats.que.push(new SC({u:target,n:0},0,0,17));}
               var remaining:Number=m.laser.blind.remaining(target);
               if(remaining==previous)frozen++;else if(remaining<previous)advanced++;
               previous=remaining;
               if(ticks-since<45)return;
               ok(m.cfg.diag.laserShots==slowShots+1,"laser fires exactly once inside controllable time stop (before="+slowShots+", after="+m.cfg.diag.laserShots+", hold="+wp.hold+", count="+wp.kol_shoot+", queue="+w.gg.sats.que.length+", pip="+w.pip.active+")");
               ok(frozen>0 && advanced>0 && remaining>5 && remaining<6,"real Sandevistan freezes display frames and advances only slow world steps");
               key();ok(w.onPause && w.godMode,"actual Sandevistan replay starts");phase=3;since=ticks;return;
            }
            if(phase==3)
            {
               if(w.onPause)return;
               ok(!w.godMode && m.cfg.diag.laserError==null,"Sandevistan replay completes without laser errors");
               ok(m.laser.blind.remaining(target)>0 && target.celUnit==null,"blind state survives replay and resumes normally");
               ok(m.cfg.diag.laserShots==slowShots+2,"recorded laser shot is reproduced exactly once during replay");
               finish(true);return;
            }
            if(phase==1)
            {
               if(ticks-since<24)return;
               // Wait for actual world progress under load, not a fixed number
               // of wall-clock Timer ticks. Still fail if the actor never steps.
               if(ticks-since<200 && target.hp>0 && m.laser.blind.remaining(target)>=5.5)return;
               w.onPause=true;
               ok(m.laser.blind.remaining(target)>0 && m.laser.blind.remaining(target)<5.5 && target.hp>0,"blind timer advances through actual Location.step (remaining="+m.laser.blind.remaining(target)+", hp="+target.hp+", pause="+w.onPause+", pip="+w.pip.active+")");
               ok(target.celUnit==null,"live scene does not reacquire moving player while blind");
               ok(m.cfg.diag.laserError==null,"live actor update has no laser errors");
               m.cfg.laserEnabled=false;m.laser.frame(w);
               ok(m.laser.blind.remaining(target)==0 && target.vision>0,"disable restores vision and removes control state");
               if(slow)
               {
                  m.cfg.laserEnabled=true;m.laser.frame(w);m.laser.blind.apply(target,w);
                  target.fixed=true;w.onPause=false;w.godMode=false;key();
                  ok(w.onPause && !w.godMode,"actual Sandevistan hotkey enters time stop");
                  position(w.gg,240,320);target.storona=-1;position(target,500,320);target.stun=100;
                  wp.hold=12;wp.t_attack=wp.t_auto=wp.t_reload=0;wp.is_shoot=false;wp.ready=true;
                  slowShots=m.cfg.diag.laserShots;
                  previous=6;phase=2;since=ticks;return;
               }
               finish(true);return;
            }
            if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            if(m.settings.api!=null)for each(var page:Object in m.settings.api.getPages())if(page.modId=="sandevistan")slow=true;
            var U:Class=MSWU.cls("fe.unit.Unit"),u:*=new U();
            u.loc=w.loc;u.storona=1;u.celUnit=w.gg;
            access=MSWU.cls("fe.unit.MSWBlindAccess");var sats:Class=MSWU.cls("fe.inter.MSWLaserSats"); access["clearTarget"](u);
            ok(u.celUnit==null && access["state"](u)==2,"same-package internal Unit access against original host");
            var C:Class=MSWU.cls("fe.inter.SatsCel"),rec:Object={u:u,n:0};
            var c:*=new C(rec,0,0,17);
            ok(sats["target"](c)===u,"SATS exact target identity without coordinate guessing");c.remove();
            c=new C(null,40,50,17);ok(sats["target"](c)==null,"SATS point queue remains a point");c.remove();
            runRules();
            phase=1;since=ticks;w.onPause=false;
         }catch(err:*) {log+="FAIL "+err+"\n"+err.getStackTrace()+"\n";finish(false);}
      }
      private function actor(id:String,x:Number=500):*
      {
         var u:*=w.loc.createUnit(id,x,320,true);
         ok(u!=null,"native actor created: "+id);
         u.fraction=2;u.hp=u.maxhp;u.sost=1;u.disabled=u.trigDis=u.npc=u.noAgro=false;
         u.storona=-1;u.shithp=0;u.stun=u.t_emerg=0;position(u,x,320);u.isVis=true;return u;
      }
      private function position(u:*,x:Number,y:Number):void
      {u.setPos(x,y);u.X1=x-u.scX/2;u.X2=x+u.scX/2;u.Y1=y-u.scY;u.Y2=y;u.eyeX=x+u.scX*.25*u.storona;u.eyeY=y-u.scY*.75;u.setVisPos();}
      private function stepBlind(u:*,count:int):void
      {for(var i:int=0;i<count;i++){var s:Object=m.laser.blind.states[u];if(s==null)break;s.node.step();if(m.cfg.diag.laserError!=null)throw new Error(m.cfg.diag.laserError);}}
      private function runRules():void
      {
         for(var x:int=100;x<1300;x+=20)for(var y:int=80;y<420;y+=20){var t:*=w.loc.getAbsTile(x,y);t.phis=0;t.water=0;}
         wp=w.invent.weapons[MSWLaser.ID];ok(wp!=null && wp.ammo=="batt","gift uses original batt ammunition");
         var gift:Number=m.cfg.diag.laserGifts;m.laser.provision(w);m.laser.provision(w);
         ok(m.cfg.diag.laserGifts==gift,"gift is idempotent within save");
         var saved:Object=w.game.save();ok(saved.triggers[MSWLaser.GIFT]==1,"gift marker is serialized by original save");
         var bytes:ByteArray=new ByteArray();bytes.writeObject(saved);bytes.position=0;
         ok(bytes.readObject().triggers[MSWLaser.GIFT]==1,"per-save gift marker survives AMF serialization and reload");
         delete w.invent.weapons[MSWLaser.ID];m.laser.provision(w);
         ok(w.invent.weapons[MSWLaser.ID]==null,"lost or sold gun is not re-gifted");w.invent.weapons[MSWLaser.ID]=wp;
         var W:Class=MSWU.cls("fe.weapon.Weapon"),loaded:*=W["create"](w.gg,MSWLaser.ID);loaded.hold=7;
         w.invent.weapons[MSWLaser.ID]=loaded;w.gg.currentWeapon=loaded;w.gg.childObjs[0]=loaded;w.gg.sats.weapon=loaded;m.laser.frame(w);wp=w.invent.weapons[MSWLaser.ID];
         ok(getQualifiedClassName(wp)=="fe.weapon::MSWDazzlerWeapon" && wp.hold==7 && w.gg.currentWeapon===wp && w.gg.childObjs[0]===wp && w.gg.sats.weapon===wp && m.cfg.diag.laserGifts==gift,"native restored weapon rebinds without losing ammo or granting another gun");
         ok(wp.kol==0 && wp.damage==0 && !wp.auto && wp.holder==12 && wp.rashod==2 && wp.rapid==24 && wp.reload==60,"native gun configured for 6 shots, zero damage, semi-auto");
         w.gg.currentWeapon=wp;position(w.gg,240,320);w.gg.dx=w.gg.dy=0;
         target=actor("raider");w.loc.units=[w.gg,target];w.loc.objs=[];
         wp.bulX=300;wp.bulY=MSWLaserGeometry.eye(target).y;
         w.celX=w.gg.celX=MSWLaserGeometry.eye(target).x;w.celY=w.gg.celY=MSWLaserGeometry.eye(target).y;
         var hp:Number=target.hp,hit:Object=m.laser.fire(w,wp);
         ok(hit.unit===target && hit.eye && target.hp==hp && m.laser.blind.remaining(target)==6,"front eye hit blinds with exactly zero HP damage");
         stepBlind(target,30);ok(Math.abs(m.laser.blind.remaining(target)-5)<0.001,"30 enemy action steps consume one second");
         m.laser.blind.apply(target,w);ok(m.laser.blind.remaining(target)==6,"repeat hit refreshes without stacking");
         for(var j:int=0;j<6;j++)m.laser.frame(w);
         ok(m.laser.blind.remaining(target)==6,"display frames during time stop consume no enemy time");
         m.laser.blind.clear();position(target,500,320);
         var eyeY:Number=MSWLaserGeometry.eye(target).y;
         hit=MSWLaserGeometry.castRay(w,300,target.Y-5,0,6,1000,w.gg);
         ok(hit.unit===target && !hit.eye,"body hit stops beam without blindness");
         target.storona=1;position(target,500,320);
         hit=MSWLaserGeometry.castRay(w,300,MSWLaserGeometry.eye(target).y,0,6,1000,w.gg);ok(!hit.eye,"rear eye-coordinate hit does not blind");
         target.storona=-1;position(target,500,320);target.shithp=50;
         hit=MSWLaserGeometry.castRay(w,300,MSWLaserGeometry.eye(target).y,0,6,1000,w.gg);ok(!hit.eye,"active shield blocks eye effect");target.shithp=0;
         target.armor=9999;target.dexter=9999;hit=MSWLaserGeometry.castRay(w,300,MSWLaserGeometry.eye(target).y,0,6,1000,w.gg);
         ok(hit.eye,"armor and hidden hit chance do not negate geometry");
         t=w.loc.getAbsTile(400,MSWLaserGeometry.eye(target).y);var orig:Object={phis:t.phis,x1:t.phX1,x2:t.phX2,y1:t.phY1,y2:t.phY2};
         t.phis=1;t.phX1=390;t.phX2=430;t.phY1=160;t.phY2=350;
         hit=MSWLaserGeometry.castRay(w,300,MSWLaserGeometry.eye(target).y,0,6,1000,w.gg);ok(hit.unit==null && hit.x<=390,"terrain stops beam before enemy");
         t.phis=orig.phis;t.phX1=orig.x1;t.phX2=orig.x2;t.phY1=orig.y1;t.phY2=orig.y2;
         var blocker:*=actor("raider",420);position(blocker,420,320);w.loc.units=[w.gg,blocker,target];
         hit=MSWLaserGeometry.castRay(w,300,MSWLaserGeometry.eye(target).y,0,6,1000,w.gg);ok(hit.unit===blocker,"first enemy prevents penetration into second");
         blocker.exterminate();w.loc.units=[w.gg,target];
         wp.bulX=300;wp.bulY=MSWLaserGeometry.eye(target).y;w.celX=w.gg.celX=MSWLaserGeometry.eye(target).x;w.celY=w.gg.celY=MSWLaserGeometry.eye(target).y+10;
         ok(MSWLaserGeometry.assist(w,wp,m.cfg)===target,"standing body assistance acquires nearby visible eye");
         target.invis=true;ok(MSWLaserGeometry.assist(w,wp,m.cfg)==null,"cloaked target receives no automatic eye assistance");target.invis=false;
         w.gg.dx=10;ok(MSWLaserGeometry.assist(w,wp,m.cfg)===target,"running retains automatic correction near body");w.gg.dx=0;w.gg.dy=10;
         ok(MSWLaserGeometry.assist(w,wp,m.cfg)===target,"vertical speed retains minimum correction");
         m.cfg.laserAssist=false;w.celY=w.gg.celY=MSWLaserGeometry.eye(target).y;hit=m.laser.fire(w,wp);ok(hit.eye,"manual precision still works with assistance off at high speed");w.gg.dy=0;m.laser.blind.clear();m.cfg.laserAssist=true;
         // Force the native firing path, not merely a custom effect invocation.
         wp.hold=12;wp.t_attack=wp.rapid;wp.t_reload=0;wp.t_prep=20;wp.loc=w.loc;wp.X=300;wp.Y=MSWLaserGeometry.eye(target).y;
         var shots:Number=m.cfg.diag.laserShots;wp.step();m.laser.frame(w);
         ok(wp.hold==10 && m.cfg.diag.laserShots==shots+1,"original Weapon shoot spends two batteries and invokes one beam");
         m.laser.frame(w);ok(m.cfg.diag.laserShots==shots+1,"display callbacks do not double-fire");
         for(j=0;j<40;j++){wp.step();m.laser.frame(w);}ok(m.cfg.diag.laserShots==shots+1,"native shot-counter reset cannot create a phantom beam");
         gunCycle();
         m.laser.blind.clear();
         var C:Class=MSWU.cls("fe.inter.SatsCel"),q:*=new C({u:target,n:0},0,0,17);
         w.gg.sats.que.push(q);wp.bulX=300;wp.bulY=target.Y;w.gg.celX=target.X;w.gg.celY=target.Y-target.scY/2;
         hit=m.laser.fire(w,wp);ok(hit.eye && hit.unit===target,"SATS targets exact selected eye beyond ordinary correction angle");
         w.gg.sats.que.pop();q.remove();m.laser.blind.clear();
         satsCycle();target.exterminate();
         for each(var id:String in ["raider","slaver","zebra","ranger","merc","encl","alicorn","protect","gutsy","robot","eqd","sentinel","roller","spritebot","vortex","dron","msp","thunderhead","turret","landturret","wturret","bossturret","zombie","hellhound","rat","ant","bloat","bloodwing","fish","necros","bossraider","bossnecr","bossalicorn","megadron","bossencl","ultra"])
         {
            var enemy:*=actor(id);w.loc.units=[w.gg,enemy];
            ok(m.laser.blind.apply(enemy,w),"blind accepted: "+id);
            var frac:int=enemy.fraction,vision:Number=m.laser.blind.states[enemy].vision;
            stepBlind(enemy,20);
            ok(enemy.celUnit==null && enemy.fraction==frac && m.laser.blind.remaining(enemy)>5,"panic steps without player target/faction change: "+id);
            if(enemy.currentWeapon!=null)
            {
               var panicKey:String=enemy.currentWeapon.tip==1?"laserPanicSwings":"laserPanicShots";
               var panics:Number=m.cfg.diag[panicKey]||0;
               var es:Object=m.laser.blind.states[enemy];enemy.currentWeapon.t_attack=enemy.currentWeapon.t_auto=0;enemy.currentWeapon.t_reload=0;
               enemy.currentWeapon.hold=enemy.currentWeapon.holder;
               es.next=999;es.burst=120;es.angle=0;enemy.stun=0;
               stepBlind(enemy,Math.max(20,enemy.currentWeapon.prep+8));
               ok(m.cfg.diag[panicKey]>panics,"native weapon actually attacks during panic: "+id+" / "+enemy.currentWeapon.id);
            }
            m.laser.blind.clear();ok(enemy.vision==vision && enemy.celUnit==null,"control/vision restored: "+id);enemy.exterminate();
         }
         panicDamage();
         cleanupRules();
         var object:*=w.loc.firstObj;while(object!=null){var following:*=object.nobj;if(MSWU.has(object,"owner") || getQualifiedClassName(object)=="fe.graph::Part")w.loc.remObj(object);object=following;}
         target=actor("raider");w.loc.units=[w.gg,target];m.laser.blind.apply(target,w);
         if(target.currentWeapon!=null)target.currentWeapon.damage=0;
         ok(MSWSettingsHub.buildLaserItems(m).length==15,"fifteen laser settings provided");
         m.cfg.laserDuration=8;m.cfg.save();var cfg:MSWConfig=new MSWConfig();cfg.load();ok(cfg.laserDuration==8,"laser settings persist");m.cfg.laserDuration=6;
         ui();
         ok(m.cfg.diag.laserError==null,"all paused rule checks have no runtime errors");
      }
      private function cleanupRules():void
      {
         var u:*=actor("raider");w.loc.units=[w.gg,u];
         u.controlOn=false;ok(!m.laser.blind.apply(u,w) && !u.controlOn,"script-disabled actor is never awakened");u.controlOn=true;
         m.laser.blind.apply(u,w);var saved:Object=u.save();
         ok(saved.vision==null && saved.remaining==null,"native enemy save excludes temporary blind data");
         u.sost=2;m.laser.blind.prune(w);ok(m.laser.blind.remaining(u)==0 && u.vision>0,"dying actor returns immediately to its original death logic");
         u.sost=1;m.laser.blind.apply(u,w);u.trigDis=true;m.laser.blind.prune(w);
         ok(m.laser.blind.remaining(u)==0 && u.trigDis,"external scripted disable remains intact during cleanup");u.trigDis=false;
         m.laser.blind.apply(u,w);m.laser.frame({loc:null,gg:w.gg});
         ok(m.laser.blind.remaining(u)==0 && u.vision>0,"scene identity change restores and discards old actors");
         m.laser.frame(w);u.exterminate();
         u=actor("turret");u.hack(0);ok(!m.laser.blind.apply(u,w) && access["scriptStopped"](u),"hacked sleeping turret is never awakened by blindness");u.exterminate();
      }
      private function key():void
      {w.main.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,220));w.main.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,220));}
      private function satsCycle():void
      {
         w.gg.childObjs[0]=wp;wp.setPers(w.gg,w.gg.pers);wp.addVisual();w.gg.setWeaponPos();
         m.laser.configure(wp);wp.hold=12;wp.t_auto=wp.t_attack=wp.t_reload=0;wp.is_shoot=false;wp.ready=true;
         w.gg.controlOn();w.gg.sats.weapon=wp;w.gg.sats.od=80;
         var C:Class=MSWU.cls("fe.inter.SatsCel");w.gg.sats.que.push(new C({u:target,n:0},0,0,17));
         for(var i:int=0;i<100 && w.gg.sats.que.length>0;i++) {w.gg.step();m.laser.frame(w);}
         ok(w.gg.sats.que.length==0 && w.gg.sats.od>=63 && w.gg.sats.od<64,"original SATS queue shoots and charges seventeen AP");
         ok(m.laser.blind.remaining(target)>0 && wp.hold==10,"executed SATS shot blinds the selected eye and spends ammo");m.laser.blind.clear();
      }
      private function gunCycle():void
      {
         var recycle:Number=w.gg.pers.recyc;w.gg.pers.recyc=1;
         wp.hold=12;wp.t_attack=wp.t_auto=wp.t_reload=0;wp.ready=true;wp.lvl=0;wp.perslvl=0;
         var n:Number=m.cfg.diag.laserShots;
         for(var i:int=0;i<100;i++){wp.attack();wp.step();m.laser.frame(w);}
         ok(m.cfg.diag.laserShots==n+1 && wp.hold==10,"holding fire produces only one semi-auto shot");
         for(var shot:int=1;shot<6;shot++)
         {
            for(i=0;i<30;i++){wp.step();m.laser.frame(w);}
            wp.attack();wp.step();m.laser.frame(w);
         }
         ok(wp.hold==0 && m.cfg.diag.laserShots==n+6,"six clicks consume exactly a full magazine");
         w.gg.pers.recyc=recycle;
         w.invent.items.batt.kol=50;wp.t_attack=0;wp.initReload();
         ok(wp.t_reload==60,"native reload starts with two seconds");
         for(i=0;i<60;i++){wp.step();m.laser.frame(w);}
         ok(wp.t_reload==0 && wp.hold==12 && w.invent.items.batt.kol==38,"native reload refills twelve batteries after sixty steps");
         m.cfg.laserMagazine=3;m.laser.configure(wp);
         ok(wp.hold==6 && w.invent.items.batt.kol==44,"smaller magazine refunds overflow batteries");
         m.cfg.laserMagazine=6;m.laser.configure(wp);
         n=m.cfg.diag.laserShots;
         m.cfg.laserEnabled=false;m.laser.configure(wp);wp.step();
         for(i=0;i<10;i++)wp.step();
         m.cfg.laserEnabled=true;m.laser.configure(wp);wp.step();m.laser.frame(w);
         ok(m.cfg.diag.laserShots==n,"disable and re-enable cannot schedule a phantom shot");
         wp.t_attack=20;m.cfg.laserInterval=0.2;m.laser.configure(wp);
         for(i=0;i<25;i++){wp.step();m.laser.frame(w);}
         ok(m.cfg.diag.laserShots==n,"changing fire interval during cooldown cannot repeat the previous shot");
         m.cfg.laserInterval=0.8;m.laser.configure(wp);
      }
      private function panicDamage():void
      {
         var owner:*=actor("raider",400),victim:*=actor("raider",550);
         victim.armor=victim.dexter=victim.dodge=victim.neujaz=0;victim.hp=victim.maxhp=10000;
         w.loc.units=[w.gg,owner,victim];owner.fixed=true;owner.storona=1;
         var B:Class=MSWU.cls("fe.weapon.Bullet");
         var old:*=new B(owner,480,290,null,true);old.dx=100;old.vel=100;old.damage=40;old.precision=0;
         var W:Class=MSWU.cls("fe.weapon.Weapon"),gun:*=W["create"](owner,"p9mm");
         owner.currentWeapon=gun;owner.childObjs=[gun];gun.loc=w.loc;gun.ready=true;gun.hold=999;gun.precision=0;gun.deviation=0;
         gun.X=400;gun.Y=290;gun.t_attack=gun.rapid;gun.t_prep=20;
         m.laser.blind.apply(owner,w);
         var state:Object=m.laser.blind.states[owner];state.next=999;state.angle=0;state.burst=0;
         stepBlind(owner,1);
         var born:*=null,obj:*=w.loc.firstObj;
         while(obj!=null) {if(MSWU.has(obj,"owner") && obj.owner===owner && obj!==old && MSWU.has(obj,"targetObj"))born=obj;obj=obj.nobj;}
         ok(born!=null && born.pobj is MSWLaserStep,"native panic weapon births receive a shot guard");
         ok(!(old.pobj is MSWLaserStep),"pre-blind in-flight shot is not retroactively changed");
         var hp:Number=victim.hp;old.step();ok(victim.hp==hp,"pre-blind shot retains original allied immunity");
         state.sources.laser=0;stepBlind(owner,1);ok(m.laser.blind.remaining(owner)==0,"panic expires before its projectile lands");
         born.X=500;born.Y=290;born.dx=60;born.dy=0;born.vel=60;born.damage=40;born.precision=0;born.miss=0;born.probiv=0;born.pier=10000;
         var frac:int=owner.fraction;born.pobj.step();
         ok(victim.hp<hp && owner.fraction==frac,"panic projectile damages same-faction actor after recovery without faction mutation");
         // A native projectile emitted inside a blinded actor's child step.
         var neutralShot:*=null;owner.childObjs=[{step:function():void {neutralShot=new B(owner,500,290,null,true);neutralShot.dx=60;neutralShot.vel=60;neutralShot.damage=40;neutralShot.precision=0;neutralShot.pier=10000;}}];
         victim.fraction=0;victim.neujaz=0;hp=victim.hp;
         m.laser.blind.apply(owner,w);state=m.laser.blind.states[owner];state.next=999;state.angle=0;state.burst=0;stepBlind(owner,1);neutralShot.pobj.step();
         ok(victim.hp<hp,"panic projectile can damage a neutral actor");
         victim.fraction=owner.fraction;victim.friendlyExpl=0;victim.neujaz=0;hp=victim.hp;
         var bomb:*=null;owner.childObjs=[{step:function():void {bomb=new B(owner,530,290,null,true);bomb.weap=gun;bomb.liv=1;bomb.explRadius=100;bomb.damageExpl=100;bomb.pier=10000;bomb.tipDamage=4;}}];
         stepBlind(owner,1);bomb.pobj.step();
         var blast:*=null;obj=w.loc.firstObj;while(obj!=null){if(MSWU.has(obj,"targetObj") && obj.targetObj===victim)blast=obj;obj=obj.nobj;}
         ok(blast!=null && blast.damage>0 && victim.friendlyExpl==0,"panic explosion lifts only its own allied immunity and restores victim flags");
         for(var bi:int=0;bi<3 && blast.in_chain;bi++)blast.pobj.step();
         ok(victim.hp<hp,"native panic explosion actually damages its immune ally");
         m.laser.blind.clear();owner.childObjs=[];owner.exterminate();victim.exterminate();
         owner=actor("zombie",450);victim=actor("raider",490);victim.armor=victim.dexter=victim.dodge=victim.neujaz=0;hp=victim.hp;
         w.loc.units=[w.gg,owner,victim];m.laser.blind.apply(owner,w);state=m.laser.blind.states[owner];state.next=999;state.angle=0;state.burst=1;
         stepBlind(owner,1);ok(victim.hp<hp,"blinded melee actor can hurt its own faction");
         m.laser.blind.clear();owner.exterminate();victim.exterminate();
         owner=actor("raider",400);victim=actor("raider",450);victim.armor=victim.dexter=victim.dodge=victim.neujaz=0;victim.hp=victim.maxhp=10000;
         gun=W["create"](owner,"zknife");owner.currentWeapon=gun;owner.childObjs=[gun];gun.loc=w.loc;
         w.loc.units=[w.gg,owner,victim];m.laser.blind.apply(owner,w);state=m.laser.blind.states[owner];state.next=999;state.angle=0;state.burst=3;
         stepBlind(owner,1);var blade:*=gun.b;hp=victim.hp;
         blade.X=victim.X;blade.Y=victim.Y-victim.scY/2;blade.dx=blade.dy=0;blade.damage=40;blade.precision=0;blade.miss=0;blade.pier=10000;blade.checkLine=false;blade.probiv=1;blade.parr=null;
         state.sources.laser=0;stepBlind(owner,1);blade.run();
         ok(victim.hp<hp,"panic blade retains allied contact after blindness expires");
         victim.neujaz=0;hp=victim.hp;blade.parr=null;gun.t_attack+=100;blade.run();
         ok(victim.hp==hp,"later ordinary blade swing restores allied immunity");
         m.laser.blind.clear();owner.exterminate();victim.exterminate();
      }
      private function ui():void
      {
         w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.visual.x=0;w.visual.y=0;
         position(w.gg,240,320);position(target,500,320);target.isVis=true;
         w.celX=w.gg.celX=MSWLaserGeometry.eye(target).x;w.celY=w.gg.celY=MSWLaserGeometry.eye(target).y;w.gg.dx=w.gg.dy=0;
         wp.bulX=300;wp.bulY=MSWLaserGeometry.eye(target).y;m.laser.fire(w,wp);m.laser.frame(w);
         screenshot("laser-hud.png");
         m.panel.toggleOverlay();m.panel.handleKey(9);m.panel.handleKey(9);
         m.panel.handleKey(40);m.panel.handleKey(39);
         ok(m.cfg.laserDuration==6.5,"F6 laser page keyboard edits its setting");
         m.panel.update(w);screenshot("laser-settings.png");m.panel.handleKey(37);m.panel.toggleOverlay();m.panel.update(w);
         var found:Boolean=false;for each(var page:Object in m.settings.api.getPages())if(page.modId=="msw-laser")found=true;
         ok(found,"independent ModSettings registers the laser page");
      }
      private function screenshot(name:String):void
      {
         var st:*=w.main.stage,b:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0);b.draw(st);
         var enc:Class=MSWU.cls("flash.display.PNGEncoderOptions"),bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream"),fs:*=new S();
         fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();b.dispose();
      }
      private function finish(pass:Boolean):void {timer.stop();write("results.txt",log+(pass?"PASS laser game smoke":"FAIL laser game smoke")+"\n");var n:Class=MSWU.cls("flash.desktop.NativeApplication");n["nativeApplication"].exit(pass?0:1);}
      private function write(name:String,s:String):void {var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream"),f:*=F["applicationStorageDirectory"].resolvePath(name),fs:*=new S();fs.open(f,"write");fs.writeUTFBytes(s);fs.close();}
   }
}
