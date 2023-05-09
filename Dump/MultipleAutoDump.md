# Capture memory dump by procdump
1. Download [procdump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump)

1. Run **command prompt** as Administrator and navigate to procdump.

    ![](/Dump/images/ManualDump1.png)

1. Find out the PID of w3wp.exe. Note, I use IIS worker process as example.

    Option 1. By IIS Manager

    ![](/Dump/images/ManualDump2.png)
    
    ![](/Dump/images/ManualDump4.png)

    Option 2. By Task Manager

    ![](/Dump/images/ManualDump3.png)
1. Run in command prompt
    ```bash
    procdump -ma -accepteula -s 10 -n 3 PID
    ```
    ![](/Dump/images/ManualDump5.png)