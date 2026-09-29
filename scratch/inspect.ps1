$content = [System.IO.File]::ReadAllText("c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\AdminDashboard.cshtml.cs")
$lines = $content -split "`r`n"
$line = $lines[1204] # Line 1205 (0-indexed)
write-host "Line text: $line"
$line.ToCharArray() | ForEach-Object {
    write-host "$([int]$_): '$([char]$_)'"
}
