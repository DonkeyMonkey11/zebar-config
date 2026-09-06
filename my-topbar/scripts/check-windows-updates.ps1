# check-windows-updates.ps1
# Retorna "true" se houver atualizacoes do Windows disponiveis para instalar
# OU se ja houver um reinicio pendente de uma atualizacao ja instalada.
# Retorna "false" caso contrario. Usado pelo update-check-server.js (sino da barra).

$ErrorActionPreference = 'SilentlyContinue'

$rebootReq = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
$rebootPend = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

if ($rebootReq -or $rebootPend) {
    Write-Output "true"
    exit
}

try {
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result = $searcher.Search("IsInstalled=0 and IsHidden=0")

    # Ignora ruidos: drivers opcionais e atualizacoes de definicoes (Defender),
    # que chegam varias vezes por dia. So acende para atualizacoes de software relevantes.
    $ignoredCategories = @('Drivers', 'Definition Updates')
    $pending = @($result.Updates | Where-Object {
        $shouldIgnore = $false
        foreach ($cat in $_.Categories) {
            if ($ignoredCategories -contains $cat.Name) { $shouldIgnore = $true; break }
        }
        -not $shouldIgnore
    })

    if ($pending.Count -gt 0) {
        Write-Output "true"
    } else {
        Write-Output "false"
    }
} catch {
    Write-Output "false"
}
