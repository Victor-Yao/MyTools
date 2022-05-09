@echo off
set path=%1
set logParser="C:\Program Files (x86)\Log Parser 2.2\logparser.exe"
cd /d %path%
mkdir ret

echo "start processing"
for %%n in (u_ex*.log) do %logParser% -i:W3C -q:on -o:csv "SELECT date,time,c-ip,cs-username,s-ip,s-port,cs-method,cs-uri-stem,sc-status,sc-win32-status,sc-substatus,x-session,x-fullpath FROM %%n" >> ".\ret\%%n.csv"
echo "start done"

exit