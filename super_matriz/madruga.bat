@echo off
for /f "tokens=*" %%A in ('dir madruga.bat /b /s') do ( set "dir_app=%%~dA%%~pA" )
for /f "tokens=*" %%A in ('dir initialize.bat /b /s') do ( set "drive_app=%%~dA" & call "%%A" & if ERRORLEVEL 1 exit /b 1)


:: Inicializa
call:startup & if ERRORLEVEL 1 (call:end error & exit /b 1)
call:exec_efetexe "%dir_fontes%"
call:exec_efetexe "%dir_gerencia%"
call:exec_adsdosip
call:nlist_user "/a /b /c"
call:systime


:: ###################

call:exec_discoj

:: ###################

call:exec_killuser "madruga_somente"
call:exec_bkpf "%dir_matriz%" "madruga"
for /f "tokens=*" %%Z in ('dir %dir_app_filiais% /a-d /b') do (call:exec_atufil %%~nZ)
call:exec_atu_dtuc "%dir_matriz%"
call:exec_killuser "madruga_somente"
call:exec_reindexa "%dir_matriz%" & if ERRORLEVEL 1 (
    call:exec_killuser "madruga_somente"
    call:exec_indxluiz "%dir_matriz%"
    call:exec_tpindexa "%dir_matriz%" "70"
)
call:exec_atupedcp "%dir_matriz%"
call:exec_buscabo "%dir_matriz%"
call:exec_divcpa "%dir_matriz%" "9"
call:exec_limpaprn "%dir_matriz%"
for /f "tokens=*" %%Z in ('dir %dir_app_filiais% /b /s') do (call:exec_atusp %%~nZ %%Z)
call:exec_comfil "%dir_matriz%"
call:exec_atudf "%dir_matriz%"
call:exec_embarque "%dir_matriz%"
call:exec_alrtprot "%dir_matriz%"
call:exec_atucpa "%dir_matriz%"
call:exec_envtranf "%dir_matriz%" "99"
call:exec_transito "%dir_matriz%"

:: ###################

call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Apagando arquivos '%dir_matriz%pedent*.ntx'"
del %dir_matriz%pedent*.ntx > nul
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Apagando arquivos '%dir_matriz%cot?.ntx'"
del %dir_matriz%cot?.ntx > nul
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Apagando arquivo '%dir_matriz%sk.txt'"
del %dir_matriz%sk.txt > nul
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Apagando arquivos '%dir_matriz%operador\env\*.env'"
del %dir_matriz%operador\env\*.env > nul
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Apagando arquivos '%dir_matriz%operador\tra\*.txt'"
del %dir_matriz%operador\tra\*.txt > nul
call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Apagando arquivos '%dir_matriz%repres70.*'"
del %dir_matriz%repres70.* > nul

:: ###################

call:exec_repres2 "%dir_matriz%"
for /f "tokens=*" %%Z in ('dir %dir_app_filiais% /b /s') do (call:exec_objvend %%~nZ %%Z)
for /f "tokens=*" %%Z in ('dir %dir_app_filiais% /a-d /b') do (call:exec_cop %%~nZ)
call:exec_copiinv "%dir_matriz%"



:: Fim
(call:end & exit /b 0)


:: ###################
:: ###################


:startup -- prepara ambiente
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    :: Zera pid
    set "pid_code_madruga="
    
    :: ###################
    
    :: Cria PID
    call "%file_functions%" MAKE_PID "%madruga_display%" "%pid_madruga%" "pid_code_madruga" & if ERRORLEVEL 1 ( exit /b 1 )
    
exit /b 0


