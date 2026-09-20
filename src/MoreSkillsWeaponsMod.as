package
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;

   /**
    * 模组文档类（SWF 主类）。
    * 由补丁后 MainFE 的 loader 加载并调用 init(main)。
    *
    * 事件时序（shared-knowledge input-system）：
    * - 本类 ENTER_FRAME 注册晚于游戏 MainMenu → 每帧在游戏 step 之后执行；
    * - 本类 KEY_DOWN 注册早于游戏 Ctr → 面板按键可抢在游戏前处理。
    */
   public class MoreSkillsWeaponsMod extends Sprite
   {
      /**
       * 注意：补丁 loader 的调用方式是
       * `applicationDomain.getDefinition("MoreSkillsWeaponsMod").init(main)`
       * —— 对**类**调用 init（静态方法），main = MainFE 实例。
       * 因此必须提供 public static init，内部委托给单例实例。
       */
      private static var inst:MoreSkillsWeaponsMod = null;

      /** Isolated AIR harness only; never exposes the production instance. */
      public static function testInstance():*
      {
         var na:Class=MSWU.cls("flash.desktop.NativeApplication");
         return na!=null && na["nativeApplication"]["applicationID"]!="pfe" ? inst : null;
      }

      public static function init(main:*):void
      {
         try
         {
            if(inst == null) inst = new MoreSkillsWeaponsMod();
            inst.instanceInit(main);
         }
         catch(e:*)
         {
         }
      }

      public var cfg:MSWConfig;
      public var weapon:MSWWeapon;
      public var bullets:MSWBullets;
      public var smart:MSWSmartWeapons;
      public var trajectory:MSWTrajectory;
      public var panel:MSWPanel;
      public var aim:MSWAim;
      /** 2026-08-17 自 Sandevistan 迁移：手雷击落 / 疾跑切枪 */
      public var projhits:MSWProjHits;
      public var swaprun:MSWSwaprun;
      /** 2026-08-18 D-037/D-038：魔法冲刺保持蹲/趴姿 */
      public var dashpose:MSWDashPose;
      /** 2026-08-29 测试实例自动驱动（仅 appid≠pfe 激活，用户实例零影响） */
      public var autotest:MSWAutoTest;
      /** 模组设置聚合页登记簿（design/mod-settings-hub.md），2026-08-29 一期 */
      public var settings:MSWSettingsHub;

      private var stage_:* = null;
      private var booted:Boolean = false;
      private var pendingMain:* = null;
      private var retryHooked:Boolean = false;

      public function MoreSkillsWeaponsMod()
      {
         super();
         cfg = new MSWConfig();
         weapon = new MSWWeapon(this);
         bullets = new MSWBullets(this);
         trajectory = new MSWTrajectory(this);
         panel = new MSWPanel(this);
         smart = new MSWSmartWeapons(this);
         aim = new MSWAim(this);
         projhits = new MSWProjHits(this);
         swaprun = new MSWSwaprun(this);
         dashpose = new MSWDashPose(this);
         settings = new MSWSettingsHub();
         autotest = new MSWAutoTest(this);
      }

      /** Legacy same-domain facade: queue/forward registrations to independent ModSettings. */
      public static function settingsRegister(modId:String, displayName:String, items:Array,
                                              onPageClose:Function = null, desc:String = ""):Boolean
      {
         try
         {
            if(inst != null)
            {
               inst.settings.registerPage(modId, displayName, items, onPageClose, desc);
               inst.cfg.diagSet("hubReg", modId);
               return true;
            }
         }
         catch(e:*)
         {
         }
         return false;
      }

      /** 由游戏 loader 调用；main 为 MainFE 实例。 */
      public function instanceInit(main:*):void
      {
         pendingMain = main;
         tryBoot();
      }

      private function tryBoot():void
      {
         if(booted) return;
         var st:* = null;
         try
         {
            if(pendingMain != null && pendingMain["stage"] != null) st = pendingMain["stage"];
            if(st == null && this.stage != null) st = this.stage;
         }
         catch(e:*)
         {
         }
         if(st == null)
         {
            // stage 尚不可用：挂在 main 的 ENTER_FRAME 上重试
            try
            {
               if(pendingMain != null && !retryHooked)
               {
                  pendingMain.addEventListener(Event.ENTER_FRAME, onRetry);
                  retryHooked = true;
               }
            }
            catch(e:*)
            {
            }
            return;
         }
         stage_ = st;
         booted = true;
         try
         {
            if(pendingMain != null) pendingMain.removeEventListener(Event.ENTER_FRAME, onRetry);
         }
         catch(e:*)
         {
         }
         cfg.load();
         cfg.diagSet("ver", "1.5.2-smart-smooth");
         settings.registerPage("msw", "MoreSkills&Weapons",
            MSWSettingsHub.buildMswItems(this), mswPageClose, "武器与技能扩展");
         settings.registerPage("msw-smart", "智能武器", MSWSettingsHub.buildSmartItems(this), mswPageClose,
            "实弹枪与霰弹枪：准星停留锁定，弯曲追踪与局部绕障；时长可调。");
         weapon.injectXml();
         stage_.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
         stage_.addEventListener(Event.ENTER_FRAME, onSmartBeforeFrame, false, 1000, true);
         stage_.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
         stage_.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
         cfg.diagSet("booted", 1);
         cfg.diagFlush();
      }

      private function onRetry(e:Event):void
      {
         tryBoot();
      }

      /** MSW 页收起：滑块延迟保存统一落盘。 */
      private function mswPageClose():void
      {
         cfg.clamp();
         cfg.save();
      }

      private var frameN:int = 0;

      private function onSmartBeforeFrame(e:Event):void
      {
         try { smart.prepare(MSWU.world()); }
         catch(err:*) { cfg.diagSet("smartError","prepare:"+err); }
      }

      private function onFrame(e:Event):void
      {
         try
         {
            var w:* = MSWU.world();
            if(w == null) return;
            frameN++;
            cfg.diagAdd("frames");
            autotest.update(w); // 测试实例自动驱动（用户实例空转）
            settings.connect(w);
            cfg.diagSet("modAPI", settings.api != null ? "ModSettings-connected" : "waiting-ModSettings");
            if(frameN % 300 == 0) cfg.diagFlush();
            if(!worldSeen)
            {
               worldSeen = true;
               cfg.diagSet("world", 1);
               cfg.diagFlush();
            }
            if(panel.pipPageActive(w) && !pipSeen)
            {
               pipSeen = true;
               cfg.diagSet("pip", 1);
               cfg.diagFlush();
            }
            weapon.apply(w);      // 每帧应用配置（grav/explRadius/noTrass/nazv）
            weapon.provision(w);  // 发放武器+初始弹药（幂等）
            bullets.process(w);   // 子弹跟踪：跳弹/弹跳/引爆
            smart.frame(w);       // 锁定时钟与HUD；实际制导由场景步进钩子驱动
            projhits.process(w);  // 2026-08-17 迁移：手雷击落（投掷物可击落）
            trajectory.update(w); // SATS 弹道覆盖层
            aim.update(w);        // 蹲姿/梯子举枪
            dashpose.update(w);   // 2026-08-18 D-037/D-038：魔法冲刺保持蹲/趴姿
            panel.update(w);      // 设置面板（哔哔小马"模组"子页 + F6 浮层）
         }
         catch(err:*)
         {
            cfg.diagSet("lastErr", "frame:" + err);
            if(frameN % 60 == 0) cfg.diagFlush();
         }
      }

      private var worldSeen:Boolean = false;
      private var pipSeen:Boolean = false;
      private var keyN:int = 0;

      /**
       * 浮层热键：仅 F6。
       * 历史：F6/F7/F8/F10 + 179 多键方案中，F10 与其他模组热键冲突
       * （用户反馈），F8 在该键盘上不产生键事件；诊断（hk117=9）证明 F6 稳定
       * 到达。其他 F 键只做诊断记录（hk<code>），不触发、不拦截。
       */
      private function isHotKey(code:int):Boolean
      {
         return code == 117;
      }

      private function onKeyUp(e:KeyboardEvent):void
      {
         try
         {
            if(e.keyCode == 87) aim.heldW = false;
            if(e.keyCode == 16) aim.heldShift = false;
            // 蹲姿举枪中吞掉 S 的 KEY_UP：防止松开 S 的一帧窗口
            // （Ctr 清 keySit → 下一控制帧 !keySit 成立 → 原版 unsit）
            // 仅 Shift+W 瞄准中生效；单独按 W 不拦截（原版起身/爬升）
            if(e.keyCode == 83 && cfg.aimSkill && aim.heldW && aim.heldShift)
            {
               var ww:* = MSWU.world();
               if(ww != null)
               {
                  var g0:* = ww["gg"];
                  if(g0 != null && g0["isSit"] == true && g0["ggControl"] == true && MSWU.num(g0, "rat") == 0)
                  {
                     aim.forceKeySit(ww);
                     e.stopImmediatePropagation();
                     e.preventDefault();
                  }
               }
            }
         }
         catch(err:*)
         {
         }
      }

      private function onKeyDown(e:KeyboardEvent):void
      {
         try
         {
            if(e.keyCode == 229) return; // IME 事件，不吞
            // W/Shift 物理键跟踪（蹲姿/梯子举枪技能）
            if(e.keyCode == 87)
            {
               aim.heldW = true;
               // 同步 heldShift：Shift 与 W 几乎同时按下时，W 的 KEY_DOWN
               // 可能先于 Shift 到达（事件顺序无保证）。若不同步，按 W 那一帧
               // update 里 on=false → 恢复兜底的 prevSit 被 !on 分支清成 false
               // → 吞键失效时游戏 unsit 站起后无法坐回 → 举枪完全失效。
               if(e.shiftKey) aim.heldShift = true;
               cfg.diagAdd("wDown");
            }
            if(e.keyCode == 16) aim.heldShift = true;
            // 举枪 = Shift+W：仅 Shift 按下时吞 W / 置 noStairs；
            // 单独按 W 保持原版（坐姿起身、梯子爬升）。
            // 用 e.shiftKey（事件时物理状态）判定，不依赖 heldShift 的
            // 事件到达顺序（Shift/W 同时按下时 W 事件可能先到）。
            if(e.keyCode == 87 && cfg.aimSkill && e.shiftKey)
            {
               var ww:* = MSWU.world();
               if(ww != null)
               {
                  var g0:* = ww["gg"];
                  if(g0 != null)
                  {
                     if(g0["isSit"] == true)
                     {
                        cfg.diagAdd("wSitDown");
                     }
                     if(MSWU.num(g0, "isLaz") != 0)
                     {
                        cfg.diagAdd("wLazDown");
                        // 梯子 + Shift+W：KEY_DOWN 即置 noStairs，消除第一帧
                        // 爬升（帧内置位晚于该次游戏 step，会爬 ~5px）。
                        // 单独的 W 不置 → 原版爬升。
                        if(g0["ggControl"] == true && MSWU.num(g0, "rat") == 0)
                        {
                           g0["noStairs"] = true;
                        }
                     }
                     if(g0["isSit"] == true && g0["ggControl"] == true && MSWU.num(g0, "rat") == 0)
                     {
                        // 蹲姿举枪：吞掉 W，阻止原版 unsit（起身由 SPACE 原生完成）
                        cfg.diagAdd("wSwallow");
                        // 注：不在按键路径 flush——SharedObject.flush() 是同步
                        // 磁盘 I/O，每次按键 flush 会造成可感知卡顿（2026-08-18
                        // 玩家实测"第一次举枪卡顿"）；诊断由帧级 flush 落盘。
                        // 吞键失效兜底（D-030 实测：stopImmediatePropagation 在该
                        // 运行时不能阻止 Ctr 置位 keyBeUp）：直接改写 Ctr 状态。
                        // Ctr 的 keyDowns[87] 置 true 后，按住 W 期间的后续重复
                        // KEY_DOWN 会被 Ctr 的 keyDowns 守卫跳过 → keyBeUp 不再
                        // 被置位 → 游戏 step 的 2884（isSit && keyBeUp && !keySit）
                        // 永不触发 → 坐姿保持（帧内三保险仍然保留作双保险）。
                        try
                        {
                           var ctr0:* = ww["ctr"];
                           if(ctr0 != null)
                           {
                              ctr0["keyBeUp"] = false;
                              if(ctr0["keyDowns"] != null && ctr0["keyDowns"][87] == false)
                              {
                                 ctr0["keyDowns"][87] = true;
                              }
                           }
                        }
                        catch(e7:*)
                        {
                        }
                        e.stopImmediatePropagation();
                        e.preventDefault();
                        return;
                     }
                  }
               }
            }
            keyN++;
            cfg.diagAdd("keys");
            // 注：不再在按键路径 flush（同步磁盘 I/O 卡顿，2026-08-18 实测）；
            // 诊断由帧级 flush（onFrame frameN%300）落盘。
            if((e.keyCode >= 117 && e.keyCode <= 123) || e.keyCode == 179)
            {
               cfg.diagAdd("hk" + e.keyCode);
            }
            var w:* = MSWU.world();
            if(w != null)
            {
               var pip0:* = w["pip"];
               if(pip0 != null && pip0["active"] == true)
               {
                  // 哔哔小马开着：模组面板纯鼠标交互（原版控件），仅 F6 =
                  // 开/关"模组"面板（在任意子页会先跳到 Opt 页再展开）。
                  // 2026-08-28 v2：取代 v1 的文字面板按键消费。
                  if(isHotKey(e.keyCode))
                  {
                     panel.tabToggle(w);
                     e.stopImmediatePropagation();
                     e.preventDefault();
                  }
                  return;
               }
            }
            if(panel.overlayOpen)
            {
               if(e.keyCode == 27 || isHotKey(e.keyCode))
               {
                  panel.toggleOverlay();
                  e.stopImmediatePropagation();
                  e.preventDefault();
                  return;
               }
               if(panel.handleKey(e.keyCode))
               {
                  e.stopImmediatePropagation();
                  e.preventDefault();
                  return;
               }
               // 浮层打开：吞掉游戏操作键，防止角色移动/开火
               e.stopImmediatePropagation();
               e.preventDefault();
               return;
            }
            // 2026-08-17 迁移：疾跑中切枪（swaprun）——事件层拦截。
            // 放在面板/浮层处理之后：面板打开时已提前 return，不会误触发；
            // 斯安维斯坦回放期（onPause+godMode）由 MSWU.inGameplay 屏蔽，
            // 时停期放行（D-033：对齐原版行为）。
            if(swaprun.intercept(e, MSWU.world()))
            {
               return;
            }
            if(isHotKey(e.keyCode))
            {
               panel.toggleOverlay();
               e.stopImmediatePropagation();
               e.preventDefault();
            }
         }
         catch(err:*)
         {
            cfg.diagSet("lastErr", "key:" + err);
         }
      }
   }
}
