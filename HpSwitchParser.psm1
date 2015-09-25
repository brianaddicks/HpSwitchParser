###############################################################################
## Start Powershell Cmdlets
###############################################################################

###############################################################################
# Get-HpInterface

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
	$DefinedVlans = Get-HpVlan $ShowSupportOutput
	
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

###############################################################################
# Get-HpVlan

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
			
		}
	}	
	return $ReturnObject
}

###############################################################################
## Start Helper Functions
###############################################################################

###############################################################################
# HelperDetectClassful

function HelperDetectClassful {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0,ParameterSetName='RxString')]
		[ValidatePattern("(\d+\.){3}\d+")]
		[String]$IpAddress
	)
	
	$VerbosePrefix = "HelperDetectClassful: "
	
	$Regex = [regex] "(?x)
					  (?<first>\d+)\.
					  (?<second>\d+)\.
					  (?<third>\d+)\.
					  (?<fourth>\d+)"
						  
	$Match = HelperEvalRegex $Regex $IpAddress
	
	$First  = $Match.Groups['first'].Value
	$Second = $Match.Groups['second'].Value
	$Third  = $Match.Groups['third'].Value
	$Fourth = $Match.Groups['fourth'].Value
	
	$Mask = 32
	if ($Fourth -eq "0") {
		$Mask -= 8
		if ($Third -eq "0") {
			$Mask -= 8
			if ($Second -eq "0") {
				$Mask -= 8
			}
		}
	}
	
	return "$IpAddress/$([string]$Mask)"
}

###############################################################################
# HelperEvalRegex

function HelperEvalRegex {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0,ParameterSetName='RxString')]
		[String]$RegexString,
		
		[Parameter(Mandatory=$True,Position=0,ParameterSetName='Rx')]
		[regex]$Regex,
		
		[Parameter(Mandatory=$True,Position=1)]
		[string]$StringToEval,
		
		[Parameter(Mandatory=$False)]
		[string]$ReturnGroupName,
		
		[Parameter(Mandatory=$False)]
		[int]$ReturnGroupNumber,
		
		[Parameter(Mandatory=$False)]
		$VariableToUpdate,
		
		[Parameter(Mandatory=$False)]
		[string]$ObjectProperty,
		
		[Parameter(Mandatory=$False)]
		[string]$LoopName
	)
	
	$VerbosePrefix = "HelperEvalRegex: "
	
	if ($RegexString) {
		$Regex = [Regex] $RegexString
	}
	
	if ($ReturnGroupName) { $ReturnGroup = $ReturnGroupName }
	if ($ReturnGroupNumber) { $ReturnGroup = $ReturnGroupNumber }
	
	$Match = $Regex.Match($StringToEval)
	if ($Match.Success) {
		#Write-Verbose "$VerbosePrefix Matched: $($Match.Value)"
		if ($ReturnGroup) {
			#Write-Verbose "$VerbosePrefix ReturnGroup"
			switch ($ReturnGroup.Gettype().Name) {
				"Int32" {
					$ReturnValue = $Match.Groups[$ReturnGroup].Value.Trim()
				}
				"String" {
					$ReturnValue = $Match.Groups["$ReturnGroup"].Value.Trim()
				}
				default { Throw "ReturnGroup type invalid" }
			}
			if ($VariableToUpdate) {
				if ($VariableToUpdate.Value.$ObjectProperty) {
					#Property already set on Variable
					continue $LoopName
				} else {
					$VariableToUpdate.Value.$ObjectProperty = $ReturnValue
					Write-Verbose "$ObjectProperty`: $ReturnValue"
				}
				continue $LoopName
			} else {
				return $ReturnValue
			}
		} else {
			return $Match
		}
	} else {
		if ($ObjectToUpdate) {
			return
			# No Match
		} else {
			return $false
		}
	}
}

###############################################################################
# HelperTestVerbose

function HelperTestVerbose {
[CmdletBinding()]
param()
    [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference
}

###############################################################################
## Export Cmdlets
###############################################################################

Export-ModuleMember *-*
