# zenos-runner

Two self-hosted GitHub Actions runners for `pacholoamit/ZenOS`: `k8s-zenos-0` and `k8s-zenos-1`, with the labels
`zenos-ci` and `zenos-k8s`. They run as the StatefulSet `zenos-runner` in the namespace `github-runners`, which Flux
applies from this folder. They copy the TrueNAS runners (`zentech-github-runner`, runbook
`/mnt/nvme/tenants/zentech/github-runner/README.md` on `ssh truenas_admin@192.168.0.53`): the same image, registration
and volumes, adapted to Kubernetes. See the header of `statefulset.yaml` for the design.

Every ZenOS workflow says `runs-on: ${{ vars.ZENOS_RUNNER || 'ubuntu-latest' }}`. While the repository variable
`ZENOS_RUNNER` is `zenos-ci`, jobs run on any runner with that label: these two and the two TrueNAS runners
(`zenos-truenas,zenos-ci`). Self-hosted minutes cost nothing. Without the variable, jobs run on GitHub-hosted runners,
and those minutes are billed.

## Layout

| Path | What |
|---|---|
| `statefulset.yaml` | The two runners. The image is pinned by digest. |
| `secret.yaml` (SOPS) | `RUNNER_TOKEN`, blank except during a registration. |
| `storageclass.yaml` | `longhorn-runner-cache`: Longhorn with one replica on the runner's node, for the rebuildable volumes. |
| `namespace.yaml` | `github-runners`, with baseline pod security. |
| `images/zenos-runner/` (repository root) | `Dockerfile`, `entrypoint.sh` (registers or restores, then runs), `job-started.sh` (the per-job hook): the NAS image plus tini and `RUNNER_NAME`. Built by `.github/workflows/zenos-runner-image.yml`. |
| PVC `state-zenos-runner-<n>` (1Gi, `longhorn`, 3 replicas) | The runner's identity: `.runner*` and `.credentials*`. Never delete this casually; see Re-register. |
| PVC `work-zenos-runner-<n>` (15Gi) | `_work`: the workspace, the tool cache and bun's package cache (`_work/.bun-install-cache`). |
| PVC `npm-zenos-runner-<n>` (2Gi) | The npm/npx cache. |

bun's cache sits on the work volume, not on a volume of its own as on the NAS: on the same filesystem as the checkout,
`bun install` hardlinks node_modules instead of copying it, which takes 27 s here instead of 72 s.

Runner `k8s-zenos-<n>` is pod `zenos-runner-<n>`.

## Kill switch

```sh
gh variable set ZENOS_RUNNER -R pacholoamit/ZenOS --body zenos-truenas   # the NAS runners only
gh variable set ZENOS_RUNNER -R pacholoamit/ZenOS --body zenos-ci        # back to the shared pool
gh variable delete ZENOS_RUNNER -R pacholoamit/ZenOS                     # GitHub-hosted runners, billed
```

- Use `zenos-truenas` when the cluster is down or these runners misbehave: this pool then gets no new jobs.
- Jobs that are already queued for a label stay queued. Cancel them and re-run them after flipping the switch.

## Status

```sh
gh api repos/pacholoamit/ZenOS/actions/runners --jq '.runners[] | {name, status, busy, labels: [.labels[].name]}'
kubectl -n github-runners get pods,pvc -o wide
kubectl -n github-runners logs zenos-runner-0 --tail=50
```

## Redeploy (after changing statefulset.yaml or the image)

The StatefulSet updates `OnDelete`: Flux applies the change, and a runner takes it when its pod is deleted. Delete a
pod only while its runner shows `busy: false`: deleting it cancels the job it is running.

```sh
kubectl -n github-runners delete pod zenos-runner-0
```

The pod comes back with its saved identity, so no token is needed.

## Update

