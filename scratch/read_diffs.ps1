$logFile = "C:\Users\ADMIN\.gemini\antigravity\brain\0cc1fc54-2839-41f0-adf7-48b10ea84e19\.system_generated\logs\transcript.jsonl"
if (Test-Path $logFile) {
    $lines = Get-Content $logFile
    foreach ($line in $lines) {
        if ($line -like '*Tickets.cshtml*' -or $line -like '*Donate.cshtml*') {
            try {
                $obj = ConvertFrom-Json $line
                if ($obj.tool_calls) {
                    foreach ($tc in $obj.tool_calls) {
                        if ($tc.name -eq "replace_file_content") {
                            Write-Output "File: $($tc.args.TargetFile)"
                            Write-Output "Instruction: $($tc.args.Instruction)"
                            Write-Output "TargetContent: $($tc.args.TargetContent)"
                            Write-Output "ReplacementContent: $($tc.args.ReplacementContent)"
                            Write-Output "=============================="
                        }
                    }
                }
                if ($obj.content -like '*[diff_block_start]*') {
                    Write-Output "CONTENT DIFF:"
                    Write-Output $obj.content
                    Write-Output "=============================="
                }
            } catch {
                # Ignore json parse error
            }
        }
    }
} else {
    Write-Output "Log file not found"
}
