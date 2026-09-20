package
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   public class MSWLaserHUD extends Sprite
   {
      private var labels:Array=[];
      public function MSWLaserHUD() {mouseEnabled=mouseChildren=false;name="MSWLaserHUD";}
      private function point(w:*,x:Number,y:Number):Point {return globalToLocal(w.visual.localToGlobal(new Point(x,y)));}
      public function render(w:*,equipped:Boolean,target:*,states:Dictionary,flashes:Array):void
      {
         if(parent!==w.main)w.main.addChild(this);visible=true;graphics.clear();
         for each(var old:TextField in labels)old.visible=false;
         for each(var shot:Object in flashes)
         {
            var a:Point=point(w,shot.x,shot.y),b:Point=point(w,shot.tx,shot.ty);
            graphics.lineStyle(3,0x65E8FF,0.65);graphics.moveTo(a.x,a.y);graphics.lineTo(b.x,b.y);
            graphics.lineStyle(1,0xFFFFFF,1);graphics.moveTo(a.x,a.y);graphics.lineTo(b.x,b.y);
            if(shot.hit) {graphics.drawCircle(b.x,b.y,9);graphics.drawCircle(b.x,b.y,3);}
         }
         if(!equipped)return;
         if(target!=null) {a=point(w,target.eyeX,target.eyeY);graphics.lineStyle(1.5,0x65E8FF,1);graphics.drawCircle(a.x,a.y,7);}
         var n:int=0;
         for each(var s:Object in states)
         {
            if(!s.unit.isVis || s.remaining<=0)continue;
            a=point(w,s.unit.X,s.unit.Y1-20);
            var tf:TextField;
            if(n>=labels.length)
            {tf=new TextField();tf.defaultTextFormat=new TextFormat("SimHei",13,0x85EEFF);tf.width=120;tf.height=22;tf.selectable=tf.mouseEnabled=false;addChild(tf);labels.push(tf);}
            else tf=labels[n];
            tf.visible=true;tf.text="失明 "+(s.remaining/30).toFixed(1)+"s";tf.x=a.x-35;tf.y=a.y;n++;
         }
      }
   }
}
