$p = 'c:\Projects\Datumvista\research\bahrain-utility-cost-study-2025\index.html'
$t = [System.IO.File]::ReadAllText($p)
function Arr($n) { ([regex]::Match($t, "var $n=\[([^\]]*)\]")).Groups[1].Value.Split(',') }
$months = 'January','February','March','April','May','June','July','August','September','October','November','December'

# --- Table 1: monthly series (canvas c1) ---
$r1 = New-Object System.Text.StringBuilder
foreach ($y in 2020..2026) {
  $vals = Arr "d$y"
  for ($i = 0; $i -lt $vals.Count; $i++) {
    [void]$r1.AppendLine("<tr><td>$($months[$i]) $y</td><td>$($vals[$i])</td></tr>")
  }
}
$t1 = @"
<details class="chart-data">
  <summary>Chart data: monthly total bill, January 2020 to March 2026</summary>
  <table class="dt">
    <caption>Monthly EWA bill in BD, January 2020 to March 2026. 2026 values are provisional.</caption>
    <thead><tr><th scope="col">Month</th><th scope="col">Monthly bill (BD)</th></tr></thead>
    <tbody>
$($r1.ToString())    </tbody>
  </table>
</details>
"@

# --- Table 2: seasonal comparison (canvas c2) ---
$r2 = New-Object System.Text.StringBuilder
$a20 = Arr 'd2020'; $a22 = Arr 'd2022'; $a24 = Arr 'd2024'; $a25 = Arr 'd2025'
for ($i = 0; $i -lt 12; $i++) {
  [void]$r2.AppendLine("<tr><td>$($months[$i])</td><td>$($a20[$i])</td><td>$($a22[$i])</td><td>$($a24[$i])</td><td>$($a25[$i])</td></tr>")
}
$t2 = @"
<details class="chart-data">
  <summary>Chart data: seasonal pattern by year</summary>
  <table class="dt">
    <caption>Monthly EWA bill in BD for 2020, 2022, 2024 and 2025, by month.</caption>
    <thead><tr><th scope="col">Month</th><th scope="col">2020</th><th scope="col">2022</th><th scope="col">2024</th><th scope="col">2025</th></tr></thead>
    <tbody>
$($r2.ToString())    </tbody>
  </table>
</details>
"@

# --- Table 3: bill composition (canvas c3) ---
$r3 = New-Object System.Text.StringBuilder
$e = Arr 'eAvg'; $w = Arr 'wAvg'; $m = Arr 'mAvg'
$lbl = '2020','2021','2022','2023','2024','2025'
for ($i = 0; $i -lt 6; $i++) {
  $tot = [math]::Round([double]$e[$i] + [double]$w[$i] + [double]$m[$i], 1)
  [void]$r3.AppendLine("<tr><td>$($lbl[$i])</td><td>$($e[$i])</td><td>$($w[$i])</td><td>$($m[$i])</td><td>$tot</td></tr>")
}
$t3 = @"
<details class="chart-data">
  <summary>Chart data: average monthly bill composition by year</summary>
  <table class="dt">
    <caption>Average monthly amount in BD by charge type, 2020 to 2025. Total is the sum of the three components.</caption>
    <thead><tr><th scope="col">Year</th><th scope="col">Electricity</th><th scope="col">Water</th><th scope="col">Municipality fee</th><th scope="col">Total</th></tr></thead>
    <tbody>
$($r3.ToString())    </tbody>
  </table>
</details>
"@

$c1 = '<div style="position:relative;height:250px"><canvas id="c1" role="img" aria-label="Line chart of monthly EWA bills Jan 2020 to Mar 2026."></canvas></div>'
$c2 = '<div style="position:relative;height:230px"><canvas id="c2" role="img" aria-label="Seasonal comparison chart showing summer peaks and winter troughs across years."></canvas></div>'
$c3 = '<div style="position:relative;height:220px"><canvas id="c3" role="img" aria-label="Stacked bar chart showing bill composition by year."></canvas></div>'
foreach ($pair in @(@($c1, $t1), @($c2, $t2), @($c3, $t3))) {
  if (-not $t.Contains($pair[0])) { throw "canvas anchor not found: $($pair[0].Substring(50,20))" }
  $t = $t.Replace($pair[0], $pair[0] + "`r`n" + $pair[1])
}
[System.IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))
"rows: $($r1.ToString().Split("`n").Where({$_ -like '*<tr>*'}).Count) / $($r2.ToString().Split("`n").Where({$_ -like '*<tr>*'}).Count) / $($r3.ToString().Split("`n").Where({$_ -like '*<tr>*'}).Count)"
