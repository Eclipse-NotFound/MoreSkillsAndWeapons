package
{
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import flash.utils.getQualifiedClassName;
   /** Visual eye/sensor anchors. Native eyeX/Y are coarse perception origins. */
   public class MSWLaserEyes
   {
      private static var access:Class;
      // Local visual coordinates measured against the original 1.02 sprites.
      // Bitmap actors with head-pose tables take the animated path below.
      private static const anchors:Object={
         UnitProtect:[16,-80],UnitGutsy:[0,-78],UnitEqd:[28,-64],UnitMerc:[22,-70],
         UnitZombie:[27,-64],UnitHellhound:[27,-98],UnitMonstrik:[16,-15],
         UnitAnt:[18,-16],UnitNecros:[15,-45],UnitBossEncl:[32,-83],
         UnitRobobrain:[16,-55],UnitSentinel:[0,-90],UnitBossUltra:[0,-104],
         UnitRoller:[0,0],UnitSpriteBot:[16,-22],UnitVortex:[3,-22],
         UnitDron:[0,-20],UnitBossDron:[0,-20],UnitMsp:[0,-14],
         UnitBloat:[5,-18],UnitBat:[4,-4],UnitFish:[11,-22],
         UnitThunderHead:[-1800,-1000]
      };
      private static function local(u:*,node:DisplayObject,x:Number,y:Number):Object
      {
         // Transform only inside the actor. Camera, zoom, and temporary visual
         // parenting never change the world-space hit position.
         var p:Point=u.vis.globalToLocal(node.localToGlobal(new Point(x,y)));
         var matrix:*=u.vis.transform.matrix;
         p=matrix.transformPoint(p);
         return {x:p.x,y:p.y};
      }
      public static function available(u:*):Boolean
      {
         if(getQualifiedClassName(u)!="fe.unit::UnitTurret")return true;
         // Hidden mounts retain their light child even with the casing closed.
         // Only the fully deployed sprite exposes a hittable sensor.
         if(u.vis==null || u.vis.osn==null || u.vis.osn.currentFrame!=1)return false;
         var light:*=u.vis.osn.light;
         if(light==null || !light.visible)return false;
         var bounds:*=light.getBounds(light);
         return bounds.width>0 && bounds.height>0;
      }
      public static function point(u:*):Object
      {
         var type:String=getQualifiedClassName(u).split("::").pop();
         if(u.vis!=null)
         {
            // These vector actors expose the actual animated eye symbol.
            if(type=="UnitBossRaider" || type=="UnitBossNecr")
            {
               var part:*=u.vis.osn.body.head.eye;
               if(part!=null)
               {var bounds:*=part.getBounds(part);return local(u,part,bounds.x+bounds.width/2,bounds.y+bounds.height/2);}
            }
            if(type=="UnitTurret" && u.vis.osn!=null && u.vis.osn.light!=null)
               return local(u,u.vis.osn.light,0,0);
         }
         if(access==null)access=MSWU.cls("fe.unit.MSWBlindAccess");
         var p:Object=access==null?null:access["pose"](u);
         if(p!=null && type!="UnitGutsy" && type!="UnitMerc" && MSWU.has(u,"wPos") && u.wPos!=null && u.wPos[p.id]!=null)
         {
            var head:*=u.wPos[p.id][p.frame];
            if(head!=null)
            {
               var ox:Number=-6,oy:Number=-10;
               var a:Number=MSWU.num(head,"r")*Math.PI/180;
               // Alicorn tables describe a levitating weapon, whose rotation
               // is independent of the head; use only its animated translation.
               if(type=="UnitAlicorn") {ox=-20;oy=32;a=0;}
               if(type=="UnitBossAlicorn") {ox=-25;oy=45;a=0;}
               return {x:u.X+(p.x+head.x+ox*Math.cos(a)-oy*Math.sin(a))*u.storona,
                       y:u.Y+p.y+head.y+ox*Math.sin(a)+oy*Math.cos(a)};
            }
         }
         var anchor:Array=anchors[type];
         if(anchor!=null && u.vis!=null)return local(u,u.vis,anchor[0],anchor[1]);
         return {x:u.X+u.scX*.25*u.storona,y:u.Y-u.scY*.75};
      }
   }
}
