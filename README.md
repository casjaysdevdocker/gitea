# gitea

An all-in-one Alpine-based Docker image that bundles **Gitea** (self-hosted Git service), **Docker-in-Docker** (dockerd), and **act_runner** (Gitea Actions CI runner) into a single container. Designed for teams that want a complete self-hosted Git + CI/CD stack without orchestrating multiple containers. Gitea is pre-configured with Actions enabled, SSH access, LFS, and five act_runner worker instances that register automatically on first boot.

---

## 🐳 Docker

### Pull and run

```shell
docker run -d \
  --restart always \
  --privileged \
  --name casjaysdevdocker-gitea-latest \
  --hostname gitea \
  -e TZ=${TIMEZONE:-America/New_York} \
  -v /var/lib/srv/$USER/docker/casjaysdevdocker/gitea/data:/data:z \
  -v /var/lib/srv/$USER/docker/casjaysdevdocker/gitea/config:/config:z \
  -p 80:80 \
  -p 7833:7833 \
  -p 2375:2375 \
  -p 44015:44015 \
  casjaysdevdocker/gitea:latest
```

> **Note:** `--privileged` is required — the container runs a full Docker daemon (DinD) and needs cgroup v2 access.

### Ports

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| `80` | TCP | Gitea | Web UI and HTTP clone |
| `7833` | TCP | sshd | Git SSH access (`git clone git@host:user/repo`) |
| `2375` | TCP | dockerd | Docker daemon (plain HTTP — bind to localhost or a trusted network only) |
| `44015` | TCP | act_runner | Actions artifact/cache server |

### Volumes

| Path | Description |
|------|-------------|
| `/config` | Gitea config, SSH host keys, act_runner registration state |
| `/data` | Gitea repositories, LFS objects, SQLite database, Docker layer cache |

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `America/New_York` | Container timezone |
| `SERVER_ADDRESS` | `http://localhost` | Gitea URL used by act_runner for self-registration |
| `SERVER_TOKEN` | *(auto-generated)* | act_runner registration token — generated from Gitea on first boot if not set |
| `RUNNER_LABELS` | *(runner default)* | Comma-separated labels applied to all registered runners |
| `RUNNERS_START` | `5` | Number of act_runner worker instances to start |
| `RUNNERS_LOG_DIR` | `/var/log/act_runner` | Directory for per-runner log files |

### docker-compose

```yaml
services:
  gitea:
    image: casjaysdevdocker/gitea:latest
    container_name: casjaysdevdocker-gitea
    restart: always
    privileged: true
    hostname: gitea
    environment:
      - TZ=America/New_York
      - RUNNERS_START=5
    volumes:
      - /var/lib/srv/$USER/docker/casjaysdevdocker/gitea/data:/data:z
      - /var/lib/srv/$USER/docker/casjaysdevdocker/gitea/config:/config:z
    ports:
      - 80:80
      - 7833:7833
      - 2375:2375
      - 44015:44015
```

### Automatic install/update via dockermgr

```shell
dockermgr update gitea
```

---

## 🛠️ Development

### Get source files

```shell
git clone "https://github.com/casjaysdevdocker/gitea" "$HOME/Projects/github/casjaysdevdocker/gitea"
```

### 🐳 Docker build

The image builds for `linux/amd64` and `linux/arm64` via BuildX. Gitea and act_runner binaries are downloaded from GitHub/Gitea APIs at build time.

```shell
cd "$HOME/Projects/github/casjaysdevdocker/gitea"
buildx
```

Image tags pushed: `casjaysdevdocker/gitea:latest` and `casjaysdevdocker/gitea:YYMM` (date tag).

---

## 👤 Authors

🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵

---

## 📄 License

MIT — see [LICENSE.md](LICENSE.md)
