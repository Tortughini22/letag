# Guide Néo OS

Néo OS est un système léger en français, basé sur **Debian 13 « trixie »** et le bureau **XFCE 4.20**, réglé pour le HP Z200 (Core i5-650, 4 Go de RAM, disque dur mécanique, Quadro FX 380 LP). Il reprend les habitudes de Windows : raccourcis clavier, gestionnaire des tâches et explorateur de fichiers organisés de la même façon.

## Le bureau en bref

| Pour… | Faire |
|---|---|
| Ouvrir le menu et chercher une application | Touche **Windows**, puis taper le nom |
| Gestionnaire de fichiers | **Windows + E** |
| Exécuter une commande | **Windows + R** |
| Paramètres | **Windows + I** (Centre Néo : menu → Centre Néo) |
| Gestionnaire des tâches | **Ctrl + Maj + Échap** |
| Menu de session (verrouiller, se déconnecter, éteindre) | **Ctrl + Alt + Suppr** |
| Verrouiller | **Windows + L** |
| Afficher le bureau | **Windows + D** |
| Ranger une fenêtre à gauche / à droite / agrandir / réduire | **Windows + ← / → / ↑ / ↓** |

La liste complète est dans **Raccourcis clavier** (menu → Aide, ou Centre Néo). Elle est aussi reproduite dans le fichier `RACCOURCIS.md`.

**Différences avec Windows** : **Windows + ↓** réduit toujours la fenêtre. Pour restaurer une fenêtre agrandie, utilisez **Windows + ↑** (bascule agrandir/restaurer). **Windows + R** ouvre la recherche d'applications XFCE en mode « commande ». **Windows + S** recherche des fichiers (Catfish).

### Applications fournies

- **Internet** : Firefox ESR, avec le bloqueur de publicités uBlock Origin.
- **Discord** : à installer depuis le menu → **Installer Discord** (téléchargement depuis discord.com).
- **Bureautique** : LibreOffice Writer, Calc et Impress ; lecteur PDF Atril.
- **Vidéo et musique** : Celluloid.
- **Fichiers** : explorateur Thunar, gestionnaire d'archives Xarchiver, recherche Catfish.
- **Programmation** : Geany, Git, Python 3, gcc et make.
- **Outils Néo** :
  - Centre Néo ;
  - Gestionnaire des tâches ;
  - Diagnostic Néo ;
  - Raccourcis clavier ;
  - Mettre à jour le système.

## Apparence : thème clair ou sombre

Centre Néo → **Apparence**, ou dans un terminal : `neo-theme sombre` (ou `clair`, `basculer`).

La palette est la même partout : fenêtres, menus, notifications, écran de connexion, installateur et menus de démarrage.

| Couleur | Rôle |
|---|---|
| crème `#FEF9EB` | fond principal |
| menthe clair `#C6EBD4` | panneaux et barre des tâches |
| menthe `#7DCDAD` | sélections et progression |
| vert d'eau `#91D2BC` | survol |
| bleu `#4478AF` | actions principales et liens |
| bleu marine `#0F2B5B` | texte, et fond du thème sombre |

Les erreurs (rouge) et les avertissements (ambre) gardent des couleurs distinctes, avec une icône et un texte explicite. Les contrastes sont détaillés dans `CONTRASTE.md`.

**Votre propre fond d'écran** : clic droit sur le bureau → Paramètres du bureau → choisissez l'image.

## Animations

Centre Néo → **Animations** :

- **Complètes** (par défaut) : ouverture, fermeture, réduction et restauration des fenêtres, menus, notifications et changements de bureau, en 90 à 200 ms, avec des ombres légères et des coins arrondis.
- **Réduites** : fondus très courts, sans déplacement.
- **Désactivées** : aucune animation ni ombre, le réglage le plus économe.

En ligne de commande : `neo-animations completes` (ou `reduites`, `desactivees`).

Les animations sont produites par le compositeur picom, avec un rendu XRender sans OpenGL. **En mode d'affichage de secours, elles sont toujours désactivées** (code NEO-AFF-004). Si l'image saccade ou laisse des traces, choisissez « Réduites » ou « Désactivées ».

## Gestionnaire des tâches (Ctrl + Maj + Échap)

