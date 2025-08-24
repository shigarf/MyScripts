<#
.SYNOPSIS
    YT-DLP Interactive Toolkit
.DESCRIPTION
    Interactive PowerShell toolkit for yt-dlp with video, audio, playlist, and batch downloads.
    Uses temp staging, subtitle array handling, filename sanitization, and per-file history logging.
.VERSION
    1.1.0 (2025-08-24)
#>

# =========================
#   CONFIGURATION
# =========================
$ScriptVersion = "1.1.0"
$UserName = $env:USERNAME
$TempDir  = "C:\Users\$UserName\Downloads\temp"
$VideoDir = "C:\Users\$UserName\Videos"
$MusicDir = "C:\Users\$UserName\Music"
$LogFile  = "C:\Users\$UserName\Documents\yt-dlp_history.log"

# Ensure directories exist
$null = New-Item -ItemType Directory -Force -Path $TempDir, $VideoDir, $MusicDir

# =========================
#   COLOR OUTPUT
# =========================
function Write-Color($Text, $Color="White") {
    Write-Host $Text -ForegroundColor $Color
}

# =========================
#   DEPENDENCY CHECK
# =========================
function Check-Dependency($cmd, $wingetId) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Color "[!] $cmd not found. Attempting to install via winget..." Yellow
        & winget install --id $wingetId -e --source winget --silent | Out-Host
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Color "[X] Failed to install $cmd. Install manually and re-run." Red
            return $false
        }
    }
    return $true
}

Write-Color " ╔══════════════════════════════════════╗" Cyan
Write-Color ("║   YT-DLP TOOLKIT v{0}                ║" -f $ScriptVersion) Green
Write-Color " ╠══════════════════════════════════════╣" Cyan
Write-Color " ║ Checking dependencies...             ║" Cyan
Write-Color " ╚══════════════════════════════════════╝" Cyan

$ytDlpOK = Check-Dependency "yt-dlp" "yt-dlp.yt-dlp"
$ffmpegOK = Check-Dependency "ffmpeg" "Gyan.FFmpeg"
if (-not ($ytDlpOK -and $ffmpegOK)) {
    Write-Color "Please ensure yt-dlp and ffmpeg are installed and in PATH." Red
    exit 1
}

# =========================
#   UTILITIES
# =========================
function Sanitize-PathSegment($name) {
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $regex = "[{0}]" -f [regex]::Escape($invalidChars)
    return ($name -replace $regex, "_")
}

function Log-Download($type, $url, $finalPath) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp | $type | $url | $finalPath"
}

