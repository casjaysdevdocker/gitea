# Docker image for gitea using the alpine template
ARG IMAGE_NAME="gitea"
ARG PHP_SERVER="gitea"
ARG BUILD_DATE="Sun Aug  4 01:40:42 PM EDT 2024"
ARG LANGUAGE="en_US.UTF-8"
ARG TIMEZONE="America/New_York"
ARG WWW_ROOT_DIR="/usr/share/httpd/default"
ARG DEFAULT_FILE_DIR="/usr/local/share/template-files"
ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data"
ARG DEFAULT_CONF_DIR="/usr/local/share/template-files/config"
ARG DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"

ARG USER="root"
ARG SHELL_OPTS="set -e -o pipefail"

ARG SERVICE_PORT="80"
ARG EXPOSE_PORTS="80"
ARG PHP_VERSION="system"
ARG NODE_VERSION="system"
ARG NODE_MANAGER="system"

ARG IMAGE_REPO="casjaysdevdocker/gitea"
ARG IMAGE_VERSION="latest"
ARG CONTAINER_VERSION="USE_DATE"

ARG PULL_URL="casjaysdev/alpine"
ARG DISTRO_VERSION="${IMAGE_VERSION}"
ARG BUILD_VERSION="${BUILD_DATE}"

FROM tianon/gosu:latest AS gosu
FROM ${PULL_URL}:${DISTRO_VERSION} AS build
ARG TZ
ARG USER
ARG LICENSE
ARG TIMEZONE
ARG LANGUAGE
ARG IMAGE_NAME
ARG PHP_SERVER
ARG BUILD_DATE
ARG SERVICE_PORT
ARG EXPOSE_PORTS
ARG BUILD_VERSION
ARG IMAGE_VERSION
ARG WWW_ROOT_DIR
ARG DEFAULT_FILE_DIR
ARG DEFAULT_DATA_DIR
ARG DEFAULT_CONF_DIR
ARG DEFAULT_TEMPLATE_DIR
ARG DISTRO_VERSION
ARG NODE_VERSION
ARG NODE_MANAGER
ARG PHP_VERSION
ARG SHELL_OPTS

ARG PACK_LIST="fuse-overlayfs btrfs-progs e2fsprogs e2fsprogs-extra git ip6tables iptables openssl pigz shadow-uidmap xfsprogs xz zfs docker nginx jq \
  "

ENV ENV=~/.bashrc
ENV SHELL="/bin/sh"
ENV TZ="${TIMEZONE}"
ENV TIMEZONE="${TZ}"
ENV LANG="${LANGUAGE}"
ENV TERM="xterm-256color"
ENV HOSTNAME="casjaysdevdocker-gitea"

USER ${USER}
WORKDIR /root

COPY ./rootfs/usr/local/bin/pkmgr /usr/local/bin/pkmgr
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu

RUN echo "Initializing the system"; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/init" ];then echo "Running the init script";sh "/root/docker/setup/init";echo "Done running the init script";fi; \
  echo ""

RUN echo "Creating and editing system files "; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/system" ];then echo "Running the system script";sh "/root/docker/setup/system";echo "Done running the system script";fi; \
  echo ""

RUN echo "" \
  $SHELL_OPTS; \
  echo ""

RUN echo ""; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Setting up and installing packages"; \
  $SHELL_OPTS; \
  if [ -n "${PACK_LIST}" ];then echo "Installing packages: $PACK_LIST";pkmgr install ${PACK_LIST};fi; \
  echo ""

RUN echo "Initializing packages before copying files to image"; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/packages" ];then echo "Running the packages script";sh "/root/docker/setup/packages";echo "Done running the packages script";fi; \
  echo ""

COPY ./rootfs/. /
COPY ./Dockerfile /root/docker/Dockerfile

