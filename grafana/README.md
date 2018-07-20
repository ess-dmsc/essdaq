# Grafana

A local Graphite and Grafana Docker setup for detector DAQ.


## Installation

Run `./install.sh`

## Open grafana

Just open *localhost:3000* to get the Grafana
web interface. You can log into the Grafana server with
user *admin* and password *admin*.

To add a data source to Grafana, select **Data Sources** and **Add data
source**. In the *Add data source* screen, choose a name for the data source
and select *Graphite* as the type. Set the URL to *http://graphite:80* and
access to *proxy*. Click **Add** to finish.


