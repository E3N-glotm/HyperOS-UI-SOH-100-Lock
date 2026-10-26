# HyperOS UI SOH 100 Lock · 电池界面健康度固定

**语言：简体中文（当前） | [English](README_EN.md)**

独立的 Magisk 实验模块，用于在已验证的 Xiaomi `pudding` 电池驱动上将**界面层 SOH** 固定为 100。与“电池循环档位与老化策略模块”分别发布，两者作用不同。

**当前版本：v1.0.0（实验版）** · [下载 Release](https://github.com/E3N-glotm/HyperOS-UI-SOH-100-Lock/releases)

> [!WARNING]
> **UI SOH 100 不表示电芯恢复到新电池容量。** 修改显示或厂商估算值可能影响部分容量补偿与策略判断；它不是电芯校准，也没有改变真实 SOH、循环次数、Qmax、电池温度或实际充电参数。

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
