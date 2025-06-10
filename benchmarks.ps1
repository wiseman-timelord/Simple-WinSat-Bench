# benchmarks.ps1
# Compatibility for Windows Server 2012 (non-R2)
# Output matches exact 79-character width formatting

function Get-CenteredText {
    param (
        [string]$Text,
        [int]$Width = 79
    )
    if ($Text.Length -ge $Width) {
        return $Text.Substring(0, $Width)
    }
    $padLeft = [math]::Floor(($Width - $Text.Length) / 2)
    $padRight = $Width - $Text.Length - $padLeft
    return " " * $padLeft + $Text + " " * $padRight
}

function Write-ErrorAndExit {
    param (
        [string]$Message,
        [string]$Details = ""
    )
    Write-Host "ERROR: $Message" -ForegroundColor Red
    if ($Details) {
        Write-Host $Details -ForegroundColor Yellow
    }
    Write-Host "Aborting script." -ForegroundColor Red
    Write-Host ""
    Write-Host ("-" * 79)
    Write-Host "Press any key to exit..."
    try {
        [Console]::ReadKey($true) | Out-Null
    } catch {
        Read-Host "Press Enter to exit"
    }
    exit 1
}

function Test-WinSATAvailability {
    $winsatPath = "$env:SystemRoot\System32\WinSAT.exe"
    if (-not (Test-Path $winsatPath)) {
        Write-ErrorAndExit "WinSAT.exe not found at $winsatPath" @"
SOLUTION:
Copy WinSAT.exe from a Windows Desktop OS to your server's System32 folder.
Ensure the file has proper permissions to execute.
"@
    }
}

# Initial Benchmarking Banner
Clear-Host
$line = "=" * 79
Write-Host $line
Write-Host "    Simple-Winsat-Bench : Benchmarking"
Write-Host $line
Write-Host ""

# Verify WinSAT is available
Test-WinSATAvailability

