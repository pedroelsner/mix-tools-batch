@echo off
for /f "tokens=*" %%A in ('dir /ad /b') do ( set "dir_app_%%A=%%~dA%%~pA%%A\" )


:: Carrega arquivo de configuração 'app.ini'
for /f "tokens=1,2* delims=^=" %%A in (%dir_app_config%app.ini) do (call:set_var "%%A" "%%B")


:: ###################


:: INCLUDE
set "file_functions=%dir_app_include%functions.bat"

:: Log
set "log_success=OK"
set "log_error=ERRO"
set "log_fatal_error=ERRO FATAL"
set "log_exec_sintaxe_error=A sintaxe do comando esta incorreta"
set "log_exec_invalid_param=O parametro informado esta incorreto"
set "log_exec_success=Finalizado"
set "log_exec_error=Falhou"

:: SVN
set /a "svn_update_wait_seconds=svn_update_wait_minutes*30"


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
