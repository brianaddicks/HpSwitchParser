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
			$EvalParams.Regex          = [regex] '^\s+edit\ \d+'
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
				
				<#
				# Tcp Port Range
				$EvalParams.Regex          = [regex] "^\s+set\ (?<protocol>udp|tcp)-portrange\ (?<port>.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$Protocol = $Eval.Groups["protocol"].Value
					Write-Verbose $Protocol
					$List  = @()
					$Split = ($Eval.Groups["port"].Value).Trim().Split()
					Write-Verbose "port: $($Eval.Groups["port"].Value.Split())"
					foreach ($s in $Split) {
						Write-Verbose "s $s"
						$Range = ($s.split(":"))[0]
						Write-Verbose "Range $Range"
						$DashSplit = $Range.Split('-')
						if ($DashSplit[0] -eq $DashSplit[1]) {
							$Range = $DashSplit[0]
						}
						$NewObject.Value += "$Protocol/$Range"
					}
				}#>
				
				###########################################################################################
				# Regular Properties
				
				<#
				set srcintf "internal"
				set dstintf "wan1"
					set srcaddr "Grta server network"             
					set dstaddr "Forest Park Local Network"             
				set action ipsec
				set schedule "always"
					set service "ANY"             
				set inbound enable
				set outbound enable
				set vpntunnel "ForestPark VPN"
#>
				
				# Update eval Parameters for remaining matches
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
					
				$EvalParams.Regex          = [regex] '^\s+set\ srcintf\ "(.+?)"'
				$EvalParams.ObjectProperty = "SourceInterface"
				$Eval                      = HelperEvalRegex @EvalParams
				
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}