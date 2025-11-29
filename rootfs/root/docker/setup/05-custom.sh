#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202511290736-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  MIT
# @@Copyright        :  Copyright 2025 CasjaysDev
# @@Created          :  Sat Nov 29 07:36:08 AM EST 2025
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
GITEA_VERSION="${GITEA_VERSION:-latest}"
GITEA_BIN_FILE="/usr/local/bin/gitea"
ACT_BIN_FILE="/usr/local/bin/act_runner"
ARCH="$(uname -m | tr '[:upper]' '[:lower]')"
case "$ARCH" in x86_64) ARCH="amd64" ;; aarch64) ARCH="arm64" ;; *) echo "$ARCH is not supported by this script" >&2 && exit 1 ;; esac
ACT_VERSIONS="$(curl -q -LSsf 'https://gitea.com/api/v1/repos/gitea/act_runner/releases' -H 'accept: application/json' | jq -r '.[].tag_name' | sort -Vr | head -n1)"
ACT_URL="$(curl -q -LSsf "https://gitea.com/api/v1/repos/gitea/act_runner/releases/tags/$ACT_VERSIONS" -H 'accept: application/json' | jq -rc '.assets|.[]|.browser_download_url' | grep "linux.*$ARCH$")"
if [ -z "$GITEA_VERSION" ] || [ "$GITEA_VERSION" = "latest" ] || [ "$GITEA_VERSION" = "current" ]; then
	GITEA_URL="$(curl -s https://api.github.com/repos/go-gitea/gitea/releases/latest | jq -r '.assets[] | select(.name|match("linux.*'${ARCH}'$")) | .browser_download_url')"
else
	GITEA_URL="https://github.com/go-gitea/gitea/releases/download/v$GITEA_VERSION/gitea-$GITEA_VERSION-linux-$ARCH"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Predefined actions
echo "Dowloading gitea from $GITEA_URL"
if curl -q -LSsf "$GITEA_URL" -o "/tmp/gitea.$$"; then
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
	exitCode=$((exitCode++))
fi
echo "Downloading act_runner from $ACT_URL"
if curl -q -LSsf "$ACT_URL" -o "/tmp/act_runner.$$"; then
	mv -f "/tmp/act_runner.$$" "$ACT_BIN_FILE"
	echo "act_runner has been installed to: $ACT_BIN_FILE"
	chmod +x "$ACT_BIN_FILE"
else
	echo "Failed to download act_runner" >&2
	exitCode=$((exitCode++))
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
