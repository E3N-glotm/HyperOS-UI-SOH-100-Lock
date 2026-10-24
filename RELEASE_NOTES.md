## v1.0.0 - standalone UI SOH 100 Lock

**Independent Magisk module; unrelated to the Battery Cycle + SOH Index Lock release series.**

### Validated on Xiaomi pudding / HyperOS 4.0.4.0

- UI SOH: 99 -> 100 on actual sysfs, with OEM 11-field checksum preserved.
- System-reported charge_full: 6,878 -> 6,978 mAh after dynamic compensation updated.
- Raw fuel-gauge SOH: 96 -> 96 (unchanged).
- Battery cycle count: 117 -> 117 (unchanged).
- Qmax: 6,762 -> 6,762 mAh (unchanged).

Automatic monitoring after reboot, 90-second interval, maximum 3 sysfs writes per hour, stops safely on unknown frame or failure. Magisk Action shows status.

**Important:** Higher reported charge_full is an accounting/compensation effect, NOT actual capacity restoration. The vendor kernel still printed a storage-write error during live testing, so persistence across reboots depends on the module service; long-term reboot behaviour is not yet proven.

### 中文

这是**单独的 Magisk Release**，不影响原先的电池循环／老化策略模块。pudding / HyperOS 4.0.4.0 真机已核实：UI SOH 99% -> 100%，系统报告满充容量 6878 -> 6978mAh；原始 SOH、循环次数和 Qmax 均未改变。电量计仍报告过保存失败的内核错误，因此**重启后的持续生效依赖模块服务**，并非已验证的永久写入。

**100% 是人为固定的 UI 估计输入，不等于电池恢复为新电池。**
