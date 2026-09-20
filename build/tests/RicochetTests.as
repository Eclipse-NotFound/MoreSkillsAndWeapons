package
{
   import flash.display.Sprite;
   import flash.net.SharedObject;
   import flash.utils.getDefinitionByName;
   import fe.weapon.Bullet;

   public class RicochetTests extends Sprite
   {
      private var checks:int = 0;
      private var report:String = "";
      public function RicochetTests()
      {
         trace("START RicochetTests");
         try
         {
            rules(); chains(); distanceModes(); wallBoundaries(); configAndPanel();
            finish("PASS " + checks + " assertions", 0);
         }
         catch(e:*) { finish("FAIL " + e + "\n" + e.getStackTrace(), 1); }
      }
      private function ok(value:Boolean, name:String):void
      {
         if(!value) throw new Error(name);
         checks++; report += "PASS " + name + "\n";
      }
      private function near(a:Number, b:Number, name:String):void { ok(Math.abs(a-b)<0.000001, name); }
      private function cfg():MSWConfig
      {
         var c:MSWConfig = new MSWConfig(); c.ricochet=true; c.diag={}; return c;
      }
      private function rules():void
      {
         var c:MSWConfig=cfg(); var r:MSWRicochet=new MSWRicochet(c);
         ok(r.plan(100,10)!=null,"legacy first bounce"); r.recordBounce();
         ok(r.plan(100,10)==null,"legacy second stops");
         c.ricochetCount=3; c.ricochetChance=80; c.ricochetChanceDecay=50;
         c.ricochetDamageDecay=20; c.ricochetSpeedDecay=25;
         r=new MSWRicochet(c);
         for(var i:int=0;i<3;i++)
         {
            var p:Object=r.plan(100,10,0.99);
            near(p.damage,100,"base damage "+i); near(p.speedScale,1,"base speed "+i); r.recordBounce();
         }
         ok(r.plan(100,10,0.8)==null,"80 percent boundary fails");
         p=r.plan(100,10,0.799); near(p.damage,80,"first extra damage"); near(p.speedScale,0.75,"first extra speed");
         r.recordBounce(); ok(r.plan(80,7.5,0.4)==null,"40 percent boundary fails");
         p=r.plan(80,7.5,0.399); near(p.damage,64,"second extra compounds"); r.recordBounce();
         ok(r.plan(64,5.625,0.2)==null,"20 percent boundary fails");
         ok(r.plan(64,5.625,0.199)!=null,"20 percent accepts lower roll");
         c.ricochetCount=0; c.ricochetChance=0; r=new MSWRicochet(c);
         ok(r.plan(100,10,0)==null,"zero base zero chance stops immediately");
         c.ricochetChance=100; c.ricochetChanceDecay=0; c.ricochetDamageDecay=0; c.ricochetSpeedDecay=0;
         r=new MSWRicochet(c);
         for(i=0;i<100;i++) { ok(r.plan(100,10,0.999)!=null,"hard cap permits "+(i+1)); r.recordBounce(); }
         ok(r.plan(100,10,0)==null,"hard cap refuses 101");
         c.ricochetChanceDecay=100; r=new MSWRicochet(c); ok(r.plan(100,10)!=null,"100 decay allows first extra"); r.recordBounce();
         ok(r.plan(100,10,0)==null,"100 decay stops next extra");
         c.ricochetDamageDecay=100; r=new MSWRicochet(c); ok(r.plan(100,10)==null,"zero resulting damage stops");
         c.ricochetDamageDecay=0; c.ricochetSpeedDecay=100; r=new MSWRicochet(c); ok(r.plan(100,10)==null,"zero speed stops");
         c.ricochetSpeedDecay=50; r=new MSWRicochet(c);
         ok(r.plan(100,1.9)==null,"subpixel speed stops"); ok(r.plan(100,2)!=null,"exact speed one allowed");
         ok(r.plan(0,10)==null,"zero incoming damage stops"); ok(r.plan(NaN,10)==null,"invalid damage stops");
         c=cfg(); c.ricochetCount=3; r=new MSWRicochet(c); c.ricochetCount=0;
         ok(r.plan(100,10)!=null,"config snapshot independent");
      }
      private function scene(c:MSWConfig):Object
      {
         var wall:Object={phis:1,phX1:100,phX2:140,phY1:0,phY2:400};
         var loc:Object={active:true,firstObj:null,spaceX:30,spaceY:30};
         loc.getAbsTile=function(x:Number,y:Number):* { return wall; };
         var owner:Object={player:true,loc:loc};
         var m:Object={cfg:c};
         return {loc:loc,owner:owner,wall:wall,engine:new MSWBullets(m),w:{loc:loc,gg:owner}};
      }
      private function initial(s:Object):Bullet { return new Bullet(s.owner,95,100); }
      private function hit(s:Object,b:Bullet):Bullet
      {
         b.X=105; b.Y=100; b.dx=Math.abs(b.dx); b.babah=true; b.liv=3;
         s.engine.process(s.w);
         return s.loc.firstObj === b ? null : s.loc.firstObj as Bullet;
      }
      private function chains():void
      {
         var c:MSWConfig=cfg(); c.ricochetCount=3; c.ricochetResetDistance=false;
         var s:Object=scene(c); var b:Bullet=initial(s); s.engine.process(s.w);
         c.ricochet=false; c.ricochetCount=0; // Already flying retains enabled state + all settings.
         for(var i:int=0;i<3;i++)
         {
            b=hit(s,b); ok(b!=null,"tracked chain bounce "+(i+1));
            near(b.damage,100,"chain base damage "+i); near(b.dx,-10,"chain reflection "+i);
            near(b.dist,123,"travel distance inherited "+i);
         }
         ok(hit(s,b)==null,"tracked chain fourth stops"); near(c.diag.ricBounce,3,"success counter exact");
         s.engine.process(s.w); near(c.diag.ricBounce,3,"dead body not processed twice");
         c=cfg(); c.ricochetCount=2; s=scene(c); b=initial(s); // first observed already dead
         b=hit(s,b); ok(b!=null,"birth frame impact bounces"); b=hit(s,b); ok(b!=null,"birth frame chain inherits count");
         ok(hit(s,b)==null,"birth frame chain stops at two");
         c=cfg(); c.ricochetCount=0; c.ricochetChance=100; c.ricochetDamageDecay=20; c.ricochetSpeedDecay=50;
         s=scene(c); b=initial(s); s.engine.process(s.w);
         b=hit(s,b); near(b.damage,80,"spawn damage decayed"); near(b.vel,5,"spawn velocity decayed"); near(b.dx,-5,"spawn vector decayed");
         b=hit(s,b); near(b.damage,64,"second spawn damage compounded"); near(b.vel,2.5,"second spawn speed compounded");
         b=hit(s,b); ok(b!=null,"1.25 speed survives"); ok(hit(s,b)==null,"0.625 speed ends chain");
         c=cfg(); c.ricochetCount=0; c.ricochetChance=100;
         s=scene(c); b=initial(s); s.engine.process(s.w);
         for(i=0;i<100;i++) { b=hit(s,b); ok(b!=null,"spawn chain cap permits "+(i+1)); }
         ok(hit(s,b)==null,"spawn chain cap stops 101"); near(c.diag.ricBounce,100,"spawn chain cap count");
         c=cfg(); c.ricochet=false; s=scene(c); b=initial(s); s.engine.process(s.w); c.ricochet=true;
         ok(hit(s,b)==null,"enabling cannot capture old bullet");
         c=cfg(); s=scene(c); b=initial(s); s.engine.process(s.w); s.wall.phis=0;
         ok(hit(s,b)==null,"destroyed wall not revived");
         c=cfg(); s=scene(c); b=initial(s); b.explRadius=100; s.engine.process(s.w);
         ok(hit(s,b)==null,"explosive bullet excluded");
         c=cfg(); s=scene(c); b=initial(s); b.owner.player=false; s.engine.process(s.w);
         ok(hit(s,b)==null,"enemy bullet excluded");
      }
      private function distanceModes():void
      {
         for each(var reset:Boolean in [true,false])
         {
            var c:MSWConfig=cfg(); c.ricochetCount=1; c.ricochetChance=100;
            c.ricochetResetDistance=reset;
            var s:Object=scene(c); var b:Bullet=initial(s);
            b.dist=5000; b.precision=480; b.antiprec=80; b.miss=0.2;
            s.engine.process(s.w); c.ricochetResetDistance=!reset;
            for(var i:int=0;i<3;i++)
            {
               b=hit(s,b); ok(b!=null,"distance mode bounce "+reset+"/"+i);
               near(b.dist,reset?0:5000+i*100,"distance snapshot base and extra "+reset+"/"+i);
               near(b.damage,100,"distance mode damage "+reset+"/"+i);
               ok(b.precision==480 && b.antiprec==80 && b.miss==0.2,"accuracy fields retained "+reset+"/"+i);
               b.dist+=100;
            }
         }
      }
      private function wallBoundaries():void
      {
         // Inclusive wall collision: reflecting an exact face hit must spawn outside it.
         for each(var face:Array in [[100,120,10,0],[140,120,-10,0],[120,100,0,10],[120,140,0,-10]])
         {
            var c:MSWConfig=cfg(); var s:Object=scene(c);
            s.wall.phY1=100; s.wall.phY2=140;
            var b:Bullet=new Bullet(s.owner,face[0]-face[2],face[1]-face[3]);
            b.dx=face[2]; b.dy=face[3]; s.engine.process(s.w);
            b.X=face[0]; b.Y=face[1]; b.babah=true; b.liv=3;
            s.engine.process(s.w);
            var next:Bullet=s.loc.firstObj as Bullet;
            ok(next!==b,"exact face continuation "+face);
            ok(next.X<100 || next.X>140 || next.Y<100 || next.Y>140,"exact face spawns outside wall "+face);
            near(next.damage,100,"exact face preserves damage "+face);
            near(next.dx,-face[2],"exact face dx "+face);
            near(next.dy,-face[3],"exact face dy "+face);
         }
      }
      private function configAndPanel():void
      {
         var old:SharedObject=SharedObject.getLocal("MSWConfig"); old.clear(); old.data.ricochet=true; old.flush();
         var c:MSWConfig=new MSWConfig(); c.load();
         ok(c.ricochet && c.ricochetCount==1 && c.ricochetChance==0,"old save migration");
         ok(c.ricochetResetDistance,"old save defaults to distance reset");
         c.ricochetCount=5; c.ricochetChance=80; c.ricochetChanceDecay=50; c.ricochetDamageDecay=20; c.ricochetSpeedDecay=25; c.ricochetResetDistance=false; c.save();
         c=new MSWConfig(); c.load();
         ok(c.ricochetCount==5 && c.ricochetChance==80 && c.ricochetChanceDecay==50 && c.ricochetDamageDecay==20 && c.ricochetSpeedDecay==25,"all five values round trip");
         ok(!c.ricochetResetDistance,"distance reset off persists");
         c.ricochetCount=99; c.ricochetChance=NaN; c.ricochetChanceDecay=Infinity; c.ricochetDamageDecay=-1; c.ricochetSpeedDecay=999; c.clamp();
         ok(c.ricochetCount==20 && c.ricochetChance==0 && c.ricochetChanceDecay==0 && c.ricochetDamageDecay==0 && c.ricochetSpeedDecay==100,"invalid values bounded");
         var m:Object={cfg:c}; var items:Array=MSWSettingsHub.buildMswItems(m);
         ok(items.length==18,"settings fit all 18 rows");
         for each(var it:Object in items) it["set"](it.def);
         c.save(); c=new MSWConfig(); c.load(); m.cfg=c;
         ok(c.ricochetCount==1 && c.ricochetChance==0 && c.ricochetChanceDecay==0 && c.ricochetDamageDecay==0 && c.ricochetSpeedDecay==0,"restore default contract persisted");
         ok(c.ricochetResetDistance,"restore default enables distance reset");
         var panel:MSWPanel=new MSWPanel(m); panel.handleKey(40); panel.handleKey(39);
         ok(c.ricochetCount==2,"F6 count increment");
         for(var i:int=0;i<4;i++) { panel.handleKey(40); panel.handleKey(39); }
         ok(c.ricochetChance==1 && c.ricochetChanceDecay==1 && c.ricochetDamageDecay==1 && c.ricochetSpeedDecay==1,"F6 percent fields increment by one");
         panel.handleKey(40); panel.handleKey(39); ok(!c.ricochetResetDistance,"F6 distance reset toggle");
         ok(items[6].suffix=="","distance check has no percent suffix");
         for(i=0;i<11;i++) panel.handleKey(40);
         panel.handleKey(39); ok(!c.dashKeepPose,"F6 last row reachable");
         panel.handleKey(40); panel.handleKey(39); ok(c.ricochet,"F6 wraps to first row");
      }
      private function finish(result:String, code:int):void
      {
         report += result + "\n"; trace(report);
         var fileCls:Class=getDefinitionByName("flash.filesystem.File") as Class;
         var streamCls:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var f:*=fileCls["applicationStorageDirectory"].resolvePath("results.txt");
         var fs:*=new streamCls(); fs.open(f,"write"); fs.writeUTFBytes(report); fs.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