RUN echo "Updating system files "; \
  $SHELL_OPTS; \
  echo "Updating system files "; \
  echo "$TIMEZONE" >"/etc/timezone"; \
  touch "/etc/profile" "/root/.profile"; \
  echo 'hosts: files dns' >"/etc/nsswitch.conf"; \
  [ "$PHP_VERSION" = "system" ] && PHP_VERSION="php" || true; \
  BASH_CMD="$(command -v bash 2>/dev/null|| true)"; \
  PHP_BIN="$(command -v ${PHP_VERSION} 2>/dev/null || true)"; \
  PHP_FPM="$(ls /usr/*bin/php*fpm* 2>/dev/null || true)"; \
  pip_bin="$(command -v python3 2>/dev/null || command -v python2 2>/dev/null || command -v python 2>/dev/null || true)"; \
  py_version="$(command $pip_bin --version | sed 's|[pP]ython ||g' | awk -F '.' '{print $1$2}' | grep '[0-9]' || true)"; \
  [ "$py_version" -gt "310" ] && pip_opts="--break-system-packages " || pip_opts=""; \
  if [ -n "$pip_bin" ];then $pip_bin -m pip install certbot-dns-rfc2136 certbot-dns-duckdns certbot-dns-cloudflare certbot-nginx $pip_opts || true;fi; \
  [ -f "$BASH_CMD" ] && { rm -rf "/bin/sh" || true; } && ln -sf "$BASH_CMD" "/bin/sh" || true; \
  [ -n "$BASH_CMD" ] && sed -i 's|root:x:.*|root:x:0:0:root:/root:'$BASH_CMD'|g' "/etc/passwd" || true; \
  [ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime" || true; \
  [ -n "$PHP_BIN" ] && [ -z "$(command -v php 2>/dev/null)" ] && ln -sf "$PHP_BIN" "/usr/bin/php" 2>/dev/null || true; \
  [ -n "$PHP_FPM" ] && [ -z "$(command -v php-fpm 2>/dev/null)" ] && ln -sf "$PHP_FPM" "/usr/bin/php-fpm" 2>/dev/null || true; \
  if [ -f "/etc/profile.d/color_prompt.sh.disabled" ]; then mv -f "/etc/profile.d/color_prompt.sh.disabled" "/etc/profile.d/color_prompt.sh";fi ; \
  { [ -f "/etc/bash/bashrc" ] && cp -Rf "/etc/bash/bashrc" "/root/.bashrc"; } || { [ -f "/etc/bashrc" ] && cp -Rf "/etc/bashrc" "/root/.bashrc"; } || { [ -f "/etc/bash.bashrc" ] && cp -Rf "/etc/bash.bashrc" "/root/.bashrc"; } || true; \
  if [ -z "$(command -v "apt-get" 2>/dev/null)" ];then grep -s -q 'alias quit' "/root/.bashrc" || printf '# Profile\n\n%s\n%s\n%s\n' '. /etc/profile' '. /root/.profile' "alias quit='exit 0 2>/dev/null'" >>"/root/.bashrc"; fi; \
  if [ "$PHP_VERSION" != "system" ] && [ -e "/etc/php" ] && [ -d "/etc/${PHP_VERSION}" ];then rm -Rf "/etc/php";fi; \
  if [ "$PHP_VERSION" != "system" ] && [ -n "${PHP_VERSION}" ] && [ -d "/etc/${PHP_VERSION}" ];then ln -sf "/etc/${PHP_VERSION}" "/etc/php";fi; \
  if [ -f "/root/docker/setup/files" ];then echo "Running the files script";sh "/root/docker/setup/files";echo "Done running the files script";fi; \
  echo ""

RUN echo "Custom Settings"; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Setting up users and scripts "; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/users" ];then echo "Running the users script";sh "/root/docker/setup/users";echo "Done running the users script";fi; \
  echo ""

RUN echo ""; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Setting OS Settings "; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Custom Applications"; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Running custom commands"; \
  if [ -f "/root/docker/setup/custom" ];then echo "Running the custom script";sh "/root/docker/setup/custom";echo "Done running the custom script";fi; \
  echo ""

RUN echo ""; \
  $SHELL_OPTS; \
  echo

