# Things about Edge WebView2 
It provides some useful information about Edge WebView2.

## Find Installed WV2
1. Download [FindInstalledWV2.ps1](/Browsers/Scripts/FindInstalledWV2.ps1) or copy and paste code to a text file.
1. Run `.\FindInstalledWV2.ps1` and check output.
    ```
    ==========================================================================================
    [1] Microsoft Edge WebView2 Runtime
    Version         : 143.0.3650.96
    SystemComponent : 1
    Registry Path   : HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView
    ==========================================================================================
    ```

## Show WV2 in the installed program
1. Go to the Registry Path you got from **Find Installed WV2**. 
1. Set **SystemComponent** value as **0**.
1. Press `Win + R` and run `appwiz.cpl`.
1. Search `WebView2` and see result like below  
![webview21.png](/Browsers/images/webview21.png)
