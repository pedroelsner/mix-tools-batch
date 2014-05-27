@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup "%~1" "%~2" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:UPDATE
:: Verifica se o diretório existe
if not exist %dir_svn_matriz%nul (
	call:checkout_svn "%dir_svn_matriz%" & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)
)

call:update_svn "%dir_svn_matriz%" & if ERRORLEVEL 1 (goto WAIT_RETRY_UPDATE)

:: Copia '%precodrd_file%' os arquivos da pasta 'dir_svn_matriz' para 'dir_dados' e verifica se todos foram copiados
call "%file_functions%" COPY_FILES "%atupreco_display%" "%dir_svn_matriz%" "%dir_dados%" "%precodrd_file%" "/W:10" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call "%file_functions%" CHECK_FILES_COPIED "%atupreco_display%" "%dir_svn_matriz%" "%dir_dados%" "%precodrd_file%" & if ERRORLEVEL 1 (call:end error & exit /b 1)

:: Concluído, chama CONTINUE
goto CONTINUE


:WAIT_RETRY_UPDATE
:: Acrescenta 1 ao marcador
set /a "svn_error+=1"

:: Se atingiu limite maximo de tentativas, envia e-mail e zera marcador
if "%svn_error%" GEQ "%svn_try_after_sendmail%" (
    call "%file_functions%" SEND_MAIL_ERROR
    set /a "svn_error=0"
)

:: Apaga diretório e aguarda o tempo estipulado e chama UPDATE
call "%file_functions%" DELETE_DIR "%dir_svn_matriz%" "/S /Q"
call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
ping -n %svn_wait_seconds% -w 500 0.0.0.1 > nul
goto UPDATE


:: ###################


:CONTINUE
call:exec_atupreco "%~2" "%~3" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: Apaga indice SEGCOML.NTX
call "%file_functions%" DELETE_FILE "%dir_dados%SEGCOML.NTX"
call "%file_functions%" DELETE_FILE "%dir_dados%LIBSENHA.NTX"


:: Fim
(call:end & exit /b 0)



:: ###################
:: ###################


:startup option path -- prepara ambiente
::                   -- %~1:option [in] - parâmetro de inicialização
::                   -- %~2:path   [in] - diretório
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_atupreco="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Verifica se o path foi informado
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_error%" "O diretorio para execucao do ATUPRECO nao foi informado"
        exit /b 1
    ) else (
        if not exist %~2 (
            call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_error%" "O diretorio para execucao do ATUPRECO nao existe"
            exit /b 1
        )
    )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%atupreco_display%" "%pid_atupreco%" "pid_code_atupreco" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:end error -- encerra processamento
::         -- %~1:error [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_atupreco%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%atupreco_display%" "%pid_atupreco%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_success%" "%log_exec_success%"
    
exit /b 0


:: ###################


:checkout_svn path -- realiza checkout do repositório
::                 -- %~1:path [in] - diretorio
:$created 05/01/2012 :$author Pedro Elsner
:$updated  :$by 

    call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_success%" "Criando repositorio '%~1'"
    
    svn checkout %svn_connection_matriz% %~1 & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_error%" "Erro ao criar repositorio"
        exit /b 1
    )

exit /b 0


:update_svn path -- atualiza o diretório
::               -- %~1:path [in] - diretorio
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 

    :: Prepara repositório
    svn upgrade %~1
    svn cleanup %~1
    
    call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_success%" "Atualizando repositorio '%~1'"
    
    svn update --accept theirs-full %~1 & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_error%" "Erro ao atualizar repositorio"
        exit /b 1
    )

exit /b 0


:exec_atupreco path option -- executa ATUPRECO
::                         -- %~1:path   [in] - diretório base
::                         -- %~2:option [in] - parâmetro da aplicação
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    call "%file_functions%" SAVE_LOG "%atupreco_display%" "%log_success%" "Executando '%lib_atupreco% %~2' em '%~1'"
    
    %lib_atupreco% %~2
    if "%errorlevel%" GEQ "1" (
        %drive_app% & cd %dir_app%
        exit /b 1
    )
	
	:: Aguarda 10 segundos
	call "%file_functions%" WAIT_SECONDS "10"
	
	:: Verifica se foi executado com sucesso
	dir %~1%ok_atupreco% | findstr /I %date:~4,10% & if ERRORLEVEL 1 (
        %drive_app% & cd %dir_app%
        exit /b 1
	)
	
    %drive_app% & cd %dir_app%
    
exit /b 0

