#!/usr/bin/env bash
# Grades behaviour, not a particular fix: the plan must settle, the node
# address must survive an apply, and the build stamp must stop moving.
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"
command -v terraform >/dev/null || { echo "SKIP - terraform not installed (run ../setup-terraform.sh)"; exit 0; }

rm -rf out .terraform terraform.tfstate* 2>/dev/null
terraform init -input=false >/dev/null 2>&1 || { echo "FAIL - terraform init failed"; exit 1; }
terraform apply -auto-approve -input=false >/dev/null 2>&1 || { echo "FAIL - first apply failed"; exit 1; }

stamp_before=$(find out -name build.json -exec md5sum {} \; 2>/dev/null | cut -d' ' -f1)

# A clean plan, an apply, then clean again. Twice, because a resource that is
# dropped from state on read looks clean exactly once.
terraform plan -input=false -detailed-exitcode >/dev/null 2>&1
rc=$?
[ "$rc" -eq 1 ] && { echo "FAIL - plan errored"; exit 1; }
[ "$rc" -eq 2 ] && { echo "FAIL - plan still wants changes immediately after apply"; exit 1; }

terraform apply -auto-approve -input=false >/dev/null 2>&1 || { echo "FAIL - second apply failed"; exit 1; }
terraform plan -input=false -detailed-exitcode >/dev/null 2>&1
rc=$?
[ "$rc" -eq 2 ] && { echo "FAIL - plan clean once but not after a second apply"; exit 1; }
[ "$rc" -eq 1 ] && { echo "FAIL - plan errored on the second pass"; exit 1; }

# Behaviour that must survive the fix.
grep -rq 'address=127.0.0.1' out/ 2>/dev/null \
  || { echo "FAIL - the [node] address is gone; you removed the requirement instead of fixing it"; exit 1; }
grep -rq '\[node\]' out/ 2>/dev/null \
  || { echo "FAIL - no [node] section anywhere under out/"; exit 1; }
grep -q "service=${TF_VAR_service:-api}" out/app.conf 2>/dev/null \
  || { echo "FAIL - out/app.conf no longer carries the service name"; exit 1; }

stamp_after=$(find out -name build.json -exec md5sum {} \; 2>/dev/null | cut -d' ' -f1)
[ -n "$stamp_after" ] || { echo "FAIL - out/build.json is gone; keep the stamp, just make it stable"; exit 1; }
[ "$stamp_before" = "$stamp_after" ] \
  || { echo "FAIL - the build stamp still changes on every apply"; exit 1; }

n=$(terraform state list | wc -l)
[ "$n" -ge 2 ] || { echo "FAIL - only $n resource(s) in state; you deleted the problem"; exit 1; }

echo "PASS - plan settles across two applies, node address intact, stamp stable ($n resources)"
