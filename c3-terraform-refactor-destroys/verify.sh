#!/usr/bin/env bash
# Rebuilds the state that is deployed today from baseline/, then applies the
# refactored root to it. Passes only on a completely empty plan.
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"
command -v terraform >/dev/null || { echo "SKIP - terraform not installed (run ../setup-terraform.sh)"; exit 0; }

rm -rf .work
mkdir -p .work
cp baseline/*.tf .work/

# 1. Establish the pre-refactor state, exactly as it is in production.
( cd .work && terraform init -input=false >/dev/null 2>&1 && \
              terraform apply -auto-approve -input=false >/dev/null 2>&1 ) \
  || { echo "FAIL - could not establish the baseline (baseline/ edited?)"; exit 1; }

before_addrs=$( cd .work && terraform state list | sort )
before_files=$( cd .work && find out -type f -exec md5sum {} \; 2>/dev/null | sort )
n_before=$(wc -l <<<"$before_addrs")
[ "$n_before" -eq 3 ] || { echo "FAIL - baseline produced $n_before resources, expected 3"; exit 1; }

# 2. Swap in the refactored code, keeping the state file.
rm -f .work/*.tf
cp ./*.tf .work/ 2>/dev/null
rm -rf .work/modules && cp -r modules .work/
( cd .work && terraform init -input=false -upgrade >/dev/null 2>&1 ) \
  || { echo "FAIL - terraform init failed on the refactored code"; exit 1; }

# 3. The plan may move resources, but must add/change/destroy nothing.
#    A pending move is itself a state change, so -detailed-exitcode returns 2
#    here even on a correct fix. The add/change/destroy counts are the test.
out=$( cd .work && terraform plan -input=false -no-color 2>&1 )
if grep -q 'Error:' <<<"$out"; then
  echo "FAIL - plan errored:"; grep -A3 'Error:' <<<"$out" | head -8; exit 1
fi
if ! grep -qE 'Plan: 0 to add, 0 to change, 0 to destroy\.|No changes\.' <<<"$out"; then
  echo "FAIL - the plan is not a no-op:"
  grep -E '^Plan:|will be destroyed|will be created|must be replaced' <<<"$out" | head -10
  exit 1
fi

# 4. Applying it must leave the state settled.
( cd .work && terraform apply -auto-approve -input=false >/dev/null 2>&1 ) \
  || { echo "FAIL - apply of the refactored code failed"; exit 1; }
rc_out=$( cd .work && terraform plan -input=false -detailed-exitcode >/dev/null 2>&1; echo $? )
[ "$rc_out" -eq 0 ] || { echo "FAIL - plan still not clean after applying the move (exit $rc_out)"; exit 1; }

# 5. The refactor must actually have happened, not been reverted.
after_addrs=$( cd .work && terraform state list | sort )
if ! grep -q '^module\.service\.' <<<"$after_addrs"; then
  echo "FAIL - nothing is inside module.service; the plan is empty because you undid the refactor"
  echo "$after_addrs"; exit 1
fi
n_after=$(grep -c '^module\.service\.' <<<"$after_addrs")
[ "$n_after" -eq 3 ] || { echo "FAIL - $n_after resources in the module, expected 3"; exit 1; }

# 6. Nothing on disk moved or changed.
after_files=$( cd .work && find out -type f -exec md5sum {} \; 2>/dev/null | sort )
[ "$before_files" = "$after_files" ] \
  || { echo "FAIL - the files on disk changed; the objects were not preserved"; exit 1; }

echo "PASS - empty plan, all 3 resources now under module.service, files untouched"
