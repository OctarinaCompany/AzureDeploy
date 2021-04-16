[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [string]$Options,
    [string]$HostName
)

$startTime = get-date

function Show-TimeSpan([TimeSpan]$ts) {
	$d = $ts.Days; $h = $ts.Hours; $m = $ts.Minutes; $as = "","s"
	$res = $(if ($d) { "{0} day{1}," -f $d, $as[$d -gt 1] }
  if ($h) { "{0} hour{1}," -f $h, $as[$h -gt 1] }
  if ($m) { "{0} minute{1}," -f $m, $as[$m -gt 1] }
  "{0} second{1}" -f $ts.Seconds,$as[$ts.Seconds -gt 1]) -join ""
	#Write-Host $res -foregroundcolor "cyan"
  return $res.Trim() + "."
}

### Init

Set-ExecutionPolicy Bypass -Scope Process # IMPORTANT for IIS installation.

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

& "C:\ProgramData\chocolatey\bin\choco.exe" install webpicmd -y

Import-Module WebAdministration # Configure IIS with powershell

$OptionsArgs = $Options.Split(",") | Select-Object $_

### Install Options

if($OptionsArgs.Contains("IIS"))
{
    Write-Information "### IIS ###"
    # https://weblog.west-wind.com/posts/2017/may/25/automating-iis-feature-installation-with-powershell
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
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets

    & "C:\ProgramData\chocolatey\bin\choco.exe" install dotnet-5.0-windowshosting -y

    & "C:\ProgramData\chocolatey\bin\choco.exe" install urlrewrite -y
}

if($OptionsArgs.Contains("WebDeploy"))
{
    Write-Information "### WebDeploy ###"

    & "C:\ProgramData\chocolatey\bin\choco.exe" install webdeploy -y

    & "C:\ProgramData\chocolatey\bin\WebpiCmd-x64.exe" /Install /AcceptEULA /SuppressReboot /Products:WDeploy_2_1

    #& "WebpiCmd-x64.exe" /Install /AcceptEULA /SuppressReboot /Products:WDeploy36NoSMO

    & "C:\ProgramData\chocolatey\bin\WebpiCmd-x64.exe" /Install /AcceptEULA /SuppressReboot /Products:WDeploy36PS

    # Should be uninstalled and reinstalled for some reasons...
    #https://stackoverflow.com/a/40722931/7361736

    & "C:\ProgramData\chocolatey\bin\choco.exe" uninstall webdeploy -y

    & "C:\ProgramData\chocolatey\bin\choco.exe" install webdeploy -y

    New-NetFirewallRule -DisplayName 'WebDeploy 8172' -Profile 'Private' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8172
}

if($OptionsArgs.Contains("SSL"))
{
    if($HostName -ne $null)
    {
      Write-Information "### SSL ###"

      # IIS Binding
      $SiteIIS = "Default Web Site"
      
      Remove-WebBinding -Name $SiteIIS  -HostHeader "" -IPAddress "*" -Port 80
      
      New-WebBinding -name $SiteIIS -Protocol "http" -HostHeader $HostName -IPAddress "*" -Port 80
      
      New-WebBinding -name $SiteIIS -Protocol "https" -HostHeader $HostName -IPAddress "*" -Port 443
      
      # Create certificate

      & "C:\ProgramData\chocolatey\bin\choco.exe" install win-acme -y

      & "C:\ProgramData\chocolatey\bin\wacs.exe" --target iis --host $HostName --siteid 1 --accepttos --emailaddress void@dummy.com
     
      # Certificate Bind

      $Certificate = Get-ChildItem "cert:\LocalMachine\WebHosting" | where-object { $_.Subject -like "*$HostName*" }
      
      $Binding = Get-WebBinding -Name $SiteIIS -Protocol "https"
      
      $Binding.AddSslCertificate($Certificate.GetCertHashString(), "WebHosting")

      # Redirection 80->443

      $RuleName = 'http to https'
      
      $Inbound = '(.*)'
      $Outbound = 'https://{HTTP_HOST}{REQUEST_URI}'
      $Site = 'IIS:\Sites\' + $SiteIIS
      $Root = 'system.webServer/rewrite/rules'
      $Filter = "{0}/rule[@name='{1}']" -f $Root, $RuleName
      
      Add-WebConfigurationProperty -PSPath $Site -filter $Root -name '.' -value @{name=$RuleName; patterSyntax='Regular Expressions'; stopProcessing='True'}
      Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/match" -name 'url' -value $Inbound
      Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/conditions" -name '.' -value @{input='{HTTPS}'; matchType='0'; pattern='^OFF$'; ignoreCase='True'; negate='False'}
      Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/action" -name 'type' -value 'Redirect'
      Set-WebConfigurationProperty -PSPath $Site -filter "$Filter/action" -name 'url' -value $Outbound

    }
    else 
    {
        Write-Error "HostName argument is null with 'SSL' option"
    }
}

if($OptionsArgs.Contains("VSCode"))
{
  Write-Information "### VSCode ###"
  & "C:\ProgramData\chocolatey\bin\choco.exe" install vscode -y
}

if($OptionsArgs.Contains("Chrome"))
{
  Write-Information "### Chrome ###"
  & "C:\ProgramData\chocolatey\bin\choco.exe" install GoogleChrome -y
}

Set-TimeZone -Id "W. Europe Standard Time" -PassThru

net stop was /y
net start w3svc

Write-Host
Write-Host (Show-TimeSpan ($(get-date) - $startTime))
Write-Host
