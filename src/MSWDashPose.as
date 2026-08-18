package
{
   /**
    * 魔法冲刺保持姿态技能（设计见 state/design/design-冲刺保持趴姿.md，D-037/D-038）。
    *
    * 原版行为：蹲下（isSit）或趴着（lurked）时施放魔法冲刺（sp_kdash），
    * UnitPlayer.actions() 在冲刺期间每帧强制 `stay = false`（1065-1069 行）：
    * - 蹲姿：control() `isSit && !stay → unsit()`（2889）→ 蹲姿解除；
    * - 趴姿：actions() lurked 清理 `!stay → lurked=false`（1045-1048）→ 站起。
    * （玩家实测：按 S 进入的是蹲姿 isSit——原版蹲姿是粘性的，松 S 不解除，
    * 起身只走 W（2884）/SPACE（2706）/水/梯子/rat 路径——D-038）
    *
    * 本组件在游戏 step 之后（frame-late，与跳弹同模式）接管姿态：
    * - 检测 `kdash_t` 0→>0 且当时 isSit==true 或 lurked==true（work==""）→ 进入接管；
    * - 冲刺期间（kdash>0）每帧强制，抵掉原版解除路径，保持原姿态：
    *   · 蹲姿：isSit=true + stay=true + 碰撞盒 scX/scY=sitX/sitY（防 W/!stay 解除），
    *     animate() 的 stay 分支 + walk 分支 isSit 处理渲染蹲姿/polz 爬行滑行；
    *   · 趴姿：lurked=true + stay=true + lurkX=X + lurkBox=null，
    *     并以 work="lurk"+t_work=20 让 animate() 播放完整趴姿动画（滑行）；
    * - 冲刺结束（kdash==0）：停止刷新 work/t_work（趴姿动画自然落定冻结），
    *   继续保姿态——玩家可保持蹲/趴继续移动（只能蹲/趴进入的通道全程保持）；
    * - 退出接管：kdash==0 后游戏解除了姿态（isSit/lurked 变 false = W/SPACE/
    *   水/梯子/rat 等原版解除路径已执行）或玩家死亡（sost>=2）——交还原版。
    *   冲刺中（kdash>0）即使玩家按 W/SPACE 也保持姿态（"全程保持"语义）。
    */
   public class MSWDashPose
   {
      private var mod:*;
      /** 接管中 */
      private var active:Boolean = false;
      /** 姿态分支：1=蹲姿(isSit)，2=趴姿(lurked) */
      private var poseMode:int = 0;
      /** 上一帧 kdash_t（检测 0→>0 跳变） */
      private var prevKdash:int = 0;
      /** 接管时的玩家实例（防换人/换存档后残留接管） */
      private var curGg:* = null;

      public function MSWDashPose(m:*)
      {
         mod = m;
      }

      /** 每帧调用（游戏 step 之后）。 */
      public function update(w:*):void
      {
         try
         {
            if(w == null) return;
            if(!MSWU.inGameplay(w)) return; // 回放期不介入（D-033 语义）
            var gg:* = w["gg"];
            if(gg == null)
            {
               active = false;
               poseMode = 0;
               curGg = null;
               prevKdash = 0;
               return;
            }
            if(active && curGg !== gg)
            {
               // 玩家实例变化（换存档/重开）：放弃接管
               active = false;
               poseMode = 0;
               curGg = null;
               prevKdash = 0;
               return;
            }
            var kdash:int = MSWU.num(gg, "kdash_t");
            var isSitNow:Boolean = gg["isSit"] == true;
            var lurkedNow:Boolean = gg["lurked"] == true;

            // ---- 退出接管 ----
            if(active)
            {
               var exit:Boolean = false;
               // 死亡/濒死：sost==2 计时死亡中，>=3 已死
               if(MSWU.num(gg, "sost") >= 2) exit = true;
               // rat 变形（ratOn 会 unlurk + isSit=false）
               if(MSWU.num(gg, "rat") != 0) exit = true;
               // 冲刺结束后：游戏解除了姿态 = 原版解除路径（W/SPACE/水/梯子）
               // 已执行——交还原版。冲刺中（kdash>0）不退出（"全程保持"）。
               if(!exit && kdash == 0)
               {
                  if(poseMode == 1 && !isSitNow) exit = true;
                  if(poseMode == 2 && !lurkedNow) exit = true;
               }
               if(exit)
               {
                  active = false;
                  poseMode = 0;
                  prevKdash = kdash;
                  mod.cfg.diagAdd("dashPoseExit");
                  return;
               }
            }

            // ---- 进入接管：蹲/趴着（稳定姿态，work==""）时魔法冲刺开始 ----
            if(!active && kdash > 0 && prevKdash == 0 &&
               MSWU.str(gg, "work") == "")
            {
               if(lurkedNow)
               {
                  active = true;
                  poseMode = 2;
                  curGg = gg;
                  mod.cfg.diagAdd("dashPoseCast");
               }
               else if(isSitNow)
               {
                  active = true;
                  poseMode = 1;
                  curGg = gg;
                  mod.cfg.diagAdd("dashPoseCast");
               }
            }

            if(active)
            {
               // 姿态接管（每帧强制，抵掉 actions() 的 stay=false 与解除路径）
               gg["stay"] = true;
               if(poseMode == 1)
               {
                  // 蹲姿：防 control() 2884/2889 的 unsit；碰撞盒保持坐姿尺寸
                  // （sit(true) 幂等早退无法修盒，直接对齐 sitX/sitY——
                  // 若游戏已 unsit 过一次，scX/scY 会被还原成 stayX/stayY）
                  gg["isSit"] = true;
                  var scY:Number = MSWU.num(gg, "scY");
                  if(scY != MSWU.num(gg, "sitY"))
                  {
                     gg["scX"] = MSWU.num(gg, "sitX");
                     gg["scY"] = MSWU.num(gg, "sitY");
                  }
               }
               else
               {
                  // 趴姿：防 actions() 三个 lurked 清理路径
                  // （!stay / lurkBox / |X-lurkX|>10 位移）
                  gg["lurked"] = true;
                  gg["lurkX"] = MSWU.num(gg, "X");
                  gg["lurkBox"] = null;
                  if(kdash > 0)
                  {
                     // 冲刺中：维持趴姿动画（animate() 的 lurk 分支需要
                     // t_work>0 && work=="lurk"；animState 置空迫使它从帧 1
                     // 重新 gotoAndStop("lurk"+lurkTip) + body.gotoAndPlay(1)）
                     gg["work"] = "lurk";
                     gg["t_work"] = 20;
                     if(MSWU.str(gg, "animState") != "lurk")
                     {
                        gg["animState"] = "";
                     }
                  }
                  // 冲刺结束：不刷新 work/t_work —— 游戏 actions() 自然衰减
                  // t_work 20→0 → work="" → animate() 落到 lurked 分支（身体
                  // 冻结在趴姿帧），玩家保持趴姿可继续移动（lurkX 每帧跟随）
               }
               mod.cfg.diagAdd("dashPoseF");
            }
            prevKdash = kdash;
         }
         catch(e:*)
         {
         }
      }
   }
}
