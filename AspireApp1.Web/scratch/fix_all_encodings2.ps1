# PowerShell script to clean up encodings and replace currency symbol from £/₫ to $
$dir = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shopnew"
$files = Get-ChildItem -Path $dir -Filter "*.cshtml" -Recurse

# Define replacements
$replacements = @{
    '£' = '$'
    'Â£' = '$'
    '₫' = '$'
    'âˆ’' = '−'
    'âœ•' = '✕'
    'âœ"' = '✓'
    'â€¢' = '•'
    'â€¹' = '‹'
    'â€º' = '›'
    'Ã—' = '✕'
    'â€™' = ''''
}

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $modified = $false
    
    foreach ($key in $replacements.Keys) {
        if ($content.Contains($key)) {
            $content = $content.Replace($key, $replacements[$key])
            $modified = $true
        }
    }
    
    if ($modified) {
        # Save back as UTF-8 with BOM
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8WithBom)
        Write-Host "Updated: $($file.Name)"
    }
}
Write-Host "Done!"
