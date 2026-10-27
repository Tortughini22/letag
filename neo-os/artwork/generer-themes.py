#!/usr/bin/env python3
"""Génère les thèmes « Neo-Clair » et « Neo-Sombre » de Néo OS.

Palette imposée (exacte) :
  crème        #FEF9EB  fond principal du thème clair
  menthe clair #C6EBD4  panneaux et surfaces secondaires
  menthe       #7DCDAD  accents, sélections, progression
  vert d'eau   #91D2BC  survols, éléments complémentaires
  bleu         #4478AF  actions principales, liens, éléments actifs
  bleu marine  #0F2B5B  textes, éléments structurants, fond du thème sombre

Méthode :
  1. GTK 3/4 : base Arc (paquet Debian arc-theme, GPL-3). Chaque couleur des
     feuilles de style et des images compilées (gtk.gresource) est remplacée
     selon son rôle (accent, neutre, erreur…) par une couleur de la palette ou
     un mélange de deux couleurs de la palette (superposition).
  2. Une surcouche CSS fixe ensuite les rôles importants : sélection menthe
     avec texte marine, boutons principaux bleus à texte blanc, survol vert
     d'eau, liens bleus, panneaux menthe clair, infobulles marine, erreurs et
     avertissements distincts, relief discret (ombres légères, coins arrondis).
  3. xfwm4 : décorations de fenêtres dessinées ici (coins arrondis, boutons
     ronds), notifications (xfce4-notifyd) et contrastes calculés (WCAG 2.1).

Usage : generer-themes.py <racine arc-theme extraite> <dossier themes> <fichier contraste.md>
Dépendances : python3, python3-pil, libglib2.0-bin, libglib2.0-dev-bin.
"""
import colorsys
import os
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw

CREME = "#FEF9EB"
MENTHE_CLAIR = "#C6EBD4"
MENTHE = "#7DCDAD"
VERT_EAU = "#91D2BC"
BLEU = "#4478AF"
MARINE = "#0F2B5B"
BLANC = "#FFFFFF"
# Couleurs d'état (hors palette, volontairement distinctes pour rester
# identifiables ; toujours accompagnées d'une icône et d'un texte explicite).
ERREUR = "#B3261E"
ERREUR_SOMBRE = "#FFB4AB"
AVERT_FOND = "#F2C14E"
AVERT_TEXTE = "#7A4A00"
AVERT_SOMBRE = "#FFD27A"


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hexa(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)


def melange(a, b, t):
    """Superposition de b sur a avec l'opacité t (0..1)."""
    a, b = rgb(a), rgb(b)
    return hexa(tuple(a[i] * (1 - t) + b[i] * t for i in range(3)))


def luminance(h):
    def canal(c):
        c /= 255.0
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(h)
    return 0.2126 * canal(r) + 0.7152 * canal(g) + 0.0722 * canal(b)


def contraste(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# --- Correspondance des couleurs d'Arc vers la palette -------------------------

class Correspondance:
    def __init__(self, sombre, pour_images=False):
        self.sombre = sombre
        self.images = pour_images
        self.cache = {}

    def __call__(self, r, g, b):
        cle = (r, g, b)
        if cle not in self.cache:
            self.cache[cle] = rgb(self.calculer(r, g, b))
        return self.cache[cle]

    def calculer(self, r, g, b):
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        deg = h * 360.0
        # Accent bleu d'Arc (#5294e2 et nuances)
        if 195 <= deg <= 240 and s >= 0.35:
            if self.images:
                # cases cochées, boutons radio, interrupteurs : bleu « actif »
                return BLEU if l < 0.75 else MENTHE_CLAIR
            if l < 0.55:
                return BLEU
            if l < 0.70:
                return MENTHE
            if l < 0.82:
                return VERT_EAU
            return MENTHE_CLAIR
        # Rouges (erreurs, bouton fermer) et oranges/jaunes (avertissements)
        if s >= 0.40 and (deg < 15 or deg > 340):
            return (ERREUR_SOMBRE if self.sombre else ERREUR) if l < 0.75 else melange(ERREUR, CREME, 0.8)
        if s >= 0.40 and 15 <= deg < 65:
            return AVERT_SOMBRE if self.sombre else AVERT_FOND
        # Verts (réussite) : menthe
        if s >= 0.30 and 75 <= deg < 180:
            return MENTHE
        # Neutres : rampe entre marine et crème
        if not self.sombre:
            if l >= 0.94:
                return CREME
            if l >= 0.80:
                return melange(CREME, MARINE, 0.16)     # bordures
            if l >= 0.55:
                return melange(CREME, MARINE, 0.45)     # texte désactivé
            return MARINE                               # texte
        if l >= 0.75:
            return CREME                                # texte
        if l >= 0.55:
            return melange(MARINE, CREME, 0.55)         # texte atténué
        if l >= 0.33:
            return melange(MARINE, MENTHE_CLAIR, 0.22)  # survol, boutons
        if l >= 0.27:
            return melange(MARINE, MENTHE_CLAIR, 0.09)  # vues (léger relief)
        if l >= 0.22:
            return MARINE                               # fond principal
        return melange(MARINE, "#000000", 0.30)         # bordures, creux


def _hex6(f):
    def rempl(m):
        v = m.group(1)
        return hexa(f(int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)))
    return rempl


