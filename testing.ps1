[CmdletBinding()]
Param (
    [Parameter(Mandatory=$False,Position=0)]
	[switch]$PushToStrap
)

$VerbosePreference = "Continue"

if ($PushToStrap) {
    & ".\buildmodule.ps1" -PushToStrap
} else {
    & ".\buildmodule.ps1"
}

ipmo .\*.psd1

$global:ConfigDir = "$Sharefile\LTG Engineering\Customers\Georgia Perimeter College\Palo Alto"
$global:ConfigFile = $ConfigDir + '\Dun_Core.log'
$Global:Config = gc $ConfigFile

$global:device = New-Object CiscoParser.Device
$device.Name = "Dun_Core"
$device.Interfaces = Get-CiscoInterface $Config
$device.NetworkObjects = Get-CiscoNetworkObject $Config
$device.NetworkObjects += Get-CiscoObjectGroup $Config
$Device.AccessLists = Get-CiscoAccessList $Config -Verbose

# Create Expanded Object List
#$global:ExpandedObjectList = $Device.NetworkObjects | Select Name,@{N="Expanded";E={Resolve-CiscoObject $_ $Device.NetworkObjects}}

$AclArray = @()
$VerbosePreference = Continue

foreach ($i in $device.Interfaces) {
	Write-Verbose $i.Name
	if ($i.Layer3.AccessGroup.Name) {
		$Acl = $Device.AccessLists | ? { $_.name -eq $i.Layer3.AccessGroup.Name }
		foreach ($a in $acl.Rules) {
			$NewObject = "" | Select Name,IpAddress,Acl,Number,Action,Protocol,
			                         SourceAddress,SourcePort,
									 DestinationAddress,DestinationPort,
									 Remark
			
			$NewObject.Name               = $i.Name
			$NewObject.IpAddress          = $i.Layer3.IpAddress
			$NewObject.Acl                = $Acl.Name
			$NewObject.Number             = $a.Number
			$NewObject.Action             = $a.Action
			$NewObject.Protocol           = $a.Protocol
			$NewObject.SourceAddress      = $a.SourceAddress
			$NewObject.SourcePort         = $a.SourcePort
			$NewObject.DestinationAddress = $a.DestinationAddress
			$NewObject.DestinationPort    = $a.DestinationPort
			$NewObject.Remark             = $a.Remark
			
			$AclArray += $NewObject
		}
	}
}

$AclArray | Export-Csv "$ConfigDir\Dun_Core.csv" -NoTypeInformation
& "$ConfigDir\Dun_Core.csv"