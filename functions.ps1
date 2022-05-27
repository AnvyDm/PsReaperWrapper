# variables
$RootPath = "$env:SystemDrive\UaReaper"
$VenvPath = "$RootPath\venv"
$PyPath = "$RootPath\Python"
$LocalMhddosProxy = "$RootPath\mhddos_proxy"
# functions
function Download-File {
    param ( [string]$SourceUrl, [string]$DestinationPath )

    $FilePath = Join-Path -Path $DestinationPath -ChildPath $($SourceUrl.Split("/")[-1])
    (New-Object System.Net.WebClient).DownloadFile($SourceUrl, $FilePath)
    Write-Output $FilePath
}

function Download-String {
    param ( [string]$SourceUrl )
    
    (New-Object System.Net.WebClient).DownloadString($SourceUrl)
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
    [System.Environment]::SetEnvironmentVariable('PATH', "$Value;$CurrentValue", 'Process')
}

function Write-MidleHost {
    param( [string]$message, [switch]$Here )

    if ($Here) {$rt="`r"} else {$rt=''}
    $ConsoleSize = $host.ui.rawui.WindowSize
    $marginSize = (($ConsoleSize.Width - $message.Length) / 2) -1
    $margin = ' ' * $MarginSize
    Write-Host "$rt$margin $message $margin" @args
}

function Get-Ipv4Address {
    param ([string]$address)

    $ServerName = ($address -as [uri]).host
    $Port = ($address -as [uri]).Port
    
    try{
        $IpAddress = [System.Net.Dns]::GetHostAddresses($ServerName, 2).IPAddressToString
        Write-Output "${IpAddress}:${Port}"
    }
    catch {
        $address
    }
}