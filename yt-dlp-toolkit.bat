@echo off
setlocal EnableDelayedExpansion

:: === FFMPEG CHECK ===
where /Q ffmpeg.exe
if ERRORLEVEL 1 (
  echo [WARN] ffmpeg.exe not found in PATH.

  rem Check script folder
  if not exist "%SCRIPT_DIR%ffmpeg.exe" (
    echo [ERROR] ffmpeg.exe not found. 
    echo Please install FFmpeg or copy ffmpeg.exe into %SCRIPT_DIR%.
    pause & exit /b
  ) else (
    echo [INFO] Found ffmpeg.exe in script directory.
    set "FFMPEG=%SCRIPT_DIR%ffmpeg.exe"
  )
) else (
  echo [INFO] Found ffmpeg in PATH.
  set "FFMPEG=ffmpeg"
)

:: === VERSION & AUTHOR INFO ===
set "SCRIPT_VERSION=yt-dlp-toolkit v1.6"
set "SCRIPT_AUTHOR=Syed S. Mashaam"

:: === SCRIPT & OUTPUT PATHS ===
set "SCRIPT_DIR=%~dp0"
set "YTDLP=C:\yt-dlp\yt-dlp.exe"
set "OUTDIR=%USERPROFILE%\Videos\YT-DLP"

:: === INITIAL SETUP ===
if not exist "%YTDLP%" (
  echo [ERROR] yt-dlp.exe not found in %SCRIPT_DIR%
  pause & exit /b
)
if not exist "%USERPROFILE%\Videos" (
  echo [ERROR] Videos directory does not exist. Creating it...
  mkdir "%USERPROFILE%\Videos"
)
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

:: === MAIN MENU ===
:MainMenu
cls
echo ============================================
echo        %SCRIPT_VERSION%
echo        Author: %SCRIPT_AUTHOR%
echo        YouTube Toolkit
echo ============================================
echo.
echo [1] Download video + subtitles into folder
echo [2] Extract MP3 audio
echo [3] Download entire playlist
echo [Q] Quit
echo ============================================
set /p choice=Choose an option: 
if /I "%choice%"=="1" goto DoOption1
if /I "%choice%"=="2" goto DoOption2
if /I "%choice%"=="3" goto DoOption3
if /I "%choice%"=="Q" exit /b
goto MainMenu

:DoOption1
set /p VIDEO_URL=Enter YouTube URL: 
echo [INFO] Downloading video + subtitles...
"%YTDLP%" --write-subs --write-auto-sub --sub-lang en --convert-subs srt ^
  -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" ^
  -o "%OUTDIR%\%%(title)s\%%(title)s.%%(ext)s" "%VIDEO_URL%"
goto TaskEnd

:DoOption2
set /p VIDEO_URL=Enter YouTube URL: 
echo [INFO] Extracting MP3 audio...
"%YTDLP%" --extract-audio --audio-format mp3 -o "%OUTDIR%\%%(title)s.%%(ext)s" "%VIDEO_URL%"
goto TaskEnd

:DoOption3
set /p VIDEO_URL=Enter Playlist URL: 
echo [INFO] Downloading entire playlist...
"%YTDLP%" -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" ^
  -o "%OUTDIR%\%%(playlist_title)s\%%(playlist_index)s - %%(title)s.%%(ext)s" "%VIDEO_URL%"
goto TaskEnd

:TaskEnd
echo.
echo [INFO] Task/Tasks completed.
pause
exit /b