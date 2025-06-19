# Capture Exception memory dump by procdump
1. Download [procdump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump)

1. Run **command prompt** as Administrator and navigate to procdump.

    ![](/Dump/images/ManualDump1.png)

1. Write up to a Full dumps if an exception's code/name/msg contains 'keywords':
    ```bash
    procdump -ma -n 1 -e 1 -f keywords w3wp.exe
    ```
    *Tip: if your app doesn't host on w3wp.exe, replace w3wp.exe of the host processs, e.g.dotnet.exe*