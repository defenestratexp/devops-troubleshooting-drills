# Solution: Import reports success but the table has one row

> Stop. Have you run `./verify.sh`?

The importer pulls the link text out of each line with `/>([^<]*)</` - note
the `*` - and uses it as the slug.

Look at the markup. Each line is a nested pair of anchors:

    <h2><a name="testing"></a><a href="#testing">Testing</a></h2>

The FIRST `>` ... `<` pair in that string is the `>` closing `<h2>` followed
immediately by the `<` opening `<a`. There is nothing between them. Because the
quantifier is `*`, an empty capture is a perfectly good match, so the regex
succeeds and returns `""` for **every single line**. A `+` would have been forced
to skip past it and find `Testing`.

The real problem is the pairing of two decisions:

1. `[^<]*` matches the EMPTY string happily, so every row gets `slug = ""`.
2. `ON CONFLICT (slug) DO NOTHING` means a duplicate slug is not an error. It is
   silently skipped, and the loop still increments `n`.

So the reported count is the number of lines READ, not the number of rows
WRITTEN. The two have been allowed to drift apart.

Find the real cause by making the database tell you instead of the script:

    SELECT slug, count(*) FROM quotes GROUP BY slug;

or change the insert temporarily to `RETURNING id` and count what actually
comes back.

The fix has two halves and you want both:

- Make the parse strict: `[^<]+` so an empty capture cannot match, and throw (or
  at minimum log) when a line does not parse rather than inserting a blank.
- Report what was written, not what was attempted: use `RETURNING id` and count
  the rows you get back, or check `result.rowCount`.

Why interviewers care: `ON CONFLICT DO NOTHING` and `INSERT ... IGNORE` are
extremely common ways to make an importer idempotent, and they convert data bugs
into silence. If you use them, you owe the system a reconciliation check -
"rows in equals rows out" - or you will not find out for weeks. Which is exactly
what happened here.