def _rgbx(f):
    def rempl(m):
        n = f(int(m.group(2)), int(m.group(3)), int(m.group(4)))
        return "%s(%d, %d, %d%s" % (m.group(1), n[0], n[1], n[2], m.group(5))
    return rempl


RE_HEX = re.compile(r"#([0-9a-fA-F]{6})(?![0-9a-fA-F])")
RE_RGB = re.compile(r"\b(rgba?)\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*([,)])")


def recolorer_texte(chemin, f):
    with open(chemin, encoding="utf-8", errors="surrogateescape") as fi:
        t = fi.read()
    n = RE_RGB.sub(_rgbx(f), RE_HEX.sub(_hex6(f), t))
    if n != t:
        with open(chemin, "w", encoding="utf-8", errors="surrogateescape") as fo:
            fo.write(n)


def recolorer_png(chemin, f):
    img = Image.open(chemin).convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a:
                n = f(r, g, b)
                px[x, y] = (n[0], n[1], n[2], a)
    img.save(chemin)


def recolorer_arbre(racine, f_css, f_img):
    for d, _, fichiers in os.walk(racine):
        for nom in fichiers:
            p = os.path.join(d, nom)
            if os.path.islink(p):
                continue
            if nom.endswith(".png"):
                recolorer_png(p, f_img)
            elif nom.endswith((".css", ".rc", ".svg", "gtkrc", ".xml")):
                recolorer_texte(p, f_css)


def recolorer_gresource(chemin, f_css, f_img):
    res = subprocess.run(["gresource", "list", chemin], check=True,
                         capture_output=True, text=True).stdout.split()
    with tempfile.TemporaryDirectory() as tmp:
        for r in res:
            dest = os.path.join(tmp, r.lstrip("/"))
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as fo:
                fo.write(subprocess.run(["gresource", "extract", chemin, r],
                                        check=True, capture_output=True).stdout)
        recolorer_arbre(tmp, f_css, f_img)
        xml = os.path.join(tmp, "neo.gresource.xml")
        with open(xml, "w") as fo:
            fo.write('<?xml version="1.0" encoding="UTF-8"?>\n<gresources>\n  <gresource prefix="/">\n')
            for r in res:
                fo.write("    <file>%s</file>\n" % r.lstrip("/"))
            fo.write("  </gresource>\n</gresources>\n")
        subprocess.run(["glib-compile-resources", "--sourcedir", tmp, "--target", chemin, xml], check=True)


# --- Surcouche CSS : rôles de la palette -------------------------------------

