package
{
   import flash.display.Sprite;
   /** 测试专用文档类：游戏仍从 pfe.swf 启动，沿原 loader 调用生产入口。 */
   public class SmokeMod extends Sprite
   {
      public var entry:Class=MoreSkillsWeaponsMod;
      private var probe:GameSmoke;
      public function SmokeMod() { probe=new GameSmoke(); }
   }
}
