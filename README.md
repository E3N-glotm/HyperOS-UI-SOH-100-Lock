# HyperOS UI SOH 100 Lock · 电池界面健康度固定

**语言：简体中文（当前） | [English](README_EN.md)**

独立的 Magisk 实验模块，用于在已验证的 Xiaomi `pudding` 电池驱动上将**界面层 SOH** 固定为 100。与“电池循环档位与老化策略模块”分别发布，两者作用不同。

**当前版本：v1.1.0-alpha.1（预览版）** · [下载 Release](https://github.com/E3N-glotm/HyperOS-UI-SOH-100-Lock/releases)

> [!WARNING]
> **UI SOH 100 不表示电芯恢复到新电池容量。** 修改显示或厂商估算值可能影响部分容量补偿与策略判断；它不是电芯校准，也没有改变真实 SOH、循环次数、Qmax、电池温度或实际充电参数。

## 2026-11-10 重要纠正：旧版界面伴随 APK 已停用

**不要继续安装 v1.1.0-alpha.1 的独立 LSPosed APK。** 已在真实 `OS4.0.5.0.XPCCNXM` / 安全中心 `13.6.6-261028.0.1` 核查，用户查看的电池保护界面实际是 `com.miui.powercenter.nightcharge.ChargerProtectActivity` 内的 `ChargeProtectFragment.onCreatePreferences`，而旧 APK Hook 的是**另一个页面** `com.miui.powercenter.charge.ChargeFeatureFragment`，未解决用户报告的循环次数不显示问题。手机已移除旧伴随 APK。

从原厂 DEX 确认真实原因：`ChargeProtectFragment` 虽然创建 `reference_cycle_count`，但通过 `oh.g.N()` 机型/地区能力判断将该条目从 `preference_key_category_battery_info` 移除；该判断在中国区固件中返回 false。原始循环次数仍可从 `/sys/class/xm_power/fg_master/cyclecount` 读取，本机为 **129**。**不应改变 ROM 地区/全局 Build 标志**，因为会影响同一页面其它条目与更多系统功能。

按照用户要求，后续只接受**一个 Magisk ZIP、没有独立 APK**的解决方案。须使用仅针对安全中心进程的系统无感、可卸载运行时补丁，恢复原生循环次数偏好且保持真实健康/充电数据不变。**该原生界面补丁尚未完成构建及手机可视验收，不要把现有 Magisk ZIP 误称为已修复原生页面。** 现有 Magisk ZIP 的「操作」页可以只读显示真实循环计数，UI SOH 覆盖功能仍按原逻辑运行。

## v1.1.0-alpha.1：电池保护循环次数显示兼容（预览版）

**[查看新版本 Release](https://github.com/E3N-glotm/HyperOS-UI-SOH-100-Lock/releases/tag/v1.1.0-alpha.1)**。

2026-11-09 实机检查 Xiaomi pudding / Android 17 / OS4.0.5.0.XPCCNXM：驱动 `cyclecount=128`、`/sys/class/power_supply/battery/cycle_count=128`，原厂 11 字段 `ui_soh` 中第 2 项为 128，安全中心 13.6.6 日志 `BatteryHealthUtils.getBatteryCycleCount:128`。**底层真实循环次数正常，消失的是页面展示，不可通过伪造电池计数或修改原厂充电档位修复。**

此版本保留原 Magisk 模块 ID，`ui_soh_core.sh`、`service.sh`、`customize.sh` **不改变**；只改 Magisk“操作”页的真实循环次数查询，并发布一个**可选的 LSPosed 伴随 APK**：

- **Magisk**：`HyperOS-UI-SOH-100-Lock-v1.1.0-alpha.1.zip`。升级原 UI SOH 模块，依然只把已验证的 UI SOH 第 1 字段限制为 100，真实循环次数和其余字段不改。
- **LSPosed**：`HyperOS-Battery-Cycle-UI-Compat-v1.1.0-alpha.1.apk`。在系统安全中心的电池保护 `ChargeFeatureFragment.onCreatePreferences(Bundle, String)` 加入只读循环数条目，优先使用和安全中心相同的 `miui.util.IMiCharge.getBatteryCycleCount()`，失败时只读检测硬件节点；识别到原厂循环数条目已经显示时跳过，不制造重复项。
- **安装 LSPosed 伴随 APK**：安装 APK → 打开 LSPosed 管理器 → 启用“E3N 电池循环显示兼容” → 作用域只勾选**安全中心（`com.miui.securitycenter`）** → 重新启动安全中心进程或重启手机 → 进入电池保护页核实是否显示真实次数。若不使用 LSPosed，Magisk「操作」页仍能查看原厂真实循环次数。

这不是将两个原本独立的电池模块合并：**电池循环档位与老化策略锁定模块仍独立**，当前固件已触发其源配置指纹保护、状态为 INACTIVE，此版本**不会**强行重新启用或修改老化充电曲线。

**验证边界：**CI 完成 Java/DEX/签名、静态回归及 ZIP 校验，实机确认系统返回 128 次；手机已安装伴随 APK，但由于当前锁屏且 LSPosed 作用域尚未启用，**尚未完成实际页面显示验证**，故只发布 alpha 预览版。APK 使用临时预览签名，今后更新可能需要卸载旧伴随 APK 后重新安装。该补丁不修改任何电池计数、健康度原值或充电电流、电压和温控策略。


## 功能

- 探测当前驱动 `/sys/class/xm_power/fg_master/ui_soh` 接口，不依赖系统版本号。
- 每 90 秒读取一次 UI SOH 数据，校验 OEM **11 字段帧及校验字节**，只调整 UI SOH 字段和对应校验字节。
- 每小时最多 3 次写入；无法识别格式、遇到连续 OEM 冲突或写入失败时停止，避免无限重试。
- Magisk“操作”页显示当前 UI SOH、原始 SOH 和事件日志。

## 已验证结果及局限

在 `pudding` / HyperOS 4 的一次实际测试中，UI SOH 从 99 变为 100，系统上报的 `charge_full` 从 6878 变为 6978 mAh；**真实 SOH 仍为 96%，Qmax 及循环次数未变化**。上报容量变化属于估算/补偿，不能证明可用电量真正增加。内核曾输出保存失败信息，跨重启保持效果依赖模块服务，不能视作永久写入。

## 安装、状态与恢复

使用 [Release ZIP](https://github.com/E3N-glotm/HyperOS-UI-SOH-100-Lock/releases) 从 Magisk 安装并重启，通过“操作”页观察是否生效。停用或卸载并重启后停止覆盖，原厂 UI SOH 估算会随其后续更新机制恢复。

日志位置：`/data/adb/modules/hyperos_ui_soh_100_lock/lock.log`。

此项目是实验性能力探测版本，未验证其他电量计芯片及固件接口，**不推荐盲目跨机型刷入**。
