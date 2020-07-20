## Troubleshooting


### Check that EFU is running
The EFU is a Linux application is called efu, check that the process exist.
On the server running the efu process issue the following command

     > ps aux | grep efu

### Check the internal EFU counters
Locate the efustats.py script (event-formation-unit/utils/efushell/efustats.py)

    > ./efustats.py

This should return a number of lines with detector-specific counters. It looks something
like this
```
     > STAT_GET efu.sonde.0.receive.packets 7626
     > STAT_GET efu.sonde.0.receive.bytes 1105915
     > STAT_GET efu.sonde.0.receive.dropped 0
     > STAT_GET efu.sonde.0.readouts.seq_errors 1
     > STAT_GET efu.sonde.0.events.count 7629
     > STAT_GET efu.sonde.0.events.geometry_errors 0
     > STAT_GET efu.sonde.0.transmit.bytes 10912880
     > STAT_GET efu.sonde.0.thread.idle 109442
     > STAT_GET efu.sonde.0.thread.fifo_synch_errors 0
     > STAT_GET efu.sonde.0.kafka.produce_fails 0
     > STAT_GET efu.sonde.0.kafka.ev_errors 0
     > STAT_GET efu.sonde.0.kafka.ev_others 0
     > STAT_GET efu.sonde.0.kafka.dr_errors 0
     > STAT_GET efu.sonde.0.kafka.dr_others 0
     > STAT_GET efu.sonde.0.main.uptime 7
```

Look for receive.packets and transmit.bytes which should be nonzero and increasing
on successive calls if data is being received. Also check kafka.produce_fails which
should be 0.

### Check that Kafka and Zookeeper are running
On the server running Kafka, issue the following commands

    > ps aux | grep kafka
    > ps aux | grep zookeeper
    > netstat -an | grep tcp (look for ports 9092 and 2181)

### Check daquiri
Daquiri must subscribe to a Kafka broker using a combination of ip address and tcp port.
The broker string must match the ip address of the Kafka server. If the ip address
is 10.1.2.3, then the broker url is 10.1.2.3:9092.
