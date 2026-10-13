#!/usr/bin/env bash
# The whole point is the FIRST apply on a clean tree, so this wipes everything
# before it starts. Then checks idempotence, because a fix that re-runs the
# build step forever is not a fix.
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"
command -v terraform >/dev/null || { echo "SKIP - terraform not installed (run ../setup-terraform.sh)"; exit 0; }

rm -rf out .terraform terraform.tfstate* 2>/dev/null
terraform init -input=false >/dev/null 2>&1 || { echo "FAIL - terraform init failed"; exit 1; }

err=$(terraform apply -auto-approve -input=false -no-color 2>&1)
if [ $? -ne 0 ]; then
  echo "FAIL - the first apply on a clean tree still fails:"
  grep -A2 'Error:' <<<"$err" | head -8
  exit 1
fi

[ -f out/version.txt ]   || { echo "FAIL - out/version.txt was never produced"; exit 1; }
[ -f out/manifest.json ] || { echo "FAIL - out/manifest.json was never produced"; exit 1; }

want=$(tr -d '[:space:]' < out/version.txt)
got=$(python3 -c 'import json,sys; print(json.load(open("out/manifest.json"))["release"])' 2>/dev/null | tr -d '[:space:]')
[ -n "$want" ] || { echo "FAIL - out/version.txt is empty"; exit 1; }
[ "$want" = "$got" ] \
  || { echo "FAIL - manifest says '$got' but the build step produced '$want'"; exit 1; }

# A dependency fixed with a trigger that fires every time is not fixed.
terraform apply -auto-approve -input=false >/dev/null 2>&1 || { echo "FAIL - second apply failed"; exit 1; }
terraform plan -input=false -detailed-exitcode >/dev/null 2>&1
rc=$?
[ "$rc" -eq 2 ] && { echo "FAIL - apply is not idempotent; the plan still wants changes"; exit 1; }
[ "$rc" -eq 1 ] && { echo "FAIL - plan errored"; exit 1; }

echo "PASS - clean-tree apply succeeded first time, manifest matches ($want), apply is idempotent"
