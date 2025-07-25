<#
.SYNOPSIS
  ESPTool v5 Automator — Flashing & eFuse Management
.DESCRIPTION
  PowerShell 7 script for ESP32-WROOM-32E / ESP32-S3 flashing,
  eFuse management, MAC read/write, memory dump, and more.
  Interactive console UI with ASCII interface, supports esptool v5.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = "ESPTool Automator"

#------------------------------------------------------------
# Global Config
#------------------------------------------------------------
$script:baud = 460800  # Default baud rate for esptool

#------------------------------------------------------------
# UI Color Palette and Version
#------------------------------------------------------------
$script:UIColors = @{
    Title     = 'DarkCyan'
    Section   = 'Magenta'
    MenuItem  = 'White'
    Highlight = 'Blue'
    Warning   = 'Yellow'
    Error     = 'Red'
}
$script:Version = '1.1.0'
$script:subtitle = "ESPTool v5 Automator"

#------------------------------------------------------------
# UI Functions
#------------------------------------------------------------
function Show-Separator {
    param(
        [string]$Char = '─'
    )
    $width = $Host.UI.RawUI.WindowSize.Width - 1
    Write-Host ($Char * $width) -ForegroundColor $script:UIColors.Section
}

function Show-Logo {
    $logoLines = @(
    '    ____    _   _   ___    ____    ____  __   __   ',
    '   / ___|  | | | | |_ _|  / ___|  / ___| \ \ / /   ',
    '   \___ \  | |_| |  | |  | |  _  | |  _   \ V /    ',
    '    ___) | |  _  |  | |  | |_| | | |_| |   | |     ',
    '   |____/  |_| |_| |___|  \____|  \____|   |_|     ',
        "         v$($script:subtitle)        "
        "         v$($script:Version)        "
    )
    foreach ($line in $logoLines) {
        $pad = [Math]::Floor((($Host.UI.RawUI.WindowSize.Width - $line.Length)/2))
        Write-Host (' ' * $pad) $line -ForegroundColor $script:UIColors.Title
    }
}

function Show-Header {
    Clear-Host
    Show-Separator
    Show-Logo
    Show-Separator

    $status = " Port: $port    Chip: $chip    Baud: $script:baud "
    $pad    = [Math]::Floor((($Host.UI.RawUI.WindowSize.Width - $status.Length)/2))
    Write-Host (' ' * $pad) $status -ForegroundColor $script:UIColors.MenuItem

    Show-Separator
    Write-Host ''
}

function Show-Menu {
    Show-Header

    $sections = @(
        @{ Title = 'Main Actions';     Keys = 1..6           },
        @{ Title = 'Advanced Actions'; Keys = 7..12          },
        @{ Title = 'Utility Actions';  Keys = @(13,14,0,'R') }
    )

    $chunkSize = 4

    foreach ($sec in $sections) {
        # Center the section title
        $secTitle = "  $($sec.Title)  "
        $pad      = [Math]::Floor((($Host.UI.RawUI.WindowSize.Width - $secTitle.Length) / 2))
        Write-Host (' ' * $pad) $secTitle -ForegroundColor $script:UIColors.Section

        # Break the keys into groups of $chunkSize
        $keys = $sec.Keys
        for ($i = 0; $i -lt $keys.Count; $i += $chunkSize) {
            $end = [Math]::Min($i + $chunkSize - 1, $keys.Count - 1)
            $group = $keys[$i..$end]

            # Build and print one line of up to 4 items
            $line = ''
            foreach ($key in $group) {
                $label = $menuMap[$key]
                $line += "[{0}] {1,-18}" -f $key, $label
            }
            Write-Host $line -ForegroundColor $script:UIColors.MenuItem
        }

        Write-Host ''  # blank line after each section
    }

    Write-Host "Type [R] to select serial port" -ForegroundColor $script:UIColors.Warning
    Write-Host ''  # final padding
}

#------------------------------------------------------------
# Core Functionality
#------------------------------------------------------------
$menuMap = @{
     1 = "Read Chip ID";      2 = "Read Flash ID";   3 = "Erase Flash"
     4 = "Flash Firmware";    5 = "Dump Flash";      6 = "Read MAC"
     7 = "Write MAC";         8 = "Read eFuses";     9 = "Burn eFuse"
    10 = "Read Memory";      11 = "Write Memory";   12 = "Load+Exec Stub"
    13 = "Reset Chip";       14 = "esptool Version"; 0 = "Exit"
    'R'= "Select Serial Port"
}

