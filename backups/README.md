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