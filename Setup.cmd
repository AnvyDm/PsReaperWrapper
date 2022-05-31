echo off

SET SRC=https://raw.githubusercontent.com/AnvyDm/PsUaReaper/master/Setup.ps1
powershell.exe -Command {(New-Object System.Net.WebClient).DownloadFile("%SRC%", "%~DP0Setup.ps1")}
powershell.exe -ExecutionPolicy Bypass -File "%~DP0Setup.ps1"