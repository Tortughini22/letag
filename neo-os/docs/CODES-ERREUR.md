# Codes d'erreur de Néo OS

Chaque message de Néo OS porte un code `NEO-<domaine>-<numéro>`. Le **Diagnostic Néo** (menu → Système, ou `neo-diagnostic`) détecte la plupart de ces situations et exporte un rapport. Ce fichier est généré depuis `/usr/local/lib/neo/neo_erreurs.py`.

## Affichage (AFF)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-AFF-001` | Avertissement | **Affichage de secours actif** — L'ordinateur utilise le pilote graphique générique VESA (option « nomodeset »). L'affichage fonctionne mais sans accélération : il est lent et la résolution peut être limitée. | Centre Néo → Pilote d'affichage → « Automatique », puis redémarrez. Si l'écran reste noir, redémarrez sur « Néo OS — dépannage » et essayez « Sans accélération ». |
| `NEO-AFF-002` | Erreur | **Pilote de la carte NVIDIA non chargé** — Une carte graphique NVIDIA est présente mais le pilote libre « nouveau » n'est pas actif. | Vérifiez qu'aucune option « nomodeset » ou « modprobe.blacklist=nouveau » n'est restée dans le menu de démarrage, puis choisissez « Automatique » dans le Centre Néo et redémarrez. |
| `NEO-AFF-003` | Avertissement | **Erreurs du serveur graphique** — Le journal du serveur d'affichage (Xorg) contient des erreurs. Certaines sont sans gravité, d'autres expliquent un écran figé ou une résolution incorrecte. | Si l'affichage est instable, choisissez « OpenGL logiciel » ou « Sans accélération » dans le Centre Néo. Joignez le rapport du Diagnostic si vous demandez de l'aide. |
| `NEO-AFF-004` | Information | **Animations désactivées en mode secours** — En affichage de secours, les animations et les ombres sont désactivées pour garder un affichage fluide sans accélération graphique. | Rien à faire : elles reviendront avec le pilote d'affichage automatique. |
| `NEO-AFF-005` | Avertissement | **Erreurs du pilote graphique « nouveau »** — Le noyau a signalé des erreurs de la carte graphique (blocage ou faute du processeur graphique). Elles peuvent provoquer des gels ou des artefacts à l'écran. | Centre Néo → Pilote d'affichage → « OpenGL logiciel », puis « Sans accélération » si le problème persiste. Redémarrez après chaque changement. |
| `NEO-AFF-006` | Information | **OpenGL logiciel actif** — Les calculs 3D sont faits par le processeur (llvmpipe) au lieu de la carte graphique. | C'est normal si vous avez choisi ce mode pour contourner des plantages. Sinon, revenez à « Automatique » dans le Centre Néo. |
| `NEO-AFF-010` | Erreur | **Changement de pilote d'affichage refusé** — Ce réglage modifie le menu de démarrage et demande les droits administrateur. | Relancez l'action et saisissez votre mot de passe quand il est demandé. |

## Réseau (RES)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-RES-001` | Erreur | **Aucune connexion réseau active** — Aucune carte réseau n'est connectée : le câble est peut-être débranché ou la box éteinte. | Vérifiez le câble Ethernet (voyants allumés sur la prise), redémarrez la box, puis cliquez sur l'icône réseau de la barre des tâches. |
| `NEO-RES-002` | Erreur | **Pas d'adresse réseau** — La carte réseau est connectée mais n'a pas reçu d'adresse IP de la box (DHCP). | Débranchez et rebranchez le câble, ou redémarrez la box. Icône réseau → « Modifier les connexions » si une adresse fixe est nécessaire. |
| `NEO-RES-003` | Erreur | **Noms de domaine introuvables (DNS)** — Le réseau local fonctionne mais les noms de sites (par exemple deb.debian.org) ne sont pas traduits en adresses. | Redémarrez la box. Si le problème persiste, indiquez un serveur DNS (par exemple 9.9.9.9) dans les paramètres de la connexion. |
| `NEO-RES-004` | Erreur | **Internet injoignable** — Les sites Internet ne répondent pas alors que le réseau local fonctionne. | Vérifiez la connexion de la box à Internet (voyants, autre appareil). Un pare-feu ou un proxy d'entreprise peut aussi bloquer l'accès. |
| `NEO-RES-005` | Erreur | **Service réseau arrêté** — NetworkManager, qui gère les connexions, ne fonctionne pas. | Dans un terminal : sudo systemctl restart NetworkManager, ou redémarrez l'ordinateur. |

