# Local smoke test — streams video/loop.mp4 to YouTube for a short time so you
# can confirm your stream key and video work BEFORE relying on GitHub Actions.
# Requires ffmpeg on PATH (https://ffmpeg.org/download.html, or `winget install ffmpeg`).
#
# Usage:
#   $env:YT_STREAM_KEY = "your-stream-key-here"
#   .\scripts\test-local.ps1

if (-not $env:YT_STREAM_KEY) {
    Write-Error "Set `$env:YT_STREAM_KEY first (see YouTube Studio > Go Live > Stream key)."
    exit 1
}

$video = Join-Path $PSScriptRoot "..\video\loop.mp4"
if (-not (Test-Path $video)) {
    Write-Error "No video at $video — drop your mp4 there first."
    exit 1
}

$streamUrl = "rtmp://a.rtmp.youtube.com/live2/$env:YT_STREAM_KEY"

ffmpeg -re -stream_loop -1 -i $video `
  -vf scale=1280:-2 `
  -c:v libx264 -preset veryfast -profile:v high `
  -b:v 3000k -maxrate 3000k -bufsize 6000k `
  -g 60 -keyint_min 60 -r 30 -pix_fmt yuv420p `
  -c:a aac -b:a 128k -ar 44100 `
  -f flv $streamUrl
