@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Se parâmetro 'log' foi informado, sai da rotina
::  -> Apenas envia arquivo de log (sem registrar LOG)
if "%~2"=="log" (goto STARTUP_SEND_LOG)


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################

:: Se COMPACTA não foi executado com sucesso, chama-o novamente
call "%file_functions%" CHECK_EXEC_SUCCESS %compacta_display% & if ERRORLEVEL 1 (call:exec_compacta "%option_app%" & if ERRORLEVEL 1 (call:end error & exit /b 1))

:: ###################


:DELETE

:: Verifica se o diretório existe
if not exist %dir_svn_filial%nul (
	call:checkout_svn "%dir_svn_filial%" & if ERRORLEVEL 1 (goto WAIT_RETRY_DELETE)
)

call:update_svn "%dir_svn_filial%" & if ERRORLEVEL 1 (goto WAIT_RETRY_DELETE)
call:delete_svn "%dir_svn_filial%" "%option_app%"

:: Se em algum arquivo falhou, tenta novamente
if "%files_deleted_errors%" GEQ "1" goto WAIT_RETRY_DELETE

:: Copia TODOS os arquivos da pasta 'dir_compacta_local' para 'dir_svn_filial' e verifica se todos foram copiados
call "%file_functions%" COPY_FILES "%svn_display%" "%dir_compacta_local%" "%dir_svn_filial%" "%all_files%" "/W:10"
call "%file_functions%" CHECK_FILES_COPIED "%svn_display%" "%dir_compacta_local%" "%dir_svn_filial%" "%all_files%" & if ERRORLEVEL 1 (call:end error & exit /b 1)

:: Copia arquivo de log para 'dir_svn_filial' (sem registrar LOG)
call "%file_functions%" NOLOG_COPY_FILES "%svn_display%" "%dir_app_log%" "%dir_svn_filial%" "%option_app%%csv_files%" "/W:10"

:: Concluído, chama ADD
goto ADD


:WAIT_RETRY_DELETE
:: Acrescenta 1 ao marcador
set /a "svn_error+=1"

:: Se atingiu limite maximo de tentativas, envia e-mail e zera marcador
if "%svn_error%" GEQ "%svn_try_after_sendmail%" (
    call "%file_functions%" SEND_MAIL_ERROR
    set /a "svn_error=0"
)

:: Apaga diretório e aguarda o tempo estipulado e chama DELETE
call "%file_functions%" DELETE_DIR "%dir_svn_filial%" "/S /Q"
call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
ping -n %svn_wait_seconds% -w 500 0.0.0.1 > nul
goto DELETE


:: ###################


:ADD
call:add_svn "%dir_svn_filial%" "%option_app%"

:: Se em algum arquivo falhou, tenta novamente
if "%files_added_errors%" GEQ "1" goto WAIT_RETRY_ADD

:: Concluído, chama SUCCESS
goto SUCCESS


:WAIT_RETRY_ADD
:: Acrescenta 1 ao marcador
set /a "svn_error+=1"

:: Se atingiu limite maximo de tentativas, envia e-mail e zera marcador
if "%svn_error%" GEQ "%svn_try_after_sendmail%" (
    call "%file_functions%" SEND_MAIL_ERROR
    set /a "svn_error=0"
)

:: Aguarda o tempo estipulado e chama ADD
call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
ping -n %svn_wait_seconds% -w 500 0.0.0.1 > nul
goto ADD


:: ###################


:SUCCESS
call:end
goto SEND_LOG


:: ###################
:: ###################


:startup option -- prepara ambiente
::              -- %~1:option [in] - parâmetro de inicialização
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_svn="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%svn_display%" "%pid_svn%" "pid_code_svn" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:end error -- encerra processamento
::         -- %~1:error [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_svn%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%svn_display%" "%pid_svn%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "%log_exec_success%"
    
exit /b 0


:: ###################


:exec_compacta option -- executa COMPACTA
::                    -- option:%~1 [in] - parâmetro do sistema
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Executando %compacta_display% (%~1)"
    call "%file_compacta%" "%~1" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:checkout_svn path -- realiza checkout do repositório
::                 -- %~1:path [in] - diretorio
:$created 05/01/2012 :$author Pedro Elsner
:$updated  :$by 

    call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Criando repositorio '%~1'"
    
    svn checkout %svn_auth% %svn_connection_filial% %~1 & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Erro ao criar repositorio"
        exit /b 1
    )

exit /b 0


:update_svn path -- atualiza o diretório
::               -- %~1:path [in] - diretorio
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 

    :: Prepara repositório
    svn upgrade %svn_auth% %~1
    svn cleanup %svn_auth% %~1
    
    call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Atualizando repositorio '%~1'"
    
    svn update %svn_auth% --accept theirs-full %~1 & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Erro ao atualizar repositorio"
        exit /b 1
    )

exit /b 0


