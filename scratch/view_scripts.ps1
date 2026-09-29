$content = Get-Content "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shared\_Layout.cshtml" -Raw
$matches = [regex]::Matches($content, '(?is)<script[^>]*>(.*?)</script>')
foreach ($m in $matches) {
    Write-Output "=== SCRIPT BLOCK ==="
    Write-Output $m.Value
    Write-Output "===================="
}
