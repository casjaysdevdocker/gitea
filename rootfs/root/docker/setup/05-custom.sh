#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202408091653-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  MIT
# @@ReadME           :
# @@Copyright        :  Copyright 2023 CasjaysDev
# @@Created          :  Mon Aug 28 06:48:42 PM EDT 2023
# @@File             :  05-custom.sh
# @@Description      :  script to run custom
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck shell=bash
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
set -e -o pipefail
[ "$DEBUGGER" = "on" ] && echo "Enabling debugging" && set -x$DEBUGGER_OPTIONS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set env variables
GET_ARCH="$(uname -m | tr '[:upper]' '[:lower]')"
case "$GET_ARCH" in
x86_64) ARCH="amd64" && unset GET_ARCH ;;
aarch64) ARCH="arm64" && unset GET_ARCH ;;
*) echo "$GET_ARCH is not supported by this script" >&2 && exit 1 ;;
esac
exitCode=0
GITEA_VERSION="${GITEA_VERSION:-latest}"
GITEA_BIN_FILE="/usr/local/bin/gitea"
ACT_BIN_FILE="/usr/local/bin/act_runner"
ACT_VERSIONS="$(curl -q -LSsf 'https://gitea.com/api/v1/repos/gitea/act_runner/releases' -H 'accept: application/json' | jq -r '.[].tag_name' | sort -Vr | head -n1)"
ACT_URL="$(curl -q -LSsf "https://gitea.com/api/v1/repos/gitea/act_runner/releases/tags/$ACT_VERSIONS" -H 'accept: application/json' | jq -rc '.assets|.[]|.browser_download_url' | grep "linux.*$ARCH$")"
if [ "$GITEA_VERSION" = "latest" ] || [ "$GITEA_VERSION" = "current" ]; then
  GITEA_URL="$(curl -s https://api.github.com/repos/go-gitea/gitea/releases/latest | jq -r '.assets[] | select(.name|match("linux.*'${ARCH}'$")) | .browser_download_url')"
else
  GITEA_URL="https://github.com/go-gitea/gitea/releases/download/v$GITEA_VERSION/gitea-$GITEA_VERSION-linux-$ARCH"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main script
echo "Dowloading from $GITEA_URL"
curl -q -LSsf "$GITEA_URL" -o "$GITEA_BIN_FILE" && GITEA=true || echo "Failed to download gitea" >&2
echo "Downloading act_runner from $ACT_URL"
curl -q -LSsf "$ACT_URL" -o "$ACT_BIN_FILE" && ACT=true || echo "Failed to download act_runner" >&2
if [ "$GITEA" = true ] && [ "$ACT" = true ]; then
  chmod +x "$GITEA_BIN_FILE" "$ACT_BIN_FILE"
  if [ -d "/etc/sudoers.d" ]; then
    echo "gitea       ALL=(ALL)      NOPASSWD: ALL" >"/etc/sudoers.d/gitea"
    echo "docker      ALL=(ALL)      NOPASSWD: ALL" >"/etc/sudoers.d/docker"
  fi
else
  exitCode=5
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
[ $exitCode -eq 0 ] && [ -x "$ACT_BIN_FILE" ] && [ -x "$ACT_BIN_FILE" ] && echo "gitea has been installed to: $GITEA_BIN_FILE" || echo "Failed to install gitea or act_runner" >&2
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
