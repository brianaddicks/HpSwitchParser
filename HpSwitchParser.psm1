###############################################################################
## Start Powershell Cmdlets
###############################################################################

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
