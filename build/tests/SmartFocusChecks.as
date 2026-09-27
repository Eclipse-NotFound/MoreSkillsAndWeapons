package
{
   import flash.net.SharedObject;
   public class SmartFocusChecks
   {
      public static function run(ok:Function):void
      {
         var cfg:MSWConfig=new MSWConfig(),multi:MSWSmartMultiLock=new MSWSmartMultiLock(),focus:MSWSmartFocus=new MSWSmartFocus();
         var a:Object={X1:0,X2:40,Y1:0,Y2:60,hp:100,sost:1},b:Object={X1:30,X2:70,Y1:0,Y2:60,hp:100,sost:1};
         var valid:Function=function(u:*):Boolean{return u.hp>0 && u.sost<3;};
         ok(!cfg.smartFocus && cfg.smartFocusRadius==48,"focus defaults off with independent 48 radius");
         multi.advance([a,b],[a,b],0.3,cfg);
         ok(focus.select(multi.locks,20,30,48,valid)==null,"hover does not skip acquisition");
         multi.advance([a,b],[a,b],0.3,cfg);
         ok(focus.select(multi.locks,20,30,48,valid).target===a,"body directly pointed at wins over nearby body");
         ok(focus.select(multi.locks,37,30,48,valid).target===b,"overlap chooses nearer center without dwell");
         ok(focus.select(multi.locks,35,30,48,valid).target===b,"exact tie retains current focus");
         ok(focus.select(multi.locks,71,30,0,valid)==null,"zero range excludes even one pixel outside body");
         ok(focus.select(multi.locks,70,30,0,valid).target===b,"zero range includes body boundary");
         ok(focus.select(multi.locks,118,30,48,valid).target===b,"outer range boundary is inclusive");
         ok(focus.select(multi.locks,118.1,30,48,valid)==null,"moving outside range releases immediately");
         focus.select(multi.locks,20,30,48,valid);
         ok(multi.pick().target===a && multi.pick().target===b,"focus selection never consumes round-robin cursor");
         multi.stateFor(a).strength=0.4;
         ok(focus.select(multi.locks,20,30,48,valid).strength==0.4,"focus keeps decaying lock strength without refill");
         a.hp=0;
         ok(focus.select(multi.locks,37,30,48,valid)==null,"focused death blocks nearby auto focus");
         ok(focus.select(multi.locks,50,30,48,valid)==null,"world-space cursor or enemy motion cannot unblock death");
         ok(multi.pick(valid).target===b,"default distribution skips dead enemy during focus block");
         focus.aimMoved();
         ok(focus.select(multi.locks,50,30,48,valid).target===b,"new actual input releases death block");
         b.sost=3;focus.aimMoved();b.sost=1;
         ok(focus.select(multi.locks,50,30,48,valid).target===b,"death before input between frames is observed before unblock");
         b.hp=0;focus.select(multi.locks,50,30,48,valid);focus.clear();b.hp=100;
         ok(focus.select(multi.locks,50,30,48,valid).target===b,"mode reset clears stale death gate");
         multi.stateFor(b).strength=0;
         ok(focus.select(multi.locks,50,30,48,valid)==null,"fully lost lock cannot focus");
         var so:SharedObject=SharedObject.getLocal("MSWConfig");so.clear();so.data.smartRadius=92;so.data.smartMultiLock=true;so.flush();
         cfg=new MSWConfig();cfg.load();
         ok(!cfg.smartFocus && cfg.smartFocusRadius==48 && cfg.smartRadius==92 && cfg.smartMultiLock,"old config migration preserves existing values and adds defaults");
         cfg.smartFocusRadius=NaN;cfg.clamp();ok(cfg.smartFocusRadius==48,"NaN focus radius falls back safely");
         cfg.smartFocusRadius=-5;cfg.clamp();ok(cfg.smartFocusRadius==0,"focus lower bound");
         cfg.smartFocusRadius=999;cfg.clamp();ok(cfg.smartFocusRadius==200,"focus upper bound");
         cfg.smartFocusRadius=73;cfg.clamp();ok(cfg.smartFocusRadius==72,"focus step normalization");
         cfg.smartFocus=true;cfg.save();var loaded:MSWConfig=new MSWConfig();loaded.load();
         ok(loaded.smartFocus && loaded.smartFocusRadius==72 && loaded.smartRadius==92,"focus save and reload independent of single-lock radius");
         var items:Array=MSWSettingsHub.buildSmartItems({cfg:cfg});
         for each(var item:Object in items)if(item.key=="smartFocus" || item.key=="smartFocusRadius")item["set"](item.def);
         ok(!cfg.smartFocus && cfg.smartFocusRadius==48 && cfg.smartRadius==92,"focus settings reset does not touch single-lock radius");
      }
   }
}
