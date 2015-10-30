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
			<#
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
			
			# Name
			$EvalParams.ObjectProperty = "Name"
			$EvalParams.Regex          = [regex] "^\ name\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
			# Description
			$EvalParams.ObjectProperty = "Description"
			$EvalParams.Regex          = [regex] "^\ description\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			#>
		}
	}	
	return $ReturnObject
}