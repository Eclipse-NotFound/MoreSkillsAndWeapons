package
{
   import flash.utils.getQualifiedClassName;
   /** Geometry only. Resolve the first body/obstacle before testing its eye. */
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
      public static function eye(u:*):Object {return {x:u.eyeX,y:u.eyeY};}
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
      public static function trace(w:*,x:Number,y:Number,a:Number,eyeRadius:Number,limit:Number=2000,owner:*=null):Object
      {
         var dx:Number=Math.cos(a),dy:Number=Math.sin(a),end:Number=wall(w.loc,x,y,dx,dy,limit);
         var first:*=null,best:Number=end;
         for each(var u:* in w.loc.units)
         {
            if(u===owner || !live(u,w.loc))continue;
            var d:Number=rect(x,y,dx,dy,u,best);
            if(d<best) {first=u;best=d;}
         }
         var hit:Boolean=false;
         if(first!=null)
         {
            var e:Object=eye(first),along:Number=(e.x-x)*dx+(e.y-y)*dy;
            var cross:Number=Math.abs((e.x-x)*dy-(e.y-y)*dx);
            hit=along>=0 && along<=end && cross<=radius(first,eyeRadius) && front(first,dx) && MSWU.num(first,"shithp")<=0;
            if(hit)best=along;
         }
         return {unit:first,eye:hit,x:x+dx*best,y:y+dy*best,distance:best,angle:a};
      }
      public static function assist(w:*,wp:*,cfg:*):*
      {
         var speed:Number=Math.sqrt(w.gg.dx*w.gg.dx+w.gg.dy*w.gg.dy);
         var maxAngle:Number=cfg.laserAngle*Math.PI/180*Math.max(0,1-speed/cfg.laserSpeed);
         if(maxAngle<=0)return null;
         var base:Number=Math.atan2(w.gg.celY-wp.bulY,w.gg.celX-wp.bulX),best:Number=Infinity,result:*=null;
         for each(var u:* in w.loc.units)
         {
            if(!hostile(u,w) || !u.isVis || u.invis || (u.vis!=null && !u.vis.visible))continue;
            var bx:Number=Math.max(u.X1-w.celX,0,w.celX-u.X2),by:Number=Math.max(u.Y1-w.celY,0,w.celY-u.Y2);
            if(bx*bx+by*by>cfg.laserRadius*cfg.laserRadius)continue;
            var e:Object=eye(u),a:Number=Math.atan2(e.y-wp.bulY,e.x-wp.bulX);
            if(Math.abs(angle(a-base))>maxAngle)continue;
            var dist:Number=(e.x-w.celX)*(e.x-w.celX)+(e.y-w.celY)*(e.y-w.celY);
            if(dist>=best)continue;
            var hit:Object=trace(w,wp.bulX,wp.bulY,a,cfg.laserEye,2000,w.gg);
            if(hit.unit===u && hit.eye) {best=dist;result=u;}
         }
         return result;
      }
   }
}
