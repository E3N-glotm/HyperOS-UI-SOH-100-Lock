#!/usr/bin/env python3
"""Retired-companion contract for the verified native battery protection page.

The v1.1.0-alpha.1 companion APK hooked ChargeFeatureFragment, which is not the
page users actually open. This test freezes what the next Magisk-only native
patch must bind against, using the on-device 13.6.6-261028.0.1 disassembly, and
refuses any regression back to the wrong page or to an extra APK.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
hook = (root / "companion/src/io/github/e3n/batterycycle/"
                    "BatteryCycleDisplayHook.java").read_text(encoding="utf-8")
prop = (root / "module.prop").read_text(encoding="utf-8")
action = (root / "action.sh").read_text(encoding="utf-8")

VERIFIED_PAGE = "com.miui.powercenter.nightcharge.ChargeProtectFragment"
WRONG_PAGE = "com.miui.powercenter.charge.ChargeFeatureFragment"

checks = {
    "the companion source is frozen and points at the retired wrong page":
        WRONG_PAGE in hook and "FROZEN v1.1.0-alpha.1" in hook,
    "the frozen companion is not described as the fix":
        "DEPRECATED" in hook and "Not shipped" in hook,
    "the verified page and preference key are recorded for the next patch":
        VERIFIED_PAGE in hook and "reference_cycle_count" in hook,
    "the OEM capability gate that removes the row is recorded":
        "oh.g.N" in hook and "removePreference" in hook,
    "the wrong page can never silently become the active target again":
        WRONG_PAGE not in action
        and VERIFIED_PAGE.split(".")[-1] in action,
    "no standalone APK is shipped in this module version":
        "no standalone companion apk" in action.lower(),
}
for label, ok in checks.items():
    if not ok:
        raise AssertionError(label)
    print("PASS", label)
print("NATIVE_PAGE_TARGET_CONTRACT_PASS")
