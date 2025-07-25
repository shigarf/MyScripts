<#
.SYNOPSIS
  ESPTool v5 Automator — Flashing & eFuse Management
.DESCRIPTION
  PowerShell 7 script for ESP32-WROOM-32E / ESP32-S3 flashing, reading eFuses, MAC, and memory.
  Interactive console UI with ASCII interface, supports esptool v5.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = "ESPTool Automator"

# Global Config
$script:baud = 460800
$width = { $Host.UI.RawUI.WindowSize.Width - 1 }
$sep   = { '-' * (&$width) }

# Menu options map
$menuMap = @{
    1  = "Read Chip ID"
    2  = "Read Flash ID"
    3  = "Erase Flash"
    4  = "Flash Firmware"
    5  = "Dump Flash"
    6  = "Read MAC"
    7  = "Write MAC"
    8  = "Read eFuses"
    9  = "Burn eFuse"
    10 = "Read Memory"
    11 = "Write Memory"
    12 = "Load+Exec Stub"
    13 = "Reset Chip"
    14 = "esptool Version"
    0  = "Exit"
}

# Function: Detect esptool.exe path
function Get-EsptoolPath {
    Write-Host "Checking for esptool.exe ..." -ForegroundColor Yellow
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
        Write-Host "[ERROR] esptool.exe not found. Please install and retry." -ForegroundColor Red
        exit 1
    }
}

# Function: Detect espefuse.exe path
function Get-EspefusePath {
    Write-Host "Checking for espefuse ..." -ForegroundColor Yellow
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
        Write-Host "[ERROR] espefuse.exe not found. Install via 'pip install esptool'." -ForegroundColor Red
        exit 1
    }
}

# Function: Get serial port with selection
function Get-SerialPort {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($null -eq $ports -or $ports.Length -eq 0) {
        Write-Error "No COM ports found. Connect your ESP device and try again."
        exit
    }
    elseif ($ports.Count -eq 1) {
        Write-Host "Auto-selected port: $($ports[0])" -ForegroundColor Green
        return $ports[0]
    }
    else {
        Write-Host "Available COM ports:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $ports.Count; $i++) {
            Write-Host " [$i] $($ports[$i])"
        }
        $idx = Read-Host "Select index (0-$($ports.Count - 1))"
        if ($idx -match '^\d+$' -and $idx -lt $ports.Count) {
            return $ports[$idx]
        }
        Write-Host "Invalid selection. Exiting." -ForegroundColor Red
        exit
    }
}

# Function: Select chip type
function Select-Chip {
    Clear-Host
    Write-Host ""
    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    Write-Host "|  Select Chip                  |" -ForegroundColor Cyan
    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    Write-Host "|  [1] ESP32-WROOM-32E          |" -ForegroundColor Cyan
    Write-Host "|  [2] ESP32-S3                 |" -ForegroundColor Cyan
    Write-Host "+-------------------------------+" -ForegroundColor Cyan
    do {
        $choice = Read-Host "Enter choice (1 or 2)"
    } until ($choice -in '1','2')

    if ($choice -eq '2') {
        return "esp32s3"
    }
    else {
        return "esp32"
    }
}

# Function: Show header
function Show-Header {
    Clear-Host
    Write-Host (&$sep) -ForegroundColor DarkCyan
    $title = "ESPTool v5 Automator"
    $pad   = [Math]::Max(0, [Math]::Floor(((&$width) - $title.Length)/2))
    Write-Host (" " * $pad) $title
    Write-Host (&$sep) -ForegroundColor DarkCyan
    Write-Host ("Port: {0,-8} Chip: {1,-8} Baud: {2}" -f $port, $chip, $script:baud) -ForegroundColor Green
    Write-Host (&$sep) -ForegroundColor DarkCyan
    Write-Host ""
}

# Function: Show menu nicely formatted
function Show-Menu {
    Show-Header
    $sections = @(
        @{Title = "Main Actions";      Keys = 1..6},
        @{Title = "Advanced Actions";  Keys = 7..12},
        @{Title = "Utility Actions";   Keys = @(13,14,0)}
    )
    foreach ($section in $sections) {
        Write-Host ""
        Write-Host "== $($section.Title) ==" -ForegroundColor Magenta
        $line = ""
        foreach ($key in $section.Keys) {
            $line += "[{0}] {1,-16}" -f $key, $menuMap[$key]
        }
        Write-Host $line
    }
    Write-Host ""
}

# Function: Run esptool with progress (renamed parameter to avoid collision)
function Invoke-Esptool {
    [CmdletBinding()]
    param(
        [string[]]$EsptoolArgs      # was $ToolArgs or $esptoolArgs
    )
    $cmd = "esptool {0}" -f ($EsptoolArgs -join ' ')
    Write-Host "Running: $cmd" -ForegroundColor Cyan

    & $script:esptoolPath @EsptoolArgs
}

# Function: Run espefuse command
function Invoke-Espefuse {
    [CmdletBinding()]
    param(
        [string[]]$EspefuseArgs     # avoid using $espfuseArgs
    )
    $cmd = "espefuse {0}" -f ($EspefuseArgs -join ' ')
    Write-Host "Running: $cmd" -ForegroundColor Cyan

    & $script:espefusePath @EspefuseArgs
}

