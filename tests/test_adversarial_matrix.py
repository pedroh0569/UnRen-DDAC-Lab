#!/usr/bin/env python3
"""Adversarial regression tests for visible-source extraction and reinjection.

All files are original synthetic fixtures; no DDLC/template content or assets.
"""
import importlib.util
import os
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "UnRen-DDAC-v145-python.py")
SPEC = importlib.util.spec_from_file_location("ddac_v145_adversarial", SOURCE)
DDAC = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DDAC)


def write(path, data, encoding="utf-8", newline=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding=encoding, newline=newline) as f:
        f.write(data)


def values(entries):
    out = []
    for e in entries:
        try:
            out.append(DDAC.decodificar_literal_traducao(e["original"]))
        except Exception:
            out.append(e["original"])
    return out


def run():
    checks = 0
    failures = []
    with tempfile.TemporaryDirectory(prefix="ddac-adversarial-") as tmp:
        game = os.path.join(tmp, "game")
        os.makedirs(game)

        # 1: Nested supported extensions; ignored/generated folders must not leak in.
        write(os.path.join(game, "script.rpy"), 'label start:\n    "Texto visível"\n')
        write(os.path.join(game, "nested", "module.rpym"), 'init -2:\n    "Módulo visível"\n')
        write(os.path.join(game, "nested", "notes.txt"), 'dream, 1, 0.5, 0.2\nhope, 1, 0.5, 0.2\n')
        for folder in ("tl", "cache", ".git", "__pycache__"):
            write(os.path.join(game, folder, "hidden.rpy"), 'label start:\n    "Não extrair"\n')
        write(os.path.join(game, "DDAC_generated.rpy"), 'label start:\n    "Gerado"\n')
        candidates = DDAC.coletar_candidatos_extracao(game)
        rels = {os.path.relpath(p, game).replace(os.sep, "/") for p in candidates}
        checks += 1
        expected = {"script.rpy", "nested/module.rpym", "nested/notes.txt"}
        if not expected.issubset(rels): failures.append("discovery: faltou arquivo suportado: " + repr(expected - rels))
        if any(any(seg in rel.split("/") for seg in ("tl", "cache", ".git", "__pycache__")) for rel in rels):
            failures.append("discovery: entrou arquivo de pasta ignorada")
        if any(os.path.basename(rel).startswith(DDAC.PREFIXO) for rel in rels): failures.append("discovery: entrou arquivo gerado")

        # 2: Comments/code strings are not mistaken for player-facing dialogue.
        f = os.path.join(game, "adversarial.rpy")
        src = ('# "Comentário que não deve ser extraído"\r\n'
               'init python:\r\n'
               '    debug = "String técnica interna"\r\n'
               '    renpy.notify("Notificação visível")\r\n'
               'label start:\r\n'
               '    e "Oi [player], {i}amigo{/i}! %(score)d"\r\n'
               '    menu:\r\n'
               '        "Escolha" if score > 0:\r\n'
               '            "Continuar":\r\n'
               '                $ selected = "go"\r\n')
        write(f, src, newline="")
        _, entries = DDAC.extrair_arquivo_com_mapa(f, set(), {}, {}, {})
        found = set(values(entries))
        checks += 1
        for want in ("Notificação visível", "Oi [player], {i}amigo{/i}! %(score)d", "Escolha", "Continuar"):
            if want not in found: failures.append("extract: faltou literal esperado " + repr(want))
        for unwanted in ("Comentário que não deve ser extraído", "String técnica interna"):
            if unwanted in found: failures.append("extract: falso positivo " + repr(unwanted))

        # 3: Reinject a translation and assert code/tags/variables remain untouched.
        dialogue = next((e for e in entries if "Oi [player]" in values([e])[0]), None)
        checks += 1
        if dialogue is None:
            failures.append("reinject: não localizou fala principal")
        else:
            translated, errors = DDAC.reinjetar_arquivo(f, [dialogue], ['"Olá [player], {i}amigo{/i}! %(score)d"'])
            checks += 1
            if errors or translated is None:
                failures.append("reinject: falhou tradução de literal dinâmico: " + repr(errors))
            else:
                result = "".join(translated)
                for token in ("[player]", "{i}", "{/i}", "%(score)d", "$ selected = \"go\"", "score > 0"):
                    if token not in result: failures.append("reinject: perdeu código/token " + repr(token))
                if "Olá [player]" not in result: failures.append("reinject: tradução não aplicada")
                if "Oi [player]" not in result: checks += 1

        # 4: Stale source must be rejected, not silently overwritten.
        stale = os.path.join(game, "stale.rpy")
        write(stale, 'label start:\n    "Original"\n')
        _, stale_map = DDAC.extrair_arquivo_com_mapa(stale, set(), {}, {}, {})
        write(stale, 'label start:\n    "Alterado manualmente"\n')
        _, errors = DDAC.reinjetar_arquivo(stale, stale_map, ['"Tradução"'])
        checks += 1
        if not errors: failures.append("safety: mapa desatualizado não foi rejeitado")

        # 5: Translation count mismatch must fail closed.
        stable = os.path.join(game, "stable.rpy")
        write(stable, 'label start:\n    "Um"\n    "Dois"\n')
        _, stable_map = DDAC.extrair_arquivo_com_mapa(stable, set(), {}, {}, {})
        _, errors = DDAC.reinjetar_arquivo(stable, stable_map, [])
        checks += 1
        if not errors: failures.append("safety: contagem de traduções incorreta não foi rejeitada")

        # 6: Empty, comments-only and malformed source should not crash discovery/extraction.
        for name, content in (("empty.rpy", ""), ("comments_only.rpy", '# "Não extrair"\n'),
                              ("broken.rpy", 'label start\n    "String sem fechamento\n    $ value =\n')):
            p = os.path.join(game, name)
            write(p, content)
            try:
                DDAC.extrair_arquivo_com_mapa(p, set(), {}, {}, {})
                checks += 1
            except Exception as exc:
                failures.append("robustness: crash em {}: {}: {}".format(name, type(exc).__name__, exc))

        # 7: Unicode (including accents) survives a read/extract cycle.
        uni = os.path.join(game, "unicode.rpy")
        write(uni, 'label start:\n    "Coração, ação, maçã — 日本語"\n')
        _, uni_entries = DDAC.extrair_arquivo_com_mapa(uni, set(), {}, {}, {})
        checks += 1
        if "Coração, ação, maçã — 日本語" not in values(uni_entries):
            failures.append("unicode: literal Unicode não preservado")

        # 8: Percent-format compatibility. Keep source placeholders that survive
        # translation, but escape literal percent signs newly present in output.
        percent_cases = [
            ("Score: %s", "Pontuação: %s", "Pontuação: %s"),
            ("Score: %(score)d", "Pontuação: %(score)d", "Pontuação: %(score)d"),
            ("Value %04d and %A", "Valor %04d e data %A", "Valor %04d e data %A"),
            ("Value %s, then %s", "Valor %s, depois %s", "Valor %s, depois %s"),
            ("Progress: 100% complete", "Progresso: 100% concluído", "Progresso: 100%% concluído"),
            ("No percentage here", "Agora há 25% de progresso", "Agora há 25%% de progresso"),
            ("Literal %% percent", "Percentual literal %%", "Percentual literal %%"),
            ("Progress: 100% complete", "Progress: 100% complete", "Progress: 100% complete"),
        ]
        for original, translated, expected in percent_cases:
            got = DDAC.normalizar_percentuais_para_reintegracao(original, translated)
            checks += 1
            if got != expected:
                failures.append("percent: {} -> {!r}; esperado {!r}, recebido {!r}".format(original, expected, got))

    print("ADVERSARIAL MATRIX: {} scenarios; {} failure(s)".format(checks, len(failures)))
    for failure in failures: print("FAIL: " + failure)
    if failures: return 1
    print("PASS: nested discovery, ignore rules, code/dialogue, reinjection safety, malformed input, Unicode")
    return 0

if __name__ == "__main__":
    raise SystemExit(run())