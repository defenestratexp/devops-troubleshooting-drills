    ./setup.sh

Then answer, in ANSWERS.md:

 1. How many connections exist, and what STATE are they in? Give the query.
 2. Which state is the problem, and why is it worse than plain "idle"?
 3. Name the specific query that finds long-running transactions, with duration.
 4. Terminate only the offending sessions, leaving any legitimate ones. Give the
    query you used.
 5. Is raising max_connections the right fix? Argue both sides, then commit to
    one. What would you do instead or in addition?
 6. What would you add to monitoring so this pages BEFORE the app fails?

Cleanup:  docker rm -f practice-pg
