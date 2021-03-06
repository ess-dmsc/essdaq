#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#ensure that we are in the script directory
pushd $THISDIR

echo "Grafana install started: "$(date) | tee -a $LOGFILE

# set up the docker repository -- dependencies
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 || exit 1
# add CentOS docker repo
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# install
sudo yum install -y docker-ce docker-ce-cli containerd.io || exit 1
# start
# This may fail when running centos on Docker, where we
# have some other issues, so for now, do not fail because of this
# as the next steps will anyway.
sudo systemctl start docker

# Whe running in Docker we need to expose /var/run/docker.sock to
# the container, then grafana will launch on the jenkins node
sudo docker swarm init || exit 1
sleep 2
sudo docker ps
sudo docker network ls
sudo docker stack deploy -c docker/docker-compose.yml metrics || exit 1
sudo docker ps
sudo docker network ls

if test -d $HOME/Desktop; then
  echo Adding desktop icons
  cp -rf ./Grafana.desktop $HOME/Desktop/
  echo "Icon=$THISDIR/icon.png" >> $HOME/Desktop/Grafana.desktop
fi

echo "Grafana installed! Please proceed with (manual) configuration steps:"
cat README.md

echo "Grafana install finished: "$(date) | tee -a $LOGFILE
