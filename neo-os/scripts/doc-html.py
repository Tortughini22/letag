#!/usr/bin/python3
"""Pages d'aide HTML autonomes de Néo OS (installées dans /usr/share/doc/neo/) :
  guide.html         utilisation + installation (docs/UTILISATION.md, docs/INSTALLATION.md)
  raccourcis.html    fiche des raccourcis (depuis /usr/share/neo/raccourcis.tsv)
  codes-erreur.html  codes NEO-xxx-nnn (depuis le catalogue neo_erreurs.py)
Écrit aussi docs/RACCOURCIS.md et docs/CODES-ERREUR.md (mêmes sources).
Usage : doc-html.py <dossier docs> <dossier de sortie>"""
import os
import sys

import markdown

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(ICI, "live-build", "config", "includes.chroot")
sys.path.insert(0, os.path.join(INC, "usr", "local", "lib", "neo"))
import neo_erreurs  # noqa: E402

CSS = """
:root{--bg:#FEF9EB;--surface:#C6EBD4;--ink:#0F2B5B;--accent:#7DCDAD;--lien:#4478AF;--ligne:#D9DCD8}
@media (prefers-color-scheme:dark){:root{--bg:#0F2B5B;--surface:#25426A;--ink:#FEF9EB;--accent:#7DCDAD;--lien:#91D2BC;--ligne:#3A5478}}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 Inter,system-ui,sans-serif}
nav{background:var(--surface);padding:10px 20px;display:flex;gap:18px;flex-wrap:wrap}
nav a{color:var(--ink);font-weight:600;text-decoration:none}
nav a:hover{text-decoration:underline}
main{max-width:900px;margin:0 auto;padding:28px 20px 64px}
h1{font-size:30px;letter-spacing:-.4px}
h1::before{content:"";display:inline-block;width:12px;height:12px;border-radius:50%;background:var(--accent);margin-right:12px;vertical-align:middle}
h2{margin-top:2.2em;border-bottom:2px solid var(--accent);padding-bottom:6px}
a{color:var(--lien);text-decoration:underline}
code,pre,kbd{font-family:"DejaVu Sans Mono",monospace;font-size:14px}
kbd{background:var(--surface);border-radius:5px;padding:1px 6px;font-weight:bold}
pre{background:var(--surface);border-radius:10px;padding:12px 14px;overflow:auto}
table{border-collapse:collapse;width:100%}
td,th{border:1px solid var(--ligne);padding:6px 10px;text-align:left;vertical-align:top}
th{background:var(--surface)}
blockquote{margin:0;padding:8px 16px;border-left:4px solid var(--accent);background:var(--surface)}
"""
NAV = '<nav><a href="guide.html">Guide</a><a href="raccourcis.html">Raccourcis clavier</a><a href="codes-erreur.html">Codes d\'erreur</a></nav>'


def page(titre, corps):
    return ('<!doctype html><html lang="fr"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>'
            '<style>%s</style></head><body>%s<main>%s</main></body></html>' % (titre, CSS, NAV, corps))


def md(texte):
    return markdown.markdown(texte, extensions=["tables", "fenced_code", "toc"])


def raccourcis_md():
    sections = {"commande": "Applications et session", "xfwm4": "Fenêtres et bureaux",
                "natif": "Fichiers et édition"}
    lignes = {k: [] for k in sections}
    for l in open(os.path.join(INC, "usr/share/neo/raccourcis.tsv"), encoding="utf-8"):
        if l.startswith("#") or not l.strip():
            continue
        c = l.rstrip("\n").split("\t")
        lignes[c[0]].append(c)
    t = ["# Raccourcis clavier de Néo OS", "",
         "La touche **Windows** est la touche au logo Windows (aussi appelée Super). Cette fiche est "
         "générée depuis `/usr/share/neo/raccourcis.tsv`, la même liste que celle appliquée à l'ouverture "
         "de session ; dans Néo OS : menu → Raccourcis clavier.", ""]
    for k, nom in sections.items():
        t += ["## " + nom, "", "| Touches | Action |", "|---|---|"]
        t += ["| <kbd>%s</kbd> | %s |" % (c[3], c[4]) for c in lignes[k]]
        t.append("")
    return "\n".join(t)


def main(docs, sortie):
    os.makedirs(sortie, exist_ok=True)
    guide = "<hr>".join(md(open(os.path.join(docs, n), encoding="utf-8").read())
                        for n in ("UTILISATION.md", "INSTALLATION.md"))
    rac, codes = raccourcis_md(), neo_erreurs.markdown()
    for nom, contenu in (("RACCOURCIS.md", rac), ("CODES-ERREUR.md", codes)):
        with open(os.path.join(docs, nom), "w", encoding="utf-8") as f:
            f.write(contenu + "\n")
    for nom, titre, corps in (("guide.html", "Guide Néo OS", guide),
                              ("raccourcis.html", "Raccourcis clavier", md(rac)),
                              ("codes-erreur.html", "Codes d'erreur", md(codes))):
        with open(os.path.join(sortie, nom), "w", encoding="utf-8") as f:
            f.write(page(titre, corps))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
