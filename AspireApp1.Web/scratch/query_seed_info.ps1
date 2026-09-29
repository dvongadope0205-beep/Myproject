$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();

# OrderItems schema
$cmd = $conn.CreateCommand();
$cmd.CommandText = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OrderItems'";
$r = $cmd.ExecuteReader();
Write-Output "=== OrderItems Schema ==="
while ($r.Read()) { Write-Output ($r.GetString(0) + " (" + $r.GetString(1) + ")") }
$r.Close();

# Sample user IDs
$cmd2 = $conn.CreateCommand();
$cmd2.CommandText = "SELECT TOP 10 UserId, FullName, Email FROM Users";
$r2 = $cmd2.ExecuteReader();
Write-Output "`n=== Sample Users ==="
while ($r2.Read()) { Write-Output ($r2.GetInt32(0).ToString() + " | " + $r2.GetString(1) + " | " + $r2.GetString(2)) }
$r2.Close();

# Experience names
$cmd3 = $conn.CreateCommand();
$cmd3.CommandText = "SELECT TOP 5 ExperienceId, Name, Price FROM Experience";
$r3 = $cmd3.ExecuteReader();
Write-Output "`n=== Sample Experiences ==="
while ($r3.Read()) { Write-Output ($r3.GetInt32(0).ToString() + " | " + $r3.GetString(1) + " | " + $r3.GetDecimal(2).ToString()) }
$r3.Close();

# Events
$cmd4 = $conn.CreateCommand();
$cmd4.CommandText = "SELECT TOP 5 EventId, Title, BasePrice FROM Events";
$r4 = $cmd4.ExecuteReader();
Write-Output "`n=== Sample Events ==="
while ($r4.Read()) { Write-Output ($r4.GetInt32(0).ToString() + " | " + $r4.GetString(1) + " | " + $r4.GetDecimal(2).ToString()) }
$r4.Close();

# Memberships
$cmd5 = $conn.CreateCommand();
$cmd5.CommandText = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Memberships'";
$r5 = $cmd5.ExecuteReader();
Write-Output "`n=== Memberships Schema ==="
while ($r5.Read()) { Write-Output ($r5.GetString(0) + " (" + $r5.GetString(1) + ")") }
$r5.Close();

# Check existing order count
$cmd6 = $conn.CreateCommand();
$cmd6.CommandText = "SELECT COUNT(*) FROM Orders";
$r6 = $cmd6.ExecuteScalar();
Write-Output ("`n=== Existing order count: " + $r6.ToString() + " ===")

$conn.Close();
