#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202605241158-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  MIT
# @@Copyright        :  Copyright 2026 CasjaysDev
# @@Created          :  Sun May 24 11:58:45 AM EDT 2026
# @@File             :  05-custom.sh
# @@Description      :  script to run custom
# @@Changelog        :  newScript
# @@TODO             :  Refactor code
# @@Other            :  N/A
# @@Resource         :  N/A
# @@Terminal App     :  yes
# @@sudo/root        :  yes
# @@Template         :  templates/dockerfiles/init_scripts/05-custom.sh
# - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC1001,SC1003,SC2001,SC2003,SC2016,SC2031,SC2090,SC2115,SC2120,SC2155,SC2199,SC2229,SC2317,SC2329
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
set -o pipefail
[ "$DEBUGGER" = "on" ] && echo "Enabling debugging" && set -x$DEBUGGER_OPTIONS
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set env variables
exitCode=0
apk add --no-cache ca-certificates 2>/dev/null || true
update-ca-certificates 2>/dev/null || true
GITEA_VERSION="${GITEA_VERSION:-latest}"
GITEA_BIN_FILE="/usr/local/bin/gitea"
ACT_BIN_FILE="/usr/local/bin/act_runner"
ARCH="$(uname -m | tr '[:upper]' '[:lower]')"
case "$ARCH" in x86_64) ARCH="amd64" ;; aarch64) ARCH="arm64" ;; *) echo "$ARCH is not supported by this script" >&2 && exit 1 ;; esac
# Pinned fallback used when gitea.com is unreachable from the build host
# Repo was renamed gitea/act_runner -> gitea/runner; binaries are now gitea-runner-{ver}-linux-{arch}
ACT_RUNNER_FALLBACK_VERSION="${ACT_RUNNER_FALLBACK_VERSION:-v1.0.8}"
# Fetch latest version tag from the renamed repo — 30s connect timeout
ACT_VERSIONS="$(curl -q --connect-timeout 30 --max-time 45 -LSsf \
  'https://gitea.com/api/v1/repos/gitea/runner/releases' \
  -H 'accept: application/json' 2>/dev/null | jq -r '.[].tag_name' | sort -Vr | head -n1)"
# Fall back to pinned version if API is unreachable
[ -z "$ACT_VERSIONS" ] && ACT_VERSIONS="$ACT_RUNNER_FALLBACK_VERSION" && echo "WARNING: gitea.com unreachable, using act_runner $ACT_VERSIONS" >&2
# Fetch download URL from API; binary names use the version without leading 'v'
ACT_URL="$(curl -q --connect-timeout 30 --max-time 45 -LSsf \
  "https://gitea.com/api/v1/repos/gitea/runner/releases/tags/$ACT_VERSIONS" \
  -H 'accept: application/json' 2>/dev/null | jq -rc '.assets|.[]|.browser_download_url' | grep "linux-${ARCH}$")"
# If API parse yielded nothing, construct the direct download URL from the version
# Tag format: v1.0.8 → filename: gitea-runner-1.0.8-linux-amd64 (strip leading 'v')
ACT_VER_PLAIN="${ACT_VERSIONS#v}"
[ -z "$ACT_URL" ] && ACT_URL="https://gitea.com/gitea/runner/releases/download/${ACT_VERSIONS}/gitea-runner-${ACT_VER_PLAIN}-linux-${ARCH}"
if [ -z "$GITEA_VERSION" ] || [ "$GITEA_VERSION" = "latest" ] || [ "$GITEA_VERSION" = "current" ]; then
	_latest_url="$(curl -4sfL -o /dev/null -w '%{url_effective}' https://github.com/go-gitea/gitea/releases/latest 2>/dev/null)"
	GITEA_VERSION="$(printf '%s\n' "$_latest_url" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
fi
if [ -z "$GITEA_VERSION" ]; then
	echo "Failed to resolve gitea latest version from GitHub" >&2
	exit 1
fi
GITEA_URL="https://github.com/go-gitea/gitea/releases/download/v${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-${ARCH}"
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Predefined actions
echo "Downloading gitea from $GITEA_URL"
if curl -4 -q -LSsf --retry 5 --retry-delay 10 --retry-all-errors "$GITEA_URL" -o "/tmp/gitea.$$"; then
	mv -f "/tmp/gitea.$$" "$GITEA_BIN_FILE"
	echo "gitea has been installed to: $GITEA_BIN_FILE"
	chmod +x "$GITEA_BIN_FILE"
	if [ -d "/etc/sudoers.d" ]; then
		echo "root       ALL=(ALL)      NOPASSWD: ALL" >"/etc/sudoers.d/root"
		echo "git        ALL=(ALL)      NOPASSWD: ALL" >"/etc/sudoers.d/git"
		echo "docker     ALL=(ALL)      NOPASSWD: ALL" >"/etc/sudoers.d/docker"
	fi
else
	echo "Failed to download gitea" >&2
	exitCode=$((exitCode + 1))
fi
echo "Downloading act_runner from $ACT_URL"
if [ -z "$ACT_URL" ]; then
	echo "Failed to resolve act_runner download URL" >&2
	exitCode=$((exitCode + 1))
elif curl -q -LSsf --retry 5 --retry-delay 10 --retry-all-errors "$ACT_URL" -o "/tmp/act_runner.$$"; then
	mv -f "/tmp/act_runner.$$" "$ACT_BIN_FILE"
	echo "act_runner has been installed to: $ACT_BIN_FILE"
	chmod +x "$ACT_BIN_FILE"
else
	echo "Failed to download act_runner" >&2
	exitCode=$((exitCode + 1))
fi
[ -x "$ACT_BIN_FILE" ] && [ -x "$GITEA_BIN_FILE" ] && exitCode=0
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Main script

# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
#exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
# - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
# - - - - - - - - - - - - - - - - - - - - - - - - -
