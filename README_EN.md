# HyperOS UI SOH 100 Lock

**Language: [简体中文](README.md) | English (current)**


Author: E3N | Current release: v1.1.0-alpha.2 (preview, not marked Latest) — Magisk ZIP only, no standalone companion APK.

## v1.1.0-alpha.2: no standalone APK, layered read-only display diagnostics

[Release](https://github.com/E3N-glotm/HyperOS-UI-SOH-100-Lock/releases/tag/v1.1.0-alpha.2). The UI SOH core and its service are **byte-identical** to v1.1.0-alpha.1 (CI diffs them against the frozen tag); only observability changed and the standalone companion APK is no longer published. The module id stays `hyperos_ui_soh_100_lock` and the version advances to `1.1.0-alpha.2` / `versionCode=1102`.

The Magisk Action page now reports three distinct layers through a read-only probe (`ui_soh_display_layers.sh`): the fuel-gauge UI SOH sysfs input this module pins, the Security Center persisted value plus the PowerCenterProvider return value, and the raw SOH with the real cycle counters — each labelled with its source path and unit (cycles / percent / µAh / mAh). An unreadable layer prints `unreadable` instead of a substitute value. Writing the fuel-gauge UI input does not rewrite the Security Center record or the Provider return value, the Provider value is not raw cell health, and `charge_full` is a fuel-gauge estimate that moves with the UI SOH estimate rather than a measured capacity restoration.

The frozen companion source records the real target for the next Magisk-only native patch: bind to `com.miui.powercenter.nightcharge.ChargeProtectFragment.onCreatePreferences`, key on the OEM preference `reference_cycle_count` so the native row is restored rather than duplicated, read only `miui.util.IMiCharge.getBatteryCycleCount()` with read-only sysfs fallbacks, inject nothing when the value is unavailable, never inject into an unverified Security Center build, and never touch the Provider return value, the persisted health record, raw SOH, the counters or any charge policy. Until that patch is built and visually accepted on the native page, this module does not claim the native page is fixed.

This is an **independent Magisk module** targeting Xiaomi pudding BQ27Z561 driver's vendor UI SOH. It is not combined with the existing Battery Cycle + SOH Index Lock.

## Nov 10, 2026 correction: prior companion APK is deprecated

**Do not install the v1.1.0-alpha.1 standalone LSPosed companion APK.** On the tested HyperOS OS4.0.5.0 / Security Center 13.6.6, the actual Battery Protection page is `com.miui.powercenter.nightcharge.ChargeProtectFragment.onCreatePreferences`, not the `com.miui.powercenter.charge.ChargeFeatureFragment` incorrectly targeted by the companion APK. It was not a verified UI fix and has been uninstalled from the tested phone.

OEM DEX analysis confirms the UI creates `reference_cycle_count` but removes the native preference under `oh.g.N()` model/region feature gating. The true cycle count is still available in `/sys/class/xm_power/fg_master/cyclecount` (**129 cycles** at inspection). Global international-build spoofing is not an acceptable fix because it changes other feature paths.

Future display repair must be delivered as a **Magisk-only ZIP with no standalone APK and no LSPosed scope configuration**, strictly limited to the Security Center UI and leaving BMS/charging policies intact. **No such native in-process display patch has yet passed build and visual on-device validation.** The existing Magisk Action can already read true cycles; do not interpret it as a confirmed repair of Xiaomi's native Battery Protection page.

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
