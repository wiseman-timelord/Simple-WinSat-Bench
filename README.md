# Simple-WinSat-Bench
Its a simple WinSat benchmarker for Server editions of Windows.

### Description
I was trying to get windows experience index working through "ExperienceIndexOK" a third party experience index program, however, it didnt work, and WinSat was missing from System32, so a solution was provided, to copy over WinSat from equivalent relating desktop edition of windows, which I did, but then only, Drive and Gpu, tests worked, hence, with some assessment of presentation, Simple-WinSat-Bench was created. While the stats are limited, the score is in my optinion more functional than windows experience index, because we are using average of the 2 scores, not just lowest value. The downfall is obviously no cpu tests.

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

### Notation
- The drives uses lowest value from classic WEI scores, while the dx score is based on a timer, with 2:00 as base of 8, 1:30 would be 9, etc.

### Requirements
- Version of Server without WinSat (eg, Server 2012) AND relating version of Windows Desktop containing WinSat (ie, Windows 8). You will need WinSat.exe, obviously I cant provide it in the package or link it, because its made by M$.
- Powershell Core - TBA.  
