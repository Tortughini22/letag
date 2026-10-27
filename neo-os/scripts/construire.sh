#!/bin/sh
# Néo OS — construction reproductible de l'image ISO.
#
#   sudo ./scripts/construire.sh
#
# Sur Debian 13 avec live-build installé, la construction se fait directement.
# Sur un autre système Linux (Ubuntu, Fedora, Debian plus ancienne…), un chroot
# Debian 13 de construction est créé avec debootstrap puis utilisé.
#
# Variables facultatives :
#   NEO_BUILDER          emplacement du chroot de construction (défaut /var/tmp/neo-builder)
#   NEO_APT_PROXY        proxy HTTP pour apt pendant la construction (ex. apt-cacher-ng)
#   NEO_MIRROR           miroir Debian utilisé pendant la construction
#   NEO_SECURITY_MIRROR  miroir sécurité utilisé pendant la construction
# L'image finale utilise toujours https://deb.debian.org et https://security.debian.org.
#
# Résultat : sortie/neo-os-1.0-amd64.iso (+ .sha256)
set -eu

PROJET=$(dirname "$(dirname "$(readlink -f "$0")")")
[ "$(id -u)" -eq 0 ] || { echo "À lancer en administrateur (sudo)." >&2; exit 1; }

DEPS="live-build librsvg2-bin fonts-inter python3-pil python3-markdown libglib2.0-bin libglib2.0-dev-bin ca-certificates"

est_trixie() {
	[ -r /etc/os-release ] && . /etc/os-release && [ "${ID:-}" = debian ] && [ "${VERSION_ID:-}" = 13 ]
}

if ! est_trixie || [ -n "${NEO_FORCER_CHROOT:-}" ]; then
	[ -z "${NEO_DANS_BUILDER:-}" ] || { echo "Le chroot n'est pas une Debian 13." >&2; exit 1; }
	command -v debootstrap >/dev/null || { echo "Installez debootstrap (et debian-archive-keyring)." >&2; exit 1; }
	B="${NEO_BUILDER:-/var/tmp/neo-builder}"
	if [ ! -x "$B/usr/bin/lb" ]; then
		echo "== Création du chroot de construction Debian 13 dans $B"
		http_proxy="${NEO_APT_PROXY:-}" debootstrap --variant=minbase \
			--include="$(echo $DEPS | tr ' ' ',')" trixie "$B" "${NEO_MIRROR:-https://deb.debian.org/debian}"
	fi
	mkdir -p "$B/projet"
	mountpoint -q "$B/projet" || mount --bind "$PROJET" "$B/projet"
	for m in proc sys dev dev/pts; do mountpoint -q "$B/$m" || mount --bind "/$m" "$B/$m"; done
	cp -L /etc/resolv.conf "$B/etc/resolv.conf" 2>/dev/null || true
	set +e
	chroot "$B" /usr/bin/env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin LANG=C.UTF-8 TERM="${TERM:-dumb}" \
		NEO_DANS_BUILDER=1 NEO_APT_PROXY="${NEO_APT_PROXY:-}" \
		NEO_MIRROR="${NEO_MIRROR:-}" NEO_SECURITY_MIRROR="${NEO_SECURITY_MIRROR:-}" \
		http_proxy="${NEO_APT_PROXY:-}" \
		/bin/sh /projet/scripts/construire.sh
	rc=$?
	set -e
	for m in dev/pts dev sys proc projet; do umount "$B/$m" 2>/dev/null || umount -l "$B/$m" || true; done
	exit $rc
fi

# --- Construction sur Debian 13 -------------------------------------------
manque=""
for p in $DEPS; do dpkg -s "$p" >/dev/null 2>&1 || manque="$manque $p"; done
if [ -n "$manque" ]; then
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y $manque
fi

# Horodatage reproductible : date du dernier commit, sinon date fixe.
if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
	SOURCE_DATE_EPOCH=$(git -C "$PROJET" log -1 --format=%ct 2>/dev/null || echo 1767225600)
fi
export SOURCE_DATE_EPOCH

echo "== Génération des éléments visuels"
sh "$PROJET/artwork/generer.sh"

echo "== Construction de l'image (live-build) — compter 30 à 90 minutes"
cd "$PROJET/live-build"
lb clean >/dev/null 2>&1 || true
export NEO_APT_PROXY="${NEO_APT_PROXY:-}" NEO_MIRROR="${NEO_MIRROR:-}" NEO_SECURITY_MIRROR="${NEO_SECURITY_MIRROR:-}"
lb config
lb build

ISO=$(ls -1 ./*.iso 2>/dev/null | head -n 1)
[ -n "$ISO" ] || { echo "Échec : aucune image produite, voir live-build/build.log" >&2; exit 1; }
mkdir -p "$PROJET/sortie"
mv "$ISO" "$PROJET/sortie/neo-os-1.0-amd64.iso"
cd "$PROJET/sortie"
sha256sum neo-os-1.0-amd64.iso > neo-os-1.0-amd64.iso.sha256
ls -lh neo-os-1.0-amd64.iso
echo "Image prête : $PROJET/sortie/neo-os-1.0-amd64.iso"
