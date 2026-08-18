package
{
   /**
    * 魔法冲刺保持姿态技能（设计见 state/design/design-冲刺保持趴姿.md，D-037/D-038/D-039）。
    *
    * 原版行为：蹲下（isSit）或趴着（lurked）时施放魔法冲刺（sp_kdash），
    * UnitPlayer.actions() 在冲刺期间每帧强制 `stay = false`（1065-1069 行）：
    * - 蹲姿：control() `isSit && !stay → unsit()`（2889）→ 蹲姿解除；
    * - 趴姿：actions() lurked 清理 `!stay → lurked=false`（1045-1048）→ 站起。
    *
    * 版本历史：
    * - D-037/D-038：读取 `gg["lurked"]`（internal）→ 密封类 internal 成员从
    *   模组侧 bracket 访问抛 #1069 → update() 每帧死在外层 catch → 组件从未
    *   生效（玩家实测两轮"无效果"；Sandevistan 源码 5921 行同样证实
    *   "keyDowns 是 internal 无法访问"）。
    * - D-039（本版）：**全部改用 public 字段**（isSit/stay/scX/scY/sitX/sitY/
    *   work/t_work/animState/sost/rat/X/sloy/kdash_t + ctr 键位）——
    *   · 蹲姿分支（用户实测场景：按 S）：isSit+stay+scX/scY 每帧强制；
    *     冲刺中保持姿态；退出 = kdash==0 后游戏解除了 isSit
    *     （W/SPACE/水/梯子原版路径已执行）；姿态保持期可正常移动/操作。
    *   · 趴姿分支（尽力而为，lurked/lurkX/lurkBox 均 internal 不可写）：
    *     sloy∈{0,1}（public）代理 lurked 检测；冲刺中 work="lurk"+
    *     t_work=20+stay 强制（播趴姿动画；抵 !stay 与 |X-lurkX| 清理）；
    *     冲刺结束置 t_work=1 → 快速衰减 work="" → 位移>10px 的冲刺
    *     结束后趴姿无法保持（lurkX internal 不可跟随，原版站起回归）；
    *     box 趴伏（lurkBox!=null）冲刺中可能被 box 清理——已知限制。
    */
   public class MSWDashPose
   {
      private var mod:*;
      /** 接管中 */
      private var active:Boolean = false;
      /** 姿态分支：1=蹲姿(isSit)，2=趴姿(lurked 代理=sloy 0/1) */
      private var poseMode:int = 0;
      /** 上一帧 kdash_t（检测 0→>0 跳变） */
      private var prevKdash:int = 0;
      /** 接管时的玩家实例（防换人/换存档后残留接管） */
      private var curGg:* = null;
      /** internal 访问探针（一次性，留档验证） */
      private var probed:Boolean = false;
      /**
       * 钉扎坐姿身体帧（D-042：硬编码 getStayFrame 对 isSit 的默认值 2——
       * 开阔地坐姿；贴墙坐姿为 49+，冲刺时已离墙，用开阔地坐姿正确）。
       * 历史：D-041 曾"施放帧快照 body.currentFrame"——但施放帧游戏已把身体
       * 播进 polz/down/up 过渡段（3-26 帧），快照抓到站起过渡帧 → 钉扎冻在
       * 半站起姿态 = 玩家实测的"站起动画抽搐"。
       */
      private var sitFrame:int = 2;
      /** 落地检测（Y 稳定帧数） */
      private var prevY:Number = 0;
      private var stableFrames:int = 0;

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
            // 一次性探针：internal 成员 lurked 是否可访问（D-039 留档）
            if(!probed)
            {
               probed = true;
               try
               {
                  var pv:* = gg["lurked"];
                  if(pv === undefined) mod.cfg.diagAdd("lurkProbeUndef");
                  else mod.cfg.diagAdd("lurkProbeOK");
               }
               catch(e:*) { mod.cfg.diagAdd("lurkProbeErr"); }
            }
            var kdash:int = MSWU.num(gg, "kdash_t");
            // 诊断：kdash 是否真的触发（区分"技能不是 sp_kdash"与"接管逻辑问题"）
            if(kdash > 0) mod.cfg.diagAdd("kdashSeen");
            if(!MSWU.inGameplay(w)) return; // 回放期不介入（D-033 语义）
            var isSitNow:Boolean = gg["isSit"] == true;      // public
            var sloyNow:int = MSWU.num(gg, "sloy");          // public
            var workStr:String = MSWU.str(gg, "work");       // public
            var lurkedProxy:Boolean = (sloyNow == 0 || sloyNow == 1);

            // ---- 退出接管 ----
            if(active)
            {
               var exit:Boolean = false;
               // 死亡/濒死：sost==2 计时死亡中，>=3 已死
               if(MSWU.num(gg, "sost") >= 2) exit = true;
               // rat 变形（ratOn 会 unlurk + isSit=false）
               if(MSWU.num(gg, "rat") != 0) exit = true;
               // 冲刺结束后：游戏解除了姿态 = 原版解除路径已执行——交还原版。
               // 冲刺中（kdash>0）不退出（"全程保持"语义）。
               if(!exit && kdash == 0)
               {
                  if(poseMode == 1 && !isSitNow) exit = true;
                  if(poseMode == 2)
                  {
                     // work=="unlurk"：原版 unlurk() 已执行（W/空格/蹲）；
                     // 或 sloy 已回 2（lurked 已死——|X-lurkX| 位移清理 /
                     // lurkBox 清理已生效；sloy 0/1 仅 lurked 时存在）
                     if(workStr == "unlurk") exit = true;
                     if(sloyNow == 2) exit = true;
                  }
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
            if(!active && kdash > 0 && prevKdash == 0)
            {
               if(workStr != "")
               {
                  mod.cfg.diagAdd("dashEntryBlockWork");
               }
               else if(isSitNow)
               {
                  active = true;
                  poseMode = 1;
                  curGg = gg;
                  stableFrames = 0;
                  prevY = MSWU.num(gg, "Y");
                  mod.cfg.diagAdd("dashEntrySit");
                  mod.cfg.diagAdd("dashPoseCast");
               }
               else if(lurkedProxy)
               {
                  active = true;
                  poseMode = 2;
                  curGg = gg;
                  mod.cfg.diagAdd("dashEntryLurk");
                  mod.cfg.diagAdd("dashPoseCast");
               }
               else
               {
                  mod.cfg.diagAdd("dashEntryBlockPose");
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
                  if(MSWU.num(gg, "scY") != MSWU.num(gg, "sitY"))
                  {
                     gg["scX"] = MSWU.num(gg, "sitX");
                     gg["scY"] = MSWU.num(gg, "sitY");
                  }
                  // 落地检测（Y 稳定 3 帧=已落地；冲刺中/落地前 Y 持续变化）
                  var yNow:Number = MSWU.num(gg, "Y");
                  if(Math.abs(yNow - prevY) < 0.3) stableFrames++;
                  else stableFrames = 0;
                  prevY = yNow;
                  // 视觉钉扎（D-040/D-041）：冲刺中游戏 animate() 走空中分支
                  // （"jump"/"pinok" 根帧，无 isSit 处理 → 渲染站姿）；钉回
                  // 坐姿（根帧 "stay" + 身体冻结在冲刺前坐姿帧——零动画零抽搐；
                  // D-040 的 polz+body.play() 会让身体播进 down/up 过渡帧段
                  // = "站起动画抽搐"）。钉扎窗口 = 冲刺全程 + 落地前（修
                  // "最后一刻才恢复"）。Flash 在所有 ENTER_FRAME 监听器之后
                  // 渲染——当帧生效。
                  if(kdash > 0 || !(stableFrames >= 3))
                  {
                     pinPose(gg, sitFrame);
                  }
               }
               else
               {
                  // 趴姿（public 尽力而为）：lurked/lurkX/lurkBox internal
                  // 不可写——stay=true 抵 !stay 清理；work="lurk" 抵
                  // |X-lurkX| 位移清理并让 animate() 播趴姿动画
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
                  else if(MSWU.num(gg, "t_work") > 1)
                  {
                     // 冲刺结束：快速收尾（t_work=1 → 下一帧 actions() 归零
                     // work="" → 位移清理决定趴姿去留——位移>10px 站起回归
                     // 原版；位移小则趴姿保持）
                     gg["t_work"] = 1;
                  }
               }
               mod.cfg.diagAdd("dashPoseF");
            }
            prevKdash = kdash;
         }
         catch(e:*)
         {
         }
      }

      /** 钉扎坐姿（根帧 "stay" + 身体冻结在坐姿帧 2——零动画零抽搐）。 */
      private function pinPose(gg:*, frame:int):void
      {
         try
         {
            var vis:* = gg["vis"];
            if(vis == null) return;
            var osn:* = vis["osn"];
            if(osn == null) return;
            osn["gotoAndStop"]("stay");
            var body:* = osn["body"];
            if(body != null) body["gotoAndStop"](frame);
            mod.cfg.diagAdd("dashPosePin");
         }
         catch(e:*)
         {
            mod.cfg.diagAdd("dashPosePinErr");
         }
      }
   }
}
