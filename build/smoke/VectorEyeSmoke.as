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

   /** TEST ONLY: native vector poses and coordinate-preserving raw visuals. */
   public class VectorEyeSmoke extends Sprite
   {
      private static var probe:VectorEyeSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,started:Boolean=false,log:String="";
      private var records:Array=[];
      private var failures:int=0;
      public function VectorEyeSmoke() {}
      public static function init(main:*):void {probe=new VectorEyeSmoke();probe.start(main);}
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
            catalog(w);
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
      private function tree(node:DisplayObject,path:String="",depth:int=0):Array
      {
         var a:Array=[],r:Rectangle=node.getBounds(node);
         a.push({path:path,name:node.name,type:flash.utils.getQualifiedClassName(node),x:node.x,y:node.y,r:node.rotation,sx:node.scaleX,sy:node.scaleY,frame:node is MovieClip?MovieClip(node).currentFrame:0,frames:node is MovieClip?MovieClip(node).totalFrames:0,bounds:[r.x,r.y,r.width,r.height]});
         if(depth<5 && node is DisplayObjectContainer){var c:DisplayObjectContainer=DisplayObjectContainer(node);for(var i:int=0;i<c.numChildren;i++)a=a.concat(tree(c.getChildAt(i),path+"/"+c.getChildAt(i).name,depth+1));}return a;
      }
      private function advance(node:DisplayObject,f:int,depth:int=0):void
      {
         if(depth>0 && node is MovieClip && MovieClip(node).totalFrames>1)MovieClip(node).gotoAndStop(Math.min(f,MovieClip(node).totalFrames));
         if(depth<6 && node is DisplayObjectContainer){var c:DisplayObjectContainer=DisplayObjectContainer(node);for(var i:int=0;i<c.numChildren;i++)advance(c.getChildAt(i),f,depth+1);}
      }
      private function catalog(w:*):void
      {
         var specs:Array=[],base:Array=["robot","sentinel","ultra","megadron","roller","spritebot","vortex","msp","bossraider","bossnecr"];
         for each(var id:String in base)specs.push({id:id,cid:null});
         for each(id in ["bloodwing","fish","bloat","dron"]){var max:int=id=="bloat"?10:(id=="dron"?3:2),min:int=id=="bloat"?0:1;for(var n:int=min;n<=max;n++)specs.push({id:id,cid:String(n)});}
         var eyes:Class=domain.getDefinition("MSWLaserEyes") as Class;
         for each(var spec:Object in specs)
         {
            var u:*=w.loc.createUnit(spec.id,600,320,true,null,spec.cid);if(u==null)continue;
            u.storona=1;u.sost=1;u.stay=true;u.dx=u.dy=0;u.setPos(600,320);u.actions();u.setVisPos();u.animate();u.vis.visible=true;
            var key:String=spec.id+(spec.cid==null?"":spec.cid),osn:MovieClip=u.vis.osn,poses:Array=[],tiles:Array=[];
            for(var outer:int=1;outer<=osn.totalFrames;outer++)
            {
               osn.gotoAndStop(outer);if(osn.currentLabel=="die")continue;
               for each(var f:int in [1,8,16])
               {
                  advance(osn,f);var bounds:Rectangle=u.vis.getBounds(u.vis),scale:Number=Math.min(4,270/bounds.width,260/bounds.height),mat:Matrix=new Matrix(scale,0,0,scale,140-(bounds.x+bounds.width/2)*scale,265-bounds.bottom*scale);
                  var tile:BitmapData=new BitmapData(290,300,false,0x33404C);tile.draw(u.vis,mat);
                  var e:Object=eyes["point"](u),lp:Point=u.vis.globalToLocal(u.vis.parent.localToGlobal(new Point(e.x,e.y))),mark:Sprite=new Sprite();lp=mat.transformPoint(lp);mark.graphics.lineStyle(1,0xFF6666);mark.graphics.drawCircle(lp.x,lp.y,5);tile.draw(mark);
                  var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("_sans",12,0xFFFFFF);label.width=285;label.text=key+" osn="+outer+" "+osn.currentLabel+" inner="+f;tile.draw(label,new Matrix(1,0,0,1,3,277));tiles.push(tile);
                  poses.push({outer:outer,inner:f,label:osn.currentLabel,eye:[e.x-u.vis.x,e.y-u.vis.y],tree:tree(u.vis)});
                  // A coordinate-preserving raw visual supports independent annotations.
                  var raw:BitmapData=new BitmapData(400,320,true,0);raw.draw(u.vis,new Matrix(1,0,0,1,200,250));savePNG(raw,key+"-"+outer+"-"+f+".png");raw.dispose();
               }
            }
            var sheet:BitmapData=new BitmapData(870,300*Math.ceil(tiles.length/3),false,0x33404C);for(var i:int=0;i<tiles.length;i++)sheet.copyPixels(tiles[i],tiles[i].rect,new Point(i%3*290,int(i/3)*300));savePNG(sheet,"vector-"+key+".png");sheet.dispose();
            records.push({id:spec.id,cid:spec.cid,key:key,poses:poses});write("catalog.json",JSON.stringify(records,null,2));log+="CAPTURE "+key+" poses="+poses.length+"\n";u.exterminate();
         }
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
