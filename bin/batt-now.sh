#!/bin/bash
C=$(cat /sys/class/power_supply/BAT1/current_now)
V=$(cat /sys/class/power_supply/BAT1/voltage_now)
S=$(cat /sys/class/power_supply/BAT1/status)
awk -v c="$C" -v v="$V" -v s="$S" 'BEGIN { printf "%.2fW  [%s]\n", c*v/1000000000000, s }'
