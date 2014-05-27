@echo off & call:%* & if ERRORLEVEL 1 ( exit /b 1) else ( exit /b 0 )


:LOAD_CONFIG repository -- carrega configurações
::                      -- %~2:repository  [in] - repositório para atualização
:$created 13/03/2014 :$author Pedro Elsner
:$updated  :$by


    if "%~1"=="" (
        call:FATAL_ERROR "A sintaxe do comando esta incorreta"
        exit /b 1
    )
    
    set "repository_name=%~1"
    call:CHECK_REPOSITORY_OPTION & if ERRORLEVEL 1 ( exit /b 1 )
    
    
exit /b 0


:CHECK_REPOSITORY_OPTION -- verifica configuração se define variáveis
:$created 13/03/2014 :$author Pedro Elsner
:$updated  :$by
    
        
    :: Verifica se arquivo de configuração
    if not exist %dir_app_repositories%%repository_name%.ini (
        call:FATAL_ERROR "Nao foi encontrado o arquivo de configuracao do repositorio: '%repository_name%.ini'"
        exit /b 1
    )
    
    :: Carrega configurações da filial (SVN)
    for /f "tokens=1,2* delims=^=" %%A in (%dir_app_repositories%%repository_name%.ini) do (call:SET_VAR "%%A" "%%B")
    set "svn_connection=svn://%svn_server%/var/svn/%repository_name%"
    set "svn_auth=--username %svn_username% --password %svn_password%"
    
    
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



:FATAL_ERROR message -- mostra mensagem de erro
::                   -- %~1:message [in] - mensagem
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by    
    
    echo [%log_fatal_error%] %app_display%: %~1
    
exit /b 0


:LOG app status message -- exibe log na tela
::                      -- %~1:app     [in] - nome do aplicativo
::                      -- %~2:status  [in] - sucesso ou erro
::                      -- %~3:message [in] - mensagem
:$created 13/03/2014 :$author Pedro Elsner
:$updated  :$by    
    
    setlocal
        if "%time:~0,1%"==" " (set "temp_time=0%time:~1,7%") else (set "temp_time=%time:~0,8%")
        echo %date:~-10% %temp_time% [%~2] %~1: %~3
    endlocal
    
exit /b 0
