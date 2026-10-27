# Guide Letag OS

Letag OS est un système léger en français, basé sur **Debian 13 « trixie »** et le bureau **XFCE 4.20**, réglé pour le HP Z200 (Core i5-650, 4 Go de RAM, disque dur mécanique, Quadro FX 380).

## Le bureau en bref

| Pour… | Faire |
|---|---|
| Ouvrir le menu et chercher une application | Touche **Super** (Windows), ou clic sur le logo en bas à gauche, puis taper |
| Lancer une application par son nom | **Alt + F2** |
| Chercher un fichier | **Super + F** (Catfish) |
| Ouvrir le gestionnaire de fichiers | **Super + E** (Thunar) |
| Ouvrir un terminal | **Super + T** ou **Ctrl + Alt + T** |
| Verrouiller l'écran | **Super + L** |
| Afficher le bureau | **Super + D** |
| Réglages Letag (thème, effets, affichage) | **Super + I**, ou menu → Centre Letag |
| Tous les réglages | Menu → Paramètres (Gestionnaire de paramètres XFCE) |

La barre des tâches, en bas, contient le menu, les applications épinglées (clic droit sur une icône pour épingler ou désépingler), la zone de notification (réseau), le son, l'horloge et le bouton d'arrêt.

### Applications fournies

- **Internet** : Firefox ESR (version maintenue à long terme, mises à jour de sécurité Debian), avec le bloqueur de publicités uBlock Origin.
- **Bureautique** : LibreOffice Writer, Calc, Impress ; lecteur PDF Atril.
- **Vidéo / musique** : Celluloid (basé sur mpv).
- **Fichiers** : Thunar, gestionnaire d'archives Xarchiver, recherche Catfish.
- **Programmation** : Geany (éditeur/IDE léger), Git, Python 3 (venv, pip), outils de compilation (gcc, make).
- **Outils** : terminal, éditeur de texte Mousepad, visionneuse d'images Ristretto, capture d'écran, gestionnaire des tâches.

D'autres logiciels s'installent avec `sudo apt install <paquet>` (catalogue Debian complet).

## Thème clair / sombre

Centre Letag → **Apparence**, ou dans un terminal :

```
letag-theme sombre      # ou : clair, basculer
```

Le thème change les fenêtres, les icônes, la barre et le fond d'écran. Firefox et LibreOffice suivent le thème.

## Effets visuels et fluidité

Par défaut, le profil **Minimal** est actif : pas de composition, pas d'ombres, pas de transparence, pas d'animation. C'est le réglage le plus fluide et le plus sûr avec la carte Quadro FX 380.

Si l'affichage est stable, le profil **Équilibré** ajoute des ombres sous les fenêtres (composition légère, sans transparence ni animation) :

```
letag-effets equilibre  # revenir : letag-effets minimal
```

Si l'image se déchire, saccade ou laisse des traces, revenez à **Minimal**.

## Pilote d'affichage

La Quadro FX 380 utilise le pilote libre **nouveau**. Le pilote NVIDIA 340.xx, le dernier à prendre en charge cette carte, n'est plus maintenu et ne fonctionne pas avec Debian 13. Quatre modes sont disponibles (Centre Letag → **Pilote d'affichage**, ou `sudo letag-graphique <mode>`) :

| Mode | Quand l'utiliser |
|---|---|
| `auto` | Défaut : nouveau avec accélération. |
| `logiciel` | Firefox, la vidéo ou des applications 3D plantent ou affichent des artefacts : l'OpenGL est alors calculé par le processeur. |
| `sans-accel` | L'écran se fige ou clignote : nouveau sans aucune accélération. |
| `secours` | L'écran reste noir : pilote VESA générique (lent, résolution parfois limitée). |

