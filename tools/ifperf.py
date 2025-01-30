# Copyright (C) 2025 European Spallation Source, ERIC. See LICENSE file
# ===----------------------------------------------------------------------===#
#    Tool to measure perfomance of a network interface.
# ===----------------------------------------------------------------------===#

import psutil
import time

def get_network_interface_data(interface):
    net_io = psutil.net_io_counters(pernic=True)
    if interface in net_io:
        return net_io[interface].bytes_recv
    else:
        raise ValueError(f"Interface {interface} not found")

def measure_rx_data(interface, interval=1):
    try:
        prev_data = get_network_interface_data(interface)
        while True:
            time.sleep(interval)
            current_data = get_network_interface_data(interface)
            rx_data = current_data - prev_data
            prev_data = current_data
            print(f"Received data on {interface}: {rx_data / interval} bytes/sec")
    except KeyboardInterrupt:
        print("Measurement stopped.")
"""
  Measures the data received per second on an interface with the
  psutil tools.
"""
if __name__ == "__main__":
    interface = input("Enter the network interface to monitor (e.g., eth0): ")
    measure_rx_data(interface)
