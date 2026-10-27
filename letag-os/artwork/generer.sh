#!/bin/sh
# Letag OS — génère les éléments visuels à partir des sources :
#   * PNG (fonds d'écran, logos, écran de démarrage, GRUB, Calamares) depuis artwork/src/*.svg ;
#   * thèmes GTK/xfwm4 Letag-Clair et Letag-Sombre dérivés du paquet Debian arc-theme ;
#   * thèmes d'icônes Letag et Letag-Sombre (héritent de Papirus) ;
#   * guide HTML embarqué, depuis docs/*.md.
# À exécuter sur Debian 13 (le chroot de construction). Dépendances :
#   librsvg2-bin fonts-inter python3-pil python3-markdown libglib2.0-bin libglib2.0-dev-bin
set -eu

ICI=$(dirname "$(readlink -f "$0")")
PROJET=$(dirname "$ICI")
SRC="$ICI/src"
CFG="$PROJET/live-build/config"
INC="$CFG/includes.chroot"
L="$INC/usr/share/letag"

png() { rsvg-convert -w "$2" -h "$3" "$SRC/$1" -o "$4"; }

echo "== Images"
mkdir -p "$L/fonds" "$L/logo" "$L/grub" "$CFG/bootloaders/syslinux_common" "$CFG/bootloaders/grub-pc" \
	"$INC/etc/calamares/branding/letag" "$INC/usr/share/backgrounds/letag"
png fond-clair.svg 1920 1080 "$L/fonds/letag-clair.png"
png fond-sombre.svg 1920 1080 "$L/fonds/letag-sombre.png"
cp "$L/fonds/letag-sombre.png" "$L/fonds/letag-connexion.png"
cp "$SRC/fond-clair.svg" "$SRC/fond-sombre.svg" "$INC/usr/share/backgrounds/letag/"
cp "$SRC/logo.svg" "$SRC/symbole.svg" "$L/logo/"
png logo.svg 256 256 "$L/logo/logo-256.png"
png logo.svg 128 128 "$L/logo/avatar.png"
png fond-grub.svg 1024 768 "$L/grub/fond.png"
png splash-isolinux.svg 640 480 "$CFG/bootloaders/syslinux_common/splash.png"
png fond-grub.svg 800 600 "$CFG/bootloaders/grub-pc/splash.png"
B="$INC/etc/calamares/branding/letag"
png logo.svg 128 128 "$B/logo.png"
png accueil.svg 520 300 "$B/accueil.png"
for i in 1 2 3; do png "diapo$i.svg" 800 440 "$B/diapo$i.png"; done

echo "== Thèmes d'icônes"
for t in Letag Letag-Sombre; do
	# Papirus-Light : icônes de barre foncées, lisibles sur la barre claire.
	parent=Papirus-Light; [ "$t" = Letag-Sombre ] && parent=Papirus-Dark
	d="$INC/usr/share/icons/$t"
	rm -rf "$d"; mkdir -p "$d/scalable/apps"
	cat > "$d/index.theme" <<EOT
[Icon Theme]
Name=$t
Comment=Icônes Letag OS (logo et outils), le reste vient de $parent
Inherits=$parent,Adwaita,hicolor
Directories=scalable/apps

[scalable/apps]
Size=48
MinSize=16
MaxSize=512
Type=Scalable
Context=Applications
EOT
	for n in letag-menu start-here distributor-logo debian-logo letag; do cp "$SRC/logo.svg" "$d/scalable/apps/$n.svg"; done
	cp "$SRC/centre.svg" "$d/scalable/apps/letag-centre.svg"
	for n in letag-installer install-debian calamares; do cp "$SRC/installer.svg" "$d/scalable/apps/$n.svg"; done
done

echo "== Thèmes GTK (dérivés d'Arc)"
TMP=$(mktemp -d)
( cd "$TMP" && apt-get download arc-theme >/dev/null )
dpkg-deb -x "$TMP"/arc-theme_*.deb "$TMP/arc"
rm -rf "$INC/usr/share/themes/Letag-Clair" "$INC/usr/share/themes/Letag-Sombre"
python3 "$ICI/recolorer-arc.py" "$TMP/arc/usr/share/themes" "$INC/usr/share/themes"
for t in Letag-Clair Letag-Sombre; do
	cp "$TMP/arc/usr/share/doc/arc-theme/copyright" "$INC/usr/share/themes/$t/COPYRIGHT-arc-theme"
done
rm -rf "$TMP"

echo "== Guide HTML"
mkdir -p "$INC/usr/share/doc/letag"
python3 "$PROJET/scripts/doc-html.py" "$PROJET/docs" "$INC/usr/share/doc/letag/guide.html"
echo "Éléments générés."
