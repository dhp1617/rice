#!/bin/bash
# WiFi picker using rofi + nmcli — no terminal needed

# Get unique networks sorted by signal
NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list \
    | awk -F: '!seen[$1]++ && $1 != "" {print $1}' \
    | head -20)

[ -z "$NETWORKS" ] && { notify-send "WiFi" "No networks found"; exit 1; }

CURRENT=$(nmcli -t -f NAME connection show --active | head -1)

# Add "Disconnect" if connected
MENU="$NETWORKS"
[ -n "$CURRENT" ] && MENU="Disconnect current\n$NETWORKS"

CHOSEN=$(echo -e "$MENU" | rofi -dmenu -i -p "WiFi" \
    -theme-str 'window {width: 400px;} listview {lines: 10;}')

[ -z "$CHOSEN" ] && exit 0

if [ "$CHOSEN" = "Disconnect current" ]; then
    nmcli connection down "$CURRENT"
    notify-send "WiFi" "Disconnected"
    exit 0
fi

# Known network?
if nmcli connection show "$CHOSEN" &>/dev/null; then
    nmcli connection up "$CHOSEN" && notify-send "WiFi" "Connected to $CHOSEN"
else
    # New — prompt password
    PASS=$(rofi -dmenu -password -p "Password: $CHOSEN" -theme-str 'window {width: 400px;}')
    [ -z "$PASS" ] && exit 0
    if nmcli device wifi connect "$CHOSEN" password "$PASS"; then
        notify-send "WiFi" "Connected to $CHOSEN"
    else
        notify-send "WiFi" "Failed to connect"
    fi
fi
