# Solution: The page loads but the button does nothing

> Stop. Have you run `./verify.sh`?

Two separate bugs, and the second one is why the first was invisible.

**Bug 1 - the contract mismatch.** `index.html` uses `hx-post`, the API's switch
only implements `OPTIONS` and `GET`, so a POST falls through to
`default: 405 Method not allowed`. "Curling it by hand works" because the
developer curled it with GET, which is the default. The front end and the back
end disagree about the method and nobody compared them.

Fix either side - `hx-get` in the markup, or add a `case "POST"` - but pick
deliberately. A read with no side effects should be a GET.

**Bug 2 - the error path reports success.** Look at the catch:

    } catch (err) {
      console.error("error", err);
      res.end();          // <- no writeHead
    }

`res.end()` with no status set sends Node's default, which is **200**. So every
server-side exception returns `200 OK` with an empty body. The browser gets a
successful empty response, renders nothing, and logs no error - which is exactly
the reported symptom, and the reason this survived in production.

Fix:

    } catch (err) {
      console.error("error", err);
      if (!res.headersSent) res.writeHead(500, { "Content-Type": "text/plain" });
      res.end("Internal Server Error");
    }

The `headersSent` guard matters: if the handler already wrote a 200 before
throwing, you cannot change the status, and calling writeHead twice throws a
second error inside your error handler.

Why this one is worth remembering: a 200 with an empty body is invisible to
every layer of monitoring you have. Load balancer health checks pass, your
5xx-rate alert never fires, the SLO looks perfect, and the only evidence is a
line in a container log nobody reads. "Errors must not return 200" is a
reliability rule, not a style preference.

