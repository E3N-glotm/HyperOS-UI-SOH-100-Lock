#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/lock.log"
CORE="$MODDIR/ui_soh_core.sh"
NODE=/sys/class/xm_power/fg_master/ui_soh
touch "$LOG"
logline() {
  printf '%s %s\n' "$(/system/bin/date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
  [ "$(/system/bin/wc -c < "$LOG")" -gt 32768 ] && {
    /system/bin/tail -n 120 "$LOG" > "$LOG.tmp"
    /system/bin/mv -f "$LOG.tmp" "$LOG"
  }
}
tries=0
while [ "$(/system/bin/getprop sys.boot_completed)" != 1 ]; do
  [ -f "$MODDIR/disable" ] && exit 0
  /system/bin/sleep 5
  tries=$((tries + 1))
  [ "$tries" -le 120 ] || exit 0
done
logline "started; max 3 sysfs writes per hour"
window=0
count=0
while :; do
  if [ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ]; then exit 0; fi
  now=$(/system/bin/date +%s)
  if [ "$((now - window))" -ge 3600 ]; then
    window=$now
    count=0
  fi
  state=$(/system/bin/cat "$NODE" 2>/dev/null)
  set -- $state
  if [ "$#" -eq 11 ] && [ "$1" != 100 ]; then
    if [ "$count" -ge 3 ]; then
      logline "OEM conflict: >3 writes/hour; stop until next boot"
      exit 0
    fi
    out=$(/system/bin/sh "$CORE" once "$NODE" 2>&1)
    code=$?
    if [ "$code" -ne 0 ]; then
      logline "write/verify failure code=$code; stopping: $out"
      exit 0
    fi
    count=$((count + 1))
    logline "$out"
  fi
  /system/bin/sleep 90
done
