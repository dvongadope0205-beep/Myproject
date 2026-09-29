$webDir = "c:\WEBDEV\AspireApp1\AspireApp1.Web"

# Search all .css files
$cssFiles = Get-ChildItem -Path $webDir -Recurse -Filter *.css
foreach ($file in $cssFiles) {
    if ($file.FullName -like '*\lib\*' -or $file.FullName -like '*\obj\*' -or $file.FullName -like '*\bin\*') { continue }
    $content = Get-Content $file.FullName -Raw
    
    # Check for empty selector/missing selector before {
    # Match a { that is either at start of file or after another } or ; with only whitespace in between
    # But note media queries might contain nested braces, like @media ... { .class { ... } }
    # A simple regex for "selector missing" in CSS is a { that follows whitespace/newlines after a ; or }
    # Or just count braces
    $openBraces = [regex]::Matches($content, '\{').Count
    $closeBraces = [regex]::Matches($content, '\}').Count
    if ($openBraces -ne $closeBraces) {
        Write-Output "CSS mismatch in: $($file.FullName) - Open={0}, Close={1}" -f $openBraces, $closeBraces
    }
}

# Search all .cshtml files for style/script block issues
$cshtmlFiles = Get-ChildItem -Path $webDir -Recurse -Filter *.cshtml
foreach ($file in $cshtmlFiles) {
    if ($file.FullName -like '*\obj\*' -or $file.FullName -like '*\bin\*') { continue }
    $content = Get-Content $file.FullName -Raw
    
    # Style blocks
    $styleMatches = [regex]::Matches($content, '(?is)<style[^>]*>(.*?)</style>')
    foreach ($m in $styleMatches) {
        $styleContent = $m.Groups[1].Value
        $openBraces = [regex]::Matches($styleContent, '\{').Count
        $closeBraces = [regex]::Matches($styleContent, '\}').Count
        if ($openBraces -ne $closeBraces) {
            Write-Output "STYLE tag mismatch in: $($file.FullName) - Open={0}, Close={1}" -f $openBraces, $closeBraces
        }
    }

    # Script blocks
    $scriptMatches = [regex]::Matches($content, '(?is)<script[^>]*>(.*?)</script>')
    foreach ($m in $scriptMatches) {
        $scriptContent = $m.Groups[1].Value
        $openBraces = [regex]::Matches($scriptContent, '\{').Count
        $closeBraces = [regex]::Matches($scriptContent, '\}').Count
        if ($openBraces -ne $closeBraces) {
            Write-Output "SCRIPT tag mismatch in: $($file.FullName) - Open={0}, Close={1}" -f $openBraces, $closeBraces
        }
        
        $openParen = [regex]::Matches($scriptContent, '\(').Count
        $closeParen = [regex]::Matches($scriptContent, '\)').Count
        if ($openParen -ne $closeParen) {
            Write-Output "SCRIPT tag parentheses mismatch in: $($file.FullName) - Open={0}, Close={1}" -f $openParen, $closeParen
        }
    }
}
