#!/system/bin/sh
SKIPMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true
ui_print "- HyperOS UI SOH 100 Lock by E3N"
ui_print "- Standalone module; no ROM version gate"
if [ ! -r /sys/class/xm_power/fg_master/ui_soh ]; then
  abort "! Missing vendor fg_master/ui_soh"
fi
chmod 0755 "$MODPATH/ui_soh_core.sh" "$MODPATH/service.sh" "$MODPATH/action.sh"
/system/bin/sh "$MODPATH/ui_soh_core.sh" check /sys/class/xm_power/fg_master/ui_soh ||
  abort "! Unknown UI SOH frame; fail closed"
ui_print "- Frame validated; service will start after reboot"
