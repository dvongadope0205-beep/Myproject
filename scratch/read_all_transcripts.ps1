$folders = @("f5a6be33-385a-47a0-9a6b-0d7b387bb0a2", "aff00d25-3ecd-4b3a-9e55-2dd49cceb5cd")
foreach ($folder in $folders) {
    $logFile = "C:\Users\ADMIN\.gemini\antigravity\brain\$folder\.system_generated\logs\transcript.jsonl"
    if (Test-Path $logFile) {
        Write-Output "=== Transcripts for $folder ==="
        $lines = Get-Content $logFile
        foreach ($line in $lines) {
            if ($line -like '*replace_file_content*' -or $line -like '*write_to_file*') {
                try {
                    $obj = ConvertFrom-Json $line
                    if ($obj.tool_calls) {
                        foreach ($tc in $obj.tool_calls) {
                            if ($tc.name -eq "replace_file_content" -or $tc.name -eq "write_to_file") {
                                Write-Output "  File: $($tc.args.TargetFile)"
                                Write-Output "  Instruction: $($tc.args.Instruction)"
                                Write-Output "  ----------------"
                            }
                        }
                    }
                } catch {}
            }
        }
    }
}
