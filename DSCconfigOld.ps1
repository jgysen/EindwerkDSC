﻿Configuration NewDomain 

{

param(

[parameter(Mandatory = $true)]
[pscredential]$domainCred,

[parameter(Mandatory = $true)]
[pscredential]$safemodeAdministratorCred,

[parameter(Mandatory = $true)]
[pscredential]$passwordCred 

)

Import-DscResource -ModuleName xActiveDirectory
Import-DscResource –ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xNetworking
Import-DscResource -ModuleName xComputerManagement
Import-DscResource -ModuleName xdhcpserver
Import-DscResource -ModuleName xSmbShare 

Node $AllNodes.Where{ $_.Role -eq "Primary DC" }.NodeName
{
LocalConfigurationManager {
ActionAfterReboot = 'ContinueConfiguration'
ConfigurationMode = 'ApplyOnly'
RebootNodeIfNeeded = $true
}

xIPAddress NewIPAddress
{
IPAddress = "192.168.0.100/24"
InterfaceAlias = 'Ethernet0'
AddressFamily = "IPV4"
}

xDefaultGatewayAddress DefaultGateway
{
Address = "192.168.0.1"
InterfaceAlias = 'Ethernet0'
AddressFamily = "IPV4"
}

WindowsFeature DHCP {
DependsOn = '[xIPAddress]NewIpAddress'
Name = 'DHCP'
Ensure = 'PRESENT'
IncludeAllSubFeature = $true 

}

function Get-TargetResource {
[CmdletBinding()]
[OutputType([System.Collections.Hashtable])]
param
(
[parameter(Mandatory)]
[String]$Name,

[parameter(Mandatory)]
[String]$IPStartRange,

[parameter(Mandatory)]
[String]$IPEndRange,

[parameter(Mandatory)]
[String]$SubnetMask,

[ValidateSet('IPv4')]
[String]$AddressFamily = 'IPv4'

)

$dhcpScope = Get-DhcpServerv4Scope | Where-Object { ($_.StartRange -eq $IPStartRange) -and ($_.EndRange -eq $IPEndRange) }
if ($dhcpScope) {
$ensure = 'Present'
}
else {
$ensure = 'Absent'
}

@{
ScopeID = "192.168.0.0"
Name = "scopeAD-DC"
IPStartRange = "192.168.0.150"
IPEndRange = "192.168.0.200"
SubnetMask = "255.255.255.0"
LeaseDuration = "8:00:00"
State = "Active"
AddressFamily = 'IPv4'
Ensure = "Present"
DependsOn = "[WindowsFeature]DHCP"
}

xDhcpServerOption ServerOpt
{
ScopeID = "192.168.0.0"
DnsServerIPAddress = "192.168.0.100"
DnsDomain = "bmoos.local"
AddressFamily = "IPv4" 
Ensure = "Present"

}
}

WindowsFeature DNS { 
Ensure = "Present" 
Name = "DNS"
}

xDnsServerAddress DnsServerAddress 
{ 
Address = '127.0.0.1' 
InterfaceAlias = 'Ethernet0'
AddressFamily = 'IPv4'
DependsOn = "[WindowsFeature]DNS"
}

WindowsFeature AD-Domain-Services {

Ensure = "Present"
Name = "AD-Domain-Services"
DependsOn = "[File]ADFiles"
}

WindowsFeature RSAT-DNS-Server {
Ensure = "Present"
Name = "RSAT-DNS-Server"
DependsOn = "[WindowsFeature]DNS"
}

File ADFiles {
DestinationPath = 'C:\NTDS'
Type = 'Directory'
Ensure = 'Present'
}
WindowsFeature RSAT-AD-Tools {
Name = 'RSAT-AD-Tools'
Ensure = 'Present'
DependsOn = "[WindowsFeature]AD-Domain-Services"
}

WindowsFeature RSAT-ADDS {
Ensure = "Present"
Name = "RSAT-ADDS"
DependsOn = "[WindowsFeature]AD-Domain-Services"
}

WindowsFeature RSAT-ADDS-Tools { 
Name = 'RSAT-ADDS-Tools'
Ensure = 'Present'
DependsOn = "[WindowsFeature]RSAT-ADDS"
}

WindowsFeature ADDSInstall {
Ensure = "Present"
Name = "AD-Domain-Services"
}

WindowsFeature ADDSTools {
Ensure = 'Present'
Name = 'RSAT-ADDS'
}

WindowsFeature RSAT-AD-AdminCenter {
Name = 'RSAT-AD-AdminCenter'
Ensure = 'Present'
DependsOn = "[WindowsFeature]AD-Domain-Services"
}

WindowsFeature IIS {
Ensure = 'Present'
Name = 'Web-Server'
}

WindowsFeature IISConsole {
Ensure = 'Present'
Name = 'Web-Mgmt-Console'
DependsOn = '[WindowsFeature]IIS'
}

WindowsFeature IISScriptingTools {
Ensure = 'Present'
Name = 'Web-Scripting-Tools'
DependsOn = '[WindowsFeature]IIS'
}

File Indexfile {
Ensure = 'Present'
Type = 'file'
DestinationPath = "C:\inetpub\wwwroot\index.html"
Contents = "<html>
<header><title>Welkom</title></header>
<body>
Welkom bij browerij Moos, waar drinken op de werkvloer mag!
</body>
</html>"
}

xFirewall IISinboundwebserviceshttpTCP
{
Name = "IISinboundwebserviceshttpTCP"
Ensure = "Present"
Direction = "inbound"
Description = "allow HTTP traffic for Internet Information Services (IIS) [TCP 80]"
Profile = "Domain"
Protocol = "TCP"
LocalPort = ("80")
Action = "Allow"
Enabled = "True"
}

User LocalAdmin {
UserName = "joris"
FullName = "joris gysen"
Ensure = 'Present'
Password = $passwordCred
Description = 'User created by DSC'
PasswordNeverExpires = $true
PasswordChangeNotAllowed = $true
}

Group Marketing {
GroupName = 'GRmarketing'
Ensure = 'Present'
Members = @( 'joris' )
}

Group HR {
GroupName = 'GRHR'
Ensure = 'Present'
Members = @( 'joris' )
}

Group Production {
GroupName = 'GRProduction'
Ensure = 'Present'
Members = @( 'joris' )
}

Group Logistics {
GroupName = 'GRLogistics'
Ensure = 'Present'
Members = @( 'joris' )
}

Group Research {
GroupName = 'GRResearch'
Ensure = 'Present'
Members = @( 'joris' )
}

File Share {
Ensure = "present"
DestinationPath = "c:\share"
Type = "Directory"
}

File Marketing {
Ensure = "present"
DestinationPath = "c:\share\Marketing"
Type = "Directory"
}

File HR {
Ensure = "present"
DestinationPath = "c:\share\HR"
Type = "Directory"
}

File Production {
Ensure = "present"
DestinationPath = "c:\share\Production"
Type = "Directory"
}

File Logistics {
Ensure = "present"
DestinationPath = "c:\share\Logistics"
Type = "Directory"
}

File Research {
Ensure = "present"
DestinationPath = "c:\share\Research"
Type = "Directory"
}

xSmbShare Marketing 
{ 
Ensure = "Present" 
Name = "marketing" 
Path = "C:\share\Marketing" 
ChangeAccess = "GRmarketing" 
} 

xSmbShare HR 
{ 
Ensure = "Present" 
Name = "HR" 
Path = "C:\share\HR"
ChangeAccess = "GRHR" 
} 

xSmbShare Production
{ 
Ensure = "Present" 
Name = "Production" 
Path = "C:\share\Production" 
ChangeAccess = "GRproduction" 
} 

xSmbShare Logistics 
{ 
Ensure = "Present" 
Name = "Logistics" 
Path = "C:\share\logistics" 
ChangeAccess = "GRlogistics" 
} 

xSmbShare Research
{ 
Ensure = "Present" 
Name = "Research" 
Path = "C:\share\Research" 
ChangeAccess = "GRresearch" 
} 

xADDomain FirstDC
{
DomainName = "bmoos.local"
DomainNETBIOSName = "BMOOS"
DomainAdministratorCredential = $domainCred
SafemodeAdministratorPassword = $safemodeAdministratorCred
DatabasePath = 'C:\NTDS' 
LogPath = 'C:\NTDS' 
DependsOn = "[WindowsFeature]ADDSInstall"
}

}#Node

}#Config Closing

#AD Config

$ADConfig = @{
AllNodes = @(
@{
NodeName = "localhost"
Role = "Primary DC"
DomainName = "bmoos.local"
RetryCount = 20
RetryIntervalSec = 30
PsDscAllowPlainTextPassword = $true
PSDscAllowDomainUser = $true
}
)
}

NewDomain -ConfigurationData $ADConfig `
-safemodeAdministratorCred (Get-Credential -UserName '(Administrator)' `
-Message "New Domain Safe Mode Administrator Password") `
-domainCred (Get-Credential -UserName bmoos.local\administrator `
-Message "New Domain Admin Credential") `
-passwordCred (Get-Credential -UserName '(joris gysen)' `
-Message "New Domain Admin Credential") `

Set-DscLocalConfigurationManager -Path .\NewDomain -Verbose -Force 
Start-dscconfiguration .\NewDomain -wait -verbose
