#!/bin/sh
# Néo OS — vérifications automatiques d'un système démarré (live ou installé).
# À lancer en administrateur, en VM comme sur le HP Z200 :
#   sudo sh verifier-systeme.sh            (rapport à l'écran)
#   sudo sh verifier-systeme.sh > rapport.txt
# Chaque ligne commence par OK, ÉCHEC ou INFO. Ne modifie rien.
set -u

ok=0; echec=0
verif() { # description, commande (succès attendu)
	if sh -c "$2" >/dev/null 2>&1; then echo "OK     $1"; ok=$((ok + 1))
	else echo "ÉCHEC  $1"; echec=$((echec + 1)); fi
}
info() { echo "INFO   $1"; }

echo "=== Néo OS — vérification du $(date '+%d/%m/%Y %H:%M') ==="
info "Système : $(. /etc/os-release; echo "$PRETTY_NAME")"
info "Noyau : $(uname -r)"
info "Processeur : $(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)"
info "Démarrage : $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)$([ -d /run/live/medium ] && echo ' — session live')"
info "Carte graphique : $(lspci 2>/dev/null | grep -Ei 'vga|3d' | cut -d: -f3- | tr '\n' ' ')"
info "Pilote noyau graphique : $(for d in /sys/class/drm/card*/device/driver; do basename "$(readlink -f "$d")"; done 2>/dev/null | sort -u | tr '\n' ' ')"
info "Ligne de commande : $(cat /proc/cmdline)"

echo "--- Processeur"
if grep -qw avx /proc/cpuinfo; then
	info "Le processeur a AVX (ce n'est pas un i5-650 / Westmere)"
else
	verif "Fonctionne sans AVX (comme l'i5-650)" "true"
fi
verif "SSE4.2 présent (x86-64-v2)" "grep -qw sse4_2 /proc/cpuinfo"

echo "--- Services"
verif "Aucun service en échec" "[ -z \"\$(systemctl --failed --no-legend --plain)\" ]"
systemctl --failed --no-legend --plain 2>/dev/null | sed 's/^/       échec : /'
verif "earlyoom actif" "systemctl is-active earlyoom"
verif "LightDM actif" "systemctl is-active lightdm"
verif "NetworkManager actif" "systemctl is-active NetworkManager"
verif "NetworkManager-wait-online désactivé" "! systemctl is-enabled NetworkManager-wait-online"
verif "Minuteurs de mise à jour actifs" "systemctl is-active apt-daily.timer && systemctl is-active apt-daily-upgrade.timer"
verif "Mises à jour de sécurité automatiques configurées" "apt-config dump | grep -q 'APT::Periodic::Unattended-Upgrade \"1\"'"
verif "Pas de Bluetooth / CUPS / Avahi / ModemManager" "! systemctl list-unit-files bluetooth.service cups.service avahi-daemon.service ModemManager.service | grep -q enabled"

echo "--- Mémoire"
verif "zram actif en swap" "grep -q zram /proc/swaps"
verif "Caches d'icônes présents (Papirus, Néo)" "[ -f /usr/share/icons/Papirus/icon-theme.cache ] && [ -f /usr/share/icons/Neo/icon-theme.cache ]"
verif "Cache des polices présent" "ls /var/cache/fontconfig/*.cache-* "
verif "zram compressé en zstd" "grep -q '\[zstd\]' /sys/block/zram0/comp_algorithm"
info "Swap : $(awk 'NR>1 {printf "%s %d Mo prio %s ; ", $1, $3/1024, $5}' /proc/swaps)"
verif "vm.swappiness = 150" "[ \"\$(sysctl -n vm.swappiness)\" = 150 ]"
verif "vm.page-cluster = 0" "[ \"\$(sysctl -n vm.page-cluster)\" = 0 ]"
verif "vm.dirty_ratio = 10" "[ \"\$(sysctl -n vm.dirty_ratio)\" = 10 ]"

echo "--- Disque"
for d in /sys/block/sd?; do
	[ -e "$d" ] || continue
	n=$(basename "$d")
	if [ "$(cat "$d/queue/rotational")" = 1 ]; then
		verif "Ordonnanceur BFQ sur $n (rotatif)" "grep -q '\[bfq\]' $d/queue/scheduler"
	else
		info "$n non rotatif : ordonnanceur $(cat "$d/queue/scheduler")"
	fi
done
if [ ! -d /run/live/medium ]; then
	verif "Racine montée en noatime" "findmnt -no OPTIONS / | grep -q noatime"
	verif "Dépôts Debian en HTTPS avec sécurité" "grep -rqs 'https://security.debian.org' /etc/apt/sources.list /etc/apt/sources.list.d/"
	verif "Entrées GRUB de dépannage" "grep -q 'Néo OS — dépannage' /boot/grub/grub.cfg"
	verif "Outils live retirés (calamares, live-boot)" "! dpkg -s calamares && ! dpkg -s live-boot"
fi

