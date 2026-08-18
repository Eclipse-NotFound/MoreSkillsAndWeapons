package
{
   /**
    * 魔法冲刺保持趴姿技能（设计见 state/design/design-冲刺保持趴姿.md，D-037）。
    *
    * 原版行为：趴着（lurked）时施放魔法冲刺（sp_kdash），UnitPlayer.actions()
    * 在冲刺期间每帧强制 `stay = false`（1065-1069 行）→ 次帧 lurked 清理
    * （`!stay → lurked=false`）→ animate() 脱离趴姿 → 冲刺结束时已站起。
    *
    * 本组件在游戏 step 之后（frame-late，与跳弹同模式）接管姿态：
    * - 检测 `kdash_t` 0→>0 且当时 lurked==true（稳定趴姿，work==""）→ 进入接管；
    * - 冲刺期间每帧强制 stay=true / lurked=true / lurkX=X / lurkBox=null，
    *   抵掉 actions() 的三个 lurked 清理路径（!stay / lurkBox / 位移）；
    *   并以 work="lurk" + t_work=20 让 animate() 播放完整趴姿动画（滑行）；
    * - kdash_t 归零后停止刷新 work/t_work —— 动画自然播完，身体冻结在趴姿帧
    *   （lurked=true 保持），玩家可保持趴姿继续移动（只能趴姿进入的通道内
    *   全程趴姿滑行/爬行）；
    * - 退出接管：游戏进入站起流程（work=="unlurk"，W/空格/蹲键由原版
    *   control() 触发 unlurk()）或玩家死亡（sost>=3）—— 交还原版。
    */
   public class MSWDashPose
   {
      private var mod:*;
      /** 接管中 */
      private var active:Boolean = false;
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
               curGg = null;
               prevKdash = 0;
               return;
            }
            if(active && curGg !== gg)
            {
               // 玩家实例变化（换存档/重开）：放弃接管
               active = false;
               curGg = null;
               prevKdash = 0;
               return;
            }
            var kdash:int = MSWU.num(gg, "kdash_t");
            var lurked:Boolean = gg["lurked"] == true;

            // ---- 退出接管 ----
            if(active)
            {
               var exit:Boolean = false;
               // 玩家解除（W/空格/蹲）已由原版 control() 处理成 work="unlurk"；
               // 直接探测 work 最可靠（control() 的 clearAll 会清掉按键状态，
               // 键位探测会漏）
               if(MSWU.str(gg, "work") == "unlurk") exit = true;
               // 死亡/濒死：sost==2 计时死亡中，>=3 已死
               if(MSWU.num(gg, "sost") >= 2) exit = true;
               if(exit)
               {
                  active = false;
                  prevKdash = kdash;
                  mod.cfg.diagAdd("dashPoseExit");
                  return;
               }
            }

            // ---- 进入接管：趴着（稳定趴姿）时魔法冲刺开始 ----
            if(!active && kdash > 0 && prevKdash == 0 && lurked &&
               MSWU.str(gg, "work") == "")
            {
               active = true;
               curGg = gg;
               mod.cfg.diagAdd("dashPoseCast");
            }

            if(active)
            {
               // 姿态接管（每帧强制，抵掉 actions() 的 stay=false 与清理路径）
               gg["stay"] = true;
               gg["lurked"] = true;
               // lurkX 跟随当前位置：防 `work!="lurk" && |X-lurkX|>10` 清理
               // （冲刺/爬行位移远大于 10px）
               gg["lurkX"] = MSWU.num(gg, "X");
               // 冲出趴伏物（床/桌下）后防 lurkBox 清理；解除后重趴时会重新
               // 扫描（lurk() 重新找 box），置空安全
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
