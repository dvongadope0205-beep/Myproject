$searchDir = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shopnew"
$files = Get-ChildItem -Path $searchDir -Recurse -Filter *.cshtml

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    $openLabels = [regex]::Matches($content, '(?i)<label\b').Count
    $closeLabels = [regex]::Matches($content, '(?i)</label>').Count
    
    $openH3 = [regex]::Matches($content, '(?i)<h3\b').Count
    $closeH3 = [regex]::Matches($content, '(?i)</h3>').Count

    $openDiv = [regex]::Matches($content, '(?i)<div\b').Count
    $closeDiv = [regex]::Matches($content, '(?i)</div>').Count

    if ($openLabels -ne $closeLabels -or $openH3 -ne $closeH3 -or $openDiv -ne $closeDiv) {
        Write-Output "Mismatched: $($file.Name)"
        Write-Output "  Labels: Open=$openLabels, Close=$closeLabels"
        Write-Output "  H3:     Open=$openH3, Close=$closeH3"
        Write-Output "  Div:    Open=$openDiv, Close=$closeDiv"
        Write-Output "------------------------"
    }
}
