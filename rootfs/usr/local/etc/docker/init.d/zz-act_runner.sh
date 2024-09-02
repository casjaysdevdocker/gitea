#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202408091659-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  zz-act_runner.sh --help
# @@Copyright        :  Copyright: (c) 2024 Jason Hempstead, Casjays Developments
# @@Created          :  Friday, Aug 09, 2024 16:59 EDT
# @@File             :  zz-act_runner.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/start-service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run trap command on exit
trap 'retVal=$?;[ "$SERVICE_IS_RUNNING" != "yes" ] && [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE";exit $retVal' SIGINT SIGTERM EXIT
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup debugging - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[ -f "/config/.debug" ] && [ -z "$DEBUGGER_OPTIONS" ] && export DEBUGGER_OPTIONS="$(<"/config/.debug")" || DEBUGGER_OPTIONS="${DEBUGGER_OPTIONS:-}"
{ [ "$DEBUGGER" = "on" ] || [ -f "/config/.debug" ]; } && echo "Enabling debugging" && set -xo pipefail -x$DEBUGGER_OPTIONS && export DEBUGGER="on" || set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
export PATH="/usr/local/etc/docker/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_FILE="$0"
SERVICE_NAME="act_runner"
SCRIPT_NAME="$(basename "$SCRIPT_FILE" 2>/dev/null)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# exit if __start_init_scripts function hasn't been Initialized
if [ ! -f "/run/__start_init_scripts.pid" ]; then
  echo "__start_init_scripts function hasn't been Initialized" >&2
  SERVICE_IS_RUNNING="no"
  exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import the functions file
if [ -f "/usr/local/etc/docker/functions/entrypoint.sh" ]; then
  . "/usr/local/etc/docker/functions/entrypoint.sh"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables
