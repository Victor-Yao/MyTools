$paths = @(
  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
  "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$items = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match "WebView2|Edge WebView2" } |
  Select-Object @{
      Name="RegistryPath"; Expression={ $_.PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::','' }
    }, DisplayName, DisplayVersion, SystemComponent

if (-not $items) {
  Write-Host "No WebView2 / Edge WebView2 uninstall entries were found." -ForegroundColor Yellow
  return
}

$i = 0
$items | ForEach-Object {
  $i++
  Write-Host ("=" * 90)
  Write-Host ("[{0}] {1}" -f $i, $_.DisplayName)
  Write-Host ("Version         : {0}" -f $_.DisplayVersion)
  Write-Host ("SystemComponent : {0}" -f $_.SystemComponent)
  Write-Host ("Registry Path   : {0}" -f $_.RegistryPath)
}
Write-Host ("=" * 90)
