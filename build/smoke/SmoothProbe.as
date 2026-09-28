package
{
   import flash.events.Event;
   import flash.display.BitmapData;
   import flash.utils.getTimer;
   import flash.utils.getQualifiedClassName;
   import flash.utils.Timer;
   public class SmoothProbe
   {
      private var timer:Timer=new Timer(50),ticks:int=0;
      private var log:String="",points:Array=[];
      private var m:*,w:*,gun:*,target:*;
      private function ok(v:Boolean,s:String):void { if(!v)throw new Error(s);log+="PASS "+s+"\n"; }
      public function SmoothProbe(){timer.addEventListener("timer",tick);timer.start();}
      private function tick(e:Event):void
      {
         try
         {
            ticks++;m=MoreSkillsWeaponsMod.testInstance();w=MSWU.world();
            if(ticks>1000)throw new Error("timeout");
            if(w!=null && w.verror.visible)throw new Error("game startup: "+w.verror.txt.text);
            if(ticks<160 || m==null || w==null || w.gg==null || w.loc==null || !w.loc.active)return;
            if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;w.catPause=false;w.gg.ggControl=true;
            for(var x:int=160;x<1100;x+=20)for(var y:int=40;y<600;y+=20){var tile:*=w.loc.getAbsTile(x,y);if(tile!=null)tile.phis=0;}
            var W:Class=MSWU.cls("fe.weapon.Weapon"),U:Class=MSWU.cls("fe.unit.Unit"),B:Class=MSWU.cls("fe.weapon.Bullet");
            gun=W["create"](w.gg,"p9mm");w.gg.currentWeapon=gun;
            target=new U();target.loc=w.loc;target.fraction=2;target.sost=1;target.hp=target.maxhp=1000000;target.isVis=true;
            target.blood=0;target.showNumbs=false;target.opt=null;target.skin=target.armor=target.armor_qual=target.shithp=0;target.dexter=100;w.testDam=true;w.showHit=0;
            target.X=720;target.Y=140;target.X1=710;target.X2=730;target.Y1=100;target.Y2=140;w.loc.units.push(target);
            m.cfg.smartEnabled=true;m.cfg.smartTurn=1080;m.cfg.smartTurnRadius=100;m.cfg.smartLife=2;m.smart.frame(w);m.smart.lock.target=target;m.smart.lock.strength=1;
            var b:*=spawn(220,400,160,0);
            points=[{x:b.X,y:b.Y}];w.loc.firstObj.step();var shot:Object=m.smart.snapshot(b);
            if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
            if(b.X==220 && b.Y==400)
            {
               var n:int=Math.floor(Math.max(Math.abs(b.dx),Math.abs(b.dy))/MSWU.cls("fe.World")["maxdelta"])+1;
               for(var i:int=0;i<n && !b.babah;i++){b.run(n);points.push({x:b.X,y:b.Y});}
            }
            else points=shot.motionPath.concat();
            var angle:Number=0,maxKink:Number=0,straight:Number=0,maxStraight:Number=0,total:Number=0;
            for(i=1;i<points.length;i++)
            {
               var p:Object=points[i-1],q:Object=points[i];var a:Number=Math.atan2(q.y-p.y,q.x-p.x);
               var delta:Number=Math.abs(MSWSmartRoute.angle(a-angle));var len:Number=MSWSmartRoute.distance(p.x,p.y,q.x,q.y);
               maxKink=Math.max(maxKink,delta);straight=delta<0.000001?straight+len:len;maxStraight=Math.max(maxStraight,straight);total+=len;angle=a;
            }
            log="MEASURE speed=160 maxKinkDegrees="+(maxKink*180/Math.PI)+" longestStraight="+maxStraight+" distance="+total+"\n";
            write("trace.json",JSON.stringify(points));
            if(maxKink>5*Math.PI/180 || maxStraight>24)throw new Error("visible angular kink / long straight segment during steering");
            if(Math.abs(total-160)>0.001)throw new Error("smoothing changed speed");
            var endX:Number=b.X,endY:Number=b.Y;
            b.step();m.smart.afterProjectiles();
            ok(b.X==endX && b.Y==endY && b.liv==99 && Math.abs(b.dist-160)<0.001 && !b.babah,"native step ages once without moving twice or leaving false impact");
            ok(b.vis.scaleX==0 && b.vis.parent.getChildByName("MSWSmartTrail")!=null,"curved native-art tracer replaces the straight strip");
            var image:BitmapData=new BitmapData(1100,650,false,0x18202B);image.draw(b.vis.parent);
            var enc:Class=MSWU.cls("flash.display.PNGEncoderOptions");var bytes:*=Object(image)["encode"](image.rect,new enc());
            var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream"),fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath("curve.png"),"write");fs.writeBytes(bytes);fs.close();image.dispose();
            var budget:Number=shot.remaining;m.smart.frame(w);m.smart.frame(w);
            ok(shot.remaining==budget,"frozen display frames retain budget");
            w.loc.remObj(b);m.smart.frame(w);
            ok(b.vis.parent==null,"removed native projectile visual cleaned");
            // Compare identical native shots. Smaller radius must bend farther
            // during the same travelled distance, with no speed/lifetime change.
            var turns:Array=[];
            for each(var radius:Number in [10,50,100,200])
            {
               m.cfg.smartTurnRadius=radius;m.smart.lock.target=target;m.smart.lock.strength=1;
               b=spawn(220,400,160,0);w.loc.firstObj.step();shot=m.smart.snapshot(b);
               turns.push(Math.abs(Math.atan2(b.dy,b.dx)));b.step();m.smart.afterProjectiles();
               log+="RADIUS percent="+radius+" degrees="+(turns[turns.length-1]*180/Math.PI)+" distance="+b.dist+"\n";
               ok(b.liv==99 && Math.abs(b.dist-160)<0.001 && shot.turnRadius==radius,"radius "+radius+" uses same native speed and age");
               m.cfg.smartTurnRadius=70;m.smart.frame(w);
               ok(shot.turnRadius==radius,"in-flight shot keeps radius snapshot "+radius);
               w.loc.remObj(b);m.smart.frame(w);
            }
            ok(turns[0]>turns[1] && turns[1]>turns[2] && turns[2]>turns[3],"smaller radius bends native shots more sharply");
            m.cfg.smartTurnRadius=50;
            // Native damage and detouring around a physical 80x80 box.
            pos(520,240);var wall:Array=[];
            for(x=320;x<400;x+=40)for(y=200;y<280;y+=40){tile=w.loc.getAbsTile(x+1,y+1);tile.phis=1;tile.phX1=x;tile.phX2=x+40;tile.phY1=y;tile.phY2=y+40;wall.push(tile);}
            m.smart.lock.target=target;m.smart.lock.strength=1;
            b=spawn(220,240,20,0);var hp:Number=target.hp,curved:Boolean=false;var route:Array=[];
            for(i=0;i<80 && !b.babah;i++){physics();route=route.concat(m.smart.snapshot(b).motionPath || []);if(Math.abs(b.Y-240)>40)curved=true;}
            write("obstacle-trace.json",JSON.stringify(route));
            ok(curved && target.hp<hp,"curved native bullet clears solid box and damages covered target");
            w.loc.remObj(b);
            m.cfg.ricochet=true;m.cfg.ricochetCount=2;m.cfg.smartTurn=90;
            b=spawn(310,240,25,0);m.bullets.process(w);physics();shot=m.smart.snapshot(b);budget=shot.remaining;
            ok(b.babah,"insufficient turn radius still causes real wall collision");
            m.bullets.process(w);var bounce:*=w.loc.firstObj;
            while(bounce!=null && (bounce===b || m.smart.snapshot(bounce)!==shot))bounce=bounce.nobj;
            ok(bounce!=null && bounce.dx<0 && shot.remaining==budget,"ricochet uses actual final segment and inherits remaining budget");
            ok(m.smart.snapshot(bounce).turnRadius==50,"ricochet preserves radius snapshot");
            w.loc.remObj(b);w.loc.remObj(bounce);m.cfg.ricochet=false;m.cfg.smartTurn=1080;
            for each(tile in wall)tile.phis=0;
            // Expiry restores native straight flight; no stale trail survives.
            pos(720,240);m.cfg.smartLife=0.1;b=spawn(220,240,10,0);
            for(i=0;i<3;i++)physics();shot=m.smart.snapshot(b);
            ok(shot.remaining==0 && b.liv==97,"substeps do not multiply lifetime or guidance time");
            endX=b.X;physics();ok(Math.abs(b.X-endX-10)<0.001 && b.vis.scaleX==1,"expiry restores native motion and tracer");
            w.loc.remObj(b);m.cfg.smartLife=2;
            // Natural chain ordering, including births after last frame's hook.
            var batch:Array=[];for(i=0;i<64;i++)batch.push(spawn(220,400+i%8,160,0));
            var start:int=getTimer();physics();var cost:int=getTimer()-start;
            for each(b in batch)if(b.babah || b.liv!=99 || Math.abs(b.dist-160)>0.001)throw new Error("batch bullet advanced incorrectly");
            ok(true,"all 64 batch bullets advanced and finalized exactly once");
            ok(cost<2000,"64 fast curved bullets completed in "+cost+" ms");
            m.cfg.smartEnabled=false;m.smart.frame(w);
            for each(b in batch)if(b.vis.parent.getChildByName("MSWSmartTrail")!=null)throw new Error("stale disabled trail");
            ok(true,"disable removes all curved trails");
            ok(m.cfg.diag.smartError==null,"no smart runtime error");
            finish("PASS smooth trajectory",0);
         }
         catch(err:*){finish("FAIL "+err,1);}
      }
      private function pos(x:Number,y:Number):void { target.X=x;target.Y=y+20;target.X1=x-12;target.X2=x+12;target.Y1=y-20;target.Y2=y+20; }
      private function spawn(x:Number,y:Number,dx:Number,dy:Number):*
      { var B:Class=MSWU.cls("fe.weapon.Bullet");var b:*=new B(w.gg,x,y,MSWU.cls("visualBullet"),true);b.weap=gun;b.damage=100;b.tipDamage=0;b.precision=10;b.miss=1;b.dx=dx;b.dy=dy;b.vel=Math.sqrt(dx*dx+dy*dy);return b; }
      private function physics():void
      {
         var b:*=w.loc.firstObj;var n:int=0;
         while(b!=null && n++<12000){var next:*=b.nobj;b.step();b=next;}
         if(m.cfg.diag.smartError!=null)throw new Error(m.cfg.diag.smartError);
      }
      private function write(name:String,s:String):void{var F:Class=MSWU.cls("flash.filesystem.File"),S:Class=MSWU.cls("flash.filesystem.FileStream");var f:*=new S();f.open(F["applicationStorageDirectory"].resolvePath(name),"write");f.writeUTFBytes(s);f.close();}
      private function finish(s:String,code:int):void{write("results.txt",log+s+"\n");timer.stop();MSWU.cls("flash.desktop.NativeApplication")["nativeApplication"].exit(code);}
   }
}
