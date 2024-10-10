# usage: ./IISLog2Excel.ps1 -logDir "C:\Users\weyao\CodeRepos\MyTools\Test"

# script parameters
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [string]$logDir
)

# *****functions****
function Invoke-LogParser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath,
        [Parameter(Mandatory = $true)]
        [string]$csvFilePath
    )
    
    $LogParser = "C:\Program Files (x86)\Log Parser 2.2\logparser.exe"
    $LogParserArgs = "-i:w3c -q:on -o:csv"
    $fields = "date,time,c-ip,cs-username,s-ip,s-port,cs-method,cs-uri-stem,sc-status,sc-substatus,sc-win32-status,x-session,x-fullpath"
    $sqlCmd = "`"SELECT $fields FROM $LogFilePath`" >> `"$csvFilePath`""

    $LogParserCommand = "& `"$LogParser`" $LogParserArgs $sqlCmd"

    try {
        Invoke-Expression $LogParserCommand -ErrorAction Stop
        return $true
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $($_.Exception.Message)
        return $false
    }
}

function LoadCsv2Excel {
    param (
        [Parameter(Mandatory = $true)]
        $csvFiles,
        [Parameter(Mandatory = $true)]
        [string]$excelFile
    )

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false

    $workbook = $excel.Workbooks.Open($excelFile)
    
    foreach ($file in $csvFiles) {
        $csvFile = $file.FullName
        # Create a new sheet and set it as active
        $newSheet = $workbook.Sheets.Add()
        $newSheet.Activate()

        $queryTable = $newSheet.QueryTables.Add("TEXT;" + $csvFile, $newSheet.Range("A1"))
        $queryTable.Name = "CSV Data"
        $queryTable.FieldNames = $true
        $queryTable.TextFileParseType = [Microsoft.Office.Interop.Excel.XlTextParsingType]::xlDelimited
        $queryTable.TextFileCommaDelimiter = $true
        $queryTable.Refresh() | Out-Null

        # use csv file name as sheet name 
        $newSheet.Name = (Split-Path $csvFile -Leaf).Split(".")[0]
        Remove-Item $csvFile
    }

    # $workbook.SaveAs($excelFile, [Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook)
    $workbook.Save()
    $workbook.Close()
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

function CreateExcelFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$excelFile
    )

    # Create a new Excel Application object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $true

    # Create a new workbook
    $workbook = $excel.Workbooks.Add()

    # Save the workbook to a new file
    $workbook.SaveAs($excelFile)

    # Close the workbook and the Excel application
    $workbook.Close()
    $excel.Quit()

    # Release the ComObject resources
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

function SearchFiles {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$directory,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$searchPattern
    )

    # Validate the directory path
    if (-not (Test-Path -Path $directory -PathType Container)) {
        Write-Error "Directory '$directory' does not exist."
        return
    }

    # Get files list and group them by parent folder
    return Get-ChildItem -Path $directory -Filter $searchPattern -Recurse | Group-Object { $_.Directory.Name }
}
# *****functions****


# convert IIS to CSV 
$iisGroups = SearchFiles -directory $logDir -searchPattern "u_ex*.log"
foreach ($iisGroup in $iisGroups) {
    foreach ($file in $iisGroup.Group) {
        $iisLog = $file.FullName
        $csvFile = $iisLog.Replace(".log", ".csv")
        if (Test-Path $csvFile) {
            Remove-Item $csvFile
        }

        $result = Invoke-LogParser -LogFilePath $iisLog -csvFilePath $csvFile
        if (!$result) {
            Write-Output "Invoke-LogParser failed"
            Write-Output "IIS Log: $iisLog"
            break
        }
    }
}
Write-Output "Invoke-LogParser completed"

# Load CSV files to Excel
$csvGroups = SearchFiles -directory $logDir -searchPattern "u_ex*.csv"
foreach ($csvGroup in $csvGroups) {
    $csvDir = Split-Path $csvGroup.Group[0].FullName
    $excelFile = Join-Path -Path $csvDir -ChildPath ($csvGroup.Name + ".xlsx")

    if (-not (Test-Path $excelFile)) { 
        CreateExcelFile -excelFile $excelFile
    }

    LoadCsv2Excel -csvFiles $csvGroup.Group -excelFile $excelFile
    # Remove-Item $csvFile
}
Write-Output "Load csv to excel completed"