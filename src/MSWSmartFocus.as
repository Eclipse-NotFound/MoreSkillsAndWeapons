package
{
   /** Selects a completed lock without consuming the multi-lock rotation. */
   public class MSWSmartFocus
   {
      public var target:*=null;
      private var waitForMove:Boolean=false;
      public function MSWSmartFocus() {}

      public function clear():void { target=null;waitForMove=false; }

      private function observeDeath():void
      {
         if(target!=null && (MSWU.num(target,"hp")<=0 || MSWU.num(target,"sost")>=3))
         { target=null;waitForMove=true; }
      }

      /** Called only for real cursor movement during active play, not camera motion. */
      public function aimMoved():void
      { observeDeath();waitForMove=false; }

      public function select(locks:Array,x:Number,y:Number,radius:Number,valid:Function):MSWSmartLock
      {
         observeDeath();
         if(waitForMove)return null;
         var best:MSWSmartLock=null,edge:Number=Number.POSITIVE_INFINITY,center:Number=Number.POSITIVE_INFINITY;
         for each(var state:MSWSmartLock in locks)
         {
            var u:*=state.target;
            if(u==null || state.strength<=0 || !valid(u))continue;
            var dx:Number=Math.max(u.X1-x,0,x-u.X2),dy:Number=Math.max(u.Y1-y,0,y-u.Y2);
            var distance:Number=dx*dx+dy*dy;
            if(distance>radius*radius)continue;
            dx=(u.X1+u.X2)/2-x;dy=(u.Y1+u.Y2)/2-y;
            var middle:Number=dx*dx+dy*dy;
            // Inside a body has distance zero. Center distance resolves overlapping bodies.
            if(distance<edge || distance==edge && (middle<center || middle==center && u===target))
            { best=state;edge=distance;center=middle; }
         }
         target=best==null?null:best.target;
         return best;
      }
   }
}
