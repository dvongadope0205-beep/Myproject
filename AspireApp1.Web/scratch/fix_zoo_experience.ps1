$path = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\experience\zoo-experience.cshtml"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$content = $content.Replace(".card-details span {", ".card-details > span {")
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Output "Fixed zoo-experience.cshtml selector successfully"