# Initialization
$script:esptoolPath = Get-EsptoolPath
$script:espefusePath = Get-EspefusePath
$port             = Get-SerialPort
$chip             = Select-Chip

# Main loop
while ($true) {
    Clear-Host
    Show-Menu
    Write-Host (&$sep) -ForegroundColor DarkCyan
    $selection = Read-Host "Select option"

    if (-not [int]::TryParse($selection, [ref]$null)) {
        Write-Host "Invalid input. Please enter a number from 0 to 14." -ForegroundColor Red
        continue
    }
    if (-not $menuMap.ContainsKey([int]$selection)) {
        Write-Host "Invalid option. Please select a valid choice." -ForegroundColor Red
        continue
    }

    Clear-Host
    Write-Host ("Selected: [{0}] {1}" -f $selection, $menuMap[[int]$selection]) -ForegroundColor Yellow
    Write-Host (&$sep) -ForegroundColor DarkCyan

    switch ([int]$selection) {
        1 {
            $esptoolArgs = @('--chip', $chip, '--port', $port, 'chip-id')
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        2 {
            $esptoolArgs = @('--chip', $chip, '--port', $port, 'flash-id')
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        3 {
            $esptoolArgs = @('--chip', $chip, '--port', $port, 'erase-flash')
            Invoke-Esptool -EsptoolArgs $esptoolArgs 
        }
        4 {
            $fwFolder = Read-Host "Enter firmware folder path"
            if (Test-Path $fwFolder) {
                $bins = Get-ChildItem $fwFolder -Filter *.bin -File
                $boot = ($bins | Where-Object { $_.BaseName -match '^boot' }    | Select-Object -First 1).FullName
                $part = ($bins | Where-Object { $_.BaseName -match '^part' }    | Select-Object -First 1).FullName
                $app  = ($bins | Where-Object { $_.BaseName -match '^(firm|app)' } | Select-Object -First 1).FullName

                if (-not $boot) { $boot = Read-Host "Enter bootloader.bin full path" }
                if (-not $part) { $part = Read-Host "Enter partition-table.bin full path" }
                if (-not $app)  { $app  = Read-Host "Enter firmware.bin full path" }
            }
            else {
                Write-Host "Folder not found, entering files manually." -ForegroundColor Red
                $boot = Read-Host "Bootloader.bin path"
                $part = Read-Host "Partition-table.bin path"
                $app  = Read-Host "Firmware.bin path"
            }

            $esptoolArgs = @(
                '--chip',  $chip,
                '--port',  $port,
                '--baud',  $script:baud,
                'write-flash', '-z',
                '0x1000',  $boot,
                '0x8000',  $part,
                '0x10000', $app
            )
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        5 {
            $startOffset = Read-Host "Start offset (hex, e.g. 0x00000)"
            $length      = Read-Host "Length (decimal)"
            $outputFile  = Read-Host "Output filename"
            $esptoolArgs = @(
                '--chip', $chip,
                '--port', $port,
                'dump-flash',
                '--start', $startOffset,
                '--length',$length,
                $outputFile
            )
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        6 {
            $esptoolArgs = @('--chip', $chip, '--port', $port, 'read-mac')
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        7 {
            $newMac = Read-Host "Enter new MAC (xx:xx:xx:xx:xx:xx)"
            $esptoolArgs   = @('--chip', $chip, '--port', $port, 'write-mac', $newMac)
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        8 {
            $espfuseArgs = @('--chip', $chip, '--port', $port, 'summary')
            Invoke-Espefuse $espfuseArgs
        }
        9 {
            $efuseField = Read-Host "Enter eFuse to burn (e.g. DIS_USB_JTAG)"
            $espfuseArgs       = @('--chip', $chip, '--port', $port, 'burn-efuse', $efuseField)
            Invoke-Espefuse $espfuseArgs
        }
        10 {
            $address = Read-Host "Memory address (hex)"
            $count   = Read-Host "Byte count (decimal)"
            $file    = Read-Host "Output filename"
            $esptoolArgs    = @('--chip', $chip, '--port', $port, 'read-memory', $address, $count, $file)
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        11 {
            $address = Read-Host "Memory address (hex)"
            $file    = Read-Host "Input filename"
            $esptoolArgs    = @('--chip', $chip, '--port', $port, 'write-memory', $address, $file)
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        12 {
            $address  = Read-Host "RAM address to load stub (hex)"
            $stubFile = Read-Host "Stub filename to load"
            $esptoolArgs     = @('--chip', $chip, '--port', $port, 'load-ram', $address, $stubFile)
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        13 {
            $esptoolArgs = @('--chip', $chip, '--port', $port, 'run')
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        14 {
            $esptoolArgs = @('version')
            Invoke-Esptool -EsptoolArgs $esptoolArgs
        }
        0 {
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0
        }
    }

    Write-Host ""
    Write-Host "Press any key to continue..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}