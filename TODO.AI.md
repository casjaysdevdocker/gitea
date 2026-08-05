# TODO.AI.md

## Lint cleanup — pre-existing script-lint violations (found incidentally while wiring act_runner cache-server)

Not fixed yet — out of scope for the cache-enablement change; flagged by `script-lint` agent.

- `rootfs/usr/local/bin/start-runners`:
  - line 24: UUOC — `echo "$SERVER_ADDRESS" | grep -q '://'` should be `[[ "$SERVER_ADDRESS" == *"://"* ]]`
  - line 24: `grep -q '://'` missing `--` before query
- `rootfs/usr/local/etc/docker/init.d/zz-act_runner.sh`:
  - line 4: `##@Version` header present but no matching `VERSION=` assignment in script body
  - missing `--` before the grep query at lines 124 (x2), 130, 133, 134, 369, 390, 401, 438, 468, 525 (x2), 544 (x2, also should quote the `grep` pattern), 571, 583

## App-breaking bug fixed — DEBUGGER guard pattern under set -e (functions/entrypoint.sh)

Needs syncing back to the upstream template in `casjay-dotfiles/scripts` per the Docker Template
Update Runbook in AI.md — `functions/entrypoint.sh` is normally regenerated, not hand-edited.

- 26x occurrences of `[ "$DEBUGGER" = "on" ] && echo/printf/__service_banner "..."` used as a bare
  statement: under `set -e`, this aborts the whole script silently whenever `$DEBUGGER` != "on"
  (the default). This was the root cause of the container dying immediately after printing only
  the startup banner. Fixed by appending `|| true` to all 26 occurrences.

## App-breaking bug fixed — __random_password() SIGPIPE (functions/entrypoint.sh)

Needs syncing back to the upstream template in `casjay-dotfiles/scripts` per the Docker Template
Update Runbook in AI.md — `functions/entrypoint.sh` is normally regenerated, not hand-edited.

- `__random_password()` (~line 333): `tr | head -c` pipeline died under `set -eo pipefail` on
  SIGPIPE. Fixed by wrapping in `{ ... } || true`.

## App-breaking bug fixed — __format_variables() whitespace-only input (functions/entrypoint.sh)

Needs syncing back to the upstream template per AI.md's runbook.

- `__format_variables()` (~line 187): `printf '%s\n' $input | sort -Ru | tr '\n' ' '` always
  emits at least one line even when `$input` word-splits to zero words (whitespace-only), because
  `printf` with a format containing `%s` runs once even with no args. This made `ENV_PORTS` /
  `WEB_SERVER_PORTS` resolve to a single space `" "` instead of empty when no port env vars were
  set, which made `SERVICE_PORT` in `08-gitea.sh` become `" "` — passing the `-n` test but
  rendering as an empty `--port` arg to `gitea web`, which broke gitea's CLI argument parsing
  entirely (`Command error: unknown command: /config/gitea/app.ini`). Fixed by replacing the
  `[ -z "$input" ]` check with `[[ "$input" =~ [^[:space:]] ]] || return 0`.

## Other observations not yet actioned

- `.gitea/workflows/docker.yaml` uses the same stale/unpinned action pattern (`@v2`-`@v4`, DockerHub-only, `catthehacker/ubuntu:act-latest`) that was removed from the `opengist` repo's duplicate workflow — no `build.yml` counterpart exists here yet.
- `Dockerfile` sets forbidden OCI labels (`org.opencontainers.image.base.name`, `.schema-version`, duplicate `authors`) — same issue previously found and fixed in `opengist`.
