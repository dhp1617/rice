#!/bin/bash
# Logs battery + system state every N seconds for later analysis
# Usage: batt-log.sh [interval_seconds]   (default 60)

INTERVAL=${1:-60}
LOG="$HOME/battery-logs/batt-$(date +%Y%m%d-%H%M).csv"
mkdir -p "$HOME/battery-logs"

# CSV header
echo "time,percent,watts,voltage,status,load1,cpu_mhz,cpu_temp,governor,brightness,top_cpu" > "$LOG"

echo "Logging to: $LOG"
echo "Interval: ${INTERVAL}s  |  Ctrl+C to stop"

trap 'echo ""; echo "Stopped. Log saved to: $LOG"; exit 0' INT

while true; do
    # Time
    T=$(date +"%Y-%m-%d %H:%M:%S")

    # Battery
    P=$(cat /sys/class/power_supply/BAT1/capacity)
    C=$(cat /sys/class/power_supply/BAT1/current_now)
    V=$(cat /sys/class/power_supply/BAT1/voltage_now)
    S=$(cat /sys/class/power_supply/BAT1/status)
    W=$(awk -v c="$C" -v v="$V" 'BEGIN { printf "%.2f", c*v/1000000000000 }')

    # System
    LOAD=$(awk '{print $1}' /proc/loadavg)
    CPU_MHZ=$(awk '/cpu MHz/ {print $4; exit}' /proc/cpuinfo | awk '{printf "%.0f", $1}')
    GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

    # Temp (first available sensor)
    TEMP=$(awk 'NR==1 {printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1)

    # Brightness (percent)
    BR_CUR=$(cat /sys/class/backlight/amdgpu_bl2/brightness 2>/dev/null)
    BR_MAX=$(cat /sys/class/backlight/amdgpu_bl2/max_brightness 2>/dev/null)
    BRIGHT=$(awk -v c="$BR_CUR" -v m="$BR_MAX" 'BEGIN { if (m>0) printf "%.0f", c/m*100; else print "?" }')

    # Top CPU process (name only)
    TOP3=$(ps -eo comm,pcpu --sort=-pcpu | awk 'NR<=4 && NR>=2 {printf "%s:%.1f ", $1, $2}')

    # Top 3 CPU processes (name+%)

    # Write row
    echo "$T,$P,$W,$V,$S,$LOAD,$CPU_MHZ,$TEMP,$GOV,$BRIGHT,$TOP" >> "$LOG"

    sleep "$INTERVAL"
done
