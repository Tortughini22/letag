E="DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000"
sudo -u letag env $E letag-effets minimal
pkill -x nm-applet; sleep 1
sudo -u letag env $E nohup nm-applet --indicator > /tmp/nm.log 2>&1 &
sleep 20
echo "=== FIN-DIAG6"
