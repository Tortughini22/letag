U=letag
sudo -u $U DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus xfconf-query -c xfce4-panel -p /plugins/plugin-5 -lv
nmcli -t device status
sudo -u $U DISPLAY=:0 xprop -root _NET_SYSTEM_TRAY_S0 2>&1 | head -2
journalctl -b --no-pager _COMM=nm-applet | tail -5
echo "=== FIN-DIAG2"
