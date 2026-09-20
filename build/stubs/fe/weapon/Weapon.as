package fe.weapon
{
   import fe.Pt;
   public class Weapon extends Pt
   {
      public function Weapon(owner:*,id:String,variant:int=0) { super(); }
      protected function shoot():Bullet { return null; }
   }
}
