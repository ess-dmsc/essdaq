# Grafana

A local Graphite and Grafana Docker setup for detector DAQ.

## Installation
Installation scripts are provided on an "As is" basis. They have been used
and have been working but are not production quality. Please let us know
about problems and suggested fixes.

### Ubuntu
Run `./install.sh`

### CentOS
Run `./install_centos7.sh`

### MacOS
#### Install Docker
     https://docs.docker.com/docker-for-mac/install/

#### Install Graphite
    docker run -d\
     --name graphite\
     --restart=always\
     -p 80:80\
     -p 2003-2004:2003-2004\
     -p 2023-2024:2023-2024\
     -p 8125:8125/udp\
     -p 8126:8126\
     graphiteapp/graphite-statsd

#### Install Grafana
    docker run \
      -d \
      -p 3000:3000 \
      --restart=always\
      --name=grafana \
      -v grafana-storage:/var/lib/grafana \
      grafana/grafana

## Open/configure Grafana
Just open *http://localhost:3000* to get the Grafana
web interface. You can log into the Grafana server with
user *admin* and password *admin*.

To add a data source to Grafana, select **Data Sources** and **Add data
source**. In the *Add data source* screen, choose a name for the data source
and select *Graphite* as the type. Set the URL to *http://graphite:80* and
access to *proxy*. Click **Add** to finish.

You can also load preconfigured dashboards provided in the `dashboards` folder.
