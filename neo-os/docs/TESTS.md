# Compte rendu de tests — Néo OS 1.0

Tests réalisés le 27/10/2026 dans un conteneur Linux (cloud), **sans le HP Z200**. Sauf mention contraire, les résultats portent sur l'image finale :

```
neo-os-1.0-amd64.iso — 1 258 291 200 octets (1,2 Go, tient sur un DVD)
SHA-256 4075b6318b683decda254e7ba5b740f5ed819a0f5608a97378f7d2a047877c70
```

Cette image a été construite par `scripts/construire.sh` (live-build Debian 13, dans un chroot debootstrap). Le dépôt ne contient pas l'ISO : il faut la reconstruire (voir le README). Une nouvelle construction télécharge les paquets du jour (mises à jour de sécurité), donc la somme de contrôle changera.

## Environnement de test

| Élément | Machine virtuelle | HP Z200 réel |
|---|---|---|
| Processeur | QEMU **Westmere** émulé (TCG, sans KVM) : même jeu d'instructions que le Core i5-650, **sans AVX** | Core i5-650 |
| Mémoire | 4 096 Mo | 4 Go DDR3 |
| Démarrage | SeaBIOS (BIOS), chipset Q35 ; un essai OVMF (UEFI) | BIOS HP |
| Graphique | **QXL** (pilote `qxl`/modesetting) | Quadro FX 380 LP → **nouveau** |
| Disque | fichier qcow2 de 320 Go, vu comme disque **rotatif** SATA | disque dur 320 Go |
| Réseau | carte e1000 (NAT QEMU) | Intel 82578DM (e1000e) |

**Sans KVM, l'émulation est 10 à 30 fois plus lente qu'un vrai processeur.** Les durées ci-dessous ne disent donc rien des performances du HP.

## Résultats vérifiés en machine virtuelle

### Démarrage et session d'essai (live)

