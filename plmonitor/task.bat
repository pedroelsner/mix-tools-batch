@echo off
for /f "tokens=*" %%A in ('dir plmonitor.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1 )


:: ###################


:: Inicializa
goto MAIN


:: ###################
:: ###################


:svn_update -- atualiza todos os arquivos do super-descompacta
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


:wait_seconds seconds -- aguarda alguns segundos
::                           -- %~1:seconds [in] - segundos para esperar
:$created 11/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    ping -n %~1 -w 500 0.0.0.1 > nul

exit /b 0 


:: ###################
:: ###################


:WAIT_RETRY_UPDATE
call:fatal_error "Nao foi possivel atualiza o %app_display%"
call:fatal_error "Aguarndando %svn_update_wait_minutes% min. para reiniciar"
call:wait_seconds %svn_update_wait_seconds%


:MAIN
call:svn_update & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)


:: ###################


for %%A in (%dir_app_repositories%*) do (
    call %dir_app%plmonitor.bat %%~nA
)

:: Encerra todo o processo
exit /b 0
