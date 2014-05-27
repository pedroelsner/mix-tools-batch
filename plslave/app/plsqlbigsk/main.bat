@echo off

:: Inicializa
call:startup & if ERRORLEVEL 1 ( call:end error & exit /b 1 )


:: ###############

call:exec_descompacta & if ERRORLEVEL 1 ( call:end error & exit /b 1 )

call:exec_update & if ERRORLEVEL 1 ( call:end error & exit /b 1 )


:: ###############


:: Fim
(call:end & exit /b 0)


:: ###############
:: ###############


:startup option -- prepara ambiente
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    :: Carrega configurações
    call "%file_functions%" LOAD_APP & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Carrega variáveis
    call:initialize
    
    
    :: ###################
    
    
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "Verificando processos em '%plsqlbigsk_svn%'..."
    
    
    :: Lista todos os processos para executar
    setlocal ENABLEDELAYEDEXPANSION
    for %%A in (%plsqlbigsk_svn_dir%\*.rar) do (
        if !exec_name!null==null (
            :: Verifica se existe arquivo '.ini'
            if exist "%plsqlbigsk_svn_dir%\%%~nA.ini" (
                
                :: Verifica se processo já foi executado
                if not exist %app_pid% (
                    call "%file_functions%" SET_VAR "exec_name" "%%~nA"
                ) else (
                    type %app_pid% | findstr "%%~nA" > nul
                    if ERRORLEVEL 1 ( call "%file_functions%" SET_VAR "exec_name" "%%~nA" ) else (
                        call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "%%~nA (executado)"
                    )
                )
                
                if not !exec_name!null==null (
                     :: Carrega '.ini'
                     call:load_ini
                     :: Verifica agendamento da rotina
                     call:check_scheduler "%%~nA"
                )
                
            )
        )
    )
    endlocal & set "exec_name=%exec_name%"
    
    
    :: ##################
    
    if %exec_name%null==null ( exit /b 1 )
    
    :: ##################
    
    
    :: Log
    set "app_log=%plslave_dir_log%%app_name%-%exec_name%.csv"
    set "app_svn_log=%filial_svn_dir_log%%app_name%-%exec_name%.csv"
    set "app_plsqlbigsk_log=%plslave_dir_log%%app_name%-%exec_name%-%totaltrq_plsqlbigsk%.LOG"
    set "app_plsqlbigsk_svn_log=%filial_svn_dir_log%%app_name%-%exec_name%-%totaltrq_plsqlbigsk%.LOG"
    set "save_log=true"
    
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "Iniciando processo: %exec_name%"
    
exit /b 0


:initialize -- carrega variáveis da app
:$created 12/03/2014 :$author Pedro Elsner
:$updated  :$by
    
    :: Carrega arquivo de configuração 'app.ini'
    set "app_ini=%app_dir%app.ini"
    if exist %app_ini% (
        for /f "tokens=1,2* delims=^=" %%A in (%app_ini%) do (call "%file_functions%" SET_VAR "%%A" "%%B")
    )
    
    set "plsqlbigsk_svn_dir=%svn_dir%%plsqlbigsk_svn%\%app_name%"
    

exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 06/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    
    if %exec_name%null==null (
        call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "%log_exec_success%"
        exit /b 0
    )
    
    :: Cria arquivo de PID
    echo %exec_name% >> %app_pid%
    
    :: LOG
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%app_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "%log_exec_success%"
    
exit /b 0


:load_ini -- carregar ini
:$created 06/03/2014 :$author Pedro Elsner
:$updated  :$by 

   for /f "tokens=1,2* delims=^=" %%A in (%plsqlbigsk_svn_dir%\%exec_name%.ini) do (call "%file_functions%" SET_VAR "%%A" "%%B")
                
exit /b 0


