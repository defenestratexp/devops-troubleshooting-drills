# Solution: Batch job says done, writes nothing

> Stop. Have you run `./verify.sh`?

`Array.prototype.forEach` **does not await an async callback.** It calls the
function, gets a Promise back, and throws it away. So the loop finishes
instantly, `console.log("import complete")` runs, `db.end()` closes the
connection - and the eight queries are still pending. They are then cancelled
when the socket closes, and the process exits 0 because nothing ever rejected
into anything that was watching.

This is the single most common async bug in JavaScript, and it is ugly precisely
because it fails silently and in the success direction.

Three things are wrong and all three need fixing:

1. **`forEach` with async.** Use a plain `for...of`, which does honour `await`:

       for (const name of NAMES) {
         await db.query("INSERT INTO records (name) VALUES ($1)", [name]);
       }

   Or run them concurrently on purpose and wait for all of them:

       await Promise.all(NAMES.map((name) =>
         db.query("INSERT INTO records (name) VALUES ($1)", [name])));

   `Promise.all` is faster but gives up ordering and fails fast on the first
   rejection. `for...of` is sequential and predictable. Say which you chose and
   why - that is the interesting part of the answer.

2. **`db.connect()` and `db.end()` are not awaited either.** The same bug twice.
   `run` must be `async` and both must be awaited.

3. **Nothing sets a non-zero exit code.** An unhandled rejection in a top-level
   call does not reliably fail the process in a way a scheduler notices. Wrap it:

       run().catch((err) => { console.error(err); process.exit(1); });

   A batch job that cannot report failure is worse than no job, because
   everything downstream now trusts data that is not there.

How to catch this class of bug generally: **make the job report what the
database says, not what the loop did.** `SELECT count(*)` at the end and compare
it against the number you intended to write. The same reconciliation idea as
f1 - the count you print must come from the system of record.

