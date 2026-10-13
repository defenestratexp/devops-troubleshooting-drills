#!/usr/bin/env bash
# Scans every object in the repository's object database, not just what is
# reachable from a branch -- an unreachable commit is still readable by anyone
# who knows or can guess its id, and `git log` will not show it to you.
cd "$(dirname "$0")"
command -v git >/dev/null || { echo "SKIP - git not installed"; exit 0; }

KEY='AKIAIOSFODNN7EXAMPLE'
SECRET='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'

[ -d repo/.git ] || ./setup.sh >/dev/null 2>&1
[ -d repo/.git ] || { echo "FAIL - ./setup.sh did not build repo/"; exit 1; }

fails=0
note() { echo "FAIL - $1"; fails=$((fails+1)); }

# --- 1. the key must not be in ANY object ----------------------------------
found=""
while read -r oid type _; do
  [ "$type" = "blob" ] || continue
  if git -C repo cat-file blob "$oid" 2>/dev/null | grep -qF -e "$KEY" -e "$SECRET"; then
    found="$oid"; break
  fi
done < <(git -C repo cat-file --batch-all-objects --batch-check 2>/dev/null)

if [ -n "$found" ]; then
  note "the key is still readable from object $found"
  reachable=$(git -C repo log --all --format=%H 2>/dev/null \
    | while read -r c; do
        git -C repo grep -qF "$KEY" "$c" 2>/dev/null && { echo reachable; break; }
      done)
  if [ -n "$reachable" ]; then
    echo "        it is still reachable from a branch -- the history was not rewritten"
  else
    echo "        it is unreachable but not pruned: try"
    echo "          git reflog expire --expire=now --all && git gc --prune=now"
  fi
fi

# --- 2. the repository must still be a working repository -------------------
for f in config.py importer.py uploader.py; do
  git -C repo cat-file -e "HEAD:$f" 2>/dev/null || note "repo/$f is missing at HEAD"
done
git -C repo show HEAD:config.py 2>/dev/null | grep -q 'os.environ' \
  || note "repo/config.py at HEAD no longer reads credentials from the environment"
git -C repo show HEAD:uploader.py 2>/dev/null | grep -q 'upload_with_retry' \
  || note "the retry logic from the last commit is gone"

n=$(git -C repo rev-list --count HEAD 2>/dev/null || echo 0)
[ "${n:-0}" -ge 4 ] \
  || note "HEAD has only $n commit(s); rewrite the history, do not discard it"

# --- 3. the part that actually ends the exposure ---------------------------
if [ ! -f ROTATION.md ]; then
  note "ROTATION.md is missing -- see requirement 3 in the README"
else
  grep -qiE 'rotat|revok|deactivat|disable|delete the key|new (access )?key' ROTATION.md \
    || note "ROTATION.md does not say to rotate or revoke the key"
  grep -qiE 'before|first|immediately|straight away|then clean|prior' ROTATION.md \
    || note "ROTATION.md does not say when to rotate relative to the cleanup"
fi

[ "$fails" -eq 0 ] && { echo "PASS - the key is in no object, the repository still works ($n commits), and ROTATION.md is written"; exit 0; }
echo "-- $fails problem(s) remaining"
exit 1
