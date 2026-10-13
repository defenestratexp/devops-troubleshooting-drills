# Solution: Random lookup fails most of the time

> Stop. Have you run `./verify.sh`?

**Two bugs that only break together, which is why fixing one does not help.**

Bug A is in the SQL. `ALTER SEQUENCE items_id_seq RESTART WITH 40` runs BEFORE
the inserts, so the ten rows get ids **40 to 49**, not 1 to 10. Confirm it
rather than assuming:

    SELECT count(*), min(id), max(id) FROM items;

Bug B is in the JavaScript:

    Math.ceil(Math.random() * limit * 2)

With `max(id) = 49` that asks for an id between 1 and 98. Only 40-49 exist, so
roughly 10 of 98 candidate values can hit a row - about a 10% success rate,
distributed randomly, which is exactly the "no pattern" symptom.

Now the instructive part. Fix ONLY the `* 2` and you still ask for 1-49, of
which 1-39 are missing - still ~80% failure. Fix ONLY the sequence and ids
become 1-10 while you still ask for 1-20 - ~50% failure. **The behaviour
improves without becoming correct**, which is how people conclude their fix was
wrong and revert a good change.

The robust fix is to stop guessing ids altogether. Do not model a random row as
"pick a number between 1 and max" - that assumes a dense, gap-free id space,
which is false the moment anything is deleted or a sequence skips:

    SELECT body FROM items ORDER BY random() LIMIT 1;

or, for a large table where `ORDER BY random()` is too expensive:

    SELECT body FROM items OFFSET floor(random() * (SELECT count(*) FROM items)) LIMIT 1;

Third defect worth naming even though the verify does not test it directly:
`row.rows[0].body` throws a TypeError when there is no row. Guard it. A missing
row is a normal outcome of this design, not an exceptional one, and it should
produce a 404 or a retry rather than an unhandled exception.

The lesson to say out loud: **"my change made it better but not correct" is the
signature of two interacting bugs.** Partial improvement is not weak evidence of
a right fix - it is strong evidence of a second cause.

