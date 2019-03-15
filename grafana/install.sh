#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

RELEASE=$(grep CODENAME /etc/lsb-release | sed -e's/^.*=//g')

sudo apt-get install -y curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable"
sudo apt-get update && sudo apt-get install -y docker-ce

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
