function Get-HpSysname {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-HpSysname: "
		
	$TotalLines = $ShowSupportOutput.Count
	$i          = 0 
	$StopWatch  = [System.Diagnostics.Stopwatch]::StartNew() # used by Write-Progress so it doesn't slow the whole function down
	
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
		
		$Regex = [regex] "^\ sysname\ (.+)"
		$Match = HelperEvalRegex $Regex $line -ReturnGroupNum 1
		if ($Match) {
			$ReturnObject = $Match
		}
	}
	Write-Progress -Activity "Reading Support Output" -Status "Complete" -PercentComplete 100 -Completed	
	return $ReturnObject
}