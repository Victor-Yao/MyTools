@echo off
set path=%1
set logParser="C:\Program Files (x86)\Log Parser 2.2\logparser.exe"
cd /d %path%
mkdir ret

for %%n in (u_ex*.log) do %logParser% -i:iisw3c -q:off -o:csv "SELECT date,time,s-ip,cs-method,cs-uri-stem,cs-uri-query,s-port,cs-username,c-ip,cs(User-Agent), cs(Referer), sc-status,sc-substatus,sc-win32-status,time-taken FROM %%n" >> ".\ret\%%n.csv"

exit