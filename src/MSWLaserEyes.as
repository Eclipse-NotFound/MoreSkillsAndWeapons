package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.geom.Point;
   import flash.utils.getQualifiedClassName;
   /** Visual eye/sensor anchors. Native eyeX/Y are coarse perception origins. */
   public class MSWLaserEyes
   {
      private static var access:Class;
      // Native 1.02 Merc pupil centres, in the displayed 170x170 bitmap frame.
      // Row 0 is ground movement/stay; row 1 is flight/jump. Its wPos table
      // follows the separate gun arm, so it cannot locate the animated eye.
      private static const mercEyes:Array=[null,
         [ // sprGriffon1
            [[119.5,63.5],[119,63.5],[119,63.5],[119.5,63.5],[119,63.5],[119.5,64],[119,63],[119.5,63.5],[119.5,63.5],[119,62.5],[119.5,62.5],[119.5,63],[119.5,62],[120,62],[120.5,61.5],[120.5,62],[120.5,61.5],[120.5,61],[121.5,61.5],[120.5,63],[120.5,62.5],[120,63.5],[119.5,63.5],[119.5,63.5],[119.5,63.5]],
            [[131.5,66],[131,65],[131.5,65],[131,64.5],[132,64],[132,64],[132,62.5],[132.5,62],[132.5,63.5],[132,64],[131.5,64],[131,64],[131.5,65],[131.5,65.5]]
         ],
         [ // sprGriffon2
            [[119.5,63.5],[118.5,62],[119,62],[118.5,62.5],[119,62.5],[119,62.5],[119,62.5],[119,62],[119,62.5],[119,62],[119.5,62],[119.5,61.5],[120,61.5],[120,62.5],[120.5,61.5],[120.5,61],[120.5,61.5],[120.5,61],[120.5,62],[120.5,61.5],[120,62.5],[120,60.5],[119,60],[119,62],[119.5,62.5]],
            [[130.5,65],[131,64],[131,65],[131,63.5],[131.5,63],[132,63],[132,61],[132.5,62],[132,62],[132.5,64],[131.5,63.5],[131,63.5],[130.5,63.5],[131,65]]
         ],
         [ // sprGriffon3
            [[119,60.5],[119,60.5],[119,61.5],[119,60.5],[119,61],[119,60.5],[119,61],[119.5,60.5],[119,61],[119.5,60.5],[119.5,61.5],[119.5,62],[120.5,61.5],[120,63.5],[120.5,62],[120.5,62],[120.5,61.5],[120.5,62],[121,61],[120.5,61],[120.5,61],[120.5,60],[120,60.5],[119.5,60.5],[119.5,60.5]],
            [[130.5,63],[131,63],[131,63.5],[131.5,63],[131.5,64.5],[131.5,62.5],[132.5,63.5],[132.5,61.5],[132,62.5],[131.5,62.5],[131.5,64.5],[131.5,63],[131,63],[131.5,63]]
         ],
         [ // sprGriffon4
            [[120,62.5],[121,62],[120,63.5],[121,62],[119,61.5],[120.5,62.5],[120,62.5],[119.5,61.5],[119.5,63],[119.5,63],[121,63.5],[120,61],[121.5,60.5],[120,61.5],[122.5,61.5],[121.5,61],[121.5,60.5],[120.5,61],[121.5,61.5],[119.5,62],[121.5,60.5],[122.5,62.5],[121,63],[122,63.5],[123,63]],
            [[132,65],[131.5,65.5],[132,63],[133,63.5],[132,63],[133.5,62.5],[133.5,62],[132.5,63.5],[133,61],[132.5,63],[131.5,63.5],[133,63.5],[132.5,63.5],[132.5,63.5]]
         ],
         [ // sprGriffon5
            [[125,63],[125,63],[125,63],[125,63],[125,63],[125,63],[125,63],[125,63],[125.5,62.5],[125.5,62.5],[125.5,62],[125.5,61.5],[126,61.5],[126,61],[126.5,60.5],[126.5,60],[126.5,60.5],[128,60],[126,61],[125.5,62],[124.5,62.5],[122,62.5],[121.5,62.5],[124.5,63],[122,63]],
            [[136.5,65],[137,64.5],[137.5,64],[137.5,63.5],[138,63],[138,62],[138,61.5],[138.5,61],[138,61.5],[138,62],[137.5,62.5],[137.5,63.5],[137,64],[137,64.5]]
         ]
      ];
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
      private static function child(node:*,index:int):DisplayObject
      {
         var c:DisplayObjectContainer=node as DisplayObjectContainer;
         return c!=null && index>=0 && index<c.numChildren?c.getChildAt(index):null;
      }
      private static function pose(u:*):Object
      {
         if(access==null)access=MSWU.cls("fe.unit.MSWBlindAccess");
         return access==null?null:access["pose"](u);
      }
      public static function available(u:*):Boolean
      {
         if(!MSWEyeFrames.available(pose(u)))return false;
         if(getQualifiedClassName(u)=="fe.unit::UnitBat" && u.vis!=null && u.vis.osn!=null && u.vis.osn.currentFrame==1)return false;
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
                  return type=="UnitBossRaider"?local(u,part,-42,-17):local(u,part,-34,-12);
            }
            if(type=="UnitTurret" && u.vis.osn!=null && u.vis.osn.light!=null)
               return local(u,u.vis.osn.light,0,0);
            // Native vector timelines replace their inner clips when a pose
            // changes. Resolve the current part instead of caching old clips.
            var osn:*=MSWU.has(u.vis,"osn")?u.vis.osn:null;
            if(osn!=null)
            {
               if(type=="UnitBat" && osn.currentFrame>1)
               {
                  part=child(osn,0);
                  if(part!=null && MSWU.has(part,"head"))return local(u,part.head,10,-5);
               }
               if(type=="UnitFish" && MSWU.has(osn,"body"))
               {
                  part=child(osn.body,4);
                  if(part!=null)return u.id=="fish2"?local(u,part,33,-84):local(u,part,49,-38);
               }
               if(type=="UnitBloat")
               {
                  var variant:int=int(String(u.id).substr(5));
                  if(variant>=7)
                  {part=child(osn,1);if(part!=null)return local(u,part,6.5,-6);}
                  else
                  {
                     var insect:Array=[[6,-5],[7,-8],[7,-8],[13,-10],[9,-8],[9,-7],[9,-9]][Math.max(0,variant)];
                     return local(u,osn,insect[0],insect[1]);
                  }
               }
               if(type=="UnitMsp")
               {
                  part=child(osn,0);
                  if(osn.currentFrame>1 && part is DisplayObjectContainer)
                  {
                     part=child(part,DisplayObjectContainer(part).numChildren-1);
                     if(part!=null)
                     {
                        // The awake frame uses a Shape at a nonzero local
                        // origin; walking uses a centred sensor MovieClip.
                        var bounds:*=part.getBounds(part);
                        return local(u,part,bounds.x+bounds.width/2,bounds.y+bounds.height/2);
                     }
                  }
                  return local(u,osn,0,-16);
               }
               if(type=="UnitVortex")
               {part=child(osn,0);if(part!=null)return local(u,part,0,-7);}
               if(type=="UnitRobobrain" && MSWU.has(osn,"body"))
               {part=child(osn.body,3);if(part!=null)return local(u,part,15,-3);}
               if((type=="UnitSentinel" || type=="UnitBossUltra") && MSWU.has(osn,"body"))
                  return type=="UnitBossUltra"?local(u,osn.body,10,-232):local(u,osn.body,0,-234);
               if(type=="UnitDron" || type=="UnitBossDron" || type=="UnitRoller")return local(u,osn,0,0);
               if(type=="UnitSpriteBot")return local(u,osn,16,0);
            }
         }
         var p:Object=pose(u),pixel:Array=MSWEyeFrames.point(p);
         if(pixel!=null)return local(u,p.bitmap,pixel[0],pixel[1]);
         if(p!=null && type=="UnitMerc" && mercEyes[u.tr]!=null && mercEyes[u.tr][p.id]!=null)
         {
            var merc:Array=mercEyes[u.tr][p.id][p.frame];
            if(merc!=null)return local(u,p.bitmap,merc[0],merc[1]);
         }
         if(p!=null && type!="UnitGutsy" && type!="UnitMerc" && MSWU.has(u,"wPos") && u.wPos!=null && u.wPos[p.id]!=null)
         {
            var head:*=u.wPos[p.id][p.frame];
            if(head!=null)
            {
               var ox:Number=-6,oy:Number=-10;
               var offset:Array=MSWEyeFrames.headOffset(p.sprite);
               if(offset!=null){ox+=offset[0];oy+=offset[1];}
               var a:Number=MSWU.num(head,"r")*Math.PI/180;
               // Alicorn tables describe a levitating weapon, whose rotation
               // is independent of the head; use only its animated translation.
               if(type=="UnitAlicorn") {ox=-20;oy=32;a=0;}
               if(type=="UnitBossAlicorn") {ox=-25;oy=45;a=0;}
               return local(u,p.bitmap,head.x+ox*Math.cos(a)-oy*Math.sin(a),head.y+ox*Math.sin(a)+oy*Math.cos(a));
            }
         }
         var anchor:Array=anchors[type];
         if(anchor!=null && u.vis!=null)return local(u,u.vis,anchor[0],anchor[1]);
         return {x:u.X+u.scX*.25*u.storona,y:u.Y-u.scY*.75};
      }
   }
}