- **Processus** : les **Applications** (une ligne par application, ses sous-processus en dessous), les **Processus en arrière-plan** et les **Processus du système**.
  - Pour chacun : processeur, mémoire privée, disque, état.
  - Recherche avec **Ctrl + F** ; tri par clic sur un titre de colonne.
  - **Fin de tâche** (bouton, touche **Suppr** ou clic droit) : l'application reçoit une demande de fermeture normale, comme avec Alt + F4. Si elle ne répond pas après 5 secondes, Néo OS propose **Forcer l'arrêt**.
  - Les **processus essentiels** (session, affichage, son, réseau) sont protégés et ne peuvent pas être arrêtés depuis le gestionnaire (code NEO-TCH-001). Les processus du système ne sont pas modifiables non plus (NEO-TCH-002).
- **Performances** : graphiques sur 60 secondes pour le processeur, la mémoire, chaque disque, chaque connexion réseau et la carte graphique.
  - **Carte graphique** : avec le pilote « nouveau » de la Quadro FX 380, la charge et la mémoire vidéo utilisée ne sont pas publiées par le pilote ; elles s'affichent **« Indisponible »**, sans valeur inventée. Avec une carte AMD (pilote amdgpu), ces valeurs sont lues réellement.
  - **Mémoire** : utilisée, disponible, **en cache** (libérée automatiquement si besoin), swap compressé zram et barre de composition.
- **Démarrage** : programmes lancés à l'ouverture de session, avec une case pour les activer ou les désactiver. Les éléments essentiels sont protégés. L'« impact au démarrage » n'est pas mesuré.
- **Libérer de la RAM…** :
  1. La fenêtre affiche la mémoire utilisée, disponible et en cache, avec une explication.
  2. Elle liste les applications ouvertes, triées par mémoire, **sans rien cocher d'avance**.
  3. Après votre confirmation, les applications cochées reçoivent une demande de fermeture normale.
  4. Néo OS affiche ensuite la **mémoire réellement récupérée**, mesurée avant et après.

  Pour alléger Firefox sans le fermer, utilisez la page `about:unloads`.

## Explorateur de fichiers (Windows + E)

Thunar est réglé comme l'Explorateur Windows :

