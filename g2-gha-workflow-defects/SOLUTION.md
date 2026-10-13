# Solution: GitHub Actions: review this workflow before it ships

> Stop. Have you run `./verify.sh`?

## Defect 1 (critical) — `pull_request_target` checking out the PR head

    on:
      pull_request_target:
    ...
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}

This is remote code execution by anyone with a GitHub account, and it is worth
being able to explain precisely, because the two triggers differ in exactly one
way that matters.

- `pull_request` runs the workflow **as defined in the base branch**, in a
  context with a read-only token and **no secrets** for fork PRs. Safe by
  design: a fork's code runs, but with no privileges.
- `pull_request_target` runs the workflow definition from the base branch too,
  but in the context of the **base** repository: full `secrets`, and a token
  with write access. It exists for workflows that need to label or comment on
  untrusted PRs without running their code.

The `ref:` line then checks out the fork's code into that privileged context.
`npm ci` runs the fork's `package.json` — and `preinstall`/`postinstall`
scripts are arbitrary commands. So a stranger opens a PR containing a
`postinstall` that prints `$AWS_SECRET_ACCESS_KEY` to the log or posts it to
their own server, and your production credentials leave the building. They do
not need the PR to be approved, reviewed, or merged. Opening it is enough.

Fix: use `pull_request` and check out the default ref.

    on:
      pull_request:
        types: [opened, synchronize]
    ...
      - uses: actions/checkout@v4

If you genuinely need `pull_request_target` — to label PRs, say — then never
check out untrusted code in it, and split the job: a `pull_request` job that
builds, and a separate privileged job that consumes only inert artifacts.
GitHub's own guidance is blunt about this, and it has been exploited in the
wild repeatedly.

This is the defect that "looks like a helpful feature": whoever wrote it added
`ref:` to make CI test the PR's actual code, which is a completely reasonable
thing to want.

## Defect 2 — no `permissions:` block

With no `permissions:` key, `GITHUB_TOKEN` gets the repository or organisation
default, which on older repositories is read **and write** to everything:
contents, packages, issues, deployments. Any compromised dependency in the
install step inherits that.

Fix — declare least privilege at the workflow level and widen per job only
where needed:

    permissions:
      contents: read

Say the general rule out loud in an interview: default deny, widen at the
narrowest scope, and prefer an OIDC role over long-lived cloud keys — those
`AWS_ACCESS_KEY_ID` secrets should be
`permissions: id-token: write` plus `aws-actions/configure-aws-credentials`
assuming a role, so there is no static key to steal in the first place.

## Defect 3 — a cache key that can never change

    key: node-modules

A constant key means the first cache saved under it is the cache every
subsequent run restores, for the life of the repository. Bump a dependency and
the lockfile changes, but the cache does not, so CI keeps installing the old
tree. The failure mode is worse than a stale cache: `npm ci` restores
`node_modules` from the cache and tests pass against versions that no longer
match the lockfile — so CI is green for an artifact that does not match what
production will install.

Fix — the key must be a function of the inputs:

    key: node-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

`hashFiles` over the lockfile is the standard idiom. Include `runner.os`
because a cache built on one runner image is not valid on another.

## Defect 4 — no concurrency group on the deploy

Two merges to `main` ninety seconds apart start two deploy jobs. Nothing
orders them. The older one can finish last, so `main` ends up running the
previous commit, and the dashboard says both deploys succeeded. This is
genuinely hard to debug after the fact, because the logs are both green.

Fix:

    deploy:
      concurrency:
        group: deploy-production
        cancel-in-progress: false

Note the two different settings for the two different jobs, and that the choice
is not cosmetic:

- For **CI** on a branch, `cancel-in-progress: true` — superseded test runs are
  waste.
- For a **deploy**, `cancel-in-progress: false` — cancelling a deploy halfway
  leaves a half-deployed system, which is worse than a slow queue.

## Defect 5 — `npm install` instead of `npm ci`

`npm install` is allowed to resolve versions the lockfile does not name, and
will rewrite `package-lock.json` to match what it chose. In CI that means the
tested tree is not necessarily the locked tree, and two runs of the same commit
can install different code.

`npm ci` installs exactly the lockfile, fails if `package.json` and the
lockfile disagree, and deletes `node_modules` first. The equivalents are worth
knowing by name: `pip install -r requirements.txt --require-hashes`,
`bundle install --deployment`, `yarn install --immutable`,
`terraform init -lockfile=readonly`.

## Worth mentioning in review, not required here

- **Pin actions to a commit SHA**, not a tag: `actions/checkout@v4` is a
  moving pointer and a compromised tag is a supply-chain attack on everyone
  using it. `actions/checkout@8f4b7f8…` with the version in a trailing comment
  is the hardened form, and Dependabot can bump it.
- **A GitHub Environment** on the deploy job gives you required reviewers and
  scoped secrets — so production credentials are not visible to every workflow
  in the repository.
- `if: github.ref == 'refs/heads/main'` on the deploy job is correct and worth
  keeping, but it is a convenience, not a security control: it is evaluated by
  the same workflow it is protecting.
