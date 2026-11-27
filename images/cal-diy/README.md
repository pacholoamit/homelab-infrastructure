# cal-diy image

`ghcr.io/pacholoamit/cal-diy` is [cal.diy](https://github.com/calcom/cal.diy) (the MIT community
edition of Cal.com) built from its own `Dockerfile`, unchanged, for the TrueNAS app `zentech-cal`
at `https://cal.zentech.ph`.

Why we build it: upstream publishes no image. Docker Hub `calcom/cal.diy` has no tags, and the last
release (`v6.2.0`) predates the cal.diy fork. There are no upstream releases to follow, so the image
is pinned to a commit of `main`.

- `UPSTREAM_REF` holds that commit (40 hex characters, one line).
- `.github/workflows/cal-diy-image.yml` builds it on a GitHub-hosted runner (the build needs about
  6.5 GB of memory for half an hour, more than the box or our own runners should give it) and pushes
  `ghcr.io/pacholoamit/cal-diy:<first 12 characters of the commit>`.
- The public address is baked in at build time (`NEXT_PUBLIC_WEBAPP_URL=https://cal.zentech.ph`), so
  the container rewrites nothing when it starts. No secret is a build argument: the secrets the
  build asks for are throwaway values, and the real ones are read at run time from the app's `.env`.

## Updating cal.diy

1. Put the new commit of `calcom/cal.diy` `main` in `UPSTREAM_REF` and push. The workflow builds,
   starts the image against an empty database (migrations and the app-store seed run, then
   `/api/version` must answer) and pushes it.
2. Copy the `image@digest` line from the run's summary.
3. On the box, follow `/mnt/nvme/tenants/zentech/cal/README.md`: dump the database first (cal.diy's
   migrations are forward-only), put the new digest in `compose.yml`, then
   `midclt call -j app.redeploy zentech-cal`.
