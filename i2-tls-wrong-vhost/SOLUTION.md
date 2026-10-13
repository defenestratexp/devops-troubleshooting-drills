# Solution: TLS: the wrong site answers for a name nobody configured

> Stop. Have you run `./verify.sh`?

## Why it happens

The certificate has to be chosen during the TLS handshake, before any HTTP
exists. At that moment nginx has exactly one piece of information about what
the client wants: the **SNI** value in the ClientHello. The `Host` header is
inside the encrypted request and arrives later — so by the time nginx could
read it, it has already presented a certificate.

So nginx must pick a `server` block from SNI alone. When SNI matches no
`server_name`, it falls back to the **default server for that listen
address** — and when nobody has declared one, the default is simply *the first
matching `server` block nginx loaded*.

Load order is `include conf.d/*.conf`, which globs in filename order. Hence
`10-app.conf` wins, which is why renaming it to `30-app.conf` changes the
answer. That experiment is the proof: the behaviour was never about app being
special, only about it being first.

The result is a server that answers for every name pointed at its IP —
including unconfigured subdomains of your own, and including any name an
attacker chooses to point at you — with a real site's content, under a
certificate for a name the client did not ask for.

## The fix

Claim the default explicitly, with a block that serves nothing:

    # conf.d/00-catchall.conf
    server {
        listen 443 ssl default_server;
        ssl_reject_handshake on;
    }

`ssl_reject_handshake on` (nginx 1.19.4+) aborts the handshake with the TLS
alert `unrecognized_name` (alert 112) and **presents no certificate at all**,
which is exactly right: a server with nothing to say for this name should not
hand over a certificate for a different one.

The filename matters only as insurance. `default_server` is explicit and wins
regardless of load order — but naming it `00-` means that if someone later
deletes the directive, the fallback is still this block rather than a real
site.

Do the same for plain HTTP, where the equivalent is a `444` (nginx's
"close the connection without a response"):

    server {
        listen 80 default_server;
        return 444;
    }

### Before `ssl_reject_handshake` existed

The old idiom was a default block with a deliberately useless self-signed
certificate and `return 444`. It works, but the client still receives a
certificate — and the certificate it receives is one that will produce a
confusing name-mismatch error rather than an honest "I do not serve that
name". `ssl_reject_handshake` is strictly better where you have it.

## What this is worth in an interview

The chain of reasoning is the valuable part, and it generalises past nginx:

- **SNI is chosen before HTTP exists**, so certificate selection and request
  routing are two separate decisions made at two different layers. Most
  confusing vhost behaviour comes from conflating them.
- Any TLS terminator serving multiple names has a default, and if you have not
  chosen it, something else has: Apache falls back to the first vhost,
  HAProxy to the first `crt` in the directory, an ALB to the listener's default
  certificate and default action.
- **A 200 from a hostname you never configured is a finding, not a curiosity.**
  It means the name is being served by something that has no idea it is
  responsible for it, and it is how a dangling DNS record turns into someone
  else's content on your certificate.

## The habit

Two checks worth having:

- `nginx -T` prints the fully merged configuration in load order. It is the
  only honest answer to "which block is the default", and it also catches a
  `server_name` typo that silently moves a site into the fallback.
- A monitoring check for a name that *should not* resolve to a real site, and
  which asserts the handshake is **refused**. Most monitoring only asserts that
  things which should work do. This drill exists because a check written to
  prove a site was up accidentally proved something else was wrong.

Worth also knowing the matching order within SNI, since it decides which block
is chosen when several could match: exact names first, then leading-wildcard
(`*.n9n.test`), then trailing-wildcard, then regular expressions in
configuration order — and only then the default server.
