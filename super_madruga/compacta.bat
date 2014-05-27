@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do (set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup "%~1" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################


:: Chama BKP se não foi executado com sucesso
call "%file_functions%" CHECK_EXEC_SUCCESS %bkp_display% & if ERRORLEVEL 1 (call:exec_bkp "%option_app%" "%bkp_option_local%" & if ERRORLEVEL 1 (call:end error & exit /b 1))


:: ###################


:: COMPACTA ARQUIVOS LOCAL
call "%file_functions%" MAKE_DIR_OR_DELETE_OLD_FILES "%compacta_display%" "%dir_compacta_local%" "%all_files%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:compact_list "%list_compacta%" "%dir_compacta_local%" & if ERRORLEVEL 1 (call:end error & exit /b 1)



:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup option -- prepara ambiente
::              -- %~1:option [in] - parâmetro de inicialização
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_compacta="
    
    :: ###################
    
    :: Carrega configurações
    call "%file_functions%" LOAD_CONFIG "%~1" & if ERRORLEVEL 1 ( exit /b 1 )
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%compacta_display%" "%pid_compacta%" "pid_code_compacta" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:end error -- encerra processamento
::         -- %~1:error [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_compacta%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%compacta_display%" "%pid_compacta%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "%log_exec_success%"

exit /b 0


:: ###################


:exec_bkp option1 option2 -- executa BKPDIA
::                        -- option1:%~1 [in, opt] - opção do sistema
::                        -- option2:%~2 [in, opt] - opção do sistema
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Executando %bkp_display% (%~1) (%~2)"
    call "%file_bkp%" "%~1" "%~2" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:compact_list list path -- compacta os arquivos de 'list_compacta'
::                      -- %~1:list [in] - lista
::                      -- %~2:path [in] - diretorio
:$created 04/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    setlocal ENABLEDELAYEDEXPANSION
    set "temp_dir=%~2"
    %temp_dir:~0,2% & cd %temp_dir%
    
    set "temp_file_name=file"
    set "temp_list=%temp_file_name%.fls"
    set "temp_rar=%temp_file_name%"
    set "temp_list_rar_files=%temp_file_name%.pts"
    set "temp_list_all_files=temp.tmp"
    
    set "temp_extensions_rar=%rar_files%"
    set "temp_extensions_rar=%temp_extensions_rar:[all]=*%"
    set "temp_extensions_rar=%temp_extensions_rar:[x]=?%"
    
    set "temp_extensions_all=%all_files%"
    set "temp_extensions_all=%temp_extensions_all:[all]=*%"
    set "temp_extensions_all=%temp_extensions_all:[x]=?%"
    
    
    ::###########################
    :: Cria NOVA lista temporária
    ::###########################
        del %temp_list% > nul
        call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Criando lista temporaria '%%~2%temp_list%'"
        for /f "tokens=1,2 delims=;" %%A in (%~1) do (
            if "%%A"=="[dir_bkp]" (
               echo %dir_bkp%%%B >> %temp_list%
            )
            if "%%A"=="[dir_bkp_local]" (
               echo %dir_bkp_local%%%B >> %temp_list%
            )
            if "%%A"=="[dir_dados]" (
               echo %dir_dados%%%B >> %temp_list%
            )
            if "%%A"=="[dir_fontes]" (
               echo %dir_dados%%%B >> %temp_list%
            )
        )
    ::###########################
    
    
    call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Compactando arquivos da lista '%~1' em '%~2'"
    rar32 a -ep -k -m5 -s -y -v2000 %temp_rar% @%temp_list% 
    rem & if errorlevel 1 ( call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_error%" "Erro ao compactar algum(ns) arquivo(s)" )
    
    :: Testa arquivos compactados
    rar32 t %temp_extensions_rar% & if errorlevel 1 (
        call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_error%" "Falha na verificação dos arquivos gerados"
        rem endlocal & %drive_app% & cd %dir_app% & exit /b 1
    )
    
    
    ::###########################
    :: RENOMEIA ARQUIVOS
    ::###########################
        
        
        call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Aguardando 2 min. para renomear arquivos criados (rotina ELSNER)"
        ping -n 60 -w 500 0.0.0.1 > nul
        
        dir %temp_file_name%%temp_extensions_all% /b > %temp_list_all_files%
        for /f "tokens=1,2,3* delims=." %%A in (temp.tmp) do (
           if "%%C"=="" ( 
               call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Renomeando(1) '%%A.%%B' para '%option_app%.%%B'"
               rename %%A.%%B %option_app%.%%B
           ) else (
               call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Renomeando(2) '%%A.%%B.%%C' para '%option_app%.%%B.%%C'"
               rename %%A.%%B.%%C %option_app%.%%B.%%C
           )
        )
        del %temp_list_all_files% /F /Q > nul
        
        call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "PARA GARANTIR - Renomear arquivos '%temp_file_name%*' para '%option_app%*' (rotina OBA)"
        ren %temp_file_name%* %option_app%*
        
        
        :: Redefine variáveis
        set "temp_list=%option_app%.fls"
        set "temp_rar=%option_app%"
        set "temp_list_rar_files=%option_app%.pts"
        
    ::###########################
    
    
    :: Cria lista com arquivos gerados
    dir %temp_rar%%temp_extensions_rar% /b > %temp_list_rar_files%
    
    :: Verificando quantidade de arquivos criados
    endlocal & set "temp_count_files=" & for /f "tokens=*" %%A in (%~2%temp_list_rar_files%) do call "%file_functions%" COUNT temp_count_files
    call "%file_functions%" SAVE_LOG "%compacta_display%" "%log_success%" "Criado(s): %temp_count_files% arquivo(s)"
    %drive_app% & cd %dir_app%
    
exit /b 0
