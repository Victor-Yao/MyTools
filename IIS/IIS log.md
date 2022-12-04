# IIS logs collecting steps
1. Launch **command prompt** as **Administrator** and run `netsh http flush logbuffer`. (*It flushes log entries cached in memory*) 
![](/IIS/images/IISLog5.png)
1. Open IIS Manager (*inetmgr.exe*). Click on **Sites** icon and save the **site ID** in the right panel.
![](/IIS/images/IISLog1.png)
1. Expend Sites icon, click on the wanted site and open **Logging** feature in the middle panel.
![](/IIS/images/IISLog2.png)
1. Save and navigate to the log file path by file exploer.
![](/IIS/images/IISLog3.png)
1. The log folder name is made up by **w3svc + siteID**. Select the specific folder base on site ID we saved.
![](/IIS/images/IISLog4.png)