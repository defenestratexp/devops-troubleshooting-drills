const http = require('http');
const PORT = 3000;
// Bind explicitly to loopback so nothing outside this box can reach it.
http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('hello\n');
}).listen(PORT, '0.0.0.0', () => {
  console.log(`listening on 127.0.0.1:${PORT}`);
});
