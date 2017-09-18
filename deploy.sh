#!/bin/sh

# `$ ./deploy.sh -d t.go5le.net -p ~/git/cdmisRestAPI -P 5000 -m 127.0.0.1:28000 -e server.js`

while getopts ":hd:p:P:v:e:m:" opt; do
  # echo $opt
  case $opt in
    d) 
      # echo $OPTIND ${opt} ${OPTARG}
      restApiHost=${OPTARG}
      ;;
    p) 
      # echo $OPTIND ${opt} ${OPTARG}
      apPath=${OPTARG}
      ;;
    P) 
      # echo $OPTIND ${opt} ${OPTARG}
      PORT=${OPTARG}
      ;;
    m) 
      # echo $OPTIND ${opt} ${OPTARG}
      mongo_url=${OPTARG}
      ;;
    v) 
      # echo $OPTIND ${opt} ${OPTARG}
      APP_VERSION=${OPTARG}
      ;;
    e) 
      # echo $OPTIND ${opt} ${OPTARG}
      entry_file=${OPTARG}
      ;;
    h) 
      # echo $OPTIND ${opt} ${OPTARG}
      echo "./deploy.sh -d www.domain.com -p /path/to/somewhere -P 80 -v 1.1.0"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
if [ ! $restApiHost ]; then
  echo "Need a hostname, e.g. -d test.go5le.net"
  exit 1
fi
if [ ! $apPath ]; then
  if [ ! $APP_VERSION ]; then
    echo "App path not provided(e.g. -p /path/to/somewhere), assume you are in a git repository direcroty!"
    apPath=${PWD}
  else
    echo "App path not provided, auto assigned a path /opt/cdmis!"
    apPath="/opt/cdmis"
  fi
fi

sudo chmod 755 ./pre-setup.sh && sudo ./pre-setup.sh
if [ ${PWD} != $apPath -a ${PWD}/ != $apPath ]; then
  cp * $apPath -rf && cd $apPath \
  && sudo ./deploy.sh $@
  exit 0
fi
if [ ! -f $apPath/mongodb/mongodb.conf ]; then
  mkdir -p $apPath/mongodb && cp mongodb.conf $apPath/mongodb
fi

# MongoDB
MONGO_VERSION=3.4.1

# mongoDbDir=$apPath/mongodb
mongoDbDir=/opt/cdmis-data
mkdir -p $mongoDbDir

set +e
docker pull mongo:$MONGO_VERSION
docker update --restart=no mongodb
docker exec mongodb mongod --shutdown
sleep 2
docker rm -f mongodb
set -e

echo "Running mongo:$MONGO_VERSION"

docker run \
  -d \
  --restart=always \
  --publish=127.0.0.1:${mongod_port:-27017}:27017 \
  --volume=$mongoDbDir:/data/db \
  --volume=$apPath/mongodb:/mongodb-conf \
  --name=mongodb \
  -v /etc/localtime:/etc/localtime:ro \
  mongo:$MONGO_VERSION mongod -f /mongodb-conf/mongodb.conf

# Nginx && SSL
set +e
docker pull jrcs/letsencrypt-nginx-proxy-companion:latest
docker pull jwilder/nginx-proxy
docker rm -f nginx-proxy nginx-proxy-letsencrypt
set -e
echo "Pulled jwilder/nginx-proxy and jrcs/letsencrypt-nginx-proxy-companion"

mkdir -p /bundle/client
docker run -d -p 80:80 -p 443:443 \
  --name nginx-proxy \
  --restart=always\
  -v $apPath/certs:/etc/nginx/certs:ro \
  -v $apPath/my-proxy.conf:/etc/nginx/conf.d/my-proxy.conf \
  -v $apPath:/bundle \
  -v /etc/nginx/vhost.d \
  -v /usr/share/nginx/html \
  -v /var/run/docker.sock:/tmp/docker.sock:ro \
  -v /etc/localtime:/etc/localtime:ro \
  --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
  jwilder/nginx-proxy
  # jwilder/nginx-proxy:alpine
echo "Ran nginx-proxy as $APPNAME"

sleep 2s
docker run -d \
  --name nginx-proxy-letsencrypt \
  --restart=always \
  -e "DEBUG=true" \
  -v $apPath/certs:/etc/nginx/certs:rw \
  --volumes-from nginx-proxy \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /etc/localtime:/etc/localtime:ro \
  jrcs/letsencrypt-nginx-proxy-companion
echo "Ran jrcs/letsencrypt-nginx-proxy-companion"

# APP
set +e
docker pull alexgzhou/alpine:bme319s
docker rm -f alpine-bme319-cdmis
set -e

if [ $APP_VERSION ]; then
  curl -L -o bundle.zip https://github.com/BME319/cdmisRestAPI/archive/v${APP_VERSION}.zip
  unzip bundle.zip -d ./
  # cp settings.js bundle && cp config.js bundle
fi

mongo_docker_url=`docker inspect --format='{{.NetworkSettings.IPAddress}}' mongodb`:27017
echo ${mongo_url:-$mongo_docker_url}
docker run -d \
  --name alpine-bme319-cdmis \
  --restart=always \
  --expose=${PORT:-80} \
  -e "VIRTUAL_HOST=$restApiHost" \
  -e "VIRTUAL_PORT=${PORT:-80}" \
  -e "HTTPS_METHOD=noredirect" \
  -e "LETSENCRYPT_HOST=$restApiHost" \
  -e "LETSENCRYPT_EMAIL=alexgzhou@163.com" \
  -v $apPath:/bundle \
  -v /etc/localtime:/etc/localtime:ro \
  alexgzhou/alpine:bme319s -e ${entry_file:-"index.js"} -p ${PORT:-80} -m ${mongo_url:-$mongo_docker_url}
echo "Ran App"
