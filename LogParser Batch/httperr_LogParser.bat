@echo off
set path=%1
set logParser="C:\Program Files (x86)\Log Parser 2.2\logparser.exe"
cd /d %path%
mkdir ret

echo "start processing"
for %%n in (httperr*.log) do %logParser% -i:HTTPERR  -q:on -o:csv "SELECT date,time,c-ip,c-port,s-ip,s-port,cs-version,cs-method,cs-uri,sc-status,s-siteid,s-reason,s-queuename FROM %%n" >> ".\ret\%%n.csv"
echo "done"

exit