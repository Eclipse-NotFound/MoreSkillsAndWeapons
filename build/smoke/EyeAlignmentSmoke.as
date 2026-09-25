package
{
   import flash.display.*;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.geom.*;
   import flash.text.*;

   /** TEST ONLY: native Merc pixels and production eye resolver, independent SWF. */
   public class EyeAlignmentSmoke extends Sprite
   {
      private static var probe:EyeAlignmentSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,started:Boolean=false,log:String="";
      private var records:Array=[];
      private var failures:int=0;
      public function EyeAlignmentSmoke() {}
      public static function init(main:*):void {probe=new EyeAlignmentSmoke();probe.start(main);}
      private function start(main:*):void
      {
         host=main;loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaded);
         loader.load(new URLRequest("app:/mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf"),new LoaderContext(false,new ApplicationDomain(main.loaderInfo.applicationDomain)));
      }
      private function loaded(e:Event):void
      {
         domain=loader.contentLoaderInfo.applicationDomain;
         var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class;entry["init"](host);
         timer.addEventListener("timer",tick);timer.start();
      }
      private function tick(e:Event):void
      {
         try {
            ticks++;
            var entry:Class=domain.getDefinition("MoreSkillsWeaponsMod") as Class,WC:Class=domain.getDefinition("fe.World") as Class;
            var m:*=entry["testInstance"](),w:*=WC["w"];
            if(ticks>600)throw new Error("world timeout");
            if(w==null || m==null || !w.allLandsLoaded)return;
            if(w.verror.visible)throw new Error(w.verror.txt.text);
            if(!started){w.mm.active=false;w.newGame(-1,"LP",null);started=true;return;}
            if(ticks<90 || w.gg==null || w.loc==null || !w.loc.active || w.invent.weapons["mswlaserpointer"]==null)return;
            w.gg.controlOn();if(w.gg.atkPoss==0)return;
            timer.stop();if(w.pip.active)w.pip.onoff();w.onPause=true;w.godMode=false;
            w.gui.dialText();w.catPause=false;w.gg.work="";w.gg.t_work=0;w.gg.dx=w.gg.dy=0;w.loc.base=false;
            for(var x:int=100;x<1300;x+=20)for(var y:int=40;y<550;y+=20){var tile:*=w.loc.getAbsTile(x,y);tile.phis=tile.water=0;}
            w.loc.objs=[];w.invent.items.batt.kol=1000;
            variants(w);
            for(var variant:int=1;variant<=5;variant++)
            {
               var u:*=w.loc.createUnit("merc",600,320,true,null,String(variant));
               u.fraction=2;u.hp=u.maxhp;u.sost=1;u.disabled=u.trigDis=u.npc=u.noAgro=false;
               u.storona=1;u.shithp=0;u.stun=u.t_emerg=0;u.isVis=true;
               u.setPos(600,320);u.actions();u.setVisPos();u.vis.visible=true;
               capture(u,"stay",96);capture(u,"walk",96);capture(u,"fly",96);capture(u,"jump",20);
               frozenTransforms(u);nativeShots(w,m,u);u.exterminate();
            }
            write("frames.json",JSON.stringify(records,null,2));
            if(failures>0)throw new Error(failures+" displayed eye alignment checks failed");
            finish(true,"");
         }catch(err:*){finish(false,String(err)+"\n"+err.getStackTrace());}
      }
      private function bitmap(node:DisplayObject):Bitmap
      {
         if(node is Bitmap)return Bitmap(node);
         var c:DisplayObjectContainer=node as DisplayObjectContainer;
         if(c!=null)for(var i:int=0;i<c.numChildren;i++){var b:Bitmap=bitmap(c.getChildAt(i));if(b!=null)return b;}
         return null;
      }
      private function variants(w:*):void
      {
         var sheet:BitmapData=new BitmapData(1600,700,false,0x33404C);
         for(var variant:int=1;variant<=5;variant++)
         {
            var u:*=w.loc.createUnit("merc",600,320,true,null,String(variant));
            u.storona=1;u.setPos(600,320);u.setVisPos();u.vis.visible=true;
            check(u.tr==variant,"native Merc variant "+variant);
            for(var row:int=0;row<=1;row++)
            {
               u.blit(row,0);sheet.draw(u.vis,new Matrix(3,0,0,3,(variant-1)*320+130,row*350+310));
               var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("_sans",13,0xFFFFFF);label.width=310;label.text="merc"+variant+" row="+row;
               sheet.draw(label,new Matrix(1,0,0,1,(variant-1)*320+4,row*350+328));
               savePNG(bitmap(u.vis).bitmapData,"merc"+variant+"-row"+row+"-pixels.png");
            }
            u.exterminate();
         }
         savePNG(sheet,"merc-variants.png");sheet.dispose();
      }
      private function check(pass:Boolean,message:String):void
      {log+=(pass?"PASS ":"FAIL ")+message+"\n";if(!pass)failures++;}
      private function iris(b:Bitmap,row:int,variant:int,frame:int=0):Point
      {
         // Independently find the yellow iris in native pixels. This detector
         // is only a test oracle; production never scans sprite pixels.
         var left:int=row==0?112:124,right:int=row==0?125:136,top:int=row==0?57:59,bottom:int=row==0?69:72;
         if(variant==5){left=row==0?120:131;right=row==0?131:142;top=55;bottom=73;}
         // These helmet frames have a dark visor or a reflection that is not
         // its centre. Independently marked against the exported native PNGs.
         if(variant==5 && row==0)
         {
            var visor:Object={18:[126,61],19:[125.5,62],20:[124.5,62.5],21:[122,62.5],22:[121.5,62.5],24:[122,63]};
            if(visor[frame]!=null)return new Point(visor[frame][0],visor[frame][1]);
         }
         var sx:Number=0,sy:Number=0,n:int=0;
         for(var y:int=top;y<bottom;y++)for(var x:int=left;x<right;x++)
         {
            var c:uint=b.bitmapData.getPixel32(x,y),r:int=(c>>16)&255,g:int=(c>>8)&255,blue:int=c&255;
            var match:Boolean=variant==1?(r>90 && r-g>45 && r-blue>35):
               (variant==2?(r>145 && g>135 && blue<90 && r<g*1.5):
               (variant==3?(r>180 && g>100 && g<210 && blue<90):
               (variant==4?(blue>100 && blue-r>28 && blue-g>28):(r>220 && g>220 && blue>220))));
            if((c>>>24)>240 && match){sx+=x+.5;sy+=y+.5;n++;}
         }
         if(n==0)return null;
         return new Point(sx/n,sy/n);
      }
      private function aligned(u:*,label:String,row:int,frame:int=0):void
      {
         var b:Bitmap=bitmap(u.vis),pixel:Point=iris(b,row,u.tr,frame);
         if(pixel==null){check(false,"native eye pixels missing merc"+u.tr+" "+label);return;}
         var expected:Point=u.vis.parent.globalToLocal(b.localToGlobal(pixel));
         var eyes:Class=domain.getDefinition("MSWLaserEyes") as Class,e:Object=eyes["point"](u);
         var error:Number=Point.distance(expected,new Point(e.x,e.y));
         check(error<=3,"merc"+u.tr+" "+label+" native eye distance="+error.toFixed(3)+" limit=3");
      }
      private function capture(u:*,state:String,count:int):void
      {
         var eyes:Class=domain.getDefinition("MSWLaserEyes") as Class,access:Class=domain.getDefinition("fe.unit.MSWBlindAccess") as Class;
         var frames:Array=[],seen:Object={};
         u.stay=state=="stay" || state=="walk";u.isFly=state=="fly";u.dx=state=="walk"?4:0;
         for(var i:int=0;i<count;i++)
         {
            u.dy=state=="jump"?(i-10)*2:0;u.animate();u.setVisPos();
            var p:Object=access["pose"](u),key:String=p.id+"-"+p.frame;
            if(seen[key])continue;seen[key]=true;
            var b:Bitmap=bitmap(u.vis),e:Object=eyes["point"](u),nativePoint:Point=u.vis.globalToLocal(b.localToGlobal(new Point(0,0)));
            var data:BitmapData=new BitmapData(320,350,false,0x33404C),raw:BitmapData=data.clone();
            var matrix:Matrix=new Matrix(3,0,0,3,130,310);
            raw.draw(u.vis,matrix);data.draw(u.vis,matrix);
            var marker:Sprite=new Sprite();marker.graphics.lineStyle(1,0xFF6666);marker.graphics.drawCircle(130+(e.x-u.X)*3,310+(e.y-u.Y)*3,18);data.draw(marker);
            var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("_sans",13,0xFFFFFF);label.width=310;label.text=state+" row="+p.id+" frame="+p.frame;data.draw(label,new Matrix(1,0,0,1,4,328));
            frames.push(data);
            savePNG(raw,"merc"+u.tr+"-"+state+"-"+key+"-raw.png");raw.dispose();
            savePNG(b.bitmapData,"merc"+u.tr+"-"+state+"-"+key+"-pixels.png");
            var pixel:Point=iris(b,p.id,u.tr,p.frame);
            records.push({variant:u.tr,state:state,pose:{id:p.id,frame:p.frame,x:p.x,y:p.y},nativeEye:pixel==null?null:{x:pixel.x,y:pixel.y},origin:{x:u.X,y:u.Y},eye:e,bitmapOrigin:{x:nativePoint.x,y:nativePoint.y},visMatrix:String(u.vis.transform.matrix),bitmapMatrix:String(b.transform.matrix),parentMatrix:String(b.parent.transform.matrix)});
            aligned(u,state+" row="+p.id+" frame="+p.frame,p.id,p.frame);
         }
         var sheet:BitmapData=new BitmapData(320*4,350*Math.ceil(frames.length/4),false,0x33404C);
         for(i=0;i<frames.length;i++){sheet.copyPixels(frames[i],frames[i].rect,new Point((i%4)*320,int(i/4)*350));frames[i].dispose();}
         savePNG(sheet,"merc"+u.tr+"-"+state+"-overlay.png");sheet.dispose();
         log+="CAPTURE merc"+u.tr+" "+state+" uniqueFrames="+frames.length+"\n";
      }
      private function frozenTransforms(u:*):void
      {
         u.dx=u.dy=0;u.blit(1,0);
         for each(var side:int in [1,-1]){u.storona=side;u.setVisPos();aligned(u,"frozen hover facing="+side,1);}
         // A frozen blit still reproduces: no next-frame race is required.
         var parent:DisplayObjectContainer=u.vis.parent,saved:Matrix=parent.transform.matrix.clone();
         parent.scaleX=parent.scaleY=1.7;parent.x+=81;parent.y-=33;
         aligned(u,"frozen hover with camera transform",1);parent.transform.matrix=saved;
         u.storona=1;u.setVisPos();u.stay=true;u.isFly=false;u.animate();
         aligned(u,"landed and stationary after flight",0);
      }
      private function nativeShots(w:*,m:*,u:*):void
      {
         var access:Class=domain.getDefinition("fe.unit.MSWBlindAccess") as Class;
         w.loc.units=[w.gg,u];m.cfg.laserAssist=false;m.cfg.laserNonFront=false;
         m.cfg.pointerEnabled=m.cfg.laserEnabled=true;
         for each(var id:String in ["mswdazzler","mswlaserpointer"])
         for each(var row:int in [0,1])for each(var side:int in [1,-1])
         {
            m.pointer.stop();m.laser.clear();u.storona=side;u.sost=1;u.hp=u.maxhp;u.setPos(650,280);u.setVisPos();u.blit(row,0);
            var b:Bitmap=bitmap(u.vis),pixel:Point=iris(b,row,u.tr);
            if(pixel==null){check(false,"native shot eye pixels missing merc"+u.tr);continue;}
            if(u.tr!=5)pixel.x+=1.5;
            var eye:Point=u.vis.parent.globalToLocal(b.localToGlobal(pixel));
            w.gg.setPos(eye.x+side*100,eye.y+230);w.gg.storona=-side;w.gg.setVisPos();
            if(w.gg.currentWeapon==null || w.gg.currentWeapon.id!=id)w.gg.changeWeapon(id,true);
            var wp:*=w.gg.currentWeapon;
            w.cam.celX=eye.x*w.cam.scaleV+w.cam.vx;w.cam.celY=eye.y*w.cam.scaleV+w.cam.vy;
            w.celX=w.gg.celX=eye.x;w.celY=w.gg.celY=eye.y;
            for(var i:int=0;i<12;i++){w.gg.setWeaponPos();wp.step();}wp.getBulXY();
            var hp:Number=u.hp,shots:Number=Number(m.cfg.diag.laserShots||0),label:String=id+" merc"+u.tr+" manual visual eye row="+row+" facing="+side;
            if(id=="mswlaserpointer")
            {m.pointer.prepare(w);wp.step();w.ctr.keyAttack=true;wp.attack();m.pointer.frame(w);check(m.pointer.lit,"native pointer on "+label);}
            else
            {wp.hold=12;wp.t_attack=wp.t_reload=wp.t_auto=0;wp.is_shoot=false;wp.t_prep=20;wp.attack();wp.step();check(Number(m.cfg.diag.laserShots||0)==shots+1,"native gun fired "+label);}
            check(m.laser.blind.remaining(u)==6,"blind "+label+" remain="+m.laser.blind.remaining(u));
            check(u.hp==hp,"zero damage "+label);
         }
         m.pointer.stop();m.laser.clear();
         check(m.cfg.diag.pointerError==null && m.cfg.diag.laserError==null,"no laser or pointer callback errors");
      }
      private function savePNG(b:BitmapData,name:String):void
      {
         var enc:Class=getDefinitionByName("flash.display.PNGEncoderOptions") as Class,bytes:*=Object(b)["encode"](b.rect,new enc());
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeBytes(bytes);fs.close();
      }
      private function write(name:String,s:String):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
         var fs:*=new S();fs.open(F["applicationStorageDirectory"].resolvePath(name),"write");fs.writeUTFBytes(s);fs.close();
      }
      private function finish(pass:Boolean,error:String):void
      {
         timer.stop();write("eye-alignment.txt",log+(error?"FAIL "+error+"\n":"")+(pass?"PASS eye alignment":"FAIL eye alignment")+"\n");
         var app:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;app["nativeApplication"].exit(pass?0:1);
      }
   }
}
