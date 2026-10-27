E="DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
sudo -u letag env $E xfconf-query -c xfce4-panel -p /plugins/plugin-5/icon-size -r
sudo -u letag env $E xfconf-query -c xfce4-panel -p /plugins/plugin-5/square-icons -r
sudo -u letag env $E xfce4-panel -r
echo "=== FIN-DIAG3"
