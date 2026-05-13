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
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/gitea/gitea/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/gitea/rootfs"
git clone "https://github.com/dockermgr/gitea" "$HOME/.local/share/CasjaysDev/dockermgr/gitea"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/gitea/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-gitea-latest \
--hostname gitea \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
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
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/gitea/gitea/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/gitea/gitea/latest/rootfs/config:/config:z"
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
