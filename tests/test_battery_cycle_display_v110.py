#!/usr/bin/env python3
"""Conservative safety contracts for the optional battery protection UI adapter."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
src = (root / "companion/src/io/github/e3n/batterycycle/BatteryCycleDisplayHook.java").read_text()
manifest = (root / "companion/AndroidManifest.xml").read_text()
module = (root / "module.prop").read_text()
core = (root / "ui_soh_core.sh").read_text()
service = (root / "service.sh").read_text()
action = (root / "action.sh").read_text()
boot = (root / "customize.sh").read_text()
checks = {
    "target only Xiaomi Security Center package":
        'PKG = "com.miui.securitycenter"' in src,
    "scope only Security Center":
        (root/"companion/assets/xposed_scope").read_text().strip() == "com.miui.securitycenter",
    "non-exported, permission-free, non-autostart companion":
        "<uses-permission" not in manifest and "<activity" not in manifest
        and "<service" not in manifest and "<receiver" not in manifest,
    "hook exact verified OEM preference lifecycle and not arbitrary activity":
        'com.miui.powercenter.charge.ChargeFeatureFragment' in src
        and '"onCreatePreferences", Bundle.class, String.class' in src,
    "prefer OEM IMiCharge cycle count":
        'Class.forName("miui.util.IMiCharge"' in src
        and '"getBatteryCycleCount"' in src,
    "read-only sysfs fallbacks":
        '"/sys/class/xm_power/fg_master/cyclecount"' in src
        and '"/sys/class/power_supply/battery/cycle_count"' in src,
    "no forged counters or unbounded values":
        'value >= 0 && value <= 10000' in src
        and 'return -1;' in src,
    "do not duplicate native cycle row":
        'hasNativeVisibleCycleRow(screen)' in src,
    "inject only a non-selectable preference with a stable key":
        '"e3n_actual_battery_cycle_count"' in src
        and '"setSelectable", false' in src,
    "no file writes or charge policy mutations in hook":
        not any(x in src for x in ('FileWriter','FileOutputStream','ProcessBuilder',
                                  'Runtime.getRuntime','setprop','chmod','su -c',
                                  'batteryantiaging','BAA_config')),
    "existing UI SOH core remains frame-verified":
        "sum % 256" in core and 'new_check=' in core
        and '"$ACTION" = once' in core,
    "no battery count rewriting in Magisk shell components":
        "cyclecount" not in service and
        'cyclecount' not in boot,
    "full version and unique id retained":
        "version=1.1.0-alpha.1" in module
        and "versionCode=1101" in module
        and "id=hyperos_ui_soh_100_lock" in module,
    "Magisk action shows actual independent count":
        '/sys/class/xm_power/fg_master/cyclecount' in action,
}
for name, ok in checks.items():
    assert ok, name
    print("PASS", name)
print("BATTERY_CYCLE_UI_READONLY_ADAPTER_SAFETY_PASS")
