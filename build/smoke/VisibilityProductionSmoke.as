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
   import flash.utils.getTimer;
   import flash.utils.getDefinitionByName;
   import flash.geom.Point;
   import flash.geom.Rectangle;

   /** TEST ONLY: actual production visibility and acquisition, with native unit flags. */
   public class VisibilityProductionSmoke extends Sprite
   {
      private static var probe:VisibilityProductionSmoke;
      private var host:*,loader:Loader=new Loader(),domain:ApplicationDomain,timer:Timer=new Timer(50);
      private var m:*,w:*,weapon:*,started:Boolean=false,phase:int=0,ticks:int=0,since:int=0;
      private var log:String="",checks:int=0,failures:int=0,targets:Array=[],rows:Array=[];
      public function VisibilityProductionSmoke(){}
      public static function init(main:*):void{probe=new VisibilityProductionSmoke();probe.start(main);}
      private function cls(n:String):Class{return domain.getDefinition(n) as Class;}
      private function start(main:*):void
      {
         host=main;
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void{
            domain=loader.contentLoaderInfo.applicationDomain;cls("MoreSkillsWeaponsMod")["init"](host);
            timer.addEventListener("timer",tick);timer.start();
         });
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void{finish(false,e.text);});
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(host.loaderInfo.applicationDomain)));
      }
      private function check(v:Boolean,msg:String):void
      {checks++;if(!v)failures++;log+=(v?"PASS ":"FAIL ")+msg+"\n";}
      private function record(u:*,label:String):void
      {
         var a:Point=w.visual.localToGlobal(new Point(u.X1,u.Y1)),b:Point=w.visual.localToGlobal(new Point(u.X2,u.Y2));
         var vr:Rectangle=u.vis.getBounds(host.stage),s:*=m.smart.multiLock.stateFor(u);
         var row:Object={label:label,id:u.id,body:[u.X1,u.Y1,u.X2,u.Y2],screen:[a.x,a.y,b.x,b.y],art:[vr.x,vr.y,vr.width,vr.height],
            isVis:u.isVis,invis:u.invis,alpha:u.vis.alpha,drawn:u.vis.visible,disabled:u.disabled,trigDis:u.trigDis,npc:u.npc,noAgro:u.noAgro,
            hp:u.hp,sost:u.sost,fraction:u.fraction,allowed:m.smart.targetAllowed(u,w),visible:m.smart.visible(u,w),
            locked:s!=null && s.target===u,progress:s==null?0:s.progress,eye:[w.gg.eyeX,w.gg.eyeY]};
         rows.push(row);log+="STATE "+JSON.stringify(row)+"\n";
      }
      private function tick(e:Event):void
      {
         try{
            ticks++;if(ticks>1800)throw new Error("timeout phase="+phase);
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];
            if(m==null || w==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(ticks%100==0)write("heartbeat.txt","ticks="+ticks+" phase="+phase+"\n"+log);
            if(w.gg==null || w.loc==null || !w.loc.active || ticks<100)return;
            if(phase==0)
            {
               if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.controlOn();
               w.gui.dialText();w.gg.work="";w.gg.t_work=0;w.loc.base=false;
               for(var x:int=80;x<1400;x+=20)for(var y:int=40;y<760;y+=20)
               {var t:*=w.loc.getAbsTile(x,y);t.phis=t.water=0;t.door=null;}
               w.gg.setPos(220,360);w.gg.dx=w.gg.dy=0;w.gg.actions();w.gg.setVisPos();
               w.visual.x=w.visual.y=0;w.visual.scaleX=w.visual.scaleY=1;
               w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;
               weapon=cls("fe.weapon.Weapon")["create"](w.gg,"p9mm");w.gg.currentWeapon=weapon;
               w.loc.units=[w.gg];w.loc.objs=[];
               var ids:Array=["raider","zombie","rat","bloodwing","bloat","protect","robot","alicorn","zebra"];
               for(var i:int=0;i<ids.length;i++)
               {
                  var u:*=w.loc.createUnit(ids[i],420+(i%3)*150,160+int(i/3)*170,true);
                  if(u==null)throw new Error("native creation "+ids[i]);
                  u.dx=u.dy=0;u.actions();u.setVisPos();u.animate();targets.push(u);record(u,"spawn");
               }
               m.cfg.smartEnabled=true;m.cfg.smartMultiLock=true;m.cfg.smartAcquire=0.3;m.cfg.smartKeepOutOfSight=false;
               m.smart.frame(w);since=getTimer();phase=1;return;
            }
            if(phase==1 && getTimer()-since>1000)
            {
               for each(u in targets)
               {
                  record(u,"after-acquire");
                  if(u.isVis && !u.invis && u.vis.visible && u.vis.alpha>0.99 && m.smart.targetAllowed(u,w))
                  {
                     check(m.smart.visible(u,w),"clear screen-centre native "+u.id+" visible");
                     var s:*=m.smart.multiLock.stateFor(u);check(s!=null && s.target===u,"clear native "+u.id+" locks");
                  }
               }
               screenshot("native-baseline.png");
               check(m.cfg.diag.smartError==null,"smart frame has no swallowed exception: "+m.cfg.diag.smartError);
               var subject:*=targets[0];
               for each(var zoom:Number in [0.5,0.75,1,1.5])for each(var shift:Number in [-120,0,180])
               {
                  w.visual.scaleX=w.visual.scaleY=zoom;w.visual.x=shift;w.visual.y=20;
                  check(m.smart.visible(subject,w),"unobstructed native remains visible at zoom="+zoom+" shift="+shift);
               }
               w.visual.x=w.visual.y=0;w.visual.scaleX=w.visual.scaleY=1;
               // Native support platform: the player's actual eye has a clear
               // ray to the lower target, while an estimated torso ray may not.
               for(x=80;x<280;x+=40)
               {t=w.loc.getAbsTile(x+1,361);t.phis=1;t.phX1=x;t.phX2=x+40;t.phY1=360;t.phY2=400;}
               w.gg.storona=1;w.gg.setPos(220,360);w.gg.dx=w.gg.dy=0;w.gg.actions();w.gg.setVisPos();
               subject.setPos(420,580);subject.setVisPos();w.loc.units=[w.gg,subject];targets=[subject];
               m.smart.multiLock.clear();
               var eyeClear:Boolean=w.loc.isLine(w.gg.eyeX,w.gg.eyeY,subject.X,subject.Y1+3);
               check(eyeClear,"native player eye sees the lower target above platform edge");
               record(subject,"platform-edge");
               check(m.smart.visible(subject,w),"native-eye-visible lower target passes smart visibility");
               phase=2;since=getTimer();return;
            }
            if(phase==2 && getTimer()-since>1000)
            {
               subject=targets[0];record(subject,"platform-after-acquire");
               s=m.smart.multiLock.stateFor(subject);
               check(s!=null && s.target===subject,"native-eye-visible lower target completes multi-lock");
               for(x=80;x<280;x+=40)w.loc.getAbsTile(x+1,361).phis=0;
               var hidden:*=w.loc.createUnit("alicorn",600,320,true,null,"1");
               w.loc.units=[w.gg,hidden];targets=[hidden];hidden.setCel(w.gg);hidden.alarma();
               for(i=0;i<600 && !hidden.invis;i++)hidden.control();
               check(hidden.invis && !hidden.isVis,"native alicorn enters its own stealth ability");
               w.pers.infravis=1;
               for(i=0;i<24;i++)hidden.animate();
               hidden.setVisPos();m.smart.multiLock.clear();record(hidden,"infrared-revealed");
               check(hidden.vis.visible && hidden.vis.alpha>0.99,"native detection fully renders the stealth enemy");
               check(m.smart.visible(hidden,w),"fully revealed on-screen enemy passes smart visibility");
               phase=3;since=getTimer();return;
            }
            if(phase==3 && getTimer()-since>1000)
            {
               hidden=targets[0];record(hidden,"infrared-after-acquire");s=m.smart.multiLock.stateFor(hidden);
               check(s!=null && s.target===hidden,"native infrared-revealed target completes multi-lock");
               var savedX:Number=hidden.X,savedY:Number=hidden.Y;
               hidden.setPos(2400,savedY);hidden.setVisPos();
               check(!m.smart.visible(hidden,w),"infrared detection does not acquire off-screen enemies");
               hidden.setPos(savedX,savedY);hidden.setVisPos();
               for(y=40;y<760;y+=40)
               {t=w.loc.getAbsTile(401,y+1);t.phis=1;t.phX1=400;t.phX2=440;t.phY1=y;t.phY2=y+40;}
               check(!m.smart.visible(hidden,w),"infrared detection does not acquire through a solid wall");
               for(y=40;y<760;y+=40)w.loc.getAbsTile(401,y+1).phis=0;
               hidden.vis.visible=false;
               check(!m.smart.visible(hidden,w),"an externally hidden stealth sprite cannot use infrared exception");
               hidden.vis.visible=true;hidden.vis.alpha=0.4;
               check(!m.smart.visible(hidden,w),"infrared exception waits for the native reveal to become visible");
               for(i=0;i<24;i++)hidden.animate();
               // The same real acquisition path must also work in single mode.
               m.cfg.smartMultiLock=false;w.celX=hidden.X;w.celY=(hidden.Y1+hidden.Y2)/2;
               w.cam.celX=w.celX;w.cam.celY=w.celY;m.smart.frame(w);
               phase=4;since=getTimer();return;
            }
            if(phase==4 && getTimer()-since>1000)
            {
               hidden=targets[0];
               check(m.smart.lock.target===hidden,"native infrared-revealed target completes single lock");
               w.pers.infravis=0;for(i=0;i<24;i++)hidden.animate();
               check(!m.smart.visible(hidden,w),"undetected stealth target still cannot acquire");
               hidden= w.loc.createUnit("zombie",600,320,true);
               hidden.invis=true;w.pers.infravis=1;
               check(!m.smart.visible(hidden,w),"infrared does not bypass other native invisibility states");
               check(m.cfg.diag.smartError==null,"both acquisition modes finish without frame errors");
               finish(failures==0,"");
            }
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function screenshot(name:String):void
      {
         var bmp:BitmapData=new BitmapData(host.stage.stageWidth,host.stage.stageHeight,false,0);bmp.draw(host.stage);
         var enc:Class=cls("flash.display.PNGEncoderOptions"),bytes:*=Object(bmp)["encode"](bmp.rect,new enc());
         var fs:*=new (cls("flash.filesystem.FileStream"))();fs.open(cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();bmp.dispose();
      }
      private function write(name:String,value:String):void
      {
         var fs:*=new (cls("flash.filesystem.FileStream"))();fs.open(cls("flash.filesystem.File")["applicationStorageDirectory"].resolvePath(name),"write");fs.writeUTFBytes(value);fs.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();write("visibility.json",JSON.stringify(rows,null,2));
         write("production-visibility.txt",log+(error?"FAIL "+error+"\n":"")+"checks="+checks+" failures="+failures+"\n"+(pass?"PASS production visibility":"FAIL production visibility")+"\n");
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(pass?0:1);
      }
   }
}