:end error -- encerra processamento
::         -- %~1:error  [in, opt] - pode ser 'error'
:$created 01/11/2011 :$author Pedro Elsner
:$updated  :$by 
    
    if "%pid_code_madruga%"=="" ( exit /b 1 )
    
    :: ###################
    
    :: Apaga PID
    call "%file_functions%" KILL_PID "%madruga_display%" "%pid_madruga%"
    
    :: Se função foi chamada por um erro
    if "%~1"=="error" (
        
        if "%pid_code_madruga%"=="" ( exit /b 1 )
        
        :: Registra LOG e envia e-mail de erro, se PID existir
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_error%" "%log_exec_error%"
        call "%file_functions%" SEND_MAIL_ERROR "%option_app%"
        
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "%log_exec_success%"
        call "%file_functions%" CHECK_SUCCESS_FULL "%option_app%"
    )
    
    :: Copia arquivo de log para rede
    mkdir %dir_sm_log% > nul
    copy /Y %file_log% %dir_sm_log%%matriz_svn%.%file_log_extension% > nul
    
    
    :: ###################
    :: ###################
    
    :: Mapeia Servidor STORAGE
    net use %storage_map%: %storage_path% > nul
    
    :: Copia log super_madruga
    mkdir %storage_sm_log% > nul
    copy /Y %file_log% %storage_sm_log%%matriz_svn%.%file_log_extension% > nul
    
    
    :: ###################
    
    if "%~1"=="error" ( exit /b 1 )
exit /b 0


:set_var var value -- define variável
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


:: ###################


:nlist_user option -- gera lista de usuarios conectados
::          	   -- %~1:option [in] - parametros
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Gerando lista de usuarios conectados (%nlist_user_result%)"
    
    %dir_app_log:~0,2% & cd %dir_app_log%
    %file_nlist% user %~1 > %nlist_user_result%
    %drive_app% & cd %dir_app%
    
exit /b 0


:systime -- sincroniza horario com o servidor
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 

	
	call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Sincroniza horario com o servidor"
	%file_systime%

exit /b 0


:exec_killuser option -- remove os usuários da rede
::               -- %~1:option [in] - parametro
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 

	f: & cd \sk\madruga\
    
	call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Remove usuarios da rede (%~1)"
	killuser.exe %~1
    
    %drive_app% & cd %dir_app%

exit /b 0


:: ###################


:exec_discoj -- executa DISCOJ
:$created 27/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %discoj_display%"
    call "%file_discoj%" & if ERRORLEVEL 1 ( exit /b 1 )

exit /b 0


:exec_atusp filial file -- executa ATUSP
::                      -- %~1:filial [in] - nome da filial
::                      -- %~2:file   [in] - arquivo
:$created 02/02/2012 :$author Pedro Elsner
:$updated  :$by 
    
    
    for /f "tokens=1,2* delims=^=" %%A in (%~2) do (call:set_var "%%A" "%%B")
    
    %dir_matriz:~0,2% & cd %dir_matriz%
    
    if not exist e1%filial_code%.txt (
        %drive_app% & cd %dir_app%
        exit /b 0
    )
    
    blat -install %blat_smtp% %blat_sender% 5 25
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atusp_display% (%~1)"
    call "%file_functions%" SAVE_LOG "%atusp_display%" "%log_success%" "Iniciado"
    
    call "%file_functions%" SAVE_LOG "%atusp_display%" "%log_success%" "Compactando 'atusp%filial_code%.ace'"
    if exist atusp%filial_code%.ace ( del atusp%filial_code%.ace > nul )
    ace a -m5 -ep -std -d1024 -tc:\temp atusp%filial_code%.ace e1%filial_code%.dbf e2%filial_code%.dbf
    
    call "%file_functions%" SAVE_LOG "%atusp_display%" "%log_success%" "Enviando 'atusp%filial_code%.ace' para '%filial_email%'"
    
    if "%~1"=="santos" ( blat atusp%filial_code%.ace -t %filial_email% -s "Salvar em f:\santos e Descompactar" -uuencode -noh2 )
    else ( blat atusp%filial_code%.ace -t %filial_email% -s "Salvar em f:\dados e Descompactar" -uuencode -noh2 )
    del e1%filial_code%.txt > nul
    
    call "%file_functions%" SAVE_LOG "%atusp_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_objvend filial file
