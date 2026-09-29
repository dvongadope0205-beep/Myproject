$pagesDir = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages"
$files = Get-ChildItem -Path $pagesDir -Filter "*.cshtml" -Recurse

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    foreach ($tag in @("div", "p", "h3", "label")) {
        $opens = [regex]::Matches($content, "<$tag\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
        $closes = [regex]::Matches($content, "</$tag>", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
        if ($opens -ne $closes) {
            Write-Host "[$($file.Name)] Mismatch for <$tag>: opens=$opens, closes=$closes"
        }
    }
}
