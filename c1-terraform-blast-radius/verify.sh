#!/usr/bin/env bash
cd "$(dirname "$0")"
command -v terraform >/dev/null || { echo "SKIP - terraform not installed"; exit 0; }
grep -q "for_each" main.tf || { echo "FAIL - still index-addressed (no for_each)"; exit 1; }
rm -rf out .terraform terraform.tfstate* 2>/dev/null
terraform init -input=false >/dev/null 2>&1
terraform apply -auto-approve -input=false >/dev/null 2>&1 || { echo "FAIL - apply failed"; exit 1; }
before=$(terraform state list | wc -l)
sed -i 's/"alpha", "beta", "gamma", "delta"/"alpha", "gamma", "delta"/' variables.tf
out=$(terraform plan -input=false -no-color 2>&1)
sed -i 's/"alpha", "gamma", "delta"/"alpha", "beta", "gamma", "delta"/' variables.tf
destroy=$(grep -cE '^  # .* will be destroyed' <<<"$out")
replace=$(grep -cE 'must be replaced' <<<"$out")
if [ "$destroy" -eq 1 ] && [ "$replace" -eq 0 ]; then
  echo "PASS - exactly 1 destroy, 0 replacements (was $before resources)"; exit 0
fi
echo "FAIL - plan wants $destroy destroy(s) and $replace replacement(s); expected 1 and 0"
exit 1
