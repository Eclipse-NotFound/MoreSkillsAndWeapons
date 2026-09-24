package
{
   /** Bounded, side-effect-free trajectory forecasts choose a radius, never a hit. */
   public class MSWAdaptiveRadius
   {
      public static function reset(s:Object):void
      {
         s.radiusNow=s.turnRadius;s.radiusStable=0;s.radiusAge=0;
         s.radiusCause="reset";s.radiusForecasts=0;
      }
      public static function select(b:*,s:Object,path:Array,turn:Number):Number
      {
         var normal:Number=bound(s.turnRadius,50),minimum:Number=Math.min(normal,bound(s.minTurnRadius,10));
         var current:Number=s.radiusNow==null?normal:Number(s.radiusNow);
         current=Math.max(minimum,Math.min(normal,current));
         if(minimum==normal){s.radiusNow=normal;return normal/100;}
         var u:*=s.target,tx:Number=(u.X1+u.X2)/2,ty:Number=(u.Y1+u.Y2)/2;
         var vx:Number=finite(u.dx),vy:Number=finite(u.dy);
         // Re-evaluate immediately after a target change; otherwise every other
         // physical step. Waiting uses the last chosen radius, not a new guess.
         if(s.radiusAge>0 && Math.abs(tx-Number(s.radiusTX))<8 && Math.abs(ty-Number(s.radiusTY))<8 &&
            vx==s.radiusVX && vy==s.radiusVY)
         {s.radiusAge--;s.radiusNow=current;return current/100;}
         s.radiusAge=1;s.radiusTX=tx;s.radiusTY=ty;s.radiusVX=vx;s.radiusVY=vy;
         var base:Object=evaluate(b,s,path,turn,normal/100);
         s.radiusForecasts=int(s.radiusForecasts)+1;s.radiusCause=base.status;
         var desired:Number=normal,best:Object=base,previous:Number=normal;
         // Exhaustion is unknown, not proof that a larger radius cannot hit.
         if(!base.hit && base.status!="unknown")
         {
            for(var i:int=1;i<=4;i++)
            {
               var candidate:Number=normal-(normal-minimum)*i/4;
               var trial:Object=evaluate(b,s,path,turn,candidate/100);
               s.radiusForecasts++;
               if(trial.hit)
               {
                  desired=candidate;best=trial;
                  // Refine only the first successful interval. A smaller radius
                  // can take a different obstacle path, so no global monotonicity
                  // or mathematically optimal radius is assumed.
                  for(var j:int=0;j<2;j++)
                  {
                     var mid:Number=(desired+previous)/2;
                     trial=evaluate(b,s,path,turn,mid/100);s.radiusForecasts++;
                     if(trial.hit)desired=mid;else previous=mid;
                  }
                  break;
               }
               if(trial.status!="unknown" && trial.score+2<best.score)
               {desired=candidate;best=trial;}
               previous=candidate;
            }
         }
         if(desired<current-0.01)
         {
            current=desired;s.radiusStable=0;
            s.radiusTightens=int(s.radiusTightens)+1;
         }
         else if(desired>current+0.01 && best.hit)
         {
            s.radiusStable=int(s.radiusStable)+1;
            // Two forecasts of a safe larger radius, then at most 10 percentage
            // points per forecast. Check the intermediate radius as well.
            if(s.radiusStable>=2)
            {
               candidate=Math.min(desired,current+10);
               trial=evaluate(b,s,path,turn,candidate/100);s.radiusForecasts++;
               if(trial.hit){current=candidate;s.radiusRecovers=int(s.radiusRecovers)+1;}
               else s.radiusStable=0;
            }
         }
         else s.radiusStable=0;
         s.radiusNow=Math.max(minimum,Math.min(normal,current));
         return s.radiusNow/100;
      }
      public static function evaluate(b:*,s:Object,path:Array,turn:Number,scale:Number):Object
      {
         // Preserve ammunition capabilities in this private prediction object.
         // A planned breakable window remains a route; native collision still
         // stops the real shot, and forecasting never damages the window.
         var p:Object={X:Number(b.X),Y:Number(b.Y),dx:Number(b.dx),dy:Number(b.dy),loc:b.loc,
            destroy:MSWU.num(b,"destroy"),tipDecal:MSWU.num(b,"tipDecal"),explRadius:MSWU.num(b,"explRadius")};
         var route:Array=path.concat(),u:*=s.target;
         var vx:Number=finite(u.dx),vy:Number=finite(u.dy);
         var x1:Number=u.X1,x2:Number=u.X2,y1:Number=u.Y1,y2:Number=u.Y2;
         var cx:Number=(x1+x2)/2,cy:Number=(y1+y2)/2;
         var available:Number=Math.min(Math.max(1,Number(s.remaining)*30+1),Math.max(1,Number(b.liv)-3));
         var steps:Number=Math.min(100,available);
         var time:Number=0,samples:int=0,closest:Number=1e30;
         var bearing:Number=Math.atan2(p.Y-cy,p.X-cx),winding:Number=0;
         var speed:Number=Math.sqrt(p.dx*p.dx+p.dy*p.dy);
         if(!(speed>0) || route.length==0)return {hit:false,status:"unknown",score:closest};
         while(time<steps-0.000001)
         {
            speed=Math.sqrt(p.dx*p.dx+p.dy*p.dy);
            var maxTurn:Number=turn/scale;
            var first:Object=route[0];
            // A coarse forecast can cut inside the real arc and falsely report
            // a near hit. Share the exact native integration subdivision.
            var count:int=MSWSmartRoute.motionSamples(speed,maxTurn);
            var dt:Number=Math.min(1/count,steps-time);
            for(var k:int=0;k<count && time<steps-0.000001;k++)
            {
               if(samples++>=256)return {hit:false,status:"unknown",score:closest};
               route[route.length-1]={x:cx+vx*time,y:cy+vy*time};
               while(route.length>1 && MSWSmartRoute.clear(p.loc,p.X,p.Y,route[1].x,route[1].y,2,p))route.shift();
               first=route[0];dt=Math.min(1/count,steps-time);
               MSWSmartRoute.steer(p,first.x,first.y,maxTurn*dt,p.loc,dt,scale);
               var nx:Number=p.X+p.dx*dt,ny:Number=p.Y+p.dy*dt;
               // Bullet.run tests the sampled position, not a swept rectangle.
               // A segment grazing a corner between samples is not a native hit.
               var rx:Number=nx-vx*(time+dt),ry:Number=ny-vy*(time+dt);
               var hit:Boolean=rx>=x1 && rx<=x2 && ry>=y1 && ry<=y2;
               closest=Math.min(closest,MSWSmartRoute.distance(nx,ny,cx+vx*(time+dt),cy+vy*(time+dt)));
               if(!MSWSmartRoute.clear(p.loc,p.X,p.Y,nx,ny,0.5,p))return {hit:false,status:"wall",score:closest+800};
               var nextBearing:Number=Math.atan2(ny-cy-vy*(time+dt),nx-cx-vx*(time+dt));
               // Once on the final approach, circling most of the way around
               // the target is observed failure of this approach, not merely
               // an exhausted forecast. Try tighter radii before flying it.
               // Do not count turns along an intentional multi-corner detour.
               if(route.length==1)winding+=MSWSmartRoute.angle(nextBearing-bearing);
               else winding=0;
               bearing=nextBearing;
               if(Math.abs(winding)>Math.PI*1.5)return {hit:false,status:"orbit",score:closest+400};
               if(hit)return {hit:true,status:"hit",score:0,time:time+dt};
               p.X=nx;p.Y=ny;time+=dt;
            }
            // Motion has already applied acceleration for the current step.
            p.dx+=finite(b.ddx);p.dy+=finite(b.ddy);
         }
         return {hit:false,status:available>100?"unknown":"miss",score:closest};
      }
      public static function intersects(x:Number,y:Number,tx:Number,ty:Number,x1:Number,y1:Number,x2:Number,y2:Number):Boolean
      {
         var lo:Number=0,hi:Number=1,dx:Number=tx-x,dy:Number=ty-y,a:Number,b:Number,t:Number;
         if(Math.abs(dx)<0.0000001){if(x<x1 || x>x2)return false;}
         else
         {
            a=(x1-x)/dx;b=(x2-x)/dx;if(a>b){t=a;a=b;b=t;}
            lo=Math.max(lo,a);hi=Math.min(hi,b);if(lo>hi)return false;
         }
         if(Math.abs(dy)<0.0000001){if(y<y1 || y>y2)return false;}
         else
         {
            a=(y1-y)/dy;b=(y2-y)/dy;if(a>b){t=a;a=b;b=t;}
            lo=Math.max(lo,a);hi=Math.min(hi,b);if(lo>hi)return false;
         }
         return true;
      }
      private static function bound(value:*,fallback:Number):Number
      {var n:Number=Number(value);return isFinite(n)?Math.max(10,Math.min(200,n)):fallback;}
      private static function finite(value:*):Number
      {var n:Number=Number(value);return isFinite(n)?n:0;}
   }
}
