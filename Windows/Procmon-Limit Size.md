# Capture procmon

1. Download [Procmon](https://docs.microsoft.com/zh-cn/sysinternals/downloads/procmon). <br>

1.  Launch Command Prompt with admin privileges and navigate to the Procmon folder.<br>

1. Run following command. You can change the RingBufferSize up to 4GB. <br>
`Procmon /AcceptEula /Minimized /Quiet /PagingFile /RingBufferSize 800`<br>
<img src="./Images/procmon4.png" alt="procmon4.png" width="500">
<br> *Procmon Usage* <br>
<img src="./Images/procmon5.png" alt="procmon5.png" width="500">

1. **Reproduce** your issue. <br>

1. Save "Logfile.PML" to local disk. <br>
<img src="./Images/procmon3.png" alt="procmon3.png" width="500">