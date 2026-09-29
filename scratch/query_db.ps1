$connectionString = "Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Trusted_Connection=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT OrderId, UserId, OrderDate, PaymentStatus, TransactionRef FROM Orders WHERE UserId = 1011 ORDER BY OrderId DESC"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "OrderId: $($r['OrderId']) | UserId: $($r['UserId']) | Date: $($r['OrderDate']) | Status: $($r['PaymentStatus']) | Ref: $($r['TransactionRef'])"
}
$r.Close()
$conn.Close()
