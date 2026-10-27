#!/bin/sh
# Letag OS — tests en machine virtuelle QEMU, au plus près du HP Z200 :
#   processeur émulé « Westmere » (même génération que le Core i5-650 :
#   SSE4.2, AES-NI, PAS d'AVX), 4 Go de RAM, 2 cœurs / 4 threads, BIOS
#   (SeaBIOS, chipset Q35/ICH9 proche du Q57 du Z200), disque SATA de 320 Go
#   (fichier creux), port série journalisé.
#
# Usage :
#   scripts/tester-vm.sh live      [image.iso]   démarre la session d'essai
#   scripts/tester-vm.sh installer [image.iso]   idem, avec un disque de 320 Go à installer
#   scripts/tester-vm.sh disque                  démarre le système installé sur ce disque
#
# Variables : LETAG_VM_DIR (dossier de travail, défaut tests/vm),
#             LETAG_VM_AFFICHAGE (none|gtk|vnc=:1, défaut none),
#             LETAG_VM_OPTIONS (paramètres noyau ajoutés, ex. « letag.rapport »).
# Sans KVM, QEMU émule le processeur (TCG) : tout est 10 à 30 fois plus lent
# que sur le vrai matériel. Les durées mesurées en VM ne valent donc PAS pour le HP.
# Commandes de contrôle : socket QMP $LETAG_VM_DIR/qmp.sock (captures d'écran,
# clavier), voir scripts/vm-qmp.py.
set -eu

PROJET=$(dirname "$(dirname "$(readlink -f "$0")")")
MODE="${1:-live}"
ISO="${2:-$PROJET/sortie/letag-os-1.0-amd64.iso}"
DIR="${LETAG_VM_DIR:-$PROJET/tests/vm}"
mkdir -p "$DIR"
DISQUE="$DIR/disque-320G.qcow2"

ACCEL="-accel tcg,thread=multi"
[ -w /dev/kvm ] && ACCEL="-accel kvm"

set -- -machine q35 $ACCEL -cpu Westmere -smp 4,cores=2,threads=2 -m 4096 \
	-device qxl-vga,vgamem_mb=32 -display "${LETAG_VM_AFFICHAGE:-none}" \
	-netdev user,id=net0 -device e1000,netdev=net0 \
	-device ich9-usb-ehci1,id=usb -device usb-tablet,bus=usb.0 \
	-serial "file:$DIR/serie-$MODE.log" \
	-qmp "unix:$DIR/qmp.sock,server=on,wait=off" \
	-rtc base=localtime

case "$MODE" in
	live|installer)
		[ -f "$ISO" ] || { echo "Image introuvable : $ISO" >&2; exit 1; }
		if [ "$MODE" = installer ] && [ ! -f "$DISQUE" ]; then
			qemu-img create -f qcow2 "$DISQUE" 320G
		fi
		set -- "$@" -drive "file=$ISO,media=cdrom,if=none,id=cd,readonly=on" -device ide-cd,drive=cd,bus=ide.0 -boot d
		if [ -n "${LETAG_VM_OPTIONS:-}" ]; then
			# Options noyau supplémentaires : on démarre directement le noyau de
			# l'ISO avec la ligne de commande de l'entrée « Essayer Letag OS ».
			xorriso -osirrox on -indev "$ISO" -extract /live/vmlinuz "$DIR/vmlinuz" \
				-extract /live/initrd.img "$DIR/initrd.img" -extract /isolinux/live.cfg "$DIR/live.cfg" >/dev/null 2>&1
			chmod u+w "$DIR"/vmlinuz "$DIR"/initrd.img "$DIR"/live.cfg
			ligne=$(awk '/append/ {sub(/^[ \t]*append[ \t]+/, ""); print; exit}' "$DIR/live.cfg")
			set -- "$@" -kernel "$DIR/vmlinuz" -initrd "$DIR/initrd.img" -append "$ligne console=tty0 console=ttyS0,115200 $LETAG_VM_OPTIONS"
		fi
		if [ "$MODE" = installer ]; then
			set -- "$@" -drive "file=$DISQUE,if=none,id=hd" -device ide-hd,drive=hd,bus=ide.1
		fi
		;;
	disque)
		[ -f "$DISQUE" ] || { echo "Pas de disque installé : lancez d'abord le mode installer." >&2; exit 1; }
		set -- "$@" -drive "file=$DISQUE,if=none,id=hd" -device ide-hd,drive=hd,bus=ide.0 -boot c
		;;
	*) echo "Usage : $0 live|installer|disque [image.iso]" >&2; exit 2 ;;
esac

echo "QEMU ($MODE) — journal série : $DIR/serie-$MODE.log"
exec qemu-system-x86_64 "$@"
