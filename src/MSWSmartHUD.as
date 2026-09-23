package
{
   import flash.display.CapsStyle;
   import flash.display.JointStyle;
   import flash.display.LineScaleMode;
   import flash.display.Sprite;
   import flash.geom.Point;

   /** Screen-sized lock markers. Lock state owns timing, visibility and expiry. */
   public class MSWSmartHUD extends Sprite
   {
      public static const VERSION:String="2-adjustable-size";
      private static const RED:uint=0xFF4040;
      private static const BLUE:uint=0x40A8FF;

      public function MSWSmartHUD()
      {
         name="MSWSmartHUD";
         mouseEnabled=false;
         mouseChildren=false;
      }

      public function render(w:*,lock:MSWSmartLock,size:Number=24):void
      {
         if(parent!==w.main) w.main.addChild(this);
         graphics.clear();
         visible=lock.target!=null || lock.candidate!=null;
         var radius:Number=(isFinite(size)?Math.max(12,Math.min(80,size)):24)/2;
         if(lock.target!=null) marker(w,lock.target,lock.strength,radius);
         if(lock.candidate!=null && lock.candidate!==lock.target)
            marker(w,lock.candidate,lock.progress,radius);
      }

      private function marker(w:*,u:*,progress:Number,radius:Number):void
      {
         if(progress<=0 || isNaN(progress)) return;
         progress=Math.min(1,progress);
         var facing:Number=MSWU.num(u,"storona")<0?-1:1;
         var center:Point=w.visual.localToGlobal(new Point(
            (u.X1+u.X2)/2+(u.X2-u.X1)*0.15*facing,
            u.Y1+(u.Y2-u.Y1)*0.4));
         // Build in stage coordinates before converting to our parent: camera
         // zoom and parent transforms must not stretch the configured diamond.
         var vertices:Array=[
            globalToLocal(new Point(center.x,center.y-radius)),
            globalToLocal(new Point(center.x-radius,center.y)),
            globalToLocal(new Point(center.x,center.y+radius)),
            globalToLocal(new Point(center.x+radius,center.y))];
         if(progress<1) outline(vertices,RED,4);
         outline(vertices,BLUE,progress*4);
      }

      private function outline(vertices:Array,color:uint,edges:Number):void
      {
         graphics.lineStyle(2,color,1,false,LineScaleMode.NONE,CapsStyle.NONE,JointStyle.MITER);
         graphics.moveTo(vertices[0].x,vertices[0].y);
         for(var i:int=0;i<4 && edges>0;i++)
         {
            var a:Point=vertices[i], b:Point=vertices[(i+1)%4];
            var part:Number=Math.min(1,edges);
            graphics.lineTo(a.x+(b.x-a.x)*part,a.y+(b.y-a.y)*part);
            edges-=part;
         }
      }
   }
}
