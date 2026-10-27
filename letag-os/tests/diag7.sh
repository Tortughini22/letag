E="DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000"
cat /tmp/nm.log
sudo -u letag env $E busctl --user list 2>/dev/null | grep -iE 'StatusNotifier|appindicator|nm-applet' 
sudo -u letag env $E xwininfo -root -tree | grep -iE 'nm-applet|tray' | head -5
echo "=== FIN-DIAG7"
