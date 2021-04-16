#IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools  # to allow Import-Module WebAdministration
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
# Configure IIS with powershell
Import-Module WebAdministration 

#Installers

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install webpicmd -y

#Web Deploy

choco install webdeploy -y
WebpiCmd.exe /Install /AcceptEULA /SuppressReboot /Products:WDeploy_2_1
#& "WebpiCmd-x64.exe" /Install /AcceptEULA /SuppressReboot /Products:WDeploy36NoSMO
WebpiCmd.exe /Install /AcceptEULA /SuppressReboot /Products:WDeploy36PS
# Should be uninstalled and reinstalled for some reasons...
# https://stackoverflow.com/a/40722931/7361736
choco uninstall webdeploy -y
choco install webdeploy -y
New-NetFirewallRule -DisplayName 'WebDeploy 8172' -Profile 'Private' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8172
