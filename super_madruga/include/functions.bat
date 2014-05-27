@echo off & call:%* & if ERRORLEVEL 1 ( exit /b 1) else ( exit /b 0 )


:LOAD_CONFIG option -- carrega configurações
::                  -- %~1:option  [in] - parâmetro do aplicativo
:$created 10/11/2011 :$author Pedro Elsner
:$updated  :$by

    if "%~1"=="" (
        call:FATAL_ERROR "%log_exec_sintaxe_error%"
        exit /b 1
    )
    
    set "option_app=%~1"
    call:CHECK_APP_OPTION & if ERRORLEVEL 1 ( exit /b 1 )
    
    
    :: Ajusta / Define variáveis
    set "dir_bkp=%dir_bkp%%filial_svn%\%option_app%\"
    set "dir_compacta=%dir_bkp%svn\"
    set "dir_bkp_local=%dir_bkp_local%%filial_svn%\%option_app%\"
    set "dir_compacta_local=%dir_bkp_local%svn\"
    set "file_log=%dir_app_log%%option_app%-log.%file_log_extension%"
    set "file_log_temp=%dir_app_temp%%option_app%-log.tmp"
    
    :: PIDs
    set "pid_madruga=%dir_app_pid%%option_app%-madruga.pid"
    set "pid_bkp=%dir_app_pid%%option_app%-bkp.pid"
    set "pid_bkpdia=%dir_app_pid%%option_app%-bkpdia.pid"
    set "pid_compacta=%dir_app_pid%%option_app%-compacta.pid"
    set "pid_atupreco=%dir_app_pid%%option_app%-atupreco.pid"
    set "pid_svn=%dir_app_pid%%option_app%-svn_atualiza.pid"

exit /b 0


