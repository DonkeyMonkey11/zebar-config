# zebar-ensure-running.ps1
# Substitui a logica antiga de "matar tudo (zebar + TODO node.exe) e reiniciar" que rodava
# em varias tarefas agendadas simultaneas (ZebarOnUnlock, ZebarWatchdog, ZebarHealthWatcher,
# ZebarDailyRestart), causando condicoes de corrida e derrubando processos Node.js
# nao relacionados ao Zebar.
#
# Este script e IDEMPOTENTE: so INICIA o que estiver faltando. Nunca faz Stop-Process.
# Identifica os processos node do zebar pela linha de comando exata (nao pelo nome
# generico "node"), entao nao interfere em outros processos Node.js do usuario.

$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = $PSScriptRoot
$logFile = Join-Path $scriptDir 'zebar-ensure.log'

function Write-Log {
    param($msg)
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
}

# Evita execucoes concorrentes (varios gatilhos podem disparar quase ao mesmo tempo:
# logon, unlock e o watchdog periodico).
$mutex = New-Object System.Threading.Mutex($false, "Global\ZebarEnsureRunning")
if (-not $mutex.WaitOne(5000)) {
    Write-Log "Outra instancia ja esta rodando - saindo."
    exit
}

try {
    # Mantem o log enxuto (ultimas 500 linhas)
    if (Test-Path $logFile) {
        $lines = Get-Content $logFile -Tail 500
        Set-Content -Path $logFile -Value $lines
    }

    # 1) zebar.exe - so inicia se nao estiver rodando
    if (-not (Get-Process -Name 'zebar' -ErrorAction SilentlyContinue)) {
        Write-Log "zebar.exe nao encontrado - iniciando"
        Start-Process 'C:\Program Files\glzr.io\Zebar\zebar.exe'
    }

    $updateJs  = Join-Path $scriptDir 'update-check-server.js'
    $activeJs  = Join-Path $scriptDir 'active-window-server.js'

    # 2) update-check-server.js (node, porta 6127) - identifica pelo command line exato
    $updateRunning = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
        Where-Object { $_.CommandLine -like "*$updateJs*" }
    if (-not $updateRunning) {
        Write-Log "update-check-server.js nao encontrado - iniciando"
        Start-Process 'C:\Program Files\nodejs\node.exe' -ArgumentList "`"$updateJs`"" -WindowStyle Hidden
    }

    # 3) active-window-server.js (node, porta 6126) - identifica pelo command line exato
    $activeRunning = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
        Where-Object { $_.CommandLine -like "*$activeJs*" }
    if (-not $activeRunning) {
        Write-Log "active-window-server.js nao encontrado - iniciando"
        Start-Process 'C:\Program Files\nodejs\node.exe' -ArgumentList "`"$activeJs`"" -WindowStyle Hidden
    }
}
finally {
    $mutex.ReleaseMutex()
}