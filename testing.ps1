[CmdletBinding()]
Param (
    [Parameter(Mandatory=$False,Position=0)]
	[switch]$PushToStrap
)

#$VerbosePreference = "Continue"

if ($PushToStrap) {
    & ".\buildmodule.ps1" -PushToStrap
} else {
    & ".\buildmodule.ps1"
}

ipmo .\*.psd1

$global:ConfigDir  = "\\vmware-host\Shared Folders\ShareFile\Shared Folders\LTG Engineering\Customers\SRTA\Project Data\Assessment\GRTA"
$global:ConfigFile = $ConfigDir + '\192.168.3.254.cfg'
$Global:Config     = gc $ConfigFile

