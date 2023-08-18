@echo off

SET DIRECTORY="c:\reports"

IF NOT EXIST %DIRECTORY% (
    mkdir %DIRECTORY%
)

Reg query HKLM\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\SSL /s > %DIRECTORY%\%computername%_ssl1.txt
Reg query HKLM\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL /s > %DIRECTORY%\%computername%_ssl2.txt
Reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL /s > %DIRECTORY%\%computername%_ssl3.txt
Reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA\FIPSAlgorithmPolicy /s > %DIRECTORY%\%computername%_ssl4.txt

echo reports exported successfully!