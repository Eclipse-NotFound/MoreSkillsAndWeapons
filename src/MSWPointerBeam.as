package
{
   import flash.display.Sprite;
   /** One persistent world-layer graphic; no game-time fade or attack object. */
   public class MSWPointerBeam extends Sprite
   {
      public function MSWPointerBeam() {name="MSWPointerBeam";mouseEnabled=mouseChildren=false;}
      public function draw(w:*,x:Number,y:Number,hit:Object):void
      {
         var layer:*=w.grafon.visObjs[2];if(parent!==layer)layer.addChild(this);
         visible=true;graphics.clear();
         graphics.lineStyle(3,0xF84351,0.25);graphics.moveTo(x,y);graphics.lineTo(hit.x,hit.y);
         graphics.lineStyle(1,0xFFBAC1,0.95);graphics.moveTo(x,y);graphics.lineTo(hit.x,hit.y);
         graphics.lineStyle();graphics.beginFill(0xFF414E,0.3);graphics.drawCircle(hit.x,hit.y,4);graphics.endFill();
         graphics.beginFill(0xFFF1F1,1);graphics.drawCircle(hit.x,hit.y,1.6);graphics.endFill();
      }
      public function dispose():void {graphics.clear();if(parent!=null)parent.removeChild(this);}
   }
}
