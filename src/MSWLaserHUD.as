package
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   public class MSWLaserHUD extends Sprite
   {
      private var labels:Array=[];
      private var marks:Array=[];
      private var debugStatus:TextField;
      private var lastMessage:String="等待开火";
      private var serial:int=0;
      public function MSWLaserHUD() {mouseEnabled=mouseChildren=false;name="MSWLaserHUD";}
      private function point(w:*,x:Number,y:Number):Point {return globalToLocal(w.visual.localToGlobal(new Point(x,y)));}
      public function clearDebug():void {marks=[];lastMessage="等待开火";serial=0;}
      public function error(message:String):void {lastMessage="开火处理异常："+message;}
      public function report(hit:Object,result:String,seconds:Number,eyeRadius:Number):void
      {
         var text:String,color:uint=0xFFC76A;
         if(result=="blind") {text="眼部命中 · 已失明 "+seconds.toFixed(1)+"s";color=0x85FFAA;}
         else if(result=="body")text="身体命中 · 未经过眼区";
         else if(result=="back")text="眼区命中 · 非正面射入";
         else if(result=="shield")text="眼区命中 · 护盾阻挡";
         else if(result=="ineligible")text="眼区命中 · 目标不受失明影响";
         else {text="未命中单位 · 遮挡或射程终点";color=0xDDDDDD;}
         serial++;lastMessage="#"+serial+" "+text;
         var mark:Object={unit:hit.unit,x:hit.x,y:hit.y,text:text,color:color,until:getTimer()+3000,eye:null,radius:0};
         if(hit.unit!=null) {mark.eye=MSWLaserGeometry.eye(hit.unit);mark.radius=MSWLaserGeometry.radius(hit.unit,eyeRadius);}
         for(var i:int=marks.length-1;i>=0;i--)if(marks[i].unit===hit.unit)marks.splice(i,1);
         marks.push(mark);if(marks.length>8)marks.shift();
      }
      private function label(n:int,text:String,color:uint,x:Number,y:Number):void
      {
         var tf:TextField;
         if(n>=labels.length)
         {tf=new TextField();tf.defaultTextFormat=new TextFormat("SimHei",13);tf.width=290;tf.height=23;tf.selectable=tf.mouseEnabled=false;addChild(tf);labels.push(tf);}
         else tf=labels[n];
         tf.visible=true;tf.text=text;tf.textColor=color;tf.x=x;tf.y=y;
      }
      public function render(w:*,equipped:Boolean,target:*,states:Dictionary,debug:Boolean=false):void
      {
         if(parent!==w.main)w.main.addChild(this);visible=true;graphics.clear();
         for each(var old:TextField in labels)old.visible=false;
         if(debugStatus!=null)debugStatus.visible=false;
         if(!debug)clearDebug();
         if(!equipped)return;
         var a:Point;
         if(target!=null) {var e:Object=MSWLaserGeometry.eye(target);a=point(w,e.x,e.y);graphics.lineStyle(1.5,0x65E8FF,1);graphics.drawCircle(a.x,a.y,7);}
         var n:int=0;
         for each(var s:Object in states)
         {
            if(!s.unit.isVis || s.remaining<=0)continue;
            a=point(w,s.unit.X,s.unit.Y1-20);
            label(n++,"失明 "+(s.remaining/30).toFixed(1)+"s",0x85EEFF,a.x-35,a.y);
         }
         if(!debug)return;
         if(debugStatus==null)
         {
            debugStatus=new TextField();debugStatus.name="MSWLaserDebugStatus";
            debugStatus.defaultTextFormat=new TextFormat("SimHei",14,0xFFFFFF);
            debugStatus.background=true;debugStatus.backgroundColor=0x17202B;
            debugStatus.selectable=debugStatus.mouseEnabled=false;debugStatus.height=25;
            debugStatus.x=12;debugStatus.y=70;addChild(debugStatus);
         }
         debugStatus.width=Math.min(640,stage.stageWidth-24);debugStatus.visible=true;
         debugStatus.text="激光调试｜"+lastMessage;
         for(var i:int=marks.length-1;i>=0;i--)
         {
            var mark:Object=marks[i];if(getTimer()>=mark.until) {marks.splice(i,1);continue;}
            a=point(w,mark.x,mark.y);graphics.lineStyle(2,mark.color,1);
            graphics.moveTo(a.x-5,a.y);graphics.lineTo(a.x+5,a.y);
            graphics.moveTo(a.x,a.y-5);graphics.lineTo(a.x,a.y+5);
            if(mark.eye!=null)
            {
               var ep:Point=point(w,mark.eye.x,mark.eye.y),edge:Point=point(w,mark.eye.x+mark.radius,mark.eye.y);
               graphics.drawCircle(ep.x,ep.y,Point.distance(ep,edge));
            }
            label(n++,mark.text,mark.color,Math.max(8,Math.min(stage.stageWidth-295,a.x+9)),Math.max(98,a.y-45));
         }
      }
   }
}
