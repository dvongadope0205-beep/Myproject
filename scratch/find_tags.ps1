$files = Get-ChildItem -Path "c:\WEBDEV\AspireApp1\AspireApp1.Web" -Recurse -Filter *.cshtml
foreach ($file in $files) {
    if ($file.FullName -like '*\obj\*' -or $file.FullName -like '*\bin\*') { continue }
    $content = Get-Content $file.FullName -Raw
    if ($content -match '<h3\b') {
        Write-Output "H3 found in: $($file.FullName)"
    }
    if ($content -match '<label\b') {
        Write-Output "Label found in: $($file.FullName)"
    }
}
