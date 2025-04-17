# How to Collect Network Trace Log from Edge
1. Open **Edge** and launch  **DevTools** by press **F12**.<br>

1. Go to the **Network** tab, click on **clear cache** and check the **Disable Cache** option.<br>
    <img src="./images/edgehar1.png" alt="edgehar1.png" width="600">

1. Click the **Record** button to begin recording, then reproduce issue.<br>
    <img src="./images/edgehar2.png" alt="edgehar2.png" width="600">

1. Once the issue is reproduced and the request is complete, click the **Record** button to stop recording. Then, click the **Export HAR** button to save it.<br>
    <img src="./images/edgehar3.png" alt="edgehar3.png" width="600">

For more details, please refer to the [guidance](https://learn.microsoft.com/en-us/azure/azure-portal/capture-browser-trace#microsoft-edge) in the Edge documentation.