function Get-EsptoolPath {
    Clear-Host
    Show-Separator
    $title = "ESPTool v5 Automator"
    $pad   = [Math]::Floor((($Host.UI.RawUI.WindowSize.Width - $title.Length)/2))
    Write-Host (' ' * $pad) $title -ForegroundColor $script:UIColors.Title
    Show-Separator

    Write-Host "Checking for esptool.exe ..." -ForegroundColor $script:UIColors.Warning
    $cmd = Get-Command esptool.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "Found esptool.exe in PATH." -ForegroundColor Green
        return "esptool.exe"
    }
    elseif (Test-Path ".\esptool.exe") {
        Write-Host "Found local esptool.exe." -ForegroundColor Green
        return ".\esptool.exe"
    }
    else {
        Write-Host "[ERROR] esptool.exe not found. Please install and retry." -ForegroundColor $script:UIColors.Error
        exit 1
    }
}

function Get-EspefusePath {
    Write-Host "Checking for espefuse.exe ..." -ForegroundColor $script:UIColors.Warning
    $cmd = Get-Command espefuse.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "Found espefuse.exe in PATH." -ForegroundColor Green
        return "espefuse.exe"
    }
    elseif (Test-Path ".\espefuse.exe") {
        Write-Host "Found local espefuse.exe." -ForegroundColor Green
        return ".\espefuse.exe"
    }
    else {
        Write-Host "[ERROR] espefuse.exe not found. Install via 'pip install esptool'." -ForegroundColor $script:UIColors.Error
        exit 1
    }
}

function Get-SerialPort {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames()
    if (-not $ports -or $ports.Count -eq 0) {
        Write-Error "No COM ports found. Connect your ESP device and try again."
        return $null
    }
    if ($ports.Count -eq 1) {
        Write-Host "Auto-selected port: $($ports[0])" -ForegroundColor Green
        return $ports[0]
    }

    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    Write-Host "|  Available COM Ports          |" -ForegroundColor Cyan
    Write-Host "+-------------------------------+" -ForegroundColor Cyan

    for ($i = 0; $i -lt $ports.Count; $i++) {
        Write-Host " [$i] $($ports[$i])"
    }

    do {
        $idx = Read-Host "Select index (0-$($ports.Count - 1))"
    } until ($idx -match '^\d+$' -and [int]$idx -lt $ports.Count)

    $port = $ports[[int]$idx]
    Show-Separator
    Write-Host "Selected port: $port" -ForegroundColor Green
    return $port
}

function Select-Chip {
    Write-Host ''
    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    Write-Host "|  Select Chip                  |" -ForegroundColor Cyan
    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    Write-Host "|  [0] Auto Detect              |" -ForegroundColor Cyan
    Write-Host "|  [1] ESP32-WROOM-32E          |" -ForegroundColor Cyan
    Write-Host "|  [2] ESP32-S3                 |" -ForegroundColor Cyan
    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    Write-Host ''

    do {
        Write-Host "Enter choice-" -ForegroundColor $script:UIColors.Warning
        $choice = Read-Host
        if (-not $choice) {
            Write-Host "Please enter a valid choice." -ForegroundColor $script:UIColors.Error
            continue
        }
    } until ($choice -in '0','1','2')

    switch ($choice) {
        '0' { return "auto"   }
        '1' { return "esp32"  }
        '2' { return "esp32s3" }
    }
}

function TryGetBinPath {
    param (
        [System.IO.FileInfo[]]$Bins,
        [string]$Pattern,
        [string]$Label
    )
    $match = $Bins | Where-Object { $_.BaseName -match $Pattern } | Select-Object -First 1
    if ($match) {
        Write-Host ("Found {0}: {1}" -f $Label, $match.Name) -ForegroundColor Green
        return $match.FullName
    }
    else {
        Write-Host "Could not detect $Label automatically." -ForegroundColor $script:UIColors.Warning
        return $null
    }
}

function Invoke-Esptool {
    [CmdletBinding()]
    param (
        [string[]]$EsptoolArgs
    )
    $cmd = "esptool {0}" -f ($EsptoolArgs -join ' ')
    Write-Host "Running: $cmd" -ForegroundColor Cyan
    & $script:esptoolPath @EsptoolArgs
}

function Invoke-Espefuse {
    [CmdletBinding()]
    param (
        [string[]]$EspefuseArgs
    )
    $cmd = "espefuse {0}" -f ($EspefuseArgs -join ' ')
    Write-Host "Running: $cmd" -ForegroundColor Cyan
    & $script:espefusePath @EspefuseArgs
}

#------------------------------------------------------------
# Initialization
#------------------------------------------------------------
$script:esptoolPath = Get-EsptoolPath
$script:espefusePath = Get-EspefusePath
$port = Get-SerialPort
if (-not $port) { exit 1 }
$chip = Select-Chip

