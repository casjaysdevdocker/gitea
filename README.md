## 👋 Welcome to gitea 🚀  

gitea README  
  
  
## Run container

```shell
dockermgr update gitea
```

### via command line

```shell
docker pull casjaysdevdocker/gitea:latest && \
docker run -d \
--restart always \
--name casjaysdevdocker-gitea \
--hostname casjaysdev-gitea \
-e TZ=${TIMEZONE:-America/New_York} \
-v $HOME/.local/share/srv/docker/gitea/files/data:/data:z \
-v $HOME/.local/share/srv/docker/gitea/files/config:/config:z \
-p 80:80 \
casjaysdevdocker/gitea:latest
```

### via docker-compose

```yaml
version: "2"
services:
  gitea:
    image: casjaysdevdocker/gitea
    container_name: gitea
    environment:
      - TZ=America/New_York
      - HOSTNAME=casjaysdev-gitea
    volumes:
      - $HOME/.local/share/srv/docker/gitea/files/data:/data:z
      - $HOME/.local/share/srv/docker/gitea/files/config:/config:z
    ports:
      - 80:80
    restart: always
```

## Authors  

🤖 casjay: [Github](https://github.com/casjay) [Docker](https://hub.docker.com/r/casjay) 🤖  
⛵ CasjaysDevDocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/r/casjaysdevdocker) ⛵  
