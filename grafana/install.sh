#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

# From https://docs.docker.com/install/linux/docker-ce/ubuntu/
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common || exit 1

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || exit 1
sudo apt-get update || exit 1
sudo apt-get install -y docker-ce || exit 1

sudo docker swarm init || exit 1
sudo docker stack deploy -c docker/docker-compose.yml metrics || exit 1

if test -d $HOME/Desktop; then
  echo Adding desktop icons
  cp -rf ./Grafana.desktop $HOME/Desktop/
  echo "Icon=$THISDIR/icon.png" >> $HOME/Desktop/Grafana.desktop
fi

echo "Grafana installed! Please proceed with (manual) configuration steps:"
cat README.md

echo "Grafana install finished" >> $LOGFILE
