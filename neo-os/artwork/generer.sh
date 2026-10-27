#!/bin/sh
# Néo OS — génère les éléments visuels à partir des sources :
#   * PNG (fonds d'écran, logos, écran de démarrage, GRUB, Calamares) depuis artwork/src/*.svg ;
#   * thèmes GTK/xfwm4/notifications Neo-Clair et Neo-Sombre (palette Néo, base arc-theme)
#     et le tableau des contrastes docs/CONTRASTE.md ;
#   * thème GRUB du système installé ;
#   * thèmes d'icônes Néo et Neo-Sombre (héritent de Papirus) ;
#   * guide HTML embarqué, depuis docs/*.md.
# À exécuter sur Debian 13 (le chroot de construction). Dépendances :
#   librsvg2-bin fonts-inter python3-pil python3-markdown libglib2.0-bin libglib2.0-dev-bin
set -eu
# Pas de fichiers .pyc dans includes.chroot (ils finiraient dans l'image).
export PYTHONDONTWRITEBYTECODE=1

ICI=$(dirname "$(readlink -f "$0")")
PROJET=$(dirname "$ICI")
SRC="$ICI/src"
CFG="$PROJET/live-build/config"
INC="$CFG/includes.chroot"
L="$INC/usr/share/neo"

png() { rsvg-convert -w "$2" -h "$3" "$SRC/$1" -o "$4"; }

echo "== Images"
mkdir -p "$L/fonds" "$L/logo" "$L/grub" "$CFG/bootloaders/syslinux_common" "$CFG/bootloaders/grub-pc" \
	"$INC/etc/calamares/branding/neo" "$INC/usr/share/backgrounds/neo"
png fond-clair.svg 1920 1080 "$L/fonds/neo-clair.png"
png fond-sombre.svg 1920 1080 "$L/fonds/neo-sombre.png"
cp "$L/fonds/neo-sombre.png" "$L/fonds/neo-connexion.png"
cp "$SRC/fond-clair.svg" "$SRC/fond-sombre.svg" "$INC/usr/share/backgrounds/neo/"
cp "$SRC/logo.svg" "$SRC/symbole.svg" "$L/logo/"
png logo.svg 256 256 "$L/logo/logo-256.png"
png logo.svg 128 128 "$L/logo/avatar.png"
png fond-grub.svg 1024 768 "$L/grub/fond.png"
png splash-isolinux.svg 640 480 "$CFG/bootloaders/syslinux_common/splash.png"
png fond-grub.svg 800 600 "$CFG/bootloaders/grub-pc/splash.png"
B="$INC/etc/calamares/branding/neo"
png logo.svg 128 128 "$B/logo.png"
png accueil.svg 520 300 "$B/accueil.png"
for i in 1 2 3; do png "diapo$i.svg" 800 440 "$B/diapo$i.png"; done

echo "== Thèmes d'icônes"
for t in Neo Neo-Sombre; do
	# Papirus-Light : icônes de barre foncées, lisibles sur la barre claire.
	parent=Papirus-Light; [ "$t" = Neo-Sombre ] && parent=Papirus-Dark
	d="$INC/usr/share/icons/$t"
	rm -rf "$d"; mkdir -p "$d/scalable/apps"
	cat > "$d/index.theme" <<EOT
[Icon Theme]
Name=$t
Comment=Icônes Néo OS (logo et outils), le reste vient de $parent
Inherits=$parent,Adwaita,hicolor
Directories=scalable/apps

[scalable/apps]
Size=48
MinSize=16
MaxSize=512
Type=Scalable
Context=Applications
EOT
	for n in neo-menu start-here distributor-logo debian-logo neo; do cp "$SRC/logo.svg" "$d/scalable/apps/$n.svg"; done
	cp "$SRC/centre.svg" "$d/scalable/apps/neo-centre.svg"
	cp "$SRC/taches.svg" "$d/scalable/apps/neo-taches.svg"
	cp "$SRC/diagnostic.svg" "$d/scalable/apps/neo-diagnostic.svg"
	cp "$SRC/raccourcis.svg" "$d/scalable/apps/neo-raccourcis.svg"
	for n in neo-installer install-debian calamares; do cp "$SRC/installer.svg" "$d/scalable/apps/$n.svg"; done
done

echo "== Thème GRUB"
G="$INC/boot/grub/themes/neo"
rm -rf "$G"; mkdir -p "$G"
png fond-grub.svg 1024 768 "$G/fond.png"
python3 - "$G" <<'EOT'
import sys
from PIL import Image, ImageDraw
d = sys.argv[1]
menthe = (0x7D, 0xCD, 0xAD, 255)
Image.new("RGBA", (8, 30), menthe).save(d + "/select_c.png")
for cote in ("w", "e"):
    im = Image.new("RGBA", (8, 30), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle((0 if cote == "w" else -8, 0, 15 if cote == "w" else 7, 29), radius=7, fill=menthe)
    im.save("%s/select_%s.png" % (d, cote))
EOT
cat > "$G/theme.txt" <<'EOT'
# Néo OS — thème GRUB (palette Néo)
title-text: ""
desktop-image: "fond.png"
desktop-color: "#0F2B5B"
terminal-font: "Unifont Regular 16"
terminal-box: ""

+ boot_menu {
	left = 12%
	width = 76%
	top = 18%
	height = 60%
	item_font = "Unifont Regular 16"
	selected_item_font = "Unifont Regular 16"
	item_color = "#FEF9EB"
	selected_item_color = "#0F2B5B"
	item_height = 30
	item_padding = 10
	item_spacing = 6
	icon_width = 0
	icon_height = 0
	item_icon_space = 0
	selected_item_pixmap_style = "select_*.png"
}

+ label {
	id = "__timeout__"
	top = 100%-70
	left = 0
	width = 100%
	height = 20
	align = "center"
	color = "#C6EBD4"
	font = "Unifont Regular 16"
	text = "Démarrage automatique dans %d s"
}

+ label {
	top = 100%-42
	left = 0
	width = 100%
	height = 20
	align = "center"
	color = "#91D2BC"
	font = "Unifont Regular 16"
	text = "Entrée : démarrer   ·   e : modifier   ·   Échap : menu précédent"
}
EOT

echo "== Thèmes GTK, xfwm4 et notifications (palette Néo)"
TMP=$(mktemp -d)
( cd "$TMP" && apt-get download arc-theme >/dev/null )
dpkg-deb -x "$TMP"/arc-theme_*.deb "$TMP/arc"
rm -rf "$INC/usr/share/themes/Neo-Clair" "$INC/usr/share/themes/Neo-Sombre"
python3 "$ICI/generer-themes.py" "$TMP/arc/usr/share/themes" "$INC/usr/share/themes" "$PROJET/docs/CONTRASTE.md"
for t in Neo-Clair Neo-Sombre; do
	cp "$TMP/arc/usr/share/doc/arc-theme/copyright" "$INC/usr/share/themes/$t/COPYRIGHT-arc-theme"
done
rm -rf "$TMP"

echo "== Guide HTML"
mkdir -p "$INC/usr/share/doc/neo"
python3 "$PROJET/scripts/doc-html.py" "$PROJET/docs" "$INC/usr/share/doc/neo"
echo "Éléments générés."
