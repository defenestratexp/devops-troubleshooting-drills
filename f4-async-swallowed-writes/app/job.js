const { Client } = require("pg");

const NAMES = ["ada", "grace", "edsger", "barbara",
               "donald", "alan", "john", "margaret"];

const run = () => {
  const db = new Client();
  db.connect();

  NAMES.forEach(async (name) => {
    await db.query("INSERT INTO records (name) VALUES ($1)", [name]);
  });

  console.log("import complete");
  db.end();
};

run();
