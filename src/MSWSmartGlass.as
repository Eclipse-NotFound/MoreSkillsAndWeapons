package
{
   /** Optical transparency and planned destruction never change native collision. */
   public class MSWSmartGlass
   {
      public static const VERSION:String="1-windows";
      public static function window(t:*):Boolean
      {
         if(t==null || !("door" in t) || t.door==null)return false;
         return t.door.id=="window1" || t.door.id=="window2";
      }
      public static function breakable(loc:*,t:*,b:*):Boolean
      {
         if(b==null || !window(t) || t.door.id!="window1")return false;
         var damage:int=int(MSWU.num(b,"destroy"));
         if(damage<=0 || t.indestruct || t.thre>damage || (!loc.destroyOn && t.hp>500))return false;
         if(MSWU.num(b,"tipDecal")==100 && damage<=50 && t.thre>0)return false;
         // Explosion terrain damage uses the same hitTile rules, but samples
         // tile centres. Only a blast covering the whole impact tile is certain.
         var blast:Number=MSWU.num(b,"explRadius");
         if(blast>0 && blast<=Math.sqrt(20*20+20*20))return false;
         if(t.door.dead || (t.door.inter!=null && t.door.inter.prize))return false;
         return true;
      }
      public static function routeKey(b:*):String
      {
         return int(MSWU.num(b,"destroy"))+":"+MSWU.num(b,"tipDecal")+":"+MSWU.num(b,"explRadius");
      }
      public static function visible(loc:*,x:Number,y:Number,tx:Number,ty:Number):Boolean
      {
         // Match Location.isLine's 9px sampling and open endpoints; ignore only
         // the two native window identities, never material 5 or other breakables.
         var n:int=Math.floor(Math.max(Math.abs(tx-x),Math.abs(ty-y))/9)+1;
         if(n>600)return false;
         for(var i:int=1;i<n;i++)
         {
            var px:Number=x+(tx-x)*i/n,py:Number=y+(ty-y)*i/n;
            var t:*=loc.getAbsTile(Math.floor(px),Math.floor(py));
            if(t==null)return false;
            if(t.phis==1 && px>=t.phX1 && px<=t.phX2 && py>=t.phY1 && py<=t.phY2 && !window(t))return false;
         }
         return true;
      }
   }
}
