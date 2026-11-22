param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceHtmlPath = Join-Path $projectRoot "password_gen_custom.html"
$extensionSourceDirectory = Join-Path $projectRoot "chrome-extension"
$distDirectory = Join-Path $projectRoot "dist"
$extensionOutputDirectory = Join-Path $distDirectory "chrome-extension"
$manifestSourcePath = Join-Path $extensionSourceDirectory "manifest.json"

$projectRootFullPath = [System.IO.Path]::GetFullPath($projectRoot).TrimEnd('\')
$extensionOutputFullPath = [System.IO.Path]::GetFullPath($extensionOutputDirectory)
if (-not $extensionOutputFullPath.StartsWith(
  $projectRootFullPath + '\',
  [System.StringComparison]::OrdinalIgnoreCase
)) {
  throw "The extension output directory must stay inside the project directory."
}

$manifest = Get-Content -Raw -Encoding utf8 $manifestSourcePath | ConvertFrom-Json
$version = $manifest.version
$zipPath = Join-Path $distDirectory "passgen-custom-chrome-v$version.zip"
$englishHtmlPath = Join-Path $distDirectory "password_gen_custom_en.html"

if (Test-Path -LiteralPath $extensionOutputDirectory) {
  Remove-Item -LiteralPath $extensionOutputDirectory -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
if (Test-Path -LiteralPath $englishHtmlPath) {
  Remove-Item -LiteralPath $englishHtmlPath -Force
}

[System.IO.Directory]::CreateDirectory($extensionOutputDirectory) | Out-Null
Copy-Item -LiteralPath $manifestSourcePath -Destination $extensionOutputDirectory
Copy-Item -LiteralPath (Join-Path $extensionSourceDirectory "popup.css") -Destination $extensionOutputDirectory
Copy-Item -LiteralPath (Join-Path $extensionSourceDirectory "images") -Destination $extensionOutputDirectory -Recurse
Copy-Item -LiteralPath (Join-Path $extensionSourceDirectory "_locales") -Destination $extensionOutputDirectory -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination $extensionOutputDirectory

$sourceHtml = Get-Content -Raw -Encoding utf8 $sourceHtmlPath
if ($sourceHtml -notmatch [regex]::Escape("PassGen Custom v$version")) {
  throw "The HTML title and manifest version do not match."
}
$englishMessagesJson = Get-Content -Raw -Encoding utf8 (
  Join-Path $extensionSourceDirectory "_locales\en\messages.json"
)
if (-not $sourceHtml.Contains("const EMBEDDED_LOCALE = null;") -or
    -not $sourceHtml.Contains("const EMBEDDED_MESSAGES = null;")) {
  throw "The embedded locale markers are missing from password_gen_custom.html."
}
$englishHtml = $sourceHtml.Replace('<html lang="ja">', '<html lang="en">')
$englishHtml = $englishHtml.Replace(
  'const EMBEDDED_LOCALE = null;',
  'const EMBEDDED_LOCALE = "en";'
)
$englishHtml = $englishHtml.Replace(
  'const EMBEDDED_MESSAGES = null;',
  "const EMBEDDED_MESSAGES = $englishMessagesJson;"
)
[System.IO.File]::WriteAllText(
  $englishHtmlPath,
  $englishHtml,
  [System.Text.UTF8Encoding]::new($false)
)

$scriptPattern = '(?s)<script>\s*(.*?)\s*</script>\s*</body>'
$scriptMatch = [regex]::Match($sourceHtml, $scriptPattern)
if (-not $scriptMatch.Success) {
  throw "Could not find exactly one inline script in password_gen_custom.html."
}

$popupScript = $scriptMatch.Groups[1].Value
$popupHtml = [regex]::Replace(
  $sourceHtml,
  $scriptPattern,
  '  <script src="popup.js"></script>' + "`r`n</body>"
)
$popupHtml = $popupHtml.Replace(
  "</head>",
  '  <link rel="stylesheet" href="popup.css">' + "`r`n</head>"
)

[System.IO.File]::WriteAllText(
  (Join-Path $extensionOutputDirectory "popup.html"),
  $popupHtml,
  [System.Text.UTF8Encoding]::new($false)
)
[System.IO.File]::WriteAllText(
  (Join-Path $extensionOutputDirectory "popup.js"),
  $popupScript + "`r`n",
  [System.Text.UTF8Encoding]::new($false)
)

& (Join-Path $projectRoot "tests\extension-package.test.ps1") -ExtensionDirectory $extensionOutputDirectory

Compress-Archive -Path (Join-Path $extensionOutputDirectory "*") -DestinationPath $zipPath -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  if (-not ($zip.Entries.FullName -contains "manifest.json")) {
    throw "manifest.json was not found at the root of the ZIP archive."
  }
} finally {
  $zip.Dispose()
}

Write-Host "Built Chrome extension: $extensionOutputDirectory"
Write-Host "Built Chrome Web Store ZIP: $zipPath"
Write-Host "Built standalone English HTML: $englishHtmlPath"
