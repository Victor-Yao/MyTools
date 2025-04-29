# How to capture Full User crash dump on Edge
1. Search and open **Environment Variables**. <br>
    <img src="./images/edgecrashdump1.png" alt="edgecrashdump1.png" width="500">

1. Add a **New User Variable**, <br>
`Variable name: ENABLE_HEAP_DUMPS`<br>
`Variable value: 1`<br>
    <img src="./images/edgecrashdump2.png" alt="edgecrashdump2.png" width="500">

1. Access `edge://settings/system` and **disable Startup boost**<br>
    <img src="./images/edgecrashdump3.png" alt="edgecrashdump3.png" width="500">
    <br>Tips: if this setting is greyed out and not allowed to change, please using command or powershell with Admin to run below cmdlet,
    <br>`REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f` 

1. Restart Edge compeletely and take settings effect. Please using taskmgr and ensure **all msedge.exe are closed**.<br>

1. Open Edge and **reproduce issue**. Then, check if there is any dump files generated at `%LOCALAPPDATA%\Microsoft\Edge\User Data\Crashpad\reports`.<br>