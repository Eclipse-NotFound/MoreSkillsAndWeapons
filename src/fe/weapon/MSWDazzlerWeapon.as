package fe.weapon
{
   import flash.utils.describeType;
   /** Native weapon lifecycle, with one synchronous callback per actual shot. */
   public class MSWDazzlerWeapon extends Weapon
   {
      public var onShot:Function;
      public function MSWDazzlerWeapon(original:*)
      {
         super(original.owner,original.id,original.variant);
         var self:*=this;
         for each(var field:XML in describeType(original).variable)
         {var key:String=String(field.@name);self[key]=original[key];}
      }
      override protected function shoot():Bullet
      {
         var self:*=this,hold:Number=self.hold,count:int=self.kol_shoot;
         var result:Bullet=super.shoot();
         if(self.kol_shoot>count)
         {
            // The configured shots per magazine is exact even with recyc.
            self.hold=hold-self.rashod;
            if(onShot!=null)onShot(this);
         }
         return result;
      }
   }
}
