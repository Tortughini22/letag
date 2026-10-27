E="DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000"
sudo -u letag env $E xfce4-panel -r; sleep 25
sudo -u letag env $E xfconf-query -c xfce4-panel -p /plugins/plugin-5 -lv
echo "=== FIN-DIAG8"
