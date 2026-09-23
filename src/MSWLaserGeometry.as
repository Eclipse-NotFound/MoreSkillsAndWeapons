package
{
   import flash.utils.getQualifiedClassName;
   /** First contact among obstacles, bodies and their visible eye regions. */
   public class MSWLaserGeometry
   {
      private static var access:Class;
      public static function live(u:*,loc:*):Boolean
      {return u!=null && u.loc===loc && u.hp>0 && u.sost<3 && !u.disabled && !u.trigDis && u.scX>0 && u.scY>0;}
      public static function hostile(u:*,w:*):Boolean
      {
         if(!live(u,w.loc) || u.sost!=1 || u===w.gg || u.fraction<=0 || u.fraction>=100 || u.fraction==w.gg.fraction || u.npc || u.noAgro)return false;
         if(access==null)access=MSWU.cls("fe.unit.MSWBlindAccess");
         if(access!=null && access["scriptStopped"](u))return false;
         var type:String=getQualifiedClassName(u);
         return !/::(Mine|UnitTrap|UnitTrigger|UnitDamager|UnitTransmitter|UnitBloatEmitter)$/.test(type);
      }
      public static function radius(u:*,r:Number):Number
      {return Math.max(3,Math.min(10,r*Math.sqrt(Math.max(1,u.scX*u.scY)/2400)));}
      public static function front(u:*,dx:Number):Boolean {return dx*u.storona< -0.000001;}
      public static function eye(u:*):Object
      {return MSWLaserEyes.point(u);}
      public static function angle(a:Number):Number {while(a>Math.PI)a-=2*Math.PI;while(a< -Math.PI)a+=2*Math.PI;return a;}
      public static function rect(x:Number,y:Number,dx:Number,dy:Number,b:*,limit:Number):Number
      {
         var lo:Number=0,hi:Number=limit;
         if(Math.abs(dx)<1e-9) {if(x<b.X1 || x>b.X2)return Infinity;}
         else {var a:Number=(b.X1-x)/dx,c:Number=(b.X2-x)/dx;lo=Math.max(lo,Math.min(a,c));hi=Math.min(hi,Math.max(a,c));}
         if(Math.abs(dy)<1e-9) {if(y<b.Y1 || y>b.Y2)return Infinity;}
         else {a=(b.Y1-y)/dy;c=(b.Y2-y)/dy;lo=Math.max(lo,Math.min(a,c));hi=Math.min(hi,Math.max(a,c));}
         return hi>=lo && hi>=0?lo:Infinity;
      }
      public static function wall(loc:*,x:Number,y:Number,dx:Number,dy:Number,limit:Number):Number
      {
         var best:Number=limit;
         // Traverse every crossed grid cell, then intersect its actual solid
         // rectangle. No fixed sample interval can skip a thin corner.
         var tileClass:Class=MSWU.cls("fe.loc.Tile");
         var sx:Number=tileClass["tileX"],sy:Number=tileClass["tileY"];
         var cx:int=Math.floor(x/sx),cy:int=Math.floor(y/sy);
         var stepx:int=dx<0?-1:1,stepy:int=dy<0?-1:1;
         var tx:Number=Math.abs(dx)<1e-9?Infinity:((cx+(dx<0?0:1))*sx-x)/dx;
         var ty:Number=Math.abs(dy)<1e-9?Infinity:((cy+(dy<0?0:1))*sy-y)/dy;
         var deltax:Number=Math.abs(sx/dx),deltay:Number=Math.abs(sy/dy),t:Number=0;
         while(t<=best)
         {
            if(cx<0 || cy<0 || cx>=loc.spaceX || cy>=loc.spaceY) {best=Math.min(best,t);break;}
            var tile:*=loc.getTile(cx,cy);
            if(tile.phis==1)
               best=Math.min(best,rect(x,y,dx,dy,{X1:tile.phX1,X2:tile.phX2,Y1:tile.phY1,Y2:tile.phY2},limit));
            if(tx<ty) {t=tx;tx+=deltax;cx+=stepx;}
            else {t=ty;ty+=deltay;cy+=stepy;}
         }
         for each(var box:* in loc.objs)
         {
            if(box!=null && MSWU.has(box,"dead") && !box.dead && MSWU.num(box,"phis")>0)
               best=Math.min(best,rect(x,y,dx,dy,box,limit));
         }
         return best;
      }
      // Do not name this trace: release mxmlc can erase an unqualified call as
      // a debug trace while leaving its return-value coercion (VerifyError 1024).
      public static function castRay(w:*,x:Number,y:Number,a:Number,eyeRadius:Number,limit:Number=2000,owner:*=null):Object
      {
         var dx:Number=Math.cos(a),dy:Number=Math.sin(a),end:Number=wall(w.loc,x,y,dx,dy,limit);
         var first:*=null,best:Number=end,eyeAlong:Number=0,hit:Boolean=false,reason:String="miss";
         for each(var u:* in w.loc.units)
         {
            if(u===owner || !live(u,w.loc))continue;
            var e:Object=eye(u),along:Number=(e.x-x)*dx+(e.y-y)*dy,r:Number=radius(u,eyeRadius);
            var cross:Number=Math.abs((e.x-x)*dy-(e.y-y)*dx);
            var throughEye:Boolean=along>=0 && along<=end && cross<=r;
            var eyeEntry:Number=throughEye?Math.max(0,along-Math.sqrt(Math.max(0,r*r-cross*cross))):Infinity;
            var d:Number=Math.min(rect(x,y,dx,dy,u,end),eyeEntry);
            if(d<best)
            {
               first=u;best=d;eyeAlong=along;
               hit=throughEye && front(u,dx) && MSWU.num(u,"shithp")<=0;
               reason=!throughEye?"body":(!front(u,dx)?"back":(MSWU.num(u,"shithp")>0?"shield":"eye"));
            }
         }
         if(hit)best=eyeAlong;
         return {unit:first,eye:hit,x:x+dx*best,y:y+dy*best,distance:best,angle:a,reason:reason};
      }
      public static function assist(w:*,wp:*,cfg:*):*
      {
         if(!cfg.laserAssist)return null;
         var speed:Number=Math.sqrt(w.gg.dx*w.gg.dx+w.gg.dy*w.gg.dy);
         var range:Number=cfg.laserBodyRadius*(1-(1-cfg.laserAssistFloor/100)*Math.min(1,speed/cfg.laserAssistSpeed));
         var pointed:*=null,pointedEye:Number=Infinity,result:*=null,bestBody:Number=Infinity,bestEye:Number=Infinity;
         for each(var u:* in w.loc.units)
         {
            if(!hostile(u,w) || !u.isVis || u.invis || (u.vis!=null && !u.vis.visible))continue;
            var bx:Number=Math.max(u.X1-w.celX,0,w.celX-u.X2),by:Number=Math.max(u.Y1-w.celY,0,w.celY-u.Y2);
            var body:Number=bx*bx+by*by;
            if(body>range*range)continue;
            var e:Object=eye(u);
            var dist:Number=(e.x-w.celX)*(e.x-w.celX)+(e.y-w.celY)*(e.y-w.celY);
            // Identify the body under the cursor BEFORE checking its eye ray.
            // An invalid pointed target must not redirect this shot to a neighbour.
            if(body==0)
            {
               if(dist<pointedEye) {pointed=u;pointedEye=dist;}
               continue;
            }
            if(pointed!=null || body>bestBody || (body==bestBody && dist>=bestEye))continue;
            if(reachable(w,wp,u,e,cfg)) {bestBody=body;bestEye=dist;result=u;}
         }
         if(pointed!=null)return reachable(w,wp,pointed,eye(pointed),cfg)?pointed:null;
         return result;
      }
      private static function reachable(w:*,wp:*,u:*,e:Object,cfg:*):Boolean
      {
         var hit:Object=castRay(w,wp.bulX,wp.bulY,Math.atan2(e.y-wp.bulY,e.x-wp.bulX),cfg.laserEye,2000,w.gg);
         return hit.unit===u && hit.eye;
      }
   }
}
