#!/system/bin/sh
# v1.1.0-alpha.2: read-only evidence with each value labelled by layer, source
# path and unit, so a display-layer difference is never mistaken for a change in
# real battery capacity or in Security Center health. No sysfs write happens
# here; ui_soh_core.sh is only ever invoked in "check" mode.
MODDIR=${0%/*}
echo "HyperOS UI SOH 100 Lock by E3N (v1.1.0-alpha.2, Magisk-only)"
if [ -f "$MODDIR/ui_soh_display_layers.sh" ]; then
  /system/bin/sh "$MODDIR/ui_soh_display_layers.sh"
else
  # Fallback for a partial install: still read-only, still labelled.
  printf 'ui_soh_frame=%s\n' \
    "$(/system/bin/cat /sys/class/xm_power/fg_master/ui_soh 2>/dev/null || echo unreadable)"
  printf 'raw_soh_percent=%s\n' \
    "$(/system/bin/cat /sys/class/xm_power/fg_master/soh 2>/dev/null || echo unreadable)"
  printf 'fg_cyclecount_cycles=%s\n' \
    "$(/system/bin/cat /sys/class/xm_power/fg_master/cyclecount 2>/dev/null || echo unreadable)"
  printf 'power_supply_cycle_count_cycles=%s\n' \
    "$(/system/bin/cat /sys/class/power_supply/battery/cycle_count 2>/dev/null || echo unreadable)"
  printf 'charge_full_uAh=%s\n' \
    "$(/system/bin/cat /sys/class/power_supply/battery/charge_full 2>/dev/null || echo unreadable)"
fi
echo "--- SOH lock core state ---"
/system/bin/sh "$MODDIR/ui_soh_core.sh" check /sys/class/xm_power/fg_master/ui_soh 2>/dev/null ||
  echo "ui_soh_core: frame not recognised (fail closed, no write attempted)"
echo "--- Native battery protection page (cycle row) ---"
echo "The OEM ChargeProtectFragment removes reference_cycle_count on CN firmware"
echo "after its own capability check. That page is not repaired by this module"
echo "yet, and no standalone companion APK ships with this version."
echo "Recent SOH lock events:"
/system/bin/tail -n 12 "$MODDIR/lock.log" 2>/dev/null || true
