package
{
   import flash.events.Event;
   import flash.system.ApplicationDomain;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;

   public class DamageProbe
   {
      private var timer:Timer=new Timer(50);
      private var t:int=0;
      private var phase:int=0;
      private var since:int=0;
      private var count:int=0;
      private var w:*;
      private var b:*;
      private var target:*;
      private var wall:*;
      private var log:String="";
      public function DamageProbe() { timer.addEventListener("timer",tick); timer.start(); }
      private function check(v:Boolean,name:String):void { if(!v)throw new Error(name); log+="PASS "+name+"\n"; }
      private function hit(bullet:*):Number
      {
         target.hp=target.maxhp=1000000;
         target.udarBullet(bullet);
         return 1000000-target.hp;
      }
      private function tick(e:Event):void
      {
         try
         {
            t++;
            if(t>1800)throw new Error("timeout phase "+phase);
            if(!ApplicationDomain.currentDomain.hasDefinition("fe.World"))return;
            w=getDefinitionByName("fe.World")["w"];
            if(w==null || w.gg==null || w.loc==null || !w.loc.active || w.gg.loc!==w.loc)return;
            if(w.verror!=null && w.verror.visible)throw new Error(w.verror.txt.text);
            var carrier:*=w.main.getChildByName("MSWModAPICarrier"); if(carrier==null)return;
            if(phase==0)
            {
               var items:Array;
               for each(var p:Object in carrier.modAPI.getPages())if(p.modId=="msw")items=p.items;
               if(items==null)return;
               for each(var it:Object in items)
               {
                  if(it.key=="ricochet")it["set"](true);
                  else if(it.key=="ricochetCount")it["set"](10);
                  else if(String(it.key).indexOf("ricochet")==0)it["set"](0);
               }
               w.onPause=true; w.testDam=true; w.showHit=0;
               var U:Class=getDefinitionByName("fe.unit.Unit") as Class;
               target=new U(); target.loc=w.loc; target.fraction=2; target.dexter=0;
               target.blood=0; target.isVis=false; target.showNumbs=false; target.opt=null;
               target.skin=0; target.armor=0; target.armor_qual=0; target.shithp=0;
               for(var x:int=60;x<w.loc.spaceX*40-60 && wall==null;x+=40)
                  for(var y:int=60;y<w.loc.spaceY*40-60;y+=40)
                  {
                     var tile:*=w.loc.getAbsTile(x,y);
                     if(tile!=null && tile.phis==1 && tile.phX1>80 && tile.phX2<w.loc.spaceX*40-20 && tile.phY2-tile.phY1>10 && w.loc.getAbsTile(tile.phX1-6,(tile.phY1+tile.phY2)/2).phis==0) {wall=tile;break;}
                  }
               check(wall!=null,"wall available");
               var B:Class=getDefinitionByName("fe.weapon.Bullet") as Class;
               b=new B(w.gg,wall.phX1-5,(wall.phY1+wall.phY2)/2,null,true);
               b.damage=100; b.dx=b.vel=10; b.dy=0; b.knockx=1; b.knocky=0; b.tipDamage=0;
               b.pier=20; b.armorMult=0.5;
               check(hit(b)==100,"direct neutral target loses 100 HP");
               target.skin=100; check(hit(b)==70,"direct armored target loses 70 HP"); target.skin=0;
               phase=1; since=t; return;
            }
            if(phase==1 && t-since>=3)
            {
               // Alternate exact-face and penetrating substep collisions.
               b.X=wall.phX1-(count%2==0?5:6); b.Y=(wall.phY1+wall.phY2)/2;
               b.dx=Math.abs(b.dx); b.dy=0;
               b.step(); // Actual original wall collision, including crash/popadalo.
               var impact:*=w.loc.getAbsTile(b.X,b.Y);
               check(impact===wall && impact.phis==1,"collision reaches selected intact wall "+count);
               check(b.babah,"actual wall collision "+count);
               check(b.damage==100,"wall keeps raw damage "+count);
               phase=2; since=t; return;
            }
            if(phase==2 && t-since>=3)
            {
               var next:*=null; var o:*=w.loc.firstObj;
               while(o!=null)
               {
                  if(o!==b && "owner" in o && o.owner===w.gg && "babah" in o && !o.babah && "begx" in o){next=o;break;}
                  o=o.nobj;
               }
               if(count==10)
               {
                  check(next==null,"stops after ten base bounces");
                  finish("PASS damage baseline",0); return;
               }
               check(next!=null,"continuation exists "+(count+1)); count++; b=next;
               var neutral:Number=hit(b);
               log+="MEASURE bounce="+count+" raw="+b.damage+" neutralHP="+neutral+" dist="+b.dist+" precision="+b.precision+"\n";
               check(neutral==100,"bounce neutral target HP "+count);
               target.skin=100; check(hit(b)==70,"bounce armor/piercing HP "+count); target.skin=0;
               if(count==10)accuracyControl(b);
               phase=1; since=t;
            }
         }
         catch(err:*){finish("FAIL "+err+"\n"+err.getStackTrace(),1);}
      }
      private function accuracyControl(bullet:*):void
      {
         // Use the instantiated base weapon: XML contains variant char nodes too.
         var lmg:*=w.gg.invent.addWeapon("lmg");
         check(lmg!=null,"light machine gun created by game");
         target.dexter=1; bullet.precision=lmg.precision;
         bullet.antiprec=lmg.antiprec;
         check(bullet.precision>0,"light machine gun base precision positive");
         log+="MEASURE lmg basePrecision="+bullet.precision+" antiprec="+bullet.antiprec+" targetDexter=1 miss=0\n";
         var savedX:Number=bullet.X; var savedY:Number=bullet.Y;
         var savedDx:Number=bullet.dx; var savedVel:Number=bullet.vel;
         target.setPos(wall.phX1-6,bullet.Y+5);
         bullet.targetObj=target; bullet.dx=-1; bullet.vel=1;
         for each(var distance:Number in [100,1000,5000,10000])
         {
            var hits:int=0; var min:Number=1000000; var max:Number=0;
            var misses:int=0;
            for(var i:int=0;i<2000;i++)
            {
               // Real Bullet.run: geometric overlap, hit-list gate, accuracy, then HP.
               bullet.X=wall.phX1-5; bullet.Y=savedY;
               bullet.dist=distance-1; bullet.parr=[]; bullet.babah=false; bullet.liv=100;
               target.hp=target.maxhp=1000000;
               bullet.run();
               var dealt:Number=1000000-target.hp;
               if(dealt>0){hits++; min=Math.min(min,dealt); max=Math.max(max,dealt);}
               else if(!bullet.babah)misses++;
            }
            log+="MEASURE lmg collision dist="+distance+" hits="+hits+"/2000 missContinues="+misses+" nonzeroHP="+min+".."+max+"\n";
            check(min==100 && max==100,"landed hit damage unchanged at distance "+distance);
            check(hits+misses==2000,"zero HP corresponds to miss and continued flight "+distance);
         }
         target.dexter=0; bullet.precision=0; bullet.antiprec=0;
         bullet.targetObj=null; bullet.X=savedX; bullet.Y=savedY;
         bullet.dx=savedDx; bullet.vel=savedVel; bullet.babah=false; bullet.liv=100; bullet.parr=[];
      }
      private function finish(result:String,code:int):void
      {
         timer.stop();
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class;
         var S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var stream:*=new S(); stream.open(F["applicationStorageDirectory"].resolvePath("results.txt"),"write");stream.writeUTFBytes(log+result+"\n");stream.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
