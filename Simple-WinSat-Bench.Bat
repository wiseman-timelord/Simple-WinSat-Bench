:: Enhanced Simple-WinSat-Bench Launcher
@echo off
setlocal enabledelayedexpansion

:: Global Variables
set "ScriptDirectory=%~dp0"
set "ScriptDirectory=%ScriptDirectory:~0,-1%"

:: Initialize error handling
set "ErrorCount=0"
set "ErrorLog=%ScriptDirectory%\Errors.Log"
set "CrashLog=%ScriptDirectory%\Crashes.Log"

:: Check Admin and PowerShell availability
call :check_prerequisites
if !errorlevel! neq 0 goto :end_of_script

goto :startup_sequence

:: Check Prerequisites
:check_prerequisites
:: Check Admin
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo ===============================================================================
    echo     ERROR: Administrator Rights Required
    echo ===============================================================================
    echo.
    echo This tool requires administrator privileges to run WinSAT benchmarks.
    echo Please right-click this batch file and select "Run as administrator".
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: Check PowerShell availability
call :check_powershell
if !errorlevel! neq 0 (
    echo.
    echo ===============================================================================
    echo     ERROR: PowerShell Not Available
    echo ===============================================================================
    echo.
    echo This tool requires PowerShell to function properly.
    echo Please ensure PowerShell is installed and available in PATH.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

goto :eof

:: Check PowerShell Availability
:check_powershell
set "PSAvailable=0"
where pwsh >nul 2>&1
if !errorlevel! equ 0 (
    set "PSAvailable=1"
    set "PSCommand=pwsh"
    goto :eof
)

where powershell >nul 2>&1
if !errorlevel! equ 0 (
    set "PSAvailable=1"
    set "PSCommand=powershell"
    goto :eof
)

exit /b 1

:: Display Banner
:displayBanner
cls
echo ===============================================================================
echo     Simple-WinSat-Bench : Batch Launcher
echo ===============================================================================
echo.
timeout /t 1 /nobreak >nul 2>&1
goto :eof

:: Display Separator
:displaySeparator
echo.
echo -------------------------------------------------------------------------------
goto :eof

:: Log Error Function
:logError
echo [%date% %time%] %~1 >> "%ErrorLog%"
set /a ErrorCount+=1
goto :eof

:: Startup Sequence
:startup_sequence
cd /d "%ScriptDirectory%"
call :displayBanner
echo Status: Administrator Rights Confirmed
timeout /t 1 /nobreak >nul 2>&1
echo Working Directory: %ScriptDirectory%
timeout /t 1 /nobreak >nul 2>&1
echo PowerShell Engine: %PSCommand%
timeout /t 1 /nobreak >nul 2>&1

:: Clean up old logs
echo Cleaning up old logs...
if exist "%ErrorLog%" del "%ErrorLog%" >nul 2>&1
if exist "%CrashLog%" del "%CrashLog%" >nul 2>&1
echo Log cleanup completed.
timeout /t 1 /nobreak >nul 2>&1

:: Check for required PowerShell scripts
call :check_scripts
if !errorlevel! neq 0 (
    echo.
    echo ERROR: Required PowerShell scripts are missing.
    echo Please ensure benchmarks.ps1 and diagnostics.ps1 are in the same directory.
    echo.
    pause
    goto :end_of_script
)

goto :main_menu

:: Check Scripts Existence
:check_scripts
if not exist "%ScriptDirectory%\benchmarks.ps1" (
    call :logError "benchmarks.ps1 not found"
    exit /b 1
)
if not exist "%ScriptDirectory%\diagnostics.ps1" (
    call :logError "diagnostics.ps1 not found"
    exit /b 1
)
goto :eof

:: Main Menu
:main_menu
call :displayBanner
echo.
echo     1. Run Benchmarks and Show Results
echo     2. Run Diagnostic Checks
echo     3. View Error Log (if exists)
echo     4. About / System Information
echo.
call :displaySeparator
set /p choice=Selection; Menu Options = 1-4, Exit = X: 

if /i "%choice%"=="x" goto :end_of_script
if /i "%choice%"=="1" goto :run_benchmarks
if /i "%choice%"=="2" goto :run_diagnostics
if /i "%choice%"=="3" goto :view_error_log
if /i "%choice%"=="4" goto :show_about

echo Invalid choice. Please select 1-4 or X to exit.
timeout /t 2 /nobreak >nul 2>&1
goto :main_menu

:: Run Benchmarks
:run_benchmarks
call :displayBanner
echo Launching WinSAT Benchmarks...
echo This may take several minutes to complete.
echo.
timeout /t 2 /nobreak >nul 2>&1

call :runPSScript "benchmarks.ps1"
set "ExitCode=!errorlevel!"

if !ExitCode! neq 0 (
    echo.
    echo WARNING: Benchmark script exited with code !ExitCode!
    echo [%date% %time%] benchmarks.ps1 failed with exit code !ExitCode! >> "%CrashLog%"
    call :logError "benchmarks.ps1 execution failed with exit code !ExitCode!"
    echo.
    echo Check the error log for more details.
    timeout /t 3 /nobreak >nul 2>&1
)

echo.
echo Press any key to return to main menu...
pause >nul
goto :main_menu

:: Run Diagnostics
:run_diagnostics
call :displayBanner
echo Running System Diagnostics...
echo.
timeout /t 2 /nobreak >nul 2>&1

call :runPSScript "diagnostics.ps1"
set "ExitCode=!errorlevel!"

if !ExitCode! neq 0 (
    echo.
    echo WARNING: Diagnostic script exited with code !ExitCode!
    echo [%date% %time%] diagnostics.ps1 failed with exit code !ExitCode! >> "%CrashLog%"
    call :logError "diagnostics.ps1 execution failed with exit code !ExitCode!"
    echo.
    echo Check the error log for more details.
    timeout /t 3 /nobreak >nul 2>&1
)

echo.
echo Press any key to return to main menu...
pause >nul
goto :main_menu

:: View Error Log
:view_error_log
call :displayBanner
echo Error Log Contents:
echo.
if exist "%ErrorLog%" (
    type "%ErrorLog%"
    echo.
    echo -------------------------------------------------------------------------------
    echo Total Errors: %ErrorCount%
) else (
    echo No errors recorded.
)

if exist "%CrashLog%" (
    echo.
    echo Crash Log Contents:
    echo.
    type "%CrashLog%"
) else (
    echo No crashes recorded.
)

echo.
echo Press any key to return to main menu...
pause >nul
goto :main_menu

:: Show About
:show_about
call :displayBanner
echo System Information:
echo.
echo PowerShell Engine: %PSCommand%
echo Script Directory: %ScriptDirectory%
echo Current User: %USERNAME%
echo Computer Name: %COMPUTERNAME%
echo.
echo This tool uses WinSAT to benchmark Windows Server 2012 systems.
echo WinSAT must be manually copied from a desktop Windows installation.
echo.
echo For support and updates, check the project documentation.
echo.
echo Press any key to return to main menu...
pause >nul
goto :main_menu

:: Function to run PowerShell scripts with enhanced error handling
:runPSScript
echo Executing PowerShell script: "%~1"
set "ScriptPath=%ScriptDirectory%\%~1"

if not exist "%ScriptPath%" (
    echo ERROR: Script file not found: %ScriptPath%
    call :logError "Script file not found: %ScriptPath%"
    exit /b 1
)

echo Using PowerShell engine: %PSCommand%
timeout /t 1 /nobreak >nul 2>&1

%PSCommand% -NoProfile -ExecutionPolicy Bypass -File "%ScriptPath%"
set "PSExitCode=!errorlevel!"

if !PSExitCode! neq 0 (
    echo.
    echo PowerShell script execution completed with exit code: !PSExitCode!
    if !PSExitCode! geq 1 (
        echo This may indicate an error or early termination.
    )
)

exit /b !PSExitCode!

:: Exit
:end_of_script
call :displayBanner
echo.
echo Shutting down Simple-WinSat-Bench...
if %ErrorCount% gtr 0 (
    echo.
    echo Warning: %ErrorCount% error(s) were logged during this session.
    echo Check %ErrorLog% for details.
)
echo.
echo Thank you for using Simple-WinSat-Bench!
timeout /t 3 /nobreak >nul 2>&1
exit /b 0