# gitea

A self-hosted Docker image for [Gitea](https://gitea.io) — a lightweight, fast Git hosting service — bundled with the Gitea Actions runner (`act_runner`) and Docker-in-Docker support so CI pipelines run out of the box.

---

## 🐳 Docker

### Quick start

```shell
docker run -d \
  --restart always \
  --privileged \
  --name casjaysdevdocker-gitea-latest \
  --hostname git \
  -e TZ=America/New_York \
  -e GITEA_SERVER=git.example.com \
  -v /srv/docker/gitea/data:/data:z \
  -v /srv/docker/gitea/config:/config:z \
  -p 80:80 \
  -p 22:22 \
  casjaysdevdocker/gitea:latest
```

### via docker compose

```yaml
services:
  gitea:
    image: casjaysdevdocker/gitea:latest
    container_name: casjaysdevdocker-gitea-latest
    hostname: git
    privileged: true
    restart: always
    environment:
      - TZ=America/New_York
      - GITEA_SERVER=git.example.com
      - GITEA_PROTO=https
    volumes:
      - /srv/docker/gitea/data:/data:z
      - /srv/docker/gitea/config:/config:z
    ports:
      - 80:80
      - 22:22
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
| `22` | TCP | Git over SSH |

### Notes

- **`--privileged` is required** for Docker-in-Docker (act\_runner runs CI jobs inside containers).
- The container ships its own `/etc/resolv.conf` (Cloudflare + Google DNS, no search domain) so DNS resolution inside the container is not affected by the host's search domain configuration.
- `GITEA_SERVER` **must be set** for a production deployment — without it, `ROOT_URL`, SSH clone URLs, and all system email addresses fall back to the container's short hostname.
- The mailer is **disabled by default**. Set `GITEA_EMAIL_CONFIRM=yes` to enable it along with the SMTP relay.
- SQLite is the default database. For external MySQL/Postgres set `GITEA_SQL_TYPE`, `GITEA_SQL_HOST`, `GITEA_SQL_USER`, `GITEA_SQL_PASS`, and `GITEA_SQL_NAME`.

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
