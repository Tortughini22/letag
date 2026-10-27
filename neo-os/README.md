# Néo OS

Système d'exploitation léger, en français, pour **HP Z200 SFF** (Core i5-650, 4 Go DDR3, disque dur de 320 Go, Quadro FX 380 LP). Il repose sur **Debian 13 « trixie »** et **XFCE 4.20**.

Usages visés : navigation Internet, bureautique, vidéo, gestion de fichiers et programmation, avec la fluidité comme priorité.

- Choix techniques et vérifications matérielles : [docs/CHOIX-TECHNIQUES.md](docs/CHOIX-TECHNIQUES.md)
- Créer la clé USB et installer : [docs/INSTALLATION.md](docs/INSTALLATION.md)
- Utilisation, mises à jour, récupération : [docs/UTILISATION.md](docs/UTILISATION.md)
- Tests effectués et limites connues : [docs/TESTS.md](docs/TESTS.md)
- Raccourcis clavier : [docs/RACCOURCIS.md](docs/RACCOURCIS.md) · Codes d'erreur : [docs/CODES-ERREUR.md](docs/CODES-ERREUR.md) · Contrastes : [docs/CONTRASTE.md](docs/CONTRASTE.md)

## Arborescence

```
neo-os/
├── README.md
├── artwork/
│   ├── src/*.svg            logo, fonds clair/sombre, démarrage, GRUB, installateur
│   ├── generer-themes.py    thèmes GTK, xfwm4 et notifications Neo-Clair/Sombre
│   │                        (palette Néo, dérivés d'Arc) + rapport de contraste
│   └── generer.sh           produit PNG, thèmes, icônes et guide HTML
├── docs/                    documentation (le guide HTML embarqué en est issu)
│   └── captures/            captures d'écran des tests en machine virtuelle
├── live-build/              configuration live-build de l'image
│   ├── auto/config          options : Debian 13, BIOS+UEFI, zstd, français…
│   └── config/
│       ├── package-lists/   paquets (système, graphique, bureau, applications, live)
│       ├── hooks/normal/    locale, services, identité, polices, nettoyage
│       ├── bootloaders/     menus isolinux (BIOS) et GRUB (UEFI) Néo
│       └── includes.chroot/ fichiers copiés dans le système :
│           ├── etc/xdg/neo/           réglages XFCE par défaut (barre, thème, xfwm4…)
│           ├── etc/calamares/           installateur (aucune option présélectionnée)
│           ├── etc/sysctl.d, udev, systemd/zram-generator.conf, default/earlyoom
│           ├── etc/default/grub.d, etc/grub.d/42_neo_depannage
│           ├── etc/firefox, usr/lib/firefox-esr/defaults/pref/neo.js
│           ├── usr/local/bin/       neo-centre (centre Néo), neo-theme, neo-animations,
│           │                        neo-taches (gestionnaire des tâches), neo-diagnostic,
│           │                        neo-erreur, neo-raccourcis, neo-menu-session,
│           │                        neo-discord, neo-mesure, neo-graphique, neo-xserveur,
│           │                        neo-maj, neo-session, neo-installer
│           ├── usr/local/lib/neo/   neo_erreurs.py (catalogue des codes NEO-…)
│           ├── usr/share/neo/       raccourcis.tsv, profils picom (animations)
│           ├── usr/local/sbin/      neo-secours
│           └── usr/share/neo/calamares/  scripts d'installation (GRUB, dépôts)
├── tests/
│   └── verifier-systeme.sh  contrôles automatiques (VM ou HP réel)
└── scripts/
    ├── construire.sh        construction reproductible de l'ISO
    ├── creer-cle-usb.sh     écriture sécurisée sur clé USB
    ├── tester-vm.sh         tests QEMU (CPU Westmere sans AVX, 4 Go, BIOS)
    ├── vm-qmp.py            pilotage de la VM (captures, clavier, souris)
    └── doc-html.py          aide HTML embarquée (guide, raccourcis, codes d'erreur)
```

## Construire l'image

Prérequis : une machine Linux x86-64, les droits administrateur, environ 15 Go libres et un accès Internet.

```
sudo ./scripts/construire.sh
```

- Sur **Debian 13**, live-build est utilisé directement.
- Sur un **autre Linux** (Ubuntu, Fedora…), le script crée d'abord un chroot Debian 13 avec `debootstrap` (paquets `debootstrap` et `debian-archive-keyring` requis).
- Résultat : `sortie/neo-os-1.0-amd64.iso` et son `.sha256`.
- Compter de 30 à 90 minutes. Le cache de paquets accélère les constructions suivantes.
- Options : `NEO_APT_PROXY=http://…:3142` (apt-cacher-ng), `NEO_MIRROR=…`.

Pour reconstruire uniquement les éléments visuels (sur Debian 13) : `sh artwork/generer.sh`.

## Tester en machine virtuelle

Compte rendu complet : [docs/TESTS.md](docs/TESTS.md). Captures : [docs/captures/](docs/captures/).

```
./scripts/tester-vm.sh live                     # session d'essai
NEO_VM_AFFICHAGE=gtk ./scripts/tester-vm.sh installer   # installer sur un disque virtuel de 320 Go
./scripts/tester-vm.sh disque                   # démarrer le système installé
```

## Licences

La licence des scripts et de la configuration de ce projet reste à définir par le propriétaire du dépôt. Les thèmes Neo-Clair et Neo-Sombre sont dérivés d'Arc (GPL-3.0, voir `COPYRIGHT-arc-theme` dans chaque thème). Les paquets inclus restent sous leurs licences Debian respectives.
