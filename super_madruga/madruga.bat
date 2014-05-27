@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################

if "%option_app%"=="completo" (
    
    :: Alerta usuários da rede
    call:alert_to_begin
    
    :: Executa ENVTRANF antes de compactar e enviar
    call:exec_envtranf "%dir_dados%" & if ERRORLEVEL 1 (call "%file_functions%" SAVE_ERROS_PRO "%madruga_display%" "%dir_dados%")

    :: Executa ATUPRECO
    call:exec_atupreco "%option_app%" "%dir_dados%" "matriz" & if ERRORLEVEL 1 (call "%file_functions%" SAVE_ERROS_PRO "%madruga_display%" "%dir_dados%")
    
)


:: Copia, compacta e envia os arquivos desejados
call:exec_bkp "%option_app%" "%bkp_option_local%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:exec_svn "%option_app%"


if "%option_app%"=="completo" (
    
    :: Executa processo de atualização da filial
    call:exec_reindexa "%dir_dados%" "" & if ERRORLEVEL 1 (call "%file_functions%" SAVE_ERROS_PRO "%madruga_display%" "%dir_dados%")
    call:exec_baixfil "%dir_dados%" "matriz" & if ERRORLEVEL 1 (call "%file_functions%" SAVE_ERROS_PRO "%madruga_display%" "%dir_dados%")
    
    :: Realiza backup e gera 'DADOS.RAR'
    call:exec_bkpdia "%option_app%"
    
)


goto CHECK_PARALLEL_PROCESSES


:: ###################


:WAIT_RETRY_PARALLEL_PROCESSES
:: Aguarda o tempo estipulado
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Aguardando %svn_wait_minutes% min."
ping -n %svn_wait_seconds% -w 500 0.0.0.1 > nul


:CHECK_PARALLEL_PROCESSES
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Verificando termino dos Processos Paralelos"

:: Verifica arquivo de LOG possui o processo finalizado OU falhou
call "%file_functions%" CHECK_EXEC_SUCCESS "%compacta_display%" & if ERRORLEVEL 1 (
    call "%file_functions%" CHECK_EXEC_ERROR "%compacta_display%" & if ERRORLEVEL 1 (goto WAIT_RETRY_PARALLEL_PROCESSES)
)
call "%file_functions%" CHECK_EXEC_SUCCESS "%svn_display%" & if ERRORLEVEL 1 (
    call "%file_functions%" CHECK_EXEC_ERROR "%svn_display%" & if ERRORLEVEL 1 (goto WAIT_RETRY_PARALLEL_PROCESSES)
)


call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Processos Paralelos finalizados"


:: ###################


:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup option -- prepara ambiente
::              -- %~1:option [in] - parâmetro de inicialização
:$created 31/10/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_madruga="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%madruga_display%" "%pid_madruga%" "pid_code_madruga" & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_madruga%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%madruga_display%" "%pid_madruga%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        
        if "%pid_code_madruga%"=="" ( exit /b 1 )
        
        :: Registra LOG e envia e-mail de erro, se PID existir
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_error%" "%log_exec_error%"
        call "%file_functions%" SEND_MAIL_ERROR "%option_app%"
        
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "%log_exec_success%"
        call "%file_functions%" CHECK_SUCCESS_FULL "%option_app%"
    )
    
    :: Envia LOG
    call:exec_svn_log "%option_app%" 
    
    if "%~1"=="error" ( exit /b 1 )
exit /b 0


:: ###################


:alert_to_begin -- avisa os usuários da rede para começar
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Aguardando %madruga_wait_minutes_x2% minuto(s) para iniciar rotinas de atualizacao da filial"
    
    send "%app_display%: Rotinas de atualização da filial serão iniciadas dentro de %madruga_wait_minutes_x2% minuto(s)." everyone /b
    ping -n %madruga_wait_seconds% -w 500 0.0.0.1 > nul
    
    send "%app_display%: Rotinas de atualização da filial serão iniciadas dentro de %madruga_wait_minutes% minuto(s). Por favor, feche o sistema." everyone /b
    ping -n %madruga_wait_seconds% -w 500 0.0.0.1 > nul
    
    send "%app_display%: Rotinas de atualização foram iniciadas!" everyone /b
    
    call "%file_functions%" KILL_USER "%dir_dados%" "somente_madruga"

exit /b 0
    

