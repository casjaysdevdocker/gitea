# TODO.AI.md

## Lint cleanup done — UUOC fixed (start-runners)

Verified clean by `script-lint` agent after fix.

- `rootfs/usr/local/bin/start-runners`: line 24 UUOC (`echo | grep -q '://'`) replaced with
  `[[ "$SERVER_ADDRESS" != *"://"* ]]`; grep call removed entirely so the missing `--` no longer
  applies.

## New lint finding — line-length violation (start-runners)

Found by `script-lint` while verifying the fixes above; unrelated to those fixes, not yet actioned.

- `rootfs/usr/local/bin/start-runners` line 36: `RUNNER_LABELS="${RUNNER_LABELS:-...}"` default
  value is 781 characters, exceeds the 180-char line limit. Needs splitting across multiple lines
  (e.g. build the default via an array or heredoc instead of one long string literal).

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

## App-breaking bug fixed — missing /config/env directory (bin/entrypoint.sh)

- `/config/env` directory was never explicitly created. It only came into existence as a side
  effect of `__create_env_file()` (functions/entrypoint.sh) copying
  `/usr/local/etc/docker/env/default.sample` into it — but that sample file/dir does not exist in
  this image's rootfs, so `__create_env_file()` returns early (line 960) without creating the
  directory. `05-dockerd.sh`'s `__create_service_env()` then fails writing
  `/config/env/docker.local.sh` directly (`cat <<'EOF' >"/config/env/....local.sh"`, no `tee`
  suppression) with `No such file or directory`; `zz-act_runner.sh` hits the same error writing
  `/config/env/act_runner.local.sh`. Fixed by adding
  `mkdir -p "/config/env" 2>/dev/null || true` alongside the other `/config/*` directory creation
  lines (~line 241) in `rootfs/usr/local/bin/entrypoint.sh`. Needs syncing to the upstream
  template per AI.md's runbook.

## Other observations not yet actioned

- `.gitea/workflows/docker.yaml` uses the same stale/unpinned action pattern (`@v2`-`@v4`, DockerHub-only, `catthehacker/ubuntu:act-latest`) that was removed from the `opengist` repo's duplicate workflow — no `build.yml` counterpart exists here yet.
- `Dockerfile` sets forbidden OCI labels (`org.opencontainers.image.base.name`, `.schema-version`, duplicate `authors`) — same issue previously found and fixed in `opengist`.
