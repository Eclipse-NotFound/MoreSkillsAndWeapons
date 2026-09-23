package
{
   import flash.utils.Dictionary;
   public class MSWLaser
   {
      public static const ID:String="mswdazzler";
      public static const NAME:String="非致命激光枪";
      public static const GIFT:String="msw_dazzler_granted_v1";
      public static const VERSION:String="6-turret-sensors";
      private var mod:*;
      public var blind:MSWBlindController;
      private var hud:MSWLaserHUD=new MSWLaserHUD();
      private var loc:*,player:*;
      private var seen:Dictionary=new Dictionary(true);
      private var beams:Array=[];
      private var sats:Class;
      private var weaponClass:Class;
      public function MSWLaser(m:*) {mod=m;blind=new MSWBlindController(m);}
      public function injectXml():void
      {
         mod.cfg.diagSet("laserRuntimeVersion",VERSION);
         mod.cfg.diagSet("laserError",null);
         var c:Class=MSWU.cls("fe.AllData");if(c==null)return;
         var d:XML=c["d"];
         if(d.weapon.(@id==ID).length())return;
         var node:XML=d.weapon.(@id=="lasp")[0].copy();node.@id=ID;
         delete node.char;delete node.ammo;delete node.dop;delete node.com;
         node.appendChild(<char maxhp="1000000" damage="0" rapid="24" prec="0" tipdam="5" destroy="0" kol="0" auto="0"/>);
         node.appendChild(<ammo holder="12" rashod="2" reload="60"/>);
         node.phis.@deviation=0;node.phis.@recoil=0;
         node.vis.@vweap="vislasp";node.vis.@tipdec=0;
         node.sats.@cons=17;node.sats.@noperc=1;node.n=NAME;
         d.appendChild(node);
      }
      public function provision(w:*):void
      {
         if(!mod.cfg.laserEnabled || w.game==null || w.invent==null || w.loc==null || !w.loc.active || w.gg==null)return;
         if(w.game.triggers[GIFT]==1)return;
         var wp:*=w.invent.weapons[ID];
         if(wp==null) {wp=w.invent.addWeapon(ID);if(wp==null)return;wp.hold=0;}
         wp=ensureWeapon(w);configure(wp);w.game.triggers[GIFT]=1;mod.cfg.diagAdd("laserGifts");
      }
      private function ensureWeapon(w:*):*
      {
         var old:*=w.invent.weapons[ID];if(old==null)return null;
         if(weaponClass==null)weaponClass=MSWU.cls("fe.weapon.MSWDazzlerWeapon");
         if(weaponClass==null)throw new Error("Dazzler weapon class missing from build");
         if(old is weaponClass)return old;
         var wp:*=new weaponClass(old);w.invent.weapons[ID]=wp;
         if(w.gg.currentWeapon===old)w.gg.currentWeapon=wp;
         // Loading queues the saved gun before the equip animation finishes.
         // That pending reference must follow the inventory replacement too.
         if(w.gg.newWeapon===old)w.gg.newWeapon=wp;
         for(var key:String in w.gg.childObjs)if(w.gg.childObjs[key]===old)w.gg.childObjs[key]=wp;
         if(w.gg.sats.weapon===old)w.gg.sats.weapon=wp;
         wp.onShot=function(fired:*):void
         {
            var current:*=MSWU.world();
            try {if(current!=null && fired.owner===current.gg && mod.cfg.laserEnabled)fire(current,fired);}
            catch(e:*) {mod.cfg.diagSet("laserError","shot:"+e);if(mod.cfg.laserDebug)hud.error(String(e));}
         };
         return wp;
      }
      public function configure(wp:*):void
      {
         var c:*=mod.cfg;wp.nazv=NAME;
         var r:Object=seen[wp];
         if(r==null) {r={enabled:c.laserEnabled};seen[wp]=r;}
         if(r.enabled!=c.laserEnabled) {wp.t_attack=0;wp.is_shoot=false;r.enabled=c.laserEnabled;}
         // Original shoot supplies ammo, sound, semi-auto and SATS bookkeeping.
         // Zero projectiles prevents any ordinary damage/accuracy/ricochet path.
         wp.kol=0;wp.auto=false;wp.damage=wp.damageExpl=wp.explRadius=wp.destroy=wp.otbros=0;
         wp.deviation=wp.recoil=0;wp.precision=0;wp.noPerc=true;wp.noTrass=true;
         var rapid:int=Math.max(3,Math.round(c.laserInterval*30));
         if(wp.rapid!=rapid && wp.t_attack>0)
            wp.t_attack=wp.t_attack==wp.rapid?rapid:Math.min(wp.t_attack,rapid-1);
         wp.rapid=rapid;wp.drot=0;
         wp.holder=c.laserMagazine*c.laserAmmo;wp.rashod=c.laserAmmo;wp.reload=Math.round(c.laserReload*30);
         if(wp.hold>wp.holder)
         {
            var w:*=MSWU.world(),extra:int=wp.hold-wp.holder;
            if(w!=null && w.invent!=null && w.invent.items[wp.ammo]!=null)
            {w.invent.items[wp.ammo].kol+=extra;w.invent.mass[2]+=w.invent.items[wp.ammo].mass*extra;wp.hold=wp.holder;}
         }
         wp.reloadMult=1;wp.satsCons=c.laserAP;wp.noSats=!c.laserEnabled;
         wp.hp=wp.maxhp; // No random wear misfire on an otherwise valid eye shot.
         if(!c.laserEnabled)wp.t_attack=wp.rapid+1000;
      }
      public function frame(w:*):void
      {
         try
         {
            if(w.loc!==loc || w.gg!==player)
            {
               clear();loc=w.loc;player=w.gg;seen=new Dictionary(true);
            }
            if(loc==null || player==null || player.hp<=0) {clear();return;}
            if(!loc.active || w.invent==null || w.invent.weapons==null)return;
            var wp:*=ensureWeapon(w);if(wp!=null)configure(wp);
            if(!mod.cfg.laserEnabled) {blind.clearSource("laser");clearVisuals();blind.prune(w);return;}
            provision(w);blind.prune(w);
            render(w);
         }
         catch(e:*) {mod.cfg.diagSet("laserError","frame:"+e);}
      }
      public function prepare(w:*):void
      {
         if(w==null || w.gg==null || w.loc==null || !w.loc.active || w.invent==null || w.invent.weapons==null)return;
         var wp:*=ensureWeapon(w);if(wp!=null)configure(wp);
      }
      public function clear():void
      {blind.clear();clearVisuals();}
      private function clearVisuals():void
      {for each(var b:MSWLaserBeam in beams)b.dispose();beams=[];hud.clearDebug();hud.visible=false;}
      public function fire(w:*,wp:*):Object
      {
         mod.cfg.diagAdd("laserShotEntered");
         if(sats==null)sats=MSWU.cls("fe.inter.MSWLaserSats");
         var a:Number=Math.atan2(w.gg.celY-wp.bulY,w.gg.celX-wp.bulX),u:*=null;
         if(w.gg.sats.que.length>0)
         {
            if(sats==null)throw new Error("Laser SATS access missing from build");
            u=sats["target"](w.gg.sats.que[0]);
            if(u!=null && MSWLaserGeometry.hostile(u,w)) {var e:Object=MSWLaserGeometry.eye(u);a=Math.atan2(e.y-wp.bulY,e.x-wp.bulX);}
         }
         else {u=MSWLaserGeometry.assist(w,wp,mod.cfg);if(u!=null) {e=MSWLaserGeometry.eye(u);a=Math.atan2(e.y-wp.bulY,e.x-wp.bulX);}}
         var hit:Object=MSWLaserGeometry.castRay(w,wp.bulX,wp.bulY,a,mod.cfg.laserEye,2000,w.gg);
         var applied:Boolean=hit.eye && MSWLaserGeometry.hostile(hit.unit,w) && blind.apply(hit.unit,w);
         var result:String=applied?"blind":(hit.eye?"ineligible":hit.reason);
         mod.cfg.diagSet("laserLastHit",result);
         if(mod.cfg.laserDebug)hud.report(hit,result,blind.remaining(hit.unit),mod.cfg.laserEye);
         beams.push(new MSWLaserBeam(w,wp,hit));
         mod.cfg.diagAdd("laserShots");return hit;
      }
      private function render(w:*):void
      {
         for(var i:int=beams.length-1;i>=0;i--)if(!beams[i].in_chain)beams.splice(i,1);
         var wp:*=w.gg.currentWeapon;
         var equipped:Boolean=wp!=null && wp.id==ID && !w.pip.active && !mod.panel.overlayOpen;
         var target:*=null;
         if(equipped) {wp.getBulXY();target=MSWLaserGeometry.assist(w,wp,mod.cfg);}
         hud.render(w,equipped,target,blind.states,mod.cfg.laserDebug);
      }
   }
}
