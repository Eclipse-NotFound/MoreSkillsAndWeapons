package
{
   import flash.events.Event;
   import flash.system.ApplicationDomain;
   import flash.events.KeyboardEvent;
   import flash.events.UncaughtErrorEvent;
   import flash.utils.Timer;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   public class FocusSandyProbe
   {
      private var timer:Timer=new Timer(50),t:int=0,phase:int=0,since:int=0;
      private var m:*,w:*,weapon:*,target:*,log:String="";
      private var initial:Dictionary=new Dictionary(true),replayed:Dictionary=new Dictionary(true);
      private var frozen:int=0,budgetChecks:int=0,replaySteps:int=0;
      private var preExisting:*,preBudget:Number,heldChecks:int=0;
      private var slowCurves:int=0,replayCurves:int=0,maxKink:Number=0;
      private var multi:Boolean=false,adaptive:Boolean=false,targetList:Array=[],recordTargets:Array=[],replayTargets:Array=[];
      private var errorHooked:Boolean=false;
      private var domain:ApplicationDomain;
      public function FocusSandyProbe(d:ApplicationDomain){domain=d;multi=true;adaptive=true;timer.addEventListener("timer",tick);timer.start();}
      private function cls(name:String):Class{return domain.getDefinition(name) as Class;}
      private function ok(v:Boolean,s:String):void{if(!v)throw new Error(s);log+="PASS "+s+"\n";}
      private function key():void{w.main.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,220));w.main.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,220));}
      private function tick(e:Event):void
      {
         try
         {
            t++;if(t%60==0)write("heartbeat.txt","t="+t+" phase="+phase+" frozen="+frozen+" replay="+replaySteps+"\n"+log);
            if(t>1100)throw new Error("timeout "+phase);
            m=cls("MoreSkillsWeaponsMod")["testInstance"]();w=cls("fe.World")["w"];if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(!errorHooked)
            {
               errorHooked=true;
               w.main.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,function(error:UncaughtErrorEvent):void {
                  error.preventDefault();finish("FAIL uncaught host error: "+error.error+"\n"+(error.error is Error?Error(error.error).getStackTrace():""),1);
               });
               w.main.addEventListener(Event.ENTER_FRAME,observeReplay,false,-10000);
            }
            if(w.verror.visible)throw new Error("game: "+w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            if(phase==0)
            {
               // Wait for the test-only automatic Pip opening to finish first.
               if(t<160 || m.cfg.diag.frames<600)return;
               var pages:Array=("api" in m.settings) && m.settings.api!=null ? m.settings.api.getPages() : m.settings.getPages();
               var found:Boolean=false;for each(var page:Object in pages)if(page.modId=="sandevistan")found=true;
               if(!found)return;
               ok(found,"installed Sandevistan copy loaded and registered settings");
               if(w.pip.active)w.pip.onoff();w.onPause=false;w.godMode=false;w.catPause=false;w.gg.controlOn();
               for(var x:int=160;x<1000;x+=20)for(var y:int=80;y<400;y+=20){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null)tile.phis=0;}
               w.gg.setPos(220,320);w.gg.setVisPos();w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.cam.celX=800;w.cam.celY=280;
               for(x=160;x<1000;x+=40){tile=w.loc.getAbsTile(x+1,321);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=320;tile.phY2=360;}
               var W:Class=cls("fe.weapon.Weapon");weapon=W["create"](w.gg,"p9mm");weapon.hold=99;weapon.hp=weapon.maxhp;weapon.lvl=0;weapon.perslvl=0;
               w.gg.currentWeapon=weapon;w.gg.childObjs[0]=weapon;weapon.setPers(w.gg,w.gg.pers);weapon.addVisual();w.gg.setWeaponPos();
               var U:Class=cls("fe.unit.Unit");target=new U();target.loc=w.loc;target.fraction=2;target.sost=1;target.hp=target.maxhp=1000000;
               target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;target.X=800;target.Y=320;target.X1=785;target.X2=815;target.Y1=260;target.Y2=320;
               w.loc.units.push(target);
               m.cfg.smartEnabled=true;m.cfg.smartTurnRadius=30;m.cfg.smartLife=2;m.cfg.ricochet=false;m.cfg.smartHold=3;m.cfg.smartDecay=5;
               m.cfg.smartAdaptiveRadius=adaptive;m.cfg.smartMinTurnRadius=10;
               targetList=[target];
               if(multi)
               {
                  for(var targetIndex:int=0;targetIndex<2;targetIndex++)
                  {
                     var other:*=new U();other.loc=w.loc;other.fraction=2;other.sost=1;other.hp=other.maxhp=1000000;
                     other.isVis=true;other.blood=0;other.showNumbs=false;other.opt=null;other.X=750-targetIndex*70;other.Y=220-targetIndex*80;
                     other.X1=other.X-15;other.X2=other.X+15;other.Y1=other.Y-60;other.Y2=other.Y;
                     w.loc.units.push(other);targetList.push(other);
                  }
               }
               m.cfg.smartFocus=true;m.cfg.smartFocusRadius=48;m.cfg.smartMultiLock=multi;m.cfg.smartKeepOutOfSight=multi;m.smart.frame(w);
               if(multi)m.smart.multiLock.advance(targetList,targetList,m.cfg.smartAcquire,m.cfg);
               else {m.smart.lock.target=target;m.smart.lock.strength=1;}
               var B:Class=cls("fe.weapon.Bullet");preExisting=new B(w.gg,250,240,null,true);preExisting.weap=weapon;preExisting.damage=20;preExisting.dx=2;preExisting.vel=2;
               m.smart.frame(w);ok(m.smart.snapshot(preExisting)!=null,"pre-stop smart bullet has its own budget");
               key();ok(w.onPause && !w.godMode,"real hotkey enters controllable time stop");phase=1;since=t;return;
            }
            var b:*=w.loc.firstObj;var s:Object;
            while(b!=null)
            {
               if(getQualifiedClassName(b)=="fe.weapon::Bullet" && b.owner===w.gg && (s=m.smart.snapshot(b))!=null)
               {
                  if((!multi || b===preExisting) && s.turnRadius!=30)throw new Error("recorded/replayed shot lost radius snapshot");
                  if(s.motionPath!=null && s.motionPath.length>2)
                  {
                     var pts:Array=s.motionPath;var firstAngle:Number=Math.atan2(pts[1].y-pts[0].y,pts[1].x-pts[0].x);
                     var lastAngle:Number=firstAngle;
                     for(var k:int=2;k<pts.length;k++)
                     {
                        var a:Number=Math.atan2(pts[k].y-pts[k-1].y,pts[k].x-pts[k-1].x);
                        maxKink=Math.max(maxKink,Math.abs(cls("MSWSmartRoute")["angle"](a-lastAngle)));lastAngle=a;
                     }
                     if(Math.abs(cls("MSWSmartRoute")["angle"](lastAngle-firstAngle))>0.0001)
                     {if(phase==1)slowCurves++;else if(initial[b]==null)replayCurves++;}
                  }
                  if(phase==1)
                  {
                     if(multi && initial[b]==null && b!==preExisting)recordTargets.push({unit:s.target,radius:s.turnRadius,adaptive:s.adaptive,minimum:s.minTurnRadius,x:b.begx,y:b.begy});
                     if(initial[b]!=null && !b.babah)
                     {
                        var prev:Object=initial[b];
                        if(b.liv==prev.liv){if(Math.abs(s.remaining-prev.remaining)>0.000001)throw new Error("frozen budget changed");frozen++;}
                        else if(b.liv<prev.liv){if(Math.abs(prev.remaining-s.remaining-(prev.liv-b.liv)/30)>0.000001)throw new Error("slow step budget mismatch");budgetChecks++;}
                     }
                     initial[b]={liv:b.liv,remaining:s.remaining};
                  }
                  else if(w.onPause && w.godMode && initial[b]==null)
                  {observeReplay();if(s.remaining<2 && b.precision==0 && b.miss==0)replaySteps++;}
               }
               b=b.nobj;
            }
            if(phase==1)
            {
               var aimed:*=targetList[t-since>=26?1:0];w.celX=w.gg.celX=aimed.X;w.celY=w.gg.celY=(aimed.Y1+aimed.Y2)/2;w.cam.celX=w.celX*w.cam.scaleV+w.cam.vx;w.cam.celY=w.celY*w.cam.scaleV+w.cam.vy;
               if(t-since==6 || t-since==16 || t-since==26)
               {
                  if(multi)
                  {
                     m.cfg.smartTurnRadius=30+int((t-since-6)/10)*10;
                     if(adaptive)m.cfg.smartMinTurnRadius=10+int((t-since-6)/10)*10;
                     log+="RECORD mode="+m.cfg.smartMultiLock+" locks="+m.smart.multiLock.locks.length+" weapon="+w.gg.currentWeapon.id+" active="+cls("MSWU")["inGameplay"](w)+" control="+w.gg.ggControl+"\n";
                     for each(var watched:* in targetList)log+="TARGET x="+watched.X+" allowed="+m.smart.targetAllowed(watched,w)+" listed="+w.loc.units.indexOf(watched)+" lock="+(m.smart.multiLock.stateFor(watched)==null?"missing":m.smart.multiLock.stateFor(watched).strength)+"\n";
                  }
                  weapon.t_auto=0;weapon.t_attack=0;weapon.t_reload=0;ok(weapon.attack(),"actual pistol attack accepted");
               }
               if(t-since>=40)
               {
                  ok(frozen>0 && budgetChecks>0,"real time-stop frozen frames and slow physics budget agree");
                  preBudget=m.smart.snapshot(preExisting).remaining;
                  m.cfg.smartTurnRadius=200; // Replay must use the recorded 30%, not current settings.
                  if(adaptive){m.cfg.smartAdaptiveRadius=false;m.cfg.smartMinTurnRadius=200;}
                  m.cfg.smartFocus=false;m.cfg.smartFocusRadius=0;if(multi){m.cfg.smartMultiLock=false;m.smart.multiLock.clear();}
                  key();ok(w.onPause && w.godMode,"real hotkey starts Sandevistan replay");phase=2;since=t;
               }
            }
            else if(phase==2 && w.onPause)
            {ok(Math.abs(m.smart.snapshot(preExisting).remaining-preBudget)<0.000001,"pinned original keeps budget during replay");heldChecks++;}
            else if(phase==2 && !w.onPause)
            {
               ok(m.cfg.diag.smartReplayStart>0,"smart adapter observes actual replay transition");
               ok(m.cfg.diag.smartReplayMatched>=3,"recreated shots recover their original lock snapshots");
               ok(!(m.cfg.diag.smartReplayUnmatched>0),"no recreated shot loses its recording match");
               ok(replaySteps>0,"actual replay steps curve recreated accurate bullets");
               ok(m.cfg.smartTurnRadius==200,"replay retained recorded 30% radius after settings changed to 200%");
               if(multi)
               {
                  ok(recordTargets.length==3 && recordTargets[0].unit===targetList[0] && recordTargets[1].unit===targetList[0] && recordTargets[2].unit===targetList[1],"real time-stop focuses first two shots on A then switches only new shot to B");
                  var match:Boolean=replayTargets.length==recordTargets.length;
                  for(var ri:int=0;ri<recordTargets.length;ri++)
                  {
                     var record:Object=recordTargets[ri],replay:Object=ri<replayTargets.length?replayTargets[ri]:null;
                     log+="SNAPSHOT shot="+ri+" muzzle="+record.x+","+record.y+" target="+record.unit.X+","+record.unit.Y+" radius="+record.radius+" replay="+(replay==null?"missing":replay.unit.X+","+replay.unit.Y+" radius="+replay.radius)+"\n";
                     if(replay==null || replay.unit!==record.unit || replay.radius!=record.radius)match=false;
                     if(adaptive && (replay==null || !replay.adaptive || replay.minimum!=record.minimum || record.minimum!=10+ri*10))match=false;
                     if(adaptive)log+="ADAPTIVE snapshot="+record.adaptive+","+record.minimum+" replay="+(replay==null?"missing":replay.adaptive+","+replay.minimum)+"\n";
                  }
                  ok(match,"replay restores each recorded target after multi mode and current locks are cleared");
                  if(adaptive)ok(match && !m.cfg.smartAdaptiveRadius && m.cfg.smartMinTurnRadius==200,"real replay retains per-shot adaptive mode and 10/20/30 minimum radii after settings are disabled");
               }
               ok(heldChecks>0,"pre-existing bullet replay budget verified");
               ok(target.hp<target.maxhp,"replayed smart bullets settle real target damage");
               ok(!w.godMode,"Sandevistan restores normal world state");
               ok(slowCurves>0 && replayCurves>0 && maxKink<=Math.PI/60+0.00001,"real slow/replay trajectories use adaptive native substeps; peak kink="+(maxKink*180/Math.PI));
               finish("PASS smart Sandevistan integration",0);
            }
         }
         catch(err:*){finish("FAIL "+err+"\n"+err.getStackTrace()+"\ndiag="+(m==null?"":JSON.stringify(m.cfg.diag)),1);}
      }
      private function observeReplay(e:Event=null):void
      {
         if(m==null || w==null || phase!=2 || !w.onPause || !w.godMode)return;
         var b:*=w.loc.firstObj;
         while(b!=null)
         {
            if(getQualifiedClassName(b)=="fe.weapon::Bullet" && b.owner===w.gg && initial[b]==null && replayed[b]==null)
            {
               var s:Object=m.smart.snapshot(b);
               if(s!=null)
               {
                  replayed[b]=true;
                  log+="REPLAY birth muzzle="+b.begx+","+b.begy+" target="+s.target.X+","+s.target.Y+" radius="+s.turnRadius+"\n";
                  if(multi)replayTargets.push({unit:s.target,radius:s.turnRadius,adaptive:s.adaptive,minimum:s.minTurnRadius,x:b.begx,y:b.begy});
               }
            }
            b=b.nobj;
         }
      }
      private function write(name:String,s:String):void{var F:Class=cls("flash.filesystem.File"),S:Class=cls("flash.filesystem.FileStream");var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath(name),"write");f.writeUTFBytes(s);f.close();}
      private function finish(s:String,code:int):void{write("results.txt",log+s+"\n");timer.stop();cls("flash.desktop.NativeApplication")["nativeApplication"].exit(code);}
   }
}
