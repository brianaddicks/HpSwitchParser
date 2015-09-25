function Get-HpInterface {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-HpInterface: "
	
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
		# New Object
		
		$Regex = [regex] "^interface\ (.+)"
		$Match = HelperEvalRegex $Regex $line -ReturnGroupNum 1
		if ($Match) {
			$NewObject       = New-Object -TypeName HpSwitchParser.Interface
			$NewObject.Name  = $Match
			$ReturnObject   += $NewObject
		}
		
		if ($NewObject) {
			
			###########################################################################################
			# End of Section
			$Regex = [regex] "^#"
			$Match = HelperEvalRegex $Regex $line
			if ($Match) {
				$NewObject = $null
				continue
			}
			
			###########################################################################################
			# Bool Properties and Properties that need special processing
			# Eval Parameters for this section
			$EvalParams = @{}
			$EvalParams.StringToEval     = $line
			
			
			# DhcpRelayEnabled
			$EvalParams.Regex          = [regex] '^\ dhcp\ select\ relay$'
			$Eval                      = HelperEvalRegex @EvalParams
			if ($Eval) { $NewObject.DhcpRelayEnabled = $true }
			
			# DhcpRelayList
			$EvalParams.Regex          = [regex] "^\ dhcp\ relay\ server-address\ (?<ip>$IpRx)"
			$Eval                      = HelperEvalRegex @EvalParams
			if ($Eval) { $NewObject.DhcpRelayList += $Eval.Groups['ip'].Value }
			
			# Undo Vlan 1
			$EvalParams.Regex          = [regex] "^\ undo\ port\ trunk\ permit\ vlan\ 1"
			$Eval                      = HelperEvalRegex @EvalParams
			if ($Eval) { $NewObject.PermittedVlans = $NewObject.PermittedVlans | ? { $_ -ne 1 } }
			
			# IpAddress
			$EvalParams.Regex = [regex] "^\ ip\ address\ (?<ip>$IpRx)\ (?<mask>$IpRx)"
			$Eval             = HelperEvalRegex @EvalParams
			if ($Eval) {
				Write-Verbose "$VerbosePrefix Ip Found"
				$NewObject.IpAddress = $Eval.Groups['ip'].Value
				$NewObject.IpAddress += '/' + (ConvertTo-MaskLength $Eval.Groups['mask'].Value)
			}
			
			
			###########################################################################################
			# Regular Properties
			
			# Update eval Parameters for remaining matches
			$EvalParams.VariableToUpdate = ([REF]$NewObject)
			$EvalParams.ReturnGroupNum   = 1
			$EvalParams.LoopName         = 'fileloop'
			
			###############################################
			# General Properties
			
			# Description
			$EvalParams.ObjectProperty = "Description"
			$EvalParams.Regex          = [regex] "^\ description\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
			# PortLinkType
			$EvalParams.ObjectProperty = "PortLinkType"
			$EvalParams.Regex          = [regex] "^\ port\ link-type\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
		}
	}	
	return $ReturnObject
}