$filePath = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\AdminDashboard.cshtml"
$text = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$ansiEncoding = [System.Text.Encoding]::GetEncoding("windows-1252")
$bytes = $ansiEncoding.GetBytes($text)
[System.IO.File]::WriteAllBytes($filePath, $bytes)
Write-Host "Restored file encoding successfully!"
