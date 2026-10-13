Find it first, so you know what you are removing:

    cd repo
    git log --oneline
    git log -p | grep -n AKIAIOSFODNN7EXAMPLE
    git log --all --full-history -- config.py

    # which commits contain it?
    git rev-list --all | while read -r c; do
      git grep -q AKIAIOSFODNN7EXAMPLE "$c" 2>/dev/null && echo "$c"
    done

Then the questions, in order:

  1. A commit is immutable and its id is a hash of its content. So what does
     "removing" something in a later commit actually do to the earlier one?

  2. If you rewrite history to drop the key, what happens to the **old**
     commits? They are no longer reachable from any branch — are they gone?
     Look up `git reflog`, dangling objects, and what `git gc` does and does
     not do by default. Prove it:

         git cat-file --batch-all-objects --batch-check | head
         git fsck --unreachable

  3. Your repository is a clone. The key is also in the fork someone made, in
     every colleague's local clone, in the CI cache, in the hosting provider's
     web interface for the old commit, and possibly in a pull request diff.
     Which of those can your rewrite reach?

  4. Given the answer to 3 — what is the *only* action that actually ends the
     exposure, and should it happen before or after the cleanup? That is
     `ROTATION.md`.

Tools: `git filter-repo` is the current recommendation; `git filter-branch`
ships with git and is deprecated but works. Either is acceptable. So is doing
it by hand with an interactive rebase if you prefer. The grader checks the
object database, not which tool you used.
