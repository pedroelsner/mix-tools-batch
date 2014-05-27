@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A")
if ERRORLEVEL 1 (exit /b 1)


:: ###################


:: Inicializa
goto MAIN


:: ###################
:: ###################


:svn_atualiza_super_madruga -- atualiza todos os arquivos do super-madruga
:$created 18/11/2011 :$author Pedro Elsner
:$updated  :$by

    svn upgrade %dir_app%
    svn cleanup %dir_app%
    svn update --accept theirs-full %dir_app% & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:fatal_error message -- mostra mensagem de erro
::                   -- %~1:message [in] - mensagem
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by    
    
    echo [%log_fatal_error%] %app_display%: %~1
    
exit /b 0


:: ###################
:: ###################


:WAIT_RETRY_UPDATE
call:fatal_error "Nao foi possivel atualiza o %app_display%"
call:fatal_error "Aguarndando %svn_update_wait_minutes% min. para reiniciar"
:: Aguarda o tempo estipulado
ping -n %svn_update_wait_seconds% -w 500 0.0.0.1 > nul


:MAIN
:: Atualiza SUPER MADRUGA
call:svn_atualiza_super_madruga & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)

:: ###################


:: Define processo
if "%~1"=="" ( set "option_app=completo" ) else ( set "option_app=%~1" )

:: Verifica se arquivo de configuração existe
set "list_compacta=%dir_app_config%%option_app%\compacta.lst"
if not exist %list_compacta% (
    call:fatal_error "%log_exec_invalid_param%"
    exit /b 1
)
set "list_bkp_dados=%dir_app_config%%option_app%\bkp_dados.lst"
if not exist %list_bkp_dados% (
    call:fatal_error "%log_exec_invalid_param%"
    exit /b 1
)

:: ###################


:: Executa MADRUGA
call "%file_madruga%" "%option_app%"
REM if "%option_app%"=="completo" ( call "%file_madruga%" "estoque" )



:: Encerra todo o processo
exit /b 0
