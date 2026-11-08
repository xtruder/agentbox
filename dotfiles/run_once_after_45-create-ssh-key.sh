#!/usr/bin/env bash
# Creates agentbox's own SSH key once; the Hermes coding profile uses it to
# reach development hosts. Authorize ~/.ssh/id_ed25519.pub on those hosts.
set -euo pipefail

key="$HOME/.ssh/id_ed25519"
[[ -f $key ]] && exit
install -d -m 0700 "$HOME/.ssh"
ssh-keygen -q -t ed25519 -N '' -C "agent@agentbox" -f "$key"
