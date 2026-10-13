# Solution: Git: the key was removed four months ago

> Stop. Have you run `./verify.sh`?

## Why both people were right

A commit is immutable, and its id is a hash of its content. Commit 5 did not
edit commit 3 — it could not. It added a *new* commit whose tree happens not to
contain the key. Commit 3 is still there, still contains the key, and
`git show 5e760d6:config.py` prints it.

So "we removed it" is true of the working tree and meaningless as a security
statement. `grep -r` across a checkout only ever sees one commit.

## Step 1 — rewrite the history

`git filter-repo` is the current recommendation (it is not bundled; install it
separately):

    git filter-repo --replace-text <(echo 'AKIAIOSFODNN7EXAMPLE==>REDACTED')

With only bundled git, `filter-branch` does the same job and warns you that it
is deprecated:

    FILTER_BRANCH_SQUELCH_WARNING=1 \
    git filter-branch -f --tree-filter '
      if [ -f config.py ]; then
        sed -i "s/AKIAIOSFODNN7EXAMPLE/REDACTED/" config.py
      fi' -- --all

Removing the value rather than the whole file keeps the other commits intact,
which is why the rewrite here preserves all six. `--path config.py
--invert-paths` would delete the file from history entirely and prune the
commit that only added it.

Note that every commit id from the first rewritten commit onwards changes.
Everyone with a clone has to re-clone or reset onto the new history; open pull
requests and any tags pointing at old commits break. That cost is why this is
a decision, not a reflex.

## Step 2 — the rewrite does not delete anything

This is the part the grader is really testing, and it catches two separate
hiding places.

**`refs/original/`.** `filter-branch` helpfully keeps your old branch under
`refs/original/refs/heads/<branch>`. That is a ref, so the entire pre-rewrite
history is still reachable — `git log --all` still shows the key.

    git for-each-ref --format='%(refname)' refs/original | xargs -n1 git update-ref -d

**Unreachable objects.** With the refs gone, the old commits and blobs are
unreachable but *not removed*. They sit in the object database until something
prunes them, and anyone who knows or logs an old commit id can still read it —
which on a hosting provider includes the web UI, the API and any cached PR
diff.

    git reflog expire --expire=now --all
    git gc --prune=now

Prove it before and after:

    git fsck --unreachable
    git cat-file --batch-all-objects --batch-check

Plain `git gc` will not do it: unreachable objects get a two-week grace period
(`gc.pruneExpire`) specifically so that an accidental reset is recoverable.
That grace period is a feature, and here it is a two-week window in which the
secret is still readable.

## Step 3 — the only thing that actually matters

Rewriting your clone's history does not reach:

- the fork someone made last month
- every colleague's local clone, and their reflogs
- the CI runner's cache and any build logs that printed the config
- the hosting provider's own copy: old commits often remain accessible by id
  via the web UI and API even after a force-push, until support garbage
  collects them
- any secret scanner, SIEM or chat integration that has already ingested it
- whoever found it before you did

So the honest conclusion is: **the key must be treated as compromised, and
rotated.** Deactivate it, confirm in CloudTrail that nothing is still calling
with it, then delete it and issue a new one.

And the order matters. **Rotate first, clean up second.** Rotation takes
minutes and ends the exposure; a history rewrite takes a coordination effort
across everyone with a clone and ends nothing. Doing the cleanup first means
spending your fastest hour on the part that does not help, while a live
credential is in a public place.

That is what `ROTATION.md` is for, and it is why requirement 3 is the one that
matters most. In a real interview, an answer that purges the history and does
not mention rotation is a failed answer, however good the git is.

## Preventing the next one

- **A pre-commit hook or server-side scanner.** `gitleaks`, `trufflehog`, or
  GitHub/GitLab push protection, which rejects the push rather than reporting
  it afterwards. Rejecting is categorically better: nothing to rewrite.
- **Nothing secret in the repository, ever** — not even encrypted, unless you
  have chosen that deliberately (SOPS, `git-crypt`, sealed secrets). The
  default should be that credentials come from a secret manager at runtime.
- **Make the right thing easy.** The key got committed because
  `config.py` was the obvious place to put it and the environment-variable
  version was more work. A `.env.example` and a one-line loader in the
  repository from day one removes that pressure.
- **Scan the whole history once**, not just new commits. Every repository that
  predates the scanner has its own commit 3.
