#!/usr/bin/env bash
set -euo pipefail

# node-pty provides OpenChamber's terminal; npm skips its native build
# scripts unless they are allowed explicitly.
/home/linuxbrew/.linuxbrew/bin/npm install --global --allow-scripts=node-pty @openchamber/web
