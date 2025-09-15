# Checklist of SmartScreen for Edge

1. Enable **SmartScreen Debug log**
    - Open Event viewer and access *Applications and services Logs → Microsoft → Windows → SmartScreen → Debug*. 
    - Click **Enable Log**.
    <br><img src="./images/smartscreen1.png" alt="smartscreen1.png" width="600">

2. Enable **edge tracing log**
    - Open Edge and access *edge://tracing* in address bar. 
    - Click *Reload*, choose *Manually select settings*. 
    <br><img src="./images/smartscreen2.png" alt="smartscreen2.png" width="600">
    - Check *SmartScreen* only and remove others in the *Record Categories*. Click **Record**
    <br><img src="./images/smartscreen3.png" alt="smartscreen3.png" width="600">

3. > Reproduce issue after completes *#1* and *#2*.

4. *Stop* and *Save* edge tracing.
    <br><img src="./images/smartscreen4.png" alt="smartscreen4.png" width="600">

5. Check *SmartScreen Debug log* and click *Save All Events As* if any items generated.
    <br><img src="./images/smartscreen5.png" alt="smartscreen5.png" width="600">

6. Access *Windows Security → Protection History*, expend and check items about blocked content. Take screenshots about SmartScreen related items.
    <br><img src="./images/smartscreen6.png" alt="smartscreen6.png" width="600">