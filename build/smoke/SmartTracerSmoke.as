package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;

   /** TEST ONLY: pixel comparison of the real native Bullet and production motion. */
   public class SmartTracerSmoke extends Sprite
   {
      private static var probe:SmartTracerSmoke;
      private var loader:Loader=new Loader(),timer:Timer=new Timer(50),domain:ApplicationDomain;
      private var w:*,m:*,weapon:*,ticks:int=0,log:String="",failures:int=0;
      private var sheet:BitmapData=new BitmapData(1100,700,false,0x18202B);
      public function SmartTracerSmoke() {}
      public static function init(main:*):void {probe=new SmartTracerSmoke();probe.start(main);}
      private function cls(name:String):Class {return domain.getDefinition(name) as Class;}
      private function start(main:*):void
      {
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void {
            try {domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](main);timer.addEventListener("timer",tick);timer.start();}
            catch(err:*) {finish(false,String(err)+"\n"+err.getStackTrace());}
         });
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void {finish(false,e.text);});
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function check(value:Boolean,message:String):void
      {log+=(value?"PASS ":"FAIL ")+message+"\n";if(!value)failures++;}
      private function tick(e:Event):void
      {
         try {
            ticks++;if(ticks>1400)throw new Error("timeout");
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(w!=null && w.verror.visible)throw new Error(w.verror.txt.text);
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active || ticks<160)return;
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;
            m.cfg.smartEnabled=false;w.loc.units=[w.gg];w.loc.objs=[];
            for(var x:int=160;x<1300;x+=20)for(var y:int=40;y<650;y+=20){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null){tile.phis=0;tile.water=0;}}
            weapon=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");
            label("Native tracer (left) / smart tracer (right); same projectile, speed and scale",15,8);
            var row:int=0;
            for each(var speed:Number in [5,20,60,100,160])
            {
               var native:Object=sample(speed,false,row),smart:Object=sample(speed,true,row);
               var energy:Number=smart.energy/native.energy,length:Number=smart.width/native.width;
               log+="MEASURE speed="+speed+" native="+JSON.stringify(native)+" smart="+JSON.stringify(smart)+" energyRatio="+energy+" lengthRatio="+length+"\n";
               check(energy>=0.9 && energy<=1.1,"speed="+speed+" smart visible light matches native within 10%");
               check(Math.abs(smart.width-native.width)<=3,"speed="+speed+" smart visible length matches native within 3px");
               check(profileError(native,smart)<0.12,"speed="+speed+" native gradient and palette retained");
               label("speed="+speed+" light="+energy.toFixed(2)+" length="+length.toFixed(2),15,60+row*100);row++;
            }
            native=sample(20,false,5,"visualRainbow");smart=sample(20,true,5,"visualRainbow");
            log+="RAINBOW native="+JSON.stringify(native)+" smart="+JSON.stringify(smart)+"\n";
            check(profileError(native,smart)<0.12 && Math.abs(smart.energy/native.energy-1)<0.1,"native rainbow palette and brightness retained");
            label("Rainbow rounds",15,560);
            controls();curve();
            png("tracers.png",sheet);finish(failures==0,"");
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function sample(speed:Number,smart:Boolean,row:int,visual:String="visualBullet"):Object
      {
         var b:*=new (cls("fe.weapon.Bullet"))(w.gg,500,300,cls(visual),true);
         b.weap=weapon;b.dx=speed;b.dy=0;b.vel=speed;b.damage=1;b.precision=0;b.miss=0;
         var holder:Sprite=new Sprite();holder.addChild(b.vis);
         var motion:*=new (cls("MSWSmartMotion"))(),shot:Object={turnRadius:100,adaptive:false};
         if(smart)motion.advance(b,shot,[{x:1100,y:300}],Math.PI/5);
         b.step();if(smart)motion.finish();
         check(!b.babah && Math.abs(b.X-500-speed)<0.001,"native movement intact speed="+speed+" smart="+smart);
         check(b.liv==99 && Math.abs(b.dist-speed)<0.001,"native age and distance unchanged speed="+speed+" smart="+smart);
         var bitmap:BitmapData=new BitmapData(320,60,true,0),matrix:Matrix=new Matrix(1,0,0,1,280-b.X,30-b.Y);
         bitmap.draw(holder,matrix);
         var result:Object=measure(bitmap);
         sheet.draw(bitmap,new Matrix(1,0,0,1,smart?700:340,45+row*100));
         bitmap.dispose();motion.clear();w.loc.remObj(b);
         return result;
      }
      private function measure(bitmap:BitmapData):Object
      {
         var energy:Number=0,bright:int=0,peak:Number=0,minX:int=320,maxX:int=-1;
         for(var x:int=0;x<bitmap.width;x++)for(var y:int=0;y<bitmap.height;y++)
         {
            var c:uint=bitmap.getPixel32(x,y),a:Number=(c>>>24)/255;
            var light:Number=a*(0.2126*((c>>16)&255)+0.7152*((c>>8)&255)+0.0722*(c&255));
            energy+=light;peak=Math.max(peak,light);
            if(light>4){minX=Math.min(minX,x);maxX=Math.max(maxX,x);}if(light>80)bright++;
         }
         var c1:uint=bitmap.getPixel32(270,30),c2:uint=bitmap.getPixel32(240,30),c3:uint=bitmap.getPixel32(210,30);
         return {energy:energy,width:maxX-minX+1,peak:peak,brightPixels:bright,profile:[c1.toString(16),c2.toString(16),c3.toString(16)]};
      }
      private function profileError(a:Object,b:Object):Number
      {
         var error:Number=0;
         for(var i:int=0;i<a.profile.length;i++)
         {
            var ac:uint=parseInt(a.profile[i],16),bc:uint=parseInt(b.profile[i],16);
            for(var shift:int=0;shift<=24;shift+=8)error=Math.max(error,Math.abs(((ac>>>shift)&255)-((bc>>>shift)&255))/255);
         }
         return error;
      }
      private function controls():void
      {
         var b:*=new (cls("fe.weapon.Bullet"))(w.gg,300,300,cls("visualBullet"),true);
         b.weap=weapon;b.dx=5;b.dy=0;b.vel=5;b.damage=1;b.precision=0;b.miss=0;
         var holder:Sprite=new Sprite();holder.addChild(b.vis);
         var motion:*=new (cls("MSWSmartMotion"))(),shot:Object={turnRadius:100,adaptive:false};
         var missing:int=0,minWidth:int=1000,maxWidth:int=0,before:Object,after:Object;
         for(var i:int=0;i<60;i++)
         {
            motion.advance(b,shot,[{x:1100,y:300}],Math.PI/5);b.step();motion.finish();
            var line:*=holder.getChildByName("MSWSmartTrail");if(line==null)missing++;
            before=capture(holder,b);motion.finish();motion.prune();after=capture(holder,b);
            if(after.energy!=before.energy || after.width!=before.width)missing++;
            minWidth=Math.min(minWidth,before.width);maxWidth=Math.max(maxWidth,before.width);
         }
         log+="CONTROL 60 native physics steps; 300px travelled; missingOrChangedOnFinish="+missing+" minWidth="+minWidth+" maxWidth="+maxWidth+"\n";
         check(missing==0,"tracer survives every physics step and repeated finish/prune without flicker");
         check(minWidth>=85 && maxWidth<=91,"full native length retained across slow steps");
         motion.remove(b);check(holder.getChildByName("MSWSmartTrail")==null && b.vis.visible,"stopping guidance restores original visual and clears curved trail");
         b.step();check(Math.abs(capture(holder,b).energy-27660.30)<10,"ordinary native tracer resumes after guidance");
         motion.advance(b,shot,[{x:1100,y:300}],Math.PI/5);b.step();motion.finish();
         w.loc.remObj(b);motion.prune();check(holder.getChildByName("MSWSmartTrail")==null,"native removal cleans smart tracer");motion.clear();
      }
      private function curve():void
      {
         var b:*=new (cls("fe.weapon.Bullet"))(w.gg,420,420,cls("visualBullet"),true);
         b.weap=weapon;b.dx=20;b.dy=0;b.vel=20;b.damage=1;b.precision=0;b.miss=0;
         var holder:Sprite=new Sprite();holder.addChild(b.vis);
         var motion:*=new (cls("MSWSmartMotion"))(),shot:Object={turnRadius:30,adaptive:false},history:Array=[];
         for(var i:int=0;i<7;i++)
         {
            motion.advance(b,shot,[{x:460,y:140}],Math.PI/3);history=history.concat(shot.motionPath);b.step();motion.finish();
         }
         check(!b.babah && Math.abs(b.dist-140)<0.001 && b.liv==93,"curved tracer preserves native flight distance and age");
         var bitmap:BitmapData=new BitmapData(1100,650,true,0);bitmap.draw(holder);
         var distance:Number=0,tested:int=0,found:int=0;
         for(i=history.length-2;i>=0;i--)
         {
            var p:Object=history[i],q:Object=history[i+1];distance+=Math.sqrt((p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y));
            if(distance<25 || distance>75)continue;
            tested++;var visible:Boolean=false;
            for(var x:int=int(p.x)-2;x<=int(p.x)+2;x++)for(var y:int=int(p.y)-2;y<=int(p.y)+2;y++)if((bitmap.getPixel32(x,y)>>>24)>20)visible=true;
            if(visible)found++;
         }
         log+="CURVE old-path visible="+found+"/"+tested+"\n";
         check(tested>8 && found==tested,"tracer follows earlier curved flight beyond the current 20px step");
         var bg:BitmapData=new BitmapData(1100,650,false,0x18202B);bg.draw(bitmap);png("curved-tracer.png",bg);bg.dispose();bitmap.dispose();
         // Impact must show the native impact frame instead of retaining a ribbon.
         b.babah=true;b.vis.gotoAndStop(2);b.step();motion.prune();
         check(holder.getChildByName("MSWSmartTrail")==null && b.vis.visible && b.vis.currentFrame==2,"impact restores native artwork and removes history");
         w.loc.remObj(b);motion.clear();
      }
      private function capture(holder:Sprite,b:*):Object
      {
         var bitmap:BitmapData=new BitmapData(320,60,true,0);bitmap.draw(holder,new Matrix(1,0,0,1,280-b.X,30-b.Y));
         var result:Object=measure(bitmap);bitmap.dispose();return result;
      }
      private function label(value:String,x:Number,y:Number):void
      {
         var t:TextField=new TextField();t.defaultTextFormat=new TextFormat("Arial",15,0xFFFFFF);t.width=1080;t.height=30;t.text=value;
         sheet.draw(t,new Matrix(1,0,0,1,x,y));
      }
      private function png(name:String,bitmap:BitmapData):void
      {
         var bytes:*=Object(bitmap)["encode"](bitmap.rect,new (cls("flash.display.PNGEncoderOptions"))());
         var s:*=new (cls("flash.filesystem.FileStream"))();s.open(cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");s.writeBytes(bytes);s.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,s:*=new S();
         s.open(F["applicationStorageDirectory"].resolvePath("smart-tracer.txt"),"write");s.writeUTFBytes(log+(error?"FAIL "+error+"\n":"")+(pass?"PASS smart tracer":"FAIL smart tracer")+"\n");s.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
