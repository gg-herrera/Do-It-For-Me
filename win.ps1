Clear-Host

$OS = (Get-ComputerInfo).OsName
if ($OS -like "*Windows*") {
    Write-Host "[+] $OS Machine detected."
} else {
    Write-Error "[!] This script is intended for Windows machines only. Exiting from $OS ..."
    exit 1
}

$ADMIN = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (-Not $ADMIN) {
    Write-Error "[!] This script requires administrative privileges. Please run as Administrator. Exiting..."
    exit 1
}
$usrname = $env:USERNAME
$ARCH = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
$ChocoState = $false
$PythonState = $false
$gitState = $false
$uvState = $false
Write-Host "[i] Machine Info: $usrname | $ARCH on $OS"
Write-Host "[+] Starting the setup process..."

$EnvChocoInstall = "C:\ProgramData\chocolatey"

Write-Host "[?] Do you want to continue? The Program will install some dependencies including Chocolatey. (Y/N)" -ForegroundColor Yellow

$response = [Console]::ReadKey($true).KeyChar.ToString().ToUpper()
if ($response -eq 'Y' -or $response -eq 'S') {
    Write-Host "[+] Confimation received. Proceeding..."
} else {
    Write-Warning "[-] Operation cancelled by user. Exiting..."
    exit 0
}

if (-Not (Test-Path $EnvChocoInstall)) {
        Write-Host "[i] Chocolatey Not Found. Using Temporary Install..."
        Invoke-WebRequest https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
    } else {
        $ChocoState = $true
        Write-Host "[+] Chocolatey Found. Using Existing Install..."
    }

Write-Host "[?] Checking if Python is installed..."
$PythonExists = Get-Command "python"
if ($PythonExists) {
    $PythonState = $true
    Write-Host "[+] Python is already installed!"
} else {
    Write-Host "[-] Python is not installed. Executing Temporary Python Script..."
    $(choco install python313 -y)   
}

Write-Host "[?] Checking if uv is installed..."
$uvExists = Get-Command "uv"
if ($uvExists) {
    $uvState = $true
    Write-Host "[+] uv is already installed!"
} else {
    Write-Host "[-] uv is not installed. Executing Temporary uv Script..."
    $(powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex")
}


Write-Host "[?] Checking if git is installed..."
$gitExists = Get-Command "git"
if ($gitExists) {
    $gitState = $true
    Write-Host "[+] Git is already installed!"
} else {
    Write-Host "[-] Git is not installed. Executing Temporary Git Script..."
    $(choco install git -y)
}

try {
    Write-Host "[i] Running DIFM Python Script with uv..."
    $(uv run ./difm.py) } catch {
        Write-Warning $_
    }
if (-Not $PythonState) {
    Write-Host "[i] Cleaning up Temporary Python Install..."
    $(choco uninstall python313 -y)
}

if (-not $gitState) {
    Write-Host "[i] Cleaning up Temporary Git Install..."
    $(choco uninstall git -y)
}

if (-not $uvState) {
    Write-Host "[i] Cleaning up Temporary uv Install..."
    $(Invoke-WebRequest -LsSf https://astral.sh/uv/install.sh | sh)
}

if (-Not $ChocoState) {
    Write-Host "[i] Cleaning up Temporary Chocolatey Install..."
    Remove-Item -Recurse -Force "C:\ProgramData\chocolatey"
}