RUN echo "Running final commands before cleanup"; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/post" ];then echo "Running the post script";sh "/root/docker/setup/post";echo "Done running the post script";fi; \
  echo ""

RUN echo "Deleting unneeded files"; \
  $SHELL_OPTS; \
  pkmgr clean; \
  rm -Rf "/config" "/data" || true; \
  rm -rf /etc/systemd/system/*.wants/* || true; \
  rm -rf /lib/systemd/system/systemd-update-utmp* || true; \
  rm -rf /lib/systemd/system/anaconda.target.wants/* || true; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* || true; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* || true; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* || true; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* || true; \
  rm -Rf /usr/share/doc/* /var/tmp/* /var/cache/*/* /root/.cache/* /usr/share/info/* /tmp/* || true; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ];then cd "/lib/systemd/system/sysinit.target.wants" && rm -f $(ls | grep -v systemd-tmpfiles-setup);fi

RUN echo "Init done"
FROM scratch
ARG TZ
ARG USER
ARG LICENSE
ARG TIMEZONE
ARG LANGUAGE
ARG IMAGE_NAME
ARG PHP_SERVER
ARG BUILD_DATE
ARG SERVICE_PORT
ARG EXPOSE_PORTS
ARG BUILD_VERSION
ARG IMAGE_VERSION
ARG WWW_ROOT_DIR
ARG DEFAULT_FILE_DIR
ARG DEFAULT_DATA_DIR
ARG DEFAULT_CONF_DIR
ARG DEFAULT_TEMPLATE_DIR
ARG DISTRO_VERSION
ARG NODE_VERSION
ARG NODE_MANAGER
ARG PHP_VERSION

USER ${USER}
WORKDIR /root

LABEL \
  maintainer="CasjaysDev <docker-admin@casjaysdev.pro>" \
  org.opencontainers.image.vendor="CasjaysDev" \
  org.opencontainers.image.authors="CasjaysDev" \
  org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}" \
  org.opencontainers.image.name="${IMAGE_NAME}" \
  org.opencontainers.image.base.name="${IMAGE_NAME}" \
  org.opencontainers.image.license="${LICENSE}" \
  org.opencontainers.image.build-date="${BUILD_DATE}" \
  org.opencontainers.image.version="${BUILD_VERSION}" \
  org.opencontainers.image.schema-version="${BUILD_VERSION}" \
  org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/gitea" \
  org.opencontainers.image.url.source="https://hub.docker.com/r/casjaysdevdocker/gitea" \
  org.opencontainers.image.vcs-type="Git" \
  org.opencontainers.image.vcs-ref="${BUILD_VERSION}" \
  org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/gitea" \
  org.opencontainers.image.documentation="https://github.com/casjaysdevdocker/gitea" \
  com.github.containers.toolbox="false"

ENV \
  ENV=~/.bashrc \
  USER="${USER}" \
  SHELL="/bin/bash" \
  TZ="${TIMEZONE}" \
  TIMEZONE="${TZ}" \
  LANG="${LANGUAGE}" \
  TERM="xterm-256color" \
  PORT="${SERVICE_PORT}" \
  ENV_PORTS="${EXPOSE_PORTS}" \
  CONTAINER_NAME="${IMAGE_NAME}" \
  HOSTNAME="casjaysdev-${IMAGE_NAME}" \
  PHP_SERVER="${PHP_SERVER}" \
  NODE_VERSION="${NODE_VERSION}" \
  NODE_MANAGER="${NODE_MANAGER}" \
  PHP_VERSION="${PHP_VERSION}" \
  DISTRO_VERSION="${IMAGE_VERSION}" \
  WWW_ROOT_DIR="${WWW_ROOT_DIR}"

COPY --from=build /. /

VOLUME [ "/config","/data" ]

EXPOSE ${ENV_PORTS}

CMD [ "tail","-f","/dev/null" ]
ENTRYPOINT [ "tini","--","/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=10m --interval=5m --timeout=15s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
