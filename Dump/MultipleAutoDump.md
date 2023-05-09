# Capture memory dump by procdump
1. Download [procdump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump)

1. Run **command prompt** as Administrator and navigate to procdump.

    ![](/Dump/image/ManualDump1.png)

1. Find out the PID of w3wp.exe. Note, I use IIS worker process as example.

    Option 1. By IIS Manager

    ![](/Dump/image/ManualDump2.png)
    
    ![](/Dump/image/ManualDump4.png)

    Option 2. By Task Manager

    ![](/Dump/image/ManualDump3.png)
1. Run in command prompt
    ```bash
    procdump -ma -accepteula -s 10 -n 3 PID
    ```
    ![](/Dump/image/ManualDump5.png)