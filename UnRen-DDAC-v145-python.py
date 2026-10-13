

# -*- coding: utf-8 -*-
import ast
import base64
import io
import json
import os
import re
import sys
import time
import traceback
import subprocess
import tempfile
import csv
import hashlib
import shutil
import threading
import urllib.error
import urllib.parse
import urllib.request
import unicodedata
import warnings
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED, as_completed

try:
    TEXT_TYPES = (basestring,)
except NameError:
    TEXT_TYPES = (str,)

def texto_compativel(valor, padrao=u"", campos=(u"tipo", u"texto", u"text", u"valor", u"value", u"nome", u"name", u"id")):
    """Normaliza valores textuais de mapas e caches sem chamar métodos de string em dicts."""
    if isinstance(valor, TEXT_TYPES):
        return valor
    if isinstance(valor, dict):
        for campo in campos:
            candidato = valor.get(campo)
            if isinstance(candidato, TEXT_TYPES):
                return candidato
        return padrao
    if valor is None:
        return padrao
    try:
        return unicode(valor)
    except NameError:
        try:
            return str(valor)
        except Exception:
            return padrao

PREFIXO = "DDAC_"
DDAC_BUILD = "V145-OptionalOracle-Fallback-PersistentReviewReports-RegressionTests"
PASTA_ENTRADA_NOME = "DDAC-DIALOGOS-EXTRAIDOS"
PASTA_SAIDA_TRADUZIDO_NOME = "DDAC-DIALOGOS-MESCLADOS"
PASTA_TRADUCAO_GOOGLE_NOME = "DDAC-DIÁLOGOS-TRADUZIDOS"

# Nomes reais das pastas variam com o idioma escolhido no menu.
NOMES_PASTAS_IDIOMA = {
    1: (u"DDAC-Diálogos-Extraídos", u"DDAC-Diálogos-Mesclados"),
    2: (u"DDAC-Extracted-Dialogues", u"DDAC-Merged-Dialogues"),
    3: (u"DDAC-Diálogos-Extraídos", u"DDAC-Diálogos-Mezclados"),
}
PASTA_ENTRADA_NOMES_COMPATIVEIS = tuple(dict.fromkeys(
    nome_entrada for nome_entrada, _ in NOMES_PASTAS_IDIOMA.values()
))

NOMES_LOG_EXTRACAO_IDIOMA = {
    1: "UnRen-DDAC-Extração-de-Diálogos.txt",
    2: "UnRen-DDAC-Dialogue-Extraction.txt",
    3: "UnRen-DDAC-Extracción-de-Diálogos.txt",
}
NOMES_LOG_TRADUCAO_IDIOMA = {
    1: "UnRen-DDAC-Tradução-com-Google-Translate.txt",
    2: "UnRen-DDAC-Translation-with-Google-Translate.txt",
    3: "UnRen-DDAC-Traducción-con-Google-Translate.txt",
}
NOMES_LOG_REINTEGRACAO_IDIOMA = {
    1: "UnRen-DDAC-Reintegração-de-Diálogos.txt",
    2: "UnRen-DDAC-Dialogue-Reinjection.txt",
    3: "UnRen-DDAC-Reintegración-de-Diálogos.txt",
}
NOMES_CACHE_PERSISTENTE_DIR_IDIOMA = {
    1: u"DDAC-Cache-Tradução",
    2: u"DDAC-Translation-Cache",
    3: u"DDAC-Caché-de-Traducción",
}
NOMES_CACHE_TEMP_IDIOMA = {
    1: u"UnRen-DDAC-Google-Translate-cache-temporário.json",
    2: u"UnRen-DDAC-Google-Translate-temporary-cache.json",
    3: u"UnRen-DDAC-Google-Translate-caché-temporal.json",
}
NOMES_DIAGNOSTICO_IDIOMA = {
    1: u"UnRen-DDAC-Diagnóstico-Google-Translate.txt",
    2: u"UnRen-DDAC-Google-Translate-Diagnostics.txt",
    3: u"UnRen-DDAC-Diagnóstico-de-Google-Translate.txt",
}
NOMES_DIAGNOSTICO_ESTRESSE_IDIOMA = {
    1: u"UnRen-DDAC-Diagnóstico-de-Estresse-Google-Translate.txt",
    2: u"UnRen-DDAC-Google-Translate-Stress-Diagnostic.txt",
    3: u"UnRen-DDAC-Diagnóstico-de-Estrés-de-Google-Translate.txt",
}
NOME_LOG_EXTRATOR = None
NOME_LOG_REINJETOR = None
NOME_LOG_TRADUTOR = None
EXTENSOES = (".rpy", ".rpym", ".txt", "_ren.py")
PASTAS_IGNORADAS = {"__pycache__", ".git", PASTA_ENTRADA_NOME, PASTA_SAIDA_TRADUZIDO_NOME, "cache", "tl"}

# Regra global: arquivos-base conhecidos que nunca podem gerar entradas de
# tradução automática. A mesma regra é aplicada ao motor DDAC, ao Oráculo
# Ren'Py e novamente ao Cérebro Semântico como defesa final.
ARQUIVOS_GLOBAIS_IGNORADOS_EXTRACAO = frozenset((
    u"script-poemresponses.rpy",
))

def arquivo_globalmente_ignorado_extracao(relativo):
    caminho = relativo or u""
    try:
        caminho = caminho.replace("\\", "/")
    except Exception:
        pass
    base = os.path.basename(caminho).rstrip("/").rsplit("/", 1)[-1].lower()
    return base in ARQUIVOS_GLOBAIS_IGNORADOS_EXTRACAO


MAPAS_COMPATIVEIS = (u"_mapa-ddac.json", u"_ddac-map.json")
NOME_MAPA = MAPAS_COMPATIVEIS[0]
INDENTACAO_SAIDA = u"    "

# --------------------------------------------------------------------------------
# Textos da tela nos três idiomas: 1 = Português, 2 = English, 3 = Espanhol.
# O idioma escolhido no menu do .bat chega como terceiro parametro.
# --------------------------------------------------------------------------------
IDIOMA = 1
MODO_EXIBICAO = u"resumido"
NOME_LOG_EXTRATOR = NOMES_LOG_EXTRACAO_IDIOMA.get(IDIOMA, NOMES_LOG_EXTRACAO_IDIOMA[1])


def exibicao_detalhada():
    return False


def barra_progresso(atual, total, largura=24):
    total = max(1, total)
    atual = max(0, min(atual, total))
    preenchido = int(round(largura * (float(atual) / float(total))))
    if preenchido >= largura:
        corpo = u"=" * largura
    elif preenchido <= 0:
        corpo = u">" + u" " * (largura - 1)
    else:
        corpo = u"=" * max(0, preenchido - 1) + u">" + u" " * (largura - preenchido)
    return u"[{}]".format(corpo)


def velocidade_e_eta(concluidos, total, inicio):
    decorrido = max(0.001, time.time() - inicio)
    velocidade = float(concluidos) / decorrido if concluidos else 0.0
    restante = max(0, total - concluidos)
    eta = float(restante) / velocidade if velocidade else 0.0
    return velocidade, eta
NOME_LOG_REINJETOR = NOMES_LOG_REINTEGRACAO_IDIOMA.get(IDIOMA, NOMES_LOG_REINTEGRACAO_IDIOMA[1])
NOME_LOG_TRADUTOR = NOMES_LOG_TRADUCAO_IDIOMA.get(IDIOMA, NOMES_LOG_TRADUCAO_IDIOMA[1])


def atualizar_nomes_pastas_por_idioma():
    global PASTA_ENTRADA_NOME, PASTA_SAIDA_TRADUZIDO_NOME, PASTA_TRADUCAO_GOOGLE_NOME, PASTAS_IGNORADAS
    global GOOGLE_CACHE_PERSISTENTE_DIR, GOOGLE_CACHE_NOME, GOOGLE_CACHE_DIAGNOSTICO_NOME, GOOGLE_CACHE_ESTRESSE_NOME
    entrada, saida = NOMES_PASTAS_IDIOMA.get(IDIOMA, NOMES_PASTAS_IDIOMA[1])
    nomes_traducao = {1: u"DDAC-Diálogos-Traduzidos", 2: u"DDAC-Translated-Dialogues", 3: u"DDAC-Diálogos-Traducidos"}
    PASTA_ENTRADA_NOME = entrada
    PASTA_SAIDA_TRADUZIDO_NOME = saida
    PASTA_TRADUCAO_GOOGLE_NOME = nomes_traducao.get(IDIOMA, nomes_traducao[1])
    GOOGLE_CACHE_PERSISTENTE_DIR = NOMES_CACHE_PERSISTENTE_DIR_IDIOMA.get(IDIOMA, NOMES_CACHE_PERSISTENTE_DIR_IDIOMA[1])
    GOOGLE_CACHE_NOME = NOMES_CACHE_TEMP_IDIOMA.get(IDIOMA, NOMES_CACHE_TEMP_IDIOMA[1])
    GOOGLE_CACHE_DIAGNOSTICO_NOME = NOMES_DIAGNOSTICO_IDIOMA.get(IDIOMA, NOMES_DIAGNOSTICO_IDIOMA[1])
    GOOGLE_CACHE_ESTRESSE_NOME = NOMES_DIAGNOSTICO_ESTRESSE_IDIOMA.get(IDIOMA, NOMES_DIAGNOSTICO_ESTRESSE_IDIOMA[1])
    PASTAS_IGNORADAS = {"__pycache__", ".git", "cache", "DDAC-Game", "DDAC-Traduzido", "tl"}
    # Ignora as pastas de saída de TODOS os idiomas, senão uma rodada em EN/ES
    # varreria a pasta gerada por uma rodada anterior em PT (e vice-versa).
    for _entrada, _saida in NOMES_PASTAS_IDIOMA.values():
        PASTAS_IGNORADAS.add(_entrada)
        PASTAS_IGNORADAS.add(_saida)
    for _nome_traducao in (u"DDAC-Diálogos-Traduzidos", u"DDAC-Translated-Dialogues", u"DDAC-Diálogos-Traducidos", u"DDAC-Dialogos-Traduzidos", u"DDAC-Dialogos-Traducidos"):
        PASTAS_IGNORADAS.add(_nome_traducao)

MENSAGENS = {
    1: {
        "cab_extrair": u" DDAC - Extrair Diálogos",
        "cab_reinjetar": u" DDAC - Reinjetar Tradução",
        "pasta_escaneada": u"Pasta escaneada: {0}",
        "pasta_saida": u"Pasta de saída:  {0}",
        "pasta_traducao": u"Pasta com tradução: {0}",
        "pasta_original": u"Pasta original:     {0}",
        "pasta_saida2": u"Pasta de saída:     {0}",
        "etapa1_extrair": u"Etapa 1/3: localizando arquivos .rpy/.rpym/.txt...",
        "etapa2_extrair": u"Etapa 2/3: identificando personagens com nome dinâmico...",
        "etapa3_extrair": u"Etapa 3/3: extraindo diálogo e recriando a estrutura em {0}...",
        "arquivos_encontrados": u"  {0} arquivo(s) encontrado(s)",
        "vars_dinamicas": u"  {0} variável(is) de nome dinâmico encontrada(s)",
        "erro": u"ERRO",
        "erro_arquivo": u"ERRO {0}  ->  {1}",
        "ok_linhas": u"OK  {0}  ->  {1} linha(s)",
        "res_escaneados": u"Arquivos escaneados: {0}",
        "res_com_dialogo": u"Arquivos com diálogo extraído: {0}",
        "res_linhas": u"Linhas de diálogo extraídas: {0}",
        "res_sem_dialogo": u"Arquivos sem diálogo detectado ({0}):",
        "imp1": u"IMPORTANTE: não apague, renomeie nem edite o arquivo {0} que fica",
        "imp2": u"na raiz de {0} -- ele guarda a posição de cada texto pra reinjeção.",
        "imp3": u"Ao traduzir, edite só o texto entre aspas de cada linha, mantendo as",
        "imp4": u"aspas no lugar.",
        "imp5": u"Não adicione nem remova linhas. Quando terminar, abra este programa",
        "imp6": u"de novo e use a opção 3 para reintegrar.",
        "log_salvo": u"Log salvo em: {0}",
        "err_pasta_entrada": u"Nenhuma pasta de diálogos extraídos compatível foi encontrada. Use a opção 1 (Extrair diálogos) primeiro.",
        "reinj_multiplas_titulo": u"Foram encontradas duas ou mais pastas de diálogos. Escolha qual versão deseja reintegrar:",
        "reinj_multiplas_opcao": u"  {0}) {1}",
        "reinj_multiplas_prompt": u"Escolha uma opção: ",
        "reinj_multiplas_invalida": u"Opção inválida. Escolha uma das opções acima.",
        "reinj_selecao_titulo": u"ESCOLHA A FONTE DA TRADUÇÃO",
        "reinj_selecao_item": u"[{0}] {1}",
        "reinj_selecao_pasta": u"    Pasta: {0}",
        "reinj_selecao_caminho": u"    Caminho: {0}",
        "reinj_selecao_prompt": u"Digite o número da opção: ",
        "reinj_selecao_invalida": u"Opção inválida. Digite o número de uma das opções acima.",
        "reinj_tipo_manual": u"Extração / tradução manual",
        "reinj_tipo_google": u"Google Translate / tradução",
        "rj_modo_titulo": u"Modo de reintegração",
        "rj_modo_normal": u"1) Reintegração normal (recomendado)",
        "rj_modo_seguro": u"2) Reintegração segura (backup + validação completa)",
        "rj_modo_prompt": u"Escolha um modo: ",
        "rj_modo_invalido": u"Opção inválida. Escolha 1 ou 2.",
        "rj_validacao_pre": u"VALIDAÇÃO ANTES DA REINTEGRAÇÃO",
        "rj_validacao_pos": u"VALIDAÇÃO APÓS A REINTEGRAÇÃO",
        "rj_validacao_ok": u"Validação concluída sem diferenças inesperadas.",
        "rj_validacao_falhou": u"A validação encontrou problemas. A reintegração foi recusada.",
        "rj_backup_ok": u"Backup da saída anterior criado em: {0}",
        "rj_backup_nao": u"Nenhuma saída anterior para backup.",
        "rj_textos_alterados": u"Textos realmente alterados",
        "rj_textos_iguais": u"Textos sem alteração",
        "rj_arquivos_ok": u"Arquivos validados",
        "rj_arquivos_esperados": u"Arquivos esperados pelo mapa",
        "rj_entradas_esperadas": u"Entradas esperadas pelo mapa",
        "rj_entradas_encontradas": u"Entradas encontradas",
        "rj_diferencas": u"Diferenças inesperadas",
        "rj_modificados": u"Arquivos modificados",
        "rj_tempo": u"Tempo total",
        "rj_velocidade": u"Velocidade média",
        "err_mapa": u"Arquivo '{0}' não encontrado dentro de {1}. Use a opção 1 primeiro.",
        "err_ler_mapa": u"Falha ao ler {0}: {1}",
        "etapa1_reinj": u"Etapa 1/2: localizando arquivos traduzidos em {0}...",
        "etapa2_reinj": u"Etapa 2/2: validando e reinjetando cada texto na posição original...",
        "sem_mapa": u"SEM MAPA  {0}  (sem entrada em {1}, pulado)",
        "erro_ler_trad": u"ERRO  {0}  ->  falha ao ler tradução: {1}",
        "erro_inesperado": u"ERRO  {0}  ->  falha inesperada: {1}",
        "falha": u"FALHA  {0}",
        "res_trad_encontrados": u"Arquivos traduzidos encontrados: {0}",
        "res_reinj_ok": u"Arquivos reinjetados com sucesso: {0}",
        "res_reinj_falha": u"Arquivos com falha (não alterados): {0}",
        "res_reinj_linhas": u"Linhas reinjetadas no total: {0}",
        "res_sem_mapa": u"Arquivos sem entrada no mapa (pulados): {0}",
        "ok_reinjetadas": u"OK  {0}  ->  {1} linha(s) reinjetada(s)",
        "pronto1": u"A pasta de diálogos mesclados está pronta em: {0}",
        "pronto2": u"Recorte a pasta '{0}' (dentro de {1}) e cole por cima da pasta",
        "pronto3": u"'{0}' original do mod, substituindo, para aplicar a tradução.",
        "atencao1": u"ATENÇÃO: {0} arquivo(s) NÃO foram reinjetados por segurança -- veja",
        "atencao2": u"os detalhes acima e no log. Nenhum arquivo original foi modificado.",
        "rj_contagem": u"contagem não bate: o mapa espera {0} texto(s), mas o arquivo traduzido tem {1}. NÃO adicione nem remova linhas de texto -- edite só o conteúdo entre aspas de cada uma.",
        "rj_sem_original": u"arquivo original não encontrado: {0}",
        "rj_linha_inexistente": u"linha {0} não existe mais no arquivo original (o mod foi alterado desde a extração?)",
        "rj_linha_mudou": u"linha {0} (colunas {1}-{2}) do arquivo original mudou desde a extração (esperado: {3!r} / encontrado: {4!r})",
        "log_tag_info": u"INFO",
        "log_tag_aviso": u"AVISO",
        "log_tag_erro": u"ERRO",
        "log_cab_extrator": u"DDAC Extração de Diálogos - INÍCIO DA EXECUÇÃO",
        "log_cab_reinjetor": u"DDAC Reintegração de Diálogos - INÍCIO DA EXECUÇÃO",
        "log_datahora": u"Data/Hora: {0}",
        "log_pasta_escaneada": u"Pasta escaneada: {0}",
        "log_pasta_saida": u"Pasta de saída: {0}",
        "log_etapa1_extrair": u"Etapa 1/3: {0} arquivo(s) .rpy/.rpym/.txt localizado(s)",
        "log_etapa2_extrair": u"Etapa 2/3: {0} variável(is) de nome dinâmico: {1}",
        "log_etapa3_extrair": u"Etapa 3/3: iniciando extração de diálogo",
        "log_falha_ler": u"Falha ao ler {0}: {1}",
        "log_sem_dialogo": u"Sem diálogo detectado: {0}",
        "log_linhas": u"{0} linha(s)",
        "log_res_escaneados": u"Arquivos escaneados",
        "log_res_com_dialogo": u"Arquivos com diálogo",
        "log_res_sem_dialogo": u"Arquivos sem diálogo",
        "log_res_linhas": u"Linhas de diálogo extraídas",
        "log_res_erros": u"Erros de leitura",
        "log_pasta_traducao": u"Pasta com tradução ({0}): {1}",
        "log_pasta_original": u"Pasta original (jogo): {0}",
        "log_etapa1_reinj": u"Etapa 1/2: {0} arquivo(s) traduzido(s) localizado(s)",
        "log_etapa2_reinj": u"Etapa 2/2: iniciando reinjeção",
        "log_sem_mapa_arq": u"Arquivo sem entrada em {0}, pulado: {1}",
        "log_falha_ler_trad": u"Falha ao ler tradução de {0}: {1}",
        "log_falha_inesperada": u"Falha inesperada ao reinjetar {0}: {1}",
        "log_falha_reinjetar": u"Falha ao reinjetar {0}:",
        "log_linhas_reinj": u"{0} linha(s) reinjetada(s)",
        "log_res_trad_encontrados": u"Arquivos traduzidos encontrados",
        "log_res_ok": u"Reinjetados com sucesso",
        "log_res_falhas": u"Falhas (não alterados)",
        "log_res_sem_mapa": u"Sem entrada no mapa (pulados)",
        "log_res_linhas_reinj": u"Linhas reinjetadas",
        "modo_desconhecido": u"Modo desconhecido: {0!r}",
        "t_sem_extracao": u"Nenhuma pasta de diálogos extraídos compatível foi encontrada. Use a opção 1 primeiro.",
        "t_mapa_invalido": u"Falha ao ler o mapa: {0}",
        "t_origem_prompt": u"Idioma de origem [auto]: ",
        "t_destino_prompt": u"Idioma de destino [pt-BR]: ",
        "t_conectando": u"Testando acesso à rede do Google Translate...",
        "t_conectado": u"Acesso ao Google Translate OK. O teste não consome a cota do endpoint de tradução.",
        "t_erro_conexao": u"Falha no Google Translate: {0}",
        "t_cancelado": u"Tradução cancelada.",
        "t_processando": u"Processando {0} textos únicos...",
        "t_arquivo": u"OK  {0}  ->  {1} texto(s)",
        "t_falha_texto": u"FALHA ao traduzir este arquivo; o arquivo copiado foi mantido com o que foi possível traduzir.",
        "t_nenhuma": u"Nenhum texto foi processado.",
        "t_pronto": u"Tradução concluída. Pasta criada em: {0}",
        "t_log_inicio": u"DDAC Tradução com Google Translate - INÍCIO DA EXECUÇÃO",
        "t_log_pasta": u"Pasta de entrada: {0}",
        "t_log_saida": u"Pasta de saída: {0}",
        "t_log_arquivo": u"Textos processados em {0}",
        "t_log_falha": u"Falha em {0}",
        "t_log_fim": u"DDAC Tradução com Google Translate - FIM DA EXECUÇÃO",
        "t_lote_inicio": u"Lote {0}/{1}  ->  {2} texto(s) enviado(s)",
        "t_lote_ok": u"Lote {0}/{1} OK  ->  {2} texto(s) traduzido(s) em {3:.1f}s",
        "t_lote_erro": u"Lote {0}/{1} FALHOU  ->  {2}",
        "t_fallback": u"Fallback individual iniciado para o lote {0}/{1}",
        "t_progresso": u"Progresso: {0}/{1} textos  |  {2} lote(s) OK  |  {3} falha(s)",
        "t_config_paralela": u"Paralelo: {0} requisições simultâneas  |  até {1} textos por lote  |  {2} caracteres por lote",
        "t_cache": u"Cache: {0} tradução(ões) reaproveitada(s)",
        "t_arquivo_inicio": u"INÍCIO  {0}  ->  {1} texto(s)",
        "t_arquivo_fim": u"FIM  {0}  ->  {1} texto(s) em {2:.1f}s",
        "t_cancelado": u"Tradução cancelada.",
        "etapa_biblioteca": u"Etapa 0/3: consultando a biblioteca DDLC/Template ({0} arquivos catalogados)...",
        "bib_ignorado": u"IGN {0}  ->  sem diálogo nativo ({1})",
        "bib_novo_texto": u"NOVO {0}  ->  {1} linha(s) em arquivo normalmente sem diálogo ({2})",
        "res_bib_ignorados": u"Arquivos ignorados pela biblioteca ({0}):",
        "res_bib_novos": u"Arquivos fora do padrão da biblioteca (texto novo) ({0}):",
        "log_bib_ignorado": u"{0}: ignorado pela biblioteca -- {1}",
        "log_bib_novo": u"{0}: texto novo em arquivo sem diálogo nativo -- {1}",
        "log_res_bib_ignorados": u"Ignorados pela biblioteca",
        "log_res_bib_novos": u"Arquivos com texto fora do padrão",
    },
    2: {
        "cab_extrair": u" DDAC - Extract Dialogue",
        "cab_reinjetar": u" DDAC - Reinject Translation",
        "pasta_escaneada": u"Scanned folder: {0}",
        "pasta_saida": u"Output folder:  {0}",
        "pasta_traducao": u"Translation folder: {0}",
        "pasta_original": u"Original folder:    {0}",
        "pasta_saida2": u"Output folder:      {0}",
        "etapa1_extrair": u"Step 1/3: locating .rpy/.rpym/.txt files...",
        "etapa2_extrair": u"Step 2/3: identifying characters with dynamic names...",
        "etapa3_extrair": u"Step 3/3: extracting dialogue and rebuilding the structure in {0}...",
        "arquivos_encontrados": u"  {0} file(s) found",
        "vars_dinamicas": u"  {0} dynamic name variable(s) found",
        "erro": u"ERROR",
        "erro_arquivo": u"ERROR {0}  ->  {1}",
        "ok_linhas": u"OK  {0}  ->  {1} line(s)",
        "res_escaneados": u"Files scanned: {0}",
        "res_com_dialogo": u"Files with extracted dialogue: {0}",
        "res_linhas": u"Dialogue lines extracted: {0}",
        "res_sem_dialogo": u"Files with no dialogue detected ({0}):",
        "imp1": u"IMPORTANT: do not delete, rename or edit the {0} file that sits",
        "imp2": u"at the root of {0} -- it stores the position of every text for reinjection.",
        "imp3": u"When translating, edit only the text between quotes on each line, keeping",
        "imp4": u"the quotes in place.",
        "imp5": u"Do not add or remove lines. When you are done, run this program",
        "imp6": u"again and use option 2.",
        "log_salvo": u"Log saved to: {0}",
        "err_pasta_entrada": u"No compatible extracted-dialogue folder was found. Use option 1 (Extract dialogue) first.",
        "reinj_multiplas_titulo": u"Multiple dialogue folders were found. Choose which version to reintegrate:",
        "reinj_multiplas_opcao": u"  {0}) {1}",
        "reinj_multiplas_prompt": u"Choose an option: ",
        "reinj_multiplas_invalida": u"Invalid option. Choose one of the options above.",
        "reinj_selecao_titulo": u"CHOOSE THE TRANSLATION SOURCE",
        "reinj_selecao_item": u"[{0}] {1}",
        "reinj_selecao_pasta": u"    Folder: {0}",
        "reinj_selecao_caminho": u"    Path: {0}",
        "reinj_selecao_prompt": u"Enter the option number: ",
        "reinj_selecao_invalida": u"Invalid option. Enter the number of one of the options above.",
        "reinj_tipo_manual": u"Extraction / manual translation",
        "reinj_tipo_google": u"Google Translate / translation",
        "rj_modo_titulo": u"Reintegration mode",
        "rj_modo_normal": u"1) Normal (recommended)",
        "rj_modo_seguro": u"2) Safe (backup + full validation)",
        "rj_modo_prompt": u"Choose mode [1]: ",
        "rj_modo_invalido": u"Invalid option. Choose 1 or 2.",
        "rj_validacao_pre": u"PRE-REINTEGRATION VALIDATION",
        "rj_validacao_pos": u"POST-REINTEGRATION VALIDATION",
        "rj_validacao_ok": u"Validation completed with no unexpected differences.",
        "rj_validacao_falhou": u"Validation found problems. Reintegration was refused.",
        "rj_backup_ok": u"Backup of the previous output created at: {0}",
        "rj_backup_nao": u"No previous output to back up.",
        "rj_textos_alterados": u"Texts actually changed",
        "rj_textos_iguais": u"Texts unchanged",
        "rj_arquivos_ok": u"Files validated",
        "rj_arquivos_esperados": u"Files expected by the map",
        "rj_entradas_esperadas": u"Entries expected by the map",
        "rj_entradas_encontradas": u"Entries found",
        "rj_diferencas": u"Unexpected differences",
        "rj_modificados": u"Files modified",
        "rj_tempo": u"Total time",
        "rj_velocidade": u"Average speed",
        "err_mapa": u"File '{0}' not found inside {1}. Use option 1 first.",
        "err_ler_mapa": u"Failed to read {0}: {1}",
        "etapa1_reinj": u"Step 1/2: locating translated files in {0}...",
        "etapa2_reinj": u"Step 2/2: validating and reinjecting each text at its original position...",
        "sem_mapa": u"NO MAP  {0}  (no entry in {1}, skipped)",
        "erro_ler_trad": u"ERROR  {0}  ->  failed to read translation: {1}",
        "erro_inesperado": u"ERROR  {0}  ->  unexpected failure: {1}",
        "falha": u"FAILED  {0}",
        "res_trad_encontrados": u"Translated files found: {0}",
        "res_reinj_ok": u"Files reinjected successfully: {0}",
        "res_reinj_falha": u"Failed files (left untouched): {0}",
        "res_reinj_linhas": u"Total lines reinjected: {0}",
        "res_sem_mapa": u"Files with no map entry (skipped): {0}",
        "ok_reinjetadas": u"OK  {0}  ->  {1} line(s) reinjected",
        "pronto1": u"The translated folder is ready at: {0}",
        "pronto2": u"Cut the '{0}' folder (inside {1}) and paste it over the original",
        "pronto3": u"'{0}' folder of the mod, replacing it, to apply the translation.",
        "atencao1": u"WARNING: {0} file(s) were NOT reinjected for safety -- see the",
        "atencao2": u"details above and in the log. No original file was modified.",
        "rj_contagem": u"count mismatch: the map expects {0} text(s), but the translated file has {1}. Do NOT add or remove text lines -- edit only the content between quotes on each one.",
        "rj_sem_original": u"original file not found: {0}",
        "rj_linha_inexistente": u"line {0} no longer exists in the original file (was the mod changed after extraction?)",
        "rj_linha_mudou": u"line {0} (columns {1}-{2}) of the original file changed after extraction (expected: {3!r} / found: {4!r})",
        "log_tag_info": u"INFO",
        "log_tag_aviso": u"WARNING",
        "log_tag_erro": u"ERROR",
        "log_cab_extrator": u"DDAC Dialogue Extraction - EXECUTION START",
        "log_cab_reinjetor": u"DDAC Dialogue Reintegration - EXECUTION START",
        "log_datahora": u"Date/Time: {0}",
        "log_pasta_escaneada": u"Scanned folder: {0}",
        "log_pasta_saida": u"Output folder: {0}",
        "log_etapa1_extrair": u"Step 1/3: {0} .rpy/.rpym/.txt file(s) located",
        "log_etapa2_extrair": u"Step 2/3: {0} dynamic name variable(s): {1}",
        "log_etapa3_extrair": u"Step 3/3: starting dialogue extraction",
        "log_falha_ler": u"Failed to read {0}: {1}",
        "log_sem_dialogo": u"No dialogue detected: {0}",
        "log_linhas": u"{0} line(s)",
        "log_res_escaneados": u"Files scanned",
        "log_res_com_dialogo": u"Files with dialogue",
        "log_res_sem_dialogo": u"Files without dialogue",
        "log_res_linhas": u"Dialogue lines extracted",
        "log_res_erros": u"Read errors",
        "log_pasta_traducao": u"Translation folder ({0}): {1}",
        "log_pasta_original": u"Original folder (game): {0}",
        "log_etapa1_reinj": u"Step 1/2: {0} translated file(s) located",
        "log_etapa2_reinj": u"Step 2/2: starting reinjection",
        "log_sem_mapa_arq": u"File with no entry in {0}, skipped: {1}",
        "log_falha_ler_trad": u"Failed to read translation of {0}: {1}",
        "log_falha_inesperada": u"Unexpected failure reinjecting {0}: {1}",
        "log_falha_reinjetar": u"Failed to reinject {0}:",
        "log_linhas_reinj": u"{0} line(s) reinjected",
        "log_res_trad_encontrados": u"Translated files found",
        "log_res_ok": u"Reinjected successfully",
        "log_res_falhas": u"Failures (left untouched)",
        "log_res_sem_mapa": u"No map entry (skipped)",
        "log_res_linhas_reinj": u"Lines reinjected",
        "modo_desconhecido": u"Unknown mode: {0!r}",
        "t_sem_extracao": u"No compatible extracted-dialogues folder was found. Use option 1 first.",
        "t_mapa_invalido": u"Failed to read the map: {0}",
        "t_origem_prompt": u"Source language [auto]: ",
        "t_destino_prompt": u"Target language [pt-BR]: ",
        "t_conectando": u"Testing connection to Google Translate...",
        "t_conectado": u"Google Translate connection OK.",
        "t_erro_conexao": u"Google Translate failed: {0}",
        "t_cancelado": u"Translation cancelled.",
        "t_processando": u"Processing {0} unique texts...",
        "t_arquivo": u"OK  {0}  ->  {1} text(s)",
        "t_falha_texto": u"FAILED to translate this file; the copied file was kept unchanged.",
        "t_nenhuma": u"No text was processed.",
        "t_pronto": u"Translation completed. Output folder: {0}",
        "t_log_inicio": u"DDAC Google Translate - START",
        "t_log_pasta": u"Input folder: {0}",
        "t_log_saida": u"Output folder: {0}",
        "t_log_arquivo": u"Texts processed in {0}",
        "t_log_falha": u"Failed in {0}",
        "t_log_fim": u"DDAC Google Translate - END",
        "t_lote_inicio": u"Batch {0}/{1}  ->  {2} text(s) sent",
        "t_lote_ok": u"Batch {0}/{1} OK  ->  {2} text(s) translated in {3:.1f}s",
        "t_lote_erro": u"Batch {0}/{1} FAILED  ->  {2}",
        "t_fallback": u"Individual fallback started for batch {0}/{1}",
        "t_progresso": u"Progress: {0}/{1} texts  |  {2} batch(es) OK  |  {3} failure(s)",
        "t_config_paralela": u"Parallel: {0} simultaneous requests  |  up to {1} texts per batch  |  {2} chars per batch",
        "t_cache": u"Cache: {0} translation(s) reused",
        "t_arquivo_inicio": u"START  {0}  ->  {1} text(s)",
        "t_arquivo_fim": u"END  {0}  ->  {1} text(s) in {2:.1f}s",
        "etapa_biblioteca": u"Step 0/3: checking the DDLC/Template library ({0} catalogued files)...",
        "bib_ignorado": u"SKIP {0}  ->  no native dialogue ({1})",
        "bib_novo_texto": u"NEW  {0}  ->  {1} line(s) in a file that normally has no dialogue ({2})",
        "res_bib_ignorados": u"Files skipped by the library ({0}):",
        "res_bib_novos": u"Files outside the library baseline (new text) ({0}):",
        "log_bib_ignorado": u"{0}: skipped by the library -- {1}",
        "log_bib_novo": u"{0}: new text in a file without native dialogue -- {1}",
        "log_res_bib_ignorados": u"Skipped by the library",
        "log_res_bib_novos": u"Files with text outside the baseline",
    },
    3: {
        "cab_extrair": u" DDAC - Extraer Diálogos",
        "cab_reinjetar": u" DDAC - Reinyectar Traducción",
        "pasta_escaneada": u"Carpeta escaneada: {0}",
        "pasta_saida": u"Carpeta de salida: {0}",
        "pasta_traducao": u"Carpeta con traducción: {0}",
        "pasta_original": u"Carpeta original:       {0}",
        "pasta_saida2": u"Carpeta de salida:      {0}",
        "etapa1_extrair": u"Paso 1/3: localizando archivos .rpy/.rpym/.txt...",
        "etapa2_extrair": u"Paso 2/3: identificando personajes con nombre dinámico...",
        "etapa3_extrair": u"Paso 3/3: extrayendo diálogos y recreando la estructura en {0}...",
        "arquivos_encontrados": u"  {0} archivo(s) encontrado(s)",
        "vars_dinamicas": u"  {0} variable(s) de nombre dinámico encontrada(s)",
        "erro": u"ERROR",
        "erro_arquivo": u"ERROR {0}  ->  {1}",
        "ok_linhas": u"OK  {0}  ->  {1} línea(s)",
        "res_escaneados": u"Archivos escaneados: {0}",
        "res_com_dialogo": u"Archivos con diálogo extraído: {0}",
        "res_linhas": u"Líneas de diálogo extraídas: {0}",
        "res_sem_dialogo": u"Archivos sin diálogo detectado ({0}):",
        "imp1": u"IMPORTANTE: no borres, renombres ni edites el archivo {0} que está",
        "imp2": u"en la raíz de {0} -- guarda la posición de cada texto para la reinyección.",
        "imp3": u"Al traducir, edita solo el texto entre comillas de cada línea, dejando",
        "imp4": u"las comillas en su lugar.",
        "imp5": u"No agregues ni quites líneas. Cuando termines, abre este programa",
        "imp6": u"de nuevo y usa la opción 2.",
        "log_salvo": u"Log guardado en: {0}",
        "err_pasta_entrada": u"No se encontró ninguna carpeta compatible de diálogos extraídos. Usa primero la opción 1 (Extraer diálogos).",
        "reinj_multiplas_titulo": u"Se encontraron varias carpetas de diálogos. Elige qué versión deseas reinyectar:",
        "reinj_multiplas_opcao": u"  {0}) {1}",
        "reinj_multiplas_prompt": u"Elige una opción: ",
        "reinj_multiplas_invalida": u"Opción no válida. Elige una de las opciones anteriores.",
        "reinj_selecao_titulo": u"ELIGE LA FUENTE DE LA TRADUCCIÓN",
        "reinj_selecao_item": u"[{0}] {1}",
        "reinj_selecao_pasta": u"    Carpeta: {0}",
        "reinj_selecao_caminho": u"    Ruta: {0}",
        "reinj_selecao_prompt": u"Escribe el número de la opción: ",
        "reinj_selecao_invalida": u"Opción no válida. Escribe el número de una de las opciones anteriores.",
        "reinj_tipo_manual": u"Extracción / traducción manual",
        "reinj_tipo_google": u"Google Translate / traducción",
        "rj_modo_titulo": u"Modo de reintegración",
        "rj_modo_normal": u"1) Normal (recomendado)",
        "rj_modo_seguro": u"2) Seguro (copia de seguridad + validación completa)",
        "rj_modo_prompt": u"Elige el modo [1]: ",
        "rj_modo_invalido": u"Opción no válida. Elige 1 o 2.",
        "rj_validacao_pre": u"VALIDACIÓN ANTES DE LA REINTEGRACIÓN",
        "rj_validacao_pos": u"VALIDACIÓN DESPUÉS DE LA REINTEGRACIÓN",
        "rj_validacao_ok": u"Validación completada sin diferencias inesperadas.",
        "rj_validacao_falhou": u"La validación encontró problemas. Se rechazó la reintegración.",
        "rj_backup_ok": u"Copia de seguridad de la salida anterior creada en: {0}",
        "rj_backup_nao": u"No había una salida anterior para respaldar.",
        "rj_textos_alterados": u"Textos realmente modificados",
        "rj_textos_iguais": u"Textos sin cambios",
        "rj_arquivos_ok": u"Archivos validados",
        "rj_arquivos_esperados": u"Archivos esperados por el mapa",
        "rj_entradas_esperadas": u"Entradas esperadas por el mapa",
        "rj_entradas_encontradas": u"Entradas encontradas",
        "rj_diferencas": u"Diferencias inesperadas",
        "rj_modificados": u"Archivos modificados",
        "rj_tempo": u"Tiempo total",
        "rj_velocidade": u"Velocidad media",
        "err_mapa": u"Archivo '{0}' no encontrado dentro de {1}. Usa primero la opción 1.",
        "err_ler_mapa": u"Fallo al leer {0}: {1}",
        "etapa1_reinj": u"Paso 1/2: localizando archivos traducidos en {0}...",
        "etapa2_reinj": u"Paso 2/2: validando y reinyectando cada texto en su posición original...",
        "sem_mapa": u"SIN MAPA  {0}  (sin entrada en {1}, omitido)",
        "erro_ler_trad": u"ERROR  {0}  ->  fallo al leer la traducción: {1}",
        "erro_inesperado": u"ERROR  {0}  ->  fallo inesperado: {1}",
        "falha": u"FALLO  {0}",
        "res_trad_encontrados": u"Archivos traducidos encontrados: {0}",
        "res_reinj_ok": u"Archivos reinyectados con éxito: {0}",
        "res_reinj_falha": u"Archivos con errores (no modificados): {0}",
        "res_reinj_linhas": u"Líneas reinyectadas en total: {0}",
        "res_sem_mapa": u"Archivos sin entrada en el mapa (omitidos): {0}",
        "ok_reinjetadas": u"OK  {0}  ->  {1} línea(s) reinyectada(s)",
        "pronto1": u"La carpeta traducida está lista en: {0}",
        "pronto2": u"Corta la carpeta '{0}' (dentro de {1}) y pégala sobre la carpeta",
        "pronto3": u"'{0}' original del mod, reemplazándola, para aplicar la traducción.",
        "atencao1": u"ATENCIÓN: {0} archivo(s) NO fueron reinyectados por seguridad -- revisa",
        "atencao2": u"los detalles arriba y en el log. Ningún archivo original fue modificado.",
        "rj_contagem": u"la cuenta no coincide: el mapa espera {0} texto(s), pero el archivo traducido tiene {1}. NO agregues ni quites líneas de texto -- edita solo el contenido entre comillas de cada una.",
        "rj_sem_original": u"archivo original no encontrado: {0}",
        "rj_linha_inexistente": u"la línea {0} ya no existe en el archivo original (se modificó el mod después de la extracción?)",
        "rj_linha_mudou": u"la línea {0} (columnas {1}-{2}) del archivo original cambió después de la extracción (esperado: {3!r} / encontrado: {4!r})",
        "log_tag_info": u"INFO",
        "log_tag_aviso": u"AVISO",
        "log_tag_erro": u"ERROR",
        "log_cab_extrator": u"DDAC Extracción de Diálogos - INICIO DE LA EJECUCIÓN",
        "log_cab_reinjetor": u"DDAC Reintegración de Diálogos - INICIO DE LA EJECUCIÓN",
        "log_datahora": u"Fecha/Hora: {0}",
        "log_pasta_escaneada": u"Carpeta escaneada: {0}",
        "log_pasta_saida": u"Carpeta de salida: {0}",
        "log_etapa1_extrair": u"Paso 1/3: {0} archivo(s) .rpy/.rpym/.txt localizado(s)",
        "log_etapa2_extrair": u"Paso 2/3: {0} variable(s) de nombre dinámico: {1}",
        "log_etapa3_extrair": u"Paso 3/3: iniciando la extracción de diálogos",
        "log_falha_ler": u"Fallo al leer {0}: {1}",
        "log_sem_dialogo": u"Sin diálogo detectado: {0}",
        "log_linhas": u"{0} línea(s)",
        "log_res_escaneados": u"Archivos escaneados",
        "log_res_com_dialogo": u"Archivos con diálogo",
        "log_res_sem_dialogo": u"Archivos sin diálogo",
        "log_res_linhas": u"Líneas de diálogo extraídas",
        "log_res_erros": u"Errores de lectura",
        "log_pasta_traducao": u"Carpeta con traducción ({0}): {1}",
        "log_pasta_original": u"Carpeta original (juego): {0}",
        "log_etapa1_reinj": u"Paso 1/2: {0} archivo(s) traducido(s) localizado(s)",
        "log_etapa2_reinj": u"Paso 2/2: iniciando la reinyección",
        "log_sem_mapa_arq": u"Archivo sin entrada en {0}, omitido: {1}",
        "log_falha_ler_trad": u"Fallo al leer la traducción de {0}: {1}",
        "log_falha_inesperada": u"Fallo inesperado al reinyectar {0}: {1}",
        "log_falha_reinjetar": u"Fallo al reinyectar {0}:",
        "log_linhas_reinj": u"{0} línea(s) reinyectada(s)",
        "log_res_trad_encontrados": u"Archivos traducidos encontrados",
        "log_res_ok": u"Reinyectados con éxito",
        "log_res_falhas": u"Fallos (no modificados)",
        "log_res_sem_mapa": u"Sin entrada en el mapa",
        "log_res_linhas_reinj": u"Líneas reinyectadas",
        "modo_desconhecido": u"Modo desconocido: {0!r}",
        "t_sem_extracao": u"No se encontró una carpeta compatible de diálogos extraídos. Usa primero la opción 1.",
        "t_mapa_invalido": u"No se pudo leer el mapa: {0}",
        "t_origem_prompt": u"Idioma de origen [auto]: ",
        "t_destino_prompt": u"Idioma de destino [pt-BR]: ",
        "t_conectando": u"Probando la conexión con Google Translate...",
        "t_conectado": u"Conexión con Google Translate correcta.",
        "t_erro_conexao": u"Falló Google Translate: {0}",
        "t_cancelado": u"Traducción cancelada.",
        "t_processando": u"Procesando {0} textos únicos...",
        "t_arquivo": u"OK  {0}  ->  {1} texto(s)",
        "t_falha_texto": u"FALLO al traducir este archivo; se mantuvo sin cambios la copia.",
        "t_nenhuma": u"No se procesó ningún texto.",
        "t_pronto": u"Traducción terminada. Carpeta de salida: {0}",
        "t_log_inicio": u"DDAC Google Translate - INICIO",
        "t_log_pasta": u"Carpeta de entrada: {0}",
        "t_log_saida": u"Carpeta de salida: {0}",
        "t_log_arquivo": u"Textos procesados en {0}",
        "t_log_falha": u"Fallo en {0}",
        "t_log_fim": u"DDAC Google Translate - FIN",
        "t_lote_inicio": u"Lote {0}/{1}  ->  {2} texto(s) enviado(s)",
        "t_lote_ok": u"Lote {0}/{1} OK  ->  {2} texto(s) traducido(s) en {3:.1f}s",
        "t_lote_erro": u"Lote {0}/{1} FALLÓ  ->  {2}",
        "t_fallback": u"Fallback individual iniciado para el lote {0}/{1}",
        "t_progresso": u"Progreso: {0}/{1} textos  |  {2} lote(s) OK  |  {3} fallo(s)",
        "t_config_paralela": u"Paralelo: {0} solicitudes simultáneas  |  hasta {1} textos por lote  |  {2} caracteres por lote",
        "t_cache": u"Caché: {0} traducción(es) reutilizada(s)",
        "t_arquivo_inicio": u"INICIO  {0}  ->  {1} texto(s)",
        "t_arquivo_fim": u"FIN  {0}  ->  {1} texto(s) en {2:.1f}s",
        "etapa_biblioteca": u"Paso 0/3: consultando la biblioteca DDLC/Template ({0} archivos catalogados)...",
        "bib_ignorado": u"IGN {0}  ->  sin diálogo nativo ({1})",
        "bib_novo_texto": u"NUEVO {0}  ->  {1} línea(s) en un archivo normalmente sin diálogo ({2})",
        "res_bib_ignorados": u"Archivos ignorados por la biblioteca ({0}):",
        "res_bib_novos": u"Archivos fuera del estándar de la biblioteca (texto nuevo) ({0}):",
        "log_bib_ignorado": u"{0}: ignorado por la biblioteca -- {1}",
        "log_bib_novo": u"{0}: texto nuevo en archivo sin diálogo nativo -- {1}",
        "log_res_bib_ignorados": u"Ignorados por la biblioteca",
        "log_res_bib_novos": u"Archivos con texto fuera del estándar",
    },
}


PREFLIGHT_MENSAGENS = {
    1: {
        "titulo": u"VERIFICAÇÃO PRÉVIA (SOMENTE LEITURA)",
        "subtitulo": u"Nada no jogo, no mapa ou nas pastas de trabalho será modificado nesta etapa.",
        "etapa_extrair": u"Extração de diálogos",
        "etapa_traduzir": u"Tradução com Google Translate",
        "etapa_reinjetar": u"Reintegração de tradução",
        "ok": u"OK", "aviso": u"AVISO", "erro": u"ERRO",
        "apto": u"PRÉ-FLIGHT: APTO",
        "apto_aviso": u"PRÉ-FLIGHT: APTO COM AVISO",
        "bloqueado": u"PRÉ-FLIGHT: BLOQUEADO",
        "game": u"Game original", "fontes": u"Fontes Ren'Py visíveis",
        "rpy": u".rpy", "rpym": u".rpym", "renpy_py": u"_ren.py", "txt": u".txt",
        "compilados": u"Compilados/arquivos empacotados", "rpyc": u".rpyc", "rpymc": u".rpymc", "rpa": u".rpa",
        "mapa": u"Mapa DDAC", "entradas": u"Entradas no mapa",
        "arquivos_mapa": u"Arquivos no mapa", "arquivos_entrada": u"Arquivos na pasta de trabalho",
        "correspondencia": u"Correspondência dos textos",
        "fontes_reinj_titulo": u"FONTES DISPONÍVEIS PARA REINTEGRAÇÃO",
        "fontes_reinj_total": u"{0} fonte(s) encontrada(s)",
        "fontes_reinj_item": u"[{0}] {1}",
        "fontes_reinj_pasta": u"Pasta",
        "fontes_reinj_caminho": u"Caminho",
        "fontes_reinj_arquivos": u"Arquivos",
        "fontes_reinj_textos": u"Textos",
        "fontes_reinj_correspondencia": u"Correspondência",
        "triplo": u"Monólogo com aspas triplas",
        "triplo_msg": u"Foram encontradas strings triplas de possível monólogo; elas recebem aviso porque esse formato exige análise específica para não alterar a estrutura.",
        "tl": u"Pasta tl existente",
        "tl_msg": u"A pasta tl foi identificada e será ignorada pelo extrator; seu conteúdo não participa da tradução nem da reinjeção.",
        "sem_fonte": u"Não há fonte .rpy/.rpym/_ren.py visível no game.",
        "compilado_only": u"Há arquivos .rpyc/.rpymc/.rpa, mas não há fonte de script visível. Descompacte/descompile o projeto antes de usar a extração de diálogos.",
        "game_inexistente": u"A pasta game não foi encontrada e a raiz também não parece ser um diretório de game válido.",
        "entrada_inexistente": u"Nenhuma pasta de diálogos extraídos compatível foi encontrada.",
        "mapa_inexistente": u"O arquivo de mapa não foi encontrado.",
        "mapa_leitura": u"Falha ao ler o mapa: {0}",
        "nenhum_texto": u"A pasta de trabalho não contém entradas de texto compatíveis com o mapa.",
        "contagem": u"O mapa espera {0} texto(s), mas a pasta contém {1} texto(s).",
        "sem_saida": u"Ainda não existe uma pasta traduzida; isso é esperado antes da tradução.",
        "continuar": u"A etapa pode continuar.",
    },
    2: {
        "titulo": u"PREFLIGHT CHECK (READ-ONLY)",
        "subtitulo": u"Nothing in the game, map, or work folders will be modified during this check.",
        "etapa_extrair": u"Dialogue extraction", "etapa_traduzir": u"Google Translate", "etapa_reinjetar": u"Translation reinjection",
        "ok": u"OK", "aviso": u"WARNING", "erro": u"ERROR",
        "apto": u"PREFLIGHT: READY", "apto_aviso": u"PREFLIGHT: READY WITH WARNING", "bloqueado": u"PREFLIGHT: BLOCKED",
        "game": u"Original game", "fontes": u"Visible Ren'Py sources", "rpy": u".rpy", "rpym": u".rpym", "renpy_py": u"_ren.py", "txt": u".txt",
        "compilados": u"Compiled/packed files", "rpyc": u".rpyc", "rpymc": u".rpymc", "rpa": u".rpa",
        "mapa": u"DDAC map", "entradas": u"Map entries", "arquivos_mapa": u"Files in map", "arquivos_entrada": u"Files in work folder",
        "correspondencia": u"Text correspondence",
        "fontes_reinj_titulo": u"AVAILABLE SOURCES FOR REINJECTION",
        "fontes_reinj_total": u"{0} source(s) found",
        "fontes_reinj_item": u"[{0}] {1}",
        "fontes_reinj_pasta": u"Folder",
        "fontes_reinj_caminho": u"Path",
        "fontes_reinj_arquivos": u"Files",
        "fontes_reinj_textos": u"Texts",
        "fontes_reinj_correspondencia": u"Correspondence",
        "triplo": u"Triple-quoted monologue",
        "triplo_msg": u"Triple-quoted strings that may be monologues were found; they receive a warning because this format needs specific handling to avoid changing structure.",
        "tl": u"Existing tl folder", "tl_msg": u"The tl folder was detected and will be ignored by the extractor; its contents do not participate in translation or reinjection.",
        "sem_fonte": u"No visible .rpy/.rpym/_ren.py source was found in the game.",
        "compilado_only": u".rpyc/.rpymc/.rpa files exist, but no visible script source exists. Unpack/decompile the project before using dialogue extraction.",
        "game_inexistente": u"The game folder was not found and the root does not look like a valid game directory.",
        "entrada_inexistente": u"No compatible extracted-dialogue folder was found.", "mapa_inexistente": u"The map file was not found.",
        "mapa_leitura": u"Failed to read the map: {0}", "nenhum_texto": u"The work folder contains no text entries compatible with the map.",
        "contagem": u"The map expects {0} text(s), but the folder contains {1} text(s).",
        "sem_saida": u"No translated output folder exists yet; that is expected before translation.", "continuar": u"The step can continue.",
    },
    3: {
        "titulo": u"VERIFICACIÓN PREVIA (SOLO LECTURA)",
        "subtitulo": u"Nada en el juego, el mapa o las carpetas de trabajo será modificado durante esta comprobación.",
        "etapa_extrair": u"Extracción de diálogos", "etapa_traduzir": u"Google Translate", "etapa_reinjetar": u"Reintegración de traducción",
        "ok": u"OK", "aviso": u"AVISO", "erro": u"ERROR",
        "apto": u"PREFLIGHT: APTO", "apto_aviso": u"PREFLIGHT: APTO CON AVISO", "bloqueado": u"PREFLIGHT: BLOQUEADO",
        "game": u"Juego original", "fontes": u"Fuentes Ren'Py visibles", "rpy": u".rpy", "rpym": u".rpym", "renpy_py": u"_ren.py", "txt": u".txt",
        "compilados": u"Compilados/archivos empaquetados", "rpyc": u".rpyc", "rpymc": u".rpymc", "rpa": u".rpa",
        "mapa": u"Mapa DDAC", "entradas": u"Entradas en el mapa", "arquivos_mapa": u"Archivos en el mapa", "arquivos_entrada": u"Archivos en la carpeta de trabajo",
        "correspondencia": u"Correspondência de textos",
        "fontes_reinj_titulo": u"FUENTES DISPONIBLES PARA LA REINSERCIÓN",
        "fontes_reinj_total": u"{0} fuente(s) encontrada(s)",
        "fontes_reinj_item": u"[{0}] {1}",
        "fontes_reinj_pasta": u"Carpeta",
        "fontes_reinj_caminho": u"Ruta",
        "fontes_reinj_arquivos": u"Archivos",
        "fontes_reinj_textos": u"Textos",
        "fontes_reinj_correspondencia": u"Correspondencia",
        "triplo": u"Monólogo con comillas triples",
        "triplo_msg": u"Se encontraron cadenas triples que pueden ser monólogos; reciben un aviso porque este formato necesita un manejo específico para no cambiar la estructura.",
        "tl": u"Carpeta tl existente", "tl_msg": u"Se detectó la carpeta tl y el extractor la ignorará; su contenido no participa en la traducción ni la reinyección.",
        "sem_fonte": u"No se encontró una fuente .rpy/.rpym/_ren.py visible en el juego.",
        "compilado_only": u"Existen .rpyc/.rpymc/.rpa, pero no hay fuente de script visible. Desempaqueta/descompila el proyecto antes de usar la extracción de diálogos.",
        "game_inexistente": u"No se encontró la carpeta game y la raíz tampoco parece un directorio game válido.",
        "entrada_inexistente": u"No se encontró una carpeta compatible de diálogos extraídos.", "mapa_inexistente": u"No se encontró el archivo de mapa.",
        "mapa_leitura": u"No se pudo leer el mapa: {0}", "nenhum_texto": u"La carpeta de trabajo no contiene entradas de texto compatibles con el mapa.",
        "contagem": u"El mapa espera {0} texto(s), pero la carpeta contiene {1} texto(s).",
        "sem_saida": u"Todavía no existe una carpeta traducida; esto es esperado antes de traducir.", "continuar": u"La etapa puede continuar.",
    },
}


def ptext(chave):
    return PREFLIGHT_MENSAGENS.get(IDIOMA, PREFLIGHT_MENSAGENS[1]).get(chave, PREFLIGHT_MENSAGENS[1][chave])


def t(chave):
    return MENSAGENS.get(IDIOMA, MENSAGENS[1]).get(chave, MENSAGENS[1][chave])

# Mensagens da camada DualBrain: todos os textos visíveis desta camada ficam
# disponíveis nos três idiomas para impedir regressões de interface.
DUAL_MENSAGENS = {
    1: {
        "titulo": u"DDAC Extração Dual - V118",
        "nova_execucao": u"NOVA EXECUÇÃO: relatório diagnóstico é temporário e será removido ao concluir com sucesso.",
        "game_missing": u"Pasta game não encontrada.",
        "stage1_start": u"ETAPA 1/14 - Escaneando a pasta game...",
        "stage1_done": u"ETAPA 1/14 - Escanear game: {0} arquivo(s) [OK]",
        "stage2_start": u"ETAPA 2/14 - Motor DDAC: iniciando extração...",
        "stage2_done": u"ETAPA 2/14 - Motor DDAC: {0} candidatos [OK]",
        "stage3_start": u"ETAPA 3/14 - Motor Ren'Py: iniciando Oráculo...",
        "stage3_done": u"ETAPA 3/14 - Motor Ren'Py: {0} candidatos | ativo={1} [{2}]",
        "stage4_done": u"ETAPA 4/14 - Comparação: concordâncias={0} | DDAC-only={1} | Ren'Py-only={2} [OK]",
        "stage5_done": u"ETAPA 5/14 - Duplicatas consolidadas: {0} [OK]",
        "stage6_done": u"ETAPA 6/14 - Sobreposições resolvidas: {0} conflito(s) [OK]",
        "stage7_done": u"ETAPA 7/14 - Contexto: {0} [OK]",
        "stage8_done": u"ETAPA 8/14 - Classificação: aceitos={0} | revisão={1} | ignorados={2} | engine-common={3} | globais={4} [OK]",
        "stage9_done": u"ETAPA 9/14 - Mapa canônico: {0} entradas [OK]",
        "stage10_pending": u"ETAPA 10/14 - Preparação para tradução: PENDENTE (Opção 2)",
        "stage11_pending": u"ETAPA 11/14 - Validação de tokens: PENDENTE (após Opção 2)",
        "stage12_pending": u"ETAPA 12/14 - Reintegração: PENDENTE (Opção 3)",
        "stage13_pending": u"ETAPA 13/14 - Validação da saída: PENDENTE (Opção 3)",
        "stage14_pending": u"ETAPA 14/14 - Auditoria final: PENDENTE (Opção 3)",
        "pending_log": u"ETAPAS 10-14: adiadas corretamente para tradução/reintegração; não são declaradas executadas na extração.",
        "blocked_log": u"DUALBRAIN BLOQUEADO: o motor Ren'Py não foi ativado. O motor DDAC não continuará sozinho.",
        "blocked_reason": u"Oráculo Ren'Py obrigatório inativo; detalhes registrados no diagnóstico do SDK.",
        "final_status": u"EXTRAÇÃO DUAL CONCLUÍDA",
        "oracle_yes": u"SIM",
        "oracle_no": u"NÃO",
        "status_ok": u"OK",
        "status_fail": u"FALHA",
        "label_status": u"Status final",
        "label_scanned": u"Arquivos escaneados",
        "label_ddac": u"Candidatos DDAC",
        "label_renpy": u"Candidatos Ren'Py",
        "label_concord": u"Concordâncias DDAC + Ren'Py",
        "label_only_ddac": u"Somente DDAC",
        "label_only_renpy": u"Somente Ren'Py",
        "label_canonical": u"Entradas canônicas",
        "label_oracle": u"Oráculo Ren'Py ativo",
        "label_executed": u"Etapas executadas",
        "label_pending": u"Etapas pendentes",
        "label_time": u"Tempo total",
        "internal_error": u"ERRO INTERNO NO DUALBRAIN V118: {0}",
        "internal_final": u"ERRO_INTERNO",
        "translate_stage": u"ETAPA 10/14 - Google Translate recebe somente entradas canônicas.",
        "tokens_stage": u"ETAPA 11/14 - Validação final de tokens: {0}",
        "reinject_stage": u"ETAPA 12/14 - Reintegração canônica...",
        "output_stage": u"ETAPA 13/14 - Validação da saída: OK",
        "audit_stage": u"ETAPA 14/14 - Auditoria final: verificando colisões e compilados...",
        "audit_summary": u"ETAPA 14/14 - Auditoria de colisões: removidos={0} | conflitos={1} | preservados={2} | .rpyc pareados reportados={3}",
        "installer": u"Aplicador seguro: {0}",
        "label_removed": u"Scripts game/common removidos por hash idêntico",
        "label_conflicts": u"Conflitos game/common",
        "label_preserved": u"Preservados por mapa antigo",
        "report_title": u"Relatório de colisões do DDAC",
        "report_no_issue": u"Nenhuma colisão ou inconsistência foi encontrada.",
        "report_issue": u"Foram encontradas ocorrências que exigem atenção.",
    },
    2: {
        "titulo": u"DDAC Dual Extraction - V118",
        "nova_execucao": u"NEW RUN: diagnostic report is temporary and will be removed after successful completion.",
        "game_missing": u"Game folder not found.",
        "stage1_start": u"STAGE 1/14 - Scanning the game folder...",
        "stage1_done": u"STAGE 1/14 - Scan game: {0} file(s) [OK]",
        "stage2_start": u"STAGE 2/14 - DDAC engine: starting extraction...",
        "stage2_done": u"STAGE 2/14 - DDAC engine: {0} candidate(s) [OK]",
        "stage3_start": u"STAGE 3/14 - Ren'Py engine: starting Oracle...",
        "stage3_done": u"STAGE 3/14 - Ren'Py engine: {0} candidate(s) | active={1} [{2}]",
        "stage4_done": u"STAGE 4/14 - Comparison: matches={0} | DDAC-only={1} | Ren'Py-only={2} [OK]",
        "stage5_done": u"STAGE 5/14 - Duplicates consolidated: {0} [OK]",
        "stage6_done": u"STAGE 6/14 - Overlaps resolved: {0} conflict(s) [OK]",
        "stage7_done": u"STAGE 7/14 - Context: {0} [OK]",
        "stage8_done": u"STAGE 8/14 - Classification: accepted={0} | review={1} | ignored={2} | engine-common={3} | global={4} [OK]",
        "stage9_done": u"STAGE 9/14 - Canonical map: {0} entries [OK]",
        "stage10_pending": u"STAGE 10/14 - Translation preparation: PENDING (Option 2)",
        "stage11_pending": u"STAGE 11/14 - Token validation: PENDING (after Option 2)",
        "stage12_pending": u"STAGE 12/14 - Reintegration: PENDING (Option 3)",
        "stage13_pending": u"STAGE 13/14 - Output validation: PENDING (Option 3)",
        "stage14_pending": u"STAGE 14/14 - Final audit: PENDING (Option 3)",
        "pending_log": u"STAGES 10-14: correctly deferred to translation/reintegration; they are not marked as executed during extraction.",
        "blocked_log": u"DUALBRAIN BLOCKED: the Ren'Py engine was not activated. The DDAC engine will not continue alone.",
        "blocked_reason": u"Required Ren'Py Oracle inactive; details are recorded in the SDK diagnostics.",
        "final_status": u"DUAL EXTRACTION COMPLETED",
        "oracle_yes": u"YES",
        "oracle_no": u"NO",
        "status_ok": u"OK",
        "status_fail": u"FAILED",
        "label_status": u"Final status",
        "label_scanned": u"Files scanned",
        "label_ddac": u"DDAC candidates",
        "label_renpy": u"Ren'Py candidates",
        "label_concord": u"DDAC + Ren'Py matches",
        "label_only_ddac": u"DDAC-only",
        "label_only_renpy": u"Ren'Py-only",
        "label_canonical": u"Canonical entries",
        "label_oracle": u"Ren'Py Oracle active",
        "label_executed": u"Stages executed",
        "label_pending": u"Pending stages",
        "label_time": u"Total time",
        "internal_error": u"INTERNAL ERROR IN DUALBRAIN V118: {0}",
        "internal_final": u"INTERNAL_ERROR",
        "translate_stage": u"STAGE 10/14 - Google Translate receives only canonical entries.",
        "tokens_stage": u"STAGE 11/14 - Final token validation: {0}",
        "reinject_stage": u"STAGE 12/14 - Canonical reintegration...",
        "output_stage": u"STAGE 13/14 - Output validation: OK",
        "audit_stage": u"STAGE 14/14 - Final audit: checking collisions and compiled files...",
        "audit_summary": u"STAGE 14/14 - Collision audit: removed={0} | conflicts={1} | preserved={2} | paired .rpyc reported={3}",
        "installer": u"Safe installer: {0}",
        "label_removed": u"game/common scripts removed by identical hash",
        "label_conflicts": u"game/common conflicts",
        "label_preserved": u"Preserved by old map",
        "report_title": u"DDAC Collision Report",
        "report_no_issue": u"No collision or inconsistency was found.",
        "report_issue": u"Occurrences requiring attention were found.",
    },
    3: {
        "titulo": u"DDAC Extracción Dual - V118",
        "nova_execucao": u"NUEVA EJECUCIÓN: el informe de diagnóstico es temporal y se eliminará al completar correctamente.",
        "game_missing": u"No se encontró la carpeta game.",
        "stage1_start": u"ETAPA 1/14 - Escaneando la carpeta game...",
        "stage1_done": u"ETAPA 1/14 - Escanear game: {0} archivo(s) [OK]",
        "stage2_start": u"ETAPA 2/14 - Motor DDAC: iniciando extracción...",
        "stage2_done": u"ETAPA 2/14 - Motor DDAC: {0} candidato(s) [OK]",
        "stage3_start": u"ETAPA 3/14 - Motor Ren'Py: iniciando Oráculo...",
        "stage3_done": u"ETAPA 3/14 - Motor Ren'Py: {0} candidato(s) | activo={1} [{2}]",
        "stage4_done": u"ETAPA 4/14 - Comparación: coincidencias={0} | solo-DDAC={1} | solo-Ren'Py={2} [OK]",
        "stage5_done": u"ETAPA 5/14 - Duplicados consolidados: {0} [OK]",
        "stage6_done": u"ETAPA 6/14 - Superposiciones resueltas: {0} conflicto(s) [OK]",
        "stage7_done": u"ETAPA 7/14 - Contexto: {0} [OK]",
        "stage8_done": u"ETAPA 8/14 - Clasificación: aceptados={0} | revisión={1} | ignorados={2} | engine-common={3} | globales={4} [OK]",
        "stage9_done": u"ETAPA 9/14 - Mapa canónico: {0} entradas [OK]",
        "stage10_pending": u"ETAPA 10/14 - Preparación para traducción: PENDIENTE (Opción 2)",
        "stage11_pending": u"ETAPA 11/14 - Validación de tokens: PENDIENTE (después de la Opción 2)",
        "stage12_pending": u"ETAPA 12/14 - Reintegración: PENDIENTE (Opción 3)",
        "stage13_pending": u"ETAPA 13/14 - Validación de salida: PENDIENTE (Opción 3)",
        "stage14_pending": u"ETAPA 14/14 - Auditoría final: PENDIENTE (Opción 3)",
        "pending_log": u"ETAPAS 10-14: correctamente aplazadas para traducción/reintegración; no se declaran ejecutadas durante la extracción.",
        "blocked_log": u"DUALBRAIN BLOQUEADO: el motor Ren'Py no se activó. El motor DDAC no continuará por sí solo.",
        "blocked_reason": u"El Oráculo Ren'Py obligatorio está inactivo; los detalles están registrados en el diagnóstico del SDK.",
        "final_status": u"EXTRACCIÓN DUAL COMPLETADA",
        "oracle_yes": u"SÍ",
        "oracle_no": u"NO",
        "status_ok": u"OK",
        "status_fail": u"FALLO",
        "label_status": u"Estado final",
        "label_scanned": u"Archivos escaneados",
        "label_ddac": u"Candidatos DDAC",
        "label_renpy": u"Candidatos Ren'Py",
        "label_concord": u"Coincidencias DDAC + Ren'Py",
        "label_only_ddac": u"Solo DDAC",
        "label_only_renpy": u"Solo Ren'Py",
        "label_canonical": u"Entradas canónicas",
        "label_oracle": u"Oráculo Ren'Py activo",
        "label_executed": u"Etapas ejecutadas",
        "label_pending": u"Etapas pendientes",
        "label_time": u"Tiempo total",
        "internal_error": u"ERROR INTERNO EN DUALBRAIN V118: {0}",
        "internal_final": u"ERROR_INTERNO",
        "translate_stage": u"ETAPA 10/14 - Google Translate recibe solamente entradas canónicas.",
        "tokens_stage": u"ETAPA 11/14 - Validación final de tokens: {0}",
        "reinject_stage": u"ETAPA 12/14 - Reintegración canónica...",
        "output_stage": u"ETAPA 13/14 - Validación de salida: OK",
        "audit_stage": u"ETAPA 14/14 - Auditoría final: comprobando colisiones y compilados...",
        "audit_summary": u"ETAPA 14/14 - Auditoría de colisiones: eliminados={0} | conflictos={1} | preservados={2} | .rpyc emparejados reportados={3}",
        "installer": u"Aplicador seguro: {0}",
        "label_removed": u"Scripts game/common eliminados por hash idéntico",
        "label_conflicts": u"Conflictos game/common",
        "label_preserved": u"Preservados por mapa antiguo",
        "report_title": u"Informe de colisiones de DDAC",
        "report_no_issue": u"No se encontró ninguna colisión o inconsistencia.",
        "report_issue": u"Se encontraron incidencias que requieren atención.",
    },
}

COLISAO_RELATORIO_ROTULOS = {
    1: {
        "removidos": u"Scripts removidos por hash idêntico",
        "conflitos": u"Conflitos game/common diferentes",
        "preservados": u"Arquivos preservados por mapa antigo",
        "rpyc": u"Arquivos .rpyc pareados reportados",
        "rpyc_nao_apagados": u".rpyc pareados não apagados",
        "instalacao": u"A instalação final substitui a pasta game inteiramente",
        "idioma": u"Português",
    },
    2: {
        "removidos": u"Scripts removed by identical hash",
        "conflitos": u"Different game/common conflicts",
        "preservados": u"Files preserved by old map",
        "rpyc": u"Paired .rpyc files reported",
        "rpyc_nao_apagados": u"Paired .rpyc files not deleted",
        "instalacao": u"The final installation replaces the game folder entirely",
        "idioma": u"English",
    },
    3: {
        "removidos": u"Scripts eliminados por hash idéntico",
        "conflitos": u"Conflictos game/common diferentes",
        "preservados": u"Archivos preservados por mapa antiguo",
        "rpyc": u"Archivos .rpyc emparejados reportados",
        "rpyc_nao_apagados": u".rpyc emparejados no eliminados",
        "instalacao": u"La instalación final sustituye por completo la carpeta game",
        "idioma": u"Español",
    },
}

def dt(chave, *args):
    valor = DUAL_MENSAGENS.get(IDIOMA, DUAL_MENSAGENS[1]).get(chave, DUAL_MENSAGENS[1][chave])
    return valor.format(*args) if args else valor


QSTR = r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
LINHA_DIALOGO = re.compile(r'^(?:(?:\w+|' + QSTR + r')\s+){0,2}(' + QSTR + r').*$')
TEXTO_UI = re.compile(r'_\(\s*(' + QSTR + r')\s*\)')
# Placeholders puros de data/hora são texto traduzível quando marcados explicitamente
# com _()/__()/_p(). Eles não são código: precisam entrar no mapa para que a
# tradução preserve os tokens {hour}, {minute}, {month}, {day} e {year}.
PLACEHOLDER_TRADUZIVEL_RE = re.compile(r'^\s*\{[A-Za-z_][A-Za-z0-9_.]*\}(?:\s*[:/\-]\s*\{[A-Za-z_][A-Za-z0-9_.]*\})+\s*$')
PRIMEIRA_PALAVRA = re.compile(r'^(\w+)')

PALAVRAS_DEFINICAO = {"define", "default"}
NOME_PERSONAGEM = re.compile(r'(?<!Dynamic)Character\(\s*(?:name\s*=\s*)?(' + QSTR + r')')
DYNAMIC_CHARACTER = re.compile(r'DynamicCharacter\(\s*(?:name\s*=\s*)?(' + QSTR + r')')
VARIAVEL_DEFINICAO = re.compile(r'^(?:define|default)\s+([\w.]+)\s*=')
VALOR_STRING_SIMPLES = re.compile(r'^(?:define|default)\s+[\w.]+\s*=\s*(' + QSTR + r')\s*$')
PREFIXOS_TECNICOS = ("build.",)
NOMES_TECNICOS_CONHECIDOS = {
    "config.window", "config.save_directory", "config.gl_test_image",
    "config.window_icon", "config.save_json_callbacks",
}
EXTENSOES_TECNICAS = (
    "ttf", "otf", "png", "jpg", "jpeg", "webp", "webm", "ogg", "mp3", "wav",
    "rpy", "rpyc", "rpa", "txt", "ico",
)
# Referências a arquivos/recursos não são diálogos traduzíveis.
# Além das extensões conhecidas, o scanner compara cada texto entre aspas
# com um índice de todos os arquivos existentes dentro da pasta game.
# Exemplos: "gui/menu_art_y.png", "gui/overlay/main_menu.png".
REFERENCIA_ARQUIVO = re.compile(
    r'^(?:[A-Za-z0-9_.-]+[\\/])+[^\\/\s]+\.(?:'
    + "|".join(EXTENSOES_TECNICAS)
    + r')$',
    re.IGNORECASE
)
# Recursos com tags de loop/fade/ATL: são parâmetros técnicos, não falas.
RECURSO_COM_TAG = re.compile(
    r'^(?:<[^>]+>\s*)+(?:[A-Za-z0-9_.()\- ]+[\\/])+[^\\/]+\.(?:ogg|mp3|wav|flac|m4a|webm)$',
    re.IGNORECASE
)
RECURSO_COM_TAG_SEM_PASTA = re.compile(
    r'^(?:<[^>]+>\s*)+(?:[^\\/]+\.(?:ogg|mp3|wav|flac|m4a|webm))$',
    re.IGNORECASE
)
RECURSO_CAMINHO = re.compile(
    r'^(?:[A-Za-z0-9_.()\- ]+[\\/])+[^\\/]+\.(?:ttf|otf|png|jpg|jpeg|gif|webp|webm|ogg|mp3|wav|flac|m4a|rpy|rpyc|rpa|ico|json|chr|py|pyc|dll|so|apk)$',
    re.IGNORECASE
)

ATRIBUICAO_DOLAR = re.compile(r'^\$\s*([\w.]+)\s*=\s*(' + QSTR + r')\s*$')

PALAVRAS_RESERVADAS = {
    "voice", "fit", "image", "play", "queue", "stop", "scene", "show", "hide",
    "with", "window", "pause", "screen", "label", "jump", "call", "return",
    "python", "init", "define", "default", "translate", "style", "transform",
    "layeredimage", "menu", "if", "elif", "else", "while", "for", "pass",
    "continue", "break", "nvl", "camera", "physics",
    "font", "color", "hover_color", "selected_color", "insensitive_color",
    "idle_color", "add", "key", "keysym", "id", "style_prefix", "background",
    "foreground", "thumb", "base_bar", "top_bar", "bottom_bar", "unscrollable",
    "scrollbars", "layout", "outlines", "hover_outlines", "input", "caret",
    "size_group", "on", "action", "value", "adjustment", "properties",
    "xpos", "ypos", "xalign", "yalign", "xanchor", "yanchor", "xsize", "ysize",
    "xoffset", "yoffset", "spacing", "padding", "margin", "at", "tooltip",
    "hover_sound", "activate_sound", "focus_mask", "range", "alt",
}

# =============================================================================
# UTILITÁRIOS DE ARQUIVOS / LOGS
# =============================================================================
class Log(object):
    def __init__(self, caminho):
        self.caminho = caminho
        self.linhas = []
        self._lock = threading.RLock()

    def separador(self):
        with self._lock:
            self.linhas.append(u"=" * 60)

    def titulo(self, texto):
        with self._lock:
            self.linhas.append(texto)

    def _tag(self, tag, mensagem):
        with self._lock:
            self.linhas.append(u"[{0}] {1}".format(tag, mensagem))

    def info(self, mensagem):
        self._tag(t("log_tag_info"), mensagem)

    def aviso(self, mensagem):
        self._tag(t("log_tag_aviso"), mensagem)

    def erro(self, mensagem):
        self._tag(t("log_tag_erro"), mensagem)

    def resultado(self, rotulo, valor):
        with self._lock:
            rotulo_padded = (rotulo + u" " * 34)[:34]
            self.linhas.append(u"{0}: {1}".format(rotulo_padded, valor))

    def salvar(self):
        with self._lock:
            dados = u"\n".join(self.linhas) + u"\n"
        temp = self.caminho + u".tmp"
        # Normaliza apenas um eventual `\` colado antes dos separadores `====`.
        # Isso não altera caminhos, mensagens ou conteúdo de usuário.
        dados = re.sub(r'(?m)^\\(?=={20,}$)', u"", dados)
        with io.open(temp, "w", encoding="utf-8") as f:
            f.write(dados)
        os.replace(temp, self.caminho)


def anexar_linhas_log(caminho, linhas):
    try:
        with io.open(caminho, "a", encoding="utf-8") as f:
            if os.path.isfile(caminho) and os.path.getsize(caminho) > 0:
                f.write(u"\n")
            for linha in linhas:
                f.write(linha + u"\n")
    except Exception:
        pass


def _inspecionar_pastas_tl(pasta_game):
    encontradas = []
    if not os.path.isdir(pasta_game):
        return encontradas
    for pasta_atual, subpastas, arquivos in os.walk(pasta_game):
        if os.path.basename(pasta_atual).lower() != "tl":
            continue
        rel_tl = os.path.relpath(pasta_atual, pasta_game).replace(os.sep, "/")
        idiomas = []
        for nome in sorted(subpastas):
            caminho = os.path.join(pasta_atual, nome)
            if os.path.isdir(caminho):
                idiomas.append(nome)
        encontradas.append({"caminho": rel_tl, "idiomas": idiomas, "arquivos": len(arquivos)})
    return encontradas


def encontrar_pasta_game(raiz):
    candidato = os.path.join(raiz, "game")
    if os.path.isdir(candidato):
        return candidato
    return raiz


# --- Arquivo-base explicitamente bloqueado na extração ---
# script-poemresponses.rpy é um arquivo-base do DDLC/Template que não deve entrar
# na extração automática. O bloqueio é feito pelo nome-base, independentemente
# da pasta em que o arquivo esteja localizado.
POEMRESPONSES_BASE_NAME = u"script-poemresponses.rpy"


def _ler_texto_arquivo_seguros_poemresponses(caminho):
    try:
        bruto = b""
        with open(caminho, "rb") as f:
            bruto = f.read()
        return bruto.decode("utf-8", "ignore")
    except Exception:
        try:
            return u"".join(ler_linhas_raw(caminho))
        except Exception:
            return u""


def _assinatura_poemresponses_base(caminho):
    """Pontua a semelhança estrutural com o script-poemresponses do DDLC/template.

    Não usa hash exato, porque mods frequentemente acrescentam/removem linhas no
    arquivo-base. A decisão só é positiva quando vários elementos característicos
    aparecem juntos.
    """
    if os.path.basename(caminho).lower() != POEMRESPONSES_BASE_NAME:
        return 0
    texto = _ler_texto_arquivo_seguros_poemresponses(caminho)
    if not texto:
        return 0
    score = 0
    if re.search(r'(?m)^\s*label\s+poemresponse_start\s*:', texto):
        score += 3
    if re.search(r'(?m)^\s*label\s+poemresponse_(?:loop|start2)\s*:', texto):
        score += 1
    if re.search(r'(?m)^\s*label\s+poemresponse_(?:sayori|natsuki|yuri|monika|callback)\b', texto, re.I):
        score += 1
    if re.search(r'\bcall\s+showpoem\s*\(', texto, re.I):
        score += 1
    if re.search(r'\bcall\s+expression\s+nextscene\b', texto, re.I):
        score += 1
    if re.search(r'\b(?:poemopinion|poemappeal|skip_poem|poemsread)\b', texto, re.I):
        score += 1
    labels_ch = re.findall(r'(?m)^\s*label\s+ch\d+_(?:s|n|y|m)_(?:bad|med|good|end)(?:\w*)\s*:', texto, re.I)
    if len(labels_ch) >= 4:
        score += 4
    elif len(labels_ch) >= 2:
        score += 2
    return score


def _poemresponses_referenciado_externamente(pasta_game, caminho_alvo):
    """Verdadeiro quando outro arquivo do jogo parece chamar/usar labels desse arquivo.

    A busca é deliberadamente conservadora: qualquer ocorrência externa dos labels
    característicos impede o descarte. Isso prefere traduzir a mais do que correr o
    risco de ignorar um arquivo realmente utilizado.
    """
    texto_alvo = _ler_texto_arquivo_seguros_poemresponses(caminho_alvo)
    if not texto_alvo:
        return True
    nomes = set(re.findall(r'(?m)^\s*label\s+([A-Za-z_]\w*)\s*:', texto_alvo))
    nomes.update((u"poemresponse_start", u"poemresponse_loop", u"poemresponse_start2"))
    if not nomes:
        return True
    padrao = re.compile(r'(?<![A-Za-z0-9_])(?:' + u'|'.join(re.escape(n) for n in sorted(nomes, key=len, reverse=True)) + r')(?![A-Za-z0-9_])')
    alvo_abs = os.path.abspath(caminho_alvo)
    ignoradas = set(p.lower() for p in PASTAS_IGNORADAS)
    for pasta_atual, subpastas, arquivos in os.walk(pasta_game):
        subpastas[:] = [d for d in subpastas if d.lower() not in ignoradas]
        for nome in arquivos:
            caminho = os.path.join(pasta_atual, nome)
            if os.path.abspath(caminho).lower() == alvo_abs.lower():
                continue
            low = nome.lower()
            if not low.endswith((".rpy", ".rpym", ".rpyc", ".rpymc", "_ren.py")):
                continue
            try:
                if low.endswith((".rpyc", ".rpymc")):
                    with open(caminho, "rb") as f:
                        dados = f.read()
                    try:
                        texto = dados.decode("utf-8", "ignore")
                    except Exception:
                        texto = dados.decode("latin-1", "ignore")
                else:
                    texto = _ler_texto_arquivo_seguros_poemresponses(caminho)
                if texto and padrao.search(texto):
                    return True
            except Exception:
                # Erro de leitura não autoriza o descarte.
                return True
    return False


def deve_ignorar_poemresponses_nao_usado(pasta_game, caminho):
    # Regra fixa: este arquivo-base não participa da extração, esteja ele
    # na raiz de game ou em qualquer subpasta.
    return os.path.basename(caminho).lower() == POEMRESPONSES_BASE_NAME


def _preflight_contar_fontes(pasta_game):
    contagem = {".rpy": 0, ".rpym": 0, "_ren.py": 0, ".txt": 0, ".rpyc": 0, ".rpymc": 0, ".rpa": 0}
    triples = []
    tl_existente = False
    for pasta_atual, subpastas, arquivos in os.walk(pasta_game):
        if any(d.lower() == "tl" for d in subpastas):
            tl_existente = True
        subpastas[:] = [d for d in subpastas if d not in PASTAS_IGNORADAS]
        for nome in arquivos:
            low = nome.lower()
            ext = None
            if low.endswith(".rpy"): ext = ".rpy"
            elif low.endswith(".rpym"): ext = ".rpym"
            elif low.endswith("_ren.py"): ext = "_ren.py"
            elif low.endswith(".txt"): ext = ".txt"
            elif low.endswith(".rpyc"): ext = ".rpyc"
            elif low.endswith(".rpymc"): ext = ".rpymc"
            elif low.endswith(".rpa"): ext = ".rpa"
            if ext:
                if not (low.endswith((".rpy", ".rpym")) and
                        deve_ignorar_poemresponses_nao_usado(pasta_game, os.path.join(pasta_atual, nome))):
                    contagem[ext] += 1
            # _ren.py uses triple-quoted blocks as part of its Ren'Py syntax,
            # so only ordinary .rpy/.rpym files are warned here.
            if low.endswith((".rpy", ".rpym")):
                caminho = os.path.join(pasta_atual, nome)
                try:
                    bruto = u"".join(ler_linhas_raw(caminho))
                    if re.search(r'(?m)^\s*(?:(?:[A-Za-z_][\w.]*)\s+)?(?:"""|\'\'\')', bruto):
                        triples.append(os.path.relpath(caminho, pasta_game).replace(os.sep, "/"))
                except Exception:
                    pass
    return contagem, triples, tl_existente


def _preflight_ler_mapa(caminho):
    try:
        with io.open(caminho, "r", encoding="utf-8") as f:
            mapa = json.load(f)
    except Exception as exc:
        return None, [ptext("mapa_leitura").format(exc)]
    if not isinstance(mapa, dict):
        return None, [u"Mapa inválido: estrutura principal não é um objeto JSON."]
    entradas = sum(len(v) for v in mapa.values() if isinstance(v, list))
    return mapa, entradas


def _preflight_textos_da_pasta(pasta_entrada, mapa=None):
    total = 0
    arquivos = 0
    problemas = []
    extras = []
    mapa_chaves = set(mapa.keys()) if isinstance(mapa, dict) else None
    if not os.path.isdir(pasta_entrada):
        return arquivos, total, problemas, extras
    for caminho in coletar_candidatos_reinjecao(pasta_entrada):
        rel = os.path.relpath(caminho, pasta_entrada).replace(os.sep, "/")
        if mapa_chaves is not None and rel not in mapa_chaves:
            extras.append(rel)
            continue
        arquivos += 1
        try:
            total += len(ler_textos_traduzidos(caminho))
        except Exception as exc:
            problemas.append(u"{}: {}".format(rel, exc))
    return arquivos, total, problemas, extras


def executar_preflight(raiz, etapa):
    """Checagem somente leitura antes das 3 etapas do fluxo de diálogos."""
    print(u"============================================================")
    print(u" " + ptext("titulo"))
    print(u"============================================================")
    print(u" " + ptext("subtitulo"))
    print(u"")
    nomes = {"extrair": "etapa_extrair", "traduzir": "etapa_traduzir", "reinjetar": "etapa_reinjetar"}
    print(u" " + ptext(nomes.get(etapa, "etapa_extrair")))
    print(u"")

    erros = []
    avisos = []
    pasta_game = encontrar_pasta_game(raiz)
    if not os.path.isdir(pasta_game):
        erros.append(ptext("game_inexistente"))

    if etapa == "extrair":
        if os.path.isdir(pasta_game):
            cont, triples, tl_existente = _preflight_contar_fontes(pasta_game)
        else:
            cont = {k:0 for k in (".rpy", ".rpym", "_ren.py", ".txt", ".rpyc", ".rpymc", ".rpa")}
            triples = []
            tl_existente = False
        total_fontes = cont[".rpy"] + cont[".rpym"] + cont["_ren.py"]
        print(u" {}: {}".format(ptext("game"), pasta_game if os.path.isdir(pasta_game) else u"-"))
        print(u" {}: {}  ({}: {}, {}: {}, {}: {})".format(ptext("fontes"), total_fontes, ptext("rpy"), cont[".rpy"], ptext("rpym"), cont[".rpym"], ptext("renpy_py"), cont["_ren.py"]))
        print(u" {}: {}  ({}: {}, {}: {}, {}: {})".format(ptext("compilados"), cont[".rpyc"]+cont[".rpymc"]+cont[".rpa"], ptext("rpyc"), cont[".rpyc"], ptext("rpymc"), cont[".rpymc"], ptext("rpa"), cont[".rpa"]))
        print(u" {}: {}".format(ptext("txt"), cont[".txt"]))
        if tl_existente:
            print(u" {}: {}".format(ptext("tl"), ptext("aviso")))
            avisos.append(ptext("tl_msg"))
            for item in _inspecionar_pastas_tl(pasta_game):
                nomes = item["idiomas"]
                if nomes:
                    print(u"   {}: {}".format(item["caminho"], u", ".join(nomes)))
                else:
                    print(u"   {}: {}".format(item["caminho"], u"(sem subpastas de idioma)"))
        if triples:
            print(u" {}: {}".format(ptext("triplo"), ptext("aviso")))
            avisos.append(ptext("triplo_msg"))
            for caminho in triples[:12]: print(u"   - {}".format(caminho))
            if len(triples) > 12: print(u"   - ... +{}".format(len(triples)-12))
        if total_fontes == 0:
            if cont[".rpa"] or cont[".rpyc"] or cont[".rpymc"]:
                # V145 lê fontes visíveis; arquivos RPA/RPYC precisam ser extraídos/descompilados antes.
                erros.append(ptext("compilado_only"))
            else:
                erros.append(ptext("sem_fonte"))

    elif etapa == "traduzir":
        pasta_entrada, nome_mapa_escolhido = localizar_pasta_extracao_traducao(raiz)
        print(u" {}: {}".format(ptext("mapa"), pasta_entrada or u"-"))
        if not pasta_entrada:
            erros.append(ptext("entrada_inexistente"))
        else:
            nome_mapa = next((n for n in MAPAS_COMPATIVEIS if os.path.isfile(os.path.join(pasta_entrada, n))), None)
            if not nome_mapa:
                erros.append(ptext("mapa_inexistente"))
            else:
                mapa, valor = _preflight_ler_mapa(os.path.join(pasta_entrada, nome_mapa))
                if mapa is None:
                    erros.extend(valor)
                else:
                    arquivos, textos, problemas, extras = _preflight_textos_da_pasta(pasta_entrada, mapa)
                    print(u" {}: {}".format(ptext("arquivos_mapa"), len(mapa)))
                    print(u" {}: {}".format(ptext("entradas"), valor))
                    print(u" {}: {}".format(ptext("arquivos_entrada"), arquivos))
                    print(u" {}: {}".format(ptext("correspondencia"), ptext("ok") if valor == textos else ptext("erro")))
                    if extras:
                        msg_extras = {
                            1: u"Arquivo(s) fora do mapa encontrado(s) na pasta de trabalho; serão ignorados nesta etapa: {}",
                            2: u"File(s) outside the map found in the work folder; they will be ignored in this step: {}",
                            3: u"Archivo(s) fuera del mapa encontrado(s) en la carpeta de trabajo; se ignorarán en esta etapa: {}",
                        }.get(IDIOMA, u"Arquivo(s) fora do mapa encontrado(s) na pasta de trabalho; serão ignorados nesta etapa: {}")
                        lista_extras = u", ".join(extras[:12]) + (u" ... +{}".format(len(extras)-12) if len(extras) > 12 else u"")
                        avisos.append(msg_extras.format(lista_extras))
                    if valor == 0:
                        erros.append(ptext("nenhum_texto"))
                    elif valor != textos:
                        erros.append(ptext("contagem").format(valor, textos))
                    if problemas: erros.extend(problemas[:10])
                    if not os.path.isdir(os.path.join(raiz, PASTA_TRADUCAO_GOOGLE_NOME)):
                        print(u" {}".format(ptext("sem_saida")))

    elif etapa == "reinjetar":
        print(u" {}: {}".format(ptext("game"), pasta_game))
        print(u"")
        candidatos_dialogos = listar_pastas_dialogos_por_categoria(raiz, {u"extracao", u"traducao"})
        if not candidatos_dialogos:
            print(u" {}: -".format(ptext("mapa")))
            erros.append(ptext("entrada_inexistente"))
        else:
            validos = 0
            print(u"============================================================")
            print(u" {}".format(ptext("fontes_reinj_titulo")))
            print(u"============================================================")
            print(u" {}".format(ptext("fontes_reinj_total").format(len(candidatos_dialogos))))
            print(u"")
            if len(candidatos_dialogos) > 1:
                avisos.append(u"Há múltiplas pastas de diálogos; a etapa de reintegração pedirá a escolha somente depois desta checagem.")
            for idx, (pasta_entrada, nome_mapa, categoria) in enumerate(candidatos_dialogos, 1):
                tipo = t("reinj_tipo_google") if categoria == u"traducao" else t("reinj_tipo_manual")
                nome_pasta = os.path.basename(pasta_entrada)
                print(u" {}".format(ptext("fontes_reinj_item").format(idx, tipo)))
                print(u"   {}: {}".format(ptext("fontes_reinj_pasta"), nome_pasta))
                try:
                    with io.open(os.path.join(pasta_entrada, nome_mapa), "r", encoding="utf-8") as f:
                        mapa = json.load(f)
                except Exception as exc:
                    print(u"   {}: {}".format(ptext("fontes_reinj_correspondencia"), ptext("erro")))
                    print(u"   {}: {}".format(ptext("fontes_reinj_caminho"), pasta_entrada))
                    avisos.append(u"{}: {}".format(nome_pasta, ptext("mapa_leitura").format(exc)))
                    print(u"")
                    continue
                if not isinstance(mapa, dict):
                    avisos.append(u"{}: mapa inválido.".format(nome_pasta))
                    print(u"   {}: {}".format(ptext("fontes_reinj_correspondencia"), ptext("erro")))
                    print(u"   {}: {}".format(ptext("fontes_reinj_caminho"), pasta_entrada))
                    print(u"")
                    continue
                candidatos_arquivo = coletar_candidatos_reinjecao(pasta_entrada)
                pre = validar_pre_reintegracao(pasta_game, pasta_entrada, mapa, candidatos_arquivo)
                print(u"   {}: {}".format(ptext("fontes_reinj_arquivos"), pre["arquivos_validados"]))
                print(u"   {}: {}/{}".format(ptext("fontes_reinj_textos"), pre["entradas_encontradas"], pre["entradas_esperadas"]))
                print(u"   {}: {}".format(ptext("fontes_reinj_correspondencia"), ptext("ok") if not pre["erros"] else ptext("erro")))
                print(u"   {}: {}".format(ptext("fontes_reinj_caminho"), pasta_entrada))
                print(u"")
                if not pre["erros"]:
                    validos += 1
                else:
                    avisos.append(u"{}: {} problema(s) de correspondência; não escolha esta pasta na reintegração.".format(nome_pasta, len(pre["erros"])))
            if validos == 0:
                erros.append(u"Nenhum dos candidatos de reintegração passou na validação prévia.")

    if erros:
        print(u"")
        print(u" " + ptext("bloqueado"))
        for erro in erros[:40]: print(u"  - {}".format(erro))
        return 1
    print(u"")
    if avisos:
        print(u" " + ptext("apto_aviso"))
        for aviso in avisos: print(u"  - {}".format(aviso))
    else:
        print(u" " + ptext("apto"))
    print(u" " + ptext("continuar"))
    print(u"")
    return 0

def ler_linhas_raw(caminho):
    with io.open(caminho, "r", encoding="utf-8", errors="replace", newline="") as f:
        conteudo = f.read()
    return conteudo.splitlines(keepends=True)


def eh_arquivo_gerado(nome):
    return nome.startswith(PREFIXO)


IGNORADOS_EXTRACAO_AUTOMATICA = []

def coletar_candidatos_extracao(pasta_game):
    candidatos = []
    ignoradas = set(p.lower() for p in PASTAS_IGNORADAS)
    for pasta_atual, subpastas, arquivos in os.walk(pasta_game):
        subpastas[:] = [p for p in subpastas if p.lower() not in ignoradas]
        for nome in arquivos:
            caminho = os.path.join(pasta_atual, nome)
            if eh_arquivo_gerado(nome):
                continue
            if not nome.lower().endswith(EXTENSOES):
                continue
            rel_candidato = os.path.relpath(caminho, pasta_game)
            if arquivo_globalmente_ignorado_extracao(rel_candidato):
                IGNORADOS_EXTRACAO_AUTOMATICA.append(rel_candidato.replace(os.sep, "/"))
                continue
            # Não extrair script-poemresponses base quando ele é estruturalmente
            # equivalente ao DDLC/template e não há nenhuma referência externa.
            # A decisão é feita aqui, antes da criação do mapa.
            if deve_ignorar_poemresponses_nao_usado(pasta_game, caminho):
                IGNORADOS_EXTRACAO_AUTOMATICA.append(
                    os.path.relpath(caminho, pasta_game).replace(os.sep, "/"))
                continue
            candidatos.append(caminho)
    return candidatos


def eh_arquivo_lista_palavras_poema(caminho):
    base = os.path.splitext(os.path.basename(caminho or u''))[0].lower()
    normalizado = re.sub(r'[^a-z0-9]+', '', unicodedata.normalize('NFKD', base).encode('ascii', 'ignore').decode('ascii'))
    nomes = POEM_WORDS_NOMES_NORMALIZADOS
    if normalizado in nomes:
        return True
    # Fallback pelo conteúdo: reduz dependência do nome usado por cada mod.
    try:
        with io.open(caminho, 'r', encoding='utf-8', errors='replace', newline='') as f:
            for bruto in f:
                linha = bruto.strip()
                if not linha or linha.startswith('#'):
                    continue
                partes = [x.strip() for x in linha.split(',')]
                if len(partes) >= 4:
                    try:
                        float(partes[1]); float(partes[2]); float(partes[3])
                        return True
                    except Exception:
                        pass
                break
    except Exception:
        pass
    return False


def extrair_txt_lista_palavras_poema(caminho):
    """Extrai somente a primeira coluna (word) das listas CSV de poemas.

    Comentários, cabeçalhos e os três pesos numéricos ficam fora da tradução.
    O mapa guarda a posição da primeira coluna para a reintegração preservar
    integralmente o restante da linha.
    """
    entradas = []
    linhas = ler_linhas_raw(caminho)
    for numero, raw in enumerate(linhas, 1):
        linha = raw.rstrip('\r\n')
        limpa = linha.strip()
        if not limpa or limpa.startswith('#'):
            continue
        partes = linha.split(',')
        if len(partes) < 4:
            continue
        try:
            float(partes[1].strip()); float(partes[2].strip()); float(partes[3].strip())
        except Exception:
            continue
        inicio = len(linha) - len(linha.lstrip())
        palavra = partes[0].strip()
        if not palavra:
            continue
        # Não permitir uma primeira coluna que já seja apenas um número: no
        # formato conhecido isso é índice/peso, não palavra do jogo.
        if re.fullmatch(r'[-+]?\d+(?:\.\d+)?', palavra):
            continue
        inicio_real = linha.find(palavra, inicio)
        fim_real = inicio_real + len(palavra)
        entradas.append({
            'linha': numero,
            'coluna_inicio': inicio_real,
            'coluna_fim': fim_real,
            'original': palavra,
            'tipo': 'poema_palavra_txt',
            'confianca': 100,
            'contexto': u'palavra exibida do banco CSV do minijogo de poemas',
        })
    return entradas


def escrever_txt_palavras_extraido(caminho_origem, caminho_destino, entradas):
    pasta = os.path.dirname(caminho_destino)
    if pasta and not os.path.isdir(pasta):
        os.makedirs(pasta)
    with io.open(caminho_destino, 'w', encoding='utf-8', newline='\n') as f:
        f.write(u'\n'.join(u'    ' + codificar_literal_traducao(e['original']) for e in entradas))
        if entradas:
            f.write(u'\n')


def copiar_arquivo_txt(caminho_origem, caminho_destino):
    pasta_destino = os.path.dirname(caminho_destino)
    if pasta_destino and not os.path.isdir(pasta_destino):
        os.makedirs(pasta_destino)
    with io.open(caminho_origem, "rb") as origem:
        dados = origem.read()
    with io.open(caminho_destino, "wb") as destino:
        destino.write(dados)


def normalizar_referencia_arquivo(valor):
    try:
        valor = valor.replace(u"\\", u"/").strip()
    except Exception:
        return u""
    while valor.startswith(u"./"):
        valor = valor[2:]
    while valor.startswith(u"../"):
        valor = valor[3:]
    while valor.startswith(u"/"):
        valor = valor[1:]
    return valor.replace(u"//", u"/").lower()


def construir_indice_arquivos(pasta_base):
    indice = set()
    if not pasta_base or not os.path.isdir(pasta_base):
        return indice
    ignoradas = set(p.lower() for p in PASTAS_IGNORADAS)
    for pasta_atual, subpastas, arquivos in os.walk(pasta_base):
        subpastas[:] = [p for p in subpastas if p.lower() not in ignoradas]
        for nome in arquivos:
            caminho = os.path.join(pasta_atual, nome)
            try:
                relativo = os.path.relpath(caminho, pasta_base)
            except Exception:
                continue
            indice.add(normalizar_referencia_arquivo(relativo))
            indice.add(normalizar_referencia_arquivo(nome))
    return indice


def referencia_existe_no_mod(valor_com_aspas, indice_arquivos):
    interior = valor_com_aspas[1:-1]
    normalizado = normalizar_referencia_arquivo(interior)
    if not normalizado:
        return True
    if normalizado in indice_arquivos:
        return True
    return False


def eh_renpy_moderno(caminho):
    return caminho.lower().endswith("_ren.py")


def mascarar_secoes_python_renpy(conteudo):
    """Mantém somente as seções Ren'Py de um _ren.py, preservando offsets."""
    if not conteudo:
        return conteudo
    linhas = conteudo.splitlines(True)
    ativo = False
    saida = []
    for linha in linhas:
        marcador = linha.rstrip("\r\n")
        if marcador == '"""renpy':
            ativo = True
            saida.append(linha)
            continue
        if marcador == '"""' and ativo:
            saida.append(linha)
            ativo = False
            continue
        if ativo:
            saida.append(linha)
        else:
            # Preserva quebras e offsets para o mapa.
            saida.append(u"".join(u"\n" if c == u"\n" else (u"\r" if c == u"\r" else u" ") for c in linha))
    return u"".join(saida)


def linhas_renpy_ativas(caminho, linhas_raw):
    if not eh_renpy_moderno(caminho):
        return [True] * len(linhas_raw)
    ativo = False
    resultado = []
    for linha in linhas_raw:
        marcador = linha.rstrip("\r\n")
        if marcador == '"""renpy':
            ativo = True
            resultado.append(True)
            continue
        if marcador == '"""' and ativo:
            resultado.append(True)
            ativo = False
            continue
        resultado.append(ativo)
    return resultado


# --- DDAC safety knowledge layer (additive; legacy extraction remains authoritative) ---

# -----------------------------------------------------------------------------
# ORÁCULO SEMÂNTICO REN'PY (opcional, preferencial quando um SDK compatível
# estiver disponível na máquina do usuário)
# -----------------------------------------------------------------------------
# O DDAC não copia o parser/engine do Ren'Py para dentro do .bat. Em vez disso,
# quando encontra um SDK oficial, chama o próprio CLI/AST de Dialogue/Strings em
# um projeto temporário somente-leitura. Isso permite usar o conhecimento
# semântico real da engine sem abandonar os detectores específicos de DDLC.
ORACULO_RENPY = {
    "ativo": False,
    "sdk": u"",
    "versao": u"",
    "entradas": [],
    "por_arquivo": {},
    "game_root": u"",
    "nativas_total": 0,
    "nativas_mapeadas": 0,
    "nativas_duplicadas": 0,
    "nativas_ambiguas": 0,
    "nativas_multilinha": 0,
    "nativas_cobertura_real": 0,
    "nativas_cobertura_pct": 100.0,
    "nativas_em_escopo": 0,
    "nativas_fora_escopo": 0,
    "nativas_fallback_texto": 0,
    "nativas_nao_localizadas": 0,
    "falhas": [],
    "candidatos": [],
}

RENpy_ESTADOS_TECNICOS = frozenset({
    "ending", "state", "status", "flag", "route", "chapter", "act",
    "scene", "scene_id", "scene_index", "route_id", "route_index",
    "chapter_id", "chapter_index", "choice", "choice_id", "event_id",
    "event", "passage", "passage_id", "current_route", "current_scene",
})

DDLC_VARIAVEIS_NOME_CONHECIDAS = frozenset({
    "n_name", "t_name", "c_name", "sk_name", "mom_name", "dad_name",
    "doctor_name", "teacher_name", "professor_name", "police_name",
    "pov_name", "player_name", "ch_name", "y_name", "s_name",
    "m_name", "name_sayori", "name_natsuki", "name_yuri", "name_monika",
})

# Nomes modernos/legados do banco do minigame de poemas.
POEM_WORDS_NOMES_NORMALIZADOS = frozenset({
    "editedpoemwords", "poemwords", "editedpoemword", "poemword",
    "editedpoemsword", "poemsword", "poemwordlist", "poemwordslist",
    "poemwordsren", "editedpoemwordsren", "poemwordspy",
})

BIBLIOTECA_RENPY = {
    "tokens_nao_dialogo": set([
        "voice", "fit", "image", "play", "queue", "stop", "scene", "show", "hide", "with",
        "window", "pause", "label", "jump", "call", "return", "python", "init", "translate",
        "style", "transform", "layeredimage", "screen", "camera", "physics", "font", "color",
        "hover_color", "selected_color", "insensitive_color", "idle_color", "add", "key", "keysym",
        "id", "style_prefix", "background", "foreground", "thumb", "base_bar", "top_bar",
        "bottom_bar", "unscrollable", "scrollbars", "layout", "outlines", "hover_outlines",
        "input", "caret", "size_group", "action", "value", "adjustment", "properties", "xpos",
        "bg", "music", "sound", "audio", "sfx", "ambience", "renpy",
        "ypos", "xalign", "yalign", "xanchor", "yanchor", "xsize", "ysize", "xoffset", "yoffset",
        "spacing", "padding", "margin", "at", "tooltip", "hover_sound", "activate_sound",
        "focus_mask", "range", "alt", "timer", "test", "old", "new",
        "shader", "text_style", "style_group", "mouse",
    ])
}

# --- Biblioteca DDAC: catalogo separado em DUAS bibliotecas independentes.
# 1) DDLC 1.1.1 PC  -> 35 arquivos .rpy da arvore "game" (no jogo original eles
#    vêm compilados dentro de scripts.rpa; não contar os .rpyc como arquivos extras).
# 2) DDLC Mod Template 2.0 (release verificável 2.1.0) -> 6 arquivos .rpy na raiz
#    de "game" + os arquivos de "game/advanced_scripts".
# Arquivos com o mesmo nome nas duas bibliotecas NÃO são fundidos: a origem é
# escolhida pelo caminho do arquivo dentro do mod.

# Conhecimento do ecossistema moderno do DDLC Mod Template.
# Não é uma whitelist fechada: serve como sinal contextual e documentação interna.
CATALOGO_TEMPLATE_MODERNO = {
    "_ren.py": u"Código Ren'Py/Python moderno; pode conter blocos Ren'Py e strings visíveis.",
    "poemwords_ren.py": u"Banco moderno de palavras do minigame de poemas.",
    "definitions.rpy": u"Definições e nomes exibidos de personagens.",
    "screens.rpy": u"Telas e strings de interface.",
    "poems.rpy": u"Poemas e corpos de poemas.",
    "poems_special.rpy": u"Poemas especiais e estruturas visuais.",
}

# diálogo: True  = PASSA  (tem texto traduzível de fábrica, sempre extraído)
#          False = BARRADO (arquivo técnico; só aparece se o mod colocar texto novo)
BIB_DDLC = u"DDLC 1.1.1"
BIB_TPL = u"Template 2.0 + Template 4.2.4 (legado) + Template 5.x (moderno)"

BIBLIOTECA_DDLC = {}
BIBLIOTECA_TPL = {}

# --- 1) DDLC 1.1.1 PC -- game/ (35 arquivos .rpy) ---
_CATALOGO_DDLC = (
    (u"script.rpy", u"Ponto de entrada, início do jogo e roteamento de capítulos", True),
    (u"splash.rpy", u"Tela de abertura, aviso de conteúdo e checagens iniciais", True),
    (u"script-ch0.rpy", u"Capítulo 0 da história", True),
    (u"script-ch1.rpy", u"Capítulo 1 da história", True),
    (u"script-ch2.rpy", u"Capítulo 2 da história", True),
    (u"script-ch3.rpy", u"Capítulo 3 da história", True),
    (u"script-ch4.rpy", u"Capítulo 4 da história", True),
    (u"script-ch5.rpy", u"Capítulo 5 da história (transição para o Ato 2)", True),
    (u"script-ch10.rpy", u"Ato 2 - início", True),
    (u"script-ch20.rpy", u"Ato 2 - continuação", True),
    (u"script-ch21.rpy", u"Ato 2 - continuação", True),
    (u"script-ch22.rpy", u"Ato 2 - continuação", True),
    (u"script-ch23.rpy", u"Ato 2 - continuação", True),
    (u"script-ch30.rpy", u"Ato 2 - trecho final", True),
    (u"script-ch40.rpy", u"Ato 3 - Monika / final", True),
    (u"script-exclusives-sayori.rpy", u"Cenas exclusivas da Sayori", True),
    (u"script-exclusives-natsuki.rpy", u"Cenas exclusivas da Natsuki", True),
    (u"script-exclusives-yuri.rpy", u"Cenas exclusivas da Yuri", True),
    (u"script-exclusives2-natsuki.rpy", u"Cenas exclusivas da Natsuki (parte 2)", True),
    (u"script-exclusives2-yuri.rpy", u"Cenas exclusivas da Yuri (parte 2)", True),
    (u"script-poemgame.rpy", u"Minigame de escrever poema (interface e falas)", True),
    (u"script-poemresponses.rpy", u"Reações das garotas aos poemas", True),
    (u"script-poemresponses2.rpy", u"Reações das garotas aos poemas (parte 2)", True),
    (u"poems.rpy", u"Poemas do jogo (título e corpo do poema)", True),
    (u"poems_special.rpy", u"Poemas especiais (Monika/Sayori)", True),
    (u"credits.rpy", u"Tela de créditos", True),
    (u"screens.rpy", u"Telas do jogo (menu, salvar, opções, caixa de texto)", True),
    (u"options.rpy", u"Configuração do jogo (título da janela, nome do mod, 'sobre')", True),
    (u"cgs.rpy", u"Controle de desbloqueio das CGs da galeria", False),
    (u"console.rpy", u"Console de desenvolvedor / depuração", False),
    (u"definitions.rpy", u"Definições de personagens, sprites e variáveis; no final do arquivo ficam os nomes exibidos das personagens (Sayori, Yuri, Natsuki, Mom, Dad, Doctor...)", True),
    (u"effects.rpy", u"Efeitos visuais (glitch, distorção)", False),
    (u"glitchtext.rpy", u"Gerador de texto corrompido (código)", False),
    (u"gui.rpy", u"Estilo visual da interface (cores, fontes, tamanhos)", False),
    (u"transforms.rpy", u"Animações e posicionamento de sprites", False),
)

# --- 2) DDLC Mod Template 2.0 (2.1.0) -- game/ e game/advanced_scripts/ ---
_CATALOGO_TPL = (
    (u"options.rpy", u"Configuração básica do template/mod", True),
    (u"screens.rpy", u"Telas e textos de interface", True),
    (u"script-example.rpy", u"Cena de exemplo para o modder", True),
    (u"script.rpy", u"Estrutura/roteamento básico do projeto", True),
    (u"splash.rpy", u"Avisos e tela inicial", True),
    (u"tutorials.rpy", u"Tutoriais/avisos do template", True),
    (u"advanced_scripts/credits.rpy", u"Tela de créditos", True),
    (u"advanced_scripts/poems.rpy", u"Poemas", True),
    (u"advanced_scripts/poems_special.rpy", u"Poemas especiais", True),
    (u"advanced_scripts/script-poemgame.rpy", u"Minigame de poemas", True),
    (u"advanced_scripts/cgs.rpy", u"Sistema de CGs", False),
    (u"advanced_scripts/console.rpy", u"Console/desenvolvimento", False),
    (u"advanced_scripts/definitions.rpy", u"Definições de personagens/recursos; inclui os nomes exibidos das personagens", True),
    (u"advanced_scripts/effects.rpy", u"Efeitos visuais", False),
    (u"advanced_scripts/glitchtext.rpy", u"Geração/manipulação de texto glitch", False),
    (u"advanced_scripts/gui.rpy", u"Configuração visual", False),
    (u"advanced_scripts/transforms.rpy", u"Transformações/posicionamento", False),
)

for _e in _CATALOGO_DDLC:
    BIBLIOTECA_DDLC[_e[0].lower()] = {
        "origem": BIB_DDLC, "funcao": _e[1], "dialogo": _e[2],
    }

for _e in _CATALOGO_TPL:
    _chave = _e[0].lower()
    BIBLIOTECA_TPL[_chave] = {
        "origem": BIB_TPL, "funcao": _e[1], "dialogo": _e[2],
    }
    BIBLIOTECA_TPL[_chave.split("/")[-1]] = BIBLIOTECA_TPL[_chave]


def consultar_biblioteca(caminho_relativo):
    caminho = caminho_relativo.replace("\\", "/").lower().lstrip("./")
    if caminho.startswith("game/"):
        caminho = caminho[len("game/"):]
    nome = caminho.split("/")[-1]

    # Arquivo dentro de advanced_scripts pertence sempre ao Template.
    if "advanced_scripts/" in caminho:
        info = BIBLIOTECA_TPL.get(caminho.split("advanced_scripts/")[-1])
        info = info or BIBLIOTECA_TPL.get("advanced_scripts/" + nome)
        if info:
            return info
        return None

    info = BIBLIOTECA_DDLC.get(nome)
    if info:
        return info
    info = BIBLIOTECA_TPL.get(nome)
    if info:
        return info
    if nome.startswith("script-ch") and nome.endswith(".rpy"):
        return {
            "origem": BIB_DDLC,
            "funcao": u"Capítulo da história",
            "dialogo": True,
        }
    return None


_TRADUCOES_BIB = {
    2: {
        "Ponto de entrada, início do jogo e roteamento de capítulos": "Entry point, game startup, and chapter routing",
        "Tela de abertura, aviso de conteúdo e checagens iniciais": "Opening screen, content warning, and initial checks",
        "Capítulo 0 da história": "Chapter 0 of the story", "Capítulo 1 da história": "Chapter 1 of the story",
        "Capítulo 2 da história": "Chapter 2 of the story", "Capítulo 3 da história": "Chapter 3 of the story",
        "Capítulo 4 da história": "Chapter 4 of the story", "Capítulo 5 da história (transição para o Ato 2)": "Chapter 5 of the story (transition to Act 2)",
        "Ato 2 - início": "Act 2 - beginning", "Ato 2 - continuação": "Act 2 - continuation",
        "Reações das garotas aos poemas": "Girls' reactions to poems",
        "Poemas do jogo (título e corpo do poema)": "Game poems (title and poem body)",
        "Tela de créditos": "Credits screen",
        "Telas do jogo (menu, salvar, opções, caixa de texto)": "Game screens (menu, save, options, text box)",
        "Configuração do jogo (título da janela, nome do mod, 'sobre')": "Game configuration (window title, mod name, 'about')",
        "Console de desenvolvedor / depuração": "Developer console / debugging",
        "Definições de personagens, sprites e variáveis; no final do arquivo ficam os nomes exibidos das personagens (Sayori, Yuri, Natsuki, Mom, Dad, Doctor...)": "Character, sprite, and variable definitions; displayed character names are at the end (Sayori, Yuri, Natsuki, Mom, Dad, Doctor...)",
        "Efeitos visuais (glitch, distorção)": "Visual effects (glitch, distortion)",
        "Gerador de texto corrompido (código)": "Corrupted-text generator (code)",
        "Animações e posicionamento de sprites": "Sprite animation and positioning",
        "Configuração básica do template/mod": "Basic template/mod configuration",
        "Estrutura/roteamento básico do projeto": "Project structure/routing",
        "Definições de personagens/recursos; inclui os nomes exibidos das personagens": "Character/resource definitions; includes displayed character names",
        "Geração/manipulação de texto glitch": "Glitch-text generation/manipulation",
        "Configuração visual": "Visual configuration",
        "Transformações/posicionamento": "Transforms/positioning",
        "Capítulo da história": "Chapter of the story",
    },
    3: {
        "Ponto de entrada, início do jogo e roteamento de capítulos": "Punto de entrada, início del juego y enrutamiento de capítulos",
        "Tela de abertura, aviso de conteúdo e checagens iniciais": "Pantalla de início, aviso de contenido y comprobaciones iniciales",
        "Capítulo 0 da história": "Capítulo 0 de la historia", "Capítulo 1 da história": "Capítulo 1 de la historia",
        "Capítulo 2 da história": "Capítulo 2 de la historia", "Capítulo 3 da história": "Capítulo 3 de la historia",
        "Capítulo 4 da história": "Capítulo 4 de la historia", "Capítulo 5 da história (transição para o Ato 2)": "Capítulo 5 de la historia (transición al Acto 2)",
        "Ato 2 - início": "Acto 2 - início", "Ato 2 - continuação": "Acto 2 - continuación",
        "Reações das garotas aos poemas": "Reacciones de las chicas a los poemas",
        "Poemas do jogo (título e corpo do poema)": "Poemas del juego (título y cuerpo del poema)",
        "Tela de créditos": "Pantalla de créditos",
        "Telas do jogo (menu, salvar, opções, caixa de texto)": "Pantallas del juego (menú, guardar, opciones, cuadro de texto)",
        "Configuração do jogo (título da janela, nome do mod, 'sobre')": "Configuración del juego (título de la ventana, nombre del mod, 'acerca de')",
        "Console de desenvolvedor / depuração": "Consola de desarrollador / depuración",
        "Definições de personagens, sprites e variáveis; no final do arquivo ficam os nomes exibidos das personagens (Sayori, Yuri, Natsuki, Mom, Dad, Doctor...)": "Definiciones de personajes, sprites y variables; al final están los nombres mostrados de los personajes (Sayori, Yuri, Natsuki, Mom, Dad, Doctor...)",
        "Efeitos visuais (glitch, distorção)": "Efectos visuales (glitch, distorsión)",
        "Gerador de texto corrompido (código)": "Generador de texto corrupto (código)",
        "Animações e posicionamento de sprites": "Animaciones y posicionamiento de sprites",
        "Configuração básica do template/mod": "Configuración básica del template/mod",
        "Estrutura/roteamento básico do projeto": "Estructura/enrutamiento básico del proyecto",
        "Definições de personagens/recursos; inclui os nomes exibidos das personagens": "Definiciones de personajes/recursos; incluye los nombres mostrados de los personajes",
        "Geração/manipulação de texto glitch": "Generación/manipulación de texto glitch",
        "Configuração visual": "Configuración visual",
        "Transformações/posicionamento": "Transformaciones/posicionamiento",
        "Capítulo da história": "Capítulo de la historia",
    },
}

def descricao_biblioteca(info):
    funcao = _TRADUCOES_BIB.get(IDIOMA, {}).get(info["funcao"], info["funcao"])
    return u"{0} / {1}".format(info["origem"], funcao)


CHAR_DEF_LINE_RE = re.compile(r'^\s*(?:define|default)\s+([\w.]+)\s*=\s*(?:(?:renpy\.)?)(Character|DynamicCharacter)\s*\(')
DOLLAR_ASSIGN_RE = re.compile(r'^\$\s*([\w.]+)\s*=\s*(' + QSTR + r')\s*$')
IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_.]*$')

# Definições de personagem: cobre formas de uma linha e multilinha.
CHAR_DEF_START_RE = re.compile(
    r'\b(?:define|default)\s+([A-Za-z_][\w.]*)\s*=\s*(?:(?:renpy\.)?)(Character|DynamicCharacter)\s*\('
)

def _find_matching_paren(text, open_pos):
    """Encontra o ')' correspondente, ignorando parênteses dentro de strings/comentários."""
    depth = 0
    quote = None
    esc = False
    i = open_pos
    while i < len(text):
        ch = text[i]
        if quote is not None:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == quote:
                quote = None
            i += 1
            continue
        if ch in ('"', "'"):
            quote = ch
            i += 1
            continue
        if ch == '#':
            # Comentário até a quebra de linha.
            nl = text.find('\n', i)
            i = len(text) if nl < 0 else nl + 1
            continue
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _line_col_from_offset(text, offset):
    linha = text.count('\n', 0, offset) + 1
    inicio_linha = text.rfind('\n', 0, offset)
    if inicio_linha < 0:
        inicio_linha = 0
    else:
        inicio_linha += 1
    return linha, offset - inicio_linha


def analisar_construtores_achievements(caminho, conteudo):
    """Extrai textos visíveis de Achievement/AchievementCount.

    Os construtores normalmente ficam em blocos Python e podem ocupar várias
    linhas. Recuperamos somente os campos semanticamente visíveis: nome,
    descrição e locked_desc. A forma posicional usa os dois primeiros
    argumentos string; campos nomeados são acrescentados quando existirem.
    """
    entradas = []
    for m in re.finditer(r'\bAchievement(?:Count)?\s*\(', conteudo, re.I):
        open_pos = conteudo.find('(', m.start())
        close_pos = _find_matching_paren(conteudo, open_pos)
        if open_pos < 0 or close_pos < 0:
            continue
        chamada = conteudo[open_pos + 1:close_pos]

        encontrados = []
        # Forma posicional: nome e descrição são os dois primeiros literais.
        pos_strings = list(re.finditer(QSTR, chamada))
        if pos_strings:
            encontrados.append((pos_strings[0].start(), pos_strings[0].group(0), 'name'))
        if len(pos_strings) >= 2:
            encontrados.append((pos_strings[1].start(), pos_strings[1].group(0), 'description'))

        # Forma nomeada: acrescenta/substitui campos semanticamente explícitos.
        for campo in ('name', 'description', 'locked_desc'):
            for mn in re.finditer(r'\b' + re.escape(campo) + r'\s*=\s*(' + QSTR + r')', chamada, re.I):
                encontrados.append((mn.start(1), mn.group(1), campo))

        vistos_span = set()
        for pos, q, campo in sorted(encontrados, key=lambda x: x[0]):
            chave = (pos, q)
            if chave in vistos_span:
                continue
            vistos_span.add(chave)
            interior = strip_quotes(q).strip()
            if not interior or interior == '???' or not tem_conteudo_traduzivel(q):
                continue
            absoluto = open_pos + 1 + pos
            linha, coluna = _line_col_from_offset(conteudo, absoluto)
            entradas.append({
                'linha': linha,
                'coluna_inicio': coluna,
                'coluna_fim': coluna + len(q),
                'original': q,
                'tipo': 'ui',
                'confianca': 100,
                'contexto': 'texto visível de Achievement: ' + campo,
            })
    return entradas


def analisar_definicoes_personagens(caminho, conteudo):
    """Retorna entradas de nome/dynamic-name em Character/DynamicCharacter, inclusive multilinha."""
    entradas = []
    dynamic_vars = set()
    for m in CHAR_DEF_START_RE.finditer(conteudo):
        var_name = m.group(1)
        kind = m.group(2)
        open_pos = conteudo.find('(', m.start())
        if open_pos < 0:
            continue
        close_pos = _find_matching_paren(conteudo, open_pos)
        if close_pos < 0:
            # Não descartar a definição: ainda tentaremos a linha atual.
            close_pos = min(len(conteudo), m.end() + 4000)
        chamada = conteudo[open_pos + 1:close_pos]

        # name="..." / name='...'
        m_name = re.search(r'\bname\s*=\s*(' + QSTR + r')', chamada)
        if m_name:
            q = m_name.group(1)
            absoluto = open_pos + 1 + m_name.start(1)
            interior = strip_quotes(q)
            dynamic = bool(kind == 'DynamicCharacter' or re.search(r'\bdynamic\s*=\s*True\b', chamada, re.I))
            if dynamic and IDENT.match(interior):
                dynamic_vars.add(interior)
            elif not parece_texto_tecnico(q):
                linha, coluna = _line_col_from_offset(conteudo, absoluto)
                entradas.append({
                    'linha': linha, 'coluna_inicio': coluna, 'coluna_fim': coluna + len(q),
                    'original': q, 'tipo': 'nome_personagem', 'confianca': 100,
                    'contexto': 'definição de personagem: ' + var_name,
                })
        else:
            # Primeiro argumento posicional.
            m_first = re.match(r'\s*(' + QSTR + r')', chamada)
            if m_first:
                q = m_first.group(1)
                absoluto = open_pos + 1 + m_first.start(1)
                interior = strip_quotes(q)
                dynamic = bool(kind == 'DynamicCharacter' or re.search(r'\bdynamic\s*=\s*True\b', chamada, re.I))
                if dynamic and IDENT.match(interior):
                    dynamic_vars.add(interior)
                elif not parece_texto_tecnico(q):
                    linha, coluna = _line_col_from_offset(conteudo, absoluto)
                    entradas.append({
                        'linha': linha, 'coluna_inicio': coluna, 'coluna_fim': coluna + len(q),
                        'original': q, 'tipo': 'nome_personagem', 'confianca': 100,
                        'contexto': 'definição de personagem: ' + var_name,
                    })
    return entradas, dynamic_vars



def analisar_definicoes_phone(caminho, conteudo):
    """Extrai nomes visíveis dos objetos phone.character.Character em 01definitions.rpy.

    Esta regra é exclusiva do arquivo phone/definitions/01definitions.rpy e não
    deduplica nada por texto: cada ocorrência possui sua própria posição no mapa.
    Assim, se outro arquivo também possuir a mesma definição/nome, os dois
    arquivos continuam tendo suas próprias entradas na extração.
    """
    caminho_norm = caminho.replace("\\", "/").lower()
    if not caminho_norm.endswith("phone/definitions/01definitions.rpy"):
        return []

    entradas = []

    # "Welcome" e o nome do grupo padrao exibido pela interface do telefone.
    # Nao e uma fala; recebe uma categoria propria e mantem sua posicao real.
    for m_group in re.finditer(r'\bdefine\s+(' + QSTR + r')\s*:', conteudo, re.I):
        q_group = m_group.group(1)
        if strip_quotes(q_group) != 'Welcome':
            continue
        absoluto = m_group.start(1)
        linha, coluna = _line_col_from_offset(conteudo, absoluto)
        entradas.append({
            'linha': linha,
            'coluna_inicio': coluna,
            'coluna_fim': coluna + len(q_group),
            'original': q_group,
            'tipo': 'nome_grupo',
            'confianca': 100,
            'contexto': 'nome do grupo de telefone',
        })

    for m in re.finditer(r'\bphone\.character\.Character\s*\(', conteudo, re.I):
        open_pos = conteudo.find('(', m.start())
        if open_pos < 0:
            continue
        close_pos = _find_matching_paren(conteudo, open_pos)
        if close_pos < 0:
            close_pos = min(len(conteudo), open_pos + 4000)
        chamada = conteudo[open_pos + 1:close_pos]

        # Prioridade para name="..." quando a chamada usa argumento nomeado.
        m_name = re.search(r'\bname\s*=\s*(' + QSTR + r')', chamada)
        if m_name:
            q = m_name.group(1)
            absoluto = open_pos + 1 + m_name.start(1)
        else:
            # Forma normal do sistema do telefone: Character("Nome", ...)
            m_first = re.match(r'\s*(' + QSTR + r')', chamada)
            if not m_first:
                continue
            q = m_first.group(1)
            absoluto = open_pos + 1 + m_first.start(1)

        if parece_texto_tecnico(q):
            continue
        linha, coluna = _line_col_from_offset(conteudo, absoluto)
        entradas.append({
            'linha': linha,
            'coluna_inicio': coluna,
            'coluna_fim': coluna + len(q),
            'original': q,
            'tipo': 'nome_personagem',
            'confianca': 100,
            'contexto': 'nome de personagem do telefone',
        })
    return entradas

def coletar_variaveis_nome_dinamico(candidatos):
    variaveis = set()
    for caminho in candidatos:
        try:
            with io.open(caminho, 'r', encoding='utf-8', errors='replace', newline='') as f:
                conteudo = f.read()
        except Exception:
            continue
        _, descobertas = analisar_definicoes_personagens(caminho, conteudo)
        variaveis.update(descobertas)
        # Mantem compatibilidade com a deteccao simples existente.
        for m in re.finditer(r'DynamicCharacter\s*\(\s*(?:name\s*=\s*)?(' + QSTR + r')', conteudo):
            valor = strip_quotes(m.group(1))
            if IDENT.match(valor):
                variaveis.add(valor)
    return variaveis
STRING_DEFAULT_RE = re.compile(r'^\s*(?:define|default)\s+([\w.]+)\s*=\s*(' + QSTR + r')\s*$')
# Definição do nome do jogo: nunca deve entrar na tradução. Mantemos o restante
# de options.rpy normalmente processável; somente a linha `define config.name = ...`
# é ignorada.
CONFIG_NAME_DEFINE_RE = re.compile(r'^\s*define\s+config\.name\s*=')
PURE_VISIBLE_URL_RE = re.compile(r'^(?:https?|ftp)://\S+$', re.I)
def strip_quotes(s):
    s = s.strip()
    # Ren\'Py também aceita o prefixo r em strings diretas e usa backtick
    # como delimitador alternativo. Mantemos o prefixo fora do conteúdo.
    if len(s) >= 3 and s[0] in 'rR' and s[1] in ('"', "'", '`') and s[-1] == s[1]:
        s = s[1:]
    if len(s) >= 2 and ((s[0] == '"' and s[-1] == '"') or (s[0] == "'" and s[-1] == "'") or (s[0] == '`' and s[-1] == '`')):
        return s[1:-1]
    return s

def iter_renpy_literais_especiais(linha):
    """Itera strings de uma linha que o QSTR legado não cobre: r\"...\" e `...`.

    Retorna (inicio_literal, fim_literal, literal, eh_raw). O prefixo `r` fica
    deliberadamente fora do span para que a reinjeção preserve a sintaxe original.
    Strings triplas são tratadas pelos extratores multilinha/monólogo.
    """
    n = len(linha)
    i = 0
    while i < n:
        inicio = i
        raw = False
        if linha[i] in 'rR' and i + 1 < n and linha[i + 1] in ('"', "'", '`') and (i == 0 or not (linha[i - 1].isalnum() or linha[i - 1] == '_')):
            raw = True
            i += 1
        if i >= n or linha[i] not in ('"', "'", '`'):
            i = inicio + 1
            continue
        quote = linha[i]
        # O scanner especial só deve recuperar as formas que o QSTR legado não
        # cobre: backtick e prefixo r. Strings normais ficam sob o parser principal
        # para não reabrir falsos positivos em caminhos/atribuições técnicas.
        if not raw and quote != '`':
            i = inicio + 1
            continue
        # Triple quote: deixar os extratores dedicados tratarem isso.
        if linha.startswith(quote * 3, i):
            i += 3
            continue
        qpos = i
        j = i + 1
        while j < n:
            if linha[j] == '\\':
                j += 2
                continue
            if linha[j] == quote:
                yield (qpos, j + 1, linha[qpos:j + 1], raw)
                i = j + 1
                break
            j += 1
        else:
            i = inicio + 1
def parecer_sem_tecnico(v):
    x = strip_quotes(v)
    return bool(x) and not re.match(r'^#[0-9a-fA-F]{3,8}$', x) and not re.match(r'^(?:https?|ftp)://', x, re.I)
def parece_texto_tecnico(valor_com_aspas, var_nome="", indice_arquivos=None):
    interior = strip_quotes(valor_com_aspas).strip()
    if not interior:
        return True

    # Exceções: algumas variáveis são feitas para aparecer diretamente na UI.
    # config.version é metadado do projeto, não texto de gameplay.
    if var_nome in ("config.name", "gui.about"):
        return False
    if var_nome == "config.version":
        return True

    # Nomes de variáveis que representam recursos, build ou configuração técnica.
    if (re.match(r'^build\.', var_nome, re.I) or
            re.match(r'^(?:config|preferences|persistent|gui)\.', var_nome, re.I) or
            re.match(r'^(?:audio|music|sound|sfx|ambience|image)\.', var_nome, re.I)):
        return True

    if re.match(r'^#[0-9a-fA-F]{3,8}$', interior):
        return True
    # URL pura pode ser tratada como tecnica quando o contexto nao a marcou como visivel.
    # URL dentro de uma frase continua sendo texto legivel e sera preservada por tokens no Google.
    if PURE_VISIBLE_URL_RE.match(interior):
        return True
    # Comandos de shell e strings feitas só de pontuação de código (ex.: um apóstrofo).
    if re.match(r'^(?:powershell(?:\.exe)?|pwsh|wmic|cmd(?:\.exe)?\s+/[a-z])\b', interior, re.I):
        return True
    if re.match(r'^[\s\'"`\\/|,;:=+()\[\]{}<>@$%^&_]+$', interior):
        return True
    if re.match(r'^[A-Za-z0-9+/]{16,}={0,2}$', interior) and re.search(r'\d', interior):
        return True

    # Mensagens de status legíveis continuam sendo texto de tela, mesmo quando
    # mencionam um módulo/binário. Elas são seguras como texto porque o módulo
    # é apenas parte do conteúdo exibido; os tokens de arquivo são protegidos
    # antes do Google Translate.
    if re.match(r'^(?:In[ií]cio|Start):\s*[A-Za-z0-9_.-]+(?:\s*->\s*[A-Za-z0-9_.-]+)?$', interior, re.I):
        return False
    if re.match(r'^[A-Za-z0-9_.-]+:\s*(?:SUCCESS|OK|DONE|CONCLU[IÍ]DO)\.?$', interior, re.I):
        return False

    # Diagnóstico/saída de baixo nível que pode até aparecer em uma tela de
    # erro, mas não é conteúdo de tradução: kernel logs, endereços, drivers,
    # arquivos .so/.dll e mensagens de IRQ/PCI/DMA/ATA. Mantemos mensagens
    # humanas fora desses padrões (ex.: créditos, GitHub Template, status).
    if (re.match(r'^\s*(?:\*\*\*|[-–]\s*Address\b|(?:hda|hdc|ide|fd|eno|eth)\d*\b|(?:acpi|pci|irq|gsi|dma)\b|/init:)', interior, re.I)
            or re.match(r'^[A-Za-z0-9_.-]+\.(?:c|h|cpp|hpp):', interior, re.I)
            or (re.search(r'\.(?:so|dll|exe|bin)\b', interior, re.I) and
                re.search(r'(?:ImportError|Loaded|SUCCESS|disable|nvdrs|DDLC\.so)', interior, re.I))
            or re.search(r'\b(?:Datestamp|CHS=|sectors\s*\(|ATAPI|CD-ROM|ATA (?:DISK|FLOPPY)|VIRTUAL (?:HARD|CD|FLOPPY)|driver Revision)\b', interior, re.I)
            or re.search(r'0x(?:[0-9A-Fa-f]{4,}|force\s*=\s*panic)\b', interior, re.I)):
        return True

    # Cores nomeadas e comandos visuais codificados como strings.
    if re.match(r'^(?:white|black|red|green|blue|yellow|cyan|magenta|gray|grey|transparent)$', interior, re.I):
        return True
    if re.match(r'^(?:bg|scene|show|hide|with|play|queue|stop|voice|image|transform|camera|add|at|on|contains)\b', interior):
        return True
    if re.match(r'^[A-Za-z_][A-Za-z0-9_.]*(?:_(?:header|body|title_text|empty_text|text_key|id|key))$', interior, re.I):
        return True
    if var_nome and VAR_RECURSO_RE.match(var_nome.split('.')[-1]):
        return True

    # Tags de audio/ATL + caminho de recurso.
    if RECURSO_COM_TAG.match(interior) or RECURSO_COM_TAG_SEM_PASTA.match(interior):
        return True
    if RECURSO_CAMINHO.match(interior):
        return True
    if re.match(r'^[^\\/\s]+\.(?:ttf|otf|ttc|png|jpg|jpeg|gif|webp|webm|ogg|mp3|wav|flac|m4a|ico|rpy|rpyc|rpa)$', interior, re.I):
        return True

    # Se o texto coincide exatamente com um arquivo real do mod, é recurso.
    if indice_arquivos is not None:
        try:
            n = normalizar_referencia_arquivo(interior)
            if n and n in indice_arquivos:
                return True
        except Exception:
            pass

    # Cobertura final para referencias de recursos, inclusive nomes com espacos.
    if re.match(r'^(?:[A-Za-z0-9_.()\- ]+[\\/])+[^\\/]+\.(?:ttf|otf|png|jpg|jpeg|gif|webp|webm|ogg|mp3|wav|flac|m4a|rpy|rpyc|rpa|txt|ico|json|chr|py|pyc|dll|so|apk)$', interior, re.I):
        return True

    return False
# --- Camada contextual recuperada das versões de maior cobertura ---
ARQUIVOS_TEXTO_SEMANTICO = (
    "credits", "credit", "end_credits", "splash", "exception", "exceptions",
    "renpy_patches", "lockdown_check", "template_checks", "depreciated",
    "deprecation", "depreciation", "warning", "notice", "poem_response",
    "poem_responses", "phone",
)
STRING_LITERAL_RE = re.compile(QSTR)
IDENTIFICADOR_PURO_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_.-]*$')
IDENTIFICADOR_COMPOSTO_RE = re.compile(
    r'^[A-Za-z_][A-Za-z0-9_.-]*(?:_(?:header|body|text|title|title_text|empty|empty_text|name|id|key|label))$',
    re.I
)
VAR_RECURSO_RE = re.compile(
    r'^(?:bg|background|scene|image|img|sprite|sprites|cg|cgs|layer|layers|mask|icon|thumbnail|thumb|avatar|face|expression|pose|transform|font|music|song|track|audio|sound|sfx|voice|ambience|movie|video|gui)$',
    re.I
)
BLOCO_TECNICO_RE = re.compile(
    r"^(?:image(?:\s+['\"]?[^:]*?)?|transform(?:\s+[^:]+)?|layeredimage(?:\s+[^:]+)?|style(?:\s+[^:]+)?)\s*:",
    re.I
)

def construir_linhas_blocos_tecnicos(linhas_raw):
    # Marca apenas sublinhas de blocos visuais declarativos. Screen/menu/python
    # continuam analisados porque podem conter texto realmente visível.
    marcadas = set()
    pilha = []
    for idx, raw in enumerate(linhas_raw, 1):
        linha = raw.rstrip('\r\n')
        limpa = linha.strip()
        if not limpa or limpa.startswith('#'):
            continue
        indent = len(linha) - len(linha.lstrip())
        while pilha and indent <= pilha[-1]:
            pilha.pop()
        if pilha:
            marcadas.add(idx)
        if BLOCO_TECNICO_RE.match(limpa):
            pilha.append(indent)
    return marcadas

PYTHON_INICIO_RE = re.compile(r'^(?:init(?:\s+-?\d+)?\s+)?python\b[^:#"\']*:\s*(?:#.*)?$')
ELEMENTOS_CONTAINER = frozenset([
    "side", "vpgrid", "grid", "frame", "window", "fixed", "vbox", "hbox", "viewport",
    "imagemap", "hotspot", "mousearea", "button", "bar", "vbar", "drag", "draggroup",
    "area", "null",
])

def construir_linhas_python(linhas_raw):
    # Marca as linhas que estão DENTRO de blocos python (init python:, python:,
    # python early:, python in x:...), inclusive docstrings de várias linhas.
    # Também reconhece corpos de def/class como fallback. Isso evita que uma
    # docstring seja confundida com diálogo caso o bloco python esteja escrito
    # de uma forma que a regex principal não consiga identificar.
    marcadas = set()
    py_indent = None
    def_indentes = []
    em_triplo = None
    for idx, raw in enumerate(linhas_raw, 1):
        linha = raw.rstrip('\r\n')
        limpa = linha.strip()
        indent = len(linha) - len(linha.lstrip())

        if em_triplo is not None:
            marcadas.add(idx)
            if linha.count(em_triplo) % 2 == 1:
                em_triplo = None
            continue

        if not limpa or limpa.startswith('#'):
            continue

        while def_indentes and indent <= def_indentes[-1]:
            def_indentes.pop()

        if py_indent is not None and indent <= py_indent:
            py_indent = None

        dentro_python = py_indent is not None or bool(def_indentes)

        if PYTHON_INICIO_RE.match(limpa):
            py_indent = indent
            dentro_python = True
            continue

        if re.match(r'^(?:async\s+)?(?:def|class)\b.*:\s*(?:#.*)?$', limpa):
            def_indentes.append(indent)
            continue

        if not dentro_python:
            continue

        marcadas.add(idx)

        for aspas in (chr(34) * 3, chr(39) * 3):
            if linha.count(aspas) % 2 == 1:
                em_triplo = aspas
                break

    return marcadas
def parece_frase(valor_com_aspas):
    interior = strip_quotes(valor_com_aspas).strip()
    if len(interior.split()) >= 3:
        return True
    return bool(re.search(r'[.!?\u2026:;,]$', interior))

def parece_codigo_na_linha(linha_limpa, inicio, fim):
    # Bloqueia falsos positivos típicos do fallback LEGACY_DIALOGO:
    # chaves de dicionário, strings passadas a __init__/funções e fragmentos
    # de docstrings que parecem diálogo por terem texto antes da string.
    trecho = linha_limpa[inicio:fim]
    interior = strip_quotes(trecho).strip()
    prefixo = linha_limpa[:inicio].strip()
    sufixo = linha_limpa[fim:].strip()

    if re.search(r'\b(?:__init__|def|class|return|import|from|lambda|self|super)\b', prefixo, re.I):
        return True

    if re.match(r'^[' + chr(34) + chr(39) + r'][A-Za-z_][A-Za-z0-9_.-]*[' + chr(34) + chr(39) + r']\s*:', trecho + sufixo):
        return True

    if re.match(r'^[A-Za-z_][A-Za-z0-9_-]*(?:\.[A-Za-z0-9_-]+)*$', interior):
        palavras = re.findall(r'[A-Za-z_][A-Za-z0-9_.-]*', prefixo)
        if len(palavras) >= 3:
            return True

    # Bloqueia o formato de layout usado em código, como `side "t b":` ou
    # `side "t c":`, sem bloquear falas normais.
    if re.match(r'^[A-Za-z]+(?:\s+[A-Za-z]+){1,3}$', interior) and sufixo.startswith(':'):
        return True

    return False

def arquivo_tem_contexto_textual(caminho):
    nome = os.path.basename(caminho).lower()
    stem = os.path.splitext(nome)[0]
    return any(tok in stem for tok in ARQUIVOS_TEXTO_SEMANTICO)

def parece_string_semantica(valor_com_aspas, caminho, var_nome="", permitir_identificador=False):
    interior = strip_quotes(valor_com_aspas).strip()
    if not interior:
        return False
    if parece_texto_tecnico(valor_com_aspas, var_nome=var_nome):
        return False
    if IDENTIFICADOR_COMPOSTO_RE.match(interior):
        return False
    if IDENTIFICADOR_PURO_RE.match(interior) and " " not in interior:
        return bool(permitir_identificador)
    return True

TEXTUAL_ASSIGN_RE = re.compile(
    r'^\s*(?:\$\s*)?((?:message|messages|text|caption|prompt|title|description|warning|error|exception|notice|header|body|show)[A-Za-z0-9_.]*|[A-Za-z_][A-Za-z0-9_.]*(?:\.|_)(?:message|messages|text|caption|prompt|title|description|warning|error|exception|notice|header|body|show)[A-Za-z0-9_.]*)\s*=\s*(' + QSTR + r')\s*$',
    re.I
)
DYNAMIC_VISIBLE_TEXT_ASSIGN_RE = re.compile(
    r'^\s*\$\s*(menutext)\s*=\s*(' + QSTR + r')\s*$',
    re.I
)
PROPRIEDADES_NAO_TEXTO = frozenset([
    "id", "style", "style_prefix", "variant", "idle", "hover", "insensitive",
    "selected_idle", "selected_hover", "selected_insensitive", "layout",
    "size_group", "ground",
])
ELEMENTOS_DE_TELA = frozenset([
    "text", "textbutton", "label", "viewport", "vpgrid", "frame", "window",
    "vbox", "hbox", "fixed", "imagebutton", "button", "bar", "vbar", "input",
    "key", "timer", "use", "hotspot", "imagemap", "side", "grid", "null",
    "drag", "draggroup", "mousearea", "area",
])
EXTENSOES_IMAGEM_VOCABULARIO = (".png", ".jpg", ".jpeg", ".webp", ".gif", ".webm", ".avif")

def tem_conteudo_traduzivel(valor_com_aspas):
    interior = strip_quotes(valor_com_aspas)
    restante = re.sub(r'\[[^\]]*\]|\{[^}]*\}|\\.', u"", interior)
    if re.search(r'[^\W\d_]', restante):
        return True
    return bool(re.match(r'^[\s.?!\u2026*~\-\u2014\u2013]+$', restante))


TEXT_CALL_START_RE = re.compile(r'\b(?:Text|ParameterizedText)\s*\(', re.I)


def extrair_fragmentos_text_call_dinamico(linha, caminho):
    """Extrai literais visíveis do primeiro argumento dinâmico de Text()."""
    saida = []
    for m_call in TEXT_CALL_START_RE.finditer(linha):
        abre = linha.find(u'(', m_call.start())
        if abre < 0:
            continue
        fecha = _find_matching_paren(linha, abre)
        if fecha < 0:
            continue
        arg0 = linha[abre + 1:fecha]

        depth = 0
        quote = None
        esc = False
        fim_arg = len(arg0)
        for i, ch in enumerate(arg0):
            if quote is not None:
                if esc:
                    esc = False
                elif ch == u'\\':
                    esc = True
                elif ch == quote:
                    quote = None
                continue
            if ch in (u'\"', u"'"):
                quote = ch
            elif ch in (u'(', u'[', u'{'):
                depth += 1
            elif ch in (u')', u']', u'}'):
                depth = max(0, depth - 1)
            elif ch == u',' and depth == 0:
                fim_arg = i
                break

        expr = arg0[:fim_arg]
        if u'+' not in expr:
            continue

        base = abre + 1
        for sm in re.finditer(QSTR, expr):
            q = sm.group(0)
            if not tem_conteudo_traduzivel(q):
                continue
            if not parece_string_semantica(q, caminho):
                continue
            saida.append((base + sm.start(), base + sm.end(), q))
    return saida

def variavel_eh_tecnica(var_nome, valor_com_aspas, vocabulario):
    if not vocabulario or var_nome in ("config.name", "gui.about"):
        return False

    # Nomes de personagens definidos explicitamente pelo ecossistema DDLC.
    # Isso inclui N_name, t_name, c_name, sk_name, mom_name e variantes *_name
    # catalogadas em definitions.rpy / construtores de Character.
    nomes_personagem = vocabulario.get("nomes_personagem_variaveis", set())
    base = var_nome.rsplit(".", 1)[-1].lower()
    if base in DDLC_VARIAVEIS_NOME_CONHECIDAS or var_nome in nomes_personagem:
        return False
    if base.endswith("_name") and var_nome in vocabulario.get("nomes_personagem_variaveis", set()):
        return False

    if var_nome in vocabulario["variaveis_tecnicas"]:
        return True

    # Variáveis de estilo são identificadores Ren'Py, não texto de interface.
    # Evita enviar valores como `button_text` / `text_style` para o tradutor.
    base = var_nome.rsplit(".", 1)[-1].lower()
    if base in ("style", "style_prefix") or base.endswith("_style") or base.endswith("_style_prefix"):
        return True

    # Variáveis terminadas em _key/_id costumam guardar chaves internas.
    # Só bloqueamos quando o valor também é um identificador puro; isso não
    # afeta nomes exibidos legítimos como `ch4_name = "Yuri"`.
    valor = strip_quotes(valor_com_aspas).strip()
    if (base in ("key", "id") or base.endswith("_key") or base.endswith("_id")) and IDENT.match(valor):
        return True

    # Estados/rotas internos: barrar quando o valor tem forma de identificador
    # ou flag. Se o valor for uma frase natural, mantemos a possibilidade de
    # ser texto visível e deixamos o oráculo semântico/heurísticas decidirem.
    if base in RENpy_ESTADOS_TECNICOS:
        if (IDENT.match(valor) or re.fullmatch(r"[-+]?\d+(?:\.\d+)?", valor) or
                valor.lower() in ("true", "false", "none", "null")):
            return True

    # Metadados/build nunca são destino do Google.
    if re.match(r"^(?:build(?:\.|$)|__build|__version|version_info)", base, re.I):
        return True

    return valor in vocabulario["nomes_do_jogo"]

def coletar_vocabulario(pasta_game, candidatos):
    variaveis_tecnicas = set()
    nomes_do_jogo = set()
    personagens = set()
    nomes_personagem_variaveis = set()
    padrao_personagem = re.compile(r'^(?:define|default)\s+([A-Za-z_]\w*)\s*=\s*(?:renpy\.)?(?:Dynamic)?Character\s*\(')
    padroes_nome = (
        re.compile(r'^(?:image|layeredimage)\s+([A-Za-z_][\w. ]*?)\s*(?:=|:)'),
        re.compile(r'^(?:label|screen)\s+([A-Za-z_][\w.]*)'),
    )
    padroes_variavel = (
        re.compile(r'\b([A-Za-z_][\w.]*)\s*(?:==|!=)\s*["\'][^"\']'),
        re.compile(r'["\'][^"\']+["\']\s*(?:==|!=)\s*([A-Za-z_][\w.]*)'),
        re.compile(r'\b(?:SetVariable|SetScreenVariable|ToggleVariable|ToggleScreenVariable)\(\s*["\']([\w.]+)["\']'),
    )
    for caminho in candidatos:
        if caminho.lower().endswith(".txt"):
            continue
        try:
            with io.open(caminho, 'r', encoding='utf-8', errors='replace', newline='') as f:
                linhas = f.read().splitlines()
        except Exception:
            continue
        eh_arquivo_definicoes = os.path.basename(caminho).lower() in ("definitions.rpy", "01definitions.rpy")
        for linha in linhas:
            limpa = linha.strip()
            if eh_arquivo_definicoes:
                m_nome_def = re.match(r'^(?:define\s+|default\s+)?([A-Za-z_][A-Za-z0-9_]*_name)\s*=\s*(?:u)?["\'][^"\']+["\']', limpa)
                if m_nome_def:
                    nomes_personagem_variaveis.add(m_nome_def.group(1))
            m_pers = padrao_personagem.match(limpa)
            if m_pers:
                personagens.add(m_pers.group(1))
            for padrao in padroes_nome:
                m = padrao.match(limpa)
                if m:
                    nome = m.group(1).strip()
                    nomes_do_jogo.add(nome)
                    nomes_do_jogo.update(nome.split())
            for padrao in padroes_variavel:
                variaveis_tecnicas.update(padrao.findall(limpa))
    ignoradas = set(p.lower() for p in PASTAS_IGNORADAS)
    for pasta_atual, subpastas, arquivos in os.walk(pasta_game):
        subpastas[:] = [p for p in subpastas if p.lower() not in ignoradas]
        for nome in arquivos:
            base, extensao = os.path.splitext(nome)
            if extensao.lower() in EXTENSOES_IMAGEM_VOCABULARIO:
                nomes_do_jogo.add(base)
    return {"variaveis_tecnicas": variaveis_tecnicas, "nomes_do_jogo": nomes_do_jogo,
            "personagens": personagens, "nomes_personagem_variaveis": nomes_personagem_variaveis}

def extrair_info_nome_personagem(chamada, kind):
    m = re.search(r'\bname\s*=\s*(' + QSTR + r'|[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)', chamada)
    if m:
        v=m.group(1)
        if v[:1] in ('"', "'"): return strip_quotes(v), None, m.start(1)
        return (None, v, m.start(1)) if kind == 'DynamicCharacter' else (None, None, m.start(1))
    m = re.match(r'\s*(' + QSTR + r')\s*(?:,|\))', chamada)
    if m:
        v=strip_quotes(m.group(1))
        if kind == 'DynamicCharacter' and IDENT.match(v): return None, v, m.start(1)
        return v, None, m.start(1)
    return None, None, -1

def _parse_python_string_at(text, pos):
    """Retorna (fim_exclusivo, eh_triplo) para uma string Python iniciada em pos."""
    if pos < 0 or pos >= len(text) or text[pos] not in ('"', "'"):
        return -1, False
    quote = text[pos]
    if text.startswith(quote * 3, pos):
        delim = quote * 3
        i = pos + 3
        while i < len(text):
            if text.startswith(delim, i):
                # Uma sequência escapada de barras não fecha a string.
                barras = 0
                j = i - 1
                while j >= pos and text[j] == '\\':
                    barras += 1
                    j -= 1
                if barras % 2 == 0:
                    return i + 3, True
            i += 1
        return -1, True

    i = pos + 1
    esc = False
    while i < len(text):
        ch = text[i]
        if esc:
            esc = False
        elif ch == '\\':
            esc = True
        elif ch == quote:
            return i + 1, False
        elif ch in '\r\n':
            return -1, False
        i += 1
    return -1, False


def _find_matching_paren_python(text, open_pos):
    """Encontra o ')' correspondente respeitando strings simples/triplas e comentários."""
    if open_pos < 0 or open_pos >= len(text) or text[open_pos] != '(':
        return -1
    depth = 0
    i = open_pos
    while i < len(text):
        ch = text[i]
        if ch in ('"', "'"):
            fim, _ = _parse_python_string_at(text, i)
            if fim < 0:
                return -1
            i = fim
            continue
        if ch == '#':
            nl = text.find('\n', i)
            i = len(text) if nl < 0 else nl + 1
            continue
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _offsets_de_linhas(linhas_raw):
    offsets = []
    atual = 0
    for linha in linhas_raw:
        offsets.append(atual)
        atual += len(linha)
    offsets.append(atual)
    return offsets


def _linha_e_coluna_por_offset(offsets, offset):
    # Busca linear é suficiente aqui: só é usada para as entradas especiais de poemas.
    lo, hi = 0, len(offsets) - 1
    while lo + 1 < hi:
        meio = (lo + hi) // 2
        if offsets[meio] <= offset:
            lo = meio
        else:
            hi = meio
    return lo + 1, offset - offsets[lo]


def _achar_fecho_aspas_mesma_linha(linha, pos, quote):
    i = pos + 1
    while i < len(linha):
        if linha[i] == "\\":
            i += 2
            continue
        if linha[i] == quote:
            return i
        i += 1
    return -1


def _prefixo_parece_texto_multilinha(prefixo):
    p = prefixo.strip()
    if not p:
        return True
    if any(ch in p for ch in ('=', '(', ')', '[', ']', '{', '}', ':')):
        return False
    baixos = p.lower()
    proibidos = (
        'label ', 'jump ', 'call ', 'return ', 'define ', 'default ', 'init ',
        'python ', 'screen ', 'transform ', 'style ', 'image ', 'scene ',
        'show ', 'hide ', 'play ', 'stop ', 'queue ', 'voice ', 'with ',
        'camera ', 'layeredimage ', 'renpy.', 'config.', 'gui.', '$',
    )
    if baixos.startswith(proibidos):
        return False
    palavras = re.findall(r'[A-Za-z_][A-Za-z0-9_.-]*', p)
    if not palavras or len(palavras) > 12:
        return False
    if any(x.lower() in ('text', 'caption', 'message', 'title', 'description', 'font', 'color') for x in palavras[:-1]):
        return False
    return True


def _registrar_fragmento_multilinha(por_linha, numero, linha, inicio, fim, contexto):
    inicio = max(0, inicio)
    fim = min(len(linha), fim)
    while inicio < fim and linha[inicio] in ' \t':
        inicio += 1
    while fim > inicio and linha[fim - 1] in ' \t':
        fim -= 1
    if inicio >= fim:
        return
    texto = linha[inicio:fim]
    if not texto.strip():
        return
    literal = codificar_literal_traducao(texto)
    if not tem_conteudo_traduzivel(literal):
        return
    por_linha.setdefault(numero, []).append({
        'coluna_inicio': inicio,
        'coluna_fim': fim,
        'original': texto,
        'trecho': literal,
        'tipo': 'multilinha_renpy',
        'confianca': 100,
        'contexto': contexto,
    })


def _eh_arquivo_banco_poemas_python(caminho):
    """Retorna True para o banco Python principal de poemas."""
    rel = (caminho or u'').replace('\\', '/').lower()
    base = os.path.basename(rel)
    return ('/poem_responses/py/' in rel and base in ('poems.rpy', 'poems_ren.py'))

def extrair_strings_multilinha_renpy(caminho, linhas_raw, linhas_python=None, linhas_blocos_tecnicos=None):
    linhas_python = linhas_python or set()
    linhas_blocos_tecnicos = linhas_blocos_tecnicos or set()
    caminho_norm = caminho.replace('\\', '/').lower()
    base = os.path.basename(caminho_norm)
    # O parser semântico de poemas é o dono de poems.rpy/poems_ren.py.
    # O detector genérico não deve capturar add_poem/title/text como diálogo.
    if (('/poem_responses/' in caminho_norm and base in ('poems.rpy', 'poems_ren.py'))
            or '/py/' in caminho_norm or caminho_norm.endswith('/py')):
        return {}, set()
    por_linha = {}
    linhas_envolvidas = set()
    ativo = None

    for idx, raw in enumerate(linhas_raw, 1):
        linha = raw.rstrip('\r\n')
        if idx in linhas_python or idx in linhas_blocos_tecnicos:
            continue

        if ativo is not None:
            quote = ativo['quote']
            fechamento = _achar_fecho_aspas_mesma_linha(linha, -1, quote) if linha else -1
            linhas_envolvidas.add(idx)
            if fechamento >= 0:
                _registrar_fragmento_multilinha(por_linha, idx, linha, 0, fechamento, ativo['contexto'])
                ativo = None
            else:
                _registrar_fragmento_multilinha(por_linha, idx, linha, 0, len(linha), ativo['contexto'])
            continue

        if not linha.strip() or linha.lstrip().startswith('#'):
            continue

        i = 0
        abertura_encontrada = None
        while i < len(linha):
            if linha[i] == "\\":
                i += 2
                continue
            if linha.startswith('"""', i) or linha.startswith("'''", i):
                i += 3
                continue
            if linha[i] in ('"', "'"):
                q = linha[i]
                fechamento = _achar_fecho_aspas_mesma_linha(linha, i, q)
                if fechamento >= 0:
                    i = fechamento + 1
                    continue
                if _prefixo_parece_texto_multilinha(linha[:i]):
                    abertura_encontrada = (i, q)
                    break
            i += 1
        if abertura_encontrada is None:
            continue

        pos, quote = abertura_encontrada
        contexto = u"Multilinha Ren'Py: " + (u'fala' if linha[:pos].strip() else u'narrativa')
        _registrar_fragmento_multilinha(por_linha, idx, linha, pos + 1, len(linha), contexto)
        linhas_envolvidas.add(idx)
        ativo = {'quote': quote, 'contexto': contexto}

    return por_linha, linhas_envolvidas

def extrair_corpos_poemas(caminho, linhas_raw):
    """Extrai corpos textuais multilinha de poemas e construções de tradução explícita.

    Suporta tanto poem_db.add_poem()/Poem(...) quanto o formato comum
    `text=_()`/`text=_(string tripla)` usado por mods antigos e modernos.
    Cada linha física recebe uma entrada própria no mapa para preservar a
    estrutura necessária à reinjeção.
    """
    caminho_norm = caminho.replace('\\', '/').lower()
    base = os.path.basename(caminho_norm)
    if base not in ('poems.rpy', 'poems_ren.py') and '/poem_responses/' not in caminho_norm:
        return {}, set()
    if base == POEMRESPONSES_BASE_NAME:
        return {}, set()

    conteudo = u''.join(linhas_raw)
    offsets = _offsets_de_linhas(linhas_raw)
    por_linha = {}
    bloqueios = set()

    def adicionar_titulo_literal(abs_args_inicio, args_text, contexto=u'título do poema'):
        m_title = re.search(r'\btitle\s*=\s*("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')', args_text, re.I)
        if not m_title:
            return
        literal = m_title.group(1)
        abs_literal = abs_args_inicio + m_title.start(1)
        linha_num = conteudo.count('\n', 0, abs_literal) + 1
        inicio_linha = conteudo.rfind('\n', 0, abs_literal) + 1
        col_inicio = abs_literal - inicio_linha
        por_linha.setdefault(linha_num, []).append({
            'coluna_inicio': col_inicio,
            'coluna_fim': col_inicio + len(literal),
            'original': literal,
            'trecho': literal,
            'tipo': 'poema_titulo',
            'confianca': 100,
            'contexto': contexto,
        })

    text_re = re.compile(
        r'\btext\s*=\s*(?:(?:_|__|___|_p)\s*\(\s*)?(?:r\s*)?(?P<quote>"{3}|\'{3}|"|\')',
        re.I
    )
    translate_re = re.compile(r'\btranslate\s*=\s*(' + QSTR + r')', re.I)
    ident_re = re.compile(r'\b(?:poem_db\s*\.\s*)?add_poem\s*\(\s*(' + QSTR + r')', re.I)

    def adicionar_corpo(abs_valor, fim_string, identificador, tipo='poema_corpo', contexto_prefixo=u'corpo do poema '):
        if fim_string < 0:
            return
        m_quote = conteudo[abs_valor:abs_valor + 3]
        if m_quote not in ('"""', "'''"):
            return
        inicio_conteudo = abs_valor + 3
        if inicio_conteudo < fim_string and conteudo[inicio_conteudo] == '\\':
            if conteudo.startswith('\\\r\n', inicio_conteudo):
                inicio_conteudo += 3
            elif conteudo.startswith('\\\n', inicio_conteudo):
                inicio_conteudo += 2
        fim_conteudo = fim_string - 3
        if inicio_conteudo >= fim_conteudo:
            return
        for numero, inicio_linha in enumerate(offsets[:-1], 1):
            fim_linha = offsets[numero]
            inicio = max(inicio_conteudo, inicio_linha)
            fim = min(fim_conteudo, fim_linha)
            if inicio >= fim:
                continue
            linha_sem_fim = linhas_raw[numero - 1].rstrip('\r\n')
            lim = min(fim, inicio_linha + len(linha_sem_fim))
            if lim <= inicio:
                continue
            raw = conteudo[inicio:lim]
            if raw.endswith('\\'):
                lim -= 1
                raw = raw[:-1]
            if not raw.strip():
                continue
            col_inicio = inicio - inicio_linha
            col_fim = lim - inicio_linha
            por_linha.setdefault(numero, []).append({
                'coluna_inicio': col_inicio,
                'coluna_fim': col_fim,
                'original': raw,
                'trecho': json.dumps(raw, ensure_ascii=False),
                'tipo': tipo,
                'confianca': 100,
                'contexto': contexto_prefixo + identificador,
            })

    # A) poem_db.add_poem(...) — usado por alguns templates/mods.
    add_re = re.compile(r'\b(?:poem_db\s*\.\s*)?add_poem\s*\(', re.I)
    for m_call in add_re.finditer(conteudo):
        linha_inicio = conteudo.rfind('\n', 0, m_call.start()) + 1
        if conteudo[linha_inicio:m_call.start()].lstrip().startswith('#'):
            continue
        abre = conteudo.find('(', m_call.start())
        fecha = _find_matching_paren_python(conteudo, abre)
        if fecha < 0:
            continue
        args = conteudo[abre + 1:fecha]
        adicionar_titulo_literal(abre + 1, args)
        m_trans = translate_re.search(args)
        modo = 'all'
        if m_trans:
            try:
                modo = ast.literal_eval(m_trans.group(1))
            except Exception:
                modo = strip_quotes(m_trans.group(1))
        if modo not in ('all', 'title', 'text', 'none'):
            continue
        if modo in ('none', 'title'):
            continue
        m_text = text_re.search(args)
        if not m_text:
            continue
        abs_valor = abre + 1 + m_text.start('quote')
        fim_string, eh_triplo = _parse_python_string_at(conteudo, abs_valor)
        if not eh_triplo:
            continue
        m_id = ident_re.match(conteudo[m_call.start():])
        identificador = strip_quotes(m_id.group(1)) if m_id else u'poema'
        for _items in por_linha.values():
            for _item in _items:
                if _item.get('tipo') == 'poema_titulo' and _item.get('contexto') == u'título do poema':
                    _item['contexto'] = u'título do poema ' + identificador
        adicionar_corpo(abs_valor, fim_string, identificador)

    # B) Construtores Poem(...) — formato comum em mods como Interaction.
    poem_ctor_re = re.compile(r'(?m)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*Poem\s*\(')
    for m_ctor in poem_ctor_re.finditer(conteudo):
        linha_inicio = conteudo.rfind('\n', 0, m_ctor.start()) + 1
        if conteudo[linha_inicio:m_ctor.start()].lstrip().startswith('#'):
            continue
        abre = conteudo.find('(', m_ctor.start())
        fecha = _find_matching_paren_python(conteudo, abre)
        if fecha < 0:
            continue
        bloco = conteudo[m_ctor.start():fecha + 1]
        m_text = text_re.search(bloco)
        if not m_text:
            continue
        abs_valor = m_ctor.start() + m_text.start('quote')
        fim_string, eh_triplo = _parse_python_string_at(conteudo, abs_valor)
        if not eh_triplo:
            continue
        m_title = re.search(r'(?m)^\s*title\s*=\s*(["\'])(.*?)\1\s*,?\s*$', bloco)
        titulo = m_title.group(2) if m_title else u''
        if m_title:
            abs_literal = m_ctor.start() + m_title.start(1)
            literal = m_title.group(1) + m_title.group(2) + m_title.group(1)
            linha_num = conteudo.count('\n', 0, abs_literal) + 1
            inicio_linha = conteudo.rfind('\n', 0, abs_literal) + 1
            col_inicio = abs_literal - inicio_linha
            por_linha.setdefault(linha_num, []).append({
                'coluna_inicio': col_inicio,
                'coluna_fim': col_inicio + len(literal),
                'original': literal,
                'trecho': literal,
                'tipo': 'poema_titulo',
                'confianca': 100,
                'contexto': u'título de Poem ' + (m_ctor.group(1) or u'')
            })
        corpo_start = abs_valor + 3
        corpo_end = fim_string - 3
        corpo = conteudo[corpo_start:corpo_end]
        if corpo.startswith('\\\r\n'):
            corpo = corpo[3:]
        elif corpo.startswith('\\\n'):
            corpo = corpo[2:]
        compact_b64 = u''.join(x for x in corpo if not x.isspace() and x != u'\\')
        base64_especial = False
        if len(compact_b64) >= 32 and len(compact_b64) % 4 == 0 and re.fullmatch(r'[A-Za-z0-9+/=]+', compact_b64):
            try:
                bruto_dec = base64.b64decode(compact_b64, validate=True)
                dec = bruto_dec.decode('utf-8')
                imprimiveis = sum(1 for ch in dec if ch.isprintable() or ch in u'\r\n\t')
                base64_especial = len(dec) >= 12 and float(imprimiveis) / max(1, len(dec)) >= 0.92
            except Exception:
                base64_especial = False
        linhas_corpo = [x for x in corpo.splitlines() if x.strip()]
        virgulas_duplas = corpo.count(u',,')
        tokens_glitch = re.findall(r'\b[A-Za-z]{5,}\b', corpo)
        glitch_especial = (
            virgulas_duplas >= 8 and len(linhas_corpo) >= 3 and
            len(tokens_glitch) >= 20 and
            not re.search(r'[.!?]{2,}|\b(?:the|you|i|my|and|but|this|that)\b', corpo, re.I)
        )
        if base64_especial or glitch_especial:
            continue
        adicionar_corpo(abs_valor, fim_string,
                        m_ctor.group(1) + (u' (' + titulo + u')' if titulo else u''))

    return por_linha, bloqueios


def extrair_strings_gettext_multilinha(caminho, linhas_raw):
    """Extrai strings triplas usadas explicitamente em _()/__()/___()/_p()."""
    base = os.path.basename(caminho).lower()
    if base == POEMRESPONSES_BASE_NAME:
        return {}, set()
    conteudo = u''.join(linhas_raw)
    offsets = _offsets_de_linhas(linhas_raw)
    por_linha = {}
    linhas_envolvidas = set()
    padrao = re.compile(
        r'(?<![A-Za-z0-9_.])(?:_|__|___|_p)\s*\(\s*(?:r\s*)?(?P<quote>"{3}|\'{3})',
        re.I
    )
    for m in padrao.finditer(conteudo):
        linha_inicio = conteudo.rfind('\n', 0, m.start()) + 1
        if conteudo[linha_inicio:m.start()].lstrip().startswith('#'):
            continue
        abs_valor = m.start('quote')
        fim_string, eh_triplo = _parse_python_string_at(conteudo, abs_valor)
        if fim_string < 0 or not eh_triplo:
            continue
        inicio_conteudo = abs_valor + 3
        if inicio_conteudo < fim_string and conteudo[inicio_conteudo] == '\\':
            if conteudo.startswith('\\\r\n', inicio_conteudo):
                inicio_conteudo += 3
            elif conteudo.startswith('\\\n', inicio_conteudo):
                inicio_conteudo += 2
        fim_conteudo = fim_string - 3
        if inicio_conteudo >= fim_conteudo:
            continue
        group = hashlib.sha256(('%s\0%d' % (caminho, abs_valor)).encode('utf-8')).hexdigest()[:20]
        for numero, inicio_linha in enumerate(offsets[:-1], 1):
            fim_linha = offsets[numero]
            inicio = max(inicio_conteudo, inicio_linha)
            fim = min(fim_conteudo, fim_linha)
            if inicio >= fim:
                continue
            linha_sem_fim = linhas_raw[numero - 1].rstrip('\r\n')
            lim = min(fim, inicio_linha + len(linha_sem_fim))
            if lim <= inicio:
                continue
            raw = conteudo[inicio:lim]
            if raw.endswith('\\'):
                lim -= 1
                raw = raw[:-1]
            if not raw.strip():
                continue
            col_inicio = inicio - inicio_linha
            col_fim = lim - inicio_linha
            por_linha.setdefault(numero, []).append({
                'coluna_inicio': col_inicio,
                'coluna_fim': col_fim,
                'original': raw,
                'trecho': json.dumps(raw, ensure_ascii=False),
                'tipo': 'gettext_multilinha',
                'confianca': 100,
                'contexto': u'string multilinha explícita de tradução (_/__/_p)',
                'logical_group_hint': group,
            })
            linhas_envolvidas.add(numero)
    return por_linha, linhas_envolvidas


def decodificar_texto_extraido(texto):
    """Converte uma linha de poema JSON-quotada de volta para texto bruto.

    Não usa ``strip()`` no valor inteiro antes do json.loads(): espaços que fazem
    parte do conteúdo da string precisam sobreviver à reintegração, especialmente
    em corpos multilinha que usam continuação física com ``\\``.
    """
    valor = texto if isinstance(texto, str) else str(texto or u"")
    if len(valor) >= 2 and valor.lstrip().startswith('"') and valor.rstrip().endswith('"'):
        try:
            resultado = json.loads(valor)
            if isinstance(resultado, str):
                return resultado
        except Exception:
            pass
    return strip_quotes(valor.strip())


def literal_unico_traduzivel(valor):
    """Verdadeiro quando o valor inteiro é uma única string literal Ren'Py real."""
    if not isinstance(valor, str):
        return False
    s = valor.strip()
    if len(s) >= 3 and s[0] in 'rR' and s[1] in (u'"', u"'", u'`') and s[-1] == s[1]:
        s = s[1:]
    if len(s) < 2 or s[0] not in (u'"', u"'", u'`') or s[-1] != s[0]:
        return False
    quote = s[0]
    i = 1
    while i < len(s) - 1:
        if s[i] == u'\\':
            i += 2
            continue
        if s[i] == quote:
            return i == len(s) - 1
        i += 1
    return True



def _localizar_tripo_abertura(linha):
    """Localiza aspas triplas de monólogo ou de _p()/funções de tradução Ren'Py."""
    candidatos = []
    for q in (chr(34) * 3, chr(39) * 3):
        pos = linha.find(q)
        if pos >= 0 and (pos == 0 or linha[pos - 1] != "\\"):
            # Prefixo r antes da tripla também é aceito.
            if pos > 0 and linha[pos - 1] in 'rR' and (pos < 2 or not (linha[pos - 2].isalnum() or linha[pos - 2] == '_')):
                candidatos.append((pos, q))
            else:
                candidatos.append((pos, q))
    if not candidatos:
        return None
    pos, q = min(candidatos, key=lambda x: x[0])
    prefixo = linha[:pos].strip()
    if prefixo.startswith('#'):
        return None
    if prefixo:
        # _p/_(...)/__(...)/___(...) são construções explícitas de tradução e
        # precisam ser aceitas mesmo em atribuições como
        # `define gui.about = _p("""...""")`.
        if re.search(r'(?:^|[=,(])\s*(?:_|__|___|_p)\s*\(\s*r?\s*$', prefixo, re.I):
            return pos, q
        proibidos = ('$ ', 'label ', 'jump ', 'call ', 'define ', 'default ', 'init ', 'python ', 'screen ', 'transform ', 'style ')
        if prefixo.startswith(proibidos):
            return None
        if re.fullmatch(r'r', prefixo, re.I):
            return pos, q
        if not re.fullmatch(r'(?:r\s+)?(?:[A-Za-z_][\w.]*|\[[^\]]+\]|(?:[A-Za-z_][\w.]*\s+){1,5}[A-Za-z_][\w.]*)', prefixo):
            return None
    return pos, q


def _extrair_monologos_triplos_renpy(caminho, linhas_raw, linhas_python=None, linhas_blocos_tecnicos=None):
    """Extrai monólogos Ren'Py e strings de tradução em aspas triplas fora de Python.

    Cada linha física de conteúdo vira uma entrada independente no mapa para
    preservar a estrutura original exigida pela reinjeção. Strings triplas dentro
    de diretórios Python/compatibilidade são tratadas como docstrings/código e
    permanecem fora da extração.
    """
    base = os.path.basename(caminho).lower()
    caminho_norm = caminho.replace('\\', '/').lower()
    if base == POEMRESPONSES_BASE_NAME:
        return {}, set()
    # poems.rpy/poems_ren.py são processados por extrair_corpos_poemas(), que
    # já conhece o limite lógico dos blocos Poem/text=_()/__()/_p(). Não deixe
    # o extrator genérico de monólogo duplicar as mesmas linhas físicas.
    if base in ('poems.rpy', 'poems_ren.py') and '/poem_responses/' in caminho_norm:
        return {}, set()
    # Pastas `py` deste template carregam código Python/compatibilidade. Em
    # particular, há docstrings e blocos `python early:` escritos com aspas
    # triplas que não são texto de jogo. Não devemos transformá-los em diálogo.
    if '/py/' in caminho_norm or caminho_norm.endswith('/py'):
        return {}, set()
    linhas_python = linhas_python or set()
    linhas_blocos_tecnicos = linhas_blocos_tecnicos or set()
    por_linha = {}
    linhas_monologo = set()
    ativo = None

    def adicionar_segmento(numero, linha_original, inicio, fim, contexto):
        if inicio < 0 or fim <= inicio:
            return
        while inicio < fim and linha_original[inicio] in ' \t':
            inicio += 1
        while fim > inicio and linha_original[fim - 1] in ' \t':
            fim -= 1
        if inicio < fim and linha_original[inicio] == '\\' and linha_original[inicio + 1:].strip() == '':
            inicio = fim
        if fim > inicio and linha_original[fim - 1] == '\\':
            fim -= 1
        if inicio >= fim:
            return
        texto = linha_original[inicio:fim]
        if not tem_conteudo_traduzivel(json.dumps(texto, ensure_ascii=False)):
            return
        por_linha.setdefault(numero, []).append({
            'coluna_inicio': inicio,
            'coluna_fim': fim,
            'original': linha_original[inicio:fim],
            'trecho': json.dumps(texto, ensure_ascii=False),
            'tipo': 'monologo_triplas',
            'confianca': 100,
            'contexto': contexto,
        })

    for idx, raw in enumerate(linhas_raw, 1):
        linha = raw.rstrip('\r\n')
        if idx in linhas_python or idx in linhas_blocos_tecnicos:
            continue

        if ativo is not None:
            q = ativo['quote']
            fechamento = linha.find(q)
            linhas_monologo.add(idx)
            if fechamento >= 0:
                adicionar_segmento(idx, linha, 0, fechamento, ativo['contexto'])
                ativo = None
            else:
                adicionar_segmento(idx, linha, 0, len(linha), ativo['contexto'])
            continue

        if not linha.strip() or linha.lstrip().startswith('#'):
            continue
        abertura = _localizar_tripo_abertura(linha)
        if not abertura:
            continue
        pos, q = abertura
        # String tripla sem prefixo de fala (_p/_(...)/__... ou personagem)
        # é típica de docstring. Ren'Py aceita strings diretas nas construções
        # de diálogo, mas triple-quoted strings genéricas não são uma forma
        # normal de narrativa; evitamos capturar código por acidente.
        prefixo = linha[:pos].strip()
        if not prefixo and linha.lstrip().startswith(q):
            continue
        linhas_monologo.add(idx)
        inicio = pos + 3
        restante = linha[inicio:]
        fechamento_rel = restante.find(q)
        contexto = u"Monólogo Ren'Py em aspas triplas"
        if fechamento_rel >= 0:
            adicionar_segmento(idx, linha, inicio, inicio + fechamento_rel, contexto)
            continue
        if restante == '\\':
            ativo = {'quote': q, 'contexto': contexto}
        else:
            if restante.startswith('\\'):
                inicio += 1
            adicionar_segmento(idx, linha, inicio, len(linha), contexto)
            ativo = {'quote': q, 'contexto': contexto}

    return por_linha, linhas_monologo


# Prioridade global para resolver candidatos que disputam o mesmo trecho físico.
# A regra é deliberadamente única para todos os mods: fontes sintáticas mais
# específicas vencem detectores genéricos. Em empate, a primeira ocorrência
# continua sendo mantida. Isso impede dupla reinjeção sem criar correções
# específicas por arquivo/mod.
TIPO_PRIORIDADE_SOBREPOSICAO = {
    'poema_titulo': 510,
    'poema_corpo': 500,
    'gettext_multilinha': 470,
    'monologo_triplas': 460,
    'multilinha_renpy': 450,
    'poema_palavra_txt': 430,
    'poema_palavra': 430,
    'renpy_nativo_dialogo': 320,
    'renpy_nativo_string': 310,
    'url_visivel': 300,
    'nome_personagem': 220,
    'texto_creditos_bloco': 210,
    'texto_creditos_dados': 180,
    'variavel_texto': 170,
    'dialogo': 160,
    'narrativa': 150,
    'ui': 140,
}


def _resolver_sobreposicoes_registros(registros):
    """Remove disputas de spans na mesma linha usando a política global de prioridade.

    O detector antigo eliminava apenas spans exatamente iguais. Quando um detector
    especializado cobre 0-24 e outro cobre 0-23, ambos passavam e a reinjeção
    podia escrever duas vezes na mesma região. Aqui todos os candidatos de uma
    linha são comparados por intervalo físico antes de entrarem no mapa final.

    Retorna (registros_filtrados, conflitos). `conflitos` é somente informativo:
    um conflito resolvido não interrompe a extração.
    """
    if len(registros) <= 1:
        return list(registros), []

    classificados = []
    for indice, registro in enumerate(registros):
        inicio, fim = registro[0], registro[1]
        tipo = registro[2] if len(registro) > 2 else u''
        prioridade = TIPO_PRIORIDADE_SOBREPOSICAO.get(tipo, 100)
        tamanho = max(0, fim - inicio)
        classificados.append((indice, registro, prioridade, tamanho))

    # Mais específico primeiro; em empate, preserva a ordem original.
    classificados.sort(key=lambda item: (-item[2], -item[3], item[0]))

    mantidos = []
    conflitos = []
    for indice, registro, prioridade, tamanho in classificados:
        inicio, fim = registro[0], registro[1]
        conflito_com = None
        for _, outro, outra_prioridade, outro_tamanho in mantidos:
            o_inicio, o_fim = outro[0], outro[1]
            if max(inicio, o_inicio) < min(fim, o_fim):
                conflito_com = (outro, outra_prioridade, outro_tamanho)
                break

        if conflito_com is not None:
            outro, outra_prioridade, outro_tamanho = conflito_com
            conflitos.append({
                'novo_tipo': registro[2] if len(registro) > 2 else u'',
                'novo_inicio': inicio,
                'novo_fim': fim,
                'mantido_tipo': outro[2] if len(outro) > 2 else u'',
                'mantido_inicio': outro[0],
                'mantido_fim': outro[1],
            })
            continue

        mantidos.append((indice, registro, prioridade, tamanho))

    mantidos.sort(key=lambda item: item[0])
    return [registro for _, registro, _, _ in mantidos], conflitos


def _resolver_sobreposicoes_mapa(entradas_mapa, textos_traduzidos):
    """Filtra entradas já mapeadas que disputam o mesmo span físico.

    Compatibilidade importante: mapas antigos do V100 também ficam seguros.
    A validação de contagem continua exigindo a mesma quantidade de textos;
    somente os candidatos sobrepostos deixam de ser escritos no arquivo.
    """
    pares = list(enumerate(zip(entradas_mapa, textos_traduzidos)))
    if len(pares) <= 1:
        return [(e, t) for _, (e, t) in pares], []

    classificados = []
    for indice, (entrada, traduzido) in pares:
        linha = int(entrada.get('linha', 0) or 0)
        inicio = int(entrada.get('coluna_inicio', 0) or 0)
        fim = int(entrada.get('coluna_fim', 0) or 0)
        tipo = entrada.get('tipo', u'')
        prioridade = TIPO_PRIORIDADE_SOBREPOSICAO.get(tipo, 100)
        tamanho = max(0, fim - inicio)
        classificados.append((indice, entrada, traduzido, linha, inicio, fim, prioridade, tamanho))

    classificados.sort(key=lambda item: (-item[6], -item[7], item[0]))
    mantidos = []
    conflitos = []

    for item in classificados:
        indice, entrada, traduzido, linha, inicio, fim, prioridade, tamanho = item
        conflito_com = None
        for outro in mantidos:
            _, outra_entrada, _, outra_linha, outro_inicio, outro_fim, outra_prioridade, outro_tamanho = outro
            if linha == outra_linha and max(inicio, outro_inicio) < min(fim, outro_fim):
                conflito_com = outra_entrada
                break
        if conflito_com is not None:
            conflitos.append({
                'linha': linha,
                'novo_tipo': tipo,
                'novo_inicio': inicio,
                'novo_fim': fim,
                'mantido_tipo': conflito_com.get('tipo', u''),
                'mantido_inicio': int(conflito_com.get('coluna_inicio', 0) or 0),
                'mantido_fim': int(conflito_com.get('coluna_fim', 0) or 0),
            })
            continue
        mantidos.append(item)

    mantidos.sort(key=lambda item: item[0])
    return [(item[1], item[2]) for item in mantidos], conflitos


def extrair_arquivo_com_mapa(caminho, variaveis_nome_dinamico, indice_arquivos=None, vocabulario=None, oracle_por_arquivo=None):
    """Extração de alta cobertura: motor atual + recuperação contextual de versões anteriores."""
    textos = []
    mapa = []
    linhas_raw = ler_linhas_raw(caminho)
    linhas_blocos_tecnicos = construir_linhas_blocos_tecnicos(linhas_raw)
    linhas_python = construir_linhas_python(linhas_raw)
    conteudo_completo = u"".join(linhas_raw)
    conteudo_analise = mascarar_secoes_python_renpy(conteudo_completo) if eh_renpy_moderno(caminho) else conteudo_completo
    linhas_ativas = linhas_renpy_ativas(caminho, linhas_raw)

    entradas_definicoes, dynamic_vars_descobertas = analisar_definicoes_personagens(caminho, conteudo_analise)
    # Achievement/AchievementCount vivem frequentemente dentro de blocos Python
    # modernos, que são mascarados em `conteudo_analise`. Por isso esta regra
    # recebe o conteúdo completo e recupera somente os argumentos textuais
    # semanticamente visíveis.
    entradas_definicoes.extend(analisar_construtores_achievements(caminho, conteudo_completo))
    # 01definitions.rpy do telefone usa phone.character.Character(...), que
    # não é uma definição Character tradicional. Trata-se de outra fonte válida
    # de nomes exibidos; ela deve ser analisada separadamente e sem eliminar
    # ocorrências só porque o mesmo texto também existe em definitions.rpy.
    entradas_definicoes.extend(analisar_definicoes_phone(caminho, conteudo_analise))
    variaveis_nome_dinamico.update(dynamic_vars_descobertas)
    definicoes_por_linha = {}
    for entrada_def in entradas_definicoes:
        definicoes_por_linha.setdefault(entrada_def["linha"], []).append(entrada_def)

    linhas_em_definicao_personagem = set()
    for m_char_span in CHAR_DEF_START_RE.finditer(conteudo_analise):
        abre = conteudo_analise.find('(', m_char_span.start())
        fecha = _find_matching_paren(conteudo_analise, abre) if abre >= 0 else -1
        if fecha < 0:
            continue
        l1, _ = _line_col_from_offset(conteudo_analise, m_char_span.start())
        l2, _ = _line_col_from_offset(conteudo_analise, fecha)
        for numero in range(l1, l2 + 1):
            linhas_em_definicao_personagem.add(numero)

    QSTR_LOCAL = QSTR
    # Mantém o fallback amplo da versão recente: ele é importante para o dia 1.
    SUFIXO_FALA = r'(?:\s+(?:nointeract|id\s+[\w.]+|with\s+[\w.]+(?:\((?:[^()]|\([^()]*\))*\))?|\((?:[^()]|\([^()]*\))*\)))+'
    SUFIXO_ESCOLHA = r'(?:\s*\((?:[^()]|\([^()]*\))*\))?(?:\s+if\s+.+?)?\s*:'
    PREFIJO_FALA = r'(?:-?[A-Za-z0-9_][A-Za-z0-9_.-]*|@|' + QSTR_LOCAL + r')'
    LEGACY_DIALOGO = re.compile(r'^(?:(?:' + PREFIJO_FALA + r')\s+){0,16}(' + QSTR_LOCAL + r')(?:(?:\s*:)?(?:\s*\w*)?|' + SUFIXO_FALA + r'|' + SUFIXO_ESCOLHA + r')\s*(?:#.*)?$')
    UI_RES = re.compile(r'(?<!\w)(?:_|__|___|_p)\s*\(\s*(' + QSTR_LOCAL + r')')
    VISIBLE_CALL_RE = re.compile(r'\b(?:renpy\.input|renpy\.notify|renpy\.say|Notify|Confirm|InputValue)\s*\(\s*(' + QSTR_LOCAL + r')')
    TEXT_CALL_RE = re.compile(r'\b(?:Text|ParameterizedText)\s*\(\s*(' + QSTR_LOCAL + r')')
    SHOW_DISPLAY_TEXT_RE = re.compile(
        r'\bshow\s+(?:text|credits(?:_header|_text|_[A-Za-z0-9_]+)?|[A-Za-z_][A-Za-z0-9_]*(?:text|caption|message|dialog|label|title|header|body)[A-Za-z0-9_]*)\s+(' + QSTR_LOCAL + r')'
    )
    UPDATECONSOLE_MESSAGE_RE = re.compile(
        r'\b(?:updateconsole|updateconsole_clearall)\s*\([^,]+,\s*(' + QSTR_LOCAL + r')'
    )
    VISIBLE_KWARG_RE = re.compile(
        r'\b(?:message|text|caption|prompt|title)\s*=\s*(' + QSTR_LOCAL + r')'
    )
    DIALOG_CALL_RE = re.compile(
        r'\b(?:dialog|show_dialog)\s*\([^\n]*?\b(?:message|text|caption|prompt)\s*=\s*(' + QSTR_LOCAL + r')'
    )
    CALL_SCREEN_DIALOG_RE = re.compile(
        r'\b(?:call|show)\s+screen\s+dialog\s*\(\s*(' + QSTR_LOCAL + r')'
    )
    RENPY_CALL_SCREEN_DIALOG_RE = re.compile(
        r'\brenpy\.(?:call_screen|show_screen)\s*\(\s*[\"\']dialog[\"\']\s*,\s*(' + QSTR_LOCAL + r')',
        re.I
    )
    DIALOG_SHOW_OBJECT_RE = re.compile(
        r'\b(?:Show|renpy\.(?:show_screen|call_screen))\s*\([^\n]*?(?:\bscreen\s*=\s*)?[\"\']dialog[\"\']',
        re.I
    )
    SHOW_MESSAGE_KWARG_RE = re.compile(
        r'\b(?:Show|show|renpy\.(?:show_screen|call_screen))\s*\([^\n]*?\bmessage\s*=\s*(' + QSTR_LOCAL + r')',
        re.I
    )
    EXCEPTION_MESSAGE_RE = re.compile(
        r'\b(?:renpy\.(?:error|notify)|(?:Exception|RuntimeError|ValueError|TypeError|AssertionError))\s*\(\s*(' + QSTR_LOCAL + r')'
    )
    SCREEN_TEXT_RE = re.compile(r'^\s*(?:text|textbutton|button|label|prompt|tooltip|confirm|caption)\s+(?:\(\s*)?(?:_\s*\(\s*)?(' + QSTR_LOCAL + r')', re.I)
    UI_DISPLAY_ARG_RE = re.compile(r'^\s*(?:text|textbutton|button|label|prompt|tooltip|confirm|caption)\s+(?:\(\s*)?(?:_\s*\(\s*)?(' + QSTR_LOCAL + r')', re.I)
    # Propriedades Ren'Py que encerram a expressão principal de um displayable.
    # É usada apenas para procurar fragmentos literais na expressão exibida,
    # sem atravessar para `action`, `style`, coordenadas ou outros argumentos.
    SCREEN_TEXT_PROPERTIES = frozenset((
        'action','alternate','at','activate_sound','background','default','focus_mask',
        'hover_sound','hovered','id','key','keysym','modal','mouse','padding','pos',
        'sensitive','selected','style','style_prefix','text_align','text_color',
        'text_font','text_size','text_style','tooltip','unhovered','xalign','xanchor',
        'xfill','xmaximum','xminimum','xoffset','xpadding','xpos','xsize','xzoom',
        'yalign','yanchor','yfill','ymaximum','yminimum','yoffset','ypadding','ypos',
        'ysize','yzoom','size_group','clipping','layout','vertical','spacing','margin',
        'align','anchor','area','xmargin','ymargin','xaround','yaround','xadjustment',
        'yadjustment','selected_idle','selected_hover','insensitive','substitute',
        'text_xalign','text_yalign','text_outlines','text_bold','text_italic',
        'text_kerning','text_line_spacing','text_line_leading','text_indent','text_justify',
        'text_slow','text_slow_done','text_min_width','text_max_width','text_minimum',
        'text_maximum','text_fit','language','style_group'
    ))

    def fim_expressao_texto_screen(linha, inicio):
        """Encontra o final do texto de text/textbutton, respeitando strings e parênteses."""
        quote = None; escape = False; paren = bracket = brace = 0; i = inicio
        while i < len(linha):
            ch = linha[i]
            if quote is not None:
                if escape: escape = False
                elif ch == '\\': escape = True
                elif ch == quote: quote = None
                i += 1; continue
            if ch in ('"', "'", '`'):
                quote = ch; i += 1; continue
            if ch == '(': paren += 1
            elif ch == ')' and paren: paren -= 1
            elif ch == '[': bracket += 1
            elif ch == ']' and bracket: bracket -= 1
            elif ch == '{': brace += 1
            elif ch == '}' and brace: brace -= 1
            elif ch == ':' and not (paren or bracket or brace):
                return i
            if ch.isspace() and not (paren or bracket or brace):
                m_prop = re.match(r'\s+([A-Za-z_][A-Za-z0-9_]*)\b', linha[i:])
                if m_prop and m_prop.group(1).lower() in SCREEN_TEXT_PROPERTIES:
                    return i
            i += 1
        return len(linha)

    MENU_OPTION_RE = re.compile(r'^\s*(' + QSTR_LOCAL + r')\s*(?:(?:if\b.*)|:)?\s*(?:#.*)?$')
    EXPLICIT_SAY_RE = re.compile(r'^\s*(' + QSTR_LOCAL + r')\s+(' + QSTR_LOCAL + r')(?:\s|$)')
    VISIVEL_ASSIGN_RE = re.compile(r'^\s*(?:define|default)\s+(config\.name|gui\.(?:about|name|title|main_menu_caption))\s*=\s*(' + QSTR_LOCAL + r')\s*$')
    PYTHON_RETURN_TEXT_RE = re.compile(r'^\s*return\s+(' + QSTR_LOCAL + r')\s*$', re.I)
    UPDATECONSOLE_BROAD_RE = re.compile(r'\b(?:updateconsole|updateconsole_clearall)\s*\(\s*(?:' + QSTR_LOCAL + r')\s*,\s*(' + QSTR_LOCAL + r')', re.I)
    ocupados = set()

    def registrar(linha_numero, inicio_limpo, fim_limpo, trecho, tipo, confianca, contexto, original_mapa=None):
        if not trecho:
            return
        if tipo not in ('poema_corpo', 'gettext_multilinha', 'multilinha_renpy', 'monologo_triplas') and trecho[0] not in ('"', "'", '`'):
            return
        if tipo not in ('poema_corpo', 'gettext_multilinha', 'multilinha_renpy', 'monologo_triplas'):
            inicio_real = len(prefixo_ws) + inicio_limpo
            fim_real = len(prefixo_ws) + fim_limpo
            # O span precisa coincidir exatamente com uma string real da linha.
            # Além do QSTR legado, aceitamos strings Ren'Py especiais (`...` e
            # r"..."/r'...'/r`...`). O prefixo r fica fora do span.
            span_normal = any(
                m.start() == inicio_real and m.end() == fim_real and m.group(0) == trecho
                for m in re.finditer(QSTR_LOCAL, linha_sem_fim)
            )
            span_especial = any(
                inicio == inicio_real and fim == fim_real and literal == trecho
                for inicio, fim, literal, _raw in iter_renpy_literais_especiais(linha_sem_fim)
            )
            if not (span_normal or span_especial):
                return
        # Algumas categorias especiais sao texto de jogador mesmo quando
        # o literal, isoladamente, parece um identificador/comando tecnico.
        # Ex.: palavras do minijogo de poemas como "play" e o nome de
        # grupo do telefone como "Welcome".
        # URL pura exibida em diálogo/UI é preservada no mapa, porém marcada
        # como `url_visivel` para nunca ser enviada ao Google Translate.
        if PURE_VISIBLE_URL_RE.match(strip_quotes(trecho).strip()) and tipo in (
                'dialogo', 'narrativa', 'ui', 'renpy_nativo_dialogo',
                'renpy_nativo_string', 'nome_grupo', 'monologo_triplas'):
            tipo = 'url_visivel'
        # Exceção contextual estreita: um literal que é parte da expressão
        # principal de `text`/`textbutton` é conteúdo visual comprovado. Nessa
        # posição, palavras curtas como "play", "camera" ou "with" podem parecer
        # identificadores para o filtro global, mas são rótulos vistos pelo usuário.
        # A regra só é ativada pelo detector abaixo, que limita o span à expressão
        # do texto e para antes de propriedades como `action`, evitando capturar
        # nomes de telas, variáveis e strings técnicas de ações.
        ui_expr_visivel = (tipo == 'ui' and contexto == 'fragmento textual estático em expressão de text/textbutton')
        if tipo not in ('poema_palavra', 'poema_palavra_txt', 'nome_grupo', 'url_visivel'):
            # Um placeholder puro como {hour}:{minute} ou {month}/{day}/{year}
            # é texto traduzível quando veio explicitamente de _()/__()/_p().
            # Não deixe o filtro técnico transformá-lo em "pontuação sem texto".
            placeholder_gettext = (
                tipo == 'ui' and
                PLACEHOLDER_TRADUZIVEL_RE.match(strip_quotes(trecho)) is not None
            )
            if (not placeholder_gettext and not ui_expr_visivel and
                    parece_texto_tecnico(trecho, indice_arquivos=indice_arquivos)):
                return
        if (tipo not in ('dialogo', 'narrativa', 'poema_palavra', 'nome_grupo', 'url_visivel')
                and not placeholder_gettext
                and not tem_conteudo_traduzivel(trecho)):
            return
        chave_origem = (linha_numero, inicio_limpo + len(prefixo_ws), fim_limpo + len(prefixo_ws))
        if chave_origem in poemas_bloqueados:
            return
        chave = (linha_numero, inicio_limpo, fim_limpo)
        if chave in ocupados:
            return
        ocupados.add(chave)
        registros.append((inicio_limpo, fim_limpo, tipo, confianca, contexto, trecho, original_mapa))

    poemas_por_linha, poemas_bloqueados = extrair_corpos_poemas(caminho, linhas_raw)
    gettext_por_linha, linhas_gettext_multilinha = extrair_strings_gettext_multilinha(caminho, linhas_raw)
    monologos_por_linha, linhas_monologo = _extrair_monologos_triplos_renpy(
        caminho, linhas_raw, linhas_python, linhas_blocos_tecnicos
    )
    multilinhas_por_linha, linhas_multilinha = extrair_strings_multilinha_renpy(
        caminho, linhas_raw, linhas_python, linhas_blocos_tecnicos
    )
    screen_indent = None
    menu_stack = []
    config_menu_bloco = None
    # Arquivos de layout Ren'Py mantêm parte da UI diretamente em
    # Python. Esses textos são visíveis mesmo sem `text()`/`menu` tradicional:
    # labels de config.main_menu/config.game_menu e mensagens layout.*.
    CONFIG_MAIN_MENU_LABEL_RE = re.compile(r'^\s*\(\s*(?:u)?(' + QSTR_LOCAL + r')\s*,')
    CONFIG_GAME_MENU_LABEL_RE = re.compile(r'^\s*\(\s*(?:None|(?:u)?' + QSTR_LOCAL + r')\s*,\s*(?:u)?(' + QSTR_LOCAL + r')\s*,')
    LAYOUT_VISIBLE_ASSIGN_RE = re.compile(r'^\s*layout\.[A-Z][A-Z0-9_]*\s*=\s*(' + QSTR_LOCAL + r')\s*$')
    for idx, linha_raw in enumerate(linhas_raw):
        numero_linha = idx + 1
        linha_sem_fim = linha_raw.rstrip("\r\n")
        linha_limpa = linha_sem_fim.strip()
        if not linha_limpa or linha_limpa.startswith('#'):
            continue

        # Regra global: o título definido por `config.name` permanece sempre original.
        # Bloqueia somente essa definição; o restante do options.rpy continua normal.
        if CONFIG_NAME_DEFINE_RE.match(linha_sem_fim):
            continue

        # Menus padrão do Ren'Py: somente o rótulo realmente mostrado ao
        # jogador entra no mapa; ações como `"load_screen"`/`"True"` ficam fora.
        if re.match(r'^\s*config\.main_menu\s*=\s*\[', linha_limpa, re.I):
            config_menu_bloco = 'main'
        elif re.match(r'^\s*config\.game_menu\s*=\s*\[', linha_limpa, re.I):
            config_menu_bloco = 'game'
        elif config_menu_bloco and linha_limpa == ']':
            config_menu_bloco = None
        prefixo_ws = linha_sem_fim[:len(linha_sem_fim) - len(linha_sem_fim.lstrip())]
        nivel_indent = len(prefixo_ws)
        registros = []

        if config_menu_bloco == 'main':
            m_cfgmenu = CONFIG_MAIN_MENU_LABEL_RE.match(linha_limpa)
            if m_cfgmenu:
                registrar(numero_linha, m_cfgmenu.start(1), m_cfgmenu.end(1), m_cfgmenu.group(1), 'ui', 100, 'rótulo visível de config.main_menu')
        elif config_menu_bloco == 'game':
            m_cfgmenu = CONFIG_GAME_MENU_LABEL_RE.match(linha_limpa)
            if m_cfgmenu:
                registrar(numero_linha, m_cfgmenu.start(1), m_cfgmenu.end(1), m_cfgmenu.group(1), 'ui', 100, 'rótulo visível de config.game_menu')

        # Regra global: fragmentos fixos em rótulos dinâmicos de botões.
        # Ex.: button_list.append((("edit child: {}").format(value), ...)).
        # O texto do template é exibido como botão; o argumento de format permanece intacto.
        if re.search(r'\bbutton_list\s*\.\s*append\s*\(', linha_limpa, re.I):
            m_btn_template = re.search(r'(' + QSTR_LOCAL + r')\s*\.\s*format\s*\(', linha_limpa)
            if m_btn_template:
                q_btn = m_btn_template.group(1)
                try:
                    v_btn = decodificar_literal_traducao(q_btn)
                except Exception:
                    v_btn = strip_quotes(q_btn)
                if tem_conteudo_traduzivel(q_btn) and re.search(r'[A-Za-zÀ-ÖØ-öø-ÿ]{2}', re.sub(r'\{[^{}]*\}', ' ', v_btn)):
                    registrar(numero_linha, m_btn_template.start(1), m_btn_template.end(1), q_btn,
                              'ui', 98, 'modelo textual de botão dinâmico')

        # Regra global: fragmento textual concatenado em mensagem/notificação visível.
        # Captura somente literais ligados por + dentro de notify/error, sem traduzir
        # a variável ou a expressão que produz o valor dinâmico.
        m_notify = re.search(r'\b(?:renpy\.)?(?:notify|error)\s*\(', linha_limpa, re.I)
        if m_notify:
            trecho_notify = linha_limpa[m_notify.start():]
            for m_notify_piece in re.finditer(r'\+\s*(' + QSTR_LOCAL + r')', trecho_notify):
                q_notify = m_notify_piece.group(1)
                if tem_conteudo_traduzivel(q_notify):
                    ini_notify = m_notify.start() + m_notify_piece.start(1)
                    fim_notify = m_notify.start() + m_notify_piece.end(1)
                    registrar(numero_linha, ini_notify, fim_notify, q_notify, 'ui', 96,
                              'fragmento textual de notificação dinâmica')

        # Regra global: rótulo humano em tupla de grupo/opções, seguido por uma
        # tupla de identificadores técnicos. Esses rótulos costumam alimentar menus
        # e botões a partir de dados de configuração, sem aparecer em `textbutton`.
        m_group_label = re.match(r'^\s*\(\s*(' + QSTR_LOCAL + r')\s*,\s*\(\s*([\"\'][A-Za-z_][A-Za-z0-9_]*[\"\'])\s*,', linha_limpa)
        if m_group_label:
            q_group = m_group_label.group(1)
            try:
                v_group = decodificar_literal_traducao(q_group)
            except Exception:
                v_group = strip_quotes(q_group)
            if re.search(r'[A-Za-zÀ-ÖØ-öø-ÿ]', v_group) and (re.search(r'\s|[/&-]', v_group)) and tem_conteudo_traduzivel(q_group):
                registrar(numero_linha, m_group_label.start(1), m_group_label.end(1), q_group,
                          'ui', 94, 'rótulo de grupo de opções usado pela interface')

        m_layout_visible = LAYOUT_VISIBLE_ASSIGN_RE.match(linha_limpa)
        if m_layout_visible:
            registrar(numero_linha, m_layout_visible.start(1), m_layout_visible.end(1), m_layout_visible.group(1), 'ui', 100, "mensagem visível do layout Ren'Py")
        # Oráculo semântico nativo: adiciona somente um literal que o próprio
        # Ren'Py confirmou como diálogo/string e que foi localizado unicamente
        # na mesma linha. Duplicatas ficam com o detector existente.
        caminho_norm = caminho.replace('\\', '/').lower()
        oracle_file = {}
        if oracle_por_arquivo:
            rel_oracle = os.path.relpath(caminho, ORACULO_RENPY.get('game_root') or os.path.dirname(caminho)).replace('\\', '/').lower()
            oracle_file = oracle_por_arquivo.get(rel_oracle, {})
            if not oracle_file and rel_oracle.startswith('game/'):
                oracle_file = oracle_por_arquivo.get(rel_oracle[5:], {})
            if not oracle_file:
                base_nome = os.path.basename(caminho_norm)
                oracle_file = oracle_por_arquivo.get(base_nome, {})

        # Palavras do banco do minijogo de poemas. Embora a declaracao esteja
        # dentro de Python, o valor de add_word() acaba sendo usado diretamente
        # como wordString e exibido em textbutton. Cada palavra e uma entrada
        # independente no mapa, sem deduplicacao por texto.
        caminho_norm = caminho.replace('\\', '/').lower()
        if caminho_norm.endswith('/poem_game/py/poemwords.rpy'):
            m_word = re.search(r'\bpoem_word_db\s*\.\s*add_word\s*\(\s*(' + QSTR_LOCAL + r')', linha_limpa, re.I)
            if m_word:
                registrar(numero_linha, m_word.start(1), m_word.end(1), m_word.group(1),
                          'poema_palavra', 100, 'palavra exibida como botão do minijogo de poemas')

        # Template moderno 5.x: poemwords_ren.py pode usar estruturas Python
        # diferentes; aproveitamos chamadas add_word/PoemWord e mantemos o
        # restante do código fora da tradução.
        if 'poemwords' in os.path.basename(caminho_norm).lower():
            for m_word_mod in re.finditer(r'\b(?:add_word|PoemWord)\s*\(\s*(' + QSTR_LOCAL + r')', linha_limpa, re.I):
                qword = m_word_mod.group(1)
                if tem_conteudo_traduzivel(qword) and not parece_texto_tecnico(qword):
                    registrar(numero_linha, m_word_mod.start(1), m_word_mod.end(1), qword,
                              'poema_palavra', 100, 'palavra do banco moderno poemwords_ren')

        # Reconciliação do oráculo: só agora, depois das especializações de
        # poema, adicionamos evidências semânticas ainda não cobertas pelo scanner.
        _ad, _dup, _amb = _injetar_entradas_oraculo_na_linha(
            numero_linha, linha_sem_fim, os.path.basename(caminho_norm), oracle_file,
            registros, prefixo_ws, ocupados)
        ORACULO_RENPY["nativas_mapeadas"] += _ad
        ORACULO_RENPY["nativas_duplicadas"] += _dup
        ORACULO_RENPY["nativas_ambiguas"] += _amb

        # No modo de poema corrompido, "Monika" vira a base dos caracteres
        # dos botoes. Ha duas ocorrencias independentes no arquivo.
        if caminho_norm.endswith('/poem_game/script-poemgame.rpy'):
            m_glitch_word = re.search(r'\blist\s*\(\s*(' + QSTR_LOCAL + r')\s*\)', linha_limpa)
            if m_glitch_word and strip_quotes(m_glitch_word.group(1)) == 'Monika':
                registrar(numero_linha, m_glitch_word.start(1), m_glitch_word.end(1), m_glitch_word.group(1),
                          'poema_palavra', 100, 'palavra-base do modo de poema corrompido')

        for entrada_poema in poemas_por_linha.get(numero_linha, []):
            base_coluna = len(prefixo_ws)
            inicio_poema = entrada_poema['coluna_inicio'] - base_coluna
            fim_poema = entrada_poema['coluna_fim'] - base_coluna
            if inicio_poema < 0 or fim_poema <= inicio_poema:
                continue
            registrar(numero_linha, inicio_poema, fim_poema,
                      entrada_poema['trecho'], entrada_poema['tipo'], entrada_poema['confianca'],
                      entrada_poema['contexto'], original_mapa=entrada_poema['original'])

        for entrada_gettext in gettext_por_linha.get(numero_linha, []):
            base_coluna = len(prefixo_ws)
            inicio_g = entrada_gettext['coluna_inicio'] - base_coluna
            fim_g = entrada_gettext['coluna_fim'] - base_coluna
            if inicio_g < 0 or fim_g <= inicio_g:
                continue
            registrar(numero_linha, inicio_g, fim_g,
                      entrada_gettext['trecho'], entrada_gettext['tipo'], entrada_gettext['confianca'],
                      entrada_gettext['contexto'], original_mapa=entrada_gettext['original'])

        for entrada_monologo in monologos_por_linha.get(numero_linha, []):
            base_coluna = len(prefixo_ws)
            inicio_m = entrada_monologo['coluna_inicio'] - base_coluna
            fim_m = entrada_monologo['coluna_fim'] - base_coluna
            if inicio_m < 0 or fim_m <= inicio_m:
                continue
            registrar(numero_linha, inicio_m, fim_m,
                      entrada_monologo['trecho'], entrada_monologo['tipo'], entrada_monologo['confianca'],
                      entrada_monologo['contexto'], original_mapa=entrada_monologo['original'])

        for entrada_multilinha in multilinhas_por_linha.get(numero_linha, []):
            base_coluna = len(prefixo_ws)
            inicio_ml = entrada_multilinha['coluna_inicio'] - base_coluna
            fim_ml = entrada_multilinha['coluna_fim'] - base_coluna
            if inicio_ml < 0 or fim_ml <= inicio_ml:
                continue
            registrar(numero_linha, inicio_ml, fim_ml,
                      entrada_multilinha['trecho'], entrada_multilinha['tipo'], entrada_multilinha['confianca'],
                      entrada_multilinha['contexto'], original_mapa=entrada_multilinha['original'])

        em_bloco_visual_tecnico = numero_linha in linhas_blocos_tecnicos
        em_python = numero_linha in linhas_python
        arquivo_base = os.path.basename(caminho).lower()
        alias_visual_em_definitions = (
            arquivo_base == 'definitions.rpy' and
            re.match(r'^[' + chr(34) + chr(39) + r'][A-Za-z_][A-Za-z0-9_.-]*(?:\s+(?:[0-9]+|[0-9]+[A-Za-z]+|ghost[0-9]+))+[' + chr(34) + chr(39) + r']$', linha_limpa, re.I)
        )
        if alias_visual_em_definitions:
            continue

        # Recuperação semântica de listas/tuplas de créditos. Não abre o filtro
        # para todas as strings do arquivo: exige contexto de créditos + estrutura.
        # O nome da variável é tokenizado para evitar falsos positivos como
        # `steam` -> `team`; metadados dunder (ex.: __author__) não são texto de UI.
        m_credit_head = re.match(r'^(?:(?:define|default)\s+|\$\s*)?[\'\"]?([A-Za-z_][\w.]*)', linha_limpa)
        credit_head = m_credit_head.group(1) if m_credit_head else ''
        credit_tokens = [x for x in re.split(r'[_\W]+', credit_head.lower()) if x]
        tokens_credito = frozenset((
            'credit', 'credits', 'author', 'authors', 'contributor', 'contributors',
            'staff', 'team', 'special', 'thanks'
        ))
        tem_contexto_credito = bool(set(credit_tokens) & set(('credit', 'credits', 'author', 'authors', 'contributor', 'contributors', 'staff', 'team')))
        is_dunder_meta = bool(credit_head.startswith('__') and credit_head.endswith('__'))
        linha_dados_creditos = (
            bool(credit_head) and not is_dunder_meta and tem_contexto_credito
            and len(list(STRING_LITERAL_RE.finditer(linha_limpa))) >= 2
            and bool(re.search(r'[=\[({:]', linha_limpa))
        )
        if linha_dados_creditos and not em_bloco_visual_tecnico:
            for m in STRING_LITERAL_RE.finditer(linha_limpa):
                q = m.group(0)
                if parece_string_semantica(q, caminho, permitir_identificador=True):
                    registrar(numero_linha, m.start(), m.end(), q, 'texto_creditos_dados', 90, 'dado textual de créditos')

        # Algumas mensagens do template_checks.py são retornadas por métodos
        # dentro de blocos Python modernos. Elas continuam sendo texto visível
        # ao usuário, portanto precisam ser recuperadas antes do descarte geral
        # das linhas Python modernas.
        arquivo_especial_pre = arquivo_base in (
            'exceptions.rpy', 'renpy_patches.rpy', 'depreciated.rpy', 'template_checks.rpy', 'template_checks_ren.py'
        )
        if arquivo_especial_pre:
            m_return_pre = PYTHON_RETURN_TEXT_RE.match(linha_limpa)
            if m_return_pre:
                registrar(numero_linha, m_return_pre.start(1), m_return_pre.end(1), m_return_pre.group(1), 'ui', 100, 'mensagem retornada por exceção/template')
            elif linha_limpa.lower().startswith('return ') and ('"' in linha_limpa or "'" in linha_limpa):
                for m in re.finditer(QSTR_LOCAL, linha_limpa):
                    qret = m.group(0)
                    if len(strip_quotes(qret).strip()) >= 3:
                        registrar(numero_linha, m.start(0), m.end(0), qret, 'ui', 92, 'fragmento textual de exceção/template')
        # Recupera literais de texto em continuações de concatenação dos
        # validadores do template. Ex.: + ".rpa' was not found...".
        # O filtro semântico continua bloqueando caminhos, comandos, hashes e
        # outros dados técnicos; a regra só é aplicada aos arquivos especiais.
        if arquivo_especial_pre and linha_limpa.startswith('+'):
            for m_concat in re.finditer(QSTR_LOCAL, linha_limpa):
                q_concat = m_concat.group(0)
                if (parece_string_semantica(q_concat, caminho) and
                        tem_conteudo_traduzivel(q_concat)):
                    registrar(numero_linha, m_concat.start(0), m_concat.end(0), q_concat,
                              'ui', 95, 'fragmento textual em concatenação de mensagem')

        if not linhas_ativas[idx] and eh_renpy_moderno(caminho):
            for rx, tipo, contexto in (
                    (UI_RES, 'ui', 'texto traduzível em Python'),
                    (VISIBLE_CALL_RE, 'ui', 'texto visível via API Ren\'Py'),
                    (TEXT_CALL_RE, 'ui', 'Text() / texto de display')):
                for m in rx.finditer(linha_limpa):
                    registrar(numero_linha, m.start(1), m.end(1), m.group(1), tipo, 100, contexto)
            for inicio_dyn, fim_dyn, q_dyn in extrair_fragmentos_text_call_dinamico(linha_limpa, caminho):
                registrar(numero_linha, inicio_dyn, fim_dyn, q_dyn, 'ui', 99, 'fragmento textual dinâmico em Text()')
            for item in registros:
                inicio, fim, tipo, conf, ctx, texto, original_mapa = item
                inicio_real = len(prefixo_ws) + inicio
                fim_real = len(prefixo_ws) + fim
                esperado = original_mapa if original_mapa is not None else texto
                if linha_sem_fim[inicio_real:fim_real] == esperado:
                    textos.append((ctx, texto)); mapa.append({"linha": numero_linha, "coluna_inicio": inicio_real, "coluna_fim": fim_real, "original": esperado, "tipo": tipo, "confianca": conf, "contexto": ctx})
            continue

        # Mesmo dentro de blocos visuais, preserve texto que sabemos que é desenhado.
        if em_bloco_visual_tecnico:
            for rx, tipo, contexto in (
                    (UI_RES, 'ui', 'wrapper em bloco visual'),
                    (TEXT_CALL_RE, 'ui', 'Text() dentro de bloco visual'),
                    (VISIBLE_CALL_RE, 'ui', 'API visível dentro de bloco visual'),
                    (SHOW_DISPLAY_TEXT_RE, 'ui', 'texto exibido via show/displayable')):
                for m in rx.finditer(linha_limpa):
                    registrar(numero_linha, m.start(1), m.end(1), m.group(1), tipo, 100, contexto)
            # Não usar fallback indiscriminado neste bloco.
            pass
        else:
            # Definições de personagem, inclusive multilinha.
            for entrada_def in definicoes_por_linha.get(numero_linha, []):
                inicio_real = entrada_def["coluna_inicio"]
                fim_real = entrada_def["coluna_fim"]
                if inicio_real >= len(prefixo_ws):
                    inicio_limpo = inicio_real - len(prefixo_ws); fim_limpo = fim_real - len(prefixo_ws)
                    q = linha_limpa[inicio_limpo:fim_limpo]
                    if q == entrada_def["original"]:
                        registrar(numero_linha, inicio_limpo, fim_limpo, q, entrada_def["tipo"], entrada_def["confianca"], entrada_def["contexto"])

            for m in UI_RES.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 100, 'string traduzível / wrapper Ren\'Py')

            m_dollar = DOLLAR_ASSIGN_RE.match(linha_limpa)
            if m_dollar and m_dollar.group(1) in variaveis_nome_dinamico:
                q = m_dollar.group(2)
                registrar(numero_linha, m_dollar.start(2), m_dollar.end(2), q, 'nome_personagem', 100, u'nome dinâmico: ' + m_dollar.group(1))

            m_default = STRING_DEFAULT_RE.match(linha_limpa)
            if m_default and m_default.group(1) in variaveis_nome_dinamico:
                q = m_default.group(2)
                registrar(numero_linha, m_default.start(2), m_default.end(2), q, 'nome_personagem', 100, u'nome dinâmico: ' + m_default.group(1))

            if m_default:
                var_nome = m_default.group(1)
                q = m_default.group(2)
                if not parece_texto_tecnico(q, var_nome=var_nome, indice_arquivos=indice_arquivos) and not variavel_eh_tecnica(var_nome, q, vocabulario):
                    registrar(numero_linha, m_default.start(2), m_default.end(2), q, 'variavel_texto', 90, u'default/define com texto: ' + var_nome)

            # Recupera atribuicoes textuais sem exigir define/default.
            m_dynamic_text = DYNAMIC_VISIBLE_TEXT_ASSIGN_RE.match(linha_limpa)
            if m_dynamic_text:
                registrar(numero_linha, m_dynamic_text.start(2), m_dynamic_text.end(2), m_dynamic_text.group(2), 'ui', 100, 'texto visível atribuído a menutext')

            m_text_assign = TEXTUAL_ASSIGN_RE.match(linha_limpa)
            if m_text_assign:
                var_nome = m_text_assign.group(1)
                q = m_text_assign.group(2)
                if not parece_texto_tecnico(q, var_nome=var_nome, indice_arquivos=indice_arquivos) and not variavel_eh_tecnica(var_nome, q, vocabulario):
                    registrar(numero_linha, m_text_assign.start(2), m_text_assign.end(2), q, 'variavel_texto', 92, u'variável textual: ' + var_nome)

            # Chamadas de texto/UI.
            for m in VISIBLE_CALL_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 100, 'texto visível via API Ren\'Py')
            for m in TEXT_CALL_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 95, 'Text() / texto de display')
            for inicio_dyn, fim_dyn, q_dyn in extrair_fragmentos_text_call_dinamico(linha_limpa, caminho):
                registrar(numero_linha, inicio_dyn, fim_dyn, q_dyn, 'ui', 99, 'fragmento textual dinâmico em Text()')
            for m in SHOW_DISPLAY_TEXT_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 98, 'texto exibido via show/displayable')
            for m in UPDATECONSOLE_MESSAGE_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 96, 'mensagem visível do console')
            for m in UPDATECONSOLE_BROAD_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 96, 'mensagem visível do console')
            for m in DIALOG_CALL_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 100, 'mensagem visível em dialog/show_dialog')
            for m in CALL_SCREEN_DIALOG_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 100, 'mensagem visível em call/show screen dialog')
            for m in RENPY_CALL_SCREEN_DIALOG_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 100, 'mensagem visível via renpy.call_screen/show_screen dialog')

            for m in SHOW_MESSAGE_KWARG_RE.finditer(linha_limpa):
                registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 100, 'mensagem visível em Show/show message=')

            # Retornos Python de mensagens: primeiro a forma exata, depois cada
            # fragmento textual de um return concatenado (exceptions.rpy).
            arquivo_especial = os.path.basename(caminho).lower() in ("exceptions.rpy", "renpy_patches.rpy", "depreciated.rpy", "template_checks_ren.py", "poems.rpy")
            if arquivo_especial:
                # poems.rpy possui uma mensagem deprecada montada por concatenação.
                # Extraímos apenas os fragmentos de linguagem natural; o comando
                # antigo ($ poem_db.show_poem(...)) permanece bloqueado.
                if arquivo_base == 'poems.rpy' and 'depreciated' in linha_limpa.lower() and 'poem_db.show_poem' in linha_limpa:
                    for m_dep in re.finditer(QSTR_LOCAL, linha_limpa):
                        qdep = m_dep.group(0)
                        interior_dep = strip_quotes(qdep)
                        if not interior_dep.strip() or 'poem_db.show_poem' in interior_dep:
                            continue
                        if interior_dep.lstrip().startswith('$'):
                            continue
                        if re.fullmatch(r'(?:%[A-Za-z0-9]+|[=,;: ])+', interior_dep):
                            continue
                        if parece_texto_tecnico(qdep, indice_arquivos=indice_arquivos):
                            continue
                        if tem_conteudo_traduzivel(qdep):
                            registrar(numero_linha, m_dep.start(0), m_dep.end(0), qdep, 'ui', 95, 'fragmento textual da mensagem deprecada')

                m_return = PYTHON_RETURN_TEXT_RE.match(linha_limpa)
                if m_return:
                    registrar(numero_linha, m_return.start(1), m_return.end(1), m_return.group(1), 'ui', 100, 'mensagem retornada por exceção')
                elif linha_limpa.lower().startswith('return ') and ('"' in linha_limpa or "'" in linha_limpa):
                    for m in re.finditer(QSTR_LOCAL, linha_limpa):
                        qret = m.group(0)
                        if len(strip_quotes(qret).strip()) >= 3:
                            registrar(numero_linha, m.start(0), m.end(0), qret, 'ui', 92, 'fragmento textual de exceção')

            primeiro_m_kw = re.match(r'^([A-Za-z_][\w.]*)', linha_limpa)
            primeiro_low_kw = primeiro_m_kw.group(1).lower() if primeiro_m_kw else ''
            for m in VISIBLE_KWARG_RE.finditer(linha_limpa):
                if primeiro_low_kw.startswith('build.'):
                    continue
                if (primeiro_low_kw not in BIBLIOTECA_RENPY.get('tokens_nao_dialogo', set())
                        or 'dialog(' in linha_limpa.lower()
                        or 'screen dialog' in linha_limpa.lower()
                        or linha_limpa.lower().startswith(('call screen dialog', 'show screen dialog'))
                        or DIALOG_SHOW_OBJECT_RE.search(linha_limpa)):
                    registrar(numero_linha, m.start(1), m.end(1), m.group(1), 'ui', 92, 'texto visível em argumento nomeado')

            for m_ui_display in UI_DISPLAY_ARG_RE.finditer(linha_limpa):
                q_ui = m_ui_display.group(1)
                # Evita capturar strings técnicas após nomes de propriedades; a regra
                # só aceita um literal imediatamente associado ao displayable.
                if tem_conteudo_traduzivel(q_ui) and not parece_texto_tecnico(q_ui, indice_arquivos=indice_arquivos):
                    try:
                        q_ui_valor = decodificar_literal_traducao(q_ui)
                    except Exception:
                        q_ui_valor = strip_quotes(q_ui)
                    tipo_ui = 'texto_creditos_bloco' if parece_bloco_creditos_google(q_ui_valor, caminho, 'ui') else 'ui'
                    contexto_ui = 'bloco de créditos em displayable Ren\'Py' if tipo_ui == 'texto_creditos_bloco' else 'texto visível em displayable Ren\'Py'
                    registrar(numero_linha, m_ui_display.start(1), m_ui_display.end(1), q_ui, tipo_ui, 110 if tipo_ui == 'texto_creditos_bloco' else 99, contexto_ui)

            if re.match(r'^screen\b.*:', linha_limpa):
                screen_indent = nivel_indent
            elif screen_indent is not None and nivel_indent <= screen_indent and not re.match(r'^screen\b', linha_limpa):
                screen_indent = None
            if screen_indent is not None:
                for m in SCREEN_TEXT_RE.finditer(linha_limpa):
                    q_screen_credito = m.group(1)
                    try:
                        q_screen_valor = decodificar_literal_traducao(q_screen_credito)
                    except Exception:
                        q_screen_valor = strip_quotes(q_screen_credito)
                    tipo_screen = 'texto_creditos_bloco' if parece_bloco_creditos_google(q_screen_valor, caminho, 'ui') else 'ui'
                    contexto_screen = 'bloco de créditos em screen' if tipo_screen == 'texto_creditos_bloco' else 'texto de screen'
                    registrar(numero_linha, m.start(1), m.end(1), q_screen_credito, tipo_screen, 110 if tipo_screen == 'texto_creditos_bloco' else 98, contexto_screen)
                # Uma linha `text` pode continuar com outras strings após um
                # `+` ou outra expressão Python. Capture cada literal adicional
                # para não deixar a segunda metade de um texto visível para trás.
                # Recupera fragmentos de linguagem natural em expressões dinâmicas
                # como `textbutton indent*2 + "- " + "camera"` ou
                # `textbutton indent*4 + "  with [value[1]]"`. Só lemos a expressão
                # de texto e paramos antes das propriedades/ações do displayable.
                # Literais compostos apenas por placeholders/valores dinâmicos não
                # entram, pois não contêm texto estático para traduzir.
                m_screen_expr = re.match(r'^(?:textbutton|text)\s+', linha_limpa, re.I)
                if m_screen_expr:
                    inicio_expr = m_screen_expr.end()
                    fim_expr = fim_expressao_texto_screen(linha_limpa, inicio_expr)
                    expr_texto = linha_limpa[inicio_expr:fim_expr]
                    for m_expr_lit in re.finditer(QSTR_LOCAL, expr_texto):
                        q_expr = m_expr_lit.group(0)
                        try:
                            valor_expr = decodificar_literal_traducao(q_expr)
                        except Exception:
                            valor_expr = strip_quotes(q_expr)
                        # Remova interpolação Ren'Py e placeholders de formatação
                        # antes de confirmar se o literal possui palavras estáticas.
                        estatico_expr = re.sub(r'\[[^\]]*\]', ' ', valor_expr)
                        estatico_expr = re.sub(r'\{[^{}]*\}', ' ', estatico_expr)
                        letras_expr = re.findall(r'[A-Za-zÀ-ÖØ-öø-ÿ]', estatico_expr)
                        if len(letras_expr) < 2:
                            continue
                        if not tem_conteudo_traduzivel(q_expr):
                            continue
                        inicio_piece = inicio_expr + m_expr_lit.start(0)
                        fim_piece = inicio_expr + m_expr_lit.end(0)
                        registrar(numero_linha, inicio_piece, fim_piece, q_expr, 'ui', 98,
                                  'fragmento textual estático em expressão de text/textbutton')

            # Menu pode aparecer dentro de outro menu. A variável única da versão
            # anterior perdia o menu-pai quando o submenu terminava. A pilha preserva
            # todos os níveis válidos segundo a indentação lógica do Ren'Py.
            if re.match(r'^menu\b.*:', linha_limpa, re.I):
                while menu_stack and nivel_indent <= menu_stack[-1]:
                    menu_stack.pop()
                menu_stack.append(nivel_indent)
            else:
                while menu_stack and nivel_indent <= menu_stack[-1]:
                    menu_stack.pop()
            if menu_stack:
                m_menu = MENU_OPTION_RE.match(linha_limpa)
                if m_menu:
                    q_menu = m_menu.group(1)
                    if tem_conteudo_traduzivel(q_menu) and not parece_texto_tecnico(q_menu, indice_arquivos=indice_arquivos):
                        registrar(numero_linha, m_menu.start(1), m_menu.end(1), q_menu, 'ui', 98, 'opção textual de menu Ren\'Py')

            if not em_python:
                m_lbl = re.match(r'^label\s+(' + QSTR_LOCAL + r')', linha_limpa)
                if m_lbl:
                    registrar(numero_linha, m_lbl.start(1), m_lbl.end(1), m_lbl.group(1), 'ui', 96, 'texto de label (tela/telefone)')

            m_var = VISIVEL_ASSIGN_RE.match(linha_limpa)
            if m_var:
                registrar(numero_linha, m_var.start(2), m_var.end(2), m_var.group(2), 'ui', 100, 'variável visível: ' + m_var.group(1))

            if numero_linha not in linhas_em_definicao_personagem:
                m_char = CHAR_DEF_LINE_RE.match(linha_limpa)
                if m_char:
                    kind = m_char.group(2); chamada = linha_limpa[m_char.end():]
                    display_name, dynamic_var, pos_nome = extrair_info_nome_personagem(chamada, kind)
                    if display_name is not None and pos_nome >= 0:
                        mq = re.match(QSTR_LOCAL, chamada[pos_nome:])
                        if mq:
                            q = mq.group(0); pos = m_char.end() + pos_nome
                            registrar(numero_linha, pos, pos + len(q), q, 'nome_personagem', 100, 'definição de personagem')

            m_exp = EXPLICIT_SAY_RE.match(linha_limpa)
            if m_exp and not em_python and not linha_limpa.lower().startswith(('label ', 'image ', 'scene ', 'show ', 'play ', 'voice ')):
                q1, q2 = m_exp.group(1), m_exp.group(2)
                # "m" "Olá!": se "m" é o nome de uma variável de personagem do jogo, é chave, não nome.
                if not (vocabulario and strip_quotes(q1) in vocabulario.get('personagens', ())):
                    registrar(numero_linha, m_exp.start(1), m_exp.end(1), q1, 'nome_personagem', 100, 'nome explícito de fala')
                registrar(numero_linha, m_exp.start(2), m_exp.end(2), q2, 'dialogo', 100, 'fala explícita')

            primeiro_m = re.match(r'^([A-Za-z_][\w.]*)', linha_limpa)
            eh_reservada = bool(primeiro_m) and primeiro_m.group(1).lower() in BIBLIOTECA_RENPY.get('tokens_nao_dialogo', set())
            if not eh_reservada and numero_linha not in linhas_em_definicao_personagem:
                m = LEGACY_DIALOGO.match(linha_limpa)
                if m and not re.match(r'\s*:\s*[^\s#]', linha_limpa[m.end(1):]):
                    # Fala pode ser escrita como várias strings adjacentes na
                    # mesma linha (concatenação implícita):  m "parte 1 " "parte 2".
                    # Registra TODAS as strings do bloco final contíguo, senão as
                    # primeiras partes ficariam sem tradução.
                    todas = [x for x in re.finditer(QSTR_LOCAL, linha_limpa) if x.end() <= m.end(1)]
                    bloco = []
                    for x in reversed(todas):
                        if bloco and linha_limpa[x.end():bloco[-1].start()].strip() != '':
                            break
                        bloco.append(x)
                    bloco.reverse()
                    for x in bloco:
                        prefixo_txt = linha_limpa[:x.start()].strip()
                        palavras_prefixo = re.findall(r'[\w.]+', prefixo_txt)
                        # "m" "Olá!": a primeira string é a chave do personagem, não texto.
                        if (len(bloco) >= 2 and x is bloco[0] and vocabulario
                                and strip_quotes(x.group(0)) in vocabulario.get('personagens', ())):
                            continue
                        if em_python and (prefixo_txt or not parece_frase(x.group(0))):
                            continue
                        if parece_codigo_na_linha(linha_limpa, x.start(), x.end()):
                            continue
                        # Regra global: uma string isolada de nível 0 é narrativa Ren'Py válida.
                        # Ela deve ser extraída mesmo sem nome de personagem ou prefixo.
                        # O filtro parece_codigo_na_linha e as regras semânticas acima
                        # continuam impedindo literais que sejam código/estrutura técnica.
                        if (palavras_prefixo and palavras_prefixo[-1] in PROPRIEDADES_NAO_TEXTO
                                and palavras_prefixo[0] in (PROPRIEDADES_NAO_TEXTO | ELEMENTOS_DE_TELA | frozenset(['has']))):
                            continue
                        if (palavras_prefixo and palavras_prefixo[-1] in ELEMENTOS_CONTAINER
                                and palavras_prefixo[0] in (PROPRIEDADES_NAO_TEXTO | ELEMENTOS_DE_TELA | frozenset(['has']))):
                            continue
                        if len(palavras_prefixo) >= 2 and palavras_prefixo[-1] == 'key':
                            continue
                        if len(palavras_prefixo) >= 2 and palavras_prefixo[0] == 'phone' and palavras_prefixo[1] in ('call', 'hangup', 'discussion'):
                            continue
                        if palavras_prefixo and palavras_prefixo[0] in ELEMENTOS_DE_TELA and not tem_conteudo_traduzivel(x.group(0)):
                            continue
                        registrar(numero_linha, x.start(), x.end(), x.group(0),
                                  'dialogo' if prefixo_txt else 'narrativa', 95,
                                  prefixo_txt or 'narrativa / string isolada')

        # Cobertura adicional para strings diretas Ren'Py fora do QSTR legado.
        # Só consideramos r"..."/r\'...\'/r`...` e `...`, evitando abrir o scanner
        # genérico para todas as strings normais e, assim, reduzindo falsos positivos.
        if not em_python:
            contexto_especial = (
                bool(re.match(r'^(?:_|__|___|_p)\s*\(', linha_limpa, re.I)) or
                bool(re.match(r'^(?:text|textbutton|button|label|prompt|tooltip|confirm|caption)\b', linha_limpa, re.I)) or
                bool(re.match(r'^menu\b', linha_limpa, re.I)) or
                bool(screen_indent is not None) or
                bool(menu_stack) or
                bool(re.match(r'^r?["\'`]', linha_limpa, re.I)) or
                bool(re.match(r'^[A-Za-z_][\w.]*\s+(?:r)?["\'`]', linha_limpa, re.I)) or
                bool(re.search(r'\b(?:Text|ParameterizedText|renpy\.(?:say|notify|input)|Notify|Confirm|InputValue)\s*\(.*(?:r)?["\'`]', linha_limpa, re.I))
            )
            if contexto_especial:
                for inicio_especial, fim_especial, q_especial, raw_especial in iter_renpy_literais_especiais(linha_limpa):
                    if not tem_conteudo_traduzivel(q_especial):
                        continue
                    if parece_codigo_na_linha(linha_limpa, inicio_especial, fim_especial):
                        continue
                    prefixo_especial = linha_limpa[:inicio_especial].strip()
                    sufixo_especial = linha_limpa[fim_especial:].strip()
                    semantica_ok = parece_string_semantica(q_especial, caminho)
                    # Raw/backtick de uma única palavra pode ser texto válido.
                    # Quando o literal é o item de uma opção de menu, ou quando
                    # está sozinho como narrativa, o contexto sintático resolve a
                    # ambiguidade que o filtro de identificadores teria criado.
                    contexto_visivel_especial = (
                        (bool(menu_stack) and sufixo_especial.startswith(':')) or
                        (not prefixo_especial and not sufixo_especial and
                         bool(re.match(r'^r?["\'`]', linha_limpa, re.I)))
                    )
                    if not semantica_ok and not contexto_visivel_especial:
                        continue
                    tipo_especial = 'ui'
                    if prefixo_especial and re.match(r'^[A-Za-z_][\w.]*$', prefixo_especial.split()[-1]):
                        candidato_personagem = prefixo_especial.split()[-1]
                        if vocabulario and candidato_personagem in vocabulario.get('personagens', ()):
                            tipo_especial = 'dialogo'
                    elif re.match(r'^r?["\'`]', linha_limpa, re.I):
                        tipo_especial = 'narrativa'
                    registrar(numero_linha, inicio_especial, fim_especial, q_especial, tipo_especial, 98,
                              'string Ren\'Py especial (raw/backtick)')

        if numero_linha in linhas_monologo:
            especiais = [r for r in registros if r[2] in ('gettext_multilinha', 'poema_corpo')]
            registros = especiais or [r for r in registros if r[2] == 'monologo_triplas']

        # Materialização/deduplicação. Primeiro resolve sobreposições físicas
        # entre detectores diferentes; depois elimina somente duplicatas exatas.
        registros, _conflitos_sobreposicao = _resolver_sobreposicoes_registros(registros)
        vistos = set()
        for inicio_limpo, fim_limpo, tipo, conf, ctx, trecho, original_mapa in registros:
            chave = (inicio_limpo, fim_limpo)
            if chave in vistos:
                continue
            vistos.add(chave)
            inicio = len(prefixo_ws) + inicio_limpo
            fim = len(prefixo_ws) + fim_limpo
            esperado = original_mapa if original_mapa is not None else trecho
            if linha_sem_fim[inicio:fim] != esperado:
                continue
            textos.append((ctx, trecho))
            mapa.append({"linha": numero_linha, "coluna_inicio": inicio, "coluna_fim": fim, "original": (original_mapa if original_mapa is not None else trecho), "tipo": tipo, "confianca": conf, "contexto": ctx})

    return textos, mapa

PASTAS_SEM_TEXTO = (u"images", u"image", u"imagens")

def em_pasta_sem_texto(caminho, pasta_game):
    # Arquivos dentro da pasta de imagens (ex.: images/MPT) são scripts de
    # ferramenta/imagem: não têm texto que o jogador veja, então não são extraídos.
    try:
        rel = os.path.relpath(caminho, pasta_game)
    except ValueError:
        return False
    partes = [p.lower() for p in rel.replace('\\', '/').split('/')[:-1]]
    return any(p in PASTAS_SEM_TEXTO for p in partes)



# -----------------------------------------------------------------------------
# Oráculo semântico Ren'Py: descoberta do SDK, execução segura e reconciliação.
# -----------------------------------------------------------------------------
def _normalizar_rel_renpy(valor):
    valor = (valor or u"").replace("\\", "/").strip()
    while valor.startswith("./"):
        valor = valor[2:]
    if valor.lower().startswith("game/"):
        valor = valor[5:]
    return valor.replace("//", "/")


def _versao_numerica(valor):
    nums = re.findall(r"\d+", valor or u"")
    try:
        return tuple(int(x) for x in nums[:4])
    except Exception:
        return tuple()


def _raizes_candidatas_sdk_renpy(raiz):
    """Localiza SDKs Ren'Py completos, com caminho explícito preferencial e fallback seguro.

    A nova raiz oficial do cache é %LOCALAPPDATA%\\DDAC. Os caches DDAC-SDK e
    DDAC-SDK-Mobile continuam sendo lidos somente para compatibilidade retroativa.
    DDAC_RENPY_SDK nunca bloqueia a descoberta se estiver incompleto.
    """
    candidatas=[]
    def add(p):
        if not p: return
        p=os.path.abspath(os.path.expandvars(os.path.expanduser(p)))
        if os.path.isdir(p) and p not in candidatas: candidatas.append(p)
    for env_nome in ("DDAC_RENPY_SDK","RENPY_SDK"): add(os.environ.get(env_nome,""))
    local=os.environ.get("LOCALAPPDATA",""); user=os.environ.get("USERPROFILE","")
    programdata=os.environ.get("PROGRAMDATA",""); programfiles=os.environ.get("PROGRAMFILES",""); programfiles_x86=os.environ.get("PROGRAMFILES(X86)","")
    bases=[os.path.join(local,"DDAC"),raiz,os.path.dirname(raiz),os.path.join(local,"DDAC-SDK"),os.path.join(local,"DDAC-SDK-Mobile"),os.path.join(local,"DDAC-SDK-Port"),os.path.join(local,"RenPy"),os.path.join(user,"RenPy"),os.path.join(user,"renpy"),os.path.join(programdata,"RenPy"),os.path.join(programfiles,"RenPy"),os.path.join(programfiles_x86,"RenPy")]
    for base in bases: add(base)
    visitados=set(); fila=[(p,0) for p in list(candidatas)]
    while fila:
        atual,nivel=fila.pop(0); chave=os.path.normcase(os.path.normpath(atual))
        if chave in visitados: continue
        visitados.add(chave)
        if os.path.isfile(os.path.join(atual,"renpy.py")): add(atual); continue
        if nivel>=5: continue
        try: nomes=os.listdir(atual)
        except Exception: continue
        for nome in nomes:
            low=nome.lower()
            if low in ("cache","__pycache__",".git","temp","tmp"): continue
            p2=os.path.join(atual,nome)
            if os.path.isdir(p2) and (nivel==0 or any(k in low for k in ("renpy","ddac","sdk","6.","7.","8."))): fila.append((p2,nivel+1))
    return [p for p in candidatas if os.path.isfile(os.path.join(p,"renpy.py"))]

def _listar_pythons_sdk(sdk):
    """Lista todos os Python embutidos plausíveis, tolerando layouts antigos/novos."""
    encontrados=[]; vistos=set()
    preferidos=(
        os.path.join(sdk,"lib","py3-windows-x86_64","python.exe"),
        os.path.join(sdk,"lib","py3-windows-i686","python.exe"),
        os.path.join(sdk,"lib","py2-windows-x86_64","python.exe"),
        os.path.join(sdk,"lib","py2-windows-i686","python.exe"),
        os.path.join(sdk,"lib","windows-x86_64","python.exe"),
        os.path.join(sdk,"lib","windows-i686","python.exe"),
        os.path.join(sdk,"lib","python.exe"),
        os.path.join(sdk,"python.exe"),
    )
    def add(p):
        if not p or not os.path.isfile(p): return
        chave=os.path.normcase(os.path.abspath(p))
        if chave in vistos: return
        vistos.add(chave); encontrados.append(os.path.abspath(p))
    for p in preferidos: add(p)
    try:
        lib_root=os.path.join(sdk,"lib")
        for root,dirs,files in os.walk(lib_root):
            rel=os.path.relpath(root,lib_root)
            profundidade=0 if rel=="." else rel.count(os.sep)+1
            if profundidade>4:
                dirs[:]=[]; continue
            dirs[:]=[d for d in dirs if d.lower() not in ("cache","__pycache__")]
            if "python.exe" in files: add(os.path.join(root,"python.exe"))
    except Exception:
        pass
    return encontrados


def _localizar_python_sdk(sdk):
    """Escolhe o Python embutido que realmente consegue iniciar no ambiente do SDK."""
    pythons=_listar_pythons_sdk(sdk)
    if not pythons:
        return None
    primeiro=pythons[0]
    for py in pythons:
        try:
            raiz_python=os.path.dirname(os.path.abspath(py))
            lib_dir=os.path.join(raiz_python,"Lib")
            usa_pyo=(os.path.isfile(os.path.join(lib_dir,"site.pyo")) and
                     not os.path.isfile(os.path.join(lib_dir,"site.py")) and
                     not os.path.isfile(os.path.join(lib_dir,"site.pyc")))
            flags=["-O"] if usa_pyo else []
            env=os.environ.copy()
            env.pop("PYTHONUSERBASE",None)
            env["PYTHONHOME"]=raiz_python
            env["PYTHONPATH"]=lib_dir
            cp=subprocess.run([py]+flags+["-c","import sys,site; print(sys.version_info[0])"],cwd=sdk,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding="utf-8",errors="replace",timeout=20)
            if cp.returncode==0 and (cp.stdout or "").strip().splitlines()[-1:] :
                return py
        except Exception:
            continue
    return primeiro


def _obter_versao_sdk(python_sdk, sdk):
    """Obtém a versão do SDK pelo CLI e, se necessário, pelo código do SDK."""
    if python_sdk:
        try:
            cp=subprocess.run([python_sdk,"renpy.py","--version"],cwd=sdk,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding="utf-8",errors="replace",timeout=45)
            saida=(cp.stdout or u"").strip(); m=re.search(r"Ren.?Py\s+([0-9]+(?:\.[0-9]+){1,4})",saida,re.I)
            if m: return m.group(1)
        except Exception: pass
    for path in (os.path.join(sdk,"renpy","__init__.py"),os.path.join(sdk,"renpy","version.py"),os.path.join(sdk,"renpy","vc_version.py")):
        if not os.path.isfile(path): continue
        try:
            with io.open(path,"r",encoding="utf-8",errors="replace") as f: src=f.read()
            for pat in (r"version_tuple\s*=\s*\(([^)]*)\)",r"__version__\s*=\s*[\"']([^\"']+)",r"version\s*=\s*[\"']([^\"']+)"):
                m=re.search(pat,src,re.I)
                if m:
                    nums=re.findall(r"\d+",m.group(1))
                    if nums: return u".".join(nums[:4])
        except Exception: pass
    return u""


def _versao_por_nome_caminho_sdk(sdk):
    partes=os.path.normpath(sdk).replace("/",os.sep).split(os.sep); achados=[]
    for parte in partes:
        m=re.fullmatch(r"6\.\d+\.\d+(?:\.\d+)?",parte)
        if m: achados.append(m.group(0)); continue
        m=re.search(r"renpy[-_ ]?((?:6\.\d+\.\d+(?:\.\d+)?)|(?:7\.\d+\.\d+)|(?:8\.\d+\.\d+))",parte,re.I)
        if m: achados.append(m.group(1))
    return achados[-1] if achados else u""

def _detectar_versao_projeto_renpy(pasta_game, candidatos):
    """Infere a versão do Ren'Py usando as mesmas fontes fortes da V53 e algumas
    extensões seguras. Nunca trata um nome genérico de pasta como versão exata.

    Ordem de evidência:
      1) game/script_version.txt (metadado oficial de distribuições Ren'Py);
      2) renpy/__init__.py local do projeto (version_tuple/__version__);
      3) renpy/vc_version.py local (Ren'Py 8 e builds modernas);
      4) qualquer .rpy/.rpym/.py do projeto com comparação explícita de
         renpy.version_tuple;
      5) cache DDAC-SDK local ao projeto, somente quando existe uma única
         versão inequívoca.
    """
    evidencias = []
    raiz_projeto = os.path.dirname(os.path.abspath(pasta_game))

    def ler_texto(caminho):
        for enc in ("utf-8-sig", "cp1252", "latin-1"):
            try:
                with io.open(caminho, "r", encoding=enc, errors="replace") as f:
                    return f.read()
            except Exception:
                continue
        return u""

    def adicionar(nums, origem):
        if not nums:
            return
        # SDKs oficiais são endereçados por até 4 componentes; a detecção pode
        # receber um quinto componente de build, mas a preparação reduz para 4.
        nums = tuple(int(x) for x in nums if str(x).strip() != "")
        if nums:
            evidencias.append((nums[:5], origem))

    # 1) Evidência auxiliar: log.txt, quando existe. Não é obrigatório e não
    # vence metadados de versão encontrados diretamente nos arquivos do projeto.
    # Exemplo observado: Ren'Py 7.5.3.22090809.
    caminhos_log = (
        os.path.join(raiz_projeto, "log.txt"),
        os.path.join(pasta_game, "log.txt"),
    )
    for caminho_log in caminhos_log:
        if not os.path.isfile(caminho_log):
            continue
        dados_log = ler_texto(caminho_log)
        m_log = re.search(r"Ren.?Py\s+([0-9]+(?:\.[0-9]+){2,4})", dados_log, re.I)
        if m_log:
            todos = tuple(int(x) for x in m_log.group(1).split("."))
            if todos[0] == 6 and len(todos) >= 4:
                nums_log = todos[:4]
            else:
                nums_log = todos[:3]
            adicionar(nums_log, caminho_log + " :: Ren'Py do log.txt")

    # 2) Metadado oficial criado pelo processo de distribuição do Ren'Py.
    # O Ren'Py atual grava repr(renpy.version_tuple[:-1]) em script_version.txt.
    # Portanto (7, 4, 11) continua sendo uma evidência forte para o SDK 7.4.11.
    for nome in ("script_version.txt", "script_version.rpy", "script_version.rpyc"):
        caminho_sv = os.path.join(pasta_game, nome)
        if not os.path.isfile(caminho_sv) or not caminho_sv.lower().endswith((".txt", ".rpy")):
            continue
        dados = ler_texto(caminho_sv).strip()
        nums = tuple(int(x) for x in re.findall(r"\d+", dados)[:4])
        if nums:
            adicionar(nums, caminho_sv)
            break

    # 3) Cópia local do motor, exatamente como a V53 faz.
    caminho_init = os.path.join(raiz_projeto, "renpy", "__init__.py")
    if os.path.isfile(caminho_init):
        txt = ler_texto(caminho_init)
        for padrao in (
            r"version_tuple\s*=\s*\(\s*([0-9]+(?:\s*,\s*[0-9]+){1,4})",
            r"version_tuple\s*=\s*\(?([0-9]+(?:\s*,\s*[0-9]+){1,4})\)?",
        ):
            m = re.search(padrao, txt, re.I)
            if m:
                nums = tuple(int(x) for x in re.findall(r"\d+", m.group(1))[:5])
                adicionar(nums, caminho_init + " :: version_tuple")
                break
        if not any(orig == caminho_init + " :: version_tuple" for _, orig in evidencias):
            m = re.search(r"__version__\s*=\s*[\"']([^\"']+)", txt, re.I)
            if m:
                nums = tuple(int(x) for x in re.findall(r"\d+", m.group(1))[:5])
                adicionar(nums, caminho_init + " :: __version__")

    # 4) Ren'Py 8 passou a calcular version_tuple a partir de vc_version.py.
    caminho_vc = os.path.join(raiz_projeto, "renpy", "vc_version.py")
    if os.path.isfile(caminho_vc):
        txt = ler_texto(caminho_vc)
        m = re.search(r"(?m)^\s*version\s*=\s*[\"']?([^\"'\r\n]+)", txt, re.I)
        if m:
            nums = tuple(int(x) for x in re.findall(r"\d+", m.group(1))[:5])
            adicionar(nums, caminho_vc + " :: version")

    # 5) Comparações explícitas de versão podem aparecer em scripts do mod.
    # Não limitamos isso a options/config/definitions: alguns templates colocam
    # a compatibilidade em um arquivo separado.
    for caminho in candidatos:
        if not caminho.lower().endswith((".rpy", ".rpym", ".py")):
            continue
        txt = ler_texto(caminho)
        if not txt:
            continue
        for m in re.finditer(r"renpy\.version_tuple\s*==\s*\(([^)]+)\)", txt, re.I):
            nums = tuple(int(x) for x in re.findall(r"\d+", m.group(1))[:5])
            adicionar(nums, caminho + " :: version_tuple==")
        if re.search(r"Ren.?Py\s*8\s+DDLC\s+Compliant", txt, re.I):
            adicionar((8,), caminho + " :: Ren'Py 8 DDLC Compliant")
        if re.search(r"Ren.?Py\s*7\s+DDLC\s+Compliant", txt, re.I):
            adicionar((7,), caminho + " :: Ren'Py 7 DDLC Compliant")
        if re.search(r"Ren.?Py\s*6\s+DDLC\s+Compliant", txt, re.I):
            adicionar((6,), caminho + " :: Ren'Py 6 DDLC Compliant")

    # Evidências completas (incluindo o log opcional) têm prioridade sobre cache.
    completas = [x for x in evidencias if len(x[0]) >= 3]
    if completas:
        # Evidência de maior especificidade primeiro; em empate, metadados mais
        # confiáveis vêm antes de comentários de compatibilidade.
        def peso(item):
            nums, origem = item
            low = origem.lower()
            forte = 0
            if "script_version.txt" in low:
                forte = 5
            elif "__init__.py" in low and ("version_tuple" in low or "__version__" in low):
                forte = 4
            elif "vc_version.py" in low:
                forte = 4
            elif "version_tuple==" in low:
                forte = 3
            elif "log.txt" in low:
                forte = 1
            return (forte, len(nums))
        completas.sort(key=peso, reverse=True)
        return completas[0][0], completas

    # 6) Igual à estratégia de cache usada pela V53, mas sem escolher
    # arbitrariamente a versão mais alta quando há várias.
    cache_raizes = [
        os.path.join(raiz_projeto, "DDAC-SDK"),
        os.path.join(raiz_projeto, "DDAC-SDK-Mobile"),
    ]
    local = os.environ.get("LOCALAPPDATA", "")
    if local:
        cache_raizes.append(os.path.join(local, "DDAC-SDK"))
        cache_raizes.append(os.path.join(local, "DDAC-SDK-Mobile"))

    cache_versoes = []
    vistos_cache = set()
    for base in cache_raizes:
        if not os.path.isdir(base):
            continue
        try:
            nomes = os.listdir(base)
        except Exception:
            continue
        for nome in nomes:
            if not re.match(r"^\d+(?:\.\d+){1,3}$", nome):
                continue
            caminho_sdk = os.path.join(base, nome)
            if not os.path.isfile(os.path.join(caminho_sdk, "renpy.py")):
                continue
            chave = (os.path.normcase(os.path.abspath(caminho_sdk)), nome)
            if chave in vistos_cache:
                continue
            vistos_cache.add(chave)
            cache_versoes.append((tuple(int(x) for x in nome.split(".")), caminho_sdk + " :: cache"))

    # Uma única versão exata no cache é segura para reutilização. Com duas ou
    # mais versões, a rotina antiga escolheria uma arbitrariamente; aqui não
    # fazemos isso, porque a Opção 1 exige o SDK exato.
    unicas = {}
    for nums, origem in cache_versoes:
        unicas.setdefault(nums, origem)
    if len(unicas) == 1:
        nums, origem = next(iter(unicas.items()))
        return nums, [(nums, origem)]

    # Evidências apenas de família são úteis para diagnóstico, mas não autorizam
    # baixar um SDK exato. Retornamos-nas separadas para o chamador poder registrar
    # o motivo do bloqueio sem fabricar precisão.
    familias = [x for x in evidencias if len(x[0]) < 3]
    if familias:
        familias.sort(key=lambda item: len(item[0]), reverse=True)
        return familias[0][0], familias

    return None, []


def _estimativa_major_renpy(pasta_game, candidatos):
    alvo, _ = _detectar_versao_projeto_renpy(pasta_game, candidatos)
    if alvo:
        return alvo[0]
    nomes = [os.path.basename(x).lower() for x in candidatos]
    if any(x.endswith("_ren.py") for x in nomes):
        return 8
    if any("renpy-8" in x or "renpy8" in x for x in nomes):
        return 8
    if any("renpy-7" in x or "renpy7" in x for x in nomes):
        return 7
    if any("renpy-6" in x or "renpy6" in x for x in nomes):
        return 6
    return None

def _extrair_campo_nativo(valor):
    valor = valor or u""
    try:
        return ast.literal_eval(u'"' + valor + u'"')
    except Exception:
        # Fallback conservador para --escape.
        return (valor.replace(u"\\\\", u"\\")
                    .replace(u"\\t", u"\\t")
                    .replace(u"\\r", u"\\r")
                    .replace(u"\\n", u"\\n")
                    .replace(u'\\"', u'"'))


def _ler_dialogue_tab(caminho):
    entradas = []
    if not os.path.isfile(caminho):
        return entradas
    data = None
    last_error = None
    for enc in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            with io.open(caminho, "r", encoding=enc, errors="replace", newline="") as f:
                data = f.read()
            break
        except Exception as exc:
            last_error = exc
    if data is None:
        return entradas
    leitor = csv.reader(data.splitlines(), delimiter="\t", quotechar='"')
    try:
        cab = next(leitor)
    except StopIteration:
        return entradas
    idx = {str(v).strip().lower(): i for i, v in enumerate(cab)}
    i_file = idx.get("filename", 3)
    i_line = idx.get("line number", 4)
    i_text = idx.get("dialogue", 2)
    i_char = idx.get("character", 1)
    i_id = idx.get("identifier", 0)
    for row in leitor:
        if not row:
            continue
        if max(i_file, i_line, i_text, i_char, i_id) >= len(row):
            continue
        try:
            linha = int(row[i_line])
        except Exception:
            continue
        texto = _extrair_campo_nativo(row[i_text])
        arquivo = _normalizar_rel_renpy(row[i_file])
        if not arquivo or not texto:
            continue
        entradas.append({
            "arquivo": arquivo,
            "linha": linha,
            "texto": texto,
            "personagem": _extrair_campo_nativo(row[i_char]),
            "identificador": _extrair_campo_nativo(row[i_id]),
        })
    return entradas


def _copiar_game_para_oraculo(pasta_game, destino):
    """Monta uma cópia mínima e isolada do código-fonte Ren'Py para o oráculo.

    Copia apenas scripts-fonte (.rpy, .rpym e *_ren.py). Não copia lib/, RPA,
    imagens, áudio, executáveis ou recursos externos: essa etapa serve para
    validação semântica dos scripts, não para montar uma cópia executável do mod.
    Se um projeto precisar de recursos para inicializar o oráculo, a falha fica
    registrada e o extrator próprio continua em modo sem validação.
    """
    destino = os.path.abspath(destino)
    destino_game = os.path.join(destino, "game")
    os.makedirs(destino_game, exist_ok=True)
    ignorar_dirs = {
        ".git", "__pycache__", "cache", "tmp", "temp", "lib", "renpy",
        "ddac-sdk", "ddac-rascunho", "ddac-dependencia",
    }
    extensoes_script = (".rpy", ".rpym")
    prefixos_ignorados = ("unren-ddac", "ddac-dual", "ddac-diálogos", "ddac-dialogos")
    copiados = 0
    for raiz_atual, dirs, arquivos in os.walk(pasta_game):
        dirs[:] = [d for d in dirs if d.lower() not in ignorar_dirs and
                   not any(d.lower().startswith(p) for p in prefixos_ignorados)]
        relativo_dir = os.path.relpath(raiz_atual, pasta_game)
        if relativo_dir == ".":
            relativo_dir = ""
        for nome in arquivos:
            low = nome.lower()
            if not (low.endswith(extensoes_script) or low.endswith("_ren.py")):
                continue
            if any(low.startswith(p) for p in prefixos_ignorados):
                continue
            origem = os.path.join(raiz_atual, nome)
            subdestino = os.path.join(destino_game, relativo_dir) if relativo_dir else destino_game
            os.makedirs(subdestino, exist_ok=True)
            try:
                shutil.copy2(origem, os.path.join(subdestino, nome))
                copiados += 1
            except Exception as exc:
                try:
                    print(u"  Oráculo Ren'Py: falha ao copiar script '{}': {}".format(
                        os.path.join(relativo_dir, nome), exc), flush=True)
                except Exception:
                    pass
    if copiados == 0:
        raise RuntimeError(u"Nenhum script-fonte Ren'Py (.rpy/.rpym/*_ren.py) pôde ser copiado para o oráculo.")
    return destino_game


def _candidatos_string_linha(linha_texto, alvo):
    encontrados = []
    vistos = set()
    for m in re.finditer(QSTR, linha_texto):
        q = m.group(0)
        try:
            dec = decodificar_literal_traducao(q)
        except Exception:
            dec = strip_quotes(q)
        if dec == alvo:
            chave=(m.start(),m.end())
            if chave not in vistos:
                vistos.add(chave); encontrados.append((m.start(), m.end(), q))
    for inicio, fim, q, _raw in iter_renpy_literais_especiais(linha_texto):
        try:
            dec = decodificar_literal_traducao(q)
        except Exception:
            dec = strip_quotes(q)
        if dec == alvo:
            chave=(inicio,fim)
            if chave not in vistos:
                vistos.add(chave); encontrados.append((inicio,fim,q))
    encontrados.sort(key=lambda x:x[0])
    return encontrados


def _familia_python_sdk(sdk, python_sdk, versao_cli=u""):
    """Identifica a família real do interpretador do SDK (2 ou 3)."""
    caminho = os.path.normcase(os.path.abspath(python_sdk)).replace("\\", "/")
    partes = caminho.split("/")
    texto = "/".join(partes)
    if any(("py3-" in p or p.startswith("py3_") or p == "py3") for p in partes):
        return 3
    if any(("py2-" in p or p.startswith("py2_") or p == "py2") for p in partes):
        return 2
    # Fallback global por geração do Ren'Py: Ren'Py 8 usa Python 3; Ren'Py 6/7
    # usam Python 2 nas famílias suportadas pelo DDAC.
    nums = _versao_numerica(versao_cli or u"")
    if nums and nums[0] >= 8:
        return 3
    if nums and nums[0] in (6, 7):
        return 2
    return 0


def _ambiente_python_sdk(sdk, python_sdk, versao_cli=u""):
    """Prepara o ambiente do Python embutido sem quebrar SDKs modernos.

    Ren'Py 6/7 legado pode depender explicitamente de PYTHONHOME/PYTHONPATH.
    Ren'Py 8 moderno usa um Python 3 embutido e pode carregar ``site`` como
    módulo congelado/embutido; nesse caso não se deve impor uma pasta ``Lib``
    artificial.
    """
    env = os.environ.copy()
    env.pop("PYTHONUSERBASE", None)
    env.pop("PYTHONNOUSERSITE", None)
    python_home = os.path.dirname(os.path.abspath(python_sdk))
    lib_dir = os.path.join(python_home, "Lib")
    familia = _familia_python_sdk(sdk, python_sdk, versao_cli)

    if familia == 2:
        env["PYTHONHOME"] = python_home
        env["PYTHONPATH"] = lib_dir
        return env

    # Python 3 moderno: confiar no ambiente próprio do SDK.
    env.pop("PYTHONHOME", None)
    env.pop("PYTHONPATH", None)
    env["PYTHONNOUSERSITE"] = "1"
    return env


def _flags_python_sdk(py_diag):
    """Usa -O somente quando a instalação depende de arquivos .pyo."""
    if py_diag.get("site_pyo") and not py_diag.get("site_py") and not py_diag.get("site_pyc"):
        return ["-O"]
    return []


def _diagnostico_python_sdk(sdk, python_sdk):
    """Retorna dados objetivos sobre a instalação do Python do SDK."""
    raiz_python = os.path.dirname(os.path.abspath(python_sdk))
    lib_dir = os.path.join(raiz_python, "Lib")
    return {
        "python_dir": raiz_python,
        "lib_dir": lib_dir,
        "lib_existe": os.path.isdir(lib_dir),
        "site_py": os.path.isfile(os.path.join(lib_dir, "site.py")),
        "site_pyc": os.path.isfile(os.path.join(lib_dir, "site.pyc")),
        "site_pyo": os.path.isfile(os.path.join(lib_dir, "site.pyo")),
        "python_dll_27": os.path.isfile(os.path.join(raiz_python, "python27.dll")),
        "libpython_dll": os.path.isfile(os.path.join(raiz_python, "libpython2.7.dll")),
        "sdk": sdk,
    }


def _classificar_falha_oraculo_python(msg):
    """Classifica falhas de ambiente por causa global reutilizável."""
    baixo = texto_compativel(msg, u"").lower()
    if "site.__file__" in baixo or "module 'site' has no attribute '__file__'" in baixo:
        return u"PY3_SITE_FILE_OPCIONAL"
    if "no module named site" in baixo:
        return u"PY_LEGACY_SITE_MISSING"
    if "python smoke-test" in baixo and "retornou" in baixo:
        return u"PYTHON_EMBEDDED_SMOKETEST"
    if "too few arguments" in baixo or ("renpy.py" in baixo and "dialogue" in baixo and "argument" in baixo):
        return u"RENPY_DIALOGUE_SIGNATURE"
    return u"RENPY_ORACLE_GENERIC"


def _preparar_oraculo_renpy(pasta_game, candidatos, log):
    """Executa o Dialogue/Strings nativo do SDK compatível, sempre em cópia.

    V103 trata o SDK preparado pelo BAT como uma dependência explícita. A rotina
    não depende apenas de autodiscovery: o caminho DDAC_RENPY_SDK é testado primeiro,
    com diagnóstico completo de Python, renpy.py, versão e execução do CLI.
    """
    for chave in ORACULO_RENPY:
        if isinstance(ORACULO_RENPY[chave], list): ORACULO_RENPY[chave] = []
        elif isinstance(ORACULO_RENPY[chave], dict): ORACULO_RENPY[chave] = {}
        elif isinstance(ORACULO_RENPY[chave], bool): ORACULO_RENPY[chave] = False
        elif isinstance(ORACULO_RENPY[chave], int): ORACULO_RENPY[chave] = 0
        else: ORACULO_RENPY[chave] = u""

    explicit = os.environ.get("DDAC_RENPY_SDK", "")
    if explicit:
        explicit = os.path.abspath(os.path.expandvars(os.path.expanduser(explicit)))
    sdks = _raizes_candidatas_sdk_renpy(os.path.dirname(pasta_game))
    if explicit and os.path.isdir(explicit) and os.path.isfile(os.path.join(explicit, "renpy.py")):
        sdks = [explicit] + [x for x in sdks if os.path.normcase(os.path.normpath(x)) != os.path.normcase(os.path.normpath(explicit))]

    alvo, evidencias = _detectar_versao_projeto_renpy(pasta_game, candidatos)
    alvo_texto = ".".join(map(str, alvo)) if alvo else "desconhecido"
    log.info(u"Ren'Py alvo detectado: {}{}".format(
        alvo_texto,
        u" | evidência: {}".format(evidencias[0][1]) if evidencias else u""))
    log.info(u"Oráculo Ren'Py: {} candidato(s) de SDK encontrados.".format(len(sdks)))
    if explicit:
        log.info(u"Oráculo Ren'Py: DDAC_RENPY_SDK explícito={}".format(explicit))

    alvo_sdk = tuple(alvo[:4] if alvo and alvo[0] == 6 and len(alvo) >= 4 else alvo[:3]) if alvo else tuple()
    diagnostics = []
    info = []
    for sdk in sdks:
        py = _localizar_python_sdk(sdk)
        versao_cli = _obter_versao_sdk(py, sdk) if py else u""
        versao_path = _versao_por_nome_caminho_sdk(sdk)
        identidade = versao_cli or versao_path
        vt = _versao_numerica(identidade)
        match_cli = bool(alvo_sdk and vt and tuple(vt[:len(alvo_sdk)]) == alvo_sdk)
        match_path = bool(alvo_sdk and versao_path and _versao_numerica(versao_path)[:len(alvo_sdk)] == alvo_sdk)
        valid = bool(py and os.path.isfile(os.path.join(sdk, "renpy.py")))
        explicit_match = bool(explicit and os.path.normcase(os.path.normpath(sdk)) == os.path.normcase(os.path.normpath(explicit)))
        d = {
            "sdk": sdk,
            "python": py or u"",
            "renpy_py": os.path.isfile(os.path.join(sdk, "renpy.py")),
            "versao_cli": versao_cli or u"",
            "versao_caminho": versao_path or u"",
            "match_cli": match_cli,
            "match_caminho": match_path,
            "explicit": explicit_match,
            "valido": valid,
        }
        diagnostics.append(d)
        log.info(u"Oráculo candidato: {} | Python={} | CLI={} | caminho={} | explícito={} | match_cli={} | match_caminho={}".format(
            sdk, py or u"não encontrado", versao_cli or u"?", versao_path or u"?",
            u"SIM" if explicit_match else u"NÃO", u"SIM" if match_cli else u"NÃO",
            u"SIM" if match_path else u"NÃO"))
        if valid:
            info.append((sdk, py, versao_cli, vt, versao_path, match_cli, match_path, explicit_match))

    ORACULO_RENPY["candidatos"] = diagnostics
    if not info:
        ORACULO_RENPY["falhas"] = [u"Nenhum SDK Ren'Py completo com Python embutido foi localizado."]
        log.erro(u"Oráculo Ren'Py: nenhum SDK completo com Python embutido foi localizado.")
        return {}

    if alvo_sdk:
        # Regra obrigatória da Opção 1: o Oráculo usa o SDK exato detectado.
        # A compatibilidade é ampliada pelos layouts/cache e pelo teste real do
        # Python embutido, não por uma troca silenciosa para outra versão.
        compat = [x for x in info if x[5] or x[6]]
        if not compat:
            msg = u"SDK Ren'Py correspondente a {} não foi localizado/validado; extração seguirá sem validação pelo oráculo.".format(".".join(map(str, alvo_sdk)))
            ORACULO_RENPY["falhas"] = [msg]
            log.erro(u"Oráculo Ren'Py: " + msg)
            return {}
        info = compat

    def prioridade(item):
        sdk, py, versao_cli, vt, versao_path, match_cli, match_path, explicit_match = item
        return (
            0 if explicit_match else 1,
            0 if match_cli else (1 if match_path else 2),
            tuple(-x for x in (vt or ())),
            sdk.lower(),
        )

    info.sort(key=prioridade)
    falhas = []
    for pos, (sdk, py, versao_cli, vt, versao_path, match_cli, match_path, explicit_match) in enumerate(info[:8], 1):
        temp = None
        try:
            versao = versao_cli or versao_path or u"desconhecida"
            print(u"  Oráculo Ren'Py: testando SDK {}/{} -> {} ({})...".format(
                pos, min(8, len(info)), versao, sdk), flush=True)
            log.info(u"Oráculo Ren'Py: iniciando candidato {} | sdk={} | python={} | versão={}".format(pos, sdk, py, versao))

            # Smoke test do executável do SDK antes de copiar o jogo.
            # Ren'Py 6/7 usa um Python antigo instalado dentro de lib/<plataforma>.
            # Forçamos PYTHONHOME/PYTHONPATH para a instalação adjacente ao
            # python.exe, evitando o ImportError "No module named site" quando
            # o Windows/usuário possui outra instalação Python ou quando o
            # interpretador legado não consegue calcular o prefixo sozinho.
            py_env = _ambiente_python_sdk(sdk, py, versao_cli or versao_path or u"")
            py_diag = _diagnostico_python_sdk(sdk, py)
            py_flags = _flags_python_sdk(py_diag)
            familia_python = _familia_python_sdk(sdk, py, versao_cli or versao_path or u"")
            py_moderno = familia_python == 3
            log.info(u"Oráculo Ren'Py: ambiente Python | família={} | PYTHONHOME={} | PYTHONPATH={} | Lib={} | site.py={} | site.pyc={} | site.pyo={} | site.__file__ é opcional=SIM".format(
                u"Python 3 moderno" if py_moderno else u"Python 2/legado",
                py_env.get("PYTHONHOME", u"<não imposto>"), py_env.get("PYTHONPATH", u"<não imposto>"),
                u"SIM" if py_diag["lib_existe"] else u"NÃO",
                u"SIM" if py_diag["site_py"] else u"NÃO",
                u"SIM" if py_diag["site_pyc"] else u"NÃO",
                u"SIM" if py_diag["site_pyo"] else u"NÃO"))
            log.info(u"Oráculo Ren'Py: flags Python={}".format(u" ".join(py_flags) if py_flags else u"(nenhuma)"))
            try:
                cp_probe = subprocess.run(
                    [py] + py_flags + ["-c", "import sys,site; print(sys.version); print(sys.prefix); print(getattr(site, '__file__', '<built-in-or-frozen>')); print(sys.flags.optimize); print('renpy_py=' + str(bool(__import__('os').path.isfile('renpy.py'))))"],
                    cwd=sdk, env=py_env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, encoding="utf-8", errors="replace", timeout=45
                )
                probe = (cp_probe.stdout or u"").strip().replace(u"\n", u" | ")
                log.info(u"Oráculo Ren'Py: Python smoke-test código={} | saída={}".format(cp_probe.returncode, probe[-800:] or u"<vazio>"))
                if cp_probe.returncode == 0 and u"<built-in-or-frozen>" in probe:
                    log.info(u"Oráculo Ren'Py: módulo site carregado sem __file__; comportamento aceito para Python 3 moderno." )
                if cp_probe.returncode != 0:
                    msg = u"{}: Python smoke-test retornou {} | Lib={} | site.py={} | site.pyc={} | site.pyo={}".format(
                        sdk, cp_probe.returncode,
                        u"SIM" if py_diag["lib_existe"] else u"NÃO",
                        u"SIM" if py_diag["site_py"] else u"NÃO",
                        u"SIM" if py_diag["site_pyc"] else u"NÃO",
                        u"SIM" if py_diag["site_pyo"] else u"NÃO")
                    codigo_falha = _classificar_falha_oraculo_python(msg)
                    msg = msg + u" | classe_global={}".format(codigo_falha)
                    falhas.append(msg); log.erro(u"Oráculo Ren'Py: " + msg); continue
            except Exception as exc:
                msg = u"{}: Python smoke-test falhou: {}".format(sdk, exc)
                falhas.append(msg); log.erro(u"Oráculo Ren'Py: " + msg); continue

            temp = tempfile.mkdtemp(prefix="ddac_renpy_oracle_")
            _copiar_game_para_oraculo(pasta_game, temp)
            external_char = os.path.join(temp, "characters", "monika.chr")
            log.info(u"Oráculo Ren'Py: projeto isolado preparado | characters/monika.chr={}".format(u"SIM" if os.path.isfile(external_char) else u"NÃO"))
            if not os.path.isfile(external_char):
                log.aviso(u"Oráculo Ren'Py: o projeto isolado não contém characters/monika.chr; init do jogo pode falhar ao executar renpy.file().")
            cmd_dialogue = [py] + py_flags + ["renpy.py", temp, "dialogue"]
            # Ren'Py 7/8 exigem o argumento de idioma no comando Dialogue.
            # None representa o idioma primário/original do projeto; Ren'Py 6 mantém a chamada legada que já foi validada na V118.
            if _versao_numerica(versao) and _versao_numerica(versao)[0] >= 7:
                cmd_dialogue.append("None")
            cmd_dialogue += ["--strings", "--escape"]
            log.info(u"Oráculo Ren'Py: executando Dialogue + Strings: {}".format(u" ".join(cmd_dialogue)))
            print(u"  ETAPA 3/14 - Oráculo Ren'Py: executando Dialogue + Strings...".format(), flush=True)
            print(u"  (o SDK está processando o projeto isolado; esta etapa pode levar alguns segundos)", flush=True)
            inicio_dialogue = time.time()
            proc_dialogue = subprocess.Popen(
                cmd_dialogue, cwd=sdk, env=py_env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, encoding="utf-8", errors="replace", universal_newlines=True
            )
            def _heartbeat_oraculo():
                while proc_dialogue.poll() is None:
                    time.sleep(5.0)
                    if proc_dialogue.poll() is None:
                        print(u"  ↳ Oráculo Ren'Py ainda executando... {:.0f}s".format(time.time() - inicio_dialogue), flush=True)
            heartbeat = threading.Thread(target=_heartbeat_oraculo)
            heartbeat.daemon = True
            heartbeat.start()
            try:
                out, _ = proc_dialogue.communicate(timeout=600)
                rc_dialogue = proc_dialogue.returncode
            except subprocess.TimeoutExpired:
                proc_dialogue.kill()
                out, _ = proc_dialogue.communicate()
                rc_dialogue = proc_dialogue.returncode if proc_dialogue.returncode is not None else 124
            cp = type("DDACProcessResult", (), {"returncode": rc_dialogue, "stdout": out})()
            tab = os.path.join(temp, "dialogue.tab")
            tail = [x.strip() for x in out.splitlines() if x.strip()][-15:]
            log.info(u"Oráculo Ren'Py: Dialogue terminou código={} | dialogue.tab={} | saída={}".format(
                cp.returncode, u"SIM" if os.path.isfile(tab) else u"NÃO", u" || ".join(tail)))
            print(u"  ETAPA 3/14 - Dialogue + Strings concluído | código={} | dialogue.tab={}".format(
                cp.returncode, u"SIM" if os.path.isfile(tab) else u"NÃO"
            ), flush=True)
            if cp.returncode != 0 or not os.path.isfile(tab):
                msg = u"{}: Dialogue código={} | dialogue.tab={} | saída={}".format(
                    sdk, cp.returncode, u"SIM" if os.path.isfile(tab) else u"NÃO", u" || ".join(tail))
                ORACULO_RENPY["falhas"].append(msg)
                ORACULO_RENPY["diagnostico_temp"] = temp
                falhas.append(msg); temp = None; continue

            entradas_brutas = _ler_dialogue_tab(tab)
            if not entradas_brutas:
                msg = u"{}: dialogue.tab vazio ou ilegível".format(sdk)
                falhas.append(msg); continue
            ignoradas_oraculo = [x for x in entradas_brutas if arquivo_globalmente_ignorado_extracao(x.get("arquivo", ""))]
            entradas = [x for x in entradas_brutas if not arquivo_globalmente_ignorado_extracao(x.get("arquivo", ""))]
            ORACULO_RENPY["nativas_brutas_total"] = len(entradas_brutas)
            ORACULO_RENPY["nativas_ignoradas_arquivos_globais"] = len(ignoradas_oraculo)
            if ignoradas_oraculo:
                log.info(u"Oráculo Ren'Py: {} entrada(s) removida(s) pela regra global de arquivos ignorados.".format(len(ignoradas_oraculo)))

            print(u"  Oráculo Ren'Py: {} entradas nativas encontradas após filtros globais.".format(len(entradas)), flush=True)
            ORACULO_RENPY["ativo"] = True
            ORACULO_RENPY["sdk"] = sdk
            ORACULO_RENPY["versao"] = versao
            ORACULO_RENPY["entradas"] = entradas
            ORACULO_RENPY["nativas_total"] = len(entradas)
            ORACULO_RENPY["nativas_multilinha"] = sum(1 for x in entradas if u"\n" in x.get("texto", u""))
            ORACULO_RENPY["game_root"] = os.path.abspath(pasta_game)
            por_arquivo = {}
            for item in entradas:
                por_arquivo.setdefault(item["arquivo"].lower(), {}).setdefault(item["linha"], []).append(item)
            ORACULO_RENPY["por_arquivo"] = por_arquivo

            # Lint é diagnóstico; não desativa o oráculo quando houver avisos de script.
            try:
                cp_lint = subprocess.run(
                    [py] + py_flags + ["renpy.py", temp, "lint"], cwd=sdk, env=py_env, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=600
                )
                if cp_lint.returncode != 0:
                    for l in [x.strip() for x in (cp_lint.stdout or u"").splitlines() if x.strip()][-8:]:
                        log.aviso(u"Ren'Py Lint (cópia de diagnóstico): " + l)
                log.info(u"Oráculo Ren'Py: Lint código={}.".format(cp_lint.returncode))
            except Exception as exc:
                log.aviso(u"Ren'Py Lint não pôde ser executado: {}".format(exc))

            ORACULO_RENPY["falhas"] = falhas[:30]
            ORACULO_RENPY["projeto_isolado_recursos_externos"] = True
            log.info(u"Oráculo Ren'Py ATIVO: SDK={} | versão={} | {} entradas nativas.".format(
                sdk, versao, len(entradas)))
            print(u"  Oráculo Ren'Py: ATIVO -> {} | {} entradas".format(versao, len(entradas)), flush=True)
            return por_arquivo
        except subprocess.TimeoutExpired:
            msg = u"{}: timeout de 600s".format(sdk)
            falhas.append(msg); log.erro(u"Oráculo Ren'Py: " + msg)
        except Exception as exc:
            msg = u"{}: {}".format(sdk, exc)
            falhas.append(msg); log.erro(u"Oráculo Ren'Py: falha -> " + msg)
        finally:
            if temp:
                try: shutil.rmtree(temp, ignore_errors=True)
                except Exception: pass

    ORACULO_RENPY["falhas"] = falhas[:30]
    for f in falhas[:10]: log.erro(u"Oráculo Ren'Py: " + f)
    return {}

def _injetar_entradas_oraculo_na_linha(linha_numero, linha_sem_fim, arquivo_relativo, oracle_file, registros, prefixo_ws, ja_ocupados):
    if not oracle_file:
        return (0, 0, 0)
    entradas = oracle_file.get(linha_numero, [])
    if not entradas:
        return (0, 0, 0)
    adicionadas = duplicadas = ambiguas = 0
    for item in entradas:
        candidatos = _candidatos_string_linha(linha_sem_fim, item["texto"])
        if len(candidatos) == 0:
            continue
        if len(candidatos) > 1:
            ambiguas += 1
            continue
        inicio, fim, q = candidatos[0]
        chave = (inicio - len(prefixo_ws), fim - len(prefixo_ws))
        if chave in ja_ocupados:
            duplicadas += 1
            continue
        # Não usa a posição nativa isoladamente para fabricar um texto que não
        # esteja literalmente na fonte. O oráculo só entra quando consegue
        # provar o match arquivo + linha + literal.
        if chave[0] < 0:
            continue
        tipo_oraculo = ('renpy_nativo_dialogo' if item.get('personagem') else 'renpy_nativo_string')
        # URL pura exibida em uma fala/menu continua sendo texto visível e precisa
        # entrar no mapa, mas jamais deve ser enviada ao Google Translate.
        if item.get('personagem') and PURE_VISIBLE_URL_RE.match(strip_quotes(q).strip()):
            tipo_oraculo = 'url_visivel'
        registros.append((chave[0], chave[1],
                          tipo_oraculo,
                          100,
                          u"Oráculo Ren'Py: {}{}".format(
                              u"fala" if item.get('personagem') else u"string/menu",
                              (u" [{}]".format(item.get('identificador')) if item.get('identificador') else u"")),
                          q, None))
        ja_ocupados.add(chave)
        adicionadas += 1
    return adicionadas, duplicadas, ambiguas

# =============================================================================
# EXTRAÇÃO E MAPA
# =============================================================================

def _normalizar_texto_oraculo_mapa(valor):
    """Decodifica o literal Ren'Py armazenado no mapa DDAC."""
    if valor is None:
        return u""
    texto = str(valor)
    try:
        return decodificar_literal_traducao(texto)
    except Exception:
        return strip_quotes(texto)


def _normalizar_texto_oraculo_sdk(valor):
    """Mantém literalmente o texto já decodificado entregue pelo SDK."""
    return u"" if valor is None else str(valor)


def _texto_oraculo_relevante(texto):
    """Retorna True quando a entrada nativa tem aparência de texto traduzível."""
    if texto is None:
        return False
    s = str(texto).strip()
    if not s:
        return False
    if s.startswith((u"$", u"#")):
        return False
    if re.match(r'^(label|jump|call|define|default|transform|screen|init|python)\b', s, re.I):
        return False
    if re.match(r'^[A-Za-z_][A-Za-z0-9_]*(?:[.\\/][A-Za-z0-9_.\\/-]+)?$', s):
        return False
    if re.match(r'^[A-Za-z]:[\\/]', s):
        return False
    if re.search(r'\.(?:rpy|rpym|rpyc|py|png|jpg|jpeg|webp|ogg|mp3|wav|ttf|otf)$', s, re.I):
        return False
    if not re.search(r'[A-Za-zÀ-ÿ]', s):
        return False
    return True


def _auditar_cobertura_oraculo(mapa_completo, candidatos=None, ignorados_bib=None):
    """Audita o que o SDK oficial encontrou contra o mapa DDAC final.

    Importante: "nativas_mapeadas" e "nativas_duplicadas" são contadores de
    eventos ocorridos durante a injeção do Oráculo e não são partes de uma
    mesma soma. A cobertura desta auditoria é calculada exclusivamente pelo
    cruzamento final SDK <-> mapa, evitando o antigo relatório enganoso.
    """
    if not ORACULO_RENPY.get("ativo"):
        return

    encontrados_exatos = set()
    encontrados_texto = {}
    arquivos_mapa = set()

    for rel, mapa in (mapa_completo or {}).items():
        reln = _normalizar_rel_renpy(rel).lower()
        arquivos_mapa.add(reln)
        for item in mapa or []:
            linha = int(item.get("linha", 0) or 0)
            original = _normalizar_texto_oraculo_mapa(
                item.get("original", item.get("trecho", u""))
            )
            encontrados_exatos.add((reln, linha, original))
            chave = (reln, original)
            encontrados_texto[chave] = encontrados_texto.get(chave, 0) + 1

    # O escopo da auditoria representa arquivos-fonte realmente analisáveis.
    # Ele inclui os arquivos candidatos, mas respeita os arquivos explicitamente
    # retirados pela biblioteca DDAC. O relatório não chamará essas entradas de
    # "diálogos perdidos": elas são apenas candidatas nativas não correspondidas.
    arquivos_escopo = set(arquivos_mapa)
    for caminho in candidatos or []:
        try:
            rel = os.path.relpath(
                caminho,
                ORACULO_RENPY.get("game_root") or os.path.dirname(caminho)
            )
            rel = _normalizar_rel_renpy(rel).lower()
            # Nunca adicionar caminhos relativos quebrados com ".." ao escopo.
            if not rel.startswith("../") and not rel.startswith("..\\"):
                arquivos_escopo.add(rel)
        except Exception:
            pass

    ignorados = set()
    for caminho, _descricao in (ignorados_bib or []):
        ignorados.add(_normalizar_rel_renpy(caminho).lower())
    for caminho in IGNORADOS_EXTRACAO_AUTOMATICA:
        ignorados.add(_normalizar_rel_renpy(caminho).lower())

    pendentes = []
    fora_escopo = 0
    fallback_texto = 0
    fallback_monologo = 0
    correspondencia_exata = 0
    restantes = dict(encontrados_texto)
    monologo_restantes = {}
    for rel, mapa in (mapa_completo or {}).items():
        reln = _normalizar_rel_renpy(rel).lower()
        for item_map in mapa or []:
            if item_map.get('tipo') not in ('monologo_triplas', 'gettext_multilinha', 'poema_corpo'):
                continue
            txt_m = re.sub(r'\s+', ' ', _normalizar_texto_oraculo_mapa(item_map.get('original', u''))).strip()
            if txt_m:
                chave_m = (reln, txt_m)
                monologo_restantes[chave_m] = monologo_restantes.get(chave_m, 0) + 1
    escopo = 0

    for item in ORACULO_RENPY.get("entradas", []):
        reln = _normalizar_rel_renpy(item.get("arquivo", u"")).lower()
        linha = int(item.get("linha", 0) or 0)
        texto = _normalizar_texto_oraculo_sdk(item.get("texto", u""))

        if (
            reln not in arquivos_escopo
            or reln in ignorados
            or not _texto_oraculo_relevante(texto)
        ):
            fora_escopo += 1
            continue

        escopo += 1

        if (reln, linha, texto) in encontrados_exatos:
            chave = (reln, texto)
            if restantes.get(chave, 0) > 0:
                restantes[chave] -= 1
            correspondencia_exata += 1
            continue

        chave = (reln, texto)
        if restantes.get(chave, 0) > 0:
            restantes[chave] -= 1
            fallback_texto += 1
            continue

        # Ren'Py monologue mode pode exportar um bloco inteiro como uma única
        # entrada nativa contendo várias linhas, enquanto o mapa precisa manter
        # cada linha física separada para que a reinjeção preserve a estrutura.
        # Nesse caso, prova-se a cobertura comparando todas as linhas do bloco
        # com as entradas `monologo_triplas` do mesmo arquivo.
        if '\n' in texto or '\r' in texto:
            partes = [re.sub(r'\s+', ' ', p).strip() for p in re.split(r'[\r\n]+', texto) if p.strip()]
            consumo = []
            possivel = bool(partes)
            for parte in partes:
                chave_m = (reln, parte)
                if monologo_restantes.get(chave_m, 0) <= 0:
                    possivel = False
                    break
                consumo.append(chave_m)
            if possivel:
                for chave_m in consumo:
                    monologo_restantes[chave_m] -= 1
                fallback_monologo += 1
                continue

        pendentes.append(item)

    # Estas três métricas são a única base da "cobertura" do Oráculo.
    cobertas = correspondencia_exata + fallback_texto
    total_relevante = escopo

    ORACULO_RENPY["nativas_total"] = len(ORACULO_RENPY.get("entradas", []))
    ORACULO_RENPY["nativas_em_escopo"] = total_relevante
    ORACULO_RENPY["nativas_fora_escopo"] = fora_escopo
    ORACULO_RENPY["nativas_correspondencia_exata"] = correspondencia_exata
    ORACULO_RENPY["nativas_fallback_texto"] = fallback_texto
    ORACULO_RENPY["nativas_fallback_monologo"] = fallback_monologo
    cobertas += fallback_monologo
    ORACULO_RENPY["nativas_cobertura_real"] = cobertas
    ORACULO_RENPY["nativas_cobertura_pct"] = (100.0 * cobertas / total_relevante) if total_relevante else 100.0
    ORACULO_RENPY["nativas_nao_localizadas"] = len(pendentes)
    ORACULO_RENPY["nativas_nao_localizadas_amostras"] = [
        u"{}:{} -> {}".format(
            x.get("arquivo", "?"),
            x.get("linha", "?"),
            (x.get("texto", "") or "")[:180].replace("\r", "\\r").replace("\n", "\\n")
        )
        for x in pendentes[:30]
    ]
    ORACULO_RENPY["falhas"] = [
        u"Nativa relevante não correspondida ao mapa: {}".format(amostra)
        for amostra in ORACULO_RENPY["nativas_nao_localizadas_amostras"]
    ]


def _sha256_texto_utf8(texto):
    return hashlib.sha256((texto or u'').encode('utf-8')).hexdigest()

def _token_signature_mapa(original):
    try:
        texto = decodificar_literal_traducao(original)
    except Exception:
        texto = strip_quotes(original)
    return [raw for _,_,raw in _intervalos_tokens_google(texto)]

def _iter_intervalos_brackets_balanceados(texto):
    """Retorna intervalos [..] com nesting balanceado, respeitando escapes e aspas."""
    abertos=[]; i=0; n=len(texto)
    quote=None; esc=False
    while i<n:
        ch=texto[i]
        if quote is not None:
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: quote=None
            i+=1; continue
        if ch in ('"', "'", '`'):
            quote=ch; i+=1; continue
        if ch=='\\': i+=2; continue
        if ch=='[': abertos.append(i)
        elif ch==']' and abertos:
            inicio=abertos.pop()
            if not abertos:
                yield inicio, i+1
        i+=1

def _hash_contexto_linhas(linhas_raw, numero, raio=2):
    a=max(0,numero-1-raio); b=min(len(linhas_raw),numero+raio)
    return _sha256_texto_utf8(u''.join(linhas_raw[a:b]))

def _enriquecer_mapa_integridade(mapa, caminho, caminho_relativo, linhas_raw=None):
    linhas_raw = linhas_raw if linhas_raw is not None else ler_linhas_raw(caminho)
    source_sha = sha256_arquivo(caminho)
    ultimo_grupo = None
    ultima_linha = None
    ultimo_tipo = None
    ultimo_contexto = None
    for entrada in mapa:
        numero=int(entrada.get('linha',0) or 0)
        original=entrada.get('original',entrada.get('trecho',u''))
        base_id = u'{0}\0{1}\0{2}\0{3}\0{4}'.format(source_sha, numero, entrada.get('coluna_inicio',0), entrada.get('coluna_fim',0), original)
        entrada['source_sha256']=source_sha
        entrada['entry_id']=hashlib.sha256(base_id.encode('utf-8')).hexdigest()[:24]
        tipo=entrada.get('tipo',u'')
        contexto=entrada.get('contexto',u'')
        especial=tipo in ('multilinha_renpy','monologo_triplas','poema_corpo','gettext_multilinha')
        if especial and ultimo_grupo and tipo==ultimo_tipo and contexto==ultimo_contexto and ultima_linha is not None and numero <= ultima_linha+2:
            grupo=ultimo_grupo
        else:
            grupo_base=u'{0}\0{1}\0{2}'.format(source_sha, tipo, numero)
            grupo=hashlib.sha256(grupo_base.encode('utf-8')).hexdigest()[:20] if especial else entrada['entry_id']
        entrada['logical_group_id']=grupo
        linha_raw=linhas_raw[numero-1] if 1 <= numero <= len(linhas_raw) else u''
        entrada['source_line_hash']=_sha256_texto_utf8(linha_raw)
        entrada['context_hash']=_hash_contexto_linhas(linhas_raw,numero)
        entrada['token_signature']=_token_signature_mapa(original)
        ultimo_grupo=grupo if especial else None
        ultima_linha=numero if especial else None
        ultimo_tipo=tipo if especial else None
        ultimo_contexto=contexto if especial else None
    return mapa


def executar_extracao(raiz):
    global IGNORADOS_EXTRACAO_AUTOMATICA
    IGNORADOS_EXTRACAO_AUTOMATICA = []
    inicio_total=time.time()
    pasta_game=encontrar_pasta_game(raiz)
    pasta_saida_base=os.path.join(raiz,PASTA_ENTRADA_NOME)
    log=Log(os.path.join(raiz,NOME_LOG_EXTRATOR))
    log.separador(); log.titulo(t("log_cab_extrator")); log.titulo(t("log_datahora").format(time.strftime("%d/%m/%Y %H:%M:%S"))); log.separador()
    log.info(t("log_pasta_escaneada").format(pasta_game)); log.info(t("log_pasta_saida").format(pasta_saida_base)); log.info(u"Modo de exibição: {0}".format(MODO_EXIBICAO))
    print("============================================================"); print(t("cab_extrair")); print("============================================================"); print("")
    print(t("pasta_escaneada").format(pasta_game)); print(t("pasta_saida").format(pasta_saida_base)); print("")
    print(t("etapa_biblioteca").format(len(BIBLIOTECA_DDLC))); log.info(t("etapa_biblioteca").format(len(BIBLIOTECA_DDLC))); print("")
    print(t("etapa1_extrair")); candidatos_iniciais=coletar_candidatos_extracao(pasta_game); indice_arquivos=construir_indice_arquivos(pasta_game); arquivos_encontrados=len(candidatos_iniciais); print(t("arquivos_encontrados").format(arquivos_encontrados));
    if IGNORADOS_EXTRACAO_AUTOMATICA:
        for _ign in IGNORADOS_EXTRACAO_AUTOMATICA:
            print(u"[INFO] Arquivo-base não utilizado ignorado na extração: {0}".format(_ign))
            log.info(u"Arquivo-base não utilizado ignorado na extração: {0}".format(_ign))
    print(""); log.info(t("log_etapa1_extrair").format(arquivos_encontrados))
    print(t("etapa2_extrair")); variaveis_nome_dinamico=coletar_variaveis_nome_dinamico(candidatos_iniciais); vocabulario=coletar_vocabulario(pasta_game,candidatos_iniciais); candidatos=[c for c in candidatos_iniciais if not em_pasta_sem_texto(c,pasta_game)]; arquivos_analisados=len(candidatos); print(t("vars_dinamicas").format(len(variaveis_nome_dinamico))); print(""); log.info(t("log_etapa2_extrair").format(len(variaveis_nome_dinamico),", ".join(sorted(variaveis_nome_dinamico)) or "-"))
    print(t("etapa2b_extrair") if "etapa2b_extrair" in MENSAGENS.get(IDIOMA,{}) else u"Etapa 2b/3: ativando oráculo semântico Ren'Py quando disponível..."); print(u"  Python 3 acima = motor DDAC. O SDK Ren'Py, quando encontrado, usa o seu próprio Python compatível.", flush=True);
    oracle_por_arquivo = _preparar_oraculo_renpy(pasta_game, candidatos, log)
    if ORACULO_RENPY["ativo"]:
        print(u"  Oráculo Ren'Py ativo: {} | {}".format(ORACULO_RENPY["versao"], ORACULO_RENPY["nativas_total"]))
    else:
        print(u"  Oráculo Ren'Py não disponível; motor DDAC continuará como fallback completo.")
    print(t("etapa3_extrair").format(PASTA_ENTRADA_NOME)); print(""); log.info(t("log_etapa3_extrair"))
    total_com_dialogo=total_linhas=total_erros=0; vazios=[]; ignorados_bib=[]; novos_bib=[]; mapa_completo={}
    for numero,caminho in enumerate(candidatos,1):
        caminho_relativo=os.path.relpath(caminho,pasta_game)
        try:
            if caminho.lower().endswith(".txt"):
                caminho_saida=os.path.join(pasta_saida_base,caminho_relativo)
                if eh_arquivo_lista_palavras_poema(caminho):
                    entradas_txt=extrair_txt_lista_palavras_poema(caminho)
                    if entradas_txt:
                        escrever_txt_palavras_extraido(caminho, caminho_saida, entradas_txt)
                        chave=caminho_relativo.replace(os.sep,"/")
                        mapa_completo[chave]=_enriquecer_mapa_integridade(entradas_txt, caminho, chave)
                        total_com_dialogo+=1; total_linhas+=len(entradas_txt)
                        log.resultado(caminho_relativo,t("log_linhas").format(len(entradas_txt)) + u" | lista de palavras de poema filtrada")
                    else:
                        IGNORADOS_EXTRACAO_AUTOMATICA.append(caminho_relativo.replace(os.sep, "/"))
                        log.aviso(u"TXT de poema sem linhas CSV válidas; omitido da saída traduzível: {}".format(caminho_relativo))
                else:
                    IGNORADOS_EXTRACAO_AUTOMATICA.append(caminho_relativo.replace(os.sep, "/"))
                    log.info(u"TXT técnico sem texto mapeável; omitido da saída traduzível: {}".format(caminho_relativo))
            else:
                textos,mapa=extrair_arquivo_com_mapa(caminho,variaveis_nome_dinamico,indice_arquivos,vocabulario,oracle_por_arquivo); info_bib=consultar_biblioteca(caminho_relativo); sem_dialogo_nativo=bool(info_bib) and info_bib["dialogo"] is False
                if not textos:
                    if sem_dialogo_nativo:
                        descricao=descricao_biblioteca(info_bib); ignorados_bib.append((caminho_relativo,descricao)); log.info(t("log_bib_ignorado").format(caminho_relativo,descricao))
                    else: vazios.append(caminho_relativo)
                else:
                    if sem_dialogo_nativo:
                        descricao=descricao_biblioteca(info_bib); novos_bib.append((caminho_relativo,len(textos),descricao)); log.aviso(t("log_bib_novo").format(caminho_relativo,descricao))
                    caminho_saida=os.path.join(pasta_saida_base,caminho_relativo); pasta_saida=os.path.dirname(caminho_saida)
                    if pasta_saida and not os.path.isdir(pasta_saida): os.makedirs(pasta_saida)
                    with io.open(caminho_saida,"w",encoding="utf-8",newline="\n") as f: f.write(u"\n".join([u""]+[INDENTACAO_SAIDA+texto for _,texto in textos])+u"\n")
                    chave=caminho_relativo.replace(os.sep,"/"); mapa_completo[chave]=_enriquecer_mapa_integridade(mapa, caminho, chave, linhas_raw=ler_linhas_raw(caminho)); total_com_dialogo+=1; total_linhas+=len(textos); log.resultado(caminho_relativo,t("log_linhas").format(len(textos)))
                    if exibicao_detalhada(): print(t("ok_linhas").format(caminho_relativo,len(textos)))
        except Exception as exc:
            total_erros+=1; log.erro(t("log_falha_ler").format(caminho_relativo,exc)); print(t("erro_arquivo").format(caminho_relativo,exc))
        print(u"\rArquivos: {0}/{1} {2}".format(numero,max(1,arquivos_analisados),barra_progresso(numero,max(1,arquivos_analisados))),end=u"")
    print("")
    if not os.path.isdir(pasta_saida_base): os.makedirs(pasta_saida_base)
    with io.open(os.path.join(pasta_saida_base,NOME_MAPA),"w",encoding="utf-8") as f: json.dump(mapa_completo,f,ensure_ascii=False,indent=1)
    decorrido=time.time()-inicio_total; velocidade=float(total_linhas)/max(0.001,decorrido)
    print(""); print(t("res_escaneados").format(arquivos_encontrados)); print(u"Arquivos analisados: {0}".format(arquivos_analisados)); print(u"Arquivos extraídos: {0}".format(total_com_dialogo)); print(u"Textos extraídos: {0}".format(total_linhas)); print(u"TXT técnico/fora do mapa omitido: {0}".format(len(IGNORADOS_EXTRACAO_AUTOMATICA))); print(u"{0} 100%".format(barra_progresso(arquivos_analisados,max(1,arquivos_analisados)))); print(u"Concluído em {0:.1f}s | {1:.1f} textos/s".format(decorrido,velocidade))
    if exibicao_detalhada():
        if vazios: print(t("res_sem_dialogo").format(len(vazios))); [print(u"  - {0}".format(x)) for x in vazios]
        if ignorados_bib: print(t("res_bib_ignorados").format(len(ignorados_bib))); [print(u"  - {0} ({1})".format(a,b)) for a,b in ignorados_bib]
        if novos_bib: print(t("res_bib_novos").format(len(novos_bib))); [print(u"  - {0} -> {1} ({2})".format(a,b,c)) for a,b,c in novos_bib]
    _auditar_cobertura_oraculo(mapa_completo, candidatos=candidatos, ignorados_bib=ignorados_bib)
    print(""); print(t("imp1").format(NOME_MAPA)); print(t("imp2").format(PASTA_ENTRADA_NOME)); print(t("imp3")); print(t("imp4")); print(t("imp5")); print(t("imp6"))
    log.separador(); log.resultado(t("log_res_escaneados"),str(arquivos_encontrados)); log.resultado(u"Arquivos analisados",str(arquivos_analisados)); log.resultado(u"Arquivos extraídos",str(total_com_dialogo)); log.resultado(t("log_res_sem_dialogo"),str(len(vazios))); log.resultado(t("log_res_linhas"),str(total_linhas)); log.resultado(t("log_res_bib_ignorados"),str(len(ignorados_bib))); log.resultado(t("log_res_bib_novos"),str(len(novos_bib))); log.resultado(t("log_res_erros"),str(total_erros));
    log.resultado(u"Oráculo Ren'Py ativo", u"SIM" if ORACULO_RENPY["ativo"] else u"NÃO")
    if ORACULO_RENPY["ativo"]:
        cobertura_total = ORACULO_RENPY.get("nativas_em_escopo", 0)
        cobertura_real = ORACULO_RENPY.get("nativas_cobertura_real", 0)
        cobertura_pct = ORACULO_RENPY.get("nativas_cobertura_pct", (100.0 * cobertura_real / cobertura_total) if cobertura_total else 100.0)
        log.resultado(u"Oráculo Ren'Py - SDK", ORACULO_RENPY["sdk"]); log.resultado(u"Oráculo Ren'Py - versão", ORACULO_RENPY["versao"]); log.resultado(u"Oráculo Ren'Py - entradas nativas", str(ORACULO_RENPY["nativas_total"])); log.resultado(u"Oráculo Ren'Py - candidatos em escopo", str(ORACULO_RENPY.get("nativas_em_escopo", 0))); log.resultado(u"Oráculo Ren'Py - correspondência exata arquivo+linha+texto", str(ORACULO_RENPY.get("nativas_correspondencia_exata", 0))); log.resultado(u"Oráculo Ren'Py - correspondência fallback arquivo+texto", str(ORACULO_RENPY.get("nativas_fallback_texto", 0))); log.resultado(u"Oráculo Ren'Py - ações de injeção DDAC", str(ORACULO_RENPY["nativas_mapeadas"])); log.resultado(u"Oráculo Ren'Py - entradas já existentes no mapa", str(ORACULO_RENPY["nativas_duplicadas"])); log.resultado(u"Oráculo Ren'Py - fora do escopo/filtro técnico", str(ORACULO_RENPY.get("nativas_fora_escopo", 0))); log.resultado(u"Oráculo Ren'Py - ambíguas", str(ORACULO_RENPY["nativas_ambiguas"])); log.resultado(u"Oráculo Ren'Py - multilinha", str(ORACULO_RENPY["nativas_multilinha"])); log.resultado(u"Oráculo Ren'Py - correspondência real SDK↔mapa", u"{0}/{1} ({2:.1f}%)".format(cobertura_real, cobertura_total, cobertura_pct)); log.resultado(u"Oráculo Ren'Py - candidatos nativos sem correspondência no mapa", str(ORACULO_RENPY["nativas_nao_localizadas"]));
        for amostra in ORACULO_RENPY.get("nativas_nao_localizadas_amostras", []): log.info(u"[ORÁCULO AUDITORIA] " + amostra)
    log.resultado(u"Tempo total",u"{0:.1f}s".format(decorrido)); log.resultado(u"Velocidade média",u"{0:.1f} textos/s".format(velocidade)); log.separador(); log.salvar(); print(""); print(t("log_salvo").format(log.caminho)); return 0

def ler_textos_traduzidos(caminho):
    with io.open(caminho, "r", encoding="utf-8", errors="replace") as f:
        conteudo = f.read()
    if conteudo.endswith(u"\n"):
        conteudo = conteudo[:-1]
    if conteudo == u"":
        return []
    linhas = conteudo.split(u"\n")
    uteis = []
    for l in linhas:
        despido = l.strip()
        if not despido:
            continue
        if despido.startswith(u"#"):
            continue
        uteis.append(despido)
    return uteis


def coletar_candidatos_reinjecao(pasta_entrada):
    candidatos = []
    mapas = set(MAPAS_COMPATIVEIS)
    mapa_chaves = None
    try:
        mapa_nome = next((n for n in MAPAS_COMPATIVEIS if os.path.isfile(os.path.join(pasta_entrada, n))), None)
        if mapa_nome:
            with io.open(os.path.join(pasta_entrada, mapa_nome), "r", encoding="utf-8") as f:
                mapa = json.load(f)
            if isinstance(mapa, dict):
                mapa_chaves = set(_dual_norm_rel(k) for k in mapa.keys())
    except Exception:
        mapa_chaves = None
    for pasta_atual, subpastas, arquivos in os.walk(pasta_entrada):
        for nome in arquivos:
            if nome in mapas:
                continue
            caminho = os.path.join(pasta_atual, nome)
            rel = _dual_norm_rel(os.path.relpath(caminho, pasta_entrada))
            if mapa_chaves is not None and rel not in mapa_chaves:
                continue
            candidatos.append(caminho)
    candidatos.sort(key=lambda x: x.lower())
    return candidatos


def _contar_aspas_nao_escapadas(texto, caractere):
    total = 0
    i = 0
    while i < len(texto):
        if texto[i] == u'\\':
            i += 2
            continue
        if texto[i] == caractere:
            total += 1
        i += 1
    return total


def _validar_fragmento_multilinha_compat(original, traduzido):
    if u'\n' in traduzido or u'\r' in traduzido:
        return False, 'quebra_fisica'
    dq_o = _contar_aspas_nao_escapadas(original, u'"')
    sq_o = _contar_aspas_nao_escapadas(original, u"'")
    if u'"""' not in original and u"'''" not in original and ((dq_o % 2) or (sq_o % 2)):
        return False, 'mapa_legado_truncado'
    dq_t = _contar_aspas_nao_escapadas(traduzido, u'"')
    sq_t = _contar_aspas_nao_escapadas(traduzido, u"'")
    if dq_o != dq_t or sq_o != sq_t:
        return False, 'aspas_estruturais_alteradas'
    for q in (u'"""', u"'''"):
        if q in original and q not in traduzido:
            return False, 'delimitador_triplo_alterado'
    if original.rstrip().endswith(u'\\') and not traduzido.rstrip().endswith(u'\\'):
        return False, 'barra_continuacao_alterada'
    return True, None


def reinjetar_arquivo(caminho_original, entradas_mapa, textos_traduzidos):
    erros = []
    avisos_compat = 0

    if len(entradas_mapa) != len(textos_traduzidos):
        erros.append(t("rj_contagem").format(len(entradas_mapa), len(textos_traduzidos)))
        return None, erros

    if not os.path.isfile(caminho_original):
        erros.append(t("rj_sem_original").format(caminho_original))
        return None, erros

    linhas_raw = ler_linhas_raw(caminho_original)

    for entrada in entradas_mapa:
        numero_linha = entrada["linha"]
        if numero_linha < 1 or numero_linha > len(linhas_raw):
            erros.append(t("rj_linha_inexistente").format(numero_linha))
            continue
        linha_sem_fim = linhas_raw[numero_linha - 1].rstrip("\r\n")
        trecho_atual = linha_sem_fim[entrada["coluna_inicio"]:entrada["coluna_fim"]]
        if trecho_atual != entrada["original"]:
            erros.append(t("rj_linha_mudou").format(
                numero_linha, entrada["coluna_inicio"], entrada["coluna_fim"],
                entrada["original"], trecho_atual
            ))

    if erros:
        return None, erros

    pares_reinjecao, _conflitos_sobreposicao = _resolver_sobreposicoes_mapa(
        entradas_mapa, textos_traduzidos
    )
    por_linha = {}
    for entrada, traduzido in pares_reinjecao:
        por_linha.setdefault(entrada["linha"], []).append((entrada, traduzido))

    linhas_resultado = list(linhas_raw)

    for numero_linha, itens in por_linha.items():
        linha_raw = linhas_resultado[numero_linha - 1]
        linha_sem_fim = linha_raw.rstrip("\r\n")
        fim = linha_raw[len(linha_sem_fim):]

        itens_ordenados = sorted(itens, key=lambda par: par[0]["coluna_inicio"], reverse=True)
        nova_linha = linha_sem_fim
        for entrada, traduzido in itens_ordenados:
            tipo_entrada = entrada.get("tipo")
            # Compatibilidade com mapas antigos: o scanner de versões anteriores
            # podia classificar código Python de poem_responses/py/poems.rpy como
            # multilinha_renpy. Esses trechos jamais devem ser traduzidos/reinjetados.
            # Corpos reais de poema continuam sendo poema_corpo.
            if (_eh_arquivo_banco_poemas_python(caminho_original) and
                    tipo_entrada in ("multilinha_renpy", "monologo_triplas", "gettext_multilinha")):
                original_legado = entrada.get("original", u"")
                codigo_poema_legado = (
                    re.match(r'^\s*poem_db\s*\.\s*add_poem\s*\(', original_legado, re.I) or
                    re.match(r'^\s*author_[A-Za-z0-9_]+\s*,\s*$', original_legado, re.I) or
                    re.match(r'^\s*title\s*=', original_legado, re.I) or
                    re.match(r'^\s*text\s*=', original_legado, re.I) or
                    re.match(r'^\s*translate\s*=', original_legado, re.I) or
                    re.match(r'^\s*"poem_[A-Za-z0-9_]+"\s*,\s*$', original_legado, re.I) or
                    '"""' in original_legado or ('"' * 3) in original_legado
                )
                if codigo_poema_legado:
                    avisos_compat += 1
                    continue
            if tipo_entrada == "poema_corpo":
                traduzido = decodificar_texto_extraido(traduzido)
            elif tipo_entrada in ("multilinha_renpy", "monologo_triplas", "gettext_multilinha"):
                # Esses mapas representam um fragmento físico sem as aspas, pois
                # o literal externo continua aberto no .rpy original.
                traduzido = decodificar_literal_traducao(traduzido)
            elif tipo_entrada == "poema_palavra_txt":
                traduzido = decodificar_literal_traducao(traduzido)
                if '\n' in traduzido or '\r' in traduzido or ',' in traduzido or '#' in traduzido:
                    erros.append(u"Tradução inválida para palavra de poema na linha {0}: o resultado contém vírgula, comentário ou quebra de linha.".format(entrada.get("linha", u"?")))
                    continue
            if traduzido == entrada.get("original"):
                continue
            # Traduzido chega como literal canônico (normalmente entre aspas duplas).
            # Reescrevemos usando o mesmo delimitador/prefixo do literal original.
            if tipo_entrada not in ("poema_palavra_txt", "poema_corpo", "multilinha_renpy", "monologo_triplas", "gettext_multilinha"):
                try:
                    traduzido = codificar_literal_com_formato(entrada.get("original", u'""'), decodificar_literal_traducao(traduzido))
                except Exception:
                    pass
            if tipo_entrada == "poema_palavra_txt":
                nova_linha = (
                    nova_linha[:entrada["coluna_inicio"]]
                    + traduzido
                    + nova_linha[entrada["coluna_fim"]:]
                )
                continue
            if entrada.get("tipo") not in ("poema_corpo", "multilinha_renpy", "monologo_triplas", "gettext_multilinha") and not literal_unico_traduzivel(entrada.get("original", u"")):
                erros.append(u"Mapa inválido: entrada não é um literal único na linha {0}.".format(entrada.get("linha", u"?")))
                continue
            if entrada.get("tipo") in ("multilinha_renpy", "monologo_triplas", "gettext_multilinha"):
                ok_multi, motivo_multi = _validar_fragmento_multilinha_compat(entrada.get("original", u""), traduzido)
                if not ok_multi:
                    if motivo_multi == 'mapa_legado_truncado':
                        avisos_compat += 1
                        continue
                    erros.append(u"Tradução inválida: fragmento multilinha incompatível ({0}) na linha {1}.".format(motivo_multi, entrada.get("linha", u"?")))
                    continue
            elif entrada.get("tipo") != "poema_corpo" and not literal_unico_traduzivel(traduzido):
                erros.append(u"Tradução inválida: resultado contém sintaxe fora do literal na linha {0}.".format(entrada.get("linha", u"?")))
                continue
            traduzido = normalizar_percentuais_para_reintegracao(entrada.get("original", u""), traduzido)
            nova_linha = (
                nova_linha[:entrada["coluna_inicio"]]
                + traduzido
                + nova_linha[entrada["coluna_fim"]:]
            )

        linhas_resultado[numero_linha - 1] = nova_linha + fim

    if avisos_compat:
        print(u"[AVISO] Compatibilidade: {0} fragmento(s) de mapa legado truncado(s) foram preservados no original.".format(avisos_compat))
    return linhas_resultado, erros


def normalizar_nome_pasta_multilingue(nome):
    texto = unicodedata.normalize("NFKD", nome or u"")
    texto = u"".join(ch for ch in texto if not unicodedata.combining(ch))
    texto = texto.casefold().replace(u"_", u"-")
    texto = re.sub(r"[^a-z0-9-]+", u"-", texto)
    texto = re.sub(r"-+", u"-", texto).strip(u"-")
    return texto


PASTAS_DIALOGOS_CATEGORIAS = {
    u"extracao": {
        u"ddac-dialogos-extraidos",
        u"ddac-extracted-dialogues",
    },
    u"traducao": {
        u"ddac-dialogos-traduzidos",
        u"ddac-dialogos-traducidos",
        u"ddac-translated-dialogues",
    },
    u"mesclagem": {
        u"ddac-dialogos-mesclados",
        u"ddac-dialogos-mezclados",
        u"ddac-merged-dialogues",
    },
}


def classificar_pasta_dialogos(caminho):
    normalizado = normalizar_nome_pasta_multilingue(os.path.basename(os.path.normpath(caminho)))
    for categoria, nomes in PASTAS_DIALOGOS_CATEGORIAS.items():
        if normalizado in nomes:
            return categoria
    return None


def listar_pastas_dialogos_por_categoria(raiz, categorias):
    encontrados = []
    vistos = set()
    for nome in os.listdir(raiz):
        caminho = os.path.join(raiz, nome)
        if not os.path.isdir(caminho):
            continue
        categoria = classificar_pasta_dialogos(caminho)
        if categoria not in categorias:
            continue
        chave = os.path.normcase(os.path.normpath(caminho))
        if chave in vistos:
            continue
        nome_mapa = None
        for nome_mapa_candidato in MAPAS_COMPATIVEIS:
            if os.path.isfile(os.path.join(caminho, nome_mapa_candidato)):
                nome_mapa = nome_mapa_candidato
                break
        if nome_mapa:
            vistos.add(chave)
            encontrados.append((caminho, nome_mapa, categoria))
    encontrados.sort(key=lambda item: (0 if item[2] == u"extracao" else 1, normalizar_nome_pasta_multilingue(os.path.basename(item[0]))))
    return encontrados

def localizar_pasta_reinjecao(raiz):
    candidatos = listar_pastas_dialogos_por_categoria(raiz, {u"extracao", u"traducao"})
    if not candidatos:
        return None, None
    if len(candidatos) == 1:
        caminho_unico, nome_mapa_unico, categoria_unica = candidatos[0]
        descricao = t("reinj_tipo_google") if categoria_unica == u"traducao" else t("reinj_tipo_manual")
        print(u"")
        print(u"============================================================")
        print(u" {}".format(t("reinj_selecao_titulo")))
        print(u"============================================================")
        print(u"")
        print(u"  Uma única fonte compatível foi encontrada; seleção automática.")
        print(u"  Fonte: {}".format(descricao))
        print(u"  Pasta: {}".format(os.path.basename(caminho_unico)))
        print(u"  Caminho: {}".format(caminho_unico))
        print(u"  Iniciando a reintegração automaticamente...")
        return caminho_unico, nome_mapa_unico

    print(u"")
    print(u"============================================================")
    print(u" {}".format(t("reinj_selecao_titulo")))
    print(u"============================================================")
    print(u"")
    for i, (caminho, nome_mapa, categoria) in enumerate(candidatos, 1):
        if categoria == u"traducao":
            descricao = t("reinj_tipo_google")
        else:
            descricao = t("reinj_tipo_manual")
        print(t("reinj_selecao_item").format(i, descricao))
        print(t("reinj_selecao_pasta").format(os.path.basename(caminho)))
        print(t("reinj_selecao_caminho").format(caminho))
        print(u"")
    while True:
        try:
            escolha = input(t("reinj_selecao_prompt")).strip()
        except (EOFError, KeyboardInterrupt):
            return None, None
        if escolha.isdigit():
            indice = int(escolha) - 1
            if 0 <= indice < len(candidatos):
                return candidatos[indice][0], candidatos[indice][1]
        print(t("reinj_selecao_invalida"))


# =============================================================================
# GOOGLE TRANSLATE
# =============================================================================
#
# Objetivo desta versão (v40):
#   - poucos workers I/O simultâneos dentro de cada arquivo (padrão seguro);
#   - cada worker possui sua própria sessão Google RPC;
#   - cache temporario por execucao, por origem + destino + texto;
#   - ritmo global (GOOGLE_THROTTLE) com intervalo mínimo entre QUALQUER
#     requisição, de qualquer worker -- evita rajadas que derrubam o IP;
#   - ao levar um 429 (limite do Google), TODOS os workers pausam juntos por
#     um cooldown crescente (backoff exponencial), em vez de insistir na hora;
#   - barra de progresso no console sem inundar a tela;
#   - o arquivo atual termina antes de o próximo começar.
# -----------------------------------------------------------------------------
try:
    import http.cookiejar
except ImportError:
    import cookielib as cookiejar_compat
else:
    cookiejar_compat = http.cookiejar

GOOGLE_HOSTS = (
    (u"google.com", u"https://translate.google.com"),
    (u"google.com.br", u"https://translate.google.com.br"),
    (u"google.co.uk", u"https://translate.google.co.uk"),
)
GOOGLE_RPC_ID = u"MkEWBc"
GOOGLE_STATIC_BL = u"boq_translate-webserver_20201207.13_p0"
GOOGLE_TIMEOUT = 15
GOOGLE_WORKERS = 5
GOOGLE_SCHEDULER_CHUNK = 50
GOOGLE_JOB_WINDOW_MULTIPLIER = 20
GOOGLE_RETRIES = 2
GOOGLE_RESIDUAL_RETRIES = 1
# Intervalo mínimo (segundos) entre QUALQUER requisição de tradução, não
# importa o worker -- é o que evita a rajada que derrubou o IP antes.
GOOGLE_INTERVALO_MINIMO = 0.30
# Cooldown aplicado a TODOS os workers assim que qualquer um deles leva um
# 429. Cresce a cada 429 seguido (backoff exponencial) e volta ao valor
# inicial depois de um tempo sem bloqueios.
GOOGLE_BACKOFF_INICIAL = 6.0
GOOGLE_BACKOFF_MAXIMO = 90.0
GOOGLE_BACKOFF_MULTIPLICADOR = 2.0
GOOGLE_CACHE_SCHEMA = 13
GOOGLE_CACHE_NOME = u"UnRen-DDAC-Google-Translate-rpc-cache-temp.json"
GOOGLE_CACHE_PERSISTENTE_DIR = NOMES_CACHE_PERSISTENTE_DIR_IDIOMA.get(1)
GOOGLE_CACHE_DIAGNOSTICO_NOME = NOMES_DIAGNOSTICO_IDIOMA.get(1)
GOOGLE_CACHE_ESTRESSE_NOME = NOMES_DIAGNOSTICO_ESTRESSE_IDIOMA.get(1)
GOOGLE_CACHE_PERSISTENTE_NOME = u"Google-Translate-rpc-v1.json"
GOOGLE_CACHE_MOTOR_ID = u"rpc-v1"
GOOGLE_CACHE_CREDITOS_MOTOR_ID = u"rpc-v1-credit-v2"
# Em arquivos grandes, regravar o JSON inteiro do cache a cada 25 itens gera I/O
# desnecessário. Salvamos em blocos maiores e continuamos salvando ao final de
# cada arquivo e imediatamente diante de erros, preservando a retomada.
GOOGLE_CACHE_SAVE_A_CADA = 100
GOOGLE_CACHE_PERSISTENTE_SAVE_A_CADA = 250
# O cache de retomada é diferente do cache persistente: ele precisa ser
# atualizado durante a execução, mas não a cada texto. Regravar um JSON inteiro
# depois de cada conclusão gera I/O crescente e pode paralisar a fila no final.
GOOGLE_CACHE_TEMP_SAVE_A_CADA = 25
GOOGLE_HEARTBEAT_SEGUNDOS = 5.0
# Calibração temporária do limite: 0,30s já foi confirmado anteriormente em
# duas rodadas completas; o teste de estresse começa no próximo degrau.
GOOGLE_DIAGNOSTICO_ESTRESSE_LOTE = 180
GOOGLE_DIAGNOSTICO_ESTRESSE_INTERVALOS = (0.25, 0.20, 0.15, 0.10)
GOOGLE_DIAGNOSTICO_ESTRESSE_BASELINE = 0.30

LANGUAGE_ALIASES = {
    "auto": "auto", "automatico": "auto", "automático": "auto", "automatic": "auto",
    "ptbr": "pt-BR", "pt-br": "pt-BR", "pt_br": "pt-BR", "pt brasil": "pt-BR",
    "portugues brasil": "pt-BR", "português brasil": "pt-BR", "brazilian portuguese": "pt-BR", "portuguese brazil": "pt-BR",
    "pt": "pt", "portugues": "pt", "português": "pt", "portuguese": "pt",
    "ptpt": "pt-PT", "pt-pt": "pt-PT", "portugal": "pt-PT", "português portugal": "pt-PT", "portuguese portugal": "pt-PT",
    "en": "en", "ingles": "en", "inglês": "en", "english": "en",
    "es": "es", "espanhol": "es", "español": "es", "spanish": "es",
    "fr": "fr", "frances": "fr", "francês": "fr", "french": "fr",
    "de": "de", "alemao": "de", "alemão": "de", "german": "de",
    "it": "it", "italiano": "it", "italian": "it",
    "ja": "ja", "japones": "ja", "japonês": "ja", "japanese": "ja",
    "ko": "ko", "coreano": "ko", "korean": "ko",
    "zh": "zh-CN", "zh-cn": "zh-CN", "chines": "zh-CN", "chinês": "zh-CN", "chinese": "zh-CN",
    "ru": "ru", "russo": "ru", "russian": "ru",
    "tr": "tr", "turco": "tr", "turkish": "tr",
    "uk": "uk", "ucraniano": "uk", "ukrainian": "uk",
    "pl": "pl", "polones": "pl", "polonês": "pl", "polish": "pl",
    "nl": "nl", "holandes": "nl", "holandês": "nl", "dutch": "nl",
    "ar": "ar", "arabe": "ar", "árabe": "ar", "arabic": "ar",
    "hi": "hi", "hindi": "hi",
    "vi": "vi", "vietnamita": "vi", "vietnamese": "vi",
    "id": "id", "indonesio": "id", "indonésio": "id", "indonesian": "id",
}

# Protege percentuais/formatos que já existem no texto original.
# Não inclui o espaço como flag de formato: em texto natural, sequências como
# `100% com` devem ser tratadas como um percentual literal e não como `%c`.
# A etapa de reintegração também protege qualquer sequência percentual original
# antes de escapar percentuais novos introduzidos pela tradução.
# Nomes canônicos das quatro personagens principais são protegidos globalmente
# em qualquer texto enviado ao Google; nunca devem ser traduzidos. O limite
# inclui '_' para não capturar identificadores como sayori_route.
TOKEN_PROTECAO_RE = re.compile(
    r'\r\n|\n|\r|https?://\S+|(?:[A-Za-z0-9_.-]+[\\/])*[A-Za-z0-9_.-]+\.(?:png|jpg|jpeg|gif|webp|webm|ogg|mp3|wav|flac|m4a|ttf|otf|ttc|rpy|rpyc|rpa|dll|so|exe|bin|json|py|pyc)(?![A-Za-z0-9_.-])|\\.|\{[^}\r\n]*\}|(?<![A-Za-zÀ-ÿ_])(Sayori|Monika|Natsuki|Yuri)(?![A-Za-zÀ-ÿ_])|%%|%(?:\([^)]*\))?[#0\-+]*(?:\*|\d+)?(?:\.(?:\*|\d+))?(?:[hlL])?[A-Za-z]'
)
PERCENTUAL_ORIGINAL_RE = re.compile(
    r'\\%|%%|%(?:\([^)]*\))?[#0\-+]*(?:\*|\d+)?(?:\.(?:\*|\d+))?(?:[hlL])?[A-Za-z]'
)


def normalizar_idioma_codigo(valor, padrao):
    texto = (valor or u"").strip()
    chave = texto.lower().replace(u"_", u"-")
    return LANGUAGE_ALIASES.get(chave, texto or padrao)


def validar_codigo_idioma(valor):
    return bool(re.match(r'^[A-Za-z]{2,3}(?:-[A-Za-z]{2,4})?$', valor) or valor == u"auto")


def decodificar_literal_traducao(literal):
    valor = literal.strip()
    # Backtick é string Ren'Py direta, mas não é string Python.
    bruto = valor[1:] if len(valor) >= 3 and valor[0] in 'rR' and valor[1] in ('"', "'", '`') else valor
    if len(bruto) >= 2 and bruto[0] == '`' and bruto[-1] == '`':
        interior = bruto[1:-1]
        return (interior.replace(u'\\`', u'`')
                        .replace(u'\\\\', u'\\')
                        .replace(u'\\n', u'\n')
                        .replace(u'\\r', u'\r')
                        .replace(u'\\t', u'\t'))
    try:
        with warnings.catch_warnings():
            warnings.filterwarnings("ignore", message=r"invalid escape sequence.*", category=SyntaxWarning)
            resultado = ast.literal_eval(valor)
        if isinstance(resultado, str):
            return resultado
    except Exception:
        pass
    return strip_quotes(valor)

def codificar_literal_com_formato(original_literal, texto):
    """Reescreve o texto usando o mesmo delimitador/prefixo da string original."""
    original = (original_literal or u'').strip()
    raw = len(original) >= 3 and original[0] in 'rR' and original[1] in ('"', "'", '`') and original[-1] == original[1]
    quote = original[1] if raw else (original[0] if original[:1] in ('"', "'", '`') else '"')
    prefixo = original[0] if raw else u''
    if raw:
        body = texto.replace(quote, u'\\' + quote)
        return prefixo + quote + body + quote
    body = texto.replace(u'\\', u'\\\\').replace(u'\r', u'\\r').replace(u'\n', u'\\n').replace(u'\t', u'\\t')
    body = body.replace(quote, u'\\' + quote)
    return quote + body + quote


def codificar_literal_traducao(texto):
    partes = [u'"']
    i = 0
    while i < len(texto):
        ch = texto[i]
        if ch == u'\\':
            if i + 1 < len(texto) and texto[i + 1] in (u'%', u'[', u'{', u' '):
                partes.append(u'\\')
            else:
                partes.append(u'\\\\')
        elif ch == u'"':
            partes.append(u'\\"')
        elif ch == u'\n':
            partes.append(u'\\n')
        elif ch == u'\r':
            partes.append(u'\\r')
        elif ch == u'\t':
            partes.append(u'\\t')
        else:
            partes.append(ch)
        i += 1
    partes.append(u'"')
    return u"".join(partes)


def _intervalos_tokens_google(texto):
    """Retorna tokens protegíveis em ordem, incluindo interpolação [] aninhada."""
    intervalos=[]
    for m in TOKEN_PROTECAO_RE.finditer(texto):
        intervalos.append((m.start(), m.end(), m.group(0)))
    for a,b in _iter_intervalos_brackets_balanceados(texto):
        intervalos.append((a,b,texto[a:b]))
    intervalos.sort(key=lambda x:(x[0], -(x[1]-x[0])))
    resultado=[]; ultimo=-1
    for a,b,raw in intervalos:
        if a < ultimo:
            continue
        resultado.append((a,b,raw)); ultimo=b
    return resultado


# Termos e estruturas que permanecem no idioma original quando fazem parte de
# frases traduzíveis. Créditos não são descartados: somente as categorias/roles
# são traduzidas; pessoas, artistas, handles, títulos e recursos permanecem.
TERMOS_NAO_TRADUZIR_GOOGLE = (
    u"Doki Doki Literature Club", u"Team Salvato", u"Steam", u"Twitch",
    u"Discord", u"YouTube", u"Ren'Py", u"GitHub", u"Patreon", u"itch.io",
)
_RE_TERMOS_NAO_TRADUZIR_GOOGLE = re.compile(
    u"|".join(re.escape(x) for x in sorted(TERMOS_NAO_TRADUZIR_GOOGLE, key=len, reverse=True)), re.I
)

# Vocabulário global de categorias/roles de créditos. Não identifica nomes de
# pessoas: a tradução só é aplicada quando a linha termina em ':' ou é uma
# função curta conhecida. Assim "Casual Monika: DestinyPVEGal" permanece intacto.
CREDITOS_CATEGORIAS_TRADUZIVEIS = frozenset((
    u"credit", u"credits", u"acknowledgements", u"acknowledgments", u"special thanks",
    u"song covers", u"music credits", u"soundtrack", u"misc sound effects", u"sound effects",
    u"mod resources", u"mod resource", u"sprites", u"backgrounds", u"backgrounds art",
    u"playtesters", u"playtester", u"flower moon logo", u"ending cg", u"ending",
    u"writing", u"music", u"coding", u"coder", u"coders", u"programming", u"programmer",
    u"programmers", u"translation", u"translations", u"translator", u"translators",
    u"editing", u"editor", u"editors", u"proofreading", u"proofreader", u"artist", u"artists",
    u"art", u"artwork", u"animation", u"animator", u"animators", u"voice acting",
    u"voice actor", u"voice actors", u"voices", u"voice", u"composer", u"composers",
    u"sound design", u"sound designer", u"design", u"designer", u"designers", u"development",
    u"development team", u"developer", u"developers", u"team", u"staff", u"author", u"authors",
    u"contributors", u"contributor", u"tester", u"testers", u"fonts", u"font", u"assets",
    u"mod assets", u"resources", u"resource", u"logo", u"logos", u"illustration", u"illustrations",
    u"cg", u"cgs", u"thanks", u"special thanks", u"visuals", u"visual art", u"gui", u"ui",
    u"interface", u"interface design", u"effects", u"sound effects", u"music", u"credits"
))
CREDITOS_PREFIXOS_CATEGORIA = (
    u"song ", u"music ", u"sound ", u"misc ", u"mod ", u"special ", u"voice ",
    u"background", u"sprite", u"playtest", u"ending ", u"flower moon ", u"writing",
    u"coding", u"program", u"translat", u"edit", u"proof", u"artist", u"art",
    u"animation", u"animator", u"development", u"developer", u"resource", u"asset",
    u"credit", u"acknowledg", u"thanks", u"staff", u"team", u"author", u"contributor"
)

_RE_URL_CREDITOS = re.compile(r'https?://|www\\.', re.I)

def _normalizar_linha_credito(texto):
    return u" ".join(texto_compativel(texto, u"").strip().lower().split())

def _rotulo_credito_eh_categoria(label):
    normal = _normalizar_linha_credito(label).rstrip(':').strip()
    if not normal or len(normal) > 80:
        return False
    if _RE_URL_CREDITOS.search(normal):
        return False
    if normal in CREDITOS_CATEGORIAS_TRADUZIVEIS:
        return True
    palavras = [p for p in re.split(r'[^a-z0-9À-ÿ]+', normal) if p]
    if len(palavras) > 6:
        return False
    # Um cabeçalho só é traduzido quando contém vocabulário inequívoco de
    # créditos; nomes próprios terminados em ':' não entram por engano.
    return any(normal.startswith(prefixo) or palavra in normal for prefixo in CREDITOS_PREFIXOS_CATEGORIA for palavra in (prefixo.strip(),))
def _linha_credito_role_eh_categoria(line):
    normal = _normalizar_linha_credito(line)
    return normal in CREDITOS_CATEGORIAS_TRADUZIVEIS and len(normal) <= 40

def parece_bloco_creditos_google(texto, rel=u"", tipo=u""):
    texto = texto_compativel(texto, u"")
    rel_norm = texto_compativel(rel, u"").replace('\\','/').lower()
    linhas = texto.splitlines()
    if len(linhas) < 2:
        return False
    for linha in linhas:
        body = linha.strip()
        if not body:
            continue
        if body.endswith(':') and _rotulo_credito_eh_categoria(body[:-1]):
            return True
        if _linha_credito_role_eh_categoria(body):
            return True
    # Arquivos/seções explicitamente de créditos ainda precisam de um rótulo
    # reconhecível; o nome do arquivo sozinho não transforma todo o conteúdo em
    # crédito.
    if 'credit' in os.path.basename(rel_norm) or 'acknowledg' in os.path.basename(rel_norm):
        return any((l.strip().endswith(':') and len(l.strip()) <= 80) for l in linhas)
    return False

def _traduzir_fragmento_credito_google(cliente, fragmento, origem, destino):
    fragmento = texto_compativel(fragmento, u"")
    protegido, tokens = proteger_tokens_google(fragmento)
    origem_google = origem
    if origem == u"auto" and destino.lower().startswith(u"pt") and fonte_parece_inglesa_google(fragmento):
        origem_google = u"en"
    bruto = cliente.traduzir(protegido, origem_google, destino)
    validar_tokens_google_preservados(bruto, tokens)
    bruto = escapar_percentuais_novos_google(bruto)
    return restaurar_tokens_google(bruto, tokens)

def traduzir_bloco_creditos_google(cliente, texto, origem, destino):
    """Traduz somente rótulos/roles dentro de um bloco de créditos.

    Nomes de pessoas, handles, títulos de músicas, recursos e descrições após o
    cabeçalho permanecem literalmente iguais. Retorna None quando não parece um
    bloco de créditos reconhecível.
    """
    texto = texto_compativel(texto, u"")
    if not parece_bloco_creditos_google(texto, u"", u""):
        return None
    partes = texto.splitlines(True)
    saida=[]
    alterou=False
    categorias_encontradas=0
    for parte in partes:
        corpo = parte.rstrip('\r\n')
        final = parte[len(corpo):]
        if not corpo.strip():
            saida.append(parte); continue
        esquerda = corpo[:len(corpo)-len(corpo.lstrip())]
        direita = corpo[len(corpo.rstrip()):]
        centro = corpo.strip()
        traduzir_label = False
        modo = 'header'
        if centro.endswith(':') and _rotulo_credito_eh_categoria(centro[:-1]):
            traduzir_label = True
        elif _linha_credito_role_eh_categoria(centro):
            traduzir_label = True
            modo = 'role'
        elif re.match(r'^(?:made with|copyright(?:\\s|$)|all rights reserved)', centro, re.I):
            # Frases de licença/copyright podem ser traduzidas normalmente; os
            # nomes/marcas/URLs conhecidos permanecem protegidos.
            traduzir_label = True
            modo = 'sentence'
        if traduzir_label:
            categorias_encontradas += 1
            try:
                if modo == 'header':
                    label = centro[:-1].rstrip()
                    traduzido = _traduzir_fragmento_credito_google(cliente, label, origem, destino)
                    novo = esquerda + traduzido.strip() + ':' + direita + final
                else:
                    traduzido = _traduzir_fragmento_credito_google(cliente, centro, origem, destino)
                    novo = esquerda + traduzido.strip() + direita + final
                if novo != parte:
                    alterou=True
                saida.append(novo)
            except Exception:
                raise
        else:
            saida.append(parte)
    if not categorias_encontradas or not alterou:
        return texto
    resultado = u''.join(saida)
    validar_integridade_traducao_google(texto, resultado)
    validar_termos_protegidos_google(texto, resultado)
    return resultado

def _ocorrencias_termos_protegidos_google(texto):
    texto = texto_compativel(texto, u"")
    return list(_RE_TERMOS_NAO_TRADUZIR_GOOGLE.finditer(texto))

def validar_termos_protegidos_google(original, traducao):
    original = texto_compativel(original, u"")
    traducao = texto_compativel(traducao, u"")
    for termo in TERMOS_NAO_TRADUZIR_GOOGLE:
        n_origem = len(re.findall(re.escape(termo), original, flags=re.I))
        if not n_origem:
            continue
        n_saida = len(re.findall(re.escape(termo), traducao, flags=re.I))
        if n_saida != n_origem:
            raise GoogleTranslateValidationError(u"termo protegido alterado/removido: {0}".format(termo))

def entrada_nao_traduzivel_google(texto, rel=u"", tipo=u""):
    # Créditos e avisos de copyright NÃO são descartados. O tradutor trabalha
    # por partes e protege nomes/marcas, permitindo traduzir as categorias.
    return False

def proteger_tokens_google(texto):
    tokens=[]; partes=[]; pos=0
    intervalos=list(_intervalos_tokens_google(texto))
    for m in _ocorrencias_termos_protegidos_google(texto):
        intervalos.append((m.start(), m.end(), m.group(0)))
    intervalos.sort(key=lambda item:(item[0], -(item[1]-item[0])))
    for a,b,raw in intervalos:
        if a < pos:
            continue
        partes.append(texto[pos:a])
        token=u"DDACZ{:04d}Q".format(len(tokens))
        tokens.append((token,raw))
        partes.append(token); pos=b
    partes.append(texto[pos:])
    return u"".join(partes), tokens


def restaurar_tokens_google(texto, tokens):
    resultado = texto
    for token, original in tokens:
        resultado = resultado.replace(token, original)
        resultado = resultado.replace(token.lower(), original)
    return resultado


def escapar_percentuais_novos_google(texto):
    """Torna seguros os percentuais que não vieram protegidos do original.

    Um único `%` pode virar operador de formatação no Ren'Py quando o texto
    passa pelo mecanismo `what % tag_quoting_dict`. Percentuais em pares (`%%`)
    já são seguros e permanecem como estão. Runs ímpares recebem um `%` extra.
    """
    def repl(m):
        bruto = m.group(0)
        return bruto if len(bruto) % 2 == 0 else bruto + u"%"
    return re.sub(r"%+", repl, texto)


def normalizar_percentuais_para_reintegracao(original, traduzido):
    """Preserva percentuais que existiam no original e escapa os novos.

    Também funciona para cache/arquivos de tradução produzidos por versões
    anteriores, evitando que um `%` literal recém-introduzido chegue ao código
    do jogo sem `%%`. Percentuais originais como `%s` e formatos de data `%A`
    são mantidos exatamente.
    """
    if traduzido == original:
        return traduzido

    tokens = []
    protegido = traduzido
    for m in PERCENTUAL_ORIGINAL_RE.finditer(original):
        bruto = m.group(0)
        token = u"DDACP{:04d}Q".format(len(tokens))
        pos = protegido.find(bruto)
        if pos < 0:
            continue
        tokens.append((token, bruto))
        protegido = protegido[:pos] + token + protegido[pos + len(bruto):]

    protegido = escapar_percentuais_novos_google(protegido)
    for token, bruto in tokens:
        protegido = protegido.replace(token, bruto)
    return protegido


TAG_PARES_GOOGLE_RE = re.compile(
    r'(\{([A-Za-z_][\w.-]*)(?:=[^}\r\n]*)?\})(.*?)\{/\2\}',
    re.I | re.S
)


def texto_visivel_tag_google(texto):
    texto = texto_compativel(texto, u"")
    valor = re.sub(r'\{[^}\r\n]*\}|\[[^]\r\n]*\]', u'', texto)
    valor = valor.replace(u'\\n', u' ').replace(u'\\r', u' ').replace(u'\\t', u' ')
    return re.sub(r'\s+', u'', valor)


def validar_integridade_traducao_google(original, traducao):
    if not isinstance(original, TEXT_TYPES) or not isinstance(traducao, TEXT_TYPES):
        raise GoogleTranslateValidationError(u"resultado de tradução não é texto")
    if original.strip() and not traducao.strip():
        raise GoogleTranslateValidationError(u'tradução retornou texto vazio')
    validar_termos_protegidos_google(original, traducao)
    pares_orig = list(TAG_PARES_GOOGLE_RE.finditer(original))
    pares_trad = list(TAG_PARES_GOOGLE_RE.finditer(traducao))
    if len(pares_orig) != len(pares_trad):
        raise GoogleTranslateValidationError(
            u'quantidade de tags pareadas alterada ({0} -> {1})'.format(len(pares_orig), len(pares_trad))
        )
    for par_orig, par_trad in zip(pares_orig, pares_trad):
        if par_orig.group(2).lower() != par_trad.group(2).lower():
            raise GoogleTranslateValidationError(u'tipo de tag alterado durante a tradução')
        if texto_visivel_tag_google(par_orig.group(3)) and not texto_visivel_tag_google(par_trad.group(3)):
            raise GoogleTranslateValidationError(u'texto visível dentro de tag foi apagado pela tradução')


PORTUGUES_ALTO_SINAL = frozenset({
    u"eu", u"você", u"voce", u"ele", u"ela", u"eles", u"elas", u"nós", u"nos",
    u"meu", u"minha", u"meus", u"minhas", u"seu", u"sua", u"seus", u"suas",
    u"do", u"da", u"dos", u"das", u"de", u"em", u"na", u"nas", u"nos",
    u"para", u"por", u"com", u"sem", u"sobre", u"entre", u"até", u"ate",
    u"que", u"não", u"nao", u"sim", u"já", u"ja", u"aqui", u"ali",
    u"isso", u"isto", u"aquilo", u"esse", u"essa", u"este", u"esta", u"esses", u"essas",
    u"está", u"esta", u"são", u"sao", u"foi", u"vai", u"vou", u"vamos",
    u"tem", u"tenho", u"temos", u"têm", u"têm", u"quero", u"quer", u"pode", u"posso",
    u"acho", u"sei", u"sabe", u"fazer", u"feito", u"muito", u"pouco", u"mais", u"menos",
    u"porque", u"como", u"quando", u"onde", u"quem", u"qual", u"qualquer", u"também", u"tambem",
    u"agora", u"depois", u"antes", u"sempre", u"nunca", u"mesmo", u"mesma",
    u"estava", u"estavam", u"estou", u"estamos", u"estão", u"estao", u"ser", u"estar",
    u"tocando", u"tocando", u"trilha", u"sonora", u"versão", u"versao", u"jogabilidade",
    u"indisponível", u"indisponivel", u"selecionar", u"selecionado", u"configurações", u"configuracoes",
})


ENGLISH_HIGH_CONFIDENCE = frozenset({
    u"took", u"screenshot", u"quick", u"complete", u"message",
    u"save", u"load", u"back", u"next", u"skip", u"continue", u"settings",
    u"preferences", u"history", u"cancel", u"delete", u"confirm", u"type",
    u"file", u"files", u"close", u"open", u"start", u"end", u"return",
    u"remove", u"reset", u"option", u"page", u"help", u"game", u"story",
    u"school", u"student", u"friend", u"friends", u"conversation", u"situation",
})


def fonte_parece_inglesa_google(texto):
    """Heurística conservadora para reconhecer fonte realmente inglesa."""
    valor = texto_compativel(texto, u"")
    valor = re.sub(r"\{[^}\r\n]*\}|\[[^]\r\n]*\]", u" ", valor)
    valor = re.sub(r"https?://\S+", u" ", valor, flags=re.I)
    palavras = re.findall(r"[A-Za-zÀ-ÿ]+(?:['’][A-Za-zÀ-ÿ]+)?", valor.lower())
    if not palavras:
        return False
    # Marcadores portugueses vencem evidência inglesa isolada. Isso evita que
    # títulos de músicas, créditos ou frases mistas já traduzidas sejam marcados.
    pt = sum(1 for p in palavras if p in PORTUGUES_ALTO_SINAL)
    if pt >= 1:
        return False
    if any(p in ENGLISH_RETRY_CONTRACTIONS for p in palavras):
        return True
    # Uma palavra UI de alta confiança (Save, Load, Screenshot etc.) pode ser inglesa sozinha.
    if len(palavras) == 1:
        return palavras[0] in ENGLISH_HIGH_CONFIDENCE
    distintivas = sum(1 for p in palavras if p in ENGLISH_RETRY_DISTINCTIVE or p in ENGLISH_HIGH_CONFIDENCE)
    comuns = sum(1 for p in palavras if p in ENGLISH_RETRY_COMMON)
    dicas = sum(1 for p in palavras if p in EQUAL_TRANSLATION_ENGLISH_HINTS)
    if distintivas >= 2:
        return True
    if distintivas >= 1 and comuns >= 1:
        return True
    if dicas >= 2 and len(palavras) <= 8:
        return True
    return len(palavras) >= 4 and comuns >= 3 and pt == 0


def validar_resultado_traducao_google(original, traducao, tipo_entrada, origem, destino):
    """Impede que inglês claramente não traduzido seja contado como sucesso."""
    original = texto_compativel(original, u"")
    traducao = texto_compativel(traducao, u"")
    tipo_entrada = texto_compativel(tipo_entrada, u"")
    origem = texto_compativel(origem, u"auto")
    destino = texto_compativel(destino, u"pt-BR")
    validar_integridade_traducao_google(original, traducao)
    if not isinstance(original, TEXT_TYPES) or not isinstance(traducao, TEXT_TYPES):
        raise GoogleTranslateValidationError(u"resultado de tradução não é texto")
    if not destino or not destino.lower().startswith(u"pt"):
        return
    tipo = tipo_entrada or u""
    tipos_textuais = {
        u"dialogo", u"renpy_nativo_dialogo", u"renpy_nativo_string",
        u"narrativa", u"ui", u"poema_corpo", u"poema_palavra", u"poema_palavra_txt",
        u"nome_grupo", u"variavel_texto",
    }
    if tipo not in tipos_textuais:
        return
    # Se a saída for exatamente uma correção determinística cadastrada pelo DDAC,
    # ela já foi revisada pelo próprio projeto. Não a rejeitar pelo detector de
    # inglês residual por conter nomes próprios, títulos, créditos ou marcas.
    for regra in globals().get(u"CORRECOES_INDIVIDUAIS_GOOGLE", []):
        if regra.get(u"origem") == original and regra.get(u"traducao") == traducao:
            return
    fonte = (original or u"").strip()
    saida = (traducao or u"").strip()
    origem_lower = (origem or u"auto").lower()
    fonte_inglesa = fonte_parece_inglesa_google(fonte)
    if not fonte_inglesa:
        return
    if saida == fonte and (origem_lower == u"auto" or origem_lower.startswith(u"en")):
        raise GoogleTranslateValidationError(u"Google devolveu o texto original em inglês sem tradução para PT-BR")
    if parece_residuo_ingles_resultado(fonte, saida, tipo):
        raise GoogleTranslateValidationError(u"resultado contém inglês residual após a tradução para PT-BR")


def reparar_conteudo_tag_vazio_google(original, traducao, cliente, origem, destino):
    pares_orig = list(TAG_PARES_GOOGLE_RE.finditer(original))
    pares_trad = list(TAG_PARES_GOOGLE_RE.finditer(traducao))
    if len(pares_orig) != len(pares_trad):
        return None
    partes = []
    pos = 0
    alterou = False
    for porig, ptrad in zip(pares_orig, pares_trad):
        if porig.group(2).lower() != ptrad.group(2).lower():
            return None
        partes.append(traducao[pos:ptrad.start(3)])
        interior_orig = porig.group(3)
        interior_trad = ptrad.group(3)
        if texto_visivel_tag_google(interior_orig) and not texto_visivel_tag_google(interior_trad):
            # Traduz somente o conteúdo que o Google apagou, preservando a tag
            # externa já traduzida e os tokens internos.
            protegido, tokens = proteger_tokens_google(interior_orig)
            reparado = cliente.traduzir(protegido, origem, destino)
            validar_tokens_google_preservados(reparado, tokens)
            reparado = escapar_percentuais_novos_google(reparado)
            reparado = restaurar_tokens_google(reparado, tokens)
            partes.append(reparado)
            alterou = True
        else:
            partes.append(interior_trad)
        pos = ptrad.end(3)
        partes.append(traducao[pos:ptrad.end()])
        pos = ptrad.end()
    partes.append(traducao[pos:])
    return u"".join(partes) if alterou else None


def adicionar_marcadores_tags_google(texto):
    contador = [0]
    def repl(m):
        conteudo = m.group(3)
        if not texto_visivel_tag_google(conteudo):
            return m.group(0)
        n = contador[0]
        contador[0] += 1
        inicio = u'DDACM{:04d}Q'.format(n * 2)
        fim = u'DDACM{:04d}Q'.format(n * 2 + 1)
        return m.group(1) + inicio + conteudo + fim + u'{/' + m.group(2) + u'}'
    return TAG_PARES_GOOGLE_RE.sub(repl, texto)


def remover_marcadores_tags_google(texto):
    return re.sub(r'DDACM\d{4}Q', u'', texto, flags=re.I)


def validar_tokens_google_preservados(texto, tokens):
    # A presença individual não basta: o tradutor pode duplicar ou reordenar
    # tokens sem removê-los. A sequência devolvida deve ser idêntica à esperada.
    esperado = [token.lower() for token, _ in tokens]
    encontrados = [token.lower() for token in re.findall(r'DDACZ\d{4}Q', texto, re.I)]

    if encontrados != esperado:
        if not encontrados:
            raise GoogleTranslateValidationError(u'tokens protegidos foram removidos pela tradução')
        if len(encontrados) != len(esperado):
            raise GoogleTranslateValidationError(
                u'sequência de tokens protegidos alterada: quantidade esperada {0}, recebida {1}'.format(
                    len(esperado), len(encontrados)))
        raise GoogleTranslateValidationError(u'sequência de tokens protegidos alterada: ordem/duplicação detectada')


def traduzir_por_fragmentos_sem_tokens_google(cliente, texto, origem, destino):
    """Fallback quando o Google elimina placeholders opacos."""
    partes = []
    pos = 0
    encontrou_token = False
    for m in TOKEN_PROTECAO_RE.finditer(texto):
        encontrou_token = True
        fragmento = texto[pos:m.start()]
        if fragmento:
            if re.search(r"[^\W\d_]", fragmento, re.UNICODE):
                partes.append(cliente.traduzir(fragmento, origem, destino))
            else:
                partes.append(fragmento)
        partes.append(m.group(0))
        pos = m.end()
    final = texto[pos:]
    if final:
        if re.search(r"[^\W\d_]", final, re.UNICODE):
            partes.append(cliente.traduzir(final, origem, destino))
        else:
            partes.append(final)
    if not encontrou_token:
        return None
    resultado = u"".join(partes)
    resultado = escapar_percentuais_novos_google(resultado)
    validar_integridade_traducao_google(texto, resultado)
    return resultado


def extrair_payload_rpc_google(bruto):
    # batchexecute returns framed JSON; locate the first complete frame that contains MkEWBc.
    for linha_idx, linha in enumerate(bruto.split(u"\n")):
        if u'"' + GOOGLE_RPC_ID + u'"' not in linha[:200]:
            continue
        resp = u""
        abertura = fechamento = 0
        em_string = False
        escapado = False
        for linha2 in bruto.split(u"\n")[linha_idx:]:
            resp += linha2
            for char in linha2:
                if char == u'"' and not escapado:
                    em_string = not em_string
                if not em_string:
                    if char == u"[": abertura += 1
                    elif char == u"]": fechamento += 1
                escapado = (char == u"\\" and not escapado)
                if char != u"\\": escapado = False
            if abertura and abertura == fechamento:
                break
            resp += u"\n"
        if not resp:
            continue
        try:
            envelope = json.loads(resp)
            if isinstance(envelope, list) and envelope and isinstance(envelope[0], list) and len(envelope[0]) >= 3:
                raw = envelope[0][2]
                return json.loads(raw) if isinstance(raw, str) else raw
        except Exception:
            continue
    raise ValueError(u"estrutura RPC do Google não reconhecida")


def _procurar_traducao_rpc_google(obj):
    if isinstance(obj, list):
        if len(obj) > 5 and isinstance(obj[5], list):
            valores = [p[0] for p in obj[5] if isinstance(p, list) and p and isinstance(p[0], TEXT_TYPES) and p[0]]
            if valores:
                separador = u" " if len(obj) > 3 and obj[3] else u""
                return separador.join(valores)
        for item in obj:
            resultado = _procurar_traducao_rpc_google(item)
            if resultado:
                return resultado
    elif isinstance(obj, dict):
        for item in obj.values():
            resultado = _procurar_traducao_rpc_google(item)
            if resultado:
                return resultado
    return None


def extrair_traducao_rpc_google(payload):
    try:
        bloco = payload[1][0][0]
        if isinstance(bloco, list) and len(bloco) > 5 and isinstance(bloco[5], list):
            valores = [p[0] for p in bloco[5] if isinstance(p, list) and p and isinstance(p[0], str)]
            if valores:
                return (u" " if len(bloco) > 3 and bloco[3] else u"").join(valores)
        if isinstance(bloco, list) and bloco and isinstance(bloco[0], str) and bloco[0]:
            return bloco[0]
    except Exception:
        pass
    resultado = _procurar_traducao_rpc_google(payload)
    if resultado:
        return resultado
    raise ValueError(u"estrutura RPC de tradução não reconhecida")


class GoogleTranslateError(RuntimeError):
    pass


class GoogleTranslateValidationError(GoogleTranslateError):
    pass


class GoogleRateLimitError(GoogleTranslateError):
    pass


class GoogleThrottle(object):
    """Ritmo global compartilhado por todos os workers do pool Google.

    Duas responsabilidades:
      1) Garantir um intervalo mínimo entre QUALQUER requisição, mesmo vindo
         de workers/hosts diferentes (throttling por tempo, não por worker).
      2) Se o Google responder 429, aplicar um cooldown que pausa TODO mundo
         (não só quem levou o 429) e cresce a cada 429 seguido, voltando ao
         valor inicial depois de um tempo sem bloqueios.
    """

    def __init__(self, intervalo_minimo, backoff_inicial, backoff_maximo, backoff_mult):
        self.intervalo_minimo = intervalo_minimo
        self.backoff_inicial = backoff_inicial
        self.backoff_maximo = backoff_maximo
        self.backoff_mult = backoff_mult
        self.lock = threading.Lock()
        self.proxima_liberacao = 0.0
        self.backoff_atual = backoff_inicial

    def aguardar_vez(self):
        while True:
            with self.lock:
                agora = time.perf_counter()
                espera = self.proxima_liberacao - agora
                if espera <= 0:
                    self.proxima_liberacao = agora + self.intervalo_minimo
                    return
            time.sleep(min(espera, 1.0))

    def registrar_bloqueio(self, log=None):
        with self.lock:
            pausa = self.backoff_atual
            self.proxima_liberacao = time.perf_counter() + pausa
            self.backoff_atual = min(self.backoff_atual * self.backoff_mult, self.backoff_maximo)
        if log:
            log.aviso(u"Google sinalizou limite de requisições (429); pausando TODOS os workers por {0:.0f}s antes de continuar.".format(pausa))
        time.sleep(pausa)

    def registrar_sucesso(self):
        with self.lock:
            self.backoff_atual = self.backoff_inicial


GOOGLE_THROTTLE = GoogleThrottle(GOOGLE_INTERVALO_MINIMO, GOOGLE_BACKOFF_INICIAL, GOOGLE_BACKOFF_MAXIMO, GOOGLE_BACKOFF_MULTIPLICADOR)


class GoogleGTXClient(object):
    """Cliente Google Translate Web alternativo via endpoint GTX público.

    Continua sendo Google Translate Web, sem Cloud Translation/API key. Cada
    cliente possui sua própria sessão/cookie jar, mas o DDAC mantém um
    rate-limit global para evitar rajadas.
    """
    def __init__(self, nome_host=u"translate.googleapis.com", host_base=u"https://translate.googleapis.com", log=None, worker_id=0):
        self.nome_host = nome_host
        self.host_base = host_base
        self.log = log
        self.worker_id = worker_id
        self.ready = False
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookiejar_compat.CookieJar()))
        self.lock = threading.Lock()
        self.network_lock = threading.Lock()
        self.reqid = int(time.time() * 1000) % 9000000 + 1000 + worker_id * 100
        self.ultima_latencia = None
        self.requests = 0
        self.rate_limits = 0
        self.latencias = []

    def _headers(self, extra=None):
        h = {
            u"User-Agent": u"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36",
            u"Accept-Language": u"pt-BR,pt;q=0.9,en;q=0.8",
            u"Connection": u"keep-alive",
            u"Accept": u"*/*",
        }
        if extra: h.update(extra)
        return h

    def conectar(self):
        # A home do Google Translate serve apenas para confirmar conectividade;
        # nenhuma tradução é consumida aqui.
        url = u"https://translate.google.com/"
        req = urllib.request.Request(url, headers=self._headers())
        with self.opener.open(req, timeout=GOOGLE_TIMEOUT) as resposta:
            resposta.read(1024)
        self.ready = True
        if self.log:
            self.log.info(u"Sessão worker {0} preparada: Google Translate Web RPC".format(self.worker_id + 1))

    def traduzir(self, texto, origem, destino):
        texto = texto_compativel(texto, u"")
        origem = texto_compativel(origem, u"auto") or u"auto"
        destino = texto_compativel(destino, u"pt-BR") or u"pt-BR"
        if not self.ready:
            self.conectar()
        with self.lock:
            reqid = self.reqid
            self.reqid += 1
        query = {
            u"client": u"gtx",
            u"sl": origem,
            u"tl": destino,
            u"dt": u"t",
            u"q": texto,
            u"tk": u"",
            u"_reqid": str(reqid),
        }
        url = self.host_base + u"/translate_a/single?" + urllib.parse.urlencode(query, doseq=True)
        req = urllib.request.Request(url, headers=self._headers({u"Referer": u"https://translate.google.com/"}))
        GOOGLE_THROTTLE.aguardar_vez()
        inicio_req = time.perf_counter()
        self.requests += 1
        try:
            # Um cliente/sessão nunca sobrepõe duas requisições próprias.
            with self.network_lock:
                with self.opener.open(req, timeout=GOOGLE_TIMEOUT) as resposta:
                    status = getattr(resposta, "status", 200)
                    bruto = resposta.read().decode(u"utf-8", u"replace")
        except urllib.error.HTTPError as exc:
            if exc.code == 429:
                self.rate_limits += 1
                GOOGLE_THROTTLE.registrar_bloqueio(self.log)
                raise GoogleRateLimitError(u"HTTP 429 Too Many Requests ({0})".format(self.nome_host))
            raise
        finally:
            self.ultima_latencia = time.perf_counter() - inicio_req
            self.latencias.append(self.ultima_latencia)
        if status == 429:
            self.rate_limits += 1
            GOOGLE_THROTTLE.registrar_bloqueio(self.log)
            raise GoogleRateLimitError(u"HTTP 429 Too Many Requests ({0})".format(self.nome_host))
        if status >= 400:
            raise GoogleTranslateError(u"HTTP {0} ({1})".format(status, self.nome_host))
        try:
            dados = json.loads(bruto)
            partes = []
            blocos = dados[0] if isinstance(dados, list) and dados else []
            if isinstance(blocos, list):
                for bloco in blocos:
                    if isinstance(bloco, list) and bloco and isinstance(bloco[0], TEXT_TYPES):
                        partes.append(bloco[0])
            resultado = u"".join(partes)
            if not resultado:
                raise ValueError(u"resposta GTX sem texto traduzido")
            GOOGLE_THROTTLE.registrar_sucesso()
            return resultado
        except Exception as exc:
            raise GoogleTranslateError(u"resposta GTX inválida: {0}".format(exc))


class GoogleRPCClient(object):
    def __init__(self, nome_host, host_base, log=None, worker_id=0):
        self.nome_host = nome_host
        self.host_base = host_base
        self.log = log
        self.worker_id = worker_id
        self.fsid = None
        self.bl = GOOGLE_STATIC_BL
        self.ready = False
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookiejar_compat.CookieJar()))
        self.reqid = int(time.time() * 1000) % 9000000 + 1000 + worker_id * 100
        self.lock = threading.Lock()
        self.ultima_latencia = None
        self.ultimo_status = None
        self.ultimos_bytes = 0
        self.requests = 0
        self.rate_limits = 0
        self.latencias = []

    def _headers(self, extra=None):
        h = {
            u"User-Agent": u"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36",
            u"Accept-Language": u"pt-BR,pt;q=0.9,en;q=0.8",
            u"Connection": u"keep-alive",
        }
        if extra: h.update(extra)
        return h

    def conectar(self):
        inicio_req = time.perf_counter()
        url = self.host_base + u"/"
        req = urllib.request.Request(url, headers=self._headers())
        try:
            with self.opener.open(req, timeout=GOOGLE_TIMEOUT) as resposta:
                status = getattr(resposta, "status", 200)
                bruto = resposta.read().decode(u"utf-8", u"replace")
                self.ultimo_status = status
                self.ultimos_bytes = len(bruto.encode(u"utf-8", u"replace"))
        finally:
            self.ultima_latencia = time.perf_counter() - inicio_req
        if status >= 400:
            raise urllib.error.HTTPError(url, status, u"HTTP {0}".format(status), None, None)
        m_fsid = re.search(r'"FdrFJe"\s*:\s*"([^"]+)"', bruto)
        m_bl = re.search(r'"cfb2h"\s*:\s*"([^"]+)"', bruto)
        if m_fsid: self.fsid = m_fsid.group(1)
        if m_bl: self.bl = m_bl.group(1)
        self.ready = True
        if self.log:
            self.log.info(u"Sessão worker {0} preparada: {1}".format(self.worker_id + 1, self.nome_host))

    def traduzir(self, texto, origem, destino):
        texto = texto_compativel(texto, u"")
        origem = texto_compativel(origem, u"auto") or u"auto"
        destino = texto_compativel(destino, u"pt-BR") or u"pt-BR"
        if not self.ready: self.conectar()
        with self.lock:
            reqid = self.reqid
            self.reqid += 1000
        interno = json.dumps([[texto, origem or u"auto", destino, True], [None]], ensure_ascii=False, separators=(u",", u":"))
        rpc_request = json.dumps([[[GOOGLE_RPC_ID, interno, None, u"generic"]]], ensure_ascii=False, separators=(u",", u":"))
        query = {
            u"rpcids": GOOGLE_RPC_ID, u"source-path": u"/", u"bl": self.bl,
            u"hl": destino or u"pt-BR", u"soc-app": u"1", u"soc-platform": u"1", u"soc-device": u"1",
            u"_reqid": str(reqid), u"rt": u"c"
        }
        if self.fsid: query[u"f.sid"] = self.fsid
        url = self.host_base + u"/_/TranslateWebserverUi/data/batchexecute?" + urllib.parse.urlencode(query)
        dados = urllib.parse.urlencode({u"f.req": rpc_request}).encode(u"utf-8")
        headers = self._headers({u"Accept": u"*/*", u"Content-Type": u"application/x-www-form-urlencoded;charset=UTF-8", u"Origin": self.host_base, u"Referer": self.host_base + u"/", u"X-Same-Domain": u"1"})
        req = urllib.request.Request(url, headers=headers, data=dados, method=u"POST")
        # Respeita o ritmo global antes de disparar -- isso vale mesmo se
        # OUTRO worker levou o 429 (o cooldown é compartilhado por todos).
        GOOGLE_THROTTLE.aguardar_vez()
        inicio_req = time.perf_counter()
        self.requests += 1
        try:
            with self.opener.open(req, timeout=GOOGLE_TIMEOUT) as resposta:
                status = getattr(resposta, "status", 200)
                bruto = resposta.read().decode(u"utf-8", u"replace")
                self.ultimo_status = status
                self.ultimos_bytes = len(bruto.encode(u"utf-8", u"replace"))
        except urllib.error.HTTPError as exc:
            self.ultimo_status = exc.code
            self.ultimos_bytes = 0
            if exc.code == 429:
                self.rate_limits += 1
                GOOGLE_THROTTLE.registrar_bloqueio(self.log)
                raise GoogleRateLimitError(u"HTTP 429 Too Many Requests ({0})".format(self.nome_host))
            raise
        finally:
            self.ultima_latencia = time.perf_counter() - inicio_req
            self.latencias.append(self.ultima_latencia)
        if status == 429:
            self.rate_limits += 1
            GOOGLE_THROTTLE.registrar_bloqueio(self.log)
            raise GoogleRateLimitError(u"HTTP 429 Too Many Requests ({0})".format(self.nome_host))
        if status >= 400: raise GoogleTranslateError(u"HTTP {0} ({1})".format(status, self.nome_host))
        GOOGLE_THROTTLE.registrar_sucesso()
        return extrair_traducao_rpc_google(extrair_payload_rpc_google(bruto))


def criar_pool_google(log):
    pool = []
    for worker in range(GOOGLE_WORKERS):
        nome, host = GOOGLE_HOSTS[worker % len(GOOGLE_HOSTS)]
        try:
            c = GoogleRPCClient(nome, host, log, worker)
            c.conectar()
            pool.append(c)
        except Exception as exc:
            if log:
                log.erro(u"Worker {0}: falha ao preparar {1}: {2}".format(worker + 1, nome, exc))
    if not pool:
        raise GoogleTranslateError(u"nenhuma sessão Google Translate Web pôde ser preparada")
    return pool



# =============================================================================
# BANCO DE CORREÇÕES ACUMULATIVAS E INDIVIDUAIS
# =============================================================================
# Cada regra casa somente com o TEXTO ORIGINAL. Uma regra nova não recebe o
# resultado de outra correção: regras antigas permanecem independentes.
# Acrescente novas entradas ao final da lista sem editar as anteriores.
# arquivo="*" torna a regra global; caso contrário use o caminho relativo .rpy.
# tipo="*" aceita qualquer tipo de entrada.
CORRECOES_INDIVIDUAIS_GOOGLE = [
    {
        u"id": u"R001_MONIKA_106",
        u"arquivo": u"monika_route/story.rpy",
        u"tipo": u"dialogo",
        u"origem": u"You'll be an embarrasment to her...{p=1.0} You'll break her image...",
        u"traducao": u"Você será uma vergonha para ela...{p=1.0} Você vai destruir a imagem que ela tem...",
    },
    {
        u"id": u"R002_MONIKA_364",
        u"arquivo": u"monika_route/story.rpy",
        u"tipo": u"dialogo",
        u"origem": u"It wouldn't be {i}this{/i} big of a problem...",
        u"traducao": u"Não seria {i}um problema tão grande{/i} assim...",
    },
    {
        u"id": u"R003_MONIKA_487",
        u"arquivo": u"monika_route/story.rpy",
        u"tipo": u"dialogo",
        u"origem": u"Mmmhhh, not really. Everyone was just-{p=0.5} weird.",
        u"traducao": u"Hmmm, não muito. Todo mundo estava só-{p=0.5} estranho.",
    },
    {
        u"id": u"R004_MONIKA_491",
        u"arquivo": u"monika_route/story.rpy",
        u"tipo": u"dialogo",
        u"origem": u"Everyone was just só-{p=0.5} nice today...",
        u"traducao": u"Todo mundo estava tão-{p=0.5} legal hoje...",
    },
    {
        u"id": u"R005_MONIKA_063_SPACING",
        u"arquivo": u"monika_route/story.rpy",
        u"tipo": u"dialogo",
        u"origem": u"Um...sure. Yeah.",
        u"traducao": u"Hum... claro. Sim.",
    },
    {
        u"id": u"R006_SCREENS_QUIT",
        u"arquivo": u"screens.rpy",
        u"tipo": u"*",
        u"origem": u"Quit",
        u"traducao": u"Sair",
    },
    {
        u"id": u"R007_STORY_ROUTE_SAYORI",
        u"arquivo": u"story.rpy",
        u"tipo": u"*",
        u"origem": u"sayori_route",
        u"traducao": u"Rota da Sayori",
    },
    {
        u"id": u"R008_STORY_ROUTE_YURI",
        u"arquivo": u"story.rpy",
        u"tipo": u"*",
        u"origem": u"yuri_route",
        u"traducao": u"Rota da Yuri",
    },
    {
        u"id": u"R009_STORY_ROUTE_NATSUKI",
        u"arquivo": u"story.rpy",
        u"tipo": u"*",
        u"origem": u"natsuki_route",
        u"traducao": u"Rota da Natsuki",
    },
    {
        u"id": u"R010_STORY_ROUTE_MONIKA",
        u"arquivo": u"story.rpy",
        u"tipo": u"*",
        u"origem": u"monika route",
        u"traducao": u"Rota da Monika",
    },
    {
        u"id": u"R011_SCRIPT_NAME_SAYORI",
        u"arquivo": u"script.rpy",
        u"tipo": u"nome_personagem",
        u"origem": u"Sayori",
        u"traducao": u"Sayori",
    },
    {
        u"id": u"R012_SCRIPT_NAME_MONIKA",
        u"arquivo": u"script.rpy",
        u"tipo": u"nome_personagem",
        u"origem": u"Monika",
        u"traducao": u"Monika",
    },
    {
        u"id": u"R013_SCRIPT_NAME_NATSUKI",
        u"arquivo": u"script.rpy",
        u"tipo": u"nome_personagem",
        u"origem": u"Natsuki",
        u"traducao": u"Natsuki",
    },
    {
        u"id": u"R014_SCRIPT_NAME_YURI",
        u"arquivo": u"script.rpy",
        u"tipo": u"nome_personagem",
        u"origem": u"Yuri",
        u"traducao": u"Yuri",
    },
    {
        u"id": u"R015_DEFINITIONS_NAME_MONIKA",
        u"arquivo": u"definitions/definitions.rpy",
        u"tipo": u"nome_personagem",
        u"origem": u"Monika",
        u"traducao": u"Monika",
    },
    {
        u"id": u"R016_DEFINITIONS_NAME_YURI",
        u"arquivo": u"definitions/definitions.rpy",
        u"tipo": u"nome_personagem",
        u"origem": u"Yuri",
        u"traducao": u"Yuri",
    },
    {
        u"id": u"R017_DEFINITIONS_CH4_YURI",
        u"arquivo": u"definitions/definitions.rpy",
        u"tipo": u"variavel_texto",
        u"origem": u"Yuri",
        u"traducao": u"Yuri",
    },
    {
        u"id": u"R020_POEM_FLICKER_BACK",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"I flicker back.",
        u"traducao": u"Eu pisco de volta.",
    },
    {
        u"id": u"R021_POEM_MOON_PHASE",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"The moon increments its phase and reflects that much more light off of my cutting knife.",
        u"traducao": u"A lua muda de fase e reflete muito mais luz sobre minha faca de corte.",
    },
    {
        u"id": u"R022_POEM_BRANDISH_KNIFE",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"Each time I brandish my cutting knife, the raccoon shows me its excitement.",
        u"traducao": u"Cada vez que empunho minha faca de corte, o guaxinim demonstra sua empolgação.",
    },
    {
        u"id": u"R023_POEM_BOUNDARY_LINE",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"I sink my toes into the ultimate boundary line, tempted by the foamy tendrils.",
        u"traducao": u"Afundo os dedos dos pés no limite final, tentado pelas gavinhas espumosas.",
    },
    {
        u"id": u"R024_POEM_TURN_BACK",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"Turn back, and I abandon my peace to erode at the shore.",
        u"traducao": u"Eu volto e abandono minha paz para que ela se desgaste na margem.",
    },
    {
        u"id": u"R025_POEM_STREETLIGHT",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"He steps into the streetlight. I gasp and drop my umbrella.",
        u"traducao": u"Ele entra sob a luz do poste. Eu suspiro e deixo meu guarda-chuva cair.",
    },
    {
        u"id": u"R026_POEM_FORTY_GEARS",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"Forty gears and a ticking clock. A clock that ticks one second for every rotation of the planet. ",
        u"traducao": u"Quarenta engrenagens e um relógio que tiquetaqueia. Um relógio que marca um segundo a cada rotação do planeta.",
    },
    {
        u"id": u"R027_POEM_WINDY_SAIL",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"Set you free in my windy sail",
        u"traducao": u"Liberto você na minha vela ao vento.",
    },
    {
        u"id": u"R028_POEM_STANDING",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"My standing is a little bit taller",
        u"traducao": u"Minha estatura é um pouco maior.",
    },
    {
        u"id": u"R029_POEM_SCALP",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"I pop off my scalp like the lid of a cookie jar.",
        u"traducao": u"Eu arranco meu couro cabeludo como a tampa de um pote de biscoitos.",
    },
    {
        u"id": u"R030_POEM_RETINAS",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"Already scorched with a permanent copy of the meaningless image.",
        u"traducao": u"Já chamuscadas com uma cópia permanente da imagem sem sentido.",
    },
    {
        u"id": u"R031_POEM_PEN",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"Swallowing my fears, I brandish my pen.",
        u"traducao": u"Engolindo meus medos, empunho minha caneta.",
    },
    {
        u"id": u"R032_POEM_ALL_PURPOSE",
        u"arquivo": u"poem_responses/poems.rpy",
        u"tipo": u"poema_corpo",
        u"origem": u"All purpose,",
        u"traducao": u"Todo propósito,",
    },
]


def aplicar_correcao_individual_google(texto, rel, tipo_entrada, destino, log=None):
    texto = texto_compativel(texto, u"")
    rel = texto_compativel(rel, u"")
    tipo_entrada = texto_compativel(tipo_entrada, u"")
    destino = texto_compativel(destino, u"pt-BR")
    if not destino or not destino.lower().startswith(u"pt"):
        return None, None
    rel_norm = (rel or u"").replace(u"\\", u"/").lower()
    tipo_norm = (tipo_entrada or u"").lower()
    for regra in CORRECOES_INDIVIDUAIS_GOOGLE:
        if regra.get(u"origem") != (texto or u""):
            continue
        arquivo_regra = (regra.get(u"arquivo") or u"*").replace(u"\\", u"/").lower()
        if arquivo_regra != u"*" and arquivo_regra != rel_norm:
            continue
        tipo_regra = (regra.get(u"tipo") or u"*").lower()
        if tipo_regra != u"*" and tipo_regra != tipo_norm:
            continue
        traducao = regra.get(u"traducao")
        if isinstance(traducao, str):
            if log:
                log.aviso(u"Correção individual {0} aplicada em {1}; a regra casa apenas com o texto original.".format(
                    regra.get(u"id", u"SEM_ID"), rel))
            return traducao, regra.get(u"id", u"SEM_ID")
    return None, None


ENGLISH_RETRY_DISTINCTIVE = {
    u"problem", u"game", u"over", u"huh", u"come", u"coming", u"keep", u"mom", u"mother",
    u"father", u"loading", u"settings", u"quit", u"finish", u"start",
    u"sorry", u"please", u"thanks", u"thank", u"why", u"what", u"where",
    u"when", u"who", u"how", u"help", u"love", u"hate", u"girl", u"boy",
    u"confession", u"crush", u"routine", u"story", u"school", u"student",
    u"friend", u"friends", u"friendship", u"conversation", u"situation",
    u"moment", u"moments", u"house", u"home", u"store", u"today",
    u"tomorrow", u"yesterday", u"night", u"morning", u"lunch", u"club",
    u"room", u"world", u"head", u"heart", u"face", u"hands", u"chair",
    u"door", u"window", u"table", u"kitchen", u"party", u"food", u"book",
    u"books", u"water", u"drink", u"look", u"looked", u"looking", u"felt",
    u"feel", u"feeling", u"walk", u"walked", u"walking", u"talk", u"talked",
    u"say", u"said", u"saying", u"tell", u"told", u"know", u"knew",
    u"think", u"thought", u"want", u"wanted", u"need", u"needed", u"make",
    u"made", u"doing", u"done", u"good", u"bad", u"little", u"big", u"small",
    u"back", u"away", u"around", u"again", u"always", u"never", u"really",
    u"very", u"just", u"only", u"maybe", u"sure", u"right", u"wrong", u"well",
    u"finally", u"suddenly", u"quickly", u"slowly", u"because", u"before",
    u"after", u"while", u"someone", u"something", u"everything", u"anyone",
}
ENGLISH_RETRY_COMMON = {
    u"i", u"you", u"he", u"she", u"it", u"we", u"they", u"my", u"your",
    u"the", u"a", u"an", u"and", u"but", u"or", u"with", u"without",
    u"is", u"are", u"was", u"were", u"am", u"to", u"of", u"in", u"on",
    u"for", u"this", u"that", u"not", u"no", u"yes", u"be", u"been",
    u"being", u"do", u"did", u"does", u"will", u"would", u"could", u"should",
    u"have", u"has", u"had", u"can", u"cannot", u"here", u"there", u"everyone",
    u"something", u"someone",
}

# Contrações são evidência forte de inglês em falas que o Google devolveu
# literalmente. A regra continua valendo somente para resultado idêntico.
ENGLISH_RETRY_CONTRACTIONS = {
    u"that's", u"it's", u"i'm", u"you're", u"we're", u"they're", u"i've",
    u"you've", u"we've", u"they've", u"don't", u"doesn't", u"didn't",
    u"can't", u"cannot", u"couldn't", u"shouldn't", u"wouldn't", u"won't",
    u"isn't", u"aren't", u"wasn't", u"weren't", u"haven't", u"hasn't",
    u"hadn't",
}

ENGLISH_HESITATION_WORDS = {u"um", u"uh", u"er", u"erm"}

# Entradas de interface/controle que não devem receber uma tradução textual
# forçada porque são teclas, placeholders, identificadores ou abreviações
# tratadas pelo patch da Opção 4.
EQUAL_TRANSLATION_PROTECTED = {
    u"x", u"Ctrl", u"H", u"S", u"V", u"Auto", u"Q.Save", u"Menu",
    u"one_line_one_property", u"spline_editor",
    u"{#auto_page}A", u"{#quick_page}Q",
    u"{#file_time}%A, %B %d %Y, %H:%M",
}

# Correções pontuais para expressões que o Google pode devolver idênticas,
# embora exista uma tradução PT-BR clara e desejada.
# Correções locais somente para resultados que o Google devolveu
# EXATAMENTE iguais ao original. Isso nunca substitui uma tradução que
# o Google já tenha alterado com sucesso.
EQUAL_TRANSLATION_FALLBACK_PTBR = {
    u"no": u"Não",
    u"yes": u"Sim",
    u"game over": u"Fim de jogo",
    u"huh": u"Hein?",
    u"aah": u"Ah...",
    u"the confession": u"a confissão",
    u"developing a crush": u"desenvolvendo uma paixão",
    u"a routine day": u"um dia rotineiro",
    # Rótulos/termos ingleses curtos que podem, ocasionalmente, voltar iguais.
    u"close editor": u"Fechar editor?",
    u"no files": u"Nenhum arquivo",
    u"nothing to put": u"Nada para inserir",
    u"clipboard": u"área de transferência",
    u"absolute": u"absoluto",
    u"fraction": u"fração",
    u"option": u"opção",
    u"remove": u"remover",
    u"close": u"fechar",
    u"loop": u"ciclo",
    u"reset": u"reiniciar",
    u"return": u"voltar",
    u"start": u"iniciar",
    u"end": u"fim",
}

# Palavras/fragmentos que são sinais fortes de inglês quando um resultado
# inteiro voltou idêntico. A lista é deliberadamente pequena para não
# transformar nomes, risadas, efeitos sonoros ou identificadores técnicos.
EQUAL_TRANSLATION_ENGLISH_HINTS = {
    u"please", u"type", u"value", u"files", u"file", u"clipboard",
    u"close", u"editor", u"open", u"start", u"end", u"return", u"remove",
    u"reset", u"option", u"absolute", u"fraction", u"nothing", u"used",
    u"time", u"invalid", u"can", u"can't", u"cannot", u"new", u"scene",
    u"select", u"set", u"amount", u"change", u"property", u"following",
    u"only", u"one", u"page", u"save", u"load", u"help", u"yes", u"no",
    u"game", u"over", u"huh", u"sorry", u"what", u"where", u"why",
    u"confession", u"crush", u"routine", u"story", u"school", u"student",
    u"friend", u"friends", u"friendship", u"conversation", u"situation",
    u"moment", u"moments", u"house", u"home", u"store", u"today",
    u"tomorrow", u"yesterday", u"night", u"morning", u"lunch", u"club",
    u"room", u"world", u"head", u"heart", u"face", u"hands", u"chair",
    u"door", u"window", u"table", u"kitchen", u"party", u"food", u"book",
    u"books", u"water", u"drink", u"look", u"looked", u"looking", u"felt",
    u"feel", u"feeling", u"walk", u"walked", u"walking", u"talk", u"talked",
    u"say", u"said", u"saying", u"tell", u"told", u"know", u"knew",
    u"think", u"thought", u"want", u"wanted", u"need", u"needed", u"make",
    u"made", u"doing", u"done", u"good", u"bad", u"little", u"big", u"small",
    u"back", u"away", u"around", u"again", u"always", u"never", u"really",
    u"very", u"just", u"only", u"maybe", u"sure", u"right", u"wrong", u"well",
    u"finally", u"suddenly", u"quickly", u"slowly", u"because", u"before",
    u"after", u"while", u"someone", u"something", u"everything", u"anyone",
}


def _chave_fallback_ptbr(texto):
    valor = texto or u""
    valor = re.sub(r"\{[^}\r\n]*\}|\[[^]\r\n]*\]", u" ", valor)
    valor = re.sub(r"[^A-Za-zÀ-ÿ'’]+", u" ", valor)
    return re.sub(r"\s+", u" ", valor).strip().lower()


def deve_forcar_retentativa_igual(texto):
    """
    Retentativa usada para textos que voltaram idênticos ao original.
    Mantém a proteção contra identificadores, abreviações e efeitos sonoros.
    """
    t = (texto or u"").strip()
    chave = _chave_fallback_ptbr(t)
    if not t or t in EQUAL_TRANSLATION_PROTECTED:
        return False
    if chave in EQUAL_TRANSLATION_FALLBACK_PTBR:
        return True
    if not re.search(r"[A-Za-zÀ-ÿ]", t):
        return False
    if "_" in t and not re.search(r"\s", t):
        return False
    if re.match(r"^[A-Za-z]$", t):
        return False
    # Não gastar requisições com risadas/efeitos sonoros que o Google
    # corretamente pode devolver sem mudança.
    if re.match(r"^(?:ha(?:ha)+|h(?:mm|m)+|a+h+|g+(?:lp)+)\W*$", t.lower()):
        return False
    palavras = re.findall(r"[A-Za-zÀ-ÿ]+(?:['’][A-Za-zÀ-ÿ]+)?", t.lower())
    if any(p in EQUAL_TRANSLATION_ENGLISH_HINTS for p in palavras):
        return True
    comuns = sum(1 for p in palavras if p in ENGLISH_RETRY_COMMON)
    return len(palavras) >= 3 and comuns >= 1


def deve_forcar_retentativa_dialogo(texto):
    """
    Detector conservador para FALAS (tipo=diálogo) que o Google devolveu
    exatamente iguais ao original. Só entra nessa rota quando há evidência
    textual razoavelmente clara de inglês, preservando nomes, efeitos sonoros,
    identificadores e atalhos.
    """
    t = (texto or u"").strip()
    if not t or t in EQUAL_TRANSLATION_PROTECTED:
        return False
    chave = _chave_fallback_ptbr(t)
    if chave in EQUAL_TRANSLATION_FALLBACK_PTBR:
        return True
    if not re.search(r"[A-Za-zÀ-ÿ]", t):
        return False
    if "_" in t and not re.search(r"\s", t):
        return False
    if re.match(r"^[A-Za-z]$", t):
        return False
    # Interjeições, risadas e efeitos sonoros continuam fora desta rota.
    if re.match(r"^(?:ha(?:ha)+|h(?:mm|m)+|a+h+|g+(?:lp)+)\W*$", t.lower()):
        return False
    palavras = re.findall(r"[A-Za-zÀ-ÿ]+(?:['’][A-Za-zÀ-ÿ]+)?", t.lower())
    distintivas = sum(1 for p in palavras if p in ENGLISH_RETRY_DISTINCTIVE)
    comuns = sum(1 for p in palavras if p in ENGLISH_RETRY_COMMON)
    if any(p in ENGLISH_RETRY_CONTRACTIONS for p in palavras):
        return True
    # Construções do tipo "I have, um...". "um" sozinho não é evidência
    # suficiente, pois também é uma palavra normal em português; ele só pesa
    # quando vem acompanhado de evidência inglesa.
    tem_hesitacao = any(p in ENGLISH_HESITATION_WORDS for p in palavras)
    if tem_hesitacao and (distintivas >= 1 or comuns >= 1):
        return True
    # Para diálogos, uma palavra inglesa distintiva (come, mom, what, etc.)
    # já é evidência suficiente; sem isso, exigimos pelo menos duas palavras
    # comuns de inglês para evitar falsos positivos em nomes ou interjeições.
    if distintivas >= 1:
        return True
    return comuns >= 2


# Vocabulário adicional para detectar inglês residual em traduções parcialmente alteradas.
# A lista cobre palavras muito comuns/estruturais e não substitui o Google; ela serve
# apenas para decidir quando vale fazer a retentativa explícita en->pt-BR.
RESIDUAL_ENGLISH_STRONG = {
    # Sinais fortes encontrados na auditoria da V127 e anglicismos que não
    # devem permanecer em uma saída PT-BR traduzível.
    u"spackle", u"feedback", u"modder", u"bolthead", u"piercing", u"flash",
    u"flashing",
}

# Termos curtos que podem aparecer como empréstimos, nomes ou coincidências;
# não são considerados fortes isoladamente.
RESIDUAL_ENGLISH_AMBIGUOUS = {
    u"online", u"player", u"mod", u"game", u"poem", u"star",
    u"red", u"velvet", u"portal", u"animal", u"enigma", u"overdose",
}

RESIDUAL_ENGLISH_WORDS = {
    u"about", u"above", u"across", u"actually", u"after", u"again", u"against", u"ago",
    u"all", u"almost", u"already", u"also", u"always", u"another", u"any", u"anything",
    u"anyway", u"away", u"back", u"because", u"before", u"behind", u"below", u"beside",
    u"between", u"both", u"break", u"bring", u"brought", u"call", u"called", u"calling",
    u"came", u"care", u"carry", u"change", u"changed", u"check", u"choose", u"chosen",
    u"clear", u"close", u"closed", u"coming", u"continue", u"could", u"couldn't", u"course",
    u"cut", u"day", u"days", u"decide", u"decided", u"did", u"didn't", u"different",
    u"does", u"doesn't", u"doing", u"done", u"don't", u"down", u"each", u"else", u"enough",
    u"even", u"ever", u"every", u"everything", u"exactly", u"feel", u"felt", u"find", u"found",
    u"first", u"from", u"get", u"gets", u"getting", u"give", u"given", u"gives", u"go", u"goes",
    u"going", u"gone", u"got", u"guess", u"had", u"has", u"haven't", u"having", u"hear",
    u"heard", u"help", u"here", u"herself", u"him", u"himself", u"hold", u"hope", u"how",
    u"however", u"idea", u"if", u"immediately", u"into", u"just", u"keep", u"keeps", u"knew",
    u"know", u"knows", u"last", u"later", u"left", u"let", u"lets", u"like", u"liked", u"little",
    u"look", u"looks", u"made", u"make", u"makes", u"maybe", u"mean", u"means", u"might",
    u"more", u"most", u"much", u"must", u"myself", u"near", u"never", u"next", u"nothing",
    u"now", u"off", u"often", u"once", u"other", u"others", u"out", u"over", u"own", u"part",
    u"perhaps", u"place", u"play", u"point", u"put", u"quite", u"rather", u"really", u"remember",
    u"right", u"said", u"same", u"saw", u"say", u"says", u"second", u"seem", u"seems", u"seen",
    u"should", u"shouldn't", u"since", u"something", u"sometimes", u"soon", u"still", u"such",
    u"take", u"taken", u"takes", u"tell", u"than", u"that", u"their", u"them", u"themselves",
    u"then", u"there", u"these", u"thing", u"things", u"think", u"thinks", u"thought", u"through",
    u"together", u"too", u"try", u"trying", u"turn", u"under", u"until", u"used", u"use", u"uses",
    u"very", u"wait", u"want", u"wants", u"was", u"wasn't", u"way", u"well", u"went", u"were",
    u"weren't", u"what", u"whatever", u"when", u"whenever", u"where", u"whether", u"which",
    u"while", u"who", u"whole", u"whose", u"why", u"without", u"won't", u"work", u"worked",
    u"would", u"wouldn't", u"yeah", u"yet", u"your", u"yourself", u"you're",
}

def _texto_sem_ruido_para_detector_ingles(valor):
    valor = texto_compativel(valor, u"")
    for termo in TERMOS_NAO_TRADUZIR_GOOGLE:
        valor = re.sub(re.escape(termo), u" ", valor, flags=re.I)
    # URLs, caminhos, extensões e tokens protegidos não são evidência de
    # inglês residual. Ignorá-los evita retentativas desnecessárias e,
    # principalmente, evita substituir uma tradução correta por uma segunda
    # tradução pior causada apenas por texto técnico/URL.
    valor = re.sub(r"https?://\S+", u" ", valor, flags=re.I)
    valor = re.sub(r"(?:[A-Za-z0-9_.-]+[\\/])*[A-Za-z0-9_.-]+\.(?:png|jpg|jpeg|gif|webp|webm|ogg|mp3|wav|flac|m4a|ttf|otf|ttc|rpy|rpyc|rpa|dll|so|exe|bin|json|py|pyc)", u" ", valor, flags=re.I)
    valor = re.sub(r"\{[^}\r\n]*\}|\[[^]\r\n]*\]", u" ", valor)
    return valor


def normalizar_termos_ingles_residuais_ptbr(texto):
    """Remove poucos anglicismos inequívocos sem reescrever o estilo da tradução."""
    valor = texto_compativel(texto, u"")
    regras = (
        (r"\bgame\s+over\b", u"fim de jogo"),
        (r"\bmodder\b", u"autor do mod"),
        (r"\bfeedback\b", u"retorno"),
        (r"\bo spackle\b", u"a massa corrida"),
        (r"\bSpackle\b", u"Massa corrida"),
        (r"\bspackle\b", u"massa corrida"),
        (r"\bBolthead\b", u"Cabeça de parafuso"),
        (r"\bbolthead\b", u"cabeça de parafuso"),
        (r"\bFlash\b", u"Clarão"),
        (r"\bflash\b", u"clarão"),
        (r"\bpiercing\b", u"perfurante"),
    )
    for padrao, substituicao in regras:
        valor = re.sub(padrao, substituicao, valor)
    return valor


def parece_residuo_ingles_resultado(original, resultado, tipo_entrada):
    """Detecta inglês residual mesmo quando o Google traduziu apenas parte.

    A rotina continua restrita a tipos textuais traduzíveis. Para reduzir falsos
    positivos, exige evidência de inglês na fonte e procura no resultado palavras
    inglesas que sobreviveram. Uma palavra inglesa residual já é suficiente quando
    ela é distintiva; para palavras estruturais, basta uma ocorrência em uma frase
    cuja fonte também tenha evidência inglesa.
    """
    if not original or not resultado or original == resultado:
        return False
    if tipo_entrada not in (u"dialogo", u"renpy_nativo_dialogo", u"renpy_nativo_string", u"narrativa", u"ui", u"poema_corpo", u"poema_palavra", u"poema_palavra_txt", u"nome_grupo", u"variavel_texto", u"url_visivel"):
        return False
    if resultado in EQUAL_TRANSLATION_PROTECTED:
        return False
    fonte = _texto_sem_ruido_para_detector_ingles(original).strip()
    saida = _texto_sem_ruido_para_detector_ingles(resultado).strip()
    if "_" in saida and not re.search(r"\\s", saida):
        return False
    if re.match(r"^(?:ha(?:ha)+|h(?:mm|m)+|a+h+|g+(?:lp)+)\\W*$", saida.lower()):
        return False

    # Nomes principais protegidos globalmente nunca contam como inglês residual.
    nomes_protegidos = {u"sayori", u"monika", u"natsuki", u"yuri"}
    if u"let's play" in saida.lower():
        # Rótulo deliberado do mod; a Opção 4 o adapta para "Modo com Censura".
        return False

    palavras_fonte = re.findall(r"[A-Za-zÀ-ÿ]+(?:['’][A-Za-zÀ-ÿ]+)?", fonte.lower())
    palavras_saida = re.findall(r"[A-Za-zÀ-ÿ]+(?:['’][A-Za-zÀ-ÿ]+)?", saida.lower())
    palavras_saida_sem_nomes = [p for p in palavras_saida if p not in nomes_protegidos]
    if not palavras_saida_sem_nomes:
        return False

    # Termos residuais inequívocos são suficientes mesmo quando a fonte
    # já estava parcialmente em PT-BR ou quando está corrompida/fragmentada.
    # Isso fecha a lacuna que permitiu `feedback` e `modder` passarem quando
    # o próprio mapa já trazia o restante da frase em português.
    if any(p in RESIDUAL_ENGLISH_STRONG for p in palavras_saida_sem_nomes):
        return True

    if len(palavras_fonte) < 2:
        return False

    # A fonte precisa parecer realmente inglesa.
    dist_fonte = sum(1 for p in palavras_fonte if p in ENGLISH_RETRY_DISTINCTIVE)
    comuns_fonte = sum(1 for p in palavras_fonte if p in ENGLISH_RETRY_COMMON or p in RESIDUAL_ENGLISH_WORDS)
    tem_contracao_fonte = any(p in ENGLISH_RETRY_CONTRACTIONS for p in palavras_fonte)
    fonte_ingles = (dist_fonte >= 1 or comuns_fonte >= 2 or tem_contracao_fonte)
    if not fonte_ingles:
        return False

    # Qualquer contração inglesa sobrevivente é sinal forte.
    if any(p in ENGLISH_RETRY_CONTRACTIONS for p in palavras_saida_sem_nomes):
        return True

    # Termos fortes precisam ter sobrevivido literalmente da própria fonte.
    # Isso evita marcar palavras portuguesas que apenas coincidem com o inglês.
    fonte_set = set(palavras_fonte)
    fortes = RESIDUAL_ENGLISH_STRONG | ENGLISH_RETRY_DISTINCTIVE
    if any((p in fonte_set and p in fortes and p not in RESIDUAL_ENGLISH_AMBIGUOUS)
           for p in palavras_saida_sem_nomes):
        return True

    # Um termo inglês distinguível sobrevivente continua sendo suficiente.
    if any(p in ENGLISH_RETRY_DISTINCTIVE for p in palavras_saida_sem_nomes):
        return True

    # Vocabulário estrutural/comum. Isso cobre resultados híbridos do tipo
    # "Eu really gosto", "Ela said isso" ou "Você can fazer".
    residuais_comuns = {
        u"i", u"you", u"he", u"she", u"it", u"we", u"they", u"my", u"your",
        u"the", u"and", u"but", u"or", u"with", u"without", u"to", u"of",
        u"is", u"are", u"was", u"were", u"am", u"this", u"that", u"not",
        u"yes", u"be", u"been", u"being", u"do", u"did", u"does", u"will",
        u"would", u"could", u"should", u"have", u"has", u"had", u"can",
        u"cannot", u"here", u"there", u"everyone", u"someone", u"something",
        u"please", u"sorry", u"thanks", u"what", u"why", u"where", u"when",
        u"who", u"how",
    }
    comuns_saida = sum(1 for p in palavras_saida_sem_nomes if p not in PORTUGUES_ALTO_SINAL and (p in residuais_comuns or p in RESIDUAL_ENGLISH_WORDS or p in RESIDUAL_ENGLISH_STRONG))
    # Uma única palavra comum pode ser nome próprio, URL fragmentada ou
    # coincidência lexical. Para retentativa automática exigimos duas evidências
    # estruturais; palavras distintivas/contrações continuam disparando sozinhas.
    if comuns_saida >= 2:
        return True

    # Última proteção: se uma palavra com pelo menos 4 letras permaneceu
    # exatamente igual à fonte e estiver no vocabulário residual, reprocessa.
    fonte_set = set(palavras_fonte)
    for p in palavras_saida_sem_nomes:
        if len(p) >= 4 and p in fonte_set and p in RESIDUAL_ENGLISH_WORDS:
            return True
    return False


def parece_sobra_ingles_curto(texto):
    """Compatibilidade: mantém o detector antigo disponível para o restante do código."""
    limpo = re.sub(r"[^A-Za-z\s\'-]+", u" ", texto or u"").lower()
    palavras = [p for p in re.split(r"\s+", limpo) if p]
    if not palavras or len(palavras) > 14:
        return False
    distintivas = sum(1 for p in palavras if p in ENGLISH_RETRY_DISTINCTIVE)
    comuns = sum(1 for p in palavras if p in ENGLISH_RETRY_COMMON)
    if len(palavras) == 1 and palavras[0] in (u"huh", u"sorry", u"please"):
        return True
    return distintivas >= 1 and (len(palavras) >= 2 or comuns >= 1)


def normalizar_espacos_pos_pontuacao_google(original, traducao):
    """Corrige perda de espaço após pontuação sem reescrever a tradução.

    A correção só atua quando o texto original possuía espaços após . ! ? ou ; :
    e a resposta do Google juntou a pontuação à palavra seguinte. Isso trata
    casos como `claro.Sim` -> `claro. Sim` sem mexer em números decimais.
    """
    if not original or not traducao:
        return traducao
    limites_orig = re.findall(r"[.!?;:]\s+(?=[A-Za-zÀ-ÿ])", original)
    faltantes = len(limites_orig)
    if faltantes <= 0:
        return traducao
    padrao = re.compile(r"([.!?;:])(?=[A-ZÀ-Ý])")
    def repl(m):
        nonlocal faltantes
        if faltantes <= 0:
            return m.group(0)
        faltantes -= 1
        return m.group(1) + u" "
    return padrao.sub(repl, traducao)


def entrada_eh_config_name_global(entrada):
    """Identifica a definição global do nome do jogo sem bloquear options.rpy inteiro."""
    if not isinstance(entrada, dict):
        return False
    contexto = texto_compativel(entrada.get(u"contexto"), u"").lower()
    # O extrator registra config.name no contexto do mapa.
    # A regra usa o contexto para também proteger mapas antigos já existentes.
    return u"config.name" in contexto and (u"define" in contexto or u"default" in contexto)



def traduzir_por_fragmentos_residual_google(cliente, texto, origem, destino):
    """Último fallback para respostas que voltaram em inglês/resposta vazia.

    Não altera o motor principal: continua usando o mesmo cliente RPC e a mesma
    sessão. A diferença é que o texto é dividido em fragmentos preservando
    quebras, URLs, tags e tokens técnicos. Isso ajuda o Google a traduzir textos
    curtos/credits/strings que ele ocasionalmente devolve idênticos quando
    enviados como uma única unidade.
    """
    texto = texto_compativel(texto, u"")
    if not texto.strip():
        return texto

    partes = re.split(r'(\r\n|\n|\\n)', texto)
    saida = []
    alterou = False
    for parte in partes:
        if parte in (u"\r\n", u"\n", u"\\n") or not parte:
            saida.append(parte)
            continue
        # Divide primeiro por frases. Para strings curtas que o RPC devolve
        # inteiras em inglês, existe um segundo nível de fragmentação por
        # vírgula/;/:. Isso evita que uma frase curta como "No, continue where
        # I left off." fique presa em retries mesmo quando o Google traduz
        # corretamente cada segmento menor. Identificadores e linhas longas
        # continuam protegidos contra fragmentação agressiva.
        sentencas = re.split(r'(?<=[.!?])\s+(?=[A-Za-zÀ-ÿ])', parte)
        unidades = []
        for sentenca in sentencas:
            if (len(sentenca) <= 180 and re.search(r'[,;:]\s+', sentenca)
                    and not re.search(r'https?://|www\.', sentenca, re.I)):
                pedacos = re.split(r'([,;:]\s+)', sentenca)
                corrente = u''
                for pedaco in pedacos:
                    if not pedaco:
                        continue
                    corrente += pedaco
                    if re.search(r'[,;:]\s+$', pedaco):
                        unidades.append(corrente)
                        corrente = u''
                if corrente:
                    unidades.append(corrente)
            else:
                unidades.append(sentenca)
        sub_saida = []
        for fragmento in unidades:
            if not fragmento or not re.search(r"[^\W\d_]", fragmento, re.UNICODE):
                sub_saida.append(fragmento)
                continue
            protegido, tokens = proteger_tokens_google(fragmento)
            resultado = cliente.traduzir(protegido, u"en", destino)
            validar_tokens_google_preservados(resultado, tokens)
            resultado = escapar_percentuais_novos_google(resultado)
            resultado = restaurar_tokens_google(resultado, tokens)
            sub_saida.append(resultado)
            if resultado != fragmento:
                alterou = True
        saida.append(u"".join(sub_saida))
    resultado_final = u"".join(saida)
    if not alterou or resultado_final == texto:
        return None
    return resultado_final


def traduzir_texto_worker(texto, origem, destino, pool, indice, total, log, rel, tipo_entrada=None, scheduler_index=None):
    texto = texto_compativel(texto, u"")
    origem = texto_compativel(origem, u"auto") or u"auto"
    destino = texto_compativel(destino, u"pt-BR") or u"pt-BR"
    rel = texto_compativel(rel, u"")
    tipo_entrada = texto_compativel(tipo_entrada, u"")
    correcao, regra_id = aplicar_correcao_individual_google(texto, rel, tipo_entrada, destino, log)
    if correcao is not None:
        try:
            validar_integridade_traducao_google(texto, correcao)
            return indice, correcao, None
        except Exception as exc:
            return indice, None, GoogleTranslateValidationError(
                u"regra individual {0} gerou resultado inválido: {1}".format(regra_id, exc)
            )

    # Créditos são tratados em nível estrutural: traduzimos somente categorias
    #/roles e preservamos nomes, artistas, títulos e recursos. Isso elimina as
    # retentativas artificiais causadas pelo detector de inglês residual.
    if parece_bloco_creditos_google(texto, rel, tipo_entrada):
        base_index_credito = scheduler_index if scheduler_index is not None else indice
        try:
            cliente_credito = pool[base_index_credito % max(1, len(pool))]
            resultado_credito = traduzir_bloco_creditos_google(cliente_credito, texto, origem, destino)
            if resultado_credito is not None:
                return indice, resultado_credito, None
        except Exception as exc:
            if log:
                log.erro(u"Falha ao processar bloco de créditos {0}, texto {1}/{2}: {3}".format(rel, indice + 1, total, exc))
            return indice, None, exc

    # Quando a fonte parece inglês e o usuário pediu detecção automática,
    # enviamos explicitamente `en`. Isso elimina o custo de redetecção do Google
    # e melhora bastante fragmentos poéticos curtos.
    origem_google = origem
    if origem == u"auto" and destino.lower().startswith(u"pt") and fonte_parece_inglesa_google(texto):
        origem_google = u"en"

    base_index = scheduler_index if scheduler_index is not None else indice
    ultimo = None
    melhores = []
    tentativas_principais = max(1, GOOGLE_RETRIES)
    for tentativa in range(tentativas_principais):
        pos = (base_index + tentativa) % max(1, len(pool))
        cliente = pool[pos]
        protegido, tokens = proteger_tokens_google(texto)
        try:
            resultado = cliente.traduzir(protegido, origem_google, destino)
            validar_tokens_google_preservados(resultado, tokens)
            resultado = escapar_percentuais_novos_google(resultado)
            resultado = restaurar_tokens_google(resultado, tokens)
            resultado = normalizar_espacos_pos_pontuacao_google(texto, resultado)
            if destino.lower().startswith(u"pt"):
                resultado = normalizar_termos_ingles_residuais_ptbr(resultado)

            # Uma segunda camada é feita SOMENTE quando há evidência de inglês residual.
            # Ela usa outro worker/cliente e não reinicia uma cascata de 20 tentativas.
            residual = False
            if destino.lower().startswith(u"pt"):
                if resultado == texto:
                    residual = (origem_google == u"en" and deve_forcar_retentativa_dialogo(texto) if tipo_entrada in (u"dialogo",u"renpy_nativo_dialogo") else
                                origem_google == u"en" and deve_forcar_retentativa_igual(texto))
                else:
                    residual = parece_residuo_ingles_resultado(texto, resultado, tipo_entrada)

            if not residual:
                validar_resultado_traducao_google(texto, resultado, tipo_entrada, origem_google, destino)
                return indice, resultado, None

            melhores.append(resultado)
            # Fast-path para strings curtas que o RPC devolveu em inglês: em vez
            # de repetir a mesma frase 3-4 vezes, tenta imediatamente o fallback
            # por fragmentos. Isso reduz muito o custo de créditos/splash/UI curtos.
            if (destino.lower().startswith(u"pt") and len(texto) <= 180 and
                    re.search(r'[,;:]\s+', texto) and
                    not re.search(r'https?://|www\.', texto, re.I)):
                try:
                    reparado_rapido=traduzir_por_fragmentos_residual_google(cliente, texto, origem_google, destino)
                    if reparado_rapido is not None:
                        reparado_rapido=normalizar_espacos_pos_pontuacao_google(texto,reparado_rapido)
                        reparado_rapido=normalizar_termos_ingles_residuais_ptbr(reparado_rapido)
                        validar_resultado_traducao_google(texto,reparado_rapido,tipo_entrada,origem_google,destino)
                        return indice,reparado_rapido,None
                except Exception as fast_exc:
                    ultimo=fast_exc
            log.aviso(u"Resultado com inglês residual em {0}, texto {1}/{2}; tentando Google Translate Web novamente com outra sessão.".format(rel, indice + 1, total))
            for retry_n in range(GOOGLE_RESIDUAL_RETRIES):
                cliente_retry = pool[(base_index + tentativa + retry_n + 1) % max(1, len(pool))]
                try:
                    retry_protegido, retry_tokens = proteger_tokens_google(texto)
                    retry_bruto = cliente_retry.traduzir(retry_protegido, u"en", destino)
                    validar_tokens_google_preservados(retry_bruto, retry_tokens)
                    retry_resultado = restaurar_tokens_google(escapar_percentuais_novos_google(retry_bruto), retry_tokens)
                    retry_resultado = normalizar_espacos_pos_pontuacao_google(texto, retry_resultado)
                    if destino.lower().startswith(u"pt"):
                        retry_resultado = normalizar_termos_ingles_residuais_ptbr(retry_resultado)
                    if parece_residuo_ingles_resultado(texto, retry_resultado, tipo_entrada):
                        melhores.append(retry_resultado)
                        continue
                    validar_resultado_traducao_google(texto, retry_resultado, tipo_entrada, u"en", destino)
                    return indice, retry_resultado, None
                except Exception as retry_exc:
                    ultimo = retry_exc
                    if isinstance(retry_exc, GoogleRateLimitError):
                        continue
                    log.aviso(u"Retentativa Google Translate Web ({0}, texto {1}/{2}): {3}".format(rel, indice + 1, total, retry_exc))

            # Se ainda houver resíduo, NÃO contabilizar como sucesso silencioso.
            # Preservamos o cache de retomada e encerramos esta entrada como falha
            # explícita para que outra execução tente novamente.
            if ultimo is not None and isinstance(ultimo, Exception):
                raise ultimo
            raise GoogleTranslateValidationError(u"resultado contém inglês residual após as tentativas do Google Translate Web")
        except GoogleTranslateValidationError as exc:
            ultimo = exc
            # Primeiro tenta reparar conteúdo visível perdido dentro de tags.
            if u"texto visível dentro de tag foi apagado pela tradução" in str(exc):
                try:
                    reparado_tag = reparar_conteudo_tag_vazio_google(texto, resultado, cliente, origem_google, destino)
                    if reparado_tag is not None:
                        validar_resultado_traducao_google(texto, reparado_tag, tipo_entrada, origem_google, destino)
                        return indice, reparado_tag, None
                except Exception as reparo_tag_exc:
                    ultimo = reparo_tag_exc
            # Falhas de token merecem o fallback por fragmentos existente.
            if (u"token protegido foi removido pela tradução" in str(exc) or
                    u"tokens protegidos foram removidos pela tradução" in str(exc) or
                    u"sequência de tokens protegidos alterada" in str(exc)):
                try:
                    reparado = traduzir_por_fragmentos_sem_tokens_google(cliente, texto, origem_google, destino)
                    if reparado is not None:
                        validar_resultado_traducao_google(texto, reparado, tipo_entrada, origem_google, destino)
                        return indice, reparado, None
                except Exception as reparo_exc:
                    ultimo = reparo_exc
            # Último recurso para residual inglês/resposta idêntica: o mesmo RPC,
            # mesma sessão e mesmo throttle, mas em fragmentos menores.
            try:
                reparado_residual = traduzir_por_fragmentos_residual_google(cliente, texto, origem_google, destino)
                if reparado_residual is not None:
                    reparado_residual = normalizar_espacos_pos_pontuacao_google(texto, reparado_residual)
                    if destino.lower().startswith(u"pt"):
                        reparado_residual = normalizar_termos_ingles_residuais_ptbr(reparado_residual)
                    validar_resultado_traducao_google(texto, reparado_residual, tipo_entrada, origem_google, destino)
                    return indice, reparado_residual, None
            except Exception as reparo_residual_exc:
                ultimo = reparo_residual_exc
        except GoogleRateLimitError as exc:
            ultimo = exc
            # O throttle global já pausou os demais workers. Tentar novamente numa
            # nova sessão só depois do backoff é suficiente; não criar rajadas novas.
            continue
        except Exception as exc:
            ultimo = exc
            if log:
                log.erro(u"Falha worker Google Translate Web ({0}, texto {1}/{2}): {3}".format(rel, indice + 1, total, exc))
            continue

    if ultimo is None:
        ultimo = GoogleTranslateError(u"tradução não produziu resultado")
    return indice, None, ultimo


def carregar_cache_google(caminho):
    if not os.path.isfile(caminho): return {}
    try:
        with io.open(caminho, "r", encoding="utf-8") as f: dados = json.load(f)
        if isinstance(dados, dict) and dados.get(u"schema") == GOOGLE_CACHE_SCHEMA and isinstance(dados.get(u"entries"), dict): return dados[u"entries"]
    except Exception: pass
    return {}


def salvar_cache_google(caminho, cache):
    temp = caminho + u".tmp"
    with io.open(temp, "w", encoding="utf-8") as f:
        json.dump({u"schema": GOOGLE_CACHE_SCHEMA, u"entries": cache}, f, ensure_ascii=False, indent=1)
    os.replace(temp, caminho)

def limpar_cache_google_temporario(caminho):
    """Remove o cache temporário e o arquivo de escrita atomica associado."""
    removido = True
    for alvo in (caminho, caminho + u".tmp"):
        try:
            if os.path.isfile(alvo):
                os.remove(alvo)
        except Exception:
            removido = False
    return removido


def chave_cache_google(origem, destino, texto):
    origem = texto_compativel(origem, u"auto") or u"auto"
    destino = texto_compativel(destino, u"")
    texto = texto_compativel(texto, u"")
    return u"{0}\x1f{1}\x1f{2}\x1f{3}".format(GOOGLE_CACHE_MOTOR_ID, origem.lower(), destino.lower(), texto)



def chave_cache_credito_google(origem, destino, texto):
    origem = texto_compativel(origem, u"auto") or u"auto"
    destino = texto_compativel(destino, u"")
    texto = texto_compativel(texto, u"")
    return u"{0}\x1f{1}\x1f{2}\x1f{3}".format(GOOGLE_CACHE_CREDITOS_MOTOR_ID, origem.lower(), destino.lower(), texto)


def cache_credito_google_pode_reutilizar(cache, chave, fonte, destino):
    valor = cache.get(chave)
    # Migração transparente: V137/V138 gravaram créditos com a chave RPC
    # genérica. Se ela ainda estiver no cache, reaproveitamos e promovemos
    # para a chave específica de créditos, evitando novas requisições.
    if not isinstance(valor, TEXT_TYPES):
        chave_legado = chave_cache_google(u"auto", destino, fonte)
        valor = cache.get(chave_legado)
        if not isinstance(valor, TEXT_TYPES):
            return None
        valor = texto_compativel(valor, u"")
        cache[chave] = valor
    else:
        valor = texto_compativel(valor, u"")
    try:
        src_lines = fonte.splitlines()
        dst_lines = valor.splitlines()
        if len(src_lines) != len(dst_lines):
            return None
        for src_line, dst_line in zip(src_lines, dst_lines):
            src_body = src_line.strip()
            dst_body = dst_line.strip()
            if not src_body:
                if dst_body:
                    return None
                continue
            is_role = (src_body.endswith(':') and _rotulo_credito_eh_categoria(src_body[:-1])) or _linha_credito_role_eh_categoria(src_body)
            if not is_role and src_line != dst_line:
                return None
        validar_integridade_traducao_google(fonte, valor)
        return valor
    except Exception:
        return None


def origem_cache(chave):
    try:
        partes = texto_compativel(chave, u"").split(u"\x1f", 3)
        return partes[1].lower() if len(partes) >= 4 else partes[0].lower()
    except Exception:
        return u"auto"


def origem_cache_is_auto(chave):
    return origem_cache(chave) == u"auto"


def cache_google_pode_reutilizar(cache, chave, fonte, destino, tipo_entrada, rel=u""):
    chave = texto_compativel(chave, u"")
    fonte = texto_compativel(fonte, u"")
    destino = texto_compativel(destino, u"pt-BR")
    tipo_entrada = texto_compativel(tipo_entrada, u"")
    valor = cache.get(chave)
    if not isinstance(valor, TEXT_TYPES):
        return None
    correcao_cache, regra_cache = aplicar_correcao_individual_google(fonte, rel, tipo_entrada, destino, None)
    if correcao_cache is not None:
        valor = correcao_cache
    valor = normalizar_percentuais_para_reintegracao(fonte, valor)
    if destino.lower().startswith(u"pt"):
        valor = normalizar_termos_ingles_residuais_ptbr(valor)
    try:
        try:
            origem_cache_val = origem_cache(chave)
        except Exception:
            origem_cache_val = u"auto"
        validar_resultado_traducao_google(fonte, valor, tipo_entrada, origem_cache_val, destino)
    except Exception:
        return None
    if (destino.lower().startswith(u"pt") and origem_cache_is_auto(chave) and
            ((valor == fonte and
              ((tipo_entrada == u"dialogo" and deve_forcar_retentativa_dialogo(fonte)) or
               (tipo_entrada != u"dialogo" and deve_forcar_retentativa_igual(fonte)))) or
             parece_residuo_ingles_resultado(fonte, valor, tipo_entrada))):
        return None
    return valor


def salvar_cache_google_seguro(cache, chave, fonte, valor):
    # Durante a execução, tradução válida diferente do original nunca é
    # substituída automaticamente por outra resposta do Google.
    # Inglês-original -> tradução efetiva é a única substituição automática.
    if not isinstance(valor, str):
        return False
    atual = cache.get(chave)
    if atual is None or atual == fonte:
        cache[chave] = valor
        return True
    return False


def localizar_pasta_extracao_traducao(raiz):
    candidatos = listar_pastas_dialogos_por_categoria(raiz, {u"extracao"})
    if not candidatos:
        return None, None
    # If more than one extraction folder exists (for example after runs in
    # different interface languages), keep the same explicit choice model.
    if len(candidatos) == 1:
        return candidatos[0][0], candidatos[0][1]
    print(u"")
    print(t("reinj_multiplas_titulo"))
    for i, (caminho, nome_mapa, categoria) in enumerate(candidatos, 1):
        print(t("reinj_multiplas_opcao").format(i, caminho))
    print(u"")
    while True:
        try:
            escolha = input(t("reinj_multiplas_prompt")).strip()
        except (EOFError, KeyboardInterrupt):
            return None, None
        if escolha.isdigit():
            indice = int(escolha) - 1
            if 0 <= indice < len(candidatos):
                return candidatos[indice][0], candidatos[indice][1]
        print(t("reinj_multiplas_invalida"))


def configurar_intervalo_diagnostico(intervalo):
    # Ajuste somente em memória para o teste atual; GOOGLE_INTERVALO_MINIMO
    # continua 0.30s no arquivo e nada é persistido.
    with GOOGLE_THROTTLE.lock:
        GOOGLE_THROTTLE.intervalo_minimo = float(intervalo)
        GOOGLE_THROTTLE.proxima_liberacao = 0.0
        GOOGLE_THROTTLE.backoff_atual = GOOGLE_THROTTLE.backoff_inicial


def _diagnostico_estresse_texto(cliente, texto, origem, destino, indice, parar_evento):
    if parar_evento.is_set():
        return {
            "ok": False, "rate_limit": False, "cancelado": True,
            "worker": cliente.worker_id + 1, "indice": indice,
            "segundos": 0.0, "status": cliente.ultimo_status, "erro": None,
        }
    inicio = time.perf_counter()
    try:
        cliente.traduzir(texto, origem, destino)
        return {
            "ok": True, "rate_limit": False, "cancelado": False,
            "worker": cliente.worker_id + 1, "indice": indice,
            "segundos": time.perf_counter() - inicio,
            "status": cliente.ultimo_status or 200, "erro": None,
        }
    except GoogleRateLimitError as exc:
        parar_evento.set()
        return {
            "ok": False, "rate_limit": True, "cancelado": False,
            "worker": cliente.worker_id + 1, "indice": indice,
            "segundos": time.perf_counter() - inicio,
            "status": cliente.ultimo_status,
            "erro": u"{0}: {1}".format(type(exc).__name__, exc),
            "momento": time.perf_counter(),
        }
    except Exception as exc:
        parar_evento.set()
        return {
            "ok": False, "rate_limit": False, "cancelado": False,
            "worker": cliente.worker_id + 1, "indice": indice,
            "segundos": time.perf_counter() - inicio,
            "status": cliente.ultimo_status,
            "erro": u"{0}: {1}".format(type(exc).__name__, exc),
        }


def executar_diagnostico_estresse_google(raiz):
    caminho_log = os.path.join(raiz, GOOGLE_CACHE_ESTRESSE_NOME)
    log = Log(caminho_log)
    log.separador()
    log.titulo(u"DDAC - Teste de estresse do limite do Google Translate")
    log.info(u"Baseline previamente confirmado: {0:.2f}s (não será refeito neste teste).".format(GOOGLE_DIAGNOSTICO_ESTRESSE_BASELINE))
    log.info(u"Lote por degrau: {0} textos únicos; intervalos: {1}.".format(
        GOOGLE_DIAGNOSTICO_ESTRESSE_LOTE,
        u" -> ".join(u"{0:.2f}s".format(x) for x in GOOGLE_DIAGNOSTICO_ESTRESSE_INTERVALOS)))
    log.info(u"O teste usa o pool real de workers e o GOOGLE_THROTTLE real, somente em memória.")

    print(u"============================================================")
    print(u" TESTE DE ESTRESSE DO GOOGLE TRANSLATE")
    print(u"============================================================")
    print(u"")
    print(u"0,30s já foi confirmado anteriormente; esta calibração começa em 0,25s.")
    print(u"Serão usados {0} textos únicos por degrau, sem alterar arquivos do jogo.".format(GOOGLE_DIAGNOSTICO_ESTRESSE_LOTE))
    print(u"O primeiro HTTP 429 encerra a sondagem; o último degrau limpo fica como referência.")
    print(u"")

    origem = u"auto"
    destino = u"pt-BR"
    try:
        pool = criar_pool_google(log)
    except Exception as exc:
        log.erro(u"Falha ao preparar o pool Google: {0}".format(exc))
        log.salvar()
        print(u"ERRO ao preparar o pool Google: {0}".format(exc))
        return 1

    ultimo_seguro = GOOGLE_DIAGNOSTICO_ESTRESSE_BASELINE
    total_inicio = time.perf_counter()
    resultado_parada = None

    for etapa, intervalo in enumerate(GOOGLE_DIAGNOSTICO_ESTRESSE_INTERVALOS, 1):
        configurar_intervalo_diagnostico(intervalo)
        nonce = int(time.time() * 1000000)
        textos = [
            u"UnRen-DDAC stress {0}-{1}-{2:04d}: texto sintético único para calibração.".format(
                nonce, int(round(intervalo * 100)), i + 1)
            for i in range(GOOGLE_DIAGNOSTICO_ESTRESSE_LOTE)
        ]

        print(u"[DEGRAU {0}/{1}] Intervalo {2:.2f}s | {3} textos | {4} workers".format(
            etapa, len(GOOGLE_DIAGNOSTICO_ESTRESSE_INTERVALOS), intervalo, len(textos), len(pool)))
        log.separador()
        log.info(u"INÍCIO degrau={0:.2f}s lote={1} workers={2}".format(intervalo, len(textos), len(pool)))

        inicio_etapa = time.perf_counter()
        ok = 0
        rate_limits = []
        erros_nao_429 = []
        parar_evento = threading.Event()

        with ThreadPoolExecutor(max_workers=len(pool)) as executor:
            futuros = []
            for indice, texto in enumerate(textos):
                cliente = pool[indice % len(pool)]
                futuros.append(executor.submit(
                    _diagnostico_estresse_texto, cliente, texto, origem, destino, indice + 1, parar_evento
                ))

            for concluido, futuro in enumerate(as_completed(futuros), 1):
                r = futuro.result()
                if r["cancelado"]:
                    pass
                elif r["ok"]:
                    ok += 1
                elif r["rate_limit"]:
                    rate_limits.append(r)
                else:
                    erros_nao_429.append(r)
                if concluido == 1 or concluido == len(textos) or concluido % 10 == 0:
                    print(u"\r  Progresso: {0}/{1}".format(concluido, len(textos)), end=u"")
        print(u"")

        decorrido = time.perf_counter() - inicio_etapa
        log.info(u"FIM degrau={0:.2f}s ok={1} 429={2} erros_não_429={3} tempo={4:.2f}s".format(
            intervalo, ok, len(rate_limits), len(erros_nao_429), decorrido))

        if erros_nao_429:
            primeiro = min(erros_nao_429, key=lambda x: x["indice"])
            resultado_parada = u"inconclusivo"
            print(u"  RESULTADO: INCONCLUSIVO — erro não-429 no texto {0}: {1}".format(
                primeiro["indice"], primeiro["erro"]))
            log.erro(u"Teste inconclusivo em {0:.2f}s por erro não-429 no texto {1}: {2}".format(
                intervalo, primeiro["indice"], primeiro["erro"]))
            break

        if rate_limits:
            primeiro = min(rate_limits, key=lambda x: x.get("momento", x["segundos"]))
            resultado_parada = u"429"
            print(u"  RESULTADO: 429 detectado | texto {0} | Worker {1}".format(
                primeiro["indice"], primeiro["worker"]))
            print(u"  Último degrau sem 429: {0:.2f}s".format(ultimo_seguro))
            log.aviso(u"429 detectado no degrau {0:.2f}s, texto {1}, worker {2}. Último degrau limpo: {3:.2f}s".format(
                intervalo, primeiro["indice"], primeiro["worker"], ultimo_seguro))
            break

        ultimo_seguro = intervalo
        taxa = float(ok) / max(0.001, decorrido)
        print(u"  PASSOU: {0} textos sem 429 | {1:.2f}s | ~{2:.1f} textos/s".format(
            ok, decorrido, taxa))
        log.info(u"PASSOU degrau {0:.2f}s sem 429.".format(intervalo))

    total_decorrido = time.perf_counter() - total_inicio
    print(u"")
    print(u"RESULTADO FINAL")
    print(u"  Último intervalo confirmado sem 429: {0:.2f}s".format(ultimo_seguro))
    if resultado_parada == u"429":
        print(u"  O próximo degrau abaixo desse valor produziu 429 nesta execução.")
    elif resultado_parada == u"inconclusivo":
        print(u"  O teste não atingiu uma conclusão de limite por causa de um erro não-429.")
    else:
        print(u"  Todos os degraus de 0,25s até 0,10s passaram sem 429 nesta execução.")
    print(u"  O valor do script continua configurado em {0:.2f}s; este diagnóstico não o altera no arquivo.".format(GOOGLE_INTERVALO_MINIMO))
    print(u"  Tempo total do diagnóstico: {0:.2f}s".format(total_decorrido))
    print(u"")
    print(u"Log salvo em:")
    print(u"  {0}".format(caminho_log))
    log.resultado(u"Intervalo de referência sem 429", u"{0:.2f}s".format(ultimo_seguro))
    log.resultado(u"Tempo total", u"{0:.2f}s".format(total_decorrido))
    log.separador()
    log.salvar()
    return 0


def _diagnostico_rpc_unico(cliente, origem, destino, numero):
    texto = u"UnRen-DDAC diagnóstico {0}".format(numero)
    inicio = time.perf_counter()
    try:
        resultado = cliente.traduzir(texto, origem, destino)
        decorrido = time.perf_counter() - inicio
        return {
            "ok": True, "host": cliente.nome_host, "worker": cliente.worker_id + 1,
            "segundos": decorrido, "status": cliente.ultimo_status or 200,
            "bytes": cliente.ultimos_bytes, "texto": resultado,
            "erro": None,
        }
    except Exception as exc:
        decorrido = time.perf_counter() - inicio
        return {
            "ok": False, "host": cliente.nome_host, "worker": cliente.worker_id + 1,
            "segundos": decorrido, "status": cliente.ultimo_status,
            "bytes": cliente.ultimos_bytes, "texto": None,
            "erro": u"{0}: {1}".format(type(exc).__name__, exc),
        }


def executar_diagnostico_google(raiz):
    caminho_log = os.path.join(raiz, GOOGLE_CACHE_DIAGNOSTICO_NOME)
    log = Log(caminho_log)
    log.separador()
    log.titulo(u"DDAC - Diagnóstico do Google Translate")
    log.info(u"Teste leve: 1 RPC individual + 4 RPCs concorrentes.")
    log.info(u"O teste usa o endpoint web interno do Google Translate atualmente usado pelo motor.")
    print(u"============================================================")
    print(u" DIAGNÓSTICO DO GOOGLE TRANSLATE")
    print(u"============================================================")
    print(u"")
    print(u"Este teste não altera arquivos do jogo.")
    print(u"Serão feitas 5 traduções reais no endpoint para medir a latência.")
    print(u"")

    origem = u"auto"
    destino = u"pt-BR"
    clientes = []
    print(u"[1/2] Testando a página do Google Translate...")
    for worker in range(4):
        nome, host = GOOGLE_HOSTS[worker % len(GOOGLE_HOSTS)]
        cliente = GoogleRPCClient(nome, host, log, worker)
        inicio = time.perf_counter()
        try:
            cliente.conectar()
            decorrido = time.perf_counter() - inicio
            clientes.append(cliente)
            print(u"  Worker {0} | {1:<12} | HOME {2:6.2f}s | HTTP {3} | f.sid {4} | bl {5}".format(
                worker + 1, nome, decorrido, cliente.ultimo_status or 200,
                u"OK" if cliente.fsid else u"não", u"dinâmico" if cliente.bl != GOOGLE_STATIC_BL else u"estático"))
            log.info(u"HOME worker={0} host={1} tempo={2:.3f}s status={3} fsid={4} bl={5}".format(
                worker + 1, nome, decorrido, cliente.ultimo_status or 200,
                u"sim" if cliente.fsid else u"não", u"dinâmico" if cliente.bl != GOOGLE_STATIC_BL else u"estático"))
        except Exception as exc:
            decorrido = time.perf_counter() - inicio
            print(u"  Worker {0} | {1:<12} | HOME FALHOU em {2:.2f}s | {3}".format(worker + 1, nome, decorrido, exc))
            log.erro(u"HOME worker={0} host={1} tempo={2:.3f}s erro={3}".format(worker + 1, nome, decorrido, exc))

    if not clientes:
        print(u"")
        print(u"Nenhuma sessão Google pôde ser preparada.")
        log.salvar()
        return 1

    print(u"")
    print(u"[2/2] Testando o endpoint REAL de tradução...")
    base = _diagnostico_rpc_unico(clientes[0], origem, destino, 1)
    if base["ok"]:
        print(u"  RPC individual | {0:<12} | {1:6.2f}s | HTTP {2} | resposta {3} bytes".format(
            base["host"], base["segundos"], base["status"], base["bytes"]))
    else:
        print(u"  RPC individual | {0:<12} | FALHOU após {1:6.2f}s | {2}".format(
            base["host"], base["segundos"], base["erro"]))
    log.info(u"RPC individual host={0} tempo={1:.3f}s status={2} ok={3} erro={4}".format(
        base["host"], base["segundos"], base["status"], base["ok"], base["erro"] or u"-"))

    inicio_conc = time.perf_counter()
    resultados = []
    with ThreadPoolExecutor(max_workers=len(clientes)) as executor:
        futuros = [executor.submit(_diagnostico_rpc_unico, cliente, origem, destino, i + 2) for i, cliente in enumerate(clientes)]
        for futuro in as_completed(futuros):
            resultados.append(futuro.result())
    tempo_onda = time.perf_counter() - inicio_conc
    resultados.sort(key=lambda item: item["worker"])

    print(u"")
    print(u"  Concorrência: {0} requisições simultâneas | onda {1:.2f}s".format(len(resultados), tempo_onda))
    for r in resultados:
        if r["ok"]:
            print(u"    Worker {0} | {1:<12} | {2:6.2f}s | HTTP {3}".format(r["worker"], r["host"], r["segundos"], r["status"]))
        else:
            print(u"    Worker {0} | {1:<12} | FALHOU {2:6.2f}s | {3}".format(r["worker"], r["host"], r["segundos"], r["erro"]))
        log.info(u"RPC concorrente worker={0} host={1} tempo={2:.3f}s status={3} ok={4} erro={5}".format(
            r["worker"], r["host"], r["segundos"], r["status"], r["ok"], r["erro"] or u"-"))

    sucessos = [r for r in resultados if r["ok"]]
    if base["ok"] and sucessos:
        menor = min(r["segundos"] for r in sucessos)
        maior = max(r["segundos"] for r in sucessos)
        media = sum(r["segundos"] for r in sucessos) / len(sucessos)
        print(u"")
        print(u"RESULTADO")
        print(u"  RPC individual: {0:.2f}s".format(base["segundos"]))
        print(u"  RPC concorrente: min {0:.2f}s | média {1:.2f}s | máx {2:.2f}s".format(menor, media, maior))
        if base["segundos"] >= 5.0:
            print(u"  INDÍCIO: uma única requisição já está lenta; o gargalo está no caminho do RPC/Google, não na barra de progresso do script.")
        elif maior >= max(5.0, base["segundos"] * 2.0):
            print(u"  INDÍCIO: a latência cresce bastante com concorrência; há possível contenção/throttling no endpoint.")
        else:
            print(u"  INDÍCIO: a latência do RPC está baixa e relativamente estável; o problema pode estar além deste teste.")
    elif not base["ok"]:
        print(u"")
        print(u"  INDÍCIO: a requisição real de tradução falhou; o teste da página inicial, sozinho, não garante que o endpoint de tradução esteja saudável.")
    else:
        print(u"")
        print(u"  Nenhum RPC concorrente retornou sucesso.")

    print(u"")
    print(u"Log salvo em:")
    print(u"  {0}".format(caminho_log))
    log.salvar()
    return 0


def testar_conexao_google(log=None):
    # Apenas abre a home do Google Translate; não consome uma tradução.
    pool=criar_pool_google(log)
    return pool


def executar_traducao_google(raiz):
    inicio_total=time.time()
    pasta_entrada,nome_mapa=localizar_pasta_extracao_traducao(raiz)
    if not pasta_entrada:
        print(t("t_sem_extracao")); return 1
    caminho_mapa=os.path.join(pasta_entrada,nome_mapa)
    try:
        with io.open(caminho_mapa,"r",encoding="utf-8") as f: mapa_completo=json.load(f)
    except Exception as exc:
        print(t("t_mapa_invalido").format(exc)); return 1
    try:
        origem=normalizar_idioma_codigo(input(t("t_origem_prompt")).strip(),u"auto")
        destino=normalizar_idioma_codigo(input(t("t_destino_prompt")).strip(),u"pt-BR")
    except (EOFError,KeyboardInterrupt):
        print(t("t_cancelado")); return 0
    if not validar_codigo_idioma(origem) or not validar_codigo_idioma(destino) or destino==u"auto":
        print(t("t_erro_conexao").format(u"código de idioma inválido: origem={0}, destino={1}".format(origem,destino))); return 1

    total_global=sum(len(v) for _,v in sorted(mapa_completo.items()))
    log=Log(os.path.join(raiz,NOME_LOG_TRADUTOR)); log.separador(); log.titulo(u"DDAC Tradução com Google Translate Web RPC - INÍCIO DA EXECUÇÃO")
    log.info(t("t_log_pasta").format(pasta_entrada)); pasta_saida=os.path.join(raiz,PASTA_TRADUCAO_GOOGLE_NOME); log.info(t("t_log_saida").format(pasta_saida))
    log.info(u"Idioma de origem: {0} | idioma de destino: {1}".format(origem,destino))
    log.info(u"Mapa não é traduzido; somente textos apontados por ele são processados.")
    log.info(u"Motor Google: Google Translate Web (RPC) | {0} workers | janela dinâmica {1} tarefas | blocos de escalonamento de {2} entradas | intervalo global mínimo de {3:.2f}s | cooldown crescente em 429. Paralelismo distribuído entre arquivos, fila dinâmica, cache persistente e auditoria final independente.".format(GOOGLE_WORKERS, GOOGLE_WORKERS*GOOGLE_JOB_WINDOW_MULTIPLIER, GOOGLE_SCHEDULER_CHUNK, GOOGLE_INTERVALO_MINIMO))

    try:
        pool=testar_conexao_google(log)
    except Exception as exc:
        log.erro(u"Teste de conexão: {0}".format(exc)); log.salvar(); print(t("t_erro_conexao").format(exc)); return 1
    print(t("t_conectado")); print(t("t_processando").format(total_global))

    pasta_saida_real=os.path.realpath(pasta_saida)
    raiz_real=os.path.realpath(raiz)
    esperado_saida=os.path.realpath(os.path.join(raiz_real, PASTA_TRADUCAO_GOOGLE_NOME))
    if pasta_saida_real != esperado_saida or os.path.dirname(pasta_saida_real) != raiz_real or os.path.basename(pasta_saida_real) != PASTA_TRADUCAO_GOOGLE_NOME:
        raise RuntimeError(u"Bloqueio de segurança: a pasta de saída da tradução não corresponde ao diretório DDAC esperado.")
    if os.path.isdir(pasta_saida):
        shutil.rmtree(pasta_saida)
    shutil.copytree(pasta_entrada,pasta_saida)

    # Cache temporário de retomada: NÃO apagar no início. A V124 apagava o
    # próprio cache antes de carregá-lo, impedindo a retomada real.
    cache_temp_path=os.path.join(raiz, GOOGLE_CACHE_NOME)
    cache_dir_persistente=os.path.join(raiz, GOOGLE_CACHE_PERSISTENTE_DIR)
    cache_persistente_path=os.path.join(cache_dir_persistente, GOOGLE_CACHE_PERSISTENTE_NOME)
    if not os.path.isdir(os.path.dirname(cache_temp_path)):
        os.makedirs(os.path.dirname(cache_temp_path))
    if not os.path.isdir(cache_dir_persistente):
        os.makedirs(cache_dir_persistente)

    modo_cache=os.environ.get("DDAC_GT_CACHE_MODE", "usar").strip().lower()
    if modo_cache in (u"clear",u"limpar",u"3"):
        try:
            if os.path.isfile(cache_persistente_path): os.remove(cache_persistente_path)
            if os.path.isfile(cache_persistente_path+u".tmp"): os.remove(cache_persistente_path+u".tmp")
        except Exception: pass
        modo_cache=u"usar"
    usar_cache_persistente = modo_cache not in (u"ignore",u"ignorar",u"0",u"nao",u"não")
    cache_persistente=carregar_cache_google(cache_persistente_path) if usar_cache_persistente else {}
    cache_temp=carregar_cache_google(cache_temp_path)
    cache={}
    cache.update(cache_persistente); cache.update(cache_temp)
    cache_lock=threading.Lock()

    if usar_cache_persistente:
        log.info(u"Cache persistente ATIVO: {0}".format(cache_persistente_path))
    else:
        log.info(u"Cache persistente IGNORADO nesta execução. Para usar novamente, remova DDAC_GT_CACHE_MODE=ignore do ambiente.")
    if cache_temp:
        log.info(u"Cache de retomada encontrado: {0} entrada(s) válidas carregadas de {1}.".format(len(cache_temp), cache_temp_path))

    arquivos=[]
    filas={}
    total_cache_reutilizado=0
    total_persistente_reutilizado=0
    total_temp_reutilizado=0
    total_urls_preservadas=0
    total_global_done=0

    for rel,entradas in sorted(mapa_completo.items()):
        caminho=os.path.join(pasta_saida,rel.replace(u"/",os.sep))
        inicio_pre=time.time()
        try:
            with io.open(caminho,"r",encoding="utf-8",errors="replace",newline="") as f:
                linhas=f.read().splitlines(True)
            indices=[i for i,linha in enumerate(linhas) if linha.strip() and not linha.strip().startswith(u"#")]
            if len(indices)!=len(entradas):
                raise ValueError(u"contagem do arquivo ({0}) diferente do mapa ({1})".format(len(indices),len(entradas)))
            fontes=[]
            tipos=[]
            config_prot=[]
            resultados=[None]*len(indices)
            pendentes=[]
            for ordem,i in enumerate(indices):
                literal_origem=linhas[i].strip()
                if not literal_unico_traduzivel(literal_origem):
                    raise ValueError(u"entrada do mapa não é um literal único na linha {0}: {1}".format(i+1,literal_origem))
                fonte=decodificar_literal_traducao(literal_origem)
                fontes.append(texto_compativel(fonte,u""))
                entrada=entradas[ordem]
                tipo_bruto=entrada.get("tipo") if isinstance(entrada,dict) else None
                tipo_seguro=texto_compativel(tipo_bruto,u"")
                tipos.append(tipo_seguro)
                config_prot.append(entrada_eh_config_name_global(entrada))
            for i,fonte in enumerate(fontes):
                entrada_meta=entradas[i] if isinstance(entradas[i],dict) else {}
                # Blocos de créditos usam uma chave de cache própria. A V138
                # forçava todos os créditos de volta à fila em toda execução; isso
                # deixava 15-20 entradas "novas" mesmo depois de traduzidas.
                # Agora eles são processados uma vez e reaproveitados normalmente.
                if parece_bloco_creditos_google(fonte, rel, tipos[i]):
                    tipos[i]=u"texto_creditos_bloco"
                    chave_credito=chave_cache_credito_google(origem,destino,fonte)
                    valor_credito=cache_credito_google_pode_reutilizar(cache,chave_credito,fonte,destino)
                    if valor_credito is not None:
                        resultados[i]=normalizar_espacos_pos_pontuacao_google(fonte,valor_credito)
                        total_global_done+=1; total_cache_reutilizado+=1
                        if chave_credito in cache_persistente: total_persistente_reutilizado+=1
                        elif chave_credito in cache_temp: total_temp_reutilizado+=1
                    else:
                        pendentes.append((i,fonte,chave_credito,tipos[i]))
                    continue
                if config_prot[i] or entrada_meta.get(u"nao_traduzir") or entrada_nao_traduzivel_google(fonte, rel, tipos[i]):
                    resultados[i]=fonte; total_global_done+=1
                    continue
                if tipos[i]==u"url_visivel":
                    resultados[i]=fonte; total_urls_preservadas+=1; total_global_done+=1
                    continue
                chave=chave_cache_google(origem,destino,fonte)
                valor=cache_google_pode_reutilizar(cache,chave,fonte,destino,tipos[i],rel)
                if valor is not None:
                    valor=normalizar_espacos_pos_pontuacao_google(fonte,valor)
                    resultados[i]=valor; total_global_done+=1; total_cache_reutilizado+=1
                    if chave in cache_persistente: total_persistente_reutilizado+=1
                    elif chave in cache_temp: total_temp_reutilizado+=1
                else:
                    pendentes.append((i,fonte,chave,tipos[i]))
            arquivos.append({u"rel":rel,u"caminho":caminho,u"linhas":linhas,u"indices":indices,u"fontes":fontes,u"tipos":tipos,u"resultados":resultados,u"pendentes":pendentes,u"inicio":inicio_pre})
            if pendentes:
                filas[rel]=list(pendentes)
            print(u"  {0} | cache {1} | pendentes {2}/{3}".format(rel, len(fontes)-len(pendentes), len(pendentes), len(fontes)))
        except Exception as exc:
            log.erro(u"PRÉ-PROCESSAMENTO FALHOU {0}: {1}".format(rel,exc)); log.salvar(); print(u"AVISO {0}: {1}".format(rel,exc))
            arquivos.append({u"rel":rel,u"erro":exc,u"linhas":[],u"indices":[],u"fontes":[],u"tipos":[],u"resultados":[],u"pendentes":[]})

    total_pendentes=sum(len(v) for v in filas.values())
    print(u"Fila global: {0} tradução(ões) novas | cache persistente {1} | cache de retomada {2}".format(total_pendentes,total_persistente_reutilizado,total_temp_reutilizado))
    log.info(u"Fila global criada: {0} traduções pendentes, {1} reaproveitadas do cache persistente, {2} do cache de retomada.".format(total_pendentes,total_persistente_reutilizado,total_temp_reutilizado))

    # Escalonamento round-robin por blocos: cada arquivo recebe até N entradas
    # por rodada. Assim arquivos grandes não monopolizam a fila e arquivos
    # pequenos terminam rapidamente, enquanto 5 workers continuam ocupados.
    rels=[r for r in sorted(filas.keys(), key=lambda x: (-len(filas[x]), x))]
    jobs=[]
    filas_mut={r:list(v) for r,v in filas.items()}
    while True:
        adicionou=False
        for rel in rels:
            q=filas_mut.get(rel,[])
            if not q: continue
            parte=q[:GOOGLE_SCHEDULER_CHUNK]
            del q[:GOOGLE_SCHEDULER_CHUNK]
            for item in parte:
                jobs.append((rel,)+item)
            adicionou=True
        if not adicionou: break

    por_rel={a[u"rel"]:a for a in arquivos}
    total_jobs=len(jobs); concluido_jobs=0; falhas_def=0; falhas_registradas=set(); scheduler_index=0
    janela=max(GOOGLE_WORKERS, GOOGLE_WORKERS*GOOGLE_JOB_WINDOW_MULTIPLIER)
    pos_job=0
    ultimo_cache_temp_salvo=0
    ultimo_heartbeat=time.time()
    if total_jobs:
        with ThreadPoolExecutor(max_workers=len(pool)) as executor:
            futuros={}
            def enfileirar():
                nonlocal pos_job, scheduler_index
                while pos_job < total_jobs and len(futuros) < janela:
                    rel,i,fonte,chave,tipo=jobs[pos_job]
                    futuro=executor.submit(traduzir_texto_worker,fonte,origem,destino,pool,i,len(por_rel[rel][u"fontes"]),log,rel,tipo,scheduler_index)
                    futuros[futuro]=(rel,i,fonte,chave)
                    pos_job+=1; scheduler_index+=1
            enfileirar()
            while futuros:
                agora_heartbeat=time.time()
                faltam=max(0,total_jobs-concluido_jobs)
                concluidos, _ = wait(list(futuros.keys()), timeout=GOOGLE_HEARTBEAT_SEGUNDOS, return_when=FIRST_COMPLETED)
                if not concluidos:
                    decorrido_sem_evento=agora_heartbeat-ultimo_heartbeat if ultimo_heartbeat else GOOGLE_HEARTBEAT_SEGUNDOS
                    # O heartbeat só avisa uma vez por período de espera.
                    # A barra de progresso principal continua sendo atualizada
                    # quando alguma tradução realmente termina.
                    if decorrido_sem_evento >= GOOGLE_HEARTBEAT_SEGUNDOS:
                        print(u"\n[Aguardando Google Translate Web] {0:5.1f}% | {1}/{2} | {3} tarefa(s) em voo | sem nova conclusão há {4:.0f}s".format(100.0*concluido_jobs/max(1,total_jobs),concluido_jobs,total_jobs,len(futuros),max(0.0,decorrido_sem_evento)), flush=True)
                        ultimo_heartbeat=time.time()
                    continue
                ultimo_heartbeat=time.time()
                for futuro in concluidos:
                    rel,i,fonte,chave=futuros.pop(futuro)
                    try:
                        indice,valor,erro=futuro.result()
                    except Exception as exc:
                        indice,valor,erro=i,None,exc
                    arq=por_rel[rel]
                    if erro is None and valor is not None:
                        with cache_lock:
                            salvar_cache_google_seguro(cache,chave,fonte,valor)
                        arq[u"resultados"][indice]=valor
                        total_global_done+=1
                    else:
                        arq[u"resultados"][indice]=fonte
                        falhas_def+=1
                        falhas_registradas.add((rel,indice))
                        log.erro(u"Falha definitiva: {0} texto {1}/{2}: {3}".format(rel,indice+1,len(arq[u"fontes"]),erro))
                        total_global_done+=1
                    concluido_jobs+=1
                    if concluido_jobs==1 or concluido_jobs==total_jobs or concluido_jobs%10==0:
                        print(u"\rProgresso Google Translate Web: {0:5.1f}% | {1}/{2} | cache {3} | workers {4}".format(100.0*concluido_jobs/max(1,total_jobs),concluido_jobs,total_jobs,total_cache_reutilizado,len(pool)), end=u"", flush=True)
                # Cache de retomada: salvar em blocos. Antes ele era regravado
                # após praticamente TODA conclusão, fazendo o custo de disco crescer
                # com o tamanho da fila e podendo aparentar um congelamento no final.
                if (concluido_jobs - ultimo_cache_temp_salvo >= GOOGLE_CACHE_TEMP_SAVE_A_CADA or concluido_jobs == total_jobs):
                    salvar_cache_google(cache_temp_path,cache)
                    ultimo_cache_temp_salvo=concluido_jobs
                    # O log detalhado também passa a ser persistido durante a execução.
                    log.salvar()
                    print(u"\rProgresso Google Translate Web: {0:5.1f}% | {1}/{2} | cache {3} | workers {4} | checkpoint salvo".format(100.0*concluido_jobs/max(1,total_jobs),concluido_jobs,total_jobs,total_cache_reutilizado,len(pool)), end=u"", flush=True)
                if usar_cache_persistente and (concluido_jobs % GOOGLE_CACHE_PERSISTENTE_SAVE_A_CADA == 0 or concluido_jobs == total_jobs):
                    salvar_cache_google(cache_persistente_path,cache)
                enfileirar()
        print(u"")

    total_arquivos=0; total_textos=0
    for arq in arquivos:
        if arq.get(u"erro") is not None:
            continue
        try:
            rel=arq[u"rel"]; linhas=arq[u"linhas"]; indices=arq[u"indices"]; resultados=arq[u"resultados"]
            for ordem,idx in enumerate(indices):
                linha=linhas[idx]; fim=u"\r\n" if linha.endswith(u"\r\n") else (u"\n" if linha.endswith(u"\n") else u"")
                corpo=linha[:-len(fim)] if fim else linha
                prefixo=corpo[:len(corpo)-len(corpo.lstrip())]
                valor=resultados[ordem] if resultados[ordem] is not None else arq[u"fontes"][ordem]
                linhas[idx]=prefixo+codificar_literal_traducao(valor)+fim
            with io.open(arq[u"caminho"],"w",encoding="utf-8",newline="") as f:
                f.write(u"".join(linhas))
            total_arquivos+=1; total_textos+=len(indices)
            pend=len(arq[u"pendentes"]); cache_count=len(indices)-pend
            tempo_arquivo=time.time()-arq[u"inicio"]
            log.resultado(rel,u"{0} texto(s) | cache inicial {1} | novos {2} | tempo {3:.1f}s".format(len(indices),cache_count,pend,tempo_arquivo))
        except Exception as exc:
            falhas_def+=1; log.erro(u"ARQUIVO FALHOU NA GRAVAÇÃO {0}: {1}".format(arq.get(u"rel",u"?"),exc))

    # Auditoria final independente: nenhuma execução pode declarar sucesso se
    # uma saída válida não passar novamente pela mesma validação após toda a fila.
    auditoria_falhas = 0
    for arq in arquivos:
        if arq.get(u"erro") is not None:
            continue
        for ordem, valor_aud in enumerate(arq[u"resultados"]):
            if (arq[u"rel"], ordem) in falhas_registradas:
                continue
            fonte_aud = arq[u"fontes"][ordem]
            tipo_aud = arq[u"tipos"][ordem]
            if valor_aud is None:
                auditoria_falhas += 1
                log.erro(u"Auditoria final: {0} texto {1}/{2} sem resultado.".format(arq[u"rel"], ordem + 1, len(arq[u"fontes"])))
                arq[u"resultados"][ordem] = fonte_aud
                continue
            valor_aud = normalizar_termos_ingles_residuais_ptbr(valor_aud) if destino.lower().startswith(u"pt") else valor_aud
            arq[u"resultados"][ordem] = valor_aud
            try:
                validar_resultado_traducao_google(fonte_aud, valor_aud, tipo_aud, origem, destino)
            except Exception as exc:
                auditoria_falhas += 1
                falhas_registradas.add((arq[u"rel"], ordem))
                log.erro(u"Auditoria final: {0} texto {1}/{2} rejeitado: {3}".format(arq[u"rel"], ordem + 1, len(arq[u"fontes"]), exc))
                # Não mascarar uma falha com uma tradução que o validador recusou.
                arq[u"resultados"][ordem] = fonte_aud

    falhas_def += auditoria_falhas

    salvar_cache_google(cache_temp_path,cache)
    if usar_cache_persistente:
        salvar_cache_google(cache_persistente_path,cache)
    tempo_total=time.time()-inicio_total
    print(u"Fila de tradução concluída: {0}/{1}. Tempo total: {2:.1f}s".format(total_jobs,total_jobs,tempo_total))
    total_requests=sum(getattr(c,u"requests",0) for c in pool)
    total_429=sum(getattr(c,u"rate_limits",0) for c in pool)
    latencias=[x for c in pool for x in getattr(c,u"latencias",[])]
    media_lat=sum(latencias)/len(latencias) if latencias else 0.0
    log.separador(); log.resultado(u"Motor",u"Google Translate Web RPC v1"); log.resultado(u"Arquivos processados",str(total_arquivos)); log.resultado(u"Textos processados",str(total_textos)); log.resultado(u"URLs visíveis preservadas",str(total_urls_preservadas)); log.resultado(u"Cache persistente reutilizado",str(total_persistente_reutilizado)); log.resultado(u"Cache de retomada reutilizado",str(total_temp_reutilizado)); log.resultado(u"Falhas definitivas",str(falhas_def)); log.resultado(u"Requisições HTTP",str(total_requests)); log.resultado(u"HTTP 429",str(total_429)); log.resultado(u"Latência média por requisição",u"{0:.3f}s".format(media_lat)); log.resultado(u"Tempo total",u"{0:.1f}s".format(tempo_total))
    if falhas_def == 0:
        removido=limpar_cache_google_temporario(cache_temp_path)
        if removido:
            log.info(u"Cache temporário de retomada removido ao concluir com sucesso; cache persistente preservado em: {0}".format(cache_persistente_path))
        else:
            log.aviso(u"Não foi possível remover imediatamente o cache temporário: {0}".format(cache_temp_path))
        log.info(u"Tradução concluída com sucesso; todos os textos receberam resultado.")
        mensagem_final=t("t_pronto").format(pasta_saida)
    else:
        log.aviso(u"Tradução incompleta: {0} falha(s) definitiva(s). Cache temporário preservado para retomada: {1}".format(falhas_def,cache_temp_path))
        mensagem_final=u"Tradução incompleta. O cache de retomada foi preservado; execute novamente para continuar."
    log.titulo(u"DDAC Tradução com Google Translate Web RPC - FIM DA EXECUÇÃO"); log.salvar(); print(u""); print(mensagem_final); return 0 if falhas_def==0 else 1


# =============================================================================
# REINTEGRAÇÃO E VALIDAÇÃO
# =============================================================================
def sha256_arquivo(caminho):
    import hashlib
    h=hashlib.sha256()
    with open(caminho,"rb") as f:
        while True:
            bloco=f.read(1024*1024)
            if not bloco:
                break
            h.update(bloco)
    return h.hexdigest()


def comparar_literal_traducao(a,b,tipo=None):
    """Compara dois literais pelo conteúdo semântico, sem tratar reformatação como tradução."""
    va=decodificar_literal_traducao(a)
    vb=decodificar_literal_traducao(b)
    if tipo==u"poema_corpo":
        # O extrator normaliza a representação dos corpos de poema e pode remover
        # apenas o espaço final estrutural que existe no literal original.
        return va.rstrip()==vb.rstrip()
    return va==vb


def validar_pre_reintegracao(pasta_game,pasta_entrada_base,mapa_completo,candidatos):
    erros=[]; mapa_chaves=set(mapa_completo.keys()); candidatos_map=set()
    entradas_esperadas=sum(len(v) for v in mapa_completo.values()); entradas_encontradas=0; alterados=0; iguais=0
    for caminho in candidatos:
        rel=os.path.relpath(caminho,pasta_entrada_base).replace(os.sep,"/")
        if rel not in mapa_completo:
            if caminho.lower().endswith(".txt") and not os.path.isfile(os.path.join(pasta_game,rel)):
                erros.append(u"TXT sem correspondente no game original: {0}".format(rel))
            continue
        candidatos_map.add(rel); original=os.path.join(pasta_game,rel)
        if not os.path.isfile(original):
            erros.append(t("rj_sem_original").format(original)); continue
        try: textos=ler_textos_traduzidos(caminho)
        except Exception as exc: erros.append(u"Falha ao ler tradução {0}: {1}".format(rel,exc)); continue
        entradas=mapa_completo[rel]; entradas_encontradas+=len(textos)
        try:
            linhas_validacao=ler_linhas_raw(original)
            source_hashes={e.get('source_sha256') for e in entradas if e.get('source_sha256')}
            if source_hashes and (len(source_hashes)!=1 or next(iter(source_hashes))!=sha256_arquivo(original)):
                erros.append(u"{}: SHA-256 do arquivo original não corresponde ao mapa.".format(rel)); continue
            for e in entradas:
                numero=int(e.get('linha',0) or 0)
                if numero<1 or numero>len(linhas_validacao):
                    erros.append(u"{}: linha inválida no mapa: {}".format(rel,numero)); continue
                linha=linhas_validacao[numero-1]
                if e.get('source_line_hash') and e.get('source_line_hash')!=_sha256_texto_utf8(linha):
                    erros.append(u"{}: hash da linha mudou na linha {}.".format(rel,numero))
                if e.get('context_hash') and e.get('context_hash')!=_hash_contexto_linhas(linhas_validacao,numero):
                    erros.append(u"{}: contexto da linha mudou na linha {}.".format(rel,numero))
                if e.get('token_signature') is not None and e.get('token_signature')!=_token_signature_mapa(e.get('original',u'')):
                    erros.append(u"{}: assinatura de tokens do mapa está inconsistente na linha {}.".format(rel,numero))
                if e.get('entry_id'):
                    base_id=u'{0}\0{1}\0{2}\0{3}\0{4}'.format(e.get('source_sha256',u''),numero,e.get('coluna_inicio',0),e.get('coluna_fim',0),e.get('original',u''))
                    esperado_id=hashlib.sha256(base_id.encode('utf-8')).hexdigest()[:24]
                    if e.get('entry_id')!=esperado_id:
                        erros.append(u"{}: entry_id inconsistente na linha {}.".format(rel,numero))
            if any(u"hash da linha mudou" in x or u"contexto da linha mudou" in x or u"assinatura de tokens" in x or u"entry_id inconsistente" in x for x in erros if x.startswith(rel+u':')):
                continue
        except Exception as exc:
            erros.append(u"{}: falha validando integridade do mapa: {}".format(rel,exc)); continue
        if len(textos)!=len(entradas):
            erros.append(u"{0}: {1}".format(rel,t("rj_contagem").format(len(entradas),len(textos)))); continue
        try: _,rj_erros=reinjetar_arquivo(original,entradas,textos)
        except Exception as exc: rj_erros=[str(exc)]
        for erro in rj_erros: erros.append(u"{0}: {1}".format(rel,erro))
        for entrada,traduzido in zip(entradas,textos):
            if comparar_literal_traducao(traduzido, entrada.get("original", ""), entrada.get("tipo")): iguais+=1
            else: alterados+=1
    for rel in sorted(mapa_chaves-candidatos_map):
        erros.append(u"Arquivo mapeado não encontrado na pasta selecionada: {0}".format(rel))
    return {"erros":erros,"arquivos_esperados":len(mapa_chaves),"arquivos_validados":len(candidatos_map),"entradas_esperadas":entradas_esperadas,"entradas_encontradas":entradas_encontradas,"alterados":alterados,"iguais":iguais}


def validar_pos_reintegracao(pasta_game,pasta_saida_wrap,pasta_entrada_base,mapa_completo,candidatos,removidos_intencionais=None):
    erros=[]
    removidos_intencionais=set(_dual_norm_rel(x) for x in (removidos_intencionais or []))
    orig_files=set(); out_files=set()
    for raiz_dir,_,arquivos in os.walk(pasta_game):
        for nome in arquivos: orig_files.add(os.path.relpath(os.path.join(raiz_dir,nome),pasta_game).replace(os.sep,"/"))
    for raiz_dir,_,arquivos in os.walk(pasta_saida_wrap):
        for nome in arquivos: out_files.add(os.path.relpath(os.path.join(raiz_dir,nome),pasta_saida_wrap).replace(os.sep,"/"))
    for rel in sorted(orig_files-out_files):
        if _dual_norm_rel(rel) in removidos_intencionais:
            continue
        erros.append(u"Arquivo original ausente na saída: {0}".format(rel))
    for rel in sorted(out_files-orig_files): erros.append(u"Arquivo inesperado criado na saída: {0}".format(rel))
    for rel in sorted(orig_files & out_files):
        original=os.path.join(pasta_game,rel); saida=os.path.join(pasta_saida_wrap,rel)
        if rel in mapa_completo:
            try:
                entrada_path=os.path.join(pasta_entrada_base,rel.replace("/",os.sep)); textos=ler_textos_traduzidos(entrada_path)
                esperadas,rj_erros=reinjetar_arquivo(original,mapa_completo[rel],textos)
                if rj_erros:
                    for erro in rj_erros: erros.append(u"{0}: {1}".format(rel,erro)); continue
                with io.open(saida,"r",encoding="utf-8",errors="replace",newline="") as f: real=f.read()
                if real!=u"".join(esperadas): erros.append(u"Conteúdo reintegrado diferente do esperado: {0}".format(rel))
            except Exception as exc: erros.append(u"Falha na validação de {0}: {1}".format(rel,exc))
        else:
            try:
                if sha256_arquivo(original)!=sha256_arquivo(saida): erros.append(u"Arquivo fora do mapa foi alterado: {0}".format(rel))
            except Exception as exc: erros.append(u"Falha comparando {0}: {1}".format(rel,exc))
    return {"erros":erros,"total_orig":len(orig_files),"total_saida":len(out_files)}


def criar_backup_saida(raiz,pasta_saida_wrap):
    if not os.path.isdir(pasta_saida_wrap): return None
    stamp=time.strftime("%Y%m%d-%H%M%S")
    destino=os.path.join(raiz,u"UnRen-DDAC-Backup-Reintegração-{}".format(stamp))
    shutil.copytree(pasta_saida_wrap,destino)
    return destino



def limpar_compilados_sombreados(pasta_raiz, log=None):
    """Remove .rpyc/.rpymc da saída mesclada.

    A distribuição do DDAC leva os arquivos-fonte como autoridade. Os arquivos
    compilados antigos são desnecessários na pasta mesclada e aumentam o custo
    da cópia; o Ren'Py pode recompilar o código na primeira inicialização.
    """
    removidos=[]
    if not os.path.isdir(pasta_raiz): return removidos
    for pasta_atual,subpastas,arquivos in os.walk(pasta_raiz):
        subpastas[:]=[d for d in subpastas if d.lower() not in (u'__pycache__',)]
        for nome in list(arquivos):
            if not nome.lower().endswith((u'.rpyc',u'.rpymc')): continue
            caminho=os.path.join(pasta_atual,nome)
            try:
                os.remove(caminho)
                removidos.append(os.path.relpath(caminho,pasta_raiz).replace(os.sep,'/'))
            except Exception as exc:
                if log is not None:
                    log.aviso(u'Não foi possível remover compilado {}: {}'.format(os.path.relpath(caminho,pasta_raiz),exc))
    if log is not None and removidos:
        log.info(u'Compilados removidos da saída mesclada: {}'.format(len(removidos)))
    return removidos


def executar_reinjecao(raiz):
    inicio_total=time.time()
    pasta_game=encontrar_pasta_game(raiz)
    pasta_entrada_base,nome_mapa_reinj=localizar_pasta_reinjecao(raiz)
    pasta_saida_base=os.path.join(raiz,PASTA_SAIDA_TRADUZIDO_NOME)
    caminho_mapa_completo=os.path.join(pasta_entrada_base,nome_mapa_reinj) if pasta_entrada_base else None
    nome_pasta_wrap=os.path.basename(os.path.normpath(pasta_game))
    pasta_saida_wrap=os.path.join(pasta_saida_base,nome_pasta_wrap)

    log=Log(os.path.join(raiz,NOME_LOG_REINJETOR)); log.separador(); log.titulo(t("log_cab_reinjetor")); log.titulo(t("log_datahora").format(time.strftime("%d/%m/%Y %H:%M:%S"))); log.separador()
    log.info(t("log_pasta_traducao").format(os.path.basename(pasta_entrada_base) if pasta_entrada_base else "-",pasta_entrada_base or "-")); log.info(t("log_pasta_original").format(pasta_game)); log.info(t("log_pasta_saida").format(pasta_saida_wrap))
    print("============================================================"); print(t("cab_reinjetar")); print("============================================================"); print(""); print(t("pasta_traducao").format(pasta_entrada_base or "-")); print(t("pasta_original").format(pasta_game)); print(t("pasta_saida2").format(pasta_saida_wrap)); print("")
    if not pasta_entrada_base:
        msg=t("err_pasta_entrada"); print(t("erro")+": "+msg); log.erro(msg); log.salvar(); return 1
    if not os.path.isfile(caminho_mapa_completo):
        msg=t("err_mapa").format(nome_mapa_reinj,os.path.basename(pasta_entrada_base)); print(t("erro")+": "+msg); log.erro(msg); log.salvar(); return 1

    print(t("rj_modo_titulo")); print(u""); print(t("rj_modo_normal")); print(t("rj_modo_seguro")); print(u"")
    while True:
        try: escolha_modo=input(t("rj_modo_prompt")).strip() or "1"
        except (EOFError,KeyboardInterrupt): log.aviso(u"Reintegração cancelada pelo usuário."); log.salvar(); return 0
        if escolha_modo in ("1","2"): break
        print(t("rj_modo_invalido"))
    modo_seguro=(escolha_modo=="2")

    try:
        with io.open(caminho_mapa_completo,"r",encoding="utf-8") as f: mapa_completo=json.load(f)
    except Exception as exc:
        msg=t("err_ler_mapa").format(NOME_MAPA,exc); print(t("erro")+": "+msg); log.erro(msg); log.salvar(); return 1

    candidatos=coletar_candidatos_reinjecao(pasta_entrada_base)
    print(t("etapa1_reinj").format(os.path.basename(pasta_entrada_base))); print(t("arquivos_encontrados").format(len(candidatos))); log.info(t("log_etapa1_reinj").format(len(candidatos)))

    print(""); print(t("rj_validacao_pre")); pre=validar_pre_reintegracao(pasta_game,pasta_entrada_base,mapa_completo,candidatos)
    print(u"{0}: {1}".format(t("rj_arquivos_esperados"),pre["arquivos_esperados"])); print(u"{0}: {1}".format(t("rj_arquivos_ok"),pre["arquivos_validados"])); print(u"{0}: {1}".format(t("rj_entradas_esperadas"),pre["entradas_esperadas"])); print(u"{0}: {1}".format(t("rj_entradas_encontradas"),pre["entradas_encontradas"])); print(u"{0}: {1}".format(t("rj_textos_alterados"),pre["alterados"])); print(u"{0}: {1}".format(t("rj_textos_iguais"),pre["iguais"]))
    for k in ("rj_arquivos_esperados","rj_arquivos_ok","rj_entradas_esperadas","rj_entradas_encontradas","rj_textos_alterados","rj_textos_iguais"): log.resultado(t(k),str(pre[{'rj_arquivos_esperados':'arquivos_esperados','rj_arquivos_ok':'arquivos_validados','rj_entradas_esperadas':'entradas_esperadas','rj_entradas_encontradas':'entradas_encontradas','rj_textos_alterados':'alterados','rj_textos_iguais':'iguais'}[k]]))
    if pre["erros"]:
        print(t("rj_validacao_falhou"));
        for erro in pre["erros"][:30]: print(u"  - {0}".format(erro)); log.erro(erro)
        if len(pre["erros"])>30: log.erro(u"... e mais {0} erro(s).".format(len(pre["erros"])-30))
        log.salvar(); return 1
    print(t("rj_validacao_ok"))

    if modo_seguro:
        try:
            backup=criar_backup_saida(raiz,pasta_saida_wrap)
            if backup: print(t("rj_backup_ok").format(backup)); log.info(t("rj_backup_ok").format(backup))
            else: print(t("rj_backup_nao")); log.info(t("rj_backup_nao"))
        except Exception as exc:
            msg=u"Falha ao criar backup seguro: {0}".format(exc); print(t("erro")+": "+msg); log.erro(msg); log.salvar(); return 1

    print(""); print(t("etapa2_reinj")); log.info(t("etapa2_reinj"))
    print(u"  Preparando a pasta de saída e invalidando compilados antigos...", flush=True)
    try:
        if os.path.isdir(pasta_saida_wrap): shutil.rmtree(pasta_saida_wrap)
        shutil.copytree(pasta_game,pasta_saida_wrap)
        log.info(u"Game original copiado integralmente para a saída antes da reintegração.")
        compilados_sombreados = limpar_compilados_sombreados(pasta_saida_wrap, log=log)
        if compilados_sombreados:
            print(u"  Compilados antigos invalidados: {} arquivo(s). Eles serão recompilados pelo Ren'Py quando necessário.".format(len(compilados_sombreados)), flush=True)
        else:
            print(u"  Nenhum compilado sombreado precisou ser invalidado.", flush=True)
    except Exception as exc:
        msg=u"Falha ao copiar o game original para a saída: {0}".format(exc); print(t("erro")+": "+msg); log.erro(msg); log.salvar(); return 1

    total_ok=total_falha=total_linhas_reinjetadas=0; sem_mapa=[]; arquivos_total=len(candidatos); modificados=0
    print(u"  Progresso da reintegração: 0.0% | [>                         ]", flush=True)
    ultimo_progresso = -1
    progresso_passo = max(1, int(100.0 / 20.0))
    for numero,caminho_traduzido in enumerate(candidatos,1):
        caminho_relativo=os.path.relpath(caminho_traduzido,pasta_entrada_base); chave=caminho_relativo.replace(os.sep,"/"); caminho_original=os.path.join(pasta_game,caminho_relativo)
        try:
            entradas_mapa=mapa_completo.get(chave)
            if entradas_mapa is None:
                if caminho_traduzido.lower().endswith(".txt"):
                    # TXT que não pertence ao banco de palavras permanece como cópia
                    # original; ele não participa da tradução.
                    copiar_arquivo_txt(caminho_traduzido,os.path.join(pasta_saida_wrap,caminho_relativo)); total_ok+=1
                else:
                    sem_mapa.append(caminho_relativo)
            else:
                textos_traduzidos=ler_textos_traduzidos(caminho_traduzido); linhas_resultado,erros=reinjetar_arquivo(caminho_original,entradas_mapa,textos_traduzidos)
                if erros:
                    total_falha+=1
                    for e in erros: log.erro(u"{0}: {1}".format(caminho_relativo,e))
                else:
                    caminho_saida=os.path.join(pasta_saida_wrap,caminho_relativo); pasta_saida=os.path.dirname(caminho_saida)
                    if pasta_saida and not os.path.isdir(pasta_saida): os.makedirs(pasta_saida)
                    with io.open(caminho_saida,"w",encoding="utf-8",newline="") as f: f.write(u"".join(linhas_resultado))
                    total_ok+=1; total_linhas_reinjetadas+=len(entradas_mapa); modificados += 1 if any(not comparar_literal_traducao(textos_traduzidos[i], entradas_mapa[i].get("original", ""), entradas_mapa[i].get("tipo")) for i in range(len(entradas_mapa))) else 0
        except Exception as exc:
            total_falha+=1; log.erro(u"{0}: {1}".format(caminho_relativo,exc))
        marcador = int((100.0 * numero) / max(1,arquivos_total))
        if marcador != ultimo_progresso and (marcador % progresso_passo == 0 or numero == arquivos_total):
            ultimo_progresso = marcador
            print(u"\r  Progresso da reintegração: {:5.1f}% | {:>4}/{:<4} {}".format(
                100.0 * numero / max(1,arquivos_total), numero, arquivos_total,
                barra_progresso(numero,max(1,arquivos_total))
            ), end=u"", flush=True)
    print(u"")

    print(u"ETAPA 13/14 - Validação da saída: verificando arquivos, integridade e compilados invalidados...", flush=True)
    print(""); print(t("rj_validacao_pos")); pos=validar_pos_reintegracao(pasta_game,pasta_saida_wrap,pasta_entrada_base,mapa_completo,candidatos,compilados_sombreados); print(u"{0}: {1}".format(t("rj_diferencas"),len(pos["erros"]))); log.resultado(t("rj_diferencas"),str(len(pos["erros"])))
    if pos["erros"]:
        print(t("rj_validacao_falhou"));
        for erro in pos["erros"][:30]: print(u"  - {0}".format(erro)); log.erro(erro)
        if len(pos["erros"])>30: log.erro(u"... e mais {0} erro(s).".format(len(pos["erros"])-30))
        log.salvar(); return 1
    print(t("rj_validacao_ok"))

    decorrido=time.time()-inicio_total; velocidade=float(total_linhas_reinjetadas)/max(0.001,decorrido)
    print(""); print(t("res_trad_encontrados").format(len(candidatos))); print(t("res_reinj_ok").format(total_ok)); print(t("res_reinj_falha").format(total_falha)); print(t("res_reinj_linhas").format(total_linhas_reinjetadas)); print(u"{0}: {1}".format(t("rj_modificados"),modificados)); print(u"{0}: {1}".format(t("rj_textos_alterados"),pre["alterados"])); print(u"{0}: {1}".format(t("rj_textos_iguais"),pre["iguais"])); print(u"{0}: {1:.1f}s".format(t("rj_tempo"),decorrido)); print(u"{0}: {1:.1f} linhas/s".format(t("rj_velocidade"),velocidade)); print(u"{0} 100%".format(barra_progresso(arquivos_total,max(1,arquivos_total))))
    log.separador(); log.resultado(t("log_res_trad_encontrados"),str(len(candidatos))); log.resultado(t("log_res_ok"),str(total_ok)); log.resultado(t("log_res_falhas"),str(total_falha)); log.resultado(t("log_res_sem_mapa"),str(len(sem_mapa))); log.resultado(t("log_res_linhas_reinj"),str(total_linhas_reinjetadas)); log.resultado(t("rj_modificados"),str(modificados)); log.resultado(t("rj_textos_alterados"),str(pre["alterados"])); log.resultado(t("rj_textos_iguais"),str(pre["iguais"])); log.resultado(t("rj_tempo"),u"{0:.1f}s".format(decorrido)); log.resultado(t("rj_velocidade"),u"{0:.1f} linhas/s".format(velocidade)); log.separador(); log.salvar(); print(""); print(t("log_salvo").format(log.caminho)); return 0 if total_falha==0 else 1


def executar_deteccao_sdk(raiz):
    pasta_game = encontrar_pasta_game(raiz)
    if not pasta_game:
        print("DDAC_TARGET_VERSION=")
        print("DDAC_SDK_VERSION=")
        print("DDAC_TARGET_FAMILY=")
        print("DDAC_TARGET_EVIDENCE=")
        print("DDAC_TARGET_FALLBACK=")
        return 1
    try:
        candidatos = coletar_candidatos_extracao(pasta_game)
    except Exception:
        candidatos = []
    alvo, evidencias = _detectar_versao_projeto_renpy(pasta_game, candidatos)
    alvo_texto = ".".join(str(x) for x in alvo) if alvo else ""
    if alvo and len(alvo) >= 3:
        # O log e a versão oficial do SDK usam 3 componentes.
        sdk_tuple = tuple(alvo[:3])
        sdk_texto = ".".join(str(x) for x in sdk_tuple)
        fallback = "NAO"
        familia = str(alvo[0])
    elif alvo:
        # Família (6/7/8) ajuda no diagnóstico, mas não autoriza baixar um SDK
        # por uma URL incompleta como renpy.org/dl/7/.
        sdk_texto = ""
        familia = str(alvo[0])
        fallback = "SIM_FAMILIA"
    else:
        sdk_texto = ""
        familia = ""
        fallback = "SIM_SEM_EVIDENCIA"
    evidencia = evidencias[0][1] if evidencias else ""
    print("DDAC_TARGET_VERSION=" + alvo_texto)
    print("DDAC_SDK_VERSION=" + sdk_texto)
    print("DDAC_TARGET_FAMILY=" + familia)
    print("DDAC_TARGET_EVIDENCE=" + evidencia.replace("=", ""))
    print("DDAC_TARGET_FALLBACK=" + fallback)
    return 0 if sdk_texto else 1

def executar_teste_cobertura_sintaxe_renpy():
    """Testa menus aninhados, multilinha/_p, monólogo triplo, raw/backtick e [] aninhado."""
    with tempfile.TemporaryDirectory(prefix='ddac_sintaxe_') as td:
        game=os.path.join(td,'game'); os.makedirs(game)
        caminho=os.path.join(game,'teste.rpy')
        texto=(
            'label start:\n'
            '    menu:\n'
            '        "Menu externo":\n'
            '            menu:\n'
            '                "Submenu":\n'
            '                    pass\n'
            '            "Depois do submenu":\n'
            '                pass\n'
            '        r"Raw traduzível":\n'
            '            pass\n'
            '        `Backtick traduzível`:\n'
            '            pass\n'
            '    define_text = _p("""\n'
            '        Primeira linha traduzível.\n'
            '\n'
            '        Segunda linha traduzível.\n'
            '        """)\n'
            '    e """\n'
            '        Monólogo um.\n'
            '\n'
            '        Monólogo dois.\n'
            '        """\n'
            '    e r"Raw [player.names[0]] e {i}tag{/i}"\n'
            '    y -s_dark e1d b1f 4p 5c "Tudo certo."\n'
        )
        with io.open(caminho,'w',encoding='utf-8',newline='') as f: f.write(texto)
        mapa_out=os.path.join(td,'out')
        os.makedirs(mapa_out)
        # Contexto mínimo: o extrator trabalha sem SDK neste teste.
        textos,mapa=extrair_arquivo_com_mapa(caminho,set(),construir_indice_arquivos(game),{'personagens':set(),'nomes_personagem_variaveis':set(),'variaveis_tecnicas':set(),'nomes_do_jogo':set()},None)
        mapa=_enriquecer_mapa_integridade(mapa,caminho,'teste.rpy')
        originals=[x.get('original','') for x in mapa]
        required=(u'"Depois do submenu":', u'"Raw traduzível":', u'`Backtick traduzível`')
        if not any('Depois do submenu' in x for x in originals):
            raise RuntimeError('menu aninhado: opção após submenu não foi extraída')
        obrigatorios=('source_sha256','entry_id','logical_group_id','token_signature','source_line_hash','context_hash')
        if any(k not in mapa[0] for k in obrigatorios):
            raise RuntimeError('mapa de integridade: campos adicionais ausentes')
        if not any('Raw traduzível' in x for x in originals):
            raise RuntimeError("string raw Ren'Py não foi extraída")
        if not any('Backtick traduzível' in x for x in originals):
            raise RuntimeError('string com backtick não foi extraída')
        gettext_sample = 'x = _p("""\nPrimeira linha traduzível.\nSegunda linha.\n""")'
        gp, _gl = extrair_strings_gettext_multilinha('sample.rpy', gettext_sample.splitlines(True))
        if not gp:
            raise RuntimeError('string multilinha _p não foi extraída pelo detector explícito')
        poem_gettext = 'poem_responses/poems.rpy'
        pp, _ = extrair_strings_gettext_multilinha(poem_gettext, gettext_sample.splitlines(True))
        if not pp:
            raise RuntimeError('poem_responses/poems.rpy foi bloqueado indevidamente para _p multilinha')
        blocked, _ = extrair_strings_gettext_multilinha('poem_responses/' + POEMRESPONSES_BASE_NAME, gettext_sample.splitlines(True))
        if blocked:
            raise RuntimeError('script-poemresponses.rpy não foi bloqueado como solicitado')
        raw_single='r"Hello"'
        if not any(q == '"Hello"' and raw for _,_,q,raw in iter_renpy_literais_especiais(raw_single)):
            raise RuntimeError('string raw simples não foi reconhecida')
        if not any(e.get('tipo') in ('multilinha_renpy', 'monologo_triplas') for e in mapa):
            raise RuntimeError('multilinha/_p ou monólogo triplo não foi extraído')
        if not any('Primeira linha traduzível' in x for x in originals):
            raise RuntimeError('_p com aspas triplas não foi extraído')
        if not any('Tudo certo.' in x for x in originals):
            raise RuntimeError('fala com atributos (-attr/@) não foi extraída')
        if not any('[player.names[0]]' in x for x in originals):
            raise RuntimeError('interpolação com [] aninhado não foi preservada como texto')
        ml=[e for e in mapa if e.get('tipo')=='monologo_triplas']
        if not ml:
            raise RuntimeError('nenhum fragmento triplo disponível para teste de reinjeção')
        traducoes_re = []
        for e in mapa:
            if e.get('tipo') in ('gettext_multilinha', 'multilinha_renpy', 'monologo_triplas', 'poema_corpo'):
                traducoes_re.append(codificar_literal_traducao(e.get('original','')))
            else:
                traducoes_re.append(e.get('original',''))
        linhas_re, err_re = reinjetar_arquivo(caminho, mapa, traducoes_re)
        if err_re:
            raise RuntimeError('reinjeção sintática do self-test falhou: ' + '; '.join(err_re[:3]))
        joined=''.join(linhas_re)
        if 'define_text = _p("""' not in joined or 'Primeira linha traduzível.' not in joined:
            raise RuntimeError('reinjeção de _p triplo alterou a estrutura')

        # Regressão global: spans sobrepostos devem gerar apenas uma entrada.
        overlap_test = [
            (0, 8, 'poema_corpo', 100, '', '"ABCDEFG"', None),
            (1, 8, 'multilinha_renpy', 100, '', 'ABCDEFG', None),
        ]
        resolvidos, conflitos = _resolver_sobreposicoes_registros(overlap_test)
        if len(resolvidos) != 1 or not conflitos or resolvidos[0][2] != 'poema_corpo':
            raise RuntimeError('resolução global de sobreposição de spans falhou')

        # Regressão global: compilado sombreado só é removido quando a fonte existe.
        comp_dir = os.path.join(td, 'compiled-test')
        os.makedirs(comp_dir)
        with io.open(os.path.join(comp_dir, 'sample.rpy'), 'w', encoding='utf-8') as f:
            f.write('label start:\n    pass\n')
        with io.open(os.path.join(comp_dir, 'orphan.rpyc'), 'wb') as f:
            f.write(b'compiled')
        with io.open(os.path.join(comp_dir, 'sample.rpyc'), 'wb') as f:
            f.write(b'compiled')
        removidos = limpar_compilados_sombreados(comp_dir)
        if 'sample.rpyc' not in removidos or os.path.exists(os.path.join(comp_dir, 'sample.rpyc')):
            raise RuntimeError('limpeza global de .rpyc sombreado falhou')
        if os.path.exists(os.path.join(comp_dir, 'orphan.rpyc')):
            raise RuntimeError('limpeza global não removeu .rpyc órfão como esperado')
    # Validação direta do formato de token de [] aninhado.
    esperado=[m.group(0) for m in TOKEN_PROTECAO_RE.finditer('x')]
    protegido,tokens=proteger_tokens_google('A [player.names[0]] {i}x{/i}')
    validar_tokens_google_preservados(protegido,tokens)
    if restaurar_tokens_google(protegido,tokens)!='A [player.names[0]] {i}x{/i}':
        raise RuntimeError('restauração de [] aninhado falhou')
    print(u'TESTE COBERTURA SINTAXE: OK | menu aninhado, _p, monólogo triplo, raw, backtick e [] aninhado')
    return 0


def executar_teste_integridade_tokens():
    esperado = [(u"DDACZ0000Q", u"{hour}"), (u"DDACZ0001Q", u"{minute}")]
    validar_tokens_google_preservados(u"DDACZ0000Q:DDACZ0001Q", esperado)
    casos_invalidos = (
        u"DDACZ0001Q:DDACZ0000Q",
        u"DDACZ0000Q:DDACZ0000Q",
    )
    for caso in casos_invalidos:
        try:
            validar_tokens_google_preservados(caso, esperado)
        except GoogleTranslateValidationError as exc:
            if u"ordem/duplicação" not in str(exc):
                raise
        else:
            raise GoogleTranslateValidationError(u"teste inválido de ordem/duplicação não foi detectado")
    print(u"TESTE TOKENS: OK | sequência, reordenação e duplicação detectadas")
    return 0



# ==============================================================================
# V103 - DUAL BRAIN / PIPELINE DE 14 ETAPAS
# ==============================================================================
# Camada global sobre o núcleo V100. Os dois motores analisam o mesmo source
# independentemente; o cérebro consolida somente spans existentes no source.
# Regra absoluta: o pipeline nunca inventa texto.

_DUAL_REPORT_NAME = u"DDAC-Dual-Relatorio.json"
_DUAL_COLLISION_REPORT_NAME = u"DDAC-Colisão-Relatório.json"
_DUAL_COLLISION_REPORT_LEGACY_NAME = u"DDAC-Colisao-Relatorio.json"
_DUAL_COLLISION_REPORT_DIR = None
_DUAL_INSTALLER_NAME = u"DDAC-APLICAR-MESCLAGEM.bat"
_DUAL_STAGE_NAMES = (
    u"Escanear game", u"Extrair com DDAC", u"Extrair com Ren'Py",
    u"Comparar motores", u"Consolidar duplicatas", u"Resolver sobreposições",
    u"Analisar contexto", u"Classificar texto traduzível",
    u"Gerar mapa canônico", u"Preparar tradução canônica",
    u"Validar tokens", u"Reintegrar spans canônicos",
    u"Validar saída", u"Auditar colisões finais"
)


_DUAL_LINES_CACHE = {}


def _dual_get_lines(pasta_game, rel):
    key = (os.path.abspath(pasta_game), _dual_norm_rel(rel))
    cached = _DUAL_LINES_CACHE.get(key)
    if cached is not None:
        return cached
    path = os.path.join(pasta_game, _dual_norm_rel(rel).replace("/", os.sep))
    lines = ler_linhas_raw(path)
    _DUAL_LINES_CACHE[key] = lines
    return lines


def _dual_norm_rel(path):
    return os.path.normpath(path).replace(os.sep, "/").lstrip("./")


def _dual_span_key(c):
    return (_dual_norm_rel(c.get("arquivo", "")), int(c.get("linha", 0) or 0),
            int(c.get("coluna_inicio", 0) or 0), int(c.get("coluna_fim", 0) or 0))


def _dual_text_key(c):
    return (_dual_norm_rel(c.get("arquivo", "")), int(c.get("linha", 0) or 0),
            int(c.get("coluna_inicio", 0) or 0), int(c.get("coluna_fim", 0) or 0),
            c.get("original", ""))


def _dual_priority(c):
    return {
        "poema_titulo": 1010, "poema_corpo": 1000, "gettext_multilinha": 990,
        "monologo_triplas": 980, "multilinha_renpy": 970,
        "dialogo": 900, "renpy_nativo_dialogo": 900,
        "narrativa": 890, "renpy_nativo_string": 880,
        "ui": 870, "menu": 860, "poema_palavra_txt": 850,
        "nome_personagem": 700, "variavel_texto": 600, "url_visivel": 500,
    }.get(c.get("tipo"), 100)


def _dual_intersect(a, b):
    if _dual_norm_rel(a.get("arquivo", "")) != _dual_norm_rel(b.get("arquivo", "")):
        return False
    if int(a.get("linha", 0) or 0) != int(b.get("linha", 0) or 0):
        return False
    a0, a1 = int(a.get("coluna_inicio", 0) or 0), int(a.get("coluna_fim", 0) or 0)
    b0, b1 = int(b.get("coluna_inicio", 0) or 0), int(b.get("coluna_fim", 0) or 0)
    return max(a0, b0) < min(a1, b1)


def _dual_resolve_exact_duplicates(candidates):
    out=[]; by_span={}; dup=0
    for c in candidates:
        key=_dual_span_key(c)
        if key not in by_span:
            n=dict(c)
            n["proveniencia"]=sorted(set(n.get("proveniencia", []) or [n.get("motor", "desconhecido")]))
            by_span[key]=n; out.append(n); continue
        dup += 1
        prev=by_span[key]
        prev["proveniencia"]=sorted(set((prev.get("proveniencia",[]) or []) + (c.get("proveniencia",[]) or []) + [c.get("motor", "desconhecido")]))
        if not prev.get("original") and c.get("original"): prev["original"]=c["original"]
    return out, {"entrada":len(candidates),"duplicatas":dup,"saida":len(out)}


def _dual_resolve_overlaps(candidates):
    """Stage 6: resolve spans per physical file/line, avoiding global O(n²)."""
    groups = {}
    for c in candidates:
        key = (_dual_norm_rel(c.get("arquivo", "")), int(c.get("linha", 0) or 0))
        groups.setdefault(key, []).append(c)
    kept=[]; conflicts=[]
    for key, group in groups.items():
        ranked=sorted(group,key=lambda c:(-int(_dual_priority(c)),int(c.get("coluna_inicio",0) or 0),-int(c.get("coluna_fim",0) or 0),str(c.get("entry_id", ""))))
        accepted=[]
        for c in ranked:
            hit=next((k for k in accepted if _dual_intersect(c,k)),None)
            if hit is None:
                accepted.append(c); continue
            conflicts.append({"acao":"descartou","mantido":_dual_span_key(hit),"descartado":_dual_span_key(c),"motivo":"prioridade_semantica"})
        kept.extend(accepted)
    return sorted(kept,key=_dual_text_key),conflicts


def _dual_source_literal_exists(c, pasta_game):
    rel=_dual_norm_rel(c.get("arquivo","")); path=os.path.join(pasta_game,rel.replace("/",os.sep))
    if not os.path.isfile(path): return False
    try:
        raw=_dual_get_lines(pasta_game,rel); ln=int(c.get("linha",0) or 0)
        c0=int(c.get("coluna_inicio",0) or 0); c1=int(c.get("coluna_fim",0) or 0)
        return 1 <= ln <= len(raw) and 0 <= c0 < c1 <= len(raw[ln-1]) and raw[ln-1][c0:c1] == c.get("original","")
    except Exception:
        return False


def _dual_context(c, pasta_game):
    rel=_dual_norm_rel(c.get("arquivo","")); path=os.path.join(pasta_game,rel.replace("/",os.sep))
    try:
        lines=_dual_get_lines(pasta_game,rel); ln=int(c.get("linha",0) or 0)
        return {"before":lines[max(0,ln-4):max(0,ln-1)],"line":lines[ln-1] if 1<=ln<=len(lines) else u"","after":lines[ln:min(len(lines),ln+3)]}
    except Exception:
        return {"before":[],"line":u"","after":[]}


def _dual_classify(c):
    text_value=c.get("original","") or ""; tipo=c.get("tipo","") or ""; ctx=c.get("contexto",{})
    visible_types={"dialogo","narrativa","ui","menu","poema_titulo","poema_corpo","poema_palavra_txt","gettext_multilinha","monologo_triplas","renpy_nativo_dialogo","renpy_nativo_string","url_visivel","nome_personagem"}
    technical=parece_texto_tecnico(text_value)
    explicit=tipo in visible_types or bool(re.search(r"\bmenu\s*:|\bscreen\s+[A-Za-z_]\w*\s*:|\blabel\s+[A-Za-z_]\w*\s*:","\n".join(ctx.get("before",[]))+"\n"+ctx.get("line",u"")))
    if technical and not explicit:
        c["decisao"]="IGNORADO"; c["motivo_classificacao"]="parece_codigo_ou_identificador_tecnico"; c["confianca"]=0.98
    else:
        c["decisao"]="ACEITO"; c["motivo_classificacao"]="texto_visivel_ou_candidato_semantico"; c["confianca"]=0.99 if tipo in visible_types else 0.85
    return c


def _dual_engine_common_duplicate(rel,pasta_game,raiz=None):
    """Detecta cópia exata de renpy/common sem misturar com arquivos game diferentes."""
    if not raiz:
        return False, None
    src=os.path.join(pasta_game, _dual_norm_rel(rel).replace("/", os.sep))
    common=os.path.join(raiz, "renpy", "common", _dual_norm_rel(rel).replace("/", os.sep))
    if not (os.path.isfile(src) and os.path.isfile(common)):
        return False, None
    try:
        h1=sha256_arquivo(src); h2=sha256_arquivo(common)
    except Exception:
        return False, None
    return h1 == h2, h2


def _dual_classify_all(candidates,pasta_game,raiz=None):
    accepted=[]; review=[]; ignored=[]
    for c in candidates:
        n=dict(c); n["contexto"]=_dual_context(n,pasta_game)
        rel=_dual_norm_rel(n.get("arquivo",""))
        if arquivo_globalmente_ignorado_extracao(rel):
            n["decisao"]="IGNORADO"; n["motivo_classificacao"]="arquivo_globalmente_ignorado_extracao"; n["classificacao"]="GLOBAL_FILE_EXCLUSION"; n["confianca"]=1.0; ignored.append(n); continue
        if entrada_nao_traduzivel_google(n.get("original",u""), rel, n.get("tipo",u"")):
            n["decisao"]="IGNORADO"
            n["motivo_classificacao"]="credito_ou_nomenclatura_protegida_nao_traduzivel"
            n["classificacao"]="NON_TRANSLATABLE_CREDIT"
            n["nao_traduzir"]=True
            n["confianca"]=1.0
            ignored.append(n); continue
        is_common,common_hash=_dual_engine_common_duplicate(rel,pasta_game,raiz)
        if is_common:
            n["decisao"]="IGNORADO"
            n["motivo_classificacao"]="duplicata_exata_do_renpy_common"
            n["classificacao"]="ENGINE_COMMON_DUPLICATE"
            n["engine_common_sha256"]=common_hash
            n["confianca"]=1.0
            ignored.append(n)
            continue
        if not _dual_source_literal_exists(n,pasta_game):
            n["decisao"]="REVISAO"; n["motivo_classificacao"]="span_nao_confirmado_no_source"; n["confianca"]=0.0; review.append(n); continue
        _dual_classify(n)
        (accepted if n["decisao"]=="ACEITO" else ignored if n["decisao"]=="IGNORADO" else review).append(n)
    return accepted,review,ignored


def _dual_canonicalize(accepted,pasta_game):
    out=[]
    for c in accepted:
        n=dict(c); n["arquivo"]=_dual_norm_rel(n.get("arquivo",""));
        if arquivo_globalmente_ignorado_extracao(n["arquivo"]):
            continue
        path=os.path.join(pasta_game,n["arquivo"].replace("/",os.sep))
        try: raw=_dual_get_lines(pasta_game,n["arquivo"]); ln=int(n.get("linha",0) or 0); c0=int(n.get("coluna_inicio",0) or 0); c1=int(n.get("coluna_fim",0) or 0)
        except Exception: continue
        if not (1<=ln<=len(raw) and 0<=c0<c1<=len(raw[ln-1])): continue
        if raw[ln-1][c0:c1] != n.get("original",""): continue
        n["original"]=raw[ln-1][c0:c1]; n["origem_canonica"]="source_literal"
        n["termos_protegidos"]=[m.group(0) for m in _ocorrencias_termos_protegidos_google(n["original"])]
        out.append(n)
    out,_=_dual_resolve_exact_duplicates(out)
    return sorted(out,key=_dual_text_key)


def _dual_merge_map_with_integrity(canonical,pasta_game):
    grouped={}
    for c in canonical: grouped.setdefault(c["arquivo"],[]).append(c)
    out={}
    for rel,items in grouped.items():
        path=os.path.join(pasta_game,rel.replace("/",os.sep)); out[rel]=_enriquecer_mapa_integridade(items,path,rel,linhas_raw=_dual_get_lines(pasta_game,rel))
    return out


def _dual_write_canonical_outputs(raiz,pasta_game,canonical,mapa):
    pasta_saida=os.path.join(raiz,PASTA_ENTRADA_NOME)
    os.makedirs(pasta_saida,exist_ok=True)
    grouped={}
    for c in canonical: grouped.setdefault(c["arquivo"],[]).append(c)
    for rel,items in grouped.items():
        dst=os.path.join(pasta_saida,rel.replace("/",os.sep)); os.makedirs(os.path.dirname(dst),exist_ok=True)
        src=os.path.join(pasta_game,rel.replace("/",os.sep))
        if rel.lower().endswith(".txt") and eh_arquivo_lista_palavras_poema(src):
            escrever_txt_palavras_extraido(src,dst,items)
        else:
            with io.open(dst,"w",encoding="utf-8",newline="\n") as f:
                f.write(u"\n".join([u""]+[INDENTACAO_SAIDA+c.get("texto_saida",c.get("original",u"")) for c in items])+u"\n")
    with io.open(os.path.join(pasta_saida,NOME_MAPA),"w",encoding="utf-8") as f: json.dump(mapa,f,ensure_ascii=False,indent=1)
    return pasta_saida


def _dual_reset_output_dir(raiz, log):
    path=os.path.join(raiz,PASTA_ENTRADA_NOME)
    if not os.path.isdir(path): return
    backup=os.path.join(raiz,u"{}-Backup-{}".format(PASTA_ENTRADA_NOME,time.strftime("%Y%m%d-%H%M%S")))
    if os.path.exists(backup): backup += u"-{}".format(os.getpid())
    os.rename(path,backup); log.info(u"ETAPA 1/14: saída anterior preservada em {}".format(os.path.basename(backup)))


def _dual_stage2_ddac(pasta_game,candidatos,log):
    indice=construir_indice_arquivos(pasta_game); vars_dyn=coletar_variaveis_nome_dinamico(candidatos); vocab=coletar_vocabulario(pasta_game,candidatos); ddac=[]
    total=max(1,len(candidatos)); ultimo_marcador=-1
    print(u"  Progresso DDAC: 0.0% | [>                         ]", flush=True)
    for numero_caminho,caminho in enumerate(candidatos,1):
        rel=_dual_norm_rel(os.path.relpath(caminho,pasta_game))
        if caminho.lower().endswith(".txt"):
            if eh_arquivo_lista_palavras_poema(caminho):
                for e in extrair_txt_lista_palavras_poema(caminho) or []:
                    n=dict(e); n.update({"arquivo":rel,"motor":"DDAC","proveniencia":["DDAC"]}); ddac.append(n)
            continue
        try:
            textos,mapa=extrair_arquivo_com_mapa(caminho,vars_dyn,indice,vocab,{})
            for pair,entry in zip(textos,mapa):
                text_value = pair[1] if isinstance(pair,(tuple,list)) and len(pair) >= 2 else entry.get("original","")
                n=dict(entry); n.update({"arquivo":rel,"motor":"DDAC","proveniencia":["DDAC"],"texto_detectado":text_value,"texto_saida":text_value}); ddac.append(n)
        except Exception as exc: log.aviso(u"Motor DDAC falhou em {}: {}".format(rel,exc))
        marcador = int((100.0 * numero_caminho) / total)
        passo = max(1, int(100.0 / 20.0))
        if marcador != ultimo_marcador and (marcador % passo == 0 or numero_caminho == total):
            ultimo_marcador = marcador
            largura = 28
            preenchido = int(round(largura * (float(numero_caminho) / total)))
            preenchido = max(0, min(largura, preenchido))
            corpo = u"=" * preenchido + (u">" if preenchido < largura else u"")
            corpo += u" " * max(0, largura - len(corpo))
            print(u"\r  Progresso DDAC: {:5.1f}% | {:>4}/{:<4} [{}]".format(
                100.0 * numero_caminho / total, numero_caminho, total, corpo
            ), end=u"", flush=True)
    print(u"")
    return ddac,vars_dyn


def _dual_stage3_renpy(pasta_game,candidatos,log):
    oracle=_preparar_oraculo_renpy(pasta_game,candidatos,log); out=[]
    if not ORACULO_RENPY.get("ativo"): return out
    for rel,by_line in (oracle or {}).items():
        if isinstance(by_line,dict):
            iter_items=[]
            for _ln,items in by_line.items():
                if isinstance(items,(list,tuple)): iter_items.extend(items)
                elif isinstance(items,dict): iter_items.append(items)
        elif isinstance(by_line,(list,tuple)):
            iter_items=by_line
        else:
            iter_items=[]
        for item in iter_items:
            n=dict(item); r=_dual_norm_rel(n.get("arquivo",rel)); r=r[5:] if r.startswith("game/") else r; n["arquivo"]=r; n["motor"]="RenPy"; n["proveniencia"]=["RenPy"]; n.setdefault("tipo","renpy_nativo_string")
            if arquivo_globalmente_ignorado_extracao(r):
                continue
            try:
                lines=_dual_get_lines(pasta_game,r); ln=int(n.get("linha",0) or 0); line=lines[ln-1].rstrip("\r\n")
                matches=_candidatos_string_linha(line,n.get("texto",u""))
            except Exception:
                matches=[]
            if len(matches)==1:
                c0,c1,q=matches[0]; n["coluna_inicio"]=c0; n["coluna_fim"]=c1; n["original"]=q; n["texto_saida"]=q
                if n.get("personagem") and PURE_VISIBLE_URL_RE.match(strip_quotes(q).strip()): n["tipo"]="url_visivel"
            else:
                n["coluna_inicio"]=0; n["coluna_fim"]=0; n["original"]=u""; n["texto_saida"]=u""; n["renpy_match_ambiguo"]=len(matches)
            out.append(n)
    return out

def _dual_stage4_compare(ddac,renpy):
    a={_dual_text_key(c) for c in ddac}; b={_dual_text_key(c) for c in renpy}
    return {"ddac":len(a),"renpy":len(b),"concordancias_exatas":len(a&b),"somente_ddac":len(a-b),"somente_renpy":len(b-a)}


_DUAL_REPORT_DIR = None

def _dual_report_path(raiz):
    """Relatório persistente ao lado do BAT; não é apagado após sucesso."""
    return os.path.join(os.path.abspath(raiz), _DUAL_REPORT_NAME)


def _dual_report_itens_compactos(itens):
    """Campos úteis para revisar texto; evita serializar contexto/código inteiro."""
    saida = []
    for item in itens or []:
        literal = item.get("original", u"")
        try:
            texto_visivel = decodificar_literal_traducao(literal)
        except Exception:
            texto_visivel = strip_quotes(literal)
        saida.append({
            "arquivo": item.get("arquivo", u""),
            "linha": item.get("linha", 0),
            "tipo": item.get("tipo", u""),
            "texto": texto_visivel,
            "literal_fonte": literal,
            "decisao": item.get("decisao", u""),
            "classificacao": item.get("classificacao", u""),
            "motivo": item.get("motivo_classificacao", u""),
            "confianca": item.get("confianca", None),
            "motor": item.get("motor", u"DDAC"),
            "proveniencia": item.get("proveniencia", [u"DDAC"]),
        })
    return saida

def _dual_report_oracle_compacto():
    o = dict(ORACULO_RENPY)
    # O relatório de estado não precisa carregar as 25k+ entradas nativas nem
    # a tabela por arquivo. Essas estruturas continuam disponíveis em memória
    # durante o pipeline; o mapa canônico é que preserva os dados de produção.
    for chave in ("entradas", "por_arquivo"):
        o.pop(chave, None)
    o["entradas_nativas_serializadas"] = False
    o["por_arquivo_serializado"] = False
    return o

def _dual_write_report(raiz,report):
    caminho=_dual_report_path(raiz)
    report["relatorio_diagnostico"] = caminho
    with io.open(caminho,"w",encoding="utf-8") as f: json.dump(report,f,ensure_ascii=False,indent=2)
    return caminho

def _dual_cleanup_success_temp_report():
    global _DUAL_REPORT_DIR
    if _DUAL_REPORT_DIR and os.path.isdir(_DUAL_REPORT_DIR):
        try: shutil.rmtree(_DUAL_REPORT_DIR, ignore_errors=True)
        except Exception: pass
    _DUAL_REPORT_DIR = None


def executar_pipeline_dual_v112(raiz):
    global IGNORADOS_EXTRACAO_AUTOMATICA, _DUAL_LINES_CACHE
    IGNORADOS_EXTRACAO_AUTOMATICA=[]; _DUAL_LINES_CACHE={}; inicio=time.time(); log=Log(os.path.join(raiz,NOME_LOG_EXTRATOR)); status={str(i):"PENDENTE" for i in range(1,15)}
    report={"versao":"V145-OptionalOracle","run_id":"{}-{}".format(time.strftime("%Y%m%d-%H%M%S"),os.getpid()),"etapas":_DUAL_STAGE_NAMES,"stage_status":status,"oraculo_renpy_required":False,"validacao_renpy":"PENDENTE","terminal_status":"EM_EXECUCAO","arquitetura":"DDAC independente + oráculo RenPy opcional + cérebro semântico determinístico"}
    try:
        _stale=os.path.join(raiz,_DUAL_REPORT_NAME)
        if os.path.isfile(_stale): os.remove(_stale)
    except Exception:
        pass
    log.separador(); log.titulo(dt("titulo")); log.titulo(t("log_datahora").format(time.strftime("%d/%m/%Y %H:%M:%S"))); log.separador(); log.info(dt("nova_execucao")); _dual_write_report(raiz,report); log.salvar()
    try:
        pasta_game=encontrar_pasta_game(raiz)
        if not pasta_game:
            status["1"]="FALHA"; report.update({"terminal_status":"FALHA","erro":"Pasta game não encontrada."}); log.erro(dt("game_missing")); _dual_write_report(raiz,report); log.salvar(); return 1
        print(dt("stage1_start"), flush=True)
        candidatos=coletar_candidatos_extracao(pasta_game)
        if not candidatos:
            status["1"]="FALHA"
            try:
                contagem,_triples,_tl=_preflight_contar_fontes(pasta_game)
                compilados=contagem.get(".rpa",0)+contagem.get(".rpyc",0)+contagem.get(".rpymc",0)
            except Exception:
                compilados=0
            if compilados:
                motivo=u"Nenhum script-fonte utilizável foi encontrado. O projeto contém arquivos empacotados/compilados, mas esta etapa não extrai RPA nem descompila RPYC. Extraia os RPA e descompile os RPYC antes de executar a Opção 1."
            else:
                motivo=u"Nenhum arquivo-fonte compatível (.rpy, .rpym, *_ren.py ou texto suportado) foi encontrado dentro da pasta game. A extração foi interrompida sem substituir resultados anteriores."
            report.update({"terminal_status":"SEM_FONTES_DE_SCRIPT","arquivos_scan":0,"candidatos_ddac":0,"candidatos_renpy":0,"validacao_renpy":"NAO_APLICAVEL","erro":motivo,"stage_status":status})
            log.erro(motivo); _dual_write_report(raiz,report); log.resultado(dt("label_status"),u"FALHA: sem fontes para extração"); log.resultado(u"Relatório",os.path.join(os.path.abspath(raiz),_DUAL_REPORT_NAME)); log.salvar()
            print(u"[ERRO] " + motivo, flush=True)
            return 1
        # Não arquiva/substitui uma extração anterior até confirmar fontes válidas.
        _dual_reset_output_dir(raiz,log)
        status["1"]="OK"; print(dt("stage1_done", len(candidatos)), flush=True); log.info(dt("stage1_done", len(candidatos)))
        print(dt("stage2_start"), flush=True)
        ddac,vars_dyn=_dual_stage2_ddac(pasta_game,candidatos,log); status["2"]="OK"; print(dt("stage2_done", len(ddac)), flush=True); log.info(dt("stage2_done", len(ddac)))
        print(dt("stage3_start"), flush=True)
        renpy=_dual_stage3_renpy(pasta_game,candidatos,log)
        active=bool(ORACULO_RENPY.get("ativo"))
        status_oraculo = {1:u"SEM VALIDAÇÃO", 2:u"NOT VALIDATED", 3:u"SIN VALIDACIÓN"}.get(IDIOMA, u"SEM VALIDAÇÃO")
        status["3"] = "OK" if active else "SEM VALIDACAO"
        status_etapa = dt("status_ok") if active else status_oraculo
        print(dt("stage3_done", len(renpy), dt("oracle_yes") if active else dt("oracle_no"), status_etapa), flush=True)
        log.info(dt("stage3_done", len(renpy), dt("oracle_yes") if active else dt("oracle_no"), status_etapa))
        if not active:
            aviso_fallback = {
                1:u"O oráculo Ren'Py não ficou disponível. A extração continua apenas com o motor DDAC; o resultado deve ser revisado e está marcado como sem validação.",
                2:u"The Ren'Py Oracle was unavailable. Extraction continues with the DDAC engine only; review the result because it is marked as not validated.",
                3:u"El oráculo Ren'Py no estuvo disponible. La extracción continúa solo con el motor DDAC; revise el resultado porque está marcado sin validación.",
            }.get(IDIOMA, u"O oráculo Ren'Py não ficou disponível. A extração continua apenas com o motor DDAC; o resultado está marcado como sem validação.")
            print(u"  [AVISO] " + aviso_fallback, flush=True)
            log.aviso(aviso_fallback)
        cmp=_dual_stage4_compare(ddac,renpy); status["4"]="OK"; log.info(dt("stage4_done", cmp["concordancias_exatas"], cmp["somente_ddac"], cmp["somente_renpy"])); print(dt("stage4_done", cmp["concordancias_exatas"], cmp["somente_ddac"], cmp["somente_renpy"]), flush=True)
        combined,dup=_dual_resolve_exact_duplicates(ddac+renpy); status["5"]="OK"; log.info(dt("stage5_done", dup["duplicatas"])); print(dt("stage5_done", dup["duplicatas"]), flush=True)
        resolved,conf=_dual_resolve_overlaps(combined); status["6"]="OK"; log.info(dt("stage6_done", len(conf))); print(dt("stage6_done", len(conf)), flush=True)
        accepted,review,ignored=_dual_classify_all(resolved,pasta_game,raiz); status["7"]="OK"; status["8"]="OK"; engine_common_ignored=sum(1 for x in ignored if x.get("classificacao")=="ENGINE_COMMON_DUPLICATE"); log.info(dt("stage7_done", len(resolved))); log.info(dt("stage8_done", len(accepted), len(review), len(ignored), engine_common_ignored, sum(1 for x in ignored if x.get("classificacao")=="GLOBAL_FILE_EXCLUSION"))); print(dt("stage7_done", len(resolved)), flush=True); print(dt("stage8_done", len(accepted), len(review), len(ignored), engine_common_ignored, sum(1 for x in ignored if x.get("classificacao")=="GLOBAL_FILE_EXCLUSION")), flush=True)
        canonical=_dual_canonicalize(accepted,pasta_game); mapa=_dual_merge_map_with_integrity(canonical,pasta_game); _dual_write_canonical_outputs(raiz,pasta_game,canonical,mapa); status["9"]="OK"; log.info(dt("stage9_done", len(canonical))); print(dt("stage9_done", len(canonical)), flush=True)
        for n in range(10,15): status[str(n)]="PENDENTE"
        print(dt("stage10_pending")); print(dt("stage11_pending")); print(dt("stage12_pending")); print(dt("stage13_pending")); print(dt("stage14_pending")); log.info(dt("pending_log"))
        report.update({"arquivos_scan":len(candidatos),"candidatos_ddac":len(ddac),"candidatos_renpy":len(renpy),"comparacao":cmp,"duplicatas_consolidadas":dup,"sobreposicoes_resolvidas":len(conf),"aceitos":len(accepted),"revisao":len(review),"ignorados":len(ignored),"revisao_itens":_dual_report_itens_compactos(review),"ignorados_itens":_dual_report_itens_compactos(ignored),"ignorados_engine_common":engine_common_ignored,"ignorados_arquivos_globais":sum(1 for x in ignored if x.get("classificacao")=="GLOBAL_FILE_EXCLUSION"),"canonicos":len(canonical),"sem_inventar_texto":True,"oraculo_renpy_ativo":active,"validacao_renpy":"VALIDADA" if active else "SEM VALIDACAO","motor_fallback_ddac":not active,"oraculo_renpy":_dual_report_oracle_compacto(),"stage_status":status,"terminal_status":"EXTRACAO_CONCLUIDA" if active else "EXTRACAO_CONCLUIDA_SEM_VALIDACAO","etapas_executadas":[1,2,3,4,5,6,7,8,9],"etapas_pendentes":[10,11,12,13,14]}); _dual_write_report(raiz,report)
        log.resultado(dt("label_status"),dt("final_status") if active else status_oraculo); log.resultado(dt("label_scanned"),str(len(candidatos))); log.resultado(dt("label_ddac"),str(len(ddac))); log.resultado(dt("label_renpy"),str(len(renpy))); log.resultado(dt("label_concord"),str(cmp["concordancias_exatas"])); log.resultado(dt("label_only_ddac"),str(cmp["somente_ddac"])); log.resultado(dt("label_only_renpy"),str(cmp["somente_renpy"])); log.resultado(dt("label_canonical"),str(len(canonical))); log.resultado(dt("label_oracle"),dt("oracle_yes") if active else status_oraculo); log.resultado(u"Itens em REVISÃO",str(len(review))); log.resultado(u"Itens ignorados (relatório persistente)",str(len(ignored))); log.resultado(u"Relatório",os.path.join(os.path.abspath(raiz),_DUAL_REPORT_NAME)); log.resultado(dt("label_executed"),u"1-9"); log.resultado(dt("label_pending"),u"10-14"); log.resultado(dt("label_time"),u"{:.1f}s".format(time.time()-inicio)); log.separador(); log.salvar(); return 0
    except Exception as exc:
        tb=traceback.format_exc(); report.update({"stage_status":status,"terminal_status":"ERRO_INTERNO","erro":str(exc),"traceback":tb}); log.erro(u"ERRO INTERNO NO DUALBRAIN V118: {}".format(exc)); [log.erro(x) for x in tb.splitlines()[-20:]]
        try: _dual_write_report(raiz,report); log.resultado(dt("label_status"),dt("internal_final")); log.resultado(dt("label_time"),u"{:.1f}s".format(time.time()-inicio)); log.separador(); log.salvar()
        except Exception: pass
        return 1

def _dual_validate_translation_tokens(raiz):
    pasta=os.path.join(raiz,PASTA_ENTRADA_NOME); mapa_path=os.path.join(pasta,NOME_MAPA)
    if not os.path.isfile(mapa_path): return {"ok":False,"erro":"mapa canônico ausente"}
    with io.open(mapa_path,"r",encoding="utf-8") as f: mapa=json.load(f)
    total=0; falhas=[]; validacoes=0
    for rel,entries in mapa.items():
        path=os.path.join(pasta,rel.replace("/",os.sep))
        if not os.path.isfile(path): falhas.append(u"arquivo ausente: {}".format(rel)); continue
        texts=ler_textos_traduzidos(path)
        if len(texts)!=len(entries): falhas.append(u"contagem divergente: {}".format(rel)); continue
        for i,e in enumerate(entries):
            esperado=e.get("token_signature") or []
            try:
                recebido=_token_signature_mapa(texts[i])
                if recebido!=esperado:
                    raise GoogleTranslateValidationError(u"assinatura de tokens alterada")
                validacoes+=1
            except Exception as exc: falhas.append(u"{}#{}: {}".format(rel,i+1,exc))
            total+=1
    return {"ok":not falhas,"entradas":total,"tokens_validados":validacoes,"falhas":falhas}


def executar_traducao_google_v101(raiz):
    print(dt("translate_stage"))
    rc=_V100_EXECUTAR_TRADUCAO_GOOGLE(raiz)
    if rc not in (0,None): return rc
    v=_dual_validate_translation_tokens(raiz); print(dt("tokens_stage", dt("status_ok") if v.get("ok") else dt("status_fail")))
    if not v.get("ok"):
        with io.open(os.path.join(raiz,"DDAC-Dual-Tokens-Erro.txt"),"w",encoding="utf-8") as f: f.write(u"\n".join(v.get("falhas",[]) or [v.get("erro",u"erro desconhecido")]))
        return 1
    return 0


def _dual_clean_runtime_duplicates(raiz,pasta_game,log, mapa=None):
    """Audita colisões game/common; conflitos divergentes ficam registrados para diagnóstico."""
    common=os.path.join(raiz,"renpy","common"); removed=[]; conflicts=[]; preserved=[]
    if not os.path.isdir(common): return removed,conflicts,preserved
    canonical_files=set((mapa or {}).keys())
    for root,dirs,files in os.walk(pasta_game):
        for fn in files:
            if not fn.lower().endswith((".rpy",".rpym")): continue
            src=os.path.join(root,fn); rel=_dual_norm_rel(os.path.relpath(src,pasta_game)); other=os.path.join(common,rel.replace("/",os.sep))
            if not os.path.isfile(other): continue
            try: h1=sha256_arquivo(src); h2=sha256_arquivo(other)
            except Exception: continue
            if h1==h2:
                if rel in canonical_files:
                    preserved.append({"arquivo":rel,"motivo":"mapa_atual_contem_entradas; preservado e tratado como duplicata exata do runtime"})
                    continue
                try:
                    os.remove(src); removed.append(rel)
                except Exception as exc:
                    preserved.append({"arquivo":rel,"motivo":"não foi possível remover a cópia idêntica: {}".format(exc)})
            else:
                conflicts.append({"arquivo":rel,"game_sha256":h1,"common_sha256":h2,"tratamento":"preservado_sem_alteracao_pelo_aplicador","rpyc_pareado":"invalidar_antes_da_primeira_execucao"})
    return removed,conflicts,preserved


def _dual_compile_collision_scan(pasta_game):
    paired=[]
    for root,dirs,files in os.walk(pasta_game):
        names={x.lower() for x in files}
        for fn in files:
            low=fn.lower()
            if low.endswith(".rpyc") and (low[:-1]+"y") in names:
                paired.append(_dual_norm_rel(os.path.relpath(os.path.join(root,fn),pasta_game)))
            elif low.endswith(".rpymc") and (low[:-1]+"m") in names:
                paired.append(_dual_norm_rel(os.path.relpath(os.path.join(root,fn),pasta_game)))
    return sorted(set(paired),key=lambda x:x.lower())



def _bat_set_safe(value):
    # Mensagens entram em set "VAR=..."; % deve ser duplicado para não ser expandido pelo CMD.
    value=(value or u'').replace(u'%',u'%%')
    return value.replace(u'\r',u' ').replace(u'\n',u' ')


APLICADOR_MENSAGENS={
    1:{
        'titulo':u'DDAC - Aplicar Mesclagem',
        'etapa_backup':u'[1/4] Fazendo backup da game atual...',
        'etapa_validar':u'[2/4] Validando os recursos da mesclagem...',
        'etapa_aplicar':u'[3/4] Substituindo completamente a game...',
        'etapa_final':u'[4/4] Aplicação da game concluída.',
        'erro_game_mesclada':u'A pasta game da mesclagem não foi encontrada.',
        'erro_backup_anterior':u'Não foi possível rotacionar o backup anterior da game.',
        'erro_backup_game':u'Falha no backup da game atual.',
        'erro_merged_gone':u'A pasta game da mesclagem desapareceu antes da aplicação.',
        'erro_apply':u'Falha ao aplicar a game mesclada.',
        'aviso_game_ausente':u'A pasta game atual não foi encontrada; a aplicação continuará.',
        'sucesso':u'APLICAÇÃO CONCLUÍDA COM SUCESSO',
        'backup_game':u'Backup da game original:',
        'backup_anterior':u'Backup anterior preservado:',
        'game_aplicada':u'Game aplicada:',
        'recompila':u'Os arquivos de código serão recompilados pelo Ren\'Py na próxima inicialização, quando necessário.',
        'erro_tag':u'ERRO',
        'aviso_tag':u'AVISO',
        'press':u'Pressione qualquer tecla para continuar...',
    },
    2:{
        'titulo':u'DDAC - Apply Merge',
        'etapa_backup':u'[1/4] Backing up the current game...',
        'etapa_validar':u'[2/4] Validating the merge resources...',
        'etapa_aplicar':u'[3/4] Completely replacing the game...',
        'etapa_final':u'[4/4] Game application completed.',
        'erro_game_mesclada':u'The merged game folder was not found.',
        'erro_backup_anterior':u'The previous game backup could not be rotated.',
        'erro_backup_game':u'Failed to back up the current game.',
        'erro_merged_gone':u'The merged game folder disappeared before application.',
        'erro_apply':u'Failed to apply the merged game.',
        'aviso_game_ausente':u'The current game folder was not found; the application will continue.',
        'sucesso':u'APPLICATION COMPLETED SUCCESSFULLY',
        'backup_game':u'Original game backup:',
        'backup_anterior':u'Previous backup preserved:',
        'game_aplicada':u'Applied game:',
        'recompila':u'Code files will be recompiled by Ren\'Py on the next startup when needed.',
        'erro_tag':u'ERROR',
        'aviso_tag':u'WARNING',
        'press':u'Press any key to continue...',
    },
    3:{
        'titulo':u'DDAC - Aplicar combinación',
        'etapa_backup':u'[1/4] Haciendo copia de seguridad de la game actual...',
        'etapa_validar':u'[2/4] Validando los recursos de la combinación...',
        'etapa_aplicar':u'[3/4] Sustituyendo por completo la game...',
        'etapa_final':u'[4/4] Aplicación de la game completada.',
        'erro_game_mesclada':u'No se encontró la carpeta game de la combinación.',
        'erro_backup_anterior':u'No se pudo rotar la copia de seguridad anterior de la game.',
        'erro_backup_game':u'No se pudo crear la copia de seguridad de la game actual.',
        'erro_merged_gone':u'La carpeta game de la combinación desapareció antes de la aplicación.',
        'erro_apply':u'No se pudo aplicar la game combinada.',
        'aviso_game_ausente':u'No se encontró la carpeta game actual; la aplicación continuará.',
        'sucesso':u'APLICACIÓN COMPLETADA CORRECTAMENTE',
        'backup_game':u'Copia de seguridad de la game original:',
        'backup_anterior':u'Copia de seguridad anterior conservada:',
        'game_aplicada':u'Game aplicada:',
        'recompila':u'Los archivos de código se recompilarán por Ren\'Py en el próximo inicio, cuando sea necesario.',
        'erro_tag':u'ERROR',
        'aviso_tag':u'AVISO',
        'press':u'Pulsa cualquier tecla para continuar...',
    },
}


def _multilang_placeholder_signature(texto):
    return tuple(re.findall(r'\{[^{}]*\}', texto or u''))


def validar_multilingue_completo():
    """Garante paridade estrutural entre Português, English e Español."""
    tabelas=((u'MENSAGENS',MENSAGENS),(u'APLICADOR_MENSAGENS',APLICADOR_MENSAGENS),(u'DUAL_MENSAGENS',DUAL_MENSAGENS),(u'COLISAO_RELATORIO_ROTULOS',COLISAO_RELATORIO_ROTULOS))
    for nome,tabela in tabelas:
        conjuntos=[set(tabela.get(i,{}).keys()) for i in (1,2,3)]
        if not (conjuntos[0]==conjuntos[1]==conjuntos[2]):
            raise RuntimeError(u'Multilíngua inconsistente em {}: chaves divergentes.'.format(nome))
        for chave in sorted(conjuntos[0]):
            vals=[tabela[i].get(chave,u'') for i in (1,2,3)]
            if any(v is None or v==u'' for v in vals):
                raise RuntimeError(u'Multilíngua incompleta em {}.{}'.format(nome,chave))
            sig=[_multilang_placeholder_signature(v) for v in vals]
            if not (sig[0]==sig[1]==sig[2]):
                raise RuntimeError(u'Placeholders divergentes em {}.{}'.format(nome,chave))
            br=[v.count(u'\n') for v in vals]
            if not (br[0]==br[1]==br[2]):
                raise RuntimeError(u'Quebras de linha divergentes em {}.{}'.format(nome,chave))
    return True


def _dual_write_installer(merged_root):
    """Gera um aplicador econômico e localizado. Não toca em renpy/common."""
    validar_multilingue_completo()
    installer=os.path.join(merged_root,_DUAL_INSTALLER_NAME)
    m=APLICADOR_MENSAGENS.get(IDIOMA,APLICADOR_MENSAGENS[1])
    q=lambda k:_bat_set_safe(m[k])
    template="""@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
set "MERGED=%~dp0game"
set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "TARGET=%ROOT%\\game"
set "DDAC_BACKUP_ROOT=%ROOT%\\DDAC-Backup"
set "DDAC_GAME_BACKUP=%DDAC_BACKUP_ROOT%\\game"

if not exist "%MERGED%\\" (
    echo [__ERROR_TAG__] __ERR_GAME_MERGED__
    echo __PRESS__
    pause >nul
    exit /b 1
)
if not exist "%DDAC_BACKUP_ROOT%\\" mkdir "%DDAC_BACKUP_ROOT%" >nul 2>&1

set "BACKUP_PREVIOUS="
if exist "%DDAC_GAME_BACKUP%\\" (
    set "BACKUP_PREVIOUS=%DDAC_BACKUP_ROOT%\\game-previous-%RANDOM%"
    move "%DDAC_GAME_BACKUP%" "%BACKUP_PREVIOUS%" >nul 2>&1
    if errorlevel 1 (
        echo [__ERROR_TAG__] __ERR_ROTATE__
        echo __PRESS__
        pause >nul
        exit /b 1
    )
)

if exist "%DDAC_GAME_BACKUP%\\" rmdir /Q /S "%DDAC_GAME_BACKUP%" >nul 2>&1
mkdir "%DDAC_GAME_BACKUP%" >nul 2>&1

echo ============================================================
echo __TITLE__
echo ============================================================
echo __STEP1__
if exist "%TARGET%\\" (
    robocopy "%TARGET%" "%DDAC_GAME_BACKUP%" /E /COPY:DAT /R:0 /W:0 /NFL /NDL /NJH /NJS /XF *.rpyc *.rpymc >nul
    if errorlevel 8 (
        echo [__ERROR_TAG__] __ERR_BACKUP_GAME__
        echo __PRESS__
        pause >nul
        exit /b 1
    )
) else (
    echo [__WARNING_TAG__] __WARN_GAME_MISSING__
)

echo __STEP2__
if not exist "%MERGED%\\" (
    echo [__ERROR_TAG__] __ERR_MERGED_GONE__
    call :DDAC_ROLLBACK_GAME
    echo __PRESS__
    pause >nul
    exit /b 1
)

echo __STEP3__
if exist "%TARGET%\\" rmdir /Q /S "%TARGET%" >nul 2>&1
mkdir "%TARGET%" >nul 2>&1
robocopy "%MERGED%" "%TARGET%" /E /COPY:DAT /R:0 /W:0 /NFL /NDL /NJH /NJS /XF *.rpyc *.rpymc >nul
if errorlevel 8 (
    echo [__ERROR_TAG__] __ERR_APPLY__
    call :DDAC_ROLLBACK_GAME
    echo __PRESS__
    pause >nul
    exit /b 1
)

echo __STEP4__
echo.
echo ============================================================
echo __SUCCESS__
echo ============================================================
echo __BACKUP_GAME__ "%DDAC_GAME_BACKUP%"
if defined BACKUP_PREVIOUS echo __BACKUP_PREVIOUS__ "%BACKUP_PREVIOUS%"
echo __GAME_APPLIED__ "%TARGET%"
echo.
echo __RECOMPILE__
echo ============================================================
echo __PRESS__
pause >nul
exit /b 0

:DDAC_ROLLBACK_GAME
if exist "%TARGET%\\" rmdir /Q /S "%TARGET%" >nul 2>&1
if exist "%DDAC_GAME_BACKUP%\\" (
    mkdir "%TARGET%" >nul 2>&1
    robocopy "%DDAC_GAME_BACKUP%" "%TARGET%" /E /COPY:DAT /R:0 /W:0 /NFL /NDL /NJH /NJS /XF *.rpyc *.rpymc >nul
)
exit /b 0
"""
    rep={
        '__ERR_GAME_MERGED__':q('erro_game_mesclada'),'__ERROR_TAG__':q('erro_tag'),'__WARNING_TAG__':q('aviso_tag'),'__PRESS__':q('press'),'__TITLE__':q('titulo'),
        '__STEP1__':q('etapa_backup'),'__ERR_ROTATE__':q('erro_backup_anterior'),'__ERR_BACKUP_GAME__':q('erro_backup_game'),
        '__WARN_GAME_MISSING__':q('aviso_game_ausente'),'__STEP2__':q('etapa_validar'),'__ERR_MERGED_GONE__':q('erro_merged_gone'),
        '__STEP3__':q('etapa_aplicar'),'__ERR_APPLY__':q('erro_apply'),'__STEP4__':q('etapa_final'),
        '__SUCCESS__':q('sucesso'),'__BACKUP_GAME__':q('backup_game'),'__BACKUP_PREVIOUS__':q('backup_anterior'),
        '__GAME_APPLIED__':q('game_aplicada'),'__RECOMPILE__':q('recompila')
    }
    for a,b in rep.items(): template=template.replace(a,b)
    with io.open(installer,'w',encoding='utf-8',newline='\r\n') as f: f.write(template)
    return installer

def _dual_collision_report_path_temp():
    global _DUAL_COLLISION_REPORT_DIR
    if _DUAL_COLLISION_REPORT_DIR is None or not os.path.isdir(_DUAL_COLLISION_REPORT_DIR):
        _DUAL_COLLISION_REPORT_DIR = tempfile.mkdtemp(prefix="ddac_colisao_relatorio_")
    return os.path.join(_DUAL_COLLISION_REPORT_DIR, _DUAL_COLLISION_REPORT_NAME)


def _dual_collision_report_has_findings(report):
    for chave in ("removidos_game_vs_renpy_common_identicos", "conflitos_game_vs_renpy_common_diferentes", "preservados_por_mapa_antigo", "rpyc_pareados_reportados"):
        if report.get(chave):
            return True
    if report.get("rpyc_pareados_nao_apagados") is not True:
        return True
    if report.get("instalacao_final_substitui_game_inteiramente") is not True:
        return True
    return False


def _dual_finalize_collision_report(raiz, report):
    global _DUAL_COLLISION_REPORT_DIR
    temp_path = _dual_collision_report_path_temp()
    with io.open(temp_path,"w",encoding="utf-8") as f:
        json.dump(report,f,ensure_ascii=False,indent=2)
    for legado in (_DUAL_COLLISION_REPORT_NAME, _DUAL_COLLISION_REPORT_LEGACY_NAME):
        stale = os.path.join(raiz,legado)
        if os.path.isfile(stale):
            try: os.remove(stale)
            except Exception: pass
    if _dual_collision_report_has_findings(report):
        final_path = os.path.join(raiz,_DUAL_COLLISION_REPORT_NAME)
        shutil.copyfile(temp_path, final_path)
        try: shutil.rmtree(_DUAL_COLLISION_REPORT_DIR, ignore_errors=True)
        except Exception: pass
        _DUAL_COLLISION_REPORT_DIR = None
        return final_path
    try: shutil.rmtree(_DUAL_COLLISION_REPORT_DIR, ignore_errors=True)
    except Exception: pass
    _DUAL_COLLISION_REPORT_DIR = None
    return None


def executar_reinjecao_v101(raiz):
    print(dt("reinject_stage"))
    rc=_V100_EXECUTAR_REINJECAO(raiz)
    if rc not in (0,None): return rc
    pasta_game=encontrar_pasta_game(raiz); merged=os.path.join(raiz,PASTA_SAIDA_TRADUZIDO_NOME,os.path.basename(os.path.normpath(pasta_game)))
    print(dt("output_stage"))
    log=Log(os.path.join(raiz,NOME_LOG_REINJETOR)); mapa_path=os.path.join(raiz,PASTA_ENTRADA_NOME,NOME_MAPA); mapa_atual={}
    try:
        if os.path.isfile(mapa_path):
            with io.open(mapa_path,"r",encoding="utf-8") as f: mapa_atual=json.load(f)
    except Exception:
        mapa_atual={}
    print(dt("audit_stage"), flush=True)
    removed,conflicts,preserved=_dual_clean_runtime_duplicates(raiz,merged,log,mapa_atual); paired=_dual_compile_collision_scan(merged)
    report={"removidos_game_vs_renpy_common_identicos":removed,"conflitos_game_vs_renpy_common_diferentes":conflicts,"preservados_por_mapa_antigo":preserved,"rpyc_pareados_reportados":paired,"rpyc_pareados_nao_apagados":True,"instalacao_final_substitui_game_inteiramente":True,"_rotulos":COLISAO_RELATORIO_ROTULOS.get(IDIOMA,COLISAO_RELATORIO_ROTULOS[1])}
    report["_relatorio"]={"título":dt("report_title"),"resultado":dt("report_issue") if _dual_collision_report_has_findings(report) else dt("report_no_issue"),"idioma":COLISAO_RELATORIO_ROTULOS.get(IDIOMA,COLISAO_RELATORIO_ROTULOS[1])["idioma"]}
    collision_path=_dual_finalize_collision_report(raiz,report)
    installer=_dual_write_installer(os.path.dirname(merged)); print(dt("audit_summary",len(removed),len(conflicts),len(preserved),len(paired))); print(dt("installer", installer));
    anexar_linhas_log(NOME_LOG_REINJETOR,[u"="*60,dt("audit_stage"),dt("audit_summary",len(removed),len(conflicts),len(preserved),len(paired)),dt("label_removed")+u": "+str(len(removed)),dt("label_conflicts")+u": "+str(len(conflicts)),dt("label_preserved")+u": "+str(len(preserved))])
    return 0


_V100_EXECUTAR_TRADUCAO_GOOGLE=executar_traducao_google
_V100_EXECUTAR_REINJECAO=executar_reinjecao

# Compatibilidade de roteamento: Opção 2 usa o motor Google Translate Web (RPC) V141
# definida acima; Opções 1 e 3 continuam apontando para os pipelines
# DualBrain/Reintegração já validados.
_V141_EXECUTAR_TRADUCAO_GOOGLE=executar_traducao_google
def executar_extracao(raiz): return executar_pipeline_dual_v112(raiz)
def executar_traducao_google(raiz): return _V141_EXECUTAR_TRADUCAO_GOOGLE(raiz)
def executar_reinjecao(raiz): return executar_reinjecao_v101(raiz)


def executar_selftest_v118(raiz):
    global IDIOMA
    assert GOOGLE_WORKERS == 5
    _credito_teste = u"Song Covers:\nEnd of Small Sanctuary by Akira Yamaoka and Team Silent\nBe Quiet and Drive (Acoustic ver.) by Deftones\n"
    assert parece_bloco_creditos_google(_credito_teste, u"screens.rpy", u"ui") is True
    assert _rotulo_credito_eh_categoria(u"Song Covers") is True
    assert _rotulo_credito_eh_categoria(u"Casual Monika") is False
    assert entrada_nao_traduzivel_google(_credito_teste, u"screens.rpy", u"ui") is False
    assert GOOGLE_INTERVALO_MINIMO >= 0.30
    assert GOOGLE_RETRIES >= 2
    assert GoogleRPCClient is not GoogleGTXClient
    assert GOOGLE_SCHEDULER_CHUNK == 50
    assert GOOGLE_CACHE_SCHEMA == 13
    assert GOOGLE_CACHE_MOTOR_ID == u"rpc-v1"
    assert GOOGLE_CACHE_CREDITOS_MOTOR_ID == u"rpc-v1-credit-v2"
    assert validar_multilingue_completo() is True
    for _idioma_test in (1,2,3):
        assert DUAL_MENSAGENS[_idioma_test]["titulo"]
        assert COLISAO_RELATORIO_ROTULOS[_idioma_test]["idioma"]
    a={"arquivo":"x.rpy","linha":10,"coluna_inicio":0,"coluna_fim":5,"original":"Hello","tipo":"dialogo","motor":"DDAC","proveniencia":["DDAC"]}
    b=dict(a); b["motor"]="RenPy"; b["proveniencia"]=["RenPy"]
    c=dict(a); c.update({"coluna_inicio":1,"coluna_fim":4,"original":"ell"})
    merged,st=_dual_resolve_exact_duplicates([a,b]); assert len(merged)==1 and st["duplicatas"]==1
    resolved,conf=_dual_resolve_overlaps([a,c]); assert len(resolved)==1 and conf
    cmp=_dual_stage4_compare([a],[b]); assert cmp["concordancias_exatas"]==1
    with tempfile.TemporaryDirectory(prefix="ddac_v112_stage2_") as td:
        game=os.path.join(td,"game"); os.makedirs(game)
        with io.open(os.path.join(game,"x.rpy"),"w",encoding="utf-8") as f: f.write("label start:\n    \"Hello\"\n")
        assert os.path.isdir(game)
    # Regressão V142: preservar palavras estáticas visíveis em expressões
    # dinâmicas de `textbutton` sem extrair o valor variável nem ações.
    with tempfile.TemporaryDirectory(prefix="ddac_v142_screen_expr_") as td:
        fixture=os.path.join(td,"screen_expr.rpy")
        with io.open(fixture,"w",encoding="utf-8") as f:
            f.write('screen test:\n'
                    '    textbutton indent*2+"- "+"camera" action Return()\n'
                    '    textbutton indent*4+"  with [value[1]]":\n'
                    '        action Return()\n'
                    '    textbutton "[value]" action Return()\n'
                    '    textbutton text action Return()\n')
        _fixture_texts,_fixture_map=extrair_arquivo_com_mapa(fixture,set(),{},set(),{})
        _fixture_literals=[e.get("original","") for e in _fixture_map]
        assert '"camera"' in _fixture_literals
        assert '"  with [value[1]]"' in _fixture_literals
        assert '"[value]"' not in _fixture_literals
        assert '"Return()"' not in _fixture_literals
    _report_test={"removidos_game_vs_renpy_common_identicos":[],"conflitos_game_vs_renpy_common_diferentes":[],"preservados_por_mapa_antigo":[],"rpyc_pareados_reportados":[],"rpyc_pareados_nao_apagados":True,"instalacao_final_substitui_game_inteiramente":True}
    assert _dual_collision_report_has_findings(_report_test) is False
    assert _dual_collision_report_has_findings(dict(_report_test, rpyc_pareados_nao_apagados=False)) is True
    assert _DUAL_INSTALLER_NAME=="DDAC-APLICAR-MESCLAGEM.bat"
    assert executar_extracao.__name__ == "executar_extracao"
    assert executar_extracao is not executar_extracao.__globals__.get("_V100_EXECUTAR_REINJECAO")
    _test_tmp=tempfile.mkdtemp(prefix="ddac_v115_installer_")
    try:
        _inst=_dual_write_installer(_test_tmp)
        _txt=io.open(_inst,"r",encoding="utf-8").read()
        assert 'set "DDAC_BACKUP_ROOT=%ROOT%\\DDAC-Backup"' in _txt
        assert 'set "DDAC_GAME_BACKUP=%DDAC_BACKUP_ROOT%\\game"' in _txt
        assert "DDAC Backup" not in _txt
        assert "/XF *.rpyc *.rpymc" in _txt
        assert "DDAC Backup" not in _txt
        assert "renpy\\common" not in _txt.lower()
    finally:
        shutil.rmtree(_test_tmp,ignore_errors=True)
    with tempfile.TemporaryDirectory(prefix="ddac_v117_collision_") as tdc:
        global _DUAL_COLLISION_REPORT_DIR
        empty={"removidos_game_vs_renpy_common_identicos":[],"conflitos_game_vs_renpy_common_diferentes":[],"preservados_por_mapa_antigo":[],"rpyc_pareados_reportados":[],"rpyc_pareados_nao_apagados":True,"instalacao_final_substitui_game_inteiramente":True,"_rotulos":COLISAO_RELATORIO_ROTULOS[1],"_relatorio":{"título":dt("report_title"),"resultado":dt("report_no_issue"),"idioma":"Português"}}
        assert _dual_finalize_collision_report(tdc, empty) is None
        assert not os.path.exists(os.path.join(tdc,_DUAL_COLLISION_REPORT_NAME))
        finding=dict(empty); finding["conflitos_game_vs_renpy_common_diferentes"]=[{"arquivo":"x.rpy"}]
        outp=_dual_finalize_collision_report(tdc,finding)
        assert outp and os.path.isfile(outp)
        with io.open(outp,"r",encoding="utf-8") as f: _cr=json.load(f)
        assert _cr["conflitos_game_vs_renpy_common_diferentes"]
        _logp=os.path.join(tdc,"reinj.txt")
        with io.open(_logp,"w",encoding="utf-8") as f: f.write(u"base\n")
        anexar_linhas_log(_logp,[u"auditoria",u"Conflitos: 0"])
        assert io.open(_logp,"r",encoding="utf-8").read().splitlines()[-2:] == [u"auditoria",u"Conflitos: 0"]
        shutil.rmtree(os.path.dirname(outp),ignore_errors=True)
    with tempfile.TemporaryDirectory(prefix="ddac_v112_rpyc_") as tdc:
        gc=os.path.join(tdc,"game"); os.makedirs(gc)
        with io.open(os.path.join(gc,"sample.rpy"),"w",encoding="utf-8") as f: f.write('label start:\n    "Olá"\n')
        with io.open(os.path.join(gc,"sample.rpyc"),"wb") as f: f.write(b"compiled")
        removidos=limpar_compilados_sombreados(gc)
        assert "sample.rpyc" in removidos and not os.path.exists(os.path.join(gc,"sample.rpyc"))
        # A validação deve aceitar somente os compilados explicitamente invalidados.
        outc=os.path.join(tdc,"out"); shutil.copytree(gc,outc)
        mapa_c={ "sample.rpy": [{"linha":2,"coluna_inicio":4,"coluna_fim":10,"original":"\"Olá\""}] }
        with io.open(os.path.join(tdc,"mapa.json"),"w",encoding="utf-8") as f: json.dump(mapa_c,f)
    # Regressão global: strings fixas em interface construída dinamicamente.
    with tempfile.TemporaryDirectory(prefix="ddac_v143_ui_dynamic_") as td:
        gc=os.path.join(td,"game"); os.makedirs(gc)
        sample=os.path.join(gc,"sample.rpy")
        with io.open(sample,"w",encoding="utf-8") as f:
            f.write('''init python:\n    props_sets = (\n        ("Child/Pos", ("child", "xpos")),\n    )\n    renpy.notify(_(value + " is not callable."))\n    button_list.append((("edit child: {}".format(v[0])), action))\n''')
        _dynamic_texts, _dynamic_map = extrair_arquivo_com_mapa(sample, set(), {}, {}, {})
        _dynamic_values = [item[1] for item in _dynamic_texts]
        assert any('edit child' in value for value in _dynamic_values), 'template de botão dinâmico não detectado'
        assert any('is not callable' in value for value in _dynamic_values), 'fragmento de notificação não detectado'
        assert any('Child/Pos' in value for value in _dynamic_values), 'rótulo de grupo da interface não detectado'
    # Regressão V145: textos comuns de UI e diálogo preservados sem extrair ações/código.
    with tempfile.TemporaryDirectory(prefix="ddac_v145_ui_coverage_") as td:
        fixture=os.path.join(td,"ui.rpy")
        with io.open(fixture,"w",encoding="utf-8") as f:
            f.write('label start:\n'
                    '    "Hello, [player_name]!"\n'
                    '    menu:\n'
                    '        "Continue":\n'
                    '            pass\n'
                    'screen test_menu:\n'
                    '    textbutton "Save" action Return()\n'
                    '    textbutton "Settings" action ShowMenu("preferences")\n'
                    '    textbutton dynamic_label action Return()\n')
        _ui_texts,_ui_map=extrair_arquivo_com_mapa(fixture,set(),{},set(),{})
        _ui_literals=[e.get("original","") for e in _ui_map]
        assert '"Hello, [player_name]!"' in _ui_literals
        assert '"Continue"' in _ui_literals
        assert '"Save"' in _ui_literals
        assert '"Settings"' in _ui_literals
        assert '"Return()"' not in _ui_literals
        assert '"preferences"' not in _ui_literals
        assert '"dynamic_label"' not in _ui_literals
    # Regressão V145: falha do oráculo não bloqueia a extração e deixa relatório rastreável.
    with tempfile.TemporaryDirectory(prefix="ddac_v145_oracle_fallback_") as td:
        game=os.path.join(td,"game"); os.makedirs(game)
        with io.open(os.path.join(game,"script.rpy"),"w",encoding="utf-8") as f:
            f.write('label start:\n    "Fallback dialogue"\nscreen test:\n    textbutton "Exit" action Return()\n')
        _orig_stage3=globals().get("_dual_stage3_renpy")
        _orig_language=IDIOMA
        def _force_oracle_unavailable(_game,_candidates,_log):
            for _k in ORACULO_RENPY:
                if isinstance(ORACULO_RENPY[_k],list): ORACULO_RENPY[_k]=[]
                elif isinstance(ORACULO_RENPY[_k],dict): ORACULO_RENPY[_k]={}
                elif isinstance(ORACULO_RENPY[_k],bool): ORACULO_RENPY[_k]=False
                elif isinstance(ORACULO_RENPY[_k],int): ORACULO_RENPY[_k]=0
                else: ORACULO_RENPY[_k]=u""
            ORACULO_RENPY["falhas"]=[u"falha simulada de teste"]
            return []
        try:
            globals()["_dual_stage3_renpy"]=_force_oracle_unavailable
            _fallback_rc=executar_pipeline_dual_v112(td)
            assert _fallback_rc==0, "fallback deve completar sem oráculo"
            _fallback_report_path=os.path.join(td,_DUAL_REPORT_NAME)
            assert os.path.isfile(_fallback_report_path), "relatório deve persistir na raiz"
            with io.open(_fallback_report_path,"r",encoding="utf-8") as f: _fallback_report=json.load(f)
            assert _fallback_report.get("terminal_status")=="EXTRACAO_CONCLUIDA_SEM_VALIDACAO"
            assert _fallback_report.get("oraculo_renpy_ativo") is False
            assert _fallback_report.get("motor_fallback_ddac") is True
            _fallback_map_path=os.path.join(td,PASTA_ENTRADA_NOME,NOME_MAPA)
            assert os.path.isfile(_fallback_map_path), "mapa deve ser criado pelo fallback"
            with io.open(_fallback_map_path,"r",encoding="utf-8") as f: _fallback_map=json.load(f)
            assert _fallback_map, "fallback deve produzir entradas canônicas"
        finally:
            globals()["_dual_stage3_renpy"]=_orig_stage3
            IDIOMA=_orig_language
    # Regressão V145: ausência de fontes não pode resultar em mapa vazio nem mover a saída anterior.
    with tempfile.TemporaryDirectory(prefix="ddac_v145_no_sources_") as td:
        game=os.path.join(td,"game"); os.makedirs(game)
        with io.open(os.path.join(game,"scripts.rpa"),"wb") as f: f.write(b"RPA-3.0 test")
        outdir=os.path.join(td,PASTA_ENTRADA_NOME); os.makedirs(outdir)
        sentinel=os.path.join(outdir,"nao_apagar.txt")
        with io.open(sentinel,"w",encoding="utf-8") as f: f.write(u"extração anterior")
        rc_sem_fonte=executar_pipeline_dual_v112(td)
        assert rc_sem_fonte != 0, "sem fontes o pipeline deve falhar explicitamente"
        assert os.path.isfile(sentinel), "a extração anterior não deve ser movida/substituída"
        semfonte_report=os.path.join(td,_DUAL_REPORT_NAME)
        with io.open(semfonte_report,"r",encoding="utf-8") as f: rr=json.load(f)
        assert rr.get("terminal_status")=="SEM_FONTES_DE_SCRIPT"
        assert not os.path.isfile(os.path.join(outdir,NOME_MAPA)), "não criar mapa vazio"
    print(u"SELFTEST V145: OK | UI/dialogo, código protegido, fallback do oráculo, relatório persistente e sem-fonte")
    return 0


def main():
    global IDIOMA, NOME_LOG_EXTRATOR, NOME_LOG_REINJETOR, NOME_LOG_TRADUTOR, NOME_MAPA
    modo = sys.argv[1] if len(sys.argv) > 1 else ""
    raiz = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()

    try:
        escolhido = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    except ValueError:
        escolhido = 1
    IDIOMA = escolhido if escolhido in MENSAGENS else 1
    MODO_EXIBICAO = u"resumido"
    NOME_LOG_EXTRATOR = NOMES_LOG_EXTRACAO_IDIOMA.get(IDIOMA, NOMES_LOG_EXTRACAO_IDIOMA[1])
    NOME_LOG_REINJETOR = NOMES_LOG_REINTEGRACAO_IDIOMA.get(IDIOMA, NOMES_LOG_REINTEGRACAO_IDIOMA[1])
    NOME_LOG_TRADUTOR = NOMES_LOG_TRADUCAO_IDIOMA.get(IDIOMA, NOMES_LOG_TRADUCAO_IDIOMA[1])
    atualizar_nomes_pastas_por_idioma()

    if modo in ("selftest_v101", "selftest_v102", "selftest_v103", "selftest_v104", "selftest_v105", "selftest_v106", "selftest_v107", "selftest_v108", "selftest_v109", "selftest_v112", "selftest_v113", "selftest_v116", "selftest_v117", "selftest_v118", "selftest_v143", "selftest_v145"):
        return executar_selftest_v118(raiz)
    if modo == "detectar_sdk":
        return executar_deteccao_sdk(raiz)
    if modo == "preflight_tokens":
        return executar_teste_integridade_tokens()
    if modo == "preflight_sintaxe":
        return executar_teste_cobertura_sintaxe_renpy()

    if modo == "preflight":
        etapa = sys.argv[4].strip().lower() if len(sys.argv) > 4 else "extrair"
        return executar_preflight(raiz, etapa)
    elif modo == "extrair":
        retorno = executar_extracao(raiz)
        return retorno if retorno is not None else 0
    elif modo == "traduzir":
        return executar_traducao_google(raiz)
    elif modo == "diagnostico_google":
        return executar_diagnostico_google(raiz)
    elif modo == "diagnostico_estresse_google":
        return executar_diagnostico_estresse_google(raiz)
    elif modo == "reinjetar":
        retorno = executar_reinjecao(raiz)
        return retorno if retorno is not None else 0
    else:
        print(t("modo_desconhecido").format(modo))

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        import traceback
        traceback.print_exc()
        sys.exit(1)
