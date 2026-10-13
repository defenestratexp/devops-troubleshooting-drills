"""Grades the fixed workflow by inspecting it, not by running it.

Checks properties rather than exact text, so there is more than one way to
pass -- but each check is specific about which defect it is looking for.
"""
import sys

try:
    import yaml
except ImportError:
    print("SKIP - python3 PyYAML not installed (apt install python3-yaml)")
    sys.exit(0)

PATH = ".github/workflows/ci.yml"

try:
    with open(PATH) as fh:
        wf = yaml.safe_load(fh)
except FileNotFoundError:
    print("FAIL - %s is missing" % PATH)
    sys.exit(1)
except yaml.YAMLError as exc:
    print("FAIL - %s is not valid YAML: %s" % (PATH, exc))
    sys.exit(1)

if not isinstance(wf, dict):
    print("FAIL - %s did not parse to a mapping" % PATH)
    sys.exit(1)

problems = []
jobs = wf.get("jobs") or {}

# PyYAML resolves a bare `on:` to the boolean True (the YAML 1.1 truthy set),
# which is why `wf["on"]` is not reliable here.
triggers = wf.get("on", wf.get(True)) or {}
trigger_names = set(triggers) if isinstance(triggers, (dict, list)) else {triggers}


def steps_of(job):
    return [s for s in (job.get("steps") or []) if isinstance(s, dict)]


def all_steps():
    for name, job in jobs.items():
        if isinstance(job, dict):
            for step in steps_of(job):
                yield name, step


def text_of(step):
    return "%s %s %s" % (step.get("uses", ""), step.get("run", ""), step.get("with", ""))


# ---- 1. untrusted code in a privileged trigger -----------------------------
checkouts_head = [
    (j, s) for j, s in all_steps()
    if "checkout" in str(s.get("uses", ""))
    and "pull_request.head" in str((s.get("with") or {}).get("ref", ""))
]
if "pull_request_target" in trigger_names and checkouts_head:
    problems.append(
        "pull_request_target still checks out the PR head ref -- any fork can "
        "run code with your secrets")
if "pull_request_target" not in trigger_names and "pull_request" not in trigger_names:
    problems.append("the workflow no longer runs on pull requests at all")

# ---- 2. least privilege for GITHUB_TOKEN -----------------------------------
wf_perms = wf.get("permissions")
job_perms = {n: j.get("permissions") for n, j in jobs.items() if isinstance(j, dict)}
if wf_perms is None and any(p is None for p in job_perms.values()):
    problems.append("no permissions: block, so GITHUB_TOKEN keeps the repository default")
for scope, val in list((wf_perms or {}).items() if isinstance(wf_perms, dict) else []):
    if scope == "contents" and val not in ("read", "none"):
        problems.append("workflow-level contents permission is '%s', not read" % val)
if wf_perms == "write-all" or any(p == "write-all" for p in job_perms.values()):
    problems.append("permissions: write-all is not least privilege")

# ---- 3. a cache key that can never change ----------------------------------
cache_steps = [(j, s) for j, s in all_steps() if "actions/cache" in str(s.get("uses", ""))]
for job_name, step in cache_steps:
    key = str((step.get("with") or {}).get("key", ""))
    if "hashFiles(" not in key:
        problems.append(
            "the cache key in job '%s' is %r -- nothing in it changes when a "
            "dependency changes" % (job_name, key))

# ---- 4. racing deploys -----------------------------------------------------
# Resolved once and asserted non-empty: an earlier version fell back to a
# literal "deploy" that no longer existed, so deleting the deploy job skipped
# every check below and the cheat passed.
deploy_jobs = [n for n in jobs if "deploy" in n.lower()]
if not deploy_jobs:
    problems.append("there is no deploy job; it must still deploy on main")
has_wf_conc = isinstance(wf.get("concurrency"), (dict, str))
for name in deploy_jobs:
    job = jobs.get(name)
    if not isinstance(job, dict):
        continue
    if not has_wf_conc and not isinstance(job.get("concurrency"), (dict, str)):
        problems.append(
            "job '%s' has no concurrency group, so two merges can deploy out of order"
            % name)

# ---- 5. reproducible installs ----------------------------------------------
runs = " ".join(str(s.get("run", "")) for _, s in all_steps())
if "npm install" in runs or "npm ci" not in runs:
    problems.append(
        "the install step does not use npm ci -- npm install may resolve "
        "versions the lockfile does not name")

# ---- the workflow must still do its job ------------------------------------
if not jobs:
    problems.append("the workflow has no jobs")
if "npm test" not in runs:
    problems.append("the tests are no longer run")
if not any("upload-coverage" in str(s.get("run", "")) for _, s in all_steps()):
    problems.append("the coverage upload is gone")
for name in deploy_jobs:
    job = jobs.get(name)
    if isinstance(job, dict):
        needs = job.get("needs")
        needs = [needs] if isinstance(needs, str) else (needs or [])
        if "test" not in needs:
            problems.append("job '%s' no longer waits for the tests" % name)
if "push" not in trigger_names:
    problems.append("the workflow no longer runs on push to main")

if problems:
    print("FAIL - %d problem(s):" % len(problems))
    for p in problems:
        print("  - %s" % p)
    sys.exit(1)

print("PASS - all five defects fixed and the workflow still does its job")
