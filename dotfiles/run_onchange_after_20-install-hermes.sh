#!/usr/bin/env bash
# Installs the latest stable Hermes Agent once; `hermes update` owns upgrades.
set -euo pipefail

if [[ ! -x $HOME/.local/bin/hermes ]]; then
  # Hermes drives the system Google Chrome over CDP, so skip its Chromium.
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh |
    bash -s -- --skip-setup --skip-browser --non-interactive
fi

# The gateway unit embeds Hermes' managed runtime paths, so Hermes generates
# it. It is enabled but not started so a new VM does not connect to messaging
# platforms before its configuration is migrated.
"$HOME/.local/bin/hermes" gateway install --no-start-now --start-on-login --if-missing
