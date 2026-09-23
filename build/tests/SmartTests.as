package
{
   import flash.display.Sprite;
   import flash.net.SharedObject;
   import flash.utils.getDefinitionByName;
   public class SmartTests extends Sprite
   {
      private var n:int=0;
      private var report:String="";
      private function ok(v:Boolean,s:String):void { if(!v)throw new Error(s); n++;report+="PASS "+s+"\n"; }
      private function near(a:Number,b:Number,s:String):void { ok(Math.abs(a-b)<0.00001,s+" got "+a); }
      public function SmartTests()
      {
         try
         {
            var c:MSWConfig=new MSWConfig(), l:MSWSmartLock=new MSWSmartLock();
            var a:Object={},b:Object={};
            ok(!c.smartEnabled,"new and migrated config defaults disabled");
            l.advance(a,false,0.3,c); near(l.progress,0.5,"half acquisition");
            l.advance(null,false,0.1,c); near(l.progress,0.5,"grace holds candidate");
            l.advance(null,false,0.2,c); near(l.progress,0.25,"retreat starts only after grace");
            l.advance(b,false,0.3,c); near(l.progress,0.5,"another candidate starts from zero");
            l.advance(b,false,0.3,c); ok(l.target===b && l.strength==1,"lock completes");
            l.advance(null,true,1,c); ok(l.target===b && l.strength==1,"reticle departure keeps visible target");
            l.advance(null,false,0.6,c); near(l.strength,1,"hold interval");
            l.advance(null,false,0.75,c); near(l.strength,0.5,"linear decay");
            l.advance(null,true,0.1,c); near(l.strength,0.75,"automatic gradual recovery");
            l.advance(null,false,0.6,c); near(l.strength,0.75,"new hold does not refill");
            l.advance(null,false,1.5,c); ok(l.target==null,"complete loss requires acquisition again");
            l.advance(a,false,0.6,c); l.advance(b,true,0.3,c); ok(l.target===a,"old lock retained during new acquisition");
            l.advance(b,true,0.3,c); ok(l.target===b,"switch only on completion");
            c.smartKeepOutOfSight=true;
            l.strength=0.5;
            l.advance(null,false,10,c);
            ok(l.target===b && l.strength==0.5 && l.lost==0,"existing unseen lock holds current strength indefinitely");
            l.advance(a,false,0.3,c);
            l.advance(null,false,c.smartGrace+c.smartRetreat+0.1,c);
            ok(l.target===b && l.candidate==null,"unseen new candidate still retreats while old lock persists");
            l.advance(null,true,0.2,c);near(l.strength,1,"sight restores a previously weakened held lock");
            c.smartKeepOutOfSight=false;
            l.advance(null,false,c.smartHold+c.smartDecay+0.1,c);
            ok(l.target==null,"turning the switch off resumes existing loss timer");
            c.smartTurn=NaN;c.smartLife=-2;c.smartRadius=205;c.smartGrace=0.149; c.clamp();
            near(c.smartTurn,1080,"bad numeric config fallback");near(c.smartLife,0.1,"positive guidance budget");near(c.smartRadius,200,"bounded search tolerance");near(c.smartGrace,0.15,"two decimal precision");
            c.smartTurnRadius=NaN;c.smartHudSize=NaN;c.clamp();
            near(c.smartTurnRadius,50,"new radius default is tighter");near(c.smartHudSize,24,"new HUD default is smaller");
            c.smartTurnRadius=-10;c.smartHudSize=999;c.clamp();
            near(c.smartTurnRadius,10,"radius lower bound");near(c.smartHudSize,80,"HUD upper bound");
            c.smartTurnRadius=999;c.smartHudSize=-1;c.clamp();
            near(c.smartTurnRadius,200,"radius upper bound");near(c.smartHudSize,12,"HUD lower bound");
            var legacy:SharedObject=SharedObject.getLocal("MSWConfig");legacy.clear();legacy.data.smartTurn=1440;legacy.data.smartEnabled=true;legacy.flush();
            var migrated:MSWConfig=new MSWConfig();migrated.load();
            ok(migrated.smartTurn==1440 && migrated.smartEnabled && migrated.smartTurnRadius==50 && migrated.smartHudSize==24 && !migrated.smartKeepOutOfSight,"old config preserves choices and adds new defaults");
            var items:Array=MSWSettingsHub.buildSmartItems({cfg:c});ok(items.length==13,"all thirteen adjustable settings available");
            for each(var item:Object in items) { item["set"](item.def); near(Number(item["get"]()),Number(item.def),"default "+item.key); }
            var fresh:MSWConfig=new MSWConfig(); c.smartEnabled=true;c.smartKeepOutOfSight=true;c.smartGrace=0.25;c.smartTurnRadius=30;c.smartHudSize=18;c.save();fresh.load();
            ok(fresh.smartEnabled && fresh.smartKeepOutOfSight && fresh.smartGrace==0.25 && fresh.smartTurnRadius==30 && fresh.smartHudSize==18,"all smart settings persist");
            var wall:Object={phis:1,phX1:90,phX2:130,phY1:40,phY2:120};
            var loc:Object={getAbsTile:function(x:Number,y:Number):* {return x>=90 && x<=130 && y>=40 && y<=120?wall:{phis:0};}};
            ok(!MSWSmartRoute.clear(loc,0,80,210,80),"wall blocks direct shot");
            var path:Array=MSWSmartRoute.find(loc,0,80,210,80);ok(path.length>1,"bounded path around box");
            var x:Number=0,y:Number=80;
            for each(var p:Object in path) {ok(MSWSmartRoute.clear(loc,x,y,p.x,p.y),"route segment clears physical obstacle");x=p.x;y=p.y;}
            var sealed:Object={getAbsTile:function(x:Number,y:Number):* {return {phis:1,phX1:-1000,phX2:1000,phY1:-1000,phY2:1000};}};
            ok(MSWSmartRoute.find(sealed,0,0,100,0).length==0,"enclosed target route fails finitely");
            var empty:Object={getAbsTile:function(x:Number,y:Number):* {return {phis:0};}};
            var bullet:Object={X:0,Y:0,dx:20,dy:0,vel:20};
            MSWSmartRoute.steer(bullet,-100,0,Math.PI/6,empty);
            near(bullet.rot,Math.PI/6,"U turn respects angular limit");near(bullet.vel,20,"turn preserves bullet speed");
            for(var i:int=0;i<5;i++)MSWSmartRoute.steer(bullet,-100,0,Math.PI/6,empty);
            near(Math.abs(bullet.rot),Math.PI,"full U turn possible");
            var soft:Object={X:0,Y:0,dx:20,dy:0,vel:20},tight:Object={X:0,Y:0,dx:20,dy:0,vel:20};
            MSWSmartRoute.steer(soft,500,300,1,empty,0.1,1);
            MSWSmartRoute.steer(tight,500,300,2,empty,0.1,0.5);
            near(tight.rot,soft.rot*2,"half radius doubles unsaturated pursuit curvature");
            near(tight.vel,soft.vel,"radius adjustment preserves speed");
            finish("PASS "+n+" assertions",0);
         }
         catch(e:*) { finish("FAIL "+e+"\n"+e.getStackTrace(),1); }
      }
      private function finish(s:String,code:int):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class, S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath("results.txt"),"write");f.writeUTFBytes(report+s+"\n");f.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
