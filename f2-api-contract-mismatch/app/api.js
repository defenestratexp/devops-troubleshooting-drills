const http = require("http");
const PORT = 7788;

const QUOTES = ["complexity bad", "grug say no", "tools good"];

const server = http.createServer(async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  try {
    switch (req.method) {
      case "OPTIONS":
        res.writeHead(204);
        res.end();
        return;
      case "GET":
        if (req.url === "/quote") {
          res.writeHead(200, { "Content-Type": "text/plain" });
          res.end(QUOTES[Math.floor(Math.random() * QUOTES.length)]);
          return;
        }
        if (req.url === "/boom") {
          throw new Error("deliberate failure");
        }
        res.writeHead(404);
        res.end("Not found");
        return;
      default:
        res.writeHead(405);
        res.end("Method not allowed");
    }
  } catch (err) {
    console.error("error", err);
    res.end();
  }
});

server.listen(PORT, "0.0.0.0", () => console.log("api on " + PORT));
