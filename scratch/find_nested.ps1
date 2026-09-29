$files = Get-ChildItem -Path "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages" -Recurse -Filter *.cshtml

$labelRegex = '(?is)<label\b(?![^>]*/>)[^>]*>(?:(?!</?label\b)[\s\S])*?<div\b'
$h3DivRegex = '(?is)<h3\b(?![^>]*/>)[^>]*>(?:(?!</?h3\b)[\s\S])*?<div\b'
$h3PRegex   = '(?is)<h3\b(?![^>]*/>)[^>]*>(?:(?!</?h3\b)[\s\S])*?<p\b'

Write-Output "=== Checking nested div inside label ==="
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match $labelRegex) {
        # Find exact line number
        $lines = Get-Content $file.FullName
        for ($i=0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '<label\b' -and $lines[$i+1] -match '<div\b') {
                Write-Output "Found in: $($file.FullName) at line $($i+1)"
            }
        }
    }
}

Write-Output "`n=== Checking nested div/p inside h3 ==="
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match $h3DivRegex -or $content -match $h3PRegex) {
        Write-Output "Found H3 violation in: $($file.FullName)"
    }
}
