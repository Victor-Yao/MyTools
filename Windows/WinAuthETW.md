# Event Trace for Windows Authentication

1. Download [Auth-Script.zip](/Windows/Scripts/Auth-Script.zip) and unzip it.

1. Launch Powershell as **Administrator** and nagigate to **Auth-Script** 

1. Run `.\start-auth.ps1`
![WinAuthETW1.png](/Windows/Images/WinAuthETW1.png)

1. **Reproduce Issue**

1. Run `.\stop-auth.ps1 `
![WinAuthETW2.png](/Windows/Images/WinAuthETW2.png)

1. Await script executing finishes, zip **authlogs** folder
![WinAuthETW3.png](/Windows/Images/WinAuthETW3.png)
