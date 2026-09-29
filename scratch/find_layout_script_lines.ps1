$lines = Get-Content "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shared\_Layout.cshtml"
$inScript = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -like '*<script*') {
        $inScript = $true
        Write-Output "--- SCRIPT START at line $($i + 1) ---"
    }
    if ($inScript) {
        Write-Output "$($i + 1): $line"
    }
    if ($line -like '*</script>*') {
        $inScript = $false
        Write-Output "--- SCRIPT END at line $($i + 1) ---`n"
    }
}
