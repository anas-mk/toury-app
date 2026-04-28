param([Parameter(ValueFromRemainingArguments=$true)] [string[]] $Files)
foreach ($f in $Files) {
  if (-not (Test-Path $f)) { continue }
  $b = [System.IO.File]::ReadAllBytes($f)
  if ($b.Length -lt 2) { continue }
  $isUtf16Le = ($b[0] -eq 0xFF -and $b[1] -eq 0xFE) -or ($b[1] -eq 0 -and $b[0] -ne 0)
  if (-not $isUtf16Le) { continue }
  if ($b[0] -eq 0xFF -and $b[1] -eq 0xFE) {
    $text = [System.Text.Encoding]::Unicode.GetString($b, 2, $b.Length - 2)
  } else {
    $text = [System.Text.Encoding]::Unicode.GetString($b)
  }
  $u = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllBytes($f, $u.GetBytes($text))
  Write-Output ("re-encoded UTF-16 -> UTF-8: " + $f)
}
