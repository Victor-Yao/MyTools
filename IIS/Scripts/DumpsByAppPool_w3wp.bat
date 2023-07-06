:: Example: DumpByAppPool_w3wp.bat DefaultAppPool

@echo off
SETLOCAL EnableDelayedExpansion

:: name of the app pool
set appPool=%1

:: Output file
set outputFile=output.txt

:: use appcmd to list the worker processes
for /f "tokens=2" %%i in ('C:\Windows\System32\inetsrv\appcmd list wp ^| findstr /R /C:"%appPool%"') do (
  :: get the PID
  set wpid=%%i

  :: print the PID
  echo Worker process ID: !wpid! >> %outputFile%
  
  :: use procdump to monitor the process
  echo Starting procdump >> %outputFile%
  procdump -accepteula -ma -n 3 -s 5 !wpid! >> %outputFile%
)

if not defined wpid (
  echo No worker process found for application pool: %appPool% >> %outputFile%
)

ENDLOCAL
