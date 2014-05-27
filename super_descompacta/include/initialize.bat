@echo off
for /f "tokens=*" %%A in ('dir /ad /b') do ( set "dir_app_%%A=%%~dA%%~pA%%A\" )
set "dir_app_filiais=%dir_app_config%filiais\"


:: Carrega arquivo de configuração 'app.ini'
for /f "tokens=1,2* delims=^=" %%A in (%dir_app_config%app.ini) do (call:set_var "%%A" "%%B")


:: ###################


:: INCLUDE
set "file_functions=%dir_app_include%functions.bat"

:: ROTINA
set /a "files_copied_errors=0"
set "file_pid_extension=pid"
set "file_pts_extension=pts"
set "file_tmp_extension=tmp"
set "all_files=[all].[all]"
set "rar_files=[all].r[all]"
set "dbf_files=[all].db[x]"
set "csv_files=[all].csv"


:: LOG
set "log_success=OK"
set "log_error=ERRO"
set "log_fatal_error=ERRO FATAL"
set "log_exec_success=Finalizado"
set "log_exec_error=Falhou"
set "file_log_extension=csv"

:: SVN
set /a "svn_update_wait_seconds=svn_update_wait_minutes*30"

:: BLAT
set "file_blat_temp=%dir_app_temp%blat.tmp"

:: DESCOMPACTA
set "file_descompacta=%dir_app%descompacta.bat"
set "pid_descompacta=%dir_app_pid%%computername%descompacta"


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
