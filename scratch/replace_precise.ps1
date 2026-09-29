$path = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\AdminDashboard.cshtml.cs"
$content = [System.IO.File]::ReadAllText($path)
$lines = $content -split "\n"

write-host "Line 1204 before: $($lines[1204])"

# Replace any \" with "" on this specific line
$lines[1204] = $lines[1204] -replace '\\\"', '""'

write-host "Line 1204 after: $($lines[1204])"

$content = $lines -join "`n"
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
write-host "Simplification run completed."
