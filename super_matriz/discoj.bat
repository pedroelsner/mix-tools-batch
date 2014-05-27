@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup & if ERRORLEVEL 1 (call:end error & exit /b 1)

:: ###################


call "%file_functions%" MAKE_DIR_OR_DELETE_OLD_FILES "%discoj_display%" "%dir_precodrd%" "%all_files%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
rem call:exec_altfabr "%dir_matriz%" "9" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:exec_pedcpa "%dir_matriz%" "9" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:exec_envfil "%dir_matriz%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:exec_gerpreco "%dir_matriz%" & if ERRORLEVEL 1 (call:end error & exit /b 1)


:: ###################
:: ###################
MOVE %dir_matriz%PRECODRD.DBF %dir_precodrd%
IF EXIST %dir_matriz%REPRES.TXT  COPY %dir_matriz%REPRES.DBF %dir_precodrd%REPRES70.DBF
IF EXIST %dir_matriz%REPRES.TXT  COPY %dir_matriz%REPRES.DBT %dir_precodrd%REPRES70.DBT
IF EXIST %dir_matriz%CLI70.DBF   COPY %dir_matriz%CLI70.DBF  %dir_precodrd%CLI70.DBF
IF EXIST %dir_matriz%ESTBOL.DBF  COPY %dir_matriz%ESTBOL.DBF %dir_precodrd%ESTBOL.DBF
IF EXIST %dir_matriz%TRANSP.TXT  COPY %dir_matriz%TRANSP.DBF %dir_precodrd%TRANSP70.DBF
COPY %dir_matriz%FORNECE.DBF  %dir_precodrd%FORNEMA.DBF
COPY %dir_matriz%GRUPOS.DBF   %dir_precodrd%GRUPOSC.DBF
COPY %dir_matriz%CLASSES.DBF  %dir_precodrd%CLASSESC.DBF
:: ###################
:: ###################


call "%file_functions%" COPY_FILES "%discoj_display%" "%dir_matriz%" "%dir_precodrd%" "%discoj_list_precodrd%" "/W:10 /PURGE"
call "%file_functions%" CHECK_FILES_COPIED "%discoj_display%" "%dir_matriz%" "%dir_precodrd%" "%discoj_list_precodrd%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:exec_compacta "%dir_matriz%" "%precodrd_file%" "%dir_precodrd%" & if ERRORLEVEL 1 (call:end error & exit /b 1)
call "%file_functions%" DELETE_DIR "%dir_precodrd%" "/S /Q"



:: ###################


:DELETE
:: Verifica se o diretório existe
if not exist %dir_svn_matriz%nul (
	call:checkout_svn "%dir_svn_matriz%" & if ERRORLEVEL 1 (goto WAIT_RETRY_DELETE)
)

call:update_svn "%dir_svn_matriz%" & if ERRORLEVEL 1 (goto WAIT_RETRY_DELETE)
call:delete_svn "%dir_svn_matriz%" "%precodrd_file%"

:: Se em algum arquivo falhou, tenta novamente
if "%files_deleted_errors%" GEQ "1" goto WAIT_RETRY_DELETE

:: Copia 'precordrd.ace' da pasta 'dir_matriz' para 'dir_svn_matriz' e verifica se foi copiado
call "%file_functions%" COPY_FILES "%discoj_display%" "%dir_matriz%" "%dir_svn_matriz%" "%precodrd_file%" "/W:10"
call "%file_functions%" CHECK_FILES_COPIED "%discoj_display%" "%dir_matriz%" "%dir_svn_matriz%" "%precodrd_file%" & if ERRORLEVEL 1 (call:end error & exit /b 1)

:: Concluído, chama ADD
goto ADD


:WAIT_RETRY_DELETE
:: Acrescenta 1 ao marcador
set /a "svn_error+=1"

:: Se atingiu limite maximo de tentativas, envia e-mail e zera marcador
if "%svn_error%" GEQ "%svn_try_after_sendmail%" (
    call "%file_functions%" SEND_MAIL_ERROR
    set /a "svn_error=0"
)

:: Apaga diretório e aguarda o tempo estipulado e chama DELETE
call "%file_functions%" DELETE_DIR "%dir_svn_matriz%" "/S /Q"
call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
ping -n %svn_wait_seconds% -w 500 0.0.0.1 > nul
goto DELETE


:: ###################


:ADD
call:add_svn "%dir_svn_matriz%" "%precodrd_file%"

:: Se em algum arquivo falhou, tenta novamente
if "%files_added_errors%" GEQ "1" goto WAIT_RETRY_ADD

:: Concluído, chama SUCCESS
goto SUCCESS


:WAIT_RETRY_ADD
:: Acrescenta 1 ao marcador
set /a "svn_error+=1"

:: Se atingiu limite maximo de tentativas, envia e-mail e zera marcador
if "%svn_error%" GEQ "%svn_try_after_sendmail%" (
    call "%file_functions%" SEND_MAIL_ERROR
    set /a "svn_error=0"
)

:: Aguarda o tempo estipulado e chama ADD
call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Aguardando %svn_wait_minutes% min. para reiniciar"
ping -n %svn_wait_seconds% -w 500 0.0.0.1 > nul
goto ADD


:: ###################