def couleurs(sombre):
    if sombre:
        return dict(
            fond=MARINE, texte=CREME, surface=melange(MARINE, MENTHE_CLAIR, 0.12),
            vue=melange(MARINE, MENTHE_CLAIR, 0.06), bordure=melange(MARINE, CREME, 0.22),
            attenue=melange(MARINE, CREME, 0.62), survol=melange(MARINE, VERT_EAU, 0.30),
            selection=MENTHE, texte_selection=MARINE, action=BLEU, texte_action=BLANC,
            lien=VERT_EAU, lien_visite=MENTHE_CLAIR, progression=MENTHE,
            erreur=ERREUR_SOMBRE, avert=AVERT_SOMBRE, info_fond=melange(MARINE, BLEU, 0.55),
            infobulle_fond=CREME, infobulle_texte=MARINE, ombre="rgba(0, 0, 0, 0.35)",
            barre=melange(MARINE, MENTHE_CLAIR, 0.12), case_bord=melange(MARINE, CREME, 0.55))
    return dict(
        fond=CREME, texte=MARINE, surface=MENTHE_CLAIR, vue=CREME,
        bordure=melange(CREME, MARINE, 0.16), attenue=melange(CREME, MARINE, 0.70),
        survol=VERT_EAU, selection=MENTHE, texte_selection=MARINE, action=BLEU,
        texte_action=BLANC, lien=BLEU, lien_visite=MARINE, progression=MENTHE,
        erreur=ERREUR, avert=AVERT_TEXTE, info_fond=MENTHE_CLAIR,
        infobulle_fond=MARINE, infobulle_texte=CREME, ombre="rgba(15, 43, 91, 0.16)",
        barre=MENTHE_CLAIR, case_bord=melange(CREME, MARINE, 0.55))


