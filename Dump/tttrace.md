# Capture TTT Trace for IIS Worker Process
1. Download [TTD](/Dump/binary/TTD.zip). Unzip TTD_32bit.zip or TTD_64bit.zip based on your architecture.

1.  Create **c:\tttoutput** as the destination folder to save output logs.

1. Find out the **PID** of w3wp.exe

1. Run **command prompt** as Admin and navigate to **/TTD_64bit**(or /TTD_32bit)

1. Run below cmdlet
    ```bash
    tttracer -attach PID -bg -noUI -dumpFull -out c:\tttoutput
    ```

1. Reproduce issue

1. Run below cmdlet once it's done
    ```bash
    tttracer -stop all
    ```
    ![](/Dump/images/ttt1.png)

1. To check if TTT trace generated under c:\tttoutput.