#!/usr/bin/env bash
# Clones the latest Hermes WebUI release once. start.sh discovers the agent's
# managed Python through the hermes launcher, so nothing else is installed.
set -euo pipefail

dir="$HOME/.hermes/hermes-webui"
if [[ ! -d $dir/.git ]]; then
  tag=$(curl -fsSL https://api.github.com/repos/nesquena/hermes-webui/releases/latest | jq -r .tag_name)
  git clone https://github.com/nesquena/hermes-webui.git "$dir"
  git -C "$dir" checkout --detach "$tag"
fi
