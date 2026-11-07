#!/usr/bin/env bash
set -euo pipefail

brew=/home/linuxbrew/.linuxbrew/bin
if [[ ! -x $brew/openchamber ]]; then
  "$brew/npm" install --global @openchamber/web
fi
