param()

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "chrome-extension\images"
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

foreach ($size in @(16, 32, 48, 128)) {
  $bitmap = [System.Drawing.Bitmap]::new($size, $size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.Clear([System.Drawing.Color]::Transparent)

  $background = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 79, 70, 229)
  )
  $margin = if ($size -eq 128) { 16 } else { [Math]::Max(1, [Math]::Round($size * 0.04)) }
  $artSize = $size - (2 * $margin)
  $graphics.FillEllipse($background, $margin, $margin, $artSize, $artSize)

  $strokeWidth = [Math]::Max(2, $artSize * 0.09)
  $keyPen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, $strokeWidth)
  $keyPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $keyPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

  $ringSize = $artSize * 0.28
  $ringX = $margin + ($artSize * 0.23)
  $ringY = $margin + ($artSize * 0.24)
  $graphics.DrawEllipse($keyPen, $ringX, $ringY, $ringSize, $ringSize)

  $shaftStartX = $ringX + ($ringSize * 0.78)
  $shaftStartY = $ringY + ($ringSize * 0.78)
  $shaftEndX = $margin + ($artSize * 0.76)
  $shaftEndY = $margin + ($artSize * 0.77)
  $graphics.DrawLine($keyPen, $shaftStartX, $shaftStartY, $shaftEndX, $shaftEndY)
  $graphics.DrawLine(
    $keyPen,
    $margin + ($artSize * 0.64),
    $margin + ($artSize * 0.65),
    $margin + ($artSize * 0.58),
    $margin + ($artSize * 0.72)
  )
  $graphics.DrawLine(
    $keyPen,
    $margin + ($artSize * 0.72),
    $margin + ($artSize * 0.73),
    $margin + ($artSize * 0.66),
    $margin + ($artSize * 0.80)
  )

  $outputPath = Join-Path $outputDirectory "icon$size.png"
  $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $keyPen.Dispose()
  $background.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

Write-Host "Generated Chrome extension icons: $outputDirectory"