:exec_bkp option1 option2 -- executa BKP
::                        -- option1:%~1 [in, opt] - parâmetro do sistema
::                        -- option2:%~2 [in, opt] - parâmetro do sistema
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %bkp_display% (%~1)"
        call "%file_bkp%" "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %bkp_display% (%~1) (%~2)"
        call "%file_bkp%" "%~1" "%~2" & if ERRORLEVEL 1 ( exit /b 1 )
    )
    
exit /b 0


:exec_bkpdia option -- executa BKPDIA
::                  -- option:%~1 [in, opt] - parâmetro do sistema
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %bkpdia_display% (%~1)"
    call "%file_bkpdia%" "%~1" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:exec_compacta option -- executa COMPACTA
::                    -- option:%~1 [in, opt] - parâmetro do sistema
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %compacta_display% (%~1)"
    call "%file_compacta%" "%~1" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:exec_svn option -- executa SVN
::               -- option:%~1 [in, opt] - parâmetro do sistema
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    
    if "%~1"=="completo" ( 
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando Paralelamente %svn_display% (%~1)"
        start call "%file_svn%" "%~1" ^& exit
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %svn_display% (%~1)"
        call "%file_svn%" "%~1"
    )
    
exit /b 0


:exec_madruga option -- executa MADRUGA
::                   -- option:%~1 [in, opt] - parâmetro do sistema
:$created 26/10/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando Paralelamente %madruga_display% (%~1)"
    start call "%file_madruga%" "%~1" ^& exit
    
exit /b 0


:exec_atupreco app_option path option  -- executa ATUPRECO
::                                     -- %~1:path   [in] - diretório base
::                                     -- %~2:option [in] - parâmetro da aplicação
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~3"=="" (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atupreco_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atupreco_display% (%~3)" 
    )
    call "%file_atupreco%" "%~1" "%~2" "%~3" & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:exec_svn_log option -- executa SVN
::                   -- %~1:option  [in] - parâmetro de configuração
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Copia arquivos de log para 'dir_svn_filial' (não registra LOG)
    call "%file_functions%" NOLOG_COPY_FILES "%madruga_display%" "%dir_app_log%" "%dir_svn_filial%" "%~1%csv_files%" "/W:10"
    
    :: Executa SVN
    call "%file_svn%" "%~1" "log"

exit /b 0


:exec_envtranf path -- executa ENVTRANF
::                  -- %~1:path [in] - diretório base
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %envtranf_display%"
    call "%file_functions%" SAVE_LOG "%envtranf_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_envtranf% 99
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%envtranf_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%envtranf_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_baixfil path option -- executa BAIXFIL
::                        -- %~1:path   [in] - diretório base
::                        -- %~2:option [in] - parâmetro da aplicação
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %baixfil_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %baixfil_display% (%~2)" 
    )
    call "%file_functions%" SAVE_LOG "%baixfil_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_baixfil% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%baixfil_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    
	:: Aguarda 10 segundos
	call "%file_functions%" WAIT_SECONDS "10"
	
	:: Verifica se foi executado com sucesso
	dir %~1%ok_baixfil% | findstr /I %date:~4,10% & if ERRORLEVEL 1 (
		call "%file_functions%" SAVE_LOG "%baixfil_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
	)
	
    call "%file_functions%" SAVE_LOG "%baixfil_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
	
    
exit /b 0


:exec_altfabr path -- executa ALTFABR
::                 -- %~1:path [in] - diretório base
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %altfabr_display%"
    call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir% 
    
    %file_altfabr%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    
	:: Aguarda 10 segundos
	call "%file_functions%" WAIT_SECONDS "10"
	
	:: Verifica se foi executado com sucesso
	dir %~1%ok_altfabr% | findstr /I %date:~4,10% & if ERRORLEVEL 1 (
		call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
	)
	
    call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_reindexa path option -- executa REINDEXA
::                         -- %~1:path   [in] - diretório base
::                         -- %~1:option [in] - parâmetro da aplicação
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %reindexa_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %reindexa_display% (%~2)" 
    )
    call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_reindexa% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
	
	:: Aguarda 10 segundos
	call "%file_functions%" WAIT_SECONDS "10"
	
	:: Verifica se foi executado com sucesso
	dir %~1%ok_reindexa% | findstr /I %date:~4,10% & if ERRORLEVEL 1 (
		call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
	)
	
    call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_imppreco path file -- executa IMPPRECO
::                       -- %~1:path [in] - diretório base
::                       -- %~1:file [in] - arquivo com os precos
:$created 23/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %imppreco_display% (%~2)" 
    call "%file_functions%" SAVE_LOG "%imppreco_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_imppreco% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%imppreco_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%imppreco_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0
