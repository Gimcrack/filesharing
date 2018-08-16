@echo off

REM    Copyright © 2009-2017 Quest Software Inc.
REM    All rights reserved.
REM
REM    File: agent_msi_provision.bat
REM
REM    This bat installs the K1000 Agent.
REM
REM    Params:
REM      %1 - required, server hostname on which installer sits
REM      %2 - required, server path to subdir of installer
REM      %3 - required, name of msi installer file
REM      %4 - optional, if present is K1000 server hostname, if not given, defaults to %1
REM

echo [MSGCODE: 000] Begin agent_msi_provision.bat processing.

REM If given 3rd param, use it, otherwise first param is our K1000 server
set KBOX_SERVER=%4
if "x%4x" == "xx" set KBOX_SERVER=%1

REM Change working dir to temp
cd %windir%\temp

REM Detect correct Program Files folder. Note this batch file may run in 32-bit env (SysWOW64/cmd.exe)
REM So %ProgramFiles% might be Program Files (x86), but we always want to check the regular Program Files.
set K64=no
if "%ProgramFiles(x86)%" == "" echo [MSGCODE: 032] Detected 32-bit platform.
if "%ProgramFiles(x86)%" == "" goto on32Bit
  set K64=yes
echo [MSGCODE: 064] Detected 64-bit platform.
:on32Bit

REM Just use the ProgramFiles 
REM set KProgramFiles=%ProgramFiles%

:: Set KProgramFiles to 32-bit dir on x64
SET KProgramFiles=%ProgramFiles(x86)%
IF NOT EXIST "%KProgramFiles%" SET KProgramFiles=%ProgramFiles%
:: Set KSystem32 to 32-bit dir on x64
SET KSystem32=%SystemRoot%\SysWOW64
IF NOT EXIST %KSystem32% SET KSystem32=%SystemRoot%\System32

REM Detect if 5.2 (or later) agent is already installed in Dell directory, if so, skip everything else
if exist "%KProgramFiles%\Dell\KACE\AMPTools.exe" goto skip
REM Detect if 5.2 (or later) agent is already installed in Quest directory, if so, skip everything else
if exist "%KProgramFiles%\Quest\KACE\AMPTools.exe" goto skip
REM Detect if 5.1 (or earlier) agent is already installed, if so, skip everything else
if exist "%KProgramFiles%\kace\kbox\kboxclient.exe" goto skip
REM Detect if older agent exists at the hard coded path -- we should NEVER get here
if exist "%ProgramFiles%\kace\kbox\kboxclient.exe" goto skip
goto install

:skip

echo [MSGCODE: 014] K1000 Agent is already installed.
goto end

:install

REM Run our msi installer
echo [MSGCODE: 015] Executing MSI installer.

set INSTALLER="\\%1\%2\agent_provisioning\windows_platform\%3"

REM Set install path to %temp% when the passed in server path is set to "local_install"
if "%2" == "local_install" set INSTALLER="%temp%\%3"

echo on

start /wait msiexec.exe /qn /l*v %temp%\ampmsi.log /i %INSTALLER% HOST=%KBOX_SERVER%

echo off
set retcode=%errorlevel%
echo Return code (MSI_ERROR_LEVEL) from MSI execution: [%retcode%] 
REM detect and print error related to trying to install 5.4 agent on Windows 2000
if "%retcode%"=="1" type %temp%\ampmsi.log | findstr ERROR_INSTALL_REJECTED | findstr /V \-\-

REM Detect when installation fails because PowerShell is not installed.
if "%retcode%"=="1603" type %temp%\ampmsi.log | findstr /I /c:"powershell to be installed"

REM Report if the agent is installed, so the K1000 provisioning system 
REM can record success or failure.
REM The server will be looking for this string, so don't change it, 
REM without changing it as well.
if exist "%KProgramFiles%\Quest\KACE\AMPTools.exe" echo [MSGCODE: 001] K1000 Agent is installed.
if not exist "%KProgramFiles%\Quest\KACE\AMPTools.exe" echo [MSGCODE: 002] K1000 Agent is not installed.

REM We need to wait 15 seconds for the AMP service to connect to the server 
REM (or fail to connect)  This ping command is a hack since windows doesn't 
REM have a sleep command.
ping 127.0.0.1 -n 15 -w 1000 > nul

REM Is AMP connected?
if exist "%ALLUSERSPROFILE%\Quest\KACE\AMP_CONNECTED" echo [MSGCODE: 091] AMP is connected.
if not exist "%ALLUSERSPROFILE%\Quest\KACE\AMP_CONNECTED" echo [MSGCODE: 092] AMP is not connected.

REM Dump our KUID
if exist "%ALLUSERSPROFILE%\Quest\KACE\kuid.txt" set /p KUID=<"%ALLUSERSPROFILE%\Quest\KACE\kuid.txt"
if not "%KUID%"=="" echo [MSGCODE: 093] KUID value detected.
if not "%KUID%"=="" echo [MSGCODE: 094] K1000 agent KUID: %KUID%
if "%KUID%"=="" echo [MSGCODE: 095] KUID value not written by MSI installer.

:end

echo [MSGCODE: 100] End agent_msi_provision.bat processing.
