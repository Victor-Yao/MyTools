# Enable IIS Failed Request Trace Rule for specific HTTP status code

1. Install FREB module, [reference](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/tracing/)

1. Click on wanted web site and open Freb in the features panel.

    ![](/IIS/images/Freb1.png)

1. Add a rule, configure the HTTP sta

    ![](/IIS/images/Freb2.png)
**Input the HTTP status code you want to capture**. It supports to input a range of http status code. I use 500 as example.

    ![](/IIS/images/Freb7.png)
    
    ![](/IIS/images/Freb4.png)

1. Go back to the site portal and enable the rule.

    ![](/IIS/images/Freb5.png)

1. Reproduce issue and collect logs

    ![](/IIS/images/Freb6.png)