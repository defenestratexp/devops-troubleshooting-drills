# The page loads but the button does nothing

**Budget:** ~25 minutes

## The report

A single-page app has a button that should fetch a quote. Clicking it does
nothing - no text appears, and the browser console shows no error. The API is
up: the container is running and healthy.

Curling the API by hand "works". The developer insists the API is fine and the
problem must be the front end.

Make the button's request return the quote body, and make a genuine server-side
failure return a 5xx instead of what it returns today.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
