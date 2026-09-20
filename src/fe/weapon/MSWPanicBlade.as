package fe.weapon
{
   import flash.utils.describeType;
   /** WClub reuses an unlinked Bullet for its actual swept blade geometry.
    * Keep that native geometry/damage, enabling friendly contact only for a
    * swing started while blind, including its remainder after recovery. */
   public class MSWPanicBlade extends Bullet
   {
      private var active:Boolean=false;
      private var lastAttack:Number=0;
      public function MSWPanicBlade(original:*)
      {
         super(original.owner,original.X,original.Y,null,false);
         var self:*=this;
         for each(var field:XML in describeType(original).variable)
         {var key:String=String(field.@name);self[key]=original[key];}
      }
      public function arm():void
      {active=true;lastAttack=Object(this).weap.t_attack;}
      override public function run(div:int=1):*
      {
         var self:*=this,t:Number=self.weap.t_attack;
         if(t>lastAttack)active=false; // A later ordinary swing is not panic.
         lastAttack=t;
         var old:*=self.targetObj;
         if(active)
         {
            var x:Number=self.X+self.dx/div,y:Number=self.Y+self.dy/div;
            self.targetObj=null;
            for each(var u:* in self.loc.units)
            {
               if(u===self.owner || u.loc!==self.loc || u.disabled || u.trigDis || u.sost>=3)continue;
               if(x>=u.X1 && x<=u.X2 && y>=u.Y1 && y<=u.Y2) {self.targetObj=u;break;}
            }
         }
         try {super.run(div);}
         finally {self.targetObj=old;}
      }
   }
}
