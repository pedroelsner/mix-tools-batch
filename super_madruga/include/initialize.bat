@echo off
for /f "tokens=*" %%A in ('dir /ad /b') do ( set "dir_app_%%A=%%~dA%%~pA%%A\" )
set "dir_app_erro=%dir_app_log%erro\"


:: Carrega arquivo de configuração 'filial.ini'
if exist %dir_app_config%filial.ini (
    for /f "tokens=1,2* delims=^=" %%A in (%dir_app_config%filial.ini) do (call:set_var "%%A" "%%B")
)

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
set "filename_erros_pro=erros.pro"

:: pyBLAT
set "file_pyblat=%dir_app_lib%pyBlat.exe"

:: BLAT
set "file_blat_temp=%dir_app_temp%blat.tmp"

:: KILLUSER
set "file_killuser=%dir_fontes%killuser.exe"

:: ENVTRANF
set "file_envtranf=%dir_fontes%envtranf.exe"

:: REINDEXA
set "file_reindexa=%dir_fontes%reindexa.exe"
set "ok_reindexa=reindexa.ok"

:: ALTFABR
set "file_altfabr=%dir_fontes%altfabr.exe"
set "ok_altfabr=altfabr.ok"

:: BAIXFIL
set "file_baixfil=%dir_fontes%baixfil.exe"
set "ok_baixfil=baixfil.ok"

:: IMPPRECO
set "file_imppreco=%dir_fontes%imppreco.exe"


:: ###################


:: MADRUGA
set "file_madruga=%dir_app%madruga.bat"
set /a "madruga_wait_seconds=madruga_wait_minutes*30"
set /a "madruga_wait_minutes_x2=madruga_wait_minutes*2"
set /a "madruga_wait_seconds_x2=madruga_wait_minutes_x2*30"

:: BKP
set "file_bkp=%dir_app%bkp.bat"
set "bkp_option_local=local"
set "bkp_option_rede=rede"

:: BKPDIA
set "file_bkpdia=%dir_app%bkpdia.bat"

:: COMPACTA
set "file_compacta=%dir_app%compacta.bat"
set "compacta_prefix_files=sm"

:: AUTPRECO
set "file_atupreco=%dir_app%atupreco.bat"
set "lib_atupreco=%dir_fontes%atupreco.exe"
set "ok_atupreco=atupreco.ok"

:: SVN
set "file_svn=%dir_app%svn_atualiza.bat"
set "svn_auth=--username %svn_username% --password %svn_password%"
set "dir_svn_matriz=%dir_svn%%matriz_svn%\"
set "svn_connection_matriz=svn://%svn_server%/var/svn/%matriz_svn%"
set "dir_svn_filial=%dir_svn%%filial_svn%\"
set "svn_connection_filial=svn://%svn_server%/var/svn/%filial_svn%"
set /a "svn_error=0"
set /a "svn_wait_seconds=svn_wait_minutes*30"
set /a "svn_sendlog_wait_seconds=svn_sendlog_wait_minutes*30"
set /a "svn_update_wait_seconds=svn_update_wait_minutes*30"


:: ###################


:: Se arquivo de configuração da filial NÃO existe, sai da rotina
if not exist %dir_app_config%filial.ini (
    call:fatal_error "Arquivo de configuracao 'filial.ini' nao foi encontrado"
    exit /b 1
)


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
