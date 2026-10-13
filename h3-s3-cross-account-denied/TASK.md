Write your answers in `ANSWERS.md` before reading `SOLUTION.md`.

1. **The rule.** For a cross-account S3 read, which policies must allow the
   call, and in which accounts do they live? State the rule precisely enough
   that it tells you how many separate documents have to say yes.

2. **Defect one.** The object is encrypted with SSE-KMS using a CMK in account
   A. Read `policies/kms-key-policy-account-A.json` and say what is missing,
   which API call fails, and what error the caller sees. Write the statement
   you would add.

3. **Defect two.** Look at the `get-object-acl` output in `bucket-facts.md` and
   say who owns `orders.csv`. Then explain why account A's bucket policy cannot
   grant account B access to that object, and why account A's own
   administrator cannot read it either. Name the bucket setting that causes
   this and the setting that fixes it permanently.

4. **Defect three.** Even with the above fixed, the reader in account B needs
   something in its *own* account that it does not have today. What, and why is
   the bucket policy not enough?

5. **Why does listing work when reading does not?** Say which permission each
   operation needs, on which resource ARN, and what that tells you about where
   the failure is.

6. **The diagnostic.** Name the one thing you would look at to tell a
   KMS-caused `AccessDenied` from an S3-caused one without changing anything.