- **Panneau gauche** :
  - dossiers habituels (Bureau, Documents, Téléchargements, Images, Musique, Vidéos) ;
  - signets « accès rapide » ;
  - disques et clés USB (montage d'un clic) ;
  - corbeille.
- **Barre d'adresse modifiable** (**Ctrl + L**) avec les boutons Précédent, Suivant, Dossier parent et Actualiser. **Recherche** avec **Ctrl + F** (recherche dans les sous-dossiers).
- Vue **détails** par défaut (Nom, Modifié le, Type, Taille). Changement de vue avec **Ctrl + 1/2/3** ou le sélecteur de la barre d'outils.
- **Clic droit** :
  - ouvrir avec ;
  - copier, couper, coller ;
  - renommer (**F2**) ;
  - **Créer un document** (texte, Writer, Calc) ;
  - **Propriétés** (**Alt + Entrée**).
- **Glisser-déposer** : déplace dans le même disque, copie vers un autre disque, comme Windows. **Suppr** met à la corbeille.
- **Copie** : fenêtre de progression avec vitesse et temps restant. Si un fichier existe déjà, Thunar propose **Remplacer**, **Ignorer** ou **Renommer** (l'équivalent de « Conserver les deux »), pour un fichier ou pour tous.

**Différences restantes avec l'Explorateur Windows** :

- **Signets** : l'« Accès rapide » de Windows correspond ici aux signets, qui s'affichent dans le panneau gauche. Pour ajouter un signet : clic droit sur un dossier → **Envoyer vers → Panneau latéral** (ou **Ctrl + D**).
- **Barre d'adresse** : elle reste un champ texte, sans le « fil d'Ariane » cliquable de Windows.
- **Pas de ruban** : les commandes sont dans les menus et dans le clic droit.
- **Copie de fichiers déjà existants** : pour garder les deux fichiers, choisissez « Renommer » et donnez un nouveau nom. Windows ajoute « (2) » automatiquement.
- **Bibliothèques et OneDrive** : non disponibles. Les partages réseau Windows (SMB) restent accessibles par le menu **Aller → Réseau**.

## Erreurs et Diagnostic Néo

Chaque message d'erreur de Néo OS comporte :

- un **code** (par exemple `NEO-MAJ-101`) ;
- une **explication** ;
- une **solution**.

La liste complète est dans **Codes d'erreur** (menu → Aide), et dans le fichier `CODES-ERREUR.md`.

Le **Diagnostic Néo** (menu → Système) vérifie :

- **Affichage** : pilote, mode secours, erreurs Xorg et du pilote nouveau ;
- **Réseau** : câble, adresse, DNS, accès à Internet ;
- **Stockage** : espace, lecture seule, erreurs du disque, alertes SMART ;
- **Mémoire** : mémoire disponible, fermetures par earlyoom, zram ;
- **Mises à jour** : ancienneté, mises à jour en attente, redémarrage nécessaire, installation interrompue ;
- **Applications** : services en échec, plantages récents.

Une vérification impossible (droits insuffisants, outil absent) est signalée **« Indisponible »**. **Exporter le rapport…** enregistre un fichier texte à joindre à une demande d'aide. En terminal, utilisez `neo-diagnostic --texte`, ou `sudo neo-diagnostic --texte` pour lire tous les journaux.

Le diagnostic ne recherche que les situations répertoriées : il ne prévoit pas toutes les pannes.

## Discord

Menu → **Installer Discord** (ou Centre Néo) :

1. Le paquet officiel est téléchargé depuis **discord.com** en HTTPS.
2. Le nom du paquet et son éditeur (« Discord Maintainer Team », adresse `@discord.com`) sont vérifiés.
3. Le paquet est installé.

Au premier lancement, Discord télécharge son application (environ 100 Mo), puis se met à jour seul. **Discord ne démarre pas automatiquement** à l'ouverture de session. Vous pouvez l'activer vous-même dans les paramètres de Discord (« Ouvrir Discord au démarrage »).

Discord consomme plusieurs centaines de Mo de mémoire : fermez-le quand vous ne l'utilisez pas.

## Mémoire et performances

- **zram** : une partie de la RAM sert de mémoire d'échange compressée, bien plus rapide qu'un fichier d'échange sur le disque mécanique.
- **earlyoom** : si la mémoire vient à manquer, le programme le plus gourmand est fermé avant que l'ordinateur ne gèle (code NEO-MEM-002 dans le Diagnostic).
- **Disque mécanique** : ordonnanceur BFQ, option `noatime`, journal système limité, tâches de fond en priorité minimale.
- **Firefox** : 4 processus de contenu, onglets déchargés en cas de manque de mémoire, H.264 préféré à AV1 et VP9.

Pour mesurer la mémoire : `sudo neo-mesure --detail` donne la part réelle de chaque programme ; vous pouvez aussi consulter l'onglet Performances.

## Mises à jour

- Les **correctifs de sécurité** de Debian s'installent **automatiquement** chaque jour.
- Pour **tout** mettre à jour, y compris Discord : menu → **Mettre à jour le système**, ou `neo-maj`. En cas d'échec, un code `NEO-MAJ-1xx` explique la cause : pas de réseau, une autre installation en cours, disque plein…

## Pilote d'affichage

La Quadro FX 380 utilise le pilote libre **nouveau**. Quatre modes sont disponibles dans Centre Néo → **Pilote d'affichage**, ou avec `sudo neo-graphique <mode>` :

| Mode | Quand l'utiliser |
|---|---|
| `auto` | Mode par défaut : nouveau avec accélération. |
| `logiciel` | Plantages ou artefacts en 3D (OpenGL calculé par le processeur). |
| `sans-accel` | Écran figé ou qui clignote. |
| `secours` | Écran noir : pilote VESA générique. Lent, sans animations, et sans changement de résolution (RANDR désactivé). |

Le changement prend effet au redémarrage. Si l'écran reste noir, choisissez au démarrage **« Néo OS — dépannage » → « Affichage de secours »**.

## Récupération

- **Le système ne démarre plus** :
  1. Démarrez sur la clé USB Néo OS (touche **F9** au démarrage du HP Z200).
  2. Choisissez **Essayer Néo OS**.
  3. Dans un terminal, lancez `sudo neo-secours` : il permet de réinstaller GRUB, de revenir au mode d'affichage automatique ou d'ouvrir un terminal dans le système installé. Il n'efface aucune donnée.
- **Console de récupération** : menu GRUB → **Néo OS — dépannage** → **Console de récupération**.
- **Fichiers supprimés ou partition perdue** : `sudo testdisk` / `sudo photorec` depuis la clé.
- **Santé du disque** : `sudo smartctl -H /dev/sda`. Le Diagnostic signale aussi les alertes SMART du journal (NEO-STO-005).

Sauvegardez régulièrement vos documents sur une clé ou un disque externe.
