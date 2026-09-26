#!/usr/bin/env bash
# Starts one ZenOS runner. Its identity (.runner*, .credentials*) lives in
# /runner-state on the dataset: restored on every start, and created once,
# from a registration token (RUNNER_TOKEN), while that directory is empty.
set -euo pipefail
shopt -s nullglob

cd /home/runner
# Leftovers from this container's previous life; no .NET process runs yet.
find /tmp -mindepth 1 -maxdepth 1 -user "$(id -u)" -exec rm -rf {} + 2>/dev/null || true

if [ -s /runner-state/.runner ]; then
  cp -p /runner-state/.runner* /runner-state/.credentials* .
else
  if [ -z "${RUNNER_TOKEN:-}" ]; then
    echo "zenos-runner: /runner-state is empty and RUNNER_TOKEN is not set." >&2
    echo "zenos-runner: see README.md, \"Re-register\", then redeploy the app." >&2
    exit 1
  fi
  ./config.sh --unattended --replace \
    --url "${RUNNER_URL:?}" --token "$RUNNER_TOKEN" \
    --name "$(hostname)" --labels "${RUNNER_LABELS:?}" --work _work
  for f in .runner* .credentials*; do
    install -m 600 "$f" "/runner-state/$f"
  done
fi
unset RUNNER_TOKEN

# .path and .env describe this image, so they are regenerated on every start.
if [ -x ./env.sh ]; then ./env.sh; fi
exec ./run.sh