CSS_NEO = """
/* ===== Néo OS : rôles de la palette (ajouté après le thème de base) ===== */
@define-color neo_fond %(fond)s;
@define-color neo_texte %(texte)s;
@define-color neo_surface %(surface)s;
@define-color neo_selection %(selection)s;
@define-color neo_action %(action)s;
@define-color theme_bg_color %(fond)s;
@define-color theme_fg_color %(texte)s;
@define-color theme_base_color %(vue)s;
@define-color theme_text_color %(texte)s;
@define-color theme_selected_bg_color %(selection)s;
@define-color theme_selected_fg_color %(texte_selection)s;
@define-color error_color %(erreur)s;
@define-color warning_color %(avert)s;
@define-color link_color %(lien)s;

window, .background, dialog, messagedialog .dialog-vbox { background-color: %(fond)s; color: %(texte)s; }
.view, textview text, treeview.view, iconview, entry, spinbutton:not(.vertical), list, row { color: %(texte)s; }

/* Sélection : vert menthe, texte bleu marine (contraste 7,4:1) */
*:selected, selection, .view:selected, treeview.view:selected, iconview:selected,
row:selected, flowbox flowboxchild:selected, entry selection, textview text selection,
label selection, calendar:selected {
  background-color: %(selection)s; color: %(texte_selection)s; }
row:selected label, row:selected image, treeview.view:selected:focus { color: %(texte_selection)s; }

/* Survol : vert d'eau */
row:hover:not(:selected), button:hover:not(:active):not(:checked):not(:disabled):not(.suggested-action):not(.destructive-action),
modelbutton:hover, notebook > header tab:hover:not(:checked) {
  background-color: %(survol)s; color: %(texte)s; }

/* Boutons : relief discret */
button { border-radius: 7px; box-shadow: 0 1px 1px %(ombre)s; }
button:active, button:checked { box-shadow: inset 0 1px 2px %(ombre)s; }
button.flat, button.titlebutton, button.sidebar-button { box-shadow: none; }

/* Action principale : bleu, texte blanc (4,6:1) */
button.suggested-action, button.default:not(.flat), .suggested-action {
  background-image: none; background-color: %(action)s; color: %(texte_action)s;
  border-color: %(action)s; }
button.suggested-action:hover { background-color: shade(%(action)s, 1.08); color: %(texte_action)s; }
button.suggested-action label, button.suggested-action image { color: %(texte_action)s; }
button.destructive-action, button.destructive-action label { background-image: none; background-color: """ + ERREUR + """; color: #FFFFFF; border-color: """ + ERREUR + """; }

/* Boutons basculés (enfoncés) : menthe, texte marine */
button:checked:not(.flat):not(.suggested-action), stackswitcher button:checked, .linked > button:checked,
button.toggle:checked { background-image: none; background-color: %(selection)s; color: %(texte_selection)s; border-color: shade(%(selection)s, 0.85); }
button:checked label, button:checked image, stackswitcher button:checked label { color: %(texte_selection)s; }
button:checked:disabled, button:checked:disabled label { background-color: alpha(%(selection)s, 0.45); color: %(attenue)s; }

/* Cases à cocher et boutons radio non cochés : contour toujours visible */
check:not(:checked):not(:indeterminate), radio:not(:checked):not(:indeterminate) {
  -gtk-icon-source: none; min-width: 14px; min-height: 14px; border: 1px solid %(case_bord)s;
  background-color: %(vue)s; border-radius: 3px; }
radio:not(:checked):not(:indeterminate) { border-radius: 50%%; }
check:not(:checked):disabled, radio:not(:checked):disabled { opacity: 0.5; }

/* Éléments actifs : bleu */
switch:checked { background-color: %(action)s; border-color: %(action)s; }
notebook > header tab:checked { box-shadow: inset 0 -3px %(action)s; color: %(texte)s; }
entry:focus, spinbutton:focus, textview:focus { border-color: %(action)s; box-shadow: inset 0 0 0 1px %(action)s; }
stacksidebar row:selected, placessidebar row:selected { box-shadow: inset 3px 0 %(action)s; }

/* Liens */
*:link, link, button.link, label link { color: %(lien)s; }
*:visited, link:visited { color: %(lien_visite)s; }

/* Progression : menthe */
progressbar progress, levelbar block.filled, scale highlight, scale trough highlight {
  background-image: none; background-color: %(progression)s; border-color: shade(%(progression)s, 0.85); }
progressbar trough, levelbar trough, scale trough { background-color: %(bordure)s; }

/* Panneaux et surfaces secondaires : menthe clair */
headerbar, .titlebar:not(headerbar), toolbar.primary-toolbar, actionbar, searchbar,
.sidebar, placessidebar, placessidebar list, stacksidebar, .sidebar .view, .sidebar row,
paned > .sidebar, .thunar .sidebar, statusbar {
  background-color: %(surface)s; background-image: none; color: %(texte)s; border-color: %(bordure)s; }
headerbar label, headerbar .title, .sidebar label { color: %(texte)s; }
.sidebar row:selected, placessidebar row:selected, stacksidebar row:selected, .sidebar .view:selected,
.sidebar row:selected label { background-color: %(selection)s; color: %(texte_selection)s; }
.sidebar row:hover:not(:selected) { background-color: %(survol)s; }
separator { background-color: %(bordure)s; }
frame > border, .frame, scrolledwindow.frame { border-color: %(bordure)s; }

/* Menus et fenêtres surgissantes : fond plein, bordure fine, relief discret */
menu, .menu, .context-menu, popover, popover.background, .csd menu, .csd .menu {
  background-color: %(fond)s; color: %(texte)s; border: 1px solid %(bordure)s; padding: 4px; }
menu menuitem, .menu menuitem { border-radius: 5px; padding: 5px 10px; }
menu menuitem:hover, .menu menuitem:hover, menubar > menuitem:hover {
  background-color: %(selection)s; color: %(texte_selection)s; }
menu menuitem:hover label, menu menuitem:hover accelerator { color: %(texte_selection)s; }
menuitem accelerator { color: %(attenue)s; }
popover { border-radius: 10px; box-shadow: 0 4px 12px %(ombre)s; }

/* Infobulles : bleu marine / crème */
tooltip, tooltip.background, .tooltip { background-color: %(infobulle_fond)s; color: %(infobulle_texte)s;
  border-radius: 6px; border: none; }
tooltip label, tooltip * { color: %(infobulle_texte)s; }

/* Erreurs et avertissements : toujours avec icône et texte explicite */
.error, label.error { color: %(erreur)s; }
.warning, label.warning { color: %(avert)s; }
infobar.error > revealer > box, infobar.error .content, infobar.error {
  background-color: """ + ERREUR + """; color: #FFFFFF; }
infobar.warning > revealer > box, infobar.warning .content, infobar.warning {
  background-color: """ + AVERT_FOND + """; color: """ + MARINE + """; }
infobar.info > revealer > box, infobar.info .content, infobar.info, infobar.question > revealer > box {
  background-color: %(info_fond)s; color: %(texte)s; }
infobar.error label, infobar.error image { color: #FFFFFF; }
infobar.warning label, infobar.warning image { color: """ + MARINE + """; }
entry.error { border-color: %(erreur)s; box-shadow: inset 0 0 0 1px %(erreur)s; }

/* Bureau (xfdesktop) : étiquettes lisibles */
XfdesktopIconView.view.label { color: %(texte)s; text-shadow: none; background-color: alpha(%(fond)s, 0.85); border-radius: 5px; }
XfdesktopIconView.view.label:selected { background-color: %(selection)s; color: %(texte_selection)s; }

/* Menu des applications (Whisker) */
#whiskermenu-window { background-color: %(fond)s; border: 1px solid %(bordure)s; }
#whiskermenu-window treeview.view, #whiskermenu-window iconview { background-color: %(fond)s; }
#whiskermenu-window button.radio:checked, #whiskermenu-window button:checked { background-color: %(selection)s; color: %(texte_selection)s; }

/* Écran de connexion (lightdm-gtk-greeter) */
#login_window, #restart_dialog, #shutdown_dialog {
  background-color: %(fond)s; color: %(texte)s; border-radius: 14px;
  border: 1px solid %(bordure)s; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.30); padding: 6px; }
#login_window #content_frame, #login_window #buttonbox_frame { background-color: transparent; border: none; }
#login_window #user_combobox button, #login_window entry { border-radius: 8px; }
#login_window #login_button, #login_window #unlock_button { background-image: none; background-color: """ + BLEU + """;
  color: #FFFFFF; border-color: """ + BLEU + """; border-radius: 8px; }
#login_window #greeter_infobar { border-radius: 8px; }
#panel_window { background-color: %(barre)s; color: %(texte)s; }
#panel_window label, #panel_window menubar > menuitem { color: %(texte)s; }
"""

