"""IAM policy evaluation, reduced to the part that decides these requests.

This is the grader, and it is meant to be read. The whole algorithm is
`evaluate()`; everything else is matching and printing.

Scope, stated honestly: Effect, Action/NotAction, Resource/NotResource, and
IAM's `*` and `?` wildcards. No conditions, no resource-based policies, no
permission boundaries, no SCPs, no session policies. Action matching is
case-insensitive (IAM's own behaviour); resource matching is not.
"""
import glob
import json
import os
import re
import sys

EXPLICIT_DENY = "Deny (explicit)"
IMPLICIT_DENY = "Deny (implicit)"
ALLOW = "Allow"


def as_list(value):
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def wildcard_match(pattern, value, fold=False):
    """IAM wildcards: * is any sequence, ? is exactly one character."""
    rx = "^" + re.escape(pattern).replace(r"\*", ".*").replace(r"\?", ".") + "$"
    return re.match(rx, value, re.IGNORECASE if fold else 0) is not None


def statement_applies(stmt, action, resource):
    """Does this statement have anything to say about this request?

    A statement must constrain the action somehow and the resource somehow.
    NotAction/NotResource invert the test: the statement applies to everything
    the listed patterns do NOT match.
    """
    actions = as_list(stmt.get("Action"))
    not_actions = as_list(stmt.get("NotAction"))
    resources = as_list(stmt.get("Resource"))
    not_resources = as_list(stmt.get("NotResource"))

    if not actions and not not_actions:
        return False
    if not resources and not not_resources:
        return False

    if actions and not any(wildcard_match(p, action, fold=True) for p in actions):
        return False
    if not_actions and any(wildcard_match(p, action, fold=True) for p in not_actions):
        return False
    if resources and not any(wildcard_match(p, resource) for p in resources):
        return False
    if not_resources and any(wildcard_match(p, resource) for p in not_resources):
        return False
    return True


def evaluate(policies, action, resource):
    """Default deny; an explicit Deny anywhere wins; otherwise any Allow wins."""
    verdict = IMPLICIT_DENY
    reason = "no statement allows it"
    for name, policy in policies:
        for stmt in as_list(policy.get("Statement")):
            if not statement_applies(stmt, action, resource):
                continue
            sid = stmt.get("Sid", "<no Sid>")
            if stmt.get("Effect") == "Deny":
                # Deny wins regardless of what else matched, so stop here.
                return EXPLICIT_DENY, "%s/%s" % (name, sid)
            verdict = ALLOW
            reason = "%s/%s" % (name, sid)
    return verdict, reason


def load_policies(directory="policies"):
    out = []
    for path in sorted(glob.glob(os.path.join(directory, "*.json"))):
        with open(path) as fh:
            out.append((os.path.basename(path), json.load(fh)))
    return out


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    os.chdir(here)

    try:
        policies = load_policies()
    except json.JSONDecodeError as exc:
        print("FAIL - a policy in policies/ is not valid JSON: %s" % exc)
        return 1
    if not policies:
        print("FAIL - no policy documents found in policies/")
        return 1

    with open("requests.json") as fh:
        requests = json.load(fh)

    wrong = 0
    for req in requests:
        verdict, reason = evaluate(policies, req["action"], req["resource"])
        got = ALLOW if verdict == ALLOW else "Deny"
        ok = got == req["expect"]
        if not ok:
            wrong += 1
        print("%-5s want %-5s got %-15s  %s %s" % (
            "ok" if ok else "WRONG",
            req["expect"],
            verdict,
            req["action"],
            req["resource"],
        ))
        if not ok:
            print("       %s" % req["why"])
            print("       decided by: %s" % reason)

    print()
    if wrong:
        print("FAIL - %d of %d requests resolve incorrectly" % (wrong, len(requests)))
        return 1
    print("PASS - all %d requests resolve as required" % len(requests))
    return 0


if __name__ == "__main__":
    sys.exit(main())
