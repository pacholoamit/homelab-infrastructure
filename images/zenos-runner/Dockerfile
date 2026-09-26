# ghcr.io/pacholoamit/zenos-runner — the TrueNAS runners' image
# (zentech-github-runner:local, /mnt/nvme/tenants/zentech/github-runner/image on
# the NAS) for the zenos-runner StatefulSet in clusters/home/apps/zenos-runners:
# GitHub's runner image plus what ubuntu-latest gives the ZenOS jobs and this
# image lacks. Built by .github/workflows/zenos-runner-image.yml; the versions
# are the ARG defaults, which match the NAS's .env. Kubernetes changes against
# the NAS copy: tini as PID 1, and the runner name from RUNNER_NAME.
#   - Node 22 (hosted ships 22.x): `npx convex | eas-cli | @better-auth/cli`,
#     the explicit `node` calls in check-types and postinstall scripts, and it
#     keeps tsc/vitest/next/playwright on Node rather than bun's node shim.
#   - Playwright's Chromium system packages, so e2e's `--with-deps` is a no-op.
#   - zstd, so actions/cache compresses (and keys caches) like hosted runners.
#   - LANG=C.UTF-8 as on hosted; TZ stays unset (UTC), which unit tests assume.
ARG RUNNER_VERSION=2.337.0
ARG NODE_MAJOR=22
FROM node:${NODE_MAJOR}-bookworm-slim AS node

FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION}
ARG PLAYWRIGHT_VERSION=1.62.1
USER root
ENV LANG=C.UTF-8 \
    ACTIONS_RUNNER_HOOK_JOB_STARTED=/usr/local/bin/zenos-job-started.sh
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && apt-get update \
 && apt-get install -y --no-install-recommends zstd tini \
 && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npx -y "playwright@${PLAYWRIGHT_VERSION}" install-deps chromium \
 && rm -rf /var/lib/apt/lists/* /root/.npm /root/.cache \
 && node --version && npm --version && zstd --version && tini --version
# The runner user takes truenas_admin's uid/gid, so what it writes on the
# dataset stays manageable from the host without sudo.
RUN groupmod -g 950 runner && usermod -u 950 runner
COPY --chmod=755 entrypoint.sh /usr/local/bin/zenos-runner
COPY --chmod=755 job-started.sh /usr/local/bin/zenos-job-started.sh
USER runner
# tini is PID 1 in the pod, as Docker's `init: true` is on the NAS: it passes
# the kubelet's SIGTERM on to the runner and reaps what finished jobs orphan.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/zenos-runner"]