:CHECK_APP_OPTION -- verifica configuração se define variáveis
:$created 10/11/2011 :$author Pedro Elsner
:$updated  :$by
    
    :: COMPACTA
    set "list_compacta=%dir_app_config%%option_app%\compacta.lst"
    if not exist %list_compacta% (
        call:FATAL_ERROR "%log_exec_invalid_param%"
        exit /b 1
    )
    
    :: BKP DADOS
    set "list_bkp_dados=%dir_app_config%%option_app%\bkp_dados.lst"
    if not exist %list_bkp_dados% (
        call:FATAL_ERROR "%log_exec_invalid_param%"
        exit /b 1
    )
    setlocal ENABLEDELAYEDEXPANSION
    for /f "tokens=*" %%A in (%list_bkp_dados%) do (set "temp_bkp_extensions_dados=%%A !temp_bkp_extensions_dados!")
    endlocal & set "bkp_extensions_dados=%temp_bkp_extensions_dados%"
    
    
    :: BKP FONTES
    set "list_bkp_fontes=%dir_app_config%%option_app%\bkp_fontes.lst"
    if not exist %list_bkp_fontes% (
        set "list_bkp_fontes="
        exit /b 0
    )
    setlocal ENABLEDELAYEDEXPANSION
    for /f "tokens=*" %%A in (%list_bkp_fontes%) do (set "temp_bkp_extensions_fontes=%%A !temp_bkp_extensions_fontes!")
    endlocal & set "bkp_extensions_fontes=%temp_bkp_extensions_fontes%"
    
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
        set "temp_pid=SM%temp_time:~6,2%%temp_date:~3,2%%temp_date:~6,4%%temp_time:~0,2%%temp_date:~0,2%%temp_time:~3,2%"
    
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
    
    :: Se for o MADRUGA, apaga arquivo de log (e temporário)
    if "%~1"=="%madruga_display%" ( 
		
		:: Verficica execução anterior do madruga
		call "%file_functions%" CHECK_EXEC_TODAY "%~1" & if ERRORLEVEL 1 (
            if "%option_app%"=="completo" (
                call:FATAL_ERROR "Nao foi possivel iniciar"
                call:FATAL_ERROR "Processo ja foi executado hoje: %date:~-10%"
                exit /b 1
            )
		)
		
        call:DELETE_FILE "%file_log%"
        call:DELETE_FILE "%file_log_temp%"
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
        
        echo %pid_process%;%filial_code%;%filial_svn%;%date:~-10% %temp_time%;%computername%;%~1;%~2;%~3 >> %file_log%
        echo %date:~-10% %temp_time% [%~2] %~1: %~3
    endlocal
    
exit /b 0


:SAVE_ERROS_PRO display path -- copia 'erros.pro' para backup
::                                                   -- %~1:display   [in] - caminho do diretório
::                                                   -- %~2:path      [in] - aplicativo
:$created 10/05/2012 :$author Pedro Elsner
:$updated  :$by    
    
    setlocal
        set "temp_date=%date:~-10%"
        set "temp_date_erro=%temp_date:~6,4%%temp_date:~3,2%%temp_date:~0,2%"
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")
        set "temp_time_erro=%temp_time:~0,2%%temp_time:~3,2%%temp_time:~6,2%"
        
        set "temp_filename_erros_pro=%temp_date_erro%%temp_time_erro%-%filename_erros_pro%"
        
        copy %~2%filename_erros_pro% %dir_app_erro%%temp_filename_erros_pro% > nul
        call:SAVE_LOG "%~1" "%log_success%" "Copiando (%filename_erros_pro%) para '%dir_app_erro%%temp_filename_erros_pro%'"
        
    endlocal
    
exit /b 0


:MAKE_DIR_OR_DELETE_OLD_FILES display path extension -- apaga todos os arquivos do diretorio
::                                                   -- %~1:display   [in] - caminho do diretório
::                                                   -- %~2:path      [in] - aplicativo
::                                                   -- %~3:extension [in] - extenções
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Se não existir, cria o diretório
    if not exist %~2\nul (
        call:SAVE_LOG "%~1" "%log_success%" "Criando diretorio '%~2'"
        mkdir %~2 > nul & if ERRORLEVEL 1 ( exit /b 1 )
        exit /b 0
    )
    
    setlocal
        set "temp_extensions=%~3"
        set "temp_extensions=%temp_extensions:[all]=*%"
        set "temp_extensions=%temp_extensions:[x]=?%"
        
        call:SAVE_LOG "%~1" "%log_success%" "Apagando (%temp_extensions%) de '%~2'"
        del %~2\%temp_extensions% /F /Q /A-H > nul
    endlocal
    
    
exit /b 0


:MAKE_DIR display path extension -- cria diretorio
::                                                   -- %~1:display   [in] - caminho do diretório
::                                                   -- %~2:path      [in] - aplicativo
:$created 11/04/2012 :$author Pedro Elsner
:$updated  :$by 
    
    :: Se não existir, cria o diretório
    if not exist %~2\nul (
        call:SAVE_LOG "%~1" "%log_success%" "Criando diretorio '%~2'"
        mkdir %~2 > nul & if ERRORLEVEL 1 ( exit /b 1 )
        exit /b 0
    )
    
exit /b 0


:DELETE_DIR path option -- apaga diretório
::                      -- %~1:path   [in] - caminho do diretório
::                      -- %~2:option [in] - parametros
:$created 05/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    rmdir %~2 %~1 > nul
    
exit /b 0


:DELETE_FILE file -- apaga arquivo
::                -- %~1:path   [in] - caminho do diretório
:$created 12/04/2012 :$author Pedro Elsner
:$updated  :$by 
    
    del %~1 > nul
    
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


:NOLOG_COPY_FILES source destination extensions options -- copia os arquivos
::                                                      -- %~1:display     [in] - aplicativo
::                                                      -- %~2:source      [in] - diretório de origem
::                                                      -- %~3:destination [in] - diretório de destino
::                                                      -- %~4:extensions  [in] - extensões para copiar
::                                                      -- %~5:options     [in] - opções
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


:COUNT var -- incremente variável
::         -- %~1:var [in] - variável
:$created 07/11/2011 :$author Pedro Elsner
:$updated  $by 
    
    if not defined %~1 ( set /a "%~1=0" )
    set /a "%~1+=1"

exit /b 0


:KILL_TASK app -- mata um processo
::             -- %~1:app [in] - nome do aplicativo
:$created 09/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Encerrando processo '%~1'"
    
    :: Encerra processo
    taskkill /F /IM %~1 & if ERRORLEVEL 1 ( 
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Erro ao encerrar '%~1'"
        exit /b 1
    )

exit /b 0


:KILL_USER path option -- tira todos os usuários do sistema
::                     -- %~1:path   [in] - diretorio
::                     -- %~2:option [in] - parâmetro
:$created 21/12/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Removendo usuarios do sistema (%~2)"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_killuser% %~2
    
    %drive_app% & cd %dir_app%

exit /b 0


:IS_COMPUTER text -- verifica se o nome do compudaor termina com o parâmetro informado
::                -- %~1:text [in] - texto
:$created 08/11/2011 :$author Pedro Elsner
:$updated  :$by 

    echo %computername% | findstr /I "\<*%~1\>" > nul
    if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:CHECK_EXEC_SUCCESS display -- verifica execução com sucesso de um aplicativo
::                                               -- %~1:display [in] - informe a variável 'display' do aplicativo
:$created 10/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    type %file_log% | findstr "%~1;%log_success%;%log_exec_success%" > nul
    if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:CHECK_EXEC_ERROR display -- verifica execução falhou de um aplicativo
::                                          -- %~1:display [in] - informe a variável 'display' do aplicativo
:$created 23/12/2011 :$author Pedro Elsner
:$updated  :$by 
    
    type %file_log% | findstr "%~1;%log_error%;%log_exec_error%" > nul
    if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:CHECK_EXEC_TODAY display -- verifica execução de um aplicativo na data corrente
::                        -- %~1:display [in] - informe a variável 'display' do aplicativo
:$created 13/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    type %file_log% | findstr "%~1;%log_success%;%log_exec_success%" | findstr "%date:~-10%" > nul
    if ERRORLEVEL 1 ( 
		type %file_log% | findstr "%~1;%log_error%;%log_exec_error%" | findstr "%date:~-10%" > nul
		if ERRORLEVEL 1 ( exit /b 0 )
	)
	
exit /b 1


:WAIT_SECONDS seconds -- aguarda os segundos específicados
::                    -- %~1:seconds [in] - segundos
:$created 09/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
	ping -n %~1 -w 500 0.0.0.1 > nul

exit /b 0


:SEND_MAIL_ERROR option -- envia mensagem de erro com anexo (*-log.cvs)
::                      -- %~1:option [in] - parâmetro de inicialização
:$created 08/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Cria arquivo de log temporário
    type %file_log% | findstr "%log_error%" > %file_log_temp%
    
    :: Cria mensagem para o e-mail
    echo %app_display% > %file_blat_temp%
    echo -------- >> %file_blat_temp%
    echo Filial: %filial_display% >> %file_blat_temp%
    echo Processo: %~1 - FALHOU >> %file_blat_temp%
    echo -------- >> %file_blat_temp%
    echo Resumo dos erros encontrados: >> %file_blat_temp%
        setlocal ENABLEDELAYEDEXPANSION
            for /f "tokens=*" %%Z in (%file_log_temp%) do (for /f "tokens=1,2,3,4,5,6* delims=;" %%A in ('echo %%Z') do (echo %%B [%%E] %%D: %%F >> %file_blat_temp%))
        endlocal
    echo -------- >> %file_blat_temp%
    echo Segue anexo log completo. >> %file_blat_temp%
    
    :: Configura BLAT e envia
    blat -install %blat_smtp% %blat_sender% > nul
    blat %file_blat_temp% -t %blat_receive% -s "%date:~-10% | Filial: %filial_display% | Processo: %~1 - FALHOU" -attach %file_log% > nul

exit /b 0


:CHECK_SUCCESS_FULL -- verifica se houve 100% sucesso
::                      -- %~1:option [in] - parâmetro de inicialização
:$created 09/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Verifica se houve algum erro
    ::  -> Se não, sai da rotina
    type %file_log% | findstr "%log_error%" > nul
    if ERRORLEVEL 1 ( exit /b 0 )
    
    
    :: Cria arquivo de log temporário
    type %file_log% | findstr "%log_error%" > %file_log_temp%
    
    :: Processo concluído com erro(s)
    ::  -> Envia e-mail
    :: Cria mensagem para o e-mail
    echo %app_display% > %file_blat_temp%
    echo -------- >> %file_blat_temp%
    echo Filial: %filial_display% >> %file_blat_temp%
    echo Processo: %~1 - Concluido com erro(s) >> %file_blat_temp%
    echo -------- >> %file_blat_temp%
    echo Resumo do(s) erro(s) encontrado(s): >> %file_blat_temp%
        setlocal ENABLEDELAYEDEXPANSION
            for /f "tokens=*" %%Z in (%file_log_temp%) do (for /f "tokens=1,2,3,4,5,6* delims=;" %%A in ('echo %%Z') do (echo %%B [%%E] %%D: %%F >> %file_blat_temp%))
        endlocal
    echo -------- >> %file_blat_temp%
    echo Segue anexo log completo. >> %file_blat_temp%
    
    :: Configura BLAT e envia
    blat -install %blat_smtp% %blat_sender% > nul
    blat %file_blat_temp% -t %blat_receive% -s "%date:~-10% | Filial: %filial_display% | Processo: %~1 - Concluido com erro(s)" -attach %file_log% > nul

exit /b 0
