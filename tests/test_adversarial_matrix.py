#!/usr/bin/env python3
"""Adversarial regression matrix; all fixtures are synthetic text."""
import importlib.util, os, tempfile
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE=os.path.join(ROOT,"UnRen-DDAC-v145-python.py")
SPEC=importlib.util.spec_from_file_location("ddac_v145_adversarial",SOURCE)
DDAC=importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(DDAC)
def write(path,data,newline=None):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    with open(path,"w",encoding="utf-8",newline=newline) as f: f.write(data)
def values(entries):
    out=[]
    for e in entries:
        try: out.append(DDAC.decodificar_literal_traducao(e["original"]))
        except Exception: out.append(e["original"])
    return out
def run():
    checks=0; failures=[]
    with tempfile.TemporaryDirectory(prefix="ddac-adversarial-") as tmp:
        game=os.path.join(tmp,"game"); os.makedirs(game)
        write(os.path.join(game,"script.rpy"),'label start:\n    "Texto visível"\n')
        write(os.path.join(game,"nested","module.rpym"),'init -2:\n    "Módulo visível"\n')
        write(os.path.join(game,"nested","notes.txt"),'dream, 1, 0.5, 0.2\nhope, 1, 0.5, 0.2\n')
        for folder in ("tl","cache",".git","__pycache__"):
            write(os.path.join(game,folder,"hidden.rpy"),'label start:\n    "Não extrair"\n')
        write(os.path.join(game,"DDAC_generated.rpy"),'label start:\n    "Gerado"\n')
        candidates=DDAC.coletar_candidatos_extracao(game)
        rels={os.path.relpath(p,game).replace(os.sep,"/") for p in candidates}
        expected={"script.rpy","nested/module.rpym","nested/notes.txt"}; checks+=1
        if not expected.issubset(rels): failures.append("discovery: faltou "+repr(expected-rels))
        if any(any(seg in rel.split("/") for seg in ("tl","cache",".git","__pycache__")) for rel in rels): failures.append("discovery: pasta ignorada incluída")
        if any(os.path.basename(rel).startswith(DDAC.PREFIXO) for rel in rels): failures.append("discovery: arquivo gerado incluído")
        f=os.path.join(game,"adversarial.rpy")
        src=('# "Comentário que não deve ser extraído"\r\ninit python:\r\n    debug = "String técnica interna"\r\n    renpy.notify("Notificação visível")\r\nlabel start:\r\n    e "Oi [player], {i}amigo{/i}! %(score)d"\r\n    menu:\r\n        "Escolha" if score > 0:\r\n            "Continuar":\r\n                $ selected = "go"\r\n')
        write(f,src,newline="")
        _,entries=DDAC.extrair_arquivo_com_mapa(f,set(),{},{},{})
        found=set(values(entries)); checks+=1
        for want in ("Notificação visível","Oi [player], {i}amigo{/i}! %(score)d","Escolha","Continuar"):
            if want not in found: failures.append("extract: literal ausente "+repr(want))
        for unwanted in ("Comentário que não deve ser extraído","String técnica interna"):
            if unwanted in found: failures.append("extract: falso positivo "+repr(unwanted))
        dialogue=next((e for e in entries if "Oi [player]" in values([e])[0]),None); checks+=1
        if dialogue is None: failures.append("reinject: fala principal não encontrada")
        else:
            translated,errors=DDAC.reinjetar_arquivo(f,[dialogue],['"Olá [player], {i}amigo{/i}! %(score)d"']); checks+=1
            if errors or translated is None: failures.append("reinject: erro "+repr(errors))
            else:
                result="".join(translated)
                for token in ("[player]","{i}","{/i}","%(score)d",'$ selected = "go"',"score > 0"):
                    if token not in result: failures.append("reinject: token/código perdido "+repr(token))
                if "Olá [player]" not in result: failures.append("reinject: tradução não aplicada")
        stale=os.path.join(game,"stale.rpy")
        write(stale,'label start:\n    "Original"\n')
        _,stale_map=DDAC.extrair_arquivo_com_mapa(stale,set(),{},{},{})
        write(stale,'label start:\n    "Alterado manualmente"\n')
        _,errors=DDAC.reinjetar_arquivo(stale,stale_map,['"Tradução"']); checks+=1
        if not errors: failures.append("safety: mapa desatualizado aceito")
        for name,data in (("empty.rpy",""),("comments.rpy",'# only a comment\n'),("broken.rpy",'label start\n    "String sem fechamento\n    $ value =\n')):
            p=os.path.join(game,name); write(p,data)
            try: DDAC.extrair_arquivo_com_mapa(p,set(),{},{},{})
            except Exception as exc: failures.append("robustness: exceção em {}: {}".format(name,exc))
            checks+=1
        uni=os.path.join(game,"unicode.rpy")
        write(uni,'label start:\n    "Coração, ação, maçã — 日本語"\n')
        _,uni_entries=DDAC.extrair_arquivo_com_mapa(uni,set(),{},{},{}); checks+=1
        if "Coração, ação, maçã — 日本語" not in values(uni_entries): failures.append("unicode: literal Unicode alterado")
        percent_cases=[
          ("Score: %s","Pontuação: %s","Pontuação: %s"),
          ("Score: %(score)d","Pontuação: %(score)d","Pontuação: %(score)d"),
          ("Value %04d and %A","Valor %04d e data %A","Valor %04d e data %A"),
          ("Value %s, then %s","Valor %s, depois %s","Valor %s, depois %s"),
          ("Progress: 100% complete","Progresso: 100% concluído","Progresso: 100%% concluído"),
          ("No percentage here","Agora há 25% de progresso","Agora há 25%% de progresso"),
          ("Literal %% percent","Percentual literal %%","Percentual literal %%"),
          ("Progress: 100% complete","Progress: 100% complete","Progress: 100% complete")]
        for original,translated,expected in percent_cases:
            got=DDAC.normalizar_percentuais_para_reintegracao(original,translated); checks+=1
            if got!=expected: failures.append("percent: {} esperado {!r}, recebido {!r}".format(original,expected,got))
    print("ADVERSARIAL MATRIX: {} checks; {} failure(s)".format(checks,len(failures)))
    for failure in failures: print("FAIL: "+failure)
    if failures: return 1
    print("PASS: discovery, ignore rules, dynamic tokens, reinjection safety, malformed input, Unicode, percent formatting")
    return 0
if __name__=="__main__": raise SystemExit(run())
