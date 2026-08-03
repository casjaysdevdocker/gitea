# TODO.AI.md

## Lint cleanup — pre-existing script-lint violations (found incidentally while wiring act_runner cache-server)

Not fixed yet — out of scope for the cache-enablement change; flagged by `script-lint` agent.

- `rootfs/usr/local/bin/start-runners`:
  - line 24: UUOC — `echo "$SERVER_ADDRESS" | grep -q '://'` should be `[[ "$SERVER_ADDRESS" == *"://"* ]]`
  - line 24: `grep -q '://'` missing `--` before query
- `rootfs/usr/local/etc/docker/init.d/zz-act_runner.sh`:
  - line 4: `##@Version` header present but no matching `VERSION=` assignment in script body
  - missing `--` before the grep query at lines 124 (x2), 130, 133, 134, 369, 390, 401, 438, 468, 525 (x2), 544 (x2, also should quote the `grep` pattern), 571, 583

## Other observations not yet actioned

- `.gitea/workflows/docker.yaml` uses the same stale/unpinned action pattern (`@v2`-`@v4`, DockerHub-only, `catthehacker/ubuntu:act-latest`) that was removed from the `opengist` repo's duplicate workflow — no `build.yml` counterpart exists here yet.
- `Dockerfile` sets forbidden OCI labels (`org.opencontainers.image.base.name`, `.schema-version`, duplicate `authors`) — same issue previously found and fixed in `opengist`.
