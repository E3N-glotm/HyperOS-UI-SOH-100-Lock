#!/system/bin/sh
SKIPMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true
ui_print "- HyperOS UI SOH 100 Lock by E3N (v1.1.0-alpha.2)"
ui_print "- Standalone module; no ROM version gate"
if [ ! -r /sys/class/xm_power/fg_master/ui_soh ]; then
  abort "! Missing vendor fg_master/ui_soh"
fi
chmod 0755 "$MODPATH/ui_soh_core.sh" "$MODPATH/service.sh" "$MODPATH/action.sh" \
  "$MODPATH/ui_soh_display_layers.sh"
/system/bin/sh "$MODPATH/ui_soh_core.sh" check /sys/class/xm_power/fg_master/ui_soh ||
  abort "! Unknown UI SOH frame; fail closed"
ui_print "- Frame validated; service will start after reboot"
ui_print "- Magisk Action now prints UI SOH, Provider value, raw SOH and cycles"
ui_print "  with their source layer and unit (read-only)"
ui_print "- No standalone companion APK in this release"
