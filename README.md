# Simple-WinSat-Bench
Status : Beta - could be improved.

### Description
Its a simple WinSat benchmarker for Server editions of Windows. Was trying "ExperienceIndexOK" (a third party experience index), however, it didnt work due to WinSat missing from System32, so a solution was, to copy over WinSat from equivalent desktop edition of windows, but then only, Drive and Gpu, tests worked, hence, the limited stats just needed to be presented somehow. While the stats are limited, the score is possibly more functional, because we are using average of the 2 scores, not just lowest value (like in Experience Index). The main downfall is obviously no cpu tests.

### Preview
Here is what to expect...
```
===============================================================================
    Simple-Winsat-Bench : Results
===============================================================================


Ave. Direct3D Alpha Blend Performance             3409.22 F/s
Ave. Direct3D Texture Load Performance           1784.93 F/s
Ave. Direct3D Geometry Performance               4274.66 F/s
Graphics Score = 9.8 (timer)


Disk  Random 16.0 Read                       317.33 MB/s
Disk  Sequential 64.0 Read                   513.18 MB/s
Disk  Sequential 64.0 Write                  515.21 MB/s
Drives Score = 8.1 (classic)


Final Result = 8.9


-------------------------------------------------------------------------------
Press Any key to continue...


```

### Requirements
- Version of Windows with the file "SystemDrive\Windows\System32\WinSat.exe", or alternatively if you a have Server without WinSat (eg, Server 2012), then find a relating version of Windows Desktop containing WinSat (ie, Windows 8), and copy it over.
- Powershell - Qwen3-235B-A22B assessed the `benchmark.ps1` script, and said it was PowerShell 3.0+ compatible.  

### Notation
- The drives uses lowest value from classic WEI scores, while the dx score is based on a timer, with 2:00 as base of 8, 1:30 would be 9, etc.

### Development
- Add a psd1 for "Final Result = 8.9 (+0.3)", remembering previous score. 

### Warnings
- Copying Windows files to other editions of Windows, may have unexpected results and be unsafe. Ensure not to over-write/corrupt important files in "..\system32` folder.

