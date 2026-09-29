$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();
$script = Get-Content -Raw -Path "c:\WEBDEV\AspireApp1\AspireApp1.Web\scratch\03_SeedTransactionData.sql";
$statements = [System.Text.RegularExpressions.Regex]::Split($script, "(?m)^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase);
foreach ($statement in $statements) {
    if (![string]::IsNullOrWhiteSpace($statement)) {
        try {
            $cmd = $conn.CreateCommand();
            $cmd.CommandText = $statement.Trim();
            $cmd.CommandTimeout = 60;
            $reader = $cmd.ExecuteReader();
            if ($reader.HasRows) {
                while ($reader.Read()) {
                    $row = ""
                    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                        $row += $reader.GetName($i) + ": " + $reader.GetValue($i).ToString() + " | "
                    }
                    Write-Output $row
                }
            }
            $reader.Close();
        } catch {
            Write-Error $_.Exception.Message
        }
    }
}
$conn.Close();
Write-Output "Seed script execution completed!";
