package
{
   import flash.display.Sprite;
   public class LaserSmokeMod extends Sprite
   {
      public var entry:Class=MoreSkillsWeaponsMod;
      private var probe:*;
      public function LaserSmokeMod()
      {
         try { trace("LASER constructor"); probe=new LaserProbe(); trace("LASER probe ready"); }
         catch(e:*) {trace("LASER ERROR "+e+"\n"+e.getStackTrace());}
      }
   }
}
