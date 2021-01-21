'-------------------------------------------------------------------------------------------
' Performance Monitor Analysis Script.
'
' Purpose:
' ========
'
' Analyzes a performance monitor log to provide a generic high level analysis
'
'
' Author: Jeff Fanjoy, Microsoft Corp. (jfanjoy@microsoft.com)
' Last Modified: 20-March-2012
'
'     UPDATED 2/13/2009 By StevePar - Added OS detection and new registry path for Windows 7
'     UPDATED 3/02/2012 By StevePar - Added command line option to bypass input box
'     UPDATED 3/19/2012 By Sunilr   - Added OS detection for Windows 8
'     UPDATED 4/16/2012 By StevePar - Added Privileged time for CPU and summary for Process
'                                     Added Registry values to bypass input box and set top N processes
'                                     Fixed a conversion bug that prevented some warnings from displaying
'     UPDATED 8/12/2012 By AustinM  - Changed max cpu allowed for a process from 1000 to 64000, previously 
'                                     above 1000 was considered bogus
'     UPDATED 8/31/2013 bY StevePar - Added OS detection for Windows 8.1 (incremented to version 1.7)
'     UPDATED 10/08/2014 BY StevePar -  Added OS detection for Windows 10 Preview (incremented to version 1.8)
'
'
' Known Issues:
'
'   1.  Relog has known issues across a UNC and as a result sometimes will fail when
'       attempting to process a log across a UNC.  Copying the file to a local hard disk
'       will generally mitigate this.
'
'   2.  Relog will sometimes produce output that has numerous problems including samples
'       out of order and missing samples.  There is nothing that can be done about this
'       but fortunately it doesn't occur often.  This script is a garbage in garbage out
'       processing of relog data, so if the data is bad, the script won't know the
'       difference, although attempts are made to mitigate this as it processes.
'
'   3.  The script assumes that a log file was generated on an English localized OS.  Any
'       log file generated on a non-English localized OS should process correctly however
'       it will not process any of the counters since the script will be looking for the
'       counter names in English only.  Handling localized languages other than English is
'       being considered for the next major version of the script depending on demand for
'       such a feature.
'
'-------------------------------------------------------------------------------------------

' Disable all error reporting and just go on our merry way
On Error Resume Next

' Set script version details
Const pma_Name = "Performance Monitor Analyzer"
Const pma_Version = "v1.8"
Const pma_Author = "Jeff Fanjoy, Microsoft Corp. (jfanjoy@microsoft.com)"

' Default location for configuration options in the registry
Const pma_reg_defaults_key = "HKCU\Software\Microsoft\PMAVbs\"

' Set global constants
Const jf_WindowsFolder = 0
Const jf_SystemFolder = 1
Const jf_TemporaryFolder = 2

Const jf_PadStrLeft = 0
Const jf_PadStrRight = 1

Const fso_ForReading = 1
Const fso_ForWriting = 2
Const fso_ForAppending = 8

'---- DataTypeEnum Values ----
Const adDouble = 5
Const adVarChar = 200
Const adFldMayBeNull = &H00000040

' Set global variables
Dim strTempFolder          ' "TEMP" environment variable
Dim strOrgFolder           ' Path where Original Perfmon file is located
Dim strCounterFile         ' Path for Counter File to be created
Dim strOutputFile          ' Path for Output CSV file to be created
Dim strResultsFile         ' Path for Results file
Dim strResultsFileFB       ' Path for Results file if we cannot write strOrgFolder
Dim strResultsFileWrite    ' Path of results file that was written
Dim strOrgFile             ' Original Perfmon file to be processed
Dim strRegPath             ' Registry path to set Context Menu
Dim strRegPathCSV          ' Registry path to set CSV options
Dim strRegPathBLG          ' Registry path to set BLG options
Dim strLogFilename         ' Filename only of Perfmon log
Dim strServerName          ' Server name from Perfmon log
Dim strStartDate           ' Start Date/Time of log
Dim strEndDate             ' End Date/Time of log
Dim strUserStartDate       ' User inputted start date
Dim strUserEndDate         ' User inputted end date
Dim strDuration            ' Duration of log
Dim strSamples             ' Number of samples in log
Dim strSampleInterval      ' Interval between samples
Dim iDuration_Days         ' Duration in Days
Dim iDuration_Hour         ' Duration in Hours
Dim iDuration_Min          ' Duration in Minutes
Dim iDuration_Sec          ' Duration in Seconds
Dim strRebootTimes         ' Dates and Times when reboots occurred
Dim ArrHeaders             ' Store headers (counters)
Dim iNumCounters           ' Number counters collected
Dim bCScript               ' Whether or not we are using cscript engine
Dim ScriptStart            ' Time when script was executed
Dim ScriptEnd              ' Time when script completed
Dim RelogStart             ' Time when relog was executed
Dim RelogEnd               ' Time when relog completed
Dim ArrProcessors()        ' Array for storing processor details
Dim ArrDisks()             ' Array for storing disk details
Dim ArrNICs()              ' Array for storing NIC details
Dim ArrTS()                ' Array for TS sessions
Dim ArrServerWorkQueues()  ' Array for storing Server Work Queue details
Dim strConcerns            ' Potential concerns
Dim iTotalSamples          ' Total Samples taken from the Perfmon
Dim strProcessingTime      ' Time taken to process log
Dim strRelogTime           ' Time taken for Relog
Dim bSystemUpTime          ' Flags whether or not system up time counter was found
Dim iOutOfOrder            ' Flags if samples are out of order
Dim bShowTopN_Handle      ' Whether or not to show the TOP N: Handle Count
Dim bShowTopN_Thread      ' Whether or not to show the TOP N: Thread Count
Dim bShowTopN_PBytes      ' Whether or not to show the TOP N: Private Bytes
Dim bShowTopN_VBytes      ' Whether or not to show the TOP N: Virtual Bytes
Dim bShowTopN_WSet        ' Whether or not to show the TOP N: Working Set
Dim bShowTopN_CPU         ' Whether or not to show the TOP N: % Processor Time
Dim bShowTopN_IOData      ' Whether or not to show the TOP N: IO Data Bytes
Dim bShowMemory            ' Whether or not to show the Memory section
Dim bShowProcessor         ' Whether or not to show the Processor section
Dim bShowDisk              ' Whether or not to show the Physical Disk section
Dim bShowNIC               ' Whether or not to show the NIC section
Dim bIncludeTopN_Handle   ' Whether or not to Include the TOP N: Handle Count
Dim bIncludeTopN_Thread   ' Whether or not to Include the TOP N: Thread Count
Dim bIncludeTopN_PBytes   ' Whether or not to Include the TOP N: Private Bytes
Dim bIncludeTopN_VBytes   ' Whether or not to Include the TOP N: Virtual Bytes
Dim bIncludeTopN_WSet     ' Whether or not to Include the TOP N: Working Set
Dim bIncludeTopN_CPU      ' Whether or not to Include the TOP N: % Processor Time
Dim bIncludeTopN_IOData   ' Whether or not to Include the TOP N: IO Data Bytes
Dim bIncludeMemory         ' Whether or not to Include the Memory section
Dim bIncludeProcessor      ' Whether or not to Include the Processor section
Dim bIncludeDisk           ' Whether or not to Include the Physical Disk section
Dim bIncludeNIC            ' Whether or not to Include the NIC section
Dim bIncludeTS             ' Whether or not to Include the Terminal Server Sessions section
Dim b_CLIOverride          ' Was the number of instances overridden via command line?
Dim strInput               ' For capturing input from Inputbox
Dim ArrData()              ' Array for storing data imported
Dim ArrTempData()          ' Array for storing temporary calculated data
Dim dTmpData               ' Temp value holder for data samples
Dim bWriteLog              ' Whether or not to write log
Dim strLocale              ' Storage of local setting that was in use
Dim g_bShowInputBox        ' Boolean to allow non-promted operation
Dim g_numInstancesToProcess ' Number of instances to include in each summary output
Dim bIs64bit                 ' Boolean to track if machine is 64-bit so we can ignore x86 warnings


' Set global objects
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
Set objRSCounters = CreateObject("ADODB.Recordset")
Set objRSResults = CreateObject("ADODB.Recordset")
Set objRSProcess = CreateObject("ADODB.Recordset")


' Set processing variables
strTempFolder = objFSO.GetSpecialFolder(jf_TemporaryFolder)
strCounterFile = strTempFolder & "\pma_counters_" & objFSO.GetTempName()
strOutputFile = strTempFolder & "\pma_outputfile_"  & objFSO.GetTempName()
strResultsFileFB = strTempFolder & "\pma_resultsfile_"  & objFSO.GetTempName()
strLogFile = strTempFolder & "\pma_processlog_"  & objFSO.GetTempName()

' Determine where to register context menu
If ((Left(UCase(getOS()),4) = "WIN7") Or  (Left(UCase(getOS()),4) = "WIN8") Or  (Left(UCase(getOS()),5) = "WIN10")) Then
	strRegPath = "HKCR\Diagnostic.Perfmon.Document\shell\PMA"
Else
	strRegPath = "HKCR\PerfFile\shell\PMA"
End If

' Set default decision making variables to false
bSystemUpTime = False
bShowTopN_Handle = False
bShowTopN_Thread = False
bShowTopN_PBytes = False
bShowTopN_VBytes = False
bShowTopN_WSet = False
bShowTopN_CPU = False
bShowTopN_IOData = False
bShowMemory = False
bShowProcessor = False
bShowDisk = False
bShowNIC = False
bIncludeTopN_Handle = False
bIncludeTopN_Thread = False
bIncludeTopN_PBytes = False
bIncludeTopN_VBytes = False
bIncludeTopN_WSet = False
bIncludeTopN_CPU = False
bIncludeTopN_IOData = False
bIncludeMemory = False
bIncludeProcessor = False
bIncludeDisk = False
bIncludeNIC = False
bIncludeTS = False
bSamplesSkewed = False
bWriteLog = False
bIs64bit = False
b_CLIOverride = False

' Set counters to 0
iOutOfOrder = 0
iProcessorCount = 0
iServerWorkQueuesCount = 0
iDiskCount = 0
iNICCount = 0
iTSCount = 0

' Set default array dimensions
ReDim ArrProcessors(iProcessorCount)
ReDim ArrDisks(iDiskCount)
ReDim ArrNICs(iNICCount)
ReDim ArrTS(iTSCount)

' Display inputbox by default
g_bShowInputBox = True

' Set number of instances to include in each summary either via reg value or default to 10 if blank or zero
g_numInstancesToProcess = ReadReg(pma_reg_defaults_key & "NumSummaryInstances")
If(g_numInstancesToProcess = "") Then g_numInstancesToProcess = 10
If(CInt(g_numInstancesToProcess) = 0) Then g_numInstancesToProcess = 10


'--- MAIN SCRIPT CODE --------------------------------------------------------------------------'


' Check if we can write to our desired logfile location and if so open the log file
if IsWritable(strLogFile) then bWriteLog = True
if bWriteLog then Set objLogFile = objFSO.CreateTextFile(strLogFile, True)

' Check if our locale setting is other than English (United States)
' If it is different, then set locale to 1033 (en-us) during processing
strLocale = SetLocale()
ShowMsg "Regional Settings Detected: " & strLocale
if strLocale <> 1033 then 
   SetLocale(1033)
   ShowMsg "Regional Settings changed to 1033 - English (United States) - for processing."
end if

' Set what scripting engine we are using
bCScript = CheckScriptEngine

' Show header details in script processing window
Call ShowHeader

ShowMsg "Begin Processing..."

' Parse command line arguments
Call ParseCommandLine()

' If for some reason default options are not configured in registry set to "*"
strDefaultOptions = ReadReg(strRegPath & "\DefaultOptions")
if Trim(strDefaultOptions) = "" then strDefaultOptions = "*"

' Display runtime options and collect desired options from user
Call SetRunTimeOptions("Please select counter objects that you wish to include in the report.","Options Selection", strDefaultOptions)

' Capture start time of script
ScriptStart = Time()

' Create counter listing
Call GenerateCounterListing(strCounterFile)

' Execute relog to generate CSV file
result = ExecuteRelog(strTempFolder, strOrgFile, strCounterFile, strOutputFile)

' If result from relog is anything other than 0 relog didn't work correctly
' In this case we cannot continue
if result <> 0 then
   ShowMsgW "Relog Failed! (" & result & ") - Processing Terminated!"
   WScript.Quit
end if
strRelogTime = TimeDiff("s", RelogStart, RelogEnd)

' Parse the output CSV file created by relog
Call ParseOutputFile(strOutputFile)

' Calculate averages of data samples imported
Call CalculateAverages()

' Process counters that have numerous instances (e.g. disk, processor)
Call PopulateInstanceArrays()

' Update objRSProcess recordset with process specific values
Call UpdateProcessListing()

' Process through data to identify areas of concern
Call IdentifyConcerns()
   

' Capture end time of script
ScriptEnd = Time()

' Determine seconds difference between start and end of script processing
strProcessingTime = TimeDiff("s",ScriptStart,ScriptEnd)

ShowMsg "Processing Completed in " & strProcessingTime & " second(s)."

' Generate results to text file for review
Call WriteResults()

if strLocale <> 1033 then
   SetLocale(strLocale)
   ShowMsg "Regional Settings Restored: " & SetLocale()
end if

' If we were logging then close the log file
if bWriteLog then objLogFile.Close

' Show me the results file generated
objShell.Run "notepad " & strResultsFileWrite

'--- END MAIN SCRIPT CODE ----------------------------------------------------------------------'


' Destroy global objects
Set objFSO = Nothing
Set objShell = Nothing
Set objRSCounters = Nothing
Set objRSResults = Nothing
Set objRSProcess = Nothing


