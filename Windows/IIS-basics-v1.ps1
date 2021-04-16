Set-ExecutionPolicy Bypass -Scope Process

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

#Url Rewrite

choco install urlrewrite --version=2.0.2

#Redirection 80->443

$RuleName = 'http to https'
$Inbound = '(.*)'
$Outbound = 'https://{HTTP_HOST}{REQUEST_URI}'
$Site = 'IIS:\Sites\Default Web Site'
$Root = 'system.webServer/rewrite/rules'
$Filter = "{0}/rule[@name='{1}']" -f $Root, $RuleName

Add-WebConfigurationProperty -PSPath $Site -filter $Root -name '.' -value @{name=$RuleName; patterSyntax='Regular Expressions'; stopProcessing='True'}
Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/match" -name 'url' -value $Inbound
Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/conditions" -name '.' -value @{input='{HTTPS}'; matchType='0'; pattern='^OFF$'; ignoreCase='True'; negate='False'}
Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/action" -name 'type' -value 'Redirect'
Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/action" -name 'url' -value $Outbound

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
