# ESS DAQ: Simplified setup of the EFU-based data acquisition system

[![DOI](https://zenodo.org/badge/135150324.svg)](https://zenodo.org/badge/latestdoi/135150324)

This repository contains a set of scripts and config files for getting a neutron detector data acquisition system up and running. The functionality provided by these scripts is summarized below:

- Install and configure `conan` to provide dependencies for ESS projects.
- Install docker and configure the `grafana` service for data stream statistics.
- Install `kafka`, use provided scripts to easily start and stop it at will.
- Download and build the [Event Formation Unit](https://github.com/ess-dmsc/event-formation-unit).
- Download and build [DAQuiri](https://github.com/ess-dmsc/daquiri).

A description of the contents of each directory in the root of the repository can be found in [documentation/directories.md](documentation/directories.md).

## Getting started

### Prerequisites

 * The only package you should need to install on a fresh operating system are `git`, `cmake` and `python3`. If you intend to commit changes, now is also the time to configure your `ssh` to work with `github`.
 * If you can authenticate to github with ssh, the necessary projects will be cloned accordingly and you will be able to commit changes to those projects.

### Installing

#### 1. Cloning the essdaq scripts
```
git clone https://github.com/ess-dmsc/essdaq.git
cd essdaq
```

#### 2. Interactive installation
```
./install.sh          # for Ubuntu
./install_centos7.sh  # for CentOS
```

The script *install.sh* and *install_centos7.sh* will ask you a few questions during the installation process.


### Post-install configuration

#### 1. Create a configuration file
In order to run correctly the essdaq scripts need to know the following about your system:

* IP address of the servers running Daquiri, Kafka, EFU and Grafana
* Location to write data files
* Name of the ethernet adaptor in use (to be able to run `config/scripts/hwcheck.sh` and `efu/netstats.sh`)

This is specified in a system config file. In the `config/` directory, copy one of the `system_*.sh` files to `system_mysystem.sh`  and modify it to your liking. For example it might look like this:

    > cat config/system_mysystem.sh
    #!/bin/bash

    EFU_IP=127.0.0.1
    KAFKA_IP=127.0.0.1
    DAQUIRI_IP=127.0.0.1
    GRAFANA_IP=127.0.0.1

    UDP_ETH=eno1

    DUMP_PATH=/tmp/data

#### 2. Make a symlink
Create a symbolic link to the configuration file named `system.sh`. This ways you can
keep multiple configurations around.

    > ln -s config/system_mysystem.sh config/system.sh

#### 3. Setup detector specific scripts
Here you should create a new directory for your detector under the `detectors/` directory
if you can't use one of the existing ones.

Start with the following files

    localconfig.sh  and set export DETECTOR=yourdetector
    start.sh
    stop.sh

### Running

You should ensure that docker/grafana and Kafka is running. You also need to manually start
Daquiri but following that daquiri can be controlled by the start and stop scripts.

    > cd essdaq/daquiri/daquiri/build
    > ./bin/daquiri

Now you should be able to start acquisitions with
    > ./start.sh

and stop them with
    > ./stop.sh

## Troubleshooting

Not seeing the data you expected? Follow these steps for [troubleshooting](documentation/troubleshoot.md)

## Contributing

See the [CONTRIBUTING.md](CONTRIBUTING.md) file for details.

## Authors

* Morten Jagd Christensen
* Martin Shetty

See the list of contributors [on Github](https://github.com/ess-dmsc/essdaq/graphs/contributors).

## License

This project is licensed under the BSD-2 License - see the [LICENSE](LICENSE) file for details.
