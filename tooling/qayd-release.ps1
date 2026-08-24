#requires -Version 7.0
<##
.SYNOPSIS
    Qayd single-app release and Shorebird operations.

.DESCRIPTION
    This script deliberately contains no school/tenant matrix and no secret values.
    It operates from the Qayd repository and keeps keystores, key.properties, and
    generated Base64 material outside Git.

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command Status

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command InitShorebird

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command CreateSigningKey

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command SetGitHubSecrets -Repo Emran025/qayd

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command NativeRelease -BuildNumber 42

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command Patch -Track staging -ReleaseVersion latest

.EXAMPLE
    .\tooling\qayd-release.ps1 -Command Patch -Track stable -ReleaseVersion latest
#>

[CmdletBinding()]
param(
    [ValidateSet(
        'Help',
        'Status',
        'InitShorebird',
        'CreateSigningKey',
        'ConfigureLocalSigning',
        'SetGitHubSecrets',
        'NativeRelease',
        'Patch',
        'Tag'
    )]
    [string]$Command = 'Help',

    [string]$Repo = 'Emran025/qayd',

    [ValidateSet('staging', 'stable')]
    [string]$Track = 'staging',

    [string]$ReleaseVersion = 'latest',

    [ValidatePattern('^v?\d+\.\d+\.\d+(\+\d+)?$')]
    [string]$Version,

    [ValidateRange(1, 2147483647)]
    [int]$BuildNumber,

    [string]$ApiUrl = $env:QAYD_API_URL,

    [string]$SigningDirectory = (Join-Path $HOME 'qayd-signing'),

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
    [OutputType([string])]
    param()

    $root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
        throw "Qayd project root was not found: $root"
    }
    return $root
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)

    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter()][string[]]$Arguments = @(),
        [switch]$AllowFailure
    )

    Write-Host "> $Executable $($Arguments -join ' ')" -ForegroundColor DarkGray
    if ($DryRun) {
        return
    }

    & $Executable @Arguments
    if (-not $AllowFailure -and $LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE`: $Executable"
    }
}

function Get-PubspecVersion {
    $root = Get-ProjectRoot
    $line = Get-Content (Join-Path $root 'pubspec.yaml') |
        Where-Object { $_ -match '^version:\s*' } |
        Select-Object -First 1
    if (-not $line -or $line -notmatch '^version:\s*(?<version>[^\s#]+)') {
        throw 'Unable to read version from pubspec.yaml.'
    }
    return $Matches.version
}

function Get-ShorebirdAppId {
    $root = Get-ProjectRoot
    $configPath = Join-Path $root 'shorebird.yaml'
    if (-not (Test-Path $configPath)) {
        throw "shorebird.yaml is missing. Run InitShorebird first."
    }

    $config = Get-Content $configPath -Raw
    if ($config -notmatch '(?m)^\s*app_id:\s*(?<appId>[^\s#]+)') {
        throw 'shorebird.yaml does not contain app_id.'
    }

    $appId = $Matches.appId.Trim()
    if ($appId -eq 'REPLACE_WITH_QAYD_SHOREBIRD_APP_ID') {
        throw 'shorebird.yaml still contains the placeholder app_id. Run shorebird init on an authenticated machine.'
    }
    return $appId
}

function Initialize-Shorebird {
    Assert-Command 'shorebird'
    $root = Get-ProjectRoot
    Push-Location $root
    try {
        Write-Section 'Initialize Shorebird for the single Qayd app'
        Invoke-Checked 'shorebird' @('login')
        Invoke-Checked 'shorebird' @('init', '--display-name', 'Qayd')
        Write-Host 'Review shorebird.yaml, then commit only the public app_id configuration.' -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

function Convert-SecureStringToPlainText {
    param([Parameter(Mandatory)][Security.SecureString]$SecureString)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function New-AndroidSigningKey {
    Assert-Command 'keytool'
    $directory = [IO.Path]::GetFullPath($SigningDirectory)
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $keystorePath = Join-Path $directory 'qayd-release.jks'

    if (Test-Path $keystorePath) {
        throw "Refusing to overwrite existing keystore: $keystorePath"
    }

    $alias = Read-Host 'Android key alias [qayd-release]'
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = 'qayd-release' }
    $storeSecure = Read-Host 'Keystore password' -AsSecureString
    $keySecure = Read-Host 'Private key password' -AsSecureString
    $storePassword = Convert-SecureStringToPlainText $storeSecure
    $keyPassword = Convert-SecureStringToPlainText $keySecure

    try {
        $env:QAYD_STORE_PASSWORD = $storePassword
        $env:QAYD_KEY_PASSWORD = $keyPassword
        Invoke-Checked 'keytool' @(
            '-genkeypair', '-v',
            '-keystore', $keystorePath,
            '-storetype', 'JKS',
            '-alias', $alias,
            '-keyalg', 'RSA',
            '-keysize', '4096',
            '-validity', '10000',
            '-storepass:env', 'QAYD_STORE_PASSWORD',
            '-keypass:env', 'QAYD_KEY_PASSWORD',
            '-dname', 'CN=Qayd Release, OU=Qayd, O=Qayd, L=Unknown, ST=Unknown, C=US'
        )
    }
    finally {
        Remove-Item Env:QAYD_STORE_PASSWORD -ErrorAction SilentlyContinue
        Remove-Item Env:QAYD_KEY_PASSWORD -ErrorAction SilentlyContinue
        $storePassword = $null
        $keyPassword = $null
    }

    $metadataPath = Join-Path $directory 'qayd-signing-metadata.txt'
    @(
        "keystore=$keystorePath"
        "alias=$alias"
        'storePassword=<kept by operator; not written to disk>'
        'keyPassword=<kept by operator; not written to disk>'
        'base64File=qayd-release.jks.base64'
    ) | Set-Content -Path $metadataPath -NoNewline

    Write-Host "Created Android keystore outside the repository: $keystorePath" -ForegroundColor Green
    Write-Host "Keep the keystore and passwords backed up in encrypted offline storage." -ForegroundColor Yellow
}

function Convert-KeystoreToBase64 {
    $directory = [IO.Path]::GetFullPath($SigningDirectory)
    $keystorePath = Join-Path $directory 'qayd-release.jks'
    if (-not (Test-Path $keystorePath)) {
        throw "Keystore not found: $keystorePath"
    }

    $outputPath = Join-Path $directory 'qayd-release.jks.base64'
    $bytes = [IO.File]::ReadAllBytes($keystorePath)
    [Convert]::ToBase64String($bytes) | Set-Content -Path $outputPath -NoNewline
    Write-Host "Created Base64 material outside the repository: $outputPath" -ForegroundColor Green
    return $outputPath
}

function Set-GitHubSecretFromValue {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Value
    )

    if ($DryRun) {
        Write-Host "> gh secret set $Name --repo $Repo (value is never printed)" -ForegroundColor DarkGray
        return
    }

    $Value | & gh secret set $Name --repo $Repo
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set GitHub secret '$Name'."
    }
}

function Set-GitHubSecrets {
    Assert-Command 'gh'
    $directory = [IO.Path]::GetFullPath($SigningDirectory)
    $base64Path = Convert-KeystoreToBase64
    $base64 = Get-Content $base64Path -Raw
    $storeSecure = Read-Host 'Keystore password' -AsSecureString
    $keySecure = Read-Host 'Private key password' -AsSecureString
    $storePassword = Convert-SecureStringToPlainText $storeSecure
    $keyPassword = Convert-SecureStringToPlainText $keySecure
    $alias = Read-Host 'Android key alias'
    $apiUrl = Read-Host 'Production Qayd API URL'
    $shorebirdTokenSecure = Read-Host 'Shorebird API token' -AsSecureString
    $shorebirdToken = Convert-SecureStringToPlainText $shorebirdTokenSecure

    try {
        Set-GitHubSecretFromValue 'ANDROID_KEYSTORE_BASE64' $base64
        Set-GitHubSecretFromValue 'ANDROID_KEYSTORE_PASSWORD' $storePassword
        Set-GitHubSecretFromValue 'ANDROID_KEY_ALIAS' $alias
        Set-GitHubSecretFromValue 'ANDROID_KEY_PASSWORD' $keyPassword
        Set-GitHubSecretFromValue 'QAYD_API_URL' $apiUrl
        Set-GitHubSecretFromValue 'SHOREBIRD_TOKEN' $shorebirdToken
    }
    finally {
        $base64 = $null
        $storePassword = $null
        $keyPassword = $null
        $shorebirdToken = $null
    }

    Write-Host "GitHub Secrets configured for $Repo. Secret values were not printed." -ForegroundColor Green
}

function Get-ChangedFiles {
    Assert-Command 'git'
    $root = Get-ProjectRoot
    Push-Location $root
    try {
        $files = @()
        $files += @(git diff --name-only)
        $files += @(git diff --cached --name-only)
        if ((git rev-parse --verify HEAD^ 2>$null)) {
            $files += @(git diff --name-only HEAD^ HEAD)
        }
        return @($files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    }
    finally {
        Pop-Location
    }
}

function Assert-DartOnlyPatch {
    $blocked = @(
        '^android/', '^ios/', '^macos/', '^linux/', '^windows/',
        '^assets/', '^pubspec\.yaml$', '^pubspec\.lock$', '^shorebird\.yaml$'
    )
    $changed = Get-ChangedFiles
    $native = @($changed | Where-Object {
        $file = $_
        $blocked | Where-Object { $file -match $_ }
    })
    if ($native.Count -gt 0) {
        throw "Patch refused. Native/dependency/asset changes detected: $($native -join ', ')"
    }
}

function Configure-LocalAndroidSigning {
    $root = Get-ProjectRoot
    $directory = [IO.Path]::GetFullPath($SigningDirectory)
    $keystorePath = Join-Path $directory 'qayd-release.jks'
    if (-not (Test-Path $keystorePath)) {
        throw "Keystore not found: $keystorePath. Run CreateSigningKey first."
    }

    $alias = Read-Host 'Android key alias'
    $storeSecure = Read-Host 'Keystore password' -AsSecureString
    $keySecure = Read-Host 'Private key password' -AsSecureString
    $storePassword = Convert-SecureStringToPlainText $storeSecure
    $keyPassword = Convert-SecureStringToPlainText $keySecure
    $propertiesPath = Join-Path $root 'android/key.properties'

    try {
        @(
            "storeFile=$keystorePath"
            "storePassword=$storePassword"
            "keyAlias=$alias"
            "keyPassword=$keyPassword"
        ) | Set-Content -Path $propertiesPath -NoNewline
        Write-Host "Created ignored local signing file: $propertiesPath" -ForegroundColor Green
        Write-Host 'It is excluded from Git. Never commit or share it.' -ForegroundColor Yellow
    }
    finally {
        $storePassword = $null
        $keyPassword = $null
    }
}

function Get-DartDefineArguments {
    $apiUrl = $ApiUrl
    if ([string]::IsNullOrWhiteSpace($apiUrl)) {
        $apiUrl = Read-Host 'Production Qayd API URL for this build'
    }
    if ([string]::IsNullOrWhiteSpace($apiUrl)) {
        throw 'QAYD_API_URL is required for a production build.'
    }
    return @('--', "--dart-define=QAYD_API_URL=$apiUrl")
}

function Publish-NativeRelease {
    Assert-Command 'shorebird'
    $appId = Get-ShorebirdAppId
    $root = Get-ProjectRoot
    $number = if ($BuildNumber -gt 0) { $BuildNumber } else { [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
    $version = Get-PubspecVersion

    Push-Location $root
    try {
        Write-Section "Publish native Android release for Qayd $version+$number"
        Write-Host "Shorebird app_id: $appId" -ForegroundColor DarkGray
        $arguments = @(
            'release', 'android',
            '--artifact', 'apk',
            '--build-number', "$number",
            '--no-confirm'
        ) + (Get-DartDefineArguments)
        Invoke-Checked 'shorebird' $arguments
    }
    finally {
        Pop-Location
    }
}

function Publish-DartPatch {
    Assert-Command 'shorebird'
    $appId = Get-ShorebirdAppId
    Assert-DartOnlyPatch
    $root = Get-ProjectRoot

    Push-Location $root
    try {
        Write-Section "Publish Dart/Flutter patch to $Track"
        Write-Host "Shorebird app_id: $appId" -ForegroundColor DarkGray
        $arguments = @(
            'patch', 'android',
            '--release-version', $ReleaseVersion,
            '--track', $Track,
            '--no-confirm'
        ) + (Get-DartDefineArguments)
        Invoke-Checked 'shorebird' $arguments
    }
    finally {
        Pop-Location
    }
}

function New-QaydTag {
    Assert-Command 'git'
    if ([string]::IsNullOrWhiteSpace($Version)) {
        throw 'Tag requires -Version, for example -Version v1.0.1.'
    }
    $tag = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
    $root = Get-ProjectRoot
    Push-Location $root
    try {
        if (git rev-parse --verify "refs/tags/$tag" 2>$null) {
            throw "Tag already exists locally: $tag. Refusing to delete or force-push tags."
        }
        Invoke-Checked 'git' @('tag', '-a', $tag, '-m', "Qayd $tag")
        Invoke-Checked 'git' @('push', 'origin', $tag)
        Write-Host "Pushed immutable release tag $tag" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

function Show-Status {
    Assert-Command 'git'
    $root = Get-ProjectRoot
    Write-Section 'Qayd single-app release status'
    Write-Host "Project: $root"
    Write-Host "Version: $(Get-PubspecVersion)"
    if (Test-Path (Join-Path $root 'shorebird.yaml')) {
        try {
            Write-Host "Shorebird app_id: $(Get-ShorebirdAppId)"
        }
        catch {
            Write-Host "Shorebird app_id: not configured ($(($_.Exception.Message)))" -ForegroundColor Yellow
        }
    }
    Push-Location $root
    try {
        git status --short --branch
    }
    finally {
        Pop-Location
    }
}

function Show-Help {
    Write-Section 'Qayd release commands'
    @'
Commands:
  Status
      Show project version, git status, and Shorebird configuration state.

  InitShorebird
      Run shorebird login and shorebird init --display-name Qayd.
      This creates the real public app_id; it must not be fabricated.

  CreateSigningKey
      Create android signing material under $HOME/qayd-signing, never in Git.

  ConfigureLocalSigning
      Create android/key.properties from the external keystore and secure prompts.
      The file is ignored by Git and must never be committed.

  SetGitHubSecrets
      Convert the keystore and securely send the six required values to GitHub:
      SHOREBIRD_TOKEN, ANDROID_KEYSTORE_BASE64,
      ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS,
      ANDROID_KEY_PASSWORD, and QAYD_API_URL.

  NativeRelease
      Publish a complete Shorebird Android release. Use after native,
      dependency, or asset changes. It does not publish to Google Play.

  Patch
      Publish Dart/Flutter-only code to Shorebird. Native/dependency/asset
      changes are refused locally. Default track is staging; use -Track stable
      only after validation.

  Tag
      Create and push an annotated immutable tag. Existing tags are never
      deleted or force-pushed.

Examples:
  .\tooling\qayd-release.ps1 -Command Status
  .\tooling\qayd-release.ps1 -Command InitShorebird
  .\tooling\qayd-release.ps1 -Command CreateSigningKey
  .\tooling\qayd-release.ps1 -Command SetGitHubSecrets
  .\tooling\qayd-release.ps1 -Command NativeRelease -BuildNumber 42
  .\tooling\qayd-release.ps1 -Command Patch -Track staging
  .\tooling\qayd-release.ps1 -Command Patch -Track stable
  .\tooling\qayd-release.ps1 -Command Tag -Version v1.0.1
'@
}

switch ($Command) {
    'Help' { Show-Help }
    'Status' { Show-Status }
    'InitShorebird' { Initialize-Shorebird }
    'CreateSigningKey' { New-AndroidSigningKey }
    'ConfigureLocalSigning' { Configure-LocalAndroidSigning }
    'SetGitHubSecrets' { Set-GitHubSecrets }
    'NativeRelease' { Publish-NativeRelease }
    'Patch' { Publish-DartPatch }
    'Tag' { New-QaydTag }
}
