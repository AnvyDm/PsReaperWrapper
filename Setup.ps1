﻿[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
Clear-Host
$host.ui.RawUI.WindowTitle = "Ps Ukrainian Reaper"

# Will be necessary for Windows 7 adaptation
If ($PSVersionTable.PSVersion.Major -lt 3) {
    $PsScriptRoot = Split-Path $MyInvocation.MyCommand.Path
}

# List of generic functions
function Download-File {
    param ( [string]$SourceUrl, [string]$DestinationPath )

    $FilePath = Join-Path -Path $DestinationPath -ChildPath $($SourceUrl.Split("/")[-1])
    (New-Object System.Net.WebClient).DownloadFile($SourceUrl, $FilePath)
    Write-Output $FilePath
}

function Unzip-File {
    param([string]$Path, [string]$DestinationPath)

    $null = New-Item -Path $DestinationPath -ItemType Directory
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Path, $DestinationPath)
}

function Set-EnvVariable {
    param([string]$Variable, [string]$Value)

    $CurrentValue = [System.Environment]::GetEnvironmentVariable($Variable, 'Process')
    if ($CurrentValue -notlike "*$Variable*") {
        [System.Environment]::SetEnvironmentVariable('PATH', "$Value;$CurrentValue", 'Process')
    }
}

$RootPath = "$env:SystemDrive\PsUaReaper"

# completely remove existing folder
If ( (Test-Path -Path $RootPath) -and $Force ) {
    Write-Host "`tЗнайдено попередню версію UaReaper. Видалення..."
    # mtab file has system attribute and cannot be removed in usual way
    attrib $RootPath\Git\etc\mtab -s
    Remove-Item -Path $RootPath -Recurse -Confirm:$false -Force
}

#Create project folder
Write-Host "`tРозташування $RootPath"
$null = New-Item -Path $RootPath -ItemType Directory -Force

$ScriptEnvs = @{
    'PowerShell' = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/PowerShell-7.2.4-win-x86.zip'
    'Python' = 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-win32.zip'
}

# Download Python and PowerShell
foreach ($key in $ScriptEnvs.Keys) {
    $Name = $key
    $srcUrl =  $ScriptEnvs[$key]

    $srcTarget = "$RootPath\$Name"
    If ( (Test-Path -Path $srcTarget) -and !$Force ) { continue }
    Write-Host "`tЗавантаження $Name..."
    $srcArchive = Download-File -SourceUrl $srcUrl -DestinationPath $RootPath

    Write-Host "`tРозпаковка $Name..."
    Unzip-File -Path $srcArchive -DestinationPath $srcTarget
    Remove-Item -Path $srcArchive -Force
}

# configure Python
Write-Host "`tНалаштування Python..."
# Environment variable is set for current process and child processes only. user and machine environments have no changes
# Set-EnvVariable -Variable 'PATH' -Value "$RootPath\Python;$RootPath\Python\Scripts"

# specify python environment
@'
python38.zip
.
..\mhddos_proxy\

# Uncomment to run site.main() automatically
import site
'@ | Set-Content -Path "$RootPath\Python\python38._pth"

# download and install modules
$PipInstaller = Download-File -SourceUrl 'https://bootstrap.pypa.io/get-pip.py'  -DestinationPath $RootPath\Python
&"$RootPath\Python\Python.exe" "$PipInstaller" --quiet --no-warn-script-location
&"$RootPath\Python\Python.exe" -m pip install encoding-tools --quiet --no-warn-script-location
$null = New-Item -Path "$RootPath\Python\DLLs" -ItemType Directory -Force

# Download Git
If ( (Test-Path "$RootPath\Git\cmd\git.exe") -and !$Force ) { }
else {
    Write-Host "`tЗавантаження Git..."
    $GitUrl = 'https://github.com/git-for-windows/git/releases/download/v2.36.1.windows.1/PortableGit-2.36.1-32-bit.7z.exe'
    $GitArchive = Download-File -SourceUrl $GitUrl -DestinationPath $RootPath

    Write-Host "`tРозпаковка Git..."
    Start-Process -FilePath $GitArchive -ArgumentList "-o `"$RootPath\Git`" -y" -Wait -WindowStyle 'Hidden'
    Remove-Item -Path $GitArchive -Force
}

Write-Host "`tПочаткове середовище готово`n"
# remove-Item -Path "$PsScriptRoot\Setup.ps1"

# Clone Powershell Wrapper
Write-Host "`tЗавантаження файлів PsUaReaper..."
$StartParams = @{
    'FilePath' = "$RootPath\Git\cmd\git.exe"
    'Wait' = $true
    'WindowStyle' = 'Hidden'
}
if (Test-Path -Path "$RootPath\PsScripts") {
    $null = $StartParams.Add("ArgumentList", "-C $RootPath\PsScripts pull")
    $Message = "`tPsUareaper було оновлено!"
}
else {
    $null = $StartParams.Add("ArgumentList", "clone https://github.com/AnvyDm/PsUaReaper.git $RootPath\PsScripts")
    $Message = "`tPsUaReaper було встановлено!"
}
Start-Process @StartParams
Write-Host $Message

# Create start script
Copy-Item -Path "$RootPath\PsScripts\Start.cmd" -Destination "$RootPath\Start.cmd" -Force

# start wrapper
Write-Host "`tЗапуск...`n"
&"$RootPath\Powershell\pwsh.exe" -ExecutionPolicy Bypass -File "$RootPath\PsScripts\wrapper.ps1"