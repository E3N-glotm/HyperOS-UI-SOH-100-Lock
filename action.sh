#!/system/bin/sh
MODDIR=${0%/*}
echo "HyperOS UI SOH 100 Lock by E3N"
echo "Vendor UI SOH frame:"
/system/bin/cat /sys/class/xm_power/fg_master/ui_soh
echo "Raw gauge SOH:"
/system/bin/cat /sys/class/xm_power/fg_master/soh
echo "Recent events:"
/system/bin/tail -n 12 "$MODDIR/lock.log" 2>/dev/null
