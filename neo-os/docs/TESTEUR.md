# Néo OS 1.0 — Guide du testeur

Merci de tester Néo OS. Ce guide s'adresse à quelqu'un d'à l'aise avec Linux et l'installation d'un système. Il va droit au but.

**Néo OS**, c'est Debian 13 « trixie » avec XFCE 4.20, Xorg et le pilote nouveau, en français, en amd64 sans AVX. La cible est un **HP Z200 SFF** (i5-650, 4 Go, disque dur de 320 Go, Quadro FX 380 LP), mais toute machine x86-64 BIOS ou UEFI convient.

Les comptes rendus de VM viennent d'émulation QEMU sans KVM. **Rien n'a encore été testé sur du vrai matériel** : c'est justement l'objet de votre retour.

## 1. Ce que vous recevez

| Fichier | Rôle |
|---|---|
| `neo-os-1.0-amd64.iso` | image hybride (DVD ou clé USB, BIOS + UEFI), environ 1,2 Go |
| `neo-os-1.0-amd64.iso.sha256` | somme de contrôle |
| `TESTEUR.md` (ce guide) | procédure |
| `FICHE-RETOUR.md` | grille à remplir et à renvoyer |

Vérifiez l'image avant tout :

```
sha256sum -c neo-os-1.0-amd64.iso.sha256    # doit afficher : OK
```

## 2. Créer le support

- **Linux** : `sudo dd if=neo-os-1.0-amd64.iso of=/dev/sdX bs=4M conv=fsync status=progress`. Vérifiez `/dev/sdX` avec `lsblk` : la clé entière est écrasée.
- **Windows** : Rufus, en **mode Image DD**, ou balenaEtcher.
- **Ventoy** : non testé. Préférez `dd` pour éviter les faux problèmes.

## 3. Démarrer la session d'essai (live)

1. Sur le HP Z200, appuyez sur **F9** (menu de démarrage) ; **F10** ouvre le BIOS. Utilisez de préférence un port USB à l'arrière.
2. Le menu isolinux propose :
   - **Essayer Neo OS** : par défaut, démarrage automatique après 10 s ;
   - **Essayer - sans accélération graphique** : `nouveau.noaccel=1` ;
   - **Essayer - affichage de secours (VESA)** : `nomodeset` ;
   - **Essayer - chargé en mémoire vive (toram)** ;
   - **Mode sans échec**, puis la détection du matériel (HDT) et memtest86+.

   L'installation se lance depuis le bureau de la session d'essai.
3. La session s'ouvre seule. Compte `neo`, mot de passe `live`, avec sudo.

Si l'écran reste noir ou si l'affichage se fige, notez à quelle étape, puis essayez dans l'ordre l'entrée « sans accélération », puis « secours ». C'est une information essentielle.

La session live **ne touche pas** au disque interne : aucun montage automatique, aucun swap disque activé.

## 4. Installer (optionnel, sur un disque sans données précieuses)

1. Double-cliquez sur **Installer Néo OS** sur le bureau. Un écran liste les disques ; cochez « J'ai sauvegardé… ».
2. Dans Calamares, la page Partitions n'a **aucune option présélectionnée**. Les choix possibles : « Effacer le disque », « À côté », « Remplacer » ou « Manuel ». « Aucun swap » est recommandé, car zram est déjà actif.
3. Rien n'est écrit avant « Installer maintenant » sur le résumé.
4. L'installation se fait hors ligne. GRUB s'installe en BIOS (grub-pc) ou en UEFI selon le démarrage.
5. Au redémarrage, retirez la clé. Le menu GRUB contient un sous-menu **« Néo OS — dépannage »** : affichage de secours, sans accélération, console de récupération.

## 5. Quoi tester (environ 30 à 45 min)

Cochez au fur et à mesure dans `FICHE-RETOUR.md`.

**Démarrage et affichage**
- Temps du menu jusqu'au bureau (chronomètre), en live puis une fois installé.
- Pilote réellement utilisé : `Centre Néo → Affichage`, ou `glxinfo -B` et `grep -i nouveau /var/log/Xorg.0.log`.
- Artefacts, scintillements, gels ? Une vidéo YouTube 720p ou 1080p dans Firefox : fluide ou saccadée ?

**Bureau et apparence**
- Thèmes clair et sombre (Centre Néo) : écran de connexion, fenêtres, menus, notifications.
- Lisibilité générale, éléments mal contrastés, textes coupés.

**Animations** (Centre Néo → Animations : Complètes / Réduites / Désactivées)
- Ouverture, fermeture, réduction et restauration des fenêtres, menus, notifications : fluides ou saccadées ?
- En mode « affichage de secours », elles doivent être désactivées d'office.

**Raccourcis Windows** (fiche complète dans *Aide → Raccourcis clavier*)
- Win, Win+E, Win+R, Win+I, Win+L (installé uniquement), Win+D, Win+flèches, Alt+Tab, Alt+F4, Ctrl+Shift+Échap, Ctrl+Alt+Suppr, F2 dans l'explorateur, Ctrl+C/X/V/Z/A.

**Gestionnaire des tâches** (Ctrl+Shift+Échap)
- Onglets Processus, Performances et Démarrage. Graphiques CPU, RAM, disque, réseau et GPU. La GPU et la VRAM doivent afficher « Indisponible » avec nouveau.
- « Fin de tâche » sur une application, et refus sur un processus système.
- « Libérer de la RAM » : rien ne doit se fermer sans votre accord, et la RAM récupérée doit s'afficher.

**Explorateur (Thunar)** : barre d'adresse modifiable, accès rapide, clé USB branchée à chaud, copie avec conflit (remplacer, ignorer, garder les deux), corbeille, propriétés.

**Diagnostic** (menu → Diagnostic) : lancer l'analyse, puis **Exporter le rapport…**. **Joignez ce rapport à votre retour.**

**Réseau et logiciels** : Ethernet ; clé Wi-Fi si vous en avez une. Firefox. **Installer Discord** depuis le menu (téléchargé depuis discord.com) : se lance-t-il, et ne démarre-t-il pas seul à la session suivante ? Lancez **Mettre à jour le système**.

**Mémoire**, à mesurer après 2 minutes au repos, avec `free -m` et `sudo neo-mesure --detail` :
1. bureau seul, animations désactivées ;
2. bureau seul, animations complètes ;
3. Firefox ouvert sur 3 onglets, plus Discord connecté.

**Veille et arrêt** : redémarrage et extinction propres ; mise en veille et réveil si vous voulez.

## 6. Recueillir les journaux (en cas de problème)

Sur Néo OS, dans un terminal :

```
neo-diagnostic --exporter ~/diagnostic-neo.txt
sudo neo-mesure --detail > ~/memoire-neo.txt
journalctl -b -p warning --no-pager > ~/journal-neo.txt
cp /var/log/Xorg.0.log ~/xorg-neo.log 2>/dev/null
{ lspci -nnk; lsusb; lsblk -f; free -m; uname -a; } > ~/materiel-neo.txt
```

Sur une session live, copiez ces fichiers sur une seconde clé USB **avant d'éteindre** : la session live ne conserve rien. Pour un gel complet, utilisez Ctrl+Alt+F2, puis `journalctl -b -1` au démarrage suivant (système installé uniquement).

## 7. Renvoyer

Envoyez `FICHE-RETOUR.md` rempli, les fichiers de la section 6 et quelques photos ou captures (touche Impr. écran) de ce qui ne va pas.
