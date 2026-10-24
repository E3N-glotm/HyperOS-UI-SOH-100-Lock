#!/system/bin/sh
# Validated against the 11-number output of Xiaomi BQ27Z561.
# Last field is a check byte: (sum of all 11 fields) mod 256 == 255.
# Only field 1 (UI SOH) and last field are changed; fields 2-10 are preserved.
set -f
ACTION=${1:-check}
NODE=${2:-/sys/class/xm_power/fg_master/ui_soh}
raw=$(/system/bin/cat "$NODE" 2>/dev/null) || exit 2
set -- $raw
[ "$#" -eq 11 ] || exit 3
sum=0
i=0
for num do
  case "$num" in
    ""|*[!0-9]*|0[0-9]*) exit 4 ;;
  esac
  [ "${#num}" -le 6 ] || exit 4
  if [ "$i" -eq 0 ]; then
    [ "$num" -ge 80 ] && [ "$num" -le 100 ] || exit 5
  fi
  if [ "$i" -eq 10 ]; then
    [ "$num" -ge 0 ] && [ "$num" -le 255 ] || exit 6
    old_check=$num
  fi
  sum=$((sum + num))
  i=$((i + 1))
done
[ "$((sum % 256))" -eq 255 ] || exit 7
old_soh=$1
if [ "$ACTION" = check ]; then
  printf 'valid ui_soh=%s\n' "$old_soh"
  exit 0
fi
[ "$ACTION" = once ] || exit 8
[ "$old_soh" -eq 100 ] && exit 0
delta=$((100 - old_soh))
new_check=$(((old_check - delta + 256) % 256))
shift
set -- 100 "$@"
new=""
i=0
for num do
  [ "$i" -eq 10 ] && num=$new_check
  if [ -z "$new" ]; then new=$num; else new="$new $num"; fi
  i=$((i + 1))
done
printf '%s\n' "$new" > "$NODE" 2>/dev/null || exit 9
after=$(/system/bin/cat "$NODE" 2>/dev/null) || exit 10
set -- $after
[ "$#" -eq 11 ] && [ "$1" -eq 100 ] || exit 11
printf 'changed %s -> %s\n' "$raw" "$after"
