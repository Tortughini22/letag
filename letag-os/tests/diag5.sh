E="DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000"
sudo -u letag env $E letag-effets equilibre
sleep 5
sudo -u letag env $E xwininfo -root -tree | grep -i -E 'nm-applet|networkmanager|systray|tray' | head
echo "=== FIN-DIAG5"
