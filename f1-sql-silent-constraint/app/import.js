const fs = require("fs");
const { Client } = require("pg");

const lines = fs.readFileSync("./quotes.txt", "utf8").trim().split("\n");

(async () => {
  const db = new Client();
  await db.connect();
  let n = 0;
  for (const line of lines) {
    // pull the link text out to use as the slug
    const slug = (/>([^<]*)</.exec(line) || [, ""])[1];
    const body = line;
    await db.query(
      "INSERT INTO quotes (slug, body) VALUES ($1, $2) ON CONFLICT (slug) DO NOTHING",
      [slug, body]
    );
    n++;
  }
  console.log(`imported ${n} quotes`);
  await db.end();
})();
