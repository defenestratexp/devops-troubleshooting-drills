# Solution: A filter silently drops rows

> Stop. Have you run `./verify.sh`?

`archived != true` does not mean "archived is not true". In SQL, any
comparison with NULL evaluates to **NULL**, not TRUE or FALSE - and `WHERE`
keeps only rows where the predicate is TRUE. So the four rows with
`archived = NULL` are discarded by the filter that was supposed to include them.

Prove it to yourself before fixing it:

    SELECT archived, count(*) FROM users GROUP BY archived;
    SELECT NULL != true;        -- returns NULL, not t

Three correct fixes, in descending order of how much I would want them in a code
review:

1. **Say what you mean, using the NULL-safe operator:**

       WHERE archived IS NOT TRUE

   `IS [NOT] TRUE/FALSE/UNKNOWN` is three-valued-logic aware and reads exactly
   like the requirement. This is the best fix to the query.

2. **Handle the NULL explicitly:**

       WHERE archived = false OR archived IS NULL
       WHERE COALESCE(archived, false) = false

   Correct, but `COALESCE` on the column usually prevents an index from being
   used, so it costs you on a large table.

3. **Fix the schema, which is where the bug really lives.** A boolean flag with
   three possible states is a modelling error. `archived BOOLEAN NOT NULL
   DEFAULT false` makes the broken query impossible to write. If NULL is
   genuinely meaningful - "we do not know" - then it is not a boolean and should
   be an enum or a nullable timestamp (`archived_at`), which is the pattern most
   schemas settle on because it carries *when* as well as *whether*.

Two more places the same trap bites, worth knowing because interviewers like
them:

- `NOT IN (subquery)` returns NO rows if the subquery yields a single NULL.
  `NOT EXISTS` does not have this behaviour. This one has caused real outages.
- `COUNT(column)` skips NULLs while `COUNT(*)` does not, so the two disagree on
  exactly this data and neither is wrong.

The transferable instinct: when a filter returns fewer rows than you expect and
the SQL looks right, **group by the column you are filtering on** and look at
what values actually exist - including NULL. Do not reason about the data, ask
it.