::                         -- %~1:filial [in] - nome da filial
::                         -- %~2:file   [in] - arquivo
:$created 02/02/2012 :$author Pedro Elsner
:$updated  :$by 
    
    
    for /f "tokens=1,2* delims=^=" %%A in (%~2) do (call:set_var "%%A" "%%B")
    
    %dir_matriz:~0,2% & cd %dir_matriz%
    
    if not exist OBJ%filial_code%.RAR (
        %drive_app% & cd %dir_app%
        exit /b 0
    )
    
    blat -install %blat_smtp% %blat_sender% 5 25
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %objvend_display% (%~1)"
    call "%file_functions%" SAVE_LOG "%objvend_display%" "%log_success%" "Iniciado"
    
    call "%file_functions%" SAVE_LOG "%objvend_display%" "%log_success%" "Enviando 'atusp%filial_code%.ace' para '%filial_email%'"
    if "%~1"=="santos" ( blat OBJ%filial_code%.RAR -t %filial_email% -s "Salvar em f:\santos e Descompactar" -uuencode -noh2 )
    else ( blat OBJ%filial_code%.RAR -t %filial_email% -s "Salvar em f:\dados e Descompactar" -uuencode -noh2 )
    del OBJ%filial_code%.RAR > nul
    
    call "%file_functions%" SAVE_LOG "%objvend_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_atufil filial -- executa ATUFIL
::                  -- %~1:filial [in] - nome da filial
:$created 02/02/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Copiando 'print*.bat perm*.* local.* recibo.htm recibo.png partida.htm partida2.htm' de '%dir_matriz%' para '%dir_sk%%~1'"
    copy /y %dir_matriz%PRINT*.BAT %dir_sk%%~1
    copy /y %dir_matriz%PERM*.* %dir_sk%%~1
    copy /y %dir_matriz%local.* %dir_sk%%~1\locais.*
    copy /y %dir_matriz%RECIBO.HTM %dir_sk%%~1
    copy /y %dir_matriz%RECIBO.PNG %dir_sk%%~1
    copy /y %dir_matriz%PARTIDA.HTM %dir_sk%%~1
    copy /y %dir_matriz%PARTIDA2.HTM %dir_sk%%~1
    
exit /b 0


:exec_cop filial
::                  -- %~1:filial [in] - nome da filial
:$created 02/02/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Copiando 'perm* locais* cadvar1*' de '%dir_matriz%' para '%dir_sk%%~1'"
    copy /y %dir_matriz%perm* %dir_sk%%~1
    copy /y %dir_matriz%locais* %dir_sk%%~1
    copy /y %dir_matriz%cadvar1* %dir_sk%%~1
    
exit /b 0


:exec_efetexe path -- executa EFETEXE
::                 -- %~1:path [in] - diretório base
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %efetexe_display%"
    call "%file_functions%" SAVE_LOG "%efetexe_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_efetexe%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%efetexe_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%efetexe_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_adsdosip -- executa ADSDOSIP
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %adsdosip_display%"
    start %file_adsdosip%
    
exit /b 0


:exec_atu_dtuc path -- executa ATU_DTUC
::                  -- %~1:path [in] - diretório base
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atu_dtuc_display%"
    call "%file_functions%" SAVE_LOG "%atu_dtuc_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_atu_dtuc%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%atu_dtuc_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%atu_dtuc_display%" "%log_success%" "%log_exec_success%"
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


:exec_reindexa path -- executa REINDEXA
::                  -- %~1:path [in] - diretório base
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %reindexa_display%"
    call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_reindexa%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%reindexa_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_indxluiz path -- executa INDXLUIZ
::                  -- %~1:path [in] - diretório base
:$created 28/11/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %indxluiz_display%"
    call "%file_functions%" SAVE_LOG "%indxluiz_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_indxluiz%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%indxluiz_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%indxluiz_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_tpindexa path param -- executa INDXLUIZ
::                        -- %~1:path  [in] - diretório base
::                        -- %~2:param [in] - parametro
:$created 28/11/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %tpindexa_display% (%~2)"
    call "%file_functions%" SAVE_LOG "%tpindexa_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_tpindexa% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%tpindexa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%tpindexa_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_atupedcp path -- executa ATUPEDCP
