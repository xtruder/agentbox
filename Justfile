instance := env_var_or_default("AGENTBOX_INSTANCE", "jarvis:agentbox")
image := env_var_or_default("AGENTBOX_IMAGE", "images:ubuntu/26.04/cloud")
cpus := env_var_or_default("AGENTBOX_CPUS", "12")
memory := env_var_or_default("AGENTBOX_MEMORY", "16GiB")
pool := env_var_or_default("AGENTBOX_POOL", "sdb-pool")
disk_size := env_var_or_default("AGENTBOX_DISK_SIZE", "100GiB")
timeout := env_var_or_default("AGENTBOX_TIMEOUT", "3600")
incus := env_var_or_default("INCUS", "incus")

default:
    @just --list

# Create and boot the VM; cloud-init provisions it and reboots once.
create:
    #!/usr/bin/env bash
    set -euo pipefail
    if {{ incus }} info "{{ instance }}" >/dev/null 2>&1; then
      printf '%s already exists; run `just delete` first.\n' "{{ instance }}" >&2
      exit 1
    fi
    {{ incus }} init "{{ image }}" "{{ instance }}" \
      --vm \
      -c limits.cpu="{{ cpus }}" \
      -c limits.memory="{{ memory }}" \
      -c boot.autostart=true \
      -c cloud-init.user-data="$(cat cloud-init/user-data.yaml)" \
      -s "{{ pool }}" \
      -d root,size="{{ disk_size }}"
    {{ incus }} start "{{ instance }}"
    # Incus 7.5.1's agent reboots for cloud-init before reporting that it
    # applied the image templates, so the host re-applies them on every boot
    # and the VM loops. The first boot already has the rendered templates.
    # Fixed upstream by lxc/incus@4e799f7287.
    {{ incus }} config unset "{{ instance }}" volatile.apply_template

# Wait for cloud-init, its reboot, and the autologin X11 session.
wait:
    #!/usr/bin/env bash
    set -euo pipefail
    deadline=$((SECONDS + {{ timeout }}))
    until {{ incus }} exec "{{ instance }}" -- cloud-init status --wait >/dev/null 2>&1; do
      ((SECONDS < deadline)) || { echo 'cloud-init did not finish' >&2; exit 1; }
      sleep 10
    done
    # cloud-init reports done just before its power_state reboot.
    sleep 30
    until {{ incus }} exec "{{ instance }}" -- sh -c \
      'loginctl list-sessions --no-legend | grep -q " agent seat0 "' >/dev/null 2>&1; do
      ((SECONDS < deadline)) || { echo 'agent session did not start' >&2; exit 1; }
      sleep 5
    done

# Join the tailnet; pass the key with TS_AUTHKEY.
tailscale-up:
    #!/usr/bin/env bash
    set -euo pipefail
    : "${TS_AUTHKEY:?set TS_AUTHKEY to a Tailscale auth key}"
    {{ incus }} exec "{{ instance }}" --env TS_AUTHKEY="$TS_AUTHKEY" -- \
      sh -c 'tailscale up --auth-key="$TS_AUTHKEY" --hostname=agentbox'
    {{ incus }} exec "{{ instance }}" -- tailscale ip -4

# Show provisioning and service state.
status:
    {{ incus }} exec "{{ instance }}" -- sh -c '\
      cloud-init status --long; \
      id agent; \
      loginctl list-sessions --no-legend; \
      systemctl is-active lightdm xrdp tailscaled ssh; \
      systemctl --failed --no-pager; \
      runuser -u agent -- env XDG_RUNTIME_DIR=/run/user/1000 systemctl --user --no-pager --failed; \
      runuser -u agent -- env XDG_RUNTIME_DIR=/run/user/1000 systemctl --user --no-pager --no-legend list-units "hermes-*" traefik.service openchamber.service x11vnc.service hermes-browser.service personal-graph.service'

# Open a shell as agent.
shell:
    {{ incus }} exec "{{ instance }}" --user 1000 --group 1000 --cwd /home/agent \
      --env HOME=/home/agent --env XDG_RUNTIME_DIR=/run/user/1000 -- bash -l

# Show the VM's VGA console.
console:
    {{ incus }} console "{{ instance }}" --type vga

# Delete the VM if it exists.
delete:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! {{ incus }} info "{{ instance }}" >/dev/null 2>&1; then
      exit
    fi
    {{ incus }} stop "{{ instance }}" --force >/dev/null 2>&1 || true
    {{ incus }} delete "{{ instance }}"