:SUCCESS
:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup -- prepara ambiente
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_discoj="
    
    :: ###################
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%discoj_display%" "%pid_discoj%" "pid_code_discoj" & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    
    if "%pid_code_discoj%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%discoj_display%" "%pid_discoj%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "%log_exec_error%"
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "%log_exec_success%"
    
exit /b 0


:: ###################


:checkout_svn path -- realiza checkout do repositório
::                 -- %~1:path [in] - diretorio
:$created 05/01/2012 :$author Pedro Elsner
:$updated  :$by 

    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Criando repositorio '%~1'"
    
    svn checkout %svn_auth% %svn_connection_matriz% %~1 & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao criar repositorio"
        exit /b 1
    )

exit /b 0


:update_svn path -- atualiza o diretório
::               -- %~1:path [in] - diretorio
:$created 07/11/2011 :$author Pedro Elsner
:$updated  :$by 

    :: Prepara repositório
    svn upgrade %svn_auth% %~1
    svn cleanup %svn_auth% %~1
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Atualizando repositorio '%~1'"
    
    svn update %svn_auth% --accept theirs-full %~1 & if ERRORLEVEL 1 (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao atualizar repositorio"
        exit /b 1
    )

exit /b 0


:delete_svn path files -- apaga os arquivos
::                     -- %~1:path  [in] - diretório
::                     -- %~2:files [in] - arquivos
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Reseta variável
    set /a "files_deleted_errors=0"
    
    :: Verifica se exite arquivos no diretorio
    setlocal
    for /f "tokens=*" %%A in ('dir /a-d /b "%~1%~2" ^| find /n /c /v ""') do (set "temp_count_files=%%A")
    endlocal & if "%temp_count_files%"=="0" (exit /b 0)
    
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Excluindo (%~2) de '%~1'"

    for /f "tokens=*" %%G in ('dir /a-d /b "%~1%~2"') do (
        svn delete %svn_auth% %~1%%G --force
        if ERRORLEVEL 1 (
            call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao excluir '%%G'"
            set /a "files_deleted_errors+=1"
        ) else (
            svn commit %svn_auth% -m '' %~1%%G
            if ERRORLEVEL 1 (
                call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao excluir '%%G'"
                set /a "files_deleted_errors+=1"
            )
        )
    )
    
    if "%files_deleted_errors%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Concluido com erro(s): %files_deleted_errors%"
    )

exit /b 0


:add_svn path files -- adiciona os arquivos
::                  -- %~1:path  [in] - diretório
::                  -- %~2:files [in] - arquivos
:$created 24/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    :: Reseta variável
    set /a "files_added_errors=0"

    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Enviando (%~2) de '%~1'"

    for /f "tokens=*" %%G in ('dir /a-d /b "%~1%~2"') do (
        svn add %svn_auth% %~1%%G --force
        if ERRORLEVEL 1 (
            call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao enviar '%%G'"
            set /a "files_added_errors+=1"
        ) else (
            svn commit %svn_auth% -m '' %~1%%G
            if ERRORLEVEL 1 (
                call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao enviar '%%G'"
                set /a "files_added_errors+=1"
            )
        )
    )
    
    if "%files_added_errors%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Concluido com erro(s): %files_added_errors%"
    )

exit /b 0



:exec_altfabr path option -- executa altfabr
::                        -- %~1:path   [in] - diretório base
::                        -- %~2:option [in] - opção
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Executando %altfabr_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Executando %altfabr_display% (%~2)" 
    )
    call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_altfabr% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%altfabr_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_pedcpa path -- executa PEDCPA
::                -- %~1:path [in] - diretório base
::                -- %~2:option [in] - opção
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Executando %pedcpa_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Executando %pedcpa_display% (%~2)" 
    )
    call "%file_functions%" SAVE_LOG "%pedcpa_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_pedcpa% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%pedcpa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%pedcpa_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_envfil path -- executa ENVFIL
::                -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Executando %envfil_display%"
    call "%file_functions%" SAVE_LOG "%envfil_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_envfil%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%envfil_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%envfil_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_gerpreco path -- executa GERPRECO
::                  -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Executando %gerpreco_display%"
    call "%file_functions%" SAVE_LOG "%gerpreco_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_gerpreco%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%gerpreco_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%gerpreco_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_compacta path file dir_source -- compacta os arquivos gerando 'PRECODRD.ACE'
::                                  -- %~1:path       [in] - diretório base
::                                  -- %~2:file       [in] - arquivo
::                                  -- %~3:dir_source [in] - diretorio a ser compactado
:$created 27/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Compactando arquivos de '%~1' em '%~2'"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    del j:\SK\MATRIZ\PRECODRD.ACE > nul
    ACE M -Tj:\SK\MATRIZ -M5 -EP -Parqmatsk -STD -d1024 -s J:\SK\MATRIZ\PRECODRD.ACE J:\SK\MATRIZ\PRECODRD\*.*
    if errorlevel 1 (
        call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_error%" "Erro ao compactar algum(ns) arquivo(s)"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    
    call "%file_functions%" SAVE_LOG "%discoj_display%" "%log_success%" "Arquivos '%~2' foi gerado"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_bkpf path option -- executa BKPF
::                     -- %~1:path   [in] - diretório base
::                     -- %~2:option [in] - option
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Bloqueia o sistema ate processar as filiais na matriz (super_descompacta)"
   
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_bkpf% %~2
    %drive_app% & cd %dir_app%
    
exit /b 0

