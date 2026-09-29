$path = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Join.cshtml"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Replace ColNational Zoo or ColNation Zoo with Colchester Zoo
$content = $content -replace 'ColNational\s+Zoo', 'Colchester Zoo'
$content = $content -replace 'ColNation\s+Zoo', 'Colchester Zoo'

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Output "Colchester Zoo replacement completed"
