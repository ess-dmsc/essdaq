# ESS DAQ: Scripts and utilities for setup of the EFU-based data acquisition system

## What can it do?
- install and configure `conan` to provide dependencies for ESS projects
- install docker and configure the `grafana` service for data stream statistics
- install `kafka`, use provided scripts to easily start and stop it at will
- download and build the `Event Formation Unit`
- download and build `DAQuiri`
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
grafana               | dashboard configuration files for import
