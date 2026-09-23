package
{
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.display.StageAlign;
   import flash.display.StageScaleMode;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;

   /** Executes the production renderer and samples its actual raster output. */
   public class SmartHudRenderTest extends Sprite
   {
      private var scene:Sprite=new Sprite(), world:Sprite=new Sprite(), hud:MSWSmartHUD=new MSWSmartHUD();
      private var lock:MSWSmartLock=new MSWSmartLock(), w:Object;
      private var unit:Object={X1:80,X2:120,Y1:80,Y2:120,storona:1};
      private var log:String="", checks:int=0;
      private var size:Number=40;
      public function SmartHudRenderTest() { addEventListener(Event.ADDED_TO_STAGE,run); }
      private function ok(value:Boolean,message:String):void
      { if(!value)throw new Error(message);checks++;log+="PASS "+message+"\n"; }
      private function raster():BitmapData
      { hud.render(w,lock,size);var b:BitmapData=new BitmapData(800,500,true,0);b.draw(stage);return b; }
      private function color(b:BitmapData,x:int,y:int,blue:Boolean):Boolean
      { var c:uint=b.getPixel(x,y);return blue?((c&255)>150 && ((c>>16)&255)<140):(((c>>16)&255)>150 && (c&255)<140); }
      private function boundsOf(b:BitmapData,isBlue:Boolean):Rectangle
      {
         var minX:int=b.width,minY:int=b.height,maxX:int=-1,maxY:int=-1;
         for(var y:int=0;y<b.height;y++)for(var x:int=0;x<b.width;x++)
            if((b.getPixel32(x,y)>>>24)>100 && color(b,x,y,isBlue))
            {minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}
         return maxX<0?new Rectangle():new Rectangle(minX,minY,maxX-minX+1,maxY-minY+1);
      }
      private function blue(b:BitmapData):Rectangle { return boundsOf(b,true); }
      private function run(e:Event):void
      {
         try
         {
            stage.scaleMode=StageScaleMode.NO_SCALE;stage.align=StageAlign.TOP_LEFT;
            addChild(scene);scene.addChild(world);w={main:scene,visual:world};
            lock.candidate=unit;lock.progress=0.25;
            var b:BitmapData=raster();
            ok(color(b,96,86,true),"quarter: top-left edge blue");
            ok(color(b,96,106,false) && color(b,116,106,false) && color(b,116,86,false),"quarter: remaining three edges red");
            ok(b.getPixel32(106,96)==0,"diamond center is hollow");b.dispose();
            lock.progress=0.5;b=raster();ok(color(b,96,106,true) && color(b,116,106,false),"half: counterclockwise left half blue");b.dispose();
            lock.progress=0.75;b=raster();ok(color(b,116,106,true) && color(b,116,86,false),"three quarters: bottom-right blue, top-right red");b.dispose();
            lock.progress=0.125;b=raster();ok(color(b,101,81,true) && color(b,91,91,false),"fractional edge stops between vertices");b.dispose();
            lock.target=unit;lock.candidate=null;lock.strength=1;b=raster();
            savePNG(b,"full-lock.png");
            ok(boundsOf(b,false).isEmpty(),"full lock has no red pixels");b.dispose();
            lock.strength=0.75;b=raster();ok(color(b,116,86,false) && color(b,116,106,true),"loss retracts from the same blue endpoint");b.dispose();
            lock.strength=1;
            scene.x=scene.y=100; // Keep the largest marker inside the bitmap at 0.5x.
            for each(var scale:Number in [0.5,1,1.5,2])
            {
               scene.scaleX=scale;scene.scaleY=scale;world.scaleX=1.25;world.scaleY=0.8;
               for each(size in [12,24,40,80])
               {
                  b=raster();var bounds:Rectangle=blue(b);
                  ok(bounds.width>=size-2 && bounds.width<=size+3 && bounds.height>=size-2 && bounds.height<=size+3,size+" screen px at parent scale "+scale);b.dispose();
               }
            }
            size=40;
            scene.x=scene.y=0;
            scene.scaleX=scene.scaleY=world.scaleX=world.scaleY=1;
            unit.storona=-1;b=raster();bounds=blue(b);ok(Math.abs(bounds.x+bounds.width/2-94)<2,"chest anchor mirrors when facing left");b.dispose();
            unit.X1+=70;unit.X2+=70;b=raster();bounds=blue(b);ok(Math.abs(bounds.x+bounds.width/2-164)<2,"marker follows target movement");b.dispose();
            lock.candidate={X1:280,X2:320,Y1:80,Y2:120,storona:1,isVis:false};lock.progress=0.5;
            b=raster();ok(color(b,296,86,true) && color(b,316,86,false),"occluded candidate still renders beside old lock");
            ok(color(b,154,86,true),"old target remains visible while acquiring replacement");b.dispose();
            lock.clear();b=raster();ok(!hud.visible && blue(b).isEmpty() && boundsOf(b,false).isEmpty(),"zero/clear removes both markers immediately");b.dispose();
            ok(hud.numChildren==0 && !hud.mouseEnabled && !hud.mouseChildren,"no old text, no mouse interception");
            // Contact sheet uses the production vectors, with captions outside the HUD.
            scene.removeChildren();scene.addChild(world);world.scaleX=world.scaleY=1;
            var values:Array=[0.01,0.25,0.5,0.75,1,0.75,0.5,0.25];
            for(var i:int=0;i<values.length;i++)
            {
               var l:MSWSmartLock=new MSWSmartLock();var marker:MSWSmartHUD=new MSWSmartHUD();
               var x:Number=90+(i%4)*180,y:Number=i<4?110:280;
               l.target={X1:x-26,X2:x+14,Y1:y-16,Y2:y+24,storona:1};l.strength=values[i];marker.render(w,l);
               var t:TextField=new TextField();t.defaultTextFormat=new TextFormat("Arial",16,0xCDD5E0);t.width=175;t.x=x-50;t.y=y+40;
               t.text=(i<4?"Acquire ":"Lock / loss ")+Math.round(values[i]*100)+"%";scene.addChild(t);
            }
            b=new BitmapData(800,400,false,0x18212C);b.draw(stage);savePNG(b,"preview.png");b.dispose();
            finish("PASS smart HUD raster: "+checks+" checks",0);
         }
         catch(err:*) {finish("FAIL "+err+"\n"+err.getStackTrace(),1);}
      }
      private function savePNG(b:BitmapData,name:String):void
      {
         var enc:Class=MSWU.cls("flash.display.PNGEncoderOptions");var bytes:*=Object(b)["encode"](b.rect,new enc());
         var S:Class=MSWU.cls("flash.filesystem.FileStream"),f:*=new S();f.open(MSWU.cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");f.writeBytes(bytes);f.close();
      }
      private function finish(s:String,code:int):void
      {
         var S:Class=MSWU.cls("flash.filesystem.FileStream"),f:*=new S();f.open(MSWU.cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath("results.txt"),"write");f.writeUTFBytes(log+s+"\n");f.close();
         MSWU.cls("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
