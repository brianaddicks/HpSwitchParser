function Get-FgStaticRoute {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$IpRx = [regex] "(\d+\.){3}\d+"
	$VerbosePrefix = "Get-FgStaticRoute: "
	
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
		
		$Regex = [regex] "^config\ router\ static"
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
			$EvalParams.Regex          = [regex] '^\s+edit\ "(.+?)"'
			$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
			if ($Eval) {
				$NewObject         = New-Object FortiShell.Route
				$NewObject.Number  = $Eval
				$ReturnObject     += $NewObject
				Write-Verbose "object created: $($NewObject.Number)"
			}
			if ($NewObject) {
				
				###########################################################################################
				# Special Properties
				
				# Tcp Port Range
				$EvalParams.Regex          = [regex] "^\s+set\ dst\ (?<network>$IpRx)\ (?<mask>$IpRx)"
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Destination  = $Eval.Groups['network'].Value
					$NewObject.Destination += '/'
					$NewObject.Destination += (ConvertTo-MaskLength $Eval.Groups['mask'].Value)
				}
				
				###########################################################################################
				# Regular Properties
				
				# Update eval Parameters for remaining matches
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
					
				# SourceInterface	
				$EvalParams.Regex          = [regex] '^\s+set\ device\ "(.+?)"'
				$EvalParams.ObjectProperty = "Interface"
				$Eval                      = HelperEvalRegex @EvalParams
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}