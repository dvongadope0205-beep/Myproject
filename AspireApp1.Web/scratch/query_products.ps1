$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();
$cmd = $conn.CreateCommand();
$cmd.CommandText = "SELECT ProductId, Name, IsSizeEnabled, IsSizeChartEnabled FROM ShopProducts";
$r = $cmd.ExecuteReader();
while ($r.Read()) {
    Write-Output ($r.GetInt32(0).ToString() + " | " + $r.GetString(1) + " | SizeEnabled: " + $r.GetBoolean(2).ToString() + " | ChartEnabled: " + $r.GetBoolean(3).ToString());
}
$conn.Close();
