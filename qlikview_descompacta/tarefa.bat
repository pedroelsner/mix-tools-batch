@echo off
for /f "tokens=*" %%A in ('dir descompacta.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1 )


:: ###################


:: Inicializa
goto MAIN


:: ###################
:: ###################


:svn_atualiza_super_descompacta -- atualiza todos os arquivos do super-descompacta
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
:: Atualiza SUPER DESCOMPACTA
call:svn_atualiza_super_descompacta & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)


:: ###################


:: Define processo
if "%~1"=="" ( set "option_app=completo" ) else ( set "option_app=%~1" )

:: Verifica se arquivo de configuração existe
set "config_option=%dir_app_config%%option_app%.ini"
if not exist %config_option% (
    call:fatal_error "O parametro informado esta incorreto"
    exit /b 1
)


:: ###################


:: Executa 'DESCOMPACTA' para todas as filiais configuradas
for %%A in (%dir_app_filiais%*) do (
    start /MIN call %file_descompacta% %option_app% %%~nA ^& exit
    ping -n 2 -w 500 0.0.0.1 > nul
)

:: Encerra todo o processo
exit /b 0