## Stockage (STO)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-STO-001` | Avertissement | **Disque système presque plein** — Il reste moins de 10 % d'espace libre sur la partition du système. | Videz la corbeille et le dossier Téléchargements (triez par Taille dans l'explorateur pour repérer les gros fichiers). Dans un terminal, « sudo apt clean » supprime les paquets téléchargés. |
| `NEO-STO-002` | Erreur | **Disque système plein** — Il reste moins de 3 % d'espace libre : les mises à jour et l'enregistrement de fichiers peuvent échouer, et des programmes peuvent se bloquer. | Libérez de la place tout de suite (corbeille, Téléchargements, sudo apt clean), puis relancez le Diagnostic. |
| `NEO-STO-003` | Erreur | **Système de fichiers en lecture seule** — Le système a protégé le disque en interdisant l'écriture, en général après une erreur du disque. | Sauvegardez vos fichiers sur une clé USB, puis redémarrez. Si le problème revient, le disque est peut-être en fin de vie : voir NEO-STO-005. |
| `NEO-STO-004` | Erreur | **Erreurs de lecture ou d'écriture du disque** — Le noyau a enregistré des erreurs d'entrée/sortie sur un disque : câble, connecteur ou disque défaillant. | Sauvegardez vos données sans attendre. Vérifiez le câble SATA, puis consultez l'état SMART : sudo smartctl -a /dev/sda. |
| `NEO-STO-005` | Erreur | **Alerte de santé du disque (SMART)** — Le disque signale lui-même des secteurs défectueux ou une défaillance prévisible. | Sauvegardez immédiatement vos fichiers importants et prévoyez de remplacer le disque. |
| `NEO-STO-006` | Erreur | **Erreurs du système de fichiers** — Le système de fichiers ext4 a signalé des incohérences. | Redémarrez : la vérification automatique est faite au démarrage. Si elle échoue, démarrez sur la clé Néo OS et lancez « sudo neo-secours » (option terminal) puis fsck. |

## Mémoire (MEM)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-MEM-001` | Avertissement | **Mémoire disponible faible** — Moins de 10 % de la mémoire vive est disponible : l'ordinateur risque de ralentir. | Gestionnaire des tâches → « Libérer de la RAM » : fermez les applications que vous choisissez (onglets Firefox en trop, Discord, LibreOffice). |
| `NEO-MEM-002` | Avertissement | **Applications fermées pour éviter un blocage** — La mémoire était épuisée : earlyoom a fermé le programme le plus gourmand pour que l'ordinateur ne se fige pas. | Gardez moins d'onglets ou d'applications ouverts en même temps, et fermez Discord quand vous ne l'utilisez pas. |
| `NEO-MEM-003` | Erreur | **Le noyau a dû arrêter un programme** — La mémoire a été complètement épuisée et le noyau a arrêté un programme en urgence. | Même conseil que NEO-MEM-002 ; vérifiez aussi que zram est actif (NEO-MEM-004). |
| `NEO-MEM-004` | Avertissement | **Mémoire compressée (zram) inactive** — Le swap compressé en mémoire n'est pas actif : la mémoire disponible est plus faible. | Redémarrez. Si le problème persiste : sudo systemctl restart systemd-zram-setup@zram0. |
| `NEO-MEM-005` | Avertissement | **Mémoire d'échange presque pleine** — Plus de 80 % de la mémoire d'échange est utilisée. | Fermez des applications avec « Libérer de la RAM » dans le Gestionnaire des tâches. |

