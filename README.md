## 👋 Welcome to gitea 🚀

Self-hosted Git service with built-in CI/CD (Gitea Actions), Docker-in-Docker support, and SSH access.

## Features

- 🚀 **Latest Gitea** - Auto-downloads latest version on build
- 🐳 **Docker-in-Docker** - Run Docker inside the container for CI/CD
- ⚙️ **Gitea Actions** - Built-in CI/CD with act_runner (5 parallel runners by default)
- 🔐 **SSH Server** - Git operations over SSH (port 22/7833)
- 📦 **Package Registry** - Container, NPM, Maven, PyPI, and more
- 💾 **SQLite** - Zero-config database (PostgreSQL/MySQL supported)
- 🔧 **Easy Configuration** - Environment variable driven setup

## Quick Start

### Simple Run (HTTP only)

```bash
docker run -d \
  --privileged \
  --name gitea \
  -p 80:80 \
  -p 22:22 \
  -v "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/data:/data:z" \
  -v "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/config:/config:z" \
  casjaysdevdocker/gitea:latest
```

Access Gitea at: `http://localhost`

## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update gitea
```
  
## Install and run container
  
```shell
mkdir -p "$HOME/.local/share/srv/docker/gitea/rootfs"
git clone "https://github.com/dockermgr/gitea" "$HOME/.local/share/CasjaysDev/dockermgr/gitea"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/gitea/rootfs/." "$HOME/.local/share/srv/docker/gitea/rootfs/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-gitea \
--hostname gitea \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/data:/data:z" \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/config:/config:z" \
-p 80:80 \
casjaysdevdocker/gitea:latest
```
  
## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GITEA_EMAIL_CONFIRM` | `false` | Enable email notifications |
| `EMAIL_RELAY` | `172.17.0.1` | SMTP relay (Docker host gateway) |
| `SERVER_ADMIN` | `administrator@$HOSTNAME` | Admin email address |
| `RUNNERS_START` | `5` | Number of parallel CI/CD runners |
| `GITEA_HOSTNAME` | `$HOSTNAME` | Gitea server hostname |
| `TZ` | `America/New_York` | Timezone |

### Enable Email Notifications

```bash
docker run -d \
  --privileged \
  --name gitea \
  -e GITEA_EMAIL_CONFIRM=yes \
  -e EMAIL_RELAY=smtp.gmail.com \
  -e SERVER_ADMIN=admin@example.com \
  -p 80:80 -p 22:22 \
  -v "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/data:/data:z" \
  -v "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/config:/config:z" \
  casjaysdevdocker/gitea:latest
```

## via docker-compose

```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/gitea
    container_name: casjaysdevdocker-gitea
    environment:
      - TZ=America/New_York
      - HOSTNAME=gitea
    volumes:
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/data:/data:z"
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-gitea/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/gitea
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/gitea" "$HOME/Projects/github/casjaysdevdocker/gitea"
```
  
## Build container

```shell
cd "$HOME/Projects/github/casjaysdevdocker/gitea"
buildx
```

## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
