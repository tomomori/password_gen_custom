param(
  [Parameter(Mandatory = $true)]
  [string]$ExtensionDirectory
)

$ErrorActionPreference = "Stop"
$resolvedExtensionDirectory = (Resolve-Path -LiteralPath $ExtensionDirectory).Path
$manifestPath = Join-Path $resolvedExtensionDirectory "manifest.json"
$popupHtmlPath = Join-Path $resolvedExtensionDirectory "popup.html"
$popupScriptPath = Join-Path $resolvedExtensionDirectory "popup.js"
$popupStylePath = Join-Path $resolvedExtensionDirectory "popup.css"

foreach ($requiredPath in @($manifestPath, $popupHtmlPath, $popupScriptPath, $popupStylePath)) {
  if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
    throw "Required file is missing: $requiredPath"
  }
}

$manifest = Get-Content -Raw -Encoding utf8 $manifestPath | ConvertFrom-Json
if ($manifest.manifest_version -ne 3) {
  throw "manifest_version must be 3."
}
if ($manifest.action.default_popup -ne "popup.html") {
  throw "default_popup must be popup.html."
}
if ($manifest.default_locale -ne "en") {
  throw "default_locale must be en."
}
if ($manifest.permissions -notcontains "clipboardWrite") {
  throw "clipboardWrite permission is required."
}
if ($manifest.PSObject.Properties.Name -contains "host_permissions") {
  throw "This extension must not request host permissions."
}

$popupHtml = Get-Content -Raw -Encoding utf8 $popupHtmlPath
if ($popupHtml -match '\son(?:click|change|input|load)\s*=') {
  throw "popup.html contains an inline event handler."
}
if ($popupHtml -match '(?s)<script(?![^>]*\bsrc=)[^>]*>') {
  throw "popup.html contains an inline script."
}
if ($popupHtml -notmatch '<script\s+src="popup\.js"></script>') {
  throw "popup.html does not load popup.js."
}
if ($popupHtml -notmatch '<link\s+rel="stylesheet"\s+href="popup\.css">') {
  throw "popup.html does not load popup.css."
}

$localeDirectory = Join-Path $resolvedExtensionDirectory "_locales"
$japaneseMessagesPath = Join-Path $localeDirectory "ja\messages.json"
$englishMessagesPath = Join-Path $localeDirectory "en\messages.json"
foreach ($messagesPath in @($japaneseMessagesPath, $englishMessagesPath)) {
  if (-not (Test-Path -LiteralPath $messagesPath -PathType Leaf)) {
    throw "Locale messages file is missing: $messagesPath"
  }
}

$japaneseMessages = Get-Content -Raw -Encoding utf8 $japaneseMessagesPath | ConvertFrom-Json
$englishMessages = Get-Content -Raw -Encoding utf8 $englishMessagesPath | ConvertFrom-Json
$japaneseKeys = @($japaneseMessages.PSObject.Properties.Name | Sort-Object)
$englishKeys = @($englishMessages.PSObject.Properties.Name | Sort-Object)
$keyDifference = @(Compare-Object $japaneseKeys $englishKeys)
if ($keyDifference.Count -ne 0) {
  throw "Japanese and English locale keys do not match."
}
foreach ($messages in @($japaneseMessages, $englishMessages)) {
  if ($messages.pageTitle.message -notmatch [regex]::Escape("v$($manifest.version)")) {
    throw "Localized page title and manifest version do not match."
  }
}

$htmlLocaleKeys = @(
  [regex]::Matches($popupHtml, 'data-i18n(?:-title|-aria-label)?="([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)
$dynamicLocaleKeys = @(
  "themeLight", "themeDark", "lengthValue", "strengthVeryStrong",
  "strengthGood", "strengthWeak", "copy", "copySuccess", "copyFailure",
  "copyFailureTitle", "copyTitle", "confirmSourceLink"
)
foreach ($localeKey in @($htmlLocaleKeys + $dynamicLocaleKeys)) {
  if ($japaneseKeys -notcontains $localeKey) {
    throw "Locale key is not defined: $localeKey"
  }
}

foreach ($iconPath in $manifest.icons.PSObject.Properties.Value) {
  $fullIconPath = Join-Path $resolvedExtensionDirectory $iconPath
  if (-not (Test-Path -LiteralPath $fullIconPath -PathType Leaf)) {
    throw "Manifest icon is missing: $iconPath"
  }
}

Write-Host "Extension package validation: passed"
