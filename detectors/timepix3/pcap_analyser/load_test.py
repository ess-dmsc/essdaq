import struct
import os
import time
import gc
import pickle
import pandas as pd
from scapy.all import *
from UdpParser import *
from multiprocessing import Pool, Value, Manager
          
def handle_error(error):
    print(error)

def epoch_s_to_ns(epoch_s):
    return epoch_s * 1e9

def ms_to_epoch(ms):
    return ms / 1e3

def get_paths(files):
    paths = []
    for file in files:
        paths.append(os.path.join(folder, file))
    
    return paths

if __name__ == "__main__":

    start = time.time()

    folder = r'pickle/split'

    pcap_files = []

    for file in os.listdir(folder):
        if os.path.isfile(os.path.join(folder, file)):
            pcap_files.append(file)

    pcap_files.sort()
    print(pcap_files)

    all_pixels = pd.DataFrame()
    all_evr = pd.DataFrame()
    all_tdc = pd.DataFrame()

    chunk_size = 1000000

    last_readout = 0
    last_packetid = 0
    for file in pcap_files:
        with open(os.path.join(folder, file), 'rb') as reader:
            parser = pickle.load(reader)

        if(len(parser.pixel) != 0):
            parser.pixel['Readout'] = parser.pixel['Readout'] + last_readout
            parser.pixel['PacketId'] = parser.pixel['PacketId'] + last_packetid
        if(len(parser.tdc) != 0):
            parser.tdc['Readout'] = parser.tdc['Readout'] + last_readout
            parser.tdc['PacketId'] = parser.tdc['PacketId'] + last_packetid
        if(len(parser.evr) != 0):
            parser.evr['Readout'] = parser.evr['Readout'] + last_readout
            parser.evr['PacketId'] = parser.evr['PacketId'] + last_packetid

        last_readout += parser.readout_counter
        last_packetid += parser.packet_counter

        all_pixels = pd.concat([all_pixels, parser.pixel], ignore_index=True)

        all_tdc = pd.concat([all_tdc, parser.tdc], ignore_index=True)
        all_evr = pd.concat([all_evr, parser.evr], ignore_index=True)

    print (f"All pixels: {len(all_pixels.index)}")
    print (f"All evr: {len(all_evr.index)}")
    print (f"All tdc: {len(all_tdc.index)}")

    all_records = len(all_pixels.index) + len(all_tdc.index) + len(all_evr.index)

    print(f"All records: {all_records}")
    # print(f"All readouts: {UdpParser.readout_counter.value}")

    end = time.time()

    print(f"Done in {end - start}")

    while True:
        pass
