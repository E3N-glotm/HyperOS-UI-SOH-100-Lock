#!/usr/bin/env python3
"""v1.1.0-alpha.2 display-layer contract: read-only, labelled, APK-free.

Statements are inspected with comments removed, so a comment that names an
operation it deliberately avoids cannot be mistaken for that operation.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
action = (root / "action.sh").read_text(encoding="utf-8")
layers = (root / "ui_soh_display_layers.sh").read_text(encoding="utf-8")
core = (root / "ui_soh_core.sh").read_text(encoding="utf-8")
service = (root / "service.sh").read_text(encoding="utf-8")
customize = (root / "customize.sh").read_text(encoding="utf-8")
prop = (root / "module.prop").read_text(encoding="utf-8")


def executed(text: str) -> str:
    return "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("#"))


reporter = executed(layers)
checks = {
    "module id stays immutable and the version advances":
        "id=hyperos_ui_soh_100_lock" in prop
        and "version=1.1.0-alpha.2" in prop and "versionCode=1102" in prop,
    "the SOH core is byte-identical to the released v1.1.0-alpha.1 core":
        core == (root / "tests/expected/ui_soh_core_v1101.sh").read_text(
            encoding="utf-8"),
    "the SOH service loop is unchanged":
        service == (root / "tests/expected/service_v1101.sh").read_text(
            encoding="utf-8"),
    "the reporter is strictly read-only":
        not any(
            token in reporter.replace('printf "probe_write_policy=none\\n"', "")
            for token in (
                "> \"$NODE", ">\"$NODE", "settings put", "settings delete",
                "content insert", "content update", "content delete",
                "content write", "setprop", "resetprop", "chmod", "chcon",
                "mount ", "umount", "echo 100", "ui_soh_core.sh once",
            )
        )
        and "ui_soh_core.sh" not in reporter,
    "the reporter declares its write policy":
        "probe_write_policy=none" in reporter,
    "every layer is labelled with its source path":
        "/sys/class/xm_power/fg_master/ui_soh" in layers
        and "/sys/class/xm_power/fg_master/soh" in layers
        and "/sys/class/xm_power/fg_master/cyclecount" in layers
        and "/sys/class/power_supply/battery/cycle_count" in layers
        and "/sys/class/power_supply/battery/charge_full" in layers
        and "content://com.miui.powercenter.provider" in layers
        and "getBatteryHealthValue" in layers
        and "pc_sec_user0_ui_soh" in layers,
    "units are explicit so microamp-hour values are never shown as mAh":
        "charge_full_uAh" in layers and "charge_full_mAh" in layers
        and "charge_full_design_uAh" in layers and "charge_full_design_mAh" in layers
        and "cycles" in layers and "percent" in layers,
    "missing data is reported as unreadable instead of substituted":
        "unreadable" in reporter and "|| echo unreadable" in reporter,
    "the three layers are declared distinct rather than merged":
        "separate" in layers and "not raw cell" in layers
        and "not a capacity change" in layers,
    "action is read-only and never writes the fuel gauge":
        not any(
            token in executed(action)
            for token in ("settings put", "content insert", "content update",
                          "content delete", "setprop", "chmod", "chcon",
                          "mount ", "umount")
        )
        and 'ui_soh_core.sh" check' in executed(action)
        and 'ui_soh_core.sh" once' not in executed(action),
    "action delegates to the labelled reporter when present":
        "ui_soh_display_layers.sh" in action,
    "no standalone companion APK is shipped or referenced as a fix":
        ".apk" not in action and ".apk" not in customize
        and "batterycycledisplay" not in executed(action),
    "the unrepaired native page is stated instead of claimed fixed":
        "not repaired by this module" in action
        and "reference_cycle_count" in action,
    "the installer hands over the reporter with the right mode":
        "ui_soh_display_layers.sh" in customize
        and customize.count("chmod 0755") >= 1,
    "no firmware build-number or SDK decision gate was introduced":
        not any(
            token in executed(layers) + executed(action) + executed(customize)
            for token in ('[ "$(getprop ro.build.version', '[ "$SDK', '[ "$BUILD')
        ),
}
for label, ok in checks.items():
    if not ok:
        raise AssertionError(label)
    print("PASS", label)
print("UI_SOH_DISPLAY_LAYERS_READONLY_APK_FREE_CONTRACT_PASS")
