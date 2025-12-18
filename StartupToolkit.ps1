<#
.SYNOPSIS
    Windows Startup Diagnostic Toolkit

.DESCRIPTION
    Enumerates startup items from HKLM/HKCU Run keys,
    categorizes them into Valid, Suspicious, and Broken,
    and exports professional reports (CSV, Markdown, HTML).
    HTML report includes DuckDuckGo search links for quick reputation checks.

.NOTES
    Authored by Christopher Munn
#>

# ==============================
# CONFIGURATION
# ==============================
# Change these paths if you want reports saved elsewhere.
$CsvPath      = "C:\temp\StartupPrograms.csv"
$MarkdownPath = "C:\temp\StartupPrograms.md"
$HtmlPath     = "C:\temp\StartupPrograms.html"

# ==============================
# FUNCTION: Get-StartupPrograms
# ==============================
function Get-StartupPrograms {
    [CmdletBinding()]
    param()

    $runKeys = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    )

    foreach ($key in $runKeys) {
        if (Test-Path $key) {
            $props = Get-ItemProperty -Path $key
            $props.PSObject.Properties |
                Where-Object { $_.MemberType -eq 'NoteProperty' -and $_.Name -notmatch '^PS' } |
                ForEach-Object {
                    $path = $props.$($_.Name)

                    # Default values
                    $exists = $false
                    $exe    = $null

                    # Regex: find first .exe path in the string
                    if (![string]::IsNullOrWhiteSpace($path)) {
                        if ($path -match '([A-Z]:\\[^"]+?\.exe)') {
                            $exe = $matches[1]
                            if (Test-Path $exe) { $exists = $true }
                        }
                    }

                    # Flag suspicious locations
                    $suspicious = $false
                    $reason     = $null
                    if ($path -match 'AppData') { $suspicious = $true; $reason = "Runs from AppData (user profile)" }
                    elseif ($path -match 'Roaming') { $suspicious = $true; $reason = "Runs from Roaming profile" }
                    elseif ($path -match 'Temp') { $suspicious = $true; $reason = "Runs from Temp folder" }
                    elseif ($path -match '\\Users\\') { $suspicious = $true; $reason = "Runs from user directory" }

                    # Return structured object
                    [PSCustomObject]@{
                        Hive       = if ($key -like 'HKLM*') { 'Local Machine' } else { 'Current User' }
                        Name       = $_.Name
                        Path       = $path
                        Exists     = $exists
                        Suspicious = $suspicious
                        Reason     = $reason
                    }
                }
        }
    }
}

