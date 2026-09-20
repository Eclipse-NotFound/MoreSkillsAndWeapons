package
{
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.utils.Timer;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   public class SandySmartProbe
   {
      private var timer:Timer=new Timer(50),t:int=0,phase:int=0,since:int=0;
      private var m:*,w:*,weapon:*,target:*,log:String="";
      private var initial:Dictionary=new Dictionary(true),replayed:Dictionary=new Dictionary(true);
      private var frozen:int=0,budgetChecks:int=0,replaySteps:int=0;
      private var preExisting:*,preBudget:Number,heldChecks:int=0;
      public function SandySmartProbe(){timer.addEventListener("timer",tick);timer.start();}
      private function ok(v:Boolean,s:String):void{if(!v)throw new Error(s);log+="PASS "+s+"\n";}
      private function key():void{w.main.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,220));w.main.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,220));}
      private function tick(e:Event):void
      {
         try
         {
            t++;if(t%60==0)write("heartbeat.txt","t="+t+" phase="+phase+" frozen="+frozen+" replay="+replaySteps+"\n"+log);
            if(t>1100)throw new Error("timeout "+phase);
            m=MoreSkillsWeaponsMod.testInstance();w=MSWU.world();if(m==null || w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(w.verror.visible)throw new Error("game: "+w.verror.txt.text);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            if(phase==0)
            {
               if(t<160)return;
               var found:Boolean=false;for each(var page:Object in m.settings.getPages())if(page.modId=="sandevistan")found=true;
               if(!found)return;
               ok(found,"installed Sandevistan copy loaded and registered settings");
               if(w.pip.active)w.pip.onoff();w.onPause=false;w.godMode=false;w.catPause=false;w.gg.controlOn();
               for(var x:int=160;x<1000;x+=20)for(var y:int=80;y<400;y+=20){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null)tile.phis=0;}
               w.gg.setPos(220,320);w.gg.setVisPos();w.cam.moved=false;w.cam.vx=w.cam.vy=0;w.cam.scaleV=1;w.cam.celX=800;w.cam.celY=280;
               for(x=160;x<1000;x+=40){tile=w.loc.getAbsTile(x+1,321);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=320;tile.phY2=360;}
               var W:Class=MSWU.cls("fe.weapon.Weapon");weapon=W["create"](w.gg,"p9mm");weapon.hold=99;weapon.hp=weapon.maxhp;weapon.lvl=0;weapon.perslvl=0;
               w.gg.currentWeapon=weapon;w.gg.childObjs[0]=weapon;weapon.setPers(w.gg,w.gg.pers);weapon.addVisual();w.gg.setWeaponPos();
               var U:Class=MSWU.cls("fe.unit.Unit");target=new U();target.loc=w.loc;target.fraction=2;target.sost=1;target.hp=target.maxhp=1000000;
               target.isVis=true;target.blood=0;target.showNumbs=false;target.opt=null;target.X=800;target.Y=320;target.X1=785;target.X2=815;target.Y1=260;target.Y2=320;
               w.loc.units.push(target);
               m.cfg.smartEnabled=true;m.cfg.smartLife=2;m.cfg.ricochet=false;m.cfg.smartHold=3;m.cfg.smartDecay=5;
               m.smart.frame(w);m.smart.lock.target=target;m.smart.lock.strength=1;
               var B:Class=MSWU.cls("fe.weapon.Bullet");preExisting=new B(w.gg,250,240,null,true);preExisting.weap=weapon;preExisting.damage=20;preExisting.dx=2;preExisting.vel=2;
               m.smart.frame(w);ok(m.smart.snapshot(preExisting)!=null,"pre-stop smart bullet has its own budget");
               key();ok(w.onPause && !w.godMode,"real hotkey enters controllable time stop");phase=1;since=t;return;
            }
            var b:*=w.loc.firstObj;var s:Object;
            while(b!=null)
            {
               if(getQualifiedClassName(b)=="fe.weapon::Bullet" && b.owner===w.gg && (s=m.smart.snapshot(b))!=null)
               {
                  if(phase==1)
                  {
                     if(initial[b]!=null && !b.babah)
                     {
                        var prev:Object=initial[b];
                        if(b.liv==prev.liv){if(Math.abs(s.remaining-prev.remaining)>0.000001)throw new Error("frozen budget changed");frozen++;}
                        else if(b.liv<prev.liv){if(Math.abs(prev.remaining-s.remaining-(prev.liv-b.liv)/30)>0.000001)throw new Error("slow step budget mismatch");budgetChecks++;}
                     }
                     initial[b]={liv:b.liv,remaining:s.remaining};
                  }
                  else if(w.onPause && w.godMode && initial[b]==null)
                  {if(replayed[b]==null)log+="REPLAY born x="+b.X+" y="+b.Y+" dx="+b.dx+" dy="+b.dy+" damage="+b.damage+" target="+target.X+","+target.Y+"\n";replayed[b]=true;if(s.remaining<2 && b.precision==0 && b.miss==0)replaySteps++;}
               }
               b=b.nobj;
            }
            if(phase==1)
            {
               w.celX=800;w.celY=280;w.gg.celX=800;w.gg.celY=280;
               if(t-since==6 || t-since==16 || t-since==26){weapon.t_auto=0;weapon.t_attack=0;weapon.t_reload=0;ok(weapon.attack(),"actual pistol attack accepted");}
               if(t-since>=40)
               {
                  ok(frozen>0 && budgetChecks>0,"real time-stop frozen frames and slow physics budget agree");
                  preBudget=m.smart.snapshot(preExisting).remaining;
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
               ok(heldChecks>0,"pre-existing bullet replay budget verified");
               ok(target.hp<target.maxhp,"replayed smart bullets settle real target damage");
               ok(!w.godMode,"Sandevistan restores normal world state");
               finish("PASS smart Sandevistan integration",0);
            }
         }
         catch(err:*){finish("FAIL "+err+"\n"+err.getStackTrace()+"\ndiag="+(m==null?"":JSON.stringify(m.cfg.diag)),1);}
      }
      private function write(name:String,s:String):void{var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream");var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath(name),"write");f.writeUTFBytes(s);f.close();}
      private function finish(s:String,code:int):void{write("results.txt",log+s+"\n");timer.stop();MSWU.cls("flash.desktop.NativeApplication")["nativeApplication"].exit(code);}
   }
}
