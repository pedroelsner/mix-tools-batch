@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A")
if ERRORLEVEL 1 (exit /b 1)


:: ###################
:: ###################


:: Acessa diretório /PID
%dir_app_pid:~0,2% & cd %dir_app_pid%

:: Veirifica arquivos de PID e excluir o que pertencer a maquina
for /f "tokens=*" %%Z in ('dir *.pid /a-d /b') do (
    type %%Z | findstr %computername% > nul & if ERRORLEVEL 1 (echo .>nul) else (del %%Z /Q)
)

:: Volta para o diretório da aplicação
%dir_app:~0,2% & cd %dir_app%


:: Encerra todo o processo
exit /b 0
