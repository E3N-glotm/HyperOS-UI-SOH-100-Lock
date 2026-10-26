# HyperOS UI SOH 100 Lock

**Language: [简体中文](README.md) | English (current)**


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
