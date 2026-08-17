package
{
   import flash.utils.Dictionary;

   /**
    * 可编程榴弹炮的武器侧管理：
    * - 运行时向 AllData.d 注入 <weapon id='mswglau'> 节点（克隆自 glau）
    * - 会话内发放武器 + 初始弹药（走原厂 Invent.addWeapon / plusItem）
    * - 每帧把当前配置应用到武器实例（grav / explRadius / noTrass / nazv）
    */
   public class MSWWeapon
   {
      public static const WEAPON_ID:String = "mswglau";
      public static const WEAPON_NAME:String = "可编程榴弹炮";

      private var mod:*;
      /** 武器实例 -> {origExpl:Number}（explRadius 被置 0 前保留原值） */
      private var reg:Dictionary = new Dictionary(true);

      public function MSWWeapon(m:*)
      {
         mod = m;
      }

      /** 模组初始化时调用一次；幂等。 */
      public function injectXml():void
      {
         try
         {
            var c:Class = MSWU.cls("fe.AllData");
            if(c == null) return;
            var d:XML = c["d"];
            if(d.weapon.(@id == WEAPON_ID).length() > 0) return;
            var node:XML = new XML(
               '<weapon id="' + WEAPON_ID + '" tip="3" cat="6" skill="5" lvl="3">' +
               '<char maxhp="100" damexpl="120" damage="0" rapid="25" prec="6" crit="0" tipdam="4" knock="50" destroy="600" expl="150"/>' +
               '<phis speed="35" grav="1" grav2="0" drot="8" deviation="8" recoil="5" massa="10" m="2"/>' +
               '<vis vweap="visglau" tipdec="9" vbul="gren40" spring="0"/>' +
               '<snd shoot="glau_s" reload="flamer_r" noise="800"/>' +
               '<sats noperc="1" cons="32"/>' +
               '<ammo holder="6" reload="60"/>' +
               '<a>gren40</a>' +
               '</weapon>');
            d.appendChild(node);
         }
         catch(e:*)
         {
         }
      }

      /** 每帧调用：世界就绪后发放武器（仅当尚未拥有）。 */
      public function provision(w:*):void
      {
         try
         {
            if(w == null) return;
            var loc:* = w["loc"];
            if(loc == null || !loc["active"]) return;
            var gg:* = w["gg"];
            if(gg == null || gg["ggControl"] != true) return;
            var invent:* = gg["invent"];
            if(invent == null) return;
            var weapons:* = invent["weapons"];
            if(weapons == null) return;
            if(weapons[WEAPON_ID] != null) return;
            var wp:* = invent["addWeapon"](WEAPON_ID);
            if(wp != null)
            {
               wp["nazv"] = WEAPON_NAME;
               invent["plusItem"]("gren40", 12);
            }
         }
         catch(e:*)
         {
         }
      }

      /** 每帧调用：把当前配置写到武器实例（开火时由游戏读取）。 */
      public function apply(w:*):void
      {
         try
         {
            if(w == null) return;
            var gg:* = w["gg"];
            if(gg == null) return;
            var invent:* = gg["invent"];
            if(invent == null) return;
            var weapons:* = invent["weapons"];
            if(weapons == null) return;
            var wp:* = weapons[WEAPON_ID];
            if(wp == null) return;
            var r:* = reg[wp];
            if(r == null)
            {
               r = {
                  origExpl: MSWU.num(wp, "explRadius", 150),
                  origDestroy: MSWU.num(wp, "destroy", 600),
                  origTipDec: MSWU.num(wp, "tipDecal", 9)
               };
               reg[wp] = r;
            }
            wp["nazv"] = WEAPON_NAME;
            wp["grav"] = mod.cfg.dropRate;
            wp["speed"] = mod.cfg.muzzleVel;
            wp["noTrass"] = true;
            if(mod.cfg.wallHits > 0)
            {
               // 飞行弹不带爆炸半径/破坏力/贴花：撞墙的 hitTile(0,..,0) 在
               // dyrka 里因 tipDecal==0 直接返回——反弹对墙壁零伤害零视觉
               // （玩家实测：未爆炸时墙壁不该有破坏动画）。爆炸时由
               // explode() 用 origDestroy/origTipDec 完整结算。
               wp["explRadius"] = 0;
               wp["destroy"] = 0;
               wp["tipDecal"] = 0;
            }
            else
            {
               wp["explRadius"] = r.origExpl;
               wp["destroy"] = r.origDestroy;
               wp["tipDecal"] = r.origTipDec;
            }
         }
         catch(e:*)
         {
         }
      }

      /** 爆炸半径原值（SATS 半径圈与手动引爆用）。 */
      public function origExplRadius(wp:*):Number
      {
         if(wp == null) return 150;
         var r:* = reg[wp];
         if(r != null && MSWU.has(r, "origExpl")) return MSWU.num(r, "origExpl", 150);
         return MSWU.num(wp, "explRadius", 150) > 0 ? MSWU.num(wp, "explRadius", 150) : 150;
      }

      /** 破坏力原值（手动引爆 explDestroy 用）。 */
      public function origDestroy(wp:*):Number
      {
         if(wp == null) return 600;
         var r:* = reg[wp];
         if(r != null && MSWU.has(r, "origDestroy")) return MSWU.num(r, "origDestroy", 600);
         return MSWU.num(wp, "destroy", 600) > 0 ? MSWU.num(wp, "destroy", 600) : 600;
      }

      /** 贴花类型原值（爆炸破坏瓦片时的裂痕视觉）。 */
      public function origTipDec(wp:*):Number
      {
         if(wp == null) return 9;
         var r:* = reg[wp];
         if(r != null && MSWU.has(r, "origTipDec")) return MSWU.num(r, "origTipDec", 9);
         return 9;
      }
   }
}
