package
{
   /** Bounded local routing. Physical collision still belongs to the original Bullet. */
   public class MSWSmartRoute
   {
      public static function clear(loc:*, x:Number,y:Number, tx:Number,ty:Number, margin:Number=2):Boolean
      {
         var n:int=Math.ceil(Math.max(Math.abs(tx-x),Math.abs(ty-y))/8);
         if(n>600) return false;
         n=Math.max(1,n);
         for(var i:int=0;i<=n;i++)
         {
            var px:Number=x+(tx-x)*i/n, py:Number=y+(ty-y)*i/n;
            if(blocked(loc,px,py,margin)) return false;
         }
         return true;
      }
      private static function blocked(loc:*,x:Number,y:Number,m:Number):Boolean
      {
         for(var i:int=0;i<5;i++)
         {
            var px:Number=x+(i==1?-m:i==2?m:0), py:Number=y+(i==3?-m:i==4?m:0);
            var t:*=loc.getAbsTile(px,py);
            if(t==null) return true;
            if(t.phis==1 && px>=t.phX1 && px<=t.phX2 && py>=t.phY1 && py<=t.phY2) return true;
         }
         return false;
      }
      public static function find(loc:*,sx:Number,sy:Number,tx:Number,ty:Number):Array
      {
         if(clear(loc,sx,sy,tx,ty)) return [{x:tx,y:ty}];
         // Search at most 180 nodes, within 240 pixels of the bullet. A node can
         // connect directly to the distant goal, so only the nearby obstruction is routed.
         var open:Array=[{x:sx,y:sy,g:0,h:distance(sx,sy,tx,ty),p:null,ix:0,iy:0}];
         var visited:Object={}; var best:Object={}; best["0,0"]=0;
         var expanded:int=0;
         while(open.length>0 && expanded++<180)
         {
            var bi:int=0;
            for(var i:int=1;i<open.length;i++) if(open[i].g+open[i].h<open[bi].g+open[bi].h) bi=i;
            var a:Object=open.splice(bi,1)[0]; var key:String=a.ix+","+a.iy;
            if(visited[key]) continue;
            visited[key]=true;
            if(clear(loc,a.x,a.y,tx,ty))
            {
               var route:Array=[{x:tx,y:ty}];
               while(a.p!=null) { route.unshift({x:a.x,y:a.y}); a=a.p; }
               return route;
            }
            for(var dx:int=-1;dx<=1;dx++) for(var dy:int=-1;dy<=1;dy++)
            {
               if(dx==0 && dy==0) continue;
               var ix:int=a.ix+dx, iy:int=a.iy+dy;
               if(Math.abs(ix)>10 || Math.abs(iy)>10) continue;
               key=ix+","+iy;
               if(visited[key]) continue;
               var nx:Number=sx+ix*24, ny:Number=sy+iy*24;
               var g:Number=a.g+(dx!=0 && dy!=0?33.9411:24);
               if(key in best && best[key]<=g) continue;
               if(!clear(loc,a.x,a.y,nx,ny)) continue;
               best[key]=g;
               open.push({x:nx,y:ny,g:g,h:distance(nx,ny,tx,ty),p:a,ix:ix,iy:iy});
            }
         }
         return [];
      }
      public static function distance(x:Number,y:Number,tx:Number,ty:Number):Number
      { return Math.sqrt((x-tx)*(x-tx)+(y-ty)*(y-ty)); }
      public static function angle(a:Number):Number
      { while(a>Math.PI)a-=Math.PI*2; while(a< -Math.PI)a+=Math.PI*2; return a; }
      public static function steer(b:*,tx:Number,ty:Number,maxTurn:Number,loc:*,fraction:Number=1,radiusScale:Number=1):void
      {
         var speed:Number=Math.sqrt(b.dx*b.dx+b.dy*b.dy);
         if(!(speed>0) || !isFinite(speed)) return;
         var old:Number=Math.atan2(b.dy,b.dx);
         var turn:Number=pursuit(b,tx,ty,maxTurn,fraction,radiusScale);
         // Preserve momentum and angular limit. If the preferred arc hits terrain,
         // try other legal headings for this step; never teleport around an obstacle.
         var choices:Array=[turn,-maxTurn,maxTurn,0,-maxTurn/2,maxTurn/2];
         var score:Number=1e9, selected:Number=turn;
         for each(var d:Number in choices)
         {
            var a:Number=old+d;
            if(!clear(loc,b.X,b.Y,b.X+Math.cos(a)*speed*fraction,b.Y+Math.sin(a)*speed*fraction,0.5)) continue;
            var cost:Number=Math.abs(angle(turn-d));
            if(cost<score) { score=cost; selected=d; }
            if(cost==0) break;
         }
         applyTurn(b,selected,speed);
      }
      public static function pursuit(b:*,tx:Number,ty:Number,maxTurn:Number,fraction:Number=1,radiusScale:Number=1):Number
      {
         var speed:Number=Math.sqrt(b.dx*b.dx+b.dy*b.dy);
         var old:Number=Math.atan2(b.dy,b.dx);
         var desired:Number=angle(Math.atan2(ty-b.Y,tx-b.X)-old);
         // Pursuit curvature eases into the target bearing over travelled
         // distance, instead of snapping onto a ray as soon as the turn fits.
         var requested:Number=desired;
         if(fraction<1 && Math.abs(desired)<Math.PI/2)
         {
            requested=2*speed*fraction*Math.sin(desired)/(Math.max(speed*fraction,distance(b.X,b.Y,tx,ty))*radiusScale);
            // Radius changes pursuit curvature as well as the angular ceiling.
            // Stop at the target bearing instead of oversteering across it.
            if(radiusScale<1) requested=Math.max(-Math.abs(desired),Math.min(Math.abs(desired),requested));
         }
         return Math.max(-maxTurn,Math.min(maxTurn,requested));
      }
      public static function applyTurn(b:*,turn:Number,speed:Number):void
      {
         var a:Number=Math.atan2(b.dy,b.dx)+turn;
         b.dx=Math.cos(a)*speed; b.dy=Math.sin(a)*speed; b.vel=speed;
         b.rot=a; b.vRot=true; b.knockx=b.dx/speed; b.knocky=b.dy/speed;
      }
   }
}
