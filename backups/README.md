# Backups de configuração (fora do ecossistema glzr.io)

Esta pasta guarda backups das configurações de apps que **não** fazem parte do
setup do Zebar/GlazeWM, para recuperação caso você precise formatar o PC.

> Zebar e GlazeWM já estão totalmente versionados no topo deste repositório —
> não precisam de backup aqui.

## Windhawk

Pasta `windhawk/`. Contém:

- `userprofile.json` — lista de mods instalados e suas versões.
- `taskbar-styler-settings-backup.xml` — o estilo/aparência da sua taskbar.
- `ModsSource/*.wh.cpp` — código-fonte de todos os mods que você usa.

**Como restaurar:**
1. Instale o Windhawk (https://windhawk.net).
2. Feche o Windhawk.
3. Copie `userprofile.json` e `taskbar-styler-settings-backup.xml` para
   `C:\ProgramData\Windhawk\`.
4. Copie os arquivos `*.wh.cpp` para `C:\ProgramData\Windhawk\ModsSource\`.
5. Abra o Windhawk. Os mods aparecerão instalados com a mesma versão; ele
   recompila o que for necessário sozinho.

## PowerToys

Pasta `powertoys/`. Contém `settings.json`.

**Como restaurar:**
1. Instale o PowerToys (Microsoft Store ou GitHub).
2. Feche o PowerToys (clique direito no ícone da bandeja → Sair).
3. Copie `settings.json` para
   `C:\Users\SEU_USUARIO\AppData\Local\Microsoft\PowerToys\settings.json`.
4. Abra o PowerToys.

## Armadilhas conhecidas

### ExplorerPatcher quebra a barra (conflito com Windhawk)

**NÃO instale o ExplorerPatcher.** Ele está marcado com `winget pin add --id
valinet.ExplorerPatcher` para nunca ser reinstalado/atualizado automaticamente.

Histórico: em 01/10/2026, um `winget update --all` instalou o ExplorerPatcher
(provavelmente como dependência de outro pacote) numa versão compilada para
um build do Windows diferente do instalado. Ele passou a brigar com o
Windhawk (que já faz toda a customização da taskbar via Taskbar Styler) e
travou a barra por completo. Corrigido com:
```powershell
winget uninstall --id valinet.ExplorerPatcher
winget pin add --id valinet.ExplorerPatcher
```
Se a barra quebrar de novo do nada, verifique primeiro se o ExplorerPatcher
voltou (`winget list --id valinet.ExplorerPatcher`).

### Janelas do GlazeWM menores que a tela depois de reiniciar o explorer.exe

Se o `explorer.exe` for reiniciado (por qualquer motivo: crash, correção de
mod, etc.) e as janelas do GlazeWM pararem de abrir em tela cheia — como se
sobrasse uma faixa vazia onde ficaria a taskbar nativa —, rode:
```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Rodrigo\.glzr\zebar\my-topbar\scripts\fix-taskbar-workarea.ps1
```
Isso religa o auto-hide da taskbar nativa (forçando o Windows a liberar a
área de trabalho presa) e manda o GlazeWM redesenhar as janelas. Detalhes da
causa no cabeçalho do próprio script.
