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
            ok(!migrated.smartSmooth && migrated.smartSmoothing==50,"old config adds disabled smooth mode and its default amount");
            c.smartSmoothing=NaN;c.clamp();near(c.smartSmoothing,50,"invalid smoothing uses default");
            c.smartSmoothing=-5;c.clamp();near(c.smartSmoothing,0,"smoothing minimum");
            c.smartSmoothing=103;c.clamp();near(c.smartSmoothing,100,"smoothing maximum");
            var items:Array=MSWSettingsHub.buildSmartItems({cfg:c});ok(items.length==16,"all sixteen adjustable settings available");
            for each(var item:Object in items) { item["set"](item.def); near(Number(item["get"]()),Number(item.def),"default "+item.key); }
            var fresh:MSWConfig=new MSWConfig(); c.smartEnabled=true;c.smartMultiLock=true;c.smartKeepOutOfSight=true;c.smartGrace=0.25;c.smartTurnRadius=30;c.smartHudSize=18;c.smartSmooth=true;c.smartSmoothing=75;c.save();fresh.load();
            ok(fresh.smartEnabled && fresh.smartMultiLock && fresh.smartKeepOutOfSight && fresh.smartGrace==0.25 && fresh.smartTurnRadius==30 && fresh.smartHudSize==18,"all smart settings persist");
            multiTests();
            ok(fresh.smartSmooth && fresh.smartSmoothing==75,"smooth mode and amount persist");
            smoothTests();
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
      private function smoothTests():void
      {
         var clearTile:Object={phis:0};
         var empty:Object={getAbsTile:function(x:Number,y:Number):* {return clearTile;}};
         var peaks:Array=[],turns:Array=[];
         for each(var amount:Number in [0,25,50,100])
         {
            var b:Object={X:0,Y:0,dx:20,dy:0,vel:20,loc:empty};
            var s:Object={smoothing:amount,remaining:5};
            var previous:Number=0,peak:Number=0,early:Number=0;
            for(var i:int=0;i<100;i++)
            {
               var old:Number=Math.atan2(b.dy,b.dx),ty:Number=i<40?300:-300;
               if(amount==0)MSWSmartRoute.steer(b,1800,ty,0.12,empty,0.2,0.5);
               else MSWSmartSmooth.steer(b,s,[{x:1800,y:ty}],0.12,0.2,0.5);
               var change:Number=MSWSmartRoute.angle(Math.atan2(b.dy,b.dx)-old);
               peak=Math.max(peak,Math.abs(change-previous));previous=change;
               if(i==4)early=Math.abs(Math.atan2(b.dy,b.dx));
               b.X+=b.dx*0.2;b.Y+=b.dy*0.2;
               if(Math.abs(b.vel-20)>0.000001 || Math.abs(change)>0.120001)throw new Error("smooth controller changed speed/turn ceiling");
            }
            peaks.push(peak);turns.push(early);
            ok(amount==0 || !(s.smoothUrgent>0),"ordinary distant pursuit needs no emergency at "+amount);
         }
         ok(peaks[2]<peaks[0]*0.3 && peaks[3]<peaks[2],"smooth controller reduces turn-rate jump when target reverses");
         ok(turns[0]>turns[1] && turns[1]>turns[2] && turns[2]>turns[3],"higher amount progressively softens initial turn response");
         ok(true,"all smoothing levels retain native speed and original turn ceiling");
         var urgent:Object={X:0,Y:0,dx:20,dy:0,vel:20,loc:empty};
         s={smoothing:100,remaining:0.05};
         MSWSmartSmooth.steer(urgent,s,[{x:10,y:10}],0.1,0.2,0.5);
         ok(s.smoothUrgent>0 && Math.abs(urgent.rot)<=0.100001,"near target and expiring budget allow bounded urgent correction");
         var wall:Object={phis:1,phX1:16,phX2:40,phY1:-10,phY2:10};
         var blocked:Object={getAbsTile:function(x:Number,y:Number):* {return x>=16 && x<=40 && y>=-10 && y<=10?wall:clearTile;}};
         urgent={X:0,Y:0,dx:20,dy:0,vel:20,loc:blocked};s={smoothing:100,remaining:2};
         MSWSmartSmooth.steer(urgent,s,[{x:200,y:0}],0.1,0.2,0.5);
         ok(s.smoothUrgent>0 && isFinite(urgent.dx) && Math.abs(urgent.rot)<=0.100001,"lookahead detects imminent wall without violating angular limit");
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
