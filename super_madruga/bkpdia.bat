@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:: Executa BKP
call:exec_bkp "%option_app%" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: GERA DADOS.RAR
if "%option_app%"=="completo" (

    call "%file_functions%" DELETE_FILE "%dir_bkp_local%dados.rar"
    
    :: Compacta 'dir_bkp_local'
    call:compacta_dados "%dir_bkp_local%" "%bkp_dia_dados_extensions%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
    
    :: Copia 'DADO.RAR' de 'dir_bkp_local' para 'dir_bkp' e verifica se arquivo foi copiado
    call "%file_functions%" COPY_FILES "%bkpdia_display%" "%dir_bkp_local%" "%dir_bkp%" "dados.rar" "/W:10"
    call "%file_functions%" CHECK_FILES_COPIED "%bkpdia_display%" "%dir_bkp_local%" "%dir_bkp%" "dados.rar" & if ERRORLEVEL 1 (call:end error & exit /b 1)
)


:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup option -- prepara ambiente
::              -- %~1:option [in] - parâmetro de inicialização
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_bkpdia="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%bkpdia_display%" "%pid_bkpdia%" "pid_code_bkpdia" & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_bkpdia%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%bkpdia_display%" "%pid_bkpdia%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%bkpdia_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%bkpdia_display%" "%log_success%" "%log_exec_success%"

exit /b 0


:: ###################


:exec_bkp option -- executa BKP
::               -- %~1:option [in] - parâmetro de inicialização
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by

    call "%file_functions%" SAVE_LOG "%bkpdia_display%" "%log_success%" "Executando %bkp_display% (%~1)"
    call "%file_bkp%" "%~1" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:compacta_dados extensions path extensions -- compacta arquivos em um RAR
::                                         -- %~1:path       [in] - caminho
::                                         -- %~2:extensions [in] - extensões
:$created 03/11/2011 $author Pedro Elsner
    
    setlocal
    set "temp_dir=%~1"
    %temp_dir:~0,2% & cd %temp_dir%
    set "temp_extensions=%~2"
    set "temp_extensions=%temp_extensions:[all]=*%"
    set "temp_extensions=%temp_extensions:[x]=?%"
    call "%file_functions%" SAVE_LOG "%bkpdia_display%" "%log_success%" "Compactando arquivos (%temp_extensions%) de '%~1'"
    
    :: Compactando os arquivos
    rar32 a -d1024 -ep -k -m5 -rr -s -y dados %temp_extensions% & echo . & endlocal
    if errorlevel 1 (
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%bkpdia_display%" "%log_success%" "Arquivo criado '%~1DADOS.RAR'"
    %drive_app% & cd %dir_app%

exit /b 0
