package
{
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;

   /** Bend the native flight artwork along a bounded history of actual positions.
    * Rendering only: no collision, target or projectile state is simulated here. */
   public class MSWSmartTrail extends Sprite
   {
      private static var textures:Dictionary=new Dictionary();
      private var track:Array=[];
      private var art:Object;
      private var original:DisplayObject;
      private var nativeScale:Number=1;
      public var dirty:Boolean=false;

      public function MSWSmartTrail(b:*)
      {
         name="MSWSmartTrail";mouseEnabled=false;mouseChildren=false;
         original=b.vis;art=texture(original);
      }
      private static function texture(visual:DisplayObject):Object
      {
         var type:Class=Object(visual).constructor as Class;
         if(type==null)return null;
         if(textures[type]!=null)return textures[type];
         // A fresh frame preserves the original symbol's palette, including
         // alicorn rainbow rounds, without capturing flight/impact transforms.
         var source:DisplayObject=new type();
         if(source is MovieClip)MovieClip(source).gotoAndStop(1);
         var bounds:Rectangle=source.getBounds(source);
         if(bounds.isEmpty() || bounds.width>2048 || bounds.height>256)return null;
         var left:Number=Math.floor(bounds.left)-1,top:Number=Math.floor(bounds.top)-1;
         var width:int=Math.ceil(bounds.right)-left+1,height:int=Math.ceil(bounds.bottom)-top+1;
         var bitmap:BitmapData=new BitmapData(width,height,true,0);
         bitmap.draw(source,new Matrix(1,0,0,1,-left,-top),null,null,null,true);
         var result:Object={bitmap:bitmap,left:left,top:top,width:width,height:height};
         textures[type]=result;return result;
      }
      public function append(points:Array,b:*):void
      {
         for each(var p:Object in points)
         {
            if(track.length==0){track.push({x:p.x,y:p.y,d:0});continue;}
            var last:Object=track[track.length-1];
            var dx:Number=p.x-last.x,dy:Number=p.y-last.y,length:Number=Math.sqrt(dx*dx+dy*dy);
            if(length<0.000001)continue;
            var next:Object={x:p.x,y:p.y,d:last.d+length};
            // Subpixel samples retain their arc length but do not grow an
            // unbounded history when time-stop makes motion extremely slow.
            if(track.length>2 && next.d-track[track.length-2].d<0.5)track[track.length-1]=next;
            else track.push(next);
         }
         if(art!=null && track.length>2)
         {
            var tail:Number=track[track.length-1].d+art.left*Math.max(1,b.vel/100)-2;
            var drop:int=0;
            while(drop<track.length-2 && track[drop+1].d<tail)drop++;
            if(drop>0)track.splice(0,drop);
         }
         dirty=true;
      }
      private function at(distance:Number):Object
      {
         var low:int=0,high:int=track.length-1;
         while(high-low>1){var mid:int=(low+high)>>1;if(track[mid].d>distance)high=mid;else low=mid;}
         var a:Object=track[low],b:Object=track[high],span:Number=b.d-a.d;
         var f:Number=(distance-a.d)/span,dx:Number=b.x-a.x,dy:Number=b.y-a.y;
         var length:Number=Math.sqrt(dx*dx+dy*dy);
         return {x:a.x+dx*f,y:a.y+dy*f,nx:-dy/length,ny:dx/length};
      }
      public function render(b:*):void
      {
         if(!dirty)return;
         dirty=false;
         if(art==null || track.length<2)return;
         if(parent!==original.parent)original.parent.addChildAt(this,original.parent.getChildIndex(original));
         var scale:Number=Math.max(1,b.vel/100),heightScale:Number=original.scaleY;
         var count:int=Math.min(512,Math.max(1,Math.ceil(art.width*scale/2)));
         var vertices:Vector.<Number>=new Vector.<Number>(),uv:Vector.<Number>=new Vector.<Number>(),indices:Vector.<int>=new Vector.<int>();
         var end:Number=track[track.length-1].d;
         for(var i:int=0;i<=count;i++)
         {
            var u:Number=i/count,p:Object=at(end+(art.left+art.width*u)*scale);
            var top:Number=art.top*heightScale,bottom:Number=(art.top+art.height)*heightScale;
            vertices.push(p.x+p.nx*top,p.y+p.ny*top,p.x+p.nx*bottom,p.y+p.ny*bottom);
            // drawTriangles uses size-1 as the UV span. Preserve native pixel
            // spacing; a 0..1 mapping broadens the narrow core by one texel.
            var tx:Number=u*art.width/(art.width-1);
            uv.push(tx,0,tx,art.height/(art.height-1));
            if(i<count){var j:int=i*2;indices.push(j,j+1,j+2,j+1,j+3,j+2);}
         }
         graphics.clear();graphics.beginBitmapFill(art.bitmap,null,false,true);
         graphics.drawTriangles(vertices,indices,uv);graphics.endFill();
         transform.colorTransform=original.transform.colorTransform;blendMode=original.blendMode;
         visible=original.visible;nativeScale=scale;original.scaleX=0;
         // Before enough history exists, at() extrapolates the initial tangent.
         // This matches the native full-length trail at the muzzle; later frames
         // use only the travelled curve, never a straight chord across a corner.
      }
      public function release():void
      {
         if(parent!=null)parent.removeChild(this);
         // Keep the native visibility flag available to time-stop recorders.
         // If impact already changed the scale, retain its native animation.
         if(art!=null && original!=null && original.scaleX==0)original.scaleX=nativeScale;
         track=[];graphics.clear();
      }
   }
}
