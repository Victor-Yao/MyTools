# Debug ARR rule and URL Rewrite rule by FREB

1. Install FREB module, [reference](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/tracing/)

1. Click on wanted web site and open Freb in the features panel.

    ![](/IIS/images/Freb1.png)

1. Add a rule

    ![](/IIS/images/Freb2.png)

    ![](/IIS/images/Freb8.png)

    ![](/IIS/images/Freb9.png)

    ![](/IIS/images/Freb10.png)

1. Go back to the site portal and enable the rule.

    ![](/IIS/images/Freb5.png)

1. Reproduce and collect logs

    ![](/IIS/images/Freb6.png)

This [MS Doc](https://learn.microsoft.com/en-us/iis/extensions/url-rewrite-module/using-failed-request-tracing-to-trace-rewrite-rules) shares an example about using FREB to trace Rewrite rule.  