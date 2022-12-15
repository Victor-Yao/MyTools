# Capture memory dump by procdump
1. Download [procdump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump)

1. Run **command prompt** as Administrator and navigate to procdump.

    ![](/Windows/Images/ManualDump1.png)

1. Find out the PID of w3wp.exe. Note, I use IIS worker process as example.

    Option 1. By IIS Manager

    ![](/Windows/Images/ManualDump2.png)
    ![](/Windows/Images/ManualDump4.png)

    Option 2. By Task Manager

    ![](/Windows/Images/ManualDump3.png)
1. Run `procdump -ma -accepteula -s 10 -n 3 PID`

    ![](/Windows/Images/ManualDump5.png)