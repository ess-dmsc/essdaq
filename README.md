# ESS DAQ: Simplified setup of the EFU-based data acquisition system

[![DOI](https://zenodo.org/badge/135150324.svg)](https://zenodo.org/badge/latestdoi/135150324)

## What can it do?
- install and configure `conan` to provide dependencies for ESS projects
- install docker and configure the `grafana` service for data stream statistics
- install `kafka`, use provided scripts to easily start and stop it at will
- download and build the [Event Formation Unit](https://github.com/ess-dmsc/event-formation-unit)
- download and build [DAQuiri](https://github.com/ess-dmsc/daquiri)
- update `conan`, `EFU` and `DAQuiri` to latest versions

## Before you start
The only package you should need to install on a fresh system is `git`. If you intend to commit changes, now is also the time to configure your `ssh` or whatever other authentication credentials to work with `github`.

## First install
Just run `./install.sh` and answer the simple questions

## At any later point
Just run `./update.sh` and answer the simple questions

## Directories
Directory             | Function
-------------         | -------------
grafana               | grafana installation scripts, configuration files
kafka                 | kafka installation and start/stop scripts
multigrid             | detector-specific setup for multigrid
