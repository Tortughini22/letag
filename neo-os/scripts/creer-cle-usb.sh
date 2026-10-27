#!/bin/sh
# Néo OS — copie l'image ISO sur une clé USB (TOUT le contenu de la clé est remplacé).
# Sécurités : refuse un disque non amovible ou monté comme système, affiche le
# modèle et la taille, exige de retaper le nom du périphérique.
# Usage : sudo ./scripts/creer-cle-usb.sh neo-os-1.0-amd64.iso /dev/sdX
set -eu

ISO="${1:-}"; CLE="${2:-}"
[ -f "$ISO" ] && [ -n "$CLE" ] || { echo "Usage : sudo $0 <image.iso> </dev/sdX>" >&2; exit 2; }
[ "$(id -u)" -eq 0 ] || { echo "À lancer avec sudo." >&2; exit 1; }
[ -b "$CLE" ] || { echo "$CLE n'est pas un périphérique bloc." >&2; exit 1; }
[ "$(lsblk -dno TYPE "$CLE")" = disk ] || { echo "Indiquez le disque entier (ex. /dev/sdb), pas une partition." >&2; exit 1; }

nom=$(basename "$CLE")
if [ "$(cat "/sys/block/$nom/removable" 2>/dev/null)" != 1 ] && [ "$(lsblk -dno TRAN "$CLE")" != usb ]; then
	echo "Refus : $CLE n'est ni amovible ni USB (disque interne ?)." >&2; exit 1
fi
if lsblk -no MOUNTPOINT "$CLE" | grep -qE '^/(boot.*)?$'; then
	echo "Refus : $CLE contient le système en cours d'utilisation." >&2; exit 1
fi
taille_iso=$(stat -c %s "$ISO"); taille_cle=$(blockdev --getsize64 "$CLE")
[ "$taille_cle" -gt "$taille_iso" ] || { echo "Clé trop petite." >&2; exit 1; }

echo "Périphérique : $CLE — $(lsblk -dno MODEL,SIZE "$CLE")"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$CLE"
echo
echo "TOUT le contenu de $CLE va être effacé."
printf "Retapez « %s » pour confirmer : " "$CLE"
read -r reponse
[ "$reponse" = "$CLE" ] || { echo "Annulé."; exit 1; }

for p in $(lsblk -lnpo NAME "$CLE" | tail -n +2); do umount "$p" 2>/dev/null || true; done
dd if="$ISO" of="$CLE" bs=4M conv=fsync status=progress
sync
echo "Clé prête. Démarrez le HP Z200 avec F9 pour choisir la clé."
