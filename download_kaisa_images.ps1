<#
Downloads five Unsplash stock photos for KAISA's login background crossfade.
Run this from the ROOT of your Flutter project:
  powershell -ExecutionPolicy Bypass -File .\download_kaisa_images.ps1
Each file goes in assets/images/, which your pubspec.yaml already includes.
#>
param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$imagesDirectory = Join-Path $ProjectRoot 'assets\images'
New-Item -ItemType Directory -Path $imagesDirectory -Force | Out-Null

$photos = @(
  @{ Name = 'kaisa_bg_01.jpg'; Id = 'photo-1529156069898-49953e39b3ac' }, # Community / friendship
  @{ Name = 'kaisa_bg_02.jpg'; Id = 'photo-1522202176988-66273c2fd55f' }, # Learning / teamwork
  @{ Name = 'kaisa_bg_03.jpg'; Id = 'photo-1529333166437-7750a6dd5a70' }, # Group / community
  @{ Name = 'kaisa_bg_04.jpg'; Id = 'photo-1542601906990-b4d3fb778b09' }, # Environment
  @{ Name = 'kaisa_bg_05.jpg'; Id = 'photo-1556761175-b413da4baf72' }  # Collaboration
)

$failures = 0
foreach ($photo in $photos) {
  $destination = Join-Path $imagesDirectory $photo.Name
  $url = "https://images.unsplash.com/$($photo.Id)?auto=format&fit=crop&w=1600&q=82"
  Write-Host "Downloading $($photo.Name)..." -ForegroundColor Cyan
  try {
    Invoke-WebRequest -Uri $url -OutFile $destination -TimeoutSec 60 -Headers @{'User-Agent'='Mozilla/5.0'}
    if ((Get-Item $destination).Length -lt 5000) {
      throw "Image is unexpectedly small."
    }
    Write-Host "Saved $destination" -ForegroundColor Green
  } catch {
    $failures++
    Remove-Item -LiteralPath $destination -ErrorAction SilentlyContinue
    Write-Warning "Could not download $($photo.Name): $_"
  }
}

if ($failures -gt 0) {
  Write-Warning "$failures image(s) failed. The Flutter page falls back to online images / its dark green background."
} else {
  Write-Host 'All five login images are now installed in assets/images/.' -ForegroundColor Green
}
Write-Host 'Restart your Flutter app (flutter run -d chrome) to bundle local assets.'
