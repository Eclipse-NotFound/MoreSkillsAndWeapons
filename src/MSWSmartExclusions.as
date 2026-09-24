package
{
   /** MSW's user-selected target exclusions. Match exact entity IDs, not faction or shared AI class. */
   public class MSWSmartExclusions
   {
      public static const GROUPS:Array=[
         ["bio","生物"],["nests","云团与巢穴"],["small","小型机械"],
         ["mines","普通地雷"],["devices","机关与装置"]
      ];
      // key, group, player label, concrete entity IDs (including all variants).
      public static const DEFINITIONS:Array=[
         ["bloodwing","bio","血翼","bloodwing bloodwing2"],
         ["fish","bio","鱼类","fish1 fish2 fish3"],
         ["tarakan","bio","辐射蟑螂","tarakan"],
         ["rat","bio","老鼠","rat"],
         ["molerat","bio","鼹鼠","molerat"],
         ["scorp","bio","辐射蝎","scorp1 scorp2 scorp3"],
         ["ant","bio","蚂蚁","ant1 ant2 ant3"],
         ["slime","bio","史莱姆","slime cryoslime pinkslime"],
         ["bloat","bio","肉食灵","bloat0 bloat1 bloat2 bloat3 bloat4 bloat5 bloat6 bloat7 bloat8 bloat9 bloat10"],
         ["necros","nests","死灵云团","necros"],
         ["ebloat","nests","肉食灵巢穴","ebloat"],
         ["eant","nests","蚁穴","eant"],
         ["spritebot","small","机械精灵","spritebot"],
         ["vortex","small","旋翼机","vortex"],
         ["roller","small","电击球","roller roller2"],
         ["msp","small","蜘蛛地雷","msp"],
         ["dron","small","无马机","dron1 dron2 dron3"],
         ["hmine","mines","土制地雷","hmine"],
         ["mine","mines","破片地雷","mine"],
         ["plamine","mines","等离子地雷","plamine"],
         ["impmine","mines","脉冲地雷","impmine"],
         ["zebmine","mines","斑马破片地雷","zebmine"],
         ["balemine","mines","野火地雷","balemine"],
         ["trigcans","devices","瓶罐警铃","trigcans"],
         ["trigridge","devices","绊线","trigridge"],
         ["trigplate","devices","压力板","trigplate"],
         ["triglaser","devices","激光传感器","triglaser"],
         ["damshot","devices","陷阱枪","damshot"],
         ["damgren","devices","蹄雷串","damgren"],
         ["damexpl1","devices","部署好的炸药","damexpl1"],
         ["transmitter","devices","发报机","transmitter"]
      ];
      private static var byId:Object=makeIndex();
      private static function makeIndex():Object
      {
         var result:Object={};
         for each(var d:Array in DEFINITIONS)
            for each(var id:String in String(d[3]).split(" ")) result[id]=d[0];
         return result;
      }
      public static function copy(value:*):Object
      {
         var result:Object={};
         if(value==null || !(value is Object)) return result;
         for each(var d:Array in DEFINITIONS)
            if(value.hasOwnProperty(d[0]) && value[d[0]]===true) result[d[0]]=true;
         return result;
      }
      public static function excludes(unit:*,selected:Object):Boolean
      {
         if(unit==null || selected==null) return false;
         var id:String=MSWU.str(unit,"id");
         return byId.hasOwnProperty(id) && selected[byId[id]]===true;
      }
      public static function items(mod:*,group:String):Array
      {
         var result:Array=[];
         for each(var d:Array in DEFINITIONS)
            if(d[1]==group) result.push(item(mod,d));
         return result;
      }
      private static function item(mod:*,d:Array):Object
      {
         var key:String=d[0],label:String=d[2];
         var detail:String=key=="bloat"?"包括肉食灵王；巢穴单独设置。":
            key=="dron"?"包括安保、战斗、英克雷无马机；不含雷霆之首的特殊部件。":"同类变种一并生效。";
         return {key:"smartExclude_"+key,label:label,kind:"check",min:0,max:0,step:1,def:false,suffix:"",
            hint:"勾选后不锁定此类目标。"+detail+"单/多锁共用；在途弹停止追踪，取消后重新获取。",
            get:function():Boolean {return mod.cfg.smartExclusions[key]===true;},
            set:function(value:*):void {
               if(value===true) mod.cfg.smartExclusions[key]=true;
               else delete mod.cfg.smartExclusions[key];
               mod.cfg.save();
            }};
      }
      public static function register(mod:*):void
      {
         var combined:Array=[],groups:Array=[];
         for each(var group:Array in GROUPS)
         {
            var keys:Array=[],labels:Object={};
            for each(var option:Object in items(mod,group[0]))
            {
               keys.push(option.key); labels[option.key]=option.label;
               option.label=group[1]+" · "+option.label;
               combined.push(option);
            }
            groups.push({id:group[0],label:group[1],keys:keys,itemLabels:labels,
               offLabel:"未豁免",mixedLabel:"部分豁免",onLabel:"全部豁免",setAll:groupSetter(mod,group[0])});
         }
         mod.settings.registerPage("msw-exempt","锁定豁免",combined,null,
            "勾选＝不锁定；大类按钮全选/清空，展开可逐项调整。单/多锁共用。恢复默认清除全部豁免，普通子弹碰撞和伤害不变。",groups);
      }
      private static function groupSetter(mod:*,groupId:String):Function
      {
         return function(value:Boolean):void {
            for each(var d:Array in DEFINITIONS) if(d[1]==groupId)
            {
               if(value) mod.cfg.smartExclusions[d[0]]=true;
               else delete mod.cfg.smartExclusions[d[0]];
            }
            mod.cfg.save();
         };
      }
   }
}
