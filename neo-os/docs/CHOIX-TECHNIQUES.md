# Choix techniques de Néo OS

## Matériel cible, vérifications

| Composant | Ce qui a été vérifié | Conséquence |
|---|---|---|
| **Core i5-650** (Clarkdale, 2010) | Jeu d'instructions x86-64-v2 : SSE4.2, POPCNT et AES-NI présents, **pas d'AVX**. | Il faut une distribution compilée pour x86-64 « de base » (v1/v2). Debian amd64 vise la v1, ce qui convient. À éviter : RHEL 10 et ses dérivées (exigent x86-64-v3, donc AVX2), et les variantes « v3 » de certaines distributions. Les tests VM utilisent le modèle de processeur QEMU **Westmere** (même génération, sans AVX). |
| **BIOS du HP Z200** | Machine de 2009-2010 à BIOS « Legacy ». Les témoignages trouvés indiquent qu'elle n'a pas d'UEFI. Menu de démarrage : **F9**. Réglages : **F10**. | L'ISO démarre en BIOS via **isolinux** (et en UEFI via GRUB pour d'autres machines). Le système installé utilise **GRUB BIOS (grub-pc)**, déjà présent sur le support : l'installation ne demande pas Internet. *À valider sur le HP.* |
| **Quadro FX 380 LP** | Puce **GT218 (« NVA8 »)**, famille Tesla/NV50 (le modèle FX 380 non-LP utilise une G96). Le dernier pilote NVIDIA pour cette famille, le **340.xx**, n'est plus maintenu depuis 2019 et ne fonctionne pas avec les noyaux et le serveur X récents (absent de Debian 13). Le pilote libre **nouveau** prend en charge NVA8 : affichage, 2D, OpenGL 3.3 via Mesa. Le décodage vidéo matériel (VP4) exige un firmware NVIDIA non redistribuable : il est indisponible. | Pilote **nouveau** (noyau + Xorg) par défaut, avec trois modes de repli (OpenGL logiciel, sans accélération, VESA/nomodeset), choisis au démarrage ou par `neo-graphique`. Vidéo décodée par le processeur. *Stabilité de nouveau à valider sur le HP.* |
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
- **Animations : picom 12** (compositeur XRender, sans OpenGL) remplace le compositeur de xfwm4, qui ne sait pas animer l'ouverture, la fermeture ou la réduction des fenêtres. Trois niveaux dans le centre Néo (`neo-animations`) : *complètes* (ouverture 0,16 s, fermeture 0,12 s, réduction vers la barre 0,19 s, menus 0,09 s, notifications glissantes 0,18 s), *réduites* (fondus de 0,10 s) et *désactivées* (aucun compositeur). Les durées restent sous 0,2 s : l'effet se voit sans ralentir.
- En **mode secours** (`nomodeset` ou `nouveau.noaccel=1`), `neo-animations` force « désactivées », quel que soit le réglage.
- La barre a un fond uni : sans compositeur, les icônes de notification (XEmbed) deviennent invisibles sur fond transparent, ce qui a été constaté en test.
- **Xorg plutôt que Wayland** : sur nouveau/Tesla, Wayland dépend d'une accélération OpenGL fragile, alors que Xorg dispose de replis éprouvés (VESA, fbdev, shadowfb).
- Écartés : GNOME et KDE Plasma (trop gourmands pour 4 Go avec un navigateur ouvert, compositeur OpenGL obligatoire) ; LXQt (correct, mais moins cohérent en GTK avec Firefox et LibreOffice).

## Identité visuelle

Palette imposée, reprise du fond d'écran de l'utilisateur :

| Couleur | Code | Rôle |
|---|---|---|
| Crème | `#FEF9EB` | fond principal du thème clair |
| Menthe clair | `#C6EBD4` | barre, panneaux latéraux, surfaces secondaires |
| Menthe | `#7DCDAD` | accents, sélections, barres de progression |
| Vert d'eau | `#91D2BC` | survol, éléments complémentaires |
| Bleu | `#4478AF` | actions principales, liens, éléments actifs |
| Bleu marine | `#0F2B5B` | texte, structure, fond du thème sombre |

- **Couleurs unies**, reliefs discrets : ombres marine à 20 %, coins arrondis de 8 à 9 px, boutons de titre ronds.
- **Thèmes GTK Neo-Clair / Neo-Sombre**, générés depuis Arc (léger, sans moteur) par `artwork/generer-themes.py`. Le script produit aussi la décoration xfwm4, le thème des notifications, et calcule les contrastes WCAG ([CONTRASTE.md](CONTRASTE.md)).
- **Lisibilité** : texte marine sur menthe (7,4:1), sur menthe clair (10,7:1) et sur crème (13,2:1). Le texte n'est jamais blanc sur menthe (1,9:1). Le bleu `#4478AF` sur crème atteint 4,4:1, juste sous le seuil AA de 4,5:1 pour le petit texte : les liens restent soulignés, et les boutons bleus portent du texte blanc (4,6:1).
- **Erreurs et avertissements** hors palette, pour rester immédiatement reconnaissables : rouge `#B3261E` avec texte blanc pour les erreurs et actions destructrices, ambre `#F2C14E` avec texte marine pour les avertissements, toujours accompagnés d'une icône et d'un texte explicite.
- Identité commune à isolinux, GRUB (thème graphique), LightDM, Calamares (feuille de style QSS), xfwm4, les notifications et les icônes Néo (Papirus + icônes propres).
- **Typographie** : Inter pour l'interface, DejaVu Sans Mono pour le code.

## Outils Néo

- **Gestionnaire des tâches** (`neo-taches`, Python/GTK + psutil) : remplace xfce4-taskmanager, qui n'a ni graphiques disque/réseau ni onglet Démarrage. Il ne montre que des valeurs réellement mesurées : la charge GPU et la VRAM ne sont pas exposées par nouveau, elles sont donc affichées « Indisponible » avec la raison. Les processus essentiels (session, Xorg, systemd…) sont protégés. « Libérer de la RAM » ne ferme que les applications cochées par l'utilisateur, après confirmation, et affiche la mémoire réellement récupérée (différence de MemAvailable).
- **Raccourcis Windows** : une seule liste (`/usr/share/neo/raccourcis.tsv`) sert à la fois à les appliquer (xfconf) et à générer la fiche d'aide.
- **Codes d'erreur** `NEO-XXX-NNN` (`neo_erreurs.py`) : chaque message donne le code, l'explication et la solution. Le **Diagnostic** ne signale que ce qui est réellement détectable. Quand une vérification n'est pas possible (par exemple un journal illisible sans droits), il l'affiche « Indisponible » au lieu de conclure.
- **Discord** : il n'est pas inclus dans l'image, car sa licence n'en autorise pas la redistribution. `neo-discord` télécharge le paquet officiel depuis discord.com, vérifie que la redirection reste sur un domaine Discord et que le paquet déclare bien le nom `discord`, un mainteneur `@discord.com` et l’architecture amd64 (le .deb n’est pas signé : la garantie vient du HTTPS vers discord.com), puis l'installe. Il désactive aussi « Ouvrir Discord au démarrage ». Le paquet officiel n'est qu'un lanceur : l'application (Electron, sans AVX requis) est téléchargée au premier lancement et se met à jour seule.

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
| `unattended-upgrades.service` | désactivé (le minuteur `apt-daily-upgrade` reste actif) | Ce service ne sert qu'à retarder l'arrêt et garde un processus Python d'environ 30 Mo. |
| Caches d'icônes et de polices | régénérés à la construction et vérifiés à chaque démarrage | Sans eux, chaque application GTK consommait 60 à 90 Mo de plus (mesuré). |
| Paquets recommandés | non installés (`APT::Install-Recommends false`) | Évite les dépendances superflues. |
| Firefox | 4 processus, onglets déchargés si la mémoire manque, H.264 préféré | Mémoire et charge processeur. |

**Services absents** : Bluetooth, CUPS (impression : `sudo apt install task-print-server system-config-printer`), Avahi, ModemManager, indexation de fichiers, Snap/Flatpak.

## Installation et récupération

- **Calamares** démarre **sans aucune option de partitionnement présélectionnée**. Il est précédé d'un écran Néo qui liste les disques et exige de confirmer la sauvegarde. Rien n'est écrit avant la validation du résumé, et le système n'efface jamais un disque de lui-même.
- La session live ne monte ni n'active le swap du disque interne (comportement par défaut de live-boot).
- En mode secours (`nomodeset`, pilote VESA), Xorg démarre sans l'extension RANDR (`neo-xserveur`), car il plantait à l'ouverture de la session XFCE (constaté en test).
- GRUB détecte les autres systèmes (os-prober) et ajoute un sous-menu **« Néo OS — dépannage »** : affichage de secours, affichage sans accélération, console de récupération. Les entrées de récupération de Debian restent disponibles.
- La clé USB fait office de **support de secours** : `neo-secours` (réinstaller GRUB, réinitialiser l'affichage, chroot), GParted, TestDisk/PhotoRec et memtest86+.
