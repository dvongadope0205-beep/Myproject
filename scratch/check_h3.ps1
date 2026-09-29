$pagesDir = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages"
$files = Get-ChildItem -Path $pagesDir -Filter "*.cshtml" -Recurse

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    # Extract <h3...>(.*?)</h3> blocks
    $matches = [regex]::Matches($content, "<h3[^>]*>([\s\S]*?)</h3>", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $inner = $m.Groups[1].Value
        if ($inner -match "<div" -or $inner -match "<p") {
            Write-Host "[$($file.Name)] Violating h3 content:"
            Write-Host $m.Value
            Write-Host "--------------------"
        }
    }
}
