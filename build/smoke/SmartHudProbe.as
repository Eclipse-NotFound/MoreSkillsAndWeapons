package
{
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.Timer;

   public class SmartHudProbe
   {
      private var timer:Timer=new Timer(50),ticks:int=0,phase:int=0;
      private var m:*,w:*,target:*,candidate:*,hud:MSWSmartHUD;
      private var log:String="";
      public function SmartHudProbe(){timer.addEventListener("timer",tick);timer.start();}
      private function ok(value:Boolean,message:String):void
      {if(!value)throw new Error(message);log+="PASS "+message+"\n";}
      private function tick(e:Event):void
      {
         try
         {
            ticks++;if(ticks%100==0)write("heartbeat.txt","tick="+ticks+" phase="+phase+"\n"+log);
            if(ticks>800)throw new Error("timeout phase "+phase);
            m=MoreSkillsWeaponsMod.testInstance();w=MSWU.world();
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(w.verror.visible)throw new Error("game dialog: "+w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error("smart error: "+m.cfg.diag.smartError);
            if(phase==0)
            {
               if(ticks<220)return;
               if(w.pip.active)w.pip.onoff();
               if(m.panel.overlayOpen)m.panel.toggleOverlay();
               w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
               var W:Class=MSWU.cls("fe.weapon.Weapon");w.gg.currentWeapon=W["create"](w.gg,"p9mm");
               target=w.loc.createUnit("raider",w.gg.X+140,w.gg.Y,true);
               candidate=w.loc.createUnit("raider",w.gg.X+240,w.gg.Y,true);
               ok(target!=null && candidate!=null,"two native Raider sprites created");
               for each(var u:* in [target,candidate])
               {u.fraction=2;u.hp=u.maxhp;u.sost=1;u.disabled=false;u.npc=false;u.noAgro=false;u.storona=-1;u.setVisPos();u.isVis=true;}
               m.cfg.smartEnabled=true;m.smart.frame(w);
               hud=w.main.getChildByName("MSWSmartHUD") as MSWSmartHUD;
               ok(hud!=null && hud.numChildren==0,"production frame installs diamond HUD without text");
               phase=1;return;
            }
            if(phase==1)
            {
               // Native render has now had a frame to display the new sprites.
               m.smart.lock.target=target;m.smart.lock.strength=1;
               m.smart.lock.candidate=candidate;m.smart.lock.progress=0.5;
               hud.render(w,m.smart.lock);screenshot("game-two-targets.png");
               ok(hud.visible && target.vis!=null && candidate.vis!=null,"native scene renders old lock and new candidate");
               var a:Point=w.visual.localToGlobal(new Point(target.X,target.Y));
               write("scene.txt","player="+w.gg.X+","+w.gg.Y+" target="+target.X+","+target.Y+" screen="+a+" stage="+w.main.stage.stageWidth+"x"+w.main.stage.stageHeight);
               m.smart.lock.candidate=null;m.smart.lock.progress=0;
               w.celX=-1000;w.celY=-1000;
               for each(var size:Number in [12,24,40,80])
               {
                  m.cfg.smartHudSize=size;m.smart.frame(w);
                  var bounds:Rectangle=hud.getBounds(w.main.stage);
                  ok(Math.abs(bounds.width-size)<4 && Math.abs(bounds.height-size)<4,"production frame uses configured HUD size "+size);
               }
               m.cfg.smartHudSize=24;
               m.smart.lock.advance(null,false,m.cfg.smartHold+m.cfg.smartDecay/2,m.cfg);
               hud.render(w,m.smart.lock);screenshot("game-loss.png");
               ok(Math.abs(m.smart.lock.strength-0.5)<0.001,"actual lock decay reaches half blue");
               m.smart.lock.advance(null,false,m.cfg.smartDecay,m.cfg);hud.render(w,m.smart.lock);
               ok(m.smart.lock.target==null && !hud.visible,"actual lock expiry clears marker");
               m.smart.lock.advance(candidate,true,m.cfg.smartAcquire/2,m.cfg);hud.render(w,m.smart.lock);
               ok(m.smart.lock.candidate===candidate && hud.visible,"candidate appears during actual acquisition");
               candidate.isVis=false;
               m.smart.lock.advance(null,false,m.cfg.smartGrace/2,m.cfg);hud.render(w,m.smart.lock);
               ok(hud.visible && m.smart.lock.progress==0.5,"occluded acquisition retains its marker during grace");
               m.smart.lock.advance(null,false,m.cfg.smartGrace+m.cfg.smartRetreat,m.cfg);hud.render(w,m.smart.lock);
               ok(!hud.visible,"interrupted candidate disappears on zero");
               m.smart.lock.target=target;m.smart.lock.strength=1;hud.render(w,m.smart.lock);
               m.cfg.smartEnabled=false;m.smart.frame(w);
               ok(!hud.visible && m.smart.lock.target==null,"master switch clears and hides HUD");
               ok(m.cfg.diag.smartError==null,"no smart runtime errors");
               finish("PASS smart HUD game smoke",0);
            }
         }
         catch(err:*){finish("FAIL "+err+"\n"+err.getStackTrace(),1);}
      }
      private function screenshot(name:String):void
      {
         var st:*=w.main.stage,b:BitmapData=new BitmapData(st.stageWidth,st.stageHeight,false,0);b.draw(st);
         var enc:Class=MSWU.cls("flash.display.PNGEncoderOptions");var bytes:*=Object(b)["encode"](b.rect,new enc());
         var S:Class=MSWU.cls("flash.filesystem.FileStream"),f:*=new S();f.open(MSWU.cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");f.writeBytes(bytes);f.close();b.dispose();
      }
      private function write(name:String,value:String):void
      {var S:Class=MSWU.cls("flash.filesystem.FileStream"),f:*=new S();f.open(MSWU.cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");f.writeUTFBytes(value);f.close();}
      private function finish(value:String,code:int):void
      {write("results.txt",log+value+"\n");timer.stop();MSWU.cls("flash.desktop.NativeApplication")["nativeApplication"].exit(code);}
   }
}
