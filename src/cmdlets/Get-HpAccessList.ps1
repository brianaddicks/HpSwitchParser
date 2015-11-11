function Get-HpAccessList {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-HpAccessList: "
	
	$IpRx = [regex] "(\d+\.){3}\d+"
	
	$TotalLines = $ShowSupportOutput.Count
	$i          = 0 
	$StopWatch  = [System.Diagnostics.Stopwatch]::StartNew() # used by Write-Progress so it doesn't slow the whole function down
	
	$ReturnObject = @()
	
	:fileloop foreach ($line in $ShowSupportOutput) {
		$i++
		
		# Write progress bar, we're only updating every 1000ms, if we do it every line it takes forever
		
		if ($StopWatch.Elapsed.TotalMilliseconds -ge 1000) {
			$PercentComplete = [math]::truncate($i / $TotalLines * 100)
	        Write-Progress -Activity "Reading Support Output" -Status "$PercentComplete% $i/$TotalLines" -PercentComplete $PercentComplete
	        $StopWatch.Reset()
			$StopWatch.Start()
		}
		
		if ($line -eq "") { continue }
		
		###########################################################################################
		# New Acl
		
		$Regex = [regex] "^acl\ number\ (?<num>\d+)(\ name\ (?<name>.+))?"
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$NewObject         = New-Object -TypeName HpSwitchParser.AccessList
			$NewObject.Number  = $Match.Groups['num'].Value
			$NewObject.Name    = $Match.Groups['name'].Value
			$ReturnObject     += $NewObject
		}
		
		if ($NewObject) {
			
			$EvalParams = @{}
			$EvalParams.StringToEval = $line
			
			$EvalParams.Regex = [regex] "(?mx)
				^\ rule
				\ (?<number>\d+)
				\ (?<action>permit|deny)
				(\ (?<protocol>ospf|udp|tcp|icmp|ip))?
				
				# Source
				(\ 
					source\ (?<sourcenet>$IpRx)\ (?<sourcemask>$IpRx|0)
				)?
				
				# Destination
				(\ 
					destination\ (?<destnet>$IpRx)\ (?<destmask>$IpRx|0)
				)?
				
				#Destination Port
				(\ (
					destination-port\ eq\ (?<destport>\w+)|
					icmp-type\ (?<destport>\w+)
				))?"
					
			$Eval = HelperEvalRegex @EvalParams
			if ($Eval) {
				$NewRule          = New-Object -TypeName HpSwitchParser.AclRule
				$NewObject.Rules += $NewRule
				
				$NewRule.Number   = $Eval.Groups['number'].Value
				$NewRule.Action   = $Eval.Groups['action'].Value
				$NewRule.Protocol = $Eval.Groups['protocol'].Value
				
				$NewRule.Source  = $Eval.Groups['sourcenet'].Value
				$Mask = $Eval.Groups['sourcemask']
				if ($Mask.Success) {
					if ($Mask.Value -eq '0') { 
						$NewRule.Source += '/32'
					} else {
						$NewRule.Source += '/' + (32 - [int](ConvertTo-MaskLength $Mask.Value)) }
				}
				
				$NewRule.Destination  = $Eval.Groups['destnet'].Value
				$Mask = $Eval.Groups['destmask']
				if ($Mask.Success) {
					if ($Mask.Value -eq '0') { 
						$NewRule.Destination += '/32'
					} else {
						$NewRule.Destination += '/' + (32 - [int](ConvertTo-MaskLength $Mask.Value)) }
				}
				
				$NewRule.DestinationPort = $Eval.Groups['destport'].Value
			}
		}
	}	
	return $ReturnObject
}