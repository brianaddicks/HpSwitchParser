function Get-FgPolicy {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-FgPolicy: "
	
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
		# Section Start
		
		$Regex = [regex] "^config\ firewall\ policy"
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$Section = $true
			Write-Verbose "Section started"
		}
		
		if ($Section) {
			#Write-Verbose $line
			###########################################################################################
			# End of Section
			$Regex = [regex] '^end$'
			$Match = HelperEvalRegex $Regex $line
			if ($Match) {
				$NewObject = $null
				break
			}
			
			###########################################################################################
			# Bool Properties and Properties that need special processing
			# Eval Parameters for this section
			$EvalParams              = @{}
			$EvalParams.StringToEval = $line
			
			
			# New Address Object
			$EvalParams.Regex          = [regex] '^\s+edit\ (\d+)'
			$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
			if ($Eval) {
				$NewObject       = New-Object FortiShell.Policy
				$NewObject.Number  = $Eval
				$ReturnObject   += $NewObject
				Write-Verbose "object created: $($NewObject.Number)"
			}
			if ($NewObject) {
				
				###########################################################################################
				# Special Properties
				
				# Inbound
				$EvalParams.Regex          = [regex] "^\s+set\ inbound\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq "enable") {
					$NewObject.Inbound = $true
				}
				
				# Outbound
				$EvalParams.Regex          = [regex] "^\s+set\ outbound\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq "enable") {
					$NewObject.Outbound = $true
				}
				
				###########################################################################################
				# Regular Properties
				
				# Update eval Parameters for remaining matches
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
				
				# SourceInterface	
				$EvalParams.Regex          = [regex] '^\s+set\ srcintf\ "(.+?)"'
				$EvalParams.ObjectProperty = "SourceInterface"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# SourceInterface	
				$EvalParams.Regex          = [regex] '^\s+set\ dstintf\ "(.+?)"'
				$EvalParams.ObjectProperty = "DestinationInterface"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# SourceAddress	
				$EvalParams.Regex          = [regex] '^\s+set\ srcaddr\ "(.+?)"'
				$EvalParams.ObjectProperty = "SourceAddress"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# DestinationAddress
				$EvalParams.Regex          = [regex] '^\s+set\ dstaddr\ "(.+?)"'
				$EvalParams.ObjectProperty = "DestinationAddress"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# Action	
				$EvalParams.Regex          = [regex] '^\s+set\ action\ (.+)'
				$EvalParams.ObjectProperty = "Action"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# Schedule
				$EvalParams.Regex          = [regex] '^\s+set\ schedule\ "(.+?)"'
				$EvalParams.ObjectProperty = "Schedule"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# Service
				$EvalParams.Regex          = [regex] '^\s+set\ service\ "(.+?)"'
				$EvalParams.ObjectProperty = "Service"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# VpnTunnel
				$EvalParams.Regex          = [regex] '^\s+set\ vpntunnel\ "(.+?)"'
				$EvalParams.ObjectProperty = "VpnTunnel"
				$Eval                      = HelperEvalRegex @EvalParams
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}