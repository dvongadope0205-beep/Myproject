$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();
$cmd = $conn.CreateCommand();
$cmd.CommandText = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts'";
$r = $cmd.ExecuteReader();
while ($r.Read()) {
    Write-Output ($r.GetString(0) + " (" + $r.GetString(1) + ")");
}
$conn.Close();