- **Runner:** it updates itself. To move the image forward too, bump `RUNNER_VERSION` in
  `images/zenos-runner/Dockerfile` (see https://github.com/actions/runner/releases) and push. Copy the `image:` line
  from the zenos-runner-image run's summary into `statefulset.yaml`, push, then redeploy each runner.
- **Node, Playwright:** `NODE_MAJOR` and `PLAYWRIGHT_VERSION` in the same Dockerfile. Keep them equal to the NAS's
  `.env`, so both pools run the same toolchain.

## Capacity

A runner requests 1 CPU and 3Gi and may use 6Gi, the TrueNAS runners' cap (a cold `validate` fills it). It has no
CPU limit, so a job uses idle cores.

Memory available on 2026-09-26 (capacity minus working set): k3s-node-1 4.8 GiB, k3s-node-2 7.4 GiB, k3s-node-3
11.8 GiB. The kubelets have no memory eviction threshold (`evictionHard` lists only disk signals), so an
overcommitted node goes straight to the kernel OOM killer, and that killer can pick a homelab app before a runner.
Hence:

- No runner on a control-plane node or on k3s-node-1, which carries the stateful apps and has less room than one
  job. By requests it looks the emptiest worker, so without the rule the scheduler would pick it first.
- One runner per worker (required pod anti-affinity), so two replicas: one on k3s-node-2, one on k3s-node-3.
- Priority class `homelab-ci` (-100, never preempts): an app that cannot schedule preempts a runner, and a runner
  that does not fit stays Pending. Priority does not steer the OOM killer; the 6Gi limits against each node's free
  memory do.

Add a replica, and drop the `NotIn` for k3s-node-1, only after that node has at least 7 GiB available.

### k3s-node-3's CPU

k3s-node-3's VM runs QEMU's generic `kvm64` CPU ("Common KVM processor": no SSE4.2, POPCNT, AVX or AVX2), while
k3s-node-1 and k3s-node-2 pass their host CPUs through. bun needs at least SSE4.2 and POPCNT: on k3s-node-3 it dies
with `Illegal instruction` (SIGILL) in some jobs, as `help-center:check` did in the proof run. So the `NotIn` list also
holds k3s-node-3, and `zenos-runner-0` (`k8s-zenos-0`) stays Pending and shows offline in GitHub. To bring it back:

1. In Proxmox, set that VM's processor type to `host` (`qm set <vmid> --cpu host`), then shut it down and start it
   (a reboot keeps the old CPU). Check with `grep -m1 "model name" /proc/cpuinfo` on the node.
2. Remove `k3s-node-3` from the `NotIn` list in `statefulset.yaml` and push. The pod schedules there with its saved
   identity.

GitHub deletes a runner that has been offline for 14 days. After that, re-register it (below) before step 2.

## Re-register

GitHub deletes a self-hosted runner that has been offline for more than 14 days, and a runner removed in the UI is
gone too. Its pod then exits at start with a session or registration error. To register it again:

1. Mint a token (repo admin; valid for one hour) and write it into the secret without printing it:

   ```sh
   gh api -X POST repos/pacholoamit/ZenOS/actions/runners/registration-token --jq .token \
     | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))' \
     | SOPS_AGE_KEY_FILE=age.agekey sops set --value-stdin clusters/home/apps/zenos-runners/secret.yaml '["stringData"]["RUNNER_TOKEN"]'
   ```

   Commit, push, and wait for Flux (`flux get kustomizations apps`).
2. Empty the runner's state: delete its state volume, then its pod. The StatefulSet recreates both, and
   `config.sh --replace` takes over the name.

   ```sh
   kubectl -n github-runners delete pvc state-zenos-runner-<n> --wait=false
   kubectl -n github-runners delete pod zenos-runner-<n>
   ```

3. Blank the token again (`sops set clusters/home/apps/zenos-runners/secret.yaml '["stringData"]["RUNNER_TOKEN"]' '""'`),
   push, and once the runner is idle delete its pod once more, so that no process keeps the token.

## Clean caches

While the runner is idle, delete its rebuildable volumes, then its pod; the StatefulSet recreates them empty. Never
touch `state-*`.

```sh
kubectl -n github-runners delete pvc work-zenos-runner-<n> npm-zenos-runner-<n> --wait=false
kubectl -n github-runners delete pod zenos-runner-<n>
```

## Remove

1. Flip the kill switch to `zenos-truenas` first.
2. Remove `zenos-runners` from `clusters/home/apps/kustomization.yaml` and push. Flux deletes the namespace, the
   StatefulSet and its volumes.
3. Remove the runners in GitHub (Settings → Actions → Runners), or with
   `gh api -X DELETE repos/pacholoamit/ZenOS/actions/runners/<id>`.
