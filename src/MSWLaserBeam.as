package
{
   import fe.Pt;
   /** Original laser-pistol art and four simulation-step fade, visuals only. */
   public class MSWLaserBeam extends Pt
   {
      private var age:int=0;
      public function MSWLaserBeam(w:*,wp:*,hit:Object)
      {
         super();var self:*=this;
         var asset:Class=wp.vBullet;
         self.loc=w.loc;self.sloy=2;self.X=hit.x;self.Y=hit.y;
         self.vis=new asset();self.vis.stop();self.vis.name="MSWLaserBeam";
         self.vis.x=hit.x;self.vis.y=hit.y;self.vis.rotation=hit.angle*180/Math.PI;
         self.vis.laser.scaleX=hit.distance/100;self.vis.blendMode=wp.bulBlend;
         self.loc.addObj(this);
      }
      public function dispose():void
      {
         var self:*=this;
         if(self.vis!=null && self.vis.parent!=null)self.vis.parent.removeChild(self.vis);
         if(self.in_chain)self.loc.remObj(this);
      }
      override public function step():*
      {
         var self:*=this;age++;
         if(age>=4)dispose();else self.vis.alpha=(4-age)/4;
      }
   }
}
