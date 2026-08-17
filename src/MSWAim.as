package
{
   /**
    * 蹲姿/梯子举枪技能（设计见 design/skill-aim-sit-ladder.md）。
    *
    * 按键：举枪 = Shift+W（heldShift && heldW）；单独的 W 不拦截，
    * 保持原版语义（坐姿 W = 起身、梯子 W = 爬升）。
    *
    * 机制：
    * - 坐下（isSit，public）+ Shift+W：
    *   · KEY_DOWN 层吞 W（入口完成）——阻止"先坐下后 Shift+W"的 unsit；
    *   · "按住 W 再坐下"的流程没有新 W 事件可吞——瞄准期间每帧强制
    *     `ctr.keySit = true`（堵住 unsit 的 `!keySit` 条件，且坐姿 sit(true)
    *     幂等无副作用），并用 noStairs=true 防强制 keySit 引发的误爬梯；
    *   · S 的 KEY_UP 在瞄准中被吞（入口完成），防止松开 S 的一帧窗口触发 unsit；
    *   · 起身 = 松开 Shift 后按 W（原版 unsit）或 SPACE（原生 jumpp→unsit）。
    *   · 每帧把 currentWeapon.vis.y 抬高 40px（复刻 setWeaponPos 的
    *     weaponY-=40 与上方瓦片判定）——枪口 getBulXY 读 vis.emit，
    *     贴图抬高 = 枪口抬高 = 子弹出生点上移，可越障射击。
    * - 梯子（isLaz!=0，public）+ Shift+W：KEY_DOWN 即置 noStairs=true
    *   （消除第一帧爬升）；帧内维持 + 抬贴图；单独的 W 正常爬升
    *   （noStairs 不置）、S 爬降、松开 W 后 SPACE 脱离（均原版）。
    * - 抬枪为 10 帧渐入（与原版站立举枪阈值一致），松开立即恢复（原版同）。
    */
   public class MSWAim
   {
      private var mod:*;
      private var tAim:int = 0;
      private var forcingKeySit:Boolean = false;
      private var prevSit:Boolean = false;

      /** 由入口维护的物理键状态 */
      public var heldW:Boolean = false;
      public var heldShift:Boolean = false;

      private static const RAISE:int = 40;   // setWeaponPos 的抬枪高度
      private static const FRAMES:int = 10;  // 原版 t_up 阈值

      public function MSWAim(m:*)
      {
         mod = m;
      }

      /** 瞄准中强制 keySit/keyBeUp（供入口在 S 的 KEY_UP 时调用）。 */
      public function forceKeySit(w:*):void
      {
         try
         {
            if(w == null || w["ctr"] == null) return;
            w["ctr"]["keySit"] = true;
            w["ctr"]["keyBeUp"] = false;
         }
         catch(e:*)
         {
         }
      }

      /** 每帧调用（游戏 step 之后）。 */
      public function update(w:*):void
      {
         try
         {
            if(w == null) return;
            var gg:* = w["gg"];
            if(gg == null) return;
            var isSitNow:Boolean = gg["isSit"] == true;
            // 举枪 = Shift+W；单独的 W 不拦截（原版起身/爬升）
            var on:Boolean = mod.cfg.aimSkill && gg["ggControl"] == true &&
               MSWU.num(gg, "rat") == 0 && heldW && heldShift;
            // 观测（在我强制之前）：游戏 step 后 keyBeUp 是否仍为 true——
            // 实测 keyBeUpLeak=7：Ctr 确实置位了 keyBeUp（吞键失效），
            // 当帧 control 的 2884 已触发 unsit（2026-08-17 实测证据）
            if(on && w["ctr"] != null && w["ctr"]["keyBeUp"] == true)
            {
               mod.cfg.diagAdd("keyBeUpLeak");
            }
            if(!on)
            {
               release(w, gg);
               prevSit = isSitNow;
               return;
            }
            // 站起恢复兜底：上一帧坐姿、本帧被游戏任何路径取消（吞键失效时
            // control 的 2884：isSit && keyBeUp && !keySit）→ 立即坐回。
            // 排除 SPACE 主动起身（keyJump=true / jumpp>0 时放行）。
            // 注：prevSit 由所有分支统一维护（!on 分支也更新），
            // 否则按 W 那一帧 prevSit 恒为 false、恢复永不触发（上版 bug）。
            if(prevSit && !isSitNow)
            {
               var spJump:Boolean = (w["ctr"] != null && w["ctr"]["keyJump"] == true) ||
                  MSWU.num(gg, "jumpp") > 0;
               if(!spJump)
               {
                  try
                  {
                     gg["sit"](true);
                     mod.cfg.diagAdd("sitRestored");
                     isSitNow = true;
                  }
                  catch(e6:*)
                  {
                  }
               }
            }
            prevSit = isSitNow;
            var sitAim:Boolean = isSitNow;
            // 梯子举枪同样要求 Shift+W（单独 W = 原版爬升）
            var lazAim:Boolean = !sitAim && MSWU.num(gg, "isLaz") != 0 && heldShift;
            if(!sitAim && !lazAim)
            {
               // W 被吞后起身（SPACE）等情况：要求重新按 W
               release(w, gg);
               heldW = false;
               return;
            }
            // 状态维持
            gg["noStairs"] = true;
            if(sitAim)
            {
               forceKeySit(w);
               forcingKeySit = true;
               // 双保险：坐姿瞄准中，控制帧看到的 keyBeUp 恒 false（堵
               // unsit 路径1: isSit && keyBeUp && !keySit），
               // stay 恒 true（堵 unsit 路径2: isSit && !stay——
               // 任何向下运动一帧（dy>0 碰撞结算）都会置 stay=false）。
               gg["stay"] = true;
            }
            else if(forcingKeySit)
            {
               forcingKeySit = false;
            }
            if(tAim < FRAMES)
            {
               tAim++;
            }
            // 抬枪：贴图 + 枪口（渐入）
            var wp:* = gg["currentWeapon"];
            if(wp != null && MSWU.num(wp, "tip") != 5)
            {
               var vis:* = wp["vis"];
               if(vis != null)
               {
                  var wX:Number = MSWU.num(gg, "weaponX", MSWU.num(wp, "X"));
                  var wY:Number = MSWU.num(gg, "weaponY", MSWU.num(wp, "Y"));
                  var loc:* = w["loc"];
                  var t:* = (loc != null) ? loc["getAbsTile"](wX, wY - RAISE) : null;
                  if(t == null || MSWU.num(t, "phis") != 1)
                  {
                     var off:Number = RAISE * tAim / FRAMES;
                     try
                     {
                        vis["y"] = MSWU.num(vis, "y") - off;
                     }
                     catch(e:*)
                     {
                     }
                  }
               }
            }
         }
         catch(e:*)
         {
         }
      }

      private function release(w:*, gg:*):void
      {
         tAim = 0;
         try
         {
            gg["noStairs"] = false;
         }
         catch(e:*)
         {
         }
         if(forcingKeySit)
         {
            forcingKeySit = false;
            try
            {
               if(w != null && w["ctr"] != null)
               {
                  w["ctr"]["keySit"] = false;
               }
            }
            catch(e:*)
            {
            }
         }
      }
   }
}
