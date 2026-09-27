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

   /** TEST ONLY: native bitmap asset/pose catalog, independent of production. */
   public class EyeCatalogSmoke extends Sprite
   {
      private static var probe:EyeCatalogSmoke;
      private var host:*,loader:Loader=new Loader(),timer:Timer=new Timer(100);
      private var domain:ApplicationDomain,ticks:int=0,started:Boolean=false,log:String="";
      private var records:Array=[];
      private var failures:int=0;
      public function EyeCatalogSmoke() {}
      public static function init(main:*):void {probe=new EyeCatalogSmoke();probe.start(main);}
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
      private function catalog(w:*):void
      {
         var all:Class=domain.getDefinition("fe.AllData") as Class,data:XML=all["d"];
         var eyes:Class=domain.getDefinition("MSWLaserEyes") as Class,access:Class=domain.getDefinition("fe.unit.MSWBlindAccess") as Class;
         var assets:Array=[];
         for each(var xml:XML in data.unit)
         {
            if(!xml.vis.@blit.length())continue;
            var asset:String=String(xml.vis.@blit),bd:BitmapData=w.grafon.getSpriteList(asset);
            if(bd==null)continue;
            var base:XML=data.unit.(@id==xml.@parent)[0],an:Object={};
            if(base!=null)for each(var a:XML in base.blit)an[String(a.@id)]={state:String(a.@id),row:int(a.@y),length:a.@len.length()?int(a.@len):1};
            for each(a in xml.blit)an[String(a.@id)]={state:String(a.@id),row:int(a.@y),length:a.@len.length()?int(a.@len):1};
            var anims:Array=[];for each(var aa:Object in an)anims.push(aa);
            var id:String=String(xml.@id),parent:String=String(xml.@parent),spawn:String=parent||id,cid:String=null;
            if(parent)cid=id.substr(parent.length);
            if(id=="protect1"){spawn="protect";cid="1";}
            if(id=="gutsy1"){spawn="gutsy";cid="1";}
            if(id=="scorp1" || id=="scorp2"){spawn="scorp";cid=id;}
            assets.push({id:id,asset:asset,spawn:spawn,cid:cid,width:int(xml.vis.@sprX),height:xml.vis.@sprY.length()?int(xml.vis.@sprY):int(xml.vis.@sprX),anims:anims});
            savePNG(bd,asset+".png");
         }
         write("assets.json",JSON.stringify(assets,null,2));
         var specs:Array=assets.concat();
         for each(var obj:XML in data.obj){var name:String=String(obj.@id),cl:String=String(obj.@cl);if(["UnitTurret","UnitRobobrain","UnitSentinel","UnitBossUltra","UnitBossDron","UnitRoller","UnitSpriteBot","UnitVortex","UnitDron","UnitMsp","UnitThunderHead","UnitBat","UnitFish","UnitBloat","UnitBossRaider","UnitBossNecr"].indexOf(cl)>=0)specs.push({id:name,spawn:name,cid:null,anims:[]});}
         var tiles:Array=[];
         for each(var spec:Object in specs)
         {
            if(spec.id=="phoenix" || spec.id=="owl")continue;
            var u:*=w.loc.createUnit(spec.spawn,600,320,true,null,spec.cid);
            if(u==null){log+="SKIP "+spec.id+" no unit\n";continue;}
            u.storona=1;u.sost=1;u.stay=true;u.dx=u.dy=0;u.setPos(600,320);u.actions();u.setVisPos();u.animate();u.vis.visible=true;
            if(u.vis is MovieClip)MovieClip(u.vis).stop();
            if(spec.spawn.indexOf("turret")>=0 && u.vis.osn!=null)u.vis.osn.gotoAndStop(1);
            var poses:Array=[];
            if(spec.asset)
            {
               var seen:Object={};
               for each(aa in spec.anims)
               {
                  if(["die","death","fall"].indexOf(aa.state)>=0)continue;
                  for(var f:int=0;f<aa.length;f++)
                  {
                     var key:String=aa.row+"-"+f;if(seen[key])continue;seen[key]=true;
                     u.blit(aa.row,f);var p:Object=access["pose"](u),eye:Object=eyes["point"](u);
                     var b:Bitmap=bitmap(u.vis),pixel:Point=b.globalToLocal(u.vis.parent.localToGlobal(new Point(eye.x,eye.y)));
                     poses.push({row:aa.row,frame:f,state:aa.state,eye:[pixel.x,pixel.y]});
                  }
               }
               u.blit(0,0);
            }
            var bounds:Rectangle=u.vis.getBounds(u.vis),scale:Number=Math.min(4,230/bounds.width,235/bounds.height),mat:Matrix=new Matrix(scale,0,0,scale,125-(bounds.x+bounds.width/2)*scale,245-bounds.bottom*scale);
            var tile:BitmapData=new BitmapData(250,280,false,0x33404C);tile.draw(u.vis,mat);
            var e:Object=eyes["point"](u),lp:Point=u.vis.globalToLocal(u.vis.parent.localToGlobal(new Point(e.x,e.y))),mark:Sprite=new Sprite();
            lp=mat.transformPoint(lp);mark.graphics.lineStyle(1,0xFF6666);mark.graphics.drawCircle(lp.x,lp.y,6);tile.draw(mark);
            var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("_sans",13,0xFFFFFF);label.width=245;label.text=spec.id;tile.draw(label,new Matrix(1,0,0,1,4,255));tiles.push(tile);
            savePNG(tile,"actor-"+spec.id+".png");
            records.push({id:spec.id,type:flash.utils.getQualifiedClassName(u),tr:Object(u).hasOwnProperty("tr")?u.tr:null,poses:poses,eyeLocal:[e.x-u.vis.x,e.y-u.vis.y],tree:tree(u.vis)});
            log+="CAPTURE "+spec.id+" poses="+poses.length+"\n";
            u.exterminate();
         }
         for(var start:int=0;start<tiles.length;start+=24){var count:int=Math.min(24,tiles.length-start),sheet:BitmapData=new BitmapData(1500,280*Math.ceil(count/6),false,0x33404C);for(var i:int=0;i<count;i++)sheet.copyPixels(tiles[start+i],tiles[start+i].rect,new Point(i%6*250,int(i/6)*280));savePNG(sheet,"catalog-"+int(start/24)+".png");sheet.dispose();}
         write("catalog.json",JSON.stringify(records,null,2));
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