:check_scheduler exec_name -- verifica agendamento da rotina
::                         -- %~1:exec_name  [in] - nome do processo
:$created 10/03/2014 :$author Pedro Elsner
:$updated  :$by
    
    
    :: Verifica variavies do arquivo
    if %exec_date%null==null ( set exec_name= )
    if %exec_time%null==null ( set exec_name= )
    
    if %exec_name%null==null (
        call "%file_functions%" SAVE_LOG "%app_display%" "%log_error%" "%~1 (erro no arquivo '.ini')"
        exit /b 1
    )
    
    :: Ajusta formato
    if "%exec_time:~1,1%"==":" ( set "exec_time=0%exec_time%" )
    
    :: Verifica forma
    if not "%exec_date:~2,1%"=="/" ( set exec_name= )
    if not "%exec_date:~5,1%"=="/" ( set exec_name= )
    if not "%exec_time:~2,1%"==":" ( set exec_name= )
    
    if %exec_name%null==null (
        call "%file_functions%" SAVE_LOG "%app_display%" "%log_error%" "%~1 (erro no arquivo '.ini')"
        exit /b 1
    )
    
    
    :: ###############
    
    
    if "%exec_date:~0,1%"=="0" ( set "exec_date_day=%exec_date:~1,1%" ) else ( set "exec_date_day=%exec_date:~0,2%" )
    if "%exec_date:~3,1%"=="0" ( set "exec_date_month=%exec_date:~4,1%" ) else ( set "exec_date_month=%exec_date:~3,2%" )
    set "exec_date_year=%exec_date:~-4%"
    set "exec_date_compare=%exec_date:~-4%%exec_date:~3,2%%exec_date:~0,2%"
    
    if "%exec_time:~0,1%"=="0" ( set "exec_time_hour=%exec_time:~1,1%" ) else ( set "exec_time_hour=%exec_time:~0,2%" )
    if "%exec_time:~3,1%"=="0" ( set "exec_time_minute=%exec_time:~4,1%" ) else ( set "exec_time_minute=%exec_time:~3,2%" )
    
    
    :: ###############
    
    
    :: Se data atual for maior que agendada
    :: executa!!!
    if %plslave_date_compare% gtr %exec_date_compare% ( exit /b 0 )
    
    :: Se data atual for menor que agendada
    if %plslave_date_compare% lss %exec_date_compare% ( set exec_name= )
    
    :: Verifica horario
    if %plslave_time_hour% lss %exec_time_hour% ( set exec_name= ) else (
        if %plslave_time_hour%==%exec_time_hour% (
            if %plslave_time_minute% lss %exec_time_minute% ( set exec_name= )
        )
    )
    
    
    if %exec_name%null==null (
        call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "%~1 (agendado: %exec_date% %exec_time%)"
        exit /b 1
    )
    
    
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


:exec_descompacta -- aplica atualização
:$created 10/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%app_display%" "%log_success%" "Executando %app_descompacta_display%" 
    call "%file_functions%" SAVE_LOG "%app_descompacta_display%" "%log_success%" "Iniciado" 
    
    set "plsqlbigsk_descompacta_dir=%plsqlbigsk_atualize_dir%\%app_name%"
    set "plsqlbigsk_descompacta_rar=%plsqlbigsk_svn_dir%\%exec_name%.rar"

    
    :: Verifica se pasta de backup existe
    if exist %plsqlbigsk_descompacta_dir%\nul (
        :: Apaga a pasta
        call "%file_functions%" SAVE_LOG "%app_descompacta_display%" "%log_success%" "Apagando diretorio '%plsqlbigsk_descompacta_dir%'" 
        call "%file_functions%" DELETE_DIR %plsqlbigsk_descompacta_dir% "/S /Q"
    )
    
    
    :: Descompactando arquivos
    call "%file_functions%" SAVE_LOG "%app_descompacta_display%" "%log_success%" "Descompactando '%plsqlbigsk_descompacta_rar%' em '%plsqlbigsk_atualize_dir%'" 
    %file_unrar% x %plsqlbigsk_descompacta_rar% %plsqlbigsk_atualize_dir%
    
    
    call "%file_functions%" SAVE_LOG "%app_descompacta_display%" "%log_success%" "%log_exec_success%" 

exit /b 0


:exec_update -- copia executavel
:$created 09/05/2014 :$author Pedro Elsner
:$updated  :$by 
    
    :: Se TOTAL.TRQ não existir, sai
    set "plsqlbigsk_update_dir=%plsqlbigsk_atualize_dir%\%app_name%"
    set "plsqlbigsk_update_file=%plsqlbigsk_update_dir%\plsqlbigsk.exe"
    if not exist %plsqlbigsk_update_file% ( exit /b 1 )
    
    
    call "%file_functions%" SAVE_LOG "%app_update_display%" "%log_success%" "Copiando '%plsqlbigsk_update_file%' para '%plsqlbigsk_dir%'" 
    call "%file_functions%" COPY_FILE "%plsqlbigsk_update_file%" "%plsqlbigsk_dir%\" & if ERRORLEVEL 1 (
       call "%file_functions%" SAVE_LOG "%app_update_display%" "%log_error%" "%log_exec_error%" 
       exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%app_update_display%" "%log_success%" "%log_exec_success%" 

exit /b 0

