package
{
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   public class MSWBlindController
   {
      private var mod:*;
      private var access:Class;
      private var bladeClass:Class;
      public var states:Dictionary=new Dictionary(true);
      private var shots:Dictionary=new Dictionary(true);
      public function MSWBlindController(m:*) {mod=m;}
      public function apply(u:*,w:*):Boolean
      {
         if(!MSWLaserGeometry.hostile(u,w) || !MSWLaserEyes.available(u))return false;
         if(access==null)access=MSWU.cls("fe.unit.MSWBlindAccess");
         if(access==null)throw new Error("Laser host access missing from build");
         var s:Object=states[u];
         if(s!=null) {s.remaining=mod.cfg.laserDuration*30;return true;}
         // Never resume an actor a script had already disabled.
         if(MSWU.has(u,"controlOn") && !u.controlOn)return false;
         s={unit:u,remaining:mod.cfg.laserDuration*30,x:u.X,y:u.Y,next:0,burst:0,dir:1,meleeWait:0,
            vision:u.vision,hearing:MSWU.num(u,"hearing"),wp:u.currentWeapon,find:null,force:0,turret:MSWLaserGeometry.turret(u)};
         states[u]=s;
         if(s.wp!=null) {s.find=s.wp.findCel;s.force=s.wp.forceRot;}
         if(s.wp!=null && s.wp.tip==1)
         {
            if(bladeClass==null)bladeClass=MSWU.cls("fe.weapon.MSWPanicBlade");
            if(bladeClass==null)throw new Error("Panic blade class missing from build");
            if(!(s.wp.b is bladeClass))s.wp.b=new bladeClass(s.wp.b);
         }
         s.node=new MSWLaserStep(function(node:*):void {advance(s,node);});
         insertBefore(s.node,u);
         access["clearTarget"](u);u.vision=0;
         mod.cfg.diagAdd("laserBlinds");return true;
      }
      public function remaining(u:*):Number {return states[u]==null?0:states[u].remaining/30;}
      public static function insertBefore(node:*,target:*):void
      {
         if(node.in_chain && node.loc===target.loc && node.nobj===target)return;
         if(node.in_chain)node.loc.remObj(node);
         var loc:*=target.loc;node.loc=loc;node.X=node.Y=0;
         if(!target.in_chain)return;
         node.pobj=target.pobj;node.nobj=target;node.in_chain=true;
         if(target.pobj!=null)target.pobj.nobj=node;else loc.firstObj=node;
         target.pobj=node;
         if(loc.nextObj===target)loc.nextObj=node;
      }
      private function end(s:Object):void
      {
         var u:*=s.unit;
         if(s.node!=null && s.node.in_chain)s.node.loc.remObj(s.node);
         if(u!=null)
         {
            if(u.vision==0)u.vision=s.vision;
            u.walk=0;u.setCel(null,u.X+u.storona*120,u.Y-u.scY/2);
            access["clearTarget"](u,!access["scriptStopped"](u));
            if(s.wp!=null && s.find!==null) {s.wp.findCel=s.find;s.wp.forceRot=s.force;}
            delete states[u];
         }
      }
      public function clear():void
      {
         var all:Array=[];for each(var s:Object in states)all.push(s);
         for each(s in all)end(s);
         for each(var shot:Object in shots)if(shot.node.in_chain)shot.node.loc.remObj(shot.node);
         states=new Dictionary(true);shots=new Dictionary(true);
      }
      public function prune(w:*):void
      {
         var ended:Array=[];
         for each(var s:Object in states)
         {
            if(!MSWLaserGeometry.live(s.unit,w.loc) || s.unit.sost!=1 || access["scriptStopped"](s.unit))ended.push(s);
            else insertBefore(s.node,s.unit);
         }
         for each(s in ended)end(s);
         for(var b:* in shots)if(!b.in_chain || b.loc!==w.loc)
         {if(shots[b].node.in_chain)shots[b].node.loc.remObj(shots[b].node);delete shots[b];}
      }
      private function advance(s:Object,node:*):void
      {
         var u:*=s.unit,w:*=MSWU.world(),loc:*=node.loc;
         if(!u.in_chain || !MSWLaserGeometry.live(u,loc) || u.sost!=1 || access["scriptStopped"](u) || !mod.cfg.laserEnabled) {end(s);return;}
         if(s.remaining<=0) {end(s);return;}
         // Location.step saved nextObj before invoking this guard. Skip exactly
         // this actor, including when the actor removes itself during effects.
         loc.nextObj=u.nobj;
         try
         {
            if(u.t_emerg>0) {u.t_emerg--;u.setVisPos();return;}
            s.remaining--;s.meleeWait--;access["clearTarget"](u);u.vision=0;
            if(u.inter!=null)u.inter.step();
            u.getRasst2();if(u.radioactiv)u.ggModum();
            u.forces();
            if(s.turret)u.walk=0;
            var wp:*=u.currentWeapon;
            if(u.stun<=0 && u.t_throw<=0 && !u.levit)
            {
               if(s.next--<=0)
               {
                  s.burst=Math.max(3+int(Math.random()*7),wp==null?0:wp.prep+3);
                  s.next=s.burst+12+int(Math.random()*24);
                  s.dir=Math.random()<0.5?-1:1;
                  if(u.X>s.x+100)s.dir=-1;if(u.X<s.x-100)s.dir=1;
                  s.angle=Math.random()*Math.PI*2;
                  if(s.turret)s.angle=MSWLaserGeometry.angle(s.angle);
               }
               // A turret rotates its barrel, not its mounting or armour.
               if(!s.turret)access["facing"](u,Math.cos(s.angle)<0?-1:1);
               u.setCel(null,u.X+Math.cos(s.angle)*700,u.Y-u.scY/2+Math.sin(s.angle)*700);
               if(!u.fixed && !s.turret)
               {
                  u.walk=s.dir;
                  u.dx+=s.dir*Math.max(0.2,MSWU.num(u,"accel",0.5));
                  var speed:Number=Math.max(1,Math.min(u.walkSpeed,u.maxSpeed));
                  u.dx=Math.max(-speed,Math.min(speed,u.dx));
                  if(u.isFly)u.dy+=(s.y-u.Y)*0.01+(Math.random()-0.5)*0.3;
               }
               if(wp!=null)
               {
                  wp.findCel=false;wp.forceRot=s.angle;wp.rot=s.angle;
                  if(s.burst-->0)
                  {
                     var attackBefore:int=wp.t_attack;wp.attack();
                     if(wp.tip==1 && attackBefore<=0 && wp.t_attack>0) {wp.b.arm();mod.cfg.diagAdd("laserPanicSwings");}
                  }
               }
               else if(s.burst>0 && s.meleeWait<=0) {s.burst=0;s.meleeWait=Math.max(24,wp==null?30:wp.rapid);melee(u,loc);}
            }
            else u.walk=0;
            if(!u.fixed)
            {
               var div:int=Math.max(1,Math.ceil(Math.max(Math.abs(u.dx+u.osndx),Math.abs(u.dy+u.osndy))/10));
               for(var i:int=0;i<div;i++)u.run(div);
            }
            u.checkWater();u.actions();u.setVisPos();
            if(u.hpbar!=null)u.setHpbarPos();
            if(!s.turret)u.animate();
            u.onCursor=u.isVis && u.X1<w.celX && u.X2>w.celX && u.Y1<w.celY && u.Y2>w.celY?u.prior:0;
            // Mark births around the child weapon steps; old in-flight shots
            // keep their original semantics. Do not change the shooter's faction.
            var before:Dictionary=chainSet(loc);
            for each(var child:* in u.childObjs)if(child!=null)child.step();
            // Native Weapon.step constrains fixed mount firing arcs. Draw the
            // resulting barrel angle, rather than the unclamped requested one.
            if(s.turret)u.animate();
            var b:*=loc.firstObj;
            while(b!=null)
            {
               var next:*=b.nobj;
               if(!before[b] && MSWU.has(b,"owner") && b.owner===u && MSWU.has(b,"targetObj") && MSWU.has(b,"run"))trackShot(b);
               b=next;
            }
            access["finish"](u);
         }
         catch(e:*) {mod.cfg.diagSet("laserError","blind-step:"+e+(e is Error?"\n"+e.getStackTrace():""));end(s);}
      }
      private function melee(u:*,loc:*):void
      {
         var damage:Number=u.dam;
         if(u.currentWeapon!=null && u.currentWeapon.tip==1)damage+=u.currentWeapon.damage*0.5;
         if(damage<=0)return;
         for each(var v:* in loc.units)
         {
            if(v===u || !MSWLaserGeometry.live(v,loc))continue;
            var dx:Number=v.X-u.X,dy:Number=(v.Y-v.scY/2)-(u.Y-u.scY/2);
            if(dx*u.storona>=0 && Math.abs(dx)<u.scX/2+v.scX/2+24 && Math.abs(dy)<Math.max(u.scY,v.scY)/2)
               u.attKorp(v);
         }
      }
      private function chainSet(loc:*):Dictionary
      {var d:Dictionary=new Dictionary(true),o:*=loc.firstObj;while(o!=null){d[o]=true;o=o.nobj;}return d;}
      private function trackShot(b:*):void
      {
         if(shots[b]!=null)return;
         if(getQualifiedClassName(b)=="fe.weapon::SmartBullet")b.cel=null;
         mod.cfg.diagAdd("laserPanicShots");
         var s:Object={bullet:b,node:null};s.node=new MSWLaserStep(function(n:*):void {shotStep(s,n);});shots[b]=s;insertBefore(s.node,b);
      }
      private function shotStep(s:Object,node:*):void
      {
         var b:*=s.bullet,loc:*=node.loc;
         if(!b.in_chain) {if(node.in_chain)loc.remObj(node);delete shots[b];return;}
         loc.nextObj=b.nobj;
         var old:*=b.targetObj;
         var explosionProtection:Array=[],before:Dictionary=chainSet(loc);
         try
         {
            var dx:Number=b.dx+MSWU.num(b,"ddx"),dy:Number=b.dy+MSWU.num(b,"ddy"),len:Number=Math.sqrt(dx*dx+dy*dy),best:Number=len+1,chosen:*=null;
            if(len>0)for each(var u:* in loc.units)
            {
               if(u===b.owner || !MSWLaserGeometry.live(u,loc))continue;
               var dist:Number=MSWLaserGeometry.rect(b.X,b.Y,dx/len,dy/len,u,len);
               if(dist<best) {best=dist;chosen=u;}
            }
            // The original explosion creates targeted secondary bullets. Lift
            // only its allied blast immunity, without changing any faction.
            if(b.explRadius>0)for each(u in loc.units)
            {
               if(u!==b.owner && u.fraction==b.owner.fraction)
               {explosionProtection.push({unit:u,value:u.friendlyExpl});u.friendlyExpl=1;}
            }
            b.targetObj=old!=null?old:chosen;b.step();
            var child:*=loc.firstObj;
            while(child!=null)
            {
               var next:*=child.nobj;
               if(!before[child] && MSWU.has(child,"owner") && child.owner===b.owner && MSWU.has(child,"targetObj") && MSWU.has(child,"run"))trackShot(child);
               child=next;
            }
         }
         catch(e:*) {mod.cfg.diagSet("laserError","panic-shot:"+e);}
         finally {b.targetObj=old;for each(var saved:Object in explosionProtection)saved.unit.friendlyExpl=saved.value;}
      }
   }
}
