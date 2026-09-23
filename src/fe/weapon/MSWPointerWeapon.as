package fe.weapon
{
   import flash.utils.describeType;
   /** Native input consumes one press; no native shot, reload or replay event. */
   public class MSWPointerWeapon extends Weapon
   {
      public var onPress:Function;
      public var onStep:Function;
      public function MSWPointerWeapon(original:*)
      {
         super(original.owner,original.id,original.variant);
         var self:*=this;
         for each(var field:XML in describeType(original).variable)
         {var key:String=String(field.@name);self[key]=original[key];}
      }
      override public function attack(sats:Boolean=false):Boolean
      {
         if(!sats && onPress!=null)onPress(this);
         return false;
      }
      override protected function shoot():Bullet {return null;}
      override public function step():*
      {
         super.step();
         if(onStep!=null)onStep(this);
      }
   }
}
