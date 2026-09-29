$files = @(
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\CustomerInfo.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shop2\info.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shopnew\info.cshtml"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        Write-Output "$file :"
        Write-Output "  div:   open=$([regex]::Matches($content, '<div\b').Count), close=$([regex]::Matches($content, '</div>').Count)"
        Write-Output "  h3:    open=$([regex]::Matches($content, '<h3\b').Count), close=$([regex]::Matches($content, '</h3>').Count)"
        Write-Output "  label: open=$([regex]::Matches($content, '<label\b').Count), close=$([regex]::Matches($content, '</label>').Count)"
        Write-Output "  p:     open=$([regex]::Matches($content, '<p\b').Count), close=$([regex]::Matches($content, '</p>').Count)"
        Write-Output "  style: open=$([regex]::Matches($content, '<style\b').Count), close=$([regex]::Matches($content, '</style>').Count)"
        Write-Output "  script:open=$([regex]::Matches($content, '<script\b').Count), close=$([regex]::Matches($content, '</script>').Count)"
        Write-Output "------------------------"
    } else {
        Write-Output "Not found: $file"
    }
}
