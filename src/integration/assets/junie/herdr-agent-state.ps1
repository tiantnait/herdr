# installed by herdr
# managed by herdr; reinstalling the integration replaces this file.
# HERDR_INTEGRATION_ID=junie
# HERDR_INTEGRATION_VERSION=1

param([string]$Action = "")
if ($Action -notin @("session", "working", "blocked", "idle", "release")) { exit 0 }
if ($env:HERDR_ENV -ne "1" -or [string]::IsNullOrWhiteSpace($env:HERDR_PANE_ID)) { exit 0 }
if ([string]::IsNullOrWhiteSpace($env:HERDR_SOCKET_PATH)) { exit 0 }

$inputText = [Console]::In.ReadToEnd()
try { $payload = if ($inputText.Trim()) { $inputText | ConvertFrom-Json } else { $null } } catch { $payload = $null }
$sessionId = if ($null -ne $payload) { [string]$payload.session_id } else { "" }
if ($Action -eq "session" -and [string]::IsNullOrWhiteSpace($sessionId)) { exit 0 }
$seq = [DateTime]::UtcNow.Ticks
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { "herdr" }
$commandArgs = @("pane")
if ($Action -eq "session") {
    $commandArgs += @("report-agent-session", $env:HERDR_PANE_ID, "--source", "herdr:junie", "--agent", "junie", "--agent-session-id", $sessionId, "--seq", $seq)
} elseif ($Action -eq "release") {
    $commandArgs += @("release-agent", $env:HERDR_PANE_ID, "--source", "herdr:junie", "--agent", "junie", "--seq", $seq)
} else {
    $commandArgs += @("report-agent", $env:HERDR_PANE_ID, "--source", "herdr:junie", "--agent", "junie", "--state", $Action, "--seq", $seq)
    if ($sessionId) { $commandArgs += @("--agent-session-id", $sessionId) }
}
try { & $herdr @commandArgs 2>$null | Out-Null } catch { }