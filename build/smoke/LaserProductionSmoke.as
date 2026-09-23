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
   import flash.utils.getQualifiedClassName;
   import flash.geom.Point;
   import flash.geom.Matrix;

   /** TEST ONLY. Loads the exact production bytes; never links MSW source. */
   public class LaserProductionSmoke extends Sprite
   {
      private static var probe:LaserProductionSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,log:String="";
      public function LaserProductionSmoke() {}
      public static function init(main:*):void
      {probe=new LaserProductionSmoke();probe.start(main);}
      private function start(main:*):void
      {
         host=main;
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaded);
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void{finish(false,e.text);});
         // Match a normal mod's parent domain, without exposing harness classes.
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function loaded(e:Event):void
      {
         try {
            domain=loader.contentLoaderInfo.applicationDomain;
            var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;entry["init"](host);
            timer.addEventListener("timer",tick);timer.start();
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function ok(value:Boolean,message:String):void
      {if(!value)throw new Error(message);log+="PASS "+message+"\n";}
      private function position(u:*,x:Number,y:Number):void
      {u.setPos(x,y);u.X1=x-u.scX/2;u.X2=x+u.scX/2;u.Y1=y-u.scY;u.Y2=y;u.eyeX=x+u.scX*.25*u.storona;u.eyeY=y-u.scY*.75;u.setVisPos();}
      private function tick(e:Event):void
      {
         try {
            ticks++;
            var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;
            var worldClass:Class=domain.getDefinition("fe.World") as Class;
            var m:*=entry["testInstance"](),w:*=worldClass["w"];
            if(ticks>1000)throw new Error("game did not become ready");
            if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active || m.cfg.diag.frames<600)return;
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            for(var x:int=100;x<1300;x+=20)for(var y:int=80;y<420;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=0;tile.water=0;}
            var target:*=w.loc.createUnit("raider",500,320,true);
            target.fraction=2;target.hp=target.maxhp;target.sost=1;target.disabled=target.trigDis=target.npc=target.noAgro=false;
            target.storona=-1;target.shithp=0;target.stun=0;target.isVis=true;position(target,500,320);
            position(w.gg,240,320);w.gg.dx=w.gg.dy=0;w.loc.units=[w.gg,target];w.loc.objs=[];
            var wp:*=w.invent.weapons["mswdazzler"];
            ok(wp!=null,"production save receives dazzler");
            var geometry:Class=domain.getDefinition("MSWLaserGeometry") as Class;
            var eye:Object=geometry["eye"](target);
            w.gg.currentWeapon=wp;w.gg.childObjs[0]=wp;
            w.celX=w.gg.celX=eye.x;w.celY=w.gg.celY=eye.y;
            wp.loc=w.loc;wp.X=300;wp.Y=eye.y;wp.bulX=300;wp.bulY=eye.y;
            wp.hold=12;wp.t_attack=wp.rapid;wp.t_reload=0;wp.t_prep=20;
            var shots:Number=Number(m.cfg.diag.laserShots||0),hp:Number=target.hp;
            log+="BEFORE weapon="+getQualifiedClassName(wp)+" laserError="+m.cfg.diag.laserError+"\n";
            wp.step();m.laser.frame(w);
            log+="AFTER ammo="+wp.hold+" shots="+m.cfg.diag.laserShots+" blind="+m.laser.blind.remaining(target)+" laserError="+m.cfg.diag.laserError+"\n";
            ok(wp.hold==10,"native shot consumes two batteries");
            ok(Number(m.cfg.diag.laserShots)==shots+1,"native production shot emits one beam callback");
            ok(m.laser.blind.remaining(target)==6 && target.hp==hp,"production eye shot blinds without direct damage");
            var beam:*=w.loc.firstObj;
            while(beam!=null && getQualifiedClassName(beam)!="MSWLaserBeam")beam=beam.nobj;
            ok(beam!=null && beam.vis.parent===w.grafon.visObjs[2],"production native beam exists in world layer");
            var midpoint:Point=new Point(400-Number(beam.vis.laser.scaleX)*50,100);
            var b:BitmapData=new BitmapData(800,200,true,0);b.draw(beam.vis,new Matrix(1,0,0,1,400,100));
            var painted:Boolean=false;
            for(x=int(midpoint.x)-3;x<=int(midpoint.x)+3;x++)for(y=int(midpoint.y)-3;y<=int(midpoint.y)+3;y++)if(x>=0 && y>=0 && x<b.width && y<b.height && (b.getPixel32(x,y)>>>24)>0)painted=true;
            b.dispose();ok(painted,"production beam is actually drawn between muzzle and eye");
            ok(m.cfg.diag.laserError==null,"production laser has no runtime verification error");
            finish(true,"");
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath("production-shot.txt"),"write");
         fs.writeUTFBytes(log+(error?"FAIL "+error+"\n":"")+(pass?"PASS production laser shot":"FAIL production laser shot")+"\n");fs.close();
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(pass?0:1);
      }
   }
}
