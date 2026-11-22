param()

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
  param(
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [float]$Radius
  )

  $diameter = $Radius * 2
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "images"
$outputPath = Join-Path $outputDirectory "store-promo-small.png"
$iconPath = Join-Path $projectRoot "chrome-extension\images\icon128.png"

if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
  throw "Extension icon not found: $iconPath"
}

[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

# Chrome Web Store promotional images must not contain transparency.
$bitmap = [System.Drawing.Bitmap]::new(
  440,
  280,
  [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$backgroundRectangle = [System.Drawing.Rectangle]::new(0, 0, 440, 280)
$backgroundBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
  $backgroundRectangle,
  [System.Drawing.Color]::FromArgb(255, 36, 31, 105),
  [System.Drawing.Color]::FromArgb(255, 91, 78, 235),
  18
)
$graphics.FillRectangle($backgroundBrush, $backgroundRectangle)

# Soft geometric accents keep the tile recognizable without locale-specific text.
$accentBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(32, 255, 255, 255)
)
$graphics.FillEllipse($accentBrush, -72, -92, 240, 240)
$graphics.FillEllipse($accentBrush, 333, 180, 170, 170)

$shadowBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(55, 11, 8, 55)
)
$shadowPath = New-RoundedRectanglePath 32 42 160 204 28
$graphics.FillPath($shadowBrush, $shadowPath)

$cardBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
$cardPath = New-RoundedRectanglePath 28 36 160 204 28
$graphics.FillPath($cardBrush, $cardPath)

$icon = [System.Drawing.Image]::FromFile($iconPath)
$graphics.DrawImage($icon, 44, 52, 128, 128)

$miniFieldBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 239, 238, 255)
)
$miniFieldPath = New-RoundedRectanglePath 51 190 114 26 13
$graphics.FillPath($miniFieldBrush, $miniFieldPath)

$miniDotBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 79, 70, 229)
)
foreach ($x in @(70, 89, 108, 127, 146)) {
  $graphics.FillEllipse($miniDotBrush, $x, 199, 8, 8)
}

# A simplified password field and controls communicate the extension's purpose.
$fieldShadowPath = New-RoundedRectanglePath 211 64 205 68 18
$graphics.FillPath($shadowBrush, $fieldShadowPath)
$fieldPath = New-RoundedRectanglePath 207 59 205 68 18
$graphics.FillPath($cardBrush, $fieldPath)

$passwordDotBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 62, 55, 159)
)
foreach ($x in @(229, 249, 269, 289, 309, 329)) {
  $graphics.FillEllipse($passwordDotBrush, $x, 87, 10, 10)
}

$actionBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 79, 70, 229)
)
$actionPath = New-RoundedRectanglePath 357 77 36 32 10
$graphics.FillPath($actionBrush, $actionPath)

$sparkPen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 3)
$sparkPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$sparkPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$graphics.DrawLine($sparkPen, 375, 84, 375, 102)
$graphics.DrawLine($sparkPen, 366, 93, 384, 93)

$controlsShadowPath = New-RoundedRectanglePath 211 149 205 68 18
$graphics.FillPath($shadowBrush, $controlsShadowPath)
$controlsPath = New-RoundedRectanglePath 207 144 205 68 18
$graphics.FillPath($cardBrush, $controlsPath)

$trackBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 221, 219, 245)
)
$activeTrackBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 79, 70, 229)
)
$knobBrush = [System.Drawing.SolidBrush]::new(
  [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
)
$knobOutline = [System.Drawing.Pen]::new(
  [System.Drawing.Color]::FromArgb(255, 79, 70, 229),
  3
)

foreach ($row in @(
  @{ Y = 163; ActiveWidth = 78; KnobX = 304 },
  @{ Y = 183; ActiveWidth = 112; KnobX = 338 }
)) {
  $trackPath = New-RoundedRectanglePath 227 $row.Y 154 6 3
  $graphics.FillPath($trackBrush, $trackPath)
  $activePath = New-RoundedRectanglePath 227 $row.Y $row.ActiveWidth 6 3
  $graphics.FillPath($activeTrackBrush, $activePath)
  $graphics.FillEllipse($knobBrush, $row.KnobX - 7, $row.Y - 4, 14, 14)
  $graphics.DrawEllipse($knobOutline, $row.KnobX - 7, $row.Y - 4, 14, 14)
  $trackPath.Dispose()
  $activePath.Dispose()
}

$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$knobOutline.Dispose()
$knobBrush.Dispose()
$activeTrackBrush.Dispose()
$trackBrush.Dispose()
$controlsPath.Dispose()
$controlsShadowPath.Dispose()
$sparkPen.Dispose()
$actionPath.Dispose()
$actionBrush.Dispose()
$passwordDotBrush.Dispose()
$fieldPath.Dispose()
$fieldShadowPath.Dispose()
$miniDotBrush.Dispose()
$miniFieldPath.Dispose()
$miniFieldBrush.Dispose()
$icon.Dispose()
$cardPath.Dispose()
$cardBrush.Dispose()
$shadowPath.Dispose()
$shadowBrush.Dispose()
$accentBrush.Dispose()
$backgroundBrush.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Generated Chrome Web Store promotional image: $outputPath"