#------------------------------------------------------------
# Main Loop
#------------------------------------------------------------
while ($true) {
    Clear-Host
    Show-Menu
    Show-Separator

    $selection = Read-Host "Select option or [R] to select serial port"

    if ($selection -match '^[Rr]$') {
        $newPort = Get-SerialPort
        if ($newPort) { $port = $newPort }
        continue
    }

    if (-not [int]::TryParse($selection, [ref]$null)) {
        Write-Host "Invalid input. Please enter a number or R." -ForegroundColor $script:UIColors.Error
        continue
    }

    $selInt = [int]$selection
    if (-not $menuMap.ContainsKey($selInt)) {
        Write-Host "Invalid option. Please select a valid choice." -ForegroundColor $script:UIColors.Error
        continue
    }

    Clear-Host
    Show-Separator
    Write-Host ("Selected: [{0}] {1}" -f $selInt, $menuMap[$selInt]) `
        -ForegroundColor $script:UIColors.MenuItem `
        -BackgroundColor $script:UIColors.Highlight
    Show-Separator

    switch ($selInt) {
        1  { Invoke-Esptool    -EsptoolArgs @('--chip',$chip,'--port',$port,'chip-id') }
        2  { Invoke-Esptool    -EsptoolArgs @('--chip',$chip,'--port',$port,'flash-id') }
        3  { Invoke-Esptool    -EsptoolArgs @('--chip',$chip,'--port',$port,'erase-flash') }
        4  {
            $fwFolder = Read-Host "Enter folder path [bootloader.bin, partition-table.bin, firmware/app.bin]"
            if (Test-Path $fwFolder) {
                $bins = Get-ChildItem $fwFolder -Filter *.bin -File
                $boot = TryGetBinPath -Bins $bins -Pattern '^boot'      -Label 'bootloader'
                $part = TryGetBinPath -Bins $bins -Pattern '^part'      -Label 'partition-table'
                $app  = TryGetBinPath -Bins $bins -Pattern '^(firm|app)'-Label 'firmware/app'
                if (-not $boot) { $boot = Read-Host "Bootloader.bin path" }
                if (-not $part) { $part = Read-Host "Partition-table.bin path" }
                if (-not $app)  { $app  = Read-Host "Firmware.bin path" }
            }
            else {
                Write-Host "⚠ Folder not found — manual entry required." -ForegroundColor $script:UIColors.Error
                $boot = Read-Host "Bootloader.bin path"
                $part = Read-Host "Partition-table.bin path"
                $app  = Read-Host "Firmware.bin path"
            }
            Invoke-Esptool -EsptoolArgs @(
                '--chip',$chip,'--port',$port,'--baud',$script:baud,
                'write-flash','-z',
                '0x1000',$boot,
                '0x8000',$part,
                '0x10000',$app
            )
        }
        5  {
            $startOffset = Read-Host "Start offset (hex, e.g. 0x00000)"
            $length      = Read-Host "Length (decimal)"
            $outputFile  = Read-Host "Output filename"
            Invoke-Esptool -EsptoolArgs @(
                '--chip',$chip,'--port',$port,
                'dump-flash','--start',$startOffset,'--length',$length,
                $outputFile
            )
        }
        6  { Invoke-Esptool -EsptoolArgs @('--chip',$chip,'--port',$port,'read-mac') }
        7  {
            $newMac = Read-Host "Enter new MAC (xx:xx:xx:xx:xx:xx)"
            Invoke-Esptool -EsptoolArgs @('--chip',$chip,'--port',$port,'write-mac',$newMac)
        }
        8  { Invoke-Espefuse -EspefuseArgs @('--chip',$chip,'--port',$port,'summary') }
        9  {
            $efuseField = Read-Host "Enter eFuse to burn (e.g. DIS_USB_JTAG)"
            Invoke-Espefuse -EspefuseArgs @('--chip',$chip,'--port',$port,'burn-efuse',$efuseField)
        }
       10 {
            $address = Read-Host "Memory address (hex)"
            $count   = Read-Host "Byte count (decimal)"
            $file    = Read-Host "Output filename"
            Invoke-Esptool -EsptoolArgs @('--chip',$chip,'--port',$port,'read-memory',$address,$count,$file)
        }
       11 {
            $address = Read-Host "Memory address (hex)"
            $file    = Read-Host "Input filename"
            Invoke-Esptool -EsptoolArgs @('--chip',$chip,'--port',$port,'write-memory',$address,$file)
        }
       12 {
            $address  = Read-Host "RAM address to load stub (hex)"
            $stubFile = Read-Host "Stub filename to load"
            Invoke-Esptool -EsptoolArgs @('--chip',$chip,'--port',$port,'load-ram',$address,$stubFile)
        }
       13 { Invoke-Esptool -EsptoolArgs @('--chip',$chip,'--port',$port,'run') }
       14 { Invoke-Esptool -EsptoolArgs @('version') }
        0 {
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0
        }
    }

    Write-Host ''
    Write-Host "Press any key to continue..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}