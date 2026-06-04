# Generates `android/cacerts.local` — a project-local Java trust store
# that includes any TLS-intercepting root CA (Avast, Kaspersky, ESET,
# corporate proxy, etc.) present in the Windows certificate store.
#
# Why this exists:
#   Some antivirus / corporate-firewall products do HTTPS interception:
#   they replace every server cert with one signed by a private root
#   they installed into Windows. Windows trusts that root (so Chrome,
#   curl, PowerShell work) but Java's JDK has its own trust store
#   (`cacerts`) which doesn't, so every `gradle dependencies` download
#   fails with `PKIX path building failed`. The fix is to copy the
#   JDK's `cacerts` to the project, add the intercepting root, and
#   point Gradle at the local copy via `org.gradle.jvmargs` in
#   `gradle.properties`.
#
# Usage:
#   1. Open PowerShell at the project root.
#   2. Run:   .\android\setup-cacerts.ps1
#   3. If the script reports "no intercepting CA found" you don't need
#      this workaround at all — comment out the `-Djavax.net.ssl.trustStore=…`
#      lines in `android/gradle.properties` and you're done.
#
# Safe to re-run: regenerates the file from scratch.

$ErrorActionPreference = "Stop"

# Locate the JDK shipped with Android Studio (matches gradle.properties).
$jdkHome = "C:\Program Files\Android\Android Studio\jbr"
$keytool = Join-Path $jdkHome "bin\keytool.exe"
$srcCacerts = Join-Path $jdkHome "lib\security\cacerts"
$dstCacerts = Join-Path $PSScriptRoot "cacerts.local"

if (-not (Test-Path $keytool)) {
    Write-Error "keytool not found at $keytool — install Android Studio or update jdkHome in this script."
    exit 1
}
if (-not (Test-Path $srcCacerts)) {
    Write-Error "JDK cacerts not found at $srcCacerts."
    exit 1
}

Write-Host "[1/3] Copying JDK cacerts → $dstCacerts"
Copy-Item -Path $srcCacerts -Destination $dstCacerts -Force

# Heuristic patterns for well-known TLS-intercepting roots.
$mitmPatterns = @(
    "Avast",
    "AVG",
    "Kaspersky",
    "ESET",
    "Bitdefender",
    "Norton",
    "Symantec.*Intercep",
    "Cisco Umbrella",
    "ZScaler",
    "Fortinet",
    "Sophos",
    "Trend Micro",
    "McAfee Web Gateway"
)
$pattern = ($mitmPatterns -join "|")

Write-Host "[2/3] Scanning Windows trust store for intercepting roots..."
$roots = @()
foreach ($store in @("Cert:\LocalMachine\Root", "Cert:\CurrentUser\Root")) {
    $roots += Get-ChildItem -Path $store -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -match $pattern -or $_.Issuer -match $pattern }
}
$roots = $roots | Sort-Object Thumbprint -Unique

if ($roots.Count -eq 0) {
    Write-Host "  → No intercepting CA found. You can comment out the SSL flags in gradle.properties." -ForegroundColor Yellow
    exit 0
}

Write-Host "[3/3] Importing $($roots.Count) intercepting root cert(s) into cacerts.local"
$tempCer = Join-Path $env:TEMP "_mitm_root_export.cer"
foreach ($cert in $roots) {
    $alias = ($cert.Subject -replace "[^A-Za-z0-9]", "_").ToLower()
    if ($alias.Length -gt 60) { $alias = $alias.Substring(0, 60) }
    Write-Host "  • $($cert.Subject)" -ForegroundColor Cyan
    Export-Certificate -Cert $cert -FilePath $tempCer -Type CERT -Force | Out-Null
    & $keytool -importcert -trustcacerts -noprompt -alias $alias -file $tempCer `
        -keystore $dstCacerts -storepass changeit 2>&1 | Out-Null
}
Remove-Item -Path $tempCer -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. cacerts.local is now ready and gradle.properties already points at it." -ForegroundColor Green
