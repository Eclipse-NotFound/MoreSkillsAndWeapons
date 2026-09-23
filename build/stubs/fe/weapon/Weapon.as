package fe.weapon
{
   import fe.Pt;
   public class Weapon extends Pt
   {
      public function Weapon(owner:*,id:String,variant:int=0) { super(); }
      public function attack(sats:Boolean=false):Boolean { return false; }
      protected function shoot():Bullet { return null; }
   }
}
