# 非致命激光枪读档失效与命中调试

## 现象与复现

用户反馈仍无弹道，要求设置中加入实战失明调试标志。真实配置只读诊断显示核心 1.7.0-multi-lock、激光 3-visual-eyes，laserShots=30 / laserBlinds=2 未增长，且没有新组件应写入的 laserLastHit；没有 laserError。这使排查转向实际开火对象，而非继续调整素材。

`build/test-laser-reload.ps1 -Nodebug` 对原正式 SWF（SHA256 F02FF3DBC917F557C59ADEF2EBC9605163E132FAC964952A1B437B8BF1BB5E97）复现：隔离新档赠枪→装备→saveGame(1)→comLoad=1→自然换枪结束→开火。结果扣弹 12→10，但回调计数未定义，失明 0，错误为空；背包为 MSWDazzlerWeapon，currentWeapon/newWeapon 都是原 Weapon。

三项假设按顺序排查：读档待装备引用恢复旧对象、回调丢失、生成后的光束被隐藏。`UnitPlayer.attach()` 调用延迟 changeWeapon，把原对象存入 newWeapon；ensureWeapon 未替换此字段。只补 newWeapon 引用同步，同一测试即恢复每枪一次回调、失明6秒、HP不变。单变量证据留 build/out/laser-debug/baseline-reload-fail.txt 与 single-change-pass.txt。

此前测试直接即时装备或只调用 Weapon.create，没有覆盖实际读档的延迟装备窗口；因此先前的通过不能排除用户这个故障。

## 修复及调试入口

- MSWLaser.ensureWeapon 同步 gg.newWeapon===old 的引用，其余原生换枪过程保持。
- 激光组件标记 `4-reload-debug`；核心仍沿用已安装的 1.7.0-multi-lock。
- `laserDebug=false`，Pip「模组→非致命激光枪」及 F6 激光页新增「失明命中调试标志」，共12项。两入口共享并持久保存。
- 装备本枪时显示最近开火结果；命中点十字、命中时眼区与原因保留3秒。成功为绿色“已失明”，其余区分身体/背面/护盾/不适用目标/未命中单位；每目标只留最新标志，最多8个。关闭立即隐藏调试，不隐藏原有倒计时。
- 诊断新计数 laserShotEntered 在 fire 入口增加，laserLastHit 记录细分原因；回调异常在开关开启时可见。
- 沿用原版激光素材、投射物层与4次世界步消退；根因修复恢复其执行，没有再换自绘光束。

## 验证与产物

- 最终生产候选：build/out/laser-debug/MoreSkillsWeaponsMod.swf，43654字节，SHA256 `04A7E69F62044840F9BCA112E235632546096FB9C360C6F5869446DAF4E1E0B9`。
- 正式编译、33个定义，原宿主类型外部引用，无 Smoke/Probe。
- 39行 PASS 的读档/诊断/实际舞台检查，包含最终成功行：默认关、F6开关、保存重载、ModSettings共享、全部命中原因、关闭隐藏且普通倒计时保留、原生换枪/耗弹/致盲、移动朝向与传感器。
- 未暂停 World/Location 开火，EXIT_FRAME 采完整舞台：暂隐藏单个光束做像素差分，6帧见光束、峰值174个像素变化；样图 build/out/laser-reload/live-laser-stage.png。测试窗口隐藏但实际游戏显示树被完整合成，不只绘素材自身。
- 251行 PASS 的既有机制与实际 Sandevistan 联测，含最后成功行；时停内开火一次、回放一次、失明保持及计时。
- 对安装基线及候选逐类反编译比对：只变 MSWConfig、MSWSettingsHub、MSWLaser、MSWLaserGeometry、MSWLaserHUD。其余28类一致，保留多重锁定、HUD与原运动逻辑。
- 最终生产字节另过51项多重锁定实战，含9弹均分、5弹粒霰弹、真实伤害、独立遮挡与死亡；使用HEAD对应探针冻结到out/laser-debug/probe，避免混入并发的1.8测试要求。
- 安装前后同字节均通过900帧持续运行、ModSettings-connected、tabOn=1，激光4-reload-debug，无lastErr/smartError/laserError。安装已完成；备份release/MoreSkillsWeaponsMod.before-laser-reload-debug-20260923.swf，42525字节、SHA256 F02FF3DBC917F557C59ADEF2EBC9605163E132FAC964952A1B437B8BF1BB5E97。回滚将其复制回正式路径再重启。
- 冻结源码从本轮开始时 HEAD（46d0e64）提取，只加5个生产文件的本轮改动；同期平滑弹道正在其他工作中修改，未将其未完成源码混入本候选。

安装状态及回滚指纹以 state/MEMORY.md 的最新安装记录为准。本次只验证根1.02、代表敌人和独立实际时停；不宣称覆盖全部模组组合、DLC、长期游戏和所有眼位动画。
