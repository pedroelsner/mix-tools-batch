@echo off
for /f "tokens=*" %%A in ('dir /ad /b') do ( set "plslave_dir_%%A=%%~dA%%~pA%%A\" )

:: Carrega arquivo de configuração 'filial.ini'
if exist %plslave_dir_config%filial.ini (
    for /f "tokens=1,2* delims=^=" %%A in (%plslave_dir_config%filial.ini) do (call:set_var "%%A" "%%B")
)

:: Carrega arquivo de configuração 'app.ini'
for /f "tokens=1,2* delims=^=" %%A in (%plslave_dir_config%app.ini) do (call:set_var "%%A" "%%B")


:: ###################


:: INCLUDE
set "file_functions=%plslave_dir_include%functions.bat"

:: ROTINAS
set "files_extensions="
set /a "files_copied_errors=0"
set "all_files=[all].[all]"
set "exe_files=[all].exe"
set "csv_files=[all].csv"
set "rar_files=[all].r[x][x]"
set "precodrd_file=precodrd.ace"

:: Log
set "save_log=true"
set "log_success=OK"
set "log_error=ERRO"
set "log_fatal_error=ERRO FATAL"
set "log_exec_sintaxe_error=A sintaxe do comando esta incorreta"
set "log_exec_invalid_param=O parametro informado esta incorreto"
set "log_exec_success=Finalizado"
set "log_exec_error=Falhou"

:: Temp
set "temp_datetime=%plslave_dir_temp%datetime.tmp"
set "temp_datetime_bkp=%plslave_dir_temp%datetime_bkp.tmp"

:: SVN
set "filial_svn_dir=%svn_dir%%filial_svn%\"
set "filial_svn_dir_log=%filial_svn_dir%log\"
set "filial_svn_dir_pid=%filial_svn_dir%pid\"
set "filial_svn_connection=svn://%svn_server%/var/svn/%filial_svn%"
set "filial_svn_auth=--username %filial_svn_username% --password %filial_svn_password%"
set /a "svn_error=0"
set /a "svn_wait_seconds=svn_wait_minutes*30"
set /a "svn_sendlog_wait_seconds=svn_sendlog_wait_minutes*30"
set /a "svn_update_wait_seconds=svn_update_wait_minutes*30"

:: Lib
set "file_plink=%plslave_dir_lib%plink.exe"
set "file_pyblat=%plslave_dir_lib%pyBlat.exe"
set "file_pydatetime=%plslave_dir_lib%pyDateTime.exe"
set "file_rar32=%plslave_dir_lib%rar32.exe"
set "file_robocopy=%plslave_dir_lib%robocopy.exe"
set "file_unrar=%plslave_dir_lib%unrar.exe"


:: Se arquivo de configuração da filial NÃO existe, sai da rotina
if not exist %plslave_dir_config%filial.ini (
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
