$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();

# Ticket types
$cmd = $conn.CreateCommand();
$cmd.CommandText = "SELECT TicketTypeId, TypeName, BasePrice FROM TicketTypes";
$r = $cmd.ExecuteReader();
Write-Output "=== TicketTypes ==="
while ($r.Read()) { Write-Output ($r.GetInt32(0).ToString() + " | " + $r.GetString(1) + " | " + $r.GetDecimal(2).ToString()) }
$r.Close();

# All experiences
$cmd2 = $conn.CreateCommand();
$cmd2.CommandText = "SELECT ExperienceId, Name, Price FROM Experience";
$r2 = $cmd2.ExecuteReader();
Write-Output "`n=== All Experiences ==="
while ($r2.Read()) { Write-Output ($r2.GetInt32(0).ToString() + " | " + $r2.GetString(1) + " | " + $r2.GetDecimal(2).ToString()) }
$r2.Close();

# All events
$cmd3 = $conn.CreateCommand();
$cmd3.CommandText = "SELECT EventId, Title, BasePrice FROM Events";
$r3 = $cmd3.ExecuteReader();
Write-Output "`n=== All Events ==="
while ($r3.Read()) { Write-Output ($r3.GetInt32(0).ToString() + " | " + $r3.GetString(1) + " | " + $r3.GetDecimal(2).ToString()) }
$r3.Close();

# Shop products for orders
$cmd4 = $conn.CreateCommand();
$cmd4.CommandText = "SELECT TOP 10 ProductId, Name, Price FROM ShopProducts WHERE IsActive=1";
$r4 = $cmd4.ExecuteReader();
Write-Output "`n=== Sample ShopProducts ==="
while ($r4.Read()) { Write-Output ($r4.GetInt32(0).ToString() + " | " + $r4.GetString(1) + " | " + $r4.GetDecimal(2).ToString()) }
$r4.Close();

# Check constraint on OrderType
$cmd5 = $conn.CreateCommand();
$cmd5.CommandText = "SELECT DISTINCT OrderType FROM Orders";
$r5 = $cmd5.ExecuteReader();
Write-Output "`n=== Existing OrderTypes ==="
while ($r5.Read()) { Write-Output $r5.GetString(0) }
$r5.Close();

# Check all user count
$cmd6 = $conn.CreateCommand();
$cmd6.CommandText = "SELECT COUNT(*) FROM Users";
$userCount = $cmd6.ExecuteScalar();
Write-Output ("`n=== Total users: " + $userCount.ToString() + " ===")

# Check constraint definition
$cmd7 = $conn.CreateCommand();
$cmd7.CommandText = "SELECT name, definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('Orders')";
$r7 = $cmd7.ExecuteReader();
Write-Output "`n=== Orders Check Constraints ==="
while ($r7.Read()) { Write-Output ($r7.GetString(0) + ": " + $r7.GetString(1)) }
$r7.Close();

$conn.Close();
