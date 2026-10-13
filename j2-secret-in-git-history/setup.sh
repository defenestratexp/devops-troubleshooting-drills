#!/usr/bin/env bash
# Builds the fixture repository under repo/. Six commits; an AWS key is
# committed in commit 3, used in 4, and "removed" in 5.
#
# The key is AWS's own documented example key pair, so it is a recognisable
# shape that has never been valid anywhere.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf repo
mkdir repo
cd repo

git init -q
git config user.name  "Drill Fixture"
git config user.email "fixture@n9n.test"
git config commit.gpgsign false

cat > importer.py <<'EOF'
"""Pulls the nightly order feed."""


def fetch(path):
    with open(path) as fh:
        return fh.read().splitlines()
EOF
git add -A
git commit -q -m "initial order importer"

cat > uploader.py <<'EOF'
"""Uploads processed feeds to S3."""


def upload(rows):
    raise NotImplementedError
EOF
git add -A
git commit -q -m "stub out the S3 uploader"

cat > config.py <<'EOF'
# S3 credentials for the feeds bucket.
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
AWS_REGION = "us-east-1"
BUCKET = "n9n-feeds"
EOF
git add -A
git commit -q -m "add S3 credentials so the importer can upload"

cat > uploader.py <<'EOF'
"""Uploads processed feeds to S3."""
import config


def upload(rows):
    print("would upload %d rows to %s as %s"
          % (len(rows), config.BUCKET, config.AWS_ACCESS_KEY_ID))
EOF
git add -A
git commit -q -m "wire the uploader up to the credentials"

cat > config.py <<'EOF'
"""S3 configuration. Credentials come from the environment."""
import os

AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
BUCKET = "n9n-feeds"
EOF
git add -A
git commit -q -m "read credentials from the environment, not from the repo"

cat >> uploader.py <<'EOF'


def upload_with_retry(rows, attempts=3):
    for attempt in range(attempts):
        try:
            return upload(rows)
        except Exception:
            if attempt == attempts - 1:
                raise
EOF
git add -A
git commit -q -m "retry failed uploads"

echo "fixture repo/ built:"
git log --oneline | sed 's/^/  /'
