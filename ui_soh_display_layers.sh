#!/system/bin/sh
# v1.1.0-alpha.2 read-only battery display layer reporter.
#
# The three numbers users see are three different layers and must never be
# merged into one claim:
#   1. fuel-gauge UI SOH sysfs input (what this module pins to 100),
#   2. Security Center persistent value + PowerCenterProvider return value,
#   3. raw fuel-gauge SOH and the real cycle counters.
#
# Strictly read-only: no sysfs write, no settings write, no content write, no
# property change, no chmod/chcon, no mount. It never runs ui_soh_core.sh in
# write mode. When a layer cannot be read it prints "unreadable" instead of a
# substitute, so a missing value can never look like a real 0 or 100.
NODE_UI=/sys/class/xm_power/fg_master/ui_soh
NODE_SOH=/sys/class/xm_power/fg_master/soh
NODE_CYCLE=/sys/class/xm_power/fg_master/cyclecount
PS_CYCLE=/sys/class/power_supply/battery/cycle_count
PS_FULL=/sys/class/power_supply/battery/charge_full
PS_DESIGN=/sys/class/power_supply/battery/charge_full_design
PROVIDER_URI=content://com.miui.powercenter.provider
PROVIDER_METHOD=getBatteryHealthValue

ro() {
  /system/bin/cat "$1" 2>/dev/null || echo unreadable
}

# µAh -> mAh with one decimal, pure shell, no bc dependency.
mah() {
  v="$1"
  case "$v" in ''|*[!0-9]*) printf 'unreadable'; return 0 ;; esac
  whole=$((v / 1000))
  tenth=$(( (v % 1000) / 100 ))
  printf '%d.%d' "$whole" "$tenth"
}

# Only the numbers the OEM kernel interface actually exposes are compared.
# charge_full_design is printed for context and is NOT asserted equal.
match_note() {
  if [ "$1" = unreadable ] || [ "$2" = unreadable ]; then
    printf 'cannot compare (unreadable source)'
  elif [ "$1" = "$2" ]; then
    printf 'agree'
  else
    printf 'differ (different data layers, not a capacity change)'
  fi
}

echo "=== HyperOS UI SOH 100 Lock v1.1.0-alpha.2 display layers (read-only) ==="
printf 'device=%s\n' "$(getprop ro.product.device)"
printf 'oem_build=%s\n' "$(getprop ro.build.version.incremental)"
printf 'security_center_version=%s\n' \
  "$(dumpsys package com.miui.securitycenter 2>/dev/null | \
     sed -n 's/^[[:space:]]*versionName=//p' | head -1)"
printf 'probe_write_policy=none\n'
echo
echo "--- Layer 1: fuel-gauge UI SOH sysfs input (this module pins field 1 to 100) ---"
frame="$(ro "$NODE_UI")"
printf 'ui_soh_frame=%s\n' "$frame"
set -- $frame
if [ "$#" = 11 ]; then
  printf 'ui_soh_field1=%s\n' "$1"
  printf 'ui_soh_field2=%s\n  (field 2 is the OEM frame value; this module never rewrites it)\n' "$2"
else
  printf 'ui_soh_field1=unreadable_or_unknown_frame\n'
fi
echo
echo "--- Layer 2: Security Center persisted value and OEM Provider return ---"
printf 'settings_secure_pc_sec_user0_ui_soh=%s\n' \
  "$(/system/bin/settings get secure pc_sec_user0_ui_soh 2>/dev/null || echo unreadable)"
PROVIDER_VALUE="$(/system/bin/content call --uri "$PROVIDER_URI" \
  --method "$PROVIDER_METHOD" 2>/dev/null | \
  sed -n 's/.*key_get_battery_health_value=\([^],}]*\).*/\1/p' | head -1)"
[ -n "$PROVIDER_VALUE" ] || PROVIDER_VALUE=unreadable
printf 'provider_getBatteryHealthValue=%s\n' "$PROVIDER_VALUE"
echo "(unreadable means the OEM Provider did not answer this query; it does not mean health is 0)"
echo
echo "--- Layer 3: raw fuel gauge and real counters ---"
printf 'raw_soh_percent=%s\n' "$(ro "$NODE_SOH")"
printf 'fg_cyclecount_cycles=%s\n' "$(ro "$NODE_CYCLE")"
printf 'power_supply_cycle_count_cycles=%s\n' "$(ro "$PS_CYCLE")"
FULL="$(ro "$PS_FULL")"
DESIGN="$(ro "$PS_DESIGN")"
printf 'charge_full_uAh=%s\n' "$FULL"
printf 'charge_full_mAh=%s\n' "$(mah "$FULL")"
printf 'charge_full_design_uAh=%s\n' "$DESIGN"
printf 'charge_full_design_mAh=%s\n' "$(mah "$DESIGN")"
echo
echo "--- Cross-layer consistency (informational only) ---"
printf 'fg_cyclecount_vs_power_supply=%s\n' \
  "$(match_note "$(ro "$NODE_CYCLE")" "$(ro "$PS_CYCLE")")"
echo "UI SOH sysfs field 1 and the Security Center Provider value are separate"
echo "layers: writing the fuel-gauge UI input does not rewrite the Security Center"
echo "record or the Provider return value, and the Provider value is not raw cell"
echo "health. charge_full is a fuel-gauge estimate; it moves with the UI SOH"
echo "estimate and is not a measured capacity restoration."
