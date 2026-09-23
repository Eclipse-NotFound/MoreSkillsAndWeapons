package
{
   import flash.utils.getTimer;
   public class MSWPointer
   {
      public static const ID:String="mswlaserpointer";
      public static const NAME:String="激光笔";
      public static const GIFT:String="msw_pointer_granted_v1";
      public static const CHARGE:String="msw_pointer_charge_v1";
      public static const VERSION:String="1-continuous";
      private var mod:*;
      private var loc:*,player:*,weaponClass:Class;
      private var beam:MSWPointerBeam=new MSWPointerBeam();
      private var hud:MSWLaserHUD=new MSWLaserHUD();
      private var sweep:MSWPointerSweep=new MSWPointerSweep();
      private var stepped:Boolean=false;
      private var lastTime:int=0;
      private var lastDebug:int=0;
      public var lit:Boolean=false;
      public function MSWPointer(m:*) {mod=m;hud.name="MSWPointerHUD";}
      public function injectXml():void
      {
         mod.cfg.diagSet("pointerRuntimeVersion",VERSION);mod.cfg.diagSet("pointerError",null);
         var c:Class=MSWU.cls("fe.AllData");if(c==null)return;
         var d:XML=c["d"];if(d.weapon.(@id==ID).length())return;
         var node:XML=d.weapon.(@id=="lasp")[0].copy();node.@id=ID;
         delete node.char;delete node.ammo;delete node.dop;delete node.com;
         node.appendChild(<char maxhp="1000000" damage="0" rapid="24" prec="0" tipdam="5" destroy="0" kol="0" auto="0"/>);
         node.appendChild(<ammo holder="0" rashod="0" reload="0"/>);
         node.phis.@deviation=0;node.phis.@recoil=0;node.vis.@vweap="vislasp";node.vis.@tipdec=0;
         node.sats.@cons=0;node.sats.@noperc=1;node.n=NAME;d.appendChild(node);
      }
      public function provision(w:*):void
      {
         if(!mod.cfg.pointerEnabled || w.game==null || w.invent==null || w.gg==null || w.loc==null || !w.loc.active)return;
         if(w.game.triggers[GIFT]==1)return;
         var wp:*=w.invent.weapons[ID];
         if(wp==null)wp=w.invent.addWeapon(ID);
         if(wp==null)return;
         wp=ensureWeapon(w);configure(wp);w.game.triggers[GIFT]=1;mod.cfg.diagAdd("pointerGifts");
      }
      private function ensureWeapon(w:*):*
      {
         var old:*=w.invent.weapons[ID];if(old==null)return null;
         if(weaponClass==null)weaponClass=MSWU.cls("fe.weapon.MSWPointerWeapon");
         if(weaponClass==null)throw new Error("Pointer weapon class missing from build");
         if(old is weaponClass)return old;
         var wp:*=new weaponClass(old);w.invent.weapons[ID]=wp;
         if(w.gg.currentWeapon===old)w.gg.currentWeapon=wp;
         if(w.gg.newWeapon===old)w.gg.newWeapon=wp;
         for(var key:String in w.gg.childObjs)if(w.gg.childObjs[key]===old)w.gg.childObjs[key]=wp;
         if(w.gg.sats.weapon===old)w.gg.sats.weapon=wp;
         wp.onPress=function(fired:*):void
         {
            try
            {
               var current:*=MSWU.world();
               if(current==null || fired!==current.gg.currentWeapon || !current.ctr.keyAttack)return;
               // Consume the actual native press even if autoAttack also calls attack.
               current.ctr.keyAttack=false;stepped=true;
               if(interrupted(current) || paused(current))return;
               if(lit) {consume(current,elapsed());stop();}
               else if(activateCharge(current))
               {lit=true;lastTime=getTimer();sweep.reset();illuminate(current,fired);mod.cfg.diagAdd("pointerOns");}
            }
            catch(e:*) {fail("press",e);}
         };
         wp.onStep=function(current:*):void
         {if(current.owner===player && current===player.currentWeapon)stepped=true;};
         return wp;
      }
      public function configure(wp:*):void
      {
         wp.nazv=NAME;wp.kol=0;wp.auto=false;wp.holder=wp.hold=wp.rashod=wp.reload=0;
         wp.damage=wp.damageExpl=wp.explRadius=wp.destroy=wp.otbros=0;
         wp.deviation=wp.recoil=wp.precision=wp.drot=0;wp.noPerc=wp.noTrass=wp.noSats=true;
         wp.t_attack=wp.t_reload=wp.t_prep=0;wp.is_shoot=false;wp.hp=wp.maxhp;
      }
      public function prepare(w:*):void
      {
         stepped=false;
         if(w==null || w.gg==null || w.loc==null || w.invent==null || w.invent.weapons==null)return;
         if(w.loc!==loc || w.gg!==player) {stop();loc=w.loc;player=w.gg;}
         var wp:*=ensureWeapon(w);if(wp!=null)configure(wp);
      }
      private function interrupted(w:*):Boolean
      {
         if(!mod.cfg.pointerEnabled || w.gg==null || w.loc==null || !w.loc.active || w.gg.hp<=0 || w.gg.sost>=3)return true;
         if(w.gg.currentWeapon==null || w.gg.currentWeapon.id!=ID || !w.gg.ggControl)return true;
         if(w.onPause && w.godMode)return true;
         if(w.gg.work!="" || w.gg.t_work>0 || w.catPause || w.t_exit>0)return true;
         return w.pip.active || w.sats.active || w.sats.que.length>0 || w.onConsol ||
            (w.stand!=null && w.stand.active) || mod.panel.overlayOpen;
      }
      private function paused(w:*):Boolean
      {return w.allStat!=1 || w.mm.active || w.gui.guiPause || w.verror.visible || (w.onPause && !stepped);}
      private function elapsed():Number
      {var now:int=getTimer(),dt:Number=lastTime==0?0:Math.max(0,(now-lastTime)/1000);lastTime=now;return dt;}
      public function charge(w:*):Number
      {
         var n:Number=Number(w.game.triggers[CHARGE]);
         return isFinite(n)?Math.max(0,Math.min(1,n)):0;
      }
      private function activateCharge(w:*):Boolean
      {
         if(charge(w)>1e-9)return true;
         var item:*=w.invent.items["batt"];
         if(item==null || item.kol<1)return false;
         item.kol--;w.invent.mass[2]-=item.mass;w.calcMass=true;
         w.game.triggers[CHARGE]=1;mod.cfg.diagAdd("pointerBatteries");return true;
      }
      /** Pay only for elapsed illuminated time, keeping fractional paid energy. */
      public function consume(w:*,seconds:Number):Boolean
      {
         var needed:Number=Math.max(0,seconds)*mod.cfg.pointerRate;
         while(needed>1e-9)
         {
            if(!activateCharge(w))return false;
            var available:Number=charge(w),used:Number=Math.min(available,needed);
            w.game.triggers[CHARGE]=Math.max(0,available-used);needed-=used;
         }
         return charge(w)>1e-9 || (w.invent.items["batt"]!=null && w.invent.items["batt"].kol>=1);
      }
      public function stop():void
      {lit=false;sweep.reset();beam.dispose();lastTime=getTimer();}
      private function illuminate(w:*,wp:*):void
      {
         wp.getBulXY();
         var a:Number=Math.atan2(w.gg.celY-wp.bulY,w.gg.celX-wp.bulX);
         var hit:Object=sweep.scan(w,wp.bulX,wp.bulY,a,mod.cfg.pointerEye,function(sample:Object):void
         {
            if(sample.eye && MSWLaserGeometry.hostile(sample.unit,w))mod.laser.blind.apply(sample.unit,w,mod.cfg.pointerDuration,"pointer");
         });
         beam.draw(w,wp.bulX,wp.bulY,hit);
         var result:String=hit.eye && mod.laser.blind.remaining(hit.unit)>0?"blind":(hit.eye?"ineligible":hit.reason);
         mod.cfg.diagSet("pointerLastHit",result);
         if(mod.cfg.pointerDebug && getTimer()-lastDebug>=150)
         {hud.report(hit,result,mod.laser.blind.remaining(hit.unit),mod.cfg.pointerEye);lastDebug=getTimer();}
      }
      public function frame(w:*):void
      {
         try
         {
            var dt:Number=elapsed();
            if(w.gg!==player || w.loc!==loc) {stop();player=w.gg;loc=w.loc;}
            if(w.gg==null || w.loc==null || w.invent==null || w.game==null) {stop();hud.visible=false;return;}
            provision(w);
            var wp:*=ensureWeapon(w);if(wp!=null)configure(wp);
            if(!mod.cfg.pointerEnabled)mod.laser.blind.clearSource("pointer");
            var equipped:Boolean=w.gg.currentWeapon!=null && w.gg.currentWeapon.id==ID;
            if(interrupted(w))stop();
            else if(paused(w))sweep.reset();
            else if(lit)
            {
               if(!consume(w,dt))stop();
               else illuminate(w,wp);
            }
            hud.render(w,equipped && !w.pip.active && !mod.panel.overlayOpen,null,mod.laser.blind.states,mod.cfg.pointerDebug);
            if(equipped && w.gui!=null)
               w.gui.vis.textWeapon.getChildByName("holder").text=(lit?"亮 ":"灭 ")+int(w.invent.items["batt"].kol)+" · 余"+Math.ceil(charge(w)*100)+"%";
            mod.cfg.diagSet("pointerLit",lit);mod.cfg.diagSet("pointerCharge",charge(w));
         }
         catch(e:*) {fail("frame",e);}
      }
      private function fail(where:String,e:*):void
      {stop();mod.cfg.diagSet("pointerError",where+":"+e+(e is Error?"\n"+e.getStackTrace():""));if(mod.cfg.pointerDebug)hud.error(String(e));}
   }
}
