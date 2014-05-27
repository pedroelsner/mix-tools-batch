@echo off & call:%* & if ERRORLEVEL 1 ( exit /b 1) else ( exit /b 0 )


:LOAD_CONFIG option filial -- carrega configurações
::                                 -- %~1:option  [in] - parâmetro do aplicativo
::                                 -- %~2:filial  [in] - parâmetro do aplicativo
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by

    :: Verifica variável do sistema
    if "%dir_app_log%"=="" (
        call:FATAL_ERROR "Diretorio de LOG nao esta configurado"
        exit /b 1
    )
    if "%dir_app_pid%"=="" (
        call:FATAL_ERROR "Diretorio de PID nao esta configurado"
        exit /b 1
    )
    
    
    if "%~1"=="" (
        call:FATAL_ERROR "A sintaxe do comando esta incorreta"
        exit /b 1
    )
    if "%~2"=="" (
        call:FATAL_ERROR "A sintaxe do comando esta incorreta"
        exit /b 1
    )
    set "option_app=%~1"
    set "filial_app=%~2"
    call:CHECK_APP_OPTION & if ERRORLEVEL 1 ( exit /b 1 )
    
    
    :: Ajusta / Define variáveis
    set "file_log=%dir_app_log%%option_app%\%filial_app%-log.%file_log_extension%"
    set "file_temp=%dir_app_temp%%option_app%-%filial_app%.%file_tmp_extension%"
    set "pid_descompacta=%pid_descompacta%-%option_app%-%filial_app%.%file_pid_extension%"
    set "dir_source_files=%dir_source%%option_app%"
    set "dir_source_file_log=%dir_source%%option_app%-log.%file_log_extension%"
    set "dir_source_file_pts=%dir_source%%option_app%.%file_pts_extension%"
    
    
    :: Verifica se arquivos de origem estão prontos
    call:CHECK_DIR_SOURCE_READY & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Pega parâmetros da filial
    call:GET_FILIAL_PARAMS "%svn_display%" "%dir_source_file_log%" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Verifica se arquivos pertencem a filial
    if not "%filial_app%"=="%filial_svn%" (
        call:FATAL_ERROR "Arquivos do repositorio nao pertencem a filial '%filial_app%'"
        exit /b 1
    )
    
    
    :: Verifica arquivo de LOG antigo
    if exist %file_log% (
        call:CHECK_FILIAL_PROCESS "%filial_pid_process%" "%file_log%" & if ERRORLEVEL 1 (
            call:CHECK_EXEC_SUCCESS "%descompacta_display%" "%file_log%" & if not ERRORLEVEL 1 (
                call:FATAL_ERROR "Processo '%filial_pid_process%' ja foi descompactado"
                exit /b 1
            )
        )
    )
        
    
    :: Verifica limiti de processo (CLUSTER)
    call:CHECK_LIMIT_PROCCESS & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:CHECK_APP_OPTION -- verifica configuração se define variáveis
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by
    
    :: Verifica se arquivo de configuração existe
    set "config_option=%dir_app_config%%option_app%.ini"
    if not exist %config_option% (
        call:FATAL_ERROR "O parametro informado esta incorreto"
        exit /b 1
    )
    
    :: Verifica se arquivo de configuração da filial existe
    if not exist %dir_app_filiais%%filial_app%.ini (
        call:FATAL_ERROR "Nao foi encontrado o arquivo de configuracao da filial: '%filial_app%.ini'"
        exit /b 1
    )
    
    :: Carrega configurações da filial (SVN)
    for /f "tokens=1,2* delims=^=" %%A in (%dir_app_filiais%%filial_app%.ini) do (call:SET_VAR "%%A" "%%B")
    set "svn_connection=svn://%svn_server%/var/svn/%filial_app%"
    set "svn_auth=--username %svn_username% --password %svn_password%"
    
    
    :: ###################
    
    
    :: Zera variáveis / Carrega as configurações
    set "dir_source="
    set "dir_destination="
    for /f "tokens=1,2* delims=^=" %%A in (%dir_app_config%%option_app%.ini) do (call:SET_VAR "%%A" "%%B")
    
    if "%dir_source%"=="" (
        call:FATAL_ERROR "A configuracao do arquivo INI esta incorreta"
        exit /b 1
    )
    
    if "%dir_destination%"=="" (
        call:FATAL_ERROR "A configuracao do arquivo INI esta incorreta"
        exit /b 1
    )
    
    :: Verifica se diretórios existem
    if not exist %dir_source%nul (
        call:FATAL_ERROR "Diretorio '%dir_source%' nao existe"
        exit /b 1
    )
    
    if not exist %dir_destination%nul (
        mkdir %dir_destination% > nul & if ERRORLEVEL 1 ( 
            call:FATAL_ERROR "Diretorio '%dir_destination%' nao existe"
            call:FATAL_ERROR "Nao foi possivel criar o diretorio '%dir_destination%'"
            exit /b 1
        )
    )
    
    
    :: ###################
    
    
    :: Atualiza diretórios com nome da filial
    set "dir_source=%dir_source%%filial_app%\"
    if not "%filial_app%"=="lapa" ( set "dir_destination=%dir_destination%%filial_app%\" )
    if "%filial_app%"=="lapa" ( set "dir_destination=%dir_destination%matriz\" )
    
    
    :: Verifica se diretório existe
    if not exist %dir_destination%nul (
        mkdir %dir_destination% > nul & if ERRORLEVEL 1 ( 
            call:FATAL_ERROR "Diretorio '%dir_destination%' nao existe"
            call:FATAL_ERROR "Nao foi possivel criar o diretorio '%dir_destination%'"
            exit /b 1
        )
    )
    
    
    :: ###################
    
    
    :: Verifica se diretório de LOG existe
    if not exist %dir_app_log%%option_app%\nul (
        mkdir %dir_app_log%%option_app% > nul & if ERRORLEVEL 1 ( 
            call:FATAL_ERROR "Diretorio '%dir_app_log%%option_app%' nao existe"
            call:FATAL_ERROR "Nao foi possivel criar o diretorio '%dir_app_log%%option_app%'"
            exit /b 1
        )
    )
    
exit /b 0


:CHECK_LIMIT_PROCCESS -- verifica número limite de processos
:$created 16/12/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Verifica os processos em execução (LOCAL)
    set /a "cluster_count_pid=0"
    for %%A in (%dir_app_pid%%computername%*) do (call:COUNT "cluster_count_pid")
    
    if "%cluster_count_pid%" GEQ "%cluster_limit_proccess%" (
        call:FATAL_ERROR "Limite de processos simultaneos foi atingido"
        exit /b 1
    )
    
    
    :: Verifica processo em execução (CLUSTER)
    set /a "cluster_count_pid=0"
    for %%A in (%dir_app_pid%*%filial_app%.*) do (call:COUNT "cluster_count_pid")
    
    if "%cluster_count_pid%" GEQ "1" (
        call:FATAL_ERROR "Processo da filial '%filial_app%' esta sendo executado por outro computador"
        exit /b 1
    )

exit /b 0


:CHECK_DIR_SOURCE_READY -- verifica configuração se define variáveis
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by
    
	
	:: Verifica se o diretório existe
	if not exist %dir_source%nul (
        svn checkout %svn_auth% %svn_connection% %dir_source% & if ERRORLEVEL 1 (
            call:FATAL_ERROR "Não foi possivel realizar o checkout"
            exit /b 1
        )
    )
	
    :: Atualiza repositorio (SVN)
    svn upgrade %svn_auth% %dir_source%
    svn cleanup %svn_auth% %dir_source%
    svn update %svn_auth% --accept theirs-full %dir_source%
    if ERRORLEVEL 1 ( 
		:: Apaga repositorio e faz um novo checkout
		call:DELETE_DIR "%dir_source%" "/S /Q"
		svn checkout %svn_auth% %svn_connection% %dir_source% & if ERRORLEVEL 1 (
			call:FATAL_ERROR "SVN falhou ao atualizar repositorio '%dir_source%'"
            call:FATAL_ERROR "Não foi possivel realizar o checkout"
            exit /b 1
        )
    )
    
    :: Verifica se o arquivo com lista de partes existe
    if not exist %dir_source_file_pts% (
        call:FATAL_ERROR "Arquivo '%option_app%.pts' nao foi encontrado no repositorio"
        exit /b 1
    )
    
    :: Verifica se todas as partes REALMENTE chegaram
    for /f "tokens=1*" %%A in (%dir_source_file_pts% ) do (
        if not "%%A"=="" (
            if not exist %dir_source%%%A (
                call:FATAL_ERROR "Arquivo '%%A' nao foi encontrado no repositorio"
                exit /b 1
            )
        )
    )
    
    :: Verifica se o arquivo de log existe
    if not exist %dir_source_file_log% (
        call:FATAL_ERROR "Arquivo '%option_app%-log.%file_log_extension%' nao foi encontrado no repositorio"
        exit /b 1
    )
    
    :: Verifica se SVN finalizou com sucesso
    call:CHECK_EXEC_SUCCESS "%svn_display%" "%dir_source_file_log%" & if ERRORLEVEL 1 (
        call:FATAL_ERROR "Processo '%svn_display%' ainda nao foi finalizado na filial"
        exit /b 1
    )
    
exit /b 0


:CHECK_FILIAL_PROCESS process log -- verifica se processo esta no log
::                                -- %~1:process [in] - código do processo
::                                -- %~2:log     [in] - arquivo de log
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    type %~2 | findstr "%~1" > nul
    if not ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:CHECK_EXEC_SUCCESS display log -- verifica execução com sucesso de um aplicativo
::                              -- %~1:display [in] - informe a variável 'display' do aplicativo
::                              -- %~2:log     [in] - arquivo de log
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    type %~2 | findstr "%~1;%log_success%;%log_exec_success%" > nul
    if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:CHECK_EXEC_ERROR display log -- verifica execução falhou de um aplicativo
::                            -- %~1:display [in] - informe a variável 'display' do aplicativo
::                            -- %~2:log     [in] - arquivo de log
:$created 23/12/2011 :$author Pedro Elsner
:$updated  :$by 
    
    type %~2 | findstr "%~1;%log_error%;%log_exec_error%" > nul
    if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:SET_VAR var value -- define variável
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


:GET_FILIAL_PARAMS display log -- pega o código da filial através de um aplicativo
::                             -- %~1:display [in] - informe a variável 'display' do aplicativo
::                             -- %~2:log     [in] - arquivo de log
:$created 25/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    type %~2 | findstr "%~1;%log_success%;%log_exec_success%" > %file_temp%
    if ERRORLEVEL 1 ( exit /b 1 )
    
    for /f "tokens=1,2,3* delims=;" %%A in (%file_temp%) do (
        set "filial_pid_process=%%A"
        set "filial_code=%%B"
        set "filial_svn=%%C"
    )

exit /b 0


:FATAL_ERROR message -- mostra mensagem de erro
::                   -- %~1:message [in] - mensagem
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by    
    
    echo [%log_fatal_error%] %app_display%: %~1
    
exit /b 0


:MAKE_PID_PROCESS -- cria PID em variável para o processo
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by
    
    :: Se PID existir, sai da rotina
    if not "%pid_process%"=="" ( exit /b 0 )
    
    setlocal
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")
        set "temp_date=%date:~-10%"
        set "temp_pid=QD%temp_time:~6,2%%temp_date:~4,2%%temp_date:~6,4%%temp_time:~0,2%%temp_date:~0,2%%temp_time:~3,2%"
    
    endlocal & set "pid_process=%temp_pid%" & call:SAVE_LOG "%app_display%" "%log_success%" "Processamento: %temp_pid%"
    
exit /b 0


:MAKE_PID display file var -- cria arquivo de processo (p/ controle de execução)
::                         -- %~1:display [in] - nome do aplicativo
::                         -- %~2:file    [in] - nome do arquivo (*.pid)
::                         -- %~3:var     [in] - variável para armazenar PID
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by
    
    :: Se PID existir, sai da rotina
    if exist %~2 (
        call:FATAL_ERROR "Nao foi possivel iniciar"
        for /f "tokens=*" %%Z in (%~2) do (for /f "tokens=1* delims=;" %%A in ('echo %%Z') do (call:FATAL_ERROR "Outro processo esta executando a rotina (PID: %%A)"))
        exit /b 1
    )
    
    :: Se for o DESCOMPACTA, apaga arquivo de log (e temporário)
    if "%~1"=="%descompacta_display%" (
        del %file_log% > nul
        set "pid_process="
    )
    
    :: Cria PID para todo o processo
    call:MAKE_PID_PROCESS
    
    setlocal
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")
        set "temp_date=%date:~-10%"
        set "temp_pid=%SESSIONNAME:~0,1%%temp_time:~6,2%%temp_date:~3,2%%STATION%%temp_date:~6,4%%temp_time:~0,2%%temp_date:~0,2%%temp_time:~3,2%"
        
        echo %temp_pid%;%date:~-10% %temp_time%;%computername% > %~2
        call:SAVE_LOG "%~1" "%log_success%" "Iniciado (PID: %temp_pid%)"
    endlocal & set "%~3=%temp_pid%"
    
exit /b 0


:KILL_PID display file error -- apaga arquivo de processo (p/ controle de execução)
::                           -- %~1:display [in] - nome do aplicativo
::                           -- %~2:file    [in] - nome do arquivo (*.pid)
::                           -- %~3:error   [in] - se houve erro ao criar PID
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by
    
    :: Se houve erro ao criar PID, sai da rotina
    if "%~3"=="0" (exit /b 0)
    
    :: Verifica se este computador criou o processo
    ::  -> Apaga o arquivo
    type %~2 | findstr %computername% > nul
    if ERRORLEVEL 1 ( echo.>nul ) else ( del %~2 > nul )
    
exit /b 0


:SAVE_LOG app status message -- adiciona ocorrência no arquivo de log
::                           -- %~1:app     [in] - nome do aplicativo
::                           -- %~2:status  [in] - sucesso ou erro
::                           -- %~3:message [in] - mensagem
:$created 30/10/2011 :$author Pedro Elsner
:$updated  :$by    
    
    setlocal
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")
        
        echo %pid_process%;%filial_code%;%filial_app%;%date:~-10% %temp_time%;%computername%;%~1;%~2;%~3 >> %file_log%
        echo %date:~-10% %temp_time% [%~2] %~1: %~3
    endlocal
    
exit /b 0


:MAKE_DIR_OR_DELETE_OLD_FILES display path -- apaga todos os arquivos do diretorio
::                                         -- %~1:display [in] - caminho do diretório
::                                         -- %~2:path    [in] - aplicativo
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Se não existir, cria o diretório
    if not exist %~2\nul (
        call:SAVE_LOG "%~1" "%log_success%" "Criando diretorio '%~2'"
        mkdir %~2 > nul & if ERRORLEVEL 1 ( exit /b 1 )
        exit /b 0
    )
        
    call:SAVE_LOG "%~1" "%log_success%" "Apagando (*.*) de '%~2'"
    del %~2\*.* /F /Q /A-H > nul
    
exit /b 0


:DELETE_DIR path -- apaga diretório
::               -- %~1:path   [in] - caminho do diretório
::               -- %~2:option [in] - parametros
:$created 05/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    rmdir %~2 %~1 > nul
    
exit /b 0


:COPY_FILES display source destination extensions options -- copia os arquivos
::                                                        -- %~1:display     [in] - aplicativo
::                                                        -- %~2:source      [in] - diretório de origem
::                                                        -- %~3:destination [in] - diretório de destino
::                                                        -- %~4:extensions  [in] - extensões para copiar
::                                                        -- %~5:options     [in] - opções
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    setlocal
    set "temp_extensions=%~4"
    set "temp_extensions=%temp_extensions:[all]=*%"
    set "temp_extensions=%temp_extensions:[x]=?%"
    
    call:SAVE_LOG "%~1" "%log_success%" "Copiando (%temp_extensions%) de '%~2' para '%~3'"

    :: Copia todos os arquivos com a extensão específicada
    ::  -> /W:10  - Tempo de espera entre tentativas (em segundos)
    ::  -> /PURGE - Apaga todos os arquivos do diretório de destino (aparentemente não funciona...)
    robocopy %~5 %~2 %~3 %temp_extensions% & echo . & endlocal & if ERRORLEVEL 8 ( exit /b 1 )
    
exit /b 0


:NOLOG_COPY_FILES display source destination extensions options -- copia os arquivos
::                                                              -- %~1:display     [in] - aplicativo
::                                                              -- %~2:source      [in] - diretório de origem
::                                                              -- %~3:destination [in] - diretório de destino
::                                                              -- %~4:extensions  [in] - extensões para copiar
::                                                              -- %~5:options     [in] - opções
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    setlocal
    set "temp_extensions=%~4"
    set "temp_extensions=%temp_extensions:[all]=*%"
    set "temp_extensions=%temp_extensions:[x]=?%"

    :: Copia todos os arquivos com a extensão específicada
    ::  -> /W:10  - Tempo de espera entre tentativas (em segundos)
    ::  -> /PURGE - Apaga todos os arquivos do diretório de destino (aparentemente não funciona...)
    robocopy %~5 %~2 %~3 %temp_extensions% & echo . & endlocal & if ERRORLEVEL 8 ( exit /b 1 )
    
exit /b 0


:CHECK_FILES_COPIED requiris_files source destination extensions -- verifica arquivos copiados
::                                                               -- %~1:display        [in] - aplicativo
::                                                               -- %~2:source         [in] - diretório de origem
::                                                               -- %~3:destination    [in] - diretório de destino
::                                                               -- %~4:extensions     [in] - extensões dos arquivos
:$created 03/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Reseta variáveis
    set /a "files_copied_errors=0"
    
    :: Monta a variavel 'files_extensions'
    call:RESET_FILES_EXTENSIONS
    for %%A in (%~4) do call:FILES_EXTENSIONS "%~2" "%%A"    
    
    :: Verifica se todos os arquivos foram copiados
    ::  -> Lista arquivos no diretorio de origem e compara com diretorio de destino
    for /f "tokens=*" %%Z in ('dir %files_extensions% /a-d /b') do (
        if not exist %~3%%Z (
            set /a "files_copied_errors+=1"
            call:SAVE_LOG "%~1" "%log_error%" "Erro ao copiar: '%~2%%Z'"
        )
    )
    
    :: Se algum arquivo não foi copiado, aborta processo
    if %files_copied_errors% GEQ 1 (
        call:SAVE_LOG "%~1" "%log_error%" "Total de erro(s): %files_copied_errors%"
        exit /b 1
    )
    
    
    call:SAVE_LOG "%~1" "%log_success%" "Arquivo(s) copiado(s)"
    
exit /b 0


:RESET_FILES_EXTENSIONS -- apaga variável 'files_extensions'
:$created 03/11/2011 $author Pedro Elsner
:$updated  $by 

    set "files_extensions="
    
exit /b 0


:FILES_EXTENSIONS source extensions -- monta variável 'files_extensions'
::                                  -- %~1:source     [in] - diretório
::                                  -- %~2:extensions [in] - extensões
:$created 03/11/2011 :$author Pedro Elsner
:$updated  $by 
    
    setlocal
    set "temp_extensions=%~2"
    set "temp_extensions=%temp_extensions:[all]=*%"
    set "temp_extensions=%temp_extensions:[x]=?%"
    (endlocal & set files_extensions=%files_extensions% "%~1\%temp_extensions%")

exit /b 0


:MOVE_CURSOR_TO path -- move cursor do prompt para o diretorio especificado
::                   -- %~1:path [in] - caminho
:$created 12/11/2011 :$author Pedro Elsner
:$updated  :$by 

    setlocal
    set "temp_dir=%~1"
    %temp_dir:~0,2% & cd %temp_dir%
    endlocal
    
exit /b 0


:COUNT var -- incremente variável
::         -- %~1:var [in] - variável
:$created 07/11/2011 :$author Pedro Elsner
:$updated  $by 
    
    if not defined %~1 ( set /a "%~1=0" )
    set /a "%~1+=1"

exit /b 0
