# kafka
A local Apache Kafka setup with a reasonable configuration for ESS detector DAQ

## Installing
Install with `./install.sh`

You may need to change the IP address specified in the 'listeners=' configuration.
This can be done using `./setlistener.sh`

## Running
On the machine where you intend to run the broker:

Start with `./start_kafka.sh`

Stop with `./stop_kafka.sh`


## Confirming
To confirm that Kafka is running `./check_kafka.sh`

This can be done on any machine, so long as the correct IP is provided in the configuration script in the `essdaq` root directory.
