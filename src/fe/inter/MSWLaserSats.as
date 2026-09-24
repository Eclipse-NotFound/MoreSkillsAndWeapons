package fe.inter
{
   /** Same-package, externally linked access; never defines a host class. */
   public class MSWLaserSats
   {
      public static function target(entry:*):*
      {
         var c:SatsCel=entry as SatsCel;
         return c!=null && c.un!=null ? c.un.u : null;
      }
      public static function refreshLabels(sats:*,weapon:*):void
      {
         if(sats==null || !sats.active || weapon==null || sats.weapon!==weapon)return;
         // Native candidate clips retain their hover/click handlers and queue
         // identity. Only this gun's inapplicable probability text is replaced.
         for each(var row:Object in sats.units)
         {
            if(row==null || row.u==null || row.v==null)continue;
            var label:*=row.v.getChildByName("su");
            if(label==null || label.txt==null)continue;
            // Flash TextField stores line breaks as CR; compare the same form
            // so an unchanged label is not reassigned on every frame.
            var text:String=String(row.u.nazv)+"\r瞄眼";
            if(label.txt.text!=text)label.txt.text=text;
         }
      }
   }
}
