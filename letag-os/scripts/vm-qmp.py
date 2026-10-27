#!/usr/bin/python3
"""Pilotage d'une VM de test par QMP (utilisé par les tests de Letag OS).

  vm-qmp.py <socket> capture <fichier.png>
  vm-qmp.py <socket> touches <combinaison> [...]   ex. ret, tab, ctrl-alt-t, meta_l
  vm-qmp.py <socket> texte "<texte ASCII>"
  vm-qmp.py <socket> clic <x> <y> [largeur hauteur]  (coordonnées écran, tablette USB)
  vm-qmp.py <socket> quitter
"""
import json
import os
import socket
import subprocess
import sys
import tempfile
import time

# Disposition du clavier invité : Letag OS est en AZERTY (fr). Les touches
# envoyées par QMP sont physiques (positions QWERTY), d'où cette table.
AZERTY = {" ": "spc", "\n": "ret", "a": "q", "q": "a", "z": "w", "w": "z", "m": "semicolon",
          "&": "1", '"': "3", "'": "4", "(": "5", "-": "6", "_": "8", ")": "minus", "=": "equal",
          "+": "shift-equal", ",": "m", "?": "shift-m", ";": "comma", ".": "shift-comma",
          ":": "dot", "/": "shift-dot", "!": "slash", "<": "less", ">": "shift-less",
          "|": "alt_r-6", "#": "alt_r-3", "@": "alt_r-0", "\\": "alt_r-8", "$": "bracket_right",
          "*": "backslash", "{": "alt_r-4", "}": "alt_r-equal", "[": "alt_r-5", "]": "alt_r-minus"}
for _c in "0123456789":
    AZERTY[_c] = "shift-" + _c
QWERTY = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash", ",": "comma",
          "=": "equal", ";": "semicolon", "'": "apostrophe", "_": "shift-minus",
          ":": "shift-semicolon", '"': "shift-apostrophe", "|": "shift-backslash",
          ">": "shift-dot", "<": "shift-comma", "&": "shift-7", "*": "shift-8"}
CAR = QWERTY if os.environ.get("LETAG_VM_CLAVIER") == "us" else AZERTY


class QMP:
    def __init__(self, chemin):
        self.s = socket.socket(socket.AF_UNIX)
        self.s.connect(chemin)
        self.f = self.s.makefile("rw")
        self.f.readline()
        self.cmd("qmp_capabilities")

    def cmd(self, nom, **args):
        self.f.write(json.dumps({"execute": nom, "arguments": args}) + "\n")
        self.f.flush()
        while True:
            r = json.loads(self.f.readline())
            if "return" in r or "error" in r:
                if "error" in r:
                    raise RuntimeError(r["error"])
                return r["return"]


def touches(q, combo):
    keys = [{"type": "qcode", "data": k} for k in combo.split("-")]
    q.cmd("send-key", keys=keys, **{"hold-time": 80})
    time.sleep(0.15)


def main():
    q = QMP(sys.argv[1])
    action = sys.argv[2]
    if action == "capture":
        with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as t:
            ppm = t.name
        os.chmod(ppm, 0o666)
        q.cmd("screendump", filename=ppm)
        time.sleep(0.5)
        subprocess.run(["convert", ppm, sys.argv[3]], check=True)
        os.unlink(ppm)
    elif action == "touches":
        for c in sys.argv[3:]:
            touches(q, c)
    elif action == "texte":
        for ch in sys.argv[3]:
            if ch in CAR:
                touches(q, CAR[ch])
            elif ch.isupper():
                touches(q, "shift-" + CAR.get(ch.lower(), ch.lower()))
            else:
                touches(q, ch)
    elif action == "clic":
        x, y = int(sys.argv[3]), int(sys.argv[4])
        w = int(sys.argv[5]) if len(sys.argv) > 5 else 1024
        h = int(sys.argv[6]) if len(sys.argv) > 6 else 768
        ev = [{"type": "abs", "data": {"axis": "x", "value": x * 32767 // (w - 1)}},
              {"type": "abs", "data": {"axis": "y", "value": y * 32767 // (h - 1)}}]
        q.cmd("input-send-event", events=ev)
        time.sleep(0.1)
        for down in (True, False):
            q.cmd("input-send-event", events=[{"type": "btn", "data": {"down": down, "button": "left"}}])
            time.sleep(0.1)
    elif action == "quitter":
        q.cmd("quit")


if __name__ == "__main__":
    main()
