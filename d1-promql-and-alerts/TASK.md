Write your answers in ANSWERS.md before reading SOLUTION.md.

For each of the three rules: what is the defect, what is the corrected
expression, and what would the user have experienced?

Then write PromQL for:

  A. The availability SLI for service "api" as a ratio over 30 days, where
     "good" means any response that is not 5xx. Assume the counter
     http_requests_total{service="api", status="..."}.

  B. A fast-burn alert expression for a 99.9% availability objective: fire when
     the error budget is being consumed at 14.4x over a 1-hour window AND at the
     same rate over a 5-minute window.

  C. State the 30-day error budget for 99.9% in MINUTES, and show the arithmetic.
