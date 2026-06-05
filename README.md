# gitea

A self-hosted Docker image for [Gitea](https://gitea.io) — a lightweight, fast Git hosting service — bundled with the Gitea Actions runner (`act_runner`) and Docker-in-Docker support so CI pipelines run out of the box.

---

## 🐳 Docker

### Quick start

```shell
docker run -d \
  --name casjaysdevdocker-gitea-latest \
  --privileged \
  --restart always \
  --tty \
  --cgroupns private \
  --hostname git.example.com \
  --domainname example.com \
  --network bridge \
  --cap-add CHOWN \
  --cap-add SYS_TIME \
  --cap-add SYS_ADMIN \
  -e TZ=America/New_York \
  -e HOSTNAME=git.example.com \
  -e GITEA_PROTO=http \
  -e DATABASE_DIR_SQLITE=/data/db/sqlite \
  -v /srv/docker/gitea/data:/data:z \
  -v /srv/docker/gitea/config:/config:z \
  -v /srv/docker/databases/sqlite/gitea:/data/db/sqlite:z \
  -p 80:80 \
  -p 22:22 \
  casjaysdevdocker/gitea:latest
```

### via docker compose

```yaml
# nginx proxy address - http://172.17.0.1:80

x-logging: &default-logging
  driver: json-file
  options:
    max-size: "5m"
    max-file: "1"

services:
  gitea:
    image: casjaysdevdocker/gitea:latest
    pull_policy: always
    container_name: casjaysdevdocker-gitea-latest
    hostname: git.example.com
    domainname: example.com
    privileged: true
    tty: true
    restart: always
    logging: *default-logging
    cgroupns_mode: private
    cap_add:
      - CHOWN
      - SYS_TIME
      - SYS_ADMIN
    environment:
      TZ: ${TZ:-America/New_York}
      CONTAINER_NAME: casjaysdevdocker-gitea-latest
      HOSTNAME: ${BASE_HOST_NAME:-git.example.com}
      GITEA_PROTO: http
      DATABASE_DIR_SQLITE: /data/db/sqlite
    volumes:
      - ./volumes/data:/data:z
      - ./volumes/config:/config:z
      - ./volumes/db/sqlite:/data/db/sqlite:z
    ports:
      - "172.17.0.1:80:80"
      - "172.17.0.1:22:22"
    networks:
      - gitea

networks:
  gitea:
    name: gitea
    external: false
```

### Environment variables

**General**

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `America/New_York` | Timezone |
| `DEBUGGER` | _(empty)_ | Set to `on` to enable shell-level debug tracing |

**Server / domain**

| Variable | Default | Description |
|----------|---------|-------------|
| `GITEA_SERVER` | `hostname -f` | Public FQDN — sets ROOT\_URL, DOMAIN, SSH\_DOMAIN, and all email addresses. **Always set this in production.** |
| `GITEA_HOSTNAME` | _(empty)_ | Alias for `GITEA_SERVER` |
| `FULL_DOMAIN_NAME` | _(empty)_ | Fallback FQDN used when neither `GITEA_SERVER` nor `GITEA_HOSTNAME` is set |
| `DOMAIN` | _(empty)_ | Overrides the domain used in email addresses (takes precedence over `GITEA_SERVER`) |
| `GITEA_PROTO` | `http` | Protocol used in ROOT\_URL (`http` or `https`) |
| `GITEA_PORT` | `80` | Internal port Gitea listens on |
| `GITEA_NAME` | `SelfHosted GIT Server` | Site title shown in the UI |
| `GITEA_TZ` | `$TZ` | Override timezone for Gitea specifically |
| `GITEA_WORK_DIR` | `/data/gitea` | Override Gitea's work path |

**Users**

| Variable | Default | Description |
|----------|---------|-------------|
| `GITEA_ROOT_USER_NAME` | _(empty)_ | Initial admin account username (created on first run) |
| `GITEA_ROOT_PASS_WORD` | _(empty)_ | Initial admin account password |
| `GITEA_USER_NAME` | _(empty)_ | Initial normal user username |
| `GITEA_USER_PASS_WORD` | _(empty)_ | Initial normal user password |

**Mail**

| Variable | Default | Description |
|----------|---------|-------------|
| `GITEA_ADMIN` | `administrator@<GITEA_SERVER>` | Admin contact / mailer FROM address |
| `GITEA_EMAIL_RELAY` | `172.17.0.1` | SMTP relay host |
| `GITEA_EMAIL_CONFIRM` | `false` | Set to `yes` to require email confirmation and enable the mailer |

**Database**

| Variable | Default | Description |
|----------|---------|-------------|
| `GITEA_SQL_TYPE` | `sqlite3` | Database type (`sqlite3`, `mysql`, `postgres`) |
| `GITEA_SQL_HOST` | `localhost` | Database host (external DB only) |
| `GITEA_SQL_DB_HOST` | `$GITEA_SQL_HOST` | Alternate database host variable |
| `GITEA_SQL_USER` | _(empty)_ | Database user (external DB only) |
| `GITEA_SQL_PASS` | _(empty)_ | Database password (external DB only) |
| `GITEA_SQL_NAME` | _(empty)_ | Database name (external DB only) |
| `DATABASE_DIR_SQLITE` | `$DATA_DIR/db/sqlite` | Override the SQLite database directory (mount a separate volume here to keep the DB outside `/data`) |

**act\_runner**

| Variable | Default | Description |
|----------|---------|-------------|
| `RUNNERS_START` | `5` | Number of act\_runner instances to register |
| `RUNNER_CACHE_PORT` | `44015` | Port for the act\_runner cache server |
| `RUNNER_IP_ADDRESS` | container IP | IP address act\_runner registers with Gitea |
| `RUNNER_DEFAULT_HOME` | `/config/act_runner/gitea` | Directory where runner registration state is stored |
| `RUNNER_CONFIG_NAME` | `act_runner.yaml` | Runner config filename inside `RUNNER_DEFAULT_HOME` |
| `ACT_RUNNER_FALLBACK_VERSION` | `v1.0.8` | Pinned act\_runner version used if gitea.com is unreachable during build |

### Volumes

| Path | Purpose |
|------|---------|
| `/data` | Repositories, SQLite database, LFS objects, attachments, indexes |
| `/config` | `app.ini`, SSH host keys, act\_runner config — persisted across container restarts |

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| `80` | TCP | Gitea web UI and API |
| `22` (internal) / `7833` (default external) | TCP | Git over SSH — host port 22 is typically taken by sshd; map container port 22 to an available host port and set `SSH_PORT` to match |

### Notes

- **`--privileged` is required** for Docker-in-Docker (act\_runner runs CI jobs inside containers).
- The container ships its own `/etc/resolv.conf` (Cloudflare + Google DNS, no search domain) so DNS resolution inside the container is not affected by the host's search domain configuration.
- `GITEA_SERVER` **must be set** for a production deployment — without it, `ROOT_URL`, SSH clone URLs, and all system email addresses fall back to the container's short hostname.
- The mailer is **disabled by default**. Set `GITEA_EMAIL_CONFIRM=yes` to enable it along with the SMTP relay.
- SQLite is the default database. For external MySQL/Postgres set `GITEA_SQL_TYPE`, `GITEA_SQL_HOST`, `GITEA_SQL_USER`, `GITEA_SQL_PASS`, and `GITEA_SQL_NAME`.

---

## 🏃 Adding external runners

External runners let you add dedicated hardware (e.g. a native ARM64 server) to your Gitea Actions pool without running the full container. Each runner registers directly against your Gitea instance and declares its own labels, so matrix workflows can target it by architecture.

### 1 — Get a registration token

In the Gitea web UI: **Site Administration → Runners → Create Runner Token**

Or via API:

```shell
curl -s -X POST https://git.example.com/api/v1/user/actions/runners/registration-token \
  -H "Authorization: token <your-api-token>"
```

### 2 — Install the act_runner binary

```shell
# Detect arch
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
VER=v1.0.8

curl -LSsf "https://gitea.com/gitea/runner/releases/download/${VER}/gitea-runner-${VER#v}-linux-${ARCH}" \
  -o /usr/local/bin/act_runner
chmod +x /usr/local/bin/act_runner
```

### 3 — Register against your Gitea instance

```shell
act_runner register \
  --instance https://git.example.com \
  --token    <registration-token> \
  --name     "arm64-server" \
  --labels   "arm64:docker://ubuntu:latest,linux/arm64:docker://ubuntu:latest,alpine:docker://alpine:latest,debian:docker://debian:latest" \
  --no-interactive
```

Label format: `name:type:image` — all jobs run inside Docker containers, never directly on the host.
- `arm64:docker://ubuntu:latest` — dispatched to this runner, job runs in a native arm64 Ubuntu container
- `linux/arm64:docker://ubuntu:latest` — OCI-style label for the same runner
- Docker must be installed and running on the host machine

### 4 — Run as a systemd service

```ini
# /etc/systemd/system/act_runner.service
[Unit]
Description=Gitea Actions Runner
After=network.target

[Service]
ExecStart=/usr/local/bin/act_runner daemon
WorkingDirectory=/var/lib/act_runner
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```shell
mkdir -p /var/lib/act_runner
mv .runner /var/lib/act_runner/   # move registration file to working dir
systemctl daemon-reload
systemctl enable --now act_runner
```

### Matrix workflow example

Once both an amd64 and an arm64 runner are registered:

```yaml
jobs:
  build:
    strategy:
      matrix:
        arch: [amd64, arm64]
    runs-on: ${{ matrix.arch }}
    steps:
      - uses: actions/checkout@v4
      - run: uname -m   # confirms native arch
```

---

## 🛠️ Development

### Prerequisites

- Docker with `buildx`
- `bash`, `git`

### Build from source

```shell
git clone https://github.com/casjaysdevdocker/gitea "$HOME/Projects/github/casjaysdevdocker/gitea"
cd "$HOME/Projects/github/casjaysdevdocker/gitea"
buildx
```

### Install via dockermgr

```shell
sudo bash -c "$(curl -q -LSsf https://github.com/systemmgr/installer/raw/main/install.sh)"
sudo systemmgr --config && sudo systemmgr install scripts
dockermgr update gitea
```

---

## 📄 License

MIT — see [LICENSE.md](LICENSE.md)
