# managed by herdr; reinstalling the integration replaces this file.
# HERDR_INTEGRATION_ID=junie
# HERDR_INTEGRATION_VERSION=1

# Reports the current Junie session id to Herdr so the pane can be restored
# after a Herdr server restart. Lifecycle state stays with Herdr's screen
# detection because Junie does not emit a hook on every interruption.

param([string]$Action = "")
if ($Action -ne "session") { exit 0 }
if ($env:HERDR_ENV -ne "1" -or [string]::IsNullOrWhiteSpace($env:HERDR_PANE_ID)) { exit 0 }
if ([string]::IsNullOrWhiteSpace($env:HERDR_SOCKET_PATH)) { exit 0 }

$inputText = [Console]::In.ReadToEnd()
try { $payload = if ($inputText.Trim()) { $inputText | ConvertFrom-Json } else { $null } } catch { $payload = $null }
$sessionId = if ($null -ne $payload) { [string]$payload.session_id } else { "" }
if ([string]::IsNullOrWhiteSpace($sessionId)) { exit 0 }
$seq = [DateTime]::UtcNow.Ticks
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { "herdr" }
$commandArgs = @("pane", "report-agent-session", $env:HERDR_PANE_ID, "--source", "herdr:junie", "--agent", "junie", "--agent-session-id", $sessionId, "--seq", $seq)
try { & $herdr @commandArgs 2>$null | Out-Null } catch { }