Le changement prend effet au redémarrage. En mode `secours`, l'extension RANDR de Xorg est désactivée (le pilote VESA plante sans cela) : l'outil « Écrans » ne permet alors pas de changer la résolution. **Si l'écran reste noir au démarrage**, choisissez dans le menu GRUB **« Letag OS — dépannage » → « Affichage de secours »**, connectez-vous, puis choisissez un autre mode.

## Mémoire et performances

- **zram** : une partie de la RAM sert de mémoire d'échange compressée (environ 3 Go de capacité pour environ 1 Go de RAM réelle quand elle est pleine). C'est bien plus rapide qu'un fichier d'échange sur le disque mécanique.
- **earlyoom** : si la mémoire vient vraiment à manquer, le programme le plus gourmand (en priorité un onglet de Firefox ou LibreOffice) est fermé avant que l'ordinateur ne gèle.
- **Disque** : ordonnanceur BFQ (le bureau reste réactif pendant une copie ou une mise à jour), option `noatime`, journal système limité à 64 Mo, tâches de fond (mises à jour, index des manuels) en priorité minimale.
- **Firefox** : 4 processus de contenu au lieu de 8, onglets déchargés quand la mémoire manque, AV1 et VP9 désactivés pour que les sites servent du H.264, moins coûteux à décoder (pour les réactiver : `about:config` → `media.av1.enabled` et `media.mediasource.vp9.enabled`).

Pour mesurer la mémoire utilisée :

```
letag-mesure                # résumé
sudo letag-mesure --detail  # part réelle (PSS) de chaque programme
```

Conseils : évitez d'ouvrir plus de 10 à 15 onglets à la fois ; préférez la vidéo en 720p ou 1080p à 30 images/s.

## Mises à jour

- Les **mises à jour de sécurité** de Debian s'installent **automatiquement** chaque jour (unattended-upgrades).
- Pour **tout** mettre à jour : menu → **Mettre à jour le système**, ou :

```
letag-maj
```

- Firefox ESR reçoit ses correctifs de sécurité par ce même canal.
- Debian 13 est maintenue jusqu'en 2028 environ, puis prise en charge à long terme (LTS) jusqu'en 2030 environ.

## Récupération

### L'écran reste noir ou l'affichage est instable

1. Au démarrage, menu GRUB → **Letag OS — dépannage** → **Affichage de secours (nomodeset)**.
2. Une fois connecté : Centre Letag → Pilote d'affichage → `sans-accel` ou `logiciel` → Appliquer → redémarrer.

### Le système ne démarre plus du tout

1. Démarrez sur la clé USB (ou le DVD) Letag OS : **F9** au démarrage du HP Z200 pour choisir le périphérique.
2. Choisissez **Essayer Letag OS**.
3. Ouvrez un terminal et lancez `sudo letag-secours` :
   - **1** : réinstaller GRUB ;
   - **2** : revenir au mode d'affichage automatique ;
   - **3** : ouvrir un terminal administrateur dans le système installé (réparer un paquet, changer un mot de passe…).

L'outil ne formate rien et n'efface aucune donnée.

### Mode récupération (console)

Menu GRUB → **Letag OS — dépannage** → **Console de récupération** : session administrateur sans interface graphique. Le menu « Options avancées » de Debian propose aussi les modes de récupération de chaque noyau.

### Récupérer des fichiers

Depuis la session live, Thunar accède aux partitions du disque (cliquez sur la partition dans le panneau de gauche, le mot de passe de la session live est `live`). **TestDisk** et **PhotoRec** (`sudo testdisk`, `sudo photorec`) retrouvent des partitions ou des fichiers supprimés.

### Santé du disque dur

Le disque d'origine du Z200 a plus de quinze ans. Vérifiez son état de temps en temps :

```
sudo smartctl -H /dev/sda      # « PASSED » = pas d'alerte
sudo smartctl -A /dev/sda      # surveiller Reallocated_Sector_Ct et Current_Pending_Sector
```

Sauvegardez régulièrement vos documents sur une clé ou un disque externe.
