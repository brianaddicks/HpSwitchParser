function Get-HpVlan {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-HpVlan: "
	
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
		# New Interface
		
		$Regex = [regex] "^vlan\ (?<id>\d+)"
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$NewObject     = New-Object -TypeName HpSwitchParser.Vlan
			$NewObject.Id  = $Match.Groups['id'].Value
			$ReturnObject += $NewObject
		}
		
		$Regex = [regex] "^interface Vlan-interface(?<id>\d+)"
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$VlanId = $Match.Groups['id'].Value
			Write-Verbose "$VerbosePrefix Looking up vlan $VlanId"
			$NewObject = $ReturnObject | ? { $_.Id -eq $VlanId }
			if (!($NewObject)) {
				Write-Warning "No Vlan found with Id: $VlanId"
			}
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
			
			<#
			# SwitchPort
			$EvalParams.Regex          = [regex] '^\ switchport$'
			$Eval                      = HelperEvalRegex @EvalParams
			if ($Eval) { $NewInterface.Switchport.Enabled = $true }
			#>
			
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
			
			
			
		}
	}	
	return $ReturnObject
}