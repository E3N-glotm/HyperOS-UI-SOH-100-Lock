# HyperOS UI SOH 100 Lock

**Language: [简体中文](README.md) | English (current)**


Author: E3N | Release v1.0.0 (experimental).

This is an **independent Magisk module** targeting Xiaomi pudding BQ27Z561 driver's vendor UI SOH. It is not combined with the existing Battery Cycle + SOH Index Lock.

## v1.1.0-alpha.1 (preview): Restore visible battery cycle count in protection settings

[New preview release](https://github.com/E3N-glotm/HyperOS-UI-SOH-100-Lock/releases/tag/v1.1.0-alpha.1).

On Nov 9, Xiaomi pudding / Android 17 reported an actual cycle count of **128** in both Android and OEM sysfs, the second field of the eleven-value UI SOH frame, and Security Center 13.6.6 logs (`BatteryHealthUtils.getBatteryCycleCount: 128`). This confirms the underlying counter is intact; the missing item is a presentation problem, not lost battery telemetry.

Two separate artifacts:

- **Magisk ZIP**: `HyperOS-UI-SOH-100-Lock-v1.1.0-alpha.1.zip`. Existing UI SOH core, 90-second service, install-time validation and hardware behavior are unchanged; Magisk Action now includes read-only live cycle diagnostics.
- **Optional LSPosed companion APK**: `HyperOS-Battery-Cycle-UI-Compat-v1.1.0-alpha.1.apk`. Injects a read-only `Battery cycle count` preference into Xiaomi Security Center's `ChargeFeatureFragment.onCreatePreferences(Bundle, String)` using OEM `IMiCharge.getBatteryCycleCount()` or strict read-only hardware fallback, and avoids duplicating a visible native cycle entry.

To enable the companion: install APK, open LSPosed Manager, activate **E3N Battery Cycle Display Compat** and scope it **only** to `com.miui.securitycenter`, then restart Security Center or reboot and check Battery protection. The companion does not run without LSPosed and scope activation. It does not alter any charging policy, SOH inputs, firmware, or underlying battery counter.

The separate Battery Cycle & SOH Index Lock module currently fails closed because its OEM encrypted configuration fingerprint changed; this release intentionally does not re-enable its battery aging charging policy. **CI validated APK compilation and integrity, and on-device reads confirm 128 actual cycles, but the protected lock screen prevented visual UI verification after installation.** Thus this remains a preview and should not be presented as an end-to-end verified display fix. The APK uses a temporary preview signature and may require uninstalling the previous preview companion before future upgrades.


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
