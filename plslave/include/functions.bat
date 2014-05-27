@echo off & call:%* & if ERRORLEVEL 1 ( exit /b 1) else ( exit /b 0 )


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


:FATAL_ERROR message -- mostra mensagem de erro
::                   -- %~1:message [in] - mensagem
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by    
    
    echo [%log_fatal_error%] %plslave_display%: %~1
    
exit /b 0


:LOAD_CONFIG option -- carrega configurações
::                  -- %~1:option  [in] - parâmetro do aplicativo
:$created 06/03/2014 :$author Pedro Elsner
:$updated  :$by
    
    
    :: Desativa gravação de log
    set "save_log=false"
    set "datetime_diff_seconds=0"
    set "update_datetime=false"
    
    
    :: #############
    
    
    :: Verifica se arquivo DATETIME existe
    if not exist %temp_datetime% (
        set "update_datetime=true"
    ) else (
    
        :: Verifica data da ultima atualização
        call:FIND_IN_FILE "%temp_datetime%" "Datetime server: %date:~-4%-%date:~3,2%-%date:~0,2%" & if ERRORLEVEL 1 (
            set "update_datetime=true"
            call "%file_functions%" COPY_FILE "%temp_datetime%" "%temp_datetime_bkp%"
        )
    )
    
    
    if %update_datetime%==true (
        
        :: Atualiza DATETIME
        echo n | %file_plink% -pw %linux_password% %linux_username%@%linux_server% date +"\"Datetime server: %%Y-%%m-%%d %%T\"" > %temp_datetime%
        
        :: Verfica arquivo
        call:FIND_IN_FILE "%temp_datetime%" "Datetime server:" & if ERRORLEVEL 1 (
            if not exist %temp_datetime_bkp% ( 
                call "%file_functions%" DELETE_FILE "%temp_datetime%"
                exit /b 1
            )
            call "%file_functions%" COPY_FILE "%temp_datetime_bkp%" "%temp_datetime%"
            call "%file_functions%" DELETE_FILE "%temp_datetime_bkp%"
        ) else (
            
            :: Adiciona DATETIME local
            setlocal ENABLEDELAYEDEXPANSION
                set "datetime_updated_date=%date:~-4%-%date:~3,2%-%date:~0,2%"
                if "%time:~0,1%"==" " (set "datetime_updated_time=0%time:~1,7%") else (set "datetime_updated_time=%time:~0,8%")
                call "%file_functions%" WAIT_SECONDS 2
                echo Datetime local: !datetime_updated_date! !datetime_updated_time! >> %temp_datetime%
            endlocal
        )
        
    )
    
    :: Apaga arquivo de BACKUP
    if exist %temp_datetime_bkp% ( call "%file_functions%" DELETE_FILE "%temp_datetime_bkp%" )
    
    :: Pega diferença em segundos com a Matriz
    call "%file_pydatetime%" diff %temp_datetime%
    set "datetime_diff_seconds=%errorlevel%"
    
    :: Aplica segundos na Data e Hora
    call "%file_pydatetime%" date %datetime_diff_seconds%
    set "plslave_date=%errorlevel:~-2%/%errorlevel:~4,2%/%errorlevel:~0,4%"
    call "%file_pydatetime%" time %datetime_diff_seconds%
    set "plslave_time=%errorlevel:~1,2%:%errorlevel:~3,2%:%errorlevel:~5,2%"
    
    :: Formata Data
    if "%plslave_date:~0,1%"=="0" ( set "plslave_date_day=%plslave_date:~1,1%" ) else ( set "plslave_date_day=%plslave_date:~0,2%" )
    if "%plslave_date:~3,1%"=="0" ( set "plslave_date_month=%plslave_date:~4,1%" ) else ( set "plslave_date_month=%plslave_date:~3,2%" )
    set "plslave_date_year=%plslave_date:~-4%"
    set "plslave_date_compare=%plslave_date:~-4%%plslave_date:~3,2%%plslave_date:~0,2%"
    
    :: Formata Hora
    if "%plslave_time:~0,1%"==" " (set "plslave_time=0%plslave_time:~1,7%") else (set "plslave_time=%plslave_time:~0,8%")
    if "%plslave_time:~0,1%"=="0" ( set "plslave_time_hour=%plslave_time:~1,1%" ) else ( set "plslave_time_hour=%plslave_time:~0,2%" )
    if "%plslave_time:~3,1%"=="0" ( set "plslave_time_minute=%plslave_time:~4,1%" ) else ( set "plslave_time_minute=%plslave_time:~3,2%" ) 
    
    :: Reset vars
    set app_name=
    set app_dir=
    set app_display=
    set app_ini=
    set app_initialize=
    set app_main=
    set app_pid=
    set app_svn_pid=
    set app_log=
    set app_svn_log=
    set app_plsqlbigsk_log=
    set app_plsqlbigsk_svn_log=
    set exec_name=
    set exec_date=
    set exec_time=
    
    
    :: ############
    
    
    if "%~1"=="" (
        call:FATAL_ERROR "%log_exec_sintaxe_error%"
        exit /b 1
    )
    
    set "app_name=%~1"
    set "app_dir=%plslave_dir_app%%app_name%\"
    call:CHECK_APP & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:CHECK_APP -- verifica arquivos da apliação
