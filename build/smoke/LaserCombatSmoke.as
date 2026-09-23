package
{
   import flash.display.Sprite;
   import flash.display.Loader;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFormat;
   /** TEST ONLY: native actor geometry, inventory equip and weapon actions. */
   public class LaserCombatSmoke extends Sprite
   {
      private static var probe:LaserCombatSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,log:String="",started:Boolean=false;
      private var liveTarget:*,liveFrame:int=0;
      public function LaserCombatSmoke() {}
      public static function init(main:*):void {probe=new LaserCombatSmoke();probe.start(main);}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaded);
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function loaded(e:Event):void
      {
         domain=loader.contentLoaderInfo.applicationDomain;
         var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;entry["init"](host);
         timer.addEventListener("timer",tick);timer.start();
      }
      private function ok(value:Boolean,message:String):void {if(!value)throw new Error(message);log+="PASS "+message+"\n";}
      private function tick(e:Event):void
      {
         try {
            ticks++;
            var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class,WC:Class=domain.getDefinition("fe.World") as Class;
            var m:*=entry["testInstance"](),w:*=WC["w"];
            if(ticks>600)throw new Error("game did not become ready");
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswdazzler"]==null)return;
            if(liveTarget!=null)
            {
               if(ticks-liveFrame<20)return;
               if(m.laser.blind.remaining(liveTarget)>=5.5 && ticks-liveFrame<150)return;
               ok(m.laser.blind.remaining(liveTarget)>0 && m.laser.blind.remaining(liveTarget)<5.5,"natural battle steps keep blindness and advance its timer");
               ok(liveTarget.vision==0 && liveTarget.celUnit==null,"blinded moving actor cannot reacquire player");
               ok(m.cfg.diag.laserError==null,"no laser errors through natural battle updates");
               finish(true,"");return;
            }
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            for(var x:int=100;x<1300;x+=20)for(var y:int=80;y<420;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=0;tile.water=0;}
            atlas(w);
            var target:*=w.loc.createUnit("raider",500,320,true);
            target.fraction=2;target.hp=target.maxhp;target.sost=1;target.disabled=target.trigDis=target.npc=target.noAgro=false;
            target.storona=-1;target.shithp=0;target.stun=target.t_emerg=0;target.isVis=true;
            target.setPos(500,320);target.actions();target.setVisPos();target.animate();
            w.gg.setPos(240,320);w.gg.storona=1;w.gg.dx=w.gg.dy=0;w.loc.units=[w.gg,target];w.loc.objs=[];
            w.gg.changeWeapon("mswdazzler",true);m.laser.frame(w);
            var wp:*=w.gg.currentWeapon;
            // This visual eye is measured from the native raider sprite, not
            // copied from the production target resolver under test.
            m.cfg.laserAssist=false;
            w.celX=w.gg.celX=target.X-26;w.celY=w.gg.celY=target.Y-68;
            for(var i:int=0;i<20;i++){w.gg.setWeaponPos();wp.step();}
            wp.getBulXY();
            target.setWeaponPos(2);
            log+="NATIVE eye="+target.eyeX+","+target.eyeY+" body="+target.X1+","+target.Y1+","+target.X2+","+target.Y2+" muzzle="+wp.bulX+","+wp.bulY+" facing="+target.storona+" mouth="+target.weaponX+","+target.weaponY+","+target.weaponR+" visual="+getQualifiedClassName(target.vis)+"\n";
            var image:BitmapData=new BitmapData(720,480,false,0x33404C),mat:Matrix=new Matrix(4*target.storona,0,0,4,360,400);
            target.vis.visible=true;image.draw(target.vis,mat);
            var marker:Sprite=new Sprite();marker.graphics.lineStyle(1,0x00FFFF);marker.graphics.drawCircle((target.eyeX-target.X)*4+360,(target.eyeY-target.Y)*4+400,6);
            image.draw(marker);savePNG(image,"native-eye.png");image.dispose();
            wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
            var shots:Number=Number(m.cfg.diag.laserShots||0),hp:Number=target.hp;
            wp.attack();wp.step();m.laser.frame(w);
            log+="SHOT ammo="+wp.hold+" shots="+m.cfg.diag.laserShots+" blind="+m.laser.blind.remaining(target)+" error="+m.cfg.diag.laserError+"\n";
            ok(wp.hold==10 && Number(m.cfg.diag.laserShots)==shots+1,"native equip/attack fires exactly once");
            ok(m.laser.blind.remaining(target)==6 && target.hp==hp,"manual shot at visible eye blinds without damage");
            var beam:*=w.loc.firstObj;while(beam!=null && getQualifiedClassName(beam)!="MSWLaserBeam")beam=beam.nobj;
            ok(beam!=null && beam.vis.parent===w.grafon.visObjs[2],"beam is rendered in the original projectile world layer");
            ok(getQualifiedClassName(beam.vis)==getQualifiedClassName(new wp.vBullet()),"beam uses the native laser-pistol asset");
            var beamImage:BitmapData=new BitmapData(780,150,false,0x33404C);
            beamImage.draw(beam.vis,new Matrix(1,0,0,1,650,70));savePNG(beamImage,"native-laser-beam.png");beamImage.dispose();
            beam.step();ok(Math.abs(beam.vis.alpha-.75)<.001,"native laser fade starts at three-quarter opacity");
            beam.step();beam.step();beam.step();ok(!beam.in_chain && beam.vis.parent==null,"beam removes itself after four game steps");
            var geometry:Class=domain.getDefinition("MSWLaserGeometry") as Class;
            m.laser.blind.clear();target.stay=true;target.dx=target.dy=0;target.animate();
            var eye:Object=geometry["eye"](target);
            var hit:Object=geometry["castRay"](w,300,eye.y,0,6,2000,w.gg);
            log+="STANDING eye="+eye.x+","+eye.y+" bodyTop="+target.Y1+" hit="+hit.eye+"\n";
            ok(hit.eye && hit.unit===target,"standing visual eye works");
            target.exterminate();target=w.loc.createUnit("protect",500,320,true);target.storona=-1;target.shithp=0;target.setPos(500,320);target.actions();target.setVisPos();target.animate();w.loc.units=[w.gg,target];
            hit=geometry["castRay"](w,300,240,0,6,2000,w.gg);
            ok(hit.eye && hit.unit===target,"visible robot sensor above body collision box can be hit");
            target.exterminate();target=w.loc.createUnit("raider",500,320,true);target.storona=-1;target.shithp=0;target.t_emerg=0;target.setPos(500,320);target.actions();target.setVisPos();target.animate();w.loc.units=[w.gg,target];
            // Real gun/assist path after turning and animated movement. Eye
            // geometry was independently checked against sprite pixels above.
            m.cfg.laserAssist=true;
            for(i=0;i<12;i++)
            {
               m.laser.blind.clear();target.storona=i%2?-1:1;target.stay=true;target.dx=i%3?4:0;target.animate();target.setVisPos();
               w.gg.setPos(i%2?240:760,320);w.gg.storona=-target.storona;w.gg.setVisPos();w.gg.dx=w.gg.dy=0;
               eye=geometry["eye"](target);w.celX=w.gg.celX=eye.x;w.celY=w.gg.celY=eye.y+6;
               for(var settle:int=0;settle<15;settle++){w.gg.setWeaponPos();wp.step();}
               wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
               wp.attack();wp.step();m.laser.frame(w);
               ok(m.laser.blind.remaining(target)==6,"native aim assist hits displayed eye after move/turn "+i);
            }
            w.onPause=false;w.catPause=false;w.gg.ggControl=true;
            liveTarget=target;liveFrame=ticks;timer.start();
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function atlas(w:*):void
      {
         var ids:Array=["raider","slaver","zebra","ranger","merc","encl","alicorn","protect","gutsy","robot","eqd","sentinel","roller","spritebot","vortex","dron","msp","thunderhead","turret","landturret","wturret","bossturret","zombie","hellhound","rat","ant","bloat","bloodwing","fish","necros","bossraider","bossnecr","bossalicorn","megadron","bossencl","ultra"];
         var sheet:BitmapData=new BitmapData(1320,1680,false,0x33404C),geometry:Class=domain.getDefinition("MSWLaserGeometry") as Class;
         for(var n:int=0;n<ids.length;n++)
         {
            var u:*=w.loc.createUnit(ids[n],600,320,true);u.storona=1;u.sost=1;u.stay=true;u.dx=u.dy=0;u.setPos(600,320);u.actions();u.setVisPos();u.animate();u.vis.visible=true;
            var cx:Number=(n%6)*220+100,cy:Number=int(n/6)*280+235;
            var bounds:*=u.vis.getBounds(u.vis),scale:Number=Math.min(2,200/bounds.width,220/bounds.height);
            sheet.draw(u.vis,new Matrix(scale,0,0,scale,cx,cy));
            var p:Object=geometry["eye"](u),mark:Sprite=new Sprite();mark.graphics.lineStyle(1,0x00FFFF);mark.graphics.drawCircle(cx+(u.eyeX-u.X)*scale,cy+(u.eyeY-u.Y)*scale,3);
            mark.graphics.lineStyle(1,0xFF6666);mark.graphics.drawCircle(cx+(p.x-u.X)*scale,cy+(p.y-u.Y)*scale,4);sheet.draw(mark);
            var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("_sans",13,0xFFFFFF);label.width=215;label.text=ids[n]+" "+u.animState;sheet.draw(label,new Matrix(1,0,0,1,int(n%6)*220+4,int(n/6)*280+248));
            log+="ATLAS "+ids[n]+" "+getQualifiedClassName(u)+" size="+u.scX+","+u.scY+" eye="+(p.x-u.X)+","+(p.y-u.Y)+" bounds="+bounds+"\n";
            if(ids[n]=="protect")
            {
               var h:Object=geometry["castRay"]({loc:u.loc,gg:w.gg},u.X-150,u.Y-80,0,6,2000,w.gg);
               log+="PROTECT visible sensor above body: hit="+h.eye+" bodyTop="+u.Y1+" sensorY="+(u.Y-80)+"\n";
            }
            u.exterminate();
         }
         savePNG(sheet,"eye-atlas.png");sheet.dispose();
      }
      private function savePNG(b:BitmapData,name:String):void
      {
         var enc:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class,bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath("combat-shot.txt"),"write");fs.writeUTFBytes(log+(error?"FAIL "+error+"\n":"")+(pass?"PASS production laser shot":"FAIL production laser shot")+"\n");fs.close();
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(pass?0:1);
      }
   }
}
