@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1 )


:: ###################


:: Inicializa
goto MAIN


:: ###################
:: ###################


:svn_atualiza_super_matriz -- atualiza todos os arquivos do super-matriz
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
:: Atualiza SUPER MATRIZ
call:svn_atualiza_super_matriz & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)


:: ###################


:: Executa 'MADRUGA' da matriz
call %file_madruga%


:: Encerra todo o processo
exit /b 0