' Function to check that we are using cscript.exe as our scripting engine.
' This should always be true since registry is configured to use cscript however
' a user could change this if they wanted to.
Function CheckScriptEngine()

   strEngine = LCase(Mid(WScript.FullName, InstrRev(WScript.FullName, "\")+1))
   if strEngine = "cscript.exe" then 
      CheckScriptEngine = True
   else
      CheckScriptEngine = False
   end if

End Function


' Sub to display message to the scripting window but only if we are using cscript.
Sub ShowMsg(str)
   
   if bCScript then WScript.Echo Time() & "  " & str
   if bWriteLog then objLogFile.WriteLine(Time() & "   " & str)
   
End Sub


' Sub to display a message no matter what scripting host via a msgbox.
Sub ShowMsgW(str)
   
   msgbox str
   
End Sub


' Sub to provide details of the script executing.
Sub ShowHeader()

   if bCScript then
      WScript.Echo vbCrlf & pma_Name & " " & pma_Version
      WScript.Echo "Author: " & pma_Author & vbCrLf
   end if
   
End Sub


' Function to pad or reduce a string provided to the length provided.
' If padding then the directional identifies which side the padding goes.
'    jf_PadStrLeft = Data goes on the left side followed by spaces.
'    jf_PadStrRight = Data goes on the right side prefixed by spaces.
Function PadStr(ByVal str, strlen, PadDir)

   ' check if string length is longer than desired length
   ' if it is then we simply reduce to desired length
   if len(str) > strlen then 
      str = Left(str,strlen)
   else
      ' Check for padding direction and insert spaces
      Select Case PadDir
         Case jf_PadStrLeft: str = str & Space(strlen - len(str))
         Case jf_PadStrRight: str = Space(strlen - len(str)) & str
      End Select
   end if
   
   PadStr = str
   
End Function


' Function to pad or reduce a string provided to the length provided using
' provided character.
' If padding then the directional identifies which side the padding goes.
'    jf_PadStrLeft = Data goes on the left side followed by char.
'    jf_PadStrRight = Data goes on the right side prefixed by char.
Function PadStrWChar(ByVal str, strlen, PadDir, strChar)

   ' check if string length is longer than desired length
   ' if it is then we simply reduce to desired length
   if len(str) > strlen then 
      str = Left(str,strlen)
   else
      ' Check for padding direction and insert char
      Select Case PadDir
         Case jf_PadStrLeft: str = str & String(strlen - len(str),strChar)
         Case jf_PadStrRight: str = String(strlen - len(str),strChar) & str
      End Select
   end if
   
   PadStrWChar = str
   
End Function


' Sub for adding details to strConcerns.
' This will be displayed as "Areas To Investigate" in the results file.
Sub AddConcern(strCounter, strQualifier, strDesc())

   ' Add the counter to the string
   strConcerns = strConcerns & "   " & strCounter & vbCrLf
   ' Indent and add Min, Max and Avg values for the counter
   strConcerns = strConcerns & "        "
   strConcerns = strConcerns & "[Min: " & AddCommas(objRSResults("Min")) & strQualifier & ", Max: " & AddCommas(objRSResults("Max")) & strQualifier & ", Avg: " & AddCommas(objRSResults("Avg")) & strQualifier & "]" & vbCrLf
   ' Process description strings provided
   For i = 0 to UBound(strDesc)
      if strDesc(i) <> "" then strConcerns = strConcerns & PadStr("", 13, jf_PadStrLeft) & "- " & strDesc(i) & vbCrLf
   Next
   strConcerns = strConcerns & vbCrLf
   
End Sub


' Sub to set the runtime options or define default runtime options
Sub SetRuntimeOptions(strPrefix, strTitle, strDefault)

   If(g_bShowInputBox) Then
	   ' Generate message to display in Inputbox
	   strInputMsg = strPrefix & vbCrLf & VbCrLf
	   strInputMsg = strInputMsg & "M = Memory totals" & vbCrLf
	   strInputMsg = strInputMsg & "P = Processor totals" & vbCrLf
	   strInputMsg = strInputMsg & "D = Physical Disk totals" & vbCrLf
	   strInputMsg = strInputMsg & "N = Network Interface totals" & vbCrLf
	   strInputMsg = strInputMsg & "T = Terminal Server Sessions totals" & vbCrLf & vbCrLf
	   strInputMsg = strInputMsg & "H = TOP " & g_numInstancesToProcess & " Processes: Handle Count" & vbCrLf
	   strInputMsg = strInputMsg & "S = TOP " & g_numInstancesToProcess & " Processes: Thread Count" & vbCrLf
	   strInputMsg = strInputMsg & "B = TOP " & g_numInstancesToProcess & " Processes: Private Bytes" & vbCrLf
	   strInputMsg = strInputMsg & "V = TOP " & g_numInstancesToProcess & " Processes: Virtual Bytes" & vbCrLf
	   strInputMsg = strInputMsg & "W = TOP " & g_numInstancesToProcess & " Processes: Working Set" & vbCrLf
	   strInputMsg = strInputMsg & "C = TOP " & g_numInstancesToProcess & " Processes: % Processor Time" & vbCrLf
	   strInputMsg = strInputMsg & "I = TOP " & g_numInstancesToProcess & " Processes: IO Data Bytes/sec" & vbCrLf & vbCrLf
	   strInputMsg = strInputMsg & "* = Include Everything" & vbCrLf & vbCrLf
	   strInputMsg = strInputMsg & "Examples:" & vbCrLf
	   strInputMsg = strInputMsg & "   MPDN = Totals Summary only." & vbCrLf
	   strInputMsg = strInputMsg & "   MPDNTHSBVWCI = Everything." & vbCrLf
	   strInputMsg = strInputMsg & "   HSBVWCI = All Top 'N' Processes only." & vbCrLf
	   strInputMsg = strInputMsg & "   MPDH = Memory, Processor, Disk and Handles." & vbCrLf
	   
	   
	   ' Display inputbox to users and collect input
	   strInput = InputBox(strInputMsg, strTitle, strDefault)
	   
	   ' Uppercase the input for processing
	   strInput = UCase(strInput)
	   
	   ' If blank input was provided or cancel button was clicked then abort script
	   if Trim(strInput) = "" then
	      msgbox "No counters selected, aborting execution."
	      WScript.Quit
	   end if
	
	   ' Check for summary options
	   if instr(strInput, "M") > 0 then bIncludeMemory = True
	   if instr(strInput, "P") > 0 then bIncludeProcessor = True
	   if instr(strInput, "D") > 0 then bIncludeDisk = True
	   if instr(strInput, "N") > 0 then bIncludeNIC = True
	   if instr(strInput, "T") > 0 then bIncludeTS = True
	   
	   ' Check for Top 10 Processes options
	   if instr(strInput, "H") > 0 then bIncludeTopN_Handle = True
	   if instr(strInput, "S") > 0 then bIncludeTopN_Thread = True
	   if instr(strInput, "B") > 0 then bIncludeTopN_PBytes = True
	   if instr(strInput, "V") > 0 then bIncludeTopN_VBytes = True
	   if instr(strInput, "W") > 0 then bIncludeTopN_WSet = True
	   if instr(strInput, "C") > 0 then bIncludeTopN_CPU = True
	   if instr(strInput, "I") > 0 then bIncludeTopN_IOData = True
   
   Else
   	'don't show input box, just turn on everything
   	strInput = "*"
   
   End If
   
   ' Check if "*" was submitted, if so turn on everything
   if instr(strInput, "*") > 0 then
      bIncludeMemory = True
      bIncludeProcessor = True
      bIncludeDisk = True
      bIncludeNIC = True
      bIncludeTS = True
      bIncludeTopN_Handle = True
      bIncludeTopN_Thread = True
      bIncludeTopN_PBytes = True
      bIncludeTopN_VBytes = True
      bIncludeTopN_WSet = True
      bIncludeTopN_CPU = True
      bIncludeTopN_IOData = True
   end if
   
End Sub


' Sub to parse command line arguments provided.
Sub ParseCommandLine()

   ' Check if no arguments were passed
   ' If no arguments then we are likely running script for the first time
   ' otherwise process the filename provided as a command line parameter
   if WScript.Arguments.Count = 0 Then
      'Prompt for elevation to write to the registry
      ElevateThisScript()
      ' Set default processing options in registry.  Read the value if it
      ' exists and use that as the default selection currently.
      strDefaultOptions = ReadReg(strRegPath & "\DefaultOptions")
      if Trim(strDefaultOptions) = "" then strDefaultOptions = "*"
      Call SetRuntimeOptions("Please select counter objects that you wish to include as defaults" & _
                              " in reports generated." & vbCrLf & vbCrLf & "These options will be" & _
                              " the default options selected when prompted each time a Performance" & _
                              " Monitor log is processed however you will be able to change these" & _
                              " options at processing time for the individual log.", _
                              "Default Options Selection", strDefaultOptions)
      
      ' Set default options value to what the user selected
      strDefaultOptions = strInput

      ' Set command line that we will be using for context menu
      ' cmd.exe /c START /BELOWNORMAL is used so the script and all sub
      ' processes will run in below normal priority in order to make sure
      ' we do not consume all the processing resources of the machine
      strRegcommandLine = "cmd.exe /c START /BELOWNORMAL cscript.exe """ & WScript.ScriptFullName & """ ""%1"""

      ' Check what the current default handler for CSV files is
      ' If this is empty then we will set the default handler to PerfFile
      ' otherwise we will add a PMA shell component under the current
      ' default handler
      strCSVReg = ReadReg("HKCR\.csv\")
      if strCSVReg = "" then
         Call WriteReg("HKCR\.csv\", "PerfFile", "REG_SZ")
      else
         Call WriteReg("HKCR\" & strCSVReg & "\shell\PMA\", "Open With " & pma_Name, "REG_SZ")
         Call WriteReg("HKCR\" & strCSVReg & "\shell\PMA" & "\command\", strRegCommandLine, "REG_SZ")
      end if
      
      ' Create the context menu definitions under the PerfFile handler
      Call WriteReg(strRegPath & "\", "Open With " & pma_Name, "REG_SZ")
      Call WriteReg(strRegPath & "\command\", strRegCommandLine, "REG_SZ")
      
      ' Set the default options value
      Call WriteReg(strRegPath & "\DefaultOptions", strDefaultOptions, "REG_SZ")

      ' Prepare output message to advise user that script was installed successfully
      strHelp = pma_Name & " " & pma_Version & vbCrLf & "Written By: " & pma_Author & vbCrLf & vbCrLf
      strHelp = strHelp & "----------------------------------------------------------------------------------------------------------" & vbCrLf & vbCrLf
      strHelp = strHelp & "Context menu addition for *.blg and *.csv files installed." & vbCrLf & vbCrLf
      strHelp = strHelp & "Usage: Right-click on a *.blg/*.csv file and select 'Open with " & pma_Name & "'" & vbCrLf
      strHelp = strHelp & vbCrLf
      strHelp = strHelp & "*** NOTE: Only log files generated on English Localized OS are supported!!! ***" & vbCrLf

      ' Show message to user that script was installed
      ShowMsgW strHelp
      
      ' Terminate processing
      WScript.Quit
      
   Else
	
	    ' if -q is passed at the end of the command line don't display the InputBox
		set args = Wscript.arguments
		For x = 0 to args.count - 1
			If(ucase(args(x)) = "-Q") Then
				g_bShowInputBox = False
				b_CLIOverride = True
			End If
			
			' Set the number of instances to summarize if -T was passed followed by a number
			If(UCase(args(x)) = "-T") Then
				If(IsNumeric(args(x+1))) Then 
					g_numInstancesToProcess = CInt(args(x+1))
					b_CLIOverride = True
				End If
			End If
			
			' Set Original File to be processed
			If(Right(Ucase(args(x)),4) = ".BLG") Then strOrgFile = args(x)
			
		Next
		
		' Check for NoPrompt registry value
		If (ReadReg(pma_reg_defaults_key & "NoPrompt") = "1") Then
			g_bShowInputBox = False
		End If
		
		'Check if we should prompt for the number of instances to summarize
		'Unless -T was passed (command line always wins)
		If((ReadReg(pma_reg_defaults_key & "PromptForNumInstances") = "1") And (b_CLIOverride = False)) Then
			g_numInstancesToProcess = InputBox("Enter number of instances to process:", "", g_numInstancesToProcess)
			If(Not(IsNumeric(g_numInstancesToProcess))) Then g_numInstancesToProcess = 10
		End If
	            
	      ' Use FileSystemObject to identify parent folder of file we're processing
	      strOrgFolder = objFSO.GetParentFolderName(objFSO.GetAbsolutePathName(strOrgFile))
	      
	      ' Set results file to <parentfolder>\<perfmonlogwithextensionstripped>-PMA-Summary.TXT
	      strResultsFile = strOrgFolder & "\" & Left(objFSO.GetFileName(strOrgFile), Instr(objFSO.GetFileName(strOrgFile), ".")-1) & "-PMA-Summary.TXT"
	      ShowMsg "Performance log: " & strOrgFile

   End If

End Sub


' Sub to build the recordsets that will be used in script processing.
'
' objRSCounters = Recordset of all the counters to be included when
'                 we execute relog.
' objRSResults  = Recordset that will hold the first, last, min, max
'                 average and samples values for each counter.
' objRSProcess  = Recordset that will hold the values for each
'                 individual \Process(*) counter collected.
Sub Build_RecordSets()

   With objRSCounters
      .Fields.Append "Counter", advarchar, 255, adFldMayBeNull

      .Open
      
      ' Memory counters
      if bIncludeMemory then
         .AddNew "Counter", "\Memory\Available MBytes"
         .AddNew "Counter", "\Memory\Pool Paged Bytes"
         .AddNew "Counter", "\Memory\Pool NonPaged Bytes"
         .AddNew "Counter", "\Memory\Free System Page Table Entries"
         .AddNew "Counter", "\Memory\Cache Bytes"
         .AddNew "Counter", "\Memory\Committed Bytes"
         .AddNew "Counter", "\Memory\Commit Limit"
         .AddNew "Counter", "\Memory\% Committed Bytes In Use"
         .AddNew "Counter", "\Memory\Pages/sec"
         if not bIncludeTopN_Handle then .AddNew "Counter", "\Process(_Total)\Handle Count"
         if not bIncludeTopN_Thread then .AddNew "Counter", "\Process(_Total)\Thread Count"
         if not bIncludeTopN_PBytes then .AddNew "Counter", "\Process(_Total)\Private Bytes"
         if not bIncludeTopN_VBytes then .AddNew "Counter", "\Process(_Total)\Virtual Bytes"
         if not bIncludeTopN_WSet then .AddNew "Counter", "\Process(_Total)\Working Set"
      end if
      if bIncludeTopN_Handle then .AddNew "Counter", "\Process(*)\Handle Count"
      if bIncludeTopN_Thread then .AddNew "Counter", "\Process(*)\Thread Count"
      if bIncludeTopN_PBytes then .AddNew "Counter", "\Process(*)\Private Bytes"
      if bIncludeTopN_VBytes then .AddNew "Counter", "\Process(*)\Virtual Bytes"
      if bIncludeTopN_WSet then .AddNew "Counter", "\Process(*)\Working Set"
      
      ' Processor counters
      if bIncludeProcessor then
         .AddNew "Counter", "\System\Processor Queue Length"
         .AddNew "Counter", "\Processor(*)\% Processor Time"
         .AddNew "Counter", "\Processor(*)\% User Time"
         .AddNew "Counter", "\Processor(*)\% Privileged Time"
         .AddNew "Counter", "\Processor(*)\% DPC Time"
         .AddNew "Counter", "\Processor(*)\% Interrupt Time"
      end If
      If bIncludeTopN_CPU Then
       .AddNew "Counter", "\Process(*)\% Processor Time"
       .AddNew "Counter", "\Process(*)\% Privileged Time"
      End If
      
      ' Physical Disk counters
      if bIncludeDisk then
         .AddNew "Counter", "\PhysicalDisk(*)\% Idle Time"
         .AddNew "Counter", "\PhysicalDisk(*)\Avg. Disk sec/Transfer"
         .AddNew "Counter", "\PhysicalDisk(*)\Disk Bytes/sec"
         .AddNew "Counter", "\PhysicalDisk(*)\Avg. Disk Queue Length"
         .AddNew "Counter", "\PhysicalDisk(*)\Split IO/Sec"
         .AddNew "Counter", "\PhysicalDisk(*)\Disk Transfers/sec"
      end if
      If bIncludeTopN_IOData then .AddNew "Counter", "\Process(*)\IO Data Bytes/sec"
      
      ' Network Interface counters
      if bIncludeNIC then
         .AddNew "Counter", "\Network Interface(*)\Bytes Total/sec"
         .AddNew "Counter", "\Network Interface(*)\Current Bandwidth"
         .AddNew "Counter", "\Network Interface(*)\Output Queue Length"
         .AddNew "Counter", "\Network Interface(*)\Packets/sec"
         .AddNew "Counter", "\Network Interface(*)\Packets Received Discarded"
         .AddNew "Counter", "\Network Interface(*)\Packets Received Errors"
      end if
      
      ' Terminal Services Counters
      if bIncludeTS then
         .AddNew "Counter", "\Terminal Services Session(*)\% Processor Time"
         .AddNew "Counter", "\Terminal Services Session(*)\Handle Count"
         .AddNew "Counter", "\Terminal Services Session(*)\Thread Count"
         .AddNew "Counter", "\Terminal Services Session(*)\Private Bytes"
         .AddNew "Counter", "\Terminal Services Session(*)\Virtual Bytes"
         .AddNew "Counter", "\Terminal Services Session(*)\Working Set"
      end if
      
      'Server Work Queues
      .AddNew "Counter", "\Server Work Queues(*)\Active Threads"
      .AddNew "Counter", "\Server Work Queues(*)\Available Work Items"
      .AddNew "Counter", "\Server Work Queues(*)\Queue Length"
      .AddNew "Counter", "\Server Work Queues(*)\Work Item Shortages"
      .AddNew "Counter", "\Server Work Queues(*)\Current Clients"
      
      ' System uptime details (THIS MUST BE THE LAST COUNTER ADDED FOR UPTIME/REBOOT ACCOUNTING TO WORK!)
      .AddNew "Counter", "\System\System Up Time"
      
     
      .Update

   End With
   
   With objRSResults
      .Fields.Append "Counter", advarchar, 255, adFldMayBeNull
      .Fields.Append "Category", advarchar, 255, adFldMayBeNull
      .Fields.Append "Description", advarchar, 255, adFldMayBeNull
      .Fields.Append "Samples", adDouble
      .Fields.Append "First", adDouble
      .Fields.Append "Last", adDouble
      .Fields.Append "Min", adDouble
      .Fields.Append "Max", adDouble
      .Fields.Append "Avg", adDouble
      
      .Open
      
   End WIth
   
   With objRSProcess
      .Fields.Append "Process", advarchar, 255, adFldMayBeNull
      .Fields.Append "Category", advarchar, 255, adFldMayBeNull
      .Fields.Append "Description", advarchar, 255, adFldMayBeNull
      .Fields.Append "Handle_First", adDouble
      .Fields.Append "Handle_Last", adDouble
      .Fields.Append "Handle_Min", adDouble
      .Fields.Append "Handle_Max", adDouble
      .Fields.Append "Handle_Avg", adDouble
      .Fields.Append "Thread_First", adDouble
      .Fields.Append "Thread_Last", adDouble
      .Fields.Append "Thread_Min", adDouble
      .Fields.Append "Thread_Max", adDouble
      .Fields.Append "Thread_Avg", adDouble
      .Fields.Append "PrivateBytes_First", adDouble
      .Fields.Append "PrivateBytes_Last", adDouble
      .Fields.Append "PrivateBytes_Min", adDouble
      .Fields.Append "PrivateBytes_Max", adDouble
      .Fields.Append "PrivateBytes_Avg", adDouble
      .Fields.Append "VirtualBytes_First", adDouble
      .Fields.Append "VirtualBytes_Last", adDouble
      .Fields.Append "VirtualBytes_Min", adDouble
      .Fields.Append "VirtualBytes_Max", adDouble
      .Fields.Append "VirtualBytes_Avg", adDouble
      .Fields.Append "WorkingSet_First", adDouble
      .Fields.Append "WorkingSet_Last", adDouble
      .Fields.Append "WorkingSet_Min", adDouble
      .Fields.Append "WorkingSet_Max", adDouble
      .Fields.Append "WorkingSet_Avg", adDouble
      .Fields.Append "ProcessorUsage_First", adDouble
      .Fields.Append "ProcessorUsage_Last", adDouble
      .Fields.Append "ProcessorUsage_Min", adDouble
      .Fields.Append "ProcessorUsage_Max", adDouble
      .Fields.Append "ProcessorUsage_Avg", adDouble
      .Fields.Append "PrivilegedProcessorUsage_First", adDouble
      .Fields.Append "PrivilegedProcessorUsage_Last", adDouble
      .Fields.Append "PrivilegedProcessorUsage_Min", adDouble
      .Fields.Append "PrivilegedProcessorUsage_Max", adDouble
      .Fields.Append "PrivilegedProcessorUsage_Avg", adDouble
      .Fields.Append "IODataBytes_First", adDouble
      .Fields.Append "IODataBytes_Last", adDouble
      .Fields.Append "IODataBytes_Min", adDouble
      .Fields.Append "IODataBytes_Max", adDouble
      .Fields.Append "IODataBytes_Avg", adDouble
      
      .Open
      
   End With
   
End Sub

' Sub to generate the counter listing file that relog will use from
' the contents of the objRSCounters recordset.
Sub GenerateCounterListing(strPath)

   ShowMsg "Creating counter listing..."
   
   ' Build the recordsets
   Call Build_Recordsets()
   
   ' Create text file that will contain counters to pass to relog
   Set objCounterFile = objFSO.CreateTextFile(strPath)
   
   ' Move to beginning of recordset to start processing
   if not objRSCounters.BOF then objRSCounters.MoveFirst
   
   ShowMsg "Generating counter file: " & strPath
   
   ' Enumerate through each record and output the counter
   While not objRSCounters.EOF
      objCounterFile.Writeline(objRSCounters("Counter"))
      ShowMsg "   " & objRSCounters("Counter")
      objRSCounters.MoveNext
   Wend
   
   objCounterFile.Close
   
   ShowMsg "Completed counter listing."
   
   ' Destroy our connection to the text file as it is no longer required
   Set objCounterFile = Nothing

End Sub


' Function to execute relog to process the perfmon counter log and return
' only the counters required to be analyzed.  This data will be outputted
' to the user temporary folder and stored in CSV format.
Function ExecuteRelog(strTmpPath, strOrgFile, strCounterFile, strOutputFile)
   
   ' Advise user that we are executing relog and that this can take some time
   ' Relog typically takes only seconds or a couple minutes but in rare cases
   ' has taken a couple hours to process a log
   ShowMsg "Regenerating Perfmon data to: " & strOutputFile & "..."
   ShowMsg "   Waiting on relog to complete - This may take a few minutes..."

   ' Define command line that we will be executing
   strRun = "relog """ & strOrgFile & """ -cf """ & strCounterFile & """ -o """ & strOutputFile & """ -f CSV -y"
   
   ' Capture time when relog was started
   RelogStart = Time()
   
   ' Run relog and capture return code
   ExecuteRelog = objShell.Run(strRun, 6, True)
   
   ' Capture time when relog was completed
   RelogEnd = Time()
   
   ShowMsg "Completed regenerating Performance Monitor data."

End Function


' Read a registry value.  Returns blank if value does not exist or could
' not be read.
Function ReadReg(ByVal strRegValue)

   ' Disable error processing so we don't get script termination if
   ' the value doesn't exist
   On Error Resume Next

   ' Read the registry value
   ReadReg = objShell.RegRead(strRegValue)
   
   ' If an error is returned then set function to return blank value
   if Err.Number <> 0 then ReadReg = ""
   Err.Clear

End Function


' Write a registry key or value.  A key is written if the strRegData ends
' in "\", otherwise a value of type specified in strDataType is written.
Function WriteReg(ByVal strRegKey, strRegData, strDataType)

   ' Disable error processing so we don't get script termination if
   ' the key or value doesn't write properly (e.g. access denied)
   On Error Resume Next

   ' Since supplying a data type is optional we won't pass it if
   ' we don't require it otherwise we pass all the arguments
   if strDataType = "" then
      objShell.RegWrite strRegKey, strRegData
   else
      objShell.RegWrite strRegKey, strRegData, strDataType
   end if
   
   ' If an error is returned then set the function to return the
   ' error code
   WriteReg = Err.Number
   Err.Clear

End Function


' Function to strip any leading and trailing quotation marks as all
' data returned via relog is wrapped in quotes.
Function StripQuotes(str)

   if instr(str,"""") = 1 then str = Right(str,len(str)-1)
   if instr(str,"""") = len(str) then str = Left(str,Len(str)-1)
   
   StripQuotes = str
   
End Function


' Function to extract the log file name from the full path provided
Function GetLogFilename(ByVal str)

   if instr(str,"\") > 0 then
      iPos = 1
      While instr(iPos,str,"\") > 0
         iPos = instr(iPos,str,"\") + 1
      WEnd
      str = Right(str,len(str) - (iPos - 1))
   end if
   
   GetLogFilename = str
   
End Function


' Function to extract the server name from a counter that is passed
Function GetServer(ByVal str)

   str = StripQuotes(str)
   str = Right(str,len(str)-2)
   str = Left(str,instr(str,"\")-1)
   
   GetServer = str
   
End Function


' Function to strip the server name from a counter that is passed
Function StripServer(ByVal str)

   str = StripQuotes(str)
   str = Right(str,len(str)-(instr(3,str,"\")-1))
   
   StripServer = str
   
End Function


' Sub to bubblesort an array that is passed
Sub SortArray(Arr)

   For i = UBound(Arr) - 1 TO 0 Step -1
      For j = 0 to i
         if Arr(j) > Arr(j+1) then
            temp = Arr(j+1)
            Arr(j+1) = Arr(j)
            Arr(j) = temp
         end if
      Next
   Next
   
End Sub


' Function to provide the time difference in hours, minutes or seconds
' between two times.
Function TimeDiff(ByVal Interval, ByVal Time1, ByVal Time2)
   
   ' With perfmons all time values include milliseconds but these are
   ' not valid in Date/Time functions so they must be stripped
   if instr(Time1,".") > 0 then Time1 = Left(Time1,instr(Time1,".")-1)
   if instr(Time2,".") > 0 then Time2 = Left(Time2,instr(Time2,".")-1)

   ' Convert the Time values provided into vbLongTime format
   Time1 = FormatDateTime(Time1, vbLongTime)
   Time2 = FormatDateTime(Time2, vbLongTime)
   
   ' Extract hours in time values
   HourTime1 = Hour(Time1)
   HourTime2 = Hour(Time2)
   
   ' Extract minutes in time values
   MinuteTime1 = Minute(Time1)
   MinuteTime2 = Minute(Time2)
   
   ' Extract seconds in time values
   SecondTime1 = Second(Time1)
   SecondTime2 = Second(Time2)
   
   ' Add everything up to provide the time values in seconds
   Time1InSeconds = SecondTime1 + (MinuteTime1 * 60) + (HourTime1 * 3600)
   Time2InSeconds = SecondTime2 + (MinuteTime2 * 60) + (HourTime2 * 3600)
   
   ' Subtract first time from second to get the difference in seconds
   TimeDifference = Time2InSeconds - Time1InSeconds
   
   ' If Time Difference is negative then we must have crossed a day
   ' By adding 86400 seconds we can make up that difference
   if TimeDifference < 0 then TimeDifference = TimeDifference + 86400
   
   ' Convert values to hours or minutes based on function call
   Select Case Interval
      Case "h"
         TimeDifference = TimeDifference / 3600
      Case "m"
         TimeDifference = TimeDifference / 60
   End Select
   
   ' Set results
   TimeDiff = TimeDifference
   
End Function


' Function to find a record based on the value of the find string
Function FindRecord(objRS, strFind)
   
   ' Move to first position of the record
   if not objRS.BOF then objRS.MoveFirst
   
   ' Execute the find for the value of the find string
   objRS.Find strFind
   
   ' If we reach the end of the recordset then we didn't find the record
   ' Otherwise return that it was found
   if objRS.EOF then 
      FindRecord = False
   else
      FindRecord = True
   end if
   
End Function


' Function to find a counter in the array provided based on the value of the 
' find string.
Function FindCounter(Arr, strFind)
   
   ' Set default to false
   bFoundCtr = False
   
   ' Enumerate the array for the value of the find string
   For i = 1 to UBound(Arr)
      ' If we find the string then set our value to true
      if Arr(i) = strFind then bFoundCtr = True
   Next
   
   ' Return results
   FindCounter = bFoundCtr
   
End Function


' Function to convert the System Up Time value into a string following the format
' of d h m s.
Function UpTime2Str(iUptime)
  
   ' Convert value provided to integer
   iUptime = Int(iUptime)
   
   ' Determine days, hours, minutes and seconds
   iUT_Day = Int(iUptime / 86400)
   iUT_Hour = Int((iUptime - (iUT_Day * 86400)) / 3600)
   iUT_Min = Int((iUptime - ((iUT_Day * 86400) + (iUT_Hour * 3600))) / 60)
   iUT_Sec = Int(iUptime - ((iUT_Day * 86400) + (iUT_Hour * 3600) + (iUT_Min * 60)))
   
   ' Return results string
   UpTime2Str = iUT_Day & "d " & iUT_Hour & "h " & iUT_Min & "m " & iUT_Sec & "s"
   
End Function


' Sub to populate instance arrays for counters that have multiple instances
Sub PopulateInstanceArrays()

   ShowMsg "Populating instance arrays..."
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   strDiskCounter = vbNullString
   strProcessorCounter = vbNullString
   strNICCompleted = vbNullString
   strTSCounter = vbNullString
   strServerWorkQueuesCounter = vbNullString
   
   While not objRSResults.EOF
      
      ' Check if counter is a disk counter
      if instr(objRSResults("Counter"), "\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"),"\PhysicalDisk(_Total)") = 0 then
         ' If we haven't already identified a disk counter to process then we do it now
         if strDiskCounter = vbNullString then strDiskCounter = Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\"))
         
         ' Check if our disk counter is the same as our counter flagged to process
         if Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\")) = strDiskCounter then
            ' Parse out the instance identifier
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)

            ' Update array
            ReDim Preserve ArrDisks(iDiskCount)
            ArrDisks(iDiskCount) = strTmp
            iDiskCount = iDiskCount + 1
         end if
      end if
      
      ' Check if counter is a Processor counter
      if instr(objRSResults("Counter"), "\Processor(") > 0 AND instr(objRSResults("Counter"),"\Processor(_Total)") = 0 then
         ' If we haven't already identified a Processor counter to process then we do it now
         if strProcessorCounter = vbNullString then strProcessorCounter = Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\"))
         
         ' Check if our Processor counter is the same as our counter flagged to process
         if Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\")) = strProcessorCounter then
            ' Parse out the instance identifier
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)

            ' Update array
            ReDim Preserve ArrProcessors(iProcessorCount)
            ArrProcessors(iProcessorCount) = strTmp
            iProcessorCount = iProcessorCount + 1
         end If
      end If
      
      ' Check if counter is a Server Work Queues counter
      if instr(objRSResults("Counter"), "\Server Work Queues(") > 0 then
         ' If we haven't already identified a Server Work Queues counter to process then we do it now
         if strServerWorkQueuesCounter = vbNullString then strServerWorkQueuesCounter = Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\"))
         ' Check if our Server Work Queues counter is the same as our counter flagged to process
         if Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\")) = strServerWorkQueuesCounter then
            ' Parse out the instance identifier
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)

            ' Update array
            ReDim Preserve ArrServerWorkQueues(iServerWorkQueuesCount)
            ArrServerWorkQueues(iServerWorkQueuesCount) = strTmp
            iServerWorkQueuesCount = iServerWorkQueuesCount + 1
         End If
      end If
      
      ' Check if counter is a NIC counter
      if instr(objRSResults("Counter"), "\Network Interface(") > 0 then
         ' If we haven't already identified a NIC counter to process then we do it now
         if strNICCounter = vbNullString then strNICCounter = Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\"))
         
         ' Check if our NIC counter is the same as our counter flagged to process
         if Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\")) = strNICCounter then
            ' Parse out the instance identifier
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)

            ' Update array
            ReDim Preserve ArrNICs(iNICCount)
            ArrNICs(iNICCount) = strTmp
            iNICCount = iNICCount + 1
         end if
      end if
      
      ' Check if counter is a TS counter
      if instr(objRSResults("Counter"), "\Terminal Services Session(") > 0 then
         ' If we haven't already identified a TS counter to process then we do it now
         if strTSCounter = vbNullString then strTSCounter = Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\"))
         
         ' Check if our TS counter is the same as our counter flagged to process
         if Right(objRSResults("Counter"),len(objRSResults("Counter")) - instrrev(objRSResults("Counter"),"\")) = strTSCounter then
            ' Parse out the instance identifier
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)

            ' Update array
            ReDim Preserve ArrTS(iTSCount)
            ArrTS(iTSCount) = strTmp
            iTSCount = iTSCount + 1
         end if
      end if

      objRSResults.MoveNext
   Wend
   
   ' Sort the arrays for processors, disks, nics and TS sessions
   Call SortArray(ArrProcessors)
   Call SortArray(ArrServerWorkQueues)
   Call SortArray(ArrDisks)
   Call SortArray(ArrNICs)
   Call SortArray(ArrTS)

   ShowMsg "Completed populating instance arrays."

End Sub


' Sub to update objRSProcess with result values for individual processes
Sub UpdateProcessListing()

   ShowMsg "Updating process specific values..."
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   While not objRSResults.EOF
   
      ' Update Handle Count values for individual processes
      if (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Handle Count") > 0) then
         if objRSResults("Counter") <> "\Process(_Total)\Handle Count" then
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .BOF AND not .EOF then
                  .Fields("Handle_First") = objRSResults("First")
                  .Fields("Handle_Last") = objRSResults("Last")
                  .Fields("Handle_Min") = objRSResults("Min")
                  .Fields("Handle_Max") = objRSResults("Max")
                  .Fields("Handle_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "Handles - Unable to find process: " & strTmp
               end if
            End With
         end if
      end if

      ' Update Thread Count values for individual processes
      if (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Thread Count") > 0) then
         if objRSResults("Counter") <> "\Process(_Total)\Thread Count" then
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .BOF AND not .EOF then
                  .Fields("Thread_First") = objRSResults("First")
                  .Fields("Thread_Last") = objRSResults("Last")
                  .Fields("Thread_Min") = objRSResults("Min")
                  .Fields("Thread_Max") = objRSResults("Max")
                  .Fields("Thread_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "Threads - Unable to find process: " & strTmp
               end if
            End With
         end if
      end if

      ' Update Private Bytes values for individual processes
      if instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Private Bytes") > 0 then
         if not objRSResults("Counter") = "\Process(_Total)\Private Bytes" then
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .EOF then
                  .Fields("PrivateBytes_First") = objRSResults("First")
                  .Fields("PrivateBytes_Last") = objRSResults("Last")
                  .Fields("PrivateBytes_Min") = objRSResults("Min")
                  .Fields("PrivateBytes_Max") = objRSResults("Max")
                  .Fields("PrivateBytes_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "Private Bytes - Unable to find process: " & strTmp
               end if
            End With
         end If
      end if

      ' Update Virtual Bytes values for individual processes
      if instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Virtual Bytes") > 0 then
         if not objRSResults("Counter") = "\Process(_Total)\Virtual Bytes" then
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .EOF then
                  .Fields("VirtualBytes_First") = objRSResults("First")
                  .Fields("VirtualBytes_Last") = objRSResults("Last")
                  .Fields("VirtualBytes_Min") = objRSResults("Min")
                  .Fields("VirtualBytes_Max") = objRSResults("Max")
                  .Fields("VirtualBytes_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "Virtual Bytes - Unable to find process: " & strTmp
               end if
            End With
         end if
      end if

      ' Update Working Set values for individual processes
      if instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Working Set") > 0 then
         if not objRSResults("Counter") = "\Process(_Total)\Working Set" then
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .EOF then
                  .Fields("WorkingSet_First") = objRSResults("First")
                  .Fields("WorkingSet_Last") = objRSResults("Last")
                  .Fields("WorkingSet_Min") = objRSResults("Min")
                  .Fields("WorkingSet_Max") = objRSResults("Max")
                  .Fields("WorkingSet_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "Working Set - Unable to find process: " & strTmp
               end if
            End With
         end if
      end if

      ' Update % Processor Time values for individual processes
      if instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "% Processor Time") > 0 then
         if not objRSResults("Counter") = "\Process(_Total)\% Processor Time" AND _
            not objRSResults("Counter") = "\Process(Idle)\% Processor Time" then
            
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .EOF then
                  .Fields("ProcessorUsage_First") = objRSResults("First")
                  .Fields("ProcessorUsage_Last") = objRSResults("Last")
                  .Fields("ProcessorUsage_Min") = objRSResults("Min")
                  .Fields("ProcessorUsage_Max") = objRSResults("Max")
                  .Fields("ProcessorUsage_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "% Processor Time - Unable to find process: " & strTmp
               end if
            End With
         End if
      end If

      ' Update % Privileged Time values for individual processes
      if instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "% Privileged Time") > 0 then
         if not objRSResults("Counter") = "\Process(_Total)\% Privileged Time" AND _
            not objRSResults("Counter") = "\Process(Idle)\% Privileged Time" then
            
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .EOF then
                  .Fields("PrivilegedProcessorUsage_First") = objRSResults("First")
                  .Fields("PrivilegedProcessorUsage_Last") = objRSResults("Last")
                  .Fields("PrivilegedProcessorUsage_Min") = objRSResults("Min")
                  .Fields("PrivilegedProcessorUsage_Max") = objRSResults("Max")
                  .Fields("PrivilegedProcessorUsage_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "% Privileged Time - Unable to find process: " & strTmp
               end if
            End With
         End if
      end If
      
      ' Update IO Data Bytes/sec values for individual processes
      if instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "IO Data Bytes/sec") > 0 then
         if not objRSResults("Counter") = "\Process(_Total)\IO Data Bytes/sec" then
            iStart = instr(objRSResults("Counter"),"(")+1
            iEnd = instr(objRSResults("Counter"),")") - iStart
            strTmp = mid(objRSResults("Counter"),iStart,iEnd)
            With objRSProcess
               if not .BOF then .MoveFirst
               .Find "Process = '" & strTmp & "'"
               if not .EOF then
                  .Fields("IODataBytes_First") = objRSResults("First")
                  .Fields("IODataBytes_Last") = objRSResults("Last")
                  .Fields("IODataBytes_Min") = objRSResults("Min")
                  .Fields("IODataBytes_Max") = objRSResults("Max")
                  .Fields("IODataBytes_Avg") = objRSResults("Avg")
                  
                  .Update
               else
                  ShowMsg "IO Data Bytes/sec - Unable to find process: " & strTmp
               end if
            End With
         end if
      end if

      objRSResults.MoveNext
   Wend
   
   ShowMsg "Completed updating process values."
   
End Sub


' Sub to process objRSResults values that have been added up to calculate averages
Sub CalculateAverages()

   ShowMsg "Calculating counter averages..."
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   while not objRSResults.EOF

      ShowMsg objRSResults("Counter") & " | " & objRSResults("Avg") & " | " & objRSResults("Samples")

      ' Perform the Avg calculation
      if objRSResults("Samples") > 0 then objRSResults("Avg") = objRSResults("Avg") / objRSResults("Samples")
      
      ' Change all the byte values that we want to display as MB
      if (objRSResults("Counter") = "\Memory\Pool Paged Bytes") OR _
         (objRSResults("Counter") = "\Memory\Pool NonPaged Bytes") OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Private Bytes") > 0) OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Virtual Bytes") > 0) OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Working Set") > 0) OR _
         (objRSResults("Counter") = "\Memory\Cache Bytes") OR _
         (objRSResults("Counter") = "\Memory\Committed Bytes") OR _
         (objRSResults("Counter") = "\Memory\Commit Limit") OR _
         (instr(objRSResults("Counter"),"\Terminal Services Session(") > 0 AND instr(objRSResults("Counter"), "Private Bytes") > 0) OR _
         (instr(objRSResults("Counter"),"\Terminal Services Session(") > 0 AND instr(objRSResults("Counter"), "Virtual Bytes") > 0) OR _
         (instr(objRSResults("Counter"),"\Terminal Services Session(") > 0 AND instr(objRSResults("Counter"), "Working Set") > 0) then

         objRSResults("First") = CLng(objRSResults("First") / 1048576)
         objRSResults("Last") = CLng(objRSResults("Last") / 1048576)
         objRSResults("Min") = CLng(objRSResults("Min") / 1048576)
         objRSResults("Max") = CLng(objRSResults("Max") / 1048576)
         objRSResults("Avg") = CLng(objRSResults("Avg") / 1048576)
      
      end if
      
      ' Change all the byte values that we want to display as KB
      if (instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Disk Bytes/sec") > 0) OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "IO Data Bytes/sec") > 0) OR _
         (instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Bytes Total/sec") > 0) then
      
         objRSResults("First") = Round(objRSResults("First") / 1024)
         objRSResults("Last") = Round(objRSResults("Last") / 1024)
         objRSResults("Min") = Round(objRSResults("Min") / 1024)
         objRSResults("Max") = Round(objRSResults("Max") / 1024)
         objRSResults("Avg") = Round(objRSResults("Avg") / 1024)

      end if
      
      ' Change all the values that simply need to be rounded and displayed with 0 decimals
      if (objRSResults("Counter") = "\Memory\Available MBytes") OR _
         (objRSResults("Counter") = "\Memory\Free System Page Table Entries") OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Handle Count") > 0) OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "Thread Count") > 0) OR _
         (objRSResults("Counter") = "\Memory\% Committed Bytes In Use") OR _
         (objRSResults("Counter") = "\System\Processor Queue Length") OR _
         (instr(objRSResults("Counter"),"\Terminal Services Session(") > 0 AND instr(objRSResults("Counter"), "Handle Count") > 0) OR _
         (instr(objRSResults("Counter"),"\Terminal Services Session(") > 0 AND instr(objRSResults("Counter"), "Thread Count") > 0) OR _
         (instr(objRSResults("Counter"),"\Server Work Queues(") > 0) OR _
         (instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Output Queue Length") > 0) OR _
         (instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Packets/sec") > 0) OR _
         (instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Packets Received Discarded") > 0) OR _
         (instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Packets Received Errors") > 0) then
         
         objRSResults("First") = Round(objRSResults("First"))
         objRSResults("Last") = Round(objRSResults("Last"))
         objRSResults("Min") = Round(objRSResults("Min"))
         objRSResults("Max") = Round(objRSResults("Max"))
         objRSResults("Avg") = Round(objRSResults("Avg"))
         
      end if
      
      ' Change all the values that simply need to be rounded and displayed with 2 decimals
      if (instr(objRSResults("Counter"),"\Processor(") > 0 AND instr(objRSResults("Counter"), "% Processor Time") > 0) OR _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "% Processor Time") > 0) Or _
         (instr(objRSResults("Counter"),"\Process(") > 0 AND instr(objRSResults("Counter"), "% Privileged Time") > 0) Or _
         (instr(objRSResults("Counter"),"\Processor(") > 0 AND instr(objRSResults("Counter"), "% DPC Time") > 0) OR _
         (instr(objRSResults("Counter"),"\Processor(") > 0 AND instr(objRSResults("Counter"), "% Interrupt Time") > 0) Or _
         (instr(objRSResults("Counter"),"\Processor(") > 0 And instr(objRSResults("Counter"), "% Privileged Time") > 0) Or _
         (instr(objRSResults("Counter"),"\Processor(") > 0 And instr(objRSResults("Counter"), "% User Time") > 0) Or _
         (instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "% Idle Time") > 0) OR _
         (instr(objRSResults("Counter"),"\Terminal Services Session(") > 0 AND instr(objRSResults("Counter"), "% Processor Time") > 0) then

         objRSResults("First") = Round(objRSResults("First"),2)
         objRSResults("Last") = Round(objRSResults("Last"),2)
         objRSResults("Min") = Round(objRSResults("Min"),2)
         objRSResults("Max") = Round(objRSResults("Max"),2)
         objRSResults("Avg") = Round(objRSResults("Avg"),2)
         
      end if
      
      ' Change all the values that simply need to be rounded and displayed with 3 decimals
      if (objRSResults("Counter") = "\Memory\Pages/sec") OR _
         (instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Avg. Disk sec/Transfer") > 0) OR _
         (instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Avg. Disk Queue Length") > 0) OR _
         (instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Split IO/Sec") > 0) OR _
         (instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Disk Transfers/sec") > 0) then

         objRSResults("First") = Round(objRSResults("First"),3)
         objRSResults("Last") = Round(objRSResults("Last"),3)
         objRSResults("Min") = Round(objRSResults("Min"),3)
         objRSResults("Max") = Round(objRSResults("Max"),3)
         objRSResults("Avg") = Round(objRSResults("Avg"),3)
         
      end if
      
      ' Change all the values that need to be divided by 1000000, rounded and displayed with 0 decimals
      if (instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Current Bandwidth") > 0) then

         objRSResults("First") = Round(objRSResults("First") / 1000000)
         objRSResults("Last") = Round(objRSResults("Last") / 1000000)
         objRSResults("Min") = Round(objRSResults("Min") / 1000000)
         objRSResults("Max") = Round(objRSResults("Max") / 1000000)
         objRSResults("Avg") = Round(objRSResults("Avg") / 1000000)

      end if

      objRSResults.Update
      objRSResults.MoveNext
      
   Wend
   
   ShowMsg "Completed calculating counter averages."
   
End Sub


' Sub to process objRSResults and identify any concerns based on Min, Max or Avg values
' or based on comparative calculations with other counters
Sub IdentifyConcerns()

   ShowMsg "Processing for threshold violations..."
   
      '***clandis***
      ' Check free system PTEs to determine bitness
      ' 33,554,432 PTEs with 4K page size to address 128 GB paged pool on 64-bit
      ' 524,288 PTEs with 4K page size to address 2 GB paged pool on 32-bit
      ' Therefore we can say >524288 free system PTEs indicates a 64-bit machine.   
   
      If Not objRSResults.BOF Then objRSResults.MoveFirst

      While Not objRSResults.EOF
   
            If objRSResults("Counter") = "\Memory\Free System Page Table Entries" Then
                  If objRSResults("Max") > 524288 Then
                        bIs64bit = True
						ShowMsg "Free System PTEs (MAX) " & objRSResults("Max") & " > 524288 so this must be from a 64-bit machine"
                  Else
                  		bIs64bit = False
                  End If
      End If
   
      objRSResults.MoveNext
      
   Wend
   '/***clandis***

   
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   While not objRSResults.EOF
      
      ' Flag if Available MBytes falls below 15MB
      if (objRSResults("Counter") = "\Memory\Available MBytes") then
         if objRSResults("Min") < 15 then
            Call AddConcern(objRSResults("Counter"), "MB", _
                  Array("Below 4MB is hazardous.", _
                        "Investigate applications with high Private/Virtual Bytes."))
            end if
      end if
      
      ' Flag if Pool Paged Bytes climbs above 300MB
      If ((objRSResults("Counter") = "\Memory\Pool Paged Bytes") And (Not bIs64bit))then
         if objRSResults("Max") > 300 Then
            Call AddConcern(objRSResults("Counter"), "MB", _
                  Array("W2K Theoretical Limit is 491MB (192MB with /3GB).", _
                        "Q304101 if exhausted during large file operations.", _
                        "Capture poolmon log to collect driver usage."))
         end if
      end if

      ' Flag if Pool Non-Paged climbs to > 95 but <= 128 as this may be an issue if /3GB is enabled
      ' Flag if Pool Non-Paged climbs above 200
      If ((objRSResults("Counter") = "\Memory\Pool NonPaged Bytes") and (Not bIs64bit)) then
         if (objRSResults("Max") > 95 AND objRSResults("Max") <= 128) then
            Call AddConcern(objRSResults("Counter"),"MB", _
                  Array("This is generally only concerning if /3GB is in use.", _
                        "W2K Theoretical Limit is 256MB (128MB with /3GB).", _
                        "Capture poolmon log to collect driver usage."))
         end if
         if objRSResults("Max") > 200 then 
            Call AddConcern(objRSResults("Counter"),"MB", _
                  Array("W2K Theoretical Limit is 256MB (128MB with /3GB).", _
                        "Capture poolmon log to collect driver usage."))
         end if
      end if

      ' Flag Free System PTEs if they fall below 10000
      if objRSResults("Counter") = "\Memory\Free System Page Table Entries" Then
         if objRSResults("Min") < 10000 then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("System should have more than 10,000 PTEs.", _
                        "At 502 system becomes unresponsive.", _
                        "If W2K3 & /3GB check BOOT.INI for /USERVA=[2800-3072]."))
         end if
      end if

      ' Flag Handle count if total climbs above 15,000
      if objRSResults("Counter") = "\Process(_Total)\Handle Count" then
         if (objRSResults("Max") >= 15000) then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("This may be a normal amount on Terminal Servers in Application Mode.", _
                        "Investigate individual applications using > 1,500 handles."))
         end if
      end if

      ' Flag Thread count if total climbs above 1,500
      if objRSResults("Counter") = "\Process(_Total)\Thread Count" then
         if (objRSResults("Max") >= 1500) then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("This may be a normal amount on Terminal Servers in Application Mode.", _
                        "Investigate individual applications using > 150 threads."))
         end if
      end if
      
      ' Flag Cache Bytes if Max climbs above 400MB and Avg is above 300MB
      If ((objRSResults("Counter") = "\Memory\Cache Bytes") and (Not bIs64bit)) then
         if objRSResults("Max") > 400 AND objRSResults("Avg") > 300 then
            Call AddConcern(objRSResults("Counter"), "MB", _
                  Array("Caching can explain available memory swings.", _
                        "Often a sign of a disk bottleneck."))
         end if
      end if

      ' Flag Commit Limit if it changes at all
      if objRSResults("Counter") = "\Memory\Commit Limit" then
         if (objRSResults("Min") <> objRSResults("Max")) then
            Call AddConcern(objRSResults("Counter"), "MB", _
                  Array("Should not change - means page file has been expanded.", _
                        "Apps can react poorly to memory allocation rejection.", _
                        "Review Committed Bytes and % Committed Bytes In Use."))
         end if
      end if

      ' Flag % Committed Bytes In Use if Max climbs above 80% and Avg is above 60%
      if objRSResults("Counter") = "\Memory\% Committed Bytes In Use" then
         if objRSResults("Max") > 80 AND objRSResults("Avg") > 60 then
            Call AddConcern(objRSResults("Counter"), "%", _
                  Array("Committed Bytes should rise and fall with load/unload hours.", _
                        "This is especially concerning if Commit Limit is changing."))
         end if
      end if

      ' Flag Pages/sec if Avg is above 100
      if objRSResults("Counter") = "\Memory\Pages/sec" then
         if objRSResults("Avg") > 100 then
            Call AddConcern(objRSResults("Counter"),"", _
                  Array("High values (~500) may be fine if disk subsystem is fast.", _
                        "Review % Idle Time and Avg. Disk sec/Transfer for I/O rates."))
         end if
      end if

      ' Flag Processor Queue Length if Avg is above 10
      if objRSResults("Counter") = "\System\Processor Queue Length" then
         if objRSResults("Avg") > 10 then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("A sustained processor queue length greater than 10 is concerning.", _
                        "< 10 = fair, < 2 = good, 0 = excellent."))
         end if
      end if

      ' Flag % Processor time on each processor if Avg is above 70%
      if instr(objRSResults("Counter"),"\Processor(") > 0 AND instr(objRSResults("Counter"), "% Processor Time") > 0 then
         if objRSResults("Counter") <> "\Processor(_Total)\% Processor Time" then
            if objRSResults("Avg") > 70 then
               Call AddConcern(objRSResults("Counter"), "%", _
                     Array("Check individual processes for high usage."))
            end if
         end if
      end if

      ' Flag % DPC time on each processor if Avg is above 15%
      if instr(objRSResults("Counter"),"\Processor(") > 0 AND instr(objRSResults("Counter"), "% DPC Time") > 0 then
         if objRSResults("Counter") <> "\Processor(_Total)\% DPC Time" then
            if objRSResults("Avg") > 15 then
               Call AddConcern(objRSResults("Counter"), "%", _
                     Array("Time required to process I/O is high.", _
                           "This should be less than 15%."))
            end if
         end if
     end if

      ' Flag % Interrupt time on each processor if Avg is above 10%
      if instr(objRSResults("Counter"),"\Processor(") > 0 AND instr(objRSResults("Counter"), "% Interrupt Time") > 0 then
         if objRSResults("Counter") <> "\Processor(_Total)\% Interrupt Time" then
            if objRSResults("Avg") > 10 then
               Call AddConcern(objRSResults("Counter"), "%", _
                     Array("Time required to setup an I/O request is high.", _
                           "This should be less than 10%."))
            end if
         end if
      end if

      ' Flag % Idle Time if Avg is below 60%
      if instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "% Idle Time") > 0 then
         if objRSResults("Counter") <> "\PhysicalDisk(_Total)\% Idle Time" then
            if objRSResults("Avg") < 60 then
               Call AddConcern(objRSResults("Counter"), "%", _
                     Array("Disk is heavily utilized and may be a bottleneck.", _
                           "Investigate Disk bytes/sec and individual process IO Data bytes/sec for high disk usage."))
            end if
         end if
      end if

      ' Flag Avg Disk sec/Transfer if Avg is above 0.03 seconds
      if instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Avg. Disk sec/Transfer") > 0 then
         if objRSResults("Counter") <> "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer" then
            if objRSResults("Avg") > 0.03 then
               Call AddConcern(objRSResults("Counter"), "", _
                     Array("> 0.030 = Poor, < 0.030 = Fair, < 0.020 = Good, < 0.010 = Excellent.", _
                           "Cached disks < 0.001 = Excellent, < 0.002 = Good."))
            end if
         end if
      end if

      ' Flag Avg Disk Queue Length if Avg is above 5
      if instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Avg. Disk Queue Length") > 0 then
         if objRSResults("Counter") <> "\PhysicalDisk(_Total)\Avg. Disk Queue Length" then
            if objRSResults("Avg") > 5 then
               Call AddConcern(objRSResults("Counter"), "", _
                     Array("Generally up to 2 per spindle (Hard Disk Device) is acceptable."))
            end if
         end if
      end if

      ' Flag Split IO/Sec if Avg is above 5% of Disk Transfer/sec Avg
      if instr(objRSResults("Counter"),"\PhysicalDisk(") > 0 AND instr(objRSResults("Counter"), "Split IO/Sec") > 0 then
         if objRSResults("Counter") <> "\PhysicalDisk(_Total)\Split IO/Sec" then
            ' Parse Split IO/Sec counter to set which Disk Transfer/sec counter we want
            strTmp = Left(objRSResults("Counter"),instrrev(objRSResults("Counter"), "\")) & "Disk Transfers/sec"
            
            ' Save Avg value of Split IO/sec counter
            varSplitIO = CDbl(objRSResults("Avg"))
            ' Default VarPercent to 0
            varPercent = 0
            
            ' Save place in recordset to pickup back where we left off
            varBookmark = objRSResults.Bookmark
            
            ' Search for Disk Transfer/sec counter - if it wasn't included then we can't calculate
            if FindRecord(objRSResults, "Counter = '" & strTmp & "'") then 
               If(CDbl(objRSResults("Avg")) <> 0 ) Then
               	varPercent = Round((varSplitIO / CDbl(objRSResults("Avg"))) * 100,2)
               End If
            end If

            ' Return back to our saved spot in the recordset processing
            objRSResults.Bookmark = varBookmark

            if varPercent > 5 then
               Call AddConcern(objRSResults("Counter"), "", _
                     Array("Split IO operations make up " & varPercent & "% of Disk Transfers.", _
                           "RAID may be too small/NTFS block too small.", _
                           "Disk may have moderate to heavy fragmentation."))
            end if
         end if
      end if

      ' Flag Output Queue Length if Avg is above 2
      if instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Output Queue Length") > 0 then
         if objRSResults("Avg") > 2 then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("> 2 identifies delays.", _
                        "Unreliable on W2K without Q834940 hotfix or if checksum is offloaded to NIC."))
         end if
      end if

      ' Flag Packets Received Discarded if any have occurred
      if instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Packets Received Discarded") > 0 then
         if objRSResults("Max") > 0 then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("Suggests hardware problems."))
         end if
      end if

      ' Flag Packets Received Errors if any have occurred
      if instr(objRSResults("Counter"),"\Network Interface(") > 0 AND instr(objRSResults("Counter"), "Packets Received Errors") > 0 then
         if objRSResults("Max") > 0 then
            Call AddConcern(objRSResults("Counter"), "", _
                  Array("Suggests hardware problems."))
         end if
      end if

      objRSResults.MoveNext
      
   Wend
   
   ShowMsg "Completed checking for threshold violations."
   
End Sub


' Sub to process objRSResults values that have been added up to calculate averages
' and identify any concerns based on the Min, Max or Avg values.
' Sub to parse the CSV output file generated by relog, import the data and 
' execute calculations to determine first, last, min, max, averages and #
' of samples for each counter.  Once all this has been collected the results
' are dumped into objRSResults recordset.
Sub ParseOutputFile(strFile)

   ' Read data from strOutputFile
   Set objFile = objFSO.OpenTextFile(strFile,fso_ForReading,true)
   
   ' Pull all the data into a single stream
   strData = objFile.ReadAll
   objFile.Close
   
   ' Destory text file connection as it is no longer required
   Set objFile = Nothing

   ' Extract first line to CRLF to get the headers (counters)
   strLen = Instr(strData,vbCrLf)
   strHeaders = Left(strData,strLen-2)
   ArrHeaders = Split(strHeaders,",")
   strData = Right(strData, Len(strData) - (strLen+1))
   
   ' The upper limit of the array translates to the number of counters
   ' collected on a 0 based index
   iNumCounters = UBound(ArrHeaders)
   
   ' Capture the server name from one of the headers
   strServerName = UCase(GetServer(ArrHeaders(1)))
   ShowMsg "Server Name = " & strServerName
   
   ' Capture log file name from strOrgFile value
   strLogFilename = UCase(GetLogFilename(strOrgFile))
   ShowMsg "Performance Monitor Log = " & strLogFileName
   
   ' Process header array to identify counters included in regenerated log
   ShowMsg "Importing counters collected from regenerated log..."
   
   ' Change the value of header for sample date to something useful
   ArrHeaders(0) = "SampleDate"
   
   ' Enumerate the rest of the counters checking for which counters
   ' have been included to determine if we will be showing these sections
   ' in the results file
   For i = 1 to iNumCounters
      ShowMsg "   Found counter: " & ArrHeaders(i)
      ArrHeaders(i) = Trim(StripServer(ArrHeaders(i)))
      
      ' Check counters to determine whether or not to display sections
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\Handle Count") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\Handle Count" then bShowTopN_Handle = True
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\Thread Count") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\Thread Count" then bShowTopN_Thread = True
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\Private Bytes") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\Private Bytes" then bShowTopN_PBytes = True
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\Virtual Bytes") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\Virtual Bytes" then bShowTopN_VBytes = True
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\Working Set") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\Working Set" then bShowTopN_WSet = True
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\% Processor Time") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\% Processor Time" then bShowTopN_CPU = True
      if instr(ArrHeaders(i), "\Process(") > 0 AND _
         instr(ArrHeaders(i),"\IO Data Bytes/sec") > 0 AND _
         ArrHeaders(i) <> "\Process(_Total)\IO Data Bytes/sec" then bShowTopN_IOData = True
      if instr(ArrHeaders(i), "\Memory\") > 0 then bShowMemory = True
      if instr(ArrHeaders(i), "\Processor(") > 0 OR instr(ArrHeaders(i), "\System\Processor Queue Length") > 0 then bShowProcessor = True
      if instr(ArrHeaders(i), "\PhysicalDisk(") > 0 then bShowDisk = True
      if instr(ArrHeaders(i), "\Network Interface(") > 0 then bShowNIC = True
   Next
   ShowMsg "Completed importing counters from regenerated log."

   ' Populate objRSResults recordset with counters and default values
   ShowMsg "Populating results recordset with default values..."
   For i = 1 to iNumCounters
      ShowMsg "   Processing counter: " & ArrHeaders(i)
      With objRSResults
         .AddNew "Counter", ArrHeaders(i)
         .Fields("First") = 0
         .Fields("Last") = 0
         .Fields("Min") = 0
         .Fields("Max") = 0
         .Fields("Avg") = 0
         .Fields("Samples") = 0
         
         .Update
         
      End With
   Next
   ShowMsg "Completed setting default values."
   
   ' Import data into objRSData recordset to prepare for processing
   ShowMsg "Importing data samples into data set..."
   ShowMsg "   This may take a few minutes..."
   iRecCounter = 0
   strLastSampleDate = ""
   strThisSampleDate = ""
   
   ' Split the data stream into an array based on carriage return/line feed
   ArrRecords = Split(strData, vbCrLf)
   
   ' Since we are splitting on vbCrLf we are likely creating a null record at the end
   if ArrRecords(UBound(ArrRecords)) = vbNullString then ReDim Preserve ArrRecords(UBound(ArrRecords)-1)

   ' Upper bound of ArrRecords is our total number of samples on a 0
   ' based index
   iTotalSamples = UBound(ArrRecords)
   
   ' Redimension our data array for the number of samples by the number of counters
   ReDim ArrData(iTotalSamples, iNumCounters)
   
   ' Enumerate the ArrData array to strip the quotes from values, strip
   ' milliseconds from sample date/time and identify if any samples are
   ' out of order and as a result may look like a reboot occurred when
   ' it didn't or provided messed up start and end dates
   for l = 0 to iTotalSamples
      
      ' Parse out a single record
      ArrRecord = Split(ArrRecords(l),",")
      
      ' Process the data into the ArrData array trimming and stripping quotes
      for m = 0 to iNumCounters
         ArrData(l,m) = trim(StripQuotes(ArrRecord(m)))
      next
      
      ' Extract sample date/time and strip milliseconds
      if instr(ArrData(l,0), ".") > 0 then ArrData(l,0) = Left(ArrData(l,0), instr(ArrData(l,0), ".")-1)
      
      ' Check if samples are occurring out of order
      ' Relog has known issue of producing data out of order
      strLastSampleDate = strThisSampleDate
      strThisSampleDate = ArrData(l,0)
      if strThisSampleDate < strLastSampleDate then iOutofOrder = iOutofOrder + 1
      
      ' Display a comment every 50 samples to identify processing completed
      iRecCounter = iRecCounter + 1
      if iRecCounter = 50 then
         ShowMsg "   Imported " & (l+1) & " of " & (iTotalSamples+1) & " samples."
         iRecCounter = 0
      end if
   next
   ReDim ArrRecords(0)
   ShowMsg "Completed importing data samples into data set: " & (iTotalSamples+1) & " sample(s)."
   ShowMsg iOutOfOrder & " samples were detected out of order."
   
   ' Determine if System Up Time counter was included
   bSystemUpTime = FindCounter(ArrHeaders, "\System\System Up Time")
   
   ' Check ArrData(0,0) through ArrData(9,0) or as many sample as we
   ' have and strip highest and lowest differences then average the
   ' remaining items to determine the sample interval
   ' Check if our total samples is >= 10 (0 based index) and if so
   ' capture the first 10 samples to average out
   ShowMsg "Processing sample segment to determine sample interval..."
   if iTotalSamples >= 9 then
      ReDim ArrTempData(9)
   else
      ReDim ArrTempData(iTotalSamples)
   end if
   iTmpSampleLast = 0
   iTmpSampleThis = 0
   ' Copy samples to temp array
   for l = 0 to UBound(ArrTempData)
      ArrTempData(l) = ArrData(l,0)
      if l > 0 then 
         iTmpSampleLast = iTmpSampleThis
         iTmpSampleThis = Int(TimeDiff("s", ArrTempData(l-1), ArrTempData(l)))
         ' If we are processing the first sample then we want the last to be
         ' the same for our check
         if l = 1 then iTmpSampleLast = iTmpSampleThis
         if iTmpSampleLast <> iTmpSampleThis then bSamplesSkewed = True
'         ShowMsg "   W00t: " & ArrTempData(l-1) & " - " & ArrTempData(l)
         ShowMsg "   Sample " & (l+1) & " shows sample interval of " & iTmpSampleThis & " second(s)."
      end if
   next
   ' Sort temp array
   Call SortArray(ArrTempData)
   ' If our total samples is greater than 3 (0 based index) then we 
   ' can process our averages trimming lowest and highest and taking
   ' an average of the values in the middle otherwise we will have to
   ' settle for difference between sample 1 and 2 (or worse fewer than
   ' 2 samples is worthless)
   if iTotalSamples > 2 then
      ArrTempData(0) = 0
      iErrorSamples = 0
      for l = 2 to UBound(ArrTempData)-1
         iTmpSample = Int(TimeDiff("s", ArrTempData(l-1), ArrTempData(l)))
         ' Perform a check to rule out silly values so we will only accept
         ' sample intervals between 0 and 10000
         if iTmpSample > 0 and iTmpSample < 10000 then
            ArrTempData(0) = Int(ArrTempData(0)) + iTmpSample
         else
            iErrorSamples = iErrorSamples + 1
         end if
      next
      ShowMsg "   " & iErrorSamples & " sample(s) discarded due to unrealistic sample."
      ArrTempData(0) = Int(Int(ArrTempData(0)) / (UBound(ArrTempData)-2-iErrorSamples))
   else
      ' If total samples is greater than 1 then we at least have 2 samples
      ' to work with otherwise we simply set our sample interval to 0
      if iTotalSamples > 0 then
         ArrTempData(0) = Int(TimeDiff("s", ArrTempData(0), ArrTempData(1)))
      else
         ArrTempData(0) = 0
      end if
   end if
      
   ' Convert the sample interval to a readable number - we can use the Uptime2Str function
   strSampleInterval = Uptime2Str(CLng(ArrTempData(0)))

   ' If we have some skewed samples then we need to note that our sample interval is
   ' based on an averaged out calculation
   if (bSamplesSkewed and iTotalSamples > 2) then strSampleInterval = strSampleInterval & " (Average - sample intervals were varied)"
   ShowMsg "Completed processing sample segment."
   ShowMsg "Sample Interval = " & strSampleInterval
   
   ' Determine Start and End Dates by processing first sample and last
   ' sample counter 0
   strStartDate = ArrData(0,0)
   strEndDate = ArrData(iTotalSamples,0)

   ' Figure out the log duration based on the start and end dates identified
   iDuration_Days = DateDiff("d", Left(strStartDate,instr(strStartDate," ")-1), Left(strEndDate,instr(strEndDate," ")-1))
   ' If second date is less than first date then TimeDiff would have added
   ' 86400 to the date to mitigate the negative so we will need to remove
   ' 1 day from our total days as we didn't quite make the full 24 hours
   dTime1 = CDate(FormatDateTime(strStartDate, vbLongTime))
   dTime2 = CDate(FormatDateTime(strEndDate, vbLongtime))
   if dTime2 < dTime1 then iDuration_Days = iDuration_Days - 1
   iDuration_TotalSec = TimeDiff("s", strStartDate,strEndDate)
   iDuration_Hour = Int(iDuration_TotalSec / 3600)
   iDuration_Min = Int((iDuration_TotalSec - (iDuration_Hour * 3600)) / 60)
   iDuration_Sec = Int(iDuration_TotalSec - ((iDuration_Hour * 3600) + (iDuration_Min * 60)))
   ShowMsg "Log Duration = " & iDuration_Days & "d " & iDuration_Hour & "h " & iDuration_Min & "m " & iDuration_Sec & "s"
   
   ' Set the total log samples
   strSamples = CStr(iTotalSamples+1)
   ShowMsg "Total Samples = " & strSamples
      
   ' Determine uptimes for Start and End Dates
   if bSystemUpTime = True then strStartDate = strStartDate & " (Uptime was: " & Uptime2Str(ArrData(0,iNumCounters)) & ")"
   ShowMsg "Start Date/Time = " & strStartDate
   if bSystemUpTime = True then strEndDate = strEndDate & " (Uptime was: " & Uptime2Str(ArrData(iTotalSamples,iNumCounters)) & ")"
   ShowMsg "End Date/Time = " & strEndDate
   
   ' Scan for reboots - only available if System Up Time counter was included
   if bSystemUpTime = True then
      ShowMsg "Scanning for reboots..."
      iLastUptime = 0
      iThisUptime = 0
      for i = 0 to iTotalSamples
         iLastUptime = iThisUptime
         if ArrData(i,iNumCounters) <> "" then iThisUptime = CLng(ArrData(i,iNumCounters))
         if iThisUptime < iLastUptime Then
            strRebootTimes = strRebootTimes & PadStr("Reboot Detected",20,jf_PadStrLeft) & ": " & _
               ArrData(i,0) & " (Uptime was: " & UpTime2Str(iLastUptime) & _
               ")" & vbCrLf
         end if
      Next
      if strRebootTimes = "" then
         ShowMsg "No reboots detected."
      else
         ShowMsg strRebootTimes
      end if
   else
      ShowMsg "System Up Time counter not included in Performance Log."
      strRebootTimes = "*** System Up Time counter not included - no uptime or reboot detection available!"
   end if
   
   ' Temp Array for calculations
   ' 0 = First
   ' 1 = Last
   ' 2 = Min
   ' 3 = Max
   ' 4 - Avg
   ' 5 - Samples
   
'   ' Populate the objRSResults recordset while calculating averages
   ShowMsg "Populating values to result recordset..."

   ' Redimension temp array to number of counters - 1 since we do not
   ' need to process the sample date/time in this array by 6 values
   ' of calculations as outlined above
   ReDim ArrTempData((iNumCounters-1),5)
   
   iRecCount = 0
   ' Enumerate through total samples provided in ArrData array
   for i = 0 to iTotalSamples
      
      ' Enumerate through each counter in the ArrData array
      for j = 1 to iNumCounters
         ' If value in position is not blank then set dTmpData to that value
         ' otherwise set to 0
         if ArrData(i,j) <> "" then 
            dTmpData = CDbl(ArrData(i,j))
         else
            dTmpData = 0
         end if
         ' If we are processing the first sample and that sample is not
         ' blank then we can set our First and Minimum values otherwise
         ' we will continue to use the default already provided for these
         ' values which is 0
         if i = 1 then
            if ArrData(i,j) <> "" then
               ' We must index based on j-1 as iNumCounters is based on
               ' boundaries for ArrData array and not ArrTempData array
               ' which does not include array element 0 from ArrData
               ArrTempData(j-1,0) = dTmpData
               ArrTempData(j-1,2) = dTmpData
            end if
         end if
         ' If ArrData value is not blank then check to see if we are working
         ' with an unrealistic value and if not then check for min, max changes
         ' and add to averages, last value and # of samples.  If data is not
         ' blank then we will set position 1 (last value) to 0
         if ArrData(i,j) <> "" then
            if not ((instr(ArrHeaders(j), "% Processor Time") > 0) AND dTmpData > 64000) then     ' austinM Changed 1000 to 64000.  1000 threshold for Systems with 64 processors was not large enough
               ' If current data is less than what is in current ArrTempData record
               ' position 2 (Min value) then current data is new min value
               if dTmpData < ArrTempData(j-1,2) then ArrTempData(j-1,2) = dTmpData
               ' If current data is greater than what is in current ArrTempData record
               ' position 3 (Max value) then current data is new max value
               if dTmpData > ArrTempData(j-1,3) then ArrTempData(j-1,3) = dTmpData
               ' Add current data to existing data for averages calculation
               ' in position 4
               ArrTempData(j-1,4) = ArrTempData(j-1,4) + dTmpData
               ' Updated value in position 1 (last value) to current value
               ArrTempData(j-1,1) = dTmpData
               ' Increase value in position 5 (# of samples) as we have valid data
               ArrTempData(j-1,5) = ArrTempData(j-1,5) + 1
            end if
         else
            ArrTempData(j-1,1) = 0
         end if
      next
      iRecCount = iRecCount + 1
      if iRecCount = 50 then
         ShowMsg "   Processed " & (i+1) & " of " & (iTotalSamples+1) & " samples."
         iRecCount = 0
      end if
   next

   ' Move to beginning of results recordset to dump calculated values
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   ' Enumerate ArrTempData array to dump calculated values into objRSResults
   for i = 0 to (iNumCounters - 1)
      objRSResults("First") = ArrTempData(i,0)
      objRSResults("Last") = ArrTempData(i,1)
      objRSResults("Min") = ArrTempData(i,2)
      objRSResults("Max") = ArrTempData(i,3)
      objRSResults("Avg") = ArrTempData(i,4)
      objRSResults("Samples") = ArrTempData(i,5)
      objRSResults.Update
      objRSResults.MoveNext
   next

   ' Sort recordset ascending by counter
   objRSResults.Sort = "Counter ASC"
   
   ShowMsg "Completed populating values to result recordset."
   
   ' Move to beginning of results recordset to build process listing
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   ' Build process listing in process recordset
   ShowMsg "Building process listing in process recordset..."
   While not objRSResults.EOF
      if (not instr(objRSResults("Counter"),"\Process(_Total)") > 0) AND instr(objRSResults("Counter"),"\Process(") > 0 then
         iStart = instr(objRSResults("Counter"),"(")+1
         iEnd = instr(objRSResults("Counter"),")") - iStart
         strTmp = mid(objRSResults("Counter"),iStart,iEnd)
         if not objRSProcess.BOF then objRSProcess.MoveFirst
         objRSProcess.Find "Process = '" & strTmp & "'"
         if objRSProcess.EOF then
            ShowMsg "Adding Process: " & strTmp
            objRSProcess.AddNew "Process", strTmp
            objRSProcess.Update
         end if
      end if
      objRSResults.MoveNext
   Wend
   ShowMsg "Completed building process listing in process recordset."

End Sub


' Function to add commas into a number at appropriate points
' to separate out thousands, millions, billions etc.
Function AddCommas(ByVal str)

   if instr(str,".") > 0 then 
      strDecimals = right(str,len(str)-instr(str,".")+1)
      str = left(str,instr(str,".")-1)
   end if
   if len(str) > 3 then str = left(str,len(str)-3) & "," & right(str,3)
   if len(str) > 7 then str = left(str,len(str)-7) & "," & right(str,7)
   if len(str) > 11 then str = left(str,len(str)-11) & "," & right(str,11)
   if len(str) > 15 then str = left(str,len(str)-15) & "," & right(str,15)
   
   Addcommas = str & strDecimals
   
End Function


' Function to create a display header in results output
Function CreateDisplayHeader(strHeaderName)

   str = ""
   str = str & PadStr(strHeaderName, 37, jf_PadStrLeft)
'   str = str & PadStr("First", 10, jf_PadStrRight)
'   str = str & "   "
'   str = str & PadStr("Last", 10, jf_PadStrRight)
'   str = str & "   "
   str = str & PadStr("Minimum", 10, jf_PadStrRight)
   str = str & "   "
   str = str & PadStr("Maximum", 10, jf_PadStrRight)
   str = str & "   "
   str = str & PadStr("Average", 10, jf_PadStrRight)
'   str = str & "   "
'   str = str & PadStr("Samples", 10, jf_PadStrRight)
   str = str & vbCrLf & PadStrWChar("",len(str),jf_PadStrLeft,"=") & vbCrLf
   
   CreateDisplayHeader = str

End Function


' Function to create display string for results output.  If for some
' reason it cannot locate the counter it is trying to process it will
' return not found.  This should never happen as only counters included
' are configured to display.
Function CreateDisplayString(strFriendlyName, strCounter, strTrailer)
' Using the specified counter generates the display string

   ' Move to the first record before doing our search
   if not objRSResults.BOF then objRSResults.MoveFirst
   
   ' Find the counter in results recordset
   objRSResults.Find "Counter = '" & strCounter & "'"
   
   ' If we aren't at beginning or ending of the recprdset then
   ' we must have found the counter
   if not (objRSResults.BOF or objRSResults.EOF) then
      ' Extract values for first, last, min, max, avg and samples
      dFirst = objRSResults("First")
      dLast = objRSResults("Last")
      dMin = objRSResults("Min")
      dMax = objRSResults("Max")
      dAvg = objRSResults("Avg")
      dSamples = objRSResults("Samples")
      ' Build the display string from results provided
      str = ""
      str = str & PadStr(strFriendlyName,35, jf_PadStrLeft) & ": "
'      str = str & PadStr(AddCommas(dFirst) & strTrailer,10,jf_PadStrRight)
'      str = str & " | "
'      str = str & PadStr(AddCommas(dLast) & strTrailer,10,jf_PadStrRight)
'      str = str & " | "
      str = str & PadStr(AddCommas(dMin) & strTrailer,10,jf_PadStrRight)
      str = str & " | "
      str = str & PadStr(AddCommas(dMax) & strTrailer,10,jf_PadStrRight)
      str = str & " | "
      str = str & PadStr(AddCommas(dAvg) & strTrailer,10,jf_PadStrRight)
'      str = str & " | "
'      str = str & PadStr(AddCommas(dSamples),10,jf_PadStrRight)
      
      CreateDisplayString = str & vbCrLf
   
   else
      ShowMsg strCounter & " not found."
      CreateDisplayString = vbNullString
   end if
   
End Function


' Function to determine if a given file can be opened for writing.
' If no error occurs when attempting to open the file then we have the
' ability to write, otherwise an error returns and we identify the
' failure to write.
Function IsWritable(strFilespec)

   IsWritable = True
   On Error Resume Next
   Set objTemp = objFSO.OpenTextFile(strFilespec, fso_ForWriting, true)
   if Err then
      IsWritable = False
      ShowMsg "Failed to write to: " & strFilespec
   end if
   On Error Goto 0
   
End Function


' Sub to output results to the results file after determining if we can
' successfully write a file.  Which sections are written to the results
' file is based on counters include and bShowxxx variables.
Sub WriteResults()

   ' Try writing to same folder where the perfmon log originated and
   ' if that fails then try writing to the user temp folder.  If that
   ' also fails then we simply cannot write a results file so we will
   ' terminate the processing of the script
   if IsWritable(strResultsFile) = True then
      strResultsFileWrite = strResultsFile
   else
      strResultsFileWrite = strResultsFileFB
      if not IsWritable(strResultsFileFB) then 
         ShowMsgW "Unable to write results to current folder or Temporary Folder - Terminating!"
         WScript.Quit
      end if
   end if

   ShowMsg "Writing results to: " & strResultsFileWrite & "..."
   Set objResults = objFSO.OpenTextFile(strResultsFileWrite, fso_ForWriting,true)

   strMsg = vbNullString

   strMsg = strMsg & "Areas to Investigate" & vbCrLf
   strMsg = strMsg & "====================" & vbCrLf
   if strConcerns = vbNullString then
      strMsg = strMsg & "None found during search for known thresholds." & vbCrLf
   else
      strMsg = strMsg & strConcerns
   end if

   strMsg = strMsg & vbCrLf & vbCrLf
   
   strMsg = strMsg & "Performance Monitor Log Summary" & vbCrLf
   strMsg = strMsg & "===============================" & vbCrLf & vbCrLf
   strMsg = strMsg & "Log Filename        : " & strLogFilename & vbCrLf
   strMsg = strMsg & "Server Name         : " & strServerName & vbCrLf
   strMsg = strMsg & "Start Date & Time   : " & strStartDate & vbCrLf
   strMsg = strMsg & "End Date & Time     : " & strEndDate & vbCrLf
   strMsg = strMsg & "Log Duration        : " & iDuration_Days & "d " & iDuration_Hour & "h " & iDuration_Min & "m " & iDuration_Sec & "s " & vbCrLf
   strMsg = strMsg & "Total Samples       : " & strSamples & vbCrLf
   strMsg = strMsg & "Sample Interval     : " & strSampleInterval & vbCrLf
   if strRebootTimes <> vbNullString then strMsg = strMsg & vbCrLf & strRebootTimes
   if iOutOfOrder > 0 then strMsg = strMsg & vbCrlf & "*** SAMPLES DETECTED OUT OF ORDER - DATE/TIME/REBOOT RESULTS MAY BE INVALID! ***" & vbCrLf
   
   if bShowMemory then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("Memory")
      strMsg = strMsg & CreateDisplayString("Available Bytes", "\Memory\Available MBytes", "MB")
      strMsg = strMsg & CreateDisplayString("Pool Paged Bytes", "\Memory\Pool Paged Bytes", "MB")
      strMsg = strMsg & CreateDisplayString("Pool NonPaged Bytes", "\Memory\Pool NonPaged Bytes", "MB")
      strMsg = strMsg & CreateDisplayString("Free System PTEs", "\Memory\Free System Page Table Entries", "")
      strMsg = strMsg & CreateDisplayString("Handle Count", "\Process(_Total)\Handle Count", "")
      strMsg = strMsg & CreateDisplayString("Thread Count", "\Process(_Total)\Thread Count", "")
      strMsg = strMsg & CreateDisplayString("Private Bytes", "\Process(_Total)\Private Bytes", "MB")
      strMsg = strMsg & CreateDisplayString("Virtual Bytes", "\Process(_Total)\Virtual Bytes", "MB")
      strMsg = strMsg & CreateDisplayString("Working Set", "\Process(_Total)\Working Set", "MB")
      strMsg = strMsg & CreateDisplayString("Cache Bytes", "\Memory\Cache Bytes", "MB")
      strMsg = strMsg & CreateDisplayString("Committed Bytes", "\Memory\Committed Bytes", "MB")
      strMsg = strMsg & CreateDisplayString("Commit Limit", "\Memory\Commit Limit", "MB")
      strMsg = strMsg & CreateDisplayString("% Committed Bytes Used", "\Memory\% Committed Bytes In Use", "%")
      strMsg = strMsg & CreateDisplayString("Pages/sec", "\Memory\Pages/sec", "")
   end if

   if bShowProcessor then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("Processor")
      strMsg = strMsg & CreateDisplayString("Processor Queue Length", "\System\Processor Queue Length", "")
      strMsg = strMsg & CreateDisplayString("% Processor Time", "\Processor(_Total)\% Processor Time", "%")
      For i = 0 to UBound(ArrProcessors)
         if ArrProcessors(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Processor: " & ArrProcessors(i), "\Processor(" & ArrProcessors(i) & ")\% Processor Time", "%")
      Next
      strMsg = strMsg & CreateDisplayString("% User Time", "\Processor(_Total)\% User Time", "%")
      For i = 0 to UBound(ArrProcessors)
         If ArrProcessors(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Processor: " & ArrProcessors(i), "\Processor(" & ArrProcessors(i) & ")\% User Time", "%")
      Next
      strMsg = strMsg & CreateDisplayString("% Privileged Time", "\Processor(_Total)\% Privileged Time", "%")
      For i = 0 to UBound(ArrProcessors)
         if ArrProcessors(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Processor: " & ArrProcessors(i), "\Processor(" & ArrProcessors(i) & ")\% Privileged Time", "%")
      Next
      strMsg = strMsg & CreateDisplayString("% DPC Time", "\Processor(_Total)\% DPC Time", "%")
      For i = 0 to UBound(ArrProcessors)
         if ArrProcessors(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Processor: " & ArrProcessors(i), "\Processor(" & ArrProcessors(i) & ")\% DPC Time", "%")
      Next
      strMsg = strMsg & CreateDisplayString("% Interrupt Time", "\Processor(_Total)\% Interrupt Time", "%")
      For i = 0 to UBound(ArrProcessors)
         if ArrProcessors(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Processor: " & ArrProcessors(i), "\Processor(" & ArrProcessors(i) & ")\% Interrupt Time", "%")
      Next
   end If
   
   if bShowDisk then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("Physical Disk")
      strMsg = strMsg & CreateDisplayString("% Idle Time", "\PhysicalDisk(_Total)\% Idle Time", "%")
      For i = 0 to UBound(ArrDisks)
         if ArrDisks(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Disk: " & ArrDisks(i), "\PhysicalDisk(" & ArrDisks(i) & ")\% Idle Time","%")
      Next
      strMsg = strMsg & CreateDisplayString("Avg. Disk sec/Transfer", "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer", "")
      For i = 0 to UBound(ArrDisks)
         if ArrDisks(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Disk: " & ArrDisks(i), "\PhysicalDisk(" & ArrDisks(i) & ")\Avg. Disk sec/Transfer","")
      Next
      strMsg = strMsg & CreateDisplayString("Disk Bytes/sec", "\PhysicalDisk(_Total)\Disk Bytes/sec", "KB")
      For i = 0 to UBound(ArrDisks)
         if ArrDisks(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Disk: " & ArrDisks(i), "\PhysicalDisk(" & ArrDisks(i) & ")\Disk Bytes/sec","KB")
      Next
      strMsg = strMsg & CreateDisplayString("Avg. Disk Queue Length", "\PhysicalDisk(_Total)\Avg. Disk Queue Length", "")
      For i = 0 to UBound(ArrDisks)
         if ArrDisks(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Disk: " & ArrDisks(i), "\PhysicalDisk(" & ArrDisks(i) & ")\Avg. Disk Queue Length","")
      Next
      strMsg = strMsg & CreateDisplayString("Split IO/Sec", "\PhysicalDisk(_Total)\Split IO/Sec", "")
      For i = 0 to UBound(ArrDisks)
         if ArrDisks(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Disk: " & ArrDisks(i), "\PhysicalDisk(" & ArrDisks(i) & ")\Split IO/Sec","")
      Next
      strMsg = strMsg & CreateDisplayString("Disk Transfers/Sec", "\PhysicalDisk(_Total)\Disk Transfers/Sec", "")
      For i = 0 to UBound(ArrDisks)
         if ArrDisks(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   Disk: " & ArrDisks(i), "\PhysicalDisk(" & ArrDisks(i) & ")\Disk Transfers/sec","")
      Next
   end if
   
   if iNICCount > 0 AND bShowNIC then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("Network Interface")
      strMsg = strMsg & "Bytes Total/sec" & vbCrLf
      For i = 0 to UBound(ArrNICs)
         if ArrNICs(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrNICs(i), "\Network Interface(" & ArrNICs(i) & ")\Bytes Total/sec","KB")
      Next
      strMsg = strMsg & "Current Bandwidth" & vbCrLf
      For i = 0 to UBound(ArrNICs)
         if ArrNICs(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrNICs(i), "\Network Interface(" & ArrNICs(i) & ")\Current Bandwidth","Mbit")
      Next
      strMsg = strMsg & "Output Queue Length" & vbCrLf
      For i = 0 to UBound(ArrNICs)
         if ArrNICs(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrNICs(i), "\Network Interface(" & ArrNICs(i) & ")\Output Queue Length","")
      Next
      strMsg = strMsg & "Packets/sec" & vbCrLf
      For i = 0 to UBound(ArrNICs)
         if ArrNICs(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrNICs(i), "\Network Interface(" & ArrNICs(i) & ")\Packets/sec","")
      Next
      strMsg = strMsg & "Packets Received Discarded" & vbCrLf
      For i = 0 to UBound(ArrNICs)
         if ArrNICs(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrNICs(i), "\Network Interface(" & ArrNICs(i) & ")\Packets Received Discarded","")
      Next
      strMsg = strMsg & "Packets Received Errors" & vbCrLf
      For i = 0 to UBound(ArrNICs)
         if ArrNICs(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrNICs(i), "\Network Interface(" & ArrNICs(i) & ")\Packets Received Errors","")
      Next
   end If
   
    if iServerWorkQueuesCount > 0 Then
      strMsg = strMsg & vbCrLf & vbCrLf
      strMsg = strMsg & CreateDisplayHeader("Server Work Queues")
      
      For i = 0 to UBound(ArrServerWorkQueues)
         If ArrServerWorkQueues(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("Active Threads("& ArrServerWorkQueues(i)&")", "\Server Work Queues(" & ArrServerWorkQueues(i) & ")\Active Threads", "")
      Next
      
      For i = 0 to UBound(ArrServerWorkQueues)
         If ArrServerWorkQueues(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("Available Work Items("& ArrServerWorkQueues(i)&")", "\Server Work Queues(" & ArrServerWorkQueues(i) & ")\Available Work Items", "")
      Next
      
      For i = 0 to UBound(ArrServerWorkQueues)
         If ArrServerWorkQueues(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("Queue Length(" & ArrServerWorkQueues(i)&")", "\Server Work Queues(" & ArrServerWorkQueues(i) & ")\Queue Length", "")
      Next
      
      For i = 0 to UBound(ArrServerWorkQueues)
         If ArrServerWorkQueues(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("Work Item Shortages(" & ArrServerWorkQueues(i) &")", "\Server Work Queues(" & ArrServerWorkQueues(i) & ")\Work Item Shortages", "")
      Next
      
      For i = 0 to UBound(ArrServerWorkQueues)
         If ArrServerWorkQueues(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("Current Clients(" & ArrServerWorkQueues(i)&")", "\Server Work Queues(" & ArrServerWorkQueues(i) & ")\Current Clients", "")
      Next
      

   end If
   
   if iTSCount > 0 then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("Terminal Services Session")
      strMsg = strMsg & "% Processor Time" & vbCrLf
      For i = 0 to UBound(ArrTS)
         if ArrTS(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrTS(i), "\Terminal Services Session(" & ArrTS(i) & ")\% Processor Time","%")
      Next
      strMsg = strMsg & "Handle Count" & vbCrLf
      For i = 0 to UBound(ArrTS)
         if ArrTS(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrTS(i), "\Terminal Services Session(" & ArrTS(i) & ")\Handle Count","")
      Next
      strMsg = strMsg & "Thread Count" & vbCrLf
      For i = 0 to UBound(ArrTS)
         if ArrTS(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrTS(i), "\Terminal Services Session(" & ArrTS(i) & ")\Thread Count","")
      Next
      strMsg = strMsg & "Private Bytes" & vbCrLf
      For i = 0 to UBound(ArrTS)
         if ArrTS(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrTS(i), "\Terminal Services Session(" & ArrTS(i) & ")\Private Bytes","MB")
      Next
      strMsg = strMsg & "Virtual Bytes" & vbCrLf
      For i = 0 to UBound(ArrTS)
         if ArrTS(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrTS(i), "\Terminal Services Session(" & ArrTS(i) & ")\Virtual Bytes","MB")
      Next
      strMsg = strMsg & "Working Set" & vbCrLf
      For i = 0 to UBound(ArrTS)
         if ArrTS(i) <> vbNullString then strMsg = strMsg & CreateDisplayString("   " & ArrTS(i), "\Terminal Services Session(" & ArrTS(i) & ")\Working Set","MB")
      Next
   end if
   
   if bShowTopN_Handle then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": Handle Count")
      objRSProcess.Sort = "Handle_Max DESC"
      if not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\Handle Count", "")
         objRSProcess.MoveNext
         iCount = iCount + 1
      Wend
   end if

   if bShowTopN_Thread then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": Thread Count")
      objRSProcess.Sort = "Thread_Max DESC"
      if not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\Thread Count", "")
         objRSProcess.MoveNext
         iCount = iCount + 1
      Wend
   end if

   if bShowTopN_PBytes then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": Private Bytes")
      objRSProcess.Sort = "PrivateBytes_Max DESC"
      if not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\Private Bytes", "MB")
         objRSProcess.MoveNext
         iCount = iCount + 1
      Wend
   end if

   if bShowTopN_VBytes then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": Virtual Bytes")
      objRSProcess.Sort = "VirtualBytes_Max DESC"
      if not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\Virtual Bytes", "MB")
         objRSProcess.MoveNext
         iCount = iCount + 1
      Wend
   end if

   if bShowTopN_WSet then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": Working Set")
      objRSProcess.Sort = "WorkingSet_Max DESC"
      if not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\Working Set", "MB")
         objRSProcess.MoveNext
         iCount = iCount + 1
      Wend
   end If 

   if bShowTopN_CPU then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": % Processor Time")
      objRSProcess.Sort = "ProcessorUsage_Avg DESC"
      If not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         If not objRSResults.BOF then objRSResults.MoveFirst
         objRSResults.Find "Counter = '\Process(" & objRSProcess("Process") & ")\% Processor Time'"
         If not objRSResults.EOF then
            ' Calculate percentage of current counter samples to total samples
            iSamplePercent = CInt(objRSResults("Samples") / iTotalSamples * 100)
            ' If individual counter samples are greater than 10% of total samples consider it a valid test
            ' We don't want to show a high cpu usage from a process that only ran for a few samples
            If iSamplePercent > 10 then
               strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\% Processor Time", "%")
               iCount = iCount + 1
            end If
         end If
         objRSProcess.MoveNext
      Wend
      
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": % Privileged Time")
      objRSProcess.Sort = "PrivilegedProcessorUsage_Avg DESC"
      If not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         If not objRSResults.BOF then objRSResults.MoveFirst
         objRSResults.Find "Counter = '\Process(" & objRSProcess("Process") & ")\% Privileged Time'"
         If not objRSResults.EOF then
            ' Calculate percentage of current counter samples to total samples
            iSamplePercent = CInt(objRSResults("Samples") / iTotalSamples * 100)
            ' If individual counter samples are greater than 10% of total samples consider it a valid test
            ' We don't want to show a high cpu usage from a process that only ran for a few samples
            If iSamplePercent > 10 then
               strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\% Privileged Time", "%")
               iCount = iCount + 1
            end If
         end If
         objRSProcess.MoveNext
      Wend
   end if

   If bShowTopN_IOData then
      strMsg = strMsg & vbCrLf & vbCrLf
      
      strMsg = strMsg & CreateDisplayHeader("TOP " & g_numInstancesToProcess & ": IO Data Bytes")
      objRSProcess.Sort = "IODataBytes_Avg DESC"
      if not objRSProcess.BOF then objRSProcess.MoveFirst
      
      iCount = 1
      While (not objRSProcess.EOF) AND (iCount <= g_numInstancesToProcess)
         if not objRSResults.BOF then objRSResults.MoveFirst
         objRSResults.Find "Counter = '\Process(" & objRSProcess("Process") & ")\IO Data Bytes/sec'"
         if not objRSResults.EOF then
            ' Calculate percentage of current counter samples to total samples
            iSamplePercent = CInt(objRSResults("Samples") / iTotalSamples * 100)
            ' If individual counter samples are greater than 10% of total samples consider it a valid test
            ' We don't want to show a high cpu usage from a process that only ran for a few samples
            if iSamplePercent > 10 then
               strMsg = strMsg & CreateDisplayString(PadStr(iCount & ".",4,jf_PadStrLeft) & objRSProcess("Process"), "\Process(" & objRSProcess("Process") & ")\IO Data Bytes/sec", "KB")
               iCount = iCount + 1
            end if
         end if
         objRSProcess.MoveNext
      Wend
   end if

   strMsg = strMsg & vbCrLf & vbCrLf & vbCrLf & vbCrLf
   strMsg = strMsg & "Report generated by   : " & pma_Name & " " & pma_Version & vbCrLf
   strMsg = strMsg & "Written By            : " & pma_Author & vbCrLf
   strMsg = strMsg & "Generated on          : " & Now() & vbCrLf
   strMsg = strMsg & "Log processing time   : " & strProcessingTime & " second(s)." & vbCrLf
   strMsg = strMsg & "Relog processing time : " & strRelogTime & " second(s)." & vbCrLf
   strMsg = strMsg & "Total Counters        : " & CStr(iNumCounters+1) & vbCrLf
   strMsg = strMsg & "Total Processes       : " & CStr(objRSProcess.RecordCount) & vbCrLf
   strMsg = strMsg & vbCrLf & "[ADDITIONAL USAGE NOTES]" & vbCrLf
   strMsg = strMsg & vbCrLf
   strMsg = strMsg & "To prevent prompting for configuration (default to '*') set the following registry value:" & vbCrLf
   strMsg = strMsg & "   HKCU\Software\Microsoft\PMAVbs\NoPrompt = 1 [REG_DWORD]"
   strMsg = strMsg & vbCrLf & vbCrLf
   strMsg = strMsg & "To change the default number for TOP 'n' processes set the following registry value:" & vbCrLf
   strMsg = strMsg & "   HKCU\Software\Microsoft\PMAVbs\NumSummaryInstances = <desired number>  [REG_DWORD] (default = 10)"
   strMsg = strMsg & vbCrLf & vbCrLf
   strMsg = strMsg & "To remove the 'Open With " & pma_Name & "' context menu delete the following registry key(s):" & vbCrLf
   strMsg = strMsg & "   BLG context menu   : " & strRegPath & vbCrLf
   strCSVReg = ReadReg("HKCR\.csv\")
   if strCSVReg <> "PerfFile" then
      strMsg = strMsg & "   CSV context menu   : HKCR\.csv\" & strCSVReg & "\shell\PMA" & vbCrLf
   end if
   
   
   objResults.Write(strMsg)
   
   objResults.Close
   
   Set objResults = Nothing
   
   ShowMsg "Completed writing results."
   
End Sub




''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Function name:   getOS 
' Determines OS by reading reg val & comparing to known values
' OS type returned as:
'    "Win95A", "Win95B", "Win98", "Win98SE", "WinME"
'    "WinNT4-Wrkstat", "WinNT4-Srvr", "WinNT4-Srvr-DC"
'    "Win2K-Wrkstat", "Win2K-Srvr", "Win2k-Srvr-DC", "WinXP-Wrkstat"
'   "Win2k3-Srvr", "Winwk3-Srvr-DC", "Vista-Wrkstat", "Win2k8-Srvr"
'  "Win2k8-Srvr-DC", "Win7-Wrkstat", "Win7-Srvr", "Win7-Srvr-DC"
'  
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function getOS()
	On Error Resume Next
	Dim oFSO, oShell
  	Const sModule = "getOS"

  	Set oFSO = CreateObject("Scripting.FileSystemObject")
  	Set oShell = CreateObject("Wscript.Shell")

	Dim sOStype, sOSversion
	sOStype = oShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
  
	If Err.Number <> 0 Then
	    ' Hex(Err.Number)="80070002"
	    ' - Could not find this key, OS must be Win9x
	    Err.Clear
	    sOStype = oShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\VersionNumber")
	    If Err.Number <> 0 Then
	      GetOS = "Unknown Win9x"
	      ' Could not pinpoint exact Win9x type
	      Exit Function  ' >>>
    	End If
	End If

	If sOStype = "LanmanNT" _
	OR sOStype = "ServerNT" _
	OR sOStype = "WinNT" Then
	    Err.Clear
	    sOSversion = oShell.RegRead(_
	      "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentVersion")
	    If Err.Number<>0 Then
		    GetOS = "Unknown NTx"
      		' Could not determine NT version
      		Exit Function  ' >>>
    	End If
  	End If

	If sOSversion = "4.0" Then
    	Select Case sOStype
      	Case "LanmanNT"
        	sOStype = "WinNT4-Srvr-DC"
        	' From HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType
      	Case "ServerNT"
        	sOStype = "WinNT4-Srvr"
        	' From HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType
      	Case "WinNT"
        	sOStype = "WinNT4-Wrkstat"
        	' From HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType
    	End Select
 	 
 	 ElseIf sOSversion = "5.0" Then
    	sOStype = "Win2K"
    	Dim sTmp
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "LanmanNT" Then
      		sTmp = "-Srvr-DC"
      		sOStype = sOStype & sTmp
		Else
      		GetOS = "Unknown Win2K"
      		' Could not pinpoint exact Win2K type
      		Exit Function  ' >>>
      	End If
      
      ElseIf sOSversion = "5.1" Then
    	sOStype = "WinXP"
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp
    	Else
      		GetOS = "Unknown WinXP"
      		' Could not pinpoint exact WinXP type
      		Exit Function  ' >>>
      		
   		End If
	  ElseIf sOSversion = "5.2" Then
    	sOStype = "Win2K3"
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp
		ElseIf sTmp = "LanmanNT" Then
        	sOStype = "Win2k3-Srvr-DC"
    	Else
      		GetOS = "Unknown Windows 2003"
      		' Could not pinpoint exact Win2K3 type
      		Exit Function  ' >>>
      End If
	
	  ElseIf sOSversion = "6.0" Then
    	sOStype = "Win2k8"		'Vista or Longhorn (Windows Server 2008)
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
			sOStype = "Vista"	'reset OS type to Vista so we return Vista-Wrkstat
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp	'We will return Win2k8-Srvr 
		ElseIf sTmp = "LanmanNT" Then
        	sOStype = "Win2k8-Srvr-DC"
    	Else
      		getOS = "Unknown Windows Vista/Longhorn"
      		' Could not pinpoint exact Vista/Windows 2008 type
      		Exit Function  ' >>>
      End If
      
      'Added this section 2/13/09 to detect Windows 7
      ElseIf sOSversion = "6.1" Then
    	sOStype = "Win7"		'Windows 7 or Windows Server 2008 R2
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp	'We will return Win7-Srvr 
		ElseIf sTmp = "LanmanNT" Then
        	sOStype = "Win7-Srvr-DC"
    	Else
      		getOS = "Unknown Windows 7/2008 R2"
      		' Could not pinpoint exact Windows 7/Windows 2008 R2 type
      		Exit Function  ' >>>
      End If
      
      ' 3.20.2012 sunilr added this section to detect Windows 8 Consumer Preview Version
      ElseIf sOSversion = "6.2" Then
    	sOStype = "Win8"		'Windows 8 Consumer Preview Version
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp	'We will return Win8-Srvr 
		ElseIf sTmp = "LanmanNT" Then
        	sOStype = "Win8-Srvr-DC"
    	Else
      		getOS = "Unknown Windows 8"
      		' Could not pinpoint exact Windows 8 type
      		Exit Function  ' >>>
      End If
      
      ElseIf sOSversion = "6.3" Then
    	sOStype = "Win8.1"		'Windows 8.1 RTM Version
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp	'We will return Win8-Srvr 
		ElseIf sTmp = "LanmanNT" Then
        	sOStype = "Win81-Srvr-DC"
    	Else
      		getOS = "Unknown Windows 8.1"
      		' Could not pinpoint exact Windows 8 type
      		Exit Function  ' >>>
      End If
      
      ElseIf sOSversion = "6.4" Then
    	sOStype = "Win10"		'Windows 10 Tech Preview
    	sTmp = oShell.RegRead(_
      	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions\ProductType")
    	If sTmp = "WinNT" Then
      		sTmp = "-Wrkstat"
      		sOStype = sOStype & sTmp
    	ElseIf sTmp = "ServerNT" Then
      		sTmp = "-Srvr"
      		sOStype = sOStype & sTmp	'We will return Win8-Srvr 
		ElseIf sTmp = "LanmanNT" Then
        	sOStype = "Win81-Srvr-DC"
    	Else
      		getOS = "Unknown Windows 10"
      		' Could not pinpoint exact Windows 8 type
      		Exit Function  ' >>>
      End If
      
  	Else
    	Select Case sOStype
      	Case "4.00.950"
        	sOStype = "Win95A"
      	Case "4.00.1111"
        	sOStype = "Win95B"
      	Case "4.03.1214"
        	sOStype = "Win95B"
      	Case "4.10.1998"
        	sOStype = "Win98"
      	Case "4.10.2222"
	        sOStype = "Win98SE"
    	Case "4.90.3000"
        	sOStype = "WinME"   ' Windows Me
      	Case Else
        	MsgBox "sOStype = " & sOStype & vbCrLf & "Could not recognize" &_
        	" this particular OS.  Please contact your system administrator.",_
        	vbCritical, "Error in module: " & sModule
    	End Select
  	End If
  	GetOS = sOStype
 	' --- CleanUp
	Set oFSO = Nothing
  	Set oShell = Nothing
  	
End Function


'*********************************************************************************
'	Subroutine: ElevateThisScript()	
'
'	Author: Steve Parr, Microsoft (stevepar@microsoft.com)
'	Last Modified:  August 2, 2007
'	
'	Purpose: (Intended for Vista and Windows Server 2008)
'	Forces the currently running script to prompt for UAC elevation if it detects
'	that the current user credentials do not have administrative privileges
'
'	If run on Windows XP this script will cause the RunAs dialog to appear if the user
'	does not have administrative rights, giving the opportunity to run as an administrator  
'
'	This Sub Attempts to call the script with its original arguments.  Arguments that contain a space
'	will be wrapped in double quotes when the script calls itself again.
'
'	Usage:  Add a call to this sub (ElevateThisScript) to the beginning of your script to ensure
'	        that the script gets an administrative token
'**********************************************************************************		
Sub ElevateThisScript()
	
	Const HKEY_CLASSES_ROOT  = &H80000000
	Const HKEY_CURRENT_USER  = &H80000001
	Const HKEY_LOCAL_MACHINE = &H80000002
	Const HKEY_USERS         = &H80000003
	const KEY_QUERY_VALUE	  = 1
	Const KEY_SET_VALUE		  = 2

	Dim scriptEngine, engineFolder, argString, arg, Args, scriptCommand, HasRequiredAccess
	Dim objShellApp : Set objShellApp = CreateObject("Shell.Application")
		
	
	scriptEngine = Ucase(Mid(Wscript.FullName,InstrRev(Wscript.FullName,"\")+1))
	engineFolder = Left(Wscript.FullName,InstrRev(Wscript.FullName,"\"))
	argString = ""
	
	Set Args = Wscript.Arguments
	
	For each arg in Args						'loop though argument array as a collection to rebuild argument string
		If instr(arg," ") > 0 Then arg = """" & arg & """"	'if the argument contains a space wrap it in double quotes
		argString = argString & " " & Arg
	Next

	scriptCommand = engineFolder & scriptEngine
		
	Dim strComputer : strComputer = "."
		
	Dim objReg, bHasAccessRight
	Set objReg=GetObject("winmgmts:"_
		& "{impersonationLevel=impersonate}!\\" &_ 
		strComputer & "\root\default:StdRegProv")
	

	'Check for administrative registry access rights
	objReg.CheckAccess HKEY_LOCAL_MACHINE, "System\CurrentControlSet\Control\CrashControl", _
		KEY_SET_VALUE, bHasAccessRight
	
	If bHasAccessRight = True Then
	
		HasRequiredRegAccess = True
		Exit Sub
		
	Else
		
		HasRequiredRegAccess = False
		objShellApp.ShellExecute scriptCommand, " """ & Wscript.ScriptFullName & """" & argString, "", "runas"
		WScript.Quit
	End If
		
	
End Sub