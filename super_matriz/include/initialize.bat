@echo off
for /f "tokens=*" %%A in ('dir /ad /b') do ( set "dir_app_%%A=%%~dA%%~pA%%A\" )
set "dir_app_filiais=%dir_app_config%filiais\"

:: Carrega arquivo de configuração 'app.ini'
for /f "tokens=1,2* delims=^=" %%A in (%dir_app_config%app.ini) do (call:set_var "%%A" "%%B")


:: ###################


:: INCLUDE
set "file_functions=%dir_app_include%functions.bat"

:: ROTINAS
set "files_extensions="
set /a "files_copied_errors=0"
set "all_files=[all].[all]"
set "exe_files=[all].exe"
set "csv_files=[all].csv"
set "rar_files=[all].r[x][x]"
set "precodrd_file=precodrd.ace"

:: LOG
set "log_success=OK"
set "log_error=ERRO"
set "log_fatal_error=ERRO FATAL"
set "log_exec_sintaxe_error=A sintaxe do comando esta incorreta"
set "log_exec_invalid_param=O parametro informado esta incorreto"
set "log_exec_success=Finalizado"
set "log_exec_error=Falhou"
set "file_log_extension=csv"
set "file_log=%dir_app_log%log.%file_log_extension%"
set "file_log_temp=%dir_app_temp%log.tmp"

:: SVN
set "svn_auth=--username %svn_username% --password %svn_password%"
set "dir_svn_matriz=%dir_svn%%matriz_svn%\"
set "svn_connection_matriz=svn://%svn_server%/var/svn/%matriz_svn%"
set /a "svn_error=0"
set /a "svn_wait_seconds=svn_wait_minutes*30"
set /a "svn_sendlog_wait_seconds=svn_sendlog_wait_minutes*30"
set /a "svn_update_wait_seconds=svn_update_wait_minutes*30"

:: BLAT
set "file_blat_temp=%dir_app_temp%blat.tmp"

:: MADRUGA
set "file_madruga=%dir_app%madruga.bat"
set "pid_madruga=%dir_app_pid%madruga.pid"

:: DISCOJ
set "file_discoj=%dir_app%discoj.bat"
set "pid_discoj=%dir_app_pid%discoj.pid"
set "dir_precodrd=%dir_matriz%PRECODRD\"
set "list_precodrd=%dir_app_config%precodrd.lst"
if not exist %list_precodrd% (
    call:FATAL_ERROR "O arquivo de configuracao '%dir_app_config%precodrd.lst' nao foi encontrado"
    exit /b 1
)
setlocal ENABLEDELAYEDEXPANSION
for /f "tokens=*" %%A in (%list_precodrd%) do (set "temp_discoj_list_precodrd=%%A !temp_discoj_list_precodrd!")
endlocal & set "discoj_list_precodrd=%temp_discoj_list_precodrd%"


:: ###################


:: EFETEXE
set "file_efetexe=%dir_fontes%efetexe.exe"

:: ADSDOSIP
set "file_adsdosip=%dir_fontes%adsdosip.exe"

:: NLIST
set "file_nlist=%dir_public%nlist.exe"
set "nlist_user_result=%dir_app_log%users.txt"

:: SYSTIME
set "file_systime=%dir_public%systime.exe"

:: ATU_DTUC
set "file_atu_dtuc=%dir_fontes%atu_dtuc.exe"

:: REINDEXA
set "file_reindexa=%dir_fontes%reindexa.exe"

:: ATUPEDCP
set "file_atupedcp=%dir_fontes%atupedcp.exe"

:: ALTFABR
set "file_altfabr=%dir_fontes%altfabr.exe"
set "prn_altf=%dir_matriz%altf.prn"

:: BUSCABO
set "file_buscabo=%dir_fontes%buscabo.exe"

:: DIVCPA
set "file_divcpa=%dir_fontes%divcpa.exe"

:: LIMPAPRN
set "file_limpaprn=%dir_fontes%limpaprn.exe"

:: COMFIL
set "file_comfil=%dir_fontes%comfil.exe"

:: ATUDF
set "file_atudf=%dir_fontes%atudf.exe"

:: EMBARQUE
set "file_embarque=%dir_fontes%embarque.exe"

:: ALRTPROT
set "file_alrtprot=%dir_fontes%alrtprot.exe"

:: ATUCPA
set "file_atucpa=%dir_fontes%atucpa.exe"

:: ENVTRANF
set "file_envtranf=%dir_fontes%envtranf.exe"

:: TRANSITO
set "file_transito=%dir_fontes%transito.exe"

:: PEDCPA
set "file_pedcpa=%dir_fontes%pedcpa.exe"

:: ENVFIL
set "file_envfil=%dir_fontes%envfil.exe"

:: GERPRECO
set "file_gerpreco=%dir_fontes%gerpreco.exe"

:: REPRES2
set "file_repres2=%dir_fontes%repres2.exe"

:: COPIINV
set "file_copiinv=%dir_fontes%copiinv.exe"

:: BKPF
set "file_bkpf=%dir_fontes%bkpf.exe"

:: INDXLUIZ
set "file_indxluiz=%dir_fontes%indxluiz.exe"

:: TPINDEXA
set "file_tpindexa=%dir_fontes%tpindexa.exe"


:: ###################


:: Fim
exit /b 0


:: ###################
:: ###################


:set_var var value -- define variável
::                 -- %~1:var   [in] - variável
::                 -- %~2:value [in] - valor
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    setlocal
        set "temp_var=%~1"
        if "%temp_var%"=="" (exit /b 1)
        if "%temp_var:~0,1%"=="#" (exit /b 1)
    endlocal
    
    set "%~1=%~2" > nul
    
exit /b 0


:fatal_error message -- mostra mensagem de erro
::                   -- %~1:message [in] - mensagem
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by    
    
    echo [%log_fatal_error%] %app_display%: %~1
    
exit /b 0
