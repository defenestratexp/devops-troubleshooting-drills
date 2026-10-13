Run it and read the three wrong verdicts. The evaluator tells you which
statement decided each one, which is most of the diagnosis.

Then, for each wrong verdict, the question that cracks it:

  **The deleted artifact.** Which statement allows `s3:DeleteObject`? Nobody
  wrote `s3:DeleteObject` anywhere. What does `s3:*` expand to, and what does
  `arn:aws:s3:::n9n-*/*` match?

  **The customer data read.** `NoCustomerData` was written to stop exactly
  this. Work through `statement_applies()` by hand for this request: the
  statement says `NotAction: s3:GetObject`, and the request *is*
  `s3:GetObject`. Does the statement apply? Say out loud what `NotAction`
  means — it is not "deny this action".

  **The production password.** What does `n9n/*` match? List three secret
  names it matches that are not deploy secrets.

A thing to notice while you are in there: `s3:ListBucket` is allowed on
`arn:aws:s3:::n9n-artifacts`, but `s3:GetObject` is allowed by a different
statement. Why would the first one *not* work on
`arn:aws:s3:::n9n-artifacts/*`? Once you remove the over-broad statement you
will need the answer, because two of the passing requests will start failing.

Pass condition: all ten requests resolve as `requests.json` requires.
