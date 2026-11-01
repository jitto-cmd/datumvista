$p = 'c:\Projects\Datumvista\research\bahrain-utility-cost-study-2025\index.html'
$t = [System.IO.File]::ReadAllText($p)

# --- pull the c1 table rows straight out of the committed HTML ---
$block = $t.Substring($t.IndexOf('<summary>Chart data: monthly total bill'))
$block = $block.Substring(0, $block.IndexOf('</table>'))
$rows = [regex]::Matches($block, '<tr><td>([A-Za-z]+) (\d{4})</td><td>([\d.]+)</td></tr>')
"rows parsed: $($rows.Count)"
$data = @{}
foreach ($r in $rows) {
  $y = [int]$r.Groups[2].Value; $m = $r.Groups[1].Value; $v = [double]$r.Groups[3].Value
  if (-not $data.ContainsKey($y)) { $data[$y] = @() }
  $data[$y] += , @($m, $v)
}

"`n=== ALL-YEARS EXTREMES ==="
$flat = foreach ($y in $data.Keys) { foreach ($e in $data[$y]) { [pscustomobject]@{ Year = $y; Month = $e[0]; Value = $e[1] } } }
$peak = $flat | Sort-Object Value -Descending | Select-Object -First 1
$low = $flat | Sort-Object Value | Select-Object -First 1
"peak: $($peak.Month) $($peak.Year) = BD $($peak.Value)"
"lowest: $($low.Month) $($low.Year) = BD $($low.Value)"

"`n=== PER-YEAR MEAN / MIN / MAX / SEASONAL GAP ==="
foreach ($y in ($data.Keys | Sort-Object)) {
  $vals = $data[$y] | ForEach-Object { $_[1] }
  $mean = [math]::Round((($vals | Measure-Object -Average).Average), 2)
  $min = ($vals | Measure-Object -Minimum).Minimum
  $max = ($vals | Measure-Object -Maximum).Maximum
  $gap = [math]::Round($max - $min, 2)
  $gapPct = [math]::Round(($gap / $min) * 100, 1)
  "$y : n=$($vals.Count) mean=$mean min=$min max=$max gap=$gap ($gapPct% of trough)"
}

"`n=== YEAR-ON-YEAR (full years only) ==="
$means = @{}
foreach ($y in 2020..2025) { $vals = $data[$y] | ForEach-Object { $_[1] }; $means[$y] = [math]::Round((($vals | Measure-Object -Average).Average), 2) }
foreach ($y in 2021..2025) {
  $abs = [math]::Round($means[$y] - $means[$y - 1], 2)
  $pct = [math]::Round(($abs / $means[$y - 1]) * 100, 1)
  "$($y - 1) avg $($means[$y - 1]) -> $y avg $($means[$y]) : $abs BD ($pct%)"
}
$abs204 = [math]::Round($means[2024] - $means[2020], 2)
"2020 -> 2024 total: $abs204 BD over 4 years = $([math]::Round($abs204 * 12, 2)) BD/year, $([math]::Round(($means[2024] - $means[2020]) / $means[2020] * 100, 1))%"

"`n=== COMPOSITION SHARES (from c3 table) ==="
$c3 = $t.Substring($t.IndexOf('<summary>Chart data: average monthly bill composition'))
$c3 = $c3.Substring(0, $c3.IndexOf('</table>'))
foreach ($m in [regex]::Matches($c3, '<tr><td>(\d{4})</td><td>([\d.]+)</td><td>([\d.]+)</td><td>([\d.]+)</td><td>([\d.]+)</td></tr>')) {
  $y = $m.Groups[1].Value; $e = [double]$m.Groups[2].Value; $w = [double]$m.Groups[3].Value; $mu = [double]$m.Groups[4].Value; $tot = [double]$m.Groups[5].Value
  "$y total $tot BD -> electricity $([math]::Round($e / $tot * 100, 1))% / water $([math]::Round($w / $tot * 100, 1))% / municipality $([math]::Round($mu / $tot * 100, 1))%"
}

"`n=== SANITY CHECK AGAINST PAGE CLAIMS ==="
$all = $flat | ForEach-Object { $_.Value }
"mean of all 75 = $([math]::Round((($all | Measure-Object -Average).Average), 2))  (page stat says BD 68)"
"page stat lowest = BD 56 (Feb 2022) ; chart data Feb 2022 = $(($data[2022] | Where-Object { $_[0] -eq 'February' })[1]) ; chart min for 2022 = $((($data[2022] | ForEach-Object { $_[1] }) | Measure-Object -Minimum).Minimum)"
