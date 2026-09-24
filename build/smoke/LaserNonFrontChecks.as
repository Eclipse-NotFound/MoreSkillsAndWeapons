package
{
   import flash.system.ApplicationDomain;
   import flash.display.BitmapData;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.events.MouseEvent;
   /** TEST ONLY: loads production definitions; expected boundaries are independent. */
   public class LaserNonFrontChecks
   {
      public static function settings(domain:ApplicationDomain,w:*,m:*,Legacy:Class,ok:Function,savePNG:Function):void
      {
         var Config:Class=domain.getDefinition("MSWConfig") as Class,c:*=m.cfg,page:Object,items:Object={};
         for each(var p:Object in m.settings.api.getPages())if(p.modId=="msw-laser")page=p;
         for each(var item:Object in page.items)items[item.key]=item;
         ok(!c.laserNonFront && c.laserNonFrontRatio==50 && items.laserNonFront.def===false && items.laserNonFrontRatio.def==50,"non-front config and UI default to disabled / 50 percent");
         items.laserNonFrontRatio.set(70);items.laserNonFront.set(true);page.onPageClose();
         var fresh:*=new Config();fresh.load();
         ok(fresh.laserNonFront && fresh.laserNonFrontRatio==70,"non-front switch and ratio persist together");
         if(Legacy!=null)
         {
            var old:*=new Legacy();old.load();old.laserDuration=7;old.save();fresh=new Config();fresh.load();
            ok(fresh.laserNonFront && fresh.laserNonFrontRatio==70 && fresh.laserDuration==7,"actual previous SWF save preserves unknown non-front settings on re-upgrade");
         }
         c.laserNonFrontRatio=NaN;c.clamp();ok(c.laserNonFrontRatio==50,"invalid non-front ratio falls back to 50");
         items.laserNonFrontRatio.set(-1);ok(c.laserNonFrontRatio==0,"non-front ratio accepts zero lower bound");
         items.laserNonFrontRatio.set(101);ok(c.laserNonFrontRatio==100,"non-front ratio caps at 100");
         items.laserNonFrontRatio.set(53);ok(c.laserNonFrontRatio==55,"non-front ratio uses five-point steps");
         for each(item in page.items)item.set(item.def);page.onPageClose();
         m.panel.toggleOverlay();for(var i:int=0;i<5;i++)m.panel.handleKey(9);
         for(i=0;i<12;i++)m.panel.handleKey(40);m.panel.handleKey(13);
         m.panel.handleKey(40);m.panel.handleKey(37);m.panel.update(w);
         var image:BitmapData=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,false,0);image.draw(w.main.stage);savePNG(image,"nonfront-f6.png");image.dispose();
         m.panel.toggleOverlay();m.panel.update(w);fresh=new Config();fresh.load();
         ok(fresh.laserNonFront && fresh.laserNonFrontRatio==45,"F6 scroll reaches both new controls and persists them");
         if(!w.pip.active)w.pip.onoff(5);if(!m.panel.tabActive())m.panel.tabToggle(w);m.settings.api.selectPage("msw-laser");
         var row:*=find(w.main,"laserNonFront");ok(row!=null && row.settingsSc.selected,"Pip renders the shared non-front checkbox");
         row.settingsSc.selected=false;row.settingsSc.dispatchEvent(new Event(Event.CHANGE));
         fresh=new Config();fresh.load();ok(!fresh.laserNonFront && fresh.laserNonFrontRatio==45,"Pip switch saves immediately without resetting ratio");
         row=find(w.main,"laserNonFrontRatio");ok(row!=null,"Pip renders non-front range slider");
         row.settingsSc.scrollPosition=15;row.settingsSc.dispatchEvent(new Event(Event.SCROLL));
         ok(c.laserNonFrontRatio==75,"Pip slider adjusts non-front ratio to 75 percent");
         page.onPageClose();fresh=new Config();fresh.load();ok(fresh.laserNonFrontRatio==75,"Pip page close saves non-front ratio");
         find(w.main,"SettingsReset",true).dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
         fresh=new Config();fresh.load();
         ok(!fresh.laserNonFront && fresh.laserNonFrontRatio==50 && fresh.laserBodyRadius==60 && fresh.laserAssistFloor==50,"Pip reset restores direction and range defaults together");
         image=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,false,0);image.draw(w.main.stage);savePNG(image,"nonfront-pip.png");image.dispose();
         w.pip.onoff();w.onPause=true;m.panel.update(w);
      }
      private static function find(o:*,key:String,byName:Boolean=false):*
      {
         if(byName && o.name==key)return o;
         try {if(!byName && o.settingsItem!=null && o.settingsItem.key==key)return o;}catch(ignore:*){}
         if(o is DisplayObjectContainer)for(var i:int=0;i<o.numChildren;i++){var r:*=find(o.getChildAt(i),key,byName);if(r!=null)return r;}
         return null;
      }
      private static function pose(u:*,x:Number,y:Number,facing:int=1):void
      {
         u.fraction=2;u.hp=u.maxhp;u.sost=1;u.disabled=u.trigDis=u.npc=u.noAgro=false;
         u.storona=facing;u.shithp=0;u.stun=u.t_emerg=0;u.isVis=true;u.invis=false;
         u.dx=u.dy=0;u.stay=true;u.setPos(x,y);u.actions();u.animate();u.setVisPos();u.vis.visible=true;
      }
      private static function aim(w:*,x:Number,y:Number):void {w.celX=w.gg.celX=x;w.celY=w.gg.celY=y;}
      public static function combat(domain:ApplicationDomain,w:*,m:*,wp:*,u:*,ok:Function,savePNG:Function):void
      {
         var G:Class=domain.getDefinition("MSWLaserGeometry") as Class,c:*=m.cfg;
         c.laserNonFront=true;c.laserNonFrontRatio=50;c.laserAssist=true;c.laserDebug=false;
         w.gg.setPos(240,320);w.gg.storona=1;w.loc.units=[w.gg,u];w.loc.objs=[];
         for each(var x:Number in [380,650,1050])for each(var v:Array in [[0,0],[10,0],[0,-10],[6,8]])
         {
            m.laser.clear();pose(u,x,320);w.gg.dx=v[0];w.gg.dy=v[1];aim(w,u.X,u.Y2-4);
            for(var settle:int=0;settle<15;settle++){w.gg.setWeaponPos();wp.step();}
            wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
            var hp:Number=u.hp,shots:Number=c.diag.laserShots;wp.attack();wp.step();
            ok(m.laser.blind.remaining(u)==6 && u.hp==hp && wp.hold==10 && c.diag.laserShots==shots+1,"native rear body shot blinds without damage x="+x+" speed="+v);
         }
         m.laser.clear();pose(u,600,320);wp.bulX=300;wp.bulY=260;
         for each(var sample:Array in [[0,0,30],[5,0,22.5],[10,0,15],[0,-10,15],[6,8,15],[30,40,15]])
         {
            w.gg.dx=sample[0];w.gg.dy=sample[1];aim(w,u.X2+sample[2],u.Y2-5);
            ok(G["assist"](w,wp,c)===u,"rear inclusive halo boundary "+sample);
            aim(w,u.X2+sample[2]+0.01,u.Y2-5);ok(G["assist"](w,wp,c)==null,"rear outside halo boundary "+sample);
            aim(w,u.X,u.Y2-1);ok(G["assist"](w,wp,c)===u,"rear direct body unaffected by speed "+sample);
         }
         w.gg.dx=w.gg.dy=0;c.laserNonFrontRatio=0;aim(w,u.X2,u.Y2);
         ok(G["assist"](w,wp,c)===u,"zero rear ratio preserves direct body edge");
         aim(w,u.X2+0.01,u.Y2);ok(G["assist"](w,wp,c)==null,"zero rear ratio removes only outside halo");
         pose(u,600,320,-1);aim(w,u.X2+60,u.Y2-5);
         ok(G["assist"](w,wp,c)===u,"front halo stays 60 even with rear ratio zero");
         pose(u,600,320);c.laserNonFrontRatio=100;
         ok(G["assist"](w,wp,c)===u,"100 percent rear ratio matches front range");
         c.laserNonFrontRatio=50;c.laserBodyRadius=80;aim(w,u.X2+40,u.Y2-5);
         ok(G["assist"](w,wp,c)===u,"rear halo follows customized front radius");c.laserBodyRadius=60;
         // Facing is relative to the muzzle, not the player's cached side.
         var e:Object=G["eye"](u);wp.bulX=800;wp.bulY=e.y;aim(w,u.X2+60,u.Y2-5);
         ok(G["assist"](w,wp,c)===u,"muzzle across right-facing target uses full front range");
         wp.bulX=300;c.laserAssist=false;aim(w,u.X,u.Y2-4);
         var hit:Object=m.laser.fire(w,wp);ok(hit.unit===u && !hit.eye && m.laser.blind.remaining(u)==0,"rear body hit remains harmless with assist disabled");
         aim(w,e.x,e.y);hit=m.laser.fire(w,wp);
         ok(hit.eye && m.laser.blind.remaining(u)==6,"precise manual rear eye hit succeeds without assist");
         c.laserNonFront=false;m.laser.frame(w);
         ok(m.laser.blind.remaining(u)==6,"turning direction switch off preserves existing blindness");
         var s:Object=m.laser.blind.states[u];s.next=999;s.burst=0;s.node.step();
         ok(m.laser.blind.remaining(u)==179/30 && u.vision==0,"existing blindness still counts enemy action time after switch off");
         s.sources.laser=1;s.node.step();s.node.step();ok(m.laser.blind.remaining(u)==0 && u.vision>0,"existing blindness expires normally after switch off");
         pose(u,600,320);e=G["eye"](u);aim(w,e.x,e.y);wp.bulY=e.y;
         hit=m.laser.fire(w,wp);ok(!hit.eye && hit.reason=="back","next manual rear shot obeys disabled switch");
         c.laserNonFront=true;
         for each(var offset:Number in [-100,100])
         {
            m.laser.clear();wp.bulX=e.x;wp.bulY=e.y+offset;aim(w,e.x,e.y);hit=m.laser.fire(w,wp);
            ok(hit.eye && m.laser.blind.remaining(u)==6,"exact vertical manual eye ray succeeds offset="+offset);
            c.laserAssist=true;aim(w,u.X2+30,u.Y2-5);ok(G["assist"](w,wp,c)===u,"vertical assist uses non-front halo offset="+offset);
            aim(w,u.X2+30.01,u.Y2-5);ok(G["assist"](w,wp,c)==null,"vertical assist rejects outside non-front halo offset="+offset);c.laserAssist=false;
         }
         m.laser.clear();wp.bulX=300;wp.bulY=e.y;c.laserNonFrontRatio=0;c.laserBodyRadius=0;
         var Sats:Class=domain.getDefinition("fe.inter.SatsCel") as Class,q:*=new Sats({u:u,n:0},0,0,17);
         w.gg.sats.que.push(q);aim(w,1200,400);hit=m.laser.fire(w,wp);
         ok(hit.unit===u && hit.eye && m.laser.blind.remaining(u)==6 && wp.satsCons==17,"SATS rear eye targeting ignores zero radius and disabled ordinary assist");
         m.laser.clear();c.laserNonFront=false;hit=m.laser.fire(w,wp);
         ok(!hit.eye && hit.reason=="back","SATS restores front requirement with direction switch off");
         w.gg.sats.que.pop();q.remove();c.laserNonFront=true;c.laserAssist=true;c.laserBodyRadius=60;c.laserNonFrontRatio=50;
         aim(w,u.X,u.Y2-4);u.shithp=50;
         ok(G["assist"](w,wp,c)==null,"rear assist cannot bypass active shield");aim(w,e.x,e.y);hit=m.laser.fire(w,wp);
         ok(!hit.eye && hit.reason=="shield","manual rear ray reports active shield");u.shithp=0;
         var b:*=w.loc.createUnit("raider",660,430,true);pose(b,660,430,-1);w.loc.units=[w.gg,u,b];wp.bulY=260;
         aim(w,u.X2-1,u.Y2-1);u.shithp=50;
         w.loc.units=[w.gg,b];ok(G["assist"](w,wp,c)===b,"non-front priority fixture has valid neighbouring eye");w.loc.units=[w.gg,u,b];
         ok(G["assist"](w,wp,c)==null,"shielded pointed rear body never retargets valid neighbour");u.shithp=0;
         var wallFixture:Array=LaserTestWall.put(w.loc,480,500,240,280);
         ok(G["assist"](w,wp,c)==null,"wall-blocked rear body never retargets neighbour");LaserTestWall.restore(wallFixture);
         // Lower the neighbour enough that its eye ray passes below the first
         // body's bottom. The previous no-retarget fixture need not do that.
         pose(b,660,430,-1);var be:Object=G["eye"](b);
         hit=G["castRay"](w,wp.bulX,wp.bulY,Math.atan2(be.y-wp.bulY,be.x-wp.bulX),6,2000,w.gg,true);
         ok(hit.unit===b && hit.eye,"mixed-facing fixture has an unobstructed front target");
         c.laserNonFrontRatio=0;aim(w,u.X2+1,u.Y2-1);
         ok(G["assist"](w,wp,c)===b,"mixed-facing candidates apply their own halo before selection");
         b.exterminate();w.loc.units=[w.gg,u];c.laserNonFrontRatio=50;
         var blocker:*=w.loc.createUnit("raider",440,320,true);pose(blocker,440,320);w.loc.units=[w.gg,blocker,u];
         aim(w,e.x,e.y);hit=m.laser.fire(w,wp);
         ok(hit.unit===blocker && m.laser.blind.remaining(u)==0,"first intervening unit still blocks rear eye ray");blocker.exterminate();w.loc.units=[w.gg,u];
         wp.bulY=e.y;var tile:*=w.loc.getAbsTile(400,e.y),old:Object={phis:tile.phis,x1:tile.phX1,x2:tile.phX2,y1:tile.phY1,y2:tile.phY2};
         tile.phis=1;tile.phX1=390;tile.phX2=430;tile.phY1=200;tile.phY2=340;
         hit=m.laser.fire(w,wp);ok(hit.unit==null && hit.distance<200,"solid map tile blocks rear manual ray");
         tile.phis=old.phis;tile.phX1=old.x1;tile.phX2=old.x2;tile.phY1=old.y1;tile.phY2=old.y2;
         m.laser.clear();pose(u,500,320);w.gg.dx=w.gg.dy=0;aim(w,u.X,u.Y2-4);w.gg.setWeaponPos();wp.step();m.laser.frame(w);
         var hud:*=w.main.getChildByName("MSWLaserHUD"),raster:BitmapData=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,true,0);
         raster.draw(hud);var bounds:*=raster.getColorBoundsRect(0xFF000000,0,false);
         ok(bounds.width>10 && bounds.width<30 && bounds.height>10 && bounds.height<30,"HUD shows rear assisted eye circle when allowed");
         c.laserNonFront=false;m.laser.frame(w);raster.fillRect(raster.rect,0);raster.draw(hud);bounds=raster.getColorBoundsRect(0xFF000000,0,false);
         ok(bounds.width==0 && bounds.height==0,"HUD immediately removes forbidden rear eye circle");raster.dispose();
         c.laserNonFront=true;m.laser.frame(w);var image:BitmapData=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,false,0);image.draw(w.main.stage);savePNG(image,"nonfront-stage.png");image.dispose();
         m.laser.clear();pose(u,500,320,-1);c.laserNonFront=false;c.laserNonFrontRatio=50;c.laserDebug=true;c.save();
      }
   }
}
