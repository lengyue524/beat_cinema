param(
  [string]$InputFile = "10-5-performance-samples.csv",
  [string]$OutputFile = "10-5-performance-report.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $InputFile)) {
  throw "输入文件不存在: $InputFile`n请先创建 CSV，列头: metric,seconds"
}

$rows = Import-Csv -Path $InputFile
if (-not $rows -or $rows.Count -eq 0) {
  throw "输入文件为空: $InputFile"
}

$thresholds = @{
  "first_load" = 3.0
  "cache_load" = 1.0
  "filter_sort" = 0.2
  "playlist_reenter" = 1.5
  "single_download_settle" = 1.0
  "batch_download_settle" = 3.0
}

function Get-Percentile {
  param([double[]]$Data, [double]$P)
  if ($Data.Count -eq 0) { return 0.0 }
  $sorted = $Data | Sort-Object
  if ($sorted.Count -eq 1) { return [double]$sorted[0] }
  $rank = ($P / 100.0) * ($sorted.Count - 1)
  $low = [math]::Floor($rank)
  $high = [math]::Ceiling($rank)
  if ($low -eq $high) { return [double]$sorted[$low] }
  $weight = $rank - $low
  return ([double]$sorted[$low] * (1 - $weight)) + ([double]$sorted[$high] * $weight)
}

$grouped = $rows | Group-Object metric
$result = @()

foreach ($g in $grouped) {
  $metric = [string]$g.Name
  $samples = @()
  foreach ($r in $g.Group) {
    $samples += [double]$r.seconds
  }

  $p50 = [math]::Round((Get-Percentile -Data $samples -P 50), 3)
  $p95 = [math]::Round((Get-Percentile -Data $samples -P 95), 3)
  $max = [math]::Round(($samples | Measure-Object -Maximum).Maximum, 3)
  $threshold = if ($thresholds.ContainsKey($metric)) { [double]$thresholds[$metric] } else { $null }

  $verdict = "pass"
  if ($threshold -ne $null) {
    if ($p95 -gt $threshold) {
      $verdict = "fail"
    } elseif ($max -gt $threshold) {
      $verdict = "warn"
    }
  } else {
    $verdict = "warn"
  }

  $result += [pscustomobject]@{
    metric = $metric
    samples = $samples.Count
    p50 = $p50
    p95 = $p95
    max = $max
    threshold = $threshold
    verdict = $verdict
  }
}

$blocking = $false
foreach ($item in $result) {
  if ($item.metric -in @("first_load", "cache_load") -and $item.verdict -eq "fail") {
    $blocking = $true
  }
  if ($item.metric -in @("single_download_settle", "batch_download_settle") -and $item.verdict -eq "fail") {
    $blocking = $true
  }
}

$payload = [pscustomobject]@{
  generatedAt = (Get-Date).ToString("s")
  inputFile = $InputFile
  outputFile = $OutputFile
  blocking = $blocking
  metrics = $result
}

$json = $payload | ConvertTo-Json -Depth 6
Set-Content -Path $OutputFile -Value $json -Encoding UTF8
Write-Output "Performance report written: $OutputFile"
if ($blocking) {
  Write-Output "Blocking verdict: yes"
} else {
  Write-Output "Blocking verdict: no"
}