NOTIFY_CSS = """/* Néo OS — notifications (xfce4-notifyd) */
#XfceNotifyWindow {
  background-color: %(fond)s; color: %(texte)s;
  border: 1px solid %(bordure)s; border-radius: 12px; }
#XfceNotifyWindow:hover { border-color: %(selection)s; }
#XfceNotifyWindow label#summary { font-weight: bold; color: %(texte)s; }
#XfceNotifyWindow label#body { color: %(texte)s; }
#XfceNotifyWindow button { background-color: %(surface)s; color: %(texte)s; border-radius: 7px; }
#XfceNotifyWindow button:hover { background-color: %(survol)s; }
#XfceNotifyWindow progressbar progress { background-color: %(progression)s; }
#XfceNotifyWindow progressbar trough { background-color: %(bordure)s; }
/* Notification critique (erreurs) : bord rouge épais en plus de l'icône */
#XfceNotifyWindow.critical { border: 2px solid %(erreur)s; }
"""


# --- Décorations xfwm4 ---------------------------------------------------------

def dessiner_xfwm4(dossier, sombre):
    os.makedirs(dossier, exist_ok=True)
    c = couleurs(sombre)
    titre = rgb(c["fond"])
    bord = rgb(c["bordure"])
    H, R, B = 32, 9, 4   # hauteur de titre, rayon des coins, bordures

    def img(nom, w, h, dessin):
        for etat in ("active", "inactive"):
            im = Image.new("RGBA", (w, h), titre + (255,))
            dessin(ImageDraw.Draw(im), im, etat)
            im.save(os.path.join(dossier, "%s-%s.png" % (nom, etat)))

    def coin(gauche):
        def d(dr, im, etat):
            im.paste((0, 0, 0, 0), (0, 0, im.size[0], im.size[1]))
            boite = (0, 0, 2 * R + 2, H + R) if gauche else (-R - 3, 0, R - 1, H + R)
            dr.rounded_rectangle(boite, radius=R, fill=titre + (255,), outline=bord + (255,))
        return d

    def haut(dr, im, etat):
        dr.line((0, 0, im.size[0], 0), fill=bord + (255,))

    img("top-left", R, H, coin(True))
    img("top-right", R, H, coin(False))
    for i in range(1, 6):
        img("title-%d" % i, 2, H, haut)

    def cote(gauche):
        def d(dr, im, etat):
            x = 0 if gauche else B - 1
            dr.line((x, 0, x, im.size[1]), fill=bord + (255,))
        return d

    img("left", B, 4, cote(True))
    img("right", B, 4, cote(False))

    def bas(dr, im, etat):
        dr.line((0, B - 1, im.size[0], B - 1), fill=bord + (255,))

    img("bottom", 4, B, bas)

    def coin_bas(gauche):
        def d(dr, im, etat):
            x = 0 if gauche else B - 1
            dr.line((x, 0, x, B - 1), fill=bord + (255,))
            dr.line((0, B - 1, B, B - 1), fill=bord + (255,))
        return d

    img("bottom-left", B, B, coin_bas(True))
    img("bottom-right", B, B, coin_bas(False))

    # Boutons ronds (fermer : rouge, réduire : ambre, agrandir : menthe),
    # symbole visible au survol ; gris-vert pour une fenêtre inactive.
    couleurs_btn = {"close": "#E06C64", "hide": AVERT_FOND, "maximize": MENTHE,
                    "maximize-toggled": MENTHE}
    inactif = melange(c["fond"], MARINE if not sombre else CREME, 0.22)
    W, D = 24, 14
    for nom, coul in couleurs_btn.items():
        for etat in ("active", "inactive", "prelight", "pressed"):
            im = Image.new("RGBA", (W, H), titre + (255,))
            dr = ImageDraw.Draw(im)
            x0, y0 = (W - D) // 2, (H - D) // 2
            remplissage = rgb(inactif) if etat == "inactive" else rgb(coul)
            if etat == "pressed":
                remplissage = tuple(int(v * 0.82) for v in remplissage)
            dr.ellipse((x0, y0, x0 + D, y0 + D), fill=remplissage + (255,),
                       outline=tuple(int(v * 0.85) for v in remplissage) + (255,))
            if etat in ("prelight", "pressed"):
                g = rgb(MARINE) + (255,)
                cx, cy = x0 + D / 2, y0 + D / 2
                if nom == "close":
                    dr.line((cx - 3, cy - 3, cx + 3, cy + 3), fill=g, width=2)
                    dr.line((cx - 3, cy + 3, cx + 3, cy - 3), fill=g, width=2)
                elif nom == "hide":
                    dr.line((cx - 4, cy, cx + 4, cy), fill=g, width=2)
                elif nom == "maximize":
                    dr.line((cx - 4, cy, cx + 4, cy), fill=g, width=2)
                    dr.line((cx, cy - 4, cx, cy + 4), fill=g, width=2)
                else:
                    dr.rectangle((cx - 3, cy - 3, cx + 3, cy + 3), outline=g, width=2)
            im.save(os.path.join(dossier, "%s-%s.png" % (nom, etat)))
    # Bouton menu (icône de l'application dessinée par xfwm4) et autres
    for nom in ("menu", "shade", "stick"):
        for etat in ("active", "inactive", "prelight", "pressed"):
            Image.new("RGBA", (W, H), titre + (255,)).save(os.path.join(dossier, "%s-%s.png" % (nom, etat)))
    with open(os.path.join(dossier, "themerc"), "w") as f:
        f.write("""# Néo OS — décorations xfwm4 (générées par generer-themes.py)
button_offset=6
button_spacing=2
show_app_icon=true
full_width_title=true
title_vertical_offset_active=0
title_vertical_offset_inactive=0
title_shadow_active=false
title_shadow_inactive=false
active_text_color=%s
inactive_text_color=%s
title_horizontal_offset=4
""" % (c["texte"], c["attenue"]))


