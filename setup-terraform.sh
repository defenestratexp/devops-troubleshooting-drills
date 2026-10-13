#!/usr/bin/env bash
# Terraform into ~/.local/bin for the c* exercises. Nothing here touches the
# real terraform docker environment or any cloud credentials - the exercises
# use the local provider and write files under the exercise directory.
set -u
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
if command -v terraform >/dev/null; then
  terraform version | head -1
  exit 0
fi
ver=$(curl -sS https://api.github.com/repos/hashicorp/terraform/releases/latest \
      | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)
[ -n "$ver" ] || { echo "could not determine latest terraform version"; exit 1; }
echo "installing terraform $ver"
tmp=$(mktemp -d)
curl -sSLo "$tmp/tf.zip" \
  "https://releases.hashicorp.com/terraform/${ver}/terraform_${ver}_linux_amd64.zip"
unzip -qo "$tmp/tf.zip" -d "$HOME/.local/bin"
rm -rf "$tmp"
chmod +x "$HOME/.local/bin/terraform"
terraform version | head -1