function Run-WinSATTest {
    param (
        [string]$TestName,
        [int]$TimeoutSeconds = 300
    )
    Write-Host "Running $TestName Benchmarks..."
    $tempFile = "$env:TEMP\winsat_$TestName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    try {
        # Use ProcessStartInfo for better control
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "winsat"
        $processInfo.Arguments = $TestName
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        $outputData = New-Object System.Text.StringBuilder
        $errorData = New-Object System.Text.StringBuilder
        
        $outputEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
            if ($Event.SourceEventArgs.Data) {
                $Event.MessageData.AppendLine($Event.SourceEventArgs.Data)
            }
        } -MessageData $outputData
        
        $errorEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
            if ($Event.SourceEventArgs.Data) {
                $Event.MessageData.AppendLine($Event.SourceEventArgs.Data)
            }
        } -MessageData $errorData
        
        $process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            throw "WinSAT $TestName timed out after $TimeoutSeconds seconds"
        }
        
        Unregister-Event -SourceIdentifier $outputEvent.Name
        Unregister-Event -SourceIdentifier $errorEvent.Name
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = $errorData.ToString()
            throw "WinSAT $TestName failed with exit code $($process.ExitCode). Error: $errorOutput"
        }
        
        $output = $outputData.ToString()
        $output | Out-File -FilePath $tempFile -Encoding UTF8
        Write-Host "...$TestName Scores Collected.`r`n"
        return $output -split "`n"
    }
    catch {
        Write-ErrorAndExit "Failed to run winsat $TestName" $_.Exception.Message
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Parse-D3DMetrics {
    param ([string[]]$Output)
    
    $metrics = @{
        Alpha = @()
        Texture = @()
        Geometry = @()
        Runtime = $null
    }
    
    foreach ($line in $Output) {
        if ($line -match "Direct3D Alpha Blend Performance.*?(\d+(?:\.\d+)?)\s*F/s") {
            $metrics.Alpha += [double]$matches[1]
        }
        elseif ($line -match "Direct3D Texture Load Performance.*?(\d+(?:\.\d+)?)\s*F/s") {
            $metrics.Texture += [double]$matches[1]
        }
        elseif ($line -match "Direct3D Geometry Performance.*?(\d+(?:\.\d+)?)\s*F/s") {
            $metrics.Geometry += [double]$matches[1]
        }
        elseif ($line -match "Total Run Time.*?(\d+:\d+\.\d+)") {
            $metrics.Runtime = $matches[1]
        }
    }
    
    return $metrics
}

function Parse-DiskMetrics {
    param ([string[]]$Output)
    
    $diskMetrics = @()
    
    foreach ($line in $Output) {
        if ($line -match "Disk\s+(Random|Sequential)\s+(\d+(?:\.\d+)?)\s+(Read|Write).*?(\d+(?:\.\d+)?)\s*MB/s.*?(\d+(?:\.\d+)?)") {
            $diskMetrics += [PSCustomObject]@{
                Type = "$($matches[1]) $($matches[2]) $($matches[3])"
                Value = [double]$matches[4]
                Score = if ($matches[5]) { [double]$matches[5] } else { 0.0 }
            }
        }
    }
    
    return $diskMetrics
}

function Calculate-Average {
    param ([double[]]$Values)
    if ($Values.Count -eq 0) { return 0.0 }
    return ($Values | Measure-Object -Sum).Sum / $Values.Count
}

function Calculate-D3DScore {
    param ([string]$RuntimeString)
    
    if (-not $RuntimeString -or $RuntimeString -eq "N/A") {
        return 8.0  # Default base score if no runtime available
    }
    
    # Parse runtime string (format: "M:SS.mmm" or "MM:SS.mmm")
    if ($RuntimeString -match "(\d+):(\d+)\.(\d+)") {
        $minutes = [int]$matches[1]
        $seconds = [int]$matches[2]
        $milliseconds = [int]$matches[3]
        
        # Convert to total seconds
        $totalSeconds = ($minutes * 60) + $seconds + ($milliseconds / 1000)
        
        # Base score is 8.0 for 2:00 (120 seconds)
        $baseTimeSeconds = 120.0
        $baseScore = 8.0
        
        # Calculate score adjustment: +0.5 points for every 15 seconds faster than base
        # -0.5 points for every 15 seconds slower than base
        $timeDifference = $baseTimeSeconds - $totalSeconds
        $scoreAdjustment = ($timeDifference / 15.0) * 0.5
        
        $finalScore = $baseScore + $scoreAdjustment
        
        # Ensure score stays within reasonable bounds (minimum 1.0, maximum 15.0)
        $finalScore = [Math]::Max(1.0, [Math]::Min(15.0, $finalScore))
        
        return $finalScore
    }
    
    # If parsing fails, return base score
    return 8.0
}

# Run GPU Benchmark (d3d)
$d3dOutput = Run-WinSATTest -TestName "d3d"

# Run HD Benchmark (disk)
$diskOutput = Run-WinSATTest -TestName "disk"

# Assemble results
Write-Host "Assembling results...`r`n"
Start-Sleep -Seconds 2

# Clear screen and display final results
Clear-Host
Write-Host $line
Write-Host "    Simple-Winsat-Bench : Results"
Write-Host $line
Write-Host ""
Write-Host ""

# Parse metrics
$d3dMetrics = Parse-D3DMetrics -Output $d3dOutput
$diskMetrics = Parse-DiskMetrics -Output $diskOutput

# Calculate averages
$aveAlpha = Calculate-Average -Values $d3dMetrics.Alpha
$aveTexture = Calculate-Average -Values $d3dMetrics.Texture
$aveGeometry = Calculate-Average -Values $d3dMetrics.Geometry

# Calculate scores
$d3dScore = Calculate-D3DScore -RuntimeString $d3dMetrics.Runtime
$lowestDiskScore = if ($diskMetrics.Count -gt 0) {
    ($diskMetrics.Score | Where-Object { $_ -gt 0 } | Measure-Object -Minimum).Minimum
} else { 0.0 }

# Calculate final result as average of D3D score and disk score
$finalResult = if ($lowestDiskScore -gt 0) {
    ($d3dScore + $lowestDiskScore) / 2.0
} else {
    $d3dScore  # Use only D3D score if disk score unavailable
}

# Display metrics
Write-Host ("Ave. Direct3D Alpha Blend Performance             {0:F2} F/s" -f $aveAlpha)
Write-Host ("Ave. Direct3D Texture Load Performance           {0:F2} F/s" -f $aveTexture)
Write-Host ("Ave. Direct3D Geometry Performance               {0:F2} F/s" -f $aveGeometry)
Write-Host ("Graphics Score = {0:F1} (timer)" -f $d3dScore)
Write-Host ""
Write-Host ""

# Display disk metrics
if ($diskMetrics.Count -ge 3) {
    $randomRead = $diskMetrics | Where-Object { $_.Type -like "*Random*Read*" } | Select-Object -First 1
    $seqRead = $diskMetrics | Where-Object { $_.Type -like "*Sequential*Read*" } | Select-Object -First 1
    $seqWrite = $diskMetrics | Where-Object { $_.Type -like "*Sequential*Write*" } | Select-Object -First 1
    
    Write-Host ("Disk  Random 16.0 Read                       {0:F2} MB/s" -f $(if ($randomRead) { $randomRead.Value } else { 0.0 }))
    Write-Host ("Disk  Sequential 64.0 Read                   {0:F2} MB/s" -f $(if ($seqRead) { $seqRead.Value } else { 0.0 }))
    Write-Host ("Disk  Sequential 64.0 Write                  {0:F2} MB/s" -f $(if ($seqWrite) { $seqWrite.Value } else { 0.0 }))
} else {
    Write-Host "Disk  Random 16.0 Read                       0.00 MB/s"
    Write-Host "Disk  Sequential 64.0 Read                   0.00 MB/s"
    Write-Host "Disk  Sequential 64.0 Write                  0.00 MB/s"
}

Write-Host ("Drives Score = {0:F1} (classic)" -f $lowestDiskScore)
Write-Host ""
Write-Host ""
Write-Host ("Final Result = {0:F1}" -f $finalResult)
Write-Host ""
Write-Host ""

# Footer
Write-Host ("-" * 79)
Write-Host "Press Any key to continue..."

# Wait for key press
try {
    [Console]::ReadKey($true) | Out-Null
} catch {
    Read-Host "Press Enter to continue"
}