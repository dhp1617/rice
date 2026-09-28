#!/bin/bash
SECS=${1:-30}
SUM=0
echo "Sampling for ${SECS}s..."
for i in $(seq 1 $SECS); do
    C=$(cat /sys/class/power_supply/BAT1/current_now)
    V=$(cat /sys/class/power_supply/BAT1/voltage_now)
    PART=$(awk -v c="$C" -v v="$V" 'BEGIN { printf "%d", c*v/1000000 }')
    SUM=$((SUM + PART))
    sleep 1
done
awk -v s="$SUM" -v n="$SECS" 'BEGIN { printf "Average: %.2fW over %ds\n", s/n/1000000, n }'
