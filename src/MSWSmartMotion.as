package
{
   import flash.display.Sprite;
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
         maxTurn/=radiusScale;
         // At most six pixels / three degrees per native collision sample.
         var count:int=Math.min(256,Math.max(1,Math.ceil(speed/6),Math.ceil(maxTurn/(Math.PI/60))));
         var points:Array=[{x:b.X,y:b.Y}];
         s.motionPath=points;
         var smooth:Boolean=s.smooth==true && Number(s.smoothing)>0;
         for(var i:int=0;i<count && !b.babah && b.in_chain;i++)
         {
            while(path.length>1 && MSWSmartRoute.clear(b.loc,b.X,b.Y,path[1].x,path[1].y,2,b)) path.shift();
            var p:Object=path[0];
            if(smooth) MSWSmartSmooth.steer(b,s,path,maxTurn/count,1/count,radiusScale,i%4==0);
            else MSWSmartRoute.steer(b,p.x,p.y,maxTurn/count,b.loc,1/count,radiusScale);
            b.run(count);
            points.push({x:b.X,y:b.Y});
         }
         // Skip only the native step's already-completed motion block. Restore
         // at chain end, before frame observers (ricochet / time-stop) see it.
         if(!b.babah && b.in_chain) { b.babah=true; pending.push(b); }
         if(b.vis!=null && b.spring==1)
         {
            var old:Object=trails[b];
            trails[b]={points:points,sprite:old==null?null:old.sprite,dirty:true};
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
            var t:Object=trails[b];
            if(!t.dirty) continue;
            var line:Sprite=t.sprite;
            if(line==null)
            {
               line=new Sprite();line.name="MSWSmartTrail";line.mouseEnabled=false;line.mouseChildren=false;t.sprite=line;
            }
            if(line.parent!==b.vis.parent) b.vis.parent.addChildAt(line,b.vis.parent.getChildIndex(b.vis));
            line.graphics.clear();
            line.graphics.lineStyle(2,0xFFDE91,0.7,false,"normal","round","round");
            var points:Array=t.points;
            line.graphics.moveTo(points[0].x,points[0].y);
            for(var i:int=1;i<points.length;i++)line.graphics.lineTo(points[i].x,points[i].y);
            // Native visualBullet stretches a straight 100px strip. Keep its
            // small head; draw the actual curved travelled path behind it.
            b.vis.scaleX=0.04;
            t.dirty=false;
         }
      }

      public function remove(b:*):void
      {
         var t:Object=trails[b];
         if(t!=null && t.sprite!=null && t.sprite.parent!=null) t.sprite.parent.removeChild(t.sprite);
         delete trails[b];
         if(b.vis!=null && b.spring==1) b.vis.scaleX=b.babah?1:Math.max(1,b.vel/100);
      }
      public function prune():void
      {
         for(var b:* in trails) if(!b.in_chain || b.babah || b.vis==null || b.vis.parent==null) remove(b);
      }
      public function clear():void
      { finish();for(var b:* in trails)remove(b); }
   }
}