function Move-StagedFiles {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$DestRoot,
        [Parameter()][string[]]$Extensions = @("*.mp4","*.mkv","*.webm","*.mp3"),
        [Parameter()][string]$Url = "",
        [Parameter(Mandatory)][string]$Type
    )
    $moved = 0
    foreach ($pattern in $Extensions) {
        Get-ChildItem -Path (Join-Path $SourceRoot "*") -Include $pattern -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $relative = Resolve-Path $_.FullName | ForEach-Object { $_.Path.Replace((Resolve-Path $SourceRoot).Path, "").TrimStart("\") }
            $destSubDir = Split-Path $relative -Parent
            $sanitizedSubDir = ($destSubDir -split "\\") | ForEach-Object { if ($_ -ne "") { Sanitize-PathSegment $_ } }
            $targetDir = if ($sanitizedSubDir) { Join-Path $DestRoot (Join-Path -Path "" -ChildPath ($sanitizedSubDir -join "\")) } else { $DestRoot }
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

            $safeName = Sanitize-PathSegment($_.Name)
            $finalPath = Join-Path $targetDir $safeName
            Move-Item -LiteralPath $_.FullName -Destination $finalPath -Force
            if ($Url) { Log-Download $Type $Url $finalPath } else { Log-Download $Type "<multiple>" $finalPath }
            $moved++
        }
    }
    return $moved
}

function Clean-EmptyDirs($root) {
    if (-not (Test-Path $root)) { return }
    Get-ChildItem -Path $root -Recurse -Directory | Sort-Object FullName -Descending | ForEach-Object {
        if (-not (Get-ChildItem -Path $_.FullName -Force)) {
            Remove-Item -Force -Recurse -Path $_.FullName -ErrorAction SilentlyContinue
        }
    }
    # If root is empty after operations, don't remove root itself (it's our temp)
}

# =========================
#   SUBTITLE OPTIONS (yt-dlp 2025.08.20)
# =========================
function Get-SubtitleOption {
    Write-Color "Subtitle Options:" Cyan
    Write-Color "[0] No subtitles" Yellow
    Write-Color "[1] Manual subtitles only" Yellow
    Write-Color "[2] Auto-generated subtitles only" Yellow
    Write-Color "[3] Manual + Auto-generated subtitles" Yellow
    Write-Color "[4] All available subtitles (manual + auto, all languages)" Yellow

    $subChoice = Read-Host "Select subtitle option"
    switch ($subChoice) {
        "0" { return @() }
        "1" { 
            $lang = Read-Host "Enter language code(s) (e.g., en or en,es)"
            return @("--write-sub", "--sub-langs", $lang, "--embed-subs")
        }
        "2" { 
            $lang = Read-Host "Enter language code(s) (e.g., en or en,es)"
            return @("--write-auto-sub", "--sub-langs", $lang, "--embed-subs")
        }
        "3" { 
            $lang = Read-Host "Enter language code(s) (e.g., en or en,es)"
            return @("--write-sub", "--write-auto-sub", "--sub-langs", $lang, "--embed-subs")
        }
        "4" { 
            return @("--write-sub", "--write-auto-sub", "--sub-langs", "all", "--embed-subs")
        }
        default { 
            Write-Color "Invalid choice, no subtitles will be downloaded." Red
            return @()
        }
    }
}

# =========================
#   MENU
# =========================
function Show-Menu {
    Clear-Host
    Write-Color " ╔═════════════════════════════════════════════╗" Cyan
    Write-Color(" ║   YT-DLP TOOLKIT v{0} - INTERACTIVE       ║" -f $ScriptVersion) Green
    Write-Color " ╠═════════════════════════════════════════════╣" Cyan
    Write-Color " ║ [1] Download Video (with subtitles option)  ║" Yellow
    Write-Color " ║ [2] Download MP3 Audio                      ║" Yellow
    Write-Color " ║ [3] Download Entire Playlist                ║" Yellow
    Write-Color " ║ [4] Batch Download from Text File           ║" Yellow
    Write-Color " ║ [0] Exit                                    ║" Red
    Write-Color " ╚═════════════════════════════════════════════╝" Cyan
}

# =========================
#   DOWNLOADS
# =========================
function Download-Video {
    $url = Read-Host "Enter the video URL"
    $subs = Get-SubtitleOption
    # Stage to temp root
    yt-dlp @subs -o "$TempDir\%(title)s.%(ext)s" $url

    $moved = Move-StagedFiles -SourceRoot $TempDir -DestRoot $VideoDir -Extensions @("*.mp4","*.mkv","*.webm") -Url $url -Type "VIDEO"
    if ($moved -gt 0) {
        Write-Color "Video saved to $VideoDir" Green
    } else {
        Write-Color "No video files found to move. Check yt-dlp output." Red
    }
    Clean-EmptyDirs $TempDir
    Pause
}

function Download-MP3 {
    $url = Read-Host "Enter the video URL"
    yt-dlp --extract-audio --audio-format mp3 -o "$TempDir\%(title)s.%(ext)s" $url

    $moved = Move-StagedFiles -SourceRoot $TempDir -DestRoot $MusicDir -Extensions @("*.mp3") -Url $url -Type "AUDIO"
    if ($moved -gt 0) {
        Write-Color "Audio saved to $MusicDir" Green
    } else {
        Write-Color "No audio files found to move. Check yt-dlp output." Red
    }
    Clean-EmptyDirs $TempDir
    Pause
}

function Download-Playlist {
    $url = Read-Host "Enter the playlist URL"
    $subs = Get-SubtitleOption
    # Stage under temp\playlist\<playlist_title>
    $stageRoot = Join-Path $TempDir "playlist"
    New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
    yt-dlp @subs -o "$stageRoot\%(playlist_title)s\%(title)s.%(ext)s" $url

    # Move preserving subfolders into Videos\<sanitized playlist title>\...
    $moved = Move-StagedFiles -SourceRoot $stageRoot -DestRoot $VideoDir -Extensions @("*.mp4","*.mkv","*.webm") -Url $url -Type "PLAYLIST"
    if ($moved -gt 0) {
        Write-Color "Playlist videos saved under $VideoDir\<playlist title>" Green
    } else {
        Write-Color "No playlist files found to move. Check yt-dlp output." Red
    }
    # Cleanup the stage area
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $stageRoot
    Pause
}

function Batch-Download {
    $filePath = Read-Host "Enter path to the text file (format: URL|FolderName per line)"
    if (-not (Test-Path $filePath)) {
        Write-Color "File not found: $filePath" Red
        Pause
        return
    }
    $lines = Get-Content $filePath | Where-Object { $_.Trim() -ne "" }
    if (-not $lines) {
        Write-Color "The file is empty." Red
        Pause
        return
    }

    foreach ($line in $lines) {
        $parts = $line -split "\|"
        if ($parts.Count -lt 2) {
            Write-Color "Invalid line (expected URL|FolderName): $line" Red
            continue
        }
        $url = $parts[0].Trim()
        $folderName = Sanitize-PathSegment($parts[1].Trim())
        if (-not $url) { Write-Color "Skipping blank URL entry." Red; continue }

        # Stage under temp\batch\<folderName>
        $stageRoot = Join-Path (Join-Path $TempDir "batch") $folderName
        New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

        $subs = Get-SubtitleOption
        yt-dlp @subs -o "$stageRoot\%(title)s.%(ext)s" $url

        # Move to Videos\<folderName>
        $targetRoot = Join-Path $VideoDir $folderName
        $moved = Move-StagedFiles -SourceRoot $stageRoot -DestRoot $targetRoot -Extensions @("*.mp4","*.mkv","*.webm") -Url $url -Type "BATCH"
        if ($moved -eq 0) {
            Write-Color "No files moved for: $url" Red
        }

        # Clean this stage folder
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $stageRoot
    }

    # Clean broader temp if any empty dirs left
    Clean-EmptyDirs $TempDir
    Write-Color "Batch download complete." Green
    Pause
}

# =========================
#   MAIN LOOP
# =========================
do {
    Show-Menu
    $choice = Read-Host "Select an option"
    switch ($choice) {
        "1" { Download-Video }
        "2" { Download-MP3 }
        "3" { Download-Playlist }
        "4" { Batch-Download }
        "0" { Write-Color "Exiting..." Cyan }
        default { Write-Color "Invalid choice, try again." Red; Pause }
    }
} while ($choice -ne "0")