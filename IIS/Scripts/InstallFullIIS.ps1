# Ensure running with administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!" 
    Break
}  

# Import Server Manager Module
Import-Module ServerManager

# Check if IIS is installed
if ((Get-WindowsFeature -Name Web-Server).InstallState -eq 'Installed')
{
    Write-Output "IIS is already installed."
}
else
{
    # Install IIS with all features
    Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools
    Write-Output "IIS has been installed with all features."
}
