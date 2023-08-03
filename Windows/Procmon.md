# Capture process IO trace by procmon

1. Download [Procmon](https://docs.microsoft.com/zh-cn/sysinternals/downloads/procmon)

1. Launch **procmon.exe** as adminstator and reset filter.

    ![](/Windows/Images/procmon1.png)

1. enable Boot Logging if it requires reboot server to reproduce issue.

    ![](/Windows/Images/procmon2.png)

1. Reproduce your issue

1. Save "Logfile.PML"

    ![](/Windows/Images/procmon3.png)
