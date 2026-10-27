#!/usr/bin/python3
"""Assemble docs/UTILISATION.md et docs/INSTALLATION.md en un guide HTML
autonome (sans ressource externe) installé dans /usr/share/doc/letag/."""
import os
import sys

import markdown

DOCS = ["UTILISATION.md", "INSTALLATION.md"]
CSS = """
:root{--bg:#F3F3F1;--card:#fff;--ink:#1B1B1B;--sub:#6b6b67;--red:#E23B2E;--line:#e2e1dc}
@media (prefers-color-scheme:dark){:root{--bg:#1B1B1B;--card:#242423;--ink:#F3F3F1;--sub:#a5a5a0;--line:#333331}}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 Inter,system-ui,sans-serif}
main{max-width:860px;margin:0 auto;padding:32px 20px 64px}
h1{font-size:30px;letter-spacing:-.4px}
h1::before{content:"";display:inline-block;width:12px;height:12px;border-radius:50%;background:var(--red);margin-right:12px;vertical-align:middle}
h2{margin-top:2.2em;border-bottom:1px solid var(--line);padding-bottom:6px}
a{color:var(--red)}
code,pre{font-family:"DejaVu Sans Mono",monospace;font-size:14px}
pre{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px;overflow:auto}
table{border-collapse:collapse;width:100%;background:var(--card)}
td,th{border:1px solid var(--line);padding:6px 10px;text-align:left;vertical-align:top}
blockquote{margin:0;padding:8px 16px;border-left:4px solid var(--red);background:var(--card)}
hr{border:0;border-top:1px solid var(--line);margin:48px 0}
"""


def main(src, dest):
    parties = []
    for nom in DOCS:
        with open(os.path.join(src, nom), encoding="utf-8") as f:
            parties.append(markdown.markdown(f.read(), extensions=["tables", "fenced_code", "toc"]))
    html = ("<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
            "<title>Guide Letag OS</title><style>%s</style></head><body><main>%s</main></body></html>"
            % (CSS, "<hr>".join(parties)))
    with open(dest, "w", encoding="utf-8") as f:
        f.write(html)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
