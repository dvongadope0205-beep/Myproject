$searchDir = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages"
$files = Get-ChildItem -Path $searchDir -Recurse -Filter *.cshtml

Write-Output "--- Checking nested div inside label ---"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '<label[^>]*>[\s\S]*?<div[\s\S]*?</label>') {
        Write-Output "Found in: $($file.FullName)"
    }
}

Write-Output "`n--- Checking h3 nesting/tag issues ---"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    # Search for h3 matching
    $matches = [regex]::Matches($content, '<h3[^>]*>([\s\S]*?)</h3>')
    foreach ($m in $matches) {
        $inner = $m.Groups[1].Value
        if ($inner -match '<div' -or $inner -match '<p') {
            Write-Output "h3 with nested div/p in: $($file.FullName)"
            Write-Output "Content: $($m.Value)"
        }
    }
}
