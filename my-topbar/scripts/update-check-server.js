const http = require('http');
const { exec } = require('child_process');

const PORT = 6127;
// Verifica reinicio pendente (update ja instalado) OU atualizacoes
// disponiveis para instalar via API real do Windows Update (COM).
const path = require('path');
const CHECK_SCRIPT = path.join(__dirname, 'check-windows-updates.ps1');

let hasUpdates = false;

function checkUpdates() {
  exec(
    `powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "${CHECK_SCRIPT}"`,
    { windowsHide: true, timeout: 120000 },
    (err, stdout) => {
      if (err) return;
      hasUpdates = stdout.trim().toLowerCase() === 'true';
    }
  );
}

checkUpdates();
// Verifica a cada 30 min (checagem e assincrona, nao trava o servidor HTTP)
setInterval(checkUpdates, 1800000);

http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ hasUpdates }));
}).listen(PORT, 'localhost');
