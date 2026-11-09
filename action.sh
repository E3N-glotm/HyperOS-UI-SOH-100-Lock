#!/system/bin/sh
# v1.1: read-only evidence for both the real fuel gauge and displayed SOH.
MODDIR=${0%/*}
echo "HyperOS UI SOH 100 Lock + Cycle UI Compat by E3N"
printf '真实循环次数 / Real cycles: '
/system/bin/cat /sys/class/xm_power/fg_master/cyclecount 2>/dev/null ||
  /system/bin/cat /sys/class/power_supply/battery/cycle_count 2>/dev/null ||
  echo 'unavailable'
printf '原始SOH / Raw SOH: '
/system/bin/cat /sys/class/xm_power/fg_master/soh 2>/dev/null || echo unavailable
echo "OEM UI SOH frame (field 2 is untouched cycle count):"
/system/bin/cat /sys/class/xm_power/fg_master/ui_soh 2>/dev/null || echo unavailable
echo "可选电池保护页兼容插件 (须独立安装并在LSPosed中作用于安全中心):"
/system/bin/pm path io.github.e3n.hyperos.batterycycledisplay 2>/dev/null ||
  echo "未安装；请查看同版本Release的APK"
echo "Recent SOH lock events:"
/system/bin/tail -n 12 "$MODDIR/lock.log" 2>/dev/null || true