## Mises à jour (MAJ)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-MAJ-001` | Avertissement | **Vérification des mises à jour ancienne** — Les listes de mises à jour n'ont pas été rafraîchies depuis plus de 7 jours (ordinateur souvent hors ligne ou mises à jour automatiques bloquées). | Lancez « Mettre à jour le système » avec une connexion Internet. |
| `NEO-MAJ-002` | Information | **Mises à jour disponibles** — Des mises à jour sont prêtes à être installées. | Lancez « Mettre à jour le système ». |
| `NEO-MAJ-003` | Avertissement | **Redémarrage nécessaire** — Une mise à jour (noyau ou bibliothèque système) ne sera active qu'après un redémarrage. | Redémarrez l'ordinateur quand vous le pouvez. |
| `NEO-MAJ-004` | Erreur | **Installation de paquets interrompue** — Une mise à jour a été interrompue (coupure, arrêt forcé) : le gestionnaire de paquets doit terminer sa configuration. | Dans un terminal : sudo dpkg --configure -a, puis « Mettre à jour le système ». |
| `NEO-MAJ-005` | Erreur | **Échec des mises à jour automatiques** — La dernière installation automatique des correctifs de sécurité a échoué. | Lancez « Mettre à jour le système » pour voir le message détaillé. |
| `NEO-MAJ-101` | Erreur | **Serveurs de mise à jour injoignables** — Les dépôts Debian ne répondent pas : pas de connexion Internet, ou problème temporaire. | Vérifiez la connexion (Diagnostic → Réseau) puis réessayez. |
| `NEO-MAJ-102` | Erreur | **Une autre installation est en cours** — Le gestionnaire de paquets est déjà utilisé (mise à jour automatique en cours, par exemple). | Patientez quelques minutes puis réessayez. Ne redémarrez pas pendant une mise à jour. |
| `NEO-MAJ-103` | Erreur | **Espace disque insuffisant pour la mise à jour** — Il n'y a pas assez de place pour télécharger et installer les mises à jour. | Libérez de l'espace (voir NEO-STO-001) puis réessayez. |
| `NEO-MAJ-104` | Erreur | **La mise à jour a échoué** — Le gestionnaire de paquets a renvoyé une erreur. | Lisez le message affiché au-dessus, lancez « sudo dpkg --configure -a » puis réessayez. Le Diagnostic exporte un rapport utile pour demander de l'aide. |

## Applications (APP)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-APP-001` | Erreur | **Services système en échec** — Des services du système n'ont pas pu démarrer. | Redémarrez. Si le problème persiste, notez les noms affichés et consultez « journalctl -b -u <service> ». |
| `NEO-APP-002` | Avertissement | **Services de session en échec** — Des services de votre session (son, notifications…) n'ont pas pu démarrer. | Fermez la session et rouvrez-la. |
| `NEO-APP-003` | Avertissement | **Plantages récents d'applications** — Des programmes se sont arrêtés brutalement (erreur de segmentation) depuis le démarrage. | Relancez l'application. Si elle plante toujours, mettez le système à jour ; pour une application graphique 3D, essayez « OpenGL logiciel ». |

## Gestionnaire des tâches (TCH)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-TCH-001` | Avertissement | **Processus essentiel protégé** — Ce processus fait fonctionner votre session ou le système : l'arrêter fermerait la session, couperait le son ou l'affichage, ou rendrait l'ordinateur instable. | Si la session est bloquée, utilisez Ctrl + Alt + Suppr → « Se déconnecter » ou redémarrez. |
| `NEO-TCH-002` | Information | **Processus système** — Ce processus appartient au système ou à un autre utilisateur : il n'est pas arrêté depuis le Gestionnaire des tâches. | S'il pose problème, redémarrez l'ordinateur ou utilisez un terminal administrateur. |
| `NEO-TCH-003` | Avertissement | **Le programme ne répond pas** — L'application n'a pas fermé dans le délai imparti après la demande de fermeture. | Choisissez « Forcer l'arrêt » : les données non enregistrées de cette application seront perdues. |
| `NEO-TCH-004` | Information | **Processus déjà terminé** — Le processus s'est arrêté entre-temps. | Rien à faire. |

## Discord (DIS)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-DIS-001` | Erreur | **Téléchargement de Discord impossible** — Le site officiel discord.com n'a pas pu être joint. | Vérifiez la connexion Internet (Diagnostic → Réseau) puis réessayez. |
| `NEO-DIS-002` | Erreur | **Fichier Discord refusé** — Le fichier obtenu ne provient pas du site officiel de Discord ou n'est pas le paquet Discord attendu : il n'a pas été installé. | Réessayez plus tard. N'installez Discord que depuis discord.com. |
| `NEO-DIS-003` | Erreur | **Installation de Discord échouée** — Le paquet Discord n'a pas pu être installé (dépendance manquante ou installation interrompue). | Mettez le système à jour puis relancez « Installer Discord ». |

## Installation (INS)

| Code | Gravité | Problème | Que faire |
|---|---|---|---|
| `NEO-INS-001` | Information | **Installateur disponible depuis la clé uniquement** — L'installateur ne fonctionne que dans la session d'essai lancée depuis la clé USB ou le DVD. | Démarrez l'ordinateur sur la clé Néo OS (touche F9 sur le HP Z200). |

