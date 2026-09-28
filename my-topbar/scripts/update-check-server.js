const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = 6127;
// Verifica reinicio pendente (update ja instalado) OU atualizacoes
// disponiveis para instalar via API real do Windows Update (COM).
const CHECK_SCRIPT = path.join(__dirname, 'check-windows-updates.ps1');
const LOG_FILE = path.join(__dirname, 'update-check-server.log');

const CHECK_INTERVAL_MS = 1800000; // 30 min
const RETRY_DELAY_MS = 60000;      // 1 min, em caso de falha
const MAX_FAILURES = 3;            // apos isso, desliga o sininho

let hasUpdates = false;
let consecutiveFailures = 0;
let busy = false;

function log(msg) {
  const ts = new Date().toISOString();
  const line = `[${ts}] ${msg}`;
  try {
    fs.appendFileSync(LOG_FILE, line + '\n');
  } catch (e) {}
}

function checkUpdates() {
  if (busy) return;
  busy = true;

  exec(
    `powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "${CHECK_SCRIPT}"`,
    { windowsHide: true, timeout: 120000 },
    (err, stdout) => {
      if (err) {
        consecutiveFailures++;
        log(
          `Falha #${consecutiveFailures} na checagem ` +
          `(${err.signal || err.code || err.message}); reagendando em ${RETRY_DELAY_MS}ms`
        );

        // Depois de varias falhas seguidas, nao ha como saber se existe
        // atualizacao. Para nao deixar o sininho preso em "true" obsoleto,
        // desliga ate a proxima checagem bem-sucedida.
        if (consecutiveFailures >= MAX_FAILURES && hasUpdates) {
          hasUpdates = false;
          log(`${MAX_FAILURES} falhas seguidas -> sininho desligado (hasUpdates=false)`);
        }

        busy = false;
        setTimeout(checkUpdates, RETRY_DELAY_MS);
        return;
      }

      consecutiveFailures = 0;
      hasUpdates = (stdout || '').trim().toLowerCase() === 'true';
      log(`Checagem OK -> hasUpdates=${hasUpdates}`);
      busy = false;
    }
  );
}

checkUpdates();
setInterval(checkUpdates, CHECK_INTERVAL_MS);

http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ hasUpdates }));
}).listen(PORT, 'localhost');