:$created 10/11/2011 :$author Pedro Elsner
:$updated  :$by
    
    :: main.bat
    set "app_main=%app_dir%main.bat"
    if not exist %app_main% (
        call:FATAL_ERROR "%log_exec_invalid_param%"
        exit /b 1
    )
    
exit /b 0


:LOAD_APP -- carrega configurações da aplicação
:$created 07/03/2014 :$author Pedro Elsner
:$updated  :$by
    
    :: initialize.bat
    set "app_initialize=%app_dir%initialize.bat"
    if exist %app_initialize% ( call %app_initialize% )
    
    :: PID file
    set "app_pid=%plslave_dir_pid%%app_name%.pid"
    set "app_svn_pid=%filial_svn_dir_pid%%app_name%.pid"
    
    :: Se PID existir no SVN, copiar para plslave
    if exist %app_svn_pid% (
        call:XCOPY_FILE "%app_svn_pid%" "%plslave_dir_pid%" "/S /Y"
        call:WAIT_SECONDS 2
    )

exit /b 0


:SAVE_LOG app status message -- adiciona ocorrência no arquivo de log
::                           -- %~1:app     [in] - nome do aplicativo
::                           -- %~2:status  [in] - sucesso ou erro
::                           -- %~3:message [in] - mensagem
:$created 30/10/2011 :$author Pedro Elsner
:$updated  :$by    
    
    setlocal
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")        
        echo %date:~-10% %temp_time% [%~2] %~1: %~3
    endlocal
    
    if %exec_name%null==null ( exit /b 0 )
    if "%save_log%"=="false" ( exit /b 0 )
    
    setlocal ENABLEDELAYEDEXPANSION
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")
        
        :: Data e Hora Matriz
        call "%file_pydatetime%" date %datetime_diff_seconds%
        set "temp_date_matriz=%errorlevel:~-2%/%errorlevel:~4,2%/%errorlevel:~0,4%"
        call "%file_pydatetime%" time %datetime_diff_seconds%
        set "temp_time_matriz=%errorlevel:~1,2%:%errorlevel:~3,2%:%errorlevel:~5,2%"
        
        echo %app_name%;%exec_name%;%temp_date_matriz% %temp_time_matriz%;%filial_display%;%filial_code%;%date:~-10% %temp_time%;%~1;%~2;%~3 >> %app_log%
    endlocal
    
exit /b 0


:MAKE_DIR display path extension -- cria diretorio
::                               -- %~1:display   [in] - caminho do diretório
::                               -- %~2:path      [in] - aplicativo
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


:COPY_FILE orig dest -- copia arquivo
::                   -- %~1:orig   [in] - arquivo de origem
::                   -- %~2:dest   [in] - destino
:$created 11/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    copy "%~1" "%~2" > nul & if ERRORLEVEL 1 ( exit /b 1)
    
exit /b 0


:XCOPY_FILE orig dest params -- copia arquivo
::                           -- %~1:orig   [in] - arquivo de origem
::                           -- %~2:dest   [in] - destino
::                           -- %~3:dest   [in] - parametros
:$created 11/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    xcopy "%~1" "%~2" %~3 > nul & if ERRORLEVEL 1 ( exit /b 1)
    
exit /b 0


:WAIT_SECONDS seconds -- aguarda alguns segundos
::                           -- %~1:seconds [in] - segundos para esperar
:$created 11/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    ping -n %~1 -w 500 0.0.0.1 > nul

exit /b 0 


:FIND_IN_FILE file content -- procura conteúdo em arquivo
::                         -- %~1:file    [in] - arquivo
::                         -- %~1:content [in] - conteudo
:$created 12/03/2014 :$author Pedro Elsner
:$updated  :$by 
    
    type %~1 | findstr /c:"%~2" > nul
    if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0