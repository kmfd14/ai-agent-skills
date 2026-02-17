@echo off
REM Tauri Payroll SaaS Builder - Skill Installation Script for Windows

echo ==================================================
echo Tauri Payroll SaaS Builder - Skill Installer
echo ==================================================
echo.

set SKILL_NAME=tauri-payroll-saas-builder
set CONTINUE_DIR=%USERPROFILE%\.continue\skills
set CLAUDE_DEV_DIR=%USERPROFILE%\.vscode\extensions\claude-dev-skills
set SCRIPT_DIR=%~dp0

echo Select your VS Code Claude extension:
echo 1) Continue
echo 2) Claude Dev / Cline
echo 3) Manual (just show me the paths)
echo.
set /p choice="Enter choice [1-3]: "

if "%choice%"=="1" goto continue_install
if "%choice%"=="2" goto claude_dev_install
if "%choice%"=="3" goto manual_install
goto invalid_choice

:continue_install
echo.
echo Installing for Continue extension...

REM Create directory if it doesn't exist
if not exist "%CONTINUE_DIR%" mkdir "%CONTINUE_DIR%"

REM Backup if exists
if exist "%CONTINUE_DIR%\%SKILL_NAME%" (
    echo Skill already exists. Backing up...
    rename "%CONTINUE_DIR%\%SKILL_NAME%" "%SKILL_NAME%.backup.%date:~-4%%date:~-10,2%%date:~-7,2%"
)

REM Copy skill
xcopy /E /I "%SCRIPT_DIR%" "%CONTINUE_DIR%\%SKILL_NAME%"

echo.
echo Success! Skill installed successfully!
echo.
echo Next steps:
echo 1. Open VS Code
echo 2. Press Ctrl + Shift + P
echo 3. Search for 'Continue: Open Config'
echo 4. Add this to your config.json:
echo.
echo {
echo   "skills": [
echo     {
echo       "name": "tauri-payroll-saas-builder",
echo       "path": "%CONTINUE_DIR%\%SKILL_NAME%\SKILL.md"
echo     }
echo   ]
echo }
echo.
echo 5. Reload VS Code
echo 6. Use @tauri-payroll-saas-builder in Continue chat
goto end

:claude_dev_install
echo.
echo Installing for Claude Dev / Cline extension...

REM Create directory if it doesn't exist
if not exist "%CLAUDE_DEV_DIR%" mkdir "%CLAUDE_DEV_DIR%"

REM Backup if exists
if exist "%CLAUDE_DEV_DIR%\%SKILL_NAME%" (
    echo Skill already exists. Backing up...
    rename "%CLAUDE_DEV_DIR%\%SKILL_NAME%" "%SKILL_NAME%.backup.%date:~-4%%date:~-10,2%%date:~-7,2%"
)

REM Copy skill
xcopy /E /I "%SCRIPT_DIR%" "%CLAUDE_DEV_DIR%\%SKILL_NAME%"

echo.
echo Success! Skill installed successfully!
echo.
echo Next steps:
echo 1. Open VS Code
echo 2. In Claude Dev/Cline chat, reference the skill by pasting SKILL.md content
echo 3. Or configure Claude Dev to auto-load skills
echo.
echo Skill location: %CLAUDE_DEV_DIR%\%SKILL_NAME%\SKILL.md
goto end

:manual_install
echo.
echo Manual Installation Paths:
echo.
echo For Continue:
echo   Copy to: %CONTINUE_DIR%\%SKILL_NAME%\
echo.
echo For Claude Dev/Cline:
echo   Copy to: %CLAUDE_DEV_DIR%\%SKILL_NAME%\
echo.
echo Source directory: %SCRIPT_DIR%
goto end

:invalid_choice
echo Invalid choice. Exiting.
exit /b 1

:end
echo.
echo Installation complete! See README.md for usage instructions.
echo ==================================================
pause
