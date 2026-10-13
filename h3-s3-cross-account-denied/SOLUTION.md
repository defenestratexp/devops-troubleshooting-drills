# Solution: S3: cross-account read denied, and the bucket policy allows it

> Stop. Have you run `./verify.sh`?

## 1. The rule

For a cross-account call, **both** sides must allow it:

- the **identity policy** in the *calling* account (B) must allow the action on
  the resource, and
- the **resource policy** in the *owning* account (A) must allow the calling
  principal.

Neither one alone is sufficient, and an explicit `Deny` in either kills it.
Within a single account, a resource policy alone or an identity policy alone is
enough — which is exactly why cross-account surprises people who have only ever
done same-account work.

Then add the layers that can independently say no: an SCP in either
organisation, a permission boundary on the role, a VPC endpoint policy if the
call goes through one, and — for an encrypted object — the **KMS key policy**,
which is a separate resource policy on a separate service.

So the honest answer to "how many documents have to say yes" here is four: B's
identity policy, A's bucket policy, A's key policy, and B's identity policy
again for the KMS action.

## 2. Defect one — the key policy does not allow the reader to decrypt

`GetObject` on an SSE-KMS object makes S3 call `kms:Decrypt` on the caller's
behalf, **as the caller**. The key policy has statements for account A's root
and for `DataProducer` (encrypt only). Nothing allows account B anything, so
the decrypt is denied and S3 surfaces it as `AccessDenied` on `GetObject` —
which is why everyone stares at the bucket policy.

Add to the key policy:

    {
      "Sid": "AllowPartnerDecrypt",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::444455556666:role/PartnerReader" },
      "Action": ["kms:Decrypt", "kms:DescribeKey"],
      "Resource": "*"
    }

`Resource: "*"` in a key policy means "this key" — a key policy is attached to
the key, so there is nothing else it could mean.

Note the asymmetry worth remembering: **reading** an SSE-KMS object needs
`kms:Decrypt`; **writing** one needs `kms:GenerateDataKey` (and usually
`kms:Encrypt`). A role that can only `Decrypt` can read and not write, which is
often what you want for a partner.

## 3. Defect two — the objects are not owned by the bucket owner

    get-object-acl → Owner ID 9e1f... (account 777788889999, the vendor)

With `ObjectOwnership: ObjectWriter`, whoever uploads an object **owns** it.
The vendor uploads with a plain `aws s3 cp`, so every object in the feed is
owned by account `777788889999`, not by account A.

The consequence is the one that sounds wrong until you have hit it: a bucket
policy grants permissions over resources the bucket owner controls, and the
bucket owner does not control the ACL of an object it does not own. So:

- A's bucket policy cannot grant B access to those objects.
- **A's own administrator cannot read them either** — and that is the
  diagnostic that proves this is what is happening. Have account A's admin try
  `get-object`. If the bucket owner is denied its own object, ownership is the
  problem, and no amount of editing the bucket policy will help.

Two fixes, and the difference matters:

- *Per upload, by the writer:* `aws s3 cp --acl bucket-owner-full-control`.
  Works, but depends on the vendor remembering it on every upload, forever, and
  does nothing for the objects already there.
- *Permanently, by the bucket owner:* set Object Ownership to
  **`BucketOwnerEnforced`**. ACLs are disabled entirely, every object is owned
  by the bucket owner regardless of who writes it, and access is decided purely
  by policy. This is the modern default for new buckets and the right answer.

Existing objects keep their ownership, so after flipping the setting the
already-uploaded files still need a rewrite — a server-side copy over
themselves (`aws s3 cp s3://b/k s3://b/k --metadata-directive COPY`) re-creates
them under the new ownership.

## 4. Defect three — account B's role has no KMS permission of its own

The key policy allowing B is necessary and not sufficient. Because this is
cross-account, B's **identity** policy must also allow `kms:Decrypt` on that
key ARN — the same two-sided rule as in part 1, applied to KMS instead of S3.
The role's policy today mentions only S3.

    {
      "Effect": "Allow",
      "Action": ["kms:Decrypt", "kms:DescribeKey"],
      "Resource": "arn:aws:kms:us-east-1:111122223333:key/8f3c1b2a-..."
    }

Cross-account access is never grantable by one side alone. The owner offers;
the consumer must accept, in its own policy.

## 5. Why listing works and reading does not

They are different permissions on **different resource ARNs**:

| Operation | Permission | Resource |
| --- | --- | --- |
| `aws s3 ls` | `s3:ListBucket` | `arn:aws:s3:::n9n-data-exchange` (the bucket) |
| `aws s3 cp` | `s3:GetObject` | `arn:aws:s3:::n9n-data-exchange/*` (the objects) |

`ListBucket` returns metadata held by the bucket, which account A does own and
can therefore grant, and it never touches KMS or the object ACL. So it
succeeds while every read fails — and that split is itself the clue: the
failure is at the object layer, not at the bucket or principal layer.

Worth knowing the related behaviour: without `s3:ListBucket`, a `GetObject` for
a key that does not exist returns **403**, not 404, because S3 will not confirm
or deny the existence of an object you have no permission to list. With
`ListBucket`, you get a 404. So "403 on a key I am sure is missing" usually
means missing `ListBucket` rather than a missing object.

## 6. The diagnostic

**CloudTrail.** A KMS-caused denial appears as a separate `Decrypt` event from
`kms.amazonaws.com` with an `errorCode` of `AccessDenied`, naming the key and
the principal — and the S3 `GetObject` event is there too. Which service
recorded the denial is the whole answer, and it takes thirty seconds.

Two cheaper checks that need no log access:

- **Have the bucket owner read the object.** If account A's admin is denied,
  it is object ownership.
- **Put an unencrypted object in the bucket and read that.** If it reads fine,
  the problem is KMS, not S3.

## The habit

When a cross-account call is denied, enumerate the documents that have to agree
before editing any of them:

    caller's identity policy
    resource policy on the thing
    resource policy on the KEY, if encrypted
    caller's identity policy for the KMS action
    SCPs on both accounts
    permission boundary on the role
    object ownership, for S3 specifically

"The bucket policy allows it" is one of seven. The reason this takes teams days
is that each person checks the one they own, finds it correct, and reports back
that it is not their problem — and all of them are right.
