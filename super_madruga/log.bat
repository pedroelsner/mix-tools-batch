@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A")
if ERRORLEVEL 1 (exit /b 1)

:: Carrega configurações
call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )


:: ###############
:: ###############


:: Exibe rotinas processadas com sucesso
find "%log_success%;%log_exec_success%" "%file_log%"

:: Exibe rotinas processadas com erro
find "%log_error%;%log_exec_error%" "%file_log%"


:: ###############
:: ###############


:: Encerra todo o processo
exit /b 0
