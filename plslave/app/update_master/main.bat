@echo off

:: Inicializa
call:startup & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:UPDATE
:: Verifica se respositório da filial existe
if not exist %update_master_svn_dir%nul (
	call:checkout_svn & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
)


call:update_svn & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
goto CONTINUE


:WAIT_RETRY_UPDATE
:: Apaga diretório e aguarda o tempo estipulado e chama UPDATE
call "%file_functions%" SAVE_LOG "%plopen_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
call "%file_functions%" WAIT_SECONDS %svn_wait_seconds%
goto UPDATE


:: ###################


:CONTINUE
rem Fim



:: ###################


:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup option -- prepara ambiente
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    
    :: Carrega configurações
    call "%file_functions%" LOAD_APP & if ERRORLEVEL 1 ( exit /b 1 )
    
    
    :: ###################
    
    
    :: Carrega arquivo de configuração 'app.ini'
    set "app_ini=%app_dir%app.ini"
    if exist %app_ini% (
        for /f "tokens=1,2* delims=^=" %%A in (%app_dir%app.ini) do (call "%file_functions%" SET_VAR "%%A" "%%B")
    )
    
    :: SVN
    set "update_master_svn_dir=%svn_dir%%update_master_svn%\"
    set "update_master_svn_connection=svn://%svn_server%/var/svn/%update_master_svn%"
    set "update_master_svn_auth=--username %update_master_svn_username% --password %update_master_svn_password%"
    
    
    :: ###################
    
    
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "Iniciando"
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 06/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "%log_exec_success%"
    
exit /b 0


:: ###################


:checkout_svn -- realiza checkout do repositório
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 

    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "Criando repositorio '%update_master_svn_dir%'"
    
    svn checkout %update_master_svn_connection% %update_master_svn_dir% & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%app_display%" "%log_error%" "Erro ao criar repositorio"
        exit /b 1
    )

exit /b 0


:update_svn -- atualiza o diretório
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 

    :: Prepara repositório
    svn upgrade %update_master_svn_dir%
    svn cleanup %update_master_svn_dir%
    
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "Atualizando repositorio '%update_master_svn_dir%'"
    
    svn update --accept theirs-full %update_master_svn_dir% & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%update_master_svn_dir%" "%log_error%" "Erro ao atualizar repositorio"
        exit /b 1
    )

exit /b 0