| Test | Résultat |
|---|---|
| Démarrage BIOS de l'ISO via isolinux, menu Néo en français, démarrage auto après 10 s | ✅ (capture 01) |
| Démarrage UEFI (OVMF) jusqu'au menu GRUB Néo | ✅ menu affiché (capture 12) ; démarrage UEFI complet non poursuivi |
| Fonctionnement sans AVX (le noyau et tout l'espace utilisateur tournent sur le processeur Westmere émulé) | ✅ |
| Connexion automatique, bureau XFCE Néo (thème clair, fond, barre, dock épinglé, icône réseau) | ✅ |
| Menu d'applications (touche Super) et recherche (« vid » → Celluloid, mpv, Atril, Ristretto) | ✅ (capture 06) |
| `tests/verifier-systeme.sh` en live | ✅ **30 OK, 0 échec** |
| Pas de verrouillage d'écran pendant 30 minutes d'inactivité (installation) | ✅ |

### Installation (Calamares)

| Test | Résultat |
|---|---|
| Écran de sécurité Néo : liste des disques, bouton bloqué tant que la sauvegarde n'est pas confirmée | ✅ |
| Calamares en français, identité Néo, clavier « French / Défaut » (AZERTY) et Europe/Paris présélectionnés | ✅ (capture 08) |
| Page Partitions : **aucune option présélectionnée**, bouton « Suivant » inactif tant que l'utilisateur n'a pas choisi ; mode BIOS détecté | ✅ |
| Disque contenant une partition encore montée : seul le partitionnement manuel est proposé | ✅ (observé lors d'un essai interrompu) |
| Résumé détaillé des opérations, puis seconde confirmation « Installer maintenant » | ✅ (capture 09) |
| Installation complète sur disque vierge (MBR/msdos, ext4, sans swap disque), **hors ligne** (GRUB BIOS déjà sur le support) | ✅ environ 31 min en émulation |
| Diaporama Néo pendant l'installation | ✅ (capture 10) |
| Paquets live retirés, dépôts HTTPS + sécurité écrits, disque GRUB mémorisé pour les mises à jour de `grub-pc` | ✅ |

### Système installé

| Test | Résultat |
|---|---|
| GRUB BIOS : entrée Néo OS, options avancées Debian (récupération), sous-menu **Néo OS — dépannage** | ✅ (captures 02, 03) |
| Écran de connexion LightDM Néo (sombre) | ✅ (capture 04) |
| `tests/verifier-systeme.sh` | ✅ **34 OK, 0 échec** : zram zstd, BFQ, `noatime`, earlyoom, mises à jour automatiques, aucun service en échec, Néo OS dans `os-release`, etc. |
| Bascule thème sombre (fenêtres, barre, fond, terminal) et Centre Néo | ✅ (capture 07) |
| Firefox ESR 153.5.1esr : démarrage, français, thème sombre suivi, uBlock Origin actif | ✅ (build n° 5, mêmes paquets) |
| `neo-graphique sans-accel / logiciel / auto` : GRUB régénéré, état correct | ✅ |
| Entrée **Affichage de secours (nomodeset)** : Xorg en VESA, session stable avec le lanceur `neo-xserveur` | ✅ (capture 11) |
| Espace occupé après installation | 3,2 Go sur `/` |

### Mémoire (objectif : moins de 700 Mo au repos)

Indicateur : `MemTotal − MemAvailable` (cache disque exclu), mesuré par `neo-mesure` environ 6 à 10 minutes après la connexion, avec **un terminal ouvert** pour lancer la mesure.

| Situation | Mémoire utilisée | Somme des PSS des programmes |
|---|---|---|
| Session live (image finale) | **693 Mo** | 361 Mo |
| Système installé (image finale) | **672 Mo** | 340 Mo |
| Système installé + Firefox ouvert (2 onglets) (build n° 5) | 1 073 Mo | 983 Mo |
| *Avant correction des caches d'icônes et de polices (build n° 2, live)* | *1 280 Mo* | *935 Mo* |

En VM, l'objectif de 700 Mo est donc atteint, de justesse. Sur le HP, le pilote nouveau, le firmware et la carte réseau différents feront varier le résultat de quelques dizaines de Mo : **la mesure est à refaire sur la machine** (voir plus bas).

### Problèmes trouvés en test et corrigés

| Problème constaté | Cause | Correction |
|---|---|---|
| Pas de connexion automatique en live | `user-setup` n'était que « recommandé » par live-config | paquet ajouté |
| Icônes génériques | chargeur SVG `librsvg2-common` absent | paquet ajouté |
| 60 à 90 Mo de RAM en trop par application GTK | caches d'icônes supprimés par un crochet live-build, cache de polices vide | crochet `9100-neo-caches` + service `neo-caches` au démarrage |
| Icône réseau invisible sans compositeur | fond de barre transparent | barre à fond uni ; icônes Papirus-Light pour le thème clair |
| Échec de l'installation (« unsquashfs introuvable ») | `squashfs-tools` seulement recommandé | paquet ajouté |
| `noatime` absent du fstab | Calamares 3.3 lit ces options dans `mount.conf` | configuration déplacée |
| Diaporama vide | modules QML Qt 6 manquants, tailles nulles | paquets et `show.qml` corrigés |
| **Plantage de Xorg en mode secours** (segfault dans `RRGetInfo`, pilote VESA) | appel RandR de `xfsettingsd` | `neo-xserveur` : X sans RANDR quand `nomodeset` est actif |
| Verrouillage d'écran pendant l'installation | light-locker actif en live | désactivé en session live |
| Nom « Debian » dans `/etc/os-release` | fichier détourné par live-build pendant la construction | lien posé au démarrage (tmpfiles) |

## À valider sur le HP Z200 (non vérifiable ici)

1. **Démarrage USB/DVD par le BIOS HP** (F9). La VM ne simule ni le BIOS HP ni ses particularités USB.
2. **Pilote nouveau sur la Quadro FX 380 LP (GT218)** : affichage, résolution native, stabilité, mise en veille de l'écran. Si besoin, essayer `logiciel` puis `sans-accel`.
3. **Composition « Équilibré »** : vérifier l'absence de déchirures et d'artefacts.
4. **Vidéo** : lecture 720p/1080p H.264 dans Firefox et Celluloid, en décodage processeur (pas de décodage matériel avec nouveau). Surveiller la charge avec le gestionnaire des tâches.
5. **Mémoire au repos** : se connecter, attendre 5 minutes sans rien lancer, puis exécuter `sudo neo-mesure --detail`. Ou démarrer avec l'option `neo.rapport` : le rapport arrive dans `journalctl -u neo-rapport`.
6. **Réactivité du disque mécanique** : démarrage complet (`systemd-analyze`), ouverture de Firefox et de LibreOffice, copie de gros fichiers pendant la navigation (effet de BFQ).
7. **Son** (puce HD Audio de la carte mère) et **réseau** Intel e1000e.
8. **Installation à côté d'un système existant** (« Installer à côté » / « Remplacer une partition ») : seul l'effacement d'un disque vierge virtuel a été testé de bout en bout.
9. **`neo-secours`** depuis la clé (réinstallation de GRUB, chroot) : syntaxe vérifiée, scénario non exécuté.
10. **`neo-maj`** et la mise à jour automatique : non exécutés, car la VM n'a pas d'accès direct à Internet (proxy d'inspection TLS du bac à sable, que Firefox refuse à juste titre).

Le script `tests/verifier-systeme.sh` peut être lancé tel quel sur le HP (`sudo sh verifier-systeme.sh > rapport.txt`) pour reprendre tous les contrôles ci-dessus.

## Limites connues

- **Pas de décodage vidéo matériel** : le firmware NVIDIA nécessaire n'est pas redistribuable. AV1 et VP9 sont désactivés dans Firefox pour préférer le H.264 ; la 4K et le 1080p à 60 images/s seront probablement saccadés.
- **Pilote NVIDIA propriétaire impossible** : le 340.xx n'est plus maintenu et ne fonctionne pas avec Debian 13.
- **Chiffrement du disque** non proposé en installation guidée : les outils `cryptsetup-initramfs` ne sont pas sur le support live.
- **Mode secours (VESA)** : sans RANDR, l'outil « Écrans » ne peut pas changer la résolution.
- **UEFI** (autres machines) : sans Internet pendant l'installation, `grub-pc` reste installé. Lancer ensuite `sudo apt install grub-efi-amd64`.
- **Bus d'accessibilité (AT-SPI)** non installé pour économiser de la mémoire. Les applications l'indiquent dans le terminal ; pour le réactiver : `sudo apt install at-spi2-core`.
- **Fichier d'échange** absent par défaut (choix « Aucun swap » recommandé). Pas d'hibernation.
- Le guide HTML intégré à l'ISO testée a été généré juste avant deux ajouts mineurs de `docs/UTILISATION.md` (`neo-mesure --detail`, limite RANDR). Une reconstruction les intègre.