# --- Programme principal -----------------------------------------------------

VARIANTES = {
    "Neo-Clair": ("Arc-Lighter", "Néo clair", False),
    "Neo-Sombre": ("Arc-Dark", "Néo sombre", True),
}


def rapport_contraste(chemin):
    lignes = [
        ("Texte marine sur crème (fond principal clair)", MARINE, CREME),
        ("Texte marine sur menthe clair (panneaux, barre)", MARINE, MENTHE_CLAIR),
        ("Texte marine sur menthe (sélection)", MARINE, MENTHE),
        ("Texte marine sur vert d'eau (survol)", MARINE, VERT_EAU),
        ("Texte blanc sur bleu (bouton principal)", BLANC, BLEU),
        ("Lien bleu sur crème", BLEU, CREME),
        ("Lien bleu sur menthe clair", BLEU, MENTHE_CLAIR),
        ("Texte crème sur marine (thème sombre)", CREME, MARINE),
        ("Lien vert d'eau sur marine (thème sombre)", VERT_EAU, MARINE),
        ("Menthe sur marine (accent, thème sombre)", MENTHE, MARINE),
        ("Texte crème sur surface sombre", CREME, melange(MARINE, MENTHE_CLAIR, 0.12)),
        ("Infobulle crème sur marine", CREME, MARINE),
        ("Texte d'erreur sur crème", ERREUR, CREME),
        ("Texte blanc sur fond d'erreur", BLANC, ERREUR),
        ("Texte marine sur fond d'avertissement", MARINE, AVERT_FOND),
        ("Texte d'avertissement sur crème", AVERT_TEXTE, CREME),
        ("Erreur claire sur marine (thème sombre)", ERREUR_SOMBRE, MARINE),
        ("Avertissement clair sur marine (thème sombre)", AVERT_SOMBRE, MARINE),
        ("Texte atténué sur crème", melange(CREME, MARINE, 0.70), CREME),
        ("Texte blanc sur menthe (non utilisé : insuffisant)", BLANC, MENTHE),
        ("Bleu sur marine (non utilisé pour du texte)", BLEU, MARINE),
    ]
    with open(chemin, "w", encoding="utf-8") as f:
        f.write("# Contrastes de la palette Néo OS\n\n"
                "Calculés par `artwork/generer-themes.py` selon WCAG 2.1. Seuils : **4,5:1** pour le "
                "texte courant (AA), **3:1** pour le grand texte et les éléments graphiques.\n\n"
                "| Combinaison | Couleurs | Rapport | Texte courant (AA) |\n|---|---|---|---|\n")
        for nom, a, b in lignes:
            r = contraste(a, b)
            verdict = "✅" if r >= 4.5 else ("⚠️ grand texte / graphique seulement" if r >= 3 else "❌ non utilisé pour du texte")
            f.write("| %s | `%s` sur `%s` | %.2f:1 | %s |\n" % (nom, a.upper(), b.upper(), r, verdict))
    print("contrastes :", chemin)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    src_root, out_root, rapport = sys.argv[1:4]
    os.makedirs(out_root, exist_ok=True)
    for nom, (source, affiche, sombre) in VARIANTES.items():
        dst = os.path.join(out_root, nom)
        shutil.rmtree(dst, ignore_errors=True)
        shutil.copytree(os.path.join(src_root, source), dst, symlinks=True,
                        ignore=shutil.ignore_patterns("unity", "plank", "metacity-1", "xfwm4", "cinnamon", "gnome-shell"))
        f_css, f_img = Correspondance(sombre), Correspondance(sombre, pour_images=True)
        recolorer_arbre(dst, f_css, f_img)
        for g in ("gtk-3.0/gtk.gresource", "gtk-4.0/gtk.gresource"):
            p = os.path.join(dst, g)
            if os.path.exists(p):
                recolorer_gresource(p, f_css, f_img)
        c = couleurs(sombre)
        for g in ("gtk-3.0/gtk.css", "gtk-4.0/gtk.css"):
            p = os.path.join(dst, g)
            if os.path.exists(p):
                with open(p, "a") as fo:
                    fo.write(CSS_NEO % c)
        notif = os.path.join(dst, "xfce-notify-4.0")
        os.makedirs(notif, exist_ok=True)
        with open(os.path.join(notif, "gtk.css"), "w") as fo:
            fo.write(NOTIFY_CSS % c)
        dessiner_xfwm4(os.path.join(dst, "xfwm4"), sombre)
        with open(os.path.join(dst, "index.theme"), "w") as fo:
            fo.write("[Desktop Entry]\nType=X-GNOME-Metatheme\nName=%s\n"
                     "Comment=Thème Néo OS (palette Néo), dérivé d'Arc (GPL-3.0)\nEncoding=UTF-8\n\n"
                     "[X-GNOME-Metatheme]\nGtkTheme=%s\nMetacityTheme=%s\nIconTheme=%s\n"
                     "CursorTheme=Adwaita\nButtonLayout=menu:minimize,maximize,close\n"
                     % (affiche, nom, nom, "Neo-Sombre" if sombre else "Neo"))
        print("thème généré :", dst)
    rapport_contraste(rapport)


if __name__ == "__main__":
    main()
