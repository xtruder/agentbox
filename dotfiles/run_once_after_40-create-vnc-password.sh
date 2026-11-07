#!/usr/bin/env bash
# Generates the RDP/VNC password once; read it from ~/.config/x11vnc/password.
set -euo pipefail

dir="$HOME/.config/x11vnc"
[[ -f $dir/passwd ]] && exit
install -d -m 0700 "$dir"
# VNC authentication only uses the first 8 characters. Truncate in bash:
# `| head -c 8` would SIGPIPE tr and fail under pipefail.
password=$(head -c 512 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9')
password=${password:0:8}
(umask 077 && printf '%s\n' "$password" >"$dir/password")
x11vnc -storepasswd "$password" "$dir/passwd" >/dev/null
