<#
.SYNOPSIS
  Equaliza as janelas tiling do GlazeWM via IPC (WebSocket ws://127.0.0.1:6123).

.DESCRIPTION
  Para cada workspace, coloca as janelas tiling que sao filhas diretas do
  workspace com a mesma largura (tiling horizontal) ou a mesma altura (tiling
  vertical). Janelas flutuantes/fullscreen/minimizadas nao sao alteradas.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File C:\Users\Rodrigo\scripts\equalize-glazewm.ps1
#>
[CmdletBinding()]
param(
  [int]$Port = 6123
)

$ErrorActionPreference = 'Stop'
$ct = [System.Threading.CancellationToken]::None

function Send-IpcMessage {
  param([Parameter(Mandatory = $true)][string]$Message)

  $ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $ws.ConnectAsync([uri]"ws://127.0.0.1:$Port", $ct).GetAwaiter().GetResult()

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
  $ws.SendAsync(
    [System.ArraySegment[byte]]::new($bytes),
    [System.Net.WebSockets.WebSocketMessageType]::Text,
    $true,
    $ct
  ).GetAwaiter().GetResult()

  $ms = New-Object System.IO.MemoryStream
  $buf = New-Object byte[] 131072
  do {
    $r = $ws.ReceiveAsync([System.ArraySegment[byte]]::new($buf), $ct).GetAwaiter().GetResult()
    $ms.Write($buf, 0, $r.Count)
  } while (-not $r.EndOfMessage)

  $ws.Dispose()
  return ([System.Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json)
}

function Test-TilingWindow {
  param($Node)
  return ($Node.type -eq 'window' -and $Node.state.type -eq 'tiling' -and $null -ne $Node.tilingSize)
}

# Cada passada reconsult o estado atual e reaplica os tamanhos alvo.
# O redimensionamento do GlazeWM redistribui o espaco de forma proporcional
# entre os irmaos, entao varias passadas sao necessarias para convergir.
$maxPasses = 8
$processed = 0

for ($pass = 0; $pass -lt $maxPasses; $pass++) {
  $workspacesResp = Send-IpcMessage 'query workspaces'
  if (-not $workspacesResp.success) {
    throw "Falha ao consultar workspaces: $($workspacesResp.error)"
  }

  $anyChange = $false
  $processed = 0

  foreach ($workspace in $workspacesResp.data.workspaces) {
    # Ignora workspaces com split containers aninhados (fora do escopo do script).
    if (@($workspace.children | Where-Object { $_.type -eq 'split' }).Count -gt 0) {
      Write-Warning "Workspace '$($workspace.name)' tem split containers aninhados; ignorado."
      continue
    }

    $tiling = @($workspace.children | Where-Object { Test-TilingWindow $_ })
    if ($tiling.Count -lt 2) { continue }

    $direction = $workspace.tilingDirection

    if ($direction -eq 'horizontal') {
      $total = [int]($tiling | Measure-Object -Property width -Sum).Sum
    } else {
      $total = [int]($tiling | Measure-Object -Property height -Sum).Sum
    }

    $n = $tiling.Count
    $base = [int][math]::Floor($total / $n)
    $rem = $total % $n

    for ($i = 0; $i -lt ($n - 1); $i++) {
      $win = $tiling[$i]
      $current = if ($direction -eq 'horizontal') { [int]$win.width } else { [int]$win.height }
      $target = if ($i -lt $rem) { $base + 1 } else { $base }

      if ([math]::Abs($current - $target) -le 1) { continue }

      if ($direction -eq 'horizontal') {
        $cmd = "command --id $($win.id) size --width ${target}px"
      } else {
        $cmd = "command --id $($win.id) size --height ${target}px"
      }

      $resp = Send-IpcMessage $cmd
      if (-not $resp.success) {
        Write-Warning "Falha ao redimensionar '$($win.title)': $($resp.error)"
      } else {
        $anyChange = $true
      }
    }

    $processed++
  }

  if (-not $anyChange) { break }
}

Write-Host "Equalizacao concluida. Workspaces processados: $processed."
