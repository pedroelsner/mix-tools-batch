@echo off
for /f "tokens=*" %%A in ('dir descompacta.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1 )


:: Inicializa
call:startup "%~1" "%~2" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:: Apaga todos os arquivos da pasta 'dir_destination_temp' se processo COMPLETO
if "%option_app%"=="completo" (
	call "%file_functions%" MAKE_DIR_OR_DELETE_OLD_FILES "%descompacta_display%" "%dir_destination%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
)

:: Copia os arquivos de 'dir_source' para 'dir_destination_temp' e verifica se todos os arquivos foram copiados
call "%file_functions%" COPY_FILES "%descompacta_display%" "%dir_source%" "%dir_destination%" "%option_app%%rar_files%" "/W:10"
call "%file_functions%" CHECK_FILES_COPIED "%descompacta_display%" "%dir_source%" "%dir_destination%" "%option_app%%rar_files%" & if ERRORLEVEL 1 (call:end error & exit /b 1)

:: Descompacta
call:descompacta "%option_app%" "%dir_destination%" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup option filial -- prepara ambiente
::                     -- %~1:option [in] - parâmetro de inicialização
::                     -- %~1:filial [in] - parâmetro de inicialização
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_descompacta="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" "%~2" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%descompacta_display%" "%pid_descompacta%" "pid_code_descompacta" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Registra LOG do processo que sera descompactado
    call "%file_functions%" SAVE_LOG "%descompacta_display%" "%log_success%" "Descompactando processo: %filial_pid_process%"
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 16/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_descompacta%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%descompacta_display%" "%pid_descompacta%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%descompacta_display%" "%log_error%" "%log_exec_error%"
    ) else (
        call "%file_functions%" SAVE_LOG "%descompacta_display%" "%log_success%" "%log_exec_success%"
    )
    
    
    if "%~1"=="error" (exit /b 1)
exit /b 0


:: ###################


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

    for /f "tokens=*" %%G in ('dir /a-d /b "%~1%~2*.*"') do (
        svn delete %svn_auth% %~1%%G --force
        if ERRORLEVEL 1 (
            set /a "files_deleted_errors+=1"
        ) else (
            svn commit %svn_auth% -m '' %~1%%G
            if ERRORLEVEL 1 (
                set /a "files_deleted_errors+=1"
            )
        )
    )

exit /b 0


:descompacta file path -- compacta os arquivos de 'list_compacta'
::                     -- %~1:file [in] - arquivo principal
::                     -- %~1:path [in] - diretorio
:$created 04/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    setlocal ENABLEDELAYEDEXPANSION
    set "temp_path=%~2"
    for /f "tokens=*" %%A in (%dir_source_file_pts%) do ( set "temp_file=%%A" )
    set "temp_extension=*.rar"
    
    %temp_path:~0,2% & cd %temp_path%
    
    :: Descompacta arquivos
    call "%file_functions%" SAVE_LOG "%descompacta_display%" "%log_success%" "Descompactando em '%temp_path%' arquivo principal '%temp_file%' e suas partes"
    unrar e -y %temp_file% & echo . & if errorlevel 1 ( endlocal & %drive_app% & cd %dir_app% & exit /b 1 )
    
    :: Excluir arquivos RAR da pasta
    call "%file_functions%" SAVE_LOG "%descompacta_display%" "%log_success%" "Apagando arquivos (%temp_extension%) de '%temp_path%'"
    del %temp_extension% /F /Q > nul
    endlocal
    
    %drive_app% & cd %dir_app%
    
exit /b 0