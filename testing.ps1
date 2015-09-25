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

$global:ConfigDir = "c:\temp\aps"
$global:ConfigFile = $ConfigDir + '\hp-core.txt'
$Global:Config = gc $ConfigFile