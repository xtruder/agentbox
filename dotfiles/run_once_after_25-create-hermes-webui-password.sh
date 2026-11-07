#!/usr/bin/env bash
# Generates the Hermes WebUI password once; read it from ~/.config/hermes/webui.env.
set -euo pipefail

env_file="$HOME/.config/hermes/webui.env"
[[ -f $env_file ]] && exit
install -d -m 0700 "$(dirname "$env_file")"
# Avoid `| head -c`: it would SIGPIPE tr and fail under pipefail.
password=$(head -c 512 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9')
(umask 077 && printf 'HERMES_WEBUI_PASSWORD=%s\n' "${password:0:24}" >"$env_file")
