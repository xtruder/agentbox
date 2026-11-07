# agentbox contributor guidance

- This repository is public and is cloned anonymously by the VM. Never commit
  secrets, tokens, passwords, or migrated Hermes state. Units that need a secret
  read it from a file in the VM and use `ConditionPathExists` so they stay down
  until it exists.
- Hermes WebUI is published by Traefik. Keep `hermes-webui.service` dependent on
  `~/.config/hermes/webui.env` (`HERMES_WEBUI_PASSWORD`); without it the WebUI
  serves sessions and memory unauthenticated.
- The desktop is Xfce on X11 by design: cua-driver and CDP Chrome work natively
  there, while Ubuntu's GNOME is Wayland-only. Do not switch to GNOME without
  restoring the Wayland workarounds.
- Install apt packages and third-party repositories with cloud-init's `apt` and
  `packages` modules, not shell scripts. keyserver.ubuntu.com serves a stale
  Google key without its current signing subkeys, so keep Google's key inline.
- Keep `just create`'s `volatile.apply_template` workaround while the host runs
  Incus 7.5.1 (see README); without it the VM reboots forever.
- Keep `nousershstk` on the kernel command line (cloud-init GRUB drop-in).
  Without it PID 1 crashes on this host's CET shadow stack emulation and the
  VM panics minutes to hours after boot.
- User-level setup belongs in chezmoi under `dotfiles/` (`.chezmoiroot`).
  Install scripts must be idempotent and safe to rerun from `chezmoi update`.
  Hermes, the WebUI and OpenChamber install the latest release once; upgrades
  go through their own updaters.
- Let Hermes generate `hermes-gateway.service` (`hermes gateway install`); it
  embeds the managed runtime paths that change between Hermes releases.
- Under `set -euo pipefail`, do not truncate an endless stream with `| head`;
  the writer gets SIGPIPE and the script fails with status 141.
- Verify changes by recreating the VM: `just delete && just create && just wait
  && just status`.
