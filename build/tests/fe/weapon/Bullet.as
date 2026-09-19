package fe.weapon
{
   /** 仅测试源路径包含此类；模拟对象链与 public 字段，不进入发布 SWF。 */
   public dynamic class Bullet
   {
      public function Bullet(owner:*, x:Number, y:Number, visClass:Class = null, dummy:Boolean = false)
      {
         this.owner = owner;
         this.X = this.begx = x; this.Y = this.begy = y;
         this.dx = this.vel = 10; this.dy = 0; this.liv = 100; this.damage = 100;
         this.damageExpl = this.explRadius = this.brakeR = this.tipDamage = 0;
         this.babah = false; this.weap = {id:"pistol"}; this.weapId = "pistol";
         this.vRot = true; this.flare = null; this.vis = null; this.dist = 123;
         this.nobj = owner.loc.firstObj;
         owner.loc.firstObj = this;
      }
   }
}
