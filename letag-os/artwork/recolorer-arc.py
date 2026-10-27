#!/usr/bin/env python3
"""Dérive les thèmes GTK/xfwm4 « Letag-Clair » et « Letag-Sombre » du thème Arc.

Arc (paquet Debian arc-theme, GPL-3) est léger et bien rendu sous XFCE, mais son
accent est bleu et ses gris sont bleutés. Ce script :
  * remplace l'accent bleu (#5294e2 et ses nuances) par le rouge Letag #E23B2E ;
  * désature les gris bleutés pour obtenir des neutres chauds ;
  * applique la même transformation au CSS, aux fichiers texte (gtkrc, xpm,
    themerc, svg) et aux PNG, y compris ceux des ressources compilées
    (gtk.gresource), qui sont extraites puis recompilées.

Usage : recolorer-arc.py <racine arc-theme extraite> <dossier de sortie>
Dépendances : python3, python3-pil, libglib2.0-bin (gresource, glib-compile-resources).
"""
import colorsys
import os
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

ACCENT_HUE = 4.5 / 360.0  # teinte de #E23B2E
VARIANTES = {
    # nom du thème Letag : (thème Arc source, nom affiché, sombre ?)
    "Letag-Clair": ("Arc-Lighter", "Letag clair", False),
    "Letag-Sombre": ("Arc-Dark", "Letag sombre", True),
}
# Ajouts CSS propres à Letag : étiquettes des icônes du bureau lisibles sur
# les fonds clair et sombre (xfdesktop les écrit en blanc ombré par défaut).
CSS_LETAG = """
/* --- Letag OS --- */
XfdesktopIconView.view.label {
  color: %(texte)s;
  text-shadow: none;
}
XfdesktopIconView.view.label:selected {
  color: #ffffff;
}
"""
TEXT_EXT = (".css", ".rc", ".xpm", ".svg", ".xml", "themerc", "gtkrc", ".theme")

_cache = {}


def transformer(r, g, b):
    """Transforme une couleur RVB (0-255) selon la palette Letag."""
    key = (r, g, b)
    if key in _cache:
        return _cache[key]
    h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
    deg = h * 360.0
    if 205.0 <= deg <= 235.0 and s >= 0.35:
        # Accent : #5294e2 (l=0.604) doit devenir exactement #E23B2E (l=0.533).
        decal = max(0.0, 1.0 - abs(l - 0.604) / 0.3)
        l = min(1.0, max(0.0, l + (0.533 - 0.604) * decal))
        s = min(1.0, s * 1.06)
        h = ACCENT_HUE
    elif 195.0 <= deg <= 245.0 and s < 0.35:
        # Gris bleuté -> gris neutre légèrement chaud.
        s = s * 0.25
        h = 45.0 / 360.0
    else:
        _cache[key] = key
        return key
    nr, ng, nb = colorsys.hls_to_rgb(h, l, s)
    res = (round(nr * 255), round(ng * 255), round(nb * 255))
    _cache[key] = res
    return res


def _hex6(m):
    v = m.group(1)
    r, g, b = int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)
    nr, ng, nb = transformer(r, g, b)
    if (nr, ng, nb) == (r, g, b):
        return m.group(0)
    return "#%02x%02x%02x" % (nr, ng, nb)


def _rgb(m):
    fn, r, g, b, reste = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4)), m.group(5)
    nr, ng, nb = transformer(r, g, b)
    return "%s(%d, %d, %d%s" % (fn, nr, ng, nb, reste)


RE_HEX = re.compile(r"#([0-9a-fA-F]{6})(?![0-9a-fA-F])")
RE_RGB = re.compile(r"\b(rgba?)\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*([,)])")


def recolorer_texte(chemin):
    with open(chemin, encoding="utf-8", errors="surrogateescape") as f:
        txt = f.read()
    nouveau = RE_RGB.sub(_rgb, RE_HEX.sub(_hex6, txt))
    if nouveau != txt:
        with open(chemin, "w", encoding="utf-8", errors="surrogateescape") as f:
            f.write(nouveau)


def recolorer_png(chemin):
    img = Image.open(chemin)
    mode = img.mode
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    change = False
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            n = transformer(r, g, b)
            if n != (r, g, b):
                px[x, y] = (n[0], n[1], n[2], a)
                change = True
    if change:
        if mode not in ("RGBA", "LA"):
            img = img.convert("RGBA")
        img.save(chemin)


def recolorer_arbre(racine):
    for dossier, _, fichiers in os.walk(racine):
        for nom in fichiers:
            p = os.path.join(dossier, nom)
            if os.path.islink(p):
                continue
            if nom.endswith(".png"):
                recolorer_png(p)
            elif nom.endswith(TEXT_EXT):
                recolorer_texte(p)


def recolorer_gresource(chemin):
    """Extrait une gtk.gresource, la recolore et la recompile au même endroit."""
    ressources = subprocess.run(["gresource", "list", chemin], check=True,
                                capture_output=True, text=True).stdout.split()
    with tempfile.TemporaryDirectory() as tmp:
        for r in ressources:
            dest = os.path.join(tmp, r.lstrip("/"))
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                f.write(subprocess.run(["gresource", "extract", chemin, r],
                                       check=True, capture_output=True).stdout)
        recolorer_arbre(tmp)
        xml = os.path.join(tmp, "letag.gresource.xml")
        with open(xml, "w") as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n<gresources>\n  <gresource prefix="/">\n')
            for r in ressources:
                f.write("    <file>%s</file>\n" % r.lstrip("/"))
            f.write("  </gresource>\n</gresources>\n")
        subprocess.run(["glib-compile-resources", "--sourcedir", tmp,
                        "--target", chemin, xml], check=True)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src_root, out_root = sys.argv[1], sys.argv[2]
    os.makedirs(out_root, exist_ok=True)
    for nom, (source, affiche, sombre) in VARIANTES.items():
        src = os.path.join(src_root, source)
        dst = os.path.join(out_root, nom)
        shutil.rmtree(dst, ignore_errors=True)
        shutil.copytree(src, dst, symlinks=True,
                        ignore=shutil.ignore_patterns("unity", "plank", "metacity-1"))
        recolorer_arbre(dst)
        for g in ("gtk-3.0/gtk.gresource", "gtk-4.0/gtk.gresource"):
            p = os.path.join(dst, g)
            if os.path.exists(p):
                recolorer_gresource(p)
        with open(os.path.join(dst, "gtk-3.0", "gtk.css"), "a") as f:
            f.write(CSS_LETAG % {"texte": "#F3F3F1" if sombre else "#1B1B1B"})
        with open(os.path.join(dst, "index.theme"), "w") as f:
            f.write("[Desktop Entry]\nType=X-GNOME-Metatheme\nName=%s\n"
                    "Comment=Thème Letag OS dérivé d'Arc (GPL-3.0)\nEncoding=UTF-8\n\n"
                    "[X-GNOME-Metatheme]\nGtkTheme=%s\nMetacityTheme=%s\n"
                    "IconTheme=%s\nCursorTheme=Adwaita\nButtonLayout=menu:minimize,maximize,close\n"
                    % (affiche, nom, nom, nom))
        print("thème généré :", dst, "(sombre)" if sombre else "(clair)")


if __name__ == "__main__":
    main()
