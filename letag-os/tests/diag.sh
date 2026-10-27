U=letag
echo "=== XDG_CONFIG_DIRS (session) : $(tr '\0' '\n' < /proc/$(pgrep -u $U -x xfce4-panel)/environ | grep XDG_CONFIG_DIRS)"
echo "=== panel rc :"; ls -la /home/$U/.config/xfce4/panel/ 2>&1; cat /home/$U/.config/xfce4/panel/docklike-3.rc 2>&1
echo "=== nm-applet :"; pgrep -a nm-applet; ls /etc/xdg/autostart | tr '\n' ' '
echo; echo "=== systray :"; xfconf-query -c xfce4-panel -lv 2>/dev/null | head -0
echo "=== os-release :"; ls -la /etc/os-release; head -2 /etc/os-release; dpkg-divert --list | grep os-release
echo "=== xfce4-panel.xml :"; sed -n 1,200p /home/$U/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml 2>&1 | grep -E 'plugin-[0-9]+"|systray|known|hidden' | head -30
echo "=== journal nm-applet/panel :"; journalctl -b --no-pager 2>/dev/null | grep -iE 'nm-applet|docklike|systray|wrapper' | tail -15
echo "=== FIN-DIAG"
