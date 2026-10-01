<#
.SYNOPSIS
  Corrige janelas do GlazeWM que nao abrem em tela cheia porque o Windows
  ficou com uma area de trabalho (work area) presa, reservando espaco para
  a taskbar nativa mesmo com "ocultar automaticamente" ativado.

.DESCRIPTION
  Sintoma: depois de reiniciar o explorer.exe (ex.: apos remover um mod/app
  que conflitava com ele, como o ExplorerPatcher), as janelas tiling do
  GlazeWM continuam com a altura antiga, como se a taskbar nativa ainda
  estivesse ocupando ~60px na parte de baixo do monitor — mesmo ela estando
  configurada para auto-hide.

  Causa: o explorer.exe registra a taskbar como um "appbar" (SHAppBarMessage)
  assim que inicia. Se ela for recriada enquanto o GlazeWM/outro processo ja
  tiver lido a area de trabalho, o Windows pode manter a reserva antiga ate
  que o auto-hide seja reativado manualmente.

  Fix: desliga e religa o bit de "auto-hide" da taskbar via registro
  (equivalente a desmarcar/marcar "Ocultar automaticamente a barra de
  tarefas" em Configuracoes > Personalizacao > Barra de tarefas), avisa o
  shell via WM_SETTINGCHANGE, e entao pede ao GlazeWM para redesenhar as
  janelas com a area de trabalho correta.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File C:\Users\Rodrigo\.glzr\zebar\my-topbar\scripts\fix-taskbar-workarea.ps1
#>
[CmdletBinding()]
param(
  [string]$GlazewmCli = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
)

$ErrorActionPreference = 'Stop'

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class TrayFix {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
    public const int HWND_BROADCAST = 0xffff;
    public const uint WM_SETTINGCHANGE = 0x001A;
    public const uint SMTO_ABORTIFHUNG = 0x0002;
}
"@

function Send-TraySettingsChanged {
  $res = [UIntPtr]::Zero
  [TrayFix]::SendMessageTimeout(
    [IntPtr]0xffff, [TrayFix]::WM_SETTINGCHANGE, [UIntPtr]::Zero,
    'TraySettings', [TrayFix]::SMTO_ABORTIFHUNG, 2000, [ref]$res
  ) | Out-Null
}

$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'

if (-not (Test-Path $key)) {
  throw "Chave de registro da taskbar nao encontrada: $key"
}

Write-Host 'Desligando auto-hide da taskbar...'
$settings = (Get-ItemProperty $key).Settings
$settings[8] = $settings[8] -band (-bnot 0x1)
Set-ItemProperty -Path $key -Name Settings -Value $settings
Send-TraySettingsChanged
Start-Sleep -Milliseconds 800

Write-Host 'Religando auto-hide da taskbar...'
$settings2 = (Get-ItemProperty $key).Settings
$settings2[8] = $settings2[8] -bor 0x1
Set-ItemProperty -Path $key -Name Settings -Value $settings2
Send-TraySettingsChanged
Start-Sleep -Milliseconds 500

if (Test-Path $GlazewmCli) {
  Write-Host 'Pedindo ao GlazeWM para redesenhar as janelas...'
  & $GlazewmCli command 'wm-redraw' | Out-Null
} else {
  Write-Warning "GlazeWM CLI nao encontrado em '$GlazewmCli'; pule esta etapa ou ajuste o parametro -GlazewmCli."
}

Write-Host 'Concluido. Verifique se as janelas agora preenchem a tela inteira.'
