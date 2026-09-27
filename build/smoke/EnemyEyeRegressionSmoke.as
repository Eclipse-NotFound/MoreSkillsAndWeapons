package
{
   import flash.display.*;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.geom.*;
   import flash.text.*;

   /** TEST ONLY: independently annotated native eyes; exact production SWF. */
   public class EnemyEyeRegressionSmoke extends Sprite
   {
      private static var probe:EnemyEyeRegressionSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,started:Boolean=false,log:String="";
      private var records:Array=[];
      private var failures:int=0;
      public function EnemyEyeRegressionSmoke() {}
      public static function init(main:*):void {probe=new EnemyEyeRegressionSmoke();probe.start(main);}
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
      private function tick(e:Event):void
      {
         try {
            ticks++;
            var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class,WC:Class=domain.getDefinition("fe.World") as Class;
            var m:*=entry["testInstance"](),w:*=WC["w"];
            if(ticks>600)throw new Error("world timeout");
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(ticks<90 || w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswlaserpointer"]==null)return;
            w.gg.controlOn();if(w.gg.atkPoss==0)return;
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            w.gui.dialText();w.catPause=false;w.gg.work="";w.gg.t_work=0;w.gg.dx=w.gg.dy=0;w.loc.base=false;
            for(var x:int=100;x<1300;x+=20)for(var y:int=40;y<550;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;}
            w.loc.objs=[];w.invent.items.batt.kol=1000;
            var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
            var fs:*=new S();fs.open(F["applicationDirectory"].resolvePath("eye-native-fixtures.json"),"read");var specs:Array=JSON.parse(fs.readUTFBytes(fs.bytesAvailable)) as Array;fs.close();
            for each(var spec:Object in specs)
            {
               var u:*=w.loc.createUnit(spec.spawn,650,280,true,null,spec.cid);
               u.fraction=2;u.hp=u.maxhp;u.sost=1;u.disabled=u.trigDis=u.npc=u.noAgro=false;u.shithp=0;u.stun=u.t_emerg=0;u.isVis=true;
               u.setPos(650,280);u.actions();u.setVisPos();u.vis.visible=true;
               check(u.id==spec.id,"native identity "+spec.id+" actual="+u.id);
               nativeShots(w,m,u,spec);u.exterminate();
            }
            hiddenEyes(w);
            if(failures>0)throw new Error(failures+" independent eye checks failed");
            finish(true,"");
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function bitmap(node:DisplayObject):Bitmap
      {
         if(node is Bitmap)return Bitmap(node);
         var c:DisplayObjectContainer=node as DisplayObjectContainer;
         if(c!=null)for(var i:int=0;i<c.numChildren;i++){var b:Bitmap=bitmap(c.getChildAt(i));if(b!=null)return b;}
         return null;
      }
      private function check(pass:Boolean,message:String):void
      {log+=(pass?"PASS ":"FAIL ")+message+"\n";if(!pass)failures++;}
      private function hiddenEyes(w:*):void
      {
         var eyes:Class=domain.getDefinition("MSWLaserEyes") as Class,geometry:Class=domain.getDefinition("MSWLaserGeometry") as Class;
         for each(var s:Object in [{spawn:"bloodwing",cid:"1",outer:1},{spawn:"zombie",cid:"1",row:6},{spawn:"hellhound",cid:"1",row:6}])
         {
            var u:*=w.loc.createUnit(s.spawn,650,280,true,null,s.cid);u.fraction=2;u.sost=1;u.hp=u.maxhp;u.storona=1;u.disabled=u.trigDis=false;u.shithp=0;u.actions();u.setVisPos();
            if(s.outer)u.vis.osn.gotoAndStop(s.outer);else u.blit(s.row,0);
            w.loc.units=[w.gg,u];var e:Object=eyes["point"](u);
            check(!eyes["available"](u),"covered eye unavailable "+s.spawn);
            var hit:Object=geometry["castRay"](w,e.x+150,e.y,Math.PI,6,2000,w.gg,true);
            check(!hit.eye,"covered eye cannot be hit "+s.spawn);u.exterminate();
         }
      }
      private function advance(node:DisplayObject,f:int,depth:int=0):void
      {
         if(depth>0 && node is MovieClip && MovieClip(node).totalFrames>1)MovieClip(node).gotoAndStop(Math.min(f,MovieClip(node).totalFrames));
         if(depth<6 && node is DisplayObjectContainer){var c:DisplayObjectContainer=DisplayObjectContainer(node);for(var i:int=0;i<c.numChildren;i++)advance(c.getChildAt(i),f,depth+1);}
      }
      private function nativeShots(w:*,m:*,u:*,spec:Object):void
      {
         var eyes:Class=domain.getDefinition("MSWLaserEyes") as Class;
         w.loc.units=[w.gg,u];m.cfg.laserAssist=false;m.cfg.laserNonFront=false;m.cfg.pointerEnabled=m.cfg.laserEnabled=true;
         for each(var id:String in ["mswdazzler","mswlaserpointer"])for each(var side:int in [1,-1])
         {
            m.pointer.stop();m.laser.clear();u.storona=side;u.sost=1;u.hp=u.maxhp;u.setPos(650,280);u.setVisPos();
            var node:DisplayObject;
            if(spec.kind=="vector") {u.vis.osn.gotoAndStop(spec.outer);advance(u.vis.osn,spec.inner);node=u.vis;}
            else {u.blit(spec.row,spec.frame);node=bitmap(u.vis);}
            var pixel:Point=new Point(spec.eye[0],spec.eye[1]);
            var eye:Point=u.vis.parent.globalToLocal(node.localToGlobal(pixel)),actual:Object=eyes["point"](u),distance:Number=Point.distance(eye,new Point(actual.x,actual.y));
            var label:String=id+" "+spec.id+" r="+(spec.kind=="vector"?spec.outer:spec.row)+" f="+(spec.kind=="vector"?spec.inner:spec.frame)+" facing="+side;
            check(distance<=3,"independent eye distance "+label+" error="+distance.toFixed(2));
            if(distance>3)log+="DETAIL visual-local actual="+node.globalToLocal(u.vis.parent.localToGlobal(new Point(actual.x,actual.y)))+" native="+pixel+"\n";
            w.gg.setPos(eye.x+side*180,eye.y+100);w.gg.storona=-side;w.gg.setVisPos();
            if(w.gg.currentWeapon==null || w.gg.currentWeapon.id!=id)w.gg.changeWeapon(id,true);
            var wp:*=w.gg.currentWeapon;
            w.cam.celX=eye.x*w.cam.scaleV+w.cam.vx;w.cam.celY=eye.y*w.cam.scaleV+w.cam.vy;w.celX=w.gg.celX=eye.x;w.celY=w.gg.celY=eye.y;
            for(var i:int=0;i<12;i++){w.gg.setWeaponPos();wp.step();}wp.getBulXY();
            var hp:Number=u.hp,shots:Number=Number(m.cfg.diag.laserShots||0);
            if(id=="mswlaserpointer")
            {m.pointer.prepare(w);wp.step();w.ctr.keyAttack=true;wp.attack();m.pointer.frame(w);check(m.pointer.lit,"native pointer on "+label);}
            else
            {wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;wp.attack();wp.step();check(Number(m.cfg.diag.laserShots||0)==shots+1,"native gun fired "+label);}
            check(m.laser.blind.remaining(u)==6,"blind visual eye "+label+" remain="+m.laser.blind.remaining(u));
            check(u.hp==hp,"zero damage "+label);
         }
         m.pointer.stop();m.laser.clear();
         check(m.cfg.diag.pointerError==null && m.cfg.diag.laserError==null,"no callback errors "+spec.id);
      }
      private function savePNG(b:BitmapData,name:String):void
      {
         var enc:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class,bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();
      }
      private function write(name:String,s:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeUTFBytes(s);fs.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();write("eye-alignment.txt",log+(error?"FAIL "+error+"\n":"")+(pass?"PASS eye alignment":"FAIL eye alignment")+"\n");
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(pass?0:1);
      }
   }
}
