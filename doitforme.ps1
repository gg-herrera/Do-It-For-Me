Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


Write-Host "Welcome to Do It For Me! ->"
$OS = (Get-ComputerInfo).OsName
if ($OS -like "*Windows*") {
    Write-Host "$OS Machine detected."
} else {
    Write-Error "This script is intended for Windows machines only. Exiting from $OS ..."
    exit 1
}
$ADMIN = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (-Not $ADMIN) {
    Write-Error "This script requires administrative privileges. Please run as Administrator. Exiting..."
    exit 1
}
Write-Host "Starting the setup process..."

$EnvChocoInstall = "C:\ProgramData\chocolatey"
if (-Not (Test-Path $EnvChocoInstall)) {
    Write-Host "Chocolatey Not Found. Using Temporary Install..."
    Invoke-WebRequest https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
} else {
    Write-Host "Chocolatey Found. Using Existing Install..."
}
Write-Host "Checking Application Database..."
$AppDB = [ordered]@{}
$UnsortedAppDB = @{
    "Brave" = "choco install brave -y";
    "Chrome" = "choco install googlechrome -y";
    "Firefox" = "choco install firefox -y";
    "Opera" = "choco install opera -y";
    "OperaGX" = "choco install operagx -y";
    "Tor" = "choco install tor-browser -y";
    "EpicGames" = "choco install epicgameslauncher -y";
    "Groove" = "choco install groove -y";
    "Steam" = "choco install steam -y";
    "Discord" = "choco install discord -y";
    "Zoom" = "choco install zoom -y";
    "VLC" = "choco install vlc -y";
    "Winrar" = "choco install winrar -y";
    "WPSOffice" = "choco install wps-office -y";
    "LibreOffice" = "choco install libreoffice-fresh -y";
    "BleachBit" = "choco install bleachbit -y";
    "Kaspersky" = "choco install kav -y";
    "Avast" = "choco install avastfreeantivirus -y";
    "Malwarebytes" = "choco install malwarebytes -y";
    "ProtonVPN" = "choco install protonvpn -y";
    "Spotify" = "choco install spotify -y";
    "Vscode" = "choco install vscode -y";
    "Python" = "choco install python -y";
    "NodeJS" = "choco install nodejs -y";
    "Git" = "choco install git -y";
    "Slack" = "choco install slack -y";
    "Docker" = "choco install docker-desktop -y";
    "OneDrive" = "choco install onedrive -y";
    "OBSStudio" = "choco install obs-studio -y";
    "VirtualBox" = "choco install virtualbox -y";
    "AdobeAcrobatReader" = "choco install adobereader -y";
    "Gimp" = "choco install gimp -y";
    "Krita" = "choco install krita -y";
    "Audacity" = "choco install audacity -y";
}

# Sort the hashtable in reverse alphabetical order
$SortedKeys = $UnsortedAppDB.Keys | Sort-Object 
foreach ($key in $SortedKeys) {
    $AppDB[$key] = $UnsortedAppDB[$key]
}



function ShowTopMessage {
    param (
        [string]$Message,
        [string]$Title
    )
    
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $messageBox = New-Object System.Windows.Forms.Form
    $messageBox.Text = $Title
    $messageBox.Size = New-Object System.Drawing.Size(300, 150)
    $messageBox.StartPosition = "CenterScreen"
    
    # Fixed division calculation
    $xPosition = [int](($screen.Width - $messageBox.Width) / 2)
    $messageBox.Location = New-Object System.Drawing.Point($xPosition, 0)
    $messageBox.TopMost = $true
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(260, 40)
    $messageBox.Controls.Add($label)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(110, 70)
    $messageBox.Controls.Add($okButton)
    
    $messageBox.ShowDialog()
}

function Install-Application {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$AppNames
    )

    $Form.Enabled = $false
    try {
        foreach ($App in $AppNames) {
            Write-Host "Installing $App..."
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "powershell.exe"
            $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$($AppDB[$App])`""
            # Changed these settings to show the window
            $processInfo.UseShellExecute = $true
            $processInfo.WindowStyle = 'Normal'
            $processInfo.CreateNoWindow = $false

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            $process.Start() | Out-Null
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) {
                ShowTopMessage -Message "Installation of $App failed with exit code $($process.ExitCode)." -Title "Error"
                Write-Error "Installation of $App failed with exit code $($process.ExitCode)."
                Write-Host $process
            } else {
                Write-Host "$App installed successfully."
            }
        }
  
    }
    catch {
        ShowTopMessage -Message "Installation error occurred" -Title "Error"
        Write-Error $_.Exception.Message
    }
    finally {
        $Form.Enabled = $true
    }
}

function handleChecked {
    $selected = @()
    foreach ($Control in $Form.Controls) {
        if ($Control -is [System.Windows.Forms.CheckBox] -and $Control.Checked) {
            $selected += $Control.Text
        }
    }
    
    if ($selected.Count -eq 0) {
        ShowTopMessage -Message "Select at least one application" -Title "Warning"
        return
    }

    $Form.BackColor = [System.Drawing.Color]::BlueViolet
    try {
        Install-Application -AppNames $selected
    }
    finally {
        $Form.BackColor = [System.Drawing.Color]::Black
    }
}

Write-Host "Initializing Do It For Me GUI..."

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Do It For Me"
$Form.size = New-Object System.Drawing.Size(600, 400)
$Form.TopMost = $true
$Form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::Black

$row1y = 35
$row2y = 35
$row3y = 35
$row4y = 35

foreach ($App in $AppDB.Keys) {
    $CheckBox = New-Object System.Windows.Forms.CheckBox
    $CheckBox.Text = $App
    $Checkbox.ForeColor = [System.Drawing.Color]::White
    $CheckBox.AutoSize = $true

    if ($Form.Controls.Count -lt 8) {
        $CheckBox.Location = New-Object System.Drawing.Point(20, $row1y)
        $row1y += 30
    } elseif ($Form.Controls.Count -lt 16) {
        $CheckBox.Location = New-Object System.Drawing.Point(150, $row2y)
        $row2y += 30
    } elseif ($Form.Controls.Count -lt 24) {
        $CheckBox.Location = New-Object System.Drawing.Point(280, $row3y)
        $row3y += 30
    } else {
        $CheckBox.Location = New-Object System.Drawing.Point(410, $row4y)
        $row4y += 30
    }

    $Form.Controls.Add($CheckBox)
}
$InstallBtn = New-Object System.Windows.Forms.Button
$InstallBtn.Text = "Install application(s)"
$InstallBtn.BackColor = [System.Drawing.Color]::Green
$InstallBtn.Add_Click({ handleChecked })
$InstallBtn.Location = New-Object System.Drawing.Point(50, 300)
$InstallBtn.Size = New-Object System.Drawing.Size(120, 30)

$Form.Controls.Add($InstallBtn)

# Show form and clean up
try {
    $Form.ShowDialog() | Out-Null
}
finally {
    if ($Form) {
        $Form.Dispose()
    }
}
try {
    if (Test-Path $EnvChocoInstall) {
        Write-Host "Cleaning up temporary Chocolatey installation..."
        Remove-Item $EnvChocoInstall -Recurse -Force
        Write-Host "Chocolatry Installation Cleaning Was Successful"
    }
}
catch {
    Write-Warning "Failed to clean up Chocolatey installation: $_"
}
