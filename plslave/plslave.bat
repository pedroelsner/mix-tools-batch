@echo off
for /f "tokens=*" %%A in ('dir plslave.bat /b /s') do ( set "plslave_dir=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "plslave_drive=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:UPDATE
:: Verifica se respositório da filial existe
if not exist %filial_svn_dir%nul (
	call:checkout_svn & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
)

if not exist %filial_svn_dir_log%nul (
	call "%file_functions%" MAKE_DIR "%plslave_display%" "%filial_svn_dir_log%"
    call:add_svn "%filial_svn_dir_log%" & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
)

if not exist %filial_svn_dir_pid%nul (
    call "%file_functions%" MAKE_DIR "%plslave_display%" "%filial_svn_dir_pid%"
	call:add_svn "%filial_svn_dir_pid%" & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
)


:: Concluído, chama CONTINUE
goto CONTINUE


:WAIT_RETRY_UPDATE
:: Apaga diretório e aguarda o tempo estipulado e chama UPDATE
call "%file_functions%" DELETE_DIR "%filial_svn_dir%" "/S /Q"
call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
call "%file_functions%" WAIT_SECONDS %svn_wait_seconds%
goto UPDATE


:: ###################


:CONTINUE
:: Executa aplicação
call %app_main%
if %exec_name%null==null (call:end & exit /b 0)


:: Desativa LOG em arquivo
set "save_log=false"


call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Encerrando: Por favor, aguarde..."
call "%file_functions%" WAIT_SECONDS 2
call "%file_functions%" XCOPY_FILE "%app_log%" "%filial_svn_dir_log%" "/S /Y"
call "%file_functions%" XCOPY_FILE "%app_pid%" "%filial_svn_dir_pid%" "/S /Y"
if exist %app_plsqlbigsk_log% (
    call "%file_functions%" XCOPY_FILE "%app_plsqlbigsk_log%" "%filial_svn_dir_log%" "/S /Y"
)
call "%file_functions%" WAIT_SECONDS 2


:SEND_LOG
call:add_svn "%app_svn_log%" & if ERRORLEVEL 1 (goto SEND_LOG_WAIT)
goto SEND_PID

:SEND_LOG_WAIT
call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Tentando novamente em %svn_wait_minutes% min."
call "%file_functions%" WAIT_SECONDS %svn_wait_seconds%
goto SEND_LOG

:SEND_PID
call:add_svn "%app_svn_pid%" & if ERRORLEVEL 1 (goto SEND_PID_WAIT)
goto SEND_PLSQLBIGSK

:SEND_PID_WAIT
call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Tentando novamente em %svn_wait_minutes% min."
call "%file_functions%" WAIT_SECONDS %svn_wait_seconds%
goto SEND_PID

:SEND_PLSQLBIGSK
if exist %app_plsqlbigsk_svn_log% (
    call:add_svn "%app_plsqlbigsk_svn_log%" & if ERRORLEVEL 1 (goto SEND_PLSQLBIGSK_WAIT)
)
goto FIM

:SEND_PLSQLBIGSK_WAIT
call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Tentando novamente em %svn_wait_minutes% min."
call "%file_functions%" WAIT_SECONDS %svn_wait_seconds%
goto SEND_PLSQLBIGSK


:: ###################

:FIM
:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup option -- prepara ambiente
::              -- %~1:option [in] - parâmetro de inicialização
:$created 06/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Iniciado"
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 06/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "%log_exec_success%"
    
exit /b 0


:: ###################


:checkout_svn -- realiza checkout do repositório
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 

    call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Criando repositorio '%filial_svn_dir%'"
    
    svn checkout %filial_svn_connection% %filial_svn_dir% & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_error%" "Erro ao criar repositorio"
        exit /b 1
    )

exit /b 0


:update_svn -- atualiza o diretório
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 

    :: Prepara repositório
    svn upgrade %filial_svn_dir%
    svn cleanup %filial_svn_dir%
    
    call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Atualizando repositorio '%filial_svn_dir%'"
    
    svn update --accept theirs-full %filial_svn_dir% & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_error%" "Erro ao atualizar repositorio"
        exit /b 1
    )

exit /b 0


:add_svn path option -- adiciona os arquivos
::                   -- %~1:file [in] - diretório
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Reseta variável
    set /a "files_added_errors=0"

    call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_success%" "Enviando '%~1' para repositorio '%filial_svn%'"
    svn add %filial_svn_auth% %~1 --force
    if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_error%" "Erro ao enviar '%~1'"
        set /a "files_added_errors+=1"
    ) else (
        svn commit %filial_svn_auth% -m '' %~1
        if ERRORLEVEL 1 (
            call "%file_functions%" SAVE_LOG "%plslave_display%" "%log_error%" "Erro ao enviar '%~1'"
            set /a "files_added_errors+=1"
        )
    )
    
exit /b 0
