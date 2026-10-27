# Choix techniques de Letag OS

## Matériel cible, vérifications

| Composant | Ce qui a été vérifié | Conséquence |
|---|---|---|
| **Core i5-650** (Clarkdale, 2010) | Jeu d'instructions x86-64-v2 : SSE4.2, POPCNT et AES-NI présents, **pas d'AVX**. | Il faut une distribution compilée pour x86-64 « de base » (v1/v2). Debian amd64 vise la v1, ce qui convient. À éviter : RHEL 10 et ses dérivées (exigent x86-64-v3, donc AVX2), et les variantes « v3 » de certaines distributions. Les tests VM utilisent le modèle de processeur QEMU **Westmere** (même génération, sans AVX). |
| **BIOS du HP Z200** | Machine de 2009-2010 à BIOS « Legacy ». Les témoignages trouvés indiquent qu'elle n'a pas d'UEFI. Menu de démarrage : **F9**. Réglages : **F10**. | L'ISO démarre en BIOS via **isolinux** (et en UEFI via GRUB pour d'autres machines). Le système installé utilise **GRUB BIOS (grub-pc)**, déjà présent sur le support : l'installation ne demande pas Internet. *À valider sur le HP.* |
| **Quadro FX 380 LP** | Puce **GT218 (« NVA8 »)**, famille Tesla/NV50 (le modèle FX 380 non-LP utilise une G96). Le dernier pilote NVIDIA pour cette famille, le **340.xx**, n'est plus maintenu depuis 2019 et ne fonctionne pas avec les noyaux et le serveur X récents (absent de Debian 13). Le pilote libre **nouveau** prend en charge NVA8 : affichage, 2D, OpenGL 3.3 via Mesa. Le décodage vidéo matériel (VP4) exige un firmware NVIDIA non redistribuable : il est indisponible. | Pilote **nouveau** (noyau + Xorg) par défaut, avec trois modes de repli (OpenGL logiciel, sans accélération, VESA/nomodeset), choisis au démarrage ou par `letag-graphique`. Vidéo décodée par le processeur. *Stabilité de nouveau à valider sur le HP.* |
| **4 Go DDR3, disque mécanique** | — | Priorité à une faible occupation mémoire et à peu d'accès disque : zram, earlyoom, BFQ, noatime, journaux limités, pas de services superflus (voir plus bas). |
| Wi-Fi / Bluetooth | Non mentionnés, donc **non supposés**. | Aucun paquet Bluetooth ni firmware Wi-Fi. NetworkManager gère le réseau filaire, et une clé Wi-Fi USB si son pilote est libre. |

## Base : Debian 13 « trixie »

- **Maintenue** : version stable sortie en août 2025, mises à jour de sécurité jusqu'en 2028 environ, puis LTS jusqu'en 2030 environ.
- **Compatible avec ce processeur** : baseline amd64 sans AVX.
- **Noyau 6.12 LTS** : nouveau, BFQ et zram (zstd) inclus.
- **Firefox ESR** suivi par l'équipe sécurité Debian, plus **unattended-upgrades** pour les correctifs automatiques.
- **Outils de construction reproductibles** : `live-build` (qui produit les ISO officielles Debian Live) et **Calamares** (l'installateur de Debian Live), tous deux dans l'archive.
- Alternatives écartées : Ubuntu/Xubuntu, plus lourd (snap, Firefox en snap), et Arch, sans ISO reproductible stable ni maintenance « tranquille » adaptée.

## Bureau : XFCE 4.20 + Xorg

- Bureau complet et francisé : barre des tâches, menu Whisker avec recherche, Thunar, gestionnaire de paramètres. Il est léger, entre 400 et 600 Mo au repos selon les distributions, ce qui reste à mesurer ici.
- Son compositeur xfwm4 est **désactivable** à chaud. Il fonctionne en XRender, sans OpenGL, ce qui est peu exigeant pour la carte graphique.
- **Xorg plutôt que Wayland** : sur nouveau/Tesla, Wayland dépend d'une accélération OpenGL fragile, alors que Xorg dispose de replis éprouvés (VESA, fbdev, shadowfb).
- Écartés : GNOME et KDE Plasma (trop gourmands pour 4 Go avec un navigateur ouvert, compositeur OpenGL obligatoire) ; LXQt (correct, mais moins cohérent en GTK avec Firefox et LibreOffice).

## Identité visuelle

Palette reprise du projet « LE TAG » du même dépôt : fond `#F3F3F1`, encre `#1B1B1B`, rouge `#E23B2E`.

- **Thèmes GTK/xfwm4 Letag-Clair et Letag-Sombre** : générés depuis Arc (thème léger, sans moteur), avec l'accent bleu remplacé par le rouge Letag et des gris neutres (`artwork/recolorer-arc.py`, appliqué aussi aux ressources compilées).
- **Icônes** : Papirus / Papirus-Dark, plus le logo et les icônes Letag.
- **Typographie** : Inter pour l'interface, DejaVu Sans Mono pour le code.
- Logo, fonds d'écran, écran de démarrage isolinux, fond GRUB, écran de connexion LightDM (sombre, sans animation) et diaporama de l'installateur partent tous des SVG de `artwork/src/`.

## Mémoire et disque

| Réglage | Valeur | Raison |
|---|---|---|
| zram (zram-generator) | 75 % de la RAM, zstd, priorité 100 | Swap rapide en RAM compressée (ratio typique 2,5 à 4). |
| Swap disque | aucun par défaut (fichier proposé à l'installation) | Sur disque mécanique, le swap provoque des gels de plusieurs secondes. |
| `vm.swappiness` | 150 | Avec zram, l'échange est moins coûteux que de relire des fichiers sur le disque lent. |
| `vm.page-cluster` | 0 | Pas de lecture anticipée en zram. |
| `vm.vfs_cache_pressure` | 50 | Garder les métadonnées des fichiers en cache. |
| `vm.dirty_*_ratio` | 3 / 10 | Écritures plus régulières : pas de gel pendant les grosses copies. |
| earlyoom | RAM < 5 % **et** swap < 10 % | Fermer l'onglet le plus gourmand plutôt que geler le système. |
| Ordonnanceur E/S | BFQ (disques rotatifs) | Garde le bureau réactif pendant les tâches de fond. |
| Montage | `noatime` | Pas d'écriture à chaque lecture. |
| journald | 64 Mo maximum, écriture différée de 10 min | Moins d'écritures disque. |
| apt-daily, man-db | `Nice=19`, E/S « idle » | Tâches de fond invisibles. |
| `NetworkManager-wait-online` | désactivé | Démarrage plus rapide. |
| Paquets recommandés | non installés (`APT::Install-Recommends false`) | Évite les dépendances superflues. |
| Firefox | 4 processus, onglets déchargés si la mémoire manque, H.264 préféré | Mémoire et charge processeur. |

**Services absents** : Bluetooth, CUPS (impression : `sudo apt install task-print-server system-config-printer`), Avahi, ModemManager, indexation de fichiers, Snap/Flatpak.

## Installation et récupération

- **Calamares** démarre **sans aucune option de partitionnement présélectionnée**. Il est précédé d'un écran Letag qui liste les disques et exige de confirmer la sauvegarde. Rien n'est écrit avant la validation du résumé, et le système n'efface jamais un disque de lui-même.
- La session live ne monte ni n'active le swap du disque interne (comportement par défaut de live-boot).
- GRUB détecte les autres systèmes (os-prober) et ajoute un sous-menu **« Letag OS — dépannage »** : affichage de secours, affichage sans accélération, console de récupération. Les entrées de récupération de Debian restent disponibles.
- La clé USB fait office de **support de secours** : `letag-secours` (réinstaller GRUB, réinitialiser l'affichage, chroot), GParted, TestDisk/PhotoRec et memtest86+.
