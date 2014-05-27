@echo off
for /f "tokens=*" %%A in ('dir plmonitor.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1 )


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:UPDATE
:: Verifica se respositório da filial existe
if not exist %repository_svn_dir%nul (
	call:checkout_svn & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
)


call:update_svn & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
goto CONTINUE


:WAIT_RETRY_UPDATE
:: Apaga diretório e aguarda o tempo estipulado e chama UPDATE
call "%file_functions%" LOG "%plopen_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
call "%file_functions%" WAIT_SECONDS %svn_wait_seconds%
goto UPDATE


:CONTINUE
(call:end & exit /b 0)


:: ###################
:: ###################


:startup repository -- prepara ambiente
::                  -- %~1:repository [in] - parâmetro de inicialização
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" LOG "%app_display%" "%log_success%" "Iniciado"
    
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    
    :: SVN
    set "repository_svn_dir=%svn_dir%%repository_name%\"
    set "repository_svn_connection=svn://%svn_server%/var/svn/%repository_name%"
    set "repository_svn_auth=--username %svn_username% --password %svn_password%"
    
    
    call "%file_functions%" LOG "%app_display%" "%log_success%" "Atualizando '%repository_name%'"
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~1"=="error" (
        call "%file_functions%" LOG "%app_display%" "%log_error%" "%log_exec_error%"
    ) else (
        call "%file_functions%" LOG "%app_display%" "%log_success%" "%log_exec_success%"
    )
    
    
    if "%~1"=="error" (exit /b 1)
exit /b 0


:: ###################


:: ###################


:checkout_svn -- realiza checkout do repositório
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 

    call "%file_functions%" LOG "%app_display%" "%log_success%" "Criando repositorio '%repository_name%'"
    
    svn checkout %repository_svn_connection% %repository_svn_dir% & if ERRORLEVEL 1 (
        call "%file_functions%" LOG "%app_display%" "%log_error%" "Erro ao criar repositorio"
        exit /b 1
    )

exit /b 0


:update_svn -- atualiza o diretório
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 

    :: Prepara repositório
    svn upgrade %repository_svn_dir%
    svn cleanup %repository_svn_dir%
    
    call "%file_functions%" LOG "%app_display%" "%log_success%" "Atualizando repositorio '%repository_svn_dir%'"
    
    svn update --accept theirs-full %repository_svn_dir% & if ERRORLEVEL 1 (
        call "%file_functions%" LOG "%repository_svn_dir%" "%log_error%" "Erro ao atualizar repositorio"
        exit /b 1
    )

exit /b 0

