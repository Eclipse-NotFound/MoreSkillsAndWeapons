package
{
   import flash.utils.Dictionary;

   /** Curved integration on the SAME native Bullet: run() owns every collision.
    * The following native step still owns age, explosions and removal. */
   public class MSWSmartMotion
   {
      private var pending:Array=[];
      private var trails:Dictionary=new Dictionary();
      public function MSWSmartMotion() {}

      public function advance(b:*,s:Object,path:Array,maxTurn:Number):void
      {
         b.dx+=b.ddx; b.dy+=b.ddy;
         var speed:Number=Math.sqrt(b.dx*b.dx+b.dy*b.dy);
         if(!(speed>0) || !isFinite(speed)) return;
         var radiusScale:Number=s.turnRadius==null?1:Number(s.turnRadius)/100;
         radiusScale=isFinite(radiusScale)?Math.max(0.1,Math.min(2,radiusScale)):1;
         if(s.adaptive==true)radiusScale=MSWAdaptiveRadius.select(b,s,path,maxTurn);
         maxTurn/=radiusScale;
         // At most six pixels / three degrees per native collision sample.
         var count:int=MSWSmartRoute.motionSamples(speed,maxTurn);
         var points:Array=[{x:b.X,y:b.Y}];
         s.motionPath=points;
         for(var i:int=0;i<count && !b.babah && b.in_chain;i++)
         {
            while(path.length>1 && MSWSmartRoute.clear(b.loc,b.X,b.Y,path[1].x,path[1].y,2,b)) path.shift();
            var p:Object=path[0];
            MSWSmartRoute.steer(b,p.x,p.y,maxTurn/count,b.loc,1/count,radiusScale);
            b.run(count);
            points.push({x:b.X,y:b.Y});
         }
         // Skip only the native step's already-completed motion block. Restore
         // at chain end, before frame observers (ricochet / time-stop) see it.
         if(!b.babah && b.in_chain) { b.babah=true; pending.push(b); }
         if(b.vis!=null && b.spring==1)
         {
            var trail:MSWSmartTrail=trails[b];
            if(trail==null){trail=new MSWSmartTrail(b);trails[b]=trail;}
            trail.append(points,b);
         }
      }

      public function finish():void
      {
         for each(var b:* in pending) if(b.liv>0 && !b.isExpl) b.babah=false;
         pending=[];
         for(var key:* in trails)
         {
            b=key;
            if(!b.in_chain || b.babah || b.vis==null || b.vis.parent==null) { remove(b); continue; }
            MSWSmartTrail(trails[b]).render(b);
         }
      }

      public function remove(b:*):void
      {
         var t:MSWSmartTrail=trails[b];
         if(t!=null)t.release();
         delete trails[b];
      }
      public function prune():void
      {
         for(var b:* in trails) if(!b.in_chain || b.babah || b.vis==null || b.vis.parent==null) remove(b);
      }
      public function clear():void
      { finish();for(var b:* in trails)remove(b); }
   }
}
