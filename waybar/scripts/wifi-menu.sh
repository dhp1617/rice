#!/bin/bash

networks=$(nmcli -f IN-USE,SIGNAL,SSID device wifi list | tail -n +2 | sed '/^[[:space:]]*$/d')

selected=$(echo "$networks" | rofi -dmenu \
    -p "󰤨  Wi-Fi" \
    -theme ~/.config/rofi/wifi.rasi)

[ -z "$selected" ] && exit 0

ssid=$(echo "$selected" | sed 's/^...//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

nmcli connection up "$ssid" 2>/dev/null || \
nmcli device wifi connect "$ssid"
