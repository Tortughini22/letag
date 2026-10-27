#!/bin/sh
# Letag OS — vérifications automatiques d'un système démarré (live ou installé).
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

echo "=== Letag OS — vérification du $(date '+%d/%m/%Y %H:%M') ==="
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
verif "Caches d'icônes présents (Papirus, Letag)" "[ -f /usr/share/icons/Papirus/icon-theme.cache ] && [ -f /usr/share/icons/Letag/icon-theme.cache ]"
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
	verif "Entrées GRUB de dépannage" "grep -q 'Letag OS — dépannage' /boot/grub/grub.cfg"
	verif "Outils live retirés (calamares, live-boot)" "! dpkg -s calamares && ! dpkg -s live-boot"
fi

echo "--- Bureau et identité"
verif "Thèmes Letag-Clair et Letag-Sombre présents" "[ -f /usr/share/themes/Letag-Clair/gtk-3.0/gtk.gresource ] && [ -f /usr/share/themes/Letag-Sombre/gtk-3.0/gtk.gresource ]"
verif "Icônes Letag (héritent de Papirus)" "grep -q 'Inherits=Papirus' /usr/share/icons/Letag/index.theme"
verif "Rendu SVG des icônes (librsvg)" "ls /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/ | grep -q svg"
verif "Police Inter" "fc-list | grep -qi 'Inter'"
verif "Nom du système : Letag OS" "grep -q '^NAME=\"Letag OS\"' /etc/os-release"
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

echo "--- Mesure"
/usr/local/bin/letag-mesure --detail 2>/dev/null | sed 's/^/       /'
echo "=== Résultat : $ok OK, $echec ÉCHEC ==="
