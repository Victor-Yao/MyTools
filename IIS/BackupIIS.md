## Backup and Restore IIS Configurations

1. Launch **command prompt** as **Administrator** and navigate to **%windir%\system32\inetsrv\\**.
1. Run `appcmd add backup mybackup` to add a backup

    ![](/IIS/images/backupIIS1.png)

1. Run `appcmd list backup` to list backups. *Note, the backups start with **CFGHISTORY_** are automatically added by IIS server when you change something.*

    ![](/IIS/images/backupIIS2.png)

1. Run `appcmd restore backup mybackup` to restore the specific backup.

    ![](/IIS/images/backupIIS3.png)

1. The path of backup repository is **C:\inetpub\history**

    ![](/IIS/images/IISConfigHistory.png)