for set_env in "/root/env.sh" "/usr/local/etc/docker/env"/*.sh "/config/env"/*.sh; do
  [ -f "$set_env" ] && . "$set_env"
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf '%s\n' "# - - - Initializing $SERVICE_NAME - - - #"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom functions
__gen_auth_token() {
  local user conf_file auth_token token_dir gitea_bin exitCode
  exitCode=1
  user="${GITEA_USER:-git}"
  token_dir="$CONF_DIR/tokens"
  gitea_bin="$(command -v gitea)"
  mkdir -p "$token_dir" >/dev/null 2>&1
  conf_file="$(find "/config" "/etc" -type f -name '*.ini' 2>/dev/null | grep -E 'git/app.ini|gitea/app.ini|gitea.ini' | head -n1 | grep '^')"
  if [ -n "$SYS_AUTH_TOKEN" ]; then
    auth_token="$SYS_AUTH_TOKEN"
  elif [ -s "$CONF_DIR/tokens/system" ]; then
    auth_token="$(<"$CONF_DIR/tokens/system")"
  fi
  auth_token="$(echo "$auth_token" | grep -vE '# |^$')"
  auth_token="${auth_token:-$(gosu $user $gitea_bin --config "$conf_file" actions generate-runner-token 2>/dev/null | grep -vE '\.\.\.|# |^$')}"
  if [ -n "$auth_token" ]; then
    exitCode=0
    echo "$auth_token"
    echo "$auth_token" >"$CONF_DIR/tokens/system"
  fi
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Script to execute
START_SCRIPT="/usr/local/etc/docker/exec/$SERVICE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Reset environment before executing service
RESET_ENV="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the database root dir
DATABASE_BASE_DIR="${DATABASE_BASE_DIR:-/data/db}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the database directory
DATABASE_DIR="${DATABASE_DIR_ACT_RUNNER:-$DATABASE_BASE_DIR/sqlite}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set webroot
WWW_ROOT_DIR="/usr/share/httpd/default"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Default predefined variables
DATA_DIR="/data/act_runner"   # set data directory
CONF_DIR="/config/act_runner" # set config directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the containers etc directory
ETC_DIR="/etc/act_runner"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the var dir
VAR_DIR=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TMP_DIR="/tmp/act_runner"       # set the temp dir
RUN_DIR="/run/act_runner"       # set scripts pid dir
LOG_DIR="/data/logs/act_runner" # set log directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the working dir
WORK_DIR=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# port which service is listening on
SERVICE_PORT="44015"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User to use to launch service - IE: postgres
RUNAS_USER="root" # normally root
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User and group in which the service switches to - IE: nginx,apache,mysql,postgres
SERVICE_USER="git"  # execute command as another user
SERVICE_GROUP="git" # Set the service group
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set user and group ID
#SERVICE_UID="0" # set the user id
#SERVICE_GID="0" # set the group id
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# execute command variables - keep single quotes variables will be expanded later
EXEC_CMD_BIN=''    # command to execute
EXEC_CMD_ARGS=''   # command arguments
EXEC_PRE_SCRIPT='' # execute script before
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a web server
IS_WEB_SERVER="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a database server
IS_DATABASE_SERVICE="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Does this service use a database server
USES_DATABASE_SERVICE="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show message before execute
PRE_EXEC_MESSAGE=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Update path var
PATH="$PATH:."
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Where to save passwords to
ROOT_FILE_PREFIX="/config/secure/auth/root" # directory to save username/password for root user
USER_FILE_PREFIX="/config/secure/auth/user" # directory to save username/password for normal user
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info password/random]
root_user_name="${ACT_RUNNER_ROOT_USER_NAME:-}" # root user name
root_user_pass="${ACT_RUNNER_ROOT_PASS_WORD:-}" # root user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Normal user info [password/random]
user_name="${ACT_RUNNER_USER_NAME:-}"      # normal user name
user_pass="${ACT_RUNNER_USER_PASS_WORD:-}" # normal user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Load variables from config
[ -f "/config/env/act_runner.script.sh" ] && . "/config/env/act_runner.script.sh" # Generated by my dockermgr script
[ -f "/config/env/act_runner.sh" ] && . "/config/env/act_runner.sh"               # Overwrite the variabes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional predefined variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables
GITEA_PORT="${GITEA_PORT:-80}"
SYS_AUTH_TOKEN="$(__gen_auth_token)"
GITEA_USER="${GITEA_USER:-SERVICE_USER}"
INSTANCE_HOSTNAME="${GITEA_HOSTNAME:-$HOSTNAME}"
RUNNER_LABELS="linux:host,"
RUNNER_LABELS+="node:docker://node:latest,"
RUNNER_LABELS+="node14:docker://node:14,"
RUNNER_LABELS+="node16:docker://node:16,"
RUNNER_LABELS+="node18:docker://node:18,"
RUNNER_LABELS+="node20:docker://node:20,"
RUNNER_LABELS+="node22:docker://node:22,"
RUNNER_LABELS+="python3:docker://python:latest,"
RUNNER_LABELS+="php7:docker://casjaysdevdocker/php:7,"
RUNNER_LABELS+="php8:docker://casjaysdevdocker/php:8,"
RUNNER_LABELS+="php:docker://casjaysdevdocker/php:latest,"
RUNNER_LABELS+="alpine:docker://casjaysdev/alpine:latest,"
RUNNER_LABELS+="debian:docker://casjaysdev/debian:latest,"
RUNNER_LABELS+="ubuntu:docker://casjaysdev/ubuntu:latest,"
RUNNER_LABELS+="almalinux:docker://casjaysdev/almalinux:latest,"
RUNNER_LABELS+="act_runner:docker://catthehacker/ubuntu:full-latest"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Specifiy custom directories to be created
ADD_APPLICATION_FILES=""
ADD_APPLICATION_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPLICATION_FILES="$LOG_DIR/$SERVICE_NAME.log"
APPLICATION_DIRS="$RUN_DIR $ETC_DIR $CONF_DIR $LOG_DIR $TMP_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional config dirs - will be Copied to /etc/$name
ADDITIONAL_CONFIG_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# define variables that need to be loaded into the service - escape quotes - var=\"value\",other=\"test\"
CMD_ENV=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite based on file/directory
RUNNER_CACHE_HOST="${RUNNER_CACHE_HOST:-localhost}"
RUNNER_CACHE_PORT="${RUNNER_CACHE_PORT:-$SERVICE_PORT}"
RUNNER_CONFIG_NAME="${RUNNER_CONFIG_NAME:-runner.yaml}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Per Application Variables or imports

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom prerun functions - IE setup WWW_ROOT_DIR
__execute_prerun() {
  # Setup /config directories
  __init_config_etc

  # Define other actions/commands
  while :; do
    pgrep gitea && break || { echo "Waiting for gitea to start before continuing" >&2 && sleep 60; }
  done
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Run any pre-execution checks
__run_pre_execute_checks() {
  # Set variables
  local exitStatus=0
  local pre_execute_checks_MessageST="Running preexecute check for $SERVICE_NAME"   # message to show at start
  local pre_execute_checks_MessageEnd="Finished preexecute check for $SERVICE_NAME" # message to show at completion
  __banner "$pre_execute_checks_MessageST"
  # Put command to execute in parentheses
  {
    [ -d "$CONF_DIR/reg" ] || mkdir -p "$CONF_DIR/reg"
    [ -d "$DATA_DIR/cache" ] || mkdir -p "$DATA_DIR/cache"
    if [ ! -f "$CONF_DIR/reg/default.sample" ]; then
      cat <<EOF >"$CONF_DIR/reg/default.sample"
# Edit this file and execute it
exitStatus=1
RUNNER_NAME="default"
RUNNER_HOME="$HOME/.config/act_runner"
RUNNER_LABELS="$RUNNER_LABELS"
RUNNER_AUTH_TOKEN="${RUNNER_AUTH_TOKEN:-$SYS_AUTH_TOKEN}"
RUNNER_HOSTNAME="${INSTANCE_HOSTNAME}"
RUNNER_REGISTER_URL="http://\${RUNNER_HOSTNAME}"
mkdir -p "\$RUNNER_HOME"
[ -f \$RUNNER_HOME/config.yaml" ] || act_runner generate-config >"\$RUNNER_HOME/config.yaml"
act_runner register --config "\$RUNNER_HOME/config.yaml" --labels "\$RUNNER_LABELS" --name "\$RUNNER_NAME" --instance "\$RUNNER_REGISTER_URL" --token "\$RUNNER_AUTH_TOKEN" --no-interactive && exitStatus=0 || exitStatus=1
if [ "\$exitStatus" -eq 0 ]; then
  act_runner daemon --config $"\$RUNNER_HOME/config.yaml" &
  exitStatus=\$?
fi
exit \$exitStatus 

EOF
      chmod -Rf 755 "$CONF_DIR/reg/default.sample"
    fi
    if [ ! -f "$CONF_DIR/reg/runner-1.reg" ]; then
      cat <<EOF >"$CONF_DIR/reg/runner-1.reg"
# Settings for the default gitea runner
RUNNER_NAME="runner-1"
RUNNER_HOME="$CONF_DIR/multi/\$RUNNER_NAME"
RUNNER_HOSTNAME="http://${INSTANCE_HOSTNAME:-127.0.0.1:$GITEA_PORT}"
RUNNER_REGISTER_URL="http://127.0.0.1:$GITEA_PORT"
RUNNER_AUTH_TOKEN="${RUNNER_AUTH_TOKEN:-$SYS_AUTH_TOKEN}"
RUNNER_LABELS="$RUNNER_LABELS"

EOF
    fi
    if [ ! -f "$CONF_DIR/reg/runner-2.reg" ]; then
      cat <<EOF >"$CONF_DIR/reg/runner-2.reg"
# Settings for the default local runner
RUNNER_NAME="runner-2"
RUNNER_HOME="$CONF_DIR/multi/\$RUNNER_NAME"
RUNNER_HOSTNAME="http://${INSTANCE_HOSTNAME:-127.0.0.1:$GITEA_PORT}"
RUNNER_REGISTER_URL="http://127.0.0.1:$GITEA_PORT"
RUNNER_AUTH_TOKEN="${RUNNER_AUTH_TOKEN:-$SYS_AUTH_TOKEN}"
RUNNER_LABELS="$RUNNER_LABELS"

EOF
    fi

    if [ -f "$ETC_DIR/default_config.yaml" ]; then
      mkdir -p "$CONF_DIR/default"
      [ -f "$CONF_DIR/default/$RUNNER_CONFIG_NAME" ] || copy "$ETC_DIR/default_config.yaml" "$CONF_DIR/default/$RUNNER_CONFIG_NAME"
      if [ ! -f "$ETC_DIR/runners" ] && [ -f "$CONF_DIR/default/$RUNNER_CONFIG_NAME" ] && [ -n "$SYS_AUTH_TOKEN" ]; then
        __replace "REPLACE_RUNNER_TEMP" "$TMP_DIR/gitea" "$CONF_DIR/default/$RUNNER_CONFIG_NAME"
        __replace "REPLACE_RUNNER_HOME" "$CONF_DIR/default" "$CONF_DIR/default/$RUNNER_CONFIG_NAME"
        __replace "REPLACE_RUNNER_CACHE_HOST" "$RUNNER_CACHE_HOST" "$CONF_DIR/default/$RUNNER_CONFIG_NAME"
        __replace "REPLACE_RUNNER_CACHE_PORT" "$RUNNER_CACHE_PORT" "$CONF_DIR/default/$RUNNER_CONFIG_NAME"
        echo "creating gitea in $CONF_DIR/default and registering with http://$INSTANCE_HOSTNAME"
        act_runner register --config "$CONF_DIR/default/$RUNNER_CONFIG_NAME" --labels "$RUNNER_LABELS" --name "gitea" --instance "http://127.0.0.1:$GITEA_PORT" --token "$SYS_AUTH_TOKEN" --no-interactive 2>/dev/stdout
      fi
    fi

    for runner in "$CONF_DIR/reg"/*.reg; do
      while :; do
        [ -f "$runner" ] && . "$runner"
        RUNNER_LABELS="${RUNNER_LABELS:-act_runner}"
        RUNNER_NAME="${RUNNER_NAME:-$(basename "${runner//.reg/}")}"
        RUNNER_HOME="${RUNNER_HOME:-$CONF_DIR/multi/$RUNNER_NAME}"
        RUNNER_AUTH_TOKEN="${RUNNER_AUTH_TOKEN:-$(__gen_auth_token)}"
        RUNNER_HOSTNAME="${RUNNER_HOSTNAME:-http://$INSTANCE_HOSTNAME}"
        RUNNER_REGISTER_URL="${RUNNER_REGISTER_URL:-http://127.0.0.1:$GITEA_PORT}"
        [ -d "$RUNNER_HOME" ] || mkdir -p "$RUNNER_HOME"
        [ -d "$CONF_DIR/tokens" ] || mkdir -p "$CONF_DIR/tokens"
        [ -f "$CONF_DIR/tokens/system" ] && { grep -qs '.' "$CONF_DIR/tokens/system" || rm -Rf "$CONF_DIR/tokens/system"; }
        [ -f "$CONF_DIR/tokens/$RUNNER_NAME" ] && { grep -qs "$CONF_DIR/tokens/$RUNNER_NAME" || rm -Rf "$CONF_DIR/tokens/$RUNNER_NAME"; }
        #
        { [ -f "$RUNNER_HOME/runners" ] || [ ! -s "$RUNNER_HOME/runners" ]; } && break
        [ -z "$RUNNER_NAME" ] && [ -z "$RUNNER_HOME" ] && echo "RUNNER_NAME or RUNNER_HOME is not set" >&2 && break
        #
        [ -s "$CONF_DIR/tokens/system" ] && RUNNER_AUTH_TOKEN="${RUNNER_AUTH_TOKEN:-$(<"$CONF_DIR/tokens/system")}"
        [ -s "$CONF_DIR/tokens/$RUNNER_NAME" ] && RUNNER_AUTH_TOKEN="${RUNNER_AUTH_TOKEN:-$(<"$CONF_DIR/tokens/$RUNNER_NAME")}"
        #
        printf '%s' "$RUNNER_AUTH_TOKEN" >"$CONF_DIR/tokens/$RUNNER_NAME"
        chmod -Rf 600 "$CONF_DIR/tokens/system" "$CONF_DIR/tokens/$RUNNER_NAME" 2>/dev/null
        #
        if [ -z "$RUNNER_AUTH_TOKEN" ]; then
          echo "$(date +'%H:%M') Error: RUNNER_AUTH_TOKEN is not set - visit $INSTANCE_HOSTNAME/admin/actions/runners" >&2
          echo "Then edit $runner or set in $CONF_DIR/tokens/$RUNNER_NAME" >&2
          sleep 120
        else
          echo "creating $RUNNER_NAME in $RUNNER_HOME and registering with $RUNNER_REGISTER_URL"
          [ -f "$RUNNER_HOME/$RUNNER_CONFIG_NAME" ] || copy "$ETC_DIR/default_config.yaml" "$RUNNER_HOME/$RUNNER_CONFIG_NAME"
          __replace "REPLACE_RUNNER_HOME" "$RUNNER_HOME" "$RUNNER_HOME/$RUNNER_CONFIG_NAME"
          __replace "REPLACE_RUNNER_TEMP" "$TMP_DIR/$RUNNER_NAME" "$RUNNER_HOME/$RUNNER_CONFIG_NAME"
          __replace "REPLACE_RUNNER_CACHE_HOST" "$RUNNER_CACHE_HOST" "$RUNNER_HOME/$RUNNER_CONFIG_NAME"
          __replace "REPLACE_RUNNER_CACHE_PORT" "$RUNNER_CACHE_PORT" "$RUNNER_HOME/$RUNNER_CONFIG_NAME"
          if grep -sq "$RUNNER_HOME" "$RUNNER_HOME/$RUNNER_CONFIG_NAME" && grep -sq "$TMP_DIR/$RUNNER_NAME" "$RUNNER_HOME/$RUNNER_CONFIG_NAME"; then
            act_runner register --config "$RUNNER_HOME/$RUNNER_CONFIG_NAME" --labels "$RUNNER_LABELS" --name "$RUNNER_NAME" --instance "$RUNNER_REGISTER_URL" --token "$RUNNER_AUTH_TOKEN" --no-interactive 2>/dev/stdout
            if [ $? -eq 0 ] || [ -f "$RUNNER_HOME/runners" ]; then
              copy "$runner" "$RUNNER_HOME/$RUNNER_NAME.reg"
              chown -Rf "$SERVICE_USER":"$SERVICE_GROUP" "$RUNNER_HOME"
              echo "$RUNNER_NAME has been registered"
              exitStatus=0
              break
            else
              exitStatus=$((exitStatus++))
              echo "$(date +'%H:%M') Failed to register $RUNNER_NAME - $exitStatus" >&2
              sleep 20
            fi
          else
            exitStatus=$((exitStatus++))
            echo "Something seems to have gone wrong modifying $RUNNER_HOME/$RUNNER_CONFIG_NAME" >&2
          fi
        fi
        unset RUNNER_HOME RUNNER_NAME RUNNER_AUTH_TOKEN RUNNER_HOSTNAME RUNNER_REGISTER_URL
      done
    done 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" >/dev/null
    chown -Rf "$SERVICE_USER":"$SERVICE_GROUP" "$CONF_DIR" "$ETC_DIR" "$DATA_DIR" 2>/dev/null
    return $exitStatus
  }
  exitStatus=$?
  __banner "$pre_execute_checks_MessageEnd: Status $exitStatus"

  # show exit message
  if [ $exitStatus -ne 0 ]; then
    echo "The pre-execution check has failed" >&2
    [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE"
    exit 1
  fi
  return $exitStatus
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__update_conf_files() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # CD into temp to bybass any permission errors
  cd /tmp || false # lets keep shellcheck happy by adding false
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # delete files
  #__rm ""

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # custom commands

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # replace variables
  # __replace "" "" "$CONF_DIR/act_runner.conf"
  # replace variables recursively
  #  __find_replace "" "" "$CONF_DIR"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # define actions

  # exit function
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run before executing
__pre_execute() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  # define commands

  # execute if directories is empty
  __is_dir_empty "" && true
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Set permissions
  __fix_permissions "$SERVICE_USER" "$SERVICE_GROUP"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copy /config to /etc
  for config_2_etc in $CONF_DIR $ADDITIONAL_CONFIG_DIRS; do
    __initialize_system_etc "$config_2_etc" 2>/dev/stderr | tee -p -a "$LOG_DIR/init.txt"
  done
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Replace variables
  HOSTNAME="$sysname" __initialize_replace_variables "$ETC_DIR" "$CONF_DIR" "$WWW_ROOT_DIR"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # unset unneeded variables
  unset filesperms filename config_2_etc change_user change_user ADDITIONAL_CONFIG_DIRS application_files filedirs
  # Lets wait a few seconds before continuing
  sleep 5
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run after executing
__post_execute() {
  local pid=""                                                    # init pid var
  local retVal=0                                                  # set default exit code
  local waitTime=60                                               # how long to wait before executing
  local postMessageST="Running post commands for $SERVICE_NAME"   # message to show at start
  local postMessageEnd="Finished post commands for $SERVICE_NAME" # message to show at completion
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}"  # set hostname

  # wait
  sleep $waitTime
  # execute commands
  (
    # show message
    __banner "$postMessageST"
    # commands to execute
    if [ -f "$CONF_DIR/default/runners" ] && [ -f "$CONF_DIR/default/$RUNNER_CONFIG_NAME" ]; then
      act_runner daemon --config $CONF_DIR/default/$RUNNER_CONFIG_NAME &
      pid=$!
      sleep 5 && ps ax | awk '{print $1}' | grep -v 'grep' | grep -q "$pid$" && is_running="yes"
      if [ "$is_running" = "yes" ]; then
        echo "$(date)" >"$CONF_DIR/.runner"
        echo "$$" >"$RUN_DIR/act_runner.pid"
        echo "$pid" >"$RUN_DIR/act_runner.gitea.pid"
        echo "Runner: gitea has been started with pid: $pid" | tee -a -p "$LOG_DIR/init.txt"
      else
        echo "Runner: gitea has failed to start" >/dev/stderr
        [ -f "$RUN_DIR/act_runner.gitea.pid" ] && rm -f "$RUN_DIR/act_runner.gitea.pid"
      fi
      unset pid is_running
    fi
    if [ -d "$CONF_DIR/multi" ]; then
      for multi_dir in "$CONF_DIR/multi"/*; do
        if [ -n "$multi_dir" ] && [ -d "$multi_dir" ]; then
          name="$(basename "$multi_dir")"
          conf="$multi_dir/$RUNNER_CONFIG_NAME"
          if [ -f "$conf" ] && [ -f "$multi_dir/runners" ]; then
            act_runner daemon --config $conf &
            pid=$!
            sleep 5 && ps ax | awk '{print $1}' | grep -v 'grep' | grep -q "$pid$" && is_running="yes"
            if [ "$is_running" = "yes" ]; then
              echo "$pid" >"$RUN_DIR/act_runner.$name.pid"
              echo "Runner: $name has been started with pid: $pid" | tee -a -p "$LOG_DIR/init.txt"
            else
              echo "Runner: $name has failed to start" >/dev/stderr
              [ -f "$RUN_DIR/act_runner.$name.pid" ] && rm -f "$RUN_DIR/act_runner.$name.pid"
            fi
          fi
        fi
        unset pid is_running name
      done
    fi
    if [ -f "$CONF_DIR/cache_server.yaml" ]; then
      act_runner cache-server --config $CONF_DIR/cache_server.yaml -s 0.0.0.0 -p $RUNNER_CACHE_PORT 2>>/dev/stderr | tee -a -p "$LOG_DIR/act_runner_cache.log" &
      execPid=$!
      sleep 5 && ps ax | awk '{print $1}' | grep -v grep | grep -q "$execPid$" && return 0 || return 2
    fi
    # show exit message
    __banner "$postMessageEnd: Status $retVal"
  ) 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" &
  pid=$!
  # set exitCode
  ps ax | awk '{print $1}' | grep -v grep | grep -q "$execPid$" && retVal=0 || retVal=10
  return $retVal
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__pre_message() {
  local exitCode=0
  if [ -n "$user_name" ] || [ -n "$user_pass" ] || [ -n "$root_user_name" ] || [ -n "$root_user_pass" ]; then
    __banner "User info"
    [ -n "$user_name" ] && __printf_space "40" "username:" "$user_name" && echo "$user_name" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_name"
    [ -n "$user_pass" ] && __printf_space "40" "password:" "saved to ${USER_FILE_PREFIX}/${SERVICE_NAME}_pass" && echo "$user_pass" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_pass"
    [ -n "$root_user_name" ] && __printf_space "40" "root username:" "$root_user_name" && echo "$root_user_name" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name"
    [ -n "$root_user_pass" ] && __printf_space "40" "root password:" "saved to ${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass" && echo "$root_user_pass" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass"
    __banner ""
  fi
  [ -n "$PRE_EXEC_MESSAGE" ] && eval echo "$PRE_EXEC_MESSAGE"
  # execute commands

  # set exitCode
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to setup ssl support
__update_ssl_conf() {
  local exitCode=0
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  # execute commands

  # set exitCode
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__create_service_env() {
  cat <<EOF | tee -p "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" &>/dev/null
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info [password/random]
#ENV_ROOT_USER_NAME="${ENV_ROOT_USER_NAME:-$ACT_RUNNER_ROOT_USER_NAME}"   # root user name
#ENV_ROOT_USER_PASS="${ENV_ROOT_USER_NAME:-$ACT_RUNNER_ROOT_PASS_WORD}"   # root user password
#root_user_name="${ENV_ROOT_USER_NAME:-$root_user_name}"                              #
#root_user_pass="${ENV_ROOT_USER_PASS:-$root_user_pass}"                              #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Normal user info [password/random]
#ENV_USER_NAME="${ENV_USER_NAME:-$ACT_RUNNER_USER_NAME}"                  #
#ENV_USER_PASS="${ENV_USER_PASS:-$ACT_RUNNER_USER_PASS_WORD}"             #
#user_name="${ENV_USER_NAME:-$user_name}"                                             # normal user name
#user_pass="${ENV_USER_PASS:-$user_pass}"                                             # normal user password

EOF
  __file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# script to start server
__run_start_script() {
  local runExitCode=0
  local workdir="$(eval echo "${WORK_DIR:-}")"                   # expand variables
  local cmd="$(eval echo "${EXEC_CMD_BIN:-}")"                   # expand variables
  local args="$(eval echo "${EXEC_CMD_ARGS:-}")"                 # expand variables
  local name="$(eval echo "${EXEC_CMD_NAME:-}")"                 # expand variables
  local pre="$(eval echo "${EXEC_PRE_SCRIPT:-}")"                # expand variables
  local extra_env="$(eval echo "${CMD_ENV//,/ }")"               # expand variables
  local lc_type="$(eval echo "${LANG:-${LC_ALL:-$LC_CTYPE}}")"   # expand variables
  local home="$(eval echo "${workdir//\/root/\/tmp\/docker}")"   # expand variables
  local path="$(eval echo "$PATH")"                              # expand variables
  local message="$(eval echo "")"                                # expand variables
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  [ -f "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh" ] && . "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh"
  #
  __run_pre_execute_checks 2>/dev/stderr | tee -a -p "/data/logs/entrypoint.log" "$LOG_DIR/init.txt" || return 20
  #
  if [ -z "$cmd" ]; then
    __post_execute 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt"
    retVal=$?
    echo "Initializing $SCRIPT_NAME has completed"
    exit $retVal
  else
    # ensure the command exists
    if [ ! -x "$cmd" ]; then
      echo "$name is not a valid executable"
      return 2
    fi
    # check and exit if already running
    if __proc_check "$name" || __proc_check "$cmd"; then
      echo "$name is already running" >&2
      return 0
    else
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # show message if env exists
      if [ -n "$cmd" ]; then
        [ -n "$SERVICE_USER" ] && echo "Setting up $cmd to run as $SERVICE_USER" || SERVICE_USER="root"
        [ -n "$SERVICE_PORT" ] && echo "$name will be running on port $SERVICE_PORT" || SERVICE_PORT=""
      fi
      if [ -n "$pre" ] && [ -n "$(command -v "$pre" 2>/dev/null)" ]; then
        export cmd_exec="$pre $cmd $args"
        message="Starting service: $name $args through $pre"
      else
        export cmd_exec="$cmd $args"
        message="Starting service: $name $args"
      fi
      [ -n "$su_exec" ] && echo "using $su_exec" | tee -a -p "$LOG_DIR/init.txt"
      echo "$message" | tee -a -p "$LOG_DIR/init.txt"
      su_cmd touch "$SERVICE_PID_FILE"
      __post_execute 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" &
      if [ "$RESET_ENV" = "yes" ]; then
        env_command="$(echo "env -i HOME=\"$home\" LC_CTYPE=\"$lc_type\" PATH=\"$path\" HOSTNAME=\"$sysname\" USER=\"${SERVICE_USER:-$RUNAS_USER}\" $extra_env")"
        execute_command="$(__trim "$su_exec $env_command $cmd_exec")"
        if [ ! -f "$START_SCRIPT" ]; then
          cat <<EOF >"$START_SCRIPT"
#!/usr/bin/env bash
trap 'exitCode=\$?;[ \$exitCode -ne 0 ] && [ -f "\$SERVICE_PID_FILE" ] && rm -Rf "\$SERVICE_PID_FILE";exit \$exitCode' EXIT
#
set -Eeo pipefail
# Setting up $cmd to run as ${SERVICE_USER:-root} with env
retVal=10
cmd="$cmd"
SERVICE_PID_FILE="$SERVICE_PID_FILE"
$execute_command 2>"/dev/stderr" >>"$LOG_DIR/$SERVICE_NAME.log" &
execPid=\$!
sleep 10
checkPID="\$(ps ax | awk '{print \$1}' | grep -v grep | grep "\$execPid$" || false)"
[ -n "\$execPid"  ] && [ -n "\$checkPID" ] && echo "\$execPid" >"\$SERVICE_PID_FILE" && retVal=0 || retVal=10
[ "\$retVal" = 0 ] && echo "\$cmd has been started" || echo "\$cmd has failed to start - args: $args" >&2
exit \$retVal

EOF
        fi
      else
        if [ ! -f "$START_SCRIPT" ]; then
          execute_command="$(__trim "$su_exec $cmd_exec")"
          cat <<EOF >"$START_SCRIPT"
#!/usr/bin/env bash
trap 'exitCode=\$?;[ \$exitCode -ne 0 ] && [ -f "\$SERVICE_PID_FILE" ] && rm -Rf "\$SERVICE_PID_FILE";exit \$exitCode' EXIT
#
set -Eeo pipefail
# Setting up $cmd to run as ${SERVICE_USER:-root}
retVal=10
cmd="$cmd"
SERVICE_PID_FILE="$SERVICE_PID_FILE"
$execute_command 2>>"/dev/stderr" >>"$LOG_DIR/$SERVICE_NAME.log" &
execPid=\$!
sleep 10
checkPID="\$(ps ax | awk '{print \$1}' | grep -v grep | grep "\$execPid$" || false)"
[ -n "\$execPid"  ] && [ -n "\$checkPID" ] && echo "\$execPid" >"\$SERVICE_PID_FILE" && retVal=0 || retVal=10
[ "\$retVal" = 0 ] && echo "\$cmd has been started" || echo "\$cmd has failed to start - args: $args" >&2
exit \$retVal

EOF
        fi
      fi
    fi
    [ -x "$START_SCRIPT" ] || chmod 755 -Rf "$START_SCRIPT"
    [ "$CONTAINER_INIT" = "yes" ] || eval sh -c "$START_SCRIPT"
    runExitCode=$?
    return $runExitCode
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# username and password actions
__run_secure_function() {
  if [ -n "$user_name" ] || [ -n "$user_pass" ]; then
    for filesperms in "${USER_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms" 2>/dev/null
      fi
    done 2>/dev/null | tee -p -a "$LOG_DIR/init.txt"
  fi
  if [ -n "$root_user_name" ] || [ -n "$root_user_pass" ]; then
    for filesperms in "${ROOT_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms" 2>/dev/null
      fi
    done 2>/dev/null | tee -p -a "$LOG_DIR/init.txt"
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow ENV_ variable - Import env file
__file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICE_EXIT_CODE=0 # default exit code
# application specific
EXEC_CMD_NAME="$(basename "$EXEC_CMD_BIN")"                                # set the binary name
SERVICE_PID_FILE="/run/init.d/$EXEC_CMD_NAME.pid"                          # set the pid file location
SERVICE_PID_NUMBER="$(__pgrep)"                                            # check if running
EXEC_CMD_BIN="$(type -P "$EXEC_CMD_BIN" || echo "$EXEC_CMD_BIN")"          # set full path
EXEC_PRE_SCRIPT="$(type -P "$EXEC_PRE_SCRIPT" || echo "$EXEC_PRE_SCRIPT")" # set full path
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Only run check
__check_service "$1"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create auth directories
[ -n "$USER_FILE_PREFIX" ] && { [ -d "$USER_FILE_PREFIX" ] || mkdir -p "$USER_FILE_PREFIX"; }
[ -n "$ROOT_FILE_PREFIX" ] && { [ -d "$ROOT_FILE_PREFIX" ] || mkdir -p "$ROOT_FILE_PREFIX"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$IS_WEB_SERVER" = "yes" ] && RESET_ENV="yes"
[ -n "$RUNAS_USER" ] || RUNAS_USER="root"
[ -n "$SERVICE_USER" ] || SERVICE_USER="${RUNAS_USER:-root}"
[ -n "$SERVICE_GROUP" ] || SERVICE_GROUP="${RUNAS_USER:-root}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Database env
if [ "$IS_DATABASE_SERVICE" = "yes" ] || [ "$USES_DATABASE_SERVICE" = "yes" ]; then
  RESET_ENV="no"
  DATABASE_CREATE="${ENV_DATABASE_CREATE:-$DATABASE_CREATE}"
  DATABASE_USER="${ENV_DATABASE_USER:-${DATABASE_USER:-$user_name}}"
  DATABASE_PASSWORD="${ENV_DATABASE_PASSWORD:-${DATABASE_PASSWORD:-$user_pass}}"
  DATABASE_ROOT_USER="${ENV_DATABASE_ROOT_USER:-${DATABASE_ROOT_USER:-$root_user_name}}"
  DATABASE_ROOT_PASSWORD="${ENV_DATABASE_ROOT_PASSWORD:-${DATABASE_ROOT_PASSWORD:-$root_user_pass}}"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow per init script usernames and passwords
__file_exists_with_content "$ETC_DIR/auth/user/name" && user_name="$(<"$ETC_DIR/auth/user/name")"
__file_exists_with_content "$ETC_DIR/auth/user/pass" && user_pass="$(<"$ETC_DIR/auth/user/pass")"
__file_exists_with_content "$ETC_DIR/auth/root/name" && root_user_name="$(<"$ETC_DIR/auth/root/name")"
__file_exists_with_content "$ETC_DIR/auth/root/pass" && root_user_pass="$(<"$ETC_DIR/auth/root/pass")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set password to random if variable is random
[ "$user_pass" = "random" ] && user_pass="$(__random_password)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$root_user_pass" = "random" ] && root_user_pass="$(__random_password)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow setting initial users and passwords via environment
user_name="$(eval echo "${ENV_USER_NAME:-$user_name}")"
user_pass="$(eval echo "${ENV_USER_PASS:-$user_pass}")"
root_user_name="$(eval echo "${ENV_ROOT_USER_NAME:-$root_user_name}")"
root_user_pass="$(eval echo "${ENV_ROOT_USER_PASS:-$root_user_pass}")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow variables via imports - Overwrite existing
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" ] && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ensure needed directories exists
[ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
[ -d "$RUN_DIR" ] || mkdir -p "$RUN_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# pre-run function
__execute_prerun
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create user if needed
__create_service_user "$SERVICE_USER" "$SERVICE_GROUP" "${WORK_DIR:-/home/$SERVICE_USER}" "${SERVICE_UID:-}" "${SERVICE_GID:-}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Modify user if needed
__set_user_group_id $SERVICE_USER ${SERVICE_UID:-} ${SERVICE_GID:-}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create base directories
__setup_directories
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set switch user command
__switch_to_user
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize the home/working dir
__init_working_dir
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# show init message
__pre_message
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
__initialize_db_users
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize ssl
__update_ssl_conf
__update_ssl_certs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Updating config files
__create_service_env
__update_conf_files
__initialize_database
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_secure_function
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run the pre execute commands
__pre_execute
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_start_script 2>>/dev/stderr | tee -p -a "/data/logs/entrypoint.log" && errorCode=0 || errorCode=10
if [ -n "$EXEC_CMD_BIN" ]; then
  if [ "$errorCode" -ne 0 ]; then
    echo "Failed to execute: ${cmd_exec:-$EXEC_CMD_BIN $EXEC_CMD_ARGS}" | tee -p -a "/data/logs/entrypoint.log" "$LOG_DIR/init.txt"
    rm -Rf "$SERVICE_PID_FILE"
    SERVICE_EXIT_CODE=10
    SERVICE_IS_RUNNING="no"
  else
    SERVICE_EXIT_CODE=0
    SERVICE_IS_RUNNING="no"
  fi
  SERVICE_EXIT_CODE=0
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__banner "Initializing of $SERVICE_NAME has completed with statusCode: $SERVICE_EXIT_CODE" | tee -p -a "/data/logs/entrypoint.log" "$LOG_DIR/init.txt"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $SERVICE_EXIT_CODE
