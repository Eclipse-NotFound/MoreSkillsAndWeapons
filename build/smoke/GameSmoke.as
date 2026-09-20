package
{
   import flash.display.Sprite;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import flash.utils.Timer;

   [SWF(width="1100", height="700", frameRate="60")]
   public class GameSmoke extends Sprite
   {
      private var timer:Timer=new Timer(50);
      private var ticks:int=0;
      private var phase:int=0;
      private var w:*;
      private var api:*;
      private var items:Array;
      private var rows:Array=[];
      private var bullet:*;
      private var wall:*;
      private var bounceN:int=0;
      private var phaseTick:int=0;
      private var log:String="";
      public function GameSmoke()
      {
         timer.addEventListener("timer",tick);
         timer.start();
      }
      private function check(v:Boolean,label:String):void
      {
         if(!v) throw new Error(label);
         log+="PASS "+label+"\n";
      }
      private function setValue(key:String,value:*):void
      {
         for each(var it:Object in items) if(it.key==key) { it["set"](value); return; }
         throw new Error("Missing item "+key);
      }
      private function value(key:String):*
      {
         for each(var it:Object in items) if(it.key==key) return it["get"]();
         return null;
      }
      private function findRows(o:*):void
      {
         if(o==null || !("visible" in o) || !o.visible) return;
         if("mswItem" in o && o.mswItem!=null) rows.push(o);
         if("numChildren" in o) for(var i:int=0;i<o.numChildren;i++) findRows(o.getChildAt(i));
      }
      private function resetButton(o:*):*
      {
         if(o==null || !o.visible) return null;
         if(o is TextField && o.text=="恢复默认") return o.parent;
         if("numChildren" in o) for(var i:int=0;i<o.numChildren;i++) { var b:*=resetButton(o.getChildAt(i)); if(b!=null)return b; }
         return null;
      }
      private function tick(e:Event):void
      {
         try
         {
            ticks++;
            if(ticks%120==0) write("heartbeat.txt","tick="+ticks+" phase="+phase+"\n"+log);
            if(ticks>3600) throw new Error("timeout phase="+phase);
            if(!ApplicationDomain.currentDomain.hasDefinition("fe.World")) return;
            w=getDefinitionByName("fe.World")["w"];
            if(w==null || w.gg==null || w.loc==null) return;
            if(w.verror!=null && w.verror.visible) throw new Error("game dialog: "+w.verror.txt.text);
            var carrier:*=w.main.getChildByName("MSWModAPICarrier");
            if(carrier==null) return;
            api=carrier.modAPI;
            for each(var pg:Object in api.getPages()) if(pg.modId=="msw") items=pg.items;
            if(items==null) return;
            if(phase==0)
            {
               rows=[]; findRows(w.main);
               if(rows.length!=18) return; // Existing isolated auto-driver opens the real Pip panel.
               if(phaseTick==0) { phaseTick=ticks; return; }
               if(ticks-phaseTick<10) return;
               check(items.length==18,"real Pip renders all 18 settings");
               check(rows[17].mswItem.key=="dashKeepPose","last original setting visible");
               for each(var row:* in rows)
               {
                  var key:String=row.mswItem.key;
                  if(key=="ricochetResetDistance")
                  {
                     check(value(key)===true,"real distance reset defaults on");
                     row.mswSc.selected=false;
                     row.mswSc.dispatchEvent(new Event("change"));
                     check(value(key)===false,"real distance reset checkbox off");
                     var saved:MSWConfig=new MSWConfig(); saved.load();
                     check(!saved.ricochetResetDistance,"real checkbox persists immediately");
                  }
                  if(key=="ricochetCount" || key=="ricochetChance" || key=="ricochetChanceDecay" || key=="ricochetDamageDecay" || key=="ricochetSpeedDecay")
                  {
                     var target:Number=key=="ricochetCount"?3:(key=="ricochetChance"?80:(key=="ricochetChanceDecay"?50:(key=="ricochetDamageDecay"?20:25)));
                     row.mswSc.scrollPosition=target;
                     row.mswSc.dispatchEvent(new Event("scroll"));
                     check(Number(value(key))==target,"real slider "+key);
                  }
               }
               screenshot("settings.png");
               var reset:*=resetButton(w.main); check(reset!=null,"reset button found");
               reset.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
               check(value("ricochetResetDistance")===true,"real reset click restores distance reset");
               check(value("ricochetCount")==1 && value("ricochetChance")==0 && value("ricochetChanceDecay")==0 && value("ricochetDamageDecay")==0 && value("ricochetSpeedDecay")==0,"real reset click restores all five");
               setValue("ricochet",true); setValue("ricochetCount",3); setValue("ricochetChance",100); setValue("ricochetChanceDecay",100); setValue("ricochetDamageDecay",20); setValue("ricochetSpeedDecay",50);
               w.onPause=true;
               // Pick an actual interior wall; stop the world so only controlled collisions occur.
               for(var x:int=60;x<w.loc.spaceX*40-60 && wall==null;x+=40)
                  for(var y:int=60;y<w.loc.spaceY*40-60;y+=40)
                  {
                     var tile:*=w.loc.getAbsTile(x,y);
                     if(tile!=null && tile.phis==1 && tile.phX1>20 && tile.phX2<w.loc.spaceX*40-20 && tile.phY2-tile.phY1>10) { wall=tile; break; }
                  }
               check(wall!=null,"actual solid wall found");
               var B:Class=getDefinitionByName("fe.weapon.Bullet") as Class;
               bullet=new B(w.gg,wall.phX1-5,(wall.phY1+wall.phY2)/2,null,true);
               bullet.dx=10; bullet.dy=0; bullet.vel=10; bullet.damage=100; bullet.tipDamage=0; bullet.dist=5000;
               phase=1; phaseTick=ticks; return;
            }
            if(phase==1 && ticks-phaseTick>=3)
            {
               // Changing the live UI must not change the already registered bullet.
               setValue("ricochet",false); setValue("ricochetCount",0); setValue("ricochetChance",0);
               setValue("ricochetResetDistance",false);
               bullet.X=wall.phX1+5; bullet.dx=Math.abs(bullet.dx); bullet.babah=true; bullet.liv=3;
               phase=2; phaseTick=ticks; return;
            }
            if(phase==2 && ticks-phaseTick>=3)
            {
               var next:*=null; var o:*=w.loc.firstObj;
               while(o!=null) { if(o!==bullet && "owner" in o && o.owner===w.gg && "babah" in o && !o.babah && "begx" in o) {next=o;break;} o=o.nobj; }
               if(bounceN==4)
               {
                  check(next==null,"real extra probability decays to zero and stops");
                  write("results.txt",log+"PASS real game smoke\n"); shutdown(0); return;
               }
               check(next!=null,"real Bullet continuation "+(bounceN+1));
               bounceN++;
               check(Math.abs(next.damage-(bounceN<=3?100:80))<0.00001,"real damage step "+bounceN);
               check(Math.abs(next.vel-(bounceN<=3?10:5))<0.00001,"real speed step "+bounceN);
               check(next.dist==0,"real distance reset base and extra "+bounceN);
               bullet=next; phase=1; phaseTick=ticks;
            }
         }
         catch(err:*) { write("results.txt",log+"FAIL "+err+"\n"+err.getStackTrace()); shutdown(1); }
      }
      private function write(name:String,text:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class;
         var S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var s:*=new S(); s.open(F["applicationStorageDirectory"].resolvePath(name),"write"); s.writeUTFBytes(text); s.close();
      }
      private function screenshot(name:String):void
      {
         var gameStage:*=w.main.stage;
         // 隐藏测试窗口不一定派发 RENDER，先让原版 fl.controls 绘制皮肤。
         for each(var row:* in rows)
         {
            var control:*=row.mswSc;
            if(control!=null && "drawNow" in control) control.drawNow();
         }
         var b:BitmapData=new BitmapData(gameStage.stageWidth,gameStage.stageHeight,false,0);
         b.draw(gameStage);
         var encoder:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class;
         var bytes:* = Object(b)["encode"](b.rect,new encoder());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class;
         var S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var s:*=new S(); s.open(F["applicationStorageDirectory"].resolvePath(name),"write"); s.writeBytes(bytes); s.close(); b.dispose();
      }
      private function shutdown(code:int):void
      {
         timer.stop();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
