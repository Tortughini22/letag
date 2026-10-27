# Installer Néo OS

## 1. Préparer le support

L'image `neo-os-1.0-amd64.iso` est **hybride** : elle démarre gravée sur DVD ou copiée sur une clé USB, en mode BIOS (cas du HP Z200) comme en UEFI.

Vérifiez d'abord l'image :

```
sha256sum -c neo-os-1.0-amd64.iso.sha256
```

### Clé USB (4 Go minimum) — tout son contenu sera remplacé

**Sous Linux**, avec le script fourni, qui refuse les disques non amovibles et demande confirmation :

```
sudo ./scripts/creer-cle-usb.sh neo-os-1.0-amd64.iso /dev/sdX
```

ou manuellement (vérifiez trois fois `/dev/sdX` avec `lsblk` : une erreur efface le mauvais disque) :

```
sudo dd if=neo-os-1.0-amd64.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

**Sous Windows** : [Rufus](https://rufus.ie) → sélectionner l'ISO → quand Rufus le demande, choisir **« Écrire en mode Image DD »**. balenaEtcher convient aussi.

### DVD

L'image tient sur un DVD simple couche (4,7 Go). Gravez-la **en tant qu'image** (« Graver l'image disque »), pas en tant que fichier. Le démarrage depuis DVD est plus lent que depuis une clé USB 2.0.

## 2. Démarrer le HP Z200

1. Branchez la clé sur un port USB **à l'arrière** (directement sur la carte mère), ou insérez le DVD.
2. Allumez et appuyez plusieurs fois sur **F9** (menu de démarrage) et choisissez la clé USB ou le lecteur DVD.
   Si la clé n'apparaît pas : **F10** (Computer Setup) → Storage → Boot Order, vérifiez que les périphériques USB sont autorisés et placés avant le disque dur.
3. Le menu **Néo OS** apparaît. **Essayer Néo OS** démarre seul après 10 secondes.
4. En cas d'écran noir, redémarrez et choisissez **Essayer — affichage sans accélération**, puis **Essayer — affichage de secours** si nécessaire.

La session d'essai ne modifie **pas** le disque dur. L'utilisateur est `neo` et le mot de passe `live`.

> Le Z200 n'offre que le démarrage BIOS (« Legacy »). Le système s'installe donc avec GRUB en mode BIOS, sans accès Internet nécessaire.

## 3. Installer

Double-cliquez sur **Installer Néo OS** sur le bureau. Pendant la session d'essai, l'écran ne se verrouille pas. Un écran de sécurité liste les disques détectés et rappelle ce que fait chaque mode. Il faut cocher « J'ai sauvegardé… » pour ouvrir l'installateur.

L'installateur (Calamares) demande :

1. **Langue, lieu, clavier** — français, Europe/Paris et AZERTY sont proposés d'office.
2. **Partitions** — **aucune option n'est présélectionnée** :
   - **Installer à côté** : partage le disque avec un système existant (Windows…), dont les fichiers sont conservés. Faites quand même une sauvegarde : un redimensionnement interrompu (coupure de courant) peut abîmer les données.
   - **Remplacer une partition** : seule la partition choisie est effacée.
   - **Partitionnement manuel** : contrôle complet. Réutilisez une partition `/home` existante **sans** cocher « Formater » pour garder vos fichiers.
   - **Effacer le disque** : supprime **tout** le contenu du disque choisi.
   - **Swap** : « Aucun Swap » (choix par défaut) est recommandé (la mémoire d'échange compressée zram est déjà active). « Fichier d'échange » ajoute une réserve sur le disque, plus lente.
3. **Utilisateur** — nom, mot de passe (il sert aussi pour les tâches d'administration via `sudo`), nom de l'ordinateur.
4. **Résumé** — toutes les modifications du disque sont listées. **Rien n'est écrit avant de cliquer sur « Installer ».**

L'installation copie le système de la clé vers le disque, installe GRUB sur le disque choisi, puis retire les outils propres à la session d'essai. Elle ne demande pas d'accès Internet. La durée sur le HP reste à mesurer : en machine virtuelle émulée, sans accélération, elle a pris environ 30 minutes.

Retirez la clé au redémarrage.

## 4. Après l'installation

- Ouvrez **Centre Néo** pour choisir le thème clair ou sombre et vérifier le pilote d'affichage.
- Branchez le câble réseau, puis lancez **Mettre à jour le système**.
- Les autres systèmes présents (Windows, autre Linux) apparaissent dans le menu GRUB.

## 5. Espace et partitions conseillées (disque de 320 Go)

| Partition | Taille | Rôle |
|---|---|---|
| `/` (ext4) | 40 Go | Système et logiciels (3,2 Go utilisés juste après l'installation) |
| `/home` (ext4) | le reste | Vos documents, séparés du système : une réinstallation peut les conserver |

Une partition unique `/` (choix des modes guidés) fonctionne aussi très bien.
