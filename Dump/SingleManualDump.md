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
1. Replace PID with your process ID and run it in the command prompt
    ```bash
    procdump -ma -accepteula PID
    ```