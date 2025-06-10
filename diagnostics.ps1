# diagnostics.ps1
# Enhanced version for Windows Server 2012 (non-R2)
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

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    Write-Host "PowerShell Version: $($version.Major).$($version.Minor).$($version.Build)" -ForegroundColor Cyan
    
    if ($version.Major -lt 3) {
        Write-Host "WARNING: PowerShell version is older than 3.0" -ForegroundColor Yellow
        Write-Host "Some features may not work correctly." -ForegroundColor Yellow
    } else {
        Write-Host "PowerShell version is compatible." -ForegroundColor Green
    }
    Write-Host ""
}

function Test-SystemRequirements {
    Write-Host "System Requirements Check:" -ForegroundColor Cyan
    
    # Check OS Version
    $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        Write-Host "OS: $($os.Caption) Build $($os.BuildNumber)" -ForegroundColor Cyan
        if ($os.BuildNumber -eq "9200") {
            Write-Host "Windows Server 2012 detected - Compatible" -ForegroundColor Green
        } elseif ($os.BuildNumber -eq "9600") {
            Write-Host "Windows Server 2012 R2 detected - Compatible" -ForegroundColor Green
        } else {
            Write-Host "OS Version: $($os.BuildNumber) - May be compatible" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Could not determine OS version" -ForegroundColor Yellow
    }
    
    # Check Architecture
    $arch = $env:PROCESSOR_ARCHITECTURE
    Write-Host "Architecture: $arch" -ForegroundColor Cyan
    
    # Check available memory
    if ($os) {
        $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        Write-Host "Total Memory: $totalMem GB" -ForegroundColor Cyan
        if ($totalMem -lt 2) {
            Write-Host "WARNING: Low memory may affect benchmark performance" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
}

function Test-WinSATComponents {
    Write-Host "WinSAT Component Analysis:" -ForegroundColor Cyan
    
    $winsatPath = "$env:SystemRoot\System32\WinSAT.exe"
    $winsatDir = "$env:SystemRoot\System32"
    
    # Check main executable
    if (Test-Path $winsatPath) {
        $fileInfo = Get-Item $winsatPath
        Write-Host "WinSAT.exe: Found" -ForegroundColor Green
        Write-Host "  Size: $($fileInfo.Length) bytes" -ForegroundColor Cyan
        Write-Host "  Modified: $($fileInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
        Write-Host "  Version: $(try { $fileInfo.VersionInfo.FileVersion } catch { 'Unknown' })" -ForegroundColor Cyan
    } else {
        Write-Host "WinSAT.exe: NOT FOUND" -ForegroundColor Red
        return $false
    }
    
    # Check for supporting DLLs
    $supportingFiles = @(
        "winsat.dll",
        "winsatapi.dll"
    )
    
    foreach ($file in $supportingFiles) {
        $filePath = Join-Path $winsatDir $file
        if (Test-Path $filePath) {
            Write-Host "$file`: Found" -ForegroundColor Green
        } else {
            Write-Host "$file`: Missing (may be optional)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    return $true
}

function Test-WinSATPermissions {
    Write-Host "Permission Check:" -ForegroundColor Cyan
    
    try {
        # Test if we can execute WinSAT with a simple command
        $testProcess = Start-Process -FilePath "winsat" -ArgumentList "-?" -NoNewWindow -PassThru -Wait -ErrorAction Stop
        
        if ($testProcess.ExitCode -eq 0 -or $testProcess.ExitCode -eq 1) {
            Write-Host "WinSAT execution test: PASSED" -ForegroundColor Green
            Write-Host "WinSAT is accessible and can be executed." -ForegroundColor Green
        } else {
            Write-Host "WinSAT execution test: WARNING" -ForegroundColor Yellow
            Write-Host "WinSAT responded with exit code: $($testProcess.ExitCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "WinSAT execution test: FAILED" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    return $true
}

function Test-TempDirectory {
    Write-Host "Temporary Directory Check:" -ForegroundColor Cyan
    
    $tempPath = $env:TEMP
    Write-Host "Temp Path: $tempPath" -ForegroundColor Cyan
    
    if (Test-Path $tempPath) {
        Write-Host "Temp directory exists: YES" -ForegroundColor Green
        
        # Test write permissions
        $testFile = Join-Path $tempPath "winsat_test_$(Get-Date -Format 'yyyyMMddHHmmss').tmp"
        try {
            "test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            Write-Host "Temp directory writable: YES" -ForegroundColor Green
        }
        catch {
            Write-Host "Temp directory writable: NO" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Temp directory exists: NO" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    return $true
}

# Requirements Check Banner
Clear-Host
$line = "=" * 79
$header = "Simple-Winsat-Bench : Requirements Check"
Write-Host $line
Write-Host (Get-CenteredText $header)
Write-Host $line
Write-Host ""

# Run all diagnostic checks
$allChecksPassed = $true

Test-PowerShellVersion
Test-SystemRequirements

$winsatAvailable = Test-WinSATComponents
$allChecksPassed = $allChecksPassed -and $winsatAvailable

if ($winsatAvailable) {
    $permissionsOk = Test-WinSATPermissions
    $allChecksPassed = $allChecksPassed -and $permissionsOk
}

$tempOk = Test-TempDirectory
$allChecksPassed = $allChecksPassed -and $tempOk

# Final result
Write-Host ("=" * 79)
if ($allChecksPassed) {
    Write-Host (Get-CenteredText "ALL CHECKS PASSED - READY FOR BENCHMARKING")
    Write-Host ""
    Write-Host "Your system is ready to run WinSAT benchmarks." -ForegroundColor Green
} else {
    Write-Host (Get-CenteredText "SOME CHECKS FAILED - REVIEW ABOVE")
    Write-Host ""
    Write-Host "Please resolve the issues above before running benchmarks." -ForegroundColor Red
    
    if (-not $winsatAvailable) {
        Write-Host ""
        Write-Host "SOLUTION FOR MISSING WINSAT:" -ForegroundColor Yellow
        Write-Host "1. Find WinSAT.exe on a desktop Windows system at:" -ForegroundColor Yellow
        Write-Host "   C:\Windows\System32\WinSAT.exe" -ForegroundColor Yellow
        Write-Host "2. Copy the file to this server's System32 folder:" -ForegroundColor Yellow
        Write-Host "   $env:SystemRoot\System32\" -ForegroundColor Yellow
        Write-Host "3. Ensure the file has proper permissions to execute." -ForegroundColor Yellow
        Write-Host "4. You may also need to copy winsat.dll if available." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host ("-" * 79)
Write-Host "Press any key to continue..."

# Wait for key press
try {
    [Console]::ReadKey($true) | Out-Null
} catch {
    Read-Host "Press Enter to continue"
}