:: Purpose:       Installs a package
:: Requirements:  1. Run this script with Administrator rights
:: Author:        vocatus on reddit.com/r/sysadmin ( vocatus.gate@gmail.com ) // PGP key ID: 0x07d1490f82a211a2
:: History:       1.0.0 + Initial write


:::::::::::::::
:: VARIABLES :: -- Set these to your desired values
:::::::::::::::
:: Log location and name. Do not use trailing slashes (\)
set LOGPATH=%SystemDrive%\Logs
set LOGFILE=

:: Package to install. Do not use trailing slashes (\)
set LOCATION=
set BINARY_VERSION=
set FLAGS=ALLUSERS=1 /q /norestart

:: Create the log directory if it doesn't exist
if not exist %LOGPATH% mkdir %LOGPATH%


::::::::::
:: Prep :: -- Don't change anything in this section
::::::::::
@echo off
set SCRIPT_VERSION=1.0.0
set SCRIPT_UPDATED=2015-12-30
:: Get the date into ISO 8601 standard date format (yyyy-mm-dd) so we can use it
FOR /f %%a in ('WMIC OS GET LocalDateTime ^| find "."') DO set DTS=%%a
set CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%

:: This is useful if we start from a network share; converts CWD to a drive letter
pushd "%~dp0"
cls


::::::::::::::::::
:: INSTALLATION ::
::::::::::::::::::
:: Kill any running instances of Chrome before installing. This is to avoid the UAC popup for Google Update which occurs if you push the installation while Chrome is running in a user session
%SystemDrive%\windows\system32\taskkill.exe /F /IM chrome.exe /T 2>NUL
wmic process where name="chrome.exe" call terminate 2>NUL

:: Install package from local directory (if all files are in the same directory)
msiexec.exe /i "googlechromestandaloneenterprise64.msi" %FLAGS%

:: Import the reg file that disables Chrome auto-updater
regedit /s Tweak_Disable_Chrome_Auto-Update.reg

:: Delete auto-update tasks that Google installs
del /f /q %WinDir%\Tasks\GoogleUpdate*.job
del /f /q %WinDir%\System32\Tasks\GoogleUpdate*.job

:: Disable, then delete Google Update services
net stop gupdatem 2>NUL
net stop gupdate 2>NUL
sc delete gupdatem 2>NUL
sc delete gupdate 2>NUL

:: Remove Google Update directory
if exist "%ProgramFiles(x86)%\Google\Update" rmdir /s /q "%ProgramFiles(x86)%\Google\Update"
if exist "%ProgramFiles%\Google\Update" rmdir /s /q "%ProgramFiles%\Google\Update"

:: Remove desktop icon - Windows XP
if exist "%allusersprofile%\Desktop\Google Chrome.lnk" del "%allusersprofile%\Desktop\Google Chrome.lnk" /S

:: Remove desktop icon - Windows 7 and up
if exist "%public%\Desktop\Google Chrome.lnk" del "%public%\Desktop\Google Chrome.lnk"

:: Pop back to original directory. Isn't necessary in stand-alone runs of the script, but is needed when being called from another script
popd

:: Return exit code to SCCM/PDQ Deploy/etc
exit /B %EXIT_CODE%