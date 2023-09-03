## 👋 Welcome to gitea 🚀  

gitea README  
  
  
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
