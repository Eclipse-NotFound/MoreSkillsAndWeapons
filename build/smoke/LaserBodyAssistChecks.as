package
{
   import flash.system.ApplicationDomain;
   import flash.display.BitmapData;
   import flash.events.Event;
   import flash.events.MouseEvent;
   /** TEST ONLY: exercises the optimized production SWF through native actors. */
   public class LaserBodyAssistChecks
   {
      public static function settings(domain:ApplicationDomain,w:*,m:*,Legacy:Class,ok:Function,savePNG:Function):void
      {
         var Config:Class=domain.getDefinition("MSWConfig") as Class,c:*=m.cfg;
         ok(c.laserAssist && c.laserBodyRadius==60 && c.laserAssistFloor==50,"body assist starts enabled at 60px / 50 percent");
         if(Legacy!=null)
         {
            ok(c.laserAssistSpeed==18 && c.laserDuration==8,"first upgrade inherits customized speed and unrelated laser duration");
            ok(c.laserRadius==116 && c.laserAngle==13 && c.laserSpeed==18,"first upgrade preserves every legacy assist setting");
         }
         var page:Object,items:Object={},item:Object;
         for each(var p:Object in m.settings.api.getPages())if(p.modId=="msw-laser")page=p;
         ok(page!=null && page.items.length==15,"registered laser page contains fifteen settings");
         for each(item in page.items)items[item.key]=item;
         ok(items.laserRadius==null && items.laserAngle==null && items.laserSpeed==null,"old angle controls leave the UI without losing stored keys");
         ok(items.laserAssist.def===true && items.laserBodyRadius.def==60 && items.laserAssistFloor.def==50 && items.laserAssistSpeed.def==10,"new UI defaults match fresh configuration");
         items.laserBodyRadius.set(84);items.laserAssistFloor.set(75);items.laserAssistSpeed.set(12.5);items.laserAssist.set(false);page.onPageClose();
         var fresh:*=new Config();fresh.load();
         ok(!fresh.laserAssist && fresh.laserBodyRadius==84 && fresh.laserAssistFloor==75 && fresh.laserAssistSpeed==12.5,"custom body settings survive save and a fresh configuration instance");
         if(Legacy!=null)
         {
            var old:*=new Legacy();old.load();
            ok(old.laserRadius==116 && old.laserAngle==13 && old.laserSpeed==18,"actual previous SWF reads its original customized settings after upgrade");
            old.laserDuration=7;old.save();fresh=new Config();fresh.load();
            ok(!fresh.laserAssist && fresh.laserBodyRadius==84 && fresh.laserAssistFloor==75 && fresh.laserAssistSpeed==12.5 && fresh.laserDuration==7,"old SWF save and re-upgrade preserve new choices without reinitializing");
         }
         c.laserBodyRadius=NaN;c.laserAssistFloor=Infinity;c.laserAssistSpeed=NaN;c.clamp();
         ok(c.laserBodyRadius==60 && c.laserAssistFloor==50 && c.laserAssistSpeed==10,"invalid stored numbers fall back to approved defaults");
         items.laserBodyRadius.set(-20);items.laserAssistFloor.set(0);items.laserAssistSpeed.set(0);
         ok(c.laserBodyRadius==0 && c.laserAssistFloor==10 && c.laserAssistSpeed==1,"new controls enforce lower bounds");
         items.laserBodyRadius.set(999);items.laserAssistFloor.set(999);items.laserAssistSpeed.set(999);
         ok(c.laserBodyRadius==160 && c.laserAssistFloor==100 && c.laserAssistSpeed==40,"new controls enforce upper bounds");
         for each(item in page.items)item.set(item.def);page.onPageClose();
         // F6 retains the last selected page. Cycle a complete set to reset the row.
         m.panel.toggleOverlay();for(var i:int=0;i<5;i++)m.panel.handleKey(9);
         for(i=0;i<3;i++)m.panel.handleKey(40);m.panel.handleKey(13);
         m.panel.handleKey(40);m.panel.handleKey(39);
         m.panel.handleKey(40);m.panel.handleKey(37);
         m.panel.handleKey(40);m.panel.handleKey(39);m.panel.toggleOverlay();
         fresh=new Config();fresh.load();
         ok(!fresh.laserAssist && fresh.laserBodyRadius==64 && fresh.laserAssistFloor==45 && fresh.laserAssistSpeed==10.5,"F6 changes and persists all four new controls");
         for each(item in page.items)item.set(item.def);page.onPageClose();
         fresh=new Config();fresh.load();
         ok(fresh.laserAssist && fresh.laserBodyRadius==60 && fresh.laserAssistFloor==50 && fresh.laserAssistSpeed==10,"reset through shared setting definitions restores defaults");
         if(Legacy!=null)ok(fresh.laserRadius==116 && fresh.laserAngle==13 && fresh.laserSpeed==18,"restoring current defaults does not rewrite rollback settings");
         if(!w.pip.active)w.pip.onoff(5);if(!m.panel.tabActive())m.panel.tabToggle(w);m.settings.api.selectPage("msw-laser");
         var row:*=settingRow(w.main,"laserAssist");
         ok(row!=null && row.settingsSc.selected,"Pip renders the new enabled assistance checkbox");
         row.settingsSc.selected=false;row.settingsSc.dispatchEvent(new Event(Event.CHANGE));
         fresh=new Config();fresh.load();ok(!fresh.laserAssist,"actual Pip checkbox immediately saves the switch");
         row=settingRow(w.main,"laserBodyRadius");ok(row!=null,"Pip renders the new body radius control");
         row.settingsSc.scrollPosition=20;row.settingsSc.dispatchEvent(new Event(Event.SCROLL));
         ok(c.laserBodyRadius==80,"actual Pip slider changes body radius to 80px");
         var reset:*=named(w.main,"SettingsReset");ok(reset!=null,"Pip has a reset control");reset.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
         ok(c.laserAssist && c.laserBodyRadius==60 && c.laserAssistFloor==50 && c.laserAssistSpeed==10,"actual Pip reset restores all four assistance defaults");
         var image:BitmapData=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,false,0);image.draw(w.main.stage);savePNG(image,"body-assist-settings.png");image.dispose();
         w.pip.onoff();w.onPause=true;m.panel.update(w);
      }
      private static function settingRow(o:*,key:String):*
      {
         try {if(o.settingsItem!=null && o.settingsItem.key==key)return o;}catch(ignore:*){}
         if(o is flash.display.DisplayObjectContainer)for(var i:int=0;i<o.numChildren;i++){var r:*=settingRow(o.getChildAt(i),key);if(r!=null)return r;}
         return null;
      }
      private static function named(o:*,name:String):*
      {
         if(o.name==name)return o;
         if(o is flash.display.DisplayObjectContainer)for(var i:int=0;i<o.numChildren;i++){var r:*=named(o.getChildAt(i),name);if(r!=null)return r;}
         return null;
      }
      private static function pose(u:*,x:Number,y:Number,facing:int=-1):void
      {
         u.fraction=2;u.hp=u.maxhp;u.sost=1;u.disabled=u.trigDis=u.npc=u.noAgro=false;
         u.storona=facing;u.shithp=0;u.stun=u.t_emerg=0;u.isVis=true;u.invis=false;
         u.dx=u.dy=0;u.stay=true;u.setPos(x,y);u.actions();u.animate();u.setVisPos();u.vis.visible=true;
      }
      private static function aim(w:*,x:Number,y:Number):void {w.celX=w.gg.celX=x;w.celY=w.gg.celY=y;}
      private static function eyeDistance(G:Class,u:*,w:*):Number
      {var e:Object=G["eye"](u);return (e.x-w.celX)*(e.x-w.celX)+(e.y-w.celY)*(e.y-w.celY);}
      public static function combat(domain:ApplicationDomain,w:*,m:*,wp:*,a:*,ok:Function,savePNG:Function):void
      {
         var G:Class=domain.getDefinition("MSWLaserGeometry") as Class,c:*=m.cfg;
         c.laserAssist=true;c.laserBodyRadius=60;c.laserAssistFloor=50;c.laserAssistSpeed=10;
         c.laserDebug=false;m.laser.clear();w.gg.setPos(240,320);w.gg.storona=1;
         // Native attack/step: cursor goes to the lower body, never to the eye.
         for each(var x:Number in [380,650,1050])for each(var velocity:Array in [[0,0],[10,0],[0,-10],[6,8]])
         {
            pose(a,x,320);w.loc.units=[w.gg,a];m.laser.blind.clear();
            w.gg.dx=velocity[0];w.gg.dy=velocity[1];aim(w,a.X,a.Y2-4);
            for(var settle:int=0;settle<15;settle++){w.gg.setWeaponPos();wp.step();}
            wp.getBulXY();var e:Object=G["eye"](a),hp:Number=a.hp;
            if(x==380)ok(Math.abs(Math.atan2(e.y-wp.bulY,e.x-wp.bulX)-Math.atan2(w.celY-wp.bulY,w.celX-wp.bulX))>5*Math.PI/180,"close body aim exceeds former five-degree gate at velocity "+velocity);
            wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;
            var shots:Number=m.cfg.diag.laserShots;wp.attack();wp.step();
            ok(m.laser.blind.remaining(a)==6 && a.hp==hp && wp.hold==10 && m.cfg.diag.laserShots==shots+1,"native body-aim shot blinds at x="+x+" velocity="+velocity);
         }
         m.laser.clear();pose(a,600,320);w.loc.units=[w.gg,a];wp.bulX=300;wp.bulY=260;
         // Independently chosen expected boundaries: standing, half-speed,
         // horizontal/vertical/combined full speed and speed beyond threshold.
         for each(var sample:Array in [[0,0,60],[5,0,45],[10,0,30],[0,10,30],[6,-8,30],[30,40,30]])
         {
            w.gg.dx=sample[0];w.gg.dy=sample[1];aim(w,a.X2+sample[2],a.Y2-5);
            ok(G["assist"](w,wp,c)===a,"inclusive peripheral boundary "+sample);
            aim(w,a.X2+sample[2]+0.01,a.Y2-5);
            ok(G["assist"](w,wp,c)==null,"outside peripheral boundary "+sample);
            aim(w,a.X,a.Y2-1);ok(G["assist"](w,wp,c)===a,"direct body remains reliable at velocity "+sample);
         }
         c.laserBodyRadius=0;aim(w,a.X2,a.Y2);
         ok(G["assist"](w,wp,c)===a,"zero peripheral radius still accepts collision-body edge");
         aim(w,a.X2+0.01,a.Y2);ok(G["assist"](w,wp,c)==null,"zero peripheral radius excludes points outside body");
         c.laserBodyRadius=60;c.laserAssistFloor=100;aim(w,a.X2+60,a.Y2-5);
         ok(G["assist"](w,wp,c)===a,"100 percent minimum keeps full range at high speed");
         c.laserAssistFloor=50;w.gg.dx=w.gg.dy=0;aim(w,a.X,a.Y2-4);
         c.laserAssist=false;ok(G["assist"](w,wp,c)==null,"manual switch disables selection even directly on body");
         var hit:Object=m.laser.fire(w,wp);ok(!hit.eye && hit.unit===a && m.laser.blind.remaining(a)==0,"manual body shot stays harmless and does not become eye contact");
         e=G["eye"](a);aim(w,e.x,e.y);hit=m.laser.fire(w,wp);
         ok(hit.eye && m.laser.blind.remaining(a)==6,"manual accurate eye shot remains effective with assistance off");
         var Sats:Class=domain.getDefinition("fe.inter.SatsCel") as Class,q:*=new Sats({u:a,n:0},0,0,17);
         m.laser.clear();w.gg.sats.que.push(q);aim(w,a.X,a.Y2-4);hit=m.laser.fire(w,wp);
         ok(hit.eye && hit.unit===a && m.laser.blind.remaining(a)==6,"SATS selected-eye targeting remains independent of ordinary assist toggle");
         w.gg.sats.que.pop();q.remove();
         m.laser.clear();c.laserAssist=true;aim(w,a.X,a.Y2-4);
         a.invis=true;ok(G["assist"](w,wp,c)==null,"cloaked actor excluded");a.invis=false;
         a.isVis=false;ok(G["assist"](w,wp,c)==null,"out-of-sight actor excluded");a.isVis=true;
         a.controlOn=false;ok(G["assist"](w,wp,c)==null,"script-controlled actor excluded");a.controlOn=true;
         a.fraction=w.gg.fraction;ok(G["assist"](w,wp,c)==null,"friendly actor excluded");a.fraction=2;
         a.hp=0;ok(G["assist"](w,wp,c)==null,"dead actor excluded");a.hp=a.maxhp;
         var b:*=w.loc.createUnit("raider",660,380,true);pose(b,660,380);
         pose(a,600,320);w.loc.units=[w.gg,a,b];aim(w,a.X2-1,a.Y2-1);
         ok(eyeDistance(G,b,w)<eyeDistance(G,a,w),"priority fixture: nearby actor eye is closer than pointed actor eye");
         ok(G["assist"](w,wp,c)===a,"direct body takes priority over nearer neighbouring eye");
         aim(w,a.X2+2,a.Y2-1);ok(G["assist"](w,wp,c)===a,"nearest body wins outside both bodies even when another eye is closer");
         pose(b,600,430);aim(w,600,340);
         ok(w.celY-a.Y2==b.Y1-w.celY && eyeDistance(G,b,w)<eyeDistance(G,a,w),"peripheral tie fixture has equal body distances and nearer second eye");
         ok(G["assist"](w,wp,c)===b,"equal peripheral body distances break tie by eye distance");
         b.shithp=50;ok(G["assist"](w,wp,c)===a,"without a directly pointed body selection skips invalid peripheral target");b.shithp=0;
         pose(b,660,380);
         // A second target below the first has an unobstructed low eye ray.
         // It must not steal a shot when the explicitly pointed first one fails.
         aim(w,a.X2-1,a.Y2-1);pose(a,600,320,1);
         w.loc.units=[w.gg,b];ok(G["assist"](w,wp,c)===b,"neighbour is genuinely reachable within peripheral range");w.loc.units=[w.gg,a,b];
         ok(G["assist"](w,wp,c)==null,"back-facing pointed body never retargets neighbour");
         hit=m.laser.fire(w,wp);ok(!hit.eye && m.laser.blind.remaining(b)==0,"rejected pointed body fires original ray without blinding neighbour");
         pose(a,600,320);a.shithp=50;ok(G["assist"](w,wp,c)==null,"shielded pointed body never retargets neighbour");a.shithp=0;
         var wallFixture:Array=LaserTestWall.put(w.loc,480,500,240,280);
         ok(G["assist"](w,wp,c)==null,"wall-blocked pointed eye never retargets neighbour");LaserTestWall.restore(wallFixture);
         // Overlapping native collision rectangles: nearer eye, not unit-array order.
         pose(b,615,340);aim(w,615,310);w.loc.units=[w.gg,a,b];
         ok(w.celX>=a.X1 && w.celX<=a.X2 && w.celY>=a.Y1 && w.celY<=a.Y2 && w.celX>=b.X1 && w.celX<=b.X2 && w.celY>=b.Y1 && w.celY<=b.Y2,"overlap fixture points into both native bodies");
         ok(eyeDistance(G,b,w)<eyeDistance(G,a,w),"overlap fixture has uniquely nearer second eye");
         ok(G["assist"](w,wp,c)==null,"nearer overlapping eye behind first body remains physically blocked");
         pose(b,585,340);aim(w,585,310);
         ok(G["assist"](w,wp,c)===b,"overlap chooses closest eye");
         w.loc.units=[w.gg,b,a];ok(G["assist"](w,wp,c)===b,"overlap choice is independent of enumeration order");
         b.shithp=50;e=G["eye"](a);hit=G["castRay"](w,wp.bulX,wp.bulY,Math.atan2(e.y-wp.bulY,e.x-wp.bulX),6,2000,w.gg);
         ok(hit.unit===a && hit.eye,"other overlapping eye is physically reachable when chosen eye is shielded");
         ok(G["assist"](w,wp,c)==null,"invalid chosen overlap does not fall back to the other body");b.shithp=0;
         b.exterminate();w.loc.units=[w.gg,a];pose(a,600,320);aim(w,a.X,a.Y2-4);
         // Real solid map tile, with actual cast result proving the wall position.
         e=G["eye"](a);wp.bulY=e.y;var tile:*=w.loc.getAbsTile(400,e.y);
         var old:Object={phis:tile.phis,x1:tile.phX1,x2:tile.phX2,y1:tile.phY1,y2:tile.phY2};
         tile.phis=1;tile.phX1=390;tile.phX2=430;tile.phY1=200;tile.phY2=340;
         ok(G["assist"](w,wp,c)==null,"solid terrain blocks assistance");
         tile.phis=old.phis;tile.phX1=old.x1;tile.phX2=old.x2;tile.phY1=old.y1;tile.phY2=old.y2;
         wp.bulX=700;ok(G["assist"](w,wp,c)==null,"muzzle already past a left-facing target fails front rule");
         wp.bulX=e.x;wp.bulY=e.y-80;ok(G["assist"](w,wp,c)==null,"pure vertical eye ray cannot satisfy front rule");
         // Indicator is drawn only for the same eligible assisted target.
         pose(a,500,320);w.gg.dx=w.gg.dy=0;aim(w,a.X,a.Y2-4);w.gg.setWeaponPos();wp.step();
         w.visual.x=w.visual.y=0;w.visual.scaleX=w.visual.scaleY=1;
         m.laser.clear();m.laser.frame(w);var hud:*=w.main.getChildByName("MSWLaserHUD");
         var raster:BitmapData=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,true,0);raster.draw(hud);
         var bounds:*=raster.getColorBoundsRect(0xFF000000,0,false);
         ok(bounds.width>10 && bounds.width<30 && bounds.height>10 && bounds.height<30,"HUD draws only the assisted eye circle before a shot");
         pose(a,500,320,1);m.laser.frame(w);raster.fillRect(raster.rect,0);raster.draw(hud);bounds=raster.getColorBoundsRect(0xFF000000,0,false);raster.dispose();
         ok(bounds.width==0 && bounds.height==0,"invalid pointed eye hides the normal assistance circle");
         pose(a,500,320);aim(w,a.X,a.Y2-4);m.laser.frame(w);
         var image:BitmapData=new BitmapData(w.main.stage.stageWidth,w.main.stage.stageHeight,false,0);image.draw(w.main.stage);savePNG(image,"body-assist-stage.png");image.dispose();
         c.laserDebug=true;c.save();m.laser.clear();
      }
   }
}
