FROM gitea/gitea:latest

ARG alpine_version=edge \
  LICENSE=WTFPL \
  IMAGE_NAME=gitea \
  TIMEZONE=America/New_York \
  PORT="3000 22"

ENV SHELL=/bin/bash \
  TERM=xterm-256color \
  HOSTNAME=${HOSTNAME:-casjaysdev-$IMAGE_NAME} \
  TZ=$TIMEZONE

RUN mkdir -p /bin/ /config/ /data/ && \
  rm -Rf /bin/.gitkeep /config/.gitkeep /data/.gitkeep /etc/apk/repositories && \
  echo "http://dl-cdn.alpinelinux.org/alpine/$alpine_version/main" >> /etc/apk/repositories && \
  echo "http://dl-cdn.alpinelinux.org/alpine/$alpine_version/community" >> /etc/apk/repositories && \
  echo "http://dl-cdn.alpinelinux.org/alpine/$alpine_version/testing" >> /etc/apk/repositories && \
  apk update -U --no-cache

COPY ./bin/. /usr/local/bin/
COPY ./config/. /config/
COPY ./data/. /data/

#FROM scratch
ARG BUILD_DATE="20221008"

LABEL org.label-schema.name="gitea" \
  org.label-schema.description="Containerized version of gitea" \
  org.label-schema.url="https://hub.docker.com/r/casjaysdevdocker/gitea" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/gitea" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="$LICENSE" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="latest" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>"

ENV SHELL="/bin/bash" \
  TERM="xterm-256color" \
  HOSTNAME="casjaysdev-gitea" \
  TZ="${TZ:-America/New_York}" \
  GITEA__mailer__ENABLED="" \
  GITEA__mailer__FROM="" \
  GITEA__mailer__MAILER_TYPE="" \
  GITEA__mailer__HOST="" \
  GITEA__mailer__IS_TLS_ENABLED="" \
  GITEA__mailer__USER="" \
  GITEA__mailer__PASSWD=""

WORKDIR /root

VOLUME ["/root","/config","/data"]

EXPOSE $PORT

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

#COPY --from=build /. /

#ENTRYPOINT [ "/sbin/tini", "--" ]
#HEALTHCHECK --interval=15s --timeout=3s CMD [ "/usr/local/bin/entrypoint-gitea.sh", "healthcheck" ]
#CMD [ "/usr/local/bin/entrypoint-gitea.sh" ]

