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
         trace("SmartTests: start");
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
            ok(migrated.smartTurn==1440 && migrated.smartEnabled && migrated.smartTurnRadius==50 && migrated.smartHudSize==24 && !migrated.smartKeepOutOfSight && !migrated.smartMultiLock,"old config preserves choices and adds new defaults");
            ok(!migrated.smartAdaptiveRadius && migrated.smartMinTurnRadius==10,"old config adds disabled adaptation and minimum radius");
            legacy.data.smartSmooth=true;legacy.data.smartSmoothing=75;legacy.data.smartTurnRadius=160;legacy.flush();
            migrated=new MSWConfig();migrated.load();
            ok(migrated.smartAdaptiveRadius && migrated.smartMinTurnRadius==10 && migrated.smartTurnRadius==160,"legacy enabled state migrates without converting smoothing amount");
            legacy.data.smartAdaptiveRadius=false;legacy.flush();migrated.load();
            ok(!migrated.smartAdaptiveRadius,"explicit new off overrides old smooth on");
            c.smartMinTurnRadius=NaN;c.clamp();near(c.smartMinTurnRadius,10,"invalid minimum uses default");
            c.smartMinTurnRadius=-5;c.clamp();near(c.smartMinTurnRadius,10,"minimum radius lower bound");
            c.smartMinTurnRadius=999;c.clamp();near(c.smartMinTurnRadius,200,"minimum radius upper bound");
            var items:Array=MSWSettingsHub.buildSmartItems({cfg:c});ok(items.length==18,"all eighteen adjustable settings available");
            for each(var item:Object in items) { item["set"](item.def); near(Number(item["get"]()),Number(item.def),"default "+item.key); }
            var fresh:MSWConfig=new MSWConfig(); c.smartEnabled=true;c.smartMultiLock=true;c.smartKeepOutOfSight=true;c.smartGrace=0.25;c.smartTurnRadius=30;c.smartHudSize=18;c.smartAdaptiveRadius=true;c.smartMinTurnRadius=20;c.save();fresh.load();
            ok(fresh.smartEnabled && fresh.smartMultiLock && fresh.smartKeepOutOfSight && fresh.smartGrace==0.25 && fresh.smartTurnRadius==30 && fresh.smartHudSize==18,"all smart settings persist");
            multiTests();
            SmartFocusChecks.run(ok);
            ok(fresh.smartAdaptiveRadius && fresh.smartMinTurnRadius==20,"adaptive mode and minimum radius persist");
            adaptiveTests();
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
            SmartGlassChecks.run(ok);
            finish("PASS "+n+" assertions",0);
         }
         catch(e:*) { finish("FAIL "+e+"\n"+e.getStackTrace(),1); }
      }
      private function multiTests():void
      {
         var cfg:MSWConfig=new MSWConfig(),multi:MSWSmartMultiLock=new MSWSmartMultiLock();
         var a:Object={},b:Object={},c:Object={},d:Object={};
         var all:Array=[a,b,c];
         multi.advance(all,[a,b,b],0.3,cfg);
         ok(multi.locks.length==2 && multi.stateFor(c)==null,"only visible targets start; repeated units do not duplicate");
         near(multi.stateFor(a).progress,0.5,"first target acquires in parallel");
         near(multi.stateFor(b).progress,0.5,"second target acquires in parallel");
         ok(multi.pick()==null,"unfinished locks receive no projectile");
         multi.advance(all,all,0.3,cfg);
         ok(multi.stateFor(a).target===a && multi.stateFor(b).target===b,"two visible targets finish together");
         near(multi.stateFor(c).progress,0.5,"later arrival has its own clock");
         ok(multi.pick().target===a && multi.pick().target===b && multi.pick().target===a,"rotation skips unfinished candidate");
         multi.clear();multi.advance(all,all,0.6,cfg);
         var order:Boolean=true;
         for(var i:int=0;i<9;i++) if(multi.pick().target!==all[i%3])order=false;
         ok(order,"consecutive bullets and pellets rotate evenly over all locks");
         ok(multi.pick().target===a,"rotation continues after a volley");
         multi.advance([b,c],[b,c],0,cfg);
         ok(multi.stateFor(a)==null && multi.pick().target===b,"removing previous target does not skip the next target");
         ok(multi.pick(function(u:*):Boolean{return u!==c;}).target===b,"death between frames is skipped before assignment");
         ok(multi.pick(function(u:*):Boolean{return false;})==null,"no valid target ends selection finitely");
         multi.clear();multi.advance(all,all,0.6,cfg);
         multi.advance(all,[a,c],cfg.smartHold+cfg.smartDecay/2,cfg);
         near(multi.stateFor(b).strength,0.5,"occluded target decays independently");
         near(multi.stateFor(a).strength,1,"visible target stays fully locked");
         cfg.smartKeepOutOfSight=true;
         multi.advance(all,[a,c],20,cfg);
         near(multi.stateFor(b).strength,0.5,"hold switch preserves each unseen lock's current strength");
         multi.advance([a,b,c,d],[a,c,d],0.3,cfg);
         multi.advance([a,b,c,d],[a,c],cfg.smartGrace+cfg.smartRetreat+0.1,cfg);
         ok(multi.stateFor(d)==null,"hold switch never preserves an unfinished new target");
         cfg.smartKeepOutOfSight=false;
         multi.advance(all,[a,c],cfg.smartHold+cfg.smartDecay,cfg);
         ok(multi.stateFor(b)==null && multi.locks.length==2,"expired lock removed without touching other targets");
         multi.advance([a,c],[],cfg.smartHold+cfg.smartDecay,cfg);
         ok(multi.locks.length==0 && multi.pick()==null,"all expired targets release references");
         all=[];for(i=0;i<256;i++)all.push({});
         multi.advance(all,all,0.6,cfg);order=true;
         for(i=0;i<all.length;i++)if(multi.pick().target!==all[i])order=false;
         ok(multi.locks.length==256 && order,"all visible targets retained without an artificial target cap");
         multi.clear();ok(multi.locks.length==0 && multi.pick()==null,"mode or world reset clears all locks and rotation");
      }
      private function adaptiveTests():void
      {
         var tile:Object={phis:0},loc:Object={getAbsTile:function(x:Number,y:Number):*{return tile;}};
         var b:Object={X:0,Y:0,dx:20,dy:0,ddx:0,ddy:0,liv:100,loc:loc};
         var u:Object={X1:588,X2:612,Y1:10,Y2:50,dx:0,dy:0};
         var path:Array=[{x:600,y:30}],s:Object={target:u,remaining:2,turnRadius:200,minTurnRadius:10};
         var before:String=JSON.stringify(path),x:Number=b.X,dx:Number=b.dx;
         var prediction:Object=MSWAdaptiveRadius.evaluate(b,s,path,Math.PI/5,2);
         ok(prediction.hit,"normal large radius can reach the open target: "+prediction.status);
         near(MSWAdaptiveRadius.select(b,s,path,Math.PI/5),2,"feasible normal radius is retained");
         ok(JSON.stringify(path)==before && b.X==x && b.dx==dx,"prediction does not move real projectile or mutate route");
         u.X1=188;u.X2=212;u.Y1=80;u.Y2=120;path=[{x:200,y:100}];
         s={target:u,remaining:0.6,turnRadius:200,minTurnRadius:10};
         prediction=MSWAdaptiveRadius.evaluate(b,s,path,Math.PI/60,2);
         ok(!prediction.hit && prediction.status!="unknown","wide slow turn misses before guidance ends");
         var radius:Number=MSWAdaptiveRadius.select(b,s,path,Math.PI/60);
         ok(radius<2 && radius>0.1,"early rescue chooses an intermediate radius, not always minimum: "+radius);
         ok(MSWAdaptiveRadius.evaluate(b,s,path,Math.PI/60,radius).hit,"selected rescue reaches predicted target area");
         s={target:u,remaining:0.6,turnRadius:200,minTurnRadius:180};
         radius=MSWAdaptiveRadius.select(b,s,path,Math.PI/60);
         ok(radius>=1.8 && radius<=2,"unreachable target never overrides user minimum");
         s={target:u,remaining:2,turnRadius:50,minTurnRadius:200};
         near(MSWAdaptiveRadius.select(b,s,path,Math.PI/5),0.5,"minimum above normal never widens ordinary radius");
         // Native-resolution forecasts need more samples since v1.14.2. Keep
         // recovery's intermediate radius within the finite prediction budget.
         u.X1=108;u.X2=132;u.Y1=10;u.Y2=50;path=[{x:120,y:30}];
         s={target:u,remaining:2,turnRadius:200,minTurnRadius:10,radiusNow:50};
         ok(MSWAdaptiveRadius.evaluate(b,s,path,Math.PI/5,0.6).hit,"recovery fixture has a verified safe intermediate radius");
         near(MSWAdaptiveRadius.select(b,s,path,Math.PI/5),0.5,"first safe forecast does not immediately restore radius");
         s.radiusAge=0;radius=MSWAdaptiveRadius.select(b,s,path,Math.PI/5);
         ok(radius>0.5 && radius<2,"stable recovery grows gradually");
         s.radiusAge=0;s.radiusNow=30;s.radiusStable=4;MSWAdaptiveRadius.reset(s);
         ok(s.radiusNow==200 && s.radiusAge==0 && s.radiusStable==0,"ricochet resets prediction and recovery history");
         ok(MSWAdaptiveRadius.intersects(0,0,200,0,90,-5,110,5),"swept target test catches fast crossings");
         ok(!MSWAdaptiveRadius.intersects(0,6,200,6,90,-5,110,5),"swept target test rejects a near miss");
         b.liv=1000;s.remaining=8;u.X1=99990;u.X2=100010;path=[{x:100000,y:30}];
         ok(MSWAdaptiveRadius.evaluate(b,s,path,Math.PI/5,2).status=="unknown","forecast budget exhaustion is not proof of a miss");
      }
      private function finish(s:String,code:int):void
      {
         trace(s);
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class, S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath("results.txt"),"write");f.writeUTFBytes(report+s+"\n");f.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
