# ghcr.io/pacholoamit/zenos-runner: the ZenOS CI runner for Actions Runner
# Controller (clusters/home/apps/zenos-runners). Built and pushed by
# .github/workflows/zenos-runner-image.yml; the scale set pins it by digest.
#
# GitHub's runner image plus what ubuntu-latest gives the ZenOS jobs and this
# image lacks, the same toolchain as the TrueNAS runners (zentech-github-runner):
#   - Node 22, official binaries (hosted ships 22.x): tsc, vitest and next run
#     on Node rather than bun's node shim.
#   - zstd, so actions/cache compresses and keys caches like hosted runners.
#     Without it, turbo and fallow caches saved by other runners never restore.
#   - LANG=C.UTF-8 as on hosted; TZ stays unset (UTC), which unit tests assume.
# The base already has git, jq, unzip, curl, python3 and passwordless sudo for
# `runner`, so Playwright's `install --with-deps` can apt-get its libraries at
# run time. Every runner pod is ephemeral, so nothing a job installs carries over.
FROM node:24.21.0-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6 AS node

FROM ghcr.io/actions/actions-runner:2.337.0@sha256:e5496277be5d09bc968b3d64911b74e219ac4a3f2edce956a3ecf9271bea1ef4
USER root
ENV LANG=C.UTF-8
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && apt-get update \
 && apt-get install -y --no-install-recommends zstd \
 && rm -rf /var/lib/apt/lists/* \
 && node --version && npm --version && zstd --version
USER runner
