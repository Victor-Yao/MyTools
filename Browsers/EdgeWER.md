# Collect Edge crash dump by WER
1. Create target folder, **C:\dumps**. <br>

1. Download [msedge-wer.reg](Browsers\Scripts\msedge-wer.reg) and **import** it to Registry. <br>
    <img src="./images/msedgewer1.png" alt="msedgewer1.png" width="250">

1. Double check if it's imported successuly as below screen. <br>
`HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\msedge.exe` <br>
    <img src="./images/msedgewer2.png" alt="msedgewer2.png" width="500">

1. Once issue happens again, check if any dump files generated in the **C:\dumps**.