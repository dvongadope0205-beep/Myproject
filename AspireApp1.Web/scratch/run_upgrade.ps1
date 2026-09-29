$conn = New-Object System.Data.SqlClient.SqlConnection("Server=(localdb)\MSSQLLocalDB;Database=ZooDatabase;Integrated Security=True");
$conn.Open();
$script = Get-Content -Raw -Path "c:\WEBDEV\AspireApp1\AspireApp1.Web\scratch\03_DatabaseSchemaUpgrades.sql";
$statements = [System.Text.RegularExpressions.Regex]::Split($script, "(?m)^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase);
foreach ($statement in $statements) {
    if (![string]::IsNullOrWhiteSpace($statement)) {
        try {
            $cmd = $conn.CreateCommand();
            $cmd.CommandText = $statement.Trim();
            $cmd.ExecuteNonQuery() | Out-Null;
        } catch {
            Write-Error $_.Exception.Message
        }
    }
}
$conn.Close();
Write-Output "Database upgrade script executed successfully!";
