package
{
   import flash.utils.getDefinitionByName;
   /** Test fixture: a solid map rectangle, never a prop pretending to be a wall. */
   public class LaserTestWall
   {
      public static function put(loc:*,x1:Number,x2:Number,y1:Number,y2:Number):Array
      {
         var T:Class=getDefinitionByName("fe.loc.Tile") as Class,saved:Array=[];
         var sx:Number=T["tileX"],sy:Number=T["tileY"];
         for(var x:int=Math.floor(x1/sx);x<Math.ceil(x2/sx);x++)
         for(var y:int=Math.floor(y1/sy);y<Math.ceil(y2/sy);y++)
         {
            var t:*=loc.getTile(x,y);
            saved.push({t:t,phis:t.phis,x1:t.phX1,x2:t.phX2,y1:t.phY1,y2:t.phY2});
            t.phis=1;t.phX1=Math.max(x1,x*sx);t.phX2=Math.min(x2,(x+1)*sx);
            t.phY1=Math.max(y1,y*sy);t.phY2=Math.min(y2,(y+1)*sy);
         }
         return saved;
      }
      public static function restore(saved:Array):void
      {for each(var s:Object in saved){s.t.phis=s.phis;s.t.phX1=s.x1;s.t.phX2=s.x2;s.t.phY1=s.y1;s.t.phY2=s.y2;}}
   }
}
