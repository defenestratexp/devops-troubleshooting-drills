const http = require("http");
const { Pool } = require("pg");
const db = new Pool();
const PORT = 7799;

const randomUpTo = (limit) => Math.ceil(Math.random() * limit * 2);

const getRandom = async () => {
  const r = await db.query("SELECT max(id) AS max FROM items");
  const id = randomUpTo(r.rows[0].max);
  const row = await db.query("SELECT body FROM items WHERE id = $1", [id]);
  return row.rows[0].body;
};

http.createServer(async (req, res) => {
  try {
    if (req.url === "/item") {
      const body = await getRandom();
      res.writeHead(200, { "Content-Type": "text/plain" });
      res.end(body);
      return;
    }
    res.writeHead(404); res.end("Not found");
  } catch (err) {
    console.error("error", err.message);
    if (!res.headersSent) res.writeHead(500);
    res.end("error");
  }
}).listen(PORT, "0.0.0.0", () => console.log("api on " + PORT));
