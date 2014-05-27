@echo off 
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:: Se não informado, executa BKP LOCAL e REDE
if "%~2"=="" (
    
    call:bkp "%dir_bkp_local%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
    call:bkp "%dir_bkp%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
    
    :: Apaga alguns arquivos da pasta 'dados'
    if "%option_app%"=="completo" (call:delete_some_files "%dir_dados%")
    
) else (
    if "%~2"=="%bkp_option_local%" (call:bkp "%dir_bkp_local%" & if ERRORLEVEL 1 (call:end error & exit /b 1))
    if "%~2"=="%bkp_option_rede%" (call:bkp "%dir_bkp%" & if ERRORLEVEL 1 (call:end error & exit /b 1))
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
    set "pid_code_bkp="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%bkp_display%" "%pid_bkp%" "pid_code_bkp" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:end error -- encerra processamento
::         -- %~1:error [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_bkp%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%bkp_display%" "%pid_bkp%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%bkp_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%bkp_display%" "%log_success%" "%log_exec_success%"

exit /b 0


:: ###################


:bkp destination -- realiza o backup no diretório especificado
::               -- %~1:destination [in] - diretório destino
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 

    :: Cria o diretório de destino
    call "%file_functions%" MAKE_DIR "%bkp_display%" "%~1" & if ERRORLEVEL 1 ( exit /b 1 )

    :: Copia os arquivos de 'dir_dados' para diretório destino e verifica se arquivos foram copiados
    call "%file_functions%" COPY_FILES "%bkp_display%" "%dir_dados%" "%~1" "%bkp_extensions_dados%" "/W:10"
    call "%file_functions%" CHECK_FILES_COPIED "%bkp_display%" "%dir_dados%" "%~1" "%bkp_extensions_dados%" & if ERRORLEVEL 1 ( exit /b 1 )

    :: Copia os arquivos da pasta 'fontes' para diretório destino e verifica se arquivos foram copiados
    if not "%list_bkp_fontes%"=="" (
        call "%file_functions%" COPY_FILES "%bkp_display%" "%dir_fontes%" "%~1" "%bkp_extensions_fontes%" "/W:10"
        call "%file_functions%" CHECK_FILES_COPIED "%bkp_display%" "%dir_fontes%" "%~1" "%bkp_extensions_fontes%" & if ERRORLEVEL 1 ( exit /b 1 )
    )

exit /b 0


:delete_some_files path -- apaga alguns arquivos
::                      -- %~1:path [in] - caminho
:$created 03/11/2011 :$author Pedro Elsner

    if exist %~1\$*        ( del %~1\$* )
    if exist %~1\$*.*      ( del %~1\$*.* )
    if exist %~1\a0*.*     ( del %~1\a0*.* )
    if exist %~1\a1*.*     ( del %~1\a1*.* )
    if exist %~1\a2*.*     ( del %~1\a2*.* )
    if exist %~1\b0*.*     ( del %~1\b0*.* )
    if exist %~1\b1*.*     ( del %~1\b1*.* )
    if exist %~1\b2*.*     ( del %~1\b2*.* )
    if exist %~1\s0*.*     ( del %~1\s0*.* )
    if exist %~1\s1*.*     ( del %~1\s1*.* )
    if exist %~1\s2*.*     ( del %~1\s2*.* )
    if exist %~1\inter*.*  ( del %~1\inter*.* )
    if exist %~1\said4*.*  ( del %~1\said4*.* )
    if exist %~1\lista*.*  ( del %~1\lista*.* )
    if exist %~1\lista3*.* ( del %~1\lista3*.* )
    if exist %~1\lista4*.* ( del %~1\lista4*.* )
    if exist %~1\lista6*.* ( del %~1\lista6*.* )
    if exist %~1\lista9*.* ( del %~1\lista9*.* )
    if exist %~1\minuta.*  ( del %~1\minuta.* )

exit /b 0
