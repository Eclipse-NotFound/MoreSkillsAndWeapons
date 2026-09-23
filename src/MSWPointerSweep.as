package
{
   import flash.utils.Dictionary;
   /** Sample actual interpolated aim, including eye crossings between frames.
    * The displayed ray never snaps to a target. Every sample uses first contact. */
   public class MSWPointerSweep
   {
      private var previous:Object;
      public function MSWPointerSweep() {}
      public function reset():void {previous=null;}
      private function capture(w:*,x:Number,y:Number,a:Number):Object
      {
         var poses:Dictionary=new Dictionary(true);
         for each(var u:* in w.loc.units)if(MSWLaserGeometry.live(u,w.loc))
            poses[u]={X1:u.X1,X2:u.X2,Y1:u.Y1,Y2:u.Y2,eye:MSWLaserGeometry.eye(u)};
         return {x:x,y:y,a:a,poses:poses};
      }
      private function between(now:Object,t:Number):Dictionary
      {
         var result:Dictionary=new Dictionary(true);
         for(var u:* in now.poses)
         {
            var b:Object=now.poses[u],p:Object=previous.poses[u];
            if(p==null) {result[u]=b;continue;}
            result[u]={X1:p.X1+(b.X1-p.X1)*t,X2:p.X2+(b.X2-p.X2)*t,
               Y1:p.Y1+(b.Y1-p.Y1)*t,Y2:p.Y2+(b.Y2-p.Y2)*t,
               eye:{x:p.eye.x+(b.eye.x-p.eye.x)*t,y:p.eye.y+(b.eye.y-p.eye.y)*t}};
         }
         return result;
      }
      private function offset(now:Object,u:*,turn:Number,t:Number):Number
      {
         var b:Object=now.poses[u],p:Object=previous.poses[u];
         var x:Number=previous.x+(now.x-previous.x)*t,y:Number=previous.y+(now.y-previous.y)*t;
         return MSWLaserGeometry.angle(Math.atan2(p.eye.y+(b.eye.y-p.eye.y)*t-y,p.eye.x+(b.eye.x-p.eye.x)*t-x)-previous.a-turn*t);
      }
      public function scan(w:*,x:Number,y:Number,a:Number,r:Number,contact:Function):Object
      {
         var now:Object=capture(w,x,y,a),hit:Object=MSWLaserGeometry.castRay(w,x,y,a,r,2000,w.gg);
         contact(hit);
         if(previous!=null)
         {
            var turn:Number=MSWLaserGeometry.angle(a-previous.a),times:Array=[];
            // Coarse samples cover grazing contacts; roots capture tiny eye
            // regions even during a large but continuous mouse sweep.
            for(var j:int=1;j<8;j++)times.push(j/8);
            for(var u:* in now.poses)
            {
               if(previous.poses[u]==null || !MSWLaserGeometry.hostile(u,w))continue;
               var lo:Number=0,hi:Number=1,ol:Number=offset(now,u,turn,0),oh:Number=offset(now,u,turn,1);
               if(ol*oh>0 || Math.abs(oh-ol)>Math.PI)continue;
               for(j=0;j<14;j++)
               {
                  var mid:Number=(lo+hi)/2,om:Number=offset(now,u,turn,mid);
                  if(ol*om<=0)hi=mid;else {lo=mid;ol=om;}
               }
               times.push((lo+hi)/2);
            }
            for each(var t:Number in times)
            {
               var sample:Object=MSWLaserGeometry.castRay(w,previous.x+(x-previous.x)*t,previous.y+(y-previous.y)*t,
                  previous.a+turn*t,r,2000,w.gg,false,between(now,t));
               contact(sample);
            }
         }
         previous=now;return hit;
      }
   }
}