::                  -- %~1:path [in] - diretório base
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atupedcp_display%"
    call "%file_functions%" SAVE_LOG "%atupedcp_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_atupedcp%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%atupedcp_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%atupedcp_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_buscabo path -- executa BUSCABO
::                  -- %~1:path [in] - diretório base
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %buscabo_display%"
    call "%file_functions%" SAVE_LOG "%buscabo_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_buscabo%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%buscabo_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%buscabo_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_divcpa path option -- executa DIVCPA
::                       -- %~1:path [in] - diretório base
::                       -- %~2:option [in] - parametro
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %divcpa_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %divcpa_display% (%~2)" 
    )
    call "%file_functions%" SAVE_LOG "%divcpa_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_divcpa% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%divcpa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%divcpa_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_limpaprn path -- executa LIMPAPRN
::                 -- %~1:path [in] - diretório base
:$created 17/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %limpaprn_display%"
    call "%file_functions%" SAVE_LOG "%limpaprn_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_limpaprn%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%limpaprn_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%limpaprn_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_comfil path -- executa COMFIL
::                -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %comfil_display%"
    call "%file_functions%" SAVE_LOG "%comfil_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_comfil%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%comfil_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%comfil_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_atudf path -- executa ATUDF
::               -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atudf_display%"
    call "%file_functions%" SAVE_LOG "%atudf_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_atudf%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%atudf_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%atudf_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_embarque path -- executa EMBARQUE
::                  -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %embarque_display%"
    call "%file_functions%" SAVE_LOG "%embarque_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_embarque%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%embarque_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%embarque_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_alrtprot path -- executa ALRTPROT
::                  -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %alrtprot_display%"
    call "%file_functions%" SAVE_LOG "%alrtprot_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_alrtprot%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%alrtprot_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%alrtprot_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_atucpa path -- executa ATUCPA
::                -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %atucpa_display%"
    call "%file_functions%" SAVE_LOG "%atucpa_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_atucpa%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%atucpa_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%atucpa_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_envtranf path -- executa ENVTRANF
::                  -- %~1:path   [in] - diretório base
::                  -- %~2:option [in] - parametro
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    if "%~2"=="" (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %envtranf_display%" 
    ) else (
        call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %envtranf_display% (%~2)" 
    )
    call "%file_functions%" SAVE_LOG "%envtranf_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_envtranf% %~2
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%envtranf_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%envtranf_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_transito path -- executa TRANSITO
::                  -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %transito_display%"
    call "%file_functions%" SAVE_LOG "%transito_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_transito%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%transito_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%transito_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_repres2 path -- executa REPRES2
::                 -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %repres2_display%"
    call "%file_functions%" SAVE_LOG "%repres2_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_repres2%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%repres2_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%repres2_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_estoque path -- executa ESTOQUE
::                 -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %estoque_display%"
    call "%file_functions%" SAVE_LOG "%estoque_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_estoque%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%estoque_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%estoque_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0


:exec_copiinv path -- executa COPIINV
::                 -- %~1:path [in] - diretório base
:$created 23/01/2012 :$author Pedro Elsner
:$updated  :$by 
    
    call "%file_functions%" SAVE_LOG "%madruga_display%" "%log_success%" "Executando %copiinv_display%"
    call "%file_functions%" SAVE_LOG "%copiinv_display%" "%log_success%" "Iniciado"
    
    setlocal
    set "temp_dir=%~1"
    endlocal & %temp_dir:~0,2% & cd %temp_dir%
    
    %file_copiinv%
    if "%errorlevel%" GEQ "1" (
        call "%file_functions%" SAVE_LOG "%copiinv_display%" "%log_error%" "%log_exec_error%"
        %drive_app% & cd %dir_app%
        exit /b 1
    )
    call "%file_functions%" SAVE_LOG "%copiinv_display%" "%log_success%" "%log_exec_success%"
    %drive_app% & cd %dir_app%
    
exit /b 0