:delete_svn path option -- apaga os arquivos
::                      -- %~1:path   [in] - diretório
::                      -- %~2:option [in] - parâmetro do sistema
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Reseta variável
    set /a "files_deleted_errors=0"
    
    :: Verifica se exite arquivos no diretorio
    setlocal
    for /f "tokens=*" %%A in ('dir /a-d /b "%~1%~2*.*" ^| find /n /c /v ""') do (set "temp_count_files=%%A")
    endlocal & if "%temp_count_files%"=="0" (exit /b 0)
    
    
    call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Excluindo (%~2*.*) de '%~1'"

    for /f "tokens=*" %%G in ('dir /a-d /b "%~1%~2*.*"') do (
        svn delete %svn_auth% %~1%%G --force
        if ERRORLEVEL 1 (
            call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Erro ao excluir '%%G'"
            set /a "files_deleted_errors+=1"
        ) else (
            svn commit %svn_auth% -m '' %~1%%G
            if ERRORLEVEL 1 (
                call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Erro ao excluir '%%G'"
                set /a "files_deleted_errors+=1"
            )
        )
    )
    
    if "%files_deleted_errors%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Concluido com erro(s): %files_deleted_errors%"
    )

exit /b 0


:add_svn path option -- adiciona os arquivos
::                   -- %~1:path   [in] - diretório
::                   -- %~2:option [in] - parâmetro do sistema
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Reseta variável
    set /a "files_added_errors=0"

    call "%file_functions%" SAVE_LOG "%svn_display%" "%log_success%" "Enviando (%~2*.*) de '%~1'"

    for /f "tokens=*" %%G in ('dir /a-d /b "%~1%~2*.*"') do (
        svn add %svn_auth% %~1%%G --force
        if ERRORLEVEL 1 (
            call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Erro ao enviar '%%G'"
            set /a "files_added_errors+=1"
        ) else (
            svn commit %svn_auth% -m '' %~1%%G
            if ERRORLEVEL 1 (
                call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Erro ao enviar '%%G'"
                set /a "files_added_errors+=1"
            )
        )
    )
    
    if "%files_added_errors%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%svn_display%" "%log_error%" "Concluido com erro(s): %files_added_errors%"
    )

exit /b 0


:: ###################
:: ###################


:STARTUP_SEND_LOG
:: Carrega configurações
call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
goto SEND_LOG


:WAIT_RETRY_SEND_LOG
:: Aguarda o tempo estipulado
ping -n %svn_sendlog_wait_seconds% -w 500 0.0.0.1 > nul


:SEND_LOG
:: Prepara repositório
svn upgrade %svn_auth% %dir_svn_filial%
svn cleanup %svn_auth% %dir_svn_filial%

:: Atualiza
svn update %svn_auth% --accept theirs-full %~1 & if ERRORLEVEL 1 (goto WAIT_RETRY_SEND_LOG)

:: Verifica se exite arquivos no diretorio e exclui
setlocal
for /f "tokens=*" %%A in ('dir /a-d /b "%dir_svn_filial%/%option_app%*.csv" ^| find /n /c /v ""') do (set "temp_count_files=%%A")
endlocal & if "%temp_count_files%" GTR "0" (
    
    :: Reseta variável
    set /a "files_deleted_errors=0"
    
    for /f "tokens=*" %%G in ('dir /a-d /b "%dir_svn_filial%/%option_app%*.csv"') do (
        svn delete %svn_auth% %dir_svn_filial%/%%G --force
        if ERRORLEVEL 1 (
            set /a "files_deleted_errors+=1"
        ) else (
            svn commit %svn_auth% -m '' %dir_svn_filial%/%%G
            if ERRORLEVEL 1 (set /a "files_deleted_errors+=1")
        )
    )
    
    if "%files_deleted_errors%" GEQ "1" (goto WAIT_RETRY_SEND_LOG)
    
)

:: Copia arquivo de log para 'dir_svn_filial' (sem registrar LOG)
call "%file_functions%" NOLOG_COPY_FILES "%compacta_display%" "%dir_app_log%" "%dir_svn_filial%" "%option_app%%csv_files%" "/W:10" & if ERRORLEVEL 1 (goto WAIT_RETRY_SEND_LOG)

:: Adiciona e Envia
set /a "files_added_errors=0"
    
for /f "tokens=*" %%G in ('dir /a-d /b "%dir_svn_filial%/%option_app%*.csv"') do (
    svn add %svn_auth% %dir_svn_filial%/%%G --force
    if ERRORLEVEL 1 (
        set /a "files_added_errors+=1"
    ) else (
        svn commit %svn_auth% -m '' %dir_svn_filial%/%%G
        if ERRORLEVEL 1 (set /a "files_added_errors+=1")
    )
)

if "%files_added_errors%" GEQ "1" (goto WAIT_RETRY_SEND_LOG)
