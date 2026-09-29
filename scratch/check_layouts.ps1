$files = @(
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shared\_Layout.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shop2\Shared\_Layout.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shopnew\Shared\_Layout.cshtml"
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
