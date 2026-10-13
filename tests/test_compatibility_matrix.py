#!/usr/bin/env python3
"""Synthetic compatibility matrix for visible Ren'Py source layouts.

No DDLC/template game files or assets are copied. Every fixture below is original,
minimal test text intended only to exercise DDAC source discovery and literal mapping.
"""
import importlib.util
import os
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "UnRen-DDAC-v145-python.py")
SPEC = importlib.util.spec_from_file_location("ddac_v145_matrix", SOURCE)
DDAC = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DDAC)

FIXTURES = {
    "classic_layout": {
        "game/script.rpy": '''define e = Character("Emily")
label start:
    e "Hello, {i}friend{/i}!"
    "A line of narration."
    menu:
        "Choose one":
            "Stay here":
                $ choice = "stay"
''',
        "game/screens.rpy": '''screen quick_menu():
    textbutton "Save" action ShowMenu("save")
''',
    },
    "template_python2_layout": {
        "game/definitions.rpy": '''define m = Character("Monika")
define s = Character("Sayori")
''',
        "game/poemresponses.rpy": '''label poemresponse_start:
    m "I {i}really{/i} like your poem."
''',
        "game/poemwords.txt": "dream\nhope\n",
    },
    "template_python3_layout": {
        "game/script.rpy": '''label start:
    "Welcome back, [player]..."
    $ score = 100
    e "You scored %(score)d points."
screen score_display():
    text "%s points" % score''',
        "game/py/poemwords_ren.py": '''"""renpy
label poem_word_bank:
    "A quiet moon."
"""
''',
        "game/definitions_ren.py": '''"""renpy
define e = Character("Emily")
"""
''',
    },
    "reorganized_nested_layout": {
        "game/addons/custom/story.rpy": '''label addon_story:
    "An add-on line."
''',
        "game/py/custom_text_ren.py": '''"""renpy
label custom_text:
    "A line in a modern _ren.py file."
"""
''',
        "game/poems/custom_poem.rpy": '''label poem_custom:
    "A small poem."
''',
    },
}

EXPECTED = {
    "classic_layout": {"Hello, {i}friend{/i}!", "A line of narration.", "Choose one", "Stay here", "Save", "Emily"},
    "template_python2_layout": {"Monika", "Sayori", "I {i}really{/i} like your poem."},
    "template_python3_layout": {"Welcome back, [player]...", "A quiet moon.", "Emily", "You scored %(score)d points.", "%s points"},
    "reorganized_nested_layout": {"An add-on line.", "A line in a modern _ren.py file.", "A small poem."},
}


def run():
    failures = []
    checks = 0
    with tempfile.TemporaryDirectory(prefix="ddac-compat-matrix-") as root:
        for profile, files in FIXTURES.items():
            project = os.path.join(root, profile)
            game = os.path.join(project, "game")
            for rel, contents in files.items():
                full = os.path.join(project, *rel.split("/"))
                os.makedirs(os.path.dirname(full), exist_ok=True)
                with open(full, "w", encoding="utf-8", newline="") as stream:
                    stream.write(contents)
            candidates = DDAC.coletar_candidatos_extracao(game)
            rel_candidates = {os.path.relpath(path, game).replace(os.sep, "/") for path in candidates}
            expected_files = {rel[len("game/"):] for rel in files}
            checks += 1
            if not expected_files.issubset(rel_candidates):
                failures.append("{}: source discovery missed {}".format(profile, sorted(expected_files - rel_candidates)))
            found = set()
            for path in candidates:
                _, entries = DDAC.extrair_arquivo_com_mapa(path, set(), {}, {}, {})
                for entry in entries:
                    original = entry.get("original", "")
                    # Compare the actual literal value, not its quote style.
                    try:
                        value = DDAC.decodificar_literal_traducao(original)
                    except Exception:
                        value = original.strip("\\\"'")
                    found.add(value)
            checks += len(EXPECTED[profile])
            for wanted in EXPECTED[profile] - found:
                failures.append("{}: missing expected translatable literal {!r}".format(profile, wanted))
    print("COMPATIBILITY MATRIX: {} checks; {} failure(s)".format(checks, len(failures)))
    for failure in failures:
        print("FAIL: " + failure)
    if failures:
        return 1
    print("PASS: classic, Python 2 template shape, Python 3/_ren.py shape, nested/add-on layout")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())