@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion
REM DDAC internal build: V144-DualBrain-GoogleRPC-CreditCache-FastResidual-MultilineCompat-ScreenDynamicText-Windows
REM V144: remove somente o subsistema DDAC Debug de Diálogos; preserva os logs operacionais e as correções de extração da V143.
title UnRen-DDAC - V145 - Texto Visível - Extração - Tradução - Reintegração - by Pedro
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
set "PYTHONUNBUFFERED=1"

REM Garante um ambiente limpo desde o início: se o Windows do usuário já tiver
REM PYTHONHOME/PYTHONPATH definidas globalmente (comum quando há outro Python
REM instalado na máquina), essas variáveis quebram o Python embutido usado aqui
REM com "ImportError: No module named site". A rotina de Diálogos define o que
REM precisar por conta própria mais adiante.
set "PYTHONHOME="
set "PYTHONPATH="

REM =============================================================================
REM UnRen-DDAC - Extração - Tradução - Mesclagem - by Pedro
REM Compatibilidade desta versão: Windows / CMD.exe. O arquivo usa recursos nativos
REM do Windows (PowerShell, findstr e o runtime Python embutido/cacheado). Não é
REM um script .sh/.command e não é executável nativamente no Linux ou macOS.
REM V145 - extração ampla de texto visível, Google Translate e reintegração - oráculo opcional com fallback e relatório persistente
REM
REM Este arquivo contém SOMENTE a rotina de Diálogos:
REM   1) Extrair diálogos      - separa o texto traduzível dos arquivos .rpy
REM   2) Google Translate      - traduz a extração usando o serviço Google Translate
REM   3) Reinjetar tradução    - devolve o texto traduzido para os .rpy originais
REM
REM Tudo que a rotina precisa está aqui dentro: menu de idioma (pt/en/es),
REM termos de uso, localização da dependência (Python 3 embeddable oficial),
REM download/validação dessa dependência e o código Python embutido no fim do
REM arquivo, depois do marcador.
REM =============================================================================

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "SDKROOT=%LOCALAPPDATA%\DDAC"
set "LOG_DIALOGOS="
set "LOG=%LOG_DIALOGOS%"
:lang_menu
cls
echo.
echo  ============================================================
echo   UnRen-DDAC - by Pedro
echo  ============================================================
echo.
echo   Escolha o seu idioma:
echo.
echo    1) Português
echo    2) English
echo    3) Español
echo.
set "LANG="
set /p "LANG=Opção: "
if "%LANG%"=="1" goto lang_pt
if "%LANG%"=="2" goto lang_en
if "%LANG%"=="3" goto lang_es
echo.
echo  Opção inválida. / Invalid option. / Opción no válida.
pause
goto lang_menu
:lang_pt
set "txt_tag_erro=ERRO"
set "T_TITLE=UnRen-DDAC - by Pedro"
set "T_SUPPORT=Ren'Py 6 / 7 / 8"
set "T_DISCLAIMER=Criação de fã não oficial, sem vínculo com a Team Salvato."
set "T_CHOOSE=Escolha uma opção:"
set "T_DIALOGOS=Extrair / traduzir / reintegrar diálogos traduzíveis"
set "T_DIALOGOS_DESC=Extrai, traduz com Google Translate e reintegra o texto traduzível do mod"
set "T_DLG_EXTRACT=Extrair diálogos do mod para traduzir"
set "T_DLG_EXTRACT_DET=da pasta game para a pasta DDAC-Diálogos-Extraídos"
set "T_DLG_TRANSLATE=Traduzir os textos extraídos com Google Translate"
set "T_DLG_TRANSLATE_DET=da pasta DDAC-Diálogos-Extraídos para a pasta DDAC-Diálogos-Traduzidos"
set "T_DLG_REINJECT=Reinjetar a tradução no mod"
set "T_DLG_REINJECT_DET=da pasta DDAC-Diálogos-Traduzidos ou DDAC-Diálogos-Extraídos para DDAC-Diálogos-Mesclados"
set "T_DLG_DIAG=Diagnosticar a conexão com o Google Translate"
set "T_DLG_DIAG_DET=mede a página do Google e o endpoint real de tradução antes de qualquer mudança no motor"
set "T_PATCH=Patch de interface PT-BR do Ren'Py"
set "T_PATCH_DESC=cria automaticamente o arquivo completo da interface interna dentro da pasta game do projeto"
set "T_PATCH_EXIST=O patch já existe nesse game e será atualizado."
set "T_PATCH_OK=Patch de interface PT-BR criado com sucesso:"
set "T_PATCH_NOGAME=A pasta game não foi encontrada ao lado deste arquivo."
set "T_PATCH_ERR=Não foi possível preparar o arquivo do patch."
set "T_PATCH_PRIORITY1=Este arquivo tem prioridade sobre a tradução do jogo nas opções de interface que ele força."
set "T_PATCH_PRIORITY2=Exemplo: se o jogo traduzir Preferences como Preferências, o patch força Configurações."
set "T_PATCH_PRIORITY3=A tradução original do jogo não é apagada nem modificada."
set "T_PATCH_PRESS=Pressione ENTER para sair:"
set "T_DLG_START_DIAG=[INÍCIO] Diagnóstico do Google Translate..."
set "T_DLG_START_EXTRACT=[INÍCIO] Extraindo os diálogos traduzíveis do mod/jogo..."
set "T_DLG_PREFLIGHT_TITLE=VERIFICAÇÃO PRÉVIA"
set "T_DLG_PREFLIGHT_READONLY=Checagem somente leitura. Nenhum arquivo do jogo será modificado aqui."
set "T_DLG_PREFLIGHT_CONTINUE=Pré-verificação concluída. Iniciando a etapa..."
set "T_DLG_START_TRANSLATE=[INÍCIO] Traduzindo os diálogos com Google Translate..."
set "T_DLG_START_REINJECT=[INÍCIO] Reinjetando a tradução nos arquivos do mod/jogo..."
set "T_DLG_LOG_TITLE=LOG DO JOGO NECESSÁRIO PARA A EXTRAÇÃO"
set "T_DLG_LOG_MISSING=O log.txt deste jogo/mod não foi gerado ou não foi encontrado."
set "T_DLG_LOG_MISSING_2=Para identificar a versão exata do RenPy com segurança, o DDAC precisa desse log."
set "T_DLG_LOG_ACTION=Saia do DDAC, execute o jogo/mod uma vez, feche o jogo e execute novamente a Opção 1."
set "T_DLG_LOG_VERSION=Versão RenPy obtida do log:"
set "T_DLG_LOG_PATH=Caminho do log usado:"
set "T_DLG_ERR_MARK=Erro interno: não foi possível localizar o código Python embutido neste arquivo."
set "T_DLG_ERR_MARK2=O .bat pode ter sido corrompido ou editado incorretamente."
set "T_DLG_DEP_L1=Esta ferramenta de Diálogos usa um Python 3 próprio e independente,"
set "T_DLG_DEP_L2=para executar o motor DDAC; ele NÃO substitui o Python interno do RenPy usado pelo SDK semântico."
set "T_DLG_ERR_DEP=Não foi possível preparar a dependência necessária para os Diálogos."
set "T_DLG_ERR_DEP2=Tente novamente, ou baixe manualmente pela página oficial mostrada acima."
set "T_DLG_DEP_TITLE=DEPENDÊNCIA NECESSÁRIA"
set "T_DLG_DEP_CANDOWNLOAD=O UnRen-DDAC pode baixar automaticamente o Python 3.13.15"
set "T_DLG_DEP_EMBED=embutível, usado somente pelo motor DDAC de Diálogos (não pelo SDK RenPy)."
set "T_DLG_DEP_NOTINSTALLED=Ele NÃO será instalado no Windows e NÃO altera o Python do PC."
set "T_DLG_SDK_TITLE=DEPENDÊNCIA REN'PY NECESSÁRIA"
set "T_DLG_SDK_TITLE_CENTER=               DEPENDÊNCIA REN'PY NECESSÁRIA"
set "T_DLG_SDK_L1=O Python 3 acima é o runtime do motor DDAC. A extração completa também usa o SDK oficial Ren'Py"
set "T_DLG_SDK_L2=compatível com o mod/jogo, usando o Python que vem dentro desse SDK."
set "T_DLG_SDK_DETECTED=Versão Ren'Py detectada:"
set "T_DLG_SDK_SELECTED=SDK Ren'Py selecionado:"
set "T_DLG_ALL_READY_RUNTIME=Python 3 do DDAC pronto:"
set "T_DLG_ALL_READY_SDK=SDK Ren'Py pronto:"
set "T_DLG_SDK_CACHE=Caminho do cache:"
set "T_DLG_SDK_SOURCE=Fonte oficial:"
set "T_DLG_SDK_DOWNLOAD=2) Baixar automaticamente o SDK oficial agora  (RECOMENDADO)"
set "T_DLG_SDK_OPENPAGE=1) Abrir a página oficial no navegador"
set "T_DLG_SDK_CANCEL=3) Cancelar"
set "T_DLG_SDK_READY_TITLE=TODAS AS DEPENDÊNCIAS PREPARADAS COM SUCESSO"
set "T_DLG_SDK_READY_L1=Python 3 e o SDK Ren'Py compatível foram preparados e verificados pelo UnRen-DDAC."
set "T_DLG_SDK_READY_L2=As duas dependências estão prontas. A extração só começa depois da escolha 1."
set "T_DLG_SDK_CONTINUE=1) Continuar com a extração agora"
set "T_DLG_SDK_BACK=2) Voltar ao menu principal"
set "T_DLG_SDK_EXACT=O script não trocará silenciosamente por outro SDK quando uma versão exata tiver sido detectada."
set "T_DLG_SDK_DOWNLOADING=Baixando o SDK Ren'Py oficial..."
set "T_DLG_SDK_EXTRACTING=Extraindo o SDK para o cache compartilhado..."
set "T_DLG_SDK_FAIL=Não foi possível preparar o SDK Ren'Py necessário para a Opção 1."
set "T_DLG_DEP_SOURCE=Fonte oficial:"
set "T_DLG_DEP_PAGE=Página oficial:"
set "T_DLG_DEP_OPENPAGE=1) Abrir a página oficial no navegador"
set "T_DLG_DEP_DOWNLOAD=2) Baixar automaticamente da fonte oficial agora  (RECOMENDADO)"
set "T_DLG_DEP_CANCEL=3) Cancelar"
set "T_DLG_DEP_PAGEOPENED=Página oficial aberta no navegador."
set "T_DLG_DEP_RUNAGAIN=Depois execute o UnRen-DDAC novamente."
set "T_DLG_DEP_ERR_RESULT=! Erro: o download não retornou nenhum resultado."
set "T_DLG_DEP_ERR_DOWNLOAD=! Erro no download:"
set "T_DLG_DEP_ERR_SIZE=! Erro: o tamanho recebido não corresponde ao pacote oficial esperado."
set "T_DLG_DEP_EXPECTED=Esperado:"
set "T_DLG_DEP_RECEIVED=Recebido:"
set "T_DLG_DEP_BYTES=bytes"
set "T_DLG_DEP_ERR_INTEGRITY=! ERRO DE INTEGRIDADE: o SHA-256 recebido não corresponde ao oficial."
set "T_DLG_DEP_DISCARDED=O arquivo baixado foi descartado."
set "T_DLG_DEP_ERR_FINALIZE=! Erro ao finalizar o download."
set "T_DLG_DEP_ERR_EXTRACT=! Erro ao extrair o pacote baixado."
set "T_DLG_DEP_ERR_NOPYTHON=! Erro: o pacote foi baixado, mas python.exe não foi encontrado."
set "T_DLG_DEP_ERR_START=! Erro: não foi possível iniciar o runtime baixado."
set "T_DLG_DEP_READY_TITLE=DEPENDÊNCIA PREPARADA COM SUCESSO"
set "T_DLG_DEP_READY_L1=A dependência necessária para os Diálogos foi baixada e"
set "T_DLG_DEP_READY_L2=verificada devidamente pelo UnRen-DDAC."
set "T_DLG_DEP_CONTINUE=1) Continuar com os Diálogos agora"
set "T_DLG_DEP_BACK=2) Voltar para o menu principal"
set "T_DLG_DEP_INVALID12=Opção inválida. Escolha 1 ou 2."
set "T_EXIT=Sair"
set "T_OPTION=Opção:"
set "T_INVALID=Opção inválida."
set "T_DLG_ERR_EXEC_HINT=Consulte a saída acima e o log, se necessário."
set "T_EXIT=Sair"
set "T_OPTION=Opção:"
set "T_INVALID=Opção inválida."
set "T_TERMS_TITLE=TERMOS DE USO"
set "T_TERMS_L01=UnRen-DDAC - by Pedro"
set "T_TERMS_L03=Aplicativo fan-made, sem vínculo oficial com a Team Salvato"
set "T_TERMS_L04=nem com o projeto Ren'Py."
set "T_TERMS_L06=SOBRE ESTE SCRIPT:"
set "T_TERMS_L07=- Extrai .rpa e descompila .rpyc de projetos Ren'Py"
set "T_TERMS_L07_2="
set "T_TERMS_L08=- Extrai diálogos traduzíveis e reinjeta a tradução no projeto"
set "T_TERMS_L09=- Gera a distribuição final do mod usando o SDK do Ren'Py"
set "T_TERMS_L10=- Pode gerar ports Android usando o RAPT oficial do Ren'Py e sempre"
set "T_TERMS_L10_2=  gera APK na versão atual do script"
set "T_TERMS_L10B=- Em projetos Ren'Py 6, usa um motor compatível mais novo somente"
set "T_TERMS_L10B_2=  durante a etapa do port mobile; o projeto original não é migrado."
set "T_TERMS_L10C=- Em Ren'Py 7, se a descompilação Python 2 terminar parcialmente, o usuário"
set "T_TERMS_L10C_2=  pode reutilizar ou baixar a dependência Python 3 e tentar os arquivos restantes."
set "T_TERMS_L10B_3="
set "T_TERMS_L12=ARQUIVOS E DADOS QUE O SCRIPT ALTERA:"
set "T_TERMS_L13=A extração e a reinjeção trabalham em pastas de trabalho do projeto."
set "T_TERMS_L13_2=  O Build e o port mobile modificam temporariamente o game\options.rpy"
set "T_TERMS_L13_3=  após criar um backup e procuram restaurar o arquivo original ao"
set "T_TERMS_L13_4=  final."
set "T_TERMS_L14=O script também cria arquivos temporários, backups e logs durante o"
set "T_TERMS_L14_2=  processamento; arquivos temporários usados internamente são limpos"
set "T_TERMS_L14_3=  quando as etapas terminam."
set "T_TERMS_L15=A reinjeção trabalha nas pastas de trabalho criadas pelo próprio"
set "T_TERMS_L15_2=  UnRen-DDAC e não deve sobrescrever o mod original baixado pelo"
set "T_TERMS_L15_3=  usuário."
set "T_TERMS_L17=DEPENDÊNCIAS BAIXADAS E FONTES OFICIAIS:"
set "T_TERMS_L18=- SDK oficial do Ren'Py, baixado de renpy.org"
set "T_TERMS_L19=- RAPT oficial para Android, baixado de renpy.org"
set "T_TERMS_L20=- JDK Eclipse Temurin, fornecido pelo projeto Eclipse Adoptium"
set "T_TERMS_L20_2="
set "T_TERMS_L20B=- Python 3.13.15 embutível, baixado de python.org e usado localmente"
set "T_TERMS_L22=ONDE AS DEPENDÊNCIAS FICAM:"
set "T_TERMS_L23=SDK, RAPT, JDK e outros arquivos auxiliares de dependências ficam no"
set "T_TERMS_L23_2=  cache compartilhado em %SDKROOT%. O RAPT pode baixar componentes do"
set "T_TERMS_L23_3=  Android SDK necessários ao port."
set "T_TERMS_L24=O runtime Python do UnRen-DDAC fica no cache compartilhado DDAC, dentro de"
set "T_TERMS_L24_2=  DDAC-Dependência. O runtime é baixado uma vez e reutilizado entre mods e idiomas."
set "T_TERMS_L24_3=  Ele não substitui o Python incluído no SDK Ren'Py selecionado."
set "T_TERMS_L24_4=  O runtime do DDAC não é instalado como programa do Windows."
set "T_TERMS_L24_5=  Os SDKs do Ren'Py ficam em subpastas versionadas do mesmo cache DDAC."
set "T_TERMS_L24_6=  A reutilização verifica a existência de um Python válido antes do uso."
set "T_TERMS_L24_7="
set "T_TERMS_L26=CONEXÕES DE REDE E PRIVACIDADE:"
set "T_TERMS_L27=O script usa a internet para baixar dependências oficiais e"
set "T_TERMS_L27_2=  verificar hashes. Os downloads são obtidos por HTTPS das fontes"
set "T_TERMS_L27_3=  configuradas no script; não há rotina do DDAC para enviar os"
set "T_TERMS_L27_4=  arquivos do projeto a um servidor."
set "T_TERMS_L31B=As pastas de projeto criadas pelo DDAC e os nomes dos arquivos de"
set "T_TERMS_L31B_2=  texto/log destinados ao usuário seguem o idioma selecionado."
set "T_TERMS_L31B_3=  Identificadores técnicos de cache/dependências, como DDAC-SDK e"
set "T_TERMS_L31B_4=  DDAC-SDK-Mobile, permanecem estáveis para reutilizar o mesmo cache"
set "T_TERMS_L31B_5=  entre idiomas."
set "T_TERMS_L27B=As mensagens produzidas pelo próprio DDAC nos logs seguem o idioma"
set "T_TERMS_L27B_2=  selecionado. Saídas brutas de ferramentas externas podem permanecer"
set "T_TERMS_L27B_3=  no idioma original da ferramenta."
set "T_TERMS_L29=GERENCIADOR DE ARMAZENAMENTO:"
set "T_TERMS_L30=A Opção 5 mostra o armazenamento controlado pelo UnRen-DDAC e seus"
set "T_TERMS_L30_2=  tamanhos reais."
set "T_TERMS_L31=A Opção 5 não remove dependências automaticamente; ela mostra o"
set "T_TERMS_L31_2=  local exato para que o usuário possa removê-las manualmente pelo"
set "T_TERMS_L31_3=  Explorer."
set "T_TERMS_L32=Diretórios técnicos internos e temporários, quando necessários à"
set "T_TERMS_L32_2=  execução, podem manter nomes técnicos fixos e não representam pastas"
set "T_TERMS_L32_3=  de saída do projeto."
set "T_TERMS_L32B=Arquivos oficiais baixados de terceiros mantêm seus nomes oficiais."
set "T_TERMS_L32B_2=  Backups, marcadores e arquivos técnicos de apoio, como"
set "T_TERMS_L32B_3=  options.rpy.ddacbak, .termos_aceitos_v3, rpatool.py e arquivos do"
set "T_TERMS_L32B_4=  unrpyc, mantêm nomes fixos quando esses nomes são exigidos pelo"
set "T_TERMS_L32B_5=  funcionamento interno das ferramentas. O nome do mapa JSON dos Diálogos"
set "T_TERMS_L32B_6=  permanece com nome técnico fixo; os arquivos de texto/log seguem o idioma."
set "T_TERMS_L32B_7="
set "T_TERMS_L33=AGRADECIMENTOS E CRÉDITOS:"
set "T_TERMS_L34=- Ren'Py, seus SDKs e RAPT oficiais: renpy.org"
set "T_TERMS_L34B=- Componentes do Android SDK utilizados pelo RAPT, conforme a"
set "T_TERMS_L34B_2=  documentação oficial do Android."
set "T_TERMS_L35=- Eclipse Adoptium e Eclipse Temurin para o JDK usado nos ports"
set "T_TERMS_L35_2=  Android."
set "T_TERMS_L36=- Python Software Foundation pelo Python embutível utilizado pelas"
set "T_TERMS_L36_2=  ferramentas."
set "T_TERMS_L37=- unrpyc, de CensoredUsername, usado para descompilar arquivos"
set "T_TERMS_L37_2=  .rpyc."
set "T_TERMS_L38=- rpatool, de Shizmob, usado para trabalhar com arquivos .rpa."
set "T_TERMS_L39=- DDLC Base e Team Salvato, como referência do projeto original"
set "T_TERMS_L39_2=  DDLC."
set "T_TERMS_L40=- DDLC Mod Template 2.0, de Bronya-Rand, como inspiração para"
set "T_TERMS_L40_2=  organização."
set "T_TERMS_L41=Nenhum arquivo ou código dessas referências é declarado como código"
set "T_TERMS_L41_2=  próprio."
set "T_TERMS_L42=As licenças e os termos originais de cada projeto continuam"
set "T_TERMS_L42_2=  aplicáveis."
set "T_TERMS_L43=FONTES E LICENÇAS:"
set "T_TERMS_L44=Ren'Py: renpy.org/doc/html/license.html"
set "T_TERMS_L45=unrpyc: github.com/CensoredUsername/unrpyc"
set "T_TERMS_L46=rpatool: codeberg.org/shiz/rpatool"
set "T_TERMS_L47=DDLC Mod Template 2.0: github.com/Bronya-Rand/DDLCModTemplate2.0"
set "T_TERMS_L48=Python: python.org; Adoptium: adoptium.net"
set "T_TERMS_L48B=Android Developers: developer.android.com (documentação oficial do"
set "T_TERMS_L48B_2=  Android)"
set "T_TERMS_L49=DDLC Base: ddlc.moe"
set "T_TERMS_CHOOSE=Deseja continuar?"
set "T_TERMS_ACCEPT=1) Aceitar e continuar"
set "T_TERMS_DECLINE=2) Recusar e sair"
set "T_TERMS_INVALID=Opção inválida. Escolha 1 ou 2."
set "T_RUNTIME_FOLDER=DDAC-Dependência"
set "T_LOG_DIALOGOS_FILE=UnRen-DDAC-Extração-de-Diálogos.txt"
set "T_TMP_DIALOGOS_RUNTIME_TEST_FILE=ddac-diálogos-teste-dependência.txt"
set "T_L_DIALOG_ERR=ERRO: a rotina de diálogos terminou com código"
goto terms_gate
:lang_en
set "txt_tag_erro=ERROR"
set "T_TITLE=UnRen-DDAC - by Pedro"
set "T_SUPPORT=Ren'Py 6 / 7 / 8"
set "T_DISCLAIMER=Unofficial fan creation, with no affiliation with Team Salvato."
set "T_CHOOSE=Choose an option:"
set "T_DIALOGOS=Dialogue extraction - translation - merge"
set "T_DIALOGOS_DESC=Extracts, translates with Google Translate, and reinjects the mod's translatable text"
set "T_DLG_EXTRACT=Extract the mod dialogue for translation"
set "T_DLG_EXTRACT_DET=from the game folder into the DDAC-Extracted-Dialogues folder"
set "T_DLG_TRANSLATE=Translate the dialogues with Google Translate"
set "T_DLG_TRANSLATE_DET=from the DDAC-Extracted-Dialogues folder into the DDAC-Translated-Dialogues folder"
set "T_DLG_REINJECT=Reinject the translation into the mod"
set "T_DLG_REINJECT_DET=from DDAC-Translated-Dialogues or DDAC-Extracted-Dialogues into DDAC-Merged-Dialogues"
set "T_DLG_DIAG=Diagnose the Google Translate connection"
set "T_DLG_DIAG_DET=measures the Google page and the real translation endpoint before changing the engine"
set "T_PATCH=Ren'Py PT-BR interface patch"
set "T_PATCH_DESC=automatically creates the complete internal interface file inside the project game folder"
set "T_PATCH_EXIST=The patch already exists in this game and will be updated."
set "T_PATCH_OK=PT-BR interface patch created successfully:"
set "T_PATCH_NOGAME=The game folder was not found next to this file."
set "T_PATCH_ERR=Could not prepare the patch file."
set "T_PATCH_PRIORITY1=This file has priority over the game translation for the interface options it forces."
set "T_PATCH_PRIORITY2=Example: if the game translates Preferences as Preferences, the patch forces Configurations."
set "T_PATCH_PRIORITY3=The original game translation is not deleted or modified."
set "T_PATCH_PRESS=Press ENTER to exit:"
set "T_DLG_START_DIAG=[START] Diagnosing Google Translate..."
set "T_DLG_START_EXTRACT=[START] Extracting the translatable dialogue from the mod/game..."
set "T_DLG_PREFLIGHT_TITLE=PREFLIGHT CHECK"
set "T_DLG_PREFLIGHT_READONLY=Read-only check. No game file will be modified here."
set "T_DLG_PREFLIGHT_CONTINUE=Preflight completed. Starting the step..."
set "T_DLG_START_TRANSLATE=[START] Translating the dialogues with Google Translate..."
set "T_DLG_START_REINJECT=[START] Reinjecting the translation into the mod files..."
set "T_DLG_LOG_TITLE=GAME LOG REQUIRED FOR EXTRACTION"
set "T_DLG_LOG_MISSING=The log.txt for this game/mod was not generated or could not be found."
set "T_DLG_LOG_MISSING_2=To identify the exact RenPy version safely, DDAC requires this log."
set "T_DLG_LOG_ACTION=Exit DDAC, run the game/mod once, close the game, and run Option 1 again."
set "T_DLG_LOG_VERSION=RenPy version obtained from the log:"
set "T_DLG_LOG_PATH=Log path used:"
set "T_DLG_ERR_MARK=Internal error: the embedded Python code could not be found in this file."
set "T_DLG_ERR_MARK2=The .bat may be corrupted or was edited incorrectly."
set "T_DLG_DEP_L1=This Dialogue tool uses its own independent Python,"
set "T_DLG_DEP_L2=which works with any mod (Python 2, 3.6, 3.7, 3.8...) without relying on the Python bundled inside the game."
set "T_DLG_ERR_DEP=Could not prepare the dependency required for the Dialogue tool."
set "T_DLG_ERR_DEP2=Try again, or download it manually from the official page shown above."
set "T_DLG_DEP_TITLE=REQUIRED DEPENDENCY"
set "T_DLG_DEP_CANDOWNLOAD=UnRen-DDAC can automatically download Python 3.13.15"
set "T_DLG_DEP_EMBED=embeddable, used only by the DDAC Dialogue engine (not by the RenPy SDK)."
set "T_DLG_DEP_NOTINSTALLED=It will NOT be installed on Windows and will NOT modify the PC's Python."
set "T_DLG_SDK_TITLE=REQUIRED REN'PY DEPENDENCY"
set "T_DLG_SDK_TITLE_CENTER=                 REQUIRED REN'PY DEPENDENCY"
set "T_DLG_SDK_L1=The Python 3 above is the DDAC runtime. Full extraction also uses the official Ren'Py SDK"
set "T_DLG_SDK_L2=that matches the mod/game, using the Python bundled inside that SDK."
set "T_DLG_SDK_DETECTED=Detected Ren'Py version:"
set "T_DLG_SDK_SELECTED=Selected Ren'Py SDK:"
set "T_DLG_ALL_READY_RUNTIME=DDAC Python 3 ready:"
set "T_DLG_ALL_READY_SDK=Ren'Py SDK ready:"
set "T_DLG_SDK_CACHE=Cache path:"
set "T_DLG_SDK_SOURCE=Official source:"
set "T_DLG_SDK_DOWNLOAD=2) Automatically download the official SDK now  (RECOMMENDED)"
set "T_DLG_SDK_OPENPAGE=1) Open the official page in the browser"
set "T_DLG_SDK_CANCEL=3) Cancel"
set "T_DLG_SDK_READY_TITLE=ALL DEPENDENCIES PREPARED SUCCESSFULLY"
set "T_DLG_SDK_READY_L1=Python 3 and the compatible Ren'Py SDK were prepared and verified by UnRen-DDAC."
set "T_DLG_SDK_READY_L2=Both dependencies are ready. Extraction starts only after choosing 1."
set "T_DLG_SDK_CONTINUE=1) Continue with the extraction now"
set "T_DLG_SDK_BACK=2) Return to the main menu"
set "T_DLG_SDK_EXACT=The script will not silently switch SDK versions when an exact version was detected."
set "T_DLG_SDK_DOWNLOADING=Downloading the official Ren'Py SDK..."
set "T_DLG_SDK_EXTRACTING=Extracting the SDK into the shared cache..."
set "T_DLG_SDK_FAIL=Could not prepare the Ren'Py SDK required by Option 1."
set "T_DLG_DEP_SOURCE=Official source:"
set "T_DLG_DEP_PAGE=Official page:"
set "T_DLG_DEP_OPENPAGE=1) Open the official page in the browser"
set "T_DLG_DEP_DOWNLOAD=2) Automatically download from the official source now  (RECOMMENDED)"
set "T_DLG_DEP_CANCEL=3) Cancel"
set "T_DLG_DEP_PAGEOPENED=Official page opened in the browser."
set "T_DLG_DEP_RUNAGAIN=Then run UnRen-DDAC again."
set "T_DLG_DEP_ERR_RESULT=! Error: the download returned no result."
set "T_DLG_DEP_ERR_DOWNLOAD=! Error during download:"
set "T_DLG_DEP_ERR_SIZE=! Error: the received size does not match the expected official package."
set "T_DLG_DEP_EXPECTED=Expected:"
set "T_DLG_DEP_RECEIVED=Received:"
set "T_DLG_DEP_BYTES=bytes"
set "T_DLG_DEP_ERR_INTEGRITY=! INTEGRITY ERROR: the received SHA-256 does not match the official value."
set "T_DLG_DEP_DISCARDED=The downloaded file was discarded."
set "T_DLG_DEP_ERR_FINALIZE=! Error finishing the download."
set "T_DLG_DEP_ERR_EXTRACT=! Error extracting the downloaded package."
set "T_DLG_DEP_ERR_NOPYTHON=! Error: the package was downloaded, but python.exe was not found."
set "T_DLG_DEP_ERR_START=! Error: could not start the downloaded runtime."
set "T_DLG_DEP_READY_TITLE=DEPENDENCY PREPARED SUCCESSFULLY"
set "T_DLG_DEP_READY_L1=The dependency required for the Dialogue tool has been downloaded"
set "T_DLG_DEP_READY_L2=and properly verified by UnRen-DDAC."
set "T_DLG_DEP_CONTINUE=1) Continue with the Dialogue tool now"
set "T_DLG_DEP_BACK=2) Return to the main menu"
set "T_DLG_DEP_INVALID12=Invalid option. Choose 1 or 2."
set "T_EXIT=Exit"
set "T_OPTION=Option:"
set "T_INVALID=Invalid option."
set "T_DLG_ERR_EXEC_HINT=See the output above and the log for details."
set "T_EXIT=Exit"
set "T_OPTION=Option:"
set "T_INVALID=Invalid option."
set "T_TERMS_TITLE=TERMS OF USE"
set "T_TERMS_L01=UnRen-DDAC - by Pedro"
set "T_TERMS_L03=Fan-made application, with no official affiliation with Team Salvato"
set "T_TERMS_L04=or the Ren'Py project."
set "T_TERMS_L06=ABOUT THIS SCRIPT:"
set "T_TERMS_L07=- Extracts .rpa files and decompiles .rpyc files from Ren'Py"
set "T_TERMS_L07_2=  projects"
set "T_TERMS_L08=- Extracts translatable dialogue and reinjects the translation"
set "T_TERMS_L09=- Builds the final mod distribution using the Ren'Py SDK"
set "T_TERMS_L10=- Can generate Android ports using the official Ren'Py RAPT and"
set "T_TERMS_L10_2=  always outputs an APK in this version of the script"
set "T_TERMS_L10B=- For Ren'Py 6 projects, a newer compatible engine is used only"
set "T_TERMS_L10B_2=  during the mobile-port step; the original project is not migrated."
set "T_TERMS_L10C=- On Ren'Py 7, if the Python 2 decompilation finishes partially, the user"
set "T_TERMS_L10C_2=  can reuse or download the Python 3 dependency and retry the remaining files."
set "T_TERMS_L10B_3="
set "T_TERMS_L12=FILES AND DATA THE SCRIPT CHANGES:"
set "T_TERMS_L13=Extraction and reinjection use project work folders. Build and"
set "T_TERMS_L13_2=  mobile port temporarily modify game\options.rpy after creating a"
set "T_TERMS_L13_3=  backup and attempt to restore the original file at the end."
set "T_TERMS_L13_4="
set "T_TERMS_L14=The script also creates temporary files, backups, and logs during"
set "T_TERMS_L14_2=  processing; temporary internal files are cleaned when the steps"
set "T_TERMS_L14_3=  finish."
set "T_TERMS_L15=Reinjection works on work folders created by UnRen-DDAC itself and"
set "T_TERMS_L15_2=  is not intended to overwrite the original mod downloaded by the"
set "T_TERMS_L15_3=  user."
set "T_TERMS_L17=DOWNLOADED DEPENDENCIES AND OFFICIAL SOURCES:"
set "T_TERMS_L18=- Official Ren'Py SDK, downloaded from renpy.org"
set "T_TERMS_L19=- Official Android RAPT, downloaded from renpy.org"
set "T_TERMS_L20=- Eclipse Temurin JDK, provided by the Eclipse Adoptium project"
set "T_TERMS_L20_2="
set "T_TERMS_L20B=- Python 3.13.15 embeddable package, downloaded from python.org"
set "T_TERMS_L22=WHERE DEPENDENCIES ARE STORED:"
set "T_TERMS_L23=SDK, RAPT, JDK, and other dependency helper files are stored in the"
set "T_TERMS_L23_2=  shared cache at %SDKROOT%. RAPT may download Android SDK components"
set "T_TERMS_L23_3=  required for the mobile port."
set "T_TERMS_L24=The UnRen-DDAC Python runtime is stored in the shared DDAC cache, inside"
set "T_TERMS_L24_2=  DDAC-Dependency. The runtime is downloaded once and reused across mods and languages."
set "T_TERMS_L24_3=  It does not replace the Python bundled inside the selected Ren'Py SDK."
set "T_TERMS_L24_4=  The DDAC runtime is not installed as a Windows program."
set "T_TERMS_L24_5=  Ren'Py SDKs are stored as versioned folders in the same DDAC cache."
set "T_TERMS_L24_6=  Reuse checks for a valid Python executable before use."
set "T_TERMS_L24_7="
set "T_TERMS_L26=NETWORK CONNECTIONS AND PRIVACY:"
set "T_TERMS_L27=The script uses the internet to download official dependencies and"
set "T_TERMS_L27_2=  verify hashes. Downloads are obtained over HTTPS from the sources"
set "T_TERMS_L27_3=  configured in the script; DDAC has no routine that uploads project"
set "T_TERMS_L27_4=  files to a server."
set "T_TERMS_L27B=Messages produced by DDAC itself in logs follow the selected"
set "T_TERMS_L27B_2=  language. Raw output from external tools may remain in the tool's"
set "T_TERMS_L27B_3=  original language."
set "T_TERMS_L29=STORAGE MANAGER:"
set "T_TERMS_L30=Option 5 shows UnRen-DDAC controlled storage and its real sizes."
set "T_TERMS_L30_2="
set "T_TERMS_L31=Option 5 does not remove dependencies automatically; it shows the"
set "T_TERMS_L31_2=  exact location so the user can remove them manually through"
set "T_TERMS_L31_3=  Explorer."
set "T_TERMS_L31B=Project folders created by DDAC and user-facing text/log filenames"
set "T_TERMS_L31B_2=  follow the selected language. Technical cache/dependency identifiers"
set "T_TERMS_L31B_3=  such as DDAC remain stable inside the same shared cache"
set "T_TERMS_L31B_4=  can be reused across languages."
set "T_TERMS_L31B_5="
set "T_TERMS_L32=Internal technical and temporary directories, when needed for"
set "T_TERMS_L32_2=  execution, may keep fixed technical names and are not project output"
set "T_TERMS_L32_3=  folders."
set "T_TERMS_L32B=Official files downloaded from third parties keep their official"
set "T_TERMS_L32B_2=  names. Technical backups, markers, and tool-support files, such as"
set "T_TERMS_L32B_3=  options.rpy.ddacbak, .termos_aceitos_v3, rpatool.py, and unrpyc"
set "T_TERMS_L32B_4=  files, keep fixed names when those names are required for internal"
set "T_TERMS_L32B_5=  tool operation. The Dialogue JSON map name stays technical and fixed;"
set "T_TERMS_L32B_6=  text/log files created by DDAC follow the selected language."
set "T_TERMS_L32B_7="
set "T_TERMS_L33=ACKNOWLEDGEMENTS AND CREDITS:"
set "T_TERMS_L34=- Ren'Py and its official SDKs and RAPT: renpy.org"
set "T_TERMS_L34B=- Android SDK components used by RAPT, according to official Android"
set "T_TERMS_L34B_2=  documentation."
set "T_TERMS_L35=- Eclipse Adoptium and Eclipse Temurin for the JDK used by Android"
set "T_TERMS_L35_2=  ports."
set "T_TERMS_L36=- Python Software Foundation for the embeddable Python used by the"
set "T_TERMS_L36_2=  tools."
set "T_TERMS_L37=- unrpyc, by CensoredUsername, used to decompile .rpyc files."
set "T_TERMS_L37_2="
set "T_TERMS_L38=- rpatool, by Shizmob, used to work with .rpa archives."
set "T_TERMS_L39=- DDLC Base and Team Salvato, as references to the original DDLC"
set "T_TERMS_L39_2=  project."
set "T_TERMS_L40=- DDLC Mod Template 2.0, by Bronya-Rand, as an organizational"
set "T_TERMS_L40_2=  reference."
set "T_TERMS_L41=No file or code from these references is claimed as original"
set "T_TERMS_L41_2=  UnRen-DDAC code."
set "T_TERMS_L42=The original licenses and terms of each project continue to apply."
set "T_TERMS_L42_2="
set "T_TERMS_L43=SOURCES AND LICENSES:"
set "T_TERMS_L44=Ren'Py: renpy.org/doc/html/license.html"
set "T_TERMS_L45=unrpyc: github.com/CensoredUsername/unrpyc"
set "T_TERMS_L46=rpatool: codeberg.org/shiz/rpatool"
set "T_TERMS_L47=DDLC Mod Template 2.0: github.com/Bronya-Rand/DDLCModTemplate2.0"
set "T_TERMS_L48=Python: python.org; Adoptium: adoptium.net"
set "T_TERMS_L48B=Android Developers: developer.android.com"
set "T_TERMS_L48B_2="
set "T_TERMS_L49=DDLC Base: ddlc.moe"
set "T_TERMS_CHOOSE=Do you want to continue?"
set "T_TERMS_ACCEPT=1) Accept and continue"
set "T_TERMS_DECLINE=2) Decline and exit"
set "T_TERMS_INVALID=Invalid option. Choose 1 or 2."
set "T_RUNTIME_FOLDER=DDAC-Dependency"
set "T_LOG_DIALOGOS_FILE=UnRen-DDAC-Dialogue-Extraction.txt"
set "T_TMP_DIALOGOS_RUNTIME_TEST_FILE=ddac-dialogue-dependency-test.txt"
set "T_L_DIALOG_ERR=ERROR: dialogue routine ended with code"
goto terms_gate
:lang_es
set "txt_tag_erro=ERROR"
set "T_TITLE=UnRen-DDAC - by Pedro"
set "T_SUPPORT=Ren'Py 6 / 7 / 8"
set "T_DISCLAIMER=Creación de fan no oficial, sin vínculo con Team Salvato."
set "T_CHOOSE=Elige una opción:"
set "T_DIALOGOS=Extracción - traducción - mezcla de diálogos traducibles"
set "T_DIALOGOS_DESC=Extrae, traduce con Google Translate y reinyecta el texto traducible del mod"
set "T_DLG_EXTRACT=Extraer los diálogos del mod para traducir"
set "T_DLG_EXTRACT_DET=de la carpeta game a la carpeta DDAC-Diálogos-Extraídos"
set "T_DLG_TRANSLATE=Traducir los diálogos con Google Translate"
set "T_DLG_TRANSLATE_DET=de la carpeta DDAC-Diálogos-Extraídos a la carpeta DDAC-Diálogos-Traducidos"
set "T_DLG_REINJECT=Reinyectar la traducción en el mod"
set "T_DLG_REINJECT_DET=de DDAC-Diálogos-Traducidos o DDAC-Diálogos-Extraídos a DDAC-Diálogos-Mezclados"
set "T_DLG_DIAG=Diagnosticar la conexión con Google Translate"
set "T_DLG_DIAG_DET=mide la página de Google y el endpoint real de traducción antes de cambiar el motor"
set "T_PATCH=Parche de interfaz PT-BR de Ren'Py"
set "T_PATCH_DESC=crea automáticamente el archivo completo de la interfaz interna dentro de la carpeta game del proyecto"
set "T_PATCH_EXIST=El parche ya existe en este juego y se actualizará."
set "T_PATCH_OK=Parche de interfaz PT-BR creado correctamente:"
set "T_PATCH_NOGAME=No se encontró la carpeta game junto a este archivo."
set "T_PATCH_ERR=No fue posible preparar el archivo del parche."
set "T_PATCH_PRIORITY1=Este archivo tiene prioridad sobre la traducción del juego en las opciones de interfaz que fuerza."
set "T_PATCH_PRIORITY2=Ejemplo: si el juego traduce Preferences como Preferencias, el parche fuerza Configuración."
set "T_PATCH_PRIORITY3=La traducción original del juego no se elimina ni se modifica."
set "T_PATCH_PRESS=Presiona ENTER para salir:"
set "T_DLG_START_DIAG=[INICIO] Diagnóstico de Google Translate..."
set "T_DLG_START_EXTRACT=[INICIO] Extrayendo los diálogos traducibles del mod/juego..."
set "T_DLG_PREFLIGHT_TITLE=VERIFICACIÓN PREVIA"
set "T_DLG_PREFLIGHT_READONLY=Comprobación de solo lectura. No se modificará ningún archivo del juego aquí."
set "T_DLG_PREFLIGHT_CONTINUE=Preverificación completada. Iniciando la etapa..."
set "T_DLG_START_TRANSLATE=[INICIO] Traduciendo los diálogos con Google Translate..."
set "T_DLG_START_REINJECT=[INICIO] Reinyectando la traducción en los archivos del mod/juego..."
set "T_DLG_LOG_TITLE=SE NECESITA EL LOG DEL JUEGO PARA LA EXTRACCIÓN"
set "T_DLG_LOG_MISSING=No se generó o no se encontró el log.txt de este juego/mod."
set "T_DLG_LOG_MISSING_2=Para identificar con seguridad la versión exacta de RenPy, DDAC necesita este log."
set "T_DLG_LOG_ACTION=Sal del DDAC, ejecuta el juego/mod una vez, ciérralo y vuelve a ejecutar la Opción 1."
set "T_DLG_LOG_VERSION=Versión de RenPy obtenida del log:"
set "T_DLG_LOG_PATH=Ruta del log utilizada:"
set "T_DLG_ERR_MARK=Error interno: no fue posible localizar el código Python incrustado en este archivo."
set "T_DLG_ERR_MARK2=El .bat puede estar corrupto o fue editado incorrectamente."
set "T_DLG_DEP_L1=Esta herramienta de Diálogos usa un Python propio e independiente,"
set "T_DLG_DEP_L2=que funciona con cualquier mod (Python 2, 3.6, 3.7, 3.8...) sin depender del Python incluido en el juego."
set "T_DLG_ERR_DEP=No se pudo preparar la dependencia necesaria para los Diálogos."
set "T_DLG_ERR_DEP2=Intenta de nuevo, o descárgala manualmente desde la página oficial mostrada arriba."
set "T_DLG_DEP_TITLE=DEPENDENCIA NECESARIA"
set "T_DLG_DEP_CANDOWNLOAD=UnRen-DDAC puede descargar automáticamente Python 3.13.15"
set "T_DLG_DEP_EMBED=embebible, que se usará únicamente con la herramienta de Diálogos."
set "T_DLG_DEP_NOTINSTALLED=NO se instalará en Windows ni modificará el Python del PC."
set "T_DLG_SDK_TITLE=DEPENDENCIA DE REN'PY NECESARIA"
set "T_DLG_SDK_TITLE_CENTER=              DEPENDENCIA DE REN'PY NECESARIA"
set "T_DLG_SDK_L1=El Python 3 anterior es el runtime de DDAC. La extracción completa también usa el SDK oficial de Ren'Py"
set "T_DLG_SDK_L2=compatible con el mod/juego, usando el Python incluido dentro de ese SDK."
set "T_DLG_SDK_DETECTED=Versión de Ren'Py detectada:"
set "T_DLG_SDK_SELECTED=SDK de Ren'Py seleccionado:"
set "T_DLG_ALL_READY_RUNTIME=Python 3 de DDAC listo:"
set "T_DLG_ALL_READY_SDK=SDK de Ren'Py listo:"
set "T_DLG_SDK_CACHE=Ruta de caché:"
set "T_DLG_SDK_SOURCE=Fuente oficial:"
set "T_DLG_SDK_DOWNLOAD=2) Descargar automáticamente el SDK oficial ahora  (RECOMENDADO)"
set "T_DLG_SDK_OPENPAGE=1) Abrir la página oficial en el navegador"
set "T_DLG_SDK_CANCEL=3) Cancelar"
set "T_DLG_SDK_READY_TITLE=TODAS LAS DEPENDENCIAS PREPARADAS CORRECTAMENTE"
set "T_DLG_SDK_READY_L1=Python 3 y el SDK de Ren'Py compatible fueron preparados y verificados por UnRen-DDAC."
set "T_DLG_SDK_READY_L2=Ambas dependencias están listas. La extracción comienza solo después de elegir 1."
set "T_DLG_SDK_CONTINUE=1) Continuar con la extracción ahora"
set "T_DLG_SDK_BACK=2) Volver al menú principal"
set "T_DLG_SDK_EXACT=El script no cambiará silenciosamente a otro SDK cuando se haya detectado una versión exacta."
set "T_DLG_SDK_DOWNLOADING=Descargando el SDK oficial de Ren'Py..."
set "T_DLG_SDK_EXTRACTING=Extrayendo el SDK en la caché compartida..."
set "T_DLG_SDK_FAIL=No se pudo preparar el SDK de Ren'Py necesario para la Opción 1."
set "T_DLG_DEP_SOURCE=Fuente oficial:"
set "T_DLG_DEP_PAGE=Página oficial:"
set "T_DLG_DEP_OPENPAGE=1) Abrir la página oficial en el navegador"
set "T_DLG_DEP_DOWNLOAD=2) Descargar automáticamente desde la fuente oficial ahora  (RECOMENDADO)"
set "T_DLG_DEP_CANCEL=3) Cancelar"
set "T_DLG_DEP_PAGEOPENED=Página oficial abierta en el navegador."
set "T_DLG_DEP_RUNAGAIN=Después ejecuta UnRen-DDAC nuevamente."
set "T_DLG_DEP_ERR_RESULT=! Error: la descarga no devolvió ningún resultado."
set "T_DLG_DEP_ERR_DOWNLOAD=! Error durante la descarga:"
set "T_DLG_DEP_ERR_SIZE=! Error: el tamaño recibido no coincide con el paquete oficial esperado."
set "T_DLG_DEP_EXPECTED=Esperado:"
set "T_DLG_DEP_RECEIVED=Recibido:"
set "T_DLG_DEP_BYTES=bytes"
set "T_DLG_DEP_ERR_INTEGRITY=! ERROR DE INTEGRIDAD: el SHA-256 recibido no coincide con el oficial."
set "T_DLG_DEP_DISCARDED=El archivo descargado fue descartado."
set "T_DLG_DEP_ERR_FINALIZE=! Error al finalizar la descarga."
set "T_DLG_DEP_ERR_EXTRACT=! Error al extraer el paquete descargado."
set "T_DLG_DEP_ERR_NOPYTHON=! Error: se descargó el paquete, pero no se encontró python.exe."
set "T_DLG_DEP_ERR_START=! Error: no se pudo iniciar el runtime descargado."
set "T_DLG_DEP_READY_TITLE=DEPENDENCIA PREPARADA CORRECTAMENTE"
set "T_DLG_DEP_READY_L1=La dependencia necesaria para los Diálogos se descargó y"
set "T_DLG_DEP_READY_L2=verificó correctamente mediante UnRen-DDAC."
set "T_DLG_DEP_CONTINUE=1) Continuar con los Diálogos ahora"
set "T_DLG_DEP_BACK=2) Volver al menú principal"
set "T_DLG_DEP_INVALID12=Opción no válida. Elige 1 o 2."
set "T_EXIT=Salir"
set "T_OPTION=Opción:"
set "T_INVALID=Opción no válida."
set "T_DLG_ERR_EXEC_HINT=Consulta la salida anterior y el log para obtener más detalles."
set "T_EXIT=Salir"
set "T_OPTION=Opción:"
set "T_INVALID=Opción no válida."
set "T_TERMS_TITLE=TÉRMINOS DE USO"
set "T_TERMS_L01=UnRen-DDAC - by Pedro"
set "T_TERMS_L03=Aplicación fan-made, sin vínculo oficial con Team Salvato"
set "T_TERMS_L04=ni con el proyecto Ren'Py."
set "T_TERMS_L06=SOBRE ESTE SCRIPT:"
set "T_TERMS_L07=- Extrae archivos .rpa y descompila archivos .rpyc de proyectos"
set "T_TERMS_L07_2=  Ren'Py"
set "T_TERMS_L08=- Extrae diálogos traducibles y reinserta la traducción"
set "T_TERMS_L09=- Genera la distribución final del mod usando el SDK de Ren'Py"
set "T_TERMS_L10=- Puede generar ports Android usando el RAPT oficial de Ren'Py y"
set "T_TERMS_L10_2=  siempre genera un APK en esta versión del script"
set "T_TERMS_L10B=- En proyectos Ren'Py 6, se usa un motor compatible más nuevo"
set "T_TERMS_L10B_2=  solamente durante la etapa del port móvil; el proyecto original no"
set "T_TERMS_L10C=- En Ren'Py 7, si la descompilación con Python 2 termina parcialmente, el usuario"
set "T_TERMS_L10C_2=  puede reutilizar o descargar la dependencia Python 3 e intentar los archivos restantes."
set "T_TERMS_L10B_3=  se migra."
set "T_TERMS_L12=ARCHIVOS Y DATOS QUE MODIFICA EL SCRIPT:"
set "T_TERMS_L13=La extracción y la reinserción usan carpetas de trabajo del"
set "T_TERMS_L13_2=  proyecto. El Build y el port móvil modifican temporalmente"
set "T_TERMS_L13_3=  game\options.rpy después de crear una copia de seguridad e intentan"
set "T_TERMS_L13_4=  restaurar el archivo original al final."
set "T_TERMS_L14=El script también crea archivos temporales, copias de seguridad y"
set "T_TERMS_L14_2=  registros durante el procesamiento; los archivos temporales internos"
set "T_TERMS_L14_3=  se limpian al terminar los pasos."
set "T_TERMS_L15=La reinserción trabaja en carpetas de trabajo creadas por el propio"
set "T_TERMS_L15_2=  UnRen-DDAC y no está destinada a sobrescribir el mod original"
set "T_TERMS_L15_3=  descargado por el usuario."
set "T_TERMS_L17=DEPENDENCIAS DESCARGADAS Y FUENTES OFICIALES:"
set "T_TERMS_L18=- SDK oficial de Ren'Py, descargado de renpy.org"
set "T_TERMS_L19=- RAPT oficial para Android, descargado de renpy.org"
set "T_TERMS_L20=- JDK Eclipse Temurin, proporcionado por el proyecto Eclipse"
set "T_TERMS_L20_2=  Adoptium"
set "T_TERMS_L20B=- Python 3.13.15 embebible, descargado de python.org"
set "T_TERMS_L22=DÓNDE SE GUARDAN LAS DEPENDENCIAS:"
set "T_TERMS_L23=SDK, RAPT, JDK y otros archivos auxiliares de dependencias se"
set "T_TERMS_L23_2=  guardan en la caché compartida de %SDKROOT%. RAPT puede descargar"
set "T_TERMS_L23_3=  componentes del Android SDK necesarios para el port móvil."
set "T_TERMS_L24=El runtime de Python de UnRen-DDAC se guarda en la caché compartida DDAC, dentro de"
set "T_TERMS_L24_2=  DDAC-Dependencia. Se descarga una vez y se reutiliza entre mods e idiomas."
set "T_TERMS_L24_3=  No sustituye el Python incluido en el SDK Ren'Py seleccionado."
set "T_TERMS_L24_4=  El runtime DDAC no se instala como programa de Windows."
set "T_TERMS_L24_5=  Los SDK de Ren'Py se guardan como carpetas versionadas en la misma caché DDAC."
set "T_TERMS_L24_6=  La reutilización comprueba que exista un Python válido antes de usar la caché."
set "T_TERMS_L24_7="
set "T_TERMS_L26=CONEXIONES DE RED Y PRIVACIDAD:"
set "T_TERMS_L27=El script usa internet para descargar dependencias oficiales y"
set "T_TERMS_L27_2=  verificar hashes. Las descargas se obtienen mediante HTTPS desde las"
set "T_TERMS_L27_3=  fuentes configuradas en el script; DDAC no tiene una rutina para"
set "T_TERMS_L27_4=  enviar los archivos del proyecto a un servidor."
set "T_TERMS_L31B=Las carpetas del proyecto creadas por DDAC y los nombres de los"
set "T_TERMS_L31B_2=  archivos de texto/log destinados al usuario siguen el idioma"
set "T_TERMS_L31B_3=  seleccionado. Los identificadores técnicos de caché/dependencias,"
set "T_TERMS_L31B_4=  como DDAC, permanecen estables dentro de la misma caché compartida"
set "T_TERMS_L31B_5=  la misma caché entre idiomas."
set "T_TERMS_L27B=Los mensajes producidos por el propio DDAC en los logs siguen el"
set "T_TERMS_L27B_2=  idioma seleccionado. La salida bruta de herramientas externas puede"
set "T_TERMS_L27B_3=  permanecer en el idioma original de la herramienta."
set "T_TERMS_L29=GESTOR DE ALMACENAMIENTO:"
set "T_TERMS_L30=La Opción 5 muestra el almacenamiento controlado por UnRen-DDAC y"
set "T_TERMS_L30_2=  sus tamaños reales."
set "T_TERMS_L31=La Opción 5 no elimina dependencias automáticamente; muestra la"
set "T_TERMS_L31_2=  ubicación exacta para que el usuario pueda eliminarlas manualmente"
set "T_TERMS_L31_3=  mediante el Explorador."
set "T_TERMS_L32=Los directorios técnicos internos y temporales, cuando son"
set "T_TERMS_L32_2=  necesarios para la ejecución, pueden mantener nombres técnicos fijos"
set "T_TERMS_L32_3=  y no representan carpetas de salida del proyecto."
set "T_TERMS_L32B=Los archivos oficiales descargados de terceros mantienen sus nombres"
set "T_TERMS_L32B_2=  oficiales. Las copias de seguridad, los marcadores y los archivos"
set "T_TERMS_L32B_3=  técnicos de apoyo, como options.rpy.ddacbak, .termos_aceitos_v3,"
set "T_TERMS_L32B_4=  rpatool.py y los archivos de unrpyc, mantienen nombres fijos cuando"
set "T_TERMS_L32B_5=  esos nombres son necesarios para el funcionamiento interno de las"
set "T_TERMS_L32B_6=  herramientas. El nombre del mapa JSON de Diálogos permanece técnico"
set "T_TERMS_L32B_7=  y fijo; los textos/logs siguen el idioma."
set "T_TERMS_L33=AGRADECIMIENTOS Y CRÉDITOS:"
set "T_TERMS_L34=- Ren'Py, sus SDK y RAPT oficiales: renpy.org"
set "T_TERMS_L34B=- Componentes del Android SDK utilizados por RAPT, según la"
set "T_TERMS_L34B_2=  documentación oficial de Android."
set "T_TERMS_L35=- Eclipse Adoptium y Eclipse Temurin para el JDK usado por los ports"
set "T_TERMS_L35_2=  Android."
set "T_TERMS_L36=- Python Software Foundation por el Python embebible usado por las"
set "T_TERMS_L36_2=  herramientas."
set "T_TERMS_L37=- unrpyc, de CensoredUsername, usado para descompilar archivos"
set "T_TERMS_L37_2=  .rpyc."
set "T_TERMS_L38=- rpatool, de Shizmob, usado para trabajar con archivos .rpa."
set "T_TERMS_L39=- DDLC Base y Team Salvato, como referencias del proyecto original"
set "T_TERMS_L39_2=  DDLC."
set "T_TERMS_L40=- DDLC Mod Template 2.0, de Bronya-Rand, como referencia de"
set "T_TERMS_L40_2=  organización."
set "T_TERMS_L41=No se declara como propio ningún archivo o código de estas"
set "T_TERMS_L41_2=  referencias."
set "T_TERMS_L42=Las licencias y términos originales de cada proyecto continúan"
set "T_TERMS_L42_2=  aplicándose."
set "T_TERMS_L43=FUENTES Y LICENCIAS:"
set "T_TERMS_L44=Ren'Py: renpy.org/doc/html/license.html"
set "T_TERMS_L45=unrpyc: github.com/CensoredUsername/unrpyc"
set "T_TERMS_L46=rpatool: codeberg.org/shiz/rpatool"
set "T_TERMS_L47=DDLC Mod Template 2.0: github.com/Bronya-Rand/DDLCModTemplate2.0"
set "T_TERMS_L48=Python: python.org; Adoptium: adoptium.net"
set "T_TERMS_L48B=Android Developers: developer.android.com (documentación oficial de"
set "T_TERMS_L48B_2=  Android)"
set "T_TERMS_L49=DDLC Base: ddlc.moe"
set "T_TERMS_CHOOSE=¿Deseas continuar?"
set "T_TERMS_ACCEPT=1) Aceptar y continuar"
set "T_TERMS_DECLINE=2) Rechazar y salir"
set "T_TERMS_INVALID=Opción no válida. Elige 1 o 2."
set "T_RUNTIME_FOLDER=DDAC-Dependencia"
set "T_LOG_DIALOGOS_FILE=UnRen-DDAC-Extracción-de-Diálogos.txt"
set "T_TMP_DIALOGOS_RUNTIME_TEST_FILE=ddac-diálogos-prueba-dependencia.txt"
set "T_L_DIALOG_ERR=ERROR: la rutina de diálogos terminó con el código"
goto terms_gate
:initialize_localized_paths
set "LOG_DIALOGOS=%ROOT%\%T_LOG_DIALOGOS_FILE%"
set "LOG=%LOG_DIALOGOS%"
exit /b 0

:terms_gate
if exist "%SDKROOT%\.termos_aceitos_v3" goto main_menu
goto terms_screen

:terms_screen
cls
echo.
echo  ============================================================
echo   %T_TERMS_TITLE%
echo  ============================================================
echo.
echo   %T_TERMS_L01%
echo.
echo   %T_TERMS_L03%
echo   %T_TERMS_L04%
echo.
echo   %T_TERMS_L06%
echo   %T_TERMS_L07%
if defined T_TERMS_L07_2 echo   %T_TERMS_L07_2%
echo   %T_TERMS_L08%
echo   %T_TERMS_L09%
echo   %T_TERMS_L10%
if defined T_TERMS_L10_2 echo   %T_TERMS_L10_2%
echo   %T_TERMS_L10B%
if defined T_TERMS_L10B_2 echo   %T_TERMS_L10B_2%
if defined T_TERMS_L10C echo   %T_TERMS_L10C%
if defined T_TERMS_L10C_2 echo   %T_TERMS_L10C_2%
if defined T_TERMS_L10B_3 echo   %T_TERMS_L10B_3%
echo.
echo   %T_TERMS_L12%
echo   %T_TERMS_L13%
if defined T_TERMS_L13_2 echo   %T_TERMS_L13_2%
if defined T_TERMS_L13_3 echo   %T_TERMS_L13_3%
if defined T_TERMS_L13_4 echo   %T_TERMS_L13_4%
echo   %T_TERMS_L14%
if defined T_TERMS_L14_2 echo   %T_TERMS_L14_2%
if defined T_TERMS_L14_3 echo   %T_TERMS_L14_3%
echo   %T_TERMS_L15%
if defined T_TERMS_L15_2 echo   %T_TERMS_L15_2%
if defined T_TERMS_L15_3 echo   %T_TERMS_L15_3%
echo.
echo   %T_TERMS_L17%
echo   %T_TERMS_L18%
echo   %T_TERMS_L19%
echo   %T_TERMS_L20%
if defined T_TERMS_L20_2 echo   %T_TERMS_L20_2%
echo   %T_TERMS_L20B%
echo.
echo   %T_TERMS_L22%
echo   %T_TERMS_L23%
if defined T_TERMS_L23_2 echo   %T_TERMS_L23_2%
if defined T_TERMS_L23_3 echo   %T_TERMS_L23_3%
echo   %T_TERMS_L24%
if defined T_TERMS_L24_2 echo   %T_TERMS_L24_2%
if defined T_TERMS_L24_3 echo   %T_TERMS_L24_3%
if defined T_TERMS_L24_4 echo   %T_TERMS_L24_4%
if defined T_TERMS_L24_5 echo   %T_TERMS_L24_5%
if defined T_TERMS_L24_6 echo   %T_TERMS_L24_6%
if defined T_TERMS_L24_7 echo   %T_TERMS_L24_7%
echo.
echo   %T_TERMS_L26%
echo   %T_TERMS_L27%
if defined T_TERMS_L27_2 echo   %T_TERMS_L27_2%
if defined T_TERMS_L27_3 echo   %T_TERMS_L27_3%
if defined T_TERMS_L27_4 echo   %T_TERMS_L27_4%
echo   %T_TERMS_L27B%
if defined T_TERMS_L27B_2 echo   %T_TERMS_L27B_2%
if defined T_TERMS_L27B_3 echo   %T_TERMS_L27B_3%
echo.
echo   %T_TERMS_L29%
echo   %T_TERMS_L30%
if defined T_TERMS_L30_2 echo   %T_TERMS_L30_2%
echo   %T_TERMS_L31%
if defined T_TERMS_L31_2 echo   %T_TERMS_L31_2%
if defined T_TERMS_L31_3 echo   %T_TERMS_L31_3%
echo   %T_TERMS_L31B%
if defined T_TERMS_L31B_2 echo   %T_TERMS_L31B_2%
if defined T_TERMS_L31B_3 echo   %T_TERMS_L31B_3%
if defined T_TERMS_L31B_4 echo   %T_TERMS_L31B_4%
if defined T_TERMS_L31B_5 echo   %T_TERMS_L31B_5%
    echo   %T_TERMS_L32%
    if defined T_TERMS_L32_2 echo   %T_TERMS_L32_2%
    if defined T_TERMS_L32_3 echo   %T_TERMS_L32_3%
    echo   %T_TERMS_L32B%
    if defined T_TERMS_L32B_2 echo   %T_TERMS_L32B_2%
    if defined T_TERMS_L32B_3 echo   %T_TERMS_L32B_3%
    if defined T_TERMS_L32B_4 echo   %T_TERMS_L32B_4%
    if defined T_TERMS_L32B_5 echo   %T_TERMS_L32B_5%
    if defined T_TERMS_L32B_6 echo   %T_TERMS_L32B_6%
    if defined T_TERMS_L32B_7 echo   %T_TERMS_L32B_7%
echo.
echo   %T_TERMS_L33%
echo   %T_TERMS_L34%
echo   %T_TERMS_L34B%
if defined T_TERMS_L34B_2 echo   %T_TERMS_L34B_2%
echo   %T_TERMS_L35%
if defined T_TERMS_L35_2 echo   %T_TERMS_L35_2%
echo   %T_TERMS_L36%
if defined T_TERMS_L36_2 echo   %T_TERMS_L36_2%
echo   %T_TERMS_L37%
if defined T_TERMS_L37_2 echo   %T_TERMS_L37_2%
echo   %T_TERMS_L38%
echo   %T_TERMS_L39%
if defined T_TERMS_L39_2 echo   %T_TERMS_L39_2%
echo   %T_TERMS_L40%
if defined T_TERMS_L40_2 echo   %T_TERMS_L40_2%
echo   %T_TERMS_L41%
if defined T_TERMS_L41_2 echo   %T_TERMS_L41_2%
echo   %T_TERMS_L42%
if defined T_TERMS_L42_2 echo   %T_TERMS_L42_2%
echo.
echo   %T_TERMS_L43%
echo   %T_TERMS_L44%
echo   %T_TERMS_L45%
echo   %T_TERMS_L46%
echo   %T_TERMS_L47%
echo   %T_TERMS_L48%
echo   %T_TERMS_L48B%
if defined T_TERMS_L48B_2 echo   %T_TERMS_L48B_2%
echo   %T_TERMS_L49%
echo.
echo  %T_TERMS_CHOOSE%
echo.
echo   %T_TERMS_ACCEPT%
echo   %T_TERMS_DECLINE%
echo.
set "TERMSOP="
set /p "TERMSOP=%T_OPTION% "
if "%TERMSOP%"=="1" goto terms_accept
if "%TERMSOP%"=="2" exit /b 0
echo.
echo  %T_TERMS_INVALID%
pause
goto terms_screen

:terms_accept
if not exist "%SDKROOT%" mkdir "%SDKROOT%" >nul 2>&1
>"%SDKROOT%\.termos_aceitos_v3" echo aceito em %date% %time%
goto main_menu
:main_menu
call :initialize_localized_paths
call :dialogos_localizar_marcador
if not defined ddac_marker goto dialogos_erro_marcador
cls
echo.
echo  ============================================================
echo   %T_TITLE%
echo  ============================================================
echo.
echo   %T_DIALOGOS%
echo   %T_DIALOGOS_DESC%
echo.
echo   %T_SUPPORT%
echo.
echo   %T_DISCLAIMER%
echo.
echo  %T_CHOOSE%
echo.
echo   1) %T_DLG_EXTRACT%
echo      %T_DLG_EXTRACT_DET%
echo.
echo   2) %T_DLG_TRANSLATE%
echo      %T_DLG_TRANSLATE_DET%
echo.
echo   3) %T_DLG_REINJECT%
echo      %T_DLG_REINJECT_DET%
echo.
echo   4) %T_PATCH%
echo      %T_PATCH_DESC%
echo.
echo   5) %T_DLG_DIAG%
echo      %T_DLG_DIAG_DET%
echo.
echo   6) %T_EXIT%
echo.
set "OP="
set /p "OP=%T_OPTION% "
if "%OP%"=="1" goto dialogos_extrair
if "%OP%"=="2" goto dialogos_traduzir
if "%OP%"=="3" goto dialogos_reinjetar
if "%OP%"=="4" goto patch_interface_ptbr
if "%OP%"=="5" goto dialogos_diagnostico
if "%OP%"=="6" exit /b 0
echo.
echo  %T_INVALID%
pause
goto main_menu


:patch_interface_ptbr
cls
echo.
echo  ============================================================
echo   %T_PATCH%
echo  ============================================================
echo.
echo   %T_PATCH_DESC%
echo.
REM SEGURANCA: a Opcao 4 so pode CRIAR/ATUALIZAR UM UNICO arquivo permitido.
REM Nenhum arquivo do mod e apagado, movido ou copiado por esta rotina.
set "PATCH_GAME=%~dp0game"
if not exist "%PATCH_GAME%\" goto patch_interface_no_game
for %%G in ("%PATCH_GAME%") do set "PATCH_GAME_FULL=%%~fG"
for %%B in ("%~f0") do set "PATCH_BATCH_FULL=%%~fB"
set "PATCH_OUT_NAME=DDAC-Interface-Universal-PT-BR.rpy"
set "PATCH_OUT=%PATCH_GAME_FULL%\%PATCH_OUT_NAME%"
for %%O in ("%PATCH_OUT%") do set "PATCH_OUT_FULL=%%~fO"
if /I not "%PATCH_OUT_FULL%"=="%PATCH_GAME_FULL%\%PATCH_OUT_NAME%" goto patch_interface_security_error
set "DDAC_PATCH_SELF=%PATCH_BATCH_FULL%"
set "DDAC_PATCH_GAME=%PATCH_GAME_FULL%"
set "DDAC_PATCH_OUT=%PATCH_OUT_FULL%"
set "DDAC_PATCH_OUT_NAME=%PATCH_OUT_NAME%"
where powershell.exe >nul 2>&1
if errorlevel 1 goto patch_interface_error
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $self=[IO.Path]::GetFullPath($env:DDAC_PATCH_SELF); $game=[IO.Path]::GetFullPath($env:DDAC_PATCH_GAME); $out=[IO.Path]::GetFullPath($env:DDAC_PATCH_OUT); $name=$env:DDAC_PATCH_OUT_NAME; $sep=[IO.Path]::DirectorySeparatorChar; if(-not ($out.StartsWith($game+$sep,[StringComparison]::OrdinalIgnoreCase)) -or [IO.Path]::GetFileName($out) -ne $name -or [IO.Path]::GetDirectoryName($out).TrimEnd([char]92,[char]47) -ne $game.TrimEnd([char]92,[char]47)){ throw 'Destino do patch fora de game bloqueado.' }; $lines=[IO.File]::ReadAllLines($self); $si=-1; $ei=-1; for($i=0;$i -lt $lines.Length;$i++){ if($lines[$i] -eq 'REM ##DDAC_PTBR_PATCH_START##'){ $si=$i+1; break } }; if($si -lt 0){ throw 'Marcador inicial do patch nao encontrado.' }; for($j=$si;$j -lt $lines.Length;$j++){ if($lines[$j] -eq 'REM ##DDAC_PTBR_PATCH_END##'){ $ei=$j; break } }; if($ei -lt 0){ throw 'Marcador final do patch nao encontrado.' }; $b64=New-Object System.Collections.Generic.List[string]; for($i=$si;$i -lt $ei;$i++){ $line=$lines[$i]; if($line.StartsWith('REM #')){ [void]$b64.Add($line.Substring(5)) } }; if($b64.Count -eq 0){ throw 'Payload do patch vazio.' }; $payload=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($b64 -join ''))); $tl=Join-Path $game 'tl\None'; $known=@{}; if(Test-Path -LiteralPath $tl -PathType Container){ Get-ChildItem -LiteralPath $tl -Recurse -File -ErrorAction Stop | Where-Object { $_.Extension -eq '.rpy' -or $_.Extension -eq '.rpym' } | ForEach-Object { Get-Content -LiteralPath $_.FullName -Encoding UTF8 -ErrorAction Stop | ForEach-Object { $t=$_.Trim(); if($t.StartsWith('old '+[char]34)){ $known[$t]=$true } } } }; $src=$payload -split '\r?\n'; $outLines=New-Object 'System.Collections.Generic.List[string]'; for($i=0;$i -lt $src.Count;$i++){ $line=$src[$i]; $trim=$line.Trim(); if($trim.StartsWith('old '+[char]34) -and ($i+1) -lt $src.Count -and $known.ContainsKey($trim)){ $i++; continue }; [void]$outLines.Add($line) }; [IO.File]::WriteAllText($out,($outLines -join [Environment]::NewLine),(New-Object Text.UTF8Encoding($false))); if(-not (Test-Path -LiteralPath $out -PathType Leaf)){ throw 'Patch nao foi criado.' }; if((Get-Item -LiteralPath $out).Length -le 0){ throw 'Patch vazio.' }; $outText=[IO.File]::ReadAllText($out); if($outText -match ('(?m)return rv\s+old '+[char]34)){ throw 'Validação do patch falhou: tradução foi inserida dentro de Python.' }; if($outText -match '(?m)^label\s+_(quit_prompt|main_menu_prompt):'){ throw 'Validação do patch falhou: label interno duplicado.' }; $parts=$outText -split '(?m)^translate None strings:\s*$'; if($parts.Count -lt 2 -or $parts[0] -match '(?m)^\s*(old|new)\s+'){ throw 'Validação do patch falhou: bloco old/new fora de translate None strings.' }; if($outText -match ('Contacting App Store'+[char]13+'?'+[char]10+'Please Wait\.\.\.')){ throw 'Validação do patch falhou: App Store com quebra física de linha.' }; if($outText -notmatch 'TERMOS DE USO DDAC'){ throw 'Validação do patch falhou: termos de uso DDAC ausentes.' }; if($outText -notmatch 'Copyright \(c\) 2026 Pedro / DDAC\.'){ throw 'Validação do patch falhou: copyright DDAC ausente.' }; Write-Output 'DDAC_PATCH_OK'" >nul 2>&1
set "PATCH_RC=%ERRORLEVEL%"
if not "%PATCH_RC%"=="0" goto patch_interface_error
if not exist "%PATCH_OUT_FULL%" goto patch_interface_error
for %%Z in ("%PATCH_OUT_FULL%") do if %%~zZ LSS 1 goto patch_interface_error
echo.
echo  %T_PATCH_OK%
echo  %PATCH_OUT_FULL%
echo.
echo  A Opção 4 foi blindada: ela não apaga, move ou copia arquivos do mod.
echo  Somente o patch acima pode ser criado ou atualizado.
echo.
set /p "DDAC_EXIT=Pressione ENTER para sair: "
exit /b 0

:patch_interface_no_game
echo.
echo  %T_PATCH_NOGAME%
echo.
set /p "DDAC_EXIT=Pressione ENTER para sair: "
exit /b 1

:patch_interface_security_error
echo.
echo  [SEGURANÇA] O destino do patch foi recusado.
echo  Nenhum arquivo foi modificado.
echo.
set /p "DDAC_EXIT=Pressione ENTER para sair: "
exit /b 1

:patch_interface_error
echo.
echo  %T_PATCH_ERR%
echo  Nenhum arquivo do mod foi apagado por esta rotina.
echo.
set /p "DDAC_EXIT=Pressione ENTER para sair: "
exit /b 1
:dialogos_localizar_marcador
REM Localização do marcador via findstr com o marcador quebrado em duas
REM variáveis (ddac_mk1+ddac_mk2), para que o texto completo do marcador nunca
REM apareça inteiro no arquivo fora do ponto real onde o Python embutido começa.
REM Extração via MORE, sem PowerShell.
set "ddac_marker="
set "ddac_mk1=REM ##DDAC_DIALOGOS"
set "ddac_mk2=_PYTHON_START##"
for /f "tokens=1 delims=:" %%L in ('findstr /n /c:"%ddac_mk1%%ddac_mk2%" "%~f0"') do if not defined ddac_marker set "ddac_marker=%%L"
exit /b 0

:find_ddac_runtime
REM Python 3 do DDAC: cache compartilhado %LOCALAPPDATA%\DDAC-SDK\DDAC-Dependência.
REM A dependência baixada uma vez é reutilizada por todos os mods/idiomas.
set "DDAC_FOUND_RUNTIME_ROOT="
set "DDAC_RUNTIME_CACHE=%SDKROOT%\DDAC-Dependência"
if exist "%DDAC_RUNTIME_CACHE%\python3\python.exe" (
    set "DDAC_FOUND_RUNTIME_ROOT=%DDAC_RUNTIME_CACHE%"
    exit /b 0
)
REM Compatibilidade: reutiliza o runtime histórico de %LOCALAPPDATA%\DDAC-SDK e o copia para a nova raiz DDAC sem apagar o antigo.
set "DDAC_RUNTIME_LEGACY_APPDATA=%LOCALAPPDATA%\DDAC-SDK\DDAC-Dependência"
if exist "%DDAC_RUNTIME_LEGACY_APPDATA%\python3\python.exe" (
    if not exist "%SDKROOT%" mkdir "%SDKROOT%" >nul 2>&1
    if not exist "%DDAC_RUNTIME_CACHE%" mkdir "%DDAC_RUNTIME_CACHE%" >nul 2>&1
    xcopy /e /i /y "%DDAC_RUNTIME_LEGACY_APPDATA%\*" "%DDAC_RUNTIME_CACHE%\" >nul 2>&1
    if exist "%DDAC_RUNTIME_CACHE%\python3\python.exe" (
        set "DDAC_FOUND_RUNTIME_ROOT=%DDAC_RUNTIME_CACHE%"
        exit /b 0
    )
    set "DDAC_FOUND_RUNTIME_ROOT=%DDAC_RUNTIME_LEGACY_APPDATA%"
    exit /b 0
)
REM Migração automática de uma dependência antiga localizada ao lado do BAT.
set "DDAC_RUNTIME_LEGACY=%~dp0%T_RUNTIME_FOLDER%"
if exist "%DDAC_RUNTIME_LEGACY%\python3\python.exe" (
    if not exist "%SDKROOT%" mkdir "%SDKROOT%" >nul 2>&1
    if not exist "%DDAC_RUNTIME_CACHE%" mkdir "%DDAC_RUNTIME_CACHE%" >nul 2>&1
    xcopy /e /i /y "%DDAC_RUNTIME_LEGACY%\*" "%DDAC_RUNTIME_CACHE%\" >nul 2>&1
    if exist "%DDAC_RUNTIME_CACHE%\python3\python.exe" (
        set "DDAC_FOUND_RUNTIME_ROOT=%DDAC_RUNTIME_CACHE%"
        exit /b 0
    )
    set "DDAC_FOUND_RUNTIME_ROOT=%DDAC_RUNTIME_LEGACY%"
    exit /b 0
)
exit /b 1
:dialogos_extrair
set "ddac_requires_renpy_sdk=0"
set "ddac_modo=extrair"
set "LOG=%~dp0UnRen-DDAC-Extração-de-Diálogos.txt"
set "txt_inicio=%T_DLG_START_EXTRACT%"
>"%LOG%" echo ============================================================
>>"%LOG%" echo DDAC Extração de Texto Visível - V145
>>"%LOG%" echo Data/Hora: %DATE% %TIME%
>>"%LOG%" echo STATUS=EXECUCAO_INICIADA^|VERSAO=V145
>>"%LOG%" echo ============================================================
REM V145: log.txt e o SDK não são requisitos obrigatórios para iniciar a extração.
REM O motor DDAC trabalha sozinho; o oráculo Ren'Py é tentado como validação adicional.
REM A detecção da versão, quando possível, é feita pelo motor embutido a partir dos arquivos do projeto.
goto dialogos_executar

:dialogos_traduzir
set "ddac_requires_renpy_sdk=0"
set "ddac_modo=traduzir"
set "LOG=%~dp0UnRen-DDAC-Tradução-com-Google-Translate.txt"
set "txt_inicio=%T_DLG_START_TRANSLATE%"
goto dialogos_executar

:dialogos_diagnostico
set "ddac_requires_renpy_sdk=0"
set "ddac_modo=diagnostico_google"
set "ddac_diag_tipo=normal"
set "LOG=%~dp0UnRen-DDAC-Diagnóstico-Google-Translate.txt"
set "txt_inicio=%T_DLG_START_DIAG%"
goto dialogos_executar_diagnostico

:dialogos_diagnostico_estresse
set "ddac_requires_renpy_sdk=0"
set "ddac_modo=diagnostico_estresse_google"
set "ddac_diag_tipo=estresse"
set "LOG=%~dp0UnRen-DDAC-Diagnóstico-Estresse-Google-Translate.txt"
set "txt_inicio=%T_DLG_START_STRESS%"
goto dialogos_executar_diagnostico

:dialogos_reinjetar
set "ddac_requires_renpy_sdk=0"
set "ddac_modo=reinjetar"
set "LOG=%~dp0UnRen-DDAC-Reintegração-de-Diálogos.txt"
set "txt_inicio=%T_DLG_START_REINJECT%"
goto dialogos_executar

:dialogos_validar_log_renpy
REM Opção 1 exige o log.txt criado pelo próprio executável do jogo/mod.
REM O arquivo fica na RAIZ da distribuição: no mesmo nível do .exe e da pasta game.
REM A leitura usa somente comandos nativos do Windows, sem PowerShell.
set "DDAC_LOG_RENPY_PATH="
set "DDAC_LOG_RENPY_VERSION="

REM %~dp0 é o diretório físico do BAT e não depende do diretório de trabalho do CMD.
if exist "%ROOT%\log.txt" set "DDAC_LOG_RENPY_PATH=%ROOT%\log.txt"
if not defined DDAC_LOG_RENPY_PATH if exist "%CD%\log.txt" set "DDAC_LOG_RENPY_PATH=%CD%\log.txt"
if not defined DDAC_LOG_RENPY_PATH exit /b 1

REM Formato real do log:
REM   Ren'Py 7.5.3.22090809
REM Ren'Py 6 usa MAJOR.MINOR.PATCH.REVISION (ex.: 6.99.12.4); Ren'Py 7/8 usam os três primeiros componentes.
REM O build adicional não entra no nome do SDK.
for /f "tokens=2" %%V in ('findstr /b /r /c:"Ren.Py [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" "%DDAC_LOG_RENPY_PATH%" 2^>nul') do (
    for /f "tokens=1-5 delims=." %%A in ("%%V") do (
        if "%%A"=="6" (
            if not "%%D"=="" (
                set "DDAC_LOG_RENPY_VERSION=%%A.%%B.%%C.%%D"
            ) else (
                set "DDAC_LOG_RENPY_VERSION=%%A.%%B.%%C"
            )
        ) else (
            set "DDAC_LOG_RENPY_VERSION=%%A.%%B.%%C"
        )
    )
    goto dialogos_validar_log_renpy_ok
)

goto dialogos_validar_log_renpy_falha

:dialogos_validar_log_renpy_falha
set "DDAC_LOG_RENPY_VERSION="
exit /b 1

:dialogos_validar_log_renpy_ok
if not defined DDAC_LOG_RENPY_VERSION exit /b 1
exit /b 0

:dialogos_log_renpy_faltando
cls
echo.
echo  ============================================================
echo  %T_DLG_LOG_TITLE%
echo  ============================================================
echo.
echo  %T_DLG_LOG_MISSING%
echo  %T_DLG_LOG_MISSING_2%
echo.
echo  %T_DLG_LOG_ACTION%
echo.
if defined DDAC_LOG_RENPY_PATH echo  Log encontrado, mas a linha de versão não pôde ser lida: %DDAC_LOG_RENPY_PATH%
if not defined DDAC_LOG_RENPY_PATH echo  Caminho verificado: %ROOT%\log.txt
echo  A Opção 1 não será executada até que o log.txt exista e contenha a versão do Ren'Py.
echo.
pause
goto main_menu

:dialogos_executar_diagnostico
set "ddac_requires_renpy_sdk=0"
call :ddac_dialogos_preparar_runtime
if not defined ddac_pythoncmd goto dialogos_erro_dependencia
if "%ddac_dependency_just_downloaded%"=="1" call :dialogos_dependency_ready_prompt
if "%ddac_dep_goto_menu%"=="1" (
    set "ddac_dep_goto_menu="
    goto main_menu
)
cls
echo.
echo  %txt_inicio%
echo.
set "ddac_tmp=%TEMP%\ddac_dialogos_%RANDOM%.py"
set "ddac_tmp_b64=%TEMP%\ddac_dialogos_%RANDOM%_payload.b64"
more +%ddac_marker% "%~f0" | findstr /b /c:"REM " > "%ddac_tmp_b64%"
if errorlevel 1 (set "ddac_rc=91"& >>"%LOG%" echo FASE=PAYLOAD_EXTRACAO^|ERRO=MORE_FINDSTR^|codigo=91& goto dialogos_erro_execucao)
>>"%LOG%" echo FASE=PAYLOAD_EXTRACAO^|OK=arquivo_base64_criado
set "DDAC_TMP_B64_RAW=%ddac_tmp_b64%"
set "DDAC_TMP_PY=%ddac_tmp%"
where powershell.exe >nul 2>&1
if errorlevel 1 (set "ddac_rc=92"& >>"%LOG%" echo FASE=PAYLOAD_DECODIFICACAO^|ERRO=POWERSHELL_NAO_ENCONTRADO^|codigo=92& goto dialogos_erro_execucao)
powershell.exe -NoProfile -NonInteractive -Command "$raw=[IO.File]::ReadAllLines($env:DDAC_TMP_B64_RAW); $out=New-Object 'System.Collections.Generic.List[string]'; foreach($l in $raw){ $x=$l.Substring(4); if($x -eq '##DDAC_DIALOGOS_PYTHON_END##'){ break }; if($x.StartsWith('#')){ $x=$x.Substring(1) }; if($x){ [void]$out.Add($x) } }; $b64=$out -join ''; [IO.File]::WriteAllBytes($env:DDAC_TMP_PY,[Convert]::FromBase64String($b64))" >nul 2>&1
if errorlevel 1 (set "ddac_rc=93"& >>"%LOG%" echo FASE=PAYLOAD_DECODIFICACAO^|ERRO=BASE64_INVALIDO_OU_POWERSHELL^|codigo=93& goto dialogos_erro_execucao)
>>"%LOG%" echo FASE=PAYLOAD_DECODIFICACAO^|OK=python_temporario_criado
del /q "%ddac_tmp_b64%" >nul 2>&1
set "ddac_raiz=%~dp0"
if "%ddac_raiz:~-1%"=="\" set "ddac_raiz=%ddac_raiz:~0,-1%"
set "PYTHONHOME="
set "PYTHONPATH="
echo.
echo ============================================================
if "%ddac_diag_tipo%"=="estresse" (
    echo  TESTE DE ESTRESSE DO GOOGLE TRANSLATE
    echo ============================================================
    echo  Teste somente leitura. Nenhum arquivo do jogo será modificado aqui.
) else (
    echo  %T_DLG_PREFLIGHT_TITLE%
    echo ============================================================
    echo  Diagnóstico em modo somente leitura.
)
echo.
echo.
echo  Executando o processamento em tempo real. Não feche esta janela.
echo.
%ddac_pythoncmd% "%ddac_tmp%" "%ddac_modo%" "%ddac_raiz%" "%LANG%"
set "ddac_rc=%ERRORLEVEL%"
del "%ddac_tmp%" >nul 2>nul
if not "%ddac_rc%"=="0" goto dialogos_erro_execucao
echo.
echo  Execução concluída com sucesso.
if defined LOG_DIALOGOS echo  Log detalhado: %LOG_DIALOGOS%
echo.
echo  Pressione qualquer tecla para sair...
pause >nul
exit /b 0
:dialogos_executar
REM Opção 1 usa duas dependências deliberadamente diferentes:
REM   Python 3 compartilhado do DDAC = nosso motor de extração/tradução/reintegração.
REM   SDK Ren'Py da versão do mod = oráculo semântico oficial, com o Python do próprio SDK.
call :ddac_dialogos_preparar_runtime
if not defined ddac_pythoncmd goto dialogos_erro_dependencia
set "ddac_dependency_session_downloaded=%ddac_dependency_just_downloaded%"
if "%ddac_requires_renpy_sdk%"=="1" call :dialogos_preparar_renpy_sdk
if "%ddac_requires_renpy_sdk%"=="1" if not defined ddac_renpy_sdk_ready goto dialogos_erro_dependencia
if "%ddac_sdk_dependency_just_downloaded%"=="1" set "ddac_dependency_session_downloaded=1"

REM A tela final só aparece quando uma dependência foi realmente baixada/preparada
REM nesta execução. Depois que o usuário confirma, as execuções seguintes
REM entram diretamente na extração enquanto o cache continuar válido.
REM As verificações ficam fora de blocos (...) para que o CMD releia os valores
REM atualizados pelas sub-rotinas depois do download/preparação.
if not "%ddac_dependency_session_downloaded%"=="1" goto dialogos_iniciar_extracao
goto dialogos_mostrar_todas_dependencias

:dialogos_mostrar_todas_dependencias
call :dialogos_sdk_ready_prompt
if "%ddac_sdk_goto_menu%"=="1" (
    set "ddac_sdk_goto_menu="
    goto main_menu
)
:dialogos_iniciar_extracao
cls
echo.
echo  %txt_inicio%
echo.
set "ddac_tmp=%TEMP%\ddac_dialogos_%RANDOM%.py"
set "ddac_tmp_b64=%TEMP%\ddac_dialogos_%RANDOM%_payload.b64"
more +%ddac_marker% "%~f0" | findstr /b /c:"REM " > "%ddac_tmp_b64%"
if errorlevel 1 (set "ddac_rc=91"& >>"%LOG%" echo FASE=PAYLOAD_EXTRACAO^|ERRO=MORE_FINDSTR^|codigo=91& goto dialogos_erro_execucao)
>>"%LOG%" echo FASE=PAYLOAD_EXTRACAO^|OK=arquivo_base64_criado
set "DDAC_TMP_B64_RAW=%ddac_tmp_b64%"
set "DDAC_TMP_PY=%ddac_tmp%"
where powershell.exe >nul 2>&1
if errorlevel 1 (set "ddac_rc=92"& >>"%LOG%" echo FASE=PAYLOAD_DECODIFICACAO^|ERRO=POWERSHELL_NAO_ENCONTRADO^|codigo=92& goto dialogos_erro_execucao)
powershell.exe -NoProfile -NonInteractive -Command "$raw=[IO.File]::ReadAllLines($env:DDAC_TMP_B64_RAW); $out=New-Object 'System.Collections.Generic.List[string]'; foreach($l in $raw){ $x=$l.Substring(4); if($x -eq '##DDAC_DIALOGOS_PYTHON_END##'){ break }; if($x.StartsWith('#')){ $x=$x.Substring(1) }; if($x){ [void]$out.Add($x) } }; $b64=$out -join ''; [IO.File]::WriteAllBytes($env:DDAC_TMP_PY,[Convert]::FromBase64String($b64))" >nul 2>&1
if errorlevel 1 (set "ddac_rc=93"& >>"%LOG%" echo FASE=PAYLOAD_DECODIFICACAO^|ERRO=BASE64_INVALIDO_OU_POWERSHELL^|codigo=93& goto dialogos_erro_execucao)
>>"%LOG%" echo FASE=PAYLOAD_DECODIFICACAO^|OK=python_temporario_criado
del /q "%ddac_tmp_b64%" >nul 2>&1
set "ddac_raiz=%~dp0"
if "%ddac_raiz:~-1%"=="\" set "ddac_raiz=%ddac_raiz:~0,-1%"
set "PYTHONHOME="
set "PYTHONPATH="
echo.
echo ============================================================
echo  %T_DLG_PREFLIGHT_TITLE%
echo ============================================================
echo  %T_DLG_PREFLIGHT_READONLY%
echo  Runtime DDAC: Python 3 compartilhado ^| Oráculo Ren'Py: opcional; a extração continua se ele falhar.
if defined DDAC_RENPY_SDK echo  SDK Ren'Py selecionado: %DDAC_RENPY_SDK%
echo.
%ddac_pythoncmd% "%ddac_tmp%" "preflight" "%ddac_raiz%" "%LANG%" "%ddac_modo%"
set "ddac_preflight_rc=%ERRORLEVEL%"
if not "%ddac_preflight_rc%"=="0" goto dialogos_preflight_falhou
echo.
echo  %T_DLG_PREFLIGHT_CONTINUE%
echo.
%ddac_pythoncmd% "%ddac_tmp%" "%ddac_modo%" "%ddac_raiz%" "%LANG%"
set "ddac_rc=%ERRORLEVEL%"
del "%ddac_tmp%" >nul 2>nul
if not "%ddac_rc%"=="0" goto dialogos_erro_execucao
echo.
echo ============================================================
echo  Execução concluída com sucesso.
if defined LOG_DIALOGOS echo  Log detalhado: %LOG_DIALOGOS%
echo.
echo  Pressione qualquer tecla para sair...
pause >nul
exit /b 0
:dialogos_preflight_falhou
echo.
echo  %T_L_DIALOG_ERR% %ddac_preflight_rc%
echo  A pré-verificação bloqueou a etapa por segurança.
echo.
pause
goto main_menu

:dialogos_erro_execucao
if not defined ddac_rc set "ddac_rc=99"
echo.
echo  %T_L_DIALOG_ERR% %ddac_rc%
echo  %T_DLG_ERR_EXEC_HINT%
if defined LOG >>"%LOG%" echo [%txt_tag_erro%] %T_L_DIALOG_ERR% %ddac_rc%
echo.
pause
goto main_menu

:dialogos_erro_dependencia
cls
echo.
echo   %T_DLG_ERR_DEP%
echo   %T_DLG_ERR_DEP2%
echo.
pause
goto main_menu

REM ==============================================================================
:ddac_dialogos_preparar_runtime
REM Dependência própria e independente dos Diálogos: Python 3 embeddable oficial
REM (mesmo pacote já validado na rotina de Extração/Descompilação -- reaproveita
REM a mesma pasta baixada, se já existir, para não baixar duas vezes).
set "ddac_pythoncmd="
set "ddac_dependency_just_downloaded=0"
call :find_ddac_runtime
if defined DDAC_FOUND_RUNTIME_ROOT (
    set "ddac_runtime_root=%DDAC_FOUND_RUNTIME_ROOT%"
) else (
    set "ddac_runtime_root=%SDKROOT%\DDAC-Dependência"
)
set "ddac_runtime_dir=%ddac_runtime_root%\python3"
set "ddac_runtime_zip=%ddac_runtime_root%\python-3.13.15-embed.zip"
set "ddac_runtime_part=%ddac_runtime_zip%.part"
set "ddac_runtime_source=https://www.python.org/downloads/release/python-31315/"

if exist "%ddac_runtime_dir%\python.exe" (
    set "ddac_pythoncmd="%ddac_runtime_dir%\python.exe""
    exit /b 0
)

if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "ddac_runtime_url=https://www.python.org/ftp/python/3.13.15/python-3.13.15-embed-amd64.zip"
    set "ddac_runtime_expected_size=11009825"
    set "ddac_runtime_expected_sha256=d1f04d990aee1253d8569e8e5104e30fa9f5fa830899f14843448872d936a2cf"
) else if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
    set "ddac_runtime_url=https://www.python.org/ftp/python/3.13.15/python-3.13.15-embed-amd64.zip"
    set "ddac_runtime_expected_size=11009825"
    set "ddac_runtime_expected_sha256=d1f04d990aee1253d8569e8e5104e30fa9f5fa830899f14843448872d936a2cf"
) else (
    set "ddac_runtime_url=https://www.python.org/ftp/python/3.13.15/python-3.13.15-embed-win32.zip"
    set "ddac_runtime_expected_size=9758828"
    set "ddac_runtime_expected_sha256=3f5506367943d16dffa89f0ea140ebf04481a80611eb119e76e95aea8c79f5ce"
)

cls
echo.
echo  ============================================================
echo                 %T_DLG_DEP_TITLE%
echo  ============================================================
echo.
echo  %T_DLG_DEP_L1%
echo  %T_DLG_DEP_L2%
echo.
echo  %T_DLG_DEP_CANDOWNLOAD%
echo  %T_DLG_DEP_EMBED%
echo  %T_DLG_DEP_NOTINSTALLED%
echo.
echo  %T_DLG_DEP_SOURCE%
echo  %ddac_runtime_url%
echo.
echo  %T_DLG_DEP_PAGE%
echo  %ddac_runtime_source%
echo.
echo  %T_DLG_DEP_OPENPAGE%
echo  %T_DLG_DEP_DOWNLOAD%
echo  %T_DLG_DEP_CANCEL%
echo.
set "ddac_runtime_choice="
set /p "ddac_runtime_choice=%T_OPTION% "
if "%ddac_runtime_choice%"=="1" (
    start "Python - fonte oficial" "%ddac_runtime_source%"
    echo.
    echo  %T_DLG_DEP_PAGEOPENED%
    echo  %T_DLG_DEP_RUNAGAIN%
    pause
    exit /b 1
)
if not "%ddac_runtime_choice%"=="2" exit /b 1

if not exist "%ddac_runtime_root%" mkdir "%ddac_runtime_root%" >nul 2>&1
if exist "%ddac_runtime_part%" del /Q "%ddac_runtime_part%" >nul 2>&1
if exist "%ddac_runtime_zip%" del /Q "%ddac_runtime_zip%" >nul 2>&1
if exist "%ddac_runtime_dir%" rmdir /Q /S "%ddac_runtime_dir%" >nul 2>&1

set "ddac_download_result="
for /f "delims=" %%R in ('powershell.exe -NoProfile -NonInteractive -Command "$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $u='%ddac_runtime_url%'; $r=Invoke-WebRequest -Uri $u -UseBasicParsing -Method Get -OutFile '%ddac_runtime_part%' -PassThru; $final=$r.BaseResponse.ResponseUri.AbsoluteUri; $finalHost=$r.BaseResponse.ResponseUri.Host; if ($finalHost -ne 'www.python.org' -and $finalHost -ne 'python.org') { throw ('Redirecionamento para host não autorizado: ' + $finalHost) }; $sha=(Get-FileHash -LiteralPath '%ddac_runtime_part%' -Algorithm SHA256).Hash; $len=(Get-Item '%ddac_runtime_part%').Length; Write-Output ('OK~' + $final + '~' + $len + '~' + $sha) } catch { Write-Output ('ERR~' + $_.Exception.Message) }" 2^>nul') do set "ddac_download_result=%%R"

if not defined ddac_download_result (
    echo %T_DLG_DEP_ERR_RESULT%
    exit /b 1
)

set "ddac_download_status="
set "ddac_download_size="
set "ddac_download_sha256="
for /f "tokens=1-4 delims=~" %%A in ("%ddac_download_result%") do (
    set "ddac_download_status=%%A"
    set "ddac_download_size=%%C"
    set "ddac_download_sha256=%%D"
)

if /I not "%ddac_download_status%"=="OK" (
    echo %T_DLG_DEP_ERR_DOWNLOAD% %ddac_download_result%
    exit /b 1
)
if not "%ddac_download_size%"=="%ddac_runtime_expected_size%" (
    echo %T_DLG_DEP_ERR_SIZE%
    echo  %T_DLG_DEP_EXPECTED% %ddac_runtime_expected_size% %T_DLG_DEP_BYTES%
    echo  %T_DLG_DEP_RECEIVED% %ddac_download_size% %T_DLG_DEP_BYTES%
    exit /b 1
)
if /I not "%ddac_download_sha256%"=="%ddac_runtime_expected_sha256%" (
    echo %T_DLG_DEP_ERR_INTEGRITY%
    echo  %T_DLG_DEP_EXPECTED% %ddac_runtime_expected_sha256%
    echo  %T_DLG_DEP_RECEIVED% %ddac_download_sha256%
    echo  %T_DLG_DEP_DISCARDED%
    exit /b 1
)

move /Y "%ddac_runtime_part%" "%ddac_runtime_zip%" >nul
if errorlevel 1 (
    echo %T_DLG_DEP_ERR_FINALIZE%
    exit /b 1
)

mkdir "%ddac_runtime_dir%" >nul 2>&1
powershell.exe -NoProfile -NonInteractive -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%ddac_runtime_zip%', '%ddac_runtime_dir%')" >nul 2>&1
if errorlevel 1 (
    echo %T_DLG_DEP_ERR_EXTRACT%
    exit /b 1
)

if not exist "%ddac_runtime_dir%\python.exe" (
    echo %T_DLG_DEP_ERR_NOPYTHON%
    exit /b 1
)

"%ddac_runtime_dir%\python.exe" -c "import sys;print(sys.version_info[0])" >"%temp%\%T_TMP_DIALOGOS_RUNTIME_TEST_FILE%" 2>nul
set "ddac_runtime_test="
if exist "%temp%\%T_TMP_DIALOGOS_RUNTIME_TEST_FILE%" set /p "ddac_runtime_test="<"%temp%\%T_TMP_DIALOGOS_RUNTIME_TEST_FILE%"
del /Q "%temp%\%T_TMP_DIALOGOS_RUNTIME_TEST_FILE%" >nul 2>&1
if not "%ddac_runtime_test%"=="3" (
    echo %T_DLG_DEP_ERR_START%
    exit /b 1
)

set "ddac_pythoncmd="%ddac_runtime_dir%\python.exe""
set "ddac_dependency_just_downloaded=1"
exit /b 0

:dialogos_preparar_renpy_sdk
set "ddac_renpy_sdk_ready="
set "ddac_sdk_dependency_just_downloaded=0"
set "ddac_sdk_goto_menu="
set "DDAC_RENPY_SDK="
set "DDAC_RENPY_SDK_STRICT="

REM A Opção 1 já validou obrigatoriamente o log.txt.
REM A versão do log é a autoridade: não apagamos nem redetectamos por outro meio.
set "DDAC_TARGET_VERSION=%DDAC_LOG_RENPY_VERSION%"
set "DDAC_SDK_VERSION=%DDAC_LOG_RENPY_VERSION%"
set "DDAC_TARGET_FAMILY="
set "DDAC_TARGET_EVIDENCE=log.txt :: Ren'Py"
set "DDAC_TARGET_FALLBACK=NAO"

if not defined DDAC_SDK_VERSION goto dialogos_sdk_version_missing
set "DDAC_SDK_DIR=%SDKROOT%\%DDAC_SDK_VERSION%"
set "DDAC_SDK_PAGE=https://www.renpy.org/dl/%DDAC_SDK_VERSION%/"
set "DDAC_SDK_ZIP=%SDKROOT%\renpy-%DDAC_SDK_VERSION%-sdk.zip"
set "DDAC_SDK_TMP=%SDKROOT%\_extract_dialogos_%DDAC_SDK_VERSION%"

if exist "%DDAC_SDK_DIR%\renpy.py" (
    set "DDAC_RENPY_SDK=%DDAC_SDK_DIR%"
    set "DDAC_RENPY_SDK_STRICT=1"
    set "ddac_renpy_sdk_ready=1"
    goto dialogos_sdk_done
)
if exist "%LOCALAPPDATA%\DDAC-SDK\%DDAC_SDK_VERSION%\renpy.py" (
    set "DDAC_RENPY_SDK=%LOCALAPPDATA%\DDAC-SDK\%DDAC_SDK_VERSION%"
    set "DDAC_RENPY_SDK_STRICT=1"
    set "ddac_renpy_sdk_ready=1"
    goto dialogos_sdk_done
)
if exist "%LOCALAPPDATA%\DDAC-SDK-Mobile\%DDAC_SDK_VERSION%\renpy.py" (
    set "DDAC_RENPY_SDK=%LOCALAPPDATA%\DDAC-SDK-Mobile\%DDAC_SDK_VERSION%"
    set "DDAC_RENPY_SDK_STRICT=1"
    set "ddac_renpy_sdk_ready=1"
    goto dialogos_sdk_done
)
call :dialogos_download_renpy_sdk
if errorlevel 1 goto dialogos_sdk_preparation_failed
set "DDAC_RENPY_SDK=%DDAC_SDK_DIR%"
set "DDAC_RENPY_SDK_STRICT=1"
set "ddac_renpy_sdk_ready=1"
goto dialogos_sdk_done

:dialogos_sdk_version_missing
cls
echo.
echo  %T_DLG_SDK_TITLE%
echo.
echo  Não foi possível determinar uma versão de SDK Ren'Py exata a partir do log.txt.
echo  %T_DLG_LOG_MISSING%
echo  %T_DLG_LOG_MISSING_2%
echo  %T_DLG_LOG_ACTION%
echo  %T_DLG_SDK_EXACT%
echo.
pause
exit /b 1

:dialogos_sdk_preparation_failed
cls
echo.
echo  %T_DLG_SDK_TITLE_CENTER%
echo.
echo  %T_DLG_SDK_FAIL%
echo  %T_DLG_SDK_SELECTED% %DDAC_SDK_VERSION%
echo.
echo  %T_DLG_SDK_CACHE% %DDAC_SDK_DIR%
echo  %T_DLG_SDK_SOURCE% %DDAC_SDK_PAGE%
echo.
pause
exit /b 1

:dialogos_sdk_done
exit /b 0

:dialogos_download_renpy_sdk
if not exist "%SDKROOT%" mkdir "%SDKROOT%" >nul 2>&1
if not exist "%SDKROOT%" exit /b 1
if exist "%DDAC_SDK_ZIP%" del /q "%DDAC_SDK_ZIP%" >nul 2>&1
if exist "%DDAC_SDK_TMP%" rmdir /s /q "%DDAC_SDK_TMP%" >nul 2>&1
cls
echo.
echo  ============================================================
echo  %T_DLG_SDK_TITLE_CENTER%
echo  ============================================================
echo.
echo  %T_DLG_SDK_L1%
echo  %T_DLG_SDK_L2%
echo.
echo  %T_DLG_SDK_DETECTED% %DDAC_TARGET_VERSION%
echo  %T_DLG_SDK_SELECTED% %DDAC_SDK_VERSION%
echo.
echo  %T_DLG_SDK_CACHE% %DDAC_SDK_DIR%
echo.
echo  %T_DLG_SDK_SOURCE% %DDAC_SDK_PAGE%
echo.
echo  %T_DLG_SDK_OPENPAGE%
echo  %T_DLG_SDK_DOWNLOAD%
echo  %T_DLG_SDK_CANCEL%
echo.
set "ddac_sdk_choice="
set /p "ddac_sdk_choice=%T_OPTION% "
if "%ddac_sdk_choice%"=="1" (
    start "Ren'Py SDK - fonte oficial" "%DDAC_SDK_PAGE%"
    echo.
    echo  Página oficial aberta no navegador.
    echo  Depois execute a Opção 1 novamente para continuar.
    pause
    exit /b 1
)
if not "%ddac_sdk_choice%"=="2" exit /b 1

echo.
echo  %T_DLG_SDK_DOWNLOADING%
set "DDAC_SDK_DOWNLOAD_RESULT="
for /f "delims=" %%R in ('powershell.exe -NoProfile -NonInteractive -Command "$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $u='https://www.renpy.org/dl/%DDAC_SDK_VERSION%/renpy-%DDAC_SDK_VERSION%-sdk.zip'; $o='%DDAC_SDK_ZIP%'; $r=Invoke-WebRequest -Uri $u -UseBasicParsing -Method Get -OutFile $o -PassThru; $final=$r.BaseResponse.ResponseUri.AbsoluteUri; $hash=(Get-FileHash -LiteralPath $o -Algorithm SHA256).Hash; $size=(Get-Item -LiteralPath $o).Length; Write-Output ('OK~' + $final + '~' + $size + '~' + $hash) } catch { Write-Output ('ERR~' + $_.Exception.Message) }" 2^>nul') do set "DDAC_SDK_DOWNLOAD_RESULT=%%R"
if not defined DDAC_SDK_DOWNLOAD_RESULT (
    del /q "%DDAC_SDK_ZIP%" >nul 2>&1
    exit /b 1
)
set "DDAC_SDK_DOWNLOAD_STATUS="
set "DDAC_SDK_DOWNLOAD_FINAL="
set "DDAC_SDK_DOWNLOAD_SIZE="
set "DDAC_SDK_DOWNLOAD_SHA="
for /f "tokens=1-4 delims=~" %%A in ("%DDAC_SDK_DOWNLOAD_RESULT%") do (
    set "DDAC_SDK_DOWNLOAD_STATUS=%%A"
    set "DDAC_SDK_DOWNLOAD_FINAL=%%B"
    set "DDAC_SDK_DOWNLOAD_SIZE=%%C"
    set "DDAC_SDK_DOWNLOAD_SHA=%%D"
)
if /I not "%DDAC_SDK_DOWNLOAD_STATUS%"=="OK" (
    del /q "%DDAC_SDK_ZIP%" >nul 2>&1
    exit /b 1
)
call :dialogos_verify_renpy_checksum "%DDAC_SDK_VERSION%" "renpy-%DDAC_SDK_VERSION%-sdk.zip" "%DDAC_SDK_ZIP%"
set "DDAC_SDK_CHECKSUM_RC=%ERRORLEVEL%"
if "%DDAC_SDK_CHECKSUM_RC%"=="1" (
    del /q "%DDAC_SDK_ZIP%" >nul 2>&1
    exit /b 1
)
if "%DDAC_SDK_CHECKSUM_RC%"=="2" echo  [AVISO] Checksum oficial indisponível; o arquivo baixado não foi substituído.
echo  %T_DLG_SDK_EXTRACTING%
mkdir "%DDAC_SDK_TMP%" >nul 2>&1
powershell.exe -NoProfile -NonInteractive -Command "try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%DDAC_SDK_ZIP%', '%DDAC_SDK_TMP%'); exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    del /q "%DDAC_SDK_ZIP%" >nul 2>&1
    rmdir /s /q "%DDAC_SDK_TMP%" >nul 2>&1
    exit /b 1
)
set "DDAC_SDK_SOURCE="
for /d %%D in ("%DDAC_SDK_TMP%\*") do if exist "%%~fD\renpy.py" if not defined DDAC_SDK_SOURCE set "DDAC_SDK_SOURCE=%%~fD"
if not defined DDAC_SDK_SOURCE if exist "%DDAC_SDK_TMP%\renpy.py" set "DDAC_SDK_SOURCE=%DDAC_SDK_TMP%"
if not defined DDAC_SDK_SOURCE (
    del /q "%DDAC_SDK_ZIP%" >nul 2>&1
    rmdir /s /q "%DDAC_SDK_TMP%" >nul 2>&1
    exit /b 1
)
if exist "%DDAC_SDK_DIR%" rmdir /s /q "%DDAC_SDK_DIR%" >nul 2>&1
move /y "%DDAC_SDK_SOURCE%" "%DDAC_SDK_DIR%" >nul 2>&1
if not exist "%DDAC_SDK_DIR%\renpy.py" (
    mkdir "%DDAC_SDK_DIR%" >nul 2>&1
    xcopy /e /i /y "%DDAC_SDK_SOURCE%\*" "%DDAC_SDK_DIR%\" >nul 2>&1
)
if not exist "%DDAC_SDK_DIR%\renpy.py" (
    del /q "%DDAC_SDK_ZIP%" >nul 2>&1
    rmdir /s /q "%DDAC_SDK_TMP%" >nul 2>&1
    exit /b 1
)
del /q "%DDAC_SDK_ZIP%" >nul 2>&1
rmdir /s /q "%DDAC_SDK_TMP%" >nul 2>&1
set "ddac_sdk_dependency_just_downloaded=1"
exit /b 0

:dialogos_verify_renpy_checksum
set "DDAC_CHECKSUM_RESULT="
set "DDAC_CHECKSUM_VERSION=%~1"
set "DDAC_CHECKSUM_FILENAME=%~2"
set "DDAC_CHECKSUM_FILE=%~3"
set "DDAC_CHECKSUM_URL=https://www.renpy.org/dl/%DDAC_CHECKSUM_VERSION%/checksums.txt"
for /f "usebackq delims=" %%R in (`powershell.exe -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; try { $r=Invoke-WebRequest -Uri $env:DDAC_CHECKSUM_URL -UseBasicParsing; $m=[regex]::Match($r.Content,'(?im)^\s*([0-9a-f]{64})\s+'+[regex]::Escape($env:DDAC_CHECKSUM_FILENAME)+'\s*$'); if($m.Success){ $a=(Get-FileHash -LiteralPath $env:DDAC_CHECKSUM_FILE -Algorithm SHA256).Hash.ToLowerInvariant(); Write-Output ('OK~'+$m.Groups[1].Value.ToLowerInvariant()+'~'+$a) } else { Write-Output 'MISSING~' } } catch { Write-Output ('UNAVAILABLE~'+$_.Exception.Message) }" 2^>nul`) do set "DDAC_CHECKSUM_RESULT=%%R"
if not defined DDAC_CHECKSUM_RESULT exit /b 2
set "DDAC_CHECKSUM_STATUS="
set "DDAC_CHECKSUM_EXPECTED="
set "DDAC_CHECKSUM_ACTUAL="
for /f "tokens=1-3 delims=~" %%A in ("%DDAC_CHECKSUM_RESULT%") do (
    set "DDAC_CHECKSUM_STATUS=%%A"
    set "DDAC_CHECKSUM_EXPECTED=%%B"
    set "DDAC_CHECKSUM_ACTUAL=%%C"
)
if /I "%DDAC_CHECKSUM_STATUS%"=="UNAVAILABLE" exit /b 2
if /I "%DDAC_CHECKSUM_STATUS%"=="MISSING" exit /b 2
if /I not "%DDAC_CHECKSUM_EXPECTED%"=="%DDAC_CHECKSUM_ACTUAL%" exit /b 1
exit /b 0

:dialogos_sdk_ready_prompt
cls
echo.
echo  ============================================================
echo  %T_DLG_SDK_READY_TITLE%
echo  ============================================================
echo.
echo  %T_DLG_SDK_READY_L1%
echo  %T_DLG_SDK_READY_L2%
echo.
echo  %T_DLG_SDK_DETECTED% %DDAC_TARGET_VERSION%
echo.
echo  %T_DLG_ALL_READY_RUNTIME% %ddac_runtime_root%
echo.
echo  %T_DLG_ALL_READY_SDK% %DDAC_RENPY_SDK%
echo.
echo  %T_DLG_SDK_CACHE% %SDKROOT%
echo.
echo  %T_DLG_SDK_CONTINUE%
echo  %T_DLG_SDK_BACK%
echo.
set "ddac_sdk_ready_opt="
set /p "ddac_sdk_ready_opt=%T_OPTION% "
if "%ddac_sdk_ready_opt%"=="1" exit /b 0
if "%ddac_sdk_ready_opt%"=="2" (
    set "ddac_sdk_goto_menu=1"
    exit /b 0
)
echo  %T_DLG_DEP_INVALID12%
pause
goto dialogos_sdk_ready_prompt

:dialogos_dependency_ready_prompt
cls
echo.
echo  ============================================================
echo             %T_DLG_DEP_READY_TITLE%
echo  ============================================================
echo.
echo  %T_DLG_DEP_READY_L1%
echo  %T_DLG_DEP_READY_L2%
echo.
echo  %T_DLG_DEP_CONTINUE%
echo  %T_DLG_DEP_BACK%
echo.
set "ddac_dep_ready_opt="
set /p "ddac_dep_ready_opt=%T_OPTION% "
if "%ddac_dep_ready_opt%"=="1" exit /b 0
if "%ddac_dep_ready_opt%"=="2" (
    set "ddac_dep_goto_menu=1"
    exit /b 0
)
echo.
echo  %T_DLG_DEP_INVALID12%
pause
goto dialogos_dependency_ready_prompt
:dialogos_erro_marcador
cls
echo.
echo   %T_DLG_ERR_MARK%
echo   %T_DLG_ERR_MARK2%
echo.
pause
goto main_menu

REM --------------------------------------------------------------------------------
REM --------------------------------------------------------------------------------
REM Código Python do módulo de Diálogos embutido com segurança para Windows.
REM O payload abaixo é Base64 dentro de comentários REM. O CMD nunca executa
REM o código Python diretamente. A rotina cria um .py temporário apenas quando
REM a Opção 1/2/3/5 precisa executá-lo, usando PowerShell para decodificar o payload.
REM --------------------------------------------------------------------------------
REM Em caso de queda de fluxo até aqui, todas as linhas continuam sendo apenas REM.
REM ##DDAC_DIALOGOS_PYTHON_START##
REM CgojIC0qLSBjb2Rpbmc6IHV0Zi04IC0qLQppbXBvcnQgYXN0CmltcG9ydCBiYXNlNjQKaW1w
REM b3J0IGlvCmltcG9ydCBqc29uCmltcG9ydCBvcwppbXBvcnQgcmUKaW1wb3J0IHN5cwppbXBv
REM cnQgdGltZQppbXBvcnQgdHJhY2ViYWNrCmltcG9ydCBzdWJwcm9jZXNzCmltcG9ydCB0ZW1w
REM ZmlsZQppbXBvcnQgY3N2CmltcG9ydCBoYXNobGliCmltcG9ydCBzaHV0aWwKaW1wb3J0IHRo
REM cmVhZGluZwppbXBvcnQgdXJsbGliLmVycm9yCmltcG9ydCB1cmxsaWIucGFyc2UKaW1wb3J0
REM IHVybGxpYi5yZXF1ZXN0CmltcG9ydCB1bmljb2RlZGF0YQppbXBvcnQgd2FybmluZ3MKZnJv
REM bSBjb25jdXJyZW50LmZ1dHVyZXMgaW1wb3J0IFRocmVhZFBvb2xFeGVjdXRvciwgd2FpdCwg
REM RklSU1RfQ09NUExFVEVELCBhc19jb21wbGV0ZWQKCnRyeToKICAgIFRFWFRfVFlQRVMgPSAo
REM YmFzZXN0cmluZywpCmV4Y2VwdCBOYW1lRXJyb3I6CiAgICBURVhUX1RZUEVTID0gKHN0ciwp
REM CgpkZWYgdGV4dG9fY29tcGF0aXZlbCh2YWxvciwgcGFkcmFvPXUiIiwgY2FtcG9zPSh1InRp
REM cG8iLCB1InRleHRvIiwgdSJ0ZXh0IiwgdSJ2YWxvciIsIHUidmFsdWUiLCB1Im5vbWUiLCB1
REM Im5hbWUiLCB1ImlkIikpOgogICAgIiIiTm9ybWFsaXphIHZhbG9yZXMgdGV4dHVhaXMgZGUg
REM bWFwYXMgZSBjYWNoZXMgc2VtIGNoYW1hciBtw6l0b2RvcyBkZSBzdHJpbmcgZW0gZGljdHMu
REM IiIiCiAgICBpZiBpc2luc3RhbmNlKHZhbG9yLCBURVhUX1RZUEVTKToKICAgICAgICByZXR1
REM cm4gdmFsb3IKICAgIGlmIGlzaW5zdGFuY2UodmFsb3IsIGRpY3QpOgogICAgICAgIGZvciBj
REM YW1wbyBpbiBjYW1wb3M6CiAgICAgICAgICAgIGNhbmRpZGF0byA9IHZhbG9yLmdldChjYW1w
REM bykKICAgICAgICAgICAgaWYgaXNpbnN0YW5jZShjYW5kaWRhdG8sIFRFWFRfVFlQRVMpOgog
REM ICAgICAgICAgICAgICAgcmV0dXJuIGNhbmRpZGF0bwogICAgICAgIHJldHVybiBwYWRyYW8K
REM ICAgIGlmIHZhbG9yIGlzIE5vbmU6CiAgICAgICAgcmV0dXJuIHBhZHJhbwogICAgdHJ5Ogog
REM ICAgICAgIHJldHVybiB1bmljb2RlKHZhbG9yKQogICAgZXhjZXB0IE5hbWVFcnJvcjoKICAg
REM ICAgICB0cnk6CiAgICAgICAgICAgIHJldHVybiBzdHIodmFsb3IpCiAgICAgICAgZXhjZXB0
REM IEV4Y2VwdGlvbjoKICAgICAgICAgICAgcmV0dXJuIHBhZHJhbwoKUFJFRklYTyA9ICJEREFD
REM XyIKRERBQ19CVUlMRCA9ICJWMTQ1LU9wdGlvbmFsT3JhY2xlLUZhbGxiYWNrLVBlcnNpc3Rl
REM bnRSZXZpZXdSZXBvcnRzLVJlZ3Jlc3Npb25UZXN0cyIKUEFTVEFfRU5UUkFEQV9OT01FID0g
REM IkREQUMtRElBTE9HT1MtRVhUUkFJRE9TIgpQQVNUQV9TQUlEQV9UUkFEVVpJRE9fTk9NRSA9
REM ICJEREFDLURJQUxPR09TLU1FU0NMQURPUyIKUEFTVEFfVFJBRFVDQU9fR09PR0xFX05PTUUg
REM PSAiRERBQy1EScOBTE9HT1MtVFJBRFVaSURPUyIKCiMgTm9tZXMgcmVhaXMgZGFzIHBhc3Rh
REM cyB2YXJpYW0gY29tIG8gaWRpb21hIGVzY29saGlkbyBubyBtZW51LgpOT01FU19QQVNUQVNf
REM SURJT01BID0gewogICAgMTogKHUiRERBQy1EacOhbG9nb3MtRXh0cmHDrWRvcyIsIHUiRERB
REM Qy1EacOhbG9nb3MtTWVzY2xhZG9zIiksCiAgICAyOiAodSJEREFDLUV4dHJhY3RlZC1EaWFs
REM b2d1ZXMiLCB1IkREQUMtTWVyZ2VkLURpYWxvZ3VlcyIpLAogICAgMzogKHUiRERBQy1EacOh
REM bG9nb3MtRXh0cmHDrWRvcyIsIHUiRERBQy1EacOhbG9nb3MtTWV6Y2xhZG9zIiksCn0KUEFT
REM VEFfRU5UUkFEQV9OT01FU19DT01QQVRJVkVJUyA9IHR1cGxlKGRpY3QuZnJvbWtleXMoCiAg
REM ICBub21lX2VudHJhZGEgZm9yIG5vbWVfZW50cmFkYSwgXyBpbiBOT01FU19QQVNUQVNfSURJ
REM T01BLnZhbHVlcygpCikpCgpOT01FU19MT0dfRVhUUkFDQU9fSURJT01BID0gewogICAgMTog
REM IlVuUmVuLUREQUMtRXh0cmHDp8Ojby1kZS1EacOhbG9nb3MudHh0IiwKICAgIDI6ICJVblJl
REM bi1EREFDLURpYWxvZ3VlLUV4dHJhY3Rpb24udHh0IiwKICAgIDM6ICJVblJlbi1EREFDLUV4
REM dHJhY2Npw7NuLWRlLURpw6Fsb2dvcy50eHQiLAp9Ck5PTUVTX0xPR19UUkFEVUNBT19JRElP
REM TUEgPSB7CiAgICAxOiAiVW5SZW4tRERBQy1UcmFkdcOnw6NvLWNvbS1Hb29nbGUtVHJhbnNs
REM YXRlLnR4dCIsCiAgICAyOiAiVW5SZW4tRERBQy1UcmFuc2xhdGlvbi13aXRoLUdvb2dsZS1U
REM cmFuc2xhdGUudHh0IiwKICAgIDM6ICJVblJlbi1EREFDLVRyYWR1Y2Npw7NuLWNvbi1Hb29n
REM bGUtVHJhbnNsYXRlLnR4dCIsCn0KTk9NRVNfTE9HX1JFSU5URUdSQUNBT19JRElPTUEgPSB7
REM CiAgICAxOiAiVW5SZW4tRERBQy1SZWludGVncmHDp8Ojby1kZS1EacOhbG9nb3MudHh0IiwK
REM ICAgIDI6ICJVblJlbi1EREFDLURpYWxvZ3VlLVJlaW5qZWN0aW9uLnR4dCIsCiAgICAzOiAi
REM VW5SZW4tRERBQy1SZWludGVncmFjacOzbi1kZS1EacOhbG9nb3MudHh0IiwKfQpOT01FU19D
REM QUNIRV9QRVJTSVNURU5URV9ESVJfSURJT01BID0gewogICAgMTogdSJEREFDLUNhY2hlLVRy
REM YWR1w6fDo28iLAogICAgMjogdSJEREFDLVRyYW5zbGF0aW9uLUNhY2hlIiwKICAgIDM6IHUi
REM RERBQy1DYWNow6ktZGUtVHJhZHVjY2nDs24iLAp9Ck5PTUVTX0NBQ0hFX1RFTVBfSURJT01B
REM ID0gewogICAgMTogdSJVblJlbi1EREFDLUdvb2dsZS1UcmFuc2xhdGUtY2FjaGUtdGVtcG9y
REM w6FyaW8uanNvbiIsCiAgICAyOiB1IlVuUmVuLUREQUMtR29vZ2xlLVRyYW5zbGF0ZS10ZW1w
REM b3JhcnktY2FjaGUuanNvbiIsCiAgICAzOiB1IlVuUmVuLUREQUMtR29vZ2xlLVRyYW5zbGF0
REM ZS1jYWNow6ktdGVtcG9yYWwuanNvbiIsCn0KTk9NRVNfRElBR05PU1RJQ09fSURJT01BID0g
REM ewogICAgMTogdSJVblJlbi1EREFDLURpYWduw7NzdGljby1Hb29nbGUtVHJhbnNsYXRlLnR4
REM dCIsCiAgICAyOiB1IlVuUmVuLUREQUMtR29vZ2xlLVRyYW5zbGF0ZS1EaWFnbm9zdGljcy50
REM eHQiLAogICAgMzogdSJVblJlbi1EREFDLURpYWduw7NzdGljby1kZS1Hb29nbGUtVHJhbnNs
REM YXRlLnR4dCIsCn0KTk9NRVNfRElBR05PU1RJQ09fRVNUUkVTU0VfSURJT01BID0gewogICAg
REM MTogdSJVblJlbi1EREFDLURpYWduw7NzdGljby1kZS1Fc3RyZXNzZS1Hb29nbGUtVHJhbnNs
REM YXRlLnR4dCIsCiAgICAyOiB1IlVuUmVuLUREQUMtR29vZ2xlLVRyYW5zbGF0ZS1TdHJlc3Mt
REM RGlhZ25vc3RpYy50eHQiLAogICAgMzogdSJVblJlbi1EREFDLURpYWduw7NzdGljby1kZS1F
REM c3Ryw6lzLWRlLUdvb2dsZS1UcmFuc2xhdGUudHh0IiwKfQpOT01FX0xPR19FWFRSQVRPUiA9
REM IE5vbmUKTk9NRV9MT0dfUkVJTkpFVE9SID0gTm9uZQpOT01FX0xPR19UUkFEVVRPUiA9IE5v
REM bmUKRVhURU5TT0VTID0gKCIucnB5IiwgIi5ycHltIiwgIi50eHQiLCAiX3Jlbi5weSIpClBB
REM U1RBU19JR05PUkFEQVMgPSB7Il9fcHljYWNoZV9fIiwgIi5naXQiLCBQQVNUQV9FTlRSQURB
REM X05PTUUsIFBBU1RBX1NBSURBX1RSQURVWklET19OT01FLCAiY2FjaGUiLCAidGwifQoKIyBS
REM ZWdyYSBnbG9iYWw6IGFycXVpdm9zLWJhc2UgY29uaGVjaWRvcyBxdWUgbnVuY2EgcG9kZW0g
REM Z2VyYXIgZW50cmFkYXMgZGUKIyB0cmFkdcOnw6NvIGF1dG9tw6F0aWNhLiBBIG1lc21hIHJl
REM Z3JhIMOpIGFwbGljYWRhIGFvIG1vdG9yIEREQUMsIGFvIE9yw6FjdWxvCiMgUmVuJ1B5IGUg
REM bm92YW1lbnRlIGFvIEPDqXJlYnJvIFNlbcOibnRpY28gY29tbyBkZWZlc2EgZmluYWwuCkFS
REM UVVJVk9TX0dMT0JBSVNfSUdOT1JBRE9TX0VYVFJBQ0FPID0gZnJvemVuc2V0KCgKICAgIHUi
REM c2NyaXB0LXBvZW1yZXNwb25zZXMucnB5IiwKKSkKCmRlZiBhcnF1aXZvX2dsb2JhbG1lbnRl
REM X2lnbm9yYWRvX2V4dHJhY2FvKHJlbGF0aXZvKToKICAgIGNhbWluaG8gPSByZWxhdGl2byBv
REM ciB1IiIKICAgIHRyeToKICAgICAgICBjYW1pbmhvID0gY2FtaW5oby5yZXBsYWNlKCJcXCIs
REM ICIvIikKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAgYmFzZSA9IG9z
REM LnBhdGguYmFzZW5hbWUoY2FtaW5obykucnN0cmlwKCIvIikucnNwbGl0KCIvIiwgMSlbLTFd
REM Lmxvd2VyKCkKICAgIHJldHVybiBiYXNlIGluIEFSUVVJVk9TX0dMT0JBSVNfSUdOT1JBRE9T
REM X0VYVFJBQ0FPCgoKTUFQQVNfQ09NUEFUSVZFSVMgPSAodSJfbWFwYS1kZGFjLmpzb24iLCB1
REM Il9kZGFjLW1hcC5qc29uIikKTk9NRV9NQVBBID0gTUFQQVNfQ09NUEFUSVZFSVNbMF0KSU5E
REM RU5UQUNBT19TQUlEQSA9IHUiICAgICIKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0K
REM IyBUZXh0b3MgZGEgdGVsYSBub3MgdHLDqnMgaWRpb21hczogMSA9IFBvcnR1Z3XDqnMsIDIg
REM PSBFbmdsaXNoLCAzID0gRXNwYW5ob2wuCiMgTyBpZGlvbWEgZXNjb2xoaWRvIG5vIG1lbnUg
REM ZG8gLmJhdCBjaGVnYSBjb21vIHRlcmNlaXJvIHBhcmFtZXRyby4KIyAtLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLQpJRElPTUEgPSAxCk1PRE9fRVhJQklDQU8gPSB1InJlc3VtaWRvIgpO
REM T01FX0xPR19FWFRSQVRPUiA9IE5PTUVTX0xPR19FWFRSQUNBT19JRElPTUEuZ2V0KElESU9N
REM QSwgTk9NRVNfTE9HX0VYVFJBQ0FPX0lESU9NQVsxXSkKCgpkZWYgZXhpYmljYW9fZGV0YWxo
REM YWRhKCk6CiAgICByZXR1cm4gRmFsc2UKCgpkZWYgYmFycmFfcHJvZ3Jlc3NvKGF0dWFsLCB0
REM b3RhbCwgbGFyZ3VyYT0yNCk6CiAgICB0b3RhbCA9IG1heCgxLCB0b3RhbCkKICAgIGF0dWFs
REM ID0gbWF4KDAsIG1pbihhdHVhbCwgdG90YWwpKQogICAgcHJlZW5jaGlkbyA9IGludChyb3Vu
REM ZChsYXJndXJhICogKGZsb2F0KGF0dWFsKSAvIGZsb2F0KHRvdGFsKSkpKQogICAgaWYgcHJl
REM ZW5jaGlkbyA+PSBsYXJndXJhOgogICAgICAgIGNvcnBvID0gdSI9IiAqIGxhcmd1cmEKICAg
REM IGVsaWYgcHJlZW5jaGlkbyA8PSAwOgogICAgICAgIGNvcnBvID0gdSI+IiArIHUiICIgKiAo
REM bGFyZ3VyYSAtIDEpCiAgICBlbHNlOgogICAgICAgIGNvcnBvID0gdSI9IiAqIG1heCgwLCBw
REM cmVlbmNoaWRvIC0gMSkgKyB1Ij4iICsgdSIgIiAqIChsYXJndXJhIC0gcHJlZW5jaGlkbykK
REM ICAgIHJldHVybiB1Ilt7fV0iLmZvcm1hdChjb3JwbykKCgpkZWYgdmVsb2NpZGFkZV9lX2V0
REM YShjb25jbHVpZG9zLCB0b3RhbCwgaW5pY2lvKToKICAgIGRlY29ycmlkbyA9IG1heCgwLjAw
REM MSwgdGltZS50aW1lKCkgLSBpbmljaW8pCiAgICB2ZWxvY2lkYWRlID0gZmxvYXQoY29uY2x1
REM aWRvcykgLyBkZWNvcnJpZG8gaWYgY29uY2x1aWRvcyBlbHNlIDAuMAogICAgcmVzdGFudGUg
REM PSBtYXgoMCwgdG90YWwgLSBjb25jbHVpZG9zKQogICAgZXRhID0gZmxvYXQocmVzdGFudGUp
REM IC8gdmVsb2NpZGFkZSBpZiB2ZWxvY2lkYWRlIGVsc2UgMC4wCiAgICByZXR1cm4gdmVsb2Np
REM ZGFkZSwgZXRhCk5PTUVfTE9HX1JFSU5KRVRPUiA9IE5PTUVTX0xPR19SRUlOVEVHUkFDQU9f
REM SURJT01BLmdldChJRElPTUEsIE5PTUVTX0xPR19SRUlOVEVHUkFDQU9fSURJT01BWzFdKQpO
REM T01FX0xPR19UUkFEVVRPUiA9IE5PTUVTX0xPR19UUkFEVUNBT19JRElPTUEuZ2V0KElESU9N
REM QSwgTk9NRVNfTE9HX1RSQURVQ0FPX0lESU9NQVsxXSkKCgpkZWYgYXR1YWxpemFyX25vbWVz
REM X3Bhc3Rhc19wb3JfaWRpb21hKCk6CiAgICBnbG9iYWwgUEFTVEFfRU5UUkFEQV9OT01FLCBQ
REM QVNUQV9TQUlEQV9UUkFEVVpJRE9fTk9NRSwgUEFTVEFfVFJBRFVDQU9fR09PR0xFX05PTUUs
REM IFBBU1RBU19JR05PUkFEQVMKICAgIGdsb2JhbCBHT09HTEVfQ0FDSEVfUEVSU0lTVEVOVEVf
REM RElSLCBHT09HTEVfQ0FDSEVfTk9NRSwgR09PR0xFX0NBQ0hFX0RJQUdOT1NUSUNPX05PTUUs
REM IEdPT0dMRV9DQUNIRV9FU1RSRVNTRV9OT01FCiAgICBlbnRyYWRhLCBzYWlkYSA9IE5PTUVT
REM X1BBU1RBU19JRElPTUEuZ2V0KElESU9NQSwgTk9NRVNfUEFTVEFTX0lESU9NQVsxXSkKICAg
REM IG5vbWVzX3RyYWR1Y2FvID0gezE6IHUiRERBQy1EacOhbG9nb3MtVHJhZHV6aWRvcyIsIDI6
REM IHUiRERBQy1UcmFuc2xhdGVkLURpYWxvZ3VlcyIsIDM6IHUiRERBQy1EacOhbG9nb3MtVHJh
REM ZHVjaWRvcyJ9CiAgICBQQVNUQV9FTlRSQURBX05PTUUgPSBlbnRyYWRhCiAgICBQQVNUQV9T
REM QUlEQV9UUkFEVVpJRE9fTk9NRSA9IHNhaWRhCiAgICBQQVNUQV9UUkFEVUNBT19HT09HTEVf
REM Tk9NRSA9IG5vbWVzX3RyYWR1Y2FvLmdldChJRElPTUEsIG5vbWVzX3RyYWR1Y2FvWzFdKQog
REM ICAgR09PR0xFX0NBQ0hFX1BFUlNJU1RFTlRFX0RJUiA9IE5PTUVTX0NBQ0hFX1BFUlNJU1RF
REM TlRFX0RJUl9JRElPTUEuZ2V0KElESU9NQSwgTk9NRVNfQ0FDSEVfUEVSU0lTVEVOVEVfRElS
REM X0lESU9NQVsxXSkKICAgIEdPT0dMRV9DQUNIRV9OT01FID0gTk9NRVNfQ0FDSEVfVEVNUF9J
REM RElPTUEuZ2V0KElESU9NQSwgTk9NRVNfQ0FDSEVfVEVNUF9JRElPTUFbMV0pCiAgICBHT09H
REM TEVfQ0FDSEVfRElBR05PU1RJQ09fTk9NRSA9IE5PTUVTX0RJQUdOT1NUSUNPX0lESU9NQS5n
REM ZXQoSURJT01BLCBOT01FU19ESUFHTk9TVElDT19JRElPTUFbMV0pCiAgICBHT09HTEVfQ0FD
REM SEVfRVNUUkVTU0VfTk9NRSA9IE5PTUVTX0RJQUdOT1NUSUNPX0VTVFJFU1NFX0lESU9NQS5n
REM ZXQoSURJT01BLCBOT01FU19ESUFHTk9TVElDT19FU1RSRVNTRV9JRElPTUFbMV0pCiAgICBQ
REM QVNUQVNfSUdOT1JBREFTID0geyJfX3B5Y2FjaGVfXyIsICIuZ2l0IiwgImNhY2hlIiwgIkRE
REM QUMtR2FtZSIsICJEREFDLVRyYWR1emlkbyIsICJ0bCJ9CiAgICAjIElnbm9yYSBhcyBwYXN0
REM YXMgZGUgc2HDrWRhIGRlIFRPRE9TIG9zIGlkaW9tYXMsIHNlbsOjbyB1bWEgcm9kYWRhIGVt
REM IEVOL0VTCiAgICAjIHZhcnJlcmlhIGEgcGFzdGEgZ2VyYWRhIHBvciB1bWEgcm9kYWRhIGFu
REM dGVyaW9yIGVtIFBUIChlIHZpY2UtdmVyc2EpLgogICAgZm9yIF9lbnRyYWRhLCBfc2FpZGEg
REM aW4gTk9NRVNfUEFTVEFTX0lESU9NQS52YWx1ZXMoKToKICAgICAgICBQQVNUQVNfSUdOT1JB
REM REFTLmFkZChfZW50cmFkYSkKICAgICAgICBQQVNUQVNfSUdOT1JBREFTLmFkZChfc2FpZGEp
REM CiAgICBmb3IgX25vbWVfdHJhZHVjYW8gaW4gKHUiRERBQy1EacOhbG9nb3MtVHJhZHV6aWRv
REM cyIsIHUiRERBQy1UcmFuc2xhdGVkLURpYWxvZ3VlcyIsIHUiRERBQy1EacOhbG9nb3MtVHJh
REM ZHVjaWRvcyIsIHUiRERBQy1EaWFsb2dvcy1UcmFkdXppZG9zIiwgdSJEREFDLURpYWxvZ29z
REM LVRyYWR1Y2lkb3MiKToKICAgICAgICBQQVNUQVNfSUdOT1JBREFTLmFkZChfbm9tZV90cmFk
REM dWNhbykKCk1FTlNBR0VOUyA9IHsKICAgIDE6IHsKICAgICAgICAiY2FiX2V4dHJhaXIiOiB1
REM IiBEREFDIC0gRXh0cmFpciBEacOhbG9nb3MiLAogICAgICAgICJjYWJfcmVpbmpldGFyIjog
REM dSIgRERBQyAtIFJlaW5qZXRhciBUcmFkdcOnw6NvIiwKICAgICAgICAicGFzdGFfZXNjYW5l
REM YWRhIjogdSJQYXN0YSBlc2NhbmVhZGE6IHswfSIsCiAgICAgICAgInBhc3RhX3NhaWRhIjog
REM dSJQYXN0YSBkZSBzYcOtZGE6ICB7MH0iLAogICAgICAgICJwYXN0YV90cmFkdWNhbyI6IHUi
REM UGFzdGEgY29tIHRyYWR1w6fDo286IHswfSIsCiAgICAgICAgInBhc3RhX29yaWdpbmFsIjog
REM dSJQYXN0YSBvcmlnaW5hbDogICAgIHswfSIsCiAgICAgICAgInBhc3RhX3NhaWRhMiI6IHUi
REM UGFzdGEgZGUgc2HDrWRhOiAgICAgezB9IiwKICAgICAgICAiZXRhcGExX2V4dHJhaXIiOiB1
REM IkV0YXBhIDEvMzogbG9jYWxpemFuZG8gYXJxdWl2b3MgLnJweS8ucnB5bS8udHh0Li4uIiwK
REM ICAgICAgICAiZXRhcGEyX2V4dHJhaXIiOiB1IkV0YXBhIDIvMzogaWRlbnRpZmljYW5kbyBw
REM ZXJzb25hZ2VucyBjb20gbm9tZSBkaW7Dom1pY28uLi4iLAogICAgICAgICJldGFwYTNfZXh0
REM cmFpciI6IHUiRXRhcGEgMy8zOiBleHRyYWluZG8gZGnDoWxvZ28gZSByZWNyaWFuZG8gYSBl
REM c3RydXR1cmEgZW0gezB9Li4uIiwKICAgICAgICAiYXJxdWl2b3NfZW5jb250cmFkb3MiOiB1
REM IiAgezB9IGFycXVpdm8ocykgZW5jb250cmFkbyhzKSIsCiAgICAgICAgInZhcnNfZGluYW1p
REM Y2FzIjogdSIgIHswfSB2YXJpw6F2ZWwoaXMpIGRlIG5vbWUgZGluw6JtaWNvIGVuY29udHJh
REM ZGEocykiLAogICAgICAgICJlcnJvIjogdSJFUlJPIiwKICAgICAgICAiZXJyb19hcnF1aXZv
REM IjogdSJFUlJPIHswfSAgLT4gIHsxfSIsCiAgICAgICAgIm9rX2xpbmhhcyI6IHUiT0sgIHsw
REM fSAgLT4gIHsxfSBsaW5oYShzKSIsCiAgICAgICAgInJlc19lc2NhbmVhZG9zIjogdSJBcnF1
REM aXZvcyBlc2NhbmVhZG9zOiB7MH0iLAogICAgICAgICJyZXNfY29tX2RpYWxvZ28iOiB1IkFy
REM cXVpdm9zIGNvbSBkacOhbG9nbyBleHRyYcOtZG86IHswfSIsCiAgICAgICAgInJlc19saW5o
REM YXMiOiB1IkxpbmhhcyBkZSBkacOhbG9nbyBleHRyYcOtZGFzOiB7MH0iLAogICAgICAgICJy
REM ZXNfc2VtX2RpYWxvZ28iOiB1IkFycXVpdm9zIHNlbSBkacOhbG9nbyBkZXRlY3RhZG8gKHsw
REM fSk6IiwKICAgICAgICAiaW1wMSI6IHUiSU1QT1JUQU5URTogbsOjbyBhcGFndWUsIHJlbm9t
REM ZWllIG5lbSBlZGl0ZSBvIGFycXVpdm8gezB9IHF1ZSBmaWNhIiwKICAgICAgICAiaW1wMiI6
REM IHUibmEgcmFpeiBkZSB7MH0gLS0gZWxlIGd1YXJkYSBhIHBvc2nDp8OjbyBkZSBjYWRhIHRl
REM eHRvIHByYSByZWluamXDp8Ojby4iLAogICAgICAgICJpbXAzIjogdSJBbyB0cmFkdXppciwg
REM ZWRpdGUgc8OzIG8gdGV4dG8gZW50cmUgYXNwYXMgZGUgY2FkYSBsaW5oYSwgbWFudGVuZG8g
REM YXMiLAogICAgICAgICJpbXA0IjogdSJhc3BhcyBubyBsdWdhci4iLAogICAgICAgICJpbXA1
REM IjogdSJOw6NvIGFkaWNpb25lIG5lbSByZW1vdmEgbGluaGFzLiBRdWFuZG8gdGVybWluYXIs
REM IGFicmEgZXN0ZSBwcm9ncmFtYSIsCiAgICAgICAgImltcDYiOiB1ImRlIG5vdm8gZSB1c2Ug
REM YSBvcMOnw6NvIDMgcGFyYSByZWludGVncmFyLiIsCiAgICAgICAgImxvZ19zYWx2byI6IHUi
REM TG9nIHNhbHZvIGVtOiB7MH0iLAogICAgICAgICJlcnJfcGFzdGFfZW50cmFkYSI6IHUiTmVu
REM aHVtYSBwYXN0YSBkZSBkacOhbG9nb3MgZXh0cmHDrWRvcyBjb21wYXTDrXZlbCBmb2kgZW5j
REM b250cmFkYS4gVXNlIGEgb3DDp8OjbyAxIChFeHRyYWlyIGRpw6Fsb2dvcykgcHJpbWVpcm8u
REM IiwKICAgICAgICAicmVpbmpfbXVsdGlwbGFzX3RpdHVsbyI6IHUiRm9yYW0gZW5jb250cmFk
REM YXMgZHVhcyBvdSBtYWlzIHBhc3RhcyBkZSBkacOhbG9nb3MuIEVzY29saGEgcXVhbCB2ZXJz
REM w6NvIGRlc2VqYSByZWludGVncmFyOiIsCiAgICAgICAgInJlaW5qX211bHRpcGxhc19vcGNh
REM byI6IHUiICB7MH0pIHsxfSIsCiAgICAgICAgInJlaW5qX211bHRpcGxhc19wcm9tcHQiOiB1
REM IkVzY29saGEgdW1hIG9ww6fDo286ICIsCiAgICAgICAgInJlaW5qX211bHRpcGxhc19pbnZh
REM bGlkYSI6IHUiT3DDp8OjbyBpbnbDoWxpZGEuIEVzY29saGEgdW1hIGRhcyBvcMOnw7VlcyBh
REM Y2ltYS4iLAogICAgICAgICJyZWlual9zZWxlY2FvX3RpdHVsbyI6IHUiRVNDT0xIQSBBIEZP
REM TlRFIERBIFRSQURVw4fDg08iLAogICAgICAgICJyZWlual9zZWxlY2FvX2l0ZW0iOiB1Ilt7
REM MH1dIHsxfSIsCiAgICAgICAgInJlaW5qX3NlbGVjYW9fcGFzdGEiOiB1IiAgICBQYXN0YTog
REM ezB9IiwKICAgICAgICAicmVpbmpfc2VsZWNhb19jYW1pbmhvIjogdSIgICAgQ2FtaW5obzog
REM ezB9IiwKICAgICAgICAicmVpbmpfc2VsZWNhb19wcm9tcHQiOiB1IkRpZ2l0ZSBvIG7Dum1l
REM cm8gZGEgb3DDp8OjbzogIiwKICAgICAgICAicmVpbmpfc2VsZWNhb19pbnZhbGlkYSI6IHUi
REM T3DDp8OjbyBpbnbDoWxpZGEuIERpZ2l0ZSBvIG7Dum1lcm8gZGUgdW1hIGRhcyBvcMOnw7Vl
REM cyBhY2ltYS4iLAogICAgICAgICJyZWlual90aXBvX21hbnVhbCI6IHUiRXh0cmHDp8OjbyAv
REM IHRyYWR1w6fDo28gbWFudWFsIiwKICAgICAgICAicmVpbmpfdGlwb19nb29nbGUiOiB1Ikdv
REM b2dsZSBUcmFuc2xhdGUgLyB0cmFkdcOnw6NvIiwKICAgICAgICAicmpfbW9kb190aXR1bG8i
REM OiB1Ik1vZG8gZGUgcmVpbnRlZ3Jhw6fDo28iLAogICAgICAgICJyal9tb2RvX25vcm1hbCI6
REM IHUiMSkgUmVpbnRlZ3Jhw6fDo28gbm9ybWFsIChyZWNvbWVuZGFkbykiLAogICAgICAgICJy
REM al9tb2RvX3NlZ3VybyI6IHUiMikgUmVpbnRlZ3Jhw6fDo28gc2VndXJhIChiYWNrdXAgKyB2
REM YWxpZGHDp8OjbyBjb21wbGV0YSkiLAogICAgICAgICJyal9tb2RvX3Byb21wdCI6IHUiRXNj
REM b2xoYSB1bSBtb2RvOiAiLAogICAgICAgICJyal9tb2RvX2ludmFsaWRvIjogdSJPcMOnw6Nv
REM IGludsOhbGlkYS4gRXNjb2xoYSAxIG91IDIuIiwKICAgICAgICAicmpfdmFsaWRhY2FvX3By
REM ZSI6IHUiVkFMSURBw4fDg08gQU5URVMgREEgUkVJTlRFR1JBw4fDg08iLAogICAgICAgICJy
REM al92YWxpZGFjYW9fcG9zIjogdSJWQUxJREHDh8ODTyBBUMOTUyBBIFJFSU5URUdSQcOHw4NP
REM IiwKICAgICAgICAicmpfdmFsaWRhY2FvX29rIjogdSJWYWxpZGHDp8OjbyBjb25jbHXDrWRh
REM IHNlbSBkaWZlcmVuw6dhcyBpbmVzcGVyYWRhcy4iLAogICAgICAgICJyal92YWxpZGFjYW9f
REM ZmFsaG91IjogdSJBIHZhbGlkYcOnw6NvIGVuY29udHJvdSBwcm9ibGVtYXMuIEEgcmVpbnRl
REM Z3Jhw6fDo28gZm9pIHJlY3VzYWRhLiIsCiAgICAgICAgInJqX2JhY2t1cF9vayI6IHUiQmFj
REM a3VwIGRhIHNhw61kYSBhbnRlcmlvciBjcmlhZG8gZW06IHswfSIsCiAgICAgICAgInJqX2Jh
REM Y2t1cF9uYW8iOiB1Ik5lbmh1bWEgc2HDrWRhIGFudGVyaW9yIHBhcmEgYmFja3VwLiIsCiAg
REM ICAgICAgInJqX3RleHRvc19hbHRlcmFkb3MiOiB1IlRleHRvcyByZWFsbWVudGUgYWx0ZXJh
REM ZG9zIiwKICAgICAgICAicmpfdGV4dG9zX2lndWFpcyI6IHUiVGV4dG9zIHNlbSBhbHRlcmHD
REM p8OjbyIsCiAgICAgICAgInJqX2FycXVpdm9zX29rIjogdSJBcnF1aXZvcyB2YWxpZGFkb3Mi
REM LAogICAgICAgICJyal9hcnF1aXZvc19lc3BlcmFkb3MiOiB1IkFycXVpdm9zIGVzcGVyYWRv
REM cyBwZWxvIG1hcGEiLAogICAgICAgICJyal9lbnRyYWRhc19lc3BlcmFkYXMiOiB1IkVudHJh
REM ZGFzIGVzcGVyYWRhcyBwZWxvIG1hcGEiLAogICAgICAgICJyal9lbnRyYWRhc19lbmNvbnRy
REM YWRhcyI6IHUiRW50cmFkYXMgZW5jb250cmFkYXMiLAogICAgICAgICJyal9kaWZlcmVuY2Fz
REM IjogdSJEaWZlcmVuw6dhcyBpbmVzcGVyYWRhcyIsCiAgICAgICAgInJqX21vZGlmaWNhZG9z
REM IjogdSJBcnF1aXZvcyBtb2RpZmljYWRvcyIsCiAgICAgICAgInJqX3RlbXBvIjogdSJUZW1w
REM byB0b3RhbCIsCiAgICAgICAgInJqX3ZlbG9jaWRhZGUiOiB1IlZlbG9jaWRhZGUgbcOpZGlh
REM IiwKICAgICAgICAiZXJyX21hcGEiOiB1IkFycXVpdm8gJ3swfScgbsOjbyBlbmNvbnRyYWRv
REM IGRlbnRybyBkZSB7MX0uIFVzZSBhIG9ww6fDo28gMSBwcmltZWlyby4iLAogICAgICAgICJl
REM cnJfbGVyX21hcGEiOiB1IkZhbGhhIGFvIGxlciB7MH06IHsxfSIsCiAgICAgICAgImV0YXBh
REM MV9yZWluaiI6IHUiRXRhcGEgMS8yOiBsb2NhbGl6YW5kbyBhcnF1aXZvcyB0cmFkdXppZG9z
REM IGVtIHswfS4uLiIsCiAgICAgICAgImV0YXBhMl9yZWluaiI6IHUiRXRhcGEgMi8yOiB2YWxp
REM ZGFuZG8gZSByZWluamV0YW5kbyBjYWRhIHRleHRvIG5hIHBvc2nDp8OjbyBvcmlnaW5hbC4u
REM LiIsCiAgICAgICAgInNlbV9tYXBhIjogdSJTRU0gTUFQQSAgezB9ICAoc2VtIGVudHJhZGEg
REM ZW0gezF9LCBwdWxhZG8pIiwKICAgICAgICAiZXJyb19sZXJfdHJhZCI6IHUiRVJSTyAgezB9
REM ICAtPiAgZmFsaGEgYW8gbGVyIHRyYWR1w6fDo286IHsxfSIsCiAgICAgICAgImVycm9faW5l
REM c3BlcmFkbyI6IHUiRVJSTyAgezB9ICAtPiAgZmFsaGEgaW5lc3BlcmFkYTogezF9IiwKICAg
REM ICAgICAiZmFsaGEiOiB1IkZBTEhBICB7MH0iLAogICAgICAgICJyZXNfdHJhZF9lbmNvbnRy
REM YWRvcyI6IHUiQXJxdWl2b3MgdHJhZHV6aWRvcyBlbmNvbnRyYWRvczogezB9IiwKICAgICAg
REM ICAicmVzX3JlaW5qX29rIjogdSJBcnF1aXZvcyByZWluamV0YWRvcyBjb20gc3VjZXNzbzog
REM ezB9IiwKICAgICAgICAicmVzX3JlaW5qX2ZhbGhhIjogdSJBcnF1aXZvcyBjb20gZmFsaGEg
REM KG7Do28gYWx0ZXJhZG9zKTogezB9IiwKICAgICAgICAicmVzX3JlaW5qX2xpbmhhcyI6IHUi
REM TGluaGFzIHJlaW5qZXRhZGFzIG5vIHRvdGFsOiB7MH0iLAogICAgICAgICJyZXNfc2VtX21h
REM cGEiOiB1IkFycXVpdm9zIHNlbSBlbnRyYWRhIG5vIG1hcGEgKHB1bGFkb3MpOiB7MH0iLAog
REM ICAgICAgICJva19yZWluamV0YWRhcyI6IHUiT0sgIHswfSAgLT4gIHsxfSBsaW5oYShzKSBy
REM ZWluamV0YWRhKHMpIiwKICAgICAgICAicHJvbnRvMSI6IHUiQSBwYXN0YSBkZSBkacOhbG9n
REM b3MgbWVzY2xhZG9zIGVzdMOhIHByb250YSBlbTogezB9IiwKICAgICAgICAicHJvbnRvMiI6
REM IHUiUmVjb3J0ZSBhIHBhc3RhICd7MH0nIChkZW50cm8gZGUgezF9KSBlIGNvbGUgcG9yIGNp
REM bWEgZGEgcGFzdGEiLAogICAgICAgICJwcm9udG8zIjogdSInezB9JyBvcmlnaW5hbCBkbyBt
REM b2QsIHN1YnN0aXR1aW5kbywgcGFyYSBhcGxpY2FyIGEgdHJhZHXDp8Ojby4iLAogICAgICAg
REM ICJhdGVuY2FvMSI6IHUiQVRFTsOHw4NPOiB7MH0gYXJxdWl2byhzKSBOw4NPIGZvcmFtIHJl
REM aW5qZXRhZG9zIHBvciBzZWd1cmFuw6dhIC0tIHZlamEiLAogICAgICAgICJhdGVuY2FvMiI6
REM IHUib3MgZGV0YWxoZXMgYWNpbWEgZSBubyBsb2cuIE5lbmh1bSBhcnF1aXZvIG9yaWdpbmFs
REM IGZvaSBtb2RpZmljYWRvLiIsCiAgICAgICAgInJqX2NvbnRhZ2VtIjogdSJjb250YWdlbSBu
REM w6NvIGJhdGU6IG8gbWFwYSBlc3BlcmEgezB9IHRleHRvKHMpLCBtYXMgbyBhcnF1aXZvIHRy
REM YWR1emlkbyB0ZW0gezF9LiBOw4NPIGFkaWNpb25lIG5lbSByZW1vdmEgbGluaGFzIGRlIHRl
REM eHRvIC0tIGVkaXRlIHPDsyBvIGNvbnRlw7pkbyBlbnRyZSBhc3BhcyBkZSBjYWRhIHVtYS4i
REM LAogICAgICAgICJyal9zZW1fb3JpZ2luYWwiOiB1ImFycXVpdm8gb3JpZ2luYWwgbsOjbyBl
REM bmNvbnRyYWRvOiB7MH0iLAogICAgICAgICJyal9saW5oYV9pbmV4aXN0ZW50ZSI6IHUibGlu
REM aGEgezB9IG7Do28gZXhpc3RlIG1haXMgbm8gYXJxdWl2byBvcmlnaW5hbCAobyBtb2QgZm9p
REM IGFsdGVyYWRvIGRlc2RlIGEgZXh0cmHDp8Ojbz8pIiwKICAgICAgICAicmpfbGluaGFfbXVk
REM b3UiOiB1ImxpbmhhIHswfSAoY29sdW5hcyB7MX0tezJ9KSBkbyBhcnF1aXZvIG9yaWdpbmFs
REM IG11ZG91IGRlc2RlIGEgZXh0cmHDp8OjbyAoZXNwZXJhZG86IHszIXJ9IC8gZW5jb250cmFk
REM bzogezQhcn0pIiwKICAgICAgICAibG9nX3RhZ19pbmZvIjogdSJJTkZPIiwKICAgICAgICAi
REM bG9nX3RhZ19hdmlzbyI6IHUiQVZJU08iLAogICAgICAgICJsb2dfdGFnX2Vycm8iOiB1IkVS
REM Uk8iLAogICAgICAgICJsb2dfY2FiX2V4dHJhdG9yIjogdSJEREFDIEV4dHJhw6fDo28gZGUg
REM RGnDoWxvZ29zIC0gSU7DjUNJTyBEQSBFWEVDVcOHw4NPIiwKICAgICAgICAibG9nX2NhYl9y
REM ZWluamV0b3IiOiB1IkREQUMgUmVpbnRlZ3Jhw6fDo28gZGUgRGnDoWxvZ29zIC0gSU7DjUNJ
REM TyBEQSBFWEVDVcOHw4NPIiwKICAgICAgICAibG9nX2RhdGFob3JhIjogdSJEYXRhL0hvcmE6
REM IHswfSIsCiAgICAgICAgImxvZ19wYXN0YV9lc2NhbmVhZGEiOiB1IlBhc3RhIGVzY2FuZWFk
REM YTogezB9IiwKICAgICAgICAibG9nX3Bhc3RhX3NhaWRhIjogdSJQYXN0YSBkZSBzYcOtZGE6
REM IHswfSIsCiAgICAgICAgImxvZ19ldGFwYTFfZXh0cmFpciI6IHUiRXRhcGEgMS8zOiB7MH0g
REM YXJxdWl2byhzKSAucnB5Ly5ycHltLy50eHQgbG9jYWxpemFkbyhzKSIsCiAgICAgICAgImxv
REM Z19ldGFwYTJfZXh0cmFpciI6IHUiRXRhcGEgMi8zOiB7MH0gdmFyacOhdmVsKGlzKSBkZSBu
REM b21lIGRpbsOibWljbzogezF9IiwKICAgICAgICAibG9nX2V0YXBhM19leHRyYWlyIjogdSJF
REM dGFwYSAzLzM6IGluaWNpYW5kbyBleHRyYcOnw6NvIGRlIGRpw6Fsb2dvIiwKICAgICAgICAi
REM bG9nX2ZhbGhhX2xlciI6IHUiRmFsaGEgYW8gbGVyIHswfTogezF9IiwKICAgICAgICAibG9n
REM X3NlbV9kaWFsb2dvIjogdSJTZW0gZGnDoWxvZ28gZGV0ZWN0YWRvOiB7MH0iLAogICAgICAg
REM ICJsb2dfbGluaGFzIjogdSJ7MH0gbGluaGEocykiLAogICAgICAgICJsb2dfcmVzX2VzY2Fu
REM ZWFkb3MiOiB1IkFycXVpdm9zIGVzY2FuZWFkb3MiLAogICAgICAgICJsb2dfcmVzX2NvbV9k
REM aWFsb2dvIjogdSJBcnF1aXZvcyBjb20gZGnDoWxvZ28iLAogICAgICAgICJsb2dfcmVzX3Nl
REM bV9kaWFsb2dvIjogdSJBcnF1aXZvcyBzZW0gZGnDoWxvZ28iLAogICAgICAgICJsb2dfcmVz
REM X2xpbmhhcyI6IHUiTGluaGFzIGRlIGRpw6Fsb2dvIGV4dHJhw61kYXMiLAogICAgICAgICJs
REM b2dfcmVzX2Vycm9zIjogdSJFcnJvcyBkZSBsZWl0dXJhIiwKICAgICAgICAibG9nX3Bhc3Rh
REM X3RyYWR1Y2FvIjogdSJQYXN0YSBjb20gdHJhZHXDp8OjbyAoezB9KTogezF9IiwKICAgICAg
REM ICAibG9nX3Bhc3RhX29yaWdpbmFsIjogdSJQYXN0YSBvcmlnaW5hbCAoam9nbyk6IHswfSIs
REM CiAgICAgICAgImxvZ19ldGFwYTFfcmVpbmoiOiB1IkV0YXBhIDEvMjogezB9IGFycXVpdm8o
REM cykgdHJhZHV6aWRvKHMpIGxvY2FsaXphZG8ocykiLAogICAgICAgICJsb2dfZXRhcGEyX3Jl
REM aW5qIjogdSJFdGFwYSAyLzI6IGluaWNpYW5kbyByZWluamXDp8OjbyIsCiAgICAgICAgImxv
REM Z19zZW1fbWFwYV9hcnEiOiB1IkFycXVpdm8gc2VtIGVudHJhZGEgZW0gezB9LCBwdWxhZG86
REM IHsxfSIsCiAgICAgICAgImxvZ19mYWxoYV9sZXJfdHJhZCI6IHUiRmFsaGEgYW8gbGVyIHRy
REM YWR1w6fDo28gZGUgezB9OiB7MX0iLAogICAgICAgICJsb2dfZmFsaGFfaW5lc3BlcmFkYSI6
REM IHUiRmFsaGEgaW5lc3BlcmFkYSBhbyByZWluamV0YXIgezB9OiB7MX0iLAogICAgICAgICJs
REM b2dfZmFsaGFfcmVpbmpldGFyIjogdSJGYWxoYSBhbyByZWluamV0YXIgezB9OiIsCiAgICAg
REM ICAgImxvZ19saW5oYXNfcmVpbmoiOiB1InswfSBsaW5oYShzKSByZWluamV0YWRhKHMpIiwK
REM ICAgICAgICAibG9nX3Jlc190cmFkX2VuY29udHJhZG9zIjogdSJBcnF1aXZvcyB0cmFkdXpp
REM ZG9zIGVuY29udHJhZG9zIiwKICAgICAgICAibG9nX3Jlc19vayI6IHUiUmVpbmpldGFkb3Mg
REM Y29tIHN1Y2Vzc28iLAogICAgICAgICJsb2dfcmVzX2ZhbGhhcyI6IHUiRmFsaGFzIChuw6Nv
REM IGFsdGVyYWRvcykiLAogICAgICAgICJsb2dfcmVzX3NlbV9tYXBhIjogdSJTZW0gZW50cmFk
REM YSBubyBtYXBhIChwdWxhZG9zKSIsCiAgICAgICAgImxvZ19yZXNfbGluaGFzX3JlaW5qIjog
REM dSJMaW5oYXMgcmVpbmpldGFkYXMiLAogICAgICAgICJtb2RvX2Rlc2NvbmhlY2lkbyI6IHUi
REM TW9kbyBkZXNjb25oZWNpZG86IHswIXJ9IiwKICAgICAgICAidF9zZW1fZXh0cmFjYW8iOiB1
REM Ik5lbmh1bWEgcGFzdGEgZGUgZGnDoWxvZ29zIGV4dHJhw61kb3MgY29tcGF0w612ZWwgZm9p
REM IGVuY29udHJhZGEuIFVzZSBhIG9ww6fDo28gMSBwcmltZWlyby4iLAogICAgICAgICJ0X21h
REM cGFfaW52YWxpZG8iOiB1IkZhbGhhIGFvIGxlciBvIG1hcGE6IHswfSIsCiAgICAgICAgInRf
REM b3JpZ2VtX3Byb21wdCI6IHUiSWRpb21hIGRlIG9yaWdlbSBbYXV0b106ICIsCiAgICAgICAg
REM InRfZGVzdGlub19wcm9tcHQiOiB1IklkaW9tYSBkZSBkZXN0aW5vIFtwdC1CUl06ICIsCiAg
REM ICAgICAgInRfY29uZWN0YW5kbyI6IHUiVGVzdGFuZG8gYWNlc3NvIMOgIHJlZGUgZG8gR29v
REM Z2xlIFRyYW5zbGF0ZS4uLiIsCiAgICAgICAgInRfY29uZWN0YWRvIjogdSJBY2Vzc28gYW8g
REM R29vZ2xlIFRyYW5zbGF0ZSBPSy4gTyB0ZXN0ZSBuw6NvIGNvbnNvbWUgYSBjb3RhIGRvIGVu
REM ZHBvaW50IGRlIHRyYWR1w6fDo28uIiwKICAgICAgICAidF9lcnJvX2NvbmV4YW8iOiB1IkZh
REM bGhhIG5vIEdvb2dsZSBUcmFuc2xhdGU6IHswfSIsCiAgICAgICAgInRfY2FuY2VsYWRvIjog
REM dSJUcmFkdcOnw6NvIGNhbmNlbGFkYS4iLAogICAgICAgICJ0X3Byb2Nlc3NhbmRvIjogdSJQ
REM cm9jZXNzYW5kbyB7MH0gdGV4dG9zIMO6bmljb3MuLi4iLAogICAgICAgICJ0X2FycXVpdm8i
REM OiB1Ik9LICB7MH0gIC0+ICB7MX0gdGV4dG8ocykiLAogICAgICAgICJ0X2ZhbGhhX3RleHRv
REM IjogdSJGQUxIQSBhbyB0cmFkdXppciBlc3RlIGFycXVpdm87IG8gYXJxdWl2byBjb3BpYWRv
REM IGZvaSBtYW50aWRvIGNvbSBvIHF1ZSBmb2kgcG9zc8OtdmVsIHRyYWR1emlyLiIsCiAgICAg
REM ICAgInRfbmVuaHVtYSI6IHUiTmVuaHVtIHRleHRvIGZvaSBwcm9jZXNzYWRvLiIsCiAgICAg
REM ICAgInRfcHJvbnRvIjogdSJUcmFkdcOnw6NvIGNvbmNsdcOtZGEuIFBhc3RhIGNyaWFkYSBl
REM bTogezB9IiwKICAgICAgICAidF9sb2dfaW5pY2lvIjogdSJEREFDIFRyYWR1w6fDo28gY29t
REM IEdvb2dsZSBUcmFuc2xhdGUgLSBJTsONQ0lPIERBIEVYRUNVw4fDg08iLAogICAgICAgICJ0
REM X2xvZ19wYXN0YSI6IHUiUGFzdGEgZGUgZW50cmFkYTogezB9IiwKICAgICAgICAidF9sb2df
REM c2FpZGEiOiB1IlBhc3RhIGRlIHNhw61kYTogezB9IiwKICAgICAgICAidF9sb2dfYXJxdWl2
REM byI6IHUiVGV4dG9zIHByb2Nlc3NhZG9zIGVtIHswfSIsCiAgICAgICAgInRfbG9nX2ZhbGhh
REM IjogdSJGYWxoYSBlbSB7MH0iLAogICAgICAgICJ0X2xvZ19maW0iOiB1IkREQUMgVHJhZHXD
REM p8OjbyBjb20gR29vZ2xlIFRyYW5zbGF0ZSAtIEZJTSBEQSBFWEVDVcOHw4NPIiwKICAgICAg
REM ICAidF9sb3RlX2luaWNpbyI6IHUiTG90ZSB7MH0vezF9ICAtPiAgezJ9IHRleHRvKHMpIGVu
REM dmlhZG8ocykiLAogICAgICAgICJ0X2xvdGVfb2siOiB1IkxvdGUgezB9L3sxfSBPSyAgLT4g
REM IHsyfSB0ZXh0byhzKSB0cmFkdXppZG8ocykgZW0gezM6LjFmfXMiLAogICAgICAgICJ0X2xv
REM dGVfZXJybyI6IHUiTG90ZSB7MH0vezF9IEZBTEhPVSAgLT4gIHsyfSIsCiAgICAgICAgInRf
REM ZmFsbGJhY2siOiB1IkZhbGxiYWNrIGluZGl2aWR1YWwgaW5pY2lhZG8gcGFyYSBvIGxvdGUg
REM ezB9L3sxfSIsCiAgICAgICAgInRfcHJvZ3Jlc3NvIjogdSJQcm9ncmVzc286IHswfS97MX0g
REM dGV4dG9zICB8ICB7Mn0gbG90ZShzKSBPSyAgfCAgezN9IGZhbGhhKHMpIiwKICAgICAgICAi
REM dF9jb25maWdfcGFyYWxlbGEiOiB1IlBhcmFsZWxvOiB7MH0gcmVxdWlzacOnw7VlcyBzaW11
REM bHTDom5lYXMgIHwgIGF0w6kgezF9IHRleHRvcyBwb3IgbG90ZSAgfCAgezJ9IGNhcmFjdGVy
REM ZXMgcG9yIGxvdGUiLAogICAgICAgICJ0X2NhY2hlIjogdSJDYWNoZTogezB9IHRyYWR1w6fD
REM o28ow7VlcykgcmVhcHJvdmVpdGFkYShzKSIsCiAgICAgICAgInRfYXJxdWl2b19pbmljaW8i
REM OiB1IklOw41DSU8gIHswfSAgLT4gIHsxfSB0ZXh0byhzKSIsCiAgICAgICAgInRfYXJxdWl2
REM b19maW0iOiB1IkZJTSAgezB9ICAtPiAgezF9IHRleHRvKHMpIGVtIHsyOi4xZn1zIiwKICAg
REM ICAgICAidF9jYW5jZWxhZG8iOiB1IlRyYWR1w6fDo28gY2FuY2VsYWRhLiIsCiAgICAgICAg
REM ImV0YXBhX2JpYmxpb3RlY2EiOiB1IkV0YXBhIDAvMzogY29uc3VsdGFuZG8gYSBiaWJsaW90
REM ZWNhIERETEMvVGVtcGxhdGUgKHswfSBhcnF1aXZvcyBjYXRhbG9nYWRvcykuLi4iLAogICAg
REM ICAgICJiaWJfaWdub3JhZG8iOiB1IklHTiB7MH0gIC0+ICBzZW0gZGnDoWxvZ28gbmF0aXZv
REM ICh7MX0pIiwKICAgICAgICAiYmliX25vdm9fdGV4dG8iOiB1Ik5PVk8gezB9ICAtPiAgezF9
REM IGxpbmhhKHMpIGVtIGFycXVpdm8gbm9ybWFsbWVudGUgc2VtIGRpw6Fsb2dvICh7Mn0pIiwK
REM ICAgICAgICAicmVzX2JpYl9pZ25vcmFkb3MiOiB1IkFycXVpdm9zIGlnbm9yYWRvcyBwZWxh
REM IGJpYmxpb3RlY2EgKHswfSk6IiwKICAgICAgICAicmVzX2JpYl9ub3ZvcyI6IHUiQXJxdWl2
REM b3MgZm9yYSBkbyBwYWRyw6NvIGRhIGJpYmxpb3RlY2EgKHRleHRvIG5vdm8pICh7MH0pOiIs
REM CiAgICAgICAgImxvZ19iaWJfaWdub3JhZG8iOiB1InswfTogaWdub3JhZG8gcGVsYSBiaWJs
REM aW90ZWNhIC0tIHsxfSIsCiAgICAgICAgImxvZ19iaWJfbm92byI6IHUiezB9OiB0ZXh0byBu
REM b3ZvIGVtIGFycXVpdm8gc2VtIGRpw6Fsb2dvIG5hdGl2byAtLSB7MX0iLAogICAgICAgICJs
REM b2dfcmVzX2JpYl9pZ25vcmFkb3MiOiB1Iklnbm9yYWRvcyBwZWxhIGJpYmxpb3RlY2EiLAog
REM ICAgICAgICJsb2dfcmVzX2JpYl9ub3ZvcyI6IHUiQXJxdWl2b3MgY29tIHRleHRvIGZvcmEg
REM ZG8gcGFkcsOjbyIsCiAgICB9LAogICAgMjogewogICAgICAgICJjYWJfZXh0cmFpciI6IHUi
REM IEREQUMgLSBFeHRyYWN0IERpYWxvZ3VlIiwKICAgICAgICAiY2FiX3JlaW5qZXRhciI6IHUi
REM IEREQUMgLSBSZWluamVjdCBUcmFuc2xhdGlvbiIsCiAgICAgICAgInBhc3RhX2VzY2FuZWFk
REM YSI6IHUiU2Nhbm5lZCBmb2xkZXI6IHswfSIsCiAgICAgICAgInBhc3RhX3NhaWRhIjogdSJP
REM dXRwdXQgZm9sZGVyOiAgezB9IiwKICAgICAgICAicGFzdGFfdHJhZHVjYW8iOiB1IlRyYW5z
REM bGF0aW9uIGZvbGRlcjogezB9IiwKICAgICAgICAicGFzdGFfb3JpZ2luYWwiOiB1Ik9yaWdp
REM bmFsIGZvbGRlcjogICAgezB9IiwKICAgICAgICAicGFzdGFfc2FpZGEyIjogdSJPdXRwdXQg
REM Zm9sZGVyOiAgICAgIHswfSIsCiAgICAgICAgImV0YXBhMV9leHRyYWlyIjogdSJTdGVwIDEv
REM MzogbG9jYXRpbmcgLnJweS8ucnB5bS8udHh0IGZpbGVzLi4uIiwKICAgICAgICAiZXRhcGEy
REM X2V4dHJhaXIiOiB1IlN0ZXAgMi8zOiBpZGVudGlmeWluZyBjaGFyYWN0ZXJzIHdpdGggZHlu
REM YW1pYyBuYW1lcy4uLiIsCiAgICAgICAgImV0YXBhM19leHRyYWlyIjogdSJTdGVwIDMvMzog
REM ZXh0cmFjdGluZyBkaWFsb2d1ZSBhbmQgcmVidWlsZGluZyB0aGUgc3RydWN0dXJlIGluIHsw
REM fS4uLiIsCiAgICAgICAgImFycXVpdm9zX2VuY29udHJhZG9zIjogdSIgIHswfSBmaWxlKHMp
REM IGZvdW5kIiwKICAgICAgICAidmFyc19kaW5hbWljYXMiOiB1IiAgezB9IGR5bmFtaWMgbmFt
REM ZSB2YXJpYWJsZShzKSBmb3VuZCIsCiAgICAgICAgImVycm8iOiB1IkVSUk9SIiwKICAgICAg
REM ICAiZXJyb19hcnF1aXZvIjogdSJFUlJPUiB7MH0gIC0+ICB7MX0iLAogICAgICAgICJva19s
REM aW5oYXMiOiB1Ik9LICB7MH0gIC0+ICB7MX0gbGluZShzKSIsCiAgICAgICAgInJlc19lc2Nh
REM bmVhZG9zIjogdSJGaWxlcyBzY2FubmVkOiB7MH0iLAogICAgICAgICJyZXNfY29tX2RpYWxv
REM Z28iOiB1IkZpbGVzIHdpdGggZXh0cmFjdGVkIGRpYWxvZ3VlOiB7MH0iLAogICAgICAgICJy
REM ZXNfbGluaGFzIjogdSJEaWFsb2d1ZSBsaW5lcyBleHRyYWN0ZWQ6IHswfSIsCiAgICAgICAg
REM InJlc19zZW1fZGlhbG9nbyI6IHUiRmlsZXMgd2l0aCBubyBkaWFsb2d1ZSBkZXRlY3RlZCAo
REM ezB9KToiLAogICAgICAgICJpbXAxIjogdSJJTVBPUlRBTlQ6IGRvIG5vdCBkZWxldGUsIHJl
REM bmFtZSBvciBlZGl0IHRoZSB7MH0gZmlsZSB0aGF0IHNpdHMiLAogICAgICAgICJpbXAyIjog
REM dSJhdCB0aGUgcm9vdCBvZiB7MH0gLS0gaXQgc3RvcmVzIHRoZSBwb3NpdGlvbiBvZiBldmVy
REM eSB0ZXh0IGZvciByZWluamVjdGlvbi4iLAogICAgICAgICJpbXAzIjogdSJXaGVuIHRyYW5z
REM bGF0aW5nLCBlZGl0IG9ubHkgdGhlIHRleHQgYmV0d2VlbiBxdW90ZXMgb24gZWFjaCBsaW5l
REM LCBrZWVwaW5nIiwKICAgICAgICAiaW1wNCI6IHUidGhlIHF1b3RlcyBpbiBwbGFjZS4iLAog
REM ICAgICAgICJpbXA1IjogdSJEbyBub3QgYWRkIG9yIHJlbW92ZSBsaW5lcy4gV2hlbiB5b3Ug
REM YXJlIGRvbmUsIHJ1biB0aGlzIHByb2dyYW0iLAogICAgICAgICJpbXA2IjogdSJhZ2FpbiBh
REM bmQgdXNlIG9wdGlvbiAyLiIsCiAgICAgICAgImxvZ19zYWx2byI6IHUiTG9nIHNhdmVkIHRv
REM OiB7MH0iLAogICAgICAgICJlcnJfcGFzdGFfZW50cmFkYSI6IHUiTm8gY29tcGF0aWJsZSBl
REM eHRyYWN0ZWQtZGlhbG9ndWUgZm9sZGVyIHdhcyBmb3VuZC4gVXNlIG9wdGlvbiAxIChFeHRy
REM YWN0IGRpYWxvZ3VlKSBmaXJzdC4iLAogICAgICAgICJyZWlual9tdWx0aXBsYXNfdGl0dWxv
REM IjogdSJNdWx0aXBsZSBkaWFsb2d1ZSBmb2xkZXJzIHdlcmUgZm91bmQuIENob29zZSB3aGlj
REM aCB2ZXJzaW9uIHRvIHJlaW50ZWdyYXRlOiIsCiAgICAgICAgInJlaW5qX211bHRpcGxhc19v
REM cGNhbyI6IHUiICB7MH0pIHsxfSIsCiAgICAgICAgInJlaW5qX211bHRpcGxhc19wcm9tcHQi
REM OiB1IkNob29zZSBhbiBvcHRpb246ICIsCiAgICAgICAgInJlaW5qX211bHRpcGxhc19pbnZh
REM bGlkYSI6IHUiSW52YWxpZCBvcHRpb24uIENob29zZSBvbmUgb2YgdGhlIG9wdGlvbnMgYWJv
REM dmUuIiwKICAgICAgICAicmVpbmpfc2VsZWNhb190aXR1bG8iOiB1IkNIT09TRSBUSEUgVFJB
REM TlNMQVRJT04gU09VUkNFIiwKICAgICAgICAicmVpbmpfc2VsZWNhb19pdGVtIjogdSJbezB9
REM XSB7MX0iLAogICAgICAgICJyZWlual9zZWxlY2FvX3Bhc3RhIjogdSIgICAgRm9sZGVyOiB7
REM MH0iLAogICAgICAgICJyZWlual9zZWxlY2FvX2NhbWluaG8iOiB1IiAgICBQYXRoOiB7MH0i
REM LAogICAgICAgICJyZWlual9zZWxlY2FvX3Byb21wdCI6IHUiRW50ZXIgdGhlIG9wdGlvbiBu
REM dW1iZXI6ICIsCiAgICAgICAgInJlaW5qX3NlbGVjYW9faW52YWxpZGEiOiB1IkludmFsaWQg
REM b3B0aW9uLiBFbnRlciB0aGUgbnVtYmVyIG9mIG9uZSBvZiB0aGUgb3B0aW9ucyBhYm92ZS4i
REM LAogICAgICAgICJyZWlual90aXBvX21hbnVhbCI6IHUiRXh0cmFjdGlvbiAvIG1hbnVhbCB0
REM cmFuc2xhdGlvbiIsCiAgICAgICAgInJlaW5qX3RpcG9fZ29vZ2xlIjogdSJHb29nbGUgVHJh
REM bnNsYXRlIC8gdHJhbnNsYXRpb24iLAogICAgICAgICJyal9tb2RvX3RpdHVsbyI6IHUiUmVp
REM bnRlZ3JhdGlvbiBtb2RlIiwKICAgICAgICAicmpfbW9kb19ub3JtYWwiOiB1IjEpIE5vcm1h
REM bCAocmVjb21tZW5kZWQpIiwKICAgICAgICAicmpfbW9kb19zZWd1cm8iOiB1IjIpIFNhZmUg
REM KGJhY2t1cCArIGZ1bGwgdmFsaWRhdGlvbikiLAogICAgICAgICJyal9tb2RvX3Byb21wdCI6
REM IHUiQ2hvb3NlIG1vZGUgWzFdOiAiLAogICAgICAgICJyal9tb2RvX2ludmFsaWRvIjogdSJJ
REM bnZhbGlkIG9wdGlvbi4gQ2hvb3NlIDEgb3IgMi4iLAogICAgICAgICJyal92YWxpZGFjYW9f
REM cHJlIjogdSJQUkUtUkVJTlRFR1JBVElPTiBWQUxJREFUSU9OIiwKICAgICAgICAicmpfdmFs
REM aWRhY2FvX3BvcyI6IHUiUE9TVC1SRUlOVEVHUkFUSU9OIFZBTElEQVRJT04iLAogICAgICAg
REM ICJyal92YWxpZGFjYW9fb2siOiB1IlZhbGlkYXRpb24gY29tcGxldGVkIHdpdGggbm8gdW5l
REM eHBlY3RlZCBkaWZmZXJlbmNlcy4iLAogICAgICAgICJyal92YWxpZGFjYW9fZmFsaG91Ijog
REM dSJWYWxpZGF0aW9uIGZvdW5kIHByb2JsZW1zLiBSZWludGVncmF0aW9uIHdhcyByZWZ1c2Vk
REM LiIsCiAgICAgICAgInJqX2JhY2t1cF9vayI6IHUiQmFja3VwIG9mIHRoZSBwcmV2aW91cyBv
REM dXRwdXQgY3JlYXRlZCBhdDogezB9IiwKICAgICAgICAicmpfYmFja3VwX25hbyI6IHUiTm8g
REM cHJldmlvdXMgb3V0cHV0IHRvIGJhY2sgdXAuIiwKICAgICAgICAicmpfdGV4dG9zX2FsdGVy
REM YWRvcyI6IHUiVGV4dHMgYWN0dWFsbHkgY2hhbmdlZCIsCiAgICAgICAgInJqX3RleHRvc19p
REM Z3VhaXMiOiB1IlRleHRzIHVuY2hhbmdlZCIsCiAgICAgICAgInJqX2FycXVpdm9zX29rIjog
REM dSJGaWxlcyB2YWxpZGF0ZWQiLAogICAgICAgICJyal9hcnF1aXZvc19lc3BlcmFkb3MiOiB1
REM IkZpbGVzIGV4cGVjdGVkIGJ5IHRoZSBtYXAiLAogICAgICAgICJyal9lbnRyYWRhc19lc3Bl
REM cmFkYXMiOiB1IkVudHJpZXMgZXhwZWN0ZWQgYnkgdGhlIG1hcCIsCiAgICAgICAgInJqX2Vu
REM dHJhZGFzX2VuY29udHJhZGFzIjogdSJFbnRyaWVzIGZvdW5kIiwKICAgICAgICAicmpfZGlm
REM ZXJlbmNhcyI6IHUiVW5leHBlY3RlZCBkaWZmZXJlbmNlcyIsCiAgICAgICAgInJqX21vZGlm
REM aWNhZG9zIjogdSJGaWxlcyBtb2RpZmllZCIsCiAgICAgICAgInJqX3RlbXBvIjogdSJUb3Rh
REM bCB0aW1lIiwKICAgICAgICAicmpfdmVsb2NpZGFkZSI6IHUiQXZlcmFnZSBzcGVlZCIsCiAg
REM ICAgICAgImVycl9tYXBhIjogdSJGaWxlICd7MH0nIG5vdCBmb3VuZCBpbnNpZGUgezF9LiBV
REM c2Ugb3B0aW9uIDEgZmlyc3QuIiwKICAgICAgICAiZXJyX2xlcl9tYXBhIjogdSJGYWlsZWQg
REM dG8gcmVhZCB7MH06IHsxfSIsCiAgICAgICAgImV0YXBhMV9yZWluaiI6IHUiU3RlcCAxLzI6
REM IGxvY2F0aW5nIHRyYW5zbGF0ZWQgZmlsZXMgaW4gezB9Li4uIiwKICAgICAgICAiZXRhcGEy
REM X3JlaW5qIjogdSJTdGVwIDIvMjogdmFsaWRhdGluZyBhbmQgcmVpbmplY3RpbmcgZWFjaCB0
REM ZXh0IGF0IGl0cyBvcmlnaW5hbCBwb3NpdGlvbi4uLiIsCiAgICAgICAgInNlbV9tYXBhIjog
REM dSJOTyBNQVAgIHswfSAgKG5vIGVudHJ5IGluIHsxfSwgc2tpcHBlZCkiLAogICAgICAgICJl
REM cnJvX2xlcl90cmFkIjogdSJFUlJPUiAgezB9ICAtPiAgZmFpbGVkIHRvIHJlYWQgdHJhbnNs
REM YXRpb246IHsxfSIsCiAgICAgICAgImVycm9faW5lc3BlcmFkbyI6IHUiRVJST1IgIHswfSAg
REM LT4gIHVuZXhwZWN0ZWQgZmFpbHVyZTogezF9IiwKICAgICAgICAiZmFsaGEiOiB1IkZBSUxF
REM RCAgezB9IiwKICAgICAgICAicmVzX3RyYWRfZW5jb250cmFkb3MiOiB1IlRyYW5zbGF0ZWQg
REM ZmlsZXMgZm91bmQ6IHswfSIsCiAgICAgICAgInJlc19yZWlual9vayI6IHUiRmlsZXMgcmVp
REM bmplY3RlZCBzdWNjZXNzZnVsbHk6IHswfSIsCiAgICAgICAgInJlc19yZWlual9mYWxoYSI6
REM IHUiRmFpbGVkIGZpbGVzIChsZWZ0IHVudG91Y2hlZCk6IHswfSIsCiAgICAgICAgInJlc19y
REM ZWlual9saW5oYXMiOiB1IlRvdGFsIGxpbmVzIHJlaW5qZWN0ZWQ6IHswfSIsCiAgICAgICAg
REM InJlc19zZW1fbWFwYSI6IHUiRmlsZXMgd2l0aCBubyBtYXAgZW50cnkgKHNraXBwZWQpOiB7
REM MH0iLAogICAgICAgICJva19yZWluamV0YWRhcyI6IHUiT0sgIHswfSAgLT4gIHsxfSBsaW5l
REM KHMpIHJlaW5qZWN0ZWQiLAogICAgICAgICJwcm9udG8xIjogdSJUaGUgdHJhbnNsYXRlZCBm
REM b2xkZXIgaXMgcmVhZHkgYXQ6IHswfSIsCiAgICAgICAgInByb250bzIiOiB1IkN1dCB0aGUg
REM J3swfScgZm9sZGVyIChpbnNpZGUgezF9KSBhbmQgcGFzdGUgaXQgb3ZlciB0aGUgb3JpZ2lu
REM YWwiLAogICAgICAgICJwcm9udG8zIjogdSInezB9JyBmb2xkZXIgb2YgdGhlIG1vZCwgcmVw
REM bGFjaW5nIGl0LCB0byBhcHBseSB0aGUgdHJhbnNsYXRpb24uIiwKICAgICAgICAiYXRlbmNh
REM bzEiOiB1IldBUk5JTkc6IHswfSBmaWxlKHMpIHdlcmUgTk9UIHJlaW5qZWN0ZWQgZm9yIHNh
REM ZmV0eSAtLSBzZWUgdGhlIiwKICAgICAgICAiYXRlbmNhbzIiOiB1ImRldGFpbHMgYWJvdmUg
REM YW5kIGluIHRoZSBsb2cuIE5vIG9yaWdpbmFsIGZpbGUgd2FzIG1vZGlmaWVkLiIsCiAgICAg
REM ICAgInJqX2NvbnRhZ2VtIjogdSJjb3VudCBtaXNtYXRjaDogdGhlIG1hcCBleHBlY3RzIHsw
REM fSB0ZXh0KHMpLCBidXQgdGhlIHRyYW5zbGF0ZWQgZmlsZSBoYXMgezF9LiBEbyBOT1QgYWRk
REM IG9yIHJlbW92ZSB0ZXh0IGxpbmVzIC0tIGVkaXQgb25seSB0aGUgY29udGVudCBiZXR3ZWVu
REM IHF1b3RlcyBvbiBlYWNoIG9uZS4iLAogICAgICAgICJyal9zZW1fb3JpZ2luYWwiOiB1Im9y
REM aWdpbmFsIGZpbGUgbm90IGZvdW5kOiB7MH0iLAogICAgICAgICJyal9saW5oYV9pbmV4aXN0
REM ZW50ZSI6IHUibGluZSB7MH0gbm8gbG9uZ2VyIGV4aXN0cyBpbiB0aGUgb3JpZ2luYWwgZmls
REM ZSAod2FzIHRoZSBtb2QgY2hhbmdlZCBhZnRlciBleHRyYWN0aW9uPykiLAogICAgICAgICJy
REM al9saW5oYV9tdWRvdSI6IHUibGluZSB7MH0gKGNvbHVtbnMgezF9LXsyfSkgb2YgdGhlIG9y
REM aWdpbmFsIGZpbGUgY2hhbmdlZCBhZnRlciBleHRyYWN0aW9uIChleHBlY3RlZDogezMhcn0g
REM LyBmb3VuZDogezQhcn0pIiwKICAgICAgICAibG9nX3RhZ19pbmZvIjogdSJJTkZPIiwKICAg
REM ICAgICAibG9nX3RhZ19hdmlzbyI6IHUiV0FSTklORyIsCiAgICAgICAgImxvZ190YWdfZXJy
REM byI6IHUiRVJST1IiLAogICAgICAgICJsb2dfY2FiX2V4dHJhdG9yIjogdSJEREFDIERpYWxv
REM Z3VlIEV4dHJhY3Rpb24gLSBFWEVDVVRJT04gU1RBUlQiLAogICAgICAgICJsb2dfY2FiX3Jl
REM aW5qZXRvciI6IHUiRERBQyBEaWFsb2d1ZSBSZWludGVncmF0aW9uIC0gRVhFQ1VUSU9OIFNU
REM QVJUIiwKICAgICAgICAibG9nX2RhdGFob3JhIjogdSJEYXRlL1RpbWU6IHswfSIsCiAgICAg
REM ICAgImxvZ19wYXN0YV9lc2NhbmVhZGEiOiB1IlNjYW5uZWQgZm9sZGVyOiB7MH0iLAogICAg
REM ICAgICJsb2dfcGFzdGFfc2FpZGEiOiB1Ik91dHB1dCBmb2xkZXI6IHswfSIsCiAgICAgICAg
REM ImxvZ19ldGFwYTFfZXh0cmFpciI6IHUiU3RlcCAxLzM6IHswfSAucnB5Ly5ycHltLy50eHQg
REM ZmlsZShzKSBsb2NhdGVkIiwKICAgICAgICAibG9nX2V0YXBhMl9leHRyYWlyIjogdSJTdGVw
REM IDIvMzogezB9IGR5bmFtaWMgbmFtZSB2YXJpYWJsZShzKTogezF9IiwKICAgICAgICAibG9n
REM X2V0YXBhM19leHRyYWlyIjogdSJTdGVwIDMvMzogc3RhcnRpbmcgZGlhbG9ndWUgZXh0cmFj
REM dGlvbiIsCiAgICAgICAgImxvZ19mYWxoYV9sZXIiOiB1IkZhaWxlZCB0byByZWFkIHswfTog
REM ezF9IiwKICAgICAgICAibG9nX3NlbV9kaWFsb2dvIjogdSJObyBkaWFsb2d1ZSBkZXRlY3Rl
REM ZDogezB9IiwKICAgICAgICAibG9nX2xpbmhhcyI6IHUiezB9IGxpbmUocykiLAogICAgICAg
REM ICJsb2dfcmVzX2VzY2FuZWFkb3MiOiB1IkZpbGVzIHNjYW5uZWQiLAogICAgICAgICJsb2df
REM cmVzX2NvbV9kaWFsb2dvIjogdSJGaWxlcyB3aXRoIGRpYWxvZ3VlIiwKICAgICAgICAibG9n
REM X3Jlc19zZW1fZGlhbG9nbyI6IHUiRmlsZXMgd2l0aG91dCBkaWFsb2d1ZSIsCiAgICAgICAg
REM ImxvZ19yZXNfbGluaGFzIjogdSJEaWFsb2d1ZSBsaW5lcyBleHRyYWN0ZWQiLAogICAgICAg
REM ICJsb2dfcmVzX2Vycm9zIjogdSJSZWFkIGVycm9ycyIsCiAgICAgICAgImxvZ19wYXN0YV90
REM cmFkdWNhbyI6IHUiVHJhbnNsYXRpb24gZm9sZGVyICh7MH0pOiB7MX0iLAogICAgICAgICJs
REM b2dfcGFzdGFfb3JpZ2luYWwiOiB1Ik9yaWdpbmFsIGZvbGRlciAoZ2FtZSk6IHswfSIsCiAg
REM ICAgICAgImxvZ19ldGFwYTFfcmVpbmoiOiB1IlN0ZXAgMS8yOiB7MH0gdHJhbnNsYXRlZCBm
REM aWxlKHMpIGxvY2F0ZWQiLAogICAgICAgICJsb2dfZXRhcGEyX3JlaW5qIjogdSJTdGVwIDIv
REM Mjogc3RhcnRpbmcgcmVpbmplY3Rpb24iLAogICAgICAgICJsb2dfc2VtX21hcGFfYXJxIjog
REM dSJGaWxlIHdpdGggbm8gZW50cnkgaW4gezB9LCBza2lwcGVkOiB7MX0iLAogICAgICAgICJs
REM b2dfZmFsaGFfbGVyX3RyYWQiOiB1IkZhaWxlZCB0byByZWFkIHRyYW5zbGF0aW9uIG9mIHsw
REM fTogezF9IiwKICAgICAgICAibG9nX2ZhbGhhX2luZXNwZXJhZGEiOiB1IlVuZXhwZWN0ZWQg
REM ZmFpbHVyZSByZWluamVjdGluZyB7MH06IHsxfSIsCiAgICAgICAgImxvZ19mYWxoYV9yZWlu
REM amV0YXIiOiB1IkZhaWxlZCB0byByZWluamVjdCB7MH06IiwKICAgICAgICAibG9nX2xpbmhh
REM c19yZWluaiI6IHUiezB9IGxpbmUocykgcmVpbmplY3RlZCIsCiAgICAgICAgImxvZ19yZXNf
REM dHJhZF9lbmNvbnRyYWRvcyI6IHUiVHJhbnNsYXRlZCBmaWxlcyBmb3VuZCIsCiAgICAgICAg
REM ImxvZ19yZXNfb2siOiB1IlJlaW5qZWN0ZWQgc3VjY2Vzc2Z1bGx5IiwKICAgICAgICAibG9n
REM X3Jlc19mYWxoYXMiOiB1IkZhaWx1cmVzIChsZWZ0IHVudG91Y2hlZCkiLAogICAgICAgICJs
REM b2dfcmVzX3NlbV9tYXBhIjogdSJObyBtYXAgZW50cnkgKHNraXBwZWQpIiwKICAgICAgICAi
REM bG9nX3Jlc19saW5oYXNfcmVpbmoiOiB1IkxpbmVzIHJlaW5qZWN0ZWQiLAogICAgICAgICJt
REM b2RvX2Rlc2NvbmhlY2lkbyI6IHUiVW5rbm93biBtb2RlOiB7MCFyfSIsCiAgICAgICAgInRf
REM c2VtX2V4dHJhY2FvIjogdSJObyBjb21wYXRpYmxlIGV4dHJhY3RlZC1kaWFsb2d1ZXMgZm9s
REM ZGVyIHdhcyBmb3VuZC4gVXNlIG9wdGlvbiAxIGZpcnN0LiIsCiAgICAgICAgInRfbWFwYV9p
REM bnZhbGlkbyI6IHUiRmFpbGVkIHRvIHJlYWQgdGhlIG1hcDogezB9IiwKICAgICAgICAidF9v
REM cmlnZW1fcHJvbXB0IjogdSJTb3VyY2UgbGFuZ3VhZ2UgW2F1dG9dOiAiLAogICAgICAgICJ0
REM X2Rlc3Rpbm9fcHJvbXB0IjogdSJUYXJnZXQgbGFuZ3VhZ2UgW3B0LUJSXTogIiwKICAgICAg
REM ICAidF9jb25lY3RhbmRvIjogdSJUZXN0aW5nIGNvbm5lY3Rpb24gdG8gR29vZ2xlIFRyYW5z
REM bGF0ZS4uLiIsCiAgICAgICAgInRfY29uZWN0YWRvIjogdSJHb29nbGUgVHJhbnNsYXRlIGNv
REM bm5lY3Rpb24gT0suIiwKICAgICAgICAidF9lcnJvX2NvbmV4YW8iOiB1Ikdvb2dsZSBUcmFu
REM c2xhdGUgZmFpbGVkOiB7MH0iLAogICAgICAgICJ0X2NhbmNlbGFkbyI6IHUiVHJhbnNsYXRp
REM b24gY2FuY2VsbGVkLiIsCiAgICAgICAgInRfcHJvY2Vzc2FuZG8iOiB1IlByb2Nlc3Npbmcg
REM ezB9IHVuaXF1ZSB0ZXh0cy4uLiIsCiAgICAgICAgInRfYXJxdWl2byI6IHUiT0sgIHswfSAg
REM LT4gIHsxfSB0ZXh0KHMpIiwKICAgICAgICAidF9mYWxoYV90ZXh0byI6IHUiRkFJTEVEIHRv
REM IHRyYW5zbGF0ZSB0aGlzIGZpbGU7IHRoZSBjb3BpZWQgZmlsZSB3YXMga2VwdCB1bmNoYW5n
REM ZWQuIiwKICAgICAgICAidF9uZW5odW1hIjogdSJObyB0ZXh0IHdhcyBwcm9jZXNzZWQuIiwK
REM ICAgICAgICAidF9wcm9udG8iOiB1IlRyYW5zbGF0aW9uIGNvbXBsZXRlZC4gT3V0cHV0IGZv
REM bGRlcjogezB9IiwKICAgICAgICAidF9sb2dfaW5pY2lvIjogdSJEREFDIEdvb2dsZSBUcmFu
REM c2xhdGUgLSBTVEFSVCIsCiAgICAgICAgInRfbG9nX3Bhc3RhIjogdSJJbnB1dCBmb2xkZXI6
REM IHswfSIsCiAgICAgICAgInRfbG9nX3NhaWRhIjogdSJPdXRwdXQgZm9sZGVyOiB7MH0iLAog
REM ICAgICAgICJ0X2xvZ19hcnF1aXZvIjogdSJUZXh0cyBwcm9jZXNzZWQgaW4gezB9IiwKICAg
REM ICAgICAidF9sb2dfZmFsaGEiOiB1IkZhaWxlZCBpbiB7MH0iLAogICAgICAgICJ0X2xvZ19m
REM aW0iOiB1IkREQUMgR29vZ2xlIFRyYW5zbGF0ZSAtIEVORCIsCiAgICAgICAgInRfbG90ZV9p
REM bmljaW8iOiB1IkJhdGNoIHswfS97MX0gIC0+ICB7Mn0gdGV4dChzKSBzZW50IiwKICAgICAg
REM ICAidF9sb3RlX29rIjogdSJCYXRjaCB7MH0vezF9IE9LICAtPiAgezJ9IHRleHQocykgdHJh
REM bnNsYXRlZCBpbiB7MzouMWZ9cyIsCiAgICAgICAgInRfbG90ZV9lcnJvIjogdSJCYXRjaCB7
REM MH0vezF9IEZBSUxFRCAgLT4gIHsyfSIsCiAgICAgICAgInRfZmFsbGJhY2siOiB1IkluZGl2
REM aWR1YWwgZmFsbGJhY2sgc3RhcnRlZCBmb3IgYmF0Y2ggezB9L3sxfSIsCiAgICAgICAgInRf
REM cHJvZ3Jlc3NvIjogdSJQcm9ncmVzczogezB9L3sxfSB0ZXh0cyAgfCAgezJ9IGJhdGNoKGVz
REM KSBPSyAgfCAgezN9IGZhaWx1cmUocykiLAogICAgICAgICJ0X2NvbmZpZ19wYXJhbGVsYSI6
REM IHUiUGFyYWxsZWw6IHswfSBzaW11bHRhbmVvdXMgcmVxdWVzdHMgIHwgIHVwIHRvIHsxfSB0
REM ZXh0cyBwZXIgYmF0Y2ggIHwgIHsyfSBjaGFycyBwZXIgYmF0Y2giLAogICAgICAgICJ0X2Nh
REM Y2hlIjogdSJDYWNoZTogezB9IHRyYW5zbGF0aW9uKHMpIHJldXNlZCIsCiAgICAgICAgInRf
REM YXJxdWl2b19pbmljaW8iOiB1IlNUQVJUICB7MH0gIC0+ICB7MX0gdGV4dChzKSIsCiAgICAg
REM ICAgInRfYXJxdWl2b19maW0iOiB1IkVORCAgezB9ICAtPiAgezF9IHRleHQocykgaW4gezI6
REM LjFmfXMiLAogICAgICAgICJldGFwYV9iaWJsaW90ZWNhIjogdSJTdGVwIDAvMzogY2hlY2tp
REM bmcgdGhlIERETEMvVGVtcGxhdGUgbGlicmFyeSAoezB9IGNhdGFsb2d1ZWQgZmlsZXMpLi4u
REM IiwKICAgICAgICAiYmliX2lnbm9yYWRvIjogdSJTS0lQIHswfSAgLT4gIG5vIG5hdGl2ZSBk
REM aWFsb2d1ZSAoezF9KSIsCiAgICAgICAgImJpYl9ub3ZvX3RleHRvIjogdSJORVcgIHswfSAg
REM LT4gIHsxfSBsaW5lKHMpIGluIGEgZmlsZSB0aGF0IG5vcm1hbGx5IGhhcyBubyBkaWFsb2d1
REM ZSAoezJ9KSIsCiAgICAgICAgInJlc19iaWJfaWdub3JhZG9zIjogdSJGaWxlcyBza2lwcGVk
REM IGJ5IHRoZSBsaWJyYXJ5ICh7MH0pOiIsCiAgICAgICAgInJlc19iaWJfbm92b3MiOiB1IkZp
REM bGVzIG91dHNpZGUgdGhlIGxpYnJhcnkgYmFzZWxpbmUgKG5ldyB0ZXh0KSAoezB9KToiLAog
REM ICAgICAgICJsb2dfYmliX2lnbm9yYWRvIjogdSJ7MH06IHNraXBwZWQgYnkgdGhlIGxpYnJh
REM cnkgLS0gezF9IiwKICAgICAgICAibG9nX2JpYl9ub3ZvIjogdSJ7MH06IG5ldyB0ZXh0IGlu
REM IGEgZmlsZSB3aXRob3V0IG5hdGl2ZSBkaWFsb2d1ZSAtLSB7MX0iLAogICAgICAgICJsb2df
REM cmVzX2JpYl9pZ25vcmFkb3MiOiB1IlNraXBwZWQgYnkgdGhlIGxpYnJhcnkiLAogICAgICAg
REM ICJsb2dfcmVzX2JpYl9ub3ZvcyI6IHUiRmlsZXMgd2l0aCB0ZXh0IG91dHNpZGUgdGhlIGJh
REM c2VsaW5lIiwKICAgIH0sCiAgICAzOiB7CiAgICAgICAgImNhYl9leHRyYWlyIjogdSIgRERB
REM QyAtIEV4dHJhZXIgRGnDoWxvZ29zIiwKICAgICAgICAiY2FiX3JlaW5qZXRhciI6IHUiIERE
REM QUMgLSBSZWlueWVjdGFyIFRyYWR1Y2Npw7NuIiwKICAgICAgICAicGFzdGFfZXNjYW5lYWRh
REM IjogdSJDYXJwZXRhIGVzY2FuZWFkYTogezB9IiwKICAgICAgICAicGFzdGFfc2FpZGEiOiB1
REM IkNhcnBldGEgZGUgc2FsaWRhOiB7MH0iLAogICAgICAgICJwYXN0YV90cmFkdWNhbyI6IHUi
REM Q2FycGV0YSBjb24gdHJhZHVjY2nDs246IHswfSIsCiAgICAgICAgInBhc3RhX29yaWdpbmFs
REM IjogdSJDYXJwZXRhIG9yaWdpbmFsOiAgICAgICB7MH0iLAogICAgICAgICJwYXN0YV9zYWlk
REM YTIiOiB1IkNhcnBldGEgZGUgc2FsaWRhOiAgICAgIHswfSIsCiAgICAgICAgImV0YXBhMV9l
REM eHRyYWlyIjogdSJQYXNvIDEvMzogbG9jYWxpemFuZG8gYXJjaGl2b3MgLnJweS8ucnB5bS8u
REM dHh0Li4uIiwKICAgICAgICAiZXRhcGEyX2V4dHJhaXIiOiB1IlBhc28gMi8zOiBpZGVudGlm
REM aWNhbmRvIHBlcnNvbmFqZXMgY29uIG5vbWJyZSBkaW7DoW1pY28uLi4iLAogICAgICAgICJl
REM dGFwYTNfZXh0cmFpciI6IHUiUGFzbyAzLzM6IGV4dHJheWVuZG8gZGnDoWxvZ29zIHkgcmVj
REM cmVhbmRvIGxhIGVzdHJ1Y3R1cmEgZW4gezB9Li4uIiwKICAgICAgICAiYXJxdWl2b3NfZW5j
REM b250cmFkb3MiOiB1IiAgezB9IGFyY2hpdm8ocykgZW5jb250cmFkbyhzKSIsCiAgICAgICAg
REM InZhcnNfZGluYW1pY2FzIjogdSIgIHswfSB2YXJpYWJsZShzKSBkZSBub21icmUgZGluw6Ft
REM aWNvIGVuY29udHJhZGEocykiLAogICAgICAgICJlcnJvIjogdSJFUlJPUiIsCiAgICAgICAg
REM ImVycm9fYXJxdWl2byI6IHUiRVJST1IgezB9ICAtPiAgezF9IiwKICAgICAgICAib2tfbGlu
REM aGFzIjogdSJPSyAgezB9ICAtPiAgezF9IGzDrW5lYShzKSIsCiAgICAgICAgInJlc19lc2Nh
REM bmVhZG9zIjogdSJBcmNoaXZvcyBlc2NhbmVhZG9zOiB7MH0iLAogICAgICAgICJyZXNfY29t
REM X2RpYWxvZ28iOiB1IkFyY2hpdm9zIGNvbiBkacOhbG9nbyBleHRyYcOtZG86IHswfSIsCiAg
REM ICAgICAgInJlc19saW5oYXMiOiB1IkzDrW5lYXMgZGUgZGnDoWxvZ28gZXh0cmHDrWRhczog
REM ezB9IiwKICAgICAgICAicmVzX3NlbV9kaWFsb2dvIjogdSJBcmNoaXZvcyBzaW4gZGnDoWxv
REM Z28gZGV0ZWN0YWRvICh7MH0pOiIsCiAgICAgICAgImltcDEiOiB1IklNUE9SVEFOVEU6IG5v
REM IGJvcnJlcywgcmVub21icmVzIG5pIGVkaXRlcyBlbCBhcmNoaXZvIHswfSBxdWUgZXN0w6Ei
REM LAogICAgICAgICJpbXAyIjogdSJlbiBsYSByYcOteiBkZSB7MH0gLS0gZ3VhcmRhIGxhIHBv
REM c2ljacOzbiBkZSBjYWRhIHRleHRvIHBhcmEgbGEgcmVpbnllY2Npw7NuLiIsCiAgICAgICAg
REM ImltcDMiOiB1IkFsIHRyYWR1Y2lyLCBlZGl0YSBzb2xvIGVsIHRleHRvIGVudHJlIGNvbWls
REM bGFzIGRlIGNhZGEgbMOtbmVhLCBkZWphbmRvIiwKICAgICAgICAiaW1wNCI6IHUibGFzIGNv
REM bWlsbGFzIGVuIHN1IGx1Z2FyLiIsCiAgICAgICAgImltcDUiOiB1Ik5vIGFncmVndWVzIG5p
REM IHF1aXRlcyBsw61uZWFzLiBDdWFuZG8gdGVybWluZXMsIGFicmUgZXN0ZSBwcm9ncmFtYSIs
REM CiAgICAgICAgImltcDYiOiB1ImRlIG51ZXZvIHkgdXNhIGxhIG9wY2nDs24gMi4iLAogICAg
REM ICAgICJsb2dfc2Fsdm8iOiB1IkxvZyBndWFyZGFkbyBlbjogezB9IiwKICAgICAgICAiZXJy
REM X3Bhc3RhX2VudHJhZGEiOiB1Ik5vIHNlIGVuY29udHLDsyBuaW5ndW5hIGNhcnBldGEgY29t
REM cGF0aWJsZSBkZSBkacOhbG9nb3MgZXh0cmHDrWRvcy4gVXNhIHByaW1lcm8gbGEgb3BjacOz
REM biAxIChFeHRyYWVyIGRpw6Fsb2dvcykuIiwKICAgICAgICAicmVpbmpfbXVsdGlwbGFzX3Rp
REM dHVsbyI6IHUiU2UgZW5jb250cmFyb24gdmFyaWFzIGNhcnBldGFzIGRlIGRpw6Fsb2dvcy4g
REM RWxpZ2UgcXXDqSB2ZXJzacOzbiBkZXNlYXMgcmVpbnllY3RhcjoiLAogICAgICAgICJyZWlu
REM al9tdWx0aXBsYXNfb3BjYW8iOiB1IiAgezB9KSB7MX0iLAogICAgICAgICJyZWlual9tdWx0
REM aXBsYXNfcHJvbXB0IjogdSJFbGlnZSB1bmEgb3BjacOzbjogIiwKICAgICAgICAicmVpbmpf
REM bXVsdGlwbGFzX2ludmFsaWRhIjogdSJPcGNpw7NuIG5vIHbDoWxpZGEuIEVsaWdlIHVuYSBk
REM ZSBsYXMgb3BjaW9uZXMgYW50ZXJpb3Jlcy4iLAogICAgICAgICJyZWlual9zZWxlY2FvX3Rp
REM dHVsbyI6IHUiRUxJR0UgTEEgRlVFTlRFIERFIExBIFRSQURVQ0NJw5NOIiwKICAgICAgICAi
REM cmVpbmpfc2VsZWNhb19pdGVtIjogdSJbezB9XSB7MX0iLAogICAgICAgICJyZWlual9zZWxl
REM Y2FvX3Bhc3RhIjogdSIgICAgQ2FycGV0YTogezB9IiwKICAgICAgICAicmVpbmpfc2VsZWNh
REM b19jYW1pbmhvIjogdSIgICAgUnV0YTogezB9IiwKICAgICAgICAicmVpbmpfc2VsZWNhb19w
REM cm9tcHQiOiB1IkVzY3JpYmUgZWwgbsO6bWVybyBkZSBsYSBvcGNpw7NuOiAiLAogICAgICAg
REM ICJyZWlual9zZWxlY2FvX2ludmFsaWRhIjogdSJPcGNpw7NuIG5vIHbDoWxpZGEuIEVzY3Jp
REM YmUgZWwgbsO6bWVybyBkZSB1bmEgZGUgbGFzIG9wY2lvbmVzIGFudGVyaW9yZXMuIiwKICAg
REM ICAgICAicmVpbmpfdGlwb19tYW51YWwiOiB1IkV4dHJhY2Npw7NuIC8gdHJhZHVjY2nDs24g
REM bWFudWFsIiwKICAgICAgICAicmVpbmpfdGlwb19nb29nbGUiOiB1Ikdvb2dsZSBUcmFuc2xh
REM dGUgLyB0cmFkdWNjacOzbiIsCiAgICAgICAgInJqX21vZG9fdGl0dWxvIjogdSJNb2RvIGRl
REM IHJlaW50ZWdyYWNpw7NuIiwKICAgICAgICAicmpfbW9kb19ub3JtYWwiOiB1IjEpIE5vcm1h
REM bCAocmVjb21lbmRhZG8pIiwKICAgICAgICAicmpfbW9kb19zZWd1cm8iOiB1IjIpIFNlZ3Vy
REM byAoY29waWEgZGUgc2VndXJpZGFkICsgdmFsaWRhY2nDs24gY29tcGxldGEpIiwKICAgICAg
REM ICAicmpfbW9kb19wcm9tcHQiOiB1IkVsaWdlIGVsIG1vZG8gWzFdOiAiLAogICAgICAgICJy
REM al9tb2RvX2ludmFsaWRvIjogdSJPcGNpw7NuIG5vIHbDoWxpZGEuIEVsaWdlIDEgbyAyLiIs
REM CiAgICAgICAgInJqX3ZhbGlkYWNhb19wcmUiOiB1IlZBTElEQUNJw5NOIEFOVEVTIERFIExB
REM IFJFSU5URUdSQUNJw5NOIiwKICAgICAgICAicmpfdmFsaWRhY2FvX3BvcyI6IHUiVkFMSURB
REM Q0nDk04gREVTUFXDiVMgREUgTEEgUkVJTlRFR1JBQ0nDk04iLAogICAgICAgICJyal92YWxp
REM ZGFjYW9fb2siOiB1IlZhbGlkYWNpw7NuIGNvbXBsZXRhZGEgc2luIGRpZmVyZW5jaWFzIGlu
REM ZXNwZXJhZGFzLiIsCiAgICAgICAgInJqX3ZhbGlkYWNhb19mYWxob3UiOiB1IkxhIHZhbGlk
REM YWNpw7NuIGVuY29udHLDsyBwcm9ibGVtYXMuIFNlIHJlY2hhesOzIGxhIHJlaW50ZWdyYWNp
REM w7NuLiIsCiAgICAgICAgInJqX2JhY2t1cF9vayI6IHUiQ29waWEgZGUgc2VndXJpZGFkIGRl
REM IGxhIHNhbGlkYSBhbnRlcmlvciBjcmVhZGEgZW46IHswfSIsCiAgICAgICAgInJqX2JhY2t1
REM cF9uYW8iOiB1Ik5vIGhhYsOtYSB1bmEgc2FsaWRhIGFudGVyaW9yIHBhcmEgcmVzcGFsZGFy
REM LiIsCiAgICAgICAgInJqX3RleHRvc19hbHRlcmFkb3MiOiB1IlRleHRvcyByZWFsbWVudGUg
REM bW9kaWZpY2Fkb3MiLAogICAgICAgICJyal90ZXh0b3NfaWd1YWlzIjogdSJUZXh0b3Mgc2lu
REM IGNhbWJpb3MiLAogICAgICAgICJyal9hcnF1aXZvc19vayI6IHUiQXJjaGl2b3MgdmFsaWRh
REM ZG9zIiwKICAgICAgICAicmpfYXJxdWl2b3NfZXNwZXJhZG9zIjogdSJBcmNoaXZvcyBlc3Bl
REM cmFkb3MgcG9yIGVsIG1hcGEiLAogICAgICAgICJyal9lbnRyYWRhc19lc3BlcmFkYXMiOiB1
REM IkVudHJhZGFzIGVzcGVyYWRhcyBwb3IgZWwgbWFwYSIsCiAgICAgICAgInJqX2VudHJhZGFz
REM X2VuY29udHJhZGFzIjogdSJFbnRyYWRhcyBlbmNvbnRyYWRhcyIsCiAgICAgICAgInJqX2Rp
REM ZmVyZW5jYXMiOiB1IkRpZmVyZW5jaWFzIGluZXNwZXJhZGFzIiwKICAgICAgICAicmpfbW9k
REM aWZpY2Fkb3MiOiB1IkFyY2hpdm9zIG1vZGlmaWNhZG9zIiwKICAgICAgICAicmpfdGVtcG8i
REM OiB1IlRpZW1wbyB0b3RhbCIsCiAgICAgICAgInJqX3ZlbG9jaWRhZGUiOiB1IlZlbG9jaWRh
REM ZCBtZWRpYSIsCiAgICAgICAgImVycl9tYXBhIjogdSJBcmNoaXZvICd7MH0nIG5vIGVuY29u
REM dHJhZG8gZGVudHJvIGRlIHsxfS4gVXNhIHByaW1lcm8gbGEgb3BjacOzbiAxLiIsCiAgICAg
REM ICAgImVycl9sZXJfbWFwYSI6IHUiRmFsbG8gYWwgbGVlciB7MH06IHsxfSIsCiAgICAgICAg
REM ImV0YXBhMV9yZWluaiI6IHUiUGFzbyAxLzI6IGxvY2FsaXphbmRvIGFyY2hpdm9zIHRyYWR1
REM Y2lkb3MgZW4gezB9Li4uIiwKICAgICAgICAiZXRhcGEyX3JlaW5qIjogdSJQYXNvIDIvMjog
REM dmFsaWRhbmRvIHkgcmVpbnllY3RhbmRvIGNhZGEgdGV4dG8gZW4gc3UgcG9zaWNpw7NuIG9y
REM aWdpbmFsLi4uIiwKICAgICAgICAic2VtX21hcGEiOiB1IlNJTiBNQVBBICB7MH0gIChzaW4g
REM ZW50cmFkYSBlbiB7MX0sIG9taXRpZG8pIiwKICAgICAgICAiZXJyb19sZXJfdHJhZCI6IHUi
REM RVJST1IgIHswfSAgLT4gIGZhbGxvIGFsIGxlZXIgbGEgdHJhZHVjY2nDs246IHsxfSIsCiAg
REM ICAgICAgImVycm9faW5lc3BlcmFkbyI6IHUiRVJST1IgIHswfSAgLT4gIGZhbGxvIGluZXNw
REM ZXJhZG86IHsxfSIsCiAgICAgICAgImZhbGhhIjogdSJGQUxMTyAgezB9IiwKICAgICAgICAi
REM cmVzX3RyYWRfZW5jb250cmFkb3MiOiB1IkFyY2hpdm9zIHRyYWR1Y2lkb3MgZW5jb250cmFk
REM b3M6IHswfSIsCiAgICAgICAgInJlc19yZWlual9vayI6IHUiQXJjaGl2b3MgcmVpbnllY3Rh
REM ZG9zIGNvbiDDqXhpdG86IHswfSIsCiAgICAgICAgInJlc19yZWlual9mYWxoYSI6IHUiQXJj
REM aGl2b3MgY29uIGVycm9yZXMgKG5vIG1vZGlmaWNhZG9zKTogezB9IiwKICAgICAgICAicmVz
REM X3JlaW5qX2xpbmhhcyI6IHUiTMOtbmVhcyByZWlueWVjdGFkYXMgZW4gdG90YWw6IHswfSIs
REM CiAgICAgICAgInJlc19zZW1fbWFwYSI6IHUiQXJjaGl2b3Mgc2luIGVudHJhZGEgZW4gZWwg
REM bWFwYSAob21pdGlkb3MpOiB7MH0iLAogICAgICAgICJva19yZWluamV0YWRhcyI6IHUiT0sg
REM IHswfSAgLT4gIHsxfSBsw61uZWEocykgcmVpbnllY3RhZGEocykiLAogICAgICAgICJwcm9u
REM dG8xIjogdSJMYSBjYXJwZXRhIHRyYWR1Y2lkYSBlc3TDoSBsaXN0YSBlbjogezB9IiwKICAg
REM ICAgICAicHJvbnRvMiI6IHUiQ29ydGEgbGEgY2FycGV0YSAnezB9JyAoZGVudHJvIGRlIHsx
REM fSkgeSBww6lnYWxhIHNvYnJlIGxhIGNhcnBldGEiLAogICAgICAgICJwcm9udG8zIjogdSIn
REM ezB9JyBvcmlnaW5hbCBkZWwgbW9kLCByZWVtcGxhesOhbmRvbGEsIHBhcmEgYXBsaWNhciBs
REM YSB0cmFkdWNjacOzbi4iLAogICAgICAgICJhdGVuY2FvMSI6IHUiQVRFTkNJw5NOOiB7MH0g
REM YXJjaGl2byhzKSBOTyBmdWVyb24gcmVpbnllY3RhZG9zIHBvciBzZWd1cmlkYWQgLS0gcmV2
REM aXNhIiwKICAgICAgICAiYXRlbmNhbzIiOiB1ImxvcyBkZXRhbGxlcyBhcnJpYmEgeSBlbiBl
REM bCBsb2cuIE5pbmfDum4gYXJjaGl2byBvcmlnaW5hbCBmdWUgbW9kaWZpY2Fkby4iLAogICAg
REM ICAgICJyal9jb250YWdlbSI6IHUibGEgY3VlbnRhIG5vIGNvaW5jaWRlOiBlbCBtYXBhIGVz
REM cGVyYSB7MH0gdGV4dG8ocyksIHBlcm8gZWwgYXJjaGl2byB0cmFkdWNpZG8gdGllbmUgezF9
REM LiBOTyBhZ3JlZ3VlcyBuaSBxdWl0ZXMgbMOtbmVhcyBkZSB0ZXh0byAtLSBlZGl0YSBzb2xv
REM IGVsIGNvbnRlbmlkbyBlbnRyZSBjb21pbGxhcyBkZSBjYWRhIHVuYS4iLAogICAgICAgICJy
REM al9zZW1fb3JpZ2luYWwiOiB1ImFyY2hpdm8gb3JpZ2luYWwgbm8gZW5jb250cmFkbzogezB9
REM IiwKICAgICAgICAicmpfbGluaGFfaW5leGlzdGVudGUiOiB1ImxhIGzDrW5lYSB7MH0geWEg
REM bm8gZXhpc3RlIGVuIGVsIGFyY2hpdm8gb3JpZ2luYWwgKHNlIG1vZGlmaWPDsyBlbCBtb2Qg
REM ZGVzcHXDqXMgZGUgbGEgZXh0cmFjY2nDs24/KSIsCiAgICAgICAgInJqX2xpbmhhX211ZG91
REM IjogdSJsYSBsw61uZWEgezB9IChjb2x1bW5hcyB7MX0tezJ9KSBkZWwgYXJjaGl2byBvcmln
REM aW5hbCBjYW1iacOzIGRlc3B1w6lzIGRlIGxhIGV4dHJhY2Npw7NuIChlc3BlcmFkbzogezMh
REM cn0gLyBlbmNvbnRyYWRvOiB7NCFyfSkiLAogICAgICAgICJsb2dfdGFnX2luZm8iOiB1IklO
REM Rk8iLAogICAgICAgICJsb2dfdGFnX2F2aXNvIjogdSJBVklTTyIsCiAgICAgICAgImxvZ190
REM YWdfZXJybyI6IHUiRVJST1IiLAogICAgICAgICJsb2dfY2FiX2V4dHJhdG9yIjogdSJEREFD
REM IEV4dHJhY2Npw7NuIGRlIERpw6Fsb2dvcyAtIElOSUNJTyBERSBMQSBFSkVDVUNJw5NOIiwK
REM ICAgICAgICAibG9nX2NhYl9yZWluamV0b3IiOiB1IkREQUMgUmVpbnRlZ3JhY2nDs24gZGUg
REM RGnDoWxvZ29zIC0gSU5JQ0lPIERFIExBIEVKRUNVQ0nDk04iLAogICAgICAgICJsb2dfZGF0
REM YWhvcmEiOiB1IkZlY2hhL0hvcmE6IHswfSIsCiAgICAgICAgImxvZ19wYXN0YV9lc2NhbmVh
REM ZGEiOiB1IkNhcnBldGEgZXNjYW5lYWRhOiB7MH0iLAogICAgICAgICJsb2dfcGFzdGFfc2Fp
REM ZGEiOiB1IkNhcnBldGEgZGUgc2FsaWRhOiB7MH0iLAogICAgICAgICJsb2dfZXRhcGExX2V4
REM dHJhaXIiOiB1IlBhc28gMS8zOiB7MH0gYXJjaGl2byhzKSAucnB5Ly5ycHltLy50eHQgbG9j
REM YWxpemFkbyhzKSIsCiAgICAgICAgImxvZ19ldGFwYTJfZXh0cmFpciI6IHUiUGFzbyAyLzM6
REM IHswfSB2YXJpYWJsZShzKSBkZSBub21icmUgZGluw6FtaWNvOiB7MX0iLAogICAgICAgICJs
REM b2dfZXRhcGEzX2V4dHJhaXIiOiB1IlBhc28gMy8zOiBpbmljaWFuZG8gbGEgZXh0cmFjY2nD
REM s24gZGUgZGnDoWxvZ29zIiwKICAgICAgICAibG9nX2ZhbGhhX2xlciI6IHUiRmFsbG8gYWwg
REM bGVlciB7MH06IHsxfSIsCiAgICAgICAgImxvZ19zZW1fZGlhbG9nbyI6IHUiU2luIGRpw6Fs
REM b2dvIGRldGVjdGFkbzogezB9IiwKICAgICAgICAibG9nX2xpbmhhcyI6IHUiezB9IGzDrW5l
REM YShzKSIsCiAgICAgICAgImxvZ19yZXNfZXNjYW5lYWRvcyI6IHUiQXJjaGl2b3MgZXNjYW5l
REM YWRvcyIsCiAgICAgICAgImxvZ19yZXNfY29tX2RpYWxvZ28iOiB1IkFyY2hpdm9zIGNvbiBk
REM acOhbG9nbyIsCiAgICAgICAgImxvZ19yZXNfc2VtX2RpYWxvZ28iOiB1IkFyY2hpdm9zIHNp
REM biBkacOhbG9nbyIsCiAgICAgICAgImxvZ19yZXNfbGluaGFzIjogdSJMw61uZWFzIGRlIGRp
REM w6Fsb2dvIGV4dHJhw61kYXMiLAogICAgICAgICJsb2dfcmVzX2Vycm9zIjogdSJFcnJvcmVz
REM IGRlIGxlY3R1cmEiLAogICAgICAgICJsb2dfcGFzdGFfdHJhZHVjYW8iOiB1IkNhcnBldGEg
REM Y29uIHRyYWR1Y2Npw7NuICh7MH0pOiB7MX0iLAogICAgICAgICJsb2dfcGFzdGFfb3JpZ2lu
REM YWwiOiB1IkNhcnBldGEgb3JpZ2luYWwgKGp1ZWdvKTogezB9IiwKICAgICAgICAibG9nX2V0
REM YXBhMV9yZWluaiI6IHUiUGFzbyAxLzI6IHswfSBhcmNoaXZvKHMpIHRyYWR1Y2lkbyhzKSBs
REM b2NhbGl6YWRvKHMpIiwKICAgICAgICAibG9nX2V0YXBhMl9yZWluaiI6IHUiUGFzbyAyLzI6
REM IGluaWNpYW5kbyBsYSByZWlueWVjY2nDs24iLAogICAgICAgICJsb2dfc2VtX21hcGFfYXJx
REM IjogdSJBcmNoaXZvIHNpbiBlbnRyYWRhIGVuIHswfSwgb21pdGlkbzogezF9IiwKICAgICAg
REM ICAibG9nX2ZhbGhhX2xlcl90cmFkIjogdSJGYWxsbyBhbCBsZWVyIGxhIHRyYWR1Y2Npw7Nu
REM IGRlIHswfTogezF9IiwKICAgICAgICAibG9nX2ZhbGhhX2luZXNwZXJhZGEiOiB1IkZhbGxv
REM IGluZXNwZXJhZG8gYWwgcmVpbnllY3RhciB7MH06IHsxfSIsCiAgICAgICAgImxvZ19mYWxo
REM YV9yZWluamV0YXIiOiB1IkZhbGxvIGFsIHJlaW55ZWN0YXIgezB9OiIsCiAgICAgICAgImxv
REM Z19saW5oYXNfcmVpbmoiOiB1InswfSBsw61uZWEocykgcmVpbnllY3RhZGEocykiLAogICAg
REM ICAgICJsb2dfcmVzX3RyYWRfZW5jb250cmFkb3MiOiB1IkFyY2hpdm9zIHRyYWR1Y2lkb3Mg
REM ZW5jb250cmFkb3MiLAogICAgICAgICJsb2dfcmVzX29rIjogdSJSZWlueWVjdGFkb3MgY29u
REM IMOpeGl0byIsCiAgICAgICAgImxvZ19yZXNfZmFsaGFzIjogdSJGYWxsb3MgKG5vIG1vZGlm
REM aWNhZG9zKSIsCiAgICAgICAgImxvZ19yZXNfc2VtX21hcGEiOiB1IlNpbiBlbnRyYWRhIGVu
REM IGVsIG1hcGEiLAogICAgICAgICJsb2dfcmVzX2xpbmhhc19yZWluaiI6IHUiTMOtbmVhcyBy
REM ZWlueWVjdGFkYXMiLAogICAgICAgICJtb2RvX2Rlc2NvbmhlY2lkbyI6IHUiTW9kbyBkZXNj
REM b25vY2lkbzogezAhcn0iLAogICAgICAgICJ0X3NlbV9leHRyYWNhbyI6IHUiTm8gc2UgZW5j
REM b250csOzIHVuYSBjYXJwZXRhIGNvbXBhdGlibGUgZGUgZGnDoWxvZ29zIGV4dHJhw61kb3Mu
REM IFVzYSBwcmltZXJvIGxhIG9wY2nDs24gMS4iLAogICAgICAgICJ0X21hcGFfaW52YWxpZG8i
REM OiB1Ik5vIHNlIHB1ZG8gbGVlciBlbCBtYXBhOiB7MH0iLAogICAgICAgICJ0X29yaWdlbV9w
REM cm9tcHQiOiB1IklkaW9tYSBkZSBvcmlnZW4gW2F1dG9dOiAiLAogICAgICAgICJ0X2Rlc3Rp
REM bm9fcHJvbXB0IjogdSJJZGlvbWEgZGUgZGVzdGlubyBbcHQtQlJdOiAiLAogICAgICAgICJ0
REM X2NvbmVjdGFuZG8iOiB1IlByb2JhbmRvIGxhIGNvbmV4acOzbiBjb24gR29vZ2xlIFRyYW5z
REM bGF0ZS4uLiIsCiAgICAgICAgInRfY29uZWN0YWRvIjogdSJDb25leGnDs24gY29uIEdvb2ds
REM ZSBUcmFuc2xhdGUgY29ycmVjdGEuIiwKICAgICAgICAidF9lcnJvX2NvbmV4YW8iOiB1IkZh
REM bGzDsyBHb29nbGUgVHJhbnNsYXRlOiB7MH0iLAogICAgICAgICJ0X2NhbmNlbGFkbyI6IHUi
REM VHJhZHVjY2nDs24gY2FuY2VsYWRhLiIsCiAgICAgICAgInRfcHJvY2Vzc2FuZG8iOiB1IlBy
REM b2Nlc2FuZG8gezB9IHRleHRvcyDDum5pY29zLi4uIiwKICAgICAgICAidF9hcnF1aXZvIjog
REM dSJPSyAgezB9ICAtPiAgezF9IHRleHRvKHMpIiwKICAgICAgICAidF9mYWxoYV90ZXh0byI6
REM IHUiRkFMTE8gYWwgdHJhZHVjaXIgZXN0ZSBhcmNoaXZvOyBzZSBtYW50dXZvIHNpbiBjYW1i
REM aW9zIGxhIGNvcGlhLiIsCiAgICAgICAgInRfbmVuaHVtYSI6IHUiTm8gc2UgcHJvY2Vzw7Mg
REM bmluZ8O6biB0ZXh0by4iLAogICAgICAgICJ0X3Byb250byI6IHUiVHJhZHVjY2nDs24gdGVy
REM bWluYWRhLiBDYXJwZXRhIGRlIHNhbGlkYTogezB9IiwKICAgICAgICAidF9sb2dfaW5pY2lv
REM IjogdSJEREFDIEdvb2dsZSBUcmFuc2xhdGUgLSBJTklDSU8iLAogICAgICAgICJ0X2xvZ19w
REM YXN0YSI6IHUiQ2FycGV0YSBkZSBlbnRyYWRhOiB7MH0iLAogICAgICAgICJ0X2xvZ19zYWlk
REM YSI6IHUiQ2FycGV0YSBkZSBzYWxpZGE6IHswfSIsCiAgICAgICAgInRfbG9nX2FycXVpdm8i
REM OiB1IlRleHRvcyBwcm9jZXNhZG9zIGVuIHswfSIsCiAgICAgICAgInRfbG9nX2ZhbGhhIjog
REM dSJGYWxsbyBlbiB7MH0iLAogICAgICAgICJ0X2xvZ19maW0iOiB1IkREQUMgR29vZ2xlIFRy
REM YW5zbGF0ZSAtIEZJTiIsCiAgICAgICAgInRfbG90ZV9pbmljaW8iOiB1IkxvdGUgezB9L3sx
REM fSAgLT4gIHsyfSB0ZXh0byhzKSBlbnZpYWRvKHMpIiwKICAgICAgICAidF9sb3RlX29rIjog
REM dSJMb3RlIHswfS97MX0gT0sgIC0+ICB7Mn0gdGV4dG8ocykgdHJhZHVjaWRvKHMpIGVuIHsz
REM Oi4xZn1zIiwKICAgICAgICAidF9sb3RlX2Vycm8iOiB1IkxvdGUgezB9L3sxfSBGQUxMw5Mg
REM IC0+ICB7Mn0iLAogICAgICAgICJ0X2ZhbGxiYWNrIjogdSJGYWxsYmFjayBpbmRpdmlkdWFs
REM IGluaWNpYWRvIHBhcmEgZWwgbG90ZSB7MH0vezF9IiwKICAgICAgICAidF9wcm9ncmVzc28i
REM OiB1IlByb2dyZXNvOiB7MH0vezF9IHRleHRvcyAgfCAgezJ9IGxvdGUocykgT0sgIHwgIHsz
REM fSBmYWxsbyhzKSIsCiAgICAgICAgInRfY29uZmlnX3BhcmFsZWxhIjogdSJQYXJhbGVsbzog
REM ezB9IHNvbGljaXR1ZGVzIHNpbXVsdMOhbmVhcyAgfCAgaGFzdGEgezF9IHRleHRvcyBwb3Ig
REM bG90ZSAgfCAgezJ9IGNhcmFjdGVyZXMgcG9yIGxvdGUiLAogICAgICAgICJ0X2NhY2hlIjog
REM dSJDYWNow6k6IHswfSB0cmFkdWNjacOzbihlcykgcmV1dGlsaXphZGEocykiLAogICAgICAg
REM ICJ0X2FycXVpdm9faW5pY2lvIjogdSJJTklDSU8gIHswfSAgLT4gIHsxfSB0ZXh0byhzKSIs
REM CiAgICAgICAgInRfYXJxdWl2b19maW0iOiB1IkZJTiAgezB9ICAtPiAgezF9IHRleHRvKHMp
REM IGVuIHsyOi4xZn1zIiwKICAgICAgICAiZXRhcGFfYmlibGlvdGVjYSI6IHUiUGFzbyAwLzM6
REM IGNvbnN1bHRhbmRvIGxhIGJpYmxpb3RlY2EgRERMQy9UZW1wbGF0ZSAoezB9IGFyY2hpdm9z
REM IGNhdGFsb2dhZG9zKS4uLiIsCiAgICAgICAgImJpYl9pZ25vcmFkbyI6IHUiSUdOIHswfSAg
REM LT4gIHNpbiBkacOhbG9nbyBuYXRpdm8gKHsxfSkiLAogICAgICAgICJiaWJfbm92b190ZXh0
REM byI6IHUiTlVFVk8gezB9ICAtPiAgezF9IGzDrW5lYShzKSBlbiB1biBhcmNoaXZvIG5vcm1h
REM bG1lbnRlIHNpbiBkacOhbG9nbyAoezJ9KSIsCiAgICAgICAgInJlc19iaWJfaWdub3JhZG9z
REM IjogdSJBcmNoaXZvcyBpZ25vcmFkb3MgcG9yIGxhIGJpYmxpb3RlY2EgKHswfSk6IiwKICAg
REM ICAgICAicmVzX2JpYl9ub3ZvcyI6IHUiQXJjaGl2b3MgZnVlcmEgZGVsIGVzdMOhbmRhciBk
REM ZSBsYSBiaWJsaW90ZWNhICh0ZXh0byBudWV2bykgKHswfSk6IiwKICAgICAgICAibG9nX2Jp
REM Yl9pZ25vcmFkbyI6IHUiezB9OiBpZ25vcmFkbyBwb3IgbGEgYmlibGlvdGVjYSAtLSB7MX0i
REM LAogICAgICAgICJsb2dfYmliX25vdm8iOiB1InswfTogdGV4dG8gbnVldm8gZW4gYXJjaGl2
REM byBzaW4gZGnDoWxvZ28gbmF0aXZvIC0tIHsxfSIsCiAgICAgICAgImxvZ19yZXNfYmliX2ln
REM bm9yYWRvcyI6IHUiSWdub3JhZG9zIHBvciBsYSBiaWJsaW90ZWNhIiwKICAgICAgICAibG9n
REM X3Jlc19iaWJfbm92b3MiOiB1IkFyY2hpdm9zIGNvbiB0ZXh0byBmdWVyYSBkZWwgZXN0w6Fu
REM ZGFyIiwKICAgIH0sCn0KCgpQUkVGTElHSFRfTUVOU0FHRU5TID0gewogICAgMTogewogICAg
REM ICAgICJ0aXR1bG8iOiB1IlZFUklGSUNBw4fDg08gUFLDiVZJQSAoU09NRU5URSBMRUlUVVJB
REM KSIsCiAgICAgICAgInN1YnRpdHVsbyI6IHUiTmFkYSBubyBqb2dvLCBubyBtYXBhIG91IG5h
REM cyBwYXN0YXMgZGUgdHJhYmFsaG8gc2Vyw6EgbW9kaWZpY2FkbyBuZXN0YSBldGFwYS4iLAog
REM ICAgICAgICJldGFwYV9leHRyYWlyIjogdSJFeHRyYcOnw6NvIGRlIGRpw6Fsb2dvcyIsCiAg
REM ICAgICAgImV0YXBhX3RyYWR1emlyIjogdSJUcmFkdcOnw6NvIGNvbSBHb29nbGUgVHJhbnNs
REM YXRlIiwKICAgICAgICAiZXRhcGFfcmVpbmpldGFyIjogdSJSZWludGVncmHDp8OjbyBkZSB0
REM cmFkdcOnw6NvIiwKICAgICAgICAib2siOiB1Ik9LIiwgImF2aXNvIjogdSJBVklTTyIsICJl
REM cnJvIjogdSJFUlJPIiwKICAgICAgICAiYXB0byI6IHUiUFLDiS1GTElHSFQ6IEFQVE8iLAog
REM ICAgICAgICJhcHRvX2F2aXNvIjogdSJQUsOJLUZMSUdIVDogQVBUTyBDT00gQVZJU08iLAog
REM ICAgICAgICJibG9xdWVhZG8iOiB1IlBSw4ktRkxJR0hUOiBCTE9RVUVBRE8iLAogICAgICAg
REM ICJnYW1lIjogdSJHYW1lIG9yaWdpbmFsIiwgImZvbnRlcyI6IHUiRm9udGVzIFJlbidQeSB2
REM aXPDrXZlaXMiLAogICAgICAgICJycHkiOiB1Ii5ycHkiLCAicnB5bSI6IHUiLnJweW0iLCAi
REM cmVucHlfcHkiOiB1Il9yZW4ucHkiLCAidHh0IjogdSIudHh0IiwKICAgICAgICAiY29tcGls
REM YWRvcyI6IHUiQ29tcGlsYWRvcy9hcnF1aXZvcyBlbXBhY290YWRvcyIsICJycHljIjogdSIu
REM cnB5YyIsICJycHltYyI6IHUiLnJweW1jIiwgInJwYSI6IHUiLnJwYSIsCiAgICAgICAgIm1h
REM cGEiOiB1Ik1hcGEgRERBQyIsICJlbnRyYWRhcyI6IHUiRW50cmFkYXMgbm8gbWFwYSIsCiAg
REM ICAgICAgImFycXVpdm9zX21hcGEiOiB1IkFycXVpdm9zIG5vIG1hcGEiLCAiYXJxdWl2b3Nf
REM ZW50cmFkYSI6IHUiQXJxdWl2b3MgbmEgcGFzdGEgZGUgdHJhYmFsaG8iLAogICAgICAgICJj
REM b3JyZXNwb25kZW5jaWEiOiB1IkNvcnJlc3BvbmTDqm5jaWEgZG9zIHRleHRvcyIsCiAgICAg
REM ICAgImZvbnRlc19yZWlual90aXR1bG8iOiB1IkZPTlRFUyBESVNQT07DjVZFSVMgUEFSQSBS
REM RUlOVEVHUkHDh8ODTyIsCiAgICAgICAgImZvbnRlc19yZWlual90b3RhbCI6IHUiezB9IGZv
REM bnRlKHMpIGVuY29udHJhZGEocykiLAogICAgICAgICJmb250ZXNfcmVpbmpfaXRlbSI6IHUi
REM W3swfV0gezF9IiwKICAgICAgICAiZm9udGVzX3JlaW5qX3Bhc3RhIjogdSJQYXN0YSIsCiAg
REM ICAgICAgImZvbnRlc19yZWlual9jYW1pbmhvIjogdSJDYW1pbmhvIiwKICAgICAgICAiZm9u
REM dGVzX3JlaW5qX2FycXVpdm9zIjogdSJBcnF1aXZvcyIsCiAgICAgICAgImZvbnRlc19yZWlu
REM al90ZXh0b3MiOiB1IlRleHRvcyIsCiAgICAgICAgImZvbnRlc19yZWlual9jb3JyZXNwb25k
REM ZW5jaWEiOiB1IkNvcnJlc3BvbmTDqm5jaWEiLAogICAgICAgICJ0cmlwbG8iOiB1Ik1vbsOz
REM bG9nbyBjb20gYXNwYXMgdHJpcGxhcyIsCiAgICAgICAgInRyaXBsb19tc2ciOiB1IkZvcmFt
REM IGVuY29udHJhZGFzIHN0cmluZ3MgdHJpcGxhcyBkZSBwb3Nzw612ZWwgbW9uw7Nsb2dvOyBl
REM bGFzIHJlY2ViZW0gYXZpc28gcG9ycXVlIGVzc2UgZm9ybWF0byBleGlnZSBhbsOhbGlzZSBl
REM c3BlY8OtZmljYSBwYXJhIG7Do28gYWx0ZXJhciBhIGVzdHJ1dHVyYS4iLAogICAgICAgICJ0
REM bCI6IHUiUGFzdGEgdGwgZXhpc3RlbnRlIiwKICAgICAgICAidGxfbXNnIjogdSJBIHBhc3Rh
REM IHRsIGZvaSBpZGVudGlmaWNhZGEgZSBzZXLDoSBpZ25vcmFkYSBwZWxvIGV4dHJhdG9yOyBz
REM ZXUgY29udGXDumRvIG7Do28gcGFydGljaXBhIGRhIHRyYWR1w6fDo28gbmVtIGRhIHJlaW5q
REM ZcOnw6NvLiIsCiAgICAgICAgInNlbV9mb250ZSI6IHUiTsOjbyBow6EgZm9udGUgLnJweS8u
REM cnB5bS9fcmVuLnB5IHZpc8OtdmVsIG5vIGdhbWUuIiwKICAgICAgICAiY29tcGlsYWRvX29u
REM bHkiOiB1IkjDoSBhcnF1aXZvcyAucnB5Yy8ucnB5bWMvLnJwYSwgbWFzIG7Do28gaMOhIGZv
REM bnRlIGRlIHNjcmlwdCB2aXPDrXZlbC4gRGVzY29tcGFjdGUvZGVzY29tcGlsZSBvIHByb2pl
REM dG8gYW50ZXMgZGUgdXNhciBhIGV4dHJhw6fDo28gZGUgZGnDoWxvZ29zLiIsCiAgICAgICAg
REM ImdhbWVfaW5leGlzdGVudGUiOiB1IkEgcGFzdGEgZ2FtZSBuw6NvIGZvaSBlbmNvbnRyYWRh
REM IGUgYSByYWl6IHRhbWLDqW0gbsOjbyBwYXJlY2Ugc2VyIHVtIGRpcmV0w7NyaW8gZGUgZ2Ft
REM ZSB2w6FsaWRvLiIsCiAgICAgICAgImVudHJhZGFfaW5leGlzdGVudGUiOiB1Ik5lbmh1bWEg
REM cGFzdGEgZGUgZGnDoWxvZ29zIGV4dHJhw61kb3MgY29tcGF0w612ZWwgZm9pIGVuY29udHJh
REM ZGEuIiwKICAgICAgICAibWFwYV9pbmV4aXN0ZW50ZSI6IHUiTyBhcnF1aXZvIGRlIG1hcGEg
REM bsOjbyBmb2kgZW5jb250cmFkby4iLAogICAgICAgICJtYXBhX2xlaXR1cmEiOiB1IkZhbGhh
REM IGFvIGxlciBvIG1hcGE6IHswfSIsCiAgICAgICAgIm5lbmh1bV90ZXh0byI6IHUiQSBwYXN0
REM YSBkZSB0cmFiYWxobyBuw6NvIGNvbnTDqW0gZW50cmFkYXMgZGUgdGV4dG8gY29tcGF0w612
REM ZWlzIGNvbSBvIG1hcGEuIiwKICAgICAgICAiY29udGFnZW0iOiB1Ik8gbWFwYSBlc3BlcmEg
REM ezB9IHRleHRvKHMpLCBtYXMgYSBwYXN0YSBjb250w6ltIHsxfSB0ZXh0byhzKS4iLAogICAg
REM ICAgICJzZW1fc2FpZGEiOiB1IkFpbmRhIG7Do28gZXhpc3RlIHVtYSBwYXN0YSB0cmFkdXpp
REM ZGE7IGlzc28gw6kgZXNwZXJhZG8gYW50ZXMgZGEgdHJhZHXDp8Ojby4iLAogICAgICAgICJj
REM b250aW51YXIiOiB1IkEgZXRhcGEgcG9kZSBjb250aW51YXIuIiwKICAgIH0sCiAgICAyOiB7
REM CiAgICAgICAgInRpdHVsbyI6IHUiUFJFRkxJR0hUIENIRUNLIChSRUFELU9OTFkpIiwKICAg
REM ICAgICAic3VidGl0dWxvIjogdSJOb3RoaW5nIGluIHRoZSBnYW1lLCBtYXAsIG9yIHdvcmsg
REM Zm9sZGVycyB3aWxsIGJlIG1vZGlmaWVkIGR1cmluZyB0aGlzIGNoZWNrLiIsCiAgICAgICAg
REM ImV0YXBhX2V4dHJhaXIiOiB1IkRpYWxvZ3VlIGV4dHJhY3Rpb24iLCAiZXRhcGFfdHJhZHV6
REM aXIiOiB1Ikdvb2dsZSBUcmFuc2xhdGUiLCAiZXRhcGFfcmVpbmpldGFyIjogdSJUcmFuc2xh
REM dGlvbiByZWluamVjdGlvbiIsCiAgICAgICAgIm9rIjogdSJPSyIsICJhdmlzbyI6IHUiV0FS
REM TklORyIsICJlcnJvIjogdSJFUlJPUiIsCiAgICAgICAgImFwdG8iOiB1IlBSRUZMSUdIVDog
REM UkVBRFkiLCAiYXB0b19hdmlzbyI6IHUiUFJFRkxJR0hUOiBSRUFEWSBXSVRIIFdBUk5JTkci
REM LCAiYmxvcXVlYWRvIjogdSJQUkVGTElHSFQ6IEJMT0NLRUQiLAogICAgICAgICJnYW1lIjog
REM dSJPcmlnaW5hbCBnYW1lIiwgImZvbnRlcyI6IHUiVmlzaWJsZSBSZW4nUHkgc291cmNlcyIs
REM ICJycHkiOiB1Ii5ycHkiLCAicnB5bSI6IHUiLnJweW0iLCAicmVucHlfcHkiOiB1Il9yZW4u
REM cHkiLCAidHh0IjogdSIudHh0IiwKICAgICAgICAiY29tcGlsYWRvcyI6IHUiQ29tcGlsZWQv
REM cGFja2VkIGZpbGVzIiwgInJweWMiOiB1Ii5ycHljIiwgInJweW1jIjogdSIucnB5bWMiLCAi
REM cnBhIjogdSIucnBhIiwKICAgICAgICAibWFwYSI6IHUiRERBQyBtYXAiLCAiZW50cmFkYXMi
REM OiB1Ik1hcCBlbnRyaWVzIiwgImFycXVpdm9zX21hcGEiOiB1IkZpbGVzIGluIG1hcCIsICJh
REM cnF1aXZvc19lbnRyYWRhIjogdSJGaWxlcyBpbiB3b3JrIGZvbGRlciIsCiAgICAgICAgImNv
REM cnJlc3BvbmRlbmNpYSI6IHUiVGV4dCBjb3JyZXNwb25kZW5jZSIsCiAgICAgICAgImZvbnRl
REM c19yZWlual90aXR1bG8iOiB1IkFWQUlMQUJMRSBTT1VSQ0VTIEZPUiBSRUlOSkVDVElPTiIs
REM CiAgICAgICAgImZvbnRlc19yZWlual90b3RhbCI6IHUiezB9IHNvdXJjZShzKSBmb3VuZCIs
REM CiAgICAgICAgImZvbnRlc19yZWlual9pdGVtIjogdSJbezB9XSB7MX0iLAogICAgICAgICJm
REM b250ZXNfcmVpbmpfcGFzdGEiOiB1IkZvbGRlciIsCiAgICAgICAgImZvbnRlc19yZWlual9j
REM YW1pbmhvIjogdSJQYXRoIiwKICAgICAgICAiZm9udGVzX3JlaW5qX2FycXVpdm9zIjogdSJG
REM aWxlcyIsCiAgICAgICAgImZvbnRlc19yZWlual90ZXh0b3MiOiB1IlRleHRzIiwKICAgICAg
REM ICAiZm9udGVzX3JlaW5qX2NvcnJlc3BvbmRlbmNpYSI6IHUiQ29ycmVzcG9uZGVuY2UiLAog
REM ICAgICAgICJ0cmlwbG8iOiB1IlRyaXBsZS1xdW90ZWQgbW9ub2xvZ3VlIiwKICAgICAgICAi
REM dHJpcGxvX21zZyI6IHUiVHJpcGxlLXF1b3RlZCBzdHJpbmdzIHRoYXQgbWF5IGJlIG1vbm9s
REM b2d1ZXMgd2VyZSBmb3VuZDsgdGhleSByZWNlaXZlIGEgd2FybmluZyBiZWNhdXNlIHRoaXMg
REM Zm9ybWF0IG5lZWRzIHNwZWNpZmljIGhhbmRsaW5nIHRvIGF2b2lkIGNoYW5naW5nIHN0cnVj
REM dHVyZS4iLAogICAgICAgICJ0bCI6IHUiRXhpc3RpbmcgdGwgZm9sZGVyIiwgInRsX21zZyI6
REM IHUiVGhlIHRsIGZvbGRlciB3YXMgZGV0ZWN0ZWQgYW5kIHdpbGwgYmUgaWdub3JlZCBieSB0
REM aGUgZXh0cmFjdG9yOyBpdHMgY29udGVudHMgZG8gbm90IHBhcnRpY2lwYXRlIGluIHRyYW5z
REM bGF0aW9uIG9yIHJlaW5qZWN0aW9uLiIsCiAgICAgICAgInNlbV9mb250ZSI6IHUiTm8gdmlz
REM aWJsZSAucnB5Ly5ycHltL19yZW4ucHkgc291cmNlIHdhcyBmb3VuZCBpbiB0aGUgZ2FtZS4i
REM LAogICAgICAgICJjb21waWxhZG9fb25seSI6IHUiLnJweWMvLnJweW1jLy5ycGEgZmlsZXMg
REM ZXhpc3QsIGJ1dCBubyB2aXNpYmxlIHNjcmlwdCBzb3VyY2UgZXhpc3RzLiBVbnBhY2svZGVj
REM b21waWxlIHRoZSBwcm9qZWN0IGJlZm9yZSB1c2luZyBkaWFsb2d1ZSBleHRyYWN0aW9uLiIs
REM CiAgICAgICAgImdhbWVfaW5leGlzdGVudGUiOiB1IlRoZSBnYW1lIGZvbGRlciB3YXMgbm90
REM IGZvdW5kIGFuZCB0aGUgcm9vdCBkb2VzIG5vdCBsb29rIGxpa2UgYSB2YWxpZCBnYW1lIGRp
REM cmVjdG9yeS4iLAogICAgICAgICJlbnRyYWRhX2luZXhpc3RlbnRlIjogdSJObyBjb21wYXRp
REM YmxlIGV4dHJhY3RlZC1kaWFsb2d1ZSBmb2xkZXIgd2FzIGZvdW5kLiIsICJtYXBhX2luZXhp
REM c3RlbnRlIjogdSJUaGUgbWFwIGZpbGUgd2FzIG5vdCBmb3VuZC4iLAogICAgICAgICJtYXBh
REM X2xlaXR1cmEiOiB1IkZhaWxlZCB0byByZWFkIHRoZSBtYXA6IHswfSIsICJuZW5odW1fdGV4
REM dG8iOiB1IlRoZSB3b3JrIGZvbGRlciBjb250YWlucyBubyB0ZXh0IGVudHJpZXMgY29tcGF0
REM aWJsZSB3aXRoIHRoZSBtYXAuIiwKICAgICAgICAiY29udGFnZW0iOiB1IlRoZSBtYXAgZXhw
REM ZWN0cyB7MH0gdGV4dChzKSwgYnV0IHRoZSBmb2xkZXIgY29udGFpbnMgezF9IHRleHQocyku
REM IiwKICAgICAgICAic2VtX3NhaWRhIjogdSJObyB0cmFuc2xhdGVkIG91dHB1dCBmb2xkZXIg
REM ZXhpc3RzIHlldDsgdGhhdCBpcyBleHBlY3RlZCBiZWZvcmUgdHJhbnNsYXRpb24uIiwgImNv
REM bnRpbnVhciI6IHUiVGhlIHN0ZXAgY2FuIGNvbnRpbnVlLiIsCiAgICB9LAogICAgMzogewog
REM ICAgICAgICJ0aXR1bG8iOiB1IlZFUklGSUNBQ0nDk04gUFJFVklBIChTT0xPIExFQ1RVUkEp
REM IiwKICAgICAgICAic3VidGl0dWxvIjogdSJOYWRhIGVuIGVsIGp1ZWdvLCBlbCBtYXBhIG8g
REM bGFzIGNhcnBldGFzIGRlIHRyYWJham8gc2Vyw6EgbW9kaWZpY2FkbyBkdXJhbnRlIGVzdGEg
REM Y29tcHJvYmFjacOzbi4iLAogICAgICAgICJldGFwYV9leHRyYWlyIjogdSJFeHRyYWNjacOz
REM biBkZSBkacOhbG9nb3MiLCAiZXRhcGFfdHJhZHV6aXIiOiB1Ikdvb2dsZSBUcmFuc2xhdGUi
REM LCAiZXRhcGFfcmVpbmpldGFyIjogdSJSZWludGVncmFjacOzbiBkZSB0cmFkdWNjacOzbiIs
REM CiAgICAgICAgIm9rIjogdSJPSyIsICJhdmlzbyI6IHUiQVZJU08iLCAiZXJybyI6IHUiRVJS
REM T1IiLAogICAgICAgICJhcHRvIjogdSJQUkVGTElHSFQ6IEFQVE8iLCAiYXB0b19hdmlzbyI6
REM IHUiUFJFRkxJR0hUOiBBUFRPIENPTiBBVklTTyIsICJibG9xdWVhZG8iOiB1IlBSRUZMSUdI
REM VDogQkxPUVVFQURPIiwKICAgICAgICAiZ2FtZSI6IHUiSnVlZ28gb3JpZ2luYWwiLCAiZm9u
REM dGVzIjogdSJGdWVudGVzIFJlbidQeSB2aXNpYmxlcyIsICJycHkiOiB1Ii5ycHkiLCAicnB5
REM bSI6IHUiLnJweW0iLCAicmVucHlfcHkiOiB1Il9yZW4ucHkiLCAidHh0IjogdSIudHh0IiwK
REM ICAgICAgICAiY29tcGlsYWRvcyI6IHUiQ29tcGlsYWRvcy9hcmNoaXZvcyBlbXBhcXVldGFk
REM b3MiLCAicnB5YyI6IHUiLnJweWMiLCAicnB5bWMiOiB1Ii5ycHltYyIsICJycGEiOiB1Ii5y
REM cGEiLAogICAgICAgICJtYXBhIjogdSJNYXBhIEREQUMiLCAiZW50cmFkYXMiOiB1IkVudHJh
REM ZGFzIGVuIGVsIG1hcGEiLCAiYXJxdWl2b3NfbWFwYSI6IHUiQXJjaGl2b3MgZW4gZWwgbWFw
REM YSIsICJhcnF1aXZvc19lbnRyYWRhIjogdSJBcmNoaXZvcyBlbiBsYSBjYXJwZXRhIGRlIHRy
REM YWJham8iLAogICAgICAgICJjb3JyZXNwb25kZW5jaWEiOiB1IkNvcnJlc3BvbmTDqm5jaWEg
REM ZGUgdGV4dG9zIiwKICAgICAgICAiZm9udGVzX3JlaW5qX3RpdHVsbyI6IHUiRlVFTlRFUyBE
REM SVNQT05JQkxFUyBQQVJBIExBIFJFSU5TRVJDScOTTiIsCiAgICAgICAgImZvbnRlc19yZWlu
REM al90b3RhbCI6IHUiezB9IGZ1ZW50ZShzKSBlbmNvbnRyYWRhKHMpIiwKICAgICAgICAiZm9u
REM dGVzX3JlaW5qX2l0ZW0iOiB1Ilt7MH1dIHsxfSIsCiAgICAgICAgImZvbnRlc19yZWlual9w
REM YXN0YSI6IHUiQ2FycGV0YSIsCiAgICAgICAgImZvbnRlc19yZWlual9jYW1pbmhvIjogdSJS
REM dXRhIiwKICAgICAgICAiZm9udGVzX3JlaW5qX2FycXVpdm9zIjogdSJBcmNoaXZvcyIsCiAg
REM ICAgICAgImZvbnRlc19yZWlual90ZXh0b3MiOiB1IlRleHRvcyIsCiAgICAgICAgImZvbnRl
REM c19yZWlual9jb3JyZXNwb25kZW5jaWEiOiB1IkNvcnJlc3BvbmRlbmNpYSIsCiAgICAgICAg
REM InRyaXBsbyI6IHUiTW9uw7Nsb2dvIGNvbiBjb21pbGxhcyB0cmlwbGVzIiwKICAgICAgICAi
REM dHJpcGxvX21zZyI6IHUiU2UgZW5jb250cmFyb24gY2FkZW5hcyB0cmlwbGVzIHF1ZSBwdWVk
REM ZW4gc2VyIG1vbsOzbG9nb3M7IHJlY2liZW4gdW4gYXZpc28gcG9ycXVlIGVzdGUgZm9ybWF0
REM byBuZWNlc2l0YSB1biBtYW5lam8gZXNwZWPDrWZpY28gcGFyYSBubyBjYW1iaWFyIGxhIGVz
REM dHJ1Y3R1cmEuIiwKICAgICAgICAidGwiOiB1IkNhcnBldGEgdGwgZXhpc3RlbnRlIiwgInRs
REM X21zZyI6IHUiU2UgZGV0ZWN0w7MgbGEgY2FycGV0YSB0bCB5IGVsIGV4dHJhY3RvciBsYSBp
REM Z25vcmFyw6E7IHN1IGNvbnRlbmlkbyBubyBwYXJ0aWNpcGEgZW4gbGEgdHJhZHVjY2nDs24g
REM bmkgbGEgcmVpbnllY2Npw7NuLiIsCiAgICAgICAgInNlbV9mb250ZSI6IHUiTm8gc2UgZW5j
REM b250csOzIHVuYSBmdWVudGUgLnJweS8ucnB5bS9fcmVuLnB5IHZpc2libGUgZW4gZWwganVl
REM Z28uIiwKICAgICAgICAiY29tcGlsYWRvX29ubHkiOiB1IkV4aXN0ZW4gLnJweWMvLnJweW1j
REM Ly5ycGEsIHBlcm8gbm8gaGF5IGZ1ZW50ZSBkZSBzY3JpcHQgdmlzaWJsZS4gRGVzZW1wYXF1
REM ZXRhL2Rlc2NvbXBpbGEgZWwgcHJveWVjdG8gYW50ZXMgZGUgdXNhciBsYSBleHRyYWNjacOz
REM biBkZSBkacOhbG9nb3MuIiwKICAgICAgICAiZ2FtZV9pbmV4aXN0ZW50ZSI6IHUiTm8gc2Ug
REM ZW5jb250csOzIGxhIGNhcnBldGEgZ2FtZSB5IGxhIHJhw616IHRhbXBvY28gcGFyZWNlIHVu
REM IGRpcmVjdG9yaW8gZ2FtZSB2w6FsaWRvLiIsCiAgICAgICAgImVudHJhZGFfaW5leGlzdGVu
REM dGUiOiB1Ik5vIHNlIGVuY29udHLDsyB1bmEgY2FycGV0YSBjb21wYXRpYmxlIGRlIGRpw6Fs
REM b2dvcyBleHRyYcOtZG9zLiIsICJtYXBhX2luZXhpc3RlbnRlIjogdSJObyBzZSBlbmNvbnRy
REM w7MgZWwgYXJjaGl2byBkZSBtYXBhLiIsCiAgICAgICAgIm1hcGFfbGVpdHVyYSI6IHUiTm8g
REM c2UgcHVkbyBsZWVyIGVsIG1hcGE6IHswfSIsICJuZW5odW1fdGV4dG8iOiB1IkxhIGNhcnBl
REM dGEgZGUgdHJhYmFqbyBubyBjb250aWVuZSBlbnRyYWRhcyBkZSB0ZXh0byBjb21wYXRpYmxl
REM cyBjb24gZWwgbWFwYS4iLAogICAgICAgICJjb250YWdlbSI6IHUiRWwgbWFwYSBlc3BlcmEg
REM ezB9IHRleHRvKHMpLCBwZXJvIGxhIGNhcnBldGEgY29udGllbmUgezF9IHRleHRvKHMpLiIs
REM CiAgICAgICAgInNlbV9zYWlkYSI6IHUiVG9kYXbDrWEgbm8gZXhpc3RlIHVuYSBjYXJwZXRh
REM IHRyYWR1Y2lkYTsgZXN0byBlcyBlc3BlcmFkbyBhbnRlcyBkZSB0cmFkdWNpci4iLCAiY29u
REM dGludWFyIjogdSJMYSBldGFwYSBwdWVkZSBjb250aW51YXIuIiwKICAgIH0sCn0KCgpkZWYg
REM cHRleHQoY2hhdmUpOgogICAgcmV0dXJuIFBSRUZMSUdIVF9NRU5TQUdFTlMuZ2V0KElESU9N
REM QSwgUFJFRkxJR0hUX01FTlNBR0VOU1sxXSkuZ2V0KGNoYXZlLCBQUkVGTElHSFRfTUVOU0FH
REM RU5TWzFdW2NoYXZlXSkKCgpkZWYgdChjaGF2ZSk6CiAgICByZXR1cm4gTUVOU0FHRU5TLmdl
REM dChJRElPTUEsIE1FTlNBR0VOU1sxXSkuZ2V0KGNoYXZlLCBNRU5TQUdFTlNbMV1bY2hhdmVd
REM KQoKIyBNZW5zYWdlbnMgZGEgY2FtYWRhIER1YWxCcmFpbjogdG9kb3Mgb3MgdGV4dG9zIHZp
REM c8OtdmVpcyBkZXN0YSBjYW1hZGEgZmljYW0KIyBkaXNwb27DrXZlaXMgbm9zIHRyw6pzIGlk
REM aW9tYXMgcGFyYSBpbXBlZGlyIHJlZ3Jlc3PDtWVzIGRlIGludGVyZmFjZS4KRFVBTF9NRU5T
REM QUdFTlMgPSB7CiAgICAxOiB7CiAgICAgICAgInRpdHVsbyI6IHUiRERBQyBFeHRyYcOnw6Nv
REM IER1YWwgLSBWMTE4IiwKICAgICAgICAibm92YV9leGVjdWNhbyI6IHUiTk9WQSBFWEVDVcOH
REM w4NPOiByZWxhdMOzcmlvIGRpYWduw7NzdGljbyDDqSB0ZW1wb3LDoXJpbyBlIHNlcsOhIHJl
REM bW92aWRvIGFvIGNvbmNsdWlyIGNvbSBzdWNlc3NvLiIsCiAgICAgICAgImdhbWVfbWlzc2lu
REM ZyI6IHUiUGFzdGEgZ2FtZSBuw6NvIGVuY29udHJhZGEuIiwKICAgICAgICAic3RhZ2UxX3N0
REM YXJ0IjogdSJFVEFQQSAxLzE0IC0gRXNjYW5lYW5kbyBhIHBhc3RhIGdhbWUuLi4iLAogICAg
REM ICAgICJzdGFnZTFfZG9uZSI6IHUiRVRBUEEgMS8xNCAtIEVzY2FuZWFyIGdhbWU6IHswfSBh
REM cnF1aXZvKHMpIFtPS10iLAogICAgICAgICJzdGFnZTJfc3RhcnQiOiB1IkVUQVBBIDIvMTQg
REM LSBNb3RvciBEREFDOiBpbmljaWFuZG8gZXh0cmHDp8Ojby4uLiIsCiAgICAgICAgInN0YWdl
REM Ml9kb25lIjogdSJFVEFQQSAyLzE0IC0gTW90b3IgRERBQzogezB9IGNhbmRpZGF0b3MgW09L
REM XSIsCiAgICAgICAgInN0YWdlM19zdGFydCI6IHUiRVRBUEEgMy8xNCAtIE1vdG9yIFJlbidQ
REM eTogaW5pY2lhbmRvIE9yw6FjdWxvLi4uIiwKICAgICAgICAic3RhZ2UzX2RvbmUiOiB1IkVU
REM QVBBIDMvMTQgLSBNb3RvciBSZW4nUHk6IHswfSBjYW5kaWRhdG9zIHwgYXRpdm89ezF9IFt7
REM Mn1dIiwKICAgICAgICAic3RhZ2U0X2RvbmUiOiB1IkVUQVBBIDQvMTQgLSBDb21wYXJhw6fD
REM o286IGNvbmNvcmTDom5jaWFzPXswfSB8IEREQUMtb25seT17MX0gfCBSZW4nUHktb25seT17
REM Mn0gW09LXSIsCiAgICAgICAgInN0YWdlNV9kb25lIjogdSJFVEFQQSA1LzE0IC0gRHVwbGlj
REM YXRhcyBjb25zb2xpZGFkYXM6IHswfSBbT0tdIiwKICAgICAgICAic3RhZ2U2X2RvbmUiOiB1
REM IkVUQVBBIDYvMTQgLSBTb2JyZXBvc2nDp8O1ZXMgcmVzb2x2aWRhczogezB9IGNvbmZsaXRv
REM KHMpIFtPS10iLAogICAgICAgICJzdGFnZTdfZG9uZSI6IHUiRVRBUEEgNy8xNCAtIENvbnRl
REM eHRvOiB7MH0gW09LXSIsCiAgICAgICAgInN0YWdlOF9kb25lIjogdSJFVEFQQSA4LzE0IC0g
REM Q2xhc3NpZmljYcOnw6NvOiBhY2VpdG9zPXswfSB8IHJldmlzw6NvPXsxfSB8IGlnbm9yYWRv
REM cz17Mn0gfCBlbmdpbmUtY29tbW9uPXszfSB8IGdsb2JhaXM9ezR9IFtPS10iLAogICAgICAg
REM ICJzdGFnZTlfZG9uZSI6IHUiRVRBUEEgOS8xNCAtIE1hcGEgY2Fuw7RuaWNvOiB7MH0gZW50
REM cmFkYXMgW09LXSIsCiAgICAgICAgInN0YWdlMTBfcGVuZGluZyI6IHUiRVRBUEEgMTAvMTQg
REM LSBQcmVwYXJhw6fDo28gcGFyYSB0cmFkdcOnw6NvOiBQRU5ERU5URSAoT3DDp8OjbyAyKSIs
REM CiAgICAgICAgInN0YWdlMTFfcGVuZGluZyI6IHUiRVRBUEEgMTEvMTQgLSBWYWxpZGHDp8Oj
REM byBkZSB0b2tlbnM6IFBFTkRFTlRFIChhcMOzcyBPcMOnw6NvIDIpIiwKICAgICAgICAic3Rh
REM Z2UxMl9wZW5kaW5nIjogdSJFVEFQQSAxMi8xNCAtIFJlaW50ZWdyYcOnw6NvOiBQRU5ERU5U
REM RSAoT3DDp8OjbyAzKSIsCiAgICAgICAgInN0YWdlMTNfcGVuZGluZyI6IHUiRVRBUEEgMTMv
REM MTQgLSBWYWxpZGHDp8OjbyBkYSBzYcOtZGE6IFBFTkRFTlRFIChPcMOnw6NvIDMpIiwKICAg
REM ICAgICAic3RhZ2UxNF9wZW5kaW5nIjogdSJFVEFQQSAxNC8xNCAtIEF1ZGl0b3JpYSBmaW5h
REM bDogUEVOREVOVEUgKE9ww6fDo28gMykiLAogICAgICAgICJwZW5kaW5nX2xvZyI6IHUiRVRB
REM UEFTIDEwLTE0OiBhZGlhZGFzIGNvcnJldGFtZW50ZSBwYXJhIHRyYWR1w6fDo28vcmVpbnRl
REM Z3Jhw6fDo287IG7Do28gc8OjbyBkZWNsYXJhZGFzIGV4ZWN1dGFkYXMgbmEgZXh0cmHDp8Oj
REM by4iLAogICAgICAgICJibG9ja2VkX2xvZyI6IHUiRFVBTEJSQUlOIEJMT1FVRUFETzogbyBt
REM b3RvciBSZW4nUHkgbsOjbyBmb2kgYXRpdmFkby4gTyBtb3RvciBEREFDIG7Do28gY29udGlu
REM dWFyw6Egc296aW5oby4iLAogICAgICAgICJibG9ja2VkX3JlYXNvbiI6IHUiT3LDoWN1bG8g
REM UmVuJ1B5IG9icmlnYXTDs3JpbyBpbmF0aXZvOyBkZXRhbGhlcyByZWdpc3RyYWRvcyBubyBk
REM aWFnbsOzc3RpY28gZG8gU0RLLiIsCiAgICAgICAgImZpbmFsX3N0YXR1cyI6IHUiRVhUUkHD
REM h8ODTyBEVUFMIENPTkNMVcONREEiLAogICAgICAgICJvcmFjbGVfeWVzIjogdSJTSU0iLAog
REM ICAgICAgICJvcmFjbGVfbm8iOiB1Ik7Dg08iLAogICAgICAgICJzdGF0dXNfb2siOiB1Ik9L
REM IiwKICAgICAgICAic3RhdHVzX2ZhaWwiOiB1IkZBTEhBIiwKICAgICAgICAibGFiZWxfc3Rh
REM dHVzIjogdSJTdGF0dXMgZmluYWwiLAogICAgICAgICJsYWJlbF9zY2FubmVkIjogdSJBcnF1
REM aXZvcyBlc2NhbmVhZG9zIiwKICAgICAgICAibGFiZWxfZGRhYyI6IHUiQ2FuZGlkYXRvcyBE
REM REFDIiwKICAgICAgICAibGFiZWxfcmVucHkiOiB1IkNhbmRpZGF0b3MgUmVuJ1B5IiwKICAg
REM ICAgICAibGFiZWxfY29uY29yZCI6IHUiQ29uY29yZMOibmNpYXMgRERBQyArIFJlbidQeSIs
REM CiAgICAgICAgImxhYmVsX29ubHlfZGRhYyI6IHUiU29tZW50ZSBEREFDIiwKICAgICAgICAi
REM bGFiZWxfb25seV9yZW5weSI6IHUiU29tZW50ZSBSZW4nUHkiLAogICAgICAgICJsYWJlbF9j
REM YW5vbmljYWwiOiB1IkVudHJhZGFzIGNhbsO0bmljYXMiLAogICAgICAgICJsYWJlbF9vcmFj
REM bGUiOiB1Ik9yw6FjdWxvIFJlbidQeSBhdGl2byIsCiAgICAgICAgImxhYmVsX2V4ZWN1dGVk
REM IjogdSJFdGFwYXMgZXhlY3V0YWRhcyIsCiAgICAgICAgImxhYmVsX3BlbmRpbmciOiB1IkV0
REM YXBhcyBwZW5kZW50ZXMiLAogICAgICAgICJsYWJlbF90aW1lIjogdSJUZW1wbyB0b3RhbCIs
REM CiAgICAgICAgImludGVybmFsX2Vycm9yIjogdSJFUlJPIElOVEVSTk8gTk8gRFVBTEJSQUlO
REM IFYxMTg6IHswfSIsCiAgICAgICAgImludGVybmFsX2ZpbmFsIjogdSJFUlJPX0lOVEVSTk8i
REM LAogICAgICAgICJ0cmFuc2xhdGVfc3RhZ2UiOiB1IkVUQVBBIDEwLzE0IC0gR29vZ2xlIFRy
REM YW5zbGF0ZSByZWNlYmUgc29tZW50ZSBlbnRyYWRhcyBjYW7DtG5pY2FzLiIsCiAgICAgICAg
REM InRva2Vuc19zdGFnZSI6IHUiRVRBUEEgMTEvMTQgLSBWYWxpZGHDp8OjbyBmaW5hbCBkZSB0
REM b2tlbnM6IHswfSIsCiAgICAgICAgInJlaW5qZWN0X3N0YWdlIjogdSJFVEFQQSAxMi8xNCAt
REM IFJlaW50ZWdyYcOnw6NvIGNhbsO0bmljYS4uLiIsCiAgICAgICAgIm91dHB1dF9zdGFnZSI6
REM IHUiRVRBUEEgMTMvMTQgLSBWYWxpZGHDp8OjbyBkYSBzYcOtZGE6IE9LIiwKICAgICAgICAi
REM YXVkaXRfc3RhZ2UiOiB1IkVUQVBBIDE0LzE0IC0gQXVkaXRvcmlhIGZpbmFsOiB2ZXJpZmlj
REM YW5kbyBjb2xpc8O1ZXMgZSBjb21waWxhZG9zLi4uIiwKICAgICAgICAiYXVkaXRfc3VtbWFy
REM eSI6IHUiRVRBUEEgMTQvMTQgLSBBdWRpdG9yaWEgZGUgY29saXPDtWVzOiByZW1vdmlkb3M9
REM ezB9IHwgY29uZmxpdG9zPXsxfSB8IHByZXNlcnZhZG9zPXsyfSB8IC5ycHljIHBhcmVhZG9z
REM IHJlcG9ydGFkb3M9ezN9IiwKICAgICAgICAiaW5zdGFsbGVyIjogdSJBcGxpY2Fkb3Igc2Vn
REM dXJvOiB7MH0iLAogICAgICAgICJsYWJlbF9yZW1vdmVkIjogdSJTY3JpcHRzIGdhbWUvY29t
REM bW9uIHJlbW92aWRvcyBwb3IgaGFzaCBpZMOqbnRpY28iLAogICAgICAgICJsYWJlbF9jb25m
REM bGljdHMiOiB1IkNvbmZsaXRvcyBnYW1lL2NvbW1vbiIsCiAgICAgICAgImxhYmVsX3ByZXNl
REM cnZlZCI6IHUiUHJlc2VydmFkb3MgcG9yIG1hcGEgYW50aWdvIiwKICAgICAgICAicmVwb3J0
REM X3RpdGxlIjogdSJSZWxhdMOzcmlvIGRlIGNvbGlzw7VlcyBkbyBEREFDIiwKICAgICAgICAi
REM cmVwb3J0X25vX2lzc3VlIjogdSJOZW5odW1hIGNvbGlzw6NvIG91IGluY29uc2lzdMOqbmNp
REM YSBmb2kgZW5jb250cmFkYS4iLAogICAgICAgICJyZXBvcnRfaXNzdWUiOiB1IkZvcmFtIGVu
REM Y29udHJhZGFzIG9jb3Jyw6puY2lhcyBxdWUgZXhpZ2VtIGF0ZW7Dp8Ojby4iLAogICAgfSwK
REM ICAgIDI6IHsKICAgICAgICAidGl0dWxvIjogdSJEREFDIER1YWwgRXh0cmFjdGlvbiAtIFYx
REM MTgiLAogICAgICAgICJub3ZhX2V4ZWN1Y2FvIjogdSJORVcgUlVOOiBkaWFnbm9zdGljIHJl
REM cG9ydCBpcyB0ZW1wb3JhcnkgYW5kIHdpbGwgYmUgcmVtb3ZlZCBhZnRlciBzdWNjZXNzZnVs
REM IGNvbXBsZXRpb24uIiwKICAgICAgICAiZ2FtZV9taXNzaW5nIjogdSJHYW1lIGZvbGRlciBu
REM b3QgZm91bmQuIiwKICAgICAgICAic3RhZ2UxX3N0YXJ0IjogdSJTVEFHRSAxLzE0IC0gU2Nh
REM bm5pbmcgdGhlIGdhbWUgZm9sZGVyLi4uIiwKICAgICAgICAic3RhZ2UxX2RvbmUiOiB1IlNU
REM QUdFIDEvMTQgLSBTY2FuIGdhbWU6IHswfSBmaWxlKHMpIFtPS10iLAogICAgICAgICJzdGFn
REM ZTJfc3RhcnQiOiB1IlNUQUdFIDIvMTQgLSBEREFDIGVuZ2luZTogc3RhcnRpbmcgZXh0cmFj
REM dGlvbi4uLiIsCiAgICAgICAgInN0YWdlMl9kb25lIjogdSJTVEFHRSAyLzE0IC0gRERBQyBl
REM bmdpbmU6IHswfSBjYW5kaWRhdGUocykgW09LXSIsCiAgICAgICAgInN0YWdlM19zdGFydCI6
REM IHUiU1RBR0UgMy8xNCAtIFJlbidQeSBlbmdpbmU6IHN0YXJ0aW5nIE9yYWNsZS4uLiIsCiAg
REM ICAgICAgInN0YWdlM19kb25lIjogdSJTVEFHRSAzLzE0IC0gUmVuJ1B5IGVuZ2luZTogezB9
REM IGNhbmRpZGF0ZShzKSB8IGFjdGl2ZT17MX0gW3syfV0iLAogICAgICAgICJzdGFnZTRfZG9u
REM ZSI6IHUiU1RBR0UgNC8xNCAtIENvbXBhcmlzb246IG1hdGNoZXM9ezB9IHwgRERBQy1vbmx5
REM PXsxfSB8IFJlbidQeS1vbmx5PXsyfSBbT0tdIiwKICAgICAgICAic3RhZ2U1X2RvbmUiOiB1
REM IlNUQUdFIDUvMTQgLSBEdXBsaWNhdGVzIGNvbnNvbGlkYXRlZDogezB9IFtPS10iLAogICAg
REM ICAgICJzdGFnZTZfZG9uZSI6IHUiU1RBR0UgNi8xNCAtIE92ZXJsYXBzIHJlc29sdmVkOiB7
REM MH0gY29uZmxpY3QocykgW09LXSIsCiAgICAgICAgInN0YWdlN19kb25lIjogdSJTVEFHRSA3
REM LzE0IC0gQ29udGV4dDogezB9IFtPS10iLAogICAgICAgICJzdGFnZThfZG9uZSI6IHUiU1RB
REM R0UgOC8xNCAtIENsYXNzaWZpY2F0aW9uOiBhY2NlcHRlZD17MH0gfCByZXZpZXc9ezF9IHwg
REM aWdub3JlZD17Mn0gfCBlbmdpbmUtY29tbW9uPXszfSB8IGdsb2JhbD17NH0gW09LXSIsCiAg
REM ICAgICAgInN0YWdlOV9kb25lIjogdSJTVEFHRSA5LzE0IC0gQ2Fub25pY2FsIG1hcDogezB9
REM IGVudHJpZXMgW09LXSIsCiAgICAgICAgInN0YWdlMTBfcGVuZGluZyI6IHUiU1RBR0UgMTAv
REM MTQgLSBUcmFuc2xhdGlvbiBwcmVwYXJhdGlvbjogUEVORElORyAoT3B0aW9uIDIpIiwKICAg
REM ICAgICAic3RhZ2UxMV9wZW5kaW5nIjogdSJTVEFHRSAxMS8xNCAtIFRva2VuIHZhbGlkYXRp
REM b246IFBFTkRJTkcgKGFmdGVyIE9wdGlvbiAyKSIsCiAgICAgICAgInN0YWdlMTJfcGVuZGlu
REM ZyI6IHUiU1RBR0UgMTIvMTQgLSBSZWludGVncmF0aW9uOiBQRU5ESU5HIChPcHRpb24gMyki
REM LAogICAgICAgICJzdGFnZTEzX3BlbmRpbmciOiB1IlNUQUdFIDEzLzE0IC0gT3V0cHV0IHZh
REM bGlkYXRpb246IFBFTkRJTkcgKE9wdGlvbiAzKSIsCiAgICAgICAgInN0YWdlMTRfcGVuZGlu
REM ZyI6IHUiU1RBR0UgMTQvMTQgLSBGaW5hbCBhdWRpdDogUEVORElORyAoT3B0aW9uIDMpIiwK
REM ICAgICAgICAicGVuZGluZ19sb2ciOiB1IlNUQUdFUyAxMC0xNDogY29ycmVjdGx5IGRlZmVy
REM cmVkIHRvIHRyYW5zbGF0aW9uL3JlaW50ZWdyYXRpb247IHRoZXkgYXJlIG5vdCBtYXJrZWQg
REM YXMgZXhlY3V0ZWQgZHVyaW5nIGV4dHJhY3Rpb24uIiwKICAgICAgICAiYmxvY2tlZF9sb2ci
REM OiB1IkRVQUxCUkFJTiBCTE9DS0VEOiB0aGUgUmVuJ1B5IGVuZ2luZSB3YXMgbm90IGFjdGl2
REM YXRlZC4gVGhlIEREQUMgZW5naW5lIHdpbGwgbm90IGNvbnRpbnVlIGFsb25lLiIsCiAgICAg
REM ICAgImJsb2NrZWRfcmVhc29uIjogdSJSZXF1aXJlZCBSZW4nUHkgT3JhY2xlIGluYWN0aXZl
REM OyBkZXRhaWxzIGFyZSByZWNvcmRlZCBpbiB0aGUgU0RLIGRpYWdub3N0aWNzLiIsCiAgICAg
REM ICAgImZpbmFsX3N0YXR1cyI6IHUiRFVBTCBFWFRSQUNUSU9OIENPTVBMRVRFRCIsCiAgICAg
REM ICAgIm9yYWNsZV95ZXMiOiB1IllFUyIsCiAgICAgICAgIm9yYWNsZV9ubyI6IHUiTk8iLAog
REM ICAgICAgICJzdGF0dXNfb2siOiB1Ik9LIiwKICAgICAgICAic3RhdHVzX2ZhaWwiOiB1IkZB
REM SUxFRCIsCiAgICAgICAgImxhYmVsX3N0YXR1cyI6IHUiRmluYWwgc3RhdHVzIiwKICAgICAg
REM ICAibGFiZWxfc2Nhbm5lZCI6IHUiRmlsZXMgc2Nhbm5lZCIsCiAgICAgICAgImxhYmVsX2Rk
REM YWMiOiB1IkREQUMgY2FuZGlkYXRlcyIsCiAgICAgICAgImxhYmVsX3JlbnB5IjogdSJSZW4n
REM UHkgY2FuZGlkYXRlcyIsCiAgICAgICAgImxhYmVsX2NvbmNvcmQiOiB1IkREQUMgKyBSZW4n
REM UHkgbWF0Y2hlcyIsCiAgICAgICAgImxhYmVsX29ubHlfZGRhYyI6IHUiRERBQy1vbmx5IiwK
REM ICAgICAgICAibGFiZWxfb25seV9yZW5weSI6IHUiUmVuJ1B5LW9ubHkiLAogICAgICAgICJs
REM YWJlbF9jYW5vbmljYWwiOiB1IkNhbm9uaWNhbCBlbnRyaWVzIiwKICAgICAgICAibGFiZWxf
REM b3JhY2xlIjogdSJSZW4nUHkgT3JhY2xlIGFjdGl2ZSIsCiAgICAgICAgImxhYmVsX2V4ZWN1
REM dGVkIjogdSJTdGFnZXMgZXhlY3V0ZWQiLAogICAgICAgICJsYWJlbF9wZW5kaW5nIjogdSJQ
REM ZW5kaW5nIHN0YWdlcyIsCiAgICAgICAgImxhYmVsX3RpbWUiOiB1IlRvdGFsIHRpbWUiLAog
REM ICAgICAgICJpbnRlcm5hbF9lcnJvciI6IHUiSU5URVJOQUwgRVJST1IgSU4gRFVBTEJSQUlO
REM IFYxMTg6IHswfSIsCiAgICAgICAgImludGVybmFsX2ZpbmFsIjogdSJJTlRFUk5BTF9FUlJP
REM UiIsCiAgICAgICAgInRyYW5zbGF0ZV9zdGFnZSI6IHUiU1RBR0UgMTAvMTQgLSBHb29nbGUg
REM VHJhbnNsYXRlIHJlY2VpdmVzIG9ubHkgY2Fub25pY2FsIGVudHJpZXMuIiwKICAgICAgICAi
REM dG9rZW5zX3N0YWdlIjogdSJTVEFHRSAxMS8xNCAtIEZpbmFsIHRva2VuIHZhbGlkYXRpb246
REM IHswfSIsCiAgICAgICAgInJlaW5qZWN0X3N0YWdlIjogdSJTVEFHRSAxMi8xNCAtIENhbm9u
REM aWNhbCByZWludGVncmF0aW9uLi4uIiwKICAgICAgICAib3V0cHV0X3N0YWdlIjogdSJTVEFH
REM RSAxMy8xNCAtIE91dHB1dCB2YWxpZGF0aW9uOiBPSyIsCiAgICAgICAgImF1ZGl0X3N0YWdl
REM IjogdSJTVEFHRSAxNC8xNCAtIEZpbmFsIGF1ZGl0OiBjaGVja2luZyBjb2xsaXNpb25zIGFu
REM ZCBjb21waWxlZCBmaWxlcy4uLiIsCiAgICAgICAgImF1ZGl0X3N1bW1hcnkiOiB1IlNUQUdF
REM IDE0LzE0IC0gQ29sbGlzaW9uIGF1ZGl0OiByZW1vdmVkPXswfSB8IGNvbmZsaWN0cz17MX0g
REM fCBwcmVzZXJ2ZWQ9ezJ9IHwgcGFpcmVkIC5ycHljIHJlcG9ydGVkPXszfSIsCiAgICAgICAg
REM Imluc3RhbGxlciI6IHUiU2FmZSBpbnN0YWxsZXI6IHswfSIsCiAgICAgICAgImxhYmVsX3Jl
REM bW92ZWQiOiB1ImdhbWUvY29tbW9uIHNjcmlwdHMgcmVtb3ZlZCBieSBpZGVudGljYWwgaGFz
REM aCIsCiAgICAgICAgImxhYmVsX2NvbmZsaWN0cyI6IHUiZ2FtZS9jb21tb24gY29uZmxpY3Rz
REM IiwKICAgICAgICAibGFiZWxfcHJlc2VydmVkIjogdSJQcmVzZXJ2ZWQgYnkgb2xkIG1hcCIs
REM CiAgICAgICAgInJlcG9ydF90aXRsZSI6IHUiRERBQyBDb2xsaXNpb24gUmVwb3J0IiwKICAg
REM ICAgICAicmVwb3J0X25vX2lzc3VlIjogdSJObyBjb2xsaXNpb24gb3IgaW5jb25zaXN0ZW5j
REM eSB3YXMgZm91bmQuIiwKICAgICAgICAicmVwb3J0X2lzc3VlIjogdSJPY2N1cnJlbmNlcyBy
REM ZXF1aXJpbmcgYXR0ZW50aW9uIHdlcmUgZm91bmQuIiwKICAgIH0sCiAgICAzOiB7CiAgICAg
REM ICAgInRpdHVsbyI6IHUiRERBQyBFeHRyYWNjacOzbiBEdWFsIC0gVjExOCIsCiAgICAgICAg
REM Im5vdmFfZXhlY3VjYW8iOiB1Ik5VRVZBIEVKRUNVQ0nDk046IGVsIGluZm9ybWUgZGUgZGlh
REM Z27Ds3N0aWNvIGVzIHRlbXBvcmFsIHkgc2UgZWxpbWluYXLDoSBhbCBjb21wbGV0YXIgY29y
REM cmVjdGFtZW50ZS4iLAogICAgICAgICJnYW1lX21pc3NpbmciOiB1Ik5vIHNlIGVuY29udHLD
REM syBsYSBjYXJwZXRhIGdhbWUuIiwKICAgICAgICAic3RhZ2UxX3N0YXJ0IjogdSJFVEFQQSAx
REM LzE0IC0gRXNjYW5lYW5kbyBsYSBjYXJwZXRhIGdhbWUuLi4iLAogICAgICAgICJzdGFnZTFf
REM ZG9uZSI6IHUiRVRBUEEgMS8xNCAtIEVzY2FuZWFyIGdhbWU6IHswfSBhcmNoaXZvKHMpIFtP
REM S10iLAogICAgICAgICJzdGFnZTJfc3RhcnQiOiB1IkVUQVBBIDIvMTQgLSBNb3RvciBEREFD
REM OiBpbmljaWFuZG8gZXh0cmFjY2nDs24uLi4iLAogICAgICAgICJzdGFnZTJfZG9uZSI6IHUi
REM RVRBUEEgMi8xNCAtIE1vdG9yIEREQUM6IHswfSBjYW5kaWRhdG8ocykgW09LXSIsCiAgICAg
REM ICAgInN0YWdlM19zdGFydCI6IHUiRVRBUEEgMy8xNCAtIE1vdG9yIFJlbidQeTogaW5pY2lh
REM bmRvIE9yw6FjdWxvLi4uIiwKICAgICAgICAic3RhZ2UzX2RvbmUiOiB1IkVUQVBBIDMvMTQg
REM LSBNb3RvciBSZW4nUHk6IHswfSBjYW5kaWRhdG8ocykgfCBhY3Rpdm89ezF9IFt7Mn1dIiwK
REM ICAgICAgICAic3RhZ2U0X2RvbmUiOiB1IkVUQVBBIDQvMTQgLSBDb21wYXJhY2nDs246IGNv
REM aW5jaWRlbmNpYXM9ezB9IHwgc29sby1EREFDPXsxfSB8IHNvbG8tUmVuJ1B5PXsyfSBbT0td
REM IiwKICAgICAgICAic3RhZ2U1X2RvbmUiOiB1IkVUQVBBIDUvMTQgLSBEdXBsaWNhZG9zIGNv
REM bnNvbGlkYWRvczogezB9IFtPS10iLAogICAgICAgICJzdGFnZTZfZG9uZSI6IHUiRVRBUEEg
REM Ni8xNCAtIFN1cGVycG9zaWNpb25lcyByZXN1ZWx0YXM6IHswfSBjb25mbGljdG8ocykgW09L
REM XSIsCiAgICAgICAgInN0YWdlN19kb25lIjogdSJFVEFQQSA3LzE0IC0gQ29udGV4dG86IHsw
REM fSBbT0tdIiwKICAgICAgICAic3RhZ2U4X2RvbmUiOiB1IkVUQVBBIDgvMTQgLSBDbGFzaWZp
REM Y2FjacOzbjogYWNlcHRhZG9zPXswfSB8IHJldmlzacOzbj17MX0gfCBpZ25vcmFkb3M9ezJ9
REM IHwgZW5naW5lLWNvbW1vbj17M30gfCBnbG9iYWxlcz17NH0gW09LXSIsCiAgICAgICAgInN0
REM YWdlOV9kb25lIjogdSJFVEFQQSA5LzE0IC0gTWFwYSBjYW7Ds25pY286IHswfSBlbnRyYWRh
REM cyBbT0tdIiwKICAgICAgICAic3RhZ2UxMF9wZW5kaW5nIjogdSJFVEFQQSAxMC8xNCAtIFBy
REM ZXBhcmFjacOzbiBwYXJhIHRyYWR1Y2Npw7NuOiBQRU5ESUVOVEUgKE9wY2nDs24gMikiLAog
REM ICAgICAgICJzdGFnZTExX3BlbmRpbmciOiB1IkVUQVBBIDExLzE0IC0gVmFsaWRhY2nDs24g
REM ZGUgdG9rZW5zOiBQRU5ESUVOVEUgKGRlc3B1w6lzIGRlIGxhIE9wY2nDs24gMikiLAogICAg
REM ICAgICJzdGFnZTEyX3BlbmRpbmciOiB1IkVUQVBBIDEyLzE0IC0gUmVpbnRlZ3JhY2nDs246
REM IFBFTkRJRU5URSAoT3BjacOzbiAzKSIsCiAgICAgICAgInN0YWdlMTNfcGVuZGluZyI6IHUi
REM RVRBUEEgMTMvMTQgLSBWYWxpZGFjacOzbiBkZSBzYWxpZGE6IFBFTkRJRU5URSAoT3BjacOz
REM biAzKSIsCiAgICAgICAgInN0YWdlMTRfcGVuZGluZyI6IHUiRVRBUEEgMTQvMTQgLSBBdWRp
REM dG9yw61hIGZpbmFsOiBQRU5ESUVOVEUgKE9wY2nDs24gMykiLAogICAgICAgICJwZW5kaW5n
REM X2xvZyI6IHUiRVRBUEFTIDEwLTE0OiBjb3JyZWN0YW1lbnRlIGFwbGF6YWRhcyBwYXJhIHRy
REM YWR1Y2Npw7NuL3JlaW50ZWdyYWNpw7NuOyBubyBzZSBkZWNsYXJhbiBlamVjdXRhZGFzIGR1
REM cmFudGUgbGEgZXh0cmFjY2nDs24uIiwKICAgICAgICAiYmxvY2tlZF9sb2ciOiB1IkRVQUxC
REM UkFJTiBCTE9RVUVBRE86IGVsIG1vdG9yIFJlbidQeSBubyBzZSBhY3RpdsOzLiBFbCBtb3Rv
REM ciBEREFDIG5vIGNvbnRpbnVhcsOhIHBvciBzw60gc29sby4iLAogICAgICAgICJibG9ja2Vk
REM X3JlYXNvbiI6IHUiRWwgT3LDoWN1bG8gUmVuJ1B5IG9ibGlnYXRvcmlvIGVzdMOhIGluYWN0
REM aXZvOyBsb3MgZGV0YWxsZXMgZXN0w6FuIHJlZ2lzdHJhZG9zIGVuIGVsIGRpYWduw7NzdGlj
REM byBkZWwgU0RLLiIsCiAgICAgICAgImZpbmFsX3N0YXR1cyI6IHUiRVhUUkFDQ0nDk04gRFVB
REM TCBDT01QTEVUQURBIiwKICAgICAgICAib3JhY2xlX3llcyI6IHUiU8ONIiwKICAgICAgICAi
REM b3JhY2xlX25vIjogdSJOTyIsCiAgICAgICAgInN0YXR1c19vayI6IHUiT0siLAogICAgICAg
REM ICJzdGF0dXNfZmFpbCI6IHUiRkFMTE8iLAogICAgICAgICJsYWJlbF9zdGF0dXMiOiB1IkVz
REM dGFkbyBmaW5hbCIsCiAgICAgICAgImxhYmVsX3NjYW5uZWQiOiB1IkFyY2hpdm9zIGVzY2Fu
REM ZWFkb3MiLAogICAgICAgICJsYWJlbF9kZGFjIjogdSJDYW5kaWRhdG9zIEREQUMiLAogICAg
REM ICAgICJsYWJlbF9yZW5weSI6IHUiQ2FuZGlkYXRvcyBSZW4nUHkiLAogICAgICAgICJsYWJl
REM bF9jb25jb3JkIjogdSJDb2luY2lkZW5jaWFzIEREQUMgKyBSZW4nUHkiLAogICAgICAgICJs
REM YWJlbF9vbmx5X2RkYWMiOiB1IlNvbG8gRERBQyIsCiAgICAgICAgImxhYmVsX29ubHlfcmVu
REM cHkiOiB1IlNvbG8gUmVuJ1B5IiwKICAgICAgICAibGFiZWxfY2Fub25pY2FsIjogdSJFbnRy
REM YWRhcyBjYW7Ds25pY2FzIiwKICAgICAgICAibGFiZWxfb3JhY2xlIjogdSJPcsOhY3VsbyBS
REM ZW4nUHkgYWN0aXZvIiwKICAgICAgICAibGFiZWxfZXhlY3V0ZWQiOiB1IkV0YXBhcyBlamVj
REM dXRhZGFzIiwKICAgICAgICAibGFiZWxfcGVuZGluZyI6IHUiRXRhcGFzIHBlbmRpZW50ZXMi
REM LAogICAgICAgICJsYWJlbF90aW1lIjogdSJUaWVtcG8gdG90YWwiLAogICAgICAgICJpbnRl
REM cm5hbF9lcnJvciI6IHUiRVJST1IgSU5URVJOTyBFTiBEVUFMQlJBSU4gVjExODogezB9IiwK
REM ICAgICAgICAiaW50ZXJuYWxfZmluYWwiOiB1IkVSUk9SX0lOVEVSTk8iLAogICAgICAgICJ0
REM cmFuc2xhdGVfc3RhZ2UiOiB1IkVUQVBBIDEwLzE0IC0gR29vZ2xlIFRyYW5zbGF0ZSByZWNp
REM YmUgc29sYW1lbnRlIGVudHJhZGFzIGNhbsOzbmljYXMuIiwKICAgICAgICAidG9rZW5zX3N0
REM YWdlIjogdSJFVEFQQSAxMS8xNCAtIFZhbGlkYWNpw7NuIGZpbmFsIGRlIHRva2VuczogezB9
REM IiwKICAgICAgICAicmVpbmplY3Rfc3RhZ2UiOiB1IkVUQVBBIDEyLzE0IC0gUmVpbnRlZ3Jh
REM Y2nDs24gY2Fuw7NuaWNhLi4uIiwKICAgICAgICAib3V0cHV0X3N0YWdlIjogdSJFVEFQQSAx
REM My8xNCAtIFZhbGlkYWNpw7NuIGRlIHNhbGlkYTogT0siLAogICAgICAgICJhdWRpdF9zdGFn
REM ZSI6IHUiRVRBUEEgMTQvMTQgLSBBdWRpdG9yw61hIGZpbmFsOiBjb21wcm9iYW5kbyBjb2xp
REM c2lvbmVzIHkgY29tcGlsYWRvcy4uLiIsCiAgICAgICAgImF1ZGl0X3N1bW1hcnkiOiB1IkVU
REM QVBBIDE0LzE0IC0gQXVkaXRvcsOtYSBkZSBjb2xpc2lvbmVzOiBlbGltaW5hZG9zPXswfSB8
REM IGNvbmZsaWN0b3M9ezF9IHwgcHJlc2VydmFkb3M9ezJ9IHwgLnJweWMgZW1wYXJlamFkb3Mg
REM cmVwb3J0YWRvcz17M30iLAogICAgICAgICJpbnN0YWxsZXIiOiB1IkFwbGljYWRvciBzZWd1
REM cm86IHswfSIsCiAgICAgICAgImxhYmVsX3JlbW92ZWQiOiB1IlNjcmlwdHMgZ2FtZS9jb21t
REM b24gZWxpbWluYWRvcyBwb3IgaGFzaCBpZMOpbnRpY28iLAogICAgICAgICJsYWJlbF9jb25m
REM bGljdHMiOiB1IkNvbmZsaWN0b3MgZ2FtZS9jb21tb24iLAogICAgICAgICJsYWJlbF9wcmVz
REM ZXJ2ZWQiOiB1IlByZXNlcnZhZG9zIHBvciBtYXBhIGFudGlndW8iLAogICAgICAgICJyZXBv
REM cnRfdGl0bGUiOiB1IkluZm9ybWUgZGUgY29saXNpb25lcyBkZSBEREFDIiwKICAgICAgICAi
REM cmVwb3J0X25vX2lzc3VlIjogdSJObyBzZSBlbmNvbnRyw7MgbmluZ3VuYSBjb2xpc2nDs24g
REM byBpbmNvbnNpc3RlbmNpYS4iLAogICAgICAgICJyZXBvcnRfaXNzdWUiOiB1IlNlIGVuY29u
REM dHJhcm9uIGluY2lkZW5jaWFzIHF1ZSByZXF1aWVyZW4gYXRlbmNpw7NuLiIsCiAgICB9LAp9
REM CgpDT0xJU0FPX1JFTEFUT1JJT19ST1RVTE9TID0gewogICAgMTogewogICAgICAgICJyZW1v
REM dmlkb3MiOiB1IlNjcmlwdHMgcmVtb3ZpZG9zIHBvciBoYXNoIGlkw6pudGljbyIsCiAgICAg
REM ICAgImNvbmZsaXRvcyI6IHUiQ29uZmxpdG9zIGdhbWUvY29tbW9uIGRpZmVyZW50ZXMiLAog
REM ICAgICAgICJwcmVzZXJ2YWRvcyI6IHUiQXJxdWl2b3MgcHJlc2VydmFkb3MgcG9yIG1hcGEg
REM YW50aWdvIiwKICAgICAgICAicnB5YyI6IHUiQXJxdWl2b3MgLnJweWMgcGFyZWFkb3MgcmVw
REM b3J0YWRvcyIsCiAgICAgICAgInJweWNfbmFvX2FwYWdhZG9zIjogdSIucnB5YyBwYXJlYWRv
REM cyBuw6NvIGFwYWdhZG9zIiwKICAgICAgICAiaW5zdGFsYWNhbyI6IHUiQSBpbnN0YWxhw6fD
REM o28gZmluYWwgc3Vic3RpdHVpIGEgcGFzdGEgZ2FtZSBpbnRlaXJhbWVudGUiLAogICAgICAg
REM ICJpZGlvbWEiOiB1IlBvcnR1Z3XDqnMiLAogICAgfSwKICAgIDI6IHsKICAgICAgICAicmVt
REM b3ZpZG9zIjogdSJTY3JpcHRzIHJlbW92ZWQgYnkgaWRlbnRpY2FsIGhhc2giLAogICAgICAg
REM ICJjb25mbGl0b3MiOiB1IkRpZmZlcmVudCBnYW1lL2NvbW1vbiBjb25mbGljdHMiLAogICAg
REM ICAgICJwcmVzZXJ2YWRvcyI6IHUiRmlsZXMgcHJlc2VydmVkIGJ5IG9sZCBtYXAiLAogICAg
REM ICAgICJycHljIjogdSJQYWlyZWQgLnJweWMgZmlsZXMgcmVwb3J0ZWQiLAogICAgICAgICJy
REM cHljX25hb19hcGFnYWRvcyI6IHUiUGFpcmVkIC5ycHljIGZpbGVzIG5vdCBkZWxldGVkIiwK
REM ICAgICAgICAiaW5zdGFsYWNhbyI6IHUiVGhlIGZpbmFsIGluc3RhbGxhdGlvbiByZXBsYWNl
REM cyB0aGUgZ2FtZSBmb2xkZXIgZW50aXJlbHkiLAogICAgICAgICJpZGlvbWEiOiB1IkVuZ2xp
REM c2giLAogICAgfSwKICAgIDM6IHsKICAgICAgICAicmVtb3ZpZG9zIjogdSJTY3JpcHRzIGVs
REM aW1pbmFkb3MgcG9yIGhhc2ggaWTDqW50aWNvIiwKICAgICAgICAiY29uZmxpdG9zIjogdSJD
REM b25mbGljdG9zIGdhbWUvY29tbW9uIGRpZmVyZW50ZXMiLAogICAgICAgICJwcmVzZXJ2YWRv
REM cyI6IHUiQXJjaGl2b3MgcHJlc2VydmFkb3MgcG9yIG1hcGEgYW50aWd1byIsCiAgICAgICAg
REM InJweWMiOiB1IkFyY2hpdm9zIC5ycHljIGVtcGFyZWphZG9zIHJlcG9ydGFkb3MiLAogICAg
REM ICAgICJycHljX25hb19hcGFnYWRvcyI6IHUiLnJweWMgZW1wYXJlamFkb3Mgbm8gZWxpbWlu
REM YWRvcyIsCiAgICAgICAgImluc3RhbGFjYW8iOiB1IkxhIGluc3RhbGFjacOzbiBmaW5hbCBz
REM dXN0aXR1eWUgcG9yIGNvbXBsZXRvIGxhIGNhcnBldGEgZ2FtZSIsCiAgICAgICAgImlkaW9t
REM YSI6IHUiRXNwYcOxb2wiLAogICAgfSwKfQoKZGVmIGR0KGNoYXZlLCAqYXJncyk6CiAgICB2
REM YWxvciA9IERVQUxfTUVOU0FHRU5TLmdldChJRElPTUEsIERVQUxfTUVOU0FHRU5TWzFdKS5n
REM ZXQoY2hhdmUsIERVQUxfTUVOU0FHRU5TWzFdW2NoYXZlXSkKICAgIHJldHVybiB2YWxvci5m
REM b3JtYXQoKmFyZ3MpIGlmIGFyZ3MgZWxzZSB2YWxvcgoKClFTVFIgPSByJyIoPzpbXiJcXF18
REM XFwuKSoifFwnKD86W15cJ1xcXXxcXC4pKlwnJwpMSU5IQV9ESUFMT0dPID0gcmUuY29tcGls
REM ZShyJ14oPzooPzpcdyt8JyArIFFTVFIgKyByJylccyspezAsMn0oJyArIFFTVFIgKyByJyku
REM KiQnKQpURVhUT19VSSA9IHJlLmNvbXBpbGUocidfXChccyooJyArIFFTVFIgKyByJylccypc
REM KScpCiMgUGxhY2Vob2xkZXJzIHB1cm9zIGRlIGRhdGEvaG9yYSBzw6NvIHRleHRvIHRyYWR1
REM esOtdmVsIHF1YW5kbyBtYXJjYWRvcyBleHBsaWNpdGFtZW50ZQojIGNvbSBfKCkvX18oKS9f
REM cCgpLiBFbGVzIG7Do28gc8OjbyBjw7NkaWdvOiBwcmVjaXNhbSBlbnRyYXIgbm8gbWFwYSBw
REM YXJhIHF1ZSBhCiMgdHJhZHXDp8OjbyBwcmVzZXJ2ZSBvcyB0b2tlbnMge2hvdXJ9LCB7bWlu
REM dXRlfSwge21vbnRofSwge2RheX0gZSB7eWVhcn0uClBMQUNFSE9MREVSX1RSQURVWklWRUxf
REM UkUgPSByZS5jb21waWxlKHInXlxzKlx7W0EtWmEtel9dW0EtWmEtejAtOV8uXSpcfSg/Olxz
REM Kls6L1wtXVxzKlx7W0EtWmEtel9dW0EtWmEtejAtOV8uXSpcfSkrXHMqJCcpClBSSU1FSVJB
REM X1BBTEFWUkEgPSByZS5jb21waWxlKHInXihcdyspJykKClBBTEFWUkFTX0RFRklOSUNBTyA9
REM IHsiZGVmaW5lIiwgImRlZmF1bHQifQpOT01FX1BFUlNPTkFHRU0gPSByZS5jb21waWxlKHIn
REM KD88IUR5bmFtaWMpQ2hhcmFjdGVyXChccyooPzpuYW1lXHMqPVxzKik/KCcgKyBRU1RSICsg
REM cicpJykKRFlOQU1JQ19DSEFSQUNURVIgPSByZS5jb21waWxlKHInRHluYW1pY0NoYXJhY3Rl
REM clwoXHMqKD86bmFtZVxzKj1ccyopPygnICsgUVNUUiArIHInKScpClZBUklBVkVMX0RFRklO
REM SUNBTyA9IHJlLmNvbXBpbGUocideKD86ZGVmaW5lfGRlZmF1bHQpXHMrKFtcdy5dKylccyo9
REM JykKVkFMT1JfU1RSSU5HX1NJTVBMRVMgPSByZS5jb21waWxlKHInXig/OmRlZmluZXxkZWZh
REM dWx0KVxzK1tcdy5dK1xzKj1ccyooJyArIFFTVFIgKyByJylccyokJykKUFJFRklYT1NfVEVD
REM TklDT1MgPSAoImJ1aWxkLiIsKQpOT01FU19URUNOSUNPU19DT05IRUNJRE9TID0gewogICAg
REM ImNvbmZpZy53aW5kb3ciLCAiY29uZmlnLnNhdmVfZGlyZWN0b3J5IiwgImNvbmZpZy5nbF90
REM ZXN0X2ltYWdlIiwKICAgICJjb25maWcud2luZG93X2ljb24iLCAiY29uZmlnLnNhdmVfanNv
REM bl9jYWxsYmFja3MiLAp9CkVYVEVOU09FU19URUNOSUNBUyA9ICgKICAgICJ0dGYiLCAib3Rm
REM IiwgInBuZyIsICJqcGciLCAianBlZyIsICJ3ZWJwIiwgIndlYm0iLCAib2dnIiwgIm1wMyIs
REM ICJ3YXYiLAogICAgInJweSIsICJycHljIiwgInJwYSIsICJ0eHQiLCAiaWNvIiwKKQojIFJl
REM ZmVyw6puY2lhcyBhIGFycXVpdm9zL3JlY3Vyc29zIG7Do28gc8OjbyBkacOhbG9nb3MgdHJh
REM ZHV6w612ZWlzLgojIEFsw6ltIGRhcyBleHRlbnPDtWVzIGNvbmhlY2lkYXMsIG8gc2Nhbm5l
REM ciBjb21wYXJhIGNhZGEgdGV4dG8gZW50cmUgYXNwYXMKIyBjb20gdW0gw61uZGljZSBkZSB0
REM b2RvcyBvcyBhcnF1aXZvcyBleGlzdGVudGVzIGRlbnRybyBkYSBwYXN0YSBnYW1lLgojIEV4
REM ZW1wbG9zOiAiZ3VpL21lbnVfYXJ0X3kucG5nIiwgImd1aS9vdmVybGF5L21haW5fbWVudS5w
REM bmciLgpSRUZFUkVOQ0lBX0FSUVVJVk8gPSByZS5jb21waWxlKAogICAgcideKD86W0EtWmEt
REM ejAtOV8uLV0rW1xcL10pK1teXFwvXHNdK1wuKD86JwogICAgKyAifCIuam9pbihFWFRFTlNP
REM RVNfVEVDTklDQVMpCiAgICArIHInKSQnLAogICAgcmUuSUdOT1JFQ0FTRQopCiMgUmVjdXJz
REM b3MgY29tIHRhZ3MgZGUgbG9vcC9mYWRlL0FUTDogc8OjbyBwYXLDom1ldHJvcyB0w6ljbmlj
REM b3MsIG7Do28gZmFsYXMuClJFQ1VSU09fQ09NX1RBRyA9IHJlLmNvbXBpbGUoCiAgICByJ14o
REM Pzo8W14+XSs+XHMqKSsoPzpbQS1aYS16MC05Xy4oKVwtIF0rW1xcL10pK1teXFwvXStcLig/
REM Om9nZ3xtcDN8d2F2fGZsYWN8bTRhfHdlYm0pJCcsCiAgICByZS5JR05PUkVDQVNFCikKUkVD
REM VVJTT19DT01fVEFHX1NFTV9QQVNUQSA9IHJlLmNvbXBpbGUoCiAgICByJ14oPzo8W14+XSs+
REM XHMqKSsoPzpbXlxcL10rXC4oPzpvZ2d8bXAzfHdhdnxmbGFjfG00YXx3ZWJtKSkkJywKICAg
REM IHJlLklHTk9SRUNBU0UKKQpSRUNVUlNPX0NBTUlOSE8gPSByZS5jb21waWxlKAogICAgcide
REM KD86W0EtWmEtejAtOV8uKClcLSBdK1tcXC9dKStbXlxcL10rXC4oPzp0dGZ8b3RmfHBuZ3xq
REM cGd8anBlZ3xnaWZ8d2VicHx3ZWJtfG9nZ3xtcDN8d2F2fGZsYWN8bTRhfHJweXxycHljfHJw
REM YXxpY298anNvbnxjaHJ8cHl8cHljfGRsbHxzb3xhcGspJCcsCiAgICByZS5JR05PUkVDQVNF
REM CikKCkFUUklCVUlDQU9fRE9MQVIgPSByZS5jb21waWxlKHInXlwkXHMqKFtcdy5dKylccyo9
REM XHMqKCcgKyBRU1RSICsgcicpXHMqJCcpCgpQQUxBVlJBU19SRVNFUlZBREFTID0gewogICAg
REM InZvaWNlIiwgImZpdCIsICJpbWFnZSIsICJwbGF5IiwgInF1ZXVlIiwgInN0b3AiLCAic2Nl
REM bmUiLCAic2hvdyIsICJoaWRlIiwKICAgICJ3aXRoIiwgIndpbmRvdyIsICJwYXVzZSIsICJz
REM Y3JlZW4iLCAibGFiZWwiLCAianVtcCIsICJjYWxsIiwgInJldHVybiIsCiAgICAicHl0aG9u
REM IiwgImluaXQiLCAiZGVmaW5lIiwgImRlZmF1bHQiLCAidHJhbnNsYXRlIiwgInN0eWxlIiwg
REM InRyYW5zZm9ybSIsCiAgICAibGF5ZXJlZGltYWdlIiwgIm1lbnUiLCAiaWYiLCAiZWxpZiIs
REM ICJlbHNlIiwgIndoaWxlIiwgImZvciIsICJwYXNzIiwKICAgICJjb250aW51ZSIsICJicmVh
REM ayIsICJudmwiLCAiY2FtZXJhIiwgInBoeXNpY3MiLAogICAgImZvbnQiLCAiY29sb3IiLCAi
REM aG92ZXJfY29sb3IiLCAic2VsZWN0ZWRfY29sb3IiLCAiaW5zZW5zaXRpdmVfY29sb3IiLAog
REM ICAgImlkbGVfY29sb3IiLCAiYWRkIiwgImtleSIsICJrZXlzeW0iLCAiaWQiLCAic3R5bGVf
REM cHJlZml4IiwgImJhY2tncm91bmQiLAogICAgImZvcmVncm91bmQiLCAidGh1bWIiLCAiYmFz
REM ZV9iYXIiLCAidG9wX2JhciIsICJib3R0b21fYmFyIiwgInVuc2Nyb2xsYWJsZSIsCiAgICAi
REM c2Nyb2xsYmFycyIsICJsYXlvdXQiLCAib3V0bGluZXMiLCAiaG92ZXJfb3V0bGluZXMiLCAi
REM aW5wdXQiLCAiY2FyZXQiLAogICAgInNpemVfZ3JvdXAiLCAib24iLCAiYWN0aW9uIiwgInZh
REM bHVlIiwgImFkanVzdG1lbnQiLCAicHJvcGVydGllcyIsCiAgICAieHBvcyIsICJ5cG9zIiwg
REM InhhbGlnbiIsICJ5YWxpZ24iLCAieGFuY2hvciIsICJ5YW5jaG9yIiwgInhzaXplIiwgInlz
REM aXplIiwKICAgICJ4b2Zmc2V0IiwgInlvZmZzZXQiLCAic3BhY2luZyIsICJwYWRkaW5nIiwg
REM Im1hcmdpbiIsICJhdCIsICJ0b29sdGlwIiwKICAgICJob3Zlcl9zb3VuZCIsICJhY3RpdmF0
REM ZV9zb3VuZCIsICJmb2N1c19tYXNrIiwgInJhbmdlIiwgImFsdCIsCn0KCiMgPT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT0KIyBVVElMSVTDgVJJT1MgREUgQVJRVUlWT1MgLyBMT0dTCiMgPT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT0KY2xhc3MgTG9nKG9iamVjdCk6CiAgICBkZWYgX19pbml0
REM X18oc2VsZiwgY2FtaW5obyk6CiAgICAgICAgc2VsZi5jYW1pbmhvID0gY2FtaW5obwogICAg
REM ICAgIHNlbGYubGluaGFzID0gW10KICAgICAgICBzZWxmLl9sb2NrID0gdGhyZWFkaW5nLlJM
REM b2NrKCkKCiAgICBkZWYgc2VwYXJhZG9yKHNlbGYpOgogICAgICAgIHdpdGggc2VsZi5fbG9j
REM azoKICAgICAgICAgICAgc2VsZi5saW5oYXMuYXBwZW5kKHUiPSIgKiA2MCkKCiAgICBkZWYg
REM dGl0dWxvKHNlbGYsIHRleHRvKToKICAgICAgICB3aXRoIHNlbGYuX2xvY2s6CiAgICAgICAg
REM ICAgIHNlbGYubGluaGFzLmFwcGVuZCh0ZXh0bykKCiAgICBkZWYgX3RhZyhzZWxmLCB0YWcs
REM IG1lbnNhZ2VtKToKICAgICAgICB3aXRoIHNlbGYuX2xvY2s6CiAgICAgICAgICAgIHNlbGYu
REM bGluaGFzLmFwcGVuZCh1Ilt7MH1dIHsxfSIuZm9ybWF0KHRhZywgbWVuc2FnZW0pKQoKICAg
REM IGRlZiBpbmZvKHNlbGYsIG1lbnNhZ2VtKToKICAgICAgICBzZWxmLl90YWcodCgibG9nX3Rh
REM Z19pbmZvIiksIG1lbnNhZ2VtKQoKICAgIGRlZiBhdmlzbyhzZWxmLCBtZW5zYWdlbSk6CiAg
REM ICAgICAgc2VsZi5fdGFnKHQoImxvZ190YWdfYXZpc28iKSwgbWVuc2FnZW0pCgogICAgZGVm
REM IGVycm8oc2VsZiwgbWVuc2FnZW0pOgogICAgICAgIHNlbGYuX3RhZyh0KCJsb2dfdGFnX2Vy
REM cm8iKSwgbWVuc2FnZW0pCgogICAgZGVmIHJlc3VsdGFkbyhzZWxmLCByb3R1bG8sIHZhbG9y
REM KToKICAgICAgICB3aXRoIHNlbGYuX2xvY2s6CiAgICAgICAgICAgIHJvdHVsb19wYWRkZWQg
REM PSAocm90dWxvICsgdSIgIiAqIDM0KVs6MzRdCiAgICAgICAgICAgIHNlbGYubGluaGFzLmFw
REM cGVuZCh1InswfTogezF9Ii5mb3JtYXQocm90dWxvX3BhZGRlZCwgdmFsb3IpKQoKICAgIGRl
REM ZiBzYWx2YXIoc2VsZik6CiAgICAgICAgd2l0aCBzZWxmLl9sb2NrOgogICAgICAgICAgICBk
REM YWRvcyA9IHUiXG4iLmpvaW4oc2VsZi5saW5oYXMpICsgdSJcbiIKICAgICAgICB0ZW1wID0g
REM c2VsZi5jYW1pbmhvICsgdSIudG1wIgogICAgICAgICMgTm9ybWFsaXphIGFwZW5hcyB1bSBl
REM dmVudHVhbCBgXGAgY29sYWRvIGFudGVzIGRvcyBzZXBhcmFkb3JlcyBgPT09PWAuCiAgICAg
REM ICAgIyBJc3NvIG7Do28gYWx0ZXJhIGNhbWluaG9zLCBtZW5zYWdlbnMgb3UgY29udGXDumRv
REM IGRlIHVzdcOhcmlvLgogICAgICAgIGRhZG9zID0gcmUuc3ViKHInKD9tKV5cXCg/PT17MjAs
REM fSQpJywgdSIiLCBkYWRvcykKICAgICAgICB3aXRoIGlvLm9wZW4odGVtcCwgInciLCBlbmNv
REM ZGluZz0idXRmLTgiKSBhcyBmOgogICAgICAgICAgICBmLndyaXRlKGRhZG9zKQogICAgICAg
REM IG9zLnJlcGxhY2UodGVtcCwgc2VsZi5jYW1pbmhvKQoKCmRlZiBhbmV4YXJfbGluaGFzX2xv
REM ZyhjYW1pbmhvLCBsaW5oYXMpOgogICAgdHJ5OgogICAgICAgIHdpdGggaW8ub3BlbihjYW1p
REM bmhvLCAiYSIsIGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6CiAgICAgICAgICAgIGlmIG9zLnBh
REM dGguaXNmaWxlKGNhbWluaG8pIGFuZCBvcy5wYXRoLmdldHNpemUoY2FtaW5obykgPiAwOgog
REM ICAgICAgICAgICAgICAgZi53cml0ZSh1IlxuIikKICAgICAgICAgICAgZm9yIGxpbmhhIGlu
REM IGxpbmhhczoKICAgICAgICAgICAgICAgIGYud3JpdGUobGluaGEgKyB1IlxuIikKICAgIGV4
REM Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwoKCmRlZiBfaW5zcGVjaW9uYXJfcGFzdGFz
REM X3RsKHBhc3RhX2dhbWUpOgogICAgZW5jb250cmFkYXMgPSBbXQogICAgaWYgbm90IG9zLnBh
REM dGguaXNkaXIocGFzdGFfZ2FtZSk6CiAgICAgICAgcmV0dXJuIGVuY29udHJhZGFzCiAgICBm
REM b3IgcGFzdGFfYXR1YWwsIHN1YnBhc3RhcywgYXJxdWl2b3MgaW4gb3Mud2FsayhwYXN0YV9n
REM YW1lKToKICAgICAgICBpZiBvcy5wYXRoLmJhc2VuYW1lKHBhc3RhX2F0dWFsKS5sb3dlcigp
REM ICE9ICJ0bCI6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgcmVsX3RsID0gb3MucGF0
REM aC5yZWxwYXRoKHBhc3RhX2F0dWFsLCBwYXN0YV9nYW1lKS5yZXBsYWNlKG9zLnNlcCwgIi8i
REM KQogICAgICAgIGlkaW9tYXMgPSBbXQogICAgICAgIGZvciBub21lIGluIHNvcnRlZChzdWJw
REM YXN0YXMpOgogICAgICAgICAgICBjYW1pbmhvID0gb3MucGF0aC5qb2luKHBhc3RhX2F0dWFs
REM LCBub21lKQogICAgICAgICAgICBpZiBvcy5wYXRoLmlzZGlyKGNhbWluaG8pOgogICAgICAg
REM ICAgICAgICAgaWRpb21hcy5hcHBlbmQobm9tZSkKICAgICAgICBlbmNvbnRyYWRhcy5hcHBl
REM bmQoeyJjYW1pbmhvIjogcmVsX3RsLCAiaWRpb21hcyI6IGlkaW9tYXMsICJhcnF1aXZvcyI6
REM IGxlbihhcnF1aXZvcyl9KQogICAgcmV0dXJuIGVuY29udHJhZGFzCgoKZGVmIGVuY29udHJh
REM cl9wYXN0YV9nYW1lKHJhaXopOgogICAgY2FuZGlkYXRvID0gb3MucGF0aC5qb2luKHJhaXos
REM ICJnYW1lIikKICAgIGlmIG9zLnBhdGguaXNkaXIoY2FuZGlkYXRvKToKICAgICAgICByZXR1
REM cm4gY2FuZGlkYXRvCiAgICByZXR1cm4gcmFpegoKCiMgLS0tIEFycXVpdm8tYmFzZSBleHBs
REM aWNpdGFtZW50ZSBibG9xdWVhZG8gbmEgZXh0cmHDp8OjbyAtLS0KIyBzY3JpcHQtcG9lbXJl
REM c3BvbnNlcy5ycHkgw6kgdW0gYXJxdWl2by1iYXNlIGRvIERETEMvVGVtcGxhdGUgcXVlIG7D
REM o28gZGV2ZSBlbnRyYXIKIyBuYSBleHRyYcOnw6NvIGF1dG9tw6F0aWNhLiBPIGJsb3F1ZWlv
REM IMOpIGZlaXRvIHBlbG8gbm9tZS1iYXNlLCBpbmRlcGVuZGVudGVtZW50ZQojIGRhIHBhc3Rh
REM IGVtIHF1ZSBvIGFycXVpdm8gZXN0ZWphIGxvY2FsaXphZG8uClBPRU1SRVNQT05TRVNfQkFT
REM RV9OQU1FID0gdSJzY3JpcHQtcG9lbXJlc3BvbnNlcy5ycHkiCgoKZGVmIF9sZXJfdGV4dG9f
REM YXJxdWl2b19zZWd1cm9zX3BvZW1yZXNwb25zZXMoY2FtaW5obyk6CiAgICB0cnk6CiAgICAg
REM ICAgYnJ1dG8gPSBiIiIKICAgICAgICB3aXRoIG9wZW4oY2FtaW5obywgInJiIikgYXMgZjoK
REM ICAgICAgICAgICAgYnJ1dG8gPSBmLnJlYWQoKQogICAgICAgIHJldHVybiBicnV0by5kZWNv
REM ZGUoInV0Zi04IiwgImlnbm9yZSIpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHRy
REM eToKICAgICAgICAgICAgcmV0dXJuIHUiIi5qb2luKGxlcl9saW5oYXNfcmF3KGNhbWluaG8p
REM KQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHJldHVybiB1IiIKCgpk
REM ZWYgX2Fzc2luYXR1cmFfcG9lbXJlc3BvbnNlc19iYXNlKGNhbWluaG8pOgogICAgIiIiUG9u
REM dHVhIGEgc2VtZWxoYW7Dp2EgZXN0cnV0dXJhbCBjb20gbyBzY3JpcHQtcG9lbXJlc3BvbnNl
REM cyBkbyBERExDL3RlbXBsYXRlLgoKICAgIE7Do28gdXNhIGhhc2ggZXhhdG8sIHBvcnF1ZSBt
REM b2RzIGZyZXF1ZW50ZW1lbnRlIGFjcmVzY2VudGFtL3JlbW92ZW0gbGluaGFzIG5vCiAgICBh
REM cnF1aXZvLWJhc2UuIEEgZGVjaXPDo28gc8OzIMOpIHBvc2l0aXZhIHF1YW5kbyB2w6FyaW9z
REM IGVsZW1lbnRvcyBjYXJhY3RlcsOtc3RpY29zCiAgICBhcGFyZWNlbSBqdW50b3MuCiAgICAi
REM IiIKICAgIGlmIG9zLnBhdGguYmFzZW5hbWUoY2FtaW5obykubG93ZXIoKSAhPSBQT0VNUkVT
REM UE9OU0VTX0JBU0VfTkFNRToKICAgICAgICByZXR1cm4gMAogICAgdGV4dG8gPSBfbGVyX3Rl
REM eHRvX2FycXVpdm9fc2VndXJvc19wb2VtcmVzcG9uc2VzKGNhbWluaG8pCiAgICBpZiBub3Qg
REM dGV4dG86CiAgICAgICAgcmV0dXJuIDAKICAgIHNjb3JlID0gMAogICAgaWYgcmUuc2VhcmNo
REM KHInKD9tKV5ccypsYWJlbFxzK3BvZW1yZXNwb25zZV9zdGFydFxzKjonLCB0ZXh0byk6CiAg
REM ICAgICAgc2NvcmUgKz0gMwogICAgaWYgcmUuc2VhcmNoKHInKD9tKV5ccypsYWJlbFxzK3Bv
REM ZW1yZXNwb25zZV8oPzpsb29wfHN0YXJ0Milccyo6JywgdGV4dG8pOgogICAgICAgIHNjb3Jl
REM ICs9IDEKICAgIGlmIHJlLnNlYXJjaChyJyg/bSleXHMqbGFiZWxccytwb2VtcmVzcG9uc2Vf
REM KD86c2F5b3JpfG5hdHN1a2l8eXVyaXxtb25pa2F8Y2FsbGJhY2spXGInLCB0ZXh0bywgcmUu
REM SSk6CiAgICAgICAgc2NvcmUgKz0gMQogICAgaWYgcmUuc2VhcmNoKHInXGJjYWxsXHMrc2hv
REM d3BvZW1ccypcKCcsIHRleHRvLCByZS5JKToKICAgICAgICBzY29yZSArPSAxCiAgICBpZiBy
REM ZS5zZWFyY2gocidcYmNhbGxccytleHByZXNzaW9uXHMrbmV4dHNjZW5lXGInLCB0ZXh0bywg
REM cmUuSSk6CiAgICAgICAgc2NvcmUgKz0gMQogICAgaWYgcmUuc2VhcmNoKHInXGIoPzpwb2Vt
REM b3Bpbmlvbnxwb2VtYXBwZWFsfHNraXBfcG9lbXxwb2Vtc3JlYWQpXGInLCB0ZXh0bywgcmUu
REM SSk6CiAgICAgICAgc2NvcmUgKz0gMQogICAgbGFiZWxzX2NoID0gcmUuZmluZGFsbChyJyg/
REM bSleXHMqbGFiZWxccytjaFxkK18oPzpzfG58eXxtKV8oPzpiYWR8bWVkfGdvb2R8ZW5kKSg/
REM Olx3Kilccyo6JywgdGV4dG8sIHJlLkkpCiAgICBpZiBsZW4obGFiZWxzX2NoKSA+PSA0Ogog
REM ICAgICAgIHNjb3JlICs9IDQKICAgIGVsaWYgbGVuKGxhYmVsc19jaCkgPj0gMjoKICAgICAg
REM ICBzY29yZSArPSAyCiAgICByZXR1cm4gc2NvcmUKCgpkZWYgX3BvZW1yZXNwb25zZXNfcmVm
REM ZXJlbmNpYWRvX2V4dGVybmFtZW50ZShwYXN0YV9nYW1lLCBjYW1pbmhvX2Fsdm8pOgogICAg
REM IiIiVmVyZGFkZWlybyBxdWFuZG8gb3V0cm8gYXJxdWl2byBkbyBqb2dvIHBhcmVjZSBjaGFt
REM YXIvdXNhciBsYWJlbHMgZGVzc2UgYXJxdWl2by4KCiAgICBBIGJ1c2NhIMOpIGRlbGliZXJh
REM ZGFtZW50ZSBjb25zZXJ2YWRvcmE6IHF1YWxxdWVyIG9jb3Jyw6puY2lhIGV4dGVybmEgZG9z
REM IGxhYmVscwogICAgY2FyYWN0ZXLDrXN0aWNvcyBpbXBlZGUgbyBkZXNjYXJ0ZS4gSXNzbyBw
REM cmVmZXJlIHRyYWR1emlyIGEgbWFpcyBkbyBxdWUgY29ycmVyIG8KICAgIHJpc2NvIGRlIGln
REM bm9yYXIgdW0gYXJxdWl2byByZWFsbWVudGUgdXRpbGl6YWRvLgogICAgIiIiCiAgICB0ZXh0
REM b19hbHZvID0gX2xlcl90ZXh0b19hcnF1aXZvX3NlZ3Vyb3NfcG9lbXJlc3BvbnNlcyhjYW1p
REM bmhvX2Fsdm8pCiAgICBpZiBub3QgdGV4dG9fYWx2bzoKICAgICAgICByZXR1cm4gVHJ1ZQog
REM ICAgbm9tZXMgPSBzZXQocmUuZmluZGFsbChyJyg/bSleXHMqbGFiZWxccysoW0EtWmEtel9d
REM XHcqKVxzKjonLCB0ZXh0b19hbHZvKSkKICAgIG5vbWVzLnVwZGF0ZSgodSJwb2VtcmVzcG9u
REM c2Vfc3RhcnQiLCB1InBvZW1yZXNwb25zZV9sb29wIiwgdSJwb2VtcmVzcG9uc2Vfc3RhcnQy
REM IikpCiAgICBpZiBub3Qgbm9tZXM6CiAgICAgICAgcmV0dXJuIFRydWUKICAgIHBhZHJhbyA9
REM IHJlLmNvbXBpbGUocicoPzwhW0EtWmEtejAtOV9dKSg/OicgKyB1J3wnLmpvaW4ocmUuZXNj
REM YXBlKG4pIGZvciBuIGluIHNvcnRlZChub21lcywga2V5PWxlbiwgcmV2ZXJzZT1UcnVlKSkg
REM KyByJykoPyFbQS1aYS16MC05X10pJykKICAgIGFsdm9fYWJzID0gb3MucGF0aC5hYnNwYXRo
REM KGNhbWluaG9fYWx2bykKICAgIGlnbm9yYWRhcyA9IHNldChwLmxvd2VyKCkgZm9yIHAgaW4g
REM UEFTVEFTX0lHTk9SQURBUykKICAgIGZvciBwYXN0YV9hdHVhbCwgc3VicGFzdGFzLCBhcnF1
REM aXZvcyBpbiBvcy53YWxrKHBhc3RhX2dhbWUpOgogICAgICAgIHN1YnBhc3Rhc1s6XSA9IFtk
REM IGZvciBkIGluIHN1YnBhc3RhcyBpZiBkLmxvd2VyKCkgbm90IGluIGlnbm9yYWRhc10KICAg
REM ICAgICBmb3Igbm9tZSBpbiBhcnF1aXZvczoKICAgICAgICAgICAgY2FtaW5obyA9IG9zLnBh
REM dGguam9pbihwYXN0YV9hdHVhbCwgbm9tZSkKICAgICAgICAgICAgaWYgb3MucGF0aC5hYnNw
REM YXRoKGNhbWluaG8pLmxvd2VyKCkgPT0gYWx2b19hYnMubG93ZXIoKToKICAgICAgICAgICAg
REM ICAgIGNvbnRpbnVlCiAgICAgICAgICAgIGxvdyA9IG5vbWUubG93ZXIoKQogICAgICAgICAg
REM ICBpZiBub3QgbG93LmVuZHN3aXRoKCgiLnJweSIsICIucnB5bSIsICIucnB5YyIsICIucnB5
REM bWMiLCAiX3Jlbi5weSIpKToKICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAg
REM IHRyeToKICAgICAgICAgICAgICAgIGlmIGxvdy5lbmRzd2l0aCgoIi5ycHljIiwgIi5ycHlt
REM YyIpKToKICAgICAgICAgICAgICAgICAgICB3aXRoIG9wZW4oY2FtaW5obywgInJiIikgYXMg
REM ZjoKICAgICAgICAgICAgICAgICAgICAgICAgZGFkb3MgPSBmLnJlYWQoKQogICAgICAgICAg
REM ICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgdGV4dG8gPSBkYWRvcy5k
REM ZWNvZGUoInV0Zi04IiwgImlnbm9yZSIpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IEV4
REM Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgdGV4dG8gPSBkYWRvcy5kZWNvZGUo
REM ImxhdGluLTEiLCAiaWdub3JlIikKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
REM ICAgICAgICAgdGV4dG8gPSBfbGVyX3RleHRvX2FycXVpdm9fc2VndXJvc19wb2VtcmVzcG9u
REM c2VzKGNhbWluaG8pCiAgICAgICAgICAgICAgICBpZiB0ZXh0byBhbmQgcGFkcmFvLnNlYXJj
REM aCh0ZXh0byk6CiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFRydWUKICAgICAgICAgICAg
REM ZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICMgRXJybyBkZSBsZWl0dXJhIG7D
REM o28gYXV0b3JpemEgbyBkZXNjYXJ0ZS4KICAgICAgICAgICAgICAgIHJldHVybiBUcnVlCiAg
REM ICByZXR1cm4gRmFsc2UKCgpkZWYgZGV2ZV9pZ25vcmFyX3BvZW1yZXNwb25zZXNfbmFvX3Vz
REM YWRvKHBhc3RhX2dhbWUsIGNhbWluaG8pOgogICAgIyBSZWdyYSBmaXhhOiBlc3RlIGFycXVp
REM dm8tYmFzZSBuw6NvIHBhcnRpY2lwYSBkYSBleHRyYcOnw6NvLCBlc3RlamEgZWxlCiAgICAj
REM IG5hIHJhaXogZGUgZ2FtZSBvdSBlbSBxdWFscXVlciBzdWJwYXN0YS4KICAgIHJldHVybiBv
REM cy5wYXRoLmJhc2VuYW1lKGNhbWluaG8pLmxvd2VyKCkgPT0gUE9FTVJFU1BPTlNFU19CQVNF
REM X05BTUUKCgpkZWYgX3ByZWZsaWdodF9jb250YXJfZm9udGVzKHBhc3RhX2dhbWUpOgogICAg
REM Y29udGFnZW0gPSB7Ii5ycHkiOiAwLCAiLnJweW0iOiAwLCAiX3Jlbi5weSI6IDAsICIudHh0
REM IjogMCwgIi5ycHljIjogMCwgIi5ycHltYyI6IDAsICIucnBhIjogMH0KICAgIHRyaXBsZXMg
REM PSBbXQogICAgdGxfZXhpc3RlbnRlID0gRmFsc2UKICAgIGZvciBwYXN0YV9hdHVhbCwgc3Vi
REM cGFzdGFzLCBhcnF1aXZvcyBpbiBvcy53YWxrKHBhc3RhX2dhbWUpOgogICAgICAgIGlmIGFu
REM eShkLmxvd2VyKCkgPT0gInRsIiBmb3IgZCBpbiBzdWJwYXN0YXMpOgogICAgICAgICAgICB0
REM bF9leGlzdGVudGUgPSBUcnVlCiAgICAgICAgc3VicGFzdGFzWzpdID0gW2QgZm9yIGQgaW4g
REM c3VicGFzdGFzIGlmIGQgbm90IGluIFBBU1RBU19JR05PUkFEQVNdCiAgICAgICAgZm9yIG5v
REM bWUgaW4gYXJxdWl2b3M6CiAgICAgICAgICAgIGxvdyA9IG5vbWUubG93ZXIoKQogICAgICAg
REM ICAgICBleHQgPSBOb25lCiAgICAgICAgICAgIGlmIGxvdy5lbmRzd2l0aCgiLnJweSIpOiBl
REM eHQgPSAiLnJweSIKICAgICAgICAgICAgZWxpZiBsb3cuZW5kc3dpdGgoIi5ycHltIik6IGV4
REM dCA9ICIucnB5bSIKICAgICAgICAgICAgZWxpZiBsb3cuZW5kc3dpdGgoIl9yZW4ucHkiKTog
REM ZXh0ID0gIl9yZW4ucHkiCiAgICAgICAgICAgIGVsaWYgbG93LmVuZHN3aXRoKCIudHh0Iik6
REM IGV4dCA9ICIudHh0IgogICAgICAgICAgICBlbGlmIGxvdy5lbmRzd2l0aCgiLnJweWMiKTog
REM ZXh0ID0gIi5ycHljIgogICAgICAgICAgICBlbGlmIGxvdy5lbmRzd2l0aCgiLnJweW1jIik6
REM IGV4dCA9ICIucnB5bWMiCiAgICAgICAgICAgIGVsaWYgbG93LmVuZHN3aXRoKCIucnBhIik6
REM IGV4dCA9ICIucnBhIgogICAgICAgICAgICBpZiBleHQ6CiAgICAgICAgICAgICAgICBpZiBu
REM b3QgKGxvdy5lbmRzd2l0aCgoIi5ycHkiLCAiLnJweW0iKSkgYW5kCiAgICAgICAgICAgICAg
REM ICAgICAgICAgIGRldmVfaWdub3Jhcl9wb2VtcmVzcG9uc2VzX25hb191c2FkbyhwYXN0YV9n
REM YW1lLCBvcy5wYXRoLmpvaW4ocGFzdGFfYXR1YWwsIG5vbWUpKSk6CiAgICAgICAgICAgICAg
REM ICAgICAgY29udGFnZW1bZXh0XSArPSAxCiAgICAgICAgICAgICMgX3Jlbi5weSB1c2VzIHRy
REM aXBsZS1xdW90ZWQgYmxvY2tzIGFzIHBhcnQgb2YgaXRzIFJlbidQeSBzeW50YXgsCiAgICAg
REM ICAgICAgICMgc28gb25seSBvcmRpbmFyeSAucnB5Ly5ycHltIGZpbGVzIGFyZSB3YXJuZWQg
REM aGVyZS4KICAgICAgICAgICAgaWYgbG93LmVuZHN3aXRoKCgiLnJweSIsICIucnB5bSIpKToK
REM ICAgICAgICAgICAgICAgIGNhbWluaG8gPSBvcy5wYXRoLmpvaW4ocGFzdGFfYXR1YWwsIG5v
REM bWUpCiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgYnJ1dG8gPSB1
REM IiIuam9pbihsZXJfbGluaGFzX3JhdyhjYW1pbmhvKSkKICAgICAgICAgICAgICAgICAgICBp
REM ZiByZS5zZWFyY2gocicoP20pXlxzKig/Oig/OltBLVphLXpfXVtcdy5dKilccyspPyg/OiIi
REM InxcJ1wnXCcpJywgYnJ1dG8pOgogICAgICAgICAgICAgICAgICAgICAgICB0cmlwbGVzLmFw
REM cGVuZChvcy5wYXRoLnJlbHBhdGgoY2FtaW5obywgcGFzdGFfZ2FtZSkucmVwbGFjZShvcy5z
REM ZXAsICIvIikpCiAgICAgICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAg
REM ICAgICAgICAgIHBhc3MKICAgIHJldHVybiBjb250YWdlbSwgdHJpcGxlcywgdGxfZXhpc3Rl
REM bnRlCgoKZGVmIF9wcmVmbGlnaHRfbGVyX21hcGEoY2FtaW5obyk6CiAgICB0cnk6CiAgICAg
REM ICAgd2l0aCBpby5vcGVuKGNhbWluaG8sICJyIiwgZW5jb2Rpbmc9InV0Zi04IikgYXMgZjoK
REM ICAgICAgICAgICAgbWFwYSA9IGpzb24ubG9hZChmKQogICAgZXhjZXB0IEV4Y2VwdGlvbiBh
REM cyBleGM6CiAgICAgICAgcmV0dXJuIE5vbmUsIFtwdGV4dCgibWFwYV9sZWl0dXJhIikuZm9y
REM bWF0KGV4YyldCiAgICBpZiBub3QgaXNpbnN0YW5jZShtYXBhLCBkaWN0KToKICAgICAgICBy
REM ZXR1cm4gTm9uZSwgW3UiTWFwYSBpbnbDoWxpZG86IGVzdHJ1dHVyYSBwcmluY2lwYWwgbsOj
REM byDDqSB1bSBvYmpldG8gSlNPTi4iXQogICAgZW50cmFkYXMgPSBzdW0obGVuKHYpIGZvciB2
REM IGluIG1hcGEudmFsdWVzKCkgaWYgaXNpbnN0YW5jZSh2LCBsaXN0KSkKICAgIHJldHVybiBt
REM YXBhLCBlbnRyYWRhcwoKCmRlZiBfcHJlZmxpZ2h0X3RleHRvc19kYV9wYXN0YShwYXN0YV9l
REM bnRyYWRhLCBtYXBhPU5vbmUpOgogICAgdG90YWwgPSAwCiAgICBhcnF1aXZvcyA9IDAKICAg
REM IHByb2JsZW1hcyA9IFtdCiAgICBleHRyYXMgPSBbXQogICAgbWFwYV9jaGF2ZXMgPSBzZXQo
REM bWFwYS5rZXlzKCkpIGlmIGlzaW5zdGFuY2UobWFwYSwgZGljdCkgZWxzZSBOb25lCiAgICBp
REM ZiBub3Qgb3MucGF0aC5pc2RpcihwYXN0YV9lbnRyYWRhKToKICAgICAgICByZXR1cm4gYXJx
REM dWl2b3MsIHRvdGFsLCBwcm9ibGVtYXMsIGV4dHJhcwogICAgZm9yIGNhbWluaG8gaW4gY29s
REM ZXRhcl9jYW5kaWRhdG9zX3JlaW5qZWNhbyhwYXN0YV9lbnRyYWRhKToKICAgICAgICByZWwg
REM PSBvcy5wYXRoLnJlbHBhdGgoY2FtaW5obywgcGFzdGFfZW50cmFkYSkucmVwbGFjZShvcy5z
REM ZXAsICIvIikKICAgICAgICBpZiBtYXBhX2NoYXZlcyBpcyBub3QgTm9uZSBhbmQgcmVsIG5v
REM dCBpbiBtYXBhX2NoYXZlczoKICAgICAgICAgICAgZXh0cmFzLmFwcGVuZChyZWwpCiAgICAg
REM ICAgICAgIGNvbnRpbnVlCiAgICAgICAgYXJxdWl2b3MgKz0gMQogICAgICAgIHRyeToKICAg
REM ICAgICAgICAgdG90YWwgKz0gbGVuKGxlcl90ZXh0b3NfdHJhZHV6aWRvcyhjYW1pbmhvKSkK
REM ICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICAgICAgcHJvYmxlbWFz
REM LmFwcGVuZCh1Int9OiB7fSIuZm9ybWF0KHJlbCwgZXhjKSkKICAgIHJldHVybiBhcnF1aXZv
REM cywgdG90YWwsIHByb2JsZW1hcywgZXh0cmFzCgoKZGVmIGV4ZWN1dGFyX3ByZWZsaWdodChy
REM YWl6LCBldGFwYSk6CiAgICAiIiJDaGVjYWdlbSBzb21lbnRlIGxlaXR1cmEgYW50ZXMgZGFz
REM IDMgZXRhcGFzIGRvIGZsdXhvIGRlIGRpw6Fsb2dvcy4iIiIKICAgIHByaW50KHUiPT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM IikKICAgIHByaW50KHUiICIgKyBwdGV4dCgidGl0dWxvIikpCiAgICBwcmludCh1Ij09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PSIpCiAgICBwcmludCh1IiAiICsgcHRleHQoInN1YnRpdHVsbyIpKQogICAgcHJpbnQodSIi
REM KQogICAgbm9tZXMgPSB7ImV4dHJhaXIiOiAiZXRhcGFfZXh0cmFpciIsICJ0cmFkdXppciI6
REM ICJldGFwYV90cmFkdXppciIsICJyZWluamV0YXIiOiAiZXRhcGFfcmVpbmpldGFyIn0KICAg
REM IHByaW50KHUiICIgKyBwdGV4dChub21lcy5nZXQoZXRhcGEsICJldGFwYV9leHRyYWlyIikp
REM KQogICAgcHJpbnQodSIiKQoKICAgIGVycm9zID0gW10KICAgIGF2aXNvcyA9IFtdCiAgICBw
REM YXN0YV9nYW1lID0gZW5jb250cmFyX3Bhc3RhX2dhbWUocmFpeikKICAgIGlmIG5vdCBvcy5w
REM YXRoLmlzZGlyKHBhc3RhX2dhbWUpOgogICAgICAgIGVycm9zLmFwcGVuZChwdGV4dCgiZ2Ft
REM ZV9pbmV4aXN0ZW50ZSIpKQoKICAgIGlmIGV0YXBhID09ICJleHRyYWlyIjoKICAgICAgICBp
REM ZiBvcy5wYXRoLmlzZGlyKHBhc3RhX2dhbWUpOgogICAgICAgICAgICBjb250LCB0cmlwbGVz
REM LCB0bF9leGlzdGVudGUgPSBfcHJlZmxpZ2h0X2NvbnRhcl9mb250ZXMocGFzdGFfZ2FtZSkK
REM ICAgICAgICBlbHNlOgogICAgICAgICAgICBjb250ID0ge2s6MCBmb3IgayBpbiAoIi5ycHki
REM LCAiLnJweW0iLCAiX3Jlbi5weSIsICIudHh0IiwgIi5ycHljIiwgIi5ycHltYyIsICIucnBh
REM Iil9CiAgICAgICAgICAgIHRyaXBsZXMgPSBbXQogICAgICAgICAgICB0bF9leGlzdGVudGUg
REM PSBGYWxzZQogICAgICAgIHRvdGFsX2ZvbnRlcyA9IGNvbnRbIi5ycHkiXSArIGNvbnRbIi5y
REM cHltIl0gKyBjb250WyJfcmVuLnB5Il0KICAgICAgICBwcmludCh1IiB7fToge30iLmZvcm1h
REM dChwdGV4dCgiZ2FtZSIpLCBwYXN0YV9nYW1lIGlmIG9zLnBhdGguaXNkaXIocGFzdGFfZ2Ft
REM ZSkgZWxzZSB1Ii0iKSkKICAgICAgICBwcmludCh1IiB7fToge30gICh7fToge30sIHt9OiB7
REM fSwge306IHt9KSIuZm9ybWF0KHB0ZXh0KCJmb250ZXMiKSwgdG90YWxfZm9udGVzLCBwdGV4
REM dCgicnB5IiksIGNvbnRbIi5ycHkiXSwgcHRleHQoInJweW0iKSwgY29udFsiLnJweW0iXSwg
REM cHRleHQoInJlbnB5X3B5IiksIGNvbnRbIl9yZW4ucHkiXSkpCiAgICAgICAgcHJpbnQodSIg
REM e306IHt9ICAoe306IHt9LCB7fToge30sIHt9OiB7fSkiLmZvcm1hdChwdGV4dCgiY29tcGls
REM YWRvcyIpLCBjb250WyIucnB5YyJdK2NvbnRbIi5ycHltYyJdK2NvbnRbIi5ycGEiXSwgcHRl
REM eHQoInJweWMiKSwgY29udFsiLnJweWMiXSwgcHRleHQoInJweW1jIiksIGNvbnRbIi5ycHlt
REM YyJdLCBwdGV4dCgicnBhIiksIGNvbnRbIi5ycGEiXSkpCiAgICAgICAgcHJpbnQodSIge306
REM IHt9Ii5mb3JtYXQocHRleHQoInR4dCIpLCBjb250WyIudHh0Il0pKQogICAgICAgIGlmIHRs
REM X2V4aXN0ZW50ZToKICAgICAgICAgICAgcHJpbnQodSIge306IHt9Ii5mb3JtYXQocHRleHQo
REM InRsIiksIHB0ZXh0KCJhdmlzbyIpKSkKICAgICAgICAgICAgYXZpc29zLmFwcGVuZChwdGV4
REM dCgidGxfbXNnIikpCiAgICAgICAgICAgIGZvciBpdGVtIGluIF9pbnNwZWNpb25hcl9wYXN0
REM YXNfdGwocGFzdGFfZ2FtZSk6CiAgICAgICAgICAgICAgICBub21lcyA9IGl0ZW1bImlkaW9t
REM YXMiXQogICAgICAgICAgICAgICAgaWYgbm9tZXM6CiAgICAgICAgICAgICAgICAgICAgcHJp
REM bnQodSIgICB7fToge30iLmZvcm1hdChpdGVtWyJjYW1pbmhvIl0sIHUiLCAiLmpvaW4obm9t
REM ZXMpKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgcHJpbnQo
REM dSIgICB7fToge30iLmZvcm1hdChpdGVtWyJjYW1pbmhvIl0sIHUiKHNlbSBzdWJwYXN0YXMg
REM ZGUgaWRpb21hKSIpKQogICAgICAgIGlmIHRyaXBsZXM6CiAgICAgICAgICAgIHByaW50KHUi
REM IHt9OiB7fSIuZm9ybWF0KHB0ZXh0KCJ0cmlwbG8iKSwgcHRleHQoImF2aXNvIikpKQogICAg
REM ICAgICAgICBhdmlzb3MuYXBwZW5kKHB0ZXh0KCJ0cmlwbG9fbXNnIikpCiAgICAgICAgICAg
REM IGZvciBjYW1pbmhvIGluIHRyaXBsZXNbOjEyXTogcHJpbnQodSIgICAtIHt9Ii5mb3JtYXQo
REM Y2FtaW5obykpCiAgICAgICAgICAgIGlmIGxlbih0cmlwbGVzKSA+IDEyOiBwcmludCh1IiAg
REM IC0gLi4uICt7fSIuZm9ybWF0KGxlbih0cmlwbGVzKS0xMikpCiAgICAgICAgaWYgdG90YWxf
REM Zm9udGVzID09IDA6CiAgICAgICAgICAgIGlmIGNvbnRbIi5ycGEiXSBvciBjb250WyIucnB5
REM YyJdIG9yIGNvbnRbIi5ycHltYyJdOgogICAgICAgICAgICAgICAgIyBWMTQ1IGzDqiBmb250
REM ZXMgdmlzw612ZWlzOyBhcnF1aXZvcyBSUEEvUlBZQyBwcmVjaXNhbSBzZXIgZXh0cmHDrWRv
REM cy9kZXNjb21waWxhZG9zIGFudGVzLgogICAgICAgICAgICAgICAgZXJyb3MuYXBwZW5kKHB0
REM ZXh0KCJjb21waWxhZG9fb25seSIpKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAg
REM ICAgZXJyb3MuYXBwZW5kKHB0ZXh0KCJzZW1fZm9udGUiKSkKCiAgICBlbGlmIGV0YXBhID09
REM ICJ0cmFkdXppciI6CiAgICAgICAgcGFzdGFfZW50cmFkYSwgbm9tZV9tYXBhX2VzY29saGlk
REM byA9IGxvY2FsaXphcl9wYXN0YV9leHRyYWNhb190cmFkdWNhbyhyYWl6KQogICAgICAgIHBy
REM aW50KHUiIHt9OiB7fSIuZm9ybWF0KHB0ZXh0KCJtYXBhIiksIHBhc3RhX2VudHJhZGEgb3Ig
REM dSItIikpCiAgICAgICAgaWYgbm90IHBhc3RhX2VudHJhZGE6CiAgICAgICAgICAgIGVycm9z
REM LmFwcGVuZChwdGV4dCgiZW50cmFkYV9pbmV4aXN0ZW50ZSIpKQogICAgICAgIGVsc2U6CiAg
REM ICAgICAgICAgIG5vbWVfbWFwYSA9IG5leHQoKG4gZm9yIG4gaW4gTUFQQVNfQ09NUEFUSVZF
REM SVMgaWYgb3MucGF0aC5pc2ZpbGUob3MucGF0aC5qb2luKHBhc3RhX2VudHJhZGEsIG4pKSks
REM IE5vbmUpCiAgICAgICAgICAgIGlmIG5vdCBub21lX21hcGE6CiAgICAgICAgICAgICAgICBl
REM cnJvcy5hcHBlbmQocHRleHQoIm1hcGFfaW5leGlzdGVudGUiKSkKICAgICAgICAgICAgZWxz
REM ZToKICAgICAgICAgICAgICAgIG1hcGEsIHZhbG9yID0gX3ByZWZsaWdodF9sZXJfbWFwYShv
REM cy5wYXRoLmpvaW4ocGFzdGFfZW50cmFkYSwgbm9tZV9tYXBhKSkKICAgICAgICAgICAgICAg
REM IGlmIG1hcGEgaXMgTm9uZToKICAgICAgICAgICAgICAgICAgICBlcnJvcy5leHRlbmQodmFs
REM b3IpCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGFycXVpdm9z
REM LCB0ZXh0b3MsIHByb2JsZW1hcywgZXh0cmFzID0gX3ByZWZsaWdodF90ZXh0b3NfZGFfcGFz
REM dGEocGFzdGFfZW50cmFkYSwgbWFwYSkKICAgICAgICAgICAgICAgICAgICBwcmludCh1IiB7
REM fToge30iLmZvcm1hdChwdGV4dCgiYXJxdWl2b3NfbWFwYSIpLCBsZW4obWFwYSkpKQogICAg
REM ICAgICAgICAgICAgICAgIHByaW50KHUiIHt9OiB7fSIuZm9ybWF0KHB0ZXh0KCJlbnRyYWRh
REM cyIpLCB2YWxvcikpCiAgICAgICAgICAgICAgICAgICAgcHJpbnQodSIge306IHt9Ii5mb3Jt
REM YXQocHRleHQoImFycXVpdm9zX2VudHJhZGEiKSwgYXJxdWl2b3MpKQogICAgICAgICAgICAg
REM ICAgICAgIHByaW50KHUiIHt9OiB7fSIuZm9ybWF0KHB0ZXh0KCJjb3JyZXNwb25kZW5jaWEi
REM KSwgcHRleHQoIm9rIikgaWYgdmFsb3IgPT0gdGV4dG9zIGVsc2UgcHRleHQoImVycm8iKSkp
REM CiAgICAgICAgICAgICAgICAgICAgaWYgZXh0cmFzOgogICAgICAgICAgICAgICAgICAgICAg
REM ICBtc2dfZXh0cmFzID0gewogICAgICAgICAgICAgICAgICAgICAgICAgICAgMTogdSJBcnF1
REM aXZvKHMpIGZvcmEgZG8gbWFwYSBlbmNvbnRyYWRvKHMpIG5hIHBhc3RhIGRlIHRyYWJhbGhv
REM OyBzZXLDo28gaWdub3JhZG9zIG5lc3RhIGV0YXBhOiB7fSIsCiAgICAgICAgICAgICAgICAg
REM ICAgICAgICAgICAyOiB1IkZpbGUocykgb3V0c2lkZSB0aGUgbWFwIGZvdW5kIGluIHRoZSB3
REM b3JrIGZvbGRlcjsgdGhleSB3aWxsIGJlIGlnbm9yZWQgaW4gdGhpcyBzdGVwOiB7fSIsCiAg
REM ICAgICAgICAgICAgICAgICAgICAgICAgICAzOiB1IkFyY2hpdm8ocykgZnVlcmEgZGVsIG1h
REM cGEgZW5jb250cmFkbyhzKSBlbiBsYSBjYXJwZXRhIGRlIHRyYWJham87IHNlIGlnbm9yYXLD
REM oW4gZW4gZXN0YSBldGFwYToge30iLAogICAgICAgICAgICAgICAgICAgICAgICB9LmdldChJ
REM RElPTUEsIHUiQXJxdWl2byhzKSBmb3JhIGRvIG1hcGEgZW5jb250cmFkbyhzKSBuYSBwYXN0
REM YSBkZSB0cmFiYWxobzsgc2Vyw6NvIGlnbm9yYWRvcyBuZXN0YSBldGFwYToge30iKQogICAg
REM ICAgICAgICAgICAgICAgICAgICBsaXN0YV9leHRyYXMgPSB1IiwgIi5qb2luKGV4dHJhc1s6
REM MTJdKSArICh1IiAuLi4gK3t9Ii5mb3JtYXQobGVuKGV4dHJhcyktMTIpIGlmIGxlbihleHRy
REM YXMpID4gMTIgZWxzZSB1IiIpCiAgICAgICAgICAgICAgICAgICAgICAgIGF2aXNvcy5hcHBl
REM bmQobXNnX2V4dHJhcy5mb3JtYXQobGlzdGFfZXh0cmFzKSkKICAgICAgICAgICAgICAgICAg
REM ICBpZiB2YWxvciA9PSAwOgogICAgICAgICAgICAgICAgICAgICAgICBlcnJvcy5hcHBlbmQo
REM cHRleHQoIm5lbmh1bV90ZXh0byIpKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdmFsb3Ig
REM IT0gdGV4dG9zOgogICAgICAgICAgICAgICAgICAgICAgICBlcnJvcy5hcHBlbmQocHRleHQo
REM ImNvbnRhZ2VtIikuZm9ybWF0KHZhbG9yLCB0ZXh0b3MpKQogICAgICAgICAgICAgICAgICAg
REM IGlmIHByb2JsZW1hczogZXJyb3MuZXh0ZW5kKHByb2JsZW1hc1s6MTBdKQogICAgICAgICAg
REM ICAgICAgICAgIGlmIG5vdCBvcy5wYXRoLmlzZGlyKG9zLnBhdGguam9pbihyYWl6LCBQQVNU
REM QV9UUkFEVUNBT19HT09HTEVfTk9NRSkpOgogICAgICAgICAgICAgICAgICAgICAgICBwcmlu
REM dCh1IiB7fSIuZm9ybWF0KHB0ZXh0KCJzZW1fc2FpZGEiKSkpCgogICAgZWxpZiBldGFwYSA9
REM PSAicmVpbmpldGFyIjoKICAgICAgICBwcmludCh1IiB7fToge30iLmZvcm1hdChwdGV4dCgi
REM Z2FtZSIpLCBwYXN0YV9nYW1lKSkKICAgICAgICBwcmludCh1IiIpCiAgICAgICAgY2FuZGlk
REM YXRvc19kaWFsb2dvcyA9IGxpc3Rhcl9wYXN0YXNfZGlhbG9nb3NfcG9yX2NhdGVnb3JpYShy
REM YWl6LCB7dSJleHRyYWNhbyIsIHUidHJhZHVjYW8ifSkKICAgICAgICBpZiBub3QgY2FuZGlk
REM YXRvc19kaWFsb2dvczoKICAgICAgICAgICAgcHJpbnQodSIge306IC0iLmZvcm1hdChwdGV4
REM dCgibWFwYSIpKSkKICAgICAgICAgICAgZXJyb3MuYXBwZW5kKHB0ZXh0KCJlbnRyYWRhX2lu
REM ZXhpc3RlbnRlIikpCiAgICAgICAgZWxzZToKICAgICAgICAgICAgdmFsaWRvcyA9IDAKICAg
REM ICAgICAgICAgcHJpbnQodSI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT0iKQogICAgICAgICAgICBwcmludCh1IiB7fSIuZm9y
REM bWF0KHB0ZXh0KCJmb250ZXNfcmVpbmpfdGl0dWxvIikpKQogICAgICAgICAgICBwcmludCh1
REM Ij09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PSIpCiAgICAgICAgICAgIHByaW50KHUiIHt9Ii5mb3JtYXQocHRleHQoImZvbnRl
REM c19yZWlual90b3RhbCIpLmZvcm1hdChsZW4oY2FuZGlkYXRvc19kaWFsb2dvcykpKSkKICAg
REM ICAgICAgICAgcHJpbnQodSIiKQogICAgICAgICAgICBpZiBsZW4oY2FuZGlkYXRvc19kaWFs
REM b2dvcykgPiAxOgogICAgICAgICAgICAgICAgYXZpc29zLmFwcGVuZCh1IkjDoSBtw7psdGlw
REM bGFzIHBhc3RhcyBkZSBkacOhbG9nb3M7IGEgZXRhcGEgZGUgcmVpbnRlZ3Jhw6fDo28gcGVk
REM aXLDoSBhIGVzY29saGEgc29tZW50ZSBkZXBvaXMgZGVzdGEgY2hlY2FnZW0uIikKICAgICAg
REM ICAgICAgZm9yIGlkeCwgKHBhc3RhX2VudHJhZGEsIG5vbWVfbWFwYSwgY2F0ZWdvcmlhKSBp
REM biBlbnVtZXJhdGUoY2FuZGlkYXRvc19kaWFsb2dvcywgMSk6CiAgICAgICAgICAgICAgICB0
REM aXBvID0gdCgicmVpbmpfdGlwb19nb29nbGUiKSBpZiBjYXRlZ29yaWEgPT0gdSJ0cmFkdWNh
REM byIgZWxzZSB0KCJyZWlual90aXBvX21hbnVhbCIpCiAgICAgICAgICAgICAgICBub21lX3Bh
REM c3RhID0gb3MucGF0aC5iYXNlbmFtZShwYXN0YV9lbnRyYWRhKQogICAgICAgICAgICAgICAg
REM cHJpbnQodSIge30iLmZvcm1hdChwdGV4dCgiZm9udGVzX3JlaW5qX2l0ZW0iKS5mb3JtYXQo
REM aWR4LCB0aXBvKSkpCiAgICAgICAgICAgICAgICBwcmludCh1IiAgIHt9OiB7fSIuZm9ybWF0
REM KHB0ZXh0KCJmb250ZXNfcmVpbmpfcGFzdGEiKSwgbm9tZV9wYXN0YSkpCiAgICAgICAgICAg
REM ICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgd2l0aCBpby5vcGVuKG9zLnBhdGguam9p
REM bihwYXN0YV9lbnRyYWRhLCBub21lX21hcGEpLCAiciIsIGVuY29kaW5nPSJ1dGYtOCIpIGFz
REM IGY6CiAgICAgICAgICAgICAgICAgICAgICAgIG1hcGEgPSBqc29uLmxvYWQoZikKICAgICAg
REM ICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAgICAgICAgICAgICAgICAg
REM IHByaW50KHUiICAge306IHt9Ii5mb3JtYXQocHRleHQoImZvbnRlc19yZWlual9jb3JyZXNw
REM b25kZW5jaWEiKSwgcHRleHQoImVycm8iKSkpCiAgICAgICAgICAgICAgICAgICAgcHJpbnQo
REM dSIgICB7fToge30iLmZvcm1hdChwdGV4dCgiZm9udGVzX3JlaW5qX2NhbWluaG8iKSwgcGFz
REM dGFfZW50cmFkYSkpCiAgICAgICAgICAgICAgICAgICAgYXZpc29zLmFwcGVuZCh1Int9OiB7
REM fSIuZm9ybWF0KG5vbWVfcGFzdGEsIHB0ZXh0KCJtYXBhX2xlaXR1cmEiKS5mb3JtYXQoZXhj
REM KSkpCiAgICAgICAgICAgICAgICAgICAgcHJpbnQodSIiKQogICAgICAgICAgICAgICAgICAg
REM IGNvbnRpbnVlCiAgICAgICAgICAgICAgICBpZiBub3QgaXNpbnN0YW5jZShtYXBhLCBkaWN0
REM KToKICAgICAgICAgICAgICAgICAgICBhdmlzb3MuYXBwZW5kKHUie306IG1hcGEgaW52w6Fs
REM aWRvLiIuZm9ybWF0KG5vbWVfcGFzdGEpKQogICAgICAgICAgICAgICAgICAgIHByaW50KHUi
REM ICAge306IHt9Ii5mb3JtYXQocHRleHQoImZvbnRlc19yZWlual9jb3JyZXNwb25kZW5jaWEi
REM KSwgcHRleHQoImVycm8iKSkpCiAgICAgICAgICAgICAgICAgICAgcHJpbnQodSIgICB7fTog
REM e30iLmZvcm1hdChwdGV4dCgiZm9udGVzX3JlaW5qX2NhbWluaG8iKSwgcGFzdGFfZW50cmFk
REM YSkpCiAgICAgICAgICAgICAgICAgICAgcHJpbnQodSIiKQogICAgICAgICAgICAgICAgICAg
REM IGNvbnRpbnVlCiAgICAgICAgICAgICAgICBjYW5kaWRhdG9zX2FycXVpdm8gPSBjb2xldGFy
REM X2NhbmRpZGF0b3NfcmVpbmplY2FvKHBhc3RhX2VudHJhZGEpCiAgICAgICAgICAgICAgICBw
REM cmUgPSB2YWxpZGFyX3ByZV9yZWludGVncmFjYW8ocGFzdGFfZ2FtZSwgcGFzdGFfZW50cmFk
REM YSwgbWFwYSwgY2FuZGlkYXRvc19hcnF1aXZvKQogICAgICAgICAgICAgICAgcHJpbnQodSIg
REM ICB7fToge30iLmZvcm1hdChwdGV4dCgiZm9udGVzX3JlaW5qX2FycXVpdm9zIiksIHByZVsi
REM YXJxdWl2b3NfdmFsaWRhZG9zIl0pKQogICAgICAgICAgICAgICAgcHJpbnQodSIgICB7fTog
REM e30ve30iLmZvcm1hdChwdGV4dCgiZm9udGVzX3JlaW5qX3RleHRvcyIpLCBwcmVbImVudHJh
REM ZGFzX2VuY29udHJhZGFzIl0sIHByZVsiZW50cmFkYXNfZXNwZXJhZGFzIl0pKQogICAgICAg
REM ICAgICAgICAgcHJpbnQodSIgICB7fToge30iLmZvcm1hdChwdGV4dCgiZm9udGVzX3JlaW5q
REM X2NvcnJlc3BvbmRlbmNpYSIpLCBwdGV4dCgib2siKSBpZiBub3QgcHJlWyJlcnJvcyJdIGVs
REM c2UgcHRleHQoImVycm8iKSkpCiAgICAgICAgICAgICAgICBwcmludCh1IiAgIHt9OiB7fSIu
REM Zm9ybWF0KHB0ZXh0KCJmb250ZXNfcmVpbmpfY2FtaW5obyIpLCBwYXN0YV9lbnRyYWRhKSkK
REM ICAgICAgICAgICAgICAgIHByaW50KHUiIikKICAgICAgICAgICAgICAgIGlmIG5vdCBwcmVb
REM ImVycm9zIl06CiAgICAgICAgICAgICAgICAgICAgdmFsaWRvcyArPSAxCiAgICAgICAgICAg
REM ICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGF2aXNvcy5hcHBlbmQodSJ7fToge30g
REM cHJvYmxlbWEocykgZGUgY29ycmVzcG9uZMOqbmNpYTsgbsOjbyBlc2NvbGhhIGVzdGEgcGFz
REM dGEgbmEgcmVpbnRlZ3Jhw6fDo28uIi5mb3JtYXQobm9tZV9wYXN0YSwgbGVuKHByZVsiZXJy
REM b3MiXSkpKQogICAgICAgICAgICBpZiB2YWxpZG9zID09IDA6CiAgICAgICAgICAgICAgICBl
REM cnJvcy5hcHBlbmQodSJOZW5odW0gZG9zIGNhbmRpZGF0b3MgZGUgcmVpbnRlZ3Jhw6fDo28g
REM cGFzc291IG5hIHZhbGlkYcOnw6NvIHByw6l2aWEuIikKCiAgICBpZiBlcnJvczoKICAgICAg
REM ICBwcmludCh1IiIpCiAgICAgICAgcHJpbnQodSIgIiArIHB0ZXh0KCJibG9xdWVhZG8iKSkK
REM ICAgICAgICBmb3IgZXJybyBpbiBlcnJvc1s6NDBdOiBwcmludCh1IiAgLSB7fSIuZm9ybWF0
REM KGVycm8pKQogICAgICAgIHJldHVybiAxCiAgICBwcmludCh1IiIpCiAgICBpZiBhdmlzb3M6
REM CiAgICAgICAgcHJpbnQodSIgIiArIHB0ZXh0KCJhcHRvX2F2aXNvIikpCiAgICAgICAgZm9y
REM IGF2aXNvIGluIGF2aXNvczogcHJpbnQodSIgIC0ge30iLmZvcm1hdChhdmlzbykpCiAgICBl
REM bHNlOgogICAgICAgIHByaW50KHUiICIgKyBwdGV4dCgiYXB0byIpKQogICAgcHJpbnQodSIg
REM IiArIHB0ZXh0KCJjb250aW51YXIiKSkKICAgIHByaW50KHUiIikKICAgIHJldHVybiAwCgpk
REM ZWYgbGVyX2xpbmhhc19yYXcoY2FtaW5obyk6CiAgICB3aXRoIGlvLm9wZW4oY2FtaW5obywg
REM InIiLCBlbmNvZGluZz0idXRmLTgiLCBlcnJvcnM9InJlcGxhY2UiLCBuZXdsaW5lPSIiKSBh
REM cyBmOgogICAgICAgIGNvbnRldWRvID0gZi5yZWFkKCkKICAgIHJldHVybiBjb250ZXVkby5z
REM cGxpdGxpbmVzKGtlZXBlbmRzPVRydWUpCgoKZGVmIGVoX2FycXVpdm9fZ2VyYWRvKG5vbWUp
REM OgogICAgcmV0dXJuIG5vbWUuc3RhcnRzd2l0aChQUkVGSVhPKQoKCklHTk9SQURPU19FWFRS
REM QUNBT19BVVRPTUFUSUNBID0gW10KCmRlZiBjb2xldGFyX2NhbmRpZGF0b3NfZXh0cmFjYW8o
REM cGFzdGFfZ2FtZSk6CiAgICBjYW5kaWRhdG9zID0gW10KICAgIGlnbm9yYWRhcyA9IHNldChw
REM Lmxvd2VyKCkgZm9yIHAgaW4gUEFTVEFTX0lHTk9SQURBUykKICAgIGZvciBwYXN0YV9hdHVh
REM bCwgc3VicGFzdGFzLCBhcnF1aXZvcyBpbiBvcy53YWxrKHBhc3RhX2dhbWUpOgogICAgICAg
REM IHN1YnBhc3Rhc1s6XSA9IFtwIGZvciBwIGluIHN1YnBhc3RhcyBpZiBwLmxvd2VyKCkgbm90
REM IGluIGlnbm9yYWRhc10KICAgICAgICBmb3Igbm9tZSBpbiBhcnF1aXZvczoKICAgICAgICAg
REM ICAgY2FtaW5obyA9IG9zLnBhdGguam9pbihwYXN0YV9hdHVhbCwgbm9tZSkKICAgICAgICAg
REM ICAgaWYgZWhfYXJxdWl2b19nZXJhZG8obm9tZSk6CiAgICAgICAgICAgICAgICBjb250aW51
REM ZQogICAgICAgICAgICBpZiBub3Qgbm9tZS5sb3dlcigpLmVuZHN3aXRoKEVYVEVOU09FUyk6
REM CiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICByZWxfY2FuZGlkYXRvID0g
REM b3MucGF0aC5yZWxwYXRoKGNhbWluaG8sIHBhc3RhX2dhbWUpCiAgICAgICAgICAgIGlmIGFy
REM cXVpdm9fZ2xvYmFsbWVudGVfaWdub3JhZG9fZXh0cmFjYW8ocmVsX2NhbmRpZGF0byk6CiAg
REM ICAgICAgICAgICAgICBJR05PUkFET1NfRVhUUkFDQU9fQVVUT01BVElDQS5hcHBlbmQocmVs
REM X2NhbmRpZGF0by5yZXBsYWNlKG9zLnNlcCwgIi8iKSkKICAgICAgICAgICAgICAgIGNvbnRp
REM bnVlCiAgICAgICAgICAgICMgTsOjbyBleHRyYWlyIHNjcmlwdC1wb2VtcmVzcG9uc2VzIGJh
REM c2UgcXVhbmRvIGVsZSDDqSBlc3RydXR1cmFsbWVudGUKICAgICAgICAgICAgIyBlcXVpdmFs
REM ZW50ZSBhbyBERExDL3RlbXBsYXRlIGUgbsOjbyBow6EgbmVuaHVtYSByZWZlcsOqbmNpYSBl
REM eHRlcm5hLgogICAgICAgICAgICAjIEEgZGVjaXPDo28gw6kgZmVpdGEgYXF1aSwgYW50ZXMg
REM ZGEgY3JpYcOnw6NvIGRvIG1hcGEuCiAgICAgICAgICAgIGlmIGRldmVfaWdub3Jhcl9wb2Vt
REM cmVzcG9uc2VzX25hb191c2FkbyhwYXN0YV9nYW1lLCBjYW1pbmhvKToKICAgICAgICAgICAg
REM ICAgIElHTk9SQURPU19FWFRSQUNBT19BVVRPTUFUSUNBLmFwcGVuZCgKICAgICAgICAgICAg
REM ICAgICAgICBvcy5wYXRoLnJlbHBhdGgoY2FtaW5obywgcGFzdGFfZ2FtZSkucmVwbGFjZShv
REM cy5zZXAsICIvIikpCiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICBjYW5k
REM aWRhdG9zLmFwcGVuZChjYW1pbmhvKQogICAgcmV0dXJuIGNhbmRpZGF0b3MKCgpkZWYgZWhf
REM YXJxdWl2b19saXN0YV9wYWxhdnJhc19wb2VtYShjYW1pbmhvKToKICAgIGJhc2UgPSBvcy5w
REM YXRoLnNwbGl0ZXh0KG9zLnBhdGguYmFzZW5hbWUoY2FtaW5obyBvciB1JycpKVswXS5sb3dl
REM cigpCiAgICBub3JtYWxpemFkbyA9IHJlLnN1YihyJ1teYS16MC05XSsnLCAnJywgdW5pY29k
REM ZWRhdGEubm9ybWFsaXplKCdORktEJywgYmFzZSkuZW5jb2RlKCdhc2NpaScsICdpZ25vcmUn
REM KS5kZWNvZGUoJ2FzY2lpJykpCiAgICBub21lcyA9IFBPRU1fV09SRFNfTk9NRVNfTk9STUFM
REM SVpBRE9TCiAgICBpZiBub3JtYWxpemFkbyBpbiBub21lczoKICAgICAgICByZXR1cm4gVHJ1
REM ZQogICAgIyBGYWxsYmFjayBwZWxvIGNvbnRlw7pkbzogcmVkdXogZGVwZW5kw6puY2lhIGRv
REM IG5vbWUgdXNhZG8gcG9yIGNhZGEgbW9kLgogICAgdHJ5OgogICAgICAgIHdpdGggaW8ub3Bl
REM bihjYW1pbmhvLCAncicsIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0ncmVwbGFjZScsIG5l
REM d2xpbmU9JycpIGFzIGY6CiAgICAgICAgICAgIGZvciBicnV0byBpbiBmOgogICAgICAgICAg
REM ICAgICAgbGluaGEgPSBicnV0by5zdHJpcCgpCiAgICAgICAgICAgICAgICBpZiBub3QgbGlu
REM aGEgb3IgbGluaGEuc3RhcnRzd2l0aCgnIycpOgogICAgICAgICAgICAgICAgICAgIGNvbnRp
REM bnVlCiAgICAgICAgICAgICAgICBwYXJ0ZXMgPSBbeC5zdHJpcCgpIGZvciB4IGluIGxpbmhh
REM LnNwbGl0KCcsJyldCiAgICAgICAgICAgICAgICBpZiBsZW4ocGFydGVzKSA+PSA0OgogICAg
REM ICAgICAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgZmxvYXQocGFy
REM dGVzWzFdKTsgZmxvYXQocGFydGVzWzJdKTsgZmxvYXQocGFydGVzWzNdKQogICAgICAgICAg
REM ICAgICAgICAgICAgICByZXR1cm4gVHJ1ZQogICAgICAgICAgICAgICAgICAgIGV4Y2VwdCBF
REM eGNlcHRpb246CiAgICAgICAgICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAgICAg
REM IGJyZWFrCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIHJldHVybiBG
REM YWxzZQoKCmRlZiBleHRyYWlyX3R4dF9saXN0YV9wYWxhdnJhc19wb2VtYShjYW1pbmhvKToK
REM ICAgICIiIkV4dHJhaSBzb21lbnRlIGEgcHJpbWVpcmEgY29sdW5hICh3b3JkKSBkYXMgbGlz
REM dGFzIENTViBkZSBwb2VtYXMuCgogICAgQ29tZW50w6FyaW9zLCBjYWJlw6dhbGhvcyBlIG9z
REM IHRyw6pzIHBlc29zIG51bcOpcmljb3MgZmljYW0gZm9yYSBkYSB0cmFkdcOnw6NvLgogICAg
REM TyBtYXBhIGd1YXJkYSBhIHBvc2nDp8OjbyBkYSBwcmltZWlyYSBjb2x1bmEgcGFyYSBhIHJl
REM aW50ZWdyYcOnw6NvIHByZXNlcnZhcgogICAgaW50ZWdyYWxtZW50ZSBvIHJlc3RhbnRlIGRh
REM IGxpbmhhLgogICAgIiIiCiAgICBlbnRyYWRhcyA9IFtdCiAgICBsaW5oYXMgPSBsZXJfbGlu
REM aGFzX3JhdyhjYW1pbmhvKQogICAgZm9yIG51bWVybywgcmF3IGluIGVudW1lcmF0ZShsaW5o
REM YXMsIDEpOgogICAgICAgIGxpbmhhID0gcmF3LnJzdHJpcCgnXHJcbicpCiAgICAgICAgbGlt
REM cGEgPSBsaW5oYS5zdHJpcCgpCiAgICAgICAgaWYgbm90IGxpbXBhIG9yIGxpbXBhLnN0YXJ0
REM c3dpdGgoJyMnKToKICAgICAgICAgICAgY29udGludWUKICAgICAgICBwYXJ0ZXMgPSBsaW5o
REM YS5zcGxpdCgnLCcpCiAgICAgICAgaWYgbGVuKHBhcnRlcykgPCA0OgogICAgICAgICAgICBj
REM b250aW51ZQogICAgICAgIHRyeToKICAgICAgICAgICAgZmxvYXQocGFydGVzWzFdLnN0cmlw
REM KCkpOyBmbG9hdChwYXJ0ZXNbMl0uc3RyaXAoKSk7IGZsb2F0KHBhcnRlc1szXS5zdHJpcCgp
REM KQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAg
REM ICAgaW5pY2lvID0gbGVuKGxpbmhhKSAtIGxlbihsaW5oYS5sc3RyaXAoKSkKICAgICAgICBw
REM YWxhdnJhID0gcGFydGVzWzBdLnN0cmlwKCkKICAgICAgICBpZiBub3QgcGFsYXZyYToKICAg
REM ICAgICAgICAgY29udGludWUKICAgICAgICAjIE7Do28gcGVybWl0aXIgdW1hIHByaW1laXJh
REM IGNvbHVuYSBxdWUgasOhIHNlamEgYXBlbmFzIHVtIG7Dum1lcm86IG5vCiAgICAgICAgIyBm
REM b3JtYXRvIGNvbmhlY2lkbyBpc3NvIMOpIMOtbmRpY2UvcGVzbywgbsOjbyBwYWxhdnJhIGRv
REM IGpvZ28uCiAgICAgICAgaWYgcmUuZnVsbG1hdGNoKHInWy0rXT9cZCsoPzpcLlxkKyk/Jywg
REM cGFsYXZyYSk6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgaW5pY2lvX3JlYWwgPSBs
REM aW5oYS5maW5kKHBhbGF2cmEsIGluaWNpbykKICAgICAgICBmaW1fcmVhbCA9IGluaWNpb19y
REM ZWFsICsgbGVuKHBhbGF2cmEpCiAgICAgICAgZW50cmFkYXMuYXBwZW5kKHsKICAgICAgICAg
REM ICAgJ2xpbmhhJzogbnVtZXJvLAogICAgICAgICAgICAnY29sdW5hX2luaWNpbyc6IGluaWNp
REM b19yZWFsLAogICAgICAgICAgICAnY29sdW5hX2ZpbSc6IGZpbV9yZWFsLAogICAgICAgICAg
REM ICAnb3JpZ2luYWwnOiBwYWxhdnJhLAogICAgICAgICAgICAndGlwbyc6ICdwb2VtYV9wYWxh
REM dnJhX3R4dCcsCiAgICAgICAgICAgICdjb25maWFuY2EnOiAxMDAsCiAgICAgICAgICAgICdj
REM b250ZXh0byc6IHUncGFsYXZyYSBleGliaWRhIGRvIGJhbmNvIENTViBkbyBtaW5pam9nbyBk
REM ZSBwb2VtYXMnLAogICAgICAgIH0pCiAgICByZXR1cm4gZW50cmFkYXMKCgpkZWYgZXNjcmV2
REM ZXJfdHh0X3BhbGF2cmFzX2V4dHJhaWRvKGNhbWluaG9fb3JpZ2VtLCBjYW1pbmhvX2Rlc3Rp
REM bm8sIGVudHJhZGFzKToKICAgIHBhc3RhID0gb3MucGF0aC5kaXJuYW1lKGNhbWluaG9fZGVz
REM dGlubykKICAgIGlmIHBhc3RhIGFuZCBub3Qgb3MucGF0aC5pc2RpcihwYXN0YSk6CiAgICAg
REM ICAgb3MubWFrZWRpcnMocGFzdGEpCiAgICB3aXRoIGlvLm9wZW4oY2FtaW5ob19kZXN0aW5v
REM LCAndycsIGVuY29kaW5nPSd1dGYtOCcsIG5ld2xpbmU9J1xuJykgYXMgZjoKICAgICAgICBm
REM LndyaXRlKHUnXG4nLmpvaW4odScgICAgJyArIGNvZGlmaWNhcl9saXRlcmFsX3RyYWR1Y2Fv
REM KGVbJ29yaWdpbmFsJ10pIGZvciBlIGluIGVudHJhZGFzKSkKICAgICAgICBpZiBlbnRyYWRh
REM czoKICAgICAgICAgICAgZi53cml0ZSh1J1xuJykKCgpkZWYgY29waWFyX2FycXVpdm9fdHh0
REM KGNhbWluaG9fb3JpZ2VtLCBjYW1pbmhvX2Rlc3Rpbm8pOgogICAgcGFzdGFfZGVzdGlubyA9
REM IG9zLnBhdGguZGlybmFtZShjYW1pbmhvX2Rlc3Rpbm8pCiAgICBpZiBwYXN0YV9kZXN0aW5v
REM IGFuZCBub3Qgb3MucGF0aC5pc2RpcihwYXN0YV9kZXN0aW5vKToKICAgICAgICBvcy5tYWtl
REM ZGlycyhwYXN0YV9kZXN0aW5vKQogICAgd2l0aCBpby5vcGVuKGNhbWluaG9fb3JpZ2VtLCAi
REM cmIiKSBhcyBvcmlnZW06CiAgICAgICAgZGFkb3MgPSBvcmlnZW0ucmVhZCgpCiAgICB3aXRo
REM IGlvLm9wZW4oY2FtaW5ob19kZXN0aW5vLCAid2IiKSBhcyBkZXN0aW5vOgogICAgICAgIGRl
REM c3Rpbm8ud3JpdGUoZGFkb3MpCgoKZGVmIG5vcm1hbGl6YXJfcmVmZXJlbmNpYV9hcnF1aXZv
REM KHZhbG9yKToKICAgIHRyeToKICAgICAgICB2YWxvciA9IHZhbG9yLnJlcGxhY2UodSJcXCIs
REM IHUiLyIpLnN0cmlwKCkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcmV0dXJuIHUi
REM IgogICAgd2hpbGUgdmFsb3Iuc3RhcnRzd2l0aCh1Ii4vIik6CiAgICAgICAgdmFsb3IgPSB2
REM YWxvclsyOl0KICAgIHdoaWxlIHZhbG9yLnN0YXJ0c3dpdGgodSIuLi8iKToKICAgICAgICB2
REM YWxvciA9IHZhbG9yWzM6XQogICAgd2hpbGUgdmFsb3Iuc3RhcnRzd2l0aCh1Ii8iKToKICAg
REM ICAgICB2YWxvciA9IHZhbG9yWzE6XQogICAgcmV0dXJuIHZhbG9yLnJlcGxhY2UodSIvLyIs
REM IHUiLyIpLmxvd2VyKCkKCgpkZWYgY29uc3RydWlyX2luZGljZV9hcnF1aXZvcyhwYXN0YV9i
REM YXNlKToKICAgIGluZGljZSA9IHNldCgpCiAgICBpZiBub3QgcGFzdGFfYmFzZSBvciBub3Qg
REM b3MucGF0aC5pc2RpcihwYXN0YV9iYXNlKToKICAgICAgICByZXR1cm4gaW5kaWNlCiAgICBp
REM Z25vcmFkYXMgPSBzZXQocC5sb3dlcigpIGZvciBwIGluIFBBU1RBU19JR05PUkFEQVMpCiAg
REM ICBmb3IgcGFzdGFfYXR1YWwsIHN1YnBhc3RhcywgYXJxdWl2b3MgaW4gb3Mud2FsayhwYXN0
REM YV9iYXNlKToKICAgICAgICBzdWJwYXN0YXNbOl0gPSBbcCBmb3IgcCBpbiBzdWJwYXN0YXMg
REM aWYgcC5sb3dlcigpIG5vdCBpbiBpZ25vcmFkYXNdCiAgICAgICAgZm9yIG5vbWUgaW4gYXJx
REM dWl2b3M6CiAgICAgICAgICAgIGNhbWluaG8gPSBvcy5wYXRoLmpvaW4ocGFzdGFfYXR1YWws
REM IG5vbWUpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHJlbGF0aXZvID0gb3Mu
REM cGF0aC5yZWxwYXRoKGNhbWluaG8sIHBhc3RhX2Jhc2UpCiAgICAgICAgICAgIGV4Y2VwdCBF
REM eGNlcHRpb246CiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICBpbmRpY2Uu
REM YWRkKG5vcm1hbGl6YXJfcmVmZXJlbmNpYV9hcnF1aXZvKHJlbGF0aXZvKSkKICAgICAgICAg
REM ICAgaW5kaWNlLmFkZChub3JtYWxpemFyX3JlZmVyZW5jaWFfYXJxdWl2byhub21lKSkKICAg
REM IHJldHVybiBpbmRpY2UKCgpkZWYgcmVmZXJlbmNpYV9leGlzdGVfbm9fbW9kKHZhbG9yX2Nv
REM bV9hc3BhcywgaW5kaWNlX2FycXVpdm9zKToKICAgIGludGVyaW9yID0gdmFsb3JfY29tX2Fz
REM cGFzWzE6LTFdCiAgICBub3JtYWxpemFkbyA9IG5vcm1hbGl6YXJfcmVmZXJlbmNpYV9hcnF1
REM aXZvKGludGVyaW9yKQogICAgaWYgbm90IG5vcm1hbGl6YWRvOgogICAgICAgIHJldHVybiBU
REM cnVlCiAgICBpZiBub3JtYWxpemFkbyBpbiBpbmRpY2VfYXJxdWl2b3M6CiAgICAgICAgcmV0
REM dXJuIFRydWUKICAgIHJldHVybiBGYWxzZQoKCmRlZiBlaF9yZW5weV9tb2Rlcm5vKGNhbWlu
REM aG8pOgogICAgcmV0dXJuIGNhbWluaG8ubG93ZXIoKS5lbmRzd2l0aCgiX3Jlbi5weSIpCgoK
REM ZGVmIG1hc2NhcmFyX3NlY29lc19weXRob25fcmVucHkoY29udGV1ZG8pOgogICAgIiIiTWFu
REM dMOpbSBzb21lbnRlIGFzIHNlw6fDtWVzIFJlbidQeSBkZSB1bSBfcmVuLnB5LCBwcmVzZXJ2
REM YW5kbyBvZmZzZXRzLiIiIgogICAgaWYgbm90IGNvbnRldWRvOgogICAgICAgIHJldHVybiBj
REM b250ZXVkbwogICAgbGluaGFzID0gY29udGV1ZG8uc3BsaXRsaW5lcyhUcnVlKQogICAgYXRp
REM dm8gPSBGYWxzZQogICAgc2FpZGEgPSBbXQogICAgZm9yIGxpbmhhIGluIGxpbmhhczoKICAg
REM ICAgICBtYXJjYWRvciA9IGxpbmhhLnJzdHJpcCgiXHJcbiIpCiAgICAgICAgaWYgbWFyY2Fk
REM b3IgPT0gJyIiInJlbnB5JzoKICAgICAgICAgICAgYXRpdm8gPSBUcnVlCiAgICAgICAgICAg
REM IHNhaWRhLmFwcGVuZChsaW5oYSkKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpZiBt
REM YXJjYWRvciA9PSAnIiIiJyBhbmQgYXRpdm86CiAgICAgICAgICAgIHNhaWRhLmFwcGVuZChs
REM aW5oYSkKICAgICAgICAgICAgYXRpdm8gPSBGYWxzZQogICAgICAgICAgICBjb250aW51ZQog
REM ICAgICAgIGlmIGF0aXZvOgogICAgICAgICAgICBzYWlkYS5hcHBlbmQobGluaGEpCiAgICAg
REM ICAgZWxzZToKICAgICAgICAgICAgIyBQcmVzZXJ2YSBxdWVicmFzIGUgb2Zmc2V0cyBwYXJh
REM IG8gbWFwYS4KICAgICAgICAgICAgc2FpZGEuYXBwZW5kKHUiIi5qb2luKHUiXG4iIGlmIGMg
REM PT0gdSJcbiIgZWxzZSAodSJcciIgaWYgYyA9PSB1IlxyIiBlbHNlIHUiICIpIGZvciBjIGlu
REM IGxpbmhhKSkKICAgIHJldHVybiB1IiIuam9pbihzYWlkYSkKCgpkZWYgbGluaGFzX3JlbnB5
REM X2F0aXZhcyhjYW1pbmhvLCBsaW5oYXNfcmF3KToKICAgIGlmIG5vdCBlaF9yZW5weV9tb2Rl
REM cm5vKGNhbWluaG8pOgogICAgICAgIHJldHVybiBbVHJ1ZV0gKiBsZW4obGluaGFzX3JhdykK
REM ICAgIGF0aXZvID0gRmFsc2UKICAgIHJlc3VsdGFkbyA9IFtdCiAgICBmb3IgbGluaGEgaW4g
REM bGluaGFzX3JhdzoKICAgICAgICBtYXJjYWRvciA9IGxpbmhhLnJzdHJpcCgiXHJcbiIpCiAg
REM ICAgICAgaWYgbWFyY2Fkb3IgPT0gJyIiInJlbnB5JzoKICAgICAgICAgICAgYXRpdm8gPSBU
REM cnVlCiAgICAgICAgICAgIHJlc3VsdGFkby5hcHBlbmQoVHJ1ZSkKICAgICAgICAgICAgY29u
REM dGludWUKICAgICAgICBpZiBtYXJjYWRvciA9PSAnIiIiJyBhbmQgYXRpdm86CiAgICAgICAg
REM ICAgIHJlc3VsdGFkby5hcHBlbmQoVHJ1ZSkKICAgICAgICAgICAgYXRpdm8gPSBGYWxzZQog
REM ICAgICAgICAgICBjb250aW51ZQogICAgICAgIHJlc3VsdGFkby5hcHBlbmQoYXRpdm8pCiAg
REM ICByZXR1cm4gcmVzdWx0YWRvCgoKIyAtLS0gRERBQyBzYWZldHkga25vd2xlZGdlIGxheWVy
REM IChhZGRpdGl2ZTsgbGVnYWN5IGV4dHJhY3Rpb24gcmVtYWlucyBhdXRob3JpdGF0aXZlKSAt
REM LS0KCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KIyBPUsOBQ1VMTyBTRU3Dgk5USUNPIFJF
REM TidQWSAob3BjaW9uYWwsIHByZWZlcmVuY2lhbCBxdWFuZG8gdW0gU0RLIGNvbXBhdMOtdmVs
REM CiMgZXN0aXZlciBkaXNwb27DrXZlbCBuYSBtw6FxdWluYSBkbyB1c3XDoXJpbykKIyAtLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLQojIE8gRERBQyBuw6NvIGNvcGlhIG8gcGFyc2VyL2VuZ2lu
REM ZSBkbyBSZW4nUHkgcGFyYSBkZW50cm8gZG8gLmJhdC4gRW0gdmV6IGRpc3NvLAojIHF1YW5k
REM byBlbmNvbnRyYSB1bSBTREsgb2ZpY2lhbCwgY2hhbWEgbyBwcsOzcHJpbyBDTEkvQVNUIGRl
REM IERpYWxvZ3VlL1N0cmluZ3MgZW0KIyB1bSBwcm9qZXRvIHRlbXBvcsOhcmlvIHNvbWVudGUt
REM bGVpdHVyYS4gSXNzbyBwZXJtaXRlIHVzYXIgbyBjb25oZWNpbWVudG8KIyBzZW3Dom50aWNv
REM IHJlYWwgZGEgZW5naW5lIHNlbSBhYmFuZG9uYXIgb3MgZGV0ZWN0b3JlcyBlc3BlY8OtZmlj
REM b3MgZGUgRERMQy4KT1JBQ1VMT19SRU5QWSA9IHsKICAgICJhdGl2byI6IEZhbHNlLAogICAg
REM InNkayI6IHUiIiwKICAgICJ2ZXJzYW8iOiB1IiIsCiAgICAiZW50cmFkYXMiOiBbXSwKICAg
REM ICJwb3JfYXJxdWl2byI6IHt9LAogICAgImdhbWVfcm9vdCI6IHUiIiwKICAgICJuYXRpdmFz
REM X3RvdGFsIjogMCwKICAgICJuYXRpdmFzX21hcGVhZGFzIjogMCwKICAgICJuYXRpdmFzX2R1
REM cGxpY2FkYXMiOiAwLAogICAgIm5hdGl2YXNfYW1iaWd1YXMiOiAwLAogICAgIm5hdGl2YXNf
REM bXVsdGlsaW5oYSI6IDAsCiAgICAibmF0aXZhc19jb2JlcnR1cmFfcmVhbCI6IDAsCiAgICAi
REM bmF0aXZhc19jb2JlcnR1cmFfcGN0IjogMTAwLjAsCiAgICAibmF0aXZhc19lbV9lc2NvcG8i
REM OiAwLAogICAgIm5hdGl2YXNfZm9yYV9lc2NvcG8iOiAwLAogICAgIm5hdGl2YXNfZmFsbGJh
REM Y2tfdGV4dG8iOiAwLAogICAgIm5hdGl2YXNfbmFvX2xvY2FsaXphZGFzIjogMCwKICAgICJm
REM YWxoYXMiOiBbXSwKICAgICJjYW5kaWRhdG9zIjogW10sCn0KClJFTnB5X0VTVEFET1NfVEVD
REM TklDT1MgPSBmcm96ZW5zZXQoewogICAgImVuZGluZyIsICJzdGF0ZSIsICJzdGF0dXMiLCAi
REM ZmxhZyIsICJyb3V0ZSIsICJjaGFwdGVyIiwgImFjdCIsCiAgICAic2NlbmUiLCAic2NlbmVf
REM aWQiLCAic2NlbmVfaW5kZXgiLCAicm91dGVfaWQiLCAicm91dGVfaW5kZXgiLAogICAgImNo
REM YXB0ZXJfaWQiLCAiY2hhcHRlcl9pbmRleCIsICJjaG9pY2UiLCAiY2hvaWNlX2lkIiwgImV2
REM ZW50X2lkIiwKICAgICJldmVudCIsICJwYXNzYWdlIiwgInBhc3NhZ2VfaWQiLCAiY3VycmVu
REM dF9yb3V0ZSIsICJjdXJyZW50X3NjZW5lIiwKfSkKCkRETENfVkFSSUFWRUlTX05PTUVfQ09O
REM SEVDSURBUyA9IGZyb3plbnNldCh7CiAgICAibl9uYW1lIiwgInRfbmFtZSIsICJjX25hbWUi
REM LCAic2tfbmFtZSIsICJtb21fbmFtZSIsICJkYWRfbmFtZSIsCiAgICAiZG9jdG9yX25hbWUi
REM LCAidGVhY2hlcl9uYW1lIiwgInByb2Zlc3Nvcl9uYW1lIiwgInBvbGljZV9uYW1lIiwKICAg
REM ICJwb3ZfbmFtZSIsICJwbGF5ZXJfbmFtZSIsICJjaF9uYW1lIiwgInlfbmFtZSIsICJzX25h
REM bWUiLAogICAgIm1fbmFtZSIsICJuYW1lX3NheW9yaSIsICJuYW1lX25hdHN1a2kiLCAibmFt
REM ZV95dXJpIiwgIm5hbWVfbW9uaWthIiwKfSkKCiMgTm9tZXMgbW9kZXJub3MvbGVnYWRvcyBk
REM byBiYW5jbyBkbyBtaW5pZ2FtZSBkZSBwb2VtYXMuClBPRU1fV09SRFNfTk9NRVNfTk9STUFM
REM SVpBRE9TID0gZnJvemVuc2V0KHsKICAgICJlZGl0ZWRwb2Vtd29yZHMiLCAicG9lbXdvcmRz
REM IiwgImVkaXRlZHBvZW13b3JkIiwgInBvZW13b3JkIiwKICAgICJlZGl0ZWRwb2Vtc3dvcmQi
REM LCAicG9lbXN3b3JkIiwgInBvZW13b3JkbGlzdCIsICJwb2Vtd29yZHNsaXN0IiwKICAgICJw
REM b2Vtd29yZHNyZW4iLCAiZWRpdGVkcG9lbXdvcmRzcmVuIiwgInBvZW13b3Jkc3B5IiwKfSkK
REM CkJJQkxJT1RFQ0FfUkVOUFkgPSB7CiAgICAidG9rZW5zX25hb19kaWFsb2dvIjogc2V0KFsK
REM ICAgICAgICAidm9pY2UiLCAiZml0IiwgImltYWdlIiwgInBsYXkiLCAicXVldWUiLCAic3Rv
REM cCIsICJzY2VuZSIsICJzaG93IiwgImhpZGUiLCAid2l0aCIsCiAgICAgICAgIndpbmRvdyIs
REM ICJwYXVzZSIsICJsYWJlbCIsICJqdW1wIiwgImNhbGwiLCAicmV0dXJuIiwgInB5dGhvbiIs
REM ICJpbml0IiwgInRyYW5zbGF0ZSIsCiAgICAgICAgInN0eWxlIiwgInRyYW5zZm9ybSIsICJs
REM YXllcmVkaW1hZ2UiLCAic2NyZWVuIiwgImNhbWVyYSIsICJwaHlzaWNzIiwgImZvbnQiLCAi
REM Y29sb3IiLAogICAgICAgICJob3Zlcl9jb2xvciIsICJzZWxlY3RlZF9jb2xvciIsICJpbnNl
REM bnNpdGl2ZV9jb2xvciIsICJpZGxlX2NvbG9yIiwgImFkZCIsICJrZXkiLCAia2V5c3ltIiwK
REM ICAgICAgICAiaWQiLCAic3R5bGVfcHJlZml4IiwgImJhY2tncm91bmQiLCAiZm9yZWdyb3Vu
REM ZCIsICJ0aHVtYiIsICJiYXNlX2JhciIsICJ0b3BfYmFyIiwKICAgICAgICAiYm90dG9tX2Jh
REM ciIsICJ1bnNjcm9sbGFibGUiLCAic2Nyb2xsYmFycyIsICJsYXlvdXQiLCAib3V0bGluZXMi
REM LCAiaG92ZXJfb3V0bGluZXMiLAogICAgICAgICJpbnB1dCIsICJjYXJldCIsICJzaXplX2dy
REM b3VwIiwgImFjdGlvbiIsICJ2YWx1ZSIsICJhZGp1c3RtZW50IiwgInByb3BlcnRpZXMiLCAi
REM eHBvcyIsCiAgICAgICAgImJnIiwgIm11c2ljIiwgInNvdW5kIiwgImF1ZGlvIiwgInNmeCIs
REM ICJhbWJpZW5jZSIsICJyZW5weSIsCiAgICAgICAgInlwb3MiLCAieGFsaWduIiwgInlhbGln
REM biIsICJ4YW5jaG9yIiwgInlhbmNob3IiLCAieHNpemUiLCAieXNpemUiLCAieG9mZnNldCIs
REM ICJ5b2Zmc2V0IiwKICAgICAgICAic3BhY2luZyIsICJwYWRkaW5nIiwgIm1hcmdpbiIsICJh
REM dCIsICJ0b29sdGlwIiwgImhvdmVyX3NvdW5kIiwgImFjdGl2YXRlX3NvdW5kIiwKICAgICAg
REM ICAiZm9jdXNfbWFzayIsICJyYW5nZSIsICJhbHQiLCAidGltZXIiLCAidGVzdCIsICJvbGQi
REM LCAibmV3IiwKICAgICAgICAic2hhZGVyIiwgInRleHRfc3R5bGUiLCAic3R5bGVfZ3JvdXAi
REM LCAibW91c2UiLAogICAgXSkKfQoKIyAtLS0gQmlibGlvdGVjYSBEREFDOiBjYXRhbG9nbyBz
REM ZXBhcmFkbyBlbSBEVUFTIGJpYmxpb3RlY2FzIGluZGVwZW5kZW50ZXMuCiMgMSkgRERMQyAx
REM LjEuMSBQQyAgLT4gMzUgYXJxdWl2b3MgLnJweSBkYSBhcnZvcmUgImdhbWUiIChubyBqb2dv
REM IG9yaWdpbmFsIGVsZXMKIyAgICB2w6ptIGNvbXBpbGFkb3MgZGVudHJvIGRlIHNjcmlwdHMu
REM cnBhOyBuw6NvIGNvbnRhciBvcyAucnB5YyBjb21vIGFycXVpdm9zIGV4dHJhcykuCiMgMikg
REM RERMQyBNb2QgVGVtcGxhdGUgMi4wIChyZWxlYXNlIHZlcmlmaWPDoXZlbCAyLjEuMCkgLT4g
REM NiBhcnF1aXZvcyAucnB5IG5hIHJhaXoKIyAgICBkZSAiZ2FtZSIgKyBvcyBhcnF1aXZvcyBk
REM ZSAiZ2FtZS9hZHZhbmNlZF9zY3JpcHRzIi4KIyBBcnF1aXZvcyBjb20gbyBtZXNtbyBub21l
REM IG5hcyBkdWFzIGJpYmxpb3RlY2FzIE7Dg08gc8OjbyBmdW5kaWRvczogYSBvcmlnZW0gw6kK
REM IyBlc2NvbGhpZGEgcGVsbyBjYW1pbmhvIGRvIGFycXVpdm8gZGVudHJvIGRvIG1vZC4KCiMg
REM Q29uaGVjaW1lbnRvIGRvIGVjb3NzaXN0ZW1hIG1vZGVybm8gZG8gRERMQyBNb2QgVGVtcGxh
REM dGUuCiMgTsOjbyDDqSB1bWEgd2hpdGVsaXN0IGZlY2hhZGE6IHNlcnZlIGNvbW8gc2luYWwg
REM Y29udGV4dHVhbCBlIGRvY3VtZW50YcOnw6NvIGludGVybmEuCkNBVEFMT0dPX1RFTVBMQVRF
REM X01PREVSTk8gPSB7CiAgICAiX3Jlbi5weSI6IHUiQ8OzZGlnbyBSZW4nUHkvUHl0aG9uIG1v
REM ZGVybm87IHBvZGUgY29udGVyIGJsb2NvcyBSZW4nUHkgZSBzdHJpbmdzIHZpc8OtdmVpcy4i
REM LAogICAgInBvZW13b3Jkc19yZW4ucHkiOiB1IkJhbmNvIG1vZGVybm8gZGUgcGFsYXZyYXMg
REM ZG8gbWluaWdhbWUgZGUgcG9lbWFzLiIsCiAgICAiZGVmaW5pdGlvbnMucnB5IjogdSJEZWZp
REM bmnDp8O1ZXMgZSBub21lcyBleGliaWRvcyBkZSBwZXJzb25hZ2Vucy4iLAogICAgInNjcmVl
REM bnMucnB5IjogdSJUZWxhcyBlIHN0cmluZ3MgZGUgaW50ZXJmYWNlLiIsCiAgICAicG9lbXMu
REM cnB5IjogdSJQb2VtYXMgZSBjb3Jwb3MgZGUgcG9lbWFzLiIsCiAgICAicG9lbXNfc3BlY2lh
REM bC5ycHkiOiB1IlBvZW1hcyBlc3BlY2lhaXMgZSBlc3RydXR1cmFzIHZpc3VhaXMuIiwKfQoK
REM IyBkacOhbG9nbzogVHJ1ZSAgPSBQQVNTQSAgKHRlbSB0ZXh0byB0cmFkdXrDrXZlbCBkZSBm
REM w6FicmljYSwgc2VtcHJlIGV4dHJhw61kbykKIyAgICAgICAgICBGYWxzZSA9IEJBUlJBRE8g
REM KGFycXVpdm8gdMOpY25pY287IHPDsyBhcGFyZWNlIHNlIG8gbW9kIGNvbG9jYXIgdGV4dG8g
REM bm92bykKQklCX0RETEMgPSB1IkRETEMgMS4xLjEiCkJJQl9UUEwgPSB1IlRlbXBsYXRlIDIu
REM MCArIFRlbXBsYXRlIDQuMi40IChsZWdhZG8pICsgVGVtcGxhdGUgNS54IChtb2Rlcm5vKSIK
REM CkJJQkxJT1RFQ0FfRERMQyA9IHt9CkJJQkxJT1RFQ0FfVFBMID0ge30KCiMgLS0tIDEpIERE
REM TEMgMS4xLjEgUEMgLS0gZ2FtZS8gKDM1IGFycXVpdm9zIC5ycHkpIC0tLQpfQ0FUQUxPR09f
REM RERMQyA9ICgKICAgICh1InNjcmlwdC5ycHkiLCB1IlBvbnRvIGRlIGVudHJhZGEsIGluw61j
REM aW8gZG8gam9nbyBlIHJvdGVhbWVudG8gZGUgY2Fww610dWxvcyIsIFRydWUpLAogICAgKHUi
REM c3BsYXNoLnJweSIsIHUiVGVsYSBkZSBhYmVydHVyYSwgYXZpc28gZGUgY29udGXDumRvIGUg
REM Y2hlY2FnZW5zIGluaWNpYWlzIiwgVHJ1ZSksCiAgICAodSJzY3JpcHQtY2gwLnJweSIsIHUi
REM Q2Fww610dWxvIDAgZGEgaGlzdMOzcmlhIiwgVHJ1ZSksCiAgICAodSJzY3JpcHQtY2gxLnJw
REM eSIsIHUiQ2Fww610dWxvIDEgZGEgaGlzdMOzcmlhIiwgVHJ1ZSksCiAgICAodSJzY3JpcHQt
REM Y2gyLnJweSIsIHUiQ2Fww610dWxvIDIgZGEgaGlzdMOzcmlhIiwgVHJ1ZSksCiAgICAodSJz
REM Y3JpcHQtY2gzLnJweSIsIHUiQ2Fww610dWxvIDMgZGEgaGlzdMOzcmlhIiwgVHJ1ZSksCiAg
REM ICAodSJzY3JpcHQtY2g0LnJweSIsIHUiQ2Fww610dWxvIDQgZGEgaGlzdMOzcmlhIiwgVHJ1
REM ZSksCiAgICAodSJzY3JpcHQtY2g1LnJweSIsIHUiQ2Fww610dWxvIDUgZGEgaGlzdMOzcmlh
REM ICh0cmFuc2nDp8OjbyBwYXJhIG8gQXRvIDIpIiwgVHJ1ZSksCiAgICAodSJzY3JpcHQtY2gx
REM MC5ycHkiLCB1IkF0byAyIC0gaW7DrWNpbyIsIFRydWUpLAogICAgKHUic2NyaXB0LWNoMjAu
REM cnB5IiwgdSJBdG8gMiAtIGNvbnRpbnVhw6fDo28iLCBUcnVlKSwKICAgICh1InNjcmlwdC1j
REM aDIxLnJweSIsIHUiQXRvIDIgLSBjb250aW51YcOnw6NvIiwgVHJ1ZSksCiAgICAodSJzY3Jp
REM cHQtY2gyMi5ycHkiLCB1IkF0byAyIC0gY29udGludWHDp8OjbyIsIFRydWUpLAogICAgKHUi
REM c2NyaXB0LWNoMjMucnB5IiwgdSJBdG8gMiAtIGNvbnRpbnVhw6fDo28iLCBUcnVlKSwKICAg
REM ICh1InNjcmlwdC1jaDMwLnJweSIsIHUiQXRvIDIgLSB0cmVjaG8gZmluYWwiLCBUcnVlKSwK
REM ICAgICh1InNjcmlwdC1jaDQwLnJweSIsIHUiQXRvIDMgLSBNb25pa2EgLyBmaW5hbCIsIFRy
REM dWUpLAogICAgKHUic2NyaXB0LWV4Y2x1c2l2ZXMtc2F5b3JpLnJweSIsIHUiQ2VuYXMgZXhj
REM bHVzaXZhcyBkYSBTYXlvcmkiLCBUcnVlKSwKICAgICh1InNjcmlwdC1leGNsdXNpdmVzLW5h
REM dHN1a2kucnB5IiwgdSJDZW5hcyBleGNsdXNpdmFzIGRhIE5hdHN1a2kiLCBUcnVlKSwKICAg
REM ICh1InNjcmlwdC1leGNsdXNpdmVzLXl1cmkucnB5IiwgdSJDZW5hcyBleGNsdXNpdmFzIGRh
REM IFl1cmkiLCBUcnVlKSwKICAgICh1InNjcmlwdC1leGNsdXNpdmVzMi1uYXRzdWtpLnJweSIs
REM IHUiQ2VuYXMgZXhjbHVzaXZhcyBkYSBOYXRzdWtpIChwYXJ0ZSAyKSIsIFRydWUpLAogICAg
REM KHUic2NyaXB0LWV4Y2x1c2l2ZXMyLXl1cmkucnB5IiwgdSJDZW5hcyBleGNsdXNpdmFzIGRh
REM IFl1cmkgKHBhcnRlIDIpIiwgVHJ1ZSksCiAgICAodSJzY3JpcHQtcG9lbWdhbWUucnB5Iiwg
REM dSJNaW5pZ2FtZSBkZSBlc2NyZXZlciBwb2VtYSAoaW50ZXJmYWNlIGUgZmFsYXMpIiwgVHJ1
REM ZSksCiAgICAodSJzY3JpcHQtcG9lbXJlc3BvbnNlcy5ycHkiLCB1IlJlYcOnw7VlcyBkYXMg
REM Z2Fyb3RhcyBhb3MgcG9lbWFzIiwgVHJ1ZSksCiAgICAodSJzY3JpcHQtcG9lbXJlc3BvbnNl
REM czIucnB5IiwgdSJSZWHDp8O1ZXMgZGFzIGdhcm90YXMgYW9zIHBvZW1hcyAocGFydGUgMiki
REM LCBUcnVlKSwKICAgICh1InBvZW1zLnJweSIsIHUiUG9lbWFzIGRvIGpvZ28gKHTDrXR1bG8g
REM ZSBjb3JwbyBkbyBwb2VtYSkiLCBUcnVlKSwKICAgICh1InBvZW1zX3NwZWNpYWwucnB5Iiwg
REM dSJQb2VtYXMgZXNwZWNpYWlzIChNb25pa2EvU2F5b3JpKSIsIFRydWUpLAogICAgKHUiY3Jl
REM ZGl0cy5ycHkiLCB1IlRlbGEgZGUgY3LDqWRpdG9zIiwgVHJ1ZSksCiAgICAodSJzY3JlZW5z
REM LnJweSIsIHUiVGVsYXMgZG8gam9nbyAobWVudSwgc2FsdmFyLCBvcMOnw7VlcywgY2FpeGEg
REM ZGUgdGV4dG8pIiwgVHJ1ZSksCiAgICAodSJvcHRpb25zLnJweSIsIHUiQ29uZmlndXJhw6fD
REM o28gZG8gam9nbyAodMOtdHVsbyBkYSBqYW5lbGEsIG5vbWUgZG8gbW9kLCAnc29icmUnKSIs
REM IFRydWUpLAogICAgKHUiY2dzLnJweSIsIHUiQ29udHJvbGUgZGUgZGVzYmxvcXVlaW8gZGFz
REM IENHcyBkYSBnYWxlcmlhIiwgRmFsc2UpLAogICAgKHUiY29uc29sZS5ycHkiLCB1IkNvbnNv
REM bGUgZGUgZGVzZW52b2x2ZWRvciAvIGRlcHVyYcOnw6NvIiwgRmFsc2UpLAogICAgKHUiZGVm
REM aW5pdGlvbnMucnB5IiwgdSJEZWZpbmnDp8O1ZXMgZGUgcGVyc29uYWdlbnMsIHNwcml0ZXMg
REM ZSB2YXJpw6F2ZWlzOyBubyBmaW5hbCBkbyBhcnF1aXZvIGZpY2FtIG9zIG5vbWVzIGV4aWJp
REM ZG9zIGRhcyBwZXJzb25hZ2VucyAoU2F5b3JpLCBZdXJpLCBOYXRzdWtpLCBNb20sIERhZCwg
REM RG9jdG9yLi4uKSIsIFRydWUpLAogICAgKHUiZWZmZWN0cy5ycHkiLCB1IkVmZWl0b3Mgdmlz
REM dWFpcyAoZ2xpdGNoLCBkaXN0b3LDp8OjbykiLCBGYWxzZSksCiAgICAodSJnbGl0Y2h0ZXh0
REM LnJweSIsIHUiR2VyYWRvciBkZSB0ZXh0byBjb3Jyb21waWRvIChjw7NkaWdvKSIsIEZhbHNl
REM KSwKICAgICh1Imd1aS5ycHkiLCB1IkVzdGlsbyB2aXN1YWwgZGEgaW50ZXJmYWNlIChjb3Jl
REM cywgZm9udGVzLCB0YW1hbmhvcykiLCBGYWxzZSksCiAgICAodSJ0cmFuc2Zvcm1zLnJweSIs
REM IHUiQW5pbWHDp8O1ZXMgZSBwb3NpY2lvbmFtZW50byBkZSBzcHJpdGVzIiwgRmFsc2UpLAop
REM CgojIC0tLSAyKSBERExDIE1vZCBUZW1wbGF0ZSAyLjAgKDIuMS4wKSAtLSBnYW1lLyBlIGdh
REM bWUvYWR2YW5jZWRfc2NyaXB0cy8gLS0tCl9DQVRBTE9HT19UUEwgPSAoCiAgICAodSJvcHRp
REM b25zLnJweSIsIHUiQ29uZmlndXJhw6fDo28gYsOhc2ljYSBkbyB0ZW1wbGF0ZS9tb2QiLCBU
REM cnVlKSwKICAgICh1InNjcmVlbnMucnB5IiwgdSJUZWxhcyBlIHRleHRvcyBkZSBpbnRlcmZh
REM Y2UiLCBUcnVlKSwKICAgICh1InNjcmlwdC1leGFtcGxlLnJweSIsIHUiQ2VuYSBkZSBleGVt
REM cGxvIHBhcmEgbyBtb2RkZXIiLCBUcnVlKSwKICAgICh1InNjcmlwdC5ycHkiLCB1IkVzdHJ1
REM dHVyYS9yb3RlYW1lbnRvIGLDoXNpY28gZG8gcHJvamV0byIsIFRydWUpLAogICAgKHUic3Bs
REM YXNoLnJweSIsIHUiQXZpc29zIGUgdGVsYSBpbmljaWFsIiwgVHJ1ZSksCiAgICAodSJ0dXRv
REM cmlhbHMucnB5IiwgdSJUdXRvcmlhaXMvYXZpc29zIGRvIHRlbXBsYXRlIiwgVHJ1ZSksCiAg
REM ICAodSJhZHZhbmNlZF9zY3JpcHRzL2NyZWRpdHMucnB5IiwgdSJUZWxhIGRlIGNyw6lkaXRv
REM cyIsIFRydWUpLAogICAgKHUiYWR2YW5jZWRfc2NyaXB0cy9wb2Vtcy5ycHkiLCB1IlBvZW1h
REM cyIsIFRydWUpLAogICAgKHUiYWR2YW5jZWRfc2NyaXB0cy9wb2Vtc19zcGVjaWFsLnJweSIs
REM IHUiUG9lbWFzIGVzcGVjaWFpcyIsIFRydWUpLAogICAgKHUiYWR2YW5jZWRfc2NyaXB0cy9z
REM Y3JpcHQtcG9lbWdhbWUucnB5IiwgdSJNaW5pZ2FtZSBkZSBwb2VtYXMiLCBUcnVlKSwKICAg
REM ICh1ImFkdmFuY2VkX3NjcmlwdHMvY2dzLnJweSIsIHUiU2lzdGVtYSBkZSBDR3MiLCBGYWxz
REM ZSksCiAgICAodSJhZHZhbmNlZF9zY3JpcHRzL2NvbnNvbGUucnB5IiwgdSJDb25zb2xlL2Rl
REM c2Vudm9sdmltZW50byIsIEZhbHNlKSwKICAgICh1ImFkdmFuY2VkX3NjcmlwdHMvZGVmaW5p
REM dGlvbnMucnB5IiwgdSJEZWZpbmnDp8O1ZXMgZGUgcGVyc29uYWdlbnMvcmVjdXJzb3M7IGlu
REM Y2x1aSBvcyBub21lcyBleGliaWRvcyBkYXMgcGVyc29uYWdlbnMiLCBUcnVlKSwKICAgICh1
REM ImFkdmFuY2VkX3NjcmlwdHMvZWZmZWN0cy5ycHkiLCB1IkVmZWl0b3MgdmlzdWFpcyIsIEZh
REM bHNlKSwKICAgICh1ImFkdmFuY2VkX3NjcmlwdHMvZ2xpdGNodGV4dC5ycHkiLCB1IkdlcmHD
REM p8Ojby9tYW5pcHVsYcOnw6NvIGRlIHRleHRvIGdsaXRjaCIsIEZhbHNlKSwKICAgICh1ImFk
REM dmFuY2VkX3NjcmlwdHMvZ3VpLnJweSIsIHUiQ29uZmlndXJhw6fDo28gdmlzdWFsIiwgRmFs
REM c2UpLAogICAgKHUiYWR2YW5jZWRfc2NyaXB0cy90cmFuc2Zvcm1zLnJweSIsIHUiVHJhbnNm
REM b3JtYcOnw7Vlcy9wb3NpY2lvbmFtZW50byIsIEZhbHNlKSwKKQoKZm9yIF9lIGluIF9DQVRB
REM TE9HT19ERExDOgogICAgQklCTElPVEVDQV9ERExDW19lWzBdLmxvd2VyKCldID0gewogICAg
REM ICAgICJvcmlnZW0iOiBCSUJfRERMQywgImZ1bmNhbyI6IF9lWzFdLCAiZGlhbG9nbyI6IF9l
REM WzJdLAogICAgfQoKZm9yIF9lIGluIF9DQVRBTE9HT19UUEw6CiAgICBfY2hhdmUgPSBfZVsw
REM XS5sb3dlcigpCiAgICBCSUJMSU9URUNBX1RQTFtfY2hhdmVdID0gewogICAgICAgICJvcmln
REM ZW0iOiBCSUJfVFBMLCAiZnVuY2FvIjogX2VbMV0sICJkaWFsb2dvIjogX2VbMl0sCiAgICB9
REM CiAgICBCSUJMSU9URUNBX1RQTFtfY2hhdmUuc3BsaXQoIi8iKVstMV1dID0gQklCTElPVEVD
REM QV9UUExbX2NoYXZlXQoKCmRlZiBjb25zdWx0YXJfYmlibGlvdGVjYShjYW1pbmhvX3JlbGF0
REM aXZvKToKICAgIGNhbWluaG8gPSBjYW1pbmhvX3JlbGF0aXZvLnJlcGxhY2UoIlxcIiwgIi8i
REM KS5sb3dlcigpLmxzdHJpcCgiLi8iKQogICAgaWYgY2FtaW5oby5zdGFydHN3aXRoKCJnYW1l
REM LyIpOgogICAgICAgIGNhbWluaG8gPSBjYW1pbmhvW2xlbigiZ2FtZS8iKTpdCiAgICBub21l
REM ID0gY2FtaW5oby5zcGxpdCgiLyIpWy0xXQoKICAgICMgQXJxdWl2byBkZW50cm8gZGUgYWR2
REM YW5jZWRfc2NyaXB0cyBwZXJ0ZW5jZSBzZW1wcmUgYW8gVGVtcGxhdGUuCiAgICBpZiAiYWR2
REM YW5jZWRfc2NyaXB0cy8iIGluIGNhbWluaG86CiAgICAgICAgaW5mbyA9IEJJQkxJT1RFQ0Ff
REM VFBMLmdldChjYW1pbmhvLnNwbGl0KCJhZHZhbmNlZF9zY3JpcHRzLyIpWy0xXSkKICAgICAg
REM ICBpbmZvID0gaW5mbyBvciBCSUJMSU9URUNBX1RQTC5nZXQoImFkdmFuY2VkX3NjcmlwdHMv
REM IiArIG5vbWUpCiAgICAgICAgaWYgaW5mbzoKICAgICAgICAgICAgcmV0dXJuIGluZm8KICAg
REM ICAgICByZXR1cm4gTm9uZQoKICAgIGluZm8gPSBCSUJMSU9URUNBX0RETEMuZ2V0KG5vbWUp
REM CiAgICBpZiBpbmZvOgogICAgICAgIHJldHVybiBpbmZvCiAgICBpbmZvID0gQklCTElPVEVD
REM QV9UUEwuZ2V0KG5vbWUpCiAgICBpZiBpbmZvOgogICAgICAgIHJldHVybiBpbmZvCiAgICBp
REM ZiBub21lLnN0YXJ0c3dpdGgoInNjcmlwdC1jaCIpIGFuZCBub21lLmVuZHN3aXRoKCIucnB5
REM Iik6CiAgICAgICAgcmV0dXJuIHsKICAgICAgICAgICAgIm9yaWdlbSI6IEJJQl9ERExDLAog
REM ICAgICAgICAgICAiZnVuY2FvIjogdSJDYXDDrXR1bG8gZGEgaGlzdMOzcmlhIiwKICAgICAg
REM ICAgICAgImRpYWxvZ28iOiBUcnVlLAogICAgICAgIH0KICAgIHJldHVybiBOb25lCgoKX1RS
REM QURVQ09FU19CSUIgPSB7CiAgICAyOiB7CiAgICAgICAgIlBvbnRvIGRlIGVudHJhZGEsIGlu
REM w61jaW8gZG8gam9nbyBlIHJvdGVhbWVudG8gZGUgY2Fww610dWxvcyI6ICJFbnRyeSBwb2lu
REM dCwgZ2FtZSBzdGFydHVwLCBhbmQgY2hhcHRlciByb3V0aW5nIiwKICAgICAgICAiVGVsYSBk
REM ZSBhYmVydHVyYSwgYXZpc28gZGUgY29udGXDumRvIGUgY2hlY2FnZW5zIGluaWNpYWlzIjog
REM Ik9wZW5pbmcgc2NyZWVuLCBjb250ZW50IHdhcm5pbmcsIGFuZCBpbml0aWFsIGNoZWNrcyIs
REM CiAgICAgICAgIkNhcMOtdHVsbyAwIGRhIGhpc3TDs3JpYSI6ICJDaGFwdGVyIDAgb2YgdGhl
REM IHN0b3J5IiwgIkNhcMOtdHVsbyAxIGRhIGhpc3TDs3JpYSI6ICJDaGFwdGVyIDEgb2YgdGhl
REM IHN0b3J5IiwKICAgICAgICAiQ2Fww610dWxvIDIgZGEgaGlzdMOzcmlhIjogIkNoYXB0ZXIg
REM MiBvZiB0aGUgc3RvcnkiLCAiQ2Fww610dWxvIDMgZGEgaGlzdMOzcmlhIjogIkNoYXB0ZXIg
REM MyBvZiB0aGUgc3RvcnkiLAogICAgICAgICJDYXDDrXR1bG8gNCBkYSBoaXN0w7NyaWEiOiAi
REM Q2hhcHRlciA0IG9mIHRoZSBzdG9yeSIsICJDYXDDrXR1bG8gNSBkYSBoaXN0w7NyaWEgKHRy
REM YW5zacOnw6NvIHBhcmEgbyBBdG8gMikiOiAiQ2hhcHRlciA1IG9mIHRoZSBzdG9yeSAodHJh
REM bnNpdGlvbiB0byBBY3QgMikiLAogICAgICAgICJBdG8gMiAtIGluw61jaW8iOiAiQWN0IDIg
REM LSBiZWdpbm5pbmciLCAiQXRvIDIgLSBjb250aW51YcOnw6NvIjogIkFjdCAyIC0gY29udGlu
REM dWF0aW9uIiwKICAgICAgICAiUmVhw6fDtWVzIGRhcyBnYXJvdGFzIGFvcyBwb2VtYXMiOiAi
REM R2lybHMnIHJlYWN0aW9ucyB0byBwb2VtcyIsCiAgICAgICAgIlBvZW1hcyBkbyBqb2dvICh0
REM w610dWxvIGUgY29ycG8gZG8gcG9lbWEpIjogIkdhbWUgcG9lbXMgKHRpdGxlIGFuZCBwb2Vt
REM IGJvZHkpIiwKICAgICAgICAiVGVsYSBkZSBjcsOpZGl0b3MiOiAiQ3JlZGl0cyBzY3JlZW4i
REM LAogICAgICAgICJUZWxhcyBkbyBqb2dvIChtZW51LCBzYWx2YXIsIG9ww6fDtWVzLCBjYWl4
REM YSBkZSB0ZXh0bykiOiAiR2FtZSBzY3JlZW5zIChtZW51LCBzYXZlLCBvcHRpb25zLCB0ZXh0
REM IGJveCkiLAogICAgICAgICJDb25maWd1cmHDp8OjbyBkbyBqb2dvICh0w610dWxvIGRhIGph
REM bmVsYSwgbm9tZSBkbyBtb2QsICdzb2JyZScpIjogIkdhbWUgY29uZmlndXJhdGlvbiAod2lu
REM ZG93IHRpdGxlLCBtb2QgbmFtZSwgJ2Fib3V0JykiLAogICAgICAgICJDb25zb2xlIGRlIGRl
REM c2Vudm9sdmVkb3IgLyBkZXB1cmHDp8OjbyI6ICJEZXZlbG9wZXIgY29uc29sZSAvIGRlYnVn
REM Z2luZyIsCiAgICAgICAgIkRlZmluacOnw7VlcyBkZSBwZXJzb25hZ2Vucywgc3ByaXRlcyBl
REM IHZhcmnDoXZlaXM7IG5vIGZpbmFsIGRvIGFycXVpdm8gZmljYW0gb3Mgbm9tZXMgZXhpYmlk
REM b3MgZGFzIHBlcnNvbmFnZW5zIChTYXlvcmksIFl1cmksIE5hdHN1a2ksIE1vbSwgRGFkLCBE
REM b2N0b3IuLi4pIjogIkNoYXJhY3Rlciwgc3ByaXRlLCBhbmQgdmFyaWFibGUgZGVmaW5pdGlv
REM bnM7IGRpc3BsYXllZCBjaGFyYWN0ZXIgbmFtZXMgYXJlIGF0IHRoZSBlbmQgKFNheW9yaSwg
REM WXVyaSwgTmF0c3VraSwgTW9tLCBEYWQsIERvY3Rvci4uLikiLAogICAgICAgICJFZmVpdG9z
REM IHZpc3VhaXMgKGdsaXRjaCwgZGlzdG9yw6fDo28pIjogIlZpc3VhbCBlZmZlY3RzIChnbGl0
REM Y2gsIGRpc3RvcnRpb24pIiwKICAgICAgICAiR2VyYWRvciBkZSB0ZXh0byBjb3Jyb21waWRv
REM IChjw7NkaWdvKSI6ICJDb3JydXB0ZWQtdGV4dCBnZW5lcmF0b3IgKGNvZGUpIiwKICAgICAg
REM ICAiQW5pbWHDp8O1ZXMgZSBwb3NpY2lvbmFtZW50byBkZSBzcHJpdGVzIjogIlNwcml0ZSBh
REM bmltYXRpb24gYW5kIHBvc2l0aW9uaW5nIiwKICAgICAgICAiQ29uZmlndXJhw6fDo28gYsOh
REM c2ljYSBkbyB0ZW1wbGF0ZS9tb2QiOiAiQmFzaWMgdGVtcGxhdGUvbW9kIGNvbmZpZ3VyYXRp
REM b24iLAogICAgICAgICJFc3RydXR1cmEvcm90ZWFtZW50byBiw6FzaWNvIGRvIHByb2pldG8i
REM OiAiUHJvamVjdCBzdHJ1Y3R1cmUvcm91dGluZyIsCiAgICAgICAgIkRlZmluacOnw7VlcyBk
REM ZSBwZXJzb25hZ2Vucy9yZWN1cnNvczsgaW5jbHVpIG9zIG5vbWVzIGV4aWJpZG9zIGRhcyBw
REM ZXJzb25hZ2VucyI6ICJDaGFyYWN0ZXIvcmVzb3VyY2UgZGVmaW5pdGlvbnM7IGluY2x1ZGVz
REM IGRpc3BsYXllZCBjaGFyYWN0ZXIgbmFtZXMiLAogICAgICAgICJHZXJhw6fDo28vbWFuaXB1
REM bGHDp8OjbyBkZSB0ZXh0byBnbGl0Y2giOiAiR2xpdGNoLXRleHQgZ2VuZXJhdGlvbi9tYW5p
REM cHVsYXRpb24iLAogICAgICAgICJDb25maWd1cmHDp8OjbyB2aXN1YWwiOiAiVmlzdWFsIGNv
REM bmZpZ3VyYXRpb24iLAogICAgICAgICJUcmFuc2Zvcm1hw6fDtWVzL3Bvc2ljaW9uYW1lbnRv
REM IjogIlRyYW5zZm9ybXMvcG9zaXRpb25pbmciLAogICAgICAgICJDYXDDrXR1bG8gZGEgaGlz
REM dMOzcmlhIjogIkNoYXB0ZXIgb2YgdGhlIHN0b3J5IiwKICAgIH0sCiAgICAzOiB7CiAgICAg
REM ICAgIlBvbnRvIGRlIGVudHJhZGEsIGluw61jaW8gZG8gam9nbyBlIHJvdGVhbWVudG8gZGUg
REM Y2Fww610dWxvcyI6ICJQdW50byBkZSBlbnRyYWRhLCBpbsOtY2lvIGRlbCBqdWVnbyB5IGVu
REM cnV0YW1pZW50byBkZSBjYXDDrXR1bG9zIiwKICAgICAgICAiVGVsYSBkZSBhYmVydHVyYSwg
REM YXZpc28gZGUgY29udGXDumRvIGUgY2hlY2FnZW5zIGluaWNpYWlzIjogIlBhbnRhbGxhIGRl
REM IGluw61jaW8sIGF2aXNvIGRlIGNvbnRlbmlkbyB5IGNvbXByb2JhY2lvbmVzIGluaWNpYWxl
REM cyIsCiAgICAgICAgIkNhcMOtdHVsbyAwIGRhIGhpc3TDs3JpYSI6ICJDYXDDrXR1bG8gMCBk
REM ZSBsYSBoaXN0b3JpYSIsICJDYXDDrXR1bG8gMSBkYSBoaXN0w7NyaWEiOiAiQ2Fww610dWxv
REM IDEgZGUgbGEgaGlzdG9yaWEiLAogICAgICAgICJDYXDDrXR1bG8gMiBkYSBoaXN0w7NyaWEi
REM OiAiQ2Fww610dWxvIDIgZGUgbGEgaGlzdG9yaWEiLCAiQ2Fww610dWxvIDMgZGEgaGlzdMOz
REM cmlhIjogIkNhcMOtdHVsbyAzIGRlIGxhIGhpc3RvcmlhIiwKICAgICAgICAiQ2Fww610dWxv
REM IDQgZGEgaGlzdMOzcmlhIjogIkNhcMOtdHVsbyA0IGRlIGxhIGhpc3RvcmlhIiwgIkNhcMOt
REM dHVsbyA1IGRhIGhpc3TDs3JpYSAodHJhbnNpw6fDo28gcGFyYSBvIEF0byAyKSI6ICJDYXDD
REM rXR1bG8gNSBkZSBsYSBoaXN0b3JpYSAodHJhbnNpY2nDs24gYWwgQWN0byAyKSIsCiAgICAg
REM ICAgIkF0byAyIC0gaW7DrWNpbyI6ICJBY3RvIDIgLSBpbsOtY2lvIiwgIkF0byAyIC0gY29u
REM dGludWHDp8OjbyI6ICJBY3RvIDIgLSBjb250aW51YWNpw7NuIiwKICAgICAgICAiUmVhw6fD
REM tWVzIGRhcyBnYXJvdGFzIGFvcyBwb2VtYXMiOiAiUmVhY2Npb25lcyBkZSBsYXMgY2hpY2Fz
REM IGEgbG9zIHBvZW1hcyIsCiAgICAgICAgIlBvZW1hcyBkbyBqb2dvICh0w610dWxvIGUgY29y
REM cG8gZG8gcG9lbWEpIjogIlBvZW1hcyBkZWwganVlZ28gKHTDrXR1bG8geSBjdWVycG8gZGVs
REM IHBvZW1hKSIsCiAgICAgICAgIlRlbGEgZGUgY3LDqWRpdG9zIjogIlBhbnRhbGxhIGRlIGNy
REM w6lkaXRvcyIsCiAgICAgICAgIlRlbGFzIGRvIGpvZ28gKG1lbnUsIHNhbHZhciwgb3DDp8O1
REM ZXMsIGNhaXhhIGRlIHRleHRvKSI6ICJQYW50YWxsYXMgZGVsIGp1ZWdvIChtZW7DuiwgZ3Vh
REM cmRhciwgb3BjaW9uZXMsIGN1YWRybyBkZSB0ZXh0bykiLAogICAgICAgICJDb25maWd1cmHD
REM p8OjbyBkbyBqb2dvICh0w610dWxvIGRhIGphbmVsYSwgbm9tZSBkbyBtb2QsICdzb2JyZScp
REM IjogIkNvbmZpZ3VyYWNpw7NuIGRlbCBqdWVnbyAodMOtdHVsbyBkZSBsYSB2ZW50YW5hLCBu
REM b21icmUgZGVsIG1vZCwgJ2FjZXJjYSBkZScpIiwKICAgICAgICAiQ29uc29sZSBkZSBkZXNl
REM bnZvbHZlZG9yIC8gZGVwdXJhw6fDo28iOiAiQ29uc29sYSBkZSBkZXNhcnJvbGxhZG9yIC8g
REM ZGVwdXJhY2nDs24iLAogICAgICAgICJEZWZpbmnDp8O1ZXMgZGUgcGVyc29uYWdlbnMsIHNw
REM cml0ZXMgZSB2YXJpw6F2ZWlzOyBubyBmaW5hbCBkbyBhcnF1aXZvIGZpY2FtIG9zIG5vbWVz
REM IGV4aWJpZG9zIGRhcyBwZXJzb25hZ2VucyAoU2F5b3JpLCBZdXJpLCBOYXRzdWtpLCBNb20s
REM IERhZCwgRG9jdG9yLi4uKSI6ICJEZWZpbmljaW9uZXMgZGUgcGVyc29uYWplcywgc3ByaXRl
REM cyB5IHZhcmlhYmxlczsgYWwgZmluYWwgZXN0w6FuIGxvcyBub21icmVzIG1vc3RyYWRvcyBk
REM ZSBsb3MgcGVyc29uYWplcyAoU2F5b3JpLCBZdXJpLCBOYXRzdWtpLCBNb20sIERhZCwgRG9j
REM dG9yLi4uKSIsCiAgICAgICAgIkVmZWl0b3MgdmlzdWFpcyAoZ2xpdGNoLCBkaXN0b3LDp8Oj
REM bykiOiAiRWZlY3RvcyB2aXN1YWxlcyAoZ2xpdGNoLCBkaXN0b3JzacOzbikiLAogICAgICAg
REM ICJHZXJhZG9yIGRlIHRleHRvIGNvcnJvbXBpZG8gKGPDs2RpZ28pIjogIkdlbmVyYWRvciBk
REM ZSB0ZXh0byBjb3JydXB0byAoY8OzZGlnbykiLAogICAgICAgICJBbmltYcOnw7VlcyBlIHBv
REM c2ljaW9uYW1lbnRvIGRlIHNwcml0ZXMiOiAiQW5pbWFjaW9uZXMgeSBwb3NpY2lvbmFtaWVu
REM dG8gZGUgc3ByaXRlcyIsCiAgICAgICAgIkNvbmZpZ3VyYcOnw6NvIGLDoXNpY2EgZG8gdGVt
REM cGxhdGUvbW9kIjogIkNvbmZpZ3VyYWNpw7NuIGLDoXNpY2EgZGVsIHRlbXBsYXRlL21vZCIs
REM CiAgICAgICAgIkVzdHJ1dHVyYS9yb3RlYW1lbnRvIGLDoXNpY28gZG8gcHJvamV0byI6ICJF
REM c3RydWN0dXJhL2VucnV0YW1pZW50byBiw6FzaWNvIGRlbCBwcm95ZWN0byIsCiAgICAgICAg
REM IkRlZmluacOnw7VlcyBkZSBwZXJzb25hZ2Vucy9yZWN1cnNvczsgaW5jbHVpIG9zIG5vbWVz
REM IGV4aWJpZG9zIGRhcyBwZXJzb25hZ2VucyI6ICJEZWZpbmljaW9uZXMgZGUgcGVyc29uYWpl
REM cy9yZWN1cnNvczsgaW5jbHV5ZSBsb3Mgbm9tYnJlcyBtb3N0cmFkb3MgZGUgbG9zIHBlcnNv
REM bmFqZXMiLAogICAgICAgICJHZXJhw6fDo28vbWFuaXB1bGHDp8OjbyBkZSB0ZXh0byBnbGl0
REM Y2giOiAiR2VuZXJhY2nDs24vbWFuaXB1bGFjacOzbiBkZSB0ZXh0byBnbGl0Y2giLAogICAg
REM ICAgICJDb25maWd1cmHDp8OjbyB2aXN1YWwiOiAiQ29uZmlndXJhY2nDs24gdmlzdWFsIiwK
REM ICAgICAgICAiVHJhbnNmb3JtYcOnw7Vlcy9wb3NpY2lvbmFtZW50byI6ICJUcmFuc2Zvcm1h
REM Y2lvbmVzL3Bvc2ljaW9uYW1pZW50byIsCiAgICAgICAgIkNhcMOtdHVsbyBkYSBoaXN0w7Ny
REM aWEiOiAiQ2Fww610dWxvIGRlIGxhIGhpc3RvcmlhIiwKICAgIH0sCn0KCmRlZiBkZXNjcmlj
REM YW9fYmlibGlvdGVjYShpbmZvKToKICAgIGZ1bmNhbyA9IF9UUkFEVUNPRVNfQklCLmdldChJ
REM RElPTUEsIHt9KS5nZXQoaW5mb1siZnVuY2FvIl0sIGluZm9bImZ1bmNhbyJdKQogICAgcmV0
REM dXJuIHUiezB9IC8gezF9Ii5mb3JtYXQoaW5mb1sib3JpZ2VtIl0sIGZ1bmNhbykKCgpDSEFS
REM X0RFRl9MSU5FX1JFID0gcmUuY29tcGlsZShyJ15ccyooPzpkZWZpbmV8ZGVmYXVsdClccyso
REM W1x3Ll0rKVxzKj1ccyooPzooPzpyZW5weVwuKT8pKENoYXJhY3RlcnxEeW5hbWljQ2hhcmFj
REM dGVyKVxzKlwoJykKRE9MTEFSX0FTU0lHTl9SRSA9IHJlLmNvbXBpbGUocideXCRccyooW1x3
REM Ll0rKVxzKj1ccyooJyArIFFTVFIgKyByJylccyokJykKSURFTlQgPSByZS5jb21waWxlKHIn
REM XltBLVphLXpfXVtBLVphLXowLTlfLl0qJCcpCgojIERlZmluacOnw7VlcyBkZSBwZXJzb25h
REM Z2VtOiBjb2JyZSBmb3JtYXMgZGUgdW1hIGxpbmhhIGUgbXVsdGlsaW5oYS4KQ0hBUl9ERUZf
REM U1RBUlRfUkUgPSByZS5jb21waWxlKAogICAgcidcYig/OmRlZmluZXxkZWZhdWx0KVxzKyhb
REM QS1aYS16X11bXHcuXSopXHMqPVxzKig/Oig/OnJlbnB5XC4pPykoQ2hhcmFjdGVyfER5bmFt
REM aWNDaGFyYWN0ZXIpXHMqXCgnCikKCmRlZiBfZmluZF9tYXRjaGluZ19wYXJlbih0ZXh0LCBv
REM cGVuX3Bvcyk6CiAgICAiIiJFbmNvbnRyYSBvICcpJyBjb3JyZXNwb25kZW50ZSwgaWdub3Jh
REM bmRvIHBhcsOqbnRlc2VzIGRlbnRybyBkZSBzdHJpbmdzL2NvbWVudMOhcmlvcy4iIiIKICAg
REM IGRlcHRoID0gMAogICAgcXVvdGUgPSBOb25lCiAgICBlc2MgPSBGYWxzZQogICAgaSA9IG9w
REM ZW5fcG9zCiAgICB3aGlsZSBpIDwgbGVuKHRleHQpOgogICAgICAgIGNoID0gdGV4dFtpXQog
REM ICAgICAgIGlmIHF1b3RlIGlzIG5vdCBOb25lOgogICAgICAgICAgICBpZiBlc2M6CiAgICAg
REM ICAgICAgICAgICBlc2MgPSBGYWxzZQogICAgICAgICAgICBlbGlmIGNoID09ICdcXCc6CiAg
REM ICAgICAgICAgICAgICBlc2MgPSBUcnVlCiAgICAgICAgICAgIGVsaWYgY2ggPT0gcXVvdGU6
REM CiAgICAgICAgICAgICAgICBxdW90ZSA9IE5vbmUKICAgICAgICAgICAgaSArPSAxCiAgICAg
REM ICAgICAgIGNvbnRpbnVlCiAgICAgICAgaWYgY2ggaW4gKCciJywgIiciKToKICAgICAgICAg
REM ICAgcXVvdGUgPSBjaAogICAgICAgICAgICBpICs9IDEKICAgICAgICAgICAgY29udGludWUK
REM ICAgICAgICBpZiBjaCA9PSAnIyc6CiAgICAgICAgICAgICMgQ29tZW50w6FyaW8gYXTDqSBh
REM IHF1ZWJyYSBkZSBsaW5oYS4KICAgICAgICAgICAgbmwgPSB0ZXh0LmZpbmQoJ1xuJywgaSkK
REM ICAgICAgICAgICAgaSA9IGxlbih0ZXh0KSBpZiBubCA8IDAgZWxzZSBubCArIDEKICAgICAg
REM ICAgICAgY29udGludWUKICAgICAgICBpZiBjaCA9PSAnKCc6CiAgICAgICAgICAgIGRlcHRo
REM ICs9IDEKICAgICAgICBlbGlmIGNoID09ICcpJzoKICAgICAgICAgICAgZGVwdGggLT0gMQog
REM ICAgICAgICAgICBpZiBkZXB0aCA9PSAwOgogICAgICAgICAgICAgICAgcmV0dXJuIGkKICAg
REM ICAgICBpICs9IDEKICAgIHJldHVybiAtMQoKCmRlZiBfbGluZV9jb2xfZnJvbV9vZmZzZXQo
REM dGV4dCwgb2Zmc2V0KToKICAgIGxpbmhhID0gdGV4dC5jb3VudCgnXG4nLCAwLCBvZmZzZXQp
REM ICsgMQogICAgaW5pY2lvX2xpbmhhID0gdGV4dC5yZmluZCgnXG4nLCAwLCBvZmZzZXQpCiAg
REM ICBpZiBpbmljaW9fbGluaGEgPCAwOgogICAgICAgIGluaWNpb19saW5oYSA9IDAKICAgIGVs
REM c2U6CiAgICAgICAgaW5pY2lvX2xpbmhhICs9IDEKICAgIHJldHVybiBsaW5oYSwgb2Zmc2V0
REM IC0gaW5pY2lvX2xpbmhhCgoKZGVmIGFuYWxpc2FyX2NvbnN0cnV0b3Jlc19hY2hpZXZlbWVu
REM dHMoY2FtaW5obywgY29udGV1ZG8pOgogICAgIiIiRXh0cmFpIHRleHRvcyB2aXPDrXZlaXMg
REM ZGUgQWNoaWV2ZW1lbnQvQWNoaWV2ZW1lbnRDb3VudC4KCiAgICBPcyBjb25zdHJ1dG9yZXMg
REM bm9ybWFsbWVudGUgZmljYW0gZW0gYmxvY29zIFB5dGhvbiBlIHBvZGVtIG9jdXBhciB2w6Fy
REM aWFzCiAgICBsaW5oYXMuIFJlY3VwZXJhbW9zIHNvbWVudGUgb3MgY2FtcG9zIHNlbWFudGlj
REM YW1lbnRlIHZpc8OtdmVpczogbm9tZSwKICAgIGRlc2NyacOnw6NvIGUgbG9ja2VkX2Rlc2Mu
REM IEEgZm9ybWEgcG9zaWNpb25hbCB1c2Egb3MgZG9pcyBwcmltZWlyb3MKICAgIGFyZ3VtZW50
REM b3Mgc3RyaW5nOyBjYW1wb3Mgbm9tZWFkb3Mgc8OjbyBhY3Jlc2NlbnRhZG9zIHF1YW5kbyBl
REM eGlzdGlyZW0uCiAgICAiIiIKICAgIGVudHJhZGFzID0gW10KICAgIGZvciBtIGluIHJlLmZp
REM bmRpdGVyKHInXGJBY2hpZXZlbWVudCg/OkNvdW50KT9ccypcKCcsIGNvbnRldWRvLCByZS5J
REM KToKICAgICAgICBvcGVuX3BvcyA9IGNvbnRldWRvLmZpbmQoJygnLCBtLnN0YXJ0KCkpCiAg
REM ICAgICAgY2xvc2VfcG9zID0gX2ZpbmRfbWF0Y2hpbmdfcGFyZW4oY29udGV1ZG8sIG9wZW5f
REM cG9zKQogICAgICAgIGlmIG9wZW5fcG9zIDwgMCBvciBjbG9zZV9wb3MgPCAwOgogICAgICAg
REM ICAgICBjb250aW51ZQogICAgICAgIGNoYW1hZGEgPSBjb250ZXVkb1tvcGVuX3BvcyArIDE6
REM Y2xvc2VfcG9zXQoKICAgICAgICBlbmNvbnRyYWRvcyA9IFtdCiAgICAgICAgIyBGb3JtYSBw
REM b3NpY2lvbmFsOiBub21lIGUgZGVzY3Jpw6fDo28gc8OjbyBvcyBkb2lzIHByaW1laXJvcyBs
REM aXRlcmFpcy4KICAgICAgICBwb3Nfc3RyaW5ncyA9IGxpc3QocmUuZmluZGl0ZXIoUVNUUiwg
REM Y2hhbWFkYSkpCiAgICAgICAgaWYgcG9zX3N0cmluZ3M6CiAgICAgICAgICAgIGVuY29udHJh
REM ZG9zLmFwcGVuZCgocG9zX3N0cmluZ3NbMF0uc3RhcnQoKSwgcG9zX3N0cmluZ3NbMF0uZ3Jv
REM dXAoMCksICduYW1lJykpCiAgICAgICAgaWYgbGVuKHBvc19zdHJpbmdzKSA+PSAyOgogICAg
REM ICAgICAgICBlbmNvbnRyYWRvcy5hcHBlbmQoKHBvc19zdHJpbmdzWzFdLnN0YXJ0KCksIHBv
REM c19zdHJpbmdzWzFdLmdyb3VwKDApLCAnZGVzY3JpcHRpb24nKSkKCiAgICAgICAgIyBGb3Jt
REM YSBub21lYWRhOiBhY3Jlc2NlbnRhL3N1YnN0aXR1aSBjYW1wb3Mgc2VtYW50aWNhbWVudGUg
REM ZXhwbMOtY2l0b3MuCiAgICAgICAgZm9yIGNhbXBvIGluICgnbmFtZScsICdkZXNjcmlwdGlv
REM bicsICdsb2NrZWRfZGVzYycpOgogICAgICAgICAgICBmb3IgbW4gaW4gcmUuZmluZGl0ZXIo
REM cidcYicgKyByZS5lc2NhcGUoY2FtcG8pICsgcidccyo9XHMqKCcgKyBRU1RSICsgcicpJywg
REM Y2hhbWFkYSwgcmUuSSk6CiAgICAgICAgICAgICAgICBlbmNvbnRyYWRvcy5hcHBlbmQoKG1u
REM LnN0YXJ0KDEpLCBtbi5ncm91cCgxKSwgY2FtcG8pKQoKICAgICAgICB2aXN0b3Nfc3BhbiA9
REM IHNldCgpCiAgICAgICAgZm9yIHBvcywgcSwgY2FtcG8gaW4gc29ydGVkKGVuY29udHJhZG9z
REM LCBrZXk9bGFtYmRhIHg6IHhbMF0pOgogICAgICAgICAgICBjaGF2ZSA9IChwb3MsIHEpCiAg
REM ICAgICAgICAgIGlmIGNoYXZlIGluIHZpc3Rvc19zcGFuOgogICAgICAgICAgICAgICAgY29u
REM dGludWUKICAgICAgICAgICAgdmlzdG9zX3NwYW4uYWRkKGNoYXZlKQogICAgICAgICAgICBp
REM bnRlcmlvciA9IHN0cmlwX3F1b3RlcyhxKS5zdHJpcCgpCiAgICAgICAgICAgIGlmIG5vdCBp
REM bnRlcmlvciBvciBpbnRlcmlvciA9PSAnPz8/JyBvciBub3QgdGVtX2NvbnRldWRvX3RyYWR1
REM eml2ZWwocSk6CiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICBhYnNvbHV0
REM byA9IG9wZW5fcG9zICsgMSArIHBvcwogICAgICAgICAgICBsaW5oYSwgY29sdW5hID0gX2xp
REM bmVfY29sX2Zyb21fb2Zmc2V0KGNvbnRldWRvLCBhYnNvbHV0bykKICAgICAgICAgICAgZW50
REM cmFkYXMuYXBwZW5kKHsKICAgICAgICAgICAgICAgICdsaW5oYSc6IGxpbmhhLAogICAgICAg
REM ICAgICAgICAgJ2NvbHVuYV9pbmljaW8nOiBjb2x1bmEsCiAgICAgICAgICAgICAgICAnY29s
REM dW5hX2ZpbSc6IGNvbHVuYSArIGxlbihxKSwKICAgICAgICAgICAgICAgICdvcmlnaW5hbCc6
REM IHEsCiAgICAgICAgICAgICAgICAndGlwbyc6ICd1aScsCiAgICAgICAgICAgICAgICAnY29u
REM ZmlhbmNhJzogMTAwLAogICAgICAgICAgICAgICAgJ2NvbnRleHRvJzogJ3RleHRvIHZpc8Ot
REM dmVsIGRlIEFjaGlldmVtZW50OiAnICsgY2FtcG8sCiAgICAgICAgICAgIH0pCiAgICByZXR1
REM cm4gZW50cmFkYXMKCgpkZWYgYW5hbGlzYXJfZGVmaW5pY29lc19wZXJzb25hZ2VucyhjYW1p
REM bmhvLCBjb250ZXVkbyk6CiAgICAiIiJSZXRvcm5hIGVudHJhZGFzIGRlIG5vbWUvZHluYW1p
REM Yy1uYW1lIGVtIENoYXJhY3Rlci9EeW5hbWljQ2hhcmFjdGVyLCBpbmNsdXNpdmUgbXVsdGls
REM aW5oYS4iIiIKICAgIGVudHJhZGFzID0gW10KICAgIGR5bmFtaWNfdmFycyA9IHNldCgpCiAg
REM ICBmb3IgbSBpbiBDSEFSX0RFRl9TVEFSVF9SRS5maW5kaXRlcihjb250ZXVkbyk6CiAgICAg
REM ICAgdmFyX25hbWUgPSBtLmdyb3VwKDEpCiAgICAgICAga2luZCA9IG0uZ3JvdXAoMikKICAg
REM ICAgICBvcGVuX3BvcyA9IGNvbnRldWRvLmZpbmQoJygnLCBtLnN0YXJ0KCkpCiAgICAgICAg
REM aWYgb3Blbl9wb3MgPCAwOgogICAgICAgICAgICBjb250aW51ZQogICAgICAgIGNsb3NlX3Bv
REM cyA9IF9maW5kX21hdGNoaW5nX3BhcmVuKGNvbnRldWRvLCBvcGVuX3BvcykKICAgICAgICBp
REM ZiBjbG9zZV9wb3MgPCAwOgogICAgICAgICAgICAjIE7Do28gZGVzY2FydGFyIGEgZGVmaW5p
REM w6fDo286IGFpbmRhIHRlbnRhcmVtb3MgYSBsaW5oYSBhdHVhbC4KICAgICAgICAgICAgY2xv
REM c2VfcG9zID0gbWluKGxlbihjb250ZXVkbyksIG0uZW5kKCkgKyA0MDAwKQogICAgICAgIGNo
REM YW1hZGEgPSBjb250ZXVkb1tvcGVuX3BvcyArIDE6Y2xvc2VfcG9zXQoKICAgICAgICAjIG5h
REM bWU9Ii4uLiIgLyBuYW1lPScuLi4nCiAgICAgICAgbV9uYW1lID0gcmUuc2VhcmNoKHInXGJu
REM YW1lXHMqPVxzKignICsgUVNUUiArIHInKScsIGNoYW1hZGEpCiAgICAgICAgaWYgbV9uYW1l
REM OgogICAgICAgICAgICBxID0gbV9uYW1lLmdyb3VwKDEpCiAgICAgICAgICAgIGFic29sdXRv
REM ID0gb3Blbl9wb3MgKyAxICsgbV9uYW1lLnN0YXJ0KDEpCiAgICAgICAgICAgIGludGVyaW9y
REM ID0gc3RyaXBfcXVvdGVzKHEpCiAgICAgICAgICAgIGR5bmFtaWMgPSBib29sKGtpbmQgPT0g
REM J0R5bmFtaWNDaGFyYWN0ZXInIG9yIHJlLnNlYXJjaChyJ1xiZHluYW1pY1xzKj1ccypUcnVl
REM XGInLCBjaGFtYWRhLCByZS5JKSkKICAgICAgICAgICAgaWYgZHluYW1pYyBhbmQgSURFTlQu
REM bWF0Y2goaW50ZXJpb3IpOgogICAgICAgICAgICAgICAgZHluYW1pY192YXJzLmFkZChpbnRl
REM cmlvcikKICAgICAgICAgICAgZWxpZiBub3QgcGFyZWNlX3RleHRvX3RlY25pY28ocSk6CiAg
REM ICAgICAgICAgICAgICBsaW5oYSwgY29sdW5hID0gX2xpbmVfY29sX2Zyb21fb2Zmc2V0KGNv
REM bnRldWRvLCBhYnNvbHV0bykKICAgICAgICAgICAgICAgIGVudHJhZGFzLmFwcGVuZCh7CiAg
REM ICAgICAgICAgICAgICAgICAgJ2xpbmhhJzogbGluaGEsICdjb2x1bmFfaW5pY2lvJzogY29s
REM dW5hLCAnY29sdW5hX2ZpbSc6IGNvbHVuYSArIGxlbihxKSwKICAgICAgICAgICAgICAgICAg
REM ICAnb3JpZ2luYWwnOiBxLCAndGlwbyc6ICdub21lX3BlcnNvbmFnZW0nLCAnY29uZmlhbmNh
REM JzogMTAwLAogICAgICAgICAgICAgICAgICAgICdjb250ZXh0byc6ICdkZWZpbmnDp8OjbyBk
REM ZSBwZXJzb25hZ2VtOiAnICsgdmFyX25hbWUsCiAgICAgICAgICAgICAgICB9KQogICAgICAg
REM IGVsc2U6CiAgICAgICAgICAgICMgUHJpbWVpcm8gYXJndW1lbnRvIHBvc2ljaW9uYWwuCiAg
REM ICAgICAgICAgIG1fZmlyc3QgPSByZS5tYXRjaChyJ1xzKignICsgUVNUUiArIHInKScsIGNo
REM YW1hZGEpCiAgICAgICAgICAgIGlmIG1fZmlyc3Q6CiAgICAgICAgICAgICAgICBxID0gbV9m
REM aXJzdC5ncm91cCgxKQogICAgICAgICAgICAgICAgYWJzb2x1dG8gPSBvcGVuX3BvcyArIDEg
REM KyBtX2ZpcnN0LnN0YXJ0KDEpCiAgICAgICAgICAgICAgICBpbnRlcmlvciA9IHN0cmlwX3F1
REM b3RlcyhxKQogICAgICAgICAgICAgICAgZHluYW1pYyA9IGJvb2woa2luZCA9PSAnRHluYW1p
REM Y0NoYXJhY3Rlcicgb3IgcmUuc2VhcmNoKHInXGJkeW5hbWljXHMqPVxzKlRydWVcYicsIGNo
REM YW1hZGEsIHJlLkkpKQogICAgICAgICAgICAgICAgaWYgZHluYW1pYyBhbmQgSURFTlQubWF0
REM Y2goaW50ZXJpb3IpOgogICAgICAgICAgICAgICAgICAgIGR5bmFtaWNfdmFycy5hZGQoaW50
REM ZXJpb3IpCiAgICAgICAgICAgICAgICBlbGlmIG5vdCBwYXJlY2VfdGV4dG9fdGVjbmljbyhx
REM KToKICAgICAgICAgICAgICAgICAgICBsaW5oYSwgY29sdW5hID0gX2xpbmVfY29sX2Zyb21f
REM b2Zmc2V0KGNvbnRldWRvLCBhYnNvbHV0bykKICAgICAgICAgICAgICAgICAgICBlbnRyYWRh
REM cy5hcHBlbmQoewogICAgICAgICAgICAgICAgICAgICAgICAnbGluaGEnOiBsaW5oYSwgJ2Nv
REM bHVuYV9pbmljaW8nOiBjb2x1bmEsICdjb2x1bmFfZmltJzogY29sdW5hICsgbGVuKHEpLAog
REM ICAgICAgICAgICAgICAgICAgICAgICAnb3JpZ2luYWwnOiBxLCAndGlwbyc6ICdub21lX3Bl
REM cnNvbmFnZW0nLCAnY29uZmlhbmNhJzogMTAwLAogICAgICAgICAgICAgICAgICAgICAgICAn
REM Y29udGV4dG8nOiAnZGVmaW5pw6fDo28gZGUgcGVyc29uYWdlbTogJyArIHZhcl9uYW1lLAog
REM ICAgICAgICAgICAgICAgICAgIH0pCiAgICByZXR1cm4gZW50cmFkYXMsIGR5bmFtaWNfdmFy
REM cwoKCgpkZWYgYW5hbGlzYXJfZGVmaW5pY29lc19waG9uZShjYW1pbmhvLCBjb250ZXVkbyk6
REM CiAgICAiIiJFeHRyYWkgbm9tZXMgdmlzw612ZWlzIGRvcyBvYmpldG9zIHBob25lLmNoYXJh
REM Y3Rlci5DaGFyYWN0ZXIgZW0gMDFkZWZpbml0aW9ucy5ycHkuCgogICAgRXN0YSByZWdyYSDD
REM qSBleGNsdXNpdmEgZG8gYXJxdWl2byBwaG9uZS9kZWZpbml0aW9ucy8wMWRlZmluaXRpb25z
REM LnJweSBlIG7Do28KICAgIGRlZHVwbGljYSBuYWRhIHBvciB0ZXh0bzogY2FkYSBvY29ycsOq
REM bmNpYSBwb3NzdWkgc3VhIHByw7NwcmlhIHBvc2nDp8OjbyBubyBtYXBhLgogICAgQXNzaW0s
REM IHNlIG91dHJvIGFycXVpdm8gdGFtYsOpbSBwb3NzdWlyIGEgbWVzbWEgZGVmaW5pw6fDo28v
REM bm9tZSwgb3MgZG9pcwogICAgYXJxdWl2b3MgY29udGludWFtIHRlbmRvIHN1YXMgcHLDs3By
REM aWFzIGVudHJhZGFzIG5hIGV4dHJhw6fDo28uCiAgICAiIiIKICAgIGNhbWluaG9fbm9ybSA9
REM IGNhbWluaG8ucmVwbGFjZSgiXFwiLCAiLyIpLmxvd2VyKCkKICAgIGlmIG5vdCBjYW1pbmhv
REM X25vcm0uZW5kc3dpdGgoInBob25lL2RlZmluaXRpb25zLzAxZGVmaW5pdGlvbnMucnB5Iik6
REM CiAgICAgICAgcmV0dXJuIFtdCgogICAgZW50cmFkYXMgPSBbXQoKICAgICMgIldlbGNvbWUi
REM IGUgbyBub21lIGRvIGdydXBvIHBhZHJhbyBleGliaWRvIHBlbGEgaW50ZXJmYWNlIGRvIHRl
REM bGVmb25lLgogICAgIyBOYW8gZSB1bWEgZmFsYTsgcmVjZWJlIHVtYSBjYXRlZ29yaWEgcHJv
REM cHJpYSBlIG1hbnRlbSBzdWEgcG9zaWNhbyByZWFsLgogICAgZm9yIG1fZ3JvdXAgaW4gcmUu
REM ZmluZGl0ZXIocidcYmRlZmluZVxzKygnICsgUVNUUiArIHInKVxzKjonLCBjb250ZXVkbywg
REM cmUuSSk6CiAgICAgICAgcV9ncm91cCA9IG1fZ3JvdXAuZ3JvdXAoMSkKICAgICAgICBpZiBz
REM dHJpcF9xdW90ZXMocV9ncm91cCkgIT0gJ1dlbGNvbWUnOgogICAgICAgICAgICBjb250aW51
REM ZQogICAgICAgIGFic29sdXRvID0gbV9ncm91cC5zdGFydCgxKQogICAgICAgIGxpbmhhLCBj
REM b2x1bmEgPSBfbGluZV9jb2xfZnJvbV9vZmZzZXQoY29udGV1ZG8sIGFic29sdXRvKQogICAg
REM ICAgIGVudHJhZGFzLmFwcGVuZCh7CiAgICAgICAgICAgICdsaW5oYSc6IGxpbmhhLAogICAg
REM ICAgICAgICAnY29sdW5hX2luaWNpbyc6IGNvbHVuYSwKICAgICAgICAgICAgJ2NvbHVuYV9m
REM aW0nOiBjb2x1bmEgKyBsZW4ocV9ncm91cCksCiAgICAgICAgICAgICdvcmlnaW5hbCc6IHFf
REM Z3JvdXAsCiAgICAgICAgICAgICd0aXBvJzogJ25vbWVfZ3J1cG8nLAogICAgICAgICAgICAn
REM Y29uZmlhbmNhJzogMTAwLAogICAgICAgICAgICAnY29udGV4dG8nOiAnbm9tZSBkbyBncnVw
REM byBkZSB0ZWxlZm9uZScsCiAgICAgICAgfSkKCiAgICBmb3IgbSBpbiByZS5maW5kaXRlcihy
REM J1xicGhvbmVcLmNoYXJhY3RlclwuQ2hhcmFjdGVyXHMqXCgnLCBjb250ZXVkbywgcmUuSSk6
REM CiAgICAgICAgb3Blbl9wb3MgPSBjb250ZXVkby5maW5kKCcoJywgbS5zdGFydCgpKQogICAg
REM ICAgIGlmIG9wZW5fcG9zIDwgMDoKICAgICAgICAgICAgY29udGludWUKICAgICAgICBjbG9z
REM ZV9wb3MgPSBfZmluZF9tYXRjaGluZ19wYXJlbihjb250ZXVkbywgb3Blbl9wb3MpCiAgICAg
REM ICAgaWYgY2xvc2VfcG9zIDwgMDoKICAgICAgICAgICAgY2xvc2VfcG9zID0gbWluKGxlbihj
REM b250ZXVkbyksIG9wZW5fcG9zICsgNDAwMCkKICAgICAgICBjaGFtYWRhID0gY29udGV1ZG9b
REM b3Blbl9wb3MgKyAxOmNsb3NlX3Bvc10KCiAgICAgICAgIyBQcmlvcmlkYWRlIHBhcmEgbmFt
REM ZT0iLi4uIiBxdWFuZG8gYSBjaGFtYWRhIHVzYSBhcmd1bWVudG8gbm9tZWFkby4KICAgICAg
REM ICBtX25hbWUgPSByZS5zZWFyY2gocidcYm5hbWVccyo9XHMqKCcgKyBRU1RSICsgcicpJywg
REM Y2hhbWFkYSkKICAgICAgICBpZiBtX25hbWU6CiAgICAgICAgICAgIHEgPSBtX25hbWUuZ3Jv
REM dXAoMSkKICAgICAgICAgICAgYWJzb2x1dG8gPSBvcGVuX3BvcyArIDEgKyBtX25hbWUuc3Rh
REM cnQoMSkKICAgICAgICBlbHNlOgogICAgICAgICAgICAjIEZvcm1hIG5vcm1hbCBkbyBzaXN0
REM ZW1hIGRvIHRlbGVmb25lOiBDaGFyYWN0ZXIoIk5vbWUiLCAuLi4pCiAgICAgICAgICAgIG1f
REM Zmlyc3QgPSByZS5tYXRjaChyJ1xzKignICsgUVNUUiArIHInKScsIGNoYW1hZGEpCiAgICAg
REM ICAgICAgIGlmIG5vdCBtX2ZpcnN0OgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAg
REM ICAgICAgcSA9IG1fZmlyc3QuZ3JvdXAoMSkKICAgICAgICAgICAgYWJzb2x1dG8gPSBvcGVu
REM X3BvcyArIDEgKyBtX2ZpcnN0LnN0YXJ0KDEpCgogICAgICAgIGlmIHBhcmVjZV90ZXh0b190
REM ZWNuaWNvKHEpOgogICAgICAgICAgICBjb250aW51ZQogICAgICAgIGxpbmhhLCBjb2x1bmEg
REM PSBfbGluZV9jb2xfZnJvbV9vZmZzZXQoY29udGV1ZG8sIGFic29sdXRvKQogICAgICAgIGVu
REM dHJhZGFzLmFwcGVuZCh7CiAgICAgICAgICAgICdsaW5oYSc6IGxpbmhhLAogICAgICAgICAg
REM ICAnY29sdW5hX2luaWNpbyc6IGNvbHVuYSwKICAgICAgICAgICAgJ2NvbHVuYV9maW0nOiBj
REM b2x1bmEgKyBsZW4ocSksCiAgICAgICAgICAgICdvcmlnaW5hbCc6IHEsCiAgICAgICAgICAg
REM ICd0aXBvJzogJ25vbWVfcGVyc29uYWdlbScsCiAgICAgICAgICAgICdjb25maWFuY2EnOiAx
REM MDAsCiAgICAgICAgICAgICdjb250ZXh0byc6ICdub21lIGRlIHBlcnNvbmFnZW0gZG8gdGVs
REM ZWZvbmUnLAogICAgICAgIH0pCiAgICByZXR1cm4gZW50cmFkYXMKCmRlZiBjb2xldGFyX3Zh
REM cmlhdmVpc19ub21lX2RpbmFtaWNvKGNhbmRpZGF0b3MpOgogICAgdmFyaWF2ZWlzID0gc2V0
REM KCkKICAgIGZvciBjYW1pbmhvIGluIGNhbmRpZGF0b3M6CiAgICAgICAgdHJ5OgogICAgICAg
REM ICAgICB3aXRoIGlvLm9wZW4oY2FtaW5obywgJ3InLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJv
REM cnM9J3JlcGxhY2UnLCBuZXdsaW5lPScnKSBhcyBmOgogICAgICAgICAgICAgICAgY29udGV1
REM ZG8gPSBmLnJlYWQoKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIGNv
REM bnRpbnVlCiAgICAgICAgXywgZGVzY29iZXJ0YXMgPSBhbmFsaXNhcl9kZWZpbmljb2VzX3Bl
REM cnNvbmFnZW5zKGNhbWluaG8sIGNvbnRldWRvKQogICAgICAgIHZhcmlhdmVpcy51cGRhdGUo
REM ZGVzY29iZXJ0YXMpCiAgICAgICAgIyBNYW50ZW0gY29tcGF0aWJpbGlkYWRlIGNvbSBhIGRl
REM dGVjY2FvIHNpbXBsZXMgZXhpc3RlbnRlLgogICAgICAgIGZvciBtIGluIHJlLmZpbmRpdGVy
REM KHInRHluYW1pY0NoYXJhY3RlclxzKlwoXHMqKD86bmFtZVxzKj1ccyopPygnICsgUVNUUiAr
REM IHInKScsIGNvbnRldWRvKToKICAgICAgICAgICAgdmFsb3IgPSBzdHJpcF9xdW90ZXMobS5n
REM cm91cCgxKSkKICAgICAgICAgICAgaWYgSURFTlQubWF0Y2godmFsb3IpOgogICAgICAgICAg
REM ICAgICAgdmFyaWF2ZWlzLmFkZCh2YWxvcikKICAgIHJldHVybiB2YXJpYXZlaXMKU1RSSU5H
REM X0RFRkFVTFRfUkUgPSByZS5jb21waWxlKHInXlxzKig/OmRlZmluZXxkZWZhdWx0KVxzKyhb
REM XHcuXSspXHMqPVxzKignICsgUVNUUiArIHInKVxzKiQnKQojIERlZmluacOnw6NvIGRvIG5v
REM bWUgZG8gam9nbzogbnVuY2EgZGV2ZSBlbnRyYXIgbmEgdHJhZHXDp8Ojby4gTWFudGVtb3Mg
REM byByZXN0YW50ZQojIGRlIG9wdGlvbnMucnB5IG5vcm1hbG1lbnRlIHByb2Nlc3PDoXZlbDsg
REM c29tZW50ZSBhIGxpbmhhIGBkZWZpbmUgY29uZmlnLm5hbWUgPSAuLi5gCiMgw6kgaWdub3Jh
REM ZGEuCkNPTkZJR19OQU1FX0RFRklORV9SRSA9IHJlLmNvbXBpbGUocideXHMqZGVmaW5lXHMr
REM Y29uZmlnXC5uYW1lXHMqPScpClBVUkVfVklTSUJMRV9VUkxfUkUgPSByZS5jb21waWxlKHIn
REM Xig/Omh0dHBzP3xmdHApOi8vXFMrJCcsIHJlLkkpCmRlZiBzdHJpcF9xdW90ZXMocyk6CiAg
REM ICBzID0gcy5zdHJpcCgpCiAgICAjIFJlblwnUHkgdGFtYsOpbSBhY2VpdGEgbyBwcmVmaXhv
REM IHIgZW0gc3RyaW5ncyBkaXJldGFzIGUgdXNhIGJhY2t0aWNrCiAgICAjIGNvbW8gZGVsaW1p
REM dGFkb3IgYWx0ZXJuYXRpdm8uIE1hbnRlbW9zIG8gcHJlZml4byBmb3JhIGRvIGNvbnRlw7pk
REM by4KICAgIGlmIGxlbihzKSA+PSAzIGFuZCBzWzBdIGluICdyUicgYW5kIHNbMV0gaW4gKCci
REM JywgIiciLCAnYCcpIGFuZCBzWy0xXSA9PSBzWzFdOgogICAgICAgIHMgPSBzWzE6XQogICAg
REM aWYgbGVuKHMpID49IDIgYW5kICgoc1swXSA9PSAnIicgYW5kIHNbLTFdID09ICciJykgb3Ig
REM KHNbMF0gPT0gIiciIGFuZCBzWy0xXSA9PSAiJyIpIG9yIChzWzBdID09ICdgJyBhbmQgc1st
REM MV0gPT0gJ2AnKSk6CiAgICAgICAgcmV0dXJuIHNbMTotMV0KICAgIHJldHVybiBzCgpkZWYg
REM aXRlcl9yZW5weV9saXRlcmFpc19lc3BlY2lhaXMobGluaGEpOgogICAgIiIiSXRlcmEgc3Ry
REM aW5ncyBkZSB1bWEgbGluaGEgcXVlIG8gUVNUUiBsZWdhZG8gbsOjbyBjb2JyZTogclwiLi4u
REM XCIgZSBgLi4uYC4KCiAgICBSZXRvcm5hIChpbmljaW9fbGl0ZXJhbCwgZmltX2xpdGVyYWws
REM IGxpdGVyYWwsIGVoX3JhdykuIE8gcHJlZml4byBgcmAgZmljYQogICAgZGVsaWJlcmFkYW1l
REM bnRlIGZvcmEgZG8gc3BhbiBwYXJhIHF1ZSBhIHJlaW5qZcOnw6NvIHByZXNlcnZlIGEgc2lu
REM dGF4ZSBvcmlnaW5hbC4KICAgIFN0cmluZ3MgdHJpcGxhcyBzw6NvIHRyYXRhZGFzIHBlbG9z
REM IGV4dHJhdG9yZXMgbXVsdGlsaW5oYS9tb27Ds2xvZ28uCiAgICAiIiIKICAgIG4gPSBsZW4o
REM bGluaGEpCiAgICBpID0gMAogICAgd2hpbGUgaSA8IG46CiAgICAgICAgaW5pY2lvID0gaQog
REM ICAgICAgIHJhdyA9IEZhbHNlCiAgICAgICAgaWYgbGluaGFbaV0gaW4gJ3JSJyBhbmQgaSAr
REM IDEgPCBuIGFuZCBsaW5oYVtpICsgMV0gaW4gKCciJywgIiciLCAnYCcpIGFuZCAoaSA9PSAw
REM IG9yIG5vdCAobGluaGFbaSAtIDFdLmlzYWxudW0oKSBvciBsaW5oYVtpIC0gMV0gPT0gJ18n
REM KSk6CiAgICAgICAgICAgIHJhdyA9IFRydWUKICAgICAgICAgICAgaSArPSAxCiAgICAgICAg
REM aWYgaSA+PSBuIG9yIGxpbmhhW2ldIG5vdCBpbiAoJyInLCAiJyIsICdgJyk6CiAgICAgICAg
REM ICAgIGkgPSBpbmljaW8gKyAxCiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgcXVvdGUg
REM PSBsaW5oYVtpXQogICAgICAgICMgTyBzY2FubmVyIGVzcGVjaWFsIHPDsyBkZXZlIHJlY3Vw
REM ZXJhciBhcyBmb3JtYXMgcXVlIG8gUVNUUiBsZWdhZG8gbsOjbwogICAgICAgICMgY29icmU6
REM IGJhY2t0aWNrIGUgcHJlZml4byByLiBTdHJpbmdzIG5vcm1haXMgZmljYW0gc29iIG8gcGFy
REM c2VyIHByaW5jaXBhbAogICAgICAgICMgcGFyYSBuw6NvIHJlYWJyaXIgZmFsc29zIHBvc2l0
REM aXZvcyBlbSBjYW1pbmhvcy9hdHJpYnVpw6fDtWVzIHTDqWNuaWNhcy4KICAgICAgICBpZiBu
REM b3QgcmF3IGFuZCBxdW90ZSAhPSAnYCc6CiAgICAgICAgICAgIGkgPSBpbmljaW8gKyAxCiAg
REM ICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgIyBUcmlwbGUgcXVvdGU6IGRlaXhhciBvcyBl
REM eHRyYXRvcmVzIGRlZGljYWRvcyB0cmF0YXJlbSBpc3NvLgogICAgICAgIGlmIGxpbmhhLnN0
REM YXJ0c3dpdGgocXVvdGUgKiAzLCBpKToKICAgICAgICAgICAgaSArPSAzCiAgICAgICAgICAg
REM IGNvbnRpbnVlCiAgICAgICAgcXBvcyA9IGkKICAgICAgICBqID0gaSArIDEKICAgICAgICB3
REM aGlsZSBqIDwgbjoKICAgICAgICAgICAgaWYgbGluaGFbal0gPT0gJ1xcJzoKICAgICAgICAg
REM ICAgICAgIGogKz0gMgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgaWYg
REM bGluaGFbal0gPT0gcXVvdGU6CiAgICAgICAgICAgICAgICB5aWVsZCAocXBvcywgaiArIDEs
REM IGxpbmhhW3Fwb3M6aiArIDFdLCByYXcpCiAgICAgICAgICAgICAgICBpID0gaiArIDEKICAg
REM ICAgICAgICAgICAgIGJyZWFrCiAgICAgICAgICAgIGogKz0gMQogICAgICAgIGVsc2U6CiAg
REM ICAgICAgICAgIGkgPSBpbmljaW8gKyAxCmRlZiBwYXJlY2VyX3NlbV90ZWNuaWNvKHYpOgog
REM ICAgeCA9IHN0cmlwX3F1b3Rlcyh2KQogICAgcmV0dXJuIGJvb2woeCkgYW5kIG5vdCByZS5t
REM YXRjaChyJ14jWzAtOWEtZkEtRl17Myw4fSQnLCB4KSBhbmQgbm90IHJlLm1hdGNoKHInXig/
REM Omh0dHBzP3xmdHApOi8vJywgeCwgcmUuSSkKZGVmIHBhcmVjZV90ZXh0b190ZWNuaWNvKHZh
REM bG9yX2NvbV9hc3BhcywgdmFyX25vbWU9IiIsIGluZGljZV9hcnF1aXZvcz1Ob25lKToKICAg
REM IGludGVyaW9yID0gc3RyaXBfcXVvdGVzKHZhbG9yX2NvbV9hc3Bhcykuc3RyaXAoKQogICAg
REM aWYgbm90IGludGVyaW9yOgogICAgICAgIHJldHVybiBUcnVlCgogICAgIyBFeGNlw6fDtWVz
REM OiBhbGd1bWFzIHZhcmnDoXZlaXMgc8OjbyBmZWl0YXMgcGFyYSBhcGFyZWNlciBkaXJldGFt
REM ZW50ZSBuYSBVSS4KICAgICMgY29uZmlnLnZlcnNpb24gw6kgbWV0YWRhZG8gZG8gcHJvamV0
REM bywgbsOjbyB0ZXh0byBkZSBnYW1lcGxheS4KICAgIGlmIHZhcl9ub21lIGluICgiY29uZmln
REM Lm5hbWUiLCAiZ3VpLmFib3V0Iik6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBpZiB2YXJf
REM bm9tZSA9PSAiY29uZmlnLnZlcnNpb24iOgogICAgICAgIHJldHVybiBUcnVlCgogICAgIyBO
REM b21lcyBkZSB2YXJpw6F2ZWlzIHF1ZSByZXByZXNlbnRhbSByZWN1cnNvcywgYnVpbGQgb3Ug
REM Y29uZmlndXJhw6fDo28gdMOpY25pY2EuCiAgICBpZiAocmUubWF0Y2gocideYnVpbGRcLics
REM IHZhcl9ub21lLCByZS5JKSBvcgogICAgICAgICAgICByZS5tYXRjaChyJ14oPzpjb25maWd8
REM cHJlZmVyZW5jZXN8cGVyc2lzdGVudHxndWkpXC4nLCB2YXJfbm9tZSwgcmUuSSkgb3IKICAg
REM ICAgICAgICAgcmUubWF0Y2gocideKD86YXVkaW98bXVzaWN8c291bmR8c2Z4fGFtYmllbmNl
REM fGltYWdlKVwuJywgdmFyX25vbWUsIHJlLkkpKToKICAgICAgICByZXR1cm4gVHJ1ZQoKICAg
REM IGlmIHJlLm1hdGNoKHInXiNbMC05YS1mQS1GXXszLDh9JCcsIGludGVyaW9yKToKICAgICAg
REM ICByZXR1cm4gVHJ1ZQogICAgIyBVUkwgcHVyYSBwb2RlIHNlciB0cmF0YWRhIGNvbW8gdGVj
REM bmljYSBxdWFuZG8gbyBjb250ZXh0byBuYW8gYSBtYXJjb3UgY29tbyB2aXNpdmVsLgogICAg
REM IyBVUkwgZGVudHJvIGRlIHVtYSBmcmFzZSBjb250aW51YSBzZW5kbyB0ZXh0byBsZWdpdmVs
REM IGUgc2VyYSBwcmVzZXJ2YWRhIHBvciB0b2tlbnMgbm8gR29vZ2xlLgogICAgaWYgUFVSRV9W
REM SVNJQkxFX1VSTF9SRS5tYXRjaChpbnRlcmlvcik6CiAgICAgICAgcmV0dXJuIFRydWUKICAg
REM ICMgQ29tYW5kb3MgZGUgc2hlbGwgZSBzdHJpbmdzIGZlaXRhcyBzw7MgZGUgcG9udHVhw6fD
REM o28gZGUgY8OzZGlnbyAoZXguOiB1bSBhcMOzc3Ryb2ZvKS4KICAgIGlmIHJlLm1hdGNoKHIn
REM Xig/OnBvd2Vyc2hlbGwoPzpcLmV4ZSk/fHB3c2h8d21pY3xjbWQoPzpcLmV4ZSk/XHMrL1th
REM LXpdKVxiJywgaW50ZXJpb3IsIHJlLkkpOgogICAgICAgIHJldHVybiBUcnVlCiAgICBpZiBy
REM ZS5tYXRjaChyJ15bXHNcJyJgXFwvfCw7Oj0rKClcW1xde308PkAkJV4mX10rJCcsIGludGVy
REM aW9yKToKICAgICAgICByZXR1cm4gVHJ1ZQogICAgaWYgcmUubWF0Y2gocideW0EtWmEtejAt
REM OSsvXXsxNix9PXswLDJ9JCcsIGludGVyaW9yKSBhbmQgcmUuc2VhcmNoKHInXGQnLCBpbnRl
REM cmlvcik6CiAgICAgICAgcmV0dXJuIFRydWUKCiAgICAjIE1lbnNhZ2VucyBkZSBzdGF0dXMg
REM bGVnw612ZWlzIGNvbnRpbnVhbSBzZW5kbyB0ZXh0byBkZSB0ZWxhLCBtZXNtbyBxdWFuZG8K
REM ICAgICMgbWVuY2lvbmFtIHVtIG3Ds2R1bG8vYmluw6FyaW8uIEVsYXMgc8OjbyBzZWd1cmFz
REM IGNvbW8gdGV4dG8gcG9ycXVlIG8gbcOzZHVsbwogICAgIyDDqSBhcGVuYXMgcGFydGUgZG8g
REM Y29udGXDumRvIGV4aWJpZG87IG9zIHRva2VucyBkZSBhcnF1aXZvIHPDo28gcHJvdGVnaWRv
REM cwogICAgIyBhbnRlcyBkbyBHb29nbGUgVHJhbnNsYXRlLgogICAgaWYgcmUubWF0Y2gocide
REM KD86SW5bacOtXWNpb3xTdGFydCk6XHMqW0EtWmEtejAtOV8uLV0rKD86XHMqLT5ccypbQS1a
REM YS16MC05Xy4tXSspPyQnLCBpbnRlcmlvciwgcmUuSSk6CiAgICAgICAgcmV0dXJuIEZhbHNl
REM CiAgICBpZiByZS5tYXRjaChyJ15bQS1aYS16MC05Xy4tXSs6XHMqKD86U1VDQ0VTU3xPS3xE
REM T05FfENPTkNMVVtJw41dRE8pXC4/JCcsIGludGVyaW9yLCByZS5JKToKICAgICAgICByZXR1
REM cm4gRmFsc2UKCiAgICAjIERpYWduw7NzdGljby9zYcOtZGEgZGUgYmFpeG8gbsOtdmVsIHF1
REM ZSBwb2RlIGF0w6kgYXBhcmVjZXIgZW0gdW1hIHRlbGEgZGUKICAgICMgZXJybywgbWFzIG7D
REM o28gw6kgY29udGXDumRvIGRlIHRyYWR1w6fDo286IGtlcm5lbCBsb2dzLCBlbmRlcmXDp29z
REM LCBkcml2ZXJzLAogICAgIyBhcnF1aXZvcyAuc28vLmRsbCBlIG1lbnNhZ2VucyBkZSBJUlEv
REM UENJL0RNQS9BVEEuIE1hbnRlbW9zIG1lbnNhZ2VucwogICAgIyBodW1hbmFzIGZvcmEgZGVz
REM c2VzIHBhZHLDtWVzIChleC46IGNyw6lkaXRvcywgR2l0SHViIFRlbXBsYXRlLCBzdGF0dXMp
REM LgogICAgaWYgKHJlLm1hdGNoKHInXlxzKig/OlwqXCpcKnxbLeKAk11ccypBZGRyZXNzXGJ8
REM KD86aGRhfGhkY3xpZGV8ZmR8ZW5vfGV0aClcZCpcYnwoPzphY3BpfHBjaXxpcnF8Z3NpfGRt
REM YSlcYnwvaW5pdDopJywgaW50ZXJpb3IsIHJlLkkpCiAgICAgICAgICAgIG9yIHJlLm1hdGNo
REM KHInXltBLVphLXowLTlfLi1dK1wuKD86Y3xofGNwcHxocHApOicsIGludGVyaW9yLCByZS5J
REM KQogICAgICAgICAgICBvciAocmUuc2VhcmNoKHInXC4oPzpzb3xkbGx8ZXhlfGJpbilcYics
REM IGludGVyaW9yLCByZS5JKSBhbmQKICAgICAgICAgICAgICAgIHJlLnNlYXJjaChyJyg/Oklt
REM cG9ydEVycm9yfExvYWRlZHxTVUNDRVNTfGRpc2FibGV8bnZkcnN8RERMQ1wuc28pJywgaW50
REM ZXJpb3IsIHJlLkkpKQogICAgICAgICAgICBvciByZS5zZWFyY2gocidcYig/OkRhdGVzdGFt
REM cHxDSFM9fHNlY3RvcnNccypcKHxBVEFQSXxDRC1ST018QVRBICg/OkRJU0t8RkxPUFBZKXxW
REM SVJUVUFMICg/OkhBUkR8Q0R8RkxPUFBZKXxkcml2ZXIgUmV2aXNpb24pXGInLCBpbnRlcmlv
REM ciwgcmUuSSkKICAgICAgICAgICAgb3IgcmUuc2VhcmNoKHInMHgoPzpbMC05QS1GYS1mXXs0
REM LH18Zm9yY2Vccyo9XHMqcGFuaWMpXGInLCBpbnRlcmlvciwgcmUuSSkpOgogICAgICAgIHJl
REM dHVybiBUcnVlCgogICAgIyBDb3JlcyBub21lYWRhcyBlIGNvbWFuZG9zIHZpc3VhaXMgY29k
REM aWZpY2Fkb3MgY29tbyBzdHJpbmdzLgogICAgaWYgcmUubWF0Y2gocideKD86d2hpdGV8Ymxh
REM Y2t8cmVkfGdyZWVufGJsdWV8eWVsbG93fGN5YW58bWFnZW50YXxncmF5fGdyZXl8dHJhbnNw
REM YXJlbnQpJCcsIGludGVyaW9yLCByZS5JKToKICAgICAgICByZXR1cm4gVHJ1ZQogICAgaWYg
REM cmUubWF0Y2gocideKD86Ymd8c2NlbmV8c2hvd3xoaWRlfHdpdGh8cGxheXxxdWV1ZXxzdG9w
REM fHZvaWNlfGltYWdlfHRyYW5zZm9ybXxjYW1lcmF8YWRkfGF0fG9ufGNvbnRhaW5zKVxiJywg
REM aW50ZXJpb3IpOgogICAgICAgIHJldHVybiBUcnVlCiAgICBpZiByZS5tYXRjaChyJ15bQS1a
REM YS16X11bQS1aYS16MC05Xy5dKig/Ol8oPzpoZWFkZXJ8Ym9keXx0aXRsZV90ZXh0fGVtcHR5
REM X3RleHR8dGV4dF9rZXl8aWR8a2V5KSkkJywgaW50ZXJpb3IsIHJlLkkpOgogICAgICAgIHJl
REM dHVybiBUcnVlCiAgICBpZiB2YXJfbm9tZSBhbmQgVkFSX1JFQ1VSU09fUkUubWF0Y2godmFy
REM X25vbWUuc3BsaXQoJy4nKVstMV0pOgogICAgICAgIHJldHVybiBUcnVlCgogICAgIyBUYWdz
REM IGRlIGF1ZGlvL0FUTCArIGNhbWluaG8gZGUgcmVjdXJzby4KICAgIGlmIFJFQ1VSU09fQ09N
REM X1RBRy5tYXRjaChpbnRlcmlvcikgb3IgUkVDVVJTT19DT01fVEFHX1NFTV9QQVNUQS5tYXRj
REM aChpbnRlcmlvcik6CiAgICAgICAgcmV0dXJuIFRydWUKICAgIGlmIFJFQ1VSU09fQ0FNSU5I
REM Ty5tYXRjaChpbnRlcmlvcik6CiAgICAgICAgcmV0dXJuIFRydWUKICAgIGlmIHJlLm1hdGNo
REM KHInXlteXFwvXHNdK1wuKD86dHRmfG90Znx0dGN8cG5nfGpwZ3xqcGVnfGdpZnx3ZWJwfHdl
REM Ym18b2dnfG1wM3x3YXZ8ZmxhY3xtNGF8aWNvfHJweXxycHljfHJwYSkkJywgaW50ZXJpb3Is
REM IHJlLkkpOgogICAgICAgIHJldHVybiBUcnVlCgogICAgIyBTZSBvIHRleHRvIGNvaW5jaWRl
REM IGV4YXRhbWVudGUgY29tIHVtIGFycXVpdm8gcmVhbCBkbyBtb2QsIMOpIHJlY3Vyc28uCiAg
REM ICBpZiBpbmRpY2VfYXJxdWl2b3MgaXMgbm90IE5vbmU6CiAgICAgICAgdHJ5OgogICAgICAg
REM ICAgICBuID0gbm9ybWFsaXphcl9yZWZlcmVuY2lhX2FycXVpdm8oaW50ZXJpb3IpCiAgICAg
REM ICAgICAgIGlmIG4gYW5kIG4gaW4gaW5kaWNlX2FycXVpdm9zOgogICAgICAgICAgICAgICAg
REM cmV0dXJuIFRydWUKICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICBwYXNz
REM CgogICAgIyBDb2JlcnR1cmEgZmluYWwgcGFyYSByZWZlcmVuY2lhcyBkZSByZWN1cnNvcywg
REM aW5jbHVzaXZlIG5vbWVzIGNvbSBlc3BhY29zLgogICAgaWYgcmUubWF0Y2gocideKD86W0Et
REM WmEtejAtOV8uKClcLSBdK1tcXC9dKStbXlxcL10rXC4oPzp0dGZ8b3RmfHBuZ3xqcGd8anBl
REM Z3xnaWZ8d2VicHx3ZWJtfG9nZ3xtcDN8d2F2fGZsYWN8bTRhfHJweXxycHljfHJwYXx0eHR8
REM aWNvfGpzb258Y2hyfHB5fHB5Y3xkbGx8c298YXBrKSQnLCBpbnRlcmlvciwgcmUuSSk6CiAg
REM ICAgICAgcmV0dXJuIFRydWUKCiAgICByZXR1cm4gRmFsc2UKIyAtLS0gQ2FtYWRhIGNvbnRl
REM eHR1YWwgcmVjdXBlcmFkYSBkYXMgdmVyc8O1ZXMgZGUgbWFpb3IgY29iZXJ0dXJhIC0tLQpB
REM UlFVSVZPU19URVhUT19TRU1BTlRJQ08gPSAoCiAgICAiY3JlZGl0cyIsICJjcmVkaXQiLCAi
REM ZW5kX2NyZWRpdHMiLCAic3BsYXNoIiwgImV4Y2VwdGlvbiIsICJleGNlcHRpb25zIiwKICAg
REM ICJyZW5weV9wYXRjaGVzIiwgImxvY2tkb3duX2NoZWNrIiwgInRlbXBsYXRlX2NoZWNrcyIs
REM ICJkZXByZWNpYXRlZCIsCiAgICAiZGVwcmVjYXRpb24iLCAiZGVwcmVjaWF0aW9uIiwgIndh
REM cm5pbmciLCAibm90aWNlIiwgInBvZW1fcmVzcG9uc2UiLAogICAgInBvZW1fcmVzcG9uc2Vz
REM IiwgInBob25lIiwKKQpTVFJJTkdfTElURVJBTF9SRSA9IHJlLmNvbXBpbGUoUVNUUikKSURF
REM TlRJRklDQURPUl9QVVJPX1JFID0gcmUuY29tcGlsZShyJ15bQS1aYS16X11bQS1aYS16MC05
REM Xy4tXSokJykKSURFTlRJRklDQURPUl9DT01QT1NUT19SRSA9IHJlLmNvbXBpbGUoCiAgICBy
REM J15bQS1aYS16X11bQS1aYS16MC05Xy4tXSooPzpfKD86aGVhZGVyfGJvZHl8dGV4dHx0aXRs
REM ZXx0aXRsZV90ZXh0fGVtcHR5fGVtcHR5X3RleHR8bmFtZXxpZHxrZXl8bGFiZWwpKSQnLAog
REM ICAgcmUuSQopClZBUl9SRUNVUlNPX1JFID0gcmUuY29tcGlsZSgKICAgIHInXig/OmJnfGJh
REM Y2tncm91bmR8c2NlbmV8aW1hZ2V8aW1nfHNwcml0ZXxzcHJpdGVzfGNnfGNnc3xsYXllcnxs
REM YXllcnN8bWFza3xpY29ufHRodW1ibmFpbHx0aHVtYnxhdmF0YXJ8ZmFjZXxleHByZXNzaW9u
REM fHBvc2V8dHJhbnNmb3JtfGZvbnR8bXVzaWN8c29uZ3x0cmFja3xhdWRpb3xzb3VuZHxzZnh8
REM dm9pY2V8YW1iaWVuY2V8bW92aWV8dmlkZW98Z3VpKSQnLAogICAgcmUuSQopCkJMT0NPX1RF
REM Q05JQ09fUkUgPSByZS5jb21waWxlKAogICAgciJeKD86aW1hZ2UoPzpccytbJ1wiXT9bXjpd
REM Kj8pP3x0cmFuc2Zvcm0oPzpccytbXjpdKyk/fGxheWVyZWRpbWFnZSg/OlxzK1teOl0rKT98
REM c3R5bGUoPzpccytbXjpdKyk/KVxzKjoiLAogICAgcmUuSQopCgpkZWYgY29uc3RydWlyX2xp
REM bmhhc19ibG9jb3NfdGVjbmljb3MobGluaGFzX3Jhdyk6CiAgICAjIE1hcmNhIGFwZW5hcyBz
REM dWJsaW5oYXMgZGUgYmxvY29zIHZpc3VhaXMgZGVjbGFyYXRpdm9zLiBTY3JlZW4vbWVudS9w
REM eXRob24KICAgICMgY29udGludWFtIGFuYWxpc2Fkb3MgcG9ycXVlIHBvZGVtIGNvbnRlciB0
REM ZXh0byByZWFsbWVudGUgdmlzw612ZWwuCiAgICBtYXJjYWRhcyA9IHNldCgpCiAgICBwaWxo
REM YSA9IFtdCiAgICBmb3IgaWR4LCByYXcgaW4gZW51bWVyYXRlKGxpbmhhc19yYXcsIDEpOgog
REM ICAgICAgIGxpbmhhID0gcmF3LnJzdHJpcCgnXHJcbicpCiAgICAgICAgbGltcGEgPSBsaW5o
REM YS5zdHJpcCgpCiAgICAgICAgaWYgbm90IGxpbXBhIG9yIGxpbXBhLnN0YXJ0c3dpdGgoJyMn
REM KToKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpbmRlbnQgPSBsZW4obGluaGEpIC0g
REM bGVuKGxpbmhhLmxzdHJpcCgpKQogICAgICAgIHdoaWxlIHBpbGhhIGFuZCBpbmRlbnQgPD0g
REM cGlsaGFbLTFdOgogICAgICAgICAgICBwaWxoYS5wb3AoKQogICAgICAgIGlmIHBpbGhhOgog
REM ICAgICAgICAgICBtYXJjYWRhcy5hZGQoaWR4KQogICAgICAgIGlmIEJMT0NPX1RFQ05JQ09f
REM UkUubWF0Y2gobGltcGEpOgogICAgICAgICAgICBwaWxoYS5hcHBlbmQoaW5kZW50KQogICAg
REM cmV0dXJuIG1hcmNhZGFzCgpQWVRIT05fSU5JQ0lPX1JFID0gcmUuY29tcGlsZShyJ14oPzpp
REM bml0KD86XHMrLT9cZCspP1xzKyk/cHl0aG9uXGJbXjojIlwnXSo6XHMqKD86Iy4qKT8kJykK
REM RUxFTUVOVE9TX0NPTlRBSU5FUiA9IGZyb3plbnNldChbCiAgICAic2lkZSIsICJ2cGdyaWQi
REM LCAiZ3JpZCIsICJmcmFtZSIsICJ3aW5kb3ciLCAiZml4ZWQiLCAidmJveCIsICJoYm94Iiwg
REM InZpZXdwb3J0IiwKICAgICJpbWFnZW1hcCIsICJob3RzcG90IiwgIm1vdXNlYXJlYSIsICJi
REM dXR0b24iLCAiYmFyIiwgInZiYXIiLCAiZHJhZyIsICJkcmFnZ3JvdXAiLAogICAgImFyZWEi
REM LCAibnVsbCIsCl0pCgpkZWYgY29uc3RydWlyX2xpbmhhc19weXRob24obGluaGFzX3Jhdyk6
REM CiAgICAjIE1hcmNhIGFzIGxpbmhhcyBxdWUgZXN0w6NvIERFTlRSTyBkZSBibG9jb3MgcHl0
REM aG9uIChpbml0IHB5dGhvbjosIHB5dGhvbjosCiAgICAjIHB5dGhvbiBlYXJseTosIHB5dGhv
REM biBpbiB4Oi4uLiksIGluY2x1c2l2ZSBkb2NzdHJpbmdzIGRlIHbDoXJpYXMgbGluaGFzLgog
REM ICAgIyBUYW1iw6ltIHJlY29uaGVjZSBjb3Jwb3MgZGUgZGVmL2NsYXNzIGNvbW8gZmFsbGJh
REM Y2suIElzc28gZXZpdGEgcXVlIHVtYQogICAgIyBkb2NzdHJpbmcgc2VqYSBjb25mdW5kaWRh
REM IGNvbSBkacOhbG9nbyBjYXNvIG8gYmxvY28gcHl0aG9uIGVzdGVqYSBlc2NyaXRvCiAgICAj
REM IGRlIHVtYSBmb3JtYSBxdWUgYSByZWdleCBwcmluY2lwYWwgbsOjbyBjb25zaWdhIGlkZW50
REM aWZpY2FyLgogICAgbWFyY2FkYXMgPSBzZXQoKQogICAgcHlfaW5kZW50ID0gTm9uZQogICAg
REM ZGVmX2luZGVudGVzID0gW10KICAgIGVtX3RyaXBsbyA9IE5vbmUKICAgIGZvciBpZHgsIHJh
REM dyBpbiBlbnVtZXJhdGUobGluaGFzX3JhdywgMSk6CiAgICAgICAgbGluaGEgPSByYXcucnN0
REM cmlwKCdcclxuJykKICAgICAgICBsaW1wYSA9IGxpbmhhLnN0cmlwKCkKICAgICAgICBpbmRl
REM bnQgPSBsZW4obGluaGEpIC0gbGVuKGxpbmhhLmxzdHJpcCgpKQoKICAgICAgICBpZiBlbV90
REM cmlwbG8gaXMgbm90IE5vbmU6CiAgICAgICAgICAgIG1hcmNhZGFzLmFkZChpZHgpCiAgICAg
REM ICAgICAgIGlmIGxpbmhhLmNvdW50KGVtX3RyaXBsbykgJSAyID09IDE6CiAgICAgICAgICAg
REM ICAgICBlbV90cmlwbG8gPSBOb25lCiAgICAgICAgICAgIGNvbnRpbnVlCgogICAgICAgIGlm
REM IG5vdCBsaW1wYSBvciBsaW1wYS5zdGFydHN3aXRoKCcjJyk6CiAgICAgICAgICAgIGNvbnRp
REM bnVlCgogICAgICAgIHdoaWxlIGRlZl9pbmRlbnRlcyBhbmQgaW5kZW50IDw9IGRlZl9pbmRl
REM bnRlc1stMV06CiAgICAgICAgICAgIGRlZl9pbmRlbnRlcy5wb3AoKQoKICAgICAgICBpZiBw
REM eV9pbmRlbnQgaXMgbm90IE5vbmUgYW5kIGluZGVudCA8PSBweV9pbmRlbnQ6CiAgICAgICAg
REM ICAgIHB5X2luZGVudCA9IE5vbmUKCiAgICAgICAgZGVudHJvX3B5dGhvbiA9IHB5X2luZGVu
REM dCBpcyBub3QgTm9uZSBvciBib29sKGRlZl9pbmRlbnRlcykKCiAgICAgICAgaWYgUFlUSE9O
REM X0lOSUNJT19SRS5tYXRjaChsaW1wYSk6CiAgICAgICAgICAgIHB5X2luZGVudCA9IGluZGVu
REM dAogICAgICAgICAgICBkZW50cm9fcHl0aG9uID0gVHJ1ZQogICAgICAgICAgICBjb250aW51
REM ZQoKICAgICAgICBpZiByZS5tYXRjaChyJ14oPzphc3luY1xzKyk/KD86ZGVmfGNsYXNzKVxi
REM Lio6XHMqKD86Iy4qKT8kJywgbGltcGEpOgogICAgICAgICAgICBkZWZfaW5kZW50ZXMuYXBw
REM ZW5kKGluZGVudCkKICAgICAgICAgICAgY29udGludWUKCiAgICAgICAgaWYgbm90IGRlbnRy
REM b19weXRob246CiAgICAgICAgICAgIGNvbnRpbnVlCgogICAgICAgIG1hcmNhZGFzLmFkZChp
REM ZHgpCgogICAgICAgIGZvciBhc3BhcyBpbiAoY2hyKDM0KSAqIDMsIGNocigzOSkgKiAzKToK
REM ICAgICAgICAgICAgaWYgbGluaGEuY291bnQoYXNwYXMpICUgMiA9PSAxOgogICAgICAgICAg
REM ICAgICAgZW1fdHJpcGxvID0gYXNwYXMKICAgICAgICAgICAgICAgIGJyZWFrCgogICAgcmV0
REM dXJuIG1hcmNhZGFzCmRlZiBwYXJlY2VfZnJhc2UodmFsb3JfY29tX2FzcGFzKToKICAgIGlu
REM dGVyaW9yID0gc3RyaXBfcXVvdGVzKHZhbG9yX2NvbV9hc3Bhcykuc3RyaXAoKQogICAgaWYg
REM bGVuKGludGVyaW9yLnNwbGl0KCkpID49IDM6CiAgICAgICAgcmV0dXJuIFRydWUKICAgIHJl
REM dHVybiBib29sKHJlLnNlYXJjaChyJ1suIT9cdTIwMjY6OyxdJCcsIGludGVyaW9yKSkKCmRl
REM ZiBwYXJlY2VfY29kaWdvX25hX2xpbmhhKGxpbmhhX2xpbXBhLCBpbmljaW8sIGZpbSk6CiAg
REM ICAjIEJsb3F1ZWlhIGZhbHNvcyBwb3NpdGl2b3MgdMOtcGljb3MgZG8gZmFsbGJhY2sgTEVH
REM QUNZX0RJQUxPR086CiAgICAjIGNoYXZlcyBkZSBkaWNpb27DoXJpbywgc3RyaW5ncyBwYXNz
REM YWRhcyBhIF9faW5pdF9fL2Z1bsOnw7VlcyBlIGZyYWdtZW50b3MKICAgICMgZGUgZG9jc3Ry
REM aW5ncyBxdWUgcGFyZWNlbSBkacOhbG9nbyBwb3IgdGVyZW0gdGV4dG8gYW50ZXMgZGEgc3Ry
REM aW5nLgogICAgdHJlY2hvID0gbGluaGFfbGltcGFbaW5pY2lvOmZpbV0KICAgIGludGVyaW9y
REM ID0gc3RyaXBfcXVvdGVzKHRyZWNobykuc3RyaXAoKQogICAgcHJlZml4byA9IGxpbmhhX2xp
REM bXBhWzppbmljaW9dLnN0cmlwKCkKICAgIHN1Zml4byA9IGxpbmhhX2xpbXBhW2ZpbTpdLnN0
REM cmlwKCkKCiAgICBpZiByZS5zZWFyY2gocidcYig/Ol9faW5pdF9ffGRlZnxjbGFzc3xyZXR1
REM cm58aW1wb3J0fGZyb218bGFtYmRhfHNlbGZ8c3VwZXIpXGInLCBwcmVmaXhvLCByZS5JKToK
REM ICAgICAgICByZXR1cm4gVHJ1ZQoKICAgIGlmIHJlLm1hdGNoKHInXlsnICsgY2hyKDM0KSAr
REM IGNocigzOSkgKyByJ11bQS1aYS16X11bQS1aYS16MC05Xy4tXSpbJyArIGNocigzNCkgKyBj
REM aHIoMzkpICsgciddXHMqOicsIHRyZWNobyArIHN1Zml4byk6CiAgICAgICAgcmV0dXJuIFRy
REM dWUKCiAgICBpZiByZS5tYXRjaChyJ15bQS1aYS16X11bQS1aYS16MC05Xy1dKig/OlwuW0Et
REM WmEtejAtOV8tXSspKiQnLCBpbnRlcmlvcik6CiAgICAgICAgcGFsYXZyYXMgPSByZS5maW5k
REM YWxsKHInW0EtWmEtel9dW0EtWmEtejAtOV8uLV0qJywgcHJlZml4bykKICAgICAgICBpZiBs
REM ZW4ocGFsYXZyYXMpID49IDM6CiAgICAgICAgICAgIHJldHVybiBUcnVlCgogICAgIyBCbG9x
REM dWVpYSBvIGZvcm1hdG8gZGUgbGF5b3V0IHVzYWRvIGVtIGPDs2RpZ28sIGNvbW8gYHNpZGUg
REM InQgYiI6YCBvdQogICAgIyBgc2lkZSAidCBjIjpgLCBzZW0gYmxvcXVlYXIgZmFsYXMgbm9y
REM bWFpcy4KICAgIGlmIHJlLm1hdGNoKHInXltBLVphLXpdKyg/OlxzK1tBLVphLXpdKyl7MSwz
REM fSQnLCBpbnRlcmlvcikgYW5kIHN1Zml4by5zdGFydHN3aXRoKCc6Jyk6CiAgICAgICAgcmV0
REM dXJuIFRydWUKCiAgICByZXR1cm4gRmFsc2UKCmRlZiBhcnF1aXZvX3RlbV9jb250ZXh0b190
REM ZXh0dWFsKGNhbWluaG8pOgogICAgbm9tZSA9IG9zLnBhdGguYmFzZW5hbWUoY2FtaW5obyku
REM bG93ZXIoKQogICAgc3RlbSA9IG9zLnBhdGguc3BsaXRleHQobm9tZSlbMF0KICAgIHJldHVy
REM biBhbnkodG9rIGluIHN0ZW0gZm9yIHRvayBpbiBBUlFVSVZPU19URVhUT19TRU1BTlRJQ08p
REM CgpkZWYgcGFyZWNlX3N0cmluZ19zZW1hbnRpY2EodmFsb3JfY29tX2FzcGFzLCBjYW1pbmhv
REM LCB2YXJfbm9tZT0iIiwgcGVybWl0aXJfaWRlbnRpZmljYWRvcj1GYWxzZSk6CiAgICBpbnRl
REM cmlvciA9IHN0cmlwX3F1b3Rlcyh2YWxvcl9jb21fYXNwYXMpLnN0cmlwKCkKICAgIGlmIG5v
REM dCBpbnRlcmlvcjoKICAgICAgICByZXR1cm4gRmFsc2UKICAgIGlmIHBhcmVjZV90ZXh0b190
REM ZWNuaWNvKHZhbG9yX2NvbV9hc3BhcywgdmFyX25vbWU9dmFyX25vbWUpOgogICAgICAgIHJl
REM dHVybiBGYWxzZQogICAgaWYgSURFTlRJRklDQURPUl9DT01QT1NUT19SRS5tYXRjaChpbnRl
REM cmlvcik6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBpZiBJREVOVElGSUNBRE9SX1BVUk9f
REM UkUubWF0Y2goaW50ZXJpb3IpIGFuZCAiICIgbm90IGluIGludGVyaW9yOgogICAgICAgIHJl
REM dHVybiBib29sKHBlcm1pdGlyX2lkZW50aWZpY2Fkb3IpCiAgICByZXR1cm4gVHJ1ZQoKVEVY
REM VFVBTF9BU1NJR05fUkUgPSByZS5jb21waWxlKAogICAgcideXHMqKD86XCRccyopPygoPzpt
REM ZXNzYWdlfG1lc3NhZ2VzfHRleHR8Y2FwdGlvbnxwcm9tcHR8dGl0bGV8ZGVzY3JpcHRpb258
REM d2FybmluZ3xlcnJvcnxleGNlcHRpb258bm90aWNlfGhlYWRlcnxib2R5fHNob3cpW0EtWmEt
REM ejAtOV8uXSp8W0EtWmEtel9dW0EtWmEtejAtOV8uXSooPzpcLnxfKSg/Om1lc3NhZ2V8bWVz
REM c2FnZXN8dGV4dHxjYXB0aW9ufHByb21wdHx0aXRsZXxkZXNjcmlwdGlvbnx3YXJuaW5nfGVy
REM cm9yfGV4Y2VwdGlvbnxub3RpY2V8aGVhZGVyfGJvZHl8c2hvdylbQS1aYS16MC05Xy5dKilc
REM cyo9XHMqKCcgKyBRU1RSICsgcicpXHMqJCcsCiAgICByZS5JCikKRFlOQU1JQ19WSVNJQkxF
REM X1RFWFRfQVNTSUdOX1JFID0gcmUuY29tcGlsZSgKICAgIHInXlxzKlwkXHMqKG1lbnV0ZXh0
REM KVxzKj1ccyooJyArIFFTVFIgKyByJylccyokJywKICAgIHJlLkkKKQpQUk9QUklFREFERVNf
REM TkFPX1RFWFRPID0gZnJvemVuc2V0KFsKICAgICJpZCIsICJzdHlsZSIsICJzdHlsZV9wcmVm
REM aXgiLCAidmFyaWFudCIsICJpZGxlIiwgImhvdmVyIiwgImluc2Vuc2l0aXZlIiwKICAgICJz
REM ZWxlY3RlZF9pZGxlIiwgInNlbGVjdGVkX2hvdmVyIiwgInNlbGVjdGVkX2luc2Vuc2l0aXZl
REM IiwgImxheW91dCIsCiAgICAic2l6ZV9ncm91cCIsICJncm91bmQiLApdKQpFTEVNRU5UT1Nf
REM REVfVEVMQSA9IGZyb3plbnNldChbCiAgICAidGV4dCIsICJ0ZXh0YnV0dG9uIiwgImxhYmVs
REM IiwgInZpZXdwb3J0IiwgInZwZ3JpZCIsICJmcmFtZSIsICJ3aW5kb3ciLAogICAgInZib3gi
REM LCAiaGJveCIsICJmaXhlZCIsICJpbWFnZWJ1dHRvbiIsICJidXR0b24iLCAiYmFyIiwgInZi
REM YXIiLCAiaW5wdXQiLAogICAgImtleSIsICJ0aW1lciIsICJ1c2UiLCAiaG90c3BvdCIsICJp
REM bWFnZW1hcCIsICJzaWRlIiwgImdyaWQiLCAibnVsbCIsCiAgICAiZHJhZyIsICJkcmFnZ3Jv
REM dXAiLCAibW91c2VhcmVhIiwgImFyZWEiLApdKQpFWFRFTlNPRVNfSU1BR0VNX1ZPQ0FCVUxB
REM UklPID0gKCIucG5nIiwgIi5qcGciLCAiLmpwZWciLCAiLndlYnAiLCAiLmdpZiIsICIud2Vi
REM bSIsICIuYXZpZiIpCgpkZWYgdGVtX2NvbnRldWRvX3RyYWR1eml2ZWwodmFsb3JfY29tX2Fz
REM cGFzKToKICAgIGludGVyaW9yID0gc3RyaXBfcXVvdGVzKHZhbG9yX2NvbV9hc3BhcykKICAg
REM IHJlc3RhbnRlID0gcmUuc3ViKHInXFtbXlxdXSpcXXxce1tefV0qXH18XFwuJywgdSIiLCBp
REM bnRlcmlvcikKICAgIGlmIHJlLnNlYXJjaChyJ1teXFdcZF9dJywgcmVzdGFudGUpOgogICAg
REM ICAgIHJldHVybiBUcnVlCiAgICByZXR1cm4gYm9vbChyZS5tYXRjaChyJ15bXHMuPyFcdTIw
REM MjYqflwtXHUyMDE0XHUyMDEzXSskJywgcmVzdGFudGUpKQoKClRFWFRfQ0FMTF9TVEFSVF9S
REM RSA9IHJlLmNvbXBpbGUocidcYig/OlRleHR8UGFyYW1ldGVyaXplZFRleHQpXHMqXCgnLCBy
REM ZS5JKQoKCmRlZiBleHRyYWlyX2ZyYWdtZW50b3NfdGV4dF9jYWxsX2RpbmFtaWNvKGxpbmhh
REM LCBjYW1pbmhvKToKICAgICIiIkV4dHJhaSBsaXRlcmFpcyB2aXPDrXZlaXMgZG8gcHJpbWVp
REM cm8gYXJndW1lbnRvIGRpbsOibWljbyBkZSBUZXh0KCkuIiIiCiAgICBzYWlkYSA9IFtdCiAg
REM ICBmb3IgbV9jYWxsIGluIFRFWFRfQ0FMTF9TVEFSVF9SRS5maW5kaXRlcihsaW5oYSk6CiAg
REM ICAgICAgYWJyZSA9IGxpbmhhLmZpbmQodScoJywgbV9jYWxsLnN0YXJ0KCkpCiAgICAgICAg
REM aWYgYWJyZSA8IDA6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgZmVjaGEgPSBfZmlu
REM ZF9tYXRjaGluZ19wYXJlbihsaW5oYSwgYWJyZSkKICAgICAgICBpZiBmZWNoYSA8IDA6CiAg
REM ICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgYXJnMCA9IGxpbmhhW2FicmUgKyAxOmZlY2hh
REM XQoKICAgICAgICBkZXB0aCA9IDAKICAgICAgICBxdW90ZSA9IE5vbmUKICAgICAgICBlc2Mg
REM PSBGYWxzZQogICAgICAgIGZpbV9hcmcgPSBsZW4oYXJnMCkKICAgICAgICBmb3IgaSwgY2gg
REM aW4gZW51bWVyYXRlKGFyZzApOgogICAgICAgICAgICBpZiBxdW90ZSBpcyBub3QgTm9uZToK
REM ICAgICAgICAgICAgICAgIGlmIGVzYzoKICAgICAgICAgICAgICAgICAgICBlc2MgPSBGYWxz
REM ZQogICAgICAgICAgICAgICAgZWxpZiBjaCA9PSB1J1xcJzoKICAgICAgICAgICAgICAgICAg
REM ICBlc2MgPSBUcnVlCiAgICAgICAgICAgICAgICBlbGlmIGNoID09IHF1b3RlOgogICAgICAg
REM ICAgICAgICAgICAgIHF1b3RlID0gTm9uZQogICAgICAgICAgICAgICAgY29udGludWUKICAg
REM ICAgICAgICAgaWYgY2ggaW4gKHUnXCInLCB1IiciKToKICAgICAgICAgICAgICAgIHF1b3Rl
REM ID0gY2gKICAgICAgICAgICAgZWxpZiBjaCBpbiAodScoJywgdSdbJywgdSd7Jyk6CiAgICAg
REM ICAgICAgICAgICBkZXB0aCArPSAxCiAgICAgICAgICAgIGVsaWYgY2ggaW4gKHUnKScsIHUn
REM XScsIHUnfScpOgogICAgICAgICAgICAgICAgZGVwdGggPSBtYXgoMCwgZGVwdGggLSAxKQog
REM ICAgICAgICAgICBlbGlmIGNoID09IHUnLCcgYW5kIGRlcHRoID09IDA6CiAgICAgICAgICAg
REM ICAgICBmaW1fYXJnID0gaQogICAgICAgICAgICAgICAgYnJlYWsKCiAgICAgICAgZXhwciA9
REM IGFyZzBbOmZpbV9hcmddCiAgICAgICAgaWYgdScrJyBub3QgaW4gZXhwcjoKICAgICAgICAg
REM ICAgY29udGludWUKCiAgICAgICAgYmFzZSA9IGFicmUgKyAxCiAgICAgICAgZm9yIHNtIGlu
REM IHJlLmZpbmRpdGVyKFFTVFIsIGV4cHIpOgogICAgICAgICAgICBxID0gc20uZ3JvdXAoMCkK
REM ICAgICAgICAgICAgaWYgbm90IHRlbV9jb250ZXVkb190cmFkdXppdmVsKHEpOgogICAgICAg
REM ICAgICAgICAgY29udGludWUKICAgICAgICAgICAgaWYgbm90IHBhcmVjZV9zdHJpbmdfc2Vt
REM YW50aWNhKHEsIGNhbWluaG8pOgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAg
REM ICAgc2FpZGEuYXBwZW5kKChiYXNlICsgc20uc3RhcnQoKSwgYmFzZSArIHNtLmVuZCgpLCBx
REM KSkKICAgIHJldHVybiBzYWlkYQoKZGVmIHZhcmlhdmVsX2VoX3RlY25pY2EodmFyX25vbWUs
REM IHZhbG9yX2NvbV9hc3Bhcywgdm9jYWJ1bGFyaW8pOgogICAgaWYgbm90IHZvY2FidWxhcmlv
REM IG9yIHZhcl9ub21lIGluICgiY29uZmlnLm5hbWUiLCAiZ3VpLmFib3V0Iik6CiAgICAgICAg
REM cmV0dXJuIEZhbHNlCgogICAgIyBOb21lcyBkZSBwZXJzb25hZ2VucyBkZWZpbmlkb3MgZXhw
REM bGljaXRhbWVudGUgcGVsbyBlY29zc2lzdGVtYSBERExDLgogICAgIyBJc3NvIGluY2x1aSBO
REM X25hbWUsIHRfbmFtZSwgY19uYW1lLCBza19uYW1lLCBtb21fbmFtZSBlIHZhcmlhbnRlcyAq
REM X25hbWUKICAgICMgY2F0YWxvZ2FkYXMgZW0gZGVmaW5pdGlvbnMucnB5IC8gY29uc3RydXRv
REM cmVzIGRlIENoYXJhY3Rlci4KICAgIG5vbWVzX3BlcnNvbmFnZW0gPSB2b2NhYnVsYXJpby5n
REM ZXQoIm5vbWVzX3BlcnNvbmFnZW1fdmFyaWF2ZWlzIiwgc2V0KCkpCiAgICBiYXNlID0gdmFy
REM X25vbWUucnNwbGl0KCIuIiwgMSlbLTFdLmxvd2VyKCkKICAgIGlmIGJhc2UgaW4gRERMQ19W
REM QVJJQVZFSVNfTk9NRV9DT05IRUNJREFTIG9yIHZhcl9ub21lIGluIG5vbWVzX3BlcnNvbmFn
REM ZW06CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBpZiBiYXNlLmVuZHN3aXRoKCJfbmFtZSIp
REM IGFuZCB2YXJfbm9tZSBpbiB2b2NhYnVsYXJpby5nZXQoIm5vbWVzX3BlcnNvbmFnZW1fdmFy
REM aWF2ZWlzIiwgc2V0KCkpOgogICAgICAgIHJldHVybiBGYWxzZQoKICAgIGlmIHZhcl9ub21l
REM IGluIHZvY2FidWxhcmlvWyJ2YXJpYXZlaXNfdGVjbmljYXMiXToKICAgICAgICByZXR1cm4g
REM VHJ1ZQoKICAgICMgVmFyacOhdmVpcyBkZSBlc3RpbG8gc8OjbyBpZGVudGlmaWNhZG9yZXMg
REM UmVuJ1B5LCBuw6NvIHRleHRvIGRlIGludGVyZmFjZS4KICAgICMgRXZpdGEgZW52aWFyIHZh
REM bG9yZXMgY29tbyBgYnV0dG9uX3RleHRgIC8gYHRleHRfc3R5bGVgIHBhcmEgbyB0cmFkdXRv
REM ci4KICAgIGJhc2UgPSB2YXJfbm9tZS5yc3BsaXQoIi4iLCAxKVstMV0ubG93ZXIoKQogICAg
REM aWYgYmFzZSBpbiAoInN0eWxlIiwgInN0eWxlX3ByZWZpeCIpIG9yIGJhc2UuZW5kc3dpdGgo
REM Il9zdHlsZSIpIG9yIGJhc2UuZW5kc3dpdGgoIl9zdHlsZV9wcmVmaXgiKToKICAgICAgICBy
REM ZXR1cm4gVHJ1ZQoKICAgICMgVmFyacOhdmVpcyB0ZXJtaW5hZGFzIGVtIF9rZXkvX2lkIGNv
REM c3R1bWFtIGd1YXJkYXIgY2hhdmVzIGludGVybmFzLgogICAgIyBTw7MgYmxvcXVlYW1vcyBx
REM dWFuZG8gbyB2YWxvciB0YW1iw6ltIMOpIHVtIGlkZW50aWZpY2Fkb3IgcHVybzsgaXNzbyBu
REM w6NvCiAgICAjIGFmZXRhIG5vbWVzIGV4aWJpZG9zIGxlZ8OtdGltb3MgY29tbyBgY2g0X25h
REM bWUgPSAiWXVyaSJgLgogICAgdmFsb3IgPSBzdHJpcF9xdW90ZXModmFsb3JfY29tX2FzcGFz
REM KS5zdHJpcCgpCiAgICBpZiAoYmFzZSBpbiAoImtleSIsICJpZCIpIG9yIGJhc2UuZW5kc3dp
REM dGgoIl9rZXkiKSBvciBiYXNlLmVuZHN3aXRoKCJfaWQiKSkgYW5kIElERU5ULm1hdGNoKHZh
REM bG9yKToKICAgICAgICByZXR1cm4gVHJ1ZQoKICAgICMgRXN0YWRvcy9yb3RhcyBpbnRlcm5v
REM czogYmFycmFyIHF1YW5kbyBvIHZhbG9yIHRlbSBmb3JtYSBkZSBpZGVudGlmaWNhZG9yCiAg
REM ICAjIG91IGZsYWcuIFNlIG8gdmFsb3IgZm9yIHVtYSBmcmFzZSBuYXR1cmFsLCBtYW50ZW1v
REM cyBhIHBvc3NpYmlsaWRhZGUgZGUKICAgICMgc2VyIHRleHRvIHZpc8OtdmVsIGUgZGVpeGFt
REM b3MgbyBvcsOhY3VsbyBzZW3Dom50aWNvL2hldXLDrXN0aWNhcyBkZWNpZGlyZW0uCiAgICBp
REM ZiBiYXNlIGluIFJFTnB5X0VTVEFET1NfVEVDTklDT1M6CiAgICAgICAgaWYgKElERU5ULm1h
REM dGNoKHZhbG9yKSBvciByZS5mdWxsbWF0Y2gociJbLStdP1xkKyg/OlwuXGQrKT8iLCB2YWxv
REM cikgb3IKICAgICAgICAgICAgICAgIHZhbG9yLmxvd2VyKCkgaW4gKCJ0cnVlIiwgImZhbHNl
REM IiwgIm5vbmUiLCAibnVsbCIpKToKICAgICAgICAgICAgcmV0dXJuIFRydWUKCiAgICAjIE1l
REM dGFkYWRvcy9idWlsZCBudW5jYSBzw6NvIGRlc3Rpbm8gZG8gR29vZ2xlLgogICAgaWYgcmUu
REM bWF0Y2gociJeKD86YnVpbGQoPzpcLnwkKXxfX2J1aWxkfF9fdmVyc2lvbnx2ZXJzaW9uX2lu
REM Zm8pIiwgYmFzZSwgcmUuSSk6CiAgICAgICAgcmV0dXJuIFRydWUKCiAgICByZXR1cm4gdmFs
REM b3IgaW4gdm9jYWJ1bGFyaW9bIm5vbWVzX2RvX2pvZ28iXQoKZGVmIGNvbGV0YXJfdm9jYWJ1
REM bGFyaW8ocGFzdGFfZ2FtZSwgY2FuZGlkYXRvcyk6CiAgICB2YXJpYXZlaXNfdGVjbmljYXMg
REM PSBzZXQoKQogICAgbm9tZXNfZG9fam9nbyA9IHNldCgpCiAgICBwZXJzb25hZ2VucyA9IHNl
REM dCgpCiAgICBub21lc19wZXJzb25hZ2VtX3ZhcmlhdmVpcyA9IHNldCgpCiAgICBwYWRyYW9f
REM cGVyc29uYWdlbSA9IHJlLmNvbXBpbGUocideKD86ZGVmaW5lfGRlZmF1bHQpXHMrKFtBLVph
REM LXpfXVx3Kilccyo9XHMqKD86cmVucHlcLik/KD86RHluYW1pYyk/Q2hhcmFjdGVyXHMqXCgn
REM KQogICAgcGFkcm9lc19ub21lID0gKAogICAgICAgIHJlLmNvbXBpbGUocideKD86aW1hZ2V8
REM bGF5ZXJlZGltYWdlKVxzKyhbQS1aYS16X11bXHcuIF0qPylccyooPzo9fDopJyksCiAgICAg
REM ICAgcmUuY29tcGlsZShyJ14oPzpsYWJlbHxzY3JlZW4pXHMrKFtBLVphLXpfXVtcdy5dKikn
REM KSwKICAgICkKICAgIHBhZHJvZXNfdmFyaWF2ZWwgPSAoCiAgICAgICAgcmUuY29tcGlsZShy
REM J1xiKFtBLVphLXpfXVtcdy5dKilccyooPzo9PXwhPSlccypbIlwnXVteIlwnXScpLAogICAg
REM ICAgIHJlLmNvbXBpbGUocidbIlwnXVteIlwnXStbIlwnXVxzKig/Oj09fCE9KVxzKihbQS1a
REM YS16X11bXHcuXSopJyksCiAgICAgICAgcmUuY29tcGlsZShyJ1xiKD86U2V0VmFyaWFibGV8
REM U2V0U2NyZWVuVmFyaWFibGV8VG9nZ2xlVmFyaWFibGV8VG9nZ2xlU2NyZWVuVmFyaWFibGUp
REM XChccypbIlwnXShbXHcuXSspWyJcJ10nKSwKICAgICkKICAgIGZvciBjYW1pbmhvIGluIGNh
REM bmRpZGF0b3M6CiAgICAgICAgaWYgY2FtaW5oby5sb3dlcigpLmVuZHN3aXRoKCIudHh0Iik6
REM CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRoIGlv
REM Lm9wZW4oY2FtaW5obywgJ3InLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxhY2Un
REM LCBuZXdsaW5lPScnKSBhcyBmOgogICAgICAgICAgICAgICAgbGluaGFzID0gZi5yZWFkKCku
REM c3BsaXRsaW5lcygpCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgY29u
REM dGludWUKICAgICAgICBlaF9hcnF1aXZvX2RlZmluaWNvZXMgPSBvcy5wYXRoLmJhc2VuYW1l
REM KGNhbWluaG8pLmxvd2VyKCkgaW4gKCJkZWZpbml0aW9ucy5ycHkiLCAiMDFkZWZpbml0aW9u
REM cy5ycHkiKQogICAgICAgIGZvciBsaW5oYSBpbiBsaW5oYXM6CiAgICAgICAgICAgIGxpbXBh
REM ID0gbGluaGEuc3RyaXAoKQogICAgICAgICAgICBpZiBlaF9hcnF1aXZvX2RlZmluaWNvZXM6
REM CiAgICAgICAgICAgICAgICBtX25vbWVfZGVmID0gcmUubWF0Y2gocideKD86ZGVmaW5lXHMr
REM fGRlZmF1bHRccyspPyhbQS1aYS16X11bQS1aYS16MC05X10qX25hbWUpXHMqPVxzKig/OnUp
REM P1siXCddW14iXCddK1siXCddJywgbGltcGEpCiAgICAgICAgICAgICAgICBpZiBtX25vbWVf
REM ZGVmOgogICAgICAgICAgICAgICAgICAgIG5vbWVzX3BlcnNvbmFnZW1fdmFyaWF2ZWlzLmFk
REM ZChtX25vbWVfZGVmLmdyb3VwKDEpKQogICAgICAgICAgICBtX3BlcnMgPSBwYWRyYW9fcGVy
REM c29uYWdlbS5tYXRjaChsaW1wYSkKICAgICAgICAgICAgaWYgbV9wZXJzOgogICAgICAgICAg
REM ICAgICAgcGVyc29uYWdlbnMuYWRkKG1fcGVycy5ncm91cCgxKSkKICAgICAgICAgICAgZm9y
REM IHBhZHJhbyBpbiBwYWRyb2VzX25vbWU6CiAgICAgICAgICAgICAgICBtID0gcGFkcmFvLm1h
REM dGNoKGxpbXBhKQogICAgICAgICAgICAgICAgaWYgbToKICAgICAgICAgICAgICAgICAgICBu
REM b21lID0gbS5ncm91cCgxKS5zdHJpcCgpCiAgICAgICAgICAgICAgICAgICAgbm9tZXNfZG9f
REM am9nby5hZGQobm9tZSkKICAgICAgICAgICAgICAgICAgICBub21lc19kb19qb2dvLnVwZGF0
REM ZShub21lLnNwbGl0KCkpCiAgICAgICAgICAgIGZvciBwYWRyYW8gaW4gcGFkcm9lc192YXJp
REM YXZlbDoKICAgICAgICAgICAgICAgIHZhcmlhdmVpc190ZWNuaWNhcy51cGRhdGUocGFkcmFv
REM LmZpbmRhbGwobGltcGEpKQogICAgaWdub3JhZGFzID0gc2V0KHAubG93ZXIoKSBmb3IgcCBp
REM biBQQVNUQVNfSUdOT1JBREFTKQogICAgZm9yIHBhc3RhX2F0dWFsLCBzdWJwYXN0YXMsIGFy
REM cXVpdm9zIGluIG9zLndhbGsocGFzdGFfZ2FtZSk6CiAgICAgICAgc3VicGFzdGFzWzpdID0g
REM W3AgZm9yIHAgaW4gc3VicGFzdGFzIGlmIHAubG93ZXIoKSBub3QgaW4gaWdub3JhZGFzXQog
REM ICAgICAgIGZvciBub21lIGluIGFycXVpdm9zOgogICAgICAgICAgICBiYXNlLCBleHRlbnNh
REM byA9IG9zLnBhdGguc3BsaXRleHQobm9tZSkKICAgICAgICAgICAgaWYgZXh0ZW5zYW8ubG93
REM ZXIoKSBpbiBFWFRFTlNPRVNfSU1BR0VNX1ZPQ0FCVUxBUklPOgogICAgICAgICAgICAgICAg
REM bm9tZXNfZG9fam9nby5hZGQoYmFzZSkKICAgIHJldHVybiB7InZhcmlhdmVpc190ZWNuaWNh
REM cyI6IHZhcmlhdmVpc190ZWNuaWNhcywgIm5vbWVzX2RvX2pvZ28iOiBub21lc19kb19qb2dv
REM LAogICAgICAgICAgICAicGVyc29uYWdlbnMiOiBwZXJzb25hZ2VucywgIm5vbWVzX3BlcnNv
REM bmFnZW1fdmFyaWF2ZWlzIjogbm9tZXNfcGVyc29uYWdlbV92YXJpYXZlaXN9CgpkZWYgZXh0
REM cmFpcl9pbmZvX25vbWVfcGVyc29uYWdlbShjaGFtYWRhLCBraW5kKToKICAgIG0gPSByZS5z
REM ZWFyY2gocidcYm5hbWVccyo9XHMqKCcgKyBRU1RSICsgcid8W0EtWmEtel9dXHcqKD86XC5b
REM QS1aYS16X11cdyopKiknLCBjaGFtYWRhKQogICAgaWYgbToKICAgICAgICB2PW0uZ3JvdXAo
REM MSkKICAgICAgICBpZiB2WzoxXSBpbiAoJyInLCAiJyIpOiByZXR1cm4gc3RyaXBfcXVvdGVz
REM KHYpLCBOb25lLCBtLnN0YXJ0KDEpCiAgICAgICAgcmV0dXJuIChOb25lLCB2LCBtLnN0YXJ0
REM KDEpKSBpZiBraW5kID09ICdEeW5hbWljQ2hhcmFjdGVyJyBlbHNlIChOb25lLCBOb25lLCBt
REM LnN0YXJ0KDEpKQogICAgbSA9IHJlLm1hdGNoKHInXHMqKCcgKyBRU1RSICsgcicpXHMqKD86
REM LHxcKSknLCBjaGFtYWRhKQogICAgaWYgbToKICAgICAgICB2PXN0cmlwX3F1b3RlcyhtLmdy
REM b3VwKDEpKQogICAgICAgIGlmIGtpbmQgPT0gJ0R5bmFtaWNDaGFyYWN0ZXInIGFuZCBJREVO
REM VC5tYXRjaCh2KTogcmV0dXJuIE5vbmUsIHYsIG0uc3RhcnQoMSkKICAgICAgICByZXR1cm4g
REM diwgTm9uZSwgbS5zdGFydCgxKQogICAgcmV0dXJuIE5vbmUsIE5vbmUsIC0xCgpkZWYgX3Bh
REM cnNlX3B5dGhvbl9zdHJpbmdfYXQodGV4dCwgcG9zKToKICAgICIiIlJldG9ybmEgKGZpbV9l
REM eGNsdXNpdm8sIGVoX3RyaXBsbykgcGFyYSB1bWEgc3RyaW5nIFB5dGhvbiBpbmljaWFkYSBl
REM bSBwb3MuIiIiCiAgICBpZiBwb3MgPCAwIG9yIHBvcyA+PSBsZW4odGV4dCkgb3IgdGV4dFtw
REM b3NdIG5vdCBpbiAoJyInLCAiJyIpOgogICAgICAgIHJldHVybiAtMSwgRmFsc2UKICAgIHF1
REM b3RlID0gdGV4dFtwb3NdCiAgICBpZiB0ZXh0LnN0YXJ0c3dpdGgocXVvdGUgKiAzLCBwb3Mp
REM OgogICAgICAgIGRlbGltID0gcXVvdGUgKiAzCiAgICAgICAgaSA9IHBvcyArIDMKICAgICAg
REM ICB3aGlsZSBpIDwgbGVuKHRleHQpOgogICAgICAgICAgICBpZiB0ZXh0LnN0YXJ0c3dpdGgo
REM ZGVsaW0sIGkpOgogICAgICAgICAgICAgICAgIyBVbWEgc2VxdcOqbmNpYSBlc2NhcGFkYSBk
REM ZSBiYXJyYXMgbsOjbyBmZWNoYSBhIHN0cmluZy4KICAgICAgICAgICAgICAgIGJhcnJhcyA9
REM IDAKICAgICAgICAgICAgICAgIGogPSBpIC0gMQogICAgICAgICAgICAgICAgd2hpbGUgaiA+
REM PSBwb3MgYW5kIHRleHRbal0gPT0gJ1xcJzoKICAgICAgICAgICAgICAgICAgICBiYXJyYXMg
REM Kz0gMQogICAgICAgICAgICAgICAgICAgIGogLT0gMQogICAgICAgICAgICAgICAgaWYgYmFy
REM cmFzICUgMiA9PSAwOgogICAgICAgICAgICAgICAgICAgIHJldHVybiBpICsgMywgVHJ1ZQog
REM ICAgICAgICAgICBpICs9IDEKICAgICAgICByZXR1cm4gLTEsIFRydWUKCiAgICBpID0gcG9z
REM ICsgMQogICAgZXNjID0gRmFsc2UKICAgIHdoaWxlIGkgPCBsZW4odGV4dCk6CiAgICAgICAg
REM Y2ggPSB0ZXh0W2ldCiAgICAgICAgaWYgZXNjOgogICAgICAgICAgICBlc2MgPSBGYWxzZQog
REM ICAgICAgIGVsaWYgY2ggPT0gJ1xcJzoKICAgICAgICAgICAgZXNjID0gVHJ1ZQogICAgICAg
REM IGVsaWYgY2ggPT0gcXVvdGU6CiAgICAgICAgICAgIHJldHVybiBpICsgMSwgRmFsc2UKICAg
REM ICAgICBlbGlmIGNoIGluICdcclxuJzoKICAgICAgICAgICAgcmV0dXJuIC0xLCBGYWxzZQog
REM ICAgICAgIGkgKz0gMQogICAgcmV0dXJuIC0xLCBGYWxzZQoKCmRlZiBfZmluZF9tYXRjaGlu
REM Z19wYXJlbl9weXRob24odGV4dCwgb3Blbl9wb3MpOgogICAgIiIiRW5jb250cmEgbyAnKScg
REM Y29ycmVzcG9uZGVudGUgcmVzcGVpdGFuZG8gc3RyaW5ncyBzaW1wbGVzL3RyaXBsYXMgZSBj
REM b21lbnTDoXJpb3MuIiIiCiAgICBpZiBvcGVuX3BvcyA8IDAgb3Igb3Blbl9wb3MgPj0gbGVu
REM KHRleHQpIG9yIHRleHRbb3Blbl9wb3NdICE9ICcoJzoKICAgICAgICByZXR1cm4gLTEKICAg
REM IGRlcHRoID0gMAogICAgaSA9IG9wZW5fcG9zCiAgICB3aGlsZSBpIDwgbGVuKHRleHQpOgog
REM ICAgICAgIGNoID0gdGV4dFtpXQogICAgICAgIGlmIGNoIGluICgnIicsICInIik6CiAgICAg
REM ICAgICAgIGZpbSwgXyA9IF9wYXJzZV9weXRob25fc3RyaW5nX2F0KHRleHQsIGkpCiAgICAg
REM ICAgICAgIGlmIGZpbSA8IDA6CiAgICAgICAgICAgICAgICByZXR1cm4gLTEKICAgICAgICAg
REM ICAgaSA9IGZpbQogICAgICAgICAgICBjb250aW51ZQogICAgICAgIGlmIGNoID09ICcjJzoK
REM ICAgICAgICAgICAgbmwgPSB0ZXh0LmZpbmQoJ1xuJywgaSkKICAgICAgICAgICAgaSA9IGxl
REM bih0ZXh0KSBpZiBubCA8IDAgZWxzZSBubCArIDEKICAgICAgICAgICAgY29udGludWUKICAg
REM ICAgICBpZiBjaCA9PSAnKCc6CiAgICAgICAgICAgIGRlcHRoICs9IDEKICAgICAgICBlbGlm
REM IGNoID09ICcpJzoKICAgICAgICAgICAgZGVwdGggLT0gMQogICAgICAgICAgICBpZiBkZXB0
REM aCA9PSAwOgogICAgICAgICAgICAgICAgcmV0dXJuIGkKICAgICAgICBpICs9IDEKICAgIHJl
REM dHVybiAtMQoKCmRlZiBfb2Zmc2V0c19kZV9saW5oYXMobGluaGFzX3Jhdyk6CiAgICBvZmZz
REM ZXRzID0gW10KICAgIGF0dWFsID0gMAogICAgZm9yIGxpbmhhIGluIGxpbmhhc19yYXc6CiAg
REM ICAgICAgb2Zmc2V0cy5hcHBlbmQoYXR1YWwpCiAgICAgICAgYXR1YWwgKz0gbGVuKGxpbmhh
REM KQogICAgb2Zmc2V0cy5hcHBlbmQoYXR1YWwpCiAgICByZXR1cm4gb2Zmc2V0cwoKCmRlZiBf
REM bGluaGFfZV9jb2x1bmFfcG9yX29mZnNldChvZmZzZXRzLCBvZmZzZXQpOgogICAgIyBCdXNj
REM YSBsaW5lYXIgw6kgc3VmaWNpZW50ZSBhcXVpOiBzw7Mgw6kgdXNhZGEgcGFyYSBhcyBlbnRy
REM YWRhcyBlc3BlY2lhaXMgZGUgcG9lbWFzLgogICAgbG8sIGhpID0gMCwgbGVuKG9mZnNldHMp
REM IC0gMQogICAgd2hpbGUgbG8gKyAxIDwgaGk6CiAgICAgICAgbWVpbyA9IChsbyArIGhpKSAv
REM LyAyCiAgICAgICAgaWYgb2Zmc2V0c1ttZWlvXSA8PSBvZmZzZXQ6CiAgICAgICAgICAgIGxv
REM ID0gbWVpbwogICAgICAgIGVsc2U6CiAgICAgICAgICAgIGhpID0gbWVpbwogICAgcmV0dXJu
REM IGxvICsgMSwgb2Zmc2V0IC0gb2Zmc2V0c1tsb10KCgpkZWYgX2FjaGFyX2ZlY2hvX2FzcGFz
REM X21lc21hX2xpbmhhKGxpbmhhLCBwb3MsIHF1b3RlKToKICAgIGkgPSBwb3MgKyAxCiAgICB3
REM aGlsZSBpIDwgbGVuKGxpbmhhKToKICAgICAgICBpZiBsaW5oYVtpXSA9PSAiXFwiOgogICAg
REM ICAgICAgICBpICs9IDIKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpZiBsaW5oYVtp
REM XSA9PSBxdW90ZToKICAgICAgICAgICAgcmV0dXJuIGkKICAgICAgICBpICs9IDEKICAgIHJl
REM dHVybiAtMQoKCmRlZiBfcHJlZml4b19wYXJlY2VfdGV4dG9fbXVsdGlsaW5oYShwcmVmaXhv
REM KToKICAgIHAgPSBwcmVmaXhvLnN0cmlwKCkKICAgIGlmIG5vdCBwOgogICAgICAgIHJldHVy
REM biBUcnVlCiAgICBpZiBhbnkoY2ggaW4gcCBmb3IgY2ggaW4gKCc9JywgJygnLCAnKScsICdb
REM JywgJ10nLCAneycsICd9JywgJzonKSk6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBiYWl4
REM b3MgPSBwLmxvd2VyKCkKICAgIHByb2liaWRvcyA9ICgKICAgICAgICAnbGFiZWwgJywgJ2p1
REM bXAgJywgJ2NhbGwgJywgJ3JldHVybiAnLCAnZGVmaW5lICcsICdkZWZhdWx0ICcsICdpbml0
REM ICcsCiAgICAgICAgJ3B5dGhvbiAnLCAnc2NyZWVuICcsICd0cmFuc2Zvcm0gJywgJ3N0eWxl
REM ICcsICdpbWFnZSAnLCAnc2NlbmUgJywKICAgICAgICAnc2hvdyAnLCAnaGlkZSAnLCAncGxh
REM eSAnLCAnc3RvcCAnLCAncXVldWUgJywgJ3ZvaWNlICcsICd3aXRoICcsCiAgICAgICAgJ2Nh
REM bWVyYSAnLCAnbGF5ZXJlZGltYWdlICcsICdyZW5weS4nLCAnY29uZmlnLicsICdndWkuJywg
REM JyQnLAogICAgKQogICAgaWYgYmFpeG9zLnN0YXJ0c3dpdGgocHJvaWJpZG9zKToKICAgICAg
REM ICByZXR1cm4gRmFsc2UKICAgIHBhbGF2cmFzID0gcmUuZmluZGFsbChyJ1tBLVphLXpfXVtB
REM LVphLXowLTlfLi1dKicsIHApCiAgICBpZiBub3QgcGFsYXZyYXMgb3IgbGVuKHBhbGF2cmFz
REM KSA+IDEyOgogICAgICAgIHJldHVybiBGYWxzZQogICAgaWYgYW55KHgubG93ZXIoKSBpbiAo
REM J3RleHQnLCAnY2FwdGlvbicsICdtZXNzYWdlJywgJ3RpdGxlJywgJ2Rlc2NyaXB0aW9uJywg
REM J2ZvbnQnLCAnY29sb3InKSBmb3IgeCBpbiBwYWxhdnJhc1s6LTFdKToKICAgICAgICByZXR1
REM cm4gRmFsc2UKICAgIHJldHVybiBUcnVlCgoKZGVmIF9yZWdpc3RyYXJfZnJhZ21lbnRvX211
REM bHRpbGluaGEocG9yX2xpbmhhLCBudW1lcm8sIGxpbmhhLCBpbmljaW8sIGZpbSwgY29udGV4
REM dG8pOgogICAgaW5pY2lvID0gbWF4KDAsIGluaWNpbykKICAgIGZpbSA9IG1pbihsZW4obGlu
REM aGEpLCBmaW0pCiAgICB3aGlsZSBpbmljaW8gPCBmaW0gYW5kIGxpbmhhW2luaWNpb10gaW4g
REM JyBcdCc6CiAgICAgICAgaW5pY2lvICs9IDEKICAgIHdoaWxlIGZpbSA+IGluaWNpbyBhbmQg
REM bGluaGFbZmltIC0gMV0gaW4gJyBcdCc6CiAgICAgICAgZmltIC09IDEKICAgIGlmIGluaWNp
REM byA+PSBmaW06CiAgICAgICAgcmV0dXJuCiAgICB0ZXh0byA9IGxpbmhhW2luaWNpbzpmaW1d
REM CiAgICBpZiBub3QgdGV4dG8uc3RyaXAoKToKICAgICAgICByZXR1cm4KICAgIGxpdGVyYWwg
REM PSBjb2RpZmljYXJfbGl0ZXJhbF90cmFkdWNhbyh0ZXh0bykKICAgIGlmIG5vdCB0ZW1fY29u
REM dGV1ZG9fdHJhZHV6aXZlbChsaXRlcmFsKToKICAgICAgICByZXR1cm4KICAgIHBvcl9saW5o
REM YS5zZXRkZWZhdWx0KG51bWVybywgW10pLmFwcGVuZCh7CiAgICAgICAgJ2NvbHVuYV9pbmlj
REM aW8nOiBpbmljaW8sCiAgICAgICAgJ2NvbHVuYV9maW0nOiBmaW0sCiAgICAgICAgJ29yaWdp
REM bmFsJzogdGV4dG8sCiAgICAgICAgJ3RyZWNobyc6IGxpdGVyYWwsCiAgICAgICAgJ3RpcG8n
REM OiAnbXVsdGlsaW5oYV9yZW5weScsCiAgICAgICAgJ2NvbmZpYW5jYSc6IDEwMCwKICAgICAg
REM ICAnY29udGV4dG8nOiBjb250ZXh0bywKICAgIH0pCgoKZGVmIF9laF9hcnF1aXZvX2JhbmNv
REM X3BvZW1hc19weXRob24oY2FtaW5obyk6CiAgICAiIiJSZXRvcm5hIFRydWUgcGFyYSBvIGJh
REM bmNvIFB5dGhvbiBwcmluY2lwYWwgZGUgcG9lbWFzLiIiIgogICAgcmVsID0gKGNhbWluaG8g
REM b3IgdScnKS5yZXBsYWNlKCdcXCcsICcvJykubG93ZXIoKQogICAgYmFzZSA9IG9zLnBhdGgu
REM YmFzZW5hbWUocmVsKQogICAgcmV0dXJuICgnL3BvZW1fcmVzcG9uc2VzL3B5LycgaW4gcmVs
REM IGFuZCBiYXNlIGluICgncG9lbXMucnB5JywgJ3BvZW1zX3Jlbi5weScpKQoKZGVmIGV4dHJh
REM aXJfc3RyaW5nc19tdWx0aWxpbmhhX3JlbnB5KGNhbWluaG8sIGxpbmhhc19yYXcsIGxpbmhh
REM c19weXRob249Tm9uZSwgbGluaGFzX2Jsb2Nvc190ZWNuaWNvcz1Ob25lKToKICAgIGxpbmhh
REM c19weXRob24gPSBsaW5oYXNfcHl0aG9uIG9yIHNldCgpCiAgICBsaW5oYXNfYmxvY29zX3Rl
REM Y25pY29zID0gbGluaGFzX2Jsb2Nvc190ZWNuaWNvcyBvciBzZXQoKQogICAgY2FtaW5ob19u
REM b3JtID0gY2FtaW5oby5yZXBsYWNlKCdcXCcsICcvJykubG93ZXIoKQogICAgYmFzZSA9IG9z
REM LnBhdGguYmFzZW5hbWUoY2FtaW5ob19ub3JtKQogICAgIyBPIHBhcnNlciBzZW3Dom50aWNv
REM IGRlIHBvZW1hcyDDqSBvIGRvbm8gZGUgcG9lbXMucnB5L3BvZW1zX3Jlbi5weS4KICAgICMg
REM TyBkZXRlY3RvciBnZW7DqXJpY28gbsOjbyBkZXZlIGNhcHR1cmFyIGFkZF9wb2VtL3RpdGxl
REM L3RleHQgY29tbyBkacOhbG9nby4KICAgIGlmICgoJy9wb2VtX3Jlc3BvbnNlcy8nIGluIGNh
REM bWluaG9fbm9ybSBhbmQgYmFzZSBpbiAoJ3BvZW1zLnJweScsICdwb2Vtc19yZW4ucHknKSkK
REM ICAgICAgICAgICAgb3IgJy9weS8nIGluIGNhbWluaG9fbm9ybSBvciBjYW1pbmhvX25vcm0u
REM ZW5kc3dpdGgoJy9weScpKToKICAgICAgICByZXR1cm4ge30sIHNldCgpCiAgICBwb3JfbGlu
REM aGEgPSB7fQogICAgbGluaGFzX2Vudm9sdmlkYXMgPSBzZXQoKQogICAgYXRpdm8gPSBOb25l
REM CgogICAgZm9yIGlkeCwgcmF3IGluIGVudW1lcmF0ZShsaW5oYXNfcmF3LCAxKToKICAgICAg
REM ICBsaW5oYSA9IHJhdy5yc3RyaXAoJ1xyXG4nKQogICAgICAgIGlmIGlkeCBpbiBsaW5oYXNf
REM cHl0aG9uIG9yIGlkeCBpbiBsaW5oYXNfYmxvY29zX3RlY25pY29zOgogICAgICAgICAgICBj
REM b250aW51ZQoKICAgICAgICBpZiBhdGl2byBpcyBub3QgTm9uZToKICAgICAgICAgICAgcXVv
REM dGUgPSBhdGl2b1sncXVvdGUnXQogICAgICAgICAgICBmZWNoYW1lbnRvID0gX2FjaGFyX2Zl
REM Y2hvX2FzcGFzX21lc21hX2xpbmhhKGxpbmhhLCAtMSwgcXVvdGUpIGlmIGxpbmhhIGVsc2Ug
REM LTEKICAgICAgICAgICAgbGluaGFzX2Vudm9sdmlkYXMuYWRkKGlkeCkKICAgICAgICAgICAg
REM aWYgZmVjaGFtZW50byA+PSAwOgogICAgICAgICAgICAgICAgX3JlZ2lzdHJhcl9mcmFnbWVu
REM dG9fbXVsdGlsaW5oYShwb3JfbGluaGEsIGlkeCwgbGluaGEsIDAsIGZlY2hhbWVudG8sIGF0
REM aXZvWydjb250ZXh0byddKQogICAgICAgICAgICAgICAgYXRpdm8gPSBOb25lCiAgICAgICAg
REM ICAgIGVsc2U6CiAgICAgICAgICAgICAgICBfcmVnaXN0cmFyX2ZyYWdtZW50b19tdWx0aWxp
REM bmhhKHBvcl9saW5oYSwgaWR4LCBsaW5oYSwgMCwgbGVuKGxpbmhhKSwgYXRpdm9bJ2NvbnRl
REM eHRvJ10pCiAgICAgICAgICAgIGNvbnRpbnVlCgogICAgICAgIGlmIG5vdCBsaW5oYS5zdHJp
REM cCgpIG9yIGxpbmhhLmxzdHJpcCgpLnN0YXJ0c3dpdGgoJyMnKToKICAgICAgICAgICAgY29u
REM dGludWUKCiAgICAgICAgaSA9IDAKICAgICAgICBhYmVydHVyYV9lbmNvbnRyYWRhID0gTm9u
REM ZQogICAgICAgIHdoaWxlIGkgPCBsZW4obGluaGEpOgogICAgICAgICAgICBpZiBsaW5oYVtp
REM XSA9PSAiXFwiOgogICAgICAgICAgICAgICAgaSArPSAyCiAgICAgICAgICAgICAgICBjb250
REM aW51ZQogICAgICAgICAgICBpZiBsaW5oYS5zdGFydHN3aXRoKCciIiInLCBpKSBvciBsaW5o
REM YS5zdGFydHN3aXRoKCInJyciLCBpKToKICAgICAgICAgICAgICAgIGkgKz0gMwogICAgICAg
REM ICAgICAgICAgY29udGludWUKICAgICAgICAgICAgaWYgbGluaGFbaV0gaW4gKCciJywgIici
REM KToKICAgICAgICAgICAgICAgIHEgPSBsaW5oYVtpXQogICAgICAgICAgICAgICAgZmVjaGFt
REM ZW50byA9IF9hY2hhcl9mZWNob19hc3Bhc19tZXNtYV9saW5oYShsaW5oYSwgaSwgcSkKICAg
REM ICAgICAgICAgICAgIGlmIGZlY2hhbWVudG8gPj0gMDoKICAgICAgICAgICAgICAgICAgICBp
REM ID0gZmVjaGFtZW50byArIDEKICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAg
REM ICAgICAgICAgaWYgX3ByZWZpeG9fcGFyZWNlX3RleHRvX211bHRpbGluaGEobGluaGFbOmld
REM KToKICAgICAgICAgICAgICAgICAgICBhYmVydHVyYV9lbmNvbnRyYWRhID0gKGksIHEpCiAg
REM ICAgICAgICAgICAgICAgICAgYnJlYWsKICAgICAgICAgICAgaSArPSAxCiAgICAgICAgaWYg
REM YWJlcnR1cmFfZW5jb250cmFkYSBpcyBOb25lOgogICAgICAgICAgICBjb250aW51ZQoKICAg
REM ICAgICBwb3MsIHF1b3RlID0gYWJlcnR1cmFfZW5jb250cmFkYQogICAgICAgIGNvbnRleHRv
REM ID0gdSJNdWx0aWxpbmhhIFJlbidQeTogIiArICh1J2ZhbGEnIGlmIGxpbmhhWzpwb3NdLnN0
REM cmlwKCkgZWxzZSB1J25hcnJhdGl2YScpCiAgICAgICAgX3JlZ2lzdHJhcl9mcmFnbWVudG9f
REM bXVsdGlsaW5oYShwb3JfbGluaGEsIGlkeCwgbGluaGEsIHBvcyArIDEsIGxlbihsaW5oYSks
REM IGNvbnRleHRvKQogICAgICAgIGxpbmhhc19lbnZvbHZpZGFzLmFkZChpZHgpCiAgICAgICAg
REM YXRpdm8gPSB7J3F1b3RlJzogcXVvdGUsICdjb250ZXh0byc6IGNvbnRleHRvfQoKICAgIHJl
REM dHVybiBwb3JfbGluaGEsIGxpbmhhc19lbnZvbHZpZGFzCgpkZWYgZXh0cmFpcl9jb3Jwb3Nf
REM cG9lbWFzKGNhbWluaG8sIGxpbmhhc19yYXcpOgogICAgIiIiRXh0cmFpIGNvcnBvcyB0ZXh0
REM dWFpcyBtdWx0aWxpbmhhIGRlIHBvZW1hcyBlIGNvbnN0cnXDp8O1ZXMgZGUgdHJhZHXDp8Oj
REM byBleHBsw61jaXRhLgoKICAgIFN1cG9ydGEgdGFudG8gcG9lbV9kYi5hZGRfcG9lbSgpL1Bv
REM ZW0oLi4uKSBxdWFudG8gbyBmb3JtYXRvIGNvbXVtCiAgICBgdGV4dD1fKClgL2B0ZXh0PV8o
REM c3RyaW5nIHRyaXBsYSlgIHVzYWRvIHBvciBtb2RzIGFudGlnb3MgZSBtb2Rlcm5vcy4KICAg
REM IENhZGEgbGluaGEgZsOtc2ljYSByZWNlYmUgdW1hIGVudHJhZGEgcHLDs3ByaWEgbm8gbWFw
REM YSBwYXJhIHByZXNlcnZhciBhCiAgICBlc3RydXR1cmEgbmVjZXNzw6FyaWEgw6AgcmVpbmpl
REM w6fDo28uCiAgICAiIiIKICAgIGNhbWluaG9fbm9ybSA9IGNhbWluaG8ucmVwbGFjZSgnXFwn
REM LCAnLycpLmxvd2VyKCkKICAgIGJhc2UgPSBvcy5wYXRoLmJhc2VuYW1lKGNhbWluaG9fbm9y
REM bSkKICAgIGlmIGJhc2Ugbm90IGluICgncG9lbXMucnB5JywgJ3BvZW1zX3Jlbi5weScpIGFu
REM ZCAnL3BvZW1fcmVzcG9uc2VzLycgbm90IGluIGNhbWluaG9fbm9ybToKICAgICAgICByZXR1
REM cm4ge30sIHNldCgpCiAgICBpZiBiYXNlID09IFBPRU1SRVNQT05TRVNfQkFTRV9OQU1FOgog
REM ICAgICAgIHJldHVybiB7fSwgc2V0KCkKCiAgICBjb250ZXVkbyA9IHUnJy5qb2luKGxpbmhh
REM c19yYXcpCiAgICBvZmZzZXRzID0gX29mZnNldHNfZGVfbGluaGFzKGxpbmhhc19yYXcpCiAg
REM ICBwb3JfbGluaGEgPSB7fQogICAgYmxvcXVlaW9zID0gc2V0KCkKCiAgICBkZWYgYWRpY2lv
REM bmFyX3RpdHVsb19saXRlcmFsKGFic19hcmdzX2luaWNpbywgYXJnc190ZXh0LCBjb250ZXh0
REM bz11J3TDrXR1bG8gZG8gcG9lbWEnKToKICAgICAgICBtX3RpdGxlID0gcmUuc2VhcmNoKHIn
REM XGJ0aXRsZVxzKj1ccyooIig/OlxcLnxbXiJcXF0pKiJ8XCcoPzpcXC58W15cJ1xcXSkqXCcp
REM JywgYXJnc190ZXh0LCByZS5JKQogICAgICAgIGlmIG5vdCBtX3RpdGxlOgogICAgICAgICAg
REM ICByZXR1cm4KICAgICAgICBsaXRlcmFsID0gbV90aXRsZS5ncm91cCgxKQogICAgICAgIGFi
REM c19saXRlcmFsID0gYWJzX2FyZ3NfaW5pY2lvICsgbV90aXRsZS5zdGFydCgxKQogICAgICAg
REM IGxpbmhhX251bSA9IGNvbnRldWRvLmNvdW50KCdcbicsIDAsIGFic19saXRlcmFsKSArIDEK
REM ICAgICAgICBpbmljaW9fbGluaGEgPSBjb250ZXVkby5yZmluZCgnXG4nLCAwLCBhYnNfbGl0
REM ZXJhbCkgKyAxCiAgICAgICAgY29sX2luaWNpbyA9IGFic19saXRlcmFsIC0gaW5pY2lvX2xp
REM bmhhCiAgICAgICAgcG9yX2xpbmhhLnNldGRlZmF1bHQobGluaGFfbnVtLCBbXSkuYXBwZW5k
REM KHsKICAgICAgICAgICAgJ2NvbHVuYV9pbmljaW8nOiBjb2xfaW5pY2lvLAogICAgICAgICAg
REM ICAnY29sdW5hX2ZpbSc6IGNvbF9pbmljaW8gKyBsZW4obGl0ZXJhbCksCiAgICAgICAgICAg
REM ICdvcmlnaW5hbCc6IGxpdGVyYWwsCiAgICAgICAgICAgICd0cmVjaG8nOiBsaXRlcmFsLAog
REM ICAgICAgICAgICAndGlwbyc6ICdwb2VtYV90aXR1bG8nLAogICAgICAgICAgICAnY29uZmlh
REM bmNhJzogMTAwLAogICAgICAgICAgICAnY29udGV4dG8nOiBjb250ZXh0bywKICAgICAgICB9
REM KQoKICAgIHRleHRfcmUgPSByZS5jb21waWxlKAogICAgICAgIHInXGJ0ZXh0XHMqPVxzKig/
REM Oig/Ol98X198X19ffF9wKVxzKlwoXHMqKT8oPzpyXHMqKT8oP1A8cXVvdGU+InszfXxcJ3sz
REM fXwifFwnKScsCiAgICAgICAgcmUuSQogICAgKQogICAgdHJhbnNsYXRlX3JlID0gcmUuY29t
REM cGlsZShyJ1xidHJhbnNsYXRlXHMqPVxzKignICsgUVNUUiArIHInKScsIHJlLkkpCiAgICBp
REM ZGVudF9yZSA9IHJlLmNvbXBpbGUocidcYig/OnBvZW1fZGJccypcLlxzKik/YWRkX3BvZW1c
REM cypcKFxzKignICsgUVNUUiArIHInKScsIHJlLkkpCgogICAgZGVmIGFkaWNpb25hcl9jb3Jw
REM byhhYnNfdmFsb3IsIGZpbV9zdHJpbmcsIGlkZW50aWZpY2Fkb3IsIHRpcG89J3BvZW1hX2Nv
REM cnBvJywgY29udGV4dG9fcHJlZml4bz11J2NvcnBvIGRvIHBvZW1hICcpOgogICAgICAgIGlm
REM IGZpbV9zdHJpbmcgPCAwOgogICAgICAgICAgICByZXR1cm4KICAgICAgICBtX3F1b3RlID0g
REM Y29udGV1ZG9bYWJzX3ZhbG9yOmFic192YWxvciArIDNdCiAgICAgICAgaWYgbV9xdW90ZSBu
REM b3QgaW4gKCciIiInLCAiJycnIik6CiAgICAgICAgICAgIHJldHVybgogICAgICAgIGluaWNp
REM b19jb250ZXVkbyA9IGFic192YWxvciArIDMKICAgICAgICBpZiBpbmljaW9fY29udGV1ZG8g
REM PCBmaW1fc3RyaW5nIGFuZCBjb250ZXVkb1tpbmljaW9fY29udGV1ZG9dID09ICdcXCc6CiAg
REM ICAgICAgICAgIGlmIGNvbnRldWRvLnN0YXJ0c3dpdGgoJ1xcXHJcbicsIGluaWNpb19jb250
REM ZXVkbyk6CiAgICAgICAgICAgICAgICBpbmljaW9fY29udGV1ZG8gKz0gMwogICAgICAgICAg
REM ICBlbGlmIGNvbnRldWRvLnN0YXJ0c3dpdGgoJ1xcXG4nLCBpbmljaW9fY29udGV1ZG8pOgog
REM ICAgICAgICAgICAgICAgaW5pY2lvX2NvbnRldWRvICs9IDIKICAgICAgICBmaW1fY29udGV1
REM ZG8gPSBmaW1fc3RyaW5nIC0gMwogICAgICAgIGlmIGluaWNpb19jb250ZXVkbyA+PSBmaW1f
REM Y29udGV1ZG86CiAgICAgICAgICAgIHJldHVybgogICAgICAgIGZvciBudW1lcm8sIGluaWNp
REM b19saW5oYSBpbiBlbnVtZXJhdGUob2Zmc2V0c1s6LTFdLCAxKToKICAgICAgICAgICAgZmlt
REM X2xpbmhhID0gb2Zmc2V0c1tudW1lcm9dCiAgICAgICAgICAgIGluaWNpbyA9IG1heChpbmlj
REM aW9fY29udGV1ZG8sIGluaWNpb19saW5oYSkKICAgICAgICAgICAgZmltID0gbWluKGZpbV9j
REM b250ZXVkbywgZmltX2xpbmhhKQogICAgICAgICAgICBpZiBpbmljaW8gPj0gZmltOgogICAg
REM ICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgbGluaGFfc2VtX2ZpbSA9IGxpbmhh
REM c19yYXdbbnVtZXJvIC0gMV0ucnN0cmlwKCdcclxuJykKICAgICAgICAgICAgbGltID0gbWlu
REM KGZpbSwgaW5pY2lvX2xpbmhhICsgbGVuKGxpbmhhX3NlbV9maW0pKQogICAgICAgICAgICBp
REM ZiBsaW0gPD0gaW5pY2lvOgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAg
REM cmF3ID0gY29udGV1ZG9baW5pY2lvOmxpbV0KICAgICAgICAgICAgaWYgcmF3LmVuZHN3aXRo
REM KCdcXCcpOgogICAgICAgICAgICAgICAgbGltIC09IDEKICAgICAgICAgICAgICAgIHJhdyA9
REM IHJhd1s6LTFdCiAgICAgICAgICAgIGlmIG5vdCByYXcuc3RyaXAoKToKICAgICAgICAgICAg
REM ICAgIGNvbnRpbnVlCiAgICAgICAgICAgIGNvbF9pbmljaW8gPSBpbmljaW8gLSBpbmljaW9f
REM bGluaGEKICAgICAgICAgICAgY29sX2ZpbSA9IGxpbSAtIGluaWNpb19saW5oYQogICAgICAg
REM ICAgICBwb3JfbGluaGEuc2V0ZGVmYXVsdChudW1lcm8sIFtdKS5hcHBlbmQoewogICAgICAg
REM ICAgICAgICAgJ2NvbHVuYV9pbmljaW8nOiBjb2xfaW5pY2lvLAogICAgICAgICAgICAgICAg
REM J2NvbHVuYV9maW0nOiBjb2xfZmltLAogICAgICAgICAgICAgICAgJ29yaWdpbmFsJzogcmF3
REM LAogICAgICAgICAgICAgICAgJ3RyZWNobyc6IGpzb24uZHVtcHMocmF3LCBlbnN1cmVfYXNj
REM aWk9RmFsc2UpLAogICAgICAgICAgICAgICAgJ3RpcG8nOiB0aXBvLAogICAgICAgICAgICAg
REM ICAgJ2NvbmZpYW5jYSc6IDEwMCwKICAgICAgICAgICAgICAgICdjb250ZXh0byc6IGNvbnRl
REM eHRvX3ByZWZpeG8gKyBpZGVudGlmaWNhZG9yLAogICAgICAgICAgICB9KQoKICAgICMgQSkg
REM cG9lbV9kYi5hZGRfcG9lbSguLi4pIOKAlCB1c2FkbyBwb3IgYWxndW5zIHRlbXBsYXRlcy9t
REM b2RzLgogICAgYWRkX3JlID0gcmUuY29tcGlsZShyJ1xiKD86cG9lbV9kYlxzKlwuXHMqKT9h
REM ZGRfcG9lbVxzKlwoJywgcmUuSSkKICAgIGZvciBtX2NhbGwgaW4gYWRkX3JlLmZpbmRpdGVy
REM KGNvbnRldWRvKToKICAgICAgICBsaW5oYV9pbmljaW8gPSBjb250ZXVkby5yZmluZCgnXG4n
REM LCAwLCBtX2NhbGwuc3RhcnQoKSkgKyAxCiAgICAgICAgaWYgY29udGV1ZG9bbGluaGFfaW5p
REM Y2lvOm1fY2FsbC5zdGFydCgpXS5sc3RyaXAoKS5zdGFydHN3aXRoKCcjJyk6CiAgICAgICAg
REM ICAgIGNvbnRpbnVlCiAgICAgICAgYWJyZSA9IGNvbnRldWRvLmZpbmQoJygnLCBtX2NhbGwu
REM c3RhcnQoKSkKICAgICAgICBmZWNoYSA9IF9maW5kX21hdGNoaW5nX3BhcmVuX3B5dGhvbihj
REM b250ZXVkbywgYWJyZSkKICAgICAgICBpZiBmZWNoYSA8IDA6CiAgICAgICAgICAgIGNvbnRp
REM bnVlCiAgICAgICAgYXJncyA9IGNvbnRldWRvW2FicmUgKyAxOmZlY2hhXQogICAgICAgIGFk
REM aWNpb25hcl90aXR1bG9fbGl0ZXJhbChhYnJlICsgMSwgYXJncykKICAgICAgICBtX3RyYW5z
REM ID0gdHJhbnNsYXRlX3JlLnNlYXJjaChhcmdzKQogICAgICAgIG1vZG8gPSAnYWxsJwogICAg
REM ICAgIGlmIG1fdHJhbnM6CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIG1vZG8g
REM PSBhc3QubGl0ZXJhbF9ldmFsKG1fdHJhbnMuZ3JvdXAoMSkpCiAgICAgICAgICAgIGV4Y2Vw
REM dCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICBtb2RvID0gc3RyaXBfcXVvdGVzKG1fdHJh
REM bnMuZ3JvdXAoMSkpCiAgICAgICAgaWYgbW9kbyBub3QgaW4gKCdhbGwnLCAndGl0bGUnLCAn
REM dGV4dCcsICdub25lJyk6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgaWYgbW9kbyBp
REM biAoJ25vbmUnLCAndGl0bGUnKToKICAgICAgICAgICAgY29udGludWUKICAgICAgICBtX3Rl
REM eHQgPSB0ZXh0X3JlLnNlYXJjaChhcmdzKQogICAgICAgIGlmIG5vdCBtX3RleHQ6CiAgICAg
REM ICAgICAgIGNvbnRpbnVlCiAgICAgICAgYWJzX3ZhbG9yID0gYWJyZSArIDEgKyBtX3RleHQu
REM c3RhcnQoJ3F1b3RlJykKICAgICAgICBmaW1fc3RyaW5nLCBlaF90cmlwbG8gPSBfcGFyc2Vf
REM cHl0aG9uX3N0cmluZ19hdChjb250ZXVkbywgYWJzX3ZhbG9yKQogICAgICAgIGlmIG5vdCBl
REM aF90cmlwbG86CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgbV9pZCA9IGlkZW50X3Jl
REM Lm1hdGNoKGNvbnRldWRvW21fY2FsbC5zdGFydCgpOl0pCiAgICAgICAgaWRlbnRpZmljYWRv
REM ciA9IHN0cmlwX3F1b3RlcyhtX2lkLmdyb3VwKDEpKSBpZiBtX2lkIGVsc2UgdSdwb2VtYScK
REM ICAgICAgICBmb3IgX2l0ZW1zIGluIHBvcl9saW5oYS52YWx1ZXMoKToKICAgICAgICAgICAg
REM Zm9yIF9pdGVtIGluIF9pdGVtczoKICAgICAgICAgICAgICAgIGlmIF9pdGVtLmdldCgndGlw
REM bycpID09ICdwb2VtYV90aXR1bG8nIGFuZCBfaXRlbS5nZXQoJ2NvbnRleHRvJykgPT0gdSd0
REM w610dWxvIGRvIHBvZW1hJzoKICAgICAgICAgICAgICAgICAgICBfaXRlbVsnY29udGV4dG8n
REM XSA9IHUndMOtdHVsbyBkbyBwb2VtYSAnICsgaWRlbnRpZmljYWRvcgogICAgICAgIGFkaWNp
REM b25hcl9jb3JwbyhhYnNfdmFsb3IsIGZpbV9zdHJpbmcsIGlkZW50aWZpY2Fkb3IpCgogICAg
REM IyBCKSBDb25zdHJ1dG9yZXMgUG9lbSguLi4pIOKAlCBmb3JtYXRvIGNvbXVtIGVtIG1vZHMg
REM Y29tbyBJbnRlcmFjdGlvbi4KICAgIHBvZW1fY3Rvcl9yZSA9IHJlLmNvbXBpbGUocicoP20p
REM XlxzKihbQS1aYS16X11bQS1aYS16MC05X10qKVxzKj1ccypQb2VtXHMqXCgnKQogICAgZm9y
REM IG1fY3RvciBpbiBwb2VtX2N0b3JfcmUuZmluZGl0ZXIoY29udGV1ZG8pOgogICAgICAgIGxp
REM bmhhX2luaWNpbyA9IGNvbnRldWRvLnJmaW5kKCdcbicsIDAsIG1fY3Rvci5zdGFydCgpKSAr
REM IDEKICAgICAgICBpZiBjb250ZXVkb1tsaW5oYV9pbmljaW86bV9jdG9yLnN0YXJ0KCldLmxz
REM dHJpcCgpLnN0YXJ0c3dpdGgoJyMnKToKICAgICAgICAgICAgY29udGludWUKICAgICAgICBh
REM YnJlID0gY29udGV1ZG8uZmluZCgnKCcsIG1fY3Rvci5zdGFydCgpKQogICAgICAgIGZlY2hh
REM ID0gX2ZpbmRfbWF0Y2hpbmdfcGFyZW5fcHl0aG9uKGNvbnRldWRvLCBhYnJlKQogICAgICAg
REM IGlmIGZlY2hhIDwgMDoKICAgICAgICAgICAgY29udGludWUKICAgICAgICBibG9jbyA9IGNv
REM bnRldWRvW21fY3Rvci5zdGFydCgpOmZlY2hhICsgMV0KICAgICAgICBtX3RleHQgPSB0ZXh0
REM X3JlLnNlYXJjaChibG9jbykKICAgICAgICBpZiBub3QgbV90ZXh0OgogICAgICAgICAgICBj
REM b250aW51ZQogICAgICAgIGFic192YWxvciA9IG1fY3Rvci5zdGFydCgpICsgbV90ZXh0LnN0
REM YXJ0KCdxdW90ZScpCiAgICAgICAgZmltX3N0cmluZywgZWhfdHJpcGxvID0gX3BhcnNlX3B5
REM dGhvbl9zdHJpbmdfYXQoY29udGV1ZG8sIGFic192YWxvcikKICAgICAgICBpZiBub3QgZWhf
REM dHJpcGxvOgogICAgICAgICAgICBjb250aW51ZQogICAgICAgIG1fdGl0bGUgPSByZS5zZWFy
REM Y2gocicoP20pXlxzKnRpdGxlXHMqPVxzKihbIlwnXSkoLio/KVwxXHMqLD9ccyokJywgYmxv
REM Y28pCiAgICAgICAgdGl0dWxvID0gbV90aXRsZS5ncm91cCgyKSBpZiBtX3RpdGxlIGVsc2Ug
REM dScnCiAgICAgICAgaWYgbV90aXRsZToKICAgICAgICAgICAgYWJzX2xpdGVyYWwgPSBtX2N0
REM b3Iuc3RhcnQoKSArIG1fdGl0bGUuc3RhcnQoMSkKICAgICAgICAgICAgbGl0ZXJhbCA9IG1f
REM dGl0bGUuZ3JvdXAoMSkgKyBtX3RpdGxlLmdyb3VwKDIpICsgbV90aXRsZS5ncm91cCgxKQog
REM ICAgICAgICAgICBsaW5oYV9udW0gPSBjb250ZXVkby5jb3VudCgnXG4nLCAwLCBhYnNfbGl0
REM ZXJhbCkgKyAxCiAgICAgICAgICAgIGluaWNpb19saW5oYSA9IGNvbnRldWRvLnJmaW5kKCdc
REM bicsIDAsIGFic19saXRlcmFsKSArIDEKICAgICAgICAgICAgY29sX2luaWNpbyA9IGFic19s
REM aXRlcmFsIC0gaW5pY2lvX2xpbmhhCiAgICAgICAgICAgIHBvcl9saW5oYS5zZXRkZWZhdWx0
REM KGxpbmhhX251bSwgW10pLmFwcGVuZCh7CiAgICAgICAgICAgICAgICAnY29sdW5hX2luaWNp
REM byc6IGNvbF9pbmljaW8sCiAgICAgICAgICAgICAgICAnY29sdW5hX2ZpbSc6IGNvbF9pbmlj
REM aW8gKyBsZW4obGl0ZXJhbCksCiAgICAgICAgICAgICAgICAnb3JpZ2luYWwnOiBsaXRlcmFs
REM LAogICAgICAgICAgICAgICAgJ3RyZWNobyc6IGxpdGVyYWwsCiAgICAgICAgICAgICAgICAn
REM dGlwbyc6ICdwb2VtYV90aXR1bG8nLAogICAgICAgICAgICAgICAgJ2NvbmZpYW5jYSc6IDEw
REM MCwKICAgICAgICAgICAgICAgICdjb250ZXh0byc6IHUndMOtdHVsbyBkZSBQb2VtICcgKyAo
REM bV9jdG9yLmdyb3VwKDEpIG9yIHUnJykKICAgICAgICAgICAgfSkKICAgICAgICBjb3Jwb19z
REM dGFydCA9IGFic192YWxvciArIDMKICAgICAgICBjb3Jwb19lbmQgPSBmaW1fc3RyaW5nIC0g
REM MwogICAgICAgIGNvcnBvID0gY29udGV1ZG9bY29ycG9fc3RhcnQ6Y29ycG9fZW5kXQogICAg
REM ICAgIGlmIGNvcnBvLnN0YXJ0c3dpdGgoJ1xcXHJcbicpOgogICAgICAgICAgICBjb3JwbyA9
REM IGNvcnBvWzM6XQogICAgICAgIGVsaWYgY29ycG8uc3RhcnRzd2l0aCgnXFxcbicpOgogICAg
REM ICAgICAgICBjb3JwbyA9IGNvcnBvWzI6XQogICAgICAgIGNvbXBhY3RfYjY0ID0gdScnLmpv
REM aW4oeCBmb3IgeCBpbiBjb3JwbyBpZiBub3QgeC5pc3NwYWNlKCkgYW5kIHggIT0gdSdcXCcp
REM CiAgICAgICAgYmFzZTY0X2VzcGVjaWFsID0gRmFsc2UKICAgICAgICBpZiBsZW4oY29tcGFj
REM dF9iNjQpID49IDMyIGFuZCBsZW4oY29tcGFjdF9iNjQpICUgNCA9PSAwIGFuZCByZS5mdWxs
REM bWF0Y2gocidbQS1aYS16MC05Ky89XSsnLCBjb21wYWN0X2I2NCk6CiAgICAgICAgICAgIHRy
REM eToKICAgICAgICAgICAgICAgIGJydXRvX2RlYyA9IGJhc2U2NC5iNjRkZWNvZGUoY29tcGFj
REM dF9iNjQsIHZhbGlkYXRlPVRydWUpCiAgICAgICAgICAgICAgICBkZWMgPSBicnV0b19kZWMu
REM ZGVjb2RlKCd1dGYtOCcpCiAgICAgICAgICAgICAgICBpbXByaW1pdmVpcyA9IHN1bSgxIGZv
REM ciBjaCBpbiBkZWMgaWYgY2guaXNwcmludGFibGUoKSBvciBjaCBpbiB1J1xyXG5cdCcpCiAg
REM ICAgICAgICAgICAgICBiYXNlNjRfZXNwZWNpYWwgPSBsZW4oZGVjKSA+PSAxMiBhbmQgZmxv
REM YXQoaW1wcmltaXZlaXMpIC8gbWF4KDEsIGxlbihkZWMpKSA+PSAwLjkyCiAgICAgICAgICAg
REM IGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICBiYXNlNjRfZXNwZWNpYWwgPSBG
REM YWxzZQogICAgICAgIGxpbmhhc19jb3JwbyA9IFt4IGZvciB4IGluIGNvcnBvLnNwbGl0bGlu
REM ZXMoKSBpZiB4LnN0cmlwKCldCiAgICAgICAgdmlyZ3VsYXNfZHVwbGFzID0gY29ycG8uY291
REM bnQodScsLCcpCiAgICAgICAgdG9rZW5zX2dsaXRjaCA9IHJlLmZpbmRhbGwocidcYltBLVph
REM LXpdezUsfVxiJywgY29ycG8pCiAgICAgICAgZ2xpdGNoX2VzcGVjaWFsID0gKAogICAgICAg
REM ICAgICB2aXJndWxhc19kdXBsYXMgPj0gOCBhbmQgbGVuKGxpbmhhc19jb3JwbykgPj0gMyBh
REM bmQKICAgICAgICAgICAgbGVuKHRva2Vuc19nbGl0Y2gpID49IDIwIGFuZAogICAgICAgICAg
REM ICBub3QgcmUuc2VhcmNoKHInWy4hP117Mix9fFxiKD86dGhlfHlvdXxpfG15fGFuZHxidXR8
REM dGhpc3x0aGF0KVxiJywgY29ycG8sIHJlLkkpCiAgICAgICAgKQogICAgICAgIGlmIGJhc2U2
REM NF9lc3BlY2lhbCBvciBnbGl0Y2hfZXNwZWNpYWw6CiAgICAgICAgICAgIGNvbnRpbnVlCiAg
REM ICAgICAgYWRpY2lvbmFyX2NvcnBvKGFic192YWxvciwgZmltX3N0cmluZywKICAgICAgICAg
REM ICAgICAgICAgICAgICAgbV9jdG9yLmdyb3VwKDEpICsgKHUnICgnICsgdGl0dWxvICsgdScp
REM JyBpZiB0aXR1bG8gZWxzZSB1JycpKQoKICAgIHJldHVybiBwb3JfbGluaGEsIGJsb3F1ZWlv
REM cwoKCmRlZiBleHRyYWlyX3N0cmluZ3NfZ2V0dGV4dF9tdWx0aWxpbmhhKGNhbWluaG8sIGxp
REM bmhhc19yYXcpOgogICAgIiIiRXh0cmFpIHN0cmluZ3MgdHJpcGxhcyB1c2FkYXMgZXhwbGlj
REM aXRhbWVudGUgZW0gXygpL19fKCkvX19fKCkvX3AoKS4iIiIKICAgIGJhc2UgPSBvcy5wYXRo
REM LmJhc2VuYW1lKGNhbWluaG8pLmxvd2VyKCkKICAgIGlmIGJhc2UgPT0gUE9FTVJFU1BPTlNF
REM U19CQVNFX05BTUU6CiAgICAgICAgcmV0dXJuIHt9LCBzZXQoKQogICAgY29udGV1ZG8gPSB1
REM Jycuam9pbihsaW5oYXNfcmF3KQogICAgb2Zmc2V0cyA9IF9vZmZzZXRzX2RlX2xpbmhhcyhs
REM aW5oYXNfcmF3KQogICAgcG9yX2xpbmhhID0ge30KICAgIGxpbmhhc19lbnZvbHZpZGFzID0g
REM c2V0KCkKICAgIHBhZHJhbyA9IHJlLmNvbXBpbGUoCiAgICAgICAgcicoPzwhW0EtWmEtejAt
REM OV8uXSkoPzpffF9ffF9fX3xfcClccypcKFxzKig/OnJccyopPyg/UDxxdW90ZT4iezN9fFwn
REM ezN9KScsCiAgICAgICAgcmUuSQogICAgKQogICAgZm9yIG0gaW4gcGFkcmFvLmZpbmRpdGVy
REM KGNvbnRldWRvKToKICAgICAgICBsaW5oYV9pbmljaW8gPSBjb250ZXVkby5yZmluZCgnXG4n
REM LCAwLCBtLnN0YXJ0KCkpICsgMQogICAgICAgIGlmIGNvbnRldWRvW2xpbmhhX2luaWNpbzpt
REM LnN0YXJ0KCldLmxzdHJpcCgpLnN0YXJ0c3dpdGgoJyMnKToKICAgICAgICAgICAgY29udGlu
REM dWUKICAgICAgICBhYnNfdmFsb3IgPSBtLnN0YXJ0KCdxdW90ZScpCiAgICAgICAgZmltX3N0
REM cmluZywgZWhfdHJpcGxvID0gX3BhcnNlX3B5dGhvbl9zdHJpbmdfYXQoY29udGV1ZG8sIGFi
REM c192YWxvcikKICAgICAgICBpZiBmaW1fc3RyaW5nIDwgMCBvciBub3QgZWhfdHJpcGxvOgog
REM ICAgICAgICAgICBjb250aW51ZQogICAgICAgIGluaWNpb19jb250ZXVkbyA9IGFic192YWxv
REM ciArIDMKICAgICAgICBpZiBpbmljaW9fY29udGV1ZG8gPCBmaW1fc3RyaW5nIGFuZCBjb250
REM ZXVkb1tpbmljaW9fY29udGV1ZG9dID09ICdcXCc6CiAgICAgICAgICAgIGlmIGNvbnRldWRv
REM LnN0YXJ0c3dpdGgoJ1xcXHJcbicsIGluaWNpb19jb250ZXVkbyk6CiAgICAgICAgICAgICAg
REM ICBpbmljaW9fY29udGV1ZG8gKz0gMwogICAgICAgICAgICBlbGlmIGNvbnRldWRvLnN0YXJ0
REM c3dpdGgoJ1xcXG4nLCBpbmljaW9fY29udGV1ZG8pOgogICAgICAgICAgICAgICAgaW5pY2lv
REM X2NvbnRldWRvICs9IDIKICAgICAgICBmaW1fY29udGV1ZG8gPSBmaW1fc3RyaW5nIC0gMwog
REM ICAgICAgIGlmIGluaWNpb19jb250ZXVkbyA+PSBmaW1fY29udGV1ZG86CiAgICAgICAgICAg
REM IGNvbnRpbnVlCiAgICAgICAgZ3JvdXAgPSBoYXNobGliLnNoYTI1NigoJyVzXDAlZCcgJSAo
REM Y2FtaW5obywgYWJzX3ZhbG9yKSkuZW5jb2RlKCd1dGYtOCcpKS5oZXhkaWdlc3QoKVs6MjBd
REM CiAgICAgICAgZm9yIG51bWVybywgaW5pY2lvX2xpbmhhIGluIGVudW1lcmF0ZShvZmZzZXRz
REM WzotMV0sIDEpOgogICAgICAgICAgICBmaW1fbGluaGEgPSBvZmZzZXRzW251bWVyb10KICAg
REM ICAgICAgICAgaW5pY2lvID0gbWF4KGluaWNpb19jb250ZXVkbywgaW5pY2lvX2xpbmhhKQog
REM ICAgICAgICAgICBmaW0gPSBtaW4oZmltX2NvbnRldWRvLCBmaW1fbGluaGEpCiAgICAgICAg
REM ICAgIGlmIGluaWNpbyA+PSBmaW06CiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAg
REM ICAgICBsaW5oYV9zZW1fZmltID0gbGluaGFzX3Jhd1tudW1lcm8gLSAxXS5yc3RyaXAoJ1xy
REM XG4nKQogICAgICAgICAgICBsaW0gPSBtaW4oZmltLCBpbmljaW9fbGluaGEgKyBsZW4obGlu
REM aGFfc2VtX2ZpbSkpCiAgICAgICAgICAgIGlmIGxpbSA8PSBpbmljaW86CiAgICAgICAgICAg
REM ICAgICBjb250aW51ZQogICAgICAgICAgICByYXcgPSBjb250ZXVkb1tpbmljaW86bGltXQog
REM ICAgICAgICAgICBpZiByYXcuZW5kc3dpdGgoJ1xcJyk6CiAgICAgICAgICAgICAgICBsaW0g
REM LT0gMQogICAgICAgICAgICAgICAgcmF3ID0gcmF3WzotMV0KICAgICAgICAgICAgaWYgbm90
REM IHJhdy5zdHJpcCgpOgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgY29s
REM X2luaWNpbyA9IGluaWNpbyAtIGluaWNpb19saW5oYQogICAgICAgICAgICBjb2xfZmltID0g
REM bGltIC0gaW5pY2lvX2xpbmhhCiAgICAgICAgICAgIHBvcl9saW5oYS5zZXRkZWZhdWx0KG51
REM bWVybywgW10pLmFwcGVuZCh7CiAgICAgICAgICAgICAgICAnY29sdW5hX2luaWNpbyc6IGNv
REM bF9pbmljaW8sCiAgICAgICAgICAgICAgICAnY29sdW5hX2ZpbSc6IGNvbF9maW0sCiAgICAg
REM ICAgICAgICAgICAnb3JpZ2luYWwnOiByYXcsCiAgICAgICAgICAgICAgICAndHJlY2hvJzog
REM anNvbi5kdW1wcyhyYXcsIGVuc3VyZV9hc2NpaT1GYWxzZSksCiAgICAgICAgICAgICAgICAn
REM dGlwbyc6ICdnZXR0ZXh0X211bHRpbGluaGEnLAogICAgICAgICAgICAgICAgJ2NvbmZpYW5j
REM YSc6IDEwMCwKICAgICAgICAgICAgICAgICdjb250ZXh0byc6IHUnc3RyaW5nIG11bHRpbGlu
REM aGEgZXhwbMOtY2l0YSBkZSB0cmFkdcOnw6NvIChfL19fL19wKScsCiAgICAgICAgICAgICAg
REM ICAnbG9naWNhbF9ncm91cF9oaW50JzogZ3JvdXAsCiAgICAgICAgICAgIH0pCiAgICAgICAg
REM ICAgIGxpbmhhc19lbnZvbHZpZGFzLmFkZChudW1lcm8pCiAgICByZXR1cm4gcG9yX2xpbmhh
REM LCBsaW5oYXNfZW52b2x2aWRhcwoKCmRlZiBkZWNvZGlmaWNhcl90ZXh0b19leHRyYWlkbyh0
REM ZXh0byk6CiAgICAiIiJDb252ZXJ0ZSB1bWEgbGluaGEgZGUgcG9lbWEgSlNPTi1xdW90YWRh
REM IGRlIHZvbHRhIHBhcmEgdGV4dG8gYnJ1dG8uCgogICAgTsOjbyB1c2EgYGBzdHJpcCgpYGAg
REM bm8gdmFsb3IgaW50ZWlybyBhbnRlcyBkbyBqc29uLmxvYWRzKCk6IGVzcGHDp29zIHF1ZSBm
REM YXplbQogICAgcGFydGUgZG8gY29udGXDumRvIGRhIHN0cmluZyBwcmVjaXNhbSBzb2JyZXZp
REM dmVyIMOgIHJlaW50ZWdyYcOnw6NvLCBlc3BlY2lhbG1lbnRlCiAgICBlbSBjb3Jwb3MgbXVs
REM dGlsaW5oYSBxdWUgdXNhbSBjb250aW51YcOnw6NvIGbDrXNpY2EgY29tIGBgXFxgYC4KICAg
REM ICIiIgogICAgdmFsb3IgPSB0ZXh0byBpZiBpc2luc3RhbmNlKHRleHRvLCBzdHIpIGVsc2Ug
REM c3RyKHRleHRvIG9yIHUiIikKICAgIGlmIGxlbih2YWxvcikgPj0gMiBhbmQgdmFsb3IubHN0
REM cmlwKCkuc3RhcnRzd2l0aCgnIicpIGFuZCB2YWxvci5yc3RyaXAoKS5lbmRzd2l0aCgnIicp
REM OgogICAgICAgIHRyeToKICAgICAgICAgICAgcmVzdWx0YWRvID0ganNvbi5sb2Fkcyh2YWxv
REM cikKICAgICAgICAgICAgaWYgaXNpbnN0YW5jZShyZXN1bHRhZG8sIHN0cik6CiAgICAgICAg
REM ICAgICAgICByZXR1cm4gcmVzdWx0YWRvCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
REM ICAgICAgICAgcGFzcwogICAgcmV0dXJuIHN0cmlwX3F1b3Rlcyh2YWxvci5zdHJpcCgpKQoK
REM CmRlZiBsaXRlcmFsX3VuaWNvX3RyYWR1eml2ZWwodmFsb3IpOgogICAgIiIiVmVyZGFkZWly
REM byBxdWFuZG8gbyB2YWxvciBpbnRlaXJvIMOpIHVtYSDDum5pY2Egc3RyaW5nIGxpdGVyYWwg
REM UmVuJ1B5IHJlYWwuIiIiCiAgICBpZiBub3QgaXNpbnN0YW5jZSh2YWxvciwgc3RyKToKICAg
REM ICAgICByZXR1cm4gRmFsc2UKICAgIHMgPSB2YWxvci5zdHJpcCgpCiAgICBpZiBsZW4ocykg
REM Pj0gMyBhbmQgc1swXSBpbiAnclInIGFuZCBzWzFdIGluICh1JyInLCB1IiciLCB1J2AnKSBh
REM bmQgc1stMV0gPT0gc1sxXToKICAgICAgICBzID0gc1sxOl0KICAgIGlmIGxlbihzKSA8IDIg
REM b3Igc1swXSBub3QgaW4gKHUnIicsIHUiJyIsIHUnYCcpIG9yIHNbLTFdICE9IHNbMF06CiAg
REM ICAgICAgcmV0dXJuIEZhbHNlCiAgICBxdW90ZSA9IHNbMF0KICAgIGkgPSAxCiAgICB3aGls
REM ZSBpIDwgbGVuKHMpIC0gMToKICAgICAgICBpZiBzW2ldID09IHUnXFwnOgogICAgICAgICAg
REM ICBpICs9IDIKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpZiBzW2ldID09IHF1b3Rl
REM OgogICAgICAgICAgICByZXR1cm4gaSA9PSBsZW4ocykgLSAxCiAgICAgICAgaSArPSAxCiAg
REM ICByZXR1cm4gVHJ1ZQoKCgpkZWYgX2xvY2FsaXphcl90cmlwb19hYmVydHVyYShsaW5oYSk6
REM CiAgICAiIiJMb2NhbGl6YSBhc3BhcyB0cmlwbGFzIGRlIG1vbsOzbG9nbyBvdSBkZSBfcCgp
REM L2Z1bsOnw7VlcyBkZSB0cmFkdcOnw6NvIFJlbidQeS4iIiIKICAgIGNhbmRpZGF0b3MgPSBb
REM XQogICAgZm9yIHEgaW4gKGNocigzNCkgKiAzLCBjaHIoMzkpICogMyk6CiAgICAgICAgcG9z
REM ID0gbGluaGEuZmluZChxKQogICAgICAgIGlmIHBvcyA+PSAwIGFuZCAocG9zID09IDAgb3Ig
REM bGluaGFbcG9zIC0gMV0gIT0gIlxcIik6CiAgICAgICAgICAgICMgUHJlZml4byByIGFudGVz
REM IGRhIHRyaXBsYSB0YW1iw6ltIMOpIGFjZWl0by4KICAgICAgICAgICAgaWYgcG9zID4gMCBh
REM bmQgbGluaGFbcG9zIC0gMV0gaW4gJ3JSJyBhbmQgKHBvcyA8IDIgb3Igbm90IChsaW5oYVtw
REM b3MgLSAyXS5pc2FsbnVtKCkgb3IgbGluaGFbcG9zIC0gMl0gPT0gJ18nKSk6CiAgICAgICAg
REM ICAgICAgICBjYW5kaWRhdG9zLmFwcGVuZCgocG9zLCBxKSkKICAgICAgICAgICAgZWxzZToK
REM ICAgICAgICAgICAgICAgIGNhbmRpZGF0b3MuYXBwZW5kKChwb3MsIHEpKQogICAgaWYgbm90
REM IGNhbmRpZGF0b3M6CiAgICAgICAgcmV0dXJuIE5vbmUKICAgIHBvcywgcSA9IG1pbihjYW5k
REM aWRhdG9zLCBrZXk9bGFtYmRhIHg6IHhbMF0pCiAgICBwcmVmaXhvID0gbGluaGFbOnBvc10u
REM c3RyaXAoKQogICAgaWYgcHJlZml4by5zdGFydHN3aXRoKCcjJyk6CiAgICAgICAgcmV0dXJu
REM IE5vbmUKICAgIGlmIHByZWZpeG86CiAgICAgICAgIyBfcC9fKC4uLikvX18oLi4uKS9fX18o
REM Li4uKSBzw6NvIGNvbnN0cnXDp8O1ZXMgZXhwbMOtY2l0YXMgZGUgdHJhZHXDp8OjbyBlCiAg
REM ICAgICAgIyBwcmVjaXNhbSBzZXIgYWNlaXRhcyBtZXNtbyBlbSBhdHJpYnVpw6fDtWVzIGNv
REM bW8KICAgICAgICAjIGBkZWZpbmUgZ3VpLmFib3V0ID0gX3AoIiIiLi4uIiIiKWAuCiAgICAg
REM ICAgaWYgcmUuc2VhcmNoKHInKD86XnxbPSwoXSlccyooPzpffF9ffF9fX3xfcClccypcKFxz
REM KnI/XHMqJCcsIHByZWZpeG8sIHJlLkkpOgogICAgICAgICAgICByZXR1cm4gcG9zLCBxCiAg
REM ICAgICAgcHJvaWJpZG9zID0gKCckICcsICdsYWJlbCAnLCAnanVtcCAnLCAnY2FsbCAnLCAn
REM ZGVmaW5lICcsICdkZWZhdWx0ICcsICdpbml0ICcsICdweXRob24gJywgJ3NjcmVlbiAnLCAn
REM dHJhbnNmb3JtICcsICdzdHlsZSAnKQogICAgICAgIGlmIHByZWZpeG8uc3RhcnRzd2l0aChw
REM cm9pYmlkb3MpOgogICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgIGlmIHJlLmZ1bGxt
REM YXRjaChyJ3InLCBwcmVmaXhvLCByZS5JKToKICAgICAgICAgICAgcmV0dXJuIHBvcywgcQog
REM ICAgICAgIGlmIG5vdCByZS5mdWxsbWF0Y2gocicoPzpyXHMrKT8oPzpbQS1aYS16X11bXHcu
REM XSp8XFtbXlxdXStcXXwoPzpbQS1aYS16X11bXHcuXSpccyspezEsNX1bQS1aYS16X11bXHcu
REM XSopJywgcHJlZml4byk6CiAgICAgICAgICAgIHJldHVybiBOb25lCiAgICByZXR1cm4gcG9z
REM LCBxCgoKZGVmIF9leHRyYWlyX21vbm9sb2dvc190cmlwbG9zX3JlbnB5KGNhbWluaG8sIGxp
REM bmhhc19yYXcsIGxpbmhhc19weXRob249Tm9uZSwgbGluaGFzX2Jsb2Nvc190ZWNuaWNvcz1O
REM b25lKToKICAgICIiIkV4dHJhaSBtb27Ds2xvZ29zIFJlbidQeSBlIHN0cmluZ3MgZGUgdHJh
REM ZHXDp8OjbyBlbSBhc3BhcyB0cmlwbGFzIGZvcmEgZGUgUHl0aG9uLgoKICAgIENhZGEgbGlu
REM aGEgZsOtc2ljYSBkZSBjb250ZcO6ZG8gdmlyYSB1bWEgZW50cmFkYSBpbmRlcGVuZGVudGUg
REM bm8gbWFwYSBwYXJhCiAgICBwcmVzZXJ2YXIgYSBlc3RydXR1cmEgb3JpZ2luYWwgZXhpZ2lk
REM YSBwZWxhIHJlaW5qZcOnw6NvLiBTdHJpbmdzIHRyaXBsYXMgZGVudHJvCiAgICBkZSBkaXJl
REM dMOzcmlvcyBQeXRob24vY29tcGF0aWJpbGlkYWRlIHPDo28gdHJhdGFkYXMgY29tbyBkb2Nz
REM dHJpbmdzL2PDs2RpZ28gZQogICAgcGVybWFuZWNlbSBmb3JhIGRhIGV4dHJhw6fDo28uCiAg
REM ICAiIiIKICAgIGJhc2UgPSBvcy5wYXRoLmJhc2VuYW1lKGNhbWluaG8pLmxvd2VyKCkKICAg
REM IGNhbWluaG9fbm9ybSA9IGNhbWluaG8ucmVwbGFjZSgnXFwnLCAnLycpLmxvd2VyKCkKICAg
REM IGlmIGJhc2UgPT0gUE9FTVJFU1BPTlNFU19CQVNFX05BTUU6CiAgICAgICAgcmV0dXJuIHt9
REM LCBzZXQoKQogICAgIyBwb2Vtcy5ycHkvcG9lbXNfcmVuLnB5IHPDo28gcHJvY2Vzc2Fkb3Mg
REM cG9yIGV4dHJhaXJfY29ycG9zX3BvZW1hcygpLCBxdWUKICAgICMgasOhIGNvbmhlY2UgbyBs
REM aW1pdGUgbMOzZ2ljbyBkb3MgYmxvY29zIFBvZW0vdGV4dD1fKCkvX18oKS9fcCgpLiBOw6Nv
REM IGRlaXhlCiAgICAjIG8gZXh0cmF0b3IgZ2Vuw6lyaWNvIGRlIG1vbsOzbG9nbyBkdXBsaWNh
REM ciBhcyBtZXNtYXMgbGluaGFzIGbDrXNpY2FzLgogICAgaWYgYmFzZSBpbiAoJ3BvZW1zLnJw
REM eScsICdwb2Vtc19yZW4ucHknKSBhbmQgJy9wb2VtX3Jlc3BvbnNlcy8nIGluIGNhbWluaG9f
REM bm9ybToKICAgICAgICByZXR1cm4ge30sIHNldCgpCiAgICAjIFBhc3RhcyBgcHlgIGRlc3Rl
REM IHRlbXBsYXRlIGNhcnJlZ2FtIGPDs2RpZ28gUHl0aG9uL2NvbXBhdGliaWxpZGFkZS4gRW0K
REM ICAgICMgcGFydGljdWxhciwgaMOhIGRvY3N0cmluZ3MgZSBibG9jb3MgYHB5dGhvbiBlYXJs
REM eTpgIGVzY3JpdG9zIGNvbSBhc3BhcwogICAgIyB0cmlwbGFzIHF1ZSBuw6NvIHPDo28gdGV4
REM dG8gZGUgam9nby4gTsOjbyBkZXZlbW9zIHRyYW5zZm9ybcOhLWxvcyBlbSBkacOhbG9nby4K
REM ICAgIGlmICcvcHkvJyBpbiBjYW1pbmhvX25vcm0gb3IgY2FtaW5ob19ub3JtLmVuZHN3aXRo
REM KCcvcHknKToKICAgICAgICByZXR1cm4ge30sIHNldCgpCiAgICBsaW5oYXNfcHl0aG9uID0g
REM bGluaGFzX3B5dGhvbiBvciBzZXQoKQogICAgbGluaGFzX2Jsb2Nvc190ZWNuaWNvcyA9IGxp
REM bmhhc19ibG9jb3NfdGVjbmljb3Mgb3Igc2V0KCkKICAgIHBvcl9saW5oYSA9IHt9CiAgICBs
REM aW5oYXNfbW9ub2xvZ28gPSBzZXQoKQogICAgYXRpdm8gPSBOb25lCgogICAgZGVmIGFkaWNp
REM b25hcl9zZWdtZW50byhudW1lcm8sIGxpbmhhX29yaWdpbmFsLCBpbmljaW8sIGZpbSwgY29u
REM dGV4dG8pOgogICAgICAgIGlmIGluaWNpbyA8IDAgb3IgZmltIDw9IGluaWNpbzoKICAgICAg
REM ICAgICAgcmV0dXJuCiAgICAgICAgd2hpbGUgaW5pY2lvIDwgZmltIGFuZCBsaW5oYV9vcmln
REM aW5hbFtpbmljaW9dIGluICcgXHQnOgogICAgICAgICAgICBpbmljaW8gKz0gMQogICAgICAg
REM IHdoaWxlIGZpbSA+IGluaWNpbyBhbmQgbGluaGFfb3JpZ2luYWxbZmltIC0gMV0gaW4gJyBc
REM dCc6CiAgICAgICAgICAgIGZpbSAtPSAxCiAgICAgICAgaWYgaW5pY2lvIDwgZmltIGFuZCBs
REM aW5oYV9vcmlnaW5hbFtpbmljaW9dID09ICdcXCcgYW5kIGxpbmhhX29yaWdpbmFsW2luaWNp
REM byArIDE6XS5zdHJpcCgpID09ICcnOgogICAgICAgICAgICBpbmljaW8gPSBmaW0KICAgICAg
REM ICBpZiBmaW0gPiBpbmljaW8gYW5kIGxpbmhhX29yaWdpbmFsW2ZpbSAtIDFdID09ICdcXCc6
REM CiAgICAgICAgICAgIGZpbSAtPSAxCiAgICAgICAgaWYgaW5pY2lvID49IGZpbToKICAgICAg
REM ICAgICAgcmV0dXJuCiAgICAgICAgdGV4dG8gPSBsaW5oYV9vcmlnaW5hbFtpbmljaW86Zmlt
REM XQogICAgICAgIGlmIG5vdCB0ZW1fY29udGV1ZG9fdHJhZHV6aXZlbChqc29uLmR1bXBzKHRl
REM eHRvLCBlbnN1cmVfYXNjaWk9RmFsc2UpKToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAg
REM cG9yX2xpbmhhLnNldGRlZmF1bHQobnVtZXJvLCBbXSkuYXBwZW5kKHsKICAgICAgICAgICAg
REM J2NvbHVuYV9pbmljaW8nOiBpbmljaW8sCiAgICAgICAgICAgICdjb2x1bmFfZmltJzogZmlt
REM LAogICAgICAgICAgICAnb3JpZ2luYWwnOiBsaW5oYV9vcmlnaW5hbFtpbmljaW86ZmltXSwK
REM ICAgICAgICAgICAgJ3RyZWNobyc6IGpzb24uZHVtcHModGV4dG8sIGVuc3VyZV9hc2NpaT1G
REM YWxzZSksCiAgICAgICAgICAgICd0aXBvJzogJ21vbm9sb2dvX3RyaXBsYXMnLAogICAgICAg
REM ICAgICAnY29uZmlhbmNhJzogMTAwLAogICAgICAgICAgICAnY29udGV4dG8nOiBjb250ZXh0
REM bywKICAgICAgICB9KQoKICAgIGZvciBpZHgsIHJhdyBpbiBlbnVtZXJhdGUobGluaGFzX3Jh
REM dywgMSk6CiAgICAgICAgbGluaGEgPSByYXcucnN0cmlwKCdcclxuJykKICAgICAgICBpZiBp
REM ZHggaW4gbGluaGFzX3B5dGhvbiBvciBpZHggaW4gbGluaGFzX2Jsb2Nvc190ZWNuaWNvczoK
REM ICAgICAgICAgICAgY29udGludWUKCiAgICAgICAgaWYgYXRpdm8gaXMgbm90IE5vbmU6CiAg
REM ICAgICAgICAgIHEgPSBhdGl2b1sncXVvdGUnXQogICAgICAgICAgICBmZWNoYW1lbnRvID0g
REM bGluaGEuZmluZChxKQogICAgICAgICAgICBsaW5oYXNfbW9ub2xvZ28uYWRkKGlkeCkKICAg
REM ICAgICAgICAgaWYgZmVjaGFtZW50byA+PSAwOgogICAgICAgICAgICAgICAgYWRpY2lvbmFy
REM X3NlZ21lbnRvKGlkeCwgbGluaGEsIDAsIGZlY2hhbWVudG8sIGF0aXZvWydjb250ZXh0bydd
REM KQogICAgICAgICAgICAgICAgYXRpdm8gPSBOb25lCiAgICAgICAgICAgIGVsc2U6CiAgICAg
REM ICAgICAgICAgICBhZGljaW9uYXJfc2VnbWVudG8oaWR4LCBsaW5oYSwgMCwgbGVuKGxpbmhh
REM KSwgYXRpdm9bJ2NvbnRleHRvJ10pCiAgICAgICAgICAgIGNvbnRpbnVlCgogICAgICAgIGlm
REM IG5vdCBsaW5oYS5zdHJpcCgpIG9yIGxpbmhhLmxzdHJpcCgpLnN0YXJ0c3dpdGgoJyMnKToK
REM ICAgICAgICAgICAgY29udGludWUKICAgICAgICBhYmVydHVyYSA9IF9sb2NhbGl6YXJfdHJp
REM cG9fYWJlcnR1cmEobGluaGEpCiAgICAgICAgaWYgbm90IGFiZXJ0dXJhOgogICAgICAgICAg
REM ICBjb250aW51ZQogICAgICAgIHBvcywgcSA9IGFiZXJ0dXJhCiAgICAgICAgIyBTdHJpbmcg
REM dHJpcGxhIHNlbSBwcmVmaXhvIGRlIGZhbGEgKF9wL18oLi4uKS9fXy4uLiBvdSBwZXJzb25h
REM Z2VtKQogICAgICAgICMgw6kgdMOtcGljYSBkZSBkb2NzdHJpbmcuIFJlbidQeSBhY2VpdGEg
REM c3RyaW5ncyBkaXJldGFzIG5hcyBjb25zdHJ1w6fDtWVzCiAgICAgICAgIyBkZSBkacOhbG9n
REM bywgbWFzIHRyaXBsZS1xdW90ZWQgc3RyaW5ncyBnZW7DqXJpY2FzIG7Do28gc8OjbyB1bWEg
REM Zm9ybWEKICAgICAgICAjIG5vcm1hbCBkZSBuYXJyYXRpdmE7IGV2aXRhbW9zIGNhcHR1cmFy
REM IGPDs2RpZ28gcG9yIGFjaWRlbnRlLgogICAgICAgIHByZWZpeG8gPSBsaW5oYVs6cG9zXS5z
REM dHJpcCgpCiAgICAgICAgaWYgbm90IHByZWZpeG8gYW5kIGxpbmhhLmxzdHJpcCgpLnN0YXJ0
REM c3dpdGgocSk6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgbGluaGFzX21vbm9sb2dv
REM LmFkZChpZHgpCiAgICAgICAgaW5pY2lvID0gcG9zICsgMwogICAgICAgIHJlc3RhbnRlID0g
REM bGluaGFbaW5pY2lvOl0KICAgICAgICBmZWNoYW1lbnRvX3JlbCA9IHJlc3RhbnRlLmZpbmQo
REM cSkKICAgICAgICBjb250ZXh0byA9IHUiTW9uw7Nsb2dvIFJlbidQeSBlbSBhc3BhcyB0cmlw
REM bGFzIgogICAgICAgIGlmIGZlY2hhbWVudG9fcmVsID49IDA6CiAgICAgICAgICAgIGFkaWNp
REM b25hcl9zZWdtZW50byhpZHgsIGxpbmhhLCBpbmljaW8sIGluaWNpbyArIGZlY2hhbWVudG9f
REM cmVsLCBjb250ZXh0bykKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpZiByZXN0YW50
REM ZSA9PSAnXFwnOgogICAgICAgICAgICBhdGl2byA9IHsncXVvdGUnOiBxLCAnY29udGV4dG8n
REM OiBjb250ZXh0b30KICAgICAgICBlbHNlOgogICAgICAgICAgICBpZiByZXN0YW50ZS5zdGFy
REM dHN3aXRoKCdcXCcpOgogICAgICAgICAgICAgICAgaW5pY2lvICs9IDEKICAgICAgICAgICAg
REM YWRpY2lvbmFyX3NlZ21lbnRvKGlkeCwgbGluaGEsIGluaWNpbywgbGVuKGxpbmhhKSwgY29u
REM dGV4dG8pCiAgICAgICAgICAgIGF0aXZvID0geydxdW90ZSc6IHEsICdjb250ZXh0byc6IGNv
REM bnRleHRvfQoKICAgIHJldHVybiBwb3JfbGluaGEsIGxpbmhhc19tb25vbG9nbwoKCiMgUHJp
REM b3JpZGFkZSBnbG9iYWwgcGFyYSByZXNvbHZlciBjYW5kaWRhdG9zIHF1ZSBkaXNwdXRhbSBv
REM IG1lc21vIHRyZWNobyBmw61zaWNvLgojIEEgcmVncmEgw6kgZGVsaWJlcmFkYW1lbnRlIMO6
REM bmljYSBwYXJhIHRvZG9zIG9zIG1vZHM6IGZvbnRlcyBzaW50w6F0aWNhcyBtYWlzCiMgZXNw
REM ZWPDrWZpY2FzIHZlbmNlbSBkZXRlY3RvcmVzIGdlbsOpcmljb3MuIEVtIGVtcGF0ZSwgYSBw
REM cmltZWlyYSBvY29ycsOqbmNpYQojIGNvbnRpbnVhIHNlbmRvIG1hbnRpZGEuIElzc28gaW1w
REM ZWRlIGR1cGxhIHJlaW5qZcOnw6NvIHNlbSBjcmlhciBjb3JyZcOnw7VlcwojIGVzcGVjw61m
REM aWNhcyBwb3IgYXJxdWl2by9tb2QuClRJUE9fUFJJT1JJREFERV9TT0JSRVBPU0lDQU8gPSB7
REM CiAgICAncG9lbWFfdGl0dWxvJzogNTEwLAogICAgJ3BvZW1hX2NvcnBvJzogNTAwLAogICAg
REM J2dldHRleHRfbXVsdGlsaW5oYSc6IDQ3MCwKICAgICdtb25vbG9nb190cmlwbGFzJzogNDYw
REM LAogICAgJ211bHRpbGluaGFfcmVucHknOiA0NTAsCiAgICAncG9lbWFfcGFsYXZyYV90eHQn
REM OiA0MzAsCiAgICAncG9lbWFfcGFsYXZyYSc6IDQzMCwKICAgICdyZW5weV9uYXRpdm9fZGlh
REM bG9nbyc6IDMyMCwKICAgICdyZW5weV9uYXRpdm9fc3RyaW5nJzogMzEwLAogICAgJ3VybF92
REM aXNpdmVsJzogMzAwLAogICAgJ25vbWVfcGVyc29uYWdlbSc6IDIyMCwKICAgICd0ZXh0b19j
REM cmVkaXRvc19ibG9jbyc6IDIxMCwKICAgICd0ZXh0b19jcmVkaXRvc19kYWRvcyc6IDE4MCwK
REM ICAgICd2YXJpYXZlbF90ZXh0byc6IDE3MCwKICAgICdkaWFsb2dvJzogMTYwLAogICAgJ25h
REM cnJhdGl2YSc6IDE1MCwKICAgICd1aSc6IDE0MCwKfQoKCmRlZiBfcmVzb2x2ZXJfc29icmVw
REM b3NpY29lc19yZWdpc3Ryb3MocmVnaXN0cm9zKToKICAgICIiIlJlbW92ZSBkaXNwdXRhcyBk
REM ZSBzcGFucyBuYSBtZXNtYSBsaW5oYSB1c2FuZG8gYSBwb2zDrXRpY2EgZ2xvYmFsIGRlIHBy
REM aW9yaWRhZGUuCgogICAgTyBkZXRlY3RvciBhbnRpZ28gZWxpbWluYXZhIGFwZW5hcyBzcGFu
REM cyBleGF0YW1lbnRlIGlndWFpcy4gUXVhbmRvIHVtIGRldGVjdG9yCiAgICBlc3BlY2lhbGl6
REM YWRvIGNvYnJlIDAtMjQgZSBvdXRybyBjb2JyZSAwLTIzLCBhbWJvcyBwYXNzYXZhbSBlIGEg
REM cmVpbmplw6fDo28KICAgIHBvZGlhIGVzY3JldmVyIGR1YXMgdmV6ZXMgbmEgbWVzbWEgcmVn
REM acOjby4gQXF1aSB0b2RvcyBvcyBjYW5kaWRhdG9zIGRlIHVtYQogICAgbGluaGEgc8OjbyBj
REM b21wYXJhZG9zIHBvciBpbnRlcnZhbG8gZsOtc2ljbyBhbnRlcyBkZSBlbnRyYXJlbSBubyBt
REM YXBhIGZpbmFsLgoKICAgIFJldG9ybmEgKHJlZ2lzdHJvc19maWx0cmFkb3MsIGNvbmZsaXRv
REM cykuIGBjb25mbGl0b3NgIMOpIHNvbWVudGUgaW5mb3JtYXRpdm86CiAgICB1bSBjb25mbGl0
REM byByZXNvbHZpZG8gbsOjbyBpbnRlcnJvbXBlIGEgZXh0cmHDp8Ojby4KICAgICIiIgogICAg
REM aWYgbGVuKHJlZ2lzdHJvcykgPD0gMToKICAgICAgICByZXR1cm4gbGlzdChyZWdpc3Ryb3Mp
REM LCBbXQoKICAgIGNsYXNzaWZpY2Fkb3MgPSBbXQogICAgZm9yIGluZGljZSwgcmVnaXN0cm8g
REM aW4gZW51bWVyYXRlKHJlZ2lzdHJvcyk6CiAgICAgICAgaW5pY2lvLCBmaW0gPSByZWdpc3Ry
REM b1swXSwgcmVnaXN0cm9bMV0KICAgICAgICB0aXBvID0gcmVnaXN0cm9bMl0gaWYgbGVuKHJl
REM Z2lzdHJvKSA+IDIgZWxzZSB1JycKICAgICAgICBwcmlvcmlkYWRlID0gVElQT19QUklPUklE
REM QURFX1NPQlJFUE9TSUNBTy5nZXQodGlwbywgMTAwKQogICAgICAgIHRhbWFuaG8gPSBtYXgo
REM MCwgZmltIC0gaW5pY2lvKQogICAgICAgIGNsYXNzaWZpY2Fkb3MuYXBwZW5kKChpbmRpY2Us
REM IHJlZ2lzdHJvLCBwcmlvcmlkYWRlLCB0YW1hbmhvKSkKCiAgICAjIE1haXMgZXNwZWPDrWZp
REM Y28gcHJpbWVpcm87IGVtIGVtcGF0ZSwgcHJlc2VydmEgYSBvcmRlbSBvcmlnaW5hbC4KICAg
REM IGNsYXNzaWZpY2Fkb3Muc29ydChrZXk9bGFtYmRhIGl0ZW06ICgtaXRlbVsyXSwgLWl0ZW1b
REM M10sIGl0ZW1bMF0pKQoKICAgIG1hbnRpZG9zID0gW10KICAgIGNvbmZsaXRvcyA9IFtdCiAg
REM ICBmb3IgaW5kaWNlLCByZWdpc3RybywgcHJpb3JpZGFkZSwgdGFtYW5obyBpbiBjbGFzc2lm
REM aWNhZG9zOgogICAgICAgIGluaWNpbywgZmltID0gcmVnaXN0cm9bMF0sIHJlZ2lzdHJvWzFd
REM CiAgICAgICAgY29uZmxpdG9fY29tID0gTm9uZQogICAgICAgIGZvciBfLCBvdXRybywgb3V0
REM cmFfcHJpb3JpZGFkZSwgb3V0cm9fdGFtYW5obyBpbiBtYW50aWRvczoKICAgICAgICAgICAg
REM b19pbmljaW8sIG9fZmltID0gb3V0cm9bMF0sIG91dHJvWzFdCiAgICAgICAgICAgIGlmIG1h
REM eChpbmljaW8sIG9faW5pY2lvKSA8IG1pbihmaW0sIG9fZmltKToKICAgICAgICAgICAgICAg
REM IGNvbmZsaXRvX2NvbSA9IChvdXRybywgb3V0cmFfcHJpb3JpZGFkZSwgb3V0cm9fdGFtYW5o
REM bykKICAgICAgICAgICAgICAgIGJyZWFrCgogICAgICAgIGlmIGNvbmZsaXRvX2NvbSBpcyBu
REM b3QgTm9uZToKICAgICAgICAgICAgb3V0cm8sIG91dHJhX3ByaW9yaWRhZGUsIG91dHJvX3Rh
REM bWFuaG8gPSBjb25mbGl0b19jb20KICAgICAgICAgICAgY29uZmxpdG9zLmFwcGVuZCh7CiAg
REM ICAgICAgICAgICAgICAnbm92b190aXBvJzogcmVnaXN0cm9bMl0gaWYgbGVuKHJlZ2lzdHJv
REM KSA+IDIgZWxzZSB1JycsCiAgICAgICAgICAgICAgICAnbm92b19pbmljaW8nOiBpbmljaW8s
REM CiAgICAgICAgICAgICAgICAnbm92b19maW0nOiBmaW0sCiAgICAgICAgICAgICAgICAnbWFu
REM dGlkb190aXBvJzogb3V0cm9bMl0gaWYgbGVuKG91dHJvKSA+IDIgZWxzZSB1JycsCiAgICAg
REM ICAgICAgICAgICAnbWFudGlkb19pbmljaW8nOiBvdXRyb1swXSwKICAgICAgICAgICAgICAg
REM ICdtYW50aWRvX2ZpbSc6IG91dHJvWzFdLAogICAgICAgICAgICB9KQogICAgICAgICAgICBj
REM b250aW51ZQoKICAgICAgICBtYW50aWRvcy5hcHBlbmQoKGluZGljZSwgcmVnaXN0cm8sIHBy
REM aW9yaWRhZGUsIHRhbWFuaG8pKQoKICAgIG1hbnRpZG9zLnNvcnQoa2V5PWxhbWJkYSBpdGVt
REM OiBpdGVtWzBdKQogICAgcmV0dXJuIFtyZWdpc3RybyBmb3IgXywgcmVnaXN0cm8sIF8sIF8g
REM aW4gbWFudGlkb3NdLCBjb25mbGl0b3MKCgpkZWYgX3Jlc29sdmVyX3NvYnJlcG9zaWNvZXNf
REM bWFwYShlbnRyYWRhc19tYXBhLCB0ZXh0b3NfdHJhZHV6aWRvcyk6CiAgICAiIiJGaWx0cmEg
REM ZW50cmFkYXMgasOhIG1hcGVhZGFzIHF1ZSBkaXNwdXRhbSBvIG1lc21vIHNwYW4gZsOtc2lj
REM by4KCiAgICBDb21wYXRpYmlsaWRhZGUgaW1wb3J0YW50ZTogbWFwYXMgYW50aWdvcyBkbyBW
REM MTAwIHRhbWLDqW0gZmljYW0gc2VndXJvcy4KICAgIEEgdmFsaWRhw6fDo28gZGUgY29udGFn
REM ZW0gY29udGludWEgZXhpZ2luZG8gYSBtZXNtYSBxdWFudGlkYWRlIGRlIHRleHRvczsKICAg
REM IHNvbWVudGUgb3MgY2FuZGlkYXRvcyBzb2JyZXBvc3RvcyBkZWl4YW0gZGUgc2VyIGVzY3Jp
REM dG9zIG5vIGFycXVpdm8uCiAgICAiIiIKICAgIHBhcmVzID0gbGlzdChlbnVtZXJhdGUoemlw
REM KGVudHJhZGFzX21hcGEsIHRleHRvc190cmFkdXppZG9zKSkpCiAgICBpZiBsZW4ocGFyZXMp
REM IDw9IDE6CiAgICAgICAgcmV0dXJuIFsoZSwgdCkgZm9yIF8sIChlLCB0KSBpbiBwYXJlc10s
REM IFtdCgogICAgY2xhc3NpZmljYWRvcyA9IFtdCiAgICBmb3IgaW5kaWNlLCAoZW50cmFkYSwg
REM dHJhZHV6aWRvKSBpbiBwYXJlczoKICAgICAgICBsaW5oYSA9IGludChlbnRyYWRhLmdldCgn
REM bGluaGEnLCAwKSBvciAwKQogICAgICAgIGluaWNpbyA9IGludChlbnRyYWRhLmdldCgnY29s
REM dW5hX2luaWNpbycsIDApIG9yIDApCiAgICAgICAgZmltID0gaW50KGVudHJhZGEuZ2V0KCdj
REM b2x1bmFfZmltJywgMCkgb3IgMCkKICAgICAgICB0aXBvID0gZW50cmFkYS5nZXQoJ3RpcG8n
REM LCB1JycpCiAgICAgICAgcHJpb3JpZGFkZSA9IFRJUE9fUFJJT1JJREFERV9TT0JSRVBPU0lD
REM QU8uZ2V0KHRpcG8sIDEwMCkKICAgICAgICB0YW1hbmhvID0gbWF4KDAsIGZpbSAtIGluaWNp
REM bykKICAgICAgICBjbGFzc2lmaWNhZG9zLmFwcGVuZCgoaW5kaWNlLCBlbnRyYWRhLCB0cmFk
REM dXppZG8sIGxpbmhhLCBpbmljaW8sIGZpbSwgcHJpb3JpZGFkZSwgdGFtYW5obykpCgogICAg
REM Y2xhc3NpZmljYWRvcy5zb3J0KGtleT1sYW1iZGEgaXRlbTogKC1pdGVtWzZdLCAtaXRlbVs3
REM XSwgaXRlbVswXSkpCiAgICBtYW50aWRvcyA9IFtdCiAgICBjb25mbGl0b3MgPSBbXQoKICAg
REM IGZvciBpdGVtIGluIGNsYXNzaWZpY2Fkb3M6CiAgICAgICAgaW5kaWNlLCBlbnRyYWRhLCB0
REM cmFkdXppZG8sIGxpbmhhLCBpbmljaW8sIGZpbSwgcHJpb3JpZGFkZSwgdGFtYW5obyA9IGl0
REM ZW0KICAgICAgICBjb25mbGl0b19jb20gPSBOb25lCiAgICAgICAgZm9yIG91dHJvIGluIG1h
REM bnRpZG9zOgogICAgICAgICAgICBfLCBvdXRyYV9lbnRyYWRhLCBfLCBvdXRyYV9saW5oYSwg
REM b3V0cm9faW5pY2lvLCBvdXRyb19maW0sIG91dHJhX3ByaW9yaWRhZGUsIG91dHJvX3RhbWFu
REM aG8gPSBvdXRybwogICAgICAgICAgICBpZiBsaW5oYSA9PSBvdXRyYV9saW5oYSBhbmQgbWF4
REM KGluaWNpbywgb3V0cm9faW5pY2lvKSA8IG1pbihmaW0sIG91dHJvX2ZpbSk6CiAgICAgICAg
REM ICAgICAgICBjb25mbGl0b19jb20gPSBvdXRyYV9lbnRyYWRhCiAgICAgICAgICAgICAgICBi
REM cmVhawogICAgICAgIGlmIGNvbmZsaXRvX2NvbSBpcyBub3QgTm9uZToKICAgICAgICAgICAg
REM Y29uZmxpdG9zLmFwcGVuZCh7CiAgICAgICAgICAgICAgICAnbGluaGEnOiBsaW5oYSwKICAg
REM ICAgICAgICAgICAgICdub3ZvX3RpcG8nOiB0aXBvLAogICAgICAgICAgICAgICAgJ25vdm9f
REM aW5pY2lvJzogaW5pY2lvLAogICAgICAgICAgICAgICAgJ25vdm9fZmltJzogZmltLAogICAg
REM ICAgICAgICAgICAgJ21hbnRpZG9fdGlwbyc6IGNvbmZsaXRvX2NvbS5nZXQoJ3RpcG8nLCB1
REM JycpLAogICAgICAgICAgICAgICAgJ21hbnRpZG9faW5pY2lvJzogaW50KGNvbmZsaXRvX2Nv
REM bS5nZXQoJ2NvbHVuYV9pbmljaW8nLCAwKSBvciAwKSwKICAgICAgICAgICAgICAgICdtYW50
REM aWRvX2ZpbSc6IGludChjb25mbGl0b19jb20uZ2V0KCdjb2x1bmFfZmltJywgMCkgb3IgMCks
REM CiAgICAgICAgICAgIH0pCiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgbWFudGlkb3Mu
REM YXBwZW5kKGl0ZW0pCgogICAgbWFudGlkb3Muc29ydChrZXk9bGFtYmRhIGl0ZW06IGl0ZW1b
REM MF0pCiAgICByZXR1cm4gWyhpdGVtWzFdLCBpdGVtWzJdKSBmb3IgaXRlbSBpbiBtYW50aWRv
REM c10sIGNvbmZsaXRvcwoKCmRlZiBleHRyYWlyX2FycXVpdm9fY29tX21hcGEoY2FtaW5obywg
REM dmFyaWF2ZWlzX25vbWVfZGluYW1pY28sIGluZGljZV9hcnF1aXZvcz1Ob25lLCB2b2NhYnVs
REM YXJpbz1Ob25lLCBvcmFjbGVfcG9yX2FycXVpdm89Tm9uZSk6CiAgICAiIiJFeHRyYcOnw6Nv
REM IGRlIGFsdGEgY29iZXJ0dXJhOiBtb3RvciBhdHVhbCArIHJlY3VwZXJhw6fDo28gY29udGV4
REM dHVhbCBkZSB2ZXJzw7VlcyBhbnRlcmlvcmVzLiIiIgogICAgdGV4dG9zID0gW10KICAgIG1h
REM cGEgPSBbXQogICAgbGluaGFzX3JhdyA9IGxlcl9saW5oYXNfcmF3KGNhbWluaG8pCiAgICBs
REM aW5oYXNfYmxvY29zX3RlY25pY29zID0gY29uc3RydWlyX2xpbmhhc19ibG9jb3NfdGVjbmlj
REM b3MobGluaGFzX3JhdykKICAgIGxpbmhhc19weXRob24gPSBjb25zdHJ1aXJfbGluaGFzX3B5
REM dGhvbihsaW5oYXNfcmF3KQogICAgY29udGV1ZG9fY29tcGxldG8gPSB1IiIuam9pbihsaW5o
REM YXNfcmF3KQogICAgY29udGV1ZG9fYW5hbGlzZSA9IG1hc2NhcmFyX3NlY29lc19weXRob25f
REM cmVucHkoY29udGV1ZG9fY29tcGxldG8pIGlmIGVoX3JlbnB5X21vZGVybm8oY2FtaW5obykg
REM ZWxzZSBjb250ZXVkb19jb21wbGV0bwogICAgbGluaGFzX2F0aXZhcyA9IGxpbmhhc19yZW5w
REM eV9hdGl2YXMoY2FtaW5obywgbGluaGFzX3JhdykKCiAgICBlbnRyYWRhc19kZWZpbmljb2Vz
REM LCBkeW5hbWljX3ZhcnNfZGVzY29iZXJ0YXMgPSBhbmFsaXNhcl9kZWZpbmljb2VzX3BlcnNv
REM bmFnZW5zKGNhbWluaG8sIGNvbnRldWRvX2FuYWxpc2UpCiAgICAjIEFjaGlldmVtZW50L0Fj
REM aGlldmVtZW50Q291bnQgdml2ZW0gZnJlcXVlbnRlbWVudGUgZGVudHJvIGRlIGJsb2NvcyBQ
REM eXRob24KICAgICMgbW9kZXJub3MsIHF1ZSBzw6NvIG1hc2NhcmFkb3MgZW0gYGNvbnRldWRv
REM X2FuYWxpc2VgLiBQb3IgaXNzbyBlc3RhIHJlZ3JhCiAgICAjIHJlY2ViZSBvIGNvbnRlw7pk
REM byBjb21wbGV0byBlIHJlY3VwZXJhIHNvbWVudGUgb3MgYXJndW1lbnRvcyB0ZXh0dWFpcwog
REM ICAgIyBzZW1hbnRpY2FtZW50ZSB2aXPDrXZlaXMuCiAgICBlbnRyYWRhc19kZWZpbmljb2Vz
REM LmV4dGVuZChhbmFsaXNhcl9jb25zdHJ1dG9yZXNfYWNoaWV2ZW1lbnRzKGNhbWluaG8sIGNv
REM bnRldWRvX2NvbXBsZXRvKSkKICAgICMgMDFkZWZpbml0aW9ucy5ycHkgZG8gdGVsZWZvbmUg
REM dXNhIHBob25lLmNoYXJhY3Rlci5DaGFyYWN0ZXIoLi4uKSwgcXVlCiAgICAjIG7Do28gw6kg
REM dW1hIGRlZmluacOnw6NvIENoYXJhY3RlciB0cmFkaWNpb25hbC4gVHJhdGEtc2UgZGUgb3V0
REM cmEgZm9udGUgdsOhbGlkYQogICAgIyBkZSBub21lcyBleGliaWRvczsgZWxhIGRldmUgc2Vy
REM IGFuYWxpc2FkYSBzZXBhcmFkYW1lbnRlIGUgc2VtIGVsaW1pbmFyCiAgICAjIG9jb3Jyw6pu
REM Y2lhcyBzw7MgcG9ycXVlIG8gbWVzbW8gdGV4dG8gdGFtYsOpbSBleGlzdGUgZW0gZGVmaW5p
REM dGlvbnMucnB5LgogICAgZW50cmFkYXNfZGVmaW5pY29lcy5leHRlbmQoYW5hbGlzYXJfZGVm
REM aW5pY29lc19waG9uZShjYW1pbmhvLCBjb250ZXVkb19hbmFsaXNlKSkKICAgIHZhcmlhdmVp
REM c19ub21lX2RpbmFtaWNvLnVwZGF0ZShkeW5hbWljX3ZhcnNfZGVzY29iZXJ0YXMpCiAgICBk
REM ZWZpbmljb2VzX3Bvcl9saW5oYSA9IHt9CiAgICBmb3IgZW50cmFkYV9kZWYgaW4gZW50cmFk
REM YXNfZGVmaW5pY29lczoKICAgICAgICBkZWZpbmljb2VzX3Bvcl9saW5oYS5zZXRkZWZhdWx0
REM KGVudHJhZGFfZGVmWyJsaW5oYSJdLCBbXSkuYXBwZW5kKGVudHJhZGFfZGVmKQoKICAgIGxp
REM bmhhc19lbV9kZWZpbmljYW9fcGVyc29uYWdlbSA9IHNldCgpCiAgICBmb3IgbV9jaGFyX3Nw
REM YW4gaW4gQ0hBUl9ERUZfU1RBUlRfUkUuZmluZGl0ZXIoY29udGV1ZG9fYW5hbGlzZSk6CiAg
REM ICAgICAgYWJyZSA9IGNvbnRldWRvX2FuYWxpc2UuZmluZCgnKCcsIG1fY2hhcl9zcGFuLnN0
REM YXJ0KCkpCiAgICAgICAgZmVjaGEgPSBfZmluZF9tYXRjaGluZ19wYXJlbihjb250ZXVkb19h
REM bmFsaXNlLCBhYnJlKSBpZiBhYnJlID49IDAgZWxzZSAtMQogICAgICAgIGlmIGZlY2hhIDwg
REM MDoKICAgICAgICAgICAgY29udGludWUKICAgICAgICBsMSwgXyA9IF9saW5lX2NvbF9mcm9t
REM X29mZnNldChjb250ZXVkb19hbmFsaXNlLCBtX2NoYXJfc3Bhbi5zdGFydCgpKQogICAgICAg
REM IGwyLCBfID0gX2xpbmVfY29sX2Zyb21fb2Zmc2V0KGNvbnRldWRvX2FuYWxpc2UsIGZlY2hh
REM KQogICAgICAgIGZvciBudW1lcm8gaW4gcmFuZ2UobDEsIGwyICsgMSk6CiAgICAgICAgICAg
REM IGxpbmhhc19lbV9kZWZpbmljYW9fcGVyc29uYWdlbS5hZGQobnVtZXJvKQoKICAgIFFTVFJf
REM TE9DQUwgPSBRU1RSCiAgICAjIE1hbnTDqW0gbyBmYWxsYmFjayBhbXBsbyBkYSB2ZXJzw6Nv
REM IHJlY2VudGU6IGVsZSDDqSBpbXBvcnRhbnRlIHBhcmEgbyBkaWEgMS4KICAgIFNVRklYT19G
REM QUxBID0gcicoPzpccysoPzpub2ludGVyYWN0fGlkXHMrW1x3Ll0rfHdpdGhccytbXHcuXSso
REM PzpcKCg/OlteKCldfFwoW14oKV0qXCkpKlwpKT98XCgoPzpbXigpXXxcKFteKCldKlwpKSpc
REM KSkpKycKICAgIFNVRklYT19FU0NPTEhBID0gcicoPzpccypcKCg/OlteKCldfFwoW14oKV0q
REM XCkpKlwpKT8oPzpccytpZlxzKy4rPyk/XHMqOicKICAgIFBSRUZJSk9fRkFMQSA9IHInKD86
REM LT9bQS1aYS16MC05X11bQS1aYS16MC05Xy4tXSp8QHwnICsgUVNUUl9MT0NBTCArIHInKScK
REM ICAgIExFR0FDWV9ESUFMT0dPID0gcmUuY29tcGlsZShyJ14oPzooPzonICsgUFJFRklKT19G
REM QUxBICsgcicpXHMrKXswLDE2fSgnICsgUVNUUl9MT0NBTCArIHInKSg/Oig/OlxzKjopPyg/
REM OlxzKlx3Kik/fCcgKyBTVUZJWE9fRkFMQSArIHInfCcgKyBTVUZJWE9fRVNDT0xIQSArIHIn
REM KVxzKig/OiMuKik/JCcpCiAgICBVSV9SRVMgPSByZS5jb21waWxlKHInKD88IVx3KSg/Ol98
REM X198X19ffF9wKVxzKlwoXHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpJykKICAgIFZJU0lCTEVf
REM Q0FMTF9SRSA9IHJlLmNvbXBpbGUocidcYig/OnJlbnB5XC5pbnB1dHxyZW5weVwubm90aWZ5
REM fHJlbnB5XC5zYXl8Tm90aWZ5fENvbmZpcm18SW5wdXRWYWx1ZSlccypcKFxzKignICsgUVNU
REM Ul9MT0NBTCArIHInKScpCiAgICBURVhUX0NBTExfUkUgPSByZS5jb21waWxlKHInXGIoPzpU
REM ZXh0fFBhcmFtZXRlcml6ZWRUZXh0KVxzKlwoXHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpJykK
REM ICAgIFNIT1dfRElTUExBWV9URVhUX1JFID0gcmUuY29tcGlsZSgKICAgICAgICByJ1xic2hv
REM d1xzKyg/OnRleHR8Y3JlZGl0cyg/Ol9oZWFkZXJ8X3RleHR8X1tBLVphLXowLTlfXSspP3xb
REM QS1aYS16X11bQS1aYS16MC05X10qKD86dGV4dHxjYXB0aW9ufG1lc3NhZ2V8ZGlhbG9nfGxh
REM YmVsfHRpdGxlfGhlYWRlcnxib2R5KVtBLVphLXowLTlfXSopXHMrKCcgKyBRU1RSX0xPQ0FM
REM ICsgcicpJwogICAgKQogICAgVVBEQVRFQ09OU09MRV9NRVNTQUdFX1JFID0gcmUuY29tcGls
REM ZSgKICAgICAgICByJ1xiKD86dXBkYXRlY29uc29sZXx1cGRhdGVjb25zb2xlX2NsZWFyYWxs
REM KVxzKlwoW14sXSssXHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpJwogICAgKQogICAgVklTSUJM
REM RV9LV0FSR19SRSA9IHJlLmNvbXBpbGUoCiAgICAgICAgcidcYig/Om1lc3NhZ2V8dGV4dHxj
REM YXB0aW9ufHByb21wdHx0aXRsZSlccyo9XHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpJwogICAg
REM KQogICAgRElBTE9HX0NBTExfUkUgPSByZS5jb21waWxlKAogICAgICAgIHInXGIoPzpkaWFs
REM b2d8c2hvd19kaWFsb2cpXHMqXChbXlxuXSo/XGIoPzptZXNzYWdlfHRleHR8Y2FwdGlvbnxw
REM cm9tcHQpXHMqPVxzKignICsgUVNUUl9MT0NBTCArIHInKScKICAgICkKICAgIENBTExfU0NS
REM RUVOX0RJQUxPR19SRSA9IHJlLmNvbXBpbGUoCiAgICAgICAgcidcYig/OmNhbGx8c2hvdylc
REM cytzY3JlZW5ccytkaWFsb2dccypcKFxzKignICsgUVNUUl9MT0NBTCArIHInKScKICAgICkK
REM ICAgIFJFTlBZX0NBTExfU0NSRUVOX0RJQUxPR19SRSA9IHJlLmNvbXBpbGUoCiAgICAgICAg
REM cidcYnJlbnB5XC4oPzpjYWxsX3NjcmVlbnxzaG93X3NjcmVlbilccypcKFxzKltcIlwnXWRp
REM YWxvZ1tcIlwnXVxzKixccyooJyArIFFTVFJfTE9DQUwgKyByJyknLAogICAgICAgIHJlLkkK
REM ICAgICkKICAgIERJQUxPR19TSE9XX09CSkVDVF9SRSA9IHJlLmNvbXBpbGUoCiAgICAgICAg
REM cidcYig/OlNob3d8cmVucHlcLig/OnNob3dfc2NyZWVufGNhbGxfc2NyZWVuKSlccypcKFte
REM XG5dKj8oPzpcYnNjcmVlblxzKj1ccyopP1tcIlwnXWRpYWxvZ1tcIlwnXScsCiAgICAgICAg
REM cmUuSQogICAgKQogICAgU0hPV19NRVNTQUdFX0tXQVJHX1JFID0gcmUuY29tcGlsZSgKICAg
REM ICAgICByJ1xiKD86U2hvd3xzaG93fHJlbnB5XC4oPzpzaG93X3NjcmVlbnxjYWxsX3NjcmVl
REM bikpXHMqXChbXlxuXSo/XGJtZXNzYWdlXHMqPVxzKignICsgUVNUUl9MT0NBTCArIHInKScs
REM CiAgICAgICAgcmUuSQogICAgKQogICAgRVhDRVBUSU9OX01FU1NBR0VfUkUgPSByZS5jb21w
REM aWxlKAogICAgICAgIHInXGIoPzpyZW5weVwuKD86ZXJyb3J8bm90aWZ5KXwoPzpFeGNlcHRp
REM b258UnVudGltZUVycm9yfFZhbHVlRXJyb3J8VHlwZUVycm9yfEFzc2VydGlvbkVycm9yKSlc
REM cypcKFxzKignICsgUVNUUl9MT0NBTCArIHInKScKICAgICkKICAgIFNDUkVFTl9URVhUX1JF
REM ID0gcmUuY29tcGlsZShyJ15ccyooPzp0ZXh0fHRleHRidXR0b258YnV0dG9ufGxhYmVsfHBy
REM b21wdHx0b29sdGlwfGNvbmZpcm18Y2FwdGlvbilccysoPzpcKFxzKik/KD86X1xzKlwoXHMq
REM KT8oJyArIFFTVFJfTE9DQUwgKyByJyknLCByZS5JKQogICAgVUlfRElTUExBWV9BUkdfUkUg
REM PSByZS5jb21waWxlKHInXlxzKig/OnRleHR8dGV4dGJ1dHRvbnxidXR0b258bGFiZWx8cHJv
REM bXB0fHRvb2x0aXB8Y29uZmlybXxjYXB0aW9uKVxzKyg/OlwoXHMqKT8oPzpfXHMqXChccyop
REM PygnICsgUVNUUl9MT0NBTCArIHInKScsIHJlLkkpCiAgICAjIFByb3ByaWVkYWRlcyBSZW4n
REM UHkgcXVlIGVuY2VycmFtIGEgZXhwcmVzc8OjbyBwcmluY2lwYWwgZGUgdW0gZGlzcGxheWFi
REM bGUuCiAgICAjIMOJIHVzYWRhIGFwZW5hcyBwYXJhIHByb2N1cmFyIGZyYWdtZW50b3MgbGl0
REM ZXJhaXMgbmEgZXhwcmVzc8OjbyBleGliaWRhLAogICAgIyBzZW0gYXRyYXZlc3NhciBwYXJh
REM IGBhY3Rpb25gLCBgc3R5bGVgLCBjb29yZGVuYWRhcyBvdSBvdXRyb3MgYXJndW1lbnRvcy4K
REM ICAgIFNDUkVFTl9URVhUX1BST1BFUlRJRVMgPSBmcm96ZW5zZXQoKAogICAgICAgICdhY3Rp
REM b24nLCdhbHRlcm5hdGUnLCdhdCcsJ2FjdGl2YXRlX3NvdW5kJywnYmFja2dyb3VuZCcsJ2Rl
REM ZmF1bHQnLCdmb2N1c19tYXNrJywKICAgICAgICAnaG92ZXJfc291bmQnLCdob3ZlcmVkJywn
REM aWQnLCdrZXknLCdrZXlzeW0nLCdtb2RhbCcsJ21vdXNlJywncGFkZGluZycsJ3BvcycsCiAg
REM ICAgICAgJ3NlbnNpdGl2ZScsJ3NlbGVjdGVkJywnc3R5bGUnLCdzdHlsZV9wcmVmaXgnLCd0
REM ZXh0X2FsaWduJywndGV4dF9jb2xvcicsCiAgICAgICAgJ3RleHRfZm9udCcsJ3RleHRfc2l6
REM ZScsJ3RleHRfc3R5bGUnLCd0b29sdGlwJywndW5ob3ZlcmVkJywneGFsaWduJywneGFuY2hv
REM cicsCiAgICAgICAgJ3hmaWxsJywneG1heGltdW0nLCd4bWluaW11bScsJ3hvZmZzZXQnLCd4
REM cGFkZGluZycsJ3hwb3MnLCd4c2l6ZScsJ3h6b29tJywKICAgICAgICAneWFsaWduJywneWFu
REM Y2hvcicsJ3lmaWxsJywneW1heGltdW0nLCd5bWluaW11bScsJ3lvZmZzZXQnLCd5cGFkZGlu
REM ZycsJ3lwb3MnLAogICAgICAgICd5c2l6ZScsJ3l6b29tJywnc2l6ZV9ncm91cCcsJ2NsaXBw
REM aW5nJywnbGF5b3V0JywndmVydGljYWwnLCdzcGFjaW5nJywnbWFyZ2luJywKICAgICAgICAn
REM YWxpZ24nLCdhbmNob3InLCdhcmVhJywneG1hcmdpbicsJ3ltYXJnaW4nLCd4YXJvdW5kJywn
REM eWFyb3VuZCcsJ3hhZGp1c3RtZW50JywKICAgICAgICAneWFkanVzdG1lbnQnLCdzZWxlY3Rl
REM ZF9pZGxlJywnc2VsZWN0ZWRfaG92ZXInLCdpbnNlbnNpdGl2ZScsJ3N1YnN0aXR1dGUnLAog
REM ICAgICAgICd0ZXh0X3hhbGlnbicsJ3RleHRfeWFsaWduJywndGV4dF9vdXRsaW5lcycsJ3Rl
REM eHRfYm9sZCcsJ3RleHRfaXRhbGljJywKICAgICAgICAndGV4dF9rZXJuaW5nJywndGV4dF9s
REM aW5lX3NwYWNpbmcnLCd0ZXh0X2xpbmVfbGVhZGluZycsJ3RleHRfaW5kZW50JywndGV4dF9q
REM dXN0aWZ5JywKICAgICAgICAndGV4dF9zbG93JywndGV4dF9zbG93X2RvbmUnLCd0ZXh0X21p
REM bl93aWR0aCcsJ3RleHRfbWF4X3dpZHRoJywndGV4dF9taW5pbXVtJywKICAgICAgICAndGV4
REM dF9tYXhpbXVtJywndGV4dF9maXQnLCdsYW5ndWFnZScsJ3N0eWxlX2dyb3VwJwogICAgKSkK
REM CiAgICBkZWYgZmltX2V4cHJlc3Nhb190ZXh0b19zY3JlZW4obGluaGEsIGluaWNpbyk6CiAg
REM ICAgICAgIiIiRW5jb250cmEgbyBmaW5hbCBkbyB0ZXh0byBkZSB0ZXh0L3RleHRidXR0b24s
REM IHJlc3BlaXRhbmRvIHN0cmluZ3MgZSBwYXLDqm50ZXNlcy4iIiIKICAgICAgICBxdW90ZSA9
REM IE5vbmU7IGVzY2FwZSA9IEZhbHNlOyBwYXJlbiA9IGJyYWNrZXQgPSBicmFjZSA9IDA7IGkg
REM PSBpbmljaW8KICAgICAgICB3aGlsZSBpIDwgbGVuKGxpbmhhKToKICAgICAgICAgICAgY2gg
REM PSBsaW5oYVtpXQogICAgICAgICAgICBpZiBxdW90ZSBpcyBub3QgTm9uZToKICAgICAgICAg
REM ICAgICAgIGlmIGVzY2FwZTogZXNjYXBlID0gRmFsc2UKICAgICAgICAgICAgICAgIGVsaWYg
REM Y2ggPT0gJ1xcJzogZXNjYXBlID0gVHJ1ZQogICAgICAgICAgICAgICAgZWxpZiBjaCA9PSBx
REM dW90ZTogcXVvdGUgPSBOb25lCiAgICAgICAgICAgICAgICBpICs9IDE7IGNvbnRpbnVlCiAg
REM ICAgICAgICAgIGlmIGNoIGluICgnIicsICInIiwgJ2AnKToKICAgICAgICAgICAgICAgIHF1
REM b3RlID0gY2g7IGkgKz0gMTsgY29udGludWUKICAgICAgICAgICAgaWYgY2ggPT0gJygnOiBw
REM YXJlbiArPSAxCiAgICAgICAgICAgIGVsaWYgY2ggPT0gJyknIGFuZCBwYXJlbjogcGFyZW4g
REM LT0gMQogICAgICAgICAgICBlbGlmIGNoID09ICdbJzogYnJhY2tldCArPSAxCiAgICAgICAg
REM ICAgIGVsaWYgY2ggPT0gJ10nIGFuZCBicmFja2V0OiBicmFja2V0IC09IDEKICAgICAgICAg
REM ICAgZWxpZiBjaCA9PSAneyc6IGJyYWNlICs9IDEKICAgICAgICAgICAgZWxpZiBjaCA9PSAn
REM fScgYW5kIGJyYWNlOiBicmFjZSAtPSAxCiAgICAgICAgICAgIGVsaWYgY2ggPT0gJzonIGFu
REM ZCBub3QgKHBhcmVuIG9yIGJyYWNrZXQgb3IgYnJhY2UpOgogICAgICAgICAgICAgICAgcmV0
REM dXJuIGkKICAgICAgICAgICAgaWYgY2guaXNzcGFjZSgpIGFuZCBub3QgKHBhcmVuIG9yIGJy
REM YWNrZXQgb3IgYnJhY2UpOgogICAgICAgICAgICAgICAgbV9wcm9wID0gcmUubWF0Y2gocidc
REM cysoW0EtWmEtel9dW0EtWmEtejAtOV9dKilcYicsIGxpbmhhW2k6XSkKICAgICAgICAgICAg
REM ICAgIGlmIG1fcHJvcCBhbmQgbV9wcm9wLmdyb3VwKDEpLmxvd2VyKCkgaW4gU0NSRUVOX1RF
REM WFRfUFJPUEVSVElFUzoKICAgICAgICAgICAgICAgICAgICByZXR1cm4gaQogICAgICAgICAg
REM ICBpICs9IDEKICAgICAgICByZXR1cm4gbGVuKGxpbmhhKQoKICAgIE1FTlVfT1BUSU9OX1JF
REM ID0gcmUuY29tcGlsZShyJ15ccyooJyArIFFTVFJfTE9DQUwgKyByJylccyooPzooPzppZlxi
REM LiopfDopP1xzKig/OiMuKik/JCcpCiAgICBFWFBMSUNJVF9TQVlfUkUgPSByZS5jb21waWxl
REM KHInXlxzKignICsgUVNUUl9MT0NBTCArIHInKVxzKygnICsgUVNUUl9MT0NBTCArIHInKSg/
REM OlxzfCQpJykKICAgIFZJU0lWRUxfQVNTSUdOX1JFID0gcmUuY29tcGlsZShyJ15ccyooPzpk
REM ZWZpbmV8ZGVmYXVsdClccysoY29uZmlnXC5uYW1lfGd1aVwuKD86YWJvdXR8bmFtZXx0aXRs
REM ZXxtYWluX21lbnVfY2FwdGlvbikpXHMqPVxzKignICsgUVNUUl9MT0NBTCArIHInKVxzKiQn
REM KQogICAgUFlUSE9OX1JFVFVSTl9URVhUX1JFID0gcmUuY29tcGlsZShyJ15ccypyZXR1cm5c
REM cysoJyArIFFTVFJfTE9DQUwgKyByJylccyokJywgcmUuSSkKICAgIFVQREFURUNPTlNPTEVf
REM QlJPQURfUkUgPSByZS5jb21waWxlKHInXGIoPzp1cGRhdGVjb25zb2xlfHVwZGF0ZWNvbnNv
REM bGVfY2xlYXJhbGwpXHMqXChccyooPzonICsgUVNUUl9MT0NBTCArIHInKVxzKixccyooJyAr
REM IFFTVFJfTE9DQUwgKyByJyknLCByZS5JKQogICAgb2N1cGFkb3MgPSBzZXQoKQoKICAgIGRl
REM ZiByZWdpc3RyYXIobGluaGFfbnVtZXJvLCBpbmljaW9fbGltcG8sIGZpbV9saW1wbywgdHJl
REM Y2hvLCB0aXBvLCBjb25maWFuY2EsIGNvbnRleHRvLCBvcmlnaW5hbF9tYXBhPU5vbmUpOgog
REM ICAgICAgIGlmIG5vdCB0cmVjaG86CiAgICAgICAgICAgIHJldHVybgogICAgICAgIGlmIHRp
REM cG8gbm90IGluICgncG9lbWFfY29ycG8nLCAnZ2V0dGV4dF9tdWx0aWxpbmhhJywgJ211bHRp
REM bGluaGFfcmVucHknLCAnbW9ub2xvZ29fdHJpcGxhcycpIGFuZCB0cmVjaG9bMF0gbm90IGlu
REM ICgnIicsICInIiwgJ2AnKToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgaWYgdGlwbyBu
REM b3QgaW4gKCdwb2VtYV9jb3JwbycsICdnZXR0ZXh0X211bHRpbGluaGEnLCAnbXVsdGlsaW5o
REM YV9yZW5weScsICdtb25vbG9nb190cmlwbGFzJyk6CiAgICAgICAgICAgIGluaWNpb19yZWFs
REM ID0gbGVuKHByZWZpeG9fd3MpICsgaW5pY2lvX2xpbXBvCiAgICAgICAgICAgIGZpbV9yZWFs
REM ID0gbGVuKHByZWZpeG9fd3MpICsgZmltX2xpbXBvCiAgICAgICAgICAgICMgTyBzcGFuIHBy
REM ZWNpc2EgY29pbmNpZGlyIGV4YXRhbWVudGUgY29tIHVtYSBzdHJpbmcgcmVhbCBkYSBsaW5o
REM YS4KICAgICAgICAgICAgIyBBbMOpbSBkbyBRU1RSIGxlZ2FkbywgYWNlaXRhbW9zIHN0cmlu
REM Z3MgUmVuJ1B5IGVzcGVjaWFpcyAoYC4uLmAgZQogICAgICAgICAgICAjIHIiLi4uIi9yJy4u
REM LicvcmAuLi5gKS4gTyBwcmVmaXhvIHIgZmljYSBmb3JhIGRvIHNwYW4uCiAgICAgICAgICAg
REM IHNwYW5fbm9ybWFsID0gYW55KAogICAgICAgICAgICAgICAgbS5zdGFydCgpID09IGluaWNp
REM b19yZWFsIGFuZCBtLmVuZCgpID09IGZpbV9yZWFsIGFuZCBtLmdyb3VwKDApID09IHRyZWNo
REM bwogICAgICAgICAgICAgICAgZm9yIG0gaW4gcmUuZmluZGl0ZXIoUVNUUl9MT0NBTCwgbGlu
REM aGFfc2VtX2ZpbSkKICAgICAgICAgICAgKQogICAgICAgICAgICBzcGFuX2VzcGVjaWFsID0g
REM YW55KAogICAgICAgICAgICAgICAgaW5pY2lvID09IGluaWNpb19yZWFsIGFuZCBmaW0gPT0g
REM ZmltX3JlYWwgYW5kIGxpdGVyYWwgPT0gdHJlY2hvCiAgICAgICAgICAgICAgICBmb3IgaW5p
REM Y2lvLCBmaW0sIGxpdGVyYWwsIF9yYXcgaW4gaXRlcl9yZW5weV9saXRlcmFpc19lc3BlY2lh
REM aXMobGluaGFfc2VtX2ZpbSkKICAgICAgICAgICAgKQogICAgICAgICAgICBpZiBub3QgKHNw
REM YW5fbm9ybWFsIG9yIHNwYW5fZXNwZWNpYWwpOgogICAgICAgICAgICAgICAgcmV0dXJuCiAg
REM ICAgICAgIyBBbGd1bWFzIGNhdGVnb3JpYXMgZXNwZWNpYWlzIHNhbyB0ZXh0byBkZSBqb2dh
REM ZG9yIG1lc21vIHF1YW5kbwogICAgICAgICMgbyBsaXRlcmFsLCBpc29sYWRhbWVudGUsIHBh
REM cmVjZSB1bSBpZGVudGlmaWNhZG9yL2NvbWFuZG8gdGVjbmljby4KICAgICAgICAjIEV4Ljog
REM cGFsYXZyYXMgZG8gbWluaWpvZ28gZGUgcG9lbWFzIGNvbW8gInBsYXkiIGUgbyBub21lIGRl
REM CiAgICAgICAgIyBncnVwbyBkbyB0ZWxlZm9uZSBjb21vICJXZWxjb21lIi4KICAgICAgICAj
REM IFVSTCBwdXJhIGV4aWJpZGEgZW0gZGnDoWxvZ28vVUkgw6kgcHJlc2VydmFkYSBubyBtYXBh
REM LCBwb3LDqW0gbWFyY2FkYQogICAgICAgICMgY29tbyBgdXJsX3Zpc2l2ZWxgIHBhcmEgbnVu
REM Y2Egc2VyIGVudmlhZGEgYW8gR29vZ2xlIFRyYW5zbGF0ZS4KICAgICAgICBpZiBQVVJFX1ZJ
REM U0lCTEVfVVJMX1JFLm1hdGNoKHN0cmlwX3F1b3Rlcyh0cmVjaG8pLnN0cmlwKCkpIGFuZCB0
REM aXBvIGluICgKICAgICAgICAgICAgICAgICdkaWFsb2dvJywgJ25hcnJhdGl2YScsICd1aScs
REM ICdyZW5weV9uYXRpdm9fZGlhbG9nbycsCiAgICAgICAgICAgICAgICAncmVucHlfbmF0aXZv
REM X3N0cmluZycsICdub21lX2dydXBvJywgJ21vbm9sb2dvX3RyaXBsYXMnKToKICAgICAgICAg
REM ICAgdGlwbyA9ICd1cmxfdmlzaXZlbCcKICAgICAgICAjIEV4Y2XDp8OjbyBjb250ZXh0dWFs
REM IGVzdHJlaXRhOiB1bSBsaXRlcmFsIHF1ZSDDqSBwYXJ0ZSBkYSBleHByZXNzw6NvCiAgICAg
REM ICAgIyBwcmluY2lwYWwgZGUgYHRleHRgL2B0ZXh0YnV0dG9uYCDDqSBjb250ZcO6ZG8gdmlz
REM dWFsIGNvbXByb3ZhZG8uIE5lc3NhCiAgICAgICAgIyBwb3Npw6fDo28sIHBhbGF2cmFzIGN1
REM cnRhcyBjb21vICJwbGF5IiwgImNhbWVyYSIgb3UgIndpdGgiIHBvZGVtIHBhcmVjZXIKICAg
REM ICAgICAjIGlkZW50aWZpY2Fkb3JlcyBwYXJhIG8gZmlsdHJvIGdsb2JhbCwgbWFzIHPDo28g
REM csOzdHVsb3MgdmlzdG9zIHBlbG8gdXN1w6FyaW8uCiAgICAgICAgIyBBIHJlZ3JhIHPDsyDD
REM qSBhdGl2YWRhIHBlbG8gZGV0ZWN0b3IgYWJhaXhvLCBxdWUgbGltaXRhIG8gc3BhbiDDoCBl
REM eHByZXNzw6NvCiAgICAgICAgIyBkbyB0ZXh0byBlIHBhcmEgYW50ZXMgZGUgcHJvcHJpZWRh
REM ZGVzIGNvbW8gYGFjdGlvbmAsIGV2aXRhbmRvIGNhcHR1cmFyCiAgICAgICAgIyBub21lcyBk
REM ZSB0ZWxhcywgdmFyacOhdmVpcyBlIHN0cmluZ3MgdMOpY25pY2FzIGRlIGHDp8O1ZXMuCiAg
REM ICAgICAgdWlfZXhwcl92aXNpdmVsID0gKHRpcG8gPT0gJ3VpJyBhbmQgY29udGV4dG8gPT0g
REM J2ZyYWdtZW50byB0ZXh0dWFsIGVzdMOhdGljbyBlbSBleHByZXNzw6NvIGRlIHRleHQvdGV4
REM dGJ1dHRvbicpCiAgICAgICAgaWYgdGlwbyBub3QgaW4gKCdwb2VtYV9wYWxhdnJhJywgJ3Bv
REM ZW1hX3BhbGF2cmFfdHh0JywgJ25vbWVfZ3J1cG8nLCAndXJsX3Zpc2l2ZWwnKToKICAgICAg
REM ICAgICAgIyBVbSBwbGFjZWhvbGRlciBwdXJvIGNvbW8ge2hvdXJ9OnttaW51dGV9IG91IHtt
REM b250aH0ve2RheX0ve3llYXJ9CiAgICAgICAgICAgICMgw6kgdGV4dG8gdHJhZHV6w612ZWwg
REM cXVhbmRvIHZlaW8gZXhwbGljaXRhbWVudGUgZGUgXygpL19fKCkvX3AoKS4KICAgICAgICAg
REM ICAgIyBOw6NvIGRlaXhlIG8gZmlsdHJvIHTDqWNuaWNvIHRyYW5zZm9ybcOhLWxvIGVtICJw
REM b250dWHDp8OjbyBzZW0gdGV4dG8iLgogICAgICAgICAgICBwbGFjZWhvbGRlcl9nZXR0ZXh0
REM ID0gKAogICAgICAgICAgICAgICAgdGlwbyA9PSAndWknIGFuZAogICAgICAgICAgICAgICAg
REM UExBQ0VIT0xERVJfVFJBRFVaSVZFTF9SRS5tYXRjaChzdHJpcF9xdW90ZXModHJlY2hvKSkg
REM aXMgbm90IE5vbmUKICAgICAgICAgICAgKQogICAgICAgICAgICBpZiAobm90IHBsYWNlaG9s
REM ZGVyX2dldHRleHQgYW5kIG5vdCB1aV9leHByX3Zpc2l2ZWwgYW5kCiAgICAgICAgICAgICAg
REM ICAgICAgcGFyZWNlX3RleHRvX3RlY25pY28odHJlY2hvLCBpbmRpY2VfYXJxdWl2b3M9aW5k
REM aWNlX2FycXVpdm9zKSk6CiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICBpZiAodGlw
REM byBub3QgaW4gKCdkaWFsb2dvJywgJ25hcnJhdGl2YScsICdwb2VtYV9wYWxhdnJhJywgJ25v
REM bWVfZ3J1cG8nLCAndXJsX3Zpc2l2ZWwnKQogICAgICAgICAgICAgICAgYW5kIG5vdCBwbGFj
REM ZWhvbGRlcl9nZXR0ZXh0CiAgICAgICAgICAgICAgICBhbmQgbm90IHRlbV9jb250ZXVkb190
REM cmFkdXppdmVsKHRyZWNobykpOgogICAgICAgICAgICByZXR1cm4KICAgICAgICBjaGF2ZV9v
REM cmlnZW0gPSAobGluaGFfbnVtZXJvLCBpbmljaW9fbGltcG8gKyBsZW4ocHJlZml4b193cyks
REM IGZpbV9saW1wbyArIGxlbihwcmVmaXhvX3dzKSkKICAgICAgICBpZiBjaGF2ZV9vcmlnZW0g
REM aW4gcG9lbWFzX2Jsb3F1ZWFkb3M6CiAgICAgICAgICAgIHJldHVybgogICAgICAgIGNoYXZl
REM ID0gKGxpbmhhX251bWVybywgaW5pY2lvX2xpbXBvLCBmaW1fbGltcG8pCiAgICAgICAgaWYg
REM Y2hhdmUgaW4gb2N1cGFkb3M6CiAgICAgICAgICAgIHJldHVybgogICAgICAgIG9jdXBhZG9z
REM LmFkZChjaGF2ZSkKICAgICAgICByZWdpc3Ryb3MuYXBwZW5kKChpbmljaW9fbGltcG8sIGZp
REM bV9saW1wbywgdGlwbywgY29uZmlhbmNhLCBjb250ZXh0bywgdHJlY2hvLCBvcmlnaW5hbF9t
REM YXBhKSkKCiAgICBwb2VtYXNfcG9yX2xpbmhhLCBwb2VtYXNfYmxvcXVlYWRvcyA9IGV4dHJh
REM aXJfY29ycG9zX3BvZW1hcyhjYW1pbmhvLCBsaW5oYXNfcmF3KQogICAgZ2V0dGV4dF9wb3Jf
REM bGluaGEsIGxpbmhhc19nZXR0ZXh0X211bHRpbGluaGEgPSBleHRyYWlyX3N0cmluZ3NfZ2V0
REM dGV4dF9tdWx0aWxpbmhhKGNhbWluaG8sIGxpbmhhc19yYXcpCiAgICBtb25vbG9nb3NfcG9y
REM X2xpbmhhLCBsaW5oYXNfbW9ub2xvZ28gPSBfZXh0cmFpcl9tb25vbG9nb3NfdHJpcGxvc19y
REM ZW5weSgKICAgICAgICBjYW1pbmhvLCBsaW5oYXNfcmF3LCBsaW5oYXNfcHl0aG9uLCBsaW5o
REM YXNfYmxvY29zX3RlY25pY29zCiAgICApCiAgICBtdWx0aWxpbmhhc19wb3JfbGluaGEsIGxp
REM bmhhc19tdWx0aWxpbmhhID0gZXh0cmFpcl9zdHJpbmdzX211bHRpbGluaGFfcmVucHkoCiAg
REM ICAgICAgY2FtaW5obywgbGluaGFzX3JhdywgbGluaGFzX3B5dGhvbiwgbGluaGFzX2Jsb2Nv
REM c190ZWNuaWNvcwogICAgKQogICAgc2NyZWVuX2luZGVudCA9IE5vbmUKICAgIG1lbnVfc3Rh
REM Y2sgPSBbXQogICAgY29uZmlnX21lbnVfYmxvY28gPSBOb25lCiAgICAjIEFycXVpdm9zIGRl
REM IGxheW91dCBSZW4nUHkgbWFudMOqbSBwYXJ0ZSBkYSBVSSBkaXJldGFtZW50ZSBlbQogICAg
REM IyBQeXRob24uIEVzc2VzIHRleHRvcyBzw6NvIHZpc8OtdmVpcyBtZXNtbyBzZW0gYHRleHQo
REM KWAvYG1lbnVgIHRyYWRpY2lvbmFsOgogICAgIyBsYWJlbHMgZGUgY29uZmlnLm1haW5fbWVu
REM dS9jb25maWcuZ2FtZV9tZW51IGUgbWVuc2FnZW5zIGxheW91dC4qLgogICAgQ09ORklHX01B
REM SU5fTUVOVV9MQUJFTF9SRSA9IHJlLmNvbXBpbGUocideXHMqXChccyooPzp1KT8oJyArIFFT
REM VFJfTE9DQUwgKyByJylccyosJykKICAgIENPTkZJR19HQU1FX01FTlVfTEFCRUxfUkUgPSBy
REM ZS5jb21waWxlKHInXlxzKlwoXHMqKD86Tm9uZXwoPzp1KT8nICsgUVNUUl9MT0NBTCArIHIn
REM KVxzKixccyooPzp1KT8oJyArIFFTVFJfTE9DQUwgKyByJylccyosJykKICAgIExBWU9VVF9W
REM SVNJQkxFX0FTU0lHTl9SRSA9IHJlLmNvbXBpbGUocideXHMqbGF5b3V0XC5bQS1aXVtBLVow
REM LTlfXSpccyo9XHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpXHMqJCcpCiAgICBmb3IgaWR4LCBs
REM aW5oYV9yYXcgaW4gZW51bWVyYXRlKGxpbmhhc19yYXcpOgogICAgICAgIG51bWVyb19saW5o
REM YSA9IGlkeCArIDEKICAgICAgICBsaW5oYV9zZW1fZmltID0gbGluaGFfcmF3LnJzdHJpcCgi
REM XHJcbiIpCiAgICAgICAgbGluaGFfbGltcGEgPSBsaW5oYV9zZW1fZmltLnN0cmlwKCkKICAg
REM ICAgICBpZiBub3QgbGluaGFfbGltcGEgb3IgbGluaGFfbGltcGEuc3RhcnRzd2l0aCgnIycp
REM OgogICAgICAgICAgICBjb250aW51ZQoKICAgICAgICAjIFJlZ3JhIGdsb2JhbDogbyB0w610
REM dWxvIGRlZmluaWRvIHBvciBgY29uZmlnLm5hbWVgIHBlcm1hbmVjZSBzZW1wcmUgb3JpZ2lu
REM YWwuCiAgICAgICAgIyBCbG9xdWVpYSBzb21lbnRlIGVzc2EgZGVmaW5pw6fDo287IG8gcmVz
REM dGFudGUgZG8gb3B0aW9ucy5ycHkgY29udGludWEgbm9ybWFsLgogICAgICAgIGlmIENPTkZJ
REM R19OQU1FX0RFRklORV9SRS5tYXRjaChsaW5oYV9zZW1fZmltKToKICAgICAgICAgICAgY29u
REM dGludWUKCiAgICAgICAgIyBNZW51cyBwYWRyw6NvIGRvIFJlbidQeTogc29tZW50ZSBvIHLD
REM s3R1bG8gcmVhbG1lbnRlIG1vc3RyYWRvIGFvCiAgICAgICAgIyBqb2dhZG9yIGVudHJhIG5v
REM IG1hcGE7IGHDp8O1ZXMgY29tbyBgImxvYWRfc2NyZWVuImAvYCJUcnVlImAgZmljYW0gZm9y
REM YS4KICAgICAgICBpZiByZS5tYXRjaChyJ15ccypjb25maWdcLm1haW5fbWVudVxzKj1ccypc
REM WycsIGxpbmhhX2xpbXBhLCByZS5JKToKICAgICAgICAgICAgY29uZmlnX21lbnVfYmxvY28g
REM PSAnbWFpbicKICAgICAgICBlbGlmIHJlLm1hdGNoKHInXlxzKmNvbmZpZ1wuZ2FtZV9tZW51
REM XHMqPVxzKlxbJywgbGluaGFfbGltcGEsIHJlLkkpOgogICAgICAgICAgICBjb25maWdfbWVu
REM dV9ibG9jbyA9ICdnYW1lJwogICAgICAgIGVsaWYgY29uZmlnX21lbnVfYmxvY28gYW5kIGxp
REM bmhhX2xpbXBhID09ICddJzoKICAgICAgICAgICAgY29uZmlnX21lbnVfYmxvY28gPSBOb25l
REM CiAgICAgICAgcHJlZml4b193cyA9IGxpbmhhX3NlbV9maW1bOmxlbihsaW5oYV9zZW1fZmlt
REM KSAtIGxlbihsaW5oYV9zZW1fZmltLmxzdHJpcCgpKV0KICAgICAgICBuaXZlbF9pbmRlbnQg
REM PSBsZW4ocHJlZml4b193cykKICAgICAgICByZWdpc3Ryb3MgPSBbXQoKICAgICAgICBpZiBj
REM b25maWdfbWVudV9ibG9jbyA9PSAnbWFpbic6CiAgICAgICAgICAgIG1fY2ZnbWVudSA9IENP
REM TkZJR19NQUlOX01FTlVfTEFCRUxfUkUubWF0Y2gobGluaGFfbGltcGEpCiAgICAgICAgICAg
REM IGlmIG1fY2ZnbWVudToKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEs
REM IG1fY2ZnbWVudS5zdGFydCgxKSwgbV9jZmdtZW51LmVuZCgxKSwgbV9jZmdtZW51Lmdyb3Vw
REM KDEpLCAndWknLCAxMDAsICdyw7N0dWxvIHZpc8OtdmVsIGRlIGNvbmZpZy5tYWluX21lbnUn
REM KQogICAgICAgIGVsaWYgY29uZmlnX21lbnVfYmxvY28gPT0gJ2dhbWUnOgogICAgICAgICAg
REM ICBtX2NmZ21lbnUgPSBDT05GSUdfR0FNRV9NRU5VX0xBQkVMX1JFLm1hdGNoKGxpbmhhX2xp
REM bXBhKQogICAgICAgICAgICBpZiBtX2NmZ21lbnU6CiAgICAgICAgICAgICAgICByZWdpc3Ry
REM YXIobnVtZXJvX2xpbmhhLCBtX2NmZ21lbnUuc3RhcnQoMSksIG1fY2ZnbWVudS5lbmQoMSks
REM IG1fY2ZnbWVudS5ncm91cCgxKSwgJ3VpJywgMTAwLCAncsOzdHVsbyB2aXPDrXZlbCBkZSBj
REM b25maWcuZ2FtZV9tZW51JykKCiAgICAgICAgIyBSZWdyYSBnbG9iYWw6IGZyYWdtZW50b3Mg
REM Zml4b3MgZW0gcsOzdHVsb3MgZGluw6JtaWNvcyBkZSBib3TDtWVzLgogICAgICAgICMgRXgu
REM OiBidXR0b25fbGlzdC5hcHBlbmQoKCgiZWRpdCBjaGlsZDoge30iKS5mb3JtYXQodmFsdWUp
REM LCAuLi4pKS4KICAgICAgICAjIE8gdGV4dG8gZG8gdGVtcGxhdGUgw6kgZXhpYmlkbyBjb21v
REM IGJvdMOjbzsgbyBhcmd1bWVudG8gZGUgZm9ybWF0IHBlcm1hbmVjZSBpbnRhY3RvLgogICAg
REM ICAgIGlmIHJlLnNlYXJjaChyJ1xiYnV0dG9uX2xpc3RccypcLlxzKmFwcGVuZFxzKlwoJywg
REM bGluaGFfbGltcGEsIHJlLkkpOgogICAgICAgICAgICBtX2J0bl90ZW1wbGF0ZSA9IHJlLnNl
REM YXJjaChyJygnICsgUVNUUl9MT0NBTCArIHInKVxzKlwuXHMqZm9ybWF0XHMqXCgnLCBsaW5o
REM YV9saW1wYSkKICAgICAgICAgICAgaWYgbV9idG5fdGVtcGxhdGU6CiAgICAgICAgICAgICAg
REM ICBxX2J0biA9IG1fYnRuX3RlbXBsYXRlLmdyb3VwKDEpCiAgICAgICAgICAgICAgICB0cnk6
REM CiAgICAgICAgICAgICAgICAgICAgdl9idG4gPSBkZWNvZGlmaWNhcl9saXRlcmFsX3RyYWR1
REM Y2FvKHFfYnRuKQogICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAg
REM ICAgICAgICAgICB2X2J0biA9IHN0cmlwX3F1b3RlcyhxX2J0bikKICAgICAgICAgICAgICAg
REM IGlmIHRlbV9jb250ZXVkb190cmFkdXppdmVsKHFfYnRuKSBhbmQgcmUuc2VhcmNoKHInW0Et
REM WmEtesOALcOWw5gtw7bDuC3Dv117Mn0nLCByZS5zdWIocidce1tee31dKlx9JywgJyAnLCB2
REM X2J0bikpOgogICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG1f
REM YnRuX3RlbXBsYXRlLnN0YXJ0KDEpLCBtX2J0bl90ZW1wbGF0ZS5lbmQoMSksIHFfYnRuLAog
REM ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAndWknLCA5OCwgJ21vZGVsbyB0ZXh0dWFs
REM IGRlIGJvdMOjbyBkaW7Dom1pY28nKQoKICAgICAgICAjIFJlZ3JhIGdsb2JhbDogZnJhZ21l
REM bnRvIHRleHR1YWwgY29uY2F0ZW5hZG8gZW0gbWVuc2FnZW0vbm90aWZpY2HDp8OjbyB2aXPD
REM rXZlbC4KICAgICAgICAjIENhcHR1cmEgc29tZW50ZSBsaXRlcmFpcyBsaWdhZG9zIHBvciAr
REM IGRlbnRybyBkZSBub3RpZnkvZXJyb3IsIHNlbSB0cmFkdXppcgogICAgICAgICMgYSB2YXJp
REM w6F2ZWwgb3UgYSBleHByZXNzw6NvIHF1ZSBwcm9kdXogbyB2YWxvciBkaW7Dom1pY28uCiAg
REM ICAgICAgbV9ub3RpZnkgPSByZS5zZWFyY2gocidcYig/OnJlbnB5XC4pPyg/Om5vdGlmeXxl
REM cnJvcilccypcKCcsIGxpbmhhX2xpbXBhLCByZS5JKQogICAgICAgIGlmIG1fbm90aWZ5Ogog
REM ICAgICAgICAgICB0cmVjaG9fbm90aWZ5ID0gbGluaGFfbGltcGFbbV9ub3RpZnkuc3RhcnQo
REM KTpdCiAgICAgICAgICAgIGZvciBtX25vdGlmeV9waWVjZSBpbiByZS5maW5kaXRlcihyJ1wr
REM XHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpJywgdHJlY2hvX25vdGlmeSk6CiAgICAgICAgICAg
REM ICAgICBxX25vdGlmeSA9IG1fbm90aWZ5X3BpZWNlLmdyb3VwKDEpCiAgICAgICAgICAgICAg
REM ICBpZiB0ZW1fY29udGV1ZG9fdHJhZHV6aXZlbChxX25vdGlmeSk6CiAgICAgICAgICAgICAg
REM ICAgICAgaW5pX25vdGlmeSA9IG1fbm90aWZ5LnN0YXJ0KCkgKyBtX25vdGlmeV9waWVjZS5z
REM dGFydCgxKQogICAgICAgICAgICAgICAgICAgIGZpbV9ub3RpZnkgPSBtX25vdGlmeS5zdGFy
REM dCgpICsgbV9ub3RpZnlfcGllY2UuZW5kKDEpCiAgICAgICAgICAgICAgICAgICAgcmVnaXN0
REM cmFyKG51bWVyb19saW5oYSwgaW5pX25vdGlmeSwgZmltX25vdGlmeSwgcV9ub3RpZnksICd1
REM aScsIDk2LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZnJhZ21lbnRvIHRleHR1
REM YWwgZGUgbm90aWZpY2HDp8OjbyBkaW7Dom1pY2EnKQoKICAgICAgICAjIFJlZ3JhIGdsb2Jh
REM bDogcsOzdHVsbyBodW1hbm8gZW0gdHVwbGEgZGUgZ3J1cG8vb3DDp8O1ZXMsIHNlZ3VpZG8g
REM cG9yIHVtYQogICAgICAgICMgdHVwbGEgZGUgaWRlbnRpZmljYWRvcmVzIHTDqWNuaWNvcy4g
REM RXNzZXMgcsOzdHVsb3MgY29zdHVtYW0gYWxpbWVudGFyIG1lbnVzCiAgICAgICAgIyBlIGJv
REM dMO1ZXMgYSBwYXJ0aXIgZGUgZGFkb3MgZGUgY29uZmlndXJhw6fDo28sIHNlbSBhcGFyZWNl
REM ciBlbSBgdGV4dGJ1dHRvbmAuCiAgICAgICAgbV9ncm91cF9sYWJlbCA9IHJlLm1hdGNoKHIn
REM XlxzKlwoXHMqKCcgKyBRU1RSX0xPQ0FMICsgcicpXHMqLFxzKlwoXHMqKFtcIlwnXVtBLVph
REM LXpfXVtBLVphLXowLTlfXSpbXCJcJ10pXHMqLCcsIGxpbmhhX2xpbXBhKQogICAgICAgIGlm
REM IG1fZ3JvdXBfbGFiZWw6CiAgICAgICAgICAgIHFfZ3JvdXAgPSBtX2dyb3VwX2xhYmVsLmdy
REM b3VwKDEpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHZfZ3JvdXAgPSBkZWNv
REM ZGlmaWNhcl9saXRlcmFsX3RyYWR1Y2FvKHFfZ3JvdXApCiAgICAgICAgICAgIGV4Y2VwdCBF
REM eGNlcHRpb246CiAgICAgICAgICAgICAgICB2X2dyb3VwID0gc3RyaXBfcXVvdGVzKHFfZ3Jv
REM dXApCiAgICAgICAgICAgIGlmIHJlLnNlYXJjaChyJ1tBLVphLXrDgC3DlsOYLcO2w7gtw79d
REM Jywgdl9ncm91cCkgYW5kIChyZS5zZWFyY2gocidcc3xbLyYtXScsIHZfZ3JvdXApKSBhbmQg
REM dGVtX2NvbnRldWRvX3RyYWR1eml2ZWwocV9ncm91cCk6CiAgICAgICAgICAgICAgICByZWdp
REM c3RyYXIobnVtZXJvX2xpbmhhLCBtX2dyb3VwX2xhYmVsLnN0YXJ0KDEpLCBtX2dyb3VwX2xh
REM YmVsLmVuZCgxKSwgcV9ncm91cCwKICAgICAgICAgICAgICAgICAgICAgICAgICAndWknLCA5
REM NCwgJ3LDs3R1bG8gZGUgZ3J1cG8gZGUgb3DDp8O1ZXMgdXNhZG8gcGVsYSBpbnRlcmZhY2Un
REM KQoKICAgICAgICBtX2xheW91dF92aXNpYmxlID0gTEFZT1VUX1ZJU0lCTEVfQVNTSUdOX1JF
REM Lm1hdGNoKGxpbmhhX2xpbXBhKQogICAgICAgIGlmIG1fbGF5b3V0X3Zpc2libGU6CiAgICAg
REM ICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG1fbGF5b3V0X3Zpc2libGUuc3RhcnQo
REM MSksIG1fbGF5b3V0X3Zpc2libGUuZW5kKDEpLCBtX2xheW91dF92aXNpYmxlLmdyb3VwKDEp
REM LCAndWknLCAxMDAsICJtZW5zYWdlbSB2aXPDrXZlbCBkbyBsYXlvdXQgUmVuJ1B5IikKICAg
REM ICAgICAjIE9yw6FjdWxvIHNlbcOibnRpY28gbmF0aXZvOiBhZGljaW9uYSBzb21lbnRlIHVt
REM IGxpdGVyYWwgcXVlIG8gcHLDs3ByaW8KICAgICAgICAjIFJlbidQeSBjb25maXJtb3UgY29t
REM byBkacOhbG9nby9zdHJpbmcgZSBxdWUgZm9pIGxvY2FsaXphZG8gdW5pY2FtZW50ZQogICAg
REM ICAgICMgbmEgbWVzbWEgbGluaGEuIER1cGxpY2F0YXMgZmljYW0gY29tIG8gZGV0ZWN0b3Ig
REM ZXhpc3RlbnRlLgogICAgICAgIGNhbWluaG9fbm9ybSA9IGNhbWluaG8ucmVwbGFjZSgnXFwn
REM LCAnLycpLmxvd2VyKCkKICAgICAgICBvcmFjbGVfZmlsZSA9IHt9CiAgICAgICAgaWYgb3Jh
REM Y2xlX3Bvcl9hcnF1aXZvOgogICAgICAgICAgICByZWxfb3JhY2xlID0gb3MucGF0aC5yZWxw
REM YXRoKGNhbWluaG8sIE9SQUNVTE9fUkVOUFkuZ2V0KCdnYW1lX3Jvb3QnKSBvciBvcy5wYXRo
REM LmRpcm5hbWUoY2FtaW5obykpLnJlcGxhY2UoJ1xcJywgJy8nKS5sb3dlcigpCiAgICAgICAg
REM ICAgIG9yYWNsZV9maWxlID0gb3JhY2xlX3Bvcl9hcnF1aXZvLmdldChyZWxfb3JhY2xlLCB7
REM fSkKICAgICAgICAgICAgaWYgbm90IG9yYWNsZV9maWxlIGFuZCByZWxfb3JhY2xlLnN0YXJ0
REM c3dpdGgoJ2dhbWUvJyk6CiAgICAgICAgICAgICAgICBvcmFjbGVfZmlsZSA9IG9yYWNsZV9w
REM b3JfYXJxdWl2by5nZXQocmVsX29yYWNsZVs1Ol0sIHt9KQogICAgICAgICAgICBpZiBub3Qg
REM b3JhY2xlX2ZpbGU6CiAgICAgICAgICAgICAgICBiYXNlX25vbWUgPSBvcy5wYXRoLmJhc2Vu
REM YW1lKGNhbWluaG9fbm9ybSkKICAgICAgICAgICAgICAgIG9yYWNsZV9maWxlID0gb3JhY2xl
REM X3Bvcl9hcnF1aXZvLmdldChiYXNlX25vbWUsIHt9KQoKICAgICAgICAjIFBhbGF2cmFzIGRv
REM IGJhbmNvIGRvIG1pbmlqb2dvIGRlIHBvZW1hcy4gRW1ib3JhIGEgZGVjbGFyYWNhbyBlc3Rl
REM amEKICAgICAgICAjIGRlbnRybyBkZSBQeXRob24sIG8gdmFsb3IgZGUgYWRkX3dvcmQoKSBh
REM Y2FiYSBzZW5kbyB1c2FkbyBkaXJldGFtZW50ZQogICAgICAgICMgY29tbyB3b3JkU3RyaW5n
REM IGUgZXhpYmlkbyBlbSB0ZXh0YnV0dG9uLiBDYWRhIHBhbGF2cmEgZSB1bWEgZW50cmFkYQog
REM ICAgICAgICMgaW5kZXBlbmRlbnRlIG5vIG1hcGEsIHNlbSBkZWR1cGxpY2FjYW8gcG9yIHRl
REM eHRvLgogICAgICAgIGNhbWluaG9fbm9ybSA9IGNhbWluaG8ucmVwbGFjZSgnXFwnLCAnLycp
REM Lmxvd2VyKCkKICAgICAgICBpZiBjYW1pbmhvX25vcm0uZW5kc3dpdGgoJy9wb2VtX2dhbWUv
REM cHkvcG9lbXdvcmRzLnJweScpOgogICAgICAgICAgICBtX3dvcmQgPSByZS5zZWFyY2gocidc
REM YnBvZW1fd29yZF9kYlxzKlwuXHMqYWRkX3dvcmRccypcKFxzKignICsgUVNUUl9MT0NBTCAr
REM IHInKScsIGxpbmhhX2xpbXBhLCByZS5JKQogICAgICAgICAgICBpZiBtX3dvcmQ6CiAgICAg
REM ICAgICAgICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtX3dvcmQuc3RhcnQoMSksIG1f
REM d29yZC5lbmQoMSksIG1fd29yZC5ncm91cCgxKSwKICAgICAgICAgICAgICAgICAgICAgICAg
REM ICAncG9lbWFfcGFsYXZyYScsIDEwMCwgJ3BhbGF2cmEgZXhpYmlkYSBjb21vIGJvdMOjbyBk
REM byBtaW5pam9nbyBkZSBwb2VtYXMnKQoKICAgICAgICAjIFRlbXBsYXRlIG1vZGVybm8gNS54
REM OiBwb2Vtd29yZHNfcmVuLnB5IHBvZGUgdXNhciBlc3RydXR1cmFzIFB5dGhvbgogICAgICAg
REM ICMgZGlmZXJlbnRlczsgYXByb3ZlaXRhbW9zIGNoYW1hZGFzIGFkZF93b3JkL1BvZW1Xb3Jk
REM IGUgbWFudGVtb3MgbwogICAgICAgICMgcmVzdGFudGUgZG8gY8OzZGlnbyBmb3JhIGRhIHRy
REM YWR1w6fDo28uCiAgICAgICAgaWYgJ3BvZW13b3JkcycgaW4gb3MucGF0aC5iYXNlbmFtZShj
REM YW1pbmhvX25vcm0pLmxvd2VyKCk6CiAgICAgICAgICAgIGZvciBtX3dvcmRfbW9kIGluIHJl
REM LmZpbmRpdGVyKHInXGIoPzphZGRfd29yZHxQb2VtV29yZClccypcKFxzKignICsgUVNUUl9M
REM T0NBTCArIHInKScsIGxpbmhhX2xpbXBhLCByZS5JKToKICAgICAgICAgICAgICAgIHF3b3Jk
REM ID0gbV93b3JkX21vZC5ncm91cCgxKQogICAgICAgICAgICAgICAgaWYgdGVtX2NvbnRldWRv
REM X3RyYWR1eml2ZWwocXdvcmQpIGFuZCBub3QgcGFyZWNlX3RleHRvX3RlY25pY28ocXdvcmQp
REM OgogICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG1fd29yZF9t
REM b2Quc3RhcnQoMSksIG1fd29yZF9tb2QuZW5kKDEpLCBxd29yZCwKICAgICAgICAgICAgICAg
REM ICAgICAgICAgICAgICAgJ3BvZW1hX3BhbGF2cmEnLCAxMDAsICdwYWxhdnJhIGRvIGJhbmNv
REM IG1vZGVybm8gcG9lbXdvcmRzX3JlbicpCgogICAgICAgICMgUmVjb25jaWxpYcOnw6NvIGRv
REM IG9yw6FjdWxvOiBzw7MgYWdvcmEsIGRlcG9pcyBkYXMgZXNwZWNpYWxpemHDp8O1ZXMgZGUK
REM ICAgICAgICAjIHBvZW1hLCBhZGljaW9uYW1vcyBldmlkw6puY2lhcyBzZW3Dom50aWNhcyBh
REM aW5kYSBuw6NvIGNvYmVydGFzIHBlbG8gc2Nhbm5lci4KICAgICAgICBfYWQsIF9kdXAsIF9h
REM bWIgPSBfaW5qZXRhcl9lbnRyYWRhc19vcmFjdWxvX25hX2xpbmhhKAogICAgICAgICAgICBu
REM dW1lcm9fbGluaGEsIGxpbmhhX3NlbV9maW0sIG9zLnBhdGguYmFzZW5hbWUoY2FtaW5ob19u
REM b3JtKSwgb3JhY2xlX2ZpbGUsCiAgICAgICAgICAgIHJlZ2lzdHJvcywgcHJlZml4b193cywg
REM b2N1cGFkb3MpCiAgICAgICAgT1JBQ1VMT19SRU5QWVsibmF0aXZhc19tYXBlYWRhcyJdICs9
REM IF9hZAogICAgICAgIE9SQUNVTE9fUkVOUFlbIm5hdGl2YXNfZHVwbGljYWRhcyJdICs9IF9k
REM dXAKICAgICAgICBPUkFDVUxPX1JFTlBZWyJuYXRpdmFzX2FtYmlndWFzIl0gKz0gX2FtYgoK
REM ICAgICAgICAjIE5vIG1vZG8gZGUgcG9lbWEgY29ycm9tcGlkbywgIk1vbmlrYSIgdmlyYSBh
REM IGJhc2UgZG9zIGNhcmFjdGVyZXMKICAgICAgICAjIGRvcyBib3RvZXMuIEhhIGR1YXMgb2Nv
REM cnJlbmNpYXMgaW5kZXBlbmRlbnRlcyBubyBhcnF1aXZvLgogICAgICAgIGlmIGNhbWluaG9f
REM bm9ybS5lbmRzd2l0aCgnL3BvZW1fZ2FtZS9zY3JpcHQtcG9lbWdhbWUucnB5Jyk6CiAgICAg
REM ICAgICAgIG1fZ2xpdGNoX3dvcmQgPSByZS5zZWFyY2gocidcYmxpc3RccypcKFxzKignICsg
REM UVNUUl9MT0NBTCArIHInKVxzKlwpJywgbGluaGFfbGltcGEpCiAgICAgICAgICAgIGlmIG1f
REM Z2xpdGNoX3dvcmQgYW5kIHN0cmlwX3F1b3RlcyhtX2dsaXRjaF93b3JkLmdyb3VwKDEpKSA9
REM PSAnTW9uaWthJzoKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG1f
REM Z2xpdGNoX3dvcmQuc3RhcnQoMSksIG1fZ2xpdGNoX3dvcmQuZW5kKDEpLCBtX2dsaXRjaF93
REM b3JkLmdyb3VwKDEpLAogICAgICAgICAgICAgICAgICAgICAgICAgICdwb2VtYV9wYWxhdnJh
REM JywgMTAwLCAncGFsYXZyYS1iYXNlIGRvIG1vZG8gZGUgcG9lbWEgY29ycm9tcGlkbycpCgog
REM ICAgICAgIGZvciBlbnRyYWRhX3BvZW1hIGluIHBvZW1hc19wb3JfbGluaGEuZ2V0KG51bWVy
REM b19saW5oYSwgW10pOgogICAgICAgICAgICBiYXNlX2NvbHVuYSA9IGxlbihwcmVmaXhvX3dz
REM KQogICAgICAgICAgICBpbmljaW9fcG9lbWEgPSBlbnRyYWRhX3BvZW1hWydjb2x1bmFfaW5p
REM Y2lvJ10gLSBiYXNlX2NvbHVuYQogICAgICAgICAgICBmaW1fcG9lbWEgPSBlbnRyYWRhX3Bv
REM ZW1hWydjb2x1bmFfZmltJ10gLSBiYXNlX2NvbHVuYQogICAgICAgICAgICBpZiBpbmljaW9f
REM cG9lbWEgPCAwIG9yIGZpbV9wb2VtYSA8PSBpbmljaW9fcG9lbWE6CiAgICAgICAgICAgICAg
REM ICBjb250aW51ZQogICAgICAgICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBpbmljaW9f
REM cG9lbWEsIGZpbV9wb2VtYSwKICAgICAgICAgICAgICAgICAgICAgIGVudHJhZGFfcG9lbWFb
REM J3RyZWNobyddLCBlbnRyYWRhX3BvZW1hWyd0aXBvJ10sIGVudHJhZGFfcG9lbWFbJ2NvbmZp
REM YW5jYSddLAogICAgICAgICAgICAgICAgICAgICAgZW50cmFkYV9wb2VtYVsnY29udGV4dG8n
REM XSwgb3JpZ2luYWxfbWFwYT1lbnRyYWRhX3BvZW1hWydvcmlnaW5hbCddKQoKICAgICAgICBm
REM b3IgZW50cmFkYV9nZXR0ZXh0IGluIGdldHRleHRfcG9yX2xpbmhhLmdldChudW1lcm9fbGlu
REM aGEsIFtdKToKICAgICAgICAgICAgYmFzZV9jb2x1bmEgPSBsZW4ocHJlZml4b193cykKICAg
REM ICAgICAgICAgaW5pY2lvX2cgPSBlbnRyYWRhX2dldHRleHRbJ2NvbHVuYV9pbmljaW8nXSAt
REM IGJhc2VfY29sdW5hCiAgICAgICAgICAgIGZpbV9nID0gZW50cmFkYV9nZXR0ZXh0Wydjb2x1
REM bmFfZmltJ10gLSBiYXNlX2NvbHVuYQogICAgICAgICAgICBpZiBpbmljaW9fZyA8IDAgb3Ig
REM ZmltX2cgPD0gaW5pY2lvX2c6CiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAg
REM ICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBpbmljaW9fZywgZmltX2csCiAgICAgICAgICAg
REM ICAgICAgICAgICBlbnRyYWRhX2dldHRleHRbJ3RyZWNobyddLCBlbnRyYWRhX2dldHRleHRb
REM J3RpcG8nXSwgZW50cmFkYV9nZXR0ZXh0Wydjb25maWFuY2EnXSwKICAgICAgICAgICAgICAg
REM ICAgICAgIGVudHJhZGFfZ2V0dGV4dFsnY29udGV4dG8nXSwgb3JpZ2luYWxfbWFwYT1lbnRy
REM YWRhX2dldHRleHRbJ29yaWdpbmFsJ10pCgogICAgICAgIGZvciBlbnRyYWRhX21vbm9sb2dv
REM IGluIG1vbm9sb2dvc19wb3JfbGluaGEuZ2V0KG51bWVyb19saW5oYSwgW10pOgogICAgICAg
REM ICAgICBiYXNlX2NvbHVuYSA9IGxlbihwcmVmaXhvX3dzKQogICAgICAgICAgICBpbmljaW9f
REM bSA9IGVudHJhZGFfbW9ub2xvZ29bJ2NvbHVuYV9pbmljaW8nXSAtIGJhc2VfY29sdW5hCiAg
REM ICAgICAgICAgIGZpbV9tID0gZW50cmFkYV9tb25vbG9nb1snY29sdW5hX2ZpbSddIC0gYmFz
REM ZV9jb2x1bmEKICAgICAgICAgICAgaWYgaW5pY2lvX20gPCAwIG9yIGZpbV9tIDw9IGluaWNp
REM b19tOgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgcmVnaXN0cmFyKG51
REM bWVyb19saW5oYSwgaW5pY2lvX20sIGZpbV9tLAogICAgICAgICAgICAgICAgICAgICAgZW50
REM cmFkYV9tb25vbG9nb1sndHJlY2hvJ10sIGVudHJhZGFfbW9ub2xvZ29bJ3RpcG8nXSwgZW50
REM cmFkYV9tb25vbG9nb1snY29uZmlhbmNhJ10sCiAgICAgICAgICAgICAgICAgICAgICBlbnRy
REM YWRhX21vbm9sb2dvWydjb250ZXh0byddLCBvcmlnaW5hbF9tYXBhPWVudHJhZGFfbW9ub2xv
REM Z29bJ29yaWdpbmFsJ10pCgogICAgICAgIGZvciBlbnRyYWRhX211bHRpbGluaGEgaW4gbXVs
REM dGlsaW5oYXNfcG9yX2xpbmhhLmdldChudW1lcm9fbGluaGEsIFtdKToKICAgICAgICAgICAg
REM YmFzZV9jb2x1bmEgPSBsZW4ocHJlZml4b193cykKICAgICAgICAgICAgaW5pY2lvX21sID0g
REM ZW50cmFkYV9tdWx0aWxpbmhhWydjb2x1bmFfaW5pY2lvJ10gLSBiYXNlX2NvbHVuYQogICAg
REM ICAgICAgICBmaW1fbWwgPSBlbnRyYWRhX211bHRpbGluaGFbJ2NvbHVuYV9maW0nXSAtIGJh
REM c2VfY29sdW5hCiAgICAgICAgICAgIGlmIGluaWNpb19tbCA8IDAgb3IgZmltX21sIDw9IGlu
REM aWNpb19tbDoKICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgIHJlZ2lzdHJh
REM cihudW1lcm9fbGluaGEsIGluaWNpb19tbCwgZmltX21sLAogICAgICAgICAgICAgICAgICAg
REM ICAgZW50cmFkYV9tdWx0aWxpbmhhWyd0cmVjaG8nXSwgZW50cmFkYV9tdWx0aWxpbmhhWyd0
REM aXBvJ10sIGVudHJhZGFfbXVsdGlsaW5oYVsnY29uZmlhbmNhJ10sCiAgICAgICAgICAgICAg
REM ICAgICAgICBlbnRyYWRhX211bHRpbGluaGFbJ2NvbnRleHRvJ10sIG9yaWdpbmFsX21hcGE9
REM ZW50cmFkYV9tdWx0aWxpbmhhWydvcmlnaW5hbCddKQoKICAgICAgICBlbV9ibG9jb192aXN1
REM YWxfdGVjbmljbyA9IG51bWVyb19saW5oYSBpbiBsaW5oYXNfYmxvY29zX3RlY25pY29zCiAg
REM ICAgICAgZW1fcHl0aG9uID0gbnVtZXJvX2xpbmhhIGluIGxpbmhhc19weXRob24KICAgICAg
REM ICBhcnF1aXZvX2Jhc2UgPSBvcy5wYXRoLmJhc2VuYW1lKGNhbWluaG8pLmxvd2VyKCkKICAg
REM ICAgICBhbGlhc192aXN1YWxfZW1fZGVmaW5pdGlvbnMgPSAoCiAgICAgICAgICAgIGFycXVp
REM dm9fYmFzZSA9PSAnZGVmaW5pdGlvbnMucnB5JyBhbmQKICAgICAgICAgICAgcmUubWF0Y2go
REM cideWycgKyBjaHIoMzQpICsgY2hyKDM5KSArIHInXVtBLVphLXpfXVtBLVphLXowLTlfLi1d
REM Kig/OlxzKyg/OlswLTldK3xbMC05XStbQS1aYS16XSt8Z2hvc3RbMC05XSspKStbJyArIGNo
REM cigzNCkgKyBjaHIoMzkpICsgciddJCcsIGxpbmhhX2xpbXBhLCByZS5JKQogICAgICAgICkK
REM ICAgICAgICBpZiBhbGlhc192aXN1YWxfZW1fZGVmaW5pdGlvbnM6CiAgICAgICAgICAgIGNv
REM bnRpbnVlCgogICAgICAgICMgUmVjdXBlcmHDp8OjbyBzZW3Dom50aWNhIGRlIGxpc3Rhcy90
REM dXBsYXMgZGUgY3LDqWRpdG9zLiBOw6NvIGFicmUgbyBmaWx0cm8KICAgICAgICAjIHBhcmEg
REM dG9kYXMgYXMgc3RyaW5ncyBkbyBhcnF1aXZvOiBleGlnZSBjb250ZXh0byBkZSBjcsOpZGl0
REM b3MgKyBlc3RydXR1cmEuCiAgICAgICAgIyBPIG5vbWUgZGEgdmFyacOhdmVsIMOpIHRva2Vu
REM aXphZG8gcGFyYSBldml0YXIgZmFsc29zIHBvc2l0aXZvcyBjb21vCiAgICAgICAgIyBgc3Rl
REM YW1gIC0+IGB0ZWFtYDsgbWV0YWRhZG9zIGR1bmRlciAoZXguOiBfX2F1dGhvcl9fKSBuw6Nv
REM IHPDo28gdGV4dG8gZGUgVUkuCiAgICAgICAgbV9jcmVkaXRfaGVhZCA9IHJlLm1hdGNoKHIn
REM Xig/Oig/OmRlZmluZXxkZWZhdWx0KVxzK3xcJFxzKik/W1wnXCJdPyhbQS1aYS16X11bXHcu
REM XSopJywgbGluaGFfbGltcGEpCiAgICAgICAgY3JlZGl0X2hlYWQgPSBtX2NyZWRpdF9oZWFk
REM Lmdyb3VwKDEpIGlmIG1fY3JlZGl0X2hlYWQgZWxzZSAnJwogICAgICAgIGNyZWRpdF90b2tl
REM bnMgPSBbeCBmb3IgeCBpbiByZS5zcGxpdChyJ1tfXFddKycsIGNyZWRpdF9oZWFkLmxvd2Vy
REM KCkpIGlmIHhdCiAgICAgICAgdG9rZW5zX2NyZWRpdG8gPSBmcm96ZW5zZXQoKAogICAgICAg
REM ICAgICAnY3JlZGl0JywgJ2NyZWRpdHMnLCAnYXV0aG9yJywgJ2F1dGhvcnMnLCAnY29udHJp
REM YnV0b3InLCAnY29udHJpYnV0b3JzJywKICAgICAgICAgICAgJ3N0YWZmJywgJ3RlYW0nLCAn
REM c3BlY2lhbCcsICd0aGFua3MnCiAgICAgICAgKSkKICAgICAgICB0ZW1fY29udGV4dG9fY3Jl
REM ZGl0byA9IGJvb2woc2V0KGNyZWRpdF90b2tlbnMpICYgc2V0KCgnY3JlZGl0JywgJ2NyZWRp
REM dHMnLCAnYXV0aG9yJywgJ2F1dGhvcnMnLCAnY29udHJpYnV0b3InLCAnY29udHJpYnV0b3Jz
REM JywgJ3N0YWZmJywgJ3RlYW0nKSkpCiAgICAgICAgaXNfZHVuZGVyX21ldGEgPSBib29sKGNy
REM ZWRpdF9oZWFkLnN0YXJ0c3dpdGgoJ19fJykgYW5kIGNyZWRpdF9oZWFkLmVuZHN3aXRoKCdf
REM XycpKQogICAgICAgIGxpbmhhX2RhZG9zX2NyZWRpdG9zID0gKAogICAgICAgICAgICBib29s
REM KGNyZWRpdF9oZWFkKSBhbmQgbm90IGlzX2R1bmRlcl9tZXRhIGFuZCB0ZW1fY29udGV4dG9f
REM Y3JlZGl0bwogICAgICAgICAgICBhbmQgbGVuKGxpc3QoU1RSSU5HX0xJVEVSQUxfUkUuZmlu
REM ZGl0ZXIobGluaGFfbGltcGEpKSkgPj0gMgogICAgICAgICAgICBhbmQgYm9vbChyZS5zZWFy
REM Y2gocidbPVxbKHs6XScsIGxpbmhhX2xpbXBhKSkKICAgICAgICApCiAgICAgICAgaWYgbGlu
REM aGFfZGFkb3NfY3JlZGl0b3MgYW5kIG5vdCBlbV9ibG9jb192aXN1YWxfdGVjbmljbzoKICAg
REM ICAgICAgICAgZm9yIG0gaW4gU1RSSU5HX0xJVEVSQUxfUkUuZmluZGl0ZXIobGluaGFfbGlt
REM cGEpOgogICAgICAgICAgICAgICAgcSA9IG0uZ3JvdXAoMCkKICAgICAgICAgICAgICAgIGlm
REM IHBhcmVjZV9zdHJpbmdfc2VtYW50aWNhKHEsIGNhbWluaG8sIHBlcm1pdGlyX2lkZW50aWZp
REM Y2Fkb3I9VHJ1ZSk6CiAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5o
REM YSwgbS5zdGFydCgpLCBtLmVuZCgpLCBxLCAndGV4dG9fY3JlZGl0b3NfZGFkb3MnLCA5MCwg
REM J2RhZG8gdGV4dHVhbCBkZSBjcsOpZGl0b3MnKQoKICAgICAgICAjIEFsZ3VtYXMgbWVuc2Fn
REM ZW5zIGRvIHRlbXBsYXRlX2NoZWNrcy5weSBzw6NvIHJldG9ybmFkYXMgcG9yIG3DqXRvZG9z
REM CiAgICAgICAgIyBkZW50cm8gZGUgYmxvY29zIFB5dGhvbiBtb2Rlcm5vcy4gRWxhcyBjb250
REM aW51YW0gc2VuZG8gdGV4dG8gdmlzw612ZWwKICAgICAgICAjIGFvIHVzdcOhcmlvLCBwb3J0
REM YW50byBwcmVjaXNhbSBzZXIgcmVjdXBlcmFkYXMgYW50ZXMgZG8gZGVzY2FydGUgZ2VyYWwK
REM ICAgICAgICAjIGRhcyBsaW5oYXMgUHl0aG9uIG1vZGVybmFzLgogICAgICAgIGFycXVpdm9f
REM ZXNwZWNpYWxfcHJlID0gYXJxdWl2b19iYXNlIGluICgKICAgICAgICAgICAgJ2V4Y2VwdGlv
REM bnMucnB5JywgJ3JlbnB5X3BhdGNoZXMucnB5JywgJ2RlcHJlY2lhdGVkLnJweScsICd0ZW1w
REM bGF0ZV9jaGVja3MucnB5JywgJ3RlbXBsYXRlX2NoZWNrc19yZW4ucHknCiAgICAgICAgKQog
REM ICAgICAgIGlmIGFycXVpdm9fZXNwZWNpYWxfcHJlOgogICAgICAgICAgICBtX3JldHVybl9w
REM cmUgPSBQWVRIT05fUkVUVVJOX1RFWFRfUkUubWF0Y2gobGluaGFfbGltcGEpCiAgICAgICAg
REM ICAgIGlmIG1fcmV0dXJuX3ByZToKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9f
REM bGluaGEsIG1fcmV0dXJuX3ByZS5zdGFydCgxKSwgbV9yZXR1cm5fcHJlLmVuZCgxKSwgbV9y
REM ZXR1cm5fcHJlLmdyb3VwKDEpLCAndWknLCAxMDAsICdtZW5zYWdlbSByZXRvcm5hZGEgcG9y
REM IGV4Y2XDp8Ojby90ZW1wbGF0ZScpCiAgICAgICAgICAgIGVsaWYgbGluaGFfbGltcGEubG93
REM ZXIoKS5zdGFydHN3aXRoKCdyZXR1cm4gJykgYW5kICgnIicgaW4gbGluaGFfbGltcGEgb3Ig
REM IiciIGluIGxpbmhhX2xpbXBhKToKICAgICAgICAgICAgICAgIGZvciBtIGluIHJlLmZpbmRp
REM dGVyKFFTVFJfTE9DQUwsIGxpbmhhX2xpbXBhKToKICAgICAgICAgICAgICAgICAgICBxcmV0
REM ID0gbS5ncm91cCgwKQogICAgICAgICAgICAgICAgICAgIGlmIGxlbihzdHJpcF9xdW90ZXMo
REM cXJldCkuc3RyaXAoKSkgPj0gMzoKICAgICAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFy
REM KG51bWVyb19saW5oYSwgbS5zdGFydCgwKSwgbS5lbmQoMCksIHFyZXQsICd1aScsIDkyLCAn
REM ZnJhZ21lbnRvIHRleHR1YWwgZGUgZXhjZcOnw6NvL3RlbXBsYXRlJykKICAgICAgICAjIFJl
REM Y3VwZXJhIGxpdGVyYWlzIGRlIHRleHRvIGVtIGNvbnRpbnVhw6fDtWVzIGRlIGNvbmNhdGVu
REM YcOnw6NvIGRvcwogICAgICAgICMgdmFsaWRhZG9yZXMgZG8gdGVtcGxhdGUuIEV4LjogKyAi
REM LnJwYScgd2FzIG5vdCBmb3VuZC4uLiIuCiAgICAgICAgIyBPIGZpbHRybyBzZW3Dom50aWNv
REM IGNvbnRpbnVhIGJsb3F1ZWFuZG8gY2FtaW5ob3MsIGNvbWFuZG9zLCBoYXNoZXMgZQogICAg
REM ICAgICMgb3V0cm9zIGRhZG9zIHTDqWNuaWNvczsgYSByZWdyYSBzw7Mgw6kgYXBsaWNhZGEg
REM YW9zIGFycXVpdm9zIGVzcGVjaWFpcy4KICAgICAgICBpZiBhcnF1aXZvX2VzcGVjaWFsX3By
REM ZSBhbmQgbGluaGFfbGltcGEuc3RhcnRzd2l0aCgnKycpOgogICAgICAgICAgICBmb3IgbV9j
REM b25jYXQgaW4gcmUuZmluZGl0ZXIoUVNUUl9MT0NBTCwgbGluaGFfbGltcGEpOgogICAgICAg
REM ICAgICAgICAgcV9jb25jYXQgPSBtX2NvbmNhdC5ncm91cCgwKQogICAgICAgICAgICAgICAg
REM aWYgKHBhcmVjZV9zdHJpbmdfc2VtYW50aWNhKHFfY29uY2F0LCBjYW1pbmhvKSBhbmQKICAg
REM ICAgICAgICAgICAgICAgICAgICAgdGVtX2NvbnRldWRvX3RyYWR1eml2ZWwocV9jb25jYXQp
REM KToKICAgICAgICAgICAgICAgICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtX2NvbmNh
REM dC5zdGFydCgwKSwgbV9jb25jYXQuZW5kKDApLCBxX2NvbmNhdCwKICAgICAgICAgICAgICAg
REM ICAgICAgICAgICAgICAgJ3VpJywgOTUsICdmcmFnbWVudG8gdGV4dHVhbCBlbSBjb25jYXRl
REM bmHDp8OjbyBkZSBtZW5zYWdlbScpCgogICAgICAgIGlmIG5vdCBsaW5oYXNfYXRpdmFzW2lk
REM eF0gYW5kIGVoX3JlbnB5X21vZGVybm8oY2FtaW5obyk6CiAgICAgICAgICAgIGZvciByeCwg
REM dGlwbywgY29udGV4dG8gaW4gKAogICAgICAgICAgICAgICAgICAgIChVSV9SRVMsICd1aScs
REM ICd0ZXh0byB0cmFkdXrDrXZlbCBlbSBQeXRob24nKSwKICAgICAgICAgICAgICAgICAgICAo
REM VklTSUJMRV9DQUxMX1JFLCAndWknLCAndGV4dG8gdmlzw612ZWwgdmlhIEFQSSBSZW5cJ1B5
REM JyksCiAgICAgICAgICAgICAgICAgICAgKFRFWFRfQ0FMTF9SRSwgJ3VpJywgJ1RleHQoKSAv
REM IHRleHRvIGRlIGRpc3BsYXknKSk6CiAgICAgICAgICAgICAgICBmb3IgbSBpbiByeC5maW5k
REM aXRlcihsaW5oYV9saW1wYSk6CiAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVy
REM b19saW5oYSwgbS5zdGFydCgxKSwgbS5lbmQoMSksIG0uZ3JvdXAoMSksIHRpcG8sIDEwMCwg
REM Y29udGV4dG8pCiAgICAgICAgICAgIGZvciBpbmljaW9fZHluLCBmaW1fZHluLCBxX2R5biBp
REM biBleHRyYWlyX2ZyYWdtZW50b3NfdGV4dF9jYWxsX2RpbmFtaWNvKGxpbmhhX2xpbXBhLCBj
REM YW1pbmhvKToKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIGluaWNp
REM b19keW4sIGZpbV9keW4sIHFfZHluLCAndWknLCA5OSwgJ2ZyYWdtZW50byB0ZXh0dWFsIGRp
REM bsOibWljbyBlbSBUZXh0KCknKQogICAgICAgICAgICBmb3IgaXRlbSBpbiByZWdpc3Ryb3M6
REM CiAgICAgICAgICAgICAgICBpbmljaW8sIGZpbSwgdGlwbywgY29uZiwgY3R4LCB0ZXh0bywg
REM b3JpZ2luYWxfbWFwYSA9IGl0ZW0KICAgICAgICAgICAgICAgIGluaWNpb19yZWFsID0gbGVu
REM KHByZWZpeG9fd3MpICsgaW5pY2lvCiAgICAgICAgICAgICAgICBmaW1fcmVhbCA9IGxlbihw
REM cmVmaXhvX3dzKSArIGZpbQogICAgICAgICAgICAgICAgZXNwZXJhZG8gPSBvcmlnaW5hbF9t
REM YXBhIGlmIG9yaWdpbmFsX21hcGEgaXMgbm90IE5vbmUgZWxzZSB0ZXh0bwogICAgICAgICAg
REM ICAgICAgaWYgbGluaGFfc2VtX2ZpbVtpbmljaW9fcmVhbDpmaW1fcmVhbF0gPT0gZXNwZXJh
REM ZG86CiAgICAgICAgICAgICAgICAgICAgdGV4dG9zLmFwcGVuZCgoY3R4LCB0ZXh0bykpOyBt
REM YXBhLmFwcGVuZCh7ImxpbmhhIjogbnVtZXJvX2xpbmhhLCAiY29sdW5hX2luaWNpbyI6IGlu
REM aWNpb19yZWFsLCAiY29sdW5hX2ZpbSI6IGZpbV9yZWFsLCAib3JpZ2luYWwiOiBlc3BlcmFk
REM bywgInRpcG8iOiB0aXBvLCAiY29uZmlhbmNhIjogY29uZiwgImNvbnRleHRvIjogY3R4fSkK
REM ICAgICAgICAgICAgY29udGludWUKCiAgICAgICAgIyBNZXNtbyBkZW50cm8gZGUgYmxvY29z
REM IHZpc3VhaXMsIHByZXNlcnZlIHRleHRvIHF1ZSBzYWJlbW9zIHF1ZSDDqSBkZXNlbmhhZG8u
REM CiAgICAgICAgaWYgZW1fYmxvY29fdmlzdWFsX3RlY25pY286CiAgICAgICAgICAgIGZvciBy
REM eCwgdGlwbywgY29udGV4dG8gaW4gKAogICAgICAgICAgICAgICAgICAgIChVSV9SRVMsICd1
REM aScsICd3cmFwcGVyIGVtIGJsb2NvIHZpc3VhbCcpLAogICAgICAgICAgICAgICAgICAgIChU
REM RVhUX0NBTExfUkUsICd1aScsICdUZXh0KCkgZGVudHJvIGRlIGJsb2NvIHZpc3VhbCcpLAog
REM ICAgICAgICAgICAgICAgICAgIChWSVNJQkxFX0NBTExfUkUsICd1aScsICdBUEkgdmlzw612
REM ZWwgZGVudHJvIGRlIGJsb2NvIHZpc3VhbCcpLAogICAgICAgICAgICAgICAgICAgIChTSE9X
REM X0RJU1BMQVlfVEVYVF9SRSwgJ3VpJywgJ3RleHRvIGV4aWJpZG8gdmlhIHNob3cvZGlzcGxh
REM eWFibGUnKSk6CiAgICAgICAgICAgICAgICBmb3IgbSBpbiByeC5maW5kaXRlcihsaW5oYV9s
REM aW1wYSk6CiAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbS5z
REM dGFydCgxKSwgbS5lbmQoMSksIG0uZ3JvdXAoMSksIHRpcG8sIDEwMCwgY29udGV4dG8pCiAg
REM ICAgICAgICAgICMgTsOjbyB1c2FyIGZhbGxiYWNrIGluZGlzY3JpbWluYWRvIG5lc3RlIGJs
REM b2NvLgogICAgICAgICAgICBwYXNzCiAgICAgICAgZWxzZToKICAgICAgICAgICAgIyBEZWZp
REM bmnDp8O1ZXMgZGUgcGVyc29uYWdlbSwgaW5jbHVzaXZlIG11bHRpbGluaGEuCiAgICAgICAg
REM ICAgIGZvciBlbnRyYWRhX2RlZiBpbiBkZWZpbmljb2VzX3Bvcl9saW5oYS5nZXQobnVtZXJv
REM X2xpbmhhLCBbXSk6CiAgICAgICAgICAgICAgICBpbmljaW9fcmVhbCA9IGVudHJhZGFfZGVm
REM WyJjb2x1bmFfaW5pY2lvIl0KICAgICAgICAgICAgICAgIGZpbV9yZWFsID0gZW50cmFkYV9k
REM ZWZbImNvbHVuYV9maW0iXQogICAgICAgICAgICAgICAgaWYgaW5pY2lvX3JlYWwgPj0gbGVu
REM KHByZWZpeG9fd3MpOgogICAgICAgICAgICAgICAgICAgIGluaWNpb19saW1wbyA9IGluaWNp
REM b19yZWFsIC0gbGVuKHByZWZpeG9fd3MpOyBmaW1fbGltcG8gPSBmaW1fcmVhbCAtIGxlbihw
REM cmVmaXhvX3dzKQogICAgICAgICAgICAgICAgICAgIHEgPSBsaW5oYV9saW1wYVtpbmljaW9f
REM bGltcG86ZmltX2xpbXBvXQogICAgICAgICAgICAgICAgICAgIGlmIHEgPT0gZW50cmFkYV9k
REM ZWZbIm9yaWdpbmFsIl06CiAgICAgICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1l
REM cm9fbGluaGEsIGluaWNpb19saW1wbywgZmltX2xpbXBvLCBxLCBlbnRyYWRhX2RlZlsidGlw
REM byJdLCBlbnRyYWRhX2RlZlsiY29uZmlhbmNhIl0sIGVudHJhZGFfZGVmWyJjb250ZXh0byJd
REM KQoKICAgICAgICAgICAgZm9yIG0gaW4gVUlfUkVTLmZpbmRpdGVyKGxpbmhhX2xpbXBhKToK
REM ICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG0uc3RhcnQoMSksIG0u
REM ZW5kKDEpLCBtLmdyb3VwKDEpLCAndWknLCAxMDAsICdzdHJpbmcgdHJhZHV6w612ZWwgLyB3
REM cmFwcGVyIFJlblwnUHknKQoKICAgICAgICAgICAgbV9kb2xsYXIgPSBET0xMQVJfQVNTSUdO
REM X1JFLm1hdGNoKGxpbmhhX2xpbXBhKQogICAgICAgICAgICBpZiBtX2RvbGxhciBhbmQgbV9k
REM b2xsYXIuZ3JvdXAoMSkgaW4gdmFyaWF2ZWlzX25vbWVfZGluYW1pY286CiAgICAgICAgICAg
REM ICAgICBxID0gbV9kb2xsYXIuZ3JvdXAoMikKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihu
REM dW1lcm9fbGluaGEsIG1fZG9sbGFyLnN0YXJ0KDIpLCBtX2RvbGxhci5lbmQoMiksIHEsICdu
REM b21lX3BlcnNvbmFnZW0nLCAxMDAsIHUnbm9tZSBkaW7Dom1pY286ICcgKyBtX2RvbGxhci5n
REM cm91cCgxKSkKCiAgICAgICAgICAgIG1fZGVmYXVsdCA9IFNUUklOR19ERUZBVUxUX1JFLm1h
REM dGNoKGxpbmhhX2xpbXBhKQogICAgICAgICAgICBpZiBtX2RlZmF1bHQgYW5kIG1fZGVmYXVs
REM dC5ncm91cCgxKSBpbiB2YXJpYXZlaXNfbm9tZV9kaW5hbWljbzoKICAgICAgICAgICAgICAg
REM IHEgPSBtX2RlZmF1bHQuZ3JvdXAoMikKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1l
REM cm9fbGluaGEsIG1fZGVmYXVsdC5zdGFydCgyKSwgbV9kZWZhdWx0LmVuZCgyKSwgcSwgJ25v
REM bWVfcGVyc29uYWdlbScsIDEwMCwgdSdub21lIGRpbsOibWljbzogJyArIG1fZGVmYXVsdC5n
REM cm91cCgxKSkKCiAgICAgICAgICAgIGlmIG1fZGVmYXVsdDoKICAgICAgICAgICAgICAgIHZh
REM cl9ub21lID0gbV9kZWZhdWx0Lmdyb3VwKDEpCiAgICAgICAgICAgICAgICBxID0gbV9kZWZh
REM dWx0Lmdyb3VwKDIpCiAgICAgICAgICAgICAgICBpZiBub3QgcGFyZWNlX3RleHRvX3RlY25p
REM Y28ocSwgdmFyX25vbWU9dmFyX25vbWUsIGluZGljZV9hcnF1aXZvcz1pbmRpY2VfYXJxdWl2
REM b3MpIGFuZCBub3QgdmFyaWF2ZWxfZWhfdGVjbmljYSh2YXJfbm9tZSwgcSwgdm9jYWJ1bGFy
REM aW8pOgogICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG1fZGVm
REM YXVsdC5zdGFydCgyKSwgbV9kZWZhdWx0LmVuZCgyKSwgcSwgJ3ZhcmlhdmVsX3RleHRvJywg
REM OTAsIHUnZGVmYXVsdC9kZWZpbmUgY29tIHRleHRvOiAnICsgdmFyX25vbWUpCgogICAgICAg
REM ICAgICAjIFJlY3VwZXJhIGF0cmlidWljb2VzIHRleHR1YWlzIHNlbSBleGlnaXIgZGVmaW5l
REM L2RlZmF1bHQuCiAgICAgICAgICAgIG1fZHluYW1pY190ZXh0ID0gRFlOQU1JQ19WSVNJQkxF
REM X1RFWFRfQVNTSUdOX1JFLm1hdGNoKGxpbmhhX2xpbXBhKQogICAgICAgICAgICBpZiBtX2R5
REM bmFtaWNfdGV4dDoKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG1f
REM ZHluYW1pY190ZXh0LnN0YXJ0KDIpLCBtX2R5bmFtaWNfdGV4dC5lbmQoMiksIG1fZHluYW1p
REM Y190ZXh0Lmdyb3VwKDIpLCAndWknLCAxMDAsICd0ZXh0byB2aXPDrXZlbCBhdHJpYnXDrWRv
REM IGEgbWVudXRleHQnKQoKICAgICAgICAgICAgbV90ZXh0X2Fzc2lnbiA9IFRFWFRVQUxfQVNT
REM SUdOX1JFLm1hdGNoKGxpbmhhX2xpbXBhKQogICAgICAgICAgICBpZiBtX3RleHRfYXNzaWdu
REM OgogICAgICAgICAgICAgICAgdmFyX25vbWUgPSBtX3RleHRfYXNzaWduLmdyb3VwKDEpCiAg
REM ICAgICAgICAgICAgICBxID0gbV90ZXh0X2Fzc2lnbi5ncm91cCgyKQogICAgICAgICAgICAg
REM ICAgaWYgbm90IHBhcmVjZV90ZXh0b190ZWNuaWNvKHEsIHZhcl9ub21lPXZhcl9ub21lLCBp
REM bmRpY2VfYXJxdWl2b3M9aW5kaWNlX2FycXVpdm9zKSBhbmQgbm90IHZhcmlhdmVsX2VoX3Rl
REM Y25pY2EodmFyX25vbWUsIHEsIHZvY2FidWxhcmlvKToKICAgICAgICAgICAgICAgICAgICBy
REM ZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtX3RleHRfYXNzaWduLnN0YXJ0KDIpLCBtX3RleHRf
REM YXNzaWduLmVuZCgyKSwgcSwgJ3ZhcmlhdmVsX3RleHRvJywgOTIsIHUndmFyacOhdmVsIHRl
REM eHR1YWw6ICcgKyB2YXJfbm9tZSkKCiAgICAgICAgICAgICMgQ2hhbWFkYXMgZGUgdGV4dG8v
REM VUkuCiAgICAgICAgICAgIGZvciBtIGluIFZJU0lCTEVfQ0FMTF9SRS5maW5kaXRlcihsaW5o
REM YV9saW1wYSk6CiAgICAgICAgICAgICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtLnN0
REM YXJ0KDEpLCBtLmVuZCgxKSwgbS5ncm91cCgxKSwgJ3VpJywgMTAwLCAndGV4dG8gdmlzw612
REM ZWwgdmlhIEFQSSBSZW5cJ1B5JykKICAgICAgICAgICAgZm9yIG0gaW4gVEVYVF9DQUxMX1JF
REM LmZpbmRpdGVyKGxpbmhhX2xpbXBhKToKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1l
REM cm9fbGluaGEsIG0uc3RhcnQoMSksIG0uZW5kKDEpLCBtLmdyb3VwKDEpLCAndWknLCA5NSwg
REM J1RleHQoKSAvIHRleHRvIGRlIGRpc3BsYXknKQogICAgICAgICAgICBmb3IgaW5pY2lvX2R5
REM biwgZmltX2R5biwgcV9keW4gaW4gZXh0cmFpcl9mcmFnbWVudG9zX3RleHRfY2FsbF9kaW5h
REM bWljbyhsaW5oYV9saW1wYSwgY2FtaW5obyk6CiAgICAgICAgICAgICAgICByZWdpc3RyYXIo
REM bnVtZXJvX2xpbmhhLCBpbmljaW9fZHluLCBmaW1fZHluLCBxX2R5biwgJ3VpJywgOTksICdm
REM cmFnbWVudG8gdGV4dHVhbCBkaW7Dom1pY28gZW0gVGV4dCgpJykKICAgICAgICAgICAgZm9y
REM IG0gaW4gU0hPV19ESVNQTEFZX1RFWFRfUkUuZmluZGl0ZXIobGluaGFfbGltcGEpOgogICAg
REM ICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbS5zdGFydCgxKSwgbS5lbmQo
REM MSksIG0uZ3JvdXAoMSksICd1aScsIDk4LCAndGV4dG8gZXhpYmlkbyB2aWEgc2hvdy9kaXNw
REM bGF5YWJsZScpCiAgICAgICAgICAgIGZvciBtIGluIFVQREFURUNPTlNPTEVfTUVTU0FHRV9S
REM RS5maW5kaXRlcihsaW5oYV9saW1wYSk6CiAgICAgICAgICAgICAgICByZWdpc3RyYXIobnVt
REM ZXJvX2xpbmhhLCBtLnN0YXJ0KDEpLCBtLmVuZCgxKSwgbS5ncm91cCgxKSwgJ3VpJywgOTYs
REM ICdtZW5zYWdlbSB2aXPDrXZlbCBkbyBjb25zb2xlJykKICAgICAgICAgICAgZm9yIG0gaW4g
REM VVBEQVRFQ09OU09MRV9CUk9BRF9SRS5maW5kaXRlcihsaW5oYV9saW1wYSk6CiAgICAgICAg
REM ICAgICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtLnN0YXJ0KDEpLCBtLmVuZCgxKSwg
REM bS5ncm91cCgxKSwgJ3VpJywgOTYsICdtZW5zYWdlbSB2aXPDrXZlbCBkbyBjb25zb2xlJykK
REM ICAgICAgICAgICAgZm9yIG0gaW4gRElBTE9HX0NBTExfUkUuZmluZGl0ZXIobGluaGFfbGlt
REM cGEpOgogICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbS5zdGFydCgx
REM KSwgbS5lbmQoMSksIG0uZ3JvdXAoMSksICd1aScsIDEwMCwgJ21lbnNhZ2VtIHZpc8OtdmVs
REM IGVtIGRpYWxvZy9zaG93X2RpYWxvZycpCiAgICAgICAgICAgIGZvciBtIGluIENBTExfU0NS
REM RUVOX0RJQUxPR19SRS5maW5kaXRlcihsaW5oYV9saW1wYSk6CiAgICAgICAgICAgICAgICBy
REM ZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtLnN0YXJ0KDEpLCBtLmVuZCgxKSwgbS5ncm91cCgx
REM KSwgJ3VpJywgMTAwLCAnbWVuc2FnZW0gdmlzw612ZWwgZW0gY2FsbC9zaG93IHNjcmVlbiBk
REM aWFsb2cnKQogICAgICAgICAgICBmb3IgbSBpbiBSRU5QWV9DQUxMX1NDUkVFTl9ESUFMT0df
REM UkUuZmluZGl0ZXIobGluaGFfbGltcGEpOgogICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51
REM bWVyb19saW5oYSwgbS5zdGFydCgxKSwgbS5lbmQoMSksIG0uZ3JvdXAoMSksICd1aScsIDEw
REM MCwgJ21lbnNhZ2VtIHZpc8OtdmVsIHZpYSByZW5weS5jYWxsX3NjcmVlbi9zaG93X3NjcmVl
REM biBkaWFsb2cnKQoKICAgICAgICAgICAgZm9yIG0gaW4gU0hPV19NRVNTQUdFX0tXQVJHX1JF
REM LmZpbmRpdGVyKGxpbmhhX2xpbXBhKToKICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1l
REM cm9fbGluaGEsIG0uc3RhcnQoMSksIG0uZW5kKDEpLCBtLmdyb3VwKDEpLCAndWknLCAxMDAs
REM ICdtZW5zYWdlbSB2aXPDrXZlbCBlbSBTaG93L3Nob3cgbWVzc2FnZT0nKQoKICAgICAgICAg
REM ICAgIyBSZXRvcm5vcyBQeXRob24gZGUgbWVuc2FnZW5zOiBwcmltZWlybyBhIGZvcm1hIGV4
REM YXRhLCBkZXBvaXMgY2FkYQogICAgICAgICAgICAjIGZyYWdtZW50byB0ZXh0dWFsIGRlIHVt
REM IHJldHVybiBjb25jYXRlbmFkbyAoZXhjZXB0aW9ucy5ycHkpLgogICAgICAgICAgICBhcnF1
REM aXZvX2VzcGVjaWFsID0gb3MucGF0aC5iYXNlbmFtZShjYW1pbmhvKS5sb3dlcigpIGluICgi
REM ZXhjZXB0aW9ucy5ycHkiLCAicmVucHlfcGF0Y2hlcy5ycHkiLCAiZGVwcmVjaWF0ZWQucnB5
REM IiwgInRlbXBsYXRlX2NoZWNrc19yZW4ucHkiLCAicG9lbXMucnB5IikKICAgICAgICAgICAg
REM aWYgYXJxdWl2b19lc3BlY2lhbDoKICAgICAgICAgICAgICAgICMgcG9lbXMucnB5IHBvc3N1
REM aSB1bWEgbWVuc2FnZW0gZGVwcmVjYWRhIG1vbnRhZGEgcG9yIGNvbmNhdGVuYcOnw6NvLgog
REM ICAgICAgICAgICAgICAgIyBFeHRyYcOtbW9zIGFwZW5hcyBvcyBmcmFnbWVudG9zIGRlIGxp
REM bmd1YWdlbSBuYXR1cmFsOyBvIGNvbWFuZG8KICAgICAgICAgICAgICAgICMgYW50aWdvICgk
REM IHBvZW1fZGIuc2hvd19wb2VtKC4uLikpIHBlcm1hbmVjZSBibG9xdWVhZG8uCiAgICAgICAg
REM ICAgICAgICBpZiBhcnF1aXZvX2Jhc2UgPT0gJ3BvZW1zLnJweScgYW5kICdkZXByZWNpYXRl
REM ZCcgaW4gbGluaGFfbGltcGEubG93ZXIoKSBhbmQgJ3BvZW1fZGIuc2hvd19wb2VtJyBpbiBs
REM aW5oYV9saW1wYToKICAgICAgICAgICAgICAgICAgICBmb3IgbV9kZXAgaW4gcmUuZmluZGl0
REM ZXIoUVNUUl9MT0NBTCwgbGluaGFfbGltcGEpOgogICAgICAgICAgICAgICAgICAgICAgICBx
REM ZGVwID0gbV9kZXAuZ3JvdXAoMCkKICAgICAgICAgICAgICAgICAgICAgICAgaW50ZXJpb3Jf
REM ZGVwID0gc3RyaXBfcXVvdGVzKHFkZXApCiAgICAgICAgICAgICAgICAgICAgICAgIGlmIG5v
REM dCBpbnRlcmlvcl9kZXAuc3RyaXAoKSBvciAncG9lbV9kYi5zaG93X3BvZW0nIGluIGludGVy
REM aW9yX2RlcDoKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAg
REM ICAgICAgICAgICAgICAgIGlmIGludGVyaW9yX2RlcC5sc3RyaXAoKS5zdGFydHN3aXRoKCck
REM Jyk6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICAg
REM ICAgICAgICAgICBpZiByZS5mdWxsbWF0Y2gocicoPzolW0EtWmEtejAtOV0rfFs9LDs6IF0p
REM KycsIGludGVyaW9yX2RlcCk6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250aW51
REM ZQogICAgICAgICAgICAgICAgICAgICAgICBpZiBwYXJlY2VfdGV4dG9fdGVjbmljbyhxZGVw
REM LCBpbmRpY2VfYXJxdWl2b3M9aW5kaWNlX2FycXVpdm9zKToKICAgICAgICAgICAgICAgICAg
REM ICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgICAgICAgICAgICAgIGlmIHRlbV9jb250
REM ZXVkb190cmFkdXppdmVsKHFkZXApOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVn
REM aXN0cmFyKG51bWVyb19saW5oYSwgbV9kZXAuc3RhcnQoMCksIG1fZGVwLmVuZCgwKSwgcWRl
REM cCwgJ3VpJywgOTUsICdmcmFnbWVudG8gdGV4dHVhbCBkYSBtZW5zYWdlbSBkZXByZWNhZGEn
REM KQoKICAgICAgICAgICAgICAgIG1fcmV0dXJuID0gUFlUSE9OX1JFVFVSTl9URVhUX1JFLm1h
REM dGNoKGxpbmhhX2xpbXBhKQogICAgICAgICAgICAgICAgaWYgbV9yZXR1cm46CiAgICAgICAg
REM ICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbV9yZXR1cm4uc3RhcnQoMSks
REM IG1fcmV0dXJuLmVuZCgxKSwgbV9yZXR1cm4uZ3JvdXAoMSksICd1aScsIDEwMCwgJ21lbnNh
REM Z2VtIHJldG9ybmFkYSBwb3IgZXhjZcOnw6NvJykKICAgICAgICAgICAgICAgIGVsaWYgbGlu
REM aGFfbGltcGEubG93ZXIoKS5zdGFydHN3aXRoKCdyZXR1cm4gJykgYW5kICgnIicgaW4gbGlu
REM aGFfbGltcGEgb3IgIiciIGluIGxpbmhhX2xpbXBhKToKICAgICAgICAgICAgICAgICAgICBm
REM b3IgbSBpbiByZS5maW5kaXRlcihRU1RSX0xPQ0FMLCBsaW5oYV9saW1wYSk6CiAgICAgICAg
REM ICAgICAgICAgICAgICAgIHFyZXQgPSBtLmdyb3VwKDApCiAgICAgICAgICAgICAgICAgICAg
REM ICAgIGlmIGxlbihzdHJpcF9xdW90ZXMocXJldCkuc3RyaXAoKSkgPj0gMzoKICAgICAgICAg
REM ICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1lcm9fbGluaGEsIG0uc3RhcnQoMCks
REM IG0uZW5kKDApLCBxcmV0LCAndWknLCA5MiwgJ2ZyYWdtZW50byB0ZXh0dWFsIGRlIGV4Y2XD
REM p8OjbycpCgogICAgICAgICAgICBwcmltZWlyb19tX2t3ID0gcmUubWF0Y2gocideKFtBLVph
REM LXpfXVtcdy5dKiknLCBsaW5oYV9saW1wYSkKICAgICAgICAgICAgcHJpbWVpcm9fbG93X2t3
REM ID0gcHJpbWVpcm9fbV9rdy5ncm91cCgxKS5sb3dlcigpIGlmIHByaW1laXJvX21fa3cgZWxz
REM ZSAnJwogICAgICAgICAgICBmb3IgbSBpbiBWSVNJQkxFX0tXQVJHX1JFLmZpbmRpdGVyKGxp
REM bmhhX2xpbXBhKToKICAgICAgICAgICAgICAgIGlmIHByaW1laXJvX2xvd19rdy5zdGFydHN3
REM aXRoKCdidWlsZC4nKToKICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAg
REM ICAgICAgaWYgKHByaW1laXJvX2xvd19rdyBub3QgaW4gQklCTElPVEVDQV9SRU5QWS5nZXQo
REM J3Rva2Vuc19uYW9fZGlhbG9nbycsIHNldCgpKQogICAgICAgICAgICAgICAgICAgICAgICBv
REM ciAnZGlhbG9nKCcgaW4gbGluaGFfbGltcGEubG93ZXIoKQogICAgICAgICAgICAgICAgICAg
REM ICAgICBvciAnc2NyZWVuIGRpYWxvZycgaW4gbGluaGFfbGltcGEubG93ZXIoKQogICAgICAg
REM ICAgICAgICAgICAgICAgICBvciBsaW5oYV9saW1wYS5sb3dlcigpLnN0YXJ0c3dpdGgoKCdj
REM YWxsIHNjcmVlbiBkaWFsb2cnLCAnc2hvdyBzY3JlZW4gZGlhbG9nJykpCiAgICAgICAgICAg
REM ICAgICAgICAgICAgIG9yIERJQUxPR19TSE9XX09CSkVDVF9SRS5zZWFyY2gobGluaGFfbGlt
REM cGEpKToKICAgICAgICAgICAgICAgICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtLnN0
REM YXJ0KDEpLCBtLmVuZCgxKSwgbS5ncm91cCgxKSwgJ3VpJywgOTIsICd0ZXh0byB2aXPDrXZl
REM bCBlbSBhcmd1bWVudG8gbm9tZWFkbycpCgogICAgICAgICAgICBmb3IgbV91aV9kaXNwbGF5
REM IGluIFVJX0RJU1BMQVlfQVJHX1JFLmZpbmRpdGVyKGxpbmhhX2xpbXBhKToKICAgICAgICAg
REM ICAgICAgIHFfdWkgPSBtX3VpX2Rpc3BsYXkuZ3JvdXAoMSkKICAgICAgICAgICAgICAgICMg
REM RXZpdGEgY2FwdHVyYXIgc3RyaW5ncyB0w6ljbmljYXMgYXDDs3Mgbm9tZXMgZGUgcHJvcHJp
REM ZWRhZGVzOyBhIHJlZ3JhCiAgICAgICAgICAgICAgICAjIHPDsyBhY2VpdGEgdW0gbGl0ZXJh
REM bCBpbWVkaWF0YW1lbnRlIGFzc29jaWFkbyBhbyBkaXNwbGF5YWJsZS4KICAgICAgICAgICAg
REM ICAgIGlmIHRlbV9jb250ZXVkb190cmFkdXppdmVsKHFfdWkpIGFuZCBub3QgcGFyZWNlX3Rl
REM eHRvX3RlY25pY28ocV91aSwgaW5kaWNlX2FycXVpdm9zPWluZGljZV9hcnF1aXZvcyk6CiAg
REM ICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICBxX3VpX3Zh
REM bG9yID0gZGVjb2RpZmljYXJfbGl0ZXJhbF90cmFkdWNhbyhxX3VpKQogICAgICAgICAgICAg
REM ICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICAgICAgICAgIHFfdWlf
REM dmFsb3IgPSBzdHJpcF9xdW90ZXMocV91aSkKICAgICAgICAgICAgICAgICAgICB0aXBvX3Vp
REM ID0gJ3RleHRvX2NyZWRpdG9zX2Jsb2NvJyBpZiBwYXJlY2VfYmxvY29fY3JlZGl0b3NfZ29v
REM Z2xlKHFfdWlfdmFsb3IsIGNhbWluaG8sICd1aScpIGVsc2UgJ3VpJwogICAgICAgICAgICAg
REM ICAgICAgIGNvbnRleHRvX3VpID0gJ2Jsb2NvIGRlIGNyw6lkaXRvcyBlbSBkaXNwbGF5YWJs
REM ZSBSZW5cJ1B5JyBpZiB0aXBvX3VpID09ICd0ZXh0b19jcmVkaXRvc19ibG9jbycgZWxzZSAn
REM dGV4dG8gdmlzw612ZWwgZW0gZGlzcGxheWFibGUgUmVuXCdQeScKICAgICAgICAgICAgICAg
REM ICAgICByZWdpc3RyYXIobnVtZXJvX2xpbmhhLCBtX3VpX2Rpc3BsYXkuc3RhcnQoMSksIG1f
REM dWlfZGlzcGxheS5lbmQoMSksIHFfdWksIHRpcG9fdWksIDExMCBpZiB0aXBvX3VpID09ICd0
REM ZXh0b19jcmVkaXRvc19ibG9jbycgZWxzZSA5OSwgY29udGV4dG9fdWkpCgogICAgICAgICAg
REM ICBpZiByZS5tYXRjaChyJ15zY3JlZW5cYi4qOicsIGxpbmhhX2xpbXBhKToKICAgICAgICAg
REM ICAgICAgIHNjcmVlbl9pbmRlbnQgPSBuaXZlbF9pbmRlbnQKICAgICAgICAgICAgZWxpZiBz
REM Y3JlZW5faW5kZW50IGlzIG5vdCBOb25lIGFuZCBuaXZlbF9pbmRlbnQgPD0gc2NyZWVuX2lu
REM ZGVudCBhbmQgbm90IHJlLm1hdGNoKHInXnNjcmVlblxiJywgbGluaGFfbGltcGEpOgogICAg
REM ICAgICAgICAgICAgc2NyZWVuX2luZGVudCA9IE5vbmUKICAgICAgICAgICAgaWYgc2NyZWVu
REM X2luZGVudCBpcyBub3QgTm9uZToKICAgICAgICAgICAgICAgIGZvciBtIGluIFNDUkVFTl9U
REM RVhUX1JFLmZpbmRpdGVyKGxpbmhhX2xpbXBhKToKICAgICAgICAgICAgICAgICAgICBxX3Nj
REM cmVlbl9jcmVkaXRvID0gbS5ncm91cCgxKQogICAgICAgICAgICAgICAgICAgIHRyeToKICAg
REM ICAgICAgICAgICAgICAgICAgICAgcV9zY3JlZW5fdmFsb3IgPSBkZWNvZGlmaWNhcl9saXRl
REM cmFsX3RyYWR1Y2FvKHFfc2NyZWVuX2NyZWRpdG8pCiAgICAgICAgICAgICAgICAgICAgZXhj
REM ZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgcV9zY3JlZW5fdmFsb3Ig
REM PSBzdHJpcF9xdW90ZXMocV9zY3JlZW5fY3JlZGl0bykKICAgICAgICAgICAgICAgICAgICB0
REM aXBvX3NjcmVlbiA9ICd0ZXh0b19jcmVkaXRvc19ibG9jbycgaWYgcGFyZWNlX2Jsb2NvX2Ny
REM ZWRpdG9zX2dvb2dsZShxX3NjcmVlbl92YWxvciwgY2FtaW5obywgJ3VpJykgZWxzZSAndWkn
REM CiAgICAgICAgICAgICAgICAgICAgY29udGV4dG9fc2NyZWVuID0gJ2Jsb2NvIGRlIGNyw6lk
REM aXRvcyBlbSBzY3JlZW4nIGlmIHRpcG9fc2NyZWVuID09ICd0ZXh0b19jcmVkaXRvc19ibG9j
REM bycgZWxzZSAndGV4dG8gZGUgc2NyZWVuJwogICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJh
REM cihudW1lcm9fbGluaGEsIG0uc3RhcnQoMSksIG0uZW5kKDEpLCBxX3NjcmVlbl9jcmVkaXRv
REM LCB0aXBvX3NjcmVlbiwgMTEwIGlmIHRpcG9fc2NyZWVuID09ICd0ZXh0b19jcmVkaXRvc19i
REM bG9jbycgZWxzZSA5OCwgY29udGV4dG9fc2NyZWVuKQogICAgICAgICAgICAgICAgIyBVbWEg
REM bGluaGEgYHRleHRgIHBvZGUgY29udGludWFyIGNvbSBvdXRyYXMgc3RyaW5ncyBhcMOzcyB1
REM bQogICAgICAgICAgICAgICAgIyBgK2Agb3Ugb3V0cmEgZXhwcmVzc8OjbyBQeXRob24uIENh
REM cHR1cmUgY2FkYSBsaXRlcmFsIGFkaWNpb25hbAogICAgICAgICAgICAgICAgIyBwYXJhIG7D
REM o28gZGVpeGFyIGEgc2VndW5kYSBtZXRhZGUgZGUgdW0gdGV4dG8gdmlzw612ZWwgcGFyYSB0
REM csOhcy4KICAgICAgICAgICAgICAgICMgUmVjdXBlcmEgZnJhZ21lbnRvcyBkZSBsaW5ndWFn
REM ZW0gbmF0dXJhbCBlbSBleHByZXNzw7VlcyBkaW7Dom1pY2FzCiAgICAgICAgICAgICAgICAj
REM IGNvbW8gYHRleHRidXR0b24gaW5kZW50KjIgKyAiLSAiICsgImNhbWVyYSJgIG91CiAgICAg
REM ICAgICAgICAgICAjIGB0ZXh0YnV0dG9uIGluZGVudCo0ICsgIiAgd2l0aCBbdmFsdWVbMV1d
REM ImAuIFPDsyBsZW1vcyBhIGV4cHJlc3PDo28KICAgICAgICAgICAgICAgICMgZGUgdGV4dG8g
REM ZSBwYXJhbW9zIGFudGVzIGRhcyBwcm9wcmllZGFkZXMvYcOnw7VlcyBkbyBkaXNwbGF5YWJs
REM ZS4KICAgICAgICAgICAgICAgICMgTGl0ZXJhaXMgY29tcG9zdG9zIGFwZW5hcyBwb3IgcGxh
REM Y2Vob2xkZXJzL3ZhbG9yZXMgZGluw6JtaWNvcyBuw6NvCiAgICAgICAgICAgICAgICAjIGVu
REM dHJhbSwgcG9pcyBuw6NvIGNvbnTDqm0gdGV4dG8gZXN0w6F0aWNvIHBhcmEgdHJhZHV6aXIu
REM CiAgICAgICAgICAgICAgICBtX3NjcmVlbl9leHByID0gcmUubWF0Y2gocideKD86dGV4dGJ1
REM dHRvbnx0ZXh0KVxzKycsIGxpbmhhX2xpbXBhLCByZS5JKQogICAgICAgICAgICAgICAgaWYg
REM bV9zY3JlZW5fZXhwcjoKICAgICAgICAgICAgICAgICAgICBpbmljaW9fZXhwciA9IG1fc2Ny
REM ZWVuX2V4cHIuZW5kKCkKICAgICAgICAgICAgICAgICAgICBmaW1fZXhwciA9IGZpbV9leHBy
REM ZXNzYW9fdGV4dG9fc2NyZWVuKGxpbmhhX2xpbXBhLCBpbmljaW9fZXhwcikKICAgICAgICAg
REM ICAgICAgICAgICBleHByX3RleHRvID0gbGluaGFfbGltcGFbaW5pY2lvX2V4cHI6ZmltX2V4
REM cHJdCiAgICAgICAgICAgICAgICAgICAgZm9yIG1fZXhwcl9saXQgaW4gcmUuZmluZGl0ZXIo
REM UVNUUl9MT0NBTCwgZXhwcl90ZXh0byk6CiAgICAgICAgICAgICAgICAgICAgICAgIHFfZXhw
REM ciA9IG1fZXhwcl9saXQuZ3JvdXAoMCkKICAgICAgICAgICAgICAgICAgICAgICAgdHJ5Ogog
REM ICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsb3JfZXhwciA9IGRlY29kaWZpY2FyX2xp
REM dGVyYWxfdHJhZHVjYW8ocV9leHByKQogICAgICAgICAgICAgICAgICAgICAgICBleGNlcHQg
REM RXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsb3JfZXhwciA9IHN0
REM cmlwX3F1b3RlcyhxX2V4cHIpCiAgICAgICAgICAgICAgICAgICAgICAgICMgUmVtb3ZhIGlu
REM dGVycG9sYcOnw6NvIFJlbidQeSBlIHBsYWNlaG9sZGVycyBkZSBmb3JtYXRhw6fDo28KICAg
REM ICAgICAgICAgICAgICAgICAgICAgIyBhbnRlcyBkZSBjb25maXJtYXIgc2UgbyBsaXRlcmFs
REM IHBvc3N1aSBwYWxhdnJhcyBlc3TDoXRpY2FzLgogICAgICAgICAgICAgICAgICAgICAgICBl
REM c3RhdGljb19leHByID0gcmUuc3ViKHInXFtbXlxdXSpcXScsICcgJywgdmFsb3JfZXhwcikK
REM ICAgICAgICAgICAgICAgICAgICAgICAgZXN0YXRpY29fZXhwciA9IHJlLnN1YihyJ1x7W157
REM fV0qXH0nLCAnICcsIGVzdGF0aWNvX2V4cHIpCiAgICAgICAgICAgICAgICAgICAgICAgIGxl
REM dHJhc19leHByID0gcmUuZmluZGFsbChyJ1tBLVphLXrDgC3DlsOYLcO2w7gtw79dJywgZXN0
REM YXRpY29fZXhwcikKICAgICAgICAgICAgICAgICAgICAgICAgaWYgbGVuKGxldHJhc19leHBy
REM KSA8IDI6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAg
REM ICAgICAgICAgICAgICBpZiBub3QgdGVtX2NvbnRldWRvX3RyYWR1eml2ZWwocV9leHByKToK
REM ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgICAgICAg
REM ICAgICAgIGluaWNpb19waWVjZSA9IGluaWNpb19leHByICsgbV9leHByX2xpdC5zdGFydCgw
REM KQogICAgICAgICAgICAgICAgICAgICAgICBmaW1fcGllY2UgPSBpbmljaW9fZXhwciArIG1f
REM ZXhwcl9saXQuZW5kKDApCiAgICAgICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihudW1l
REM cm9fbGluaGEsIGluaWNpb19waWVjZSwgZmltX3BpZWNlLCBxX2V4cHIsICd1aScsIDk4LAog
REM ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2ZyYWdtZW50byB0ZXh0dWFsIGVz
REM dMOhdGljbyBlbSBleHByZXNzw6NvIGRlIHRleHQvdGV4dGJ1dHRvbicpCgogICAgICAgICAg
REM ICAjIE1lbnUgcG9kZSBhcGFyZWNlciBkZW50cm8gZGUgb3V0cm8gbWVudS4gQSB2YXJpw6F2
REM ZWwgw7puaWNhIGRhIHZlcnPDo28KICAgICAgICAgICAgIyBhbnRlcmlvciBwZXJkaWEgbyBt
REM ZW51LXBhaSBxdWFuZG8gbyBzdWJtZW51IHRlcm1pbmF2YS4gQSBwaWxoYSBwcmVzZXJ2YQog
REM ICAgICAgICAgICAjIHRvZG9zIG9zIG7DrXZlaXMgdsOhbGlkb3Mgc2VndW5kbyBhIGluZGVu
REM dGHDp8OjbyBsw7NnaWNhIGRvIFJlbidQeS4KICAgICAgICAgICAgaWYgcmUubWF0Y2gocide
REM bWVudVxiLio6JywgbGluaGFfbGltcGEsIHJlLkkpOgogICAgICAgICAgICAgICAgd2hpbGUg
REM bWVudV9zdGFjayBhbmQgbml2ZWxfaW5kZW50IDw9IG1lbnVfc3RhY2tbLTFdOgogICAgICAg
REM ICAgICAgICAgICAgIG1lbnVfc3RhY2sucG9wKCkKICAgICAgICAgICAgICAgIG1lbnVfc3Rh
REM Y2suYXBwZW5kKG5pdmVsX2luZGVudCkKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAg
REM ICAgIHdoaWxlIG1lbnVfc3RhY2sgYW5kIG5pdmVsX2luZGVudCA8PSBtZW51X3N0YWNrWy0x
REM XToKICAgICAgICAgICAgICAgICAgICBtZW51X3N0YWNrLnBvcCgpCiAgICAgICAgICAgIGlm
REM IG1lbnVfc3RhY2s6CiAgICAgICAgICAgICAgICBtX21lbnUgPSBNRU5VX09QVElPTl9SRS5t
REM YXRjaChsaW5oYV9saW1wYSkKICAgICAgICAgICAgICAgIGlmIG1fbWVudToKICAgICAgICAg
REM ICAgICAgICAgICBxX21lbnUgPSBtX21lbnUuZ3JvdXAoMSkKICAgICAgICAgICAgICAgICAg
REM ICBpZiB0ZW1fY29udGV1ZG9fdHJhZHV6aXZlbChxX21lbnUpIGFuZCBub3QgcGFyZWNlX3Rl
REM eHRvX3RlY25pY28ocV9tZW51LCBpbmRpY2VfYXJxdWl2b3M9aW5kaWNlX2FycXVpdm9zKToK
REM ICAgICAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbV9tZW51
REM LnN0YXJ0KDEpLCBtX21lbnUuZW5kKDEpLCBxX21lbnUsICd1aScsIDk4LCAnb3DDp8OjbyB0
REM ZXh0dWFsIGRlIG1lbnUgUmVuXCdQeScpCgogICAgICAgICAgICBpZiBub3QgZW1fcHl0aG9u
REM OgogICAgICAgICAgICAgICAgbV9sYmwgPSByZS5tYXRjaChyJ15sYWJlbFxzKygnICsgUVNU
REM Ul9MT0NBTCArIHInKScsIGxpbmhhX2xpbXBhKQogICAgICAgICAgICAgICAgaWYgbV9sYmw6
REM CiAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbV9sYmwuc3Rh
REM cnQoMSksIG1fbGJsLmVuZCgxKSwgbV9sYmwuZ3JvdXAoMSksICd1aScsIDk2LCAndGV4dG8g
REM ZGUgbGFiZWwgKHRlbGEvdGVsZWZvbmUpJykKCiAgICAgICAgICAgIG1fdmFyID0gVklTSVZF
REM TF9BU1NJR05fUkUubWF0Y2gobGluaGFfbGltcGEpCiAgICAgICAgICAgIGlmIG1fdmFyOgog
REM ICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbV92YXIuc3RhcnQoMiks
REM IG1fdmFyLmVuZCgyKSwgbV92YXIuZ3JvdXAoMiksICd1aScsIDEwMCwgJ3ZhcmnDoXZlbCB2
REM aXPDrXZlbDogJyArIG1fdmFyLmdyb3VwKDEpKQoKICAgICAgICAgICAgaWYgbnVtZXJvX2xp
REM bmhhIG5vdCBpbiBsaW5oYXNfZW1fZGVmaW5pY2FvX3BlcnNvbmFnZW06CiAgICAgICAgICAg
REM ICAgICBtX2NoYXIgPSBDSEFSX0RFRl9MSU5FX1JFLm1hdGNoKGxpbmhhX2xpbXBhKQogICAg
REM ICAgICAgICAgICAgaWYgbV9jaGFyOgogICAgICAgICAgICAgICAgICAgIGtpbmQgPSBtX2No
REM YXIuZ3JvdXAoMik7IGNoYW1hZGEgPSBsaW5oYV9saW1wYVttX2NoYXIuZW5kKCk6XQogICAg
REM ICAgICAgICAgICAgICAgIGRpc3BsYXlfbmFtZSwgZHluYW1pY192YXIsIHBvc19ub21lID0g
REM ZXh0cmFpcl9pbmZvX25vbWVfcGVyc29uYWdlbShjaGFtYWRhLCBraW5kKQogICAgICAgICAg
REM ICAgICAgICAgIGlmIGRpc3BsYXlfbmFtZSBpcyBub3QgTm9uZSBhbmQgcG9zX25vbWUgPj0g
REM MDoKICAgICAgICAgICAgICAgICAgICAgICAgbXEgPSByZS5tYXRjaChRU1RSX0xPQ0FMLCBj
REM aGFtYWRhW3Bvc19ub21lOl0pCiAgICAgICAgICAgICAgICAgICAgICAgIGlmIG1xOgogICAg
REM ICAgICAgICAgICAgICAgICAgICAgICAgcSA9IG1xLmdyb3VwKDApOyBwb3MgPSBtX2NoYXIu
REM ZW5kKCkgKyBwb3Nfbm9tZQogICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFy
REM KG51bWVyb19saW5oYSwgcG9zLCBwb3MgKyBsZW4ocSksIHEsICdub21lX3BlcnNvbmFnZW0n
REM LCAxMDAsICdkZWZpbmnDp8OjbyBkZSBwZXJzb25hZ2VtJykKCiAgICAgICAgICAgIG1fZXhw
REM ID0gRVhQTElDSVRfU0FZX1JFLm1hdGNoKGxpbmhhX2xpbXBhKQogICAgICAgICAgICBpZiBt
REM X2V4cCBhbmQgbm90IGVtX3B5dGhvbiBhbmQgbm90IGxpbmhhX2xpbXBhLmxvd2VyKCkuc3Rh
REM cnRzd2l0aCgoJ2xhYmVsICcsICdpbWFnZSAnLCAnc2NlbmUgJywgJ3Nob3cgJywgJ3BsYXkg
REM JywgJ3ZvaWNlICcpKToKICAgICAgICAgICAgICAgIHExLCBxMiA9IG1fZXhwLmdyb3VwKDEp
REM LCBtX2V4cC5ncm91cCgyKQogICAgICAgICAgICAgICAgIyAibSIgIk9sw6EhIjogc2UgIm0i
REM IMOpIG8gbm9tZSBkZSB1bWEgdmFyacOhdmVsIGRlIHBlcnNvbmFnZW0gZG8gam9nbywgw6kg
REM Y2hhdmUsIG7Do28gbm9tZS4KICAgICAgICAgICAgICAgIGlmIG5vdCAodm9jYWJ1bGFyaW8g
REM YW5kIHN0cmlwX3F1b3RlcyhxMSkgaW4gdm9jYWJ1bGFyaW8uZ2V0KCdwZXJzb25hZ2Vucycs
REM ICgpKSk6CiAgICAgICAgICAgICAgICAgICAgcmVnaXN0cmFyKG51bWVyb19saW5oYSwgbV9l
REM eHAuc3RhcnQoMSksIG1fZXhwLmVuZCgxKSwgcTEsICdub21lX3BlcnNvbmFnZW0nLCAxMDAs
REM ICdub21lIGV4cGzDrWNpdG8gZGUgZmFsYScpCiAgICAgICAgICAgICAgICByZWdpc3RyYXIo
REM bnVtZXJvX2xpbmhhLCBtX2V4cC5zdGFydCgyKSwgbV9leHAuZW5kKDIpLCBxMiwgJ2RpYWxv
REM Z28nLCAxMDAsICdmYWxhIGV4cGzDrWNpdGEnKQoKICAgICAgICAgICAgcHJpbWVpcm9fbSA9
REM IHJlLm1hdGNoKHInXihbQS1aYS16X11bXHcuXSopJywgbGluaGFfbGltcGEpCiAgICAgICAg
REM ICAgIGVoX3Jlc2VydmFkYSA9IGJvb2wocHJpbWVpcm9fbSkgYW5kIHByaW1laXJvX20uZ3Jv
REM dXAoMSkubG93ZXIoKSBpbiBCSUJMSU9URUNBX1JFTlBZLmdldCgndG9rZW5zX25hb19kaWFs
REM b2dvJywgc2V0KCkpCiAgICAgICAgICAgIGlmIG5vdCBlaF9yZXNlcnZhZGEgYW5kIG51bWVy
REM b19saW5oYSBub3QgaW4gbGluaGFzX2VtX2RlZmluaWNhb19wZXJzb25hZ2VtOgogICAgICAg
REM ICAgICAgICAgbSA9IExFR0FDWV9ESUFMT0dPLm1hdGNoKGxpbmhhX2xpbXBhKQogICAgICAg
REM ICAgICAgICAgaWYgbSBhbmQgbm90IHJlLm1hdGNoKHInXHMqOlxzKlteXHMjXScsIGxpbmhh
REM X2xpbXBhW20uZW5kKDEpOl0pOgogICAgICAgICAgICAgICAgICAgICMgRmFsYSBwb2RlIHNl
REM ciBlc2NyaXRhIGNvbW8gdsOhcmlhcyBzdHJpbmdzIGFkamFjZW50ZXMgbmEKICAgICAgICAg
REM ICAgICAgICAgICAjIG1lc21hIGxpbmhhIChjb25jYXRlbmHDp8OjbyBpbXBsw61jaXRhKTog
REM IG0gInBhcnRlIDEgIiAicGFydGUgMiIuCiAgICAgICAgICAgICAgICAgICAgIyBSZWdpc3Ry
REM YSBUT0RBUyBhcyBzdHJpbmdzIGRvIGJsb2NvIGZpbmFsIGNvbnTDrWd1bywgc2Vuw6NvIGFz
REM CiAgICAgICAgICAgICAgICAgICAgIyBwcmltZWlyYXMgcGFydGVzIGZpY2FyaWFtIHNlbSB0
REM cmFkdcOnw6NvLgogICAgICAgICAgICAgICAgICAgIHRvZGFzID0gW3ggZm9yIHggaW4gcmUu
REM ZmluZGl0ZXIoUVNUUl9MT0NBTCwgbGluaGFfbGltcGEpIGlmIHguZW5kKCkgPD0gbS5lbmQo
REM MSldCiAgICAgICAgICAgICAgICAgICAgYmxvY28gPSBbXQogICAgICAgICAgICAgICAgICAg
REM IGZvciB4IGluIHJldmVyc2VkKHRvZGFzKToKICAgICAgICAgICAgICAgICAgICAgICAgaWYg
REM YmxvY28gYW5kIGxpbmhhX2xpbXBhW3guZW5kKCk6YmxvY29bLTFdLnN0YXJ0KCldLnN0cmlw
REM KCkgIT0gJyc6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBicmVhawogICAgICAgICAg
REM ICAgICAgICAgICAgICBibG9jby5hcHBlbmQoeCkKICAgICAgICAgICAgICAgICAgICBibG9j
REM by5yZXZlcnNlKCkKICAgICAgICAgICAgICAgICAgICBmb3IgeCBpbiBibG9jbzoKICAgICAg
REM ICAgICAgICAgICAgICAgICAgcHJlZml4b190eHQgPSBsaW5oYV9saW1wYVs6eC5zdGFydCgp
REM XS5zdHJpcCgpCiAgICAgICAgICAgICAgICAgICAgICAgIHBhbGF2cmFzX3ByZWZpeG8gPSBy
REM ZS5maW5kYWxsKHInW1x3Ll0rJywgcHJlZml4b190eHQpCiAgICAgICAgICAgICAgICAgICAg
REM ICAgICMgIm0iICJPbMOhISI6IGEgcHJpbWVpcmEgc3RyaW5nIMOpIGEgY2hhdmUgZG8gcGVy
REM c29uYWdlbSwgbsOjbyB0ZXh0by4KICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGxlbihi
REM bG9jbykgPj0gMiBhbmQgeCBpcyBibG9jb1swXSBhbmQgdm9jYWJ1bGFyaW8KICAgICAgICAg
REM ICAgICAgICAgICAgICAgICAgICAgICBhbmQgc3RyaXBfcXVvdGVzKHguZ3JvdXAoMCkpIGlu
REM IHZvY2FidWxhcmlvLmdldCgncGVyc29uYWdlbnMnLCAoKSkpOgogICAgICAgICAgICAgICAg
REM ICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgICAgICAgICAgICAgaWYgZW1fcHl0
REM aG9uIGFuZCAocHJlZml4b190eHQgb3Igbm90IHBhcmVjZV9mcmFzZSh4Lmdyb3VwKDApKSk6
REM CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICAgICAg
REM ICAgICAgICBpZiBwYXJlY2VfY29kaWdvX25hX2xpbmhhKGxpbmhhX2xpbXBhLCB4LnN0YXJ0
REM KCksIHguZW5kKCkpOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAg
REM ICAgICAgICAgICAgICAgICAgICAgIyBSZWdyYSBnbG9iYWw6IHVtYSBzdHJpbmcgaXNvbGFk
REM YSBkZSBuw612ZWwgMCDDqSBuYXJyYXRpdmEgUmVuJ1B5IHbDoWxpZGEuCiAgICAgICAgICAg
REM ICAgICAgICAgICAgICMgRWxhIGRldmUgc2VyIGV4dHJhw61kYSBtZXNtbyBzZW0gbm9tZSBk
REM ZSBwZXJzb25hZ2VtIG91IHByZWZpeG8uCiAgICAgICAgICAgICAgICAgICAgICAgICMgTyBm
REM aWx0cm8gcGFyZWNlX2NvZGlnb19uYV9saW5oYSBlIGFzIHJlZ3JhcyBzZW3Dom50aWNhcyBh
REM Y2ltYQogICAgICAgICAgICAgICAgICAgICAgICAjIGNvbnRpbnVhbSBpbXBlZGluZG8gbGl0
REM ZXJhaXMgcXVlIHNlamFtIGPDs2RpZ28vZXN0cnV0dXJhIHTDqWNuaWNhLgogICAgICAgICAg
REM ICAgICAgICAgICAgICBpZiAocGFsYXZyYXNfcHJlZml4byBhbmQgcGFsYXZyYXNfcHJlZml4
REM b1stMV0gaW4gUFJPUFJJRURBREVTX05BT19URVhUTwogICAgICAgICAgICAgICAgICAgICAg
REM ICAgICAgICAgIGFuZCBwYWxhdnJhc19wcmVmaXhvWzBdIGluIChQUk9QUklFREFERVNfTkFP
REM X1RFWFRPIHwgRUxFTUVOVE9TX0RFX1RFTEEgfCBmcm96ZW5zZXQoWydoYXMnXSkpKToKICAg
REM ICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgICAgICAgICAg
REM ICAgIGlmIChwYWxhdnJhc19wcmVmaXhvIGFuZCBwYWxhdnJhc19wcmVmaXhvWy0xXSBpbiBF
REM TEVNRU5UT1NfQ09OVEFJTkVSCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5k
REM IHBhbGF2cmFzX3ByZWZpeG9bMF0gaW4gKFBST1BSSUVEQURFU19OQU9fVEVYVE8gfCBFTEVN
REM RU5UT1NfREVfVEVMQSB8IGZyb3plbnNldChbJ2hhcyddKSkpOgogICAgICAgICAgICAgICAg
REM ICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgICAgICAgICAgICAgaWYgbGVuKHBh
REM bGF2cmFzX3ByZWZpeG8pID49IDIgYW5kIHBhbGF2cmFzX3ByZWZpeG9bLTFdID09ICdrZXkn
REM OgogICAgICAgICAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgICAg
REM ICAgICAgICAgaWYgbGVuKHBhbGF2cmFzX3ByZWZpeG8pID49IDIgYW5kIHBhbGF2cmFzX3By
REM ZWZpeG9bMF0gPT0gJ3Bob25lJyBhbmQgcGFsYXZyYXNfcHJlZml4b1sxXSBpbiAoJ2NhbGwn
REM LCAnaGFuZ3VwJywgJ2Rpc2N1c3Npb24nKToKICAgICAgICAgICAgICAgICAgICAgICAgICAg
REM IGNvbnRpbnVlCiAgICAgICAgICAgICAgICAgICAgICAgIGlmIHBhbGF2cmFzX3ByZWZpeG8g
REM YW5kIHBhbGF2cmFzX3ByZWZpeG9bMF0gaW4gRUxFTUVOVE9TX0RFX1RFTEEgYW5kIG5vdCB0
REM ZW1fY29udGV1ZG9fdHJhZHV6aXZlbCh4Lmdyb3VwKDApKToKICAgICAgICAgICAgICAgICAg
REM ICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgICAgICAgICAgICAgIHJlZ2lzdHJhcihu
REM dW1lcm9fbGluaGEsIHguc3RhcnQoKSwgeC5lbmQoKSwgeC5ncm91cCgwKSwKICAgICAgICAg
REM ICAgICAgICAgICAgICAgICAgICAgICAgICdkaWFsb2dvJyBpZiBwcmVmaXhvX3R4dCBlbHNl
REM ICduYXJyYXRpdmEnLCA5NSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBy
REM ZWZpeG9fdHh0IG9yICduYXJyYXRpdmEgLyBzdHJpbmcgaXNvbGFkYScpCgogICAgICAgICMg
REM Q29iZXJ0dXJhIGFkaWNpb25hbCBwYXJhIHN0cmluZ3MgZGlyZXRhcyBSZW4nUHkgZm9yYSBk
REM byBRU1RSIGxlZ2Fkby4KICAgICAgICAjIFPDsyBjb25zaWRlcmFtb3MgciIuLi4iL3JcJy4u
REM LlwnL3JgLi4uYCBlIGAuLi5gLCBldml0YW5kbyBhYnJpciBvIHNjYW5uZXIKICAgICAgICAj
REM IGdlbsOpcmljbyBwYXJhIHRvZGFzIGFzIHN0cmluZ3Mgbm9ybWFpcyBlLCBhc3NpbSwgcmVk
REM dXppbmRvIGZhbHNvcyBwb3NpdGl2b3MuCiAgICAgICAgaWYgbm90IGVtX3B5dGhvbjoKICAg
REM ICAgICAgICAgY29udGV4dG9fZXNwZWNpYWwgPSAoCiAgICAgICAgICAgICAgICBib29sKHJl
REM Lm1hdGNoKHInXig/Ol98X198X19ffF9wKVxzKlwoJywgbGluaGFfbGltcGEsIHJlLkkpKSBv
REM cgogICAgICAgICAgICAgICAgYm9vbChyZS5tYXRjaChyJ14oPzp0ZXh0fHRleHRidXR0b258
REM YnV0dG9ufGxhYmVsfHByb21wdHx0b29sdGlwfGNvbmZpcm18Y2FwdGlvbilcYicsIGxpbmhh
REM X2xpbXBhLCByZS5JKSkgb3IKICAgICAgICAgICAgICAgIGJvb2wocmUubWF0Y2gocidebWVu
REM dVxiJywgbGluaGFfbGltcGEsIHJlLkkpKSBvcgogICAgICAgICAgICAgICAgYm9vbChzY3Jl
REM ZW5faW5kZW50IGlzIG5vdCBOb25lKSBvcgogICAgICAgICAgICAgICAgYm9vbChtZW51X3N0
REM YWNrKSBvcgogICAgICAgICAgICAgICAgYm9vbChyZS5tYXRjaChyJ15yP1siXCdgXScsIGxp
REM bmhhX2xpbXBhLCByZS5JKSkgb3IKICAgICAgICAgICAgICAgIGJvb2wocmUubWF0Y2gocide
REM W0EtWmEtel9dW1x3Ll0qXHMrKD86cik/WyJcJ2BdJywgbGluaGFfbGltcGEsIHJlLkkpKSBv
REM cgogICAgICAgICAgICAgICAgYm9vbChyZS5zZWFyY2gocidcYig/OlRleHR8UGFyYW1ldGVy
REM aXplZFRleHR8cmVucHlcLig/OnNheXxub3RpZnl8aW5wdXQpfE5vdGlmeXxDb25maXJtfElu
REM cHV0VmFsdWUpXHMqXCguKig/OnIpP1siXCdgXScsIGxpbmhhX2xpbXBhLCByZS5JKSkKICAg
REM ICAgICAgICAgKQogICAgICAgICAgICBpZiBjb250ZXh0b19lc3BlY2lhbDoKICAgICAgICAg
REM ICAgICAgIGZvciBpbmljaW9fZXNwZWNpYWwsIGZpbV9lc3BlY2lhbCwgcV9lc3BlY2lhbCwg
REM cmF3X2VzcGVjaWFsIGluIGl0ZXJfcmVucHlfbGl0ZXJhaXNfZXNwZWNpYWlzKGxpbmhhX2xp
REM bXBhKToKICAgICAgICAgICAgICAgICAgICBpZiBub3QgdGVtX2NvbnRldWRvX3RyYWR1eml2
REM ZWwocV9lc3BlY2lhbCk6CiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAg
REM ICAgICAgICAgICAgICAgaWYgcGFyZWNlX2NvZGlnb19uYV9saW5oYShsaW5oYV9saW1wYSwg
REM aW5pY2lvX2VzcGVjaWFsLCBmaW1fZXNwZWNpYWwpOgogICAgICAgICAgICAgICAgICAgICAg
REM ICBjb250aW51ZQogICAgICAgICAgICAgICAgICAgIHByZWZpeG9fZXNwZWNpYWwgPSBsaW5o
REM YV9saW1wYVs6aW5pY2lvX2VzcGVjaWFsXS5zdHJpcCgpCiAgICAgICAgICAgICAgICAgICAg
REM c3VmaXhvX2VzcGVjaWFsID0gbGluaGFfbGltcGFbZmltX2VzcGVjaWFsOl0uc3RyaXAoKQog
REM ICAgICAgICAgICAgICAgICAgIHNlbWFudGljYV9vayA9IHBhcmVjZV9zdHJpbmdfc2VtYW50
REM aWNhKHFfZXNwZWNpYWwsIGNhbWluaG8pCiAgICAgICAgICAgICAgICAgICAgIyBSYXcvYmFj
REM a3RpY2sgZGUgdW1hIMO6bmljYSBwYWxhdnJhIHBvZGUgc2VyIHRleHRvIHbDoWxpZG8uCiAg
REM ICAgICAgICAgICAgICAgICAgIyBRdWFuZG8gbyBsaXRlcmFsIMOpIG8gaXRlbSBkZSB1bWEg
REM b3DDp8OjbyBkZSBtZW51LCBvdSBxdWFuZG8KICAgICAgICAgICAgICAgICAgICAjIGVzdMOh
REM IHNvemluaG8gY29tbyBuYXJyYXRpdmEsIG8gY29udGV4dG8gc2ludMOhdGljbyByZXNvbHZl
REM IGEKICAgICAgICAgICAgICAgICAgICAjIGFtYmlndWlkYWRlIHF1ZSBvIGZpbHRybyBkZSBp
REM ZGVudGlmaWNhZG9yZXMgdGVyaWEgY3JpYWRvLgogICAgICAgICAgICAgICAgICAgIGNvbnRl
REM eHRvX3Zpc2l2ZWxfZXNwZWNpYWwgPSAoCiAgICAgICAgICAgICAgICAgICAgICAgIChib29s
REM KG1lbnVfc3RhY2spIGFuZCBzdWZpeG9fZXNwZWNpYWwuc3RhcnRzd2l0aCgnOicpKSBvcgog
REM ICAgICAgICAgICAgICAgICAgICAgICAobm90IHByZWZpeG9fZXNwZWNpYWwgYW5kIG5vdCBz
REM dWZpeG9fZXNwZWNpYWwgYW5kCiAgICAgICAgICAgICAgICAgICAgICAgICBib29sKHJlLm1h
REM dGNoKHInXnI/WyJcJ2BdJywgbGluaGFfbGltcGEsIHJlLkkpKSkKICAgICAgICAgICAgICAg
REM ICAgICApCiAgICAgICAgICAgICAgICAgICAgaWYgbm90IHNlbWFudGljYV9vayBhbmQgbm90
REM IGNvbnRleHRvX3Zpc2l2ZWxfZXNwZWNpYWw6CiAgICAgICAgICAgICAgICAgICAgICAgIGNv
REM bnRpbnVlCiAgICAgICAgICAgICAgICAgICAgdGlwb19lc3BlY2lhbCA9ICd1aScKICAgICAg
REM ICAgICAgICAgICAgICBpZiBwcmVmaXhvX2VzcGVjaWFsIGFuZCByZS5tYXRjaChyJ15bQS1a
REM YS16X11bXHcuXSokJywgcHJlZml4b19lc3BlY2lhbC5zcGxpdCgpWy0xXSk6CiAgICAgICAg
REM ICAgICAgICAgICAgICAgIGNhbmRpZGF0b19wZXJzb25hZ2VtID0gcHJlZml4b19lc3BlY2lh
REM bC5zcGxpdCgpWy0xXQogICAgICAgICAgICAgICAgICAgICAgICBpZiB2b2NhYnVsYXJpbyBh
REM bmQgY2FuZGlkYXRvX3BlcnNvbmFnZW0gaW4gdm9jYWJ1bGFyaW8uZ2V0KCdwZXJzb25hZ2Vu
REM cycsICgpKToKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpcG9fZXNwZWNpYWwgPSAn
REM ZGlhbG9nbycKICAgICAgICAgICAgICAgICAgICBlbGlmIHJlLm1hdGNoKHInXnI/WyJcJ2Bd
REM JywgbGluaGFfbGltcGEsIHJlLkkpOgogICAgICAgICAgICAgICAgICAgICAgICB0aXBvX2Vz
REM cGVjaWFsID0gJ25hcnJhdGl2YScKICAgICAgICAgICAgICAgICAgICByZWdpc3RyYXIobnVt
REM ZXJvX2xpbmhhLCBpbmljaW9fZXNwZWNpYWwsIGZpbV9lc3BlY2lhbCwgcV9lc3BlY2lhbCwg
REM dGlwb19lc3BlY2lhbCwgOTgsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdzdHJp
REM bmcgUmVuXCdQeSBlc3BlY2lhbCAocmF3L2JhY2t0aWNrKScpCgogICAgICAgIGlmIG51bWVy
REM b19saW5oYSBpbiBsaW5oYXNfbW9ub2xvZ286CiAgICAgICAgICAgIGVzcGVjaWFpcyA9IFty
REM IGZvciByIGluIHJlZ2lzdHJvcyBpZiByWzJdIGluICgnZ2V0dGV4dF9tdWx0aWxpbmhhJywg
REM J3BvZW1hX2NvcnBvJyldCiAgICAgICAgICAgIHJlZ2lzdHJvcyA9IGVzcGVjaWFpcyBvciBb
REM ciBmb3IgciBpbiByZWdpc3Ryb3MgaWYgclsyXSA9PSAnbW9ub2xvZ29fdHJpcGxhcyddCgog
REM ICAgICAgICMgTWF0ZXJpYWxpemHDp8Ojby9kZWR1cGxpY2HDp8Ojby4gUHJpbWVpcm8gcmVz
REM b2x2ZSBzb2JyZXBvc2nDp8O1ZXMgZsOtc2ljYXMKICAgICAgICAjIGVudHJlIGRldGVjdG9y
REM ZXMgZGlmZXJlbnRlczsgZGVwb2lzIGVsaW1pbmEgc29tZW50ZSBkdXBsaWNhdGFzIGV4YXRh
REM cy4KICAgICAgICByZWdpc3Ryb3MsIF9jb25mbGl0b3Nfc29icmVwb3NpY2FvID0gX3Jlc29s
REM dmVyX3NvYnJlcG9zaWNvZXNfcmVnaXN0cm9zKHJlZ2lzdHJvcykKICAgICAgICB2aXN0b3Mg
REM PSBzZXQoKQogICAgICAgIGZvciBpbmljaW9fbGltcG8sIGZpbV9saW1wbywgdGlwbywgY29u
REM ZiwgY3R4LCB0cmVjaG8sIG9yaWdpbmFsX21hcGEgaW4gcmVnaXN0cm9zOgogICAgICAgICAg
REM ICBjaGF2ZSA9IChpbmljaW9fbGltcG8sIGZpbV9saW1wbykKICAgICAgICAgICAgaWYgY2hh
REM dmUgaW4gdmlzdG9zOgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgdmlz
REM dG9zLmFkZChjaGF2ZSkKICAgICAgICAgICAgaW5pY2lvID0gbGVuKHByZWZpeG9fd3MpICsg
REM aW5pY2lvX2xpbXBvCiAgICAgICAgICAgIGZpbSA9IGxlbihwcmVmaXhvX3dzKSArIGZpbV9s
REM aW1wbwogICAgICAgICAgICBlc3BlcmFkbyA9IG9yaWdpbmFsX21hcGEgaWYgb3JpZ2luYWxf
REM bWFwYSBpcyBub3QgTm9uZSBlbHNlIHRyZWNobwogICAgICAgICAgICBpZiBsaW5oYV9zZW1f
REM ZmltW2luaWNpbzpmaW1dICE9IGVzcGVyYWRvOgogICAgICAgICAgICAgICAgY29udGludWUK
REM ICAgICAgICAgICAgdGV4dG9zLmFwcGVuZCgoY3R4LCB0cmVjaG8pKQogICAgICAgICAgICBt
REM YXBhLmFwcGVuZCh7ImxpbmhhIjogbnVtZXJvX2xpbmhhLCAiY29sdW5hX2luaWNpbyI6IGlu
REM aWNpbywgImNvbHVuYV9maW0iOiBmaW0sICJvcmlnaW5hbCI6IChvcmlnaW5hbF9tYXBhIGlm
REM IG9yaWdpbmFsX21hcGEgaXMgbm90IE5vbmUgZWxzZSB0cmVjaG8pLCAidGlwbyI6IHRpcG8s
REM ICJjb25maWFuY2EiOiBjb25mLCAiY29udGV4dG8iOiBjdHh9KQoKICAgIHJldHVybiB0ZXh0
REM b3MsIG1hcGEKClBBU1RBU19TRU1fVEVYVE8gPSAodSJpbWFnZXMiLCB1ImltYWdlIiwgdSJp
REM bWFnZW5zIikKCmRlZiBlbV9wYXN0YV9zZW1fdGV4dG8oY2FtaW5obywgcGFzdGFfZ2FtZSk6
REM CiAgICAjIEFycXVpdm9zIGRlbnRybyBkYSBwYXN0YSBkZSBpbWFnZW5zIChleC46IGltYWdl
REM cy9NUFQpIHPDo28gc2NyaXB0cyBkZQogICAgIyBmZXJyYW1lbnRhL2ltYWdlbTogbsOjbyB0
REM w6ptIHRleHRvIHF1ZSBvIGpvZ2Fkb3IgdmVqYSwgZW50w6NvIG7Do28gc8OjbyBleHRyYcOt
REM ZG9zLgogICAgdHJ5OgogICAgICAgIHJlbCA9IG9zLnBhdGgucmVscGF0aChjYW1pbmhvLCBw
REM YXN0YV9nYW1lKQogICAgZXhjZXB0IFZhbHVlRXJyb3I6CiAgICAgICAgcmV0dXJuIEZhbHNl
REM CiAgICBwYXJ0ZXMgPSBbcC5sb3dlcigpIGZvciBwIGluIHJlbC5yZXBsYWNlKCdcXCcsICcv
REM Jykuc3BsaXQoJy8nKVs6LTFdXQogICAgcmV0dXJuIGFueShwIGluIFBBU1RBU19TRU1fVEVY
REM VE8gZm9yIHAgaW4gcGFydGVzKQoKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiMgT3LD
REM oWN1bG8gc2Vtw6JudGljbyBSZW4nUHk6IGRlc2NvYmVydGEgZG8gU0RLLCBleGVjdcOnw6Nv
REM IHNlZ3VyYSBlIHJlY29uY2lsaWHDp8Ojby4KIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQpk
REM ZWYgX25vcm1hbGl6YXJfcmVsX3JlbnB5KHZhbG9yKToKICAgIHZhbG9yID0gKHZhbG9yIG9y
REM IHUiIikucmVwbGFjZSgiXFwiLCAiLyIpLnN0cmlwKCkKICAgIHdoaWxlIHZhbG9yLnN0YXJ0
REM c3dpdGgoIi4vIik6CiAgICAgICAgdmFsb3IgPSB2YWxvclsyOl0KICAgIGlmIHZhbG9yLmxv
REM d2VyKCkuc3RhcnRzd2l0aCgiZ2FtZS8iKToKICAgICAgICB2YWxvciA9IHZhbG9yWzU6XQog
REM ICAgcmV0dXJuIHZhbG9yLnJlcGxhY2UoIi8vIiwgIi8iKQoKCmRlZiBfdmVyc2FvX251bWVy
REM aWNhKHZhbG9yKToKICAgIG51bXMgPSByZS5maW5kYWxsKHIiXGQrIiwgdmFsb3Igb3IgdSIi
REM KQogICAgdHJ5OgogICAgICAgIHJldHVybiB0dXBsZShpbnQoeCkgZm9yIHggaW4gbnVtc1s6
REM NF0pCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHJldHVybiB0dXBsZSgpCgoKZGVm
REM IF9yYWl6ZXNfY2FuZGlkYXRhc19zZGtfcmVucHkocmFpeik6CiAgICAiIiJMb2NhbGl6YSBT
REM REtzIFJlbidQeSBjb21wbGV0b3MsIGNvbSBjYW1pbmhvIGV4cGzDrWNpdG8gcHJlZmVyZW5j
REM aWFsIGUgZmFsbGJhY2sgc2VndXJvLgoKICAgIEEgbm92YSByYWl6IG9maWNpYWwgZG8gY2Fj
REM aGUgw6kgJUxPQ0FMQVBQREFUQSVcXEREQUMuIE9zIGNhY2hlcyBEREFDLVNESyBlCiAgICBE
REM REFDLVNESy1Nb2JpbGUgY29udGludWFtIHNlbmRvIGxpZG9zIHNvbWVudGUgcGFyYSBjb21w
REM YXRpYmlsaWRhZGUgcmV0cm9hdGl2YS4KICAgIEREQUNfUkVOUFlfU0RLIG51bmNhIGJsb3F1
REM ZWlhIGEgZGVzY29iZXJ0YSBzZSBlc3RpdmVyIGluY29tcGxldG8uCiAgICAiIiIKICAgIGNh
REM bmRpZGF0YXM9W10KICAgIGRlZiBhZGQocCk6CiAgICAgICAgaWYgbm90IHA6IHJldHVybgog
REM ICAgICAgIHA9b3MucGF0aC5hYnNwYXRoKG9zLnBhdGguZXhwYW5kdmFycyhvcy5wYXRoLmV4
REM cGFuZHVzZXIocCkpKQogICAgICAgIGlmIG9zLnBhdGguaXNkaXIocCkgYW5kIHAgbm90IGlu
REM IGNhbmRpZGF0YXM6IGNhbmRpZGF0YXMuYXBwZW5kKHApCiAgICBmb3IgZW52X25vbWUgaW4g
REM KCJEREFDX1JFTlBZX1NESyIsIlJFTlBZX1NESyIpOiBhZGQob3MuZW52aXJvbi5nZXQoZW52
REM X25vbWUsIiIpKQogICAgbG9jYWw9b3MuZW52aXJvbi5nZXQoIkxPQ0FMQVBQREFUQSIsIiIp
REM OyB1c2VyPW9zLmVudmlyb24uZ2V0KCJVU0VSUFJPRklMRSIsIiIpCiAgICBwcm9ncmFtZGF0
REM YT1vcy5lbnZpcm9uLmdldCgiUFJPR1JBTURBVEEiLCIiKTsgcHJvZ3JhbWZpbGVzPW9zLmVu
REM dmlyb24uZ2V0KCJQUk9HUkFNRklMRVMiLCIiKTsgcHJvZ3JhbWZpbGVzX3g4Nj1vcy5lbnZp
REM cm9uLmdldCgiUFJPR1JBTUZJTEVTKFg4NikiLCIiKQogICAgYmFzZXM9W29zLnBhdGguam9p
REM bihsb2NhbCwiRERBQyIpLHJhaXosb3MucGF0aC5kaXJuYW1lKHJhaXopLG9zLnBhdGguam9p
REM bihsb2NhbCwiRERBQy1TREsiKSxvcy5wYXRoLmpvaW4obG9jYWwsIkREQUMtU0RLLU1vYmls
REM ZSIpLG9zLnBhdGguam9pbihsb2NhbCwiRERBQy1TREstUG9ydCIpLG9zLnBhdGguam9pbihs
REM b2NhbCwiUmVuUHkiKSxvcy5wYXRoLmpvaW4odXNlciwiUmVuUHkiKSxvcy5wYXRoLmpvaW4o
REM dXNlciwicmVucHkiKSxvcy5wYXRoLmpvaW4ocHJvZ3JhbWRhdGEsIlJlblB5Iiksb3MucGF0
REM aC5qb2luKHByb2dyYW1maWxlcywiUmVuUHkiKSxvcy5wYXRoLmpvaW4ocHJvZ3JhbWZpbGVz
REM X3g4NiwiUmVuUHkiKV0KICAgIGZvciBiYXNlIGluIGJhc2VzOiBhZGQoYmFzZSkKICAgIHZp
REM c2l0YWRvcz1zZXQoKTsgZmlsYT1bKHAsMCkgZm9yIHAgaW4gbGlzdChjYW5kaWRhdGFzKV0K
REM ICAgIHdoaWxlIGZpbGE6CiAgICAgICAgYXR1YWwsbml2ZWw9ZmlsYS5wb3AoMCk7IGNoYXZl
REM PW9zLnBhdGgubm9ybWNhc2Uob3MucGF0aC5ub3JtcGF0aChhdHVhbCkpCiAgICAgICAgaWYg
REM Y2hhdmUgaW4gdmlzaXRhZG9zOiBjb250aW51ZQogICAgICAgIHZpc2l0YWRvcy5hZGQoY2hh
REM dmUpCiAgICAgICAgaWYgb3MucGF0aC5pc2ZpbGUob3MucGF0aC5qb2luKGF0dWFsLCJyZW5w
REM eS5weSIpKTogYWRkKGF0dWFsKTsgY29udGludWUKICAgICAgICBpZiBuaXZlbD49NTogY29u
REM dGludWUKICAgICAgICB0cnk6IG5vbWVzPW9zLmxpc3RkaXIoYXR1YWwpCiAgICAgICAgZXhj
REM ZXB0IEV4Y2VwdGlvbjogY29udGludWUKICAgICAgICBmb3Igbm9tZSBpbiBub21lczoKICAg
REM ICAgICAgICAgbG93PW5vbWUubG93ZXIoKQogICAgICAgICAgICBpZiBsb3cgaW4gKCJjYWNo
REM ZSIsIl9fcHljYWNoZV9fIiwiLmdpdCIsInRlbXAiLCJ0bXAiKTogY29udGludWUKICAgICAg
REM ICAgICAgcDI9b3MucGF0aC5qb2luKGF0dWFsLG5vbWUpCiAgICAgICAgICAgIGlmIG9zLnBh
REM dGguaXNkaXIocDIpIGFuZCAobml2ZWw9PTAgb3IgYW55KGsgaW4gbG93IGZvciBrIGluICgi
REM cmVucHkiLCJkZGFjIiwic2RrIiwiNi4iLCI3LiIsIjguIikpKTogZmlsYS5hcHBlbmQoKHAy
REM LG5pdmVsKzEpKQogICAgcmV0dXJuIFtwIGZvciBwIGluIGNhbmRpZGF0YXMgaWYgb3MucGF0
REM aC5pc2ZpbGUob3MucGF0aC5qb2luKHAsInJlbnB5LnB5IikpXQoKZGVmIF9saXN0YXJfcHl0
REM aG9uc19zZGsoc2RrKToKICAgICIiIkxpc3RhIHRvZG9zIG9zIFB5dGhvbiBlbWJ1dGlkb3Mg
REM cGxhdXPDrXZlaXMsIHRvbGVyYW5kbyBsYXlvdXRzIGFudGlnb3Mvbm92b3MuIiIiCiAgICBl
REM bmNvbnRyYWRvcz1bXTsgdmlzdG9zPXNldCgpCiAgICBwcmVmZXJpZG9zPSgKICAgICAgICBv
REM cy5wYXRoLmpvaW4oc2RrLCJsaWIiLCJweTMtd2luZG93cy14ODZfNjQiLCJweXRob24uZXhl
REM IiksCiAgICAgICAgb3MucGF0aC5qb2luKHNkaywibGliIiwicHkzLXdpbmRvd3MtaTY4NiIs
REM InB5dGhvbi5leGUiKSwKICAgICAgICBvcy5wYXRoLmpvaW4oc2RrLCJsaWIiLCJweTItd2lu
REM ZG93cy14ODZfNjQiLCJweXRob24uZXhlIiksCiAgICAgICAgb3MucGF0aC5qb2luKHNkaywi
REM bGliIiwicHkyLXdpbmRvd3MtaTY4NiIsInB5dGhvbi5leGUiKSwKICAgICAgICBvcy5wYXRo
REM LmpvaW4oc2RrLCJsaWIiLCJ3aW5kb3dzLXg4Nl82NCIsInB5dGhvbi5leGUiKSwKICAgICAg
REM ICBvcy5wYXRoLmpvaW4oc2RrLCJsaWIiLCJ3aW5kb3dzLWk2ODYiLCJweXRob24uZXhlIiks
REM CiAgICAgICAgb3MucGF0aC5qb2luKHNkaywibGliIiwicHl0aG9uLmV4ZSIpLAogICAgICAg
REM IG9zLnBhdGguam9pbihzZGssInB5dGhvbi5leGUiKSwKICAgICkKICAgIGRlZiBhZGQocCk6
REM CiAgICAgICAgaWYgbm90IHAgb3Igbm90IG9zLnBhdGguaXNmaWxlKHApOiByZXR1cm4KICAg
REM ICAgICBjaGF2ZT1vcy5wYXRoLm5vcm1jYXNlKG9zLnBhdGguYWJzcGF0aChwKSkKICAgICAg
REM ICBpZiBjaGF2ZSBpbiB2aXN0b3M6IHJldHVybgogICAgICAgIHZpc3Rvcy5hZGQoY2hhdmUp
REM OyBlbmNvbnRyYWRvcy5hcHBlbmQob3MucGF0aC5hYnNwYXRoKHApKQogICAgZm9yIHAgaW4g
REM cHJlZmVyaWRvczogYWRkKHApCiAgICB0cnk6CiAgICAgICAgbGliX3Jvb3Q9b3MucGF0aC5q
REM b2luKHNkaywibGliIikKICAgICAgICBmb3Igcm9vdCxkaXJzLGZpbGVzIGluIG9zLndhbGso
REM bGliX3Jvb3QpOgogICAgICAgICAgICByZWw9b3MucGF0aC5yZWxwYXRoKHJvb3QsbGliX3Jv
REM b3QpCiAgICAgICAgICAgIHByb2Z1bmRpZGFkZT0wIGlmIHJlbD09Ii4iIGVsc2UgcmVsLmNv
REM dW50KG9zLnNlcCkrMQogICAgICAgICAgICBpZiBwcm9mdW5kaWRhZGU+NDoKICAgICAgICAg
REM ICAgICAgIGRpcnNbOl09W107IGNvbnRpbnVlCiAgICAgICAgICAgIGRpcnNbOl09W2QgZm9y
REM IGQgaW4gZGlycyBpZiBkLmxvd2VyKCkgbm90IGluICgiY2FjaGUiLCJfX3B5Y2FjaGVfXyIp
REM XQogICAgICAgICAgICBpZiAicHl0aG9uLmV4ZSIgaW4gZmlsZXM6IGFkZChvcy5wYXRoLmpv
REM aW4ocm9vdCwicHl0aG9uLmV4ZSIpKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBw
REM YXNzCiAgICByZXR1cm4gZW5jb250cmFkb3MKCgpkZWYgX2xvY2FsaXphcl9weXRob25fc2Rr
REM KHNkayk6CiAgICAiIiJFc2NvbGhlIG8gUHl0aG9uIGVtYnV0aWRvIHF1ZSByZWFsbWVudGUg
REM Y29uc2VndWUgaW5pY2lhciBubyBhbWJpZW50ZSBkbyBTREsuIiIiCiAgICBweXRob25zPV9s
REM aXN0YXJfcHl0aG9uc19zZGsoc2RrKQogICAgaWYgbm90IHB5dGhvbnM6CiAgICAgICAgcmV0
REM dXJuIE5vbmUKICAgIHByaW1laXJvPXB5dGhvbnNbMF0KICAgIGZvciBweSBpbiBweXRob25z
REM OgogICAgICAgIHRyeToKICAgICAgICAgICAgcmFpel9weXRob249b3MucGF0aC5kaXJuYW1l
REM KG9zLnBhdGguYWJzcGF0aChweSkpCiAgICAgICAgICAgIGxpYl9kaXI9b3MucGF0aC5qb2lu
REM KHJhaXpfcHl0aG9uLCJMaWIiKQogICAgICAgICAgICB1c2FfcHlvPShvcy5wYXRoLmlzZmls
REM ZShvcy5wYXRoLmpvaW4obGliX2Rpciwic2l0ZS5weW8iKSkgYW5kCiAgICAgICAgICAgICAg
REM ICAgICAgIG5vdCBvcy5wYXRoLmlzZmlsZShvcy5wYXRoLmpvaW4obGliX2Rpciwic2l0ZS5w
REM eSIpKSBhbmQKICAgICAgICAgICAgICAgICAgICAgbm90IG9zLnBhdGguaXNmaWxlKG9zLnBh
REM dGguam9pbihsaWJfZGlyLCJzaXRlLnB5YyIpKSkKICAgICAgICAgICAgZmxhZ3M9WyItTyJd
REM IGlmIHVzYV9weW8gZWxzZSBbXQogICAgICAgICAgICBlbnY9b3MuZW52aXJvbi5jb3B5KCkK
REM ICAgICAgICAgICAgZW52LnBvcCgiUFlUSE9OVVNFUkJBU0UiLE5vbmUpCiAgICAgICAgICAg
REM IGVudlsiUFlUSE9OSE9NRSJdPXJhaXpfcHl0aG9uCiAgICAgICAgICAgIGVudlsiUFlUSE9O
REM UEFUSCJdPWxpYl9kaXIKICAgICAgICAgICAgY3A9c3VicHJvY2Vzcy5ydW4oW3B5XStmbGFn
REM cytbIi1jIiwiaW1wb3J0IHN5cyxzaXRlOyBwcmludChzeXMudmVyc2lvbl9pbmZvWzBdKSJd
REM LGN3ZD1zZGssZW52PWVudixzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLHN0ZGVycj1zdWJwcm9j
REM ZXNzLlNURE9VVCx0ZXh0PVRydWUsZW5jb2Rpbmc9InV0Zi04IixlcnJvcnM9InJlcGxhY2Ui
REM LHRpbWVvdXQ9MjApCiAgICAgICAgICAgIGlmIGNwLnJldHVybmNvZGU9PTAgYW5kIChjcC5z
REM dGRvdXQgb3IgIiIpLnN0cmlwKCkuc3BsaXRsaW5lcygpWy0xOl0gOgogICAgICAgICAgICAg
REM ICAgcmV0dXJuIHB5CiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgY29u
REM dGludWUKICAgIHJldHVybiBwcmltZWlybwoKCmRlZiBfb2J0ZXJfdmVyc2FvX3NkayhweXRo
REM b25fc2RrLCBzZGspOgogICAgIiIiT2J0w6ltIGEgdmVyc8OjbyBkbyBTREsgcGVsbyBDTEkg
REM ZSwgc2UgbmVjZXNzw6FyaW8sIHBlbG8gY8OzZGlnbyBkbyBTREsuIiIiCiAgICBpZiBweXRo
REM b25fc2RrOgogICAgICAgIHRyeToKICAgICAgICAgICAgY3A9c3VicHJvY2Vzcy5ydW4oW3B5
REM dGhvbl9zZGssInJlbnB5LnB5IiwiLS12ZXJzaW9uIl0sY3dkPXNkayxzdGRvdXQ9c3VicHJv
REM Y2Vzcy5QSVBFLHN0ZGVycj1zdWJwcm9jZXNzLlNURE9VVCx0ZXh0PVRydWUsZW5jb2Rpbmc9
REM InV0Zi04IixlcnJvcnM9InJlcGxhY2UiLHRpbWVvdXQ9NDUpCiAgICAgICAgICAgIHNhaWRh
REM PShjcC5zdGRvdXQgb3IgdSIiKS5zdHJpcCgpOyBtPXJlLnNlYXJjaChyIlJlbi4/UHlccyso
REM WzAtOV0rKD86XC5bMC05XSspezEsNH0pIixzYWlkYSxyZS5JKQogICAgICAgICAgICBpZiBt
REM OiByZXR1cm4gbS5ncm91cCgxKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246IHBhc3MKICAg
REM IGZvciBwYXRoIGluIChvcy5wYXRoLmpvaW4oc2RrLCJyZW5weSIsIl9faW5pdF9fLnB5Iiks
REM b3MucGF0aC5qb2luKHNkaywicmVucHkiLCJ2ZXJzaW9uLnB5Iiksb3MucGF0aC5qb2luKHNk
REM aywicmVucHkiLCJ2Y192ZXJzaW9uLnB5IikpOgogICAgICAgIGlmIG5vdCBvcy5wYXRoLmlz
REM ZmlsZShwYXRoKTogY29udGludWUKICAgICAgICB0cnk6CiAgICAgICAgICAgIHdpdGggaW8u
REM b3BlbihwYXRoLCJyIixlbmNvZGluZz0idXRmLTgiLGVycm9ycz0icmVwbGFjZSIpIGFzIGY6
REM IHNyYz1mLnJlYWQoKQogICAgICAgICAgICBmb3IgcGF0IGluIChyInZlcnNpb25fdHVwbGVc
REM cyo9XHMqXCgoW14pXSopXCkiLHIiX192ZXJzaW9uX19ccyo9XHMqW1wiJ10oW15cIiddKyki
REM LHIidmVyc2lvblxzKj1ccypbXCInXShbXlwiJ10rKSIpOgogICAgICAgICAgICAgICAgbT1y
REM ZS5zZWFyY2gocGF0LHNyYyxyZS5JKQogICAgICAgICAgICAgICAgaWYgbToKICAgICAgICAg
REM ICAgICAgICAgICBudW1zPXJlLmZpbmRhbGwociJcZCsiLG0uZ3JvdXAoMSkpCiAgICAgICAg
REM ICAgICAgICAgICAgaWYgbnVtczogcmV0dXJuIHUiLiIuam9pbihudW1zWzo0XSkKICAgICAg
REM ICBleGNlcHQgRXhjZXB0aW9uOiBwYXNzCiAgICByZXR1cm4gdSIiCgoKZGVmIF92ZXJzYW9f
REM cG9yX25vbWVfY2FtaW5ob19zZGsoc2RrKToKICAgIHBhcnRlcz1vcy5wYXRoLm5vcm1wYXRo
REM KHNkaykucmVwbGFjZSgiLyIsb3Muc2VwKS5zcGxpdChvcy5zZXApOyBhY2hhZG9zPVtdCiAg
REM ICBmb3IgcGFydGUgaW4gcGFydGVzOgogICAgICAgIG09cmUuZnVsbG1hdGNoKHIiNlwuXGQr
REM XC5cZCsoPzpcLlxkKyk/IixwYXJ0ZSkKICAgICAgICBpZiBtOiBhY2hhZG9zLmFwcGVuZCht
REM Lmdyb3VwKDApKTsgY29udGludWUKICAgICAgICBtPXJlLnNlYXJjaChyInJlbnB5Wy1fIF0/
REM KCg/OjZcLlxkK1wuXGQrKD86XC5cZCspPyl8KD86N1wuXGQrXC5cZCspfCg/OjhcLlxkK1wu
REM XGQrKSkiLHBhcnRlLHJlLkkpCiAgICAgICAgaWYgbTogYWNoYWRvcy5hcHBlbmQobS5ncm91
REM cCgxKSkKICAgIHJldHVybiBhY2hhZG9zWy0xXSBpZiBhY2hhZG9zIGVsc2UgdSIiCgpkZWYg
REM X2RldGVjdGFyX3ZlcnNhb19wcm9qZXRvX3JlbnB5KHBhc3RhX2dhbWUsIGNhbmRpZGF0b3Mp
REM OgogICAgIiIiSW5mZXJlIGEgdmVyc8OjbyBkbyBSZW4nUHkgdXNhbmRvIGFzIG1lc21hcyBm
REM b250ZXMgZm9ydGVzIGRhIFY1MyBlIGFsZ3VtYXMKICAgIGV4dGVuc8O1ZXMgc2VndXJhcy4g
REM TnVuY2EgdHJhdGEgdW0gbm9tZSBnZW7DqXJpY28gZGUgcGFzdGEgY29tbyB2ZXJzw6NvIGV4
REM YXRhLgoKICAgIE9yZGVtIGRlIGV2aWTDqm5jaWE6CiAgICAgIDEpIGdhbWUvc2NyaXB0X3Zl
REM cnNpb24udHh0IChtZXRhZGFkbyBvZmljaWFsIGRlIGRpc3RyaWJ1acOnw7VlcyBSZW4nUHkp
REM OwogICAgICAyKSByZW5weS9fX2luaXRfXy5weSBsb2NhbCBkbyBwcm9qZXRvICh2ZXJzaW9u
REM X3R1cGxlL19fdmVyc2lvbl9fKTsKICAgICAgMykgcmVucHkvdmNfdmVyc2lvbi5weSBsb2Nh
REM bCAoUmVuJ1B5IDggZSBidWlsZHMgbW9kZXJuYXMpOwogICAgICA0KSBxdWFscXVlciAucnB5
REM Ly5ycHltLy5weSBkbyBwcm9qZXRvIGNvbSBjb21wYXJhw6fDo28gZXhwbMOtY2l0YSBkZQog
REM ICAgICAgICByZW5weS52ZXJzaW9uX3R1cGxlOwogICAgICA1KSBjYWNoZSBEREFDLVNESyBs
REM b2NhbCBhbyBwcm9qZXRvLCBzb21lbnRlIHF1YW5kbyBleGlzdGUgdW1hIMO6bmljYQogICAg
REM ICAgICB2ZXJzw6NvIGluZXF1w612b2NhLgogICAgIiIiCiAgICBldmlkZW5jaWFzID0gW10K
REM ICAgIHJhaXpfcHJvamV0byA9IG9zLnBhdGguZGlybmFtZShvcy5wYXRoLmFic3BhdGgocGFz
REM dGFfZ2FtZSkpCgogICAgZGVmIGxlcl90ZXh0byhjYW1pbmhvKToKICAgICAgICBmb3IgZW5j
REM IGluICgidXRmLTgtc2lnIiwgImNwMTI1MiIsICJsYXRpbi0xIik6CiAgICAgICAgICAgIHRy
REM eToKICAgICAgICAgICAgICAgIHdpdGggaW8ub3BlbihjYW1pbmhvLCAiciIsIGVuY29kaW5n
REM PWVuYywgZXJyb3JzPSJyZXBsYWNlIikgYXMgZjoKICAgICAgICAgICAgICAgICAgICByZXR1
REM cm4gZi5yZWFkKCkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAg
REM ICAgIGNvbnRpbnVlCiAgICAgICAgcmV0dXJuIHUiIgoKICAgIGRlZiBhZGljaW9uYXIobnVt
REM cywgb3JpZ2VtKToKICAgICAgICBpZiBub3QgbnVtczoKICAgICAgICAgICAgcmV0dXJuCiAg
REM ICAgICAgIyBTREtzIG9maWNpYWlzIHPDo28gZW5kZXJlw6dhZG9zIHBvciBhdMOpIDQgY29t
REM cG9uZW50ZXM7IGEgZGV0ZWPDp8OjbyBwb2RlCiAgICAgICAgIyByZWNlYmVyIHVtIHF1aW50
REM byBjb21wb25lbnRlIGRlIGJ1aWxkLCBtYXMgYSBwcmVwYXJhw6fDo28gcmVkdXogcGFyYSA0
REM LgogICAgICAgIG51bXMgPSB0dXBsZShpbnQoeCkgZm9yIHggaW4gbnVtcyBpZiBzdHIoeCku
REM c3RyaXAoKSAhPSAiIikKICAgICAgICBpZiBudW1zOgogICAgICAgICAgICBldmlkZW5jaWFz
REM LmFwcGVuZCgobnVtc1s6NV0sIG9yaWdlbSkpCgogICAgIyAxKSBFdmlkw6puY2lhIGF1eGls
REM aWFyOiBsb2cudHh0LCBxdWFuZG8gZXhpc3RlLiBOw6NvIMOpIG9icmlnYXTDs3JpbyBlIG7D
REM o28KICAgICMgdmVuY2UgbWV0YWRhZG9zIGRlIHZlcnPDo28gZW5jb250cmFkb3MgZGlyZXRh
REM bWVudGUgbm9zIGFycXVpdm9zIGRvIHByb2pldG8uCiAgICAjIEV4ZW1wbG8gb2JzZXJ2YWRv
REM OiBSZW4nUHkgNy41LjMuMjIwOTA4MDkuCiAgICBjYW1pbmhvc19sb2cgPSAoCiAgICAgICAg
REM b3MucGF0aC5qb2luKHJhaXpfcHJvamV0bywgImxvZy50eHQiKSwKICAgICAgICBvcy5wYXRo
REM LmpvaW4ocGFzdGFfZ2FtZSwgImxvZy50eHQiKSwKICAgICkKICAgIGZvciBjYW1pbmhvX2xv
REM ZyBpbiBjYW1pbmhvc19sb2c6CiAgICAgICAgaWYgbm90IG9zLnBhdGguaXNmaWxlKGNhbWlu
REM aG9fbG9nKToKICAgICAgICAgICAgY29udGludWUKICAgICAgICBkYWRvc19sb2cgPSBsZXJf
REM dGV4dG8oY2FtaW5ob19sb2cpCiAgICAgICAgbV9sb2cgPSByZS5zZWFyY2gociJSZW4uP1B5
REM XHMrKFswLTldKyg/OlwuWzAtOV0rKXsyLDR9KSIsIGRhZG9zX2xvZywgcmUuSSkKICAgICAg
REM ICBpZiBtX2xvZzoKICAgICAgICAgICAgdG9kb3MgPSB0dXBsZShpbnQoeCkgZm9yIHggaW4g
REM bV9sb2cuZ3JvdXAoMSkuc3BsaXQoIi4iKSkKICAgICAgICAgICAgaWYgdG9kb3NbMF0gPT0g
REM NiBhbmQgbGVuKHRvZG9zKSA+PSA0OgogICAgICAgICAgICAgICAgbnVtc19sb2cgPSB0b2Rv
REM c1s6NF0KICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIG51bXNfbG9nID0gdG9k
REM b3NbOjNdCiAgICAgICAgICAgIGFkaWNpb25hcihudW1zX2xvZywgY2FtaW5ob19sb2cgKyAi
REM IDo6IFJlbidQeSBkbyBsb2cudHh0IikKCiAgICAjIDIpIE1ldGFkYWRvIG9maWNpYWwgY3Jp
REM YWRvIHBlbG8gcHJvY2Vzc28gZGUgZGlzdHJpYnVpw6fDo28gZG8gUmVuJ1B5LgogICAgIyBP
REM IFJlbidQeSBhdHVhbCBncmF2YSByZXByKHJlbnB5LnZlcnNpb25fdHVwbGVbOi0xXSkgZW0g
REM c2NyaXB0X3ZlcnNpb24udHh0LgogICAgIyBQb3J0YW50byAoNywgNCwgMTEpIGNvbnRpbnVh
REM IHNlbmRvIHVtYSBldmlkw6puY2lhIGZvcnRlIHBhcmEgbyBTREsgNy40LjExLgogICAgZm9y
REM IG5vbWUgaW4gKCJzY3JpcHRfdmVyc2lvbi50eHQiLCAic2NyaXB0X3ZlcnNpb24ucnB5Iiwg
REM InNjcmlwdF92ZXJzaW9uLnJweWMiKToKICAgICAgICBjYW1pbmhvX3N2ID0gb3MucGF0aC5q
REM b2luKHBhc3RhX2dhbWUsIG5vbWUpCiAgICAgICAgaWYgbm90IG9zLnBhdGguaXNmaWxlKGNh
REM bWluaG9fc3YpIG9yIG5vdCBjYW1pbmhvX3N2Lmxvd2VyKCkuZW5kc3dpdGgoKCIudHh0Iiwg
REM Ii5ycHkiKSk6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgZGFkb3MgPSBsZXJfdGV4
REM dG8oY2FtaW5ob19zdikuc3RyaXAoKQogICAgICAgIG51bXMgPSB0dXBsZShpbnQoeCkgZm9y
REM IHggaW4gcmUuZmluZGFsbChyIlxkKyIsIGRhZG9zKVs6NF0pCiAgICAgICAgaWYgbnVtczoK
REM ICAgICAgICAgICAgYWRpY2lvbmFyKG51bXMsIGNhbWluaG9fc3YpCiAgICAgICAgICAgIGJy
REM ZWFrCgogICAgIyAzKSBDw7NwaWEgbG9jYWwgZG8gbW90b3IsIGV4YXRhbWVudGUgY29tbyBh
REM IFY1MyBmYXouCiAgICBjYW1pbmhvX2luaXQgPSBvcy5wYXRoLmpvaW4ocmFpel9wcm9qZXRv
REM LCAicmVucHkiLCAiX19pbml0X18ucHkiKQogICAgaWYgb3MucGF0aC5pc2ZpbGUoY2FtaW5o
REM b19pbml0KToKICAgICAgICB0eHQgPSBsZXJfdGV4dG8oY2FtaW5ob19pbml0KQogICAgICAg
REM IGZvciBwYWRyYW8gaW4gKAogICAgICAgICAgICByInZlcnNpb25fdHVwbGVccyo9XHMqXChc
REM cyooWzAtOV0rKD86XHMqLFxzKlswLTldKyl7MSw0fSkiLAogICAgICAgICAgICByInZlcnNp
REM b25fdHVwbGVccyo9XHMqXCg/KFswLTldKyg/OlxzKixccypbMC05XSspezEsNH0pXCk/IiwK
REM ICAgICAgICApOgogICAgICAgICAgICBtID0gcmUuc2VhcmNoKHBhZHJhbywgdHh0LCByZS5J
REM KQogICAgICAgICAgICBpZiBtOgogICAgICAgICAgICAgICAgbnVtcyA9IHR1cGxlKGludCh4
REM KSBmb3IgeCBpbiByZS5maW5kYWxsKHIiXGQrIiwgbS5ncm91cCgxKSlbOjVdKQogICAgICAg
REM ICAgICAgICAgYWRpY2lvbmFyKG51bXMsIGNhbWluaG9faW5pdCArICIgOjogdmVyc2lvbl90
REM dXBsZSIpCiAgICAgICAgICAgICAgICBicmVhawogICAgICAgIGlmIG5vdCBhbnkob3JpZyA9
REM PSBjYW1pbmhvX2luaXQgKyAiIDo6IHZlcnNpb25fdHVwbGUiIGZvciBfLCBvcmlnIGluIGV2
REM aWRlbmNpYXMpOgogICAgICAgICAgICBtID0gcmUuc2VhcmNoKHIiX192ZXJzaW9uX19ccyo9
REM XHMqW1wiJ10oW15cIiddKykiLCB0eHQsIHJlLkkpCiAgICAgICAgICAgIGlmIG06CiAgICAg
REM ICAgICAgICAgICBudW1zID0gdHVwbGUoaW50KHgpIGZvciB4IGluIHJlLmZpbmRhbGwociJc
REM ZCsiLCBtLmdyb3VwKDEpKVs6NV0pCiAgICAgICAgICAgICAgICBhZGljaW9uYXIobnVtcywg
REM Y2FtaW5ob19pbml0ICsgIiA6OiBfX3ZlcnNpb25fXyIpCgogICAgIyA0KSBSZW4nUHkgOCBw
REM YXNzb3UgYSBjYWxjdWxhciB2ZXJzaW9uX3R1cGxlIGEgcGFydGlyIGRlIHZjX3ZlcnNpb24u
REM cHkuCiAgICBjYW1pbmhvX3ZjID0gb3MucGF0aC5qb2luKHJhaXpfcHJvamV0bywgInJlbnB5
REM IiwgInZjX3ZlcnNpb24ucHkiKQogICAgaWYgb3MucGF0aC5pc2ZpbGUoY2FtaW5ob192Yyk6
REM CiAgICAgICAgdHh0ID0gbGVyX3RleHRvKGNhbWluaG9fdmMpCiAgICAgICAgbSA9IHJlLnNl
REM YXJjaChyIig/bSleXHMqdmVyc2lvblxzKj1ccypbXCInXT8oW15cIidcclxuXSspIiwgdHh0
REM LCByZS5JKQogICAgICAgIGlmIG06CiAgICAgICAgICAgIG51bXMgPSB0dXBsZShpbnQoeCkg
REM Zm9yIHggaW4gcmUuZmluZGFsbChyIlxkKyIsIG0uZ3JvdXAoMSkpWzo1XSkKICAgICAgICAg
REM ICAgYWRpY2lvbmFyKG51bXMsIGNhbWluaG9fdmMgKyAiIDo6IHZlcnNpb24iKQoKICAgICMg
REM NSkgQ29tcGFyYcOnw7VlcyBleHBsw61jaXRhcyBkZSB2ZXJzw6NvIHBvZGVtIGFwYXJlY2Vy
REM IGVtIHNjcmlwdHMgZG8gbW9kLgogICAgIyBOw6NvIGxpbWl0YW1vcyBpc3NvIGEgb3B0aW9u
REM cy9jb25maWcvZGVmaW5pdGlvbnM6IGFsZ3VucyB0ZW1wbGF0ZXMgY29sb2NhbQogICAgIyBh
REM IGNvbXBhdGliaWxpZGFkZSBlbSB1bSBhcnF1aXZvIHNlcGFyYWRvLgogICAgZm9yIGNhbWlu
REM aG8gaW4gY2FuZGlkYXRvczoKICAgICAgICBpZiBub3QgY2FtaW5oby5sb3dlcigpLmVuZHN3
REM aXRoKCgiLnJweSIsICIucnB5bSIsICIucHkiKSk6CiAgICAgICAgICAgIGNvbnRpbnVlCiAg
REM ICAgICAgdHh0ID0gbGVyX3RleHRvKGNhbWluaG8pCiAgICAgICAgaWYgbm90IHR4dDoKICAg
REM ICAgICAgICAgY29udGludWUKICAgICAgICBmb3IgbSBpbiByZS5maW5kaXRlcihyInJlbnB5
REM XC52ZXJzaW9uX3R1cGxlXHMqPT1ccypcKChbXildKylcKSIsIHR4dCwgcmUuSSk6CiAgICAg
REM ICAgICAgIG51bXMgPSB0dXBsZShpbnQoeCkgZm9yIHggaW4gcmUuZmluZGFsbChyIlxkKyIs
REM IG0uZ3JvdXAoMSkpWzo1XSkKICAgICAgICAgICAgYWRpY2lvbmFyKG51bXMsIGNhbWluaG8g
REM KyAiIDo6IHZlcnNpb25fdHVwbGU9PSIpCiAgICAgICAgaWYgcmUuc2VhcmNoKHIiUmVuLj9Q
REM eVxzKjhccytERExDXHMrQ29tcGxpYW50IiwgdHh0LCByZS5JKToKICAgICAgICAgICAgYWRp
REM Y2lvbmFyKCg4LCksIGNhbWluaG8gKyAiIDo6IFJlbidQeSA4IERETEMgQ29tcGxpYW50IikK
REM ICAgICAgICBpZiByZS5zZWFyY2gociJSZW4uP1B5XHMqN1xzK0RETENccytDb21wbGlhbnQi
REM LCB0eHQsIHJlLkkpOgogICAgICAgICAgICBhZGljaW9uYXIoKDcsKSwgY2FtaW5obyArICIg
REM OjogUmVuJ1B5IDcgRERMQyBDb21wbGlhbnQiKQogICAgICAgIGlmIHJlLnNlYXJjaChyIlJl
REM bi4/UHlccyo2XHMrRERMQ1xzK0NvbXBsaWFudCIsIHR4dCwgcmUuSSk6CiAgICAgICAgICAg
REM IGFkaWNpb25hcigoNiwpLCBjYW1pbmhvICsgIiA6OiBSZW4nUHkgNiBERExDIENvbXBsaWFu
REM dCIpCgogICAgIyBFdmlkw6puY2lhcyBjb21wbGV0YXMgKGluY2x1aW5kbyBvIGxvZyBvcGNp
REM b25hbCkgdMOqbSBwcmlvcmlkYWRlIHNvYnJlIGNhY2hlLgogICAgY29tcGxldGFzID0gW3gg
REM Zm9yIHggaW4gZXZpZGVuY2lhcyBpZiBsZW4oeFswXSkgPj0gM10KICAgIGlmIGNvbXBsZXRh
REM czoKICAgICAgICAjIEV2aWTDqm5jaWEgZGUgbWFpb3IgZXNwZWNpZmljaWRhZGUgcHJpbWVp
REM cm87IGVtIGVtcGF0ZSwgbWV0YWRhZG9zIG1haXMKICAgICAgICAjIGNvbmZpw6F2ZWlzIHbD
REM qm0gYW50ZXMgZGUgY29tZW50w6FyaW9zIGRlIGNvbXBhdGliaWxpZGFkZS4KICAgICAgICBk
REM ZWYgcGVzbyhpdGVtKToKICAgICAgICAgICAgbnVtcywgb3JpZ2VtID0gaXRlbQogICAgICAg
REM ICAgICBsb3cgPSBvcmlnZW0ubG93ZXIoKQogICAgICAgICAgICBmb3J0ZSA9IDAKICAgICAg
REM ICAgICAgaWYgInNjcmlwdF92ZXJzaW9uLnR4dCIgaW4gbG93OgogICAgICAgICAgICAgICAg
REM Zm9ydGUgPSA1CiAgICAgICAgICAgIGVsaWYgIl9faW5pdF9fLnB5IiBpbiBsb3cgYW5kICgi
REM dmVyc2lvbl90dXBsZSIgaW4gbG93IG9yICJfX3ZlcnNpb25fXyIgaW4gbG93KToKICAgICAg
REM ICAgICAgICAgIGZvcnRlID0gNAogICAgICAgICAgICBlbGlmICJ2Y192ZXJzaW9uLnB5IiBp
REM biBsb3c6CiAgICAgICAgICAgICAgICBmb3J0ZSA9IDQKICAgICAgICAgICAgZWxpZiAidmVy
REM c2lvbl90dXBsZT09IiBpbiBsb3c6CiAgICAgICAgICAgICAgICBmb3J0ZSA9IDMKICAgICAg
REM ICAgICAgZWxpZiAibG9nLnR4dCIgaW4gbG93OgogICAgICAgICAgICAgICAgZm9ydGUgPSAx
REM CiAgICAgICAgICAgIHJldHVybiAoZm9ydGUsIGxlbihudW1zKSkKICAgICAgICBjb21wbGV0
REM YXMuc29ydChrZXk9cGVzbywgcmV2ZXJzZT1UcnVlKQogICAgICAgIHJldHVybiBjb21wbGV0
REM YXNbMF1bMF0sIGNvbXBsZXRhcwoKICAgICMgNikgSWd1YWwgw6AgZXN0cmF0w6lnaWEgZGUg
REM Y2FjaGUgdXNhZGEgcGVsYSBWNTMsIG1hcyBzZW0gZXNjb2xoZXIKICAgICMgYXJiaXRyYXJp
REM YW1lbnRlIGEgdmVyc8OjbyBtYWlzIGFsdGEgcXVhbmRvIGjDoSB2w6FyaWFzLgogICAgY2Fj
REM aGVfcmFpemVzID0gWwogICAgICAgIG9zLnBhdGguam9pbihyYWl6X3Byb2pldG8sICJEREFD
REM LVNESyIpLAogICAgICAgIG9zLnBhdGguam9pbihyYWl6X3Byb2pldG8sICJEREFDLVNESy1N
REM b2JpbGUiKSwKICAgIF0KICAgIGxvY2FsID0gb3MuZW52aXJvbi5nZXQoIkxPQ0FMQVBQREFU
REM QSIsICIiKQogICAgaWYgbG9jYWw6CiAgICAgICAgY2FjaGVfcmFpemVzLmFwcGVuZChvcy5w
REM YXRoLmpvaW4obG9jYWwsICJEREFDLVNESyIpKQogICAgICAgIGNhY2hlX3JhaXplcy5hcHBl
REM bmQob3MucGF0aC5qb2luKGxvY2FsLCAiRERBQy1TREstTW9iaWxlIikpCgogICAgY2FjaGVf
REM dmVyc29lcyA9IFtdCiAgICB2aXN0b3NfY2FjaGUgPSBzZXQoKQogICAgZm9yIGJhc2UgaW4g
REM Y2FjaGVfcmFpemVzOgogICAgICAgIGlmIG5vdCBvcy5wYXRoLmlzZGlyKGJhc2UpOgogICAg
REM ICAgICAgICBjb250aW51ZQogICAgICAgIHRyeToKICAgICAgICAgICAgbm9tZXMgPSBvcy5s
REM aXN0ZGlyKGJhc2UpCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgY29u
REM dGludWUKICAgICAgICBmb3Igbm9tZSBpbiBub21lczoKICAgICAgICAgICAgaWYgbm90IHJl
REM Lm1hdGNoKHIiXlxkKyg/OlwuXGQrKXsxLDN9JCIsIG5vbWUpOgogICAgICAgICAgICAgICAg
REM Y29udGludWUKICAgICAgICAgICAgY2FtaW5ob19zZGsgPSBvcy5wYXRoLmpvaW4oYmFzZSwg
REM bm9tZSkKICAgICAgICAgICAgaWYgbm90IG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9pbihj
REM YW1pbmhvX3NkaywgInJlbnB5LnB5IikpOgogICAgICAgICAgICAgICAgY29udGludWUKICAg
REM ICAgICAgICAgY2hhdmUgPSAob3MucGF0aC5ub3JtY2FzZShvcy5wYXRoLmFic3BhdGgoY2Ft
REM aW5ob19zZGspKSwgbm9tZSkKICAgICAgICAgICAgaWYgY2hhdmUgaW4gdmlzdG9zX2NhY2hl
REM OgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgdmlzdG9zX2NhY2hlLmFk
REM ZChjaGF2ZSkKICAgICAgICAgICAgY2FjaGVfdmVyc29lcy5hcHBlbmQoKHR1cGxlKGludCh4
REM KSBmb3IgeCBpbiBub21lLnNwbGl0KCIuIikpLCBjYW1pbmhvX3NkayArICIgOjogY2FjaGUi
REM KSkKCiAgICAjIFVtYSDDum5pY2EgdmVyc8OjbyBleGF0YSBubyBjYWNoZSDDqSBzZWd1cmEg
REM cGFyYSByZXV0aWxpemHDp8Ojby4gQ29tIGR1YXMgb3UKICAgICMgbWFpcyB2ZXJzw7Vlcywg
REM YSByb3RpbmEgYW50aWdhIGVzY29saGVyaWEgdW1hIGFyYml0cmFyaWFtZW50ZTsgYXF1aSBu
REM w6NvCiAgICAjIGZhemVtb3MgaXNzbywgcG9ycXVlIGEgT3DDp8OjbyAxIGV4aWdlIG8gU0RL
REM IGV4YXRvLgogICAgdW5pY2FzID0ge30KICAgIGZvciBudW1zLCBvcmlnZW0gaW4gY2FjaGVf
REM dmVyc29lczoKICAgICAgICB1bmljYXMuc2V0ZGVmYXVsdChudW1zLCBvcmlnZW0pCiAgICBp
REM ZiBsZW4odW5pY2FzKSA9PSAxOgogICAgICAgIG51bXMsIG9yaWdlbSA9IG5leHQoaXRlcih1
REM bmljYXMuaXRlbXMoKSkpCiAgICAgICAgcmV0dXJuIG51bXMsIFsobnVtcywgb3JpZ2VtKV0K
REM CiAgICAjIEV2aWTDqm5jaWFzIGFwZW5hcyBkZSBmYW3DrWxpYSBzw6NvIMO6dGVpcyBwYXJh
REM IGRpYWduw7NzdGljbywgbWFzIG7Do28gYXV0b3JpemFtCiAgICAjIGJhaXhhciB1bSBTREsg
REM ZXhhdG8uIFJldG9ybmFtb3MtbmFzIHNlcGFyYWRhcyBwYXJhIG8gY2hhbWFkb3IgcG9kZXIg
REM cmVnaXN0cmFyCiAgICAjIG8gbW90aXZvIGRvIGJsb3F1ZWlvIHNlbSBmYWJyaWNhciBwcmVj
REM aXPDo28uCiAgICBmYW1pbGlhcyA9IFt4IGZvciB4IGluIGV2aWRlbmNpYXMgaWYgbGVuKHhb
REM MF0pIDwgM10KICAgIGlmIGZhbWlsaWFzOgogICAgICAgIGZhbWlsaWFzLnNvcnQoa2V5PWxh
REM bWJkYSBpdGVtOiBsZW4oaXRlbVswXSksIHJldmVyc2U9VHJ1ZSkKICAgICAgICByZXR1cm4g
REM ZmFtaWxpYXNbMF1bMF0sIGZhbWlsaWFzCgogICAgcmV0dXJuIE5vbmUsIFtdCgoKZGVmIF9l
REM c3RpbWF0aXZhX21ham9yX3JlbnB5KHBhc3RhX2dhbWUsIGNhbmRpZGF0b3MpOgogICAgYWx2
REM bywgXyA9IF9kZXRlY3Rhcl92ZXJzYW9fcHJvamV0b19yZW5weShwYXN0YV9nYW1lLCBjYW5k
REM aWRhdG9zKQogICAgaWYgYWx2bzoKICAgICAgICByZXR1cm4gYWx2b1swXQogICAgbm9tZXMg
REM PSBbb3MucGF0aC5iYXNlbmFtZSh4KS5sb3dlcigpIGZvciB4IGluIGNhbmRpZGF0b3NdCiAg
REM ICBpZiBhbnkoeC5lbmRzd2l0aCgiX3Jlbi5weSIpIGZvciB4IGluIG5vbWVzKToKICAgICAg
REM ICByZXR1cm4gOAogICAgaWYgYW55KCJyZW5weS04IiBpbiB4IG9yICJyZW5weTgiIGluIHgg
REM Zm9yIHggaW4gbm9tZXMpOgogICAgICAgIHJldHVybiA4CiAgICBpZiBhbnkoInJlbnB5LTci
REM IGluIHggb3IgInJlbnB5NyIgaW4geCBmb3IgeCBpbiBub21lcyk6CiAgICAgICAgcmV0dXJu
REM IDcKICAgIGlmIGFueSgicmVucHktNiIgaW4geCBvciAicmVucHk2IiBpbiB4IGZvciB4IGlu
REM IG5vbWVzKToKICAgICAgICByZXR1cm4gNgogICAgcmV0dXJuIE5vbmUKCmRlZiBfZXh0cmFp
REM cl9jYW1wb19uYXRpdm8odmFsb3IpOgogICAgdmFsb3IgPSB2YWxvciBvciB1IiIKICAgIHRy
REM eToKICAgICAgICByZXR1cm4gYXN0LmxpdGVyYWxfZXZhbCh1JyInICsgdmFsb3IgKyB1JyIn
REM KQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAjIEZhbGxiYWNrIGNvbnNlcnZhZG9y
REM IHBhcmEgLS1lc2NhcGUuCiAgICAgICAgcmV0dXJuICh2YWxvci5yZXBsYWNlKHUiXFxcXCIs
REM IHUiXFwiKQogICAgICAgICAgICAgICAgICAgIC5yZXBsYWNlKHUiXFx0IiwgdSJcXHQiKQog
REM ICAgICAgICAgICAgICAgICAgIC5yZXBsYWNlKHUiXFxyIiwgdSJcXHIiKQogICAgICAgICAg
REM ICAgICAgICAgIC5yZXBsYWNlKHUiXFxuIiwgdSJcXG4iKQogICAgICAgICAgICAgICAgICAg
REM IC5yZXBsYWNlKHUnXFwiJywgdSciJykpCgoKZGVmIF9sZXJfZGlhbG9ndWVfdGFiKGNhbWlu
REM aG8pOgogICAgZW50cmFkYXMgPSBbXQogICAgaWYgbm90IG9zLnBhdGguaXNmaWxlKGNhbWlu
REM aG8pOgogICAgICAgIHJldHVybiBlbnRyYWRhcwogICAgZGF0YSA9IE5vbmUKICAgIGxhc3Rf
REM ZXJyb3IgPSBOb25lCiAgICBmb3IgZW5jIGluICgidXRmLTgtc2lnIiwgImNwMTI1MiIsICJs
REM YXRpbi0xIik6CiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRoIGlvLm9wZW4oY2FtaW5o
REM bywgInIiLCBlbmNvZGluZz1lbmMsIGVycm9ycz0icmVwbGFjZSIsIG5ld2xpbmU9IiIpIGFz
REM IGY6CiAgICAgICAgICAgICAgICBkYXRhID0gZi5yZWFkKCkKICAgICAgICAgICAgYnJlYWsK
REM ICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICAgICAgbGFzdF9lcnJv
REM ciA9IGV4YwogICAgaWYgZGF0YSBpcyBOb25lOgogICAgICAgIHJldHVybiBlbnRyYWRhcwog
REM ICAgbGVpdG9yID0gY3N2LnJlYWRlcihkYXRhLnNwbGl0bGluZXMoKSwgZGVsaW1pdGVyPSJc
REM dCIsIHF1b3RlY2hhcj0nIicpCiAgICB0cnk6CiAgICAgICAgY2FiID0gbmV4dChsZWl0b3Ip
REM CiAgICBleGNlcHQgU3RvcEl0ZXJhdGlvbjoKICAgICAgICByZXR1cm4gZW50cmFkYXMKICAg
REM IGlkeCA9IHtzdHIodikuc3RyaXAoKS5sb3dlcigpOiBpIGZvciBpLCB2IGluIGVudW1lcmF0
REM ZShjYWIpfQogICAgaV9maWxlID0gaWR4LmdldCgiZmlsZW5hbWUiLCAzKQogICAgaV9saW5l
REM ID0gaWR4LmdldCgibGluZSBudW1iZXIiLCA0KQogICAgaV90ZXh0ID0gaWR4LmdldCgiZGlh
REM bG9ndWUiLCAyKQogICAgaV9jaGFyID0gaWR4LmdldCgiY2hhcmFjdGVyIiwgMSkKICAgIGlf
REM aWQgPSBpZHguZ2V0KCJpZGVudGlmaWVyIiwgMCkKICAgIGZvciByb3cgaW4gbGVpdG9yOgog
REM ICAgICAgIGlmIG5vdCByb3c6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgaWYgbWF4
REM KGlfZmlsZSwgaV9saW5lLCBpX3RleHQsIGlfY2hhciwgaV9pZCkgPj0gbGVuKHJvdyk6CiAg
REM ICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgdHJ5OgogICAgICAgICAgICBsaW5oYSA9IGlu
REM dChyb3dbaV9saW5lXSkKICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICBj
REM b250aW51ZQogICAgICAgIHRleHRvID0gX2V4dHJhaXJfY2FtcG9fbmF0aXZvKHJvd1tpX3Rl
REM eHRdKQogICAgICAgIGFycXVpdm8gPSBfbm9ybWFsaXphcl9yZWxfcmVucHkocm93W2lfZmls
REM ZV0pCiAgICAgICAgaWYgbm90IGFycXVpdm8gb3Igbm90IHRleHRvOgogICAgICAgICAgICBj
REM b250aW51ZQogICAgICAgIGVudHJhZGFzLmFwcGVuZCh7CiAgICAgICAgICAgICJhcnF1aXZv
REM IjogYXJxdWl2bywKICAgICAgICAgICAgImxpbmhhIjogbGluaGEsCiAgICAgICAgICAgICJ0
REM ZXh0byI6IHRleHRvLAogICAgICAgICAgICAicGVyc29uYWdlbSI6IF9leHRyYWlyX2NhbXBv
REM X25hdGl2byhyb3dbaV9jaGFyXSksCiAgICAgICAgICAgICJpZGVudGlmaWNhZG9yIjogX2V4
REM dHJhaXJfY2FtcG9fbmF0aXZvKHJvd1tpX2lkXSksCiAgICAgICAgfSkKICAgIHJldHVybiBl
REM bnRyYWRhcwoKCmRlZiBfY29waWFyX2dhbWVfcGFyYV9vcmFjdWxvKHBhc3RhX2dhbWUsIGRl
REM c3Rpbm8pOgogICAgIiIiTW9udGEgdW1hIGPDs3BpYSBtw61uaW1hIGUgaXNvbGFkYSBkbyBj
REM w7NkaWdvLWZvbnRlIFJlbidQeSBwYXJhIG8gb3LDoWN1bG8uCgogICAgQ29waWEgYXBlbmFz
REM IHNjcmlwdHMtZm9udGUgKC5ycHksIC5ycHltIGUgKl9yZW4ucHkpLiBOw6NvIGNvcGlhIGxp
REM Yi8sIFJQQSwKICAgIGltYWdlbnMsIMOhdWRpbywgZXhlY3V0w6F2ZWlzIG91IHJlY3Vyc29z
REM IGV4dGVybm9zOiBlc3NhIGV0YXBhIHNlcnZlIHBhcmEKICAgIHZhbGlkYcOnw6NvIHNlbcOi
REM bnRpY2EgZG9zIHNjcmlwdHMsIG7Do28gcGFyYSBtb250YXIgdW1hIGPDs3BpYSBleGVjdXTD
REM oXZlbCBkbyBtb2QuCiAgICBTZSB1bSBwcm9qZXRvIHByZWNpc2FyIGRlIHJlY3Vyc29zIHBh
REM cmEgaW5pY2lhbGl6YXIgbyBvcsOhY3VsbywgYSBmYWxoYSBmaWNhCiAgICByZWdpc3RyYWRh
REM IGUgbyBleHRyYXRvciBwcsOzcHJpbyBjb250aW51YSBlbSBtb2RvIHNlbSB2YWxpZGHDp8Oj
REM by4KICAgICIiIgogICAgZGVzdGlubyA9IG9zLnBhdGguYWJzcGF0aChkZXN0aW5vKQogICAg
REM ZGVzdGlub19nYW1lID0gb3MucGF0aC5qb2luKGRlc3Rpbm8sICJnYW1lIikKICAgIG9zLm1h
REM a2VkaXJzKGRlc3Rpbm9fZ2FtZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIGlnbm9yYXJfZGlycyA9
REM IHsKICAgICAgICAiLmdpdCIsICJfX3B5Y2FjaGVfXyIsICJjYWNoZSIsICJ0bXAiLCAidGVt
REM cCIsICJsaWIiLCAicmVucHkiLAogICAgICAgICJkZGFjLXNkayIsICJkZGFjLXJhc2N1bmhv
REM IiwgImRkYWMtZGVwZW5kZW5jaWEiLAogICAgfQogICAgZXh0ZW5zb2VzX3NjcmlwdCA9ICgi
REM LnJweSIsICIucnB5bSIpCiAgICBwcmVmaXhvc19pZ25vcmFkb3MgPSAoInVucmVuLWRkYWMi
REM LCAiZGRhYy1kdWFsIiwgImRkYWMtZGnDoWxvZ29zIiwgImRkYWMtZGlhbG9nb3MiKQogICAg
REM Y29waWFkb3MgPSAwCiAgICBmb3IgcmFpel9hdHVhbCwgZGlycywgYXJxdWl2b3MgaW4gb3Mu
REM d2FsayhwYXN0YV9nYW1lKToKICAgICAgICBkaXJzWzpdID0gW2QgZm9yIGQgaW4gZGlycyBp
REM ZiBkLmxvd2VyKCkgbm90IGluIGlnbm9yYXJfZGlycyBhbmQKICAgICAgICAgICAgICAgICAg
REM IG5vdCBhbnkoZC5sb3dlcigpLnN0YXJ0c3dpdGgocCkgZm9yIHAgaW4gcHJlZml4b3NfaWdu
REM b3JhZG9zKV0KICAgICAgICByZWxhdGl2b19kaXIgPSBvcy5wYXRoLnJlbHBhdGgocmFpel9h
REM dHVhbCwgcGFzdGFfZ2FtZSkKICAgICAgICBpZiByZWxhdGl2b19kaXIgPT0gIi4iOgogICAg
REM ICAgICAgICByZWxhdGl2b19kaXIgPSAiIgogICAgICAgIGZvciBub21lIGluIGFycXVpdm9z
REM OgogICAgICAgICAgICBsb3cgPSBub21lLmxvd2VyKCkKICAgICAgICAgICAgaWYgbm90IChs
REM b3cuZW5kc3dpdGgoZXh0ZW5zb2VzX3NjcmlwdCkgb3IgbG93LmVuZHN3aXRoKCJfcmVuLnB5
REM IikpOgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgaWYgYW55KGxvdy5z
REM dGFydHN3aXRoKHApIGZvciBwIGluIHByZWZpeG9zX2lnbm9yYWRvcyk6CiAgICAgICAgICAg
REM ICAgICBjb250aW51ZQogICAgICAgICAgICBvcmlnZW0gPSBvcy5wYXRoLmpvaW4ocmFpel9h
REM dHVhbCwgbm9tZSkKICAgICAgICAgICAgc3ViZGVzdGlubyA9IG9zLnBhdGguam9pbihkZXN0
REM aW5vX2dhbWUsIHJlbGF0aXZvX2RpcikgaWYgcmVsYXRpdm9fZGlyIGVsc2UgZGVzdGlub19n
REM YW1lCiAgICAgICAgICAgIG9zLm1ha2VkaXJzKHN1YmRlc3Rpbm8sIGV4aXN0X29rPVRydWUp
REM CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHNodXRpbC5jb3B5MihvcmlnZW0s
REM IG9zLnBhdGguam9pbihzdWJkZXN0aW5vLCBub21lKSkKICAgICAgICAgICAgICAgIGNvcGlh
REM ZG9zICs9IDEKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6CiAgICAgICAg
REM ICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgcHJpbnQodSIgIE9yw6FjdWxvIFJl
REM bidQeTogZmFsaGEgYW8gY29waWFyIHNjcmlwdCAne30nOiB7fSIuZm9ybWF0KAogICAgICAg
REM ICAgICAgICAgICAgICAgICBvcy5wYXRoLmpvaW4ocmVsYXRpdm9fZGlyLCBub21lKSwgZXhj
REM KSwgZmx1c2g9VHJ1ZSkKICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAg
REM ICAgICAgICAgICAgICAgcGFzcwogICAgaWYgY29waWFkb3MgPT0gMDoKICAgICAgICByYWlz
REM ZSBSdW50aW1lRXJyb3IodSJOZW5odW0gc2NyaXB0LWZvbnRlIFJlbidQeSAoLnJweS8ucnB5
REM bS8qX3Jlbi5weSkgcMO0ZGUgc2VyIGNvcGlhZG8gcGFyYSBvIG9yw6FjdWxvLiIpCiAgICBy
REM ZXR1cm4gZGVzdGlub19nYW1lCgoKZGVmIF9jYW5kaWRhdG9zX3N0cmluZ19saW5oYShsaW5o
REM YV90ZXh0bywgYWx2byk6CiAgICBlbmNvbnRyYWRvcyA9IFtdCiAgICB2aXN0b3MgPSBzZXQo
REM KQogICAgZm9yIG0gaW4gcmUuZmluZGl0ZXIoUVNUUiwgbGluaGFfdGV4dG8pOgogICAgICAg
REM IHEgPSBtLmdyb3VwKDApCiAgICAgICAgdHJ5OgogICAgICAgICAgICBkZWMgPSBkZWNvZGlm
REM aWNhcl9saXRlcmFsX3RyYWR1Y2FvKHEpCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
REM ICAgICAgICAgZGVjID0gc3RyaXBfcXVvdGVzKHEpCiAgICAgICAgaWYgZGVjID09IGFsdm86
REM CiAgICAgICAgICAgIGNoYXZlPShtLnN0YXJ0KCksbS5lbmQoKSkKICAgICAgICAgICAgaWYg
REM Y2hhdmUgbm90IGluIHZpc3RvczoKICAgICAgICAgICAgICAgIHZpc3Rvcy5hZGQoY2hhdmUp
REM OyBlbmNvbnRyYWRvcy5hcHBlbmQoKG0uc3RhcnQoKSwgbS5lbmQoKSwgcSkpCiAgICBmb3Ig
REM aW5pY2lvLCBmaW0sIHEsIF9yYXcgaW4gaXRlcl9yZW5weV9saXRlcmFpc19lc3BlY2lhaXMo
REM bGluaGFfdGV4dG8pOgogICAgICAgIHRyeToKICAgICAgICAgICAgZGVjID0gZGVjb2RpZmlj
REM YXJfbGl0ZXJhbF90cmFkdWNhbyhxKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAg
REM ICAgICAgIGRlYyA9IHN0cmlwX3F1b3RlcyhxKQogICAgICAgIGlmIGRlYyA9PSBhbHZvOgog
REM ICAgICAgICAgICBjaGF2ZT0oaW5pY2lvLGZpbSkKICAgICAgICAgICAgaWYgY2hhdmUgbm90
REM IGluIHZpc3RvczoKICAgICAgICAgICAgICAgIHZpc3Rvcy5hZGQoY2hhdmUpOyBlbmNvbnRy
REM YWRvcy5hcHBlbmQoKGluaWNpbyxmaW0scSkpCiAgICBlbmNvbnRyYWRvcy5zb3J0KGtleT1s
REM YW1iZGEgeDp4WzBdKQogICAgcmV0dXJuIGVuY29udHJhZG9zCgoKZGVmIF9mYW1pbGlhX3B5
REM dGhvbl9zZGsoc2RrLCBweXRob25fc2RrLCB2ZXJzYW9fY2xpPXUiIik6CiAgICAiIiJJZGVu
REM dGlmaWNhIGEgZmFtw61saWEgcmVhbCBkbyBpbnRlcnByZXRhZG9yIGRvIFNESyAoMiBvdSAz
REM KS4iIiIKICAgIGNhbWluaG8gPSBvcy5wYXRoLm5vcm1jYXNlKG9zLnBhdGguYWJzcGF0aChw
REM eXRob25fc2RrKSkucmVwbGFjZSgiXFwiLCAiLyIpCiAgICBwYXJ0ZXMgPSBjYW1pbmhvLnNw
REM bGl0KCIvIikKICAgIHRleHRvID0gIi8iLmpvaW4ocGFydGVzKQogICAgaWYgYW55KCgicHkz
REM LSIgaW4gcCBvciBwLnN0YXJ0c3dpdGgoInB5M18iKSBvciBwID09ICJweTMiKSBmb3IgcCBp
REM biBwYXJ0ZXMpOgogICAgICAgIHJldHVybiAzCiAgICBpZiBhbnkoKCJweTItIiBpbiBwIG9y
REM IHAuc3RhcnRzd2l0aCgicHkyXyIpIG9yIHAgPT0gInB5MiIpIGZvciBwIGluIHBhcnRlcyk6
REM CiAgICAgICAgcmV0dXJuIDIKICAgICMgRmFsbGJhY2sgZ2xvYmFsIHBvciBnZXJhw6fDo28g
REM ZG8gUmVuJ1B5OiBSZW4nUHkgOCB1c2EgUHl0aG9uIDM7IFJlbidQeSA2LzcKICAgICMgdXNh
REM bSBQeXRob24gMiBuYXMgZmFtw61saWFzIHN1cG9ydGFkYXMgcGVsbyBEREFDLgogICAgbnVt
REM cyA9IF92ZXJzYW9fbnVtZXJpY2EodmVyc2FvX2NsaSBvciB1IiIpCiAgICBpZiBudW1zIGFu
REM ZCBudW1zWzBdID49IDg6CiAgICAgICAgcmV0dXJuIDMKICAgIGlmIG51bXMgYW5kIG51bXNb
REM MF0gaW4gKDYsIDcpOgogICAgICAgIHJldHVybiAyCiAgICByZXR1cm4gMAoKCmRlZiBfYW1i
REM aWVudGVfcHl0aG9uX3NkayhzZGssIHB5dGhvbl9zZGssIHZlcnNhb19jbGk9dSIiKToKICAg
REM ICIiIlByZXBhcmEgbyBhbWJpZW50ZSBkbyBQeXRob24gZW1idXRpZG8gc2VtIHF1ZWJyYXIg
REM U0RLcyBtb2Rlcm5vcy4KCiAgICBSZW4nUHkgNi83IGxlZ2FkbyBwb2RlIGRlcGVuZGVyIGV4
REM cGxpY2l0YW1lbnRlIGRlIFBZVEhPTkhPTUUvUFlUSE9OUEFUSC4KICAgIFJlbidQeSA4IG1v
REM ZGVybm8gdXNhIHVtIFB5dGhvbiAzIGVtYnV0aWRvIGUgcG9kZSBjYXJyZWdhciBgYHNpdGVg
REM YCBjb21vCiAgICBtw7NkdWxvIGNvbmdlbGFkby9lbWJ1dGlkbzsgbmVzc2UgY2FzbyBuw6Nv
REM IHNlIGRldmUgaW1wb3IgdW1hIHBhc3RhIGBgTGliYGAKICAgIGFydGlmaWNpYWwuCiAgICAi
REM IiIKICAgIGVudiA9IG9zLmVudmlyb24uY29weSgpCiAgICBlbnYucG9wKCJQWVRIT05VU0VS
REM QkFTRSIsIE5vbmUpCiAgICBlbnYucG9wKCJQWVRIT05OT1VTRVJTSVRFIiwgTm9uZSkKICAg
REM IHB5dGhvbl9ob21lID0gb3MucGF0aC5kaXJuYW1lKG9zLnBhdGguYWJzcGF0aChweXRob25f
REM c2RrKSkKICAgIGxpYl9kaXIgPSBvcy5wYXRoLmpvaW4ocHl0aG9uX2hvbWUsICJMaWIiKQog
REM ICAgZmFtaWxpYSA9IF9mYW1pbGlhX3B5dGhvbl9zZGsoc2RrLCBweXRob25fc2RrLCB2ZXJz
REM YW9fY2xpKQoKICAgIGlmIGZhbWlsaWEgPT0gMjoKICAgICAgICBlbnZbIlBZVEhPTkhPTUUi
REM XSA9IHB5dGhvbl9ob21lCiAgICAgICAgZW52WyJQWVRIT05QQVRIIl0gPSBsaWJfZGlyCiAg
REM ICAgICAgcmV0dXJuIGVudgoKICAgICMgUHl0aG9uIDMgbW9kZXJubzogY29uZmlhciBubyBh
REM bWJpZW50ZSBwcsOzcHJpbyBkbyBTREsuCiAgICBlbnYucG9wKCJQWVRIT05IT01FIiwgTm9u
REM ZSkKICAgIGVudi5wb3AoIlBZVEhPTlBBVEgiLCBOb25lKQogICAgZW52WyJQWVRIT05OT1VT
REM RVJTSVRFIl0gPSAiMSIKICAgIHJldHVybiBlbnYKCgpkZWYgX2ZsYWdzX3B5dGhvbl9zZGso
REM cHlfZGlhZyk6CiAgICAiIiJVc2EgLU8gc29tZW50ZSBxdWFuZG8gYSBpbnN0YWxhw6fDo28g
REM ZGVwZW5kZSBkZSBhcnF1aXZvcyAucHlvLiIiIgogICAgaWYgcHlfZGlhZy5nZXQoInNpdGVf
REM cHlvIikgYW5kIG5vdCBweV9kaWFnLmdldCgic2l0ZV9weSIpIGFuZCBub3QgcHlfZGlhZy5n
REM ZXQoInNpdGVfcHljIik6CiAgICAgICAgcmV0dXJuIFsiLU8iXQogICAgcmV0dXJuIFtdCgoK
REM ZGVmIF9kaWFnbm9zdGljb19weXRob25fc2RrKHNkaywgcHl0aG9uX3Nkayk6CiAgICAiIiJS
REM ZXRvcm5hIGRhZG9zIG9iamV0aXZvcyBzb2JyZSBhIGluc3RhbGHDp8OjbyBkbyBQeXRob24g
REM ZG8gU0RLLiIiIgogICAgcmFpel9weXRob24gPSBvcy5wYXRoLmRpcm5hbWUob3MucGF0aC5h
REM YnNwYXRoKHB5dGhvbl9zZGspKQogICAgbGliX2RpciA9IG9zLnBhdGguam9pbihyYWl6X3B5
REM dGhvbiwgIkxpYiIpCiAgICByZXR1cm4gewogICAgICAgICJweXRob25fZGlyIjogcmFpel9w
REM eXRob24sCiAgICAgICAgImxpYl9kaXIiOiBsaWJfZGlyLAogICAgICAgICJsaWJfZXhpc3Rl
REM Ijogb3MucGF0aC5pc2RpcihsaWJfZGlyKSwKICAgICAgICAic2l0ZV9weSI6IG9zLnBhdGgu
REM aXNmaWxlKG9zLnBhdGguam9pbihsaWJfZGlyLCAic2l0ZS5weSIpKSwKICAgICAgICAic2l0
REM ZV9weWMiOiBvcy5wYXRoLmlzZmlsZShvcy5wYXRoLmpvaW4obGliX2RpciwgInNpdGUucHlj
REM IikpLAogICAgICAgICJzaXRlX3B5byI6IG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9pbihs
REM aWJfZGlyLCAic2l0ZS5weW8iKSksCiAgICAgICAgInB5dGhvbl9kbGxfMjciOiBvcy5wYXRo
REM LmlzZmlsZShvcy5wYXRoLmpvaW4ocmFpel9weXRob24sICJweXRob24yNy5kbGwiKSksCiAg
REM ICAgICAgImxpYnB5dGhvbl9kbGwiOiBvcy5wYXRoLmlzZmlsZShvcy5wYXRoLmpvaW4ocmFp
REM el9weXRob24sICJsaWJweXRob24yLjcuZGxsIikpLAogICAgICAgICJzZGsiOiBzZGssCiAg
REM ICB9CgoKZGVmIF9jbGFzc2lmaWNhcl9mYWxoYV9vcmFjdWxvX3B5dGhvbihtc2cpOgogICAg
REM IiIiQ2xhc3NpZmljYSBmYWxoYXMgZGUgYW1iaWVudGUgcG9yIGNhdXNhIGdsb2JhbCByZXV0
REM aWxpesOhdmVsLiIiIgogICAgYmFpeG8gPSB0ZXh0b19jb21wYXRpdmVsKG1zZywgdSIiKS5s
REM b3dlcigpCiAgICBpZiAic2l0ZS5fX2ZpbGVfXyIgaW4gYmFpeG8gb3IgIm1vZHVsZSAnc2l0
REM ZScgaGFzIG5vIGF0dHJpYnV0ZSAnX19maWxlX18nIiBpbiBiYWl4bzoKICAgICAgICByZXR1
REM cm4gdSJQWTNfU0lURV9GSUxFX09QQ0lPTkFMIgogICAgaWYgIm5vIG1vZHVsZSBuYW1lZCBz
REM aXRlIiBpbiBiYWl4bzoKICAgICAgICByZXR1cm4gdSJQWV9MRUdBQ1lfU0lURV9NSVNTSU5H
REM IgogICAgaWYgInB5dGhvbiBzbW9rZS10ZXN0IiBpbiBiYWl4byBhbmQgInJldG9ybm91IiBp
REM biBiYWl4bzoKICAgICAgICByZXR1cm4gdSJQWVRIT05fRU1CRURERURfU01PS0VURVNUIgog
REM ICAgaWYgInRvbyBmZXcgYXJndW1lbnRzIiBpbiBiYWl4byBvciAoInJlbnB5LnB5IiBpbiBi
REM YWl4byBhbmQgImRpYWxvZ3VlIiBpbiBiYWl4byBhbmQgImFyZ3VtZW50IiBpbiBiYWl4byk6
REM CiAgICAgICAgcmV0dXJuIHUiUkVOUFlfRElBTE9HVUVfU0lHTkFUVVJFIgogICAgcmV0dXJu
REM IHUiUkVOUFlfT1JBQ0xFX0dFTkVSSUMiCgoKZGVmIF9wcmVwYXJhcl9vcmFjdWxvX3JlbnB5
REM KHBhc3RhX2dhbWUsIGNhbmRpZGF0b3MsIGxvZyk6CiAgICAiIiJFeGVjdXRhIG8gRGlhbG9n
REM dWUvU3RyaW5ncyBuYXRpdm8gZG8gU0RLIGNvbXBhdMOtdmVsLCBzZW1wcmUgZW0gY8OzcGlh
REM LgoKICAgIFYxMDMgdHJhdGEgbyBTREsgcHJlcGFyYWRvIHBlbG8gQkFUIGNvbW8gdW1hIGRl
REM cGVuZMOqbmNpYSBleHBsw61jaXRhLiBBIHJvdGluYQogICAgbsOjbyBkZXBlbmRlIGFwZW5h
REM cyBkZSBhdXRvZGlzY292ZXJ5OiBvIGNhbWluaG8gRERBQ19SRU5QWV9TREsgw6kgdGVzdGFk
REM byBwcmltZWlybywKICAgIGNvbSBkaWFnbsOzc3RpY28gY29tcGxldG8gZGUgUHl0aG9uLCBy
REM ZW5weS5weSwgdmVyc8OjbyBlIGV4ZWN1w6fDo28gZG8gQ0xJLgogICAgIiIiCiAgICBmb3Ig
REM Y2hhdmUgaW4gT1JBQ1VMT19SRU5QWToKICAgICAgICBpZiBpc2luc3RhbmNlKE9SQUNVTE9f
REM UkVOUFlbY2hhdmVdLCBsaXN0KTogT1JBQ1VMT19SRU5QWVtjaGF2ZV0gPSBbXQogICAgICAg
REM IGVsaWYgaXNpbnN0YW5jZShPUkFDVUxPX1JFTlBZW2NoYXZlXSwgZGljdCk6IE9SQUNVTE9f
REM UkVOUFlbY2hhdmVdID0ge30KICAgICAgICBlbGlmIGlzaW5zdGFuY2UoT1JBQ1VMT19SRU5Q
REM WVtjaGF2ZV0sIGJvb2wpOiBPUkFDVUxPX1JFTlBZW2NoYXZlXSA9IEZhbHNlCiAgICAgICAg
REM ZWxpZiBpc2luc3RhbmNlKE9SQUNVTE9fUkVOUFlbY2hhdmVdLCBpbnQpOiBPUkFDVUxPX1JF
REM TlBZW2NoYXZlXSA9IDAKICAgICAgICBlbHNlOiBPUkFDVUxPX1JFTlBZW2NoYXZlXSA9IHUi
REM IgoKICAgIGV4cGxpY2l0ID0gb3MuZW52aXJvbi5nZXQoIkREQUNfUkVOUFlfU0RLIiwgIiIp
REM CiAgICBpZiBleHBsaWNpdDoKICAgICAgICBleHBsaWNpdCA9IG9zLnBhdGguYWJzcGF0aChv
REM cy5wYXRoLmV4cGFuZHZhcnMob3MucGF0aC5leHBhbmR1c2VyKGV4cGxpY2l0KSkpCiAgICBz
REM ZGtzID0gX3JhaXplc19jYW5kaWRhdGFzX3Nka19yZW5weShvcy5wYXRoLmRpcm5hbWUocGFz
REM dGFfZ2FtZSkpCiAgICBpZiBleHBsaWNpdCBhbmQgb3MucGF0aC5pc2RpcihleHBsaWNpdCkg
REM YW5kIG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9pbihleHBsaWNpdCwgInJlbnB5LnB5Iikp
REM OgogICAgICAgIHNka3MgPSBbZXhwbGljaXRdICsgW3ggZm9yIHggaW4gc2RrcyBpZiBvcy5w
REM YXRoLm5vcm1jYXNlKG9zLnBhdGgubm9ybXBhdGgoeCkpICE9IG9zLnBhdGgubm9ybWNhc2Uo
REM b3MucGF0aC5ub3JtcGF0aChleHBsaWNpdCkpXQoKICAgIGFsdm8sIGV2aWRlbmNpYXMgPSBf
REM ZGV0ZWN0YXJfdmVyc2FvX3Byb2pldG9fcmVucHkocGFzdGFfZ2FtZSwgY2FuZGlkYXRvcykK
REM ICAgIGFsdm9fdGV4dG8gPSAiLiIuam9pbihtYXAoc3RyLCBhbHZvKSkgaWYgYWx2byBlbHNl
REM ICJkZXNjb25oZWNpZG8iCiAgICBsb2cuaW5mbyh1IlJlbidQeSBhbHZvIGRldGVjdGFkbzog
REM e317fSIuZm9ybWF0KAogICAgICAgIGFsdm9fdGV4dG8sCiAgICAgICAgdSIgfCBldmlkw6pu
REM Y2lhOiB7fSIuZm9ybWF0KGV2aWRlbmNpYXNbMF1bMV0pIGlmIGV2aWRlbmNpYXMgZWxzZSB1
REM IiIpKQogICAgbG9nLmluZm8odSJPcsOhY3VsbyBSZW4nUHk6IHt9IGNhbmRpZGF0byhzKSBk
REM ZSBTREsgZW5jb250cmFkb3MuIi5mb3JtYXQobGVuKHNka3MpKSkKICAgIGlmIGV4cGxpY2l0
REM OgogICAgICAgIGxvZy5pbmZvKHUiT3LDoWN1bG8gUmVuJ1B5OiBEREFDX1JFTlBZX1NESyBl
REM eHBsw61jaXRvPXt9Ii5mb3JtYXQoZXhwbGljaXQpKQoKICAgIGFsdm9fc2RrID0gdHVwbGUo
REM YWx2b1s6NF0gaWYgYWx2byBhbmQgYWx2b1swXSA9PSA2IGFuZCBsZW4oYWx2bykgPj0gNCBl
REM bHNlIGFsdm9bOjNdKSBpZiBhbHZvIGVsc2UgdHVwbGUoKQogICAgZGlhZ25vc3RpY3MgPSBb
REM XQogICAgaW5mbyA9IFtdCiAgICBmb3Igc2RrIGluIHNka3M6CiAgICAgICAgcHkgPSBfbG9j
REM YWxpemFyX3B5dGhvbl9zZGsoc2RrKQogICAgICAgIHZlcnNhb19jbGkgPSBfb2J0ZXJfdmVy
REM c2FvX3NkayhweSwgc2RrKSBpZiBweSBlbHNlIHUiIgogICAgICAgIHZlcnNhb19wYXRoID0g
REM X3ZlcnNhb19wb3Jfbm9tZV9jYW1pbmhvX3NkayhzZGspCiAgICAgICAgaWRlbnRpZGFkZSA9
REM IHZlcnNhb19jbGkgb3IgdmVyc2FvX3BhdGgKICAgICAgICB2dCA9IF92ZXJzYW9fbnVtZXJp
REM Y2EoaWRlbnRpZGFkZSkKICAgICAgICBtYXRjaF9jbGkgPSBib29sKGFsdm9fc2RrIGFuZCB2
REM dCBhbmQgdHVwbGUodnRbOmxlbihhbHZvX3NkayldKSA9PSBhbHZvX3NkaykKICAgICAgICBt
REM YXRjaF9wYXRoID0gYm9vbChhbHZvX3NkayBhbmQgdmVyc2FvX3BhdGggYW5kIF92ZXJzYW9f
REM bnVtZXJpY2EodmVyc2FvX3BhdGgpWzpsZW4oYWx2b19zZGspXSA9PSBhbHZvX3NkaykKICAg
REM ICAgICB2YWxpZCA9IGJvb2wocHkgYW5kIG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9pbihz
REM ZGssICJyZW5weS5weSIpKSkKICAgICAgICBleHBsaWNpdF9tYXRjaCA9IGJvb2woZXhwbGlj
REM aXQgYW5kIG9zLnBhdGgubm9ybWNhc2Uob3MucGF0aC5ub3JtcGF0aChzZGspKSA9PSBvcy5w
REM YXRoLm5vcm1jYXNlKG9zLnBhdGgubm9ybXBhdGgoZXhwbGljaXQpKSkKICAgICAgICBkID0g
REM ewogICAgICAgICAgICAic2RrIjogc2RrLAogICAgICAgICAgICAicHl0aG9uIjogcHkgb3Ig
REM dSIiLAogICAgICAgICAgICAicmVucHlfcHkiOiBvcy5wYXRoLmlzZmlsZShvcy5wYXRoLmpv
REM aW4oc2RrLCAicmVucHkucHkiKSksCiAgICAgICAgICAgICJ2ZXJzYW9fY2xpIjogdmVyc2Fv
REM X2NsaSBvciB1IiIsCiAgICAgICAgICAgICJ2ZXJzYW9fY2FtaW5obyI6IHZlcnNhb19wYXRo
REM IG9yIHUiIiwKICAgICAgICAgICAgIm1hdGNoX2NsaSI6IG1hdGNoX2NsaSwKICAgICAgICAg
REM ICAgIm1hdGNoX2NhbWluaG8iOiBtYXRjaF9wYXRoLAogICAgICAgICAgICAiZXhwbGljaXQi
REM OiBleHBsaWNpdF9tYXRjaCwKICAgICAgICAgICAgInZhbGlkbyI6IHZhbGlkLAogICAgICAg
REM IH0KICAgICAgICBkaWFnbm9zdGljcy5hcHBlbmQoZCkKICAgICAgICBsb2cuaW5mbyh1Ik9y
REM w6FjdWxvIGNhbmRpZGF0bzoge30gfCBQeXRob249e30gfCBDTEk9e30gfCBjYW1pbmhvPXt9
REM IHwgZXhwbMOtY2l0bz17fSB8IG1hdGNoX2NsaT17fSB8IG1hdGNoX2NhbWluaG89e30iLmZv
REM cm1hdCgKICAgICAgICAgICAgc2RrLCBweSBvciB1Im7Do28gZW5jb250cmFkbyIsIHZlcnNh
REM b19jbGkgb3IgdSI/IiwgdmVyc2FvX3BhdGggb3IgdSI/IiwKICAgICAgICAgICAgdSJTSU0i
REM IGlmIGV4cGxpY2l0X21hdGNoIGVsc2UgdSJOw4NPIiwgdSJTSU0iIGlmIG1hdGNoX2NsaSBl
REM bHNlIHUiTsODTyIsCiAgICAgICAgICAgIHUiU0lNIiBpZiBtYXRjaF9wYXRoIGVsc2UgdSJO
REM w4NPIikpCiAgICAgICAgaWYgdmFsaWQ6CiAgICAgICAgICAgIGluZm8uYXBwZW5kKChzZGss
REM IHB5LCB2ZXJzYW9fY2xpLCB2dCwgdmVyc2FvX3BhdGgsIG1hdGNoX2NsaSwgbWF0Y2hfcGF0
REM aCwgZXhwbGljaXRfbWF0Y2gpKQoKICAgIE9SQUNVTE9fUkVOUFlbImNhbmRpZGF0b3MiXSA9
REM IGRpYWdub3N0aWNzCiAgICBpZiBub3QgaW5mbzoKICAgICAgICBPUkFDVUxPX1JFTlBZWyJm
REM YWxoYXMiXSA9IFt1Ik5lbmh1bSBTREsgUmVuJ1B5IGNvbXBsZXRvIGNvbSBQeXRob24gZW1i
REM dXRpZG8gZm9pIGxvY2FsaXphZG8uIl0KICAgICAgICBsb2cuZXJybyh1Ik9yw6FjdWxvIFJl
REM bidQeTogbmVuaHVtIFNESyBjb21wbGV0byBjb20gUHl0aG9uIGVtYnV0aWRvIGZvaSBsb2Nh
REM bGl6YWRvLiIpCiAgICAgICAgcmV0dXJuIHt9CgogICAgaWYgYWx2b19zZGs6CiAgICAgICAg
REM IyBSZWdyYSBvYnJpZ2F0w7NyaWEgZGEgT3DDp8OjbyAxOiBvIE9yw6FjdWxvIHVzYSBvIFNE
REM SyBleGF0byBkZXRlY3RhZG8uCiAgICAgICAgIyBBIGNvbXBhdGliaWxpZGFkZSDDqSBhbXBs
REM aWFkYSBwZWxvcyBsYXlvdXRzL2NhY2hlIGUgcGVsbyB0ZXN0ZSByZWFsIGRvCiAgICAgICAg
REM IyBQeXRob24gZW1idXRpZG8sIG7Do28gcG9yIHVtYSB0cm9jYSBzaWxlbmNpb3NhIHBhcmEg
REM b3V0cmEgdmVyc8Ojby4KICAgICAgICBjb21wYXQgPSBbeCBmb3IgeCBpbiBpbmZvIGlmIHhb
REM NV0gb3IgeFs2XV0KICAgICAgICBpZiBub3QgY29tcGF0OgogICAgICAgICAgICBtc2cgPSB1
REM IlNESyBSZW4nUHkgY29ycmVzcG9uZGVudGUgYSB7fSBuw6NvIGZvaSBsb2NhbGl6YWRvL3Zh
REM bGlkYWRvOyBleHRyYcOnw6NvIHNlZ3VpcsOhIHNlbSB2YWxpZGHDp8OjbyBwZWxvIG9yw6Fj
REM dWxvLiIuZm9ybWF0KCIuIi5qb2luKG1hcChzdHIsIGFsdm9fc2RrKSkpCiAgICAgICAgICAg
REM IE9SQUNVTE9fUkVOUFlbImZhbGhhcyJdID0gW21zZ10KICAgICAgICAgICAgbG9nLmVycm8o
REM dSJPcsOhY3VsbyBSZW4nUHk6ICIgKyBtc2cpCiAgICAgICAgICAgIHJldHVybiB7fQogICAg
REM ICAgIGluZm8gPSBjb21wYXQKCiAgICBkZWYgcHJpb3JpZGFkZShpdGVtKToKICAgICAgICBz
REM ZGssIHB5LCB2ZXJzYW9fY2xpLCB2dCwgdmVyc2FvX3BhdGgsIG1hdGNoX2NsaSwgbWF0Y2hf
REM cGF0aCwgZXhwbGljaXRfbWF0Y2ggPSBpdGVtCiAgICAgICAgcmV0dXJuICgKICAgICAgICAg
REM ICAgMCBpZiBleHBsaWNpdF9tYXRjaCBlbHNlIDEsCiAgICAgICAgICAgIDAgaWYgbWF0Y2hf
REM Y2xpIGVsc2UgKDEgaWYgbWF0Y2hfcGF0aCBlbHNlIDIpLAogICAgICAgICAgICB0dXBsZSgt
REM eCBmb3IgeCBpbiAodnQgb3IgKCkpKSwKICAgICAgICAgICAgc2RrLmxvd2VyKCksCiAgICAg
REM ICAgKQoKICAgIGluZm8uc29ydChrZXk9cHJpb3JpZGFkZSkKICAgIGZhbGhhcyA9IFtdCiAg
REM ICBmb3IgcG9zLCAoc2RrLCBweSwgdmVyc2FvX2NsaSwgdnQsIHZlcnNhb19wYXRoLCBtYXRj
REM aF9jbGksIG1hdGNoX3BhdGgsIGV4cGxpY2l0X21hdGNoKSBpbiBlbnVtZXJhdGUoaW5mb1s6
REM OF0sIDEpOgogICAgICAgIHRlbXAgPSBOb25lCiAgICAgICAgdHJ5OgogICAgICAgICAgICB2
REM ZXJzYW8gPSB2ZXJzYW9fY2xpIG9yIHZlcnNhb19wYXRoIG9yIHUiZGVzY29uaGVjaWRhIgog
REM ICAgICAgICAgICBwcmludCh1IiAgT3LDoWN1bG8gUmVuJ1B5OiB0ZXN0YW5kbyBTREsge30v
REM e30gLT4ge30gKHt9KS4uLiIuZm9ybWF0KAogICAgICAgICAgICAgICAgcG9zLCBtaW4oOCwg
REM bGVuKGluZm8pKSwgdmVyc2FvLCBzZGspLCBmbHVzaD1UcnVlKQogICAgICAgICAgICBsb2cu
REM aW5mbyh1Ik9yw6FjdWxvIFJlbidQeTogaW5pY2lhbmRvIGNhbmRpZGF0byB7fSB8IHNkaz17
REM fSB8IHB5dGhvbj17fSB8IHZlcnPDo289e30iLmZvcm1hdChwb3MsIHNkaywgcHksIHZlcnNh
REM bykpCgogICAgICAgICAgICAjIFNtb2tlIHRlc3QgZG8gZXhlY3V0w6F2ZWwgZG8gU0RLIGFu
REM dGVzIGRlIGNvcGlhciBvIGpvZ28uCiAgICAgICAgICAgICMgUmVuJ1B5IDYvNyB1c2EgdW0g
REM UHl0aG9uIGFudGlnbyBpbnN0YWxhZG8gZGVudHJvIGRlIGxpYi88cGxhdGFmb3JtYT4uCiAg
REM ICAgICAgICAgICMgRm9yw6dhbW9zIFBZVEhPTkhPTUUvUFlUSE9OUEFUSCBwYXJhIGEgaW5z
REM dGFsYcOnw6NvIGFkamFjZW50ZSBhbwogICAgICAgICAgICAjIHB5dGhvbi5leGUsIGV2aXRh
REM bmRvIG8gSW1wb3J0RXJyb3IgIk5vIG1vZHVsZSBuYW1lZCBzaXRlIiBxdWFuZG8KICAgICAg
REM ICAgICAgIyBvIFdpbmRvd3MvdXN1w6FyaW8gcG9zc3VpIG91dHJhIGluc3RhbGHDp8OjbyBQ
REM eXRob24gb3UgcXVhbmRvIG8KICAgICAgICAgICAgIyBpbnRlcnByZXRhZG9yIGxlZ2FkbyBu
REM w6NvIGNvbnNlZ3VlIGNhbGN1bGFyIG8gcHJlZml4byBzb3ppbmhvLgogICAgICAgICAgICBw
REM eV9lbnYgPSBfYW1iaWVudGVfcHl0aG9uX3NkayhzZGssIHB5LCB2ZXJzYW9fY2xpIG9yIHZl
REM cnNhb19wYXRoIG9yIHUiIikKICAgICAgICAgICAgcHlfZGlhZyA9IF9kaWFnbm9zdGljb19w
REM eXRob25fc2RrKHNkaywgcHkpCiAgICAgICAgICAgIHB5X2ZsYWdzID0gX2ZsYWdzX3B5dGhv
REM bl9zZGsocHlfZGlhZykKICAgICAgICAgICAgZmFtaWxpYV9weXRob24gPSBfZmFtaWxpYV9w
REM eXRob25fc2RrKHNkaywgcHksIHZlcnNhb19jbGkgb3IgdmVyc2FvX3BhdGggb3IgdSIiKQog
REM ICAgICAgICAgICBweV9tb2Rlcm5vID0gZmFtaWxpYV9weXRob24gPT0gMwogICAgICAgICAg
REM ICBsb2cuaW5mbyh1Ik9yw6FjdWxvIFJlbidQeTogYW1iaWVudGUgUHl0aG9uIHwgZmFtw61s
REM aWE9e30gfCBQWVRIT05IT01FPXt9IHwgUFlUSE9OUEFUSD17fSB8IExpYj17fSB8IHNpdGUu
REM cHk9e30gfCBzaXRlLnB5Yz17fSB8IHNpdGUucHlvPXt9IHwgc2l0ZS5fX2ZpbGVfXyDDqSBv
REM cGNpb25hbD1TSU0iLmZvcm1hdCgKICAgICAgICAgICAgICAgIHUiUHl0aG9uIDMgbW9kZXJu
REM byIgaWYgcHlfbW9kZXJubyBlbHNlIHUiUHl0aG9uIDIvbGVnYWRvIiwKICAgICAgICAgICAg
REM ICAgIHB5X2Vudi5nZXQoIlBZVEhPTkhPTUUiLCB1Ijxuw6NvIGltcG9zdG8+IiksIHB5X2Vu
REM di5nZXQoIlBZVEhPTlBBVEgiLCB1Ijxuw6NvIGltcG9zdG8+IiksCiAgICAgICAgICAgICAg
REM ICB1IlNJTSIgaWYgcHlfZGlhZ1sibGliX2V4aXN0ZSJdIGVsc2UgdSJOw4NPIiwKICAgICAg
REM ICAgICAgICAgIHUiU0lNIiBpZiBweV9kaWFnWyJzaXRlX3B5Il0gZWxzZSB1Ik7Dg08iLAog
REM ICAgICAgICAgICAgICAgdSJTSU0iIGlmIHB5X2RpYWdbInNpdGVfcHljIl0gZWxzZSB1Ik7D
REM g08iLAogICAgICAgICAgICAgICAgdSJTSU0iIGlmIHB5X2RpYWdbInNpdGVfcHlvIl0gZWxz
REM ZSB1Ik7Dg08iKSkKICAgICAgICAgICAgbG9nLmluZm8odSJPcsOhY3VsbyBSZW4nUHk6IGZs
REM YWdzIFB5dGhvbj17fSIuZm9ybWF0KHUiICIuam9pbihweV9mbGFncykgaWYgcHlfZmxhZ3Mg
REM ZWxzZSB1IihuZW5odW1hKSIpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBj
REM cF9wcm9iZSA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAgICAgICAgICAgIFtweV0gKyBw
REM eV9mbGFncyArIFsiLWMiLCAiaW1wb3J0IHN5cyxzaXRlOyBwcmludChzeXMudmVyc2lvbik7
REM IHByaW50KHN5cy5wcmVmaXgpOyBwcmludChnZXRhdHRyKHNpdGUsICdfX2ZpbGVfXycsICc8
REM YnVpbHQtaW4tb3ItZnJvemVuPicpKTsgcHJpbnQoc3lzLmZsYWdzLm9wdGltaXplKTsgcHJp
REM bnQoJ3JlbnB5X3B5PScgKyBzdHIoYm9vbChfX2ltcG9ydF9fKCdvcycpLnBhdGguaXNmaWxl
REM KCdyZW5weS5weScpKSkpIl0sCiAgICAgICAgICAgICAgICAgICAgY3dkPXNkaywgZW52PXB5
REM X2Vudiwgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1YnByb2Nlc3MuU1RET1VU
REM LAogICAgICAgICAgICAgICAgICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9InV0Zi04IiwgZXJy
REM b3JzPSJyZXBsYWNlIiwgdGltZW91dD00NQogICAgICAgICAgICAgICAgKQogICAgICAgICAg
REM ICAgICAgcHJvYmUgPSAoY3BfcHJvYmUuc3Rkb3V0IG9yIHUiIikuc3RyaXAoKS5yZXBsYWNl
REM KHUiXG4iLCB1IiB8ICIpCiAgICAgICAgICAgICAgICBsb2cuaW5mbyh1Ik9yw6FjdWxvIFJl
REM bidQeTogUHl0aG9uIHNtb2tlLXRlc3QgY8OzZGlnbz17fSB8IHNhw61kYT17fSIuZm9ybWF0
REM KGNwX3Byb2JlLnJldHVybmNvZGUsIHByb2JlWy04MDA6XSBvciB1Ijx2YXppbz4iKSkKICAg
REM ICAgICAgICAgICAgIGlmIGNwX3Byb2JlLnJldHVybmNvZGUgPT0gMCBhbmQgdSI8YnVpbHQt
REM aW4tb3ItZnJvemVuPiIgaW4gcHJvYmU6CiAgICAgICAgICAgICAgICAgICAgbG9nLmluZm8o
REM dSJPcsOhY3VsbyBSZW4nUHk6IG3Ds2R1bG8gc2l0ZSBjYXJyZWdhZG8gc2VtIF9fZmlsZV9f
REM OyBjb21wb3J0YW1lbnRvIGFjZWl0byBwYXJhIFB5dGhvbiAzIG1vZGVybm8uIiApCiAgICAg
REM ICAgICAgICAgICBpZiBjcF9wcm9iZS5yZXR1cm5jb2RlICE9IDA6CiAgICAgICAgICAgICAg
REM ICAgICAgbXNnID0gdSJ7fTogUHl0aG9uIHNtb2tlLXRlc3QgcmV0b3Jub3Uge30gfCBMaWI9
REM e30gfCBzaXRlLnB5PXt9IHwgc2l0ZS5weWM9e30gfCBzaXRlLnB5bz17fSIuZm9ybWF0KAog
REM ICAgICAgICAgICAgICAgICAgICAgICBzZGssIGNwX3Byb2JlLnJldHVybmNvZGUsCiAgICAg
REM ICAgICAgICAgICAgICAgICAgIHUiU0lNIiBpZiBweV9kaWFnWyJsaWJfZXhpc3RlIl0gZWxz
REM ZSB1Ik7Dg08iLAogICAgICAgICAgICAgICAgICAgICAgICB1IlNJTSIgaWYgcHlfZGlhZ1si
REM c2l0ZV9weSJdIGVsc2UgdSJOw4NPIiwKICAgICAgICAgICAgICAgICAgICAgICAgdSJTSU0i
REM IGlmIHB5X2RpYWdbInNpdGVfcHljIl0gZWxzZSB1Ik7Dg08iLAogICAgICAgICAgICAgICAg
REM ICAgICAgICB1IlNJTSIgaWYgcHlfZGlhZ1sic2l0ZV9weW8iXSBlbHNlIHUiTsODTyIpCiAg
REM ICAgICAgICAgICAgICAgICAgY29kaWdvX2ZhbGhhID0gX2NsYXNzaWZpY2FyX2ZhbGhhX29y
REM YWN1bG9fcHl0aG9uKG1zZykKICAgICAgICAgICAgICAgICAgICBtc2cgPSBtc2cgKyB1IiB8
REM IGNsYXNzZV9nbG9iYWw9e30iLmZvcm1hdChjb2RpZ29fZmFsaGEpCiAgICAgICAgICAgICAg
REM ICAgICAgZmFsaGFzLmFwcGVuZChtc2cpOyBsb2cuZXJybyh1Ik9yw6FjdWxvIFJlbidQeTog
REM IiArIG1zZyk7IGNvbnRpbnVlCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhj
REM OgogICAgICAgICAgICAgICAgbXNnID0gdSJ7fTogUHl0aG9uIHNtb2tlLXRlc3QgZmFsaG91
REM OiB7fSIuZm9ybWF0KHNkaywgZXhjKQogICAgICAgICAgICAgICAgZmFsaGFzLmFwcGVuZCht
REM c2cpOyBsb2cuZXJybyh1Ik9yw6FjdWxvIFJlbidQeTogIiArIG1zZyk7IGNvbnRpbnVlCgog
REM ICAgICAgICAgICB0ZW1wID0gdGVtcGZpbGUubWtkdGVtcChwcmVmaXg9ImRkYWNfcmVucHlf
REM b3JhY2xlXyIpCiAgICAgICAgICAgIF9jb3BpYXJfZ2FtZV9wYXJhX29yYWN1bG8ocGFzdGFf
REM Z2FtZSwgdGVtcCkKICAgICAgICAgICAgZXh0ZXJuYWxfY2hhciA9IG9zLnBhdGguam9pbih0
REM ZW1wLCAiY2hhcmFjdGVycyIsICJtb25pa2EuY2hyIikKICAgICAgICAgICAgbG9nLmluZm8o
REM dSJPcsOhY3VsbyBSZW4nUHk6IHByb2pldG8gaXNvbGFkbyBwcmVwYXJhZG8gfCBjaGFyYWN0
REM ZXJzL21vbmlrYS5jaHI9e30iLmZvcm1hdCh1IlNJTSIgaWYgb3MucGF0aC5pc2ZpbGUoZXh0
REM ZXJuYWxfY2hhcikgZWxzZSB1Ik7Dg08iKSkKICAgICAgICAgICAgaWYgbm90IG9zLnBhdGgu
REM aXNmaWxlKGV4dGVybmFsX2NoYXIpOgogICAgICAgICAgICAgICAgbG9nLmF2aXNvKHUiT3LD
REM oWN1bG8gUmVuJ1B5OiBvIHByb2pldG8gaXNvbGFkbyBuw6NvIGNvbnTDqW0gY2hhcmFjdGVy
REM cy9tb25pa2EuY2hyOyBpbml0IGRvIGpvZ28gcG9kZSBmYWxoYXIgYW8gZXhlY3V0YXIgcmVu
REM cHkuZmlsZSgpLiIpCiAgICAgICAgICAgIGNtZF9kaWFsb2d1ZSA9IFtweV0gKyBweV9mbGFn
REM cyArIFsicmVucHkucHkiLCB0ZW1wLCAiZGlhbG9ndWUiXQogICAgICAgICAgICAjIFJlbidQ
REM eSA3LzggZXhpZ2VtIG8gYXJndW1lbnRvIGRlIGlkaW9tYSBubyBjb21hbmRvIERpYWxvZ3Vl
REM LgogICAgICAgICAgICAjIE5vbmUgcmVwcmVzZW50YSBvIGlkaW9tYSBwcmltw6FyaW8vb3Jp
REM Z2luYWwgZG8gcHJvamV0bzsgUmVuJ1B5IDYgbWFudMOpbSBhIGNoYW1hZGEgbGVnYWRhIHF1
REM ZSBqw6EgZm9pIHZhbGlkYWRhIG5hIFYxMTguCiAgICAgICAgICAgIGlmIF92ZXJzYW9fbnVt
REM ZXJpY2EodmVyc2FvKSBhbmQgX3ZlcnNhb19udW1lcmljYSh2ZXJzYW8pWzBdID49IDc6CiAg
REM ICAgICAgICAgICAgICBjbWRfZGlhbG9ndWUuYXBwZW5kKCJOb25lIikKICAgICAgICAgICAg
REM Y21kX2RpYWxvZ3VlICs9IFsiLS1zdHJpbmdzIiwgIi0tZXNjYXBlIl0KICAgICAgICAgICAg
REM bG9nLmluZm8odSJPcsOhY3VsbyBSZW4nUHk6IGV4ZWN1dGFuZG8gRGlhbG9ndWUgKyBTdHJp
REM bmdzOiB7fSIuZm9ybWF0KHUiICIuam9pbihjbWRfZGlhbG9ndWUpKSkKICAgICAgICAgICAg
REM cHJpbnQodSIgIEVUQVBBIDMvMTQgLSBPcsOhY3VsbyBSZW4nUHk6IGV4ZWN1dGFuZG8gRGlh
REM bG9ndWUgKyBTdHJpbmdzLi4uIi5mb3JtYXQoKSwgZmx1c2g9VHJ1ZSkKICAgICAgICAgICAg
REM cHJpbnQodSIgIChvIFNESyBlc3TDoSBwcm9jZXNzYW5kbyBvIHByb2pldG8gaXNvbGFkbzsg
REM ZXN0YSBldGFwYSBwb2RlIGxldmFyIGFsZ3VucyBzZWd1bmRvcykiLCBmbHVzaD1UcnVlKQog
REM ICAgICAgICAgICBpbmljaW9fZGlhbG9ndWUgPSB0aW1lLnRpbWUoKQogICAgICAgICAgICBw
REM cm9jX2RpYWxvZ3VlID0gc3VicHJvY2Vzcy5Qb3BlbigKICAgICAgICAgICAgICAgIGNtZF9k
REM aWFsb2d1ZSwgY3dkPXNkaywgZW52PXB5X2Vudiwgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwg
REM c3RkZXJyPXN1YnByb2Nlc3MuU1RET1VULAogICAgICAgICAgICAgICAgdGV4dD1UcnVlLCBl
REM bmNvZGluZz0idXRmLTgiLCBlcnJvcnM9InJlcGxhY2UiLCB1bml2ZXJzYWxfbmV3bGluZXM9
REM VHJ1ZQogICAgICAgICAgICApCiAgICAgICAgICAgIGRlZiBfaGVhcnRiZWF0X29yYWN1bG8o
REM KToKICAgICAgICAgICAgICAgIHdoaWxlIHByb2NfZGlhbG9ndWUucG9sbCgpIGlzIE5vbmU6
REM CiAgICAgICAgICAgICAgICAgICAgdGltZS5zbGVlcCg1LjApCiAgICAgICAgICAgICAgICAg
REM ICAgaWYgcHJvY19kaWFsb2d1ZS5wb2xsKCkgaXMgTm9uZToKICAgICAgICAgICAgICAgICAg
REM ICAgICAgcHJpbnQodSIgIOKGsyBPcsOhY3VsbyBSZW4nUHkgYWluZGEgZXhlY3V0YW5kby4u
REM LiB7Oi4wZn1zIi5mb3JtYXQodGltZS50aW1lKCkgLSBpbmljaW9fZGlhbG9ndWUpLCBmbHVz
REM aD1UcnVlKQogICAgICAgICAgICBoZWFydGJlYXQgPSB0aHJlYWRpbmcuVGhyZWFkKHRhcmdl
REM dD1faGVhcnRiZWF0X29yYWN1bG8pCiAgICAgICAgICAgIGhlYXJ0YmVhdC5kYWVtb24gPSBU
REM cnVlCiAgICAgICAgICAgIGhlYXJ0YmVhdC5zdGFydCgpCiAgICAgICAgICAgIHRyeToKICAg
REM ICAgICAgICAgICAgIG91dCwgXyA9IHByb2NfZGlhbG9ndWUuY29tbXVuaWNhdGUodGltZW91
REM dD02MDApCiAgICAgICAgICAgICAgICByY19kaWFsb2d1ZSA9IHByb2NfZGlhbG9ndWUucmV0
REM dXJuY29kZQogICAgICAgICAgICBleGNlcHQgc3VicHJvY2Vzcy5UaW1lb3V0RXhwaXJlZDoK
REM ICAgICAgICAgICAgICAgIHByb2NfZGlhbG9ndWUua2lsbCgpCiAgICAgICAgICAgICAgICBv
REM dXQsIF8gPSBwcm9jX2RpYWxvZ3VlLmNvbW11bmljYXRlKCkKICAgICAgICAgICAgICAgIHJj
REM X2RpYWxvZ3VlID0gcHJvY19kaWFsb2d1ZS5yZXR1cm5jb2RlIGlmIHByb2NfZGlhbG9ndWUu
REM cmV0dXJuY29kZSBpcyBub3QgTm9uZSBlbHNlIDEyNAogICAgICAgICAgICBjcCA9IHR5cGUo
REM IkREQUNQcm9jZXNzUmVzdWx0IiwgKCksIHsicmV0dXJuY29kZSI6IHJjX2RpYWxvZ3VlLCAi
REM c3Rkb3V0Ijogb3V0fSkoKQogICAgICAgICAgICB0YWIgPSBvcy5wYXRoLmpvaW4odGVtcCwg
REM ImRpYWxvZ3VlLnRhYiIpCiAgICAgICAgICAgIHRhaWwgPSBbeC5zdHJpcCgpIGZvciB4IGlu
REM IG91dC5zcGxpdGxpbmVzKCkgaWYgeC5zdHJpcCgpXVstMTU6XQogICAgICAgICAgICBsb2cu
REM aW5mbyh1Ik9yw6FjdWxvIFJlbidQeTogRGlhbG9ndWUgdGVybWlub3UgY8OzZGlnbz17fSB8
REM IGRpYWxvZ3VlLnRhYj17fSB8IHNhw61kYT17fSIuZm9ybWF0KAogICAgICAgICAgICAgICAg
REM Y3AucmV0dXJuY29kZSwgdSJTSU0iIGlmIG9zLnBhdGguaXNmaWxlKHRhYikgZWxzZSB1Ik7D
REM g08iLCB1IiB8fCAiLmpvaW4odGFpbCkpKQogICAgICAgICAgICBwcmludCh1IiAgRVRBUEEg
REM My8xNCAtIERpYWxvZ3VlICsgU3RyaW5ncyBjb25jbHXDrWRvIHwgY8OzZGlnbz17fSB8IGRp
REM YWxvZ3VlLnRhYj17fSIuZm9ybWF0KAogICAgICAgICAgICAgICAgY3AucmV0dXJuY29kZSwg
REM dSJTSU0iIGlmIG9zLnBhdGguaXNmaWxlKHRhYikgZWxzZSB1Ik7Dg08iCiAgICAgICAgICAg
REM ICksIGZsdXNoPVRydWUpCiAgICAgICAgICAgIGlmIGNwLnJldHVybmNvZGUgIT0gMCBvciBu
REM b3Qgb3MucGF0aC5pc2ZpbGUodGFiKToKICAgICAgICAgICAgICAgIG1zZyA9IHUie306IERp
REM YWxvZ3VlIGPDs2RpZ289e30gfCBkaWFsb2d1ZS50YWI9e30gfCBzYcOtZGE9e30iLmZvcm1h
REM dCgKICAgICAgICAgICAgICAgICAgICBzZGssIGNwLnJldHVybmNvZGUsIHUiU0lNIiBpZiBv
REM cy5wYXRoLmlzZmlsZSh0YWIpIGVsc2UgdSJOw4NPIiwgdSIgfHwgIi5qb2luKHRhaWwpKQog
REM ICAgICAgICAgICAgICAgT1JBQ1VMT19SRU5QWVsiZmFsaGFzIl0uYXBwZW5kKG1zZykKICAg
REM ICAgICAgICAgICAgIE9SQUNVTE9fUkVOUFlbImRpYWdub3N0aWNvX3RlbXAiXSA9IHRlbXAK
REM ICAgICAgICAgICAgICAgIGZhbGhhcy5hcHBlbmQobXNnKTsgdGVtcCA9IE5vbmU7IGNvbnRp
REM bnVlCgogICAgICAgICAgICBlbnRyYWRhc19icnV0YXMgPSBfbGVyX2RpYWxvZ3VlX3RhYih0
REM YWIpCiAgICAgICAgICAgIGlmIG5vdCBlbnRyYWRhc19icnV0YXM6CiAgICAgICAgICAgICAg
REM ICBtc2cgPSB1Int9OiBkaWFsb2d1ZS50YWIgdmF6aW8gb3UgaWxlZ8OtdmVsIi5mb3JtYXQo
REM c2RrKQogICAgICAgICAgICAgICAgZmFsaGFzLmFwcGVuZChtc2cpOyBjb250aW51ZQogICAg
REM ICAgICAgICBpZ25vcmFkYXNfb3JhY3VsbyA9IFt4IGZvciB4IGluIGVudHJhZGFzX2JydXRh
REM cyBpZiBhcnF1aXZvX2dsb2JhbG1lbnRlX2lnbm9yYWRvX2V4dHJhY2FvKHguZ2V0KCJhcnF1
REM aXZvIiwgIiIpKV0KICAgICAgICAgICAgZW50cmFkYXMgPSBbeCBmb3IgeCBpbiBlbnRyYWRh
REM c19icnV0YXMgaWYgbm90IGFycXVpdm9fZ2xvYmFsbWVudGVfaWdub3JhZG9fZXh0cmFjYW8o
REM eC5nZXQoImFycXVpdm8iLCAiIikpXQogICAgICAgICAgICBPUkFDVUxPX1JFTlBZWyJuYXRp
REM dmFzX2JydXRhc190b3RhbCJdID0gbGVuKGVudHJhZGFzX2JydXRhcykKICAgICAgICAgICAg
REM T1JBQ1VMT19SRU5QWVsibmF0aXZhc19pZ25vcmFkYXNfYXJxdWl2b3NfZ2xvYmFpcyJdID0g
REM bGVuKGlnbm9yYWRhc19vcmFjdWxvKQogICAgICAgICAgICBpZiBpZ25vcmFkYXNfb3JhY3Vs
REM bzoKICAgICAgICAgICAgICAgIGxvZy5pbmZvKHUiT3LDoWN1bG8gUmVuJ1B5OiB7fSBlbnRy
REM YWRhKHMpIHJlbW92aWRhKHMpIHBlbGEgcmVncmEgZ2xvYmFsIGRlIGFycXVpdm9zIGlnbm9y
REM YWRvcy4iLmZvcm1hdChsZW4oaWdub3JhZGFzX29yYWN1bG8pKSkKCiAgICAgICAgICAgIHBy
REM aW50KHUiICBPcsOhY3VsbyBSZW4nUHk6IHt9IGVudHJhZGFzIG5hdGl2YXMgZW5jb250cmFk
REM YXMgYXDDs3MgZmlsdHJvcyBnbG9iYWlzLiIuZm9ybWF0KGxlbihlbnRyYWRhcykpLCBmbHVz
REM aD1UcnVlKQogICAgICAgICAgICBPUkFDVUxPX1JFTlBZWyJhdGl2byJdID0gVHJ1ZQogICAg
REM ICAgICAgICBPUkFDVUxPX1JFTlBZWyJzZGsiXSA9IHNkawogICAgICAgICAgICBPUkFDVUxP
REM X1JFTlBZWyJ2ZXJzYW8iXSA9IHZlcnNhbwogICAgICAgICAgICBPUkFDVUxPX1JFTlBZWyJl
REM bnRyYWRhcyJdID0gZW50cmFkYXMKICAgICAgICAgICAgT1JBQ1VMT19SRU5QWVsibmF0aXZh
REM c190b3RhbCJdID0gbGVuKGVudHJhZGFzKQogICAgICAgICAgICBPUkFDVUxPX1JFTlBZWyJu
REM YXRpdmFzX211bHRpbGluaGEiXSA9IHN1bSgxIGZvciB4IGluIGVudHJhZGFzIGlmIHUiXG4i
REM IGluIHguZ2V0KCJ0ZXh0byIsIHUiIikpCiAgICAgICAgICAgIE9SQUNVTE9fUkVOUFlbImdh
REM bWVfcm9vdCJdID0gb3MucGF0aC5hYnNwYXRoKHBhc3RhX2dhbWUpCiAgICAgICAgICAgIHBv
REM cl9hcnF1aXZvID0ge30KICAgICAgICAgICAgZm9yIGl0ZW0gaW4gZW50cmFkYXM6CiAgICAg
REM ICAgICAgICAgICBwb3JfYXJxdWl2by5zZXRkZWZhdWx0KGl0ZW1bImFycXVpdm8iXS5sb3dl
REM cigpLCB7fSkuc2V0ZGVmYXVsdChpdGVtWyJsaW5oYSJdLCBbXSkuYXBwZW5kKGl0ZW0pCiAg
REM ICAgICAgICAgIE9SQUNVTE9fUkVOUFlbInBvcl9hcnF1aXZvIl0gPSBwb3JfYXJxdWl2bwoK
REM ICAgICAgICAgICAgIyBMaW50IMOpIGRpYWduw7NzdGljbzsgbsOjbyBkZXNhdGl2YSBvIG9y
REM w6FjdWxvIHF1YW5kbyBob3V2ZXIgYXZpc29zIGRlIHNjcmlwdC4KICAgICAgICAgICAgdHJ5
REM OgogICAgICAgICAgICAgICAgY3BfbGludCA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAg
REM ICAgICAgICAgIFtweV0gKyBweV9mbGFncyArIFsicmVucHkucHkiLCB0ZW1wLCAibGludCJd
REM LCBjd2Q9c2RrLCBlbnY9cHlfZW52LCBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLAogICAgICAg
REM ICAgICAgICAgICAgIHN0ZGVycj1zdWJwcm9jZXNzLlNURE9VVCwgdGV4dD1UcnVlLCBlbmNv
REM ZGluZz0idXRmLTgiLCBlcnJvcnM9InJlcGxhY2UiLCB0aW1lb3V0PTYwMAogICAgICAgICAg
REM ICAgICAgKQogICAgICAgICAgICAgICAgaWYgY3BfbGludC5yZXR1cm5jb2RlICE9IDA6CiAg
REM ICAgICAgICAgICAgICAgICAgZm9yIGwgaW4gW3guc3RyaXAoKSBmb3IgeCBpbiAoY3BfbGlu
REM dC5zdGRvdXQgb3IgdSIiKS5zcGxpdGxpbmVzKCkgaWYgeC5zdHJpcCgpXVstODpdOgogICAg
REM ICAgICAgICAgICAgICAgICAgICBsb2cuYXZpc28odSJSZW4nUHkgTGludCAoY8OzcGlhIGRl
REM IGRpYWduw7NzdGljbyk6ICIgKyBsKQogICAgICAgICAgICAgICAgbG9nLmluZm8odSJPcsOh
REM Y3VsbyBSZW4nUHk6IExpbnQgY8OzZGlnbz17fS4iLmZvcm1hdChjcF9saW50LnJldHVybmNv
REM ZGUpKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICAgICAg
REM ICAgIGxvZy5hdmlzbyh1IlJlbidQeSBMaW50IG7Do28gcMO0ZGUgc2VyIGV4ZWN1dGFkbzog
REM e30iLmZvcm1hdChleGMpKQoKICAgICAgICAgICAgT1JBQ1VMT19SRU5QWVsiZmFsaGFzIl0g
REM PSBmYWxoYXNbOjMwXQogICAgICAgICAgICBPUkFDVUxPX1JFTlBZWyJwcm9qZXRvX2lzb2xh
REM ZG9fcmVjdXJzb3NfZXh0ZXJub3MiXSA9IFRydWUKICAgICAgICAgICAgbG9nLmluZm8odSJP
REM csOhY3VsbyBSZW4nUHkgQVRJVk86IFNESz17fSB8IHZlcnPDo289e30gfCB7fSBlbnRyYWRh
REM cyBuYXRpdmFzLiIuZm9ybWF0KAogICAgICAgICAgICAgICAgc2RrLCB2ZXJzYW8sIGxlbihl
REM bnRyYWRhcykpKQogICAgICAgICAgICBwcmludCh1IiAgT3LDoWN1bG8gUmVuJ1B5OiBBVElW
REM TyAtPiB7fSB8IHt9IGVudHJhZGFzIi5mb3JtYXQodmVyc2FvLCBsZW4oZW50cmFkYXMpKSwg
REM Zmx1c2g9VHJ1ZSkKICAgICAgICAgICAgcmV0dXJuIHBvcl9hcnF1aXZvCiAgICAgICAgZXhj
REM ZXB0IHN1YnByb2Nlc3MuVGltZW91dEV4cGlyZWQ6CiAgICAgICAgICAgIG1zZyA9IHUie306
REM IHRpbWVvdXQgZGUgNjAwcyIuZm9ybWF0KHNkaykKICAgICAgICAgICAgZmFsaGFzLmFwcGVu
REM ZChtc2cpOyBsb2cuZXJybyh1Ik9yw6FjdWxvIFJlbidQeTogIiArIG1zZykKICAgICAgICBl
REM eGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICAgICAgbXNnID0gdSJ7fToge30iLmZv
REM cm1hdChzZGssIGV4YykKICAgICAgICAgICAgZmFsaGFzLmFwcGVuZChtc2cpOyBsb2cuZXJy
REM byh1Ik9yw6FjdWxvIFJlbidQeTogZmFsaGEgLT4gIiArIG1zZykKICAgICAgICBmaW5hbGx5
REM OgogICAgICAgICAgICBpZiB0ZW1wOgogICAgICAgICAgICAgICAgdHJ5OiBzaHV0aWwucm10
REM cmVlKHRlbXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgICAgICAgICAgICAgIGV4Y2VwdCBF
REM eGNlcHRpb246IHBhc3MKCiAgICBPUkFDVUxPX1JFTlBZWyJmYWxoYXMiXSA9IGZhbGhhc1s6
REM MzBdCiAgICBmb3IgZiBpbiBmYWxoYXNbOjEwXTogbG9nLmVycm8odSJPcsOhY3VsbyBSZW4n
REM UHk6ICIgKyBmKQogICAgcmV0dXJuIHt9CgpkZWYgX2luamV0YXJfZW50cmFkYXNfb3JhY3Vs
REM b19uYV9saW5oYShsaW5oYV9udW1lcm8sIGxpbmhhX3NlbV9maW0sIGFycXVpdm9fcmVsYXRp
REM dm8sIG9yYWNsZV9maWxlLCByZWdpc3Ryb3MsIHByZWZpeG9fd3MsIGphX29jdXBhZG9zKToK
REM ICAgIGlmIG5vdCBvcmFjbGVfZmlsZToKICAgICAgICByZXR1cm4gKDAsIDAsIDApCiAgICBl
REM bnRyYWRhcyA9IG9yYWNsZV9maWxlLmdldChsaW5oYV9udW1lcm8sIFtdKQogICAgaWYgbm90
REM IGVudHJhZGFzOgogICAgICAgIHJldHVybiAoMCwgMCwgMCkKICAgIGFkaWNpb25hZGFzID0g
REM ZHVwbGljYWRhcyA9IGFtYmlndWFzID0gMAogICAgZm9yIGl0ZW0gaW4gZW50cmFkYXM6CiAg
REM ICAgICAgY2FuZGlkYXRvcyA9IF9jYW5kaWRhdG9zX3N0cmluZ19saW5oYShsaW5oYV9zZW1f
REM ZmltLCBpdGVtWyJ0ZXh0byJdKQogICAgICAgIGlmIGxlbihjYW5kaWRhdG9zKSA9PSAwOgog
REM ICAgICAgICAgICBjb250aW51ZQogICAgICAgIGlmIGxlbihjYW5kaWRhdG9zKSA+IDE6CiAg
REM ICAgICAgICAgIGFtYmlndWFzICs9IDEKICAgICAgICAgICAgY29udGludWUKICAgICAgICBp
REM bmljaW8sIGZpbSwgcSA9IGNhbmRpZGF0b3NbMF0KICAgICAgICBjaGF2ZSA9IChpbmljaW8g
REM LSBsZW4ocHJlZml4b193cyksIGZpbSAtIGxlbihwcmVmaXhvX3dzKSkKICAgICAgICBpZiBj
REM aGF2ZSBpbiBqYV9vY3VwYWRvczoKICAgICAgICAgICAgZHVwbGljYWRhcyArPSAxCiAgICAg
REM ICAgICAgIGNvbnRpbnVlCiAgICAgICAgIyBOw6NvIHVzYSBhIHBvc2nDp8OjbyBuYXRpdmEg
REM aXNvbGFkYW1lbnRlIHBhcmEgZmFicmljYXIgdW0gdGV4dG8gcXVlIG7Do28KICAgICAgICAj
REM IGVzdGVqYSBsaXRlcmFsbWVudGUgbmEgZm9udGUuIE8gb3LDoWN1bG8gc8OzIGVudHJhIHF1
REM YW5kbyBjb25zZWd1ZQogICAgICAgICMgcHJvdmFyIG8gbWF0Y2ggYXJxdWl2byArIGxpbmhh
REM ICsgbGl0ZXJhbC4KICAgICAgICBpZiBjaGF2ZVswXSA8IDA6CiAgICAgICAgICAgIGNvbnRp
REM bnVlCiAgICAgICAgdGlwb19vcmFjdWxvID0gKCdyZW5weV9uYXRpdm9fZGlhbG9nbycgaWYg
REM aXRlbS5nZXQoJ3BlcnNvbmFnZW0nKSBlbHNlICdyZW5weV9uYXRpdm9fc3RyaW5nJykKICAg
REM ICAgICAjIFVSTCBwdXJhIGV4aWJpZGEgZW0gdW1hIGZhbGEvbWVudSBjb250aW51YSBzZW5k
REM byB0ZXh0byB2aXPDrXZlbCBlIHByZWNpc2EKICAgICAgICAjIGVudHJhciBubyBtYXBhLCBt
REM YXMgamFtYWlzIGRldmUgc2VyIGVudmlhZGEgYW8gR29vZ2xlIFRyYW5zbGF0ZS4KICAgICAg
REM ICBpZiBpdGVtLmdldCgncGVyc29uYWdlbScpIGFuZCBQVVJFX1ZJU0lCTEVfVVJMX1JFLm1h
REM dGNoKHN0cmlwX3F1b3RlcyhxKS5zdHJpcCgpKToKICAgICAgICAgICAgdGlwb19vcmFjdWxv
REM ID0gJ3VybF92aXNpdmVsJwogICAgICAgIHJlZ2lzdHJvcy5hcHBlbmQoKGNoYXZlWzBdLCBj
REM aGF2ZVsxXSwKICAgICAgICAgICAgICAgICAgICAgICAgICB0aXBvX29yYWN1bG8sCiAgICAg
REM ICAgICAgICAgICAgICAgICAgICAgMTAwLAogICAgICAgICAgICAgICAgICAgICAgICAgIHUi
REM T3LDoWN1bG8gUmVuJ1B5OiB7fXt9Ii5mb3JtYXQoCiAgICAgICAgICAgICAgICAgICAgICAg
REM ICAgICAgIHUiZmFsYSIgaWYgaXRlbS5nZXQoJ3BlcnNvbmFnZW0nKSBlbHNlIHUic3RyaW5n
REM L21lbnUiLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAodSIgW3t9XSIuZm9ybWF0
REM KGl0ZW0uZ2V0KCdpZGVudGlmaWNhZG9yJykpIGlmIGl0ZW0uZ2V0KCdpZGVudGlmaWNhZG9y
REM JykgZWxzZSB1IiIpKSwKICAgICAgICAgICAgICAgICAgICAgICAgICBxLCBOb25lKSkKICAg
REM ICAgICBqYV9vY3VwYWRvcy5hZGQoY2hhdmUpCiAgICAgICAgYWRpY2lvbmFkYXMgKz0gMQog
REM ICAgcmV0dXJuIGFkaWNpb25hZGFzLCBkdXBsaWNhZGFzLCBhbWJpZ3VhcwoKIyA9PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PQojIEVYVFJBw4fDg08gRSBNQVBBCiMgPT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT0KCmRlZiBfbm9ybWFsaXphcl90ZXh0b19vcmFjdWxvX21hcGEodmFsb3IpOgog
REM ICAgIiIiRGVjb2RpZmljYSBvIGxpdGVyYWwgUmVuJ1B5IGFybWF6ZW5hZG8gbm8gbWFwYSBE
REM REFDLiIiIgogICAgaWYgdmFsb3IgaXMgTm9uZToKICAgICAgICByZXR1cm4gdSIiCiAgICB0
REM ZXh0byA9IHN0cih2YWxvcikKICAgIHRyeToKICAgICAgICByZXR1cm4gZGVjb2RpZmljYXJf
REM bGl0ZXJhbF90cmFkdWNhbyh0ZXh0bykKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAg
REM cmV0dXJuIHN0cmlwX3F1b3Rlcyh0ZXh0bykKCgpkZWYgX25vcm1hbGl6YXJfdGV4dG9fb3Jh
REM Y3Vsb19zZGsodmFsb3IpOgogICAgIiIiTWFudMOpbSBsaXRlcmFsbWVudGUgbyB0ZXh0byBq
REM w6EgZGVjb2RpZmljYWRvIGVudHJlZ3VlIHBlbG8gU0RLLiIiIgogICAgcmV0dXJuIHUiIiBp
REM ZiB2YWxvciBpcyBOb25lIGVsc2Ugc3RyKHZhbG9yKQoKCmRlZiBfdGV4dG9fb3JhY3Vsb19y
REM ZWxldmFudGUodGV4dG8pOgogICAgIiIiUmV0b3JuYSBUcnVlIHF1YW5kbyBhIGVudHJhZGEg
REM bmF0aXZhIHRlbSBhcGFyw6puY2lhIGRlIHRleHRvIHRyYWR1esOtdmVsLiIiIgogICAgaWYg
REM dGV4dG8gaXMgTm9uZToKICAgICAgICByZXR1cm4gRmFsc2UKICAgIHMgPSBzdHIodGV4dG8p
REM LnN0cmlwKCkKICAgIGlmIG5vdCBzOgogICAgICAgIHJldHVybiBGYWxzZQogICAgaWYgcy5z
REM dGFydHN3aXRoKCh1IiQiLCB1IiMiKSk6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBpZiBy
REM ZS5tYXRjaChyJ14obGFiZWx8anVtcHxjYWxsfGRlZmluZXxkZWZhdWx0fHRyYW5zZm9ybXxz
REM Y3JlZW58aW5pdHxweXRob24pXGInLCBzLCByZS5JKToKICAgICAgICByZXR1cm4gRmFsc2UK
REM ICAgIGlmIHJlLm1hdGNoKHInXltBLVphLXpfXVtBLVphLXowLTlfXSooPzpbLlxcL11bQS1a
REM YS16MC05Xy5cXC8tXSspPyQnLCBzKToKICAgICAgICByZXR1cm4gRmFsc2UKICAgIGlmIHJl
REM Lm1hdGNoKHInXltBLVphLXpdOltcXC9dJywgcyk6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAg
REM ICBpZiByZS5zZWFyY2gocidcLig/OnJweXxycHltfHJweWN8cHl8cG5nfGpwZ3xqcGVnfHdl
REM YnB8b2dnfG1wM3x3YXZ8dHRmfG90ZikkJywgcywgcmUuSSk6CiAgICAgICAgcmV0dXJuIEZh
REM bHNlCiAgICBpZiBub3QgcmUuc2VhcmNoKHInW0EtWmEtesOALcO/XScsIHMpOgogICAgICAg
REM IHJldHVybiBGYWxzZQogICAgcmV0dXJuIFRydWUKCgpkZWYgX2F1ZGl0YXJfY29iZXJ0dXJh
REM X29yYWN1bG8obWFwYV9jb21wbGV0bywgY2FuZGlkYXRvcz1Ob25lLCBpZ25vcmFkb3NfYmli
REM PU5vbmUpOgogICAgIiIiQXVkaXRhIG8gcXVlIG8gU0RLIG9maWNpYWwgZW5jb250cm91IGNv
REM bnRyYSBvIG1hcGEgRERBQyBmaW5hbC4KCiAgICBJbXBvcnRhbnRlOiAibmF0aXZhc19tYXBl
REM YWRhcyIgZSAibmF0aXZhc19kdXBsaWNhZGFzIiBzw6NvIGNvbnRhZG9yZXMgZGUKICAgIGV2
REM ZW50b3Mgb2NvcnJpZG9zIGR1cmFudGUgYSBpbmplw6fDo28gZG8gT3LDoWN1bG8gZSBuw6Nv
REM IHPDo28gcGFydGVzIGRlIHVtYQogICAgbWVzbWEgc29tYS4gQSBjb2JlcnR1cmEgZGVzdGEg
REM YXVkaXRvcmlhIMOpIGNhbGN1bGFkYSBleGNsdXNpdmFtZW50ZSBwZWxvCiAgICBjcnV6YW1l
REM bnRvIGZpbmFsIFNESyA8LT4gbWFwYSwgZXZpdGFuZG8gbyBhbnRpZ28gcmVsYXTDs3JpbyBl
REM bmdhbm9zby4KICAgICIiIgogICAgaWYgbm90IE9SQUNVTE9fUkVOUFkuZ2V0KCJhdGl2byIp
REM OgogICAgICAgIHJldHVybgoKICAgIGVuY29udHJhZG9zX2V4YXRvcyA9IHNldCgpCiAgICBl
REM bmNvbnRyYWRvc190ZXh0byA9IHt9CiAgICBhcnF1aXZvc19tYXBhID0gc2V0KCkKCiAgICBm
REM b3IgcmVsLCBtYXBhIGluIChtYXBhX2NvbXBsZXRvIG9yIHt9KS5pdGVtcygpOgogICAgICAg
REM IHJlbG4gPSBfbm9ybWFsaXphcl9yZWxfcmVucHkocmVsKS5sb3dlcigpCiAgICAgICAgYXJx
REM dWl2b3NfbWFwYS5hZGQocmVsbikKICAgICAgICBmb3IgaXRlbSBpbiBtYXBhIG9yIFtdOgog
REM ICAgICAgICAgICBsaW5oYSA9IGludChpdGVtLmdldCgibGluaGEiLCAwKSBvciAwKQogICAg
REM ICAgICAgICBvcmlnaW5hbCA9IF9ub3JtYWxpemFyX3RleHRvX29yYWN1bG9fbWFwYSgKICAg
REM ICAgICAgICAgICAgIGl0ZW0uZ2V0KCJvcmlnaW5hbCIsIGl0ZW0uZ2V0KCJ0cmVjaG8iLCB1
REM IiIpKQogICAgICAgICAgICApCiAgICAgICAgICAgIGVuY29udHJhZG9zX2V4YXRvcy5hZGQo
REM KHJlbG4sIGxpbmhhLCBvcmlnaW5hbCkpCiAgICAgICAgICAgIGNoYXZlID0gKHJlbG4sIG9y
REM aWdpbmFsKQogICAgICAgICAgICBlbmNvbnRyYWRvc190ZXh0b1tjaGF2ZV0gPSBlbmNvbnRy
REM YWRvc190ZXh0by5nZXQoY2hhdmUsIDApICsgMQoKICAgICMgTyBlc2NvcG8gZGEgYXVkaXRv
REM cmlhIHJlcHJlc2VudGEgYXJxdWl2b3MtZm9udGUgcmVhbG1lbnRlIGFuYWxpc8OhdmVpcy4K
REM ICAgICMgRWxlIGluY2x1aSBvcyBhcnF1aXZvcyBjYW5kaWRhdG9zLCBtYXMgcmVzcGVpdGEg
REM b3MgYXJxdWl2b3MgZXhwbGljaXRhbWVudGUKICAgICMgcmV0aXJhZG9zIHBlbGEgYmlibGlv
REM dGVjYSBEREFDLiBPIHJlbGF0w7NyaW8gbsOjbyBjaGFtYXLDoSBlc3NhcyBlbnRyYWRhcyBk
REM ZQogICAgIyAiZGnDoWxvZ29zIHBlcmRpZG9zIjogZWxhcyBzw6NvIGFwZW5hcyBjYW5kaWRh
REM dGFzIG5hdGl2YXMgbsOjbyBjb3JyZXNwb25kaWRhcy4KICAgIGFycXVpdm9zX2VzY29wbyA9
REM IHNldChhcnF1aXZvc19tYXBhKQogICAgZm9yIGNhbWluaG8gaW4gY2FuZGlkYXRvcyBvciBb
REM XToKICAgICAgICB0cnk6CiAgICAgICAgICAgIHJlbCA9IG9zLnBhdGgucmVscGF0aCgKICAg
REM ICAgICAgICAgICAgIGNhbWluaG8sCiAgICAgICAgICAgICAgICBPUkFDVUxPX1JFTlBZLmdl
REM dCgiZ2FtZV9yb290Iikgb3Igb3MucGF0aC5kaXJuYW1lKGNhbWluaG8pCiAgICAgICAgICAg
REM ICkKICAgICAgICAgICAgcmVsID0gX25vcm1hbGl6YXJfcmVsX3JlbnB5KHJlbCkubG93ZXIo
REM KQogICAgICAgICAgICAjIE51bmNhIGFkaWNpb25hciBjYW1pbmhvcyByZWxhdGl2b3MgcXVl
REM YnJhZG9zIGNvbSAiLi4iIGFvIGVzY29wby4KICAgICAgICAgICAgaWYgbm90IHJlbC5zdGFy
REM dHN3aXRoKCIuLi8iKSBhbmQgbm90IHJlbC5zdGFydHN3aXRoKCIuLlxcIik6CiAgICAgICAg
REM ICAgICAgICBhcnF1aXZvc19lc2NvcG8uYWRkKHJlbCkKICAgICAgICBleGNlcHQgRXhjZXB0
REM aW9uOgogICAgICAgICAgICBwYXNzCgogICAgaWdub3JhZG9zID0gc2V0KCkKICAgIGZvciBj
REM YW1pbmhvLCBfZGVzY3JpY2FvIGluIChpZ25vcmFkb3NfYmliIG9yIFtdKToKICAgICAgICBp
REM Z25vcmFkb3MuYWRkKF9ub3JtYWxpemFyX3JlbF9yZW5weShjYW1pbmhvKS5sb3dlcigpKQog
REM ICAgZm9yIGNhbWluaG8gaW4gSUdOT1JBRE9TX0VYVFJBQ0FPX0FVVE9NQVRJQ0E6CiAgICAg
REM ICAgaWdub3JhZG9zLmFkZChfbm9ybWFsaXphcl9yZWxfcmVucHkoY2FtaW5obykubG93ZXIo
REM KSkKCiAgICBwZW5kZW50ZXMgPSBbXQogICAgZm9yYV9lc2NvcG8gPSAwCiAgICBmYWxsYmFj
REM a190ZXh0byA9IDAKICAgIGZhbGxiYWNrX21vbm9sb2dvID0gMAogICAgY29ycmVzcG9uZGVu
REM Y2lhX2V4YXRhID0gMAogICAgcmVzdGFudGVzID0gZGljdChlbmNvbnRyYWRvc190ZXh0bykK
REM ICAgIG1vbm9sb2dvX3Jlc3RhbnRlcyA9IHt9CiAgICBmb3IgcmVsLCBtYXBhIGluIChtYXBh
REM X2NvbXBsZXRvIG9yIHt9KS5pdGVtcygpOgogICAgICAgIHJlbG4gPSBfbm9ybWFsaXphcl9y
REM ZWxfcmVucHkocmVsKS5sb3dlcigpCiAgICAgICAgZm9yIGl0ZW1fbWFwIGluIG1hcGEgb3Ig
REM W106CiAgICAgICAgICAgIGlmIGl0ZW1fbWFwLmdldCgndGlwbycpIG5vdCBpbiAoJ21vbm9s
REM b2dvX3RyaXBsYXMnLCAnZ2V0dGV4dF9tdWx0aWxpbmhhJywgJ3BvZW1hX2NvcnBvJyk6CiAg
REM ICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICB0eHRfbSA9IHJlLnN1YihyJ1xz
REM KycsICcgJywgX25vcm1hbGl6YXJfdGV4dG9fb3JhY3Vsb19tYXBhKGl0ZW1fbWFwLmdldCgn
REM b3JpZ2luYWwnLCB1JycpKSkuc3RyaXAoKQogICAgICAgICAgICBpZiB0eHRfbToKICAgICAg
REM ICAgICAgICAgIGNoYXZlX20gPSAocmVsbiwgdHh0X20pCiAgICAgICAgICAgICAgICBtb25v
REM bG9nb19yZXN0YW50ZXNbY2hhdmVfbV0gPSBtb25vbG9nb19yZXN0YW50ZXMuZ2V0KGNoYXZl
REM X20sIDApICsgMQogICAgZXNjb3BvID0gMAoKICAgIGZvciBpdGVtIGluIE9SQUNVTE9fUkVO
REM UFkuZ2V0KCJlbnRyYWRhcyIsIFtdKToKICAgICAgICByZWxuID0gX25vcm1hbGl6YXJfcmVs
REM X3JlbnB5KGl0ZW0uZ2V0KCJhcnF1aXZvIiwgdSIiKSkubG93ZXIoKQogICAgICAgIGxpbmhh
REM ID0gaW50KGl0ZW0uZ2V0KCJsaW5oYSIsIDApIG9yIDApCiAgICAgICAgdGV4dG8gPSBfbm9y
REM bWFsaXphcl90ZXh0b19vcmFjdWxvX3NkayhpdGVtLmdldCgidGV4dG8iLCB1IiIpKQoKICAg
REM ICAgICBpZiAoCiAgICAgICAgICAgIHJlbG4gbm90IGluIGFycXVpdm9zX2VzY29wbwogICAg
REM ICAgICAgICBvciByZWxuIGluIGlnbm9yYWRvcwogICAgICAgICAgICBvciBub3QgX3RleHRv
REM X29yYWN1bG9fcmVsZXZhbnRlKHRleHRvKQogICAgICAgICk6CiAgICAgICAgICAgIGZvcmFf
REM ZXNjb3BvICs9IDEKICAgICAgICAgICAgY29udGludWUKCiAgICAgICAgZXNjb3BvICs9IDEK
REM CiAgICAgICAgaWYgKHJlbG4sIGxpbmhhLCB0ZXh0bykgaW4gZW5jb250cmFkb3NfZXhhdG9z
REM OgogICAgICAgICAgICBjaGF2ZSA9IChyZWxuLCB0ZXh0bykKICAgICAgICAgICAgaWYgcmVz
REM dGFudGVzLmdldChjaGF2ZSwgMCkgPiAwOgogICAgICAgICAgICAgICAgcmVzdGFudGVzW2No
REM YXZlXSAtPSAxCiAgICAgICAgICAgIGNvcnJlc3BvbmRlbmNpYV9leGF0YSArPSAxCiAgICAg
REM ICAgICAgIGNvbnRpbnVlCgogICAgICAgIGNoYXZlID0gKHJlbG4sIHRleHRvKQogICAgICAg
REM IGlmIHJlc3RhbnRlcy5nZXQoY2hhdmUsIDApID4gMDoKICAgICAgICAgICAgcmVzdGFudGVz
REM W2NoYXZlXSAtPSAxCiAgICAgICAgICAgIGZhbGxiYWNrX3RleHRvICs9IDEKICAgICAgICAg
REM ICAgY29udGludWUKCiAgICAgICAgIyBSZW4nUHkgbW9ub2xvZ3VlIG1vZGUgcG9kZSBleHBv
REM cnRhciB1bSBibG9jbyBpbnRlaXJvIGNvbW8gdW1hIMO6bmljYQogICAgICAgICMgZW50cmFk
REM YSBuYXRpdmEgY29udGVuZG8gdsOhcmlhcyBsaW5oYXMsIGVucXVhbnRvIG8gbWFwYSBwcmVj
REM aXNhIG1hbnRlcgogICAgICAgICMgY2FkYSBsaW5oYSBmw61zaWNhIHNlcGFyYWRhIHBhcmEg
REM cXVlIGEgcmVpbmplw6fDo28gcHJlc2VydmUgYSBlc3RydXR1cmEuCiAgICAgICAgIyBOZXNz
REM ZSBjYXNvLCBwcm92YS1zZSBhIGNvYmVydHVyYSBjb21wYXJhbmRvIHRvZGFzIGFzIGxpbmhh
REM cyBkbyBibG9jbwogICAgICAgICMgY29tIGFzIGVudHJhZGFzIGBtb25vbG9nb190cmlwbGFz
REM YCBkbyBtZXNtbyBhcnF1aXZvLgogICAgICAgIGlmICdcbicgaW4gdGV4dG8gb3IgJ1xyJyBp
REM biB0ZXh0bzoKICAgICAgICAgICAgcGFydGVzID0gW3JlLnN1YihyJ1xzKycsICcgJywgcCku
REM c3RyaXAoKSBmb3IgcCBpbiByZS5zcGxpdChyJ1tcclxuXSsnLCB0ZXh0bykgaWYgcC5zdHJp
REM cCgpXQogICAgICAgICAgICBjb25zdW1vID0gW10KICAgICAgICAgICAgcG9zc2l2ZWwgPSBi
REM b29sKHBhcnRlcykKICAgICAgICAgICAgZm9yIHBhcnRlIGluIHBhcnRlczoKICAgICAgICAg
REM ICAgICAgIGNoYXZlX20gPSAocmVsbiwgcGFydGUpCiAgICAgICAgICAgICAgICBpZiBtb25v
REM bG9nb19yZXN0YW50ZXMuZ2V0KGNoYXZlX20sIDApIDw9IDA6CiAgICAgICAgICAgICAgICAg
REM ICAgcG9zc2l2ZWwgPSBGYWxzZQogICAgICAgICAgICAgICAgICAgIGJyZWFrCiAgICAgICAg
REM ICAgICAgICBjb25zdW1vLmFwcGVuZChjaGF2ZV9tKQogICAgICAgICAgICBpZiBwb3NzaXZl
REM bDoKICAgICAgICAgICAgICAgIGZvciBjaGF2ZV9tIGluIGNvbnN1bW86CiAgICAgICAgICAg
REM ICAgICAgICAgbW9ub2xvZ29fcmVzdGFudGVzW2NoYXZlX21dIC09IDEKICAgICAgICAgICAg
REM ICAgIGZhbGxiYWNrX21vbm9sb2dvICs9IDEKICAgICAgICAgICAgICAgIGNvbnRpbnVlCgog
REM ICAgICAgIHBlbmRlbnRlcy5hcHBlbmQoaXRlbSkKCiAgICAjIEVzdGFzIHRyw6pzIG3DqXRy
REM aWNhcyBzw6NvIGEgw7puaWNhIGJhc2UgZGEgImNvYmVydHVyYSIgZG8gT3LDoWN1bG8uCiAg
REM ICBjb2JlcnRhcyA9IGNvcnJlc3BvbmRlbmNpYV9leGF0YSArIGZhbGxiYWNrX3RleHRvCiAg
REM ICB0b3RhbF9yZWxldmFudGUgPSBlc2NvcG8KCiAgICBPUkFDVUxPX1JFTlBZWyJuYXRpdmFz
REM X3RvdGFsIl0gPSBsZW4oT1JBQ1VMT19SRU5QWS5nZXQoImVudHJhZGFzIiwgW10pKQogICAg
REM T1JBQ1VMT19SRU5QWVsibmF0aXZhc19lbV9lc2NvcG8iXSA9IHRvdGFsX3JlbGV2YW50ZQog
REM ICAgT1JBQ1VMT19SRU5QWVsibmF0aXZhc19mb3JhX2VzY29wbyJdID0gZm9yYV9lc2NvcG8K
REM ICAgIE9SQUNVTE9fUkVOUFlbIm5hdGl2YXNfY29ycmVzcG9uZGVuY2lhX2V4YXRhIl0gPSBj
REM b3JyZXNwb25kZW5jaWFfZXhhdGEKICAgIE9SQUNVTE9fUkVOUFlbIm5hdGl2YXNfZmFsbGJh
REM Y2tfdGV4dG8iXSA9IGZhbGxiYWNrX3RleHRvCiAgICBPUkFDVUxPX1JFTlBZWyJuYXRpdmFz
REM X2ZhbGxiYWNrX21vbm9sb2dvIl0gPSBmYWxsYmFja19tb25vbG9nbwogICAgY29iZXJ0YXMg
REM Kz0gZmFsbGJhY2tfbW9ub2xvZ28KICAgIE9SQUNVTE9fUkVOUFlbIm5hdGl2YXNfY29iZXJ0
REM dXJhX3JlYWwiXSA9IGNvYmVydGFzCiAgICBPUkFDVUxPX1JFTlBZWyJuYXRpdmFzX2NvYmVy
REM dHVyYV9wY3QiXSA9ICgxMDAuMCAqIGNvYmVydGFzIC8gdG90YWxfcmVsZXZhbnRlKSBpZiB0
REM b3RhbF9yZWxldmFudGUgZWxzZSAxMDAuMAogICAgT1JBQ1VMT19SRU5QWVsibmF0aXZhc19u
REM YW9fbG9jYWxpemFkYXMiXSA9IGxlbihwZW5kZW50ZXMpCiAgICBPUkFDVUxPX1JFTlBZWyJu
REM YXRpdmFzX25hb19sb2NhbGl6YWRhc19hbW9zdHJhcyJdID0gWwogICAgICAgIHUie306e30g
REM LT4ge30iLmZvcm1hdCgKICAgICAgICAgICAgeC5nZXQoImFycXVpdm8iLCAiPyIpLAogICAg
REM ICAgICAgICB4LmdldCgibGluaGEiLCAiPyIpLAogICAgICAgICAgICAoeC5nZXQoInRleHRv
REM IiwgIiIpIG9yICIiKVs6MTgwXS5yZXBsYWNlKCJcciIsICJcXHIiKS5yZXBsYWNlKCJcbiIs
REM ICJcXG4iKQogICAgICAgICkKICAgICAgICBmb3IgeCBpbiBwZW5kZW50ZXNbOjMwXQogICAg
REM XQogICAgT1JBQ1VMT19SRU5QWVsiZmFsaGFzIl0gPSBbCiAgICAgICAgdSJOYXRpdmEgcmVs
REM ZXZhbnRlIG7Do28gY29ycmVzcG9uZGlkYSBhbyBtYXBhOiB7fSIuZm9ybWF0KGFtb3N0cmEp
REM CiAgICAgICAgZm9yIGFtb3N0cmEgaW4gT1JBQ1VMT19SRU5QWVsibmF0aXZhc19uYW9fbG9j
REM YWxpemFkYXNfYW1vc3RyYXMiXQogICAgXQoKCmRlZiBfc2hhMjU2X3RleHRvX3V0ZjgodGV4
REM dG8pOgogICAgcmV0dXJuIGhhc2hsaWIuc2hhMjU2KCh0ZXh0byBvciB1JycpLmVuY29kZSgn
REM dXRmLTgnKSkuaGV4ZGlnZXN0KCkKCmRlZiBfdG9rZW5fc2lnbmF0dXJlX21hcGEob3JpZ2lu
REM YWwpOgogICAgdHJ5OgogICAgICAgIHRleHRvID0gZGVjb2RpZmljYXJfbGl0ZXJhbF90cmFk
REM dWNhbyhvcmlnaW5hbCkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgdGV4dG8gPSBz
REM dHJpcF9xdW90ZXMob3JpZ2luYWwpCiAgICByZXR1cm4gW3JhdyBmb3IgXyxfLHJhdyBpbiBf
REM aW50ZXJ2YWxvc190b2tlbnNfZ29vZ2xlKHRleHRvKV0KCmRlZiBfaXRlcl9pbnRlcnZhbG9z
REM X2JyYWNrZXRzX2JhbGFuY2VhZG9zKHRleHRvKToKICAgICIiIlJldG9ybmEgaW50ZXJ2YWxv
REM cyBbLi5dIGNvbSBuZXN0aW5nIGJhbGFuY2VhZG8sIHJlc3BlaXRhbmRvIGVzY2FwZXMgZSBh
REM c3Bhcy4iIiIKICAgIGFiZXJ0b3M9W107IGk9MDsgbj1sZW4odGV4dG8pCiAgICBxdW90ZT1O
REM b25lOyBlc2M9RmFsc2UKICAgIHdoaWxlIGk8bjoKICAgICAgICBjaD10ZXh0b1tpXQogICAg
REM ICAgIGlmIHF1b3RlIGlzIG5vdCBOb25lOgogICAgICAgICAgICBpZiBlc2M6IGVzYz1GYWxz
REM ZQogICAgICAgICAgICBlbGlmIGNoPT0nXFwnOiBlc2M9VHJ1ZQogICAgICAgICAgICBlbGlm
REM IGNoPT1xdW90ZTogcXVvdGU9Tm9uZQogICAgICAgICAgICBpKz0xOyBjb250aW51ZQogICAg
REM ICAgIGlmIGNoIGluICgnIicsICInIiwgJ2AnKToKICAgICAgICAgICAgcXVvdGU9Y2g7IGkr
REM PTE7IGNvbnRpbnVlCiAgICAgICAgaWYgY2g9PSdcXCc6IGkrPTI7IGNvbnRpbnVlCiAgICAg
REM ICAgaWYgY2g9PSdbJzogYWJlcnRvcy5hcHBlbmQoaSkKICAgICAgICBlbGlmIGNoPT0nXScg
REM YW5kIGFiZXJ0b3M6CiAgICAgICAgICAgIGluaWNpbz1hYmVydG9zLnBvcCgpCiAgICAgICAg
REM ICAgIGlmIG5vdCBhYmVydG9zOgogICAgICAgICAgICAgICAgeWllbGQgaW5pY2lvLCBpKzEK
REM ICAgICAgICBpKz0xCgpkZWYgX2hhc2hfY29udGV4dG9fbGluaGFzKGxpbmhhc19yYXcsIG51
REM bWVybywgcmFpbz0yKToKICAgIGE9bWF4KDAsbnVtZXJvLTEtcmFpbyk7IGI9bWluKGxlbihs
REM aW5oYXNfcmF3KSxudW1lcm8rcmFpbykKICAgIHJldHVybiBfc2hhMjU2X3RleHRvX3V0Zjgo
REM dScnLmpvaW4obGluaGFzX3Jhd1thOmJdKSkKCmRlZiBfZW5yaXF1ZWNlcl9tYXBhX2ludGVn
REM cmlkYWRlKG1hcGEsIGNhbWluaG8sIGNhbWluaG9fcmVsYXRpdm8sIGxpbmhhc19yYXc9Tm9u
REM ZSk6CiAgICBsaW5oYXNfcmF3ID0gbGluaGFzX3JhdyBpZiBsaW5oYXNfcmF3IGlzIG5vdCBO
REM b25lIGVsc2UgbGVyX2xpbmhhc19yYXcoY2FtaW5obykKICAgIHNvdXJjZV9zaGEgPSBzaGEy
REM NTZfYXJxdWl2byhjYW1pbmhvKQogICAgdWx0aW1vX2dydXBvID0gTm9uZQogICAgdWx0aW1h
REM X2xpbmhhID0gTm9uZQogICAgdWx0aW1vX3RpcG8gPSBOb25lCiAgICB1bHRpbW9fY29udGV4
REM dG8gPSBOb25lCiAgICBmb3IgZW50cmFkYSBpbiBtYXBhOgogICAgICAgIG51bWVybz1pbnQo
REM ZW50cmFkYS5nZXQoJ2xpbmhhJywwKSBvciAwKQogICAgICAgIG9yaWdpbmFsPWVudHJhZGEu
REM Z2V0KCdvcmlnaW5hbCcsZW50cmFkYS5nZXQoJ3RyZWNobycsdScnKSkKICAgICAgICBiYXNl
REM X2lkID0gdSd7MH1cMHsxfVwwezJ9XDB7M31cMHs0fScuZm9ybWF0KHNvdXJjZV9zaGEsIG51
REM bWVybywgZW50cmFkYS5nZXQoJ2NvbHVuYV9pbmljaW8nLDApLCBlbnRyYWRhLmdldCgnY29s
REM dW5hX2ZpbScsMCksIG9yaWdpbmFsKQogICAgICAgIGVudHJhZGFbJ3NvdXJjZV9zaGEyNTYn
REM XT1zb3VyY2Vfc2hhCiAgICAgICAgZW50cmFkYVsnZW50cnlfaWQnXT1oYXNobGliLnNoYTI1
REM NihiYXNlX2lkLmVuY29kZSgndXRmLTgnKSkuaGV4ZGlnZXN0KClbOjI0XQogICAgICAgIHRp
REM cG89ZW50cmFkYS5nZXQoJ3RpcG8nLHUnJykKICAgICAgICBjb250ZXh0bz1lbnRyYWRhLmdl
REM dCgnY29udGV4dG8nLHUnJykKICAgICAgICBlc3BlY2lhbD10aXBvIGluICgnbXVsdGlsaW5o
REM YV9yZW5weScsJ21vbm9sb2dvX3RyaXBsYXMnLCdwb2VtYV9jb3JwbycsJ2dldHRleHRfbXVs
REM dGlsaW5oYScpCiAgICAgICAgaWYgZXNwZWNpYWwgYW5kIHVsdGltb19ncnVwbyBhbmQgdGlw
REM bz09dWx0aW1vX3RpcG8gYW5kIGNvbnRleHRvPT11bHRpbW9fY29udGV4dG8gYW5kIHVsdGlt
REM YV9saW5oYSBpcyBub3QgTm9uZSBhbmQgbnVtZXJvIDw9IHVsdGltYV9saW5oYSsyOgogICAg
REM ICAgICAgICBncnVwbz11bHRpbW9fZ3J1cG8KICAgICAgICBlbHNlOgogICAgICAgICAgICBn
REM cnVwb19iYXNlPXUnezB9XDB7MX1cMHsyfScuZm9ybWF0KHNvdXJjZV9zaGEsIHRpcG8sIG51
REM bWVybykKICAgICAgICAgICAgZ3J1cG89aGFzaGxpYi5zaGEyNTYoZ3J1cG9fYmFzZS5lbmNv
REM ZGUoJ3V0Zi04JykpLmhleGRpZ2VzdCgpWzoyMF0gaWYgZXNwZWNpYWwgZWxzZSBlbnRyYWRh
REM WydlbnRyeV9pZCddCiAgICAgICAgZW50cmFkYVsnbG9naWNhbF9ncm91cF9pZCddPWdydXBv
REM CiAgICAgICAgbGluaGFfcmF3PWxpbmhhc19yYXdbbnVtZXJvLTFdIGlmIDEgPD0gbnVtZXJv
REM IDw9IGxlbihsaW5oYXNfcmF3KSBlbHNlIHUnJwogICAgICAgIGVudHJhZGFbJ3NvdXJjZV9s
REM aW5lX2hhc2gnXT1fc2hhMjU2X3RleHRvX3V0ZjgobGluaGFfcmF3KQogICAgICAgIGVudHJh
REM ZGFbJ2NvbnRleHRfaGFzaCddPV9oYXNoX2NvbnRleHRvX2xpbmhhcyhsaW5oYXNfcmF3LG51
REM bWVybykKICAgICAgICBlbnRyYWRhWyd0b2tlbl9zaWduYXR1cmUnXT1fdG9rZW5fc2lnbmF0
REM dXJlX21hcGEob3JpZ2luYWwpCiAgICAgICAgdWx0aW1vX2dydXBvPWdydXBvIGlmIGVzcGVj
REM aWFsIGVsc2UgTm9uZQogICAgICAgIHVsdGltYV9saW5oYT1udW1lcm8gaWYgZXNwZWNpYWwg
REM ZWxzZSBOb25lCiAgICAgICAgdWx0aW1vX3RpcG89dGlwbyBpZiBlc3BlY2lhbCBlbHNlIE5v
REM bmUKICAgICAgICB1bHRpbW9fY29udGV4dG89Y29udGV4dG8gaWYgZXNwZWNpYWwgZWxzZSBO
REM b25lCiAgICByZXR1cm4gbWFwYQoKCmRlZiBleGVjdXRhcl9leHRyYWNhbyhyYWl6KToKICAg
REM IGdsb2JhbCBJR05PUkFET1NfRVhUUkFDQU9fQVVUT01BVElDQQogICAgSUdOT1JBRE9TX0VY
REM VFJBQ0FPX0FVVE9NQVRJQ0EgPSBbXQogICAgaW5pY2lvX3RvdGFsPXRpbWUudGltZSgpCiAg
REM ICBwYXN0YV9nYW1lPWVuY29udHJhcl9wYXN0YV9nYW1lKHJhaXopCiAgICBwYXN0YV9zYWlk
REM YV9iYXNlPW9zLnBhdGguam9pbihyYWl6LFBBU1RBX0VOVFJBREFfTk9NRSkKICAgIGxvZz1M
REM b2cob3MucGF0aC5qb2luKHJhaXosTk9NRV9MT0dfRVhUUkFUT1IpKQogICAgbG9nLnNlcGFy
REM YWRvcigpOyBsb2cudGl0dWxvKHQoImxvZ19jYWJfZXh0cmF0b3IiKSk7IGxvZy50aXR1bG8o
REM dCgibG9nX2RhdGFob3JhIikuZm9ybWF0KHRpbWUuc3RyZnRpbWUoIiVkLyVtLyVZICVIOiVN
REM OiVTIikpKTsgbG9nLnNlcGFyYWRvcigpCiAgICBsb2cuaW5mbyh0KCJsb2dfcGFzdGFfZXNj
REM YW5lYWRhIikuZm9ybWF0KHBhc3RhX2dhbWUpKTsgbG9nLmluZm8odCgibG9nX3Bhc3RhX3Nh
REM aWRhIikuZm9ybWF0KHBhc3RhX3NhaWRhX2Jhc2UpKTsgbG9nLmluZm8odSJNb2RvIGRlIGV4
REM aWJpw6fDo286IHswfSIuZm9ybWF0KE1PRE9fRVhJQklDQU8pKQogICAgcHJpbnQoIj09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PSIpOyBwcmludCh0KCJjYWJfZXh0cmFpciIpKTsgcHJpbnQoIj09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIpOyBwcmludCgi
REM IikKICAgIHByaW50KHQoInBhc3RhX2VzY2FuZWFkYSIpLmZvcm1hdChwYXN0YV9nYW1lKSk7
REM IHByaW50KHQoInBhc3RhX3NhaWRhIikuZm9ybWF0KHBhc3RhX3NhaWRhX2Jhc2UpKTsgcHJp
REM bnQoIiIpCiAgICBwcmludCh0KCJldGFwYV9iaWJsaW90ZWNhIikuZm9ybWF0KGxlbihCSUJM
REM SU9URUNBX0RETEMpKSk7IGxvZy5pbmZvKHQoImV0YXBhX2JpYmxpb3RlY2EiKS5mb3JtYXQo
REM bGVuKEJJQkxJT1RFQ0FfRERMQykpKTsgcHJpbnQoIiIpCiAgICBwcmludCh0KCJldGFwYTFf
REM ZXh0cmFpciIpKTsgY2FuZGlkYXRvc19pbmljaWFpcz1jb2xldGFyX2NhbmRpZGF0b3NfZXh0
REM cmFjYW8ocGFzdGFfZ2FtZSk7IGluZGljZV9hcnF1aXZvcz1jb25zdHJ1aXJfaW5kaWNlX2Fy
REM cXVpdm9zKHBhc3RhX2dhbWUpOyBhcnF1aXZvc19lbmNvbnRyYWRvcz1sZW4oY2FuZGlkYXRv
REM c19pbmljaWFpcyk7IHByaW50KHQoImFycXVpdm9zX2VuY29udHJhZG9zIikuZm9ybWF0KGFy
REM cXVpdm9zX2VuY29udHJhZG9zKSk7CiAgICBpZiBJR05PUkFET1NfRVhUUkFDQU9fQVVUT01B
REM VElDQToKICAgICAgICBmb3IgX2lnbiBpbiBJR05PUkFET1NfRVhUUkFDQU9fQVVUT01BVElD
REM QToKICAgICAgICAgICAgcHJpbnQodSJbSU5GT10gQXJxdWl2by1iYXNlIG7Do28gdXRpbGl6
REM YWRvIGlnbm9yYWRvIG5hIGV4dHJhw6fDo286IHswfSIuZm9ybWF0KF9pZ24pKQogICAgICAg
REM ICAgICBsb2cuaW5mbyh1IkFycXVpdm8tYmFzZSBuw6NvIHV0aWxpemFkbyBpZ25vcmFkbyBu
REM YSBleHRyYcOnw6NvOiB7MH0iLmZvcm1hdChfaWduKSkKICAgIHByaW50KCIiKTsgbG9nLmlu
REM Zm8odCgibG9nX2V0YXBhMV9leHRyYWlyIikuZm9ybWF0KGFycXVpdm9zX2VuY29udHJhZG9z
REM KSkKICAgIHByaW50KHQoImV0YXBhMl9leHRyYWlyIikpOyB2YXJpYXZlaXNfbm9tZV9kaW5h
REM bWljbz1jb2xldGFyX3ZhcmlhdmVpc19ub21lX2RpbmFtaWNvKGNhbmRpZGF0b3NfaW5pY2lh
REM aXMpOyB2b2NhYnVsYXJpbz1jb2xldGFyX3ZvY2FidWxhcmlvKHBhc3RhX2dhbWUsY2FuZGlk
REM YXRvc19pbmljaWFpcyk7IGNhbmRpZGF0b3M9W2MgZm9yIGMgaW4gY2FuZGlkYXRvc19pbmlj
REM aWFpcyBpZiBub3QgZW1fcGFzdGFfc2VtX3RleHRvKGMscGFzdGFfZ2FtZSldOyBhcnF1aXZv
REM c19hbmFsaXNhZG9zPWxlbihjYW5kaWRhdG9zKTsgcHJpbnQodCgidmFyc19kaW5hbWljYXMi
REM KS5mb3JtYXQobGVuKHZhcmlhdmVpc19ub21lX2RpbmFtaWNvKSkpOyBwcmludCgiIik7IGxv
REM Zy5pbmZvKHQoImxvZ19ldGFwYTJfZXh0cmFpciIpLmZvcm1hdChsZW4odmFyaWF2ZWlzX25v
REM bWVfZGluYW1pY28pLCIsICIuam9pbihzb3J0ZWQodmFyaWF2ZWlzX25vbWVfZGluYW1pY28p
REM KSBvciAiLSIpKQogICAgcHJpbnQodCgiZXRhcGEyYl9leHRyYWlyIikgaWYgImV0YXBhMmJf
REM ZXh0cmFpciIgaW4gTUVOU0FHRU5TLmdldChJRElPTUEse30pIGVsc2UgdSJFdGFwYSAyYi8z
REM OiBhdGl2YW5kbyBvcsOhY3VsbyBzZW3Dom50aWNvIFJlbidQeSBxdWFuZG8gZGlzcG9uw612
REM ZWwuLi4iKTsgcHJpbnQodSIgIFB5dGhvbiAzIGFjaW1hID0gbW90b3IgRERBQy4gTyBTREsg
REM UmVuJ1B5LCBxdWFuZG8gZW5jb250cmFkbywgdXNhIG8gc2V1IHByw7NwcmlvIFB5dGhvbiBj
REM b21wYXTDrXZlbC4iLCBmbHVzaD1UcnVlKTsKICAgIG9yYWNsZV9wb3JfYXJxdWl2byA9IF9w
REM cmVwYXJhcl9vcmFjdWxvX3JlbnB5KHBhc3RhX2dhbWUsIGNhbmRpZGF0b3MsIGxvZykKICAg
REM IGlmIE9SQUNVTE9fUkVOUFlbImF0aXZvIl06CiAgICAgICAgcHJpbnQodSIgIE9yw6FjdWxv
REM IFJlbidQeSBhdGl2bzoge30gfCB7fSIuZm9ybWF0KE9SQUNVTE9fUkVOUFlbInZlcnNhbyJd
REM LCBPUkFDVUxPX1JFTlBZWyJuYXRpdmFzX3RvdGFsIl0pKQogICAgZWxzZToKICAgICAgICBw
REM cmludCh1IiAgT3LDoWN1bG8gUmVuJ1B5IG7Do28gZGlzcG9uw612ZWw7IG1vdG9yIEREQUMg
REM Y29udGludWFyw6EgY29tbyBmYWxsYmFjayBjb21wbGV0by4iKQogICAgcHJpbnQodCgiZXRh
REM cGEzX2V4dHJhaXIiKS5mb3JtYXQoUEFTVEFfRU5UUkFEQV9OT01FKSk7IHByaW50KCIiKTsg
REM bG9nLmluZm8odCgibG9nX2V0YXBhM19leHRyYWlyIikpCiAgICB0b3RhbF9jb21fZGlhbG9n
REM bz10b3RhbF9saW5oYXM9dG90YWxfZXJyb3M9MDsgdmF6aW9zPVtdOyBpZ25vcmFkb3NfYmli
REM PVtdOyBub3Zvc19iaWI9W107IG1hcGFfY29tcGxldG89e30KICAgIGZvciBudW1lcm8sY2Ft
REM aW5obyBpbiBlbnVtZXJhdGUoY2FuZGlkYXRvcywxKToKICAgICAgICBjYW1pbmhvX3JlbGF0
REM aXZvPW9zLnBhdGgucmVscGF0aChjYW1pbmhvLHBhc3RhX2dhbWUpCiAgICAgICAgdHJ5Ogog
REM ICAgICAgICAgICBpZiBjYW1pbmhvLmxvd2VyKCkuZW5kc3dpdGgoIi50eHQiKToKICAgICAg
REM ICAgICAgICAgIGNhbWluaG9fc2FpZGE9b3MucGF0aC5qb2luKHBhc3RhX3NhaWRhX2Jhc2Us
REM Y2FtaW5ob19yZWxhdGl2bykKICAgICAgICAgICAgICAgIGlmIGVoX2FycXVpdm9fbGlzdGFf
REM cGFsYXZyYXNfcG9lbWEoY2FtaW5obyk6CiAgICAgICAgICAgICAgICAgICAgZW50cmFkYXNf
REM dHh0PWV4dHJhaXJfdHh0X2xpc3RhX3BhbGF2cmFzX3BvZW1hKGNhbWluaG8pCiAgICAgICAg
REM ICAgICAgICAgICAgaWYgZW50cmFkYXNfdHh0OgogICAgICAgICAgICAgICAgICAgICAgICBl
REM c2NyZXZlcl90eHRfcGFsYXZyYXNfZXh0cmFpZG8oY2FtaW5obywgY2FtaW5ob19zYWlkYSwg
REM ZW50cmFkYXNfdHh0KQogICAgICAgICAgICAgICAgICAgICAgICBjaGF2ZT1jYW1pbmhvX3Jl
REM bGF0aXZvLnJlcGxhY2Uob3Muc2VwLCIvIikKICAgICAgICAgICAgICAgICAgICAgICAgbWFw
REM YV9jb21wbGV0b1tjaGF2ZV09X2VucmlxdWVjZXJfbWFwYV9pbnRlZ3JpZGFkZShlbnRyYWRh
REM c190eHQsIGNhbWluaG8sIGNoYXZlKQogICAgICAgICAgICAgICAgICAgICAgICB0b3RhbF9j
REM b21fZGlhbG9nbys9MTsgdG90YWxfbGluaGFzKz1sZW4oZW50cmFkYXNfdHh0KQogICAgICAg
REM ICAgICAgICAgICAgICAgICBsb2cucmVzdWx0YWRvKGNhbWluaG9fcmVsYXRpdm8sdCgibG9n
REM X2xpbmhhcyIpLmZvcm1hdChsZW4oZW50cmFkYXNfdHh0KSkgKyB1IiB8IGxpc3RhIGRlIHBh
REM bGF2cmFzIGRlIHBvZW1hIGZpbHRyYWRhIikKICAgICAgICAgICAgICAgICAgICBlbHNlOgog
REM ICAgICAgICAgICAgICAgICAgICAgICBJR05PUkFET1NfRVhUUkFDQU9fQVVUT01BVElDQS5h
REM cHBlbmQoY2FtaW5ob19yZWxhdGl2by5yZXBsYWNlKG9zLnNlcCwgIi8iKSkKICAgICAgICAg
REM ICAgICAgICAgICAgICAgbG9nLmF2aXNvKHUiVFhUIGRlIHBvZW1hIHNlbSBsaW5oYXMgQ1NW
REM IHbDoWxpZGFzOyBvbWl0aWRvIGRhIHNhw61kYSB0cmFkdXrDrXZlbDoge30iLmZvcm1hdChj
REM YW1pbmhvX3JlbGF0aXZvKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAg
REM ICAgICAgSUdOT1JBRE9TX0VYVFJBQ0FPX0FVVE9NQVRJQ0EuYXBwZW5kKGNhbWluaG9fcmVs
REM YXRpdm8ucmVwbGFjZShvcy5zZXAsICIvIikpCiAgICAgICAgICAgICAgICAgICAgbG9nLmlu
REM Zm8odSJUWFQgdMOpY25pY28gc2VtIHRleHRvIG1hcGXDoXZlbDsgb21pdGlkbyBkYSBzYcOt
REM ZGEgdHJhZHV6w612ZWw6IHt9Ii5mb3JtYXQoY2FtaW5ob19yZWxhdGl2bykpCiAgICAgICAg
REM ICAgIGVsc2U6CiAgICAgICAgICAgICAgICB0ZXh0b3MsbWFwYT1leHRyYWlyX2FycXVpdm9f
REM Y29tX21hcGEoY2FtaW5obyx2YXJpYXZlaXNfbm9tZV9kaW5hbWljbyxpbmRpY2VfYXJxdWl2
REM b3Msdm9jYWJ1bGFyaW8sb3JhY2xlX3Bvcl9hcnF1aXZvKTsgaW5mb19iaWI9Y29uc3VsdGFy
REM X2JpYmxpb3RlY2EoY2FtaW5ob19yZWxhdGl2byk7IHNlbV9kaWFsb2dvX25hdGl2bz1ib29s
REM KGluZm9fYmliKSBhbmQgaW5mb19iaWJbImRpYWxvZ28iXSBpcyBGYWxzZQogICAgICAgICAg
REM ICAgICAgaWYgbm90IHRleHRvczoKICAgICAgICAgICAgICAgICAgICBpZiBzZW1fZGlhbG9n
REM b19uYXRpdm86CiAgICAgICAgICAgICAgICAgICAgICAgIGRlc2NyaWNhbz1kZXNjcmljYW9f
REM YmlibGlvdGVjYShpbmZvX2JpYik7IGlnbm9yYWRvc19iaWIuYXBwZW5kKChjYW1pbmhvX3Jl
REM bGF0aXZvLGRlc2NyaWNhbykpOyBsb2cuaW5mbyh0KCJsb2dfYmliX2lnbm9yYWRvIikuZm9y
REM bWF0KGNhbWluaG9fcmVsYXRpdm8sZGVzY3JpY2FvKSkKICAgICAgICAgICAgICAgICAgICBl
REM bHNlOiB2YXppb3MuYXBwZW5kKGNhbWluaG9fcmVsYXRpdm8pCiAgICAgICAgICAgICAgICBl
REM bHNlOgogICAgICAgICAgICAgICAgICAgIGlmIHNlbV9kaWFsb2dvX25hdGl2bzoKICAgICAg
REM ICAgICAgICAgICAgICAgICAgZGVzY3JpY2FvPWRlc2NyaWNhb19iaWJsaW90ZWNhKGluZm9f
REM YmliKTsgbm92b3NfYmliLmFwcGVuZCgoY2FtaW5ob19yZWxhdGl2byxsZW4odGV4dG9zKSxk
REM ZXNjcmljYW8pKTsgbG9nLmF2aXNvKHQoImxvZ19iaWJfbm92byIpLmZvcm1hdChjYW1pbmhv
REM X3JlbGF0aXZvLGRlc2NyaWNhbykpCiAgICAgICAgICAgICAgICAgICAgY2FtaW5ob19zYWlk
REM YT1vcy5wYXRoLmpvaW4ocGFzdGFfc2FpZGFfYmFzZSxjYW1pbmhvX3JlbGF0aXZvKTsgcGFz
REM dGFfc2FpZGE9b3MucGF0aC5kaXJuYW1lKGNhbWluaG9fc2FpZGEpCiAgICAgICAgICAgICAg
REM ICAgICAgaWYgcGFzdGFfc2FpZGEgYW5kIG5vdCBvcy5wYXRoLmlzZGlyKHBhc3RhX3NhaWRh
REM KTogb3MubWFrZWRpcnMocGFzdGFfc2FpZGEpCiAgICAgICAgICAgICAgICAgICAgd2l0aCBp
REM by5vcGVuKGNhbWluaG9fc2FpZGEsInciLGVuY29kaW5nPSJ1dGYtOCIsbmV3bGluZT0iXG4i
REM KSBhcyBmOiBmLndyaXRlKHUiXG4iLmpvaW4oW3UiIl0rW0lOREVOVEFDQU9fU0FJREErdGV4
REM dG8gZm9yIF8sdGV4dG8gaW4gdGV4dG9zXSkrdSJcbiIpCiAgICAgICAgICAgICAgICAgICAg
REM Y2hhdmU9Y2FtaW5ob19yZWxhdGl2by5yZXBsYWNlKG9zLnNlcCwiLyIpOyBtYXBhX2NvbXBs
REM ZXRvW2NoYXZlXT1fZW5yaXF1ZWNlcl9tYXBhX2ludGVncmlkYWRlKG1hcGEsIGNhbWluaG8s
REM IGNoYXZlLCBsaW5oYXNfcmF3PWxlcl9saW5oYXNfcmF3KGNhbWluaG8pKTsgdG90YWxfY29t
REM X2RpYWxvZ28rPTE7IHRvdGFsX2xpbmhhcys9bGVuKHRleHRvcyk7IGxvZy5yZXN1bHRhZG8o
REM Y2FtaW5ob19yZWxhdGl2byx0KCJsb2dfbGluaGFzIikuZm9ybWF0KGxlbih0ZXh0b3MpKSkK
REM ICAgICAgICAgICAgICAgICAgICBpZiBleGliaWNhb19kZXRhbGhhZGEoKTogcHJpbnQodCgi
REM b2tfbGluaGFzIikuZm9ybWF0KGNhbWluaG9fcmVsYXRpdm8sbGVuKHRleHRvcykpKQogICAg
REM ICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAgICAgICAgICB0b3RhbF9lcnJvcys9
REM MTsgbG9nLmVycm8odCgibG9nX2ZhbGhhX2xlciIpLmZvcm1hdChjYW1pbmhvX3JlbGF0aXZv
REM LGV4YykpOyBwcmludCh0KCJlcnJvX2FycXVpdm8iKS5mb3JtYXQoY2FtaW5ob19yZWxhdGl2
REM byxleGMpKQogICAgICAgIHByaW50KHUiXHJBcnF1aXZvczogezB9L3sxfSB7Mn0iLmZvcm1h
REM dChudW1lcm8sbWF4KDEsYXJxdWl2b3NfYW5hbGlzYWRvcyksYmFycmFfcHJvZ3Jlc3NvKG51
REM bWVybyxtYXgoMSxhcnF1aXZvc19hbmFsaXNhZG9zKSkpLGVuZD11IiIpCiAgICBwcmludCgi
REM IikKICAgIGlmIG5vdCBvcy5wYXRoLmlzZGlyKHBhc3RhX3NhaWRhX2Jhc2UpOiBvcy5tYWtl
REM ZGlycyhwYXN0YV9zYWlkYV9iYXNlKQogICAgd2l0aCBpby5vcGVuKG9zLnBhdGguam9pbihw
REM YXN0YV9zYWlkYV9iYXNlLE5PTUVfTUFQQSksInciLGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6
REM IGpzb24uZHVtcChtYXBhX2NvbXBsZXRvLGYsZW5zdXJlX2FzY2lpPUZhbHNlLGluZGVudD0x
REM KQogICAgZGVjb3JyaWRvPXRpbWUudGltZSgpLWluaWNpb190b3RhbDsgdmVsb2NpZGFkZT1m
REM bG9hdCh0b3RhbF9saW5oYXMpL21heCgwLjAwMSxkZWNvcnJpZG8pCiAgICBwcmludCgiIik7
REM IHByaW50KHQoInJlc19lc2NhbmVhZG9zIikuZm9ybWF0KGFycXVpdm9zX2VuY29udHJhZG9z
REM KSk7IHByaW50KHUiQXJxdWl2b3MgYW5hbGlzYWRvczogezB9Ii5mb3JtYXQoYXJxdWl2b3Nf
REM YW5hbGlzYWRvcykpOyBwcmludCh1IkFycXVpdm9zIGV4dHJhw61kb3M6IHswfSIuZm9ybWF0
REM KHRvdGFsX2NvbV9kaWFsb2dvKSk7IHByaW50KHUiVGV4dG9zIGV4dHJhw61kb3M6IHswfSIu
REM Zm9ybWF0KHRvdGFsX2xpbmhhcykpOyBwcmludCh1IlRYVCB0w6ljbmljby9mb3JhIGRvIG1h
REM cGEgb21pdGlkbzogezB9Ii5mb3JtYXQobGVuKElHTk9SQURPU19FWFRSQUNBT19BVVRPTUFU
REM SUNBKSkpOyBwcmludCh1InswfSAxMDAlIi5mb3JtYXQoYmFycmFfcHJvZ3Jlc3NvKGFycXVp
REM dm9zX2FuYWxpc2Fkb3MsbWF4KDEsYXJxdWl2b3NfYW5hbGlzYWRvcykpKSk7IHByaW50KHUi
REM Q29uY2x1w61kbyBlbSB7MDouMWZ9cyB8IHsxOi4xZn0gdGV4dG9zL3MiLmZvcm1hdChkZWNv
REM cnJpZG8sdmVsb2NpZGFkZSkpCiAgICBpZiBleGliaWNhb19kZXRhbGhhZGEoKToKICAgICAg
REM ICBpZiB2YXppb3M6IHByaW50KHQoInJlc19zZW1fZGlhbG9nbyIpLmZvcm1hdChsZW4odmF6
REM aW9zKSkpOyBbcHJpbnQodSIgIC0gezB9Ii5mb3JtYXQoeCkpIGZvciB4IGluIHZhemlvc10K
REM ICAgICAgICBpZiBpZ25vcmFkb3NfYmliOiBwcmludCh0KCJyZXNfYmliX2lnbm9yYWRvcyIp
REM LmZvcm1hdChsZW4oaWdub3JhZG9zX2JpYikpKTsgW3ByaW50KHUiICAtIHswfSAoezF9KSIu
REM Zm9ybWF0KGEsYikpIGZvciBhLGIgaW4gaWdub3JhZG9zX2JpYl0KICAgICAgICBpZiBub3Zv
REM c19iaWI6IHByaW50KHQoInJlc19iaWJfbm92b3MiKS5mb3JtYXQobGVuKG5vdm9zX2JpYikp
REM KTsgW3ByaW50KHUiICAtIHswfSAtPiB7MX0gKHsyfSkiLmZvcm1hdChhLGIsYykpIGZvciBh
REM LGIsYyBpbiBub3Zvc19iaWJdCiAgICBfYXVkaXRhcl9jb2JlcnR1cmFfb3JhY3VsbyhtYXBh
REM X2NvbXBsZXRvLCBjYW5kaWRhdG9zPWNhbmRpZGF0b3MsIGlnbm9yYWRvc19iaWI9aWdub3Jh
REM ZG9zX2JpYikKICAgIHByaW50KCIiKTsgcHJpbnQodCgiaW1wMSIpLmZvcm1hdChOT01FX01B
REM UEEpKTsgcHJpbnQodCgiaW1wMiIpLmZvcm1hdChQQVNUQV9FTlRSQURBX05PTUUpKTsgcHJp
REM bnQodCgiaW1wMyIpKTsgcHJpbnQodCgiaW1wNCIpKTsgcHJpbnQodCgiaW1wNSIpKTsgcHJp
REM bnQodCgiaW1wNiIpKQogICAgbG9nLnNlcGFyYWRvcigpOyBsb2cucmVzdWx0YWRvKHQoImxv
REM Z19yZXNfZXNjYW5lYWRvcyIpLHN0cihhcnF1aXZvc19lbmNvbnRyYWRvcykpOyBsb2cucmVz
REM dWx0YWRvKHUiQXJxdWl2b3MgYW5hbGlzYWRvcyIsc3RyKGFycXVpdm9zX2FuYWxpc2Fkb3Mp
REM KTsgbG9nLnJlc3VsdGFkbyh1IkFycXVpdm9zIGV4dHJhw61kb3MiLHN0cih0b3RhbF9jb21f
REM ZGlhbG9nbykpOyBsb2cucmVzdWx0YWRvKHQoImxvZ19yZXNfc2VtX2RpYWxvZ28iKSxzdHIo
REM bGVuKHZhemlvcykpKTsgbG9nLnJlc3VsdGFkbyh0KCJsb2dfcmVzX2xpbmhhcyIpLHN0cih0
REM b3RhbF9saW5oYXMpKTsgbG9nLnJlc3VsdGFkbyh0KCJsb2dfcmVzX2JpYl9pZ25vcmFkb3Mi
REM KSxzdHIobGVuKGlnbm9yYWRvc19iaWIpKSk7IGxvZy5yZXN1bHRhZG8odCgibG9nX3Jlc19i
REM aWJfbm92b3MiKSxzdHIobGVuKG5vdm9zX2JpYikpKTsgbG9nLnJlc3VsdGFkbyh0KCJsb2df
REM cmVzX2Vycm9zIiksc3RyKHRvdGFsX2Vycm9zKSk7CiAgICBsb2cucmVzdWx0YWRvKHUiT3LD
REM oWN1bG8gUmVuJ1B5IGF0aXZvIiwgdSJTSU0iIGlmIE9SQUNVTE9fUkVOUFlbImF0aXZvIl0g
REM ZWxzZSB1Ik7Dg08iKQogICAgaWYgT1JBQ1VMT19SRU5QWVsiYXRpdm8iXToKICAgICAgICBj
REM b2JlcnR1cmFfdG90YWwgPSBPUkFDVUxPX1JFTlBZLmdldCgibmF0aXZhc19lbV9lc2NvcG8i
REM LCAwKQogICAgICAgIGNvYmVydHVyYV9yZWFsID0gT1JBQ1VMT19SRU5QWS5nZXQoIm5hdGl2
REM YXNfY29iZXJ0dXJhX3JlYWwiLCAwKQogICAgICAgIGNvYmVydHVyYV9wY3QgPSBPUkFDVUxP
REM X1JFTlBZLmdldCgibmF0aXZhc19jb2JlcnR1cmFfcGN0IiwgKDEwMC4wICogY29iZXJ0dXJh
REM X3JlYWwgLyBjb2JlcnR1cmFfdG90YWwpIGlmIGNvYmVydHVyYV90b3RhbCBlbHNlIDEwMC4w
REM KQogICAgICAgIGxvZy5yZXN1bHRhZG8odSJPcsOhY3VsbyBSZW4nUHkgLSBTREsiLCBPUkFD
REM VUxPX1JFTlBZWyJzZGsiXSk7IGxvZy5yZXN1bHRhZG8odSJPcsOhY3VsbyBSZW4nUHkgLSB2
REM ZXJzw6NvIiwgT1JBQ1VMT19SRU5QWVsidmVyc2FvIl0pOyBsb2cucmVzdWx0YWRvKHUiT3LD
REM oWN1bG8gUmVuJ1B5IC0gZW50cmFkYXMgbmF0aXZhcyIsIHN0cihPUkFDVUxPX1JFTlBZWyJu
REM YXRpdmFzX3RvdGFsIl0pKTsgbG9nLnJlc3VsdGFkbyh1Ik9yw6FjdWxvIFJlbidQeSAtIGNh
REM bmRpZGF0b3MgZW0gZXNjb3BvIiwgc3RyKE9SQUNVTE9fUkVOUFkuZ2V0KCJuYXRpdmFzX2Vt
REM X2VzY29wbyIsIDApKSk7IGxvZy5yZXN1bHRhZG8odSJPcsOhY3VsbyBSZW4nUHkgLSBjb3Jy
REM ZXNwb25kw6puY2lhIGV4YXRhIGFycXVpdm8rbGluaGErdGV4dG8iLCBzdHIoT1JBQ1VMT19S
REM RU5QWS5nZXQoIm5hdGl2YXNfY29ycmVzcG9uZGVuY2lhX2V4YXRhIiwgMCkpKTsgbG9nLnJl
REM c3VsdGFkbyh1Ik9yw6FjdWxvIFJlbidQeSAtIGNvcnJlc3BvbmTDqm5jaWEgZmFsbGJhY2sg
REM YXJxdWl2byt0ZXh0byIsIHN0cihPUkFDVUxPX1JFTlBZLmdldCgibmF0aXZhc19mYWxsYmFj
REM a190ZXh0byIsIDApKSk7IGxvZy5yZXN1bHRhZG8odSJPcsOhY3VsbyBSZW4nUHkgLSBhw6fD
REM tWVzIGRlIGluamXDp8OjbyBEREFDIiwgc3RyKE9SQUNVTE9fUkVOUFlbIm5hdGl2YXNfbWFw
REM ZWFkYXMiXSkpOyBsb2cucmVzdWx0YWRvKHUiT3LDoWN1bG8gUmVuJ1B5IC0gZW50cmFkYXMg
REM asOhIGV4aXN0ZW50ZXMgbm8gbWFwYSIsIHN0cihPUkFDVUxPX1JFTlBZWyJuYXRpdmFzX2R1
REM cGxpY2FkYXMiXSkpOyBsb2cucmVzdWx0YWRvKHUiT3LDoWN1bG8gUmVuJ1B5IC0gZm9yYSBk
REM byBlc2NvcG8vZmlsdHJvIHTDqWNuaWNvIiwgc3RyKE9SQUNVTE9fUkVOUFkuZ2V0KCJuYXRp
REM dmFzX2ZvcmFfZXNjb3BvIiwgMCkpKTsgbG9nLnJlc3VsdGFkbyh1Ik9yw6FjdWxvIFJlbidQ
REM eSAtIGFtYsOtZ3VhcyIsIHN0cihPUkFDVUxPX1JFTlBZWyJuYXRpdmFzX2FtYmlndWFzIl0p
REM KTsgbG9nLnJlc3VsdGFkbyh1Ik9yw6FjdWxvIFJlbidQeSAtIG11bHRpbGluaGEiLCBzdHIo
REM T1JBQ1VMT19SRU5QWVsibmF0aXZhc19tdWx0aWxpbmhhIl0pKTsgbG9nLnJlc3VsdGFkbyh1
REM Ik9yw6FjdWxvIFJlbidQeSAtIGNvcnJlc3BvbmTDqm5jaWEgcmVhbCBTREvihpRtYXBhIiwg
REM dSJ7MH0vezF9ICh7MjouMWZ9JSkiLmZvcm1hdChjb2JlcnR1cmFfcmVhbCwgY29iZXJ0dXJh
REM X3RvdGFsLCBjb2JlcnR1cmFfcGN0KSk7IGxvZy5yZXN1bHRhZG8odSJPcsOhY3VsbyBSZW4n
REM UHkgLSBjYW5kaWRhdG9zIG5hdGl2b3Mgc2VtIGNvcnJlc3BvbmTDqm5jaWEgbm8gbWFwYSIs
REM IHN0cihPUkFDVUxPX1JFTlBZWyJuYXRpdmFzX25hb19sb2NhbGl6YWRhcyJdKSk7CiAgICAg
REM ICAgZm9yIGFtb3N0cmEgaW4gT1JBQ1VMT19SRU5QWS5nZXQoIm5hdGl2YXNfbmFvX2xvY2Fs
REM aXphZGFzX2Ftb3N0cmFzIiwgW10pOiBsb2cuaW5mbyh1IltPUsOBQ1VMTyBBVURJVE9SSUFd
REM ICIgKyBhbW9zdHJhKQogICAgbG9nLnJlc3VsdGFkbyh1IlRlbXBvIHRvdGFsIix1InswOi4x
REM Zn1zIi5mb3JtYXQoZGVjb3JyaWRvKSk7IGxvZy5yZXN1bHRhZG8odSJWZWxvY2lkYWRlIG3D
REM qWRpYSIsdSJ7MDouMWZ9IHRleHRvcy9zIi5mb3JtYXQodmVsb2NpZGFkZSkpOyBsb2cuc2Vw
REM YXJhZG9yKCk7IGxvZy5zYWx2YXIoKTsgcHJpbnQoIiIpOyBwcmludCh0KCJsb2dfc2Fsdm8i
REM KS5mb3JtYXQobG9nLmNhbWluaG8pKTsgcmV0dXJuIDAKCmRlZiBsZXJfdGV4dG9zX3RyYWR1
REM emlkb3MoY2FtaW5obyk6CiAgICB3aXRoIGlvLm9wZW4oY2FtaW5obywgInIiLCBlbmNvZGlu
REM Zz0idXRmLTgiLCBlcnJvcnM9InJlcGxhY2UiKSBhcyBmOgogICAgICAgIGNvbnRldWRvID0g
REM Zi5yZWFkKCkKICAgIGlmIGNvbnRldWRvLmVuZHN3aXRoKHUiXG4iKToKICAgICAgICBjb250
REM ZXVkbyA9IGNvbnRldWRvWzotMV0KICAgIGlmIGNvbnRldWRvID09IHUiIjoKICAgICAgICBy
REM ZXR1cm4gW10KICAgIGxpbmhhcyA9IGNvbnRldWRvLnNwbGl0KHUiXG4iKQogICAgdXRlaXMg
REM PSBbXQogICAgZm9yIGwgaW4gbGluaGFzOgogICAgICAgIGRlc3BpZG8gPSBsLnN0cmlwKCkK
REM ICAgICAgICBpZiBub3QgZGVzcGlkbzoKICAgICAgICAgICAgY29udGludWUKICAgICAgICBp
REM ZiBkZXNwaWRvLnN0YXJ0c3dpdGgodSIjIik6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAg
REM ICAgdXRlaXMuYXBwZW5kKGRlc3BpZG8pCiAgICByZXR1cm4gdXRlaXMKCgpkZWYgY29sZXRh
REM cl9jYW5kaWRhdG9zX3JlaW5qZWNhbyhwYXN0YV9lbnRyYWRhKToKICAgIGNhbmRpZGF0b3Mg
REM PSBbXQogICAgbWFwYXMgPSBzZXQoTUFQQVNfQ09NUEFUSVZFSVMpCiAgICBtYXBhX2NoYXZl
REM cyA9IE5vbmUKICAgIHRyeToKICAgICAgICBtYXBhX25vbWUgPSBuZXh0KChuIGZvciBuIGlu
REM IE1BUEFTX0NPTVBBVElWRUlTIGlmIG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9pbihwYXN0
REM YV9lbnRyYWRhLCBuKSkpLCBOb25lKQogICAgICAgIGlmIG1hcGFfbm9tZToKICAgICAgICAg
REM ICAgd2l0aCBpby5vcGVuKG9zLnBhdGguam9pbihwYXN0YV9lbnRyYWRhLCBtYXBhX25vbWUp
REM LCAiciIsIGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6CiAgICAgICAgICAgICAgICBtYXBhID0g
REM anNvbi5sb2FkKGYpCiAgICAgICAgICAgIGlmIGlzaW5zdGFuY2UobWFwYSwgZGljdCk6CiAg
REM ICAgICAgICAgICAgICBtYXBhX2NoYXZlcyA9IHNldChfZHVhbF9ub3JtX3JlbChrKSBmb3Ig
REM ayBpbiBtYXBhLmtleXMoKSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgbWFwYV9j
REM aGF2ZXMgPSBOb25lCiAgICBmb3IgcGFzdGFfYXR1YWwsIHN1YnBhc3RhcywgYXJxdWl2b3Mg
REM aW4gb3Mud2FsayhwYXN0YV9lbnRyYWRhKToKICAgICAgICBmb3Igbm9tZSBpbiBhcnF1aXZv
REM czoKICAgICAgICAgICAgaWYgbm9tZSBpbiBtYXBhczoKICAgICAgICAgICAgICAgIGNvbnRp
REM bnVlCiAgICAgICAgICAgIGNhbWluaG8gPSBvcy5wYXRoLmpvaW4ocGFzdGFfYXR1YWwsIG5v
REM bWUpCiAgICAgICAgICAgIHJlbCA9IF9kdWFsX25vcm1fcmVsKG9zLnBhdGgucmVscGF0aChj
REM YW1pbmhvLCBwYXN0YV9lbnRyYWRhKSkKICAgICAgICAgICAgaWYgbWFwYV9jaGF2ZXMgaXMg
REM bm90IE5vbmUgYW5kIHJlbCBub3QgaW4gbWFwYV9jaGF2ZXM6CiAgICAgICAgICAgICAgICBj
REM b250aW51ZQogICAgICAgICAgICBjYW5kaWRhdG9zLmFwcGVuZChjYW1pbmhvKQogICAgY2Fu
REM ZGlkYXRvcy5zb3J0KGtleT1sYW1iZGEgeDogeC5sb3dlcigpKQogICAgcmV0dXJuIGNhbmRp
REM ZGF0b3MKCgpkZWYgX2NvbnRhcl9hc3Bhc19uYW9fZXNjYXBhZGFzKHRleHRvLCBjYXJhY3Rl
REM cmUpOgogICAgdG90YWwgPSAwCiAgICBpID0gMAogICAgd2hpbGUgaSA8IGxlbih0ZXh0byk6
REM CiAgICAgICAgaWYgdGV4dG9baV0gPT0gdSdcXCc6CiAgICAgICAgICAgIGkgKz0gMgogICAg
REM ICAgICAgICBjb250aW51ZQogICAgICAgIGlmIHRleHRvW2ldID09IGNhcmFjdGVyZToKICAg
REM ICAgICAgICAgdG90YWwgKz0gMQogICAgICAgIGkgKz0gMQogICAgcmV0dXJuIHRvdGFsCgoK
REM ZGVmIF92YWxpZGFyX2ZyYWdtZW50b19tdWx0aWxpbmhhX2NvbXBhdChvcmlnaW5hbCwgdHJh
REM ZHV6aWRvKToKICAgIGlmIHUnXG4nIGluIHRyYWR1emlkbyBvciB1J1xyJyBpbiB0cmFkdXpp
REM ZG86CiAgICAgICAgcmV0dXJuIEZhbHNlLCAncXVlYnJhX2Zpc2ljYScKICAgIGRxX28gPSBf
REM Y29udGFyX2FzcGFzX25hb19lc2NhcGFkYXMob3JpZ2luYWwsIHUnIicpCiAgICBzcV9vID0g
REM X2NvbnRhcl9hc3Bhc19uYW9fZXNjYXBhZGFzKG9yaWdpbmFsLCB1IiciKQogICAgaWYgdSci
REM IiInIG5vdCBpbiBvcmlnaW5hbCBhbmQgdSInJyciIG5vdCBpbiBvcmlnaW5hbCBhbmQgKChk
REM cV9vICUgMikgb3IgKHNxX28gJSAyKSk6CiAgICAgICAgcmV0dXJuIEZhbHNlLCAnbWFwYV9s
REM ZWdhZG9fdHJ1bmNhZG8nCiAgICBkcV90ID0gX2NvbnRhcl9hc3Bhc19uYW9fZXNjYXBhZGFz
REM KHRyYWR1emlkbywgdSciJykKICAgIHNxX3QgPSBfY29udGFyX2FzcGFzX25hb19lc2NhcGFk
REM YXModHJhZHV6aWRvLCB1IiciKQogICAgaWYgZHFfbyAhPSBkcV90IG9yIHNxX28gIT0gc3Ff
REM dDoKICAgICAgICByZXR1cm4gRmFsc2UsICdhc3Bhc19lc3RydXR1cmFpc19hbHRlcmFkYXMn
REM CiAgICBmb3IgcSBpbiAodSciIiInLCB1IicnJyIpOgogICAgICAgIGlmIHEgaW4gb3JpZ2lu
REM YWwgYW5kIHEgbm90IGluIHRyYWR1emlkbzoKICAgICAgICAgICAgcmV0dXJuIEZhbHNlLCAn
REM ZGVsaW1pdGFkb3JfdHJpcGxvX2FsdGVyYWRvJwogICAgaWYgb3JpZ2luYWwucnN0cmlwKCku
REM ZW5kc3dpdGgodSdcXCcpIGFuZCBub3QgdHJhZHV6aWRvLnJzdHJpcCgpLmVuZHN3aXRoKHUn
REM XFwnKToKICAgICAgICByZXR1cm4gRmFsc2UsICdiYXJyYV9jb250aW51YWNhb19hbHRlcmFk
REM YScKICAgIHJldHVybiBUcnVlLCBOb25lCgoKZGVmIHJlaW5qZXRhcl9hcnF1aXZvKGNhbWlu
REM aG9fb3JpZ2luYWwsIGVudHJhZGFzX21hcGEsIHRleHRvc190cmFkdXppZG9zKToKICAgIGVy
REM cm9zID0gW10KICAgIGF2aXNvc19jb21wYXQgPSAwCgogICAgaWYgbGVuKGVudHJhZGFzX21h
REM cGEpICE9IGxlbih0ZXh0b3NfdHJhZHV6aWRvcyk6CiAgICAgICAgZXJyb3MuYXBwZW5kKHQo
REM InJqX2NvbnRhZ2VtIikuZm9ybWF0KGxlbihlbnRyYWRhc19tYXBhKSwgbGVuKHRleHRvc190
REM cmFkdXppZG9zKSkpCiAgICAgICAgcmV0dXJuIE5vbmUsIGVycm9zCgogICAgaWYgbm90IG9z
REM LnBhdGguaXNmaWxlKGNhbWluaG9fb3JpZ2luYWwpOgogICAgICAgIGVycm9zLmFwcGVuZCh0
REM KCJyal9zZW1fb3JpZ2luYWwiKS5mb3JtYXQoY2FtaW5ob19vcmlnaW5hbCkpCiAgICAgICAg
REM cmV0dXJuIE5vbmUsIGVycm9zCgogICAgbGluaGFzX3JhdyA9IGxlcl9saW5oYXNfcmF3KGNh
REM bWluaG9fb3JpZ2luYWwpCgogICAgZm9yIGVudHJhZGEgaW4gZW50cmFkYXNfbWFwYToKICAg
REM ICAgICBudW1lcm9fbGluaGEgPSBlbnRyYWRhWyJsaW5oYSJdCiAgICAgICAgaWYgbnVtZXJv
REM X2xpbmhhIDwgMSBvciBudW1lcm9fbGluaGEgPiBsZW4obGluaGFzX3Jhdyk6CiAgICAgICAg
REM ICAgIGVycm9zLmFwcGVuZCh0KCJyal9saW5oYV9pbmV4aXN0ZW50ZSIpLmZvcm1hdChudW1l
REM cm9fbGluaGEpKQogICAgICAgICAgICBjb250aW51ZQogICAgICAgIGxpbmhhX3NlbV9maW0g
REM PSBsaW5oYXNfcmF3W251bWVyb19saW5oYSAtIDFdLnJzdHJpcCgiXHJcbiIpCiAgICAgICAg
REM dHJlY2hvX2F0dWFsID0gbGluaGFfc2VtX2ZpbVtlbnRyYWRhWyJjb2x1bmFfaW5pY2lvIl06
REM ZW50cmFkYVsiY29sdW5hX2ZpbSJdXQogICAgICAgIGlmIHRyZWNob19hdHVhbCAhPSBlbnRy
REM YWRhWyJvcmlnaW5hbCJdOgogICAgICAgICAgICBlcnJvcy5hcHBlbmQodCgicmpfbGluaGFf
REM bXVkb3UiKS5mb3JtYXQoCiAgICAgICAgICAgICAgICBudW1lcm9fbGluaGEsIGVudHJhZGFb
REM ImNvbHVuYV9pbmljaW8iXSwgZW50cmFkYVsiY29sdW5hX2ZpbSJdLAogICAgICAgICAgICAg
REM ICAgZW50cmFkYVsib3JpZ2luYWwiXSwgdHJlY2hvX2F0dWFsCiAgICAgICAgICAgICkpCgog
REM ICAgaWYgZXJyb3M6CiAgICAgICAgcmV0dXJuIE5vbmUsIGVycm9zCgogICAgcGFyZXNfcmVp
REM bmplY2FvLCBfY29uZmxpdG9zX3NvYnJlcG9zaWNhbyA9IF9yZXNvbHZlcl9zb2JyZXBvc2lj
REM b2VzX21hcGEoCiAgICAgICAgZW50cmFkYXNfbWFwYSwgdGV4dG9zX3RyYWR1emlkb3MKICAg
REM ICkKICAgIHBvcl9saW5oYSA9IHt9CiAgICBmb3IgZW50cmFkYSwgdHJhZHV6aWRvIGluIHBh
REM cmVzX3JlaW5qZWNhbzoKICAgICAgICBwb3JfbGluaGEuc2V0ZGVmYXVsdChlbnRyYWRhWyJs
REM aW5oYSJdLCBbXSkuYXBwZW5kKChlbnRyYWRhLCB0cmFkdXppZG8pKQoKICAgIGxpbmhhc19y
REM ZXN1bHRhZG8gPSBsaXN0KGxpbmhhc19yYXcpCgogICAgZm9yIG51bWVyb19saW5oYSwgaXRl
REM bnMgaW4gcG9yX2xpbmhhLml0ZW1zKCk6CiAgICAgICAgbGluaGFfcmF3ID0gbGluaGFzX3Jl
REM c3VsdGFkb1tudW1lcm9fbGluaGEgLSAxXQogICAgICAgIGxpbmhhX3NlbV9maW0gPSBsaW5o
REM YV9yYXcucnN0cmlwKCJcclxuIikKICAgICAgICBmaW0gPSBsaW5oYV9yYXdbbGVuKGxpbmhh
REM X3NlbV9maW0pOl0KCiAgICAgICAgaXRlbnNfb3JkZW5hZG9zID0gc29ydGVkKGl0ZW5zLCBr
REM ZXk9bGFtYmRhIHBhcjogcGFyWzBdWyJjb2x1bmFfaW5pY2lvIl0sIHJldmVyc2U9VHJ1ZSkK
REM ICAgICAgICBub3ZhX2xpbmhhID0gbGluaGFfc2VtX2ZpbQogICAgICAgIGZvciBlbnRyYWRh
REM LCB0cmFkdXppZG8gaW4gaXRlbnNfb3JkZW5hZG9zOgogICAgICAgICAgICB0aXBvX2VudHJh
REM ZGEgPSBlbnRyYWRhLmdldCgidGlwbyIpCiAgICAgICAgICAgICMgQ29tcGF0aWJpbGlkYWRl
REM IGNvbSBtYXBhcyBhbnRpZ29zOiBvIHNjYW5uZXIgZGUgdmVyc8O1ZXMgYW50ZXJpb3Jlcwog
REM ICAgICAgICAgICAjIHBvZGlhIGNsYXNzaWZpY2FyIGPDs2RpZ28gUHl0aG9uIGRlIHBvZW1f
REM cmVzcG9uc2VzL3B5L3BvZW1zLnJweSBjb21vCiAgICAgICAgICAgICMgbXVsdGlsaW5oYV9y
REM ZW5weS4gRXNzZXMgdHJlY2hvcyBqYW1haXMgZGV2ZW0gc2VyIHRyYWR1emlkb3MvcmVpbmpl
REM dGFkb3MuCiAgICAgICAgICAgICMgQ29ycG9zIHJlYWlzIGRlIHBvZW1hIGNvbnRpbnVhbSBz
REM ZW5kbyBwb2VtYV9jb3Jwby4KICAgICAgICAgICAgaWYgKF9laF9hcnF1aXZvX2JhbmNvX3Bv
REM ZW1hc19weXRob24oY2FtaW5ob19vcmlnaW5hbCkgYW5kCiAgICAgICAgICAgICAgICAgICAg
REM dGlwb19lbnRyYWRhIGluICgibXVsdGlsaW5oYV9yZW5weSIsICJtb25vbG9nb190cmlwbGFz
REM IiwgImdldHRleHRfbXVsdGlsaW5oYSIpKToKICAgICAgICAgICAgICAgIG9yaWdpbmFsX2xl
REM Z2FkbyA9IGVudHJhZGEuZ2V0KCJvcmlnaW5hbCIsIHUiIikKICAgICAgICAgICAgICAgIGNv
REM ZGlnb19wb2VtYV9sZWdhZG8gPSAoCiAgICAgICAgICAgICAgICAgICAgcmUubWF0Y2gocide
REM XHMqcG9lbV9kYlxzKlwuXHMqYWRkX3BvZW1ccypcKCcsIG9yaWdpbmFsX2xlZ2FkbywgcmUu
REM SSkgb3IKICAgICAgICAgICAgICAgICAgICByZS5tYXRjaChyJ15ccyphdXRob3JfW0EtWmEt
REM ejAtOV9dK1xzKixccyokJywgb3JpZ2luYWxfbGVnYWRvLCByZS5JKSBvcgogICAgICAgICAg
REM ICAgICAgICAgIHJlLm1hdGNoKHInXlxzKnRpdGxlXHMqPScsIG9yaWdpbmFsX2xlZ2Fkbywg
REM cmUuSSkgb3IKICAgICAgICAgICAgICAgICAgICByZS5tYXRjaChyJ15ccyp0ZXh0XHMqPScs
REM IG9yaWdpbmFsX2xlZ2FkbywgcmUuSSkgb3IKICAgICAgICAgICAgICAgICAgICByZS5tYXRj
REM aChyJ15ccyp0cmFuc2xhdGVccyo9Jywgb3JpZ2luYWxfbGVnYWRvLCByZS5JKSBvcgogICAg
REM ICAgICAgICAgICAgICAgIHJlLm1hdGNoKHInXlxzKiJwb2VtX1tBLVphLXowLTlfXSsiXHMq
REM LFxzKiQnLCBvcmlnaW5hbF9sZWdhZG8sIHJlLkkpIG9yCiAgICAgICAgICAgICAgICAgICAg
REM JyIiIicgaW4gb3JpZ2luYWxfbGVnYWRvIG9yICgnIicgKiAzKSBpbiBvcmlnaW5hbF9sZWdh
REM ZG8KICAgICAgICAgICAgICAgICkKICAgICAgICAgICAgICAgIGlmIGNvZGlnb19wb2VtYV9s
REM ZWdhZG86CiAgICAgICAgICAgICAgICAgICAgYXZpc29zX2NvbXBhdCArPSAxCiAgICAgICAg
REM ICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgaWYgdGlwb19lbnRyYWRhID09ICJw
REM b2VtYV9jb3JwbyI6CiAgICAgICAgICAgICAgICB0cmFkdXppZG8gPSBkZWNvZGlmaWNhcl90
REM ZXh0b19leHRyYWlkbyh0cmFkdXppZG8pCiAgICAgICAgICAgIGVsaWYgdGlwb19lbnRyYWRh
REM IGluICgibXVsdGlsaW5oYV9yZW5weSIsICJtb25vbG9nb190cmlwbGFzIiwgImdldHRleHRf
REM bXVsdGlsaW5oYSIpOgogICAgICAgICAgICAgICAgIyBFc3NlcyBtYXBhcyByZXByZXNlbnRh
REM bSB1bSBmcmFnbWVudG8gZsOtc2ljbyBzZW0gYXMgYXNwYXMsIHBvaXMKICAgICAgICAgICAg
REM ICAgICMgbyBsaXRlcmFsIGV4dGVybm8gY29udGludWEgYWJlcnRvIG5vIC5ycHkgb3JpZ2lu
REM YWwuCiAgICAgICAgICAgICAgICB0cmFkdXppZG8gPSBkZWNvZGlmaWNhcl9saXRlcmFsX3Ry
REM YWR1Y2FvKHRyYWR1emlkbykKICAgICAgICAgICAgZWxpZiB0aXBvX2VudHJhZGEgPT0gInBv
REM ZW1hX3BhbGF2cmFfdHh0IjoKICAgICAgICAgICAgICAgIHRyYWR1emlkbyA9IGRlY29kaWZp
REM Y2FyX2xpdGVyYWxfdHJhZHVjYW8odHJhZHV6aWRvKQogICAgICAgICAgICAgICAgaWYgJ1xu
REM JyBpbiB0cmFkdXppZG8gb3IgJ1xyJyBpbiB0cmFkdXppZG8gb3IgJywnIGluIHRyYWR1emlk
REM byBvciAnIycgaW4gdHJhZHV6aWRvOgogICAgICAgICAgICAgICAgICAgIGVycm9zLmFwcGVu
REM ZCh1IlRyYWR1w6fDo28gaW52w6FsaWRhIHBhcmEgcGFsYXZyYSBkZSBwb2VtYSBuYSBsaW5o
REM YSB7MH06IG8gcmVzdWx0YWRvIGNvbnTDqW0gdsOtcmd1bGEsIGNvbWVudMOhcmlvIG91IHF1
REM ZWJyYSBkZSBsaW5oYS4iLmZvcm1hdChlbnRyYWRhLmdldCgibGluaGEiLCB1Ij8iKSkpCiAg
REM ICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgaWYgdHJhZHV6aWRvID09
REM IGVudHJhZGEuZ2V0KCJvcmlnaW5hbCIpOgogICAgICAgICAgICAgICAgY29udGludWUKICAg
REM ICAgICAgICAgIyBUcmFkdXppZG8gY2hlZ2EgY29tbyBsaXRlcmFsIGNhbsO0bmljbyAobm9y
REM bWFsbWVudGUgZW50cmUgYXNwYXMgZHVwbGFzKS4KICAgICAgICAgICAgIyBSZWVzY3JldmVt
REM b3MgdXNhbmRvIG8gbWVzbW8gZGVsaW1pdGFkb3IvcHJlZml4byBkbyBsaXRlcmFsIG9yaWdp
REM bmFsLgogICAgICAgICAgICBpZiB0aXBvX2VudHJhZGEgbm90IGluICgicG9lbWFfcGFsYXZy
REM YV90eHQiLCAicG9lbWFfY29ycG8iLCAibXVsdGlsaW5oYV9yZW5weSIsICJtb25vbG9nb190
REM cmlwbGFzIiwgImdldHRleHRfbXVsdGlsaW5oYSIpOgogICAgICAgICAgICAgICAgdHJ5Ogog
REM ICAgICAgICAgICAgICAgICAgIHRyYWR1emlkbyA9IGNvZGlmaWNhcl9saXRlcmFsX2NvbV9m
REM b3JtYXRvKGVudHJhZGEuZ2V0KCJvcmlnaW5hbCIsIHUnIiInKSwgZGVjb2RpZmljYXJfbGl0
REM ZXJhbF90cmFkdWNhbyh0cmFkdXppZG8pKQogICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2Vw
REM dGlvbjoKICAgICAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIGlmIHRpcG9fZW50
REM cmFkYSA9PSAicG9lbWFfcGFsYXZyYV90eHQiOgogICAgICAgICAgICAgICAgbm92YV9saW5o
REM YSA9ICgKICAgICAgICAgICAgICAgICAgICBub3ZhX2xpbmhhWzplbnRyYWRhWyJjb2x1bmFf
REM aW5pY2lvIl1dCiAgICAgICAgICAgICAgICAgICAgKyB0cmFkdXppZG8KICAgICAgICAgICAg
REM ICAgICAgICArIG5vdmFfbGluaGFbZW50cmFkYVsiY29sdW5hX2ZpbSJdOl0KICAgICAgICAg
REM ICAgICAgICkKICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgIGlmIGVudHJh
REM ZGEuZ2V0KCJ0aXBvIikgbm90IGluICgicG9lbWFfY29ycG8iLCAibXVsdGlsaW5oYV9yZW5w
REM eSIsICJtb25vbG9nb190cmlwbGFzIiwgImdldHRleHRfbXVsdGlsaW5oYSIpIGFuZCBub3Qg
REM bGl0ZXJhbF91bmljb190cmFkdXppdmVsKGVudHJhZGEuZ2V0KCJvcmlnaW5hbCIsIHUiIikp
REM OgogICAgICAgICAgICAgICAgZXJyb3MuYXBwZW5kKHUiTWFwYSBpbnbDoWxpZG86IGVudHJh
REM ZGEgbsOjbyDDqSB1bSBsaXRlcmFsIMO6bmljbyBuYSBsaW5oYSB7MH0uIi5mb3JtYXQoZW50
REM cmFkYS5nZXQoImxpbmhhIiwgdSI/IikpKQogICAgICAgICAgICAgICAgY29udGludWUKICAg
REM ICAgICAgICAgaWYgZW50cmFkYS5nZXQoInRpcG8iKSBpbiAoIm11bHRpbGluaGFfcmVucHki
REM LCAibW9ub2xvZ29fdHJpcGxhcyIsICJnZXR0ZXh0X211bHRpbGluaGEiKToKICAgICAgICAg
REM ICAgICAgIG9rX211bHRpLCBtb3Rpdm9fbXVsdGkgPSBfdmFsaWRhcl9mcmFnbWVudG9fbXVs
REM dGlsaW5oYV9jb21wYXQoZW50cmFkYS5nZXQoIm9yaWdpbmFsIiwgdSIiKSwgdHJhZHV6aWRv
REM KQogICAgICAgICAgICAgICAgaWYgbm90IG9rX211bHRpOgogICAgICAgICAgICAgICAgICAg
REM IGlmIG1vdGl2b19tdWx0aSA9PSAnbWFwYV9sZWdhZG9fdHJ1bmNhZG8nOgogICAgICAgICAg
REM ICAgICAgICAgICAgICBhdmlzb3NfY29tcGF0ICs9IDEKICAgICAgICAgICAgICAgICAgICAg
REM ICAgY29udGludWUKICAgICAgICAgICAgICAgICAgICBlcnJvcy5hcHBlbmQodSJUcmFkdcOn
REM w6NvIGludsOhbGlkYTogZnJhZ21lbnRvIG11bHRpbGluaGEgaW5jb21wYXTDrXZlbCAoezB9
REM KSBuYSBsaW5oYSB7MX0uIi5mb3JtYXQobW90aXZvX211bHRpLCBlbnRyYWRhLmdldCgibGlu
REM aGEiLCB1Ij8iKSkpCiAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAg
REM ZWxpZiBlbnRyYWRhLmdldCgidGlwbyIpICE9ICJwb2VtYV9jb3JwbyIgYW5kIG5vdCBsaXRl
REM cmFsX3VuaWNvX3RyYWR1eml2ZWwodHJhZHV6aWRvKToKICAgICAgICAgICAgICAgIGVycm9z
REM LmFwcGVuZCh1IlRyYWR1w6fDo28gaW52w6FsaWRhOiByZXN1bHRhZG8gY29udMOpbSBzaW50
REM YXhlIGZvcmEgZG8gbGl0ZXJhbCBuYSBsaW5oYSB7MH0uIi5mb3JtYXQoZW50cmFkYS5nZXQo
REM ImxpbmhhIiwgdSI/IikpKQogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAg
REM dHJhZHV6aWRvID0gbm9ybWFsaXphcl9wZXJjZW50dWFpc19wYXJhX3JlaW50ZWdyYWNhbyhl
REM bnRyYWRhLmdldCgib3JpZ2luYWwiLCB1IiIpLCB0cmFkdXppZG8pCiAgICAgICAgICAgIG5v
REM dmFfbGluaGEgPSAoCiAgICAgICAgICAgICAgICBub3ZhX2xpbmhhWzplbnRyYWRhWyJjb2x1
REM bmFfaW5pY2lvIl1dCiAgICAgICAgICAgICAgICArIHRyYWR1emlkbwogICAgICAgICAgICAg
REM ICAgKyBub3ZhX2xpbmhhW2VudHJhZGFbImNvbHVuYV9maW0iXTpdCiAgICAgICAgICAgICkK
REM CiAgICAgICAgbGluaGFzX3Jlc3VsdGFkb1tudW1lcm9fbGluaGEgLSAxXSA9IG5vdmFfbGlu
REM aGEgKyBmaW0KCiAgICBpZiBhdmlzb3NfY29tcGF0OgogICAgICAgIHByaW50KHUiW0FWSVNP
REM XSBDb21wYXRpYmlsaWRhZGU6IHswfSBmcmFnbWVudG8ocykgZGUgbWFwYSBsZWdhZG8gdHJ1
REM bmNhZG8ocykgZm9yYW0gcHJlc2VydmFkb3Mgbm8gb3JpZ2luYWwuIi5mb3JtYXQoYXZpc29z
REM X2NvbXBhdCkpCiAgICByZXR1cm4gbGluaGFzX3Jlc3VsdGFkbywgZXJyb3MKCgpkZWYgbm9y
REM bWFsaXphcl9ub21lX3Bhc3RhX211bHRpbGluZ3VlKG5vbWUpOgogICAgdGV4dG8gPSB1bmlj
REM b2RlZGF0YS5ub3JtYWxpemUoIk5GS0QiLCBub21lIG9yIHUiIikKICAgIHRleHRvID0gdSIi
REM LmpvaW4oY2ggZm9yIGNoIGluIHRleHRvIGlmIG5vdCB1bmljb2RlZGF0YS5jb21iaW5pbmco
REM Y2gpKQogICAgdGV4dG8gPSB0ZXh0by5jYXNlZm9sZCgpLnJlcGxhY2UodSJfIiwgdSItIikK
REM ICAgIHRleHRvID0gcmUuc3ViKHIiW15hLXowLTktXSsiLCB1Ii0iLCB0ZXh0bykKICAgIHRl
REM eHRvID0gcmUuc3ViKHIiLSsiLCB1Ii0iLCB0ZXh0bykuc3RyaXAodSItIikKICAgIHJldHVy
REM biB0ZXh0bwoKClBBU1RBU19ESUFMT0dPU19DQVRFR09SSUFTID0gewogICAgdSJleHRyYWNh
REM byI6IHsKICAgICAgICB1ImRkYWMtZGlhbG9nb3MtZXh0cmFpZG9zIiwKICAgICAgICB1ImRk
REM YWMtZXh0cmFjdGVkLWRpYWxvZ3VlcyIsCiAgICB9LAogICAgdSJ0cmFkdWNhbyI6IHsKICAg
REM ICAgICB1ImRkYWMtZGlhbG9nb3MtdHJhZHV6aWRvcyIsCiAgICAgICAgdSJkZGFjLWRpYWxv
REM Z29zLXRyYWR1Y2lkb3MiLAogICAgICAgIHUiZGRhYy10cmFuc2xhdGVkLWRpYWxvZ3VlcyIs
REM CiAgICB9LAogICAgdSJtZXNjbGFnZW0iOiB7CiAgICAgICAgdSJkZGFjLWRpYWxvZ29zLW1l
REM c2NsYWRvcyIsCiAgICAgICAgdSJkZGFjLWRpYWxvZ29zLW1lemNsYWRvcyIsCiAgICAgICAg
REM dSJkZGFjLW1lcmdlZC1kaWFsb2d1ZXMiLAogICAgfSwKfQoKCmRlZiBjbGFzc2lmaWNhcl9w
REM YXN0YV9kaWFsb2dvcyhjYW1pbmhvKToKICAgIG5vcm1hbGl6YWRvID0gbm9ybWFsaXphcl9u
REM b21lX3Bhc3RhX211bHRpbGluZ3VlKG9zLnBhdGguYmFzZW5hbWUob3MucGF0aC5ub3JtcGF0
REM aChjYW1pbmhvKSkpCiAgICBmb3IgY2F0ZWdvcmlhLCBub21lcyBpbiBQQVNUQVNfRElBTE9H
REM T1NfQ0FURUdPUklBUy5pdGVtcygpOgogICAgICAgIGlmIG5vcm1hbGl6YWRvIGluIG5vbWVz
REM OgogICAgICAgICAgICByZXR1cm4gY2F0ZWdvcmlhCiAgICByZXR1cm4gTm9uZQoKCmRlZiBs
REM aXN0YXJfcGFzdGFzX2RpYWxvZ29zX3Bvcl9jYXRlZ29yaWEocmFpeiwgY2F0ZWdvcmlhcyk6
REM CiAgICBlbmNvbnRyYWRvcyA9IFtdCiAgICB2aXN0b3MgPSBzZXQoKQogICAgZm9yIG5vbWUg
REM aW4gb3MubGlzdGRpcihyYWl6KToKICAgICAgICBjYW1pbmhvID0gb3MucGF0aC5qb2luKHJh
REM aXosIG5vbWUpCiAgICAgICAgaWYgbm90IG9zLnBhdGguaXNkaXIoY2FtaW5obyk6CiAgICAg
REM ICAgICAgIGNvbnRpbnVlCiAgICAgICAgY2F0ZWdvcmlhID0gY2xhc3NpZmljYXJfcGFzdGFf
REM ZGlhbG9nb3MoY2FtaW5obykKICAgICAgICBpZiBjYXRlZ29yaWEgbm90IGluIGNhdGVnb3Jp
REM YXM6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgY2hhdmUgPSBvcy5wYXRoLm5vcm1j
REM YXNlKG9zLnBhdGgubm9ybXBhdGgoY2FtaW5obykpCiAgICAgICAgaWYgY2hhdmUgaW4gdmlz
REM dG9zOgogICAgICAgICAgICBjb250aW51ZQogICAgICAgIG5vbWVfbWFwYSA9IE5vbmUKICAg
REM ICAgICBmb3Igbm9tZV9tYXBhX2NhbmRpZGF0byBpbiBNQVBBU19DT01QQVRJVkVJUzoKICAg
REM ICAgICAgICAgaWYgb3MucGF0aC5pc2ZpbGUob3MucGF0aC5qb2luKGNhbWluaG8sIG5vbWVf
REM bWFwYV9jYW5kaWRhdG8pKToKICAgICAgICAgICAgICAgIG5vbWVfbWFwYSA9IG5vbWVfbWFw
REM YV9jYW5kaWRhdG8KICAgICAgICAgICAgICAgIGJyZWFrCiAgICAgICAgaWYgbm9tZV9tYXBh
REM OgogICAgICAgICAgICB2aXN0b3MuYWRkKGNoYXZlKQogICAgICAgICAgICBlbmNvbnRyYWRv
REM cy5hcHBlbmQoKGNhbWluaG8sIG5vbWVfbWFwYSwgY2F0ZWdvcmlhKSkKICAgIGVuY29udHJh
REM ZG9zLnNvcnQoa2V5PWxhbWJkYSBpdGVtOiAoMCBpZiBpdGVtWzJdID09IHUiZXh0cmFjYW8i
REM IGVsc2UgMSwgbm9ybWFsaXphcl9ub21lX3Bhc3RhX211bHRpbGluZ3VlKG9zLnBhdGguYmFz
REM ZW5hbWUoaXRlbVswXSkpKSkKICAgIHJldHVybiBlbmNvbnRyYWRvcwoKZGVmIGxvY2FsaXph
REM cl9wYXN0YV9yZWluamVjYW8ocmFpeik6CiAgICBjYW5kaWRhdG9zID0gbGlzdGFyX3Bhc3Rh
REM c19kaWFsb2dvc19wb3JfY2F0ZWdvcmlhKHJhaXosIHt1ImV4dHJhY2FvIiwgdSJ0cmFkdWNh
REM byJ9KQogICAgaWYgbm90IGNhbmRpZGF0b3M6CiAgICAgICAgcmV0dXJuIE5vbmUsIE5vbmUK
REM ICAgIGlmIGxlbihjYW5kaWRhdG9zKSA9PSAxOgogICAgICAgIGNhbWluaG9fdW5pY28sIG5v
REM bWVfbWFwYV91bmljbywgY2F0ZWdvcmlhX3VuaWNhID0gY2FuZGlkYXRvc1swXQogICAgICAg
REM IGRlc2NyaWNhbyA9IHQoInJlaW5qX3RpcG9fZ29vZ2xlIikgaWYgY2F0ZWdvcmlhX3VuaWNh
REM ID09IHUidHJhZHVjYW8iIGVsc2UgdCgicmVpbmpfdGlwb19tYW51YWwiKQogICAgICAgIHBy
REM aW50KHUiIikKICAgICAgICBwcmludCh1Ij09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIpCiAgICAgICAgcHJpbnQodSIge30i
REM LmZvcm1hdCh0KCJyZWlual9zZWxlY2FvX3RpdHVsbyIpKSkKICAgICAgICBwcmludCh1Ij09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PSIpCiAgICAgICAgcHJpbnQodSIiKQogICAgICAgIHByaW50KHUiICBVbWEgw7puaWNh
REM IGZvbnRlIGNvbXBhdMOtdmVsIGZvaSBlbmNvbnRyYWRhOyBzZWxlw6fDo28gYXV0b23DoXRp
REM Y2EuIikKICAgICAgICBwcmludCh1IiAgRm9udGU6IHt9Ii5mb3JtYXQoZGVzY3JpY2FvKSkK
REM ICAgICAgICBwcmludCh1IiAgUGFzdGE6IHt9Ii5mb3JtYXQob3MucGF0aC5iYXNlbmFtZShj
REM YW1pbmhvX3VuaWNvKSkpCiAgICAgICAgcHJpbnQodSIgIENhbWluaG86IHt9Ii5mb3JtYXQo
REM Y2FtaW5ob191bmljbykpCiAgICAgICAgcHJpbnQodSIgIEluaWNpYW5kbyBhIHJlaW50ZWdy
REM YcOnw6NvIGF1dG9tYXRpY2FtZW50ZS4uLiIpCiAgICAgICAgcmV0dXJuIGNhbWluaG9fdW5p
REM Y28sIG5vbWVfbWFwYV91bmljbwoKICAgIHByaW50KHUiIikKICAgIHByaW50KHUiPT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM IikKICAgIHByaW50KHUiIHt9Ii5mb3JtYXQodCgicmVpbmpfc2VsZWNhb190aXR1bG8iKSkp
REM CiAgICBwcmludCh1Ij09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PSIpCiAgICBwcmludCh1IiIpCiAgICBmb3IgaSwgKGNhbWlu
REM aG8sIG5vbWVfbWFwYSwgY2F0ZWdvcmlhKSBpbiBlbnVtZXJhdGUoY2FuZGlkYXRvcywgMSk6
REM CiAgICAgICAgaWYgY2F0ZWdvcmlhID09IHUidHJhZHVjYW8iOgogICAgICAgICAgICBkZXNj
REM cmljYW8gPSB0KCJyZWlual90aXBvX2dvb2dsZSIpCiAgICAgICAgZWxzZToKICAgICAgICAg
REM ICAgZGVzY3JpY2FvID0gdCgicmVpbmpfdGlwb19tYW51YWwiKQogICAgICAgIHByaW50KHQo
REM InJlaW5qX3NlbGVjYW9faXRlbSIpLmZvcm1hdChpLCBkZXNjcmljYW8pKQogICAgICAgIHBy
REM aW50KHQoInJlaW5qX3NlbGVjYW9fcGFzdGEiKS5mb3JtYXQob3MucGF0aC5iYXNlbmFtZShj
REM YW1pbmhvKSkpCiAgICAgICAgcHJpbnQodCgicmVpbmpfc2VsZWNhb19jYW1pbmhvIikuZm9y
REM bWF0KGNhbWluaG8pKQogICAgICAgIHByaW50KHUiIikKICAgIHdoaWxlIFRydWU6CiAgICAg
REM ICAgdHJ5OgogICAgICAgICAgICBlc2NvbGhhID0gaW5wdXQodCgicmVpbmpfc2VsZWNhb19w
REM cm9tcHQiKSkuc3RyaXAoKQogICAgICAgIGV4Y2VwdCAoRU9GRXJyb3IsIEtleWJvYXJkSW50
REM ZXJydXB0KToKICAgICAgICAgICAgcmV0dXJuIE5vbmUsIE5vbmUKICAgICAgICBpZiBlc2Nv
REM bGhhLmlzZGlnaXQoKToKICAgICAgICAgICAgaW5kaWNlID0gaW50KGVzY29saGEpIC0gMQog
REM ICAgICAgICAgICBpZiAwIDw9IGluZGljZSA8IGxlbihjYW5kaWRhdG9zKToKICAgICAgICAg
REM ICAgICAgIHJldHVybiBjYW5kaWRhdG9zW2luZGljZV1bMF0sIGNhbmRpZGF0b3NbaW5kaWNl
REM XVsxXQogICAgICAgIHByaW50KHQoInJlaW5qX3NlbGVjYW9faW52YWxpZGEiKSkKCgojID09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09CiMgR09PR0xFIFRSQU5TTEFURQojID09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09CiMKIyBPYmpldGl2byBkZXN0YSB2ZXJzw6NvICh2NDApOgojICAgLSBw
REM b3Vjb3Mgd29ya2VycyBJL08gc2ltdWx0w6JuZW9zIGRlbnRybyBkZSBjYWRhIGFycXVpdm8g
REM KHBhZHLDo28gc2VndXJvKTsKIyAgIC0gY2FkYSB3b3JrZXIgcG9zc3VpIHN1YSBwcsOzcHJp
REM YSBzZXNzw6NvIEdvb2dsZSBSUEM7CiMgICAtIGNhY2hlIHRlbXBvcmFyaW8gcG9yIGV4ZWN1
REM Y2FvLCBwb3Igb3JpZ2VtICsgZGVzdGlubyArIHRleHRvOwojICAgLSByaXRtbyBnbG9iYWwg
REM KEdPT0dMRV9USFJPVFRMRSkgY29tIGludGVydmFsbyBtw61uaW1vIGVudHJlIFFVQUxRVUVS
REM CiMgICAgIHJlcXVpc2nDp8OjbywgZGUgcXVhbHF1ZXIgd29ya2VyIC0tIGV2aXRhIHJhamFk
REM YXMgcXVlIGRlcnJ1YmFtIG8gSVA7CiMgICAtIGFvIGxldmFyIHVtIDQyOSAobGltaXRlIGRv
REM IEdvb2dsZSksIFRPRE9TIG9zIHdvcmtlcnMgcGF1c2FtIGp1bnRvcyBwb3IKIyAgICAgdW0g
REM Y29vbGRvd24gY3Jlc2NlbnRlIChiYWNrb2ZmIGV4cG9uZW5jaWFsKSwgZW0gdmV6IGRlIGlu
REM c2lzdGlyIG5hIGhvcmE7CiMgICAtIGJhcnJhIGRlIHByb2dyZXNzbyBubyBjb25zb2xlIHNl
REM bSBpbnVuZGFyIGEgdGVsYTsKIyAgIC0gbyBhcnF1aXZvIGF0dWFsIHRlcm1pbmEgYW50ZXMg
REM ZGUgbyBwcsOzeGltbyBjb21lw6dhci4KIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
REM LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQp0cnk6
REM CiAgICBpbXBvcnQgaHR0cC5jb29raWVqYXIKZXhjZXB0IEltcG9ydEVycm9yOgogICAgaW1w
REM b3J0IGNvb2tpZWxpYiBhcyBjb29raWVqYXJfY29tcGF0CmVsc2U6CiAgICBjb29raWVqYXJf
REM Y29tcGF0ID0gaHR0cC5jb29raWVqYXIKCkdPT0dMRV9IT1NUUyA9ICgKICAgICh1Imdvb2ds
REM ZS5jb20iLCB1Imh0dHBzOi8vdHJhbnNsYXRlLmdvb2dsZS5jb20iKSwKICAgICh1Imdvb2ds
REM ZS5jb20uYnIiLCB1Imh0dHBzOi8vdHJhbnNsYXRlLmdvb2dsZS5jb20uYnIiKSwKICAgICh1
REM Imdvb2dsZS5jby51ayIsIHUiaHR0cHM6Ly90cmFuc2xhdGUuZ29vZ2xlLmNvLnVrIiksCikK
REM R09PR0xFX1JQQ19JRCA9IHUiTWtFV0JjIgpHT09HTEVfU1RBVElDX0JMID0gdSJib3FfdHJh
REM bnNsYXRlLXdlYnNlcnZlcl8yMDIwMTIwNy4xM19wMCIKR09PR0xFX1RJTUVPVVQgPSAxNQpH
REM T09HTEVfV09SS0VSUyA9IDUKR09PR0xFX1NDSEVEVUxFUl9DSFVOSyA9IDUwCkdPT0dMRV9K
REM T0JfV0lORE9XX01VTFRJUExJRVIgPSAyMApHT09HTEVfUkVUUklFUyA9IDIKR09PR0xFX1JF
REM U0lEVUFMX1JFVFJJRVMgPSAxCiMgSW50ZXJ2YWxvIG3DrW5pbW8gKHNlZ3VuZG9zKSBlbnRy
REM ZSBRVUFMUVVFUiByZXF1aXNpw6fDo28gZGUgdHJhZHXDp8OjbywgbsOjbwojIGltcG9ydGEg
REM byB3b3JrZXIgLS0gw6kgbyBxdWUgZXZpdGEgYSByYWphZGEgcXVlIGRlcnJ1Ym91IG8gSVAg
REM YW50ZXMuCkdPT0dMRV9JTlRFUlZBTE9fTUlOSU1PID0gMC4zMAojIENvb2xkb3duIGFwbGlj
REM YWRvIGEgVE9ET1Mgb3Mgd29ya2VycyBhc3NpbSBxdWUgcXVhbHF1ZXIgdW0gZGVsZXMgbGV2
REM YSB1bQojIDQyOS4gQ3Jlc2NlIGEgY2FkYSA0Mjkgc2VndWlkbyAoYmFja29mZiBleHBvbmVu
REM Y2lhbCkgZSB2b2x0YSBhbyB2YWxvcgojIGluaWNpYWwgZGVwb2lzIGRlIHVtIHRlbXBvIHNl
REM bSBibG9xdWVpb3MuCkdPT0dMRV9CQUNLT0ZGX0lOSUNJQUwgPSA2LjAKR09PR0xFX0JBQ0tP
REM RkZfTUFYSU1PID0gOTAuMApHT09HTEVfQkFDS09GRl9NVUxUSVBMSUNBRE9SID0gMi4wCkdP
REM T0dMRV9DQUNIRV9TQ0hFTUEgPSAxMwpHT09HTEVfQ0FDSEVfTk9NRSA9IHUiVW5SZW4tRERB
REM Qy1Hb29nbGUtVHJhbnNsYXRlLXJwYy1jYWNoZS10ZW1wLmpzb24iCkdPT0dMRV9DQUNIRV9Q
REM RVJTSVNURU5URV9ESVIgPSBOT01FU19DQUNIRV9QRVJTSVNURU5URV9ESVJfSURJT01BLmdl
REM dCgxKQpHT09HTEVfQ0FDSEVfRElBR05PU1RJQ09fTk9NRSA9IE5PTUVTX0RJQUdOT1NUSUNP
REM X0lESU9NQS5nZXQoMSkKR09PR0xFX0NBQ0hFX0VTVFJFU1NFX05PTUUgPSBOT01FU19ESUFH
REM Tk9TVElDT19FU1RSRVNTRV9JRElPTUEuZ2V0KDEpCkdPT0dMRV9DQUNIRV9QRVJTSVNURU5U
REM RV9OT01FID0gdSJHb29nbGUtVHJhbnNsYXRlLXJwYy12MS5qc29uIgpHT09HTEVfQ0FDSEVf
REM TU9UT1JfSUQgPSB1InJwYy12MSIKR09PR0xFX0NBQ0hFX0NSRURJVE9TX01PVE9SX0lEID0g
REM dSJycGMtdjEtY3JlZGl0LXYyIgojIEVtIGFycXVpdm9zIGdyYW5kZXMsIHJlZ3JhdmFyIG8g
REM SlNPTiBpbnRlaXJvIGRvIGNhY2hlIGEgY2FkYSAyNSBpdGVucyBnZXJhIEkvTwojIGRlc25l
REM Y2Vzc8OhcmlvLiBTYWx2YW1vcyBlbSBibG9jb3MgbWFpb3JlcyBlIGNvbnRpbnVhbW9zIHNh
REM bHZhbmRvIGFvIGZpbmFsIGRlCiMgY2FkYSBhcnF1aXZvIGUgaW1lZGlhdGFtZW50ZSBkaWFu
REM dGUgZGUgZXJyb3MsIHByZXNlcnZhbmRvIGEgcmV0b21hZGEuCkdPT0dMRV9DQUNIRV9TQVZF
REM X0FfQ0FEQSA9IDEwMApHT09HTEVfQ0FDSEVfUEVSU0lTVEVOVEVfU0FWRV9BX0NBREEgPSAy
REM NTAKIyBPIGNhY2hlIGRlIHJldG9tYWRhIMOpIGRpZmVyZW50ZSBkbyBjYWNoZSBwZXJzaXN0
REM ZW50ZTogZWxlIHByZWNpc2Egc2VyCiMgYXR1YWxpemFkbyBkdXJhbnRlIGEgZXhlY3XDp8Oj
REM bywgbWFzIG7Do28gYSBjYWRhIHRleHRvLiBSZWdyYXZhciB1bSBKU09OIGludGVpcm8KIyBk
REM ZXBvaXMgZGUgY2FkYSBjb25jbHVzw6NvIGdlcmEgSS9PIGNyZXNjZW50ZSBlIHBvZGUgcGFy
REM YWxpc2FyIGEgZmlsYSBubyBmaW5hbC4KR09PR0xFX0NBQ0hFX1RFTVBfU0FWRV9BX0NBREEg
REM PSAyNQpHT09HTEVfSEVBUlRCRUFUX1NFR1VORE9TID0gNS4wCiMgQ2FsaWJyYcOnw6NvIHRl
REM bXBvcsOhcmlhIGRvIGxpbWl0ZTogMCwzMHMgasOhIGZvaSBjb25maXJtYWRvIGFudGVyaW9y
REM bWVudGUgZW0KIyBkdWFzIHJvZGFkYXMgY29tcGxldGFzOyBvIHRlc3RlIGRlIGVzdHJlc3Nl
REM IGNvbWXDp2Egbm8gcHLDs3hpbW8gZGVncmF1LgpHT09HTEVfRElBR05PU1RJQ09fRVNUUkVT
REM U0VfTE9URSA9IDE4MApHT09HTEVfRElBR05PU1RJQ09fRVNUUkVTU0VfSU5URVJWQUxPUyA9
REM ICgwLjI1LCAwLjIwLCAwLjE1LCAwLjEwKQpHT09HTEVfRElBR05PU1RJQ09fRVNUUkVTU0Vf
REM QkFTRUxJTkUgPSAwLjMwCgpMQU5HVUFHRV9BTElBU0VTID0gewogICAgImF1dG8iOiAiYXV0
REM byIsICJhdXRvbWF0aWNvIjogImF1dG8iLCAiYXV0b23DoXRpY28iOiAiYXV0byIsICJhdXRv
REM bWF0aWMiOiAiYXV0byIsCiAgICAicHRiciI6ICJwdC1CUiIsICJwdC1iciI6ICJwdC1CUiIs
REM ICJwdF9iciI6ICJwdC1CUiIsICJwdCBicmFzaWwiOiAicHQtQlIiLAogICAgInBvcnR1Z3Vl
REM cyBicmFzaWwiOiAicHQtQlIiLCAicG9ydHVndcOqcyBicmFzaWwiOiAicHQtQlIiLCAiYnJh
REM emlsaWFuIHBvcnR1Z3Vlc2UiOiAicHQtQlIiLCAicG9ydHVndWVzZSBicmF6aWwiOiAicHQt
REM QlIiLAogICAgInB0IjogInB0IiwgInBvcnR1Z3VlcyI6ICJwdCIsICJwb3J0dWd1w6pzIjog
REM InB0IiwgInBvcnR1Z3Vlc2UiOiAicHQiLAogICAgInB0cHQiOiAicHQtUFQiLCAicHQtcHQi
REM OiAicHQtUFQiLCAicG9ydHVnYWwiOiAicHQtUFQiLCAicG9ydHVndcOqcyBwb3J0dWdhbCI6
REM ICJwdC1QVCIsICJwb3J0dWd1ZXNlIHBvcnR1Z2FsIjogInB0LVBUIiwKICAgICJlbiI6ICJl
REM biIsICJpbmdsZXMiOiAiZW4iLCAiaW5nbMOqcyI6ICJlbiIsICJlbmdsaXNoIjogImVuIiwK
REM ICAgICJlcyI6ICJlcyIsICJlc3BhbmhvbCI6ICJlcyIsICJlc3Bhw7FvbCI6ICJlcyIsICJz
REM cGFuaXNoIjogImVzIiwKICAgICJmciI6ICJmciIsICJmcmFuY2VzIjogImZyIiwgImZyYW5j
REM w6pzIjogImZyIiwgImZyZW5jaCI6ICJmciIsCiAgICAiZGUiOiAiZGUiLCAiYWxlbWFvIjog
REM ImRlIiwgImFsZW3Do28iOiAiZGUiLCAiZ2VybWFuIjogImRlIiwKICAgICJpdCI6ICJpdCIs
REM ICJpdGFsaWFubyI6ICJpdCIsICJpdGFsaWFuIjogIml0IiwKICAgICJqYSI6ICJqYSIsICJq
REM YXBvbmVzIjogImphIiwgImphcG9uw6pzIjogImphIiwgImphcGFuZXNlIjogImphIiwKICAg
REM ICJrbyI6ICJrbyIsICJjb3JlYW5vIjogImtvIiwgImtvcmVhbiI6ICJrbyIsCiAgICAiemgi
REM OiAiemgtQ04iLCAiemgtY24iOiAiemgtQ04iLCAiY2hpbmVzIjogInpoLUNOIiwgImNoaW7D
REM qnMiOiAiemgtQ04iLCAiY2hpbmVzZSI6ICJ6aC1DTiIsCiAgICAicnUiOiAicnUiLCAicnVz
REM c28iOiAicnUiLCAicnVzc2lhbiI6ICJydSIsCiAgICAidHIiOiAidHIiLCAidHVyY28iOiAi
REM dHIiLCAidHVya2lzaCI6ICJ0ciIsCiAgICAidWsiOiAidWsiLCAidWNyYW5pYW5vIjogInVr
REM IiwgInVrcmFpbmlhbiI6ICJ1ayIsCiAgICAicGwiOiAicGwiLCAicG9sb25lcyI6ICJwbCIs
REM ICJwb2xvbsOqcyI6ICJwbCIsICJwb2xpc2giOiAicGwiLAogICAgIm5sIjogIm5sIiwgImhv
REM bGFuZGVzIjogIm5sIiwgImhvbGFuZMOqcyI6ICJubCIsICJkdXRjaCI6ICJubCIsCiAgICAi
REM YXIiOiAiYXIiLCAiYXJhYmUiOiAiYXIiLCAiw6FyYWJlIjogImFyIiwgImFyYWJpYyI6ICJh
REM ciIsCiAgICAiaGkiOiAiaGkiLCAiaGluZGkiOiAiaGkiLAogICAgInZpIjogInZpIiwgInZp
REM ZXRuYW1pdGEiOiAidmkiLCAidmlldG5hbWVzZSI6ICJ2aSIsCiAgICAiaWQiOiAiaWQiLCAi
REM aW5kb25lc2lvIjogImlkIiwgImluZG9uw6lzaW8iOiAiaWQiLCAiaW5kb25lc2lhbiI6ICJp
REM ZCIsCn0KCiMgUHJvdGVnZSBwZXJjZW50dWFpcy9mb3JtYXRvcyBxdWUgasOhIGV4aXN0ZW0g
REM bm8gdGV4dG8gb3JpZ2luYWwuCiMgTsOjbyBpbmNsdWkgbyBlc3Bhw6dvIGNvbW8gZmxhZyBk
REM ZSBmb3JtYXRvOiBlbSB0ZXh0byBuYXR1cmFsLCBzZXF1w6puY2lhcyBjb21vCiMgYDEwMCUg
REM Y29tYCBkZXZlbSBzZXIgdHJhdGFkYXMgY29tbyB1bSBwZXJjZW50dWFsIGxpdGVyYWwgZSBu
REM w6NvIGNvbW8gYCVjYC4KIyBBIGV0YXBhIGRlIHJlaW50ZWdyYcOnw6NvIHRhbWLDqW0gcHJv
REM dGVnZSBxdWFscXVlciBzZXF1w6puY2lhIHBlcmNlbnR1YWwgb3JpZ2luYWwKIyBhbnRlcyBk
REM ZSBlc2NhcGFyIHBlcmNlbnR1YWlzIG5vdm9zIGludHJvZHV6aWRvcyBwZWxhIHRyYWR1w6fD
REM o28uCiMgTm9tZXMgY2Fuw7RuaWNvcyBkYXMgcXVhdHJvIHBlcnNvbmFnZW5zIHByaW5jaXBh
REM aXMgc8OjbyBwcm90ZWdpZG9zIGdsb2JhbG1lbnRlCiMgZW0gcXVhbHF1ZXIgdGV4dG8gZW52
REM aWFkbyBhbyBHb29nbGU7IG51bmNhIGRldmVtIHNlciB0cmFkdXppZG9zLiBPIGxpbWl0ZQoj
REM IGluY2x1aSAnXycgcGFyYSBuw6NvIGNhcHR1cmFyIGlkZW50aWZpY2Fkb3JlcyBjb21vIHNh
REM eW9yaV9yb3V0ZS4KVE9LRU5fUFJPVEVDQU9fUkUgPSByZS5jb21waWxlKAogICAgcidcclxu
REM fFxufFxyfGh0dHBzPzovL1xTK3woPzpbQS1aYS16MC05Xy4tXStbXFwvXSkqW0EtWmEtejAt
REM OV8uLV0rXC4oPzpwbmd8anBnfGpwZWd8Z2lmfHdlYnB8d2VibXxvZ2d8bXAzfHdhdnxmbGFj
REM fG00YXx0dGZ8b3RmfHR0Y3xycHl8cnB5Y3xycGF8ZGxsfHNvfGV4ZXxiaW58anNvbnxweXxw
REM eWMpKD8hW0EtWmEtejAtOV8uLV0pfFxcLnxce1tefVxyXG5dKlx9fCg/PCFbQS1aYS16w4At
REM w79fXSkoU2F5b3JpfE1vbmlrYXxOYXRzdWtpfFl1cmkpKD8hW0EtWmEtesOALcO/X10pfCUl
REM fCUoPzpcKFteKV0qXCkpP1sjMFwtK10qKD86XCp8XGQrKT8oPzpcLig/OlwqfFxkKykpPyg/
REM OltobExdKT9bQS1aYS16XScKKQpQRVJDRU5UVUFMX09SSUdJTkFMX1JFID0gcmUuY29tcGls
REM ZSgKICAgIHInXFwlfCUlfCUoPzpcKFteKV0qXCkpP1sjMFwtK10qKD86XCp8XGQrKT8oPzpc
REM Lig/OlwqfFxkKykpPyg/OltobExdKT9bQS1aYS16XScKKQoKCmRlZiBub3JtYWxpemFyX2lk
REM aW9tYV9jb2RpZ28odmFsb3IsIHBhZHJhbyk6CiAgICB0ZXh0byA9ICh2YWxvciBvciB1IiIp
REM LnN0cmlwKCkKICAgIGNoYXZlID0gdGV4dG8ubG93ZXIoKS5yZXBsYWNlKHUiXyIsIHUiLSIp
REM CiAgICByZXR1cm4gTEFOR1VBR0VfQUxJQVNFUy5nZXQoY2hhdmUsIHRleHRvIG9yIHBhZHJh
REM bykKCgpkZWYgdmFsaWRhcl9jb2RpZ29faWRpb21hKHZhbG9yKToKICAgIHJldHVybiBib29s
REM KHJlLm1hdGNoKHInXltBLVphLXpdezIsM30oPzotW0EtWmEtel17Miw0fSk/JCcsIHZhbG9y
REM KSBvciB2YWxvciA9PSB1ImF1dG8iKQoKCmRlZiBkZWNvZGlmaWNhcl9saXRlcmFsX3RyYWR1
REM Y2FvKGxpdGVyYWwpOgogICAgdmFsb3IgPSBsaXRlcmFsLnN0cmlwKCkKICAgICMgQmFja3Rp
REM Y2sgw6kgc3RyaW5nIFJlbidQeSBkaXJldGEsIG1hcyBuw6NvIMOpIHN0cmluZyBQeXRob24u
REM CiAgICBicnV0byA9IHZhbG9yWzE6XSBpZiBsZW4odmFsb3IpID49IDMgYW5kIHZhbG9yWzBd
REM IGluICdyUicgYW5kIHZhbG9yWzFdIGluICgnIicsICInIiwgJ2AnKSBlbHNlIHZhbG9yCiAg
REM ICBpZiBsZW4oYnJ1dG8pID49IDIgYW5kIGJydXRvWzBdID09ICdgJyBhbmQgYnJ1dG9bLTFd
REM ID09ICdgJzoKICAgICAgICBpbnRlcmlvciA9IGJydXRvWzE6LTFdCiAgICAgICAgcmV0dXJu
REM IChpbnRlcmlvci5yZXBsYWNlKHUnXFxgJywgdSdgJykKICAgICAgICAgICAgICAgICAgICAg
REM ICAgLnJlcGxhY2UodSdcXFxcJywgdSdcXCcpCiAgICAgICAgICAgICAgICAgICAgICAgIC5y
REM ZXBsYWNlKHUnXFxuJywgdSdcbicpCiAgICAgICAgICAgICAgICAgICAgICAgIC5yZXBsYWNl
REM KHUnXFxyJywgdSdccicpCiAgICAgICAgICAgICAgICAgICAgICAgIC5yZXBsYWNlKHUnXFx0
REM JywgdSdcdCcpKQogICAgdHJ5OgogICAgICAgIHdpdGggd2FybmluZ3MuY2F0Y2hfd2Fybmlu
REM Z3MoKToKICAgICAgICAgICAgd2FybmluZ3MuZmlsdGVyd2FybmluZ3MoImlnbm9yZSIsIG1l
REM c3NhZ2U9ciJpbnZhbGlkIGVzY2FwZSBzZXF1ZW5jZS4qIiwgY2F0ZWdvcnk9U3ludGF4V2Fy
REM bmluZykKICAgICAgICAgICAgcmVzdWx0YWRvID0gYXN0LmxpdGVyYWxfZXZhbCh2YWxvcikK
REM ICAgICAgICBpZiBpc2luc3RhbmNlKHJlc3VsdGFkbywgc3RyKToKICAgICAgICAgICAgcmV0
REM dXJuIHJlc3VsdGFkbwogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBy
REM ZXR1cm4gc3RyaXBfcXVvdGVzKHZhbG9yKQoKZGVmIGNvZGlmaWNhcl9saXRlcmFsX2NvbV9m
REM b3JtYXRvKG9yaWdpbmFsX2xpdGVyYWwsIHRleHRvKToKICAgICIiIlJlZXNjcmV2ZSBvIHRl
REM eHRvIHVzYW5kbyBvIG1lc21vIGRlbGltaXRhZG9yL3ByZWZpeG8gZGEgc3RyaW5nIG9yaWdp
REM bmFsLiIiIgogICAgb3JpZ2luYWwgPSAob3JpZ2luYWxfbGl0ZXJhbCBvciB1JycpLnN0cmlw
REM KCkKICAgIHJhdyA9IGxlbihvcmlnaW5hbCkgPj0gMyBhbmQgb3JpZ2luYWxbMF0gaW4gJ3JS
REM JyBhbmQgb3JpZ2luYWxbMV0gaW4gKCciJywgIiciLCAnYCcpIGFuZCBvcmlnaW5hbFstMV0g
REM PT0gb3JpZ2luYWxbMV0KICAgIHF1b3RlID0gb3JpZ2luYWxbMV0gaWYgcmF3IGVsc2UgKG9y
REM aWdpbmFsWzBdIGlmIG9yaWdpbmFsWzoxXSBpbiAoJyInLCAiJyIsICdgJykgZWxzZSAnIicp
REM CiAgICBwcmVmaXhvID0gb3JpZ2luYWxbMF0gaWYgcmF3IGVsc2UgdScnCiAgICBpZiByYXc6
REM CiAgICAgICAgYm9keSA9IHRleHRvLnJlcGxhY2UocXVvdGUsIHUnXFwnICsgcXVvdGUpCiAg
REM ICAgICAgcmV0dXJuIHByZWZpeG8gKyBxdW90ZSArIGJvZHkgKyBxdW90ZQogICAgYm9keSA9
REM IHRleHRvLnJlcGxhY2UodSdcXCcsIHUnXFxcXCcpLnJlcGxhY2UodSdccicsIHUnXFxyJyku
REM cmVwbGFjZSh1J1xuJywgdSdcXG4nKS5yZXBsYWNlKHUnXHQnLCB1J1xcdCcpCiAgICBib2R5
REM ID0gYm9keS5yZXBsYWNlKHF1b3RlLCB1J1xcJyArIHF1b3RlKQogICAgcmV0dXJuIHF1b3Rl
REM ICsgYm9keSArIHF1b3RlCgoKZGVmIGNvZGlmaWNhcl9saXRlcmFsX3RyYWR1Y2FvKHRleHRv
REM KToKICAgIHBhcnRlcyA9IFt1JyInXQogICAgaSA9IDAKICAgIHdoaWxlIGkgPCBsZW4odGV4
REM dG8pOgogICAgICAgIGNoID0gdGV4dG9baV0KICAgICAgICBpZiBjaCA9PSB1J1xcJzoKICAg
REM ICAgICAgICAgaWYgaSArIDEgPCBsZW4odGV4dG8pIGFuZCB0ZXh0b1tpICsgMV0gaW4gKHUn
REM JScsIHUnWycsIHUneycsIHUnICcpOgogICAgICAgICAgICAgICAgcGFydGVzLmFwcGVuZCh1
REM J1xcJykKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHBhcnRlcy5hcHBlbmQo
REM dSdcXFxcJykKICAgICAgICBlbGlmIGNoID09IHUnIic6CiAgICAgICAgICAgIHBhcnRlcy5h
REM cHBlbmQodSdcXCInKQogICAgICAgIGVsaWYgY2ggPT0gdSdcbic6CiAgICAgICAgICAgIHBh
REM cnRlcy5hcHBlbmQodSdcXG4nKQogICAgICAgIGVsaWYgY2ggPT0gdSdccic6CiAgICAgICAg
REM ICAgIHBhcnRlcy5hcHBlbmQodSdcXHInKQogICAgICAgIGVsaWYgY2ggPT0gdSdcdCc6CiAg
REM ICAgICAgICAgIHBhcnRlcy5hcHBlbmQodSdcXHQnKQogICAgICAgIGVsc2U6CiAgICAgICAg
REM ICAgIHBhcnRlcy5hcHBlbmQoY2gpCiAgICAgICAgaSArPSAxCiAgICBwYXJ0ZXMuYXBwZW5k
REM KHUnIicpCiAgICByZXR1cm4gdSIiLmpvaW4ocGFydGVzKQoKCmRlZiBfaW50ZXJ2YWxvc190
REM b2tlbnNfZ29vZ2xlKHRleHRvKToKICAgICIiIlJldG9ybmEgdG9rZW5zIHByb3RlZ8OtdmVp
REM cyBlbSBvcmRlbSwgaW5jbHVpbmRvIGludGVycG9sYcOnw6NvIFtdIGFuaW5oYWRhLiIiIgog
REM ICAgaW50ZXJ2YWxvcz1bXQogICAgZm9yIG0gaW4gVE9LRU5fUFJPVEVDQU9fUkUuZmluZGl0
REM ZXIodGV4dG8pOgogICAgICAgIGludGVydmFsb3MuYXBwZW5kKChtLnN0YXJ0KCksIG0uZW5k
REM KCksIG0uZ3JvdXAoMCkpKQogICAgZm9yIGEsYiBpbiBfaXRlcl9pbnRlcnZhbG9zX2JyYWNr
REM ZXRzX2JhbGFuY2VhZG9zKHRleHRvKToKICAgICAgICBpbnRlcnZhbG9zLmFwcGVuZCgoYSxi
REM LHRleHRvW2E6Yl0pKQogICAgaW50ZXJ2YWxvcy5zb3J0KGtleT1sYW1iZGEgeDooeFswXSwg
REM LSh4WzFdLXhbMF0pKSkKICAgIHJlc3VsdGFkbz1bXTsgdWx0aW1vPS0xCiAgICBmb3IgYSxi
REM LHJhdyBpbiBpbnRlcnZhbG9zOgogICAgICAgIGlmIGEgPCB1bHRpbW86CiAgICAgICAgICAg
REM IGNvbnRpbnVlCiAgICAgICAgcmVzdWx0YWRvLmFwcGVuZCgoYSxiLHJhdykpOyB1bHRpbW89
REM YgogICAgcmV0dXJuIHJlc3VsdGFkbwoKCiMgVGVybW9zIGUgZXN0cnV0dXJhcyBxdWUgcGVy
REM bWFuZWNlbSBubyBpZGlvbWEgb3JpZ2luYWwgcXVhbmRvIGZhemVtIHBhcnRlIGRlCiMgZnJh
REM c2VzIHRyYWR1esOtdmVpcy4gQ3LDqWRpdG9zIG7Do28gc8OjbyBkZXNjYXJ0YWRvczogc29t
REM ZW50ZSBhcyBjYXRlZ29yaWFzL3JvbGVzCiMgc8OjbyB0cmFkdXppZGFzOyBwZXNzb2FzLCBh
REM cnRpc3RhcywgaGFuZGxlcywgdMOtdHVsb3MgZSByZWN1cnNvcyBwZXJtYW5lY2VtLgpURVJN
REM T1NfTkFPX1RSQURVWklSX0dPT0dMRSA9ICgKICAgIHUiRG9raSBEb2tpIExpdGVyYXR1cmUg
REM Q2x1YiIsIHUiVGVhbSBTYWx2YXRvIiwgdSJTdGVhbSIsIHUiVHdpdGNoIiwKICAgIHUiRGlz
REM Y29yZCIsIHUiWW91VHViZSIsIHUiUmVuJ1B5IiwgdSJHaXRIdWIiLCB1IlBhdHJlb24iLCB1
REM Iml0Y2guaW8iLAopCl9SRV9URVJNT1NfTkFPX1RSQURVWklSX0dPT0dMRSA9IHJlLmNvbXBp
REM bGUoCiAgICB1InwiLmpvaW4ocmUuZXNjYXBlKHgpIGZvciB4IGluIHNvcnRlZChURVJNT1Nf
REM TkFPX1RSQURVWklSX0dPT0dMRSwga2V5PWxlbiwgcmV2ZXJzZT1UcnVlKSksIHJlLkkKKQoK
REM IyBWb2NhYnVsw6FyaW8gZ2xvYmFsIGRlIGNhdGVnb3JpYXMvcm9sZXMgZGUgY3LDqWRpdG9z
REM LiBOw6NvIGlkZW50aWZpY2Egbm9tZXMgZGUKIyBwZXNzb2FzOiBhIHRyYWR1w6fDo28gc8Oz
REM IMOpIGFwbGljYWRhIHF1YW5kbyBhIGxpbmhhIHRlcm1pbmEgZW0gJzonIG91IMOpIHVtYQoj
REM IGZ1bsOnw6NvIGN1cnRhIGNvbmhlY2lkYS4gQXNzaW0gIkNhc3VhbCBNb25pa2E6IERlc3Rp
REM bnlQVkVHYWwiIHBlcm1hbmVjZSBpbnRhY3RvLgpDUkVESVRPU19DQVRFR09SSUFTX1RSQURV
REM WklWRUlTID0gZnJvemVuc2V0KCgKICAgIHUiY3JlZGl0IiwgdSJjcmVkaXRzIiwgdSJhY2tu
REM b3dsZWRnZW1lbnRzIiwgdSJhY2tub3dsZWRnbWVudHMiLCB1InNwZWNpYWwgdGhhbmtzIiwK
REM ICAgIHUic29uZyBjb3ZlcnMiLCB1Im11c2ljIGNyZWRpdHMiLCB1InNvdW5kdHJhY2siLCB1
REM Im1pc2Mgc291bmQgZWZmZWN0cyIsIHUic291bmQgZWZmZWN0cyIsCiAgICB1Im1vZCByZXNv
REM dXJjZXMiLCB1Im1vZCByZXNvdXJjZSIsIHUic3ByaXRlcyIsIHUiYmFja2dyb3VuZHMiLCB1
REM ImJhY2tncm91bmRzIGFydCIsCiAgICB1InBsYXl0ZXN0ZXJzIiwgdSJwbGF5dGVzdGVyIiwg
REM dSJmbG93ZXIgbW9vbiBsb2dvIiwgdSJlbmRpbmcgY2ciLCB1ImVuZGluZyIsCiAgICB1Indy
REM aXRpbmciLCB1Im11c2ljIiwgdSJjb2RpbmciLCB1ImNvZGVyIiwgdSJjb2RlcnMiLCB1InBy
REM b2dyYW1taW5nIiwgdSJwcm9ncmFtbWVyIiwKICAgIHUicHJvZ3JhbW1lcnMiLCB1InRyYW5z
REM bGF0aW9uIiwgdSJ0cmFuc2xhdGlvbnMiLCB1InRyYW5zbGF0b3IiLCB1InRyYW5zbGF0b3Jz
REM IiwKICAgIHUiZWRpdGluZyIsIHUiZWRpdG9yIiwgdSJlZGl0b3JzIiwgdSJwcm9vZnJlYWRp
REM bmciLCB1InByb29mcmVhZGVyIiwgdSJhcnRpc3QiLCB1ImFydGlzdHMiLAogICAgdSJhcnQi
REM LCB1ImFydHdvcmsiLCB1ImFuaW1hdGlvbiIsIHUiYW5pbWF0b3IiLCB1ImFuaW1hdG9ycyIs
REM IHUidm9pY2UgYWN0aW5nIiwKICAgIHUidm9pY2UgYWN0b3IiLCB1InZvaWNlIGFjdG9ycyIs
REM IHUidm9pY2VzIiwgdSJ2b2ljZSIsIHUiY29tcG9zZXIiLCB1ImNvbXBvc2VycyIsCiAgICB1
REM InNvdW5kIGRlc2lnbiIsIHUic291bmQgZGVzaWduZXIiLCB1ImRlc2lnbiIsIHUiZGVzaWdu
REM ZXIiLCB1ImRlc2lnbmVycyIsIHUiZGV2ZWxvcG1lbnQiLAogICAgdSJkZXZlbG9wbWVudCB0
REM ZWFtIiwgdSJkZXZlbG9wZXIiLCB1ImRldmVsb3BlcnMiLCB1InRlYW0iLCB1InN0YWZmIiwg
REM dSJhdXRob3IiLCB1ImF1dGhvcnMiLAogICAgdSJjb250cmlidXRvcnMiLCB1ImNvbnRyaWJ1
REM dG9yIiwgdSJ0ZXN0ZXIiLCB1InRlc3RlcnMiLCB1ImZvbnRzIiwgdSJmb250IiwgdSJhc3Nl
REM dHMiLAogICAgdSJtb2QgYXNzZXRzIiwgdSJyZXNvdXJjZXMiLCB1InJlc291cmNlIiwgdSJs
REM b2dvIiwgdSJsb2dvcyIsIHUiaWxsdXN0cmF0aW9uIiwgdSJpbGx1c3RyYXRpb25zIiwKICAg
REM IHUiY2ciLCB1ImNncyIsIHUidGhhbmtzIiwgdSJzcGVjaWFsIHRoYW5rcyIsIHUidmlzdWFs
REM cyIsIHUidmlzdWFsIGFydCIsIHUiZ3VpIiwgdSJ1aSIsCiAgICB1ImludGVyZmFjZSIsIHUi
REM aW50ZXJmYWNlIGRlc2lnbiIsIHUiZWZmZWN0cyIsIHUic291bmQgZWZmZWN0cyIsIHUibXVz
REM aWMiLCB1ImNyZWRpdHMiCikpCkNSRURJVE9TX1BSRUZJWE9TX0NBVEVHT1JJQSA9ICgKICAg
REM IHUic29uZyAiLCB1Im11c2ljICIsIHUic291bmQgIiwgdSJtaXNjICIsIHUibW9kICIsIHUi
REM c3BlY2lhbCAiLCB1InZvaWNlICIsCiAgICB1ImJhY2tncm91bmQiLCB1InNwcml0ZSIsIHUi
REM cGxheXRlc3QiLCB1ImVuZGluZyAiLCB1ImZsb3dlciBtb29uICIsIHUid3JpdGluZyIsCiAg
REM ICB1ImNvZGluZyIsIHUicHJvZ3JhbSIsIHUidHJhbnNsYXQiLCB1ImVkaXQiLCB1InByb29m
REM IiwgdSJhcnRpc3QiLCB1ImFydCIsCiAgICB1ImFuaW1hdGlvbiIsIHUiYW5pbWF0b3IiLCB1
REM ImRldmVsb3BtZW50IiwgdSJkZXZlbG9wZXIiLCB1InJlc291cmNlIiwgdSJhc3NldCIsCiAg
REM ICB1ImNyZWRpdCIsIHUiYWNrbm93bGVkZyIsIHUidGhhbmtzIiwgdSJzdGFmZiIsIHUidGVh
REM bSIsIHUiYXV0aG9yIiwgdSJjb250cmlidXRvciIKKQoKX1JFX1VSTF9DUkVESVRPUyA9IHJl
REM LmNvbXBpbGUocidodHRwcz86Ly98d3d3XFwuJywgcmUuSSkKCmRlZiBfbm9ybWFsaXphcl9s
REM aW5oYV9jcmVkaXRvKHRleHRvKToKICAgIHJldHVybiB1IiAiLmpvaW4odGV4dG9fY29tcGF0
REM aXZlbCh0ZXh0bywgdSIiKS5zdHJpcCgpLmxvd2VyKCkuc3BsaXQoKSkKCmRlZiBfcm90dWxv
REM X2NyZWRpdG9fZWhfY2F0ZWdvcmlhKGxhYmVsKToKICAgIG5vcm1hbCA9IF9ub3JtYWxpemFy
REM X2xpbmhhX2NyZWRpdG8obGFiZWwpLnJzdHJpcCgnOicpLnN0cmlwKCkKICAgIGlmIG5vdCBu
REM b3JtYWwgb3IgbGVuKG5vcm1hbCkgPiA4MDoKICAgICAgICByZXR1cm4gRmFsc2UKICAgIGlm
REM IF9SRV9VUkxfQ1JFRElUT1Muc2VhcmNoKG5vcm1hbCk6CiAgICAgICAgcmV0dXJuIEZhbHNl
REM CiAgICBpZiBub3JtYWwgaW4gQ1JFRElUT1NfQ0FURUdPUklBU19UUkFEVVpJVkVJUzoKICAg
REM ICAgICByZXR1cm4gVHJ1ZQogICAgcGFsYXZyYXMgPSBbcCBmb3IgcCBpbiByZS5zcGxpdChy
REM J1teYS16MC05w4Atw79dKycsIG5vcm1hbCkgaWYgcF0KICAgIGlmIGxlbihwYWxhdnJhcykg
REM PiA2OgogICAgICAgIHJldHVybiBGYWxzZQogICAgIyBVbSBjYWJlw6dhbGhvIHPDsyDDqSB0
REM cmFkdXppZG8gcXVhbmRvIGNvbnTDqW0gdm9jYWJ1bMOhcmlvIGluZXF1w612b2NvIGRlCiAg
REM ICAjIGNyw6lkaXRvczsgbm9tZXMgcHLDs3ByaW9zIHRlcm1pbmFkb3MgZW0gJzonIG7Do28g
REM ZW50cmFtIHBvciBlbmdhbm8uCiAgICByZXR1cm4gYW55KG5vcm1hbC5zdGFydHN3aXRoKHBy
REM ZWZpeG8pIG9yIHBhbGF2cmEgaW4gbm9ybWFsIGZvciBwcmVmaXhvIGluIENSRURJVE9TX1BS
REM RUZJWE9TX0NBVEVHT1JJQSBmb3IgcGFsYXZyYSBpbiAocHJlZml4by5zdHJpcCgpLCkpCgpk
REM ZWYgX2xpbmhhX2NyZWRpdG9fcm9sZV9laF9jYXRlZ29yaWEobGluZSk6CiAgICBub3JtYWwg
REM PSBfbm9ybWFsaXphcl9saW5oYV9jcmVkaXRvKGxpbmUpCiAgICByZXR1cm4gbm9ybWFsIGlu
REM IENSRURJVE9TX0NBVEVHT1JJQVNfVFJBRFVaSVZFSVMgYW5kIGxlbihub3JtYWwpIDw9IDQw
REM CgpkZWYgcGFyZWNlX2Jsb2NvX2NyZWRpdG9zX2dvb2dsZSh0ZXh0bywgcmVsPXUiIiwgdGlw
REM bz11IiIpOgogICAgdGV4dG8gPSB0ZXh0b19jb21wYXRpdmVsKHRleHRvLCB1IiIpCiAgICBy
REM ZWxfbm9ybSA9IHRleHRvX2NvbXBhdGl2ZWwocmVsLCB1IiIpLnJlcGxhY2UoJ1xcJywnLycp
REM Lmxvd2VyKCkKICAgIGxpbmhhcyA9IHRleHRvLnNwbGl0bGluZXMoKQogICAgaWYgbGVuKGxp
REM bmhhcykgPCAyOgogICAgICAgIHJldHVybiBGYWxzZQogICAgZm9yIGxpbmhhIGluIGxpbmhh
REM czoKICAgICAgICBib2R5ID0gbGluaGEuc3RyaXAoKQogICAgICAgIGlmIG5vdCBib2R5Ogog
REM ICAgICAgICAgICBjb250aW51ZQogICAgICAgIGlmIGJvZHkuZW5kc3dpdGgoJzonKSBhbmQg
REM X3JvdHVsb19jcmVkaXRvX2VoX2NhdGVnb3JpYShib2R5WzotMV0pOgogICAgICAgICAgICBy
REM ZXR1cm4gVHJ1ZQogICAgICAgIGlmIF9saW5oYV9jcmVkaXRvX3JvbGVfZWhfY2F0ZWdvcmlh
REM KGJvZHkpOgogICAgICAgICAgICByZXR1cm4gVHJ1ZQogICAgIyBBcnF1aXZvcy9zZcOnw7Vl
REM cyBleHBsaWNpdGFtZW50ZSBkZSBjcsOpZGl0b3MgYWluZGEgcHJlY2lzYW0gZGUgdW0gcsOz
REM dHVsbwogICAgIyByZWNvbmhlY8OtdmVsOyBvIG5vbWUgZG8gYXJxdWl2byBzb3ppbmhvIG7D
REM o28gdHJhbnNmb3JtYSB0b2RvIG8gY29udGXDumRvIGVtCiAgICAjIGNyw6lkaXRvLgogICAg
REM aWYgJ2NyZWRpdCcgaW4gb3MucGF0aC5iYXNlbmFtZShyZWxfbm9ybSkgb3IgJ2Fja25vd2xl
REM ZGcnIGluIG9zLnBhdGguYmFzZW5hbWUocmVsX25vcm0pOgogICAgICAgIHJldHVybiBhbnko
REM KGwuc3RyaXAoKS5lbmRzd2l0aCgnOicpIGFuZCBsZW4obC5zdHJpcCgpKSA8PSA4MCkgZm9y
REM IGwgaW4gbGluaGFzKQogICAgcmV0dXJuIEZhbHNlCgpkZWYgX3RyYWR1emlyX2ZyYWdtZW50
REM b19jcmVkaXRvX2dvb2dsZShjbGllbnRlLCBmcmFnbWVudG8sIG9yaWdlbSwgZGVzdGlubyk6
REM CiAgICBmcmFnbWVudG8gPSB0ZXh0b19jb21wYXRpdmVsKGZyYWdtZW50bywgdSIiKQogICAg
REM cHJvdGVnaWRvLCB0b2tlbnMgPSBwcm90ZWdlcl90b2tlbnNfZ29vZ2xlKGZyYWdtZW50bykK
REM ICAgIG9yaWdlbV9nb29nbGUgPSBvcmlnZW0KICAgIGlmIG9yaWdlbSA9PSB1ImF1dG8iIGFu
REM ZCBkZXN0aW5vLmxvd2VyKCkuc3RhcnRzd2l0aCh1InB0IikgYW5kIGZvbnRlX3BhcmVjZV9p
REM bmdsZXNhX2dvb2dsZShmcmFnbWVudG8pOgogICAgICAgIG9yaWdlbV9nb29nbGUgPSB1ImVu
REM IgogICAgYnJ1dG8gPSBjbGllbnRlLnRyYWR1emlyKHByb3RlZ2lkbywgb3JpZ2VtX2dvb2ds
REM ZSwgZGVzdGlubykKICAgIHZhbGlkYXJfdG9rZW5zX2dvb2dsZV9wcmVzZXJ2YWRvcyhicnV0
REM bywgdG9rZW5zKQogICAgYnJ1dG8gPSBlc2NhcGFyX3BlcmNlbnR1YWlzX25vdm9zX2dvb2ds
REM ZShicnV0bykKICAgIHJldHVybiByZXN0YXVyYXJfdG9rZW5zX2dvb2dsZShicnV0bywgdG9r
REM ZW5zKQoKZGVmIHRyYWR1emlyX2Jsb2NvX2NyZWRpdG9zX2dvb2dsZShjbGllbnRlLCB0ZXh0
REM bywgb3JpZ2VtLCBkZXN0aW5vKToKICAgICIiIlRyYWR1eiBzb21lbnRlIHLDs3R1bG9zL3Jv
REM bGVzIGRlbnRybyBkZSB1bSBibG9jbyBkZSBjcsOpZGl0b3MuCgogICAgTm9tZXMgZGUgcGVz
REM c29hcywgaGFuZGxlcywgdMOtdHVsb3MgZGUgbcO6c2ljYXMsIHJlY3Vyc29zIGUgZGVzY3Jp
REM w6fDtWVzIGFww7NzIG8KICAgIGNhYmXDp2FsaG8gcGVybWFuZWNlbSBsaXRlcmFsbWVudGUg
REM aWd1YWlzLiBSZXRvcm5hIE5vbmUgcXVhbmRvIG7Do28gcGFyZWNlIHVtCiAgICBibG9jbyBk
REM ZSBjcsOpZGl0b3MgcmVjb25oZWPDrXZlbC4KICAgICIiIgogICAgdGV4dG8gPSB0ZXh0b19j
REM b21wYXRpdmVsKHRleHRvLCB1IiIpCiAgICBpZiBub3QgcGFyZWNlX2Jsb2NvX2NyZWRpdG9z
REM X2dvb2dsZSh0ZXh0bywgdSIiLCB1IiIpOgogICAgICAgIHJldHVybiBOb25lCiAgICBwYXJ0
REM ZXMgPSB0ZXh0by5zcGxpdGxpbmVzKFRydWUpCiAgICBzYWlkYT1bXQogICAgYWx0ZXJvdT1G
REM YWxzZQogICAgY2F0ZWdvcmlhc19lbmNvbnRyYWRhcz0wCiAgICBmb3IgcGFydGUgaW4gcGFy
REM dGVzOgogICAgICAgIGNvcnBvID0gcGFydGUucnN0cmlwKCdcclxuJykKICAgICAgICBmaW5h
REM bCA9IHBhcnRlW2xlbihjb3Jwbyk6XQogICAgICAgIGlmIG5vdCBjb3Jwby5zdHJpcCgpOgog
REM ICAgICAgICAgICBzYWlkYS5hcHBlbmQocGFydGUpOyBjb250aW51ZQogICAgICAgIGVzcXVl
REM cmRhID0gY29ycG9bOmxlbihjb3JwbyktbGVuKGNvcnBvLmxzdHJpcCgpKV0KICAgICAgICBk
REM aXJlaXRhID0gY29ycG9bbGVuKGNvcnBvLnJzdHJpcCgpKTpdCiAgICAgICAgY2VudHJvID0g
REM Y29ycG8uc3RyaXAoKQogICAgICAgIHRyYWR1emlyX2xhYmVsID0gRmFsc2UKICAgICAgICBt
REM b2RvID0gJ2hlYWRlcicKICAgICAgICBpZiBjZW50cm8uZW5kc3dpdGgoJzonKSBhbmQgX3Jv
REM dHVsb19jcmVkaXRvX2VoX2NhdGVnb3JpYShjZW50cm9bOi0xXSk6CiAgICAgICAgICAgIHRy
REM YWR1emlyX2xhYmVsID0gVHJ1ZQogICAgICAgIGVsaWYgX2xpbmhhX2NyZWRpdG9fcm9sZV9l
REM aF9jYXRlZ29yaWEoY2VudHJvKToKICAgICAgICAgICAgdHJhZHV6aXJfbGFiZWwgPSBUcnVl
REM CiAgICAgICAgICAgIG1vZG8gPSAncm9sZScKICAgICAgICBlbGlmIHJlLm1hdGNoKHInXig/
REM Om1hZGUgd2l0aHxjb3B5cmlnaHQoPzpcXHN8JCl8YWxsIHJpZ2h0cyByZXNlcnZlZCknLCBj
REM ZW50cm8sIHJlLkkpOgogICAgICAgICAgICAjIEZyYXNlcyBkZSBsaWNlbsOnYS9jb3B5cmln
REM aHQgcG9kZW0gc2VyIHRyYWR1emlkYXMgbm9ybWFsbWVudGU7IG9zCiAgICAgICAgICAgICMg
REM bm9tZXMvbWFyY2FzL1VSTHMgY29uaGVjaWRvcyBwZXJtYW5lY2VtIHByb3RlZ2lkb3MuCiAg
REM ICAgICAgICAgIHRyYWR1emlyX2xhYmVsID0gVHJ1ZQogICAgICAgICAgICBtb2RvID0gJ3Nl
REM bnRlbmNlJwogICAgICAgIGlmIHRyYWR1emlyX2xhYmVsOgogICAgICAgICAgICBjYXRlZ29y
REM aWFzX2VuY29udHJhZGFzICs9IDEKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAg
REM aWYgbW9kbyA9PSAnaGVhZGVyJzoKICAgICAgICAgICAgICAgICAgICBsYWJlbCA9IGNlbnRy
REM b1s6LTFdLnJzdHJpcCgpCiAgICAgICAgICAgICAgICAgICAgdHJhZHV6aWRvID0gX3RyYWR1
REM emlyX2ZyYWdtZW50b19jcmVkaXRvX2dvb2dsZShjbGllbnRlLCBsYWJlbCwgb3JpZ2VtLCBk
REM ZXN0aW5vKQogICAgICAgICAgICAgICAgICAgIG5vdm8gPSBlc3F1ZXJkYSArIHRyYWR1emlk
REM by5zdHJpcCgpICsgJzonICsgZGlyZWl0YSArIGZpbmFsCiAgICAgICAgICAgICAgICBlbHNl
REM OgogICAgICAgICAgICAgICAgICAgIHRyYWR1emlkbyA9IF90cmFkdXppcl9mcmFnbWVudG9f
REM Y3JlZGl0b19nb29nbGUoY2xpZW50ZSwgY2VudHJvLCBvcmlnZW0sIGRlc3Rpbm8pCiAgICAg
REM ICAgICAgICAgICAgICAgbm92byA9IGVzcXVlcmRhICsgdHJhZHV6aWRvLnN0cmlwKCkgKyBk
REM aXJlaXRhICsgZmluYWwKICAgICAgICAgICAgICAgIGlmIG5vdm8gIT0gcGFydGU6CiAgICAg
REM ICAgICAgICAgICAgICAgYWx0ZXJvdT1UcnVlCiAgICAgICAgICAgICAgICBzYWlkYS5hcHBl
REM bmQobm92bykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAg
REM IHJhaXNlCiAgICAgICAgZWxzZToKICAgICAgICAgICAgc2FpZGEuYXBwZW5kKHBhcnRlKQog
REM ICAgaWYgbm90IGNhdGVnb3JpYXNfZW5jb250cmFkYXMgb3Igbm90IGFsdGVyb3U6CiAgICAg
REM ICAgcmV0dXJuIHRleHRvCiAgICByZXN1bHRhZG8gPSB1Jycuam9pbihzYWlkYSkKICAgIHZh
REM bGlkYXJfaW50ZWdyaWRhZGVfdHJhZHVjYW9fZ29vZ2xlKHRleHRvLCByZXN1bHRhZG8pCiAg
REM ICB2YWxpZGFyX3Rlcm1vc19wcm90ZWdpZG9zX2dvb2dsZSh0ZXh0bywgcmVzdWx0YWRvKQog
REM ICAgcmV0dXJuIHJlc3VsdGFkbwoKZGVmIF9vY29ycmVuY2lhc190ZXJtb3NfcHJvdGVnaWRv
REM c19nb29nbGUodGV4dG8pOgogICAgdGV4dG8gPSB0ZXh0b19jb21wYXRpdmVsKHRleHRvLCB1
REM IiIpCiAgICByZXR1cm4gbGlzdChfUkVfVEVSTU9TX05BT19UUkFEVVpJUl9HT09HTEUuZmlu
REM ZGl0ZXIodGV4dG8pKQoKZGVmIHZhbGlkYXJfdGVybW9zX3Byb3RlZ2lkb3NfZ29vZ2xlKG9y
REM aWdpbmFsLCB0cmFkdWNhbyk6CiAgICBvcmlnaW5hbCA9IHRleHRvX2NvbXBhdGl2ZWwob3Jp
REM Z2luYWwsIHUiIikKICAgIHRyYWR1Y2FvID0gdGV4dG9fY29tcGF0aXZlbCh0cmFkdWNhbywg
REM dSIiKQogICAgZm9yIHRlcm1vIGluIFRFUk1PU19OQU9fVFJBRFVaSVJfR09PR0xFOgogICAg
REM ICAgIG5fb3JpZ2VtID0gbGVuKHJlLmZpbmRhbGwocmUuZXNjYXBlKHRlcm1vKSwgb3JpZ2lu
REM YWwsIGZsYWdzPXJlLkkpKQogICAgICAgIGlmIG5vdCBuX29yaWdlbToKICAgICAgICAgICAg
REM Y29udGludWUKICAgICAgICBuX3NhaWRhID0gbGVuKHJlLmZpbmRhbGwocmUuZXNjYXBlKHRl
REM cm1vKSwgdHJhZHVjYW8sIGZsYWdzPXJlLkkpKQogICAgICAgIGlmIG5fc2FpZGEgIT0gbl9v
REM cmlnZW06CiAgICAgICAgICAgIHJhaXNlIEdvb2dsZVRyYW5zbGF0ZVZhbGlkYXRpb25FcnJv
REM cih1InRlcm1vIHByb3RlZ2lkbyBhbHRlcmFkby9yZW1vdmlkbzogezB9Ii5mb3JtYXQodGVy
REM bW8pKQoKZGVmIGVudHJhZGFfbmFvX3RyYWR1eml2ZWxfZ29vZ2xlKHRleHRvLCByZWw9dSIi
REM LCB0aXBvPXUiIik6CiAgICAjIENyw6lkaXRvcyBlIGF2aXNvcyBkZSBjb3B5cmlnaHQgTsOD
REM TyBzw6NvIGRlc2NhcnRhZG9zLiBPIHRyYWR1dG9yIHRyYWJhbGhhCiAgICAjIHBvciBwYXJ0
REM ZXMgZSBwcm90ZWdlIG5vbWVzL21hcmNhcywgcGVybWl0aW5kbyB0cmFkdXppciBhcyBjYXRl
REM Z29yaWFzLgogICAgcmV0dXJuIEZhbHNlCgpkZWYgcHJvdGVnZXJfdG9rZW5zX2dvb2dsZSh0
REM ZXh0byk6CiAgICB0b2tlbnM9W107IHBhcnRlcz1bXTsgcG9zPTAKICAgIGludGVydmFsb3M9
REM bGlzdChfaW50ZXJ2YWxvc190b2tlbnNfZ29vZ2xlKHRleHRvKSkKICAgIGZvciBtIGluIF9v
REM Y29ycmVuY2lhc190ZXJtb3NfcHJvdGVnaWRvc19nb29nbGUodGV4dG8pOgogICAgICAgIGlu
REM dGVydmFsb3MuYXBwZW5kKChtLnN0YXJ0KCksIG0uZW5kKCksIG0uZ3JvdXAoMCkpKQogICAg
REM aW50ZXJ2YWxvcy5zb3J0KGtleT1sYW1iZGEgaXRlbTooaXRlbVswXSwgLShpdGVtWzFdLWl0
REM ZW1bMF0pKSkKICAgIGZvciBhLGIscmF3IGluIGludGVydmFsb3M6CiAgICAgICAgaWYgYSA8
REM IHBvczoKICAgICAgICAgICAgY29udGludWUKICAgICAgICBwYXJ0ZXMuYXBwZW5kKHRleHRv
REM W3BvczphXSkKICAgICAgICB0b2tlbj11IkREQUNaezowNGR9USIuZm9ybWF0KGxlbih0b2tl
REM bnMpKQogICAgICAgIHRva2Vucy5hcHBlbmQoKHRva2VuLHJhdykpCiAgICAgICAgcGFydGVz
REM LmFwcGVuZCh0b2tlbik7IHBvcz1iCiAgICBwYXJ0ZXMuYXBwZW5kKHRleHRvW3BvczpdKQog
REM ICAgcmV0dXJuIHUiIi5qb2luKHBhcnRlcyksIHRva2VucwoKCmRlZiByZXN0YXVyYXJfdG9r
REM ZW5zX2dvb2dsZSh0ZXh0bywgdG9rZW5zKToKICAgIHJlc3VsdGFkbyA9IHRleHRvCiAgICBm
REM b3IgdG9rZW4sIG9yaWdpbmFsIGluIHRva2VuczoKICAgICAgICByZXN1bHRhZG8gPSByZXN1
REM bHRhZG8ucmVwbGFjZSh0b2tlbiwgb3JpZ2luYWwpCiAgICAgICAgcmVzdWx0YWRvID0gcmVz
REM dWx0YWRvLnJlcGxhY2UodG9rZW4ubG93ZXIoKSwgb3JpZ2luYWwpCiAgICByZXR1cm4gcmVz
REM dWx0YWRvCgoKZGVmIGVzY2FwYXJfcGVyY2VudHVhaXNfbm92b3NfZ29vZ2xlKHRleHRvKToK
REM ICAgICIiIlRvcm5hIHNlZ3Vyb3Mgb3MgcGVyY2VudHVhaXMgcXVlIG7Do28gdmllcmFtIHBy
REM b3RlZ2lkb3MgZG8gb3JpZ2luYWwuCgogICAgVW0gw7puaWNvIGAlYCBwb2RlIHZpcmFyIG9w
REM ZXJhZG9yIGRlIGZvcm1hdGHDp8OjbyBubyBSZW4nUHkgcXVhbmRvIG8gdGV4dG8KICAgIHBh
REM c3NhIHBlbG8gbWVjYW5pc21vIGB3aGF0ICUgdGFnX3F1b3RpbmdfZGljdGAuIFBlcmNlbnR1
REM YWlzIGVtIHBhcmVzIChgJSVgKQogICAgasOhIHPDo28gc2VndXJvcyBlIHBlcm1hbmVjZW0g
REM Y29tbyBlc3TDo28uIFJ1bnMgw61tcGFyZXMgcmVjZWJlbSB1bSBgJWAgZXh0cmEuCiAgICAi
REM IiIKICAgIGRlZiByZXBsKG0pOgogICAgICAgIGJydXRvID0gbS5ncm91cCgwKQogICAgICAg
REM IHJldHVybiBicnV0byBpZiBsZW4oYnJ1dG8pICUgMiA9PSAwIGVsc2UgYnJ1dG8gKyB1IiUi
REM CiAgICByZXR1cm4gcmUuc3ViKHIiJSsiLCByZXBsLCB0ZXh0bykKCgpkZWYgbm9ybWFsaXph
REM cl9wZXJjZW50dWFpc19wYXJhX3JlaW50ZWdyYWNhbyhvcmlnaW5hbCwgdHJhZHV6aWRvKToK
REM ICAgICIiIlByZXNlcnZhIHBlcmNlbnR1YWlzIHF1ZSBleGlzdGlhbSBubyBvcmlnaW5hbCBl
REM IGVzY2FwYSBvcyBub3Zvcy4KCiAgICBUYW1iw6ltIGZ1bmNpb25hIHBhcmEgY2FjaGUvYXJx
REM dWl2b3MgZGUgdHJhZHXDp8OjbyBwcm9kdXppZG9zIHBvciB2ZXJzw7VlcwogICAgYW50ZXJp
REM b3JlcywgZXZpdGFuZG8gcXVlIHVtIGAlYCBsaXRlcmFsIHJlY8OpbS1pbnRyb2R1emlkbyBj
REM aGVndWUgYW8gY8OzZGlnbwogICAgZG8gam9nbyBzZW0gYCUlYC4gUGVyY2VudHVhaXMgb3Jp
REM Z2luYWlzIGNvbW8gYCVzYCBlIGZvcm1hdG9zIGRlIGRhdGEgYCVBYAogICAgc8OjbyBtYW50
REM aWRvcyBleGF0YW1lbnRlLgogICAgIiIiCiAgICBpZiB0cmFkdXppZG8gPT0gb3JpZ2luYWw6
REM CiAgICAgICAgcmV0dXJuIHRyYWR1emlkbwoKICAgIHRva2VucyA9IFtdCiAgICBwcm90ZWdp
REM ZG8gPSB0cmFkdXppZG8KICAgIGZvciBtIGluIFBFUkNFTlRVQUxfT1JJR0lOQUxfUkUuZmlu
REM ZGl0ZXIob3JpZ2luYWwpOgogICAgICAgIGJydXRvID0gbS5ncm91cCgwKQogICAgICAgIHRv
REM a2VuID0gdSJEREFDUHs6MDRkfVEiLmZvcm1hdChsZW4odG9rZW5zKSkKICAgICAgICBwb3Mg
REM PSBwcm90ZWdpZG8uZmluZChicnV0bykKICAgICAgICBpZiBwb3MgPCAwOgogICAgICAgICAg
REM ICBjb250aW51ZQogICAgICAgIHRva2Vucy5hcHBlbmQoKHRva2VuLCBicnV0bykpCiAgICAg
REM ICAgcHJvdGVnaWRvID0gcHJvdGVnaWRvWzpwb3NdICsgdG9rZW4gKyBwcm90ZWdpZG9bcG9z
REM ICsgbGVuKGJydXRvKTpdCgogICAgcHJvdGVnaWRvID0gZXNjYXBhcl9wZXJjZW50dWFpc19u
REM b3Zvc19nb29nbGUocHJvdGVnaWRvKQogICAgZm9yIHRva2VuLCBicnV0byBpbiB0b2tlbnM6
REM CiAgICAgICAgcHJvdGVnaWRvID0gcHJvdGVnaWRvLnJlcGxhY2UodG9rZW4sIGJydXRvKQog
REM ICAgcmV0dXJuIHByb3RlZ2lkbwoKClRBR19QQVJFU19HT09HTEVfUkUgPSByZS5jb21waWxl
REM KAogICAgcicoXHsoW0EtWmEtel9dW1x3Li1dKikoPzo9W159XHJcbl0qKT9cfSkoLio/KVx7
REM L1wyXH0nLAogICAgcmUuSSB8IHJlLlMKKQoKCmRlZiB0ZXh0b192aXNpdmVsX3RhZ19nb29n
REM bGUodGV4dG8pOgogICAgdGV4dG8gPSB0ZXh0b19jb21wYXRpdmVsKHRleHRvLCB1IiIpCiAg
REM ICB2YWxvciA9IHJlLnN1YihyJ1x7W159XHJcbl0qXH18XFtbXl1cclxuXSpcXScsIHUnJywg
REM dGV4dG8pCiAgICB2YWxvciA9IHZhbG9yLnJlcGxhY2UodSdcXG4nLCB1JyAnKS5yZXBsYWNl
REM KHUnXFxyJywgdScgJykucmVwbGFjZSh1J1xcdCcsIHUnICcpCiAgICByZXR1cm4gcmUuc3Vi
REM KHInXHMrJywgdScnLCB2YWxvcikKCgpkZWYgdmFsaWRhcl9pbnRlZ3JpZGFkZV90cmFkdWNh
REM b19nb29nbGUob3JpZ2luYWwsIHRyYWR1Y2FvKToKICAgIGlmIG5vdCBpc2luc3RhbmNlKG9y
REM aWdpbmFsLCBURVhUX1RZUEVTKSBvciBub3QgaXNpbnN0YW5jZSh0cmFkdWNhbywgVEVYVF9U
REM WVBFUyk6CiAgICAgICAgcmFpc2UgR29vZ2xlVHJhbnNsYXRlVmFsaWRhdGlvbkVycm9yKHUi
REM cmVzdWx0YWRvIGRlIHRyYWR1w6fDo28gbsOjbyDDqSB0ZXh0byIpCiAgICBpZiBvcmlnaW5h
REM bC5zdHJpcCgpIGFuZCBub3QgdHJhZHVjYW8uc3RyaXAoKToKICAgICAgICByYWlzZSBHb29n
REM bGVUcmFuc2xhdGVWYWxpZGF0aW9uRXJyb3IodSd0cmFkdcOnw6NvIHJldG9ybm91IHRleHRv
REM IHZhemlvJykKICAgIHZhbGlkYXJfdGVybW9zX3Byb3RlZ2lkb3NfZ29vZ2xlKG9yaWdpbmFs
REM LCB0cmFkdWNhbykKICAgIHBhcmVzX29yaWcgPSBsaXN0KFRBR19QQVJFU19HT09HTEVfUkUu
REM ZmluZGl0ZXIob3JpZ2luYWwpKQogICAgcGFyZXNfdHJhZCA9IGxpc3QoVEFHX1BBUkVTX0dP
REM T0dMRV9SRS5maW5kaXRlcih0cmFkdWNhbykpCiAgICBpZiBsZW4ocGFyZXNfb3JpZykgIT0g
REM bGVuKHBhcmVzX3RyYWQpOgogICAgICAgIHJhaXNlIEdvb2dsZVRyYW5zbGF0ZVZhbGlkYXRp
REM b25FcnJvcigKICAgICAgICAgICAgdSdxdWFudGlkYWRlIGRlIHRhZ3MgcGFyZWFkYXMgYWx0
REM ZXJhZGEgKHswfSAtPiB7MX0pJy5mb3JtYXQobGVuKHBhcmVzX29yaWcpLCBsZW4ocGFyZXNf
REM dHJhZCkpCiAgICAgICAgKQogICAgZm9yIHBhcl9vcmlnLCBwYXJfdHJhZCBpbiB6aXAocGFy
REM ZXNfb3JpZywgcGFyZXNfdHJhZCk6CiAgICAgICAgaWYgcGFyX29yaWcuZ3JvdXAoMikubG93
REM ZXIoKSAhPSBwYXJfdHJhZC5ncm91cCgyKS5sb3dlcigpOgogICAgICAgICAgICByYWlzZSBH
REM b29nbGVUcmFuc2xhdGVWYWxpZGF0aW9uRXJyb3IodSd0aXBvIGRlIHRhZyBhbHRlcmFkbyBk
REM dXJhbnRlIGEgdHJhZHXDp8OjbycpCiAgICAgICAgaWYgdGV4dG9fdmlzaXZlbF90YWdfZ29v
REM Z2xlKHBhcl9vcmlnLmdyb3VwKDMpKSBhbmQgbm90IHRleHRvX3Zpc2l2ZWxfdGFnX2dvb2ds
REM ZShwYXJfdHJhZC5ncm91cCgzKSk6CiAgICAgICAgICAgIHJhaXNlIEdvb2dsZVRyYW5zbGF0
REM ZVZhbGlkYXRpb25FcnJvcih1J3RleHRvIHZpc8OtdmVsIGRlbnRybyBkZSB0YWcgZm9pIGFw
REM YWdhZG8gcGVsYSB0cmFkdcOnw6NvJykKCgpQT1JUVUdVRVNfQUxUT19TSU5BTCA9IGZyb3pl
REM bnNldCh7CiAgICB1ImV1IiwgdSJ2b2PDqiIsIHUidm9jZSIsIHUiZWxlIiwgdSJlbGEiLCB1
REM ImVsZXMiLCB1ImVsYXMiLCB1Im7Ds3MiLCB1Im5vcyIsCiAgICB1Im1ldSIsIHUibWluaGEi
REM LCB1Im1ldXMiLCB1Im1pbmhhcyIsIHUic2V1IiwgdSJzdWEiLCB1InNldXMiLCB1InN1YXMi
REM LAogICAgdSJkbyIsIHUiZGEiLCB1ImRvcyIsIHUiZGFzIiwgdSJkZSIsIHUiZW0iLCB1Im5h
REM IiwgdSJuYXMiLCB1Im5vcyIsCiAgICB1InBhcmEiLCB1InBvciIsIHUiY29tIiwgdSJzZW0i
REM LCB1InNvYnJlIiwgdSJlbnRyZSIsIHUiYXTDqSIsIHUiYXRlIiwKICAgIHUicXVlIiwgdSJu
REM w6NvIiwgdSJuYW8iLCB1InNpbSIsIHUiasOhIiwgdSJqYSIsIHUiYXF1aSIsIHUiYWxpIiwK
REM ICAgIHUiaXNzbyIsIHUiaXN0byIsIHUiYXF1aWxvIiwgdSJlc3NlIiwgdSJlc3NhIiwgdSJl
REM c3RlIiwgdSJlc3RhIiwgdSJlc3NlcyIsIHUiZXNzYXMiLAogICAgdSJlc3TDoSIsIHUiZXN0
REM YSIsIHUic8OjbyIsIHUic2FvIiwgdSJmb2kiLCB1InZhaSIsIHUidm91IiwgdSJ2YW1vcyIs
REM CiAgICB1InRlbSIsIHUidGVuaG8iLCB1InRlbW9zIiwgdSJ0w6ptIiwgdSJ0w6ptIiwgdSJx
REM dWVybyIsIHUicXVlciIsIHUicG9kZSIsIHUicG9zc28iLAogICAgdSJhY2hvIiwgdSJzZWki
REM LCB1InNhYmUiLCB1ImZhemVyIiwgdSJmZWl0byIsIHUibXVpdG8iLCB1InBvdWNvIiwgdSJt
REM YWlzIiwgdSJtZW5vcyIsCiAgICB1InBvcnF1ZSIsIHUiY29tbyIsIHUicXVhbmRvIiwgdSJv
REM bmRlIiwgdSJxdWVtIiwgdSJxdWFsIiwgdSJxdWFscXVlciIsIHUidGFtYsOpbSIsIHUidGFt
REM YmVtIiwKICAgIHUiYWdvcmEiLCB1ImRlcG9pcyIsIHUiYW50ZXMiLCB1InNlbXByZSIsIHUi
REM bnVuY2EiLCB1Im1lc21vIiwgdSJtZXNtYSIsCiAgICB1ImVzdGF2YSIsIHUiZXN0YXZhbSIs
REM IHUiZXN0b3UiLCB1ImVzdGFtb3MiLCB1ImVzdMOjbyIsIHUiZXN0YW8iLCB1InNlciIsIHUi
REM ZXN0YXIiLAogICAgdSJ0b2NhbmRvIiwgdSJ0b2NhbmRvIiwgdSJ0cmlsaGEiLCB1InNvbm9y
REM YSIsIHUidmVyc8OjbyIsIHUidmVyc2FvIiwgdSJqb2dhYmlsaWRhZGUiLAogICAgdSJpbmRp
REM c3BvbsOtdmVsIiwgdSJpbmRpc3Bvbml2ZWwiLCB1InNlbGVjaW9uYXIiLCB1InNlbGVjaW9u
REM YWRvIiwgdSJjb25maWd1cmHDp8O1ZXMiLCB1ImNvbmZpZ3VyYWNvZXMiLAp9KQoKCkVOR0xJ
REM U0hfSElHSF9DT05GSURFTkNFID0gZnJvemVuc2V0KHsKICAgIHUidG9vayIsIHUic2NyZWVu
REM c2hvdCIsIHUicXVpY2siLCB1ImNvbXBsZXRlIiwgdSJtZXNzYWdlIiwKICAgIHUic2F2ZSIs
REM IHUibG9hZCIsIHUiYmFjayIsIHUibmV4dCIsIHUic2tpcCIsIHUiY29udGludWUiLCB1InNl
REM dHRpbmdzIiwKICAgIHUicHJlZmVyZW5jZXMiLCB1Imhpc3RvcnkiLCB1ImNhbmNlbCIsIHUi
REM ZGVsZXRlIiwgdSJjb25maXJtIiwgdSJ0eXBlIiwKICAgIHUiZmlsZSIsIHUiZmlsZXMiLCB1
REM ImNsb3NlIiwgdSJvcGVuIiwgdSJzdGFydCIsIHUiZW5kIiwgdSJyZXR1cm4iLAogICAgdSJy
REM ZW1vdmUiLCB1InJlc2V0IiwgdSJvcHRpb24iLCB1InBhZ2UiLCB1ImhlbHAiLCB1ImdhbWUi
REM LCB1InN0b3J5IiwKICAgIHUic2Nob29sIiwgdSJzdHVkZW50IiwgdSJmcmllbmQiLCB1ImZy
REM aWVuZHMiLCB1ImNvbnZlcnNhdGlvbiIsIHUic2l0dWF0aW9uIiwKfSkKCgpkZWYgZm9udGVf
REM cGFyZWNlX2luZ2xlc2FfZ29vZ2xlKHRleHRvKToKICAgICIiIkhldXLDrXN0aWNhIGNvbnNl
REM cnZhZG9yYSBwYXJhIHJlY29uaGVjZXIgZm9udGUgcmVhbG1lbnRlIGluZ2xlc2EuIiIiCiAg
REM ICB2YWxvciA9IHRleHRvX2NvbXBhdGl2ZWwodGV4dG8sIHUiIikKICAgIHZhbG9yID0gcmUu
REM c3ViKHIiXHtbXn1cclxuXSpcfXxcW1teXVxyXG5dKlxdIiwgdSIgIiwgdmFsb3IpCiAgICB2
REM YWxvciA9IHJlLnN1YihyImh0dHBzPzovL1xTKyIsIHUiICIsIHZhbG9yLCBmbGFncz1yZS5J
REM KQogICAgcGFsYXZyYXMgPSByZS5maW5kYWxsKHIiW0EtWmEtesOALcO/XSsoPzpbJ+KAmV1b
REM QS1aYS16w4Atw79dKyk/IiwgdmFsb3IubG93ZXIoKSkKICAgIGlmIG5vdCBwYWxhdnJhczoK
REM ICAgICAgICByZXR1cm4gRmFsc2UKICAgICMgTWFyY2Fkb3JlcyBwb3J0dWd1ZXNlcyB2ZW5j
REM ZW0gZXZpZMOqbmNpYSBpbmdsZXNhIGlzb2xhZGEuIElzc28gZXZpdGEgcXVlCiAgICAjIHTD
REM rXR1bG9zIGRlIG3DunNpY2FzLCBjcsOpZGl0b3Mgb3UgZnJhc2VzIG1pc3RhcyBqw6EgdHJh
REM ZHV6aWRhcyBzZWphbSBtYXJjYWRvcy4KICAgIHB0ID0gc3VtKDEgZm9yIHAgaW4gcGFsYXZy
REM YXMgaWYgcCBpbiBQT1JUVUdVRVNfQUxUT19TSU5BTCkKICAgIGlmIHB0ID49IDE6CiAgICAg
REM ICAgcmV0dXJuIEZhbHNlCiAgICBpZiBhbnkocCBpbiBFTkdMSVNIX1JFVFJZX0NPTlRSQUNU
REM SU9OUyBmb3IgcCBpbiBwYWxhdnJhcyk6CiAgICAgICAgcmV0dXJuIFRydWUKICAgICMgVW1h
REM IHBhbGF2cmEgVUkgZGUgYWx0YSBjb25maWFuw6dhIChTYXZlLCBMb2FkLCBTY3JlZW5zaG90
REM IGV0Yy4pIHBvZGUgc2VyIGluZ2xlc2Egc296aW5oYS4KICAgIGlmIGxlbihwYWxhdnJhcykg
REM PT0gMToKICAgICAgICByZXR1cm4gcGFsYXZyYXNbMF0gaW4gRU5HTElTSF9ISUdIX0NPTkZJ
REM REVOQ0UKICAgIGRpc3RpbnRpdmFzID0gc3VtKDEgZm9yIHAgaW4gcGFsYXZyYXMgaWYgcCBp
REM biBFTkdMSVNIX1JFVFJZX0RJU1RJTkNUSVZFIG9yIHAgaW4gRU5HTElTSF9ISUdIX0NPTkZJ
REM REVOQ0UpCiAgICBjb211bnMgPSBzdW0oMSBmb3IgcCBpbiBwYWxhdnJhcyBpZiBwIGluIEVO
REM R0xJU0hfUkVUUllfQ09NTU9OKQogICAgZGljYXMgPSBzdW0oMSBmb3IgcCBpbiBwYWxhdnJh
REM cyBpZiBwIGluIEVRVUFMX1RSQU5TTEFUSU9OX0VOR0xJU0hfSElOVFMpCiAgICBpZiBkaXN0
REM aW50aXZhcyA+PSAyOgogICAgICAgIHJldHVybiBUcnVlCiAgICBpZiBkaXN0aW50aXZhcyA+
REM PSAxIGFuZCBjb211bnMgPj0gMToKICAgICAgICByZXR1cm4gVHJ1ZQogICAgaWYgZGljYXMg
REM Pj0gMiBhbmQgbGVuKHBhbGF2cmFzKSA8PSA4OgogICAgICAgIHJldHVybiBUcnVlCiAgICBy
REM ZXR1cm4gbGVuKHBhbGF2cmFzKSA+PSA0IGFuZCBjb211bnMgPj0gMyBhbmQgcHQgPT0gMAoK
REM CmRlZiB2YWxpZGFyX3Jlc3VsdGFkb190cmFkdWNhb19nb29nbGUob3JpZ2luYWwsIHRyYWR1
REM Y2FvLCB0aXBvX2VudHJhZGEsIG9yaWdlbSwgZGVzdGlubyk6CiAgICAiIiJJbXBlZGUgcXVl
REM IGluZ2zDqnMgY2xhcmFtZW50ZSBuw6NvIHRyYWR1emlkbyBzZWphIGNvbnRhZG8gY29tbyBz
REM dWNlc3NvLiIiIgogICAgb3JpZ2luYWwgPSB0ZXh0b19jb21wYXRpdmVsKG9yaWdpbmFsLCB1
REM IiIpCiAgICB0cmFkdWNhbyA9IHRleHRvX2NvbXBhdGl2ZWwodHJhZHVjYW8sIHUiIikKICAg
REM IHRpcG9fZW50cmFkYSA9IHRleHRvX2NvbXBhdGl2ZWwodGlwb19lbnRyYWRhLCB1IiIpCiAg
REM ICBvcmlnZW0gPSB0ZXh0b19jb21wYXRpdmVsKG9yaWdlbSwgdSJhdXRvIikKICAgIGRlc3Rp
REM bm8gPSB0ZXh0b19jb21wYXRpdmVsKGRlc3Rpbm8sIHUicHQtQlIiKQogICAgdmFsaWRhcl9p
REM bnRlZ3JpZGFkZV90cmFkdWNhb19nb29nbGUob3JpZ2luYWwsIHRyYWR1Y2FvKQogICAgaWYg
REM bm90IGlzaW5zdGFuY2Uob3JpZ2luYWwsIFRFWFRfVFlQRVMpIG9yIG5vdCBpc2luc3RhbmNl
REM KHRyYWR1Y2FvLCBURVhUX1RZUEVTKToKICAgICAgICByYWlzZSBHb29nbGVUcmFuc2xhdGVW
REM YWxpZGF0aW9uRXJyb3IodSJyZXN1bHRhZG8gZGUgdHJhZHXDp8OjbyBuw6NvIMOpIHRleHRv
REM IikKICAgIGlmIG5vdCBkZXN0aW5vIG9yIG5vdCBkZXN0aW5vLmxvd2VyKCkuc3RhcnRzd2l0
REM aCh1InB0Iik6CiAgICAgICAgcmV0dXJuCiAgICB0aXBvID0gdGlwb19lbnRyYWRhIG9yIHUi
REM IgogICAgdGlwb3NfdGV4dHVhaXMgPSB7CiAgICAgICAgdSJkaWFsb2dvIiwgdSJyZW5weV9u
REM YXRpdm9fZGlhbG9nbyIsIHUicmVucHlfbmF0aXZvX3N0cmluZyIsCiAgICAgICAgdSJuYXJy
REM YXRpdmEiLCB1InVpIiwgdSJwb2VtYV9jb3JwbyIsIHUicG9lbWFfcGFsYXZyYSIsIHUicG9l
REM bWFfcGFsYXZyYV90eHQiLAogICAgICAgIHUibm9tZV9ncnVwbyIsIHUidmFyaWF2ZWxfdGV4
REM dG8iLAogICAgfQogICAgaWYgdGlwbyBub3QgaW4gdGlwb3NfdGV4dHVhaXM6CiAgICAgICAg
REM cmV0dXJuCiAgICAjIFNlIGEgc2HDrWRhIGZvciBleGF0YW1lbnRlIHVtYSBjb3JyZcOnw6Nv
REM IGRldGVybWluw61zdGljYSBjYWRhc3RyYWRhIHBlbG8gRERBQywKICAgICMgZWxhIGrDoSBm
REM b2kgcmV2aXNhZGEgcGVsbyBwcsOzcHJpbyBwcm9qZXRvLiBOw6NvIGEgcmVqZWl0YXIgcGVs
REM byBkZXRlY3RvciBkZQogICAgIyBpbmdsw6pzIHJlc2lkdWFsIHBvciBjb250ZXIgbm9tZXMg
REM cHLDs3ByaW9zLCB0w610dWxvcywgY3LDqWRpdG9zIG91IG1hcmNhcy4KICAgIGZvciByZWdy
REM YSBpbiBnbG9iYWxzKCkuZ2V0KHUiQ09SUkVDT0VTX0lORElWSURVQUlTX0dPT0dMRSIsIFtd
REM KToKICAgICAgICBpZiByZWdyYS5nZXQodSJvcmlnZW0iKSA9PSBvcmlnaW5hbCBhbmQgcmVn
REM cmEuZ2V0KHUidHJhZHVjYW8iKSA9PSB0cmFkdWNhbzoKICAgICAgICAgICAgcmV0dXJuCiAg
REM ICBmb250ZSA9IChvcmlnaW5hbCBvciB1IiIpLnN0cmlwKCkKICAgIHNhaWRhID0gKHRyYWR1
REM Y2FvIG9yIHUiIikuc3RyaXAoKQogICAgb3JpZ2VtX2xvd2VyID0gKG9yaWdlbSBvciB1ImF1
REM dG8iKS5sb3dlcigpCiAgICBmb250ZV9pbmdsZXNhID0gZm9udGVfcGFyZWNlX2luZ2xlc2Ff
REM Z29vZ2xlKGZvbnRlKQogICAgaWYgbm90IGZvbnRlX2luZ2xlc2E6CiAgICAgICAgcmV0dXJu
REM CiAgICBpZiBzYWlkYSA9PSBmb250ZSBhbmQgKG9yaWdlbV9sb3dlciA9PSB1ImF1dG8iIG9y
REM IG9yaWdlbV9sb3dlci5zdGFydHN3aXRoKHUiZW4iKSk6CiAgICAgICAgcmFpc2UgR29vZ2xl
REM VHJhbnNsYXRlVmFsaWRhdGlvbkVycm9yKHUiR29vZ2xlIGRldm9sdmV1IG8gdGV4dG8gb3Jp
REM Z2luYWwgZW0gaW5nbMOqcyBzZW0gdHJhZHXDp8OjbyBwYXJhIFBULUJSIikKICAgIGlmIHBh
REM cmVjZV9yZXNpZHVvX2luZ2xlc19yZXN1bHRhZG8oZm9udGUsIHNhaWRhLCB0aXBvKToKICAg
REM ICAgICByYWlzZSBHb29nbGVUcmFuc2xhdGVWYWxpZGF0aW9uRXJyb3IodSJyZXN1bHRhZG8g
REM Y29udMOpbSBpbmdsw6pzIHJlc2lkdWFsIGFww7NzIGEgdHJhZHXDp8OjbyBwYXJhIFBULUJS
REM IikKCgpkZWYgcmVwYXJhcl9jb250ZXVkb190YWdfdmF6aW9fZ29vZ2xlKG9yaWdpbmFsLCB0
REM cmFkdWNhbywgY2xpZW50ZSwgb3JpZ2VtLCBkZXN0aW5vKToKICAgIHBhcmVzX29yaWcgPSBs
REM aXN0KFRBR19QQVJFU19HT09HTEVfUkUuZmluZGl0ZXIob3JpZ2luYWwpKQogICAgcGFyZXNf
REM dHJhZCA9IGxpc3QoVEFHX1BBUkVTX0dPT0dMRV9SRS5maW5kaXRlcih0cmFkdWNhbykpCiAg
REM ICBpZiBsZW4ocGFyZXNfb3JpZykgIT0gbGVuKHBhcmVzX3RyYWQpOgogICAgICAgIHJldHVy
REM biBOb25lCiAgICBwYXJ0ZXMgPSBbXQogICAgcG9zID0gMAogICAgYWx0ZXJvdSA9IEZhbHNl
REM CiAgICBmb3IgcG9yaWcsIHB0cmFkIGluIHppcChwYXJlc19vcmlnLCBwYXJlc190cmFkKToK
REM ICAgICAgICBpZiBwb3JpZy5ncm91cCgyKS5sb3dlcigpICE9IHB0cmFkLmdyb3VwKDIpLmxv
REM d2VyKCk6CiAgICAgICAgICAgIHJldHVybiBOb25lCiAgICAgICAgcGFydGVzLmFwcGVuZCh0
REM cmFkdWNhb1twb3M6cHRyYWQuc3RhcnQoMyldKQogICAgICAgIGludGVyaW9yX29yaWcgPSBw
REM b3JpZy5ncm91cCgzKQogICAgICAgIGludGVyaW9yX3RyYWQgPSBwdHJhZC5ncm91cCgzKQog
REM ICAgICAgIGlmIHRleHRvX3Zpc2l2ZWxfdGFnX2dvb2dsZShpbnRlcmlvcl9vcmlnKSBhbmQg
REM bm90IHRleHRvX3Zpc2l2ZWxfdGFnX2dvb2dsZShpbnRlcmlvcl90cmFkKToKICAgICAgICAg
REM ICAgIyBUcmFkdXogc29tZW50ZSBvIGNvbnRlw7pkbyBxdWUgbyBHb29nbGUgYXBhZ291LCBw
REM cmVzZXJ2YW5kbyBhIHRhZwogICAgICAgICAgICAjIGV4dGVybmEgasOhIHRyYWR1emlkYSBl
REM IG9zIHRva2VucyBpbnRlcm5vcy4KICAgICAgICAgICAgcHJvdGVnaWRvLCB0b2tlbnMgPSBw
REM cm90ZWdlcl90b2tlbnNfZ29vZ2xlKGludGVyaW9yX29yaWcpCiAgICAgICAgICAgIHJlcGFy
REM YWRvID0gY2xpZW50ZS50cmFkdXppcihwcm90ZWdpZG8sIG9yaWdlbSwgZGVzdGlubykKICAg
REM ICAgICAgICAgdmFsaWRhcl90b2tlbnNfZ29vZ2xlX3ByZXNlcnZhZG9zKHJlcGFyYWRvLCB0
REM b2tlbnMpCiAgICAgICAgICAgIHJlcGFyYWRvID0gZXNjYXBhcl9wZXJjZW50dWFpc19ub3Zv
REM c19nb29nbGUocmVwYXJhZG8pCiAgICAgICAgICAgIHJlcGFyYWRvID0gcmVzdGF1cmFyX3Rv
REM a2Vuc19nb29nbGUocmVwYXJhZG8sIHRva2VucykKICAgICAgICAgICAgcGFydGVzLmFwcGVu
REM ZChyZXBhcmFkbykKICAgICAgICAgICAgYWx0ZXJvdSA9IFRydWUKICAgICAgICBlbHNlOgog
REM ICAgICAgICAgICBwYXJ0ZXMuYXBwZW5kKGludGVyaW9yX3RyYWQpCiAgICAgICAgcG9zID0g
REM cHRyYWQuZW5kKDMpCiAgICAgICAgcGFydGVzLmFwcGVuZCh0cmFkdWNhb1twb3M6cHRyYWQu
REM ZW5kKCldKQogICAgICAgIHBvcyA9IHB0cmFkLmVuZCgpCiAgICBwYXJ0ZXMuYXBwZW5kKHRy
REM YWR1Y2FvW3BvczpdKQogICAgcmV0dXJuIHUiIi5qb2luKHBhcnRlcykgaWYgYWx0ZXJvdSBl
REM bHNlIE5vbmUKCgpkZWYgYWRpY2lvbmFyX21hcmNhZG9yZXNfdGFnc19nb29nbGUodGV4dG8p
REM OgogICAgY29udGFkb3IgPSBbMF0KICAgIGRlZiByZXBsKG0pOgogICAgICAgIGNvbnRldWRv
REM ID0gbS5ncm91cCgzKQogICAgICAgIGlmIG5vdCB0ZXh0b192aXNpdmVsX3RhZ19nb29nbGUo
REM Y29udGV1ZG8pOgogICAgICAgICAgICByZXR1cm4gbS5ncm91cCgwKQogICAgICAgIG4gPSBj
REM b250YWRvclswXQogICAgICAgIGNvbnRhZG9yWzBdICs9IDEKICAgICAgICBpbmljaW8gPSB1
REM J0REQUNNezowNGR9UScuZm9ybWF0KG4gKiAyKQogICAgICAgIGZpbSA9IHUnRERBQ017OjA0
REM ZH1RJy5mb3JtYXQobiAqIDIgKyAxKQogICAgICAgIHJldHVybiBtLmdyb3VwKDEpICsgaW5p
REM Y2lvICsgY29udGV1ZG8gKyBmaW0gKyB1J3svJyArIG0uZ3JvdXAoMikgKyB1J30nCiAgICBy
REM ZXR1cm4gVEFHX1BBUkVTX0dPT0dMRV9SRS5zdWIocmVwbCwgdGV4dG8pCgoKZGVmIHJlbW92
REM ZXJfbWFyY2Fkb3Jlc190YWdzX2dvb2dsZSh0ZXh0byk6CiAgICByZXR1cm4gcmUuc3ViKHIn
REM RERBQ01cZHs0fVEnLCB1JycsIHRleHRvLCBmbGFncz1yZS5JKQoKCmRlZiB2YWxpZGFyX3Rv
REM a2Vuc19nb29nbGVfcHJlc2VydmFkb3ModGV4dG8sIHRva2Vucyk6CiAgICAjIEEgcHJlc2Vu
REM w6dhIGluZGl2aWR1YWwgbsOjbyBiYXN0YTogbyB0cmFkdXRvciBwb2RlIGR1cGxpY2FyIG91
REM IHJlb3JkZW5hcgogICAgIyB0b2tlbnMgc2VtIHJlbW92w6otbG9zLiBBIHNlcXXDqm5jaWEg
REM ZGV2b2x2aWRhIGRldmUgc2VyIGlkw6pudGljYSDDoCBlc3BlcmFkYS4KICAgIGVzcGVyYWRv
REM ID0gW3Rva2VuLmxvd2VyKCkgZm9yIHRva2VuLCBfIGluIHRva2Vuc10KICAgIGVuY29udHJh
REM ZG9zID0gW3Rva2VuLmxvd2VyKCkgZm9yIHRva2VuIGluIHJlLmZpbmRhbGwocidEREFDWlxk
REM ezR9UScsIHRleHRvLCByZS5JKV0KCiAgICBpZiBlbmNvbnRyYWRvcyAhPSBlc3BlcmFkbzoK
REM ICAgICAgICBpZiBub3QgZW5jb250cmFkb3M6CiAgICAgICAgICAgIHJhaXNlIEdvb2dsZVRy
REM YW5zbGF0ZVZhbGlkYXRpb25FcnJvcih1J3Rva2VucyBwcm90ZWdpZG9zIGZvcmFtIHJlbW92
REM aWRvcyBwZWxhIHRyYWR1w6fDo28nKQogICAgICAgIGlmIGxlbihlbmNvbnRyYWRvcykgIT0g
REM bGVuKGVzcGVyYWRvKToKICAgICAgICAgICAgcmFpc2UgR29vZ2xlVHJhbnNsYXRlVmFsaWRh
REM dGlvbkVycm9yKAogICAgICAgICAgICAgICAgdSdzZXF1w6puY2lhIGRlIHRva2VucyBwcm90
REM ZWdpZG9zIGFsdGVyYWRhOiBxdWFudGlkYWRlIGVzcGVyYWRhIHswfSwgcmVjZWJpZGEgezF9
REM Jy5mb3JtYXQoCiAgICAgICAgICAgICAgICAgICAgbGVuKGVzcGVyYWRvKSwgbGVuKGVuY29u
REM dHJhZG9zKSkpCiAgICAgICAgcmFpc2UgR29vZ2xlVHJhbnNsYXRlVmFsaWRhdGlvbkVycm9y
REM KHUnc2VxdcOqbmNpYSBkZSB0b2tlbnMgcHJvdGVnaWRvcyBhbHRlcmFkYTogb3JkZW0vZHVw
REM bGljYcOnw6NvIGRldGVjdGFkYScpCgoKZGVmIHRyYWR1emlyX3Bvcl9mcmFnbWVudG9zX3Nl
REM bV90b2tlbnNfZ29vZ2xlKGNsaWVudGUsIHRleHRvLCBvcmlnZW0sIGRlc3Rpbm8pOgogICAg
REM IiIiRmFsbGJhY2sgcXVhbmRvIG8gR29vZ2xlIGVsaW1pbmEgcGxhY2Vob2xkZXJzIG9wYWNv
REM cy4iIiIKICAgIHBhcnRlcyA9IFtdCiAgICBwb3MgPSAwCiAgICBlbmNvbnRyb3VfdG9rZW4g
REM PSBGYWxzZQogICAgZm9yIG0gaW4gVE9LRU5fUFJPVEVDQU9fUkUuZmluZGl0ZXIodGV4dG8p
REM OgogICAgICAgIGVuY29udHJvdV90b2tlbiA9IFRydWUKICAgICAgICBmcmFnbWVudG8gPSB0
REM ZXh0b1twb3M6bS5zdGFydCgpXQogICAgICAgIGlmIGZyYWdtZW50bzoKICAgICAgICAgICAg
REM aWYgcmUuc2VhcmNoKHIiW15cV1xkX10iLCBmcmFnbWVudG8sIHJlLlVOSUNPREUpOgogICAg
REM ICAgICAgICAgICAgcGFydGVzLmFwcGVuZChjbGllbnRlLnRyYWR1emlyKGZyYWdtZW50bywg
REM b3JpZ2VtLCBkZXN0aW5vKSkKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHBh
REM cnRlcy5hcHBlbmQoZnJhZ21lbnRvKQogICAgICAgIHBhcnRlcy5hcHBlbmQobS5ncm91cCgw
REM KSkKICAgICAgICBwb3MgPSBtLmVuZCgpCiAgICBmaW5hbCA9IHRleHRvW3BvczpdCiAgICBp
REM ZiBmaW5hbDoKICAgICAgICBpZiByZS5zZWFyY2gociJbXlxXXGRfXSIsIGZpbmFsLCByZS5V
REM TklDT0RFKToKICAgICAgICAgICAgcGFydGVzLmFwcGVuZChjbGllbnRlLnRyYWR1emlyKGZp
REM bmFsLCBvcmlnZW0sIGRlc3Rpbm8pKQogICAgICAgIGVsc2U6CiAgICAgICAgICAgIHBhcnRl
REM cy5hcHBlbmQoZmluYWwpCiAgICBpZiBub3QgZW5jb250cm91X3Rva2VuOgogICAgICAgIHJl
REM dHVybiBOb25lCiAgICByZXN1bHRhZG8gPSB1IiIuam9pbihwYXJ0ZXMpCiAgICByZXN1bHRh
REM ZG8gPSBlc2NhcGFyX3BlcmNlbnR1YWlzX25vdm9zX2dvb2dsZShyZXN1bHRhZG8pCiAgICB2
REM YWxpZGFyX2ludGVncmlkYWRlX3RyYWR1Y2FvX2dvb2dsZSh0ZXh0bywgcmVzdWx0YWRvKQog
REM ICAgcmV0dXJuIHJlc3VsdGFkbwoKCmRlZiBleHRyYWlyX3BheWxvYWRfcnBjX2dvb2dsZShi
REM cnV0byk6CiAgICAjIGJhdGNoZXhlY3V0ZSByZXR1cm5zIGZyYW1lZCBKU09OOyBsb2NhdGUg
REM dGhlIGZpcnN0IGNvbXBsZXRlIGZyYW1lIHRoYXQgY29udGFpbnMgTWtFV0JjLgogICAgZm9y
REM IGxpbmhhX2lkeCwgbGluaGEgaW4gZW51bWVyYXRlKGJydXRvLnNwbGl0KHUiXG4iKSk6CiAg
REM ICAgICAgaWYgdSciJyArIEdPT0dMRV9SUENfSUQgKyB1JyInIG5vdCBpbiBsaW5oYVs6MjAw
REM XToKICAgICAgICAgICAgY29udGludWUKICAgICAgICByZXNwID0gdSIiCiAgICAgICAgYWJl
REM cnR1cmEgPSBmZWNoYW1lbnRvID0gMAogICAgICAgIGVtX3N0cmluZyA9IEZhbHNlCiAgICAg
REM ICAgZXNjYXBhZG8gPSBGYWxzZQogICAgICAgIGZvciBsaW5oYTIgaW4gYnJ1dG8uc3BsaXQo
REM dSJcbiIpW2xpbmhhX2lkeDpdOgogICAgICAgICAgICByZXNwICs9IGxpbmhhMgogICAgICAg
REM ICAgICBmb3IgY2hhciBpbiBsaW5oYTI6CiAgICAgICAgICAgICAgICBpZiBjaGFyID09IHUn
REM IicgYW5kIG5vdCBlc2NhcGFkbzoKICAgICAgICAgICAgICAgICAgICBlbV9zdHJpbmcgPSBu
REM b3QgZW1fc3RyaW5nCiAgICAgICAgICAgICAgICBpZiBub3QgZW1fc3RyaW5nOgogICAgICAg
REM ICAgICAgICAgICAgIGlmIGNoYXIgPT0gdSJbIjogYWJlcnR1cmEgKz0gMQogICAgICAgICAg
REM ICAgICAgICAgIGVsaWYgY2hhciA9PSB1Il0iOiBmZWNoYW1lbnRvICs9IDEKICAgICAgICAg
REM ICAgICAgIGVzY2FwYWRvID0gKGNoYXIgPT0gdSJcXCIgYW5kIG5vdCBlc2NhcGFkbykKICAg
REM ICAgICAgICAgICAgIGlmIGNoYXIgIT0gdSJcXCI6IGVzY2FwYWRvID0gRmFsc2UKICAgICAg
REM ICAgICAgaWYgYWJlcnR1cmEgYW5kIGFiZXJ0dXJhID09IGZlY2hhbWVudG86CiAgICAgICAg
REM ICAgICAgICBicmVhawogICAgICAgICAgICByZXNwICs9IHUiXG4iCiAgICAgICAgaWYgbm90
REM IHJlc3A6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgdHJ5OgogICAgICAgICAgICBl
REM bnZlbG9wZSA9IGpzb24ubG9hZHMocmVzcCkKICAgICAgICAgICAgaWYgaXNpbnN0YW5jZShl
REM bnZlbG9wZSwgbGlzdCkgYW5kIGVudmVsb3BlIGFuZCBpc2luc3RhbmNlKGVudmVsb3BlWzBd
REM LCBsaXN0KSBhbmQgbGVuKGVudmVsb3BlWzBdKSA+PSAzOgogICAgICAgICAgICAgICAgcmF3
REM ID0gZW52ZWxvcGVbMF1bMl0KICAgICAgICAgICAgICAgIHJldHVybiBqc29uLmxvYWRzKHJh
REM dykgaWYgaXNpbnN0YW5jZShyYXcsIHN0cikgZWxzZSByYXcKICAgICAgICBleGNlcHQgRXhj
REM ZXB0aW9uOgogICAgICAgICAgICBjb250aW51ZQogICAgcmFpc2UgVmFsdWVFcnJvcih1ImVz
REM dHJ1dHVyYSBSUEMgZG8gR29vZ2xlIG7Do28gcmVjb25oZWNpZGEiKQoKCmRlZiBfcHJvY3Vy
REM YXJfdHJhZHVjYW9fcnBjX2dvb2dsZShvYmopOgogICAgaWYgaXNpbnN0YW5jZShvYmosIGxp
REM c3QpOgogICAgICAgIGlmIGxlbihvYmopID4gNSBhbmQgaXNpbnN0YW5jZShvYmpbNV0sIGxp
REM c3QpOgogICAgICAgICAgICB2YWxvcmVzID0gW3BbMF0gZm9yIHAgaW4gb2JqWzVdIGlmIGlz
REM aW5zdGFuY2UocCwgbGlzdCkgYW5kIHAgYW5kIGlzaW5zdGFuY2UocFswXSwgVEVYVF9UWVBF
REM UykgYW5kIHBbMF1dCiAgICAgICAgICAgIGlmIHZhbG9yZXM6CiAgICAgICAgICAgICAgICBz
REM ZXBhcmFkb3IgPSB1IiAiIGlmIGxlbihvYmopID4gMyBhbmQgb2JqWzNdIGVsc2UgdSIiCiAg
REM ICAgICAgICAgICAgICByZXR1cm4gc2VwYXJhZG9yLmpvaW4odmFsb3JlcykKICAgICAgICBm
REM b3IgaXRlbSBpbiBvYmo6CiAgICAgICAgICAgIHJlc3VsdGFkbyA9IF9wcm9jdXJhcl90cmFk
REM dWNhb19ycGNfZ29vZ2xlKGl0ZW0pCiAgICAgICAgICAgIGlmIHJlc3VsdGFkbzoKICAgICAg
REM ICAgICAgICAgIHJldHVybiByZXN1bHRhZG8KICAgIGVsaWYgaXNpbnN0YW5jZShvYmosIGRp
REM Y3QpOgogICAgICAgIGZvciBpdGVtIGluIG9iai52YWx1ZXMoKToKICAgICAgICAgICAgcmVz
REM dWx0YWRvID0gX3Byb2N1cmFyX3RyYWR1Y2FvX3JwY19nb29nbGUoaXRlbSkKICAgICAgICAg
REM ICAgaWYgcmVzdWx0YWRvOgogICAgICAgICAgICAgICAgcmV0dXJuIHJlc3VsdGFkbwogICAg
REM cmV0dXJuIE5vbmUKCgpkZWYgZXh0cmFpcl90cmFkdWNhb19ycGNfZ29vZ2xlKHBheWxvYWQp
REM OgogICAgdHJ5OgogICAgICAgIGJsb2NvID0gcGF5bG9hZFsxXVswXVswXQogICAgICAgIGlm
REM IGlzaW5zdGFuY2UoYmxvY28sIGxpc3QpIGFuZCBsZW4oYmxvY28pID4gNSBhbmQgaXNpbnN0
REM YW5jZShibG9jb1s1XSwgbGlzdCk6CiAgICAgICAgICAgIHZhbG9yZXMgPSBbcFswXSBmb3Ig
REM cCBpbiBibG9jb1s1XSBpZiBpc2luc3RhbmNlKHAsIGxpc3QpIGFuZCBwIGFuZCBpc2luc3Rh
REM bmNlKHBbMF0sIHN0cildCiAgICAgICAgICAgIGlmIHZhbG9yZXM6CiAgICAgICAgICAgICAg
REM ICByZXR1cm4gKHUiICIgaWYgbGVuKGJsb2NvKSA+IDMgYW5kIGJsb2NvWzNdIGVsc2UgdSIi
REM KS5qb2luKHZhbG9yZXMpCiAgICAgICAgaWYgaXNpbnN0YW5jZShibG9jbywgbGlzdCkgYW5k
REM IGJsb2NvIGFuZCBpc2luc3RhbmNlKGJsb2NvWzBdLCBzdHIpIGFuZCBibG9jb1swXToKICAg
REM ICAgICAgICAgcmV0dXJuIGJsb2NvWzBdCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAg
REM IHBhc3MKICAgIHJlc3VsdGFkbyA9IF9wcm9jdXJhcl90cmFkdWNhb19ycGNfZ29vZ2xlKHBh
REM eWxvYWQpCiAgICBpZiByZXN1bHRhZG86CiAgICAgICAgcmV0dXJuIHJlc3VsdGFkbwogICAg
REM cmFpc2UgVmFsdWVFcnJvcih1ImVzdHJ1dHVyYSBSUEMgZGUgdHJhZHXDp8OjbyBuw6NvIHJl
REM Y29uaGVjaWRhIikKCgpjbGFzcyBHb29nbGVUcmFuc2xhdGVFcnJvcihSdW50aW1lRXJyb3Ip
REM OgogICAgcGFzcwoKCmNsYXNzIEdvb2dsZVRyYW5zbGF0ZVZhbGlkYXRpb25FcnJvcihHb29n
REM bGVUcmFuc2xhdGVFcnJvcik6CiAgICBwYXNzCgoKY2xhc3MgR29vZ2xlUmF0ZUxpbWl0RXJy
REM b3IoR29vZ2xlVHJhbnNsYXRlRXJyb3IpOgogICAgcGFzcwoKCmNsYXNzIEdvb2dsZVRocm90
REM dGxlKG9iamVjdCk6CiAgICAiIiJSaXRtbyBnbG9iYWwgY29tcGFydGlsaGFkbyBwb3IgdG9k
REM b3Mgb3Mgd29ya2VycyBkbyBwb29sIEdvb2dsZS4KCiAgICBEdWFzIHJlc3BvbnNhYmlsaWRh
REM ZGVzOgogICAgICAxKSBHYXJhbnRpciB1bSBpbnRlcnZhbG8gbcOtbmltbyBlbnRyZSBRVUFM
REM UVVFUiByZXF1aXNpw6fDo28sIG1lc21vIHZpbmRvCiAgICAgICAgIGRlIHdvcmtlcnMvaG9z
REM dHMgZGlmZXJlbnRlcyAodGhyb3R0bGluZyBwb3IgdGVtcG8sIG7Do28gcG9yIHdvcmtlciku
REM CiAgICAgIDIpIFNlIG8gR29vZ2xlIHJlc3BvbmRlciA0MjksIGFwbGljYXIgdW0gY29vbGRv
REM d24gcXVlIHBhdXNhIFRPRE8gbXVuZG8KICAgICAgICAgKG7Do28gc8OzIHF1ZW0gbGV2b3Ug
REM byA0MjkpIGUgY3Jlc2NlIGEgY2FkYSA0Mjkgc2VndWlkbywgdm9sdGFuZG8gYW8KICAgICAg
REM ICAgdmFsb3IgaW5pY2lhbCBkZXBvaXMgZGUgdW0gdGVtcG8gc2VtIGJsb3F1ZWlvcy4KICAg
REM ICIiIgoKICAgIGRlZiBfX2luaXRfXyhzZWxmLCBpbnRlcnZhbG9fbWluaW1vLCBiYWNrb2Zm
REM X2luaWNpYWwsIGJhY2tvZmZfbWF4aW1vLCBiYWNrb2ZmX211bHQpOgogICAgICAgIHNlbGYu
REM aW50ZXJ2YWxvX21pbmltbyA9IGludGVydmFsb19taW5pbW8KICAgICAgICBzZWxmLmJhY2tv
REM ZmZfaW5pY2lhbCA9IGJhY2tvZmZfaW5pY2lhbAogICAgICAgIHNlbGYuYmFja29mZl9tYXhp
REM bW8gPSBiYWNrb2ZmX21heGltbwogICAgICAgIHNlbGYuYmFja29mZl9tdWx0ID0gYmFja29m
REM Zl9tdWx0CiAgICAgICAgc2VsZi5sb2NrID0gdGhyZWFkaW5nLkxvY2soKQogICAgICAgIHNl
REM bGYucHJveGltYV9saWJlcmFjYW8gPSAwLjAKICAgICAgICBzZWxmLmJhY2tvZmZfYXR1YWwg
REM PSBiYWNrb2ZmX2luaWNpYWwKCiAgICBkZWYgYWd1YXJkYXJfdmV6KHNlbGYpOgogICAgICAg
REM IHdoaWxlIFRydWU6CiAgICAgICAgICAgIHdpdGggc2VsZi5sb2NrOgogICAgICAgICAgICAg
REM ICAgYWdvcmEgPSB0aW1lLnBlcmZfY291bnRlcigpCiAgICAgICAgICAgICAgICBlc3BlcmEg
REM PSBzZWxmLnByb3hpbWFfbGliZXJhY2FvIC0gYWdvcmEKICAgICAgICAgICAgICAgIGlmIGVz
REM cGVyYSA8PSAwOgogICAgICAgICAgICAgICAgICAgIHNlbGYucHJveGltYV9saWJlcmFjYW8g
REM PSBhZ29yYSArIHNlbGYuaW50ZXJ2YWxvX21pbmltbwogICAgICAgICAgICAgICAgICAgIHJl
REM dHVybgogICAgICAgICAgICB0aW1lLnNsZWVwKG1pbihlc3BlcmEsIDEuMCkpCgogICAgZGVm
REM IHJlZ2lzdHJhcl9ibG9xdWVpbyhzZWxmLCBsb2c9Tm9uZSk6CiAgICAgICAgd2l0aCBzZWxm
REM LmxvY2s6CiAgICAgICAgICAgIHBhdXNhID0gc2VsZi5iYWNrb2ZmX2F0dWFsCiAgICAgICAg
REM ICAgIHNlbGYucHJveGltYV9saWJlcmFjYW8gPSB0aW1lLnBlcmZfY291bnRlcigpICsgcGF1
REM c2EKICAgICAgICAgICAgc2VsZi5iYWNrb2ZmX2F0dWFsID0gbWluKHNlbGYuYmFja29mZl9h
REM dHVhbCAqIHNlbGYuYmFja29mZl9tdWx0LCBzZWxmLmJhY2tvZmZfbWF4aW1vKQogICAgICAg
REM IGlmIGxvZzoKICAgICAgICAgICAgbG9nLmF2aXNvKHUiR29vZ2xlIHNpbmFsaXpvdSBsaW1p
REM dGUgZGUgcmVxdWlzacOnw7VlcyAoNDI5KTsgcGF1c2FuZG8gVE9ET1Mgb3Mgd29ya2VycyBw
REM b3IgezA6LjBmfXMgYW50ZXMgZGUgY29udGludWFyLiIuZm9ybWF0KHBhdXNhKSkKICAgICAg
REM ICB0aW1lLnNsZWVwKHBhdXNhKQoKICAgIGRlZiByZWdpc3RyYXJfc3VjZXNzbyhzZWxmKToK
REM ICAgICAgICB3aXRoIHNlbGYubG9jazoKICAgICAgICAgICAgc2VsZi5iYWNrb2ZmX2F0dWFs
REM ID0gc2VsZi5iYWNrb2ZmX2luaWNpYWwKCgpHT09HTEVfVEhST1RUTEUgPSBHb29nbGVUaHJv
REM dHRsZShHT09HTEVfSU5URVJWQUxPX01JTklNTywgR09PR0xFX0JBQ0tPRkZfSU5JQ0lBTCwg
REM R09PR0xFX0JBQ0tPRkZfTUFYSU1PLCBHT09HTEVfQkFDS09GRl9NVUxUSVBMSUNBRE9SKQoK
REM CmNsYXNzIEdvb2dsZUdUWENsaWVudChvYmplY3QpOgogICAgIiIiQ2xpZW50ZSBHb29nbGUg
REM VHJhbnNsYXRlIFdlYiBhbHRlcm5hdGl2byB2aWEgZW5kcG9pbnQgR1RYIHDDumJsaWNvLgoK
REM ICAgIENvbnRpbnVhIHNlbmRvIEdvb2dsZSBUcmFuc2xhdGUgV2ViLCBzZW0gQ2xvdWQgVHJh
REM bnNsYXRpb24vQVBJIGtleS4gQ2FkYQogICAgY2xpZW50ZSBwb3NzdWkgc3VhIHByw7Nwcmlh
REM IHNlc3PDo28vY29va2llIGphciwgbWFzIG8gRERBQyBtYW50w6ltIHVtCiAgICByYXRlLWxp
REM bWl0IGdsb2JhbCBwYXJhIGV2aXRhciByYWphZGFzLgogICAgIiIiCiAgICBkZWYgX19pbml0
REM X18oc2VsZiwgbm9tZV9ob3N0PXUidHJhbnNsYXRlLmdvb2dsZWFwaXMuY29tIiwgaG9zdF9i
REM YXNlPXUiaHR0cHM6Ly90cmFuc2xhdGUuZ29vZ2xlYXBpcy5jb20iLCBsb2c9Tm9uZSwgd29y
REM a2VyX2lkPTApOgogICAgICAgIHNlbGYubm9tZV9ob3N0ID0gbm9tZV9ob3N0CiAgICAgICAg
REM c2VsZi5ob3N0X2Jhc2UgPSBob3N0X2Jhc2UKICAgICAgICBzZWxmLmxvZyA9IGxvZwogICAg
REM ICAgIHNlbGYud29ya2VyX2lkID0gd29ya2VyX2lkCiAgICAgICAgc2VsZi5yZWFkeSA9IEZh
REM bHNlCiAgICAgICAgc2VsZi5vcGVuZXIgPSB1cmxsaWIucmVxdWVzdC5idWlsZF9vcGVuZXIo
REM dXJsbGliLnJlcXVlc3QuSFRUUENvb2tpZVByb2Nlc3Nvcihjb29raWVqYXJfY29tcGF0LkNv
REM b2tpZUphcigpKSkKICAgICAgICBzZWxmLmxvY2sgPSB0aHJlYWRpbmcuTG9jaygpCiAgICAg
REM ICAgc2VsZi5uZXR3b3JrX2xvY2sgPSB0aHJlYWRpbmcuTG9jaygpCiAgICAgICAgc2VsZi5y
REM ZXFpZCA9IGludCh0aW1lLnRpbWUoKSAqIDEwMDApICUgOTAwMDAwMCArIDEwMDAgKyB3b3Jr
REM ZXJfaWQgKiAxMDAKICAgICAgICBzZWxmLnVsdGltYV9sYXRlbmNpYSA9IE5vbmUKICAgICAg
REM ICBzZWxmLnJlcXVlc3RzID0gMAogICAgICAgIHNlbGYucmF0ZV9saW1pdHMgPSAwCiAgICAg
REM ICAgc2VsZi5sYXRlbmNpYXMgPSBbXQoKICAgIGRlZiBfaGVhZGVycyhzZWxmLCBleHRyYT1O
REM b25lKToKICAgICAgICBoID0gewogICAgICAgICAgICB1IlVzZXItQWdlbnQiOiB1Ik1vemls
REM bGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4z
REM NiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS8xNTMuMC4wLjAgU2FmYXJpLzUzNy4zNiIs
REM CiAgICAgICAgICAgIHUiQWNjZXB0LUxhbmd1YWdlIjogdSJwdC1CUixwdDtxPTAuOSxlbjtx
REM PTAuOCIsCiAgICAgICAgICAgIHUiQ29ubmVjdGlvbiI6IHUia2VlcC1hbGl2ZSIsCiAgICAg
REM ICAgICAgIHUiQWNjZXB0IjogdSIqLyoiLAogICAgICAgIH0KICAgICAgICBpZiBleHRyYTog
REM aC51cGRhdGUoZXh0cmEpCiAgICAgICAgcmV0dXJuIGgKCiAgICBkZWYgY29uZWN0YXIoc2Vs
REM Zik6CiAgICAgICAgIyBBIGhvbWUgZG8gR29vZ2xlIFRyYW5zbGF0ZSBzZXJ2ZSBhcGVuYXMg
REM cGFyYSBjb25maXJtYXIgY29uZWN0aXZpZGFkZTsKICAgICAgICAjIG5lbmh1bWEgdHJhZHXD
REM p8OjbyDDqSBjb25zdW1pZGEgYXF1aS4KICAgICAgICB1cmwgPSB1Imh0dHBzOi8vdHJhbnNs
REM YXRlLmdvb2dsZS5jb20vIgogICAgICAgIHJlcSA9IHVybGxpYi5yZXF1ZXN0LlJlcXVlc3Qo
REM dXJsLCBoZWFkZXJzPXNlbGYuX2hlYWRlcnMoKSkKICAgICAgICB3aXRoIHNlbGYub3BlbmVy
REM Lm9wZW4ocmVxLCB0aW1lb3V0PUdPT0dMRV9USU1FT1VUKSBhcyByZXNwb3N0YToKICAgICAg
REM ICAgICAgcmVzcG9zdGEucmVhZCgxMDI0KQogICAgICAgIHNlbGYucmVhZHkgPSBUcnVlCiAg
REM ICAgICAgaWYgc2VsZi5sb2c6CiAgICAgICAgICAgIHNlbGYubG9nLmluZm8odSJTZXNzw6Nv
REM IHdvcmtlciB7MH0gcHJlcGFyYWRhOiBHb29nbGUgVHJhbnNsYXRlIFdlYiBSUEMiLmZvcm1h
REM dChzZWxmLndvcmtlcl9pZCArIDEpKQoKICAgIGRlZiB0cmFkdXppcihzZWxmLCB0ZXh0bywg
REM b3JpZ2VtLCBkZXN0aW5vKToKICAgICAgICB0ZXh0byA9IHRleHRvX2NvbXBhdGl2ZWwodGV4
REM dG8sIHUiIikKICAgICAgICBvcmlnZW0gPSB0ZXh0b19jb21wYXRpdmVsKG9yaWdlbSwgdSJh
REM dXRvIikgb3IgdSJhdXRvIgogICAgICAgIGRlc3Rpbm8gPSB0ZXh0b19jb21wYXRpdmVsKGRl
REM c3Rpbm8sIHUicHQtQlIiKSBvciB1InB0LUJSIgogICAgICAgIGlmIG5vdCBzZWxmLnJlYWR5
REM OgogICAgICAgICAgICBzZWxmLmNvbmVjdGFyKCkKICAgICAgICB3aXRoIHNlbGYubG9jazoK
REM ICAgICAgICAgICAgcmVxaWQgPSBzZWxmLnJlcWlkCiAgICAgICAgICAgIHNlbGYucmVxaWQg
REM Kz0gMQogICAgICAgIHF1ZXJ5ID0gewogICAgICAgICAgICB1ImNsaWVudCI6IHUiZ3R4IiwK
REM ICAgICAgICAgICAgdSJzbCI6IG9yaWdlbSwKICAgICAgICAgICAgdSJ0bCI6IGRlc3Rpbm8s
REM CiAgICAgICAgICAgIHUiZHQiOiB1InQiLAogICAgICAgICAgICB1InEiOiB0ZXh0bywKICAg
REM ICAgICAgICAgdSJ0ayI6IHUiIiwKICAgICAgICAgICAgdSJfcmVxaWQiOiBzdHIocmVxaWQp
REM LAogICAgICAgIH0KICAgICAgICB1cmwgPSBzZWxmLmhvc3RfYmFzZSArIHUiL3RyYW5zbGF0
REM ZV9hL3NpbmdsZT8iICsgdXJsbGliLnBhcnNlLnVybGVuY29kZShxdWVyeSwgZG9zZXE9VHJ1
REM ZSkKICAgICAgICByZXEgPSB1cmxsaWIucmVxdWVzdC5SZXF1ZXN0KHVybCwgaGVhZGVycz1z
REM ZWxmLl9oZWFkZXJzKHt1IlJlZmVyZXIiOiB1Imh0dHBzOi8vdHJhbnNsYXRlLmdvb2dsZS5j
REM b20vIn0pKQogICAgICAgIEdPT0dMRV9USFJPVFRMRS5hZ3VhcmRhcl92ZXooKQogICAgICAg
REM IGluaWNpb19yZXEgPSB0aW1lLnBlcmZfY291bnRlcigpCiAgICAgICAgc2VsZi5yZXF1ZXN0
REM cyArPSAxCiAgICAgICAgdHJ5OgogICAgICAgICAgICAjIFVtIGNsaWVudGUvc2Vzc8OjbyBu
REM dW5jYSBzb2JyZXDDtWUgZHVhcyByZXF1aXNpw6fDtWVzIHByw7Nwcmlhcy4KICAgICAgICAg
REM ICAgd2l0aCBzZWxmLm5ldHdvcmtfbG9jazoKICAgICAgICAgICAgICAgIHdpdGggc2VsZi5v
REM cGVuZXIub3BlbihyZXEsIHRpbWVvdXQ9R09PR0xFX1RJTUVPVVQpIGFzIHJlc3Bvc3RhOgog
REM ICAgICAgICAgICAgICAgICAgIHN0YXR1cyA9IGdldGF0dHIocmVzcG9zdGEsICJzdGF0dXMi
REM LCAyMDApCiAgICAgICAgICAgICAgICAgICAgYnJ1dG8gPSByZXNwb3N0YS5yZWFkKCkuZGVj
REM b2RlKHUidXRmLTgiLCB1InJlcGxhY2UiKQogICAgICAgIGV4Y2VwdCB1cmxsaWIuZXJyb3Iu
REM SFRUUEVycm9yIGFzIGV4YzoKICAgICAgICAgICAgaWYgZXhjLmNvZGUgPT0gNDI5OgogICAg
REM ICAgICAgICAgICAgc2VsZi5yYXRlX2xpbWl0cyArPSAxCiAgICAgICAgICAgICAgICBHT09H
REM TEVfVEhST1RUTEUucmVnaXN0cmFyX2Jsb3F1ZWlvKHNlbGYubG9nKQogICAgICAgICAgICAg
REM ICAgcmFpc2UgR29vZ2xlUmF0ZUxpbWl0RXJyb3IodSJIVFRQIDQyOSBUb28gTWFueSBSZXF1
REM ZXN0cyAoezB9KSIuZm9ybWF0KHNlbGYubm9tZV9ob3N0KSkKICAgICAgICAgICAgcmFpc2UK
REM ICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICBzZWxmLnVsdGltYV9sYXRlbmNpYSA9IHRp
REM bWUucGVyZl9jb3VudGVyKCkgLSBpbmljaW9fcmVxCiAgICAgICAgICAgIHNlbGYubGF0ZW5j
REM aWFzLmFwcGVuZChzZWxmLnVsdGltYV9sYXRlbmNpYSkKICAgICAgICBpZiBzdGF0dXMgPT0g
REM NDI5OgogICAgICAgICAgICBzZWxmLnJhdGVfbGltaXRzICs9IDEKICAgICAgICAgICAgR09P
REM R0xFX1RIUk9UVExFLnJlZ2lzdHJhcl9ibG9xdWVpbyhzZWxmLmxvZykKICAgICAgICAgICAg
REM cmFpc2UgR29vZ2xlUmF0ZUxpbWl0RXJyb3IodSJIVFRQIDQyOSBUb28gTWFueSBSZXF1ZXN0
REM cyAoezB9KSIuZm9ybWF0KHNlbGYubm9tZV9ob3N0KSkKICAgICAgICBpZiBzdGF0dXMgPj0g
REM NDAwOgogICAgICAgICAgICByYWlzZSBHb29nbGVUcmFuc2xhdGVFcnJvcih1IkhUVFAgezB9
REM ICh7MX0pIi5mb3JtYXQoc3RhdHVzLCBzZWxmLm5vbWVfaG9zdCkpCiAgICAgICAgdHJ5Ogog
REM ICAgICAgICAgICBkYWRvcyA9IGpzb24ubG9hZHMoYnJ1dG8pCiAgICAgICAgICAgIHBhcnRl
REM cyA9IFtdCiAgICAgICAgICAgIGJsb2NvcyA9IGRhZG9zWzBdIGlmIGlzaW5zdGFuY2UoZGFk
REM b3MsIGxpc3QpIGFuZCBkYWRvcyBlbHNlIFtdCiAgICAgICAgICAgIGlmIGlzaW5zdGFuY2Uo
REM YmxvY29zLCBsaXN0KToKICAgICAgICAgICAgICAgIGZvciBibG9jbyBpbiBibG9jb3M6CiAg
REM ICAgICAgICAgICAgICAgICAgaWYgaXNpbnN0YW5jZShibG9jbywgbGlzdCkgYW5kIGJsb2Nv
REM IGFuZCBpc2luc3RhbmNlKGJsb2NvWzBdLCBURVhUX1RZUEVTKToKICAgICAgICAgICAgICAg
REM ICAgICAgICAgcGFydGVzLmFwcGVuZChibG9jb1swXSkKICAgICAgICAgICAgcmVzdWx0YWRv
REM ID0gdSIiLmpvaW4ocGFydGVzKQogICAgICAgICAgICBpZiBub3QgcmVzdWx0YWRvOgogICAg
REM ICAgICAgICAgICAgcmFpc2UgVmFsdWVFcnJvcih1InJlc3Bvc3RhIEdUWCBzZW0gdGV4dG8g
REM dHJhZHV6aWRvIikKICAgICAgICAgICAgR09PR0xFX1RIUk9UVExFLnJlZ2lzdHJhcl9zdWNl
REM c3NvKCkKICAgICAgICAgICAgcmV0dXJuIHJlc3VsdGFkbwogICAgICAgIGV4Y2VwdCBFeGNl
REM cHRpb24gYXMgZXhjOgogICAgICAgICAgICByYWlzZSBHb29nbGVUcmFuc2xhdGVFcnJvcih1
REM InJlc3Bvc3RhIEdUWCBpbnbDoWxpZGE6IHswfSIuZm9ybWF0KGV4YykpCgoKY2xhc3MgR29v
REM Z2xlUlBDQ2xpZW50KG9iamVjdCk6CiAgICBkZWYgX19pbml0X18oc2VsZiwgbm9tZV9ob3N0
REM LCBob3N0X2Jhc2UsIGxvZz1Ob25lLCB3b3JrZXJfaWQ9MCk6CiAgICAgICAgc2VsZi5ub21l
REM X2hvc3QgPSBub21lX2hvc3QKICAgICAgICBzZWxmLmhvc3RfYmFzZSA9IGhvc3RfYmFzZQog
REM ICAgICAgIHNlbGYubG9nID0gbG9nCiAgICAgICAgc2VsZi53b3JrZXJfaWQgPSB3b3JrZXJf
REM aWQKICAgICAgICBzZWxmLmZzaWQgPSBOb25lCiAgICAgICAgc2VsZi5ibCA9IEdPT0dMRV9T
REM VEFUSUNfQkwKICAgICAgICBzZWxmLnJlYWR5ID0gRmFsc2UKICAgICAgICBzZWxmLm9wZW5l
REM ciA9IHVybGxpYi5yZXF1ZXN0LmJ1aWxkX29wZW5lcih1cmxsaWIucmVxdWVzdC5IVFRQQ29v
REM a2llUHJvY2Vzc29yKGNvb2tpZWphcl9jb21wYXQuQ29va2llSmFyKCkpKQogICAgICAgIHNl
REM bGYucmVxaWQgPSBpbnQodGltZS50aW1lKCkgKiAxMDAwKSAlIDkwMDAwMDAgKyAxMDAwICsg
REM d29ya2VyX2lkICogMTAwCiAgICAgICAgc2VsZi5sb2NrID0gdGhyZWFkaW5nLkxvY2soKQog
REM ICAgICAgIHNlbGYudWx0aW1hX2xhdGVuY2lhID0gTm9uZQogICAgICAgIHNlbGYudWx0aW1v
REM X3N0YXR1cyA9IE5vbmUKICAgICAgICBzZWxmLnVsdGltb3NfYnl0ZXMgPSAwCiAgICAgICAg
REM c2VsZi5yZXF1ZXN0cyA9IDAKICAgICAgICBzZWxmLnJhdGVfbGltaXRzID0gMAogICAgICAg
REM IHNlbGYubGF0ZW5jaWFzID0gW10KCiAgICBkZWYgX2hlYWRlcnMoc2VsZiwgZXh0cmE9Tm9u
REM ZSk6CiAgICAgICAgaCA9IHsKICAgICAgICAgICAgdSJVc2VyLUFnZW50IjogdSJNb3ppbGxh
REM LzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYg
REM KEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvMTUzLjAuMC4wIFNhZmFyaS81MzcuMzYiLAog
REM ICAgICAgICAgICB1IkFjY2VwdC1MYW5ndWFnZSI6IHUicHQtQlIscHQ7cT0wLjksZW47cT0w
REM LjgiLAogICAgICAgICAgICB1IkNvbm5lY3Rpb24iOiB1ImtlZXAtYWxpdmUiLAogICAgICAg
REM IH0KICAgICAgICBpZiBleHRyYTogaC51cGRhdGUoZXh0cmEpCiAgICAgICAgcmV0dXJuIGgK
REM CiAgICBkZWYgY29uZWN0YXIoc2VsZik6CiAgICAgICAgaW5pY2lvX3JlcSA9IHRpbWUucGVy
REM Zl9jb3VudGVyKCkKICAgICAgICB1cmwgPSBzZWxmLmhvc3RfYmFzZSArIHUiLyIKICAgICAg
REM ICByZXEgPSB1cmxsaWIucmVxdWVzdC5SZXF1ZXN0KHVybCwgaGVhZGVycz1zZWxmLl9oZWFk
REM ZXJzKCkpCiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRoIHNlbGYub3BlbmVyLm9wZW4o
REM cmVxLCB0aW1lb3V0PUdPT0dMRV9USU1FT1VUKSBhcyByZXNwb3N0YToKICAgICAgICAgICAg
REM ICAgIHN0YXR1cyA9IGdldGF0dHIocmVzcG9zdGEsICJzdGF0dXMiLCAyMDApCiAgICAgICAg
REM ICAgICAgICBicnV0byA9IHJlc3Bvc3RhLnJlYWQoKS5kZWNvZGUodSJ1dGYtOCIsIHUicmVw
REM bGFjZSIpCiAgICAgICAgICAgICAgICBzZWxmLnVsdGltb19zdGF0dXMgPSBzdGF0dXMKICAg
REM ICAgICAgICAgICAgIHNlbGYudWx0aW1vc19ieXRlcyA9IGxlbihicnV0by5lbmNvZGUodSJ1
REM dGYtOCIsIHUicmVwbGFjZSIpKQogICAgICAgIGZpbmFsbHk6CiAgICAgICAgICAgIHNlbGYu
REM dWx0aW1hX2xhdGVuY2lhID0gdGltZS5wZXJmX2NvdW50ZXIoKSAtIGluaWNpb19yZXEKICAg
REM ICAgICBpZiBzdGF0dXMgPj0gNDAwOgogICAgICAgICAgICByYWlzZSB1cmxsaWIuZXJyb3Iu
REM SFRUUEVycm9yKHVybCwgc3RhdHVzLCB1IkhUVFAgezB9Ii5mb3JtYXQoc3RhdHVzKSwgTm9u
REM ZSwgTm9uZSkKICAgICAgICBtX2ZzaWQgPSByZS5zZWFyY2gociciRmRyRkplIlxzKjpccyoi
REM KFteIl0rKSInLCBicnV0bykKICAgICAgICBtX2JsID0gcmUuc2VhcmNoKHInImNmYjJoIlxz
REM KjpccyoiKFteIl0rKSInLCBicnV0bykKICAgICAgICBpZiBtX2ZzaWQ6IHNlbGYuZnNpZCA9
REM IG1fZnNpZC5ncm91cCgxKQogICAgICAgIGlmIG1fYmw6IHNlbGYuYmwgPSBtX2JsLmdyb3Vw
REM KDEpCiAgICAgICAgc2VsZi5yZWFkeSA9IFRydWUKICAgICAgICBpZiBzZWxmLmxvZzoKICAg
REM ICAgICAgICAgc2VsZi5sb2cuaW5mbyh1IlNlc3PDo28gd29ya2VyIHswfSBwcmVwYXJhZGE6
REM IHsxfSIuZm9ybWF0KHNlbGYud29ya2VyX2lkICsgMSwgc2VsZi5ub21lX2hvc3QpKQoKICAg
REM IGRlZiB0cmFkdXppcihzZWxmLCB0ZXh0bywgb3JpZ2VtLCBkZXN0aW5vKToKICAgICAgICB0
REM ZXh0byA9IHRleHRvX2NvbXBhdGl2ZWwodGV4dG8sIHUiIikKICAgICAgICBvcmlnZW0gPSB0
REM ZXh0b19jb21wYXRpdmVsKG9yaWdlbSwgdSJhdXRvIikgb3IgdSJhdXRvIgogICAgICAgIGRl
REM c3Rpbm8gPSB0ZXh0b19jb21wYXRpdmVsKGRlc3Rpbm8sIHUicHQtQlIiKSBvciB1InB0LUJS
REM IgogICAgICAgIGlmIG5vdCBzZWxmLnJlYWR5OiBzZWxmLmNvbmVjdGFyKCkKICAgICAgICB3
REM aXRoIHNlbGYubG9jazoKICAgICAgICAgICAgcmVxaWQgPSBzZWxmLnJlcWlkCiAgICAgICAg
REM ICAgIHNlbGYucmVxaWQgKz0gMTAwMAogICAgICAgIGludGVybm8gPSBqc29uLmR1bXBzKFtb
REM dGV4dG8sIG9yaWdlbSBvciB1ImF1dG8iLCBkZXN0aW5vLCBUcnVlXSwgW05vbmVdXSwgZW5z
REM dXJlX2FzY2lpPUZhbHNlLCBzZXBhcmF0b3JzPSh1IiwiLCB1IjoiKSkKICAgICAgICBycGNf
REM cmVxdWVzdCA9IGpzb24uZHVtcHMoW1tbR09PR0xFX1JQQ19JRCwgaW50ZXJubywgTm9uZSwg
REM dSJnZW5lcmljIl1dXSwgZW5zdXJlX2FzY2lpPUZhbHNlLCBzZXBhcmF0b3JzPSh1IiwiLCB1
REM IjoiKSkKICAgICAgICBxdWVyeSA9IHsKICAgICAgICAgICAgdSJycGNpZHMiOiBHT09HTEVf
REM UlBDX0lELCB1InNvdXJjZS1wYXRoIjogdSIvIiwgdSJibCI6IHNlbGYuYmwsCiAgICAgICAg
REM ICAgIHUiaGwiOiBkZXN0aW5vIG9yIHUicHQtQlIiLCB1InNvYy1hcHAiOiB1IjEiLCB1InNv
REM Yy1wbGF0Zm9ybSI6IHUiMSIsIHUic29jLWRldmljZSI6IHUiMSIsCiAgICAgICAgICAgIHUi
REM X3JlcWlkIjogc3RyKHJlcWlkKSwgdSJydCI6IHUiYyIKICAgICAgICB9CiAgICAgICAgaWYg
REM c2VsZi5mc2lkOiBxdWVyeVt1ImYuc2lkIl0gPSBzZWxmLmZzaWQKICAgICAgICB1cmwgPSBz
REM ZWxmLmhvc3RfYmFzZSArIHUiL18vVHJhbnNsYXRlV2Vic2VydmVyVWkvZGF0YS9iYXRjaGV4
REM ZWN1dGU/IiArIHVybGxpYi5wYXJzZS51cmxlbmNvZGUocXVlcnkpCiAgICAgICAgZGFkb3Mg
REM PSB1cmxsaWIucGFyc2UudXJsZW5jb2RlKHt1ImYucmVxIjogcnBjX3JlcXVlc3R9KS5lbmNv
REM ZGUodSJ1dGYtOCIpCiAgICAgICAgaGVhZGVycyA9IHNlbGYuX2hlYWRlcnMoe3UiQWNjZXB0
REM IjogdSIqLyoiLCB1IkNvbnRlbnQtVHlwZSI6IHUiYXBwbGljYXRpb24veC13d3ctZm9ybS11
REM cmxlbmNvZGVkO2NoYXJzZXQ9VVRGLTgiLCB1Ik9yaWdpbiI6IHNlbGYuaG9zdF9iYXNlLCB1
REM IlJlZmVyZXIiOiBzZWxmLmhvc3RfYmFzZSArIHUiLyIsIHUiWC1TYW1lLURvbWFpbiI6IHUi
REM MSJ9KQogICAgICAgIHJlcSA9IHVybGxpYi5yZXF1ZXN0LlJlcXVlc3QodXJsLCBoZWFkZXJz
REM PWhlYWRlcnMsIGRhdGE9ZGFkb3MsIG1ldGhvZD11IlBPU1QiKQogICAgICAgICMgUmVzcGVp
REM dGEgbyByaXRtbyBnbG9iYWwgYW50ZXMgZGUgZGlzcGFyYXIgLS0gaXNzbyB2YWxlIG1lc21v
REM IHNlCiAgICAgICAgIyBPVVRSTyB3b3JrZXIgbGV2b3UgbyA0MjkgKG8gY29vbGRvd24gw6kg
REM Y29tcGFydGlsaGFkbyBwb3IgdG9kb3MpLgogICAgICAgIEdPT0dMRV9USFJPVFRMRS5hZ3Vh
REM cmRhcl92ZXooKQogICAgICAgIGluaWNpb19yZXEgPSB0aW1lLnBlcmZfY291bnRlcigpCiAg
REM ICAgICAgc2VsZi5yZXF1ZXN0cyArPSAxCiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRo
REM IHNlbGYub3BlbmVyLm9wZW4ocmVxLCB0aW1lb3V0PUdPT0dMRV9USU1FT1VUKSBhcyByZXNw
REM b3N0YToKICAgICAgICAgICAgICAgIHN0YXR1cyA9IGdldGF0dHIocmVzcG9zdGEsICJzdGF0
REM dXMiLCAyMDApCiAgICAgICAgICAgICAgICBicnV0byA9IHJlc3Bvc3RhLnJlYWQoKS5kZWNv
REM ZGUodSJ1dGYtOCIsIHUicmVwbGFjZSIpCiAgICAgICAgICAgICAgICBzZWxmLnVsdGltb19z
REM dGF0dXMgPSBzdGF0dXMKICAgICAgICAgICAgICAgIHNlbGYudWx0aW1vc19ieXRlcyA9IGxl
REM bihicnV0by5lbmNvZGUodSJ1dGYtOCIsIHUicmVwbGFjZSIpKQogICAgICAgIGV4Y2VwdCB1
REM cmxsaWIuZXJyb3IuSFRUUEVycm9yIGFzIGV4YzoKICAgICAgICAgICAgc2VsZi51bHRpbW9f
REM c3RhdHVzID0gZXhjLmNvZGUKICAgICAgICAgICAgc2VsZi51bHRpbW9zX2J5dGVzID0gMAog
REM ICAgICAgICAgICBpZiBleGMuY29kZSA9PSA0Mjk6CiAgICAgICAgICAgICAgICBzZWxmLnJh
REM dGVfbGltaXRzICs9IDEKICAgICAgICAgICAgICAgIEdPT0dMRV9USFJPVFRMRS5yZWdpc3Ry
REM YXJfYmxvcXVlaW8oc2VsZi5sb2cpCiAgICAgICAgICAgICAgICByYWlzZSBHb29nbGVSYXRl
REM TGltaXRFcnJvcih1IkhUVFAgNDI5IFRvbyBNYW55IFJlcXVlc3RzICh7MH0pIi5mb3JtYXQo
REM c2VsZi5ub21lX2hvc3QpKQogICAgICAgICAgICByYWlzZQogICAgICAgIGZpbmFsbHk6CiAg
REM ICAgICAgICAgIHNlbGYudWx0aW1hX2xhdGVuY2lhID0gdGltZS5wZXJmX2NvdW50ZXIoKSAt
REM IGluaWNpb19yZXEKICAgICAgICAgICAgc2VsZi5sYXRlbmNpYXMuYXBwZW5kKHNlbGYudWx0
REM aW1hX2xhdGVuY2lhKQogICAgICAgIGlmIHN0YXR1cyA9PSA0Mjk6CiAgICAgICAgICAgIHNl
REM bGYucmF0ZV9saW1pdHMgKz0gMQogICAgICAgICAgICBHT09HTEVfVEhST1RUTEUucmVnaXN0
REM cmFyX2Jsb3F1ZWlvKHNlbGYubG9nKQogICAgICAgICAgICByYWlzZSBHb29nbGVSYXRlTGlt
REM aXRFcnJvcih1IkhUVFAgNDI5IFRvbyBNYW55IFJlcXVlc3RzICh7MH0pIi5mb3JtYXQoc2Vs
REM Zi5ub21lX2hvc3QpKQogICAgICAgIGlmIHN0YXR1cyA+PSA0MDA6IHJhaXNlIEdvb2dsZVRy
REM YW5zbGF0ZUVycm9yKHUiSFRUUCB7MH0gKHsxfSkiLmZvcm1hdChzdGF0dXMsIHNlbGYubm9t
REM ZV9ob3N0KSkKICAgICAgICBHT09HTEVfVEhST1RUTEUucmVnaXN0cmFyX3N1Y2Vzc28oKQog
REM ICAgICAgIHJldHVybiBleHRyYWlyX3RyYWR1Y2FvX3JwY19nb29nbGUoZXh0cmFpcl9wYXls
REM b2FkX3JwY19nb29nbGUoYnJ1dG8pKQoKCmRlZiBjcmlhcl9wb29sX2dvb2dsZShsb2cpOgog
REM ICAgcG9vbCA9IFtdCiAgICBmb3Igd29ya2VyIGluIHJhbmdlKEdPT0dMRV9XT1JLRVJTKToK
REM ICAgICAgICBub21lLCBob3N0ID0gR09PR0xFX0hPU1RTW3dvcmtlciAlIGxlbihHT09HTEVf
REM SE9TVFMpXQogICAgICAgIHRyeToKICAgICAgICAgICAgYyA9IEdvb2dsZVJQQ0NsaWVudChu
REM b21lLCBob3N0LCBsb2csIHdvcmtlcikKICAgICAgICAgICAgYy5jb25lY3RhcigpCiAgICAg
REM ICAgICAgIHBvb2wuYXBwZW5kKGMpCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6
REM CiAgICAgICAgICAgIGlmIGxvZzoKICAgICAgICAgICAgICAgIGxvZy5lcnJvKHUiV29ya2Vy
REM IHswfTogZmFsaGEgYW8gcHJlcGFyYXIgezF9OiB7Mn0iLmZvcm1hdCh3b3JrZXIgKyAxLCBu
REM b21lLCBleGMpKQogICAgaWYgbm90IHBvb2w6CiAgICAgICAgcmFpc2UgR29vZ2xlVHJhbnNs
REM YXRlRXJyb3IodSJuZW5odW1hIHNlc3PDo28gR29vZ2xlIFRyYW5zbGF0ZSBXZWIgcMO0ZGUg
REM c2VyIHByZXBhcmFkYSIpCiAgICByZXR1cm4gcG9vbAoKCgojID09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09CiMgQkFOQ08gREUgQ09SUkXDh8OVRVMgQUNVTVVMQVRJVkFTIEUgSU5ESVZJRFVB
REM SVMKIyA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PQojIENhZGEgcmVncmEgY2FzYSBzb21lbnRl
REM IGNvbSBvIFRFWFRPIE9SSUdJTkFMLiBVbWEgcmVncmEgbm92YSBuw6NvIHJlY2ViZSBvCiMg
REM cmVzdWx0YWRvIGRlIG91dHJhIGNvcnJlw6fDo286IHJlZ3JhcyBhbnRpZ2FzIHBlcm1hbmVj
REM ZW0gaW5kZXBlbmRlbnRlcy4KIyBBY3Jlc2NlbnRlIG5vdmFzIGVudHJhZGFzIGFvIGZpbmFs
REM IGRhIGxpc3RhIHNlbSBlZGl0YXIgYXMgYW50ZXJpb3Jlcy4KIyBhcnF1aXZvPSIqIiB0b3Ju
REM YSBhIHJlZ3JhIGdsb2JhbDsgY2FzbyBjb250csOhcmlvIHVzZSBvIGNhbWluaG8gcmVsYXRp
REM dm8gLnJweS4KIyB0aXBvPSIqIiBhY2VpdGEgcXVhbHF1ZXIgdGlwbyBkZSBlbnRyYWRhLgpD
REM T1JSRUNPRVNfSU5ESVZJRFVBSVNfR09PR0xFID0gWwogICAgewogICAgICAgIHUiaWQiOiB1
REM IlIwMDFfTU9OSUtBXzEwNiIsCiAgICAgICAgdSJhcnF1aXZvIjogdSJtb25pa2Ffcm91dGUv
REM c3RvcnkucnB5IiwKICAgICAgICB1InRpcG8iOiB1ImRpYWxvZ28iLAogICAgICAgIHUib3Jp
REM Z2VtIjogdSJZb3UnbGwgYmUgYW4gZW1iYXJyYXNtZW50IHRvIGhlci4uLntwPTEuMH0gWW91
REM J2xsIGJyZWFrIGhlciBpbWFnZS4uLiIsCiAgICAgICAgdSJ0cmFkdWNhbyI6IHUiVm9jw6og
REM c2Vyw6EgdW1hIHZlcmdvbmhhIHBhcmEgZWxhLi4ue3A9MS4wfSBWb2PDqiB2YWkgZGVzdHJ1
REM aXIgYSBpbWFnZW0gcXVlIGVsYSB0ZW0uLi4iLAogICAgfSwKICAgIHsKICAgICAgICB1Imlk
REM IjogdSJSMDAyX01PTklLQV8zNjQiLAogICAgICAgIHUiYXJxdWl2byI6IHUibW9uaWthX3Jv
REM dXRlL3N0b3J5LnJweSIsCiAgICAgICAgdSJ0aXBvIjogdSJkaWFsb2dvIiwKICAgICAgICB1
REM Im9yaWdlbSI6IHUiSXQgd291bGRuJ3QgYmUge2l9dGhpc3svaX0gYmlnIG9mIGEgcHJvYmxl
REM bS4uLiIsCiAgICAgICAgdSJ0cmFkdWNhbyI6IHUiTsOjbyBzZXJpYSB7aX11bSBwcm9ibGVt
REM YSB0w6NvIGdyYW5kZXsvaX0gYXNzaW0uLi4iLAogICAgfSwKICAgIHsKICAgICAgICB1Imlk
REM IjogdSJSMDAzX01PTklLQV80ODciLAogICAgICAgIHUiYXJxdWl2byI6IHUibW9uaWthX3Jv
REM dXRlL3N0b3J5LnJweSIsCiAgICAgICAgdSJ0aXBvIjogdSJkaWFsb2dvIiwKICAgICAgICB1
REM Im9yaWdlbSI6IHUiTW1taGhoLCBub3QgcmVhbGx5LiBFdmVyeW9uZSB3YXMganVzdC17cD0w
REM LjV9IHdlaXJkLiIsCiAgICAgICAgdSJ0cmFkdWNhbyI6IHUiSG1tbSwgbsOjbyBtdWl0by4g
REM VG9kbyBtdW5kbyBlc3RhdmEgc8OzLXtwPTAuNX0gZXN0cmFuaG8uIiwKICAgIH0sCiAgICB7
REM CiAgICAgICAgdSJpZCI6IHUiUjAwNF9NT05JS0FfNDkxIiwKICAgICAgICB1ImFycXVpdm8i
REM OiB1Im1vbmlrYV9yb3V0ZS9zdG9yeS5ycHkiLAogICAgICAgIHUidGlwbyI6IHUiZGlhbG9n
REM byIsCiAgICAgICAgdSJvcmlnZW0iOiB1IkV2ZXJ5b25lIHdhcyBqdXN0IHPDsy17cD0wLjV9
REM IG5pY2UgdG9kYXkuLi4iLAogICAgICAgIHUidHJhZHVjYW8iOiB1IlRvZG8gbXVuZG8gZXN0
REM YXZhIHTDo28te3A9MC41fSBsZWdhbCBob2plLi4uIiwKICAgIH0sCiAgICB7CiAgICAgICAg
REM dSJpZCI6IHUiUjAwNV9NT05JS0FfMDYzX1NQQUNJTkciLAogICAgICAgIHUiYXJxdWl2byI6
REM IHUibW9uaWthX3JvdXRlL3N0b3J5LnJweSIsCiAgICAgICAgdSJ0aXBvIjogdSJkaWFsb2dv
REM IiwKICAgICAgICB1Im9yaWdlbSI6IHUiVW0uLi5zdXJlLiBZZWFoLiIsCiAgICAgICAgdSJ0
REM cmFkdWNhbyI6IHUiSHVtLi4uIGNsYXJvLiBTaW0uIiwKICAgIH0sCiAgICB7CiAgICAgICAg
REM dSJpZCI6IHUiUjAwNl9TQ1JFRU5TX1FVSVQiLAogICAgICAgIHUiYXJxdWl2byI6IHUic2Ny
REM ZWVucy5ycHkiLAogICAgICAgIHUidGlwbyI6IHUiKiIsCiAgICAgICAgdSJvcmlnZW0iOiB1
REM IlF1aXQiLAogICAgICAgIHUidHJhZHVjYW8iOiB1IlNhaXIiLAogICAgfSwKICAgIHsKICAg
REM ICAgICB1ImlkIjogdSJSMDA3X1NUT1JZX1JPVVRFX1NBWU9SSSIsCiAgICAgICAgdSJhcnF1
REM aXZvIjogdSJzdG9yeS5ycHkiLAogICAgICAgIHUidGlwbyI6IHUiKiIsCiAgICAgICAgdSJv
REM cmlnZW0iOiB1InNheW9yaV9yb3V0ZSIsCiAgICAgICAgdSJ0cmFkdWNhbyI6IHUiUm90YSBk
REM YSBTYXlvcmkiLAogICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJSMDA4X1NUT1JZX1JP
REM VVRFX1lVUkkiLAogICAgICAgIHUiYXJxdWl2byI6IHUic3RvcnkucnB5IiwKICAgICAgICB1
REM InRpcG8iOiB1IioiLAogICAgICAgIHUib3JpZ2VtIjogdSJ5dXJpX3JvdXRlIiwKICAgICAg
REM ICB1InRyYWR1Y2FvIjogdSJSb3RhIGRhIFl1cmkiLAogICAgfSwKICAgIHsKICAgICAgICB1
REM ImlkIjogdSJSMDA5X1NUT1JZX1JPVVRFX05BVFNVS0kiLAogICAgICAgIHUiYXJxdWl2byI6
REM IHUic3RvcnkucnB5IiwKICAgICAgICB1InRpcG8iOiB1IioiLAogICAgICAgIHUib3JpZ2Vt
REM IjogdSJuYXRzdWtpX3JvdXRlIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJSb3RhIGRhIE5h
REM dHN1a2kiLAogICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJSMDEwX1NUT1JZX1JPVVRF
REM X01PTklLQSIsCiAgICAgICAgdSJhcnF1aXZvIjogdSJzdG9yeS5ycHkiLAogICAgICAgIHUi
REM dGlwbyI6IHUiKiIsCiAgICAgICAgdSJvcmlnZW0iOiB1Im1vbmlrYSByb3V0ZSIsCiAgICAg
REM ICAgdSJ0cmFkdWNhbyI6IHUiUm90YSBkYSBNb25pa2EiLAogICAgfSwKICAgIHsKICAgICAg
REM ICB1ImlkIjogdSJSMDExX1NDUklQVF9OQU1FX1NBWU9SSSIsCiAgICAgICAgdSJhcnF1aXZv
REM IjogdSJzY3JpcHQucnB5IiwKICAgICAgICB1InRpcG8iOiB1Im5vbWVfcGVyc29uYWdlbSIs
REM CiAgICAgICAgdSJvcmlnZW0iOiB1IlNheW9yaSIsCiAgICAgICAgdSJ0cmFkdWNhbyI6IHUi
REM U2F5b3JpIiwKICAgIH0sCiAgICB7CiAgICAgICAgdSJpZCI6IHUiUjAxMl9TQ1JJUFRfTkFN
REM RV9NT05JS0EiLAogICAgICAgIHUiYXJxdWl2byI6IHUic2NyaXB0LnJweSIsCiAgICAgICAg
REM dSJ0aXBvIjogdSJub21lX3BlcnNvbmFnZW0iLAogICAgICAgIHUib3JpZ2VtIjogdSJNb25p
REM a2EiLAogICAgICAgIHUidHJhZHVjYW8iOiB1Ik1vbmlrYSIsCiAgICB9LAogICAgewogICAg
REM ICAgIHUiaWQiOiB1IlIwMTNfU0NSSVBUX05BTUVfTkFUU1VLSSIsCiAgICAgICAgdSJhcnF1
REM aXZvIjogdSJzY3JpcHQucnB5IiwKICAgICAgICB1InRpcG8iOiB1Im5vbWVfcGVyc29uYWdl
REM bSIsCiAgICAgICAgdSJvcmlnZW0iOiB1Ik5hdHN1a2kiLAogICAgICAgIHUidHJhZHVjYW8i
REM OiB1Ik5hdHN1a2kiLAogICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJSMDE0X1NDUklQ
REM VF9OQU1FX1lVUkkiLAogICAgICAgIHUiYXJxdWl2byI6IHUic2NyaXB0LnJweSIsCiAgICAg
REM ICAgdSJ0aXBvIjogdSJub21lX3BlcnNvbmFnZW0iLAogICAgICAgIHUib3JpZ2VtIjogdSJZ
REM dXJpIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJZdXJpIiwKICAgIH0sCiAgICB7CiAgICAg
REM ICAgdSJpZCI6IHUiUjAxNV9ERUZJTklUSU9OU19OQU1FX01PTklLQSIsCiAgICAgICAgdSJh
REM cnF1aXZvIjogdSJkZWZpbml0aW9ucy9kZWZpbml0aW9ucy5ycHkiLAogICAgICAgIHUidGlw
REM byI6IHUibm9tZV9wZXJzb25hZ2VtIiwKICAgICAgICB1Im9yaWdlbSI6IHUiTW9uaWthIiwK
REM ICAgICAgICB1InRyYWR1Y2FvIjogdSJNb25pa2EiLAogICAgfSwKICAgIHsKICAgICAgICB1
REM ImlkIjogdSJSMDE2X0RFRklOSVRJT05TX05BTUVfWVVSSSIsCiAgICAgICAgdSJhcnF1aXZv
REM IjogdSJkZWZpbml0aW9ucy9kZWZpbml0aW9ucy5ycHkiLAogICAgICAgIHUidGlwbyI6IHUi
REM bm9tZV9wZXJzb25hZ2VtIiwKICAgICAgICB1Im9yaWdlbSI6IHUiWXVyaSIsCiAgICAgICAg
REM dSJ0cmFkdWNhbyI6IHUiWXVyaSIsCiAgICB9LAogICAgewogICAgICAgIHUiaWQiOiB1IlIw
REM MTdfREVGSU5JVElPTlNfQ0g0X1lVUkkiLAogICAgICAgIHUiYXJxdWl2byI6IHUiZGVmaW5p
REM dGlvbnMvZGVmaW5pdGlvbnMucnB5IiwKICAgICAgICB1InRpcG8iOiB1InZhcmlhdmVsX3Rl
REM eHRvIiwKICAgICAgICB1Im9yaWdlbSI6IHUiWXVyaSIsCiAgICAgICAgdSJ0cmFkdWNhbyI6
REM IHUiWXVyaSIsCiAgICB9LAogICAgewogICAgICAgIHUiaWQiOiB1IlIwMjBfUE9FTV9GTElD
REM S0VSX0JBQ0siLAogICAgICAgIHUiYXJxdWl2byI6IHUicG9lbV9yZXNwb25zZXMvcG9lbXMu
REM cnB5IiwKICAgICAgICB1InRpcG8iOiB1InBvZW1hX2NvcnBvIiwKICAgICAgICB1Im9yaWdl
REM bSI6IHUiSSBmbGlja2VyIGJhY2suIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJFdSBwaXNj
REM byBkZSB2b2x0YS4iLAogICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJSMDIxX1BPRU1f
REM TU9PTl9QSEFTRSIsCiAgICAgICAgdSJhcnF1aXZvIjogdSJwb2VtX3Jlc3BvbnNlcy9wb2Vt
REM cy5ycHkiLAogICAgICAgIHUidGlwbyI6IHUicG9lbWFfY29ycG8iLAogICAgICAgIHUib3Jp
REM Z2VtIjogdSJUaGUgbW9vbiBpbmNyZW1lbnRzIGl0cyBwaGFzZSBhbmQgcmVmbGVjdHMgdGhh
REM dCBtdWNoIG1vcmUgbGlnaHQgb2ZmIG9mIG15IGN1dHRpbmcga25pZmUuIiwKICAgICAgICB1
REM InRyYWR1Y2FvIjogdSJBIGx1YSBtdWRhIGRlIGZhc2UgZSByZWZsZXRlIG11aXRvIG1haXMg
REM bHV6IHNvYnJlIG1pbmhhIGZhY2EgZGUgY29ydGUuIiwKICAgIH0sCiAgICB7CiAgICAgICAg
REM dSJpZCI6IHUiUjAyMl9QT0VNX0JSQU5ESVNIX0tOSUZFIiwKICAgICAgICB1ImFycXVpdm8i
REM OiB1InBvZW1fcmVzcG9uc2VzL3BvZW1zLnJweSIsCiAgICAgICAgdSJ0aXBvIjogdSJwb2Vt
REM YV9jb3JwbyIsCiAgICAgICAgdSJvcmlnZW0iOiB1IkVhY2ggdGltZSBJIGJyYW5kaXNoIG15
REM IGN1dHRpbmcga25pZmUsIHRoZSByYWNjb29uIHNob3dzIG1lIGl0cyBleGNpdGVtZW50LiIs
REM CiAgICAgICAgdSJ0cmFkdWNhbyI6IHUiQ2FkYSB2ZXogcXVlIGVtcHVuaG8gbWluaGEgZmFj
REM YSBkZSBjb3J0ZSwgbyBndWF4aW5pbSBkZW1vbnN0cmEgc3VhIGVtcG9sZ2HDp8Ojby4iLAog
REM ICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJSMDIzX1BPRU1fQk9VTkRBUllfTElORSIs
REM CiAgICAgICAgdSJhcnF1aXZvIjogdSJwb2VtX3Jlc3BvbnNlcy9wb2Vtcy5ycHkiLAogICAg
REM ICAgIHUidGlwbyI6IHUicG9lbWFfY29ycG8iLAogICAgICAgIHUib3JpZ2VtIjogdSJJIHNp
REM bmsgbXkgdG9lcyBpbnRvIHRoZSB1bHRpbWF0ZSBib3VuZGFyeSBsaW5lLCB0ZW1wdGVkIGJ5
REM IHRoZSBmb2FteSB0ZW5kcmlscy4iLAogICAgICAgIHUidHJhZHVjYW8iOiB1IkFmdW5kbyBv
REM cyBkZWRvcyBkb3MgcMOpcyBubyBsaW1pdGUgZmluYWwsIHRlbnRhZG8gcGVsYXMgZ2F2aW5o
REM YXMgZXNwdW1vc2FzLiIsCiAgICB9LAogICAgewogICAgICAgIHUiaWQiOiB1IlIwMjRfUE9F
REM TV9UVVJOX0JBQ0siLAogICAgICAgIHUiYXJxdWl2byI6IHUicG9lbV9yZXNwb25zZXMvcG9l
REM bXMucnB5IiwKICAgICAgICB1InRpcG8iOiB1InBvZW1hX2NvcnBvIiwKICAgICAgICB1Im9y
REM aWdlbSI6IHUiVHVybiBiYWNrLCBhbmQgSSBhYmFuZG9uIG15IHBlYWNlIHRvIGVyb2RlIGF0
REM IHRoZSBzaG9yZS4iLAogICAgICAgIHUidHJhZHVjYW8iOiB1IkV1IHZvbHRvIGUgYWJhbmRv
REM bm8gbWluaGEgcGF6IHBhcmEgcXVlIGVsYSBzZSBkZXNnYXN0ZSBuYSBtYXJnZW0uIiwKICAg
REM IH0sCiAgICB7CiAgICAgICAgdSJpZCI6IHUiUjAyNV9QT0VNX1NUUkVFVExJR0hUIiwKICAg
REM ICAgICB1ImFycXVpdm8iOiB1InBvZW1fcmVzcG9uc2VzL3BvZW1zLnJweSIsCiAgICAgICAg
REM dSJ0aXBvIjogdSJwb2VtYV9jb3JwbyIsCiAgICAgICAgdSJvcmlnZW0iOiB1IkhlIHN0ZXBz
REM IGludG8gdGhlIHN0cmVldGxpZ2h0LiBJIGdhc3AgYW5kIGRyb3AgbXkgdW1icmVsbGEuIiwK
REM ICAgICAgICB1InRyYWR1Y2FvIjogdSJFbGUgZW50cmEgc29iIGEgbHV6IGRvIHBvc3RlLiBF
REM dSBzdXNwaXJvIGUgZGVpeG8gbWV1IGd1YXJkYS1jaHV2YSBjYWlyLiIsCiAgICB9LAogICAg
REM ewogICAgICAgIHUiaWQiOiB1IlIwMjZfUE9FTV9GT1JUWV9HRUFSUyIsCiAgICAgICAgdSJh
REM cnF1aXZvIjogdSJwb2VtX3Jlc3BvbnNlcy9wb2Vtcy5ycHkiLAogICAgICAgIHUidGlwbyI6
REM IHUicG9lbWFfY29ycG8iLAogICAgICAgIHUib3JpZ2VtIjogdSJGb3J0eSBnZWFycyBhbmQg
REM YSB0aWNraW5nIGNsb2NrLiBBIGNsb2NrIHRoYXQgdGlja3Mgb25lIHNlY29uZCBmb3IgZXZl
REM cnkgcm90YXRpb24gb2YgdGhlIHBsYW5ldC4gIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJR
REM dWFyZW50YSBlbmdyZW5hZ2VucyBlIHVtIHJlbMOzZ2lvIHF1ZSB0aXF1ZXRhcXVlaWEuIFVt
REM IHJlbMOzZ2lvIHF1ZSBtYXJjYSB1bSBzZWd1bmRvIGEgY2FkYSByb3Rhw6fDo28gZG8gcGxh
REM bmV0YS4iLAogICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJSMDI3X1BPRU1fV0lORFlf
REM U0FJTCIsCiAgICAgICAgdSJhcnF1aXZvIjogdSJwb2VtX3Jlc3BvbnNlcy9wb2Vtcy5ycHki
REM LAogICAgICAgIHUidGlwbyI6IHUicG9lbWFfY29ycG8iLAogICAgICAgIHUib3JpZ2VtIjog
REM dSJTZXQgeW91IGZyZWUgaW4gbXkgd2luZHkgc2FpbCIsCiAgICAgICAgdSJ0cmFkdWNhbyI6
REM IHUiTGliZXJ0byB2b2PDqiBuYSBtaW5oYSB2ZWxhIGFvIHZlbnRvLiIsCiAgICB9LAogICAg
REM ewogICAgICAgIHUiaWQiOiB1IlIwMjhfUE9FTV9TVEFORElORyIsCiAgICAgICAgdSJhcnF1
REM aXZvIjogdSJwb2VtX3Jlc3BvbnNlcy9wb2Vtcy5ycHkiLAogICAgICAgIHUidGlwbyI6IHUi
REM cG9lbWFfY29ycG8iLAogICAgICAgIHUib3JpZ2VtIjogdSJNeSBzdGFuZGluZyBpcyBhIGxp
REM dHRsZSBiaXQgdGFsbGVyIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJNaW5oYSBlc3RhdHVy
REM YSDDqSB1bSBwb3VjbyBtYWlvci4iLAogICAgfSwKICAgIHsKICAgICAgICB1ImlkIjogdSJS
REM MDI5X1BPRU1fU0NBTFAiLAogICAgICAgIHUiYXJxdWl2byI6IHUicG9lbV9yZXNwb25zZXMv
REM cG9lbXMucnB5IiwKICAgICAgICB1InRpcG8iOiB1InBvZW1hX2NvcnBvIiwKICAgICAgICB1
REM Im9yaWdlbSI6IHUiSSBwb3Agb2ZmIG15IHNjYWxwIGxpa2UgdGhlIGxpZCBvZiBhIGNvb2tp
REM ZSBqYXIuIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJFdSBhcnJhbmNvIG1ldSBjb3VybyBj
REM YWJlbHVkbyBjb21vIGEgdGFtcGEgZGUgdW0gcG90ZSBkZSBiaXNjb2l0b3MuIiwKICAgIH0s
REM CiAgICB7CiAgICAgICAgdSJpZCI6IHUiUjAzMF9QT0VNX1JFVElOQVMiLAogICAgICAgIHUi
REM YXJxdWl2byI6IHUicG9lbV9yZXNwb25zZXMvcG9lbXMucnB5IiwKICAgICAgICB1InRpcG8i
REM OiB1InBvZW1hX2NvcnBvIiwKICAgICAgICB1Im9yaWdlbSI6IHUiQWxyZWFkeSBzY29yY2hl
REM ZCB3aXRoIGEgcGVybWFuZW50IGNvcHkgb2YgdGhlIG1lYW5pbmdsZXNzIGltYWdlLiIsCiAg
REM ICAgICAgdSJ0cmFkdWNhbyI6IHUiSsOhIGNoYW11c2NhZGFzIGNvbSB1bWEgY8OzcGlhIHBl
REM cm1hbmVudGUgZGEgaW1hZ2VtIHNlbSBzZW50aWRvLiIsCiAgICB9LAogICAgewogICAgICAg
REM IHUiaWQiOiB1IlIwMzFfUE9FTV9QRU4iLAogICAgICAgIHUiYXJxdWl2byI6IHUicG9lbV9y
REM ZXNwb25zZXMvcG9lbXMucnB5IiwKICAgICAgICB1InRpcG8iOiB1InBvZW1hX2NvcnBvIiwK
REM ICAgICAgICB1Im9yaWdlbSI6IHUiU3dhbGxvd2luZyBteSBmZWFycywgSSBicmFuZGlzaCBt
REM eSBwZW4uIiwKICAgICAgICB1InRyYWR1Y2FvIjogdSJFbmdvbGluZG8gbWV1cyBtZWRvcywg
REM ZW1wdW5obyBtaW5oYSBjYW5ldGEuIiwKICAgIH0sCiAgICB7CiAgICAgICAgdSJpZCI6IHUi
REM UjAzMl9QT0VNX0FMTF9QVVJQT1NFIiwKICAgICAgICB1ImFycXVpdm8iOiB1InBvZW1fcmVz
REM cG9uc2VzL3BvZW1zLnJweSIsCiAgICAgICAgdSJ0aXBvIjogdSJwb2VtYV9jb3JwbyIsCiAg
REM ICAgICAgdSJvcmlnZW0iOiB1IkFsbCBwdXJwb3NlLCIsCiAgICAgICAgdSJ0cmFkdWNhbyI6
REM IHUiVG9kbyBwcm9ww7NzaXRvLCIsCiAgICB9LApdCgoKZGVmIGFwbGljYXJfY29ycmVjYW9f
REM aW5kaXZpZHVhbF9nb29nbGUodGV4dG8sIHJlbCwgdGlwb19lbnRyYWRhLCBkZXN0aW5vLCBs
REM b2c9Tm9uZSk6CiAgICB0ZXh0byA9IHRleHRvX2NvbXBhdGl2ZWwodGV4dG8sIHUiIikKICAg
REM IHJlbCA9IHRleHRvX2NvbXBhdGl2ZWwocmVsLCB1IiIpCiAgICB0aXBvX2VudHJhZGEgPSB0
REM ZXh0b19jb21wYXRpdmVsKHRpcG9fZW50cmFkYSwgdSIiKQogICAgZGVzdGlubyA9IHRleHRv
REM X2NvbXBhdGl2ZWwoZGVzdGlubywgdSJwdC1CUiIpCiAgICBpZiBub3QgZGVzdGlubyBvciBu
REM b3QgZGVzdGluby5sb3dlcigpLnN0YXJ0c3dpdGgodSJwdCIpOgogICAgICAgIHJldHVybiBO
REM b25lLCBOb25lCiAgICByZWxfbm9ybSA9IChyZWwgb3IgdSIiKS5yZXBsYWNlKHUiXFwiLCB1
REM Ii8iKS5sb3dlcigpCiAgICB0aXBvX25vcm0gPSAodGlwb19lbnRyYWRhIG9yIHUiIikubG93
REM ZXIoKQogICAgZm9yIHJlZ3JhIGluIENPUlJFQ09FU19JTkRJVklEVUFJU19HT09HTEU6CiAg
REM ICAgICAgaWYgcmVncmEuZ2V0KHUib3JpZ2VtIikgIT0gKHRleHRvIG9yIHUiIik6CiAgICAg
REM ICAgICAgIGNvbnRpbnVlCiAgICAgICAgYXJxdWl2b19yZWdyYSA9IChyZWdyYS5nZXQodSJh
REM cnF1aXZvIikgb3IgdSIqIikucmVwbGFjZSh1IlxcIiwgdSIvIikubG93ZXIoKQogICAgICAg
REM IGlmIGFycXVpdm9fcmVncmEgIT0gdSIqIiBhbmQgYXJxdWl2b19yZWdyYSAhPSByZWxfbm9y
REM bToKICAgICAgICAgICAgY29udGludWUKICAgICAgICB0aXBvX3JlZ3JhID0gKHJlZ3JhLmdl
REM dCh1InRpcG8iKSBvciB1IioiKS5sb3dlcigpCiAgICAgICAgaWYgdGlwb19yZWdyYSAhPSB1
REM IioiIGFuZCB0aXBvX3JlZ3JhICE9IHRpcG9fbm9ybToKICAgICAgICAgICAgY29udGludWUK
REM ICAgICAgICB0cmFkdWNhbyA9IHJlZ3JhLmdldCh1InRyYWR1Y2FvIikKICAgICAgICBpZiBp
REM c2luc3RhbmNlKHRyYWR1Y2FvLCBzdHIpOgogICAgICAgICAgICBpZiBsb2c6CiAgICAgICAg
REM ICAgICAgICBsb2cuYXZpc28odSJDb3JyZcOnw6NvIGluZGl2aWR1YWwgezB9IGFwbGljYWRh
REM IGVtIHsxfTsgYSByZWdyYSBjYXNhIGFwZW5hcyBjb20gbyB0ZXh0byBvcmlnaW5hbC4iLmZv
REM cm1hdCgKICAgICAgICAgICAgICAgICAgICByZWdyYS5nZXQodSJpZCIsIHUiU0VNX0lEIiks
REM IHJlbCkpCiAgICAgICAgICAgIHJldHVybiB0cmFkdWNhbywgcmVncmEuZ2V0KHUiaWQiLCB1
REM IlNFTV9JRCIpCiAgICByZXR1cm4gTm9uZSwgTm9uZQoKCkVOR0xJU0hfUkVUUllfRElTVElO
REM Q1RJVkUgPSB7CiAgICB1InByb2JsZW0iLCB1ImdhbWUiLCB1Im92ZXIiLCB1Imh1aCIsIHUi
REM Y29tZSIsIHUiY29taW5nIiwgdSJrZWVwIiwgdSJtb20iLCB1Im1vdGhlciIsCiAgICB1ImZh
REM dGhlciIsIHUibG9hZGluZyIsIHUic2V0dGluZ3MiLCB1InF1aXQiLCB1ImZpbmlzaCIsIHUi
REM c3RhcnQiLAogICAgdSJzb3JyeSIsIHUicGxlYXNlIiwgdSJ0aGFua3MiLCB1InRoYW5rIiwg
REM dSJ3aHkiLCB1IndoYXQiLCB1IndoZXJlIiwKICAgIHUid2hlbiIsIHUid2hvIiwgdSJob3ci
REM LCB1ImhlbHAiLCB1ImxvdmUiLCB1ImhhdGUiLCB1ImdpcmwiLCB1ImJveSIsCiAgICB1ImNv
REM bmZlc3Npb24iLCB1ImNydXNoIiwgdSJyb3V0aW5lIiwgdSJzdG9yeSIsIHUic2Nob29sIiwg
REM dSJzdHVkZW50IiwKICAgIHUiZnJpZW5kIiwgdSJmcmllbmRzIiwgdSJmcmllbmRzaGlwIiwg
REM dSJjb252ZXJzYXRpb24iLCB1InNpdHVhdGlvbiIsCiAgICB1Im1vbWVudCIsIHUibW9tZW50
REM cyIsIHUiaG91c2UiLCB1ImhvbWUiLCB1InN0b3JlIiwgdSJ0b2RheSIsCiAgICB1InRvbW9y
REM cm93IiwgdSJ5ZXN0ZXJkYXkiLCB1Im5pZ2h0IiwgdSJtb3JuaW5nIiwgdSJsdW5jaCIsIHUi
REM Y2x1YiIsCiAgICB1InJvb20iLCB1IndvcmxkIiwgdSJoZWFkIiwgdSJoZWFydCIsIHUiZmFj
REM ZSIsIHUiaGFuZHMiLCB1ImNoYWlyIiwKICAgIHUiZG9vciIsIHUid2luZG93IiwgdSJ0YWJs
REM ZSIsIHUia2l0Y2hlbiIsIHUicGFydHkiLCB1ImZvb2QiLCB1ImJvb2siLAogICAgdSJib29r
REM cyIsIHUid2F0ZXIiLCB1ImRyaW5rIiwgdSJsb29rIiwgdSJsb29rZWQiLCB1Imxvb2tpbmci
REM LCB1ImZlbHQiLAogICAgdSJmZWVsIiwgdSJmZWVsaW5nIiwgdSJ3YWxrIiwgdSJ3YWxrZWQi
REM LCB1IndhbGtpbmciLCB1InRhbGsiLCB1InRhbGtlZCIsCiAgICB1InNheSIsIHUic2FpZCIs
REM IHUic2F5aW5nIiwgdSJ0ZWxsIiwgdSJ0b2xkIiwgdSJrbm93IiwgdSJrbmV3IiwKICAgIHUi
REM dGhpbmsiLCB1InRob3VnaHQiLCB1IndhbnQiLCB1IndhbnRlZCIsIHUibmVlZCIsIHUibmVl
REM ZGVkIiwgdSJtYWtlIiwKICAgIHUibWFkZSIsIHUiZG9pbmciLCB1ImRvbmUiLCB1Imdvb2Qi
REM LCB1ImJhZCIsIHUibGl0dGxlIiwgdSJiaWciLCB1InNtYWxsIiwKICAgIHUiYmFjayIsIHUi
REM YXdheSIsIHUiYXJvdW5kIiwgdSJhZ2FpbiIsIHUiYWx3YXlzIiwgdSJuZXZlciIsIHUicmVh
REM bGx5IiwKICAgIHUidmVyeSIsIHUianVzdCIsIHUib25seSIsIHUibWF5YmUiLCB1InN1cmUi
REM LCB1InJpZ2h0IiwgdSJ3cm9uZyIsIHUid2VsbCIsCiAgICB1ImZpbmFsbHkiLCB1InN1ZGRl
REM bmx5IiwgdSJxdWlja2x5IiwgdSJzbG93bHkiLCB1ImJlY2F1c2UiLCB1ImJlZm9yZSIsCiAg
REM ICB1ImFmdGVyIiwgdSJ3aGlsZSIsIHUic29tZW9uZSIsIHUic29tZXRoaW5nIiwgdSJldmVy
REM eXRoaW5nIiwgdSJhbnlvbmUiLAp9CkVOR0xJU0hfUkVUUllfQ09NTU9OID0gewogICAgdSJp
REM IiwgdSJ5b3UiLCB1ImhlIiwgdSJzaGUiLCB1Iml0IiwgdSJ3ZSIsIHUidGhleSIsIHUibXki
REM LCB1InlvdXIiLAogICAgdSJ0aGUiLCB1ImEiLCB1ImFuIiwgdSJhbmQiLCB1ImJ1dCIsIHUi
REM b3IiLCB1IndpdGgiLCB1IndpdGhvdXQiLAogICAgdSJpcyIsIHUiYXJlIiwgdSJ3YXMiLCB1
REM IndlcmUiLCB1ImFtIiwgdSJ0byIsIHUib2YiLCB1ImluIiwgdSJvbiIsCiAgICB1ImZvciIs
REM IHUidGhpcyIsIHUidGhhdCIsIHUibm90IiwgdSJubyIsIHUieWVzIiwgdSJiZSIsIHUiYmVl
REM biIsCiAgICB1ImJlaW5nIiwgdSJkbyIsIHUiZGlkIiwgdSJkb2VzIiwgdSJ3aWxsIiwgdSJ3
REM b3VsZCIsIHUiY291bGQiLCB1InNob3VsZCIsCiAgICB1ImhhdmUiLCB1ImhhcyIsIHUiaGFk
REM IiwgdSJjYW4iLCB1ImNhbm5vdCIsIHUiaGVyZSIsIHUidGhlcmUiLCB1ImV2ZXJ5b25lIiwK
REM ICAgIHUic29tZXRoaW5nIiwgdSJzb21lb25lIiwKfQoKIyBDb250cmHDp8O1ZXMgc8OjbyBl
REM dmlkw6puY2lhIGZvcnRlIGRlIGluZ2zDqnMgZW0gZmFsYXMgcXVlIG8gR29vZ2xlIGRldm9s
REM dmV1CiMgbGl0ZXJhbG1lbnRlLiBBIHJlZ3JhIGNvbnRpbnVhIHZhbGVuZG8gc29tZW50ZSBw
REM YXJhIHJlc3VsdGFkbyBpZMOqbnRpY28uCkVOR0xJU0hfUkVUUllfQ09OVFJBQ1RJT05TID0g
REM ewogICAgdSJ0aGF0J3MiLCB1Iml0J3MiLCB1ImknbSIsIHUieW91J3JlIiwgdSJ3ZSdyZSIs
REM IHUidGhleSdyZSIsIHUiaSd2ZSIsCiAgICB1InlvdSd2ZSIsIHUid2UndmUiLCB1InRoZXkn
REM dmUiLCB1ImRvbid0IiwgdSJkb2Vzbid0IiwgdSJkaWRuJ3QiLAogICAgdSJjYW4ndCIsIHUi
REM Y2Fubm90IiwgdSJjb3VsZG4ndCIsIHUic2hvdWxkbid0IiwgdSJ3b3VsZG4ndCIsIHUid29u
REM J3QiLAogICAgdSJpc24ndCIsIHUiYXJlbid0IiwgdSJ3YXNuJ3QiLCB1IndlcmVuJ3QiLCB1
REM ImhhdmVuJ3QiLCB1Imhhc24ndCIsCiAgICB1ImhhZG4ndCIsCn0KCkVOR0xJU0hfSEVTSVRB
REM VElPTl9XT1JEUyA9IHt1InVtIiwgdSJ1aCIsIHUiZXIiLCB1ImVybSJ9CgojIEVudHJhZGFz
REM IGRlIGludGVyZmFjZS9jb250cm9sZSBxdWUgbsOjbyBkZXZlbSByZWNlYmVyIHVtYSB0cmFk
REM dcOnw6NvIHRleHR1YWwKIyBmb3LDp2FkYSBwb3JxdWUgc8OjbyB0ZWNsYXMsIHBsYWNlaG9s
REM ZGVycywgaWRlbnRpZmljYWRvcmVzIG91IGFicmV2aWHDp8O1ZXMKIyB0cmF0YWRhcyBwZWxv
REM IHBhdGNoIGRhIE9ww6fDo28gNC4KRVFVQUxfVFJBTlNMQVRJT05fUFJPVEVDVEVEID0gewog
REM ICAgdSJ4IiwgdSJDdHJsIiwgdSJIIiwgdSJTIiwgdSJWIiwgdSJBdXRvIiwgdSJRLlNhdmUi
REM LCB1Ik1lbnUiLAogICAgdSJvbmVfbGluZV9vbmVfcHJvcGVydHkiLCB1InNwbGluZV9lZGl0
REM b3IiLAogICAgdSJ7I2F1dG9fcGFnZX1BIiwgdSJ7I3F1aWNrX3BhZ2V9USIsCiAgICB1Insj
REM ZmlsZV90aW1lfSVBLCAlQiAlZCAlWSwgJUg6JU0iLAp9CgojIENvcnJlw6fDtWVzIHBvbnR1
REM YWlzIHBhcmEgZXhwcmVzc8O1ZXMgcXVlIG8gR29vZ2xlIHBvZGUgZGV2b2x2ZXIgaWTDqm50
REM aWNhcywKIyBlbWJvcmEgZXhpc3RhIHVtYSB0cmFkdcOnw6NvIFBULUJSIGNsYXJhIGUgZGVz
REM ZWphZGEuCiMgQ29ycmXDp8O1ZXMgbG9jYWlzIHNvbWVudGUgcGFyYSByZXN1bHRhZG9zIHF1
REM ZSBvIEdvb2dsZSBkZXZvbHZldQojIEVYQVRBTUVOVEUgaWd1YWlzIGFvIG9yaWdpbmFsLiBJ
REM c3NvIG51bmNhIHN1YnN0aXR1aSB1bWEgdHJhZHXDp8OjbyBxdWUKIyBvIEdvb2dsZSBqw6Eg
REM dGVuaGEgYWx0ZXJhZG8gY29tIHN1Y2Vzc28uCkVRVUFMX1RSQU5TTEFUSU9OX0ZBTExCQUNL
REM X1BUQlIgPSB7CiAgICB1Im5vIjogdSJOw6NvIiwKICAgIHUieWVzIjogdSJTaW0iLAogICAg
REM dSJnYW1lIG92ZXIiOiB1IkZpbSBkZSBqb2dvIiwKICAgIHUiaHVoIjogdSJIZWluPyIsCiAg
REM ICB1ImFhaCI6IHUiQWguLi4iLAogICAgdSJ0aGUgY29uZmVzc2lvbiI6IHUiYSBjb25maXNz
REM w6NvIiwKICAgIHUiZGV2ZWxvcGluZyBhIGNydXNoIjogdSJkZXNlbnZvbHZlbmRvIHVtYSBw
REM YWl4w6NvIiwKICAgIHUiYSByb3V0aW5lIGRheSI6IHUidW0gZGlhIHJvdGluZWlybyIsCiAg
REM ICAjIFLDs3R1bG9zL3Rlcm1vcyBpbmdsZXNlcyBjdXJ0b3MgcXVlIHBvZGVtLCBvY2FzaW9u
REM YWxtZW50ZSwgdm9sdGFyIGlndWFpcy4KICAgIHUiY2xvc2UgZWRpdG9yIjogdSJGZWNoYXIg
REM ZWRpdG9yPyIsCiAgICB1Im5vIGZpbGVzIjogdSJOZW5odW0gYXJxdWl2byIsCiAgICB1Im5v
REM dGhpbmcgdG8gcHV0IjogdSJOYWRhIHBhcmEgaW5zZXJpciIsCiAgICB1ImNsaXBib2FyZCI6
REM IHUiw6FyZWEgZGUgdHJhbnNmZXLDqm5jaWEiLAogICAgdSJhYnNvbHV0ZSI6IHUiYWJzb2x1
REM dG8iLAogICAgdSJmcmFjdGlvbiI6IHUiZnJhw6fDo28iLAogICAgdSJvcHRpb24iOiB1Im9w
REM w6fDo28iLAogICAgdSJyZW1vdmUiOiB1InJlbW92ZXIiLAogICAgdSJjbG9zZSI6IHUiZmVj
REM aGFyIiwKICAgIHUibG9vcCI6IHUiY2ljbG8iLAogICAgdSJyZXNldCI6IHUicmVpbmljaWFy
REM IiwKICAgIHUicmV0dXJuIjogdSJ2b2x0YXIiLAogICAgdSJzdGFydCI6IHUiaW5pY2lhciIs
REM CiAgICB1ImVuZCI6IHUiZmltIiwKfQoKIyBQYWxhdnJhcy9mcmFnbWVudG9zIHF1ZSBzw6Nv
REM IHNpbmFpcyBmb3J0ZXMgZGUgaW5nbMOqcyBxdWFuZG8gdW0gcmVzdWx0YWRvCiMgaW50ZWly
REM byB2b2x0b3UgaWTDqm50aWNvLiBBIGxpc3RhIMOpIGRlbGliZXJhZGFtZW50ZSBwZXF1ZW5h
REM IHBhcmEgbsOjbwojIHRyYW5zZm9ybWFyIG5vbWVzLCByaXNhZGFzLCBlZmVpdG9zIHNvbm9y
REM b3Mgb3UgaWRlbnRpZmljYWRvcmVzIHTDqWNuaWNvcy4KRVFVQUxfVFJBTlNMQVRJT05fRU5H
REM TElTSF9ISU5UUyA9IHsKICAgIHUicGxlYXNlIiwgdSJ0eXBlIiwgdSJ2YWx1ZSIsIHUiZmls
REM ZXMiLCB1ImZpbGUiLCB1ImNsaXBib2FyZCIsCiAgICB1ImNsb3NlIiwgdSJlZGl0b3IiLCB1
REM Im9wZW4iLCB1InN0YXJ0IiwgdSJlbmQiLCB1InJldHVybiIsIHUicmVtb3ZlIiwKICAgIHUi
REM cmVzZXQiLCB1Im9wdGlvbiIsIHUiYWJzb2x1dGUiLCB1ImZyYWN0aW9uIiwgdSJub3RoaW5n
REM IiwgdSJ1c2VkIiwKICAgIHUidGltZSIsIHUiaW52YWxpZCIsIHUiY2FuIiwgdSJjYW4ndCIs
REM IHUiY2Fubm90IiwgdSJuZXciLCB1InNjZW5lIiwKICAgIHUic2VsZWN0IiwgdSJzZXQiLCB1
REM ImFtb3VudCIsIHUiY2hhbmdlIiwgdSJwcm9wZXJ0eSIsIHUiZm9sbG93aW5nIiwKICAgIHUi
REM b25seSIsIHUib25lIiwgdSJwYWdlIiwgdSJzYXZlIiwgdSJsb2FkIiwgdSJoZWxwIiwgdSJ5
REM ZXMiLCB1Im5vIiwKICAgIHUiZ2FtZSIsIHUib3ZlciIsIHUiaHVoIiwgdSJzb3JyeSIsIHUi
REM d2hhdCIsIHUid2hlcmUiLCB1IndoeSIsCiAgICB1ImNvbmZlc3Npb24iLCB1ImNydXNoIiwg
REM dSJyb3V0aW5lIiwgdSJzdG9yeSIsIHUic2Nob29sIiwgdSJzdHVkZW50IiwKICAgIHUiZnJp
REM ZW5kIiwgdSJmcmllbmRzIiwgdSJmcmllbmRzaGlwIiwgdSJjb252ZXJzYXRpb24iLCB1InNp
REM dHVhdGlvbiIsCiAgICB1Im1vbWVudCIsIHUibW9tZW50cyIsIHUiaG91c2UiLCB1ImhvbWUi
REM LCB1InN0b3JlIiwgdSJ0b2RheSIsCiAgICB1InRvbW9ycm93IiwgdSJ5ZXN0ZXJkYXkiLCB1
REM Im5pZ2h0IiwgdSJtb3JuaW5nIiwgdSJsdW5jaCIsIHUiY2x1YiIsCiAgICB1InJvb20iLCB1
REM IndvcmxkIiwgdSJoZWFkIiwgdSJoZWFydCIsIHUiZmFjZSIsIHUiaGFuZHMiLCB1ImNoYWly
REM IiwKICAgIHUiZG9vciIsIHUid2luZG93IiwgdSJ0YWJsZSIsIHUia2l0Y2hlbiIsIHUicGFy
REM dHkiLCB1ImZvb2QiLCB1ImJvb2siLAogICAgdSJib29rcyIsIHUid2F0ZXIiLCB1ImRyaW5r
REM IiwgdSJsb29rIiwgdSJsb29rZWQiLCB1Imxvb2tpbmciLCB1ImZlbHQiLAogICAgdSJmZWVs
REM IiwgdSJmZWVsaW5nIiwgdSJ3YWxrIiwgdSJ3YWxrZWQiLCB1IndhbGtpbmciLCB1InRhbGsi
REM LCB1InRhbGtlZCIsCiAgICB1InNheSIsIHUic2FpZCIsIHUic2F5aW5nIiwgdSJ0ZWxsIiwg
REM dSJ0b2xkIiwgdSJrbm93IiwgdSJrbmV3IiwKICAgIHUidGhpbmsiLCB1InRob3VnaHQiLCB1
REM IndhbnQiLCB1IndhbnRlZCIsIHUibmVlZCIsIHUibmVlZGVkIiwgdSJtYWtlIiwKICAgIHUi
REM bWFkZSIsIHUiZG9pbmciLCB1ImRvbmUiLCB1Imdvb2QiLCB1ImJhZCIsIHUibGl0dGxlIiwg
REM dSJiaWciLCB1InNtYWxsIiwKICAgIHUiYmFjayIsIHUiYXdheSIsIHUiYXJvdW5kIiwgdSJh
REM Z2FpbiIsIHUiYWx3YXlzIiwgdSJuZXZlciIsIHUicmVhbGx5IiwKICAgIHUidmVyeSIsIHUi
REM anVzdCIsIHUib25seSIsIHUibWF5YmUiLCB1InN1cmUiLCB1InJpZ2h0IiwgdSJ3cm9uZyIs
REM IHUid2VsbCIsCiAgICB1ImZpbmFsbHkiLCB1InN1ZGRlbmx5IiwgdSJxdWlja2x5IiwgdSJz
REM bG93bHkiLCB1ImJlY2F1c2UiLCB1ImJlZm9yZSIsCiAgICB1ImFmdGVyIiwgdSJ3aGlsZSIs
REM IHUic29tZW9uZSIsIHUic29tZXRoaW5nIiwgdSJldmVyeXRoaW5nIiwgdSJhbnlvbmUiLAp9
REM CgoKZGVmIF9jaGF2ZV9mYWxsYmFja19wdGJyKHRleHRvKToKICAgIHZhbG9yID0gdGV4dG8g
REM b3IgdSIiCiAgICB2YWxvciA9IHJlLnN1YihyIlx7W159XHJcbl0qXH18XFtbXl1cclxuXSpc
REM XSIsIHUiICIsIHZhbG9yKQogICAgdmFsb3IgPSByZS5zdWIociJbXkEtWmEtesOALcO/J+KA
REM mV0rIiwgdSIgIiwgdmFsb3IpCiAgICByZXR1cm4gcmUuc3ViKHIiXHMrIiwgdSIgIiwgdmFs
REM b3IpLnN0cmlwKCkubG93ZXIoKQoKCmRlZiBkZXZlX2ZvcmNhcl9yZXRlbnRhdGl2YV9pZ3Vh
REM bCh0ZXh0byk6CiAgICAiIiIKICAgIFJldGVudGF0aXZhIHVzYWRhIHBhcmEgdGV4dG9zIHF1
REM ZSB2b2x0YXJhbSBpZMOqbnRpY29zIGFvIG9yaWdpbmFsLgogICAgTWFudMOpbSBhIHByb3Rl
REM w6fDo28gY29udHJhIGlkZW50aWZpY2Fkb3JlcywgYWJyZXZpYcOnw7VlcyBlIGVmZWl0b3Mg
REM c29ub3Jvcy4KICAgICIiIgogICAgdCA9ICh0ZXh0byBvciB1IiIpLnN0cmlwKCkKICAgIGNo
REM YXZlID0gX2NoYXZlX2ZhbGxiYWNrX3B0YnIodCkKICAgIGlmIG5vdCB0IG9yIHQgaW4gRVFV
REM QUxfVFJBTlNMQVRJT05fUFJPVEVDVEVEOgogICAgICAgIHJldHVybiBGYWxzZQogICAgaWYg
REM Y2hhdmUgaW4gRVFVQUxfVFJBTlNMQVRJT05fRkFMTEJBQ0tfUFRCUjoKICAgICAgICByZXR1
REM cm4gVHJ1ZQogICAgaWYgbm90IHJlLnNlYXJjaChyIltBLVphLXrDgC3Dv10iLCB0KToKICAg
REM ICAgICByZXR1cm4gRmFsc2UKICAgIGlmICJfIiBpbiB0IGFuZCBub3QgcmUuc2VhcmNoKHIi
REM XHMiLCB0KToKICAgICAgICByZXR1cm4gRmFsc2UKICAgIGlmIHJlLm1hdGNoKHIiXltBLVph
REM LXpdJCIsIHQpOgogICAgICAgIHJldHVybiBGYWxzZQogICAgIyBOw6NvIGdhc3RhciByZXF1
REM aXNpw6fDtWVzIGNvbSByaXNhZGFzL2VmZWl0b3Mgc29ub3JvcyBxdWUgbyBHb29nbGUKICAg
REM ICMgY29ycmV0YW1lbnRlIHBvZGUgZGV2b2x2ZXIgc2VtIG11ZGFuw6dhLgogICAgaWYgcmUu
REM bWF0Y2gociJeKD86aGEoPzpoYSkrfGgoPzptbXxtKSt8YStoK3xnKyg/OmxwKSspXFcqJCIs
REM IHQubG93ZXIoKSk6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBwYWxhdnJhcyA9IHJlLmZp
REM bmRhbGwociJbQS1aYS16w4Atw79dKyg/Olsn4oCZXVtBLVphLXrDgC3Dv10rKT8iLCB0Lmxv
REM d2VyKCkpCiAgICBpZiBhbnkocCBpbiBFUVVBTF9UUkFOU0xBVElPTl9FTkdMSVNIX0hJTlRT
REM IGZvciBwIGluIHBhbGF2cmFzKToKICAgICAgICByZXR1cm4gVHJ1ZQogICAgY29tdW5zID0g
REM c3VtKDEgZm9yIHAgaW4gcGFsYXZyYXMgaWYgcCBpbiBFTkdMSVNIX1JFVFJZX0NPTU1PTikK
REM ICAgIHJldHVybiBsZW4ocGFsYXZyYXMpID49IDMgYW5kIGNvbXVucyA+PSAxCgoKZGVmIGRl
REM dmVfZm9yY2FyX3JldGVudGF0aXZhX2RpYWxvZ28odGV4dG8pOgogICAgIiIiCiAgICBEZXRl
REM Y3RvciBjb25zZXJ2YWRvciBwYXJhIEZBTEFTICh0aXBvPWRpw6Fsb2dvKSBxdWUgbyBHb29n
REM bGUgZGV2b2x2ZXUKICAgIGV4YXRhbWVudGUgaWd1YWlzIGFvIG9yaWdpbmFsLiBTw7MgZW50
REM cmEgbmVzc2Egcm90YSBxdWFuZG8gaMOhIGV2aWTDqm5jaWEKICAgIHRleHR1YWwgcmF6b2F2
REM ZWxtZW50ZSBjbGFyYSBkZSBpbmdsw6pzLCBwcmVzZXJ2YW5kbyBub21lcywgZWZlaXRvcyBz
REM b25vcm9zLAogICAgaWRlbnRpZmljYWRvcmVzIGUgYXRhbGhvcy4KICAgICIiIgogICAgdCA9
REM ICh0ZXh0byBvciB1IiIpLnN0cmlwKCkKICAgIGlmIG5vdCB0IG9yIHQgaW4gRVFVQUxfVFJB
REM TlNMQVRJT05fUFJPVEVDVEVEOgogICAgICAgIHJldHVybiBGYWxzZQogICAgY2hhdmUgPSBf
REM Y2hhdmVfZmFsbGJhY2tfcHRicih0KQogICAgaWYgY2hhdmUgaW4gRVFVQUxfVFJBTlNMQVRJ
REM T05fRkFMTEJBQ0tfUFRCUjoKICAgICAgICByZXR1cm4gVHJ1ZQogICAgaWYgbm90IHJlLnNl
REM YXJjaChyIltBLVphLXrDgC3Dv10iLCB0KToKICAgICAgICByZXR1cm4gRmFsc2UKICAgIGlm
REM ICJfIiBpbiB0IGFuZCBub3QgcmUuc2VhcmNoKHIiXHMiLCB0KToKICAgICAgICByZXR1cm4g
REM RmFsc2UKICAgIGlmIHJlLm1hdGNoKHIiXltBLVphLXpdJCIsIHQpOgogICAgICAgIHJldHVy
REM biBGYWxzZQogICAgIyBJbnRlcmplacOnw7VlcywgcmlzYWRhcyBlIGVmZWl0b3Mgc29ub3Jv
REM cyBjb250aW51YW0gZm9yYSBkZXN0YSByb3RhLgogICAgaWYgcmUubWF0Y2gociJeKD86aGEo
REM PzpoYSkrfGgoPzptbXxtKSt8YStoK3xnKyg/OmxwKSspXFcqJCIsIHQubG93ZXIoKSk6CiAg
REM ICAgICAgcmV0dXJuIEZhbHNlCiAgICBwYWxhdnJhcyA9IHJlLmZpbmRhbGwociJbQS1aYS16
REM w4Atw79dKyg/Olsn4oCZXVtBLVphLXrDgC3Dv10rKT8iLCB0Lmxvd2VyKCkpCiAgICBkaXN0
REM aW50aXZhcyA9IHN1bSgxIGZvciBwIGluIHBhbGF2cmFzIGlmIHAgaW4gRU5HTElTSF9SRVRS
REM WV9ESVNUSU5DVElWRSkKICAgIGNvbXVucyA9IHN1bSgxIGZvciBwIGluIHBhbGF2cmFzIGlm
REM IHAgaW4gRU5HTElTSF9SRVRSWV9DT01NT04pCiAgICBpZiBhbnkocCBpbiBFTkdMSVNIX1JF
REM VFJZX0NPTlRSQUNUSU9OUyBmb3IgcCBpbiBwYWxhdnJhcyk6CiAgICAgICAgcmV0dXJuIFRy
REM dWUKICAgICMgQ29uc3RydcOnw7VlcyBkbyB0aXBvICJJIGhhdmUsIHVtLi4uIi4gInVtIiBz
REM b3ppbmhvIG7Do28gw6kgZXZpZMOqbmNpYQogICAgIyBzdWZpY2llbnRlLCBwb2lzIHRhbWLD
REM qW0gw6kgdW1hIHBhbGF2cmEgbm9ybWFsIGVtIHBvcnR1Z3XDqnM7IGVsZSBzw7MgcGVzYQog
REM ICAgIyBxdWFuZG8gdmVtIGFjb21wYW5oYWRvIGRlIGV2aWTDqm5jaWEgaW5nbGVzYS4KICAg
REM IHRlbV9oZXNpdGFjYW8gPSBhbnkocCBpbiBFTkdMSVNIX0hFU0lUQVRJT05fV09SRFMgZm9y
REM IHAgaW4gcGFsYXZyYXMpCiAgICBpZiB0ZW1faGVzaXRhY2FvIGFuZCAoZGlzdGludGl2YXMg
REM Pj0gMSBvciBjb211bnMgPj0gMSk6CiAgICAgICAgcmV0dXJuIFRydWUKICAgICMgUGFyYSBk
REM acOhbG9nb3MsIHVtYSBwYWxhdnJhIGluZ2xlc2EgZGlzdGludGl2YSAoY29tZSwgbW9tLCB3
REM aGF0LCBldGMuKQogICAgIyBqw6Egw6kgZXZpZMOqbmNpYSBzdWZpY2llbnRlOyBzZW0gaXNz
REM bywgZXhpZ2ltb3MgcGVsbyBtZW5vcyBkdWFzIHBhbGF2cmFzCiAgICAjIGNvbXVucyBkZSBp
REM bmdsw6pzIHBhcmEgZXZpdGFyIGZhbHNvcyBwb3NpdGl2b3MgZW0gbm9tZXMgb3UgaW50ZXJq
REM ZWnDp8O1ZXMuCiAgICBpZiBkaXN0aW50aXZhcyA+PSAxOgogICAgICAgIHJldHVybiBUcnVl
REM CiAgICByZXR1cm4gY29tdW5zID49IDIKCgojIFZvY2FidWzDoXJpbyBhZGljaW9uYWwgcGFy
REM YSBkZXRlY3RhciBpbmdsw6pzIHJlc2lkdWFsIGVtIHRyYWR1w6fDtWVzIHBhcmNpYWxtZW50
REM ZSBhbHRlcmFkYXMuCiMgQSBsaXN0YSBjb2JyZSBwYWxhdnJhcyBtdWl0byBjb211bnMvZXN0
REM cnV0dXJhaXMgZSBuw6NvIHN1YnN0aXR1aSBvIEdvb2dsZTsgZWxhIHNlcnZlCiMgYXBlbmFz
REM IHBhcmEgZGVjaWRpciBxdWFuZG8gdmFsZSBmYXplciBhIHJldGVudGF0aXZhIGV4cGzDrWNp
REM dGEgZW4tPnB0LUJSLgpSRVNJRFVBTF9FTkdMSVNIX1NUUk9ORyA9IHsKICAgICMgU2luYWlz
REM IGZvcnRlcyBlbmNvbnRyYWRvcyBuYSBhdWRpdG9yaWEgZGEgVjEyNyBlIGFuZ2xpY2lzbW9z
REM IHF1ZSBuw6NvCiAgICAjIGRldmVtIHBlcm1hbmVjZXIgZW0gdW1hIHNhw61kYSBQVC1CUiB0
REM cmFkdXrDrXZlbC4KICAgIHUic3BhY2tsZSIsIHUiZmVlZGJhY2siLCB1Im1vZGRlciIsIHUi
REM Ym9sdGhlYWQiLCB1InBpZXJjaW5nIiwgdSJmbGFzaCIsCiAgICB1ImZsYXNoaW5nIiwKfQoK
REM IyBUZXJtb3MgY3VydG9zIHF1ZSBwb2RlbSBhcGFyZWNlciBjb21vIGVtcHLDqXN0aW1vcywg
REM bm9tZXMgb3UgY29pbmNpZMOqbmNpYXM7CiMgbsOjbyBzw6NvIGNvbnNpZGVyYWRvcyBmb3J0
REM ZXMgaXNvbGFkYW1lbnRlLgpSRVNJRFVBTF9FTkdMSVNIX0FNQklHVU9VUyA9IHsKICAgIHUi
REM b25saW5lIiwgdSJwbGF5ZXIiLCB1Im1vZCIsIHUiZ2FtZSIsIHUicG9lbSIsIHUic3RhciIs
REM CiAgICB1InJlZCIsIHUidmVsdmV0IiwgdSJwb3J0YWwiLCB1ImFuaW1hbCIsIHUiZW5pZ21h
REM IiwgdSJvdmVyZG9zZSIsCn0KClJFU0lEVUFMX0VOR0xJU0hfV09SRFMgPSB7CiAgICB1ImFi
REM b3V0IiwgdSJhYm92ZSIsIHUiYWNyb3NzIiwgdSJhY3R1YWxseSIsIHUiYWZ0ZXIiLCB1ImFn
REM YWluIiwgdSJhZ2FpbnN0IiwgdSJhZ28iLAogICAgdSJhbGwiLCB1ImFsbW9zdCIsIHUiYWxy
REM ZWFkeSIsIHUiYWxzbyIsIHUiYWx3YXlzIiwgdSJhbm90aGVyIiwgdSJhbnkiLCB1ImFueXRo
REM aW5nIiwKICAgIHUiYW55d2F5IiwgdSJhd2F5IiwgdSJiYWNrIiwgdSJiZWNhdXNlIiwgdSJi
REM ZWZvcmUiLCB1ImJlaGluZCIsIHUiYmVsb3ciLCB1ImJlc2lkZSIsCiAgICB1ImJldHdlZW4i
REM LCB1ImJvdGgiLCB1ImJyZWFrIiwgdSJicmluZyIsIHUiYnJvdWdodCIsIHUiY2FsbCIsIHUi
REM Y2FsbGVkIiwgdSJjYWxsaW5nIiwKICAgIHUiY2FtZSIsIHUiY2FyZSIsIHUiY2FycnkiLCB1
REM ImNoYW5nZSIsIHUiY2hhbmdlZCIsIHUiY2hlY2siLCB1ImNob29zZSIsIHUiY2hvc2VuIiwK
REM ICAgIHUiY2xlYXIiLCB1ImNsb3NlIiwgdSJjbG9zZWQiLCB1ImNvbWluZyIsIHUiY29udGlu
REM dWUiLCB1ImNvdWxkIiwgdSJjb3VsZG4ndCIsIHUiY291cnNlIiwKICAgIHUiY3V0IiwgdSJk
REM YXkiLCB1ImRheXMiLCB1ImRlY2lkZSIsIHUiZGVjaWRlZCIsIHUiZGlkIiwgdSJkaWRuJ3Qi
REM LCB1ImRpZmZlcmVudCIsCiAgICB1ImRvZXMiLCB1ImRvZXNuJ3QiLCB1ImRvaW5nIiwgdSJk
REM b25lIiwgdSJkb24ndCIsIHUiZG93biIsIHUiZWFjaCIsIHUiZWxzZSIsIHUiZW5vdWdoIiwK
REM ICAgIHUiZXZlbiIsIHUiZXZlciIsIHUiZXZlcnkiLCB1ImV2ZXJ5dGhpbmciLCB1ImV4YWN0
REM bHkiLCB1ImZlZWwiLCB1ImZlbHQiLCB1ImZpbmQiLCB1ImZvdW5kIiwKICAgIHUiZmlyc3Qi
REM LCB1ImZyb20iLCB1ImdldCIsIHUiZ2V0cyIsIHUiZ2V0dGluZyIsIHUiZ2l2ZSIsIHUiZ2l2
REM ZW4iLCB1ImdpdmVzIiwgdSJnbyIsIHUiZ29lcyIsCiAgICB1ImdvaW5nIiwgdSJnb25lIiwg
REM dSJnb3QiLCB1Imd1ZXNzIiwgdSJoYWQiLCB1ImhhcyIsIHUiaGF2ZW4ndCIsIHUiaGF2aW5n
REM IiwgdSJoZWFyIiwKICAgIHUiaGVhcmQiLCB1ImhlbHAiLCB1ImhlcmUiLCB1ImhlcnNlbGYi
REM LCB1ImhpbSIsIHUiaGltc2VsZiIsIHUiaG9sZCIsIHUiaG9wZSIsIHUiaG93IiwKICAgIHUi
REM aG93ZXZlciIsIHUiaWRlYSIsIHUiaWYiLCB1ImltbWVkaWF0ZWx5IiwgdSJpbnRvIiwgdSJq
REM dXN0IiwgdSJrZWVwIiwgdSJrZWVwcyIsIHUia25ldyIsCiAgICB1Imtub3ciLCB1Imtub3dz
REM IiwgdSJsYXN0IiwgdSJsYXRlciIsIHUibGVmdCIsIHUibGV0IiwgdSJsZXRzIiwgdSJsaWtl
REM IiwgdSJsaWtlZCIsIHUibGl0dGxlIiwKICAgIHUibG9vayIsIHUibG9va3MiLCB1Im1hZGUi
REM LCB1Im1ha2UiLCB1Im1ha2VzIiwgdSJtYXliZSIsIHUibWVhbiIsIHUibWVhbnMiLCB1Im1p
REM Z2h0IiwKICAgIHUibW9yZSIsIHUibW9zdCIsIHUibXVjaCIsIHUibXVzdCIsIHUibXlzZWxm
REM IiwgdSJuZWFyIiwgdSJuZXZlciIsIHUibmV4dCIsIHUibm90aGluZyIsCiAgICB1Im5vdyIs
REM IHUib2ZmIiwgdSJvZnRlbiIsIHUib25jZSIsIHUib3RoZXIiLCB1Im90aGVycyIsIHUib3V0
REM IiwgdSJvdmVyIiwgdSJvd24iLCB1InBhcnQiLAogICAgdSJwZXJoYXBzIiwgdSJwbGFjZSIs
REM IHUicGxheSIsIHUicG9pbnQiLCB1InB1dCIsIHUicXVpdGUiLCB1InJhdGhlciIsIHUicmVh
REM bGx5IiwgdSJyZW1lbWJlciIsCiAgICB1InJpZ2h0IiwgdSJzYWlkIiwgdSJzYW1lIiwgdSJz
REM YXciLCB1InNheSIsIHUic2F5cyIsIHUic2Vjb25kIiwgdSJzZWVtIiwgdSJzZWVtcyIsIHUi
REM c2VlbiIsCiAgICB1InNob3VsZCIsIHUic2hvdWxkbid0IiwgdSJzaW5jZSIsIHUic29tZXRo
REM aW5nIiwgdSJzb21ldGltZXMiLCB1InNvb24iLCB1InN0aWxsIiwgdSJzdWNoIiwKICAgIHUi
REM dGFrZSIsIHUidGFrZW4iLCB1InRha2VzIiwgdSJ0ZWxsIiwgdSJ0aGFuIiwgdSJ0aGF0Iiwg
REM dSJ0aGVpciIsIHUidGhlbSIsIHUidGhlbXNlbHZlcyIsCiAgICB1InRoZW4iLCB1InRoZXJl
REM IiwgdSJ0aGVzZSIsIHUidGhpbmciLCB1InRoaW5ncyIsIHUidGhpbmsiLCB1InRoaW5rcyIs
REM IHUidGhvdWdodCIsIHUidGhyb3VnaCIsCiAgICB1InRvZ2V0aGVyIiwgdSJ0b28iLCB1InRy
REM eSIsIHUidHJ5aW5nIiwgdSJ0dXJuIiwgdSJ1bmRlciIsIHUidW50aWwiLCB1InVzZWQiLCB1
REM InVzZSIsIHUidXNlcyIsCiAgICB1InZlcnkiLCB1IndhaXQiLCB1IndhbnQiLCB1IndhbnRz
REM IiwgdSJ3YXMiLCB1Indhc24ndCIsIHUid2F5IiwgdSJ3ZWxsIiwgdSJ3ZW50IiwgdSJ3ZXJl
REM IiwKICAgIHUid2VyZW4ndCIsIHUid2hhdCIsIHUid2hhdGV2ZXIiLCB1IndoZW4iLCB1Indo
REM ZW5ldmVyIiwgdSJ3aGVyZSIsIHUid2hldGhlciIsIHUid2hpY2giLAogICAgdSJ3aGlsZSIs
REM IHUid2hvIiwgdSJ3aG9sZSIsIHUid2hvc2UiLCB1IndoeSIsIHUid2l0aG91dCIsIHUid29u
REM J3QiLCB1IndvcmsiLCB1IndvcmtlZCIsCiAgICB1IndvdWxkIiwgdSJ3b3VsZG4ndCIsIHUi
REM eWVhaCIsIHUieWV0IiwgdSJ5b3VyIiwgdSJ5b3Vyc2VsZiIsIHUieW91J3JlIiwKfQoKZGVm
REM IF90ZXh0b19zZW1fcnVpZG9fcGFyYV9kZXRlY3Rvcl9pbmdsZXModmFsb3IpOgogICAgdmFs
REM b3IgPSB0ZXh0b19jb21wYXRpdmVsKHZhbG9yLCB1IiIpCiAgICBmb3IgdGVybW8gaW4gVEVS
REM TU9TX05BT19UUkFEVVpJUl9HT09HTEU6CiAgICAgICAgdmFsb3IgPSByZS5zdWIocmUuZXNj
REM YXBlKHRlcm1vKSwgdSIgIiwgdmFsb3IsIGZsYWdzPXJlLkkpCiAgICAjIFVSTHMsIGNhbWlu
REM aG9zLCBleHRlbnPDtWVzIGUgdG9rZW5zIHByb3RlZ2lkb3MgbsOjbyBzw6NvIGV2aWTDqm5j
REM aWEgZGUKICAgICMgaW5nbMOqcyByZXNpZHVhbC4gSWdub3LDoS1sb3MgZXZpdGEgcmV0ZW50
REM YXRpdmFzIGRlc25lY2Vzc8OhcmlhcyBlLAogICAgIyBwcmluY2lwYWxtZW50ZSwgZXZpdGEg
REM c3Vic3RpdHVpciB1bWEgdHJhZHXDp8OjbyBjb3JyZXRhIHBvciB1bWEgc2VndW5kYQogICAg
REM IyB0cmFkdcOnw6NvIHBpb3IgY2F1c2FkYSBhcGVuYXMgcG9yIHRleHRvIHTDqWNuaWNvL1VS
REM TC4KICAgIHZhbG9yID0gcmUuc3ViKHIiaHR0cHM/Oi8vXFMrIiwgdSIgIiwgdmFsb3IsIGZs
REM YWdzPXJlLkkpCiAgICB2YWxvciA9IHJlLnN1YihyIig/OltBLVphLXowLTlfLi1dK1tcXC9d
REM KSpbQS1aYS16MC05Xy4tXStcLig/OnBuZ3xqcGd8anBlZ3xnaWZ8d2VicHx3ZWJtfG9nZ3xt
REM cDN8d2F2fGZsYWN8bTRhfHR0ZnxvdGZ8dHRjfHJweXxycHljfHJwYXxkbGx8c298ZXhlfGJp
REM bnxqc29ufHB5fHB5YykiLCB1IiAiLCB2YWxvciwgZmxhZ3M9cmUuSSkKICAgIHZhbG9yID0g
REM cmUuc3ViKHIiXHtbXn1cclxuXSpcfXxcW1teXVxyXG5dKlxdIiwgdSIgIiwgdmFsb3IpCiAg
REM ICByZXR1cm4gdmFsb3IKCgpkZWYgbm9ybWFsaXphcl90ZXJtb3NfaW5nbGVzX3Jlc2lkdWFp
REM c19wdGJyKHRleHRvKToKICAgICIiIlJlbW92ZSBwb3Vjb3MgYW5nbGljaXNtb3MgaW5lcXXD
REM rXZvY29zIHNlbSByZWVzY3JldmVyIG8gZXN0aWxvIGRhIHRyYWR1w6fDo28uIiIiCiAgICB2
REM YWxvciA9IHRleHRvX2NvbXBhdGl2ZWwodGV4dG8sIHUiIikKICAgIHJlZ3JhcyA9ICgKICAg
REM ICAgICAociJcYmdhbWVccytvdmVyXGIiLCB1ImZpbSBkZSBqb2dvIiksCiAgICAgICAgKHIi
REM XGJtb2RkZXJcYiIsIHUiYXV0b3IgZG8gbW9kIiksCiAgICAgICAgKHIiXGJmZWVkYmFja1xi
REM IiwgdSJyZXRvcm5vIiksCiAgICAgICAgKHIiXGJvIHNwYWNrbGVcYiIsIHUiYSBtYXNzYSBj
REM b3JyaWRhIiksCiAgICAgICAgKHIiXGJTcGFja2xlXGIiLCB1Ik1hc3NhIGNvcnJpZGEiKSwK
REM ICAgICAgICAociJcYnNwYWNrbGVcYiIsIHUibWFzc2EgY29ycmlkYSIpLAogICAgICAgIChy
REM IlxiQm9sdGhlYWRcYiIsIHUiQ2FiZcOnYSBkZSBwYXJhZnVzbyIpLAogICAgICAgIChyIlxi
REM Ym9sdGhlYWRcYiIsIHUiY2FiZcOnYSBkZSBwYXJhZnVzbyIpLAogICAgICAgIChyIlxiRmxh
REM c2hcYiIsIHUiQ2xhcsOjbyIpLAogICAgICAgIChyIlxiZmxhc2hcYiIsIHUiY2xhcsOjbyIp
REM LAogICAgICAgIChyIlxicGllcmNpbmdcYiIsIHUicGVyZnVyYW50ZSIpLAogICAgKQogICAg
REM Zm9yIHBhZHJhbywgc3Vic3RpdHVpY2FvIGluIHJlZ3JhczoKICAgICAgICB2YWxvciA9IHJl
REM LnN1YihwYWRyYW8sIHN1YnN0aXR1aWNhbywgdmFsb3IpCiAgICByZXR1cm4gdmFsb3IKCgpk
REM ZWYgcGFyZWNlX3Jlc2lkdW9faW5nbGVzX3Jlc3VsdGFkbyhvcmlnaW5hbCwgcmVzdWx0YWRv
REM LCB0aXBvX2VudHJhZGEpOgogICAgIiIiRGV0ZWN0YSBpbmdsw6pzIHJlc2lkdWFsIG1lc21v
REM IHF1YW5kbyBvIEdvb2dsZSB0cmFkdXppdSBhcGVuYXMgcGFydGUuCgogICAgQSByb3RpbmEg
REM Y29udGludWEgcmVzdHJpdGEgYSB0aXBvcyB0ZXh0dWFpcyB0cmFkdXrDrXZlaXMuIFBhcmEg
REM cmVkdXppciBmYWxzb3MKICAgIHBvc2l0aXZvcywgZXhpZ2UgZXZpZMOqbmNpYSBkZSBpbmds
REM w6pzIG5hIGZvbnRlIGUgcHJvY3VyYSBubyByZXN1bHRhZG8gcGFsYXZyYXMKICAgIGluZ2xl
REM c2FzIHF1ZSBzb2JyZXZpdmVyYW0uIFVtYSBwYWxhdnJhIGluZ2xlc2EgcmVzaWR1YWwgasOh
REM IMOpIHN1ZmljaWVudGUgcXVhbmRvCiAgICBlbGEgw6kgZGlzdGludGl2YTsgcGFyYSBwYWxh
REM dnJhcyBlc3RydXR1cmFpcywgYmFzdGEgdW1hIG9jb3Jyw6puY2lhIGVtIHVtYSBmcmFzZQog
REM ICAgY3VqYSBmb250ZSB0YW1iw6ltIHRlbmhhIGV2aWTDqm5jaWEgaW5nbGVzYS4KICAgICIi
REM IgogICAgaWYgbm90IG9yaWdpbmFsIG9yIG5vdCByZXN1bHRhZG8gb3Igb3JpZ2luYWwgPT0g
REM cmVzdWx0YWRvOgogICAgICAgIHJldHVybiBGYWxzZQogICAgaWYgdGlwb19lbnRyYWRhIG5v
REM dCBpbiAodSJkaWFsb2dvIiwgdSJyZW5weV9uYXRpdm9fZGlhbG9nbyIsIHUicmVucHlfbmF0
REM aXZvX3N0cmluZyIsIHUibmFycmF0aXZhIiwgdSJ1aSIsIHUicG9lbWFfY29ycG8iLCB1InBv
REM ZW1hX3BhbGF2cmEiLCB1InBvZW1hX3BhbGF2cmFfdHh0IiwgdSJub21lX2dydXBvIiwgdSJ2
REM YXJpYXZlbF90ZXh0byIsIHUidXJsX3Zpc2l2ZWwiKToKICAgICAgICByZXR1cm4gRmFsc2UK
REM ICAgIGlmIHJlc3VsdGFkbyBpbiBFUVVBTF9UUkFOU0xBVElPTl9QUk9URUNURUQ6CiAgICAg
REM ICAgcmV0dXJuIEZhbHNlCiAgICBmb250ZSA9IF90ZXh0b19zZW1fcnVpZG9fcGFyYV9kZXRl
REM Y3Rvcl9pbmdsZXMob3JpZ2luYWwpLnN0cmlwKCkKICAgIHNhaWRhID0gX3RleHRvX3NlbV9y
REM dWlkb19wYXJhX2RldGVjdG9yX2luZ2xlcyhyZXN1bHRhZG8pLnN0cmlwKCkKICAgIGlmICJf
REM IiBpbiBzYWlkYSBhbmQgbm90IHJlLnNlYXJjaChyIlxccyIsIHNhaWRhKToKICAgICAgICBy
REM ZXR1cm4gRmFsc2UKICAgIGlmIHJlLm1hdGNoKHIiXig/OmhhKD86aGEpK3xoKD86bW18bSkr
REM fGEraCt8ZysoPzpscCkrKVxcVyokIiwgc2FpZGEubG93ZXIoKSk6CiAgICAgICAgcmV0dXJu
REM IEZhbHNlCgogICAgIyBOb21lcyBwcmluY2lwYWlzIHByb3RlZ2lkb3MgZ2xvYmFsbWVudGUg
REM bnVuY2EgY29udGFtIGNvbW8gaW5nbMOqcyByZXNpZHVhbC4KICAgIG5vbWVzX3Byb3RlZ2lk
REM b3MgPSB7dSJzYXlvcmkiLCB1Im1vbmlrYSIsIHUibmF0c3VraSIsIHUieXVyaSJ9CiAgICBp
REM ZiB1ImxldCdzIHBsYXkiIGluIHNhaWRhLmxvd2VyKCk6CiAgICAgICAgIyBSw7N0dWxvIGRl
REM bGliZXJhZG8gZG8gbW9kOyBhIE9ww6fDo28gNCBvIGFkYXB0YSBwYXJhICJNb2RvIGNvbSBD
REM ZW5zdXJhIi4KICAgICAgICByZXR1cm4gRmFsc2UKCiAgICBwYWxhdnJhc19mb250ZSA9IHJl
REM LmZpbmRhbGwociJbQS1aYS16w4Atw79dKyg/Olsn4oCZXVtBLVphLXrDgC3Dv10rKT8iLCBm
REM b250ZS5sb3dlcigpKQogICAgcGFsYXZyYXNfc2FpZGEgPSByZS5maW5kYWxsKHIiW0EtWmEt
REM esOALcO/XSsoPzpbJ+KAmV1bQS1aYS16w4Atw79dKyk/Iiwgc2FpZGEubG93ZXIoKSkKICAg
REM IHBhbGF2cmFzX3NhaWRhX3NlbV9ub21lcyA9IFtwIGZvciBwIGluIHBhbGF2cmFzX3NhaWRh
REM IGlmIHAgbm90IGluIG5vbWVzX3Byb3RlZ2lkb3NdCiAgICBpZiBub3QgcGFsYXZyYXNfc2Fp
REM ZGFfc2VtX25vbWVzOgogICAgICAgIHJldHVybiBGYWxzZQoKICAgICMgVGVybW9zIHJlc2lk
REM dWFpcyBpbmVxdcOtdm9jb3Mgc8OjbyBzdWZpY2llbnRlcyBtZXNtbyBxdWFuZG8gYSBmb250
REM ZQogICAgIyBqw6EgZXN0YXZhIHBhcmNpYWxtZW50ZSBlbSBQVC1CUiBvdSBxdWFuZG8gZXN0
REM w6EgY29ycm9tcGlkYS9mcmFnbWVudGFkYS4KICAgICMgSXNzbyBmZWNoYSBhIGxhY3VuYSBx
REM dWUgcGVybWl0aXUgYGZlZWRiYWNrYCBlIGBtb2RkZXJgIHBhc3NhcmVtIHF1YW5kbwogICAg
REM IyBvIHByw7NwcmlvIG1hcGEgasOhIHRyYXppYSBvIHJlc3RhbnRlIGRhIGZyYXNlIGVtIHBv
REM cnR1Z3XDqnMuCiAgICBpZiBhbnkocCBpbiBSRVNJRFVBTF9FTkdMSVNIX1NUUk9ORyBmb3Ig
REM cCBpbiBwYWxhdnJhc19zYWlkYV9zZW1fbm9tZXMpOgogICAgICAgIHJldHVybiBUcnVlCgog
REM ICAgaWYgbGVuKHBhbGF2cmFzX2ZvbnRlKSA8IDI6CiAgICAgICAgcmV0dXJuIEZhbHNlCgog
REM ICAgIyBBIGZvbnRlIHByZWNpc2EgcGFyZWNlciByZWFsbWVudGUgaW5nbGVzYS4KICAgIGRp
REM c3RfZm9udGUgPSBzdW0oMSBmb3IgcCBpbiBwYWxhdnJhc19mb250ZSBpZiBwIGluIEVOR0xJ
REM U0hfUkVUUllfRElTVElOQ1RJVkUpCiAgICBjb211bnNfZm9udGUgPSBzdW0oMSBmb3IgcCBp
REM biBwYWxhdnJhc19mb250ZSBpZiBwIGluIEVOR0xJU0hfUkVUUllfQ09NTU9OIG9yIHAgaW4g
REM UkVTSURVQUxfRU5HTElTSF9XT1JEUykKICAgIHRlbV9jb250cmFjYW9fZm9udGUgPSBhbnko
REM cCBpbiBFTkdMSVNIX1JFVFJZX0NPTlRSQUNUSU9OUyBmb3IgcCBpbiBwYWxhdnJhc19mb250
REM ZSkKICAgIGZvbnRlX2luZ2xlcyA9IChkaXN0X2ZvbnRlID49IDEgb3IgY29tdW5zX2ZvbnRl
REM ID49IDIgb3IgdGVtX2NvbnRyYWNhb19mb250ZSkKICAgIGlmIG5vdCBmb250ZV9pbmdsZXM6
REM CiAgICAgICAgcmV0dXJuIEZhbHNlCgogICAgIyBRdWFscXVlciBjb250cmHDp8OjbyBpbmds
REM ZXNhIHNvYnJldml2ZW50ZSDDqSBzaW5hbCBmb3J0ZS4KICAgIGlmIGFueShwIGluIEVOR0xJ
REM U0hfUkVUUllfQ09OVFJBQ1RJT05TIGZvciBwIGluIHBhbGF2cmFzX3NhaWRhX3NlbV9ub21l
REM cyk6CiAgICAgICAgcmV0dXJuIFRydWUKCiAgICAjIFRlcm1vcyBmb3J0ZXMgcHJlY2lzYW0g
REM dGVyIHNvYnJldml2aWRvIGxpdGVyYWxtZW50ZSBkYSBwcsOzcHJpYSBmb250ZS4KICAgICMg
REM SXNzbyBldml0YSBtYXJjYXIgcGFsYXZyYXMgcG9ydHVndWVzYXMgcXVlIGFwZW5hcyBjb2lu
REM Y2lkZW0gY29tIG8gaW5nbMOqcy4KICAgIGZvbnRlX3NldCA9IHNldChwYWxhdnJhc19mb250
REM ZSkKICAgIGZvcnRlcyA9IFJFU0lEVUFMX0VOR0xJU0hfU1RST05HIHwgRU5HTElTSF9SRVRS
REM WV9ESVNUSU5DVElWRQogICAgaWYgYW55KChwIGluIGZvbnRlX3NldCBhbmQgcCBpbiBmb3J0
REM ZXMgYW5kIHAgbm90IGluIFJFU0lEVUFMX0VOR0xJU0hfQU1CSUdVT1VTKQogICAgICAgICAg
REM IGZvciBwIGluIHBhbGF2cmFzX3NhaWRhX3NlbV9ub21lcyk6CiAgICAgICAgcmV0dXJuIFRy
REM dWUKCiAgICAjIFVtIHRlcm1vIGluZ2zDqnMgZGlzdGluZ3XDrXZlbCBzb2JyZXZpdmVudGUg
REM Y29udGludWEgc2VuZG8gc3VmaWNpZW50ZS4KICAgIGlmIGFueShwIGluIEVOR0xJU0hfUkVU
REM UllfRElTVElOQ1RJVkUgZm9yIHAgaW4gcGFsYXZyYXNfc2FpZGFfc2VtX25vbWVzKToKICAg
REM ICAgICByZXR1cm4gVHJ1ZQoKICAgICMgVm9jYWJ1bMOhcmlvIGVzdHJ1dHVyYWwvY29tdW0u
REM IElzc28gY29icmUgcmVzdWx0YWRvcyBow61icmlkb3MgZG8gdGlwbwogICAgIyAiRXUgcmVh
REM bGx5IGdvc3RvIiwgIkVsYSBzYWlkIGlzc28iIG91ICJWb2PDqiBjYW4gZmF6ZXIiLgogICAg
REM cmVzaWR1YWlzX2NvbXVucyA9IHsKICAgICAgICB1ImkiLCB1InlvdSIsIHUiaGUiLCB1InNo
REM ZSIsIHUiaXQiLCB1IndlIiwgdSJ0aGV5IiwgdSJteSIsIHUieW91ciIsCiAgICAgICAgdSJ0
REM aGUiLCB1ImFuZCIsIHUiYnV0IiwgdSJvciIsIHUid2l0aCIsIHUid2l0aG91dCIsIHUidG8i
REM LCB1Im9mIiwKICAgICAgICB1ImlzIiwgdSJhcmUiLCB1IndhcyIsIHUid2VyZSIsIHUiYW0i
REM LCB1InRoaXMiLCB1InRoYXQiLCB1Im5vdCIsCiAgICAgICAgdSJ5ZXMiLCB1ImJlIiwgdSJi
REM ZWVuIiwgdSJiZWluZyIsIHUiZG8iLCB1ImRpZCIsIHUiZG9lcyIsIHUid2lsbCIsCiAgICAg
REM ICAgdSJ3b3VsZCIsIHUiY291bGQiLCB1InNob3VsZCIsIHUiaGF2ZSIsIHUiaGFzIiwgdSJo
REM YWQiLCB1ImNhbiIsCiAgICAgICAgdSJjYW5ub3QiLCB1ImhlcmUiLCB1InRoZXJlIiwgdSJl
REM dmVyeW9uZSIsIHUic29tZW9uZSIsIHUic29tZXRoaW5nIiwKICAgICAgICB1InBsZWFzZSIs
REM IHUic29ycnkiLCB1InRoYW5rcyIsIHUid2hhdCIsIHUid2h5IiwgdSJ3aGVyZSIsIHUid2hl
REM biIsCiAgICAgICAgdSJ3aG8iLCB1ImhvdyIsCiAgICB9CiAgICBjb211bnNfc2FpZGEgPSBz
REM dW0oMSBmb3IgcCBpbiBwYWxhdnJhc19zYWlkYV9zZW1fbm9tZXMgaWYgcCBub3QgaW4gUE9S
REM VFVHVUVTX0FMVE9fU0lOQUwgYW5kIChwIGluIHJlc2lkdWFpc19jb211bnMgb3IgcCBpbiBS
REM RVNJRFVBTF9FTkdMSVNIX1dPUkRTIG9yIHAgaW4gUkVTSURVQUxfRU5HTElTSF9TVFJPTkcp
REM KQogICAgIyBVbWEgw7puaWNhIHBhbGF2cmEgY29tdW0gcG9kZSBzZXIgbm9tZSBwcsOzcHJp
REM bywgVVJMIGZyYWdtZW50YWRhIG91CiAgICAjIGNvaW5jaWTDqm5jaWEgbGV4aWNhbC4gUGFy
REM YSByZXRlbnRhdGl2YSBhdXRvbcOhdGljYSBleGlnaW1vcyBkdWFzIGV2aWTDqm5jaWFzCiAg
REM ICAjIGVzdHJ1dHVyYWlzOyBwYWxhdnJhcyBkaXN0aW50aXZhcy9jb250cmHDp8O1ZXMgY29u
REM dGludWFtIGRpc3BhcmFuZG8gc296aW5oYXMuCiAgICBpZiBjb211bnNfc2FpZGEgPj0gMjoK
REM ICAgICAgICByZXR1cm4gVHJ1ZQoKICAgICMgw5psdGltYSBwcm90ZcOnw6NvOiBzZSB1bWEg
REM cGFsYXZyYSBjb20gcGVsbyBtZW5vcyA0IGxldHJhcyBwZXJtYW5lY2V1CiAgICAjIGV4YXRh
REM bWVudGUgaWd1YWwgw6AgZm9udGUgZSBlc3RpdmVyIG5vIHZvY2FidWzDoXJpbyByZXNpZHVh
REM bCwgcmVwcm9jZXNzYS4KICAgIGZvbnRlX3NldCA9IHNldChwYWxhdnJhc19mb250ZSkKICAg
REM IGZvciBwIGluIHBhbGF2cmFzX3NhaWRhX3NlbV9ub21lczoKICAgICAgICBpZiBsZW4ocCkg
REM Pj0gNCBhbmQgcCBpbiBmb250ZV9zZXQgYW5kIHAgaW4gUkVTSURVQUxfRU5HTElTSF9XT1JE
REM UzoKICAgICAgICAgICAgcmV0dXJuIFRydWUKICAgIHJldHVybiBGYWxzZQoKCmRlZiBwYXJl
REM Y2Vfc29icmFfaW5nbGVzX2N1cnRvKHRleHRvKToKICAgICIiIkNvbXBhdGliaWxpZGFkZTog
REM bWFudMOpbSBvIGRldGVjdG9yIGFudGlnbyBkaXNwb27DrXZlbCBwYXJhIG8gcmVzdGFudGUg
REM ZG8gY8OzZGlnby4iIiIKICAgIGxpbXBvID0gcmUuc3ViKHIiW15BLVphLXpcc1wnLV0rIiwg
REM dSIgIiwgdGV4dG8gb3IgdSIiKS5sb3dlcigpCiAgICBwYWxhdnJhcyA9IFtwIGZvciBwIGlu
REM IHJlLnNwbGl0KHIiXHMrIiwgbGltcG8pIGlmIHBdCiAgICBpZiBub3QgcGFsYXZyYXMgb3Ig
REM bGVuKHBhbGF2cmFzKSA+IDE0OgogICAgICAgIHJldHVybiBGYWxzZQogICAgZGlzdGludGl2
REM YXMgPSBzdW0oMSBmb3IgcCBpbiBwYWxhdnJhcyBpZiBwIGluIEVOR0xJU0hfUkVUUllfRElT
REM VElOQ1RJVkUpCiAgICBjb211bnMgPSBzdW0oMSBmb3IgcCBpbiBwYWxhdnJhcyBpZiBwIGlu
REM IEVOR0xJU0hfUkVUUllfQ09NTU9OKQogICAgaWYgbGVuKHBhbGF2cmFzKSA9PSAxIGFuZCBw
REM YWxhdnJhc1swXSBpbiAodSJodWgiLCB1InNvcnJ5IiwgdSJwbGVhc2UiKToKICAgICAgICBy
REM ZXR1cm4gVHJ1ZQogICAgcmV0dXJuIGRpc3RpbnRpdmFzID49IDEgYW5kIChsZW4ocGFsYXZy
REM YXMpID49IDIgb3IgY29tdW5zID49IDEpCgoKZGVmIG5vcm1hbGl6YXJfZXNwYWNvc19wb3Nf
REM cG9udHVhY2FvX2dvb2dsZShvcmlnaW5hbCwgdHJhZHVjYW8pOgogICAgIiIiQ29ycmlnZSBw
REM ZXJkYSBkZSBlc3Bhw6dvIGFww7NzIHBvbnR1YcOnw6NvIHNlbSByZWVzY3JldmVyIGEgdHJh
REM ZHXDp8Ojby4KCiAgICBBIGNvcnJlw6fDo28gc8OzIGF0dWEgcXVhbmRvIG8gdGV4dG8gb3Jp
REM Z2luYWwgcG9zc3XDrWEgZXNwYcOnb3MgYXDDs3MgLiAhID8gb3UgOyA6CiAgICBlIGEgcmVz
REM cG9zdGEgZG8gR29vZ2xlIGp1bnRvdSBhIHBvbnR1YcOnw6NvIMOgIHBhbGF2cmEgc2VndWlu
REM dGUuIElzc28gdHJhdGEKICAgIGNhc29zIGNvbW8gYGNsYXJvLlNpbWAgLT4gYGNsYXJvLiBT
REM aW1gIHNlbSBtZXhlciBlbSBuw7ptZXJvcyBkZWNpbWFpcy4KICAgICIiIgogICAgaWYgbm90
REM IG9yaWdpbmFsIG9yIG5vdCB0cmFkdWNhbzoKICAgICAgICByZXR1cm4gdHJhZHVjYW8KICAg
REM IGxpbWl0ZXNfb3JpZyA9IHJlLmZpbmRhbGwociJbLiE/OzpdXHMrKD89W0EtWmEtesOALcO/
REM XSkiLCBvcmlnaW5hbCkKICAgIGZhbHRhbnRlcyA9IGxlbihsaW1pdGVzX29yaWcpCiAgICBp
REM ZiBmYWx0YW50ZXMgPD0gMDoKICAgICAgICByZXR1cm4gdHJhZHVjYW8KICAgIHBhZHJhbyA9
REM IHJlLmNvbXBpbGUociIoWy4hPzs6XSkoPz1bQS1aw4Atw51dKSIpCiAgICBkZWYgcmVwbCht
REM KToKICAgICAgICBub25sb2NhbCBmYWx0YW50ZXMKICAgICAgICBpZiBmYWx0YW50ZXMgPD0g
REM MDoKICAgICAgICAgICAgcmV0dXJuIG0uZ3JvdXAoMCkKICAgICAgICBmYWx0YW50ZXMgLT0g
REM MQogICAgICAgIHJldHVybiBtLmdyb3VwKDEpICsgdSIgIgogICAgcmV0dXJuIHBhZHJhby5z
REM dWIocmVwbCwgdHJhZHVjYW8pCgoKZGVmIGVudHJhZGFfZWhfY29uZmlnX25hbWVfZ2xvYmFs
REM KGVudHJhZGEpOgogICAgIiIiSWRlbnRpZmljYSBhIGRlZmluacOnw6NvIGdsb2JhbCBkbyBu
REM b21lIGRvIGpvZ28gc2VtIGJsb3F1ZWFyIG9wdGlvbnMucnB5IGludGVpcm8uIiIiCiAgICBp
REM ZiBub3QgaXNpbnN0YW5jZShlbnRyYWRhLCBkaWN0KToKICAgICAgICByZXR1cm4gRmFsc2UK
REM ICAgIGNvbnRleHRvID0gdGV4dG9fY29tcGF0aXZlbChlbnRyYWRhLmdldCh1ImNvbnRleHRv
REM IiksIHUiIikubG93ZXIoKQogICAgIyBPIGV4dHJhdG9yIHJlZ2lzdHJhIGNvbmZpZy5uYW1l
REM IG5vIGNvbnRleHRvIGRvIG1hcGEuCiAgICAjIEEgcmVncmEgdXNhIG8gY29udGV4dG8gcGFy
REM YSB0YW1iw6ltIHByb3RlZ2VyIG1hcGFzIGFudGlnb3MgasOhIGV4aXN0ZW50ZXMuCiAgICBy
REM ZXR1cm4gdSJjb25maWcubmFtZSIgaW4gY29udGV4dG8gYW5kICh1ImRlZmluZSIgaW4gY29u
REM dGV4dG8gb3IgdSJkZWZhdWx0IiBpbiBjb250ZXh0bykKCgoKZGVmIHRyYWR1emlyX3Bvcl9m
REM cmFnbWVudG9zX3Jlc2lkdWFsX2dvb2dsZShjbGllbnRlLCB0ZXh0bywgb3JpZ2VtLCBkZXN0
REM aW5vKToKICAgICIiIsOabHRpbW8gZmFsbGJhY2sgcGFyYSByZXNwb3N0YXMgcXVlIHZvbHRh
REM cmFtIGVtIGluZ2zDqnMvcmVzcG9zdGEgdmF6aWEuCgogICAgTsOjbyBhbHRlcmEgbyBtb3Rv
REM ciBwcmluY2lwYWw6IGNvbnRpbnVhIHVzYW5kbyBvIG1lc21vIGNsaWVudGUgUlBDIGUgYSBt
REM ZXNtYQogICAgc2Vzc8Ojby4gQSBkaWZlcmVuw6dhIMOpIHF1ZSBvIHRleHRvIMOpIGRpdmlk
REM aWRvIGVtIGZyYWdtZW50b3MgcHJlc2VydmFuZG8KICAgIHF1ZWJyYXMsIFVSTHMsIHRhZ3Mg
REM ZSB0b2tlbnMgdMOpY25pY29zLiBJc3NvIGFqdWRhIG8gR29vZ2xlIGEgdHJhZHV6aXIgdGV4
REM dG9zCiAgICBjdXJ0b3MvY3JlZGl0cy9zdHJpbmdzIHF1ZSBlbGUgb2Nhc2lvbmFsbWVudGUg
REM ZGV2b2x2ZSBpZMOqbnRpY29zIHF1YW5kbwogICAgZW52aWFkb3MgY29tbyB1bWEgw7puaWNh
REM IHVuaWRhZGUuCiAgICAiIiIKICAgIHRleHRvID0gdGV4dG9fY29tcGF0aXZlbCh0ZXh0bywg
REM dSIiKQogICAgaWYgbm90IHRleHRvLnN0cmlwKCk6CiAgICAgICAgcmV0dXJuIHRleHRvCgog
REM ICAgcGFydGVzID0gcmUuc3BsaXQocicoXHJcbnxcbnxcXG4pJywgdGV4dG8pCiAgICBzYWlk
REM YSA9IFtdCiAgICBhbHRlcm91ID0gRmFsc2UKICAgIGZvciBwYXJ0ZSBpbiBwYXJ0ZXM6CiAg
REM ICAgICAgaWYgcGFydGUgaW4gKHUiXHJcbiIsIHUiXG4iLCB1IlxcbiIpIG9yIG5vdCBwYXJ0
REM ZToKICAgICAgICAgICAgc2FpZGEuYXBwZW5kKHBhcnRlKQogICAgICAgICAgICBjb250aW51
REM ZQogICAgICAgICMgRGl2aWRlIHByaW1laXJvIHBvciBmcmFzZXMuIFBhcmEgc3RyaW5ncyBj
REM dXJ0YXMgcXVlIG8gUlBDIGRldm9sdmUKICAgICAgICAjIGludGVpcmFzIGVtIGluZ2zDqnMs
REM IGV4aXN0ZSB1bSBzZWd1bmRvIG7DrXZlbCBkZSBmcmFnbWVudGHDp8OjbyBwb3IKICAgICAg
REM ICAjIHbDrXJndWxhLzsvOi4gSXNzbyBldml0YSBxdWUgdW1hIGZyYXNlIGN1cnRhIGNvbW8g
REM Ik5vLCBjb250aW51ZSB3aGVyZQogICAgICAgICMgSSBsZWZ0IG9mZi4iIGZpcXVlIHByZXNh
REM IGVtIHJldHJpZXMgbWVzbW8gcXVhbmRvIG8gR29vZ2xlIHRyYWR1egogICAgICAgICMgY29y
REM cmV0YW1lbnRlIGNhZGEgc2VnbWVudG8gbWVub3IuIElkZW50aWZpY2Fkb3JlcyBlIGxpbmhh
REM cyBsb25nYXMKICAgICAgICAjIGNvbnRpbnVhbSBwcm90ZWdpZG9zIGNvbnRyYSBmcmFnbWVu
REM dGHDp8OjbyBhZ3Jlc3NpdmEuCiAgICAgICAgc2VudGVuY2FzID0gcmUuc3BsaXQocicoPzw9
REM Wy4hP10pXHMrKD89W0EtWmEtesOALcO/XSknLCBwYXJ0ZSkKICAgICAgICB1bmlkYWRlcyA9
REM IFtdCiAgICAgICAgZm9yIHNlbnRlbmNhIGluIHNlbnRlbmNhczoKICAgICAgICAgICAgaWYg
REM KGxlbihzZW50ZW5jYSkgPD0gMTgwIGFuZCByZS5zZWFyY2gocidbLDs6XVxzKycsIHNlbnRl
REM bmNhKQogICAgICAgICAgICAgICAgICAgIGFuZCBub3QgcmUuc2VhcmNoKHInaHR0cHM/Oi8v
REM fHd3d1wuJywgc2VudGVuY2EsIHJlLkkpKToKICAgICAgICAgICAgICAgIHBlZGFjb3MgPSBy
REM ZS5zcGxpdChyJyhbLDs6XVxzKyknLCBzZW50ZW5jYSkKICAgICAgICAgICAgICAgIGNvcnJl
REM bnRlID0gdScnCiAgICAgICAgICAgICAgICBmb3IgcGVkYWNvIGluIHBlZGFjb3M6CiAgICAg
REM ICAgICAgICAgICAgICAgaWYgbm90IHBlZGFjbzoKICAgICAgICAgICAgICAgICAgICAgICAg
REM Y29udGludWUKICAgICAgICAgICAgICAgICAgICBjb3JyZW50ZSArPSBwZWRhY28KICAgICAg
REM ICAgICAgICAgICAgICBpZiByZS5zZWFyY2gocidbLDs6XVxzKyQnLCBwZWRhY28pOgogICAg
REM ICAgICAgICAgICAgICAgICAgICB1bmlkYWRlcy5hcHBlbmQoY29ycmVudGUpCiAgICAgICAg
REM ICAgICAgICAgICAgICAgIGNvcnJlbnRlID0gdScnCiAgICAgICAgICAgICAgICBpZiBjb3Jy
REM ZW50ZToKICAgICAgICAgICAgICAgICAgICB1bmlkYWRlcy5hcHBlbmQoY29ycmVudGUpCiAg
REM ICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICB1bmlkYWRlcy5hcHBlbmQoc2VudGVu
REM Y2EpCiAgICAgICAgc3ViX3NhaWRhID0gW10KICAgICAgICBmb3IgZnJhZ21lbnRvIGluIHVu
REM aWRhZGVzOgogICAgICAgICAgICBpZiBub3QgZnJhZ21lbnRvIG9yIG5vdCByZS5zZWFyY2go
REM ciJbXlxXXGRfXSIsIGZyYWdtZW50bywgcmUuVU5JQ09ERSk6CiAgICAgICAgICAgICAgICBz
REM dWJfc2FpZGEuYXBwZW5kKGZyYWdtZW50bykKICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAg
REM ICAgICAgICAgIHByb3RlZ2lkbywgdG9rZW5zID0gcHJvdGVnZXJfdG9rZW5zX2dvb2dsZShm
REM cmFnbWVudG8pCiAgICAgICAgICAgIHJlc3VsdGFkbyA9IGNsaWVudGUudHJhZHV6aXIocHJv
REM dGVnaWRvLCB1ImVuIiwgZGVzdGlubykKICAgICAgICAgICAgdmFsaWRhcl90b2tlbnNfZ29v
REM Z2xlX3ByZXNlcnZhZG9zKHJlc3VsdGFkbywgdG9rZW5zKQogICAgICAgICAgICByZXN1bHRh
REM ZG8gPSBlc2NhcGFyX3BlcmNlbnR1YWlzX25vdm9zX2dvb2dsZShyZXN1bHRhZG8pCiAgICAg
REM ICAgICAgIHJlc3VsdGFkbyA9IHJlc3RhdXJhcl90b2tlbnNfZ29vZ2xlKHJlc3VsdGFkbywg
REM dG9rZW5zKQogICAgICAgICAgICBzdWJfc2FpZGEuYXBwZW5kKHJlc3VsdGFkbykKICAgICAg
REM ICAgICAgaWYgcmVzdWx0YWRvICE9IGZyYWdtZW50bzoKICAgICAgICAgICAgICAgIGFsdGVy
REM b3UgPSBUcnVlCiAgICAgICAgc2FpZGEuYXBwZW5kKHUiIi5qb2luKHN1Yl9zYWlkYSkpCiAg
REM ICByZXN1bHRhZG9fZmluYWwgPSB1IiIuam9pbihzYWlkYSkKICAgIGlmIG5vdCBhbHRlcm91
REM IG9yIHJlc3VsdGFkb19maW5hbCA9PSB0ZXh0bzoKICAgICAgICByZXR1cm4gTm9uZQogICAg
REM cmV0dXJuIHJlc3VsdGFkb19maW5hbAoKCmRlZiB0cmFkdXppcl90ZXh0b193b3JrZXIodGV4
REM dG8sIG9yaWdlbSwgZGVzdGlubywgcG9vbCwgaW5kaWNlLCB0b3RhbCwgbG9nLCByZWwsIHRp
REM cG9fZW50cmFkYT1Ob25lLCBzY2hlZHVsZXJfaW5kZXg9Tm9uZSk6CiAgICB0ZXh0byA9IHRl
REM eHRvX2NvbXBhdGl2ZWwodGV4dG8sIHUiIikKICAgIG9yaWdlbSA9IHRleHRvX2NvbXBhdGl2
REM ZWwob3JpZ2VtLCB1ImF1dG8iKSBvciB1ImF1dG8iCiAgICBkZXN0aW5vID0gdGV4dG9fY29t
REM cGF0aXZlbChkZXN0aW5vLCB1InB0LUJSIikgb3IgdSJwdC1CUiIKICAgIHJlbCA9IHRleHRv
REM X2NvbXBhdGl2ZWwocmVsLCB1IiIpCiAgICB0aXBvX2VudHJhZGEgPSB0ZXh0b19jb21wYXRp
REM dmVsKHRpcG9fZW50cmFkYSwgdSIiKQogICAgY29ycmVjYW8sIHJlZ3JhX2lkID0gYXBsaWNh
REM cl9jb3JyZWNhb19pbmRpdmlkdWFsX2dvb2dsZSh0ZXh0bywgcmVsLCB0aXBvX2VudHJhZGEs
REM IGRlc3Rpbm8sIGxvZykKICAgIGlmIGNvcnJlY2FvIGlzIG5vdCBOb25lOgogICAgICAgIHRy
REM eToKICAgICAgICAgICAgdmFsaWRhcl9pbnRlZ3JpZGFkZV90cmFkdWNhb19nb29nbGUodGV4
REM dG8sIGNvcnJlY2FvKQogICAgICAgICAgICByZXR1cm4gaW5kaWNlLCBjb3JyZWNhbywgTm9u
REM ZQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAgICAgICAgICByZXR1cm4g
REM aW5kaWNlLCBOb25lLCBHb29nbGVUcmFuc2xhdGVWYWxpZGF0aW9uRXJyb3IoCiAgICAgICAg
REM ICAgICAgICB1InJlZ3JhIGluZGl2aWR1YWwgezB9IGdlcm91IHJlc3VsdGFkbyBpbnbDoWxp
REM ZG86IHsxfSIuZm9ybWF0KHJlZ3JhX2lkLCBleGMpCiAgICAgICAgICAgICkKCiAgICAjIENy
REM w6lkaXRvcyBzw6NvIHRyYXRhZG9zIGVtIG7DrXZlbCBlc3RydXR1cmFsOiB0cmFkdXppbW9z
REM IHNvbWVudGUgY2F0ZWdvcmlhcwogICAgIy9yb2xlcyBlIHByZXNlcnZhbW9zIG5vbWVzLCBh
REM cnRpc3RhcywgdMOtdHVsb3MgZSByZWN1cnNvcy4gSXNzbyBlbGltaW5hIGFzCiAgICAjIHJl
REM dGVudGF0aXZhcyBhcnRpZmljaWFpcyBjYXVzYWRhcyBwZWxvIGRldGVjdG9yIGRlIGluZ2zD
REM qnMgcmVzaWR1YWwuCiAgICBpZiBwYXJlY2VfYmxvY29fY3JlZGl0b3NfZ29vZ2xlKHRleHRv
REM LCByZWwsIHRpcG9fZW50cmFkYSk6CiAgICAgICAgYmFzZV9pbmRleF9jcmVkaXRvID0gc2No
REM ZWR1bGVyX2luZGV4IGlmIHNjaGVkdWxlcl9pbmRleCBpcyBub3QgTm9uZSBlbHNlIGluZGlj
REM ZQogICAgICAgIHRyeToKICAgICAgICAgICAgY2xpZW50ZV9jcmVkaXRvID0gcG9vbFtiYXNl
REM X2luZGV4X2NyZWRpdG8gJSBtYXgoMSwgbGVuKHBvb2wpKV0KICAgICAgICAgICAgcmVzdWx0
REM YWRvX2NyZWRpdG8gPSB0cmFkdXppcl9ibG9jb19jcmVkaXRvc19nb29nbGUoY2xpZW50ZV9j
REM cmVkaXRvLCB0ZXh0bywgb3JpZ2VtLCBkZXN0aW5vKQogICAgICAgICAgICBpZiByZXN1bHRh
REM ZG9fY3JlZGl0byBpcyBub3QgTm9uZToKICAgICAgICAgICAgICAgIHJldHVybiBpbmRpY2Us
REM IHJlc3VsdGFkb19jcmVkaXRvLCBOb25lCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBl
REM eGM6CiAgICAgICAgICAgIGlmIGxvZzoKICAgICAgICAgICAgICAgIGxvZy5lcnJvKHUiRmFs
REM aGEgYW8gcHJvY2Vzc2FyIGJsb2NvIGRlIGNyw6lkaXRvcyB7MH0sIHRleHRvIHsxfS97Mn06
REM IHszfSIuZm9ybWF0KHJlbCwgaW5kaWNlICsgMSwgdG90YWwsIGV4YykpCiAgICAgICAgICAg
REM IHJldHVybiBpbmRpY2UsIE5vbmUsIGV4YwoKICAgICMgUXVhbmRvIGEgZm9udGUgcGFyZWNl
REM IGluZ2zDqnMgZSBvIHVzdcOhcmlvIHBlZGl1IGRldGVjw6fDo28gYXV0b23DoXRpY2EsCiAg
REM ICAjIGVudmlhbW9zIGV4cGxpY2l0YW1lbnRlIGBlbmAuIElzc28gZWxpbWluYSBvIGN1c3Rv
REM IGRlIHJlZGV0ZWPDp8OjbyBkbyBHb29nbGUKICAgICMgZSBtZWxob3JhIGJhc3RhbnRlIGZy
REM YWdtZW50b3MgcG/DqXRpY29zIGN1cnRvcy4KICAgIG9yaWdlbV9nb29nbGUgPSBvcmlnZW0K
REM ICAgIGlmIG9yaWdlbSA9PSB1ImF1dG8iIGFuZCBkZXN0aW5vLmxvd2VyKCkuc3RhcnRzd2l0
REM aCh1InB0IikgYW5kIGZvbnRlX3BhcmVjZV9pbmdsZXNhX2dvb2dsZSh0ZXh0byk6CiAgICAg
REM ICAgb3JpZ2VtX2dvb2dsZSA9IHUiZW4iCgogICAgYmFzZV9pbmRleCA9IHNjaGVkdWxlcl9p
REM bmRleCBpZiBzY2hlZHVsZXJfaW5kZXggaXMgbm90IE5vbmUgZWxzZSBpbmRpY2UKICAgIHVs
REM dGltbyA9IE5vbmUKICAgIG1lbGhvcmVzID0gW10KICAgIHRlbnRhdGl2YXNfcHJpbmNpcGFp
REM cyA9IG1heCgxLCBHT09HTEVfUkVUUklFUykKICAgIGZvciB0ZW50YXRpdmEgaW4gcmFuZ2Uo
REM dGVudGF0aXZhc19wcmluY2lwYWlzKToKICAgICAgICBwb3MgPSAoYmFzZV9pbmRleCArIHRl
REM bnRhdGl2YSkgJSBtYXgoMSwgbGVuKHBvb2wpKQogICAgICAgIGNsaWVudGUgPSBwb29sW3Bv
REM c10KICAgICAgICBwcm90ZWdpZG8sIHRva2VucyA9IHByb3RlZ2VyX3Rva2Vuc19nb29nbGUo
REM dGV4dG8pCiAgICAgICAgdHJ5OgogICAgICAgICAgICByZXN1bHRhZG8gPSBjbGllbnRlLnRy
REM YWR1emlyKHByb3RlZ2lkbywgb3JpZ2VtX2dvb2dsZSwgZGVzdGlubykKICAgICAgICAgICAg
REM dmFsaWRhcl90b2tlbnNfZ29vZ2xlX3ByZXNlcnZhZG9zKHJlc3VsdGFkbywgdG9rZW5zKQog
REM ICAgICAgICAgICByZXN1bHRhZG8gPSBlc2NhcGFyX3BlcmNlbnR1YWlzX25vdm9zX2dvb2ds
REM ZShyZXN1bHRhZG8pCiAgICAgICAgICAgIHJlc3VsdGFkbyA9IHJlc3RhdXJhcl90b2tlbnNf
REM Z29vZ2xlKHJlc3VsdGFkbywgdG9rZW5zKQogICAgICAgICAgICByZXN1bHRhZG8gPSBub3Jt
REM YWxpemFyX2VzcGFjb3NfcG9zX3BvbnR1YWNhb19nb29nbGUodGV4dG8sIHJlc3VsdGFkbykK
REM ICAgICAgICAgICAgaWYgZGVzdGluby5sb3dlcigpLnN0YXJ0c3dpdGgodSJwdCIpOgogICAg
REM ICAgICAgICAgICAgcmVzdWx0YWRvID0gbm9ybWFsaXphcl90ZXJtb3NfaW5nbGVzX3Jlc2lk
REM dWFpc19wdGJyKHJlc3VsdGFkbykKCiAgICAgICAgICAgICMgVW1hIHNlZ3VuZGEgY2FtYWRh
REM IMOpIGZlaXRhIFNPTUVOVEUgcXVhbmRvIGjDoSBldmlkw6puY2lhIGRlIGluZ2zDqnMgcmVz
REM aWR1YWwuCiAgICAgICAgICAgICMgRWxhIHVzYSBvdXRybyB3b3JrZXIvY2xpZW50ZSBlIG7D
REM o28gcmVpbmljaWEgdW1hIGNhc2NhdGEgZGUgMjAgdGVudGF0aXZhcy4KICAgICAgICAgICAg
REM cmVzaWR1YWwgPSBGYWxzZQogICAgICAgICAgICBpZiBkZXN0aW5vLmxvd2VyKCkuc3RhcnRz
REM d2l0aCh1InB0Iik6CiAgICAgICAgICAgICAgICBpZiByZXN1bHRhZG8gPT0gdGV4dG86CiAg
REM ICAgICAgICAgICAgICAgICAgcmVzaWR1YWwgPSAob3JpZ2VtX2dvb2dsZSA9PSB1ImVuIiBh
REM bmQgZGV2ZV9mb3JjYXJfcmV0ZW50YXRpdmFfZGlhbG9nbyh0ZXh0bykgaWYgdGlwb19lbnRy
REM YWRhIGluICh1ImRpYWxvZ28iLHUicmVucHlfbmF0aXZvX2RpYWxvZ28iKSBlbHNlCiAgICAg
REM ICAgICAgICAgICAgICAgICAgICAgICAgICAgb3JpZ2VtX2dvb2dsZSA9PSB1ImVuIiBhbmQg
REM ZGV2ZV9mb3JjYXJfcmV0ZW50YXRpdmFfaWd1YWwodGV4dG8pKQogICAgICAgICAgICAgICAg
REM ZWxzZToKICAgICAgICAgICAgICAgICAgICByZXNpZHVhbCA9IHBhcmVjZV9yZXNpZHVvX2lu
REM Z2xlc19yZXN1bHRhZG8odGV4dG8sIHJlc3VsdGFkbywgdGlwb19lbnRyYWRhKQoKICAgICAg
REM ICAgICAgaWYgbm90IHJlc2lkdWFsOgogICAgICAgICAgICAgICAgdmFsaWRhcl9yZXN1bHRh
REM ZG9fdHJhZHVjYW9fZ29vZ2xlKHRleHRvLCByZXN1bHRhZG8sIHRpcG9fZW50cmFkYSwgb3Jp
REM Z2VtX2dvb2dsZSwgZGVzdGlubykKICAgICAgICAgICAgICAgIHJldHVybiBpbmRpY2UsIHJl
REM c3VsdGFkbywgTm9uZQoKICAgICAgICAgICAgbWVsaG9yZXMuYXBwZW5kKHJlc3VsdGFkbykK
REM ICAgICAgICAgICAgIyBGYXN0LXBhdGggcGFyYSBzdHJpbmdzIGN1cnRhcyBxdWUgbyBSUEMg
REM ZGV2b2x2ZXUgZW0gaW5nbMOqczogZW0gdmV6CiAgICAgICAgICAgICMgZGUgcmVwZXRpciBh
REM IG1lc21hIGZyYXNlIDMtNCB2ZXplcywgdGVudGEgaW1lZGlhdGFtZW50ZSBvIGZhbGxiYWNr
REM CiAgICAgICAgICAgICMgcG9yIGZyYWdtZW50b3MuIElzc28gcmVkdXogbXVpdG8gbyBjdXN0
REM byBkZSBjcsOpZGl0b3Mvc3BsYXNoL1VJIGN1cnRvcy4KICAgICAgICAgICAgaWYgKGRlc3Rp
REM bm8ubG93ZXIoKS5zdGFydHN3aXRoKHUicHQiKSBhbmQgbGVuKHRleHRvKSA8PSAxODAgYW5k
REM CiAgICAgICAgICAgICAgICAgICAgcmUuc2VhcmNoKHInWyw7Ol1ccysnLCB0ZXh0bykgYW5k
REM CiAgICAgICAgICAgICAgICAgICAgbm90IHJlLnNlYXJjaChyJ2h0dHBzPzovL3x3d3dcLics
REM IHRleHRvLCByZS5JKSk6CiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAg
REM ICAgcmVwYXJhZG9fcmFwaWRvPXRyYWR1emlyX3Bvcl9mcmFnbWVudG9zX3Jlc2lkdWFsX2dv
REM b2dsZShjbGllbnRlLCB0ZXh0bywgb3JpZ2VtX2dvb2dsZSwgZGVzdGlubykKICAgICAgICAg
REM ICAgICAgICAgICBpZiByZXBhcmFkb19yYXBpZG8gaXMgbm90IE5vbmU6CiAgICAgICAgICAg
REM ICAgICAgICAgICAgIHJlcGFyYWRvX3JhcGlkbz1ub3JtYWxpemFyX2VzcGFjb3NfcG9zX3Bv
REM bnR1YWNhb19nb29nbGUodGV4dG8scmVwYXJhZG9fcmFwaWRvKQogICAgICAgICAgICAgICAg
REM ICAgICAgICByZXBhcmFkb19yYXBpZG89bm9ybWFsaXphcl90ZXJtb3NfaW5nbGVzX3Jlc2lk
REM dWFpc19wdGJyKHJlcGFyYWRvX3JhcGlkbykKICAgICAgICAgICAgICAgICAgICAgICAgdmFs
REM aWRhcl9yZXN1bHRhZG9fdHJhZHVjYW9fZ29vZ2xlKHRleHRvLHJlcGFyYWRvX3JhcGlkbyx0
REM aXBvX2VudHJhZGEsb3JpZ2VtX2dvb2dsZSxkZXN0aW5vKQogICAgICAgICAgICAgICAgICAg
REM ICAgICByZXR1cm4gaW5kaWNlLHJlcGFyYWRvX3JhcGlkbyxOb25lCiAgICAgICAgICAgICAg
REM ICBleGNlcHQgRXhjZXB0aW9uIGFzIGZhc3RfZXhjOgogICAgICAgICAgICAgICAgICAgIHVs
REM dGltbz1mYXN0X2V4YwogICAgICAgICAgICBsb2cuYXZpc28odSJSZXN1bHRhZG8gY29tIGlu
REM Z2zDqnMgcmVzaWR1YWwgZW0gezB9LCB0ZXh0byB7MX0vezJ9OyB0ZW50YW5kbyBHb29nbGUg
REM VHJhbnNsYXRlIFdlYiBub3ZhbWVudGUgY29tIG91dHJhIHNlc3PDo28uIi5mb3JtYXQocmVs
REM LCBpbmRpY2UgKyAxLCB0b3RhbCkpCiAgICAgICAgICAgIGZvciByZXRyeV9uIGluIHJhbmdl
REM KEdPT0dMRV9SRVNJRFVBTF9SRVRSSUVTKToKICAgICAgICAgICAgICAgIGNsaWVudGVfcmV0
REM cnkgPSBwb29sWyhiYXNlX2luZGV4ICsgdGVudGF0aXZhICsgcmV0cnlfbiArIDEpICUgbWF4
REM KDEsIGxlbihwb29sKSldCiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAg
REM ICAgcmV0cnlfcHJvdGVnaWRvLCByZXRyeV90b2tlbnMgPSBwcm90ZWdlcl90b2tlbnNfZ29v
REM Z2xlKHRleHRvKQogICAgICAgICAgICAgICAgICAgIHJldHJ5X2JydXRvID0gY2xpZW50ZV9y
REM ZXRyeS50cmFkdXppcihyZXRyeV9wcm90ZWdpZG8sIHUiZW4iLCBkZXN0aW5vKQogICAgICAg
REM ICAgICAgICAgICAgIHZhbGlkYXJfdG9rZW5zX2dvb2dsZV9wcmVzZXJ2YWRvcyhyZXRyeV9i
REM cnV0bywgcmV0cnlfdG9rZW5zKQogICAgICAgICAgICAgICAgICAgIHJldHJ5X3Jlc3VsdGFk
REM byA9IHJlc3RhdXJhcl90b2tlbnNfZ29vZ2xlKGVzY2FwYXJfcGVyY2VudHVhaXNfbm92b3Nf
REM Z29vZ2xlKHJldHJ5X2JydXRvKSwgcmV0cnlfdG9rZW5zKQogICAgICAgICAgICAgICAgICAg
REM IHJldHJ5X3Jlc3VsdGFkbyA9IG5vcm1hbGl6YXJfZXNwYWNvc19wb3NfcG9udHVhY2FvX2dv
REM b2dsZSh0ZXh0bywgcmV0cnlfcmVzdWx0YWRvKQogICAgICAgICAgICAgICAgICAgIGlmIGRl
REM c3Rpbm8ubG93ZXIoKS5zdGFydHN3aXRoKHUicHQiKToKICAgICAgICAgICAgICAgICAgICAg
REM ICAgcmV0cnlfcmVzdWx0YWRvID0gbm9ybWFsaXphcl90ZXJtb3NfaW5nbGVzX3Jlc2lkdWFp
REM c19wdGJyKHJldHJ5X3Jlc3VsdGFkbykKICAgICAgICAgICAgICAgICAgICBpZiBwYXJlY2Vf
REM cmVzaWR1b19pbmdsZXNfcmVzdWx0YWRvKHRleHRvLCByZXRyeV9yZXN1bHRhZG8sIHRpcG9f
REM ZW50cmFkYSk6CiAgICAgICAgICAgICAgICAgICAgICAgIG1lbGhvcmVzLmFwcGVuZChyZXRy
REM eV9yZXN1bHRhZG8pCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAg
REM ICAgICAgICAgICAgdmFsaWRhcl9yZXN1bHRhZG9fdHJhZHVjYW9fZ29vZ2xlKHRleHRvLCBy
REM ZXRyeV9yZXN1bHRhZG8sIHRpcG9fZW50cmFkYSwgdSJlbiIsIGRlc3Rpbm8pCiAgICAgICAg
REM ICAgICAgICAgICAgcmV0dXJuIGluZGljZSwgcmV0cnlfcmVzdWx0YWRvLCBOb25lCiAgICAg
REM ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIHJldHJ5X2V4YzoKICAgICAgICAgICAg
REM ICAgICAgICB1bHRpbW8gPSByZXRyeV9leGMKICAgICAgICAgICAgICAgICAgICBpZiBpc2lu
REM c3RhbmNlKHJldHJ5X2V4YywgR29vZ2xlUmF0ZUxpbWl0RXJyb3IpOgogICAgICAgICAgICAg
REM ICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICAgICAgICAgIGxvZy5hdmlzbyh1IlJl
REM dGVudGF0aXZhIEdvb2dsZSBUcmFuc2xhdGUgV2ViICh7MH0sIHRleHRvIHsxfS97Mn0pOiB7
REM M30iLmZvcm1hdChyZWwsIGluZGljZSArIDEsIHRvdGFsLCByZXRyeV9leGMpKQoKICAgICAg
REM ICAgICAgIyBTZSBhaW5kYSBob3V2ZXIgcmVzw61kdW8sIE7Dg08gY29udGFiaWxpemFyIGNv
REM bW8gc3VjZXNzbyBzaWxlbmNpb3NvLgogICAgICAgICAgICAjIFByZXNlcnZhbW9zIG8gY2Fj
REM aGUgZGUgcmV0b21hZGEgZSBlbmNlcnJhbW9zIGVzdGEgZW50cmFkYSBjb21vIGZhbGhhCiAg
REM ICAgICAgICAgICMgZXhwbMOtY2l0YSBwYXJhIHF1ZSBvdXRyYSBleGVjdcOnw6NvIHRlbnRl
REM IG5vdmFtZW50ZS4KICAgICAgICAgICAgaWYgdWx0aW1vIGlzIG5vdCBOb25lIGFuZCBpc2lu
REM c3RhbmNlKHVsdGltbywgRXhjZXB0aW9uKToKICAgICAgICAgICAgICAgIHJhaXNlIHVsdGlt
REM bwogICAgICAgICAgICByYWlzZSBHb29nbGVUcmFuc2xhdGVWYWxpZGF0aW9uRXJyb3IodSJy
REM ZXN1bHRhZG8gY29udMOpbSBpbmdsw6pzIHJlc2lkdWFsIGFww7NzIGFzIHRlbnRhdGl2YXMg
REM ZG8gR29vZ2xlIFRyYW5zbGF0ZSBXZWIiKQogICAgICAgIGV4Y2VwdCBHb29nbGVUcmFuc2xh
REM dGVWYWxpZGF0aW9uRXJyb3IgYXMgZXhjOgogICAgICAgICAgICB1bHRpbW8gPSBleGMKICAg
REM ICAgICAgICAgIyBQcmltZWlybyB0ZW50YSByZXBhcmFyIGNvbnRlw7pkbyB2aXPDrXZlbCBw
REM ZXJkaWRvIGRlbnRybyBkZSB0YWdzLgogICAgICAgICAgICBpZiB1InRleHRvIHZpc8OtdmVs
REM IGRlbnRybyBkZSB0YWcgZm9pIGFwYWdhZG8gcGVsYSB0cmFkdcOnw6NvIiBpbiBzdHIoZXhj
REM KToKICAgICAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICByZXBhcmFkb190
REM YWcgPSByZXBhcmFyX2NvbnRldWRvX3RhZ192YXppb19nb29nbGUodGV4dG8sIHJlc3VsdGFk
REM bywgY2xpZW50ZSwgb3JpZ2VtX2dvb2dsZSwgZGVzdGlubykKICAgICAgICAgICAgICAgICAg
REM ICBpZiByZXBhcmFkb190YWcgaXMgbm90IE5vbmU6CiAgICAgICAgICAgICAgICAgICAgICAg
REM IHZhbGlkYXJfcmVzdWx0YWRvX3RyYWR1Y2FvX2dvb2dsZSh0ZXh0bywgcmVwYXJhZG9fdGFn
REM LCB0aXBvX2VudHJhZGEsIG9yaWdlbV9nb29nbGUsIGRlc3Rpbm8pCiAgICAgICAgICAgICAg
REM ICAgICAgICAgIHJldHVybiBpbmRpY2UsIHJlcGFyYWRvX3RhZywgTm9uZQogICAgICAgICAg
REM ICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyByZXBhcm9fdGFnX2V4YzoKICAgICAgICAgICAg
REM ICAgICAgICB1bHRpbW8gPSByZXBhcm9fdGFnX2V4YwogICAgICAgICAgICAjIEZhbGhhcyBk
REM ZSB0b2tlbiBtZXJlY2VtIG8gZmFsbGJhY2sgcG9yIGZyYWdtZW50b3MgZXhpc3RlbnRlLgog
REM ICAgICAgICAgICBpZiAodSJ0b2tlbiBwcm90ZWdpZG8gZm9pIHJlbW92aWRvIHBlbGEgdHJh
REM ZHXDp8OjbyIgaW4gc3RyKGV4Yykgb3IKICAgICAgICAgICAgICAgICAgICB1InRva2VucyBw
REM cm90ZWdpZG9zIGZvcmFtIHJlbW92aWRvcyBwZWxhIHRyYWR1w6fDo28iIGluIHN0cihleGMp
REM IG9yCiAgICAgICAgICAgICAgICAgICAgdSJzZXF1w6puY2lhIGRlIHRva2VucyBwcm90ZWdp
REM ZG9zIGFsdGVyYWRhIiBpbiBzdHIoZXhjKSk6CiAgICAgICAgICAgICAgICB0cnk6CiAgICAg
REM ICAgICAgICAgICAgICAgcmVwYXJhZG8gPSB0cmFkdXppcl9wb3JfZnJhZ21lbnRvc19zZW1f
REM dG9rZW5zX2dvb2dsZShjbGllbnRlLCB0ZXh0bywgb3JpZ2VtX2dvb2dsZSwgZGVzdGlubykK
REM ICAgICAgICAgICAgICAgICAgICBpZiByZXBhcmFkbyBpcyBub3QgTm9uZToKICAgICAgICAg
REM ICAgICAgICAgICAgICAgdmFsaWRhcl9yZXN1bHRhZG9fdHJhZHVjYW9fZ29vZ2xlKHRleHRv
REM LCByZXBhcmFkbywgdGlwb19lbnRyYWRhLCBvcmlnZW1fZ29vZ2xlLCBkZXN0aW5vKQogICAg
REM ICAgICAgICAgICAgICAgICAgICByZXR1cm4gaW5kaWNlLCByZXBhcmFkbywgTm9uZQogICAg
REM ICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyByZXBhcm9fZXhjOgogICAgICAgICAg
REM ICAgICAgICAgIHVsdGltbyA9IHJlcGFyb19leGMKICAgICAgICAgICAgIyDDmmx0aW1vIHJl
REM Y3Vyc28gcGFyYSByZXNpZHVhbCBpbmdsw6pzL3Jlc3Bvc3RhIGlkw6pudGljYTogbyBtZXNt
REM byBSUEMsCiAgICAgICAgICAgICMgbWVzbWEgc2Vzc8OjbyBlIG1lc21vIHRocm90dGxlLCBt
REM YXMgZW0gZnJhZ21lbnRvcyBtZW5vcmVzLgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
REM ICAgICByZXBhcmFkb19yZXNpZHVhbCA9IHRyYWR1emlyX3Bvcl9mcmFnbWVudG9zX3Jlc2lk
REM dWFsX2dvb2dsZShjbGllbnRlLCB0ZXh0bywgb3JpZ2VtX2dvb2dsZSwgZGVzdGlubykKICAg
REM ICAgICAgICAgICAgIGlmIHJlcGFyYWRvX3Jlc2lkdWFsIGlzIG5vdCBOb25lOgogICAgICAg
REM ICAgICAgICAgICAgIHJlcGFyYWRvX3Jlc2lkdWFsID0gbm9ybWFsaXphcl9lc3BhY29zX3Bv
REM c19wb250dWFjYW9fZ29vZ2xlKHRleHRvLCByZXBhcmFkb19yZXNpZHVhbCkKICAgICAgICAg
REM ICAgICAgICAgICBpZiBkZXN0aW5vLmxvd2VyKCkuc3RhcnRzd2l0aCh1InB0Iik6CiAgICAg
REM ICAgICAgICAgICAgICAgICAgIHJlcGFyYWRvX3Jlc2lkdWFsID0gbm9ybWFsaXphcl90ZXJt
REM b3NfaW5nbGVzX3Jlc2lkdWFpc19wdGJyKHJlcGFyYWRvX3Jlc2lkdWFsKQogICAgICAgICAg
REM ICAgICAgICAgIHZhbGlkYXJfcmVzdWx0YWRvX3RyYWR1Y2FvX2dvb2dsZSh0ZXh0bywgcmVw
REM YXJhZG9fcmVzaWR1YWwsIHRpcG9fZW50cmFkYSwgb3JpZ2VtX2dvb2dsZSwgZGVzdGlubykK
REM ICAgICAgICAgICAgICAgICAgICByZXR1cm4gaW5kaWNlLCByZXBhcmFkb19yZXNpZHVhbCwg
REM Tm9uZQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIHJlcGFyb19yZXNpZHVhbF9l
REM eGM6CiAgICAgICAgICAgICAgICB1bHRpbW8gPSByZXBhcm9fcmVzaWR1YWxfZXhjCiAgICAg
REM ICAgZXhjZXB0IEdvb2dsZVJhdGVMaW1pdEVycm9yIGFzIGV4YzoKICAgICAgICAgICAgdWx0
REM aW1vID0gZXhjCiAgICAgICAgICAgICMgTyB0aHJvdHRsZSBnbG9iYWwgasOhIHBhdXNvdSBv
REM cyBkZW1haXMgd29ya2Vycy4gVGVudGFyIG5vdmFtZW50ZSBudW1hCiAgICAgICAgICAgICMg
REM bm92YSBzZXNzw6NvIHPDsyBkZXBvaXMgZG8gYmFja29mZiDDqSBzdWZpY2llbnRlOyBuw6Nv
REM IGNyaWFyIHJhamFkYXMgbm92YXMuCiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgZXhj
REM ZXB0IEV4Y2VwdGlvbiBhcyBleGM6CiAgICAgICAgICAgIHVsdGltbyA9IGV4YwogICAgICAg
REM ICAgICBpZiBsb2c6CiAgICAgICAgICAgICAgICBsb2cuZXJybyh1IkZhbGhhIHdvcmtlciBH
REM b29nbGUgVHJhbnNsYXRlIFdlYiAoezB9LCB0ZXh0byB7MX0vezJ9KTogezN9Ii5mb3JtYXQo
REM cmVsLCBpbmRpY2UgKyAxLCB0b3RhbCwgZXhjKSkKICAgICAgICAgICAgY29udGludWUKCiAg
REM ICBpZiB1bHRpbW8gaXMgTm9uZToKICAgICAgICB1bHRpbW8gPSBHb29nbGVUcmFuc2xhdGVF
REM cnJvcih1InRyYWR1w6fDo28gbsOjbyBwcm9kdXppdSByZXN1bHRhZG8iKQogICAgcmV0dXJu
REM IGluZGljZSwgTm9uZSwgdWx0aW1vCgoKZGVmIGNhcnJlZ2FyX2NhY2hlX2dvb2dsZShjYW1p
REM bmhvKToKICAgIGlmIG5vdCBvcy5wYXRoLmlzZmlsZShjYW1pbmhvKTogcmV0dXJuIHt9CiAg
REM ICB0cnk6CiAgICAgICAgd2l0aCBpby5vcGVuKGNhbWluaG8sICJyIiwgZW5jb2Rpbmc9InV0
REM Zi04IikgYXMgZjogZGFkb3MgPSBqc29uLmxvYWQoZikKICAgICAgICBpZiBpc2luc3RhbmNl
REM KGRhZG9zLCBkaWN0KSBhbmQgZGFkb3MuZ2V0KHUic2NoZW1hIikgPT0gR09PR0xFX0NBQ0hF
REM X1NDSEVNQSBhbmQgaXNpbnN0YW5jZShkYWRvcy5nZXQodSJlbnRyaWVzIiksIGRpY3QpOiBy
REM ZXR1cm4gZGFkb3NbdSJlbnRyaWVzIl0KICAgIGV4Y2VwdCBFeGNlcHRpb246IHBhc3MKICAg
REM IHJldHVybiB7fQoKCmRlZiBzYWx2YXJfY2FjaGVfZ29vZ2xlKGNhbWluaG8sIGNhY2hlKToK
REM ICAgIHRlbXAgPSBjYW1pbmhvICsgdSIudG1wIgogICAgd2l0aCBpby5vcGVuKHRlbXAsICJ3
REM IiwgZW5jb2Rpbmc9InV0Zi04IikgYXMgZjoKICAgICAgICBqc29uLmR1bXAoe3Uic2NoZW1h
REM IjogR09PR0xFX0NBQ0hFX1NDSEVNQSwgdSJlbnRyaWVzIjogY2FjaGV9LCBmLCBlbnN1cmVf
REM YXNjaWk9RmFsc2UsIGluZGVudD0xKQogICAgb3MucmVwbGFjZSh0ZW1wLCBjYW1pbmhvKQoK
REM ZGVmIGxpbXBhcl9jYWNoZV9nb29nbGVfdGVtcG9yYXJpbyhjYW1pbmhvKToKICAgICIiIlJl
REM bW92ZSBvIGNhY2hlIHRlbXBvcsOhcmlvIGUgbyBhcnF1aXZvIGRlIGVzY3JpdGEgYXRvbWlj
REM YSBhc3NvY2lhZG8uIiIiCiAgICByZW1vdmlkbyA9IFRydWUKICAgIGZvciBhbHZvIGluIChj
REM YW1pbmhvLCBjYW1pbmhvICsgdSIudG1wIik6CiAgICAgICAgdHJ5OgogICAgICAgICAgICBp
REM ZiBvcy5wYXRoLmlzZmlsZShhbHZvKToKICAgICAgICAgICAgICAgIG9zLnJlbW92ZShhbHZv
REM KQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHJlbW92aWRvID0gRmFs
REM c2UKICAgIHJldHVybiByZW1vdmlkbwoKCmRlZiBjaGF2ZV9jYWNoZV9nb29nbGUob3JpZ2Vt
REM LCBkZXN0aW5vLCB0ZXh0byk6CiAgICBvcmlnZW0gPSB0ZXh0b19jb21wYXRpdmVsKG9yaWdl
REM bSwgdSJhdXRvIikgb3IgdSJhdXRvIgogICAgZGVzdGlubyA9IHRleHRvX2NvbXBhdGl2ZWwo
REM ZGVzdGlubywgdSIiKQogICAgdGV4dG8gPSB0ZXh0b19jb21wYXRpdmVsKHRleHRvLCB1IiIp
REM CiAgICByZXR1cm4gdSJ7MH1ceDFmezF9XHgxZnsyfVx4MWZ7M30iLmZvcm1hdChHT09HTEVf
REM Q0FDSEVfTU9UT1JfSUQsIG9yaWdlbS5sb3dlcigpLCBkZXN0aW5vLmxvd2VyKCksIHRleHRv
REM KQoKCgpkZWYgY2hhdmVfY2FjaGVfY3JlZGl0b19nb29nbGUob3JpZ2VtLCBkZXN0aW5vLCB0
REM ZXh0byk6CiAgICBvcmlnZW0gPSB0ZXh0b19jb21wYXRpdmVsKG9yaWdlbSwgdSJhdXRvIikg
REM b3IgdSJhdXRvIgogICAgZGVzdGlubyA9IHRleHRvX2NvbXBhdGl2ZWwoZGVzdGlubywgdSIi
REM KQogICAgdGV4dG8gPSB0ZXh0b19jb21wYXRpdmVsKHRleHRvLCB1IiIpCiAgICByZXR1cm4g
REM dSJ7MH1ceDFmezF9XHgxZnsyfVx4MWZ7M30iLmZvcm1hdChHT09HTEVfQ0FDSEVfQ1JFRElU
REM T1NfTU9UT1JfSUQsIG9yaWdlbS5sb3dlcigpLCBkZXN0aW5vLmxvd2VyKCksIHRleHRvKQoK
REM CmRlZiBjYWNoZV9jcmVkaXRvX2dvb2dsZV9wb2RlX3JldXRpbGl6YXIoY2FjaGUsIGNoYXZl
REM LCBmb250ZSwgZGVzdGlubyk6CiAgICB2YWxvciA9IGNhY2hlLmdldChjaGF2ZSkKICAgICMg
REM TWlncmHDp8OjbyB0cmFuc3BhcmVudGU6IFYxMzcvVjEzOCBncmF2YXJhbSBjcsOpZGl0b3Mg
REM Y29tIGEgY2hhdmUgUlBDCiAgICAjIGdlbsOpcmljYS4gU2UgZWxhIGFpbmRhIGVzdGl2ZXIg
REM bm8gY2FjaGUsIHJlYXByb3ZlaXRhbW9zIGUgcHJvbW92ZW1vcwogICAgIyBwYXJhIGEgY2hh
REM dmUgZXNwZWPDrWZpY2EgZGUgY3LDqWRpdG9zLCBldml0YW5kbyBub3ZhcyByZXF1aXNpw6fD
REM tWVzLgogICAgaWYgbm90IGlzaW5zdGFuY2UodmFsb3IsIFRFWFRfVFlQRVMpOgogICAgICAg
REM IGNoYXZlX2xlZ2FkbyA9IGNoYXZlX2NhY2hlX2dvb2dsZSh1ImF1dG8iLCBkZXN0aW5vLCBm
REM b250ZSkKICAgICAgICB2YWxvciA9IGNhY2hlLmdldChjaGF2ZV9sZWdhZG8pCiAgICAgICAg
REM aWYgbm90IGlzaW5zdGFuY2UodmFsb3IsIFRFWFRfVFlQRVMpOgogICAgICAgICAgICByZXR1
REM cm4gTm9uZQogICAgICAgIHZhbG9yID0gdGV4dG9fY29tcGF0aXZlbCh2YWxvciwgdSIiKQog
REM ICAgICAgIGNhY2hlW2NoYXZlXSA9IHZhbG9yCiAgICBlbHNlOgogICAgICAgIHZhbG9yID0g
REM dGV4dG9fY29tcGF0aXZlbCh2YWxvciwgdSIiKQogICAgdHJ5OgogICAgICAgIHNyY19saW5l
REM cyA9IGZvbnRlLnNwbGl0bGluZXMoKQogICAgICAgIGRzdF9saW5lcyA9IHZhbG9yLnNwbGl0
REM bGluZXMoKQogICAgICAgIGlmIGxlbihzcmNfbGluZXMpICE9IGxlbihkc3RfbGluZXMpOgog
REM ICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgIGZvciBzcmNfbGluZSwgZHN0X2xpbmUg
REM aW4gemlwKHNyY19saW5lcywgZHN0X2xpbmVzKToKICAgICAgICAgICAgc3JjX2JvZHkgPSBz
REM cmNfbGluZS5zdHJpcCgpCiAgICAgICAgICAgIGRzdF9ib2R5ID0gZHN0X2xpbmUuc3RyaXAo
REM KQogICAgICAgICAgICBpZiBub3Qgc3JjX2JvZHk6CiAgICAgICAgICAgICAgICBpZiBkc3Rf
REM Ym9keToKICAgICAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICAgICAg
REM Y29udGludWUKICAgICAgICAgICAgaXNfcm9sZSA9IChzcmNfYm9keS5lbmRzd2l0aCgnOicp
REM IGFuZCBfcm90dWxvX2NyZWRpdG9fZWhfY2F0ZWdvcmlhKHNyY19ib2R5WzotMV0pKSBvciBf
REM bGluaGFfY3JlZGl0b19yb2xlX2VoX2NhdGVnb3JpYShzcmNfYm9keSkKICAgICAgICAgICAg
REM aWYgbm90IGlzX3JvbGUgYW5kIHNyY19saW5lICE9IGRzdF9saW5lOgogICAgICAgICAgICAg
REM ICAgcmV0dXJuIE5vbmUKICAgICAgICB2YWxpZGFyX2ludGVncmlkYWRlX3RyYWR1Y2FvX2dv
REM b2dsZShmb250ZSwgdmFsb3IpCiAgICAgICAgcmV0dXJuIHZhbG9yCiAgICBleGNlcHQgRXhj
REM ZXB0aW9uOgogICAgICAgIHJldHVybiBOb25lCgoKZGVmIG9yaWdlbV9jYWNoZShjaGF2ZSk6
REM CiAgICB0cnk6CiAgICAgICAgcGFydGVzID0gdGV4dG9fY29tcGF0aXZlbChjaGF2ZSwgdSIi
REM KS5zcGxpdCh1Ilx4MWYiLCAzKQogICAgICAgIHJldHVybiBwYXJ0ZXNbMV0ubG93ZXIoKSBp
REM ZiBsZW4ocGFydGVzKSA+PSA0IGVsc2UgcGFydGVzWzBdLmxvd2VyKCkKICAgIGV4Y2VwdCBF
REM eGNlcHRpb246CiAgICAgICAgcmV0dXJuIHUiYXV0byIKCgpkZWYgb3JpZ2VtX2NhY2hlX2lz
REM X2F1dG8oY2hhdmUpOgogICAgcmV0dXJuIG9yaWdlbV9jYWNoZShjaGF2ZSkgPT0gdSJhdXRv
REM IgoKCmRlZiBjYWNoZV9nb29nbGVfcG9kZV9yZXV0aWxpemFyKGNhY2hlLCBjaGF2ZSwgZm9u
REM dGUsIGRlc3Rpbm8sIHRpcG9fZW50cmFkYSwgcmVsPXUiIik6CiAgICBjaGF2ZSA9IHRleHRv
REM X2NvbXBhdGl2ZWwoY2hhdmUsIHUiIikKICAgIGZvbnRlID0gdGV4dG9fY29tcGF0aXZlbChm
REM b250ZSwgdSIiKQogICAgZGVzdGlubyA9IHRleHRvX2NvbXBhdGl2ZWwoZGVzdGlubywgdSJw
REM dC1CUiIpCiAgICB0aXBvX2VudHJhZGEgPSB0ZXh0b19jb21wYXRpdmVsKHRpcG9fZW50cmFk
REM YSwgdSIiKQogICAgdmFsb3IgPSBjYWNoZS5nZXQoY2hhdmUpCiAgICBpZiBub3QgaXNpbnN0
REM YW5jZSh2YWxvciwgVEVYVF9UWVBFUyk6CiAgICAgICAgcmV0dXJuIE5vbmUKICAgIGNvcnJl
REM Y2FvX2NhY2hlLCByZWdyYV9jYWNoZSA9IGFwbGljYXJfY29ycmVjYW9faW5kaXZpZHVhbF9n
REM b29nbGUoZm9udGUsIHJlbCwgdGlwb19lbnRyYWRhLCBkZXN0aW5vLCBOb25lKQogICAgaWYg
REM Y29ycmVjYW9fY2FjaGUgaXMgbm90IE5vbmU6CiAgICAgICAgdmFsb3IgPSBjb3JyZWNhb19j
REM YWNoZQogICAgdmFsb3IgPSBub3JtYWxpemFyX3BlcmNlbnR1YWlzX3BhcmFfcmVpbnRlZ3Jh
REM Y2FvKGZvbnRlLCB2YWxvcikKICAgIGlmIGRlc3Rpbm8ubG93ZXIoKS5zdGFydHN3aXRoKHUi
REM cHQiKToKICAgICAgICB2YWxvciA9IG5vcm1hbGl6YXJfdGVybW9zX2luZ2xlc19yZXNpZHVh
REM aXNfcHRicih2YWxvcikKICAgIHRyeToKICAgICAgICB0cnk6CiAgICAgICAgICAgIG9yaWdl
REM bV9jYWNoZV92YWwgPSBvcmlnZW1fY2FjaGUoY2hhdmUpCiAgICAgICAgZXhjZXB0IEV4Y2Vw
REM dGlvbjoKICAgICAgICAgICAgb3JpZ2VtX2NhY2hlX3ZhbCA9IHUiYXV0byIKICAgICAgICB2
REM YWxpZGFyX3Jlc3VsdGFkb190cmFkdWNhb19nb29nbGUoZm9udGUsIHZhbG9yLCB0aXBvX2Vu
REM dHJhZGEsIG9yaWdlbV9jYWNoZV92YWwsIGRlc3Rpbm8pCiAgICBleGNlcHQgRXhjZXB0aW9u
REM OgogICAgICAgIHJldHVybiBOb25lCiAgICBpZiAoZGVzdGluby5sb3dlcigpLnN0YXJ0c3dp
REM dGgodSJwdCIpIGFuZCBvcmlnZW1fY2FjaGVfaXNfYXV0byhjaGF2ZSkgYW5kCiAgICAgICAg
REM ICAgICgodmFsb3IgPT0gZm9udGUgYW5kCiAgICAgICAgICAgICAgKCh0aXBvX2VudHJhZGEg
REM PT0gdSJkaWFsb2dvIiBhbmQgZGV2ZV9mb3JjYXJfcmV0ZW50YXRpdmFfZGlhbG9nbyhmb250
REM ZSkpIG9yCiAgICAgICAgICAgICAgICh0aXBvX2VudHJhZGEgIT0gdSJkaWFsb2dvIiBhbmQg
REM ZGV2ZV9mb3JjYXJfcmV0ZW50YXRpdmFfaWd1YWwoZm9udGUpKSkpIG9yCiAgICAgICAgICAg
REM ICBwYXJlY2VfcmVzaWR1b19pbmdsZXNfcmVzdWx0YWRvKGZvbnRlLCB2YWxvciwgdGlwb19l
REM bnRyYWRhKSkpOgogICAgICAgIHJldHVybiBOb25lCiAgICByZXR1cm4gdmFsb3IKCgpkZWYg
REM c2FsdmFyX2NhY2hlX2dvb2dsZV9zZWd1cm8oY2FjaGUsIGNoYXZlLCBmb250ZSwgdmFsb3Ip
REM OgogICAgIyBEdXJhbnRlIGEgZXhlY3XDp8OjbywgdHJhZHXDp8OjbyB2w6FsaWRhIGRpZmVy
REM ZW50ZSBkbyBvcmlnaW5hbCBudW5jYSDDqQogICAgIyBzdWJzdGl0dcOtZGEgYXV0b21hdGlj
REM YW1lbnRlIHBvciBvdXRyYSByZXNwb3N0YSBkbyBHb29nbGUuCiAgICAjIEluZ2zDqnMtb3Jp
REM Z2luYWwgLT4gdHJhZHXDp8OjbyBlZmV0aXZhIMOpIGEgw7puaWNhIHN1YnN0aXR1acOnw6Nv
REM IGF1dG9tw6F0aWNhLgogICAgaWYgbm90IGlzaW5zdGFuY2UodmFsb3IsIHN0cik6CiAgICAg
REM ICAgcmV0dXJuIEZhbHNlCiAgICBhdHVhbCA9IGNhY2hlLmdldChjaGF2ZSkKICAgIGlmIGF0
REM dWFsIGlzIE5vbmUgb3IgYXR1YWwgPT0gZm9udGU6CiAgICAgICAgY2FjaGVbY2hhdmVdID0g
REM dmFsb3IKICAgICAgICByZXR1cm4gVHJ1ZQogICAgcmV0dXJuIEZhbHNlCgoKZGVmIGxvY2Fs
REM aXphcl9wYXN0YV9leHRyYWNhb190cmFkdWNhbyhyYWl6KToKICAgIGNhbmRpZGF0b3MgPSBs
REM aXN0YXJfcGFzdGFzX2RpYWxvZ29zX3Bvcl9jYXRlZ29yaWEocmFpeiwge3UiZXh0cmFjYW8i
REM fSkKICAgIGlmIG5vdCBjYW5kaWRhdG9zOgogICAgICAgIHJldHVybiBOb25lLCBOb25lCiAg
REM ICAjIElmIG1vcmUgdGhhbiBvbmUgZXh0cmFjdGlvbiBmb2xkZXIgZXhpc3RzIChmb3IgZXhh
REM bXBsZSBhZnRlciBydW5zIGluCiAgICAjIGRpZmZlcmVudCBpbnRlcmZhY2UgbGFuZ3VhZ2Vz
REM KSwga2VlcCB0aGUgc2FtZSBleHBsaWNpdCBjaG9pY2UgbW9kZWwuCiAgICBpZiBsZW4oY2Fu
REM ZGlkYXRvcykgPT0gMToKICAgICAgICByZXR1cm4gY2FuZGlkYXRvc1swXVswXSwgY2FuZGlk
REM YXRvc1swXVsxXQogICAgcHJpbnQodSIiKQogICAgcHJpbnQodCgicmVpbmpfbXVsdGlwbGFz
REM X3RpdHVsbyIpKQogICAgZm9yIGksIChjYW1pbmhvLCBub21lX21hcGEsIGNhdGVnb3JpYSkg
REM aW4gZW51bWVyYXRlKGNhbmRpZGF0b3MsIDEpOgogICAgICAgIHByaW50KHQoInJlaW5qX211
REM bHRpcGxhc19vcGNhbyIpLmZvcm1hdChpLCBjYW1pbmhvKSkKICAgIHByaW50KHUiIikKICAg
REM IHdoaWxlIFRydWU6CiAgICAgICAgdHJ5OgogICAgICAgICAgICBlc2NvbGhhID0gaW5wdXQo
REM dCgicmVpbmpfbXVsdGlwbGFzX3Byb21wdCIpKS5zdHJpcCgpCiAgICAgICAgZXhjZXB0IChF
REM T0ZFcnJvciwgS2V5Ym9hcmRJbnRlcnJ1cHQpOgogICAgICAgICAgICByZXR1cm4gTm9uZSwg
REM Tm9uZQogICAgICAgIGlmIGVzY29saGEuaXNkaWdpdCgpOgogICAgICAgICAgICBpbmRpY2Ug
REM PSBpbnQoZXNjb2xoYSkgLSAxCiAgICAgICAgICAgIGlmIDAgPD0gaW5kaWNlIDwgbGVuKGNh
REM bmRpZGF0b3MpOgogICAgICAgICAgICAgICAgcmV0dXJuIGNhbmRpZGF0b3NbaW5kaWNlXVsw
REM XSwgY2FuZGlkYXRvc1tpbmRpY2VdWzFdCiAgICAgICAgcHJpbnQodCgicmVpbmpfbXVsdGlw
REM bGFzX2ludmFsaWRhIikpCgoKZGVmIGNvbmZpZ3VyYXJfaW50ZXJ2YWxvX2RpYWdub3N0aWNv
REM KGludGVydmFsbyk6CiAgICAjIEFqdXN0ZSBzb21lbnRlIGVtIG1lbcOzcmlhIHBhcmEgbyB0
REM ZXN0ZSBhdHVhbDsgR09PR0xFX0lOVEVSVkFMT19NSU5JTU8KICAgICMgY29udGludWEgMC4z
REM MHMgbm8gYXJxdWl2byBlIG5hZGEgw6kgcGVyc2lzdGlkby4KICAgIHdpdGggR09PR0xFX1RI
REM Uk9UVExFLmxvY2s6CiAgICAgICAgR09PR0xFX1RIUk9UVExFLmludGVydmFsb19taW5pbW8g
REM PSBmbG9hdChpbnRlcnZhbG8pCiAgICAgICAgR09PR0xFX1RIUk9UVExFLnByb3hpbWFfbGli
REM ZXJhY2FvID0gMC4wCiAgICAgICAgR09PR0xFX1RIUk9UVExFLmJhY2tvZmZfYXR1YWwgPSBH
REM T09HTEVfVEhST1RUTEUuYmFja29mZl9pbmljaWFsCgoKZGVmIF9kaWFnbm9zdGljb19lc3Ry
REM ZXNzZV90ZXh0byhjbGllbnRlLCB0ZXh0bywgb3JpZ2VtLCBkZXN0aW5vLCBpbmRpY2UsIHBh
REM cmFyX2V2ZW50byk6CiAgICBpZiBwYXJhcl9ldmVudG8uaXNfc2V0KCk6CiAgICAgICAgcmV0
REM dXJuIHsKICAgICAgICAgICAgIm9rIjogRmFsc2UsICJyYXRlX2xpbWl0IjogRmFsc2UsICJj
REM YW5jZWxhZG8iOiBUcnVlLAogICAgICAgICAgICAid29ya2VyIjogY2xpZW50ZS53b3JrZXJf
REM aWQgKyAxLCAiaW5kaWNlIjogaW5kaWNlLAogICAgICAgICAgICAic2VndW5kb3MiOiAwLjAs
REM ICJzdGF0dXMiOiBjbGllbnRlLnVsdGltb19zdGF0dXMsICJlcnJvIjogTm9uZSwKICAgICAg
REM ICB9CiAgICBpbmljaW8gPSB0aW1lLnBlcmZfY291bnRlcigpCiAgICB0cnk6CiAgICAgICAg
REM Y2xpZW50ZS50cmFkdXppcih0ZXh0bywgb3JpZ2VtLCBkZXN0aW5vKQogICAgICAgIHJldHVy
REM biB7CiAgICAgICAgICAgICJvayI6IFRydWUsICJyYXRlX2xpbWl0IjogRmFsc2UsICJjYW5j
REM ZWxhZG8iOiBGYWxzZSwKICAgICAgICAgICAgIndvcmtlciI6IGNsaWVudGUud29ya2VyX2lk
REM ICsgMSwgImluZGljZSI6IGluZGljZSwKICAgICAgICAgICAgInNlZ3VuZG9zIjogdGltZS5w
REM ZXJmX2NvdW50ZXIoKSAtIGluaWNpbywKICAgICAgICAgICAgInN0YXR1cyI6IGNsaWVudGUu
REM dWx0aW1vX3N0YXR1cyBvciAyMDAsICJlcnJvIjogTm9uZSwKICAgICAgICB9CiAgICBleGNl
REM cHQgR29vZ2xlUmF0ZUxpbWl0RXJyb3IgYXMgZXhjOgogICAgICAgIHBhcmFyX2V2ZW50by5z
REM ZXQoKQogICAgICAgIHJldHVybiB7CiAgICAgICAgICAgICJvayI6IEZhbHNlLCAicmF0ZV9s
REM aW1pdCI6IFRydWUsICJjYW5jZWxhZG8iOiBGYWxzZSwKICAgICAgICAgICAgIndvcmtlciI6
REM IGNsaWVudGUud29ya2VyX2lkICsgMSwgImluZGljZSI6IGluZGljZSwKICAgICAgICAgICAg
REM InNlZ3VuZG9zIjogdGltZS5wZXJmX2NvdW50ZXIoKSAtIGluaWNpbywKICAgICAgICAgICAg
REM InN0YXR1cyI6IGNsaWVudGUudWx0aW1vX3N0YXR1cywKICAgICAgICAgICAgImVycm8iOiB1
REM InswfTogezF9Ii5mb3JtYXQodHlwZShleGMpLl9fbmFtZV9fLCBleGMpLAogICAgICAgICAg
REM ICAibW9tZW50byI6IHRpbWUucGVyZl9jb3VudGVyKCksCiAgICAgICAgfQogICAgZXhjZXB0
REM IEV4Y2VwdGlvbiBhcyBleGM6CiAgICAgICAgcGFyYXJfZXZlbnRvLnNldCgpCiAgICAgICAg
REM cmV0dXJuIHsKICAgICAgICAgICAgIm9rIjogRmFsc2UsICJyYXRlX2xpbWl0IjogRmFsc2Us
REM ICJjYW5jZWxhZG8iOiBGYWxzZSwKICAgICAgICAgICAgIndvcmtlciI6IGNsaWVudGUud29y
REM a2VyX2lkICsgMSwgImluZGljZSI6IGluZGljZSwKICAgICAgICAgICAgInNlZ3VuZG9zIjog
REM dGltZS5wZXJmX2NvdW50ZXIoKSAtIGluaWNpbywKICAgICAgICAgICAgInN0YXR1cyI6IGNs
REM aWVudGUudWx0aW1vX3N0YXR1cywKICAgICAgICAgICAgImVycm8iOiB1InswfTogezF9Ii5m
REM b3JtYXQodHlwZShleGMpLl9fbmFtZV9fLCBleGMpLAogICAgICAgIH0KCgpkZWYgZXhlY3V0
REM YXJfZGlhZ25vc3RpY29fZXN0cmVzc2VfZ29vZ2xlKHJhaXopOgogICAgY2FtaW5ob19sb2cg
REM PSBvcy5wYXRoLmpvaW4ocmFpeiwgR09PR0xFX0NBQ0hFX0VTVFJFU1NFX05PTUUpCiAgICBs
REM b2cgPSBMb2coY2FtaW5ob19sb2cpCiAgICBsb2cuc2VwYXJhZG9yKCkKICAgIGxvZy50aXR1
REM bG8odSJEREFDIC0gVGVzdGUgZGUgZXN0cmVzc2UgZG8gbGltaXRlIGRvIEdvb2dsZSBUcmFu
REM c2xhdGUiKQogICAgbG9nLmluZm8odSJCYXNlbGluZSBwcmV2aWFtZW50ZSBjb25maXJtYWRv
REM OiB7MDouMmZ9cyAobsOjbyBzZXLDoSByZWZlaXRvIG5lc3RlIHRlc3RlKS4iLmZvcm1hdChH
REM T09HTEVfRElBR05PU1RJQ09fRVNUUkVTU0VfQkFTRUxJTkUpKQogICAgbG9nLmluZm8odSJM
REM b3RlIHBvciBkZWdyYXU6IHswfSB0ZXh0b3Mgw7puaWNvczsgaW50ZXJ2YWxvczogezF9LiIu
REM Zm9ybWF0KAogICAgICAgIEdPT0dMRV9ESUFHTk9TVElDT19FU1RSRVNTRV9MT1RFLAogICAg
REM ICAgIHUiIC0+ICIuam9pbih1InswOi4yZn1zIi5mb3JtYXQoeCkgZm9yIHggaW4gR09PR0xF
REM X0RJQUdOT1NUSUNPX0VTVFJFU1NFX0lOVEVSVkFMT1MpKSkKICAgIGxvZy5pbmZvKHUiTyB0
REM ZXN0ZSB1c2EgbyBwb29sIHJlYWwgZGUgd29ya2VycyBlIG8gR09PR0xFX1RIUk9UVExFIHJl
REM YWwsIHNvbWVudGUgZW0gbWVtw7NyaWEuIikKCiAgICBwcmludCh1Ij09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIpCiAgICBw
REM cmludCh1IiBURVNURSBERSBFU1RSRVNTRSBETyBHT09HTEUgVFJBTlNMQVRFIikKICAgIHBy
REM aW50KHUiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09IikKICAgIHByaW50KHUiIikKICAgIHByaW50KHUiMCwzMHMgasOhIGZv
REM aSBjb25maXJtYWRvIGFudGVyaW9ybWVudGU7IGVzdGEgY2FsaWJyYcOnw6NvIGNvbWXDp2Eg
REM ZW0gMCwyNXMuIikKICAgIHByaW50KHUiU2Vyw6NvIHVzYWRvcyB7MH0gdGV4dG9zIMO6bmlj
REM b3MgcG9yIGRlZ3JhdSwgc2VtIGFsdGVyYXIgYXJxdWl2b3MgZG8gam9nby4iLmZvcm1hdChH
REM T09HTEVfRElBR05PU1RJQ09fRVNUUkVTU0VfTE9URSkpCiAgICBwcmludCh1Ik8gcHJpbWVp
REM cm8gSFRUUCA0MjkgZW5jZXJyYSBhIHNvbmRhZ2VtOyBvIMO6bHRpbW8gZGVncmF1IGxpbXBv
REM IGZpY2EgY29tbyByZWZlcsOqbmNpYS4iKQogICAgcHJpbnQodSIiKQoKICAgIG9yaWdlbSA9
REM IHUiYXV0byIKICAgIGRlc3Rpbm8gPSB1InB0LUJSIgogICAgdHJ5OgogICAgICAgIHBvb2wg
REM PSBjcmlhcl9wb29sX2dvb2dsZShsb2cpCiAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoK
REM ICAgICAgICBsb2cuZXJybyh1IkZhbGhhIGFvIHByZXBhcmFyIG8gcG9vbCBHb29nbGU6IHsw
REM fSIuZm9ybWF0KGV4YykpCiAgICAgICAgbG9nLnNhbHZhcigpCiAgICAgICAgcHJpbnQodSJF
REM UlJPIGFvIHByZXBhcmFyIG8gcG9vbCBHb29nbGU6IHswfSIuZm9ybWF0KGV4YykpCiAgICAg
REM ICAgcmV0dXJuIDEKCiAgICB1bHRpbW9fc2VndXJvID0gR09PR0xFX0RJQUdOT1NUSUNPX0VT
REM VFJFU1NFX0JBU0VMSU5FCiAgICB0b3RhbF9pbmljaW8gPSB0aW1lLnBlcmZfY291bnRlcigp
REM CiAgICByZXN1bHRhZG9fcGFyYWRhID0gTm9uZQoKICAgIGZvciBldGFwYSwgaW50ZXJ2YWxv
REM IGluIGVudW1lcmF0ZShHT09HTEVfRElBR05PU1RJQ09fRVNUUkVTU0VfSU5URVJWQUxPUywg
REM MSk6CiAgICAgICAgY29uZmlndXJhcl9pbnRlcnZhbG9fZGlhZ25vc3RpY28oaW50ZXJ2YWxv
REM KQogICAgICAgIG5vbmNlID0gaW50KHRpbWUudGltZSgpICogMTAwMDAwMCkKICAgICAgICB0
REM ZXh0b3MgPSBbCiAgICAgICAgICAgIHUiVW5SZW4tRERBQyBzdHJlc3MgezB9LXsxfS17Mjow
REM NGR9OiB0ZXh0byBzaW50w6l0aWNvIMO6bmljbyBwYXJhIGNhbGlicmHDp8Ojby4iLmZvcm1h
REM dCgKICAgICAgICAgICAgICAgIG5vbmNlLCBpbnQocm91bmQoaW50ZXJ2YWxvICogMTAwKSks
REM IGkgKyAxKQogICAgICAgICAgICBmb3IgaSBpbiByYW5nZShHT09HTEVfRElBR05PU1RJQ09f
REM RVNUUkVTU0VfTE9URSkKICAgICAgICBdCgogICAgICAgIHByaW50KHUiW0RFR1JBVSB7MH0v
REM ezF9XSBJbnRlcnZhbG8gezI6LjJmfXMgfCB7M30gdGV4dG9zIHwgezR9IHdvcmtlcnMiLmZv
REM cm1hdCgKICAgICAgICAgICAgZXRhcGEsIGxlbihHT09HTEVfRElBR05PU1RJQ09fRVNUUkVT
REM U0VfSU5URVJWQUxPUyksIGludGVydmFsbywgbGVuKHRleHRvcyksIGxlbihwb29sKSkpCiAg
REM ICAgICAgbG9nLnNlcGFyYWRvcigpCiAgICAgICAgbG9nLmluZm8odSJJTsONQ0lPIGRlZ3Jh
REM dT17MDouMmZ9cyBsb3RlPXsxfSB3b3JrZXJzPXsyfSIuZm9ybWF0KGludGVydmFsbywgbGVu
REM KHRleHRvcyksIGxlbihwb29sKSkpCgogICAgICAgIGluaWNpb19ldGFwYSA9IHRpbWUucGVy
REM Zl9jb3VudGVyKCkKICAgICAgICBvayA9IDAKICAgICAgICByYXRlX2xpbWl0cyA9IFtdCiAg
REM ICAgICAgZXJyb3NfbmFvXzQyOSA9IFtdCiAgICAgICAgcGFyYXJfZXZlbnRvID0gdGhyZWFk
REM aW5nLkV2ZW50KCkKCiAgICAgICAgd2l0aCBUaHJlYWRQb29sRXhlY3V0b3IobWF4X3dvcmtl
REM cnM9bGVuKHBvb2wpKSBhcyBleGVjdXRvcjoKICAgICAgICAgICAgZnV0dXJvcyA9IFtdCiAg
REM ICAgICAgICAgIGZvciBpbmRpY2UsIHRleHRvIGluIGVudW1lcmF0ZSh0ZXh0b3MpOgogICAg
REM ICAgICAgICAgICAgY2xpZW50ZSA9IHBvb2xbaW5kaWNlICUgbGVuKHBvb2wpXQogICAgICAg
REM ICAgICAgICAgZnV0dXJvcy5hcHBlbmQoZXhlY3V0b3Iuc3VibWl0KAogICAgICAgICAgICAg
REM ICAgICAgIF9kaWFnbm9zdGljb19lc3RyZXNzZV90ZXh0bywgY2xpZW50ZSwgdGV4dG8sIG9y
REM aWdlbSwgZGVzdGlubywgaW5kaWNlICsgMSwgcGFyYXJfZXZlbnRvCiAgICAgICAgICAgICAg
REM ICApKQoKICAgICAgICAgICAgZm9yIGNvbmNsdWlkbywgZnV0dXJvIGluIGVudW1lcmF0ZShh
REM c19jb21wbGV0ZWQoZnV0dXJvcyksIDEpOgogICAgICAgICAgICAgICAgciA9IGZ1dHVyby5y
REM ZXN1bHQoKQogICAgICAgICAgICAgICAgaWYgclsiY2FuY2VsYWRvIl06CiAgICAgICAgICAg
REM ICAgICAgICAgcGFzcwogICAgICAgICAgICAgICAgZWxpZiByWyJvayJdOgogICAgICAgICAg
REM ICAgICAgICAgIG9rICs9IDEKICAgICAgICAgICAgICAgIGVsaWYgclsicmF0ZV9saW1pdCJd
REM OgogICAgICAgICAgICAgICAgICAgIHJhdGVfbGltaXRzLmFwcGVuZChyKQogICAgICAgICAg
REM ICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICBlcnJvc19uYW9fNDI5LmFwcGVuZChy
REM KQogICAgICAgICAgICAgICAgaWYgY29uY2x1aWRvID09IDEgb3IgY29uY2x1aWRvID09IGxl
REM bih0ZXh0b3MpIG9yIGNvbmNsdWlkbyAlIDEwID09IDA6CiAgICAgICAgICAgICAgICAgICAg
REM cHJpbnQodSJcciAgUHJvZ3Jlc3NvOiB7MH0vezF9Ii5mb3JtYXQoY29uY2x1aWRvLCBsZW4o
REM dGV4dG9zKSksIGVuZD11IiIpCiAgICAgICAgcHJpbnQodSIiKQoKICAgICAgICBkZWNvcnJp
REM ZG8gPSB0aW1lLnBlcmZfY291bnRlcigpIC0gaW5pY2lvX2V0YXBhCiAgICAgICAgbG9nLmlu
REM Zm8odSJGSU0gZGVncmF1PXswOi4yZn1zIG9rPXsxfSA0Mjk9ezJ9IGVycm9zX27Do29fNDI5
REM PXszfSB0ZW1wbz17NDouMmZ9cyIuZm9ybWF0KAogICAgICAgICAgICBpbnRlcnZhbG8sIG9r
REM LCBsZW4ocmF0ZV9saW1pdHMpLCBsZW4oZXJyb3NfbmFvXzQyOSksIGRlY29ycmlkbykpCgog
REM ICAgICAgIGlmIGVycm9zX25hb180Mjk6CiAgICAgICAgICAgIHByaW1laXJvID0gbWluKGVy
REM cm9zX25hb180MjksIGtleT1sYW1iZGEgeDogeFsiaW5kaWNlIl0pCiAgICAgICAgICAgIHJl
REM c3VsdGFkb19wYXJhZGEgPSB1ImluY29uY2x1c2l2byIKICAgICAgICAgICAgcHJpbnQodSIg
REM IFJFU1VMVEFETzogSU5DT05DTFVTSVZPIOKAlCBlcnJvIG7Do28tNDI5IG5vIHRleHRvIHsw
REM fTogezF9Ii5mb3JtYXQoCiAgICAgICAgICAgICAgICBwcmltZWlyb1siaW5kaWNlIl0sIHBy
REM aW1laXJvWyJlcnJvIl0pKQogICAgICAgICAgICBsb2cuZXJybyh1IlRlc3RlIGluY29uY2x1
REM c2l2byBlbSB7MDouMmZ9cyBwb3IgZXJybyBuw6NvLTQyOSBubyB0ZXh0byB7MX06IHsyfSIu
REM Zm9ybWF0KAogICAgICAgICAgICAgICAgaW50ZXJ2YWxvLCBwcmltZWlyb1siaW5kaWNlIl0s
REM IHByaW1laXJvWyJlcnJvIl0pKQogICAgICAgICAgICBicmVhawoKICAgICAgICBpZiByYXRl
REM X2xpbWl0czoKICAgICAgICAgICAgcHJpbWVpcm8gPSBtaW4ocmF0ZV9saW1pdHMsIGtleT1s
REM YW1iZGEgeDogeC5nZXQoIm1vbWVudG8iLCB4WyJzZWd1bmRvcyJdKSkKICAgICAgICAgICAg
REM cmVzdWx0YWRvX3BhcmFkYSA9IHUiNDI5IgogICAgICAgICAgICBwcmludCh1IiAgUkVTVUxU
REM QURPOiA0MjkgZGV0ZWN0YWRvIHwgdGV4dG8gezB9IHwgV29ya2VyIHsxfSIuZm9ybWF0KAog
REM ICAgICAgICAgICAgICAgcHJpbWVpcm9bImluZGljZSJdLCBwcmltZWlyb1sid29ya2VyIl0p
REM KQogICAgICAgICAgICBwcmludCh1IiAgw5psdGltbyBkZWdyYXUgc2VtIDQyOTogezA6LjJm
REM fXMiLmZvcm1hdCh1bHRpbW9fc2VndXJvKSkKICAgICAgICAgICAgbG9nLmF2aXNvKHUiNDI5
REM IGRldGVjdGFkbyBubyBkZWdyYXUgezA6LjJmfXMsIHRleHRvIHsxfSwgd29ya2VyIHsyfS4g
REM w5psdGltbyBkZWdyYXUgbGltcG86IHszOi4yZn1zIi5mb3JtYXQoCiAgICAgICAgICAgICAg
REM ICBpbnRlcnZhbG8sIHByaW1laXJvWyJpbmRpY2UiXSwgcHJpbWVpcm9bIndvcmtlciJdLCB1
REM bHRpbW9fc2VndXJvKSkKICAgICAgICAgICAgYnJlYWsKCiAgICAgICAgdWx0aW1vX3NlZ3Vy
REM byA9IGludGVydmFsbwogICAgICAgIHRheGEgPSBmbG9hdChvaykgLyBtYXgoMC4wMDEsIGRl
REM Y29ycmlkbykKICAgICAgICBwcmludCh1IiAgUEFTU09VOiB7MH0gdGV4dG9zIHNlbSA0Mjkg
REM fCB7MTouMmZ9cyB8IH57MjouMWZ9IHRleHRvcy9zIi5mb3JtYXQoCiAgICAgICAgICAgIG9r
REM LCBkZWNvcnJpZG8sIHRheGEpKQogICAgICAgIGxvZy5pbmZvKHUiUEFTU09VIGRlZ3JhdSB7
REM MDouMmZ9cyBzZW0gNDI5LiIuZm9ybWF0KGludGVydmFsbykpCgogICAgdG90YWxfZGVjb3Jy
REM aWRvID0gdGltZS5wZXJmX2NvdW50ZXIoKSAtIHRvdGFsX2luaWNpbwogICAgcHJpbnQodSIi
REM KQogICAgcHJpbnQodSJSRVNVTFRBRE8gRklOQUwiKQogICAgcHJpbnQodSIgIMOabHRpbW8g
REM aW50ZXJ2YWxvIGNvbmZpcm1hZG8gc2VtIDQyOTogezA6LjJmfXMiLmZvcm1hdCh1bHRpbW9f
REM c2VndXJvKSkKICAgIGlmIHJlc3VsdGFkb19wYXJhZGEgPT0gdSI0MjkiOgogICAgICAgIHBy
REM aW50KHUiICBPIHByw7N4aW1vIGRlZ3JhdSBhYmFpeG8gZGVzc2UgdmFsb3IgcHJvZHV6aXUg
REM NDI5IG5lc3RhIGV4ZWN1w6fDo28uIikKICAgIGVsaWYgcmVzdWx0YWRvX3BhcmFkYSA9PSB1
REM ImluY29uY2x1c2l2byI6CiAgICAgICAgcHJpbnQodSIgIE8gdGVzdGUgbsOjbyBhdGluZ2l1
REM IHVtYSBjb25jbHVzw6NvIGRlIGxpbWl0ZSBwb3IgY2F1c2EgZGUgdW0gZXJybyBuw6NvLTQy
REM OS4iKQogICAgZWxzZToKICAgICAgICBwcmludCh1IiAgVG9kb3Mgb3MgZGVncmF1cyBkZSAw
REM LDI1cyBhdMOpIDAsMTBzIHBhc3NhcmFtIHNlbSA0MjkgbmVzdGEgZXhlY3XDp8Ojby4iKQog
REM ICAgcHJpbnQodSIgIE8gdmFsb3IgZG8gc2NyaXB0IGNvbnRpbnVhIGNvbmZpZ3VyYWRvIGVt
REM IHswOi4yZn1zOyBlc3RlIGRpYWduw7NzdGljbyBuw6NvIG8gYWx0ZXJhIG5vIGFycXVpdm8u
REM Ii5mb3JtYXQoR09PR0xFX0lOVEVSVkFMT19NSU5JTU8pKQogICAgcHJpbnQodSIgIFRlbXBv
REM IHRvdGFsIGRvIGRpYWduw7NzdGljbzogezA6LjJmfXMiLmZvcm1hdCh0b3RhbF9kZWNvcnJp
REM ZG8pKQogICAgcHJpbnQodSIiKQogICAgcHJpbnQodSJMb2cgc2Fsdm8gZW06IikKICAgIHBy
REM aW50KHUiICB7MH0iLmZvcm1hdChjYW1pbmhvX2xvZykpCiAgICBsb2cucmVzdWx0YWRvKHUi
REM SW50ZXJ2YWxvIGRlIHJlZmVyw6puY2lhIHNlbSA0MjkiLCB1InswOi4yZn1zIi5mb3JtYXQo
REM dWx0aW1vX3NlZ3VybykpCiAgICBsb2cucmVzdWx0YWRvKHUiVGVtcG8gdG90YWwiLCB1Insw
REM Oi4yZn1zIi5mb3JtYXQodG90YWxfZGVjb3JyaWRvKSkKICAgIGxvZy5zZXBhcmFkb3IoKQog
REM ICAgbG9nLnNhbHZhcigpCiAgICByZXR1cm4gMAoKCmRlZiBfZGlhZ25vc3RpY29fcnBjX3Vu
REM aWNvKGNsaWVudGUsIG9yaWdlbSwgZGVzdGlubywgbnVtZXJvKToKICAgIHRleHRvID0gdSJV
REM blJlbi1EREFDIGRpYWduw7NzdGljbyB7MH0iLmZvcm1hdChudW1lcm8pCiAgICBpbmljaW8g
REM PSB0aW1lLnBlcmZfY291bnRlcigpCiAgICB0cnk6CiAgICAgICAgcmVzdWx0YWRvID0gY2xp
REM ZW50ZS50cmFkdXppcih0ZXh0bywgb3JpZ2VtLCBkZXN0aW5vKQogICAgICAgIGRlY29ycmlk
REM byA9IHRpbWUucGVyZl9jb3VudGVyKCkgLSBpbmljaW8KICAgICAgICByZXR1cm4gewogICAg
REM ICAgICAgICAib2siOiBUcnVlLCAiaG9zdCI6IGNsaWVudGUubm9tZV9ob3N0LCAid29ya2Vy
REM IjogY2xpZW50ZS53b3JrZXJfaWQgKyAxLAogICAgICAgICAgICAic2VndW5kb3MiOiBkZWNv
REM cnJpZG8sICJzdGF0dXMiOiBjbGllbnRlLnVsdGltb19zdGF0dXMgb3IgMjAwLAogICAgICAg
REM ICAgICAiYnl0ZXMiOiBjbGllbnRlLnVsdGltb3NfYnl0ZXMsICJ0ZXh0byI6IHJlc3VsdGFk
REM bywKICAgICAgICAgICAgImVycm8iOiBOb25lLAogICAgICAgIH0KICAgIGV4Y2VwdCBFeGNl
REM cHRpb24gYXMgZXhjOgogICAgICAgIGRlY29ycmlkbyA9IHRpbWUucGVyZl9jb3VudGVyKCkg
REM LSBpbmljaW8KICAgICAgICByZXR1cm4gewogICAgICAgICAgICAib2siOiBGYWxzZSwgImhv
REM c3QiOiBjbGllbnRlLm5vbWVfaG9zdCwgIndvcmtlciI6IGNsaWVudGUud29ya2VyX2lkICsg
REM MSwKICAgICAgICAgICAgInNlZ3VuZG9zIjogZGVjb3JyaWRvLCAic3RhdHVzIjogY2xpZW50
REM ZS51bHRpbW9fc3RhdHVzLAogICAgICAgICAgICAiYnl0ZXMiOiBjbGllbnRlLnVsdGltb3Nf
REM Ynl0ZXMsICJ0ZXh0byI6IE5vbmUsCiAgICAgICAgICAgICJlcnJvIjogdSJ7MH06IHsxfSIu
REM Zm9ybWF0KHR5cGUoZXhjKS5fX25hbWVfXywgZXhjKSwKICAgICAgICB9CgoKZGVmIGV4ZWN1
REM dGFyX2RpYWdub3N0aWNvX2dvb2dsZShyYWl6KToKICAgIGNhbWluaG9fbG9nID0gb3MucGF0
REM aC5qb2luKHJhaXosIEdPT0dMRV9DQUNIRV9ESUFHTk9TVElDT19OT01FKQogICAgbG9nID0g
REM TG9nKGNhbWluaG9fbG9nKQogICAgbG9nLnNlcGFyYWRvcigpCiAgICBsb2cudGl0dWxvKHUi
REM RERBQyAtIERpYWduw7NzdGljbyBkbyBHb29nbGUgVHJhbnNsYXRlIikKICAgIGxvZy5pbmZv
REM KHUiVGVzdGUgbGV2ZTogMSBSUEMgaW5kaXZpZHVhbCArIDQgUlBDcyBjb25jb3JyZW50ZXMu
REM IikKICAgIGxvZy5pbmZvKHUiTyB0ZXN0ZSB1c2EgbyBlbmRwb2ludCB3ZWIgaW50ZXJubyBk
REM byBHb29nbGUgVHJhbnNsYXRlIGF0dWFsbWVudGUgdXNhZG8gcGVsbyBtb3Rvci4iKQogICAg
REM cHJpbnQodSI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT0iKQogICAgcHJpbnQodSIgRElBR07Dk1NUSUNPIERPIEdPT0dMRSBU
REM UkFOU0xBVEUiKQogICAgcHJpbnQodSI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iKQogICAgcHJpbnQodSIiKQogICAgcHJp
REM bnQodSJFc3RlIHRlc3RlIG7Do28gYWx0ZXJhIGFycXVpdm9zIGRvIGpvZ28uIikKICAgIHBy
REM aW50KHUiU2Vyw6NvIGZlaXRhcyA1IHRyYWR1w6fDtWVzIHJlYWlzIG5vIGVuZHBvaW50IHBh
REM cmEgbWVkaXIgYSBsYXTDqm5jaWEuIikKICAgIHByaW50KHUiIikKCiAgICBvcmlnZW0gPSB1
REM ImF1dG8iCiAgICBkZXN0aW5vID0gdSJwdC1CUiIKICAgIGNsaWVudGVzID0gW10KICAgIHBy
REM aW50KHUiWzEvMl0gVGVzdGFuZG8gYSBww6FnaW5hIGRvIEdvb2dsZSBUcmFuc2xhdGUuLi4i
REM KQogICAgZm9yIHdvcmtlciBpbiByYW5nZSg0KToKICAgICAgICBub21lLCBob3N0ID0gR09P
REM R0xFX0hPU1RTW3dvcmtlciAlIGxlbihHT09HTEVfSE9TVFMpXQogICAgICAgIGNsaWVudGUg
REM PSBHb29nbGVSUENDbGllbnQobm9tZSwgaG9zdCwgbG9nLCB3b3JrZXIpCiAgICAgICAgaW5p
REM Y2lvID0gdGltZS5wZXJmX2NvdW50ZXIoKQogICAgICAgIHRyeToKICAgICAgICAgICAgY2xp
REM ZW50ZS5jb25lY3RhcigpCiAgICAgICAgICAgIGRlY29ycmlkbyA9IHRpbWUucGVyZl9jb3Vu
REM dGVyKCkgLSBpbmljaW8KICAgICAgICAgICAgY2xpZW50ZXMuYXBwZW5kKGNsaWVudGUpCiAg
REM ICAgICAgICAgIHByaW50KHUiICBXb3JrZXIgezB9IHwgezE6PDEyfSB8IEhPTUUgezI6Ni4y
REM Zn1zIHwgSFRUUCB7M30gfCBmLnNpZCB7NH0gfCBibCB7NX0iLmZvcm1hdCgKICAgICAgICAg
REM ICAgICAgIHdvcmtlciArIDEsIG5vbWUsIGRlY29ycmlkbywgY2xpZW50ZS51bHRpbW9fc3Rh
REM dHVzIG9yIDIwMCwKICAgICAgICAgICAgICAgIHUiT0siIGlmIGNsaWVudGUuZnNpZCBlbHNl
REM IHUibsOjbyIsIHUiZGluw6JtaWNvIiBpZiBjbGllbnRlLmJsICE9IEdPT0dMRV9TVEFUSUNf
REM QkwgZWxzZSB1ImVzdMOhdGljbyIpKQogICAgICAgICAgICBsb2cuaW5mbyh1IkhPTUUgd29y
REM a2VyPXswfSBob3N0PXsxfSB0ZW1wbz17MjouM2Z9cyBzdGF0dXM9ezN9IGZzaWQ9ezR9IGJs
REM PXs1fSIuZm9ybWF0KAogICAgICAgICAgICAgICAgd29ya2VyICsgMSwgbm9tZSwgZGVjb3Jy
REM aWRvLCBjbGllbnRlLnVsdGltb19zdGF0dXMgb3IgMjAwLAogICAgICAgICAgICAgICAgdSJz
REM aW0iIGlmIGNsaWVudGUuZnNpZCBlbHNlIHUibsOjbyIsIHUiZGluw6JtaWNvIiBpZiBjbGll
REM bnRlLmJsICE9IEdPT0dMRV9TVEFUSUNfQkwgZWxzZSB1ImVzdMOhdGljbyIpKQogICAgICAg
REM IGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAgICAgICAgICBkZWNvcnJpZG8gPSB0aW1l
REM LnBlcmZfY291bnRlcigpIC0gaW5pY2lvCiAgICAgICAgICAgIHByaW50KHUiICBXb3JrZXIg
REM ezB9IHwgezE6PDEyfSB8IEhPTUUgRkFMSE9VIGVtIHsyOi4yZn1zIHwgezN9Ii5mb3JtYXQo
REM d29ya2VyICsgMSwgbm9tZSwgZGVjb3JyaWRvLCBleGMpKQogICAgICAgICAgICBsb2cuZXJy
REM byh1IkhPTUUgd29ya2VyPXswfSBob3N0PXsxfSB0ZW1wbz17MjouM2Z9cyBlcnJvPXszfSIu
REM Zm9ybWF0KHdvcmtlciArIDEsIG5vbWUsIGRlY29ycmlkbywgZXhjKSkKCiAgICBpZiBub3Qg
REM Y2xpZW50ZXM6CiAgICAgICAgcHJpbnQodSIiKQogICAgICAgIHByaW50KHUiTmVuaHVtYSBz
REM ZXNzw6NvIEdvb2dsZSBww7RkZSBzZXIgcHJlcGFyYWRhLiIpCiAgICAgICAgbG9nLnNhbHZh
REM cigpCiAgICAgICAgcmV0dXJuIDEKCiAgICBwcmludCh1IiIpCiAgICBwcmludCh1IlsyLzJd
REM IFRlc3RhbmRvIG8gZW5kcG9pbnQgUkVBTCBkZSB0cmFkdcOnw6NvLi4uIikKICAgIGJhc2Ug
REM PSBfZGlhZ25vc3RpY29fcnBjX3VuaWNvKGNsaWVudGVzWzBdLCBvcmlnZW0sIGRlc3Rpbm8s
REM IDEpCiAgICBpZiBiYXNlWyJvayJdOgogICAgICAgIHByaW50KHUiICBSUEMgaW5kaXZpZHVh
REM bCB8IHswOjwxMn0gfCB7MTo2LjJmfXMgfCBIVFRQIHsyfSB8IHJlc3Bvc3RhIHszfSBieXRl
REM cyIuZm9ybWF0KAogICAgICAgICAgICBiYXNlWyJob3N0Il0sIGJhc2VbInNlZ3VuZG9zIl0s
REM IGJhc2VbInN0YXR1cyJdLCBiYXNlWyJieXRlcyJdKSkKICAgIGVsc2U6CiAgICAgICAgcHJp
REM bnQodSIgIFJQQyBpbmRpdmlkdWFsIHwgezA6PDEyfSB8IEZBTEhPVSBhcMOzcyB7MTo2LjJm
REM fXMgfCB7Mn0iLmZvcm1hdCgKICAgICAgICAgICAgYmFzZVsiaG9zdCJdLCBiYXNlWyJzZWd1
REM bmRvcyJdLCBiYXNlWyJlcnJvIl0pKQogICAgbG9nLmluZm8odSJSUEMgaW5kaXZpZHVhbCBo
REM b3N0PXswfSB0ZW1wbz17MTouM2Z9cyBzdGF0dXM9ezJ9IG9rPXszfSBlcnJvPXs0fSIuZm9y
REM bWF0KAogICAgICAgIGJhc2VbImhvc3QiXSwgYmFzZVsic2VndW5kb3MiXSwgYmFzZVsic3Rh
REM dHVzIl0sIGJhc2VbIm9rIl0sIGJhc2VbImVycm8iXSBvciB1Ii0iKSkKCiAgICBpbmljaW9f
REM Y29uYyA9IHRpbWUucGVyZl9jb3VudGVyKCkKICAgIHJlc3VsdGFkb3MgPSBbXQogICAgd2l0
REM aCBUaHJlYWRQb29sRXhlY3V0b3IobWF4X3dvcmtlcnM9bGVuKGNsaWVudGVzKSkgYXMgZXhl
REM Y3V0b3I6CiAgICAgICAgZnV0dXJvcyA9IFtleGVjdXRvci5zdWJtaXQoX2RpYWdub3N0aWNv
REM X3JwY191bmljbywgY2xpZW50ZSwgb3JpZ2VtLCBkZXN0aW5vLCBpICsgMikgZm9yIGksIGNs
REM aWVudGUgaW4gZW51bWVyYXRlKGNsaWVudGVzKV0KICAgICAgICBmb3IgZnV0dXJvIGluIGFz
REM X2NvbXBsZXRlZChmdXR1cm9zKToKICAgICAgICAgICAgcmVzdWx0YWRvcy5hcHBlbmQoZnV0
REM dXJvLnJlc3VsdCgpKQogICAgdGVtcG9fb25kYSA9IHRpbWUucGVyZl9jb3VudGVyKCkgLSBp
REM bmljaW9fY29uYwogICAgcmVzdWx0YWRvcy5zb3J0KGtleT1sYW1iZGEgaXRlbTogaXRlbVsi
REM d29ya2VyIl0pCgogICAgcHJpbnQodSIiKQogICAgcHJpbnQodSIgIENvbmNvcnLDqm5jaWE6
REM IHswfSByZXF1aXNpw6fDtWVzIHNpbXVsdMOibmVhcyB8IG9uZGEgezE6LjJmfXMiLmZvcm1h
REM dChsZW4ocmVzdWx0YWRvcyksIHRlbXBvX29uZGEpKQogICAgZm9yIHIgaW4gcmVzdWx0YWRv
REM czoKICAgICAgICBpZiByWyJvayJdOgogICAgICAgICAgICBwcmludCh1IiAgICBXb3JrZXIg
REM ezB9IHwgezE6PDEyfSB8IHsyOjYuMmZ9cyB8IEhUVFAgezN9Ii5mb3JtYXQoclsid29ya2Vy
REM Il0sIHJbImhvc3QiXSwgclsic2VndW5kb3MiXSwgclsic3RhdHVzIl0pKQogICAgICAgIGVs
REM c2U6CiAgICAgICAgICAgIHByaW50KHUiICAgIFdvcmtlciB7MH0gfCB7MTo8MTJ9IHwgRkFM
REM SE9VIHsyOjYuMmZ9cyB8IHszfSIuZm9ybWF0KHJbIndvcmtlciJdLCByWyJob3N0Il0sIHJb
REM InNlZ3VuZG9zIl0sIHJbImVycm8iXSkpCiAgICAgICAgbG9nLmluZm8odSJSUEMgY29uY29y
REM cmVudGUgd29ya2VyPXswfSBob3N0PXsxfSB0ZW1wbz17MjouM2Z9cyBzdGF0dXM9ezN9IG9r
REM PXs0fSBlcnJvPXs1fSIuZm9ybWF0KAogICAgICAgICAgICByWyJ3b3JrZXIiXSwgclsiaG9z
REM dCJdLCByWyJzZWd1bmRvcyJdLCByWyJzdGF0dXMiXSwgclsib2siXSwgclsiZXJybyJdIG9y
REM IHUiLSIpKQoKICAgIHN1Y2Vzc29zID0gW3IgZm9yIHIgaW4gcmVzdWx0YWRvcyBpZiByWyJv
REM ayJdXQogICAgaWYgYmFzZVsib2siXSBhbmQgc3VjZXNzb3M6CiAgICAgICAgbWVub3IgPSBt
REM aW4oclsic2VndW5kb3MiXSBmb3IgciBpbiBzdWNlc3NvcykKICAgICAgICBtYWlvciA9IG1h
REM eChyWyJzZWd1bmRvcyJdIGZvciByIGluIHN1Y2Vzc29zKQogICAgICAgIG1lZGlhID0gc3Vt
REM KHJbInNlZ3VuZG9zIl0gZm9yIHIgaW4gc3VjZXNzb3MpIC8gbGVuKHN1Y2Vzc29zKQogICAg
REM ICAgIHByaW50KHUiIikKICAgICAgICBwcmludCh1IlJFU1VMVEFETyIpCiAgICAgICAgcHJp
REM bnQodSIgIFJQQyBpbmRpdmlkdWFsOiB7MDouMmZ9cyIuZm9ybWF0KGJhc2VbInNlZ3VuZG9z
REM Il0pKQogICAgICAgIHByaW50KHUiICBSUEMgY29uY29ycmVudGU6IG1pbiB7MDouMmZ9cyB8
REM IG3DqWRpYSB7MTouMmZ9cyB8IG3DoXggezI6LjJmfXMiLmZvcm1hdChtZW5vciwgbWVkaWEs
REM IG1haW9yKSkKICAgICAgICBpZiBiYXNlWyJzZWd1bmRvcyJdID49IDUuMDoKICAgICAgICAg
REM ICAgcHJpbnQodSIgIElORMONQ0lPOiB1bWEgw7puaWNhIHJlcXVpc2nDp8OjbyBqw6EgZXN0
REM w6EgbGVudGE7IG8gZ2FyZ2FsbyBlc3TDoSBubyBjYW1pbmhvIGRvIFJQQy9Hb29nbGUsIG7D
REM o28gbmEgYmFycmEgZGUgcHJvZ3Jlc3NvIGRvIHNjcmlwdC4iKQogICAgICAgIGVsaWYgbWFp
REM b3IgPj0gbWF4KDUuMCwgYmFzZVsic2VndW5kb3MiXSAqIDIuMCk6CiAgICAgICAgICAgIHBy
REM aW50KHUiICBJTkTDjUNJTzogYSBsYXTDqm5jaWEgY3Jlc2NlIGJhc3RhbnRlIGNvbSBjb25j
REM b3Jyw6puY2lhOyBow6EgcG9zc8OtdmVsIGNvbnRlbsOnw6NvL3Rocm90dGxpbmcgbm8gZW5k
REM cG9pbnQuIikKICAgICAgICBlbHNlOgogICAgICAgICAgICBwcmludCh1IiAgSU5Ew41DSU86
REM IGEgbGF0w6puY2lhIGRvIFJQQyBlc3TDoSBiYWl4YSBlIHJlbGF0aXZhbWVudGUgZXN0w6F2
REM ZWw7IG8gcHJvYmxlbWEgcG9kZSBlc3RhciBhbMOpbSBkZXN0ZSB0ZXN0ZS4iKQogICAgZWxp
REM ZiBub3QgYmFzZVsib2siXToKICAgICAgICBwcmludCh1IiIpCiAgICAgICAgcHJpbnQodSIg
REM IElORMONQ0lPOiBhIHJlcXVpc2nDp8OjbyByZWFsIGRlIHRyYWR1w6fDo28gZmFsaG91OyBv
REM IHRlc3RlIGRhIHDDoWdpbmEgaW5pY2lhbCwgc296aW5obywgbsOjbyBnYXJhbnRlIHF1ZSBv
REM IGVuZHBvaW50IGRlIHRyYWR1w6fDo28gZXN0ZWphIHNhdWTDoXZlbC4iKQogICAgZWxzZToK
REM ICAgICAgICBwcmludCh1IiIpCiAgICAgICAgcHJpbnQodSIgIE5lbmh1bSBSUEMgY29uY29y
REM cmVudGUgcmV0b3Jub3Ugc3VjZXNzby4iKQoKICAgIHByaW50KHUiIikKICAgIHByaW50KHUi
REM TG9nIHNhbHZvIGVtOiIpCiAgICBwcmludCh1IiAgezB9Ii5mb3JtYXQoY2FtaW5ob19sb2cp
REM KQogICAgbG9nLnNhbHZhcigpCiAgICByZXR1cm4gMAoKCmRlZiB0ZXN0YXJfY29uZXhhb19n
REM b29nbGUobG9nPU5vbmUpOgogICAgIyBBcGVuYXMgYWJyZSBhIGhvbWUgZG8gR29vZ2xlIFRy
REM YW5zbGF0ZTsgbsOjbyBjb25zb21lIHVtYSB0cmFkdcOnw6NvLgogICAgcG9vbD1jcmlhcl9w
REM b29sX2dvb2dsZShsb2cpCiAgICByZXR1cm4gcG9vbAoKCmRlZiBleGVjdXRhcl90cmFkdWNh
REM b19nb29nbGUocmFpeik6CiAgICBpbmljaW9fdG90YWw9dGltZS50aW1lKCkKICAgIHBhc3Rh
REM X2VudHJhZGEsbm9tZV9tYXBhPWxvY2FsaXphcl9wYXN0YV9leHRyYWNhb190cmFkdWNhbyhy
REM YWl6KQogICAgaWYgbm90IHBhc3RhX2VudHJhZGE6CiAgICAgICAgcHJpbnQodCgidF9zZW1f
REM ZXh0cmFjYW8iKSk7IHJldHVybiAxCiAgICBjYW1pbmhvX21hcGE9b3MucGF0aC5qb2luKHBh
REM c3RhX2VudHJhZGEsbm9tZV9tYXBhKQogICAgdHJ5OgogICAgICAgIHdpdGggaW8ub3Blbihj
REM YW1pbmhvX21hcGEsInIiLGVuY29kaW5nPSJ1dGYtOCIpIGFzIGY6IG1hcGFfY29tcGxldG89
REM anNvbi5sb2FkKGYpCiAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICBwcmlu
REM dCh0KCJ0X21hcGFfaW52YWxpZG8iKS5mb3JtYXQoZXhjKSk7IHJldHVybiAxCiAgICB0cnk6
REM CiAgICAgICAgb3JpZ2VtPW5vcm1hbGl6YXJfaWRpb21hX2NvZGlnbyhpbnB1dCh0KCJ0X29y
REM aWdlbV9wcm9tcHQiKSkuc3RyaXAoKSx1ImF1dG8iKQogICAgICAgIGRlc3Rpbm89bm9ybWFs
REM aXphcl9pZGlvbWFfY29kaWdvKGlucHV0KHQoInRfZGVzdGlub19wcm9tcHQiKSkuc3RyaXAo
REM KSx1InB0LUJSIikKICAgIGV4Y2VwdCAoRU9GRXJyb3IsS2V5Ym9hcmRJbnRlcnJ1cHQpOgog
REM ICAgICAgIHByaW50KHQoInRfY2FuY2VsYWRvIikpOyByZXR1cm4gMAogICAgaWYgbm90IHZh
REM bGlkYXJfY29kaWdvX2lkaW9tYShvcmlnZW0pIG9yIG5vdCB2YWxpZGFyX2NvZGlnb19pZGlv
REM bWEoZGVzdGlubykgb3IgZGVzdGlubz09dSJhdXRvIjoKICAgICAgICBwcmludCh0KCJ0X2Vy
REM cm9fY29uZXhhbyIpLmZvcm1hdCh1ImPDs2RpZ28gZGUgaWRpb21hIGludsOhbGlkbzogb3Jp
REM Z2VtPXswfSwgZGVzdGlubz17MX0iLmZvcm1hdChvcmlnZW0sZGVzdGlubykpKTsgcmV0dXJu
REM IDEKCiAgICB0b3RhbF9nbG9iYWw9c3VtKGxlbih2KSBmb3IgXyx2IGluIHNvcnRlZChtYXBh
REM X2NvbXBsZXRvLml0ZW1zKCkpKQogICAgbG9nPUxvZyhvcy5wYXRoLmpvaW4ocmFpeixOT01F
REM X0xPR19UUkFEVVRPUikpOyBsb2cuc2VwYXJhZG9yKCk7IGxvZy50aXR1bG8odSJEREFDIFRy
REM YWR1w6fDo28gY29tIEdvb2dsZSBUcmFuc2xhdGUgV2ViIFJQQyAtIElOw41DSU8gREEgRVhF
REM Q1XDh8ODTyIpCiAgICBsb2cuaW5mbyh0KCJ0X2xvZ19wYXN0YSIpLmZvcm1hdChwYXN0YV9l
REM bnRyYWRhKSk7IHBhc3RhX3NhaWRhPW9zLnBhdGguam9pbihyYWl6LFBBU1RBX1RSQURVQ0FP
REM X0dPT0dMRV9OT01FKTsgbG9nLmluZm8odCgidF9sb2dfc2FpZGEiKS5mb3JtYXQocGFzdGFf
REM c2FpZGEpKQogICAgbG9nLmluZm8odSJJZGlvbWEgZGUgb3JpZ2VtOiB7MH0gfCBpZGlvbWEg
REM ZGUgZGVzdGlubzogezF9Ii5mb3JtYXQob3JpZ2VtLGRlc3Rpbm8pKQogICAgbG9nLmluZm8o
REM dSJNYXBhIG7Do28gw6kgdHJhZHV6aWRvOyBzb21lbnRlIHRleHRvcyBhcG9udGFkb3MgcG9y
REM IGVsZSBzw6NvIHByb2Nlc3NhZG9zLiIpCiAgICBsb2cuaW5mbyh1Ik1vdG9yIEdvb2dsZTog
REM R29vZ2xlIFRyYW5zbGF0ZSBXZWIgKFJQQykgfCB7MH0gd29ya2VycyB8IGphbmVsYSBkaW7D
REM om1pY2EgezF9IHRhcmVmYXMgfCBibG9jb3MgZGUgZXNjYWxvbmFtZW50byBkZSB7Mn0gZW50
REM cmFkYXMgfCBpbnRlcnZhbG8gZ2xvYmFsIG3DrW5pbW8gZGUgezM6LjJmfXMgfCBjb29sZG93
REM biBjcmVzY2VudGUgZW0gNDI5LiBQYXJhbGVsaXNtbyBkaXN0cmlidcOtZG8gZW50cmUgYXJx
REM dWl2b3MsIGZpbGEgZGluw6JtaWNhLCBjYWNoZSBwZXJzaXN0ZW50ZSBlIGF1ZGl0b3JpYSBm
REM aW5hbCBpbmRlcGVuZGVudGUuIi5mb3JtYXQoR09PR0xFX1dPUktFUlMsIEdPT0dMRV9XT1JL
REM RVJTKkdPT0dMRV9KT0JfV0lORE9XX01VTFRJUExJRVIsIEdPT0dMRV9TQ0hFRFVMRVJfQ0hV
REM TkssIEdPT0dMRV9JTlRFUlZBTE9fTUlOSU1PKSkKCiAgICB0cnk6CiAgICAgICAgcG9vbD10
REM ZXN0YXJfY29uZXhhb19nb29nbGUobG9nKQogICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6
REM CiAgICAgICAgbG9nLmVycm8odSJUZXN0ZSBkZSBjb25leMOjbzogezB9Ii5mb3JtYXQoZXhj
REM KSk7IGxvZy5zYWx2YXIoKTsgcHJpbnQodCgidF9lcnJvX2NvbmV4YW8iKS5mb3JtYXQoZXhj
REM KSk7IHJldHVybiAxCiAgICBwcmludCh0KCJ0X2NvbmVjdGFkbyIpKTsgcHJpbnQodCgidF9w
REM cm9jZXNzYW5kbyIpLmZvcm1hdCh0b3RhbF9nbG9iYWwpKQoKICAgIHBhc3RhX3NhaWRhX3Jl
REM YWw9b3MucGF0aC5yZWFscGF0aChwYXN0YV9zYWlkYSkKICAgIHJhaXpfcmVhbD1vcy5wYXRo
REM LnJlYWxwYXRoKHJhaXopCiAgICBlc3BlcmFkb19zYWlkYT1vcy5wYXRoLnJlYWxwYXRoKG9z
REM LnBhdGguam9pbihyYWl6X3JlYWwsIFBBU1RBX1RSQURVQ0FPX0dPT0dMRV9OT01FKSkKICAg
REM IGlmIHBhc3RhX3NhaWRhX3JlYWwgIT0gZXNwZXJhZG9fc2FpZGEgb3Igb3MucGF0aC5kaXJu
REM YW1lKHBhc3RhX3NhaWRhX3JlYWwpICE9IHJhaXpfcmVhbCBvciBvcy5wYXRoLmJhc2VuYW1l
REM KHBhc3RhX3NhaWRhX3JlYWwpICE9IFBBU1RBX1RSQURVQ0FPX0dPT0dMRV9OT01FOgogICAg
REM ICAgIHJhaXNlIFJ1bnRpbWVFcnJvcih1IkJsb3F1ZWlvIGRlIHNlZ3VyYW7Dp2E6IGEgcGFz
REM dGEgZGUgc2HDrWRhIGRhIHRyYWR1w6fDo28gbsOjbyBjb3JyZXNwb25kZSBhbyBkaXJldMOz
REM cmlvIEREQUMgZXNwZXJhZG8uIikKICAgIGlmIG9zLnBhdGguaXNkaXIocGFzdGFfc2FpZGEp
REM OgogICAgICAgIHNodXRpbC5ybXRyZWUocGFzdGFfc2FpZGEpCiAgICBzaHV0aWwuY29weXRy
REM ZWUocGFzdGFfZW50cmFkYSxwYXN0YV9zYWlkYSkKCiAgICAjIENhY2hlIHRlbXBvcsOhcmlv
REM IGRlIHJldG9tYWRhOiBOw4NPIGFwYWdhciBubyBpbsOtY2lvLiBBIFYxMjQgYXBhZ2F2YSBv
REM CiAgICAjIHByw7NwcmlvIGNhY2hlIGFudGVzIGRlIGNhcnJlZ8OhLWxvLCBpbXBlZGluZG8g
REM YSByZXRvbWFkYSByZWFsLgogICAgY2FjaGVfdGVtcF9wYXRoPW9zLnBhdGguam9pbihyYWl6
REM LCBHT09HTEVfQ0FDSEVfTk9NRSkKICAgIGNhY2hlX2Rpcl9wZXJzaXN0ZW50ZT1vcy5wYXRo
REM LmpvaW4ocmFpeiwgR09PR0xFX0NBQ0hFX1BFUlNJU1RFTlRFX0RJUikKICAgIGNhY2hlX3Bl
REM cnNpc3RlbnRlX3BhdGg9b3MucGF0aC5qb2luKGNhY2hlX2Rpcl9wZXJzaXN0ZW50ZSwgR09P
REM R0xFX0NBQ0hFX1BFUlNJU1RFTlRFX05PTUUpCiAgICBpZiBub3Qgb3MucGF0aC5pc2Rpcihv
REM cy5wYXRoLmRpcm5hbWUoY2FjaGVfdGVtcF9wYXRoKSk6CiAgICAgICAgb3MubWFrZWRpcnMo
REM b3MucGF0aC5kaXJuYW1lKGNhY2hlX3RlbXBfcGF0aCkpCiAgICBpZiBub3Qgb3MucGF0aC5p
REM c2RpcihjYWNoZV9kaXJfcGVyc2lzdGVudGUpOgogICAgICAgIG9zLm1ha2VkaXJzKGNhY2hl
REM X2Rpcl9wZXJzaXN0ZW50ZSkKCiAgICBtb2RvX2NhY2hlPW9zLmVudmlyb24uZ2V0KCJEREFD
REM X0dUX0NBQ0hFX01PREUiLCAidXNhciIpLnN0cmlwKCkubG93ZXIoKQogICAgaWYgbW9kb19j
REM YWNoZSBpbiAodSJjbGVhciIsdSJsaW1wYXIiLHUiMyIpOgogICAgICAgIHRyeToKICAgICAg
REM ICAgICAgaWYgb3MucGF0aC5pc2ZpbGUoY2FjaGVfcGVyc2lzdGVudGVfcGF0aCk6IG9zLnJl
REM bW92ZShjYWNoZV9wZXJzaXN0ZW50ZV9wYXRoKQogICAgICAgICAgICBpZiBvcy5wYXRoLmlz
REM ZmlsZShjYWNoZV9wZXJzaXN0ZW50ZV9wYXRoK3UiLnRtcCIpOiBvcy5yZW1vdmUoY2FjaGVf
REM cGVyc2lzdGVudGVfcGF0aCt1Ii50bXAiKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246IHBh
REM c3MKICAgICAgICBtb2RvX2NhY2hlPXUidXNhciIKICAgIHVzYXJfY2FjaGVfcGVyc2lzdGVu
REM dGUgPSBtb2RvX2NhY2hlIG5vdCBpbiAodSJpZ25vcmUiLHUiaWdub3JhciIsdSIwIix1Im5h
REM byIsdSJuw6NvIikKICAgIGNhY2hlX3BlcnNpc3RlbnRlPWNhcnJlZ2FyX2NhY2hlX2dvb2ds
REM ZShjYWNoZV9wZXJzaXN0ZW50ZV9wYXRoKSBpZiB1c2FyX2NhY2hlX3BlcnNpc3RlbnRlIGVs
REM c2Uge30KICAgIGNhY2hlX3RlbXA9Y2FycmVnYXJfY2FjaGVfZ29vZ2xlKGNhY2hlX3RlbXBf
REM cGF0aCkKICAgIGNhY2hlPXt9CiAgICBjYWNoZS51cGRhdGUoY2FjaGVfcGVyc2lzdGVudGUp
REM OyBjYWNoZS51cGRhdGUoY2FjaGVfdGVtcCkKICAgIGNhY2hlX2xvY2s9dGhyZWFkaW5nLkxv
REM Y2soKQoKICAgIGlmIHVzYXJfY2FjaGVfcGVyc2lzdGVudGU6CiAgICAgICAgbG9nLmluZm8o
REM dSJDYWNoZSBwZXJzaXN0ZW50ZSBBVElWTzogezB9Ii5mb3JtYXQoY2FjaGVfcGVyc2lzdGVu
REM dGVfcGF0aCkpCiAgICBlbHNlOgogICAgICAgIGxvZy5pbmZvKHUiQ2FjaGUgcGVyc2lzdGVu
REM dGUgSUdOT1JBRE8gbmVzdGEgZXhlY3XDp8Ojby4gUGFyYSB1c2FyIG5vdmFtZW50ZSwgcmVt
REM b3ZhIEREQUNfR1RfQ0FDSEVfTU9ERT1pZ25vcmUgZG8gYW1iaWVudGUuIikKICAgIGlmIGNh
REM Y2hlX3RlbXA6CiAgICAgICAgbG9nLmluZm8odSJDYWNoZSBkZSByZXRvbWFkYSBlbmNvbnRy
REM YWRvOiB7MH0gZW50cmFkYShzKSB2w6FsaWRhcyBjYXJyZWdhZGFzIGRlIHsxfS4iLmZvcm1h
REM dChsZW4oY2FjaGVfdGVtcCksIGNhY2hlX3RlbXBfcGF0aCkpCgogICAgYXJxdWl2b3M9W10K
REM ICAgIGZpbGFzPXt9CiAgICB0b3RhbF9jYWNoZV9yZXV0aWxpemFkbz0wCiAgICB0b3RhbF9w
REM ZXJzaXN0ZW50ZV9yZXV0aWxpemFkbz0wCiAgICB0b3RhbF90ZW1wX3JldXRpbGl6YWRvPTAK
REM ICAgIHRvdGFsX3VybHNfcHJlc2VydmFkYXM9MAogICAgdG90YWxfZ2xvYmFsX2RvbmU9MAoK
REM ICAgIGZvciByZWwsZW50cmFkYXMgaW4gc29ydGVkKG1hcGFfY29tcGxldG8uaXRlbXMoKSk6
REM CiAgICAgICAgY2FtaW5obz1vcy5wYXRoLmpvaW4ocGFzdGFfc2FpZGEscmVsLnJlcGxhY2Uo
REM dSIvIixvcy5zZXApKQogICAgICAgIGluaWNpb19wcmU9dGltZS50aW1lKCkKICAgICAgICB0
REM cnk6CiAgICAgICAgICAgIHdpdGggaW8ub3BlbihjYW1pbmhvLCJyIixlbmNvZGluZz0idXRm
REM LTgiLGVycm9ycz0icmVwbGFjZSIsbmV3bGluZT0iIikgYXMgZjoKICAgICAgICAgICAgICAg
REM IGxpbmhhcz1mLnJlYWQoKS5zcGxpdGxpbmVzKFRydWUpCiAgICAgICAgICAgIGluZGljZXM9
REM W2kgZm9yIGksbGluaGEgaW4gZW51bWVyYXRlKGxpbmhhcykgaWYgbGluaGEuc3RyaXAoKSBh
REM bmQgbm90IGxpbmhhLnN0cmlwKCkuc3RhcnRzd2l0aCh1IiMiKV0KICAgICAgICAgICAgaWYg
REM bGVuKGluZGljZXMpIT1sZW4oZW50cmFkYXMpOgogICAgICAgICAgICAgICAgcmFpc2UgVmFs
REM dWVFcnJvcih1ImNvbnRhZ2VtIGRvIGFycXVpdm8gKHswfSkgZGlmZXJlbnRlIGRvIG1hcGEg
REM KHsxfSkiLmZvcm1hdChsZW4oaW5kaWNlcyksbGVuKGVudHJhZGFzKSkpCiAgICAgICAgICAg
REM IGZvbnRlcz1bXQogICAgICAgICAgICB0aXBvcz1bXQogICAgICAgICAgICBjb25maWdfcHJv
REM dD1bXQogICAgICAgICAgICByZXN1bHRhZG9zPVtOb25lXSpsZW4oaW5kaWNlcykKICAgICAg
REM ICAgICAgcGVuZGVudGVzPVtdCiAgICAgICAgICAgIGZvciBvcmRlbSxpIGluIGVudW1lcmF0
REM ZShpbmRpY2VzKToKICAgICAgICAgICAgICAgIGxpdGVyYWxfb3JpZ2VtPWxpbmhhc1tpXS5z
REM dHJpcCgpCiAgICAgICAgICAgICAgICBpZiBub3QgbGl0ZXJhbF91bmljb190cmFkdXppdmVs
REM KGxpdGVyYWxfb3JpZ2VtKToKICAgICAgICAgICAgICAgICAgICByYWlzZSBWYWx1ZUVycm9y
REM KHUiZW50cmFkYSBkbyBtYXBhIG7Do28gw6kgdW0gbGl0ZXJhbCDDum5pY28gbmEgbGluaGEg
REM ezB9OiB7MX0iLmZvcm1hdChpKzEsbGl0ZXJhbF9vcmlnZW0pKQogICAgICAgICAgICAgICAg
REM Zm9udGU9ZGVjb2RpZmljYXJfbGl0ZXJhbF90cmFkdWNhbyhsaXRlcmFsX29yaWdlbSkKICAg
REM ICAgICAgICAgICAgIGZvbnRlcy5hcHBlbmQodGV4dG9fY29tcGF0aXZlbChmb250ZSx1IiIp
REM KQogICAgICAgICAgICAgICAgZW50cmFkYT1lbnRyYWRhc1tvcmRlbV0KICAgICAgICAgICAg
REM ICAgIHRpcG9fYnJ1dG89ZW50cmFkYS5nZXQoInRpcG8iKSBpZiBpc2luc3RhbmNlKGVudHJh
REM ZGEsZGljdCkgZWxzZSBOb25lCiAgICAgICAgICAgICAgICB0aXBvX3NlZ3Vybz10ZXh0b19j
REM b21wYXRpdmVsKHRpcG9fYnJ1dG8sdSIiKQogICAgICAgICAgICAgICAgdGlwb3MuYXBwZW5k
REM KHRpcG9fc2VndXJvKQogICAgICAgICAgICAgICAgY29uZmlnX3Byb3QuYXBwZW5kKGVudHJh
REM ZGFfZWhfY29uZmlnX25hbWVfZ2xvYmFsKGVudHJhZGEpKQogICAgICAgICAgICBmb3IgaSxm
REM b250ZSBpbiBlbnVtZXJhdGUoZm9udGVzKToKICAgICAgICAgICAgICAgIGVudHJhZGFfbWV0
REM YT1lbnRyYWRhc1tpXSBpZiBpc2luc3RhbmNlKGVudHJhZGFzW2ldLGRpY3QpIGVsc2Uge30K
REM ICAgICAgICAgICAgICAgICMgQmxvY29zIGRlIGNyw6lkaXRvcyB1c2FtIHVtYSBjaGF2ZSBk
REM ZSBjYWNoZSBwcsOzcHJpYS4gQSBWMTM4CiAgICAgICAgICAgICAgICAjIGZvcsOnYXZhIHRv
REM ZG9zIG9zIGNyw6lkaXRvcyBkZSB2b2x0YSDDoCBmaWxhIGVtIHRvZGEgZXhlY3XDp8Ojbzsg
REM aXNzbwogICAgICAgICAgICAgICAgIyBkZWl4YXZhIDE1LTIwIGVudHJhZGFzICJub3ZhcyIg
REM bWVzbW8gZGVwb2lzIGRlIHRyYWR1emlkYXMuCiAgICAgICAgICAgICAgICAjIEFnb3JhIGVs
REM ZXMgc8OjbyBwcm9jZXNzYWRvcyB1bWEgdmV6IGUgcmVhcHJvdmVpdGFkb3Mgbm9ybWFsbWVu
REM dGUuCiAgICAgICAgICAgICAgICBpZiBwYXJlY2VfYmxvY29fY3JlZGl0b3NfZ29vZ2xlKGZv
REM bnRlLCByZWwsIHRpcG9zW2ldKToKICAgICAgICAgICAgICAgICAgICB0aXBvc1tpXT11InRl
REM eHRvX2NyZWRpdG9zX2Jsb2NvIgogICAgICAgICAgICAgICAgICAgIGNoYXZlX2NyZWRpdG89
REM Y2hhdmVfY2FjaGVfY3JlZGl0b19nb29nbGUob3JpZ2VtLGRlc3Rpbm8sZm9udGUpCiAgICAg
REM ICAgICAgICAgICAgICAgdmFsb3JfY3JlZGl0bz1jYWNoZV9jcmVkaXRvX2dvb2dsZV9wb2Rl
REM X3JldXRpbGl6YXIoY2FjaGUsY2hhdmVfY3JlZGl0byxmb250ZSxkZXN0aW5vKQogICAgICAg
REM ICAgICAgICAgICAgIGlmIHZhbG9yX2NyZWRpdG8gaXMgbm90IE5vbmU6CiAgICAgICAgICAg
REM ICAgICAgICAgICAgIHJlc3VsdGFkb3NbaV09bm9ybWFsaXphcl9lc3BhY29zX3Bvc19wb250
REM dWFjYW9fZ29vZ2xlKGZvbnRlLHZhbG9yX2NyZWRpdG8pCiAgICAgICAgICAgICAgICAgICAg
REM ICAgIHRvdGFsX2dsb2JhbF9kb25lKz0xOyB0b3RhbF9jYWNoZV9yZXV0aWxpemFkbys9MQog
REM ICAgICAgICAgICAgICAgICAgICAgICBpZiBjaGF2ZV9jcmVkaXRvIGluIGNhY2hlX3BlcnNp
REM c3RlbnRlOiB0b3RhbF9wZXJzaXN0ZW50ZV9yZXV0aWxpemFkbys9MQogICAgICAgICAgICAg
REM ICAgICAgICAgICBlbGlmIGNoYXZlX2NyZWRpdG8gaW4gY2FjaGVfdGVtcDogdG90YWxfdGVt
REM cF9yZXV0aWxpemFkbys9MQogICAgICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
REM ICAgICAgICAgICAgIHBlbmRlbnRlcy5hcHBlbmQoKGksZm9udGUsY2hhdmVfY3JlZGl0byx0
REM aXBvc1tpXSkpCiAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgICAg
REM IGlmIGNvbmZpZ19wcm90W2ldIG9yIGVudHJhZGFfbWV0YS5nZXQodSJuYW9fdHJhZHV6aXIi
REM KSBvciBlbnRyYWRhX25hb190cmFkdXppdmVsX2dvb2dsZShmb250ZSwgcmVsLCB0aXBvc1tp
REM XSk6CiAgICAgICAgICAgICAgICAgICAgcmVzdWx0YWRvc1tpXT1mb250ZTsgdG90YWxfZ2xv
REM YmFsX2RvbmUrPTEKICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICAg
REM ICAgaWYgdGlwb3NbaV09PXUidXJsX3Zpc2l2ZWwiOgogICAgICAgICAgICAgICAgICAgIHJl
REM c3VsdGFkb3NbaV09Zm9udGU7IHRvdGFsX3VybHNfcHJlc2VydmFkYXMrPTE7IHRvdGFsX2ds
REM b2JhbF9kb25lKz0xCiAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAg
REM ICAgIGNoYXZlPWNoYXZlX2NhY2hlX2dvb2dsZShvcmlnZW0sZGVzdGlubyxmb250ZSkKICAg
REM ICAgICAgICAgICAgIHZhbG9yPWNhY2hlX2dvb2dsZV9wb2RlX3JldXRpbGl6YXIoY2FjaGUs
REM Y2hhdmUsZm9udGUsZGVzdGlubyx0aXBvc1tpXSxyZWwpCiAgICAgICAgICAgICAgICBpZiB2
REM YWxvciBpcyBub3QgTm9uZToKICAgICAgICAgICAgICAgICAgICB2YWxvcj1ub3JtYWxpemFy
REM X2VzcGFjb3NfcG9zX3BvbnR1YWNhb19nb29nbGUoZm9udGUsdmFsb3IpCiAgICAgICAgICAg
REM ICAgICAgICAgcmVzdWx0YWRvc1tpXT12YWxvcjsgdG90YWxfZ2xvYmFsX2RvbmUrPTE7IHRv
REM dGFsX2NhY2hlX3JldXRpbGl6YWRvKz0xCiAgICAgICAgICAgICAgICAgICAgaWYgY2hhdmUg
REM aW4gY2FjaGVfcGVyc2lzdGVudGU6IHRvdGFsX3BlcnNpc3RlbnRlX3JldXRpbGl6YWRvKz0x
REM CiAgICAgICAgICAgICAgICAgICAgZWxpZiBjaGF2ZSBpbiBjYWNoZV90ZW1wOiB0b3RhbF90
REM ZW1wX3JldXRpbGl6YWRvKz0xCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAg
REM ICAgICAgIHBlbmRlbnRlcy5hcHBlbmQoKGksZm9udGUsY2hhdmUsdGlwb3NbaV0pKQogICAg
REM ICAgICAgICBhcnF1aXZvcy5hcHBlbmQoe3UicmVsIjpyZWwsdSJjYW1pbmhvIjpjYW1pbmhv
REM LHUibGluaGFzIjpsaW5oYXMsdSJpbmRpY2VzIjppbmRpY2VzLHUiZm9udGVzIjpmb250ZXMs
REM dSJ0aXBvcyI6dGlwb3MsdSJyZXN1bHRhZG9zIjpyZXN1bHRhZG9zLHUicGVuZGVudGVzIjpw
REM ZW5kZW50ZXMsdSJpbmljaW8iOmluaWNpb19wcmV9KQogICAgICAgICAgICBpZiBwZW5kZW50
REM ZXM6CiAgICAgICAgICAgICAgICBmaWxhc1tyZWxdPWxpc3QocGVuZGVudGVzKQogICAgICAg
REM ICAgICBwcmludCh1IiAgezB9IHwgY2FjaGUgezF9IHwgcGVuZGVudGVzIHsyfS97M30iLmZv
REM cm1hdChyZWwsIGxlbihmb250ZXMpLWxlbihwZW5kZW50ZXMpLCBsZW4ocGVuZGVudGVzKSwg
REM bGVuKGZvbnRlcykpKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAgICAg
REM ICAgICBsb2cuZXJybyh1IlBSw4ktUFJPQ0VTU0FNRU5UTyBGQUxIT1UgezB9OiB7MX0iLmZv
REM cm1hdChyZWwsZXhjKSk7IGxvZy5zYWx2YXIoKTsgcHJpbnQodSJBVklTTyB7MH06IHsxfSIu
REM Zm9ybWF0KHJlbCxleGMpKQogICAgICAgICAgICBhcnF1aXZvcy5hcHBlbmQoe3UicmVsIjpy
REM ZWwsdSJlcnJvIjpleGMsdSJsaW5oYXMiOltdLHUiaW5kaWNlcyI6W10sdSJmb250ZXMiOltd
REM LHUidGlwb3MiOltdLHUicmVzdWx0YWRvcyI6W10sdSJwZW5kZW50ZXMiOltdfSkKCiAgICB0
REM b3RhbF9wZW5kZW50ZXM9c3VtKGxlbih2KSBmb3IgdiBpbiBmaWxhcy52YWx1ZXMoKSkKICAg
REM IHByaW50KHUiRmlsYSBnbG9iYWw6IHswfSB0cmFkdcOnw6NvKMO1ZXMpIG5vdmFzIHwgY2Fj
REM aGUgcGVyc2lzdGVudGUgezF9IHwgY2FjaGUgZGUgcmV0b21hZGEgezJ9Ii5mb3JtYXQodG90
REM YWxfcGVuZGVudGVzLHRvdGFsX3BlcnNpc3RlbnRlX3JldXRpbGl6YWRvLHRvdGFsX3RlbXBf
REM cmV1dGlsaXphZG8pKQogICAgbG9nLmluZm8odSJGaWxhIGdsb2JhbCBjcmlhZGE6IHswfSB0
REM cmFkdcOnw7VlcyBwZW5kZW50ZXMsIHsxfSByZWFwcm92ZWl0YWRhcyBkbyBjYWNoZSBwZXJz
REM aXN0ZW50ZSwgezJ9IGRvIGNhY2hlIGRlIHJldG9tYWRhLiIuZm9ybWF0KHRvdGFsX3BlbmRl
REM bnRlcyx0b3RhbF9wZXJzaXN0ZW50ZV9yZXV0aWxpemFkbyx0b3RhbF90ZW1wX3JldXRpbGl6
REM YWRvKSkKCiAgICAjIEVzY2Fsb25hbWVudG8gcm91bmQtcm9iaW4gcG9yIGJsb2NvczogY2Fk
REM YSBhcnF1aXZvIHJlY2ViZSBhdMOpIE4gZW50cmFkYXMKICAgICMgcG9yIHJvZGFkYS4gQXNz
REM aW0gYXJxdWl2b3MgZ3JhbmRlcyBuw6NvIG1vbm9wb2xpemFtIGEgZmlsYSBlIGFycXVpdm9z
REM CiAgICAjIHBlcXVlbm9zIHRlcm1pbmFtIHJhcGlkYW1lbnRlLCBlbnF1YW50byA1IHdvcmtl
REM cnMgY29udGludWFtIG9jdXBhZG9zLgogICAgcmVscz1bciBmb3IgciBpbiBzb3J0ZWQoZmls
REM YXMua2V5cygpLCBrZXk9bGFtYmRhIHg6ICgtbGVuKGZpbGFzW3hdKSwgeCkpXQogICAgam9i
REM cz1bXQogICAgZmlsYXNfbXV0PXtyOmxpc3QodikgZm9yIHIsdiBpbiBmaWxhcy5pdGVtcygp
REM fQogICAgd2hpbGUgVHJ1ZToKICAgICAgICBhZGljaW9ub3U9RmFsc2UKICAgICAgICBmb3Ig
REM cmVsIGluIHJlbHM6CiAgICAgICAgICAgIHE9ZmlsYXNfbXV0LmdldChyZWwsW10pCiAgICAg
REM ICAgICAgIGlmIG5vdCBxOiBjb250aW51ZQogICAgICAgICAgICBwYXJ0ZT1xWzpHT09HTEVf
REM U0NIRURVTEVSX0NIVU5LXQogICAgICAgICAgICBkZWwgcVs6R09PR0xFX1NDSEVEVUxFUl9D
REM SFVOS10KICAgICAgICAgICAgZm9yIGl0ZW0gaW4gcGFydGU6CiAgICAgICAgICAgICAgICBq
REM b2JzLmFwcGVuZCgocmVsLCkraXRlbSkKICAgICAgICAgICAgYWRpY2lvbm91PVRydWUKICAg
REM ICAgICBpZiBub3QgYWRpY2lvbm91OiBicmVhawoKICAgIHBvcl9yZWw9e2FbdSJyZWwiXTph
REM IGZvciBhIGluIGFycXVpdm9zfQogICAgdG90YWxfam9icz1sZW4oam9icyk7IGNvbmNsdWlk
REM b19qb2JzPTA7IGZhbGhhc19kZWY9MDsgZmFsaGFzX3JlZ2lzdHJhZGFzPXNldCgpOyBzY2hl
REM ZHVsZXJfaW5kZXg9MAogICAgamFuZWxhPW1heChHT09HTEVfV09SS0VSUywgR09PR0xFX1dP
REM UktFUlMqR09PR0xFX0pPQl9XSU5ET1dfTVVMVElQTElFUikKICAgIHBvc19qb2I9MAogICAg
REM dWx0aW1vX2NhY2hlX3RlbXBfc2Fsdm89MAogICAgdWx0aW1vX2hlYXJ0YmVhdD10aW1lLnRp
REM bWUoKQogICAgaWYgdG90YWxfam9iczoKICAgICAgICB3aXRoIFRocmVhZFBvb2xFeGVjdXRv
REM cihtYXhfd29ya2Vycz1sZW4ocG9vbCkpIGFzIGV4ZWN1dG9yOgogICAgICAgICAgICBmdXR1
REM cm9zPXt9CiAgICAgICAgICAgIGRlZiBlbmZpbGVpcmFyKCk6CiAgICAgICAgICAgICAgICBu
REM b25sb2NhbCBwb3Nfam9iLCBzY2hlZHVsZXJfaW5kZXgKICAgICAgICAgICAgICAgIHdoaWxl
REM IHBvc19qb2IgPCB0b3RhbF9qb2JzIGFuZCBsZW4oZnV0dXJvcykgPCBqYW5lbGE6CiAgICAg
REM ICAgICAgICAgICAgICAgcmVsLGksZm9udGUsY2hhdmUsdGlwbz1qb2JzW3Bvc19qb2JdCiAg
REM ICAgICAgICAgICAgICAgICAgZnV0dXJvPWV4ZWN1dG9yLnN1Ym1pdCh0cmFkdXppcl90ZXh0
REM b193b3JrZXIsZm9udGUsb3JpZ2VtLGRlc3Rpbm8scG9vbCxpLGxlbihwb3JfcmVsW3JlbF1b
REM dSJmb250ZXMiXSksbG9nLHJlbCx0aXBvLHNjaGVkdWxlcl9pbmRleCkKICAgICAgICAgICAg
REM ICAgICAgICBmdXR1cm9zW2Z1dHVyb109KHJlbCxpLGZvbnRlLGNoYXZlKQogICAgICAgICAg
REM ICAgICAgICAgIHBvc19qb2IrPTE7IHNjaGVkdWxlcl9pbmRleCs9MQogICAgICAgICAgICBl
REM bmZpbGVpcmFyKCkKICAgICAgICAgICAgd2hpbGUgZnV0dXJvczoKICAgICAgICAgICAgICAg
REM IGFnb3JhX2hlYXJ0YmVhdD10aW1lLnRpbWUoKQogICAgICAgICAgICAgICAgZmFsdGFtPW1h
REM eCgwLHRvdGFsX2pvYnMtY29uY2x1aWRvX2pvYnMpCiAgICAgICAgICAgICAgICBjb25jbHVp
REM ZG9zLCBfID0gd2FpdChsaXN0KGZ1dHVyb3Mua2V5cygpKSwgdGltZW91dD1HT09HTEVfSEVB
REM UlRCRUFUX1NFR1VORE9TLCByZXR1cm5fd2hlbj1GSVJTVF9DT01QTEVURUQpCiAgICAgICAg
REM ICAgICAgICBpZiBub3QgY29uY2x1aWRvczoKICAgICAgICAgICAgICAgICAgICBkZWNvcnJp
REM ZG9fc2VtX2V2ZW50bz1hZ29yYV9oZWFydGJlYXQtdWx0aW1vX2hlYXJ0YmVhdCBpZiB1bHRp
REM bW9faGVhcnRiZWF0IGVsc2UgR09PR0xFX0hFQVJUQkVBVF9TRUdVTkRPUwogICAgICAgICAg
REM ICAgICAgICAgICMgTyBoZWFydGJlYXQgc8OzIGF2aXNhIHVtYSB2ZXogcG9yIHBlcsOtb2Rv
REM IGRlIGVzcGVyYS4KICAgICAgICAgICAgICAgICAgICAjIEEgYmFycmEgZGUgcHJvZ3Jlc3Nv
REM IHByaW5jaXBhbCBjb250aW51YSBzZW5kbyBhdHVhbGl6YWRhCiAgICAgICAgICAgICAgICAg
REM ICAgIyBxdWFuZG8gYWxndW1hIHRyYWR1w6fDo28gcmVhbG1lbnRlIHRlcm1pbmEuCiAgICAg
REM ICAgICAgICAgICAgICAgaWYgZGVjb3JyaWRvX3NlbV9ldmVudG8gPj0gR09PR0xFX0hFQVJU
REM QkVBVF9TRUdVTkRPUzoKICAgICAgICAgICAgICAgICAgICAgICAgcHJpbnQodSJcbltBZ3Vh
REM cmRhbmRvIEdvb2dsZSBUcmFuc2xhdGUgV2ViXSB7MDo1LjFmfSUgfCB7MX0vezJ9IHwgezN9
REM IHRhcmVmYShzKSBlbSB2b28gfCBzZW0gbm92YSBjb25jbHVzw6NvIGjDoSB7NDouMGZ9cyIu
REM Zm9ybWF0KDEwMC4wKmNvbmNsdWlkb19qb2JzL21heCgxLHRvdGFsX2pvYnMpLGNvbmNsdWlk
REM b19qb2JzLHRvdGFsX2pvYnMsbGVuKGZ1dHVyb3MpLG1heCgwLjAsZGVjb3JyaWRvX3NlbV9l
REM dmVudG8pKSwgZmx1c2g9VHJ1ZSkKICAgICAgICAgICAgICAgICAgICAgICAgdWx0aW1vX2hl
REM YXJ0YmVhdD10aW1lLnRpbWUoKQogICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAg
REM ICAgICAgICAgICB1bHRpbW9faGVhcnRiZWF0PXRpbWUudGltZSgpCiAgICAgICAgICAgICAg
REM ICBmb3IgZnV0dXJvIGluIGNvbmNsdWlkb3M6CiAgICAgICAgICAgICAgICAgICAgcmVsLGks
REM Zm9udGUsY2hhdmU9ZnV0dXJvcy5wb3AoZnV0dXJvKQogICAgICAgICAgICAgICAgICAgIHRy
REM eToKICAgICAgICAgICAgICAgICAgICAgICAgaW5kaWNlLHZhbG9yLGVycm89ZnV0dXJvLnJl
REM c3VsdCgpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6CiAg
REM ICAgICAgICAgICAgICAgICAgICAgIGluZGljZSx2YWxvcixlcnJvPWksTm9uZSxleGMKICAg
REM ICAgICAgICAgICAgICAgICBhcnE9cG9yX3JlbFtyZWxdCiAgICAgICAgICAgICAgICAgICAg
REM aWYgZXJybyBpcyBOb25lIGFuZCB2YWxvciBpcyBub3QgTm9uZToKICAgICAgICAgICAgICAg
REM ICAgICAgICAgd2l0aCBjYWNoZV9sb2NrOgogICAgICAgICAgICAgICAgICAgICAgICAgICAg
REM c2FsdmFyX2NhY2hlX2dvb2dsZV9zZWd1cm8oY2FjaGUsY2hhdmUsZm9udGUsdmFsb3IpCiAg
REM ICAgICAgICAgICAgICAgICAgICAgIGFycVt1InJlc3VsdGFkb3MiXVtpbmRpY2VdPXZhbG9y
REM CiAgICAgICAgICAgICAgICAgICAgICAgIHRvdGFsX2dsb2JhbF9kb25lKz0xCiAgICAgICAg
REM ICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICAgICAgYXJxW3UicmVzdWx0
REM YWRvcyJdW2luZGljZV09Zm9udGUKICAgICAgICAgICAgICAgICAgICAgICAgZmFsaGFzX2Rl
REM Zis9MQogICAgICAgICAgICAgICAgICAgICAgICBmYWxoYXNfcmVnaXN0cmFkYXMuYWRkKChy
REM ZWwsaW5kaWNlKSkKICAgICAgICAgICAgICAgICAgICAgICAgbG9nLmVycm8odSJGYWxoYSBk
REM ZWZpbml0aXZhOiB7MH0gdGV4dG8gezF9L3syfTogezN9Ii5mb3JtYXQocmVsLGluZGljZSsx
REM LGxlbihhcnFbdSJmb250ZXMiXSksZXJybykpCiAgICAgICAgICAgICAgICAgICAgICAgIHRv
REM dGFsX2dsb2JhbF9kb25lKz0xCiAgICAgICAgICAgICAgICAgICAgY29uY2x1aWRvX2pvYnMr
REM PTEKICAgICAgICAgICAgICAgICAgICBpZiBjb25jbHVpZG9fam9icz09MSBvciBjb25jbHVp
REM ZG9fam9icz09dG90YWxfam9icyBvciBjb25jbHVpZG9fam9icyUxMD09MDoKICAgICAgICAg
REM ICAgICAgICAgICAgICAgcHJpbnQodSJcclByb2dyZXNzbyBHb29nbGUgVHJhbnNsYXRlIFdl
REM YjogezA6NS4xZn0lIHwgezF9L3syfSB8IGNhY2hlIHszfSB8IHdvcmtlcnMgezR9Ii5mb3Jt
REM YXQoMTAwLjAqY29uY2x1aWRvX2pvYnMvbWF4KDEsdG90YWxfam9icyksY29uY2x1aWRvX2pv
REM YnMsdG90YWxfam9icyx0b3RhbF9jYWNoZV9yZXV0aWxpemFkbyxsZW4ocG9vbCkpLCBlbmQ9
REM dSIiLCBmbHVzaD1UcnVlKQogICAgICAgICAgICAgICAgIyBDYWNoZSBkZSByZXRvbWFkYTog
REM c2FsdmFyIGVtIGJsb2Nvcy4gQW50ZXMgZWxlIGVyYSByZWdyYXZhZG8KICAgICAgICAgICAg
REM ICAgICMgYXDDs3MgcHJhdGljYW1lbnRlIFRPREEgY29uY2x1c8OjbywgZmF6ZW5kbyBvIGN1
REM c3RvIGRlIGRpc2NvIGNyZXNjZXIKICAgICAgICAgICAgICAgICMgY29tIG8gdGFtYW5obyBk
REM YSBmaWxhIGUgcG9kZW5kbyBhcGFyZW50YXIgdW0gY29uZ2VsYW1lbnRvIG5vIGZpbmFsLgog
REM ICAgICAgICAgICAgICAgaWYgKGNvbmNsdWlkb19qb2JzIC0gdWx0aW1vX2NhY2hlX3RlbXBf
REM c2Fsdm8gPj0gR09PR0xFX0NBQ0hFX1RFTVBfU0FWRV9BX0NBREEgb3IgY29uY2x1aWRvX2pv
REM YnMgPT0gdG90YWxfam9icyk6CiAgICAgICAgICAgICAgICAgICAgc2FsdmFyX2NhY2hlX2dv
REM b2dsZShjYWNoZV90ZW1wX3BhdGgsY2FjaGUpCiAgICAgICAgICAgICAgICAgICAgdWx0aW1v
REM X2NhY2hlX3RlbXBfc2Fsdm89Y29uY2x1aWRvX2pvYnMKICAgICAgICAgICAgICAgICAgICAj
REM IE8gbG9nIGRldGFsaGFkbyB0YW1iw6ltIHBhc3NhIGEgc2VyIHBlcnNpc3RpZG8gZHVyYW50
REM ZSBhIGV4ZWN1w6fDo28uCiAgICAgICAgICAgICAgICAgICAgbG9nLnNhbHZhcigpCiAgICAg
REM ICAgICAgICAgICAgICAgcHJpbnQodSJcclByb2dyZXNzbyBHb29nbGUgVHJhbnNsYXRlIFdl
REM YjogezA6NS4xZn0lIHwgezF9L3syfSB8IGNhY2hlIHszfSB8IHdvcmtlcnMgezR9IHwgY2hl
REM Y2twb2ludCBzYWx2byIuZm9ybWF0KDEwMC4wKmNvbmNsdWlkb19qb2JzL21heCgxLHRvdGFs
REM X2pvYnMpLGNvbmNsdWlkb19qb2JzLHRvdGFsX2pvYnMsdG90YWxfY2FjaGVfcmV1dGlsaXph
REM ZG8sbGVuKHBvb2wpKSwgZW5kPXUiIiwgZmx1c2g9VHJ1ZSkKICAgICAgICAgICAgICAgIGlm
REM IHVzYXJfY2FjaGVfcGVyc2lzdGVudGUgYW5kIChjb25jbHVpZG9fam9icyAlIEdPT0dMRV9D
REM QUNIRV9QRVJTSVNURU5URV9TQVZFX0FfQ0FEQSA9PSAwIG9yIGNvbmNsdWlkb19qb2JzID09
REM IHRvdGFsX2pvYnMpOgogICAgICAgICAgICAgICAgICAgIHNhbHZhcl9jYWNoZV9nb29nbGUo
REM Y2FjaGVfcGVyc2lzdGVudGVfcGF0aCxjYWNoZSkKICAgICAgICAgICAgICAgIGVuZmlsZWly
REM YXIoKQogICAgICAgIHByaW50KHUiIikKCiAgICB0b3RhbF9hcnF1aXZvcz0wOyB0b3RhbF90
REM ZXh0b3M9MAogICAgZm9yIGFycSBpbiBhcnF1aXZvczoKICAgICAgICBpZiBhcnEuZ2V0KHUi
REM ZXJybyIpIGlzIG5vdCBOb25lOgogICAgICAgICAgICBjb250aW51ZQogICAgICAgIHRyeToK
REM ICAgICAgICAgICAgcmVsPWFycVt1InJlbCJdOyBsaW5oYXM9YXJxW3UibGluaGFzIl07IGlu
REM ZGljZXM9YXJxW3UiaW5kaWNlcyJdOyByZXN1bHRhZG9zPWFycVt1InJlc3VsdGFkb3MiXQog
REM ICAgICAgICAgICBmb3Igb3JkZW0saWR4IGluIGVudW1lcmF0ZShpbmRpY2VzKToKICAgICAg
REM ICAgICAgICAgIGxpbmhhPWxpbmhhc1tpZHhdOyBmaW09dSJcclxuIiBpZiBsaW5oYS5lbmRz
REM d2l0aCh1IlxyXG4iKSBlbHNlICh1IlxuIiBpZiBsaW5oYS5lbmRzd2l0aCh1IlxuIikgZWxz
REM ZSB1IiIpCiAgICAgICAgICAgICAgICBjb3Jwbz1saW5oYVs6LWxlbihmaW0pXSBpZiBmaW0g
REM ZWxzZSBsaW5oYQogICAgICAgICAgICAgICAgcHJlZml4bz1jb3Jwb1s6bGVuKGNvcnBvKS1s
REM ZW4oY29ycG8ubHN0cmlwKCkpXQogICAgICAgICAgICAgICAgdmFsb3I9cmVzdWx0YWRvc1tv
REM cmRlbV0gaWYgcmVzdWx0YWRvc1tvcmRlbV0gaXMgbm90IE5vbmUgZWxzZSBhcnFbdSJmb250
REM ZXMiXVtvcmRlbV0KICAgICAgICAgICAgICAgIGxpbmhhc1tpZHhdPXByZWZpeG8rY29kaWZp
REM Y2FyX2xpdGVyYWxfdHJhZHVjYW8odmFsb3IpK2ZpbQogICAgICAgICAgICB3aXRoIGlvLm9w
REM ZW4oYXJxW3UiY2FtaW5obyJdLCJ3IixlbmNvZGluZz0idXRmLTgiLG5ld2xpbmU9IiIpIGFz
REM IGY6CiAgICAgICAgICAgICAgICBmLndyaXRlKHUiIi5qb2luKGxpbmhhcykpCiAgICAgICAg
REM ICAgIHRvdGFsX2FycXVpdm9zKz0xOyB0b3RhbF90ZXh0b3MrPWxlbihpbmRpY2VzKQogICAg
REM ICAgICAgICBwZW5kPWxlbihhcnFbdSJwZW5kZW50ZXMiXSk7IGNhY2hlX2NvdW50PWxlbihp
REM bmRpY2VzKS1wZW5kCiAgICAgICAgICAgIHRlbXBvX2FycXVpdm89dGltZS50aW1lKCktYXJx
REM W3UiaW5pY2lvIl0KICAgICAgICAgICAgbG9nLnJlc3VsdGFkbyhyZWwsdSJ7MH0gdGV4dG8o
REM cykgfCBjYWNoZSBpbmljaWFsIHsxfSB8IG5vdm9zIHsyfSB8IHRlbXBvIHszOi4xZn1zIi5m
REM b3JtYXQobGVuKGluZGljZXMpLGNhY2hlX2NvdW50LHBlbmQsdGVtcG9fYXJxdWl2bykpCiAg
REM ICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6CiAgICAgICAgICAgIGZhbGhhc19kZWYr
REM PTE7IGxvZy5lcnJvKHUiQVJRVUlWTyBGQUxIT1UgTkEgR1JBVkHDh8ODTyB7MH06IHsxfSIu
REM Zm9ybWF0KGFycS5nZXQodSJyZWwiLHUiPyIpLGV4YykpCgogICAgIyBBdWRpdG9yaWEgZmlu
REM YWwgaW5kZXBlbmRlbnRlOiBuZW5odW1hIGV4ZWN1w6fDo28gcG9kZSBkZWNsYXJhciBzdWNl
REM c3NvIHNlCiAgICAjIHVtYSBzYcOtZGEgdsOhbGlkYSBuw6NvIHBhc3NhciBub3ZhbWVudGUg
REM cGVsYSBtZXNtYSB2YWxpZGHDp8OjbyBhcMOzcyB0b2RhIGEgZmlsYS4KICAgIGF1ZGl0b3Jp
REM YV9mYWxoYXMgPSAwCiAgICBmb3IgYXJxIGluIGFycXVpdm9zOgogICAgICAgIGlmIGFycS5n
REM ZXQodSJlcnJvIikgaXMgbm90IE5vbmU6CiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAg
REM Zm9yIG9yZGVtLCB2YWxvcl9hdWQgaW4gZW51bWVyYXRlKGFycVt1InJlc3VsdGFkb3MiXSk6
REM CiAgICAgICAgICAgIGlmIChhcnFbdSJyZWwiXSwgb3JkZW0pIGluIGZhbGhhc19yZWdpc3Ry
REM YWRhczoKICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgIGZvbnRlX2F1ZCA9
REM IGFycVt1ImZvbnRlcyJdW29yZGVtXQogICAgICAgICAgICB0aXBvX2F1ZCA9IGFycVt1InRp
REM cG9zIl1bb3JkZW1dCiAgICAgICAgICAgIGlmIHZhbG9yX2F1ZCBpcyBOb25lOgogICAgICAg
REM ICAgICAgICAgYXVkaXRvcmlhX2ZhbGhhcyArPSAxCiAgICAgICAgICAgICAgICBsb2cuZXJy
REM byh1IkF1ZGl0b3JpYSBmaW5hbDogezB9IHRleHRvIHsxfS97Mn0gc2VtIHJlc3VsdGFkby4i
REM LmZvcm1hdChhcnFbdSJyZWwiXSwgb3JkZW0gKyAxLCBsZW4oYXJxW3UiZm9udGVzIl0pKSkK
REM ICAgICAgICAgICAgICAgIGFycVt1InJlc3VsdGFkb3MiXVtvcmRlbV0gPSBmb250ZV9hdWQK
REM ICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgICAgIHZhbG9yX2F1ZCA9IG5vcm1h
REM bGl6YXJfdGVybW9zX2luZ2xlc19yZXNpZHVhaXNfcHRicih2YWxvcl9hdWQpIGlmIGRlc3Rp
REM bm8ubG93ZXIoKS5zdGFydHN3aXRoKHUicHQiKSBlbHNlIHZhbG9yX2F1ZAogICAgICAgICAg
REM ICBhcnFbdSJyZXN1bHRhZG9zIl1bb3JkZW1dID0gdmFsb3JfYXVkCiAgICAgICAgICAgIHRy
REM eToKICAgICAgICAgICAgICAgIHZhbGlkYXJfcmVzdWx0YWRvX3RyYWR1Y2FvX2dvb2dsZShm
REM b250ZV9hdWQsIHZhbG9yX2F1ZCwgdGlwb19hdWQsIG9yaWdlbSwgZGVzdGlubykKICAgICAg
REM ICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6CiAgICAgICAgICAgICAgICBhdWRpdG9y
REM aWFfZmFsaGFzICs9IDEKICAgICAgICAgICAgICAgIGZhbGhhc19yZWdpc3RyYWRhcy5hZGQo
REM KGFycVt1InJlbCJdLCBvcmRlbSkpCiAgICAgICAgICAgICAgICBsb2cuZXJybyh1IkF1ZGl0
REM b3JpYSBmaW5hbDogezB9IHRleHRvIHsxfS97Mn0gcmVqZWl0YWRvOiB7M30iLmZvcm1hdChh
REM cnFbdSJyZWwiXSwgb3JkZW0gKyAxLCBsZW4oYXJxW3UiZm9udGVzIl0pLCBleGMpKQogICAg
REM ICAgICAgICAgICAgIyBOw6NvIG1hc2NhcmFyIHVtYSBmYWxoYSBjb20gdW1hIHRyYWR1w6fD
REM o28gcXVlIG8gdmFsaWRhZG9yIHJlY3Vzb3UuCiAgICAgICAgICAgICAgICBhcnFbdSJyZXN1
REM bHRhZG9zIl1bb3JkZW1dID0gZm9udGVfYXVkCgogICAgZmFsaGFzX2RlZiArPSBhdWRpdG9y
REM aWFfZmFsaGFzCgogICAgc2FsdmFyX2NhY2hlX2dvb2dsZShjYWNoZV90ZW1wX3BhdGgsY2Fj
REM aGUpCiAgICBpZiB1c2FyX2NhY2hlX3BlcnNpc3RlbnRlOgogICAgICAgIHNhbHZhcl9jYWNo
REM ZV9nb29nbGUoY2FjaGVfcGVyc2lzdGVudGVfcGF0aCxjYWNoZSkKICAgIHRlbXBvX3RvdGFs
REM PXRpbWUudGltZSgpLWluaWNpb190b3RhbAogICAgcHJpbnQodSJGaWxhIGRlIHRyYWR1w6fD
REM o28gY29uY2x1w61kYTogezB9L3sxfS4gVGVtcG8gdG90YWw6IHsyOi4xZn1zIi5mb3JtYXQo
REM dG90YWxfam9icyx0b3RhbF9qb2JzLHRlbXBvX3RvdGFsKSkKICAgIHRvdGFsX3JlcXVlc3Rz
REM PXN1bShnZXRhdHRyKGMsdSJyZXF1ZXN0cyIsMCkgZm9yIGMgaW4gcG9vbCkKICAgIHRvdGFs
REM XzQyOT1zdW0oZ2V0YXR0cihjLHUicmF0ZV9saW1pdHMiLDApIGZvciBjIGluIHBvb2wpCiAg
REM ICBsYXRlbmNpYXM9W3ggZm9yIGMgaW4gcG9vbCBmb3IgeCBpbiBnZXRhdHRyKGMsdSJsYXRl
REM bmNpYXMiLFtdKV0KICAgIG1lZGlhX2xhdD1zdW0obGF0ZW5jaWFzKS9sZW4obGF0ZW5jaWFz
REM KSBpZiBsYXRlbmNpYXMgZWxzZSAwLjAKICAgIGxvZy5zZXBhcmFkb3IoKTsgbG9nLnJlc3Vs
REM dGFkbyh1Ik1vdG9yIix1Ikdvb2dsZSBUcmFuc2xhdGUgV2ViIFJQQyB2MSIpOyBsb2cucmVz
REM dWx0YWRvKHUiQXJxdWl2b3MgcHJvY2Vzc2Fkb3MiLHN0cih0b3RhbF9hcnF1aXZvcykpOyBs
REM b2cucmVzdWx0YWRvKHUiVGV4dG9zIHByb2Nlc3NhZG9zIixzdHIodG90YWxfdGV4dG9zKSk7
REM IGxvZy5yZXN1bHRhZG8odSJVUkxzIHZpc8OtdmVpcyBwcmVzZXJ2YWRhcyIsc3RyKHRvdGFs
REM X3VybHNfcHJlc2VydmFkYXMpKTsgbG9nLnJlc3VsdGFkbyh1IkNhY2hlIHBlcnNpc3RlbnRl
REM IHJldXRpbGl6YWRvIixzdHIodG90YWxfcGVyc2lzdGVudGVfcmV1dGlsaXphZG8pKTsgbG9n
REM LnJlc3VsdGFkbyh1IkNhY2hlIGRlIHJldG9tYWRhIHJldXRpbGl6YWRvIixzdHIodG90YWxf
REM dGVtcF9yZXV0aWxpemFkbykpOyBsb2cucmVzdWx0YWRvKHUiRmFsaGFzIGRlZmluaXRpdmFz
REM IixzdHIoZmFsaGFzX2RlZikpOyBsb2cucmVzdWx0YWRvKHUiUmVxdWlzacOnw7VlcyBIVFRQ
REM IixzdHIodG90YWxfcmVxdWVzdHMpKTsgbG9nLnJlc3VsdGFkbyh1IkhUVFAgNDI5IixzdHIo
REM dG90YWxfNDI5KSk7IGxvZy5yZXN1bHRhZG8odSJMYXTDqm5jaWEgbcOpZGlhIHBvciByZXF1
REM aXNpw6fDo28iLHUiezA6LjNmfXMiLmZvcm1hdChtZWRpYV9sYXQpKTsgbG9nLnJlc3VsdGFk
REM byh1IlRlbXBvIHRvdGFsIix1InswOi4xZn1zIi5mb3JtYXQodGVtcG9fdG90YWwpKQogICAg
REM aWYgZmFsaGFzX2RlZiA9PSAwOgogICAgICAgIHJlbW92aWRvPWxpbXBhcl9jYWNoZV9nb29n
REM bGVfdGVtcG9yYXJpbyhjYWNoZV90ZW1wX3BhdGgpCiAgICAgICAgaWYgcmVtb3ZpZG86CiAg
REM ICAgICAgICAgIGxvZy5pbmZvKHUiQ2FjaGUgdGVtcG9yw6FyaW8gZGUgcmV0b21hZGEgcmVt
REM b3ZpZG8gYW8gY29uY2x1aXIgY29tIHN1Y2Vzc287IGNhY2hlIHBlcnNpc3RlbnRlIHByZXNl
REM cnZhZG8gZW06IHswfSIuZm9ybWF0KGNhY2hlX3BlcnNpc3RlbnRlX3BhdGgpKQogICAgICAg
REM IGVsc2U6CiAgICAgICAgICAgIGxvZy5hdmlzbyh1Ik7Do28gZm9pIHBvc3PDrXZlbCByZW1v
REM dmVyIGltZWRpYXRhbWVudGUgbyBjYWNoZSB0ZW1wb3LDoXJpbzogezB9Ii5mb3JtYXQoY2Fj
REM aGVfdGVtcF9wYXRoKSkKICAgICAgICBsb2cuaW5mbyh1IlRyYWR1w6fDo28gY29uY2x1w61k
REM YSBjb20gc3VjZXNzbzsgdG9kb3Mgb3MgdGV4dG9zIHJlY2ViZXJhbSByZXN1bHRhZG8uIikK
REM ICAgICAgICBtZW5zYWdlbV9maW5hbD10KCJ0X3Byb250byIpLmZvcm1hdChwYXN0YV9zYWlk
REM YSkKICAgIGVsc2U6CiAgICAgICAgbG9nLmF2aXNvKHUiVHJhZHXDp8OjbyBpbmNvbXBsZXRh
REM OiB7MH0gZmFsaGEocykgZGVmaW5pdGl2YShzKS4gQ2FjaGUgdGVtcG9yw6FyaW8gcHJlc2Vy
REM dmFkbyBwYXJhIHJldG9tYWRhOiB7MX0iLmZvcm1hdChmYWxoYXNfZGVmLGNhY2hlX3RlbXBf
REM cGF0aCkpCiAgICAgICAgbWVuc2FnZW1fZmluYWw9dSJUcmFkdcOnw6NvIGluY29tcGxldGEu
REM IE8gY2FjaGUgZGUgcmV0b21hZGEgZm9pIHByZXNlcnZhZG87IGV4ZWN1dGUgbm92YW1lbnRl
REM IHBhcmEgY29udGludWFyLiIKICAgIGxvZy50aXR1bG8odSJEREFDIFRyYWR1w6fDo28gY29t
REM IEdvb2dsZSBUcmFuc2xhdGUgV2ViIFJQQyAtIEZJTSBEQSBFWEVDVcOHw4NPIik7IGxvZy5z
REM YWx2YXIoKTsgcHJpbnQodSIiKTsgcHJpbnQobWVuc2FnZW1fZmluYWwpOyByZXR1cm4gMCBp
REM ZiBmYWxoYXNfZGVmPT0wIGVsc2UgMQoKCiMgPT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0KIyBS
REM RUlOVEVHUkHDh8ODTyBFIFZBTElEQcOHw4NPCiMgPT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0K
REM ZGVmIHNoYTI1Nl9hcnF1aXZvKGNhbWluaG8pOgogICAgaW1wb3J0IGhhc2hsaWIKICAgIGg9
REM aGFzaGxpYi5zaGEyNTYoKQogICAgd2l0aCBvcGVuKGNhbWluaG8sInJiIikgYXMgZjoKICAg
REM ICAgICB3aGlsZSBUcnVlOgogICAgICAgICAgICBibG9jbz1mLnJlYWQoMTAyNCoxMDI0KQog
REM ICAgICAgICAgICBpZiBub3QgYmxvY286CiAgICAgICAgICAgICAgICBicmVhawogICAgICAg
REM ICAgICBoLnVwZGF0ZShibG9jbykKICAgIHJldHVybiBoLmhleGRpZ2VzdCgpCgoKZGVmIGNv
REM bXBhcmFyX2xpdGVyYWxfdHJhZHVjYW8oYSxiLHRpcG89Tm9uZSk6CiAgICAiIiJDb21wYXJh
REM IGRvaXMgbGl0ZXJhaXMgcGVsbyBjb250ZcO6ZG8gc2Vtw6JudGljbywgc2VtIHRyYXRhciBy
REM ZWZvcm1hdGHDp8OjbyBjb21vIHRyYWR1w6fDo28uIiIiCiAgICB2YT1kZWNvZGlmaWNhcl9s
REM aXRlcmFsX3RyYWR1Y2FvKGEpCiAgICB2Yj1kZWNvZGlmaWNhcl9saXRlcmFsX3RyYWR1Y2Fv
REM KGIpCiAgICBpZiB0aXBvPT11InBvZW1hX2NvcnBvIjoKICAgICAgICAjIE8gZXh0cmF0b3Ig
REM bm9ybWFsaXphIGEgcmVwcmVzZW50YcOnw6NvIGRvcyBjb3Jwb3MgZGUgcG9lbWEgZSBwb2Rl
REM IHJlbW92ZXIKICAgICAgICAjIGFwZW5hcyBvIGVzcGHDp28gZmluYWwgZXN0cnV0dXJhbCBx
REM dWUgZXhpc3RlIG5vIGxpdGVyYWwgb3JpZ2luYWwuCiAgICAgICAgcmV0dXJuIHZhLnJzdHJp
REM cCgpPT12Yi5yc3RyaXAoKQogICAgcmV0dXJuIHZhPT12YgoKCmRlZiB2YWxpZGFyX3ByZV9y
REM ZWludGVncmFjYW8ocGFzdGFfZ2FtZSxwYXN0YV9lbnRyYWRhX2Jhc2UsbWFwYV9jb21wbGV0
REM byxjYW5kaWRhdG9zKToKICAgIGVycm9zPVtdOyBtYXBhX2NoYXZlcz1zZXQobWFwYV9jb21w
REM bGV0by5rZXlzKCkpOyBjYW5kaWRhdG9zX21hcD1zZXQoKQogICAgZW50cmFkYXNfZXNwZXJh
REM ZGFzPXN1bShsZW4odikgZm9yIHYgaW4gbWFwYV9jb21wbGV0by52YWx1ZXMoKSk7IGVudHJh
REM ZGFzX2VuY29udHJhZGFzPTA7IGFsdGVyYWRvcz0wOyBpZ3VhaXM9MAogICAgZm9yIGNhbWlu
REM aG8gaW4gY2FuZGlkYXRvczoKICAgICAgICByZWw9b3MucGF0aC5yZWxwYXRoKGNhbWluaG8s
REM cGFzdGFfZW50cmFkYV9iYXNlKS5yZXBsYWNlKG9zLnNlcCwiLyIpCiAgICAgICAgaWYgcmVs
REM IG5vdCBpbiBtYXBhX2NvbXBsZXRvOgogICAgICAgICAgICBpZiBjYW1pbmhvLmxvd2VyKCku
REM ZW5kc3dpdGgoIi50eHQiKSBhbmQgbm90IG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9pbihw
REM YXN0YV9nYW1lLHJlbCkpOgogICAgICAgICAgICAgICAgZXJyb3MuYXBwZW5kKHUiVFhUIHNl
REM bSBjb3JyZXNwb25kZW50ZSBubyBnYW1lIG9yaWdpbmFsOiB7MH0iLmZvcm1hdChyZWwpKQog
REM ICAgICAgICAgICBjb250aW51ZQogICAgICAgIGNhbmRpZGF0b3NfbWFwLmFkZChyZWwpOyBv
REM cmlnaW5hbD1vcy5wYXRoLmpvaW4ocGFzdGFfZ2FtZSxyZWwpCiAgICAgICAgaWYgbm90IG9z
REM LnBhdGguaXNmaWxlKG9yaWdpbmFsKToKICAgICAgICAgICAgZXJyb3MuYXBwZW5kKHQoInJq
REM X3NlbV9vcmlnaW5hbCIpLmZvcm1hdChvcmlnaW5hbCkpOyBjb250aW51ZQogICAgICAgIHRy
REM eTogdGV4dG9zPWxlcl90ZXh0b3NfdHJhZHV6aWRvcyhjYW1pbmhvKQogICAgICAgIGV4Y2Vw
REM dCBFeGNlcHRpb24gYXMgZXhjOiBlcnJvcy5hcHBlbmQodSJGYWxoYSBhbyBsZXIgdHJhZHXD
REM p8OjbyB7MH06IHsxfSIuZm9ybWF0KHJlbCxleGMpKTsgY29udGludWUKICAgICAgICBlbnRy
REM YWRhcz1tYXBhX2NvbXBsZXRvW3JlbF07IGVudHJhZGFzX2VuY29udHJhZGFzKz1sZW4odGV4
REM dG9zKQogICAgICAgIHRyeToKICAgICAgICAgICAgbGluaGFzX3ZhbGlkYWNhbz1sZXJfbGlu
REM aGFzX3JhdyhvcmlnaW5hbCkKICAgICAgICAgICAgc291cmNlX2hhc2hlcz17ZS5nZXQoJ3Nv
REM dXJjZV9zaGEyNTYnKSBmb3IgZSBpbiBlbnRyYWRhcyBpZiBlLmdldCgnc291cmNlX3NoYTI1
REM NicpfQogICAgICAgICAgICBpZiBzb3VyY2VfaGFzaGVzIGFuZCAobGVuKHNvdXJjZV9oYXNo
REM ZXMpIT0xIG9yIG5leHQoaXRlcihzb3VyY2VfaGFzaGVzKSkhPXNoYTI1Nl9hcnF1aXZvKG9y
REM aWdpbmFsKSk6CiAgICAgICAgICAgICAgICBlcnJvcy5hcHBlbmQodSJ7fTogU0hBLTI1NiBk
REM byBhcnF1aXZvIG9yaWdpbmFsIG7Do28gY29ycmVzcG9uZGUgYW8gbWFwYS4iLmZvcm1hdChy
REM ZWwpKTsgY29udGludWUKICAgICAgICAgICAgZm9yIGUgaW4gZW50cmFkYXM6CiAgICAgICAg
REM ICAgICAgICBudW1lcm89aW50KGUuZ2V0KCdsaW5oYScsMCkgb3IgMCkKICAgICAgICAgICAg
REM ICAgIGlmIG51bWVybzwxIG9yIG51bWVybz5sZW4obGluaGFzX3ZhbGlkYWNhbyk6CiAgICAg
REM ICAgICAgICAgICAgICAgZXJyb3MuYXBwZW5kKHUie306IGxpbmhhIGludsOhbGlkYSBubyBt
REM YXBhOiB7fSIuZm9ybWF0KHJlbCxudW1lcm8pKTsgY29udGludWUKICAgICAgICAgICAgICAg
REM IGxpbmhhPWxpbmhhc192YWxpZGFjYW9bbnVtZXJvLTFdCiAgICAgICAgICAgICAgICBpZiBl
REM LmdldCgnc291cmNlX2xpbmVfaGFzaCcpIGFuZCBlLmdldCgnc291cmNlX2xpbmVfaGFzaCcp
REM IT1fc2hhMjU2X3RleHRvX3V0ZjgobGluaGEpOgogICAgICAgICAgICAgICAgICAgIGVycm9z
REM LmFwcGVuZCh1Int9OiBoYXNoIGRhIGxpbmhhIG11ZG91IG5hIGxpbmhhIHt9LiIuZm9ybWF0
REM KHJlbCxudW1lcm8pKQogICAgICAgICAgICAgICAgaWYgZS5nZXQoJ2NvbnRleHRfaGFzaCcp
REM IGFuZCBlLmdldCgnY29udGV4dF9oYXNoJykhPV9oYXNoX2NvbnRleHRvX2xpbmhhcyhsaW5o
REM YXNfdmFsaWRhY2FvLG51bWVybyk6CiAgICAgICAgICAgICAgICAgICAgZXJyb3MuYXBwZW5k
REM KHUie306IGNvbnRleHRvIGRhIGxpbmhhIG11ZG91IG5hIGxpbmhhIHt9LiIuZm9ybWF0KHJl
REM bCxudW1lcm8pKQogICAgICAgICAgICAgICAgaWYgZS5nZXQoJ3Rva2VuX3NpZ25hdHVyZScp
REM IGlzIG5vdCBOb25lIGFuZCBlLmdldCgndG9rZW5fc2lnbmF0dXJlJykhPV90b2tlbl9zaWdu
REM YXR1cmVfbWFwYShlLmdldCgnb3JpZ2luYWwnLHUnJykpOgogICAgICAgICAgICAgICAgICAg
REM IGVycm9zLmFwcGVuZCh1Int9OiBhc3NpbmF0dXJhIGRlIHRva2VucyBkbyBtYXBhIGVzdMOh
REM IGluY29uc2lzdGVudGUgbmEgbGluaGEge30uIi5mb3JtYXQocmVsLG51bWVybykpCiAgICAg
REM ICAgICAgICAgICBpZiBlLmdldCgnZW50cnlfaWQnKToKICAgICAgICAgICAgICAgICAgICBi
REM YXNlX2lkPXUnezB9XDB7MX1cMHsyfVwwezN9XDB7NH0nLmZvcm1hdChlLmdldCgnc291cmNl
REM X3NoYTI1NicsdScnKSxudW1lcm8sZS5nZXQoJ2NvbHVuYV9pbmljaW8nLDApLGUuZ2V0KCdj
REM b2x1bmFfZmltJywwKSxlLmdldCgnb3JpZ2luYWwnLHUnJykpCiAgICAgICAgICAgICAgICAg
REM ICAgZXNwZXJhZG9faWQ9aGFzaGxpYi5zaGEyNTYoYmFzZV9pZC5lbmNvZGUoJ3V0Zi04Jykp
REM LmhleGRpZ2VzdCgpWzoyNF0KICAgICAgICAgICAgICAgICAgICBpZiBlLmdldCgnZW50cnlf
REM aWQnKSE9ZXNwZXJhZG9faWQ6CiAgICAgICAgICAgICAgICAgICAgICAgIGVycm9zLmFwcGVu
REM ZCh1Int9OiBlbnRyeV9pZCBpbmNvbnNpc3RlbnRlIG5hIGxpbmhhIHt9LiIuZm9ybWF0KHJl
REM bCxudW1lcm8pKQogICAgICAgICAgICBpZiBhbnkodSJoYXNoIGRhIGxpbmhhIG11ZG91IiBp
REM biB4IG9yIHUiY29udGV4dG8gZGEgbGluaGEgbXVkb3UiIGluIHggb3IgdSJhc3NpbmF0dXJh
REM IGRlIHRva2VucyIgaW4geCBvciB1ImVudHJ5X2lkIGluY29uc2lzdGVudGUiIGluIHggZm9y
REM IHggaW4gZXJyb3MgaWYgeC5zdGFydHN3aXRoKHJlbCt1JzonKSk6CiAgICAgICAgICAgICAg
REM ICBjb250aW51ZQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAgICAgICAg
REM ICBlcnJvcy5hcHBlbmQodSJ7fTogZmFsaGEgdmFsaWRhbmRvIGludGVncmlkYWRlIGRvIG1h
REM cGE6IHt9Ii5mb3JtYXQocmVsLGV4YykpOyBjb250aW51ZQogICAgICAgIGlmIGxlbih0ZXh0
REM b3MpIT1sZW4oZW50cmFkYXMpOgogICAgICAgICAgICBlcnJvcy5hcHBlbmQodSJ7MH06IHsx
REM fSIuZm9ybWF0KHJlbCx0KCJyal9jb250YWdlbSIpLmZvcm1hdChsZW4oZW50cmFkYXMpLGxl
REM bih0ZXh0b3MpKSkpOyBjb250aW51ZQogICAgICAgIHRyeTogXyxyal9lcnJvcz1yZWluamV0
REM YXJfYXJxdWl2byhvcmlnaW5hbCxlbnRyYWRhcyx0ZXh0b3MpCiAgICAgICAgZXhjZXB0IEV4
REM Y2VwdGlvbiBhcyBleGM6IHJqX2Vycm9zPVtzdHIoZXhjKV0KICAgICAgICBmb3IgZXJybyBp
REM biByal9lcnJvczogZXJyb3MuYXBwZW5kKHUiezB9OiB7MX0iLmZvcm1hdChyZWwsZXJybykp
REM CiAgICAgICAgZm9yIGVudHJhZGEsdHJhZHV6aWRvIGluIHppcChlbnRyYWRhcyx0ZXh0b3Mp
REM OgogICAgICAgICAgICBpZiBjb21wYXJhcl9saXRlcmFsX3RyYWR1Y2FvKHRyYWR1emlkbywg
REM ZW50cmFkYS5nZXQoIm9yaWdpbmFsIiwgIiIpLCBlbnRyYWRhLmdldCgidGlwbyIpKTogaWd1
REM YWlzKz0xCiAgICAgICAgICAgIGVsc2U6IGFsdGVyYWRvcys9MQogICAgZm9yIHJlbCBpbiBz
REM b3J0ZWQobWFwYV9jaGF2ZXMtY2FuZGlkYXRvc19tYXApOgogICAgICAgIGVycm9zLmFwcGVu
REM ZCh1IkFycXVpdm8gbWFwZWFkbyBuw6NvIGVuY29udHJhZG8gbmEgcGFzdGEgc2VsZWNpb25h
REM ZGE6IHswfSIuZm9ybWF0KHJlbCkpCiAgICByZXR1cm4geyJlcnJvcyI6ZXJyb3MsImFycXVp
REM dm9zX2VzcGVyYWRvcyI6bGVuKG1hcGFfY2hhdmVzKSwiYXJxdWl2b3NfdmFsaWRhZG9zIjps
REM ZW4oY2FuZGlkYXRvc19tYXApLCJlbnRyYWRhc19lc3BlcmFkYXMiOmVudHJhZGFzX2VzcGVy
REM YWRhcywiZW50cmFkYXNfZW5jb250cmFkYXMiOmVudHJhZGFzX2VuY29udHJhZGFzLCJhbHRl
REM cmFkb3MiOmFsdGVyYWRvcywiaWd1YWlzIjppZ3VhaXN9CgoKZGVmIHZhbGlkYXJfcG9zX3Jl
REM aW50ZWdyYWNhbyhwYXN0YV9nYW1lLHBhc3RhX3NhaWRhX3dyYXAscGFzdGFfZW50cmFkYV9i
REM YXNlLG1hcGFfY29tcGxldG8sY2FuZGlkYXRvcyxyZW1vdmlkb3NfaW50ZW5jaW9uYWlzPU5v
REM bmUpOgogICAgZXJyb3M9W10KICAgIHJlbW92aWRvc19pbnRlbmNpb25haXM9c2V0KF9kdWFs
REM X25vcm1fcmVsKHgpIGZvciB4IGluIChyZW1vdmlkb3NfaW50ZW5jaW9uYWlzIG9yIFtdKSkK
REM ICAgIG9yaWdfZmlsZXM9c2V0KCk7IG91dF9maWxlcz1zZXQoKQogICAgZm9yIHJhaXpfZGly
REM LF8sYXJxdWl2b3MgaW4gb3Mud2FsayhwYXN0YV9nYW1lKToKICAgICAgICBmb3Igbm9tZSBp
REM biBhcnF1aXZvczogb3JpZ19maWxlcy5hZGQob3MucGF0aC5yZWxwYXRoKG9zLnBhdGguam9p
REM bihyYWl6X2Rpcixub21lKSxwYXN0YV9nYW1lKS5yZXBsYWNlKG9zLnNlcCwiLyIpKQogICAg
REM Zm9yIHJhaXpfZGlyLF8sYXJxdWl2b3MgaW4gb3Mud2FsayhwYXN0YV9zYWlkYV93cmFwKToK
REM ICAgICAgICBmb3Igbm9tZSBpbiBhcnF1aXZvczogb3V0X2ZpbGVzLmFkZChvcy5wYXRoLnJl
REM bHBhdGgob3MucGF0aC5qb2luKHJhaXpfZGlyLG5vbWUpLHBhc3RhX3NhaWRhX3dyYXApLnJl
REM cGxhY2Uob3Muc2VwLCIvIikpCiAgICBmb3IgcmVsIGluIHNvcnRlZChvcmlnX2ZpbGVzLW91
REM dF9maWxlcyk6CiAgICAgICAgaWYgX2R1YWxfbm9ybV9yZWwocmVsKSBpbiByZW1vdmlkb3Nf
REM aW50ZW5jaW9uYWlzOgogICAgICAgICAgICBjb250aW51ZQogICAgICAgIGVycm9zLmFwcGVu
REM ZCh1IkFycXVpdm8gb3JpZ2luYWwgYXVzZW50ZSBuYSBzYcOtZGE6IHswfSIuZm9ybWF0KHJl
REM bCkpCiAgICBmb3IgcmVsIGluIHNvcnRlZChvdXRfZmlsZXMtb3JpZ19maWxlcyk6IGVycm9z
REM LmFwcGVuZCh1IkFycXVpdm8gaW5lc3BlcmFkbyBjcmlhZG8gbmEgc2HDrWRhOiB7MH0iLmZv
REM cm1hdChyZWwpKQogICAgZm9yIHJlbCBpbiBzb3J0ZWQob3JpZ19maWxlcyAmIG91dF9maWxl
REM cyk6CiAgICAgICAgb3JpZ2luYWw9b3MucGF0aC5qb2luKHBhc3RhX2dhbWUscmVsKTsgc2Fp
REM ZGE9b3MucGF0aC5qb2luKHBhc3RhX3NhaWRhX3dyYXAscmVsKQogICAgICAgIGlmIHJlbCBp
REM biBtYXBhX2NvbXBsZXRvOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBlbnRy
REM YWRhX3BhdGg9b3MucGF0aC5qb2luKHBhc3RhX2VudHJhZGFfYmFzZSxyZWwucmVwbGFjZSgi
REM LyIsb3Muc2VwKSk7IHRleHRvcz1sZXJfdGV4dG9zX3RyYWR1emlkb3MoZW50cmFkYV9wYXRo
REM KQogICAgICAgICAgICAgICAgZXNwZXJhZGFzLHJqX2Vycm9zPXJlaW5qZXRhcl9hcnF1aXZv
REM KG9yaWdpbmFsLG1hcGFfY29tcGxldG9bcmVsXSx0ZXh0b3MpCiAgICAgICAgICAgICAgICBp
REM ZiByal9lcnJvczoKICAgICAgICAgICAgICAgICAgICBmb3IgZXJybyBpbiByal9lcnJvczog
REM ZXJyb3MuYXBwZW5kKHUiezB9OiB7MX0iLmZvcm1hdChyZWwsZXJybykpOyBjb250aW51ZQog
REM ICAgICAgICAgICAgICAgd2l0aCBpby5vcGVuKHNhaWRhLCJyIixlbmNvZGluZz0idXRmLTgi
REM LGVycm9ycz0icmVwbGFjZSIsbmV3bGluZT0iIikgYXMgZjogcmVhbD1mLnJlYWQoKQogICAg
REM ICAgICAgICAgICAgaWYgcmVhbCE9dSIiLmpvaW4oZXNwZXJhZGFzKTogZXJyb3MuYXBwZW5k
REM KHUiQ29udGXDumRvIHJlaW50ZWdyYWRvIGRpZmVyZW50ZSBkbyBlc3BlcmFkbzogezB9Ii5m
REM b3JtYXQocmVsKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6IGVycm9z
REM LmFwcGVuZCh1IkZhbGhhIG5hIHZhbGlkYcOnw6NvIGRlIHswfTogezF9Ii5mb3JtYXQocmVs
REM LGV4YykpCiAgICAgICAgZWxzZToKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAg
REM aWYgc2hhMjU2X2FycXVpdm8ob3JpZ2luYWwpIT1zaGEyNTZfYXJxdWl2byhzYWlkYSk6IGVy
REM cm9zLmFwcGVuZCh1IkFycXVpdm8gZm9yYSBkbyBtYXBhIGZvaSBhbHRlcmFkbzogezB9Ii5m
REM b3JtYXQocmVsKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6IGVycm9z
REM LmFwcGVuZCh1IkZhbGhhIGNvbXBhcmFuZG8gezB9OiB7MX0iLmZvcm1hdChyZWwsZXhjKSkK
REM ICAgIHJldHVybiB7ImVycm9zIjplcnJvcywidG90YWxfb3JpZyI6bGVuKG9yaWdfZmlsZXMp
REM LCJ0b3RhbF9zYWlkYSI6bGVuKG91dF9maWxlcyl9CgoKZGVmIGNyaWFyX2JhY2t1cF9zYWlk
REM YShyYWl6LHBhc3RhX3NhaWRhX3dyYXApOgogICAgaWYgbm90IG9zLnBhdGguaXNkaXIocGFz
REM dGFfc2FpZGFfd3JhcCk6IHJldHVybiBOb25lCiAgICBzdGFtcD10aW1lLnN0cmZ0aW1lKCIl
REM WSVtJWQtJUglTSVTIikKICAgIGRlc3Rpbm89b3MucGF0aC5qb2luKHJhaXosdSJVblJlbi1E
REM REFDLUJhY2t1cC1SZWludGVncmHDp8Ojby17fSIuZm9ybWF0KHN0YW1wKSkKICAgIHNodXRp
REM bC5jb3B5dHJlZShwYXN0YV9zYWlkYV93cmFwLGRlc3Rpbm8pCiAgICByZXR1cm4gZGVzdGlu
REM bwoKCgpkZWYgbGltcGFyX2NvbXBpbGFkb3Nfc29tYnJlYWRvcyhwYXN0YV9yYWl6LCBsb2c9
REM Tm9uZSk6CiAgICAiIiJSZW1vdmUgLnJweWMvLnJweW1jIGRhIHNhw61kYSBtZXNjbGFkYS4K
REM CiAgICBBIGRpc3RyaWJ1acOnw6NvIGRvIEREQUMgbGV2YSBvcyBhcnF1aXZvcy1mb250ZSBj
REM b21vIGF1dG9yaWRhZGUuIE9zIGFycXVpdm9zCiAgICBjb21waWxhZG9zIGFudGlnb3Mgc8Oj
REM byBkZXNuZWNlc3PDoXJpb3MgbmEgcGFzdGEgbWVzY2xhZGEgZSBhdW1lbnRhbSBvIGN1c3Rv
REM CiAgICBkYSBjw7NwaWE7IG8gUmVuJ1B5IHBvZGUgcmVjb21waWxhciBvIGPDs2RpZ28gbmEg
REM cHJpbWVpcmEgaW5pY2lhbGl6YcOnw6NvLgogICAgIiIiCiAgICByZW1vdmlkb3M9W10KICAg
REM IGlmIG5vdCBvcy5wYXRoLmlzZGlyKHBhc3RhX3JhaXopOiByZXR1cm4gcmVtb3ZpZG9zCiAg
REM ICBmb3IgcGFzdGFfYXR1YWwsc3VicGFzdGFzLGFycXVpdm9zIGluIG9zLndhbGsocGFzdGFf
REM cmFpeik6CiAgICAgICAgc3VicGFzdGFzWzpdPVtkIGZvciBkIGluIHN1YnBhc3RhcyBpZiBk
REM Lmxvd2VyKCkgbm90IGluICh1J19fcHljYWNoZV9fJywpXQogICAgICAgIGZvciBub21lIGlu
REM IGxpc3QoYXJxdWl2b3MpOgogICAgICAgICAgICBpZiBub3Qgbm9tZS5sb3dlcigpLmVuZHN3
REM aXRoKCh1Jy5ycHljJyx1Jy5ycHltYycpKTogY29udGludWUKICAgICAgICAgICAgY2FtaW5o
REM bz1vcy5wYXRoLmpvaW4ocGFzdGFfYXR1YWwsbm9tZSkKICAgICAgICAgICAgdHJ5OgogICAg
REM ICAgICAgICAgICAgb3MucmVtb3ZlKGNhbWluaG8pCiAgICAgICAgICAgICAgICByZW1vdmlk
REM b3MuYXBwZW5kKG9zLnBhdGgucmVscGF0aChjYW1pbmhvLHBhc3RhX3JhaXopLnJlcGxhY2Uo
REM b3Muc2VwLCcvJykpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZXhjOgogICAg
REM ICAgICAgICAgICAgaWYgbG9nIGlzIG5vdCBOb25lOgogICAgICAgICAgICAgICAgICAgIGxv
REM Zy5hdmlzbyh1J07Do28gZm9pIHBvc3PDrXZlbCByZW1vdmVyIGNvbXBpbGFkbyB7fToge30n
REM LmZvcm1hdChvcy5wYXRoLnJlbHBhdGgoY2FtaW5obyxwYXN0YV9yYWl6KSxleGMpKQogICAg
REM aWYgbG9nIGlzIG5vdCBOb25lIGFuZCByZW1vdmlkb3M6CiAgICAgICAgbG9nLmluZm8odSdD
REM b21waWxhZG9zIHJlbW92aWRvcyBkYSBzYcOtZGEgbWVzY2xhZGE6IHt9Jy5mb3JtYXQobGVu
REM KHJlbW92aWRvcykpKQogICAgcmV0dXJuIHJlbW92aWRvcwoKCmRlZiBleGVjdXRhcl9yZWlu
REM amVjYW8ocmFpeik6CiAgICBpbmljaW9fdG90YWw9dGltZS50aW1lKCkKICAgIHBhc3RhX2dh
REM bWU9ZW5jb250cmFyX3Bhc3RhX2dhbWUocmFpeikKICAgIHBhc3RhX2VudHJhZGFfYmFzZSxu
REM b21lX21hcGFfcmVpbmo9bG9jYWxpemFyX3Bhc3RhX3JlaW5qZWNhbyhyYWl6KQogICAgcGFz
REM dGFfc2FpZGFfYmFzZT1vcy5wYXRoLmpvaW4ocmFpeixQQVNUQV9TQUlEQV9UUkFEVVpJRE9f
REM Tk9NRSkKICAgIGNhbWluaG9fbWFwYV9jb21wbGV0bz1vcy5wYXRoLmpvaW4ocGFzdGFfZW50
REM cmFkYV9iYXNlLG5vbWVfbWFwYV9yZWluaikgaWYgcGFzdGFfZW50cmFkYV9iYXNlIGVsc2Ug
REM Tm9uZQogICAgbm9tZV9wYXN0YV93cmFwPW9zLnBhdGguYmFzZW5hbWUob3MucGF0aC5ub3Jt
REM cGF0aChwYXN0YV9nYW1lKSkKICAgIHBhc3RhX3NhaWRhX3dyYXA9b3MucGF0aC5qb2luKHBh
REM c3RhX3NhaWRhX2Jhc2Usbm9tZV9wYXN0YV93cmFwKQoKICAgIGxvZz1Mb2cob3MucGF0aC5q
REM b2luKHJhaXosTk9NRV9MT0dfUkVJTkpFVE9SKSk7IGxvZy5zZXBhcmFkb3IoKTsgbG9nLnRp
REM dHVsbyh0KCJsb2dfY2FiX3JlaW5qZXRvciIpKTsgbG9nLnRpdHVsbyh0KCJsb2dfZGF0YWhv
REM cmEiKS5mb3JtYXQodGltZS5zdHJmdGltZSgiJWQvJW0vJVkgJUg6JU06JVMiKSkpOyBsb2cu
REM c2VwYXJhZG9yKCkKICAgIGxvZy5pbmZvKHQoImxvZ19wYXN0YV90cmFkdWNhbyIpLmZvcm1h
REM dChvcy5wYXRoLmJhc2VuYW1lKHBhc3RhX2VudHJhZGFfYmFzZSkgaWYgcGFzdGFfZW50cmFk
REM YV9iYXNlIGVsc2UgIi0iLHBhc3RhX2VudHJhZGFfYmFzZSBvciAiLSIpKTsgbG9nLmluZm8o
REM dCgibG9nX3Bhc3RhX29yaWdpbmFsIikuZm9ybWF0KHBhc3RhX2dhbWUpKTsgbG9nLmluZm8o
REM dCgibG9nX3Bhc3RhX3NhaWRhIikuZm9ybWF0KHBhc3RhX3NhaWRhX3dyYXApKQogICAgcHJp
REM bnQoIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PSIpOyBwcmludCh0KCJjYWJfcmVpbmpldGFyIikpOyBwcmludCgiPT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM Iik7IHByaW50KCIiKTsgcHJpbnQodCgicGFzdGFfdHJhZHVjYW8iKS5mb3JtYXQocGFzdGFf
REM ZW50cmFkYV9iYXNlIG9yICItIikpOyBwcmludCh0KCJwYXN0YV9vcmlnaW5hbCIpLmZvcm1h
REM dChwYXN0YV9nYW1lKSk7IHByaW50KHQoInBhc3RhX3NhaWRhMiIpLmZvcm1hdChwYXN0YV9z
REM YWlkYV93cmFwKSk7IHByaW50KCIiKQogICAgaWYgbm90IHBhc3RhX2VudHJhZGFfYmFzZToK
REM ICAgICAgICBtc2c9dCgiZXJyX3Bhc3RhX2VudHJhZGEiKTsgcHJpbnQodCgiZXJybyIpKyI6
REM ICIrbXNnKTsgbG9nLmVycm8obXNnKTsgbG9nLnNhbHZhcigpOyByZXR1cm4gMQogICAgaWYg
REM bm90IG9zLnBhdGguaXNmaWxlKGNhbWluaG9fbWFwYV9jb21wbGV0byk6CiAgICAgICAgbXNn
REM PXQoImVycl9tYXBhIikuZm9ybWF0KG5vbWVfbWFwYV9yZWluaixvcy5wYXRoLmJhc2VuYW1l
REM KHBhc3RhX2VudHJhZGFfYmFzZSkpOyBwcmludCh0KCJlcnJvIikrIjogIittc2cpOyBsb2cu
REM ZXJybyhtc2cpOyBsb2cuc2FsdmFyKCk7IHJldHVybiAxCgogICAgcHJpbnQodCgicmpfbW9k
REM b190aXR1bG8iKSk7IHByaW50KHUiIik7IHByaW50KHQoInJqX21vZG9fbm9ybWFsIikpOyBw
REM cmludCh0KCJyal9tb2RvX3NlZ3VybyIpKTsgcHJpbnQodSIiKQogICAgd2hpbGUgVHJ1ZToK
REM ICAgICAgICB0cnk6IGVzY29saGFfbW9kbz1pbnB1dCh0KCJyal9tb2RvX3Byb21wdCIpKS5z
REM dHJpcCgpIG9yICIxIgogICAgICAgIGV4Y2VwdCAoRU9GRXJyb3IsS2V5Ym9hcmRJbnRlcnJ1
REM cHQpOiBsb2cuYXZpc28odSJSZWludGVncmHDp8OjbyBjYW5jZWxhZGEgcGVsbyB1c3XDoXJp
REM by4iKTsgbG9nLnNhbHZhcigpOyByZXR1cm4gMAogICAgICAgIGlmIGVzY29saGFfbW9kbyBp
REM biAoIjEiLCIyIik6IGJyZWFrCiAgICAgICAgcHJpbnQodCgicmpfbW9kb19pbnZhbGlkbyIp
REM KQogICAgbW9kb19zZWd1cm89KGVzY29saGFfbW9kbz09IjIiKQoKICAgIHRyeToKICAgICAg
REM ICB3aXRoIGlvLm9wZW4oY2FtaW5ob19tYXBhX2NvbXBsZXRvLCJyIixlbmNvZGluZz0idXRm
REM LTgiKSBhcyBmOiBtYXBhX2NvbXBsZXRvPWpzb24ubG9hZChmKQogICAgZXhjZXB0IEV4Y2Vw
REM dGlvbiBhcyBleGM6CiAgICAgICAgbXNnPXQoImVycl9sZXJfbWFwYSIpLmZvcm1hdChOT01F
REM X01BUEEsZXhjKTsgcHJpbnQodCgiZXJybyIpKyI6ICIrbXNnKTsgbG9nLmVycm8obXNnKTsg
REM bG9nLnNhbHZhcigpOyByZXR1cm4gMQoKICAgIGNhbmRpZGF0b3M9Y29sZXRhcl9jYW5kaWRh
REM dG9zX3JlaW5qZWNhbyhwYXN0YV9lbnRyYWRhX2Jhc2UpCiAgICBwcmludCh0KCJldGFwYTFf
REM cmVpbmoiKS5mb3JtYXQob3MucGF0aC5iYXNlbmFtZShwYXN0YV9lbnRyYWRhX2Jhc2UpKSk7
REM IHByaW50KHQoImFycXVpdm9zX2VuY29udHJhZG9zIikuZm9ybWF0KGxlbihjYW5kaWRhdG9z
REM KSkpOyBsb2cuaW5mbyh0KCJsb2dfZXRhcGExX3JlaW5qIikuZm9ybWF0KGxlbihjYW5kaWRh
REM dG9zKSkpCgogICAgcHJpbnQoIiIpOyBwcmludCh0KCJyal92YWxpZGFjYW9fcHJlIikpOyBw
REM cmU9dmFsaWRhcl9wcmVfcmVpbnRlZ3JhY2FvKHBhc3RhX2dhbWUscGFzdGFfZW50cmFkYV9i
REM YXNlLG1hcGFfY29tcGxldG8sY2FuZGlkYXRvcykKICAgIHByaW50KHUiezB9OiB7MX0iLmZv
REM cm1hdCh0KCJyal9hcnF1aXZvc19lc3BlcmFkb3MiKSxwcmVbImFycXVpdm9zX2VzcGVyYWRv
REM cyJdKSk7IHByaW50KHUiezB9OiB7MX0iLmZvcm1hdCh0KCJyal9hcnF1aXZvc19vayIpLHBy
REM ZVsiYXJxdWl2b3NfdmFsaWRhZG9zIl0pKTsgcHJpbnQodSJ7MH06IHsxfSIuZm9ybWF0KHQo
REM InJqX2VudHJhZGFzX2VzcGVyYWRhcyIpLHByZVsiZW50cmFkYXNfZXNwZXJhZGFzIl0pKTsg
REM cHJpbnQodSJ7MH06IHsxfSIuZm9ybWF0KHQoInJqX2VudHJhZGFzX2VuY29udHJhZGFzIiks
REM cHJlWyJlbnRyYWRhc19lbmNvbnRyYWRhcyJdKSk7IHByaW50KHUiezB9OiB7MX0iLmZvcm1h
REM dCh0KCJyal90ZXh0b3NfYWx0ZXJhZG9zIikscHJlWyJhbHRlcmFkb3MiXSkpOyBwcmludCh1
REM InswfTogezF9Ii5mb3JtYXQodCgicmpfdGV4dG9zX2lndWFpcyIpLHByZVsiaWd1YWlzIl0p
REM KQogICAgZm9yIGsgaW4gKCJyal9hcnF1aXZvc19lc3BlcmFkb3MiLCJyal9hcnF1aXZvc19v
REM ayIsInJqX2VudHJhZGFzX2VzcGVyYWRhcyIsInJqX2VudHJhZGFzX2VuY29udHJhZGFzIiwi
REM cmpfdGV4dG9zX2FsdGVyYWRvcyIsInJqX3RleHRvc19pZ3VhaXMiKTogbG9nLnJlc3VsdGFk
REM byh0KGspLHN0cihwcmVbeydyal9hcnF1aXZvc19lc3BlcmFkb3MnOidhcnF1aXZvc19lc3Bl
REM cmFkb3MnLCdyal9hcnF1aXZvc19vayc6J2FycXVpdm9zX3ZhbGlkYWRvcycsJ3JqX2VudHJh
REM ZGFzX2VzcGVyYWRhcyc6J2VudHJhZGFzX2VzcGVyYWRhcycsJ3JqX2VudHJhZGFzX2VuY29u
REM dHJhZGFzJzonZW50cmFkYXNfZW5jb250cmFkYXMnLCdyal90ZXh0b3NfYWx0ZXJhZG9zJzon
REM YWx0ZXJhZG9zJywncmpfdGV4dG9zX2lndWFpcyc6J2lndWFpcyd9W2tdXSkpCiAgICBpZiBw
REM cmVbImVycm9zIl06CiAgICAgICAgcHJpbnQodCgicmpfdmFsaWRhY2FvX2ZhbGhvdSIpKTsK
REM ICAgICAgICBmb3IgZXJybyBpbiBwcmVbImVycm9zIl1bOjMwXTogcHJpbnQodSIgIC0gezB9
REM Ii5mb3JtYXQoZXJybykpOyBsb2cuZXJybyhlcnJvKQogICAgICAgIGlmIGxlbihwcmVbImVy
REM cm9zIl0pPjMwOiBsb2cuZXJybyh1Ii4uLiBlIG1haXMgezB9IGVycm8ocykuIi5mb3JtYXQo
REM bGVuKHByZVsiZXJyb3MiXSktMzApKQogICAgICAgIGxvZy5zYWx2YXIoKTsgcmV0dXJuIDEK
REM ICAgIHByaW50KHQoInJqX3ZhbGlkYWNhb19vayIpKQoKICAgIGlmIG1vZG9fc2VndXJvOgog
REM ICAgICAgIHRyeToKICAgICAgICAgICAgYmFja3VwPWNyaWFyX2JhY2t1cF9zYWlkYShyYWl6
REM LHBhc3RhX3NhaWRhX3dyYXApCiAgICAgICAgICAgIGlmIGJhY2t1cDogcHJpbnQodCgicmpf
REM YmFja3VwX29rIikuZm9ybWF0KGJhY2t1cCkpOyBsb2cuaW5mbyh0KCJyal9iYWNrdXBfb2si
REM KS5mb3JtYXQoYmFja3VwKSkKICAgICAgICAgICAgZWxzZTogcHJpbnQodCgicmpfYmFja3Vw
REM X25hbyIpKTsgbG9nLmluZm8odCgicmpfYmFja3VwX25hbyIpKQogICAgICAgIGV4Y2VwdCBF
REM eGNlcHRpb24gYXMgZXhjOgogICAgICAgICAgICBtc2c9dSJGYWxoYSBhbyBjcmlhciBiYWNr
REM dXAgc2VndXJvOiB7MH0iLmZvcm1hdChleGMpOyBwcmludCh0KCJlcnJvIikrIjogIittc2cp
REM OyBsb2cuZXJybyhtc2cpOyBsb2cuc2FsdmFyKCk7IHJldHVybiAxCgogICAgcHJpbnQoIiIp
REM OyBwcmludCh0KCJldGFwYTJfcmVpbmoiKSk7IGxvZy5pbmZvKHQoImV0YXBhMl9yZWluaiIp
REM KQogICAgcHJpbnQodSIgIFByZXBhcmFuZG8gYSBwYXN0YSBkZSBzYcOtZGEgZSBpbnZhbGlk
REM YW5kbyBjb21waWxhZG9zIGFudGlnb3MuLi4iLCBmbHVzaD1UcnVlKQogICAgdHJ5OgogICAg
REM ICAgIGlmIG9zLnBhdGguaXNkaXIocGFzdGFfc2FpZGFfd3JhcCk6IHNodXRpbC5ybXRyZWUo
REM cGFzdGFfc2FpZGFfd3JhcCkKICAgICAgICBzaHV0aWwuY29weXRyZWUocGFzdGFfZ2FtZSxw
REM YXN0YV9zYWlkYV93cmFwKQogICAgICAgIGxvZy5pbmZvKHUiR2FtZSBvcmlnaW5hbCBjb3Bp
REM YWRvIGludGVncmFsbWVudGUgcGFyYSBhIHNhw61kYSBhbnRlcyBkYSByZWludGVncmHDp8Oj
REM by4iKQogICAgICAgIGNvbXBpbGFkb3Nfc29tYnJlYWRvcyA9IGxpbXBhcl9jb21waWxhZG9z
REM X3NvbWJyZWFkb3MocGFzdGFfc2FpZGFfd3JhcCwgbG9nPWxvZykKICAgICAgICBpZiBjb21w
REM aWxhZG9zX3NvbWJyZWFkb3M6CiAgICAgICAgICAgIHByaW50KHUiICBDb21waWxhZG9zIGFu
REM dGlnb3MgaW52YWxpZGFkb3M6IHt9IGFycXVpdm8ocykuIEVsZXMgc2Vyw6NvIHJlY29tcGls
REM YWRvcyBwZWxvIFJlbidQeSBxdWFuZG8gbmVjZXNzw6FyaW8uIi5mb3JtYXQobGVuKGNvbXBp
REM bGFkb3Nfc29tYnJlYWRvcykpLCBmbHVzaD1UcnVlKQogICAgICAgIGVsc2U6CiAgICAgICAg
REM ICAgIHByaW50KHUiICBOZW5odW0gY29tcGlsYWRvIHNvbWJyZWFkbyBwcmVjaXNvdSBzZXIg
REM aW52YWxpZGFkby4iLCBmbHVzaD1UcnVlKQogICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBleGM6
REM CiAgICAgICAgbXNnPXUiRmFsaGEgYW8gY29waWFyIG8gZ2FtZSBvcmlnaW5hbCBwYXJhIGEg
REM c2HDrWRhOiB7MH0iLmZvcm1hdChleGMpOyBwcmludCh0KCJlcnJvIikrIjogIittc2cpOyBs
REM b2cuZXJybyhtc2cpOyBsb2cuc2FsdmFyKCk7IHJldHVybiAxCgogICAgdG90YWxfb2s9dG90
REM YWxfZmFsaGE9dG90YWxfbGluaGFzX3JlaW5qZXRhZGFzPTA7IHNlbV9tYXBhPVtdOyBhcnF1
REM aXZvc190b3RhbD1sZW4oY2FuZGlkYXRvcyk7IG1vZGlmaWNhZG9zPTAKICAgIHByaW50KHUi
REM ICBQcm9ncmVzc28gZGEgcmVpbnRlZ3Jhw6fDo286IDAuMCUgfCBbPiAgICAgICAgICAgICAg
REM ICAgICAgICAgICBdIiwgZmx1c2g9VHJ1ZSkKICAgIHVsdGltb19wcm9ncmVzc28gPSAtMQog
REM ICAgcHJvZ3Jlc3NvX3Bhc3NvID0gbWF4KDEsIGludCgxMDAuMCAvIDIwLjApKQogICAgZm9y
REM IG51bWVybyxjYW1pbmhvX3RyYWR1emlkbyBpbiBlbnVtZXJhdGUoY2FuZGlkYXRvcywxKToK
REM ICAgICAgICBjYW1pbmhvX3JlbGF0aXZvPW9zLnBhdGgucmVscGF0aChjYW1pbmhvX3RyYWR1
REM emlkbyxwYXN0YV9lbnRyYWRhX2Jhc2UpOyBjaGF2ZT1jYW1pbmhvX3JlbGF0aXZvLnJlcGxh
REM Y2Uob3Muc2VwLCIvIik7IGNhbWluaG9fb3JpZ2luYWw9b3MucGF0aC5qb2luKHBhc3RhX2dh
REM bWUsY2FtaW5ob19yZWxhdGl2bykKICAgICAgICB0cnk6CiAgICAgICAgICAgIGVudHJhZGFz
REM X21hcGE9bWFwYV9jb21wbGV0by5nZXQoY2hhdmUpCiAgICAgICAgICAgIGlmIGVudHJhZGFz
REM X21hcGEgaXMgTm9uZToKICAgICAgICAgICAgICAgIGlmIGNhbWluaG9fdHJhZHV6aWRvLmxv
REM d2VyKCkuZW5kc3dpdGgoIi50eHQiKToKICAgICAgICAgICAgICAgICAgICAjIFRYVCBxdWUg
REM bsOjbyBwZXJ0ZW5jZSBhbyBiYW5jbyBkZSBwYWxhdnJhcyBwZXJtYW5lY2UgY29tbyBjw7Nw
REM aWEKICAgICAgICAgICAgICAgICAgICAjIG9yaWdpbmFsOyBlbGUgbsOjbyBwYXJ0aWNpcGEg
REM ZGEgdHJhZHXDp8Ojby4KICAgICAgICAgICAgICAgICAgICBjb3BpYXJfYXJxdWl2b190eHQo
REM Y2FtaW5ob190cmFkdXppZG8sb3MucGF0aC5qb2luKHBhc3RhX3NhaWRhX3dyYXAsY2FtaW5o
REM b19yZWxhdGl2bykpOyB0b3RhbF9vays9MQogICAgICAgICAgICAgICAgZWxzZToKICAgICAg
REM ICAgICAgICAgICAgICBzZW1fbWFwYS5hcHBlbmQoY2FtaW5ob19yZWxhdGl2bykKICAgICAg
REM ICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHRleHRvc190cmFkdXppZG9zPWxlcl90ZXh0
REM b3NfdHJhZHV6aWRvcyhjYW1pbmhvX3RyYWR1emlkbyk7IGxpbmhhc19yZXN1bHRhZG8sZXJy
REM b3M9cmVpbmpldGFyX2FycXVpdm8oY2FtaW5ob19vcmlnaW5hbCxlbnRyYWRhc19tYXBhLHRl
REM eHRvc190cmFkdXppZG9zKQogICAgICAgICAgICAgICAgaWYgZXJyb3M6CiAgICAgICAgICAg
REM ICAgICAgICAgdG90YWxfZmFsaGErPTEKICAgICAgICAgICAgICAgICAgICBmb3IgZSBpbiBl
REM cnJvczogbG9nLmVycm8odSJ7MH06IHsxfSIuZm9ybWF0KGNhbWluaG9fcmVsYXRpdm8sZSkp
REM CiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGNhbWluaG9fc2Fp
REM ZGE9b3MucGF0aC5qb2luKHBhc3RhX3NhaWRhX3dyYXAsY2FtaW5ob19yZWxhdGl2byk7IHBh
REM c3RhX3NhaWRhPW9zLnBhdGguZGlybmFtZShjYW1pbmhvX3NhaWRhKQogICAgICAgICAgICAg
REM ICAgICAgIGlmIHBhc3RhX3NhaWRhIGFuZCBub3Qgb3MucGF0aC5pc2RpcihwYXN0YV9zYWlk
REM YSk6IG9zLm1ha2VkaXJzKHBhc3RhX3NhaWRhKQogICAgICAgICAgICAgICAgICAgIHdpdGgg
REM aW8ub3BlbihjYW1pbmhvX3NhaWRhLCJ3IixlbmNvZGluZz0idXRmLTgiLG5ld2xpbmU9IiIp
REM IGFzIGY6IGYud3JpdGUodSIiLmpvaW4obGluaGFzX3Jlc3VsdGFkbykpCiAgICAgICAgICAg
REM ICAgICAgICAgdG90YWxfb2srPTE7IHRvdGFsX2xpbmhhc19yZWluamV0YWRhcys9bGVuKGVu
REM dHJhZGFzX21hcGEpOyBtb2RpZmljYWRvcyArPSAxIGlmIGFueShub3QgY29tcGFyYXJfbGl0
REM ZXJhbF90cmFkdWNhbyh0ZXh0b3NfdHJhZHV6aWRvc1tpXSwgZW50cmFkYXNfbWFwYVtpXS5n
REM ZXQoIm9yaWdpbmFsIiwgIiIpLCBlbnRyYWRhc19tYXBhW2ldLmdldCgidGlwbyIpKSBmb3Ig
REM aSBpbiByYW5nZShsZW4oZW50cmFkYXNfbWFwYSkpKSBlbHNlIDAKICAgICAgICBleGNlcHQg
REM RXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICAgICAgdG90YWxfZmFsaGErPTE7IGxvZy5lcnJv
REM KHUiezB9OiB7MX0iLmZvcm1hdChjYW1pbmhvX3JlbGF0aXZvLGV4YykpCiAgICAgICAgbWFy
REM Y2Fkb3IgPSBpbnQoKDEwMC4wICogbnVtZXJvKSAvIG1heCgxLGFycXVpdm9zX3RvdGFsKSkK
REM ICAgICAgICBpZiBtYXJjYWRvciAhPSB1bHRpbW9fcHJvZ3Jlc3NvIGFuZCAobWFyY2Fkb3Ig
REM JSBwcm9ncmVzc29fcGFzc28gPT0gMCBvciBudW1lcm8gPT0gYXJxdWl2b3NfdG90YWwpOgog
REM ICAgICAgICAgICB1bHRpbW9fcHJvZ3Jlc3NvID0gbWFyY2Fkb3IKICAgICAgICAgICAgcHJp
REM bnQodSJcciAgUHJvZ3Jlc3NvIGRhIHJlaW50ZWdyYcOnw6NvOiB7OjUuMWZ9JSB8IHs6PjR9
REM L3s6PDR9IHt9Ii5mb3JtYXQoCiAgICAgICAgICAgICAgICAxMDAuMCAqIG51bWVybyAvIG1h
REM eCgxLGFycXVpdm9zX3RvdGFsKSwgbnVtZXJvLCBhcnF1aXZvc190b3RhbCwKICAgICAgICAg
REM ICAgICAgIGJhcnJhX3Byb2dyZXNzbyhudW1lcm8sbWF4KDEsYXJxdWl2b3NfdG90YWwpKQog
REM ICAgICAgICAgICApLCBlbmQ9dSIiLCBmbHVzaD1UcnVlKQogICAgcHJpbnQodSIiKQoKICAg
REM IHByaW50KHUiRVRBUEEgMTMvMTQgLSBWYWxpZGHDp8OjbyBkYSBzYcOtZGE6IHZlcmlmaWNh
REM bmRvIGFycXVpdm9zLCBpbnRlZ3JpZGFkZSBlIGNvbXBpbGFkb3MgaW52YWxpZGFkb3MuLi4i
REM LCBmbHVzaD1UcnVlKQogICAgcHJpbnQoIiIpOyBwcmludCh0KCJyal92YWxpZGFjYW9fcG9z
REM IikpOyBwb3M9dmFsaWRhcl9wb3NfcmVpbnRlZ3JhY2FvKHBhc3RhX2dhbWUscGFzdGFfc2Fp
REM ZGFfd3JhcCxwYXN0YV9lbnRyYWRhX2Jhc2UsbWFwYV9jb21wbGV0byxjYW5kaWRhdG9zLGNv
REM bXBpbGFkb3Nfc29tYnJlYWRvcyk7IHByaW50KHUiezB9OiB7MX0iLmZvcm1hdCh0KCJyal9k
REM aWZlcmVuY2FzIiksbGVuKHBvc1siZXJyb3MiXSkpKTsgbG9nLnJlc3VsdGFkbyh0KCJyal9k
REM aWZlcmVuY2FzIiksc3RyKGxlbihwb3NbImVycm9zIl0pKSkKICAgIGlmIHBvc1siZXJyb3Mi
REM XToKICAgICAgICBwcmludCh0KCJyal92YWxpZGFjYW9fZmFsaG91IikpOwogICAgICAgIGZv
REM ciBlcnJvIGluIHBvc1siZXJyb3MiXVs6MzBdOiBwcmludCh1IiAgLSB7MH0iLmZvcm1hdChl
REM cnJvKSk7IGxvZy5lcnJvKGVycm8pCiAgICAgICAgaWYgbGVuKHBvc1siZXJyb3MiXSk+MzA6
REM IGxvZy5lcnJvKHUiLi4uIGUgbWFpcyB7MH0gZXJybyhzKS4iLmZvcm1hdChsZW4ocG9zWyJl
REM cnJvcyJdKS0zMCkpCiAgICAgICAgbG9nLnNhbHZhcigpOyByZXR1cm4gMQogICAgcHJpbnQo
REM dCgicmpfdmFsaWRhY2FvX29rIikpCgogICAgZGVjb3JyaWRvPXRpbWUudGltZSgpLWluaWNp
REM b190b3RhbDsgdmVsb2NpZGFkZT1mbG9hdCh0b3RhbF9saW5oYXNfcmVpbmpldGFkYXMpL21h
REM eCgwLjAwMSxkZWNvcnJpZG8pCiAgICBwcmludCgiIik7IHByaW50KHQoInJlc190cmFkX2Vu
REM Y29udHJhZG9zIikuZm9ybWF0KGxlbihjYW5kaWRhdG9zKSkpOyBwcmludCh0KCJyZXNfcmVp
REM bmpfb2siKS5mb3JtYXQodG90YWxfb2spKTsgcHJpbnQodCgicmVzX3JlaW5qX2ZhbGhhIiku
REM Zm9ybWF0KHRvdGFsX2ZhbGhhKSk7IHByaW50KHQoInJlc19yZWlual9saW5oYXMiKS5mb3Jt
REM YXQodG90YWxfbGluaGFzX3JlaW5qZXRhZGFzKSk7IHByaW50KHUiezB9OiB7MX0iLmZvcm1h
REM dCh0KCJyal9tb2RpZmljYWRvcyIpLG1vZGlmaWNhZG9zKSk7IHByaW50KHUiezB9OiB7MX0i
REM LmZvcm1hdCh0KCJyal90ZXh0b3NfYWx0ZXJhZG9zIikscHJlWyJhbHRlcmFkb3MiXSkpOyBw
REM cmludCh1InswfTogezF9Ii5mb3JtYXQodCgicmpfdGV4dG9zX2lndWFpcyIpLHByZVsiaWd1
REM YWlzIl0pKTsgcHJpbnQodSJ7MH06IHsxOi4xZn1zIi5mb3JtYXQodCgicmpfdGVtcG8iKSxk
REM ZWNvcnJpZG8pKTsgcHJpbnQodSJ7MH06IHsxOi4xZn0gbGluaGFzL3MiLmZvcm1hdCh0KCJy
REM al92ZWxvY2lkYWRlIiksdmVsb2NpZGFkZSkpOyBwcmludCh1InswfSAxMDAlIi5mb3JtYXQo
REM YmFycmFfcHJvZ3Jlc3NvKGFycXVpdm9zX3RvdGFsLG1heCgxLGFycXVpdm9zX3RvdGFsKSkp
REM KQogICAgbG9nLnNlcGFyYWRvcigpOyBsb2cucmVzdWx0YWRvKHQoImxvZ19yZXNfdHJhZF9l
REM bmNvbnRyYWRvcyIpLHN0cihsZW4oY2FuZGlkYXRvcykpKTsgbG9nLnJlc3VsdGFkbyh0KCJs
REM b2dfcmVzX29rIiksc3RyKHRvdGFsX29rKSk7IGxvZy5yZXN1bHRhZG8odCgibG9nX3Jlc19m
REM YWxoYXMiKSxzdHIodG90YWxfZmFsaGEpKTsgbG9nLnJlc3VsdGFkbyh0KCJsb2dfcmVzX3Nl
REM bV9tYXBhIiksc3RyKGxlbihzZW1fbWFwYSkpKTsgbG9nLnJlc3VsdGFkbyh0KCJsb2dfcmVz
REM X2xpbmhhc19yZWluaiIpLHN0cih0b3RhbF9saW5oYXNfcmVpbmpldGFkYXMpKTsgbG9nLnJl
REM c3VsdGFkbyh0KCJyal9tb2RpZmljYWRvcyIpLHN0cihtb2RpZmljYWRvcykpOyBsb2cucmVz
REM dWx0YWRvKHQoInJqX3RleHRvc19hbHRlcmFkb3MiKSxzdHIocHJlWyJhbHRlcmFkb3MiXSkp
REM OyBsb2cucmVzdWx0YWRvKHQoInJqX3RleHRvc19pZ3VhaXMiKSxzdHIocHJlWyJpZ3VhaXMi
REM XSkpOyBsb2cucmVzdWx0YWRvKHQoInJqX3RlbXBvIiksdSJ7MDouMWZ9cyIuZm9ybWF0KGRl
REM Y29ycmlkbykpOyBsb2cucmVzdWx0YWRvKHQoInJqX3ZlbG9jaWRhZGUiKSx1InswOi4xZn0g
REM bGluaGFzL3MiLmZvcm1hdCh2ZWxvY2lkYWRlKSk7IGxvZy5zZXBhcmFkb3IoKTsgbG9nLnNh
REM bHZhcigpOyBwcmludCgiIik7IHByaW50KHQoImxvZ19zYWx2byIpLmZvcm1hdChsb2cuY2Ft
REM aW5obykpOyByZXR1cm4gMCBpZiB0b3RhbF9mYWxoYT09MCBlbHNlIDEKCgpkZWYgZXhlY3V0
REM YXJfZGV0ZWNjYW9fc2RrKHJhaXopOgogICAgcGFzdGFfZ2FtZSA9IGVuY29udHJhcl9wYXN0
REM YV9nYW1lKHJhaXopCiAgICBpZiBub3QgcGFzdGFfZ2FtZToKICAgICAgICBwcmludCgiRERB
REM Q19UQVJHRVRfVkVSU0lPTj0iKQogICAgICAgIHByaW50KCJEREFDX1NES19WRVJTSU9OPSIp
REM CiAgICAgICAgcHJpbnQoIkREQUNfVEFSR0VUX0ZBTUlMWT0iKQogICAgICAgIHByaW50KCJE
REM REFDX1RBUkdFVF9FVklERU5DRT0iKQogICAgICAgIHByaW50KCJEREFDX1RBUkdFVF9GQUxM
REM QkFDSz0iKQogICAgICAgIHJldHVybiAxCiAgICB0cnk6CiAgICAgICAgY2FuZGlkYXRvcyA9
REM IGNvbGV0YXJfY2FuZGlkYXRvc19leHRyYWNhbyhwYXN0YV9nYW1lKQogICAgZXhjZXB0IEV4
REM Y2VwdGlvbjoKICAgICAgICBjYW5kaWRhdG9zID0gW10KICAgIGFsdm8sIGV2aWRlbmNpYXMg
REM PSBfZGV0ZWN0YXJfdmVyc2FvX3Byb2pldG9fcmVucHkocGFzdGFfZ2FtZSwgY2FuZGlkYXRv
REM cykKICAgIGFsdm9fdGV4dG8gPSAiLiIuam9pbihzdHIoeCkgZm9yIHggaW4gYWx2bykgaWYg
REM YWx2byBlbHNlICIiCiAgICBpZiBhbHZvIGFuZCBsZW4oYWx2bykgPj0gMzoKICAgICAgICAj
REM IE8gbG9nIGUgYSB2ZXJzw6NvIG9maWNpYWwgZG8gU0RLIHVzYW0gMyBjb21wb25lbnRlcy4K
REM ICAgICAgICBzZGtfdHVwbGUgPSB0dXBsZShhbHZvWzozXSkKICAgICAgICBzZGtfdGV4dG8g
REM PSAiLiIuam9pbihzdHIoeCkgZm9yIHggaW4gc2RrX3R1cGxlKQogICAgICAgIGZhbGxiYWNr
REM ID0gIk5BTyIKICAgICAgICBmYW1pbGlhID0gc3RyKGFsdm9bMF0pCiAgICBlbGlmIGFsdm86
REM CiAgICAgICAgIyBGYW3DrWxpYSAoNi83LzgpIGFqdWRhIG5vIGRpYWduw7NzdGljbywgbWFz
REM IG7Do28gYXV0b3JpemEgYmFpeGFyIHVtIFNESwogICAgICAgICMgcG9yIHVtYSBVUkwgaW5j
REM b21wbGV0YSBjb21vIHJlbnB5Lm9yZy9kbC83Ly4KICAgICAgICBzZGtfdGV4dG8gPSAiIgog
REM ICAgICAgIGZhbWlsaWEgPSBzdHIoYWx2b1swXSkKICAgICAgICBmYWxsYmFjayA9ICJTSU1f
REM RkFNSUxJQSIKICAgIGVsc2U6CiAgICAgICAgc2RrX3RleHRvID0gIiIKICAgICAgICBmYW1p
REM bGlhID0gIiIKICAgICAgICBmYWxsYmFjayA9ICJTSU1fU0VNX0VWSURFTkNJQSIKICAgIGV2
REM aWRlbmNpYSA9IGV2aWRlbmNpYXNbMF1bMV0gaWYgZXZpZGVuY2lhcyBlbHNlICIiCiAgICBw
REM cmludCgiRERBQ19UQVJHRVRfVkVSU0lPTj0iICsgYWx2b190ZXh0bykKICAgIHByaW50KCJE
REM REFDX1NES19WRVJTSU9OPSIgKyBzZGtfdGV4dG8pCiAgICBwcmludCgiRERBQ19UQVJHRVRf
REM RkFNSUxZPSIgKyBmYW1pbGlhKQogICAgcHJpbnQoIkREQUNfVEFSR0VUX0VWSURFTkNFPSIg
REM KyBldmlkZW5jaWEucmVwbGFjZSgiPSIsICIiKSkKICAgIHByaW50KCJEREFDX1RBUkdFVF9G
REM QUxMQkFDSz0iICsgZmFsbGJhY2spCiAgICByZXR1cm4gMCBpZiBzZGtfdGV4dG8gZWxzZSAx
REM CgpkZWYgZXhlY3V0YXJfdGVzdGVfY29iZXJ0dXJhX3NpbnRheGVfcmVucHkoKToKICAgICIi
REM IlRlc3RhIG1lbnVzIGFuaW5oYWRvcywgbXVsdGlsaW5oYS9fcCwgbW9uw7Nsb2dvIHRyaXBs
REM bywgcmF3L2JhY2t0aWNrIGUgW10gYW5pbmhhZG8uIiIiCiAgICB3aXRoIHRlbXBmaWxlLlRl
REM bXBvcmFyeURpcmVjdG9yeShwcmVmaXg9J2RkYWNfc2ludGF4ZV8nKSBhcyB0ZDoKICAgICAg
REM ICBnYW1lPW9zLnBhdGguam9pbih0ZCwnZ2FtZScpOyBvcy5tYWtlZGlycyhnYW1lKQogICAg
REM ICAgIGNhbWluaG89b3MucGF0aC5qb2luKGdhbWUsJ3Rlc3RlLnJweScpCiAgICAgICAgdGV4
REM dG89KAogICAgICAgICAgICAnbGFiZWwgc3RhcnQ6XG4nCiAgICAgICAgICAgICcgICAgbWVu
REM dTpcbicKICAgICAgICAgICAgJyAgICAgICAgIk1lbnUgZXh0ZXJubyI6XG4nCiAgICAgICAg
REM ICAgICcgICAgICAgICAgICBtZW51OlxuJwogICAgICAgICAgICAnICAgICAgICAgICAgICAg
REM ICJTdWJtZW51IjpcbicKICAgICAgICAgICAgJyAgICAgICAgICAgICAgICAgICAgcGFzc1xu
REM JwogICAgICAgICAgICAnICAgICAgICAgICAgIkRlcG9pcyBkbyBzdWJtZW51IjpcbicKICAg
REM ICAgICAgICAgJyAgICAgICAgICAgICAgICBwYXNzXG4nCiAgICAgICAgICAgICcgICAgICAg
REM IHIiUmF3IHRyYWR1esOtdmVsIjpcbicKICAgICAgICAgICAgJyAgICAgICAgICAgIHBhc3Nc
REM bicKICAgICAgICAgICAgJyAgICAgICAgYEJhY2t0aWNrIHRyYWR1esOtdmVsYDpcbicKICAg
REM ICAgICAgICAgJyAgICAgICAgICAgIHBhc3NcbicKICAgICAgICAgICAgJyAgICBkZWZpbmVf
REM dGV4dCA9IF9wKCIiIlxuJwogICAgICAgICAgICAnICAgICAgICBQcmltZWlyYSBsaW5oYSB0
REM cmFkdXrDrXZlbC5cbicKICAgICAgICAgICAgJ1xuJwogICAgICAgICAgICAnICAgICAgICBT
REM ZWd1bmRhIGxpbmhhIHRyYWR1esOtdmVsLlxuJwogICAgICAgICAgICAnICAgICAgICAiIiIp
REM XG4nCiAgICAgICAgICAgICcgICAgZSAiIiJcbicKICAgICAgICAgICAgJyAgICAgICAgTW9u
REM w7Nsb2dvIHVtLlxuJwogICAgICAgICAgICAnXG4nCiAgICAgICAgICAgICcgICAgICAgIE1v
REM bsOzbG9nbyBkb2lzLlxuJwogICAgICAgICAgICAnICAgICAgICAiIiJcbicKICAgICAgICAg
REM ICAgJyAgICBlIHIiUmF3IFtwbGF5ZXIubmFtZXNbMF1dIGUge2l9dGFney9pfSJcbicKICAg
REM ICAgICAgICAgJyAgICB5IC1zX2RhcmsgZTFkIGIxZiA0cCA1YyAiVHVkbyBjZXJ0by4iXG4n
REM CiAgICAgICAgKQogICAgICAgIHdpdGggaW8ub3BlbihjYW1pbmhvLCd3JyxlbmNvZGluZz0n
REM dXRmLTgnLG5ld2xpbmU9JycpIGFzIGY6IGYud3JpdGUodGV4dG8pCiAgICAgICAgbWFwYV9v
REM dXQ9b3MucGF0aC5qb2luKHRkLCdvdXQnKQogICAgICAgIG9zLm1ha2VkaXJzKG1hcGFfb3V0
REM KQogICAgICAgICMgQ29udGV4dG8gbcOtbmltbzogbyBleHRyYXRvciB0cmFiYWxoYSBzZW0g
REM U0RLIG5lc3RlIHRlc3RlLgogICAgICAgIHRleHRvcyxtYXBhPWV4dHJhaXJfYXJxdWl2b19j
REM b21fbWFwYShjYW1pbmhvLHNldCgpLGNvbnN0cnVpcl9pbmRpY2VfYXJxdWl2b3MoZ2FtZSks
REM eydwZXJzb25hZ2Vucyc6c2V0KCksJ25vbWVzX3BlcnNvbmFnZW1fdmFyaWF2ZWlzJzpzZXQo
REM KSwndmFyaWF2ZWlzX3RlY25pY2FzJzpzZXQoKSwnbm9tZXNfZG9fam9nbyc6c2V0KCl9LE5v
REM bmUpCiAgICAgICAgbWFwYT1fZW5yaXF1ZWNlcl9tYXBhX2ludGVncmlkYWRlKG1hcGEsY2Ft
REM aW5obywndGVzdGUucnB5JykKICAgICAgICBvcmlnaW5hbHM9W3guZ2V0KCdvcmlnaW5hbCcs
REM JycpIGZvciB4IGluIG1hcGFdCiAgICAgICAgcmVxdWlyZWQ9KHUnIkRlcG9pcyBkbyBzdWJt
REM ZW51IjonLCB1JyJSYXcgdHJhZHV6w612ZWwiOicsIHUnYEJhY2t0aWNrIHRyYWR1esOtdmVs
REM YCcpCiAgICAgICAgaWYgbm90IGFueSgnRGVwb2lzIGRvIHN1Ym1lbnUnIGluIHggZm9yIHgg
REM aW4gb3JpZ2luYWxzKToKICAgICAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdtZW51IGFu
REM aW5oYWRvOiBvcMOnw6NvIGFww7NzIHN1Ym1lbnUgbsOjbyBmb2kgZXh0cmHDrWRhJykKICAg
REM ICAgICBvYnJpZ2F0b3Jpb3M9KCdzb3VyY2Vfc2hhMjU2JywnZW50cnlfaWQnLCdsb2dpY2Fs
REM X2dyb3VwX2lkJywndG9rZW5fc2lnbmF0dXJlJywnc291cmNlX2xpbmVfaGFzaCcsJ2NvbnRl
REM eHRfaGFzaCcpCiAgICAgICAgaWYgYW55KGsgbm90IGluIG1hcGFbMF0gZm9yIGsgaW4gb2Jy
REM aWdhdG9yaW9zKToKICAgICAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdtYXBhIGRlIGlu
REM dGVncmlkYWRlOiBjYW1wb3MgYWRpY2lvbmFpcyBhdXNlbnRlcycpCiAgICAgICAgaWYgbm90
REM IGFueSgnUmF3IHRyYWR1esOtdmVsJyBpbiB4IGZvciB4IGluIG9yaWdpbmFscyk6CiAgICAg
REM ICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcigic3RyaW5nIHJhdyBSZW4nUHkgbsOjbyBmb2kg
REM ZXh0cmHDrWRhIikKICAgICAgICBpZiBub3QgYW55KCdCYWNrdGljayB0cmFkdXrDrXZlbCcg
REM aW4geCBmb3IgeCBpbiBvcmlnaW5hbHMpOgogICAgICAgICAgICByYWlzZSBSdW50aW1lRXJy
REM b3IoJ3N0cmluZyBjb20gYmFja3RpY2sgbsOjbyBmb2kgZXh0cmHDrWRhJykKICAgICAgICBn
REM ZXR0ZXh0X3NhbXBsZSA9ICd4ID0gX3AoIiIiXG5QcmltZWlyYSBsaW5oYSB0cmFkdXrDrXZl
REM bC5cblNlZ3VuZGEgbGluaGEuXG4iIiIpJwogICAgICAgIGdwLCBfZ2wgPSBleHRyYWlyX3N0
REM cmluZ3NfZ2V0dGV4dF9tdWx0aWxpbmhhKCdzYW1wbGUucnB5JywgZ2V0dGV4dF9zYW1wbGUu
REM c3BsaXRsaW5lcyhUcnVlKSkKICAgICAgICBpZiBub3QgZ3A6CiAgICAgICAgICAgIHJhaXNl
REM IFJ1bnRpbWVFcnJvcignc3RyaW5nIG11bHRpbGluaGEgX3AgbsOjbyBmb2kgZXh0cmHDrWRh
REM IHBlbG8gZGV0ZWN0b3IgZXhwbMOtY2l0bycpCiAgICAgICAgcG9lbV9nZXR0ZXh0ID0gJ3Bv
REM ZW1fcmVzcG9uc2VzL3BvZW1zLnJweScKICAgICAgICBwcCwgXyA9IGV4dHJhaXJfc3RyaW5n
REM c19nZXR0ZXh0X211bHRpbGluaGEocG9lbV9nZXR0ZXh0LCBnZXR0ZXh0X3NhbXBsZS5zcGxp
REM dGxpbmVzKFRydWUpKQogICAgICAgIGlmIG5vdCBwcDoKICAgICAgICAgICAgcmFpc2UgUnVu
REM dGltZUVycm9yKCdwb2VtX3Jlc3BvbnNlcy9wb2Vtcy5ycHkgZm9pIGJsb3F1ZWFkbyBpbmRl
REM dmlkYW1lbnRlIHBhcmEgX3AgbXVsdGlsaW5oYScpCiAgICAgICAgYmxvY2tlZCwgXyA9IGV4
REM dHJhaXJfc3RyaW5nc19nZXR0ZXh0X211bHRpbGluaGEoJ3BvZW1fcmVzcG9uc2VzLycgKyBQ
REM T0VNUkVTUE9OU0VTX0JBU0VfTkFNRSwgZ2V0dGV4dF9zYW1wbGUuc3BsaXRsaW5lcyhUcnVl
REM KSkKICAgICAgICBpZiBibG9ja2VkOgogICAgICAgICAgICByYWlzZSBSdW50aW1lRXJyb3Io
REM J3NjcmlwdC1wb2VtcmVzcG9uc2VzLnJweSBuw6NvIGZvaSBibG9xdWVhZG8gY29tbyBzb2xp
REM Y2l0YWRvJykKICAgICAgICByYXdfc2luZ2xlPSdyIkhlbGxvIicKICAgICAgICBpZiBub3Qg
REM YW55KHEgPT0gJyJIZWxsbyInIGFuZCByYXcgZm9yIF8sXyxxLHJhdyBpbiBpdGVyX3JlbnB5
REM X2xpdGVyYWlzX2VzcGVjaWFpcyhyYXdfc2luZ2xlKSk6CiAgICAgICAgICAgIHJhaXNlIFJ1
REM bnRpbWVFcnJvcignc3RyaW5nIHJhdyBzaW1wbGVzIG7Do28gZm9pIHJlY29uaGVjaWRhJykK
REM ICAgICAgICBpZiBub3QgYW55KGUuZ2V0KCd0aXBvJykgaW4gKCdtdWx0aWxpbmhhX3JlbnB5
REM JywgJ21vbm9sb2dvX3RyaXBsYXMnKSBmb3IgZSBpbiBtYXBhKToKICAgICAgICAgICAgcmFp
REM c2UgUnVudGltZUVycm9yKCdtdWx0aWxpbmhhL19wIG91IG1vbsOzbG9nbyB0cmlwbG8gbsOj
REM byBmb2kgZXh0cmHDrWRvJykKICAgICAgICBpZiBub3QgYW55KCdQcmltZWlyYSBsaW5oYSB0
REM cmFkdXrDrXZlbCcgaW4geCBmb3IgeCBpbiBvcmlnaW5hbHMpOgogICAgICAgICAgICByYWlz
REM ZSBSdW50aW1lRXJyb3IoJ19wIGNvbSBhc3BhcyB0cmlwbGFzIG7Do28gZm9pIGV4dHJhw61k
REM bycpCiAgICAgICAgaWYgbm90IGFueSgnVHVkbyBjZXJ0by4nIGluIHggZm9yIHggaW4gb3Jp
REM Z2luYWxzKToKICAgICAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdmYWxhIGNvbSBhdHJp
REM YnV0b3MgKC1hdHRyL0ApIG7Do28gZm9pIGV4dHJhw61kYScpCiAgICAgICAgaWYgbm90IGFu
REM eSgnW3BsYXllci5uYW1lc1swXV0nIGluIHggZm9yIHggaW4gb3JpZ2luYWxzKToKICAgICAg
REM ICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdpbnRlcnBvbGHDp8OjbyBjb20gW10gYW5pbmhh
REM ZG8gbsOjbyBmb2kgcHJlc2VydmFkYSBjb21vIHRleHRvJykKICAgICAgICBtbD1bZSBmb3Ig
REM ZSBpbiBtYXBhIGlmIGUuZ2V0KCd0aXBvJyk9PSdtb25vbG9nb190cmlwbGFzJ10KICAgICAg
REM ICBpZiBub3QgbWw6CiAgICAgICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignbmVuaHVtIGZy
REM YWdtZW50byB0cmlwbG8gZGlzcG9uw612ZWwgcGFyYSB0ZXN0ZSBkZSByZWluamXDp8Ojbycp
REM CiAgICAgICAgdHJhZHVjb2VzX3JlID0gW10KICAgICAgICBmb3IgZSBpbiBtYXBhOgogICAg
REM ICAgICAgICBpZiBlLmdldCgndGlwbycpIGluICgnZ2V0dGV4dF9tdWx0aWxpbmhhJywgJ211
REM bHRpbGluaGFfcmVucHknLCAnbW9ub2xvZ29fdHJpcGxhcycsICdwb2VtYV9jb3JwbycpOgog
REM ICAgICAgICAgICAgICAgdHJhZHVjb2VzX3JlLmFwcGVuZChjb2RpZmljYXJfbGl0ZXJhbF90
REM cmFkdWNhbyhlLmdldCgnb3JpZ2luYWwnLCcnKSkpCiAgICAgICAgICAgIGVsc2U6CiAgICAg
REM ICAgICAgICAgICB0cmFkdWNvZXNfcmUuYXBwZW5kKGUuZ2V0KCdvcmlnaW5hbCcsJycpKQog
REM ICAgICAgIGxpbmhhc19yZSwgZXJyX3JlID0gcmVpbmpldGFyX2FycXVpdm8oY2FtaW5obywg
REM bWFwYSwgdHJhZHVjb2VzX3JlKQogICAgICAgIGlmIGVycl9yZToKICAgICAgICAgICAgcmFp
REM c2UgUnVudGltZUVycm9yKCdyZWluamXDp8OjbyBzaW50w6F0aWNhIGRvIHNlbGYtdGVzdCBm
REM YWxob3U6ICcgKyAnOyAnLmpvaW4oZXJyX3JlWzozXSkpCiAgICAgICAgam9pbmVkPScnLmpv
REM aW4obGluaGFzX3JlKQogICAgICAgIGlmICdkZWZpbmVfdGV4dCA9IF9wKCIiIicgbm90IGlu
REM IGpvaW5lZCBvciAnUHJpbWVpcmEgbGluaGEgdHJhZHV6w612ZWwuJyBub3QgaW4gam9pbmVk
REM OgogICAgICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ3JlaW5qZcOnw6NvIGRlIF9wIHRy
REM aXBsbyBhbHRlcm91IGEgZXN0cnV0dXJhJykKCiAgICAgICAgIyBSZWdyZXNzw6NvIGdsb2Jh
REM bDogc3BhbnMgc29icmVwb3N0b3MgZGV2ZW0gZ2VyYXIgYXBlbmFzIHVtYSBlbnRyYWRhLgog
REM ICAgICAgIG92ZXJsYXBfdGVzdCA9IFsKICAgICAgICAgICAgKDAsIDgsICdwb2VtYV9jb3Jw
REM bycsIDEwMCwgJycsICciQUJDREVGRyInLCBOb25lKSwKICAgICAgICAgICAgKDEsIDgsICdt
REM dWx0aWxpbmhhX3JlbnB5JywgMTAwLCAnJywgJ0FCQ0RFRkcnLCBOb25lKSwKICAgICAgICBd
REM CiAgICAgICAgcmVzb2x2aWRvcywgY29uZmxpdG9zID0gX3Jlc29sdmVyX3NvYnJlcG9zaWNv
REM ZXNfcmVnaXN0cm9zKG92ZXJsYXBfdGVzdCkKICAgICAgICBpZiBsZW4ocmVzb2x2aWRvcykg
REM IT0gMSBvciBub3QgY29uZmxpdG9zIG9yIHJlc29sdmlkb3NbMF1bMl0gIT0gJ3BvZW1hX2Nv
REM cnBvJzoKICAgICAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdyZXNvbHXDp8OjbyBnbG9i
REM YWwgZGUgc29icmVwb3Npw6fDo28gZGUgc3BhbnMgZmFsaG91JykKCiAgICAgICAgIyBSZWdy
REM ZXNzw6NvIGdsb2JhbDogY29tcGlsYWRvIHNvbWJyZWFkbyBzw7Mgw6kgcmVtb3ZpZG8gcXVh
REM bmRvIGEgZm9udGUgZXhpc3RlLgogICAgICAgIGNvbXBfZGlyID0gb3MucGF0aC5qb2luKHRk
REM LCAnY29tcGlsZWQtdGVzdCcpCiAgICAgICAgb3MubWFrZWRpcnMoY29tcF9kaXIpCiAgICAg
REM ICAgd2l0aCBpby5vcGVuKG9zLnBhdGguam9pbihjb21wX2RpciwgJ3NhbXBsZS5ycHknKSwg
REM J3cnLCBlbmNvZGluZz0ndXRmLTgnKSBhcyBmOgogICAgICAgICAgICBmLndyaXRlKCdsYWJl
REM bCBzdGFydDpcbiAgICBwYXNzXG4nKQogICAgICAgIHdpdGggaW8ub3Blbihvcy5wYXRoLmpv
REM aW4oY29tcF9kaXIsICdvcnBoYW4ucnB5YycpLCAnd2InKSBhcyBmOgogICAgICAgICAgICBm
REM LndyaXRlKGInY29tcGlsZWQnKQogICAgICAgIHdpdGggaW8ub3Blbihvcy5wYXRoLmpvaW4o
REM Y29tcF9kaXIsICdzYW1wbGUucnB5YycpLCAnd2InKSBhcyBmOgogICAgICAgICAgICBmLndy
REM aXRlKGInY29tcGlsZWQnKQogICAgICAgIHJlbW92aWRvcyA9IGxpbXBhcl9jb21waWxhZG9z
REM X3NvbWJyZWFkb3MoY29tcF9kaXIpCiAgICAgICAgaWYgJ3NhbXBsZS5ycHljJyBub3QgaW4g
REM cmVtb3ZpZG9zIG9yIG9zLnBhdGguZXhpc3RzKG9zLnBhdGguam9pbihjb21wX2RpciwgJ3Nh
REM bXBsZS5ycHljJykpOgogICAgICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ2xpbXBlemEg
REM Z2xvYmFsIGRlIC5ycHljIHNvbWJyZWFkbyBmYWxob3UnKQogICAgICAgIGlmIG9zLnBhdGgu
REM ZXhpc3RzKG9zLnBhdGguam9pbihjb21wX2RpciwgJ29ycGhhbi5ycHljJykpOgogICAgICAg
REM ICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ2xpbXBlemEgZ2xvYmFsIG7Do28gcmVtb3ZldSAu
REM cnB5YyDDs3Jmw6NvIGNvbW8gZXNwZXJhZG8nKQogICAgIyBWYWxpZGHDp8OjbyBkaXJldGEg
REM ZG8gZm9ybWF0byBkZSB0b2tlbiBkZSBbXSBhbmluaGFkby4KICAgIGVzcGVyYWRvPVttLmdy
REM b3VwKDApIGZvciBtIGluIFRPS0VOX1BST1RFQ0FPX1JFLmZpbmRpdGVyKCd4JyldCiAgICBw
REM cm90ZWdpZG8sdG9rZW5zPXByb3RlZ2VyX3Rva2Vuc19nb29nbGUoJ0EgW3BsYXllci5uYW1l
REM c1swXV0ge2l9eHsvaX0nKQogICAgdmFsaWRhcl90b2tlbnNfZ29vZ2xlX3ByZXNlcnZhZG9z
REM KHByb3RlZ2lkbyx0b2tlbnMpCiAgICBpZiByZXN0YXVyYXJfdG9rZW5zX2dvb2dsZShwcm90
REM ZWdpZG8sdG9rZW5zKSE9J0EgW3BsYXllci5uYW1lc1swXV0ge2l9eHsvaX0nOgogICAgICAg
REM IHJhaXNlIFJ1bnRpbWVFcnJvcigncmVzdGF1cmHDp8OjbyBkZSBbXSBhbmluaGFkbyBmYWxo
REM b3UnKQogICAgcHJpbnQodSdURVNURSBDT0JFUlRVUkEgU0lOVEFYRTogT0sgfCBtZW51IGFu
REM aW5oYWRvLCBfcCwgbW9uw7Nsb2dvIHRyaXBsbywgcmF3LCBiYWNrdGljayBlIFtdIGFuaW5o
REM YWRvJykKICAgIHJldHVybiAwCgoKZGVmIGV4ZWN1dGFyX3Rlc3RlX2ludGVncmlkYWRlX3Rv
REM a2VucygpOgogICAgZXNwZXJhZG8gPSBbKHUiRERBQ1owMDAwUSIsIHUie2hvdXJ9IiksICh1
REM IkREQUNaMDAwMVEiLCB1InttaW51dGV9IildCiAgICB2YWxpZGFyX3Rva2Vuc19nb29nbGVf
REM cHJlc2VydmFkb3ModSJEREFDWjAwMDBROkREQUNaMDAwMVEiLCBlc3BlcmFkbykKICAgIGNh
REM c29zX2ludmFsaWRvcyA9ICgKICAgICAgICB1IkREQUNaMDAwMVE6RERBQ1owMDAwUSIsCiAg
REM ICAgICAgdSJEREFDWjAwMDBROkREQUNaMDAwMFEiLAogICAgKQogICAgZm9yIGNhc28gaW4g
REM Y2Fzb3NfaW52YWxpZG9zOgogICAgICAgIHRyeToKICAgICAgICAgICAgdmFsaWRhcl90b2tl
REM bnNfZ29vZ2xlX3ByZXNlcnZhZG9zKGNhc28sIGVzcGVyYWRvKQogICAgICAgIGV4Y2VwdCBH
REM b29nbGVUcmFuc2xhdGVWYWxpZGF0aW9uRXJyb3IgYXMgZXhjOgogICAgICAgICAgICBpZiB1
REM Im9yZGVtL2R1cGxpY2HDp8OjbyIgbm90IGluIHN0cihleGMpOgogICAgICAgICAgICAgICAg
REM cmFpc2UKICAgICAgICBlbHNlOgogICAgICAgICAgICByYWlzZSBHb29nbGVUcmFuc2xhdGVW
REM YWxpZGF0aW9uRXJyb3IodSJ0ZXN0ZSBpbnbDoWxpZG8gZGUgb3JkZW0vZHVwbGljYcOnw6Nv
REM IG7Do28gZm9pIGRldGVjdGFkbyIpCiAgICBwcmludCh1IlRFU1RFIFRPS0VOUzogT0sgfCBz
REM ZXF1w6puY2lhLCByZW9yZGVuYcOnw6NvIGUgZHVwbGljYcOnw6NvIGRldGVjdGFkYXMiKQog
REM ICAgcmV0dXJuIDAKCgoKIyA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0KIyBWMTAzIC0gRFVB
REM TCBCUkFJTiAvIFBJUEVMSU5FIERFIDE0IEVUQVBBUwojID09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PQojIENhbWFkYSBnbG9iYWwgc29icmUgbyBuw7pjbGVvIFYxMDAuIE9zIGRvaXMgbW90
REM b3JlcyBhbmFsaXNhbSBvIG1lc21vIHNvdXJjZQojIGluZGVwZW5kZW50ZW1lbnRlOyBvIGPD
REM qXJlYnJvIGNvbnNvbGlkYSBzb21lbnRlIHNwYW5zIGV4aXN0ZW50ZXMgbm8gc291cmNlLgoj
REM IFJlZ3JhIGFic29sdXRhOiBvIHBpcGVsaW5lIG51bmNhIGludmVudGEgdGV4dG8uCgpfRFVB
REM TF9SRVBPUlRfTkFNRSA9IHUiRERBQy1EdWFsLVJlbGF0b3Jpby5qc29uIgpfRFVBTF9DT0xM
REM SVNJT05fUkVQT1JUX05BTUUgPSB1IkREQUMtQ29saXPDo28tUmVsYXTDs3Jpby5qc29uIgpf
REM RFVBTF9DT0xMSVNJT05fUkVQT1JUX0xFR0FDWV9OQU1FID0gdSJEREFDLUNvbGlzYW8tUmVs
REM YXRvcmlvLmpzb24iCl9EVUFMX0NPTExJU0lPTl9SRVBPUlRfRElSID0gTm9uZQpfRFVBTF9J
REM TlNUQUxMRVJfTkFNRSA9IHUiRERBQy1BUExJQ0FSLU1FU0NMQUdFTS5iYXQiCl9EVUFMX1NU
REM QUdFX05BTUVTID0gKAogICAgdSJFc2NhbmVhciBnYW1lIiwgdSJFeHRyYWlyIGNvbSBEREFD
REM IiwgdSJFeHRyYWlyIGNvbSBSZW4nUHkiLAogICAgdSJDb21wYXJhciBtb3RvcmVzIiwgdSJD
REM b25zb2xpZGFyIGR1cGxpY2F0YXMiLCB1IlJlc29sdmVyIHNvYnJlcG9zacOnw7VlcyIsCiAg
REM ICB1IkFuYWxpc2FyIGNvbnRleHRvIiwgdSJDbGFzc2lmaWNhciB0ZXh0byB0cmFkdXrDrXZl
REM bCIsCiAgICB1IkdlcmFyIG1hcGEgY2Fuw7RuaWNvIiwgdSJQcmVwYXJhciB0cmFkdcOnw6Nv
REM IGNhbsO0bmljYSIsCiAgICB1IlZhbGlkYXIgdG9rZW5zIiwgdSJSZWludGVncmFyIHNwYW5z
REM IGNhbsO0bmljb3MiLAogICAgdSJWYWxpZGFyIHNhw61kYSIsIHUiQXVkaXRhciBjb2xpc8O1
REM ZXMgZmluYWlzIgopCgoKX0RVQUxfTElORVNfQ0FDSEUgPSB7fQoKCmRlZiBfZHVhbF9nZXRf
REM bGluZXMocGFzdGFfZ2FtZSwgcmVsKToKICAgIGtleSA9IChvcy5wYXRoLmFic3BhdGgocGFz
REM dGFfZ2FtZSksIF9kdWFsX25vcm1fcmVsKHJlbCkpCiAgICBjYWNoZWQgPSBfRFVBTF9MSU5F
REM U19DQUNIRS5nZXQoa2V5KQogICAgaWYgY2FjaGVkIGlzIG5vdCBOb25lOgogICAgICAgIHJl
REM dHVybiBjYWNoZWQKICAgIHBhdGggPSBvcy5wYXRoLmpvaW4ocGFzdGFfZ2FtZSwgX2R1YWxf
REM bm9ybV9yZWwocmVsKS5yZXBsYWNlKCIvIiwgb3Muc2VwKSkKICAgIGxpbmVzID0gbGVyX2xp
REM bmhhc19yYXcocGF0aCkKICAgIF9EVUFMX0xJTkVTX0NBQ0hFW2tleV0gPSBsaW5lcwogICAg
REM cmV0dXJuIGxpbmVzCgoKZGVmIF9kdWFsX25vcm1fcmVsKHBhdGgpOgogICAgcmV0dXJuIG9z
REM LnBhdGgubm9ybXBhdGgocGF0aCkucmVwbGFjZShvcy5zZXAsICIvIikubHN0cmlwKCIuLyIp
REM CgoKZGVmIF9kdWFsX3NwYW5fa2V5KGMpOgogICAgcmV0dXJuIChfZHVhbF9ub3JtX3JlbChj
REM LmdldCgiYXJxdWl2byIsICIiKSksIGludChjLmdldCgibGluaGEiLCAwKSBvciAwKSwKICAg
REM ICAgICAgICAgaW50KGMuZ2V0KCJjb2x1bmFfaW5pY2lvIiwgMCkgb3IgMCksIGludChjLmdl
REM dCgiY29sdW5hX2ZpbSIsIDApIG9yIDApKQoKCmRlZiBfZHVhbF90ZXh0X2tleShjKToKICAg
REM IHJldHVybiAoX2R1YWxfbm9ybV9yZWwoYy5nZXQoImFycXVpdm8iLCAiIikpLCBpbnQoYy5n
REM ZXQoImxpbmhhIiwgMCkgb3IgMCksCiAgICAgICAgICAgIGludChjLmdldCgiY29sdW5hX2lu
REM aWNpbyIsIDApIG9yIDApLCBpbnQoYy5nZXQoImNvbHVuYV9maW0iLCAwKSBvciAwKSwKICAg
REM ICAgICAgICAgYy5nZXQoIm9yaWdpbmFsIiwgIiIpKQoKCmRlZiBfZHVhbF9wcmlvcml0eShj
REM KToKICAgIHJldHVybiB7CiAgICAgICAgInBvZW1hX3RpdHVsbyI6IDEwMTAsICJwb2VtYV9j
REM b3JwbyI6IDEwMDAsICJnZXR0ZXh0X211bHRpbGluaGEiOiA5OTAsCiAgICAgICAgIm1vbm9s
REM b2dvX3RyaXBsYXMiOiA5ODAsICJtdWx0aWxpbmhhX3JlbnB5IjogOTcwLAogICAgICAgICJk
REM aWFsb2dvIjogOTAwLCAicmVucHlfbmF0aXZvX2RpYWxvZ28iOiA5MDAsCiAgICAgICAgIm5h
REM cnJhdGl2YSI6IDg5MCwgInJlbnB5X25hdGl2b19zdHJpbmciOiA4ODAsCiAgICAgICAgInVp
REM IjogODcwLCAibWVudSI6IDg2MCwgInBvZW1hX3BhbGF2cmFfdHh0IjogODUwLAogICAgICAg
REM ICJub21lX3BlcnNvbmFnZW0iOiA3MDAsICJ2YXJpYXZlbF90ZXh0byI6IDYwMCwgInVybF92
REM aXNpdmVsIjogNTAwLAogICAgfS5nZXQoYy5nZXQoInRpcG8iKSwgMTAwKQoKCmRlZiBfZHVh
REM bF9pbnRlcnNlY3QoYSwgYik6CiAgICBpZiBfZHVhbF9ub3JtX3JlbChhLmdldCgiYXJxdWl2
REM byIsICIiKSkgIT0gX2R1YWxfbm9ybV9yZWwoYi5nZXQoImFycXVpdm8iLCAiIikpOgogICAg
REM ICAgIHJldHVybiBGYWxzZQogICAgaWYgaW50KGEuZ2V0KCJsaW5oYSIsIDApIG9yIDApICE9
REM IGludChiLmdldCgibGluaGEiLCAwKSBvciAwKToKICAgICAgICByZXR1cm4gRmFsc2UKICAg
REM IGEwLCBhMSA9IGludChhLmdldCgiY29sdW5hX2luaWNpbyIsIDApIG9yIDApLCBpbnQoYS5n
REM ZXQoImNvbHVuYV9maW0iLCAwKSBvciAwKQogICAgYjAsIGIxID0gaW50KGIuZ2V0KCJjb2x1
REM bmFfaW5pY2lvIiwgMCkgb3IgMCksIGludChiLmdldCgiY29sdW5hX2ZpbSIsIDApIG9yIDAp
REM CiAgICByZXR1cm4gbWF4KGEwLCBiMCkgPCBtaW4oYTEsIGIxKQoKCmRlZiBfZHVhbF9yZXNv
REM bHZlX2V4YWN0X2R1cGxpY2F0ZXMoY2FuZGlkYXRlcyk6CiAgICBvdXQ9W107IGJ5X3NwYW49
REM e307IGR1cD0wCiAgICBmb3IgYyBpbiBjYW5kaWRhdGVzOgogICAgICAgIGtleT1fZHVhbF9z
REM cGFuX2tleShjKQogICAgICAgIGlmIGtleSBub3QgaW4gYnlfc3BhbjoKICAgICAgICAgICAg
REM bj1kaWN0KGMpCiAgICAgICAgICAgIG5bInByb3ZlbmllbmNpYSJdPXNvcnRlZChzZXQobi5n
REM ZXQoInByb3ZlbmllbmNpYSIsIFtdKSBvciBbbi5nZXQoIm1vdG9yIiwgImRlc2NvbmhlY2lk
REM byIpXSkpCiAgICAgICAgICAgIGJ5X3NwYW5ba2V5XT1uOyBvdXQuYXBwZW5kKG4pOyBjb250
REM aW51ZQogICAgICAgIGR1cCArPSAxCiAgICAgICAgcHJldj1ieV9zcGFuW2tleV0KICAgICAg
REM ICBwcmV2WyJwcm92ZW5pZW5jaWEiXT1zb3J0ZWQoc2V0KChwcmV2LmdldCgicHJvdmVuaWVu
REM Y2lhIixbXSkgb3IgW10pICsgKGMuZ2V0KCJwcm92ZW5pZW5jaWEiLFtdKSBvciBbXSkgKyBb
REM Yy5nZXQoIm1vdG9yIiwgImRlc2NvbmhlY2lkbyIpXSkpCiAgICAgICAgaWYgbm90IHByZXYu
REM Z2V0KCJvcmlnaW5hbCIpIGFuZCBjLmdldCgib3JpZ2luYWwiKTogcHJldlsib3JpZ2luYWwi
REM XT1jWyJvcmlnaW5hbCJdCiAgICByZXR1cm4gb3V0LCB7ImVudHJhZGEiOmxlbihjYW5kaWRh
REM dGVzKSwiZHVwbGljYXRhcyI6ZHVwLCJzYWlkYSI6bGVuKG91dCl9CgoKZGVmIF9kdWFsX3Jl
REM c29sdmVfb3ZlcmxhcHMoY2FuZGlkYXRlcyk6CiAgICAiIiJTdGFnZSA2OiByZXNvbHZlIHNw
REM YW5zIHBlciBwaHlzaWNhbCBmaWxlL2xpbmUsIGF2b2lkaW5nIGdsb2JhbCBPKG7CsikuIiIi
REM CiAgICBncm91cHMgPSB7fQogICAgZm9yIGMgaW4gY2FuZGlkYXRlczoKICAgICAgICBrZXkg
REM PSAoX2R1YWxfbm9ybV9yZWwoYy5nZXQoImFycXVpdm8iLCAiIikpLCBpbnQoYy5nZXQoImxp
REM bmhhIiwgMCkgb3IgMCkpCiAgICAgICAgZ3JvdXBzLnNldGRlZmF1bHQoa2V5LCBbXSkuYXBw
REM ZW5kKGMpCiAgICBrZXB0PVtdOyBjb25mbGljdHM9W10KICAgIGZvciBrZXksIGdyb3VwIGlu
REM IGdyb3Vwcy5pdGVtcygpOgogICAgICAgIHJhbmtlZD1zb3J0ZWQoZ3JvdXAsa2V5PWxhbWJk
REM YSBjOigtaW50KF9kdWFsX3ByaW9yaXR5KGMpKSxpbnQoYy5nZXQoImNvbHVuYV9pbmljaW8i
REM LDApIG9yIDApLC1pbnQoYy5nZXQoImNvbHVuYV9maW0iLDApIG9yIDApLHN0cihjLmdldCgi
REM ZW50cnlfaWQiLCAiIikpKSkKICAgICAgICBhY2NlcHRlZD1bXQogICAgICAgIGZvciBjIGlu
REM IHJhbmtlZDoKICAgICAgICAgICAgaGl0PW5leHQoKGsgZm9yIGsgaW4gYWNjZXB0ZWQgaWYg
REM X2R1YWxfaW50ZXJzZWN0KGMsaykpLE5vbmUpCiAgICAgICAgICAgIGlmIGhpdCBpcyBOb25l
REM OgogICAgICAgICAgICAgICAgYWNjZXB0ZWQuYXBwZW5kKGMpOyBjb250aW51ZQogICAgICAg
REM ICAgICBjb25mbGljdHMuYXBwZW5kKHsiYWNhbyI6ImRlc2NhcnRvdSIsIm1hbnRpZG8iOl9k
REM dWFsX3NwYW5fa2V5KGhpdCksImRlc2NhcnRhZG8iOl9kdWFsX3NwYW5fa2V5KGMpLCJtb3Rp
REM dm8iOiJwcmlvcmlkYWRlX3NlbWFudGljYSJ9KQogICAgICAgIGtlcHQuZXh0ZW5kKGFjY2Vw
REM dGVkKQogICAgcmV0dXJuIHNvcnRlZChrZXB0LGtleT1fZHVhbF90ZXh0X2tleSksY29uZmxp
REM Y3RzCgoKZGVmIF9kdWFsX3NvdXJjZV9saXRlcmFsX2V4aXN0cyhjLCBwYXN0YV9nYW1lKToK
REM ICAgIHJlbD1fZHVhbF9ub3JtX3JlbChjLmdldCgiYXJxdWl2byIsIiIpKTsgcGF0aD1vcy5w
REM YXRoLmpvaW4ocGFzdGFfZ2FtZSxyZWwucmVwbGFjZSgiLyIsb3Muc2VwKSkKICAgIGlmIG5v
REM dCBvcy5wYXRoLmlzZmlsZShwYXRoKTogcmV0dXJuIEZhbHNlCiAgICB0cnk6CiAgICAgICAg
REM cmF3PV9kdWFsX2dldF9saW5lcyhwYXN0YV9nYW1lLHJlbCk7IGxuPWludChjLmdldCgibGlu
REM aGEiLDApIG9yIDApCiAgICAgICAgYzA9aW50KGMuZ2V0KCJjb2x1bmFfaW5pY2lvIiwwKSBv
REM ciAwKTsgYzE9aW50KGMuZ2V0KCJjb2x1bmFfZmltIiwwKSBvciAwKQogICAgICAgIHJldHVy
REM biAxIDw9IGxuIDw9IGxlbihyYXcpIGFuZCAwIDw9IGMwIDwgYzEgPD0gbGVuKHJhd1tsbi0x
REM XSkgYW5kIHJhd1tsbi0xXVtjMDpjMV0gPT0gYy5nZXQoIm9yaWdpbmFsIiwiIikKICAgIGV4
REM Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcmV0dXJuIEZhbHNlCgoKZGVmIF9kdWFsX2NvbnRl
REM eHQoYywgcGFzdGFfZ2FtZSk6CiAgICByZWw9X2R1YWxfbm9ybV9yZWwoYy5nZXQoImFycXVp
REM dm8iLCIiKSk7IHBhdGg9b3MucGF0aC5qb2luKHBhc3RhX2dhbWUscmVsLnJlcGxhY2UoIi8i
REM LG9zLnNlcCkpCiAgICB0cnk6CiAgICAgICAgbGluZXM9X2R1YWxfZ2V0X2xpbmVzKHBhc3Rh
REM X2dhbWUscmVsKTsgbG49aW50KGMuZ2V0KCJsaW5oYSIsMCkgb3IgMCkKICAgICAgICByZXR1
REM cm4geyJiZWZvcmUiOmxpbmVzW21heCgwLGxuLTQpOm1heCgwLGxuLTEpXSwibGluZSI6bGlu
REM ZXNbbG4tMV0gaWYgMTw9bG48PWxlbihsaW5lcykgZWxzZSB1IiIsImFmdGVyIjpsaW5lc1ts
REM bjptaW4obGVuKGxpbmVzKSxsbiszKV19CiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAg
REM IHJldHVybiB7ImJlZm9yZSI6W10sImxpbmUiOnUiIiwiYWZ0ZXIiOltdfQoKCmRlZiBfZHVh
REM bF9jbGFzc2lmeShjKToKICAgIHRleHRfdmFsdWU9Yy5nZXQoIm9yaWdpbmFsIiwiIikgb3Ig
REM IiI7IHRpcG89Yy5nZXQoInRpcG8iLCIiKSBvciAiIjsgY3R4PWMuZ2V0KCJjb250ZXh0byIs
REM e30pCiAgICB2aXNpYmxlX3R5cGVzPXsiZGlhbG9nbyIsIm5hcnJhdGl2YSIsInVpIiwibWVu
REM dSIsInBvZW1hX3RpdHVsbyIsInBvZW1hX2NvcnBvIiwicG9lbWFfcGFsYXZyYV90eHQiLCJn
REM ZXR0ZXh0X211bHRpbGluaGEiLCJtb25vbG9nb190cmlwbGFzIiwicmVucHlfbmF0aXZvX2Rp
REM YWxvZ28iLCJyZW5weV9uYXRpdm9fc3RyaW5nIiwidXJsX3Zpc2l2ZWwiLCJub21lX3BlcnNv
REM bmFnZW0ifQogICAgdGVjaG5pY2FsPXBhcmVjZV90ZXh0b190ZWNuaWNvKHRleHRfdmFsdWUp
REM CiAgICBleHBsaWNpdD10aXBvIGluIHZpc2libGVfdHlwZXMgb3IgYm9vbChyZS5zZWFyY2go
REM ciJcYm1lbnVccyo6fFxic2NyZWVuXHMrW0EtWmEtel9dXHcqXHMqOnxcYmxhYmVsXHMrW0Et
REM WmEtel9dXHcqXHMqOiIsIlxuIi5qb2luKGN0eC5nZXQoImJlZm9yZSIsW10pKSsiXG4iK2N0
REM eC5nZXQoImxpbmUiLHUiIikpKQogICAgaWYgdGVjaG5pY2FsIGFuZCBub3QgZXhwbGljaXQ6
REM CiAgICAgICAgY1siZGVjaXNhbyJdPSJJR05PUkFETyI7IGNbIm1vdGl2b19jbGFzc2lmaWNh
REM Y2FvIl09InBhcmVjZV9jb2RpZ29fb3VfaWRlbnRpZmljYWRvcl90ZWNuaWNvIjsgY1siY29u
REM ZmlhbmNhIl09MC45OAogICAgZWxzZToKICAgICAgICBjWyJkZWNpc2FvIl09IkFDRUlUTyI7
REM IGNbIm1vdGl2b19jbGFzc2lmaWNhY2FvIl09InRleHRvX3Zpc2l2ZWxfb3VfY2FuZGlkYXRv
REM X3NlbWFudGljbyI7IGNbImNvbmZpYW5jYSJdPTAuOTkgaWYgdGlwbyBpbiB2aXNpYmxlX3R5
REM cGVzIGVsc2UgMC44NQogICAgcmV0dXJuIGMKCgpkZWYgX2R1YWxfZW5naW5lX2NvbW1vbl9k
REM dXBsaWNhdGUocmVsLHBhc3RhX2dhbWUscmFpej1Ob25lKToKICAgICIiIkRldGVjdGEgY8Oz
REM cGlhIGV4YXRhIGRlIHJlbnB5L2NvbW1vbiBzZW0gbWlzdHVyYXIgY29tIGFycXVpdm9zIGdh
REM bWUgZGlmZXJlbnRlcy4iIiIKICAgIGlmIG5vdCByYWl6OgogICAgICAgIHJldHVybiBGYWxz
REM ZSwgTm9uZQogICAgc3JjPW9zLnBhdGguam9pbihwYXN0YV9nYW1lLCBfZHVhbF9ub3JtX3Jl
REM bChyZWwpLnJlcGxhY2UoIi8iLCBvcy5zZXApKQogICAgY29tbW9uPW9zLnBhdGguam9pbihy
REM YWl6LCAicmVucHkiLCAiY29tbW9uIiwgX2R1YWxfbm9ybV9yZWwocmVsKS5yZXBsYWNlKCIv
REM Iiwgb3Muc2VwKSkKICAgIGlmIG5vdCAob3MucGF0aC5pc2ZpbGUoc3JjKSBhbmQgb3MucGF0
REM aC5pc2ZpbGUoY29tbW9uKSk6CiAgICAgICAgcmV0dXJuIEZhbHNlLCBOb25lCiAgICB0cnk6
REM CiAgICAgICAgaDE9c2hhMjU2X2FycXVpdm8oc3JjKTsgaDI9c2hhMjU2X2FycXVpdm8oY29t
REM bW9uKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICByZXR1cm4gRmFsc2UsIE5vbmUK
REM ICAgIHJldHVybiBoMSA9PSBoMiwgaDIKCgpkZWYgX2R1YWxfY2xhc3NpZnlfYWxsKGNhbmRp
REM ZGF0ZXMscGFzdGFfZ2FtZSxyYWl6PU5vbmUpOgogICAgYWNjZXB0ZWQ9W107IHJldmlldz1b
REM XTsgaWdub3JlZD1bXQogICAgZm9yIGMgaW4gY2FuZGlkYXRlczoKICAgICAgICBuPWRpY3Qo
REM Yyk7IG5bImNvbnRleHRvIl09X2R1YWxfY29udGV4dChuLHBhc3RhX2dhbWUpCiAgICAgICAg
REM cmVsPV9kdWFsX25vcm1fcmVsKG4uZ2V0KCJhcnF1aXZvIiwiIikpCiAgICAgICAgaWYgYXJx
REM dWl2b19nbG9iYWxtZW50ZV9pZ25vcmFkb19leHRyYWNhbyhyZWwpOgogICAgICAgICAgICBu
REM WyJkZWNpc2FvIl09IklHTk9SQURPIjsgblsibW90aXZvX2NsYXNzaWZpY2FjYW8iXT0iYXJx
REM dWl2b19nbG9iYWxtZW50ZV9pZ25vcmFkb19leHRyYWNhbyI7IG5bImNsYXNzaWZpY2FjYW8i
REM XT0iR0xPQkFMX0ZJTEVfRVhDTFVTSU9OIjsgblsiY29uZmlhbmNhIl09MS4wOyBpZ25vcmVk
REM LmFwcGVuZChuKTsgY29udGludWUKICAgICAgICBpZiBlbnRyYWRhX25hb190cmFkdXppdmVs
REM X2dvb2dsZShuLmdldCgib3JpZ2luYWwiLHUiIiksIHJlbCwgbi5nZXQoInRpcG8iLHUiIikp
REM OgogICAgICAgICAgICBuWyJkZWNpc2FvIl09IklHTk9SQURPIgogICAgICAgICAgICBuWyJt
REM b3Rpdm9fY2xhc3NpZmljYWNhbyJdPSJjcmVkaXRvX291X25vbWVuY2xhdHVyYV9wcm90ZWdp
REM ZGFfbmFvX3RyYWR1eml2ZWwiCiAgICAgICAgICAgIG5bImNsYXNzaWZpY2FjYW8iXT0iTk9O
REM X1RSQU5TTEFUQUJMRV9DUkVESVQiCiAgICAgICAgICAgIG5bIm5hb190cmFkdXppciJdPVRy
REM dWUKICAgICAgICAgICAgblsiY29uZmlhbmNhIl09MS4wCiAgICAgICAgICAgIGlnbm9yZWQu
REM YXBwZW5kKG4pOyBjb250aW51ZQogICAgICAgIGlzX2NvbW1vbixjb21tb25faGFzaD1fZHVh
REM bF9lbmdpbmVfY29tbW9uX2R1cGxpY2F0ZShyZWwscGFzdGFfZ2FtZSxyYWl6KQogICAgICAg
REM IGlmIGlzX2NvbW1vbjoKICAgICAgICAgICAgblsiZGVjaXNhbyJdPSJJR05PUkFETyIKICAg
REM ICAgICAgICAgblsibW90aXZvX2NsYXNzaWZpY2FjYW8iXT0iZHVwbGljYXRhX2V4YXRhX2Rv
REM X3JlbnB5X2NvbW1vbiIKICAgICAgICAgICAgblsiY2xhc3NpZmljYWNhbyJdPSJFTkdJTkVf
REM Q09NTU9OX0RVUExJQ0FURSIKICAgICAgICAgICAgblsiZW5naW5lX2NvbW1vbl9zaGEyNTYi
REM XT1jb21tb25faGFzaAogICAgICAgICAgICBuWyJjb25maWFuY2EiXT0xLjAKICAgICAgICAg
REM ICAgaWdub3JlZC5hcHBlbmQobikKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpZiBu
REM b3QgX2R1YWxfc291cmNlX2xpdGVyYWxfZXhpc3RzKG4scGFzdGFfZ2FtZSk6CiAgICAgICAg
REM ICAgIG5bImRlY2lzYW8iXT0iUkVWSVNBTyI7IG5bIm1vdGl2b19jbGFzc2lmaWNhY2FvIl09
REM InNwYW5fbmFvX2NvbmZpcm1hZG9fbm9fc291cmNlIjsgblsiY29uZmlhbmNhIl09MC4wOyBy
REM ZXZpZXcuYXBwZW5kKG4pOyBjb250aW51ZQogICAgICAgIF9kdWFsX2NsYXNzaWZ5KG4pCiAg
REM ICAgICAgKGFjY2VwdGVkIGlmIG5bImRlY2lzYW8iXT09IkFDRUlUTyIgZWxzZSBpZ25vcmVk
REM IGlmIG5bImRlY2lzYW8iXT09IklHTk9SQURPIiBlbHNlIHJldmlldykuYXBwZW5kKG4pCiAg
REM ICByZXR1cm4gYWNjZXB0ZWQscmV2aWV3LGlnbm9yZWQKCgpkZWYgX2R1YWxfY2Fub25pY2Fs
REM aXplKGFjY2VwdGVkLHBhc3RhX2dhbWUpOgogICAgb3V0PVtdCiAgICBmb3IgYyBpbiBhY2Nl
REM cHRlZDoKICAgICAgICBuPWRpY3QoYyk7IG5bImFycXVpdm8iXT1fZHVhbF9ub3JtX3JlbChu
REM LmdldCgiYXJxdWl2byIsIiIpKTsKICAgICAgICBpZiBhcnF1aXZvX2dsb2JhbG1lbnRlX2ln
REM bm9yYWRvX2V4dHJhY2FvKG5bImFycXVpdm8iXSk6CiAgICAgICAgICAgIGNvbnRpbnVlCiAg
REM ICAgICAgcGF0aD1vcy5wYXRoLmpvaW4ocGFzdGFfZ2FtZSxuWyJhcnF1aXZvIl0ucmVwbGFj
REM ZSgiLyIsb3Muc2VwKSkKICAgICAgICB0cnk6IHJhdz1fZHVhbF9nZXRfbGluZXMocGFzdGFf
REM Z2FtZSxuWyJhcnF1aXZvIl0pOyBsbj1pbnQobi5nZXQoImxpbmhhIiwwKSBvciAwKTsgYzA9
REM aW50KG4uZ2V0KCJjb2x1bmFfaW5pY2lvIiwwKSBvciAwKTsgYzE9aW50KG4uZ2V0KCJjb2x1
REM bmFfZmltIiwwKSBvciAwKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246IGNvbnRpbnVlCiAg
REM ICAgICAgaWYgbm90ICgxPD1sbjw9bGVuKHJhdykgYW5kIDA8PWMwPGMxPD1sZW4ocmF3W2xu
REM LTFdKSk6IGNvbnRpbnVlCiAgICAgICAgaWYgcmF3W2xuLTFdW2MwOmMxXSAhPSBuLmdldCgi
REM b3JpZ2luYWwiLCIiKTogY29udGludWUKICAgICAgICBuWyJvcmlnaW5hbCJdPXJhd1tsbi0x
REM XVtjMDpjMV07IG5bIm9yaWdlbV9jYW5vbmljYSJdPSJzb3VyY2VfbGl0ZXJhbCIKICAgICAg
REM ICBuWyJ0ZXJtb3NfcHJvdGVnaWRvcyJdPVttLmdyb3VwKDApIGZvciBtIGluIF9vY29ycmVu
REM Y2lhc190ZXJtb3NfcHJvdGVnaWRvc19nb29nbGUoblsib3JpZ2luYWwiXSldCiAgICAgICAg
REM b3V0LmFwcGVuZChuKQogICAgb3V0LF89X2R1YWxfcmVzb2x2ZV9leGFjdF9kdXBsaWNhdGVz
REM KG91dCkKICAgIHJldHVybiBzb3J0ZWQob3V0LGtleT1fZHVhbF90ZXh0X2tleSkKCgpkZWYg
REM X2R1YWxfbWVyZ2VfbWFwX3dpdGhfaW50ZWdyaXR5KGNhbm9uaWNhbCxwYXN0YV9nYW1lKToK
REM ICAgIGdyb3VwZWQ9e30KICAgIGZvciBjIGluIGNhbm9uaWNhbDogZ3JvdXBlZC5zZXRkZWZh
REM dWx0KGNbImFycXVpdm8iXSxbXSkuYXBwZW5kKGMpCiAgICBvdXQ9e30KICAgIGZvciByZWws
REM aXRlbXMgaW4gZ3JvdXBlZC5pdGVtcygpOgogICAgICAgIHBhdGg9b3MucGF0aC5qb2luKHBh
REM c3RhX2dhbWUscmVsLnJlcGxhY2UoIi8iLG9zLnNlcCkpOyBvdXRbcmVsXT1fZW5yaXF1ZWNl
REM cl9tYXBhX2ludGVncmlkYWRlKGl0ZW1zLHBhdGgscmVsLGxpbmhhc19yYXc9X2R1YWxfZ2V0
REM X2xpbmVzKHBhc3RhX2dhbWUscmVsKSkKICAgIHJldHVybiBvdXQKCgpkZWYgX2R1YWxfd3Jp
REM dGVfY2Fub25pY2FsX291dHB1dHMocmFpeixwYXN0YV9nYW1lLGNhbm9uaWNhbCxtYXBhKToK
REM ICAgIHBhc3RhX3NhaWRhPW9zLnBhdGguam9pbihyYWl6LFBBU1RBX0VOVFJBREFfTk9NRSkK
REM ICAgIG9zLm1ha2VkaXJzKHBhc3RhX3NhaWRhLGV4aXN0X29rPVRydWUpCiAgICBncm91cGVk
REM PXt9CiAgICBmb3IgYyBpbiBjYW5vbmljYWw6IGdyb3VwZWQuc2V0ZGVmYXVsdChjWyJhcnF1
REM aXZvIl0sW10pLmFwcGVuZChjKQogICAgZm9yIHJlbCxpdGVtcyBpbiBncm91cGVkLml0ZW1z
REM KCk6CiAgICAgICAgZHN0PW9zLnBhdGguam9pbihwYXN0YV9zYWlkYSxyZWwucmVwbGFjZSgi
REM LyIsb3Muc2VwKSk7IG9zLm1ha2VkaXJzKG9zLnBhdGguZGlybmFtZShkc3QpLGV4aXN0X29r
REM PVRydWUpCiAgICAgICAgc3JjPW9zLnBhdGguam9pbihwYXN0YV9nYW1lLHJlbC5yZXBsYWNl
REM KCIvIixvcy5zZXApKQogICAgICAgIGlmIHJlbC5sb3dlcigpLmVuZHN3aXRoKCIudHh0Iikg
REM YW5kIGVoX2FycXVpdm9fbGlzdGFfcGFsYXZyYXNfcG9lbWEoc3JjKToKICAgICAgICAgICAg
REM ZXNjcmV2ZXJfdHh0X3BhbGF2cmFzX2V4dHJhaWRvKHNyYyxkc3QsaXRlbXMpCiAgICAgICAg
REM ZWxzZToKICAgICAgICAgICAgd2l0aCBpby5vcGVuKGRzdCwidyIsZW5jb2Rpbmc9InV0Zi04
REM IixuZXdsaW5lPSJcbiIpIGFzIGY6CiAgICAgICAgICAgICAgICBmLndyaXRlKHUiXG4iLmpv
REM aW4oW3UiIl0rW0lOREVOVEFDQU9fU0FJREErYy5nZXQoInRleHRvX3NhaWRhIixjLmdldCgi
REM b3JpZ2luYWwiLHUiIikpIGZvciBjIGluIGl0ZW1zXSkrdSJcbiIpCiAgICB3aXRoIGlvLm9w
REM ZW4ob3MucGF0aC5qb2luKHBhc3RhX3NhaWRhLE5PTUVfTUFQQSksInciLGVuY29kaW5nPSJ1
REM dGYtOCIpIGFzIGY6IGpzb24uZHVtcChtYXBhLGYsZW5zdXJlX2FzY2lpPUZhbHNlLGluZGVu
REM dD0xKQogICAgcmV0dXJuIHBhc3RhX3NhaWRhCgoKZGVmIF9kdWFsX3Jlc2V0X291dHB1dF9k
REM aXIocmFpeiwgbG9nKToKICAgIHBhdGg9b3MucGF0aC5qb2luKHJhaXosUEFTVEFfRU5UUkFE
REM QV9OT01FKQogICAgaWYgbm90IG9zLnBhdGguaXNkaXIocGF0aCk6IHJldHVybgogICAgYmFj
REM a3VwPW9zLnBhdGguam9pbihyYWl6LHUie30tQmFja3VwLXt9Ii5mb3JtYXQoUEFTVEFfRU5U
REM UkFEQV9OT01FLHRpbWUuc3RyZnRpbWUoIiVZJW0lZC0lSCVNJVMiKSkpCiAgICBpZiBvcy5w
REM YXRoLmV4aXN0cyhiYWNrdXApOiBiYWNrdXAgKz0gdSIte30iLmZvcm1hdChvcy5nZXRwaWQo
REM KSkKICAgIG9zLnJlbmFtZShwYXRoLGJhY2t1cCk7IGxvZy5pbmZvKHUiRVRBUEEgMS8xNDog
REM c2HDrWRhIGFudGVyaW9yIHByZXNlcnZhZGEgZW0ge30iLmZvcm1hdChvcy5wYXRoLmJhc2Vu
REM YW1lKGJhY2t1cCkpKQoKCmRlZiBfZHVhbF9zdGFnZTJfZGRhYyhwYXN0YV9nYW1lLGNhbmRp
REM ZGF0b3MsbG9nKToKICAgIGluZGljZT1jb25zdHJ1aXJfaW5kaWNlX2FycXVpdm9zKHBhc3Rh
REM X2dhbWUpOyB2YXJzX2R5bj1jb2xldGFyX3ZhcmlhdmVpc19ub21lX2RpbmFtaWNvKGNhbmRp
REM ZGF0b3MpOyB2b2NhYj1jb2xldGFyX3ZvY2FidWxhcmlvKHBhc3RhX2dhbWUsY2FuZGlkYXRv
REM cyk7IGRkYWM9W10KICAgIHRvdGFsPW1heCgxLGxlbihjYW5kaWRhdG9zKSk7IHVsdGltb19t
REM YXJjYWRvcj0tMQogICAgcHJpbnQodSIgIFByb2dyZXNzbyBEREFDOiAwLjAlIHwgWz4gICAg
REM ICAgICAgICAgICAgICAgICAgICAgXSIsIGZsdXNoPVRydWUpCiAgICBmb3IgbnVtZXJvX2Nh
REM bWluaG8sY2FtaW5obyBpbiBlbnVtZXJhdGUoY2FuZGlkYXRvcywxKToKICAgICAgICByZWw9
REM X2R1YWxfbm9ybV9yZWwob3MucGF0aC5yZWxwYXRoKGNhbWluaG8scGFzdGFfZ2FtZSkpCiAg
REM ICAgICAgaWYgY2FtaW5oby5sb3dlcigpLmVuZHN3aXRoKCIudHh0Iik6CiAgICAgICAgICAg
REM IGlmIGVoX2FycXVpdm9fbGlzdGFfcGFsYXZyYXNfcG9lbWEoY2FtaW5obyk6CiAgICAgICAg
REM ICAgICAgICBmb3IgZSBpbiBleHRyYWlyX3R4dF9saXN0YV9wYWxhdnJhc19wb2VtYShjYW1p
REM bmhvKSBvciBbXToKICAgICAgICAgICAgICAgICAgICBuPWRpY3QoZSk7IG4udXBkYXRlKHsi
REM YXJxdWl2byI6cmVsLCJtb3RvciI6IkREQUMiLCJwcm92ZW5pZW5jaWEiOlsiRERBQyJdfSk7
REM IGRkYWMuYXBwZW5kKG4pCiAgICAgICAgICAgIGNvbnRpbnVlCiAgICAgICAgdHJ5OgogICAg
REM ICAgICAgICB0ZXh0b3MsbWFwYT1leHRyYWlyX2FycXVpdm9fY29tX21hcGEoY2FtaW5obyx2
REM YXJzX2R5bixpbmRpY2Usdm9jYWIse30pCiAgICAgICAgICAgIGZvciBwYWlyLGVudHJ5IGlu
REM IHppcCh0ZXh0b3MsbWFwYSk6CiAgICAgICAgICAgICAgICB0ZXh0X3ZhbHVlID0gcGFpclsx
REM XSBpZiBpc2luc3RhbmNlKHBhaXIsKHR1cGxlLGxpc3QpKSBhbmQgbGVuKHBhaXIpID49IDIg
REM ZWxzZSBlbnRyeS5nZXQoIm9yaWdpbmFsIiwiIikKICAgICAgICAgICAgICAgIG49ZGljdChl
REM bnRyeSk7IG4udXBkYXRlKHsiYXJxdWl2byI6cmVsLCJtb3RvciI6IkREQUMiLCJwcm92ZW5p
REM ZW5jaWEiOlsiRERBQyJdLCJ0ZXh0b19kZXRlY3RhZG8iOnRleHRfdmFsdWUsInRleHRvX3Nh
REM aWRhIjp0ZXh0X3ZhbHVlfSk7IGRkYWMuYXBwZW5kKG4pCiAgICAgICAgZXhjZXB0IEV4Y2Vw
REM dGlvbiBhcyBleGM6IGxvZy5hdmlzbyh1Ik1vdG9yIEREQUMgZmFsaG91IGVtIHt9OiB7fSIu
REM Zm9ybWF0KHJlbCxleGMpKQogICAgICAgIG1hcmNhZG9yID0gaW50KCgxMDAuMCAqIG51bWVy
REM b19jYW1pbmhvKSAvIHRvdGFsKQogICAgICAgIHBhc3NvID0gbWF4KDEsIGludCgxMDAuMCAv
REM IDIwLjApKQogICAgICAgIGlmIG1hcmNhZG9yICE9IHVsdGltb19tYXJjYWRvciBhbmQgKG1h
REM cmNhZG9yICUgcGFzc28gPT0gMCBvciBudW1lcm9fY2FtaW5obyA9PSB0b3RhbCk6CiAgICAg
REM ICAgICAgIHVsdGltb19tYXJjYWRvciA9IG1hcmNhZG9yCiAgICAgICAgICAgIGxhcmd1cmEg
REM PSAyOAogICAgICAgICAgICBwcmVlbmNoaWRvID0gaW50KHJvdW5kKGxhcmd1cmEgKiAoZmxv
REM YXQobnVtZXJvX2NhbWluaG8pIC8gdG90YWwpKSkKICAgICAgICAgICAgcHJlZW5jaGlkbyA9
REM IG1heCgwLCBtaW4obGFyZ3VyYSwgcHJlZW5jaGlkbykpCiAgICAgICAgICAgIGNvcnBvID0g
REM dSI9IiAqIHByZWVuY2hpZG8gKyAodSI+IiBpZiBwcmVlbmNoaWRvIDwgbGFyZ3VyYSBlbHNl
REM IHUiIikKICAgICAgICAgICAgY29ycG8gKz0gdSIgIiAqIG1heCgwLCBsYXJndXJhIC0gbGVu
REM KGNvcnBvKSkKICAgICAgICAgICAgcHJpbnQodSJcciAgUHJvZ3Jlc3NvIEREQUM6IHs6NS4x
REM Zn0lIHwgezo+NH0vezo8NH0gW3t9XSIuZm9ybWF0KAogICAgICAgICAgICAgICAgMTAwLjAg
REM KiBudW1lcm9fY2FtaW5obyAvIHRvdGFsLCBudW1lcm9fY2FtaW5obywgdG90YWwsIGNvcnBv
REM CiAgICAgICAgICAgICksIGVuZD11IiIsIGZsdXNoPVRydWUpCiAgICBwcmludCh1IiIpCiAg
REM ICByZXR1cm4gZGRhYyx2YXJzX2R5bgoKCmRlZiBfZHVhbF9zdGFnZTNfcmVucHkocGFzdGFf
REM Z2FtZSxjYW5kaWRhdG9zLGxvZyk6CiAgICBvcmFjbGU9X3ByZXBhcmFyX29yYWN1bG9fcmVu
REM cHkocGFzdGFfZ2FtZSxjYW5kaWRhdG9zLGxvZyk7IG91dD1bXQogICAgaWYgbm90IE9SQUNV
REM TE9fUkVOUFkuZ2V0KCJhdGl2byIpOiByZXR1cm4gb3V0CiAgICBmb3IgcmVsLGJ5X2xpbmUg
REM aW4gKG9yYWNsZSBvciB7fSkuaXRlbXMoKToKICAgICAgICBpZiBpc2luc3RhbmNlKGJ5X2xp
REM bmUsZGljdCk6CiAgICAgICAgICAgIGl0ZXJfaXRlbXM9W10KICAgICAgICAgICAgZm9yIF9s
REM bixpdGVtcyBpbiBieV9saW5lLml0ZW1zKCk6CiAgICAgICAgICAgICAgICBpZiBpc2luc3Rh
REM bmNlKGl0ZW1zLChsaXN0LHR1cGxlKSk6IGl0ZXJfaXRlbXMuZXh0ZW5kKGl0ZW1zKQogICAg
REM ICAgICAgICAgICAgZWxpZiBpc2luc3RhbmNlKGl0ZW1zLGRpY3QpOiBpdGVyX2l0ZW1zLmFw
REM cGVuZChpdGVtcykKICAgICAgICBlbGlmIGlzaW5zdGFuY2UoYnlfbGluZSwobGlzdCx0dXBs
REM ZSkpOgogICAgICAgICAgICBpdGVyX2l0ZW1zPWJ5X2xpbmUKICAgICAgICBlbHNlOgogICAg
REM ICAgICAgICBpdGVyX2l0ZW1zPVtdCiAgICAgICAgZm9yIGl0ZW0gaW4gaXRlcl9pdGVtczoK
REM ICAgICAgICAgICAgbj1kaWN0KGl0ZW0pOyByPV9kdWFsX25vcm1fcmVsKG4uZ2V0KCJhcnF1
REM aXZvIixyZWwpKTsgcj1yWzU6XSBpZiByLnN0YXJ0c3dpdGgoImdhbWUvIikgZWxzZSByOyBu
REM WyJhcnF1aXZvIl09cjsgblsibW90b3IiXT0iUmVuUHkiOyBuWyJwcm92ZW5pZW5jaWEiXT1b
REM IlJlblB5Il07IG4uc2V0ZGVmYXVsdCgidGlwbyIsInJlbnB5X25hdGl2b19zdHJpbmciKQog
REM ICAgICAgICAgICBpZiBhcnF1aXZvX2dsb2JhbG1lbnRlX2lnbm9yYWRvX2V4dHJhY2FvKHIp
REM OgogICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
REM ICAgICAgbGluZXM9X2R1YWxfZ2V0X2xpbmVzKHBhc3RhX2dhbWUscik7IGxuPWludChuLmdl
REM dCgibGluaGEiLDApIG9yIDApOyBsaW5lPWxpbmVzW2xuLTFdLnJzdHJpcCgiXHJcbiIpCiAg
REM ICAgICAgICAgICAgICBtYXRjaGVzPV9jYW5kaWRhdG9zX3N0cmluZ19saW5oYShsaW5lLG4u
REM Z2V0KCJ0ZXh0byIsdSIiKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAg
REM ICAgICAgICAgIG1hdGNoZXM9W10KICAgICAgICAgICAgaWYgbGVuKG1hdGNoZXMpPT0xOgog
REM ICAgICAgICAgICAgICAgYzAsYzEscT1tYXRjaGVzWzBdOyBuWyJjb2x1bmFfaW5pY2lvIl09
REM YzA7IG5bImNvbHVuYV9maW0iXT1jMTsgblsib3JpZ2luYWwiXT1xOyBuWyJ0ZXh0b19zYWlk
REM YSJdPXEKICAgICAgICAgICAgICAgIGlmIG4uZ2V0KCJwZXJzb25hZ2VtIikgYW5kIFBVUkVf
REM VklTSUJMRV9VUkxfUkUubWF0Y2goc3RyaXBfcXVvdGVzKHEpLnN0cmlwKCkpOiBuWyJ0aXBv
REM Il09InVybF92aXNpdmVsIgogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgblsi
REM Y29sdW5hX2luaWNpbyJdPTA7IG5bImNvbHVuYV9maW0iXT0wOyBuWyJvcmlnaW5hbCJdPXUi
REM IjsgblsidGV4dG9fc2FpZGEiXT11IiI7IG5bInJlbnB5X21hdGNoX2FtYmlndW8iXT1sZW4o
REM bWF0Y2hlcykKICAgICAgICAgICAgb3V0LmFwcGVuZChuKQogICAgcmV0dXJuIG91dAoKZGVm
REM IF9kdWFsX3N0YWdlNF9jb21wYXJlKGRkYWMscmVucHkpOgogICAgYT17X2R1YWxfdGV4dF9r
REM ZXkoYykgZm9yIGMgaW4gZGRhY307IGI9e19kdWFsX3RleHRfa2V5KGMpIGZvciBjIGluIHJl
REM bnB5fQogICAgcmV0dXJuIHsiZGRhYyI6bGVuKGEpLCJyZW5weSI6bGVuKGIpLCJjb25jb3Jk
REM YW5jaWFzX2V4YXRhcyI6bGVuKGEmYiksInNvbWVudGVfZGRhYyI6bGVuKGEtYiksInNvbWVu
REM dGVfcmVucHkiOmxlbihiLWEpfQoKCl9EVUFMX1JFUE9SVF9ESVIgPSBOb25lCgpkZWYgX2R1
REM YWxfcmVwb3J0X3BhdGgocmFpeik6CiAgICAiIiJSZWxhdMOzcmlvIHBlcnNpc3RlbnRlIGFv
REM IGxhZG8gZG8gQkFUOyBuw6NvIMOpIGFwYWdhZG8gYXDDs3Mgc3VjZXNzby4iIiIKICAgIHJl
REM dHVybiBvcy5wYXRoLmpvaW4ob3MucGF0aC5hYnNwYXRoKHJhaXopLCBfRFVBTF9SRVBPUlRf
REM TkFNRSkKCgpkZWYgX2R1YWxfcmVwb3J0X2l0ZW5zX2NvbXBhY3RvcyhpdGVucyk6CiAgICAi
REM IiJDYW1wb3Mgw7p0ZWlzIHBhcmEgcmV2aXNhciB0ZXh0bzsgZXZpdGEgc2VyaWFsaXphciBj
REM b250ZXh0by9jw7NkaWdvIGludGVpcm8uIiIiCiAgICBzYWlkYSA9IFtdCiAgICBmb3IgaXRl
REM bSBpbiBpdGVucyBvciBbXToKICAgICAgICBsaXRlcmFsID0gaXRlbS5nZXQoIm9yaWdpbmFs
REM IiwgdSIiKQogICAgICAgIHRyeToKICAgICAgICAgICAgdGV4dG9fdmlzaXZlbCA9IGRlY29k
REM aWZpY2FyX2xpdGVyYWxfdHJhZHVjYW8obGl0ZXJhbCkKICAgICAgICBleGNlcHQgRXhjZXB0
REM aW9uOgogICAgICAgICAgICB0ZXh0b192aXNpdmVsID0gc3RyaXBfcXVvdGVzKGxpdGVyYWwp
REM CiAgICAgICAgc2FpZGEuYXBwZW5kKHsKICAgICAgICAgICAgImFycXVpdm8iOiBpdGVtLmdl
REM dCgiYXJxdWl2byIsIHUiIiksCiAgICAgICAgICAgICJsaW5oYSI6IGl0ZW0uZ2V0KCJsaW5o
REM YSIsIDApLAogICAgICAgICAgICAidGlwbyI6IGl0ZW0uZ2V0KCJ0aXBvIiwgdSIiKSwKICAg
REM ICAgICAgICAgInRleHRvIjogdGV4dG9fdmlzaXZlbCwKICAgICAgICAgICAgImxpdGVyYWxf
REM Zm9udGUiOiBsaXRlcmFsLAogICAgICAgICAgICAiZGVjaXNhbyI6IGl0ZW0uZ2V0KCJkZWNp
REM c2FvIiwgdSIiKSwKICAgICAgICAgICAgImNsYXNzaWZpY2FjYW8iOiBpdGVtLmdldCgiY2xh
REM c3NpZmljYWNhbyIsIHUiIiksCiAgICAgICAgICAgICJtb3Rpdm8iOiBpdGVtLmdldCgibW90
REM aXZvX2NsYXNzaWZpY2FjYW8iLCB1IiIpLAogICAgICAgICAgICAiY29uZmlhbmNhIjogaXRl
REM bS5nZXQoImNvbmZpYW5jYSIsIE5vbmUpLAogICAgICAgICAgICAibW90b3IiOiBpdGVtLmdl
REM dCgibW90b3IiLCB1IkREQUMiKSwKICAgICAgICAgICAgInByb3ZlbmllbmNpYSI6IGl0ZW0u
REM Z2V0KCJwcm92ZW5pZW5jaWEiLCBbdSJEREFDIl0pLAogICAgICAgIH0pCiAgICByZXR1cm4g
REM c2FpZGEKCmRlZiBfZHVhbF9yZXBvcnRfb3JhY2xlX2NvbXBhY3RvKCk6CiAgICBvID0gZGlj
REM dChPUkFDVUxPX1JFTlBZKQogICAgIyBPIHJlbGF0w7NyaW8gZGUgZXN0YWRvIG7Do28gcHJl
REM Y2lzYSBjYXJyZWdhciBhcyAyNWsrIGVudHJhZGFzIG5hdGl2YXMgbmVtCiAgICAjIGEgdGFi
REM ZWxhIHBvciBhcnF1aXZvLiBFc3NhcyBlc3RydXR1cmFzIGNvbnRpbnVhbSBkaXNwb27DrXZl
REM aXMgZW0gbWVtw7NyaWEKICAgICMgZHVyYW50ZSBvIHBpcGVsaW5lOyBvIG1hcGEgY2Fuw7Ru
REM aWNvIMOpIHF1ZSBwcmVzZXJ2YSBvcyBkYWRvcyBkZSBwcm9kdcOnw6NvLgogICAgZm9yIGNo
REM YXZlIGluICgiZW50cmFkYXMiLCAicG9yX2FycXVpdm8iKToKICAgICAgICBvLnBvcChjaGF2
REM ZSwgTm9uZSkKICAgIG9bImVudHJhZGFzX25hdGl2YXNfc2VyaWFsaXphZGFzIl0gPSBGYWxz
REM ZQogICAgb1sicG9yX2FycXVpdm9fc2VyaWFsaXphZG8iXSA9IEZhbHNlCiAgICByZXR1cm4g
REM bwoKZGVmIF9kdWFsX3dyaXRlX3JlcG9ydChyYWl6LHJlcG9ydCk6CiAgICBjYW1pbmhvPV9k
REM dWFsX3JlcG9ydF9wYXRoKHJhaXopCiAgICByZXBvcnRbInJlbGF0b3Jpb19kaWFnbm9zdGlj
REM byJdID0gY2FtaW5obwogICAgd2l0aCBpby5vcGVuKGNhbWluaG8sInciLGVuY29kaW5nPSJ1
REM dGYtOCIpIGFzIGY6IGpzb24uZHVtcChyZXBvcnQsZixlbnN1cmVfYXNjaWk9RmFsc2UsaW5k
REM ZW50PTIpCiAgICByZXR1cm4gY2FtaW5obwoKZGVmIF9kdWFsX2NsZWFudXBfc3VjY2Vzc190
REM ZW1wX3JlcG9ydCgpOgogICAgZ2xvYmFsIF9EVUFMX1JFUE9SVF9ESVIKICAgIGlmIF9EVUFM
REM X1JFUE9SVF9ESVIgYW5kIG9zLnBhdGguaXNkaXIoX0RVQUxfUkVQT1JUX0RJUik6CiAgICAg
REM ICAgdHJ5OiBzaHV0aWwucm10cmVlKF9EVUFMX1JFUE9SVF9ESVIsIGlnbm9yZV9lcnJvcnM9
REM VHJ1ZSkKICAgICAgICBleGNlcHQgRXhjZXB0aW9uOiBwYXNzCiAgICBfRFVBTF9SRVBPUlRf
REM RElSID0gTm9uZQoKCmRlZiBleGVjdXRhcl9waXBlbGluZV9kdWFsX3YxMTIocmFpeik6CiAg
REM ICBnbG9iYWwgSUdOT1JBRE9TX0VYVFJBQ0FPX0FVVE9NQVRJQ0EsIF9EVUFMX0xJTkVTX0NB
REM Q0hFCiAgICBJR05PUkFET1NfRVhUUkFDQU9fQVVUT01BVElDQT1bXTsgX0RVQUxfTElORVNf
REM Q0FDSEU9e307IGluaWNpbz10aW1lLnRpbWUoKTsgbG9nPUxvZyhvcy5wYXRoLmpvaW4ocmFp
REM eixOT01FX0xPR19FWFRSQVRPUikpOyBzdGF0dXM9e3N0cihpKToiUEVOREVOVEUiIGZvciBp
REM IGluIHJhbmdlKDEsMTUpfQogICAgcmVwb3J0PXsidmVyc2FvIjoiVjE0NS1PcHRpb25hbE9y
REM YWNsZSIsInJ1bl9pZCI6Int9LXt9Ii5mb3JtYXQodGltZS5zdHJmdGltZSgiJVklbSVkLSVI
REM JU0lUyIpLG9zLmdldHBpZCgpKSwiZXRhcGFzIjpfRFVBTF9TVEFHRV9OQU1FUywic3RhZ2Vf
REM c3RhdHVzIjpzdGF0dXMsIm9yYWN1bG9fcmVucHlfcmVxdWlyZWQiOkZhbHNlLCJ2YWxpZGFj
REM YW9fcmVucHkiOiJQRU5ERU5URSIsInRlcm1pbmFsX3N0YXR1cyI6IkVNX0VYRUNVQ0FPIiwi
REM YXJxdWl0ZXR1cmEiOiJEREFDIGluZGVwZW5kZW50ZSArIG9yw6FjdWxvIFJlblB5IG9wY2lv
REM bmFsICsgY8OpcmVicm8gc2Vtw6JudGljbyBkZXRlcm1pbsOtc3RpY28ifQogICAgdHJ5Ogog
REM ICAgICAgIF9zdGFsZT1vcy5wYXRoLmpvaW4ocmFpeixfRFVBTF9SRVBPUlRfTkFNRSkKICAg
REM ICAgICBpZiBvcy5wYXRoLmlzZmlsZShfc3RhbGUpOiBvcy5yZW1vdmUoX3N0YWxlKQogICAg
REM ZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBsb2cuc2VwYXJhZG9yKCk7IGxv
REM Zy50aXR1bG8oZHQoInRpdHVsbyIpKTsgbG9nLnRpdHVsbyh0KCJsb2dfZGF0YWhvcmEiKS5m
REM b3JtYXQodGltZS5zdHJmdGltZSgiJWQvJW0vJVkgJUg6JU06JVMiKSkpOyBsb2cuc2VwYXJh
REM ZG9yKCk7IGxvZy5pbmZvKGR0KCJub3ZhX2V4ZWN1Y2FvIikpOyBfZHVhbF93cml0ZV9yZXBv
REM cnQocmFpeixyZXBvcnQpOyBsb2cuc2FsdmFyKCkKICAgIHRyeToKICAgICAgICBwYXN0YV9n
REM YW1lPWVuY29udHJhcl9wYXN0YV9nYW1lKHJhaXopCiAgICAgICAgaWYgbm90IHBhc3RhX2dh
REM bWU6CiAgICAgICAgICAgIHN0YXR1c1siMSJdPSJGQUxIQSI7IHJlcG9ydC51cGRhdGUoeyJ0
REM ZXJtaW5hbF9zdGF0dXMiOiJGQUxIQSIsImVycm8iOiJQYXN0YSBnYW1lIG7Do28gZW5jb250
REM cmFkYS4ifSk7IGxvZy5lcnJvKGR0KCJnYW1lX21pc3NpbmciKSk7IF9kdWFsX3dyaXRlX3Jl
REM cG9ydChyYWl6LHJlcG9ydCk7IGxvZy5zYWx2YXIoKTsgcmV0dXJuIDEKICAgICAgICBwcmlu
REM dChkdCgic3RhZ2UxX3N0YXJ0IiksIGZsdXNoPVRydWUpCiAgICAgICAgY2FuZGlkYXRvcz1j
REM b2xldGFyX2NhbmRpZGF0b3NfZXh0cmFjYW8ocGFzdGFfZ2FtZSkKICAgICAgICBpZiBub3Qg
REM Y2FuZGlkYXRvczoKICAgICAgICAgICAgc3RhdHVzWyIxIl09IkZBTEhBIgogICAgICAgICAg
REM ICB0cnk6CiAgICAgICAgICAgICAgICBjb250YWdlbSxfdHJpcGxlcyxfdGw9X3ByZWZsaWdo
REM dF9jb250YXJfZm9udGVzKHBhc3RhX2dhbWUpCiAgICAgICAgICAgICAgICBjb21waWxhZG9z
REM PWNvbnRhZ2VtLmdldCgiLnJwYSIsMCkrY29udGFnZW0uZ2V0KCIucnB5YyIsMCkrY29udGFn
REM ZW0uZ2V0KCIucnB5bWMiLDApCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAg
REM ICAgICAgICAgICBjb21waWxhZG9zPTAKICAgICAgICAgICAgaWYgY29tcGlsYWRvczoKICAg
REM ICAgICAgICAgICAgIG1vdGl2bz11Ik5lbmh1bSBzY3JpcHQtZm9udGUgdXRpbGl6w6F2ZWwg
REM Zm9pIGVuY29udHJhZG8uIE8gcHJvamV0byBjb250w6ltIGFycXVpdm9zIGVtcGFjb3RhZG9z
REM L2NvbXBpbGFkb3MsIG1hcyBlc3RhIGV0YXBhIG7Do28gZXh0cmFpIFJQQSBuZW0gZGVzY29t
REM cGlsYSBSUFlDLiBFeHRyYWlhIG9zIFJQQSBlIGRlc2NvbXBpbGUgb3MgUlBZQyBhbnRlcyBk
REM ZSBleGVjdXRhciBhIE9ww6fDo28gMS4iCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
REM ICAgICBtb3Rpdm89dSJOZW5odW0gYXJxdWl2by1mb250ZSBjb21wYXTDrXZlbCAoLnJweSwg
REM LnJweW0sICpfcmVuLnB5IG91IHRleHRvIHN1cG9ydGFkbykgZm9pIGVuY29udHJhZG8gZGVu
REM dHJvIGRhIHBhc3RhIGdhbWUuIEEgZXh0cmHDp8OjbyBmb2kgaW50ZXJyb21waWRhIHNlbSBz
REM dWJzdGl0dWlyIHJlc3VsdGFkb3MgYW50ZXJpb3Jlcy4iCiAgICAgICAgICAgIHJlcG9ydC51
REM cGRhdGUoeyJ0ZXJtaW5hbF9zdGF0dXMiOiJTRU1fRk9OVEVTX0RFX1NDUklQVCIsImFycXVp
REM dm9zX3NjYW4iOjAsImNhbmRpZGF0b3NfZGRhYyI6MCwiY2FuZGlkYXRvc19yZW5weSI6MCwi
REM dmFsaWRhY2FvX3JlbnB5IjoiTkFPX0FQTElDQVZFTCIsImVycm8iOm1vdGl2bywic3RhZ2Vf
REM c3RhdHVzIjpzdGF0dXN9KQogICAgICAgICAgICBsb2cuZXJybyhtb3Rpdm8pOyBfZHVhbF93
REM cml0ZV9yZXBvcnQocmFpeixyZXBvcnQpOyBsb2cucmVzdWx0YWRvKGR0KCJsYWJlbF9zdGF0
REM dXMiKSx1IkZBTEhBOiBzZW0gZm9udGVzIHBhcmEgZXh0cmHDp8OjbyIpOyBsb2cucmVzdWx0
REM YWRvKHUiUmVsYXTDs3JpbyIsb3MucGF0aC5qb2luKG9zLnBhdGguYWJzcGF0aChyYWl6KSxf
REM RFVBTF9SRVBPUlRfTkFNRSkpOyBsb2cuc2FsdmFyKCkKICAgICAgICAgICAgcHJpbnQodSJb
REM RVJST10gIiArIG1vdGl2bywgZmx1c2g9VHJ1ZSkKICAgICAgICAgICAgcmV0dXJuIDEKICAg
REM ICAgICAjIE7Do28gYXJxdWl2YS9zdWJzdGl0dWkgdW1hIGV4dHJhw6fDo28gYW50ZXJpb3Ig
REM YXTDqSBjb25maXJtYXIgZm9udGVzIHbDoWxpZGFzLgogICAgICAgIF9kdWFsX3Jlc2V0X291
REM dHB1dF9kaXIocmFpeixsb2cpCiAgICAgICAgc3RhdHVzWyIxIl09Ik9LIjsgcHJpbnQoZHQo
REM InN0YWdlMV9kb25lIiwgbGVuKGNhbmRpZGF0b3MpKSwgZmx1c2g9VHJ1ZSk7IGxvZy5pbmZv
REM KGR0KCJzdGFnZTFfZG9uZSIsIGxlbihjYW5kaWRhdG9zKSkpCiAgICAgICAgcHJpbnQoZHQo
REM InN0YWdlMl9zdGFydCIpLCBmbHVzaD1UcnVlKQogICAgICAgIGRkYWMsdmFyc19keW49X2R1
REM YWxfc3RhZ2UyX2RkYWMocGFzdGFfZ2FtZSxjYW5kaWRhdG9zLGxvZyk7IHN0YXR1c1siMiJd
REM PSJPSyI7IHByaW50KGR0KCJzdGFnZTJfZG9uZSIsIGxlbihkZGFjKSksIGZsdXNoPVRydWUp
REM OyBsb2cuaW5mbyhkdCgic3RhZ2UyX2RvbmUiLCBsZW4oZGRhYykpKQogICAgICAgIHByaW50
REM KGR0KCJzdGFnZTNfc3RhcnQiKSwgZmx1c2g9VHJ1ZSkKICAgICAgICByZW5weT1fZHVhbF9z
REM dGFnZTNfcmVucHkocGFzdGFfZ2FtZSxjYW5kaWRhdG9zLGxvZykKICAgICAgICBhY3RpdmU9
REM Ym9vbChPUkFDVUxPX1JFTlBZLmdldCgiYXRpdm8iKSkKICAgICAgICBzdGF0dXNfb3JhY3Vs
REM byA9IHsxOnUiU0VNIFZBTElEQcOHw4NPIiwgMjp1Ik5PVCBWQUxJREFURUQiLCAzOnUiU0lO
REM IFZBTElEQUNJw5NOIn0uZ2V0KElESU9NQSwgdSJTRU0gVkFMSURBw4fDg08iKQogICAgICAg
REM IHN0YXR1c1siMyJdID0gIk9LIiBpZiBhY3RpdmUgZWxzZSAiU0VNIFZBTElEQUNBTyIKICAg
REM ICAgICBzdGF0dXNfZXRhcGEgPSBkdCgic3RhdHVzX29rIikgaWYgYWN0aXZlIGVsc2Ugc3Rh
REM dHVzX29yYWN1bG8KICAgICAgICBwcmludChkdCgic3RhZ2UzX2RvbmUiLCBsZW4ocmVucHkp
REM LCBkdCgib3JhY2xlX3llcyIpIGlmIGFjdGl2ZSBlbHNlIGR0KCJvcmFjbGVfbm8iKSwgc3Rh
REM dHVzX2V0YXBhKSwgZmx1c2g9VHJ1ZSkKICAgICAgICBsb2cuaW5mbyhkdCgic3RhZ2UzX2Rv
REM bmUiLCBsZW4ocmVucHkpLCBkdCgib3JhY2xlX3llcyIpIGlmIGFjdGl2ZSBlbHNlIGR0KCJv
REM cmFjbGVfbm8iKSwgc3RhdHVzX2V0YXBhKSkKICAgICAgICBpZiBub3QgYWN0aXZlOgogICAg
REM ICAgICAgICBhdmlzb19mYWxsYmFjayA9IHsKICAgICAgICAgICAgICAgIDE6dSJPIG9yw6Fj
REM dWxvIFJlbidQeSBuw6NvIGZpY291IGRpc3BvbsOtdmVsLiBBIGV4dHJhw6fDo28gY29udGlu
REM dWEgYXBlbmFzIGNvbSBvIG1vdG9yIEREQUM7IG8gcmVzdWx0YWRvIGRldmUgc2VyIHJldmlz
REM YWRvIGUgZXN0w6EgbWFyY2FkbyBjb21vIHNlbSB2YWxpZGHDp8Ojby4iLAogICAgICAgICAg
REM ICAgICAgMjp1IlRoZSBSZW4nUHkgT3JhY2xlIHdhcyB1bmF2YWlsYWJsZS4gRXh0cmFjdGlv
REM biBjb250aW51ZXMgd2l0aCB0aGUgRERBQyBlbmdpbmUgb25seTsgcmV2aWV3IHRoZSByZXN1
REM bHQgYmVjYXVzZSBpdCBpcyBtYXJrZWQgYXMgbm90IHZhbGlkYXRlZC4iLAogICAgICAgICAg
REM ICAgICAgMzp1IkVsIG9yw6FjdWxvIFJlbidQeSBubyBlc3R1dm8gZGlzcG9uaWJsZS4gTGEg
REM ZXh0cmFjY2nDs24gY29udGluw7phIHNvbG8gY29uIGVsIG1vdG9yIEREQUM7IHJldmlzZSBl
REM bCByZXN1bHRhZG8gcG9ycXVlIGVzdMOhIG1hcmNhZG8gc2luIHZhbGlkYWNpw7NuLiIsCiAg
REM ICAgICAgICAgIH0uZ2V0KElESU9NQSwgdSJPIG9yw6FjdWxvIFJlbidQeSBuw6NvIGZpY291
REM IGRpc3BvbsOtdmVsLiBBIGV4dHJhw6fDo28gY29udGludWEgYXBlbmFzIGNvbSBvIG1vdG9y
REM IEREQUM7IG8gcmVzdWx0YWRvIGVzdMOhIG1hcmNhZG8gY29tbyBzZW0gdmFsaWRhw6fDo28u
REM IikKICAgICAgICAgICAgcHJpbnQodSIgIFtBVklTT10gIiArIGF2aXNvX2ZhbGxiYWNrLCBm
REM bHVzaD1UcnVlKQogICAgICAgICAgICBsb2cuYXZpc28oYXZpc29fZmFsbGJhY2spCiAgICAg
REM ICAgY21wPV9kdWFsX3N0YWdlNF9jb21wYXJlKGRkYWMscmVucHkpOyBzdGF0dXNbIjQiXT0i
REM T0siOyBsb2cuaW5mbyhkdCgic3RhZ2U0X2RvbmUiLCBjbXBbImNvbmNvcmRhbmNpYXNfZXhh
REM dGFzIl0sIGNtcFsic29tZW50ZV9kZGFjIl0sIGNtcFsic29tZW50ZV9yZW5weSJdKSk7IHBy
REM aW50KGR0KCJzdGFnZTRfZG9uZSIsIGNtcFsiY29uY29yZGFuY2lhc19leGF0YXMiXSwgY21w
REM WyJzb21lbnRlX2RkYWMiXSwgY21wWyJzb21lbnRlX3JlbnB5Il0pLCBmbHVzaD1UcnVlKQog
REM ICAgICAgIGNvbWJpbmVkLGR1cD1fZHVhbF9yZXNvbHZlX2V4YWN0X2R1cGxpY2F0ZXMoZGRh
REM YytyZW5weSk7IHN0YXR1c1siNSJdPSJPSyI7IGxvZy5pbmZvKGR0KCJzdGFnZTVfZG9uZSIs
REM IGR1cFsiZHVwbGljYXRhcyJdKSk7IHByaW50KGR0KCJzdGFnZTVfZG9uZSIsIGR1cFsiZHVw
REM bGljYXRhcyJdKSwgZmx1c2g9VHJ1ZSkKICAgICAgICByZXNvbHZlZCxjb25mPV9kdWFsX3Jl
REM c29sdmVfb3ZlcmxhcHMoY29tYmluZWQpOyBzdGF0dXNbIjYiXT0iT0siOyBsb2cuaW5mbyhk
REM dCgic3RhZ2U2X2RvbmUiLCBsZW4oY29uZikpKTsgcHJpbnQoZHQoInN0YWdlNl9kb25lIiwg
REM bGVuKGNvbmYpKSwgZmx1c2g9VHJ1ZSkKICAgICAgICBhY2NlcHRlZCxyZXZpZXcsaWdub3Jl
REM ZD1fZHVhbF9jbGFzc2lmeV9hbGwocmVzb2x2ZWQscGFzdGFfZ2FtZSxyYWl6KTsgc3RhdHVz
REM WyI3Il09Ik9LIjsgc3RhdHVzWyI4Il09Ik9LIjsgZW5naW5lX2NvbW1vbl9pZ25vcmVkPXN1
REM bSgxIGZvciB4IGluIGlnbm9yZWQgaWYgeC5nZXQoImNsYXNzaWZpY2FjYW8iKT09IkVOR0lO
REM RV9DT01NT05fRFVQTElDQVRFIik7IGxvZy5pbmZvKGR0KCJzdGFnZTdfZG9uZSIsIGxlbihy
REM ZXNvbHZlZCkpKTsgbG9nLmluZm8oZHQoInN0YWdlOF9kb25lIiwgbGVuKGFjY2VwdGVkKSwg
REM bGVuKHJldmlldyksIGxlbihpZ25vcmVkKSwgZW5naW5lX2NvbW1vbl9pZ25vcmVkLCBzdW0o
REM MSBmb3IgeCBpbiBpZ25vcmVkIGlmIHguZ2V0KCJjbGFzc2lmaWNhY2FvIik9PSJHTE9CQUxf
REM RklMRV9FWENMVVNJT04iKSkpOyBwcmludChkdCgic3RhZ2U3X2RvbmUiLCBsZW4ocmVzb2x2
REM ZWQpKSwgZmx1c2g9VHJ1ZSk7IHByaW50KGR0KCJzdGFnZThfZG9uZSIsIGxlbihhY2NlcHRl
REM ZCksIGxlbihyZXZpZXcpLCBsZW4oaWdub3JlZCksIGVuZ2luZV9jb21tb25faWdub3JlZCwg
REM c3VtKDEgZm9yIHggaW4gaWdub3JlZCBpZiB4LmdldCgiY2xhc3NpZmljYWNhbyIpPT0iR0xP
REM QkFMX0ZJTEVfRVhDTFVTSU9OIikpLCBmbHVzaD1UcnVlKQogICAgICAgIGNhbm9uaWNhbD1f
REM ZHVhbF9jYW5vbmljYWxpemUoYWNjZXB0ZWQscGFzdGFfZ2FtZSk7IG1hcGE9X2R1YWxfbWVy
REM Z2VfbWFwX3dpdGhfaW50ZWdyaXR5KGNhbm9uaWNhbCxwYXN0YV9nYW1lKTsgX2R1YWxfd3Jp
REM dGVfY2Fub25pY2FsX291dHB1dHMocmFpeixwYXN0YV9nYW1lLGNhbm9uaWNhbCxtYXBhKTsg
REM c3RhdHVzWyI5Il09Ik9LIjsgbG9nLmluZm8oZHQoInN0YWdlOV9kb25lIiwgbGVuKGNhbm9u
REM aWNhbCkpKTsgcHJpbnQoZHQoInN0YWdlOV9kb25lIiwgbGVuKGNhbm9uaWNhbCkpLCBmbHVz
REM aD1UcnVlKQogICAgICAgIGZvciBuIGluIHJhbmdlKDEwLDE1KTogc3RhdHVzW3N0cihuKV09
REM IlBFTkRFTlRFIgogICAgICAgIHByaW50KGR0KCJzdGFnZTEwX3BlbmRpbmciKSk7IHByaW50
REM KGR0KCJzdGFnZTExX3BlbmRpbmciKSk7IHByaW50KGR0KCJzdGFnZTEyX3BlbmRpbmciKSk7
REM IHByaW50KGR0KCJzdGFnZTEzX3BlbmRpbmciKSk7IHByaW50KGR0KCJzdGFnZTE0X3BlbmRp
REM bmciKSk7IGxvZy5pbmZvKGR0KCJwZW5kaW5nX2xvZyIpKQogICAgICAgIHJlcG9ydC51cGRh
REM dGUoeyJhcnF1aXZvc19zY2FuIjpsZW4oY2FuZGlkYXRvcyksImNhbmRpZGF0b3NfZGRhYyI6
REM bGVuKGRkYWMpLCJjYW5kaWRhdG9zX3JlbnB5IjpsZW4ocmVucHkpLCJjb21wYXJhY2FvIjpj
REM bXAsImR1cGxpY2F0YXNfY29uc29saWRhZGFzIjpkdXAsInNvYnJlcG9zaWNvZXNfcmVzb2x2
REM aWRhcyI6bGVuKGNvbmYpLCJhY2VpdG9zIjpsZW4oYWNjZXB0ZWQpLCJyZXZpc2FvIjpsZW4o
REM cmV2aWV3KSwiaWdub3JhZG9zIjpsZW4oaWdub3JlZCksInJldmlzYW9faXRlbnMiOl9kdWFs
REM X3JlcG9ydF9pdGVuc19jb21wYWN0b3MocmV2aWV3KSwiaWdub3JhZG9zX2l0ZW5zIjpfZHVh
REM bF9yZXBvcnRfaXRlbnNfY29tcGFjdG9zKGlnbm9yZWQpLCJpZ25vcmFkb3NfZW5naW5lX2Nv
REM bW1vbiI6ZW5naW5lX2NvbW1vbl9pZ25vcmVkLCJpZ25vcmFkb3NfYXJxdWl2b3NfZ2xvYmFp
REM cyI6c3VtKDEgZm9yIHggaW4gaWdub3JlZCBpZiB4LmdldCgiY2xhc3NpZmljYWNhbyIpPT0i
REM R0xPQkFMX0ZJTEVfRVhDTFVTSU9OIiksImNhbm9uaWNvcyI6bGVuKGNhbm9uaWNhbCksInNl
REM bV9pbnZlbnRhcl90ZXh0byI6VHJ1ZSwib3JhY3Vsb19yZW5weV9hdGl2byI6YWN0aXZlLCJ2
REM YWxpZGFjYW9fcmVucHkiOiJWQUxJREFEQSIgaWYgYWN0aXZlIGVsc2UgIlNFTSBWQUxJREFD
REM QU8iLCJtb3Rvcl9mYWxsYmFja19kZGFjIjpub3QgYWN0aXZlLCJvcmFjdWxvX3JlbnB5Ijpf
REM ZHVhbF9yZXBvcnRfb3JhY2xlX2NvbXBhY3RvKCksInN0YWdlX3N0YXR1cyI6c3RhdHVzLCJ0
REM ZXJtaW5hbF9zdGF0dXMiOiJFWFRSQUNBT19DT05DTFVJREEiIGlmIGFjdGl2ZSBlbHNlICJF
REM WFRSQUNBT19DT05DTFVJREFfU0VNX1ZBTElEQUNBTyIsImV0YXBhc19leGVjdXRhZGFzIjpb
REM MSwyLDMsNCw1LDYsNyw4LDldLCJldGFwYXNfcGVuZGVudGVzIjpbMTAsMTEsMTIsMTMsMTRd
REM fSk7IF9kdWFsX3dyaXRlX3JlcG9ydChyYWl6LHJlcG9ydCkKICAgICAgICBsb2cucmVzdWx0
REM YWRvKGR0KCJsYWJlbF9zdGF0dXMiKSxkdCgiZmluYWxfc3RhdHVzIikgaWYgYWN0aXZlIGVs
REM c2Ugc3RhdHVzX29yYWN1bG8pOyBsb2cucmVzdWx0YWRvKGR0KCJsYWJlbF9zY2FubmVkIiks
REM c3RyKGxlbihjYW5kaWRhdG9zKSkpOyBsb2cucmVzdWx0YWRvKGR0KCJsYWJlbF9kZGFjIiks
REM c3RyKGxlbihkZGFjKSkpOyBsb2cucmVzdWx0YWRvKGR0KCJsYWJlbF9yZW5weSIpLHN0cihs
REM ZW4ocmVucHkpKSk7IGxvZy5yZXN1bHRhZG8oZHQoImxhYmVsX2NvbmNvcmQiKSxzdHIoY21w
REM WyJjb25jb3JkYW5jaWFzX2V4YXRhcyJdKSk7IGxvZy5yZXN1bHRhZG8oZHQoImxhYmVsX29u
REM bHlfZGRhYyIpLHN0cihjbXBbInNvbWVudGVfZGRhYyJdKSk7IGxvZy5yZXN1bHRhZG8oZHQo
REM ImxhYmVsX29ubHlfcmVucHkiKSxzdHIoY21wWyJzb21lbnRlX3JlbnB5Il0pKTsgbG9nLnJl
REM c3VsdGFkbyhkdCgibGFiZWxfY2Fub25pY2FsIiksc3RyKGxlbihjYW5vbmljYWwpKSk7IGxv
REM Zy5yZXN1bHRhZG8oZHQoImxhYmVsX29yYWNsZSIpLGR0KCJvcmFjbGVfeWVzIikgaWYgYWN0
REM aXZlIGVsc2Ugc3RhdHVzX29yYWN1bG8pOyBsb2cucmVzdWx0YWRvKHUiSXRlbnMgZW0gUkVW
REM SVPDg08iLHN0cihsZW4ocmV2aWV3KSkpOyBsb2cucmVzdWx0YWRvKHUiSXRlbnMgaWdub3Jh
REM ZG9zIChyZWxhdMOzcmlvIHBlcnNpc3RlbnRlKSIsc3RyKGxlbihpZ25vcmVkKSkpOyBsb2cu
REM cmVzdWx0YWRvKHUiUmVsYXTDs3JpbyIsb3MucGF0aC5qb2luKG9zLnBhdGguYWJzcGF0aChy
REM YWl6KSxfRFVBTF9SRVBPUlRfTkFNRSkpOyBsb2cucmVzdWx0YWRvKGR0KCJsYWJlbF9leGVj
REM dXRlZCIpLHUiMS05Iik7IGxvZy5yZXN1bHRhZG8oZHQoImxhYmVsX3BlbmRpbmciKSx1IjEw
REM LTE0Iik7IGxvZy5yZXN1bHRhZG8oZHQoImxhYmVsX3RpbWUiKSx1Ins6LjFmfXMiLmZvcm1h
REM dCh0aW1lLnRpbWUoKS1pbmljaW8pKTsgbG9nLnNlcGFyYWRvcigpOyBsb2cuc2FsdmFyKCk7
REM IHJldHVybiAwCiAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4YzoKICAgICAgICB0Yj10cmFj
REM ZWJhY2suZm9ybWF0X2V4YygpOyByZXBvcnQudXBkYXRlKHsic3RhZ2Vfc3RhdHVzIjpzdGF0
REM dXMsInRlcm1pbmFsX3N0YXR1cyI6IkVSUk9fSU5URVJOTyIsImVycm8iOnN0cihleGMpLCJ0
REM cmFjZWJhY2siOnRifSk7IGxvZy5lcnJvKHUiRVJSTyBJTlRFUk5PIE5PIERVQUxCUkFJTiBW
REM MTE4OiB7fSIuZm9ybWF0KGV4YykpOyBbbG9nLmVycm8oeCkgZm9yIHggaW4gdGIuc3BsaXRs
REM aW5lcygpWy0yMDpdXQogICAgICAgIHRyeTogX2R1YWxfd3JpdGVfcmVwb3J0KHJhaXoscmVw
REM b3J0KTsgbG9nLnJlc3VsdGFkbyhkdCgibGFiZWxfc3RhdHVzIiksZHQoImludGVybmFsX2Zp
REM bmFsIikpOyBsb2cucmVzdWx0YWRvKGR0KCJsYWJlbF90aW1lIiksdSJ7Oi4xZn1zIi5mb3Jt
REM YXQodGltZS50aW1lKCktaW5pY2lvKSk7IGxvZy5zZXBhcmFkb3IoKTsgbG9nLnNhbHZhcigp
REM CiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjogcGFzcwogICAgICAgIHJldHVybiAxCgpkZWYg
REM X2R1YWxfdmFsaWRhdGVfdHJhbnNsYXRpb25fdG9rZW5zKHJhaXopOgogICAgcGFzdGE9b3Mu
REM cGF0aC5qb2luKHJhaXosUEFTVEFfRU5UUkFEQV9OT01FKTsgbWFwYV9wYXRoPW9zLnBhdGgu
REM am9pbihwYXN0YSxOT01FX01BUEEpCiAgICBpZiBub3Qgb3MucGF0aC5pc2ZpbGUobWFwYV9w
REM YXRoKTogcmV0dXJuIHsib2siOkZhbHNlLCJlcnJvIjoibWFwYSBjYW7DtG5pY28gYXVzZW50
REM ZSJ9CiAgICB3aXRoIGlvLm9wZW4obWFwYV9wYXRoLCJyIixlbmNvZGluZz0idXRmLTgiKSBh
REM cyBmOiBtYXBhPWpzb24ubG9hZChmKQogICAgdG90YWw9MDsgZmFsaGFzPVtdOyB2YWxpZGFj
REM b2VzPTAKICAgIGZvciByZWwsZW50cmllcyBpbiBtYXBhLml0ZW1zKCk6CiAgICAgICAgcGF0
REM aD1vcy5wYXRoLmpvaW4ocGFzdGEscmVsLnJlcGxhY2UoIi8iLG9zLnNlcCkpCiAgICAgICAg
REM aWYgbm90IG9zLnBhdGguaXNmaWxlKHBhdGgpOiBmYWxoYXMuYXBwZW5kKHUiYXJxdWl2byBh
REM dXNlbnRlOiB7fSIuZm9ybWF0KHJlbCkpOyBjb250aW51ZQogICAgICAgIHRleHRzPWxlcl90
REM ZXh0b3NfdHJhZHV6aWRvcyhwYXRoKQogICAgICAgIGlmIGxlbih0ZXh0cykhPWxlbihlbnRy
REM aWVzKTogZmFsaGFzLmFwcGVuZCh1ImNvbnRhZ2VtIGRpdmVyZ2VudGU6IHt9Ii5mb3JtYXQo
REM cmVsKSk7IGNvbnRpbnVlCiAgICAgICAgZm9yIGksZSBpbiBlbnVtZXJhdGUoZW50cmllcyk6
REM CiAgICAgICAgICAgIGVzcGVyYWRvPWUuZ2V0KCJ0b2tlbl9zaWduYXR1cmUiKSBvciBbXQog
REM ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICByZWNlYmlkbz1fdG9rZW5fc2lnbmF0
REM dXJlX21hcGEodGV4dHNbaV0pCiAgICAgICAgICAgICAgICBpZiByZWNlYmlkbyE9ZXNwZXJh
REM ZG86CiAgICAgICAgICAgICAgICAgICAgcmFpc2UgR29vZ2xlVHJhbnNsYXRlVmFsaWRhdGlv
REM bkVycm9yKHUiYXNzaW5hdHVyYSBkZSB0b2tlbnMgYWx0ZXJhZGEiKQogICAgICAgICAgICAg
REM ICAgdmFsaWRhY29lcys9MQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGV4Yzog
REM ZmFsaGFzLmFwcGVuZCh1Int9I3t9OiB7fSIuZm9ybWF0KHJlbCxpKzEsZXhjKSkKICAgICAg
REM ICAgICAgdG90YWwrPTEKICAgIHJldHVybiB7Im9rIjpub3QgZmFsaGFzLCJlbnRyYWRhcyI6
REM dG90YWwsInRva2Vuc192YWxpZGFkb3MiOnZhbGlkYWNvZXMsImZhbGhhcyI6ZmFsaGFzfQoK
REM CmRlZiBleGVjdXRhcl90cmFkdWNhb19nb29nbGVfdjEwMShyYWl6KToKICAgIHByaW50KGR0
REM KCJ0cmFuc2xhdGVfc3RhZ2UiKSkKICAgIHJjPV9WMTAwX0VYRUNVVEFSX1RSQURVQ0FPX0dP
REM T0dMRShyYWl6KQogICAgaWYgcmMgbm90IGluICgwLE5vbmUpOiByZXR1cm4gcmMKICAgIHY9
REM X2R1YWxfdmFsaWRhdGVfdHJhbnNsYXRpb25fdG9rZW5zKHJhaXopOyBwcmludChkdCgidG9r
REM ZW5zX3N0YWdlIiwgZHQoInN0YXR1c19vayIpIGlmIHYuZ2V0KCJvayIpIGVsc2UgZHQoInN0
REM YXR1c19mYWlsIikpKQogICAgaWYgbm90IHYuZ2V0KCJvayIpOgogICAgICAgIHdpdGggaW8u
REM b3Blbihvcy5wYXRoLmpvaW4ocmFpeiwiRERBQy1EdWFsLVRva2Vucy1FcnJvLnR4dCIpLCJ3
REM IixlbmNvZGluZz0idXRmLTgiKSBhcyBmOiBmLndyaXRlKHUiXG4iLmpvaW4odi5nZXQoImZh
REM bGhhcyIsW10pIG9yIFt2LmdldCgiZXJybyIsdSJlcnJvIGRlc2NvbmhlY2lkbyIpXSkpCiAg
REM ICAgICAgcmV0dXJuIDEKICAgIHJldHVybiAwCgoKZGVmIF9kdWFsX2NsZWFuX3J1bnRpbWVf
REM ZHVwbGljYXRlcyhyYWl6LHBhc3RhX2dhbWUsbG9nLCBtYXBhPU5vbmUpOgogICAgIiIiQXVk
REM aXRhIGNvbGlzw7VlcyBnYW1lL2NvbW1vbjsgY29uZmxpdG9zIGRpdmVyZ2VudGVzIGZpY2Ft
REM IHJlZ2lzdHJhZG9zIHBhcmEgZGlhZ27Ds3N0aWNvLiIiIgogICAgY29tbW9uPW9zLnBhdGgu
REM am9pbihyYWl6LCJyZW5weSIsImNvbW1vbiIpOyByZW1vdmVkPVtdOyBjb25mbGljdHM9W107
REM IHByZXNlcnZlZD1bXQogICAgaWYgbm90IG9zLnBhdGguaXNkaXIoY29tbW9uKTogcmV0dXJu
REM IHJlbW92ZWQsY29uZmxpY3RzLHByZXNlcnZlZAogICAgY2Fub25pY2FsX2ZpbGVzPXNldCgo
REM bWFwYSBvciB7fSkua2V5cygpKQogICAgZm9yIHJvb3QsZGlycyxmaWxlcyBpbiBvcy53YWxr
REM KHBhc3RhX2dhbWUpOgogICAgICAgIGZvciBmbiBpbiBmaWxlczoKICAgICAgICAgICAgaWYg
REM bm90IGZuLmxvd2VyKCkuZW5kc3dpdGgoKCIucnB5IiwiLnJweW0iKSk6IGNvbnRpbnVlCiAg
REM ICAgICAgICAgIHNyYz1vcy5wYXRoLmpvaW4ocm9vdCxmbik7IHJlbD1fZHVhbF9ub3JtX3Jl
REM bChvcy5wYXRoLnJlbHBhdGgoc3JjLHBhc3RhX2dhbWUpKTsgb3RoZXI9b3MucGF0aC5qb2lu
REM KGNvbW1vbixyZWwucmVwbGFjZSgiLyIsb3Muc2VwKSkKICAgICAgICAgICAgaWYgbm90IG9z
REM LnBhdGguaXNmaWxlKG90aGVyKTogY29udGludWUKICAgICAgICAgICAgdHJ5OiBoMT1zaGEy
REM NTZfYXJxdWl2byhzcmMpOyBoMj1zaGEyNTZfYXJxdWl2byhvdGhlcikKICAgICAgICAgICAg
REM ZXhjZXB0IEV4Y2VwdGlvbjogY29udGludWUKICAgICAgICAgICAgaWYgaDE9PWgyOgogICAg
REM ICAgICAgICAgICAgaWYgcmVsIGluIGNhbm9uaWNhbF9maWxlczoKICAgICAgICAgICAgICAg
REM ICAgICBwcmVzZXJ2ZWQuYXBwZW5kKHsiYXJxdWl2byI6cmVsLCJtb3Rpdm8iOiJtYXBhX2F0
REM dWFsX2NvbnRlbV9lbnRyYWRhczsgcHJlc2VydmFkbyBlIHRyYXRhZG8gY29tbyBkdXBsaWNh
REM dGEgZXhhdGEgZG8gcnVudGltZSJ9KQogICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAg
REM ICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgb3MucmVtb3ZlKHNyYyk7
REM IHJlbW92ZWQuYXBwZW5kKHJlbCkKICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24g
REM YXMgZXhjOgogICAgICAgICAgICAgICAgICAgIHByZXNlcnZlZC5hcHBlbmQoeyJhcnF1aXZv
REM IjpyZWwsIm1vdGl2byI6Im7Do28gZm9pIHBvc3PDrXZlbCByZW1vdmVyIGEgY8OzcGlhIGlk
REM w6pudGljYToge30iLmZvcm1hdChleGMpfSkKICAgICAgICAgICAgZWxzZToKICAgICAgICAg
REM ICAgICAgIGNvbmZsaWN0cy5hcHBlbmQoeyJhcnF1aXZvIjpyZWwsImdhbWVfc2hhMjU2Ijpo
REM MSwiY29tbW9uX3NoYTI1NiI6aDIsInRyYXRhbWVudG8iOiJwcmVzZXJ2YWRvX3NlbV9hbHRl
REM cmFjYW9fcGVsb19hcGxpY2Fkb3IiLCJycHljX3BhcmVhZG8iOiJpbnZhbGlkYXJfYW50ZXNf
REM ZGFfcHJpbWVpcmFfZXhlY3VjYW8ifSkKICAgIHJldHVybiByZW1vdmVkLGNvbmZsaWN0cyxw
REM cmVzZXJ2ZWQKCgpkZWYgX2R1YWxfY29tcGlsZV9jb2xsaXNpb25fc2NhbihwYXN0YV9nYW1l
REM KToKICAgIHBhaXJlZD1bXQogICAgZm9yIHJvb3QsZGlycyxmaWxlcyBpbiBvcy53YWxrKHBh
REM c3RhX2dhbWUpOgogICAgICAgIG5hbWVzPXt4Lmxvd2VyKCkgZm9yIHggaW4gZmlsZXN9CiAg
REM ICAgICAgZm9yIGZuIGluIGZpbGVzOgogICAgICAgICAgICBsb3c9Zm4ubG93ZXIoKQogICAg
REM ICAgICAgICBpZiBsb3cuZW5kc3dpdGgoIi5ycHljIikgYW5kIChsb3dbOi0xXSsieSIpIGlu
REM IG5hbWVzOgogICAgICAgICAgICAgICAgcGFpcmVkLmFwcGVuZChfZHVhbF9ub3JtX3JlbChv
REM cy5wYXRoLnJlbHBhdGgob3MucGF0aC5qb2luKHJvb3QsZm4pLHBhc3RhX2dhbWUpKSkKICAg
REM ICAgICAgICAgZWxpZiBsb3cuZW5kc3dpdGgoIi5ycHltYyIpIGFuZCAobG93WzotMV0rIm0i
REM KSBpbiBuYW1lczoKICAgICAgICAgICAgICAgIHBhaXJlZC5hcHBlbmQoX2R1YWxfbm9ybV9y
REM ZWwob3MucGF0aC5yZWxwYXRoKG9zLnBhdGguam9pbihyb290LGZuKSxwYXN0YV9nYW1lKSkp
REM CiAgICByZXR1cm4gc29ydGVkKHNldChwYWlyZWQpLGtleT1sYW1iZGEgeDp4Lmxvd2VyKCkp
REM CgoKCmRlZiBfYmF0X3NldF9zYWZlKHZhbHVlKToKICAgICMgTWVuc2FnZW5zIGVudHJhbSBl
REM bSBzZXQgIlZBUj0uLi4iOyAlIGRldmUgc2VyIGR1cGxpY2FkbyBwYXJhIG7Do28gc2VyIGV4
REM cGFuZGlkbyBwZWxvIENNRC4KICAgIHZhbHVlPSh2YWx1ZSBvciB1JycpLnJlcGxhY2UodScl
REM Jyx1JyUlJykKICAgIHJldHVybiB2YWx1ZS5yZXBsYWNlKHUnXHInLHUnICcpLnJlcGxhY2Uo
REM dSdcbicsdScgJykKCgpBUExJQ0FET1JfTUVOU0FHRU5TPXsKICAgIDE6ewogICAgICAgICd0
REM aXR1bG8nOnUnRERBQyAtIEFwbGljYXIgTWVzY2xhZ2VtJywKICAgICAgICAnZXRhcGFfYmFj
REM a3VwJzp1J1sxLzRdIEZhemVuZG8gYmFja3VwIGRhIGdhbWUgYXR1YWwuLi4nLAogICAgICAg
REM ICdldGFwYV92YWxpZGFyJzp1J1syLzRdIFZhbGlkYW5kbyBvcyByZWN1cnNvcyBkYSBtZXNj
REM bGFnZW0uLi4nLAogICAgICAgICdldGFwYV9hcGxpY2FyJzp1J1szLzRdIFN1YnN0aXR1aW5k
REM byBjb21wbGV0YW1lbnRlIGEgZ2FtZS4uLicsCiAgICAgICAgJ2V0YXBhX2ZpbmFsJzp1J1s0
REM LzRdIEFwbGljYcOnw6NvIGRhIGdhbWUgY29uY2x1w61kYS4nLAogICAgICAgICdlcnJvX2dh
REM bWVfbWVzY2xhZGEnOnUnQSBwYXN0YSBnYW1lIGRhIG1lc2NsYWdlbSBuw6NvIGZvaSBlbmNv
REM bnRyYWRhLicsCiAgICAgICAgJ2Vycm9fYmFja3VwX2FudGVyaW9yJzp1J07Do28gZm9pIHBv
REM c3PDrXZlbCByb3RhY2lvbmFyIG8gYmFja3VwIGFudGVyaW9yIGRhIGdhbWUuJywKICAgICAg
REM ICAnZXJyb19iYWNrdXBfZ2FtZSc6dSdGYWxoYSBubyBiYWNrdXAgZGEgZ2FtZSBhdHVhbC4n
REM LAogICAgICAgICdlcnJvX21lcmdlZF9nb25lJzp1J0EgcGFzdGEgZ2FtZSBkYSBtZXNjbGFn
REM ZW0gZGVzYXBhcmVjZXUgYW50ZXMgZGEgYXBsaWNhw6fDo28uJywKICAgICAgICAnZXJyb19h
REM cHBseSc6dSdGYWxoYSBhbyBhcGxpY2FyIGEgZ2FtZSBtZXNjbGFkYS4nLAogICAgICAgICdh
REM dmlzb19nYW1lX2F1c2VudGUnOnUnQSBwYXN0YSBnYW1lIGF0dWFsIG7Do28gZm9pIGVuY29u
REM dHJhZGE7IGEgYXBsaWNhw6fDo28gY29udGludWFyw6EuJywKICAgICAgICAnc3VjZXNzbyc6
REM dSdBUExJQ0HDh8ODTyBDT05DTFXDjURBIENPTSBTVUNFU1NPJywKICAgICAgICAnYmFja3Vw
REM X2dhbWUnOnUnQmFja3VwIGRhIGdhbWUgb3JpZ2luYWw6JywKICAgICAgICAnYmFja3VwX2Fu
REM dGVyaW9yJzp1J0JhY2t1cCBhbnRlcmlvciBwcmVzZXJ2YWRvOicsCiAgICAgICAgJ2dhbWVf
REM YXBsaWNhZGEnOnUnR2FtZSBhcGxpY2FkYTonLAogICAgICAgICdyZWNvbXBpbGEnOnUnT3Mg
REM YXJxdWl2b3MgZGUgY8OzZGlnbyBzZXLDo28gcmVjb21waWxhZG9zIHBlbG8gUmVuXCdQeSBu
REM YSBwcsOzeGltYSBpbmljaWFsaXphw6fDo28sIHF1YW5kbyBuZWNlc3PDoXJpby4nLAogICAg
REM ICAgICdlcnJvX3RhZyc6dSdFUlJPJywKICAgICAgICAnYXZpc29fdGFnJzp1J0FWSVNPJywK
REM ICAgICAgICAncHJlc3MnOnUnUHJlc3Npb25lIHF1YWxxdWVyIHRlY2xhIHBhcmEgY29udGlu
REM dWFyLi4uJywKICAgIH0sCiAgICAyOnsKICAgICAgICAndGl0dWxvJzp1J0REQUMgLSBBcHBs
REM eSBNZXJnZScsCiAgICAgICAgJ2V0YXBhX2JhY2t1cCc6dSdbMS80XSBCYWNraW5nIHVwIHRo
REM ZSBjdXJyZW50IGdhbWUuLi4nLAogICAgICAgICdldGFwYV92YWxpZGFyJzp1J1syLzRdIFZh
REM bGlkYXRpbmcgdGhlIG1lcmdlIHJlc291cmNlcy4uLicsCiAgICAgICAgJ2V0YXBhX2FwbGlj
REM YXInOnUnWzMvNF0gQ29tcGxldGVseSByZXBsYWNpbmcgdGhlIGdhbWUuLi4nLAogICAgICAg
REM ICdldGFwYV9maW5hbCc6dSdbNC80XSBHYW1lIGFwcGxpY2F0aW9uIGNvbXBsZXRlZC4nLAog
REM ICAgICAgICdlcnJvX2dhbWVfbWVzY2xhZGEnOnUnVGhlIG1lcmdlZCBnYW1lIGZvbGRlciB3
REM YXMgbm90IGZvdW5kLicsCiAgICAgICAgJ2Vycm9fYmFja3VwX2FudGVyaW9yJzp1J1RoZSBw
REM cmV2aW91cyBnYW1lIGJhY2t1cCBjb3VsZCBub3QgYmUgcm90YXRlZC4nLAogICAgICAgICdl
REM cnJvX2JhY2t1cF9nYW1lJzp1J0ZhaWxlZCB0byBiYWNrIHVwIHRoZSBjdXJyZW50IGdhbWUu
REM JywKICAgICAgICAnZXJyb19tZXJnZWRfZ29uZSc6dSdUaGUgbWVyZ2VkIGdhbWUgZm9sZGVy
REM IGRpc2FwcGVhcmVkIGJlZm9yZSBhcHBsaWNhdGlvbi4nLAogICAgICAgICdlcnJvX2FwcGx5
REM Jzp1J0ZhaWxlZCB0byBhcHBseSB0aGUgbWVyZ2VkIGdhbWUuJywKICAgICAgICAnYXZpc29f
REM Z2FtZV9hdXNlbnRlJzp1J1RoZSBjdXJyZW50IGdhbWUgZm9sZGVyIHdhcyBub3QgZm91bmQ7
REM IHRoZSBhcHBsaWNhdGlvbiB3aWxsIGNvbnRpbnVlLicsCiAgICAgICAgJ3N1Y2Vzc28nOnUn
REM QVBQTElDQVRJT04gQ09NUExFVEVEIFNVQ0NFU1NGVUxMWScsCiAgICAgICAgJ2JhY2t1cF9n
REM YW1lJzp1J09yaWdpbmFsIGdhbWUgYmFja3VwOicsCiAgICAgICAgJ2JhY2t1cF9hbnRlcmlv
REM cic6dSdQcmV2aW91cyBiYWNrdXAgcHJlc2VydmVkOicsCiAgICAgICAgJ2dhbWVfYXBsaWNh
REM ZGEnOnUnQXBwbGllZCBnYW1lOicsCiAgICAgICAgJ3JlY29tcGlsYSc6dSdDb2RlIGZpbGVz
REM IHdpbGwgYmUgcmVjb21waWxlZCBieSBSZW5cJ1B5IG9uIHRoZSBuZXh0IHN0YXJ0dXAgd2hl
REM biBuZWVkZWQuJywKICAgICAgICAnZXJyb190YWcnOnUnRVJST1InLAogICAgICAgICdhdmlz
REM b190YWcnOnUnV0FSTklORycsCiAgICAgICAgJ3ByZXNzJzp1J1ByZXNzIGFueSBrZXkgdG8g
REM Y29udGludWUuLi4nLAogICAgfSwKICAgIDM6ewogICAgICAgICd0aXR1bG8nOnUnRERBQyAt
REM IEFwbGljYXIgY29tYmluYWNpw7NuJywKICAgICAgICAnZXRhcGFfYmFja3VwJzp1J1sxLzRd
REM IEhhY2llbmRvIGNvcGlhIGRlIHNlZ3VyaWRhZCBkZSBsYSBnYW1lIGFjdHVhbC4uLicsCiAg
REM ICAgICAgJ2V0YXBhX3ZhbGlkYXInOnUnWzIvNF0gVmFsaWRhbmRvIGxvcyByZWN1cnNvcyBk
REM ZSBsYSBjb21iaW5hY2nDs24uLi4nLAogICAgICAgICdldGFwYV9hcGxpY2FyJzp1J1szLzRd
REM IFN1c3RpdHV5ZW5kbyBwb3IgY29tcGxldG8gbGEgZ2FtZS4uLicsCiAgICAgICAgJ2V0YXBh
REM X2ZpbmFsJzp1J1s0LzRdIEFwbGljYWNpw7NuIGRlIGxhIGdhbWUgY29tcGxldGFkYS4nLAog
REM ICAgICAgICdlcnJvX2dhbWVfbWVzY2xhZGEnOnUnTm8gc2UgZW5jb250csOzIGxhIGNhcnBl
REM dGEgZ2FtZSBkZSBsYSBjb21iaW5hY2nDs24uJywKICAgICAgICAnZXJyb19iYWNrdXBfYW50
REM ZXJpb3InOnUnTm8gc2UgcHVkbyByb3RhciBsYSBjb3BpYSBkZSBzZWd1cmlkYWQgYW50ZXJp
REM b3IgZGUgbGEgZ2FtZS4nLAogICAgICAgICdlcnJvX2JhY2t1cF9nYW1lJzp1J05vIHNlIHB1
REM ZG8gY3JlYXIgbGEgY29waWEgZGUgc2VndXJpZGFkIGRlIGxhIGdhbWUgYWN0dWFsLicsCiAg
REM ICAgICAgJ2Vycm9fbWVyZ2VkX2dvbmUnOnUnTGEgY2FycGV0YSBnYW1lIGRlIGxhIGNvbWJp
REM bmFjacOzbiBkZXNhcGFyZWNpw7MgYW50ZXMgZGUgbGEgYXBsaWNhY2nDs24uJywKICAgICAg
REM ICAnZXJyb19hcHBseSc6dSdObyBzZSBwdWRvIGFwbGljYXIgbGEgZ2FtZSBjb21iaW5hZGEu
REM JywKICAgICAgICAnYXZpc29fZ2FtZV9hdXNlbnRlJzp1J05vIHNlIGVuY29udHLDsyBsYSBj
REM YXJwZXRhIGdhbWUgYWN0dWFsOyBsYSBhcGxpY2FjacOzbiBjb250aW51YXLDoS4nLAogICAg
REM ICAgICdzdWNlc3NvJzp1J0FQTElDQUNJw5NOIENPTVBMRVRBREEgQ09SUkVDVEFNRU5URScs
REM CiAgICAgICAgJ2JhY2t1cF9nYW1lJzp1J0NvcGlhIGRlIHNlZ3VyaWRhZCBkZSBsYSBnYW1l
REM IG9yaWdpbmFsOicsCiAgICAgICAgJ2JhY2t1cF9hbnRlcmlvcic6dSdDb3BpYSBkZSBzZWd1
REM cmlkYWQgYW50ZXJpb3IgY29uc2VydmFkYTonLAogICAgICAgICdnYW1lX2FwbGljYWRhJzp1
REM J0dhbWUgYXBsaWNhZGE6JywKICAgICAgICAncmVjb21waWxhJzp1J0xvcyBhcmNoaXZvcyBk
REM ZSBjw7NkaWdvIHNlIHJlY29tcGlsYXLDoW4gcG9yIFJlblwnUHkgZW4gZWwgcHLDs3hpbW8g
REM aW5pY2lvLCBjdWFuZG8gc2VhIG5lY2VzYXJpby4nLAogICAgICAgICdlcnJvX3RhZyc6dSdF
REM UlJPUicsCiAgICAgICAgJ2F2aXNvX3RhZyc6dSdBVklTTycsCiAgICAgICAgJ3ByZXNzJzp1
REM J1B1bHNhIGN1YWxxdWllciB0ZWNsYSBwYXJhIGNvbnRpbnVhci4uLicsCiAgICB9LAp9CgoK
REM ZGVmIF9tdWx0aWxhbmdfcGxhY2Vob2xkZXJfc2lnbmF0dXJlKHRleHRvKToKICAgIHJldHVy
REM biB0dXBsZShyZS5maW5kYWxsKHInXHtbXnt9XSpcfScsIHRleHRvIG9yIHUnJykpCgoKZGVm
REM IHZhbGlkYXJfbXVsdGlsaW5ndWVfY29tcGxldG8oKToKICAgICIiIkdhcmFudGUgcGFyaWRh
REM ZGUgZXN0cnV0dXJhbCBlbnRyZSBQb3J0dWd1w6pzLCBFbmdsaXNoIGUgRXNwYcOxb2wuIiIi
REM CiAgICB0YWJlbGFzPSgodSdNRU5TQUdFTlMnLE1FTlNBR0VOUyksKHUnQVBMSUNBRE9SX01F
REM TlNBR0VOUycsQVBMSUNBRE9SX01FTlNBR0VOUyksKHUnRFVBTF9NRU5TQUdFTlMnLERVQUxf
REM TUVOU0FHRU5TKSwodSdDT0xJU0FPX1JFTEFUT1JJT19ST1RVTE9TJyxDT0xJU0FPX1JFTEFU
REM T1JJT19ST1RVTE9TKSkKICAgIGZvciBub21lLHRhYmVsYSBpbiB0YWJlbGFzOgogICAgICAg
REM IGNvbmp1bnRvcz1bc2V0KHRhYmVsYS5nZXQoaSx7fSkua2V5cygpKSBmb3IgaSBpbiAoMSwy
REM LDMpXQogICAgICAgIGlmIG5vdCAoY29uanVudG9zWzBdPT1jb25qdW50b3NbMV09PWNvbmp1
REM bnRvc1syXSk6CiAgICAgICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcih1J011bHRpbMOtbmd1
REM YSBpbmNvbnNpc3RlbnRlIGVtIHt9OiBjaGF2ZXMgZGl2ZXJnZW50ZXMuJy5mb3JtYXQobm9t
REM ZSkpCiAgICAgICAgZm9yIGNoYXZlIGluIHNvcnRlZChjb25qdW50b3NbMF0pOgogICAgICAg
REM ICAgICB2YWxzPVt0YWJlbGFbaV0uZ2V0KGNoYXZlLHUnJykgZm9yIGkgaW4gKDEsMiwzKV0K
REM ICAgICAgICAgICAgaWYgYW55KHYgaXMgTm9uZSBvciB2PT11JycgZm9yIHYgaW4gdmFscyk6
REM CiAgICAgICAgICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IodSdNdWx0aWzDrW5ndWEgaW5j
REM b21wbGV0YSBlbSB7fS57fScuZm9ybWF0KG5vbWUsY2hhdmUpKQogICAgICAgICAgICBzaWc9
REM W19tdWx0aWxhbmdfcGxhY2Vob2xkZXJfc2lnbmF0dXJlKHYpIGZvciB2IGluIHZhbHNdCiAg
REM ICAgICAgICAgIGlmIG5vdCAoc2lnWzBdPT1zaWdbMV09PXNpZ1syXSk6CiAgICAgICAgICAg
REM ICAgICByYWlzZSBSdW50aW1lRXJyb3IodSdQbGFjZWhvbGRlcnMgZGl2ZXJnZW50ZXMgZW0g
REM e30ue30nLmZvcm1hdChub21lLGNoYXZlKSkKICAgICAgICAgICAgYnI9W3YuY291bnQodSdc
REM bicpIGZvciB2IGluIHZhbHNdCiAgICAgICAgICAgIGlmIG5vdCAoYnJbMF09PWJyWzFdPT1i
REM clsyXSk6CiAgICAgICAgICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IodSdRdWVicmFzIGRl
REM IGxpbmhhIGRpdmVyZ2VudGVzIGVtIHt9Lnt9Jy5mb3JtYXQobm9tZSxjaGF2ZSkpCiAgICBy
REM ZXR1cm4gVHJ1ZQoKCmRlZiBfZHVhbF93cml0ZV9pbnN0YWxsZXIobWVyZ2VkX3Jvb3QpOgog
REM ICAgIiIiR2VyYSB1bSBhcGxpY2Fkb3IgZWNvbsO0bWljbyBlIGxvY2FsaXphZG8uIE7Do28g
REM dG9jYSBlbSByZW5weS9jb21tb24uIiIiCiAgICB2YWxpZGFyX211bHRpbGluZ3VlX2NvbXBs
REM ZXRvKCkKICAgIGluc3RhbGxlcj1vcy5wYXRoLmpvaW4obWVyZ2VkX3Jvb3QsX0RVQUxfSU5T
REM VEFMTEVSX05BTUUpCiAgICBtPUFQTElDQURPUl9NRU5TQUdFTlMuZ2V0KElESU9NQSxBUExJ
REM Q0FET1JfTUVOU0FHRU5TWzFdKQogICAgcT1sYW1iZGEgazpfYmF0X3NldF9zYWZlKG1ba10p
REM CiAgICB0ZW1wbGF0ZT0iIiJAZWNobyBvZmYKY2hjcCA2NTAwMSA+bnVsCnNldGxvY2FsIEVu
REM YWJsZUV4dGVuc2lvbnMgRW5hYmxlRGVsYXllZEV4cGFuc2lvbgpzZXQgIk1FUkdFRD0lfmRw
REM MGdhbWUiCnNldCAiUk9PVD0lfmRwMC4uIgpmb3IgJSVJIGluICgiJVJPT1QlIikgZG8gc2V0
REM ICJST09UPSUlfmZJIgpzZXQgIlRBUkdFVD0lUk9PVCVcXGdhbWUiCnNldCAiRERBQ19CQUNL
REM VVBfUk9PVD0lUk9PVCVcXEREQUMtQmFja3VwIgpzZXQgIkREQUNfR0FNRV9CQUNLVVA9JURE
REM QUNfQkFDS1VQX1JPT1QlXFxnYW1lIgoKaWYgbm90IGV4aXN0ICIlTUVSR0VEJVxcIiAoCiAg
REM ICBlY2hvIFtfX0VSUk9SX1RBR19fXSBfX0VSUl9HQU1FX01FUkdFRF9fCiAgICBlY2hvIF9f
REM UFJFU1NfXwogICAgcGF1c2UgPm51bAogICAgZXhpdCAvYiAxCikKaWYgbm90IGV4aXN0ICIl
REM RERBQ19CQUNLVVBfUk9PVCVcXCIgbWtkaXIgIiVEREFDX0JBQ0tVUF9ST09UJSIgPm51bCAy
REM PiYxCgpzZXQgIkJBQ0tVUF9QUkVWSU9VUz0iCmlmIGV4aXN0ICIlRERBQ19HQU1FX0JBQ0tV
REM UCVcXCIgKAogICAgc2V0ICJCQUNLVVBfUFJFVklPVVM9JUREQUNfQkFDS1VQX1JPT1QlXFxn
REM YW1lLXByZXZpb3VzLSVSQU5ET00lIgogICAgbW92ZSAiJUREQUNfR0FNRV9CQUNLVVAlIiAi
REM JUJBQ0tVUF9QUkVWSU9VUyUiID5udWwgMj4mMQogICAgaWYgZXJyb3JsZXZlbCAxICgKICAg
REM ICAgICBlY2hvIFtfX0VSUk9SX1RBR19fXSBfX0VSUl9ST1RBVEVfXwogICAgICAgIGVjaG8g
REM X19QUkVTU19fCiAgICAgICAgcGF1c2UgPm51bAogICAgICAgIGV4aXQgL2IgMQogICAgKQop
REM CgppZiBleGlzdCAiJUREQUNfR0FNRV9CQUNLVVAlXFwiIHJtZGlyIC9RIC9TICIlRERBQ19H
REM QU1FX0JBQ0tVUCUiID5udWwgMj4mMQpta2RpciAiJUREQUNfR0FNRV9CQUNLVVAlIiA+bnVs
REM IDI+JjEKCmVjaG8gPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09CmVjaG8gX19USVRMRV9fCmVjaG8gPT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09CmVjaG8gX19T
REM VEVQMV9fCmlmIGV4aXN0ICIlVEFSR0VUJVxcIiAoCiAgICByb2JvY29weSAiJVRBUkdFVCUi
REM ICIlRERBQ19HQU1FX0JBQ0tVUCUiIC9FIC9DT1BZOkRBVCAvUjowIC9XOjAgL05GTCAvTkRM
REM IC9OSkggL05KUyAvWEYgKi5ycHljICoucnB5bWMgPm51bAogICAgaWYgZXJyb3JsZXZlbCA4
REM ICgKICAgICAgICBlY2hvIFtfX0VSUk9SX1RBR19fXSBfX0VSUl9CQUNLVVBfR0FNRV9fCiAg
REM ICAgICAgZWNobyBfX1BSRVNTX18KICAgICAgICBwYXVzZSA+bnVsCiAgICAgICAgZXhpdCAv
REM YiAxCiAgICApCikgZWxzZSAoCiAgICBlY2hvIFtfX1dBUk5JTkdfVEFHX19dIF9fV0FSTl9H
REM QU1FX01JU1NJTkdfXwopCgplY2hvIF9fU1RFUDJfXwppZiBub3QgZXhpc3QgIiVNRVJHRUQl
REM XFwiICgKICAgIGVjaG8gW19fRVJST1JfVEFHX19dIF9fRVJSX01FUkdFRF9HT05FX18KICAg
REM IGNhbGwgOkREQUNfUk9MTEJBQ0tfR0FNRQogICAgZWNobyBfX1BSRVNTX18KICAgIHBhdXNl
REM ID5udWwKICAgIGV4aXQgL2IgMQopCgplY2hvIF9fU1RFUDNfXwppZiBleGlzdCAiJVRBUkdF
REM VCVcXCIgcm1kaXIgL1EgL1MgIiVUQVJHRVQlIiA+bnVsIDI+JjEKbWtkaXIgIiVUQVJHRVQl
REM IiA+bnVsIDI+JjEKcm9ib2NvcHkgIiVNRVJHRUQlIiAiJVRBUkdFVCUiIC9FIC9DT1BZOkRB
REM VCAvUjowIC9XOjAgL05GTCAvTkRMIC9OSkggL05KUyAvWEYgKi5ycHljICoucnB5bWMgPm51
REM bAppZiBlcnJvcmxldmVsIDggKAogICAgZWNobyBbX19FUlJPUl9UQUdfX10gX19FUlJfQVBQ
REM TFlfXwogICAgY2FsbCA6RERBQ19ST0xMQkFDS19HQU1FCiAgICBlY2hvIF9fUFJFU1NfXwog
REM ICAgcGF1c2UgPm51bAogICAgZXhpdCAvYiAxCikKCmVjaG8gX19TVEVQNF9fCmVjaG8uCmVj
REM aG8gPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09CmVjaG8gX19TVUNDRVNTX18KZWNobyA9PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0KZWNobyBfX0JBQ0tVUF9H
REM QU1FX18gIiVEREFDX0dBTUVfQkFDS1VQJSIKaWYgZGVmaW5lZCBCQUNLVVBfUFJFVklPVVMg
REM ZWNobyBfX0JBQ0tVUF9QUkVWSU9VU19fICIlQkFDS1VQX1BSRVZJT1VTJSIKZWNobyBfX0dB
REM TUVfQVBQTElFRF9fICIlVEFSR0VUJSIKZWNoby4KZWNobyBfX1JFQ09NUElMRV9fCmVjaG8g
REM PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
REM PT09PT09CmVjaG8gX19QUkVTU19fCnBhdXNlID5udWwKZXhpdCAvYiAwCgo6RERBQ19ST0xM
REM QkFDS19HQU1FCmlmIGV4aXN0ICIlVEFSR0VUJVxcIiBybWRpciAvUSAvUyAiJVRBUkdFVCUi
REM ID5udWwgMj4mMQppZiBleGlzdCAiJUREQUNfR0FNRV9CQUNLVVAlXFwiICgKICAgIG1rZGly
REM ICIlVEFSR0VUJSIgPm51bCAyPiYxCiAgICByb2JvY29weSAiJUREQUNfR0FNRV9CQUNLVVAl
REM IiAiJVRBUkdFVCUiIC9FIC9DT1BZOkRBVCAvUjowIC9XOjAgL05GTCAvTkRMIC9OSkggL05K
REM UyAvWEYgKi5ycHljICoucnB5bWMgPm51bAopCmV4aXQgL2IgMAoiIiIKICAgIHJlcD17CiAg
REM ICAgICAgJ19fRVJSX0dBTUVfTUVSR0VEX18nOnEoJ2Vycm9fZ2FtZV9tZXNjbGFkYScpLCdf
REM X0VSUk9SX1RBR19fJzpxKCdlcnJvX3RhZycpLCdfX1dBUk5JTkdfVEFHX18nOnEoJ2F2aXNv
REM X3RhZycpLCdfX1BSRVNTX18nOnEoJ3ByZXNzJyksJ19fVElUTEVfXyc6cSgndGl0dWxvJyks
REM CiAgICAgICAgJ19fU1RFUDFfXyc6cSgnZXRhcGFfYmFja3VwJyksJ19fRVJSX1JPVEFURV9f
REM JzpxKCdlcnJvX2JhY2t1cF9hbnRlcmlvcicpLCdfX0VSUl9CQUNLVVBfR0FNRV9fJzpxKCdl
REM cnJvX2JhY2t1cF9nYW1lJyksCiAgICAgICAgJ19fV0FSTl9HQU1FX01JU1NJTkdfXyc6cSgn
REM YXZpc29fZ2FtZV9hdXNlbnRlJyksJ19fU1RFUDJfXyc6cSgnZXRhcGFfdmFsaWRhcicpLCdf
REM X0VSUl9NRVJHRURfR09ORV9fJzpxKCdlcnJvX21lcmdlZF9nb25lJyksCiAgICAgICAgJ19f
REM U1RFUDNfXyc6cSgnZXRhcGFfYXBsaWNhcicpLCdfX0VSUl9BUFBMWV9fJzpxKCdlcnJvX2Fw
REM cGx5JyksJ19fU1RFUDRfXyc6cSgnZXRhcGFfZmluYWwnKSwKICAgICAgICAnX19TVUNDRVNT
REM X18nOnEoJ3N1Y2Vzc28nKSwnX19CQUNLVVBfR0FNRV9fJzpxKCdiYWNrdXBfZ2FtZScpLCdf
REM X0JBQ0tVUF9QUkVWSU9VU19fJzpxKCdiYWNrdXBfYW50ZXJpb3InKSwKICAgICAgICAnX19H
REM QU1FX0FQUExJRURfXyc6cSgnZ2FtZV9hcGxpY2FkYScpLCdfX1JFQ09NUElMRV9fJzpxKCdy
REM ZWNvbXBpbGEnKQogICAgfQogICAgZm9yIGEsYiBpbiByZXAuaXRlbXMoKTogdGVtcGxhdGU9
REM dGVtcGxhdGUucmVwbGFjZShhLGIpCiAgICB3aXRoIGlvLm9wZW4oaW5zdGFsbGVyLCd3Jyxl
REM bmNvZGluZz0ndXRmLTgnLG5ld2xpbmU9J1xyXG4nKSBhcyBmOiBmLndyaXRlKHRlbXBsYXRl
REM KQogICAgcmV0dXJuIGluc3RhbGxlcgoKZGVmIF9kdWFsX2NvbGxpc2lvbl9yZXBvcnRfcGF0
REM aF90ZW1wKCk6CiAgICBnbG9iYWwgX0RVQUxfQ09MTElTSU9OX1JFUE9SVF9ESVIKICAgIGlm
REM IF9EVUFMX0NPTExJU0lPTl9SRVBPUlRfRElSIGlzIE5vbmUgb3Igbm90IG9zLnBhdGguaXNk
REM aXIoX0RVQUxfQ09MTElTSU9OX1JFUE9SVF9ESVIpOgogICAgICAgIF9EVUFMX0NPTExJU0lP
REM Tl9SRVBPUlRfRElSID0gdGVtcGZpbGUubWtkdGVtcChwcmVmaXg9ImRkYWNfY29saXNhb19y
REM ZWxhdG9yaW9fIikKICAgIHJldHVybiBvcy5wYXRoLmpvaW4oX0RVQUxfQ09MTElTSU9OX1JF
REM UE9SVF9ESVIsIF9EVUFMX0NPTExJU0lPTl9SRVBPUlRfTkFNRSkKCgpkZWYgX2R1YWxfY29s
REM bGlzaW9uX3JlcG9ydF9oYXNfZmluZGluZ3MocmVwb3J0KToKICAgIGZvciBjaGF2ZSBpbiAo
REM InJlbW92aWRvc19nYW1lX3ZzX3JlbnB5X2NvbW1vbl9pZGVudGljb3MiLCAiY29uZmxpdG9z
REM X2dhbWVfdnNfcmVucHlfY29tbW9uX2RpZmVyZW50ZXMiLCAicHJlc2VydmFkb3NfcG9yX21h
REM cGFfYW50aWdvIiwgInJweWNfcGFyZWFkb3NfcmVwb3J0YWRvcyIpOgogICAgICAgIGlmIHJl
REM cG9ydC5nZXQoY2hhdmUpOgogICAgICAgICAgICByZXR1cm4gVHJ1ZQogICAgaWYgcmVwb3J0
REM LmdldCgicnB5Y19wYXJlYWRvc19uYW9fYXBhZ2Fkb3MiKSBpcyBub3QgVHJ1ZToKICAgICAg
REM ICByZXR1cm4gVHJ1ZQogICAgaWYgcmVwb3J0LmdldCgiaW5zdGFsYWNhb19maW5hbF9zdWJz
REM dGl0dWlfZ2FtZV9pbnRlaXJhbWVudGUiKSBpcyBub3QgVHJ1ZToKICAgICAgICByZXR1cm4g
REM VHJ1ZQogICAgcmV0dXJuIEZhbHNlCgoKZGVmIF9kdWFsX2ZpbmFsaXplX2NvbGxpc2lvbl9y
REM ZXBvcnQocmFpeiwgcmVwb3J0KToKICAgIGdsb2JhbCBfRFVBTF9DT0xMSVNJT05fUkVQT1JU
REM X0RJUgogICAgdGVtcF9wYXRoID0gX2R1YWxfY29sbGlzaW9uX3JlcG9ydF9wYXRoX3RlbXAo
REM KQogICAgd2l0aCBpby5vcGVuKHRlbXBfcGF0aCwidyIsZW5jb2Rpbmc9InV0Zi04IikgYXMg
REM ZjoKICAgICAgICBqc29uLmR1bXAocmVwb3J0LGYsZW5zdXJlX2FzY2lpPUZhbHNlLGluZGVu
REM dD0yKQogICAgZm9yIGxlZ2FkbyBpbiAoX0RVQUxfQ09MTElTSU9OX1JFUE9SVF9OQU1FLCBf
REM RFVBTF9DT0xMSVNJT05fUkVQT1JUX0xFR0FDWV9OQU1FKToKICAgICAgICBzdGFsZSA9IG9z
REM LnBhdGguam9pbihyYWl6LGxlZ2FkbykKICAgICAgICBpZiBvcy5wYXRoLmlzZmlsZShzdGFs
REM ZSk6CiAgICAgICAgICAgIHRyeTogb3MucmVtb3ZlKHN0YWxlKQogICAgICAgICAgICBleGNl
REM cHQgRXhjZXB0aW9uOiBwYXNzCiAgICBpZiBfZHVhbF9jb2xsaXNpb25fcmVwb3J0X2hhc19m
REM aW5kaW5ncyhyZXBvcnQpOgogICAgICAgIGZpbmFsX3BhdGggPSBvcy5wYXRoLmpvaW4ocmFp
REM eixfRFVBTF9DT0xMSVNJT05fUkVQT1JUX05BTUUpCiAgICAgICAgc2h1dGlsLmNvcHlmaWxl
REM KHRlbXBfcGF0aCwgZmluYWxfcGF0aCkKICAgICAgICB0cnk6IHNodXRpbC5ybXRyZWUoX0RV
REM QUxfQ09MTElTSU9OX1JFUE9SVF9ESVIsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgICAgICBl
REM eGNlcHQgRXhjZXB0aW9uOiBwYXNzCiAgICAgICAgX0RVQUxfQ09MTElTSU9OX1JFUE9SVF9E
REM SVIgPSBOb25lCiAgICAgICAgcmV0dXJuIGZpbmFsX3BhdGgKICAgIHRyeTogc2h1dGlsLnJt
REM dHJlZShfRFVBTF9DT0xMSVNJT05fUkVQT1JUX0RJUiwgaWdub3JlX2Vycm9ycz1UcnVlKQog
REM ICAgZXhjZXB0IEV4Y2VwdGlvbjogcGFzcwogICAgX0RVQUxfQ09MTElTSU9OX1JFUE9SVF9E
REM SVIgPSBOb25lCiAgICByZXR1cm4gTm9uZQoKCmRlZiBleGVjdXRhcl9yZWluamVjYW9fdjEw
REM MShyYWl6KToKICAgIHByaW50KGR0KCJyZWluamVjdF9zdGFnZSIpKQogICAgcmM9X1YxMDBf
REM RVhFQ1VUQVJfUkVJTkpFQ0FPKHJhaXopCiAgICBpZiByYyBub3QgaW4gKDAsTm9uZSk6IHJl
REM dHVybiByYwogICAgcGFzdGFfZ2FtZT1lbmNvbnRyYXJfcGFzdGFfZ2FtZShyYWl6KTsgbWVy
REM Z2VkPW9zLnBhdGguam9pbihyYWl6LFBBU1RBX1NBSURBX1RSQURVWklET19OT01FLG9zLnBh
REM dGguYmFzZW5hbWUob3MucGF0aC5ub3JtcGF0aChwYXN0YV9nYW1lKSkpCiAgICBwcmludChk
REM dCgib3V0cHV0X3N0YWdlIikpCiAgICBsb2c9TG9nKG9zLnBhdGguam9pbihyYWl6LE5PTUVf
REM TE9HX1JFSU5KRVRPUikpOyBtYXBhX3BhdGg9b3MucGF0aC5qb2luKHJhaXosUEFTVEFfRU5U
REM UkFEQV9OT01FLE5PTUVfTUFQQSk7IG1hcGFfYXR1YWw9e30KICAgIHRyeToKICAgICAgICBp
REM ZiBvcy5wYXRoLmlzZmlsZShtYXBhX3BhdGgpOgogICAgICAgICAgICB3aXRoIGlvLm9wZW4o
REM bWFwYV9wYXRoLCJyIixlbmNvZGluZz0idXRmLTgiKSBhcyBmOiBtYXBhX2F0dWFsPWpzb24u
REM bG9hZChmKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBtYXBhX2F0dWFsPXt9CiAg
REM ICBwcmludChkdCgiYXVkaXRfc3RhZ2UiKSwgZmx1c2g9VHJ1ZSkKICAgIHJlbW92ZWQsY29u
REM ZmxpY3RzLHByZXNlcnZlZD1fZHVhbF9jbGVhbl9ydW50aW1lX2R1cGxpY2F0ZXMocmFpeixt
REM ZXJnZWQsbG9nLG1hcGFfYXR1YWwpOyBwYWlyZWQ9X2R1YWxfY29tcGlsZV9jb2xsaXNpb25f
REM c2NhbihtZXJnZWQpCiAgICByZXBvcnQ9eyJyZW1vdmlkb3NfZ2FtZV92c19yZW5weV9jb21t
REM b25faWRlbnRpY29zIjpyZW1vdmVkLCJjb25mbGl0b3NfZ2FtZV92c19yZW5weV9jb21tb25f
REM ZGlmZXJlbnRlcyI6Y29uZmxpY3RzLCJwcmVzZXJ2YWRvc19wb3JfbWFwYV9hbnRpZ28iOnBy
REM ZXNlcnZlZCwicnB5Y19wYXJlYWRvc19yZXBvcnRhZG9zIjpwYWlyZWQsInJweWNfcGFyZWFk
REM b3NfbmFvX2FwYWdhZG9zIjpUcnVlLCJpbnN0YWxhY2FvX2ZpbmFsX3N1YnN0aXR1aV9nYW1l
REM X2ludGVpcmFtZW50ZSI6VHJ1ZSwiX3JvdHVsb3MiOkNPTElTQU9fUkVMQVRPUklPX1JPVFVM
REM T1MuZ2V0KElESU9NQSxDT0xJU0FPX1JFTEFUT1JJT19ST1RVTE9TWzFdKX0KICAgIHJlcG9y
REM dFsiX3JlbGF0b3JpbyJdPXsidMOtdHVsbyI6ZHQoInJlcG9ydF90aXRsZSIpLCJyZXN1bHRh
REM ZG8iOmR0KCJyZXBvcnRfaXNzdWUiKSBpZiBfZHVhbF9jb2xsaXNpb25fcmVwb3J0X2hhc19m
REM aW5kaW5ncyhyZXBvcnQpIGVsc2UgZHQoInJlcG9ydF9ub19pc3N1ZSIpLCJpZGlvbWEiOkNP
REM TElTQU9fUkVMQVRPUklPX1JPVFVMT1MuZ2V0KElESU9NQSxDT0xJU0FPX1JFTEFUT1JJT19S
REM T1RVTE9TWzFdKVsiaWRpb21hIl19CiAgICBjb2xsaXNpb25fcGF0aD1fZHVhbF9maW5hbGl6
REM ZV9jb2xsaXNpb25fcmVwb3J0KHJhaXoscmVwb3J0KQogICAgaW5zdGFsbGVyPV9kdWFsX3dy
REM aXRlX2luc3RhbGxlcihvcy5wYXRoLmRpcm5hbWUobWVyZ2VkKSk7IHByaW50KGR0KCJhdWRp
REM dF9zdW1tYXJ5IixsZW4ocmVtb3ZlZCksbGVuKGNvbmZsaWN0cyksbGVuKHByZXNlcnZlZCks
REM bGVuKHBhaXJlZCkpKTsgcHJpbnQoZHQoImluc3RhbGxlciIsIGluc3RhbGxlcikpOwogICAg
REM YW5leGFyX2xpbmhhc19sb2coTk9NRV9MT0dfUkVJTkpFVE9SLFt1Ij0iKjYwLGR0KCJhdWRp
REM dF9zdGFnZSIpLGR0KCJhdWRpdF9zdW1tYXJ5IixsZW4ocmVtb3ZlZCksbGVuKGNvbmZsaWN0
REM cyksbGVuKHByZXNlcnZlZCksbGVuKHBhaXJlZCkpLGR0KCJsYWJlbF9yZW1vdmVkIikrdSI6
REM ICIrc3RyKGxlbihyZW1vdmVkKSksZHQoImxhYmVsX2NvbmZsaWN0cyIpK3UiOiAiK3N0cihs
REM ZW4oY29uZmxpY3RzKSksZHQoImxhYmVsX3ByZXNlcnZlZCIpK3UiOiAiK3N0cihsZW4ocHJl
REM c2VydmVkKSldKQogICAgcmV0dXJuIDAKCgpfVjEwMF9FWEVDVVRBUl9UUkFEVUNBT19HT09H
REM TEU9ZXhlY3V0YXJfdHJhZHVjYW9fZ29vZ2xlCl9WMTAwX0VYRUNVVEFSX1JFSU5KRUNBTz1l
REM eGVjdXRhcl9yZWluamVjYW8KCiMgQ29tcGF0aWJpbGlkYWRlIGRlIHJvdGVhbWVudG86IE9w
REM w6fDo28gMiB1c2EgbyBtb3RvciBHb29nbGUgVHJhbnNsYXRlIFdlYiAoUlBDKSBWMTQxCiMg
REM ZGVmaW5pZGEgYWNpbWE7IE9ww6fDtWVzIDEgZSAzIGNvbnRpbnVhbSBhcG9udGFuZG8gcGFy
REM YSBvcyBwaXBlbGluZXMKIyBEdWFsQnJhaW4vUmVpbnRlZ3Jhw6fDo28gasOhIHZhbGlkYWRv
REM cy4KX1YxNDFfRVhFQ1VUQVJfVFJBRFVDQU9fR09PR0xFPWV4ZWN1dGFyX3RyYWR1Y2FvX2dv
REM b2dsZQpkZWYgZXhlY3V0YXJfZXh0cmFjYW8ocmFpeik6IHJldHVybiBleGVjdXRhcl9waXBl
REM bGluZV9kdWFsX3YxMTIocmFpeikKZGVmIGV4ZWN1dGFyX3RyYWR1Y2FvX2dvb2dsZShyYWl6
REM KTogcmV0dXJuIF9WMTQxX0VYRUNVVEFSX1RSQURVQ0FPX0dPT0dMRShyYWl6KQpkZWYgZXhl
REM Y3V0YXJfcmVpbmplY2FvKHJhaXopOiByZXR1cm4gZXhlY3V0YXJfcmVpbmplY2FvX3YxMDEo
REM cmFpeikKCgpkZWYgZXhlY3V0YXJfc2VsZnRlc3RfdjExOChyYWl6KToKICAgIGdsb2JhbCBJ
REM RElPTUEKICAgIGFzc2VydCBHT09HTEVfV09SS0VSUyA9PSA1CiAgICBfY3JlZGl0b190ZXN0
REM ZSA9IHUiU29uZyBDb3ZlcnM6XG5FbmQgb2YgU21hbGwgU2FuY3R1YXJ5IGJ5IEFraXJhIFlh
REM bWFva2EgYW5kIFRlYW0gU2lsZW50XG5CZSBRdWlldCBhbmQgRHJpdmUgKEFjb3VzdGljIHZl
REM ci4pIGJ5IERlZnRvbmVzXG4iCiAgICBhc3NlcnQgcGFyZWNlX2Jsb2NvX2NyZWRpdG9zX2dv
REM b2dsZShfY3JlZGl0b190ZXN0ZSwgdSJzY3JlZW5zLnJweSIsIHUidWkiKSBpcyBUcnVlCiAg
REM ICBhc3NlcnQgX3JvdHVsb19jcmVkaXRvX2VoX2NhdGVnb3JpYSh1IlNvbmcgQ292ZXJzIikg
REM aXMgVHJ1ZQogICAgYXNzZXJ0IF9yb3R1bG9fY3JlZGl0b19laF9jYXRlZ29yaWEodSJDYXN1
REM YWwgTW9uaWthIikgaXMgRmFsc2UKICAgIGFzc2VydCBlbnRyYWRhX25hb190cmFkdXppdmVs
REM X2dvb2dsZShfY3JlZGl0b190ZXN0ZSwgdSJzY3JlZW5zLnJweSIsIHUidWkiKSBpcyBGYWxz
REM ZQogICAgYXNzZXJ0IEdPT0dMRV9JTlRFUlZBTE9fTUlOSU1PID49IDAuMzAKICAgIGFzc2Vy
REM dCBHT09HTEVfUkVUUklFUyA+PSAyCiAgICBhc3NlcnQgR29vZ2xlUlBDQ2xpZW50IGlzIG5v
REM dCBHb29nbGVHVFhDbGllbnQKICAgIGFzc2VydCBHT09HTEVfU0NIRURVTEVSX0NIVU5LID09
REM IDUwCiAgICBhc3NlcnQgR09PR0xFX0NBQ0hFX1NDSEVNQSA9PSAxMwogICAgYXNzZXJ0IEdP
REM T0dMRV9DQUNIRV9NT1RPUl9JRCA9PSB1InJwYy12MSIKICAgIGFzc2VydCBHT09HTEVfQ0FD
REM SEVfQ1JFRElUT1NfTU9UT1JfSUQgPT0gdSJycGMtdjEtY3JlZGl0LXYyIgogICAgYXNzZXJ0
REM IHZhbGlkYXJfbXVsdGlsaW5ndWVfY29tcGxldG8oKSBpcyBUcnVlCiAgICBmb3IgX2lkaW9t
REM YV90ZXN0IGluICgxLDIsMyk6CiAgICAgICAgYXNzZXJ0IERVQUxfTUVOU0FHRU5TW19pZGlv
REM bWFfdGVzdF1bInRpdHVsbyJdCiAgICAgICAgYXNzZXJ0IENPTElTQU9fUkVMQVRPUklPX1JP
REM VFVMT1NbX2lkaW9tYV90ZXN0XVsiaWRpb21hIl0KICAgIGE9eyJhcnF1aXZvIjoieC5ycHki
REM LCJsaW5oYSI6MTAsImNvbHVuYV9pbmljaW8iOjAsImNvbHVuYV9maW0iOjUsIm9yaWdpbmFs
REM IjoiSGVsbG8iLCJ0aXBvIjoiZGlhbG9nbyIsIm1vdG9yIjoiRERBQyIsInByb3ZlbmllbmNp
REM YSI6WyJEREFDIl19CiAgICBiPWRpY3QoYSk7IGJbIm1vdG9yIl09IlJlblB5IjsgYlsicHJv
REM dmVuaWVuY2lhIl09WyJSZW5QeSJdCiAgICBjPWRpY3QoYSk7IGMudXBkYXRlKHsiY29sdW5h
REM X2luaWNpbyI6MSwiY29sdW5hX2ZpbSI6NCwib3JpZ2luYWwiOiJlbGwifSkKICAgIG1lcmdl
REM ZCxzdD1fZHVhbF9yZXNvbHZlX2V4YWN0X2R1cGxpY2F0ZXMoW2EsYl0pOyBhc3NlcnQgbGVu
REM KG1lcmdlZCk9PTEgYW5kIHN0WyJkdXBsaWNhdGFzIl09PTEKICAgIHJlc29sdmVkLGNvbmY9
REM X2R1YWxfcmVzb2x2ZV9vdmVybGFwcyhbYSxjXSk7IGFzc2VydCBsZW4ocmVzb2x2ZWQpPT0x
REM IGFuZCBjb25mCiAgICBjbXA9X2R1YWxfc3RhZ2U0X2NvbXBhcmUoW2FdLFtiXSk7IGFzc2Vy
REM dCBjbXBbImNvbmNvcmRhbmNpYXNfZXhhdGFzIl09PTEKICAgIHdpdGggdGVtcGZpbGUuVGVt
REM cG9yYXJ5RGlyZWN0b3J5KHByZWZpeD0iZGRhY192MTEyX3N0YWdlMl8iKSBhcyB0ZDoKICAg
REM ICAgICBnYW1lPW9zLnBhdGguam9pbih0ZCwiZ2FtZSIpOyBvcy5tYWtlZGlycyhnYW1lKQog
REM ICAgICAgIHdpdGggaW8ub3Blbihvcy5wYXRoLmpvaW4oZ2FtZSwieC5ycHkiKSwidyIsZW5j
REM b2Rpbmc9InV0Zi04IikgYXMgZjogZi53cml0ZSgibGFiZWwgc3RhcnQ6XG4gICAgXCJIZWxs
REM b1wiXG4iKQogICAgICAgIGFzc2VydCBvcy5wYXRoLmlzZGlyKGdhbWUpCiAgICAjIFJlZ3Jl
REM c3PDo28gVjE0MjogcHJlc2VydmFyIHBhbGF2cmFzIGVzdMOhdGljYXMgdmlzw612ZWlzIGVt
REM IGV4cHJlc3PDtWVzCiAgICAjIGRpbsOibWljYXMgZGUgYHRleHRidXR0b25gIHNlbSBleHRy
REM YWlyIG8gdmFsb3IgdmFyacOhdmVsIG5lbSBhw6fDtWVzLgogICAgd2l0aCB0ZW1wZmlsZS5U
REM ZW1wb3JhcnlEaXJlY3RvcnkocHJlZml4PSJkZGFjX3YxNDJfc2NyZWVuX2V4cHJfIikgYXMg
REM dGQ6CiAgICAgICAgZml4dHVyZT1vcy5wYXRoLmpvaW4odGQsInNjcmVlbl9leHByLnJweSIp
REM CiAgICAgICAgd2l0aCBpby5vcGVuKGZpeHR1cmUsInciLGVuY29kaW5nPSJ1dGYtOCIpIGFz
REM IGY6CiAgICAgICAgICAgIGYud3JpdGUoJ3NjcmVlbiB0ZXN0OlxuJwogICAgICAgICAgICAg
REM ICAgICAgICcgICAgdGV4dGJ1dHRvbiBpbmRlbnQqMisiLSAiKyJjYW1lcmEiIGFjdGlvbiBS
REM ZXR1cm4oKVxuJwogICAgICAgICAgICAgICAgICAgICcgICAgdGV4dGJ1dHRvbiBpbmRlbnQq
REM NCsiICB3aXRoIFt2YWx1ZVsxXV0iOlxuJwogICAgICAgICAgICAgICAgICAgICcgICAgICAg
REM IGFjdGlvbiBSZXR1cm4oKVxuJwogICAgICAgICAgICAgICAgICAgICcgICAgdGV4dGJ1dHRv
REM biAiW3ZhbHVlXSIgYWN0aW9uIFJldHVybigpXG4nCiAgICAgICAgICAgICAgICAgICAgJyAg
REM ICB0ZXh0YnV0dG9uIHRleHQgYWN0aW9uIFJldHVybigpXG4nKQogICAgICAgIF9maXh0dXJl
REM X3RleHRzLF9maXh0dXJlX21hcD1leHRyYWlyX2FycXVpdm9fY29tX21hcGEoZml4dHVyZSxz
REM ZXQoKSx7fSxzZXQoKSx7fSkKICAgICAgICBfZml4dHVyZV9saXRlcmFscz1bZS5nZXQoIm9y
REM aWdpbmFsIiwiIikgZm9yIGUgaW4gX2ZpeHR1cmVfbWFwXQogICAgICAgIGFzc2VydCAnImNh
REM bWVyYSInIGluIF9maXh0dXJlX2xpdGVyYWxzCiAgICAgICAgYXNzZXJ0ICciICB3aXRoIFt2
REM YWx1ZVsxXV0iJyBpbiBfZml4dHVyZV9saXRlcmFscwogICAgICAgIGFzc2VydCAnIlt2YWx1
REM ZV0iJyBub3QgaW4gX2ZpeHR1cmVfbGl0ZXJhbHMKICAgICAgICBhc3NlcnQgJyJSZXR1cm4o
REM KSInIG5vdCBpbiBfZml4dHVyZV9saXRlcmFscwogICAgX3JlcG9ydF90ZXN0PXsicmVtb3Zp
REM ZG9zX2dhbWVfdnNfcmVucHlfY29tbW9uX2lkZW50aWNvcyI6W10sImNvbmZsaXRvc19nYW1l
REM X3ZzX3JlbnB5X2NvbW1vbl9kaWZlcmVudGVzIjpbXSwicHJlc2VydmFkb3NfcG9yX21hcGFf
REM YW50aWdvIjpbXSwicnB5Y19wYXJlYWRvc19yZXBvcnRhZG9zIjpbXSwicnB5Y19wYXJlYWRv
REM c19uYW9fYXBhZ2Fkb3MiOlRydWUsImluc3RhbGFjYW9fZmluYWxfc3Vic3RpdHVpX2dhbWVf
REM aW50ZWlyYW1lbnRlIjpUcnVlfQogICAgYXNzZXJ0IF9kdWFsX2NvbGxpc2lvbl9yZXBvcnRf
REM aGFzX2ZpbmRpbmdzKF9yZXBvcnRfdGVzdCkgaXMgRmFsc2UKICAgIGFzc2VydCBfZHVhbF9j
REM b2xsaXNpb25fcmVwb3J0X2hhc19maW5kaW5ncyhkaWN0KF9yZXBvcnRfdGVzdCwgcnB5Y19w
REM YXJlYWRvc19uYW9fYXBhZ2Fkb3M9RmFsc2UpKSBpcyBUcnVlCiAgICBhc3NlcnQgX0RVQUxf
REM SU5TVEFMTEVSX05BTUU9PSJEREFDLUFQTElDQVItTUVTQ0xBR0VNLmJhdCIKICAgIGFzc2Vy
REM dCBleGVjdXRhcl9leHRyYWNhby5fX25hbWVfXyA9PSAiZXhlY3V0YXJfZXh0cmFjYW8iCiAg
REM ICBhc3NlcnQgZXhlY3V0YXJfZXh0cmFjYW8gaXMgbm90IGV4ZWN1dGFyX2V4dHJhY2FvLl9f
REM Z2xvYmFsc19fLmdldCgiX1YxMDBfRVhFQ1VUQVJfUkVJTkpFQ0FPIikKICAgIF90ZXN0X3Rt
REM cD10ZW1wZmlsZS5ta2R0ZW1wKHByZWZpeD0iZGRhY192MTE1X2luc3RhbGxlcl8iKQogICAg
REM dHJ5OgogICAgICAgIF9pbnN0PV9kdWFsX3dyaXRlX2luc3RhbGxlcihfdGVzdF90bXApCiAg
REM ICAgICAgX3R4dD1pby5vcGVuKF9pbnN0LCJyIixlbmNvZGluZz0idXRmLTgiKS5yZWFkKCkK
REM ICAgICAgICBhc3NlcnQgJ3NldCAiRERBQ19CQUNLVVBfUk9PVD0lUk9PVCVcXEREQUMtQmFj
REM a3VwIicgaW4gX3R4dAogICAgICAgIGFzc2VydCAnc2V0ICJEREFDX0dBTUVfQkFDS1VQPSVE
REM REFDX0JBQ0tVUF9ST09UJVxcZ2FtZSInIGluIF90eHQKICAgICAgICBhc3NlcnQgIkREQUMg
REM QmFja3VwIiBub3QgaW4gX3R4dAogICAgICAgIGFzc2VydCAiL1hGICoucnB5YyAqLnJweW1j
REM IiBpbiBfdHh0CiAgICAgICAgYXNzZXJ0ICJEREFDIEJhY2t1cCIgbm90IGluIF90eHQKICAg
REM ICAgICBhc3NlcnQgInJlbnB5XFxjb21tb24iIG5vdCBpbiBfdHh0Lmxvd2VyKCkKICAgIGZp
REM bmFsbHk6CiAgICAgICAgc2h1dGlsLnJtdHJlZShfdGVzdF90bXAsaWdub3JlX2Vycm9ycz1U
REM cnVlKQogICAgd2l0aCB0ZW1wZmlsZS5UZW1wb3JhcnlEaXJlY3RvcnkocHJlZml4PSJkZGFj
REM X3YxMTdfY29sbGlzaW9uXyIpIGFzIHRkYzoKICAgICAgICBnbG9iYWwgX0RVQUxfQ09MTElT
REM SU9OX1JFUE9SVF9ESVIKICAgICAgICBlbXB0eT17InJlbW92aWRvc19nYW1lX3ZzX3JlbnB5
REM X2NvbW1vbl9pZGVudGljb3MiOltdLCJjb25mbGl0b3NfZ2FtZV92c19yZW5weV9jb21tb25f
REM ZGlmZXJlbnRlcyI6W10sInByZXNlcnZhZG9zX3Bvcl9tYXBhX2FudGlnbyI6W10sInJweWNf
REM cGFyZWFkb3NfcmVwb3J0YWRvcyI6W10sInJweWNfcGFyZWFkb3NfbmFvX2FwYWdhZG9zIjpU
REM cnVlLCJpbnN0YWxhY2FvX2ZpbmFsX3N1YnN0aXR1aV9nYW1lX2ludGVpcmFtZW50ZSI6VHJ1
REM ZSwiX3JvdHVsb3MiOkNPTElTQU9fUkVMQVRPUklPX1JPVFVMT1NbMV0sIl9yZWxhdG9yaW8i
REM OnsidMOtdHVsbyI6ZHQoInJlcG9ydF90aXRsZSIpLCJyZXN1bHRhZG8iOmR0KCJyZXBvcnRf
REM bm9faXNzdWUiKSwiaWRpb21hIjoiUG9ydHVndcOqcyJ9fQogICAgICAgIGFzc2VydCBfZHVh
REM bF9maW5hbGl6ZV9jb2xsaXNpb25fcmVwb3J0KHRkYywgZW1wdHkpIGlzIE5vbmUKICAgICAg
REM ICBhc3NlcnQgbm90IG9zLnBhdGguZXhpc3RzKG9zLnBhdGguam9pbih0ZGMsX0RVQUxfQ09M
REM TElTSU9OX1JFUE9SVF9OQU1FKSkKICAgICAgICBmaW5kaW5nPWRpY3QoZW1wdHkpOyBmaW5k
REM aW5nWyJjb25mbGl0b3NfZ2FtZV92c19yZW5weV9jb21tb25fZGlmZXJlbnRlcyJdPVt7ImFy
REM cXVpdm8iOiJ4LnJweSJ9XQogICAgICAgIG91dHA9X2R1YWxfZmluYWxpemVfY29sbGlzaW9u
REM X3JlcG9ydCh0ZGMsZmluZGluZykKICAgICAgICBhc3NlcnQgb3V0cCBhbmQgb3MucGF0aC5p
REM c2ZpbGUob3V0cCkKICAgICAgICB3aXRoIGlvLm9wZW4ob3V0cCwiciIsZW5jb2Rpbmc9InV0
REM Zi04IikgYXMgZjogX2NyPWpzb24ubG9hZChmKQogICAgICAgIGFzc2VydCBfY3JbImNvbmZs
REM aXRvc19nYW1lX3ZzX3JlbnB5X2NvbW1vbl9kaWZlcmVudGVzIl0KICAgICAgICBfbG9ncD1v
REM cy5wYXRoLmpvaW4odGRjLCJyZWluai50eHQiKQogICAgICAgIHdpdGggaW8ub3BlbihfbG9n
REM cCwidyIsZW5jb2Rpbmc9InV0Zi04IikgYXMgZjogZi53cml0ZSh1ImJhc2VcbiIpCiAgICAg
REM ICAgYW5leGFyX2xpbmhhc19sb2coX2xvZ3AsW3UiYXVkaXRvcmlhIix1IkNvbmZsaXRvczog
REM MCJdKQogICAgICAgIGFzc2VydCBpby5vcGVuKF9sb2dwLCJyIixlbmNvZGluZz0idXRmLTgi
REM KS5yZWFkKCkuc3BsaXRsaW5lcygpWy0yOl0gPT0gW3UiYXVkaXRvcmlhIix1IkNvbmZsaXRv
REM czogMCJdCiAgICAgICAgc2h1dGlsLnJtdHJlZShvcy5wYXRoLmRpcm5hbWUob3V0cCksaWdu
REM b3JlX2Vycm9ycz1UcnVlKQogICAgd2l0aCB0ZW1wZmlsZS5UZW1wb3JhcnlEaXJlY3Rvcnko
REM cHJlZml4PSJkZGFjX3YxMTJfcnB5Y18iKSBhcyB0ZGM6CiAgICAgICAgZ2M9b3MucGF0aC5q
REM b2luKHRkYywiZ2FtZSIpOyBvcy5tYWtlZGlycyhnYykKICAgICAgICB3aXRoIGlvLm9wZW4o
REM b3MucGF0aC5qb2luKGdjLCJzYW1wbGUucnB5IiksInciLGVuY29kaW5nPSJ1dGYtOCIpIGFz
REM IGY6IGYud3JpdGUoJ2xhYmVsIHN0YXJ0OlxuICAgICJPbMOhIlxuJykKICAgICAgICB3aXRo
REM IGlvLm9wZW4ob3MucGF0aC5qb2luKGdjLCJzYW1wbGUucnB5YyIpLCJ3YiIpIGFzIGY6IGYu
REM d3JpdGUoYiJjb21waWxlZCIpCiAgICAgICAgcmVtb3ZpZG9zPWxpbXBhcl9jb21waWxhZG9z
REM X3NvbWJyZWFkb3MoZ2MpCiAgICAgICAgYXNzZXJ0ICJzYW1wbGUucnB5YyIgaW4gcmVtb3Zp
REM ZG9zIGFuZCBub3Qgb3MucGF0aC5leGlzdHMob3MucGF0aC5qb2luKGdjLCJzYW1wbGUucnB5
REM YyIpKQogICAgICAgICMgQSB2YWxpZGHDp8OjbyBkZXZlIGFjZWl0YXIgc29tZW50ZSBvcyBj
REM b21waWxhZG9zIGV4cGxpY2l0YW1lbnRlIGludmFsaWRhZG9zLgogICAgICAgIG91dGM9b3Mu
REM cGF0aC5qb2luKHRkYywib3V0Iik7IHNodXRpbC5jb3B5dHJlZShnYyxvdXRjKQogICAgICAg
REM IG1hcGFfYz17ICJzYW1wbGUucnB5IjogW3sibGluaGEiOjIsImNvbHVuYV9pbmljaW8iOjQs
REM ImNvbHVuYV9maW0iOjEwLCJvcmlnaW5hbCI6IlwiT2zDoVwiIn1dIH0KICAgICAgICB3aXRo
REM IGlvLm9wZW4ob3MucGF0aC5qb2luKHRkYywibWFwYS5qc29uIiksInciLGVuY29kaW5nPSJ1
REM dGYtOCIpIGFzIGY6IGpzb24uZHVtcChtYXBhX2MsZikKICAgICMgUmVncmVzc8OjbyBnbG9i
REM YWw6IHN0cmluZ3MgZml4YXMgZW0gaW50ZXJmYWNlIGNvbnN0cnXDrWRhIGRpbmFtaWNhbWVu
REM dGUuCiAgICB3aXRoIHRlbXBmaWxlLlRlbXBvcmFyeURpcmVjdG9yeShwcmVmaXg9ImRkYWNf
REM djE0M191aV9keW5hbWljXyIpIGFzIHRkOgogICAgICAgIGdjPW9zLnBhdGguam9pbih0ZCwi
REM Z2FtZSIpOyBvcy5tYWtlZGlycyhnYykKICAgICAgICBzYW1wbGU9b3MucGF0aC5qb2luKGdj
REM LCJzYW1wbGUucnB5IikKICAgICAgICB3aXRoIGlvLm9wZW4oc2FtcGxlLCJ3IixlbmNvZGlu
REM Zz0idXRmLTgiKSBhcyBmOgogICAgICAgICAgICBmLndyaXRlKCcnJ2luaXQgcHl0aG9uOlxu
REM ICAgIHByb3BzX3NldHMgPSAoXG4gICAgICAgICgiQ2hpbGQvUG9zIiwgKCJjaGlsZCIsICJ4
REM cG9zIikpLFxuICAgIClcbiAgICByZW5weS5ub3RpZnkoXyh2YWx1ZSArICIgaXMgbm90IGNh
REM bGxhYmxlLiIpKVxuICAgIGJ1dHRvbl9saXN0LmFwcGVuZCgoKCJlZGl0IGNoaWxkOiB7fSIu
REM Zm9ybWF0KHZbMF0pKSwgYWN0aW9uKSlcbicnJykKICAgICAgICBfZHluYW1pY190ZXh0cywg
REM X2R5bmFtaWNfbWFwID0gZXh0cmFpcl9hcnF1aXZvX2NvbV9tYXBhKHNhbXBsZSwgc2V0KCks
REM IHt9LCB7fSwge30pCiAgICAgICAgX2R5bmFtaWNfdmFsdWVzID0gW2l0ZW1bMV0gZm9yIGl0
REM ZW0gaW4gX2R5bmFtaWNfdGV4dHNdCiAgICAgICAgYXNzZXJ0IGFueSgnZWRpdCBjaGlsZCcg
REM aW4gdmFsdWUgZm9yIHZhbHVlIGluIF9keW5hbWljX3ZhbHVlcyksICd0ZW1wbGF0ZSBkZSBi
REM b3TDo28gZGluw6JtaWNvIG7Do28gZGV0ZWN0YWRvJwogICAgICAgIGFzc2VydCBhbnkoJ2lz
REM IG5vdCBjYWxsYWJsZScgaW4gdmFsdWUgZm9yIHZhbHVlIGluIF9keW5hbWljX3ZhbHVlcyks
REM ICdmcmFnbWVudG8gZGUgbm90aWZpY2HDp8OjbyBuw6NvIGRldGVjdGFkbycKICAgICAgICBh
REM c3NlcnQgYW55KCdDaGlsZC9Qb3MnIGluIHZhbHVlIGZvciB2YWx1ZSBpbiBfZHluYW1pY192
REM YWx1ZXMpLCAncsOzdHVsbyBkZSBncnVwbyBkYSBpbnRlcmZhY2UgbsOjbyBkZXRlY3RhZG8n
REM CiAgICAjIFJlZ3Jlc3PDo28gVjE0NTogdGV4dG9zIGNvbXVucyBkZSBVSSBlIGRpw6Fsb2dv
REM IHByZXNlcnZhZG9zIHNlbSBleHRyYWlyIGHDp8O1ZXMvY8OzZGlnby4KICAgIHdpdGggdGVt
REM cGZpbGUuVGVtcG9yYXJ5RGlyZWN0b3J5KHByZWZpeD0iZGRhY192MTQ1X3VpX2NvdmVyYWdl
REM XyIpIGFzIHRkOgogICAgICAgIGZpeHR1cmU9b3MucGF0aC5qb2luKHRkLCJ1aS5ycHkiKQog
REM ICAgICAgIHdpdGggaW8ub3BlbihmaXh0dXJlLCJ3IixlbmNvZGluZz0idXRmLTgiKSBhcyBm
REM OgogICAgICAgICAgICBmLndyaXRlKCdsYWJlbCBzdGFydDpcbicKICAgICAgICAgICAgICAg
REM ICAgICAnICAgICJIZWxsbywgW3BsYXllcl9uYW1lXSEiXG4nCiAgICAgICAgICAgICAgICAg
REM ICAgJyAgICBtZW51OlxuJwogICAgICAgICAgICAgICAgICAgICcgICAgICAgICJDb250aW51
REM ZSI6XG4nCiAgICAgICAgICAgICAgICAgICAgJyAgICAgICAgICAgIHBhc3NcbicKICAgICAg
REM ICAgICAgICAgICAgICAnc2NyZWVuIHRlc3RfbWVudTpcbicKICAgICAgICAgICAgICAgICAg
REM ICAnICAgIHRleHRidXR0b24gIlNhdmUiIGFjdGlvbiBSZXR1cm4oKVxuJwogICAgICAgICAg
REM ICAgICAgICAgICcgICAgdGV4dGJ1dHRvbiAiU2V0dGluZ3MiIGFjdGlvbiBTaG93TWVudSgi
REM cHJlZmVyZW5jZXMiKVxuJwogICAgICAgICAgICAgICAgICAgICcgICAgdGV4dGJ1dHRvbiBk
REM eW5hbWljX2xhYmVsIGFjdGlvbiBSZXR1cm4oKVxuJykKICAgICAgICBfdWlfdGV4dHMsX3Vp
REM X21hcD1leHRyYWlyX2FycXVpdm9fY29tX21hcGEoZml4dHVyZSxzZXQoKSx7fSxzZXQoKSx7
REM fSkKICAgICAgICBfdWlfbGl0ZXJhbHM9W2UuZ2V0KCJvcmlnaW5hbCIsIiIpIGZvciBlIGlu
REM IF91aV9tYXBdCiAgICAgICAgYXNzZXJ0ICciSGVsbG8sIFtwbGF5ZXJfbmFtZV0hIicgaW4g
REM X3VpX2xpdGVyYWxzCiAgICAgICAgYXNzZXJ0ICciQ29udGludWUiJyBpbiBfdWlfbGl0ZXJh
REM bHMKICAgICAgICBhc3NlcnQgJyJTYXZlIicgaW4gX3VpX2xpdGVyYWxzCiAgICAgICAgYXNz
REM ZXJ0ICciU2V0dGluZ3MiJyBpbiBfdWlfbGl0ZXJhbHMKICAgICAgICBhc3NlcnQgJyJSZXR1
REM cm4oKSInIG5vdCBpbiBfdWlfbGl0ZXJhbHMKICAgICAgICBhc3NlcnQgJyJwcmVmZXJlbmNl
REM cyInIG5vdCBpbiBfdWlfbGl0ZXJhbHMKICAgICAgICBhc3NlcnQgJyJkeW5hbWljX2xhYmVs
REM Iicgbm90IGluIF91aV9saXRlcmFscwogICAgIyBSZWdyZXNzw6NvIFYxNDU6IGZhbGhhIGRv
REM IG9yw6FjdWxvIG7Do28gYmxvcXVlaWEgYSBleHRyYcOnw6NvIGUgZGVpeGEgcmVsYXTDs3Jp
REM byByYXN0cmXDoXZlbC4KICAgIHdpdGggdGVtcGZpbGUuVGVtcG9yYXJ5RGlyZWN0b3J5KHBy
REM ZWZpeD0iZGRhY192MTQ1X29yYWNsZV9mYWxsYmFja18iKSBhcyB0ZDoKICAgICAgICBnYW1l
REM PW9zLnBhdGguam9pbih0ZCwiZ2FtZSIpOyBvcy5tYWtlZGlycyhnYW1lKQogICAgICAgIHdp
REM dGggaW8ub3Blbihvcy5wYXRoLmpvaW4oZ2FtZSwic2NyaXB0LnJweSIpLCJ3IixlbmNvZGlu
REM Zz0idXRmLTgiKSBhcyBmOgogICAgICAgICAgICBmLndyaXRlKCdsYWJlbCBzdGFydDpcbiAg
REM ICAiRmFsbGJhY2sgZGlhbG9ndWUiXG5zY3JlZW4gdGVzdDpcbiAgICB0ZXh0YnV0dG9uICJF
REM eGl0IiBhY3Rpb24gUmV0dXJuKClcbicpCiAgICAgICAgX29yaWdfc3RhZ2UzPWdsb2JhbHMo
REM KS5nZXQoIl9kdWFsX3N0YWdlM19yZW5weSIpCiAgICAgICAgX29yaWdfbGFuZ3VhZ2U9SURJ
REM T01BCiAgICAgICAgZGVmIF9mb3JjZV9vcmFjbGVfdW5hdmFpbGFibGUoX2dhbWUsX2NhbmRp
REM ZGF0ZXMsX2xvZyk6CiAgICAgICAgICAgIGZvciBfayBpbiBPUkFDVUxPX1JFTlBZOgogICAg
REM ICAgICAgICAgICAgaWYgaXNpbnN0YW5jZShPUkFDVUxPX1JFTlBZW19rXSxsaXN0KTogT1JB
REM Q1VMT19SRU5QWVtfa109W10KICAgICAgICAgICAgICAgIGVsaWYgaXNpbnN0YW5jZShPUkFD
REM VUxPX1JFTlBZW19rXSxkaWN0KTogT1JBQ1VMT19SRU5QWVtfa109e30KICAgICAgICAgICAg
REM ICAgIGVsaWYgaXNpbnN0YW5jZShPUkFDVUxPX1JFTlBZW19rXSxib29sKTogT1JBQ1VMT19S
REM RU5QWVtfa109RmFsc2UKICAgICAgICAgICAgICAgIGVsaWYgaXNpbnN0YW5jZShPUkFDVUxP
REM X1JFTlBZW19rXSxpbnQpOiBPUkFDVUxPX1JFTlBZW19rXT0wCiAgICAgICAgICAgICAgICBl
REM bHNlOiBPUkFDVUxPX1JFTlBZW19rXT11IiIKICAgICAgICAgICAgT1JBQ1VMT19SRU5QWVsi
REM ZmFsaGFzIl09W3UiZmFsaGEgc2ltdWxhZGEgZGUgdGVzdGUiXQogICAgICAgICAgICByZXR1
REM cm4gW10KICAgICAgICB0cnk6CiAgICAgICAgICAgIGdsb2JhbHMoKVsiX2R1YWxfc3RhZ2Uz
REM X3JlbnB5Il09X2ZvcmNlX29yYWNsZV91bmF2YWlsYWJsZQogICAgICAgICAgICBfZmFsbGJh
REM Y2tfcmM9ZXhlY3V0YXJfcGlwZWxpbmVfZHVhbF92MTEyKHRkKQogICAgICAgICAgICBhc3Nl
REM cnQgX2ZhbGxiYWNrX3JjPT0wLCAiZmFsbGJhY2sgZGV2ZSBjb21wbGV0YXIgc2VtIG9yw6Fj
REM dWxvIgogICAgICAgICAgICBfZmFsbGJhY2tfcmVwb3J0X3BhdGg9b3MucGF0aC5qb2luKHRk
REM LF9EVUFMX1JFUE9SVF9OQU1FKQogICAgICAgICAgICBhc3NlcnQgb3MucGF0aC5pc2ZpbGUo
REM X2ZhbGxiYWNrX3JlcG9ydF9wYXRoKSwgInJlbGF0w7NyaW8gZGV2ZSBwZXJzaXN0aXIgbmEg
REM cmFpeiIKICAgICAgICAgICAgd2l0aCBpby5vcGVuKF9mYWxsYmFja19yZXBvcnRfcGF0aCwi
REM ciIsZW5jb2Rpbmc9InV0Zi04IikgYXMgZjogX2ZhbGxiYWNrX3JlcG9ydD1qc29uLmxvYWQo
REM ZikKICAgICAgICAgICAgYXNzZXJ0IF9mYWxsYmFja19yZXBvcnQuZ2V0KCJ0ZXJtaW5hbF9z
REM dGF0dXMiKT09IkVYVFJBQ0FPX0NPTkNMVUlEQV9TRU1fVkFMSURBQ0FPIgogICAgICAgICAg
REM ICBhc3NlcnQgX2ZhbGxiYWNrX3JlcG9ydC5nZXQoIm9yYWN1bG9fcmVucHlfYXRpdm8iKSBp
REM cyBGYWxzZQogICAgICAgICAgICBhc3NlcnQgX2ZhbGxiYWNrX3JlcG9ydC5nZXQoIm1vdG9y
REM X2ZhbGxiYWNrX2RkYWMiKSBpcyBUcnVlCiAgICAgICAgICAgIF9mYWxsYmFja19tYXBfcGF0
REM aD1vcy5wYXRoLmpvaW4odGQsUEFTVEFfRU5UUkFEQV9OT01FLE5PTUVfTUFQQSkKICAgICAg
REM ICAgICAgYXNzZXJ0IG9zLnBhdGguaXNmaWxlKF9mYWxsYmFja19tYXBfcGF0aCksICJtYXBh
REM IGRldmUgc2VyIGNyaWFkbyBwZWxvIGZhbGxiYWNrIgogICAgICAgICAgICB3aXRoIGlvLm9w
REM ZW4oX2ZhbGxiYWNrX21hcF9wYXRoLCJyIixlbmNvZGluZz0idXRmLTgiKSBhcyBmOiBfZmFs
REM bGJhY2tfbWFwPWpzb24ubG9hZChmKQogICAgICAgICAgICBhc3NlcnQgX2ZhbGxiYWNrX21h
REM cCwgImZhbGxiYWNrIGRldmUgcHJvZHV6aXIgZW50cmFkYXMgY2Fuw7RuaWNhcyIKICAgICAg
REM ICBmaW5hbGx5OgogICAgICAgICAgICBnbG9iYWxzKClbIl9kdWFsX3N0YWdlM19yZW5weSJd
REM PV9vcmlnX3N0YWdlMwogICAgICAgICAgICBJRElPTUE9X29yaWdfbGFuZ3VhZ2UKICAgICMg
REM UmVncmVzc8OjbyBWMTQ1OiBhdXPDqm5jaWEgZGUgZm9udGVzIG7Do28gcG9kZSByZXN1bHRh
REM ciBlbSBtYXBhIHZhemlvIG5lbSBtb3ZlciBhIHNhw61kYSBhbnRlcmlvci4KICAgIHdpdGgg
REM dGVtcGZpbGUuVGVtcG9yYXJ5RGlyZWN0b3J5KHByZWZpeD0iZGRhY192MTQ1X25vX3NvdXJj
REM ZXNfIikgYXMgdGQ6CiAgICAgICAgZ2FtZT1vcy5wYXRoLmpvaW4odGQsImdhbWUiKTsgb3Mu
REM bWFrZWRpcnMoZ2FtZSkKICAgICAgICB3aXRoIGlvLm9wZW4ob3MucGF0aC5qb2luKGdhbWUs
REM InNjcmlwdHMucnBhIiksIndiIikgYXMgZjogZi53cml0ZShiIlJQQS0zLjAgdGVzdCIpCiAg
REM ICAgICAgb3V0ZGlyPW9zLnBhdGguam9pbih0ZCxQQVNUQV9FTlRSQURBX05PTUUpOyBvcy5t
REM YWtlZGlycyhvdXRkaXIpCiAgICAgICAgc2VudGluZWw9b3MucGF0aC5qb2luKG91dGRpciwi
REM bmFvX2FwYWdhci50eHQiKQogICAgICAgIHdpdGggaW8ub3BlbihzZW50aW5lbCwidyIsZW5j
REM b2Rpbmc9InV0Zi04IikgYXMgZjogZi53cml0ZSh1ImV4dHJhw6fDo28gYW50ZXJpb3IiKQog
REM ICAgICAgIHJjX3NlbV9mb250ZT1leGVjdXRhcl9waXBlbGluZV9kdWFsX3YxMTIodGQpCiAg
REM ICAgICAgYXNzZXJ0IHJjX3NlbV9mb250ZSAhPSAwLCAic2VtIGZvbnRlcyBvIHBpcGVsaW5l
REM IGRldmUgZmFsaGFyIGV4cGxpY2l0YW1lbnRlIgogICAgICAgIGFzc2VydCBvcy5wYXRoLmlz
REM ZmlsZShzZW50aW5lbCksICJhIGV4dHJhw6fDo28gYW50ZXJpb3IgbsOjbyBkZXZlIHNlciBt
REM b3ZpZGEvc3Vic3RpdHXDrWRhIgogICAgICAgIHNlbWZvbnRlX3JlcG9ydD1vcy5wYXRoLmpv
REM aW4odGQsX0RVQUxfUkVQT1JUX05BTUUpCiAgICAgICAgd2l0aCBpby5vcGVuKHNlbWZvbnRl
REM X3JlcG9ydCwiciIsZW5jb2Rpbmc9InV0Zi04IikgYXMgZjogcnI9anNvbi5sb2FkKGYpCiAg
REM ICAgICAgYXNzZXJ0IHJyLmdldCgidGVybWluYWxfc3RhdHVzIik9PSJTRU1fRk9OVEVTX0RF
REM X1NDUklQVCIKICAgICAgICBhc3NlcnQgbm90IG9zLnBhdGguaXNmaWxlKG9zLnBhdGguam9p
REM bihvdXRkaXIsTk9NRV9NQVBBKSksICJuw6NvIGNyaWFyIG1hcGEgdmF6aW8iCiAgICBwcmlu
REM dCh1IlNFTEZURVNUIFYxNDU6IE9LIHwgVUkvZGlhbG9nbywgY8OzZGlnbyBwcm90ZWdpZG8s
REM IGZhbGxiYWNrIGRvIG9yw6FjdWxvLCByZWxhdMOzcmlvIHBlcnNpc3RlbnRlIGUgc2VtLWZv
REM bnRlIikKICAgIHJldHVybiAwCgoKZGVmIG1haW4oKToKICAgIGdsb2JhbCBJRElPTUEsIE5P
REM TUVfTE9HX0VYVFJBVE9SLCBOT01FX0xPR19SRUlOSkVUT1IsIE5PTUVfTE9HX1RSQURVVE9S
REM LCBOT01FX01BUEEKICAgIG1vZG8gPSBzeXMuYXJndlsxXSBpZiBsZW4oc3lzLmFyZ3YpID4g
REM MSBlbHNlICIiCiAgICByYWl6ID0gc3lzLmFyZ3ZbMl0gaWYgbGVuKHN5cy5hcmd2KSA+IDIg
REM ZWxzZSBvcy5nZXRjd2QoKQoKICAgIHRyeToKICAgICAgICBlc2NvbGhpZG8gPSBpbnQoc3lz
REM LmFyZ3ZbM10pIGlmIGxlbihzeXMuYXJndikgPiAzIGVsc2UgMQogICAgZXhjZXB0IFZhbHVl
REM RXJyb3I6CiAgICAgICAgZXNjb2xoaWRvID0gMQogICAgSURJT01BID0gZXNjb2xoaWRvIGlm
REM IGVzY29saGlkbyBpbiBNRU5TQUdFTlMgZWxzZSAxCiAgICBNT0RPX0VYSUJJQ0FPID0gdSJy
REM ZXN1bWlkbyIKICAgIE5PTUVfTE9HX0VYVFJBVE9SID0gTk9NRVNfTE9HX0VYVFJBQ0FPX0lE
REM SU9NQS5nZXQoSURJT01BLCBOT01FU19MT0dfRVhUUkFDQU9fSURJT01BWzFdKQogICAgTk9N
REM RV9MT0dfUkVJTkpFVE9SID0gTk9NRVNfTE9HX1JFSU5URUdSQUNBT19JRElPTUEuZ2V0KElE
REM SU9NQSwgTk9NRVNfTE9HX1JFSU5URUdSQUNBT19JRElPTUFbMV0pCiAgICBOT01FX0xPR19U
REM UkFEVVRPUiA9IE5PTUVTX0xPR19UUkFEVUNBT19JRElPTUEuZ2V0KElESU9NQSwgTk9NRVNf
REM TE9HX1RSQURVQ0FPX0lESU9NQVsxXSkKICAgIGF0dWFsaXphcl9ub21lc19wYXN0YXNfcG9y
REM X2lkaW9tYSgpCgogICAgaWYgbW9kbyBpbiAoInNlbGZ0ZXN0X3YxMDEiLCAic2VsZnRlc3Rf
REM djEwMiIsICJzZWxmdGVzdF92MTAzIiwgInNlbGZ0ZXN0X3YxMDQiLCAic2VsZnRlc3RfdjEw
REM NSIsICJzZWxmdGVzdF92MTA2IiwgInNlbGZ0ZXN0X3YxMDciLCAic2VsZnRlc3RfdjEwOCIs
REM ICJzZWxmdGVzdF92MTA5IiwgInNlbGZ0ZXN0X3YxMTIiLCAic2VsZnRlc3RfdjExMyIsICJz
REM ZWxmdGVzdF92MTE2IiwgInNlbGZ0ZXN0X3YxMTciLCAic2VsZnRlc3RfdjExOCIsICJzZWxm
REM dGVzdF92MTQzIiwgInNlbGZ0ZXN0X3YxNDUiKToKICAgICAgICByZXR1cm4gZXhlY3V0YXJf
REM c2VsZnRlc3RfdjExOChyYWl6KQogICAgaWYgbW9kbyA9PSAiZGV0ZWN0YXJfc2RrIjoKICAg
REM ICAgICByZXR1cm4gZXhlY3V0YXJfZGV0ZWNjYW9fc2RrKHJhaXopCiAgICBpZiBtb2RvID09
REM ICJwcmVmbGlnaHRfdG9rZW5zIjoKICAgICAgICByZXR1cm4gZXhlY3V0YXJfdGVzdGVfaW50
REM ZWdyaWRhZGVfdG9rZW5zKCkKICAgIGlmIG1vZG8gPT0gInByZWZsaWdodF9zaW50YXhlIjoK
REM ICAgICAgICByZXR1cm4gZXhlY3V0YXJfdGVzdGVfY29iZXJ0dXJhX3NpbnRheGVfcmVucHko
REM KQoKICAgIGlmIG1vZG8gPT0gInByZWZsaWdodCI6CiAgICAgICAgZXRhcGEgPSBzeXMuYXJn
REM dls0XS5zdHJpcCgpLmxvd2VyKCkgaWYgbGVuKHN5cy5hcmd2KSA+IDQgZWxzZSAiZXh0cmFp
REM ciIKICAgICAgICByZXR1cm4gZXhlY3V0YXJfcHJlZmxpZ2h0KHJhaXosIGV0YXBhKQogICAg
REM ZWxpZiBtb2RvID09ICJleHRyYWlyIjoKICAgICAgICByZXRvcm5vID0gZXhlY3V0YXJfZXh0
REM cmFjYW8ocmFpeikKICAgICAgICByZXR1cm4gcmV0b3JubyBpZiByZXRvcm5vIGlzIG5vdCBO
REM b25lIGVsc2UgMAogICAgZWxpZiBtb2RvID09ICJ0cmFkdXppciI6CiAgICAgICAgcmV0dXJu
REM IGV4ZWN1dGFyX3RyYWR1Y2FvX2dvb2dsZShyYWl6KQogICAgZWxpZiBtb2RvID09ICJkaWFn
REM bm9zdGljb19nb29nbGUiOgogICAgICAgIHJldHVybiBleGVjdXRhcl9kaWFnbm9zdGljb19n
REM b29nbGUocmFpeikKICAgIGVsaWYgbW9kbyA9PSAiZGlhZ25vc3RpY29fZXN0cmVzc2VfZ29v
REM Z2xlIjoKICAgICAgICByZXR1cm4gZXhlY3V0YXJfZGlhZ25vc3RpY29fZXN0cmVzc2VfZ29v
REM Z2xlKHJhaXopCiAgICBlbGlmIG1vZG8gPT0gInJlaW5qZXRhciI6CiAgICAgICAgcmV0b3Ju
REM byA9IGV4ZWN1dGFyX3JlaW5qZWNhbyhyYWl6KQogICAgICAgIHJldHVybiByZXRvcm5vIGlm
REM IHJldG9ybm8gaXMgbm90IE5vbmUgZWxzZSAwCiAgICBlbHNlOgogICAgICAgIHByaW50KHQo
REM Im1vZG9fZGVzY29uaGVjaWRvIikuZm9ybWF0KG1vZG8pKQoKaWYgX19uYW1lX18gPT0gIl9f
REM bWFpbl9fIjoKICAgIHRyeToKICAgICAgICBzeXMuZXhpdChtYWluKCkpCiAgICBleGNlcHQg
REM RXhjZXB0aW9uOgogICAgICAgIGltcG9ydCB0cmFjZWJhY2sKICAgICAgICB0cmFjZWJhY2su
REM cHJpbnRfZXhjKCkKICAgICAgICBzeXMuZXhpdCgxKQo=
REM ##DDAC_DIALOGOS_PYTHON_END##
REM ##DDAC_PTBR_PATCH_START##
REM #IyBEREFDLUludGVyZmFjZS1Vbml2ZXJzYWwtUFQtQlIg4oCUIGNhdMOhbG9nbyB1bml2ZXJzYWwg
REM #ZGUgaW50ZXJmYWNlIFBULUJSIHBhcmEgUmVuJ1B5IDYgLyA3IC8gOC4KIyBDb3B5cmlnaHQgKGMp
REM #IDIwMjYgUGVkcm8gLyBEREFDLgojIFRvZG9zIG9zIGRpcmVpdG9zIHJlc2VydmFkb3Mgc29icmUg
REM #YXMgbW9kaWZpY2HDp8O1ZXMsIGFkYXB0YcOnw7VlcyBlIHRyYWR1w6fDtWVzIG9yaWdpbmFpcyBh
REM #ZGljaW9uYWRhcyBwZWxvIEREQUMuCiMgTyBjw7NkaWdvIG9yaWdpbmFsIGRvIFJlbidQeSBlIGRl
REM #IHRlcmNlaXJvcyBtYW50w6ltIHNldXMgYXV0b3JlcywgYXZpc29zIGUgbGljZW7Dp2FzIG9yaWdp
REM #bmFpcy4KIyBURVJNT1MgREUgVVNPIEREQUM6IGFzIG1vZGlmaWNhw6fDtWVzLCBhZGFwdGHDp8O1
REM #ZXMgZSB0cmFkdcOnw7VlcyBvcmlnaW5haXMgY3JpYWRhcyBwb3IgUGVkcm8vRERBQyBuw6NvIGRl
REM #dmVtIHNlciByZW1vdmlkYXMsIGF0cmlidcOtZGFzIGEgdGVyY2Vpcm9zIG91IHJlZGlzdHJpYnXD
REM #rWRhcyBjb21vIHNlIGZvc3NlbSBkZSB0ZXJjZWlyb3MuCiMgQ29tcGF0aWJpbGlkYWRlOiBjYXTD
REM #oWxvZ28gc3VwZXJzZXQgcG9yIHZlcnPDo28sIGNvbSB2YXJpYW50ZXMgaGlzdMOzcmljYXMgZSBt
REM #b2Rlcm5hcywgdXNhbmRvIHByaW5jaXBhbG1lbnRlICd0cmFuc2xhdGUgTm9uZSBzdHJpbmdzJyBz
REM #ZW0gZHVwbGljYXIgbGFiZWxzIGludGVybm9zLgoKaW5pdCAyMDAwIHB5dGhvbjoKICAgIGlmIGdl
REM #dGF0dHIoY29uZmlnLCAibWFpbl9tZW51IiwgTm9uZSkgaXMgbm90IE5vbmU6CiAgICAgICAgY29u
REM #ZmlnLm1haW5fbWVudSA9IFsKICAgICAgICAgICAgKHUiSW5pY2lhciBqb2dvIiwgInN0YXJ0Iiwg
REM #IlRydWUiKSwKICAgICAgICAgICAgKHUiQ2FycmVnYXIgam9nbyIsIF9pbnRyYV9qdW1wcygibG9h
REM #ZF9zY3JlZW4iLCAibWFpbl9nYW1lX3RyYW5zaXRpb24iKSwgIlRydWUiKSwKICAgICAgICAgICAg
REM #KHUiQ29uZmlndXJhw6fDtWVzIiwgX2ludHJhX2p1bXBzKCJwcmVmZXJlbmNlc19zY3JlZW4iLCAi
REM #bWFpbl9nYW1lX3RyYW5zaXRpb24iKSwgIlRydWUiKSwKICAgICAgICAgICAgKHUiQWp1ZGEiLCBf
REM #aGVscCwgIlRydWUiLCAiY29uZmlnLmhlbHAiKSwKICAgICAgICAgICAgKHUiU2FpciIsIHVpLmp1
REM #bXBzKCJfcXVpdCIpLCAiVHJ1ZSIpLAogICAgICAgIF0KICAgIGlmIGdldGF0dHIoY29uZmlnLCAi
REM #Z2FtZV9tZW51IiwgTm9uZSkgaXMgbm90IE5vbmU6CiAgICAgICAgY29uZmlnLmdhbWVfbWVudSA9
REM #IFsKICAgICAgICAgICAgKE5vbmUsIHUiVm9sdGFyIiwgdWkuanVtcHMoIl9yZXR1cm4iKSwgIlRy
REM #dWUiKSwKICAgICAgICAgICAgKCJwcmVmZXJlbmNlcyIsIHUiQ29uZmlndXJhw6fDtWVzIiwgX2lu
REM #dHJhX2p1bXBzKCJwcmVmZXJlbmNlc19zY3JlZW4iLCAiaW50cmFfdHJhbnNpdGlvbiIpLCAiVHJ1
REM #ZSIpLAogICAgICAgICAgICAoInNhdmUiLCB1IlNhbHZhciBqb2dvIiwgX2ludHJhX2p1bXBzKCJz
REM #YXZlX3NjcmVlbiIsICJpbnRyYV90cmFuc2l0aW9uIiksICJub3QgbWFpbl9tZW51IiksCiAgICAg
REM #ICAgICAgICgibG9hZCIsIHUiQ2FycmVnYXIgam9nbyIsIF9pbnRyYV9qdW1wcygibG9hZF9zY3Jl
REM #ZW4iLCAiaW50cmFfdHJhbnNpdGlvbiIpLCAiVHJ1ZSIpLAogICAgICAgICAgICAoTm9uZSwgdSJN
REM #ZW51IFByaW5jaXBhbCIsIHVpLmNhbGxzaW5uZXdjb250ZXh0KCJfbWFpbl9tZW51X3Byb21wdCIp
REM #LCAibm90IG1haW5fbWVudSIpLAogICAgICAgICAgICAoImhlbHAiLCB1IkFqdWRhIiwgX2hlbHAs
REM #ICJUcnVlIiwgImNvbmZpZy5oZWxwIiksCiAgICAgICAgICAgIChOb25lLCB1IlNhaXIiLCB1aS5j
REM #YWxsc2lubmV3Y29udGV4dCgiX3F1aXRfcHJvbXB0IiksICJUcnVlIiksCiAgICAgICAgXQogICAg
REM #bGF5b3V0LkFSRV9ZT1VfU1VSRSA9IHUiVGVtIGNlcnRlemE/IgogICAgbGF5b3V0LkRFTEVURV9T
REM #QVZFID0gdSJUZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGV4Y2x1aXIgZXN0ZSBzYWx2YW1lbnRv
REM #PyIKICAgIGxheW91dC5PVkVSV1JJVEVfU0FWRSA9IHUiVGVtIGNlcnRlemEgZGUgcXVlIGRlc2Vq
REM #YSBzb2JyZXNjcmV2ZXIgZXN0ZSBzYWx2YW1lbnRvPyIKICAgIGxheW91dC5MT0FESU5HID0gdSJB
REM #byBjYXJyZWdhciBlc3RlIGpvZ28sIHZvY8OqIHBlcmRlcsOhIG8gcHJvZ3Jlc3NvIG7Do28gc2Fs
REM #dm8uXG5UZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGNvbnRpbnVhcj8iCiAgICBsYXlvdXQuUVVJ
REM #VCA9IHUiVGVtIGNlcnRlemEgZGUgcXVlIGRlc2VqYSBzYWlyPyIKICAgIGxheW91dC5NQUlOX01F
REM #TlUgPSB1IlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgdm9sdGFyIGFvIE1lbnUgUHJpbmNpcGFs
REM #P1xuVm9jw6ogcGVyZGVyw6EgbyBwcm9ncmVzc28gbsOjbyBzYWx2by4iCiAgICBsYXlvdXQuRU5E
REM #X1JFUExBWSA9IHUiVGVtIGNlcnRlemEgZGUgcXVlIGRlc2VqYSBlbmNlcnJhciBvIHJlcGxheT8i
REM #CiAgICBsYXlvdXQuU0xPV19TS0lQID0gdSJUZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGNvbWXD
REM #p2FyIGEgYXZhbsOnYXI/IgogICAgbGF5b3V0LkZBU1RfU0tJUF9TRUVOID0gdSJUZW0gY2VydGV6
REM #YSBkZSBxdWUgZGVzZWphIGF2YW7Dp2FyIGF0w6kgYSBwcsOzeGltYSBlc2NvbGhhPyIKICAgIGxh
REM #eW91dC5GQVNUX1NLSVBfVU5TRUVOID0gdSJUZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGF2YW7D
REM #p2FyIHBlbG9zIGRpw6Fsb2dvcyBuw6NvIHZpc3RvcyBhdMOpIGEgcHLDs3hpbWEgZXNjb2xoYT8i
REM #CiAgICBpZiBoYXNhdHRyKGxheW91dCwgIkNPTlRJTlVFIik6CiAgICAgICAgbGF5b3V0LkNPTlRJ
REM #TlVFID0gdSJUZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGNvbnRpbnVhciBkZSBvbmRlIHBhcm91
REM #PyIKICAgIGlmIGhhc2F0dHIobGF5b3V0LCAiVU5LTk9XTl9UT0tFTiIpOgogICAgICAgIGxheW91
REM #dC5VTktOT1dOX1RPS0VOID0gdSJFc3RlIHNhdmUgZm9pIGNyaWFkbyBlbSBvdXRybyBkaXNwb3Np
REM #dGl2by4gQXJxdWl2b3MgZGUgc2F2ZSBtYWxpY2lvc2FtZW50ZSBjcmlhZG9zIHBvZGVtIGRhbmlm
REM #aWNhciBzZXUgY29tcHV0YWRvci4gVm9jw6ogY29uZmlhIG5vIGNyaWFkb3IgZGVzdGUgc2F2ZSBl
REM #IGVtIHRvZGFzIGFzIHBlc3NvYXMgcXVlIHBvZGVyaWFtIHRlciBhbHRlcmFkbyBvIGFycXVpdm8/
REM #IgogICAgaWYgaGFzYXR0cihsYXlvdXQsICJUUlVTVF9UT0tFTiIpOgogICAgICAgIGxheW91dC5U
REM #UlVTVF9UT0tFTiA9IHUiVm9jw6ogY29uZmlhIG5vIGRpc3Bvc2l0aXZvIGVtIHF1ZSBvIHNhdmUg
REM #Zm9pIGNyaWFkbz8gVm9jw6ogc8OzIGRldmUgZXNjb2xoZXIgc2ltIHNlIGZvciBvIMO6bmljbyB1
REM #c3XDoXJpbyBkZXNzZSBkaXNwb3NpdGl2bz8iCiAgICBfd2Vla2RheV9uYW1lX2xvbmcgPSBbCiAg
REM #ICAgICAgXygieyN3ZWVrZGF5fVNlZ3VuZGEiKSwKICAgICAgICBfKCJ7I3dlZWtkYXl9VGVyw6dh
REM #IiksCiAgICAgICAgXygieyN3ZWVrZGF5fVF1YXJ0YSIpLAogICAgICAgIF8oInsjd2Vla2RheX1R
REM #dWludGEiKSwKICAgICAgICBfKCJ7I3dlZWtkYXl9U2V4dGEiKSwKICAgICAgICBfKCJ7I3dlZWtk
REM #YXl9U8OhYmFkbyIpLAogICAgICAgIF8oInsjd2Vla2RheX1Eb21pbmdvIiksCiAgICBdCiAgICBf
REM #d2Vla2RheV9uYW1lX3Nob3J0ID0gWwogICAgICAgIF8oInsjd2Vla2RheV9zaG9ydH1TZWciKSwK
REM #ICAgICAgICBfKCJ7I3dlZWtkYXlfc2hvcnR9VGVyIiksCiAgICAgICAgXygieyN3ZWVrZGF5X3No
REM #b3J0fVF1YSIpLAogICAgICAgIF8oInsjd2Vla2RheV9zaG9ydH1RdWkiKSwKICAgICAgICBfKCJ7
REM #I3dlZWtkYXlfc2hvcnR9U2V4IiksCiAgICAgICAgXygieyN3ZWVrZGF5X3Nob3J0fVNhYiIpLAog
REM #ICAgICAgIF8oInsjd2Vla2RheV9zaG9ydH1Eb20iKSwKICAgIF0KICAgIF9tb250aF9uYW1lX2xv
REM #bmcgPSBbCiAgICAgICAgXygieyNtb250aH1KYW5laXJvIiksCiAgICAgICAgXygieyNtb250aH1G
REM #ZXZlcmVpcm8iKSwKICAgICAgICBfKCJ7I21vbnRofU1hcsOnbyIpLAogICAgICAgIF8oInsjbW9u
REM #dGh9QWJyaWwiKSwKICAgICAgICBfKCJ7I21vbnRofU1haW8iKSwKICAgICAgICBfKCJ7I21vbnRo
REM #fUp1bmhvIiksCiAgICAgICAgXygieyNtb250aH1KdWxobyIpLAogICAgICAgIF8oInsjbW9udGh9
REM #QWdvc3RvIiksCiAgICAgICAgXygieyNtb250aH1TZXRlbWJybyIpLAogICAgICAgIF8oInsjbW9u
REM #dGh9T3V0dWJybyIpLAogICAgICAgIF8oInsjbW9udGh9Tm92ZW1icm8iKSwKICAgICAgICBfKCJ7
REM #I21vbnRofURlemVtYnJvIiksCiAgICBdCiAgICBfbW9udGhfbmFtZV9zaG9ydCA9IFsKICAgICAg
REM #ICBfKCJ7I21vbnRoX3Nob3J0fUphbiIpLAogICAgICAgIF8oInsjbW9udGhfc2hvcnR9RmV2Iiks
REM #CiAgICAgICAgXygieyNtb250aF9zaG9ydH1NYXIiKSwKICAgICAgICBfKCJ7I21vbnRoX3Nob3J0
REM #fUFiciIpLAogICAgICAgIF8oInsjbW9udGhfc2hvcnR9TWFpIiksCiAgICAgICAgXygieyNtb250
REM #aF9zaG9ydH1KdW4iKSwKICAgICAgICBfKCJ7I21vbnRoX3Nob3J0fUp1bCIpLAogICAgICAgIF8o
REM #InsjbW9udGhfc2hvcnR9QWdvIiksCiAgICAgICAgXygieyNtb250aF9zaG9ydH1TZXQiKSwKICAg
REM #ICAgICBfKCJ7I21vbnRoX3Nob3J0fU91dCIpLAogICAgICAgIF8oInsjbW9udGhfc2hvcnR9Tm92
REM #IiksCiAgICAgICAgXygieyNtb250aF9zaG9ydH1EZXoiKSwKICAgIF0KICAgIGlmICJGaWxlU2F2
REM #ZSIgaW4gZ2xvYmFscygpOgogICAgICAgIEZpbGVTYXZlLmFsdCA9IHUiU2FsdmFtZW50byBbdGV4
REM #dF0iCiAgICBpZiAiRmlsZUxvYWQiIGluIGdsb2JhbHMoKToKICAgICAgICBGaWxlTG9hZC5hbHQg
REM #PSB1IkNhcnJlZ2FtZW50byBbdGV4dF0iCiAgICBpZiAiRmlsZURlbGV0ZSIgaW4gZ2xvYmFscygp
REM #OgogICAgICAgIEZpbGVEZWxldGUuYWx0ID0gdSJFeGNsdWlyIHNhbHZhbWVudG8gW3RleHRdIgog
REM #ICAgaWYgIkZpbGVQYWdlTmV4dCIgaW4gZ2xvYmFscygpOgogICAgICAgIEZpbGVQYWdlTmV4dC5h
REM #bHQgPSB1IlByw7N4aW1hIHDDoWdpbmEiCiAgICBpZiAiRmlsZVBhZ2VQcmV2aW91cyIgaW4gZ2xv
REM #YmFscygpOgogICAgICAgIEZpbGVQYWdlUHJldmlvdXMuYWx0ID0gdSJQw6FnaW5hIGFudGVyaW9y
REM #IgogICAgaWYgIkZpbGVQYWdlIiBpbiBnbG9iYWxzKCk6CiAgICAgICAgX2RkYWNfb3JpZ2luYWxf
REM #RmlsZVBhZ2VfaW5pdCA9IEZpbGVQYWdlLl9faW5pdF9fCiAgICAgICAgZGVmIF9kZGFjX0ZpbGVQ
REM #YWdlX2luaXQoc2VsZiwgcGFnZSk6CiAgICAgICAgICAgIF9kZGFjX29yaWdpbmFsX0ZpbGVQYWdl
REM #X2luaXQoc2VsZiwgcGFnZSkKICAgICAgICAgICAgc2VsZi5hbHQgPSB1IlDDoWdpbmEgZGUgc2Fs
REM #dmFtZW50b3MgW3RleHRdIgogICAgICAgIEZpbGVQYWdlLl9faW5pdF9fID0gX2RkYWNfRmlsZVBh
REM #Z2VfaW5pdAogICAgaWYgIkZpbGVQYWdlTmFtZUlucHV0VmFsdWUiIGluIGdsb2JhbHMoKToKICAg
REM #ICAgICBfZGRhY19vcmlnaW5hbF9GaWxlUGFnZU5hbWVJbnB1dFZhbHVlX2luaXQgPSBGaWxlUGFn
REM #ZU5hbWVJbnB1dFZhbHVlLl9faW5pdF9fCiAgICAgICAgZGVmIF9kZGFjX0ZpbGVQYWdlTmFtZUlu
REM #cHV0VmFsdWVfaW5pdChzZWxmLCBwYXR0ZXJuPXUiUMOhZ2luYSB7fSIsCiAgICAgICAgICAgICAg
REM #ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYXV0bz11IlNhbHZhbWVudG9zIGF1dG9t
REM #w6F0aWNvcyIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
REM #cXVpY2s9dSJTYWx2YW1lbnRvcyByw6FwaWRvcyIsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
REM #ICAgICAgICAgICAgICAgICAgICAgcGFnZT1Ob25lLCBkZWZhdWx0PUZhbHNlKToKICAgICAgICAg
REM #ICAgcmV0dXJuIF9kZGFjX29yaWdpbmFsX0ZpbGVQYWdlTmFtZUlucHV0VmFsdWVfaW5pdCgKICAg
REM #ICAgICAgICAgICAgIHNlbGYsIHBhdHRlcm4sIGF1dG8sIHF1aWNrLCBwYWdlLCBkZWZhdWx0CiAg
REM #ICAgICAgICAgICkKICAgICAgICBGaWxlUGFnZU5hbWVJbnB1dFZhbHVlLl9faW5pdF9fID0gX2Rk
REM #YWNfRmlsZVBhZ2VOYW1lSW5wdXRWYWx1ZV9pbml0CiAgICAgICAgdHJ5OgogICAgICAgICAgICBG
REM #aWxlUGFnZU5hbWVJbnB1dFZhbHVlLmFsdCA9IHUiUMOhZ2luYSBkZSBzYWx2YW1lbnRvcyBbdGV4
REM #dF0iCiAgICAgICAgZXhjZXB0OgogICAgICAgICAgICBwYXNzCiAgICBpZiAiUXVpY2tTYXZlIiBp
REM #biBnbG9iYWxzKCk6CiAgICAgICAgX2RkYWNfb3JpZ2luYWxfUXVpY2tTYXZlID0gUXVpY2tTYXZl
REM #CiAgICAgICAgX2RkYWNfcXVpY2tzYXZlX2RlZmF1bHQgPSBvYmplY3QoKQogICAgICAgIEByZW5w
REM #eS5wdXJlCiAgICAgICAgZGVmIFF1aWNrU2F2ZShtZXNzYWdlPV9kZGFjX3F1aWNrc2F2ZV9kZWZh
REM #dWx0LCBuZXdlc3Q9RmFsc2UpOgogICAgICAgICAgICBpZiBtZXNzYWdlIGlzIF9kZGFjX3F1aWNr
REM #c2F2ZV9kZWZhdWx0OgogICAgICAgICAgICAgICAgbWVzc2FnZSA9IHUiU2FsdmFtZW50byByw6Fw
REM #aWRvIGNvbmNsdcOtZG8uIgogICAgICAgICAgICBydiA9IF9kZGFjX29yaWdpbmFsX1F1aWNrU2F2
REM #ZShtZXNzYWdlLCBuZXdlc3QpCiAgICAgICAgICAgIGlmIHJ2IGFuZCBoYXNhdHRyKHJ2WzBdLCAi
REM #YWx0Iik6CiAgICAgICAgICAgICAgICBydlswXS5hbHQgPSB1IlNhbHZhbWVudG8gcsOhcGlkby4i
REM #CiAgICAgICAgICAgIHJldHVybiBydgogICAgaWYgIlF1aWNrTG9hZCIgaW4gZ2xvYmFscygpOgog
REM #ICAgICAgIF9kZGFjX29yaWdpbmFsX1F1aWNrTG9hZCA9IFF1aWNrTG9hZAogICAgICAgIEByZW5w
REM #eS5wdXJlCiAgICAgICAgZGVmIFF1aWNrTG9hZChjb25maXJtPVRydWUpOgogICAgICAgICAgICBy
REM #diA9IF9kZGFjX29yaWdpbmFsX1F1aWNrTG9hZChjb25maXJtKQogICAgICAgICAgICBydi5hbHQg
REM #PSB1IkNhcnJlZ2FtZW50byByw6FwaWRvLiIKaW5pdCA5OTk5OTkgcHl0aG9uOgogICAgaWYgZ2V0
REM #YXR0cihjb25maWcsICJtYWluX21lbnUiLCBOb25lKSBpcyBub3QgTm9uZToKICAgICAgICBjb25m
REM #aWcubWFpbl9tZW51ID0gWwogICAgICAgICAgICAodSJJbmljaWFyIGpvZ28iLCAic3RhcnQiLCAi
REM #VHJ1ZSIpLAogICAgICAgICAgICAodSJDYXJyZWdhciBqb2dvIiwgX2ludHJhX2p1bXBzKCJsb2Fk
REM #X3NjcmVlbiIsICJtYWluX2dhbWVfdHJhbnNpdGlvbiIpLCAiVHJ1ZSIpLAogICAgICAgICAgICAo
REM #dSJDb25maWd1cmHDp8O1ZXMiLCBfaW50cmFfanVtcHMoInByZWZlcmVuY2VzX3NjcmVlbiIsICJt
REM #YWluX2dhbWVfdHJhbnNpdGlvbiIpLCAiVHJ1ZSIpLAogICAgICAgICAgICAodSJBanVkYSIsIF9o
REM #ZWxwLCAiVHJ1ZSIsICJjb25maWcuaGVscCIpLAogICAgICAgICAgICAodSJTYWlyIiwgdWkuanVt
REM #cHMoIl9xdWl0IiksICJUcnVlIiksCiAgICAgICAgXQogICAgaWYgZ2V0YXR0cihjb25maWcsICJn
REM #YW1lX21lbnUiLCBOb25lKSBpcyBub3QgTm9uZToKICAgICAgICBjb25maWcuZ2FtZV9tZW51ID0g
REM #WwogICAgICAgICAgICAoTm9uZSwgdSJWb2x0YXIiLCB1aS5qdW1wcygiX3JldHVybiIpLCAiVHJ1
REM #ZSIpLAogICAgICAgICAgICAoInByZWZlcmVuY2VzIiwgdSJDb25maWd1cmHDp8O1ZXMiLCBfaW50
REM #cmFfanVtcHMoInByZWZlcmVuY2VzX3NjcmVlbiIsICJpbnRyYV90cmFuc2l0aW9uIiksICJUcnVl
REM #IiksCiAgICAgICAgICAgICgic2F2ZSIsIHUiU2FsdmFyIGpvZ28iLCBfaW50cmFfanVtcHMoInNh
REM #dmVfc2NyZWVuIiwgImludHJhX3RyYW5zaXRpb24iKSwgIm5vdCBtYWluX21lbnUiKSwKICAgICAg
REM #ICAgICAgKCJsb2FkIiwgdSJDYXJyZWdhciBqb2dvIiwgX2ludHJhX2p1bXBzKCJsb2FkX3NjcmVl
REM #biIsICJpbnRyYV90cmFuc2l0aW9uIiksICJUcnVlIiksCiAgICAgICAgICAgIChOb25lLCB1Ik1l
REM #bnUgUHJpbmNpcGFsIiwgdWkuY2FsbHNpbm5ld2NvbnRleHQoIl9tYWluX21lbnVfcHJvbXB0Iiks
REM #ICJub3QgbWFpbl9tZW51IiksCiAgICAgICAgICAgICgiaGVscCIsIHUiQWp1ZGEiLCBfaGVscCwg
REM #IlRydWUiLCAiY29uZmlnLmhlbHAiKSwKICAgICAgICAgICAgKE5vbmUsIHUiU2FpciIsIHVpLmNh
REM #bGxzaW5uZXdjb250ZXh0KCJfcXVpdF9wcm9tcHQiKSwgIlRydWUiKSwKICAgICAgICBdCnRyYW5z
REM #bGF0ZSBOb25lIHN0cmluZ3M6CiAgICBvbGQgIlNlbGYtdm9pY2luZyBkaXNhYmxlZC4iCiAgICBu
REM #ZXcgIlZveiBhdXRvbcOhdGljYSBkZXNhdGl2YWRhLiIKICAgIG9sZCAiQ2xpcGJvYXJkIHZvaWNp
REM #bmcgZW5hYmxlZC4gIgogICAgbmV3ICJWb3ogZGEgw6FyZWEgZGUgdHJhbnNmZXLDqm5jaWEgYXRp
REM #dmFkYS4gIgogICAgb2xkICJTZWxmLXZvaWNpbmcgZW5hYmxlZC4gIgogICAgbmV3ICJWb3ogYXV0
REM #b23DoXRpY2EgYXRpdmFkYS4gIgogICAgb2xkICJiYXIiCiAgICBuZXcgImJhcnJhIgogICAgb2xk
REM #ICJzZWxlY3RlZCIKICAgIG5ldyAic2VsZWNpb25hZG8iCiAgICBvbGQgInZpZXdwb3J0IgogICAg
REM #bmV3ICLDoXJlYSBkZSByb2xhZ2VtIgogICAgb2xkICJob3Jpem9udGFsIHNjcm9sbCIKICAgIG5l
REM #dyAicm9sYWdlbSBob3Jpem9udGFsIgogICAgb2xkICJ2ZXJ0aWNhbCBzY3JvbGwiCiAgICBuZXcg
REM #InJvbGFnZW0gdmVydGljYWwiCiAgICBvbGQgImFjdGl2YXRlIgogICAgbmV3ICJhdGl2YXIiCiAg
REM #ICBvbGQgImRlYWN0aXZhdGUiCiAgICBuZXcgImRlc2F0aXZhciIKICAgIG9sZCAiaW5jcmVhc2Ui
REM #CiAgICBuZXcgImF1bWVudGFyIgogICAgb2xkICJkZWNyZWFzZSIKICAgIG5ldyAiZGltaW51aXIi
REM #CiAgICBvbGQgIkZvbnQgT3ZlcnJpZGUiCiAgICBuZXcgIlN1YnN0aXR1acOnw6NvIGRlIGZvbnRl
REM #IgogICAgb2xkICJEZWZhdWx0IgogICAgbmV3ICJQYWRyw6NvIgogICAgb2xkICJUZXh0IFNpemUg
REM #U2NhbGluZyIKICAgIG5ldyAiRXNjYWxhIGRvIHRhbWFuaG8gZG8gdGV4dG8iCiAgICBvbGQgIlJl
REM #c2V0IgogICAgbmV3ICJSZWRlZmluaXIiCiAgICBvbGQgIkxpbmUgU3BhY2luZyBTY2FsaW5nIgog
REM #ICAgbmV3ICJFc2NhbGEgZG8gZXNwYcOnYW1lbnRvIGVudHJlIGxpbmhhcyIKICAgIG9sZCAiU2Vs
REM #Zi1Wb2ljaW5nIgogICAgbmV3ICJWb3ogYXV0b23DoXRpY2EiCiAgICBvbGQgIk9mZiIKICAgIG5l
REM #dyAiRGVzYXRpdmFkbyIKICAgIG9sZCAiVGV4dC10by1zcGVlY2giCiAgICBuZXcgIlRleHRvIHBh
REM #cmEgZmFsYSIKICAgIG9sZCAiQ2xpcGJvYXJkIgogICAgbmV3ICLDgXJlYSBkZSB0cmFuc2ZlcsOq
REM #bmNpYSIKICAgIG9sZCAiRGVidWciCiAgICBuZXcgIkRlcHVyYcOnw6NvIgogICAgb2xkICJIaWdo
REM #IENvbnRyYXN0IFRleHQiCiAgICBuZXcgIlRleHRvIGRlIGFsdG8gY29udHJhc3RlIgogICAgb2xk
REM #ICJFbmFibGUiCiAgICBuZXcgIkF0aXZhciIKICAgIG9sZCAiRGlzYWJsZSIKICAgIG5ldyAiRGVz
REM #YXRpdmFyIgogICAgb2xkICJBY2Nlc3NpYmlsaXR5IE1lbnUuIFVzZSB1cCBhbmQgZG93biBhcnJv
REM #d3MgdG8gbmF2aWdhdGUsIGFuZCBlbnRlciB0byBhY3RpdmF0ZSBidXR0b25zIGFuZCBiYXJzLiIK
REM #ICAgIG5ldyAiTWVudSBkZSBhY2Vzc2liaWxpZGFkZS4gVXNlIGFzIHNldGFzIHBhcmEgY2ltYSBl
REM #IHBhcmEgYmFpeG8gcGFyYSBuYXZlZ2FyIGUgRW50ZXIgcGFyYSBhdGl2YXIgYm90w7VlcyBlIGJh
REM #cnJhcy4iCiAgICBvbGQgIlNlbGYtdm9pY2luZyBzdXBwb3J0IGlzIGxpbWl0ZWQgd2hlbiB1c2lu
REM #ZyBhIHRvdWNoIHNjcmVlbi4iCiAgICBuZXcgIk8gc3Vwb3J0ZSDDoCB2b3ogYXV0b23DoXRpY2Eg
REM #w6kgbGltaXRhZG8gYW8gdXNhciB1bWEgdGVsYSBzZW5zw612ZWwgYW8gdG9xdWUuIgogICAgb2xk
REM #ICJTZWxmLVZvaWNpbmcgVm9sdW1lIERyb3AiCiAgICBuZXcgIlJlZHXDp8OjbyBkbyB2b2x1bWUg
REM #ZGEgdm96IGF1dG9tw6F0aWNhIgogICAgb2xkICJTa2lwIE1vZGUiCiAgICBuZXcgIk1vZG8gZGUg
REM #YXZhbsOnbyIKICAgIG9sZCAiRmFzdCBTa2lwIE1vZGUiCiAgICBuZXcgIk1vZG8gZGUgYXZhbsOn
REM #byByw6FwaWRvIgogICAgb2xkICJBdXRvcmVsb2FkIgogICAgbmV3ICJSZWNhcnJlZ2FtZW50byBh
REM #dXRvbcOhdGljbyIKICAgIG9sZCAiU2F2ZWQgc2NyZWVuc2hvdCBhcyAlcy4iCiAgICBuZXcgIkNh
REM #cHR1cmEgZGUgdGVsYSBzYWx2YSBjb21vICVzLiIKICAgIG9sZCAiRmFpbGVkIHRvIHNhdmUgc2Ny
REM #ZWVuc2hvdCBhcyAlcy4iCiAgICBuZXcgIkZhbGhhIGFvIHNhbHZhciBhIGNhcHR1cmEgZGUgdGVs
REM #YSBjb21vICVzLiIKICAgIG9sZCAiQXJlIHlvdSBzdXJlIHlvdSB3YW50IHRvIGNvbnRpbnVlIHdo
REM #ZXJlIHlvdSBsZWZ0IG9mZj8iCiAgICBuZXcgIlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgY29u
REM #dGludWFyIGRlIG9uZGUgcGFyb3U/IgogICAgb2xkICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8g
REM #ZW5kIHRoZSByZXBsYXk/IgogICAgbmV3ICJUZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGVuY2Vy
REM #cmFyIG8gcmVwbGF5PyIKICAgIG9sZCAiQXJlIHlvdSBzdXJlIHlvdSB3YW50IHRvIHNraXAgdW5z
REM #ZWVuIGRpYWxvZ3VlIHRvIHRoZSBuZXh0IGNob2ljZT8iCiAgICBuZXcgIlZvY8OqIHRlbSBjZXJ0
REM #ZXphIGRlIHF1ZSBkZXNlamEgYXZhbsOnYXIgcGVsb3MgZGnDoWxvZ29zIG7Do28gdmlzdG9zIGF0
REM #w6kgYSBwcsOzeGltYSBlc2NvbGhhPyIKICAgIG9sZCAiQXJlIHlvdSBzdXJlIHlvdSB3YW50IHRv
REM #IHNraXAgdG8gdW5zZWVuIGRpYWxvZ3VlIG9yIHRoZSBuZXh0IGNob2ljZT8iCiAgICBuZXcgIlZv
REM #Y8OqIHRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgYXZhbsOnYXIgYXTDqSBvcyBkacOhbG9nb3Mg
REM #bsOjbyB2aXN0b3Mgb3UgYSBwcsOzeGltYSBlc2NvbGhhPyIKICAgIG9sZCAiVGhpcyBzYXZlIHdh
REM #cyBjcmVhdGVkIG9uIGEgZGlmZmVyZW50IGRldmljZS4gTWFsaWNpb3VzbHkgY29uc3RydWN0ZWQg
REM #c2F2ZSBmaWxlcyBjYW4gaGFybSB5b3VyIGNvbXB1dGVyLiBEbyB5b3UgdHJ1c3QgdGhpcyBzYXZl
REM #J3MgY3JlYXRvciBhbmQgZXZlcnlvbmUgd2hvIGNvdWxkIGhhdmUgY2hhbmdlZCB0aGUgZmlsZT8i
REM #CiAgICBuZXcgIkVzdGUgc2FsdmFtZW50byBmb2kgY3JpYWRvIGVtIG91dHJvIGRpc3Bvc2l0aXZv
REM #LiBBcnF1aXZvcyBkZSBzYWx2YW1lbnRvIG1hbGljaW9zYW1lbnRlIGNyaWFkb3MgcG9kZW0gZGFu
REM #aWZpY2FyIHNldSBjb21wdXRhZG9yLiBWb2PDqiBjb25maWEgZW0gcXVlbSBjcmlvdSBlc3RlIHNh
REM #bHZhbWVudG8gZSBlbSB0b2RhcyBhcyBwZXNzb2FzIHF1ZSBwb2RlbSB0ZXIgYWx0ZXJhZG8gbyBh
REM #cnF1aXZvPyIKICAgIG9sZCAiRG8geW91IHRydXN0IHRoZSBkZXZpY2UgdGhlIHNhdmUgd2FzIGNy
REM #ZWF0ZWQgb24/IFlvdSBzaG91bGQgb25seSBjaG9vc2UgeWVzIGlmIHlvdSBhcmUgdGhlIGRldmlj
REM #ZSdzIHNvbGUgdXNlci4iCiAgICBuZXcgIlZvY8OqIGNvbmZpYSBubyBkaXNwb3NpdGl2byBlbSBx
REM #dWUgZXN0ZSBzYWx2YW1lbnRvIGZvaSBjcmlhZG8/IEVzY29saGEgU2ltIHNvbWVudGUgc2Ugdm9j
REM #w6ogZm9yIG8gw7puaWNvIHVzdcOhcmlvIGRlc3NlIGRpc3Bvc2l0aXZvLiIKICAgIG9sZCAiVGhp
REM #cyBwcm9ncmFtIGNvbnRhaW5zIGZyZWUgc29mdHdhcmUgdW5kZXIgYSBudW1iZXIgb2YgbGljZW5z
REM #ZXMsIGluY2x1ZGluZyB0aGUgTUlUIExpY2Vuc2UgYW5kIEdOVSBMZXNzZXIgR2VuZXJhbCBQdWJs
REM #aWMgTGljZW5zZS4gQSBjb21wbGV0ZSBsaXN0IG9mIHNvZnR3YXJlLCBpbmNsdWRpbmcgbGlua3Mg
REM #dG8gZnVsbCBzb3VyY2UgY29kZSwgY2FuIGJlIGZvdW5kIHthPWh0dHBzOi8vd3d3LnJlbnB5Lm9y
REM #Zy9sL2xpY2Vuc2V9aGVyZXsvYX0uIgogICAgbmV3ICJFc3RlIHByb2dyYW1hIGNvbnTDqW0gc29m
REM #dHdhcmUgbGl2cmUgZGlzdHJpYnXDrWRvIHNvYiB2w6FyaWFzIGxpY2Vuw6dhcywgaW5jbHVpbmRv
REM #IGEgTGljZW7Dp2EgTUlUIGUgYSBHTlUgTGVzc2VyIEdlbmVyYWwgUHVibGljIExpY2Vuc2UgKExH
REM #UEwpLiBBIGxpc3RhIGNvbXBsZXRhIGRvcyBzb2Z0d2FyZXMsIGNvbSBsaW5rcyBwYXJhIG8gY8Oz
REM #ZGlnby1mb250ZSwgZXN0w6EgZGlzcG9uw612ZWwge2E9aHR0cHM6Ly93d3cucmVucHkub3JnL2wv
REM #bGljZW5zZX1hcXVpey9hfS4iCiAgICBvbGQgIiViICVkLCAlSDolTSIKICAgIG5ldyAiJWQgZGUg
REM #JWIsICVIOiVNIgogICAgb2xkICJTYXZlIHNsb3QgJXM6IFt0ZXh0XSIKICAgIG5ldyAiU2FsdmFt
REM #ZW50byAlczogW3RleHRdIgogICAgb2xkICJMb2FkIHNsb3QgJXM6IFt0ZXh0XSIKICAgIG5ldyAi
REM #Q2FycmVnYW1lbnRvICVzOiBbdGV4dF0iCiAgICBvbGQgIkRlbGV0ZSBzbG90IFt0ZXh0XSIKICAg
REM #IG5ldyAiRXhjbHVpciBzYWx2YW1lbnRvIFt0ZXh0XSIKICAgIG9sZCAiRmlsZSBwYWdlIGF1dG8i
REM #CiAgICBuZXcgIlDDoWdpbmEgZGUgc2FsdmFtZW50b3MgYXV0b23DoXRpY29zIgogICAgb2xkICJG
REM #aWxlIHBhZ2UgcXVpY2siCiAgICBuZXcgIlDDoWdpbmEgZGUgc2FsdmFtZW50b3MgcsOhcGlkb3Mi
REM #CiAgICBvbGQgIkZpbGUgcGFnZSBbdGV4dF0iCiAgICBuZXcgIlDDoWdpbmEgZGUgc2FsdmFtZW50
REM #b3MgW3RleHRdIgogICAgb2xkICJOZXh0IGZpbGUgcGFnZS4iCiAgICBuZXcgIlByw7N4aW1hIHDD
REM #oWdpbmEuIgogICAgb2xkICJQcmV2aW91cyBmaWxlIHBhZ2UuIgogICAgbmV3ICJQw6FnaW5hIGFu
REM #dGVyaW9yLiIKICAgIG9sZCAiUXVpY2sgc2F2ZSBjb21wbGV0ZS4iCiAgICBuZXcgIlNhbHZhbWVu
REM #dG8gcsOhcGlkbyBjb25jbHXDrWRvLiIKICAgIG9sZCAiUXVpY2sgc2F2ZS4iCiAgICBuZXcgIlNh
REM #bHZhbWVudG8gcsOhcGlkby4iCiAgICBvbGQgIlF1aWNrIGxvYWQuIgogICAgbmV3ICJDYXJyZWdh
REM #bWVudG8gcsOhcGlkby4iCiAgICBvbGQgInsjd2Vla2RheX1Nb25kYXkiCiAgICBuZXcgInsjd2Vl
REM #a2RheX1TZWd1bmRhLWZlaXJhIgogICAgb2xkICJ7I3dlZWtkYXl9VHVlc2RheSIKICAgIG5ldyAi
REM #eyN3ZWVrZGF5fVRlcsOnYS1mZWlyYSIKICAgIG9sZCAieyN3ZWVrZGF5fVdlZG5lc2RheSIKICAg
REM #IG5ldyAieyN3ZWVrZGF5fVF1YXJ0YS1mZWlyYSIKICAgIG9sZCAieyN3ZWVrZGF5fVRodXJzZGF5
REM #IgogICAgbmV3ICJ7I3dlZWtkYXl9UXVpbnRhLWZlaXJhIgogICAgb2xkICJ7I3dlZWtkYXl9RnJp
REM #ZGF5IgogICAgbmV3ICJ7I3dlZWtkYXl9U2V4dGEtZmVpcmEiCiAgICBvbGQgInsjd2Vla2RheX1T
REM #YXR1cmRheSIKICAgIG5ldyAieyN3ZWVrZGF5fVPDoWJhZG8iCiAgICBvbGQgInsjd2Vla2RheX1T
REM #dW5kYXkiCiAgICBuZXcgInsjd2Vla2RheX1Eb21pbmdvIgogICAgb2xkICJ7I3dlZWtkYXlfc2hv
REM #cnR9TW9uIgogICAgbmV3ICJ7I3dlZWtkYXlfc2hvcnR9U2VnIgogICAgb2xkICJ7I3dlZWtkYXlf
REM #c2hvcnR9VHVlIgogICAgbmV3ICJ7I3dlZWtkYXlfc2hvcnR9VGVyIgogICAgb2xkICJ7I3dlZWtk
REM #YXlfc2hvcnR9V2VkIgogICAgbmV3ICJ7I3dlZWtkYXlfc2hvcnR9UXVhIgogICAgb2xkICJ7I3dl
REM #ZWtkYXlfc2hvcnR9VGh1IgogICAgbmV3ICJ7I3dlZWtkYXlfc2hvcnR9UXVpIgogICAgb2xkICJ7
REM #I3dlZWtkYXlfc2hvcnR9RnJpIgogICAgbmV3ICJ7I3dlZWtkYXlfc2hvcnR9U2V4IgogICAgb2xk
REM #ICJ7I3dlZWtkYXlfc2hvcnR9U2F0IgogICAgbmV3ICJ7I3dlZWtkYXlfc2hvcnR9U8OhYiIKICAg
REM #IG9sZCAieyN3ZWVrZGF5X3Nob3J0fVN1biIKICAgIG5ldyAieyN3ZWVrZGF5X3Nob3J0fURvbSIK
REM #ICAgIG9sZCAieyNtb250aH1KYW51YXJ5IgogICAgbmV3ICJ7I21vbnRofUphbmVpcm8iCiAgICBv
REM #bGQgInsjbW9udGh9RmVicnVhcnkiCiAgICBuZXcgInsjbW9udGh9RmV2ZXJlaXJvIgogICAgb2xk
REM #ICJ7I21vbnRofU1hcmNoIgogICAgbmV3ICJ7I21vbnRofU1hcsOnbyIKICAgIG9sZCAieyNtb250
REM #aH1BcHJpbCIKICAgIG5ldyAieyNtb250aH1BYnJpbCIKICAgIG9sZCAieyNtb250aH1NYXkiCiAg
REM #ICBuZXcgInsjbW9udGh9TWFpbyIKICAgIG9sZCAieyNtb250aH1KdW5lIgogICAgbmV3ICJ7I21v
REM #bnRofUp1bmhvIgogICAgb2xkICJ7I21vbnRofUp1bHkiCiAgICBuZXcgInsjbW9udGh9SnVsaG8i
REM #CiAgICBvbGQgInsjbW9udGh9QXVndXN0IgogICAgbmV3ICJ7I21vbnRofUFnb3N0byIKICAgIG9s
REM #ZCAieyNtb250aH1TZXB0ZW1iZXIiCiAgICBuZXcgInsjbW9udGh9U2V0ZW1icm8iCiAgICBvbGQg
REM #InsjbW9udGh9T2N0b2JlciIKICAgIG5ldyAieyNtb250aH1PdXR1YnJvIgogICAgb2xkICJ7I21v
REM #bnRofU5vdmVtYmVyIgogICAgbmV3ICJ7I21vbnRofU5vdmVtYnJvIgogICAgb2xkICJ7I21vbnRo
REM #fURlY2VtYmVyIgogICAgbmV3ICJ7I21vbnRofURlemVtYnJvIgogICAgb2xkICJ7I21vbnRoX3No
REM #b3J0fUphbiIKICAgIG5ldyAieyNtb250aF9zaG9ydH1KYW4iCiAgICBvbGQgInsjbW9udGhfc2hv
REM #cnR9RmViIgogICAgbmV3ICJ7I21vbnRoX3Nob3J0fUZldiIKICAgIG9sZCAieyNtb250aF9zaG9y
REM #dH1NYXIiCiAgICBuZXcgInsjbW9udGhfc2hvcnR9TWFyIgogICAgb2xkICJ7I21vbnRoX3Nob3J0
REM #fUFwciIKICAgIG5ldyAieyNtb250aF9zaG9ydH1BYnIiCiAgICBvbGQgInsjbW9udGhfc2hvcnR9
REM #TWF5IgogICAgbmV3ICJ7I21vbnRoX3Nob3J0fU1haSIKICAgIG9sZCAieyNtb250aF9zaG9ydH1K
REM #dW4iCiAgICBuZXcgInsjbW9udGhfc2hvcnR9SnVuIgogICAgb2xkICJ7I21vbnRoX3Nob3J0fUp1
REM #bCIKICAgIG5ldyAieyNtb250aF9zaG9ydH1KdWwiCiAgICBvbGQgInsjbW9udGhfc2hvcnR9QXVn
REM #IgogICAgbmV3ICJ7I21vbnRoX3Nob3J0fUFnbyIKICAgIG9sZCAieyNtb250aF9zaG9ydH1TZXAi
REM #CiAgICBuZXcgInsjbW9udGhfc2hvcnR9U2V0IgogICAgb2xkICJ7I21vbnRoX3Nob3J0fU9jdCIK
REM #ICAgIG5ldyAieyNtb250aF9zaG9ydH1PdXQiCiAgICBvbGQgInsjbW9udGhfc2hvcnR9Tm92Igog
REM #ICAgbmV3ICJ7I21vbnRoX3Nob3J0fU5vdiIKICAgIG9sZCAieyNtb250aF9zaG9ydH1EZWMiCiAg
REM #ICBuZXcgInsjbW9udGhfc2hvcnR9RGV6IgogICAgb2xkICJMYW5ndWFnZSBbdGV4dF0iCiAgICBu
REM #ZXcgIklkaW9tYSBbdGV4dF0iCiAgICBvbGQgIkltYWdlIFtpbmRleF0gb2YgW2NvdW50XSBsb2Nr
REM #ZWQuIgogICAgbmV3ICJJbWFnZW0gW2luZGV4XSBkZSBbY291bnRdIGJsb3F1ZWFkYS4iCiAgICBv
REM #bGQgInByZXYiCiAgICBuZXcgImFudC4iCiAgICBvbGQgIm5leHQiCiAgICBuZXcgInByw7N4LiIK
REM #ICAgIG9sZCAic2xpZGVzaG93IgogICAgbmV3ICJhcHJlc2VudGHDp8OjbyIKICAgIG9sZCAicmV0
REM #dXJuIgogICAgbmV3ICJ2b2x0YXIiCiAgICBvbGQgIkdyYXBoaWNzIEFjY2VsZXJhdGlvbiIKICAg
REM #IG5ldyAiQWNlbGVyYcOnw6NvIGdyw6FmaWNhIgogICAgb2xkICJBdXRvbWF0aWNhbGx5IENob29z
REM #ZSIKICAgIG5ldyAiRXNjb2xoZXIgYXV0b21hdGljYW1lbnRlIgogICAgb2xkICJGb3JjZSBBbmds
REM #ZS9EaXJlY3RYIFJlbmRlcmVyIgogICAgbmV3ICJGb3LDp2FyIHJlbmRlcml6YWRvciBBTkdMRS9E
REM #aXJlY3RYIgogICAgb2xkICJGb3JjZSBPcGVuR0wgUmVuZGVyZXIiCiAgICBuZXcgIkZvcsOnYXIg
REM #cmVuZGVyaXphZG9yIE9wZW5HTCIKICAgIG9sZCAiRm9yY2UgU29mdHdhcmUgUmVuZGVyZXIiCiAg
REM #ICBuZXcgIkZvcsOnYXIgcmVuZGVyaXphw6fDo28gcG9yIHNvZnR3YXJlIgogICAgb2xkICJDaGFu
REM #Z2VzIHdpbGwgdGFrZSBlZmZlY3QgdGhlIG5leHQgdGltZSB0aGlzIHByb2dyYW0gaXMgcnVuLiIK
REM #ICAgIG5ldyAiQXMgYWx0ZXJhw6fDtWVzIGVudHJhcsOjbyBlbSB2aWdvciBuYSBwcsOzeGltYSB2
REM #ZXogcXVlIG8gcHJvZ3JhbWEgZm9yIGluaWNpYWRvLiIKICAgIG9sZCAiUXVpdCIKICAgIG5ldyAi
REM #U2FpciIKICAgIG9sZCAiUmV0dXJuIgogICAgbmV3ICJWb2x0YXIiCiAgICBvbGQgIlBlcmZvcm1h
REM #bmNlIFdhcm5pbmciCiAgICBuZXcgIkF2aXNvIGRlIGRlc2VtcGVuaG8iCiAgICBvbGQgIlRoaXMg
REM #Y29tcHV0ZXIgaXMgdXNpbmcgc29mdHdhcmUgcmVuZGVyaW5nLiIKICAgIG5ldyAiRXN0ZSBjb21w
REM #dXRhZG9yIGVzdMOhIHVzYW5kbyByZW5kZXJpemHDp8OjbyBwb3Igc29mdHdhcmUuIgogICAgb2xk
REM #ICJUaGlzIGNvbXB1dGVyIGlzIG5vdCB1c2luZyBzaGFkZXJzLiIKICAgIG5ldyAiRXN0ZSBjb21w
REM #dXRhZG9yIG7Do28gZXN0w6EgdXNhbmRvIHNoYWRlcnMuIgogICAgb2xkICJUaGlzIGNvbXB1dGVy
REM #IGlzIGRpc3BsYXlpbmcgZ3JhcGhpY3Mgc2xvd2x5LiIKICAgIG5ldyAiRXN0ZSBjb21wdXRhZG9y
REM #IGVzdMOhIGV4aWJpbmRvIG9zIGdyw6FmaWNvcyBsZW50YW1lbnRlLiIKICAgIG9sZCAiVGhpcyBj
REM #b21wdXRlciBoYXMgYSBwcm9ibGVtIGRpc3BsYXlpbmcgZ3JhcGhpY3M6IFtwcm9ibGVtXS4iCiAg
REM #ICBuZXcgIkVzdGUgY29tcHV0YWRvciBlbmNvbnRyb3UgdW0gcHJvYmxlbWEgYW8gZXhpYmlyIG9z
REM #IGdyw6FmaWNvczogW3Byb2JsZW1dLiIKICAgIG9sZCAiSXRzIGdyYXBoaWNzIGRyaXZlcnMgbWF5
REM #IGJlIG91dCBvZiBkYXRlIG9yIG5vdCBvcGVyYXRpbmcgY29ycmVjdGx5LiBUaGlzIGNhbiBsZWFk
REM #IHRvIHNsb3cgb3IgaW5jb3JyZWN0IGdyYXBoaWNzIGRpc3BsYXkuIFVwZGF0aW5nIERpcmVjdFgg
REM #Y291bGQgZml4IHRoaXMgcHJvYmxlbS4iCiAgICBuZXcgIk9zIGRyaXZlcnMgZ3LDoWZpY29zIHBv
REM #ZGVtIGVzdGFyIGRlc2F0dWFsaXphZG9zIG91IG7Do28gZXN0YXIgZnVuY2lvbmFuZG8gY29ycmV0
REM #YW1lbnRlLiBJc3NvIHBvZGUgY2F1c2FyIHVtYSBleGliacOnw6NvIGxlbnRhIG91IGluY29ycmV0
REM #YSBkb3MgZ3LDoWZpY29zLiBBdHVhbGl6YXIgbyBEaXJlY3RYIHBvZGUgcmVzb2x2ZXIgbyBwcm9i
REM #bGVtYS4iCiAgICBvbGQgIkl0cyBncmFwaGljcyBkcml2ZXJzIG1heSBiZSBvdXQgb2YgZGF0ZSBv
REM #ciBub3Qgb3BlcmF0aW5nIGNvcnJlY3RseS4gVGhpcyBjYW4gbGVhZCB0byBzbG93IG9yIGluY29y
REM #cmVjdCBncmFwaGljcyBkaXNwbGF5LiIKICAgIG5ldyAiT3MgZHJpdmVycyBncsOhZmljb3MgcG9k
REM #ZW0gZXN0YXIgZGVzYXR1YWxpemFkb3Mgb3UgbsOjbyBlc3RhciBmdW5jaW9uYW5kbyBjb3JyZXRh
REM #bWVudGUuIElzc28gcG9kZSBjYXVzYXIgdW1hIGV4aWJpw6fDo28gbGVudGEgb3UgaW5jb3JyZXRh
REM #IGRvcyBncsOhZmljb3MuIgogICAgb2xkICJVcGRhdGUgRGlyZWN0WCIKICAgIG5ldyAiQXR1YWxp
REM #emFyIERpcmVjdFgiCiAgICBvbGQgIkNvbnRpbnVlLCBTaG93IHRoaXMgd2FybmluZyBhZ2FpbiIK
REM #ICAgIG5ldyAiQ29udGludWFyLCBtb3N0cmFyIGVzdGUgYXZpc28gbm92YW1lbnRlIgogICAgb2xk
REM #ICJDb250aW51ZSwgRG9uJ3Qgc2hvdyB3YXJuaW5nIGFnYWluIgogICAgbmV3ICJDb250aW51YXIs
REM #IG7Do28gbW9zdHJhciBlc3RlIGF2aXNvIG5vdmFtZW50ZSIKICAgIG9sZCAiVXBkYXRpbmcgRGly
REM #ZWN0WC4iCiAgICBuZXcgIkF0dWFsaXphbmRvIG8gRGlyZWN0WC4iCiAgICBvbGQgIkRpcmVjdFgg
REM #d2ViIHNldHVwIGhhcyBiZWVuIHN0YXJ0ZWQuIEl0IG1heSBzdGFydCBtaW5pbWl6ZWQgaW4gdGhl
REM #IHRhc2tiYXIuIFBsZWFzZSBmb2xsb3cgdGhlIHByb21wdHMgdG8gaW5zdGFsbCBEaXJlY3RYLiIK
REM #ICAgIG5ldyAiTyBpbnN0YWxhZG9yIHdlYiBkbyBEaXJlY3RYIGZvaSBpbmljaWFkby4gRWxlIHBv
REM #ZGUgc2VyIGFiZXJ0byBtaW5pbWl6YWRvIG5hIGJhcnJhIGRlIHRhcmVmYXMuIFNpZ2EgYXMgaW5z
REM #dHJ1w6fDtWVzIHBhcmEgaW5zdGFsYXIgbyBEaXJlY3RYLiIKICAgIG9sZCAie2J9Tm90ZTp7L2J9
REM #IE1pY3Jvc29mdCdzIERpcmVjdFggd2ViIHNldHVwIHByb2dyYW0gd2lsbCwgYnkgZGVmYXVsdCwg
REM #aW5zdGFsbCB0aGUgQmluZyB0b29sYmFyLiBJZiB5b3UgZG8gbm90IHdhbnQgdGhpcyB0b29sYmFy
REM #LCB1bmNoZWNrIHRoZSBhcHByb3ByaWF0ZSBib3guIgogICAgbmV3ICJ7Yn1PYnNlcnZhw6fDo286
REM #ey9ifSBvIGluc3RhbGFkb3Igd2ViIGRvIERpcmVjdFggZGEgTWljcm9zb2Z0LCBwb3IgcGFkcsOj
REM #bywgaW5zdGFsYXLDoSBhIGJhcnJhIGRlIGZlcnJhbWVudGFzIGRvIEJpbmcuIFNlIG7Do28gcXVp
REM #c2VyIGVzc2EgYmFycmEsIGRlc21hcnF1ZSBhIG9ww6fDo28gY29ycmVzcG9uZGVudGUuIgogICAg
REM #b2xkICJXaGVuIHNldHVwIGZpbmlzaGVzLCBwbGVhc2UgY2xpY2sgYmVsb3cgdG8gcmVzdGFydCB0
REM #aGlzIHByb2dyYW0uIgogICAgbmV3ICJRdWFuZG8gYSBpbnN0YWxhw6fDo28gdGVybWluYXIsIGNs
REM #aXF1ZSBhYmFpeG8gcGFyYSByZWluaWNpYXIgZXN0ZSBwcm9ncmFtYS4iCiAgICBvbGQgIlJlc3Rh
REM #cnQiCiAgICBuZXcgIlJlaW5pY2lhciIKICAgIG9sZCAiRW1wdHkgU2xvdC4iCiAgICBuZXcgIlNs
REM #b3QgdmF6aW8uIgogICAgb2xkICJQcmV2aW91cyIKICAgIG5ldyAiQW50ZXJpb3IiCiAgICBvbGQg
REM #Ik5leHQiCiAgICBuZXcgIlByw7N4aW1vIgogICAgb2xkICJKb3lzdGljayBNYXBwaW5nIgogICAg
REM #bmV3ICJNYXBlYW1lbnRvIGRvIGNvbnRyb2xlIgogICAgb2xkICJBbiBleGNlcHRpb24gaGFzIG9j
REM #Y3VycmVkLiIKICAgIG5ldyAiT2NvcnJldSB1bWEgZXhjZcOnw6NvLiIKICAgIG9sZCAiUm9sbGJh
REM #Y2siCiAgICBuZXcgIlJldHJvY2VkZXIiCiAgICBvbGQgIkF0dGVtcHRzIGEgcm9sbCBiYWNrIHRv
REM #IGEgcHJpb3IgdGltZSwgYWxsb3dpbmcgeW91IHRvIHNhdmUgb3IgY2hvb3NlIGEgZGlmZmVyZW50
REM #IGNob2ljZS4iCiAgICBuZXcgIlRlbnRhIHZvbHRhciBwYXJhIHVtIG1vbWVudG8gYW50ZXJpb3Is
REM #IHBlcm1pdGluZG8gc2FsdmFyIG91IGVzY29saGVyIHVtYSBvcMOnw6NvIGRpZmVyZW50ZS4iCiAg
REM #ICBvbGQgIklnbm9yZSIKICAgIG5ldyAiSWdub3JhciIKICAgIG9sZCAiSWdub3JlcyB0aGUgZXhj
REM #ZXB0aW9uLCBhbGxvd2luZyB5b3UgdG8gY29udGludWUuIFRoaXMgb2Z0ZW4gbGVhZHMgdG8gYWRk
REM #aXRpb25hbCBlcnJvcnMuIgogICAgbmV3ICJJZ25vcmEgYSBleGNlw6fDo28sIHBlcm1pdGluZG8g
REM #Y29udGludWFyLiBJc3NvIGZyZXF1ZW50ZW1lbnRlIGNhdXNhIGVycm9zIGFkaWNpb25haXMuIgog
REM #ICAgb2xkICJSZWxvYWQiCiAgICBuZXcgIlJlY2FycmVnYXIiCiAgICBvbGQgIlJlbG9hZHMgdGhl
REM #IGdhbWUgZnJvbSBkaXNrLCBzYXZpbmcgYW5kIHJlc3RvcmluZyBnYW1lIHN0YXRlIGlmIHBvc3Np
REM #YmxlLiIKICAgIG5ldyAiUmVjYXJyZWdhIG8gam9nbyBkbyBkaXNjbywgc2FsdmFuZG8gZSByZXN0
REM #YXVyYW5kbyBvIGVzdGFkbyBkbyBqb2dvIHF1YW5kbyBwb3Nzw612ZWwuIgogICAgb2xkICJPcGVu
REM #IFRyYWNlYmFjayIKICAgIG5ldyAiQWJyaXIgcmVsYXTDs3JpbyBkZSBlcnJvIgogICAgb2xkICJP
REM #cGVucyB0aGUgdHJhY2ViYWNrLnR4dCBmaWxlIGluIGEgdGV4dCBlZGl0b3IuIgogICAgbmV3ICJB
REM #YnJlIG8gYXJxdWl2byB0cmFjZWJhY2sudHh0IGVtIHVtIGVkaXRvciBkZSB0ZXh0by4iCiAgICBv
REM #bGQgIlF1aXRzIHRoZSBnYW1lLiIKICAgIG5ldyAiU2FpIGRvIGpvZ28uIgogICAgb2xkICJQYXJz
REM #aW5nIHRoZSBzY3JpcHQgZmFpbGVkLiIKICAgIG5ldyAiTsOjbyBmb2kgcG9zc8OtdmVsIGFuYWxp
REM #c2FyIG8gc2NyaXB0LiIKICAgIG9sZCAiT3BlbiBQYXJzZSBFcnJvcnMiCiAgICBuZXcgIkFicmly
REM #IGVycm9zIGRlIGFuw6FsaXNlIgogICAgb2xkICJPcGVucyB0aGUgZXJyb3JzLnR4dCBmaWxlIGlu
REM #IGEgdGV4dCBlZGl0b3IuIgogICAgbmV3ICJBYnJlIG8gYXJxdWl2byBlcnJvcnMudHh0IGVtIHVt
REM #IGVkaXRvciBkZSB0ZXh0by4iCiAgICBvbGQgIlByZXNzIDxlc2M+IHRvIGV4aXQgY29uc29sZS4g
REM #VHlwZSBoZWxwIGZvciBoZWxwLlxuIgogICAgbmV3ICJQcmVzc2lvbmUgPGVzYz4gcGFyYSBzYWly
REM #IGRvIGNvbnNvbGUuIERpZ2l0ZSBoZWxwIHBhcmEgb2J0ZXIgYWp1ZGEuXG4iCiAgICBvbGQgIlJl
REM #bidQeSBzY3JpcHQgZW5hYmxlZC4iCiAgICBuZXcgIlNjcmlwdCBkbyBSZW4nUHkgYXRpdmFkby4i
REM #CiAgICBvbGQgIlJlbidQeSBzY3JpcHQgZGlzYWJsZWQuIgogICAgbmV3ICJTY3JpcHQgZG8gUmVu
REM #J1B5IGRlc2F0aXZhZG8uIgogICAgb2xkICJoZWxwOiBzaG93IHRoaXMgaGVscCIKICAgIG5ldyAi
REM #aGVscDogbW9zdHJhIGVzdGEgYWp1ZGEiCiAgICBvbGQgImNvbW1hbmRzOlxuIgogICAgbmV3ICJj
REM #b21hbmRvczpcbiIKICAgIG9sZCAiIDxyZW5weSBzY3JpcHQgc3RhdGVtZW50PjogcnVuIHRoZSBz
REM #dGF0ZW1lbnRcbiIKICAgIG5ldyAiIDxpbnN0cnXDp8OjbyBkZSBzY3JpcHQgZG8gUmVuJ1B5Pjog
REM #ZXhlY3V0YSBhIGluc3RydcOnw6NvXG4iCiAgICBvbGQgIiA8cHl0aG9uIGV4cHJlc3Npb24gb3Ig
REM #c3RhdGVtZW50PjogcnVuIHRoZSBleHByZXNzaW9uIG9yIHN0YXRlbWVudCIKICAgIG5ldyAiIDxl
REM #eHByZXNzw6NvIG91IGluc3RydcOnw6NvIFB5dGhvbj46IGV4ZWN1dGEgYSBleHByZXNzw6NvIG91
REM #IGluc3RydcOnw6NvIgogICAgb2xkICJjbGVhcjogY2xlYXIgdGhlIGNvbnNvbGUgaGlzdG9yeSIK
REM #ICAgIG5ldyAiY2xlYXI6IGxpbXBhIG8gaGlzdMOzcmljbyBkbyBjb25zb2xlIgogICAgb2xkICJl
REM #eGl0OiBleGl0IHRoZSBjb25zb2xlIgogICAgbmV3ICJleGl0OiBzYWkgZG8gY29uc29sZSIKICAg
REM #IG9sZCAibG9hZCA8c2xvdD46IGxvYWRzIHRoZSBnYW1lIGZyb20gc2xvdCIKICAgIG5ldyAibG9h
REM #ZCA8c2xvdD46IGNhcnJlZ2EgbyBqb2dvIGRvIHNsb3QiCiAgICBvbGQgInNhdmUgPHNsb3Q+OiBz
REM #YXZlcyB0aGUgZ2FtZSBpbiBzbG90IgogICAgbmV3ICJzYXZlIDxzbG90Pjogc2FsdmEgbyBqb2dv
REM #IG5vIHNsb3QiCiAgICBvbGQgInJlbG9hZDogcmVsb2FkcyB0aGUgZ2FtZSwgcmVmcmVzaGluZyB0
REM #aGUgc2NyaXB0cyIKICAgIG5ldyAicmVsb2FkOiByZWNhcnJlZ2EgbyBqb2dvIGUgYXR1YWxpemEg
REM #b3Mgc2NyaXB0cyIKICAgIG9sZCAid2F0Y2ggPGV4cHJlc3Npb24+OiB3YXRjaCBhIHB5dGhvbiBl
REM #eHByZXNzaW9uIgogICAgbmV3ICJ3YXRjaCA8ZXhwcmVzc2lvbj46IG1vbml0b3JhIHVtYSBleHBy
REM #ZXNzw6NvIFB5dGhvbiIKICAgIG9sZCAidW53YXRjaCA8ZXhwcmVzc2lvbj46IHN0b3Agd2F0Y2hp
REM #bmcgYW4gZXhwcmVzc2lvbiIKICAgIG5ldyAidW53YXRjaCA8ZXhwcmVzc2lvbj46IHBhcmEgZGUg
REM #bW9uaXRvcmFyIHVtYSBleHByZXNzw6NvIgogICAgb2xkICJ1bndhdGNoYWxsOiBzdG9wIHdhdGNo
REM #aW5nIGFsbCBleHByZXNzaW9ucyIKICAgIG5ldyAidW53YXRjaGFsbDogcGFyYSBkZSBtb25pdG9y
REM #YXIgdG9kYXMgYXMgZXhwcmVzc8O1ZXMiCiAgICBvbGQgImp1bXAgPGxhYmVsPjoganVtcHMgdG8g
REM #bGFiZWwiCiAgICBuZXcgImp1bXAgPGxhYmVsPjogc2FsdGEgcGFyYSBvIGxhYmVsIgogICAgb2xk
REM #ICJkaXNwbGF5IgogICAgbmV3ICJleGliacOnw6NvIgogICAgb2xkICJ0cmFuc2l0aW9ucyIKICAg
REM #IG5ldyAidHJhbnNpw6fDtWVzIgogICAgb2xkICJza2lwIHRyYW5zaXRpb25zIgogICAgbmV3ICJw
REM #dWxhciB0cmFuc2nDp8O1ZXMiCiAgICBvbGQgInZpZGVvIHNwcml0ZXMiCiAgICBuZXcgInNwcml0
REM #ZXMgZGUgdsOtZGVvIgogICAgb2xkICJzaG93IGVtcHR5IHdpbmRvdyIKICAgIG5ldyAibW9zdHJh
REM #ciBqYW5lbGEgdmF6aWEiCiAgICBvbGQgInRleHQgc3BlZWQiCiAgICBuZXcgInZlbG9jaWRhZGUg
REM #ZG8gdGV4dG8iCiAgICBvbGQgImpveXN0aWNrIgogICAgbmV3ICJqb3lzdGljayIKICAgIG9sZCAi
REM #am95c3RpY2suLi4iCiAgICBuZXcgImpveXN0aWNrLi4uIgogICAgb2xkICJza2lwIgogICAgbmV3
REM #ICJhdmFuw6dhciIKICAgIG9sZCAic2tpcCB1bnNlZW4gW3RleHRdIgogICAgbmV3ICJhdmFuw6dh
REM #ciBvIHF1ZSBuw6NvIGZvaSB2aXN0byBbdGV4dF0iCiAgICBvbGQgInNraXAgdW5zZWVuIHRleHQi
REM #CiAgICBuZXcgImF2YW7Dp2FyIHRleHRvIG7Do28gdmlzdG8iCiAgICBvbGQgImJlZ2luIHNraXBw
REM #aW5nIgogICAgbmV3ICJjb21lw6dhciBhIGF2YW7Dp2FyIgogICAgb2xkICJhZnRlciBjaG9pY2Vz
REM #IgogICAgbmV3ICJhcMOzcyBhcyBlc2NvbGhhcyIKICAgIG9sZCAic2tpcCBhZnRlciBjaG9pY2Vz
REM #IgogICAgbmV3ICJhdmFuw6dhciBhcMOzcyBhcyBlc2NvbGhhcyIKICAgIG9sZCAiYXV0by1mb3J3
REM #YXJkIHRpbWUiCiAgICBuZXcgInRlbXBvIGRlIGF2YW7Dp28gYXV0b23DoXRpY28iCiAgICBvbGQg
REM #ImF1dG8tZm9yd2FyZCIKICAgIG5ldyAiYXZhbsOnbyBhdXRvbcOhdGljbyIKICAgIG9sZCAiQXV0
REM #byBmb3J3YXJkIgogICAgbmV3ICJBdmFuw6dvIGF1dG9tw6F0aWNvIgogICAgb2xkICJhdXRvLWZv
REM #cndhcmQgYWZ0ZXIgY2xpY2siCiAgICBuZXcgImF2YW7Dp28gYXV0b23DoXRpY28gYXDDs3MgbyBj
REM #bGlxdWUiCiAgICBvbGQgImF1dG9tYXRpYyBtb3ZlIgogICAgbmV3ICJtb3ZpbWVudG8gYXV0b23D
REM #oXRpY28iCiAgICBvbGQgIndhaXQgZm9yIHZvaWNlIgogICAgbmV3ICJhZ3VhcmRhciBhIHZveiIK
REM #ICAgIG9sZCAidm9pY2Ugc3VzdGFpbiIKICAgIG5ldyAibWFudGVyIGEgdm96IgogICAgb2xkICJz
REM #ZWxmIHZvaWNpbmciCiAgICBuZXcgInZveiBhdXRvbcOhdGljYSIKICAgIG9sZCAic2VsZiB2b2lj
REM #aW5nIHZvbHVtZSBkcm9wIgogICAgbmV3ICJyZWR1w6fDo28gZG8gdm9sdW1lIGRhIHZveiBhdXRv
REM #bcOhdGljYSIKICAgIG9sZCAiY2xpcGJvYXJkIHZvaWNpbmciCiAgICBuZXcgInZveiBkYSDDoXJl
REM #YSBkZSB0cmFuc2ZlcsOqbmNpYSIKICAgIG9sZCAiZGVidWcgdm9pY2luZyIKICAgIG5ldyAidm96
REM #IGRlIGRlcHVyYcOnw6NvIgogICAgb2xkICJlbXBoYXNpemUgYXVkaW8iCiAgICBuZXcgImVuZmF0
REM #aXphciDDoXVkaW8iCiAgICBvbGQgInJvbGxiYWNrIHNpZGUiCiAgICBuZXcgImxhZG8gZG8gcmV0
REM #cm9jZXNzbyIKICAgIG9sZCAiZ2wgcG93ZXJzYXZlIgogICAgbmV3ICJlY29ub21pYSBkZSBlbmVy
REM #Z2lhIGRhIEdQVSIKICAgIG9sZCAiZ2wgZnJhbWVyYXRlIgogICAgbmV3ICJ0YXhhIGRlIHF1YWRy
REM #b3MgZGEgR1BVIgogICAgb2xkICJnbCB0ZWFyaW5nIgogICAgbmV3ICJkZXNnYXJyYW1lbnRvIGRl
REM #IGltYWdlbSBkYSBHUFUiCiAgICBvbGQgImZvbnQgdHJhbnNmb3JtIgogICAgbmV3ICJ0cmFuc2Zv
REM #cm1hw6fDo28gZGEgZm9udGUiCiAgICBvbGQgImZvbnQgc2l6ZSIKICAgIG5ldyAidGFtYW5obyBk
REM #YSBmb250ZSIKICAgIG9sZCAiZm9udCBsaW5lIHNwYWNpbmciCiAgICBuZXcgImVzcGHDp2FtZW50
REM #byBlbnRyZSBsaW5oYXMiCiAgICBvbGQgInN5c3RlbSBjdXJzb3IiCiAgICBuZXcgImN1cnNvciBk
REM #byBzaXN0ZW1hIgogICAgb2xkICJyZW5kZXJlciBtZW51IgogICAgbmV3ICJtZW51IGRvIHJlbmRl
REM #cml6YWRvciIKICAgIG9sZCAiYWNjZXNzaWJpbGl0eSBtZW51IgogICAgbmV3ICJtZW51IGRlIGFj
REM #ZXNzaWJpbGlkYWRlIgogICAgb2xkICJoaWdoIGNvbnRyYXN0IHRleHQiCiAgICBuZXcgInRleHRv
REM #IGRlIGFsdG8gY29udHJhc3RlIgogICAgb2xkICJhdWRpbyB3aGVuIG1pbmltaXplZCIKICAgIG5l
REM #dyAiw6F1ZGlvIHF1YW5kbyBtaW5pbWl6YWRvIgogICAgb2xkICJhdWRpbyB3aGVuIHVuZm9jdXNl
REM #ZCIKICAgIG5ldyAiw6F1ZGlvIHF1YW5kbyBhIGphbmVsYSBuw6NvIGVzdGl2ZXIgZW0gZm9jbyIK
REM #ICAgIG9sZCAid2ViIGNhY2hlIHByZWxvYWQiCiAgICBuZXcgInByw6ktY2FycmVnYW1lbnRvIGRv
REM #IGNhY2hlIGRhIHdlYiIKICAgIG9sZCAidm9pY2UgYWZ0ZXIgZ2FtZSBtZW51IgogICAgbmV3ICJ2
REM #b3ogYXDDs3MgbyBtZW51IGRvIGpvZ28iCiAgICBvbGQgIm1haW4gdm9sdW1lIgogICAgbmV3ICJ2
REM #b2x1bWUgcHJpbmNpcGFsIgogICAgb2xkICJtdXNpYyB2b2x1bWUiCiAgICBuZXcgInZvbHVtZSBk
REM #YSBtw7pzaWNhIgogICAgb2xkICJzb3VuZCB2b2x1bWUiCiAgICBuZXcgInZvbHVtZSBkb3Mgc29u
REM #cyIKICAgIG9sZCAidm9pY2Ugdm9sdW1lIgogICAgbmV3ICJ2b2x1bWUgZGEgdm96IgogICAgb2xk
REM #ICJtdXRlIG1haW4iCiAgICBuZXcgInNpbGVuY2lhciB2b2x1bWUgcHJpbmNpcGFsIgogICAgb2xk
REM #ICJtdXRlIG11c2ljIgogICAgbmV3ICJzaWxlbmNpYXIgbcO6c2ljYSIKICAgIG9sZCAibXV0ZSBz
REM #b3VuZCIKICAgIG5ldyAic2lsZW5jaWFyIHNvbnMiCiAgICBvbGQgIm11dGUgdm9pY2UiCiAgICBu
REM #ZXcgInNpbGVuY2lhciB2b3oiCiAgICBvbGQgIm11dGUgYWxsIgogICAgbmV3ICJzaWxlbmNpYXIg
REM #dHVkbyIKICAgIG9sZCAicmVzdG9yZSB3aW5kb3cgcG9zaXRpb24iCiAgICBuZXcgInJlc3RhdXJh
REM #ciBwb3Npw6fDo28gZGEgamFuZWxhIgogICAgb2xkICJyZXNldCIKICAgIG5ldyAicmVkZWZpbmly
REM #IgogICAgb2xkICJzZWxmIHZvaWNpbmcgZW5hYmxlIgogICAgbmV3ICJ2b3ogYXV0b23DoXRpY2Eg
REM #YXRpdmFkYSIKICAgIG9sZCAic2VsZiB2b2ljaW5nIGRpc2FibGUiCiAgICBuZXcgInZveiBhdXRv
REM #bcOhdGljYSBkZXNhdGl2YWRhIgogICAgb2xkICJjbGlwYm9hcmQgdm9pY2luZyBlbmFibGUiCiAg
REM #ICBuZXcgInZveiBkYSDDoXJlYSBkZSB0cmFuc2ZlcsOqbmNpYSBhdGl2YWRhIgogICAgb2xkICJj
REM #bGlwYm9hcmQgdm9pY2luZyBkaXNhYmxlIgogICAgbmV3ICJ2b3ogZGEgw6FyZWEgZGUgdHJhbnNm
REM #ZXLDqm5jaWEgZGVzYXRpdmFkYSIKICAgIG9sZCAiZGVidWcgdm9pY2luZyBlbmFibGUiCiAgICBu
REM #ZXcgInZveiBkZSBkZXB1cmHDp8OjbyBhdGl2YWRhIgogICAgb2xkICJkZWJ1ZyB2b2ljaW5nIGRp
REM #c2FibGUiCiAgICBuZXcgInZveiBkZSBkZXB1cmHDp8OjbyBkZXNhdGl2YWRhIgogICAgb2xkICJD
REM #bGlwYm9hcmQgdm9pY2luZyBlbmFibGVkLiBQcmVzcyAnc2hpZnQrQycgdG8gZGlzYWJsZS4iCiAg
REM #ICBuZXcgIlZveiBkYSDDoXJlYSBkZSB0cmFuc2ZlcsOqbmNpYSBhdGl2YWRhLiBQcmVzc2lvbmUg
REM #J1NoaWZ0K0MnIHBhcmEgZGVzYXRpdsOhLWxhLiIKICAgIG9sZCAiU2VsZi12b2ljaW5nIHdvdWxk
REM #IHNheSBcIltyZW5weS5kaXNwbGF5LnR0cy5sYXN0XVwiLiBQcmVzcyAnYWx0K3NoaWZ0K1YnIHRv
REM #IGRpc2FibGUuIgogICAgbmV3ICJBIHZveiBhdXRvbcOhdGljYSBkaXJpYSBcIltyZW5weS5kaXNw
REM #bGF5LnR0cy5sYXN0XVwiLiBQcmVzc2lvbmUgJ0FsdCtTaGlmdCtWJyBwYXJhIGRlc2F0aXbDoS1s
REM #YS4iCiAgICBvbGQgIlNlbGYtdm9pY2luZyBlbmFibGVkLiBQcmVzcyAndicgdG8gZGlzYWJsZS4i
REM #CiAgICBuZXcgIlZveiBhdXRvbcOhdGljYSBhdGl2YWRhLiBQcmVzc2lvbmUgJ1YnIHBhcmEgZGVz
REM #YXRpdsOhLWxhLiIKICAgIG9sZCAiVGhlIFJlbidQeSBVcGRhdGVyIGlzIG5vdCBzdXBwb3J0ZWQg
REM #b24gbW9iaWxlIGRldmljZXMuIgogICAgbmV3ICJPIGF0dWFsaXphZG9yIGRvIFJlbidQeSBuw6Nv
REM #IMOpIGNvbXBhdMOtdmVsIGNvbSBkaXNwb3NpdGl2b3MgbcOzdmVpcy4iCiAgICBvbGQgIkFuIGVy
REM #cm9yIGlzIGJlaW5nIHNpbXVsYXRlZC4iCiAgICBuZXcgIlVtIGVycm8gZXN0w6Egc2VuZG8gc2lt
REM #dWxhZG8uIgogICAgb2xkICJFaXRoZXIgdGhpcyBwcm9qZWN0IGRvZXMgbm90IHN1cHBvcnQgdXBk
REM #YXRpbmcsIG9yIHRoZSB1cGRhdGUgc3RhdHVzIGZpbGUgd2FzIGRlbGV0ZWQuIgogICAgbmV3ICJF
REM #c3RlIHByb2pldG8gbsOjbyBvZmVyZWNlIHN1cG9ydGUgYSBhdHVhbGl6YcOnw7VlcyBvdSBvIGFy
REM #cXVpdm8gZGUgc3RhdHVzIGRhIGF0dWFsaXphw6fDo28gZm9pIGV4Y2x1w61kby4iCiAgICBvbGQg
REM #IlRoaXMgYWNjb3VudCBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gcGVyZm9ybSBhbiB1cGRh
REM #dGUuIgogICAgbmV3ICJFc3RhIGNvbnRhIG7Do28gdGVtIHBlcm1pc3PDo28gcGFyYSByZWFsaXph
REM #ciB1bWEgYXR1YWxpemHDp8Ojby4iCiAgICBvbGQgIlRoaXMgYWNjb3VudCBkb2VzIG5vdCBoYXZl
REM #IHBlcm1pc3Npb24gdG8gd3JpdGUgdGhlIHVwZGF0ZSBsb2cuIgogICAgbmV3ICJFc3RhIGNvbnRh
REM #IG7Do28gdGVtIHBlcm1pc3PDo28gcGFyYSBncmF2YXIgbyByZWdpc3RybyBkYSBhdHVhbGl6YcOn
REM #w6NvLiIKICAgIG9sZCAiQ291bGQgbm90IHZlcmlmeSB1cGRhdGUgc2lnbmF0dXJlLiIKICAgIG5l
REM #dyAiTsOjbyBmb2kgcG9zc8OtdmVsIHZlcmlmaWNhciBhIGFzc2luYXR1cmEgZGEgYXR1YWxpemHD
REM #p8Ojby4iCiAgICBvbGQgIlRoZSB1cGRhdGUgZmlsZSB3YXMgbm90IGRvd25sb2FkZWQuIgogICAg
REM #bmV3ICJPIGFycXVpdm8gZGUgYXR1YWxpemHDp8OjbyBuw6NvIGZvaSBiYWl4YWRvLiIKICAgIG9s
REM #ZCAiVGhlIHVwZGF0ZSBmaWxlIGRvZXMgbm90IGhhdmUgdGhlIGNvcnJlY3QgZGlnZXN0IC0gaXQg
REM #bWF5IGhhdmUgYmVlbiBjb3JydXB0ZWQuIgogICAgbmV3ICJPIGFycXVpdm8gZGUgYXR1YWxpemHD
REM #p8OjbyBuw6NvIHRlbSBvIGRpZ2VzdCBjb3JyZXRvOyBlbGUgcG9kZSBlc3RhciBjb3Jyb21waWRv
REM #LiIKICAgIG9sZCAiV2hpbGUgdW5wYWNraW5nIHt9LCB1bmtub3duIHR5cGUge30uIgogICAgbmV3
REM #ICJBbyBkZXNjb21wYWN0YXIgezB9LCB0aXBvIGRlc2NvbmhlY2lkbyB7MX0uIgogICAgb2xkICJV
REM #cGRhdGVyIgogICAgbmV3ICJBdHVhbGl6YWRvciIKICAgIG9sZCAiVGhpcyBwcm9ncmFtIGlzIHVw
REM #IHRvIGRhdGUuIgogICAgbmV3ICJFc3RlIHByb2dyYW1hIGVzdMOhIGF0dWFsaXphZG8uIgogICAg
REM #b2xkICJbdS52ZXJzaW9uXSBpcyBhdmFpbGFibGUuIERvIHlvdSB3YW50IHRvIGluc3RhbGwgaXQ/
REM #IgogICAgbmV3ICJbdS52ZXJzaW9uXSBlc3TDoSBkaXNwb27DrXZlbC4gRGVzZWphIGluc3RhbMOh
REM #LWxhPyIKICAgIG9sZCAiUHJlcGFyaW5nIHRvIGRvd25sb2FkIHRoZSB1cGRhdGVzLiIKICAgIG5l
REM #dyAiUHJlcGFyYW5kbyBwYXJhIGJhaXhhciBhcyBhdHVhbGl6YcOnw7Vlcy4iCiAgICBvbGQgIkRv
REM #d25sb2FkaW5nIHRoZSB1cGRhdGVzLiIKICAgIG5ldyAiQmFpeGFuZG8gYXMgYXR1YWxpemHDp8O1
REM #ZXMuIgogICAgb2xkICJVbnBhY2tpbmcgdGhlIHVwZGF0ZXMuIgogICAgbmV3ICJEZXNjb21wYWN0
REM #YW5kbyBhcyBhdHVhbGl6YcOnw7Vlcy4iCiAgICBvbGQgIlRoZSB1cGRhdGVzIGhhdmUgYmVlbiBp
REM #bnN0YWxsZWQuIFRoZSBwcm9ncmFtIHdpbGwgcmVzdGFydC4iCiAgICBuZXcgIkFzIGF0dWFsaXph
REM #w6fDtWVzIGZvcmFtIGluc3RhbGFkYXMuIE8gcHJvZ3JhbWEgc2Vyw6EgcmVpbmljaWFkby4iCiAg
REM #ICBvbGQgIlRoZSB1cGRhdGVzIGhhdmUgYmVlbiBpbnN0YWxsZWQuIgogICAgbmV3ICJBcyBhdHVh
REM #bGl6YcOnw7VlcyBmb3JhbSBpbnN0YWxhZGFzLiIKICAgIG9sZCAiVGhlIHVwZGF0ZXMgd2VyZSBj
REM #YW5jZWxsZWQuIgogICAgbmV3ICJBcyBhdHVhbGl6YcOnw7VlcyBmb3JhbSBjYW5jZWxhZGFzLiIK
REM #ICAgIG9sZCAiTm8gdXBkYXRlIG1ldGhvZHMgZm91bmQuIgogICAgbmV3ICJOZW5odW0gbcOpdG9k
REM #byBkZSBhdHVhbGl6YcOnw6NvIGZvaSBlbmNvbnRyYWRvLiIKICAgIG9sZCAiQ291bGQgbm90IGRv
REM #d25sb2FkIGZpbGUgbGlzdDogIgogICAgbmV3ICJOw6NvIGZvaSBwb3Nzw612ZWwgYmFpeGFyIGEg
REM #bGlzdGEgZGUgYXJxdWl2b3M6ICIKICAgIG9sZCAiRmlsZSBsaXN0IGRpZ2VzdCBkb2VzIG5vdCBt
REM #YXRjaC4iCiAgICBuZXcgIk8gZGlnZXN0IGRhIGxpc3RhIGRlIGFycXVpdm9zIG7Do28gY29ycmVz
REM #cG9uZGUuIgogICAgb2xkICJQcmVwYXJpbmcgdG8gZG93bmxvYWQgdGhlIGdhbWUgZGF0YS4iCiAg
REM #ICBuZXcgIlByZXBhcmFuZG8gcGFyYSBiYWl4YXIgb3MgZGFkb3MgZG8gam9nby4iCiAgICBvbGQg
REM #IkRvd25sb2FkaW5nIHRoZSBnYW1lIGRhdGEuIgogICAgbmV3ICJCYWl4YW5kbyBvcyBkYWRvcyBk
REM #byBqb2dvLiIKICAgIG9sZCAiVGhlIGdhbWUgZGF0YSBoYXMgYmVlbiBkb3dubG9hZGVkLiIKICAg
REM #IG5ldyAiT3MgZGFkb3MgZG8gam9nbyBmb3JhbSBiYWl4YWRvcy4iCiAgICBvbGQgIkFuIGVycm9y
REM #IG9jY3VyZWQgd2hlbiB0cnlpbmcgdG8gZG93bmxvYWQgZ2FtZSBkYXRhOiIKICAgIG5ldyAiT2Nv
REM #cnJldSB1bSBlcnJvIGFvIHRlbnRhciBiYWl4YXIgb3MgZGFkb3MgZG8gam9nbzoiCiAgICBvbGQg
REM #IlRoaXMgZ2FtZSBjYW5ub3QgYmUgcnVuIHVudGlsIHRoZSBnYW1lIGRhdGEgaGFzIGJlZW4gZG93
REM #bmxvYWRlZC4iCiAgICBuZXcgIkVzdGUgam9nbyBuw6NvIHBvZGUgc2VyIGV4ZWN1dGFkbyBhdMOp
REM #IHF1ZSBvcyBkYWRvcyBkbyBqb2dvIHNlamFtIGJhaXhhZG9zLiIKICAgIG9sZCAiUmV0cnkiCiAg
REM #ICBuZXcgIlRlbnRhciBub3ZhbWVudGUiCiAgICBvbGQgIlN5bmMgZG93bmxvYWRlZC4iCiAgICBu
REM #ZXcgIlNpbmNyb25pemHDp8OjbyBiYWl4YWRhLiIKICAgIG9sZCAiQ291bGQgbm90IGNvbm5lY3Qg
REM #dG8gdGhlIFJlbidQeSBTeW5jIHNlcnZlci4iCiAgICBuZXcgIk7Do28gZm9pIHBvc3PDrXZlbCBj
REM #b25lY3RhciBhbyBzZXJ2aWRvciBSZW4nUHkgU3luYy4iCiAgICBvbGQgIlRoZSBSZW4nUHkgU3lu
REM #YyBzZXJ2ZXIgdGltZWQgb3V0LiIKICAgIG5ldyAiTyBzZXJ2aWRvciBSZW4nUHkgU3luYyBhdGlu
REM #Z2l1IG8gdGVtcG8gbGltaXRlLiIKICAgIG9sZCAiQW4gdW5rbm93biBlcnJvciBvY2N1cnJlZCB3
REM #aGlsZSBjb25uZWN0aW5nIHRvIHRoZSBSZW4nUHkgU3luYyBzZXJ2ZXIuIgogICAgbmV3ICJPY29y
REM #cmV1IHVtIGVycm8gZGVzY29uaGVjaWRvIGFvIGNvbmVjdGFyIGFvIHNlcnZpZG9yIFJlbidQeSBT
REM #eW5jLiIKICAgIG9sZCAiVGhlIFJlbidQeSBTeW5jIHNlcnZlciBkb2VzIG5vdCBoYXZlIGEgY29w
REM #eSBvZiB0aGlzIHN5bmMuIFRoZSBzeW5jIElEIG1heSBiZSBpbnZhbGlkLCBvciBpdCBtYXkgaGF2
REM #ZSB0aW1lZCBvdXQuIgogICAgbmV3ICJPIHNlcnZpZG9yIFJlbidQeSBTeW5jIG7Do28gcG9zc3Vp
REM #IHVtYSBjw7NwaWEgZGVzdGEgc2luY3Jvbml6YcOnw6NvLiBPIElEIHBvZGUgc2VyIGludsOhbGlk
REM #byBvdSB0ZXIgZXhwaXJhZG8uIgogICAgb2xkICJQbGVhc2UgZW50ZXIgdGhlIHN5bmMgSUQgeW91
REM #IGdlbmVyYXRlZC5cbk5ldmVyIGVudGVyIGEgc3luYyBJRCB5b3UgZGlkbid0IGNyZWF0ZSB5b3Vy
REM #c2VsZi4iCiAgICBuZXcgIkRpZ2l0ZSBvIElEIGRlIHNpbmNyb25pemHDp8OjbyBxdWUgdm9jw6og
REM #Z2Vyb3UuXG5OdW5jYSBkaWdpdGUgdW0gSUQgZGUgc2luY3Jvbml6YcOnw6NvIHF1ZSBuw6NvIHRl
REM #bmhhIHNpZG8gY3JpYWRvIHBvciB2b2PDqi4iCiAgICBvbGQgIlRoZSBzeW5jIElEIGlzIG5vdCBp
REM #biB0aGUgY29ycmVjdCBmb3JtYXQuIgogICAgbmV3ICJPIElEIGRlIHNpbmNyb25pemHDp8OjbyBu
REM #w6NvIGVzdMOhIG5vIGZvcm1hdG8gY29ycmV0by4iCiAgICBvbGQgIlRoZSBzeW5jIGNvdWxkIG5v
REM #dCBiZSBkZWNyeXB0ZWQuIgogICAgbmV3ICJOw6NvIGZvaSBwb3Nzw612ZWwgZGVzY3JpcHRvZ3Jh
REM #ZmFyIGEgc2luY3Jvbml6YcOnw6NvLiIKICAgIG9sZCAiVGhlIHN5bmMgYmVsb25ncyB0byBhIGRp
REM #ZmZlcmVudCBnYW1lLiIKICAgIG5ldyAiRXN0YSBzaW5jcm9uaXphw6fDo28gcGVydGVuY2UgYSBv
REM #dXRybyBqb2dvLiIKICAgIG9sZCAiVGhlIHN5bmMgY29udGFpbnMgYSBmaWxlIHdpdGggYW4gaW52
REM #YWxpZCBuYW1lLiIKICAgIG5ldyAiRXN0YSBzaW5jcm9uaXphw6fDo28gY29udMOpbSB1bSBhcnF1
REM #aXZvIGNvbSBub21lIGludsOhbGlkby4iCiAgICBvbGQgIlRoaXMgd2lsbCB1cGxvYWQgeW91ciBz
REM #YXZlcyB0byB0aGUge2E9aHR0cHM6Ly9zeW5jLnJlbnB5Lm9yZ31SZW4nUHkgU3luYyBTZXJ2ZXJ7
REM #L2F9LlxuRG8geW91IHdhbnQgdG8gY29udGludWU/IgogICAgbmV3ICJJc3NvIGVudmlhcsOhIHNl
REM #dXMgc2F2ZXMgcGFyYSBvIHthPWh0dHBzOi8vc3luYy5yZW5weS5vcmd9U2Vydmlkb3IgUmVuJ1B5
REM #IFN5bmN7L2F9LlxuRGVzZWphIGNvbnRpbnVhcj8iCiAgICBvbGQgIkVudGVyIFN5bmMgSUQiCiAg
REM #ICBuZXcgIkRpZ2l0ZSBvIElEIGRlIHNpbmNyb25pemHDp8OjbyIKICAgIG9sZCAiVGhpcyB3aWxs
REM #IGNvbnRhY3QgdGhlIHthPWh0dHBzOi8vc3luYy5yZW5weS5vcmd9UmVuJ1B5IFN5bmMgU2VydmVy
REM #ey9hfS4iCiAgICBuZXcgIklzc28gZW50cmFyw6EgZW0gY29udGF0byBjb20gbyB7YT1odHRwczov
REM #L3N5bmMucmVucHkub3JnfVNlcnZpZG9yIFJlbidQeSBTeW5jey9hfS4iCiAgICBvbGQgIlN5bmMg
REM #U3VjY2VzcyIKICAgIG5ldyAiU2luY3Jvbml6YcOnw6NvIGNvbmNsdcOtZGEgY29tIHN1Y2Vzc28i
REM #CiAgICBvbGQgIlRoZSBTeW5jIElEIGlzOiIKICAgIG5ldyAiTyBJRCBkZSBzaW5jcm9uaXphw6fD
REM #o28gw6k6IgogICAgb2xkICJZb3UgY2FuIHVzZSB0aGlzIElEIHRvIGRvd25sb2FkIHlvdXIgc2F2
REM #ZSBvbiBhbm90aGVyIGRldmljZS5cblRoaXMgc3luYyB3aWxsIGV4cGlyZSBpbiBhbiBob3VyLlxu
REM #UmVuJ1B5IFN5bmMgaXMgc3VwcG9ydGVkIGJ5IHthPWh0dHBzOi8vd3d3LnJlbnB5Lm9yZy9zcG9u
REM #c29ycy5odG1sfVJlbidQeSdzIFNwb25zb3Jzey9hfS4iCiAgICBuZXcgIlZvY8OqIHBvZGUgdXNh
REM #ciBlc3RlIElEIHBhcmEgYmFpeGFyIHNldSBzYXZlIGVtIG91dHJvIGRpc3Bvc2l0aXZvLlxuRXN0
REM #YSBzaW5jcm9uaXphw6fDo28gZXhwaXJhcsOhIGVtIHVtYSBob3JhLlxuTyBSZW4nUHkgU3luYyDD
REM #qSBhcG9pYWRvIHBlbG9zIHthPWh0dHBzOi8vd3d3LnJlbnB5Lm9yZy9zcG9uc29ycy5odG1sfXBh
REM #dHJvY2luYWRvcmVzIGRvIFJlbidQeXsvYX0uIgogICAgb2xkICJTeW5jIEVycm9yIgogICAgbmV3
REM #ICJFcnJvIGRlIHNpbmNyb25pemHDp8OjbyIKICAgIG9sZCAiQ29udGFjdGluZyBBcHAgU3RvcmVc
REM #blBsZWFzZSBXYWl0Li4uIgogICAgbmV3ICJDb25lY3RhbmRvIMOgIEFwcCBTdG9yZVxuQWd1YXJk
REM #ZS4uLiIKICAgIG9sZCAiU3BlZWNoIEJ1YmJsZSBFZGl0b3IiCiAgICBuZXcgIkVkaXRvciBkZSBi
REM #YWzDtWVzIGRlIGZhbGEiCiAgICBvbGQgIihoaWRlKSIKICAgIG5ldyAiKG9jdWx0YXIpIgogICAg
REM #b2xkICIoY2xlYXIgcmV0YWluZWQgYnViYmxlcykiCiAgICBuZXcgIihsaW1wYXIgYmFsw7VlcyBt
REM #YW50aWRvcykiCiAgICBvbGQgIlRyYW5zbGF0aW9uIGlkZW50aWZpZXI6IFtpZGVudGlmaWVyXSIK
REM #ICAgIG5ldyAiSWRlbnRpZmljYWRvciBkZSB0cmFkdcOnw6NvOiBbaWRlbnRpZmllcl0iCiAgICBv
REM #bGQgIiB0cmFuc2xhdGVzIFt0bC5maWxlbmFtZV06W3RsLmxpbmVudW1iZXJdIgogICAgbmV3ICIg
REM #dHJhZHV6IFt0bC5maWxlbmFtZV06W3RsLmxpbmVudW1iZXJdIgogICAgb2xkICJUaGUgaW50ZXJh
REM #Y3RpdmUgZGlyZWN0b3IgaXMgbm90IGVuYWJsZWQgaGVyZS4iCiAgICBuZXcgIk8gZGlyZXRvciBp
REM #bnRlcmF0aXZvIG7Do28gZXN0w6EgaGFiaWxpdGFkbyBhcXVpLiIKICAgIG9sZCAiKHN0YXRlbWVu
REM #dCkiCiAgICBuZXcgIihpbnN0cnXDp8OjbykiCiAgICBvbGQgIih0YWcpIgogICAgbmV3ICIodGFn
REM #KSIKICAgIG9sZCAiKGF0dHJpYnV0ZXMpIgogICAgbmV3ICIoYXRyaWJ1dG9zKSIKICAgIG9sZCAi
REM #KHRyYW5zZm9ybSkiCiAgICBuZXcgIih0cmFuc2Zvcm1hw6fDo28pIgogICAgb2xkICIodHJhbnNp
REM #dGlvbikiCiAgICBuZXcgIih0cmFuc2nDp8OjbykiCiAgICBvbGQgIihjaGFubmVsKSIKICAgIG5l
REM #dyAiKGNhbmFsKSIKICAgIG9sZCAiKGZpbGVuYW1lKSIKICAgIG5ldyAiKG5vbWUgZG8gYXJxdWl2
REM #bykiCiAgICBvbGQgIkNoYW5nZSIKICAgIG5ldyAiQWx0ZXJhciIKICAgIG9sZCAiQWRkIgogICAg
REM #bmV3ICJBZGljaW9uYXIiCiAgICBvbGQgIkNhbmNlbCIKICAgIG5ldyAiQ2FuY2VsYXIiCiAgICBv
REM #bGQgIlJlbW92ZSIKICAgIG5ldyAiUmVtb3ZlciIKICAgIG9sZCAiU3RhdGVtZW50OiIKICAgIG5l
REM #dyAiSW5zdHJ1w6fDo286IgogICAgb2xkICJUYWc6IgogICAgbmV3ICJUYWc6IgogICAgb2xkICJB
REM #dHRyaWJ1dGVzOiIKICAgIG5ldyAiQXRyaWJ1dG9zOiIKICAgIG9sZCAiVHJhbnNmb3JtczoiCiAg
REM #ICBuZXcgIlRyYW5zZm9ybWHDp8O1ZXM6IgogICAgb2xkICJCZWhpbmQ6IgogICAgbmV3ICJBdHLD
REM #oXM6IgogICAgb2xkICJUcmFuc2l0aW9uOiIKICAgIG5ldyAiVHJhbnNpw6fDo286IgogICAgb2xk
REM #ICJDaGFubmVsOiIKICAgIG5ldyAiQ2FuYWw6IgogICAgb2xkICJBdWRpbyBGaWxlbmFtZToiCiAg
REM #ICBuZXcgIk5vbWUgZG8gYXJxdWl2byBkZSDDoXVkaW86IgogICAgb2xkICJDbGljayB0byB0b2dn
REM #bGUgYXR0cmlidXRlLCByaWdodCBjbGljayB0byB0b2dnbGUgbmVnYXRpdmUgYXR0cmlidXRlLiIK
REM #ICAgIG5ldyAiQ2xpcXVlIHBhcmEgYWx0ZXJuYXIgbyBhdHJpYnV0bzsgY2xpcXVlIGNvbSBvIGJv
REM #dMOjbyBkaXJlaXRvIHBhcmEgYWx0ZXJuYXIgbyBhdHJpYnV0byBuZWdhdGl2by4iCiAgICBvbGQg
REM #IkNsaWNrIHRvIHNldCB0cmFuc2Zvcm0sIHJpZ2h0IGNsaWNrIHRvIGFkZCB0byB0cmFuc2Zvcm0g
REM #bGlzdC4iCiAgICBuZXcgIkNsaXF1ZSBwYXJhIGRlZmluaXIgYSB0cmFuc2Zvcm1hw6fDo287IGNs
REM #aXF1ZSBjb20gbyBib3TDo28gZGlyZWl0byBwYXJhIGFkaWNpb27DoS1sYSDDoCBsaXN0YSBkZSB0
REM #cmFuc2Zvcm1hw6fDtWVzLiIKICAgIG9sZCAiQ2xpY2sgdG8gc2V0LCByaWdodCBjbGljayB0byBh
REM #ZGQgdG8gYmVoaW5kIGxpc3QuIgogICAgbmV3ICJDbGlxdWUgcGFyYSBkZWZpbmlyOyBjbGlxdWUg
REM #Y29tIG8gYm90w6NvIGRpcmVpdG8gcGFyYSBhZGljaW9uw6EtbG8gw6AgbGlzdGEgZGUgaXRlbnMg
REM #YXRyw6FzLiIKICAgIG9sZCAiQ3VzdG9taXplIGRpcmVjdG9yLnRyYW5zZm9ybXMgdG8gYWRkIG1v
REM #cmUgdHJhbnNmb3Jtcy4iCiAgICBuZXcgIlBlcnNvbmFsaXplIGRpcmVjdG9yLnRyYW5zZm9ybXMg
REM #cGFyYSBhZGljaW9uYXIgbWFpcyB0cmFuc2Zvcm1hw6fDtWVzLiIKICAgIG9sZCAiQ2xpY2sgdG8g
REM #c2V0LiIKICAgIG5ldyAiQ2xpcXVlIHBhcmEgZGVmaW5pci4iCiAgICBvbGQgIkN1c3RvbWl6ZSBk
REM #aXJlY3Rvci50cmFuc2l0aW9ucyB0byBhZGQgbW9yZSB0cmFuc2l0aW9ucy4iCiAgICBuZXcgIlBl
REM #cnNvbmFsaXplIGRpcmVjdG9yLnRyYW5zaXRpb25zIHBhcmEgYWRpY2lvbmFyIG1haXMgdHJhbnNp
REM #w6fDtWVzLiIKICAgIG9sZCAiQ3VzdG9taXplIGRpcmVjdG9yLmF1ZGlvX2NoYW5uZWxzIHRvIGFk
REM #ZCBtb3JlIGNoYW5uZWxzLiIKICAgIG5ldyAiUGVyc29uYWxpemUgZGlyZWN0b3IuYXVkaW9fY2hh
REM #bm5lbHMgcGFyYSBhZGljaW9uYXIgbWFpcyBjYW5haXMuIgogICAgb2xkICJEZXZlbG9wZXIgTWVu
REM #dSIKICAgIG5ldyAiTWVudSBkbyBkZXNlbnZvbHZlZG9yIgogICAgb2xkICJSZWxvYWQgR2FtZSAo
REM #U2hpZnQrUikiCiAgICBuZXcgIlJlY2FycmVnYXIgam9nbyAoU2hpZnQrUikiCiAgICBvbGQgIlZh
REM #cmlhYmxlIFZpZXdlciIKICAgIG5ldyAiVmlzdWFsaXphZG9yIGRlIHZhcmnDoXZlaXMiCiAgICBv
REM #bGQgIlRoZW1lIFRlc3QiCiAgICBuZXcgIlRlc3RlIGRlIHRlbWEiCiAgICBvbGQgIkltYWdlIExv
REM #Y2F0aW9uIFBpY2tlciIKICAgIG5ldyAiU2VsZXRvciBkZSBwb3Npw6fDo28gZGEgaW1hZ2VtIgog
REM #ICAgb2xkICJGaWxlbmFtZSBMaXN0IgogICAgbmV3ICJMaXN0YSBkZSBhcnF1aXZvcyIKICAgIG9s
REM #ZCAiVW5kZWZpbmVkIEltYWdlcyIKICAgIG5ldyAiSW1hZ2VucyBpbmRlZmluaWRhcyIKICAgIG9s
REM #ZCAiTW91c2UgcG9zaXRpb246ICVyIgogICAgbmV3ICJQb3Npw6fDo28gZG8gbW91c2U6ICVyIgog
REM #ICAgb2xkICJSaWdodC1jbGljayBvciBlc2NhcGUgdG8gcXVpdC4iCiAgICBuZXcgIkNsaXF1ZSBj
REM #b20gbyBib3TDo28gZGlyZWl0byBvdSBwcmVzc2lvbmUgRXNjYXBlIHBhcmEgc2Fpci4iCiAgICBv
REM #bGQgIkRvbmUiCiAgICBuZXcgIkNvbmNsdcOtZG8iCiAgICBvbGQgIkNvbnNvbGUgKFNoaWZ0K08p
REM #IgogICAgbmV3ICJDb25zb2xlIChTaGlmdCtPKSIKICAgIG9sZCAiU2hvdyBJbWFnZSBMb2FkIExv
REM #ZyIKICAgIG5ldyAiTW9zdHJhciByZWdpc3RybyBkZSBjYXJyZWdhbWVudG8gZGUgaW1hZ2VucyIK
REM #ICAgIG9sZCAiSGlkZSBJbWFnZSBMb2FkIExvZyIKICAgIG5ldyAiT2N1bHRhciByZWdpc3RybyBk
REM #ZSBjYXJyZWdhbWVudG8gZGUgaW1hZ2VucyIKICAgIG9sZCAiTm8gdmFyaWFibGVzIGhhdmUgY2hh
REM #bmdlZCBzaW5jZSB0aGUgZ2FtZSBzdGFydGVkLiIKICAgIG5ldyAiTmVuaHVtYSB2YXJpw6F2ZWwg
REM #bXVkb3UgZGVzZGUgbyBpbsOtY2lvIGRvIGpvZ28uIgogICAgb2xkICJSZXR1cm4gdG8gdGhlIGRl
REM #dmVsb3BlciBtZW51IgogICAgbmV3ICJWb2x0YXIgYW8gbWVudSBkbyBkZXNlbnZvbHZlZG9yIgog
REM #ICAgb2xkICJSZWN0YW5nbGU6ICVyIgogICAgbmV3ICJSZXTDom5ndWxvOiAlciIKICAgIG9sZCAi
REM #RGlzcGxheWFibGUgSW5zcGVjdG9yIgogICAgbmV3ICJJbnNwZXRvciBkZSBkaXNwbGF5YWJsZXMi
REM #CiAgICBvbGQgIk5vdGhpbmcgdG8gaW5zcGVjdC4iCiAgICBuZXcgIk5hZGEgcGFyYSBpbnNwZWNp
REM #b25hci4iCiAgICBvbGQgIlNpemUiCiAgICBuZXcgIlRhbWFuaG8iCiAgICBvbGQgIlN0eWxlIgog
REM #ICAgbmV3ICJFc3RpbG8iCiAgICBvbGQgIkxvY2F0aW9uIgogICAgbmV3ICJMb2NhbGl6YcOnw6Nv
REM #IgogICAgb2xkICJNaXNzaW5nIEltYWdlcyIKICAgIG5ldyAiSW1hZ2VucyBhdXNlbnRlcyIKICAg
REM #IG9sZCAie2J9TWlzc2luZyBJbWFnZXN7L2J9IgogICAgbmV3ICJ7Yn1JbWFnZW5zIGF1c2VudGVz
REM #ey9ifSIKICAgIG9sZCAiUmVjdGFuZ2xlIGNvcGllZCB0byBjbGlwYm9hcmQuIgogICAgbmV3ICJS
REM #ZXTDom5ndWxvIGNvcGlhZG8gcGFyYSBhIMOhcmVhIGRlIHRyYW5zZmVyw6puY2lhLiIKICAgIG9s
REM #ZCAiUG9zaXRpb24gY29waWVkIHRvIGNsaXBib2FyZC4iCiAgICBuZXcgIlBvc2nDp8OjbyBjb3Bp
REM #YWRhIHBhcmEgYSDDoXJlYSBkZSB0cmFuc2ZlcsOqbmNpYS4iCiAgICBvbGQgIlN0YXJ0IEdhbWUi
REM #CiAgICBuZXcgIkluaWNpYXIgam9nbyIKICAgIG9sZCAiTG9hZCBHYW1lIgogICAgbmV3ICJDYXJy
REM #ZWdhciBqb2dvIgogICAgb2xkICJQcmVmZXJlbmNlcyIKICAgIG5ldyAiQ29uZmlndXJhw6fDtWVz
REM #IgogICAgb2xkICJIZWxwIgogICAgbmV3ICJBanVkYSIKICAgIG9sZCAiU2F2ZSBHYW1lIgogICAg
REM #bmV3ICJTYWx2YXIgam9nbyIKICAgIG9sZCAiTWFpbiBNZW51IgogICAgbmV3ICJNZW51IFByaW5j
REM #aXBhbCIKICAgIG9sZCAiU3RhcnQiCiAgICBuZXcgIkluaWNpYXIiCiAgICBvbGQgIk5ldyBHYW1l
REM #IgogICAgbmV3ICJOb3ZvIGpvZ28iCiAgICBvbGQgIkxvYWQiCiAgICBuZXcgIkNhcnJlZ2FyIgog
REM #ICAgb2xkICJTYXZlIgogICAgbmV3ICJTYWx2YXIiCiAgICBvbGQgIkhpc3RvcnkiCiAgICBuZXcg
REM #Ikhpc3TDs3JpY28iCiAgICBvbGQgIkFib3V0IgogICAgbmV3ICJTb2JyZSIKICAgIG9sZCAiUXVp
REM #dCBHYW1lIgogICAgbmV3ICJTYWlyIGRvIGpvZ28iCiAgICBvbGQgIkV4aXQiCiAgICBuZXcgIlNh
REM #aXIiCiAgICBvbGQgIkV4aXQgR2FtZSIKICAgIG5ldyAiU2FpciBkbyBqb2dvIgogICAgb2xkICJC
REM #YWNrIgogICAgbmV3ICJWb2x0YXIiCiAgICBvbGQgIkVuZCBSZXBsYXkiCiAgICBuZXcgIkVuY2Vy
REM #cmFyIHJlcGxheSIKICAgIG9sZCAiQ29udGludWUiCiAgICBuZXcgIkNvbnRpbnVhciIKICAgIG9s
REM #ZCAiWWVzIgogICAgbmV3ICJTaW0iCiAgICBvbGQgIk5vIgogICAgbmV3ICJOw6NvIgogICAgb2xk
REM #ICJXaW5kb3ciCiAgICBuZXcgIkphbmVsYSIKICAgIG9sZCAiRnVsbHNjcmVlbiIKICAgIG5ldyAi
REM #VGVsYSBjaGVpYSIKICAgIG9sZCAiRnVsbCBTY3JlZW4iCiAgICBuZXcgIlRlbGEgY2hlaWEiCiAg
REM #ICBvbGQgIldpbmRvd2VkIgogICAgbmV3ICJFbSBqYW5lbGEiCiAgICBvbGQgIlVuc2VlbiBUZXh0
REM #IgogICAgbmV3ICJUZXh0byBuw6NvIHZpc3RvIgogICAgb2xkICJBZnRlciBDaG9pY2VzIgogICAg
REM #bmV3ICJBcMOzcyBlc2NvbGhhcyIKICAgIG9sZCAiVGV4dCBTcGVlZCIKICAgIG5ldyAiVmVsb2Np
REM #ZGFkZSBkbyB0ZXh0byIKICAgIG9sZCAiQXV0by1Gb3J3YXJkIFRpbWUiCiAgICBuZXcgIlRlbXBv
REM #IGRlIGF2YW7Dp28gYXV0b23DoXRpY28iCiAgICBvbGQgIkF1dG8gRm9yd2FyZCIKICAgIG5ldyAi
REM #QXZhbsOnbyBhdXRvbcOhdGljbyIKICAgIG9sZCAiTXVzaWMgVm9sdW1lIgogICAgbmV3ICJWb2x1
REM #bWUgZGEgbcO6c2ljYSIKICAgIG9sZCAiU291bmQgVm9sdW1lIgogICAgbmV3ICJWb2x1bWUgZG9z
REM #IHNvbnMiCiAgICBvbGQgIlZvaWNlIFZvbHVtZSIKICAgIG5ldyAiVm9sdW1lIGRhIHZveiIKICAg
REM #IG9sZCAiTXV0ZSBBbGwiCiAgICBuZXcgIlNpbGVuY2lhciB0dWRvIgogICAgb2xkICJNdXRlIE1h
REM #aW4iCiAgICBuZXcgIlNpbGVuY2lhciB2b2x1bWUgcHJpbmNpcGFsIgogICAgb2xkICJNdXRlIE11
REM #c2ljIgogICAgbmV3ICJTaWxlbmNpYXIgbcO6c2ljYSIKICAgIG9sZCAiTXV0ZSBTb3VuZCIKICAg
REM #IG5ldyAiU2lsZW5jaWFyIHNvbnMiCiAgICBvbGQgIk11dGUgVm9pY2UiCiAgICBuZXcgIlNpbGVu
REM #Y2lhciB2b3oiCiAgICBvbGQgIlBhZ2Uge30iCiAgICBuZXcgIlDDoWdpbmEge30iCiAgICBvbGQg
REM #IkF1dG9tYXRpYyBzYXZlcyIKICAgIG5ldyAiU2FsdmFtZW50b3MgYXV0b23DoXRpY29zIgogICAg
REM #b2xkICJRdWljayBzYXZlcyIKICAgIG5ldyAiU2FsdmFtZW50b3MgcsOhcGlkb3MiCiAgICBvbGQg
REM #ImVtcHR5IHNsb3QiCiAgICBuZXcgInNsb3QgdmF6aW8iCiAgICBvbGQgIlVwbG9hZCBTeW5jIgog
REM #ICAgbmV3ICJFbnZpYXIgc2luY3Jvbml6YcOnw6NvIgogICAgb2xkICJEb3dubG9hZCBTeW5jIgog
REM #ICAgbmV3ICJCYWl4YXIgc2luY3Jvbml6YcOnw6NvIgogICAgb2xkICJWZXJzaW9uIFtjb25maWcu
REM #dmVyc2lvbiF0XVxuIgogICAgbmV3ICJWZXJzw6NvIFtjb25maWcudmVyc2lvbiF0XVxuIgogICAg
REM #b2xkICJNYWRlIHdpdGgge2E9aHR0cHM6Ly93d3cucmVucHkub3JnL31SZW4nUHl7L2F9IFtyZW5w
REM #eS52ZXJzaW9uX29ubHldLlxuXG5bcmVucHkubGljZW5zZSF0XSIKICAgIG5ldyAiRmVpdG8gY29t
REM #IHthPWh0dHBzOi8vd3d3LnJlbnB5Lm9yZy99UmVuJ1B5ey9hfSBbcmVucHkudmVyc2lvbl9vbmx5
REM #XS5cblxuW3JlbnB5LmxpY2Vuc2UhdF0iCiAgICBvbGQgIlJlbmRlcmVyIgogICAgbmV3ICJSZW5k
REM #ZXJpemFkb3IiCiAgICBvbGQgIkZvcmNlIEdMMiBSZW5kZXJlciIKICAgIG5ldyAiRm9yw6dhciBy
REM #ZW5kZXJpemFkb3IgR0wyIgogICAgb2xkICJGb3JjZSBBTkdMRTIgUmVuZGVyZXIiCiAgICBuZXcg
REM #IkZvcsOnYXIgcmVuZGVyaXphZG9yIEFOR0xFMiIKICAgIG9sZCAiRm9yY2UgR0xFUzIgUmVuZGVy
REM #ZXIiCiAgICBuZXcgIkZvcsOnYXIgcmVuZGVyaXphZG9yIEdMRVMyIgogICAgb2xkICJHYW1lcGFk
REM #IgogICAgbmV3ICJDb250cm9sZSIKICAgIG9sZCAiRW5hYmxlIChObyBCbG9ja2xpc3QpIgogICAg
REM #bmV3ICJBdGl2YXIgKHNlbSBibG9xdWVpbykiCiAgICBvbGQgIkNhbGlicmF0ZSIKICAgIG5ldyAi
REM #Q2FsaWJyYXIiCiAgICBvbGQgIlBvd2Vyc2F2ZSIKICAgIG5ldyAiRWNvbm9taWEgZGUgZW5lcmdp
REM #YSIKICAgIG9sZCAiRnJhbWVyYXRlIgogICAgbmV3ICJUYXhhIGRlIHF1YWRyb3MiCiAgICBvbGQg
REM #IlNjcmVlbiIKICAgIG5ldyAiVGVsYSIKICAgIG9sZCAiVGVhcmluZyIKICAgIG5ldyAiUmFzZ29z
REM #IGRlIHRlbGEiCiAgICBvbGQgIlRoaXMgZ2FtZSByZXF1aXJlcyB1c2Ugb2YgR0wyIHRoYXQgY2Fu
REM #J3QgYmUgaW5pdGlhbGlzZWQuIgogICAgbmV3ICJFc3RlIGpvZ28gcmVxdWVyIG8gdXNvIGRlIEdM
REM #MiwgcXVlIG7Do28gcMO0ZGUgc2VyIGluaWNpYWxpemFkby4iCiAgICBvbGQgIkRlamFWdSBTYW5z
REM #IgogICAgbmV3ICJEZWphVnUgU2FucyIKICAgIG9sZCAiT3BlbmR5c2xleGljIgogICAgbmV3ICJP
REM #cGVuZHlzbGV4aWMiCiAgICBvbGQgIktlcm5pbmciCiAgICBuZXcgIktlcm5pbmciCiAgICBvbGQg
REM #IlNlbGYtVm9pY2luZyBhbmQgQXVkaW8iCiAgICBuZXcgIlZveiBhdXRvbcOhdGljYSBlIMOhdWRp
REM #byIKICAgIG9sZCAiUHJlc3MgUiB0byByZXNldCBhbGwgc2VsZi12b2ljaW5nIHNldHRpbmdzIHRv
REM #IHRoZWlyIGRlZmF1bHQgdmFsdWVzLCBhbmQgZW5hYmxlIHNlbGYtdm9pY2luZy4iCiAgICBuZXcg
REM #IlByZXNzaW9uZSBSIHBhcmEgcmVkZWZpbmlyIHRvZGFzIGFzIGNvbmZpZ3VyYcOnw7VlcyBkZSB2
REM #b3ogYXV0b23DoXRpY2EgcGFyYSBvcyB2YWxvcmVzIHBhZHLDo28gZSBhdGl2YXIgYSB2b3ogYXV0
REM #b23DoXRpY2EuIgogICAgb2xkICJTZWxmLXZvaWNpbmcgc2V0dGluZ3MgcmVzZXQuIgogICAgbmV3
REM #ICJDb25maWd1cmHDp8O1ZXMgZGUgdm96IGF1dG9tw6F0aWNhIHJlZGVmaW5pZGFzLiIKICAgIG9s
REM #ZCAiU2VsZi1Wb2ljaW5nIFNwZWVkIgogICAgbmV3ICJWZWxvY2lkYWRlIGRhIHZveiBhdXRvbcOh
REM #dGljYSIKICAgIG9sZCAiTGFuZ3VhZ2UiCiAgICBuZXcgIklkaW9tYSIKICAgIG9sZCAiU2VsZWN0
REM #IEdhbWVwYWQgdG8gQ2FsaWJyYXRlIgogICAgbmV3ICJTZWxlY2lvbmUgbyBjb250cm9sZSBwYXJh
REM #IGNhbGlicmFyIgogICAgb2xkICJObyBHYW1lcGFkcyBBdmFpbGFibGUiCiAgICBuZXcgIk5lbmh1
REM #bSBjb250cm9sZSBkaXNwb27DrXZlbCIKICAgIG9sZCAiQ2FsaWJyYXRpbmcgW25hbWVdIChbaV0v
REM #W3RvdGFsXSkiCiAgICBuZXcgIkNhbGlicmFuZG8gW25hbWVdIChbaV0vW3RvdGFsXSkiCiAgICBv
REM #bGQgIlByZXNzIG9yIG1vdmUgdGhlICdbY29udHJvbCFzXScgW2tpbmRdLiIKICAgIG5ldyAiUHJl
REM #c3Npb25lIG91IG1vdmEgbyAnW2NvbnRyb2whc10nIFtraW5kXS4iCiAgICBvbGQgIlNraXAgKEEp
REM #IgogICAgbmV3ICJBdmFuw6dhciAoQSkiCiAgICBvbGQgIkJhY2sgKEIpIgogICAgbmV3ICJWb2x0
REM #YXIgKEIpIgogICAgb2xkICJNb25vIEF1ZGlvIgogICAgbmV3ICLDgXVkaW8gbW9ubyIKCiAgICBv
REM #bGQgIlNlbGYtVm9pY2luZyBWb2ljZSIKICAgIG5ldyAiVm96IHVzYWRhIHBlbGEgdm96IGF1dG9t
REM #w6F0aWNhIgoKICAgIG9sZCAiVGV4dCIKICAgIG5ldyAiVGV4dG8iCgogICAgb2xkICJBY2Nlc3Np
REM #YmlsaXR5IE1lbnUuIFVzZSB1cCBhbmQgZG93biBhcnJvd3MgdG8gbmF2aWdhdGUsIGFuZCBlbnRl
REM #ciB0byBhY3RpdmF0ZSBidXR0b25zIGFuZCBiYXJzLiBQcmVzcyBSIHRvIHJlc2V0IHNlbGYtdm9p
REM #Y2luZyBzZXR0aW5ncyB0byB0aGVpciBkZWZhdWx0IHZhbHVlcyBhbmQgZW5hYmxlIHNlbGYtdm9p
REM #Y2luZy4iCiAgICBuZXcgIk1lbnUgZGUgYWNlc3NpYmlsaWRhZGUuIFVzZSBhcyBzZXRhcyBwYXJh
REM #IGNpbWEgZSBwYXJhIGJhaXhvIHBhcmEgbmF2ZWdhciBlIEVudGVyIHBhcmEgYXRpdmFyIGJvdMO1
REM #ZXMgZSBiYXJyYXMuIFByZXNzaW9uZSBSIHBhcmEgcmVkZWZpbmlyIGFzIGNvbmZpZ3VyYcOnw7Vl
REM #cyBkZSB2b3ogYXV0b23DoXRpY2EgZSBhdGl2w6EtbGEuIgoKICAgIG9sZCAiVG91Y2ggdG8gcGxh
REM #eSB0aGUgdmlkZW8uIgogICAgbmV3ICJUb3F1ZSBwYXJhIHJlcHJvZHV6aXIgbyB2w61kZW8uIgoK
REM #ICAgIG9sZCAiSW1hZ2UgQXR0cmlidXRlcyIKICAgIG5ldyAiQXRyaWJ1dG9zIGRhIGltYWdlbSIK
REM #CiAgICBvbGQgIkhpZGUgZGVsZXRlZCIKICAgIG5ldyAiT2N1bHRhciBleGNsdcOtZG9zIgoKICAg
REM #IG9sZCAiU2hvdyBkZWxldGVkIgogICAgbmV3ICJNb3N0cmFyIGV4Y2x1w61kb3MiCgogICAgIyAt
REM #LS0gQ2F0w6Fsb2dvIHVuaXZlcnNhbCBEREFDOiBsZWdhZG8gUmVuJ1B5IDYgKyBtw7NkdWxvcyBS
REM #ZW4nUHkgNy84IC0tLQogICAgb2xkICJXaGlsZSBSZW4nUHkgZ2FtZXMgbWF5IGJlIHBsYXlhYmxl
REM #IHdpdGhvdXQgdGhlIHJlbnB5IG1vZHVsZSwgc29tZSBmZWF0dXJlcyBtYXkgYmUgZGlzYWJsZWQu
REM #IEZvciBtb3JlIGluZm9ybWF0aW9uLCByZWFkIHRoZSBtb2R1bGUvUkVBRE1FLnR4dCBmaWxlIG9y
REM #IGdvIHRvIGh0dHA6Ly93d3cuYmlzaG91am8udXMvcmVucHkvLiIKICAgIG5ldyAiRW1ib3JhIGpv
REM #Z29zIFJlbidQeSBwb3NzYW0gZnVuY2lvbmFyIHNlbSBvIG3Ds2R1bG8gcmVucHksIGFsZ3VucyBy
REM #ZWN1cnNvcyBwb2RlbSBzZXIgZGVzYXRpdmFkb3MuIFBhcmEgbWFpcyBpbmZvcm1hw6fDtWVzLCBs
REM #ZWlhIG1vZHVsZS9SRUFETUUudHh0IG91IGFjZXNzZSBodHRwOi8vd3d3LmJpc2hvdWpvLnVzL3Jl
REM #bnB5Ly4iCiAgICBvbGQgInJlbnB5IG1vZHVsZSBub3QgZm91bmQuIgogICAgbmV3ICJNw7NkdWxv
REM #IHJlbnB5IG7Do28gZW5jb250cmFkby4iCiAgICBvbGQgIlRoZSByZW5weSBtb2R1bGUgY291bGQg
REM #bm90IGJlIGxvYWRlZCBvbiB5b3VyIHN5c3RlbS4iCiAgICBuZXcgIk8gbcOzZHVsbyByZW5weSBu
REM #w6NvIHDDtGRlIHNlciBjYXJyZWdhZG8gbm8gc2V1IHNpc3RlbWEuIgogICAgb2xkICJPbGQgcmVu
REM #cHkgbW9kdWxlIGZvdW5kLiIKICAgIG5ldyAiTcOzZHVsbyByZW5weSBhbnRpZ28gZW5jb250cmFk
REM #by4iCiAgICBvbGQgIkFuIG9sZCB2ZXJzaW9uICglZCkgb2YgdGhlIFJlbidQeSBtb2R1bGUgd2Fz
REM #IGZvdW5kIG9uIHlvdXIgc3lzdGVtLCB3aGlsZSB0aGlzIGdhbWUgcmVxdWlyZXMgdmVyc2lvbiAl
REM #ZC4iCiAgICBuZXcgIlVtYSB2ZXJzw6NvIGFudGlnYSAoJWQpIGRvIG3Ds2R1bG8gUmVuJ1B5IGZv
REM #aSBlbmNvbnRyYWRhIG5vIHNpc3RlbWEsIG1hcyBlc3RlIGpvZ28gcmVxdWVyIGEgdmVyc8OjbyAl
REM #ZC4iCiAgICBvbGQgIlBsZWFzZSBjbGljayB0byBjb250aW51ZS4iCiAgICBuZXcgIkNsaXF1ZSBw
REM #YXJhIGNvbnRpbnVhci4iCiAgICBvbGQgIkNvbnRpbnVlIEdhbWUiCiAgICBuZXcgIkNvbnRpbnVh
REM #ciBqb2dvIgogICAgb2xkICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8gcXVpdD8iCiAgICBuZXcg
REM #IlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgc2Fpcj8iCiAgICBvbGQgIkFyZSB5b3Ugc3VyZSB5
REM #b3Ugd2FudCB0byByZXR1cm4gdG8gdGhlIG1haW4gbWVudT9cXG5UaGlzIHdpbGwgbG9zZSB1bnNh
REM #dmVkIHByb2dyZXNzLiIKICAgIG5ldyAiVGVtIGNlcnRlemEgZGUgcXVlIGRlc2VqYSB2b2x0YXIg
REM #YW8gTWVudSBQcmluY2lwYWw/XFxuVm9jw6ogcGVyZGVyw6EgbyBwcm9ncmVzc28gbsOjbyBzYWx2
REM #by4iCiAgICBvbGQgIlRyYW5zaXRpb25zIgogICAgbmV3ICJUcmFuc2nDp8O1ZXMiCiAgICBvbGQg
REM #IkJlZ2luIFNraXBwaW5nIgogICAgbmV3ICJJbmljaWFyIGF2YW7Dp28iCiAgICBvbGQgIkpveXN0
REM #aWNrLi4uIgogICAgbmV3ICJDb250cm9sZS4uLiIKICAgIG9sZCAiTm90IEFzc2lnbmVkIgogICAg
REM #bmV3ICJOw6NvIGF0cmlidcOtZG8iCiAgICBvbGQgIlNlbGVjdC9EaXNtaXNzIgogICAgbmV3ICJT
REM #ZWxlY2lvbmFyL2Rpc3BlbnNhciIKICAgIG9sZCAiSG9sZCB0byBTa2lwIgogICAgbmV3ICJTZWd1
REM #cmUgcGFyYSBhdmFuw6dhciIKICAgIG9sZCAiVG9nZ2xlIFNraXAiCiAgICBuZXcgIkFsdGVybmFy
REM #IGF2YW7Dp28iCiAgICBvbGQgIkhpZGUgVGV4dCIKICAgIG5ldyAiT2N1bHRhciB0ZXh0byIKICAg
REM #IG9sZCAiTWVudSIKICAgIG5ldyAiTWVudSIKICAgIG9sZCAiTW92ZSB0aGUgam95c3RpY2sgb3Ig
REM #cHJlc3MgYSBqb3lzdGljayBidXR0b24gdG8gY3JlYXRlIHRoZSBtYXBwaW5nLiBDbGljayB0aGUg
REM #bW91c2UgdG8gcmVtb3ZlIHRoZSBtYXBwaW5nLiIKICAgIG5ldyAiTW92YSBvIGNvbnRyb2xlIG91
REM #IHByZXNzaW9uZSB1bSBkZSBzZXVzIGJvdMO1ZXMgcGFyYSBjcmlhciBvIG1hcGVhbWVudG8uIENs
REM #aXF1ZSBjb20gbyBtb3VzZSBwYXJhIHJlbW92ZXIgbyBtYXBlYW1lbnRvLiIKICAgIG9sZCAiVGVz
REM #dCIKICAgIG5ldyAiVGVzdGFyIgogICAgb2xkICJBbGwiCiAgICBuZXcgIlRvZG9zIgogICAgb2xk
REM #ICJTb21lIgogICAgbmV3ICJBbGd1bnMiCiAgICBvbGQgIk5vbmUiCiAgICBuZXcgIk5lbmh1bSIK
REM #ICAgIG9sZCAiU2VlbiBNZXNzYWdlcyIKICAgIG5ldyAiTWVuc2FnZW5zIHZpc3RhcyIKICAgIG9s
REM #ZCAiQWxsIE1lc3NhZ2VzIgogICAgbmV3ICJUb2RhcyBhcyBtZW5zYWdlbnMiCiAgICBvbGQgIlN0
REM #b3AgU2tpcHBpbmciCiAgICBuZXcgIlBhcmFyIGRlIGF2YW7Dp2FyIgogICAgb2xkICJLZWVwIFNr
REM #aXBwaW5nIgogICAgbmV3ICJDb250aW51YXIgYXZhbsOnYW5kbyIKICAgIG9sZCAiUXVpY2siCiAg
REM #ICBuZXcgIlLDoXBpZG8iCiAgICBvbGQgIlRoZSBlcnJvciBtZXNzYWdlIHdhczoiCiAgICBuZXcg
REM #IkEgbWVuc2FnZW0gZGUgZXJybyBmb2k6IgogICAgb2xkICJZb3UgbWF5IHdhbnQgdG8gdHJ5IHNh
REM #dmluZyBpbiBhIGRpZmZlcmVudCBzbG90LCBvciBwbGF5aW5nIGZvciBhIHdoaWxlIGFuZCB0cnlp
REM #bmcgYWdhaW4gbGF0ZXIuIgogICAgbmV3ICJUYWx2ZXogc2VqYSBtZWxob3Igc2FsdmFyIGVtIG91
REM #dHJvIHNsb3Qgb3Ugam9nYXIgcG9yIGFsZ3VtIHRlbXBvIGUgdGVudGFyIG5vdmFtZW50ZSBtYWlz
REM #IHRhcmRlLiIKICAgIG9sZCAiU2F2ZSBGYWlsZWQuIgogICAgbmV3ICJGYWxoYSBhbyBzYWx2YXIu
REM #IgogICAgb2xkICJKb3lzdGljayBDb25maWd1cmF0aW9uIgogICAgbmV3ICJDb25maWd1cmHDp8Oj
REM #byBkbyBjb250cm9sZSIKICAgIG9sZCAiQXJlIHlvdSBzdXJlPyIKICAgIG5ldyAiVGVtIGNlcnRl
REM #emE/IgogICAgb2xkICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8gZGVsZXRlIHRoaXMgc2F2ZT8i
REM #CiAgICBuZXcgIlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgZXhjbHVpciBlc3RlIHNhbHZhbWVu
REM #dG8/IgogICAgb2xkICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8gb3ZlcndyaXRlIHlvdXIgc2F2
REM #ZT8iCiAgICBuZXcgIlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgc29icmVzY3JldmVyIGVzdGUg
REM #c2FsdmFtZW50bz8iCiAgICBvbGQgIkxvYWRpbmcgd2lsbCBsb3NlIHVuc2F2ZWQgcHJvZ3Jlc3Mu
REM #XFxuQXJlIHlvdSBzdXJlIHlvdSB3YW50IHRvIGRvIHRoaXM/IgogICAgbmV3ICJDYXJyZWdhciBw
REM #ZXJkZXLDoSBvIHByb2dyZXNzbyBuw6NvIHNhbHZvLlxcblRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNl
REM #amEgZmF6ZXIgaXNzbz8iCiAgICBvbGQgIkFyZSB5b3Ugc3VyZSB5b3Ugd2FudCB0byBiZWdpbiBz
REM #a2lwcGluZz8iCiAgICBuZXcgIlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgaW5pY2lhciBvIGF2
REM #YW7Dp28/IgogICAgb2xkICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8gc2tpcCB0byB0aGUgbmV4
REM #dCBjaG9pY2U/IgogICAgbmV3ICJUZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGF2YW7Dp2FyIGF0
REM #w6kgYSBwcsOzeGltYSBlc2NvbGhhPyIKICAgIG9sZCAiT3BlbiIKICAgIG5ldyAiQWJyaXIiCiAg
REM #ICBvbGQgIkNvcHkiCiAgICBuZXcgIkNvcGlhciIKICAgIG9sZCAiQ29waWVzIHRoZSB0cmFjZWJh
REM #Y2sudHh0IGZpbGUgdG8gdGhlIGNsaXBib2FyZC4iCiAgICBuZXcgIkNvcGlhIG8gYXJxdWl2byB0
REM #cmFjZWJhY2sudHh0IHBhcmEgYSDDoXJlYSBkZSB0cmFuc2ZlcsOqbmNpYS4iCiAgICBvbGQgIkNv
REM #bnNvbGUiCiAgICBuZXcgIkNvbnNvbGUiCiAgICBvbGQgIk9wZW5zIGEgY29uc29sZSB0byBhbGxv
REM #dyBkZWJ1Z2dpbmcgdGhlIHByb2JsZW0uIgogICAgbmV3ICJBYnJlIHVtIGNvbnNvbGUgcGFyYSBw
REM #ZXJtaXRpciBhIGRlcHVyYcOnw6NvIGRvIHByb2JsZW1hLiIKICAgIG9sZCAiQ29weSBCQkNvZGUi
REM #CiAgICBuZXcgIkNvcGlhciBCQkNvZGUiCiAgICBvbGQgIkNvcGllcyB0aGUgdHJhY2ViYWNrLnR4
REM #dCBmaWxlIHRvIHRoZSBjbGlwYm9hcmQgYXMgQkJjb2RlIGZvciBmb3J1bXMgbGlrZSBodHRwczov
REM #L2xlbW1hc29mdC5yZW5haS51cy8uIgogICAgbmV3ICJDb3BpYSBvIGFycXVpdm8gdHJhY2ViYWNr
REM #LnR4dCBwYXJhIGEgw6FyZWEgZGUgdHJhbnNmZXLDqm5jaWEgY29tbyBCQkNvZGUgcGFyYSBmw7Ny
REM #dW5zIGNvbW8gaHR0cHM6Ly9sZW1tYXNvZnQucmVuYWkudXMvLiIKICAgIG9sZCAiQ29waWVzIHRo
REM #ZSBlcnJvcnMudHh0IGZpbGUgdG8gdGhlIGNsaXBib2FyZC4iCiAgICBuZXcgIkNvcGlhIG8gYXJx
REM #dWl2byBlcnJvcnMudHh0IHBhcmEgYSDDoXJlYSBkZSB0cmFuc2ZlcsOqbmNpYS4iCiAgICBvbGQg
REM #IltuYW1lXSBbYXR0cmlidXRlc10gKGhpZGRlbikiCiAgICBuZXcgIltuYW1lXSBbYXR0cmlidXRl
REM #c10gKG9jdWx0bykiCiAgICBvbGQgIltuYW1lXSBbYXR0cmlidXRlc10iCiAgICBuZXcgIltuYW1l
REM #XSBbYXR0cmlidXRlc10iCiAgICBvbGQgIlR5cGUgdG8gZmlsdGVyOiAiCiAgICBuZXcgIkRpZ2l0
REM #ZSBwYXJhIGZpbHRyYXI6ICIKICAgIG9sZCAiVGV4dHVyZXM6IFt0ZXhfY291bnRdIChbdGV4X3Np
REM #emVfbWI6LjFmXSBNQikiCiAgICBuZXcgIlRleHR1cmFzOiBbdGV4X2NvdW50XSAoW3RleF9zaXpl
REM #X21iOi4xZl0gTUIpIgogICAgb2xkICJJbWFnZSBjYWNoZTogW2NhY2hlX3BjdDouMWZdJSAoW2Nh
REM #Y2hlX3NpemVfbWI6LjFmXSBNQikiCiAgICBuZXcgIkNhY2hlIGRlIGltYWdlbnM6IFtjYWNoZV9w
REM #Y3Q6LjFmXSUgKFtjYWNoZV9zaXplX21iOi4xZl0gTUIpIgogICAgb2xkICJcXG57Y29sb3I9I2Nm
REM #Y33inJQgcHJlZGljdGVkIGltYWdlIChnb29kKXsvY29sb3J9XFxue2NvbG9yPSNmY2N94pyYIHVu
REM #cHJlZGljdGVkIGltYWdlIChiYWQpey9jb2xvcn1cXG57Y29sb3I9I2ZmZn1EcmFnIHRvIG1vdmUu
REM #ey9jb2xvcn0iCiAgICBuZXcgIlxcbntjb2xvcj0jY2ZjfeKclCBpbWFnZW0gcHJldmlzdGEgKGJv
REM #YSl7L2NvbG9yfVxcbntjb2xvcj0jZmNjfeKcmCBpbWFnZW0gbsOjbyBwcmV2aXN0YSAocnVpbSl7
REM #L2NvbG9yfVxcbntjb2xvcj0jZmZmfUFycmFzdGUgcGFyYSBtb3Zlci57L2NvbG9yfSIKICAgIG9s
REM #ZCAiSW5zcGVjdGluZyBTdHlsZXMgb2YgW2Rpc3BsYXlhYmxlX25hbWUhcV0iCiAgICBuZXcgIklu
REM #c3BlY2lvbmFuZG8gZXN0aWxvcyBkZSBbZGlzcGxheWFibGVfbmFtZSFxXSIKICAgIG9sZCAiZGlz
REM #cGxheWFibGU6IgogICAgbmV3ICJlbGVtZW50byB2aXN1YWw6IgogICAgb2xkICIgICAgICAgIChu
REM #byBwcm9wZXJ0aWVzIGFmZmVjdCB0aGUgZGlzcGxheWFibGUpIgogICAgbmV3ICIgICAgICAgIChu
REM #ZW5odW1hIHByb3ByaWVkYWRlIGFmZXRhIG8gZWxlbWVudG8gdmlzdWFsKSIKICAgIG9sZCAiICAg
REM #ICAgICAoZGVmYXVsdCBwcm9wZXJ0aWVzIG9taXR0ZWQpIgogICAgbmV3ICIgICAgICAgIChwcm9w
REM #cmllZGFkZXMgcGFkcsOjbyBvbWl0aWRhcykiCiAgICBvbGQgIjxyZXByKCkgZmFpbGVkPiIKICAg
REM #IG5ldyAiPHJlcHIoKSBmYWxob3U+IgogICAgb2xkICJBbiBlcnJvciBoYXMgb2NjdXJyZWQ6Igog
REM #ICAgbmV3ICJPY29ycmV1IHVtIGVycm86IgogICAgb2xkICJDaGVja2luZyBmb3IgdXBkYXRlcy4i
REM #CiAgICBuZXcgIlZlcmlmaWNhbmRvIGF0dWFsaXphw6fDtWVzLiIKICAgIG9sZCAiRmluaXNoaW5n
REM #IHVwLiIKICAgIG5ldyAiRmluYWxpemFuZG8uIgogICAgb2xkICJQcm9jZWVkIgogICAgbmV3ICJD
REM #b250aW51YXIiCiAgICBvbGQgIk5QT1QiCiAgICBuZXcgIk5QT1QiCiAgICBvbGQgIlByZXNzIG9y
REM #IG1vdmUgdGhlIFtjb250cm9sIXNdIFtraW5kXS4iCiAgICBuZXcgIlByZXNzaW9uZSBvdSBtb3Zh
REM #IFtjb250cm9sIXNdIFtraW5kXS4iCgogICAgb2xkICJNb2RvIExldCdzIFBsYXkiCiAgICBuZXcg
REM #Ik1vZG8gY29tIENlbnN1cmEiCgppbml0IDk5OTk5OSBweXRob246CiAgICBfZGRhY19mb3JjZV9p
REM #bnRlcmZhY2UgPSB7CiAgICAgICAgIlN0YXJ0IjogdSJJbmljaWFyIiwKICAgICAgICAiU3RhcnQg
REM #R2FtZSI6IHUiSW5pY2lhciBqb2dvIiwKICAgICAgICAiTG9hZCI6IHUiQ2FycmVnYXIiLAogICAg
REM #ICAgICJMb2FkIEdhbWUiOiB1IkNhcnJlZ2FyIGpvZ28iLAogICAgICAgICJTYXZlIjogdSJTYWx2
REM #YXIiLAogICAgICAgICJTYXZlIEdhbWUiOiB1IlNhbHZhciBqb2dvIiwKICAgICAgICAiUHJlZmVy
REM #ZW5jZXMiOiB1IkNvbmZpZ3VyYcOnw7VlcyIsCiAgICAgICAgIlByZWZlcsOqbmNpYXMiOiB1IkNv
REM #bmZpZ3VyYcOnw7VlcyIsCiAgICAgICAgIlByZWZlcmVuY2lhcyI6IHUiQ29uZmlndXJhw6fDtWVz
REM #IiwKICAgICAgICAicHJlZmVyw6puY2lhcyI6IHUiQ29uZmlndXJhw6fDtWVzIiwKICAgICAgICAi
REM #cHJlZmVyZW5jaWFzIjogdSJDb25maWd1cmHDp8O1ZXMiLAogICAgICAgICJQcmVmcyI6IHUiQ29u
REM #ZmlndXJhw6fDtWVzIiwKICAgICAgICAiSGlzdG9yeSI6IHUiSGlzdMOzcmljbyIsCiAgICAgICAg
REM #Ik1haW4gTWVudSI6IHUiTWVudSBQcmluY2lwYWwiLAogICAgICAgICJNZW51IFByaW5jaXBhbCI6
REM #IHUiTWVudSBQcmluY2lwYWwiLAogICAgICAgICJNZW51IHByaW5jaXBhbCI6IHUiTWVudSBQcmlu
REM #Y2lwYWwiLAogICAgICAgICJBYm91dCI6IHUiU29icmUiLAogICAgICAgICJIZWxwIjogdSJBanVk
REM #YSIsCiAgICAgICAgIlF1aXQiOiB1IlNhaXIiLAogICAgICAgICJRdWl0IEdhbWUiOiB1IlNhaXIg
REM #ZG8gam9nbyIsCiAgICAgICAgIkV4aXQiOiB1IlNhaXIiLAogICAgICAgICJFeGl0IEdhbWUiOiB1
REM #IlNhaXIgZG8gam9nbyIsCiAgICAgICAgIlJldHVybiI6IHUiVm9sdGFyIiwKICAgICAgICAiQmFj
REM #ayI6IHUiVm9sdGFyIiwKICAgICAgICAiUmV0b3JuYXIiOiB1IlZvbHRhciIsCiAgICAgICAgIkRl
REM #c2lzdGlyIjogdSJTYWlyIiwKICAgICAgICAiU2tpcCI6IHUiQXZhbsOnYXIiLAogICAgICAgICJB
REM #dXRvIjogdSJBdXRvbcOhdGljbyIsCiAgICAgICAgIlEuU2F2ZSI6IHUiU2FsdmFtZW50byByw6Fw
REM #aWRvIiwKICAgICAgICAiUS5Mb2FkIjogdSJDYXJyZWdhbWVudG8gcsOhcGlkbyIsCiAgICAgICAg
REM #IkVuZCBSZXBsYXkiOiB1IkVuY2VycmFyIHJlcGxheSIsCiAgICAgICAgIlllcyI6IHUiU2ltIiwK
REM #ICAgICAgICAiTm8iOiB1Ik7Do28iLAogICAgICAgICJOZXcgR2FtZSI6IHUiTm92byBqb2dvIiwK
REM #ICAgICAgICAiQ29udGludWUiOiB1IkNvbnRpbnVhciIsCiAgICAgICAgIldpbmRvdyI6IHUiSmFu
REM #ZWxhIiwKICAgICAgICAiRnVsbHNjcmVlbiI6IHUiVGVsYSBjaGVpYSIsCiAgICAgICAgIkZ1bGwg
REM #U2NyZWVuIjogdSJUZWxhIGNoZWlhIiwKICAgICAgICAiV2luZG93ZWQiOiB1IkVtIGphbmVsYSIs
REM #CiAgICAgICAgIlVuc2VlbiBUZXh0IjogdSJUZXh0byBuw6NvIHZpc3RvIiwKICAgICAgICAiQWZ0
REM #ZXIgQ2hvaWNlcyI6IHUiQXDDs3MgZXNjb2xoYXMiLAogICAgICAgICJUZXh0IFNwZWVkIjogdSJW
REM #ZWxvY2lkYWRlIGRvIHRleHRvIiwKICAgICAgICAiQXV0by1Gb3J3YXJkIFRpbWUiOiB1IlRlbXBv
REM #IGRlIGF2YW7Dp28gYXV0b23DoXRpY28iLAogICAgICAgICJBdXRvIEZvcndhcmQiOiB1IkF2YW7D
REM #p28gYXV0b23DoXRpY28iLAogICAgICAgICJNdXNpYyBWb2x1bWUiOiB1IlZvbHVtZSBkYSBtw7pz
REM #aWNhIiwKICAgICAgICAiU291bmQgVm9sdW1lIjogdSJWb2x1bWUgZG9zIHNvbnMiLAogICAgICAg
REM #ICJWb2ljZSBWb2x1bWUiOiB1IlZvbHVtZSBkYSB2b3oiLAogICAgICAgICJNdXRlIEFsbCI6IHUi
REM #U2lsZW5jaWFyIHR1ZG8iLAogICAgICAgICJNdXRlIE1haW4iOiB1IlNpbGVuY2lhciB2b2x1bWUg
REM #cHJpbmNpcGFsIiwKICAgICAgICAiTXV0ZSBNdXNpYyI6IHUiU2lsZW5jaWFyIG3DunNpY2EiLAog
REM #ICAgICAgICJNdXRlIFNvdW5kIjogdSJTaWxlbmNpYXIgc29ucyIsCiAgICAgICAgIk11dGUgVm9p
REM #Y2UiOiB1IlNpbGVuY2lhciB2b3oiLAogICAgICAgICJQYWdlIHt9IjogdSJQw6FnaW5hIHt9IiwK
REM #ICAgICAgICAiQXV0b21hdGljIHNhdmVzIjogdSJTYWx2YW1lbnRvcyBhdXRvbcOhdGljb3MiLAog
REM #ICAgICAgICJRdWljayBzYXZlcyI6IHUiU2FsdmFtZW50b3MgcsOhcGlkb3MiLAogICAgICAgICJl
REM #bXB0eSBzbG90IjogdSJzbG90IHZhemlvIiwKICAgICAgICAiVXBsb2FkIFN5bmMiOiB1IkVudmlh
REM #ciBzaW5jcm9uaXphw6fDo28iLAogICAgICAgICJEb3dubG9hZCBTeW5jIjogdSJCYWl4YXIgc2lu
REM #Y3Jvbml6YcOnw6NvIiwKICAgICAgICAiUmVuZGVyZXIiOiB1IlJlbmRlcml6YWRvciIsCiAgICAg
REM #ICAgIkZvcmNlIEdMMiBSZW5kZXJlciI6IHUiRm9yw6dhciByZW5kZXJpemFkb3IgR0wyIiwKICAg
REM #ICAgICAiRm9yY2UgQU5HTEUyIFJlbmRlcmVyIjogdSJGb3LDp2FyIHJlbmRlcml6YWRvciBBTkdM
REM #RTIiLAogICAgICAgICJGb3JjZSBHTEVTMiBSZW5kZXJlciI6IHUiRm9yw6dhciByZW5kZXJpemFk
REM #b3IgR0xFUzIiLAogICAgICAgICJHYW1lcGFkIjogdSJDb250cm9sZSIsCiAgICAgICAgIkVuYWJs
REM #ZSAoTm8gQmxvY2tsaXN0KSI6IHUiQXRpdmFyIChzZW0gYmxvcXVlaW8pIiwKICAgICAgICAiQ2Fs
REM #aWJyYXRlIjogdSJDYWxpYnJhciIsCiAgICAgICAgIlBvd2Vyc2F2ZSI6IHUiRWNvbm9taWEgZGUg
REM #ZW5lcmdpYSIsCiAgICAgICAgIkZyYW1lcmF0ZSI6IHUiVGF4YSBkZSBxdWFkcm9zIiwKICAgICAg
REM #ICAiU2NyZWVuIjogdSJUZWxhIiwKICAgICAgICAiVGVhcmluZyI6IHUiRGVzZ2FycmFtZW50byBk
REM #ZSB0ZWxhIiwKICAgICAgICAiQ2hhbmdlcyB3aWxsIHRha2UgZWZmZWN0IHRoZSBuZXh0IHRpbWUg
REM #dGhpcyBwcm9ncmFtIGlzIHJ1bi4iOiB1IkFzIGFsdGVyYcOnw7VlcyBlbnRyYXLDo28gZW0gdmln
REM #b3IgbmEgcHLDs3hpbWEgdmV6IHF1ZSBvIHByb2dyYW1hIGZvciBpbmljaWFkby4iLAogICAgICAg
REM #ICJQZXJmb3JtYW5jZSBXYXJuaW5nIjogdSJBdmlzbyBkZSBkZXNlbXBlbmhvIiwKICAgICAgICAi
REM #VGhpcyBjb21wdXRlciBpcyB1c2luZyBzb2Z0d2FyZSByZW5kZXJpbmcuIjogdSJFc3RlIGNvbXB1
REM #dGFkb3IgZXN0w6EgdXNhbmRvIHJlbmRlcml6YcOnw6NvIHBvciBzb2Z0d2FyZS4iLAogICAgICAg
REM #ICJUaGlzIGdhbWUgcmVxdWlyZXMgdXNlIG9mIEdMMiB0aGF0IGNhbid0IGJlIGluaXRpYWxpc2Vk
REM #LiI6IHUiRXN0ZSBqb2dvIHJlcXVlciBvIHVzbyBkZSBHTDIsIHF1ZSBuw6NvIHDDtGRlIHNlciBp
REM #bmljaWFsaXphZG8uIiwKICAgICAgICAiVGhpcyBjb21wdXRlciBoYXMgYSBwcm9ibGVtIGRpc3Bs
REM #YXlpbmcgZ3JhcGhpY3M6IFtwcm9ibGVtXS4iOiB1IkVzdGUgY29tcHV0YWRvciB0ZW0gdW0gcHJv
REM #YmxlbWEgYW8gZXhpYmlyIG9zIGdyw6FmaWNvczogW3Byb2JsZW1dLiIsCiAgICAgICAgIkRlamFW
REM #dSBTYW5zIjogdSJEZWphVnUgU2FucyIsCiAgICAgICAgIk9wZW5keXNsZXhpYyI6IHUiT3BlbmR5
REM #c2xleGljIiwKICAgICAgICAiS2VybmluZyI6IHUiS2VybmluZyIsCiAgICAgICAgIlNlbGYtVm9p
REM #Y2luZyBhbmQgQXVkaW8iOiB1IlZveiBhdXRvbcOhdGljYSBlIMOhdWRpbyIsCiAgICAgICAgIlBy
REM #ZXNzIFIgdG8gcmVzZXQgYWxsIHNlbGYtdm9pY2luZyBzZXR0aW5ncyB0byB0aGVpciBkZWZhdWx0
REM #IHZhbHVlcywgYW5kIGVuYWJsZSBzZWxmLXZvaWNpbmcuIjogdSJQcmVzc2lvbmUgUiBwYXJhIHJl
REM #ZGVmaW5pciB0b2RhcyBhcyBjb25maWd1cmHDp8O1ZXMgZGUgdm96IGF1dG9tw6F0aWNhIHBhcmEg
REM #b3MgdmFsb3JlcyBwYWRyw6NvIGUgYXRpdmFyIGEgdm96IGF1dG9tw6F0aWNhLiIsCiAgICAgICAg
REM #IlNlbGYtdm9pY2luZyBzZXR0aW5ncyByZXNldC4iOiB1IkNvbmZpZ3VyYcOnw7VlcyBkZSB2b3og
REM #YXV0b23DoXRpY2EgcmVkZWZpbmlkYXMuIiwKICAgICAgICAiU2VsZi1Wb2ljaW5nIFNwZWVkIjog
REM #dSJWZWxvY2lkYWRlIGRhIHZveiBhdXRvbcOhdGljYSIsCiAgICAgICAgIkxhbmd1YWdlIjogdSJJ
REM #ZGlvbWEiLAogICAgICAgICJTZWxlY3QgR2FtZXBhZCB0byBDYWxpYnJhdGUiOiB1IlNlbGVjaW9u
REM #ZSBvIGNvbnRyb2xlIHBhcmEgY2FsaWJyYXIiLAogICAgICAgICJObyBHYW1lcGFkcyBBdmFpbGFi
REM #bGUiOiB1Ik5lbmh1bSBjb250cm9sZSBkaXNwb27DrXZlbCIsCiAgICAgICAgIkNhbGlicmF0aW5n
REM #IFtuYW1lXSAoW2ldL1t0b3RhbF0pIjogdSJDYWxpYnJhbmRvIFtuYW1lXSAoW2ldL1t0b3RhbF0p
REM #IiwKICAgICAgICAiUHJlc3Mgb3IgbW92ZSB0aGUgJ1tjb250cm9sIXNdJyBba2luZF0uIjogdSJQ
REM #cmVzc2lvbmUgb3UgbW92YSBvICdbY29udHJvbCFzXScgW2tpbmRdLiIsCiAgICAgICAgIlNraXAg
REM #KEEpIjogdSJBdmFuw6dhciAoQSkiLAogICAgICAgICJCYWNrIChCKSI6IHUiVm9sdGFyIChCKSIs
REM #CiAgICAgICAgIk1vbm8gQXVkaW8iOiB1IsOBdWRpbyBtb25vIiwKICAgICAgICAiU2VsZi1Wb2lj
REM #aW5nIFZvaWNlIjogdSJWb3ogdXNhZGEgcGVsYSB2b3ogYXV0b23DoXRpY2EiLAogICAgICAgICJU
REM #ZXh0IjogdSJUZXh0byIsCiAgICAgICAgIkFjY2Vzc2liaWxpdHkgTWVudS4gVXNlIHVwIGFuZCBk
REM #b3duIGFycm93cyB0byBuYXZpZ2F0ZSwgYW5kIGVudGVyIHRvIGFjdGl2YXRlIGJ1dHRvbnMgYW5k
REM #IGJhcnMuIFByZXNzIFIgdG8gcmVzZXQgc2VsZi12b2ljaW5nIHNldHRpbmdzIHRvIHRoZWlyIGRl
REM #ZmF1bHQgdmFsdWVzIGFuZCBlbmFibGUgc2VsZi12b2ljaW5nLiI6IHUiTWVudSBkZSBhY2Vzc2li
REM #aWxpZGFkZS4gVXNlIGFzIHNldGFzIHBhcmEgY2ltYSBlIHBhcmEgYmFpeG8gcGFyYSBuYXZlZ2Fy
REM #IGUgRW50ZXIgcGFyYSBhdGl2YXIgYm90w7VlcyBlIGJhcnJhcy4gUHJlc3Npb25lIFIgcGFyYSBy
REM #ZWRlZmluaXIgYXMgY29uZmlndXJhw6fDtWVzIGRlIHZveiBhdXRvbcOhdGljYSBlIGF0aXbDoS1s
REM #YS4iLAogICAgICAgICJUaGUgb3B0aW9ucyBvbiB0aGlzIG1lbnUgYXJlIGludGVuZGVkIHRvIGlt
REM #cHJvdmUgYWNjZXNzaWJpbGl0eS4gVGhleSBtYXkgbm90IHdvcmsgd2l0aCBhbGwgZ2FtZXMsIGFu
REM #ZCBzb21lIGNvbWJpbmF0aW9ucyBvZiBvcHRpb25zIG1heSByZW5kZXIgdGhlIGdhbWUgdW5wbGF5
REM #YWJsZS4gVGhpcyBpcyBub3QgYW4gaXNzdWUgd2l0aCB0aGUgZ2FtZSBvciBlbmdpbmUuIEZvciB0
REM #aGUgYmVzdCByZXN1bHRzIHdoZW4gY2hhbmdpbmcgZm9udHMsIHRyeSB0byBrZWVwIHRoZSB0ZXh0
REM #IHNpemUgdGhlIHNhbWUgYXMgaXQgb3JpZ2luYWxseSB3YXMuIjogdSJBcyBvcMOnw7VlcyBkZXN0
REM #ZSBtZW51IHTDqm0gY29tbyBvYmpldGl2byBtZWxob3JhciBhIGFjZXNzaWJpbGlkYWRlLiBFbGFz
REM #IHBvZGVtIG7Do28gZnVuY2lvbmFyIGNvbSB0b2RvcyBvcyBqb2dvcywgZSBhbGd1bWFzIGNvbWJp
REM #bmHDp8O1ZXMgcG9kZW0gZGVpeGFyIG8gam9nbyBpbXBvc3PDrXZlbCBkZSBqb2dhci4gSXNzbyBu
REM #w6NvIMOpIHVtIHByb2JsZW1hIGRvIGpvZ28gbmVtIGRhIGVuZ2luZS4gUGFyYSBvYnRlciBvcyBt
REM #ZWxob3JlcyByZXN1bHRhZG9zIGFvIGFsdGVyYXIgZm9udGVzLCB0ZW50ZSBtYW50ZXIgbyB0YW1h
REM #bmhvIGRvIHRleHRvIHByw7N4aW1vIGRvIG9yaWdpbmFsLiIsCiAgICAgICAgIlRvdWNoIHRvIHBs
REM #YXkgdGhlIHZpZGVvLiI6IHUiVG9xdWUgcGFyYSByZXByb2R1emlyIG8gdsOtZGVvLiIsCiAgICAg
REM #ICAgIkNvbnRhY3RpbmcgQXBwIFN0b3JlXG5QbGVhc2UgV2FpdC4uLiI6IHUiQ29uZWN0YW5kbyDD
REM #oCBBcHAgU3RvcmVcbkFndWFyZGUuLi4iLAogICAgICAgICJJbWFnZSBBdHRyaWJ1dGVzIjogdSJB
REM #dHJpYnV0b3MgZGEgaW1hZ2VtIiwKICAgICAgICAiSGlkZSBkZWxldGVkIjogdSJPY3VsdGFyIGV4
REM #Y2x1w61kb3MiLAogICAgICAgICJTaG93IGRlbGV0ZWQiOiB1Ik1vc3RyYXIgZXhjbHXDrWRvcyIs
REM #CiAgICAgICAgIldoaWxlIFJlbidQeSBnYW1lcyBtYXkgYmUgcGxheWFibGUgd2l0aG91dCB0aGUg
REM #cmVucHkgbW9kdWxlLCBzb21lIGZlYXR1cmVzIG1heSBiZSBkaXNhYmxlZC4gRm9yIG1vcmUgaW5m
REM #b3JtYXRpb24sIHJlYWQgdGhlIG1vZHVsZS9SRUFETUUudHh0IGZpbGUgb3IgZ28gdG8gaHR0cDov
REM #L3d3dy5iaXNob3Vqby51cy9yZW5weS8uIjogdSJFbWJvcmEgam9nb3MgUmVuJ1B5IHBvc3NhbSBm
REM #dW5jaW9uYXIgc2VtIG8gbcOzZHVsbyByZW5weSwgYWxndW5zIHJlY3Vyc29zIHBvZGVtIHNlciBk
REM #ZXNhdGl2YWRvcy4gUGFyYSBtYWlzIGluZm9ybWHDp8O1ZXMsIGxlaWEgbW9kdWxlL1JFQURNRS50
REM #eHQgb3UgYWNlc3NlIGh0dHA6Ly93d3cuYmlzaG91am8udXMvcmVucHkvLiIsCiAgICAgICAgInJl
REM #bnB5IG1vZHVsZSBub3QgZm91bmQuIjogdSJNw7NkdWxvIHJlbnB5IG7Do28gZW5jb250cmFkby4i
REM #LAogICAgICAgICJUaGUgcmVucHkgbW9kdWxlIGNvdWxkIG5vdCBiZSBsb2FkZWQgb24geW91ciBz
REM #eXN0ZW0uIjogdSJPIG3Ds2R1bG8gcmVucHkgbsOjbyBww7RkZSBzZXIgY2FycmVnYWRvIG5vIHNl
REM #dSBzaXN0ZW1hLiIsCiAgICAgICAgIk9sZCByZW5weSBtb2R1bGUgZm91bmQuIjogdSJNw7NkdWxv
REM #IHJlbnB5IGFudGlnbyBlbmNvbnRyYWRvLiIsCiAgICAgICAgIkFuIG9sZCB2ZXJzaW9uICglZCkg
REM #b2YgdGhlIFJlbidQeSBtb2R1bGUgd2FzIGZvdW5kIG9uIHlvdXIgc3lzdGVtLCB3aGlsZSB0aGlz
REM #IGdhbWUgcmVxdWlyZXMgdmVyc2lvbiAlZC4iOiB1IlVtYSB2ZXJzw6NvIGFudGlnYSAoJWQpIGRv
REM #IG3Ds2R1bG8gUmVuJ1B5IGZvaSBlbmNvbnRyYWRhIG5vIHNpc3RlbWEsIG1hcyBlc3RlIGpvZ28g
REM #cmVxdWVyIGEgdmVyc8OjbyAlZC4iLAogICAgICAgICJQbGVhc2UgY2xpY2sgdG8gY29udGludWUu
REM #IjogdSJDbGlxdWUgcGFyYSBjb250aW51YXIuIiwKICAgICAgICAiQ29udGludWUgR2FtZSI6IHUi
REM #Q29udGludWFyIGpvZ28iLAogICAgICAgICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8gcXVpdD8i
REM #OiB1IlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgc2Fpcj8iLAogICAgICAgICJBcmUgeW91IHN1
REM #cmUgeW91IHdhbnQgdG8gcmV0dXJuIHRvIHRoZSBtYWluIG1lbnU/XFxuVGhpcyB3aWxsIGxvc2Ug
REM #dW5zYXZlZCBwcm9ncmVzcy4iOiB1IlRlbSBjZXJ0ZXphIGRlIHF1ZSBkZXNlamEgdm9sdGFyIGFv
REM #IE1lbnUgUHJpbmNpcGFsP1xcblZvY8OqIHBlcmRlcsOhIG8gcHJvZ3Jlc3NvIG7Do28gc2Fsdm8u
REM #IiwKICAgICAgICAiVHJhbnNpdGlvbnMiOiB1IlRyYW5zacOnw7VlcyIsCiAgICAgICAgIkJlZ2lu
REM #IFNraXBwaW5nIjogdSJJbmljaWFyIGF2YW7Dp28iLAogICAgICAgICJKb3lzdGljay4uLiI6IHUi
REM #Q29udHJvbGUuLi4iLAogICAgICAgICJOb3QgQXNzaWduZWQiOiB1Ik7Do28gYXRyaWJ1w61kbyIs
REM #CiAgICAgICAgIlNlbGVjdC9EaXNtaXNzIjogdSJTZWxlY2lvbmFyL2Rpc3BlbnNhciIsCiAgICAg
REM #ICAgIkhvbGQgdG8gU2tpcCI6IHUiU2VndXJlIHBhcmEgYXZhbsOnYXIiLAogICAgICAgICJUb2dn
REM #bGUgU2tpcCI6IHUiQWx0ZXJuYXIgYXZhbsOnbyIsCiAgICAgICAgIkhpZGUgVGV4dCI6IHUiT2N1
REM #bHRhciB0ZXh0byIsCiAgICAgICAgIk1lbnUiOiB1Ik1lbnUiLAogICAgICAgICJNb3ZlIHRoZSBq
REM #b3lzdGljayBvciBwcmVzcyBhIGpveXN0aWNrIGJ1dHRvbiB0byBjcmVhdGUgdGhlIG1hcHBpbmcu
REM #IENsaWNrIHRoZSBtb3VzZSB0byByZW1vdmUgdGhlIG1hcHBpbmcuIjogdSJNb3ZhIG8gY29udHJv
REM #bGUgb3UgcHJlc3Npb25lIHVtIGRlIHNldXMgYm90w7VlcyBwYXJhIGNyaWFyIG8gbWFwZWFtZW50
REM #by4gQ2xpcXVlIGNvbSBvIG1vdXNlIHBhcmEgcmVtb3ZlciBvIG1hcGVhbWVudG8uIiwKICAgICAg
REM #ICAiVGVzdCI6IHUiVGVzdGFyIiwKICAgICAgICAiQWxsIjogdSJUb2RvcyIsCiAgICAgICAgIlNv
REM #bWUiOiB1IkFsZ3VucyIsCiAgICAgICAgIk5vbmUiOiB1Ik5lbmh1bSIsCiAgICAgICAgIlNlZW4g
REM #TWVzc2FnZXMiOiB1Ik1lbnNhZ2VucyB2aXN0YXMiLAogICAgICAgICJBbGwgTWVzc2FnZXMiOiB1
REM #IlRvZGFzIGFzIG1lbnNhZ2VucyIsCiAgICAgICAgIlN0b3AgU2tpcHBpbmciOiB1IlBhcmFyIGRl
REM #IGF2YW7Dp2FyIiwKICAgICAgICAiS2VlcCBTa2lwcGluZyI6IHUiQ29udGludWFyIGF2YW7Dp2Fu
REM #ZG8iLAogICAgICAgICJRdWljayI6IHUiUsOhcGlkbyIsCiAgICAgICAgIlRoZSBlcnJvciBtZXNz
REM #YWdlIHdhczoiOiB1IkEgbWVuc2FnZW0gZGUgZXJybyBmb2k6IiwKICAgICAgICAiWW91IG1heSB3
REM #YW50IHRvIHRyeSBzYXZpbmcgaW4gYSBkaWZmZXJlbnQgc2xvdCwgb3IgcGxheWluZyBmb3IgYSB3
REM #aGlsZSBhbmQgdHJ5aW5nIGFnYWluIGxhdGVyLiI6IHUiVGFsdmV6IHNlamEgbWVsaG9yIHNhbHZh
REM #ciBlbSBvdXRybyBzbG90IG91IGpvZ2FyIHBvciBhbGd1bSB0ZW1wbyBlIHRlbnRhciBub3ZhbWVu
REM #dGUgbWFpcyB0YXJkZS4iLAogICAgICAgICJTYXZlIEZhaWxlZC4iOiB1IkZhbGhhIGFvIHNhbHZh
REM #ci4iLAogICAgICAgICJKb3lzdGljayBDb25maWd1cmF0aW9uIjogdSJDb25maWd1cmHDp8OjbyBk
REM #byBjb250cm9sZSIsCiAgICAgICAgIkFyZSB5b3Ugc3VyZT8iOiB1IlRlbSBjZXJ0ZXphPyIsCiAg
REM #ICAgICAgIkFyZSB5b3Ugc3VyZSB5b3Ugd2FudCB0byBkZWxldGUgdGhpcyBzYXZlPyI6IHUiVGVt
REM #IGNlcnRlemEgZGUgcXVlIGRlc2VqYSBleGNsdWlyIGVzdGUgc2FsdmFtZW50bz8iLAogICAgICAg
REM #ICJBcmUgeW91IHN1cmUgeW91IHdhbnQgdG8gb3ZlcndyaXRlIHlvdXIgc2F2ZT8iOiB1IlRlbSBj
REM #ZXJ0ZXphIGRlIHF1ZSBkZXNlamEgc29icmVzY3JldmVyIGVzdGUgc2FsdmFtZW50bz8iLAogICAg
REM #ICAgICJMb2FkaW5nIHdpbGwgbG9zZSB1bnNhdmVkIHByb2dyZXNzLlxcbkFyZSB5b3Ugc3VyZSB5
REM #b3Ugd2FudCB0byBkbyB0aGlzPyI6IHUiQ2FycmVnYXIgcGVyZGVyw6EgbyBwcm9ncmVzc28gbsOj
REM #byBzYWx2by5cXG5UZW0gY2VydGV6YSBkZSBxdWUgZGVzZWphIGZhemVyIGlzc28/IiwKICAgICAg
REM #ICAiQXJlIHlvdSBzdXJlIHlvdSB3YW50IHRvIGJlZ2luIHNraXBwaW5nPyI6IHUiVGVtIGNlcnRl
REM #emEgZGUgcXVlIGRlc2VqYSBpbmljaWFyIG8gYXZhbsOnbz8iLAogICAgICAgICJBcmUgeW91IHN1
REM #cmUgeW91IHdhbnQgdG8gc2tpcCB0byB0aGUgbmV4dCBjaG9pY2U/IjogdSJUZW0gY2VydGV6YSBk
REM #ZSBxdWUgZGVzZWphIGF2YW7Dp2FyIGF0w6kgYSBwcsOzeGltYSBlc2NvbGhhPyIsCiAgICAgICAg
REM #Ik9wZW4iOiB1IkFicmlyIiwKICAgICAgICAiQ29weSI6IHUiQ29waWFyIiwKICAgICAgICAiQ29w
REM #aWVzIHRoZSB0cmFjZWJhY2sudHh0IGZpbGUgdG8gdGhlIGNsaXBib2FyZC4iOiB1IkNvcGlhIG8g
REM #YXJxdWl2byB0cmFjZWJhY2sudHh0IHBhcmEgYSDDoXJlYSBkZSB0cmFuc2ZlcsOqbmNpYS4iLAog
REM #ICAgICAgICJDb25zb2xlIjogdSJDb25zb2xlIiwKICAgICAgICAiT3BlbnMgYSBjb25zb2xlIHRv
REM #IGFsbG93IGRlYnVnZ2luZyB0aGUgcHJvYmxlbS4iOiB1IkFicmUgdW0gY29uc29sZSBwYXJhIHBl
REM #cm1pdGlyIGEgZGVwdXJhw6fDo28gZG8gcHJvYmxlbWEuIiwKICAgICAgICAiQ29weSBCQkNvZGUi
REM #OiB1IkNvcGlhciBCQkNvZGUiLAogICAgICAgICJDb3BpZXMgdGhlIHRyYWNlYmFjay50eHQgZmls
REM #ZSB0byB0aGUgY2xpcGJvYXJkIGFzIEJCY29kZSBmb3IgZm9ydW1zIGxpa2UgaHR0cHM6Ly9sZW1t
REM #YXNvZnQucmVuYWkudXMvLiI6IHUiQ29waWEgbyBhcnF1aXZvIHRyYWNlYmFjay50eHQgcGFyYSBh
REM #IMOhcmVhIGRlIHRyYW5zZmVyw6puY2lhIGNvbW8gQkJDb2RlIHBhcmEgZsOzcnVucyBjb21vIGh0
REM #dHBzOi8vbGVtbWFzb2Z0LnJlbmFpLnVzLy4iLAogICAgICAgICJDb3BpZXMgdGhlIGVycm9ycy50
REM #eHQgZmlsZSB0byB0aGUgY2xpcGJvYXJkLiI6IHUiQ29waWEgbyBhcnF1aXZvIGVycm9ycy50eHQg
REM #cGFyYSBhIMOhcmVhIGRlIHRyYW5zZmVyw6puY2lhLiIsCiAgICAgICAgIltuYW1lXSBbYXR0cmli
REM #dXRlc10gKGhpZGRlbikiOiB1IltuYW1lXSBbYXR0cmlidXRlc10gKG9jdWx0bykiLAogICAgICAg
REM #ICJbbmFtZV0gW2F0dHJpYnV0ZXNdIjogdSJbbmFtZV0gW2F0dHJpYnV0ZXNdIiwKICAgICAgICAi
REM #VHlwZSB0byBmaWx0ZXI6ICI6IHUiRGlnaXRlIHBhcmEgZmlsdHJhcjogIiwKICAgICAgICAiVGV4
REM #dHVyZXM6IFt0ZXhfY291bnRdIChbdGV4X3NpemVfbWI6LjFmXSBNQikiOiB1IlRleHR1cmFzOiBb
REM #dGV4X2NvdW50XSAoW3RleF9zaXplX21iOi4xZl0gTUIpIiwKICAgICAgICAiSW1hZ2UgY2FjaGU6
REM #IFtjYWNoZV9wY3Q6LjFmXSUgKFtjYWNoZV9zaXplX21iOi4xZl0gTUIpIjogdSJDYWNoZSBkZSBp
REM #bWFnZW5zOiBbY2FjaGVfcGN0Oi4xZl0lIChbY2FjaGVfc2l6ZV9tYjouMWZdIE1CKSIsCiAgICAg
REM #ICAgIlxcbntjb2xvcj0jY2ZjfeKclCBwcmVkaWN0ZWQgaW1hZ2UgKGdvb2Qpey9jb2xvcn1cXG57
REM #Y29sb3I9I2ZjY33inJggdW5wcmVkaWN0ZWQgaW1hZ2UgKGJhZCl7L2NvbG9yfVxcbntjb2xvcj0j
REM #ZmZmfURyYWcgdG8gbW92ZS57L2NvbG9yfSI6IHUiXFxue2NvbG9yPSNjZmN94pyUIGltYWdlbSBw
REM #cmV2aXN0YSAoYm9hKXsvY29sb3J9XFxue2NvbG9yPSNmY2N94pyYIGltYWdlbSBuw6NvIHByZXZp
REM #c3RhIChydWltKXsvY29sb3J9XFxue2NvbG9yPSNmZmZ9QXJyYXN0ZSBwYXJhIG1vdmVyLnsvY29s
REM #b3J9IiwKICAgICAgICAiSW5zcGVjdGluZyBTdHlsZXMgb2YgW2Rpc3BsYXlhYmxlX25hbWUhcV0i
REM #OiB1Ikluc3BlY2lvbmFuZG8gZXN0aWxvcyBkZSBbZGlzcGxheWFibGVfbmFtZSFxXSIsCiAgICAg
REM #ICAgImRpc3BsYXlhYmxlOiI6IHUiZWxlbWVudG8gdmlzdWFsOiIsCiAgICAgICAgIiAgICAgICAg
REM #KG5vIHByb3BlcnRpZXMgYWZmZWN0IHRoZSBkaXNwbGF5YWJsZSkiOiB1IiAgICAgICAgKG5lbmh1
REM #bWEgcHJvcHJpZWRhZGUgYWZldGEgbyBlbGVtZW50byB2aXN1YWwpIiwKICAgICAgICAiICAgICAg
REM #ICAoZGVmYXVsdCBwcm9wZXJ0aWVzIG9taXR0ZWQpIjogdSIgICAgICAgIChwcm9wcmllZGFkZXMg
REM #cGFkcsOjbyBvbWl0aWRhcykiLAogICAgICAgICI8cmVwcigpIGZhaWxlZD4iOiB1IjxyZXByKCkg
REM #ZmFsaG91PiIsCiAgICAgICAgIkFuIGVycm9yIGhhcyBvY2N1cnJlZDoiOiB1Ik9jb3JyZXUgdW0g
REM #ZXJybzoiLAogICAgICAgICJDaGVja2luZyBmb3IgdXBkYXRlcy4iOiB1IlZlcmlmaWNhbmRvIGF0
REM #dWFsaXphw6fDtWVzLiIsCiAgICAgICAgIkZpbmlzaGluZyB1cC4iOiB1IkZpbmFsaXphbmRvLiIs
REM #CiAgICAgICAgIlByb2NlZWQiOiB1IkNvbnRpbnVhciIsCiAgICAgICAgIk5QT1QiOiB1Ik5QT1Qi
REM #LAogICAgICAgICJQcmVzcyBvciBtb3ZlIHRoZSBbY29udHJvbCFzXSBba2luZF0uIjogdSJQcmVz
REM #c2lvbmUgb3UgbW92YSBbY29udHJvbCFzXSBba2luZF0uIiwKICAgIH0KICAgIF9kZGFjX2ZvcmNl
REM #X291dHB1dF9pbnRlcmZhY2UgPSB7CiAgICAgICAgdSJEZXNpc3RpciI6IHUiU2FpciIsCiAgICAg
REM #ICAgdSJkZXNpc3RpciI6IHUic2FpciIsCiAgICAgICAgdSJERVNJU1RJUiI6IHUiU0FJUiIsCiAg
REM #ICAgICAgdSJSZXRvcm5hciI6IHUiVm9sdGFyIiwKICAgICAgICB1InJldG9ybmFyIjogdSJ2b2x0
REM #YXIiLAogICAgICAgIHUiTm8iOiB1Ik7Do28iLAogICAgICAgIHUibm8iOiB1Im7Do28iLAogICAg
REM #ICAgIHUiTk8iOiB1Ik7Dg08iLAogICAgICAgIHUiWWVzIjogdSJTaW0iLAogICAgICAgIHUieWVz
REM #IjogdSJzaW0iLAogICAgICAgIHUiWUVTIjogdSJTSU0iLAogICAgfQogICAgdHJ5OgogICAgICAg
REM #IF9kZGFjX29yaWdpbmFsX3N0cmluZ190cmFuc2xhdGUgPSByZW5weS50cmFuc2xhdGlvbi5TdHJp
REM #bmdUcmFuc2xhdG9yLnRyYW5zbGF0ZQogICAgICAgIGRlZiBfZGRhY19mb3JjZWRfc3RyaW5nX3Ry
REM #YW5zbGF0ZShzZWxmLCBvbGQpOgogICAgICAgICAgICBpZiBvbGQgaW4gX2RkYWNfZm9yY2VfaW50
REM #ZXJmYWNlOgogICAgICAgICAgICAgICAgcmV0dXJuIF9kZGFjX2ZvcmNlX2ludGVyZmFjZVtvbGRd
REM #CiAgICAgICAgICAgIHRyYW5zbGF0ZWQgPSBfZGRhY19vcmlnaW5hbF9zdHJpbmdfdHJhbnNsYXRl
REM #KHNlbGYsIG9sZCkKICAgICAgICAgICAgcmV0dXJuIF9kZGFjX2ZvcmNlX291dHB1dF9pbnRlcmZh
REM #Y2UuZ2V0KHRyYW5zbGF0ZWQsIHRyYW5zbGF0ZWQpCiAgICAgICAgcmVucHkudHJhbnNsYXRpb24u
REM #U3RyaW5nVHJhbnNsYXRvci50cmFuc2xhdGUgPSBfZGRhY19mb3JjZWRfc3RyaW5nX3RyYW5zbGF0
REM #ZQogICAgZXhjZXB0OgogICAgICAgIHBhc3MK
REM ##DDAC_PTBR_PATCH_END##
