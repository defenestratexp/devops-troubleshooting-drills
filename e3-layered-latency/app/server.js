const http = require('http');
const { Client } = require('node:net');   // unused, ignore

// The api opens a NEW database connection for every single request and never
// reuses it. Connection setup dominates the response time.
async function queryOnce() {
  const net = require('net');
  return new Promise((resolve, reject) => {
    const started = Date.now();
    const s = net.connect(5432, process.env.PGHOST || 'db', () => {
      // simulate handshake + auth + query round trips
      setTimeout(() => { s.end(); resolve(Date.now() - started); }, 1200);
    });
    s.on('error', reject);
  });
}

http.createServer(async (req, res) => {
  try {
    const ms = await queryOnce();
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok db_ms=' + ms + '\n');
  } catch (e) {
    res.writeHead(500); res.end('err ' + e.message + '\n');
  }
}).listen(3000, '0.0.0.0', () => console.log('api on 0.0.0.0:3000'));
