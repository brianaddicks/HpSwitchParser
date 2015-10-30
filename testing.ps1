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

$global:ConfigDir  = "c:\temp\aps2\carver"
$global:ConfigFile = $ConfigDir + '\10.20.104.1.txt'
$Global:Config     = gc $ConfigFile
<#
function HelperGetSwitchConfig {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False)]
		[string]$RemoteHost,
		
		[Parameter(Mandatory=$False)]
		[string]$Username,
		
		[Parameter(Mandatory=$False)]
		[string]$Password,
		
		[Parameter(Mandatory=$False)]
		[string]$PromptString,
		
		[Parameter(Mandatory=$False)]
		[string]$ExitCommand,
		
		[Parameter(Mandatory=$True,ParameterSetName="telnet")]
		[switch]$TryTelnet
	)
	
	$Results  = ""
	$NewObject           = "" | Select IpAddress,RawOutput,Neighbors,Routes,Status
	$NewObject.IpAddress = $RemoteHost

	Start-AwaitSession
	Send-AwaitCommand "plink $Username@$RemoteHost"
	Write-Verbose "Attempting to connect to $RemoteHost over ssh"
	
	
	try {
		$Results += Wait-AwaitResponse "assword:"
		Write-Verbose "ssh succeeded"
	} catch {
		Write-Verbose "ssh failed, attempting telnet"
		Send-AwaitCommand "plink -telnet $RemoteHost"
		try {
			$Results += Wait-AwaitResponse "Username:" -StopOnError
			Write-Verbose "telnet succeeded"
			Send-AwaitCommand $Username
		} catch {
			$NewObject.Status = "timeout"
			return $NewObject
		}
	}
		
	$Results += Wait-AwaitResponse "assword:" -StopOnError
	Send-AwaitCommand $Password
	Write-Verbose "Password sent"
	
	$Results += Wait-AwaitResponse $PromptString -StopOnError
	Send-AwaitCommand "screen-length disable"
	Write-Verbose "Disabling screen paging"
	
	try {
		$CheckForError = Wait-AwaitResponse "% Unrecognized command found at"
		$ReceiveRemaining = Receive-AwaitResponse
		Stop-AwaitSession
		$NewObject.Status = "invalid commands"
		return $NewObject 
	} catch {}
	
	$Results += Wait-AwaitResponse $PromptString -StopOnError
	Send-AwaitCommand "display current-configuration"
	Write-Verbose "Getting configuration"
	
	$Results += Wait-AwaitResponse $PromptString -StopOnError
	Send-AwaitCommand "display lldp neighbor-information verbose"
	Write-Verbose "Getting lldp neighbors verbose"
	$CheckForError = Wait-AwaitResponse $PromptString 
	if ($CheckForError -match "Too many parameters") {
		Write-Verbose "wrong command, trying without verbose"
		Send-AwaitCommand "display lldp neighbor-information"
		$Results += Wait-AwaitResponse $PromptString -StopOnError
	} else {
		Write-Verbose "no errors"
		$Results += $CheckForError
	}
	
	Send-AwaitCommand "display ip routing-table"
	Write-Verbose "Getting active Routes"
	$Results += Wait-AwaitResponse $PromptString -StopOnError
	
	Send-AwaitCommand $ExitCommand
	Write-Verbose "exiting plink sessions"
	
	$Results += Receive-AwaitResponse
	Write-Verbose "Gathering results"
	
	Stop-AwaitSession
	Write-Verbose "Exiting Await session"
	
	$Results = $Results -split "`r`n"
	
	$NewObject.RawOutput = $Results
	$VerbosePreference = "silentlycontinue"
	$NewObject.Neighbors = Get-HpLldpNeighbor $NewObject.RawOutput
	$NewObject.Status    = "complete"
	
	return $NewObject
}

$IpRx = [regex]'(\d+\.){3}\d+'
$Username = "brian.addicks"
$Password = 'P^uvXHt!BeG01huf'
$RemoteHost = '10.90.240.1'
$RemoteHost = '10.210.240.1'

$PromptString = '>'
$ExitCommand  = 'quit'

$ConfigParams = @{
	'UserName'     = $Username 
	'Password'     = $Password
	'RemoteHost'   = $RemoteHost
	'PromptString' = $PromptString
	'ExitCommand'  = $ExitCommand
	'TryTelnet'    = $True }

$LogDir = "c:\temp\aps2"

$Switches  = @()
$Switches += HelperGetSwitchConfig @ConfigParams -verbose
$ValidSwitches = @()

foreach ($Switch in $Switches) {
	$Neighbors = $Switch.Neighbors | ? { ( $_.Capabilities -notmatch "phone" ) -and ( $IpRx.Match($_.IpAddress).Success) }
	
	foreach ($Neighbor in $Neighbors) {
		$NewObject           = "" | Select IpAddress,RawOutput,Neighbors,Routes,Status
		$NewObject.IpAddress = $Neighbor.IpAddress
		
		$Lookup = $Switches | ? { $_.IpAddress -eq $NewObject.IpAddress }
		if (!($Lookup)) { $Switches += $NewObject }
	}
}

$ValidSwitches = $Switches | ? { (!( $_.Status )) }

while ($ValidSwitches.Count -ne 0) {
	$i = 0
	
	foreach ($Switch in $ValidSwitches) {
		$Switches = $Switches | ? { $_ -ne $Switch }
		$i++
		$PercentCount = $ValidSwitches.Count
		$PercentComplete = [math]::truncate($i / $PercentCount * 100)
		$CompleteSwitches = ($Switches | ? { $_.Status -eq "complete" }).Count
		$TimeoutSwitches  = ($Switches | ? { $_.Status -eq "timeout" }).Count
		Write-Progress -Activity "Trying neighbors for $($Switch.IpAddress)" -Status "$PercentComplete% ($i/$PercentCount) | Complete: $CompleteSwitches | Timeout: $TimeoutSwitches" -PercentComplete $PercentComplete
		
		$ConfigParams.RemoteHost = $Switch.IpAddress
		$Switches += HelperGetSwitchConfig @ConfigParams -Verbose
		
		
	}

	Write-Progress -Activity "complete" -Status "complete" -PercentComplete 100 -Completed
	
	foreach ($Switch in $Switches) {
		$Neighbors = $Switch.Neighbors | ? { ( $_.Capabilities -notmatch "phone" ) -and ( $IpRx.Match($_.IpAddress).Success) }
		
		foreach ($Neighbor in $Neighbors) {
			$NewObject           = "" | Select IpAddress,RawOutput,Neighbors,Routes,Status
			$NewObject.IpAddress = $Neighbor.IpAddress
			
			$Lookup = $Switches | ? { $_.IpAddress -eq $NewObject.IpAddress }
			if (!($Lookup)) { $Switches += $NewObject }
		}
	}	
	$ValidSwitches = $Switches | ? { (!($_.Status)) }
}

<#
Start-AwaitSession
Send-AwaitCommand "plink $Username@192.168.1.254"
Wait-AwaitResponse "password:"
Stop-AwaitSession



$AllNeighbors = @()

foreach ($s in $Switches) { 
	if ($s.RawOutput) {
		$s.RawOutput | Out-File "$LogDir\$($s.IpAddress).txt"
	}
	
	if ($s.Neighbors) {
		$AllNeighbors += $s.Neighbors
	}
}

#>