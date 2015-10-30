function Get-HpLldpNeighbor {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-HpLldpNeighbor: "
	
	$IpRx = [regex] "(\d+\.){3}\d+"
	$HpInterfaceRx = [regex] "[a-zA-Z\-]+?\d+\/\d+\/\d+(\/\d+)?"
	
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
		}
		
		if ($line -eq "") { continue }
		
		###########################################################################################
		# New Object
		
		$Regex = [regex] "^LLDP\ neighbor\-information\ of\ port\ \d+\[($HpInterfaceRx)\]\:`$"
		$Match = HelperEvalRegex $Regex $line -ReturnGroupNum 1
		if ($Match) {
			$NewObject       = New-Object -TypeName HpSwitchParser.Neighbor
			$NewObject.LocalPort  = $Match
			$ReturnObject   += $NewObject
		}
		
		if ($NewObject) {
			
			###########################################################################################
			# Bool Properties and Properties that need special processing
			# Eval Parameters for this section
			$EvalParams = @{}
			$EvalParams.StringToEval     = $line

			###########################################################################################
			# Regular Properties
			
			# Update eval Parameters for remaining matches
			$EvalParams.VariableToUpdate = ([REF]$NewObject)
			$EvalParams.ReturnGroupNum   = 1
			$EvalParams.LoopName         = 'fileloop'
			
			###############################################
			# General Properties
			
			# ChassisId
			$EvalParams.ObjectProperty = "ChassisId"
			$EvalParams.Regex          = [regex] "^\ +Chassis\ ID\ +\:\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
			# RemotePort
			$EvalParams.ObjectProperty = "RemotePort"
			$EvalParams.Regex          = [regex] "^\ +Port\ ID\ +\:\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
			# SystemName
			$EvalParams.ObjectProperty = "SystemName"
			$EvalParams.Regex          = [regex] "^\ +System\ name\ +\:\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
			# IpAddress
			$EvalParams.ObjectProperty = "IpAddress"
			$EvalParams.Regex          = [regex] "^\ +Management\ address\ +\:\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
			# Capabilities
			$EvalParams.ObjectProperty = "Capabilities"
			$EvalParams.Regex          = [regex] "^\ +System\ capabilities\ supported\ +\:\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
		}
	}
	Write-Progress -Activity "Reading Support Output" -Status "Complete" -PercentComplete 100 -Completed	
	return $ReturnObject | Select * -Unique
}