echo "--- Bureau et identité"
verif "Thèmes Neo-Clair et Neo-Sombre présents" "[ -f /usr/share/themes/Neo-Clair/gtk-3.0/gtk.gresource ] && [ -f /usr/share/themes/Neo-Sombre/gtk-3.0/gtk.gresource ]"
verif "Icônes Néo (héritent de Papirus)" "grep -q 'Inherits=Papirus-Light' /usr/share/icons/Neo/index.theme"
verif "Rendu SVG des icônes (librsvg)" "ls /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/ | grep -q svg"
verif "Police Inter" "fc-list | grep -qi 'Inter'"
verif "Nom du système : Néo OS" "grep -q '^NAME=\"Néo OS\"' /etc/os-release"
verif "Locale française générée" "locale -a | grep -qi fr_FR.utf8"
verif "Navigateur maintenu (Firefox ESR)" "firefox-esr --version"
info "Firefox : $(firefox-esr --version 2>/dev/null)"
verif "Pilote Xorg nouveau installé" "[ -f /usr/lib/xorg/modules/drivers/nouveau_drv.so ]"
verif "Pilotes de secours vesa / fbdev installés" "[ -f /usr/lib/xorg/modules/drivers/vesa_drv.so ] && [ -f /usr/lib/xorg/modules/drivers/fbdev_drv.so ]"
if [ -f /var/log/Xorg.0.log ]; then
	info "Xorg : pilote(s) chargé(s) : $(grep -oE 'LoadModule: \"(nouveau|modesetting|vesa|fbdev|qxl)\"' /var/log/Xorg.0.log | cut -d'"' -f2 | sort -u | tr '\n' ' ')"
fi
utilisateur=$(loginctl list-sessions --no-legend 2>/dev/null | awk '$3 != "lightdm" {print $3; exit}')
if [ -n "$utilisateur" ]; then
	info "Session graphique de : $utilisateur"
	pgrep -u "$utilisateur" -x xfce4-panel >/dev/null && verif "Barre des tâches XFCE lancée" "true" || verif "Barre des tâches XFCE lancée" "false"
	pgrep -u "$utilisateur" -x xfwm4 >/dev/null && verif "Gestionnaire de fenêtres xfwm4 lancé" "true" || verif "Gestionnaire de fenêtres xfwm4 lancé" "false"
	pgrep -u "$utilisateur" -x xfdesktop >/dev/null && verif "Bureau xfdesktop lancé" "true" || verif "Bureau xfdesktop lancé" "false"
fi

echo "--- Fonctions Néo"
for o in neo-taches neo-diagnostic neo-animations neo-discord neo-menu-session neo-raccourcis neo-erreur neo-centre; do
	verif "Outil $o présent" "[ -x /usr/local/bin/$o ]"
done
verif "Bibliothèques Python (psutil, Cairo)" "python3 -c 'import psutil, gi; gi.require_foreign(\"cairo\")'"
verif "Palette Néo dans le thème clair (#7DCDAD, #0F2B5B)" "grep -q '#7DCDAD' /usr/share/themes/Neo-Clair/gtk-3.0/gtk.css && grep -q '#0F2B5B' /usr/share/themes/Neo-Clair/gtk-3.0/gtk.css"
verif "Thème des notifications Néo" "[ -f /usr/share/themes/Neo-Clair/xfce-notify-4.0/gtk.css ]"
verif "Décorations de fenêtres Néo (xfwm4)" "[ -f /usr/share/themes/Neo-Sombre/xfwm4/themerc ]"
verif "Pages d'aide (guide, raccourcis, codes d'erreur)" "[ -f /usr/share/doc/neo/raccourcis.html ] && [ -f /usr/share/doc/neo/codes-erreur.html ]"
verif "Diagnostic en mode texte" "timeout 120 /usr/local/bin/neo-diagnostic --texte | grep -q 'Fin du rapport'"
verif "Pas de démarrage automatique de picom hors neo-animations" "grep -q 'Hidden=true' /etc/xdg/neo/autostart/picom.desktop"
if [ ! -d /run/live/medium ]; then
	verif "Thème GRUB Néo" "[ -f /boot/grub/themes/neo/theme.txt ] && grep -q 'themes/neo/theme.txt' /boot/grub/grub.cfg"
fi
if dpkg -s discord >/dev/null 2>&1; then
	info "Discord : $(dpkg-query -W -f '${Version}' discord) (paquet officiel)"
else
	info "Discord : non installé (menu → Installer Discord)"
fi
if [ -n "$utilisateur" ]; then
	uidu=$(id -u "$utilisateur")
	xq() { sudo -u "$utilisateur" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uidu/bus" xfconf-query "$@" 2>/dev/null; }
	v=$(xq -c xfce4-keyboard-shortcuts -p '/commands/custom/<Primary><Shift>Escape')
	verif "Raccourci Ctrl+Maj+Échap → gestionnaire des tâches ($v)" "[ '$v' = neo-taches ]"
	for k in '/commands/custom/<Primary><Alt>Delete' '/commands/custom/Super_L' '/commands/custom/<Super>e' '/commands/custom/<Super>r' '/commands/custom/<Super>i' '/commands/custom/<Super>l' '/xfwm4/custom/<Super>d' '/xfwm4/custom/<Super>Left' '/xfwm4/custom/<Super>Right' '/xfwm4/custom/<Super>Up' '/xfwm4/custom/<Super>Down' '/xfwm4/custom/<Alt>Tab' '/xfwm4/custom/<Alt>F4'; do
		v=$(xq -c xfce4-keyboard-shortcuts -p "$k")
		[ -n "$v" ] && verif "Raccourci ${k##*/} → $v" "true" || verif "Raccourci ${k##*/} défini" "false"
	done
	v=$(xq -c thunar -p /last-location-bar)
	verif "Explorateur : barre d'adresse modifiable ($v)" "[ '$v' = ThunarLocationEntry ]"
	info "Animations : $(sudo -u "$utilisateur" HOME="$(getent passwd "$utilisateur" | cut -d: -f6)" neo-animations etat) — picom $(pgrep -u "$utilisateur" -x picom >/dev/null && echo actif || echo arrêté)"
fi

echo "--- Mesure"
/usr/local/bin/neo-mesure --detail 2>/dev/null | sed 's/^/       /'
echo "=== Résultat : $ok OK, $echec ÉCHEC ==="
