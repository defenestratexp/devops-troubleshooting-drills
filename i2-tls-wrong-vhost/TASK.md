First, see it:

    ./setup.sh && docker compose up -d
    curl -skS --resolve other.n9n.test:18444:127.0.0.1 https://other.n9n.test:18444/

Then find out whose certificate that was:

    openssl s_client -servername other.n9n.test -connect 127.0.0.1:18444 </dev/null 2>/dev/null \
      | openssl x509 -noout -subject -ext subjectAltName

Now the experiment that explains it. Rename the two files so they load in the
other order and reload:

    mv conf.d/10-app.conf conf.d/30-app.conf
    docker compose restart
    openssl s_client -servername other.n9n.test -connect 127.0.0.1:18444 </dev/null 2>/dev/null \
      | openssl x509 -noout -subject

The answer changed. Put the name back when you are done.

So the questions are:

  1. nginx has to pick a `server` block **before** it can read the Host header,
     because the certificate is chosen during the handshake. What is the only
     information it has at that point, and what does it do when that
     information matches no `server_name`?

  2. What determines which block is "the default" when nobody has said?
     (`nginx -T` shows you the merged configuration in load order.)

  3. Which directive makes that choice explicit, and what are the options for
     a default block that must not serve anything? Look up
     `ssl_reject_handshake`, and what a client sees when it fires.

Think about the consequences before you fix it. A default vhost that serves a
real site means any name pointed at this IP — including one an attacker
controls, and including your own unconfigured subdomains — gets served that
site's content and that site's certificate.
