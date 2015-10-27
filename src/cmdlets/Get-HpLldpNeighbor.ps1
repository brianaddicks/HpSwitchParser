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
	$HpInterfaceRx = [regex] "[a-zA-Z\-]+?\d+\/\d+\/\d+\/\d+"
	
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
		
		$Regex = [regex] "^LLDP\ neighbor\-information\ of\ port\ \d+\[(?<port>$HpInterfaceRx)\]\:`$"
		$Match = HelperEvalRegex $Regex $line -ReturnGroupNum 1
		if ($Match) {
			$NewObject       = New-Object -TypeName HpSwitchParser.Neighbor
			$NewObject.Name  = $Match
			$ReturnObject   += $NewObject
		}
		
		if ($NewObject) {
			
			###########################################################################################
			# Bool Properties and Properties that need special processing
			# Eval Parameters for this section
			$EvalParams = @{}
			$EvalParams.StringToEval     = $line
			<#
			
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
			
			# PermittedVlans
			$EvalParams.Regex          = [regex] "^\ port\ trunk\ permit\ vlan\ (?<vlans>.+)"
			$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
			if ($Eval) {
				Write-Verbose "$VerbosePrefix $Eval"
				$Vlans = $Eval
				if ($Vlans -eq 'all') {
					foreach ($DefinedVlan in $DefinedVlans) {
						$NewObject.PermittedVlans += $DefinedVlan.Id
					}
				} else {
					foreach ($v in $Vlans.Split()) {
						if ($v -match "to") {
							$Range = $true
						} else {
							if ($Range) {
								for ($vCount = $LastVlan + 1;$vCount -le $v;$vCount++) {
									$NewObject.PermittedVlans += $vCount
									$Range = $false
								}
							} else {
								$NewObject.PermittedVlans += [int]$v
								$LastVlan = [int]$v
							}
						}
					}
				}
				$NewObject.PermittedVlans = $NewObject.PermittedVlans | Select -Unique
			}
			
			# IpAddress
			$EvalParams.Regex = [regex] "^\ ip\ address\ (?<ip>$IpRx)\ (?<mask>$IpRx)"
			$Eval             = HelperEvalRegex @EvalParams
			if ($Eval) {
				Write-Verbose "$VerbosePrefix Ip Found"
				$NewObject.IpAddress = $Eval.Groups['ip'].Value
				$NewObject.IpAddress += '/' + (ConvertTo-MaskLength $Eval.Groups['mask'].Value)
			}
			
			
			# TrunkPvid
			$EvalParams.ObjectProperty = "Pvid"
			$EvalParams.Regex          = [regex] "^\ port\ trunk\ pvid\ vlan\ (\d+)"
			$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
			if ($Eval) {
				$NewObject.Pvid            = [int]$Eval
			}
			#>
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
			$EvalParams.Regex          = [regex] "^Chassis\ ID\ +\:\ (.+)"
			$Eval                      = HelperEvalRegex @EvalParams
			
		}
	}
	Write-Progress -Activity "Reading Support Output" -Status "Complete" -PercentComplete 100 -Completed	
	return $ReturnObject
}