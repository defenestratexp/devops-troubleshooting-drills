#!/usr/bin/env bash
# Release deploy. Unpacks a version under releases/ and points current at it.
set -euo pipefail

VER="${1:?usage: deploy.sh VERSION}"
cd "$(dirname "$0")"

echo "deploying $VER"
mkdir releases/"$VER"
cp -r artifacts/"$VER"/. releases/"$VER"/

rm -f current
ln -s releases/"$VER" current

./healthcheck.sh
echo "deployed $VER"
