$path = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\AdminDashboard.cshtml.cs"
$content = [System.IO.File]::ReadAllText($path)

# Correct the escaped quotes back to double-double quotes for verbatim C# string
$content = $content.Replace('max\"99\" min\"1\" type\"number\" value\"1\"', 'max=""99"" min=""1"" type=""number"" value=""1""')
$content = $content.Replace('class=\"quantity-button qty-plus\" type=\"button\"', 'class=""quantity-button qty-plus"" type=""button""')
$content = $content.Replace('type=\"button\"', 'type=""button""')
$content = $content.Replace('class=\"price-item\"', 'class=""price-item""')

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
write-host "Replacement completed successfully."
