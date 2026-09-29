$logFile = "C:\Users\ADMIN\.gemini\antigravity\brain\0cc1fc54-2839-41f0-adf7-48b10ea84e19\.system_generated\logs\transcript.jsonl"
if (Test-Path $logFile) {
    $lines = Get-Content $logFile
    foreach ($line in $lines) {
        if ($line -like '*replace_file_content*' -or $line -like '*write_to_file*') {
            try {
                $obj = ConvertFrom-Json $line
                if ($obj.tool_calls) {
                    foreach ($tc in $obj.tool_calls) {
                        Write-Output "File: $($tc.args.TargetFile)"
                        Write-Output "Instruction: $($tc.args.Instruction)"
                        Write-Output "=============================="
                    }
                }
            } catch {
                # Ignore json parse error
            }
        }
    }
} else {
    Write-Output "Log file not found"
}
