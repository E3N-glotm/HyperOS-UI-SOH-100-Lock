# HyperOS UI SOH 100 Lock

Author: E3N | Release v1.0.0 (experimental).

This is an **independent Magisk module** targeting Xiaomi pudding BQ27Z561 driver's vendor UI SOH. It is not combined with the existing Battery Cycle + SOH Index Lock.

## How it works

- After startup, inspects /sys/class/xm_power/fg_master/ui_soh once every 90 seconds.
- Validates the observed **11-field** frame and trailing check byte before writing; unknown formats fail closed.
- Changes **only** field 1 (UI SOH) to 100 and adjusts the trailing check byte; fields 2-10, including recorded battery history, are preserved.
- Maximum 3 writes per hour; stops on repeated OEM conflicts or a write failure, rather than looping indefinitely.
- Magisk's Action shows the UI SOH, original raw SOH and recent event log.
- No ROM version gate; feature-probing at installation/runtime.

## Warnings

This is a **reporting/estimation override**, NOT physical capacity restoration or fuel-gauge calibration. It does not touch the raw gauge SOH, cycles, thermal limits, voltage, current or charging strategy. Vendor full-capacity compensation may show higher charge_full when UI SOH is held at 100, but this does not establish higher usable battery capacity. Masking battery aging can affect other vendor policies. Monitor charging safety and temperature and disable if unusual behavior occurs. Compatibility outside the observed pudding driver is not assured.

## Installation and rollback

Install the ZIP from Magisk Modules; reboot to start the monitor. Use Magisk Action to view current status. To revert, disable or remove the module and reboot. OEM firmware will resume normal health estimation on its update schedule.

Log: /data/adb/modules/hyperos_ui_soh_100_lock/lock.log

## 中文说明

该 Magisk 模块**独立发布**，不合并进原有电池循环／老化策略模块。开机后每 90 秒检查一次 UI SOH；验证厂商 11 字段格式和末尾校验后，将**第一个 UI SOH 字段**固定为 100，并更新末尾校验字节；保留其余字段、原始 SOH、循环次数与原厂充电及温控配置。

每小时最多写入三次；如果厂商持续覆盖，或者格式不支持／验证失败，自动停止写入。卸载或关闭后重启，由厂商重新管理 UI SOH。

**注意：固定 UI SOH 不会修复电池老化、增加真实容量，也不等于更准确的健康度测量。** 它可能使系统显示的满充容量更高，但那只是估算逻辑发生变化。

Observed pudding HyperOS 4.0.4.0 readout: 99 101 0 4 99 95 95 96 96 96 242 (sum modulo 256 = 255). Fields 2-10 are not independently reverse-engineered and are not modified.
