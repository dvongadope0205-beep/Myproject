$files = Get-ChildItem -Path "c:\WEBDEV\AspireApp1\AspireApp1.Web" -Recurse -Filter *.cshtml
foreach ($file in $files) {
    if ($file.FullName -like '*\obj\*' -or $file.FullName -like '*\bin\*') { continue }
    $lines = Get-Content $file.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '<label\b') {
            Write-Output "--- Label found in $($file.FullName) at line $($i + 1) ---"
            # Print 5 lines
            $start = [Math]::Max(0, $i - 1)
            $end = [Math]::Min($lines.Count - 1, $i + 4)
            for ($j = $start; $j -le $end; $j++) {
                Write-Output "$($j+1): $($lines[$j])"
            }
            Write-Output "--------------------------------------------------"
        }
    }
}
