@echo off
for /f "tokens=*" %%A in ('dir plslave.bat /b /s') do ( set "plslave_dir=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "plslave_drive=%%~dA" & call "%%A")
if ERRORLEVEL 1 (exit /b 1)


:: ###################


:: Inicializa
goto MAIN


:: ###################
:: ###################


:svn_update -- atualiza todos os arquivos do plslave
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by

    svn upgrade %plslave_dir%
    svn cleanup %plslave_dir%
    svn update --accept theirs-full %plslave_dir% & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:fatal_error message -- mostra mensagem de erro
::                   -- %~1:message [in] - mensagem
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by    
    
    echo [%log_fatal_error%] %plslave_dir%: %~1
    
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
call:fatal_error "Nao foi possivel atualiza o %plslave_dir%"
call:fatal_error "Aguarndando %svn_update_wait_minutes% min. para reiniciar"
call:wait_seconds -n %svn_update_wait_seconds% -w 500 0.0.0.1 > nul


:MAIN
:: Atualiza
call:svn_update & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)


:: ###################


:: Executa PLSLAVE
call "%plslave_dir%plslave.bat" "update_master"

if "%filial_code%"=="00" (exit /b 0)

call "%plslave_dir%plslave.bat" "plsqlbigsk"
call "%plslave_dir%plslave.bat" "projac104"
call "%plslave_dir%plslave.bat" "totaltrq"
call "%plslave_dir%plslave.bat" "estadotrq"
rem call "%plslave_dir%plslave.bat" "filialtrq"
call "%plslave_dir%plslave.bat" "atualiza_permissao"


:: Encerra todo o processo
exit /b 0
