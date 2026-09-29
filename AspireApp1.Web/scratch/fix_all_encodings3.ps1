# ASCII-safe PowerShell script to clean up encodings and replace currency symbol from £/₫ to $
$dir = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shopnew"
$files = Get-ChildItem -Path $dir -Filter "*.cshtml" -Recurse

# Define replacements using character codes
$poundChar = [string][char]0xA3
$dongChar = [string][char]0x20AB

# Define the strings for bad encodings
$badMinus = [string]([char]0xE2 + [char]0x2C6 + [char]0x2212)  # âˆ−
$badMinus2 = [string]([char]0xE2 + [char]0x88 + [char]0x92)   # raw bytes if parsed differently
$badCross = [string]([char]0xE2 + [char]0x153 + [char]0x2022)  # âœ•
$badCross2 = [string]([char]0xE2 + [char]0x9C + [char]0x95)
$badQuote = [string]([char]0xE2 + [char]0x153 + [char]0x22)    # âœ"
$badBullet = [string]([char]0xE2 + [char]0x20AC + [char]0x2022) # â€¢
$badLt = [string]([char]0xE2 + [char]0x20AC + [char]0x2039)    # â€¹
$badGt = [string]([char]0xE2 + [char]0x20AC + [char]0x203A)    # â€º
$badTimes = [string]([char]0xC3 + [char]0xD7)                  # Ã—
$badApos = [string]([char]0xE2 + [char]0x20AC + [char]2122)    # â€™
$badPound = [string]([char]0xC2 + [char]0xA3)                  # Â£

$replacements = @{
    $poundChar = '$'
    $dongChar = '$'
    $badMinus = '-'
    $badMinus2 = '-'
    $badCross = [string][char]0x2715
    $badCross2 = [string][char]0x2715
    $badQuote = [string][char]0x2713
    $badBullet = [string][char]0x2022
    $badLt = [string][char]0x2039
    $badGt = [string][char]0x203A
    $badTimes = [string][char]0x2715
    $badApos = "'"
    $badPound = '$'
}

foreach ($file in $files) {
    # Read file content as UTF-8
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
