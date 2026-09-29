$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();
$cmd = $conn.CreateCommand();
$cmd.CommandText = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TicketTypes'";
$r = $cmd.ExecuteReader();
Write-Output "=== TicketTypes Schema ==="
while ($r.Read()) { Write-Output ($r.GetString(0) + " (" + $r.GetString(1) + ")") }
$r.Close();

$cmd2 = $conn.CreateCommand();
$cmd2.CommandText = "SELECT * FROM TicketTypes";
$r2 = $cmd2.ExecuteReader();
Write-Output "`n=== TicketTypes Data ==="
$colCount = $r2.FieldCount
for ($i = 0; $i -lt $colCount; $i++) { Write-Host -NoNewline ($r2.GetName($i) + " | ") }
Write-Host ""
while ($r2.Read()) {
    $row = ""
    for ($i = 0; $i -lt $colCount; $i++) {
        $row += $r2.GetValue($i).ToString() + " | "
    }
    Write-Output $row
}
$r2.Close();
$conn.Close();
