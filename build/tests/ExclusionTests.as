package
{
   import flash.display.Sprite;
   import flash.net.SharedObject;
   import flash.utils.getDefinitionByName;
   public class ExclusionTests extends Sprite
   {
      private var n:int=0,log:String="";
      private function ok(v:Boolean,s:String):void {if(!v)throw new Error(s);n++;log+="PASS "+s+"\n";}
      public function ExclusionTests()
      {
         try {
            var c:MSWConfig=new MSWConfig(),hub:MSWSettingsHub=new MSWSettingsHub(),mod:Object={cfg:c,settings:hub};
            var legacy:SharedObject=SharedObject.getLocal("MSWConfig");legacy.clear();legacy.data.smartEnabled=true;legacy.data.smartMultiLock=true;legacy.flush();
            c.load();ok(c.smartEnabled && c.smartMultiLock && !MSWSmartExclusions.excludes({id:"rat"},c.smartExclusions),"old config preserves modes and excludes nothing");
            MSWSmartExclusions.register(mod);var pages:Array=hub.getPages(),sizes:Array=[9,3,5,6,8],labels:Array=["生物","云团与巢穴","小型机械","普通地雷","机关与装置"];
            ok(pages.length==1 && pages[0].modId=="msw-exempt" && pages[0].displayName=="锁定豁免","single exemption menu");var items:Object={},keys:int=0;
            for(var p:int=0;p<labels.length;p++) {
               var groupItems:Array=MSWSmartExclusions.items(mod,MSWSmartExclusions.GROUPS[p][0]);
               ok(groupItems.length==sizes[p],"group row count "+labels[p]);
               for each(var it:Object in groupItems){ok(!it.get() && it.def===false && pages[0].items[keys].label==labels[p]+" · "+it.label,"grouped default permits "+it.label);items[it.key]=it;keys++;}
            }
            ok(keys==31,"exactly 31 separate options");
            var cases:Array=[
               ["bloodwing","bloodwing bloodwing2"],["fish","fish1 fish2 fish3"],["tarakan","tarakan"],["rat","rat"],["molerat","molerat"],
               ["scorp","scorp1 scorp2 scorp3"],["ant","ant1 ant2 ant3"],["slime","slime cryoslime pinkslime"],
               ["bloat","bloat0 bloat1 bloat2 bloat3 bloat4 bloat5 bloat6 bloat7 bloat8 bloat9 bloat10"],
               ["necros","necros"],["ebloat","ebloat"],["eant","eant"],["spritebot","spritebot"],["vortex","vortex"],
               ["roller","roller roller2"],["msp","msp"],["dron","dron1 dron2 dron3"],
               ["hmine","hmine"],["mine","mine"],["plamine","plamine"],["impmine","impmine"],["zebmine","zebmine"],["balemine","balemine"],
               ["trigcans","trigcans"],["trigridge","trigridge"],["trigplate","trigplate"],["triglaser","triglaser"],
               ["damshot","damshot"],["damgren","damgren"],["damexpl1","damexpl1"],["transmitter","transmitter"]
            ];
            for each(var row:Array in cases) {
               it=items["smartExclude_"+row[0]];it.set(true);
               for each(var id:String in String(row[1]).split(" "))ok(MSWSmartExclusions.excludes({id:id},c.smartExclusions),"selected category excludes "+id);
               for each(var other:Array in cases)if(other[0]!=row[0])ok(!MSWSmartExclusions.excludes({id:String(other[1]).split(" ")[0]},c.smartExclusions),row[0]+" does not exclude "+other[0]);
               var fresh:MSWConfig=new MSWConfig();fresh.load();ok(fresh.smartExclusions[row[0]]===true,"checkbox saves immediately "+row[0]);
               it.set(false);ok(!it.get(),"option can be cleared "+row[0]);
            }
            for each(it in items)it.set(true);
            for each(id in "raider1 slaver1 zebra1 merc1 ranger1 encl1 alicorn1 zombie0 hellhound1 protect robobrain gutsy eqd sentinel turret0 bossraider bossalicorn bossnecr bossultra bossdron bossencl dront ttur thunderhead destr1 training phoenix owl moon rat2 scorp99 bloat11 toString constructor".split(" "))
               ok(!MSWSmartExclusions.excludes({id:id},c.smartExclusions),"scope does not expand to "+id);
            ok(!MSWSmartExclusions.excludes(null,c.smartExclusions) && !MSWSmartExclusions.excludes({},c.smartExclusions),"missing targets and IDs are harmless");
            pages[0].items[3].set(false);ok(!c.smartExclusions.rat && c.smartExclusions.molerat,"same AI class species stay independent");
            for each(it in pages[0].items)it.set(it.def);
            ok(!c.smartExclusions.mine && !c.smartExclusions.balemine && !c.smartExclusions.msp && !c.smartExclusions.trigplate && c.smartEnabled && c.smartMultiLock,"single menu reset clears all groups and preserves smart modes");
            c.smartExclusions={rat:true,mine:"true",ant:1,raider:true};c.save();fresh=new MSWConfig();fresh.load();
            ok(fresh.smartExclusions.rat===true && !fresh.smartExclusions.mine && !fresh.smartExclusions.ant && !fresh.smartExclusions.hasOwnProperty("raider"),"stored data keeps only supported boolean selections");
            var a:Object={},b:Object={},lock:MSWSmartLock=new MSWSmartLock();lock.advance(a,false,0.6,c);lock.advance(b,true,0.2,c);lock.clearCandidate();
            ok(lock.target===a && lock.strength==1 && lock.candidate==null && lock.progress==0,"discard excluded candidate without losing valid old target");
            finish("PASS "+n+" assertions",0);
         }catch(e:*){finish("FAIL "+e+"\n"+e.getStackTrace(),1);}
      }
      private function finish(result:String,code:int):void
      {
         var F:Class=getDefinitionByName("flash.filesystem.File") as Class,S:Class=getDefinitionByName("flash.filesystem.FileStream") as Class,s:*=new S();
         s.open(F["applicationStorageDirectory"].resolvePath("results.txt"),"write");s.writeUTFBytes(log+result+"\n");s.close();
         getDefinitionByName("flash.desktop.NativeApplication")["nativeApplication"].exit(code);
      }
   }
}