# ==============================
# FUNCTION: Export-StartupPrograms
# ==============================
function Export-StartupPrograms {
    try {
        # Ensure folder exists
        $folder = Split-Path $CsvPath
        if (!(Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }

        $items = Get-StartupPrograms
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm 'GMT'")

        # Categorize entries
        $valid      = $items | Where-Object { $_.Exists -eq $true -and $_.Suspicious -eq $false }
        $suspicious = $items | Where-Object { $_.Suspicious -eq $true -and $_.Exists -eq $true }
        $broken     = $items | Where-Object { $_.Exists -eq $false }

        # ------------------------------
        # Export to CSV (raw data)
        # ------------------------------
        $items | Export-Csv -Path $CsvPath -NoTypeInformation -Force

        # ------------------------------
        # Export to Markdown (tables + summary)
        # ------------------------------
        $md = @"
# Windows Startup Diagnostic Toolkit
*Report generated: $timestamp*

## Valid Startup Programs
| Hive | Name | Path |
|------|------|------|
"@
        foreach ($v in $valid) { $md += "| $($v.Hive) | $($v.Name) | $($v.Path) |`n" }

        $md += @"

## Suspicious Startup Programs
| Hive | Name | Path | Reason |
|------|------|------|--------|
"@
        foreach ($s in $suspicious) { $md += "| $($s.Hive) | $($s.Name) | $($s.Path) | $($s.Reason) |`n" }

        $md += @"

## Broken Startup Programs
| Hive | Name | Path |
|------|------|------|
"@
        foreach ($b in $broken) { $md += "| $($b.Hive) | $($b.Name) | $($b.Path) |`n" }

        $md += @"

## Summary
- ✔ Valid: $($valid.Count)
- ⚠ Suspicious: $($suspicious.Count)
- ✖ Broken: $($broken.Count)
- **Total: $($items.Count)** (Local Machine: $(( $items | Where-Object Hive -eq 'Local Machine').Count), Current User: $(( $items | Where-Object Hive -eq 'Current User').Count))

## Legend
- ✔ **Valid**: Executable exists in trusted locations (Program Files, System32)
- ⚠ **Suspicious**: Executable exists but runs from risky locations (AppData, Roaming, Temp, user profile)
- ✖ **Broken**: Registry entry exists but path is empty or executable missing

*Authored by Chris*
"@
        $md | Out-File -FilePath $MarkdownPath -Encoding UTF8 -Force

        # ------------------------------
        # Export to HTML (dashboard view)
        # ------------------------------
        $html = @"
<html>
<head>
<style>
body { font-family: Segoe UI, sans-serif; margin: 20px; }
h1 { color: #2c3e50; }
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
th, td { border: 1px solid #ccc; padding: 6px; text-align: left; }
.valid { background-color: #d4edda; }      /* green */
.suspicious { background-color: #fff3cd; } /* yellow */
.broken { background-color: #f8d7da; }     /* red */
.summary { border: 1px solid #ccc; padding: 10px; background-color: #f4f6f7; }
.footer { font-size: 0.9em; color: #555; margin-top: 20px; }
</style>
</head>
<body>
<h1>Windows Startup Diagnostic Toolkit</h1>
<p><i>Report generated: $timestamp</i></p>
"@

        # Valid entries with DuckDuckGo search links
        $html += "<h2>Valid Startup Programs</h2><table><tr><th>Hive</th><th>Name</th><th>Path (search)</th></tr>`n"
        foreach ($v in $valid) {
            $query = [uri]::EscapeDataString($v.Path)
            $html += "<tr class='valid'><td>$($v.Hive)</td><td>$($v.Name)</td><td><a href='https://duckduckgo.com/?q=$query' target='_blank'>$($v.Path)</a></td></tr>`n"
        }
        $html += "</table>"

        # Suspicious entries with DuckDuckGo search links
        $html += "<h2>Suspicious Startup Programs</h2><table><tr><th>Hive</th><th>Name</th><th>Path (search)</th><th>Reason</th></tr>`n"
        foreach ($s in $suspicious) {
            $query = [uri]::EscapeDataString($s.Path)
            $html += "<tr class='suspicious'><td>$($s.Hive)</td><td>$($s.Name)</td><td><a href='https://duckduckgo.com/?q=$query' target='_blank'>$($s.Path)</a></td><td>$($s.Reason)</td></tr>`n"
        }
        $html += "</table>"

               # Broken entries with DuckDuckGo search links
        $html += "<h2>Broken Startup Programs</h2><table><tr><th>Hive</th><th>Name</th><th>Path (search)</th></tr>`n"
        foreach ($b in $broken) {
            $query = [uri]::EscapeDataString($b.Path)
            $html += "<tr class='broken'><td>$($b.Hive)</td><td>$($b.Name)</td><td><a href='https://duckduckgo.com/?q=$query' target='_blank'>$($b.Path)</a></td></tr>`n"
        }
        $html += "</table>"

        # Summary block
        $html += @"
<div class='summary'>
<h2>Summary</h2>
<ul>
<li>✔ Valid: $($valid.Count)</li>
<li>⚠ Suspicious: $($suspicious.Count)</li>
<li>✖ Broken: $($broken.Count)</li>
<li><b>Total: $($items.Count)</b> (Local Machine: $(( $items | Where-Object Hive -eq 'Local Machine').Count), Current User: $(( $items | Where-Object Hive -eq 'Current User').Count))</li>
</ul>
</div>
"@

        # Legend block
        $html += @"
<h2>Legend</h2>
<ul>
<li>✔ <b>Valid</b>: Executable exists in trusted locations (Program Files, System32)</li>
<li>⚠ <b>Suspicious</b>: Executable exists but runs from risky locations (AppData, Roaming, Temp, user profile)</li>
<li>✖ <b>Broken</b>: Registry entry exists but path is empty or executable missing</li>
</ul>
<div class='footer'>Authored by Christopher Munn</div>
</body>
</html>
"@

        # Write HTML file
        $html | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force

        Write-Host "Reports written to $folder"
    }
    catch {
        Write-Error "An error occurred while exporting startup programs: $_"
    }
}

# ==============================
# EXECUTION
# ==============================
# Run the export explicitly
Export-StartupPrograms
