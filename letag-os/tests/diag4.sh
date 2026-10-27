E="DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000"
pkill -x nm-applet; sleep 1
sudo -u letag env $E nohup nm-applet > /tmp/nm.log 2>&1 &
sleep 20; cat /tmp/nm.log
sudo -u letag env $E xprop -root | grep -i -E 'SYSTEM_TRAY|_NET_SUPPORTING' | head
echo "=== FIN-DIAG4"
