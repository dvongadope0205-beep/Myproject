$files = @(
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Animals\Bat.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Animals\Lion.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Animals\Orangutan.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Animals\Voi.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\experience\curious-creature-tour.cshtml",
    "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\experience\elephant-experience.cshtml"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        $original = $content
        $content = $content -replace 'Chester\s+Zoo', 'National Zoo'
        if ($content -ne $original) {
            [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
            Write-Output "Fixed: $file"
        } else {
            Write-Output "No changes: $file"
        }
    } else {
        Write-Output "Not found: $file"
    }
}
Write-Output "All done."
