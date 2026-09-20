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
   }
}
