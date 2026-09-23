package
{
   /** Route following and turn-rate continuity; native Bullet.run owns motion. */
   public class MSWSmartSmooth
   {
      public static function steer(b:*,s:Object,path:Array,maxTurn:Number,fraction:Number,radiusScale:Number,forecast:Boolean=true):void
      {
         var speed:Number=Math.sqrt(b.dx*b.dx+b.dy*b.dy);
         if(!(speed>0) || !isFinite(speed) || fraction<=0 || path.length==0) return;
         var amount:Number=Math.max(0,Math.min(1,Number(s.smoothing)/100));
         var goal:Object=aim(b,path,speed,amount);
         var wanted:Number=MSWSmartRoute.pursuit(b,goal.x,goal.y,maxTurn,fraction,radiusScale);
         var previous:Number=s.smoothRate==null?0:Number(s.smoothRate);
         if(!isFinite(previous))previous=0;
         // Express rate in radians per physical step, not per subdivision.
         var tau:Number=0.9+3.9*amount;
         var turn:Number=(previous+(wanted/fraction-previous)*(1-Math.exp(-fraction/tau)))*fraction;
         turn=Math.max(-maxTurn,Math.min(maxTurn,turn));
         var heading:Number=Math.atan2(b.dy,b.dx),length:Number=speed*fraction;
         var horizon:Number=Math.max(18,Math.min(72,speed*0.8));
         var end:Object=path[path.length-1];
         var distance:Number=MSWSmartRoute.distance(b.X,b.Y,end.x,end.y);
         var error:Number=Math.abs(MSWSmartRoute.angle(Math.atan2(end.y-b.Y,end.x-b.X)-heading));
         var limit:Number=maxTurn/fraction;
         var urgent:Boolean=false;
         if(limit>0 && error>0.14 && path.length==1)
         {
            var required:Number=error/limit;
            urgent=distance/speed<required+tau*0.35 || Number(s.remaining)*30<required+tau*0.35;
         }
         var blocked:Boolean=!MSWSmartRoute.clear(b.loc,b.X,b.Y,b.X+Math.cos(heading+turn)*length,b.Y+Math.sin(heading+turn)*length,0.5);
         if(!blocked && forecast)blocked=arcDistance(b,turn/length,horizon)<horizon;
         if(blocked)
         {
            // Prefer a legal short-horizon arc. Only six candidates and eight
            // samples each; failure still goes through real collision/ricochet.
            var choices:Array=[wanted,-maxTurn,maxTurn,0,-maxTurn/2,maxTurn/2];
            var best:Number=-1e30,selected:Number=wanted;
            for each(var candidate:Number in choices)
            {
               var free:Number=arcDistance(b,candidate/length,horizon);
               var score:Number=free*1000-Math.abs(candidate-wanted)/Math.max(0.000001,maxTurn);
               if(score>best){best=score;selected=candidate;}
            }
            turn=selected;urgent=true;
         }
         else if(urgent)turn=wanted;
         if(urgent)s.smoothUrgent=(s.smoothUrgent==null?0:int(s.smoothUrgent))+1;
         MSWSmartRoute.applyTurn(b,turn,speed);
         s.smoothRate=turn/fraction;
      }

      private static function aim(b:*,path:Array,speed:Number,amount:Number):Object
      {
         var first:Object=path[0];
         if(path.length<2)return first;
         var look:Number=Math.max(24,Math.min(80,speed*(0.7+amount)));
         var left:Number=look-MSWSmartRoute.distance(b.X,b.Y,first.x,first.y);
         if(left<=0)return first;
         var result:Object=first,from:Object=first;
         // Advance along the existing short route, only as far as directly
         // visible. Partial segments ease the handover before a waypoint vanishes.
         for(var i:int=1;i<path.length && i<=3 && left>0;i++)
         {
            var next:Object=path[i];
            var distance:Number=MSWSmartRoute.distance(from.x,from.y,next.x,next.y);
            if(distance<0.001){from=next;continue;}
            var travel:Number=Math.min(left,distance);
            for(var j:int=1;j<=4;j++)
            {
               var f:Number=travel*j/(4*distance);
               var x:Number=from.x+(next.x-from.x)*f,y:Number=from.y+(next.y-from.y)*f;
               if(!MSWSmartRoute.clear(b.loc,b.X,b.Y,x,y,2))return result;
               result={x:x,y:y};
            }
            left-=travel;from=next;
         }
         return result;
      }

      private static function arcDistance(b:*,curvature:Number,length:Number):Number
      {
         var count:int=Math.max(1,Math.min(8,Math.ceil(length/9)));
         var step:Number=length/count,x:Number=b.X,y:Number=b.Y,a:Number=Math.atan2(b.dy,b.dx);
         for(var i:int=0;i<count;i++)
         {
            a+=curvature*step;
            var nx:Number=x+Math.cos(a)*step,ny:Number=y+Math.sin(a)*step;
            if(!MSWSmartRoute.clear(b.loc,x,y,nx,ny,0.5))return i*step;
            x=nx;y=ny;
         }
         return length;
      }
   }
}
