###############################################################################
## Start Powershell Cmdlets
###############################################################################

###############################################################################
# Get-FgAddress

function Get-FgAddress {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-FgAddress: "
	
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
		# Section Start
		
		$Regex = [regex] "^config\ firewall\ address"
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
				$NewObject       = New-Object FortiShell.Address
				$NewObject.Name  = $Eval
				$ReturnObject   += $NewObject
				Write-Verbose "object created: $($NewObject.Name)"
			}
			if ($NewObject) {
				# Subnet
				$EvalParams.Regex          = [regex] "^\s+set\ subnet\ (?<ip>$IpRx)\ (?<mask>$IpRx)"
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Value = $Eval.Groups['ip'].Value
					$NewObject.Value += '/' + (ConvertTo-MaskLength $Eval.Groups['mask'].Value)
				}
				
				###########################################################################################
				# Regular Properties
				
				# Update eval Parameters for remaining matches
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
				
				###############################################
				# General Properties
				
				# Interface
				$EvalParams.ObjectProperty = "Interface"
				$EvalParams.Regex          = [regex] '^\s+set\ associated-interface\ "(.+?)"'
				$Eval                      = HelperEvalRegex @EvalParams
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-FgPolicy

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
				
				# Disabled
				$EvalParams.Regex          = [regex] "^\s+set\ status\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq "disable") {
					$NewObject.Disabled = $true
				}
				
				# ProfileStatus
				$EvalParams.Regex          = [regex] "^\s+set\ profile-status\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq "enable") {
					$NewObject.ProfileStatus = $true
				}
				
				# LogTraffic
				$EvalParams.Regex          = [regex] "^\s+set\ logtraffic\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq "enable") {
					$NewObject.LogTraffic = $true
				}
				
				# Nat
				$EvalParams.Regex          = [regex] "^\s+set\ nat\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq "enable") {
					$NewObject.NatEnabled = $true
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
				
				# Profile
				$EvalParams.Regex          = [regex] '^\s+set\ profile\ "(.+?)"'
				$EvalParams.ObjectProperty = "Profile"
				$Eval                      = HelperEvalRegex @EvalParams
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-FgService

function Get-FgService {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-FgService: "
	
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
		
		$Regex = [regex] "^config\ firewall\ service\ custom"
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
				$NewObject       = New-Object FortiShell.Service
				$NewObject.Name  = $Eval
				$ReturnObject   += $NewObject
				Write-Verbose "object created: $($NewObject.Name)"
			}
			if ($NewObject) {
				
				###########################################################################################
				# Special Properties
				
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
				}
				
				###########################################################################################
				# Regular Properties
				
				# Update eval Parameters for remaining matches
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-FgServiceGroup

function Get-FgServiceGroup {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Vlan Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-FgServiceGroup: "
	
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
		
		$Regex = [regex] "^config\ firewall\ service\ group"
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
				$NewObject       = New-Object FortiShell.ServiceGroup
				$NewObject.Name  = $Eval
				$ReturnObject   += $NewObject
				Write-Verbose "object created: $($NewObject.Name)"
			}
			if ($NewObject) {
				
				###########################################################################################
				# Special Properties
				
				# Members
				$EvalParams.Regex          = [regex] "^\s+set\ member\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) {
					$Split = $Eval.Split()
					foreach ($s in $Split) {
						$NewObject.Value += $s -replace '"',''
					}
				}
				
				###########################################################################################
				# Regular Properties
				
				# Update eval Parameters for remaining matches
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
			}
		} else {
			continue
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-FgStaticRoute

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
