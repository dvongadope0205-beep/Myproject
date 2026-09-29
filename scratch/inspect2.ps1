$content = [System.IO.File]::ReadAllText("c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\AdminDashboard.cshtml.cs")
$lines = $content -split "\n"
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -like "*max=*") {
        $l = $lines[$i]
        write-host "Index: $i"
        write-host "Text: $l"
        $chars = $l.ToCharArray()
        for ($j = 0; $j -lt $chars.Length; $j++) {
            $val = [int]$chars[$j]
            $ch = $chars[$j]
            write-host "  Char $j ($val): '$ch'"
        }
    }
}
